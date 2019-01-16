pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }
}

/**
 * @title Oraclize contract interface (returns uint256 USD)
 */
contract OraclizeInterface {
  function getEthPrice() public view returns (uint256);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) private allowed;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance( address _owner, address _spender ) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom( address _from, address _to, uint256 _value ) public returns (bool) {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval( address _spender, uint256 _addedValue ) public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval( address _spender, uint256 _subtractedValue ) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

  /**
   * @dev Overrides StandardToken._burn in order for burn and burnFrom to emit
   * an additional Burn event.
   */
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit Burn(_who, _value);
  }
}

/**
 * @title EVOAIToken
 */
contract EVOAIToken is BurnableToken {
    string public constant name = "EVOAI";
    string public constant symbol = "EVOT";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 10000000 * 1 ether; // Need to change

    /**
     * @dev Constructor
     */
    constructor() public {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

/**
 * @title Crowdsale
 */
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for EVOAIToken;

    struct State {
        string roundName;
        uint256 round;    // Round index
        uint256 tokens;   // Tokens amaunt for current round
        uint256 rate;     // USD rate of tokens
    }

    State public state;
    EVOAIToken public token;
    OraclizeInterface public oraclize;

    bool public open;
    address public fundsWallet;
    uint256 public weiRaised;
    uint256 public usdRaised;
    uint256 public privateSaleMinContrAmount = 1000;   // Min 1k
    uint256 public privateSaleMaxContrAmount = 10000;  // Max 10k

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event RoundStarts(uint256 timestamp, string round);

    /**
    * Constructor
    */
    constructor(address _tokenColdWallet, address _fundsWallet, address _oraclize) public {
        token = new EVOAIToken();
        oraclize = OraclizeInterface(_oraclize);
        open = false;
        fundsWallet = _fundsWallet;
        state.roundName = "Crowdsale doesnt started yet";
        token.safeTransfer(_tokenColdWallet, 3200000 * 1 ether);
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate wei to usd amount
        uint256 usdAmount = _getEthToUsdPrice(weiAmount);

        if(state.round == 1) {
            _validateUSDAmount(usdAmount);
        }

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(usdAmount);

        assert(tokens <= state.tokens);

        usdAmount = usdAmount.div(100); // Removing cents after whole calculation

        // update state
        state.tokens = state.tokens.sub(tokens);
        weiRaised = weiRaised.add(weiAmount);
        usdRaised = usdRaised.add(usdAmount);

        _processPurchase(_beneficiary, tokens);

        emit TokensPurchased(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
        );

        _forwardFunds();
    }

    function changeFundsWallet(address _newFundsWallet) public onlyOwner {
        require(_newFundsWallet != address(0));
        fundsWallet = _newFundsWallet;
    }

    function burnUnsoldTokens() public onlyOwner {
        require(state.round > 8, "Crowdsale does not finished yet");

        uint256 unsoldTokens = token.balanceOf(this);
        token.burn(unsoldTokens);
    }

    function changeRound() public onlyOwner {
        if(state.round == 0) {
            state = State("Private sale", 1, 300000 * 1 ether, 35);
            emit RoundStarts(now, "Private sale starts.");
        } else if(state.round == 1) {
            state = State("Pre sale", 2, 500000 * 1 ether, 45);
            emit RoundStarts(now, "Pre sale starts.");
        } else if(state.round == 2) {
            state = State("1st round", 3, 1000000 * 1 ether, 55);
            emit RoundStarts(now, "1st round starts.");
        } else if(state.round == 3) {
            state = State("2nd round",4, 1000000 * 1 ether, 65);
            emit RoundStarts(now, "2nd round starts.");
        } else if(state.round == 4) {
            state = State("3th round",5, 1000000 * 1 ether, 75);
            emit RoundStarts(now, "3th round starts.");
        } else if(state.round == 5) {
            state = State("4th round",6, 1000000 * 1 ether, 85);
            emit RoundStarts(now, "4th round starts.");
        } else if(state.round == 6) {
            state = State("5th round",7, 1000000 * 1 ether, 95);
            emit RoundStarts(now, "5th round starts.");
        } else if(state.round == 7) {
            state = State("6th round",8, 1000000 * 1 ether, 105);
            emit RoundStarts(now, "6th round starts.");
        } else if(state.round >= 8) {
            state = State("Crowdsale finished!",9, 0, 0);
            emit RoundStarts(now, "Crowdsale finished!");
        }
    }

    function endCrowdsale() external onlyOwner {
        open = false;
    }

    function startCrowdsale() external onlyOwner {
        open = true;
    }

    // -----------------------------------------
    // Internal interface
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
    * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
    *   super._preValidatePurchase(_beneficiary, _weiAmount);
    *   require(weiRaised.add(_weiAmount) <= cap);
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase( address _beneficiary, uint256 _weiAmount ) internal view {
        require(open);
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    /**
    * @dev Validate usd amount for private sale
    */
    function _validateUSDAmount( uint256 _usdAmount) internal view {
        require(_usdAmount.div(100) > privateSaleMinContrAmount);
        require(_usdAmount.div(100) < privateSaleMaxContrAmount);
    }

    /**
    * @dev Convert ETH to USD and return amount
    * @param _weiAmount ETH amount which will convert to USD
    */
    function _getEthToUsdPrice(uint256 _weiAmount) internal view returns(uint256) {
        return _weiAmount.mul(_getEthUsdPrice()).div(1 ether);
    }

    /**
    * @dev Getting price from oraclize contract
    */
    function _getEthUsdPrice() internal view returns (uint256) {
        return oraclize.getEthPrice();
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens( address _beneficiary, uint256 _tokenAmount ) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase( address _beneficiary, uint256 _tokenAmount ) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Override to extend the way in which usd is converted to tokens.
    * @param _usdAmount Value in usd to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _usdAmount
    */
    function _getTokenAmount(uint256 _usdAmount) internal view returns (uint256) {
        return _usdAmount.div(state.rate).mul(1 ether);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        fundsWallet.transfer(msg.value);
    }
}