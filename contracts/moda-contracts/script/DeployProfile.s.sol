// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Profile} from "../src/Profile.sol";

contract CounterScript is Script {
    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        Profile profile = new Profile("ModaProfile", "MODAPROFILE");
        vm.stopBroadcast();
        console2.log("Profile address", address(profile));
    }
}
