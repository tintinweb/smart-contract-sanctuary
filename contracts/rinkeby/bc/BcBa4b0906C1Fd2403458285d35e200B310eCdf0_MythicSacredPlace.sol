// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract MythicSacredPlace {

    address public owner;
    mapping (address => bool) public operatorAddress; // list of address which can gives authorizations (bonds contracts)
    mapping (address => bool) public keysOwners; // mapping of keys owners
    
    event keyTransfer(address _from, address _to);
    event keySet(address _recipient, bool _haveKey);

    constructor() {
        owner = msg.sender;
    }

    function transferOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function setOperatorAddress(address _addr, bool _isOp) external {
        require(msg.sender == owner);
        operatorAddress[_addr] = _isOp;
    }

    function setMythicalKey(address _recipient, bool _haveKey) external {
        if (operatorAddress[msg.sender]) {
            keysOwners[_recipient] = _haveKey;
            emit keySet(_recipient, _haveKey);
        }
    }

    function hasMythicalKey(address _recipient) external returns (bool) {
        return keysOwners[_recipient];
    }

    function transferKey(address _recipient) external {
        require(keysOwners[msg.sender]);
        keysOwners[msg.sender] = false;
        keysOwners[_recipient] = true;
        emit keyTransfer(msg.sender, _recipient);
    }

}