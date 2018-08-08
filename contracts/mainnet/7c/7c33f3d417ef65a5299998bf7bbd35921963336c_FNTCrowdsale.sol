/*************************************************************************
 * This contract has been merged with solidify
 * https://github.com/tiesnetwork/solidify
 *************************************************************************/
 
 pragma solidity ^0.4.18;


/*************************************************************************
 * import "zeppelin-solidity/contracts/token/TokenTimelock.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../token/SafeERC20.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/





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
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
/*************************************************************************
 * import "../token/SafeERC20.sol" : end
 *************************************************************************/

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/TokenTimelock.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./FNTRefundableCrowdsale.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "../math/SafeMath.sol" : start
 *************************************************************************/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
/*************************************************************************
 * import "../math/SafeMath.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./FinalizableCrowdsale.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "../ownership/Ownable.sol" : start
 *************************************************************************/


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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/*************************************************************************
 * import "../ownership/Ownable.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./Crowdsale.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "../token/MintableToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./StandardToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/






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
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/



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
/*************************************************************************
 * import "./StandardToken.sol" : end
 *************************************************************************/




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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}
/*************************************************************************
 * import "../token/MintableToken.sol" : end
 *************************************************************************/


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}
/*************************************************************************
 * import "./Crowdsale.sol" : end
 *************************************************************************/

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

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
/*************************************************************************
 * import "./FinalizableCrowdsale.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./RefundVault.sol" : start
 *************************************************************************/




/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}
/*************************************************************************
 * import "./RefundVault.sol" : end
 *************************************************************************/


/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale&#39;s vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

  // We&#39;re overriding the fund forwarding from Crowdsale.
  // In addition to sending the funds, we want to call
  // the RefundVault deposit function
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}
/*************************************************************************
 * import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol" : end
 *************************************************************************/


/**
 * @title FNTRefundableCrowdsale
 * @dev Extension of teh RefundableCrowdsale form zeppelin to allow vault to be
 * closed once soft cap is reached
 */
contract FNTRefundableCrowdsale is RefundableCrowdsale {

  // if the vault was closed before finalization
  bool public vaultClosed = false;

  // close vault call
  function closeVault() public onlyOwner {
    require(!vaultClosed);
    require(goalReached());
    vault.close();
    vaultClosed = true;
  }

  // We&#39;re overriding the fund forwarding from Crowdsale.
  // In addition to sending the funds, we want to call
  // the RefundVault deposit function if the vault is not closed,
  // if it is closed we forward teh funds to the wallet
  function forwardFunds() internal {
    if (!vaultClosed) {
      vault.deposit.value(msg.value)(msg.sender);
    } else {
      wallet.transfer(msg.value);
    }
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (!vaultClosed && goalReached()) {
      vault.close();
      vaultClosed = true;
    } else if (!goalReached()) {
      vault.enableRefunds();
    }
  }
}
/*************************************************************************
 * import "./FNTRefundableCrowdsale.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./FNTToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "zeppelin-solidity/contracts/token/BurnableToken.sol" : start
 *************************************************************************/



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
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/BurnableToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/PausableToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "../lifecycle/Pausable.sol" : start
 *************************************************************************/





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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}
/*************************************************************************
 * import "../lifecycle/Pausable.sol" : end
 *************************************************************************/

/**
 * @title Pausable token
 *
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
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/PausableToken.sol" : end
 *************************************************************************/

/**
   @title FNTToken, the Friend token

   Implementation of FRND, the ERC20 token for Friend, with extra methods
   to transfer value and data to execute a call on transfer.
   Uses OpenZeppelin BurnableToken, MintableToken and PausableToken.
 */
contract FNTToken is BurnableToken, MintableToken, PausableToken {
  // Token Name
  string public constant NAME = "Friend Network Token";

  // Token Symbol
  string public constant SYMBOL = "FRND";

  // Token decimals
  uint8 public constant DECIMALS = 18;

}
/*************************************************************************
 * import "./FNTToken.sol" : end
 *************************************************************************/

/**
 * @title FNTCrowdsale
 * @dev The crowdsale of the Firend Token network
 * The Friend token network will have a max total supply of 2000000000
 * The minimun cap for the sale is 25000 ETH
 * The crowdsale is capped in tokens total supply
 * If the minimun cap is not reached the ETH raised is returned
 */
contract FNTCrowdsale is FNTRefundableCrowdsale {

  uint256 public maxICOSupply;

  uint256 public maxTotalSupply;

  uint256 public minFunding;

  uint256 public mediumFunding;

  uint256 public highFunding;

  uint256 public presaleWei;

  address public teamAddress;

  address public FSNASAddress;

  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);
  event VestedTeamTokens(address first, address second, address thrid, address fourth);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev Constructor
   * Creates a Refundable Crowdsale and set the funding, max supply and addresses
   * to distribute tokens at the end of the crowdsale.
   * @param _startTime address, when the crowdsale starts
   * @param _endTime address, when the crowdsale ends
   * @param _rate address, crowdsale rate without bonus
   * @param _minFunding address, soft cap
   * @param _mediumFunding address, medium funding stage
   * @param _highFunding address, high funding stage
   * @param _wallet address, wallet to receive ETH raised
   * @param _maxTotalSupply address, maximun token supply
   * @param _teamAddress address, team&#39;s address
   * @param _FSNASAddress address, fsnas address
   */
  function FNTCrowdsale(
    uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _minFunding,
    uint256 _mediumFunding, uint256 _highFunding, address _wallet,
    uint256 _maxTotalSupply, address _teamAddress, address _FSNASAddress
  ) public
    RefundableCrowdsale(_minFunding)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_maxTotalSupply > 0);
    require(_minFunding > 0);
    require(_mediumFunding > _minFunding);
    require(_highFunding > _mediumFunding);
    require(_teamAddress != address(0));
    require(_FSNASAddress != address(0));
    minFunding = _minFunding;
    mediumFunding = _mediumFunding;
    highFunding = _highFunding;
    maxTotalSupply = _maxTotalSupply;
    maxICOSupply = maxTotalSupply.mul(82).div(100);
    teamAddress = _teamAddress;
    FSNASAddress = _FSNASAddress;
    FNTToken(token).pause();
  }

  // Internal function that returns a MintableToken, FNTToken is mintable
  function createTokenContract() internal returns (MintableToken) {
    return new FNTToken();
  }

  /**
   * @dev Buy tokens fallback function, overrides zeppelin buyTokens function
   * @param beneficiary address, the address that will receive the tokens
   *
   * ONLY send from a ERC20 compatible wallet like myetherwallet.com
   *
   */
  function buyTokens(address beneficiary) public onlyWhitelisted payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = 0;
    if (weiRaised < minFunding) {

      // If the weiRaised go from less than min funding to more than high funding
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          mediumFunding.sub(minFunding).mul(rate).mul(110).div(100)
        );
        tokens = tokens.add(
          highFunding.sub(mediumFunding).mul(rate).mul(105).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

      // If the weiRaised go from less than min funding to more than medium funding
      } else if (weiRaised.add(weiAmount) > mediumFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          mediumFunding.sub(minFunding).mul(rate).mul(110).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(mediumFunding).mul(rate).mul(105).div(100)
        );

      // If the weiRaised go from less than min funding to more than min funding
      // but less than medium
      } else if (weiRaised.add(weiAmount) > minFunding) {
        tokens = minFunding.sub(weiRaised)
          .mul(rate).mul(115).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(minFunding).mul(rate).mul(110).div(100)
        );

      // If the weiRaised still continues being less than min funding
      } else {
        tokens = weiAmount.mul(rate).mul(115).div(100);
      }

    } else if ((weiRaised >= minFunding) && (weiRaised < mediumFunding)) {

      // If the weiRaised go from more than min funding and less than min funding
      // to more than high funding
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = mediumFunding.sub(weiRaised)
          .mul(rate).mul(110).div(100);
        tokens = tokens.add(
          highFunding.sub(mediumFunding).mul(rate).mul(105).div(100)
        );
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

      // If the weiRaised go from more than min funding and less than min funding
      // to more than medium funding
      } else if (weiRaised.add(weiAmount) > mediumFunding) {
        tokens = mediumFunding.sub(weiRaised)
          .mul(rate).mul(110).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(mediumFunding).mul(rate).mul(105).div(100)
        );

      // If the weiRaised still continues being less than medium funding
      } else {
        tokens = weiAmount.mul(rate).mul(110).div(100);
      }

    } else if ((weiRaised >= mediumFunding) && (weiRaised < highFunding)) {

      // If the weiRaised go from more than medium funding and less than high funding
      // to more than high funding
      if (weiRaised.add(weiAmount) > highFunding) {
        tokens = highFunding.sub(weiRaised)
          .mul(rate).mul(105).div(100);
        tokens = tokens.add(
          weiRaised.add(weiAmount).sub(highFunding).mul(rate)
        );

      // If the weiRaised still continues being less than high funding
      } else {
        tokens = weiAmount.mul(rate).mul(105).div(100);
      }

    // If the weiRaised still continues being more than high funding
    } else {
      tokens = weiAmount.mul(rate);
    }

    // Check not to sold more than maxICOSupply
    require(token.totalSupply().add(tokens) <= maxICOSupply);

    // Take in count wei received
    weiRaised = weiRaised.add(weiAmount);

    // Mint the token to the buyer
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // Forward funds to vault
    forwardFunds();
  }

  /**
   * @dev Distribute tokens to a batch of addresses, called only by owner
   * @param addrs address[], the addresses where tokens will be issued
   * @param values uint256[], the value in wei to be added
   * @param rate uint256, the rate of tokens per ETH used
   */
  function addPresaleTokens(
    address[] addrs, uint256[] values, uint256 rate
  ) onlyOwner external {
    require(now < endTime);
    require(addrs.length == values.length);
    require(rate > 0);

    uint256 totalTokens = 0;

    for(uint256 i = 0; i < addrs.length; i ++) {
      token.mint(addrs[i], values[i].mul(rate));
      totalTokens = totalTokens.add(values[i].mul(rate));

      // Take in count wei received
      weiRaised = weiRaised.add(values[i]);
      presaleWei = presaleWei.add(values[i]);
    }

    // Check not to issue more than maxICOSupply
    require(token.totalSupply() <= maxICOSupply);
  }

  /**
   * @dev add an address to the whitelist
   * @param addrs address[] addresses to be added in whitelist
   */
  function addToWhitelist(address[] addrs) onlyOwner external {
    for(uint256 i = 0; i < addrs.length; i ++) {
      require(!whitelist[addrs[i]]);
      whitelist[addrs[i]] = true;
      WhitelistedAddressAdded(addrs[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addrs address[] addresses to be removed from whitelist
   */
  function removeFromWhitelist(address[] addrs) onlyOwner public {
    for(uint256 i = 0; i < addrs.length; i ++) {
      require(whitelist[addrs[i]]);
      whitelist[addrs[i]] = false;
      WhitelistedAddressRemoved(addrs[i]);
    }
  }


  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    
    if( goalReached() )
    {
	    finalization();
	    Finalized();
	
	    isFinalized = true;
    }
	else
	{
		if( hasEnded() )
		{
		    vault.enableRefunds();
		    
		    Finalized();
		    isFinalized = true;
		}
	}    
  }

  /**
   * @dev Finalize the crowdsale and token minting, and transfer ownership of
   * the token, can be called only by owner
   */
  function finalization() internal {
    super.finalization();

    // Multiplying tokens sold by 0,219512195122
    // 18 / 82 = 0,219512195122 , which means that for every token sold in ICO
    // 0,219512195122 extra tokens will be issued.
    uint256 extraTokens = token.totalSupply().mul(219512195122).div(1000000000000);
    uint256 teamTokens = extraTokens.div(3);
    uint256 FSNASTokens = extraTokens.div(3).mul(2);

    // Mint toke time locks to team
    TokenTimelock firstBatch = new TokenTimelock(token, teamAddress, now.add(30 days));
    token.mint(firstBatch, teamTokens.div(2));

    TokenTimelock secondBatch = new TokenTimelock(token, teamAddress, now.add(1 years));
    token.mint(secondBatch, teamTokens.div(2).div(3));

    TokenTimelock thirdBatch = new TokenTimelock(token, teamAddress, now.add(2 years));
    token.mint(thirdBatch, teamTokens.div(2).div(3));

    TokenTimelock fourthBatch = new TokenTimelock(token, teamAddress, now.add(3 years));
    token.mint(fourthBatch, teamTokens.div(2).div(3));

    VestedTeamTokens(firstBatch, secondBatch, thirdBatch, fourthBatch);

    // Mint FSNAS tokens
    token.mint(FSNASAddress, FSNASTokens);

    // Finsih the minting
    token.finishMinting();

    // Transfer ownership of token to company wallet
    token.transferOwnership(wallet);

  }

}