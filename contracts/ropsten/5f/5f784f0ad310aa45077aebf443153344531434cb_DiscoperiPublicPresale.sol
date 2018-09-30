pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require(token.approve(spender, value));
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;


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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title TokenLockup
 * @dev This contract gives possibility for token holders to have locked up (till release time) amounts of tokens on their balances. 
 */
contract TokenLockup {
    using SafeMath for uint256;  

    // LockedUp struct
    struct LockedUp {
        uint256 amount; // lockedup amount
        uint256 release; // release timestamp
    }

    // list of lockedup amounts and release timestamps
    mapping (address => LockedUp[]) public lockedup;

    // lockup event logging
    event Lockup(address indexed to, uint256 amount, uint256 release);

    /**
     * @dev Get the lockedup list count
     * @param _who address Address owns lockedup list
     * @return uint256 Lockedup list count     
     */
    function lockedUpCount(address _who) public view returns (uint256) {
        return lockedup[_who].length;
    }

    /**
     * @dev Find out if the address has locked up amounts
     * @param _who address Address checked for lockedup amounts
     * @return bool Returns true if address has lockedup amounts     
     */    
    function hasLockedUp(address _who) public view returns (bool) {
        return lockedup[_who].length > 0;
    }    

    /**
     * @dev Get balance locked up to the current moment of time
     * @param _who address Address owns lockedup amounts
     * @return uint256 Balance locked up to the current moment of time     
     */       
    function balanceLockedUp(address _who) public view returns (uint256) {
        uint256 _balanceLokedUp = 0;
        for (uint256 i = 0; i < lockedup[_who].length; i++) {
            if (lockedup[_who][i].release > block.timestamp) // solium-disable-line security/no-block-members
                _balanceLokedUp = _balanceLokedUp.add(lockedup[_who][i].amount);
        }
        return _balanceLokedUp;
    }    

    /**
     * @dev Lockup amount till release time
     * @param _who address Address gets the lockedup amount
     * @param _amount uint256 Amount to lockup
     * @param _release uint256 Release timestamp     
     */     
    function _lockup(address _who, uint256 _amount, uint256 _release) internal {
        if (_release > 0) {
            require(_who != address(0), "Lockup target address can&#39;t be zero.");
            require(_amount > 0, "Lockup amount should be > 0.");   
            require(_release > block.timestamp, "Lockup release time should be > now."); // solium-disable-line security/no-block-members 
            lockedup[_who].push(LockedUp(_amount, _release));
            emit Lockup(_who, _amount, _release);
        }            
    }      
}

/**
 * @title DiscoperiToken
 * @dev Discoperi Token contract. Initial supply of tokens is generated during deployment.
 * Tokens for sale are generated during sales. Contract uses lockup mixin.
 */
contract DiscoperiToken is ERC20, Ownable, TokenLockup {
    using SafeMath for uint256;

    // token constants
    string public constant name = "Discoperi Token"; // solium-disable-line uppercase
    string public constant symbol = "DISC"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    // total tokens supply
    uint256 public constant TOTAL_SUPPLY = 200000000000 * (10 ** uint256(decimals)); // 200,000,000,000 DISC

    // TOTAL_SUPPLY is distributed as follows
    uint256 public constant SALES_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISC - 25%
    uint256 public constant MARKET_DEV_SUPPLY = 50000000000 * (10 ** uint256(decimals)); // 50,000,000,000 DISC - 25%
    uint256 public constant TEAM_SUPPLY = 30000000000 * (10 ** uint256(decimals)); // 30,000,000,000 DISC - 15%
    uint256 public constant RESERVE_SUPPLY = 30000000000 * (10 ** uint256(decimals)); // 30,000,000,000 DISC - 15%
    uint256 public constant INVESTORS_ADVISORS_SUPPLY = 20000000000 * (10 ** uint256(decimals)); // 20,000,000,000 DISC - 10%
    uint256 public constant PR_ADVERSTISING_SUPPLY = 20000000000 * (10 ** uint256(decimals)); // 20,000,000,000 DISC - 10%
    
    // funds wallets
    address public constant MARKET_DEV_ADDRESS = 0x0;
    address public constant TEAM_ADDRESS = 0x0;
    address public constant RESERVE_ADDRESS = 0x0;
    address public constant INVESTORS_ADDRESS= 0x0;
    address public constant PR_ADVERSTISING_ADDRESS = 0x0;

    // HARD CAPS (listed here for demonstration purpose)
    uint256 public constant SEED_FUNDING_HARD_CAP = 1550000; // 1,550,000 USD
    uint256 public constant PRIVATE_PRESALE_HARD_CAP = 40000000; // 40,000,000 USD
    uint256 public constant PUBLIC_PRESALE_HARD_CAP = 40000000; // 40,000,000 USD
    uint256 public constant PUBLIC_SALE_HARD_CAP = 50000000; // 50,000,000 USD

    // private pre-sale address
    address public privatePresale;

    // public pre-sale address
    address public publicPresale;

    // public sale address
    address public publicSale;

    // tokens distributed during sales
    uint256 public saleDitributed;

    
    // restrict execution for sale contracts addresses
    modifier onlySaleContract() {
        require(isSaleContract(msg.sender), "Unauthorized attempt");
        _;
    }

    // check balance spot on transfer
    modifier spotTransfer(address _from, uint256 _value) {
        require(_value <= balanceSpot(_from), "Attempt to transfer more than balance spot");
        _;
    }

    /**
     * CONSTRUCTOR
     * @dev Allocate initial token supply
     */
    constructor() {
        // _allocate(MARKET_DEV_ADDRESS, MARKET_DEV_SUPPLY, uint(0));
        // // TODO SET CORRECT
        // _allocate(TEAM_ADDRESS, TEAM_SUPPLY, now.add(1 years)); // solium-disable-line security/no-block-members 
        // _allocate(RESERVE_ADDRESS, RESERVE_SUPPLY, uint(0));
        // _allocate(INVESTORS_ADDRESS, INVESTORS_ADVISORS_SUPPLY, uint(0)); 
        // _allocate(PR_ADVERSTISING_ADDRESS, PR_ADVERSTISING_SUPPLY, uint(0));
    }

    /**
     * @dev Allocate tokens during sales, amount can be locked up
     * @param _to address gets the tokens
     * @param _amount Amount to allocate
     * @param _releaseTime Tokens release timestamp (can be zero to omit locking up) 
     */ 
    function allocatePurchase(address _to, uint256 _amount, uint256 _releaseTime) external onlySaleContract {
        require(saleDitributed < SALES_SUPPLY, "Can&#39;t allocate more than SALES SUPPLY.");

        uint256 _amountToAllocate = _amount;
        if (saleDitributed.add(_amountToAllocate) > SALES_SUPPLY)
            _amountToAllocate = SALES_SUPPLY.sub(saleDitributed); 
        saleDitributed = saleDitributed.add(_amountToAllocate);
    
        _allocate(_to, _amountToAllocate, _releaseTime);
    }  

    /**
     * @dev Set Discoperi sale contracts addresses
     * @param _privatePresale address of the Discoperi private pre-sale contract
     * @param _publicPresale address of the Discoperi public pre-sale contract
     * @param _publicSale address of the Discoperi public sale contract
     */  
    function setSaleContracts(address _privatePresale, address _publicPresale, address _publicSale) external onlyOwner {
        require(_privatePresale != address(0), "Private pre-sale address should not be equal to zero address");
        require(_publicPresale != address(0), "Public Pre-sale address should not be equal to zero address");
        require(_publicSale != address(0), "ICO address should not be equal to zero address");

        require(privatePresale == address(0) && publicPresale == address(0) && publicSale == address(0), ""); // todo com

        privatePresale = _privatePresale;
        publicPresale = _publicPresale;
        publicSale = _publicSale;
    }

    /**
     * @dev Get balance spot for the current moment of time
     * @param _who address owns balance spot
     * @return balance spot for the current moment of time     
     */   
    function balanceSpot(address _who) public view returns (uint256) {
        uint256 _balanceSpot = balanceOf(_who);
        _balanceSpot = _balanceSpot.sub(balanceLockedUp(_who));      
        return _balanceSpot;
    }     
       
    /**
     * @dev Transfer tokens from one address to another
     * @param _to t address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transfer(address _to, uint256 _value) public spotTransfer(msg.sender, _value) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from the address which you want to send tokens from
     * @param _to the address which you want to transfer to
     * @param _value the amount of tokens to be transferred
     * @return true if the transfer was succeeded
     */
    function transferFrom(address _from, address _to, uint256 _value) public spotTransfer(_from, _value) returns (bool) {    
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev  Check if caller is sale contract
     * @return bool Returns true if caller is sale contract
     */
    function isSaleContract(address _contract) public view returns (bool) {
        if (_contract == publicSale || _contract == publicPresale || _contract == privatePresale)
            return true;
        return false;
    }

    /**
     * @dev Allocate tokens, amount can be locked up
     * @param _to who gets the tokens
     * @param _amount amount to allocate
     * @param _releaseTime tokens release timestamp (can be zero to omit locking up) 
     */ 
    function _allocate(address _to, uint256 _amount, uint256 _releaseTime) internal {
        require(_to != address(0), "Allocate destination address can&#39;t be zero");
        require(_amount > 0, "Allocate amount should be > 0.");

        _mint(_to, _amount);

        if (_releaseTime != uint256(0)) {
            _lockup(_to, _amount, _releaseTime);
        }
    }  
}

/**
 * @title DiscoperiMultiCollector
 * @dev DiscoperiMultiCollector is a ..
 */
contract DiscoperiMultiCollector is Ownable {
    using SafeMath for uint256;

     // Collectors count
    uint256 public constant COLLECTORS_COUNT = 7;

    // Collectors IDs
    uint256 public constant ETH_COLLECTOR = 0;
    uint256 public constant BTC_COLLECTOR = 1;
    uint256 public constant BTG_COLLECTOR = 2;
    uint256 public constant BCH_COLLECTOR = 3;
    uint256 public constant LTC_COLLECTOR = 4;
    uint256 public constant ZEC_COLLECTOR = 5;
    uint256 public constant USD_COLLECTOR = 6;

     // Collector struct
    struct Collector {
        bytes3 symbol;
        uint8 decimals;
        string dataSource;
        uint256 gasLimit;
        uint256 rate;
        uint256 rateUpdatedAt;
    }

    // List of collectors
    Collector[COLLECTORS_COUNT] public collectors;

    // Funds raised by collector
    uint256[COLLECTORS_COUNT] public collected;

    // Funds funded by collector by beneficiary
    mapping (address => uint256[COLLECTORS_COUNT]) public spent;

    // min & max delays for updating collector rate
    uint256 private constant MIN_UPDATE_DELAY = 30 minutes;
    uint256 private constant MAX_UPDATE_DELAY = 24 hours;

    // Current delay of rate updating
    uint256 private currentUpdateDelay = 1 hours;

    
    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the сollectors
     */ 
    constructor() public {
          // ETH purchase collector
        collectors[ETH_COLLECTOR] = Collector(
            bytes3("ETH"),
            18,
            "json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_usd",
            600000,
            0,
            0
        );

        // BTC purchase collector
        collectors[BTC_COLLECTOR] = Collector(
            bytes3("BTC"),
            8,
            "json(https://api.coinmarketcap.com/v1/ticker/bitcoin/).0.price_usd",
            400000,
            0,
            0
        );

        // BTG purchase collector
        collectors[BTG_COLLECTOR] = Collector(
            bytes3("BTG"),
            8,
            "json(https://api.coinmarketcap.com/v1/ticker/bitcoin-gold/).0.price_usd",
            400000,
            0,
            0
        );   

        // BCH purchase collector
        collectors[BCH_COLLECTOR] = Collector(
            bytes3("BCH"),
            8,
            "json(https://api.coinmarketcap.com/v1/ticker/bitcoin-cash/).0.price_usd",
            400000,
            0,
            0
        );    

        // LTC purchase collector
        collectors[LTC_COLLECTOR] = Collector(
            bytes3("LTC"),
            8,
            "json(https://api.coinmarketcap.com/v1/ticker/litecoin/).0.price_usd",
            400000,
            0,
            0
        ); 

        // ZEC purchase collector
        collectors[ZEC_COLLECTOR] = Collector(
            bytes3("ZEC"),
            8,
            "json(https://api.coinmarketcap.com/v1/ticker/zcash/).0.price_usd",
            400000,
            0,
            0
        ); 

        // USD purchase collector
        collectors[USD_COLLECTOR] = Collector(
            bytes3("USD"),
            2,
            "",
            0,
            1,
            0
        ); 
    }

    /**
     * @dev Set callback gas limit
     * @param _collector Collector id
     * @param _gasLimit New callback gas limit
     */
    function setCallbackGasLimit(uint256 _collector, uint256 _gasLimit) external onlyOwner {
        require(_collector < COLLECTORS_COUNT, "collector value should be < COLLECTORS_COUNT");
        require(_gasLimit > 0, "gas limit value should be positive");
        
        collectors[_collector].gasLimit = _gasLimit;
    }

    /**
     * @dev Set maximum delay for updating the collectors rate
     * @param _delay new delay value
     */
    function setUpdateDelay(uint256 _delay) external onlyOwner {
        require(_delay >= MIN_UPDATE_DELAY, "delay must be >= 30 minutes");
        require(_delay <= MAX_UPDATE_DELAY, "delay must be <= 24 hours");
        
        currentUpdateDelay = _delay;
    }

    /**
     * @dev Update rate value
     * @param _collector collector id
     * @param _newRate new rate value
     */
    function _updateRate(uint256 _collector, uint256 _newRate) internal {
        collectors[_collector].rate = _newRate;
        collectors[_collector].rateUpdatedAt = now; // solium-disable-line security/no-block-members
    }

    /**
     * @dev Check if rate value for the collector is actual (was updated in the last currentUpdateDelay)
     * @param _collector collector id
     */
    function _isRateActual(uint256 _collector) internal view returns(bool) {
        if (_collector == USD_COLLECTOR) {
            return true;
        }
        uint256 rateWasUpdatedAt = collectors[_collector].rateUpdatedAt;
        return now.sub(rateWasUpdatedAt) < currentUpdateDelay; // solium-disable-line security/no-block-members
    }
}

/**
 * @title DiscoperiEscrow
 * @dev DiscoperiEscrow stores funds from unauthorized investors.
 * By the time an investor receive his accredetation, funds can be withdrawn.
 */
contract DiscoperiEscrow is DiscoperiMultiCollector {
    using SafeMath for uint256;

    // Discoperi token address
    address public token;

    // Users deposits
    mapping(address => uint256[COLLECTORS_COUNT]) deposits;
    
    /**
     * @dev Event for funding order logging
     * @param funder funder who want to obtain tokens
     * @param collector collector
     * @param funds paid funds amount
     */
    event EscrowEvent(address indexed funder, uint256 collector, uint256 funds);

    /**
     * @dev Event for withdraw logging
     * @param funder funder who get a refund
     * @param collector collector
     * @param funds refund funds amount
     */
    event WithdrawEvent(address indexed funder, uint256 collector, uint256 funds);

    /**
     * @dev Event for invest logging
     * @param funder invetor address
     * @param collector collector ID
     * @param funds funds amount
     */
    event InvestEvent(address indexed funder, uint256 collector, uint256 funds);


    // onlySale modifier, restrict execution for sale contracts addresses
    modifier onlySale() {
        require(DiscoperiToken(token).isSaleContract(msg.sender), "not authorized attempt");
        _;
    }


    /**
     * @dev CONSTRUCTOR
     * @param _token address of the DiscoperiToken contract
     */
    constructor(address _token) public {
        token = _token;
    }

    /**
     * @dev Fallback function
     */
    function() public {
        revert("fallback function doesn&#39;t accept ether");
    }

    /**
     * @dev check if address has deposits
     * @param _who address of the funder
     *
     */
    function hasDeposits(address _who) external view returns(bool)  {
        for (uint i = 0; i < COLLECTORS_COUNT; i = i.add(1)) {
            if (deposits[_who][i] != 0)
                return true;
        }
        return false;
    }

    /**
     * @dev Withdraw accumulated balance for a msg.sener
     * @param _collector collector ID
     */
    function withdraw(uint256 _collector) external {
        require(_collector < COLLECTORS_COUNT, "collector ID is not valid");

        address _funder = msg.sender;

        uint _amountToWithdraw = deposits[_funder][_collector];
        require(_amountToWithdraw > 0, "amount to withdraw should be positive value");

        delete deposits[_funder][_collector];

        if (_collector == ETH_COLLECTOR)
            _funder.transfer(_amountToWithdraw);

        emit WithdrawEvent(_funder, _collector, _amountToWithdraw);
    }

    /**
     * @dev Stores the sent amount
     * @param _funder address of the funder
     * @param _collector collector ID
     * @param _amount amount of funds
     *
     */
    function deposit(address _funder, uint256 _collector, uint256 _amount) external payable onlySale  {
        deposits[_funder][_collector] = deposits[_funder][_collector].add(_amount);
        emit EscrowEvent(_funder, _collector, _amount);
    }
    
    /**
     * @dev Invest funds
     * @param _funder address of the funder
     */
    function invest(address _funder) external onlySale {

        for (uint256 _collector = 0; _collector < COLLECTORS_COUNT; _collector = _collector.add(1)) {
            if (deposits[_funder][_collector] > 0) {
                uint256 _amountToInvest = deposits[_funder][_collector];
                
                delete deposits[_funder][_collector];

                if (_collector == ETH_COLLECTOR)
                    DiscoperiSaleBase(msg.sender).acquireTokens.value(_amountToInvest)(_collector, uint256(0), _funder, _amountToInvest);
                else 
                    DiscoperiSaleBase(msg.sender).acquireTokens(_collector, uint256(0), _funder, _amountToInvest);
                
                emit InvestEvent(_funder, _collector, _amountToInvest);
            }
        }
    }
}

// <ORACLIZE_API>
/*
Copyright (c) 2015-2016 Oraclize SRL
Copyright (c) 2016 Oraclize LTD
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

// This api is currently targeted at 0.4.18, please import oraclizeAPI_pre0.4.sol or oraclizeAPI_0.4 where necessary

// Incompatible compiler version... please select one stated within pragma solidity or use different oraclizeAPI version

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}

contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}

/*
Begin solidity-cborutils
https://github.com/smartcontractkit/solidity-cborutils
MIT License
Copyright (c) 2018 SmartContract ChainLink, Ltd.
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

library Buffer {
    struct buffer {
        bytes buf;
        uint capacity;
    }

    function init(buffer memory buf, uint _capacity) internal pure {
        uint capacity = _capacity;
        if(capacity % 32 != 0) capacity += 32 - (capacity % 32);
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(ptr, capacity))
        }
    }

    function resize(buffer memory buf, uint capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint a, uint b) private pure returns(uint) {
        if(a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Appends a byte array to the end of the buffer. Resizes if doing so
     *      would exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, bytes data) internal pure returns(buffer memory) {
        if(data.length + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, data.length) * 2);
        }

        uint dest;
        uint src;
        uint len = data.length;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + buffer length + sizeof(buffer length)
            dest := add(add(bufptr, buflen), 32)
            // Update buffer length
            mstore(bufptr, add(buflen, mload(data)))
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }

        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function append(buffer memory buf, uint8 data) internal pure {
        if(buf.buf.length + 1 > buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length)
            let dest := add(add(bufptr, buflen), 32)
            mstore8(dest, data)
            // Update buffer length
            mstore(bufptr, add(buflen, 1))
        }
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
        if(len + buf.buf.length > buf.capacity) {
            resize(buf, max(buf.capacity, len) * 2);
        }

        uint mask = 256 ** len - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + buffer length + sizeof(buffer length) + len
            let dest := add(add(bufptr, buflen), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length
            mstore(bufptr, add(buflen, len))
        }
        return buf;
    }
}

library CBOR {
    using Buffer for Buffer.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    function encodeType(Buffer.buffer memory buf, uint8 major, uint value) private pure {
        if(value <= 23) {
            buf.append(uint8((major << 5) | value));
        } else if(value <= 0xFF) {
            buf.append(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.append(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.append(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.append(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(Buffer.buffer memory buf, uint8 major) private pure {
        buf.append(uint8((major << 5) | 31));
    }

    function encodeUInt(Buffer.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(Buffer.buffer memory buf, int value) internal pure {
        if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(Buffer.buffer memory buf, bytes value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeString(Buffer.buffer memory buf, string value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(Buffer.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

/*
End solidity-cborutils
 */

contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Android = 0x40;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
      return oraclize_setNetwork();
      networkID; // silence the warning and remain backwards compatible
    }
    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){ //mainnet
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){ //ropsten testnet
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){ //kovan testnet
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){ //rinkeby testnet
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){ //ethereum-bridge
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){ //ether.camp ide
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){ //browser-solidity
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) public {
      return;
      myid; result; proof; // Silence compiler warnings
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0; // unexpectedly high price
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    // parseInt
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    using CBOR for Buffer.buffer;
    function stra2cbor(string[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeString(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
        safeMemoryCleaner();
        Buffer.buffer memory buf;
        Buffer.init(buf, 1024);
        buf.startArray();
        for (uint i = 0; i < arr.length; i++) {
            buf.encodeBytes(arr[i]);
        }
        buf.endSequence();
        return buf.buf;
    }

    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
        // Convert from seconds to ledger timer ticks
        _delay *= 10;
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            // the following variables can be relaxed
            // check relaxed random contract under ethereum-examples repo
            // for an idea on how to override and replace comit hash vars
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes memory delay = new bytes(32);
        assembly {
            mstore(add(delay, 0x20), _delay)
        }

        bytes memory delay_bytes8 = new bytes(8);
        copyBytes(delay, 24, 8, delay_bytes8, 0);

        bytes[4] memory args = [unonce, nbytes, sessionKeyHash, delay];
        bytes32 queryId = oraclize_query("random", args, _customGasLimit);

        bytes memory delay_bytes8_left = new bytes(8);

        assembly {
            let x := mload(add(delay_bytes8, 0x20))
            mstore8(add(delay_bytes8_left, 0x27), div(x, 0x100000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x26), div(x, 0x1000000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x25), div(x, 0x10000000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x24), div(x, 0x100000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x23), div(x, 0x1000000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x22), div(x, 0x10000000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x21), div(x, 0x100000000000000000000000000000000000000000000000000))
            mstore8(add(delay_bytes8_left, 0x20), div(x, 0x1000000000000000000000000000000000000000000000000))

        }

        oraclize_randomDS_setCommitment(queryId, keccak256(delay_bytes8_left, args[1], sha256(args[0]), args[2]));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

        // Step 6: verify the attestation signature, APPKEY1 must sign the sessionKey from the correct ledger app (CODEHASH)
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = byte(1); //role
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


        // Step 7: verify the APPKEY1 provenance (must be signed by Ledger)
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
        // Step 1: the prefix has to match &#39;LP\x01&#39; (Ledger Proof version 1)
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;

        require(prefix.length == n_random_bytes);

        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

        // Step 2: the unique keyhash has to match with the sha256 of (context name + queryId)
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

        // Step 3: we assume sig1 is valid (it will be verified during step 5) and we verify if &#39;result&#39; is the prefix of sha256(sig1)
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

        // Step 4: commitment match verification, keccak256(delay, nbytes, unonce, sessionKeyHash) == commitment in storage.
        // This is to verify that the computed args match with the ones specified in the query.
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)){ //unonce, nbytes and sessionKeyHash match
            delete oraclize_randomDS_args[queryId];
        } else return false;


        // Step 5: validity verification for sig1 (keyhash and args signed with the sessionKey)
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

        // verify if sessionPubkeyHash was verified already, if not.. let&#39;s do it!
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

        // Buffer too small
        require(to.length >= minLength); // Should be a better way?

        // NOTE: the offset 32 is added to skip the `size` field of both bytes variables
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    // Duplicate Solidity&#39;s ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don&#39;t update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can&#39;t access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

    // the following function has been written by Alex Beregszaszi (@axic), use it under the terms of the MIT license
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // &#39;mload&#39; will pad with zeroes if we overread.
            // There is no &#39;mload8&#39; to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // &#39;byte&#39; is not working due to the Solidity parser, so lets
            // use the second best option, &#39;and&#39;
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

    function safeMemoryCleaner() internal pure {
        assembly {
            let fmem := mload(0x40)
            codecopy(fmem, codesize, sub(msize, fmem))
        }
    }

}
// </ORACLIZE_API>

/**
 * @title OraclizeProvided
 * @dev OraclizeProvided is an extented usingOraclize contract
 */
contract OraclizeProvider is usingOraclize, Ownable {
    using SafeMath for uint256;

    // oraclize gas price
    uint256 private oraclizeGasPrice = 20000000000 wei;   

    // addresses authorized to refill the contract (for oraclize queries)
    mapping (address => bool) public refillers;

    // onlyOraclize modifier, restrict execution for oraclize contract only
    modifier onlyOraclize() {
        require(msg.sender == oraclize_cbAddress(), "callback should be called by oraclize");
        _;
    }

    /**
     * @dev Set oraclize gas price
     * @param _gasPrice New oraclize gas price
     */
    function setOraclizeGasPrice(uint256 _gasPrice) external onlyOwner {
        require(_gasPrice > 0, "gasPrice should not be equal to zero");
        oraclizeGasPrice = _gasPrice;
        oraclize_setCustomGasPrice(_gasPrice);
    } 

   
    /**
     * @dev Add a refiller
     * @param _refiller address that authorized to refill the contract
     */
    function addRefiller(address _refiller) external onlyOwner  {
        require(_refiller != address(0), ""); //TODO add comments
        refillers[_refiller] = true;
    }    
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

/**
 * @title Whitelisted
 * @dev The Whitelisted contract has a whitelist of addresses, and provides basic authorization control functions.
 */
contract Whitelisted is Ownable {
    using Roles for Roles.Role;

    event WhitelistAdded(address indexed account);
    event WhitelistRemoved(address indexed account);

    Roles.Role private whitelisted;

    /**
    * @dev Throws if operator is not whitelisted.
    * @param _operator address
    */
    modifier onlyIfWhitelisted(address _operator) {
        require(isWhitelisted(_operator), "");
        _;
    }

    /**
    * @dev add an address to the whitelist
    * @param _operator address
    * @return true if the address was added to the whitelist, false if the address was already in the whitelist
    */
    function addToWhitelist(address _operator)
        public
        onlyOwner
    {
        whitelisted.add(_operator);
        emit WhitelistAdded(_operator);
    }

    /**
    * @dev getter to determine if address is in whitelist
    */
    function isWhitelisted(address _operator)
        public
        view
        returns (bool)
    {
        return whitelisted.has(_operator);
    }

    /**
    * @dev remove an address from the whitelist
    * @param _operator address
    */
    function removeFromWhitelist(address _operator)
        public
        onlyOwner
    {
        whitelisted.remove(_operator);
        emit WhitelistRemoved(_operator);
    }

}

/**
 * @title Timed
 * @dev Restrict logic execution within a time frame.
 */
contract Timed {
    
    uint256 public openingTime;
    uint256 public closingTime;

    /**
    * @dev Reverts if not in time range.
    */
    modifier onlyWhileOpen {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp >= openingTime && block.timestamp <= closingTime, "");
        _;
    }

    /**
    * @dev Reverts if not after closingTime
    */
    modifier onlyWhenClosed {
        require(hasClosed(), "");
        _;
    }

    /**
    * @dev Constructor, takes opening and closing times.
    * @param _openingTime Opening time
    * @param _closingTime Closing time
    */
    constructor(uint256 _openingTime, uint256 _closingTime) public {
        // solium-disable-next-line security/no-block-members
        // require(_openingTime >= block.timestamp, "");
        require(_closingTime >= _openingTime, "");

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
    * @dev Checks whether the open period has already elapsed.
    * @return Whether open period has elapsed
    */
    function hasClosed() public view returns (bool) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp > closingTime;
    }
}

/**
 * @title DiscoperiReferal
 * @dev DiscoperiReferal is a ..
 */
contract DiscoperiReferral {
    using SafeMath for uint256;

    // Referral to referrer mapping
    mapping (address => address) public referralToReferrer;

    // Contribution limits (USD)
    uint256[6] private contributionRanges = [
        100, 1000, 10000, 20000, 30000, 50000
    ]; 

    // Referal bonuses
    uint256[6] private referralBonuses = [
        450, 525, 600, 675, 750, 825
    ]; 

    // Referal bonuses
    uint256[6] private referrerBonuses = [
        50, 75, 100, 125, 150, 175
    ]; 

    // Exponent for the bonuses
    uint256 private constant REF_BONUS_EXPONENT = 4;

    /**
     * @dev Event for referal and referrer bonuses logging
     * @param referral referral address
     * @param referralTokens referer tokens
     * @param referrer referrer address
     * @param referrerTokens referrer tokens
     */
    event ReferralBonusEvent(address indexed referral, uint256 referralTokens, address indexed referrer, uint256 referrerTokens);


    /**
     * @dev Set referrer for address
     * @param _referral address of the referral
     * @param _referrer address of the referrer
     */ 
    function _setReferrer(address _referral, address _referrer) internal  {
        referralToReferrer[_referral] = _referrer;
    }   

    /**
     * @dev Get referral and referrer bonus depending on the contribution amount
     * @param _contribution contribution amount (USD)
     */ 
    function _getRefBonus(uint256 _contribution) internal view returns(uint256 _referralBonus, uint256 _referrerBonus) {
        for (uint256 i = contributionRanges.length.sub(1); i >= 0; i.sub(1)) {
            if (_contribution > contributionRanges[i]) {
                _referralBonus = _contribution.mul(referralBonuses[i]).div(10 ** REF_BONUS_EXPONENT);
                _referrerBonus = _contribution.mul(referrerBonuses[i]).div(10 ** REF_BONUS_EXPONENT);
            }
        }
    }  
}

/**
 * @title DiscoperiSaleLockup
 * @dev DiscoperiLockBase is a ..
 */
contract DiscoperiSaleLockup {
    using SafeMath for uint256;

    // tokens ranges (DISC)
    uint256[3] private tokensRanges = [
        0, 100000, 1000000
    ]; 

    // lockup periods
    uint256[3] private lockupPeriods = [
        12 weeks, 24 weeks, 36 weeks
    ]; 


    /**
     * @dev Get lockup period release date depending on the tokens amount
     * @param _tokensAmount DISC tokens amount
     */ 
    function _getReleaseDate(uint256 _tokensAmount) internal view returns(uint256 ) {
        for (uint256 i = tokensRanges.length.sub(1); i >= 0; i = i.sub(1)) {
            if (_tokensAmount > tokensRanges[i]) {
                return now.add(lockupPeriods[i]); // solium-disable-line security/no-block-members
            }
        }
    }   
}

/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its primary account (the one that created it)
 */
contract Secondary {
  address private _primary;

  /**
   * @dev Sets the primary account to the one that is creating the Secondary contract.
   */
  constructor() public {
    _primary = msg.sender;
  }

  /**
   * @dev Reverts if called from any account other than the primary.
   */
  modifier onlyPrimary() {
    require(msg.sender == _primary);
    _;
  }

  function primary() public view returns (address) {
    return _primary;
  }

  function transferPrimary(address recipient) public onlyPrimary {
    require(recipient != address(0));

    _primary = recipient;
  }
}

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds destinated to a payee until they
 * withdraw them. The contract that uses the escrow as its payment method
 * should be its primary, and provide public methods redirecting to the escrow&#39;s
 * deposit and withdraw.
 */
contract Escrow is Secondary {
  using SafeMath for uint256;

  event Deposited(address indexed payee, uint256 weiAmount);
  event Withdrawn(address indexed payee, uint256 weiAmount);

  mapping(address => uint256) private _deposits;

  function depositsOf(address payee) public view returns (uint256) {
    return _deposits[payee];
  }

  /**
  * @dev Stores the sent amount as credit to be withdrawn.
  * @param payee The destination address of the funds.
  */
  function deposit(address payee) public onlyPrimary payable {
    uint256 amount = msg.value;
    _deposits[payee] = _deposits[payee].add(amount);

    emit Deposited(payee, amount);
  }

  /**
  * @dev Withdraw accumulated balance for a payee.
  * @param payee The address whose funds will be withdrawn and transferred to.
  */
  function withdraw(address payee) public onlyPrimary {
    uint256 payment = _deposits[payee];
    assert(address(this).balance >= payment);

    _deposits[payee] = 0;

    payee.transfer(payment);

    emit Withdrawn(payee, payment);
  }
}

/**
 * @title ConditionalEscrow
 * @dev Base abstract escrow to only allow withdrawal if a condition is met.
 */
contract ConditionalEscrow is Escrow {
  /**
  * @dev Returns whether an address is allowed to withdraw their funds. To be
  * implemented by derived contracts.
  * @param payee The destination address of the funds.
  */
  function withdrawalAllowed(address payee) public view returns (bool);

  function withdraw(address payee) public {
    require(withdrawalAllowed(payee));
    super.withdraw(payee);
  }
}

/**
 * @title RefundEscrow
 * @dev Escrow that holds funds for a beneficiary, deposited from multiple parties.
 * The primary account may close the deposit period, and allow for either withdrawal
 * by the beneficiary, or refunds to the depositors.
 */
contract RefundEscrow is Secondary, ConditionalEscrow {
  enum State { Active, Refunding, Closed }

  event Closed();
  event RefundsEnabled();

  State private _state;
  address private _beneficiary;

  /**
   * @dev Constructor.
   * @param beneficiary The beneficiary of the deposits.
   */
  constructor(address beneficiary) public {
    require(beneficiary != address(0));
    _beneficiary = beneficiary;
    _state = State.Active;
  }

  /**
   * @return the current state of the escrow.
   */
  function state() public view returns (State) {
    return _state;
  }

  /**
   * @return the beneficiary of the escrow.
   */
  function beneficiary() public view returns (address) {
    return _beneficiary;
  }

  /**
   * @dev Stores funds that may later be refunded.
   * @param refundee The address funds will be sent to if a refund occurs.
   */
  function deposit(address refundee) public payable {
    require(_state == State.Active);
    super.deposit(refundee);
  }

  /**
   * @dev Allows for the beneficiary to withdraw their funds, rejecting
   * further deposits.
   */
  function close() public onlyPrimary {
    require(_state == State.Active);
    _state = State.Closed;
    emit Closed();
  }

  /**
   * @dev Allows for refunds to take place, rejecting further deposits.
   */
  function enableRefunds() public onlyPrimary {
    require(_state == State.Active);
    _state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @dev Withdraws the beneficiary&#39;s funds.
   */
  function beneficiaryWithdraw() public {
    require(_state == State.Closed);
    _beneficiary.transfer(address(this).balance);
  }

  /**
   * @dev Returns whether refundees can withdraw their deposits (be refunded).
   */
  function withdrawalAllowed(address payee) public view returns (bool) {
    return _state == State.Refunding;
  }
}

/**
 * @title DiscoperiRefundable
 * @dev DiscoperiRefundable is a ..
 */
contract DiscoperiRefundable is DiscoperiMultiCollector {
    using SafeMath for uint256;

    // is refund enabled
    bool private refundEnabled;

    // escrow which stores funds during sale
    // RefundEscrow private vault;
    address private vault;
    
    /**
     * @dev Event for refund logging
     * @param beneficiary beneficiary who get a refund
     * @param collector collector
     * @param funds refund funds amount
     */
    event RefundEvent(address indexed beneficiary, uint256 collector, uint256 funds);

    // when refund enabled modifier
    modifier whenRefundEnabled() {
        require(refundEnabled == true, "");
        _;
    }


    /**
     * CONSTRUCTOR
     * @dev Initialize escrow contract for storing funds in ether
     * @param _wallet wallet address
     */
    constructor(address _wallet) {
        vault = _wallet; //new RefundEscrow(_wallet);
    }

    /**
     * @dev Investors can claim refunds here if sale is unsuccessful
     * @param _collector collector ID
     */
    function claimRefund(uint256 _collector) external whenRefundEnabled {
        require(_collector < COLLECTORS_COUNT, "collector ID is not valid");

        address _funder = msg.sender;

        uint _amountToWithdraw = spent[_funder][_collector];
        require(_amountToWithdraw > 0, "amount to withdraw should be positive value");

        delete spent[_funder][_collector];

        // if (_collector == ETH_COLLECTOR)
        //     vault.withdraw(_funder);

        emit RefundEvent(_funder, _collector, _amountToWithdraw);
    }
    
    /**
     * @dev Finalize sale
     * @param _isSuccessful is sale successfull
     */
    function _finalizeSale(bool _isSuccessful) internal {
        // if (_isSuccessful) {
        //     vault.close();
        //     vault.beneficiaryWithdraw();
        // } else {
        //     refundEnabled = true;
        //     vault.enableRefunds();
        // }
    }  

     /**
     * @dev Forward funds in ether  to vault
     * @param _funder address of the funder
     * @param _funds funds amount
     */
    function _forwardFunds(address _funder, uint256 _funds) internal {
        // vault.deposit.value(_funds)(_funder);
        vault.transfer(_funds);
    }  

}

/**
 * @title DiscoperiSaleBase
 * @dev DiscoperiSaleBase is a base contract for managing 
 * Discoperi public pre-sale and Discoperi public sale stages,
 * allowing investors to purchase tokens. This contract implements
 * all functionality except _getTokenPrice() function, which should be
 * overriden in the inherited contract to return proper token price using PRICE_EXPONENT.
 */
contract DiscoperiSaleBase is Timed, Whitelisted, OraclizeProvider, DiscoperiReferral, DiscoperiSaleLockup, DiscoperiRefundable {
    using SafeMath for uint256;

    // Token decimals
    uint256 public constant TOKEN_DECIMALS = 18;

    // Exponent for the token price
    uint256 public constant PRICE_EXPONENT = 4;

    // Exponent for the rate
    uint256 public constant RATE_EXPONENT = 4;

    // Soft cap - 5,000,000 (USD)
    uint256 public constant SOFT_CAP = 5000000;   

    // minimum funsing amount (USD)
    uint256 public constant MIN_FUNDING = 100;   

    // Discoperi token address
    DiscoperiToken public token;

    // Discoperi escrow address
    DiscoperiEscrow public escrow;

    // address where funds will be collected
    address public wallet;

    // Raised USD
    uint256 public raisedUSD;

    // Tokens distributed
    uint256 public distributed;

    // Tokens obtained by beneficiary
    mapping (address => uint256) public obtained;

    // Used transactions, for preventing spending twice
    mapping (uint256 => mapping(uint256 => bool)) public usedTxs;

    // Order
    struct Order {
        address beneficiary;
        uint256 collector;
        uint256 funds;
    }

    // List of oraclize orders
    mapping (bytes32 => Order) public oraclizeOrders;

    /**
     * @dev Event for funding order logging
     * @param beneficiary beneficiary who want to obtain tokens
     * @param orderId oraclize orderId
     * @param collector collector
     * @param funds paid funds amount
     */
    event OrderEvent(address indexed beneficiary, bytes32 indexed orderId, uint256 collector, uint256 funds);

    /**
     * @dev Event for tokens obtaining logging
     * @param beneficiary beneficiary who obtain tokens
     * @param rate rate for funds
     * @param tokens amount of obtained tokens
     */
    event ObtainTokensEvent(address indexed beneficiary, uint256 collector, uint256 funds, uint256 rate, uint256 tokens);  // solium-disable-line max-len

    

   /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Discoperi Sale
     * @param _openingTime sale opening time
     * @param _closingTime sale closing time
     * @param _token Discoperi ERC20 token
     * @param _wallet Wallet address to transfer funding to
     */ 
    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        address _token, 
        address _wallet,
        address _escrow
    )
        public
        Timed(_openingTime, _closingTime) 
        DiscoperiRefundable(_wallet)    
    {
        require(_token != address(0), "token address should not be equal to zero address");
        require(_escrow != address(0), "escrow address should not be equal to zero address");
        require(_wallet != address(0), "escrow address should not be equal to zero address");

        token = DiscoperiToken(_token);
        escrow = DiscoperiEscrow(_escrow);
        wallet = _wallet;
    }

    /**
     * @dev Fallback function, used to buy tokens and refill the contract for oraclize
     */
    function () public payable {
        address _sender = msg.sender;
        uint256 _funds = msg.value;
        uint256 _collector = ETH_COLLECTOR;

        if (!refillers[_sender] && !(owner() == _sender)) {
            if (isWhitelisted(_sender))
                _orderTokens(_sender, _collector, _funds);
            else 
                escrow.deposit.value(_funds)(_sender, _collector, _funds);
        }
    }

    /**
    * @dev Accredit an investor by adding investor to the whitelist and setting referrer for investor
    * @param _investor address of the investor
    * @param _referrer address of the referrer (optional)
    * @return true if the address was added to the whitelist, false if the address was already in the whitelist
    */
    function accreditInvestor(address _investor, address _referrer) external onlyOwner {
        require(_investor != _referrer, "investor couldn&#39;t be referer for himself");

        if (_referrer != address(0))
            _setReferrer(_investor, _referrer);

        addToWhitelist(_investor);

        if (escrow.hasDeposits(_investor))
            escrow.invest(_investor);
    }

    /**
     * @dev Order tokens for beneficiary
     * @param _collector  collector id
     * @param _tx hash of the transaction
     * @param _beneficiary beneficiary who has paid coins for tokens
     * @param _funds amount of coins beneficiary has paid 
     */
    function acquireTokens(uint256 _collector, uint256 _tx, address _beneficiary, uint256 _funds) external payable onlyOwner {
        require(_collector < COLLECTORS_COUNT, "collector ID is not valid");
        require(!usedTxs[_collector][_tx] || msg.sender == address(escrow), "the tx was already processed");
        usedTxs[_collector][_tx] = true;

        if (isWhitelisted(_beneficiary))
            _orderTokens(_beneficiary, _collector, _funds);
        else 
            escrow.deposit(_beneficiary, _collector, _funds);
    }

    /**
     * @dev Must be called after sale ends, to do some extra finalization
     * work. Calls the contract&#39;s finalizeSale function.
     */
    function finalizeSale() external {
        // TODO DISCUSS HOW SOFTCAP IS DEFINING
        bool _isSaleSuccessful;

        // if (token.salesSuccessfull()) { 
        //     _isSaleSuccessful = true;
        // } else {
        //     _isSaleSuccessful = false;
        // }

        _finalizeSale(_isSaleSuccessful);
    }

    /**
     * @dev Get current rate from oraclize and transfer tokens and funds
     * @param _orderId oraclize order id
     * @param _result oraclize result
     */
    function __callback(bytes32 _orderId, string _result) public onlyOraclize {  // solium-disable-line mixedcase
        address _beneficiary = oraclizeOrders[_orderId].beneficiary;
        uint256 _collector = oraclizeOrders[_orderId].collector;
        uint256 _funds = oraclizeOrders[_orderId].funds;
        uint256 _rate = parseInt(_result, RATE_EXPONENT);

        _updateRate(_collector, _rate);
        _deliverTokens(_beneficiary, _collector, _funds, _rate);
    }   

    /**
     * @dev Makes order for tokens
     * @param _beneficiary beneficiary who wants to obtain the tokens
     * @param _collector collector 
     * @param _funds amount of the funds
     */
    function _orderTokens(address _beneficiary, uint256 _collector, uint256 _funds) internal onlyWhileOpen {
        require(_beneficiary != address(0), "beneficiary address should not be equal to zero address");
        require(_collector < COLLECTORS_COUNT, "collector value should be less than collectors count");

        if (_isRateActual(_collector)) 
            _deliverTokens(_beneficiary, _collector, _funds, collectors[_collector].rate);
        else {
            bytes32 _orderId = oraclize_query("URL", collectors[_collector].dataSource, collectors[_collector].gasLimit);

            oraclizeOrders[_orderId].beneficiary = _beneficiary;
            oraclizeOrders[_orderId].collector = _collector;
            oraclizeOrders[_orderId].funds = _funds;

            emit OrderEvent(_beneficiary, _orderId, _collector, _funds);
        }
    }
    
    /**
     * @dev Deliver tokens to beneficiary
     * @param _beneficiary beneficiary
     * @param _collector collector
     * @param _funds funds
     * @param _rate rate
     */   
    function _deliverTokens(address _beneficiary, uint256 _collector, uint256 _funds, uint256 _rate) internal {
        uint256 _tokens;

        uint256 _sum = _funds.mul(_rate).mul(10 ** (TOKEN_DECIMALS - collectors[_collector].decimals)).div(10 ** RATE_EXPONENT);           
        uint256 _usdInvested = _sum.div(10 ** TOKEN_DECIMALS);

        if (_usdInvested < MIN_FUNDING) {
            if (_collector == ETH_COLLECTOR)
                _beneficiary.transfer(_funds);
            emit RefundEvent(_beneficiary, _collector, _funds); // solium-disable-line arg-overflow
        } else {
            _tokens = _sum.mul(10 ** PRICE_EXPONENT).div(_getTokenPrice());       
            collected[_collector] = collected[_collector].add(_funds);
            spent[_beneficiary][_collector] = spent[_beneficiary][_collector].add(_funds);
            raisedUSD = raisedUSD.add(_usdInvested);

            if (_tokens > 0) {
                address _referrer = referralToReferrer[_beneficiary];
                if (_validateReferrer(_referrer)) {
                    (uint256 _referralBonusTokens, uint256 _referrerBonusTokens) = _getRefBonus(_tokens);
                    _tokens = _tokens.add(_referralBonusTokens);
                    token.allocatePurchase(_referrer, _referrerBonusTokens, _getReleaseDate(_referrerBonusTokens));
                    distributed = distributed.add(_referrerBonusTokens);
                    obtained[_referrer] = obtained[_referrer].add(_referrerBonusTokens); 
                    emit ReferralBonusEvent(_beneficiary, _referralBonusTokens, _referrer, _referrerBonusTokens);
                }
                token.allocatePurchase(_beneficiary, _tokens, _getReleaseDate(_tokens));
                distributed = distributed.add(_tokens);     
                obtained[_beneficiary] = obtained[_beneficiary].add(_tokens); 
                emit ObtainTokensEvent(_beneficiary, _collector, _funds, _rate, _tokens); 
            } 
        }
        if (_collector == ETH_COLLECTOR) {
            _forwardFunds(_beneficiary, _funds);
        }
    }

    
    /**
     * @dev Validate referrer by checking if referrer has investments
     * @param _referrer referrer address
     * @return true if referrer is valid
     */ 
    function _validateReferrer(address _referrer) internal view returns(bool) {
        if (_referrer == address(0) || obtained[_referrer] == uint(0))
            return false;
        return true;
    } 

    /**
     * @dev Override to return proper token price
     * @return token price using PRICE_EXPONENT
     */ 
    function _getTokenPrice() internal pure returns(uint256);

}

/**
 * @title DiscoperiPublicPresale
 * @dev DiscoperiPublicPresale is a contract for managing Discoperi public pre-sale stage,
 * allowing accrediting investors to purchase tokens. All functionality is implemented
 * in parent DiscoperiSaleBase contact. The pre-sale contract only sets the token price, proper for this stage.
 */
contract DiscoperiPublicPresale is DiscoperiSaleBase {
    
    // Token price (USD) using PRICE_EXPONENT
    uint256 public constant PUBLIC_PRESALE_TOKEN_PRICE = 9; 

    // public pre-sale hard cap (usd)
    uint256 public constant PUBLIC_PRESALE_HARD_CAP = 40000000; // 40,000,000 USD

    /**
     * CONSTRUCTOR
     *
     * @dev Initialize the Discoperi Sale
     * @param _openingTime sale opening time
     * @param _closingTime sale closing time
     * @param _token Discoperi ERC20 token
     * @param _wallet Wallet address to transfer funding to
     */ 
    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        address _token, 
        address _wallet,
        address _escrow
    )
        public
        DiscoperiSaleBase(_openingTime, _closingTime, _token, _wallet, _escrow)      
    {}

    /**
     * @dev Get current token price
     * @return token price using PRICE_EXPONENT
     */ 
    function _getTokenPrice() internal pure returns(uint256) {
        return PUBLIC_PRESALE_TOKEN_PRICE;
    }

    /**
     * @dev Get hard cap
     * @return hard cap value (usd)
     */ 
    function _getHardCap() internal pure returns(uint256) {
        return PUBLIC_PRESALE_HARD_CAP;
    }
}