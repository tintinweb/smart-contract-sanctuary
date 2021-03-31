/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.7.0 <0.9.0;

contract StrongHands{

    string name;
    address owner;
    

    struct Deposit{
        uint userBalance;
        uint time;
        uint bonus;
        
    }
    
     mapping(address => Deposit) public deposits;
     address[] private users;
     
     constructor () {
         name = "Strong Hands";
         owner = msg.sender;
     }
     
    function deposit() payable public {
        Deposit storage deposit = deposits[msg.sender];
        users.push(payable(msg.sender));
        if(deposit.userBalance == 0){
            deposit.time = block.timestamp;
            deposit.userBalance = msg.value;
            deposit.bonus = 0; 
        }else{
            deposit.userBalance += msg.value;
            deposit.time = block.timestamp;
        }
    }
    
    
    function withdraw() external{
        uint time = block.timestamp;
        Deposit storage deposit = deposits[msg.sender];
        require(deposit.userBalance != 0);
        if(time - deposit.time > 25 minutes){
            payable(msg.sender).transfer(deposit.userBalance + deposit.bonus);
            deposit.bonus = 0;
            deposit.userBalance = 0;
            deposit.time = 0;
        }else{
            uint timeDiff = (time - deposit.time) / 60;
            uint reducedPercent = 100 - 50 + timeDiff * 25;
            uint withdrawValue = (reducedPercent* deposit.userBalance + deposit.bonus) / 100;
            uint reducedValue = (100 - reducedPercent) * deposit.userBalance / 100;
            
            for(uint40 i = 0; i < users.length; i++){
                if(deposits[users[i]].userBalance != 0){
                    deposits[users[i]].bonus = (reducedValue * (deposits[users[i]].userBalance + deposits[users[i]].bonus)) / (address(this).balance - deposit.userBalance);
                }
            }
            payable(msg.sender).transfer(withdrawValue);
            deposit.bonus = 0;
            deposit.userBalance = 0;
            deposit.time = 0;
        }
    }
    
    
    function withdrawBonus() public{
        require(deposits[msg.sender].bonus != 0);
        payable(msg.sender).transfer(deposits[msg.sender].bonus);
        deposits[msg.sender].bonus = 0;
    }
    
    function seeDeposit() external view  returns (uint) {
        return deposits[msg.sender].userBalance;
    }
    
    function seeBonus() external view  returns (uint) {
        return deposits[msg.sender].bonus;
    }
     function seeBalance() external view  returns (uint) {
        return address(this).balance;
    }
    
    
    
}