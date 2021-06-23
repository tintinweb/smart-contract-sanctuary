/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.8.4;
contract hodlEthereum {
   event Hodl(address indexed hodler, uint indexed amount); // Not necessary without UI
   event Party(address indexed hodler, uint indexed amount); // Not necessary without UI

    mapping (address => uint) public hodlers; //creates a mapping for hodler of address of type uint used to hold balance (msg.value)
    uint constant partyTime = 1624496399; // Thu Jun 24 2021 10:59:59 GMT+1000 (Australian Eastern Standard Time)
    
    receive() payable external { //gets called when ETH gets sent to contract address
        hodlers[msg.sender] += msg.value; //
        emit Hodl(msg.sender, msg.value);
    }

    function party() public {
        require (block.timestamp > partyTime && hodlers[msg.sender] > 0);
        uint value = hodlers[msg.sender];
        hodlers[msg.sender] = 0;
        payable(msg.sender).transfer(value);
        emit Party(msg.sender, value);
    }
}