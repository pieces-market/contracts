// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../src/Auctioner.sol";
import {Asset} from "../src/Asset.sol";
import {Governor} from "../src/Governor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAuctioner} from "../src/interfaces/IAuctioner.sol";
import {IGovernor} from "../src/interfaces/IGovernor.sol";

contract GovernorTest is Test {
    Auctioner private auctioner;
    Asset private asset;
    Governor private governor;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private OWNER = makeAddr("owner");
    address private BROKER = makeAddr("broker");
    address private USER = makeAddr("user");
    address private BUYER = makeAddr("buyer");
    address private DEVIL = makeAddr("devil");

    function setUp() public {
        vm.startPrank(OWNER);
        auctioner = new Auctioner();
        governor = new Governor(address(auctioner));

        vm.recordLogs();
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        vm.stopPrank();

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[1].topics[2])));
        asset = Asset(createdAsset);

        console.log("Auctioner: ", address(auctioner));
        console.log("Asset: ", address(asset));
        console.log("Governor: ", address(governor));

        deal(OWNER, STARTING_BALANCE);
        deal(BROKER, STARTING_BALANCE);
        deal(USER, STARTING_BALANCE);
        deal(BUYER, STARTING_BALANCE);
        deal(DEVIL, STARTING_BALANCE);
    }

    function testCantMakeProposalIfNotOwner() public {
        vm.prank(DEVIL);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, DEVIL));
        governor.propose(address(asset), "New buyout offer!");
    }

    function testCanMakeProposal() public proposalMade {
        vm.prank(address(auctioner));
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.Propose(1, address(asset), block.timestamp + 1 days, "Buyout offer received!");
        vm.expectEmit(true, true, true, true, address(governor));
        emit IGovernor.StateChange(1, IGovernor.ProposalState.Active);
        governor.propose(address(asset), "Buyout offer received!");
    }

    function testBuyerCanVote() public proposalMade {
        /// @dev Buy mints and delegates votes in same timestamp as proposal is made, so votes are valid for voting
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);
    }

    function testAftermarketBuyerCanVote() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        uint devilSnapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 1);
        assertEq(asset.balanceOf(USER), 1);
        assertEq(asset.getVotes(USER), 1);

        assertEq(devilSnapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.warp(block.timestamp + 1);

        /// @dev We create proposal when both DEVIL and USER got voting power, so they can vote
        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType.For);

        governor.proposalVotes(0);
    }

    function testAftermarketBuyerCantVote() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);
        uint devilSnapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 1);
        assertEq(asset.balanceOf(USER), 1);
        assertEq(asset.getVotes(USER), 1);

        assertEq(devilSnapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.prank(DEVIL);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.For);
    }

    function testCantVoteMultipleTimes() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__AlreadyVoted.selector);
        governor.castVote(0, IGovernor.VoteType.For);

        /// @dev Transfer To Devil
        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 2);
        assertEq(asset.balanceOf(DEVIL), 2);
        assertEq(asset.getVotes(DEVIL), 2);

        vm.prank(DEVIL);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.For);

        governor.proposalVotes(0);
    }

    function testCanCountVotesForMultipleProposals() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        governor.castVote(1, IGovernor.VoteType.Abstain);

        vm.warp(block.timestamp + 1);

        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(USER), 3);
        assertEq(asset.getVotes(USER), 3);

        /// @dev We can move below vars to global, so it will be reusable for multiple tests
        uint forVotes;
        uint againstVotes;
        uint abstainVotes;

        (forVotes, againstVotes, abstainVotes) = governor.proposalVotes(0);
        assertEq(forVotes, 3);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 0);

        (forVotes, againstVotes, abstainVotes) = governor.proposalVotes(1);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 3);
    }

    function testPreviousTokenOwnerCantVote() public {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.warp(block.timestamp + 1);

        /// @dev Transfer To Devil
        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 1);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        vm.warp(block.timestamp + 1);

        uint snapshotVotes;
        snapshotVotes = asset.getPastVotes(USER, asset.clock() - 1);

        assertEq(snapshotVotes, 0);
        assertEq(asset.balanceOf(USER), 0);
        assertEq(asset.getVotes(USER), 0);

        snapshotVotes = asset.getPastVotes(DEVIL, asset.clock() - 1);

        assertEq(snapshotVotes, 3);
        assertEq(asset.balanceOf(DEVIL), 3);
        assertEq(asset.getVotes(DEVIL), 3);

        /// @dev Creating proposal on updated votes
        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        vm.warp(block.timestamp + 1);

        vm.prank(USER);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.Abstain);

        vm.prank(DEVIL);
        governor.castVote(0, IGovernor.VoteType.Abstain);
    }

    modifier proposalMade() {
        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        _;
    }
}
