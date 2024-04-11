// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IRegistry {
    // Events

    ///  @dev Emitted when a track is registered
    event TrackRegistered(string trackRegistrationHash, string trackId, address indexed trackAdmin);

    /**
     * @dev Emitted whenever the track registration hash is updated
     * as the registration hash is the IPFS hash of the metadata,
     * this is emitted when calling updateTrackMetadata
     */
    event TrackRegistrationHashUpdated(
        string trackId, string newTrackRegistrationHash, address indexed trackAdmin
    );

    /**
     * @notice Emitted when a release is registered, initiated by the Releases contract
     * when a release is successfully created
     */
    event ReleaseRegistered(string[] trackIds, address releases, uint256 tokenId);

    /// @notice Emitted when a release is unregistered
    event ReleaseUnregistered(bytes32 releaseHash);

    /// @dev Emitted whenever a field in RegisterTrack is updated
    event TrackUpdated(
        TrackStatus indexed trackStatus,
        address indexed trackAdmin,
        address trackBeneficiary,
        string trackRegistrationHash,
        string fingerprintHash,
        string validationHash,
        address trackVerifier
    );
    /**
     * @dev Represents a registered track
     * @param trackStatus The registration state of the track (pending, validated, invalidated)
     * @param trackAdmin The account that owns the rights to a track.
     * This is usually the artist address, but could be a contract.
     * @param TrackRegistrationHash This is a IPFS hash of the track metadata
     * @param FingerprintHash This is a IPFS hash of the track fingerprint
     * @param ValidationHash This is a hash of proof of validation data
     * @param TrackVerifier The account that validated the track
     */

    struct RegisteredTrack {
        TrackStatus trackStatus;
        address trackAdmin;
        address trackBeneficiary;
        string trackRegistrationHash;
        string fingerprintHash;
        string validationHash;
        address trackVerifier;
    }

    /**
     * @notice Represents a registered release.
     * @param TrackIds The ids of the tracks in the release
     * @param TokenUri The metadata uri of the release
     * @param TotalSupply The total supply of the release
     */
    struct RegisteredRelease {
        string[] trackIds;
        string tokenUri;
        uint256 totalSupply;
    }
    /// @dev The registration state of the track (pending, validated, invalidated)

    enum TrackStatus {
        PENDING,
        VALIDATED,
        INVALIDATED
    }

    /**
     * @dev Registers a track using the IPFS hash of the track metadata.
     * Track status is set to pending by default unless the user has the GOLD_ROLE.
     * The Track can be registered by the trackAdmin or a manager.
     * @param trackRegistrationHash - The registration hash of the track
     * @param trackBeneficiary - The beneficiary of the track (could be single or an 0xSplit)
     */
    function registerTrack(address trackBeneficiary, string calldata trackRegistrationHash) external;

    /**
     * @dev Returns all registered track data
     * @param trackId - The id of the track
     */
    function getTrack(string calldata trackId) external view returns (RegisteredTrack memory);

    /**
     * @dev Returns the track id for a track
     * @param trackRegistrationHash - The registration hash of the track
     */
    function getTrackId(string calldata trackRegistrationHash) external view returns (string memory);

    /**
     * @dev Sets the track status for a track
     * @notice Only a caller with the Verifier role can call this function
     * @param trackId - The id of the track
     * @param status - The new status of the track
     */
    function setTrackStatus(string calldata trackId, TrackStatus status) external;

    /**
     * @dev Sets the track uri
     * @notice Only the track owner can call this function
     * @param trackId - The id of the track
     * @param newTrackRegistrationHash - The new registration hash of the track
     * i.e. the updated IPFS hash of the track metadata
     */
    function setTrackMetadata(
        string calldata trackId,
        string calldata newTrackRegistrationHash
    ) external;

    /**
     * @dev Sets the track beneficiary for a track
     * @param trackId - The id of the track
     * @param newTrackBeneficiary - The new beneficiary of the track
     */
    function setTrackBeneficiary(string calldata trackId, address newTrackBeneficiary) external;

    /**
     * @dev Sets the track fingerprint hash for a track
     * @param trackId - The id of the track
     * @param fingerprintHash - The new fingerprint hash of the track
     */
    function setTrackFingerprintHash(
        string calldata trackId,
        string calldata fingerprintHash
    ) external;

    /**
     * @dev Sets the track validation hash for a track
     * @param trackId - The id of the track
     * @param validationHash - The new validation hash of the track
     */
    function setTrackValidationHash(string calldata trackId, string calldata validationHash) external;

    /**
     * @notice Checks the caller has permission to release a track through an open Releases contract.
     * @param trackId The id of the track
     * @param caller The address of the caller
     */
    function hasTrackAccess(string calldata trackId, address caller) external view returns (bool);

    /**
     * @notice Registers a release. In order for a release to be registered
     * the Releases contract must be registered, the tracks must be registered,
     * the Releases contract must have the track owners permission to release the track,
     * and this exact combination of ordered tracks and metadata uri must not have been
     * registered previously.
     * @param tokenId The token id of the release
     * @param trackIds The track ids of the tracks
     * @param uri The metadata uri of the release
     * @param totalSupply The total supply of the release
     */
    function registerRelease(
        uint256 tokenId,
        string[] calldata trackIds,
        string calldata uri,
        uint256 totalSupply
    ) external;

    /**
     * @notice Unregisters a releases. This deletes a release hash enabling the release
     * to be created again. Only the default admin can call this method.
     * @param releaseHash The hash of the release
     */
    function unregisterRelease(bytes32 releaseHash) external;

    /**
     * @notice Returns an array of track ids for a given token id and releases address
     * @param tokenId The token id of the release
     */
    function getReleaseTracks(uint256 tokenId) external view returns (string[] memory);

    /**
     * @notice Returns the release hash for a release
     * @param tokenId The token id of the release
     */
    function getReleaseHash(uint256 tokenId) external view returns (bytes32);

    /**
     * @notice Returns a registered release
     * @param releaseHash The hash of the release
     */
    function getRegisteredRelease(bytes32 releaseHash)
        external
        view
        returns (RegisteredRelease memory);
}
