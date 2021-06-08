/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.4.17;

contract Faucet {
    function withdraw(uint256 amount) public {
        require(amount <= 100000000000000000);
        msg.sender.transfer(amount);
    }
}