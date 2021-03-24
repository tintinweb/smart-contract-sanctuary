// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";

contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    address public owner;
    uint256 internal randomResult;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (varies by network)
        owner = msg.sender;
    }
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
}


contract Lottery is RandomNumberConsumer {
    uint private Metalottery;
    uint public prize;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    uint ticketPrice = 0.03 ether;
    
    address[] _ticketOwners;
    
    function getTicket() external payable {
        if (msg.value % ticketPrice != 0) {
            payable(msg.sender).transfer(msg.value % ticketPrice);
        }
         uint ticketsBought = msg.value / ticketPrice;
        
        prize += 2*msg.value/3;
        Metalottery = address(this).balance - prize;
        for (uint i=0; i < ticketsBought; i++) {
            _ticketOwners.push(msg.sender);
        }
    }
    
    function changeTicketPrice(uint newprice) public onlyOwner {
        require(_ticketOwners.length == 0);
        ticketPrice = newprice;
    }
    
    function awardWinner() public onlyOwner {
        /*Putting the following value in a variable effectively "locks" the amount of players until a winner is picked. */
        uint players = _ticketOwners.length;
        getRandomNumber(block.timestamp);
        uint winnerID = randomResult % players;
        payable(_ticketOwners[winnerID]).transfer(prize);
        delete _ticketOwners;
        delete prize;
    }
    
    function teamContribution() public onlyOwner {
        payable(owner).transfer(Metalottery);
    }
    
    function ticketsSold() public view returns (uint) {
       return _ticketOwners.length;
    }
    
    function kill() public onlyOwner {
        selfdestruct(payable(owner));
    }
}