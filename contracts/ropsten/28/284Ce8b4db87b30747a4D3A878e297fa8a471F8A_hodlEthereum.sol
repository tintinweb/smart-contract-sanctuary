/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

pragma solidity 0.8.4;
contract hodlEthereum {
    event Hodl(address indexed hodler, uint indexed amount);
    event Party(address indexed hodler, uint indexed amount);
    mapping (address => uint) public hodlers; //hodlers keeps track of the balance of users accounts
    uint constant partyTime = 1625623916; // The unix epoch number when ether withdraw becaomes possible
    
    receive() external payable{
        hodlers[msg.sender] += msg.value; //add the funds of the user to the users balance
        emit Hodl(msg.sender, msg.value);
    }
    
    function party() public {
        require (block.timestamp > partyTime && hodlers[msg.sender] > 0); //If the user has a balance and the timestamp is greater than zero
        uint value = hodlers[msg.sender]; //set value to the balance of the sending account
        hodlers[msg.sender] = 0; //set the balance of the sending account to zero
        payable(msg.sender).transfer(value); //transfer the balance of the users funds to their address
        emit Party(msg.sender, value);
    }
}