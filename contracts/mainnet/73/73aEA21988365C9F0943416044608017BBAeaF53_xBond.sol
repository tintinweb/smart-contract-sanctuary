/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// File: contracts/interface/ICash.sol

pragma solidity >=0.4.24;


interface ICash {
    function claimDividends(address account) external returns (uint256);

    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function balanceOf(address who) external view returns(uint256);
    function allowance(address owner_, address spender) external view returns(uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
    function redeemedShare(address account) external view returns (uint256);
}

// File: openzeppelin-eth/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
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
  function initialize(address sender) public initializer {
    _owner = sender;
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

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.4.24;


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

// File: openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.4.24;




/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string name, string symbol, uint8 decimals) public initializer {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
}

// File: openzeppelin-eth/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.4.24;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard is Initializable {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  function initialize() public initializer {
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

  uint256[50] private ______gap;
}

// File: contracts/lib/SafeMathInt.sol

/*
MIT License

Copyright (c) 2018 requestnetwork

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

pragma solidity >=0.4.24;


/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

// File: contracts/usd/bond.sol

pragma solidity >=0.4.24;








/*
 *  xBond ERC20
 */


contract xBond is ERC20Detailed, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_BOND_SUPPLY = 0;

    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;

    // eslint-ignore
    ICash Dollars;

    mapping(address => uint256) private _bondBalances;
    mapping (address => mapping (address => uint256)) private _allowedBond;

    uint256 public claimableUSD;
    uint256 public lastRebase;
    mapping (address => uint256) public lastUserRebase;

    uint256 public constantUsdRebase;
    address public ethBondOracle;
    address public timelock;

    uint256 public bondingMinimumSeconds;                       // minimum amount of allocated bonding time per user
    uint256 public coolDownPeriodSeconds;                       // how long it takes for a user to get paid their money back

    mapping (address => uint256) public lastUserPoints;         // used for global reward calculation
    uint256 public totalDollarPoints;
    uint256 public constant POINT_MULTIPLIER_BIG = 10 ** 18;

    mapping (address => uint256) public lastUserBond;           // used for minimum staking time
    mapping (address => uint256) public lastUserCoolDown;       // used for when a user starts cooldown
    mapping (address => uint256) public bondingStatus;          // 1 = cooldown, 0 regular

    function initialize(address owner_, address timelock_, address dollar_)
        public
        initializer
    {
        ERC20Detailed.initialize("xBond", "xBond", uint8(DECIMALS));
        Ownable.initialize(owner_);
        ReentrancyGuard.initialize();
        Dollars = ICash(dollar_);
        timelock = timelock_;

        _totalSupply = INITIAL_BOND_SUPPLY;
        _bondBalances[owner_] = _totalSupply;

        emit Transfer(address(0x0), owner_, _totalSupply);
    }

     /**
     * @return The total number of Dollars.
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    // show balance minus shares
    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _bondBalances[who];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        updateAccount(msg.sender)
        updateAccount(to)
        validRecipient(to)
        returns (bool)
    {
        // make sure users cannot double claim if they have already claimed
        if (lastUserRebase[msg.sender] == lastRebase) lastUserRebase[to] = lastRebase;

        lastUserPoints[msg.sender] = totalDollarPoints;
        _bondBalances[msg.sender] = _bondBalances[msg.sender].sub(value);
        _bondBalances[to] = _bondBalances[to].add(value);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function setBondingMinimumSeconds(uint256 seconds_) external {
        require(msg.sender == timelock || msg.sender == address(0x89a359A3D37C3A857E62cDE9715900441b47acEC), "unauthorized");
        bondingMinimumSeconds = seconds_;
    }

    function setCoolDownSeconds(uint256 seconds_) external {
        require(msg.sender == timelock || msg.sender == address(0x89a359A3D37C3A857E62cDE9715900441b47acEC), "unauthorized");
        coolDownPeriodSeconds = seconds_;
    }    

    function setLastRebase(uint256 newUsdAmount) external {
        require(msg.sender == address(Dollars), "unauthorized");
        lastRebase = now;

        if (newUsdAmount == 0) {
            claimableUSD = 0;
            constantUsdRebase = 0;
        } else {
            claimableUSD = claimableUSD.add(newUsdAmount);
            constantUsdRebase = claimableUSD;
        }

        totalDollarPoints = totalDollarPoints.add(newUsdAmount.mul(POINT_MULTIPLIER_BIG).div(_totalSupply));
    }

    function setTimelock(address timelock_) validRecipient(timelock_) external onlyOwner {
        timelock = timelock_;
    }

    function setEthBondOracle(address oracle_) validRecipient(oracle_) external {
        require(msg.sender == timelock);
        ethBondOracle = oracle_;
    }

    function mint(address _who, uint256 _amount) validRecipient(_who) public nonReentrant {
        require(msg.sender == address(Dollars), "unauthorized");
        require(bondingStatus[_who] == 0, 'must not be in cooldown');

        _bondBalances[_who] = _bondBalances[_who].add(_amount);
        lastUserBond[_who] = now;
        _totalSupply = _totalSupply.add(_amount);
        
        lastUserPoints[_who] = totalDollarPoints;
        emit Transfer(address(0x0), _who, _amount);
    }

    function enterBondCoolDown(address _who) validRecipient(_who) external nonReentrant returns (bool) {
        require(msg.sender == address(Dollars), "unauthorized");
        require(bondingStatus[_who] == 0, 'already in cooldown');
        require(lastUserBond[_who] + bondingMinimumSeconds <= now, "must wait minimum bonding time");
        lastUserCoolDown[_who] = now;
        bondingStatus[_who] = 1;

        return true;
    }

    // redeem 1-1 during positive rebases
    function redeem(address _who) validRecipient(_who) external nonReentrant returns (bool) {
        require(msg.sender == address(Dollars), "unauthorized");
        emit Transfer(_who, address(0x0), _bondBalances[_who]);
        _totalSupply = _totalSupply.sub(_bondBalances[_who]);
        _bondBalances[_who] = 0;

        return true;
    }

    function claimableProRataUSD(address _who) validRecipient(_who) public view returns (uint256) {
        uint256 userStake = _bondBalances[_who];

        if (lastUserPoints[_who] == 0) {
            return constantUsdRebase.mul(balanceOf(_who)).div(_totalSupply);
        } else {
            // no rewards for committed users
            if (totalDollarPoints > lastUserPoints[_who]) {
                uint256 newDividendPoints = totalDollarPoints.sub(lastUserPoints[_who]);
                uint256 owedDollars =  userStake.mul(newDividendPoints).div(POINT_MULTIPLIER_BIG);

                owedDollars = owedDollars > Dollars.balanceOf(address(Dollars)) ? Dollars.balanceOf(address(Dollars)) : owedDollars;

                return owedDollars;
            } else {
                return 0;
            }
        }
    }

    function remove(address _who, uint256 _amount, uint256 _usdAmount) validRecipient(_who) public nonReentrant {
        require(msg.sender == address(Dollars), "unauthorized");
        require(_usdAmount <= claimableUSD, "usd amount must be less than claimable usd");
        require(lastUserRebase[_who] != lastRebase, "user already claimed once - please wait until next rebase");

        uint256 proRataUsd = claimableProRataUSD(_who);
        require(_usdAmount <= proRataUsd, "usd amount exceeds pro-rata rights - please try a smaller amount");
        
        _bondBalances[_who] = _bondBalances[_who].sub(_amount);
        claimableUSD = claimableUSD.sub(_usdAmount);
        _totalSupply = _totalSupply.sub(_amount);

        lastUserRebase[_who] = lastRebase;
        lastUserPoints[_who] = totalDollarPoints;
        emit Transfer(_who, address(0x0), _amount);
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedBond[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        updateAccount(from)
        updateAccount(to)
        validRecipient(to)
        returns (bool)
    {
        // make sure users cannot double claim if they have already claimed
        if (lastUserRebase[from] == lastRebase) lastUserRebase[to] = lastRebase;

        lastUserPoints[from] = totalDollarPoints;
        _allowedBond[from][msg.sender] = _allowedBond[from][msg.sender].sub(value);

        _bondBalances[from] = _bondBalances[from].sub(value);
        _bondBalances[to] = _bondBalances[to].add(value);
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        public
        validRecipient(spender)
        returns (bool)
    {
        _allowedBond[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedBond[msg.sender][spender] =
            _allowedBond[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedBond[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public

        returns (bool)    {
        uint256 oldValue = _allowedBond[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedBond[msg.sender][spender] = 0;
        } else {
            _allowedBond[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedBond[msg.sender][spender]);
        return true;
    }

    modifier updateAccount(address account) {
        Dollars.claimDividends(account);
        (bool success, ) = ethBondOracle.call(abi.encodeWithSignature('update()'));
        _;
    }
}