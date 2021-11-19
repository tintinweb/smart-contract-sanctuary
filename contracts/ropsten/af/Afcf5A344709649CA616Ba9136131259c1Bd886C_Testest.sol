/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Testest {
    constructor() {}

    uint256 value;
    string[] strings;
    event Ad(string[]);
    function test1(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256 _result)
    {
        _result = _a - _b;
    }

    function test2(uint256 _a, uint256 _b)
        public
        pure
        returns (uint256 _result)
    {
        unchecked {
            _result = _a - _b;
        }
    }

    function transfer(address _a, uint256 _b) public returns (uint256 _result) {
        require(_a != address(0));
        require(_b > 0);
        value+=_b;
        _result = 1;
    }
    
   function event_string(string memory _a) public returns (uint256 _result) {
           strings.push(_a);
           
        _result = 1;
    }
    
     function event_string1() public returns (uint256 _result) {
         
         emit Ad(strings);
        _result = 1;
    }
}