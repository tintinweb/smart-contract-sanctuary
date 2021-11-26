/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

// 
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// 
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
        assembly {
            codehash := extcodehash(account)
        }
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract iChat {

	mapping(address => uint) public balances;

	mapping(address => mapping(address => uint)) public allowance;

	uint public totalSupply = 1000000000000* 10 ** 18;
	string public name = "Bioswap";
	string public symbol = "BIO";
	uint public decimals = 18;

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	// run when the contract is deployed
	constructor(){
		balances[msg.sender] = totalSupply;
	}

	function balanceOf(address owner) public view returns(uint){
		return balances[owner];
	}

	function transfer(address to, uint value) public returns(bool){
		require(balanceOf(msg.sender) >= value, 'Insufficient funds');
		balances[to] += value;
		balances[msg.sender] -= value;
		emit Transfer(msg.sender, to, value);
		return true;
	}

	function transferFrom(address from, address to, uint value) public returns(bool){
		require(balanceOf(from) >= value, 'Insufficient funds');
		require(allowance[from][msg.sender] >= value, 'Insufficient funds');
		balances[to] += value;
		balances[from] -= value;
		emit Transfer(from, to, value);
		return true;
	}

	function approve(address spender, uint value) public returns(bool){
		allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}
}

contract BioStaking is Ownable {
    using SafeMath for uint256;
    // Info of each user.
    struct UserInfo {
        uint256 pid;
        uint256 amount;
        uint256 extra;
        uint256 rewardDebt;
        uint256 lastStaking;
        uint256 bonus;
        bool isOwner;
    }

    // Info of each pool.
    struct PoolInfo {
        address owner;
        iChat lpToken;
        uint256 total;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // The Bio TOKEN!
    iChat public bio;
    // withdraw period
    uint256 public WITHDRAWAL_PERIOD = 1 hours;

    event AddPool(address indexed user);
    event Staking(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid);
    event WithdrawBonus(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawAll(address indexed user, uint256 indexed pid);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawAll(address indexed user, uint256 amount);
    
    constructor(iChat _bio) public {
        bio = _bio;

        // pool mặc định
        poolInfo.push(PoolInfo({
            owner: address(this),
            lpToken: bio,
            total: 0
        }));

    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function setWithdrawalPeriod(uint256 _period) external onlyOwner {
        WITHDRAWAL_PERIOD = _period;
    }

    function setBonus(address account, uint256 _bonus) external onlyOwner {
        require(_bonus > 0, 'bonus must greater than zero');
        UserInfo storage user = userInfo[account];
        require(user.amount > 0, 'not staking');
        user.bonus = _bonus;
    }

    function priceOfBio() public view returns (uint256) {
        return 500000000000000; // 5000000000000
    }
    
    // get lptoken of user
    function getStakingAmount(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];
        return user.amount;
    }
    
    // get lptoken of pool
    function getTokenOfPool(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.total;
    }
    
    function add(uint256 amount) public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 number = poolInfo.length;
        uint256 bioBal = bio.balanceOf(address(msg.sender));
        require(bioBal >= 20000000 * 10**18, 'not enough'); // 2000000000
        require(amount >= 20000000 * 10**18, 'not enough');
        require(user.amount == 0, 'user has been staking in other pool');
        require(user.isOwner == false, 'you are owner');
        
        if (amount > 0) {
            bio.transferFrom(address(msg.sender), address(this), amount);
            user.pid = number;
            user.amount = user.amount.add(amount);
            user.extra = user.amount.mul(50).div(100);
            user.rewardDebt = 0;
            user.lastStaking = block.timestamp;
            user.isOwner = true;
        }
        
        poolInfo.push(PoolInfo({
            owner: msg.sender,
            lpToken: bio,
            total: amount
        }));
        
        emit AddPool(msg.sender);
    }

    function pendingBio(address _user) external view returns (uint256 pending) {
        UserInfo storage user = userInfo[_user];
        if (user.amount > 0) {
            uint256 dayBonus = 0;
            uint256 timestampBonus = block.timestamp.sub(user.lastStaking);
            
            if(timestampBonus > 3600) {
                uint256 modBonus = timestampBonus.mod(3600);
                uint256 modBonusTimeStamp = timestampBonus.sub(modBonus);
                dayBonus = modBonusTimeStamp.div(3600);
                pending = user.amount.mul(50).mul(dayBonus).div(100).div(180).sub(user.rewardDebt);
            } else {
                pending = 0;
            }
        } else {
            pending = 0;
        }
    }

    function staking(uint256 _pid, uint256 _amount) public {
        require(_amount >= 1000 * 10**18, 'must staking at least 50$'); // 10000000
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount > 0) {
            require(user.pid == _pid, 'must use other account');
            
            uint256 dayBonus = 0;
            uint256 pending = 0;
            uint256 timestampBonus = block.timestamp.sub(user.lastStaking);
            if(timestampBonus > 3600) {
                uint256 modBonus = timestampBonus.mod(3600);
                uint256 modBonusTimeStamp = timestampBonus.sub(modBonus);
                dayBonus = modBonusTimeStamp.div(3600);
                pending = user.amount.mul(50).mul(dayBonus).div(100).div(180).sub(user.rewardDebt);
            } else {
                pending = 0;
            }
            
            if(pending > 0) {
                safeBioTransfer(msg.sender, pending);
            }
        }
        
        if (_amount > 0) {
            bio.transferFrom(address(msg.sender), address(this), _amount);
            user.pid = _pid;
            user.amount = user.amount.add(_amount);
            user.extra = user.amount.mul(50).div(100);
            user.rewardDebt = 0;
            user.bonus = 0;
            user.lastStaking = block.timestamp;
            
            pool.total = pool.total.add(_amount);
        }

        emit Staking(msg.sender, _pid, _amount);
    }
    
    function harvest(uint256 _pid) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, 'not staking');
        require(user.pid == _pid, 'must use other account');
        
        if (user.amount > 0) {
            uint256 dayBonus = 0;
            uint256 pending = 0;
            uint256 timestampBonus = block.timestamp.sub(user.lastStaking);
            
            if(timestampBonus > 3600) {
                uint256 modBonus = timestampBonus.mod(3600);
                uint256 modBonusTimeStamp = timestampBonus.sub(modBonus);
                dayBonus = modBonusTimeStamp.div(3600);
                pending = user.amount.mul(50).mul(dayBonus).div(100).div(180).sub(user.rewardDebt);
            } else {
                pending = 0;
            }
            
            if(pending > 0) {
                safeBioTransfer(msg.sender, pending);
                user.rewardDebt = user.rewardDebt.add(pending);
                user.extra = user.extra.sub(pending);
            }
        }
        
        emit Harvest(msg.sender, _pid);
    }
    
    function withdrawBonus(uint256 _pid) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, 'not staking');
        require(user.bonus > 0, 'no bonus');
        require(user.pid == _pid, 'must use other account');
        
        safeBioTransfer(address(msg.sender), user.bonus);
        
        emit WithdrawBonus(msg.sender, _pid, user.bonus);
    }

    function withdrawAll(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, 'not staking');
        require(user.pid == _pid, 'must use other account');
        require(user.lastStaking.add(WITHDRAWAL_PERIOD) < block.timestamp, '180 days to withdraw');
        
        if (user.amount > 0 && user.lastStaking.add(WITHDRAWAL_PERIOD) < block.timestamp) {
            safeBioTransfer(address(msg.sender), user.amount.add(user.extra));

            emit WithdrawAll(msg.sender, _pid);
            user.amount = 0;
            user.extra = 0;
            user.rewardDebt = 0;
            
            pool.total = pool.total.sub(user.amount);
        }
    }

    function safeBioTransfer(address _to, uint256 _amount) internal {
        uint256 bioBal = bio.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > bioBal) {
            transferSuccess = bio.transfer(_to, bioBal);
        } else {
            transferSuccess = bio.transfer(_to, _amount);
        }
        require(transferSuccess, "safeBioTransfer: Transfer failed");
    }
    
    function withdrawToOwner(uint256 _pid, address owneraddr) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lpTokenBalance = pool.total;
        if(lpTokenBalance > 0) {
            bio.transfer(address(owneraddr), lpTokenBalance);
        }
        emit EmergencyWithdraw(owneraddr, _pid, lpTokenBalance);
    }
    
    function withdrawAllToOwner(address owneraddr) public onlyOwner {
        uint256 bioBal = bio.balanceOf(address(this));
        if(bioBal > 0) {
            bio.transfer(address(owneraddr), bioBal);
        }
        emit EmergencyWithdrawAll(owneraddr, bioBal);
    }
}