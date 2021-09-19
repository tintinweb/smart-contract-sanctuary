/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity >=0.7.0 <0.9.0;

contract Increment {
    uint public x = 0;

    function increment(uint256 inttopass) public {
        x = x + inttopass;
    }
}