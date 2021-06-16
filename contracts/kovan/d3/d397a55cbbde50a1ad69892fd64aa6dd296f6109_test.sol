/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.7.6;

contract test {
    function deposit() external payable returns(uint256) {
        if (msg.value <= 1 ether) {
            return msg.value;
        } else {
            return 0;
        }
    }
}