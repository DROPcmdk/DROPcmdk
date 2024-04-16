// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ITrackRegistration} from "./interfaces/Registry/ITrackRegistration.sol";
import {IArtistRegistration} from "./interfaces/Registry/IArtistRegistration.sol";
import {IReleaseRegistration} from "./interfaces/Registry/IReleaseRegistration.sol";
import {IRegistryInitialize} from "./interfaces/Registry/IRegistryInitialize.sol";
import {IReleasesFactory} from "./interfaces/Releases/IReleasesFactory.sol";
import {IMembership} from "./interfaces/IMembership.sol";
import {IRegistry} from "./interfaces/Registry/IRegistry.sol";
import {ISplitsFactory} from "./interfaces/ISplitsFactory.sol";
import {AccessControlUpgradeable} from
    "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {console2} from "forge-std/Test.sol";

/// @notice A Registry is a contract where users can register artists, tracks, and releases.
///         Membership to the Registry is controlled by `IMembership`.
contract Registry is IRegistry, AccessControlUpgradeable {
    /// @notice only an address with a verifier role can verify a track
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /// @notice only an address with a releases registrar role can register a releases contract
    bytes32 public constant RELEASES_REGISTRAR_ROLE = keccak256("RELEASES_REGISTRAR_ROLE");

    /// @custom:storage-location erc7201:drop.storage.Registry
    struct RegistryStorage {
        IMembership _membership;
        ISplitsFactory _splitsFactory;
        string _name;
        uint256 _artistCount;
        /// @dev artistMetadataHash => artistIndex
        mapping(string => uint256) _artistIndex;
        /// @dev controller address => index[]
        mapping(address => uint256[]) _controllerArtists;
        /// @dev artistIndex => RegisteredArtist
        mapping(uint256 => RegisteredArtist) _registeredArtists;
        uint256 _trackCount;
        /// @dev trackMetadataHash => trackIndex
        mapping(string => uint256) _trackIndex;
        /// @dev controller address => trackIndex[]
        mapping(address => uint256[]) _controllerTracks;
        /// @dev trackIndex => RegisteredTrack
        mapping(uint256 => RegisteredTrack) _registeredTracks;
        uint256 _releaseCount;
        /// @dev releaseMetadataHash => ReleaseIndex
        mapping(string => uint256) _releaseIndex;
        /// @dev releaseIndex => RegisteredRelease
        mapping(uint256 => RegisteredRelease) _registeredReleases;
        /// @dev releases => tokenId => tracks on release
        mapping(address => mapping(uint256 => string[])) _releaseTracks;
        /// @dev tokenId => metadata hash
        mapping(uint256 => string) _tokenMetadataHash;
    }

    // Errors

    error MembershipRequired();
    error ArtistHasNotBeenVerified();
    error ArtistHasBeenRejected();
    error ArtistAlreadyRegistered();
    error TrackIsNotRegistered();
    error TrackAlreadyRegistered();
    error TrackHasNotBeenVerified();
    error TrackHasBeenRejected();
    error ReleaseAlreadyCreated();
    error VerifierRoleRequired();
    error ReleasesRegistrarRoleRequired();
    error CallerDoesNotHavePermission();
    error InvalidTokenContract();

    // Storage location

    // keccak256(abi.encode(uint256(keccak256("drop.storage.Registry")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RegistryStorageLocation =
        0xa5656c55b5ba9e124c34ca40a03cbf80e2cb3c5570304c90cf082d8212e93c00;

    function _getRegistryStorage() private pure returns (RegistryStorage storage $) {
        assembly {
            $.slot := RegistryStorageLocation
        }
    }

    // Modifiers

    modifier onlyMember() {
        RegistryStorage storage $ = _getRegistryStorage();
        if (!$._membership.isMember(msg.sender)) revert MembershipRequired();
        _;
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
     * @inheritdoc IRegistryInitialize
     */
    function initialize(
        address owner,
        string calldata name,
        IMembership membership,
        ISplitsFactory splitsFactory
    ) external initializer {
        RegistryStorage storage $ = _getRegistryStorage();
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        $._name = name;
        $._membership = membership;
        $._splitsFactory = splitsFactory;
    }

    // Artist Registration

    /// @inheritdoc IArtistRegistration
    function registerArtist(
        string calldata artistMetadataHash,
        address[] calldata controllers
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if ($._artistIndex[artistMetadataHash] != 0) revert ArtistAlreadyRegistered();

        $._artistCount++;

        $._artistIndex[artistMetadataHash] = $._artistCount;
        $._registeredArtists[$._artistCount].artistMetadataHash = artistMetadataHash;
        $._registeredArtists[$._artistCount].artistStatus = ArtistStatus.PENDING;

        for (uint256 i = 0; i < controllers.length; i++) {
            $._registeredArtists[$._artistCount].controllers[controllers[i]] = true;
            $._controllerArtists[controllers[i]].push($._artistCount);
        }

        emit ArtistRegistered(_createId("ARTIST", $._artistCount), artistMetadataHash);
    }

    /// @inheritdoc IArtistRegistration
    function getArtistAtIndex(uint256 artistIndex)
        external
        view
        returns (string memory artistMetadataHash, ArtistStatus status)
    {
        RegistryStorage storage $ = _getRegistryStorage();

        return (
            $._registeredArtists[artistIndex].artistMetadataHash,
            $._registeredArtists[artistIndex].artistStatus
        );
    }

    /// @inheritdoc IArtistRegistration
    function getArtistId(string calldata artistMetadataHash) external view returns (string memory) {
        RegistryStorage storage $ = _getRegistryStorage();
        uint256 index = $._artistIndex[artistMetadataHash];
        return _createId("ARTIST", index);
    }

    /// @inheritdoc IArtistRegistration
    function setArtistMetadataHash(
        uint256 artistIndex,
        string calldata newArtistMetadataHash
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        _requireCallerIsArtistController(artistIndex, msg.sender);

        $._registeredArtists[artistIndex].artistMetadataHash = newArtistMetadataHash;

        emit ArtistUpdated(
            msg.sender,
            _createId("ARTIST", artistIndex),
            newArtistMetadataHash,
            $._registeredArtists[artistIndex].artistStatus
        );
    }

    /// @inheritdoc IArtistRegistration
    function setArtistStatus(uint256 artistIndex, ArtistStatus status) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        _requireVerifierRole(msg.sender);
        $._registeredArtists[artistIndex].artistStatus = status;

        emit ArtistUpdated(
            msg.sender,
            _createId("ARTIST", artistIndex),
            $._registeredArtists[artistIndex].artistMetadataHash,
            status
        );
    }

    /// @inheritdoc IArtistRegistration
    function setArtistController(
        uint256 artistIndex,
        address controller,
        bool isController
    ) external onlyMember {
        _requireCallerIsArtistController(artistIndex, msg.sender);

        RegistryStorage storage $ = _getRegistryStorage();

        if (isController != $._registeredArtists[artistIndex].controllers[controller]) {
            $._registeredArtists[artistIndex].controllers[controller] = isController;
            emit ArtistControllerUpdated(_createId("ARTIST", artistIndex), controller, true);
        }
    }

    /// @inheritdoc IArtistRegistration
    function isArtistController(address account, uint256 artistIndex) external view returns (bool) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._registeredArtists[artistIndex].controllers[account];
    }

    //TODO add get artist tracks

    /// @inheritdoc IArtistRegistration
    function getArtistsForController() external view returns (uint256[] memory) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._controllerArtists[msg.sender];
    }

    // Track Registration

    /// @inheritdoc ITrackRegistration
    function registerTrack(
        uint256[] memory artistIndexes,
        string calldata trackMetadataHash,
        address beneficiary,
        address[] calldata controllers
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        for (uint256 i = 0; i < artistIndexes.length; i++) {
            _requireArtistVerified(artistIndexes[i]);
            _requireCallerIsArtistController(artistIndexes[i], msg.sender);
        }

        if ($._trackIndex[trackMetadataHash] != 0) revert TrackAlreadyRegistered();

        $._trackCount++;

        $._trackIndex[trackMetadataHash] = $._trackCount;

        $._registeredTracks[$._trackCount].artistIndexes = artistIndexes;
        $._registeredTracks[$._trackCount].trackMetadataHash = trackMetadataHash;
        $._registeredTracks[$._trackCount].beneficiary = beneficiary;
        $._registeredTracks[$._trackCount].trackStatus = TrackStatus.PENDING;
        for (uint256 i = 0; i < controllers.length; i++) {
            $._registeredTracks[$._trackCount].controllers[controllers[i]] = true;
            $._controllerTracks[controllers[i]].push($._trackCount);
        }

        emit TrackRegistered(
            _createId("TRACK", $._trackCount), artistIndexes, trackMetadataHash, beneficiary, msg.sender
        );
    }

    /// @inheritdoc ITrackRegistration
    function getTrackAtIndex(uint256 trackIndex)
        external
        view
        returns (
            uint256[] memory artistIndexes,
            string memory trackMetadataHash,
            address beneficiary,
            TrackStatus status
        )
    {
        RegistryStorage storage $ = _getRegistryStorage();

        return (
            $._registeredTracks[trackIndex].artistIndexes,
            $._registeredTracks[trackIndex].trackMetadataHash,
            $._registeredTracks[trackIndex].beneficiary,
            $._registeredTracks[trackIndex].trackStatus
        );
    }

    /// @inheritdoc ITrackRegistration
    function getTrackId(string calldata trackMetadataHash) external view returns (string memory) {
        RegistryStorage storage $ = _getRegistryStorage();

        uint256 index = $._trackIndex[trackMetadataHash];

        return _createId("TRACK", index);
    }

    /// @inheritdoc ITrackRegistration
    function setTrackBeneficiary(uint256 trackIndex, address newBeneficiary) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredTracks[trackIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        $._registeredTracks[trackIndex].beneficiary = newBeneficiary;

        emit TrackUpdated(
            msg.sender,
            _createId("TRACK", trackIndex),
            $._registeredTracks[trackIndex].artistIndexes,
            $._registeredTracks[trackIndex].trackMetadataHash,
            newBeneficiary,
            $._registeredTracks[trackIndex].trackStatus
        );
    }

    /// @inheritdoc ITrackRegistration
    function setTrackMetadataHash(
        uint256 trackIndex,
        string calldata newTrackMetadataHash
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredTracks[trackIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        $._registeredTracks[trackIndex].trackMetadataHash = newTrackMetadataHash;
        $._trackIndex[newTrackMetadataHash] = trackIndex;

        emit TrackUpdated(
            msg.sender,
            _createId("TRACK", trackIndex),
            $._registeredTracks[trackIndex].artistIndexes,
            newTrackMetadataHash,
            $._registeredTracks[trackIndex].beneficiary,
            $._registeredTracks[trackIndex].trackStatus
        );
    }

    /// @inheritdoc ITrackRegistration
    function setTrackStatus(uint256 trackIndex, TrackStatus status) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        _requireVerifierRole(msg.sender);

        $._registeredTracks[trackIndex].trackStatus = status;

        emit TrackUpdated(
            msg.sender,
            _createId("TRACK", trackIndex),
            $._registeredTracks[trackIndex].artistIndexes,
            $._registeredTracks[trackIndex].trackMetadataHash,
            $._registeredTracks[trackIndex].beneficiary,
            status
        );
    }

    /// @inheritdoc ITrackRegistration
    function setTrackController(
        uint256 trackIndex,
        address controller,
        bool isController
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredTracks[trackIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        if (isController != $._registeredTracks[trackIndex].controllers[controller]) {
            $._registeredTracks[trackIndex].controllers[controller] = isController;
            emit TrackControllerUpdated(_createId("TRACK", trackIndex), controller, isController);
        }
    }

    /// @inheritdoc ITrackRegistration
    function isTrackController(address account, uint256 trackIndex) external view returns (bool) {
        RegistryStorage storage $ = _getRegistryStorage();

        return $._registeredTracks[trackIndex].controllers[account];
    }

    /// @inheritdoc ITrackRegistration
    function getTracksForController() external view returns (uint256[] memory) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._controllerTracks[msg.sender];
    }

    /// @inheritdoc IReleaseRegistration
    function registerRelease(
        string calldata releaseMetadataHash,
        uint256[] memory trackIndexes,
        address[] calldata controllers,
        address[] calldata allowedTokenContracts
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        $._releaseCount++;

        if ($._releaseIndex[releaseMetadataHash] != 0) revert ReleaseAlreadyCreated();

        address[] memory beneficiaries = new address[](trackIndexes.length);

        for (uint256 i = 0; i < trackIndexes.length; i++) {
            _requireTrackIsRegistered(trackIndexes[i]);
            _requireTrackIsVerified(trackIndexes[i]);

            $._registeredReleases[$._releaseCount].releaseTracks.push(
                ReleaseTrack({trackIndex: trackIndexes[i], accessGranted: false})
            );

            beneficiaries[i] = $._registeredTracks[trackIndexes[i]].beneficiary;
        }

        $._releaseIndex[releaseMetadataHash] = $._releaseCount;

        address split = ISplitsFactory($._splitsFactory).create(beneficiaries);

        $._registeredReleases[$._releaseCount].releaseMetadataHash = releaseMetadataHash;
        $._registeredReleases[$._releaseCount].beneficiary = split;

        for (uint256 i = 0; i < controllers.length; i++) {
            $._registeredReleases[$._releaseCount].controllers[controllers[i]] = true;
        }
        for (uint256 i = 0; i < allowedTokenContracts.length; i++) {
            $._registeredReleases[$._releaseCount].allowedTokenContracts[allowedTokenContracts[i]] = true;
        }

        emit ReleaseRegistered(_createId("RELEASE", $._releaseCount), trackIndexes, msg.sender);
    }

    /// @inheritdoc IReleaseRegistration
    function unregisterRelease(uint256 releaseIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        RegistryStorage storage $ = _getRegistryStorage();

        // TODO what should happen here with any tokens that have been minted?

        delete $._registeredReleases[releaseIndex];
        emit ReleaseUnregistered(_createId("RELEASE", releaseIndex));
    }

    /// @inheritdoc IReleaseRegistration
    function getReleaseAtIndex(uint256 releaseIndex)
        external
        view
        returns (
            string memory releaseMetadataHash,
            address beneficiary,
            ReleaseTrack[] memory releaseTracks
        )
    {
        RegistryStorage storage $ = _getRegistryStorage();

        return (
            $._registeredReleases[releaseIndex].releaseMetadataHash,
            $._registeredReleases[releaseIndex].beneficiary,
            $._registeredReleases[releaseIndex].releaseTracks
        );
    }

    /// @inheritdoc IReleaseRegistration
    function getReleaseId(string calldata releaseMetadataHash) external view returns (string memory) {
        RegistryStorage storage $ = _getRegistryStorage();

        uint256 index = $._releaseIndex[releaseMetadataHash];

        return _createId("RELEASE", index);
    }

    /// @inheritdoc IReleaseRegistration
    function getReleaseTokens(uint256 releaseIndex) external view returns (ReleaseToken[] memory) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._registeredReleases[releaseIndex].releaseTokens;
    }

    /// @inheritdoc IReleaseRegistration
    function setReleaseMetadataHash(
        uint256 releaseIndex,
        string calldata newReleaseMetadataHash
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredReleases[releaseIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        $._registeredReleases[releaseIndex].releaseMetadataHash = newReleaseMetadataHash;
        $._releaseIndex[newReleaseMetadataHash] = releaseIndex;

        emit ReleaseUpdated(
            _createId("RELEASE", releaseIndex),
            newReleaseMetadataHash,
            $._registeredReleases[releaseIndex].beneficiary,
            $._registeredReleases[releaseIndex].releaseTracks,
            $._registeredReleases[releaseIndex].releaseTokens
        );
    }

    /// @inheritdoc IReleaseRegistration
    function addReleaseToken(uint256 releaseIndex, address tokenAddress, uint256 tokenId) external {
        RegistryStorage storage $ = _getRegistryStorage();
        if (!$._registeredReleases[releaseIndex].allowedTokenContracts[tokenAddress]) {
            revert InvalidTokenContract();
        }
        if (!$._registeredReleases[releaseIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        $._registeredReleases[releaseIndex].releaseTokens.push(
            ReleaseToken(tokenAddress, tokenId, block.chainid)
        );
        $._tokenMetadataHash[tokenId] = $._registeredReleases[releaseIndex].releaseMetadataHash;

        emit ReleaseTokenAdded(_createId("RELEASE", releaseIndex), tokenAddress, tokenId);
    }

    /// @inheritdoc IReleaseRegistration
    function grantTrackAccess(uint256 releaseIndex, uint256 trackIndex, bool hasAccess) external {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredTracks[trackIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        for (uint256 i = 0; i < $._registeredReleases[releaseIndex].releaseTracks.length; i++) {
            if ($._registeredReleases[releaseIndex].releaseTracks[i].trackIndex == trackIndex) {
                $._registeredReleases[releaseIndex].releaseTracks[i].accessGranted = hasAccess;
                break;
            }
        }
    }

    /// @inheritdoc IReleaseRegistration
    function checkTrackAccess(
        uint256 releaseIndex,
        uint256 trackIndex
    ) external view returns (bool hasAccess) {
        RegistryStorage storage $ = _getRegistryStorage();

        for (uint256 i = 0; i < $._registeredReleases[releaseIndex].releaseTracks.length; i++) {
            if ($._registeredReleases[releaseIndex].releaseTracks[i].trackIndex == trackIndex) {
                return $._registeredReleases[releaseIndex].releaseTracks[i].accessGranted;
            }
        }
    }

    /// @inheritdoc IReleaseRegistration
    function setReleaseController(
        uint256 releaseIndex,
        address controller,
        bool isController
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredReleases[releaseIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        if (isController != $._registeredReleases[releaseIndex].controllers[controller]) {
            $._registeredReleases[releaseIndex].controllers[controller] = isController;
            emit ReleaseControllerUpdated(_createId("RELEASE", releaseIndex), controller, isController);
        }
    }

    /// @inheritdoc IReleaseRegistration
    function isReleaseController(address account, uint256 releaseIndex) external view returns (bool) {
        RegistryStorage storage $ = _getRegistryStorage();

        return $._registeredReleases[releaseIndex].controllers[account];
    }

    /// @inheritdoc IReleaseRegistration
    function setAllowedTokenContract(
        uint256 releaseIndex,
        address tokenContract,
        bool isAllowed
    ) external onlyMember {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredReleases[releaseIndex].controllers[msg.sender]) {
            revert CallerDoesNotHavePermission();
        }

        $._registeredReleases[releaseIndex].allowedTokenContracts[tokenContract] = isAllowed;

        emit AllowedTokenContractUpdated(_createId("RELEASE", releaseIndex), tokenContract, isAllowed);
    }

    /// @inheritdoc IReleaseRegistration
    function isAllowedTokenContract(
        address tokenContract,
        uint256 releaseIndex
    ) external view returns (bool) {
        RegistryStorage storage $ = _getRegistryStorage();

        return $._registeredReleases[releaseIndex].allowedTokenContracts[tokenContract];
    }

    /// @inheritdoc IReleaseRegistration
    function getTokenMetadataHash(uint256 tokenId) external view returns (string memory) {
        RegistryStorage storage $ = _getRegistryStorage();
        return $._tokenMetadataHash[tokenId];
    }

    // Internal Functions

    // Artist

    function _requireArtistVerified(uint256 artistIndex) internal view {
        RegistryStorage storage $ = _getRegistryStorage();

        if ($._registeredArtists[artistIndex].artistStatus == ArtistStatus.PENDING) {
            revert ArtistHasNotBeenVerified();
        } else if ($._registeredArtists[artistIndex].artistStatus == ArtistStatus.REJECTED) {
            revert ArtistHasBeenRejected();
        }
    }

    function _requireCallerIsArtistController(uint256 artistIndex, address caller) internal view {
        RegistryStorage storage $ = _getRegistryStorage();

        if (!$._registeredArtists[artistIndex].controllers[caller]) {
            revert CallerDoesNotHavePermission();
        }
    }

    // Track

    function _requireTrackIsVerified(uint256 trackIndex) internal view {
        RegistryStorage storage $ = _getRegistryStorage();

        if ($._registeredTracks[trackIndex].trackStatus == TrackStatus.PENDING) {
            revert TrackHasNotBeenVerified();
        } else if ($._registeredTracks[trackIndex].trackStatus == TrackStatus.REJECTED) {
            revert TrackHasBeenRejected();
        }
    }

    function _requireTrackIsRegistered(uint256 trackIndex) internal view {
        RegistryStorage storage $ = _getRegistryStorage();

        if ($._trackIndex[$._registeredTracks[trackIndex].trackMetadataHash] == 0) {
            revert TrackIsNotRegistered();
        }
    }

    // Roles

    function _requireVerifierRole(address account) internal view {
        if (!hasRole(keccak256("VERIFIER_ROLE"), account)) {
            revert VerifierRoleRequired();
        }
    }

    function _requireReleasesRegistrarRole(address account) internal view {
        if (!hasRole(keccak256("RELEASES_REGISTRAR_ROLE"), account)) {
            revert ReleasesRegistrarRoleRequired();
        }
    }

    // Utils

    function _createId(string memory prefix, uint256 count) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                prefix, "-DROP-", Strings.toString(block.chainid), "-", Strings.toString(count)
            )
        );
    }
}
