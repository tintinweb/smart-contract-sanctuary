/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

pragma solidity ^0.4.25;

contract Example {
    event Log(string message);

    function hello() public {
        emit Log('Hello World');
    }
}