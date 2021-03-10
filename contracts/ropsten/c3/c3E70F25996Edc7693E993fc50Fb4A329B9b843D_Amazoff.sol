/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity ^0.5.0;

contract Amazoff {

    address owner;
    mapping(address=>uint256) deposits;
    uint public blackFridayEndDate;

    modifier byOwner {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    modifier ifBlackFridayClosed {
        require(blackFridayEndDate < now, "Black friday is not yet closed");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function setBlackFriday(uint timestamp) public ifBlackFridayClosed {
        blackFridayEndDate = timestamp;
    }
    
    function deposit() public payable{
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
    }
    
    function getAmount(address owner) public view returns (uint) {
        return deposits[owner];
    }

    function withdraw(uint256 amount) public ifBlackFridayClosed {
        require(deposits[msg.sender] >= amount, "No more money");
        deposits[msg.sender] = deposits[msg.sender] - amount;
        msg.sender.transfer(amount);
    }

}