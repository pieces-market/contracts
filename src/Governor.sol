// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Auctioner} from "./Auctioner.sol";
import {Asset} from "./Asset.sol"; // change it to interface
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IGovernor} from "./interfaces/IGovernor.sol";

/// @title Governor Contract
/// @notice Allows creation and management of proposals per given asset, executes passed proposals
contract Governor is Ownable, IGovernor {
    /// @dev Arrays
    uint256[] private s_ongoingProposals;

    struct ProposalCore {
        uint256 auctionId;
        address asset;
        uint256 voteStart;
        uint256 voteEnd;
        string description;
        bytes encodedFunction;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    /// @dev Variables
    uint256 private s_totalProposals;

    /// @dev Mappings
    mapping(uint256 proposalId => ProposalCore) private s_proposals;

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    /// @notice Creates new proposal
    /// @dev Emits Propose and StateChange events
    /// @param auctionId The id of the auction that received offer
    /// @param asset Address of the asset linked to the proposal
    /// @param description Proposal description
    /// @param encodedFunction Function to be called on execution expressed in bytes
    function propose(uint256 auctionId, address asset, string memory description, bytes memory encodedFunction) external onlyOwner returns (bool) {
        ProposalCore storage proposal = s_proposals[s_totalProposals];

        /// @dev Here we can take asset from Auctioner by calling getter -> compare costs (same for id)
        proposal.auctionId = auctionId;
        proposal.asset = asset;
        proposal.voteStart = block.timestamp;
        proposal.voteEnd = block.timestamp + 7 days;
        proposal.description = description;
        proposal.encodedFunction = encodedFunction;
        proposal.state = ProposalState.ACTIVE;

        emit Propose(s_totalProposals, auctionId, asset, proposal.voteStart, proposal.voteEnd, description);
        emit StateChange(s_totalProposals, ProposalState.ACTIVE);

        s_ongoingProposals.push(s_totalProposals);
        s_totalProposals++;

        /// @dev returns true if everything pass | check gas costs | check if it is even necessary
        return true;
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
        } else {
            proposal.againstVotes += votes;
        }

        proposal.hasVoted[msg.sender] = true;
    }

    /// @dev THIS FUNCTION SHOULD BE INTERNAL AND CALLED BY AUTOMATION CONTRACT !!!!!!!!!!
    /// @notice Calls proper function from Auctioner contract
    /// @param proposalId The id of the proposal
    function execute(uint proposalId) internal {
        ProposalCore storage proposal = s_proposals[proposalId];

        proposal.state = ProposalState.SUCCEEDED;
        (bool success, ) = owner().call(proposal.encodedFunction);
        if (!success) revert Governor__ExecuteFailed();

        emit StateChange(proposalId, ProposalState.SUCCEEDED);
    }

    /// @dev THIS FUNCTION SHOULD BE INTERNAL AND CALLED BY AUTOMATION CONTRACT !!!!!!!!!!
    /// @notice Cancels a proposal by changing it's state and calls 'reject()' function from Auctioner contract
    /// @dev Emits StateChange event
    /// @param proposalId The id of the proposal
    function cancel(uint proposalId) internal {
        ProposalCore storage proposal = s_proposals[proposalId];

        proposal.state = ProposalState.FAILED;
        /// @dev Consider adding return into rejectProposal -> to check if call failed or not
        Auctioner(owner()).reject(proposal.auctionId, proposal.encodedFunction);

        emit StateChange(proposalId, ProposalState.FAILED);
    }

    function exec() external {
        // Go thru all proposal's and check if time passed / votes in place -> cancel or execute as desired

        for (uint i; i < s_ongoingProposals.length; ) {
            uint id = s_ongoingProposals[i];
            ProposalCore storage proposal = s_proposals[id];

            bool quorumR = (Asset(proposal.asset).getPastTotalSupply(proposal.voteStart) / 2 < proposal.forVotes + proposal.againstVotes) &&
                (proposal.forVotes > proposal.againstVotes);

            if (proposal.voteEnd < block.timestamp) {
                if (quorumR) {
                    execute(id);
                } else {
                    cancel(id);
                }

                // Swap current element with the last one to remove it
                s_ongoingProposals[i] = s_ongoingProposals[s_ongoingProposals.length - 1];
                s_ongoingProposals.pop();

                // Consider adding emit here

                // Do not increment 'i', recheck the element at index 'i' (since it was swapped)
                continue;
            }

            unchecked {
                i++;
            }
        }
    }

    function getUnprocessed() external view returns (uint[] memory) {
        return s_ongoingProposals;
    }

    function getProposalData(uint256 id) public view returns (uint, address, uint, uint, string memory, bytes memory, uint, uint, ProposalState) {
        ProposalCore storage proposal = s_proposals[id];

        return (
            proposal.auctionId,
            proposal.asset,
            proposal.voteStart,
            proposal.voteEnd,
            proposal.description,
            proposal.encodedFunction,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.state
        );
    }

    /// @dev Below functions probably to be removed

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
    function proposalVotes(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return (proposal.forVotes, proposal.againstVotes);
    }

    /// @dev Getter
    function totalVotes(uint256 proposalId) internal view returns (uint256) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return proposal.forVotes + proposal.againstVotes;
    }
}
