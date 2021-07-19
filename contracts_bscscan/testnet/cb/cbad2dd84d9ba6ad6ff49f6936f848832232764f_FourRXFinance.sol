/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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

// File: contracts/InterestCalculator.sol


pragma solidity ^0.6.12;


contract InterestCalculator {
    using SafeMath for uint;
    uint private constant MAX_DAYS = 365;

    function _initCumulativeInterestForDays() internal pure returns(uint[366] memory) {
        uint[366] memory cumulativeInterestForDays = [
        uint(0), 1, 2, 3, 4, 6, 8, 11, 14, 17, 21, 25, 30, 35, 40, 46, 52, 58, 65, 72,
        80, 88, 96, 105, 114, 124, 134, 144, 155, 166, 178, 190, 202, 215, 228, 242, 256, 271, 286, 301,
        317, 333, 350, 367, 385, 403, 421, 440, 459, 479, 499, 520, 541, 563, 585, 607, 630, 653, 677, 701,
        726, 751, 777, 803, 830, 857, 884, 912, 940, 969, 998, 1028, 1058, 1089, 1120, 1152, 1184, 1217, 1250, 1284,
        1318, 1353, 1388, 1424, 1460, 1497, 1534, 1572, 1610, 1649, 1688, 1728, 1768, 1809, 1850, 1892, 1934, 1977, 2020, 2064,
        2108, 2153, 2199, 2245, 2292, 2339, 2387, 2435, 2484, 2533, 2583, 2633, 2684, 2736, 2788, 2841, 2894, 2948, 3002, 3057,
        3113, 3169, 3226, 3283, 3341, 3399, 3458, 3518, 3578, 3639, 3700, 3762, 3825, 3888, 3952, 4016, 4081, 4147, 4213, 4280,
        4347, 4415, 4484, 4553, 4623, 4694, 4765, 4837, 4909, 4982, 5056, 5130, 5205, 5281, 5357, 5434, 5512, 5590, 5669, 5749,
        5829, 5910, 5992, 6074, 6157, 6241, 6325, 6410, 6496, 6582, 6669, 6757, 6845, 6934, 7024, 7114, 7205, 7297, 7390, 7483,
        7577, 7672, 7767, 7863, 7960, 8058, 8156, 8255, 8355, 8455, 8556, 8658, 8761, 8864, 8968, 9073, 9179, 9285, 9392, 9500,
        9609, 9719, 9829, 9940, 10052, 10165, 10278, 10392, 10507, 10623, 10740, 10857, 10975, 11094, 11214, 11335, 11456, 11578, 11701, 11825,
        11950, 12076, 12202, 12329, 12457, 12586, 12716, 12847, 12978, 13110, 13243, 13377, 13512, 13648, 13785, 13922, 14060, 14199, 14339, 14480,
        14622, 14765, 14909, 15054, 15199, 15345, 15492, 15640, 15789, 15939, 16090, 16242, 16395, 16549, 16704, 16860, 17017, 17174, 17332, 17491,
        17651, 17812, 17974, 18137, 18301, 18466, 18632, 18799, 18967, 19136, 19306, 19477, 19649, 19822, 19996, 20171, 20347, 20524, 20702, 20881,
        21061, 21242, 21424, 21607, 21791, 21976, 22162, 22350, 22539, 22729, 22920, 23112, 23305, 23499, 23694, 23890, 24087, 24285, 24484, 24685,
        24887, 25090, 25294, 25499, 25705, 25912, 26120, 26330, 26541, 26753, 26966, 27180, 27395, 27611, 27829, 28048, 28268, 28489, 28711, 28934,
        29159, 29385, 29612, 29840, 30069, 30300, 30532, 30765, 30999, 31235, 31472, 31710, 31949, 32190, 32432, 32675, 32919, 33165, 33412, 33660,
        33909, 34160, 34412, 34665, 34920, 35176, 35433, 35692, 35952, 36213, 36476, 36740, 37005, 37272, 37540, 37809, 38080, 38352, 38625, 38900,
        39176, 39454, 39733, 40013, 40295, 40578
        ];


        return cumulativeInterestForDays;
    }

    function _getInterestTillDays(uint _day) internal pure returns(uint) {
        require(_day <= MAX_DAYS, 'FF: 1118');

        return _initCumulativeInterestForDays()[_day];
    }
}

// File: contracts/Events.sol


pragma solidity ^0.6.12;


contract Events {
    event Deposit(address user, uint amount, uint8 stakeId, address uplinkAddress, uint uplinkStakeId);
    event Withdrawn(address user, uint amount);
    event ReInvest(address user, uint amount);
    event Exited(address user, uint stakeId, uint amount);
    event PoolDrawn(uint refPoolAmount, uint sponsorPoolAmount);
}

// File: contracts/PercentageCalculator.sol


pragma solidity ^0.6.12;


contract PercentageCalculator {
    using SafeMath for uint;

    uint public constant PERCENT_MULTIPLIER = 10000;

    function _calcPercentage(uint amount, uint basisPoints) internal pure returns (uint) {
        require(basisPoints >= 0, 'FF: 1117');
        return amount.mul(basisPoints).div(PERCENT_MULTIPLIER);
    }

    function _calcBasisPoints(uint base, uint interest) internal pure returns (uint) {
        return interest.mul(PERCENT_MULTIPLIER).div(base);
    }
}

// File: contracts/utils/Utils.sol


pragma solidity ^0.6.12;


contract Utils {
    using SafeMath for uint;

    uint public constant DAY = 86400; // Seconds in a day

    function _calcDays(uint start, uint end) internal pure returns (uint) {
        return end.sub(start).div(DAY);
    }
}

// File: contracts/Constants.sol


pragma solidity ^0.6.12;


contract Constants {
    uint public constant MAX_CONTRACT_REWARD_BP = 37455; // 374.55%

    uint public constant LP_FEE_BP = 500; // 5%
    uint public constant REF_COMMISSION_BP = 800; // 8%

    // Ref and sponsor pools
    uint public constant REF_POOL_FEE_BP = 50; // 0.5%, goes to ref pool from each deposit
    uint public constant SPONSOR_POOL_FEE_BP = 50; // 0.5%, goes to sponsor pool from each deposit

    uint public constant EXIT_PENALTY_BP = 5000; // 50%, deduct from user's initial deposit on exit

    // Contract bonus
    uint public constant MAX_CONTRACT_BONUS_BP = 300; // maximum bonus a user can get 3%
    uint public constant CONTRACT_BONUS_UNIT = 250;    // For each 250 token balance of contract, gives
    uint public constant CONTRACT_BONUS_PER_UNIT_BP = 1; // 0.01% extra interest

    // Hold bonus
    uint public constant MAX_HOLD_BONUS_BP = 100; // Maximum 1% hold bonus
    uint public constant HOLD_BONUS_UNIT = 43200; // 12 hours
    uint public constant HOLD_BONUS_PER_UNIT_BP = 2; // 0.02% hold bonus for each 12 hours of hold

    uint public constant REWARD_THRESHOLD_BP = 300; // User will only get hold bonus if his rewards are more then 3% of his deposit

    uint public constant MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP = 300; // Max daily withdrawal limit if user is above REWARD_THRESHOLD_BP

    uint public constant DEV_FEE_BP = 500; // 5%
}

// File: contracts/SharedVariables.sol


pragma solidity ^0.6.12;


contract SharedVariables is Constants, Events, PercentageCalculator, InterestCalculator, Utils {

    uint public constant fourRXTokenDecimals = 8;
    IERC20 public fourRXToken;
    address public devAddress;

    struct Stake {
        uint8 id;
        bool active;
        bool optInInsured; // Is insured ???

        uint32 holdFrom; // Timestamp from which hold should be counted
        uint32 interestCountFrom; // TimeStamp from which interest should be counted, from the beginning
        uint32 lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day

        uint origDeposit;
        uint deposit; // Initial Deposit
        uint withdrawn; // Total withdrawn from this stake
        uint penalty; // Total penalty on this stale

        uint rewards;
    }

    struct User {
        address wallet; // Wallet Address
        Stake[] stakes;
    }

    mapping (address => User) public users;

    uint public maxContractBalance;

    uint16 public poolCycle;
    uint32 public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;

    uint public devBalance;

    uint[12] public refPoolBonuses;
    uint[10] public sponsorPoolBonuses;
}

// File: contracts/libs/SortedLinkedList.sol


pragma solidity ^0.6.12;


library SortedLinkedList {
    using SafeMath for uint;

    struct Item {
        address user;
        uint16 next;
        uint8 id;
        uint score;
    }

    uint16 internal constant GUARD = 0;

    function addNode(Item[] storage items, address user, uint score, uint8 id) internal {
        uint16 prev = findSortedIndex(items, score);
        require(_verifyIndex(items, score, prev), 'SLL: 1100');
        items.push(Item(user, items[prev].next, id, score));
        items[prev].next = uint16(items.length.sub(1));
    }

    function updateNode(Item[] storage items, address user, uint score, uint8 id) internal {
        (uint16 current, uint16 oldPrev) = findCurrentAndPrevIndex(items, user, id);
        require(items[oldPrev].next == current, 'SLL: 1101');
        require(items[current].user == user, 'SLL: 1102');
        require(items[current].id == id, 'SLL: 1103');
        score = score.add(items[current].score);
        items[oldPrev].next = items[current].next;
        addNode(items, user, score, id);
    }

    function initNodes(Item[] storage items) internal {
        items.push(Item(address(0), 0, 0, 0));
    }

    function _verifyIndex(Item[] storage items, uint score, uint16 prev) internal view returns (bool) {
        return prev == GUARD || (score <= items[prev].score && score > items[items[prev].next].score);
    }

    function findSortedIndex(Item[] storage items, uint score) internal view returns(uint16) {
        Item memory current = items[GUARD];
        uint16 index = GUARD;
        while(current.next != GUARD && items[current.next].score >= score) {
            index = current.next;
            current = items[current.next];
        }

        return index;
    }

    function findCurrentAndPrevIndex(Item[] storage items, address user, uint8 id) internal view returns (uint16, uint16) {
        Item memory current = items[GUARD];
        uint16 currentIndex = GUARD;
        uint16 prevIndex = GUARD;
        while(current.next != GUARD && !(current.user == user && current.id == id)) {
            prevIndex = currentIndex;
            currentIndex = current.next;
            current = items[current.next];
        }

        return (currentIndex, prevIndex);
    }

    function isInList(Item[] storage items, address user, uint8 id) internal view returns (bool) {
        Item memory current = items[GUARD];
        bool exists = false;

        while(current.next != GUARD ) {
            if (current.user == user && current.id == id) {
                exists = true;
                break;
            }
            current = items[current.next];
        }

        return exists;
    }
}

// File: contracts/Pools/SponsorPool.sol


pragma solidity ^0.6.12;


contract SponsorPool {
    SortedLinkedList.Item[] public sponsorPoolUsers;

    function _addSponsorPoolRecord(address user, uint amount, uint8 stakeId) internal {
        SortedLinkedList.addNode(sponsorPoolUsers, user, amount, stakeId);
    }

    function _cleanSponsorPoolUsers() internal {
        delete sponsorPoolUsers;
        SortedLinkedList.initNodes(sponsorPoolUsers);
    }
}

// File: contracts/Pools/ReferralPool.sol


pragma solidity ^0.6.12;


contract ReferralPool {
    SortedLinkedList.Item[] public refPoolUsers;

    function _addReferralPoolRecord(address user, uint amount, uint8 stakeId) internal {
        if (!SortedLinkedList.isInList(refPoolUsers, user, stakeId)) {
            SortedLinkedList.addNode(refPoolUsers, user, amount, stakeId);
        } else {
            SortedLinkedList.updateNode(refPoolUsers, user, amount, stakeId);
        }
    }

    function _cleanReferralPoolUsers() internal {
        delete refPoolUsers;
        SortedLinkedList.initNodes(refPoolUsers);
    }
}

// File: contracts/Pools.sol


pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;


contract Pools is SponsorPool, ReferralPool, SharedVariables {

    uint8 public constant MAX_REF_POOL_USERS = 12;
    uint8 public constant MAX_SPONSOR_POOL_USERS = 10;

    function _resetPools() internal {
        _cleanSponsorPoolUsers();
        _cleanReferralPoolUsers();
        delete refPoolBalance;
        delete sponsorPoolBalance;
        poolDrewAt = uint32(block.timestamp);
        poolCycle++;
    }

    function _updateSponsorPoolUsers(User memory user, Stake memory stake) internal {
        _addSponsorPoolRecord(user.wallet, stake.deposit, stake.id);
    }

    // Reorganise top ref-pool users to draw pool for
    function _updateRefPoolUsers(User memory uplinkUser , Stake memory stake, uint8 uplinkUserStakeId) internal {
        _addReferralPoolRecord(uplinkUser.wallet, stake.deposit, uplinkUserStakeId);
    }

    function drawPool() public {
        if (block.timestamp > poolDrewAt + 1 days) {

            SortedLinkedList.Item memory current = refPoolUsers[0];
            uint16 i = 0;

            while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = refPoolUsers[current.next];
                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(refPoolBalance, refPoolBonuses[i]));
                i++;
            }

            current = sponsorPoolUsers[0];
            i = 0;

            while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
                current = sponsorPoolUsers[current.next];
                users[current.user].stakes[current.id].rewards = users[current.user].stakes[current.id].rewards.add(_calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
                i++;
            }

            emit PoolDrawn(refPoolBalance, sponsorPoolBalance);

            _resetPools();
        }
    }

    // pool info getters

    function getPoolInfo() external view returns (uint32, uint16, uint, uint) {
        return (poolDrewAt, poolCycle, sponsorPoolBalance, refPoolBalance);
    }

    function getPoolParticipants() external view returns (address[] memory, uint8[] memory, uint[] memory, address[] memory, uint8[] memory, uint[] memory) {
        address[] memory sponsorPoolUsersAddresses = new address[](MAX_SPONSOR_POOL_USERS);
        uint8[] memory sponsorPoolUsersStakeIds = new uint8[](MAX_SPONSOR_POOL_USERS);
        uint[] memory sponsorPoolUsersAmounts = new uint[](MAX_SPONSOR_POOL_USERS);

        address[] memory refPoolUsersAddresses = new address[](MAX_REF_POOL_USERS);
        uint8[] memory refPoolUsersStakeIds = new uint8[](MAX_REF_POOL_USERS);
        uint[] memory refPoolUsersAmounts = new uint[](MAX_REF_POOL_USERS);

        uint16 i = 0;
        SortedLinkedList.Item memory current = sponsorPoolUsers[i];

        while (i < MAX_SPONSOR_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = sponsorPoolUsers[current.next];
            sponsorPoolUsersAddresses[i] = current.user;
            sponsorPoolUsersStakeIds[i] = current.id;
            sponsorPoolUsersAmounts[i] = current.score;
            i++;
        }

        i = 0;
        current = refPoolUsers[i];

        while (i < MAX_REF_POOL_USERS && current.next != SortedLinkedList.GUARD) {
            current = refPoolUsers[current.next];
            refPoolUsersAddresses[i] = current.user;
            refPoolUsersStakeIds[i] = current.id;
            refPoolUsersAmounts[i] = current.score;
            i++;
        }

        return (sponsorPoolUsersAddresses, sponsorPoolUsersStakeIds, sponsorPoolUsersAmounts, refPoolUsersAddresses, refPoolUsersStakeIds, refPoolUsersAmounts);
    }
}

// File: contracts/RewardsAndPenalties.sol


pragma solidity ^0.6.12;


contract RewardsAndPenalties is Pools {
    using SafeMath for uint;

    function _distributeReferralReward(uint amount, Stake memory stake, address uplinkAddress, uint8 uplinkStakeId) internal {
        User storage uplinkUser = users[uplinkAddress];

        uint commission = _calcPercentage(amount, REF_COMMISSION_BP);

        uplinkUser.stakes[uplinkStakeId].rewards = uplinkUser.stakes[uplinkStakeId].rewards.add(commission);

        _updateRefPoolUsers(uplinkUser, stake, uplinkStakeId);
    }

    function _calcDepositRewards(uint amount) internal pure returns (uint) {
        uint rewardPercent = 0;

        if (amount > 175 * (10**fourRXTokenDecimals)) {
            rewardPercent = 50; // 0.5%
        } else if (amount > 150 * (10**fourRXTokenDecimals)) {
            rewardPercent = 40; // 0.4%
        } else if (amount > 135 * (10**fourRXTokenDecimals)) {
            rewardPercent = 35; // 0.35%
        } else if (amount > 119 * (10**fourRXTokenDecimals)) {
            rewardPercent = 30; // 0.3%
        } else if (amount > 100 * (10**fourRXTokenDecimals)) {
            rewardPercent = 25; // 0.25%
        } else if (amount > 89 * (10**fourRXTokenDecimals)) {
            rewardPercent = 20; // 0.2%
        } else if (amount > 75 * (10**fourRXTokenDecimals)) {
            rewardPercent = 15; // 0.15%
        } else if (amount > 59 * (10**fourRXTokenDecimals)) {
            rewardPercent = 10; // 0.1%
        } else if (amount > 45 * (10**fourRXTokenDecimals)) {
            rewardPercent = 5; // 0.05%
        } else if (amount > 20 * (10**fourRXTokenDecimals)) {
            rewardPercent = 2; // 0.02%
        } else if (amount > 9 * (10**fourRXTokenDecimals)) {
            rewardPercent = 1; // 0.01%
        }

        return _calcPercentage(amount, rewardPercent);
    }

    function _calcContractBonus(Stake memory stake) internal view returns (uint) {
        uint contractBonusPercent = fourRXToken.balanceOf(address(this)).mul(CONTRACT_BONUS_PER_UNIT_BP).div(CONTRACT_BONUS_UNIT).div(10**fourRXTokenDecimals);

        if (contractBonusPercent > MAX_CONTRACT_BONUS_BP) {
            contractBonusPercent = MAX_CONTRACT_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, contractBonusPercent);
    }

    function _calcHoldRewards(Stake memory stake) internal view returns (uint) {
        uint holdBonusPercent = (block.timestamp).sub(stake.holdFrom).div(HOLD_BONUS_UNIT).mul(HOLD_BONUS_PER_UNIT_BP);

        if (holdBonusPercent > MAX_HOLD_BONUS_BP) {
            holdBonusPercent = MAX_HOLD_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, holdBonusPercent);
    }

    function _calcRewardsWithoutHoldBonus(Stake memory stake) internal view returns (uint) {
        uint interest = _calcPercentage(stake.deposit, _getInterestTillDays(_calcDays(stake.interestCountFrom, block.timestamp)));

        uint contractBonus = _calcContractBonus(stake);

        uint totalRewardsWithoutHoldBonus = stake.rewards.add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(Stake memory stake) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(stake);

        if (_calcBasisPoints(stake.deposit, rewards) >= REWARD_THRESHOLD_BP) {
            rewards = rewards.add(_calcHoldRewards(stake));
        }

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function _calcPenalty(Stake memory stake, uint withdrawalAmount) internal pure returns (uint) {
        uint basisPoints = _calcBasisPoints(stake.deposit, withdrawalAmount);
        // If user's rewards are more then REWARD_THRESHOLD_BP -- No penalty
        if (basisPoints >= REWARD_THRESHOLD_BP) {
            return 0;
        }

        return _calcPercentage(withdrawalAmount, PERCENT_MULTIPLIER.sub(basisPoints.mul(PERCENT_MULTIPLIER).div(REWARD_THRESHOLD_BP)));
    }
}

// File: contracts/Insurance.sol


pragma solidity ^0.6.12;


contract Insurance is RewardsAndPenalties {
    uint private constant BASE_INSURANCE_FOR_BP = 3500; // trigger insurance with contract balance fall below 35%
    uint private constant OPT_IN_INSURANCE_FEE_BP = 1000; // 10%
    uint private constant OPT_IN_INSURANCE_FOR_BP = 10000; // 100%

    bool public isInInsuranceState; // if contract is only allowing insured money this becomes true;

    function _checkForBaseInsuranceTrigger() internal {
        if (fourRXToken.balanceOf(address(this)) <= _calcPercentage(maxContractBalance, BASE_INSURANCE_FOR_BP)) {
            isInInsuranceState = true;
        } else {
            isInInsuranceState = false;
        }
    }

    function _getInsuredAvailableAmount(Stake memory stake, uint withdrawalAmount) internal pure returns (uint)
    {
        uint availableAmount = withdrawalAmount;
        // Calc correct insured value by checking which insurance should be applied
        uint insuredFor = BASE_INSURANCE_FOR_BP;
        if (stake.optInInsured) {
            insuredFor = OPT_IN_INSURANCE_FOR_BP;
        }

        uint maxWithdrawalAllowed = _calcPercentage(stake.deposit, insuredFor);

        require(maxWithdrawalAllowed >= stake.withdrawn.add(stake.penalty), 'FF: 1114'); // if contract is in insurance trigger, do not allow withdrawals for the users who already have withdrawn more then 35%

        if (stake.withdrawn.add(availableAmount).add(stake.penalty) > maxWithdrawalAllowed) {
            availableAmount = maxWithdrawalAllowed.sub(stake.withdrawn).sub(stake.penalty);
        }

        return availableAmount;
    }

    function _insureStake(address user, Stake storage stake) internal {
        require(!stake.optInInsured && stake.active, 'FF: 1115');
        require(fourRXToken.transferFrom(user, address(this), _calcPercentage(stake.deposit, OPT_IN_INSURANCE_FEE_BP)), 'FF: 1116');

        stake.optInInsured = true;
    }
}

// File: contracts/FourRXFinance.sol


pragma solidity ^0.6.12;


/// @title 4RX Finance Staking DAPP Contract
/// @notice Available functionality: Deposit, Withdraw, ExitProgram, Insure Stake
contract FourRXFinance is Insurance, Initializable {

    function initialize(address _devAddress, address fourRXTokenAddress) public initializer {
        devAddress = _devAddress;
        fourRXToken = IERC20(fourRXTokenAddress);

        refPoolBonuses = [2000, 1700, 1400, 1100, 1000, 700, 600, 500, 400, 300, 200, 100];
        sponsorPoolBonuses = [3000, 2000, 1200, 1000, 800, 700, 600, 400, 200, 100];

        _resetPools();

        poolCycle = 0;

        isInInsuranceState = false;
    }

    function deposit(uint amount, address uplinkAddress, uint8 uplinkStakeId) external {
        require(
            uplinkAddress == address(0) ||
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active)
        , 'FF: 1100'); // Either uplink must be registered and be a active deposit or 0 address

        User storage user = users[msg.sender];

        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2), 'FF: 1101'); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount), 'FF: 1102');

        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = uint8(user.stakes.length);
        stake.active = true;
        stake.interestCountFrom = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.origDeposit = amount;
        stake.deposit = amount.sub(_calcPercentage(amount, LP_FEE_BP)); // Deduct LP Commission
        stake.rewards = depositReward;

        _updateSponsorPoolUsers(user, stake);

        if (uplinkAddress != address(0)) {
            _distributeReferralReward(amount, stake, uplinkAddress, uplinkStakeId);
        }

        user.stakes.push(stake);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));

        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        devBalance = devBalance.add(_calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

//        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, amount, stake.id,  uplinkAddress, uplinkStakeId);
    }


    function balanceOf(address _userAddress, uint stakeId) public view returns (uint) {
        require(users[_userAddress].wallet == _userAddress, 'FF: 1103');
        User memory user = users[_userAddress];

        return _calcRewards(user.stakes[stakeId]).sub(user.stakes[stakeId].withdrawn);
    }

    function withdraw(uint stakeId) external {
        User storage user = users[msg.sender];
        Stake storage stake = user.stakes[stakeId];
        require(user.wallet == msg.sender && stake.active, 'FF: 1104'); // stake should be active

        require(stake.lastWithdrawalAt + 1 days < block.timestamp, 'FF: 1105'); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(stake).sub(stake.withdrawn).sub(stake.penalty);

        require(availableAmount > 0, 'FF: 1106');

        uint penalty = _calcPenalty(stake, availableAmount);

        if (penalty == 0) {
            availableAmount = availableAmount.sub(_calcPercentage(stake.deposit, REWARD_THRESHOLD_BP)); // Only allow withdrawal if available is more then 10% of base

            uint maxAllowedWithdrawal = _calcPercentage(stake.deposit, MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            availableAmount = _getInsuredAvailableAmount(stake, availableAmount);
        }

        availableAmount = availableAmount.sub(penalty);

        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.penalty = stake.penalty.add(penalty);

        if (stake.withdrawn >= _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP)) {
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
        }

        _checkForBaseInsuranceTrigger();

        fourRXToken.transfer(user.wallet, availableAmount);

        emit Withdrawn(user.wallet, availableAmount);
    }

    function exitProgram(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1107');
        Stake storage stake = user.stakes[stakeId];

        require(stake.active, 'FF: 1108');
        require(_calcDays(stake.interestCountFrom, block.timestamp) <= 150, 'FF: 1109'); // No exit after 150 days

        uint penaltyAmount = _calcPercentage(stake.origDeposit, EXIT_PENALTY_BP);
        uint balance = balanceOf(msg.sender, stakeId);

        uint availableAmount = stake.deposit + balance - penaltyAmount; // (deposit - entry fee + (rewards - withdrawn) - penalty)

        if (availableAmount > 0) {
            fourRXToken.transfer(user.wallet, availableAmount);
            stake.withdrawn = stake.withdrawn.add(availableAmount);
        }

        stake.active = false;
        stake.penalty = stake.penalty.add(penaltyAmount);

//        totalExited = totalExited.add(1);

        emit Exited(user.wallet, stakeId, availableAmount > 0 ? availableAmount : 0);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1110');
        Stake storage stake = user.stakes[stakeId];
        _insureStake(user.wallet, stake);
    }

    // Getters

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getContractInfo() external view returns (uint, bool) {
        return (maxContractBalance, isInInsuranceState);
    }

    function withdrawDevFee(address withdrawingAddress, uint amount) external {
        require(msg.sender == devAddress, 'FF: 1111');
        require(amount <= devBalance, 'FF: 1112');
        devBalance = devBalance.sub(amount);
        fourRXToken.transfer(withdrawingAddress, amount);
    }

    function updateDevAddress(address newDevAddress) external {
        require(msg.sender == devAddress, 'FF: 1113');
        devAddress = newDevAddress;
    }
}