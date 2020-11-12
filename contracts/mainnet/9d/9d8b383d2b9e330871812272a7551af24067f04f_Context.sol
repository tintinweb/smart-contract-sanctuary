pragma solidity ^0.6.0;
 
contract Context {
 
    constructor () internal { }
 
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}