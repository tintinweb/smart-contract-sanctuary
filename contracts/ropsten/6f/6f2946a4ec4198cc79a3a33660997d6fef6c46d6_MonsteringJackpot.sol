/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

pragma solidity 0.5.11;

interface Monstering{
    function getCurrentJackpotUser(uint id) external view returns(address);
     function getCurrentJackpotId() external view returns(uint);
     function getPool3currId() external view returns(uint);
}



contract MonsteringJackpot{
    
     address public owner;
    address monsteringcontract=0x452915842BF1246941089FB6e39aCf2655c4334C;
    event Deposite(uint amount,uint time);
    event Winner(uint amount,uint time,address winner);
    uint public nooftime=0;
    uint  counter=0;
      struct PoolUserStruct {
        bool isExist;
       bool paid;
       address user;
    }
    mapping (address => PoolUserStruct) public jackpotwinnerList;
     
    constructor() public
    {
     owner=msg.sender;   
    }
    
    function depositeFund() public payable
    {
        emit Deposite(msg.value,now);
    }
    
    function jackpotWinner() public
    {
        require(msg.sender==owner,"You are not authorized");
        counter=0;
      declareWinner();
    }
    
    function declareWinner() private
    {
        uint id= getJackpotId();
       uint Pool3currId=getPool3id();
       bool sent=false;
       
       /* To find users from 1 to 1000 then 1001 to 2000 and so on ....*/  
       if(Pool3currId>=(1000*(nooftime+1))){
        uint lower=1;
        uint num = (block.timestamp % ((id) - lower + 1)) + lower; 
        
        address winner=Monstering(monsteringcontract).getCurrentJackpotUser(num);
        
        if(!jackpotwinnerList[winner].paid){
        
          require(winner!=address(0),"address invalid ");
        sent = address(uint160(Monstering(monsteringcontract).getCurrentJackpotUser(num))).send(101 ether);
 
            if (sent) {
                 /* Number of time distributed jackpot winning amount....*/  
                nooftime+=1;
                 PoolUserStruct memory pooluserStruct;
                   pooluserStruct = PoolUserStruct({
            isExist:true,
            paid:true,
            user:winner
        });
        jackpotwinnerList[winner]=pooluserStruct;
        
                emit Winner(num,now,winner);
            }
            else{
           require(false,"Error occured while transfer");
            }
       }
       else
       {
           counter++;
           declareWinner();
       }
       
       }
       require(sent,"Allready declared winner or transfer is not possible");
    }
   
     function getJackpotId() public view returns (uint)
    {
        return Monstering(monsteringcontract).getCurrentJackpotId();
    }
    
     function getPool3id() public view returns (uint)
    {
        return Monstering(monsteringcontract).getPool3currId();
    }
    
  
    
   
        
    function getEthBalance() public view returns(uint) {
    return address(this).balance;
    }
    
    
    function sendPendingBalance(uint amount) public
    {
         require(msg.sender==owner, "You are not authorized");  
        if(msg.sender==owner){
        if(amount>0 && amount<=getEthBalance()){
         if (!address(uint160(owner)).send(amount))
         {
             
         }
        }
        }
    }
    
}