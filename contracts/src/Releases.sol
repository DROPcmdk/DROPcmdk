// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IReleases} from "./interfaces/Releases/IReleases.sol";
import {IReleasesInitialize} from "./interfaces/Releases/IReleasesInitialize.sol";
import {IRegistry} from "./interfaces/Registry/IRegistry.sol";
import {IWithdrawRelease} from "./interfaces/Releases/IWithdrawRelease.sol";

/**
 * @notice Releases is a contract to allow artists or labels to create track or multiple
 * track tokens called a "Release".
 */
contract Releases is
    IReleasesInitialize,
    IReleases,
    IWithdrawRelease,
    ERC1155SupplyUpgradeable,
    ERC1155HolderUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable
{
    // State Variables

    uint256 constant MAX_ROYALTY_AMOUNT = 2_000;

    string public name;
    string public symbol;

    uint256 public numberOfReleases;

    mapping(uint256 => string) _metadataUris;

    // Errors
    error CannotBeZeroAddress();
    error InvalidRoyaltyAmount();
    error FieldCannotBeEmpty(string field);
    error InvalidTokenId();

    /// @dev users with a Releases admin role can create releases with a curated contract
    bytes32 public constant RELEASE_ADMIN_ROLE = keccak256("RELEASE_ADMIN_ROLE");

    /**
     * @dev Constructor
     * @notice The initializer is disabled when deployed as an implementation contract
     */
    constructor() {
        _disableInitializers();
    }

    // External Functions

    /**
     * @dev Initializes the contract
     * @param name_ - The name of the Releases contract
     * @param symbol_ - The symbol of the Releases contract
     */
    function initialize(
        address admin,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __ERC1155_init("");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        if (admin == address(0)) revert CannotBeZeroAddress();
        if (bytes(name_).length == 0) revert FieldCannotBeEmpty("name");
        if (bytes(symbol_).length == 0) revert FieldCannotBeEmpty("symbol");
        name = name_;
        symbol = symbol_;
    }

    /// @inheritdoc IReleases
    function create(
        address receiver,
        address beneficiary,
        uint96 royaltyAmount,
        uint256 totalSupply,
        string calldata metadataUri
    ) external {
        if (royaltyAmount > MAX_ROYALTY_AMOUNT) revert InvalidRoyaltyAmount();

        numberOfReleases++;

        _metadataUris[numberOfReleases] = metadataUri;

        _setTokenRoyalty(numberOfReleases, beneficiary, royaltyAmount);
        _mint(receiver, numberOfReleases, totalSupply, "");

        emit ReleaseCreated(numberOfReleases);
    }

    /// @inheritdoc IWithdrawRelease
    function withdrawRelease(address receiver, uint256 tokenId, uint256 amount) external {
        if (tokenId > numberOfReleases) revert InvalidTokenId();
        _safeTransferFrom(address(this), receiver, tokenId, amount, "");
        emit ReleaseWithdrawn(msg.sender, tokenId, amount);
    }

    // Public Functions

    /**
     * @dev See {IERC1155-uri}.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId > numberOfReleases) revert InvalidTokenId();

        return _metadataUris[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            IERC165,
            ERC1155Upgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable,
            ERC1155HolderUpgradeable
        )
        returns (bool)
    {
        return interfaceId == type(IReleases).interfaceId || super.supportsInterface(interfaceId);
    }
}
