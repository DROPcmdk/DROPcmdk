// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ITrackRegistration {
    ///  @notice Emitted when a track is registered

    event TrackRegistered(
        string trackId,
        uint256[] artistIndexes,
        string trackMetadataHash,
        address indexed beneficiary,
        address indexed trackRegisterer
    );

    event TrackControllerUpdated(string trackId, address controller, bool isController);

    /// @notice Emitted whenever a field in RegisterTrack is updated
    event TrackUpdated(
        address indexed updatedBy,
        string trackId,
        uint256[] artistIndexes,
        string trackMetadataHash,
        address beneficiary,
        TrackStatus status
    );

    enum TrackStatus {
        PENDING,
        VERIFIED,
        REJECTED
    }

    /**
     * @notice Represents a registered track
     * @param artistIndexes The unique indexes of the artists on the track
     * @param trackMetadataHash This is the IPFS hash of the track metadata
     * @param beneficiary The beneficiary of the track
     * @param trackStatus The status of the track (PENDING, VERIFIED, REJECTED)
     * @param controllers The authorized addresses that can update the track
     */
    struct RegisteredTrack {
        uint256[] artistIndexes;
        string trackMetadataHash;
        address beneficiary;
        TrackStatus trackStatus;
        mapping(address => bool) controllers;
    }

    /**
     * @notice Registers a track using the IPFS hash of the track metadata and the Artist Id.
     * The account registering the track needs to be a controller for the corresponding artist Id.
     * @param artistIndexes - The unique indexes of the artists on the track
     * @param trackMetadataHash - The metadata hash of the track
     * @param beneficiary - The beneficiary of the track (could be single or an 0xSplit)
     * @param controllers - The authorized addresses that can update the track
     */
    function registerTrack(
        uint256[] memory artistIndexes,
        string calldata trackMetadataHash,
        address beneficiary,
        address[] calldata controllers
    ) external;

    /**
     * @notice Returns all registered track data
     * @param trackIndex The index of the track
     */
    function getTrackAtIndex(uint256 trackIndex)
        external
        view
        returns (
            uint256[] memory artistIds,
            string memory trackMetadataHash,
            address beneficiary,
            TrackStatus status
        );

    /**
     * @notice Returns the track id for a track
     * @param trackMetadataHash - The registration hash of the track
     */
    function getTrackId(string calldata trackMetadataHash) external view returns (string memory);

    /**
     * @notice Sets the track beneficiary for a track
     * @param trackIndex The index of the track
     * @param newBeneficiary - The new beneficiary of the track
     */
    function setTrackBeneficiary(uint256 trackIndex, address newBeneficiary) external;

    /**
     * @notice Sets the track uri
     * @notice Only the track owner can call this function
     * @param trackIndex The index of the track
     * @param newTrackMetadataHash - The new registration hash of the track
     * i.e. the updated IPFS hash of the track metadata
     */
    function setTrackMetadataHash(uint256 trackIndex, string calldata newTrackMetadataHash) external;

    /**
     * @notice Sets a track status
     * The account setting the status needs to have a verifier role
     * @param trackIndex The index of the track
     * @param status The new status of the track
     */
    function setTrackStatus(uint256 trackIndex, TrackStatus status) external;

    /**
     * @notice Sets a track controller
     * The account setting the controller needs to be a controller for the corresponding track Id.
     * @param trackIndex The index of the track
     * @param controller The address of the controller
     * @param isController The boolean value to set or unset the controller
     */
    function setTrackController(uint256 trackIndex, address controller, bool isController) external;

    /**
     * @notice Returns if the caller is a controller for the track
     * @param account The address to check
     * @param trackIndex The index of the track
     */
    function isTrackController(address account, uint256 trackIndex) external view returns (bool);

    /**
     * @notice Returns all tracks that the caller is a controller for
     */
    function getTracksForController() external view returns (uint256[] memory);
}
