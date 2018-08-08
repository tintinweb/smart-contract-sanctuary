pragma solidity 0.4.24;

// File: contracts/commons/SafeMath.sol

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

// File: contracts/flavours/Ownable.sol

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

// File: contracts/flavours/Lockable.sol

/**
 * @title Lockable
 * @dev Base contract which allows children to
 *      implement main operations locking mechanism.
 */
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

    /**
     * @dev Modifier to make a function callable
    *       only when the contract is not locked.
     */
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

    /**
     * @dev Modifier to make a function callable
     *      only when the contract is locked.
     */
    modifier whenLocked() {
        require(locked);
        _;
    }

    /**
     * @dev Called before lock/unlock completed
     */
    modifier preLockUnlock() {
      _;
    }

    /**
     * @dev called by the owner to locke, triggers locked state
     */
    function lock() public onlyOwner whenNotLocked preLockUnlock {
        locked = true;
        emit Lock();
    }

    /**
     * @dev called by the owner
     *      to unlock, returns to unlocked state
     */
    function unlock() public onlyOwner whenLocked preLockUnlock {
        locked = false;
        emit Unlock();
    }
}

// File: contracts/base/BaseFixedERC20Token.sol

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

    /// @dev ERC20 Total supply
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

    /// @dev Fired if token is transferred according to ERC20 spec
    event Transfer(address indexed from, address indexed to, uint value);

    /// @dev Fired if token withdrawal is approved according to ERC20 spec
    event Approval(address indexed owner, address indexed spender, uint value);

    /**
     * @dev Gets the balance of the specified address
     * @param owner_ The address to query the the balance of
     * @return An uint representing the amount owned by the passed address
     */
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to_ The address to transfer to.
     * @param value_ The amount to be transferred.
     */
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
        // SafeMath.sub will throw an exception if there is not enough balance
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from_ address The address which you want to send tokens from
     * @param to_ address The address which you want to transfer to
     * @param value_ uint the amount of tokens to be transferred
     */
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering
     *
     * To change the approve amount you first have to reduce the addresses
     * allowance to zero by calling `approve(spender_, 0)` if it is not
     * already 0 to mitigate the race condition described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param spender_ The address which will spend the funds.
     * @param value_ The amount of tokens to be spent.
     */
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param owner_ address The address which owns the funds
     * @param spender_ address The address which will spend the funds
     * @return A uint specifying the amount of tokens still available for the spender
     */
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

// File: contracts/base/BaseICOToken.sol

/**
 * @dev Not mintable, ERC20 compliant token, distributed by ICO/Pre-ICO.
 */
contract BaseICOToken is BaseFixedERC20Token {

    /// @dev Available supply of tokens
    uint public availableSupply;

    /// @dev ICO/Pre-ICO smart contract allowed to distribute public funds for this
    address public ico;

    /// @dev Token/ETH exchange ratio multiplier (for high accuracy)
    uint public constant ETH_TOKEN_EXCHANGE_RATIO_MULTIPLIER = 1000;

    /// @dev Token/ETH exchange ratio
    uint public ethTokenExchangeRatio;

    /// @dev Fired if investment for `amount` of tokens performed by `to` address
    event ICOTokensInvested(address indexed to, uint amount);

    /// @dev ICO contract changed for this token
    event ICOChanged(address indexed icoContract);

    modifier onlyICO() {
        require(msg.sender == ico);
        _;
    }

    /**
     * @dev Not mintable, ERC20 compliant token, distributed by ICO/Pre-ICO.
     * @param totalSupply_ Total tokens supply.
     */
    constructor(uint totalSupply_) public {
        locked = true;
        totalSupply = totalSupply_;
        availableSupply = totalSupply_;
    }

    /**
     * @dev Set address of ICO smart-contract which controls token
     * initial token distribution.
     * @param ico_ ICO contract address.
     */
    function changeICO(address ico_) public onlyOwner {
        ico = ico_;
        emit ICOChanged(ico);
    }

    function isValidICOInvestment(address to_, uint amount_) internal view returns (bool) {
        return to_ != address(0) && amount_ <= availableSupply;
    }

    /**
     * @dev Assign `amountWei_` of wei converted into tokens to investor identified by `to_` address.
     * @param to_ Investor address.
     * @param amountWei_ Number of wei invested
     * @return Amount of invested tokens
     */
    function icoInvestmentWei(address to_, uint amountWei_) public returns (uint);

    /**
     * @dev Assign `amount_` of privately distributed tokens from bounty group
     *      to someone identified with `to_` address.
     * @param to_   Tokens owner
     * @param amount_ Number of tokens distributed with decimals part
     */
    function icoAssignReservedBounty(address to_, uint amount_) public;
}

// File: contracts/base/BaseICOMintableToken.sol

/**
 * @dev Mintable, ERC20 compliant token, distributed by ICO/Pre-ICO.
 */
contract BaseICOMintableToken is BaseICOToken {

    event TokensMinted(uint mintedAmount, uint totalSupply);

    constructor(uint totalSupplyWei_) public BaseICOToken(totalSupplyWei_) {
    }

    /**
    * @dev Mint token.
    * @param mintedAmount_ amount to mint.
    */
    function mintToken(uint mintedAmount_) public onlyOwner {
        mintCheck(mintedAmount_);
        totalSupply = totalSupply.add(mintedAmount_);
        emit TokensMinted(mintedAmount_, totalSupply);
    }

    function mintCheck(uint) internal;
}

// File: contracts/ESRToken.sol

/**
 * Esperanto Token
 */
contract ESRToken is BaseICOMintableToken {
  using SafeMath for uint;

  string public constant name = "EsperantoToken";

  string public constant symbol = "ESRT";

  uint8 public constant decimals = 18;

  // --------------- Reserved groups

  uint8 public constant RESERVED_PARTNERS_GROUP = 0x1;

  uint8 public constant RESERVED_TEAM_GROUP = 0x2;

  uint8 public constant RESERVED_BOUNTY_GROUP = 0x4;

  uint internal ONE_TOKEN = 1e18; // 1e18 / ESRT = 1

  /// @dev Fired some tokens distributed to someone from staff,business
  event ReservedTokensDistributed(address indexed to, uint8 group, uint amount);

  /// @dev Fired if token exchange ratio updated
  event EthTokenExchangeRatioUpdated(uint ethTokenExchangeRatio);

  /// @dev Token sell event
  event SellToken(address indexed to, uint amount, uint bonusAmount);

  /// @dev Token reservation mapping: key(RESERVED_X) => value(number of tokens)
  mapping(uint8 => uint) public reserved;

  constructor(uint ethTokenExchangeRatio_,
              uint totalSupplyTokens_,
              uint teamTokens_,
              uint bountyTokens_,
              uint partnersTokens_) public BaseICOMintableToken(totalSupplyTokens_ * ONE_TOKEN) {
    require(availableSupply == totalSupply);
    ethTokenExchangeRatio = ethTokenExchangeRatio_;
    availableSupply = availableSupply
            .sub(teamTokens_ * ONE_TOKEN)
            .sub(bountyTokens_ * ONE_TOKEN)
            .sub(partnersTokens_ * ONE_TOKEN);
    reserved[RESERVED_TEAM_GROUP] = teamTokens_ * ONE_TOKEN;
    reserved[RESERVED_BOUNTY_GROUP] = bountyTokens_ * ONE_TOKEN;
    reserved[RESERVED_PARTNERS_GROUP] = partnersTokens_ * ONE_TOKEN;
  }

  function mintCheck(uint) internal {
    // Token not mintable until: 2020-06-01T00:00:00.000Z
    require(block.timestamp >= 1590969600);
  }

  modifier preLockUnlock() {
    // Token transfers locked until: 2019-10-01T00:00:00.000Z
    require(block.timestamp >= 1569888000);
    _;
  }

  // Disable direct payments
  function() external payable {
    revert();
  }

  /**
   * @dev Get reserved tokens for specific group
   */
  function getReservedTokens(uint8 group_) public view returns (uint) {
      return reserved[group_];
  }

  /**
   * @dev Assign `amount_` of privately distributed tokens from bounty group
   *      to someone identified with `to_` address.
   * @param to_   Tokens owner
   * @param amount_ Number of tokens distributed with decimals part
   */
  function icoAssignReservedBounty(address to_, uint amount_) public onlyICO {
    assignReservedTokens(to_, RESERVED_BOUNTY_GROUP, amount_);
  }

  /**
   * @dev Assign `amount_` of privately distributed tokens
   *      to someone identified with `to_` address.
   * @param to_   Tokens owner
   * @param group_ Group identifier of privately distributed tokens
   * @param amount_ Number of tokens distributed with decimals part
   */
  function assignReserved(address to_, uint8 group_, uint amount_) public onlyOwner {
      assignReservedTokens(to_, group_, amount_);
  }

  /**
   * @dev Assign `amount_` of privately distributed tokens
   *      to someone identified with `to_` address.
   * @param to_   Tokens owner
   * @param group_ Group identifier of privately distributed tokens
   * @param amount_ Number of tokens distributed with decimals part
   */
  function assignReservedTokens(address to_, uint8 group_, uint amount_) internal {
      require(to_ != address(0) && (group_ & 0x7) != 0);
      // SafeMath will check reserved[group_] >= amount
      reserved[group_] = reserved[group_].sub(amount_);
      balances[to_] = balances[to_].add(amount_);
      emit ReservedTokensDistributed(to_, group_, amount_);
  }

  /**
   * @dev Update ETH/Token
   * @param ethTokenExchangeRatio_ must be multiplied on ETH_TOKEN_EXCHANGE_RATIO_MULTIPLIER
   */
  function updateTokenExchangeRatio(uint ethTokenExchangeRatio_) public onlyOwner {
    ethTokenExchangeRatio = ethTokenExchangeRatio_;
    emit EthTokenExchangeRatioUpdated(ethTokenExchangeRatio);
  }


  /**
   * @dev Register token sell
   */
  function sellToken(address to_, uint amount, uint bonusAmount) public onlyOwner returns (uint)  {
    require(to_ != address(0) && amount <= availableSupply);
    availableSupply = availableSupply.sub(amount);
    balances[to_] = balances[to_].add(amount);
    assignReservedTokens(to_, RESERVED_BOUNTY_GROUP, bonusAmount);
    emit SellToken(to_, amount, bonusAmount);
    return amount;
  }

  /**
   * @dev Assign `amountWei_` of wei converted into tokens to investor identified by `to_` address.
   * @param to_ Investor address.
   * @param amountWei_ Number of wei invested
   * @return Amount of invested tokens
   */
  function icoInvestmentWei(address to_, uint amountWei_) public onlyICO returns (uint) {
    uint amount = amountWei_.mul(ethTokenExchangeRatio).div(ETH_TOKEN_EXCHANGE_RATIO_MULTIPLIER);
    require(isValidICOInvestment(to_, amount));
    availableSupply = availableSupply.sub(amount);
    balances[to_] = balances[to_].add(amount);
    emit ICOTokensInvested(to_, amount);
    return amount;
  }
}