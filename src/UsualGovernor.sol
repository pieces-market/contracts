// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Standard Governor version
contract UsualGovernor is Governor, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, Ownable {
    /// @dev ERROR!
    /// @dev Currently we can only work with one NFT
    /// @dev We would need to create our own ERC20 designed for voting only

    constructor(IVotes _token) Governor("UsualGovernor") GovernorVotes(_token) GovernorVotesQuorumFraction(51) Ownable(msg.sender) {}

    // The following functions are overrides required by Solidity.

    /// @notice Returns the voting delay in blocks.
    /// @dev This function is required to override the Governor contract's function.
    /// @return The voting delay in blocks.
    function votingDelay() public pure override(Governor) returns (uint256) {
        return 0;
    }

    /// @notice Returns the voting period in blocks.
    /// @dev This function is required to override the Governor contract's function.
    /// @return The voting period in blocks.
    function votingPeriod() public pure override(Governor) returns (uint256) {
        return 1 days;
    }

    /// @notice Returns the proposal threshold.
    /// @dev The number of votes required to create a proposal.
    /// @return The proposal threshold.
    function proposalThreshold() public pure override(Governor) returns (uint256) {
        return 0;
    }
}
