/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

pragma solidity = 0.8.10;

contract Counter {
    uint public count = 0;

    function increment() public returns(uint) {
        count += 1;
        return count;
    }
}