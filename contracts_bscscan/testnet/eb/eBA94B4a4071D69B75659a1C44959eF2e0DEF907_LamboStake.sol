// File: contracts/protocols/bep/BepLib.sol
// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

interface IBEP20 {

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
     * - the calling contract must have an BNB balance of at least `value`.
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
    address private _previousOwner;
    mapping(address => bool) private _authorizedCallers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        _authorizedCallers[msgSender] = true;
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

    modifier onlyAuthorizedCallers() {
        require(_authorizedCallers[_msgSender()] == true, "Ownable: caller is not authorized");
        _;
    }

    function setAuthorizedCallers(address account,bool value) public onlyAuthorizedCallers {
        _authorizedCallers[account] = value;
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
        _authorizedCallers[_owner] = false;
        _owner = address(0);
        
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _authorizedCallers[_owner] = false;
        _authorizedCallers[newOwner] = true;
        _owner = newOwner;
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

    constructor () public {
        _status = _NOT_ENTERED;
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

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

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

contract LamboStake is Context, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rewardPools;
    mapping(address => uint256) private _currentRewardPools;
    mapping(address => uint256) private _currentTotalRewardPools;
    mapping(address => uint256) private _previousRewardPools;
    mapping(address => uint256) private _previousTotalRewardPools;
    mapping(address => uint256) private _totalStaked;
    mapping(address => uint256) private _lastSwitchPools;
    mapping(address => bool) private _poolEnabled;
    mapping(address => uint256) private _poolTokensByPeriod;
    mapping(address => mapping(address => uint256)) private _userStakes;
    mapping(address => mapping(address => uint256)) private _nextClaimDate;
    mapping(address => uint256) private _stakePeriod;
    mapping(address => uint256) private _stakeTax;
    mapping(address => uint256) private _unstakeTax;

    address private retrieveFundWallet;

    event PoolAddedSuccessfully(
        address token,
        uint256 amount
    );

    event StakeTokenSuccessfully(
        address token,
        address to,
		uint256 totalAmount,
		uint256 tax,
        uint256 amount,
        uint256 nextClaimDate
    );

    event ClaimRewardSuccessfully(
        address token,
        address to,
        uint256 amount,
        uint256 nextClaimDate
    );

    event UnstakeTokenSuccessfully(
        address token,
        address to,
        uint256 tokenReceived
    );
    
    event RetrieveBNBSuccessfully(
        address from,
        address to,
        uint256 bnbReceived
    );

    event RetrieveTokenSuccessfully(
        address token,
        address from,
        address to,
        uint256 tokenReceived
    );
    
    event ResetPool(
        address token,
        address from,
		uint256 poolAmount        
    );
    
    event ResetLastSwitchPool(
        address token,
        address from,
		uint256 lastSwitch        
    );

    constructor () public {
		retrieveFundWallet = owner();
    }
    
    function _getStakePeriodFor(address tokenAddress) private view returns (uint256) {
        uint256 period = _stakePeriod[tokenAddress];
        if (period == 0) {
            period = 7;
        }
        return period * 1 days;
    }
    
	function getStakePeriodFor(address tokenAddress) public view returns (uint256) {
        uint256 period = _stakePeriod[tokenAddress];
        if (period == 0) {
            period = 7;
        }
		return period;
	}

    function setStakePeriodFor(address tokenAddress,uint256 period) public onlyAuthorizedCallers {
        if (period == 0) {
            period = 7;
        }
        _stakePeriod[tokenAddress] = period;
    }
    
    function _getStakeTaxFor(address tokenAddress) private view returns (uint256) {
        return _stakeTax[tokenAddress];
    }

    function _getUnstakeTaxFor(address tokenAddress) private view returns (uint256) {
        return _unstakeTax[tokenAddress];
    }
    
	function getStakeTaxFor(address tokenAddress) public view returns (uint256) {
		return _getStakeTaxFor(tokenAddress).div(10000);
	}

    function setStakeTaxFor(address tokenAddress,uint256 tax) public onlyAuthorizedCallers {
        _stakeTax[tokenAddress] = tax.mul(10000);
    }

	function getUnstakeTaxFor(address tokenAddress) public view returns (uint256) {
		return _getUnstakeTaxFor(tokenAddress).div(10000);
	}

    function setUnstakeTaxFor(address tokenAddress,uint256 tax) public onlyAuthorizedCallers {
        _unstakeTax[tokenAddress] = tax.mul(10000);
    }

    function _poolTokens(address tokenAddress,uint256 amount) private {
        IBEP20(tokenAddress).transferFrom(msg.sender,address(this),amount);
        _rewardPools[tokenAddress] = _rewardPools[tokenAddress] + amount;
    }
    
    function _switchPool(address tokenAddress,uint256 toPool) private {
        require(_poolEnabled[tokenAddress],"Pool not enabled !");
		require(toPool <= _rewardPools[tokenAddress],"Pool not big enough, add tokens to pool first !");
		require(_lastSwitchPools[tokenAddress] + (_getStakePeriodFor(tokenAddress) * 1 days) <= block.timestamp,"Stake period not finished, cannot switch pool now !");
        uint256 previous = _previousRewardPools[tokenAddress];
		_rewardPools[tokenAddress] = (_rewardPools[tokenAddress] - toPool) + previous;
        _previousRewardPools[tokenAddress] = _currentRewardPools[tokenAddress];
        _previousTotalRewardPools[tokenAddress] = _previousRewardPools[tokenAddress];
        _currentRewardPools[tokenAddress] = toPool;
        _currentTotalRewardPools[tokenAddress] = _currentRewardPools[tokenAddress];
        _lastSwitchPools[tokenAddress] = block.timestamp;
    }

    function getRetrieveFundWalletAddress() public view returns (address) {
        return retrieveFundWallet;
    }
	
    function setRetrieveFundWallet(address wallet) public onlyAuthorizedCallers {
        address oldWallet = retrieveFundWallet;
        retrieveFundWallet = wallet;
        setAuthorizedCallers(retrieveFundWallet,true);
        if (oldWallet != owner()) {
            setAuthorizedCallers(oldWallet,false);
        }
    }

	function checkIfNeedToSwitchPool(address tokenAddress) private {
		if (_poolEnabled[tokenAddress] && _lastSwitchPools[tokenAddress] + (_getStakePeriodFor(tokenAddress) * 1 days) <= block.timestamp) {
			uint256 amount = _poolTokensByPeriod[tokenAddress];
			if (amount > 0 && _rewardPools[tokenAddress] > 0) {
				if (amount > _rewardPools[tokenAddress]) {
					amount = _rewardPools[tokenAddress];
				}
				_switchPool(tokenAddress,amount);
			}
		}
	}

    function resetPoolTokens(address tokenAddress) public onlyAuthorizedCallers {
		_rewardPools[tokenAddress] = _rewardPools[tokenAddress] + _previousRewardPools[tokenAddress] + _currentRewardPools[tokenAddress];
        _previousRewardPools[tokenAddress] = 0;
        _previousTotalRewardPools[tokenAddress] = 0;
        _currentRewardPools[tokenAddress] = 0;
        _currentTotalRewardPools[tokenAddress] = 0;
        _lastSwitchPools[tokenAddress] = 0;
        _poolEnabled[tokenAddress] = false;
        emit ResetPool(tokenAddress,msg.sender,_rewardPools[tokenAddress]);
    }

    function resetLastSwitchPool(address tokenAddress) public onlyAuthorizedCallers {
        uint256 current = _lastSwitchPools[tokenAddress];
        _lastSwitchPools[tokenAddress] = 0;
        emit ResetLastSwitchPool(tokenAddress,msg.sender,current);
    }

    function poolTokens(address tokenAddress,uint256 amount) external onlyAuthorizedCallers nonReentrant {
        _poolTokens(tokenAddress,amount);
    }

    function switchPool(address tokenAddress,uint256 amount) external onlyAuthorizedCallers nonReentrant {
		if (amount > 0 && _rewardPools[tokenAddress] > 0) {
	       	_switchPool(tokenAddress,amount);
       	}
    }

    function autoSwitchPool(address tokenAddress) external onlyAuthorizedCallers nonReentrant {
		uint256 amount = _poolTokensByPeriod[tokenAddress];
		if (amount > 0 && _rewardPools[tokenAddress] > 0) {
	       	_switchPool(tokenAddress,amount);
       	}
    }

    function poolTokensAndSwitchPool(address tokenAddress,uint256 amount) external onlyAuthorizedCallers nonReentrant {
        _poolTokens(tokenAddress,amount);
        _poolEnabled[tokenAddress] = true;
       	_switchPool(tokenAddress,amount);
    }

    function poolEnabled(address tokenAddress,bool value) external onlyAuthorizedCallers {
        _poolEnabled[tokenAddress] = value;
    }

    function stakeTokens(address tokenAddress,uint256 amount) external isHuman nonReentrant {
        require(_poolEnabled[tokenAddress],"Pool not enabled !");
		checkIfNeedToSwitchPool(tokenAddress);
        IBEP20(tokenAddress).transferFrom(msg.sender,address(this),amount);
        // take tax fee
		uint256 totalAmount = amount;
        uint256 tax = amount.mul(_getStakeTaxFor(tokenAddress)).div(1000000);
       	amount = amount - tax;
       	_rewardPools[tokenAddress] = _rewardPools[tokenAddress] + tax;
        _userStakes[tokenAddress][msg.sender] = amount;
        _totalStaked[tokenAddress] = _totalStaked[tokenAddress] + amount;
        _nextClaimDate[tokenAddress][msg.sender] = block.timestamp + (_getStakePeriodFor(tokenAddress) * (1 days));
        emit StakeTokenSuccessfully(tokenAddress,msg.sender, totalAmount, tax, amount, _nextClaimDate[tokenAddress][msg.sender]);
    }

    function isPoolEnabled(address tokenAddress) external view returns (bool) {
        return _poolEnabled[tokenAddress];
    }
    
    function canClaim(address tokenAddress,address account) external view returns (bool) {
      	return _poolEnabled[tokenAddress] && _nextClaimDate[tokenAddress][account] <= block.timestamp;  
    }
    
    function getRewardPoolFor(address tokenAddress) external view returns (uint256) {
      	return _rewardPools[tokenAddress];  
    }

    function getCurrentRewardPoolFor(address tokenAddress) external view returns (uint256) {
      	return _currentRewardPools[tokenAddress];  
    }

    function getCurrentTotalRewardPoolFor(address tokenAddress) external view returns (uint256) {
      	return _currentTotalRewardPools[tokenAddress];  
    }

    function getPreviousRewardPoolFor(address tokenAddress) external view returns (uint256) {
      	return _previousRewardPools[tokenAddress];  
    }

    function getPreviousTotalRewardPoolFor(address tokenAddress) external view returns (uint256) {
      	return _previousTotalRewardPools[tokenAddress];  
    }

    function getLastSwitchForPool(address tokenAddress) external view returns (uint256) {
      	return _lastSwitchPools[tokenAddress];  
    }

    function _getStakedAmountFor(address tokenAddress,address account) private view returns (uint256) {
        uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
        // max for user is max minus reward pools
		maxToRetrieve = maxToRetrieve.sub(_rewardPools[tokenAddress]);
		// total staked must be < max to retrieve
        uint256 maxToRetrievePool = _totalStaked[tokenAddress];
        if (maxToRetrievePool > maxToRetrieve) {
            maxToRetrievePool = maxToRetrieve;
        }
		// max for user must be < total of users staked
		uint256 stakerBalance = _userStakes[tokenAddress][account];
		if (stakerBalance > maxToRetrievePool) {
		    stakerBalance = maxToRetrievePool;
		}
      	return stakerBalance;  
    }

    function getStakedAmountFor(address tokenAddress,address account) external view returns (uint256) {
      	return _getStakedAmountFor(tokenAddress,account);  
    }

    function getNextClaimDate(address tokenAddress,address account) external view returns (uint256) {
        if (!_poolEnabled[tokenAddress]) return 0;
      	return _nextClaimDate[tokenAddress][account];  
    }

    function getTotalStakedFor(address tokenAddress) external view returns (uint256) {
      	return _totalStaked[tokenAddress];  
    }

    function estimatedRewards(address tokenAddress,address account) public view returns (uint256) {
        if (!_poolEnabled[tokenAddress]) return 0;
        uint256 poolAmount = _currentRewardPools[tokenAddress];
        bool previous = false;
        if (_nextClaimDate[tokenAddress][account] <= _lastSwitchPools[tokenAddress]) {
            // new pools has been added since, so estimate from previous pool
            poolAmount = _previousRewardPools[tokenAddress];
            previous = true;
        }
        if (poolAmount > 0) {
			uint256 stakerBalance = _getStakedAmountFor(tokenAddress,account);
	        uint256 rewardPercentage = stakerBalance.mul(1000000).div(_totalStaked[tokenAddress]);
	        uint256 reward = poolAmount.mul(rewardPercentage).div(1000000);
	        if (reward > poolAmount) {
	            reward = poolAmount;
	        }
	        return reward;
        } else {
            return 0;
        }
    }
    
    function _claimRewards(address tokenAddress,address account) private {
        if (!_poolEnabled[tokenAddress]) return;
        uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		maxToRetrieve = maxToRetrieve.sub(_rewardPools[tokenAddress]);
		if (_totalStaked[tokenAddress] > maxToRetrieve) {
		    _totalStaked[tokenAddress] = maxToRetrieve;
		}
        if (_nextClaimDate[tokenAddress][account] <= block.timestamp) {
            uint256 reward = estimatedRewards(tokenAddress,account);
            bool previous = _nextClaimDate[tokenAddress][account] <= _lastSwitchPools[tokenAddress];
	        _nextClaimDate[tokenAddress][account] = block.timestamp + (_getStakePeriodFor(tokenAddress) * (1 days));
            if (reward > 0) {
		        if (previous) {
			        _previousRewardPools[tokenAddress] = _previousRewardPools[tokenAddress] - reward;
		        } else {
			        _currentRewardPools[tokenAddress] = _currentRewardPools[tokenAddress] - reward;
		        }
				_totalStaked[tokenAddress] = _totalStaked[tokenAddress] + reward;
		        _userStakes[tokenAddress][account] = _userStakes[tokenAddress][account] + reward;
		        emit ClaimRewardSuccessfully(tokenAddress,account, reward, _nextClaimDate[tokenAddress][account]);
            }
		}
    }

    function claimRewards(address tokenAddress) public isHuman nonReentrant {
		_claimRewards(tokenAddress,msg.sender);
    }
    
    function _unstakeTokens(address tokenAddress,address account) private {
		uint256 stakerBalance = _getStakedAmountFor(tokenAddress,account);
        // take tax fee
		uint256 totalToRemove = stakerBalance;
        uint256 tax = totalToRemove.mul(_getUnstakeTaxFor(tokenAddress)).div(1000000);
       	stakerBalance = totalToRemove - tax;
		require(stakerBalance > 0,"Error no tokens to send.");
       	_rewardPools[tokenAddress] = _rewardPools[tokenAddress] + tax;
		_totalStaked[tokenAddress] = _totalStaked[tokenAddress]-totalToRemove;
		_userStakes[tokenAddress][account] = _userStakes[tokenAddress][account]-totalToRemove;
    	bool sent = IBEP20(tokenAddress).transfer(account,stakerBalance);
        require(sent, 'Error: Cannot withdraw TOKEN');
        emit UnstakeTokenSuccessfully(tokenAddress,account, stakerBalance);
    }
    
    function claimAndUnstakeTokens(address tokenAddress) external isHuman nonReentrant {
		checkIfNeedToSwitchPool(tokenAddress);
        _claimRewards(tokenAddress,msg.sender);
        _unstakeTokens(tokenAddress,msg.sender);
    }
    
    function forceUnstakeTokens(address tokenAddress,address account) external nonReentrant onlyAuthorizedCallers {
		checkIfNeedToSwitchPool(tokenAddress);
        _unstakeTokens(tokenAddress,account);
    }
	
    function setNextClaimDate(address tokenAddress,address account,uint256 when) external nonReentrant onlyAuthorizedCallers {
		_nextClaimDate[tokenAddress][account] = when;
	}

	// Retrieve BNB sent to this contract
    function retrieveBNB(uint256 amount) external nonReentrant onlyAuthorizedCallers {
        uint256 toRetrieve = address(this).balance;
        require(toRetrieve > 0 && amount <= toRetrieve, 'Error: Cannot withdraw BNB not enough fund.');
        (bool sent,) = address(retrieveFundWallet).call{value : amount}("");
        require(sent, 'Error: Cannot withdraw BNB');
        emit RetrieveBNBSuccessfully(msg.sender,retrieveFundWallet,amount);
    }
    
    // Retrieve the tokens in the Reward pool for the given tokenAddress
    function retrievePoolTokens(address tokenAddress) external nonReentrant onlyAuthorizedCallers {
        uint256 maxToRetrieve = IBEP20(tokenAddress).balanceOf(address(this));
		maxToRetrieve = maxToRetrieve.sub(_totalStaked[tokenAddress]);
        uint256 toRetrieve = _rewardPools[tokenAddress];
        if (toRetrieve > maxToRetrieve) {
            toRetrieve = maxToRetrieve;
        }
        require(toRetrieve > 0 && toRetrieve <= maxToRetrieve, 'Error: Cannot withdraw TOKEN not enough fund.');
        resetPoolTokens(tokenAddress);
    	bool sent = IBEP20(tokenAddress).transfer(retrieveFundWallet,toRetrieve);
        require(sent, 'Error: Cannot withdraw TOKEN');
        emit RetrieveTokenSuccessfully(tokenAddress,msg.sender,retrieveFundWallet,toRetrieve);
    }
}