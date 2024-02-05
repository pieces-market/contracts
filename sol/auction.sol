// SPDX-License-Identifier: GPL-3.0
// Git https://github.com/pieces-market/contracts 

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract Auction is ERC721,ERC721Enumerable,ERC721Votes,IERC721Receiver, ReentrancyGuard//,ERC721URIStorage 
{

    //TODO: change emit calls to just numbers

    //mint
    uint256 public totalMints = 0;
    uint256 public maxSupply = 0;
    
    //deposits, TODO: make it private
    mapping(address => uint256) public offerDeposits;

    //events
    event statusUpdate(address indexed from, string status);
    event availableUpdate(address indexed from, string availabe);
    event govResult(address indexed from, string offer_result);

    //Scheduled = 1
    //Open = 2
    //Closed = 3 
    //Failed = 4
    //Finished = 5
    //Archived = 6
    //TODO: change to ENUM
    uint256 public status = 1;

    address payable public platform;
    address payable public broker;
    //MVP only
    address public nft;
    uint256 public nftTokenId = 0;
    IERC721 vault;
    uint256 public fee;

    //TODO: NOT USED IN MVP
    string public ipfs;

    uint256 public price;
    uint256 public total;
    uint256 public available;
    uint256 public openTs;
    uint256 public closeTs;
    uint256 public offerValue = 0;
    //TODO: review
    address[] tokenOwners;

    constructor(address payable _broker, address payable _platform, address _nft, uint256 _nftTokenId, uint256 _price, uint256 _fee, uint256 _total, uint256 _openTs, uint256 _closeTs) 
        //TODO: string.concat(s1, s2) _nft + _nftTokenId + _total + " pcs"
        ERC721(string.concat(string.concat("Fractionalized ",Strings.toHexString(uint256(uint160(_nft)), 20))), "pieces") //TODO: name after NFT name?
        EIP712("pieces.market","1") {
        platform = _platform;
        broker = _broker;
        nft = _nft;
        nftTokenId = _nftTokenId;
        vault = IERC721(nft);
        fee = _fee;
        //TODO: setup properly
        ipfs = "https://ipfs.pieces.market/data.json";
        price = _price;
        maxSupply = _total;
        total = _total;//TODO: do we really need two variables?
        tokenOwner= new address[](total);
        available = _total;
        openTs = _openTs;
        closeTs = _closeTs;
        //TODO: verify if we need to emit this
        emit statusUpdate(msg.sender, "status_update:1");
    }

    //Triggered by Broker
    function open() public nonReentrant {
        //TODO: make sure we have NFT onboard
	    if(vault.balanceOf(broker) != 0){
            //Require Broker to be Owner of NFT
            require(vault.ownerOf(nftTokenId)==msg.sender,"You are not the owner of the Nft");
            vault.safeTransferFrom(broker, address(this), nftTokenId);
        }

        //to avoid double Open
        require(status == 1, "W2");

        //TODO: temporary disabled for MVP
        //require(openTs <= block.timestamp, "W3");

        status = 2;
        emit statusUpdate(msg.sender, "status_update:2");
    }

    function buy(uint256 no) public payable nonReentrant {
	    if(status==2 && available > 0 && closeTs <= block.timestamp){
            //Auction failed, not all sold before close time
            status = 4;
            emit statusUpdate(msg.sender, "status_update:4");
        }
		
        //must be ready to Open
        require(openTs <= block.timestamp, "W3");
        //must be Open
        require(status == 2, "W8");
        //must be before Close time
        require(closeTs >= block.timestamp, "W9");
        //must have at least 1 piece
        require(available > 0, "W10");
        
        //TODO: buy only these that are available? to discuss

        //must have no available to buy
        require(available >= no, "W5");
        

        //TODO: improve logic here
	    if (status==2 && available > 0 && openTs <= block.timestamp && closeTs >= block.timestamp) {
            require(available >= no, "W5");
            //TODO: make it thread safe
            available = available - no;
            //TODO: for MVP maxSupply is total, we may change it after MVP
            require(totalSupply() < maxSupply, "W4");
            //TODO: should be always equal?
            require(msg.value >= price * no, "W6");
            
            //minting
            for(uint256 i; i < no; i++){
                emit availableUpdate(msg.sender, "available--");
                tokenOwner[totalMints] = msg.sender;
                _safeMint(msg.sender, ++totalMints);
            }

            //delegate all
            delegate(msg.sender);

	        if (available == 0) {
                //transfer to Broker
                broker.transfer(price * totalMints);
                //transfer to Platform
                //transfer everything remaining, TODO: should we check if equals to fee * total?
                platform.transfer(address(this).balance);
                status = 3;
                emit statusUpdate(msg.sender, "status_update:3");
            }
	    }
        else if(status==2 && available==0){
            //TODO: make custom require, document
            revert("Not able to buy auction");
        }
    }

    function deposit() public payable nonReentrant {
        //only in Finished status
        //TODO: limit to one deposit in one time / blocktime
        require(status == 3, "W11");
        //TODO: if previous deposit available, should we just take difference?
        offerDeposits[msg.sender] += msg.value;
        emit gov_result(msg.sender, "DEPOSIT");
    }


    function offer(address _offerer, uint256 _offerValue) public nonReentrant {
        //only in Finished status
        require(status == 3, "W12");
        //TODO: more / better check, we should just require equal
        //TODO: more testing
        require(_offerValue >= offerDeposits[_offerer], "W13");

        //TODO: disable for MVP NFT
        //TODO: W7 will be dedicated to check lower limit of Offer
        //require(msg.value >= (price * total), "W7");

        //TODO: msg.sender validation, is needed?

        offerValue = _offerValue;
        offerDeposits[_offerer] -= _offerValue;
        emit govResult(msg.sender, "SOLD");
        status = 5;
        emit statusUpdate(msg.sender, "status_update:5");
        vault.safeTransferFrom(address(this), _offerer, nftTokenId);   
    }


    //Heartbeat
    function hb() public view returns (uint, uint256, uint256, uint256, uint256, uint256, address[] memory) {
        return (block.timestamp, status, available, offerValue, openTs, closeTs, tokenOwner);
    }

    function claim() public nonReentrant {
	    if (status == 5 && available < total) {
            //TODO:require being owner
            //TODO:check how many pieces owner own
            //TODO:burn all, transfer from contract balance

	        for (uint i=0; i < tokenOwner.length; i++) {
                if(tokenOwner[i] == msg.sender){
                    tokenOwner[available] = 0x0000000000000000000000000000000000000000;
	                available++;
                    _burn(available);
                
                    //TODO: should we split value in offer()
                    payable(msg.sender).transfer(address(this).balance / (total - (available - 1)));
                    emit availableUpdate(msg.sender, "revenue claim => piece burnt");
	            }
            }

	        if (available == total) {
                status = 6;//Archive auction
		        //TODO:ensure we don't lost anything, status 6 leads to contact destruction!
                platform.transfer(address(this).balance);//TODO: transfer everything remaining?
                emit statusUpdate(msg.sender, "status_update:6");
            }
	    }
        else if(status==5 && available==total){
            //TODO: change to custom require
            revert("Not able to refund! Everything refunded");
        }
        else{
            revert("Not able to refund, there is nothing to refund");
        }
    }

    //derived functions
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize = 1);
    }

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize = 1);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    //generic functions
}
