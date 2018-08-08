pragma solidity ^0.4.20;
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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
   */
}
 
/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
*/
 
contract BurnableToken is StandardToken {
 
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
 
  event Burn(address indexed burner, uint indexed value);
}

contract TBL4Token is BurnableToken {
    
  string public constant name = "TBL4 Test Token";
    
  string public constant symbol = "TBL4";
    
  uint32 public constant decimals = 15;
    
  uint256 public constant INITIAL_SUPPLY = 17.5 * 1 ether; // should be in prod: 17500 * 1 ether: 
  // example: 10000 eth hardcap is 10M tokens + possible 20% of 2500 + 40% devs and partners = 17.5M tokens, value is 17500 * 1 ether tokens (decimals is 15).
    
  bool public stopped = false; // todo: change to true
  address public owner;
    
  modifier isRunning() {
    if (stopped) {
        if (msg.sender != owner)
            revert();
      }
    _;
  }

  function TBL4Token() public {
    owner = msg.sender;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
  
  function start() public {
    require(msg.sender == owner);
    stopped = false;
  }

  function transfer(address _to, uint256 _value) public isRunning returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public isRunning returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isRunning returns (bool) {
    return super.approve(_spender, _value);
  }

/*
  function increaseApproval(address _spender, uint _addedValue) public isRunning returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public isRunning returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
*/ 
  
}

contract TBL4TokenSale {
    
    using SafeMath for uint;
    
    address public multisigOwner;

    address public multisigFunds;
    address public devs;
    address public partners;
    //address public bonuses;
    
    uint public constant soldPercent = 60;
    uint public constant partnersPercent = 5;
    //uint public constant bonusesPercent = 3;
    uint public constant devsPercent = 35;

    uint public constant softcap = 2 * 1 ether; // should be: 1000
    uint public constant hardcap = 10 * 1 ether; // should be: 10000
 
    uint public constant startPreSale = 1529020800; // 2018-06-15 00:00, should be 1532304000 (2018-07-23 00:00)
    uint public constant endPreSale = 1529971140; // 2018-06-25 23:59, should be 1533081540 (2018-07-31 23:59)

    uint public constant startSale = 1534118400; // 2018-08-13 00:00
    uint public constant endSale = 1536796740; // 2018-09-12 23:59

    TBL4Token public token = new TBL4Token();

    bool stopped = false;

    uint256 public receivedEth = 0;
    uint256 public deliveredEth = 0;
    
    uint256 public issuedTokens;
 
    mapping(address => uint) public prebalances;
    mapping(address => uint) public salebalances;
    
    enum State{
       Running,
       Finished,
       DevsTokensIssued
    }
    
    State finalizeState = State.Running;
    
    event ReservedPresale(address indexed to, uint256 value);
    event ReservedSale(address indexed to, uint256 value);
    event Issued(address indexed to, uint256 value);
    event Refunded(address indexed to, uint256 value);

    function TBL4TokenSale() public {
        
        multisigOwner = msg.sender; // todo - change this to the real address

        multisigFunds = 0x893aafe4736d92f8f30b10E25A83F2B10878cDB3;
        devs = 0xa3Fcb8ef8E4b62240eefa0Ce712E16ADE0EC984C;
        partners = 0xa3Fcb8ef8E4b62240eefa0Ce712E16ADE0EC984C;
     //   bonuses = 0x88B7B046E44b79a46ab38800832E5E9aAac4CE57;
        
     //   rate = 1000;
    }
 
    modifier isAfterPresale() {
    	require(now > endPreSale || (stopped && now > startPreSale));
    	_;
    }

    modifier isAfterSale() {
    	require(now > endSale);
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
    
    // todo: remove this temp function 
    function getbalance() external view returns(uint) {
      return this.balance;
    }

    function() external payable {
      reserveFunds();
    }

   function reserveFunds() public payable {
       
       uint256 _value = msg.value;
       address _addr = msg.sender;
       
       require (!isContract(_addr));
       require(_value >= 0.1 * 1 ether); // todo: change to real presale bottom limit
       
       uint256 _totalFundedEth;
       
       if (!stopped && now > startPreSale && now < endPreSale)
       {
           _totalFundedEth = prebalances[_addr].add(_value);
           require(_totalFundedEth < 5 * 1 ether); // todo: change to real presale limit
           prebalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           ReservedPresale(_addr, _value);
       }
       else if (now > startSale && now < endSale)
       {
           _totalFundedEth = salebalances[_addr].add(_value);
           require(_totalFundedEth < 100 * 1 ether); // todo: change to real sale limit, do we need to add presale?
           salebalances[_addr] = _totalFundedEth;
           receivedEth = receivedEth.add(_value);
           ReservedSale(_addr, _value);
       }
       else
       {
           revert();
       }
    }

    function stopPresale() public {
        require(msg.sender == multisigOwner);
        stopped = true;
    }
    
    function isContract(address _addr) constant internal returns(bool) {
	    uint size;
	    if (_addr == 0) return false;
	    assembly {
		    size := extcodesize(_addr)
	    }
	    return size > 0;
    }

    function issueTokens(address _addr, uint256 _valTokens) internal {

        token.transfer(_addr, _valTokens);
        issuedTokens = issuedTokens.add(_valTokens);
        Issued(_addr, _valTokens);
    }

    function deliver(address _addr, uint256 _valEth, uint256 _valTokens) internal {

        uint _newDeliveredEth = deliveredEth.add(_valEth);
        require(_newDeliveredEth < hardcap);
        multisigFunds.transfer(_valEth);
        deliveredEth = _newDeliveredEth;

        issueTokens(_addr, _valTokens);
    }
    
    // everyone is able to withdraw his own money
    function refund() public {
        require(receivedEth < softcap && now > endSale);
        uint256 _value = prebalances[msg.sender]; 
        _value += salebalances[msg.sender]; 
        if (_value > 0)
        {
            prebalances[msg.sender] = 0;
            salebalances[msg.sender] = 0; 
            msg.sender.transfer(_value);
            Refunded(msg.sender, _value);
        }
    }

    function issueTokensPresale(address _addr, uint _val) public /*onlyOwner isAfterPresale */ isAboveSoftCap {

        /*require(now > endPreSale);*/
        
        require(_val >= 0);
        
        uint256 _fundedEth = prebalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                //uint256 _issuedTokens = _fundedEth.mul(rate).mul(10000000000000000).div(1 ether); rate is 1000, 1 token is 10^15, 1 ether is 10^18
                uint256 _issuedTokens = _fundedEth * 120 / 100; // 20% presale bonus
                deliver(_addr, _fundedEth, _issuedTokens);
            }
            prebalances[_addr] = 0;
        }
    }

    function issueTokensSale(address _addr, uint _val) public /*onlyOwner isAfterSale */ isAboveSoftCap {

        /*require(now > endSale);*/
        
        require(_val >= 0);
        
        uint _fundedEth = salebalances[_addr];
        if (_fundedEth > 0)
        {
            if (_fundedEth > _val)
            {
                // rollback the rest of funds
                uint256 _refunded = _fundedEth.sub(_val);
                _addr.transfer(_refunded);
                Refunded(_addr, _refunded);
                _fundedEth = _val;
            }

            if (_fundedEth > 0)
            {
                //uint256 _issuedTokens = _fundedEth.mul(rate).mul(10000000000000000).div(1 ether); rate is 1000, 1 token is 10^15, 1 ether is 10^18
                uint256 _issuedTokens = _fundedEth;
                deliver(_addr, _fundedEth, _issuedTokens);
            }
            salebalances[_addr] = 0;
        }
    }

    function issueTokensPresale(address[] _addrs) public /*onlyOwner isAfterPresale */ isAboveSoftCap {

        /*require(now > endPreSale);*/
        for (uint i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = prebalances[_addr];
           //uint256 _issuedTokens = _fundedEth.mul(rate).mul(10000000000000000).div(1 ether); rate is 1000, 1 token is 10^15, 1 ether is 10^18
            uint256 _issuedTokens = _fundedEth * 120 / 100; // 20% presale bonus
            if (_fundedEth > 0)
            {
                deliver(_addr, _fundedEth, _issuedTokens);
                prebalances[_addr] = 0;
            }            
        }
    }

    function issueTokensSale(address[] _addrs) public /*onlyOwner isAfterSale */ isAboveSoftCap {

        /*require(now > endSale);*/
        for (uint i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = salebalances[_addr];
            //uint256 _issuedTokens = _fundedEth.mul(rate).mul(10000000000000000).div(1 ether); rate is 1000, 1 token is 10^15, 1 ether is 10^18
            uint256 _issuedTokens = _fundedEth;
            if (_fundedEth > 0)
            {
                deliver(_addr, _fundedEth, _issuedTokens);
                salebalances[_addr] = 0;
            }            
        }
    }
    
    function refundTokensPresale(address[] _addrs) public /*onlyOwner*/ {

        /*require(now > endPreSale);*/
        for (uint i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = prebalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                Refunded(_addr, _fundedEth);
                prebalances[_addr] = 0;
            }
        }
    }

    function refundTokensSale(address[] _addrs) public /*onlyOwner*/ {

        /*require(now > endPreSale);*/
        for (uint i; i < _addrs.length; i++)
        {
            address _addr = _addrs[i];
            uint256 _fundedEth = salebalances[_addr];
            if (_fundedEth > 0)
            {
                _addr.transfer(_fundedEth);
                Refunded(_addr, _fundedEth);
                salebalances[_addr] = 0;
            }
        }
    }

    /* Only possible to call it in 2 years after the token sale ends */
    function finalize() public /*onlyOwner isAfterSale*/ isAboveSoftCap {

        require(finalizeState == State.Running); // endSale

        finalizeState = State.Finished;
        
        uint256 _soldTokens = issuedTokens;
        
        // transfer tokens to partners
        uint256 _partnersTokens = _soldTokens * partnersPercent / soldPercent;
        issueTokens(partners, _partnersTokens);

        //uint256 _bonusesTokens = _soldTokens * bonusesPercent / soldPercent;
        //issueTokens(bonuses, _bonusesTokens);

        // burn everything but issued (sold + partners) and devs&#39; reserve
        uint256 _tokensToBurn = token.INITIAL_SUPPLY().sub(issuedTokens).sub(_soldTokens * devsPercent / soldPercent);
        token.burn(_tokensToBurn);
        token.start();
    }

    function issueDevsTokens() public /*onlyOwner*/ isAboveSoftCap {

        require(finalizeState == State.Finished && now > endSale + 2 years); // for testing startPreSale + 10 minutes
        
        // the rest of tokens is exactly the devs amount
        uint _devsTokens = token.balanceOf(this);
        issueTokens(devs, _devsTokens);
        
        finalizeState == State.DevsTokensIssued;
    }
}