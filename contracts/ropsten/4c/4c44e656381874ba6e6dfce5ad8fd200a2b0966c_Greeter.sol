/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

pragma solidity >=0.7.0 <0.8.0;

contract Greeter {
    
    bool paused;
    mapping(address => bool) public admins;
    
    event Greeting(string text, address sender);
    
    constructor() {
        admins[msg.sender] = true;
    }
    
    modifier notPaused {
        require(!paused);
        _;
    }
    
    modifier adminOnly {
        require(admins[msg.sender]);
        _;
    }
    
    function addAdmin(address addr) adminOnly public {
        admins[addr] = true;
    }
    
    function dropAdmin(address addr) adminOnly public {
        admins[addr] = false;
    }
    
    function pause() adminOnly public {
        paused = true;
    }
    
    function unpause() adminOnly public {
        paused = false;
    }
    
    function greet(string memory text) notPaused public {
        require(keccak256(bytes(text)) != keccak256(bytes("invalid")));
        emit Greeting(text, msg.sender);
    }
    
}