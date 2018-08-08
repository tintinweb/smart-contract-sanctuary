/*
MIT License

Copyright (c) 2018 Nguyen Vu Nhat Minh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity ^0.4.20;

contract EtherChat {
    event messageSentEvent(address indexed from, address indexed to, bytes message, bytes32 encryption);
    event addContactEvent(address indexed from, address indexed to);
    event acceptContactEvent(address indexed from, address indexed to);
    event profileUpdateEvent(address indexed from, bytes32 name, bytes32 avatarUrl);
    event blockContactEvent(address indexed from, address indexed to);
    event unblockContactEvent(address indexed from, address indexed to);
    
    enum RelationshipType {NoRelation, Requested, Connected, Blocked}
    
    struct Member {
        bytes32 publicKeyLeft;
        bytes32 publicKeyRight;
        bytes32 name;
        bytes32 avatarUrl;
        uint messageStartBlock;
        bool isMember;
    }
    
    mapping (address => mapping (address => RelationshipType)) relationships;
    mapping (address => Member) public members;
    
    function addContact(address addr) public onlyMember {
        require(relationships[msg.sender][addr] == RelationshipType.NoRelation);
        require(relationships[addr][msg.sender] == RelationshipType.NoRelation);
        
        relationships[msg.sender][addr] = RelationshipType.Requested;
        emit addContactEvent(msg.sender, addr);
    }

    function acceptContactRequest(address addr) public onlyMember {
        require(relationships[addr][msg.sender] == RelationshipType.Requested);
        
        relationships[msg.sender][addr] = RelationshipType.Connected;
        relationships[addr][msg.sender] = RelationshipType.Connected;

        emit acceptContactEvent(msg.sender, addr);
    }
    
    function join(bytes32 publicKeyLeft, bytes32 publicKeyRight) public {
        require(members[msg.sender].isMember == false);
        
        Member memory newMember = Member(publicKeyLeft, publicKeyRight, "", "", 0, true);
        members[msg.sender] = newMember;
    }
    
    function sendMessage(address to, bytes message, bytes32 encryption) public onlyMember {
        require(relationships[to][msg.sender] == RelationshipType.Connected);

        if (members[to].messageStartBlock == 0) {
            members[to].messageStartBlock = block.number;
        }
        
        emit messageSentEvent(msg.sender, to, message, encryption);
    }
    
    function blockMessagesFrom(address from) public onlyMember {
        require(relationships[msg.sender][from] == RelationshipType.Connected);

        relationships[msg.sender][from] = RelationshipType.Blocked;
        emit blockContactEvent(msg.sender, from);
    }
    
    function unblockMessagesFrom(address from) public onlyMember {
        require(relationships[msg.sender][from] == RelationshipType.Blocked);

        relationships[msg.sender][from] = RelationshipType.Connected;
        emit unblockContactEvent(msg.sender, from);
    }
    
    function updateProfile(bytes32 name, bytes32 avatarUrl) public onlyMember {
        members[msg.sender].name = name;
        members[msg.sender].avatarUrl = avatarUrl;
        emit profileUpdateEvent(msg.sender, name, avatarUrl);
    }
    
    modifier onlyMember() {
        require(members[msg.sender].isMember == true);
        _;
    }
    
    function getRelationWith(address a) public view onlyMember returns (RelationshipType) {
        return relationships[msg.sender][a];
    }
}