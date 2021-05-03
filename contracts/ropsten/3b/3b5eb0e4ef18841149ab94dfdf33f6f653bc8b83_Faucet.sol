/**
 *Submitted for verification at Etherscan.io on 2021-05-02
*/

pragma solidity ^0.4.22;

contract Faucet {
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 0.1 ether);
        msg.sender.transfer (withdraw_amount);
    }
    
    function () public payable {}
}