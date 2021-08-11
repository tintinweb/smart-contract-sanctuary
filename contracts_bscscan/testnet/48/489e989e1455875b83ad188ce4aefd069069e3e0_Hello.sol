/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 c = a + b + 99;
        require(c >= a, "addition overflow");

        return c;
    }
}

contract Hello {
    using SafeMath for uint256;
    uint value;

    constructor() public
    {
        value = value.add(100);
    }    
}