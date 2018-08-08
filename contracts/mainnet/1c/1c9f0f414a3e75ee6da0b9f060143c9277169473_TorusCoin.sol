pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ForeignToken {
    function balanceOf(address owner) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
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

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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


/**
 * TorusCoin pre-sell contract.
 *
 */
contract TorusCoin is StandardToken {
    using SafeMath for uint256;

    string public name = "Torus";
    string public symbol = "TORUS";
    uint256 public decimals = 18;

    uint256 public startDatetime;
    uint256 public endDatetime;

    // Initial founder address (set in constructor)
    // All deposited ETH will be instantly forwarded to this address.
    address public founder;

    // administrator address
    address public admin;

    uint256 public coinAllocation = 700 * 10**8 * 10**decimals; //70000M tokens supply for pre-sell
    uint256 public founderAllocation = 300 * 10**8 * 10**decimals; //30000M of token supply allocated for the team allocation

    bool public founderAllocated = false; //this will change to true when the founder fund is allocated

    uint256 public saleTokenSupply = 0; //this will keep track of the token supply created during the pre-sell
    uint256 public salesVolume = 0; //this will keep track of the Ether raised during the pre-sell

    bool public halted = false; //the admin address can set this to true to halt the pre-sell due to emergency

    event Buy(address sender, address recipient, uint256 eth, uint256 tokens);
    event AllocateFounderTokens(address sender, address founder, uint256 tokens);
    event AllocateInflatedTokens(address sender, address holder, uint256 tokens);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier duringCrowdSale {
        require(block.timestamp >= startDatetime && block.timestamp <= endDatetime);
        _;
    }

    /**
     *
     * Integer value representing the number of seconds since 1 January 1970 00:00:00 UTC
     */
    function TorusCoin(uint256 startDatetimeInSeconds, address founderWallet) public {

        admin = msg.sender;
        founder = founderWallet;

        startDatetime = startDatetimeInSeconds;
        endDatetime = startDatetime + 16 * 1 days;
    }

    /**
     * allow anyone sends funds to the contract
     */
    function() public payable {
        buy(msg.sender);
    }

    /**
     * Main token buy function.
     * Buy for the sender itself or buy on the behalf of somebody else (third party address).
     */
    function buy(address recipient) payable public duringCrowdSale  {

        require(!halted);
        require(msg.value >= 0.01 ether);

        uint256 tokens = msg.value.mul(35e4);

        require(tokens > 0);

        require(saleTokenSupply.add(tokens)<=coinAllocation );

        balances[recipient] = balances[recipient].add(tokens);

        totalSupply_ = totalSupply_.add(tokens);
        saleTokenSupply = saleTokenSupply.add(tokens);
        salesVolume = salesVolume.add(msg.value);

        if (!founder.call.value(msg.value)()) revert(); //immediately send Ether to founder address

        Buy(msg.sender, recipient, msg.value, tokens);
    }

    /**
     * Set up founder address token balance.
     */
    function allocateFounderTokens() public onlyAdmin {
        require( now > endDatetime );
        require(!founderAllocated);

        balances[founder] = balances[founder].add(founderAllocation);
        totalSupply_ = totalSupply_.add(founderAllocation);
        founderAllocated = true;

        AllocateFounderTokens(msg.sender, founder, founderAllocation);
    }

    /**
     * Emergency Stop crowdsale.
     */
    function halt() public onlyAdmin {
        halted = true;
    }

    function unhalt() public onlyAdmin {
        halted = false;
    }

    /**
     * Change admin address.
     */
    function changeAdmin(address newAdmin) public onlyAdmin  {
        admin = newAdmin;
    }

    /**
     * Change founder address.
     */
    function changeFounder(address newFounder) public onlyAdmin  {
        founder = newFounder;
    }

     /**
      * Inflation
      */
    function inflate(address holder, uint256 tokens) public onlyAdmin {
        require( now > endDatetime );
        require(saleTokenSupply.add(tokens) <= coinAllocation );

        balances[holder] = balances[holder].add(tokens);
        saleTokenSupply = saleTokenSupply.add(tokens);
        totalSupply_ = totalSupply_.add(tokens);

        AllocateInflatedTokens(msg.sender, holder, tokens);

     }

    /**
     * withdraw foreign tokens
     */
    function withdrawForeignTokens(address tokenContract) onlyAdmin public returns (bool) {
        ForeignToken token = ForeignToken(tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(admin, amount);
    }


}