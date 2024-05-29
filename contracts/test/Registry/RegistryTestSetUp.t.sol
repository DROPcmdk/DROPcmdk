// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {TestUtils} from "../utils/TestUtils.sol";
import {Registry} from "../../src/Registry.sol";
import {Membership} from "../../test/mocks/MembershipMock.sol";
import {ReleasesFactory} from "../../src/ReleasesFactory.sol";
import {Releases} from "../../src/Releases.sol";
import {SplitsFactoryMock} from "../mocks/SplitsFactoryMock.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IArtistRegistration} from "../../src/interfaces/Registry/IArtistRegistration.sol";
import {ITrackRegistration} from "../../src/interfaces/Registry/ITrackRegistration.sol";

contract RegistryTestSetUp is TestUtils {
    Registry public registry;
    Membership public membership;
    SplitsFactoryMock public splitsFactory;
    ReleasesFactory public releasesFactory;
    Releases public releasesMaster;
    Releases public releases;

    address admin = _w.alice();
    string public registryName = "ACME";
    address public artist = _w.bob();
    address public artistController = _w.eric();
    address public trackVerifier = _w.carl();
    address public mockSplit = _w.dave();
    address public nonController = _w.frank();
    address public nonMember = _w.gary();

    string public artistMetadataHash = "artistHash";
    address[] public artistControllers = [artist, artistController];

    address public trackBeneficiary = _w.dave();
    string public trackMetadataHash = "trackHash";
    address[] public trackControllers = [artist, artistController];
    uint256[] public artistIndexes = [1];

    string releaseMetadataHash = "releaseHash";
    uint256[] public trackIndexes = [1];
    address[] releaseControllers = [artist, artistController];

    function setUp() public {
        membership = new Membership();
        splitsFactory = new SplitsFactoryMock(mockSplit);

        address beacon = Upgrades.deployBeacon("Registry.sol:Registry", admin);

        registry = Registry(
            Upgrades.deployBeaconProxy(
                beacon,
                abi.encodeCall(Registry.initialize, (admin, "DropRegistry", membership, splitsFactory))
            )
        );

        releasesMaster = new Releases();
        releasesFactory = new ReleasesFactory(address(releasesMaster));
        vm.startPrank(admin);
        registry.grantRole(keccak256("RELEASES_REGISTRAR_ROLE"), address(releasesFactory));
        registry.grantRole(keccak256("VERIFIER_ROLE"), admin);
        vm.stopPrank();

        membership.addMember(admin);
        membership.addMember(artist);
        membership.addMember(artistController);
        membership.addMember(nonController);

        vm.startPrank(artist);
        address releasesAddress = releasesFactory.create("name", "symbol");
        vm.stopPrank();

        releases = Releases(releasesAddress);
    }

    function registerArtist_setUp() public {
        vm.startPrank(artist);
        registry.registerArtist(artistMetadataHash, artistControllers);
        vm.startPrank(admin);
        registry.setArtistStatus(1, IArtistRegistration.ArtistStatus.VERIFIED);
        vm.stopPrank();
    }

    function registerTrack_setUp() public {
        vm.startPrank(artist);
        registry.registerTrack(artistIndexes, trackMetadataHash, trackBeneficiary, trackControllers);
        vm.stopPrank();
    }

    function verifyTrack_setUp() public {
        vm.startPrank(admin);
        registry.setTrackStatus(1, ITrackRegistration.TrackStatus.VERIFIED);
        vm.stopPrank();
    }

    function registeringRelease_setUp() public {
        vm.startPrank(artist);
        registry.registerRelease(releaseMetadataHash, trackIndexes, releaseControllers);
    }
}
