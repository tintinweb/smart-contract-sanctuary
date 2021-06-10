/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.0;

contract GameReveal {
    uint timeOut; // time to commit solution proposal
    bytes32 hash; // hash(solution + salt)  hash = hash(bienvenue, qwertyuasdf)
    string public solution;
    address owner;
    uint timestampStart;
    
    mapping(address => bytes32) public playersToCommitChoice;
    
    constructor(uint _timeOut) {
        owner = msg.sender;
        timeOut = _timeOut;
        timestampStart = block.timestamp;
        solution = "";
    }
    
    function getHash(string memory _solution, string memory _salt) pure private returns(bytes32) {
        return keccak256(abi.encodePacked(_solution, _salt));
    }
    
    function getHashExt(string memory _solution, string memory _salt) pure external returns(bytes32) {
        return getHash(_solution,_salt);
    }
    
    function checkHash(string memory _solution, string memory _salt) view private {
        require(hash == getHash(_solution,_salt));
    }
    
    
    /* Manager sets the hash and send the reward */
    function setHash(bytes32 _hash) payable external {
        require(owner == msg.sender);

        hash = _hash;
    }
    
    /* Player tries to find the solution by putting a hash to get the reward. */
    function play(bytes32 _proposalSolution) payable external {
        // check if less the timeout require()
        checkTimeOut();
        
        // put to playersToCommitChoice
        address playerAddress = msg.sender;
        
        playersToCommitChoice[playerAddress] = _proposalSolution;
        
    }
    
    // call by the owner
    // NOTE: this function can be external but only the owner knows the salt and can use correctly
    function reveal(string memory _solution, string memory _salt) external returns(string memory) {
        // faut que soit après le timeout
        checkTimeOut();
        
        // reveal la solution 
        checkHash(_solution, _salt);
        //publier la solution
        solution = _solution;
        playersToCommitChoice[address(this)] = hash;
        
        return _solution;
    }
    
    // call by the winner
    function claim(string memory _solution, string memory _salt) payable external {
        // si c'est la bonne solution on lui envoie la récompense
        // check if less the timeout require()
        checkTimeOut();
        checkHash(_solution, _salt);
        
        // send reward
        address payable player = payable(msg.sender);
       
        player.transfer(address(this).balance);
    }
    
    function getRewardAmount() external view returns (uint)  {
        return address(this).balance;
    }
    
    function checkTimeOut() public view {
        require(block.timestamp-timestampStart > timeOut);
    }
    
    function checkTimeOutExt() external view {
        checkTimeOut();
    }
}