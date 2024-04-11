// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IReleases} from "./interfaces/Releases/IReleases.sol";
import {IRegistry} from "./interfaces/Registry/IRegistry.sol";
import {IMembership} from "./interfaces/IMembership.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice A Catalog is a contract where artists and labels can register tracks.
///         Membership to the Catalog is controlled by `IMembership`.
contract Registry is IRegistry, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice an address with AUTO_VERIFIED_ROLE will have their tracks verified on registration
    bytes32 public constant AUTO_VERIFIED_ROLE = keccak256("AUTO_VERIFIED_ROLE");

    /// @custom:storage-location erc7201:moda.storage.Catalog
    struct CatalogStorage {
        IMembership _membership;
        address _releases;
        string _name;
        uint256 _trackCount;
        /// @dev trackRegistrationHash => trackId
        mapping(string => string) _trackIds;
        /// @dev trackId => RegisteredTrack
        mapping(string => RegisteredTrack) _registeredTracks;
        /// @dev trackId => trackAccess
        mapping(string => EnumerableSet.AddressSet) _trackAccess;
        /// @dev releasesOwner => releases
        mapping(address => address) _registeredReleasesContracts;
        /// @dev release => releaseOwner
        mapping(address => address) _registeredReleasesOwners;
        /// @dev releaseHash => RegisteredRelease
        mapping(bytes32 => RegisteredRelease) _registeredReleases;
        /// @dev tokenId => tracks on release
        mapping(uint256 => string[]) _releaseTracks;
        /// @dev tokenId => uri
        mapping(uint256 => string) _releaseUris;
    }

    // Errors

    error TrackIsNotRegistered();
    error TrackAlreadyRegistered();
    error TrackIsInvalid();
    error ReleasesContractIsNotOfficial();
    error ReleaseAlreadyCreated();
    error MembershipRequired();
    error MustBeTrackAdmin();
    error AccountDoesNotHaveTrackAccess();
    error VerifierRoleRequired();
    error AddressCannotBeZero();

    // Storage location

    // keccak256(abi.encode(uint256(keccak256("moda.storage.Catalog")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CatalogStorageLocation =
        0x29716ba11260d206d72844135e3b7e5c7c3a8e39cde3c7b2b654f553db068900;

    function _getCatalogStorage() private pure returns (CatalogStorage storage $) {
        assembly {
            $.slot := CatalogStorageLocation
        }
    }

    /**
     * @notice The initializer is disabled when deployed as an implementation contract
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    // External Functions

    /**
     * @notice Initializes the contract
     * @param owner The account that will gain ownership.
     * @param name The name of the Catalog
     * @param membership A custom contract to gate user access.
     */
    function initialize(
        address owner,
        string calldata name,
        IMembership membership
    ) external initializer {
        CatalogStorage storage $ = _getCatalogStorage();
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        $._name = name;
        $._membership = membership;
    }

    function setOfficialReleasesContract(address releases) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CatalogStorage storage $ = _getCatalogStorage();

        if ($._releases != address(0)) {
            revert AddressCannotBeZero();
        }
        $._releases = releases;
    }

    /// @inheritdoc IRegistry
    function registerTrack(address trackBeneficiary, string calldata trackRegistrationHash) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireTrackIsNotRegistered(trackRegistrationHash);
        _requireMembership(msg.sender);

        string memory id = string(
            abi.encodePacked(
                $._name, "-", Strings.toString(block.chainid), "-", Strings.toString($._trackCount)
            )
        );
        $._trackIds[trackRegistrationHash] = id;

        bool hasAutoVerification = hasRole(AUTO_VERIFIED_ROLE, msg.sender);

        TrackStatus status = hasAutoVerification ? TrackStatus.VALIDATED : TrackStatus.PENDING;

        $._trackAccess[id].add(msg.sender);

        $._registeredTracks[id] = RegisteredTrack(
            status, msg.sender, trackBeneficiary, trackRegistrationHash, "", "", address(0)
        );
        $._trackCount++;

        emit TrackRegistered(trackRegistrationHash, id, msg.sender);
    }

    /// @inheritdoc IRegistry
    function getTrack(string calldata trackId) external view returns (RegisteredTrack memory) {
        CatalogStorage storage $ = _getCatalogStorage();

        return $._registeredTracks[trackId];
    }

    /// @inheritdoc IRegistry
    function getTrackId(string calldata trackRegistrationHash) external view returns (string memory) {
        CatalogStorage storage $ = _getCatalogStorage();

        return $._trackIds[trackRegistrationHash];
    }

    /// @inheritdoc IRegistry
    function setTrackStatus(string calldata trackId, TrackStatus status) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireVerifierRole(msg.sender);
        _requireTrackIsRegistered(trackId);

        RegisteredTrack storage track = $._registeredTracks[trackId];
        track.trackStatus = status;
        track.trackVerifier = msg.sender;

        emit TrackUpdated(
            status,
            track.trackAdmin,
            track.trackBeneficiary,
            track.trackRegistrationHash,
            track.fingerprintHash,
            track.validationHash,
            msg.sender
        );
    }

    /// @inheritdoc IRegistry
    function setTrackBeneficiary(string calldata trackId, address newTrackBeneficiary) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireTrackIsRegistered(trackId);
        RegisteredTrack storage track = $._registeredTracks[trackId];
        _requireTrackAccess(trackId, msg.sender);
        track.trackBeneficiary = newTrackBeneficiary;
        emit TrackUpdated(
            track.trackStatus,
            track.trackAdmin,
            newTrackBeneficiary,
            track.trackRegistrationHash,
            track.fingerprintHash,
            track.validationHash,
            track.trackVerifier
        );
    }

    /// @inheritdoc IRegistry
    function setTrackMetadata(
        string calldata trackId,
        string calldata newTrackRegistrationHash
    ) external {
        _requireTrackIsRegistered(trackId);
        CatalogStorage storage $ = _getCatalogStorage();

        RegisteredTrack storage track = $._registeredTracks[trackId];
        _requireTrackAccess(trackId, msg.sender);
        track.trackRegistrationHash = newTrackRegistrationHash;

        emit TrackUpdated(
            track.trackStatus,
            track.trackAdmin,
            track.trackBeneficiary,
            newTrackRegistrationHash,
            track.fingerprintHash,
            track.validationHash,
            track.trackVerifier
        );
    }

    /// @inheritdoc IRegistry
    function setTrackFingerprintHash(
        string calldata trackId,
        string calldata fingerprintHash
    ) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireTrackIsRegistered(trackId);
        RegisteredTrack storage track = $._registeredTracks[trackId];
        _requireTrackAccess(trackId, msg.sender);
        track.fingerprintHash = fingerprintHash;
        emit TrackUpdated(
            track.trackStatus,
            track.trackAdmin,
            track.trackBeneficiary,
            track.trackRegistrationHash,
            fingerprintHash,
            track.validationHash,
            track.trackVerifier
        );
    }

    /// @inheritdoc IRegistry
    function setTrackValidationHash(string calldata trackId, string calldata validationHash) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireTrackIsRegistered(trackId);
        RegisteredTrack storage track = $._registeredTracks[trackId];
        _requireTrackAccess(trackId, msg.sender);
        track.validationHash = validationHash;
        emit TrackUpdated(
            track.trackStatus,
            track.trackAdmin,
            track.trackBeneficiary,
            track.trackRegistrationHash,
            track.fingerprintHash,
            validationHash,
            track.trackVerifier
        );
    }

    function addTrackAccess(string calldata trackId, address accessAccount) external {
        CatalogStorage storage $ = _getCatalogStorage();
        if (msg.sender != $._registeredTracks[trackId].trackAdmin) {
            revert MustBeTrackAdmin();
        }
        $._trackAccess[trackId].add(accessAccount);
    }

    function removeTrackAccess(string calldata trackId, address accessAccount) external {
        CatalogStorage storage $ = _getCatalogStorage();
        if (msg.sender != $._registeredTracks[trackId].trackAdmin) {
            revert MustBeTrackAdmin();
        }
        $._trackAccess[trackId].remove(accessAccount);
    }

    /// @inheritdoc IRegistry
    function hasTrackAccess(string calldata trackId, address caller) external view returns (bool) {
        CatalogStorage storage $ = _getCatalogStorage();
        return $._trackAccess[trackId].contains(caller);
    }

    /// @inheritdoc IRegistry
    function registerRelease(
        string[] calldata trackIds,
        string calldata uri,
        uint256 tokenId
    ) external {
        CatalogStorage storage $ = _getCatalogStorage();

        _requireReleasesContractIsOfficial(msg.sender);

        for (uint256 i = 0; i < trackIds.length; i++) {
            _requireTrackIsRegistered(trackIds[i]);
            _requireTrackIsValid(trackIds[i]);

            $._releaseTracks[tokenId].push(trackIds[i]);
        }
        $._releaseUris[tokenId] = uri;
        bytes32 releaseHash = _createReleaseHash(trackIds, uri);
        _requireReleaseNotDuplicate(releaseHash);
        $._registeredReleases[releaseHash] = RegisteredRelease(msg.sender, tokenId, trackIds);
        emit ReleaseRegistered(trackIds, msg.sender, tokenId);
    }

    /// @inheritdoc IRegistry
    function unregisterRelease(bytes32 releaseHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CatalogStorage storage $ = _getCatalogStorage();

        delete $._registeredReleases[releaseHash];
        emit ReleaseUnregistered(releaseHash);
    }

    /// @inheritdoc IRegistry
    function getReleaseTracks(uint256 tokenId) external view returns (string[] memory) {
        CatalogStorage storage $ = _getCatalogStorage();

        return $._releaseTracks[tokenId];
    }

    /// @inheritdoc IRegistry
    function getReleaseHash(uint256 tokenId) external view returns (bytes32) {
        CatalogStorage storage $ = _getCatalogStorage();

        string[] memory trackIds = $._releaseTracks[tokenId];
        string memory uri = $._releaseUris[tokenId];
        bytes32 releaseHash = _createReleaseHash(trackIds, uri);
        return releaseHash;
    }

    /// Public Functions

    /// @inheritdoc IRegistry
    function getRegisteredRelease(bytes32 releaseHash) public view returns (RegisteredRelease memory) {
        CatalogStorage storage $ = _getCatalogStorage();

        return $._registeredReleases[releaseHash];
    }

    /// Internal Functions

    function _requireMembership(address caller) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if (!$._membership.isMember(caller)) revert MembershipRequired();
    }

    function _requireVerifierRole(address account) internal view {
        if (!hasRole(keccak256("VERIFIER_ROLE"), account)) {
            revert VerifierRoleRequired();
        }
    }

    function _requireTrackIsRegistered(string calldata trackId) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if (bytes($._registeredTracks[trackId].trackRegistrationHash).length == 0) {
            revert TrackIsNotRegistered();
        }
    }

    function _requireTrackIsNotRegistered(string calldata trackRegistrationHash) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if (bytes($._trackIds[trackRegistrationHash]).length != 0) {
            revert TrackAlreadyRegistered();
        }
    }

    function _requireTrackIsValid(string calldata trackId) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if ($._registeredTracks[trackId].trackStatus == TrackStatus.INVALIDATED) {
            revert TrackIsInvalid();
        }
    }

    function _requireTrackAccess(string calldata trackId, address caller) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if (!$._trackAccess[trackId].contains(caller)) {
            revert AccountDoesNotHaveTrackAccess();
        }
    }

    function _requireReleaseNotDuplicate(bytes32 releaseHash) internal view {
        if (getRegisteredRelease(releaseHash).releases != address(0)) {
            revert ReleaseAlreadyCreated();
        }
    }

    function _requireReleasesContractIsOfficial(address releases) internal view {
        CatalogStorage storage $ = _getCatalogStorage();

        if (releases != $._releases) {
            revert ReleasesContractIsNotOfficial();
        }
    }

    function _createReleaseHash(
        string[] memory trackIds,
        string memory uri
    ) internal pure returns (bytes32) {
        bytes memory packedHashes = _packStringArray(trackIds);
        return keccak256(abi.encode(packedHashes, uri));
    }

    function _packStringArray(string[] memory array) internal pure returns (bytes memory) {
        bytes memory packedBytes = "";
        for (uint256 i = 0; i < array.length; i++) {
            packedBytes = abi.encode(packedBytes, array[i]);
        }
        return packedBytes;
    }
}
