pragma solidity ^0.4.23;

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
    uint256 c = a / b;
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

/**
 * @title TalaoMarketplace
 * @dev This contract is allowing users to buy or sell Talao tokens at a price set by the owner
 * @author Blockchain Partner
 */
contract TalaoMarketplace is Ownable {
  using SafeMath for uint256;

  TalaoToken public token;

  struct MarketplaceData {
    uint buyPrice;
    uint sellPrice;
    uint unitPrice;
  }

  MarketplaceData public marketplace;

  event SellingPrice(uint sellingPrice);
  event TalaoBought(address buyer, uint amount, uint price, uint unitPrice);
  event TalaoSold(address seller, uint amount, uint price, uint unitPrice);

  /**
  * @dev Constructor of the marketplace pointing to the TALAO token address
  * @param talao the talao token address
  **/
  constructor(address talao)
      public
  {
      token = TalaoToken(talao);
  }

  /**
  * @dev Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
  * @param newSellPrice price the users can sell to the contract
  * @param newBuyPrice price users can buy from the contract
  * @param newUnitPrice to manage decimal issue 0,35 = 35 /100 (100 is unit)
  */
  function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnitPrice)
      public
      onlyOwner
  {
      require (newSellPrice > 0 && newBuyPrice > 0 && newUnitPrice > 0, "wrong inputs");
      marketplace.sellPrice = newSellPrice;
      marketplace.buyPrice = newBuyPrice;
      marketplace.unitPrice = newUnitPrice;
  }

  /**
  * @dev Allow anyone to buy tokens against ether, depending on the buyPrice set by the contract owner.
  * @return amount the amount of tokens bought
  **/
  function buy()
      public
      payable
      returns (uint amount)
  {
      amount = msg.value.mul(marketplace.unitPrice).div(marketplace.buyPrice);
      token.transfer(msg.sender, amount);
      emit TalaoBought(msg.sender, amount, marketplace.buyPrice, marketplace.unitPrice);
      return amount;
  }

  /**
  * @dev Allow anyone to sell tokens for ether, depending on the sellPrice set by the contract owner.
  * @param amount the number of tokens to be sold
  * @return revenue ethers sent in return
  **/
  function sell(uint amount)
      public
      returns (uint revenue)
  {
      require(token.balanceOf(msg.sender) >= amount, "sender has not enough tokens");
      token.transferFrom(msg.sender, this, amount);
      revenue = amount.mul(marketplace.sellPrice).div(marketplace.unitPrice);
      msg.sender.transfer(revenue);
      emit TalaoSold(msg.sender, amount, marketplace.sellPrice, marketplace.unitPrice);
      return revenue;
  }

  /**
   * @dev Allows the owner to withdraw ethers from the contract.
   * @param ethers quantity of ethers to be withdrawn
   * @return true if withdrawal successful ; false otherwise
   */
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      if (this.balance >= ethers) {
          msg.sender.transfer(ethers);
      }
  }

  /**
   * @dev Allow the owner to withdraw tokens from the contract.
   * @param tokens quantity of tokens to be withdrawn
   */
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      token.transfer(msg.sender, tokens);
  }


  /**
  * @dev Fallback function ; only owner can send ether.
  **/
  function ()
      public
      payable
      onlyOwner
  {

  }

}

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
   * @dev Removed original require that amount released was > 0 ; releasing 0 is fine
   */
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);

    token.safeTransfer(beneficiary, amount);
  }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 * @notice Talao token transfer function cannot fail thus there&#39;s no need for revocation.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @dev Removed original require that amount released was > 0 ; releasing 0 is fine
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

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

  function Crowdsale(uint256 _rate, uint256 _startTime, uint256 _endTime, address _wallet) public {
    require(_rate > 0);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
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
  // removed view to be overriden
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}


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
  function finalize() public {
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


/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  // removed view to be overriden
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

/**
 * @title ProgressiveIndividualCappedCrowdsale
 * @dev Extension of Crowdsale with a progressive individual cap
 * @dev This contract is not made for crowdsale superior to 256 * TIME_PERIOD_IN_SEC
 * @author Request.network ; some modifications by Blockchain Partner
 */
contract ProgressiveIndividualCappedCrowdsale is RefundableCrowdsale, CappedCrowdsale {

    uint public startGeneralSale;
    uint public constant TIME_PERIOD_IN_SEC = 1 days;
    uint public constant minimumParticipation = 10 finney;
    uint public constant GAS_LIMIT_IN_WEI = 5E10 wei; // limit gas price -50 Gwei wales stopper
    uint256 public baseEthCapPerAddress;

    mapping(address=>uint) public participated;

    function ProgressiveIndividualCappedCrowdsale(uint _baseEthCapPerAddress, uint _startGeneralSale)
        public
    {
        baseEthCapPerAddress = _baseEthCapPerAddress;
        startGeneralSale = _startGeneralSale;
    }

    /**
     * @dev setting cap before the general sale starts
     * @param _newBaseCap the new cap
     */
    function setBaseCap(uint _newBaseCap)
        public
        onlyOwner
    {
        require(now < startGeneralSale);
        baseEthCapPerAddress = _newBaseCap;
    }

    /**
     * @dev overriding CappedCrowdsale#validPurchase to add an individual cap
     * @return true if investors can buy at the moment
     */
    function validPurchase()
        internal
        returns(bool)
    {
        bool gasCheck = tx.gasprice <= GAS_LIMIT_IN_WEI;
        uint ethCapPerAddress = getCurrentEthCapPerAddress();
        participated[msg.sender] = participated[msg.sender].add(msg.value);
        bool enough = participated[msg.sender] >= minimumParticipation;
        return participated[msg.sender] <= ethCapPerAddress && enough && gasCheck;
    }

    /**
     * @dev Get the current individual cap.
     * @dev This amount increase everyday in an exponential way. Day 1: base cap, Day 2: 2 * base cap, Day 3: 4 * base cap ...
     * @return individual cap in wei
     */
    function getCurrentEthCapPerAddress()
        public
        constant
        returns(uint)
    {
        if (block.timestamp < startGeneralSale) return 0;
        uint timeSinceStartInSec = block.timestamp.sub(startGeneralSale);
        uint currentPeriod = timeSinceStartInSec.div(TIME_PERIOD_IN_SEC).add(1);

        // for currentPeriod > 256 will always return 0
        return (2 ** currentPeriod.sub(1)).mul(baseEthCapPerAddress);
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


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

/**
 * @title TalaoToken
 * @dev This contract details the TALAO token and allows freelancers to create/revoke vault access, appoint agents.
 * @author Blockchain Partner
 */
contract TalaoToken is MintableToken {
  using SafeMath for uint256;

  // token details
  string public constant name = "Talao";
  string public constant symbol = "TALAO";
  uint8 public constant decimals = 18;

  // the talao marketplace address
  address public marketplace;

  // talao tokens needed to create a vault
  uint256 public vaultDeposit;
  // sum of all talao tokens desposited
  uint256 public totalDeposit;

  struct FreelanceData {
      // access price to the talent vault
      uint256 accessPrice;
      // address of appointed talent agent
      address appointedAgent;
      // how much the talent is sharing with its agent
      uint sharingPlan;
      // how much is the talent deposit
      uint256 userDeposit;
  }

  // structure that defines a client access to a vault
  struct ClientAccess {
      // is he allowed to access the vault
      bool clientAgreement;
      // the block number when access was granted
      uint clientDate;
  }

  // Vault allowance client x freelancer
  mapping (address => mapping (address => ClientAccess)) public accessAllowance;

  // Freelance data is public
  mapping (address=>FreelanceData) public data;

  enum VaultStatus {Closed, Created, PriceTooHigh, NotEnoughTokensDeposited, AgentRemoved, NewAgent, NewAccess, WrongAccessPrice}

  // Those event notifies UI about vaults action with vault status
  // Closed Vault access closed
  // Created Vault access created
  // PriceTooHigh Vault access price too high
  // NotEnoughTokensDeposited not enough tokens to pay deposit
  // AgentRemoved agent removed
  // NewAgent new agent appointed
  // NewAccess vault access granted to client
  // WrongAccessPrice client not enough token to pay vault access
  event Vault(address indexed client, address indexed freelance, VaultStatus status);

  modifier onlyMintingFinished()
  {
      require(mintingFinished == true, "minting has not finished");
      _;
  }

  /**
  * @dev Let the owner set the marketplace address once minting is over
  *      Possible to do it more than once to ensure maintainability
  * @param theMarketplace the marketplace address
  **/
  function setMarketplace(address theMarketplace)
      public
      onlyMintingFinished
      onlyOwner
  {
      marketplace = theMarketplace;
  }

  /**
  * @dev Same ERC20 behavior, but require the token to be unlocked
  * @param _spender address The address that will spend the funds.
  * @param _value uint256 The amount of tokens to be spent.
  **/
  function approve(address _spender, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.approve(_spender, _value);
  }

  /**
  * @dev Same ERC20 behavior, but require the token to be unlocked and sells some tokens to refill ether balance up to minBalanceForAccounts
  * @param _to address The address to transfer to.
  * @param _value uint256 The amount to be transferred.
  **/
  function transfer(address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool result)
  {
      return super.transfer(_to, _value);
  }

  /**
  * @dev Same ERC20 behavior, but require the token to be unlocked
  * @param _from address The address which you want to send tokens from.
  * @param _to address The address which you want to transfer to.
  * @param _value uint256 the amount of tokens to be transferred.
  **/
  function transferFrom(address _from, address _to, uint256 _value)
      public
      onlyMintingFinished
      returns (bool)
  {
      return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Set allowance for other address and notify
   *      Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   * @param _extraData some extra information to send to the approved contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      public
      onlyMintingFinished
      returns (bool)
  {
      tokenRecipient spender = tokenRecipient(_spender);
      if (approve(_spender, _value)) {
          spender.receiveApproval(msg.sender, _value, this, _extraData);
          return true;
      }
  }

  /**
   * @dev Allows the owner to withdraw ethers from the contract.
   * @param ethers quantity in weis of ethers to be withdrawn
   * @return true if withdrawal successful ; false otherwise
   */
  function withdrawEther(uint256 ethers)
      public
      onlyOwner
  {
      msg.sender.transfer(ethers);
  }

  /**
   * @dev Allow the owner to withdraw tokens from the contract without taking tokens from deposits.
   * @param tokens quantity of tokens to be withdrawn
   */
  function withdrawTalao(uint256 tokens)
      public
      onlyOwner
  {
      require(balanceOf(this).sub(totalDeposit) >= tokens, "too much tokens asked");
      _transfer(this, msg.sender, tokens);
  }

  /******************************************/
  /*      vault functions start here        */
  /******************************************/

  /**
  * @dev Allows anyone to create a vault access.
  *      Vault deposit is transferred to token contract and sum is stored in totalDeposit
  *      Price must be lower than Vault deposit
  * @param price to pay to access certificate vault
  */
  function createVaultAccess (uint256 price)
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==false, "vault already created");
      require(price<=vaultDeposit, "price asked is too high");
      require(balanceOf(msg.sender)>vaultDeposit, "user has not enough tokens to send deposit");
      data[msg.sender].accessPrice=price;
      super.transfer(this, vaultDeposit);
      totalDeposit = totalDeposit.add(vaultDeposit);
      data[msg.sender].userDeposit=vaultDeposit;
      data[msg.sender].sharingPlan=100;
      accessAllowance[msg.sender][msg.sender].clientAgreement=true;
      emit Vault(msg.sender, msg.sender, VaultStatus.Created);
  }

  /**
  * @dev Closes a vault access, deposit is sent back to freelance wallet
  *      Total deposit in token contract is reduced by user deposit
  */
  function closeVaultAccess()
      public
      onlyMintingFinished
  {
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      require(_transfer(this, msg.sender, data[msg.sender].userDeposit), "token deposit transfer failed");
      accessAllowance[msg.sender][msg.sender].clientAgreement=false;
      totalDeposit=totalDeposit.sub(data[msg.sender].userDeposit);
      data[msg.sender].sharingPlan=0;
      emit Vault(msg.sender, msg.sender, VaultStatus.Closed);
  }

  /**
  * @dev Internal transfer function used to transfer tokens from an address to another without prior authorization.
  *      Only used in these situations:
  *           * Send tokens from the contract to a token buyer (buy() function)
  *           * Send tokens from the contract to the owner in order to withdraw tokens (withdrawTalao(tokens) function)
  *           * Send tokens from the contract to a user closing its vault thus claiming its deposit back (closeVaultAccess() function)
  * @param _from address The address which you want to send tokens from.
  * @param _to address The address which you want to transfer to.
  * @param _value uint256 the amount of tokens to be transferred.
  * @return true if transfer is successful ; should throw otherwise
  */
  function _transfer(address _from, address _to, uint _value)
      internal
      returns (bool)
  {
      require(_to != 0x0, "destination cannot be 0x0");
      require(balances[_from] >= _value, "not enough tokens in sender wallet");

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }

  /**
  * @dev Appoint an agent or a new agent
  *      Former agent is replaced by new agent
  *      Agent will receive token on behalf of the freelance talent
  * @param newagent agent to appoint
  * @param newplan sharing plan is %, 100 means 100% for freelance
  */
  function agentApproval (address newagent, uint newplan)
      public
      onlyMintingFinished
  {
      require(newplan>=0&&newplan<=100, "plan must be between 0 and 100");
      require(accessAllowance[msg.sender][msg.sender].clientAgreement==true, "vault has not been created");
      emit Vault(data[msg.sender].appointedAgent, msg.sender, VaultStatus.AgentRemoved);
      data[msg.sender].appointedAgent=newagent;
      data[msg.sender].sharingPlan=newplan;
      emit Vault(newagent, msg.sender, VaultStatus.NewAgent);
  }

  /**
   * @dev Set the quantity of tokens necessary for vault access creation
   * @param newdeposit deposit (in tokens) for vault access creation
   */
  function setVaultDeposit (uint newdeposit)
      public
      onlyOwner
  {
      vaultDeposit = newdeposit;
  }

  /**
  * @dev Buy unlimited access to a freelancer vault
  *      Vault access price is transfered from client to agent or freelance depending on the sharing plan
  *      Allowance is given to client and one stores block.number for future use
  * @param freelance the address of the talent
  * @return true if access is granted ; false if not
  */
  function getVaultAccess (address freelance)
      public
      onlyMintingFinished
      returns (bool)
  {
      require(accessAllowance[freelance][freelance].clientAgreement==true, "vault does not exist");
      require(accessAllowance[msg.sender][freelance].clientAgreement!=true, "access was already granted");
      require(balanceOf(msg.sender)>data[freelance].accessPrice, "user has not enough tokens to get access to vault");

      uint256 freelance_share = data[freelance].accessPrice.mul(data[freelance].sharingPlan).div(100);
      uint256 agent_share = data[freelance].accessPrice.sub(freelance_share);
      if(freelance_share>0) super.transfer(freelance, freelance_share);
      if(agent_share>0) super.transfer(data[freelance].appointedAgent, agent_share);
      accessAllowance[msg.sender][freelance].clientAgreement=true;
      accessAllowance[msg.sender][freelance].clientDate=block.number;
      emit Vault(msg.sender, freelance, VaultStatus.NewAccess);
      return true;
  }

  /**
  * @dev Simple getter to retrieve talent agent
  * @param freelance talent address
  * @return address of the agent
  **/
  function getFreelanceAgent(address freelance)
      public
      view
      returns (address)
  {
      return data[freelance].appointedAgent;
  }

  /**
  * @dev Simple getter to check if user has access to a freelance vault
  * @param freelance talent address
  * @param user user address
  * @return true if access granted or false if not
  **/
  function hasVaultAccess(address freelance, address user)
      public
      view
      returns (bool)
  {
      return ((accessAllowance[user][freelance].clientAgreement) || (data[freelance].appointedAgent == user));
  }

}



/**
 * @title TalaoCrowdsale
 * @dev This contract handles the presale and the crowdsale of the Talao platform.
 * @author Blockchain Partner
 */
contract TalaoCrowdsale is ProgressiveIndividualCappedCrowdsale {
  using SafeMath for uint256;

  uint256 public weiRaisedPreSale;
  uint256 public presaleCap;
  uint256 public startGeneralSale;

  mapping (address => uint256) public presaleParticipation;
  mapping (address => uint256) public presaleIndividualCap;

  uint256 public constant generalRate = 1000;
  uint256 public constant presaleBonus = 250;
  uint256 public constant presaleBonusTier2 = 150;
  uint256 public constant presaleBonusTier3 = 100;
  uint256 public constant presaleBonusTier4 = 50;

  uint256 public dateOfBonusRelease;

  address public constant reserveWallet = 0xC9a2BE82Ba706369730BDbd64280bc1132347F85;
  address public constant futureRoundWallet = 0x80a27A56C29b83b25492c06b39AC049e8719a8fd;
  address public constant advisorsWallet = 0xC9a2BE82Ba706369730BDbd64280bc1132347F85;
  address public constant foundersWallet1 = 0x76934C75Ef9a02D444fa9d337C56c7ab0094154C;
  address public constant foundersWallet2 = 0xd21aF5665Dc81563328d5cA2f984b4f6281c333f;
  address public constant foundersWallet3 = 0x0DceD36d883752203E01441bD006725Acd128049;
  address public constant shareholdersWallet = 0x554bC53533876fC501b230274F47598cbD435B5E;

  uint256 public constant cliffTeamTokensRelease = 3 years;
  uint256 public constant lockTeamTokens = 4 years;
  uint256 public constant cliffAdvisorsTokens = 1 years;
  uint256 public constant lockAdvisorsTokens = 2 years;
  uint256 public constant futureRoundTokensRelease = 1 years;
  uint256 public constant presaleBonusLock = 90 days;
  uint256 public constant presaleParticipationMinimum = 10 ether;

  // 15%
  uint256 public constant dateTier2 = 1528761600; // Tuesday 12 June 2018 00:00:00
  // 10%
  uint256 public constant dateTier3 = 1529366400; // Tuesday 19 June 2018 00:00:00
  // 5%
  uint256 public constant dateTier4 = 1529971200; // Tuesday 26 June 2018 00:00:00

  uint256 public baseEthCapPerAddress = 3 ether;

  mapping (address => address) public timelockedTokensContracts;

  mapping (address => bool) public whiteListedAddress;
  mapping (address => bool) public whiteListedAddressPresale;

  /**
  * @dev Creates the crowdsale. Set starting dates, ending date, caps and wallet. Set the date of presale bonus release.
  * @param _startDate start of the presale (EPOCH format)
  * @param _startGeneralSale start of the crowdsale (EPOCH format)
  * @param _endDate end of the crowdsale (EPOCH format)
  * @param _goal soft cap
  * @param _presaleCap hard cap of the presale
  * @param _cap global hard cap
  * @param _wallet address receiving ether if sale is successful
  **/
  constructor(uint256 _startDate, uint256 _startGeneralSale, uint256 _endDate,
                          uint256 _goal, uint256 _presaleCap, uint256 _cap,
                          address _wallet)
      public
      CappedCrowdsale(_cap)
      FinalizableCrowdsale()
      RefundableCrowdsale(_goal)
      Crowdsale(generalRate, _startDate, _endDate, _wallet)
      ProgressiveIndividualCappedCrowdsale(baseEthCapPerAddress, _startGeneralSale)
  {
      require(_goal <= _cap, "goal is superior to cap");
      require(_startGeneralSale > _startDate, "general sale is starting before presale");
      require(_endDate > _startGeneralSale, "sale ends before general start");
      require(_presaleCap > 0, "presale cap is inferior or equal to 0");
      require(_presaleCap <= _cap, "presale cap is superior to sale cap");

      startGeneralSale = _startGeneralSale;
      presaleCap = _presaleCap;
      dateOfBonusRelease = endTime.add(presaleBonusLock);
  }

  /**
  * @dev Creates the talao token.
  * @return the TalaoToken address
  **/
  function createTokenContract()
      internal
      returns (MintableToken)
  {
      return new TalaoToken();
  }

  /**
  * @dev Checks if the sender is whitelisted for the presale.
  **/
  modifier onlyPresaleWhitelisted()
  {
      require(isWhitelistedPresale(msg.sender), "address is not whitelisted for presale");
      _;
  }

  /**
  * @dev Checks if the sender is whitelisted for the crowdsale.
  **/
  modifier onlyWhitelisted()
  {
      require(isWhitelisted(msg.sender) || isWhitelistedPresale(msg.sender),
              "address is not whitelisted for sale");
      _;
  }

  /**
   * @dev Whitelists an array of users for the crowdsale.
   * @param _users the users to be whitelisted
   */
  function whitelistAddresses(address[] _users)
      public
      onlyOwner
  {
      for(uint i = 0 ; i < _users.length ; i++) {
        whiteListedAddress[_users[i]] = true;
      }
  }

  /**
   * @dev Removes a user from the crowdsale whitelist.
   * @param _user the user to be removed from the crowdsale whitelist
   */
  function unwhitelistAddress(address _user)
      public
      onlyOwner
  {
      whiteListedAddress[_user] = false;
  }

  /**
   * @dev Whitelists a user for the presale with an individual cap ; cap needs to be above participation if set again
   * @param _user the users to be whitelisted
   * @param _cap the user individual cap in wei
   */
  function whitelistAddressPresale(address _user, uint _cap)
      public
      onlyOwner
  {
      require(_cap > presaleParticipation[_user], "address has reached participation cap");
      whiteListedAddressPresale[_user] = true;
      presaleIndividualCap[_user] = _cap;
  }

  /**
   * @dev Removes a user from the presale whitelist.
   * @param _user the user to be removed from the presale whitelist
   */
  function unwhitelistAddressPresale(address _user)
      public
      onlyOwner
  {
      whiteListedAddressPresale[_user] = false;
  }

  /**
   * @dev Mints tokens corresponding to the transaction value for a whitelisted user during the crowdsale.
   * @param beneficiary the user wanting to buy tokens
   */
  function buyTokens(address beneficiary)
      public
      payable
      onlyWhitelisted
  {
      require(beneficiary != 0x0, "beneficiary cannot be 0x0");
      require(validPurchase(), "purchase is not valid");

      uint256 weiAmount = msg.value;
      uint256 tokens = weiAmount.mul(generalRate);
      weiRaised = weiRaised.add(weiAmount);

      token.mint(beneficiary, tokens);
      emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
      forwardFunds();
  }

  /**
   * @dev Mints tokens corresponding to the transaction value for a whitelisted user during the presale.
   *      Presale bonus is timelocked.
   * @param beneficiary the user wanting to buy tokens
   */
  function buyTokensPresale(address beneficiary)
      public
      payable
      onlyPresaleWhitelisted
  {
      require(beneficiary != 0x0, "beneficiary cannot be 0x0");
      require(validPurchasePresale(), "presale purchase is not valid");

      // minting tokens at general rate because these tokens are not timelocked
      uint256 weiAmount = msg.value;
      uint256 tokens = weiAmount.mul(generalRate);

      // checking if a timelock contract has been already created (not the first presale investment)
      // creating a timelock contract if none exists
      if(timelockedTokensContracts[beneficiary] == 0) {
        timelockedTokensContracts[beneficiary] = new TokenTimelock(token, beneficiary, dateOfBonusRelease);
      }

      // minting timelocked tokens ; balance goes to the timelock contract
      uint256 timelockedTokens = preSaleBonus(weiAmount);
      weiRaisedPreSale = weiRaisedPreSale.add(weiAmount);

      token.mint(beneficiary, tokens);
      token.mint(timelockedTokensContracts[beneficiary], timelockedTokens);
      emit TokenPurchase(msg.sender, beneficiary, weiAmount, (tokens.add(timelockedTokens)));
      forwardFunds();
  }

  /**
   * @dev Overriding the finalization method to add minting for founders/team/reserve if soft cap is reached.
   *      Also deploying the marketplace and transferring ownership to the crowdsale owner.
   */
  function finalization()
      internal
  {
      if (goalReached()) {
        // advisors tokens : 3M ; 1 year cliff, vested for another year
        timelockedTokensContracts[advisorsWallet] = new TokenVesting(advisorsWallet, now, cliffAdvisorsTokens, lockAdvisorsTokens, false);

        // Vesting for founders ; not revocable ; 1 year cliff, vested for another year
        timelockedTokensContracts[foundersWallet1] = new TokenVesting(foundersWallet1, now, cliffTeamTokensRelease, lockTeamTokens, false);
        timelockedTokensContracts[foundersWallet2] = new TokenVesting(foundersWallet2, now, cliffTeamTokensRelease, lockTeamTokens, false);
        timelockedTokensContracts[foundersWallet3] = new TokenVesting(foundersWallet3, now, cliffTeamTokensRelease, lockTeamTokens, false);

        // mint remaining tokens out of 150M to be timelocked 1 year for future round(s)
        uint dateOfFutureRoundRelease = now.add(futureRoundTokensRelease);
        timelockedTokensContracts[futureRoundWallet] = new TokenTimelock(token, futureRoundWallet, dateOfFutureRoundRelease);

        token.mint(timelockedTokensContracts[advisorsWallet], 3000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet1], 4000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet2], 4000000000000000000000000);
        token.mint(timelockedTokensContracts[foundersWallet3], 4000000000000000000000000);

        // talao shareholders & employees
        token.mint(shareholdersWallet, 6000000000000000000000000);
        // tokens reserve for talent ambassador, bounty and cash reserve : 29M tokens ; no timelock
        token.mint(reserveWallet, 29000000000000000000000000);

        uint256 totalSupply = token.totalSupply();
        uint256 maxSupply = 150000000000000000000000000;
        uint256 toMint = maxSupply.sub(totalSupply);
        token.mint(timelockedTokensContracts[futureRoundWallet], toMint);
        token.finishMinting();
        // deploy the marketplace
        TalaoToken talao = TalaoToken(address(token));
        TalaoMarketplace marketplace = new TalaoMarketplace(address(token));
        talao.setMarketplace(address(marketplace));
        marketplace.transferOwnership(owner);

        // give the token ownership to the crowdsale owner for vault purposes
        token.transferOwnership(owner);
      }
      // if soft cap not reached ; vault opens for refunds
      super.finalization();
  }

  /**
  * @dev Fallback function redirecting to buying tokens functions depending on the time period.
  **/
  function ()
      external
      payable
  {
      if (now >= startTime && now < startGeneralSale){
        buyTokensPresale(msg.sender);
      } else {
        buyTokens(msg.sender);
      }
  }

  /**
  * @dev Checks if the crowdsale purchase is valid: correct time, value and hard cap not reached.
  *      Calls ProgressiveIndividualCappedCrowdsale&#39;s validPurchase to get individual cap.
  * @return true if all criterias are satisfied ; false otherwise
  **/
  function validPurchase()
      internal
      returns (bool)
  {
      bool withinPeriod = now >= startGeneralSale && now <= endTime;
      bool nonZeroPurchase = msg.value != 0;
      uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
      bool withinCap = totalWeiRaised.add(msg.value) <= cap;
      return withinCap && withinPeriod && nonZeroPurchase && super.validPurchase();
  }

  /**
  * @dev Checks if the presale purchase is valid: correct time, value and presale hard cap not reached.
  * @return true if all criterias are satisfied ; false otherwise
  **/
  function validPurchasePresale()
      internal
      returns (bool)
  {
      presaleParticipation[msg.sender] = presaleParticipation[msg.sender].add(msg.value);
      bool enough = presaleParticipation[msg.sender] >= presaleParticipationMinimum;
      bool notTooMuch = presaleIndividualCap[msg.sender] >= presaleParticipation[msg.sender];
      bool withinPeriod = now >= startTime && now < startGeneralSale;
      bool nonZeroPurchase = msg.value != 0;
      bool withinCap = weiRaisedPreSale.add(msg.value) <= presaleCap;
      return withinPeriod && nonZeroPurchase && withinCap && enough && notTooMuch;
  }

  function preSaleBonus(uint amount)
      internal
      returns (uint)
  {
      if(now < dateTier2) {
        return amount.mul(presaleBonus);
      } else if (now < dateTier3) {
        return amount.mul(presaleBonusTier2);
      } else if (now < dateTier4) {
        return amount.mul(presaleBonusTier3);
      } else {
        return amount.mul(presaleBonusTier4);
      }
  }

  /**
  * @dev Override of the goalReached function in order to add presale weis to crowdsale weis and check if the total amount has reached the soft cap.
  * @return true if soft cap has been reached ; false otherwise
  **/
  function goalReached()
      public
      constant
      returns (bool)
  {
      uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
      return totalWeiRaised >= goal || super.goalReached();
  }

  /**
  * @dev Check if the user is whitelisted for the crowdsale.
  * @return true if user is whitelisted ; false otherwise
  **/
  function isWhitelisted(address _user)
      public
      constant
      returns (bool)
  {
      return whiteListedAddress[_user];
  }

  /**
  * @dev Check if the user is whitelisted for the presale.
  * @return true if user is whitelisted ; false otherwise
  **/
  function isWhitelistedPresale(address _user)
      public
      constant
      returns (bool)
  {
      return whiteListedAddressPresale[_user];
  }

}