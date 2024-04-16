// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {RegistryTestSetUp} from "./Registry/RegistryTestSetUp.t.sol";
import {IReleases} from "../src/interfaces/Releases/IReleases.sol";

contract ReleasesTest is RegistryTestSetUp {
    error InvalidInitialization();

    event ReleaseCreated(uint256 tokenId);
    event ReleaseWithdrawn(address indexed receiver, uint256 tokenId, uint256 amount);
    event URI(string value, uint256 indexed id);

    // Initialization

    function test_initialize() public {}

    function test_initialize_RevertIf_already_initialized() public {}

    // create release

    function test_create() public {}

    function test_create_RevertIf_caller_is_not_release_admin() public {}

    function test_create_RevertIf_royalty_amount_is_over_2000() public {}

    function test_create_emits_event() public {}

    // withdrawRelease

    function test_withdrawRelease() public {}

    function test_withdrawRelease_RevertIf_tokenId_is_invalid() public {}

    function test_withdrawRelease_emits_event() public {}

    // setUri

    function test_setUri() public {}

    function test_setUri_RevertIf_tokenId_is_invalid() public {}

    function test_setUri_emits_event() public {}

    // royaltyInfo

    function test_royaltyInfo() public {}

    // supportsInterface

    function test_supportsInterface() public view {}
}
