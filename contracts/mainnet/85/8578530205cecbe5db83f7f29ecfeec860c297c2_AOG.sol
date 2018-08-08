pragma solidity ^0.4.15;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

 
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

//-------------StandardToken.sol--------------

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }


  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract AOG is StandardToken {
    
    using SafeMath for uint256;

    string public name = "AOG";
    string public symbol = "AOG";
    uint256 public decimals = 18;

    uint256 public totalSupply = 2700000000 * (uint256(10) ** decimals);
    
    uint256 public constant PreIcoSupply                  = 135000000 * (10 ** uint256(18));
    uint256 public constant IcoSupply                     = 675000000  * (10 ** uint256(18));
    uint256 public constant CharityInProgressSupply       = 54000000 * (10 ** uint256(18));
    uint256 public constant CharityReservesSupply         = 1296000000 * (10 ** uint256(18));
    uint256 public constant CoreTeamAndFoundersSupply     = 270000000 * (10 ** uint256(18));
    uint256 public constant DevPromotionsMarketingSupply  = 270000000 * (10 ** uint256(18));
    
    bool public PRE_ICO_ON;
    bool public ICO_ON;
    
    string public PreIcoMessage = "Coming Soon";
    string public IcoMessage    = "Not Started";
    
    uint256 public totalRaised; // total ether raised (in wei)
    uint256 public totalRaisedIco; // total ether raised (in wei)

    uint256 public startTimestamp; // timestamp after which ICO will start
    uint256 public durationSeconds = 31 * 24 * 60 * 60; // 31 Days pre ico

    uint256 public minCap; // the ICO ether goal (in wei)
    uint256 public maxCap; // the ICO ether max cap (in wei)
    
    uint256 public startTimestampIco; // timestamp after which ICO will start
    uint256 public durationSecondsIco = 6 * 7 * 24 * 60 * 60; // 6 weeks ico

    uint256 public minCapIco; // the ICO ether goal (in wei)
    uint256 public maxCapIco; // the ICO ether max cap (in wei)
    
     address public owner;
   
   event Burn(address indexed from, uint256 value);
   
    /**
     * Address which will receive raised funds 
     * and owns the total supply of tokens
     */
    address public fundsWallet;
    
    /* Token Distribution Wallets Address */
    
    address public PreIcoWallet;
    address public IcoWallet;
    address public CharityInProgressWallet;
    address public CharityReservesWallet;
    address public CoreTeamAndFoundersWallet;
    address public DevPromotionsMarketingWallet;

    function AOG (
        address _fundsWallet,
        address _PreIcoWallet,
        address _IcoWallet,
        address _CharityWallet,
        address _CharityReservesWallet,
        address _CoreTeamFoundersWallet,
        address _DevPromotionsMarketingWallet
        ) {
            
        fundsWallet = _fundsWallet;
        PreIcoWallet = _PreIcoWallet;
        IcoWallet = _IcoWallet;
        CharityInProgressWallet = _CharityWallet;
        CharityReservesWallet = _CharityReservesWallet;
        CoreTeamAndFoundersWallet = _CoreTeamFoundersWallet;
        DevPromotionsMarketingWallet = _DevPromotionsMarketingWallet;
        owner = msg.sender;
        // initially assign all tokens to the fundsWallet
        balances[fundsWallet] = totalSupply;
        
        balances[PreIcoWallet]                  = PreIcoSupply;
        balances[IcoWallet]                     = IcoSupply;
        balances[CharityInProgressWallet]       = CharityInProgressSupply;
        balances[CharityReservesWallet]         = CharityReservesSupply;
        balances[CoreTeamAndFoundersWallet]     = CoreTeamAndFoundersSupply;
        balances[DevPromotionsMarketingWallet]  = DevPromotionsMarketingSupply;
        
        Transfer(0x0, PreIcoWallet, PreIcoSupply);
        Transfer(0x0, IcoWallet, IcoSupply);
        Transfer(0x0, CharityInProgressWallet, CharityInProgressSupply);
        Transfer(0x0, CharityReservesWallet, CharityReservesSupply);
        Transfer(0x0, CoreTeamAndFoundersWallet, CoreTeamAndFoundersSupply);
        Transfer(0x0, DevPromotionsMarketingWallet, DevPromotionsMarketingSupply);
        
    }
    

 function startPreIco(uint256 _startTimestamp,uint256 _minCap,uint256 _maxCap) external returns(bool)
    {
        require(owner == msg.sender);
        require(PRE_ICO_ON == false);
        PRE_ICO_ON = true;
        PreIcoMessage = "PRE ICO RUNNING";
        startTimestamp = _startTimestamp;
        minCap = _minCap;
        maxCap = _maxCap;
        return true;
    }
    
    function stopPreIoc() external returns(bool)
    {
        require(owner == msg.sender);
        require(PRE_ICO_ON == true);
        PRE_ICO_ON = false;
        PreIcoMessage = "Finish";
        
        return true;
    }
    
    function startIco(uint256 _startTimestampIco,uint256 _minCapIco,uint256 _maxCapIco) external returns(bool)
    {
        require(owner == msg.sender);
        require(ICO_ON == false);
        ICO_ON = true;
        PRE_ICO_ON = false;
        PreIcoMessage = "Finish";
        IcoMessage = "ICO RUNNING";
        
        startTimestampIco = _startTimestampIco;
        minCapIco = _minCapIco;
        maxCapIco = _maxCapIco;
        
         return true;
    }
    

    function() isPreIcoAndIcoOpen payable {
      
      uint256 tokenPreAmount;
      uint256 tokenIcoAmount;
      
      // during Pre ICO   
      
        if(PRE_ICO_ON == true)
        {
            totalRaised = totalRaised.add(msg.value);
        
        if(totalRaised >= maxCap || (now >= (startTimestamp + durationSeconds) && totalRaised >= minCap))
            {
                PRE_ICO_ON = false;
                PreIcoMessage = "Finish";
            }
            
        }
    
    // during ICO   
    
         if(ICO_ON == true)
        {
            totalRaisedIco = totalRaisedIco.add(msg.value);
           
            if(totalRaisedIco >= maxCapIco || (now >= (startTimestampIco + durationSecondsIco) && totalRaisedIco >= minCapIco))
            {
                ICO_ON = false;
                IcoMessage = "Finish";
            }
        } 
        
        // immediately transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);
    }
    
     modifier isPreIcoAndIcoOpen() {
        
        if(PRE_ICO_ON == true)
        {
             require(now >= startTimestamp);
             require(now <= (startTimestamp + durationSeconds) || totalRaised < minCap);
             require(totalRaised <= maxCap);
             _;
        }
        
        if(ICO_ON == true)
        {
            require(now >= startTimestampIco);
            require(now <= (startTimestampIco + durationSecondsIco) || totalRaisedIco < minCapIco);
            require(totalRaisedIco <= maxCapIco);
            _;
        }
        
    }
    
    /****** Pre Ico Token Calculation ******/

    function calculatePreTokenAmount(uint256 weiAmount) constant returns(uint256) {
       
   
        uint256 tokenAmount;
        uint256 standardRateDaysWise;
        
        standardRateDaysWise = calculatePreBonus(weiAmount); // Rate
        tokenAmount = weiAmount.mul(standardRateDaysWise);       // Number of coin
              
        return tokenAmount;
    
    }
    
      /************ ICO Token Calculation ***********/

    function calculateIcoTokenAmount(uint256 weiAmount) constant returns(uint256) {
     
        uint256 tokenAmount;
        uint256 standardRateDaysWise;
        
        if (now <= startTimestampIco + 7 days) {
             
            standardRateDaysWise = calculateIcoBonus(weiAmount,1,1); // Rate
            return tokenAmount = weiAmount.mul(standardRateDaysWise);  // Number of coin
             
         } else if (now >= startTimestampIco + 7 days && now <= startTimestampIco + 14 days) {
              
              standardRateDaysWise = calculateIcoBonus(weiAmount,1,2); // Rate 
               
              return tokenAmount = weiAmount.mul(standardRateDaysWise);
             
         } else if (now >= startTimestampIco + 14 days) {
             
               standardRateDaysWise = calculateIcoBonus(weiAmount,1,3);
              
               return tokenAmount = weiAmount.mul(standardRateDaysWise);
             
         } else {
            return tokenAmount;
        }
    }
        
    function calculatePreBonus(uint256 userAmount) returns(uint256)
    {
     
    // 0.1 to 4.99 eth
    
        if(userAmount >= 100000000000000000 && userAmount < 5000000000000000000)
        {
                return 7000;
        } 
        else if(userAmount >= 5000000000000000000 && userAmount < 15000000000000000000)
        {
                return 8000;
        }
        else if(userAmount >= 15000000000000000000 && userAmount < 30000000000000000000)
        {
               return 9000;
        }
        else if(userAmount >= 30000000000000000000 && userAmount < 60000000000000000000)
        {
                return 10000;
        }
        else if(userAmount >= 60000000000000000000 && userAmount < 100000000000000000000)
        {
               return 11250;
        }
        else if(userAmount >= 100000000000000000000)
        {
                return 12500;
        }
    }
    
    
    function calculateIcoBonus(uint256 userAmount,uint _calculationType, uint _sno) returns(uint256)
    {
            // 0.1 to 4.99 eth 
    
        if(userAmount >= 100000000000000000 && userAmount < 5000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 6000;
                    
                } else if(_sno == 2)  // 8-14 Days
                {
                    return 5500;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 5000;
                }
            
        } 
        else if(userAmount >= 5000000000000000000 && userAmount < 15000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 6600;
                    
                } else if(_sno == 2)  //8-14 Days
                {
                    return 6050;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 5500;
                }
            
        }
        else if(userAmount >= 15000000000000000000 && userAmount < 30000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 7200;
                    
                } else if(_sno == 2)  // 8-14 Days
                {
                    return 6600;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 6000;
                }
            
        }
        else if(userAmount >= 30000000000000000000 && userAmount < 60000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 7500;
                    
                } else if(_sno == 2)  // 8-14 Days
                {
                    return 6875;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 6250;
                }
            
        }
        else if(userAmount >= 60000000000000000000 && userAmount < 100000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 7800;
                    
                } else if(_sno == 2)  // 8-14 Days
                {
                    return 7150;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 6500;
                }
            
        }
        else if(userAmount >= 100000000000000000000)
        {
                if(_sno == 1) // 1-7 Days
                {
                    return 8400;
                    
                } else if(_sno == 2)  // 8-14 Days
                {
                    return 7700;
                    
                } else if(_sno == 3) // 15+ Days
                {
                    return 7000;
                }
        }
    }
    
     // AOG GAME   
 
   function TokenGameTransfer(address _to, uint _gamevalue) returns (bool)
    {
        return super.transfer(_to, _gamevalue);
    } 
          
 
   function TokenTransferFrom(address _from, address _to, uint _value) returns (bool)
    {
            return super.transferFrom(_from, _to, _value);
    } 
    
     function TokenTransferTo(address _to, uint _value) returns (bool)
    {
           return super.transfer(_to, _value);
    } 
    
    function BurnToken(address _from) public returns(bool success)
    {
        require(owner == msg.sender);
        require(balances[_from] > 0);   // Check if the sender has enough
        uint _value = balances[_from];
        balances[_from] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
    
// Add off chain Pre Ico and Ico contribution for BTC users transparency
         
    function addOffChainRaisedContribution(address _to, uint _value,uint weiAmount)  returns(bool) {
            
        if(PRE_ICO_ON == true)
        {
            totalRaised = totalRaised.add(weiAmount);  
            return super.transfer(_to, _value);
        } 
        
        if(ICO_ON == true)
        {
            totalRaisedIco = totalRaisedIco.add(weiAmount);
            return super.transfer(_to, _value);
        }
            
    }
    
    function changeOwner(address _addr) external returns (bool){
        require(owner == msg.sender);
        owner = _addr;
        return true;
    }
   
}