// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Auctioner is Ownable {
    /// @dev Libraries

    /// @dev Errors
    error Auctioner__AuctionUninitialized();
    error Auctioner__AuctionNotOpened();
    error Auctioner__InsufficientFractions();
    error Auctioner__NotEnoughETH();
    error Auctioner__TransferFailed();
    error Auctioner__AuctionDoesNotExists();

    /// @dev Variables
    uint public s_totalAuctions;

    /// @dev Arrays

    /// @dev STATUSES
    // Planned - aukcja już jest zeschedulowana, smart contract oraz IPFS już powstały, ale rozpocznie się dopiero za określony czas
    // Open - otwarta i można kupować
    // Closed - wszystko sprzedano
    // Failed - niewszystko sprzedane, a czas upłynął, dostępny jest refund
    // Ongoing voting - ludzie głosują early buyout offer
    // Revenue distribution - kasa jest już na smartcontractcie, użytkownicy mogą claimować przychody
    // Archived - wszyscy sclaimowali przychód, inwestycja jest ostatecznie zamknięta

    /// @dev Enums
    enum AuctionState {
        UNINITIALIZED, // auction has not been initialized
        PLANNED, // auction has been initialized and awaits its start date
        OPENED, // auction ready to get orders for pNFT
        CLOSED, // auction finished positively - all pNFT bought
        FAILED, // auction finished negatively - not all pNFT bought (refund available)
        VOTING, // early buyout voting period
        FINISHED, // all funds transferred to broker (claim available)
        ARCHIVED // everyone claimed their revenue, investment closed
    }

    /// @dev Structs

    /// @dev Mappings

    /// @dev Events
    event Create();
    event Purchase();
    event Buyout();
    event Claim();
    event Refund();
    event Vote(); // check if event is available in gov
    event TransferToBroker();
    event StateChange(uint indexed auction, AuctionState indexed state);

    /// @dev Constructor
    constructor() Ownable(msg.sender) {}

    // 1. Broker zaklada request o aukcje - offchain
    // 2. Admin potwierdza zalozenie aukcji wywolujac funkcje (schedule - aukcja w przyszlosci) (open - aukcja instant)

    /// @dev PARAMETERS
    // Nazwa inwestycji/przedmiotu + symbol (generated based on name / offchain)
    // URI (zdjecie)
    // Całkowita wartość aktywa
    // Ilość kawałków
    // Max. ilość kawałków ile może zakupić jeden user
    // Datę rozpoczęcia aukcji
    // Datę zamknięcia aukcji (domyślnie 7 dni po dacie rozpoczęcia)
    // Adres portfela, na który trafić mają pieniądze ze sprzedaży aktywa w ramach aukcji.
    function createAuction() external onlyOwner {
        // Na podstawie czasu kiedy aukcja ma sie rozpoczac wywolujemy funkcje 'open' (instant start) lub 'schedule' (delayed start)
        //
        // emit Create();
    }

    // Function used for instant open of Auction
    function openAuction() internal {}

    // Function used for delayed open of Auction
    function scheduleAuction() internal {}

    // Function that allows buying pieces
    function buy() external {
        // emit Purchase();
        //
        // If last piece bought ->
        // emit TransferToBroker();
    }

    // Function that allows to make offer to buy certain asset instantly
    function buyout() external {
        // emit Buyout();
    }

    // Function that allows claim revenue from pNFT
    function claim() external {
        // emit Claim();
    }

    // Function that allows to withdraw funds by user if auction fails
    function refund() external {
        // emit Refund();
    }
}
