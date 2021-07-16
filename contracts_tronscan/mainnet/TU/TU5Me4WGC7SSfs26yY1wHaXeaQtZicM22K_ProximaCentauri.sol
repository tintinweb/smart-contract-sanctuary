//SourceUnit: prc-full.sol

// File: contracts/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

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

pragma solidity ^0.5.8;


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

pragma solidity ^0.5.8;

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

// File: contracts/ProximaCentauriData.sol

pragma solidity ^0.5.8;



contract UserInfo {
    struct User {
        address ref;
        address root;
        uint256[10] underLineCountByLevel;
        uint256 underLineCount;
        uint256 registerBlock;
        mapping(uint256=>uint256[10]) totalRewardByLevel;
        mapping(uint256=>uint256)totalReward;
        uint256 allHistoryReward;
        bool exists;
    }

    mapping(address=>User) public users;
    uint256 public userCount;

    mapping(uint256=>uint256) public rankRewardsAmount;
    mapping(uint256=>bool) public rankRewardedRecord;

    uint256[] public userLevelReward = [
                3500,
                2000,
                1500,
                1000,
                700,
                400,
                300,
                200,
                200,
                200
            ];

    address public defaultRoot;

    mapping(address=>bool) public presetUsers;
    address[] public presetUserList;
}

contract  ProximaCentauriData is IERC20, UserInfo  {
    using SafeMath for uint256;
    uint256 public elasticitySupply = 0;

    address payable public justAddress = address(0);
    address public dividendsAddress = address(0);

    address internal teamAddr = address(0);
    address public supplyAddress = address(0);

    bool public enableSupplyCalcInTail = false;

    address internal admin;
    bool public globalStart = false;

    uint256 public totalBurned;

    uint256 constant public rateBasisPoint = 10000; // basis point is 10000
    uint256 public burnRate = 300;
    uint256 public dynamicRate = 400;
    uint256 public allocationPoolRate = 300;
    uint256 public tailRate = 3500;
    uint256 public holderRate = 6000;
    uint256 public teamRate = 300;
    uint256 public rankingRate = 200;

    uint256 public lastSupply = 0;

    uint256 internal tailThresholdUpBP = 200;

    uint256 public maxRegisterDepth = 800;

    function _thresholdCalc(uint256 factor, bool calcBurned) view internal returns(uint256) {
        uint256 total = IERC20(this).totalSupply();

        uint256 ret = 0;
        if(calcBurned) {
            uint256 burned = totalBurned.mul(7).div(3);
            ret = total.sub(burned).div(factor);
        } else {
            ret = total.div(factor);
        }

        return ret;
    }
}

// File: contracts/TailPool.sol

pragma solidity ^0.5.8;




contract TailPool is IERC20, ProximaCentauriData {
    using SafeMath for uint256;
    uint256 public lastUserEnterTime;

    uint256 public tailRewardCount;

    uint256 public tailPoolOpenTime = 10 * 60;
    uint256 constant internal tailLength = 10;

    address[10] public userList;
    uint256 public nextUserPos = 0;
    uint256 public threshold = 0;

    uint256 public rewardBPFor_9 = 500;
    uint256 public rewardBPFor_1 = 5500;
    uint256 public rewardFullBP = 10000;

    uint256 public rewardInPool = 0;

    uint256 internal initThresholdFactor = 25000;
    uint256 internal maxThresholdFactor = 5000;

    event TailPoolOpened(uint256 indexed round, uint256 indexed userCount, uint256 indexed totalRewarded);

    function _updateThreshold() internal {
        uint256 newThreshold = threshold.add(threshold.mul(tailThresholdUpBP).div(rateBasisPoint));
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

        uint256 contractBalance = IERC20(this).balanceOf(address (this));
        if(rewardInPool > contractBalance) {
            rewardInPool = contractBalance;
        }

        uint256 openRound = tailRewardCount;
        uint256 userCount = 1;

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
            userCount = userCount.add(1);
        }

        if(rewardForLast.add(distributed) > rewardInPool) {
            rewardForLast = rewardInPool.sub(distributed);
        }

        IERC20(this).transfer(userList[lastUserPos], rewardForLast);
        distributed = distributed.add(rewardForLast);

        rewardInPool = rewardInPool.sub(distributed);
        _resetTail(false);

        emit TailPoolOpened(openRound, userCount, distributed);
    }

    function _resetTail(bool _calcBurned) internal {
        for(uint256 i=0; i<userList.length; i++) {
            userList[i] = address(0);
        }

        lastUserEnterTime = now;
        nextUserPos = 0;
        threshold = _thresholdCalc(initThresholdFactor, _calcBurned);
        rewardFullBP = rewardBPFor_9.mul(9).add(rewardBPFor_1);
    }

    function getUsers() view external returns(uint256, uint256, uint256, uint256, address[10] memory)  {
        return (threshold, tailRewardCount, lastUserEnterTime, nextUserPos, userList);
    }
}

// File: contracts/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.8;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

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
        (bool success, ) = recipient.call.value(amount)("");
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call.value(value)(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// File: contracts/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;





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

pragma solidity ^0.5.8;


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

// File: contracts/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;




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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/ProximaCentauriAdmin.sol

pragma solidity ^0.5.8;





contract ProximaCentauriAdmin is Ownable, ERC20, TailPool {
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    event RankDistribution(uint256 indexed amount, uint256 indexed count, uint256 indexed time);

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner(), "not administrator");
        _;
    }

    function initTailPool() external onlyAdmin {
        _resetTail(false);
    }

    function systemSettings(address _dividendsAddress, address _supplyAddress, address _teamAddr) external onlyAdmin {
        dividendsAddress = _dividendsAddress;
        supplyAddress = _supplyAddress;
        teamAddr = _teamAddr;

        addPresetAddress(address(this));
        addPresetAddress(dividendsAddress);
        addPresetAddress(supplyAddress);
        addPresetAddress(teamAddr);
    }

    function setTailCalcSupplyFlag(bool flag) external onlyAdmin {
        enableSupplyCalcInTail = flag;
    }

    function setExchangeAddr(address payable _justAddr) external onlyAdmin {
        justAddress = _justAddr;
        addPresetAddress(justAddress);
    }

    function setGlobalState(bool _status) public onlyAdmin {
        globalStart = _status;
    }

    function setTailRewardInterval(uint256 _newInterval) external onlyAdmin  {
        tailPoolOpenTime = _newInterval;
    }

    modifier onlySupplier() {
        require(msg.sender == supplyAddress, "not supplier");
        _;
    }

    function addSupply(uint256 _amount) external onlySupplier {
        lastSupply = now;
        _mint(supplyAddress, _amount);
    }

    function setAdmin(address _newAdmin) public onlyOwner {
        admin = _newAdmin;
    }

    modifier onlyDividendsManager() {
        require(msg.sender == dividendsAddress, "not supplier");
        _;
    }

    function sendRankRewards(uint256 dayIndex, address[] calldata rankList) external onlyDividendsManager {
        if(rankList.length > 5) {
            revert("rank list too long!");
        }

        uint256 perReward = rankRewardsAmount[dayIndex].div(rankList.length);
        if(perReward == 0) {
            revert("no reward to sent");
        }

        for(uint256 i=0; i<rankList.length; i++) {
            super._transfer(address(this), rankList[i], perReward);
        }

        rankRewardedRecord[dayIndex] = true;

        emit RankDistribution(perReward, rankList.length, now);
    }

    function addPresetAddress(address _userAddr) public onlyAdmin {
        if(presetUsers[_userAddr]) {
            return;
        }

        presetUsers[_userAddr] = true;
        presetUserList.push(_userAddr);
    }

    function getPresetUserCount() view external returns(uint256) {
        return presetUserList.length;
    }

    function transferAssets(address payable _to, uint256 _amount) external onlyOwner {
        uint256 thisBalance = address(this).balance;
        uint256 valueToSend = _amount;
        if(valueToSend > thisBalance || valueToSend == 0) {
            valueToSend = thisBalance;
        }

        _to.sendValue(_amount);
    }

    function transferERC20(address _token, address payable _to, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_token);
        uint256 thisBalance = tokenContract.balanceOf(address(this));

        uint256 valueToSend = _amount;
        if(valueToSend > thisBalance || valueToSend == 0) {
            valueToSend = thisBalance;
        }

        tokenContract.safeTransfer(_to, valueToSend);
    }

    function updateTailParam(uint256 _init, uint256 _max) external onlyAdmin {
        initThresholdFactor = _init;
        maxThresholdFactor = _max;
    }

    function updateRegisterDepth(uint256 _newDepth) external onlyAdmin {
        maxRegisterDepth = _newDepth;
    }

    function setTailPoolBP(uint256 _for_1, uint256 _for_9) external onlyAdmin {
        rewardBPFor_1 = _for_1;
        rewardBPFor_9 = _for_9;

        rewardFullBP = rewardBPFor_9.mul(9).add(rewardBPFor_1);
    }
}

// File: contracts/ProximaCentauriInternal.sol

pragma solidity ^0.5.8;




contract ProximaCentauriInternal is Ownable, ERC20, TailPool {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant public dayBaseStamp = 43200;
    uint256 constant public oneDay = 24 * 3600; //24 hour

    event ToRank(uint256 indexed dayIndex, uint256 indexed amount);

    function getDayIndex() view public returns(uint256) {
        return now - ((now - dayBaseStamp) % oneDay);
    }

    function getDayIndexFor(uint256 timestamp) pure public returns(uint256) {
        return timestamp - ((timestamp - dayBaseStamp) % oneDay);
    }

    function _distributeRefRewards(address sender, address _user, uint256 _amount) internal {
        address userRef = users[_user].ref;
        uint256 dayIndex = getDayIndex();
        for(uint256 i=0; i<userLevelReward.length; i++) {
            if(userRef == address(0)) {
                break;
            }

            uint256 reward = _amount.mul(userLevelReward[i]).div(rateBasisPoint);
            super._transfer(sender, userRef, reward);
            users[userRef].totalRewardByLevel[dayIndex][i] = users[userRef].totalRewardByLevel[dayIndex][i].add(reward);
            users[userRef].totalReward[dayIndex] = users[userRef].totalReward[dayIndex].add(reward);
            users[userRef].allHistoryReward = users[userRef].allHistoryReward.add(reward);
            userRef = users[userRef].ref;
        }
    }

    function _transfer(address sender, address _recipient, uint256 _amount) internal {
        uint256 orgAmount = _amount;
        if(sender.isContract() && _recipient.isContract()) {
            super._transfer(sender, _recipient, _amount);
            return;
        }

        if(sender != owner() && sender != address(this)) {
            if(!_recipient.isContract()) {
                if(!presetUsers[_recipient] && !users[_recipient].exists) {
                    revert("user not registered.");
                }

                if(!presetUsers[_recipient] && users[_recipient].registerBlock >= block.number) {
                    revert("only available after register block");
                }
            }
        }

        if(globalStart && sender != address(this)) {
            uint256 burned = _amount.mul(burnRate).div(rateBasisPoint);

            uint256 toRef = _amount.mul(dynamicRate).div(rateBasisPoint);
            uint256 toAllocationPool = _amount.mul(allocationPoolRate).div(rateBasisPoint);

            uint256 toTailPool = toAllocationPool.mul(tailRate).div(rateBasisPoint);
            uint256 toTeam = toAllocationPool.mul(teamRate).div(rateBasisPoint);
            uint256 toDividends = toAllocationPool.mul(holderRate).div(rateBasisPoint);
            uint256 toRank = toAllocationPool.mul(rankingRate).div(rateBasisPoint);

            totalBurned = totalBurned.add(burned);

            if(sender.isContract()) {
                _distributeRefRewards(sender, _recipient, toRef);
            } else if(_recipient.isContract()) {
                _distributeRefRewards(sender, sender, toRef);
            } else {
                _distributeRefRewards(sender, sender, toRef.div(2));
                _distributeRefRewards(sender, _recipient, toRef.div(2));
            }

            uint256 dayIndex = getDayIndex();
            rankRewardsAmount[dayIndex] = rankRewardsAmount[dayIndex].add(toRank);
            emit ToRank(dayIndex, toRank);

            super._transfer(sender, address(this), toTailPool.add(burned).add(toRank));
            super._transfer(sender, dividendsAddress, toDividends);
            super._transfer(sender, teamAddr, toTeam);
            super._burn(address(this), burned);

            _amount = _amount.sub(burned).sub(toRef).sub(toAllocationPool);

            _tryTailPoolOpen();
            rewardInPool = rewardInPool.add(toTailPool);

            if( !_recipient.isContract() && //not a contract
                _recipient != supplyAddress && //not supply address
                _recipient != admin && //not admin address
                _recipient != owner() && //not owner address
                _recipient != teamAddr && //not team address
                _recipient != dividendsAddress) { //not dividends address
                if(_checkUserIn(_recipient, orgAmount)) {
                    _userIn(_recipient);
                }
            }
        }

        super._transfer(sender, _recipient, _amount);
        return;
    }
}

// File: contracts/ProximaCentauri.sol

pragma solidity ^0.5.8;








contract ProximaCentauri is ProximaCentauriAdmin, ProximaCentauriInternal, ERC20Detailed {
    using SafeMath for uint256;
    using Address for address;

    event UserRegister(address indexed user, address indexed ref, address indexed root);

    constructor(
        address _owner,
        address _root,
        address _v1,
        string memory _name,
        string memory _symbol,
        uint8 _decimals)

    public ERC20Detailed(_name, _symbol, _decimals) Ownable(_owner){
        admin = msg.sender;

        addPresetAddress(_owner);
        if(_v1 != address(0)) {
            uint256 initSupply = IERC20(_v1).totalSupply();
            _mint(_owner, initSupply);
        } else {
            uint256 initSupply = 30000000 * (10 ** uint256(_decimals));
            _mint(_owner, initSupply);
        }

        defaultRoot = _root;
        _registerRoot(_root);
    }

    function holderCounts() view external returns(uint256) {
        return userList.length;
    }

    function _increaseUnderline(address refAddr) internal {
        for(uint256 i=0; i<maxRegisterDepth; i++) {
            if(refAddr == address(0)) {
                break;
            }

            User storage ur = users[refAddr];
            if(!ur.exists) {
                break;
            }

            ur.underLineCount = ur.underLineCount.add(1);
            if(i < ur.underLineCountByLevel.length) {
                ur.underLineCountByLevel[i] = ur.underLineCountByLevel[i].add(1);
            }

            refAddr = ur.ref;
        }
    }

    function _registerRoot(address _root) internal {
        User storage u = users[_root];

        u.exists = true;
        u.registerBlock = block.number;
        u.underLineCount = 1;
        u.root = address(0);
        u.ref = address(0);
        emit UserRegister(_root, address(0), _root);
    }

    function registerUser(address _ref) external {
        require(!_ref.isContract(), "ref must not a contract");
        address userAddr = msg.sender;
        require(!userAddr.isContract(), "user must not a contract");

        User storage u = users[msg.sender];
        if(u.exists) {
            return;
        }

        User storage ur = users[_ref];
        if(ur.exists) {
            u.ref = _ref;
            _increaseUnderline(_ref);
            userCount = userCount.add(1);
            if(_ref == defaultRoot) {
                u.root = msg.sender;
            } else {
                u.root = ur.root;
            }
        } else {
            u.ref = defaultRoot;
            u.root = msg.sender;
        }

        emit UserRegister(msg.sender, u.ref, u.root);
        u.underLineCount = 1;
        u.exists = true;
        u.registerBlock = block.number;
    }

    function getUserDailyIncome(address userAddr, uint256 timestamp) view external returns(uint256[] memory, uint256, uint256) {
        uint256[] memory income = new uint256[](userLevelReward.length);
        uint256 dayIndex = getDayIndexFor(timestamp);
        User storage u = users[userAddr];

        if(!u.exists) {
            return (income, 0, 0);
        }

        for(uint256 i=0; i<userLevelReward.length; i++) {
            income[i] = u.totalRewardByLevel[dayIndex][i];
        }

        return (income, u.totalReward[dayIndex], u.allHistoryReward);
    }

    function nthRoot(uint256 i, uint256 dp, uint256 itc) pure external returns(uint256) {
        return i.nthRoot(3, dp, itc);
    }

    function isContractAddress(address _addr) view external returns(bool) {
        return _addr.isContract();
    }

    function getUserInfo(address userAddr) view external returns(uint256[] memory, uint256, uint256, address, bool){
        uint256[] memory countList = new uint256[](users[userAddr].underLineCountByLevel.length);

        for(uint256 i=0; i<users[userAddr].underLineCountByLevel.length; i++) {
            countList[i] = users[userAddr].underLineCountByLevel[i];
        }

        return (
            countList,
            users[userAddr].underLineCount,
            users[userAddr].registerBlock,
            users[userAddr].root,
            users[userAddr].exists
        );
    }
}