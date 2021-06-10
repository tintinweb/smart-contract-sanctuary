/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.0;

contract GameReveal {
    uint timeOut; // time to commit solution proposal
    bytes32 hash; // hash(solution + salt)  hash = hash(bienvenue, qwertyuasdf)
    string solution;
    address owner;
    
    mapping(address => bytes32) public playersToCommitChoice;
    
    constructor(uint _timeOut) {
        owner = msg.sender;
        timeOut = _timeOut;
    }
    
    /* Manager sets the hash and send the reward */
    function setHash(bytes32 _hash) payable external {
        require(owner == msg.sender);

        hash = _hash;
    }
    
    /* Player tries to find the solution by putting a hash to get the reward. */
    function play(bytes32 _proposalSolution) payable external {

        // check if less the timeout require()
        require(block.timestamp < timeOut);

        // put to userToCommitChoice
        playersToCommitChoice[msg.sender] = _proposalSolution;
    }
    
    // call by the owner
    // NOTE: this function can be external but only the owner knows the salt and can use correctly
    function reveal(string memory _solution, string memory _salt) external {
        // faut que soit après le timeout
        require(owner == msg.sender);
        require(block.timestamp >= timeOut);
        require(keccak256(abi.encodePacked(_solution, _salt)) == hash);
        
        // reveal la solution 
        solution = _solution;
    }
    
    // call by the winner
    function claim(string memory _solution, string memory _salt) payable external {
        // si c'est la bonne solution on lui envoie la récompense
        require(keccak256(abi.encodePacked(_solution, _salt)) == hash);
        address payable player = payable(msg.sender);
        require(address(this).balance > 0);
        // Envoie toute la balance (monaire) à celui qui à résolu le contract
        // player.transfer(address(this).balance);
        player.transfer(getRewardAmount());
        
    }
    
    function getHash(string memory _solution, string memory _salt) pure external returns (bytes32){
        return keccak256(abi.encodePacked(_solution, _salt));
    }
    
    
    function getRewardAmount() internal view returns (uint)  {
        return address(this).balance;
    }
}