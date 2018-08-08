pragma solidity ^0.4.21;

// File: contracts/math/SafeMath.sol

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

// File: contracts/token/ERC20Basic.sol

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

// File: contracts/token/BasicToken.sol

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
    emit Transfer(msg.sender, _to, _value);
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

// File: contracts/token/BurnableToken.sol

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
        emit Burn(burner, _value);
    }
}

// File: contracts/ownership/Ownable.sol

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

// File: contracts/token/ERC20.sol

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

// File: contracts/token/StandardToken.sol

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

// File: contracts/token/MintableToken.sol

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
   *
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
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

// File: contracts/token/SafeERC20.sol

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

// File: contracts/BitexToken.sol

contract BitexToken is MintableToken, BurnableToken {
    using SafeERC20 for ERC20;

    string public constant name = "Bitex Coin";

    string public constant symbol = "XBX";

    uint8 public decimals = 18;

    bool public tradingStarted = false;

    // allow exceptional transfer fro sender address - this mapping  can be modified only before the starting rounds
    mapping (address => bool) public transferable;

    /**
     * @dev modifier that throws if spender address is not allowed to transfer
     * and the trading is not enabled
     */
    modifier allowTransfer(address _spender) {

        require(tradingStarted || transferable[_spender]);
        _;
    }
    /**
    *
    * Only the owner of the token smart contract can add allow token to be transfer before the trading has started
    *
    */

    function modifyTransferableHash(address _spender, bool value) onlyOwner public {
        transferable[_spender] = value;
    }

    /**
     * @dev Allows the owner to enable the trading.
     */
    function startTrading() onlyOwner public {
        tradingStarted = true;
    }

    /**
     * @dev Allows anyone to transfer the tokens once trading has started
     * @param _to the recipient address of the tokens.
     * @param _value number of tokens to be transfered.
     */
    function transfer(address _to, uint _value) allowTransfer(msg.sender) public returns (bool){
        return super.transfer(_to, _value);
    }

    /**
     * @dev Allows anyone to transfer the  tokens once trading has started or if the spender is part of the mapping

     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint _value) allowTransfer(_from) public returns (bool){
        return super.transferFrom(_from, _to, _value);
    }

    /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender when not paused.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
    function approve(address _spender, uint256 _value) public allowTransfer(_spender) returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * Adding whenNotPaused
     */
    function increaseApproval(address _spender, uint _addedValue) public allowTransfer(_spender) returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * Adding whenNotPaused
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public allowTransfer(_spender) returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

// File: contracts/KnowYourCustomer.sol

contract KnowYourCustomer is Ownable
{
    //
    // with this structure
    //
    struct Contributor {
        // kyc cleared or not
        bool cleared;

        // % more for the contributor bring on board in 1/100 of %
        // 2.51 % --> 251
        // 100% --> 10000
        uint16 contributor_get;

        // eth address of the referer if any - the contributor address is the key of the hash
        address ref;

        // % more for the referrer
        uint16 affiliate_get;
    }


    mapping (address => Contributor) public whitelist;
    //address[] public whitelistArray;

    /**
    *    @dev Populate the whitelist, only executed by whiteListingAdmin
    *  whiteListingAdmin /
    */

    function setContributor(address _address, bool cleared, uint16 contributor_get, uint16 affiliate_get, address ref) onlyOwner public{

        // not possible to give an exorbitant bonus to be more than 100% (100x100 = 10000)
        require(contributor_get<10000);
        require(affiliate_get<10000);

        Contributor storage contributor = whitelist[_address];

        contributor.cleared = cleared;
        contributor.contributor_get = contributor_get;

        contributor.ref = ref;
        contributor.affiliate_get = affiliate_get;

    }

    function getContributor(address _address) view public returns (bool, uint16, address, uint16 ) {
        return (whitelist[_address].cleared, whitelist[_address].contributor_get, whitelist[_address].ref, whitelist[_address].affiliate_get);
    }

    function getClearance(address _address) view public returns (bool) {
        return whitelist[_address].cleared;
    }
}

// File: contracts/crowdsale/Crowdsale.sol

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
  // overrided to create custom buy
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // overrided to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime ;
    bool nonZeroPurchase = msg.value != 0 ;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

// File: contracts/crowdsale/FinalizableCrowdsale.sol

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
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal{
  }
}

// File: contracts/crowdsale/RefundVault.sol

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
    // this is this part that shall be removed, that way if called later it run the wallet transfer in any case
    // require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}

// File: contracts/crowdsale/RefundableCrowdsale.sol

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

// File: contracts/BitexTokenCrowdSale.sol

contract BitexTokenCrowdSale is Crowdsale, RefundableCrowdsale {
    using SafeMath for uint256;

    // number of participants
    uint256 public numberOfPurchasers = 0;

    // maximum tokens that can be minted in this crowd sale - initialised later by the constructor
    uint256 public maxTokenSupply = 0;

    // amounts of tokens already minted at the begining of this crowd sale - initialised later by the constructor
    uint256 public initialTokenAmount = 0;

    // Minimum amount to been able to contribute - initialised later by the constructor
    uint256 public minimumAmount = 0;

    // to compute the bonus
    bool public preICO;

    // the token
    BitexToken public token;

    // the kyc and affiliation management
    KnowYourCustomer public kyc;

    // remaining token are sent to this address
    address public walletRemaining;

    // this is the owner of the token, when the finalize function is called
    address public pendingOwner;


    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 rate, address indexed referral, uint256 referredBonus );
    event TokenPurchaseAffiliate(address indexed ref, uint256 amount );

    function BitexTokenCrowdSale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _goal,
        uint256 _minimumAmount,
        uint256 _maxTokenSupply,
        address _wallet,
        BitexToken _token,
        KnowYourCustomer _kyc,
        bool _preICO,
        address _walletRemaining,
        address _pendingOwner
    )
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet) public
    { 
        require(_minimumAmount >= 0);
        require(_maxTokenSupply > 0);
        require(_walletRemaining != address(0));

        minimumAmount = _minimumAmount;
        maxTokenSupply = _maxTokenSupply;

        preICO = _preICO;

        walletRemaining = _walletRemaining;
        pendingOwner = _pendingOwner;

        kyc = _kyc;
        token = _token;

        //
        // record the amount of already minted token to been able to compute the delta with the tokens
        // minted during the pre sale, this is useful only for the pre - ico
        //
        if (preICO)
        {
            initialTokenAmount = token.totalSupply();
        }
    }

    /**
    *
    * Create the token on the fly, owner is the contract, not the contract owner yet
    *
    **/
    function createTokenContract() internal returns (MintableToken) {
        return token;
    }


    /**
    * @dev Calculates the amount of  coins the buyer gets
    * @param weiAmount uint the amount of wei send to the contract
    * @return uint the amount of tokens the buyer gets
    */
    function computeTokenWithBonus(uint256 weiAmount) public view returns(uint256) {
        uint256 tokens_ = 0;
        if (preICO)
        {
            if (weiAmount >= 50000 ether  ) {

                tokens_ = weiAmount.mul(34).div(100);

            }
            else if (weiAmount<50000 ether && weiAmount >= 10000 ether) {

                tokens_ = weiAmount.mul(26).div(100);

            } else if (weiAmount<10000 ether && weiAmount >= 5000 ether) {

                tokens_ = weiAmount.mul(20).div(100);

            } else if (weiAmount<5000 ether && weiAmount >= 1000 ether) {

                tokens_ = weiAmount.mul(16).div(100);
            }

        }else{
            if (weiAmount >= 50000 ether  ) {

                tokens_ = weiAmount.mul(17).div(100);

            }
            else if (weiAmount<50000 ether && weiAmount >= 10000 ether) {

                tokens_ = weiAmount.mul(13).div(100);

            } else if (weiAmount<10000 ether && weiAmount >= 5000 ether) {

                tokens_ = weiAmount.mul(10).div(100);

            } else if (weiAmount<5000 ether && weiAmount >= 1000 ether) {

                tokens_ = weiAmount.mul(8).div(100);
            }

        }

        return tokens_;
    }
    //
    // override the claimRefund, so only user that have burn their token can claim for a refund
    //
    function claimRefund() public {

        // get the number of token from this sender
        uint256 tokenBalance = token.balanceOf(msg.sender);

        // the refund can be run  only if the tokens has been burn
        require(tokenBalance == 0);

        // run the refund
        super.claimRefund();

    }

     // transfer the token owner ship to the crowdsale contract
    //        token.transferOwnership(currentIco);
    function finalization() internal {

        if (!preICO)
        {
            uint256 remainingTokens = maxTokenSupply.sub(token.totalSupply());

            // mint the remaining amount and assign them to the beneficiary
            // --> here we can manage the vesting of the remaining tokens
            //
            token.mint(walletRemaining, remainingTokens);

        }

         // finalize the refundable inherited contract
        super.finalization();

        if (!preICO)
        {
            // no more minting allowed - immutable
            token.finishMinting();
        }

        // transfer the token owner ship from the contract address to the pendingOwner icoController
        token.transferOwnership(pendingOwner);

    }



    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        // validate KYC here
        // if not part of kyc then throw
        bool cleared;
        uint16 contributor_get;
        address ref;
        uint16 affiliate_get;

        (cleared,contributor_get,ref,affiliate_get) = kyc.getContributor(beneficiary);

        // Transaction do not happen if the contributor is not KYC cleared
        require(cleared);

        // how much the contributor sent in wei
        uint256 weiAmount = msg.value;

        // Compute the number of tokens per wei using the rate
        uint256 tokens = weiAmount.mul(rate);

         // compute the amount of bonus, from the contribution amount
        uint256 bonus = computeTokenWithBonus(tokens);

        // compute the amount of token bonus for the contributor thank to his referral
        uint256 contributorGet = tokens.mul(contributor_get).div(100*100);

        // Sum it all
        tokens = tokens.add(bonus);
        tokens = tokens.add(contributorGet);

        // capped to a maxTokenSupply
        // make sure we can not mint more token than expected
        // require(((token.totalSupply()-initialTokenAmount) + tokens) <= maxTokenSupply);
        require((minted().add(tokens)) <= maxTokenSupply);


        // Mint the token
        token.mint(beneficiary, tokens);

        // log the event
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, rate, ref, contributorGet);

        // update wei raised and number of purchasers
        weiRaised = weiRaised.add(weiAmount);
        numberOfPurchasers = numberOfPurchasers + 1;

        forwardFunds();

        // ------------------------------------------------------------------
        // compute the amount of token bonus that the referral get :
        // only if KYC cleared, only if enough tokens still available
        // ------------------------------------------------------------------
        bool refCleared;
        (refCleared) = kyc.getClearance(ref);
        if (refCleared && ref != beneficiary)
        {
            // recompute the tokens amount using only the rate
            tokens = weiAmount.mul(rate);

            // compute the amount of token for the affiliate
            uint256 affiliateGet = tokens.mul(affiliate_get).div(100*100);

            // capped to a maxTokenSupply
            // make sure we can not mint more token than expected
            // we do not throw here as if this edge case happens it can be dealt with of chain
            // if ( (token.totalSupply()-initialTokenAmount) + affiliateGet <= maxTokenSupply)
            if ( minted().add(affiliateGet) <= maxTokenSupply)

            {
                // Mint the token
                token.mint(ref, affiliateGet);
                emit TokenPurchaseAffiliate(ref, tokens );
            }

        }
    }

    // overriding Crowdsale#validPurchase to add extra cap logic
    // @return true if investors can buy at the moment
    function validPurchase() internal view returns (bool) {

        // make sure we accept only the minimum contribution
        bool minAmount = (msg.value >= minimumAmount);

        // make sure that the purchase follow each rules to be valid
        return super.validPurchase() && minAmount;
    }

    function minted() public view returns(uint256)
    {
        return token.totalSupply().sub(initialTokenAmount); 
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        // bool capReached = (token.totalSupply() - initialTokenAmount) >= maxTokenSupply;
        // bool capReached = minted() >= maxTokenSupply;
        return super.hasEnded() || (minted() >= maxTokenSupply);
    }

    /**
      *
      * Admin functions only executed by owner:
      * Can change minimum amount
      *
      */
    function changeMinimumAmount(uint256 _minimumAmount) onlyOwner public {
        require(_minimumAmount > 0);

        minimumAmount = _minimumAmount;
    }

     /**
      *
      * Admin functions only executed by owner:
      * Can change rate
      *
      * We do not use an oracle here as oracle need to be paid each time, and if the oracle is not responding
      * or hacked the rate could be detrimentally modified from an contributor perspective.
      *
      */
    function changeRate(uint256 _rate) onlyOwner public {
        require(_rate > 0);
        
        rate = _rate;
    }

    /**
      *
      * Admin functions only called by owner:
      * Can change events dates
      *
      */
    function changeDates(uint256 _startTime, uint256 _endTime) onlyOwner public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

    function modifyTransferableHash(address _spender, bool value) onlyOwner public {
        token.modifyTransferableHash(_spender,value);
    }

    /**
      *
      * Admin functions only called by owner:
      * Can transfer the owner ship of the vault, so a close can be called
      * only by the owner ....
      *
      */
    function transferVault(address newOwner) onlyOwner public {
        vault.transferOwnership(newOwner);

    }
   
}