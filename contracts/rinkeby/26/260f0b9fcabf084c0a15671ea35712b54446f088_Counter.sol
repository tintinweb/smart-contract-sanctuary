/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

// See https://docs.openzeppelin.com/contracts/4.x/erc721

pragma solidity >=0.6.0 <0.9.0;

contract Counter {
    uint private _counter;    
    address private _owner;
    address private _origin;

    event CounterUpdated(address sender, address origin, uint oldValue, uint newValue);

    constructor() {
        // store the contract owner
        _owner = msg.sender;
        _origin = tx.origin;
    }

    function setCounter(uint newValue) public {
        uint old = _counter;
        _counter = newValue;
        emit CounterUpdated(msg.sender, tx.origin, old, _counter);
    }

    function getCounter() public view returns (uint) {
        return _counter;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function getOrigin() public view returns (address) {
        return _origin;
    }

    function setAsOwner(uint newValue) public {
        require(msg.sender == _owner);
        uint old = _counter;
        _counter = newValue;
        emit CounterUpdated(msg.sender, tx.origin, old, _counter);
    }
}