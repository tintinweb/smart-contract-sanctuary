/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

pragma solidity ^0.4.23;
contract messageBoard {
    mapping (uint128 => bool) public list;
    string public message;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function addMapping(uint128 _add) public {
       list[_add] = true;
    }
}