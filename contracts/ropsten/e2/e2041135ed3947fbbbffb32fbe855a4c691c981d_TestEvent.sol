/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TestEvent {

    event Event1(address indexed _from,  uint256 indexed _data);
    event Event2(address indexed _from, uint256 indexed _data);
    
    uint256 public data;

    function createEvent(uint256 _data)public returns(uint256) {
        data = _data;
        emit Event1(msg.sender,_data);
        return data;
    }
    
    function createEvent2(uint256 _data)public returns(uint256) {
        data = _data;
        emit Event2(msg.sender,_data);
        return data;
    }
    
    function createEventBoth(uint256 _data)public returns(uint256) {
        data = _data;
        emit Event1(msg.sender,_data);
        emit Event2(msg.sender,_data);
        return data;
    }
}