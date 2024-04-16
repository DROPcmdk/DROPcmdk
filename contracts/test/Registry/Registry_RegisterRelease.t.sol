// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {RegistryTestSetUp} from "./RegistryTestSetUp.t.sol";
import {Registry} from "../../src/Registry.sol";
import {ITrackRegistration} from "../../src/interfaces/Registry/ITrackRegistration.sol";
import {console2} from "forge-std/Test.sol";

contract RegisterReleaseTest is RegistryTestSetUp {
    event ReleaseRegistered(string releaseId, uint256[] trackIndexes, address registrerer);
    event ReleaseUnregistered(string releaseId);

    function test_registerRelease() public {
        registerArtist_setUp();
        registerTrack_setUp();
        verifyTrack_setUp();
        registeringRelease_setUp();

        (
            string memory releaseMetadataHash_,
            address beneficiary,
            Registry.ReleaseTrack[] memory releaseTracks
        ) = registry.getReleaseAtIndex(1);

        string memory releaseId = registry.getReleaseId(releaseMetadataHash);

        assertEq(releaseMetadataHash_, releaseMetadataHash);
        assertEq(beneficiary, mockSplit);
        assertEq(releaseId, "RELEASE-DROP-31337-1");
        assertEq(releaseTracks[0].trackIndex, 1);
        assertEq(releaseTracks[0].accessGranted, false);
    }

    function test_registerRelease_RevertIf_tracks_unverified() public {
        registerArtist_setUp();
        registerTrack_setUp();

        vm.expectRevert(Registry.TrackHasNotBeenVerified.selector);

        vm.startPrank(artist);
        registry.registerRelease(
            releaseMetadataHash, trackIndexes, releaseControllers, allowedTokenContracts
        );
    }

    function test_registerRelease_RevertIf_track_not_registered() public {
        uint256[] memory unregisteredTrackIndexes = new uint256[](1);
        unregisteredTrackIndexes[0] = 2;

        vm.expectRevert(Registry.TrackIsNotRegistered.selector);

        vm.startPrank(artist);
        registry.registerRelease(
            releaseMetadataHash, unregisteredTrackIndexes, releaseControllers, allowedTokenContracts
        );
    }

    function test_registerRelease_RevertIf_release_already_created() public {
        registerArtist_setUp();
        registerTrack_setUp();
        verifyTrack_setUp();
        registeringRelease_setUp();

        vm.expectRevert(Registry.ReleaseAlreadyCreated.selector);

        registry.registerRelease(
            releaseMetadataHash, trackIndexes, releaseControllers, allowedTokenContracts
        );
    }

    function test_registerRelease_emits_event() public {
        registerArtist_setUp();
        registerTrack_setUp();
        verifyTrack_setUp();

        vm.startPrank(artist);

        vm.expectEmit(true, true, true, true);
        emit ReleaseRegistered("RELEASE-DROP-31337-1", trackIndexes, artist);
        registry.registerRelease(
            releaseMetadataHash, trackIndexes, releaseControllers, allowedTokenContracts
        );
    }

    // unregisterRelease

    function test_unregisterRelease() public {
        registerArtist_setUp();
        registerTrack_setUp();
        verifyTrack_setUp();
        registeringRelease_setUp();

        vm.startPrank(admin);
        registry.unregisterRelease(1);

        (
            string memory releaseMetadataHash_,
            address beneficiary,
            Registry.ReleaseTrack[] memory releaseTracks
        ) = registry.getReleaseAtIndex(1);

        assertEq(releaseMetadataHash_, "");
        assertEq(beneficiary, address(0));
        assertEq(releaseTracks.length, 0);
    }

    // function test_unregisterRelease_emits_event() public {
    //     registeringRelease_setUp();
    //     vm.startPrank(artist);
    //     registry.setReleasesApprovalForAll(artist, address(releases), true);
    //     vm.stopPrank();
    //     vm.startPrank(address(releases));
    //     registry.registerRelease(
    //         registeringReleaseData.trackIds, registeringReleaseData.uri, registeringReleaseData.tokenId
    //     );
    //     vm.stopPrank();

    //     bytes32 releaseHash = registry.getReleaseHash(address(releases), registeringReleaseData.tokenId);
    //     vm.expectEmit(true, true, true, true);
    //     emit ReleaseUnregistered(releaseHash);
    //     vm.startPrank(admin);
    //     registry.unregisterRelease(releaseHash);
    //     vm.stopPrank();
    // }
}
