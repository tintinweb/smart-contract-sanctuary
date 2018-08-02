pragma solidity ^0.4.24;

contract depowithdraw {

    mapping(address=>uint) public balance;
    
    function deposit() public payable{
        updateBalance(msg.value,true);
    }

    function withdrawAmount(uint amount) public{
        require(amount<=balance[msg.sender]);
        updateBalance(amount,false);
        msg.sender.transfer(amount);
    }
    
    function updateBalance(uint amount,bool increase) internal{
        if(increase){
            balance[msg.sender]+=amount;
        }
        else{
            balance[msg.sender]-=amount;
        }
    }
}