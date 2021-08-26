/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Cookies {
    /**
     * The Cookies contract is a small piece of codelines to
     * register actions through machines calling a servers hosted code of so called websites.. .or
     * any other fitting need.
     * 
     * Contact the dev of this Contract and it's using code on https://laubenheimer.eu via that site.
     */
    struct Session {
        string ip;
        uint timestampStart;
        uint timestampLastAction;
        uint[] actions;
    }

    modifier isOwner() { 
        require(owner == payable(address(msg.sender)), "You're not the owner.");
        _;
    }

    event Activity(string description);
    event Activity(string description, uint ID);
    
    address payable public owner;
    mapping(string => uint[]) public visitors;
    Session[] public sessions;
    uint[] private actions;
    //@notice Contract-initialization, setting the owner//
    constructor() {
        owner = payable(address(msg.sender));
        actions.push(0);
        emit Activity("Initialisation of this Cookiecontract.");
    }
    
    receive () external payable {
        require(msg.value > 0);
        emit Activity("ETH-Donation received.");
    }

    function emptyTocket () external isOwner() {
        uint _amount = address(this).balance;
        require(_amount > 0);
        require(owner.send(_amount));
        emit Activity("Cleared ETH-Amount to owner.");
    }
    
    function initSession (string memory ip) external isOwner() returns(uint) {
        visitors[ip].push(sessions.length);
        uint  _timestamp = block.timestamp;
        Session memory newSession = Session(ip, _timestamp, _timestamp, actions);
        sessions.push(newSession);
        emit Activity("Init new session, sessionID: ", sessions.length - 1);
        return sessions.length - 1;
    }
    
    //@notice Here the contract contract-owner can add actions made on the web-Application.
    function webAppAction (string memory ip, uint buttonID, uint sessionID) external isOwner() returns(bool) {
        require(keccak256(bytes(sessions[sessionID].ip)) == keccak256(bytes(ip)), "Wrong Credentials.. ");
        sessions[sessionID].actions.push(buttonID);
        sessions[sessionID].timestampLastAction = block.timestamp;
        emit Activity("Button activated, buttonID: " , buttonID);
        return true;
    }
    
    //@notice These calls can be used to read the collected data in this contract.
    function getOwner() public view returns(address) {
        return owner;
    }
    function getVisitorCounter() public view returns(uint) {
        return sessions.length;
    }
    function getRegisteredVisitsFrom(string calldata ip) public view returns(uint[] memory) {
        return visitors[ip];
    }
    function getSession (uint ID) public view returns(Session memory) {
        return sessions[ID];
    }    
}