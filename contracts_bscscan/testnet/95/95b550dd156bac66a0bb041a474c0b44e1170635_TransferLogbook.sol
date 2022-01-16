/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

//testnet: 0x95b550DD156Bac66a0bb041a474c0b44E1170635

pragma solidity >=0.8.7;


contract TransferLogbook {
    event LoggedEvent(address indexed sender, uint indexed index, address indexed token, uint amount, uint value, string message);
    event LoggedUpdate(address indexed sender, uint indexed index);

    mapping (address => mapping (address => bool)) public permission;

    mapping (address => uint) public lastIndex;


    function logEvent(address token, uint amount, uint value, string memory message) external returns (uint index){
        return _logEvent(msg.sender, token, amount, value, message);
    }

    function _logEvent(address sender, address token, uint amount, uint value, string memory message) internal returns (uint index){
        lastIndex[sender] = lastIndex[sender]+1;
        index = lastIndex[sender];
        emit LoggedEvent(sender, index, token, amount, value, message);
    }

    function log() external returns (uint index){
        index = lastIndex[msg.sender];
        eventUpdate(index);
    }

    function eventUpdate(uint index) public {
        _eventUpdate(msg.sender, index);
    }

    function _eventUpdate(address sender, uint index) internal {
        emit LoggedUpdate(sender, index);
    }

    function commissionedEvent(address sender, address token, uint amount, uint value, string memory message) external returns (uint index) {
        require (permission[sender][msg.sender]);
        return _logEvent(sender, token, amount, value, message);
    }

    function commissionedLog(address sender) external returns (uint index) {
        index = lastIndex[sender];
        commissionedEventUpdate(sender, index);
    }

    function commissionedEventUpdate(address sender, uint index) public {
        require (permission[sender][msg.sender]);
        _eventUpdate(sender, index);
    }

    function setPermission(address instance, bool allowed) external {
        permission[msg.sender][instance] = allowed;
    }
}