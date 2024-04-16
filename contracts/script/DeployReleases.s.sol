// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Script, console2} from "forge-std/Script.sol";
import {IReleasesFactory} from "../src/interfaces/Releases/IReleasesFactory.sol";
import {IReleasesInitialize} from "../src/interfaces/Releases/IReleasesInitialize.sol";
import {DeployedContracts} from "./utils/DeployedContracts.sol";

contract DeployReleases is Script {
    function run() public {
        uint256 privateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address releaseAdmin = vm.envAddress("RELEASE_ADMIN");
        string memory releaseName = vm.envString("RELEASE_NAME");
        string memory releaseSymbol = vm.envString("RELEASE_SYMBOL");
        address[] memory releaseAdmins = new address[](1);
        releaseAdmins[0] = releaseAdmin;

        vm.startBroadcast(privateKey);

        IReleasesFactory releasesFactory =
            IReleasesFactory(DeployedContracts.getAt("DeployReleasesFactory.s.sol", block.chainid, 2));
        console2.log("ReleasesFactory address", address(releasesFactory));

        releasesFactory.create(releaseName, releaseSymbol);

        vm.stopBroadcast();
    }
}
