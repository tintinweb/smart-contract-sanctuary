/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity ^0.5.16;

contract Staking {
    mapping (address => uint) public balances;

    function charge(uint amount) public {
        balances[msg.sender] += amount;
    }
}