//SourceUnit: IERC20.sol

pragma solidity >=0.4.23 <0.6.1;
/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    
    function mint(address to, uint256 value) external returns (bool);
    
    function burn(address from, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: LunarInvest.sol

pragma solidity >=0.4.23 <0.6.1;

import './IERC20.sol';

contract LunarInvest {
   
   event referalEvent(address  _addr, uint32 _refindex, uint64 _amount, uint64 _value, uint64 _revenue);
    event tokenReferalEvent(address  _addr, uint8 _refindex, uint64 _amount, uint64 _value, uint64 _revenue);
   // event splitValueEvent(uint64 splitValue, uint64 _current_split_value);
   // event sendSplitEvent(uint64 _value, uint64 _split_value, uint64 _amount, uint64 _id_check);
    event lunarExchange(address payable _addr, uint _date, uint64 _tokens_amount, uint64 _token_price, uint64 _lunar_price);
    event changePrice(uint _date, uint64 _prev, uint64 _end);
    
   //**************** constructor ******************/
   constructor () public {
        owner = 0x7F797D466495770933daaceA585edBd2e1862729;
        support = 0x34b0211117a5A33A9d70F1BBd3EF5D282C195734;
        comm_support = 0x3fa69715563b519C1da358bAe49D27aD5FdC5eEe;
        splitLimit = 25;
        minimum_value = 99000000;
        referal = 0x34b0211117a5A33A9d70F1BBd3EF5D282C195734;
        lunar_token_address = 0xFDbC1BbbBfd07F181c76C41c89DF5aBED5Bf2f5a;
        lunar_support = 0x7F797D466495770933daaceA585edBd2e1862729;
        last_lunar_price_up = block.timestamp;
        lunar_price = 100;
        last_price_cent = 141000;
        admin = msg.sender;
        
    }
   
   

   //************* variables  ***********************/
   uint64 public splitLimit;
   uint64 public dollar2tron = 14000000;
   uint64 lastCircleID = 1;
   uint64 public UserID;
   uint64 public splitValue;
   uint64 public totalInvestments;
   uint64 public supportValue;
   uint64 public totalReferalValue;
   uint64 public totalReferalValueT;
   uint64 public adminReferals;
   uint64 public lunar_last_value;
   uint64 public lunar_last_value_price;
   uint64 public lunar_price = 100;
   uint64 public total_lunars;
   uint64 public total_lunars_sale;
   uint64 public minimum_value;
   uint64 public last_price_cent;
   uint64 public activeUsersAmount;
   uint64 public splitLimitHeight = 50;
   uint64[8] public referance_list = [12,8,5,4,4,3,2,2];
   uint64[8] public treferance_list = [20,10,10,5,5,5,3,2];
   uint public last_lunar_price_up;


   //************** address variables *****************/
   address payable public support;
   address payable public owner;
   address payable public comm_support;
   address payable public lunar_support;
   address public lunar_token_address;
   address payable public referal;
   address public admin;
   

   mapping (address => DataStruct.investor) public Investors;
   mapping (uint64 => address payable) public InvestorID;

    mapping (address => mapping(uint32 => uint64)) public ReferalAmounts;
    mapping (address => mapping(uint32 => uint64)) public ReferalValues;
    mapping (address => mapping(uint32 => uint64)) public RefTeam;


    mapping (address => mapping(uint32 => uint64)) public TokenReferalAmounts;
    mapping (address => mapping(uint32 => uint64)) public TokenReferalValues;
    mapping (address => mapping(uint32 => uint64)) public TokenRefTeam;


    modifier onlyOwner() {
            require(msg.sender == owner, "only Owner");
            _;
    }
    
    modifier onlyAdmin() {
            require(msg.sender == owner || msg.sender == admin, "only Owner or admin");
            _;
    }
    
    function setAdmin(address _admin) public onlyOwner {
       admin = _admin;
    }
    
    // function setDollar2Tron(uint64 _dollar_tron) public onlyAdmin {
    //     dollar2tron = _dollar_tron;
    // }
    
    function setSupport(address payable _support) public onlyOwner {
        support = _support;
    }
    
    function setLunarSupport(address payable _support) public onlyOwner {
        lunar_support = _support;
    }

    function setLunarAddress(address _lunar_address) public onlyOwner {
        lunar_token_address = _lunar_address;
    }
    
    function setSplitLimit(uint64 _split_limit) public onlyAdmin {
        splitLimit = _split_limit;
    }
    
    function setMinimumValue(uint64 _minimum_value) public onlyOwner {
        minimum_value = _minimum_value;
    }
    
    function setReferalAdmin(address payable _referal) public onlyOwner {
        referal = _referal;
    }
    
    function setSupportComm(address payable _set_support_com) public onlyOwner {
        comm_support = _set_support_com;
    }
    
    function setSplitLimitHeight(uint64 _split_limit_height) public onlyAdmin {
      splitLimitHeight = _split_limit_height;
    }

    function mintLunarTokenByShare() public onlyAdmin {
      
      if ( totalInvestments < 10000000000000) {
        IERC20 _lunar_token = IERC20(lunar_token_address);
        uint64 _for_mint = totalInvestments-lunar_last_value;
        uint64 tokens = getClearDiv(_for_mint, 30);
        if(total_lunars < 500000000000 && tokens != 0) {
            _lunar_token.mint(address(this), getClearDiv(tokens,2));
            _lunar_token.mint(lunar_support, getClearDiv(tokens,2));
            lunar_last_value = totalInvestments;
            total_lunars += getClearDiv(tokens,2);
        }
        
      }
    }
    
    function changePriceCron(uint64 _grow_price) public onlyAdmin {
        uint64 _for_mint_price = totalInvestments-lunar_last_value_price;
        uint64 _range;
        last_price_cent = getClearDiv(_grow_price,30000);
        dollar2tron = last_price_cent*100;
        if (_for_mint_price > _grow_price) {
            _range = getClearDiv(_for_mint_price, _grow_price);
            lunar_last_value_price = totalInvestments;
            lunar_price += _range;
            
            last_lunar_price_up = block.timestamp;
        }
        if ((block.timestamp - last_lunar_price_up) > 1 days) {
            if (lunar_price > 3) {
              last_lunar_price_up = block.timestamp;
              lunar_price -= 3;  
            }
        }
        emit changePrice(block.timestamp, lunar_price, lunar_price);
    }

   

    function burnLunarToken(uint64 _amount_for_burn) public onlyOwner {
      IERC20 _lunar_token = IERC20(lunar_token_address);
      uint64 contract_balance  = uint64(_lunar_token.balanceOf(address(this)));
      if (contract_balance >= _amount_for_burn) {
          _lunar_token.burn(address(this), _amount_for_burn);
        total_lunars -= _amount_for_burn;
      }
    }

    function lunarTokenExchange(address payable _ref_tokens) public payable {
      IERC20 _lunar_exchange = IERC20(lunar_token_address);
      uint64 _token_price_trx = last_price_cent*lunar_price;
      uint64 _tokens_amount = getClearDiv(uint64(msg.value)*1000000,_token_price_trx);
      
      
      editStorage(msg.sender, _ref_tokens,uint64(msg.value), true);
      if ((total_lunars + _tokens_amount) < 500000000000 && _tokens_amount <= total_lunars) {
        _lunar_exchange.transfer(msg.sender, uint256(_tokens_amount));
        total_lunars -= _tokens_amount;
        total_lunars_sale += _tokens_amount;
        emit lunarExchange(msg.sender, block.timestamp ,_tokens_amount, lunar_price, _token_price_trx);
        calculateReferal(msg.sender, uint64(msg.value), true);
      }
     
    }
    
   function signIn(address payable _ref) public {
       address payable _addr = msg.sender;
       require(Investors[_addr].referal == address(0x0),"Already signed");
       if (Investors[_addr].referal == address(0x0)) {
           Investors[_addr].referal = _ref;
           changeReferalAmount(_addr);
           UserID += 1;
           InvestorID[UserID] = _addr;
       }
   }

   function putInvestment(address payable _ref) public payable {
       require((Investors[_ref].referal != address(0x0) || _ref == support) ,"Referance is not present");
       require(msg.value > minimum_value,"Minimal value");
       editStorage(msg.sender, _ref, uint64(msg.value),false);
       calculateReferal(msg.sender, uint64(msg.value), false);
       makeSplit();

   }

   function editStorage(address payable _addr, address payable _ref, uint64 _value, bool _token) internal {
       uint64 _for_support;
       uint64 _split_value;
       uint64 _for_token_support;
       uint64 _for_commercy;
       uint64 _in_dollars;
       
       
       if (Investors[_addr].referal == address(0x0)) {
           Investors[_addr].referal = _ref;
           changeReferalAmount(_addr);
           UserID += 1;
           InvestorID[UserID] = _addr;
       }
       
       (_split_value, _for_support, _for_commercy) = getSupportSplitValues(_value);
       
       _in_dollars = getClearDiv(_value, dollar2tron);

       if (!_token) {
           if (_in_dollars > 100 && _in_dollars < splitLimitHeight) {
               splitLimit = _in_dollars;
           } else if (_in_dollars >= splitLimitHeight) {
               splitLimit = splitLimitHeight;
           } else {
               splitLimit = 25;
           } 
           splitValue += _split_value;
           totalInvestments += _value;
           if (Investors[_addr].active == false) {
             activeUsersAmount += 1;
             Investors[_addr].active = true;
           }
           Investors[_addr].active_ref = true;
           Investors[_addr].investmentValue += _value;
           
       } else {
           _for_token_support = getClearDiv(_value,10);
           sendMoney(lunar_support, _for_token_support*4);
       }
       supportValue += _for_support;
       sendMoney(support, _for_support);
       sendMoney(comm_support, _for_commercy);
   }

   function makeSplit() internal {
       uint64 _split_value;
       
       _split_value = getSplitValue();
       giveSplits(_split_value);
   }

   function giveSplits(uint64 _split_value) internal {
    uint8 i;
    uint64 _id_check;
    uint64 _last;
    uint64 _value;
    uint64 _amount;
    uint64 _total_value;
    uint64 _splitLimit;
    address payable _addr;
         
    _id_check = lastCircleID;
    if(splitLimit > activeUsersAmount) {
        _splitLimit = activeUsersAmount;
    } else {
        _splitLimit = splitLimit;
    }
    
    while (i < _splitLimit) {
        _addr = InvestorID[_id_check];
        if (Investors[_addr].active) {
            _amount = getClearDiv(Investors[_addr].investmentValue, 1000000);
            _value = _split_value * _amount;
            if (Investors[_addr].splitvalue + _value >= Investors[_addr].investmentValue*2) {
                _value = Investors[_addr].investmentValue*2 - Investors[_addr].splitvalue;
                Investors[_addr].active = false;
                activeUsersAmount -= 1;
            }
            Investors[_addr].splitvalue += _value;
            _total_value += _value;
            sendMoney(_addr, _value);
            i += 1;
            
        }

        
        _last = _id_check;
        if (_id_check+1 > UserID) {
            _id_check = 1;
        } else {
            _id_check += 1; 
        }
        
    }
    lastCircleID = _last;
    splitValue -= _total_value;
   }

   function getSplitValue() internal view returns(uint64) {
        uint64 i;
        uint64 _id_check;
        uint64 _amount;
        uint64 _current_split_value;
        uint64 _splitLimit;
         address payable _addr;
         
         _id_check = lastCircleID;
         if(splitLimit > activeUsersAmount) {
            _splitLimit = activeUsersAmount;
         } else {
             _splitLimit = splitLimit;
         }
         while (i < _splitLimit) {
            _addr = InvestorID[_id_check];
           if (Investors[_addr].active) {
              _amount += getClearDiv(Investors[_addr].investmentValue, 1000000);
              i += 1;
           }
            if (_id_check+1 > UserID) {
               _id_check = 1;
            } else {
               _id_check += 1; 
            }
           
         }
         
         //_value = getClearDiv(_value, 1000000);
         _current_split_value = getClearDiv(splitValue, _amount);
         //emit splitValueEvent(splitValue, _current_split_value);
        return _current_split_value;
   }


    
    //******************* REFERALS ************************/
   function calculateReferal(address payable _current_investment_address, 
                            uint64 _value,
                            bool _from_token) public {

        address payable _ref = Investors[_current_investment_address].referal;
        if(_from_token) {
            referalToken(_ref, _value);
        } else {
            referalSplit(_ref, _value);
        }
      
    }  

    function referalSplit(address payable _ref, 
                          uint64 _current_investment_value) internal {
        
        uint64 _current_ref_payment;
        uint64 _persent = getClearDiv(_current_investment_value,100);
        uint64 _total_ref;
        uint64 _support = 0;
      
        for (uint32 i;i < 8;i++) {
            _current_ref_payment = _persent*referance_list[i];
            _total_ref += _current_ref_payment;
            if (Investors[_ref].active_ref) {
                
                if (Investors[_ref].refvalue + Investors[_ref].ref_token_value + _current_ref_payment >= Investors[_ref].investmentValue*2) {
                    _support += _current_ref_payment - (Investors[_ref].investmentValue*2 - Investors[_ref].refvalue-Investors[_ref].ref_token_value);
                    _current_ref_payment = Investors[_ref].investmentValue*2 - (Investors[_ref].refvalue + Investors[_ref].ref_token_value);
                    Investors[_ref].active_ref = false;
                 }
                Investors[_ref].refvalue += _current_ref_payment;
                sendMoney(_ref,_current_ref_payment);
            } else {
                _support += _current_ref_payment;
            }
            emit referalEvent(_ref, i, 0, _current_investment_value, _current_ref_payment);
            
            _ref = Investors[_ref].referal;
        }
        totalReferalValue += _total_ref;
        if(_support > 0) {
            sendMoney(referal, _support);
            adminReferals += _support;
        }
    }

    function referalToken(address payable _ref, 
                          uint64 _current_investment_value) internal {

      uint8 _ref_length = 8;
      uint64 _current_ref_payment;
      uint64 _persent = getClearDiv(_current_investment_value,100);
      uint64 _total_ref;
      uint64 _support;
      
      for (uint8 i = 0;i<_ref_length;i++) {
        if (Investors[_ref].active_ref) {
            if((Investors[_ref].refvalue+Investors[_ref].ref_token_value + _current_ref_payment) >= Investors[_ref].investmentValue*2) {
                _support += _current_ref_payment - (Investors[_ref].investmentValue*2 - Investors[_ref].refvalue- Investors[_ref].ref_token_value);
                _current_ref_payment = Investors[_ref].investmentValue*2 - (Investors[_ref].refvalue + Investors[_ref].ref_token_value);
                Investors[_ref].active_ref = false;
            }
            _current_ref_payment = _persent*treferance_list[i];
            _total_ref += _current_ref_payment;
            Investors[_ref].ref_token_value += _current_ref_payment;
            sendMoney(_ref,_current_ref_payment);
        }
        
        emit tokenReferalEvent(_ref, i, 0, _current_investment_value, _current_ref_payment);
        _ref = Investors[_ref].referal;
        
       }
       totalReferalValueT += _total_ref;
    }

    function changeReferalAmount(address payable _addr) internal  {
        uint256   _ref_length = referance_list.length;
        address payable _current_ref_address = Investors[_addr].referal;
        for(uint8 i=0; i < _ref_length; i++) {
            emit tokenReferalEvent(_current_ref_address, i, 1, 0, 0);
            emit referalEvent(_current_ref_address, i, 1, 0, 0);
            _current_ref_address = Investors[_current_ref_address].referal;
        }
    }


   function getSupportSplitValues(uint64 f) internal  pure returns (uint64 splt, uint64 sup, uint64 comm) {
        assembly {
            let p := div(sub(f, mod(f,100)), 100)
            sup := mul(div(sub(f, mod(f,100)), 100),10)  
            splt := mul(div(sub(f, mod(f,100)), 100),45)  
            comm := mul(div(sub(f, mod(f,100)), 100),5)
        }
    }

    function getClearDiv(uint64 f, uint64 s) internal  pure returns (uint64 res) {
        assembly {
            res:=div(sub(f, mod(f,s)), s)  
        }
    }
    function sendMoney(address payable _addr, uint64 _value) internal {
            if (address(this).balance > _value && _value != 0) {
              _addr.transfer(_value);
            }
    }
    
    


}

library DataStruct {
    
    struct investor {
      uint64 refvalue;
      uint64 ref_token_value;
      uint64 splitvalue;
      uint64 investmentValue;
      bool active;
      bool active_ref;
      address payable referal;

  }
}