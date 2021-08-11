/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

pragma solidity ^0.5.0;

library SafePlus{
    function plus(uint256 a, uint256 b) external pure returns (uint256){
        uint256 c = a + b;
        require(c >= a, "addition overflow");

        return c;
    }
}

library SafeMath {
    using SafePlus for uint256;
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a.plus(b);
    }
}