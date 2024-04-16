// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {RegistryTestSetUp} from "./RegistryTestSetUp.t.sol";
import {Registry} from "../../src/Registry.sol";
import {IArtistRegistration} from "../../src/interfaces/Registry/IArtistRegistration.sol";
import {console2} from "forge-std/Test.sol";

contract RegisterArtistTest is RegistryTestSetUp {
    event ArtistRegistered(string id, string artistMetadataHash);

    function test_registerArtist() public {
        registerArtist_setUp();

        (string memory metadataHash, IArtistRegistration.ArtistStatus status) =
            registry.getArtistAtIndex(1);

        assertEq(metadataHash, artistMetadataHash);
        assertEq(uint256(status), uint256(IArtistRegistration.ArtistStatus.VERIFIED));
        assertEq(registry.getArtistId(artistMetadataHash), "ARTIST-DROP-31337-1");
        assertEq(registry.isArtistController(artist, 1), true);
        assertEq(registry.isArtistController(artistController, 1), true);
    }

    function test_registerArtist_RevertsIf_artist_already_registered() public {
        registerArtist_setUp();

        vm.expectRevert(Registry.ArtistAlreadyRegistered.selector);
        vm.startPrank(artist);
        registry.registerArtist(artistMetadataHash, artistControllers);
        vm.stopPrank();
    }

    function test_registerArtist_RevertIf_user_not_member() public {
        vm.expectRevert(Registry.MembershipRequired.selector);
        address nonMember = address(0x9);
        vm.startPrank(nonMember);
        registry.registerArtist(artistMetadataHash, artistControllers);
        vm.stopPrank();
    }

    function test_registerArtist_emits_event() public {
        vm.expectEmit(true, true, true, true);
        emit ArtistRegistered("ARTIST-DROP-31337-1", artistMetadataHash);

        vm.startPrank(artist);
        registry.registerArtist(artistMetadataHash, artistControllers);
        vm.stopPrank();
    }
}
