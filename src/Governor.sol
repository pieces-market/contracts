// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Asset} from "./Asset.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IGovernor} from "./interfaces/IGovernor.sol";
import {IAuctioner} from "./interfaces/IAuctioner.sol";

/// @title Governor Contract
/// @notice Allows creation and management of proposals per given asset, executes passed proposals
contract Governor is Ownable, IGovernor {
    /// @dev FUNCTION quorum = 51%

    struct ProposalCore {
        address asset;
        uint256 voteStart;
        uint256 voteEnd;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    /// @dev Variables
    uint256 private s_totalProposals;

    /// @dev Mappings
    mapping(uint256 proposalId => ProposalCore) private s_proposals;

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    /// @dev This function will be called by 'buyout()' fn from 'Auctioner.sol'

    /// @notice Creates new proposal
    /// @dev Emits Propose and StateChange events
    /// @param asset Address of the asset linked to the proposal
    /// @param description Description of the proposal
    function propose(address asset, string memory description) external onlyOwner {
        ProposalCore storage proposal = s_proposals[s_totalProposals];

        proposal.asset = asset;
        proposal.voteStart = block.timestamp;
        proposal.voteEnd = block.timestamp + 7 days;
        proposal.description = description;
        proposal.state = ProposalState.ACTIVE;

        emit Propose(s_totalProposals, asset, proposal.voteStart, proposal.voteEnd, description);
        emit StateChange(s_totalProposals, ProposalState.ACTIVE);

        s_totalProposals += 1;
    }

    /// @inheritdoc IGovernor
    function castVote(uint proposalId, VoteType vote) external {
        if (proposalId >= s_totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = s_proposals[proposalId];
        if (proposal.state != ProposalState.ACTIVE) revert Governor__ProposalNotActive();
        if (proposal.hasVoted[msg.sender] == true) revert Governor__AlreadyVoted();

        uint256 votes = Asset(proposal.asset).getPastVotes(msg.sender, proposal.voteStart);
        if (votes == 0) revert Governor__ZeroVotingPower();

        if (vote == VoteType.FOR) {
            proposal.forVotes += votes;
        } else if (vote == VoteType.AGAINST) {
            proposal.againstVotes += votes;
        } else if (vote == VoteType.ABSTAIN) {
            proposal.abstainVotes += votes;
        }

        proposal.hasVoted[msg.sender] = true;
    }

    // Minimum amount of users that voted for proposal to pass
    /// @notice Checks if the quorum for a proposal is reached
    /// @param proposalId The id of the proposal
    function quorumReached(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = s_proposals[proposalId];

        /// @dev total available votes (tokens minted so far per asset) <=
        return totalVotes(proposalId) <= proposal.forVotes + proposal.abstainVotes;
    }

    /// @notice Calls 'buyout' function from Auctioner contract
    /// @param auctionId The id of the auction
    function execute(uint auctionId) external onlyOwner {
        //IAuctioner(owner()).buyout(auctionId);
    }

    /// @notice Cancels a proposal by setting its state to
    /// @dev Emits StateChange event
    /// @param proposalId The id of the proposal
    function cancel(uint proposalId) external onlyOwner {
        if (proposalId >= s_totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = s_proposals[proposalId];

        proposal.state = ProposalState.FAILED;

        emit StateChange(proposalId, ProposalState.FAILED);
    }

    /// @dev Below functions probably to be removed

    /// @notice Checks if a proposal has succeeded based on the votes
    /// @param proposalId The id of the proposal
    function voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return proposal.forVotes > proposal.againstVotes;
    }

    /// @dev Getter
    function getVotes(address asset, address holder) external view returns (uint256) {
        return Asset(asset).getVotes(holder);
    }

    /// @dev Getter
    function votingPeriod(uint proposalId) external view returns (uint) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return (proposal.voteEnd < block.timestamp) ? 0 : (proposal.voteEnd - block.timestamp);
    }

    /// @dev Getter
    function proposalVotes(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
    }

    /// @dev Getter
    function totalVotes(uint256 proposalId) internal view returns (uint256) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
    }
}
