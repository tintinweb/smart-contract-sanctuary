/**
 *Submitted for verification at Etherscan.io on 2021-02-17
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

// File: contracts/cny/cnyPoolReward.sol

pragma solidity >=0.4.24;







interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract CNYxPoolReward is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct PoolInfo {
        IERC20 lpToken;                                                 // lp token
        uint256 allocPoint;                                             // points to dictate pool ratio
        uint256 totalSynthPoints;                                       // records the total amount of Synth inputted to pool during rebases
    }

    struct UserInfo {
        uint256 amount;                                                 // LP tokens staked in pool
        uint256 lastSynthPoints;                                        // last period where user claimed synths
    }

    ICash Synth;
    PoolInfo[] public poolInfo;

    uint256 public lastReward;                                          // timestamp of the last time Synth seigniorage was deposited into this contract
    uint256 public totalAllocPoint;
    uint256 public constant POINT_MULTIPLIER = 10 ** 18;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo; // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping(address => uint256)) public lastUserAction; // pool -> user -> last action in seconds
    mapping (uint256 => uint256) public minimumStakingSeconds; // pool -> minimum seconds
    mapping (uint256 => uint256) public minimumCoolingSeconds; // pool -> minimum cooling seconds
    mapping (uint256 => mapping(address => uint256)) public lastUserCooldownAction; // pool -> user -> last cooldown action in seconds
    mapping (uint256 => mapping(address => uint256)) public userStatus; // 0 = unstaked, 1 = staked, 2 = committed

    // constructor ========================================================================
    function initialize(address owner_, address synth_)
        public
        initializer
    {
        Ownable.initialize(owner_);
        ReentrancyGuard.initialize();
        
        Synth = ICash(synth_);
    }

    // view functions ========================================================================
    function pendingReward(address _user, uint256 _poolID) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_poolID];
        UserInfo storage user = userInfo[_poolID][_user];

        uint256 userStake = user.amount;

        // no rewards for committed users
        if (pool.totalSynthPoints > user.lastSynthPoints && userStatus[_poolID][_user] != 2) {
            uint256 newDividendPoints = pool.totalSynthPoints.sub(user.lastSynthPoints);
            uint256 owedSynth =  userStake.mul(newDividendPoints).div(POINT_MULTIPLIER);

            owedSynth = owedSynth > Synth.balanceOf(address(this)) ? Synth.balanceOf(address(this)).div(2) : owedSynth;

            return owedSynth;
        } else {
            return 0;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolAllocPoints(uint256 _poolID) external view returns (uint256) {
        return poolInfo[_poolID].allocPoint;
    }

    function getStakedLP(address _user, uint256 _poolID) external view returns (uint256) {
        return userInfo[_poolID][_user].amount;
    }

    function getPoolToken(uint256 _poolID) external view returns (address) {
        return address(poolInfo[_poolID].lpToken);
    }

    // external/public function ========================================================================
    function createUniswapPool(address factory, address tokenA, address tokenB) external returns (address) {
        address pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        
        return pair;
    }

    function deposit(uint256 _poolID, uint256 _amount) external nonReentrant returns (bool) {
        // validation checks to see if sufficient LP balance
        require(userStatus[_poolID][msg.sender] != 2, 'users committed to withdraw cannot deposit');
        require(IERC20(address(poolInfo[_poolID].lpToken)).balanceOf(msg.sender) >= _amount, "insuffient balance");

        PoolInfo storage pool = poolInfo[_poolID];
        UserInfo storage user = userInfo[_poolID][msg.sender];

        require(IERC20(pool.lpToken).transferFrom(msg.sender, address(this), _amount), "LP transfer failed");

        // auto claim if user deposits more + update their lastSynthPoints
        claimRewardInternal(_poolID, msg.sender);
        user.amount = user.amount.add(_amount);

        lastUserAction[_poolID][msg.sender] = now;
        userStatus[_poolID][msg.sender] = 1;

        return true;
    }

    function setLastRebase(uint256 newSynthAmount) external {
        require(msg.sender == address(Synth), "unauthorized");
        lastReward = block.timestamp;

        if (newSynthAmount > 0) {
            for (uint256 i = 0; i < poolInfo.length; ++i) {
                PoolInfo storage pool = poolInfo[i];
                uint256 allocPoint = pool.allocPoint;
                uint256 synthAllocated = newSynthAmount.mul(allocPoint).div(totalAllocPoint);

                uint256 totalPoolLP = IERC20(address(pool.lpToken)).balanceOf(address(this));
                pool.totalSynthPoints = pool.totalSynthPoints.add(synthAllocated.mul(POINT_MULTIPLIER).div(totalPoolLP));
            }
        }
    }

    function commitToWithdraw(uint256 _poolID) external nonReentrant returns (bool) {
        UserInfo storage user = userInfo[_poolID][msg.sender];

        require(userStatus[_poolID][msg.sender] == 1 || (user.amount > 0 && userStatus[_poolID][msg.sender] != 2), 'user must be staked first');
        require(_poolID < poolInfo.length, "must use valid pool ID");
        require(lastUserAction[_poolID][msg.sender] + minimumStakingSeconds[_poolID] <= now, "must wait the minimum staking seconds for the pool before committing to withdraw");

        claimRewardInternal(_poolID, msg.sender);

        lastUserCooldownAction[_poolID][msg.sender] = now;
        userStatus[_poolID][msg.sender] = 2;

        return true;
    }   

    function withdraw(uint256 _poolID) external nonReentrant returns (bool) {
        require(userStatus[_poolID][msg.sender] == 2, "user must commit to withdrawing first");
        require(_poolID < poolInfo.length, "must use valid pool ID");
        require(lastUserCooldownAction[_poolID][msg.sender] + minimumCoolingSeconds[_poolID] <= now, "must wait the minimum cooldown seconds for the pool before withdrawing");

        claimRewardInternal(_poolID, msg.sender);

        uint256 _amount = userInfo[_poolID][msg.sender].amount;

        resetUser(_poolID, msg.sender);
        lastUserAction[_poolID][msg.sender] = now;

        require(poolInfo[_poolID].lpToken.transfer(msg.sender, _amount), "LP return transfer failed");

        userStatus[_poolID][msg.sender] = 0;

        return true;
    }

    function claimReward(uint256 _poolID, address _user) public nonReentrant returns (bool) {
        require(_user != address(0x0));
        UserInfo storage user = userInfo[_poolID][_user];
        PoolInfo storage pool = poolInfo[_poolID];

        uint256 owedSynth = pendingReward(_user, _poolID);

        if (owedSynth > 0) require(Synth.transfer(_user, owedSynth), "Synth payout failed");
        user.lastSynthPoints = pool.totalSynthPoints;

        return true;
    }

    // governance functions ========================================================================
    // add pool -> do not add same pool more than once
    function addPool(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner returns (bool) {
        require(_lpToken != address(0x0));
        totalAllocPoint = totalAllocPoint.add(_allocPoint);

        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            totalSynthPoints: 0
        }));

        return true;
    }
    
    function setPool(uint256 _poolID, uint256 _allocPoint) external onlyOwner returns (bool) {
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_poolID].allocPoint).add(_allocPoint);
        poolInfo[_poolID].allocPoint = _allocPoint;

        return true;
    }

    function setMinimumStakingSeconds(uint256 _poolID, uint256 _minSeconds) external onlyOwner {
        minimumStakingSeconds[_poolID] = _minSeconds;
    }

    function setMinimumCoolingSeconds(uint256 _poolID, uint256 _minSeconds) external onlyOwner {
        minimumCoolingSeconds[_poolID] = _minSeconds;
    }

    // internal functions ========================================================================
    function resetUser(uint256 _poolID, address _user) internal {
        UserInfo storage user = userInfo[_poolID][_user];

        user.amount = 0;
    }

    function claimRewardInternal(uint256 _poolID, address _user) internal returns (bool) {
        UserInfo storage user = userInfo[_poolID][_user];
        PoolInfo storage pool = poolInfo[_poolID];

        uint256 owedSynth = pendingReward(_user, _poolID);

        if (owedSynth > 0) require(Synth.transfer(_user, owedSynth), "Synth payout failed");
        user.lastSynthPoints = pool.totalSynthPoints;

        return true;
    }
}