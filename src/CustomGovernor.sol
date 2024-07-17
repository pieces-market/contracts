// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev This contract only will be allowed to execute buyout function from Auctioner
/// @dev Make Auctioner owner -> so it can call execute here by Chainlink Keepers?
contract CustomGovernor is Ownable {
    /// @dev FUNCTION quorum = 51%

    enum ProposalState {
        Inactive,
        Active,
        Passed,
        Failed
    }

    enum VoteType {
        For,
        Against,
        Abstain
    }

    struct ProposalCore {
        uint256 timeLeft;
        bool executed;
        bool canceled;
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalCore) private _proposals;
    mapping(uint256 proposalId => ProposalVote) private _proposalVotes;

    constructor(address owner) Ownable(owner) {}

    function propose() external {}

    function execute() external {}

    function cancel() external {}

    function delegate() external {}

    function vote() external {}

    function getVotes() external {}

    function votingPeriod() external {}

    /// @dev SimpleVoting

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
