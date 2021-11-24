/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT 
 
pragma solidity >=0.5.0 <0.9.0;
 
contract Pool{
    
    address payable[] public players; // dynamic array of type address payable
    address public admin;
    address payable public winnerAddress;
    uint public createTime;
    
    enum POOL_STATE {
        OPEN, CLOSED
    }
    POOL_STATE public pool_state;
    
    uint constant day1 = 86400;
    uint constant day2 = 172800;
    uint constant day3 = 259200;
    
    constructor(){
        
        admin = msg.sender; // setting deployer as the admin
        pool_state = POOL_STATE.CLOSED; // initially the pool is closed 
    }
    modifier onlyWinner {
    require(msg.sender == winnerAddress);
    _;
    }
    
    // this is required to receive ETH
    receive () payable external{
        require(pool_state == POOL_STATE.OPEN); // can only accept ETH if the pool is open
        require(msg.value == 0.01 ether); // each player sends exactly 0.01 ETH, not more, not less 
        players.push(payable(msg.sender)); // add the player to the array
    }
    
    function startPool() public {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.CLOSED, "The pool is already open");
        pool_state = POOL_STATE.OPEN; // if admin calls this function then the state changes to OPEN and everyone can contribute in the pool
    }
    
    function endPool() public {
        require(msg.sender == admin);
        require(pool_state == POOL_STATE.OPEN, "The pool is already closed");
        pool_state = POOL_STATE.CLOSED; // if admin calls this function then the state changes to CLOSED and nobody can contribute in the pool
    }
    
    // only for admin to check the balance of the contract
    function getBalance() public view returns(uint){

        return address(this).balance;
    }
    
    // helper function that returns a big random integer
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function announceWinner(address payable _winnerAddress) public {
        require(msg.sender == admin); // admin will announce the winner
        winnerAddress = _winnerAddress;
        displayWinner();
        createTime = block.timestamp; // time stamp will be created
    }
    function displayWinner() public view returns(address) {
        return winnerAddress;
    }
    
    // selecting the winner
    function winnerWithdraw() public onlyWinner{
        // only the winner can call this function and withdraw the funds
        
        if(createTime < day1){ // winner gets 70% of the balance if they try to claim on the 1st day
            winnerAddress.transfer((getBalance()*70) / 100);
            payable(admin).transfer((getBalance()*30) / 100);
        }
        else if(createTime > day1 && createTime < day2){ // winner gets 80% of the balance if they try to claim on the 2nd day
            winnerAddress.transfer((getBalance()*80) / 100);
            payable(admin).transfer((getBalance()*20) / 100);
        }
        else if (createTime > day1 && createTime > day2 && createTime < day3){ // winner gets 90% of the balance if they try to claim on the 3rd day
            winnerAddress.transfer((getBalance()*90) / 100);
            payable(admin).transfer((getBalance()*10) / 100);
        }
        else { // winner gets 95% of the balance after 3 days.
            winnerAddress.transfer((getBalance()*95) / 100);
            payable(admin).transfer((getBalance()*5) / 100);
        }
        
    }
}