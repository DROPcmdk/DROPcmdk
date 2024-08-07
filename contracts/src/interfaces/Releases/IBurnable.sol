// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**
 * @notice IBurnable is an interface for burning a token.
 */
interface IBurnable {
    event Burned(uint256 tokenId, address indexed tokenOwner);

    /**
     * @dev Burns a release, used as a way to remove
     * unwanted content from an open Releases contract
     * @param tokenId - The ID of the token
     */
    function burn(uint256 tokenId) external;
}
