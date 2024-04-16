// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {ReleasesFactory} from "../src/ReleasesFactory.sol";
import {Registry} from "../src/Registry.sol";
import {Releases} from "../src/Releases.sol";
import {DeployedContracts} from "./utils/DeployedContracts.sol";
import {ISplitsFactory} from "../src/interfaces/ISplitsFactory.sol";

contract DeployReleasesFactory is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        Releases releases = new Releases();
        ReleasesFactory factory = new ReleasesFactory(address(releases));

        vm.stopBroadcast();
    }
}
