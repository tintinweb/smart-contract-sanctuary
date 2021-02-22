/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



contract RoomLPProgram {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    // TODO: Please do not forget to call the approve for this contract from the wallet.
    address public roomTokenRewardsReservoirAddress = 0x86181Ff88BDEC75d5f007cEfEE31087C8327dF77;
    address public owner;
    
    // This is ROOM/ETH LP ERC20 address.
    IERC20 public constant roomLPToken = IERC20(0xBE55c87dFf2a9f5c95cB5C07572C51fd91fe0732);

    // This is the correct CRC address of the ROOM token
    IERC20 public constant roomToken = IERC20(0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64);

    // total Room LP staked
    uint256 private _totalStaked;

    // last updated block number
    uint256 public lastUpdateBlock;

    uint256 private  _accRewardPerToken; // accumulative reward per token
    uint256 private  _rewardPerBlock;   // reward per block
    uint256 public  finishBlock; // finish rewarding block number
    uint256 public  endTime;

    mapping(address => uint256) private _rewards; // rewards balances
    mapping(address => uint256) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)
    mapping(address => uint256) private _balances; // balances per user
    
   
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 reward);
    event FarmingParametersChanged(uint256 rewardPerBlock, uint256 rewardBlockCount, address indexed roomTokenRewardsReservoirAdd);
    event RewardTransferFailed(TransferRewardState failure);
    
    enum TransferRewardState {
        Succeeded,
        RewardWalletEmpty
    }
    
    constructor () public {

        owner = msg.sender;
       
        uint256 rewardBlockCount = 1036800;  // 5760 * 30 * 6; six months = 1,036,800 blocks
        uint256 totalRewards = 240000e18;  // total rewards 240,000 Room in six months
       
        _rewardPerBlock = totalRewards * (1e18) / rewardBlockCount; // *(1e18) for math precisio
        
        finishBlock = blockNumber() + rewardBlockCount;
        endTime = ((finishBlock-blockNumber()) * 15) + (block.timestamp);
        lastUpdateBlock = blockNumber();
    }

    function changeFarmingParameters(uint256 rewardPerBlock, uint256 rewardBlockCount, address roomTokenRewardsReservoirAdd) external {

        require(msg.sender == owner, "can be called by owner only");
        updateReward(address(0));
        _rewardPerBlock = rewardPerBlock.mul(1e18); // for math precision
        
        finishBlock = blockNumber().add(rewardBlockCount);
        endTime = finishBlock.sub(blockNumber()).mul(15).add(block.timestamp);
        roomTokenRewardsReservoirAddress = roomTokenRewardsReservoirAdd;

        emit FarmingParametersChanged(_rewardPerBlock, rewardBlockCount, roomTokenRewardsReservoirAddress);
    }

    function updateReward(address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalStaked is zero; do not increment accRewardPerToken
        if (totalStaked() > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock) {
                _accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
                .mul(_rewardPerBlock)
                .div(totalStaked())
                .add(_accRewardPerToken);
            }
        }

        lastUpdateBlock = cnBlock;

        if (account != address(0)) {

            uint256 accRewardPerTokenForUser = _accRewardPerToken.sub(_prevAccRewardPerToken[account]);

            if (accRewardPerTokenForUser > 0) {
                _rewards[account] =
                _balances[account]
                .mul(accRewardPerTokenForUser)
                .div(1e18)
                .add(_rewards[account]);

                _prevAccRewardPerToken[account] = _accRewardPerToken;
            }
        }
    }

    function stake(uint256 amount) external {
        updateReward(msg.sender);

        _totalStaked = _totalStaked.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // Transfer from owner of Room Token to this address.
        roomLPToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount, bool claim) external returns(uint256 reward, TransferRewardState reason) {
        updateReward(msg.sender);


        _totalStaked = _totalStaked.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        // Send Room token staked to the original owner.
        roomLPToken.safeTransfer(msg.sender, amount);
       

        if (claim) {
          (reward, reason) = _executeRewardTransfer(msg.sender);
        }
        
         emit Unstaked(msg.sender, amount);
    }
    
    function claimReward() external returns (uint256 reward, TransferRewardState reason) {
        updateReward(msg.sender);

        return _executeRewardTransfer(msg.sender);
    }
    
    function _executeRewardTransfer(address account) internal returns(uint256 reward, TransferRewardState reason) {
        
        reward = _rewards[account];
        if (reward > 0) {
            uint256 walletBalanace = roomToken.balanceOf(roomTokenRewardsReservoirAddress);
            if (walletBalanace < reward) {
                // This fails, and we send reason 1 for the UI
                // to display a meaningful message for the user.
                // 1 means the wallet is empty.
                reason = TransferRewardState.RewardWalletEmpty;
                emit RewardTransferFailed(reason);
                
            } else {
                
                // We will transfer and then empty the rewards
                // for the sender.
                _rewards[msg.sender] = 0;
                roomToken.transferFrom(roomTokenRewardsReservoirAddress, msg.sender, reward);
                emit ClaimReward(msg.sender, reward);
            }
        }
    }

    function rewards(address account) external view returns (uint256 reward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken;

        // update accRewardPerToken, in case totalStaked is zero; do not increment accRewardPerToken
        if (totalStaked() > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock) {
                accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
                .mul(_rewardPerBlock).div(totalStaked())
                .add(accRewardPerToken);
            }
        }

        reward = _balances[account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[account]))
        .div(1e18)
        .add(_rewards[account]);
    }

    function info() external view returns (
                                uint256 cBlockNumber, 
                                uint256 rewardPerBlock,
                                uint256 rewardFinishBlock,
                                uint256 rewardEndTime,
                                uint256 walletBalance) {
        cBlockNumber = blockNumber();
        rewardFinishBlock = finishBlock;
        rewardPerBlock = _rewardPerBlock.div(1e18);
        rewardEndTime = endTime;
        walletBalance = roomToken.balanceOf(roomTokenRewardsReservoirAddress);
    }

    // expected reward,
    // please note this is only an estimation, because total balance may change during the program
    function expectedRewardsToday(uint256 amount) external view returns (uint256 reward) {

        uint256 cnBlock = blockNumber();
        uint256 prevAccRewardPerToken = _accRewardPerToken;

        uint256 accRewardPerToken = _accRewardPerToken;
        // update accRewardPerToken, in case totalStaked is zero do; not increment accRewardPerToken

        uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
        if (lastRewardBlock > lastUpdateBlock) {
            accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock)
            .mul(_rewardPerBlock).div(totalStaked().add(amount))
            .add(accRewardPerToken);
        }

        uint256 rewardsPerBlock = amount
        .mul(accRewardPerToken.sub(prevAccRewardPerToken))
        .div(1e18);

        
        reward = rewardsPerBlock.mul(5760); // 5760 blocks per day
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function blockNumber() public view returns (uint256) {
        return block.number;
    }
}