/**
 *Submitted for verification at arbiscan.io on 2022-01-06
*/

pragma solidity ^0.8.0;

library DemoDirectly {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
}

contract A {
    uint256 public data;

    function set(uint256 a) external {
        data = _add(a, 10);
    }

    function _add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function setWithLibrary(uint256 a) external {
        data = DemoDirectly.add(a, 10);
    }
}