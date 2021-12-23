/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

pragma solidity ^0.8.2;

contract Tata {

    address owner;
    string message;

    constructor() {
        owner = msg.sender;
    }
    function negativize(int32 num) pure public returns(int32) {
        require(num < 40, "Too big");
        return 0 - num;
    }

    function set(string memory _message) public {
        require(msg.sender == owner, "Bah non frere");
        message = _message;
    }

    function get() public view returns(string memory) {
        return message;
    }
}