/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity 0.7.3;

contract SafeMath {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) external pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) external pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function min(uint a, uint b) external pure returns (uint) {
        if (a < b) {
            return a;
        }
        return b;
    }
}