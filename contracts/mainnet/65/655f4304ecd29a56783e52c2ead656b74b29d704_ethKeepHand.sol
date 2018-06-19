pragma solidity^0.4.18;

contract Owned {
    address owner;
    
    modifier onlyowner(){
        if (msg.sender == owner) {
            _;
        }
    }

    function Owned() internal {
        owner = msg.sender;
    }
}



contract ethKeepHand is Owned{

    struct DepositItem{
        
        uint depositDate;     //Date of deposit
        uint256 depositValue; //The amount of deposit
        uint depositTime;     //The terms of deposit
        uint  valid;          //The address is in the state of deposit:
                              //1 indicates that there is a deposit in the corresponding address, and 0 indicates no.
    }

     mapping(address => DepositItem)  DepositItems;

     event DepositTime(uint time);
     
     //Judge whether you can withdraw money
     modifier withdrawable(address adr){

         require(this.balance >= DepositItems[adr].depositValue);
         _;
     }
    
    //Determine whether you can deposit money
    modifier isright()
    {
        require(DepositItems[msg.sender].valid !=1);
        _;
    }



    //deposit
    function addDeposit(uint _time) external payable isright{
         
         DepositTime(_time);
         DepositItems[msg.sender].depositDate = now;
         DepositItems[msg.sender].depositValue = msg.value;
         DepositItems[msg.sender].depositTime = _time;
         DepositItems[msg.sender].valid =1;

     }

     //Note how many days are left until the date of withdrawal.
     function withdrawtime() external view returns(uint){
       
       if(DepositItems[msg.sender].depositDate + DepositItems[msg.sender].depositTime > now){
         return DepositItems[msg.sender].depositDate + DepositItems[msg.sender].depositTime - now;
       }
       
        return 0;
     }

     //withdrawals
     function withdrawals() withdrawable(msg.sender) external{

        DepositItems[msg.sender].valid = 0;
        uint256 backvalue = DepositItems[msg.sender].depositValue;
        DepositItems[msg.sender].depositValue = 0;
        msg.sender.transfer(backvalue);


     }
    
     //Amount of deposit
    function getdepositValue()  external view returns(uint)
     {
        
        return DepositItems[msg.sender].depositValue;
     }
     //Contract balance
     function getvalue() public view returns(uint)
     {
         
         return this.balance;
     }
      //Decide whether to deposit money
     function  isdeposit() external view returns(uint){

         return DepositItems[msg.sender].valid;
       }


      function() public payable{
          
          revert();
      }
}