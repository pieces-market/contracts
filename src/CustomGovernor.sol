// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev This contract only will be allowed to execute buyout function from Auctioner
/// @dev Make Auctioner owner -> so it can call execute here by Chainlink Keepers?
contract CustomGovernor is Ownable {
    /// @dev FUNCTION quorum = 51%

    error Governor__ProposalNotActive();
    error Governor__ProposalDoesNotExist();

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
        address assset;
        uint256 timeLeft;
        ProposalState state;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    /// @dev Variables
    uint256 private _totalProposals;

    /// @dev Mappings
    mapping(uint256 proposalId => ProposalCore) private _proposals;

    /// @dev Constructor
    constructor(address owner) Ownable(owner) {}

    function propose() external onlyOwner {
        ProposalCore storage proposal = _proposals[_totalProposals];

        proposal.state = ProposalState.Active;

        _totalProposals += 1;
    }

    function execute() external onlyOwner {}

    function cancel(uint proposalId) external onlyOwner {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];

        proposal.state = ProposalState.Failed;
    }

    function delegate() external {}

    function castVote(uint proposalId, VoteType vote) external {
        if (proposalId >= _totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert Governor__ProposalNotActive();

        if (vote == VoteType.For) proposal.forVotes += 1;
        if (vote == VoteType.Against) proposal.againstVotes += 1;
        if (vote == VoteType.Abstain) proposal.abstainVotes += 1;
    }

    function quorumReached(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = _proposals[proposalId];

        /// @dev total available votes (tokens minted so far per asset) <=
        return totalVotes(proposalId) <= proposal.forVotes + proposal.abstainVotes;
    }

    function voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = _proposals[proposalId];

        return proposal.forVotes > proposal.againstVotes;
    }

    /// @dev Getter
    function getVotes() external {}

    /// @dev Getter
    function votingPeriod() external {}

    /// @dev Getter
    function proposalData(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        ProposalCore storage proposal = _proposals[proposalId];

        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    /// @dev Getter
    function totalVotes(uint256 /* proposalId */) internal pure returns (uint256) {
        return 0;
    }
}
