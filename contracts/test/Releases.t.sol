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

    function test_initialize() public {
        vm.skip(true);
    }

    function test_initialize_RevertIf_already_initialized() public {
        vm.skip(true);
    }

    // create release

    function test_create() public {
        vm.skip(true);
    }

    function test_create_RevertIf_caller_is_not_release_admin() public {
        vm.skip(true);
    }

    function test_create_RevertIf_royalty_amount_is_over_2000() public {
        vm.skip(true);
    }

    function test_create_emits_event() public {
        vm.skip(true);
    }

    // withdrawRelease

    function test_withdrawRelease() public {
        vm.skip(true);
    }

    function test_withdrawRelease_RevertIf_tokenId_is_invalid() public {
        vm.skip(true);
    }

    function test_withdrawRelease_emits_event() public {
        vm.skip(true);
    }

    // setUri

    function test_setUri() public {
        vm.skip(true);
    }

    function test_setUri_RevertIf_tokenId_is_invalid() public {
        vm.skip(true);
    }

    function test_setUri_emits_event() public {
        vm.skip(true);
    }

    // royaltyInfo

    function test_royaltyInfo() public {
        vm.skip(true);
    }

    // supportsInterface

    function test_supportsInterface() public {
        vm.skip(true);
    }
}
