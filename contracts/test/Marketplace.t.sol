// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RegistryTestSetUp} from "./Registry/RegistryTestSetUp.t.sol";
import {Marketplace} from "../src/Marketplace.sol";
import {ERC20TokenMock} from "./mocks/ERC20TokenMock.sol";
import {IReleases} from "../src/interfaces/Releases/IReleases.sol";

contract MarketplaceTest is Test {
    Marketplace public marketplace;
    ERC20TokenMock public token;

    string name = "TestReleases";
    string symbol = "TEST";
    address admin = address(0x6);
    address beneficiary = address(0x2);
    address recipient = address(0x7);

    address payable treasury = payable(address(0x5));
    uint256 treasuryFee = 1000;

    event SaleCreated(address indexed releaseAdmin, uint256 indexed saleId);
    event Purchase(
        address indexed releases,
        uint256 indexed tokenId,
        address indexed buyer,
        address releaseOwner,
        uint256 saleId,
        uint256 tokenAmount,
        uint256 timestamp
    );

    function setUp() public {
        vm.startPrank(admin);
        token = new ERC20TokenMock();
        marketplace = new Marketplace(token);
    }

    function test_constructor() public {}

    function createSale_setUp() public {}

    function test_createSale() public {}

    function test_createSale_RevertIf_beneficiary_address_is_zero() public {}

    function test_createSale_RevertIf_amountTotal_is_zero() public {}

    function test_createSale_RevertIf_startAt_is_after_endAt() public {}

    function test_createSale_RevertIf_maxCountPerWallet_is_zero() public {}

    function test_createSale_emits_event() public {}

    function test_purchase() public {}

    function test_purchase_RevertIf_Sale_has_not_started() public {}

    function test_purchase_RevertIf_Sale_has_ended() public {}

    function test_purchase_RevertIf_tokenAmount_is_zero() public {}

    function test_purchase_RevertIf_tokenAmount_is_greater_than_amountRemaining() public {}

    function test_purchase_RevertIf_maxCountPerWallet_is_exceeded() public {}

    function test_purchase_emits_event() public {}

    function test_withdraw() public {}
}
