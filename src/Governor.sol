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
    function propose(uint256 auctionId, address asset, string memory description, bytes memory encodedFunction) external onlyOwner {
        ProposalCore storage proposal = s_proposals[s_totalProposals];

        /// @dev Here we can take asset from Auctioner by calling getter -> compare costs (same for id)
        proposal.auctionId = auctionId;
        proposal.asset = asset;
        proposal.voteStart = block.timestamp;
        proposal.voteEnd = block.timestamp + 7 days;
        proposal.description = description;
        proposal.encodedFunction = encodedFunction;
        proposal.state = ProposalState.ACTIVE;

        uint256 proposalType;
        if (keccak256(encodedFunction) != keccak256(abi.encodeWithSignature("buyout(uint256)", auctionId))) proposalType = 1;

        emit Propose(s_totalProposals, auctionId, asset, proposal.voteStart, proposal.voteEnd, description, proposalType);
        emit StateChange(s_totalProposals, ProposalState.ACTIVE);

        s_ongoingProposals.push(s_totalProposals);
        s_totalProposals++;
    }

    /// @inheritdoc IGovernor
    function castVote(uint proposalId, VoteType vote) external {
        if (proposalId >= s_totalProposals) revert Governor__ProposalDoesNotExist();
        ProposalCore storage proposal = s_proposals[proposalId];
        if (proposal.state != ProposalState.ACTIVE) revert Governor__ProposalNotActive();
        if (proposal.hasVoted[msg.sender] == true) revert Governor__AlreadyVoted();

        uint256 votes = Asset(payable(proposal.asset)).getPastVotes(msg.sender, proposal.voteStart);
        if (votes == 0) revert Governor__ZeroVotingPower();

        if (vote == VoteType.FOR) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit CastVote(proposalId, vote, votes);

        proposal.hasVoted[msg.sender] = true;
    }

    /// @notice Execution API called by Gelato, determines if the exec function should be executed
    /// @dev This function is called by Gelato to decide whether executing the `exec()` function is necessary
    /// @return canExec Boolean that indicates whether the execution is necessary
    /// @return execPayload Encoded function selector for `exec()`
    function checker() external view returns (bool canExec, bytes memory execPayload) {
        /// @dev Consider adding below restriction
        // if(tx.gasprice > 80 gwei) return (false, bytes("Gas price too high"));

        execPayload = abi.encodeWithSelector(this.exec.selector);

        if (s_ongoingProposals.length > 0) {
            ProposalCore storage proposal = s_proposals[s_ongoingProposals[0]];
            if (proposal.voteEnd < block.timestamp) {
                return (true, execPayload);
            }
        }

        return (false, execPayload);
    }

    /// @dev Consider implementing Timelock - an optional period that allows users to exit the ecosystem (sell their tokens) before the proposal can be executed

    /// @notice Execution API called by Gelato. Processes ongoing proposals once the voting period has ended
    /// @dev This function is triggered by Gelato when the `checker()` function indicates execution is necessary
    function exec() external {
        for (uint i; i < s_ongoingProposals.length; ) {
            uint id = s_ongoingProposals[i];
            ProposalCore storage proposal = s_proposals[id];

            bool isSucceeded = (Asset(payable(proposal.asset)).getPastTotalSupply(proposal.voteStart) / 2 < proposal.forVotes + proposal.againstVotes) &&
                (proposal.forVotes > proposal.againstVotes);

            bool isFailed = block.timestamp > proposal.voteEnd;

            if (isSucceeded || isFailed) {
                proposal.state = isSucceeded ? ProposalState.SUCCEEDED : ProposalState.FAILED;

                if (isSucceeded) {
                    (bool success, ) = owner().call(proposal.encodedFunction);
                    if (!success) revert Governor__ExecuteFailed();
                } else {
                    /// @dev Consider adding return into rejectProposal -> to check if call failed or not
                    Auctioner(owner()).reject(proposal.auctionId, proposal.encodedFunction);
                }

                emit StateChange(id, proposal.state);

                // Swap current element with the last one to remove it
                s_ongoingProposals[i] = s_ongoingProposals[s_ongoingProposals.length - 1];
                s_ongoingProposals.pop();

                /// @dev Check if we indeed need this emit
                emit ProcessProposal(id);

                // Do not increment 'i', recheck the element at index 'i' (since it was swapped)
                continue;
            }

            unchecked {
                i++;
            }
        }
    }

    /// @dev Below functions probably to be removed -> to be discussed

    /// @dev Getter
    function proposalVotes(uint256 proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        ProposalCore storage proposal = s_proposals[proposalId];

        return (proposal.forVotes, proposal.againstVotes);
    }

    /// @dev Getter - dev helper
    // function getUnprocessed() public view returns (uint256[] memory) {
    //     return s_ongoingProposals;
    // }
}
