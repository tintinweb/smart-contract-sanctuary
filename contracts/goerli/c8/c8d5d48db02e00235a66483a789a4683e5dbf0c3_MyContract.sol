/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

pragma solidity 0.8.10;

contract MyContract {
    uint public x = 88;

    function setx(uint _x) public {
        x = _x;
    }
}