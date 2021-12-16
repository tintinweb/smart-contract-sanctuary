//SPDX-License-Identifier: GPL3
pragma solidity ^0.8;

import "./Ownable.sol";

contract Greeter is Ownable{

    string private _message = "Hello, World!";
    address private _owner;


    function greet() external view returns (string memory){
        return _message;
    }
    function setGreeting(string calldata greeting) external{
        _message = greeting;
    }
}