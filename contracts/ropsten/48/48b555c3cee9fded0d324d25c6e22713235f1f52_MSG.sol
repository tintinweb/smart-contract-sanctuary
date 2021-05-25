/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity 0.8.4;

// "SPDX-License-Identifier: MIT"

contract MSG {
    struct Data {
        address writer;
        string  massage;
    }
    
    mapping (uint => Data) data;
    mapping(address => string) names;
    uint256 public id;
    event Massage(uint Id, address writer, string massage, string name);
    event SetName(address writer, string name);    

function write(string memory _massage) public returns (bool success) {
        data[id].writer = msg.sender;
        data[id].massage = _massage;
        emit Massage(id, msg.sender, _massage, names[msg.sender]);
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

function read(uint256 _id) public view returns (address writer, string memory massage) {
        return (data[_id].writer, data[_id].massage);
    }

}