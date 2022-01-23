/**
 *Submitted for verification at BscScan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract CallTestContract {
    uint public demo = 0;
    function set(address _test) public {
        demo = TestContract(_test).getX();
    }

    function setX(address _test, uint _y) public {
        TestContract(_test).setX(_y);
    }
}

contract TestContract {
    uint public x = 65;
    function getX() public view returns(uint) {
        return x;
    }
    function setX(uint _x) external {
        x = _x;
    }
}