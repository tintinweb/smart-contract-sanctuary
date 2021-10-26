/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;


    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {


        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;

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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

/// @notice Stake Token-ETH Uniswap LP tokens for Token rewards
contract SwitchStakingVoice is OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using SafeMath for uint256;
    using TransferHelper for address;

    address public tokenEth;
    address public token;

    uint256 public totalStakers;
    uint256 public totalRewards;
    uint256 public totalClaimedRewards;
    uint256 public startTime;
    uint256 public firstStakeTime;
    uint256 public endTime;

    uint256 private _totalStakeTokenEth;
    uint256 private _totalWeight;
    uint256 private _mostRecentValueCalcTime;

    uint256 public _stakeDivisor;

    mapping(address => uint256) public userClaimedRewards;

    mapping(address => uint256) private _userStakedTokenEth;
    mapping(address => uint256) private _userWeighted;
    mapping(address => uint256) private _userAccumulated;

    event Deposit(uint256 totalRewards, uint256 startTime, uint256 endTime);
    event Stake(address indexed staker, uint256 tokenEthIn);
    event Payout(address indexed staker, uint256 reward);
    event Withdraw(address indexed staker, uint256 tokenEthOut);
    event Refresh(uint256 totalRewards, uint256 startTime, uint256 endTime);

    /// @dev Expects a LP token address & the base reward token address
    function initialize(address _tokenEth, address _token, uint256 divisor) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        tokenEth = _tokenEth;
        token = _token;
        _stakeDivisor = divisor;
    }

    function changeDivisor(uint256 divisor) public onlyOwner {
        _stakeDivisor = divisor;
    }

    function deposit(uint256 _startTime, uint256 _endTime) public virtual onlyOwner {
        require(startTime == 0, "LiquidityMining::deposit: already received deposit");
        require(_startTime >= block.timestamp, "LiquidityMining::deposit: start time must be in future");
        require(_endTime > _startTime, "LiquidityMining::deposit: end time must after start time");
        //require(IERC20(token).balanceOf(address(this)) == _totalRewards, "LiquidityMining::deposit: contract balance does not equal expected _totalRewards");

        totalRewards = IERC20(token).balanceOf(address(this));

        //totalRewards = _totalRewards;
        startTime = _startTime;
        endTime = _endTime;

        emit Deposit(totalRewards, _startTime, _endTime);
    }

    function refreshRewards(uint256 _endTime) public onlyOwner {
        totalRewards = IERC20(token).balanceOf(address(this));
        startTime = block.timestamp;
        endTime = _endTime;

        emit Refresh(totalRewards, block.timestamp, _endTime);
    }

    function totalStake() public view returns (uint256 total) {
        total = _totalStakeTokenEth;
    }

    function totalUserStake(address user) public view returns (uint256 total) {
        total = _userStakedTokenEth[user];
    }

    modifier update() {
        if (_mostRecentValueCalcTime == 0) {
            _mostRecentValueCalcTime = firstStakeTime;
        }

        uint256 totalCurrentStake = totalStake();

        if (totalCurrentStake > 0 && _mostRecentValueCalcTime < endTime) {
            uint256 value = 0;
            uint256 sinceLastCalc = block.timestamp.sub(_mostRecentValueCalcTime);
            uint256 perSecondReward = totalRewards.div(endTime.sub(firstStakeTime));

            if (block.timestamp < endTime) {
                value = sinceLastCalc.mul(perSecondReward);
            } else {
                uint256 sinceEndTime = block.timestamp.sub(endTime);
                value = (sinceLastCalc.sub(sinceEndTime)).mul(perSecondReward);
            }

            _totalWeight = _totalWeight.add(value.mul(10**18).div(totalCurrentStake));

            _mostRecentValueCalcTime = block.timestamp;
        }

        _;
    }

    function stake(uint256 tokenEthIn) public virtual update nonReentrant {
        require(tokenEthIn > 0, "LiquidityMining::stake: missing stake");
        require(block.timestamp >= startTime, "LiquidityMining::stake: not live yet");
        require(IERC20(token).balanceOf(address(this)) > 0, "LiquidityMining::stake: no reward balance");

        if (firstStakeTime == 0) {
            firstStakeTime = block.timestamp;
        } else {
            require(block.timestamp < endTime, "LiquidityMining::stake: staking is over");
        }

        if (tokenEthIn > 0) {
            tokenEth.safeTransferFrom(msg.sender, address(this), tokenEthIn);
        }

        if (totalUserStake(msg.sender) == 0) {
            totalStakers = totalStakers.add(1);
        }

        _stake(tokenEthIn, msg.sender);

        emit Stake(msg.sender, tokenEthIn);
    }

    function withdraw() public virtual update nonReentrant returns (uint256 tokenEthOut, uint256 reward) {
        totalStakers = totalStakers.sub(1);

        (tokenEthOut, reward) = _applyReward(msg.sender);

        if (tokenEthOut > 0) {
            tokenEth.safeTransfer(msg.sender, tokenEthOut);
        }

        if (reward > 0) {
            IERC20(token).transfer(msg.sender, reward);
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);

            emit Payout(msg.sender, reward);
        }

        emit Withdraw(msg.sender, tokenEthOut);
    }

    function payout() public virtual update nonReentrant returns (uint256 reward) {
        require(block.timestamp < endTime, "LiquidityMining::payout: withdraw instead");

        (uint256 tokenEthOut, uint256 _reward) = _applyReward(msg.sender);

        reward = _reward;

        if (reward > 0) {
            IERC20(token).transfer(msg.sender, reward);
            userClaimedRewards[msg.sender] = userClaimedRewards[msg.sender].add(
                reward
            );
            totalClaimedRewards = totalClaimedRewards.add(reward);
        }

        _stake(tokenEthOut, msg.sender);

        emit Payout(msg.sender, _reward);
    }

    function _stake(uint256 tokenEthIn, address account) private {
        uint256 addBackTokenEth;

        if (totalUserStake(account) > 0) {
            (uint256 tokenEthOut, uint256 reward) = _applyReward(account);
            addBackTokenEth = tokenEthOut;
            _userStakedTokenEth[account] = tokenEthOut;
            _userAccumulated[account] = reward;
        }

        _userStakedTokenEth[account] = _userStakedTokenEth[account].add(
            tokenEthIn
        );

        _userWeighted[account] = _totalWeight;

        _totalStakeTokenEth = _totalStakeTokenEth.add(tokenEthIn);

        if (addBackTokenEth > 0) {
            _totalStakeTokenEth = _totalStakeTokenEth.add(addBackTokenEth);
        }
    }

    function _applyReward(address account) private returns (uint256 tokenEthOut, uint256 reward) {
        uint256 _totalUserStake = totalUserStake(account);
        require(_totalUserStake > 0, "LiquidityMining::_applyReward: no coins staked");

        tokenEthOut = _userStakedTokenEth[account];

        reward = _totalUserStake
                .mul(_totalWeight.sub(_userWeighted[account]))
                //.div(10**18)
                .div(calculateMultiplier(account))
                .add(_userAccumulated[account]);

        _totalStakeTokenEth = _totalStakeTokenEth.sub(tokenEthOut);

        _userStakedTokenEth[account] = 0;

        _userAccumulated[account] = 0;
    }

    function rescueTokens(address tokenToRescue, address to, uint256 amount) public virtual onlyOwner nonReentrant {
        if (tokenToRescue == tokenEth) {
            require(amount <= IERC20(tokenEth).balanceOf(address(this)).sub(_totalStakeTokenEth),
                "LiquidityMining::rescueTokens: that Token-Eth belongs to stakers"
            );
        } else if (tokenToRescue == token) {
            if (totalStakers > 0) {
                require(amount <= IERC20(token).balanceOf(address(this)).sub(totalRewards.sub(totalClaimedRewards)),
                    "LiquidityMining::rescueTokens: that token belongs to stakers"
                );
            }
        }

        IERC20(tokenToRescue).transfer(to, amount);
    }

    // stakedivisor of 2e18 = 50% starting point
    // 1e18 = max reward value
    // 2e18 - (((2e18- 1e18) * (5000 * 10e18 / 10000) / 10e18)) = 1.5e18
    function calculateMultiplier(address account) public view returns (uint256) {
        require(account != address(0), "LiquidityMining::calculateMultiplier: missing account");

        uint256 accountBaseBalance = IERC20(token).balanceOf(account);

        //amount of token in the uni contract
        uint256 liquidityContractBalance = IERC20(token).balanceOf(tokenEth);
        //total lp token supply
        uint256 liquidityContractSupply = IERC20(tokenEth).totalSupply();

        uint256 userLP = totalUserStake(account);

        uint256 lpBaseBalance = userLP.mul(liquidityContractBalance).div(liquidityContractSupply);

        if(accountBaseBalance == 0 || liquidityContractSupply == 0 || lpBaseBalance == 0){
          return _stakeDivisor;
        }

        return _stakeDivisor.sub(_stakeDivisor.sub(10**18).mul(clamp_value(accountBaseBalance.mul(10**18).div(lpBaseBalance), 10**18)).div(10**18));
    }

    function clamp_value(uint min, uint max) view public returns (uint) {
        if (min < max) {
            return min;
        } else {
            return max;
        }
    }
}