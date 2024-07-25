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
        console.log("Check Clock: ", asset.clock());

        //vm.warp(block.timestamp + 1);
        // vm.roll(block.number + 20);

        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);
        console.log("BLOCK NUM: ", block.number);
        console.log("Check Clock 2: ", asset.clock());

        vm.roll(block.number + 1);

        uint votes = asset.getPastVotes(USER, 1);

        assertEq(votes, 3);

        assertEq(3, asset.balanceOf(USER));
        assertEq(3, asset.getVotes(USER));

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        /// @dev Transfer to Devil

        // vm.startPrank(USER);
        // asset.safeTransferFrom(USER, DEVIL, 0);
        // asset.safeTransferFrom(USER, DEVIL, 2);
        // vm.stopPrank();

        // assertEq(1, asset.balanceOf(USER));
        // //assertEq(1, asset.getVotes(USER));

        // assertEq(2, asset.balanceOf(DEVIL));
        // //assertEq(2, asset.getVotes(DEVIL));

        // vm.prank(USER);
        // governor.castVote(0, IGovernor.VoteType.For);

        // governor.proposalVotes(0);

        // vm.prank(DEVIL);
        // governor.castVote(0, IGovernor.VoteType.For);

        // governor.proposalVotes(0);

        // assertEq(0, asset.getVotes(USER));
        // assertEq(0, asset.getVotes(DEVIL));

        /// @dev NEXT PROPOSAL
        /// @notice USER vote power -> 1
        /// @notice DEVIL vote power -> 2

        // vm.prank(address(auctioner));
        // governor.propose(address(asset), "New buyout offer!");

        // vm.prank(USER);
        // governor.castVote(1, IGovernor.VoteType.For);

        // vm.prank(USER);
        // vm.expectRevert(IGovernor.Governor__AlreadyVoted.selector);
        // governor.castVote(1, IGovernor.VoteType.For);

        // (uint against, uint fore, uint abstain) = governor.proposalVotes(1);
        // console.log("Against 2 :", against);
        // console.log("For 2 :", fore);
        // console.log("Abstain 2 :", abstain);
    }

    function testCantVoteMultipleTimes() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        assertEq(3, asset.balanceOf(USER));
        assertEq(0, asset.getVotes(USER));

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        assertEq(3, asset.balanceOf(USER));
        assertEq(0, asset.getVotes(USER));

        /// @dev Transfer to Devil

        vm.startPrank(USER);
        asset.safeTransferFrom(USER, DEVIL, 0);
        asset.safeTransferFrom(USER, DEVIL, 2);
        vm.stopPrank();

        assertEq(2, asset.balanceOf(DEVIL));
        assertEq(0, asset.getVotes(DEVIL));

        /// @dev ERROR!

        vm.prank(DEVIL);
        vm.expectRevert(IGovernor.Governor__ZeroVotingPower.selector);
        governor.castVote(0, IGovernor.VoteType.For);

        governor.proposalVotes(0);
    }

    function testCanCountVotesForMultipleProposals() public proposalMade {
        vm.prank(USER);
        auctioner.buy{value: 6 ether}(0, 3);

        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        vm.prank(USER);
        governor.castVote(0, IGovernor.VoteType.For);

        assertEq(3, asset.balanceOf(USER));
        assertEq(0, asset.getVotes(USER));

        vm.prank(USER);
        governor.castVote(1, IGovernor.VoteType.For);
    }

    modifier proposalMade() {
        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        _;
    }
}
