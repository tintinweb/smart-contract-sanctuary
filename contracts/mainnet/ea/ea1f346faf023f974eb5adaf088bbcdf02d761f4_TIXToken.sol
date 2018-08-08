pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


/**
 * @title Stalled ERC20 token
 */
contract TIXStalledToken {
  uint256 public totalSupply;
  bool public isFinalized; // switched to true in operational state
  address public ethFundDeposit; // deposit address for ETH for Blocktix

  function balanceOf(address who) constant returns (uint256);
}


/**
 * @title Blocktix Token Generation Event contract
 *
 * @dev Based on code by BAT: https://github.com/brave-intl/basic-attention-token-crowdsale/blob/master/contracts/BAToken.sol
 */
contract TIXToken is StandardToken {
    mapping(address => bool) converted; // Converting from old token contract

    string public constant name = "Blocktix Token";
    string public constant symbol = "TIX";
    uint256 public constant decimals = 18;
    string public version = "1.0.1";

    // crowdsale parameters
    bool public isFinalized;                      // switched to true in operational state
    uint256 public startTime = 1501271999;        // crowdsale start time (in seconds) - this will be set once the conversion is done
    uint256 public constant endTime = 1501271999; // crowdsale end time (in seconds)
    uint256 public constant tokenGenerationCap =  62.5 * (10**6) * 10**decimals; // 62.5m TIX
    uint256 public constant tokenExchangeRate = 1041;

    // addresses
    address public tixGenerationContract; // contract address for TIX v1 Funding
    address public ethFundDeposit;        // deposit address for ETH for Blocktix

    /**
    * @dev modifier to allow actions only when the contract IS finalized
    */
    modifier whenFinalized() {
        if (!isFinalized) throw;
        _;
    }

    /**
    * @dev modifier to allow actions only when the contract IS NOT finalized
    */
    modifier whenNotFinalized() {
        if (isFinalized) throw;
        _;
    }

    // ensures that the current time is between _startTime (inclusive) and _endTime (exclusive)
    modifier between(uint256 _startTime, uint256 _endTime) {
        assert(now >= _startTime && now < _endTime);
        _;
    }

    // verifies that an amount is greater than zero
    modifier validAmount() {
        require(msg.value > 0);
        _;
    }

    // validates an address - currently only checks that it isn&#39;t null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // events
    event CreateTIX(address indexed _to, uint256 _value);

    /**
    * @dev Contructor that assigns all presale tokens and starts the sale
    */
    function TIXToken(address _tixGenerationContract)
    {
        isFinalized = false; // Initialize presale
        tixGenerationContract = _tixGenerationContract;
        ethFundDeposit = TIXStalledToken(tixGenerationContract).ethFundDeposit();
    }


    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    *
    * can only be called during once the the funding period has been finalized
    */
    function transfer(address _to, uint _value) whenFinalized {
        super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amout of tokens to be transfered
    *
    * can only be called during once the the funding period has been finalized
    */
    function transferFrom(address _from, address _to, uint _value) whenFinalized {
        super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Accepts ETH and generates TIX tokens
     *
     * can only be called during the crowdsale
     */
    function generateTokens()
        public
        payable
        whenNotFinalized
        between(startTime, endTime)
        validAmount
    {
        if (totalSupply == tokenGenerationCap)
            throw;

        uint256 tokens = SafeMath.mul(msg.value, tokenExchangeRate); // check that we&#39;re not over totals
        uint256 checkedSupply = SafeMath.add(totalSupply, tokens);
        uint256 diff;

        // return if something goes wrong
        if (tokenGenerationCap < checkedSupply)
        {
            diff = SafeMath.sub(checkedSupply, tokenGenerationCap);
            if (diff > 10**12)
                throw;
            checkedSupply = SafeMath.sub(checkedSupply, diff);
            tokens = SafeMath.sub(tokens, diff);
        }

        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;
        CreateTIX(msg.sender, tokens); // logs token creation
    }

    function hasConverted(address who) constant returns (bool)
    {
      return converted[who];
    }

    function convert(address _owner)
        external
    {
        TIXStalledToken tixStalled = TIXStalledToken(tixGenerationContract);
        if (tixStalled.isFinalized()) throw; // We can&#39;t convert tokens after the contract is finalized
        if (converted[_owner]) throw; // Throw if they have already converted
        uint256 balanceOf = tixStalled.balanceOf(_owner);
        if (balanceOf <= 0) throw; // Throw if they don&#39;t have an existing balance
        converted[_owner] = true;
        totalSupply += balanceOf;
        balances[_owner] += balanceOf;
        Transfer(this, _owner, balanceOf);
    }

    function continueGeneration()
        external
    {
        TIXStalledToken tixStalled = TIXStalledToken(tixGenerationContract);
        // Allow the sale to continue
        if (totalSupply == tixStalled.totalSupply() && tixStalled.isFinalized())
          startTime = now;
        else
          throw;
    }

    /**
    * @dev Ends the funding period and sends the ETH home
    */
    function finalize()
        external
        whenNotFinalized
    {
        if (msg.sender != ethFundDeposit) throw; // locks finalize to the ultimate ETH owner
        if (now <= endTime && totalSupply != tokenGenerationCap) throw;
        // move to operational
        isFinalized = true;
        if(!ethFundDeposit.send(this.balance)) throw;  // send the eth to Blocktix
    }

    // fallback
    function()
        payable
        whenNotFinalized
    {
        generateTokens();
    }
}