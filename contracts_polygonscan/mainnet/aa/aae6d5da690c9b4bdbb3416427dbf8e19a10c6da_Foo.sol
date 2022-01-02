/**
 *Submitted for verification at polygonscan.com on 2022-01-02
*/

// File: contracts/Foo.sol



pragma solidity >=0.7.0 <0.9.0;

contract Foo {

    uint256 public number;

    function set(uint256 num) public {
        number = num;
    }
}