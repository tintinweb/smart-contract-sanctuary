/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.5.16;

contract Test3 {

    uint counter = 0;

    function read() public view returns (uint) {
        return counter;
    }

    function increment() public {
        counter++;
    }

}