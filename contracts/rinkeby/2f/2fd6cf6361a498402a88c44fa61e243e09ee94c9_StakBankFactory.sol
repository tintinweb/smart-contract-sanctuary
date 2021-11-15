// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./StakBank.sol";
import "./interfaces/IStakBank.sol";
import "./interfaces/IJSTAK.sol";
import "./libraries/Initializable.sol";
import "./libraries/Pausable.sol";
import "./libraries/SafeMath.sol";

contract StakBankFactory is Pausable, Initializable {
    using SafeMath for uint256;

    // Array of created Pools Address
    address[] public allStakBanks;

    // JStak token address
    IJSTAK public jStak;

    // Mapping from User token. From tokens to array of created StakBank for token
    mapping(address => mapping(IERC20 => address[])) public getStakBanks;

    event JStakChanged(IJSTAK jStak);
    event StakBankCreated(
        address registedBy,
        address indexed stakingToken,
        address indexed rewardToken,
        IJSTAK jStak,
        address indexed pool,
        uint256 poolId
    );

    function initialize(IJSTAK _jStak) public initializer {
        require(_jStak != IJSTAK(0), "StakBankFactory::ZERO_ADDRESS");

        jStak = _jStak;
        owner = _msgSender();
        paused = false;
    }

    /**
     * @notice Get the number of all created pools
     * @return Return number of created polls
     */
    function allStakBanksLength() public view returns (uint256) {
        return allStakBanks.length;
    }

    /**
     * @notice Get the created pool by staking token address
     * @dev User can retrieve their created pool by address of staking tokens
     * @param _creator Address of created pool user
     * @param _stakingToken Address of staking token want to query
     * @return Created StakBanks Address
     */
    function getCreatedStakBanksByToken(address _creator, IERC20 _stakingToken)
        public
        view
        returns (address[] memory)
    {
        return getStakBanks[_creator][_stakingToken];
    }

    /**
     * @notice Retrieve number of pools created for specific token
     * @param _creator Address of created pool user
     * @param _stakingToken Address of staking token want to query
     * @return Return number of created LPBank
     */
    function getCreatedStakBanksLengthByToken(
        address _creator,
        IERC20 _stakingToken
    ) public view returns (uint256) {
        return getStakBanks[_creator][_stakingToken].length;
    }

    /**
     * @notice Owner can set the JStak contract(IERC20)
     * @param _token Address of the new jStak token
     */
    function setJStakTokenContract(IJSTAK _token) external onlyOwner {
        jStak = _token;
        emit JStakChanged(_token);
    }

    /**
     * @notice Register Pool
     * @dev To register, you MUST have an ERC20 token for reward token
     * @param _name String name of new StakBank
     * @param _stakingToken address of ERC20 staking token users will deposit
     * @param _rewardToken address of ERC20 reward token to distribute as rewards
     */
    function registerStakBank(
        string memory _name,
        IERC20 _stakingToken,
        IERC20 _rewardToken
    ) external whenNotPaused onlyOwner returns (address pool) {
        require(
            _stakingToken != IERC20(address(0)),
            "StakBankFactory::ZERO_ADDRESS"
        );
        require(
            _rewardToken != IERC20(address(0)),
            "StakBankFactory::ZERO_ADDRESS"
        );
        bytes memory tempNameString = bytes(_name);
        require(tempNameString.length != 0, "StakBankFactory::NO_NAME");

        bytes memory bytecode = type(StakBank).creationCode;
        uint256 tokenIndex = getCreatedStakBanksLengthByToken(
            _msgSender(),
            _stakingToken
        );
        bytes32 salt = keccak256(
            abi.encodePacked(_msgSender(), _stakingToken, tokenIndex)
        );
        assembly {
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(pool)) {
                revert(0, 0)
            }
        }
        IStakBank(pool).initialize(_name, _stakingToken, _rewardToken, jStak);
        getStakBanks[_msgSender()][_stakingToken].push(pool);
        allStakBanks.push(pool);
        jStak.grantJStakRole(pool);

        emit StakBankCreated(
            _msgSender(),
            address(_stakingToken),
            address(_rewardToken),
            jStak,
            pool,
            allStakBanks.length - 1
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./interfaces/IStakBank.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IJSTAK.sol";
import "./libraries/ReentrancyGuard.sol";
import "./libraries/Pausable.sol";
import "./libraries/Math.sol";
import "./libraries/SafeERC20.sol";

contract StakBank is ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // -----------------------------------------
    // STATE VARIABLES
    // -----------------------------------------

    // Token being disitributed
    IERC20 public rewardToken;

    // Token being staked
    IERC20 public stakingToken;

    // JStak token address
    IJSTAK public jStak;

    // Address of factory contract
    address public factory;

    // Name of POOL
    string public name;

    // Timestamp when pool finish
    uint256 public periodFinish;

    // Distribution per second of tokens rate
    uint256 public rewardRate;

    // Last timestamp pool was updated
    uint256 public lastUpdateTime;

    // Amount of reward per token staked
    uint256 public rewardPerTokenStored;

    // Amount of tokens being distributed
    uint256 public totalReward;

    // Amount of tokens staked
    uint256 private _totalSupply;

    // User struct to store rewards
    struct UserInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
        uint256 baseDate;
    }

    // User reward mapping
    mapping(address => UserInfo) public userInfo;

    // User stakes mapping
    mapping(address => uint256) private _balances;

    // -----------------------------------------
    // EVENTS
    // -----------------------------------------

    event PoolCreated(string name, address stakingToken, address rewardToken);
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Composed(address indexed user, uint256 reward, uint256 jStakReward);
    event RewardPaid(address indexed user, uint256 reward, uint256 jStakReward);

    // -----------------------------------------
    // MODIFIER
    // -----------------------------------------

    /**
     * @notice Update user rewards when call mutative functions
     * @param _account Address to update user rewards
     */
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userInfo[_account].rewards = earned(_account);
            userInfo[_account].userRewardPerTokenPaid = rewardPerTokenStored;
        }
        _;
    }

    // -----------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------
    constructor() {
        factory = _msgSender();
    }

    /**
     * @param _name Name of POOL
     * @param _stakingToken Address of the token being staked
     * @param _rewardToken Address of the token being disitributed
     */
    function initialize(
        string calldata _name,
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        IJSTAK _jStak
    ) external {
        require(_msgSender() == factory, "STAKBANK::UNAUTHORIZED");

        name = _name;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        jStak = _jStak;
        owner = tx.origin;
        paused = false;

        emit PoolCreated(name, address(stakingToken), address(rewardToken));
    }

    // -----------------------------------------
    // VIEWS
    // -----------------------------------------

    /**
     * @notice Returns the last latest timestamp of reward applicable
     * @return Returns blocktimestamp if < periodFinish
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Retunrs the reward per token staked rate in range of timestamp
     * @return Returns amount of tokens is distributed per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    /**
     * @notice Returns the earned tokens of an address
     * @param _account Address to find the amount of tokens
     * @return Returns amount of tokens the user earned
     */
    function earned(address _account) public view returns (uint256) {
        return
            balanceOf(_account)
                .mul(
                rewardPerToken().sub(userInfo[_account].userRewardPerTokenPaid)
            ).div(1e18)
                .add(userInfo[_account].rewards);
    }

    /**
     * @notice Returns the total amount of tokens staked in the contract
     * @return Returns only a fixed number of supply
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns the total amount of tokens of an address staked in the contract
     * @param _account Address to find the amount of tokens
     * @return Returns amount of tokens the user staked
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    /**
     * @notice Returns the multiplier of earns of an address
     * @param _account Address to find the multiplier
     * @return Returns the number of multiplier based on timestamp
     */
    function getMultiplier(address _account) public view returns (uint256) {
        uint256 multiplier;
        // get account base date
        uint256 baseDate = userInfo[_account].baseDate;
        // get elapsed seconds
        uint256 secondsElapsed = block.timestamp.sub(baseDate);
        // transform to elaspsed months
        uint256 integerMonthsElapsed = secondsElapsed
        .sub(secondsElapsed.mod(30 days))
        .div(30 days);

        // here we should match a uint256 month to a uint256 multiplier represented by a percentage
        if (integerMonthsElapsed == 2) {
            multiplier = 110;
        } else if (integerMonthsElapsed == 3) {
            multiplier = 120;
        } else if (integerMonthsElapsed == 4) {
            multiplier = 130;
        } else if (integerMonthsElapsed == 5) {
            multiplier = 140;
        } else if (integerMonthsElapsed == 6) {
            multiplier = 150;
        } else if (integerMonthsElapsed == 7) {
            multiplier = 160;
        } else if (integerMonthsElapsed == 8) {
            multiplier = 170;
        } else if (integerMonthsElapsed == 9) {
            multiplier = 180;
        } else if (integerMonthsElapsed == 10) {
            multiplier = 190;
        } else if (integerMonthsElapsed >= 11) {
            multiplier = 200;
        } else multiplier = 0;

        return multiplier;
    }

    /**
     * @notice Returns the base date of an address
     * @param _account Address to find the base date
     * @return Returns timestamp of base date of an address
     */
    function getBaseDate(address _account) external view returns (uint256) {
        return userInfo[_account].baseDate;
    }

    /**
     * @notice Returns the remaining tokens to reward
     * @return eturns amount of remaining tokens to be distributed
     */
    function getRemainingTotalReward() public view returns (uint256) {
        if (periodFinish >= block.timestamp) {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            return leftover;
        } else {
            return 0;
        }
    }

    // -----------------------------------------
    // MUTATIVE FUNCTIONS
    // -----------------------------------------

    /**
     * @notice User can stake token by this function when available
     * @param _amount Value of tokens in wei involved in the staking
     */
    function stake(uint256 _amount)
        public
        whenNotPaused
        nonReentrant
        updateReward(_msgSender())
    {
        require(_amount > 0, "STAKBANK::EMPTY_AMOUNT");
        _totalSupply = _totalSupply.add(_amount);
        _balances[_msgSender()] = _balances[_msgSender()].add(_amount);
        stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);

        if (userInfo[_msgSender()].baseDate == 0) {
            userInfo[_msgSender()].baseDate = block.timestamp;
        } else {
            updateBaseDate(_amount, _msgSender());
        }
        emit Staked(_msgSender(), _amount);
    }

    /**
     * @notice User can withdraw token by this function when available
     * @param _amount Value of tokens in wei involved in the withdraw
     */
    function withdraw(uint256 _amount)
        public
        whenNotPaused
        nonReentrant
        updateReward(_msgSender())
    {
        require(_amount > 0, "STAKBANK::EMPTY_AMOUNT");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[_msgSender()] = _balances[_msgSender()].sub(_amount);
        stakingToken.safeTransfer(_msgSender(), _amount);
        // reset user baseDate
        userInfo[_msgSender()].baseDate = block.timestamp;
        emit Withdrawn(_msgSender(), _amount);
    }

    /**
     * @notice User can exit from pool by withdrawing and getting reward by this function when available
     */
    function exit() external {
        withdraw(balanceOf(_msgSender()));
        getReward();
    }

    /**
     * @notice User can compound your tokens into the pool
     */
    function compound()
        public
        whenNotPaused
        nonReentrant
        updateReward(_msgSender())
    {
        uint256 reward = earned(_msgSender());
        uint256 jStakReward = reward.mul(getMultiplier(_msgSender())).div(100);
        require(reward > 0, "STAKBANK::ZERO_REWARD_AMOUNT");
        userInfo[_msgSender()].rewards = 0;
        _totalSupply = _totalSupply.add(reward);
        _balances[_msgSender()] = _balances[_msgSender()].add(reward);
        jStak.mint(_msgSender(), jStakReward);
        updateBaseDate(reward, _msgSender());

        emit Composed(_msgSender(), reward, jStakReward);
    }

    /**
     * @notice User can get the reward by this function when available
     */
    function getReward()
        public
        whenNotPaused
        nonReentrant
        updateReward(_msgSender())
    {
        uint256 reward = earned(_msgSender());
        if (reward > 0) {
            uint256 jStakReward = reward.mul(getMultiplier(_msgSender())).div(
                100
            );
            userInfo[_msgSender()].rewards = 0;
            rewardToken.safeTransfer(_msgSender(), reward);
            jStak.mint(_msgSender(), jStakReward);
            emit RewardPaid(_msgSender(), reward, jStakReward);
        }
    }

    // -----------------------------------------
    // INTERNAL FUNCTIONS
    // -----------------------------------------

    /**
     * @notice Update the base date of an user
     * @param _amount Address performing the staking
     * @param _account Amount of token in wei involved in the staking
     */
    function updateBaseDate(uint256 _amount, address _account) internal {
        uint256 oldBaseDate = userInfo[_account].baseDate;
        uint256 oldStake = balanceOf(_account);
        // weighted average following: [(oldBaseDate * oldStake) + (now * deposit)]/(oldStake + deposit)
        uint256 newBaseDate = (
            (oldBaseDate.mul(oldStake)).add(block.timestamp.mul(_amount))
        )
        .div(oldStake.add(_amount));
        userInfo[_account].baseDate = newBaseDate;
    }

    // -----------------------------------------
    // RESTRICTED FUNCTIONS
    // -----------------------------------------

    /**
     * @notice Owner should call it after deposit the tokens in the contract and set duration.
     * @param _reward Amount of token in wei that will be distributed
     * @param _duration Value in uint256 determine the duration of the pool
     */
    function notifyRewardAmount(uint256 _reward, uint256 _duration)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            require(_duration > 0, "LPBANK::INVALID_DURATION");
            rewardRate = _reward.div(_duration);
            totalReward = _reward;
        } else if (_duration == 0) {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(remaining);
            totalReward = totalReward.add(_reward);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = _reward.add(leftover).div(_duration);
            totalReward = totalReward.add(_reward);
        }

        periodFinish = block.timestamp.add(_duration);
        lastUpdateTime = block.timestamp;
        emit RewardAdded(_reward);
    }

    /**
     * @notice Owner can set the reward token contract(IERC20)
     * @param _token Address of the new reward token
     */
    function setRewardTokenContract(IERC20 _token) external onlyOwner {
        rewardToken = _token;
    }

    /**
     * @notice Owner can set the staking token contract(IERC20)
     * @param _token Address of the new staking token
     */
    function setStakingTokenContract(IERC20 _token) external onlyOwner {
        stakingToken = _token;
    }

    /**
     * @notice Owner can finish the pool and collect the remaining rewards
     */
    function endPoolAndCollectRemainingRewards() external onlyOwner {
        rewardToken.safeTransfer(owner, getRemainingTotalReward());
        periodFinish = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./IJSTAK.sol";

interface IStakBank {
    function initialize(
        string memory _name,
        IERC20 _lpToken,
        IERC20 _rewardToken,
        IJSTAK _jStak
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IJSTAK {
    function mint(address to, uint256 amount) external returns (bool);

    function grantJStakRole(address _address) external returns (bool);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "./Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "CONTRACT_PAUSED");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "CONTRACT_NOT_PAUSED");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(
                data,
                "SafeERC20: low-level call failed"
            );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Context {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_msgSender() == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

