// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice This interface defines a lightweight version of the required functionality to register releases
 * when a release is successfully created.
 */
interface IReleaseRegistration {
    /**
     * @notice Emitted when a release is registered
     */
    event ReleaseRegistered(string releaseId, uint256[] trackIndexes, address registrerer);

    /// @notice Emitted when a release is unregistered
    event ReleaseUnregistered(string releaseId);

    /// @notice Emitted when a release is updated
    event ReleaseUpdated(
        string releaseId,
        string releaseMetadataHash,
        address beneficiary,
        ReleaseTrack[] releaseTracks,
        ReleaseToken[] releaseTokens
    );

    event ReleaseControllerUpdated(string releaseId, address controller, bool isController);

    event AllowedTokenContractUpdated(string releaseId, address tokenContract, bool isAllowed);

    event ReleaseTokenAdded(string releaseId, address tokenAddress, uint256 tokenId);

    /**
     * @notice Represents a registered release.
     * @param releaseMetadataHash The metadata hash of the release
     * @param beneficiary The beneficiary of the release
     * @param releaseTracks The tracks in the release
     * @param controllers The authorized addresses that can update the release
     * @param allowedTokenContracts The authorized  token contract addresses
     * that can be used to create a release token
     * @param releaseTokens A list of release tokens created from the release
     */
    struct RegisteredRelease {
        string releaseMetadataHash;
        address beneficiary;
        ReleaseTrack[] releaseTracks;
        mapping(address => bool) controllers;
        mapping(address => bool) allowedTokenContracts;
        ReleaseToken[] releaseTokens;
    }
    /**
     * @notice Represents a release token that has been created from a Registered release.
     * @param tokenAddress The address of the Releases contract from which the tracks were released
     * @param tokenId The token id of the release
     */

    struct ReleaseToken {
        address tokenAddress;
        uint256 tokenId;
        uint256 chainId;
    }

    /**
     * @notice Represents a track in a release
     * @param trackIndex The index of the track
     * @param accessGranted A boolean indicating if the track has been granted access
     * by the track controller
     */
    struct ReleaseTrack {
        uint256 trackIndex;
        bool accessGranted;
    }

    /**
     * @notice Registers a release. In order for a release to be registered
     * the tracks must be registered and verified and the caller must be a
     * controller for each track used.
     * @param releaseMetadataHash The metadata hash of the release
     * @param trackIndexes The indexes of the tracks in the release
     * @param controllers The authorized accounts that can update the release
     * and create release tokens
     * @param allowedTokenContracts The contracts allowed to create release tokens
     */
    function registerRelease(
        string calldata releaseMetadataHash,
        uint256[] calldata trackIndexes,
        address[] calldata controllers,
        address[] calldata allowedTokenContracts
    ) external;

    /**
     * @notice Unregisters a releases. This deletes a release hash enabling the release
     * to be created again. Only the default admin can call this method.
     * @param releaseIndex The index of the release
     */
    function unregisterRelease(uint256 releaseIndex) external;

    /**
     * @notice Returns a registered release
     * @param releaseIndex The index of the release
     */
    function getReleaseAtIndex(uint256 releaseIndex)
        external
        view
        returns (
            string calldata releaseMetadataHash,
            address beneficiary,
            ReleaseTrack[] memory releaseTracks
        );

    /**
     * @notice Returns the id of a release
     * @param releaseMetadataHash The metadata hash of the release
     */
    function getReleaseId(string calldata releaseMetadataHash) external view returns (string memory);

    /**
     * @notice Returns a list of release tokens
     * @param releaseIndex The index of the release
     */
    function getReleaseTokens(uint256 releaseIndex) external view returns (ReleaseToken[] memory);

    /**
     * @notice Sets the Release metadata hash, the caller must be a controller
     * for the token contract the release was created from.
     * @param releaseIndex The index of the release
     * @param newReleaseMetadataHash The new metadata hash of the release
     */
    function setReleaseMetadataHash(
        uint256 releaseIndex,
        string calldata newReleaseMetadataHash
    ) external;

    /**
     * @notice Adds a release token to a registered release
     * @param releaseIndex The index of the release
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id of the release
     */
    function addReleaseToken(uint256 releaseIndex, address tokenAddress, uint256 tokenId) external;

    /**
     * @notice Grants access to a track in a release
     * @param releaseIndex The index of the release
     * @param trackIndex The index of the track
     * @param hasAccess A boolean indicating if the track controller has granted access
     */
    function grantTrackAccess(uint256 releaseIndex, uint256 trackIndex, bool hasAccess) external;

    /**
     * @notice Returns a boolean indicating if a track controller
     * has granted access to a track to be used for the release
     * @param releaseIndex The index of the release
     * @param trackIndex The index of the track
     */
    function checkTrackAccess(
        uint256 releaseIndex,
        uint256 trackIndex
    ) external view returns (bool hasAccess);

    /**
     * @notice Sets an release controller
     * The account setting the controller needs to be a controller for the corresponding release Id.
     * @param releaseIndex The index of the release
     * @param controller The address of the controller
     * @param isController The boolean value to set or unset the controller
     */
    function setReleaseController(
        uint256 releaseIndex,
        address controller,
        bool isController
    ) external;

    /**
     * @notice Returns a boolean indicating if an account is a controller for a release
     * @param account The address of the account
     * @param releaseIndex The index of the release
     */
    function isReleaseController(address account, uint256 releaseIndex) external view returns (bool);

    /**
     * @notice Sets an allowed token contract
     * The account setting the controller needs to be a controller for the corresponding release Id.
     * @param releaseIndex The index of the release
     * @param isAllowed The boolean value to set or unset the allowed contract
     */
    function setAllowedTokenContract(
        uint256 releaseIndex,
        address tokenContract,
        bool isAllowed
    ) external;

    /**
     * @notice Returns a boolean indicating if the token contract is allowed
     * to be used to create a release token
     * @param tokenContract The address of the token contract
     * @param releaseIndex The index of the release
     */
    function isAllowedTokenContract(
        address tokenContract,
        uint256 releaseIndex
    ) external view returns (bool);

    /**
     * @notice Returns the metadata hash for a token, called by a token contract to construct the URI
     * @param tokenId The id of the token
     */
    function getTokenMetadataHash(uint256 tokenId) external view returns (string memory);
}
