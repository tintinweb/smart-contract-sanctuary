pragma solidity ^0.4.24;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
 
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
 
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
 
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
 
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /*
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
   */
}
 
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
*/
 
contract BurnableToken is StandardToken {
 
  function burn(uint256 _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(msg.sender, address(0), _value);
}
 
  event Burn(address indexed burner, uint256 indexed value);
}

contract TMBToken is BurnableToken {
    
  string public constant name = "Teambrella Token";
    
  string public constant symbol = "TMB";
    
  uint32 public constant decimals = 18;
    
  uint256 public constant INITIAL_SUPPLY = 17500000E18;  // 60% is for sale:  10000000E18 max during the sale + 500000E18 max bonus during the pre-sale
  
  uint256 public constant lockPeriodStart = 1536796740;  // end of sale 2018-09-12 23:59
    
  bool public stopped = true;
  address public owner;
  
  mapping(address => uint256) public unlockTimes;

  modifier isRunning() {
    if (stopped) {
        if (msg.sender != owner)
            revert();
      }
    _;
  }

  modifier isNotLocked() {
    // unconditionally unlock everything in 2 years
    
    if (now < lockPeriodStart + 730 days) {
        // add lockedPeriods 
        if (now < unlockTimes[msg.sender])
            revert();
      }
    _;
  }

  constructor() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
  
  function start() public {
    require(msg.sender == owner);
    stopped = false;
  }

  function lockAddress(address _addr, uint256 _period) public {
      require(msg.sender == owner);
      require(stopped); // not possible to lock addresses after start of the contract
      unlockTimes[_addr] = lockPeriodStart + _period;
  }

  function transfer(address _to, uint256 _value) public isRunning isNotLocked returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isRunning isNotLocked returns (bool) {
    return super.approve(_spender, _value);
  }

/*
  function increaseApproval(address _spender, uint256 _addedValue) public isRunning isNotLocked returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public isRunning isNotLocked returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
*/ 
  
}

contract TMBTokenSale {
    
    using SafeMath for uint256;
    
    address public multisigOwner;

    address public multisigFunds;
    address public company;
    address public partners;
    
    // uint256 public constant rate = 1000;

    uint256 public constant soldPercent = 60;
    uint256 public constant partnersPercent = 5;
    uint256 public constant companyPercent = 35;

    uint256 public constant softcap = 2000 * 1 ether;
    uint256 public constant presalecap = 2500 * 1 ether;
    uint256 public constant hardcap = 10000 * 1 ether;
 
    uint256 public constant startPresale = 1532304000; // 2018-07-23 00:00
    uint256 public constant endPresale = 1534118340; // 2018-08-12 23:59

    uint256 public constant startSale = 1534118400; // 2018-08-13 00:00
    uint256 public constant endSale = 1536796740; // 2018-09-12 23:59

    TMBToken public token = new TMBToken();

    bool public stoppedSale = false;
    bool public stoppedPresale = false;

    uint256 public receivedEth = 0;
    uint256 public deliveredEth = 0;
    
    uint256 public issuedTokens;
 
    mapping(address => uint256) public preBalances;
    mapping(address => uint256) public saleBalances;
    
    bool tokensaleFinished = false;
    
    event ReservedPresale(address indexed to, uint256 value);
    event ReservedSale(address indexed to, uint256 value);
    event Issued(address indexed to, uint256 value);
    event Refunded(address indexed to, uint256 value);

    constructor() public {
        
        multisigOwner = 0x101B8fA4F9fA10B9800aCa7b2f4F4841d24DA48E;

        multisigFunds = 0xc65484367BdD9265D487d905A5AAe228e9eE1000;
        company = 0x993C5743Fe73a805d125051f77A32cFAaEF08427;
        partners = 0x66885Bf2915b687E37253F8efB50Cc01f9452802;

    }
 
    modifier isAfterPresale() {
    	require(now > endPresale || (stoppedPresale && now > startPresale));
    	_;
    }

    modifier isAfterSale() {
    	require(now > endSale || (stoppedSale && now > startSale));
    	_;
    }
	
    modifier isAboveSoftCap() {
        require(receivedEth >= softcap);
        _;
    }

    modifier onlyOwner() {
        require(multisigOwner == msg.sender);
        _;
    }
    
    function() external payable {
      reserveFunds();
    }

   function reserveFunds() public payable {
       
       uint256 _value = msg.value;
       address _addr = msg.sender;
       
       require (!isContract(_addr));
       require(_value >= 0.01 * 1 ether);
       
       uint256 _totalFundedEth;
       
       if (!stoppedPresale && now > startPresale && now < endPresale)
       {
           _totalFundedEth = preBalances[_addr].add(_value);
           preBalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           emit ReservedPresale(_addr, _value);
       }
       else if (!stoppedSale && now > startSale && now < endSale)
       {
           _totalFundedEth = saleBalances[_addr].add(_value);
           saleBalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           emit ReservedSale(_addr, _value);
       }
       else
       {
           revert();
       }
    }

    function stopPresale() public onlyOwner {
        stoppedPresale = true;
    }
    
    function stopSale() public onlyOwner {
        stoppedSale = true;
    }

    function isContract(address _addr) constant internal returns(bool) {
	    uint256 size;
	    if (_addr == 0) return false;
	    assembly {
		    size := extcodesize(_addr)
	    }
	    return size > 0;
    }

    function issueTokens(address _addr, uint256 _valTokens) internal {

        token.transfer(_addr, _valTokens);
        issuedTokens = issuedTokens.add(_valTokens);
        emit Issued(_addr, _valTokens);
    }

    function deliverPresale(address _addr, uint256 _valEth) internal {

        uint256 _issuedTokens = _valEth * 1200; // _valEth * rate + 20% presale bonus, rate == 1000
        uint256 _newDeliveredEth = deliveredEth.add(_valEth);
        require(_newDeliveredEth < presalecap);
        multisigFunds.transfer(_valEth);
        deliveredEth = _newDeliveredEth;

        issueTokens(_addr, _issuedTokens);
    }
    
    function deliverSale(address _addr, uint256 _valEth) internal {

        uint256 _issuedTokens = _valEth * 1000; // _valEth * rate, rate == 1000
        uint256 _newDeliveredEth = deliveredEth.add(_valEth);
        require(_newDeliveredEth < hardcap);
        multisigFunds.transfer(_valEth);
        deliveredEth = _newDeliveredEth;

        issueTokens(_addr, _issuedTokens);
    }
    
    // everyone is able to withdraw his own money if no softcap
    function refund() public isAfterSale {
        require(receivedEth < softcap);
        uint256 _value = preBalances[msg.sender]; 
        _value += saleBalances[msg.sender]; 
        if (_value > 0)
        {
            preBalances[msg.sender] = 0;
            saleBalances[msg.sender] = 0; 
            msg.sender.transfer(_value);
            emit Refunded(msg.sender, _value);
        }
    }

    function issueTokensPresale(address _addr, uint256 _val) public onlyOwner isAfterPresale isAboveSoftCap {

        require(_val >= 0);
        require(!tokensaleFinished);
        
        uint256 _fundedEth = preBalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint256 _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                emit Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                deliverPresale(_addr, _fundedEth);
            }
            preBalances[_addr] = 0;
        }
    }

    function issueTokensSale(address _addr, uint256 _val) public onlyOwner isAfterSale isAboveSoftCap {

        require(_val >= 0);
        require(!tokensaleFinished);
        
        uint256 _fundedEth = saleBalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint256 _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                emit Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                deliverSale(_addr, _fundedEth);
            }
            saleBalances[_addr] = 0;
        }
    }

    function issueTokensPresale(address[] _addrs) public onlyOwner isAfterPresale isAboveSoftCap {

        require(!tokensaleFinished);

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = preBalances[_addr];
            if (_fundedEth > 0)
            {
                deliverPresale(_addr, _fundedEth);
                preBalances[_addr] = 0;
            }            
        }
    }

    function issueTokensSale(address[] _addrs) public onlyOwner isAfterSale isAboveSoftCap {

        require(!tokensaleFinished);

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = saleBalances[_addr];
            if (_fundedEth > 0)
            {
                deliverSale(_addr, _fundedEth);
                saleBalances[_addr] = 0;
            }            
        }
    }
    
    function refundTokensPresale(address[] _addrs) public onlyOwner isAfterPresale {

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = preBalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                emit Refunded(_addr, _fundedEth);
                preBalances[_addr] = 0;
            }
        }
    }

    function refundTokensSale(address[] _addrs) public onlyOwner isAfterSale {

        for (uint256 i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = saleBalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                emit Refunded(_addr, _fundedEth);
                saleBalances[_addr] = 0;
            }
        }
    }

    function lockAddress(address _addr, uint256 _period) public onlyOwner {
        token.lockAddress(_addr, _period);
    }

    function finalize() public onlyOwner isAfterSale isAboveSoftCap {

        require(!tokensaleFinished);

        tokensaleFinished = true;
        
        uint256 _soldTokens = issuedTokens;
        
        // transfer tokens to partners
        uint256 _partnersTokens = _soldTokens * partnersPercent / soldPercent;
        issueTokens(partners, _partnersTokens);

        // transfer tokens to company
        uint256 _companyTokens = _soldTokens * companyPercent / soldPercent;
        issueTokens(company, _companyTokens);
        token.lockAddress(company, 730 days);

        // burn everything but issued (sold + partners + company)
        uint256 _tokensToBurn = token.balanceOf(this); //token.INITIAL_SUPPLY().sub(issuedTokens);
        token.burn(_tokensToBurn);
        token.start();
    }
}