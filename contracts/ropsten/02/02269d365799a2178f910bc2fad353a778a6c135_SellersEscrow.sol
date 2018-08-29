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
contract BuyersEscrow {
    function Deposit(address,address)public payable returns(bool) {}
    function WhoisOwner()public pure  returns(address) {}
}
contract SellersEscrow is SafeMath {
 
    uint private balance;
    uint      _SalesTax;
    uint      _SellingTokenDecimalPlaces;
    uint      _SellingTokenUnitPrice;
    address   _SellingTokenContractAddress;
    address   _BuyerContract;
    uint      _EscrowBalance;
    Token      TokenContract;
    BuyersEscrow      BuyersContract;
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
    event DepositAccepted(address indexed _from,uint _value);
    event RemainderTransfered(address indexed _from,uint _value);
    event DepositReturned(address indexed _from,uint _value);
    event EscrowCreated(uint st,uint stdp,string sts ,uint stup,address stca);
    event TotalERC20CanBuy(uint amount,uint escrowbalance);
   
    
    function GetSellingTokenDecimals() public view  returns (uint){return _SellingTokenDecimalPlaces;}   
    function GetSellingTokenContractAddress() public view  returns (address){return _SellingTokenContractAddress;}   
    function GetSellingTokenUnitPrice()public view  returns (uint){ return _SellingTokenUnitPrice;}   
    function GetEscrowBalance()public view returns (uint){ return _EscrowBalance;}   
    function GetEscrowETHBalance()public view returns (uint){ return balance;}   
    function isEscrowActive()public view returns (bool){return _isEscrowActive;}
    function WhoisOwner()public view returns  (address _address ){return EscrowOwner;}
    function Purchase(uint askingprice,address purchaseraddress)public  payable returns (uint)
    {
        emit DepositReceived(purchaseraddress,msg.value); 
        /*
        if(msg.value>= _SellingTokenUnitPrice)
        {
            
             //Get Total number of erc20 token to be sent.
             uint erc20total = safeDiv(msg.value,_SellingTokenUnitPrice);
             //Do we have a remainder of eth needs to be sent back??
           
             
             erc20total=  safeMul(erc20total,_SellingTokenDecimalPlaces);
            //if the above total is either => then _EscrowBalance
             emit TotalERC20CanBuy(erc20total,_EscrowBalance);
            if(erc20total <=_EscrowBalance)
            {
                if(TokenContract.transfer(purchaseraddress,erc20total))
                 {
                    uint ethbalancetoadd =  safeMul(erc20total,_SellingTokenUnitPrice);
                    uint remainingeth =safeSub(msg.value,ethbalancetoadd);
                    _EscrowBalance = safeSub(_EscrowBalance,erc20total);
                    balance = safeAdd(balance,ethbalancetoadd);
                    PurchaseTransactions[purchaseraddress].totalamountsold = erc20total;
                    PurchaseTransactions[purchaseraddress].purchasetime = now;
                    PurchaseTransactions[purchaseraddress].amountrecieved = msg.value;
                    PurchaseTransactions[purchaseraddress].salestax = _SalesTax; 
                    if(remainingeth>0)
                    {
                        msg.sender.transfer(remainingeth);
                        emit RemainderTransfered(this,remainingeth);
                        
                    }
                    emit DepositAccepted(purchaseraddress,msg.value);
                    if(TokenContract.balanceOf(this)>0)
                    {
                       uint remainingtokens = safeDiv(TokenContract.balanceOf(this),_SellingTokenDecimalPlaces)  ;
                       if(remainingtokens==0)// Minimum 1 ERC20 is required
                       {
                         if( TokenContract.transfer(EscrowOwner,TokenContract.balanceOf(this)))
                           {
                             _isEscrowActive = false;
                              selfdestruct(EscrowOwner);
                           }         
                        }
                     }
                     else
                     {
                         _isEscrowActive = false;
                         selfdestruct(EscrowOwner);
                     }
                     return erc20total;
                }
                else{
                     msg.sender.transfer(msg.value);
                     emit PurchaseRejected("Transfer of Assets Failed-Returned ETH"); 
                }
            }
            else
            {
               //Reject the incoming eth
               msg.sender.transfer(msg.value);
               emit PurchaseRejected("Not enough in Escrow"); 
               return 0;
            }
        }
        else{
            
                       emit PurchaseRejected("Not sufficient ETH tranmitted");
                       msg.sender.transfer(msg.value);
                        
        }
        
        
      */
           msg.sender.transfer(msg.value);
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
      /*
       _isEscrowActive = false;
       _SalesTax = st;
       _SellingTokenDecimalPlaces = stdp;
       _SellingTokenSymbol = sts;
       _SellingTokenUnitPrice = stup;
       _SellingTokenContractAddress = stca;
       */
        _isEscrowActive = false;
       _EscrowBalance = 0;
      // TokenContract = Token(stca);
       EscrowOwner = msg.sender;
      // emit   EscrowCreated( st, stdp,sts , stup, stca);
       
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