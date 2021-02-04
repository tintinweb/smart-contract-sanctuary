/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract TestEvent {

    event Event1(address indexed _from,string indexed _data);
    string public data;

    function createEvent(string memory _data)public returns(string memory) {
        data = _data;
        emit Event1(msg.sender,_data);
        return data;
    }
}