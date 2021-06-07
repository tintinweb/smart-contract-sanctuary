/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity 0.8.4;

// "SPDX-License-Identifier: MIT"

contract MSG {
    struct Data {
        address writer;
        string  message;
        uint256 time;
    }
    
    mapping (uint => Data) data;
    mapping(address => string) names;
    uint256 public id;
    event Message(uint256 Id, address writer, string message, string name, uint256 time);
    event SetName(address writer, string name);    

function write(string memory _message) public returns (bool success) {
        data[id].writer = msg.sender;
        data[id].message = _message;
        data[id].time = block.timestamp;
        emit Message(id, data[id].writer, data[id].message, names[msg.sender], data[id].time);
        id = id + 1;
        return true;
    }

function setName(string memory _name) public returns (bool success) {
        require(bytes(_name).length <= 50, "NAME MUST BE LESS THAN 50 SYMBLOS");
        names[msg.sender] = _name;
        emit SetName(msg.sender, _name);
        return true;
    }

function name(address _writer) public view returns (string memory _name) {
        return names[_writer];
    }

function read(uint256 _id) public view returns (address writer, string memory message, string memory _name, uint256 _time) {
        return (data[_id].writer, data[_id].message, names[data[_id].writer], data[_id].time);
    }

}