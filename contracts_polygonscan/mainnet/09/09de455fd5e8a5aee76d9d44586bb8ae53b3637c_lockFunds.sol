/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-04
*/

pragma solidity ^0.7.0;


contract lockFunds {
    
    string public name = "Lock Funds";
    
    uint8 public version = 3;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(address => uint256) public time;
    
    modifier notEarlier(uint256 _time){
        require(_time >= time[msg.sender]);
        _;
    }

    modifier isReady{
        require(block.timestamp >= time[msg.sender]);
        _;
    }

    constructor()public{}

    function createDep(uint256 _timestamp) notEarlier(_timestamp) payable public{
        time[msg.sender] = _timestamp;
        balanceOf[msg.sender] = msg.value + balanceOf[msg.sender];
    }

    function withdraw() isReady payable public {
        msg.sender.transfer(balanceOf[msg.sender]);
        time[msg.sender] = 0;
        balanceOf[msg.sender] = 0;
    }

}