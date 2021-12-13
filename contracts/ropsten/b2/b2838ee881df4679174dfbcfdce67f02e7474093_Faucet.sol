/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.4.17;

contract Faucet {
    function withdraw_pay(uint amount) public {
        // check max amount
        require(amount <= 1000000000000000000);

        // give one ether
        msg.sender.transfer(amount);
    }

    function () public payable {}
}