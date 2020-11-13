// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


 /* @dev Contract module which provides a basic access control mechanism, where
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
    constructor () {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract YIIFIStaking is Ownable {
    using SafeMath for uint256;
    
    IERC20 private _YIIFIToken;
    uint256 private _dailyROI = 30;
    uint256 private _decimals = 1e18;
    uint256 private _divisor = 1e4;
    uint256 private _unitDuration = 864e2;
    uint256 private _minDuration = 1296e3;
    uint256 private _stakeDuration = 7776e3;
    uint256 private _stakingPool = _decimals.mul(111e2);
    uint256 private _minimumStake = _decimals.mul(15);
    uint256 private _maximumStake = _decimals.mul(5e2);
    
    uint256 private _totalStaked;
    uint256 private _totalStakers;
    uint256 private _totalDividends;
    uint256 private _offset;

    struct Staker {
        bool exists;
        uint256 createdAt;
        uint256 amount;
        uint256 withdrawn;
    }
    
    mapping(address => Staker) stakers;
    
    event OnStake(address indexed staker, uint256 amount);
    event OnUnstake(address indexed staker, uint256 amount);
    event OnWithdraw(address indexed staker, uint256 amount);
    
    constructor() {
        _YIIFIToken = IERC20(0x60CEE60BE1eE37e7787F3dFd18fEF3299d9fA216);
        _offset = _stakingPool;
    }
    
    function createStake(uint256 _amount) public {
        require(!isStaking(_msgSender()), "Stake: Already staking");       
        require(!stakingPoolFilled(_amount), "Stake: staking pool filled");
        require(_amount >= minimumStake(), "Stake: Not enough amount to stake");
        require(_amount <= maximumStake(), "Stake: More than acceptable stake amount");
        require(_YIIFIToken.transferFrom(_msgSender(), address(this), _amount), "Stake: Token transfer failed");
        _createStake(_msgSender(), _amount);
    }
    
    function _createStake(address _staker, uint256 _amount) internal {
        _offset = _offset.sub(maturedROI(_amount));
        stakers[_staker] = Staker(true, block.timestamp, _amount, 0);
        _totalStakers = _totalStakers.add(1);
        _totalStaked = _totalStaked.add(_amount);
        emit OnStake(_staker, _amount);
    }
    
    function withdraw() public {
        require(isStaking(_msgSender()), "Withdraw: sender is not staking");
        Staker storage staker = stakers[_msgSender()];
        uint256 roi = _stakingROI(staker).sub(staker.withdrawn);
        _totalDividends = _totalDividends.add(roi);
        staker.withdrawn = staker.withdrawn.add(roi);
        require(_YIIFIToken.transfer(_msgSender(), roi), "Withdraw: Token transfer failed");
        emit OnWithdraw(_msgSender(), roi);
    }
    
    function unstake() public {
        require(isStaking(_msgSender()), "Unstake: sender is not staking");
        Staker memory staker = stakers[_msgSender()];
        uint256 duration = block.timestamp.sub(staker.createdAt);
        require(duration > _minDuration, "Unstake: Too early to unstake");
        
        uint256 amount = staker.amount;
        uint256 roi = _stakingROI(staker);
        uint256 roiOffset = maturedROI(staker.amount).sub(roi);
        uint256 roiBalance = roi.sub(staker.withdrawn);
        
        if (duration < _stakeDuration) {
            uint256 tax = _calculateTax(amount, duration);
            amount = amount.sub(tax);
            roiOffset = roiOffset.add(tax);
        }
        
        _offset = _offset.add(roiOffset);
        uint256 total = amount.add(roiBalance);
        _totalDividends = _totalDividends.add(roiBalance);
        require(_YIIFIToken.transfer(_msgSender(), total), "Unstake: Token transfer failed");
        
        _totalStakers = _totalStakers.sub(1);
        _totalStaked = _totalStaked.sub(staker.amount);
        delete stakers[_msgSender()];
        emit OnUnstake(_msgSender(), total);
    }
    
    function maturedROI(uint256 _amount) public view returns(uint256) {
        return _stakeDuration.mul(_dailyROI).mul(_amount).div(_unitDuration).div(_divisor);
    }
    
    function _calculateTax(uint256 _amount, uint256 _duration) internal pure returns(uint256) {
        uint256 firstQtr = 2592e3;
        uint256 secondQtr = 5184e3;
        uint256 thirdQtr = 7776e3;
        uint256 divisor = 1e3;
        
        if (_duration <= firstQtr) {
            return _amount.mul(15).div(divisor);   
        } else if (_duration <= secondQtr) {
            return _amount.mul(10).div(divisor);   
        } else if (_duration <= thirdQtr) {
            return _amount.mul(5).div(divisor);
        }
    }
    
    function adminWithrawal(uint256 _amount) public onlyOwner {
        require(_amount <= _offset, "AdminWithrawal: Not enough balance");
        require(_YIIFIToken.balanceOf(address(this)) >= _amount, "AdminWithrawal: Balance is less than amount");
        require(_YIIFIToken.transfer(owner(), _amount), "AdminWithrawal: Token transfer failed");
        _offset = _offset.sub(_amount);
        emit OnWithdraw(owner(), _amount);
    }
    
    function _stakingROI(Staker memory _stake) internal view returns(uint256) {
        uint256 duration = block.timestamp.sub(_stake.createdAt);
        if (duration > _stakeDuration) {
            duration = _stakeDuration;
        }
        uint256 unitDuration = duration.div(_unitDuration);
        uint256 roi = unitDuration.mul(_dailyROI).mul(_stake.amount);
        return roi.div(_divisor);
    }
    
    function stakingROI(address _staker) public view returns(uint256) {
        Staker memory staker = stakers[_staker];
        return _stakingROI(staker);
    }
    
    function stakingPoolFilled(uint256 _amount) public view returns(bool) {
        uint256 temporaryPool = _totalStaked.add(_amount);
        return temporaryPool >= _stakingPool;
    }
    
    function isStaking(address _staker) public view returns(bool) {
        return stakers[_staker].exists;
    }
    
     function stakeCreatedAt(address _staker) external view returns(uint256) {
        return stakers[_staker].createdAt;
    }
    
    function stakingtill(address _staker) external view returns(uint256 date) {
        date = stakers[_staker].createdAt;
        if (date > 0) {
            date.add(_stakeDuration);
        }
    }
    
    function rewardWithdrawn(address _staker) external view returns(uint256) {
        return stakers[_staker].withdrawn;
    }
    
    function stakedAmount(address _staker) external view returns(uint256) {
        return stakers[_staker].amount;
    }
    
    function YIIFIToken() public view returns(IERC20) {
        return _YIIFIToken;
    }
    
    function minimumStake() public view returns(uint256) {
        return _minimumStake;
    }
    
    function maximumStake() public view returns(uint256) {
        return _maximumStake;
    }
    
    function totalStaked() external view returns(uint256) {
        return _totalStaked;
    }
    
    function totalStakers() external view returns(uint256) {
        return _totalStakers;
    }
    
    function stakingPool() external view returns(uint256) {
        return _stakingPool;
    }

    function totalDividends() external view returns(uint256) {
        return _totalDividends;
    }
}