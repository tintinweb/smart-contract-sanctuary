/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/* SPDX-License-Identifier: MIT */
pragma solidity 0.8.0;

contract GameReveal {
    uint timeOut; 
    bytes32 public hash;
    address owner;
    string solution;
    
    struct CommitChoicePlayer {
        bytes32 commitment;
        string salt;
    }
    
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
    
    function getHash(string memory _solutionPlayer, string memory _salt) pure external returns (bytes32) {
        return keccak256(abi.encodePacked(_solutionPlayer, _salt));
        
        
    }
    
    /* Player tries to find the solution by putting a hash to get the reward. */
    function play(bytes32  _solutionPlayer) payable external {
        
        require(block.timestamp < timeOut, "Sorry too late to play ");

        address payable player = payable(msg.sender);
        player.transfer(address(this).balance);

        playersToCommitChoice[msg.sender] = _solutionPlayer;
      
    }
    
    function reveal( string memory _solutionPlayer, string memory _salt) external {
        // après timeOut
        require(owner == msg.sender);
                require( (block.timestamp > timeOut && keccak256(abi.encodePacked(_solutionPlayer, _salt))== hash), " Sorry but no pain no gain, Play again !");
  
//        require(block.timestamp > timeOut );
//        require(keccak256(abi.encodePacked(_solutionPlayer, _salt))== hash, " Sorry, Play again !");
        // reveal solution
        solution = _solutionPlayer;
    }
 
    function getRewardAmount() internal view returns (uint)  {
        return address(this).balance;
    }

    function claim(string memory _solutionPlayer, string memory _salt) payable external {
        // si ok envoyer recompense
        require(keccak256(abi.encode(_solutionPlayer, _salt))== hash);
        address payable player = payable(msg.sender);
        require(address(this).balance >0);
        player.transfer(getRewardAmount());
    }
    
    
 
}