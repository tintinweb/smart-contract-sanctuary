/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

pragma solidity 0.8.4;

/* 
* Property of Fey. Version 1.0.0 
* 
* RULES Play_Guess
* The algorithm generates a pseudo-random number between 0 and 5.
* You can't bet more than MAX_VALUE.
* MAX_VALUE = ETH_SUPPLY/100.
* The winning reward is 5 times the bet.
*
* RULES Play_Even_Or_Odd
* The algorithm generates a pseudo-random number even or odd.
* You can't bet more than MAX_VALUE.
* MAX_VALUE = ETH_SUPPLY/100.
* The winning reward is 1.9 times the bet.
*
*/

contract GuessMyNumber {
   address payable admin;
   uint256 constant K = 5;
   uint256 public ETH_SUPPLY;
   uint256 public MAX_VALUE;
   
   event YOU_WON(address winner, uint256 reward);
   event YOU_LOSE(address loser, uint256 contract_reward, uint256 winning_number);
   
   constructor() payable {
       require(msg.value == 5 ether);  
       ETH_SUPPLY = msg.value;
       MAX_VALUE = ETH_SUPPLY/100;
       admin = payable(msg.sender);
   }
   
    modifier onlyAdmin() {
       require(msg.sender == admin);
       _;
   }
    
    modifier range() {
        require(msg.value != 0);
        require(msg.value <= MAX_VALUE);
        _;
    }
    
    function Play_Guess(uint256 x) public range payable {
        uint256 r;
        
        ETH_SUPPLY += msg.value;
        
        r = block.timestamp;
        
        if(x >= 0 && x < 6)
        {
            
        
            if( r % 6 == 0)
            {
                //0
                if ( x == 0)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
            
            if(r % 6 == 1)
            {
                //1
                if ( x == 1)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
            
            if( r% 6 == 2)
            {
                //2
                if ( x == 2)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
            
            if( r % 6 == 3)
            {
                //3
                if ( x == 3)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
            
            if( r % 6 == 4)
            {
                //4
                if ( x == 4)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
          
            if( r % 6 == 5)
            {
                //5
                if ( x == 5)
                {
                    payable(msg.sender).transfer(msg.value * K);
                    ETH_SUPPLY = ETH_SUPPLY - msg.value * K;
                    emit YOU_WON(msg.sender,msg.value * K);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
        }
        
        MAX_VALUE = ETH_SUPPLY/100;
    }
    
    function Play_Even_Or_Odd(uint256 Even_0__Odd_1) public range payable {
        uint256 r;
        uint256 reward = msg.value * 2 - msg.value / 10;
        
        ETH_SUPPLY += msg.value;
        
        r = block.timestamp;
        
        if( Even_0__Odd_1 >= 0 && Even_0__Odd_1 < 2)
        {
        
            if( r % 2 == 0)
            {
                
                //Even
                if( Even_0__Odd_1 == 0)
                {
                payable(msg.sender).transfer(reward);
                ETH_SUPPLY = ETH_SUPPLY - reward;
                emit YOU_WON(msg.sender,reward);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 6); }
            }
            
            if( r % 2 == 1)
            {
                
                //Odd
                if( Even_0__Odd_1 == 1) 
                {
                payable(msg.sender).transfer(reward);
                ETH_SUPPLY = ETH_SUPPLY - reward;
                emit YOU_WON(msg.sender,reward);
                }
                else{ emit YOU_LOSE(msg.sender,msg.value, r % 2); }
            }
        }    
        
        MAX_VALUE = ETH_SUPPLY/100;
        
    }
    
    function withdraw(uint256 amount) onlyAdmin public {
        
        if(amount <= ETH_SUPPLY){
        payable(msg.sender).transfer(amount);
        ETH_SUPPLY = ETH_SUPPLY - amount;
        }
    }
    
}