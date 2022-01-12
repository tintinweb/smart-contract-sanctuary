pragma solidity ^0.8.0;

contract SyfinVerified {
    mapping (address => bool) private verifies;
    
    address[] public updates;

    event SetVerified(address indexed hashAddress, bool verified);
    
    address public owner;

    constructor ()  {
       owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setVerified(address addy, bool verified) public onlyOwner {
        
        updates.push(addy);
        
        verifies[addy] = verified;

        emit SetVerified(addy, verified);
    }

    function getVerified(address hashAddress) public view returns (bool) {
        return verifies[hashAddress];
    }
    
    function UpdateCount() public view returns (uint) {
        return updates.length;
    }
}