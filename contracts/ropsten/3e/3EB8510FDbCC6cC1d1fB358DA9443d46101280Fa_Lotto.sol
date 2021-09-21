/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Lotto {
    address payable[] public players;
    mapping(address  => uint) public playerMap;
    address public manager;
    uint public slotValue = 10000000000000000;
    uint public startBlock;
    uint public endBlock;
    enum state {Running, Maintenance}
    state public lottoryState;
    uint public lotteryDuration=604800;
    address payable public  winner;
    
    
    constructor(){
        manager = msg.sender;
        startBlock = block.number;
        endBlock = startBlock + (604800/15); // (60 * 60 * 24 * 7)/15 -- auction to run for a week 
        lottoryState = state.Running;
        
    }
    
      modifier managerOnly(){
        require( msg.sender == manager);
        _;
    }
    
     modifier afterStart(){
        require( block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require( block.number <= endBlock);
        _;
    }
    
    receive() external payable  afterStart beforeEnd {
        require(msg.value >= slotValue);
        require(msg.sender != manager);
        players.push(payable(msg.sender)); //payable converts a plain address to a payable one
        playerMap[msg.sender] += msg.value;
        //
    }
    
    function setMaintenance() public managerOnly {
        lottoryState = state.Maintenance;
    }
    
    function enter() public payable  afterStart beforeEnd {
        require(msg.value >= slotValue);
        require(msg.sender != manager);
        for(uint i=0; i< (msg.value/slotValue); i++ ) {
            players.push(payable(msg.sender)); //payable converts a plain address to a payable one
        }
        playerMap[msg.sender] += msg.value;
        //players.push(payable(msg.sender)); //paya
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function getMyValue(address _address) public view returns(uint){
        return playerMap[_address];
    }

     function getContract() public view returns(address){
        return address(this);
    }

    
    
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));

    }
    
    function getPlayers() public view returns(uint){
        return players.length;
    }
    
    function resetMapping(uint256 value) private {
        for (uint i=0; i<players.length; i++){
            playerMap[players[i]] = value;
        }
        
    }
    
    
    
      function pickWinner() public {
        require((lottoryState == state.Running && block.number >= endBlock && players.length >= 1) || (lottoryState == state.Maintenance && msg.sender == manager));
        
        uint index = uint(random() % players.length);
        
        uint fee = getBalance()/100;
        payable(manager).transfer(fee);
        
        winner =  players[index];
        
        winner.transfer(getBalance());
        
        resetMapping(0);
        
        players = new address payable[](0); // resetting the lottory by deplaring a dynamic empty array
    
    }
    
    fallback() external payable{
        
    }
}