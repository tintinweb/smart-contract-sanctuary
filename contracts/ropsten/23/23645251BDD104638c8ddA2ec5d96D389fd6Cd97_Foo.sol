/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.6.0;

contract Foo {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
}