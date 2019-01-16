pragma solidity 0.4.24;

contract Register {
    address public owner;
    string private info;

    constructor() public {
        owner = msg.sender;
    }
    
    function setInfo(string _info) public {
        info = _info;
    }
    
    function getInfo() public view returns (string infostring) {
        return info;
    }

    function kill() public { 
        if (msg.sender == owner)  // only allow this action if the account sending the signal is the creator / owner
            selfdestruct(owner);
    }
    
    function isAlive() public pure returns (bool) {
            return true;
    } 
        
}