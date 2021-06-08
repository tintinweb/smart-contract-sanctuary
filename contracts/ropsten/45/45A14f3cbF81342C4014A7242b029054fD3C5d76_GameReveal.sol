/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity ^0.8.0;

contract GameReveal {
    bytes32 hash;
    
    /* Manager sets the hash and send the reward */
    function setHash(string memory _solution) payable external {
        hash = keccak256(abi.encode(_solution));
    }
    
    /* Player tries find the solution by putting a hash to get the reward */
    function play(string memory _solution) payable external {
        require(hash == keccak256(abi.encode(_solution)));
        
        //send reward
        address payable player = payable(msg.sender);
        
        player.transfer(address(this).balance);
        
    }
}