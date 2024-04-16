// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ReleasesFactory} from "../src/ReleasesFactory.sol";
import {Releases} from "../src/Releases.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract ReleasesFactoryTest is Test {
    Releases public releasesMaster;
    ReleasesFactory public releasesFactory;

    address public admin = address(0xa);

    string name = "DRIP";
    string symbol = "DRIP";

    function setUp() public {
        releasesMaster = new Releases();
        releasesFactory = new ReleasesFactory(address(releasesMaster));
    }

    function test_constructor() public {}

    function test_create() public {}
}
