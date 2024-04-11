// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../src/interfaces/Registry/IRegistry.sol";
import "../src/interfaces/Releases/IReleases.sol";

/**
 * @title Marketplace
 * @dev This contract allows buying and selling of Releases and charges a fee on each sale.
 */
contract Marketplace is ERC1155Holder, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    // Types

    struct Sale {
        address seller;
        address releaseOwner;
        address payable beneficiary;
        address releases;
        uint256 tokenId;
        uint256 amountRemaining;
        uint256 amountTotal;
        uint256 pricePerToken;
        uint256 startAt;
        uint256 endAt;
        uint256 maxCountPerWallet;
    }

    // State Variables

    IERC20 _token;
    IRegistry _registry;
    address payable public treasury;
    uint256 public treasuryFee;

    /// @dev releaseOwner => saleId => Sale
    mapping(address => Sale[]) private sales;

    // Events

    /// @dev Emitted when a sale is created
    event SaleCreated(address indexed releaseOwner, uint256 indexed saleId);
    /// @dev Emitted when a sale is purchased
    event Purchase(
        address indexed releases,
        uint256 indexed tokenId,
        address indexed buyer,
        address releaseOwner,
        uint256 saleId,
        uint256 tokenAmount,
        uint256 timestamp
    );
    /// @dev Emitted when a sale is withdrawn
    event Withdraw(address indexed recipient, uint256 indexed saleId, uint256 tokenAmount);

    // Errors
    error CannotBeZeroAddress();
    error TreasuryFeeCannotBeZero();
    error TokenAmountCannotBeZero();
    error MaxCountCannotBeZero();
    error StartCannotBeAfterEnd(uint256 startTime, uint256 endTime);
    error InsufficientSupply(uint256 remainingSupply);
    error MaxSupplyReached(uint256 maxSupplyPerWallet);
    error SaleNotStarted(uint256 startTime);
    error SaleHasEnded(uint256 endTime, uint256 currentTime);
    error ReleasesIsNotRegistered();
    error OnlySellerCanWithdraw();

    /**
     * @dev Constructor
     * @param treasury_ - The address of the organizations treasury
     * @param treasuryFee_ - The percentage that will be transferred
     * to the treasury on each sale. Based on a denominator of 10_000 e.g. 1000 = 10%
     * @param token - A token that implements an IERC20 interface that will be used for payments
     * @param catalog - A contract that implements the IReleasesRegistration interface
     */
    constructor(address payable treasury_, uint256 treasuryFee_, IERC20 token, IRegistry registry) {
        if (address(token) == address(0)) revert CannotBeZeroAddress();
        if (treasuryFee_ == 0) revert TreasuryFeeCannotBeZero();
        if (treasury_ == address(0)) revert CannotBeZeroAddress();
        treasury = treasury_;
        treasuryFee = treasuryFee_;
        _token = token;
        _registry = registry;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // External Functions

    /**
     * @dev Create a sale for a given release. The tokens must come from a releases contract
     * that has been registered in the Catalog and they must be in the sellers wallet.
     * @param releaseOwner - The address of the release owner
     * @param beneficiary - The address that will receive the funds once the sale is completed
     * @param releases - A contract that implements the IReleases interface
     * @param tokenId - The id of the Token
     * @param amountTotal - The amount of tokens to sell
     * @param pricePerToken - The price per token
     * @param startAt - The start time of the sale
     * @param endAt - The end time of the sale, set to 0 for no end time
     * @param maxCountPerWallet - The maximum amount of tokens that can be purchased per wallet
     */
    function createSale(
        address releaseOwner,
        address payable beneficiary,
        IReleases releases,
        uint256 tokenId,
        uint256 amountTotal,
        uint256 pricePerToken,
        uint256 startAt,
        uint256 endAt,
        uint256 maxCountPerWallet
    ) external {
        if (IReleasesRegistration(_catalog).getReleasesOwner(address(releases)) == address(0)) {
            revert ReleasesIsNotRegistered();
        }
        if (beneficiary == address(0)) revert CannotBeZeroAddress();
        if (amountTotal == 0) revert TokenAmountCannotBeZero();
        if (endAt != 0 && startAt > endAt) {
            revert StartCannotBeAfterEnd(startAt, endAt);
        }
        if (maxCountPerWallet == 0) revert MaxCountCannotBeZero();
        IERC1155(address(releases)).safeTransferFrom(
            _msgSender(), address(this), tokenId, amountTotal, ""
        );

        sales[releaseOwner].push(
            Sale({
                seller: _msgSender(),
                releaseOwner: releaseOwner,
                beneficiary: beneficiary,
                releases: address(releases),
                tokenId: tokenId,
                amountRemaining: amountTotal,
                amountTotal: amountTotal,
                pricePerToken: pricePerToken,
                startAt: startAt,
                endAt: endAt,
                maxCountPerWallet: maxCountPerWallet
            })
        );

        emit SaleCreated(releaseOwner, sales[releaseOwner].length - 1);
    }

    /**
     * @dev Purchase a release. Payment is in USDC.
     * @param releaseOwner - The address of the release owner
     * @param saleId - The id of the sale
     * @param tokenAmount - The amount of tokens to purchase
     * @param recipient - The address that will receive the Tokens
     */
    function purchase(
        address releaseOwner,
        uint256 saleId,
        uint256 tokenAmount,
        address recipient
    ) external nonReentrant {
        Sale storage sale = _getSaleForPurchase(releaseOwner, saleId, tokenAmount);

        uint256 totalPrice = sale.pricePerToken * tokenAmount;
        uint256 fee = (treasuryFee * totalPrice) / 10_000;
        _token.safeTransferFrom(_msgSender(), address(this), totalPrice);
        _token.transfer(treasury, fee);
        _token.transfer(sale.beneficiary, totalPrice - fee);

        _transferTokens(sale.releases, sale.tokenId, tokenAmount, recipient);

        sale.amountRemaining -= tokenAmount;

        emit Purchase(
            sale.releases, sale.tokenId, recipient, releaseOwner, saleId, tokenAmount, block.timestamp
        );
    }

    /**
     * @dev Withdraw a Release. Caller must own the release.
     * @param releaseOwner - The address of the release owner
     * @param saleId - The id of the sale
     * @param tokenAmount - The amount of tokens to withdraw
     */
    function withdraw(address releaseOwner, uint256 saleId, uint256 tokenAmount) external nonReentrant {
        if (tokenAmount == 0) revert TokenAmountCannotBeZero();
        Sale storage sale = sales[releaseOwner][saleId];
        if (_msgSender() != sale.seller) revert OnlySellerCanWithdraw();
        if (tokenAmount > sale.amountRemaining) {
            revert InsufficientSupply(sale.amountRemaining);
        }
        _transferTokens(sale.releases, sale.tokenId, tokenAmount, _msgSender());

        sale.amountRemaining -= tokenAmount;

        emit Withdraw(_msgSender(), saleId, tokenAmount);
    }

    /**
     * @dev Returns a Sale
     * @param releaseOwner - The address of the release owner
     * @param saleId - The id of the sale
     */
    function getSale(address releaseOwner, uint256 saleId) external view returns (Sale memory) {
        return sales[releaseOwner][saleId];
    }

    /**
     * @dev Returns the number of sales for a given release owner
     * @param releaseOwner - The address of the release owner
     */
    function saleCount(address releaseOwner) external view returns (uint256) {
        return sales[releaseOwner].length;
    }

    /**
     * @dev Sets the treasury fee
     * @notice Caller must have DEFAULT_ADMIN_ROLE
     * @param newFee - The new treasury fee
     */
    function setTreasuryFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasuryFee = newFee;
    }

    /**
     * @dev Sets the treasury address
     * @notice Caller must have DEFAULT_ADMIN_ROLE
     * @param newTreasury - The new treasury address
     */
    function setTreasury(address payable newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = newTreasury;
    }

    // Public

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC1155Holder)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Internal

    /**
     * @dev Verifies the purchase process for a sale
     * @param releaseOwner - The address of the releaseOwner
     * @param saleId - The id of the sale
     * @param tokenAmount - The amount of tokens to purchase
     */
    function _getSaleForPurchase(
        address releaseOwner,
        uint256 saleId,
        uint256 tokenAmount
    ) internal view returns (Sale storage) {
        Sale storage sale = sales[releaseOwner][saleId];
        if (sale.startAt > block.timestamp) {
            revert SaleNotStarted(sale.startAt);
        }
        if (sale.endAt != 0 && sale.endAt < block.timestamp) {
            revert SaleHasEnded(sale.endAt, block.timestamp);
        }
        if (tokenAmount == 0) revert TokenAmountCannotBeZero();
        if (tokenAmount > sale.amountRemaining) {
            revert InsufficientSupply(sale.amountRemaining);
        }

        uint256 buyerBalance = IERC1155(sale.releases).balanceOf(_msgSender(), sale.tokenId);
        if ((buyerBalance + tokenAmount) > sale.maxCountPerWallet) {
            revert MaxSupplyReached(sale.maxCountPerWallet);
        }
        return sale;
    }

    /**
     * @dev Transfers Release tokens from the contract to the recipient
     * @param releases - The address of the Releases contract
     * @param tokenId - The id of the token
     * @param tokenAmount - The amount of tokens to transfer
     * @param recipient - The address that will receive the Tokens
     */
    function _transferTokens(
        address releases,
        uint256 tokenId,
        uint256 tokenAmount,
        address recipient
    ) internal {
        IERC1155(releases).safeTransferFrom(address(this), recipient, tokenId, tokenAmount, "");
    }
}
