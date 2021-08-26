/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract Tt {
    using SafeMath for uint256;
    uint256 public age;
    uint256 public age_big;
    address public addr1;
    address public addr2;
    
    
    function test1() public{
        // uint256 max value
        age_big = uint256(-1);
    }
    
    function test2() public{
        age = age.add(20);
    }
    
    function test3() public{
        addr1 = msg.sender;
        test4();
    }
    
    function test4() private{
        addr2 = msg.sender;
    }

}