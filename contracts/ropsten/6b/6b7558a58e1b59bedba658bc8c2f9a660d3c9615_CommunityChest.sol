/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.4.17;

contract CommunityChest {
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        // nothing else to do!
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}