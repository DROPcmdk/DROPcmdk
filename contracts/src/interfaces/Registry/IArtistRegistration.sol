// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IArtistRegistration {
    event ArtistRegistered(string id, string artistMetadataHash);

    event ArtistControllerUpdated(string artistId, address controller, bool isController);

    event ArtistUpdated(
        address indexed updatedBy, string artistId, string artistMetadataHash, ArtistStatus status
    );

    enum ArtistStatus {
        PENDING,
        VERIFIED,
        REJECTED
    }

    /**
     * @notice Represents a registered Artist
     * @param artistMetadataHash This is the IPFS hash of the artist metadata
     * @param controllers The authorized addresses that can update the Artist
     * @param artistStatus The status of the artist (PENDING, VERIFIED, REJECTED)
     */
    struct RegisteredArtist {
        string artistMetadataHash;
        mapping(address => bool) controllers;
        ArtistStatus artistStatus;
    }

    /**
     * @notice Registers an artist using the IPFS hash of the artist metadata.
     * @param artistMetadataHash This is the IPFS hash of the artist metadata
     * @param controllers The authorized addresses that can update the Artist
     */
    function registerArtist(
        string calldata artistMetadataHash,
        address[] calldata controllers
    ) external;

    /**
     * @notice Returns all registered artist data
     * @param artistIndex The index of the artist
     */
    function getArtistAtIndex(uint256 artistIndex)
        external
        view
        returns (string memory artistMetadataHash, ArtistStatus status);

    /**
     * @notice Returns the artist id of the artist
     * @param artistMetadataHash The metadata hash of the artist
     */
    function getArtistId(string calldata artistMetadataHash) external view returns (string memory);

    /**
     * @notice Sets the artist metadata hash
     * The account setting the metadata hash needs to be a controller for the corresponding artist Id.
     * @param artistIndex The index of the artist
     * @param newArtistMetadataHash The new metadata hash of the artist
     */
    function setArtistMetadataHash(
        uint256 artistIndex,
        string calldata newArtistMetadataHash
    ) external;

    /**
     * @notice Sets the status of the artist
     * The account setting the status needs to have a verifier role
     * @param artistIndex The index of the artist
     * @param newStatus The new status of the artist
     */
    function setArtistStatus(uint256 artistIndex, ArtistStatus newStatus) external;

    /**
     * @notice Sets an artist controller
     * The account setting the controller needs to be a controller for the corresponding artist Id.
     * @param artistIndex The index of the artist
     * @param controller The address of the controller
     * @param isController The boolean value to set or unset the controller
     */
    function setArtistController(uint256 artistIndex, address controller, bool isController) external;

    /**
     * @notice Returns if the caller is a controller for the artist
     * @param account The address to check
     * @param artistIndex The index of the artist
     */
    function isArtistController(address account, uint256 artistIndex) external view returns (bool);
    /**
     * @notice Returns all artists indexes that the caller is a controller for
     */
    function getArtistsForController() external view returns (uint256[] memory);
}
