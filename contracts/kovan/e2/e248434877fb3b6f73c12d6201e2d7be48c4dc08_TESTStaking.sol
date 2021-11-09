/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
	event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
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
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TESTStaking is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	
	address public devAddress; 
	address public treasuryAddress; 
	
	uint256 private _decimalConverter = 10**18;
	uint256 private _divRate = 10000;
	uint256 private _weiDecimal = 18;
	
	struct PoolList{
		address token;
		address tokenReward;
		uint256 devFee;
		uint256 treasuryFee;
		uint256 rewardBlock;
		uint256 rewardRemains;
		uint256 total;
		uint256 totalusers;
		uint256 totalPendingReward;
		uint256 poolLastBlockUpdate;
		uint256 minDeposit;
		uint256 lockPeriod;
		bool pollActive;
	}
	
	struct UserList {
        uint256 blockStart; 
        uint256 stakingAmount;
        uint256 pendingReward;
        uint256 claimReward;
        uint256 lockPeriod;
    }
			
	PoolList[] public poolList;
	mapping(uint => address[]) private pooldatas;
	mapping (uint256 => mapping (address => UserList)) public userList;
	mapping(address => bool) public existingPools;
	
	constructor(address _devAddress, address _treasuryAddress) public Ownable() {	
		devAddress = _devAddress;
		treasuryAddress = _treasuryAddress;
	}

	function addPool(address _token,address _tokenReward, uint256 _devFee, uint256 _treasuryFee, uint256 _rewardBlock, uint256 _rewardRemains, uint256 _minDeposit, uint256 _lockPeriod) external onlyOwner {
		require(existingPools[_token] != true, "pool exists");
		require(_devFee <= 200, "devFee can not more than 2%");	
		require(_treasuryFee <= 500, "treasuryFee can not more than 5%");
		require(_rewardBlock <= 9 * 10**14, "Reward cannot set over 9e14"); 
		
		poolList.push(PoolList(
			_token
			, _tokenReward
			, _devFee
			, _treasuryFee
			, _rewardBlock
			, _rewardRemains
			, 0
			, 0
			, 0
			, block.number
			, _minDeposit
			, _lockPeriod
			, true
		));
				
		existingPools[_token] = true;
	}
	
	function stake(uint256 _pid, uint256 _amount) external nonReentrant {    
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		PoolList storage pool = poolList[_pid];
		UserList storage user = userList[_pid][msg.sender];
				
		require(pool.pollActive == true, "pool closed");
		require(_amount >= pool.minDeposit, "deposit less than minimum");
		
		IERC20(pool.token).safeTransferFrom(msg.sender, address(this), _getTokenAmount(pool.token,_amount));
						
		pool.total += _amount;				
			
		if(user.stakingAmount > 0){
			user.pendingReward = pendingRewardsFromPool(_pid,msg.sender);
		} else {
			pool.totalusers += 1;
			pooldatas[_pid].push(msg.sender);
		}
		user.stakingAmount += _amount;
		user.blockStart = block.number;
		user.lockPeriod = now + pool.lockPeriod;
		
		emit Staked(msg.sender, address(pool.token) ,_amount);
	}
		
	function _updatePool(uint256 _pid) internal {
		PoolList storage pool = poolList[_pid];
		
		if(pool.total > 0){
			uint256 rewardRemains = pool.rewardRemains - pool.totalPendingReward;
			uint256 TotalShare = percent(pool.total, _decimalConverter, 4);
			uint256 blockRemain = 0;
			uint256 totalPendingReward = 0;
			
			if(block.number > pool.poolLastBlockUpdate){			
				blockRemain = block.number - pool.poolLastBlockUpdate;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
			}
			
			if(rewardRemains < totalPendingReward){
				blockRemain = rewardRemains.div(((TotalShare.mul(pool.rewardBlock).div(_divRate)))) - 1;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
				pool.pollActive = false;
			}
			
			pool.totalPendingReward += totalPendingReward;
			pool.poolLastBlockUpdate += blockRemain;
		} else {
			pool.poolLastBlockUpdate = block.number;
		}
	}
				
	function TotalPool() public view returns (uint256) {
		return poolList.length;
	}
	
	function pendingRewardsFromPool(uint256 _pid, address _user) public view returns (uint256) {
		PoolList memory pool = poolList[_pid];
		UserList memory user = userList[_pid][_user];

		if(user.stakingAmount > 0){
			uint256 rewardRemains = pool.rewardRemains - pool.totalPendingReward;
			uint256 TotalShare = percent(pool.total, _decimalConverter, 4);
			uint256 blockRemain = 0;
			uint256 totalPendingReward = 0;
			
			if(block.number > pool.poolLastBlockUpdate){			
				blockRemain = block.number - pool.poolLastBlockUpdate;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
			}
			
			if(rewardRemains < totalPendingReward){
				blockRemain = rewardRemains.div(((TotalShare.mul(pool.rewardBlock).div(_divRate)))) - 1;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
				pool.pollActive = false;
			}
			
			pool.totalPendingReward += totalPendingReward;
			pool.poolLastBlockUpdate += blockRemain;
			
			TotalShare = percent(user.stakingAmount, _decimalConverter, 4);
		
			if(pool.poolLastBlockUpdate > user.blockStart){
				blockRemain = pool.poolLastBlockUpdate - user.blockStart;
				user.pendingReward += (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
			}
		}	
		
		return user.pendingReward;
	}
	
	function claim(uint256 _pid) public nonReentrant {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		uint256 rewardAmount = pendingRewardsFromPool(_pid,msg.sender);
		require(rewardAmount > 0, "not have claimable reward");
		
		_claim(_pid, msg.sender);
	}
	
	function _claim(uint256 _pid, address account) internal {
		UserList storage user = userList[_pid][account];
		PoolList storage pool = poolList[_pid];	
		
		uint256 rewardAmount = pendingRewardsFromPool(_pid,msg.sender);
		uint256 claimAmount = rewardAmount;
		
		if(rewardAmount > 0){
			if(pool.devFee > 0){
				uint256 devAmount = rewardAmount * pool.devFee / _divRate;
				IERC20(pool.tokenReward).safeTransfer(devAddress, _getTokenAmount(pool.tokenReward,devAmount));
				claimAmount -= devAmount;
				emit DevFee(account, devAmount);
			}
			
			if(pool.treasuryFee > 0){
				uint256 treasuryAmount = rewardAmount * pool.treasuryFee / _divRate;
				IERC20(pool.tokenReward).safeTransfer(treasuryAddress, _getTokenAmount(pool.tokenReward,treasuryAmount));
				claimAmount -= treasuryAmount;
				emit treasuryFee(account, treasuryAmount);
			}
			
			IERC20(pool.tokenReward).safeTransfer(account, _getTokenAmount(pool.tokenReward,claimAmount));
				
			emit ClaimReward(account ,claimAmount);
			
			pool.rewardRemains -= rewardAmount;
			pool.totalPendingReward -= rewardAmount;
			user.claimReward += rewardAmount;
			user.pendingReward = 0;
		}
		
		user.blockStart = block.number;
	}
		
	function withdraw(uint256 _pid) public nonReentrant {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		UserList storage user = userList[_pid][msg.sender];
		PoolList storage pool = poolList[_pid];	
				
		require(user.stakingAmount > 0, "not have withdrawn balance");
		require(now > user.lockPeriod, "in locked period");
		
		_claim(_pid, msg.sender);
				
		IERC20(pool.token).safeTransfer(msg.sender, _getTokenAmount(pool.token,user.stakingAmount));
		
		emit Withdraw(msg.sender, address(pool.token) ,user.stakingAmount);
		
		pool.total -= user.stakingAmount;
		user.stakingAmount = 0;		
		user.blockStart = block.number;
		
		pool.totalusers -= 1;
		for(uint256 i = 0; i < pooldatas[_pid].length; i++) {
			if(pooldatas[_pid][i] == msg.sender){
				delete pooldatas[_pid][i];
				i = pooldatas[_pid].length;
			}
		}
	}
	
	function withdrawWithoutReward(uint256 _pid) public nonReentrant {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		UserList storage user = userList[_pid][msg.sender];
		PoolList storage pool = poolList[_pid];	
				
		require(user.stakingAmount > 0, "not have withdrawn balance");
		require(now > user.lockPeriod, "lock period");
		
		user.pendingReward = pendingRewardsFromPool(_pid,msg.sender);
						
		IERC20(pool.token).safeTransfer(msg.sender, _getTokenAmount(pool.token,user.stakingAmount));
		
		emit WithdrawWithoutReward(msg.sender, address(pool.token) ,user.stakingAmount);
		
		pool.total -= user.stakingAmount;
		pool.totalPendingReward -= user.pendingReward;
		user.pendingReward -= user.pendingReward;
		user.stakingAmount = 0;
		user.blockStart = block.number;
		
		pool.totalusers -= 1;
		for(uint256 i = 0; i < pooldatas[_pid].length; i++) {
			if(pooldatas[_pid][i] == msg.sender){
				delete pooldatas[_pid][i];
				i = pooldatas[_pid].length;
			}
		}
	}
	
	function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {
		uint _numerator  = numerator * 10 ** (precision+1);
		uint _quotient =  ((_numerator / denominator) + 5) / 10;
		return ( _quotient);
	}
	
	function _updateUsers(uint256 _pid) internal {
		address _user;
		
		_updatePool(_pid);
		
		for(uint256 i = 0; i < pooldatas[_pid].length; i++){
			_user = pooldatas[_pid][i];
			if(_user != address(0)){
				userList[_pid][_user].pendingReward = pendingRewardsFromPool(_pid,_user);
				userList[_pid][_user].blockStart = block.number;
			}
		}
	}
	
	function updateReward(uint _pid, uint256 _rewardBlock) external onlyOwner {
		PoolList storage pool = poolList[_pid];
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		require(_rewardBlock <= 9 * 10**14, "Reward cannot set over 9e14");
		
		_updateUsers(_pid);
		
		pool.rewardBlock = _rewardBlock;
	}

	function addRewardSupply(uint _pid, uint256 _addAmount) external onlyOwner {
		PoolList storage pool = poolList[_pid];
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		pool.rewardRemains += _addAmount;
		pool.pollActive = true;
		
		_updatePool(_pid);
	}

	function decreaseRewardSupply(uint _pid, uint256 _decreaseAmount) external onlyOwner {
		PoolList storage pool = poolList[_pid];
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		
		_updatePool(_pid);
		
		require(pool.rewardRemains - pool.totalPendingReward > _decreaseAmount, "Cant Decrease Reward Remains");
				
		pool.rewardRemains -= _decreaseAmount;
	}

	function updatePoolFee(uint _pid, uint256 _devFee, uint256 _treasuryFee) external onlyOwner {
		PoolList storage pool = poolList[_pid];
		
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");
		require(_devFee <= 200, "devFee can not more than 2%");	
		require(_treasuryFee <= 500, "treasuryFee can not more than 5%");
		_updatePool(_pid);
		
		pool.devFee = _devFee;
		pool.treasuryFee = _treasuryFee;
	}

	function updateAddress(address _devAddress, address _treasuryAddress) external onlyOwner {
		devAddress = address(_devAddress);
		treasuryAddress = address(_treasuryAddress);
	}
	
	function _getTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IERC20 tokenAddress = IERC20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff = 0;
		uint256 decimalDiffConverter = 0;
		uint256 amount = 0;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
	
	function _getReverseTokenAmount(address _tokenAddress, uint256 _amount) internal view returns (uint256 quotient) {
		IERC20 tokenAddress = IERC20(_tokenAddress);
		uint256 tokenDecimal = tokenAddress.decimals();
		uint256 decimalDiff = 0;
		uint256 decimalDiffConverter = 0;
		uint256 amount = 0;
			
		if(_weiDecimal != tokenDecimal){
			if(_weiDecimal > tokenDecimal){
				decimalDiff = _weiDecimal - tokenDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.mul(decimalDiffConverter);
			} else {
				decimalDiff = tokenDecimal - _weiDecimal;
				decimalDiffConverter = 10**decimalDiff;
				amount = _amount.div(decimalDiffConverter);
			}		
		} else {
			amount = _amount;
		}
		
		uint256 _quotient = amount;
		
		return (_quotient);
    }
	
	event Staked(address indexed user, address token, uint256 amount);
	event ClaimReward(address indexed user, uint256 amount);
	event treasuryFee(address indexed user, uint256 amount);
	event DevFee(address indexed user, uint256 amount);
	event Withdraw(address indexed user, address token, uint256 amount);
	event WithdrawWithoutReward(address indexed user, address token, uint256 amount);
}