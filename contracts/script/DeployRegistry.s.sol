// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {DeployedContracts} from "./utils/DeployedContracts.sol";
import "../src/Registry.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployRegistry is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address admin = vm.addr(privateKey);

        console2.log("Deploying Registry with admin:", admin);

        IMembership membership =
            IMembership(DeployedContracts.get("DeployMembership.s.sol", block.chainid));
        ISplitsFactory splitsFactory =
            ISplitsFactory(DeployedContracts.get("DeploySplitsFactory.s.sol", block.chainid));

        vm.startBroadcast(privateKey);
        address beacon = Upgrades.deployBeacon("Registry.sol:Registry", admin);

        Registry registry = Registry(
            Upgrades.deployBeaconProxy(
                beacon,
                abi.encodeCall(Registry.initialize, (admin, "DropRegistry", membership, splitsFactory))
            )
        );

        console2.log("Registry deployed at:", address(registry));

        vm.stopBroadcast();
    }
}
