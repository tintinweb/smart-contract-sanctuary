/**
 *Submitted for verification at hooscan.com on 2021-06-03
*/

pragma solidity 0.5.11;

contract A {

    uint256 public a;

    function initialize() public {
        a = 10;
    }
}

contract B is A {
    uint256 public b;

    function initialize(uint256 _b) public {
        b = _b;
    }
}