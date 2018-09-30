pragma solidity ^0.4.24;

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20Interface public token;

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
  constructor(uint256 _rate, address _wallet, ERC20Interface _token) public {
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
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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

contract ERC20Interface {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Standard is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) external returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
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
   * 
   * To avoid this issue, allowances are only allowed to be changed between zero and non-zero.
   *
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) external returns (bool) {
    require(allowed[msg.sender][_spender] == 0 || _value == 0);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() external view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) external view returns (uint256) {
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
  function increaseApproval(address _spender, uint _addedValue) external returns (bool) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool) {
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

contract ERC223Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value, bytes data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract ERC223Standard is ERC223Interface, ERC20Standard {
    using SafeMath for uint256;

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint256 _value, bytes _data) external returns(bool){
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint256 codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        emit Transfer(msg.sender, _to, _value);
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn&#39;t contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint256 _value) external returns(bool){
        uint256 codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MintableToken is ERC223Standard, Ownable {
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

contract PoolAndSaleInterface {
    address public tokenSaleAddr;
    address public votingAddr;
    address public votingTokenAddr;
    uint256 public tap;
    uint256 public initialTap;
    uint256 public initialRelease;

    function setTokenSaleContract(address _tokenSaleAddr) external;
    function startProject() external;
}

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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TimeLockPool{
    using SafeMath for uint256;

    struct LockedBalance {
      uint256 balance;
      uint256 releaseTime;
    }

    /*
      structure: lockedBalnces[owner][token] = LockedBalance(balance, releaseTime);
      token address = &#39;0x0&#39; stands for ETH (unit = wei)
    */
    mapping (address => mapping (address => LockedBalance[])) public lockedBalances;

    event Deposit(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount,
        uint256 releaseTime
    );

    event Withdraw(
        address indexed owner,
        address indexed tokenAddr,
        uint256 amount
    );

    /// @dev Constructor. 
    /// @return 
    constructor() public {}

    /// @dev Deposit tokens to specific account with time-lock.
    /// @param tokenAddr The contract address of a ERC20/ERC223 token.
    /// @param account The owner of deposited tokens.
    /// @param amount Amount to deposit.
    /// @param releaseTime Time-lock period.
    /// @return True if it is successful, revert otherwise.
    function depositERC20 (
        address tokenAddr,
        address account,
        uint256 amount,
        uint256 releaseTime
    ) external returns (bool) {
        require(account != address(0x0));
        require(tokenAddr != 0x0);
        require(msg.value == 0);
        require(amount > 0);
        require(ERC20Interface(tokenAddr).transferFrom(msg.sender, this, amount));

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

    /// @dev Deposit ETH to specific account with time-lock.
    /// @param account The owner of deposited tokens.
    /// @param releaseTime Timestamp to release the fund.
    /// @return True if it is successful, revert otherwise.
    function depositETH (
        address account,
        uint256 releaseTime
    ) external payable returns (bool) {
        require(account != address(0x0));
        address tokenAddr = address(0x0);
        uint256 amount = msg.value;
        require(amount > 0);

        lockedBalances[account][tokenAddr].push(LockedBalance(amount, releaseTime));
        emit Deposit(account, tokenAddr, amount, releaseTime);

        return true;
    }

    /// @dev Release the available balance of an account.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @param index_from Starting index of records to withdraw.
    /// @param index_to Ending index of records to withdraw.
    /// @return True if it is successful, revert otherwise.
    function withdraw (address account, address tokenAddr, uint256 index_from, uint256 index_to) external returns (bool) {
        require(account != address(0x0));

        uint256 release_amount = 0;
        for (uint256 i = index_from; i < lockedBalances[account][tokenAddr].length && i < index_to + 1; i++) {
            if (lockedBalances[account][tokenAddr][i].balance > 0 &&
                lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {

                release_amount = release_amount.add(lockedBalances[account][tokenAddr][i].balance);
                lockedBalances[account][tokenAddr][i].balance = 0;
            }
        }

        require(release_amount > 0);

        if (tokenAddr == 0x0) {
            if (!account.send(release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        } else {
            if (!ERC20Interface(tokenAddr).transfer(account, release_amount)) {
                revert();
            }
            emit Withdraw(account, tokenAddr, release_amount);
            return true;
        }
    }

    /// @dev Returns total amount of balances which already passed release time.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Available balance of specified token.
    function getAvailableBalanceOf (address account, address tokenAddr) 
        external
        view
        returns (uint256)
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime <= block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

    /// @dev Returns total amount of balances which are still locked.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Locked balance of specified token.
    function getLockedBalanceOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 balance = 0;
        for(uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if(lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp) {
                balance = balance.add(lockedBalances[account][tokenAddr][i].balance);
            }
        }
        return balance;
    }

    /// @dev Returns next release time of locked balances.
    /// @param account An account to receive tokens.
    /// @param tokenAddr An address of ERC20/ERC223 token.
    /// @return Timestamp of next release.
    function getNextReleaseTimeOf (address account, address tokenAddr)
        external
        view
        returns (uint256) 
    {
        require(account != address(0x0));

        uint256 nextRelease = 2**256 - 1;
        for (uint256 i = 0; i < lockedBalances[account][tokenAddr].length; i++) {
            if (lockedBalances[account][tokenAddr][i].releaseTime > block.timestamp &&
               lockedBalances[account][tokenAddr][i].releaseTime < nextRelease) {

                nextRelease = lockedBalances[account][tokenAddr][i].releaseTime;
            }
        }

        /* returns 0 if there are no more locked balances. */
        if (nextRelease == 2**256 - 1) {
            nextRelease = 0;
        }
        return nextRelease;
    }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
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

contract TokenController is Ownable {
    using SafeMath for uint256;

    MintableToken public targetToken;
    address public votingAddr;
    address public tokensaleManagerAddr;

    State public state;

    enum State {
        Init,
        Tokensale,
        Public
    }

    /// @dev The deployer must change the ownership of the target token to this contract.
    /// @param _targetToken : The target token this contract manage the rights to mint.
    /// @return 
    constructor (
        MintableToken _targetToken
    ) public {
        targetToken = MintableToken(_targetToken);
        state = State.Init;
    }

    /// @dev Mint and distribute specified amount of tokens to an address.
    /// @param to An address that receive the minted tokens.
    /// @param amount Amount to mint.
    /// @return True if the distribution is successful, revert otherwise.
    function mint (address to, uint256 amount) external returns (bool) {
        /*
          being called from voting contract will be available in the future
          ex. if (state == State.Public && msg.sender == votingAddr) 
        */

        if ((state == State.Init && msg.sender == owner) ||
            (state == State.Tokensale && msg.sender == tokensaleManagerAddr)) {
            return targetToken.mint(to, amount);
        }

        revert();
    }

    /// @dev Change the phase from "Init" to "Tokensale".
    /// @param _tokensaleManagerAddr A contract address of token-sale.
    /// @return True if the change of the phase is successful, revert otherwise.
    function openTokensale (address _tokensaleManagerAddr)
        external
        onlyOwner
        returns (bool)
    {
        /* check if the owner of the target token is set to this contract */
        require(MintableToken(targetToken).owner() == address(this));
        require(state == State.Init);
        require(_tokensaleManagerAddr != address(0x0));

        tokensaleManagerAddr = _tokensaleManagerAddr;
        state = State.Tokensale;
        return true;
    }

    /// @dev Change the phase from "Tokensale" to "Public". This function will be
    ///      cahnged in the future to receive an address of voting contract as an
    ///      argument in order to handle the result of minting proposal.
    /// @return True if the change of the phase is successful, revert otherwise.
    function closeTokensale () external returns (bool) {
        require(state == State.Tokensale && msg.sender == tokensaleManagerAddr);

        state = State.Public;
        return true;
    }

    /// @dev Check if the state is "Init" or not.
    /// @return True if the state is "Init", false otherwise.
    function isStateInit () external view returns (bool) {
        return (state == State.Init);
    }

    /// @dev Check if the state is "Tokensale" or not.
    /// @return True if the state is "Tokensale", false otherwise.
    function isStateTokensale () external view returns (bool) {
        return (state == State.Tokensale);
    }

    /// @dev Check if the state is "Public" or not.
    /// @return True if the state is "Public", false otherwise.
    function isStatePublic () external view returns (bool) {
        return (state == State.Public);
    }
}

contract TokenSaleManager is Ownable {
    using SafeMath for uint256;

    ERC20Interface public token;
    address public poolAddr;
    address public tokenControllerAddr;
    address public timeLockPoolAddr;
    address[] public tokenSales;
    mapping( address => bool ) public tokenSaleIndex;
    bool public isStarted = false;
    bool public isFinalized = false;

    modifier onlyDaicoPool {
        require(msg.sender == poolAddr);
        _;
    }

    modifier onlyTokenSale {
        require(tokenSaleIndex[msg.sender]);
        _;
    }

    /// @dev Constructor. It set the DaicoPool to receive the starting signal from this contract.
    /// @param _tokenControllerAddr The contract address of TokenController.
    /// @param _timeLockPoolAddr The contract address of a TimeLockPool.
    /// @param _daicoPoolAddr The contract address of DaicoPool.
    /// @param _token The contract address of a ERC20 token.
    constructor (
        address _tokenControllerAddr,
        address _timeLockPoolAddr,
        address _daicoPoolAddr,
        ERC20Interface _token
    ) public {
        require(_tokenControllerAddr != address(0x0));
        tokenControllerAddr = _tokenControllerAddr;

        require(_timeLockPoolAddr != address(0x0));
        timeLockPoolAddr = _timeLockPoolAddr;

        token = _token;

        poolAddr = _daicoPoolAddr;
        require(PoolAndSaleInterface(poolAddr).votingTokenAddr() == address(token));
        PoolAndSaleInterface(poolAddr).setTokenSaleContract(this);

    }

    /// @dev This contract doen&#39;t receive any ETH.
    function() external payable {
        revert();
    }

    /// @dev Add a new token sale with specific parameters. New sale should start
    /// @dev after the previous one closed.
    /// @param openingTime A timestamp of the date this sale will start.
    /// @param closingTime A timestamp of the date this sale will end.
    /// @param tokensCap Number of tokens to be sold. Can be 0 if it accepts carryover.
    /// @param rate Number of tokens issued with 1 ETH. [minimal unit of the token / ETH]  
    /// @param carryover If true, unsold tokens will be carryovered to next sale. 
    /// @param timeLockRate Specified rate of issued tokens will be locked. ex. 50 = 50%
    /// @param timeLockEnd A timestamp of the date locked tokens will be released.
    /// @param minAcceptableWei Minimum contribution.
    function addTokenSale (
        uint256 openingTime,
        uint256 closingTime,
        uint256 tokensCap,
        uint256 rate,
        bool carryover,
        uint256 timeLockRate,
        uint256 timeLockEnd,
        uint256 minAcceptableWei
    ) external onlyOwner {
        require(!isStarted);
        require(
            tokenSales.length == 0 ||
            TimedCrowdsale(tokenSales[tokenSales.length-1]).closingTime() < openingTime
        );

        require(TokenController(tokenControllerAddr).state() == TokenController.State.Init);

        tokenSales.push(new TokenSale(
            rate,
            token,
            poolAddr,
            openingTime,
            closingTime,
            tokensCap,
            timeLockRate,
            timeLockEnd,
            carryover,
            minAcceptableWei
        ));
        tokenSaleIndex[tokenSales[tokenSales.length-1]] = true;

    }

    /// @dev Initialize the tokensales. No other sales can be added after initialization.
    /// @return True if successful, revert otherwise.
    function initialize () external onlyOwner returns (bool) {
        require(!isStarted);
        TokenSale(tokenSales[0]).initialize(0);
        isStarted = true;
    }

    /// @dev Request TokenController to mint new tokens. This function is only called by 
    /// @dev token sales.
    /// @param _beneficiary The address to receive the new tokens.
    /// @param _tokenAmount Token amount to be minted.
    /// @return True if successful, revert otherwise.
    function mint (
        address _beneficiary,
        uint256 _tokenAmount
    ) external onlyTokenSale returns(bool) {
        require(isStarted && !isFinalized);
        require(TokenController(tokenControllerAddr).mint(_beneficiary, _tokenAmount));
        return true;
    }

    /// @dev Mint new tokens with time-lock. This function is only called by token sales.
    /// @param _beneficiary The address to receive the new tokens.
    /// @param _tokenAmount Token amount to be minted.
    /// @param _releaseTime A timestamp of the date locked tokens will be released.
    /// @return True if successful, revert otherwise.
    function mintTimeLocked (
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _releaseTime
    ) external onlyTokenSale returns(bool) {
        require(isStarted && !isFinalized);
        require(TokenController(tokenControllerAddr).mint(this, _tokenAmount));
        require(ERC20Interface(token).approve(timeLockPoolAddr, _tokenAmount));
        require(TimeLockPool(timeLockPoolAddr).depositERC20(
            token,
            _beneficiary,
            _tokenAmount,
            _releaseTime
        ));
        return true;
    }

    /// @dev Adds single address to whitelist of all token sales.
    /// @param _beneficiary Address to be added to the whitelist
    function addToWhitelist(address _beneficiary) external onlyOwner {
        require(isStarted);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            WhitelistedCrowdsale(tokenSales[i]).addToWhitelist(_beneficiary);
        }
    }

    /// @dev Adds multiple addresses to whitelist of all token sales.
    /// @param _beneficiaries Addresses to be added to the whitelist
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        require(isStarted);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            WhitelistedCrowdsale(tokenSales[i]).addManyToWhitelist(_beneficiaries);
        }
    }


    /// @dev Finalize the specific token sale. Can be done if end date has come or 
    /// @dev all tokens has been sold out. It process carryover if it is set.
    /// @param _indexTokenSale index of the target token sale. 
    function finalize (uint256 _indexTokenSale) external {
        require(isStarted && !isFinalized);
        TokenSale ts = TokenSale(tokenSales[_indexTokenSale]);

        if (ts.canFinalize()) {
            ts.finalize();
            uint256 carryoverAmount = 0;
            if (ts.carryover() &&
                ts.tokensCap() > ts.tokensMinted() &&
                _indexTokenSale.add(1) < tokenSales.length) {
                carryoverAmount = ts.tokensCap().sub(ts.tokensMinted());
            } 
            if(_indexTokenSale.add(1) < tokenSales.length) {
                TokenSale(tokenSales[_indexTokenSale.add(1)]).initialize(carryoverAmount);
            }
        }

    }

    /// @dev Finalize the manager. Can be done if all token sales are already finalized.
    /// @dev It makes the DaicoPool open the TAP.
    function finalizeTokenSaleManager () external{
        require(isStarted && !isFinalized);
        for (uint256 i = 0; i < tokenSales.length; i++ ) {
            require(FinalizableCrowdsale(tokenSales[i]).isFinalized());
        }
        require(TokenController(tokenControllerAddr).closeTokensale());
        isFinalized = true;
        PoolAndSaleInterface(poolAddr).startProject();
    }
}

contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract TokenSale is FinalizableCrowdsale,
                      WhitelistedCrowdsale {
    using SafeMath for uint256;

    address public managerAddr; 
    address public poolAddr;
    bool public isInitialized = false;
    uint256 public timeLockRate;
    uint256 public timeLockEnd;
    uint256 public tokensMinted = 0;
    uint256 public tokensCap;
    uint256 public minAcceptableWei;
    bool public carryover;

    modifier onlyManager{
        require(msg.sender == managerAddr);
        _;
    }

    /// @dev Constructor.
    /// @param _rate Number of tokens issued with 1 ETH. [minimal unit of the token / ETH]
    /// @param _token The contract address of a ERC20 token.
    /// @param _poolAddr The contract address of DaicoPool.
    /// @param _openingTime A timestamp of the date this sale will start.
    /// @param _closingTime A timestamp of the date this sale will end.
    /// @param _tokensCap Number of tokens to be sold. Can be 0 if it accepts carryover.
    /// @param _timeLockRate Specified rate of issued tokens will be locked. ex. 50 = 50%
    /// @param _timeLockEnd A timestamp of the date locked tokens will be released.
    /// @param _carryover If true, unsold tokens will be carryovered to next sale. 
    /// @param _minAcceptableWei Minimum contribution.
    /// @return 
    constructor (
        uint256 _rate, /* The unit of rate is [nano tokens / ETH] in this contract */
        ERC20Interface _token,
        address _poolAddr,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _tokensCap,
        uint256 _timeLockRate,
        uint256 _timeLockEnd,
        bool _carryover,
        uint256 _minAcceptableWei
    ) public Crowdsale(_rate, _poolAddr, _token) TimedCrowdsale(_openingTime, _closingTime) {
        require(_timeLockRate >= 0 && _timeLockRate <=100);
        require(_poolAddr != address(0x0));

        managerAddr = msg.sender;
        poolAddr = _poolAddr;
        timeLockRate = _timeLockRate;
        timeLockEnd = _timeLockEnd;
        tokensCap = _tokensCap;
        carryover = _carryover;
        minAcceptableWei = _minAcceptableWei;
    }

    /// @dev Initialize the sale. If carryoverAmount is given, it added the tokens to be sold.
    /// @param carryoverAmount Amount of tokens to be added to capTokens.
    /// @return 
    function initialize(uint256 carryoverAmount) external onlyManager {
        require(!isInitialized);
        isInitialized = true;
        tokensCap = tokensCap.add(carryoverAmount);
    }

    /// @dev Finalize the sale. It transfers all the funds it has. Can be repeated.
    /// @return 
    function finalize() onlyOwner public {
        //require(!isFinalized);
        require(isInitialized);
        require(canFinalize());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /// @dev Check if the sale can be finalized.
    /// @return True if closing time has come or tokens are sold out.
    function canFinalize() public view returns(bool) {
        return (hasClosed() || (isInitialized && tokensCap <= tokensMinted));
    }


    /// @dev It transfers all the funds it has.
    /// @return 
    function finalization() internal {
        if(address(this).balance > 0){
            poolAddr.transfer(address(this).balance);
        }
    }

    /**
     * @dev Overrides delivery by minting tokens upon purchase.
     * @param _beneficiary Token purchaser
     * @param _tokenAmount Number of tokens to be minted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        //require(tokensMinted.add(_tokenAmount) <= tokensCap);
        require(tokensMinted < tokensCap);

        uint256 time_locked = _tokenAmount.mul(timeLockRate).div(100); 
        uint256 instant = _tokenAmount.sub(time_locked);

        if (instant > 0) {
            require(TokenSaleManager(managerAddr).mint(_beneficiary, instant));
        }
        if (time_locked > 0) {
            require(TokenSaleManager(managerAddr).mintTimeLocked(
                _beneficiary,
                time_locked,
                timeLockEnd
            ));
        }
  
        tokensMinted = tokensMinted.add(_tokenAmount);
    }

    /// @dev Overrides _forwardFunds to do nothing. 
    function _forwardFunds() internal {}

    /// @dev Overrides _preValidatePurchase to check minimam contribution and initialization.
    /// @param _beneficiary Token purchaser
    /// @param _weiAmount weiAmount to pay
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(isInitialized);
        require(_weiAmount >= minAcceptableWei);
    }

    /**
     * @dev Overridden in order to change the unit of rate with [nano toekns / ETH]
     * instead of original [minimal unit of the token / wei].
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
      return _weiAmount.mul(rate).div(10**18); //The unit of rate is [nano tokens / ETH].
    }

}