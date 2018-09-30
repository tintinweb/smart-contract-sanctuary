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
contract Buyer {
    function Purchase(address)public  payable  returns (uint) {}
    function GetSellingTokenDecimals() public pure  returns (uint){}   
    function GetSellingTokenContractAddress() public pure  returns (address){}   
    function GetSellingTokenUnitPrice()public pure  returns (uint){}   
    function isEscrowActive()public pure returns (bool){}
}
contract Seller is SafeMath {
    
    address private notifierAddress;
    address private askingtokenaddress;
    uint    private askingtokenaquired;
    uint    private askingtokenunitprice;
    uint    private askingtokenmultiplier;
    uint    private askingtokenbought;
    Token   private TokenContract;
    bool private _isEscrowActive;
    uint private balance;
    string private escrowtokensymbol;
    address private EscrowOwner;
    uint private start;
    
     function GetAskingTokenDecimal() public view  returns (uint){return askingtokenmultiplier;}  
     function GetAskingUnitPrice() public view  returns (uint){return askingtokenunitprice;}  
     function GetAskingTokenBought() public view  returns (uint){return askingtokenbought;}  
     function GetBuyingTokenAddress() public view  returns (address){return askingtokenaddress;}  
     function IsEscrowActive() public view  returns (bool){return _isEscrowActive;}  
     function GetAquiredAssetBalance()public view returns (uint){ return askingtokenaquired;}   
     function GetEscrowBalance() public view  returns (uint){return balance;}  
     function GetEscrowOwner() public view  returns (address){return EscrowOwner;} 
     function GetEscrowCreationDate() public view  returns (uint){return start;} 
     function GetEscrowNotifierAddress() public view  returns (address){return notifierAddress;} 
      
     event EscrowFailed();
     event DepositReceived(address indexed _from,address indexed _contractid,uint _value);
     event PurchaseRejected(address indexed _from,address indexed _contractid,uint _value);
     event PurchaseAccepted(address indexed _from,address indexed _contractid,uint _value);
     event EscrowActivated(uint _escrowqty,address _buyingtokencontract,uint buyingtokenunitprice ,address _owner);
     event Announce(string _announcement);
   
   
   
    constructor  (address ata ,uint atup,uint atm,address na)public payable{
        // this is the constructor function that runs ONCE upon initialization
        if(msg.value>0)
        {
            _isEscrowActive = true;
            EscrowOwner = msg.sender;
            notifierAddress = na;
            balance = msg.value;
            start = now; //now is an alias for block.timestamp, not really "now"st
            TokenContract = Token(ata);
            askingtokenaddress = ata;
            askingtokenunitprice = atup;//
            askingtokenmultiplier = atm;
            emit EscrowActivated(balance,ata,atup,msg.sender);
        }
        else
        {
                
            _isEscrowActive=false;
            emit EscrowFailed();
        }
        
    }
    
   
    function NotifyMe(address buyeraddress) public {
        
        require(msg.sender==EscrowOwner||msg.sender==notifierAddress);
         Buyer buyer = Buyer(buyeraddress);
       // require(SellerContract.GetSellingTokenContractAddress()==askingtokenaddress);
        uint buyerUnitprice = buyer.GetSellingTokenUnitPrice();
        if(buyerUnitprice>=askingtokenunitprice)
        {
            address ata = buyer.GetSellingTokenContractAddress();
            if(ata==askingtokenaddress)
            {
                
                uint buyerescrowbalance = TokenContract.balanceOf(buyeraddress);
                if(buyerescrowbalance>0)
                {
                   uint erc20tokentotal = safeDiv(balance ,buyerUnitprice);// This will return in whole number
                   erc20tokentotal = safeMul(erc20tokentotal,askingtokenmultiplier);
                 
                   uint totalbought = buyer.Purchase.value(balance)(EscrowOwner);
                   if(totalbought>0)
                   {
                           askingtokenaquired = safeAdd(askingtokenaquired,totalbought);
                           emit PurchaseAccepted(this,buyeraddress,totalbought);
                   }
                   else {
                       
                         emit PurchaseRejected(this,buyeraddress,totalbought);
                   }
                }
                else{
                    emit Announce("Rejected.ZB");//Zero Balance
                }
            }
            else
            {
                 emit Announce("Rejected.ATA mismatch");
                
            }
        }
        else{
            
            emit Announce("Rejected.Ask>bid");
        }
        
    }
    function cancel() public {
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