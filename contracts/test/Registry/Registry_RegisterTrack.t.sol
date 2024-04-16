// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {RegistryTestSetUp} from "./RegistryTestSetUp.t.sol";
import {Registry} from "../../src/Registry.sol";
import {ITrackRegistration} from "../../src/interfaces/Registry/ITrackRegistration.sol";
import {IArtistRegistration} from "../../src/interfaces/Registry/IArtistRegistration.sol";

contract RegisterTrackTest is RegistryTestSetUp {
    event TrackRegistered(
        string trackId,
        uint256[] artistIndexes,
        string trackMetadataHash,
        address indexed beneficiary,
        address indexed trackRegisterer
    );

    function test_registerTrack() public {
        registerArtist_setUp();
        registerTrack_setUp();

        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 1;

        (
            uint256[] memory artistIndexes_,
            string memory trackMetadataHash_,
            address trackBeneficiary_,
            ITrackRegistration.TrackStatus status
        ) = registry.getTrackAtIndex(1);

        assertEq(artistIndexes_, indexes);
        assertEq(trackMetadataHash_, trackMetadataHash);
        assertEq(trackBeneficiary_, trackBeneficiary);
        assertEq(uint256(status), uint256(ITrackRegistration.TrackStatus.PENDING));
        assertEq(registry.getTrackId(trackMetadataHash), "TRACK-DROP-31337-1");
    }

    function test_registerTrack_RevertIf_track_already_registered() public {
        registerArtist_setUp();
        registerTrack_setUp();

        vm.expectRevert(Registry.TrackAlreadyRegistered.selector);
        vm.startPrank(artist);
        registry.registerTrack(artistIndexes, trackMetadataHash, trackBeneficiary, trackControllers);
        vm.stopPrank();
    }

    function test_registerTrack_RevertIf_user_not_member() public {
        vm.expectRevert(Registry.MembershipRequired.selector);
        vm.startPrank(nonMember);
        registry.registerTrack(artistIndexes, trackMetadataHash, trackBeneficiary, trackControllers);
        vm.stopPrank();
    }

    function test_registerTrack_RevertIf_user_is_not_artist_controller() public {
        registerArtist_setUp();

        vm.expectRevert(Registry.CallerDoesNotHavePermission.selector);
        vm.startPrank(nonController);
        registry.registerTrack(artistIndexes, trackMetadataHash, trackBeneficiary, trackControllers);
        vm.stopPrank();
    }

    function test_registerTrack_emits_event() public {
        registerArtist_setUp();

        uint256[] memory indexes = new uint256[](1);
        indexes[0] = 1;

        vm.expectEmit(true, true, true, true);
        emit TrackRegistered("TRACK-DROP-31337-1", indexes, trackMetadataHash, trackBeneficiary, artist);

        vm.startPrank(artist);
        registry.registerTrack(artistIndexes, trackMetadataHash, trackBeneficiary, trackControllers);
        vm.stopPrank();
    }
}
