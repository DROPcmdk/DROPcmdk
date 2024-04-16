// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {RegistryTestSetUp} from "./RegistryTestSetUp.t.sol";

contract RegistryInitializeTest is RegistryTestSetUp {
    error InvalidInitialization();

    /// Initialization revert

    function test_initialize_RevertIf_already_initialized() public {
        setUp();
        vm.expectRevert(InvalidInitialization.selector);
        vm.startPrank(admin);
        registry.initialize(admin, registryName, membership, splitsFactory);
        vm.stopPrank();
    }
}
