// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {AuctionerDev} from "../src/helpers/AuctionerDev.sol";
import {GovernorDev} from "../src/helpers/GovernorDev.sol";

contract DeployPiecesMarketDev is Script {
    /// @dev EXCLUDE FROM COVERAGE
    function test() public {}

    address private foundation = vm.addr(vm.envUint("FOUNDATION_KEY"));

    function run() external returns (AuctionerDev, GovernorDev) {
        uint deployerKey = vm.envUint("ADMIN_KEY");

        vm.startBroadcast(deployerKey);
        GovernorDev governor = new GovernorDev();
        console.log("Governor Dev Deployed:", address(governor));

        AuctionerDev auctioner = new AuctionerDev(foundation, address(governor));
        console.log("Auctioner Dev Deployed:", address(auctioner));

        governor.transferOwnership(address(auctioner));
        console.log("Governor Dev New Owner:", address(auctioner));
        vm.stopBroadcast();

        return (auctioner, governor);
    }
}
