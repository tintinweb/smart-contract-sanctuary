/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

// File: contracts/lib/UInt256Lib.sol

pragma solidity >=0.4.24;


/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
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

// File: contracts/interface/ISeigniorageShares.sol

pragma solidity >=0.4.24;


interface ISeigniorageShares {
    function setDividendPoints(address account, uint256 totalDividends) external returns (bool);
    function setSyntheticDividendPoints(address synth, address who, uint256 amount) external returns (bool);

    function mintShares(address account, uint256 amount) external returns (bool);

    function lastDividendPoints(address who) external view returns (uint256);
    function lastSyntheticDividendPoints(address synth, address who) external view returns (uint256);
    function stakingStatus(address who) external view returns (uint256);
    
    function externalRawBalanceOf(address who) external view returns (uint256);
    function externalTotalSupply() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function deleteShare(address account, uint256 amount) external;
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

// File: contracts/cny/cnyx.sol

pragma solidity >=0.4.24;








interface IPool {
    function setLastRebase(uint256 newUsdAmount) external;
}

/*
 *  CNYx ERC20
 */

contract CNYx is ERC20Detailed, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1
    uint256 private constant POINT_MULTIPLIER = 10 ** 9;

    uint256 public percentToTreasury;
    uint256 private _totalSupply;
    uint256 private _totalDividendPoints;
    uint256 private _unclaimedDividends;
    uint256 public rebaseRewardSynth;
    uint256 public debaseBoolean;   // 1 is true, 0 is false
    uint256 public lpToShareRatio;
    
    address[] public uniSyncPairs;

    uint256 private _totalDebtPoints;
    uint256 private _unclaimedDebt;
    
    ISeigniorageShares Shares;

    address public monetaryPolicy;
    address public sharesAddress;
    address public treasury;
    address public poolRewardAddress;

    bool public rebasePaused;
    bool public tenPercentCap;
    bool public lastRebasePositive;
    bool public lastRebaseNeutral;

    string private _symbol;

    mapping(address => uint256) public debtPoints;
    mapping(address => bool) public debaseWhitelist;
    mapping(address => uint256) private _synthBalances;
    mapping (address => mapping (address => uint256)) private _allowedSynth;
    
    // Modifiers
    modifier onlyShare() {
        require(msg.sender == sharesAddress, "unauthorized");
        _;
    }

    modifier onlyMonetaryPolicy() {
        require(msg.sender == monetaryPolicy, "unauthorized");
        _;
    }

    modifier whenRebaseNotPaused() {
        require(!rebasePaused, "paused");
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    modifier updateAccount(address account) {
        uint256 owing = dividendsOwing(account);
        uint256 debt = debtOwing(account);

        if (owing > 0) {
            _unclaimedDividends = owing <= _unclaimedDividends ? _unclaimedDividends.sub(owing) : 0;
            _synthBalances[account] = _synthBalances[account].add(owing);
            _totalSupply = _totalSupply.add(owing);
            emit Transfer(address(0), account, owing);
        }

        if (debt > 0) {
            _unclaimedDebt = debt <= _unclaimedDebt ? _unclaimedDebt.sub(debt) : 0;

            // only debase non-whitelisted users
            if (!debaseWhitelist[account]) {
                debt = debt <= _synthBalances[account] ? debt : _synthBalances[account];

                _synthBalances[account] = _synthBalances[account].sub(debt);
                _totalSupply = _totalSupply.sub(debt);
                emit Transfer(account, address(0), debt);
            }
        }

        emit LogClaim(account, owing);

        Shares.setSyntheticDividendPoints(address(this), account, _totalDividendPoints);
        debtPoints[account] = _totalDebtPoints;

        _;
    }

    // Events
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogContraction(uint256 indexed epoch, uint256 synthToBurn);
    event LogRebasePaused(bool paused);
    event LogClaim(address indexed from, uint256 value);
    event LogDebaseWhitelist(address user, bool value);

    // constructor ======================================================================================================
    function initialize(address owner_, uint256 initialDistribution_, address seigniorageAddress)
        public
        initializer
    {
        ERC20Detailed.initialize("Chinese Yuan Renminbi", "CNYx", uint8(DECIMALS));
        ReentrancyGuard.initialize();
        Ownable.initialize(owner_);

        rebasePaused = false;
        debaseBoolean = 1;
        _totalSupply = 100 * 10 ** DECIMALS;
        tenPercentCap = true;

        rebaseRewardSynth = 2000 * 10 ** DECIMALS;
        lpToShareRatio = 85;

        sharesAddress = seigniorageAddress;
        Shares = ISeigniorageShares(seigniorageAddress);

        // used to seed owner to create initial uniswap pool
        _synthBalances[owner_] = _synthBalances[owner_].add(100 * 10 ** DECIMALS);
        emit Transfer(address(0x0), owner_, 100 * 10 ** DECIMALS);

        disburse(initialDistribution_);
    }

    // view functions ======================================================================================================
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        uint256 debt = debtOwing(who);
        debt = debt <= _synthBalances[who] ? debt : _synthBalances[who];

        return _synthBalances[who].sub(debt);
    }

    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedSynth[owner_][spender];
    }

    function dividendsOwing(address account) public view returns (uint256) {
        if (_totalDividendPoints > Shares.lastSyntheticDividendPoints(address(this), account) && Shares.stakingStatus(account) == 1) {
            uint256 newDividendPoints = _totalDividendPoints.sub(Shares.lastSyntheticDividendPoints(address(this), account));
            uint256 sharesBalance = Shares.externalRawBalanceOf(account);
            return sharesBalance.mul(newDividendPoints).div(POINT_MULTIPLIER);
        } else {
            return 0;
        }
    }

    function debtOwing(address account) public view returns (uint256) {
        if (_totalDebtPoints > debtPoints[account] && !debaseWhitelist[account]) {
            uint256 newDebtPoints = _totalDebtPoints.sub(debtPoints[account]);
            uint256 dollarBalance = _synthBalances[account];
            return dollarBalance.mul(newDebtPoints).div(POINT_MULTIPLIER);
        } else {
            return 0;
        }
    }

    // external/public function ======================================================================================================
    function syncUniswapV2()
        external
    {
        for (uint256 i = 0; i < uniSyncPairs.length; i++) {
            (bool success, ) = uniSyncPairs[i].call(abi.encodeWithSignature('sync()'));
        }
    }

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        nonReentrant
        onlyMonetaryPolicy
        whenRebaseNotPaused
        updateAccount(tx.origin)
        returns (uint256)
    {
        if (supplyDelta == 0) {
            IPool(poolRewardAddress).setLastRebase(0);

            lastRebasePositive = false;
            lastRebaseNeutral = true;
        } else if (supplyDelta < 0) {
            lastRebasePositive = false;
            lastRebaseNeutral = false;

            IPool(poolRewardAddress).setLastRebase(0);

            if (debaseBoolean == 1) {
                negativeRebaseHelper(epoch, supplyDelta);
            }
        } else { // > 0
            positiveRebaseHelper(supplyDelta);

            emit LogRebase(epoch, _totalSupply);
            lastRebasePositive = true;
            lastRebaseNeutral = false;

            if (_totalSupply > MAX_SUPPLY) {
                _totalSupply = MAX_SUPPLY;
            }
        }

        for (uint256 i = 0; i < uniSyncPairs.length; i++) {
            (bool success, ) = uniSyncPairs[i].call(abi.encodeWithSignature('sync()'));
        }

        _synthBalances[tx.origin] = _synthBalances[tx.origin].add(rebaseRewardSynth);
        _totalSupply = _totalSupply.add(rebaseRewardSynth);
        emit Transfer(address(0x0), tx.origin, rebaseRewardSynth);

        return _totalSupply;
    }

    function transfer(address to, uint256 value)
        external
        nonReentrant
        validRecipient(to)
        updateAccount(msg.sender)
        updateAccount(to)
        returns (bool)
    {
        _synthBalances[msg.sender] = _synthBalances[msg.sender].sub(value);
        _synthBalances[to] = _synthBalances[to].add(value);
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        external
        nonReentrant
        validRecipient(to)
        updateAccount(from)
        updateAccount(to)
        returns (bool)
    {
        _allowedSynth[from][msg.sender] = _allowedSynth[from][msg.sender].sub(value);

        _synthBalances[from] = _synthBalances[from].sub(value);
        _synthBalances[to] = _synthBalances[to].add(value);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        external
        validRecipient(spender)
        returns (bool)
    {
        _allowedSynth[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedSynth[msg.sender][spender] =
            _allowedSynth[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedSynth[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedSynth[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedSynth[msg.sender][spender] = 0;
        } else {
            _allowedSynth[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedSynth[msg.sender][spender]);
        return true;
    }

    function claimDividends(address account) external updateAccount(account) returns (bool) {
        return true;
    }

    // governance functions ======================================================================================================
    function setDebaseWhitelist(address user, bool val) onlyOwner {
        debaseWhitelist[user] = val;
        emit LogDebaseWhitelist(user, val);
    }

    function changeSymbol(string memory symbol) public onlyOwner {
        _symbol = symbol;
    }

    function setRebaseRewardCNYx(uint256 reward) external onlyOwner {
        rebaseRewardSynth = reward;
    }

    function setTreasuryPercent(uint256 percent) external onlyOwner {
        require(percent <= 100 * 10 ** 9, 'percent too high');
        percentToTreasury = percent;
    }

    function setLpToShareRatio(uint256 val_)
        external onlyOwner
    {
        require(val_ <= 100);

        lpToShareRatio = val_;
    }

    function setTenPercentCap(bool _val)
        external onlyOwner
    {
        tenPercentCap = _val;
    }

    function setRebasePaused(bool paused)
        external onlyOwner
    {
        rebasePaused = paused;
        emit LogRebasePaused(paused);
    }

    function setDebaseBoolean(uint256 val_)
        external onlyOwner
    {
        require(val_ <= 1, "value must be 0 or 1");
        debaseBoolean = val_;
    }

    // owner functions
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setPoolAddress(address pool_) external onlyOwner {
        poolRewardAddress = pool_;
    }

    function setPolicyAddress(address policy_) external onlyOwner {
        monetaryPolicy = policy_;
    }

    function removeUniPair(uint256 index) external onlyOwner {
        if (index >= uniSyncPairs.length) return;

        for (uint i = index; i < uniSyncPairs.length-1; i++){
            uniSyncPairs[i] = uniSyncPairs[i+1];
        }
        uniSyncPairs.length--;
    }

    function getUniSyncPairs()
        external
        view
        returns (address[] memory)
    {
        address[] memory pairs = uniSyncPairs;
        return pairs;
    }

    function addSyncPairs(address[] memory uniSyncPairs_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < uniSyncPairs_.length; i++) {
            uniSyncPairs.push(uniSyncPairs_[i]);
        }
    }

    // internal functions ======================================================================================================
    function negativeRebaseHelper(uint256 epoch, int256 supplyDelta) internal {
        uint256 synthToDelete = uint256(supplyDelta.abs());
        if (synthToDelete > _totalSupply.div(10) && tenPercentCap) {
            synthToDelete = _totalSupply.div(10);
        }

        _totalDebtPoints = _totalDebtPoints.add(synthToDelete.mul(POINT_MULTIPLIER).div(_totalSupply));
        _unclaimedDebt = _unclaimedDebt.add(synthToDelete);
        emit LogContraction(epoch, synthToDelete);
    }

    function positiveRebaseHelper(int256 supplyDelta) internal {
        uint256 synthToTreasury = uint256(supplyDelta).mul(percentToTreasury).div(100 * 10 ** 9);
        uint256 synthToLPs = uint256(supplyDelta).sub(synthToTreasury).mul(lpToShareRatio).div(100);
        
        _synthBalances[treasury] = _synthBalances[treasury].add(synthToTreasury);
        emit Transfer(address(0x0), treasury, synthToTreasury);

        IPool(poolRewardAddress).setLastRebase(synthToLPs);
        _synthBalances[poolRewardAddress] = _synthBalances[poolRewardAddress].add(synthToLPs);
        emit Transfer(address(0x0), poolRewardAddress, synthToLPs);
        
        _totalSupply = _totalSupply.add(synthToTreasury).add(synthToLPs);

        disburse(uint256(supplyDelta).sub(synthToTreasury).sub(synthToLPs));
    }

    function disburse(uint256 amount) internal returns (bool) {
        _totalDividendPoints = _totalDividendPoints.add(amount.mul(POINT_MULTIPLIER).div(Shares.totalStaked()));
        _unclaimedDividends = _unclaimedDividends.add(amount);

        return true;
    }
}