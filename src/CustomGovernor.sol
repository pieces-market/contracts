// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

/// @dev This contract only will be allowed to execute buyout function from Auctioner
contract CustomGovernor {
    /// @dev FUNCTION votingPeriod
    /// @dev FUNCTION execute -> if voting successful
    /// @dev FUNCTION cancel -> if voting fails
    /// @dev FUNCTION delegate
    /// @dev FUNCTION vote
    /// @dev FUNCTION getVotes
    /// @dev FUNCTION votingPeriod

    /// @dev FUNCTION quorum = 51%

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    constructor() {}

    function proposalVotes(uint256 proposalId) public view returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    function quorumReached(uint256 proposalId) internal view returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return totalVotes(proposalId) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    function totalVotes(uint256 /* proposalId */) internal pure returns (uint256) {
        return 0;
    }

    function voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }
}
