// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ISplitsFactory} from "../ISplitsFactory.sol";

/**
 * @notice IReleases defines the interface for a Releases contract - a contract for artists
 * and labels to create token drops for their tracks.
 */
interface IReleases is IERC165 {
    event ReleaseCreated(uint256 tokenId);
    event ReleaseWithdrawn(address indexed receiver, uint256 tokenId, uint256 amount);

    /**
     * @notice Creates a new release token and transfers to the receiver.
     * @param receiver The address that will receive the release tokens
     * @param beneficiary The address that will receive royalties from the release
     * @param royaltyAmount The percentage of sale prices
     * that should be paid to the beneficiary for re-sales.
     *  Calculated by <NOMINATOR> / 10,000. e.g. For 10% royalties, pass in 1000
     * @param totalSupply The total amount of tokens to mint
     * @param metadataUri The URI for the metadata of the release
     */
    function create(
        address receiver,
        address beneficiary,
        uint96 royaltyAmount,
        uint256 totalSupply,
        string calldata metadataUri
    ) external;
}
