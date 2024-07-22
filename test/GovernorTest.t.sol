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

        address precomputedAsset = vm.computeCreateAddress(address(auctioner), vm.getNonce(address(auctioner)));

        vm.recordLogs();
        vm.expectEmit(true, true, true, true, address(auctioner));
        emit IAuctioner.Create(0, precomputedAsset, 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        auctioner.create("Asset", "AST", "https:", 2 ether, 100, 10, block.timestamp, block.timestamp + 7 days, BROKER);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        address createdAsset = address(uint160(uint256(entries[2].topics[2])));
        asset = Asset(createdAsset);
        vm.stopPrank();

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

    modifier proposalMade() {
        vm.prank(address(auctioner));
        governor.propose(address(asset), "New buyout offer!");

        _;
    }
}
