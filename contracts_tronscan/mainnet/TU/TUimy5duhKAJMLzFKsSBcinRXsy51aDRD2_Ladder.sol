//SourceUnit: Ladder.sol

// File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);


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
}// SPDX-License-Identifier: MIT

// File: contracts/ERC20Detailed.sol

pragma solidity ^0.5.9;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;

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

    function nthRoot(uint256 _a, uint256 _n, uint256 _dp, uint256 _maxIts) internal pure returns(uint256) {
        assert (_n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint256 one = 10 ** (1 + _dp);
        uint256 a0 = one ** _n * _a;

        // Initial guess: 1.0
        uint256 xNew = one;
        uint256 x;

        uint256 iter = 0;
        while (xNew != x && iter < _maxIts) {
            x = xNew;
            uint256 t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;

            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
    }
}

// File: contracts/LadderData.sol

pragma solidity ^0.5.9;



contract  LadderData is IERC20  {
    using SafeMath for uint256;
    uint256 public elasticitySupply = 0;

    address payable public justAddress = address(0);
    address public dividendsAddress = address(0);
    address public burnAddress = address(1);

    address internal teamAddr = address(0);
    address public supplyAddress = address(0);

    bool public enableSupplyCalcInTail = false;

    function _thresholdCalc(uint256 factor, bool calcBurned) view internal returns(uint256) {
        uint256 total = IERC20(this).totalSupply();

        uint256 ret = 0;
        if(calcBurned) {
            ret = total.sub(total.mul(52631578947368000).div(1e18)).div(factor);
        } else {
            ret = total.div(factor);
        }

        uint256 supplyAmount = IERC20(this).balanceOf(supplyAddress);
        if(supplyAmount > 0 && enableSupplyCalcInTail) {
            supplyAmount = supplyAmount.div(1e18);
            uint256 adjust = 0;
            if(supplyAmount > 0) {
                adjust = supplyAmount.nthRoot(3, 8, 100).div(1e9).mul(1e18);
            }
            ret = ret.add(adjust);
        }

        return ret;
    }
}

// File: contracts/TailPool.sol

pragma solidity ^0.5.9;




contract TailPool is IERC20, LadderData {
    using SafeMath for uint256;
    uint256 public lastUserEnterTime;

    uint256 public tailRewardCount;

    uint256 public tailPoolOpenTime = 60 * 60;
    uint256 constant private tailLength = 10;

    uint256 private basisPoint = 10000;

    address[10] public userList;
    uint256 public nextUserPos = 0;
    uint256 public threshold = 0;

    uint256 private thresholdUpBP = 200;

    uint256 private rewardBPFor_9 = 600;
    uint256 private rewardBPFor_1 = 4600;
    uint256 private rewardBPForTeam = 0;
    uint256 private rewardBPForHolder = 0;
    uint256 private rewardBPForBlank = 0;
    uint256 private rewardFullBP = 10000;

    uint256 public rewardInPool = 0;
    uint256 private rewardLeft = 0;

    uint256 private initThresholdFactor = 5000;
    uint256 private maxThresholdFactor = 1000;

    function _updateThreshold() internal {
        uint256 newThreshold = threshold.add(threshold.mul(thresholdUpBP).div(basisPoint));
        uint256 maxThreshold = _thresholdCalc(maxThresholdFactor, true);

        if(newThreshold > maxThreshold) {
            newThreshold = maxThreshold;
        }

        threshold = newThreshold;
    }

    function _checkUserIn(address user, uint256 amount) view internal returns(bool) {
        if(user == justAddress) {
            return false;
        }

        return (amount > threshold);
    }

    function _userIn(address user) internal {
        lastUserEnterTime = now;

        userList[nextUserPos] = user;
        nextUserPos = nextUserPos.add(1).mod(tailLength);

        _updateThreshold();
    }

    function _tryTailPoolOpen() internal {
        if(now.sub(lastUserEnterTime) <= tailPoolOpenTime) {
            return;
        }

        uint256 lastUserPos;
        if(nextUserPos == 0) {
            if(userList[0] == address(0)) {
                //no body in tail pool
                return;
            }

            lastUserPos = userList.length - 1;
        } else {
            lastUserPos = nextUserPos - 1;
        }

        tailRewardCount = tailRewardCount.add(1);
        uint256 perRewardFor_9 = rewardInPool.mul(rewardBPFor_9).div(rewardFullBP);
        uint256 rewardForLast = rewardInPool.mul(rewardBPFor_1).div(rewardFullBP);

        uint256 distributed = 0;
        for(uint256 i=0; i<userList.length; i++) {
            if(lastUserPos == i) {
                continue;
            }

            if(address(0) == userList[i]) {
                continue;
            }

            IERC20(this).transfer(userList[i], perRewardFor_9);
            distributed = distributed.add(perRewardFor_9);
        }

        if(rewardForLast.add(distributed) > rewardInPool) {
            rewardForLast = rewardInPool.sub(distributed);
        }

        IERC20(this).transfer(userList[lastUserPos], rewardForLast);
        distributed = distributed.add(rewardForLast);

        if(rewardBPForTeam > 0) {
            uint256 teamReward = rewardInPool.mul(rewardBPForTeam).div(rewardFullBP);
            if(teamReward.add(distributed) > rewardInPool) {
                teamReward = rewardInPool.sub(distributed);
            }
            IERC20(this).transfer(teamAddr, teamReward);
            distributed = distributed.add(teamReward);
        }
        
        rewardLeft = rewardLeft.add(rewardInPool.sub(distributed));
        rewardInPool = 0;
        _resetTail(false);
    }

    function _resetTail(bool _calcBurned) internal {
        for(uint256 i=0; i<userList.length; i++) {
            userList[i] = address(0);
        }

        lastUserEnterTime = now;
        nextUserPos = 0;
        rewardInPool = 0;
        threshold = _thresholdCalc(initThresholdFactor, _calcBurned);
        rewardFullBP = rewardBPFor_9.mul(9).add(rewardBPFor_1).add(rewardBPForTeam).add(rewardBPForHolder);
    }

    function getUsers() view external returns(uint256, uint256, uint256, uint256, address[10] memory)  {
        return (threshold, tailRewardCount, lastUserEnterTime, nextUserPos, userList);
    }
}

// File: contracts/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.9;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/Address.sol

pragma solidity ^0.5.9;

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

// File: contracts/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.9;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor (address owner_) internal {
        _owner = owner_;
        emit OwnershipTransferred(address(0), _owner);
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

// File: contracts/IJustSwapExchage.sol

pragma solidity ^0.5.9;

interface IJustswapExchange {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

/**
* @notice Convert TRX to Tokens.
* @dev User specifies exact input (msg.value).
* @dev User cannot specify minimum output or deadline.
*/
function () external payable;

/**
  * @dev Pricing function for converting between TRX && Tokens.
  * @param input_amount Amount of TRX or Tokens being sold.
  * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
  * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
  * @return Amount of TRX or Tokens bought.
  */
function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

/**
  * @dev Pricing function for converting between TRX && Tokens.
  * @param output_amount Amount of TRX or Tokens being bought.
  * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
  * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
  * @return Amount of TRX or Tokens sold.
  */
function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


/**
 * @notice Convert TRX to Tokens.
 * @dev User specifies exact input (msg.value) && minimum output.
 * @param min_tokens Minimum Tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of Tokens bought.
 */
function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

/**
 * @notice Convert TRX to Tokens && transfers Tokens to recipient.
 * @dev User specifies exact input (msg.value) && minimum output
 * @param min_tokens Minimum Tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output Tokens.
 * @return  Amount of Tokens bought.
 */
function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


/**
 * @notice Convert TRX to Tokens.
 * @dev User specifies maximum input (msg.value) && exact output.
 * @param tokens_bought Amount of tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of TRX sold.
 */
function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
/**
 * @notice Convert TRX to Tokens && transfers Tokens to recipient.
 * @dev User specifies maximum input (msg.value) && exact output.
 * @param tokens_bought Amount of tokens bought.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output Tokens.
 * @return Amount of TRX sold.
 */
function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

/**
 * @notice Convert Tokens to TRX.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_trx Minimum TRX purchased.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of TRX bought.
 */
function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

/**
 * @notice Convert Tokens to TRX && transfers TRX to recipient.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_trx Minimum TRX purchased.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @return  Amount of TRX bought.
 */
function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

/**
 * @notice Convert Tokens to TRX.
 * @dev User specifies maximum input && exact output.
 * @param trx_bought Amount of TRX purchased.
 * @param max_tokens Maximum Tokens sold.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return Amount of Tokens sold.
 */
function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

/**
 * @notice Convert Tokens to TRX && transfers TRX to recipient.
 * @dev User specifies maximum input && exact output.
 * @param trx_bought Amount of TRX purchased.
 * @param max_tokens Maximum Tokens sold.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @return Amount of Tokens sold.
 */
function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr).
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token_addr) bought.
 */
function tokenToTokenSwapInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
 *         Tokens (token_addr) to recipient.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token_addr) bought.
 */
function tokenToTokenTransferInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address recipient,
address token_addr)
external returns (uint256);


/**
 * @notice Convert Tokens (token) to Tokens (token_addr).
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToTokenSwapOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
 *         Tokens (token_addr) to recipient.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param token_addr The address of the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToTokenTransferOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address recipient,
address token_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (exchange_addr.token) bought.
 */
function tokenToExchangeSwapInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
 *         Tokens (exchange_addr.token) to recipient.
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies exact input && minimum output.
 * @param tokens_sold Amount of Tokens sold.
 * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
 * @param min_trx_bought Minimum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (exchange_addr.token) bought.
 */
function tokenToExchangeTransferInput(
uint256 tokens_sold,
uint256 min_tokens_bought,
uint256 min_trx_bought,
uint256 deadline,
address recipient,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToExchangeSwapOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address exchange_addr)
external returns (uint256);

/**
 * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
 *         Tokens (exchange_addr.token) to recipient.
 * @dev Allows trades through contracts that were not deployed from the same factory.
 * @dev User specifies maximum input && exact output.
 * @param tokens_bought Amount of Tokens (token_addr) bought.
 * @param max_tokens_sold Maximum Tokens (token) sold.
 * @param max_trx_sold Maximum TRX purchased as intermediary.
 * @param deadline Time after which this transaction can no longer be executed.
 * @param recipient The address that receives output TRX.
 * @param exchange_addr The address of the exchange for the token being purchased.
 * @return Amount of Tokens (token) sold.
 */
function tokenToExchangeTransferOutput(
uint256 tokens_bought,
uint256 max_tokens_sold,
uint256 max_trx_sold,
uint256 deadline,
address recipient,
address exchange_addr)
external returns (uint256);


/***********************************|
|         Getter Functions          |
|__________________________________*/

/**
 * @notice external price function for TRX to Token trades with an exact input.
 * @param trx_sold Amount of TRX sold.
 * @return Amount of Tokens that can be bought with input TRX.
 */
function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

/**
 * @notice external price function for TRX to Token trades with an exact output.
 * @param tokens_bought Amount of Tokens bought.
 * @return Amount of TRX needed to buy output Tokens.
 */
function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

/**
 * @notice external price function for Token to TRX trades with an exact input.
 * @param tokens_sold Amount of Tokens sold.
 * @return Amount of TRX that can be bought with input Tokens.
 */
function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

/**
 * @notice external price function for Token to TRX trades with an exact output.
 * @param trx_bought Amount of output TRX.
 * @return Amount of Tokens needed to buy output TRX.
 */
function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

/**
 * @return Address of Token that is sold on this exchange.
 */
function tokenAddress() external view returns (address);

/**
 * @return Address of factory that created this exchange.
 */
function factoryAddress() external view returns (address);


/***********************************|
|        Liquidity Functions        |
|__________________________________*/

/**
 * @notice Deposit TRX && Tokens (token) at current ratio to mint UNI tokens.
 * @dev min_liquidity does nothing when total UNI supply is 0.
 * @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
 * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return The amount of UNI minted.
 */
function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

/**
 * @dev Burn UNI tokens to withdraw TRX && Tokens at current ratio.
 * @param amount Amount of UNI burned.
 * @param min_trx Minimum TRX withdrawn.
 * @param min_tokens Minimum Tokens withdrawn.
 * @param deadline Time after which this transaction can no longer be executed.
 * @return The amount of TRX && Tokens withdrawn.
 */
function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

// File: contracts/Ladder.sol

pragma solidity ^0.5.9;







contract Ladder is TailPool, Ownable, ERC20, ERC20Detailed {
    using SafeMath for uint256;

    address private admin;
    bool public globalStart = false;

    uint256 public outFromJust = 0;
    uint256 public totalBurned;

    uint256 constant public rateBasisPoint = 10000;
    uint256 public burnRate = 500; // basis point is 10000
    uint256 public tailRate = 3500;
    uint256 public teamRate = 500;
    uint256 public holderRate = 6000;

    uint256 public lastSupply = 0;

    event ExchangePriceChange(uint256 indexed amount, uint256 indexed blockNumber, bool indexed sell);
    event ToHolderPool(uint256 indexed amount);

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner(), "not administrator");
        _;
    }

    modifier onlySupplier() {
        require(msg.sender == supplyAddress, "not supplier");
        _;
    }

    constructor(
        address _owner,
        address _admin,
        string memory _name,
        string memory _symbol,
        uint8 _decimals)

    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        admin = _admin;

        uint256 initSupply = 30000000 * (10 ** uint256(_decimals));
        _mint(_owner, initSupply);
    }

    function initTailPool() external onlyAdmin {
        _resetTail(false);
    }

    function systemSettings(address _dividendsAddress, address _supplyAddress, address _teamAddr) external onlyAdmin {
        dividendsAddress = _dividendsAddress;
        supplyAddress = _supplyAddress;
        teamAddr = _teamAddr;
    }

    function setTailCalcSupplyFlag(bool flag) external onlyAdmin {
        enableSupplyCalcInTail = flag;
    }

    function setExchangeAddr(address payable _justAddr) external onlyAdmin {
        justAddress = _justAddr;
    }

    function setGlobalState(bool _status) public onlyAdmin {
        globalStart = _status;
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        admin = _newAdmin;
    }

    function resetOutFromJust() public onlyAdmin {
        outFromJust = 0;
    }

    function setTailRewardInterval(uint256 _newInterval) external onlyAdmin  {
        tailPoolOpenTime = _newInterval;
    }

    function setBurnRate(uint256 _newRate) public onlyAdmin {
        require(burnRate < rateBasisPoint);
        burnRate = _newRate;
    }

    function setRewardRate(uint256 _tailRate, uint256 _teamRate, uint256 _holderRate) public onlyAdmin {
        require(_tailRate.add(_teamRate).add(_holderRate) == rateBasisPoint);
        tailRate = _tailRate;
        teamRate = _teamRate;
        holderRate = _holderRate;
    }

    function holderCounts() view external returns(uint256){
        return userList.length;
    }

    function _transfer(address sender, address _recipient, uint256 _amount) internal {
        if(_recipient == justAddress && globalStart) {
            outFromJust = outFromJust.add(_amount);
        }

        if(_recipient == justAddress || sender == justAddress) {
            emit ExchangePriceChange(_amount, block.number, _recipient == justAddress);
        }

        uint256 orgAmount = _amount;

        if(globalStart && sender != address(this)) {
            uint256 burned = _amount.mul(burnRate).div(rateBasisPoint);

            uint256 toRewardPool = burned.mul(tailRate).div(rateBasisPoint);
            uint256 toTeam = burned.mul(teamRate).div(rateBasisPoint);
            uint256 toDividends = burned.mul(holderRate).div(rateBasisPoint);

            totalBurned = totalBurned.add(burned);
            rewardInPool = rewardInPool.add(toRewardPool);

            uint256 toPoolTotal = toRewardPool.add(toDividends);

            super._transfer(sender, address(this), toRewardPool.add(burned));
            super._transfer(sender, dividendsAddress, toDividends);
            super._transfer(sender, teamAddr, toTeam);
            super._burn(address(this), burned);

            emit ToHolderPool(toDividends);

            _amount = _amount.sub(burned).sub(toPoolTotal).sub(toTeam);

            _tryTailPoolOpen();

            if(_recipient != supplyAddress && _recipient != admin && _recipient != owner() && _recipient != teamAddr && _recipient != dividendsAddress) {
                if(_checkUserIn(_recipient, orgAmount)) {
                    _userIn(_recipient);
                }
            }
        }

        super._transfer(sender, _recipient, _amount);
        return;
    }

    function addSupply(uint256  _amount) external onlySupplier {
        lastSupply = now;
        _mint(supplyAddress, _amount);
    }

    function nthRoot(uint256 i, uint256 dp, uint256 itc) pure external returns(uint256) {
        return i.nthRoot(3, dp, itc);
    }
}