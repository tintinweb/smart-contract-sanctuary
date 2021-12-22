/**
 *Submitted for verification at polygonscan.com on 2021-12-21
*/

pragma solidity 0.5.4;
contract B {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}