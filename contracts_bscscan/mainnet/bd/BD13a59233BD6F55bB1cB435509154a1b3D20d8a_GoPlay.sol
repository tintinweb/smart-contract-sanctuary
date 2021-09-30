/**
 *Submitted for verification at BscScan.com on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract GoPlay {
    
    uint256 public price;
    bool public paused = false;
    address public owner;
    address public newContractOwner;
    mapping(address => uint256) public registeredPlayers;
 
    event Pause();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor (uint256 _price) {
        owner = msg.sender;
        price = _price;
    }
 
    modifier ifNotPaused {
        require(!paused);
        _;
    }
 
    modifier onlyContractOwner {
        require(msg.sender == owner);
        _;
    }
 
    function transferOwnership(address _newOwner) external onlyContractOwner {
        require(_newOwner != address(0));
        newContractOwner = _newOwner;
    }
 
    function acceptOwnership() external {
        require(msg.sender == newContractOwner);
        emit OwnershipTransferred(owner, newContractOwner);
        owner = newContractOwner;
        newContractOwner = address(0);
    }
 
    function setPause(bool _paused) external onlyContractOwner {
        paused = _paused;
        if (paused) {
            emit Pause();
        }
    }
 
    function setPrice(uint256 _price) external onlyContractOwner {
        price = _price;
    }
 
    function registerPlayer() external payable ifNotPaused {
        require(msg.value >= price);
        registeredPlayers[msg.sender] = block.timestamp;
    }

    receive() external payable {
        
    }
    
    fallback() external payable {
        revert();
    }
    
    function withdrawBalance(uint256 _amount) external onlyContractOwner {
        payable(owner).transfer(_amount);
    }
   
}