pragma solidity 0.4.24;

// File: node_modules/zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: node_modules/zeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
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

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: node_modules/zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: node_modules/zeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: node_modules/zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting. 
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

// File: contracts/PostKYCCrowdsale.sol

/// @title PostKYCCrowdsale
/// @author Sicos et al.
contract PostKYCCrowdsale is Crowdsale, Ownable {

    struct Investment {
        bool isVerified;         // wether or not the investor passed the KYC process
        uint totalWeiInvested;   // total invested wei regardless of verification state
        // amount of token an unverified investor bought. should be zero for verified investors
        uint pendingTokenAmount;
    }

    // total amount of wei held by unverified investors should never be larger than this.balance
    uint public pendingWeiAmount = 0;

    // maps investor addresses to investment information
    mapping(address => Investment) public investments;

    /// @dev Log entry on investor verified
    /// @param investor the investor&#39;s Ethereum address
    event InvestorVerified(address investor);

    /// @dev Log entry on tokens delivered
    /// @param investor the investor&#39;s Ethereum address
    /// @param amount token amount delivered
    event TokensDelivered(address investor, uint amount);

    /// @dev Log entry on investment withdrawn
    /// @param investor the investor&#39;s Ethereum address
    /// @param value the wei amount withdrawn
    event InvestmentWithdrawn(address investor, uint value);

    /// @dev Verify investors
    /// @param _investors list of investors&#39; Ethereum addresses
    function verifyInvestors(address[] _investors) public onlyOwner {
        for (uint i = 0; i < _investors.length; ++i) {
            address investor = _investors[i];
            Investment storage investment = investments[investor];

            if (!investment.isVerified) {
                investment.isVerified = true;

                emit InvestorVerified(investor);

                uint pendingTokenAmount = investment.pendingTokenAmount;
                // now we issue tokens to the verfied investor
                if (pendingTokenAmount > 0) {
                    investment.pendingTokenAmount = 0;

                    _forwardFunds(investment.totalWeiInvested);
                    _deliverTokens(investor, pendingTokenAmount);

                    emit TokensDelivered(investor, pendingTokenAmount);
                }
            }
        }
    }

    /// @dev Withdraw investment
    /// @dev Investors that are not verified can withdraw their funds
    function withdrawInvestment() public {
        Investment storage investment = investments[msg.sender];

        require(!investment.isVerified);

        uint totalWeiInvested = investment.totalWeiInvested;

        require(totalWeiInvested > 0);

        investment.totalWeiInvested = 0;
        investment.pendingTokenAmount = 0;

        pendingWeiAmount = pendingWeiAmount.sub(totalWeiInvested);

        msg.sender.transfer(totalWeiInvested);

        emit InvestmentWithdrawn(msg.sender, totalWeiInvested);

        assert(pendingWeiAmount <= address(this).balance);
    }

    /// @dev Prevalidate purchase
    /// @param _beneficiary the investor&#39;s Ethereum address
    /// @param _weiAmount the wei amount invested
    function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal {
        // We only want the msg.sender to buy tokens
        require(_beneficiary == msg.sender);

        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /// @dev Process purchase
    /// @param _tokenAmount the token amount purchased
    function _processPurchase(address, uint _tokenAmount) internal {
        Investment storage investment = investments[msg.sender];
        investment.totalWeiInvested = investment.totalWeiInvested.add(msg.value);

        if (investment.isVerified) {
            // If the investor&#39;s KYC is already verified we issue the tokens imediatly
            _deliverTokens(msg.sender, _tokenAmount);
            emit TokensDelivered(msg.sender, _tokenAmount);
        } else {
            // If the investor&#39;s KYC is not verified we store the pending token amount
            investment.pendingTokenAmount = investment.pendingTokenAmount.add(_tokenAmount);
            pendingWeiAmount = pendingWeiAmount.add(msg.value);
        }
    }

    /// @dev Forward funds
    function _forwardFunds() internal {
        // Ensure the investor was verified, i.e. his purchased tokens were delivered,
        // before forwarding funds.
        if (investments[msg.sender].isVerified) {
            super._forwardFunds();
        }
    }

    /// @dev Forward funds
    /// @param _weiAmount the amount to be transfered
    function _forwardFunds(uint _weiAmount) internal {
        pendingWeiAmount = pendingWeiAmount.sub(_weiAmount);
        wallet.transfer(_weiAmount);
    }

    /// @dev Postvalidate purchase
    /// @param _weiAmount the amount invested
    function _postValidatePurchase(address, uint _weiAmount) internal {
        super._postValidatePurchase(msg.sender, _weiAmount);
        // checking invariant
        assert(pendingWeiAmount <= address(this).balance);
    }

}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: contracts/VreoToken.sol

/// @title VreoToken
/// @author Sicos et al.
contract VreoToken is CappedToken, PausableToken, BurnableToken {

    uint public constant TOTAL_TOKEN_CAP = 700000000e18;  // = 700.000.000 e18

    string public name = "MERO Token";
    string public symbol = "MERO";
    uint8 public decimals = 18;

    /// @dev Constructor
    constructor() public CappedToken(TOTAL_TOKEN_CAP) {
        pause();
    }

}

// File: contracts/VreoTokenSale.sol

/// @title VreoTokenSale
/// @author Sicos et al.
contract VreoTokenSale is PostKYCCrowdsale, FinalizableCrowdsale, MintedCrowdsale {

    // Maxmimum number of tokens sold in Presale+Iconiq+Vreo sales
    uint public constant TOTAL_TOKEN_CAP_OF_SALE = 450000000e18;  // = 450.000.000 e18

    // Extra tokens minted upon finalization
    uint public constant TOKEN_SHARE_OF_TEAM     =  85000000e18;  // =  85.000.000 e18
    uint public constant TOKEN_SHARE_OF_ADVISORS =  58000000e18;  // =  58.000.000 e18
    uint public constant TOKEN_SHARE_OF_LEGALS   =  57000000e18;  // =  57.000.000 e18
    uint public constant TOKEN_SHARE_OF_BOUNTY   =  50000000e18;  // =  50.000.000 e18

    // Extra token percentages
    uint public constant BONUS_PCT_IN_ICONIQ_SALE       = 30;  // TBD
    uint public constant BONUS_PCT_IN_VREO_SALE_PHASE_1 = 20;
    uint public constant BONUS_PCT_IN_VREO_SALE_PHASE_2 = 10;

    // Date/time constants
    uint public constant ICONIQ_SALE_OPENING_TIME   = 1531123200;  // 2018-07-09 10:00:00 CEST
    uint public constant ICONIQ_SALE_CLOSING_TIME   = 1532376000;  // 2018-07-23 22:00:00 CEST
    uint public constant VREO_SALE_OPENING_TIME     = 1533369600;  // 2018-08-04 10:00:00 CEST
    uint public constant VREO_SALE_PHASE_1_END_TIME = 1533672000;  // 2018-08-07 22:00:00 CEST
    uint public constant VREO_SALE_PHASE_2_END_TIME = 1534276800;  // 2018-08-14 22:00:00 CEST
    uint public constant VREO_SALE_CLOSING_TIME     = 1535832000;  // 2018-09-01 22:00:00 CEST
    uint public constant KYC_VERIFICATION_END_TIME  = 1537041600;  // 2018-09-15 22:00:00 CEST

    // Amount of ICONIQ token investors need per Wei invested in ICONIQ PreSale.
    uint public constant ICONIQ_TOKENS_NEEDED_PER_INVESTED_WEI = 450;

    // ICONIQ Token
    ERC20Basic public iconiqToken;

    // addresses token shares are minted to in finalization
    address public teamAddress;
    address public advisorsAddress;
    address public legalsAddress;
    address public bountyAddress;

    // Amount of token available for purchase
    uint public remainingTokensForSale;

    /// @dev Log entry on rate changed
    /// @param newRate the new rate
    event RateChanged(uint newRate);

    /// @dev Constructor
    /// @param _token A VreoToken
    /// @param _rate the initial rate.
    /// @param _iconiqToken An IconiqInterface
    /// @param _teamAddress Ethereum address of Team
    /// @param _advisorsAddress Ethereum address of Advisors
    /// @param _legalsAddress Ethereum address of Legals
    /// @param _bountyAddress A VreoTokenBounty
    /// @param _wallet MultiSig wallet address the ETH is forwarded to.
    constructor(
        VreoToken _token,
        uint _rate,
        ERC20Basic _iconiqToken,
        address _teamAddress,
        address _advisorsAddress,
        address _legalsAddress,
        address _bountyAddress,
        address _wallet
    )
        public
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(ICONIQ_SALE_OPENING_TIME, VREO_SALE_CLOSING_TIME)
    {
        // Token sanity check
        require(_token.cap() >= TOTAL_TOKEN_CAP_OF_SALE
                                + TOKEN_SHARE_OF_TEAM
                                + TOKEN_SHARE_OF_ADVISORS
                                + TOKEN_SHARE_OF_LEGALS
                                + TOKEN_SHARE_OF_BOUNTY);

        // Sanity check of addresses
        require(address(_iconiqToken) != address(0)
                && _teamAddress != address(0)
                && _advisorsAddress != address(0)
                && _legalsAddress != address(0)
                && _bountyAddress != address(0));

        iconiqToken = _iconiqToken;
        teamAddress = _teamAddress;
        advisorsAddress = _advisorsAddress;
        legalsAddress = _legalsAddress;
        bountyAddress = _bountyAddress;

        remainingTokensForSale = TOTAL_TOKEN_CAP_OF_SALE;
    }

    /// @dev Distribute presale
    /// @param _investors  list of investor addresses
    /// @param _amounts  list of token amounts purchased by investors
    function distributePresale(address[] _investors, uint[] _amounts) public onlyOwner {
        require(!hasClosed());
        require(_investors.length == _amounts.length);

        uint totalAmount = 0;

        for (uint i = 0; i < _investors.length; ++i) {
            VreoToken(token).mint(_investors[i], _amounts[i]);
            totalAmount = totalAmount.add(_amounts[i]);
        }

        require(remainingTokensForSale >= totalAmount);
        remainingTokensForSale = remainingTokensForSale.sub(totalAmount);
    }

    /// @dev Set rate
    /// @param _newRate the new rate
    function setRate(uint _newRate) public onlyOwner {
        // A rate change by a magnitude order of ten and above is rather a typo than intention.
        // If it was indeed desired, several setRate transactions have to be sent.
        require(rate / 10 < _newRate && _newRate < 10 * rate);

        rate = _newRate;

        emit RateChanged(_newRate);
    }

    /// @dev unverified investors can withdraw their money only after the VREO Sale ended
    function withdrawInvestment() public {
        require(hasClosed());

        super.withdrawInvestment();
    }

    /// @dev Is the sale for ICONIQ investors ongoing?
    /// @return bool
    function iconiqSaleOngoing() public view returns (bool) {
        return ICONIQ_SALE_OPENING_TIME <= now && now <= ICONIQ_SALE_CLOSING_TIME;
    }

    /// @dev Is the Vreo main sale ongoing?
    /// @return bool
    function vreoSaleOngoing() public view returns (bool) {
        return VREO_SALE_OPENING_TIME <= now && now <= VREO_SALE_CLOSING_TIME;
    }

    /// @dev Get maximum possible wei investment while Iconiq sale
    /// @param _investor an investors Ethereum address
    /// @return Maximum allowed wei investment
    function getIconiqMaxInvestment(address _investor) public view returns (uint) {
        uint iconiqBalance = iconiqToken.balanceOf(_investor);
        uint prorataLimit = iconiqBalance.div(ICONIQ_TOKENS_NEEDED_PER_INVESTED_WEI);

        // Substract Wei amount already invested.
        require(prorataLimit >= investments[_investor].totalWeiInvested);
        return prorataLimit.sub(investments[_investor].totalWeiInvested);
    }

    /// @dev Pre validate purchase
    /// @param _beneficiary an investors Ethereum address
    /// @param _weiAmount wei amount invested
    function _preValidatePurchase(address _beneficiary, uint _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        require(iconiqSaleOngoing() && getIconiqMaxInvestment(msg.sender) >= _weiAmount || vreoSaleOngoing());
    }

    /// @dev Get token amount
    /// @param _weiAmount wei amount invested
    /// @return token amount with bonus
    function _getTokenAmount(uint _weiAmount) internal view returns (uint) {
        uint tokenAmount = super._getTokenAmount(_weiAmount);

        if (now <= ICONIQ_SALE_CLOSING_TIME) {
            return tokenAmount.mul(100 + BONUS_PCT_IN_ICONIQ_SALE).div(100);
        }

        if (now <= VREO_SALE_PHASE_1_END_TIME) {
            return tokenAmount.mul(100 + BONUS_PCT_IN_VREO_SALE_PHASE_1).div(100);
        }

        if (now <= VREO_SALE_PHASE_2_END_TIME) {
            return tokenAmount.mul(100 + BONUS_PCT_IN_VREO_SALE_PHASE_2).div(100);
        }

        return tokenAmount;  // No bonus
    }

    /// @dev Deliver tokens
    /// @param _beneficiary an investors Ethereum address
    /// @param _tokenAmount token amount to deliver
    function _deliverTokens(address _beneficiary, uint _tokenAmount) internal {
        require(remainingTokensForSale >= _tokenAmount);
        remainingTokensForSale = remainingTokensForSale.sub(_tokenAmount);

        super._deliverTokens(_beneficiary, _tokenAmount);
    }

    /// @dev Finalization
    function finalization() internal {
        require(now >= KYC_VERIFICATION_END_TIME);

        VreoToken(token).mint(teamAddress, TOKEN_SHARE_OF_TEAM);
        VreoToken(token).mint(advisorsAddress, TOKEN_SHARE_OF_ADVISORS);
        VreoToken(token).mint(legalsAddress, TOKEN_SHARE_OF_LEGALS);
        VreoToken(token).mint(bountyAddress, TOKEN_SHARE_OF_BOUNTY);

        VreoToken(token).finishMinting();
        VreoToken(token).unpause();

        super.finalization();
    }

}