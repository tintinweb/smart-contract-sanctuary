pragma solidity ^0.5.9;

contract TestContract {
    function puki() public view returns(address) {
        return msg.sender;
    }
}