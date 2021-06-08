/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity 0.8.0;

contract GameReveal {
    bytes32 public hash;
    address owner;
    
    constructor() {
        owner= msg.sender;
    }
    
    // Manage sets the hash
    function setHash(bytes32 _hash) external {
        require(owner == msg.sender);
        
        hash = _hash;
    }
    
    function getHash(string memory _solution) pure external returns(bytes32) {
        return keccak256(abi.encode(_solution));
    }
    
    function play(string memory _solution) payable external {
        require(hash == keccak256(abi.encode(_solution)));
        
        address payable player = payable(msg.sender);
        
       player.send(address(this).balance);
        // Send reward
    }
    
    function getReward() external view returns(uint) {
        return address(this).balance;
    }
}