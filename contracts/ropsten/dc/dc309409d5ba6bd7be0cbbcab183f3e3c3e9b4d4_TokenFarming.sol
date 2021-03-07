/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

interface TokenReward {
	function generateReward(address account, uint256 amount) external;
}

contract TokenFarming is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	TokenReward public tokenReward;
	address public devAddress;
    address private _reward_token;
    
	uint256 private _decimalConverter = 10**18;
	uint256 private _divRate = 10000;
    

	struct PoolList{
		string pool_name;
		IERC20 lptoken;
		bool poolActive;
		uint256 devFee;
		uint256 rewardBlock;
		uint256 rewardRemains;
		uint256 lptotal;
		uint256 totalusers;
		uint256 totalPendingReward;
		uint256 poolLastBlockUpdate;
	}

	struct UserList {
        uint256 blockStart;
        uint256 stakingAmount;
        uint256 pendingReward;
        uint256 claimReward;
    }

	PoolList[] public poolList;
	mapping(uint => address[]) private pooldatas;
	mapping (uint256 => mapping (address => UserList)) public userList;
	mapping(address => bool) public existingPools;

	constructor(address _tokenReward) public Ownable() {
	    _reward_token = _tokenReward;
		tokenReward = TokenReward(_tokenReward);
		devAddress = msg.sender;
	}

	function addPool(string calldata _pool_name, address _lptoken, uint256 _devFee, uint256 _rewardBlock, uint256 _rewardRemains) external onlyOwner {
		require(existingPools[_lptoken] != true, "pool exists");

		poolList.push(PoolList(
			_pool_name
			, IERC20(_lptoken)
			, true
			, _devFee
			, _rewardBlock
			, _rewardRemains
			, 0
			, 0
			, 0
			, block.number
		));

		existingPools[_lptoken] = true;
	}

	function stakeLP(uint256 _pid, uint256 _amount) external nonReentrant {
		require(_amount > 0, "deposit something");

		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");

		_updatePool(_pid);

		PoolList storage pool = poolList[_pid];
		UserList storage user = userList[_pid][msg.sender];

		require(pool.poolActive == true, "pool closed");

		pool.lptoken.safeTransferFrom(msg.sender, address(this), _amount);

		pool.lptotal += _amount;

		if(user.stakingAmount > 0){
			user.pendingReward = pendingRewardsFromPool(_pid,msg.sender);
		} else {
			pool.totalusers += 1;
			pooldatas[_pid].push(msg.sender);
		}
		user.stakingAmount += _amount;
		user.blockStart = block.number;

		if(user_blocks_before_claim(_pid, msg.sender) < 0){
		_claim(_pid,msg.sender);
		}

		emit Staked(msg.sender, address(pool.lptoken) ,_amount);
	}

	function _updatePool(uint256 _pid) internal {
		PoolList storage pool = poolList[_pid];

		if(pool.lptotal > 0){
			uint256 rewardRemains = pool.rewardRemains - pool.totalPendingReward;
			uint256 TotalShare = percent(pool.lptotal, _decimalConverter, 4);
			uint256 blockRemain = 0;
			uint256 totalPendingReward = 0;

			if(block.number > pool.poolLastBlockUpdate){
				blockRemain = block.number - pool.poolLastBlockUpdate;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
			}

			if(rewardRemains < totalPendingReward){
				blockRemain = rewardRemains.div(((TotalShare.mul(pool.rewardBlock).div(_divRate)))) - 1;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
				pool.poolActive = false;
			}

			pool.totalPendingReward += totalPendingReward;
			pool.poolLastBlockUpdate += blockRemain;
		} else {
			pool.poolLastBlockUpdate = block.number;
		}
	}

	function totalPool() public view returns (uint256) {
		return poolList.length;
	}

	function poolName(uint256 _pid) public view returns (string memory) {
		return poolList[_pid].pool_name;
	}

	function get_LPtoken_address(uint256 _pid) public view returns (IERC20) {
		return poolList[_pid].lptoken;
	}

	function get_pool_active(uint256 _pid) public view returns (bool) {
		return poolList[_pid].poolActive;
	}

	function get_rewardRemains(uint256 _pid) public view returns (uint256) {
		return poolList[_pid].rewardRemains;
	}

	function get_rewardBlock(uint256 _pid) public view returns (uint256) {
		return poolList[_pid].rewardBlock;
	}

	function get_totalusers(uint256 _pid) public view returns (uint256) {
		return poolList[_pid].totalusers;
	}

	function get_totalPendingReward(uint256 _pid) public view returns (uint256) {
		return poolList[_pid].totalPendingReward;
	}

	function get_poolLastBlockUpdate(uint256 _pid) public view returns (uint256) {
		return poolList[_pid].poolLastBlockUpdate;
	}
	
	function get_reward_token() public view returns (address) {
		return _reward_token;
	}

	function pendingRewardsFromPool(uint256 _pid, address _user) public view returns (uint256) {
		PoolList memory pool = poolList[_pid];
		UserList memory user = userList[_pid][_user];

		if(user.stakingAmount > 0){

			uint256 rewardRemains = pool.rewardRemains - pool.totalPendingReward;
			uint256 TotalShare = percent(pool.lptotal, _decimalConverter, 4);
			uint256 blockRemain = 0;
			uint256 totalPendingReward = 0;

			if(block.number > pool.poolLastBlockUpdate){
				blockRemain = block.number - pool.poolLastBlockUpdate;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
			}

			if(rewardRemains < totalPendingReward){
				blockRemain = rewardRemains.div(((TotalShare.mul(pool.rewardBlock).div(_divRate)))) - 1;
				totalPendingReward = (blockRemain.mul(TotalShare.mul(pool.rewardBlock))).div(_divRate);
				pool.poolActive = false;
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

	function harvest(uint256 _pid) public nonReentrant {
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
		
        if(user_blocks_before_claim(_pid, account) < 0){
    		uint256 rewardAmount = pendingRewardsFromPool(_pid,msg.sender);
    		uint256 claimAmount = rewardAmount;
    
    		if(rewardAmount > 0){
    			if(pool.devFee > 0){
    				uint256 devAmount = rewardAmount * pool.devFee / _divRate;
    				tokenReward.generateReward(devAddress, devAmount);
    				claimAmount -= devAmount;
    				emit DevFee(account, devAmount);
    			}
    
    
    			
    
    			pool.rewardRemains -= rewardAmount;
    			pool.totalPendingReward -= rewardAmount;
    			user.claimReward += rewardAmount;
    			user.pendingReward = 0;
    			tokenReward.generateReward(account, claimAmount);
    			emit ClaimReward(account ,claimAmount);
        	}

        }
        
		user.blockStart = block.number;
	}

		function withdraw_LP(uint256 _pid, uint amount) public nonReentrant {
		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");

		_updatePool(_pid);

		UserList storage user = userList[_pid][msg.sender];
		PoolList storage pool = poolList[_pid];

		require(user.stakingAmount > 0, "not have withdrawn balance");
        // require((user_blocks_before_claim(_pid, msg.sender) == 0, "Not long enough time staked.")


		if(amount == user.stakingAmount){
    		
    
    		pool.totalusers -= 1;
    		for(uint256 i = 0; i < pooldatas[_pid].length; i++) {
    			if(pooldatas[_pid][i] == msg.sender){
    				delete pooldatas[_pid][i];
    				i = pooldatas[_pid].length;
    			}
    		}
    	}
	    pool.lptotal -= amount;
		user.stakingAmount -= amount;
		
		_claim(_pid, msg.sender);
		pool.lptoken.safeTransfer(msg.sender, amount);
		user.blockStart = block.number;
		emit Withdraw(msg.sender, address(pool.lptoken) ,amount);
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

		_updateUsers(_pid);

		pool.rewardBlock = _rewardBlock;
	}

	function addRewardSupply(uint _pid, uint256 _addAmount) external onlyOwner {
		PoolList storage pool = poolList[_pid];

		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");

		pool.rewardRemains += _addAmount;
		pool.poolActive = true;

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

	function updatePoolFee(uint _pid, uint256 _devFee) external onlyOwner {
		PoolList storage pool = poolList[_pid];

		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");

		_updatePool(_pid);

		pool.devFee = _devFee;
	}

	function updatePoolLP(uint _pid, address _lptoken) external onlyOwner {
		PoolList storage pool = poolList[_pid];

		uint256 countPool = poolList.length;
		require(_pid < countPool, "Not a valid Pool");

		_updatePool(_pid);
		require(pool.lptotal == 0 , "Pool have staked balance");

		existingPools[address(pool.lptoken)] = false;
		pool.lptoken = IERC20(_lptoken);
		existingPools[_lptoken] = true;
	}
	
	function get_pending_rewards(uint _pid) public view returns (uint256) {
    	return pendingRewardsFromPool(_pid,msg.sender);
	}
	
	function get_staked_LP(uint _pid) public view returns (uint256) {
		UserList storage user = userList[_pid][msg.sender];
    	return user.stakingAmount;
	}
	
	function get_user_blockstart(uint _pid, address _address) public view returns (uint256) {
		UserList storage user = userList[_pid][_address];
    	return user.blockStart;
	}
	function get_blockstart(uint _pid) public view returns (uint256) {
		return get_user_blockstart(_pid,msg.sender);
	}
	function user_blocks_before_claim(uint _pid, address _address) public view returns (int256) {
    	int256 amount = int(get_user_blockstart(_pid,_address)) + 3 - int(block.number);
    	return amount;
	}
	
	function get_blocks_before_claim(uint _pid) public view returns (int256) {
    	return user_blocks_before_claim(_pid, msg.sender);
	}
	
	function get_total_pool_LP(uint _pid) public view returns (uint256) {
	    PoolList storage pool = poolList[_pid];
	    uint current_LP = pool.lptotal;
	    return current_LP;
	}
	
	function get_user_pool_LP(uint _pid, address _address) public view returns (uint256) {
		UserList storage user = userList[_pid][_address];
        return user.stakingAmount;
	}
	
	


	event Staked(address indexed user, address lptoken, uint256 amount);
	event ClaimReward(address indexed user, uint256 amount);
	event DevFee(address indexed user, uint256 amount);
	event Withdraw(address indexed user, address lptoken, uint256 amount);
}