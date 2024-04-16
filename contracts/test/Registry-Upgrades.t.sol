// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import "../src/interfaces/IMembership.sol";
import "../src/interfaces/ISplitsFactory.sol";
import {RegistryV2Mock} from "../test/mocks/RegistryV2Mock.sol";
import {Registry} from "../src/Registry.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import {SplitsFactoryMock} from "./mocks/SplitsFactoryMock.sol";

contract RegistryUpgradesTest is Test {
    address public registryImplementation;
    address public registryImplementationV2;
    address public registryProxy;
    address public beacon;

    string public registryName = "Test";
    uint256 public chainId = 0;
    address public deployer = address(0x3);
    IMembership public membership = IMembership(address(0x4));
    SplitsFactoryMock public splitsFactory = SplitsFactoryMock(address(0x5));

    address admin = address(0x4);

    function setUp() public {
        beacon = Upgrades.deployBeacon("Registry.sol:Registry", admin);
        registryImplementation = IBeacon(beacon).implementation();

        registryProxy = Upgrades.deployBeaconProxy(
            beacon, abi.encodeCall(Registry.initialize, (admin, registryName, membership, splitsFactory))
        );
    }

    function test_beacon() public view {
        address proxyBeaconAddress = Upgrades.getBeaconAddress(registryProxy);
        assertEq(proxyBeaconAddress, beacon);
    }

    function upgrade_beacon_with_RegistryV2_setUp() public {
        vm.startPrank(admin);
        Upgrades.upgradeBeacon(beacon, "RegistryV2Mock.sol");
        vm.stopPrank();
    }

    function test_implementation_address_updated() public {
        upgrade_beacon_with_RegistryV2_setUp();
        registryImplementationV2 = IBeacon(beacon).implementation();
        assertFalse(registryImplementation == registryImplementationV2);
    }

    function test_proxy_can_call_updated_Registry() public {
        upgrade_beacon_with_RegistryV2_setUp();
        RegistryV2Mock(registryProxy).setTestingUpgradeVariable("upgradeTest");
        string memory upgradeTest = RegistryV2Mock(registryProxy).getTestingUpgradeVariable();
        assertEq(upgradeTest, "upgradeTest");
    }
}
