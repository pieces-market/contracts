// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {Auctioner} from "../../src/Auctioner.sol";
import {Asset} from "../../src/Asset.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../../src/extensions/ERC721AVotes.sol";

import {IAuctioner} from "../../src/interfaces/IAuctioner.sol";
import {IAsset} from "../../src/interfaces/IAsset.sol";
import {IERC721A} from "@ERC721A/contracts/IERC721A.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Create} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    Auctioner private auctioner;
    Create private createAuction;

    uint256 private constant STARTING_BALANCE = 100 ether;

    address private ADMIN = vm.addr(vm.envUint("ADMIN_KEY"));
    address private FOUNDATION = vm.addr(vm.envUint("FOUNDATION_KEY"));

    function setUp() public {
        vm.startPrank(ADMIN);
        auctioner = new Auctioner(FOUNDATION, address(0));
        createAuction = new Create();
        vm.stopPrank();

        console.log("Auctioner: ", address(auctioner));
    }

    function test_CreateAuctionScript() public {
        createAuction.run(address(auctioner));
    }
}
