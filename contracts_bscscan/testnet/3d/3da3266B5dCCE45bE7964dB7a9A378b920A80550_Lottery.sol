/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.2;


/** 
 * @title Lottery
 * @dev Ether lotery that transfer contract amount to winner
*/  
contract Lottery {
    
    //list of players registered in lotery
    address payable[] public players;
    address public admin;
    uint public totalPlayers = 0;
    
    /**
     * @dev makes 'admin' of the account at point of deployement
     */ 
    constructor() {
        admin = msg.sender;
        //automatically adds admin on deployment
        players.push(payable(admin));
    }
    

    
    
    /**
     * @dev requires the deposit of 0.1 ether and if met pushes on address on list
     */ 
   receive () external payable {
        //require that the transaction value to the contract is 0.1 ether
        require(msg.value == 0.01 ether , "Must send 0.01 ether amount");
        
        //makes sure that the admin can not participate in lottery
        require(msg.sender != admin);
        
        totalPlayers += 1;

        if (totalPlayers <= 1){
                    // pushing the account conducting the transaction onto the players array as a payable adress
        players.push(payable(msg.sender));
        } else { 
            pickWinner();
        }

    }
    
    /**
     * @dev gets the contracts balance
     * @return contract balance
    */ 
    function getBalance() public view returns(uint){
        // returns the contract balance 
        return address(this).balance;
    }
    
    /**
     * @dev generates random int *WARNING* -> Not safe for public use, vulnerbility detected
     * @return random uint
     */ 
    function random() internal view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    /** 
     * @dev picks a winner from the lottery, and grants winner the balance of contract
     */ 
    function pickWinner() public {


        
        address payable winner;
        
        //selects the winner with random number
        winner = players[random() % players.length];
        
        //transfers balance to winner
        winner.transfer( (getBalance() * 90) / 100); //gets only 90% of funds in contract
        payable(admin).transfer( (getBalance() * 10) / 100); //gets remaining amount AKA 10% -> must make admin a payable account
        
        
        //resets the plays array once someone is picked
       resetLottery();
       totalPlayers = (0);
        
    }
    
    /**
     * @dev resets the lottery
     */ 
    function resetLottery() internal {
        players = new address payable[](0);
    }

}