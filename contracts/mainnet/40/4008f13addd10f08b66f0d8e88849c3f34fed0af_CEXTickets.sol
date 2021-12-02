// SPDX-License-Identifier: UNNLICENSED
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
contract CEXTickets is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    
    // Starts at 0 
    Counters.Counter ID;

    // Max supply 
    uint256 maxSupply = 100;
    
    // Price increments for each segment of 25 NFTs
    uint256[] private quarters = [750000000000000000, 900000000000000000, 1050000000000000000, 1250000000000000000];

    // Tracks amount address has purchased
    mapping(address => uint256) public amountBought;
    
    // The address to receive payment from sales
    address payable payee;
    
    // Event to emit upon purchase 
    event mint(uint256 id, address mintFrom, address mintTo);
    
    constructor(string memory name, string memory symbol, address payable payRecipient) ERC721(name, symbol) {
        payee = payRecipient;
        
        uint256 currID = Counters.current(ID);
        
        // Increment ID counter
        Counters.increment(ID);
        
        // Mint NFT to user wallet
        _mint(_msgSender(), currID);
        emit mint(currID, address(this), _msgSender());
    }
    
    function buy() public payable nonReentrant {
        require(Counters.current(ID) < maxSupply, "Tickets are sold out");
        require(msg.value == currentPrice(), "Incorrect amount of ETH sent");
        // Limit 1 per wallet address
        require(amountBought[_msgSender()] < 1, "You have already bought the max amount of tickets");
        
        // Increment amount bought for message sender address
        amountBought[_msgSender()] += 1;
        
        // Pay payee
        (bool success,) = payee.call{value: msg.value}("");
        require(success, "Transfer fail");
        
        uint256 currID = Counters.current(ID);
        
        // Increment ID counter
        Counters.increment(ID);
        
        // Mint NFT to user wallet
        _mint(_msgSender(), currID);
        emit mint(currID, address(this), _msgSender());
    }
    
    function changePrice(uint256 quarterToChange, uint256 newPrice) public onlyOwner {
        quarters[quarterToChange] = newPrice;
    }
    
    // Returns the current amount of NFTs minted
    function totalSupply() public view returns(uint256) {
        return Counters.current(ID);
    }

    function currentPrice() public view returns(uint256) {
        return quarters[Counters.current(ID) / 25];
    }

    function withdraw() public {
        require(_msgSender() == payee, "You are not authorized");
        (bool success,) = payee.call{value: address(this).balance}("");
        require(success, "Transfer fail");
    }
}