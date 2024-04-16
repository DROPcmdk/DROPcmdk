// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import "../src/SplitsFactory.sol";
import "../src/interfaces/0xSplits/ISplitMain.sol";
import {DeployedContracts} from "./utils/DeployedContracts.sol";

contract DeploySplitsFactory is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address treasury = vm.envAddress("TREASURY_ADDRESS");
        uint32 treasuryFee = uint32(vm.envUint("TREASURY_FEE"));
        ISplitMain splitMain = ISplitMain(vm.envAddress("SPLIT_MAIN_ADDRESS"));

        vm.startBroadcast(privateKey);

        SplitsFactory splitsFactory = new SplitsFactory(splitMain, treasury, treasuryFee);

        console2.log("SplitsFactory deployed at:", address(splitsFactory));

        vm.stopBroadcast();
    }
}
