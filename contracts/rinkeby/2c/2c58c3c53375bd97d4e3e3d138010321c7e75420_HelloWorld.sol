/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract HelloWorld {
    enum Status{ 
        CONNECTED, 
        BLOCKED,
        JOINED, 
        AWAITING, 
        REQUESTED
    }
    mapping(address => mapping(address => uint256)) private _position;
    mapping(address => mapping(address => mapping(uint256 => string))) private _messages;
    mapping(address => mapping(address => Status)) private _connection;
    mapping(address => mapping(address => Status)) private _contacts;    
    mapping(address => Status) private _users;
    
    function getConnection(address from, address to) public view returns(Status){
        Status connection = _connection[from][to];
        return connection;
    }
    
    
    function sendMessage(address from, address to, string memory message) public {
        _assertConnection(from, to);
        uint256 position = getLastMessagePosition(from, to);
        _messages[from][to][position + 1] = message;
    }
    
    function requestConnection(address from, address to) public  view{
        Status myStatus = _users[from];
        require(myStatus == Status.JOINED, "You are not joined!");
        Status targetStatus = _users[to];
        require(targetStatus == Status.JOINED, "Target user not joined!");
        Status connection = _connection[from][to];
    }
    
    function compare(address a, address b) public pure returns(bool) {
        return a > b;
    }
    
    function join(address me) public {
        Status myStatus = _users[me];
        require(myStatus == Status.JOINED, "Already Joined!");
        _users[me] = Status.JOINED;
    }
    
    function getMessage(address from, address to, uint256 position) public view returns(string memory message){
        _assertConnection(from, to);
        return _messages[from][to][position];
    }
    
    function _assertConnection(address from, address to) private view {
        Status connection = getConnection(from, to);
        require(connection == Status.CONNECTED, "These addresses were not connected!");
    }
    
    function getLastMessagePosition(address from, address to) public view returns(uint256){
        _assertConnection(from, to);
        return _position[from][to];
    }
}