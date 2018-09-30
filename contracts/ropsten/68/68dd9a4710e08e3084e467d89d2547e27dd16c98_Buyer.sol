pragma solidity >=0.4.24;
contract SafeMath {
  function safeMul(uint a, uint b)  internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b)  internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b)  internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b)  internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b)internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b)internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b)internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function asserts(bool assertion) internal pure {
    if (!assertion) {
      revert();
    }
  }
}
contract Token {
    function transfer(address, uint)public pure returns (bool) {}
    function balanceOf(address)public pure returns (uint) {}
    function transferFrom(address, address, uint256)public pure returns (bool) {}
    function approve(address, uint256)public pure returns (bool) {}
}

contract Buyer is SafeMath {
 
    uint private balance;
    uint      _SalesTax;
    uint      _SellingTokenDecimalPlaces;
    uint      _SellingTokenUnitPrice;
    address   _SellingTokenContractAddress;
    address   _BuyerContract;
    uint      _EscrowBalance;
    Token      TokenContract;
    address    EscrowOwner;
    bool      _isEscrowActive;
    mapping (address => transaction) public PurchaseTransactions;
    struct transaction
    {
      
        uint totalamountsold; 
        uint purchasetime;
        uint amountrecieved;
        uint salestax;
    }
    event EscrowActivated(address indexed _from,uint _value);
    event DepositReceived(address indexed _from,uint _value);
    event DepositRejected(address indexed _from,uint _value);
    event PurchaseRejected(string val);
     event Announce(string val);
    event DepositAccepted(address indexed _from,uint _value);
    event RemainderTransfered(address indexed _from,uint _value);
    event DepositReturned(address indexed _from,uint _value);
    event EscrowCreated(uint st,uint stdp,string sts ,uint stup,address stca);
    event TotalERC20CanBuy(uint amount,uint escrowbalance);
    event TransactionCalculation(uint EthAmount,uint RemainderETH,uint TotalETHBalance);
   
    
    function GetSellingTokenDecimals() public view  returns (uint){return _SellingTokenDecimalPlaces;}   
    function GetSellingTokenContractAddress() public view  returns (address){return _SellingTokenContractAddress;}   
    function GetSellingTokenUnitPrice()public view  returns (uint){ return _SellingTokenUnitPrice;}   
    function GetAquiredAssetBalance()public view returns (uint){ return balance;}   
    function GetEscrowBalance()public view returns (uint){ return _EscrowBalance;}   
    function isEscrowActive()public view returns (bool){return _isEscrowActive;}
    function WhoisOwner()public view returns  (address _address ){return EscrowOwner;}
    function Purchase(address sellersAddress,address sellerscontractaddress)public  payable returns (uint)
    {
        uint incomingethbalance = msg.value;
        
        emit DepositReceived(sellersAddress,incomingethbalance); 
        if(incomingethbalance>= _SellingTokenUnitPrice)
        {
            
             //Get Total number of erc20 token to be sent.
             uint erc20total = safeDiv(incomingethbalance,_SellingTokenUnitPrice);
             //Do we have a remainder of eth needs to be sent back??
           
             
            uint  erc20totalwithdecimal =  safeMul(erc20total,_SellingTokenDecimalPlaces);
            //if the above total is either => then _EscrowBalance
             emit TotalERC20CanBuy(erc20totalwithdecimal,_EscrowBalance);
            if(erc20totalwithdecimal <=_EscrowBalance)
            {
                
                if(TokenContract.transfer(sellersAddress,erc20totalwithdecimal))
                 {
                     emit DepositAccepted(sellersAddress,incomingethbalance);
                    
                     uint ethbalancetoadd =  safeMul(erc20total,_SellingTokenUnitPrice);
                    uint remainingeth =safeSub(incomingethbalance,ethbalancetoadd);
                    _EscrowBalance = safeSub(_EscrowBalance,erc20totalwithdecimal);
                    balance = safeAdd(balance,ethbalancetoadd);
                   emit TransactionCalculation(ethbalancetoadd,remainingeth,balance);
                    
                    PurchaseTransactions[sellersAddress].totalamountsold = erc20totalwithdecimal;
                    PurchaseTransactions[sellersAddress].purchasetime = now;
                    PurchaseTransactions[sellersAddress].amountrecieved = ethbalancetoadd;
                    PurchaseTransactions[sellersAddress].salestax = _SalesTax; 
                  
                    if(remainingeth>0)
                    {
                        sellerscontractaddress.transfer(remainingeth);
                    //    purchaseraddress.transfer(remainingeth);
                        emit RemainderTransfered(sellersAddress,remainingeth);
                        
                        
                    }
                    
                     
                     return erc20totalwithdecimal;
                    
                }
                else{
                     sellerscontractaddress.transfer(incomingethbalance);
                     emit PurchaseRejected("Transfer of Assets Failed-Returned ETH"); 
                     return 0;
                }
                
            }
            else
            {
                uint remainingerc20 = safeDiv(_EscrowBalance,_SellingTokenDecimalPlaces);
                if(remainingerc20>0)
                {
                    uint remainingerc20tosend = safeMul(remainingerc20,_SellingTokenDecimalPlaces);
                    uint currentcost = safeMul(remainingerc20,_SellingTokenUnitPrice);
                    if(TokenContract.transfer(sellersAddress,remainingerc20tosend))
                    {
                         emit DepositAccepted(sellersAddress,incomingethbalance);
                       
                         uint remainingethToSender =safeSub(incomingethbalance,currentcost);
                        _EscrowBalance = safeSub(_EscrowBalance,remainingerc20tosend);
                         balance = safeAdd(balance,currentcost);
                        emit TransactionCalculation(currentcost,remainingethToSender,balance);
                        sellerscontractaddress.transfer(remainingethToSender);
                        PurchaseTransactions[sellersAddress].totalamountsold = remainingerc20tosend;
                        PurchaseTransactions[sellersAddress].purchasetime = now;
                        PurchaseTransactions[sellersAddress].amountrecieved = currentcost;
                        PurchaseTransactions[sellersAddress].salestax = _SalesTax; 
                        emit RemainderTransfered(sellersAddress,remainingethToSender);
                         return remainingerc20tosend;
                    }
                    else{
                        
                        emit PurchaseRejected("ATT Failed");
                        return 0;
                    }
                    
                }
                else
                {
                    //Reject the incoming eth
                    sellerscontractaddress.transfer(incomingethbalance);
                    emit PurchaseRejected("Not enough in Escrow"); 
                    return 0;
                }
            }
        }
        else{
            
                       emit PurchaseRejected("Not sufficient ETH tranmitted");
                       sellerscontractaddress.transfer(incomingethbalance);
                       return 0;
                        
        }
        
        
      
          // msg.sender.transfer(msg.value);
          return 0;  
       
    }
    function  ActivateEscrow(uint erc20qty,uint st,uint stdp,uint stup,address stca) public
    {
         
           require(msg.sender == EscrowOwner);
           require(_isEscrowActive == false);
          
           _SalesTax = st;
           _SellingTokenDecimalPlaces = stdp;
          
           _SellingTokenUnitPrice = stup;
           _SellingTokenContractAddress = stca;
            TokenContract = Token(stca);
       
      
       
           if(TokenContract.transferFrom(EscrowOwner,this,erc20qty))
           {
               _EscrowBalance = TokenContract.balanceOf(this);
               _isEscrowActive=true;
           }
           else
           {
               _isEscrowActive = false;
           }
       emit EscrowActivated(msg.sender, _EscrowBalance);
     }
     
     /*
    uint      _SalesTax; = st
    uint      _SellingTokenDecimalPlaces; stdp
    string    _SellingTokenSymbol; sts
    uint      _SellingTokenUnitPrice; 
    address   _SellingTokenContractAddress;
     
     */
     
 constructor(/*uint st,uint stdp,string sts,uint stup,address stca*/) public
    {
      _isEscrowActive = false;
       _EscrowBalance = 0;
       EscrowOwner = msg.sender;
     
     }   
     
      function cancel() public {
       require(msg.sender == EscrowOwner);
            if(TokenContract.balanceOf(this)>0)
            {
               if( TokenContract.transfer(EscrowOwner,TokenContract.balanceOf(this)))
                {
                    _isEscrowActive = false;
                    selfdestruct(EscrowOwner);
                    
                }
            }
            else{
                
                     _isEscrowActive = false;
                    selfdestruct(EscrowOwner);
            }
            
        
    }
}