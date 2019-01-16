pragma solidity ^0.4.24;

contract Versionchain {

string public Codename;    
uint public version;
string public Contributor;
uint public Codedate;
address public Codename_;
address public version_;
address public Contributor_;
address public Codedate_;

constructor() public {
Codename_ = msg.sender;
version_ = msg.sender;
Contributor_ = msg.sender;
Codedate_ = msg.sender;
}


function setCodename(string _Codename) public {
Codename = _Codename;
}

function setversion(uint _version) public {
version = _version;
}

function setContributor(string _Contributor) public {
Contributor = _Contributor;
}

function setCodedate(uint _Codedate) public {
Codedate = _Codedate;
}
}