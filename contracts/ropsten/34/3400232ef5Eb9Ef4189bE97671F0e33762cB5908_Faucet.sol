/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity >=0.5.0;

contract Faucet {
    receive() external payable {}
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 100000000000000000);
        payable(msg.sender).transfer(withdraw_amount);    
    }
    function SayHello() public returns (string memory) { 
        return ("SomeHello"); 
    }
}