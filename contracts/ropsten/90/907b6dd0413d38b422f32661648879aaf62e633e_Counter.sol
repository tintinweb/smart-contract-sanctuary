/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity ^0.6.0;

contract Counter {
    uint count;

    constructor() public {
        count = 0;
    }
    
    function getCount() public view returns(uint) {
        return count;
    }

    function incrementCount() public {
        count = count + 1;
    }

}