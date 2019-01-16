pragma solidity 0.4.24;

contract sendeth {
    
    address public admin;
    address public deposit;
    address public depositer;
  
 
   constructor(address _deposit) public{
        deposit = _deposit;
        admin = msg.sender;
        
   }
   
     modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }
 
    
     function changeDepositAddress(address newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
    event Payeth(address investor, uint value);
    
    function payeth() payable public returns(bool){
       
        
        deposit.transfer(msg.value);
        
        emit Payeth(msg.sender, msg.value);
        
        return true;
        
    }
    
     function () payable public{
        payeth();
    }  
  
}

 // function payeth1(address receiver, uint value) payable public returns(bool){
    //   depositer = receiver;
        
      //  depositer.transfer(value);
        
     //   emit Payeth(msg.sender, msg.value);
        
    //    return true;
        
  //  }