// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol"; 
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

contract GridZoneStakingBot {
    using SafeMath for uint256;

    struct Stake {
        bool exists;

        uint256 stakedTs;   // timestamp when staked
        uint256 unstakedTs; // timestamp when unstaked
        uint256 stakedAmount;   // token amount user staked
        uint256 rewardAmount;   // reward amount when user unstaked
    }

    mapping(address => Stake) public stakes;
    address[] public addressIndices;

    uint256 public constant REWARD_SUPPLY = 2800000e18; // 2.8 million ZONE, 10%
    uint256 public constant STAKE_LIMIT   = 19600000e18; // 19.6 million ZONE, 70% (30% at owner’s address + 40% Crowdsale)
    uint256 public constant MIN_STAKING_AMOUNT = 1e18; // 1 ZONE
    uint256 public totalStakedAmount = 0;
    uint    public aliveUsersCount = 0;

    uint internal constant DURATION_30 = 30;
    uint internal constant DURATION_60 = 60;
    uint internal constant DURATION_90 = 90;

    /* REWARD_SUPPLY / STAKE_LIMIT / DURATION_90 / = 0.001587 */
    uint256 public constant REWARD_RATE_NUMERATOR = 1587;
    uint256 public constant REWARD_RATE_DENOMINATOR = 1e6;

    /* Time of the staking opened (ex: 1614556800 -> 2021-03-01T00:00:00Z) */
    uint256 public LAUNCH_TIME;
    
    address public vault;
    address public pendingVault;

    address public admin;
    address public pendingAdmin;

    /// @notice The address of the GridZone token
    IERC20 public zoneToken;

    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewAdmin(address indexed newAdmin);
    event NewLaunchTime(uint256 newLaunchTime);
    event NewPendingVault(address indexed newPendingVault);
    event NewVault(address indexed newVault);
    event EmergencyCall(address indexed vault, uint256 amount);
    event ReturnedRemainedToken(address indexed vault, uint256 amount);
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 stakedAmount, uint256 reward);

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier isAdmin(address _account) {
        require(admin == _account, "Restricted Access!");
        _;
    }

    constructor(address _zoneToken, address _vaultAddr) public {
        admin = msg.sender;
        vault = _vaultAddr;
        zoneToken = IERC20(_zoneToken);

        LAUNCH_TIME = block.timestamp  / 1  days * 1  days;
    }

    receive() external payable {
        assert(false); // We won't accept ETH
    }

    /* Update admin address */
    function setPendingAdmin(address _pendingAdmin) external isAdmin(msg.sender) {
        pendingAdmin = _pendingAdmin;
        emit NewPendingAdmin(pendingAdmin);
    }

    function acceptAdmin() external {
        require(msg.sender == pendingAdmin, "acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay() external view returns (uint)
    {
        return _currentDay();
    }

    function _currentDay() internal view returns (uint)
    {
        return _day(LAUNCH_TIME);
    }

    function _day(uint256 _startTs) internal view returns (uint)
    {
        if (block.timestamp < _startTs){
            return 0;
        }else{
            return (block.timestamp - _startTs) / 1 days;
        }
    }

    function isOpen() external view returns (bool) {
        return _isOpen();
    }

    function _isOpen() internal view returns (bool) {
        if (STAKE_LIMIT <= totalStakedAmount) return false;
        if (DURATION_30 <= _currentDay()) return false;
        return true;
    }

    /* Set launch time as today */
    function launchToday() external isAdmin(msg.sender) {
        require(_isOpen(), "launchToday: We can't change the launch time because already reward started.");

        LAUNCH_TIME = block.timestamp  / 1  days * 1  days;
        emit NewLaunchTime(LAUNCH_TIME);
    }

    /* Update vault address */
    function setPendingVault(address _pendingVault) external isAdmin(msg.sender) {
        pendingVault = _pendingVault;
        emit NewPendingVault(pendingVault);
    }

    function acceptVault() external {
        require(msg.sender == pendingVault, "acceptVault: Call must come from pendingVault.");
        admin = msg.sender;
        pendingVault = address(0);
        emit NewVault(vault);
    }

    /**
     * @dev PUBLIC FACING: EMERGENCY CALL: Send all tokens to the vault.
     */
    /*  */
    function emergencyCall() external isAdmin(msg.sender) {
        require(vault != address(0), "Vault address is zero");

        uint256 tokenBalance = zoneToken.balanceOf(address(this));
        if (0 < tokenBalance) {
            zoneToken.transfer(vault, tokenBalance);
        }
        emit EmergencyCall(vault, tokenBalance);
    }

    /**
     * @dev PUBLIC FACING: send the remained tokens to the vault. It can be consumed the large gas.
     */
    function returnRemainedToken() external isAdmin(msg.sender) {
        require(vault != address(0), "Vault address is zero");
        require((DURATION_30 + DURATION_90) < _currentDay(), "The reward period is not ended");

        (uint256 aliveAmounts, uint256 aliveRewards) = _calcAliveAmounts();
        uint256 aliveTokens = aliveAmounts.add(aliveRewards);

        uint256 tokenBalance = zoneToken.balanceOf(address(this));
        uint256 remainedToken = 0;
        if (aliveTokens < tokenBalance) {
            remainedToken = tokenBalance - aliveTokens;
            zoneToken.transfer(vault, remainedToken);
        }
        emit ReturnedRemainedToken(vault, remainedToken);
    }

    /**
     * @dev PUBLIC FACING: Stake the specified amount of token.
     * @param amount Number of ZONE to stake
     */
    function startStake(uint256 amount) external lock() {
        address staker = msg.sender;

        require(_isOpen(), "The staking already closed");
        require(!stakes[staker].exists, "This address already staked");
        require(MIN_STAKING_AMOUNT <= amount, "The staking amount is too small");
        require(totalStakedAmount.add(amount) <= STAKE_LIMIT, "Exceed the staking limit");

        TransferHelper.safeTransferFrom(address(zoneToken), staker, address(this), amount);

        stakes[staker] = Stake({
            exists: true,
            stakedTs: block.timestamp,
            unstakedTs: 0,
            stakedAmount: amount,
            rewardAmount: 0
        });
        addressIndices.push(staker);
        totalStakedAmount = totalStakedAmount.add(amount);
        aliveUsersCount ++;

        emit Staked(staker, amount);
    }

    function endStake() external lock() {
        address staker = msg.sender;

        require(stakes[staker].exists, "User didn't stake");
        require(stakes[staker].unstakedTs == 0, "User already unstaked");

        Stake storage stake = stakes[staker];

        uint256 amount = stake.stakedAmount;
        uint256 reward = 0;
        if (_isOpen() == false) {
            // reward started
            reward = _calcReward(stake.stakedTs, amount);
        }
        uint256 payout = amount.add(reward);
        TransferHelper.safeTransfer(address(zoneToken), staker, payout);

        stake.unstakedTs = block.timestamp;
        stake.rewardAmount = reward;

        aliveUsersCount --;

        emit Unstaked(staker, amount, reward);
    }

    function _calcReward(uint256 _stakedTs, uint256 _stakedAmount) internal view returns (uint256) {
        uint stakedDay = _day(_stakedTs);
        uint rewardDay;
        if (DURATION_90 <= stakedDay) {
            rewardDay = DURATION_90;
        } else if (DURATION_60 <= stakedDay) {
            rewardDay = DURATION_60;
        } else if (DURATION_30 <= stakedDay) {
            rewardDay = DURATION_30;
        } else {
            return 0;
        }
        return _stakedAmount.mul(rewardDay).mul(REWARD_RATE_NUMERATOR).div(REWARD_RATE_DENOMINATOR);
    }

    function getStakeInfo(address staker) external view returns (uint256 stakedAmount, uint stakedDay, uint256 rewardAmount, bool isEnded) {
        Stake memory stake = stakes[staker];
        if (stake.exists == false) {
            return (0, 0, 0, false);
        }

        stakedAmount = stake.stakedAmount;
        stakedDay = _day(stake.stakedTs);
        if (stakes[staker].unstakedTs != 0) {
            // User already unstaked
            rewardAmount = stake.rewardAmount;
            isEnded = true;
        } else {
            rewardAmount = _calcReward(stake.stakedTs, stake.stakedAmount);
            isEnded = false;
        }

        return (stake.stakedAmount, stakedDay, rewardAmount, isEnded);
    }

    function _calcAliveAmounts() internal view returns (uint256 aliveAmounts, uint256 aliveRewards) {
        uint arrayLength = addressIndices.length;
        aliveAmounts = 0;
        aliveRewards = 0;

        for (uint i = 0; i < arrayLength; i++) {
            Stake memory stake = stakes[addressIndices[i]];
            if (stake.unstakedTs == 0) {
                aliveAmounts += stake.stakedAmount;
                aliveRewards += _calcReward(stake.stakedTs, stake.stakedAmount);
            }
        }
        return (aliveAmounts, aliveRewards);
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}