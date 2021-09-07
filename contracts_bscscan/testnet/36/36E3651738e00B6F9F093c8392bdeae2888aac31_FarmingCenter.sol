/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// File: openzeppelin-solidity/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity >=0.6.0 <0.8.0;

// File: contracts/lib/Ownable.sol

pragma solidity >=0.4.0;


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
    constructor() public {}

    function initializeOwner(address ownerAddr) internal {
        _owner = ownerAddr;
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

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// File: contracts/interface/IFarm.sol

pragma solidity 0.6.12;


interface IFarm {
    function initialize(address _owner, IBEP20 _sbf, address taxVault) external;
    function startFarmingPeriod(uint256 farmingPeriod, uint256 startHeight, uint256 sbfRewardPerBlock) external;
    function addPool(uint256 _allocPoint, IBEP20 _lpToken, uint256 maxTaxPercent, uint256 miniTaxFreeDay, bool _withUpdate) external;
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    function deposit(uint256 _pid, uint256 _amount, address _userAddr) external;
    function withdraw(uint256 _pid, uint256 _amount, address _userAddr) external;
    function redeemSBF(address _recipient) external;

    function pendingSBF(uint256 _pid, address _user) external view returns (uint256);
    function lpSupply(uint256 _pid) external view returns (uint256);

    function stopFarmingPhase() external;
}

// File: contracts/interface/IMintBurnToken.sol

pragma solidity ^0.6.0;

interface IMintBurnToken {

    function mintTo(address to, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

// File: @pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol



pragma solidity >=0.4.0;

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

// File: @pancakeswap/pancake-swap-lib/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

// File: contracts/FarmingCenter.sol

pragma solidity 0.6.12;
//pragma experimental ABIEncoderV2;







contract FarmingCenter is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct FarmingInfo {
        address userAddr;
        uint256 poolID;
        uint256 amount;
        uint256 timestamp;
        uint256 farmingPhaseAmount;
    }
    
    uint256 constant public POOL_ID_SBF = 0;
    uint256 constant public POOL_ID_LP_LBNB_BNB = 1;
    uint256 constant public POOL_ID_LP_SBF_BUSD = 2;

    //TODO change to 86400 for mainnet
    uint256 constant public ONE_DAY = 1; // 86400

    bool public initialized;
    bool public pool_initialized;

    address public aSBF;
    address public aLBNB2BNBLP;
    address public aSBF2BUSDLP;

    uint256 public farmingIdx;
    mapping(uint256 => FarmingInfo) public farmingInfoMap;
    mapping(address => mapping(uint256 => uint256[])) public userToFarmingIDsMap;
    mapping(uint256 => uint256) public poolAllocPoints;

    IBEP20 public sbf;
    IBEP20 public lpLBNB2BNB;
    IBEP20 public lpSBF2BUSD;

    IFarm public farmingPhase1;
    IFarm public farmingPhase2;
    IFarm public farmingPhase3;
    IFarm public farmingPhase4;

    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public sbfRewardPerBlock;

    event Deposit(address indexed userInfo, uint256 indexed pid, uint256 amount, uint256 reward);
    event Withdraw(address indexed userInfo, uint256 indexed pid, uint256 amount, uint256 reward);
    event WithdrawTax(address indexed lpAddr, address indexed userAddr, uint256 amount);
    event EmergencyWithdraw(address indexed userInfo, uint256 indexed pid, uint256 amount);

    constructor() public {}

    function initialize(
        address _owner,
        address _aSBF,
        address _aLBNB2BNBLP,
        address _aSBF2BUSDLP,

        IBEP20 _sbf,
        IBEP20 _lpLBNB2BNB,
        IBEP20 _lpSBF2BUSD,

        IFarm _farmingPhase1,
        IFarm _farmingPhase2,
        IFarm _farmingPhase3,
        IFarm _farmingPhase4,
        address _taxVault
    ) public {
        require(!initialized, "already initialized");
        initialized = true;

        super.initializeOwner(_owner);

        aSBF = _aSBF;
        aLBNB2BNBLP = _aLBNB2BNBLP;
        aSBF2BUSDLP = _aSBF2BUSDLP;

        sbf = _sbf;
        lpLBNB2BNB = _lpLBNB2BNB;
        lpSBF2BUSD = _lpSBF2BUSD;

        farmingPhase1 = _farmingPhase1;
        farmingPhase2 = _farmingPhase2;
        farmingPhase3 = _farmingPhase3;
        farmingPhase4 = _farmingPhase4;

        farmingPhase1.initialize(address(this), _sbf, _taxVault);
        farmingPhase2.initialize(address(this), _sbf, _taxVault);
        farmingPhase3.initialize(address(this), _sbf, _taxVault);
        farmingPhase4.initialize(address(this), _sbf, _taxVault);
    }

    function initPools(uint256[] calldata _allocPoints, uint256[] calldata _maxTaxPercents, uint256[] calldata _miniTaxFreeDays, bool _withUpdate) external onlyOwner {
        require(initialized, "farm is not initialized");
        require(!pool_initialized, "farms are already initialized");
        pool_initialized = true;

        require(_allocPoints.length==3&&_maxTaxPercents.length==3&&_miniTaxFreeDays.length==3, "wrong array length");

        poolAllocPoints[POOL_ID_SBF] = _allocPoints[0];
        farmingPhase1.addPool(_allocPoints[0], sbf, _maxTaxPercents[0], _miniTaxFreeDays[0], _withUpdate);
        farmingPhase2.addPool(_allocPoints[0], sbf, _maxTaxPercents[0], _miniTaxFreeDays[0], _withUpdate);
        farmingPhase3.addPool(_allocPoints[0], sbf, _maxTaxPercents[0], _miniTaxFreeDays[0], _withUpdate);
        farmingPhase4.addPool(_allocPoints[0], sbf, _maxTaxPercents[0], _miniTaxFreeDays[0], _withUpdate);

        poolAllocPoints[POOL_ID_LP_LBNB_BNB] = _allocPoints[1];
        farmingPhase1.addPool(_allocPoints[1], lpLBNB2BNB, _maxTaxPercents[1], _miniTaxFreeDays[1], _withUpdate);
        farmingPhase2.addPool(_allocPoints[1], lpLBNB2BNB, _maxTaxPercents[1], _miniTaxFreeDays[1], _withUpdate);
        farmingPhase3.addPool(_allocPoints[1], lpLBNB2BNB, _maxTaxPercents[1], _miniTaxFreeDays[1], _withUpdate);
        farmingPhase4.addPool(_allocPoints[1], lpLBNB2BNB, _maxTaxPercents[1], _miniTaxFreeDays[1], _withUpdate);

        poolAllocPoints[POOL_ID_LP_SBF_BUSD] = _allocPoints[2];
        farmingPhase1.addPool(_allocPoints[2], lpSBF2BUSD, _maxTaxPercents[2], _miniTaxFreeDays[2], _withUpdate);
        farmingPhase2.addPool(_allocPoints[2], lpSBF2BUSD, _maxTaxPercents[2], _miniTaxFreeDays[2], _withUpdate);
        farmingPhase3.addPool(_allocPoints[2], lpSBF2BUSD, _maxTaxPercents[2], _miniTaxFreeDays[2], _withUpdate);
        farmingPhase4.addPool(_allocPoints[2], lpSBF2BUSD, _maxTaxPercents[2], _miniTaxFreeDays[2], _withUpdate);
    }

    function startFarmingPeriod(uint256 _farmingPeriod, uint256 _startHeight, uint256 _sbfRewardPerBlock) public onlyOwner {
        require(pool_initialized, "farm pools are not initialized");

        startBlock = _startHeight;
        endBlock = _startHeight.add(_farmingPeriod);

        uint256 totalSBFAmount = _farmingPeriod.mul(_sbfRewardPerBlock);
        sbf.safeTransferFrom(msg.sender, address(this), totalSBFAmount);

        sbf.approve(address(farmingPhase1), totalSBFAmount.mul(10).div(100));
        sbf.approve(address(farmingPhase2), totalSBFAmount.mul(30).div(100));
        sbf.approve(address(farmingPhase3), totalSBFAmount.mul(30).div(100));
        sbf.approve(address(farmingPhase4), totalSBFAmount.mul(30).div(100));

        farmingPhase1.startFarmingPeriod(_farmingPeriod, _startHeight, _sbfRewardPerBlock.mul(10).div(100));
        farmingPhase2.startFarmingPeriod(_farmingPeriod, _startHeight, _sbfRewardPerBlock.mul(30).div(100));
        farmingPhase3.startFarmingPeriod(_farmingPeriod, _startHeight, _sbfRewardPerBlock.mul(30).div(100));
        farmingPhase4.startFarmingPeriod(_farmingPeriod, _startHeight, _sbfRewardPerBlock.mul(30).div(100));

        sbfRewardPerBlock = _sbfRewardPerBlock;
    }

    /*
     pid 0 -> sbf pool
     pid 1 -> lbnb2bnb pool
     pid 2 -> sbf2busd pool
    */
    function set(uint256 _pid, uint256 _allocPoints, bool _withUpdate) public onlyOwner {
        poolAllocPoints[_pid] = _allocPoints;

        farmingPhase1.set(_pid, _allocPoints, _withUpdate);
        farmingPhase2.set(_pid, _allocPoints, _withUpdate);
        farmingPhase3.set(_pid, _allocPoints, _withUpdate);
        farmingPhase4.set(_pid, _allocPoints, _withUpdate);
    }

    function redeemSBF() public onlyOwner {
        require(block.number>=endBlock, "farming is not end");
        farmingPhase1.redeemSBF(msg.sender);
        farmingPhase2.redeemSBF(msg.sender);
        farmingPhase3.redeemSBF(msg.sender);
        farmingPhase4.redeemSBF(msg.sender);
    }

    function pendingSBF(uint256 _pid, address _user) external view returns (uint256) {
        return farmingPhase1.pendingSBF(_pid, _user).
        add(farmingPhase2.pendingSBF(_pid, _user)).
        add(farmingPhase3.pendingSBF(_pid, _user)).
        add(farmingPhase4.pendingSBF(_pid, _user));
    }

    function getUserFarmingIdxs(uint256 _pid, address _user) external view returns(uint256[] memory) {
        return userToFarmingIDsMap[_user][_pid];
    }

    function farmingSpeed(uint256 _pid, address _user) external view returns (uint256) {
        uint256[] memory farmingIdxs = userToFarmingIDsMap[_user][_pid];
        uint256 farmingIdxsLength = farmingIdxs.length;

        uint256[] memory phaseAmountArray = new uint256[](4);
        for (uint256 idx=0;idx<farmingIdxsLength;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[farmingIdxs[idx]];
            if (farmingInfo.poolID != _pid) {
                continue;
            }
            phaseAmountArray[farmingInfo.farmingPhaseAmount-1] = phaseAmountArray[farmingInfo.farmingPhaseAmount-1].add(farmingInfo.amount);
        }
        uint256 totalAllocPoints = poolAllocPoints[0].add(poolAllocPoints[1]).add(poolAllocPoints[2]);
        uint256 poolSBFRewardPerBlock = sbfRewardPerBlock.mul(poolAllocPoints[_pid]).div(totalAllocPoints);

        uint256 totalPhaseAmount;
        uint256 accumulatePhaseAmount = phaseAmountArray[3];
        if (farmingPhase4.lpSupply(_pid)!=0) {
            totalPhaseAmount = totalPhaseAmount.add(accumulatePhaseAmount.mul(30).mul(poolSBFRewardPerBlock).div(farmingPhase4.lpSupply(_pid)));
        }

        accumulatePhaseAmount = accumulatePhaseAmount.add(phaseAmountArray[2]);
        if (farmingPhase3.lpSupply(_pid)!=0) {
            totalPhaseAmount = totalPhaseAmount.add(accumulatePhaseAmount.mul(30).mul(poolSBFRewardPerBlock).div(farmingPhase3.lpSupply(_pid)));
        }

        accumulatePhaseAmount = accumulatePhaseAmount.add(phaseAmountArray[1]);
        if (farmingPhase2.lpSupply(_pid)!=0) {
            totalPhaseAmount = totalPhaseAmount.add(accumulatePhaseAmount.mul(30).mul(poolSBFRewardPerBlock).div(farmingPhase2.lpSupply(_pid)));
        }

        accumulatePhaseAmount = accumulatePhaseAmount.add(phaseAmountArray[0]);
        if (farmingPhase1.lpSupply(_pid)!=0) {
            totalPhaseAmount = totalPhaseAmount.add(accumulatePhaseAmount.mul(10).mul(poolSBFRewardPerBlock).div(farmingPhase1.lpSupply(_pid)));
        }

        return totalPhaseAmount.div(100);
    }

    function depositSBFPool(uint256 _amount) public {
        if (_amount>0){
            farmingInfoMap[farmingIdx] = FarmingInfo({
                userAddr: msg.sender,
                poolID: POOL_ID_SBF,
                amount: _amount,
                timestamp: block.timestamp,
                farmingPhaseAmount: 1
            });
            userToFarmingIDsMap[msg.sender][POOL_ID_SBF].push(farmingIdx);
            farmingIdx++;
        }

        sbf.safeTransferFrom(address(msg.sender), address(this), _amount);

        farmingPhase1.deposit(POOL_ID_SBF, _amount, msg.sender);
        IMintBurnToken(aSBF).mintTo(msg.sender, _amount);
    }

    function withdrawSBFPool(uint256 _amount, uint256 _farmingIdx) public {
        FarmingInfo storage farmingInfo = farmingInfoMap[_farmingIdx];
        require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
        require(farmingInfo.poolID==POOL_ID_SBF, "pool id mismatch");
        require(farmingInfo.amount>=_amount, "withdraw amount too much");

        IBEP20(aSBF).transferFrom(msg.sender, address(this), _amount);
        IMintBurnToken(aSBF).burn(_amount);

        if (farmingInfo.farmingPhaseAmount >= 4) {
            farmingPhase4.withdraw(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
        }
        if (farmingInfo.farmingPhaseAmount >= 3) {
            farmingPhase3.withdraw(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
        }
        if (farmingInfo.farmingPhaseAmount >= 2) {
            farmingPhase2.withdraw(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
        }
        farmingPhase1.withdraw(POOL_ID_SBF, _amount, farmingInfo.userAddr);

        if (farmingInfo.amount == _amount) {
            uint256[] storage farmingIdxs = userToFarmingIDsMap[msg.sender][POOL_ID_SBF];
            uint256 farmingIdxsLength = farmingIdxs.length;
            for (uint256 idx=0;idx<farmingIdxsLength;idx++){
                if (farmingIdxs[idx]==_farmingIdx) {
                    farmingIdxs[idx]=farmingIdxs[farmingIdxsLength-1];
                    break;
                }
            }
            farmingIdxs.pop();
            delete farmingInfoMap[_farmingIdx];
        } else {
            farmingInfo.amount = farmingInfo.amount.sub(_amount);
            farmingInfo.farmingPhaseAmount = 1;
            farmingInfo.timestamp = block.timestamp;
        }
        sbf.safeTransfer(address(msg.sender), _amount);
    }

    function batchWithdrawSBFPool(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            withdrawSBFPool(farmingInfo.amount, _farmingIdxs[idx]);
        }
    }

    function depositLBNB2BNBPool(uint256 _amount) public {
        if (_amount>0){
            farmingInfoMap[farmingIdx] = FarmingInfo({
                userAddr: msg.sender,
                poolID: POOL_ID_LP_LBNB_BNB,
                amount: _amount,
                timestamp: block.timestamp,
                farmingPhaseAmount: 4
            });
            userToFarmingIDsMap[msg.sender][POOL_ID_LP_LBNB_BNB].push(farmingIdx);
            farmingIdx++;

            lpLBNB2BNB.safeTransferFrom(address(msg.sender), address(this), _amount);
        }

        farmingPhase1.deposit(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase2.deposit(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase3.deposit(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase4.deposit(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        
        IMintBurnToken(aLBNB2BNBLP).mintTo(msg.sender, _amount);
    }

    function withdrawLBNB2BNBPool(uint256 _amount, uint256 _farmingIdx) public {
        FarmingInfo storage farmingInfo = farmingInfoMap[_farmingIdx];
        require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
        require(farmingInfo.poolID==POOL_ID_LP_LBNB_BNB, "pool id mismatch");
        require(_amount>0, "withdraw amount must be positive");
        require(farmingInfo.amount>=_amount, "withdraw amount too much");
        
        IBEP20(aLBNB2BNBLP).transferFrom(msg.sender, address(this), _amount);
        IMintBurnToken(aLBNB2BNBLP).burn(_amount);

        farmingPhase4.withdraw(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase3.withdraw(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase2.withdraw(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);
        farmingPhase1.withdraw(POOL_ID_LP_LBNB_BNB, _amount, msg.sender);

        lpLBNB2BNB.safeTransfer(msg.sender, _amount);

        if (farmingInfo.amount == _amount) {
            uint256[] storage farmingIdxs = userToFarmingIDsMap[msg.sender][POOL_ID_LP_LBNB_BNB];
            uint256 farmingIdxsLength = farmingIdxs.length;
            for (uint256 idx=0;idx<farmingIdxsLength;idx++){
                if (farmingIdxs[idx]==_farmingIdx) {
                    farmingIdxs[idx]=farmingIdxs[farmingIdxsLength-1];
                    break;
                }
            }
            farmingIdxs.pop();
            delete farmingInfoMap[_farmingIdx];
        } else {
            farmingInfo.amount = farmingInfo.amount.sub(_amount);
            farmingInfo.timestamp = block.timestamp;
        }
    }

    function batchWithdrawLBNB2BNBPool(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            withdrawLBNB2BNBPool(farmingInfo.amount, _farmingIdxs[idx]);
        }
    }

    function depositSBF2BUSDPool(uint256 _amount) public {
        if (_amount>0){
            farmingInfoMap[farmingIdx] = FarmingInfo({
                userAddr: msg.sender,
                poolID: POOL_ID_LP_SBF_BUSD,
                amount: _amount,
                timestamp: block.timestamp,
                farmingPhaseAmount: 3
            });
            userToFarmingIDsMap[msg.sender][POOL_ID_LP_SBF_BUSD].push(farmingIdx);
            farmingIdx++;
        }

        lpSBF2BUSD.safeTransferFrom(address(msg.sender), address(this), _amount);

        farmingPhase1.deposit(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);
        farmingPhase2.deposit(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);
        farmingPhase3.deposit(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);

        IMintBurnToken(aSBF2BUSDLP).mintTo(msg.sender, _amount);
    }

    function withdrawSBF2BUSDPool(uint256 _amount, uint256 _farmingIdx) public {
        FarmingInfo storage farmingInfo = farmingInfoMap[_farmingIdx];
        require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
        require(farmingInfo.poolID==POOL_ID_LP_SBF_BUSD, "pool id mismatch");
        require(_amount>0, "withdraw amount must be positive");
        require(farmingInfo.amount>=_amount, "withdraw amount too much");

        IBEP20(aSBF2BUSDLP).transferFrom(msg.sender, address(this), _amount);
        IMintBurnToken(aSBF2BUSDLP).burn(_amount);

        if (farmingInfo.farmingPhaseAmount >= 4) {
            farmingPhase4.withdraw(POOL_ID_LP_SBF_BUSD, farmingInfo.amount, msg.sender);
        }
        farmingPhase3.withdraw(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);
        farmingPhase2.withdraw(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);
        farmingPhase1.withdraw(POOL_ID_LP_SBF_BUSD, _amount, msg.sender);

        lpSBF2BUSD.safeTransfer(msg.sender, _amount);

        if (farmingInfo.amount == _amount) {
            uint256[] storage farmingIdxs = userToFarmingIDsMap[msg.sender][POOL_ID_LP_SBF_BUSD];
            uint256 farmingIdxsLength = farmingIdxs.length;
            for (uint256 idx=0;idx<farmingIdxsLength;idx++){
                if (farmingIdxs[idx]==_farmingIdx) {
                    farmingIdxs[idx]=farmingIdxs[farmingIdxsLength-1];
                    break;
                }
            }
            farmingIdxs.pop();
            delete farmingInfoMap[_farmingIdx];
        } else {
            farmingInfo.amount = farmingInfo.amount.sub(_amount);
            farmingInfo.farmingPhaseAmount = 3;
            farmingInfo.timestamp = block.timestamp;
        }
    }

    function batchWithdrawSBF2BUSDPool(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            withdrawSBF2BUSDPool(farmingInfo.amount, _farmingIdxs[idx]);
        }
    }

    function harvest(uint256 _pid) public {
        require(_pid==POOL_ID_SBF|| _pid==POOL_ID_LP_SBF_BUSD|| _pid==POOL_ID_LP_LBNB_BNB, "wrong pool id");
        farmingPhase1.deposit(_pid, 0, msg.sender);
        farmingPhase2.deposit(_pid, 0, msg.sender);
        farmingPhase3.deposit(_pid, 0, msg.sender);
        farmingPhase4.deposit(_pid, 0, msg.sender);
    }

    function emergencyWithdrawSBF(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
            require(farmingInfo.poolID==POOL_ID_SBF, "pool id mismatch");
            sbf.safeTransfer(address(msg.sender), farmingInfo.amount);
            emit EmergencyWithdraw(msg.sender, POOL_ID_SBF, farmingInfo.amount);
            delete farmingInfoMap[_farmingIdxs[idx]];
            deleteUserFarmingIDs(_farmingIdxs[idx], POOL_ID_SBF);
        }
    }

    function emergencyWithdrawLBNB2BNBLP(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
            require(farmingInfo.poolID==POOL_ID_LP_LBNB_BNB, "pool id mismatch");
            lpLBNB2BNB.safeTransfer(address(msg.sender), farmingInfo.amount);
            emit EmergencyWithdraw(msg.sender, POOL_ID_LP_LBNB_BNB, farmingInfo.amount);
            delete farmingInfoMap[_farmingIdxs[idx]];
            deleteUserFarmingIDs(_farmingIdxs[idx], POOL_ID_LP_LBNB_BNB);
        }
    }

    function emergencyWithdrawSBF2BUSDLP(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            FarmingInfo memory farmingInfo = farmingInfoMap[_farmingIdxs[idx]];
            require(farmingInfo.userAddr==msg.sender, "can't withdraw other farming");
            require(farmingInfo.poolID==POOL_ID_LP_SBF_BUSD, "pool id mismatch");
            lpSBF2BUSD.safeTransfer(address(msg.sender), farmingInfo.amount);
            emit EmergencyWithdraw(msg.sender, POOL_ID_LP_SBF_BUSD, farmingInfo.amount);
            delete farmingInfoMap[_farmingIdxs[idx]];
            deleteUserFarmingIDs(_farmingIdxs[idx], POOL_ID_LP_SBF_BUSD);
        }
    }

    function deleteUserFarmingIDs(uint256 _idx, uint256 _pid) internal {
        uint256[] storage farmingIdxs = userToFarmingIDsMap[msg.sender][_pid];
        uint256 farmingIdxsLength = farmingIdxs.length;
        for (uint256 idx=0;idx<farmingIdxsLength;idx++){
            if (farmingIdxs[idx]==_idx) {
                farmingIdxs[idx]=farmingIdxs[farmingIdxsLength-1];
                break;
            }
        }
        farmingIdxs.pop();
    }

    function migrateSBFPoolAgeFarming(uint256 _farmingIdx) public {
        bool needMigration = false;
        FarmingInfo storage farmingInfo = farmingInfoMap[_farmingIdx];
        require(farmingInfo.userAddr!=address(0x0), "empty farming info");
        require(farmingInfo.poolID==POOL_ID_SBF, "pool id mismatch");
        if (block.timestamp-farmingInfo.timestamp>7*ONE_DAY&&farmingInfo.farmingPhaseAmount<2) {
            farmingPhase2.deposit(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
            farmingInfo.farmingPhaseAmount = 2;
            needMigration = true;
        }
        if (block.timestamp-farmingInfo.timestamp>30*ONE_DAY&&farmingInfo.farmingPhaseAmount<3) {
            farmingPhase3.deposit(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
            farmingInfo.farmingPhaseAmount = 3;
            needMigration = true;
        }
        if (block.timestamp-farmingInfo.timestamp>60*ONE_DAY&&farmingInfo.farmingPhaseAmount<4) {
            farmingPhase4.deposit(POOL_ID_SBF, farmingInfo.amount, farmingInfo.userAddr);
            farmingInfo.farmingPhaseAmount = 4;
            needMigration = true;
        }
        require(needMigration, "no need to migration");
    }

    function batchMigrateSBFPoolAgeFarming(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            migrateSBFPoolAgeFarming(_farmingIdxs[idx]);
        }
    }

    function migrateSBF2BUSDPoolAgeFarming(uint256 _farmingIdx) public {
        bool needMigration = false;
        FarmingInfo storage farmingInfo = farmingInfoMap[_farmingIdx];
        require(farmingInfo.userAddr!=address(0x0), "empty farming info");
        require(farmingInfo.poolID==POOL_ID_LP_SBF_BUSD, "pool id mismatch");
        if (block.timestamp-farmingInfo.timestamp>60*ONE_DAY&&farmingInfo.farmingPhaseAmount<4) {
            farmingPhase4.deposit(POOL_ID_LP_SBF_BUSD, farmingInfo.amount, farmingInfo.userAddr);
            farmingInfo.farmingPhaseAmount = 4;
            needMigration = true;
        }
        require(needMigration, "no need to migration");
    }

    function batchMigrateSBF2BUSDPoolAgeFarming(uint256[] memory _farmingIdxs) public {
        for(uint256 idx=0;idx<_farmingIdxs.length;idx++){
            migrateSBF2BUSDPoolAgeFarming(_farmingIdxs[idx]);
        }
    }

    function stopFarming() public onlyOwner {
        farmingPhase1.stopFarmingPhase();
        farmingPhase2.stopFarmingPhase();
        farmingPhase3.stopFarmingPhase();
        farmingPhase4.stopFarmingPhase();
    }
}