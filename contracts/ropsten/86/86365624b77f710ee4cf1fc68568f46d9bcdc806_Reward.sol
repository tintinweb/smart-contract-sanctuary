/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity ^0.4.23;

contract Reward {
    function withdraw() public {
        msg.sender.transfer(address(this).balance - 1);
    }
}