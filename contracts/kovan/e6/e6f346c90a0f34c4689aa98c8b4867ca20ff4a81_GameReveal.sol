/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.0;

contract GameReveal {
    uint timeOut; // time to the commit period
    string public solution;

    bytes32 hash; // hash(solution + salt)
    address owner;
    
    mapping(address => bytes32) playersToCommitChoice;
    
    constructor() {
        owner = msg.sender;
    }
    
    /* Manager sets the hash and send the reward */
    function setHash(bytes32 _hash, uint _gameTime) payable external {
        require(owner == msg.sender);

        timeOut = _gameTime + block.timestamp;
        hash = _hash;
    }
    
    /* Player tries to find the solution by putting a hash to get the reward. */
    function play(bytes32 _proposalSolution) external {
        require(block.timestamp < timeOut, "Too late to submit a proposal");

        playersToCommitChoice[msg.sender] = _proposalSolution;
    }
    
    // call by the owner
    // NOTE: this function can be external but only the owner knows the salt and can use correctly
    function reveal(string memory _solution, string memory _salt) external {
        require(block.timestamp > timeOut, "Wait for the Reveal period");
        require(keccak256(abi.encodePacked(_solution, _salt)) == hash, "Bad solution");
        
        solution = _solution;
    }
    
    // call by the winner
    function claim(string memory _solution, string memory _salt) payable external {
        require(keccak256(abi.encodePacked(_solution, _salt)) == playersToCommitChoice[msg.sender], "Your solution does not match with your hash");
        require(keccak256(abi.encodePacked(_solution)) == keccak256(abi.encodePacked(solution)), "Your solution does not match with the solution");
        
        address payable player = payable(msg.sender);
        
        player.transfer(address(this).balance);
    }
    
    function computeHash(string memory _solution, string memory _salt) pure external returns (bytes32) {
        return keccak256(abi.encodePacked(_solution, _salt));
    }
    
    function getRewardAmount() external view returns (uint)  {
        return address(this).balance;
    }
    
    // Time left to play 
    function getRemainingTime() external view returns (uint)  {
        if (block.timestamp > timeOut) {
            return 0;
        }

        return timeOut - block.timestamp;
    }
}