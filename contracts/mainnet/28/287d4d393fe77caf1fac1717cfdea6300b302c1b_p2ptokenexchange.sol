pragma solidity ^0.4.24;

   contract TCallee {

// Connection to other ERC20 smart contracts
 function transferFrom(address _from, address _to, uint256 _value) external returns (bool success){}

}
 
interface  ptopinterface  {
       //new exchange function
       function newExchange (address smart1, uint256 amount1, address two2, address smart2, uint256 amount2) external payable returns(uint exchangeId);
       //new exchange event
       event NewExchange (uint exchangeId, address one1, address indexed smart1, uint256 amount1, address two2, address indexed smart2, uint256 amount2);
      //get the exchange details
       function getExchange (uint _Id) external view returns (address _one1,address _smart1,uint256 _amount1, address _two2, address _smart2, uint256 _amount2, bool); 
       //cancek an exchange by one of the parties
       function cancelExchange (uint exchangeId) external payable returns (bool success);
       //cancel exchange event
       event CancelExchange (uint exchangeId);
       // do exchange function
       function doExchange (uint exchangeId) external payable returns (bool success);
       //do exchange event
       event DoExchange (uint exchangeId);
    
}

contract p2ptokenexchange is ptopinterface{
    
     address constant atokenaddress=0xf0B3BA2Dd4B2ef75d727A4045d7fBcc415B77bF0;//mainnet
    
    struct exchange {
        address one1;
        address smart1;
        uint256 amount1;
        address two2;
        address smart2;
        uint256 amount2;
        bool DealDone;
    }
    
    uint counter= 0;
    //mapping by counter 
    mapping (uint => exchange) exchanges;
    
    event NewExchange (uint exchangeId, address one1, address indexed smart1, uint256 amount1, address two2, address indexed smart2, uint256 amount2);
    event CancelExchange (uint exchangeId);
    event DoExchange (uint exchangeId);
    
    function newExchange (address smart1, uint256 amount1, address two2, address smart2, uint256 amount2) external payable returns(uint exchangeId) {
        require(msg.value>=206000000);
        exchangeId = counter;
        exchanges[exchangeId]=exchange(msg.sender,smart1,amount1,two2,smart2,amount2,false);
        counter +=1;
        if (exchanges[exchangeId].smart1==address(0)) {
        require(msg.value>=exchanges[exchangeId].amount1+206000000);
        uint256 amountTosend=(msg.value-exchanges[exchangeId].amount1);
        payether(atokenaddress, amountTosend);
        } else {
           require(payether(atokenaddress, msg.value)==true);   
        }
        emit NewExchange (exchangeId,msg.sender,smart1,amount1,two2,smart2,amount2);
        return exchangeId;
    }
    
    function getExchange (uint _Id) external view returns (address _one1,address _smart1,uint256 _amount1, address _two2, address _smart2, uint256 _amount2, bool){
        return (exchanges[_Id].one1, exchanges[_Id].smart1, exchanges[_Id].amount1, exchanges[_Id].two2, exchanges[_Id].smart2, exchanges[_Id].amount2, exchanges[_Id].DealDone);
    }
    
    function cancelExchange (uint exchangeId) external payable returns (bool success) {
         //re-entry defense
        bool locked;
        require(!locked);
        locked = true;
        require(msg.value>=206000000);
        if (msg.sender==exchanges[exchangeId].one1) {
        } else {
        require(msg.sender==exchanges[exchangeId].two2);
        require(msg.sender!=0x1111111111111111111111111111111111111111);    
        }
        
        exchanges[exchangeId].DealDone=true;
        if (exchanges[exchangeId].smart1==address(0)) {
            require(payether(exchanges[exchangeId].one1, exchanges[exchangeId].amount1)==true);
        }
         require(payether(atokenaddress, msg.value)==true);
         emit CancelExchange(exchangeId);
         locked=false;
            return true;
                }
    
    function doExchange (uint exchangeId) external payable returns (bool success) {
         //re-entry defense
        bool _locked;
        require(!_locked);
        _locked = true;
        require(msg.value>=206000000);
        if (exchanges[exchangeId].two2!=0x1111111111111111111111111111111111111111){
        require(msg.sender==exchanges[exchangeId].two2);
        } else {
        exchanges[exchangeId].two2=msg.sender;    
        }
   
        require(exchanges[exchangeId].DealDone==false);
        require(exchanges[exchangeId].amount2>0);
       
        if (exchanges[exchangeId].smart2==address(0)) {
            
            require(msg.value >=206000000 + exchanges[exchangeId].amount2);
            require(payether(atokenaddress, msg.value - exchanges[exchangeId].amount2)==true);
        } else {
            require(payether(atokenaddress, msg.value)==true);
        }
       //party 2 move tokens to party 1
        if (exchanges[exchangeId].smart2==address(0)) {
            require(payether(exchanges[exchangeId].one1,exchanges[exchangeId].amount2)==true);
        } else {
            TCallee c= TCallee(exchanges[exchangeId].smart2);
            bool x=c.transferFrom(exchanges[exchangeId].two2, exchanges[exchangeId].one1, exchanges[exchangeId].amount2);
             require(x==true);
        }
      
      //party 1 moves tokens to party 2
      if (exchanges[exchangeId].smart1==address(0)) {
         require(payether(exchanges[exchangeId].two2, exchanges[exchangeId].amount1)==true);
         
    } else {
         TCallee d= TCallee(exchanges[exchangeId].smart1);
            bool y=d.transferFrom(exchanges[exchangeId].one1, exchanges[exchangeId].two2, exchanges[exchangeId].amount1);
             require(y==true);
      
      
    }
    exchanges[exchangeId].DealDone=true;
    emit DoExchange (exchangeId); 
    _locked=false;
    return true;
}

function payether(address payto, uint256 amountTo) internal returns(bool){
    payto.transfer(amountTo);
    return true;
}
}