// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IncentiveDistribution.sol";
import "./RoleAware.sol";
import "./Fund.sol";
import "./CrossMarginTrading.sol";

/** 
@title Here we support staking for MFI incentives as well as
staking to perform the maintenance role.
*/
contract Admin is RoleAware {
    /// Margenswap (MFI) token address
    address public immutable MFI;
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;

    uint256 public constant mfiStakeTranche = 1;

    uint256 public maintenanceStakePerBlock = 15 ether;
    mapping(address => address) public nextMaintenanceStaker;
    mapping(address => mapping(address => bool)) public maintenanceDelegateTo;
    address public currentMaintenanceStaker;
    address public prevMaintenanceStaker;
    uint256 public currentMaintenanceStakerStartBlock;
    address public immutable lockedMFI;

    constructor(
        address _MFI,
        address _lockedMFI,
        address lockedMFIDelegate,
        address _roles
    ) RoleAware(_roles) {
        MFI = _MFI;
        lockedMFI = _lockedMFI;

        // for initialization purposes and to ensure availability of service
        // the team's locked MFI participate in maintenance staking only
        // (not in the incentive staking part)
        // this implies some trust of the team to execute, which we deem reasonable
        // since the locked stake is temporary and diminishing as well as the fact
        // that the team is heavily invested in the protocol and incentivized
        // by fees like any other maintainer
        // furthermore others could step in to liquidate via the attacker route
        // and take away the team fees if they were delinquent
        nextMaintenanceStaker[_lockedMFI] = _lockedMFI;
        currentMaintenanceStaker = _lockedMFI;
        prevMaintenanceStaker = _lockedMFI;
        maintenanceDelegateTo[_lockedMFI][lockedMFIDelegate];
        currentMaintenanceStakerStartBlock = block.number;
    }

    /// Maintence stake setter
    function setMaintenanceStakePerBlock(uint256 amount)
        external
        onlyOwnerExec
    {
        maintenanceStakePerBlock = amount;
    }

    function _stake(address holder, uint256 amount) internal {
        Fund(fund()).depositFor(holder, MFI, amount);

        stakes[holder] += amount;
        totalStakes += amount;

        IncentiveDistribution(incentiveDistributor()).addToClaimAmount(
            mfiStakeTranche,
            holder,
            amount
        );
    }

    /// Deposit a stake for sender
    function depositStake(uint256 amount) external {
        _stake(msg.sender, amount);
    }

    function _withdrawStake(
        address holder,
        uint256 amount,
        address recipient
    ) internal {
        // overflow failure desirable
        stakes[holder] -= amount;
        totalStakes -= amount;
        Fund(fund()).withdraw(MFI, recipient, amount);

        IncentiveDistribution(incentiveDistributor()).subtractFromClaimAmount(
            mfiStakeTranche,
            holder,
            amount
        );
    }

    /// Withdraw stake for sender
    function withdrawStake(uint256 amount) external {
        require(
            !isAuthorizedStaker(msg.sender),
            "You can't withdraw while you're authorized staker"
        );
        _withdrawStake(msg.sender, amount, msg.sender);
    }

    /// Deposit maintenance stake
    function depositMaintenanceStake(uint256 amount) external {
        require(
            amount + stakes[msg.sender] >= maintenanceStakePerBlock,
            "Insufficient stake to call even one block"
        );
        _stake(msg.sender, amount);
        if (nextMaintenanceStaker[msg.sender] == address(0)) {
            nextMaintenanceStaker[msg.sender] = getUpdatedCurrentStaker();
            nextMaintenanceStaker[prevMaintenanceStaker] = msg.sender;
        }
    }

    function getMaintenanceStakerStake(address staker)
        public
        view
        returns (uint256)
    {
        if (staker == lockedMFI) {
            return IERC20(MFI).balanceOf(lockedMFI) / 2;
        } else {
            return stakes[staker];
        }
    }

    function getUpdatedCurrentStaker() public returns (address) {
        uint256 currentStake =
            getMaintenanceStakerStake(currentMaintenanceStaker);
        while (
            (block.number - currentMaintenanceStakerStartBlock) *
                maintenanceStakePerBlock >=
            currentStake
        ) {
            if (maintenanceStakePerBlock > currentStake) {
                // delete current from daisy chain
                address nextOne =
                    nextMaintenanceStaker[currentMaintenanceStaker];
                nextMaintenanceStaker[prevMaintenanceStaker] = nextOne;
                nextMaintenanceStaker[currentMaintenanceStaker] = address(0);

                currentMaintenanceStaker = nextOne;
            } else {
                currentMaintenanceStakerStartBlock +=
                    currentStake /
                    maintenanceStakePerBlock;

                prevMaintenanceStaker = currentMaintenanceStaker;
                currentMaintenanceStaker = nextMaintenanceStaker[
                    currentMaintenanceStaker
                ];
            }
            currentStake = getMaintenanceStakerStake(currentMaintenanceStaker);
        }
        return currentMaintenanceStaker;
    }

    function viewCurrentMaintenanceStaker()
        public
        view
        returns (address staker, uint256 startBlock)
    {
        staker = currentMaintenanceStaker;
        uint256 currentStake = getMaintenanceStakerStake(staker);
        startBlock = currentMaintenanceStakerStartBlock;
        while (
            (block.number - startBlock) * maintenanceStakePerBlock >=
            currentStake
        ) {
            if (currentStake >= maintenanceStakePerBlock) {
                startBlock += currentStake / maintenanceStakePerBlock;
            }
            staker = nextMaintenanceStaker[staker];
            currentStake = getMaintenanceStakerStake(staker);
        }
    }

    /// Add a delegate for staker
    function addDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = true;
    }

    /// Remove a delegate for staker
    function removeDelegate(address forStaker, address delegate) external {
        require(
            msg.sender == forStaker ||
                maintenanceDelegateTo[forStaker][msg.sender],
            "msg.sender not authorized to delegate for staker"
        );
        maintenanceDelegateTo[forStaker][delegate] = false;
    }

    function isAuthorizedStaker(address caller)
        public
        returns (bool isAuthorized)
    {
        address currentStaker = getUpdatedCurrentStaker();
        isAuthorized =
            currentStaker == caller ||
            maintenanceDelegateTo[currentStaker][caller];
    }

    /// Penalize a staker
    function penalizeMaintenanceStake(
        address maintainer,
        uint256 penalty,
        address recipient
    ) external returns (uint256 stakeTaken) {
        require(
            isStakePenalizer(msg.sender),
            "msg.sender not authorized to penalize stakers"
        );
        if (penalty > stakes[maintainer]) {
            stakeTaken = stakes[maintainer];
        } else {
            stakeTaken = penalty;
        }
        _withdrawStake(maintainer, stakeTaken, recipient);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./RoleAware.sol";

/// @title Base lending behavior
abstract contract BaseLending {
    uint256 constant FP32 = 2**32;
    uint256 constant ACCUMULATOR_INIT = 10**18;

    struct YieldAccumulator {
        uint256 accumulatorFP;
        uint256 lastUpdated;
        uint256 hourlyYieldFP;
    }

    struct LendingMetadata {
        uint256 totalLending;
        uint256 totalBorrowed;
        uint256 lendingBuffer;
        uint256 lendingCap;
    }
    mapping(address => LendingMetadata) public lendingMeta;

    /// @dev accumulate interest per issuer (like compound indices)
    mapping(address => YieldAccumulator) public borrowYieldAccumulators;

    uint256 public maxHourlyYieldFP;
    uint256 public yieldChangePerSecondFP;

    /// @dev simple formula for calculating interest relative to accumulator
    function applyInterest(
        uint256 balance,
        uint256 accumulatorFP,
        uint256 yieldQuotientFP
    ) internal pure returns (uint256) {
        // 1 * FP / FP = 1
        return (balance * accumulatorFP) / yieldQuotientFP;
    }

    /// update the yield for an asset based on recent supply and demand
    function updatedYieldFP(
        // previous yield
        uint256 yieldFP,
        // timestamp
        uint256 lastUpdated,
        uint256 totalLendingInBucket,
        uint256 bucketTarget,
        uint256 buyingSpeed,
        uint256 withdrawingSpeed,
        uint256 bucketMaxYield
    ) internal view returns (uint256) {
        uint256 timeDiff = block.timestamp - lastUpdated;
        uint256 yieldDiff = timeDiff * yieldChangePerSecondFP;

        if (
            totalLendingInBucket >= bucketTarget ||
            buyingSpeed >= withdrawingSpeed
        ) {
            yieldFP -= min(yieldFP, yieldDiff);
        } else {
            yieldFP += yieldDiff;
            if (yieldFP > bucketMaxYield) {
                yieldFP = bucketMaxYield;
            }
        }

        return max(FP32, yieldFP);
    }

    function updateSpeed(
        uint256 speed,
        uint256 lastAction,
        uint256 amount,
        uint256 runtime
    ) internal view returns (uint256 newSpeed, uint256 newLastAction) {
        uint256 timeDiff = block.timestamp - lastAction;
        uint256 updateAmount = (amount * runtime) / (timeDiff + 1);

        uint256 oldSpeedWeight = (runtime + 120 minutes) / 3;
        uint256 updateWeight = timeDiff + 1;
        // scale adjustment relative to runtime
        newSpeed =
            (speed * oldSpeedWeight + updateAmount * updateWeight) /
            (oldSpeedWeight + updateWeight);
        newLastAction = block.timestamp;
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }

    /// @dev maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

    function _makeFallbackBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal virtual;

    function lendingTarget(LendingMetadata storage meta)
        internal
        view
        returns (uint256)
    {
        return min(meta.lendingCap, meta.totalBorrowed + meta.lendingBuffer);
    }

    /// View lending target
    function viewLendingTarget(address issuer) external view returns (uint256) {
        LendingMetadata storage meta = lendingMeta[issuer];
        return lendingTarget(meta);
    }

    /// Available tokens to this issuance
    function issuanceBalance(address issuance)
        internal
        view
        virtual
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Fund.sol";
import "../libraries/UniswapStyleLib.sol";

abstract contract BaseRouter {
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Trade has expired");
        _;
    }

    // **** SWAP ****
    /// @dev requires the initial amount to have already been sent to the first pair
    /// and for pairs to be vetted (which getAmountsIn / getAmountsOut do)
    function _swap(
        uint256[] memory amounts,
        address[] memory pairs,
        address[] memory tokens,
        address _to
    ) internal {
        for (uint256 i; i < pairs.length; i++) {
            (address input, address output) = (tokens[i], tokens[i + 1]);
            (address token0, ) = UniswapStyleLib.sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) =
                input == token0
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));

            address to = i < pairs.length - 1 ? pairs[i + 1] : _to;
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);

            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "./BaseLending.sol";

struct Bond {
    address holder;
    address issuer;
    uint256 originalPrice;
    uint256 returnAmount;
    uint256 maturityTimestamp;
    uint256 runtime;
    uint256 yieldFP;
}

/** 
@title Lending for fixed runtime, fixed interest
Lenders can pick their own bond maturity date
@dev In order to manage interest rates for the different
maturities and create a yield curve we bucket
bond runtimes into weighted baskets and adjust
rates individually per bucket, based on supply and demand.
*/
abstract contract BondLending is BaseLending {
    uint256 public minRuntime = 30 days;
    uint256 public maxRuntime = 365 days;
    uint256 public diffMaxMinRuntime = maxRuntime - minRuntime;
    /** 
    @dev this is the numerator under runtimeWeights.
    any excess left over is the weight of hourly bonds
    */
    uint256 public constant WEIGHT_TOTAL_10k = 10_000;

    struct BondBucketMetadata {
        uint256 runtimeWeight;
        uint256 buyingSpeed;
        uint256 lastBought;
        uint256 withdrawingSpeed;
        uint256 lastWithdrawn;
        uint256 yieldLastUpdated;
        uint256 totalLending;
        uint256 runtimeYieldFP;
    }

    mapping(uint256 => Bond) public bonds;

    mapping(address => BondBucketMetadata[]) public bondBucketMetadata;

    uint256 public nextBondIndex = 1;

    event LiquidityWarning(
        address indexed issuer,
        address indexed holder,
        uint256 value
    );

    function _makeBond(
        address holder,
        address issuer,
        uint256 runtime,
        uint256 amount,
        uint256 minReturn
    ) internal returns (uint256 bondIndex) {
        uint256 bucketIndex = getBucketIndex(issuer, runtime);
        BondBucketMetadata storage bondMeta =
            bondBucketMetadata[issuer][bucketIndex];

        uint256 yieldFP = calcBondYieldFP(issuer, amount, runtime, bondMeta);

        uint256 bondReturn = (yieldFP * amount) / FP32;
        if (bondReturn >= minReturn) {
            uint256 interpolatedAmount = (amount + bondReturn) / 2;
            lendingMeta[issuer].totalLending += interpolatedAmount;

            bondMeta.totalLending += interpolatedAmount;

            bondIndex = nextBondIndex;
            nextBondIndex++;

            bonds[bondIndex] = Bond({
                holder: holder,
                issuer: issuer,
                originalPrice: amount,
                returnAmount: bondReturn,
                maturityTimestamp: block.timestamp + runtime,
                runtime: runtime,
                yieldFP: yieldFP
            });

            (bondMeta.buyingSpeed, bondMeta.lastBought) = updateSpeed(
                bondMeta.buyingSpeed,
                bondMeta.lastBought,
                amount,
                runtime
            );
        }
    }

    function _withdrawBond(uint256 bondId, Bond storage bond)
        internal
        returns (uint256 withdrawAmount)
    {
        address issuer = bond.issuer;
        uint256 bucketIndex = getBucketIndex(issuer, bond.runtime);
        BondBucketMetadata storage bondMeta =
            bondBucketMetadata[issuer][bucketIndex];

        uint256 returnAmount = bond.returnAmount;
        address holder = bond.holder;

        uint256 interpolatedAmount = (bond.originalPrice + returnAmount) / 2;

        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalLending -= interpolatedAmount;
        bondMeta.totalLending -= interpolatedAmount;

        (bondMeta.withdrawingSpeed, bondMeta.lastWithdrawn) = updateSpeed(
            bondMeta.withdrawingSpeed,
            bondMeta.lastWithdrawn,
            bond.originalPrice,
            bond.runtime
        );

        delete bonds[bondId];
        if (
            meta.totalBorrowed > meta.totalLending ||
            issuanceBalance(issuer) < returnAmount
        ) {
            // apparently there is a liquidity issue
            emit LiquidityWarning(issuer, holder, returnAmount);
            _makeFallbackBond(issuer, holder, returnAmount);
        } else {
            withdrawAmount = returnAmount;
        }
    }

    function calcBondYieldFP(
        address issuer,
        uint256 addedAmount,
        uint256 runtime,
        BondBucketMetadata storage bucketMeta
    ) internal view returns (uint256 yieldFP) {
        uint256 totalLendingInBucket = addedAmount + bucketMeta.totalLending;

        yieldFP = bucketMeta.runtimeYieldFP;
        uint256 lastUpdated = bucketMeta.yieldLastUpdated;

        LendingMetadata storage meta = lendingMeta[issuer];
        uint256 bucketTarget =
            (lendingTarget(meta) * bucketMeta.runtimeWeight) / WEIGHT_TOTAL_10k;

        uint256 buying = bucketMeta.buyingSpeed;
        uint256 withdrawing = bucketMeta.withdrawingSpeed;

        YieldAccumulator storage borrowAccumulator =
            borrowYieldAccumulators[issuer];

        uint256 yieldGeneratedFP =
            (borrowAccumulator.hourlyYieldFP * meta.totalBorrowed) /
                (1 + meta.totalLending);
        uint256 _maxHourlyYieldFP = min(maxHourlyYieldFP, yieldGeneratedFP);

        uint256 bucketMaxYield = _maxHourlyYieldFP * (runtime / (1 hours));

        yieldFP = updatedYieldFP(
            yieldFP,
            lastUpdated,
            totalLendingInBucket,
            bucketTarget,
            buying,
            withdrawing,
            bucketMaxYield
        );
    }

    /// Get view of returns on bond
    function viewBondReturn(
        address issuer,
        uint256 runtime,
        uint256 amount
    ) external view returns (uint256) {
        uint256 bucketIndex = getBucketIndex(issuer, runtime);
        uint256 yieldFP =
            calcBondYieldFP(
                issuer,
                amount + bondBucketMetadata[issuer][bucketIndex].totalLending,
                runtime,
                bondBucketMetadata[issuer][bucketIndex]
            );
        return (yieldFP * amount) / FP32;
    }

    function getBucketIndex(address issuer, uint256 runtime)
        internal
        view
        returns (uint256 bucketIndex)
    {
        uint256 bucketSize =
            diffMaxMinRuntime / bondBucketMetadata[issuer].length;
        bucketIndex = (runtime - minRuntime) / bucketSize;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Fund.sol";
import "./Lending.sol";
import "./RoleAware.sol";
import "./PriceAware.sol";

// Goal: all external functions only accessible to margintrader role
// except for view functions of course

struct CrossMarginAccount {
    uint256 lastDepositBlock;
    address[] borrowTokens;
    // borrowed token address => amount
    mapping(address => uint256) borrowed;
    // borrowed token => yield quotient
    mapping(address => uint256) borrowedYieldQuotientsFP;
    address[] holdingTokens;
    // token held in portfolio => amount
    mapping(address => uint256) holdings;
    // boolean value of whether an account holds a token
    mapping(address => bool) holdsToken;
}

abstract contract CrossMarginAccounts is RoleAware, PriceAware {
    /// @dev gets used in calculating how much accounts can borrow
    uint256 public leveragePercent = 300;

    /// @dev percentage of assets held per assets borrowed at which to liquidate
    uint256 public liquidationThresholdPercent = 115;

    /// @dev record of all cross margin accounts
    mapping(address => CrossMarginAccount) internal marginAccounts;
    /// @dev total token caps
    mapping(address => uint256) public tokenCaps;
    /// @dev tracks total of short positions per token
    mapping(address => uint256) public totalShort;
    /// @dev tracks total of long positions per token
    mapping(address => uint256) public totalLong;
    uint256 public coolingOffPeriod = 10;

    /// @dev add an asset to be held by account
    function addHolding(
        CrossMarginAccount storage account,
        address token,
        uint256 depositAmount
    ) internal {
        if (!hasHoldingToken(account, token)) {
            account.holdingTokens.push(token);
            account.holdsToken[token] = true;
        }

        account.holdings[token] += depositAmount;
    }

    /// @dev adjust account to reflect borrowing of token amount
    function borrow(
        CrossMarginAccount storage account,
        address borrowToken,
        uint256 borrowAmount
    ) internal {
        if (!hasBorrowedToken(account, borrowToken)) {
            account.borrowTokens.push(borrowToken);
            account.borrowedYieldQuotientsFP[borrowToken] = Lending(lending())
                .getUpdatedBorrowYieldAccuFP(borrowToken);

            account.borrowed[borrowToken] = borrowAmount;
        } else {
            (uint256 oldBorrowed, uint256 accumulatorFP) =
                Lending(lending()).applyBorrowInterest(
                    account.borrowed[borrowToken],
                    borrowToken,
                    account.borrowedYieldQuotientsFP[borrowToken]
                );
            account.borrowedYieldQuotientsFP[borrowToken] = accumulatorFP;

            account.borrowed[borrowToken] = oldBorrowed + borrowAmount;
        }

        require(positiveBalance(account), "Insufficient balance");
    }

    /// @dev checks whether account is in the black, deposit + earnings relative to borrowed
    function positiveBalance(CrossMarginAccount storage account)
        internal
        returns (bool)
    {
        uint256 loan = loanInPeg(account);
        uint256 holdings = holdingsInPeg(account);
        // The following condition should hold:
        // holdings / loan >= leveragePercent / (leveragePercent - 100)
        // =>
        return holdings * (leveragePercent - 100) >= loan * leveragePercent;
    }

    /// @dev internal function adjusting holding and borrow balances when debt extinguished
    function extinguishDebt(
        CrossMarginAccount storage account,
        address debtToken,
        uint256 extinguishAmount
    ) internal {
        // will throw if insufficient funds
        (uint256 borrowAmount, uint256 newYieldQuot) =
            Lending(lending()).applyBorrowInterest(
                account.borrowed[debtToken],
                debtToken,
                account.borrowedYieldQuotientsFP[debtToken]
            );

        uint256 newBorrowAmount = borrowAmount - extinguishAmount;
        account.borrowed[debtToken] = newBorrowAmount;

        account.holdings[debtToken] =
            account.holdings[debtToken] -
            extinguishAmount;

        if (newBorrowAmount > 0) {
            account.borrowedYieldQuotientsFP[debtToken] = newYieldQuot;
        } else {
            delete account.borrowedYieldQuotientsFP[debtToken];

            bool decrement = false;
            uint256 len = account.borrowTokens.length;
            for (uint256 i; len > i; i++) {
                address currToken = account.borrowTokens[i];
                if (currToken == debtToken) {
                    decrement = true;
                } else if (decrement) {
                    account.borrowTokens[i - 1] = currToken;
                }
            }
            account.borrowTokens.pop();
        }
    }

    /// @dev checks whether an account holds a token
    function hasHoldingToken(CrossMarginAccount storage account, address token)
        internal
        view
        returns (bool)
    {
        return account.holdsToken[token];
    }

    /// @dev checks whether an account has borrowed a token
    function hasBorrowedToken(CrossMarginAccount storage account, address token)
        internal
        view
        returns (bool)
    {
        return account.borrowedYieldQuotientsFP[token] > 0;
    }

    /// @dev calculate total loan in reference currency, including compound interest
    function loanInPeg(CrossMarginAccount storage account)
        internal
        returns (uint256)
    {
        return
            sumTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP
            );
    }

    /// @dev total of assets of account, expressed in reference currency
    function holdingsInPeg(CrossMarginAccount storage account)
        internal
        returns (uint256)
    {
        return sumTokensInPeg(account.holdingTokens, account.holdings);
    }

    /// @dev check whether an account can/should be liquidated
    function belowMaintenanceThreshold(CrossMarginAccount storage account)
        internal
        returns (bool)
    {
        uint256 loan = loanInPeg(account);
        uint256 holdings = holdingsInPeg(account);
        // The following should hold:
        // holdings / loan >= 1.1
        // => holdings >= loan * 1.1
        return 100 * holdings < liquidationThresholdPercent * loan;
    }

    /// @dev go through list of tokens and their amounts, summing up
    function sumTokensInPeg(
        address[] storage tokens,
        mapping(address => uint256) storage amounts
    ) internal returns (uint256 totalPeg) {
        uint256 len = tokens.length;
        for (uint256 tokenId; tokenId < len; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += PriceAware.getCurrentPriceInPeg(token, amounts[token]);
        }
    }

    /// @dev go through list of tokens and their amounts, summing up
    function viewTokensInPeg(
        address[] storage tokens,
        mapping(address => uint256) storage amounts
    ) internal view returns (uint256 totalPeg) {
        uint256 len = tokens.length;
        for (uint256 tokenId; tokenId < len; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += PriceAware.viewCurrentPriceInPeg(token, amounts[token]);
        }
    }

    /// @dev go through list of tokens and ammounts, summing up with interest
    function sumTokensInPegWithYield(
        address[] storage tokens,
        mapping(address => uint256) storage amounts,
        mapping(address => uint256) storage yieldQuotientsFP
    ) internal returns (uint256 totalPeg) {
        uint256 len = tokens.length;
        for (uint256 tokenId; tokenId < len; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += yieldTokenInPeg(
                token,
                amounts[token],
                yieldQuotientsFP
            );
        }
    }

    /// @dev go through list of tokens and ammounts, summing up with interest
    function viewTokensInPegWithYield(
        address[] storage tokens,
        mapping(address => uint256) storage amounts,
        mapping(address => uint256) storage yieldQuotientsFP
    ) internal view returns (uint256 totalPeg) {
        uint256 len = tokens.length;
        for (uint256 tokenId; tokenId < len; tokenId++) {
            address token = tokens[tokenId];
            totalPeg += viewYieldTokenInPeg(
                token,
                amounts[token],
                yieldQuotientsFP
            );
        }
    }

    /// @dev calculate yield for token amount and convert to reference currency
    function yieldTokenInPeg(
        address token,
        uint256 amount,
        mapping(address => uint256) storage yieldQuotientsFP
    ) internal returns (uint256) {
        uint256 yieldFP =
            Lending(lending()).viewAccumulatedBorrowingYieldFP(token);
        // 1 * FP / FP = 1
        uint256 amountInToken = (amount * yieldFP) / yieldQuotientsFP[token];
        return PriceAware.getCurrentPriceInPeg(token, amountInToken);
    }

    /// @dev calculate yield for token amount and convert to reference currency
    function viewYieldTokenInPeg(
        address token,
        uint256 amount,
        mapping(address => uint256) storage yieldQuotientsFP
    ) internal view returns (uint256) {
        uint256 yieldFP =
            Lending(lending()).viewAccumulatedBorrowingYieldFP(token);
        // 1 * FP / FP = 1
        uint256 amountInToken = (amount * yieldFP) / yieldQuotientsFP[token];
        return PriceAware.viewCurrentPriceInPeg(token, amountInToken);
    }

    /// @dev move tokens from one holding to another
    function adjustAmounts(
        CrossMarginAccount storage account,
        address fromToken,
        address toToken,
        uint256 soldAmount,
        uint256 boughtAmount
    ) internal {
        account.holdings[fromToken] = account.holdings[fromToken] - soldAmount;
        addHolding(account, toToken, boughtAmount);
    }

    /// sets borrow and holding to zero
    function deleteAccount(CrossMarginAccount storage account) internal {
        uint256 len = account.borrowTokens.length;
        for (uint256 borrowIdx; len > borrowIdx; borrowIdx++) {
            address borrowToken = account.borrowTokens[borrowIdx];
            totalShort[borrowToken] -= account.borrowed[borrowToken];
            account.borrowed[borrowToken] = 0;
            account.borrowedYieldQuotientsFP[borrowToken] = 0;
        }
        len = account.holdingTokens.length;
        for (uint256 holdingIdx; len > holdingIdx; holdingIdx++) {
            address holdingToken = account.holdingTokens[holdingIdx];
            totalLong[holdingToken] -= account.holdings[holdingToken];
            account.holdings[holdingToken] = 0;
            account.holdsToken[holdingToken] = false;
        }
        delete account.borrowTokens;
        delete account.holdingTokens;
    }

    /// @dev minimum
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        } else {
            return a;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./CrossMarginAccounts.sol";

/** 
@title Handles liquidation of accounts below maintenance threshold
@notice Liquidation can be called by the authorized staker, 
as determined in the Admin contract.
If the authorized staker is delinquent, other participants can jump
in and attack, taking their fees and potentially even their stake,
depending how delinquent the responsible authorized staker is.
*/
abstract contract CrossMarginLiquidation is CrossMarginAccounts {
    event LiquidationShortfall(uint256 amount);
    event AccountLiquidated(address account);

    struct Liquidation {
        uint256 buy;
        uint256 sell;
        uint256 blockNum;
    }

    /// record kept around until a stake attacker can claim their reward
    struct AccountLiqRecord {
        uint256 blockNum;
        address loser;
        uint256 amount;
        address stakeAttacker;
    }

    mapping(address => Liquidation) liquidationAmounts;
    address[] internal sellTokens;
    address[] internal buyTokens;
    address[] internal tradersToLiquidate;

    mapping(address => uint256) public maintenanceFailures;
    mapping(address => AccountLiqRecord) public stakeAttackRecords;
    uint256 public avgLiquidationPerCall = 10;

    uint256 public liqStakeAttackWindow = 5;
    uint256 public MAINTAINER_CUT_PERCENT = 5;

    uint256 public failureThreshold = 10;

    /// Set failure threshold
    function setFailureThreshold(uint256 threshFactor) external onlyOwnerExec {
        failureThreshold = threshFactor;
    }

    /// Set liquidity stake attack window
    function setLiqStakeAttackWindow(uint256 window) external onlyOwnerExec {
        liqStakeAttackWindow = window;
    }

    /// Set maintainer's percent cut
    function setMaintainerCutPercent(uint256 cut) external onlyOwnerExec {
        MAINTAINER_CUT_PERCENT = cut;
    }

    /// @dev calcLiquidationAmounts does a number of tasks in this contract
    /// and some of them are not straightforward.
    /// First of all it aggregates liquidation amounts,
    /// as well as which traders are ripe for liquidation, in storage (not in memory)
    /// owing to the fact that arrays can't be pushed to and hash maps don't
    /// exist in memory.
    /// Then it also returns any stake attack funds if the stake was unsuccessful
    /// (i.e. current caller is authorized). Also see context below.
    function calcLiquidationAmounts(
        address[] memory liquidationCandidates,
        bool isAuthorized
    ) internal returns (uint256 attackReturns) {
        sellTokens = new address[](0);
        buyTokens = new address[](0);
        tradersToLiquidate = new address[](0);

        for (
            uint256 traderIndex = 0;
            liquidationCandidates.length > traderIndex;
            traderIndex++
        ) {
            address traderAddress = liquidationCandidates[traderIndex];
            CrossMarginAccount storage account = marginAccounts[traderAddress];
            if (belowMaintenanceThreshold(account)) {
                tradersToLiquidate.push(traderAddress);
                uint256 len = account.holdingTokens.length;
                for (uint256 sellIdx = 0; len > sellIdx; sellIdx++) {
                    address token = account.holdingTokens[sellIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = account.holdings[token];
                        liquidation.buy = 0;
                        liquidation.blockNum = block.number;
                        sellTokens.push(token);
                    } else {
                        liquidation.sell += account.holdings[token];
                    }
                }

                len = account.borrowTokens.length;
                for (uint256 buyIdx = 0; len > buyIdx; buyIdx++) {
                    address token = account.borrowTokens[buyIdx];
                    Liquidation storage liquidation = liquidationAmounts[token];

                    (uint256 loanAmount, ) =
                        Lending(lending()).applyBorrowInterest(
                            account.borrowed[token],
                            token,
                            account.borrowedYieldQuotientsFP[token]
                        );

                    Lending(lending()).payOff(token, loanAmount);

                    if (liquidation.blockNum != block.number) {
                        liquidation.sell = 0;
                        liquidation.buy = loanAmount;
                        liquidation.blockNum = block.number;
                        buyTokens.push(token);
                    } else {
                        liquidation.buy += loanAmount;
                    }
                }
            }

            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[traderAddress];
            if (isAuthorized) {
                attackReturns += _disburseLiqAttack(liqAttackRecord);
            }
        }
    }

    function _disburseLiqAttack(AccountLiqRecord storage liqAttackRecord)
        internal
        returns (uint256 returnAmount)
    {
        if (liqAttackRecord.amount > 0) {
            // validate attack records, if any
            uint256 blockDiff =
                min(
                    block.number - liqAttackRecord.blockNum,
                    liqStakeAttackWindow
                );

            uint256 attackerCut =
                (liqAttackRecord.amount * blockDiff) / liqStakeAttackWindow;

            Fund(fund()).withdraw(
                PriceAware.peg,
                liqAttackRecord.stakeAttacker,
                attackerCut
            );

            Admin a = Admin(admin());
            uint256 penalty =
                (a.maintenanceStakePerBlock() * attackerCut) /
                    avgLiquidationPerCall;
            a.penalizeMaintenanceStake(
                liqAttackRecord.loser,
                penalty,
                liqAttackRecord.stakeAttacker
            );

            // return remainder, after cut was taken to authorized stakekr
            returnAmount = liqAttackRecord.amount - attackerCut;
        }
    }

    /// Disburse liquidity stake attacks
    function disburseLiqStakeAttacks(address[] memory liquidatedAccounts)
        external
    {
        for (uint256 i = 0; liquidatedAccounts.length > i; i++) {
            address liqAccount = liquidatedAccounts[i];
            AccountLiqRecord storage liqAttackRecord =
                stakeAttackRecords[liqAccount];
            if (
                block.number > liqAttackRecord.blockNum + liqStakeAttackWindow
            ) {
                _disburseLiqAttack(liqAttackRecord);
                delete stakeAttackRecords[liqAccount];
            }
        }
    }

    function liquidateFromPeg() internal returns (uint256 pegAmount) {
        uint256 len = buyTokens.length;
        for (uint256 tokenIdx = 0; len > tokenIdx; tokenIdx++) {
            address buyToken = buyTokens[tokenIdx];
            Liquidation storage liq = liquidationAmounts[buyToken];
            if (liq.buy > liq.sell) {
                pegAmount += PriceAware.liquidateFromPeg(
                    buyToken,
                    liq.buy - liq.sell
                );
                delete liquidationAmounts[buyToken];
            }
        }
        delete buyTokens;
    }

    function liquidateToPeg() internal returns (uint256 pegAmount) {
        uint256 len = sellTokens.length;
        for (uint256 tokenIndex = 0; len > tokenIndex; tokenIndex++) {
            address token = sellTokens[tokenIndex];
            Liquidation storage liq = liquidationAmounts[token];
            if (liq.sell > liq.buy) {
                uint256 sellAmount = liq.sell - liq.buy;
                pegAmount += PriceAware.liquidateToPeg(token, sellAmount);
                delete liquidationAmounts[token];
            }
        }
        delete sellTokens;
    }

    function maintainerIsFailing() internal view returns (bool) {
        (address currentMaintainer, ) =
            Admin(admin()).viewCurrentMaintenanceStaker();
        return
            maintenanceFailures[currentMaintainer] >
            failureThreshold * avgLiquidationPerCall;
    }

    /// called by maintenance stakers to liquidate accounts below liquidation threshold
    function liquidate(address[] memory liquidationCandidates)
        external
        noIntermediary
        returns (uint256 maintainerCut)
    {
        bool isAuthorized = Admin(admin()).isAuthorizedStaker(msg.sender);
        bool canTakeNow = isAuthorized || maintainerIsFailing();

        // calcLiquidationAmounts does a lot of the work here
        // * aggregates both sell and buy side targets to be liquidated
        // * returns attacker cuts to them
        // * aggregates any returned fees from unauthorized (attacking) attempts
        maintainerCut = calcLiquidationAmounts(
            liquidationCandidates,
            isAuthorized
        );

        uint256 sale2pegAmount = liquidateToPeg();
        uint256 peg2targetCost = liquidateFromPeg();

        // this may be a bit imprecise, since individual shortfalls may be obscured
        // by overall returns and the maintainer cut is taken out of the net total,
        // but it gives us the general picture
        uint256 costWithCut =
            (peg2targetCost * (100 + MAINTAINER_CUT_PERCENT)) / 100;
        if (costWithCut > sale2pegAmount) {
            emit LiquidationShortfall(costWithCut - sale2pegAmount);
        }

        address loser = address(0);
        if (!canTakeNow) {
            // whoever is the current responsible maintenance staker
            // and liable to lose their stake
            loser = Admin(admin()).getUpdatedCurrentStaker();
        }

        // iterate over traders and send back their money
        // as well as giving attackers their due, in case caller isn't authorized
        for (
            uint256 traderIdx = 0;
            tradersToLiquidate.length > traderIdx;
            traderIdx++
        ) {
            address traderAddress = tradersToLiquidate[traderIdx];
            CrossMarginAccount storage account = marginAccounts[traderAddress];

            uint256 holdingsValue = holdingsInPeg(account);
            uint256 borrowValue = loanInPeg(account);
            // 5% of value borrowed
            uint256 maintainerCut4Account =
                (borrowValue * MAINTAINER_CUT_PERCENT) / 100;
            maintainerCut += maintainerCut4Account;

            if (!canTakeNow) {
                // This could theoretically lead to a previous attackers
                // record being overwritten, but only if the trader restarts
                // their account and goes back into the red within the short time window
                // which would be a costly attack requiring collusion without upside
                AccountLiqRecord storage liqAttackRecord =
                    stakeAttackRecords[traderAddress];
                liqAttackRecord.amount = maintainerCut4Account;
                liqAttackRecord.stakeAttacker = msg.sender;
                liqAttackRecord.blockNum = block.number;
                liqAttackRecord.loser = loser;
            }

            // send back trader money
            if (holdingsValue > maintainerCut4Account + borrowValue) {
                // send remaining funds back to trader
                Fund(fund()).withdraw(
                    PriceAware.peg,
                    traderAddress,
                    holdingsValue - borrowValue - maintainerCut4Account
                );
            }

            emit AccountLiquidated(traderAddress);
            deleteAccount(account);
        }

        avgLiquidationPerCall =
            (avgLiquidationPerCall * 99 + maintainerCut) /
            100;

        if (canTakeNow) {
            Fund(fund()).withdraw(PriceAware.peg, msg.sender, maintainerCut);
        }

        address currentMaintainer = Admin(admin()).getUpdatedCurrentStaker();
        if (isAuthorized) {
            if (maintenanceFailures[currentMaintainer] > maintainerCut) {
                maintenanceFailures[currentMaintainer] -= maintainerCut;
            } else {
                maintenanceFailures[currentMaintainer] = 0;
            }
        } else {
            maintenanceFailures[currentMaintainer] += maintainerCut;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Fund.sol";
import "./Lending.sol";
import "./RoleAware.sol";
import "./CrossMarginLiquidation.sol";

// Goal: all external functions only accessible to margintrader role
// except for view functions of course

contract CrossMarginTrading is CrossMarginLiquidation, IMarginTrading {
    constructor(address _peg, address _roles)
        RoleAware(_roles)
        PriceAware(_peg)
    {}

    /// @dev admin function to set the token cap
    function setTokenCap(address token, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        tokenCaps[token] = cap;
    }

    /// @dev setter for cooling off period for withdrawing funds after deposit
    function setCoolingOffPeriod(uint256 blocks) external onlyOwnerExec {
        coolingOffPeriod = blocks;
    }

    /// @dev admin function to set leverage
    function setLeveragePercent(uint256 _leveragePercent)
        external
        onlyOwnerExec
    {
        leveragePercent = _leveragePercent;
    }

    /// @dev admin function to set liquidation threshold
    function setLiquidationThresholdPercent(uint256 threshold)
        external
        onlyOwnerExec
    {
        liquidationThresholdPercent = threshold;
    }

    /// @dev gets called by router to affirm a deposit to an account
    function registerDeposit(
        address trader,
        address token,
        uint256 depositAmount
    ) external override returns (uint256 extinguishableDebt) {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");

        CrossMarginAccount storage account = marginAccounts[trader];
        account.lastDepositBlock = block.number;

        if (account.borrowed[token] > 0) {
            extinguishableDebt = min(depositAmount, account.borrowed[token]);
            extinguishDebt(account, token, extinguishableDebt);
            totalShort[token] -= extinguishableDebt;
        }

        // no overflow because depositAmount >= extinguishableDebt
        uint256 addedHolding = depositAmount - extinguishableDebt;
        _registerDeposit(account, token, addedHolding);
    }

    function _registerDeposit(
        CrossMarginAccount storage account,
        address token,
        uint256 addedHolding
    ) internal {
        addHolding(account, token, addedHolding);

        totalLong[token] += addedHolding;
        require(
            tokenCaps[token] >= totalLong[token],
            "Exceeds global token cap"
        );
    }

    /// @dev gets called by router to affirm borrowing event
    function registerBorrow(
        address trader,
        address borrowToken,
        uint256 borrowAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        addHolding(account, borrowToken, borrowAmount);
        _registerBorrow(account, borrowToken, borrowAmount);
    }

    function _registerBorrow(
        CrossMarginAccount storage account,
        address borrowToken,
        uint256 borrowAmount
    ) internal {
        totalShort[borrowToken] += borrowAmount;
        totalLong[borrowToken] += borrowAmount;
        require(
            tokenCaps[borrowToken] >= totalShort[borrowToken] &&
                tokenCaps[borrowToken] >= totalLong[borrowToken],
            "Exceeds global token cap"
        );

        borrow(account, borrowToken, borrowAmount);
    }

    /// @dev gets called by router to affirm withdrawal of tokens from account
    function registerWithdrawal(
        address trader,
        address withdrawToken,
        uint256 withdrawAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        _registerWithdrawal(account, withdrawToken, withdrawAmount);
    }

    function _registerWithdrawal(
        CrossMarginAccount storage account,
        address withdrawToken,
        uint256 withdrawAmount
    ) internal {
        require(
            block.number > account.lastDepositBlock + coolingOffPeriod,
            "No withdrawal soon after deposit"
        );

        totalLong[withdrawToken] -= withdrawAmount;
        // throws on underflow
        account.holdings[withdrawToken] =
            account.holdings[withdrawToken] -
            withdrawAmount;
        require(positiveBalance(account), "Insufficient balance");
    }

    /// @dev overcollateralized borrowing on a cross margin account, called by router
    function registerOvercollateralizedBorrow(
        address trader,
        address depositToken,
        uint256 depositAmount,
        address borrowToken,
        uint256 withdrawAmount
    ) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");

        CrossMarginAccount storage account = marginAccounts[trader];

        _registerDeposit(account, depositToken, depositAmount);
        _registerBorrow(account, borrowToken, withdrawAmount);
        _registerWithdrawal(account, borrowToken, withdrawAmount);

        account.lastDepositBlock = block.number;
    }

    /// @dev gets called by router to register a trade and borrow and extinguish as necessary
    function registerTradeAndBorrow(
        address trader,
        address tokenFrom,
        address tokenTo,
        uint256 inAmount,
        uint256 outAmount
    )
        external
        override
        returns (uint256 extinguishableDebt, uint256 borrowAmount)
    {
        require(isMarginTrader(msg.sender), "Calling contr. not an authorized");

        CrossMarginAccount storage account = marginAccounts[trader];

        if (account.borrowed[tokenTo] > 0) {
            extinguishableDebt = min(outAmount, account.borrowed[tokenTo]);
            extinguishDebt(account, tokenTo, extinguishableDebt);
            totalShort[tokenTo] -= extinguishableDebt;
        }

        uint256 sellAmount = inAmount;
        uint256 fromHoldings = account.holdings[tokenFrom];
        if (inAmount > fromHoldings) {
            sellAmount = fromHoldings;
            /// won't overflow
            borrowAmount = inAmount - sellAmount;
        }

        if (inAmount > borrowAmount) {
            totalLong[tokenFrom] -= inAmount - borrowAmount;
        }
        if (outAmount > extinguishableDebt) {
            totalLong[tokenTo] += outAmount - extinguishableDebt;
        }
        require(
            tokenCaps[tokenTo] >= totalLong[tokenTo],
            "Exceeds global token cap"
        );

        adjustAmounts(
            account,
            tokenFrom,
            tokenTo,
            sellAmount,
            outAmount - extinguishableDebt
        );

        if (borrowAmount > 0) {
            totalShort[tokenFrom] += borrowAmount;
            require(
                tokenCaps[tokenFrom] >= totalShort[tokenFrom],
                "Exceeds global token cap"
            );
            borrow(account, tokenFrom, borrowAmount);
        }
    }

    /// @dev can get called by router to register the dissolution of an account
    function registerLiquidation(address trader) external override {
        require(isMarginTrader(msg.sender), "Calling contr. not authorized");
        CrossMarginAccount storage account = marginAccounts[trader];
        require(loanInPeg(account) == 0, "Can't liquidate: borrowing");

        deleteAccount(account);
    }

    /// @dev currently holding in this token
    function viewBalanceInToken(address trader, address token)
        external
        view
        returns (uint256)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        return account.holdings[token];
    }

    /// @dev view function to display account held assets state
    function getHoldingAmounts(address trader)
        external
        view
        override
        returns (
            address[] memory holdingTokens,
            uint256[] memory holdingAmounts
        )
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        holdingTokens = account.holdingTokens;

        holdingAmounts = new uint256[](account.holdingTokens.length);
        for (uint256 idx = 0; holdingTokens.length > idx; idx++) {
            address tokenAddress = holdingTokens[idx];
            holdingAmounts[idx] = account.holdings[tokenAddress];
        }
    }

    /// @dev view function to display account borrowing state
    function getBorrowAmounts(address trader)
        external
        view
        override
        returns (address[] memory borrowTokens, uint256[] memory borrowAmounts)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        borrowTokens = account.borrowTokens;

        borrowAmounts = new uint256[](account.borrowTokens.length);
        for (uint256 idx = 0; borrowTokens.length > idx; idx++) {
            address tokenAddress = borrowTokens[idx];
            borrowAmounts[idx] = Lending(lending()).viewWithBorrowInterest(
                account.borrowed[tokenAddress],
                tokenAddress,
                account.borrowedYieldQuotientsFP[tokenAddress]
            );
        }
    }

    /// @dev view function to get loan amount in peg
    function viewLoanInPeg(address trader)
        external
        view
        returns (uint256 amount)
    {
        CrossMarginAccount storage account = marginAccounts[trader];
        return
            viewTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP
            );
    }

    /// @dev total of assets of account, expressed in reference currency
    function viewHoldingsInPeg(address trader) external view returns (uint256) {
        CrossMarginAccount storage account = marginAccounts[trader];
        return viewTokensInPeg(account.holdingTokens, account.holdings);
    }

    /// @dev can this trader be liquidated?
    function canBeLiquidated(address trader) external view returns (bool) {
        CrossMarginAccount storage account = marginAccounts[trader];
        uint256 loan =
            viewTokensInPegWithYield(
                account.borrowTokens,
                account.borrowed,
                account.borrowedYieldQuotientsFP
            );

        uint256 holdings =
            viewTokensInPeg(account.holdingTokens, account.holdings);

        return 100 * holdings >= liquidationThresholdPercent * loan;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IWETH.sol";
import "./RoleAware.sol";

/// @title Manage funding
contract Fund is RoleAware {
    using SafeERC20 for IERC20;
    /// wrapped ether
    address public immutable WETH;

    constructor(address _WETH, address _roles) RoleAware(_roles) {
        WETH = _WETH;
    }

    /// Deposit an active token
    function deposit(address depositToken, uint256 depositAmount) external {
        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
    }

    /// Deposit token on behalf of `sender`
    function depositFor(
        address sender,
        address depositToken,
        uint256 depositAmount
    ) external {
        require(isFundTransferer(msg.sender), "Unauthorized deposit");
        IERC20(depositToken).safeTransferFrom(
            sender,
            address(this),
            depositAmount
        );
    }

    /// Deposit to wrapped ether
    function depositToWETH() external payable {
        IWETH(WETH).deposit{value: msg.value}();
    }

    // withdrawers role
    function withdraw(
        address withdrawalToken,
        address recipient,
        uint256 withdrawalAmount
    ) external {
        require(isFundTransferer(msg.sender), "Unauthorized withdraw");
        IERC20(withdrawalToken).safeTransfer(recipient, withdrawalAmount);
    }

    // withdrawers role
    function withdrawETH(address recipient, uint256 withdrawalAmount) external {
        require(isFundTransferer(msg.sender), "Unauthorized withdraw");
        IWETH(WETH).withdraw(withdrawalAmount);
        Address.sendValue(payable(recipient), withdrawalAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./BaseLending.sol";

struct HourlyBond {
    uint256 amount;
    uint256 yieldQuotientFP;
    uint256 moduloHour;
}

/// @title Here we offer subscriptions to auto-renewing hourly bonds
/// Funds are locked in for an 50 minutes per hour, while interest rates float
abstract contract HourlyBondSubscriptionLending is BaseLending {
    struct HourlyBondMetadata {
        YieldAccumulator yieldAccumulator;
        uint256 buyingSpeed;
        uint256 withdrawingSpeed;
        uint256 lastBought;
        uint256 lastWithdrawn;
    }

    mapping(address => HourlyBondMetadata) hourlyBondMetadata;

    uint256 public withdrawalWindow = 15 minutes;
    // issuer => holder => bond record
    mapping(address => mapping(address => HourlyBond))
        public hourlyBondAccounts;

    uint256 public borrowingFactorPercent = 200;

    function _makeHourlyBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        updateHourlyBondAmount(issuer, bond);

        HourlyBondMetadata storage bondMeta = hourlyBondMetadata[issuer];
        bond.yieldQuotientFP = bondMeta.yieldAccumulator.accumulatorFP;
        bond.moduloHour = block.timestamp % (1 hours);
        bond.amount += amount;
        lendingMeta[issuer].totalLending += amount;

        (bondMeta.buyingSpeed, bondMeta.lastBought) = updateSpeed(
            bondMeta.buyingSpeed,
            bondMeta.lastBought,
            amount,
            1 hours
        );
    }

    function updateHourlyBondAmount(address issuer, HourlyBond storage bond)
        internal
    {
        uint256 yieldQuotientFP = bond.yieldQuotientFP;
        if (yieldQuotientFP > 0) {
            YieldAccumulator storage yA =
                getUpdatedHourlyYield(issuer, hourlyBondMetadata[issuer]);

            uint256 oldAmount = bond.amount;

            bond.amount = applyInterest(
                bond.amount,
                yA.accumulatorFP,
                yieldQuotientFP
            );

            uint256 deltaAmount = bond.amount - oldAmount;
            lendingMeta[issuer].totalLending += deltaAmount;
        }
    }

    // Retrieves bond balance for issuer and holder
    function viewHourlyBondAmount(address issuer, address holder)
        public
        view
        returns (uint256)
    {
        HourlyBond storage bond = hourlyBondAccounts[issuer][holder];
        uint256 yieldQuotientFP = bond.yieldQuotientFP;

        uint256 cumulativeYield =
            viewCumulativeYieldFP(
                hourlyBondMetadata[issuer].yieldAccumulator,
                block.timestamp
            );

        if (yieldQuotientFP > 0) {
            return applyInterest(bond.amount, cumulativeYield, yieldQuotientFP);
        } else {
            return bond.amount;
        }
    }

    function _withdrawHourlyBond(
        address issuer,
        HourlyBond storage bond,
        uint256 amount
    ) internal {
        // how far the current hour has advanced (relative to acccount hourly clock)
        uint256 currentOffset = (block.timestamp - bond.moduloHour) % (1 hours);

        require(
            withdrawalWindow >= currentOffset,
            "Tried withdrawing outside subscription cancellation time window"
        );

        bond.amount -= amount;
        lendingMeta[issuer].totalLending -= amount;

        HourlyBondMetadata storage bondMeta = hourlyBondMetadata[issuer];
        (bondMeta.withdrawingSpeed, bondMeta.lastWithdrawn) = updateSpeed(
            bondMeta.withdrawingSpeed,
            bondMeta.lastWithdrawn,
            bond.amount,
            1 hours
        );
    }

    function calcCumulativeYieldFP(
        YieldAccumulator storage yieldAccumulator,
        uint256 timeDelta
    ) internal view returns (uint256 accumulatorFP) {
        uint256 secondsDelta = timeDelta % (1 hours);
        // linearly interpolate interest for seconds
        // FP * FP * 1 / (FP * 1) = FP
        accumulatorFP =
            yieldAccumulator.accumulatorFP +
            (yieldAccumulator.accumulatorFP *
                (yieldAccumulator.hourlyYieldFP - FP32) *
                secondsDelta) /
            (FP32 * 1 hours);

        uint256 hoursDelta = timeDelta / (1 hours);
        if (hoursDelta > 0) {
            // This loop should hardly ever 1 or more unless something bad happened
            // In which case it costs gas but there isn't overflow
            for (uint256 i = 0; hoursDelta > i; i++) {
                // FP32 * FP32 / FP32 = FP32
                accumulatorFP =
                    (accumulatorFP * yieldAccumulator.hourlyYieldFP) /
                    FP32;
            }
        }
    }

    /// @dev updates yield accumulators for both borrowing and lending
    function getUpdatedHourlyYield(
        address issuer,
        HourlyBondMetadata storage bondMeta
    ) internal returns (YieldAccumulator storage accumulator) {
        accumulator = bondMeta.yieldAccumulator;
        uint256 lastUpdated = accumulator.lastUpdated;
        uint256 timeDelta = (block.timestamp - lastUpdated);

        YieldAccumulator storage borrowAccumulator =
            borrowYieldAccumulators[issuer];

        if (timeDelta > (5 minutes)) {
            accumulator.accumulatorFP = calcCumulativeYieldFP(
                accumulator,
                timeDelta
            );

            LendingMetadata storage meta = lendingMeta[issuer];

            uint256 yieldGeneratedFP =
                (borrowAccumulator.hourlyYieldFP * meta.totalBorrowed) /
                    (1 + meta.totalLending);
            uint256 _maxHourlyYieldFP = min(maxHourlyYieldFP, yieldGeneratedFP);

            accumulator.hourlyYieldFP = updatedYieldFP(
                accumulator.hourlyYieldFP,
                lastUpdated,
                meta.totalLending,
                lendingTarget(meta),
                bondMeta.buyingSpeed,
                bondMeta.withdrawingSpeed,
                _maxHourlyYieldFP
            );
            accumulator.lastUpdated = block.timestamp;
        }

        updateBorrowYieldAccu(borrowAccumulator);

        borrowAccumulator.hourlyYieldFP =
            1 +
            (borrowingFactorPercent * accumulator.hourlyYieldFP) /
            100;
    }

    function updateBorrowYieldAccu(YieldAccumulator storage borrowAccumulator)
        internal
    {
        uint256 timeDelta = block.timestamp - borrowAccumulator.lastUpdated;

        if (timeDelta > (5 minutes)) {
            borrowAccumulator.accumulatorFP = calcCumulativeYieldFP(
                borrowAccumulator,
                timeDelta
            );

            borrowAccumulator.lastUpdated = block.timestamp;
        }
    }

    function getUpdatedBorrowYieldAccuFP(address issuer)
        external
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        return yA.accumulatorFP;
    }

    function viewCumulativeYieldFP(
        YieldAccumulator storage yA,
        uint256 timestamp
    ) internal view returns (uint256) {
        uint256 timeDelta = (timestamp - yA.lastUpdated);
        if (timeDelta > 5 minutes) {
            return calcCumulativeYieldFP(yA, timeDelta);
        } else {
            return yA.accumulatorFP;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./Fund.sol";

struct Claim {
    uint256 startingRewardRateFP;
    uint256 amount;
    uint256 intraDayGain;
    uint256 intraDayLoss;
}

/// @title Manage distribution of liquidity stake incentives
/// Some efforts have been made to reduce gas cost at claim time
/// and shift gas burden onto those who would want to withdraw
contract IncentiveDistribution is RoleAware {
    // fixed point number factor
    uint256 internal constant FP32 = 2**32;
    // the amount of contraction per thousand, per day
    // of the overal daily incentive distribution
    // https://en.wikipedia.org/wiki/Per_mil
    uint256 public constant contractionPerMil = 999;
    address public immutable MFI;

    constructor(
        address _MFI,
        uint256 startingDailyDistributionWithoutDecimals,
        address _roles
    ) RoleAware(_roles) {
        MFI = _MFI;
        currentDailyDistribution =
            startingDailyDistributionWithoutDecimals *
            (1 ether);

        lastUpdatedDay = block.timestamp % (1 days);
    }

    // how much is going to be distributed, contracts every day
    uint256 public currentDailyDistribution;

    uint256 public trancheShareTotal;
    uint256[] public allTranches;

    struct TrancheMeta {
        // portion of daily distribution per each tranche
        uint256 rewardShare;
        uint256 currentDayGains;
        uint256 currentDayLosses;
        uint256 tomorrowOngoingTotals;
        uint256 yesterdayOngoingTotals;
        // aggregate all the unclaimed intra-days
        uint256 intraDayGains;
        uint256 intraDayLosses;
        uint256 intraDayRewardGains;
        uint256 intraDayRewardLosses;
        // how much each claim unit would get if they had staked from the dawn of time
        // expressed as fixed point number
        // claim amounts are expressed relative to this ongoing aggregate
        uint256 aggregateDailyRewardRateFP;
        uint256 yesterdayRewardRateFP;
        mapping(address => Claim) claims;
    }

    mapping(uint256 => TrancheMeta) public trancheMetadata;

    // last updated day
    uint256 public lastUpdatedDay;

    mapping(address => uint256) public accruedReward;

    /// Set share of tranche
    function setTrancheShare(uint256 tranche, uint256 share)
        external
        onlyOwnerExecActivator
    {
        require(
            trancheMetadata[tranche].rewardShare > 0,
            "Tranche not initialized"
        );
        _setTrancheShare(tranche, share);
    }

    function _setTrancheShare(uint256 tranche, uint256 share) internal {
        TrancheMeta storage tm = trancheMetadata[tranche];

        if (share > tm.rewardShare) {
            trancheShareTotal += share - tm.rewardShare;
        } else {
            trancheShareTotal -= tm.rewardShare - share;
        }
        tm.rewardShare = share;
    }

    /// Initialize tranche
    function initTranche(uint256 tranche, uint256 share)
        external
        onlyOwnerExecActivator
    {
        TrancheMeta storage tm = trancheMetadata[tranche];
        require(tm.rewardShare == 0, "Tranche already initialized");
        _setTrancheShare(tranche, share);

        // simply initialize to 1.0
        tm.aggregateDailyRewardRateFP = FP32;
        allTranches.push(tranche);
    }

    /// Start / increase amount of claim
    function addToClaimAmount(
        uint256 tranche,
        address recipient,
        uint256 claimAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        if (currentDailyDistribution > 0) {
            TrancheMeta storage tm = trancheMetadata[tranche];
            Claim storage claim = tm.claims[recipient];

            uint256 currentDay =
                claimAmount * (1 days - (block.timestamp % (1 days)));

            tm.currentDayGains += currentDay;
            claim.intraDayGain += currentDay * currentDailyDistribution;

            tm.tomorrowOngoingTotals += claimAmount * 1 days;
            updateAccruedReward(tm, recipient, claim);

            claim.amount += claimAmount * (1 days);
        }
    }

    /// Decrease amount of claim
    function subtractFromClaimAmount(
        uint256 tranche,
        address recipient,
        uint256 subtractAmount
    ) external {
        require(
            isIncentiveReporter(msg.sender),
            "Contract not authorized to report incentives"
        );
        uint256 currentDay = subtractAmount * (block.timestamp % (1 days));

        TrancheMeta storage tm = trancheMetadata[tranche];
        Claim storage claim = tm.claims[recipient];

        tm.currentDayLosses += currentDay;
        claim.intraDayLoss += currentDay * currentDailyDistribution;

        tm.tomorrowOngoingTotals -= subtractAmount * 1 days;

        updateAccruedReward(tm, recipient, claim);
        claim.amount -= subtractAmount * (1 days);
    }

    function updateAccruedReward(
        TrancheMeta storage tm,
        address recipient,
        Claim storage claim
    ) internal returns (uint256 rewardDelta) {
        if (claim.startingRewardRateFP > 0) {
            rewardDelta = calcRewardAmount(tm, claim);
            accruedReward[recipient] += rewardDelta;
        }
        // don't reward for current day (approximately)
        claim.startingRewardRateFP =
            tm.yesterdayRewardRateFP +
            tm.aggregateDailyRewardRateFP;
    }

    /// @dev additional reward accrued since last update
    function calcRewardAmount(TrancheMeta storage tm, Claim storage claim)
        internal
        view
        returns (uint256 rewardAmount)
    {
        uint256 ours = claim.startingRewardRateFP;
        uint256 aggregate = tm.aggregateDailyRewardRateFP;
        if (aggregate > ours) {
            rewardAmount = (claim.amount * (aggregate - ours)) / FP32;
        }
    }

    function applyIntraDay(TrancheMeta storage tm, Claim storage claim)
        internal
        view
        returns (uint256 gainImpact, uint256 lossImpact)
    {
        uint256 gain = claim.intraDayGain;
        uint256 loss = claim.intraDayLoss;

        if (gain + loss > 0) {
            gainImpact =
                (gain * tm.intraDayRewardGains) /
                (tm.intraDayGains + 1);
            lossImpact =
                (loss * tm.intraDayRewardLosses) /
                (tm.intraDayLosses + 1);
        }
    }

    /// Get a view of reward amount
    function viewRewardAmount(uint256 tranche, address claimant)
        external
        view
        returns (uint256)
    {
        TrancheMeta storage tm = trancheMetadata[tranche];
        Claim storage claim = tm.claims[claimant];

        uint256 rewardAmount =
            accruedReward[claimant] + calcRewardAmount(tm, claim);
        (uint256 gainImpact, uint256 lossImpact) = applyIntraDay(tm, claim);

        return rewardAmount + gainImpact - lossImpact;
    }

    /// Withdraw current reward amount
    function withdrawReward(uint256[] calldata tranches)
        external
        returns (uint256 withdrawAmount)
    {
        updateDayTotals();

        withdrawAmount = accruedReward[msg.sender];
        for (uint256 i; tranches.length > i; i++) {
            uint256 tranche = tranches[i];

            TrancheMeta storage tm = trancheMetadata[tranche];
            Claim storage claim = tm.claims[msg.sender];

            withdrawAmount += updateAccruedReward(tm, msg.sender, claim);

            (uint256 gainImpact, uint256 lossImpact) = applyIntraDay(tm, claim);

            withdrawAmount = withdrawAmount + gainImpact - lossImpact;

            tm.intraDayGains -= claim.intraDayGain;
            tm.intraDayLosses -= claim.intraDayLoss;
            tm.intraDayRewardGains -= gainImpact;
            tm.intraDayRewardLosses -= lossImpact;

            claim.intraDayGain = 0;
        }

        accruedReward[msg.sender] = 0;

        Fund(fund()).withdraw(MFI, msg.sender, withdrawAmount);
    }

    function updateDayTotals() internal {
        uint256 nowDay = block.timestamp / (1 days);
        uint256 dayDiff = nowDay - lastUpdatedDay;

        // shrink the daily distribution for every day that has passed
        for (uint256 i = 0; i < dayDiff; i++) {
            _updateTrancheTotals();

            currentDailyDistribution =
                (currentDailyDistribution * contractionPerMil) /
                1000;

            lastUpdatedDay += 1;
        }
    }

    function _updateTrancheTotals() internal {
        for (uint256 i; allTranches.length > i; i++) {
            uint256 tranche = allTranches[i];
            TrancheMeta storage tm = trancheMetadata[tranche];

            uint256 todayTotal =
                tm.yesterdayOngoingTotals +
                    tm.currentDayGains -
                    tm.currentDayLosses;

            uint256 todayRewardRateFP =
                (FP32 * (currentDailyDistribution * tm.rewardShare)) /
                    trancheShareTotal /
                    todayTotal;

            tm.yesterdayRewardRateFP = todayRewardRateFP;

            tm.aggregateDailyRewardRateFP += todayRewardRateFP;

            tm.intraDayGains += tm.currentDayGains * currentDailyDistribution;

            tm.intraDayLosses += tm.currentDayLosses * currentDailyDistribution;

            tm.intraDayRewardGains +=
                (tm.currentDayGains * todayRewardRateFP) /
                FP32;

            tm.intraDayRewardLosses +=
                (tm.currentDayLosses * todayRewardRateFP) /
                FP32;

            tm.yesterdayOngoingTotals = tm.tomorrowOngoingTotals;
            tm.currentDayGains = 0;
            tm.currentDayLosses = 0;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IncentiveDistribution.sol";
import "./RoleAware.sol";

/// @title helper class to facilitate staking and unstaking
/// within the incentive system.
abstract contract IncentivizedHolder is RoleAware {
    /// @dev here we cache incentive tranches to save on a bit of gas
    mapping(address => uint256) public incentiveTranches;

    /// Set incentive tranche
    function setIncentiveTranche(address token, uint8 tranche)
        external
        onlyOwnerExecActivator
    {
        incentiveTranches[token] = tranche;
    }

    function stakeClaim(
        address claimant,
        address token,
        uint256 amount
    ) internal {
        IncentiveDistribution iD =
            IncentiveDistribution(incentiveDistributor());

        uint256 tranche = incentiveTranches[token];

        iD.addToClaimAmount(tranche, claimant, amount);
    }

    function withdrawClaim(
        address claimant,
        address token,
        uint256 amount
    ) internal {
        uint256 tranche = incentiveTranches[token];

        IncentiveDistribution(incentiveDistributor()).subtractFromClaimAmount(
            tranche,
            claimant,
            amount
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Fund.sol";
import "./HourlyBondSubscriptionLending.sol";
import "./BondLending.sol";
import "./IncentivizedHolder.sol";

// TODO activate bonds for lending

/// @title Manage lending for a variety of bond issuers
contract Lending is
    RoleAware,
    HourlyBondSubscriptionLending,
    BondLending,
    IncentivizedHolder
{
    /// @dev IDs for all bonds held by an address
    mapping(address => uint256[]) public bondIds;

    /// mapping issuers to tokens
    /// (in crossmargin, the issuers are tokens  themselves)
    mapping(address => address) public issuerTokens;

    /// In case of shortfall, adjust debt
    mapping(address => uint256) public haircuts;

    /// map of available issuers
    mapping(address => bool) public activeIssuers;

    constructor(address _roles) RoleAware(_roles) {
        uint256 APR = 899;
        maxHourlyYieldFP = (FP32 * APR) / 100 / (24 * 365);

        uint256 aprChangePerMil = 3;
        yieldChangePerSecondFP = (FP32 * aprChangePerMil) / 1000;
    }

    /// Make a issuer available for protocol
    function activateIssuer(address issuer) external {
        activateIssuer(issuer, issuer);
    }

    /// Make issuer != token available for protocol (isol. margin)
    function activateIssuer(address issuer, address token)
        public
        onlyOwnerExecActivator
    {
        activeIssuers[issuer] = true;
        issuerTokens[issuer] = token;
    }

    /// Remove a issuer from trading availability
    function deactivateIssuer(address issuer) external onlyOwnerExecActivator {
        activeIssuers[issuer] = false;
    }

    /// Set lending cap
    function setLendingCap(address issuer, uint256 cap)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingCap = cap;
    }

    /// Set lending buffer
    function setLendingBuffer(address issuer, uint256 buffer)
        external
        onlyOwnerExecActivator
    {
        lendingMeta[issuer].lendingBuffer = buffer;
    }

    /// Set withdrawal window
    function setWithdrawalWindow(uint256 window) external onlyOwnerExec {
        withdrawalWindow = window;
    }

    /// Set hourly yield APR for issuer
    function setHourlyYieldAPR(address issuer, uint256 aprPercent)
        external
        onlyOwnerExecActivator
    {
        HourlyBondMetadata storage bondMeta = hourlyBondMetadata[issuer];

        if (bondMeta.yieldAccumulator.accumulatorFP == 0) {
            uint256 yieldFP = FP32 + (FP32 * aprPercent) / 100 / (24 * 365);
            bondMeta.yieldAccumulator = YieldAccumulator({
                accumulatorFP: FP32,
                lastUpdated: block.timestamp,
                hourlyYieldFP: yieldFP
            });
            bondMeta.buyingSpeed = 1;
            bondMeta.withdrawingSpeed = 1;
            bondMeta.lastBought = block.timestamp;
            bondMeta.lastWithdrawn = block.timestamp;
        } else {
            YieldAccumulator storage yA =
                getUpdatedHourlyYield(issuer, bondMeta);
            yA.hourlyYieldFP = (FP32 * (100 + aprPercent)) / 100 / (24 * 365);
        }
    }

    /// Set maximum hourly yield in floating point
    function setMaxHourlyYieldFP(uint256 maxYieldFP) external onlyOwnerExec {
        maxHourlyYieldFP = maxYieldFP;
    }

    /// Set yield change per second in floating point
    function setYieldChangePerSecondFP(uint256 changePerSecondFP)
        external
        onlyOwnerExec
    {
        yieldChangePerSecondFP = changePerSecondFP;
    }

    /// Set runtime yields in floating point
    function setRuntimeYieldsFP(address issuer, uint256[] memory yieldsFP)
        external
        onlyOwnerExec
    {
        BondBucketMetadata[] storage bondMetas = bondBucketMetadata[issuer];
        for (uint256 i; bondMetas.length > i; i++) {
            bondMetas[i].runtimeYieldFP = yieldsFP[i];
        }
    }

    /// Set miniumum runtime
    function setMinRuntime(uint256 runtime) external onlyOwnerExec {
        require(runtime > 1 hours, "Min runtime > 1 hour");
        require(maxRuntime > runtime, "Runtime too long");
        minRuntime = runtime;
    }

    /// Set maximum runtime
    function setMaxRuntime(uint256 runtime) external onlyOwnerExec {
        require(runtime > minRuntime, "Max > min runtime");
        maxRuntime = runtime;
    }

    /// Set runtime weights in floating point
    function setRuntimeWeights(address issuer, uint256[] memory weights)
        external
        onlyOwnerExecActivator
    {
        BondBucketMetadata[] storage bondMetas = bondBucketMetadata[issuer];

        if (bondMetas.length == 0) {
            // we are initializing

            uint256 hourlyYieldFP = (110 * FP32) / 100 / (24 * 365);
            uint256 bucketSize = diffMaxMinRuntime / weights.length;

            for (uint256 i; weights.length > i; i++) {
                uint256 runtime = minRuntime + bucketSize * i;
                bondMetas.push(
                    BondBucketMetadata({
                        runtimeYieldFP: (hourlyYieldFP * runtime) / (1 hours),
                        lastBought: block.timestamp,
                        lastWithdrawn: block.timestamp,
                        yieldLastUpdated: block.timestamp,
                        buyingSpeed: 1,
                        withdrawingSpeed: 1,
                        runtimeWeight: weights[i],
                        totalLending: 0
                    })
                );
            }
        } else {
            require(weights.length == bondMetas.length, "Weights don't match");
            for (uint256 i; weights.length > i; i++) {
                bondMetas[i].runtimeWeight = weights[i];
            }
        }
    }

    /// @dev how much interest has accrued to a borrowed balance over time
    function applyBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external returns (uint256 balanceWithInterest, uint256 accumulatorFP) {
        require(isBorrower(msg.sender), "Not approved call");

        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        updateBorrowYieldAccu(yA);
        accumulatorFP = yA.accumulatorFP;

        balanceWithInterest = applyInterest(
            balance,
            accumulatorFP,
            yieldQuotientFP
        );

        uint256 deltaAmount = balanceWithInterest - balance;
        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += deltaAmount;
    }

    /// @dev view function to get balance with borrowing interest applied
    function viewWithBorrowInterest(
        uint256 balance,
        address issuer,
        uint256 yieldQuotientFP
    ) external view returns (uint256) {
        uint256 accumulatorFP =
            viewCumulativeYieldFP(
                borrowYieldAccumulators[issuer],
                block.timestamp
            );
        return applyInterest(balance, accumulatorFP, yieldQuotientFP);
    }

    /// @dev gets called by router to register if a trader borrows issuers
    function registerBorrow(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        meta.totalBorrowed += amount;
        require(
            meta.totalLending >= meta.totalBorrowed,
            "Insufficient lending"
        );
    }

    /// @dev gets called by router if loan is extinguished
    function payOff(address issuer, uint256 amount) external {
        require(isBorrower(msg.sender), "Not approved borrower");
        lendingMeta[issuer].totalBorrowed -= amount;
    }

    /// @dev get the borrow yield for a specific issuer/token
    function viewAccumulatedBorrowingYieldFP(address issuer)
        external
        view
        returns (uint256)
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        return viewCumulativeYieldFP(yA, block.timestamp);
    }

    function viewAPRPer10k(YieldAccumulator storage yA)
        internal
        view
        returns (uint256)
    {
        uint256 hourlyYieldFP = yA.hourlyYieldFP;

        uint256 aprFP =
            ((hourlyYieldFP * 10_000 - FP32 * 10_000) * 365 days) / (1 hours);

        return aprFP / FP32;
    }

    /// @dev get current borrowing interest per 10k for a token / issuer
    function viewBorrowAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(borrowYieldAccumulators[issuer]);
    }

    /// @dev get current lending APR per 10k for a token / issuer
    function viewHourlyBondAPRPer10k(address issuer)
        external
        view
        returns (uint256)
    {
        return viewAPRPer10k(hourlyBondMetadata[issuer].yieldAccumulator);
    }

    /// @dev In a liquidity crunch make a fallback bond until liquidity is good again
    function _makeFallbackBond(
        address issuer,
        address holder,
        uint256 amount
    ) internal override {
        _makeHourlyBond(issuer, holder, amount);
    }

    /// @dev withdraw an hour bond
    function withdrawHourlyBond(address issuer, uint256 amount) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        // apply all interest
        updateHourlyBondAmount(issuer, bond);
        super._withdrawHourlyBond(issuer, bond, amount);

        if (bond.amount == 0) {
            delete hourlyBondAccounts[issuer][msg.sender];
        }

        disburse(issuer, msg.sender, amount);

        withdrawClaim(msg.sender, issuer, amount);
    }

    /// Shut down hourly bond account for `issuer`
    function closeHourlyBondAccount(address issuer) external {
        HourlyBond storage bond = hourlyBondAccounts[issuer][msg.sender];
        // apply all interest
        updateHourlyBondAmount(issuer, bond);

        uint256 amount = bond.amount;
        super._withdrawHourlyBond(issuer, bond, amount);

        disburse(issuer, msg.sender, amount);

        delete hourlyBondAccounts[issuer][msg.sender];

        withdrawClaim(msg.sender, issuer, amount);
    }

    /// @dev buy hourly bond subscription
    function buyHourlyBondSubscription(address issuer, uint256 amount)
        external
    {
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        if (lendingTarget(meta) >= meta.totalLending + amount) {
            collectToken(issuer, msg.sender, amount);

            super._makeHourlyBond(issuer, msg.sender, amount);

            stakeClaim(msg.sender, issuer, amount);
        }
    }

    /// @dev buy fixed term bond that does not renew
    function buyBond(
        address issuer,
        uint256 runtime,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 bondIndex) {
        require(activeIssuers[issuer], "Not approved issuer");

        LendingMetadata storage meta = lendingMeta[issuer];
        if (
            lendingTarget(meta) >= meta.totalLending + amount &&
            maxRuntime >= runtime &&
            runtime >= minRuntime
        ) {
            bondIndex = super._makeBond(
                msg.sender,
                issuer,
                runtime,
                amount,
                minReturn
            );
            if (bondIndex > 0) {
                bondIds[msg.sender].push(bondIndex);

                collectToken(issuer, msg.sender, amount);
                stakeClaim(msg.sender, issuer, amount);
            }
        }
    }

    /// @dev send back funds of bond after maturity
    function withdrawBond(uint256 bondId) external {
        Bond storage bond = bonds[bondId];
        require(msg.sender == bond.holder, "Not bond holder");
        require(
            block.timestamp > bond.maturityTimestamp,
            "bond is still immature"
        );
        // in case of a shortfall, governance can step in to provide
        // additonal compensation beyond the usual incentive which
        // gets withdrawn here
        withdrawClaim(msg.sender, bond.issuer, bond.originalPrice);

        uint256 withdrawAmount = super._withdrawBond(bondId, bond);
        disburse(bond.issuer, msg.sender, withdrawAmount);
    }

    function initBorrowYieldAccumulator(address issuer)
        external
        onlyOwnerExecActivator
    {
        YieldAccumulator storage yA = borrowYieldAccumulators[issuer];
        require(yA.accumulatorFP == 0, "don't re-initialize");

        yA.accumulatorFP = FP32;
        yA.lastUpdated = block.timestamp;
        yA.hourlyYieldFP = FP32 + FP32 / (365 * 24);
    }

    function setBorrowingFactorPercent(uint256 borrowingFactor)
        external
        onlyOwnerExec
    {
        borrowingFactorPercent = borrowingFactor;
    }

    function issuanceBalance(address issuer)
        internal
        view
        override
        returns (uint256)
    {
        address token = issuerTokens[issuer];
        if (token == issuer) {
            // cross margin
            return IERC20(token).balanceOf(fund());
        } else {
            return lendingMeta[issuer].totalLending - haircuts[issuer];
        }
    }

    function disburse(
        address issuer,
        address recipient,
        uint256 amount
    ) internal {
        uint256 haircutAmount = haircuts[issuer];
        if (haircutAmount > 0 && amount > 0) {
            uint256 totalLending = lendingMeta[issuer].totalLending;
            uint256 adjustment =
                (amount * min(totalLending, haircutAmount)) / totalLending;
            amount = amount - adjustment;
            haircuts[issuer] -= adjustment;
        }

        address token = issuerTokens[issuer];
        Fund(fund()).withdraw(token, recipient, amount);
    }

    function collectToken(
        address issuer,
        address source,
        uint256 amount
    ) internal {
        Fund(fund()).depositFor(source, issuer, amount);
    }

    function haircut(uint256 amount) external {
        haircuts[msg.sender] += amount;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./RoleAware.sol";
import "../interfaces/IMarginTrading.sol";
import "./Lending.sol";
import "./Admin.sol";
import "./IncentivizedHolder.sol";
import "./BaseRouter.sol";

/// @title Top level transaction controller
contract MarginRouter is RoleAware, IncentivizedHolder, BaseRouter {
    event AccountUpdated(address indexed trader);

    uint256 public constant mswapFeesPer10k = 10;
    address public immutable WETH;

    constructor(address _WETH, address _roles) RoleAware(_roles) {
        WETH = _WETH;
    }

    ///////////////////////////
    // Cross margin endpoints
    ///////////////////////////

    /// @notice traders call this to deposit funds on cross margin
    function crossDeposit(address depositToken, uint256 depositAmount)
        external
    {
        Fund(fund()).depositFor(msg.sender, depositToken, depositAmount);

        uint256 extinguishAmount =
            IMarginTrading(crossMarginTrading()).registerDeposit(
                msg.sender,
                depositToken,
                depositAmount
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(depositToken, extinguishAmount);
            withdrawClaim(msg.sender, depositToken, extinguishAmount);
        }
        emit AccountUpdated(msg.sender);
    }

    /// @notice deposit wrapped ehtereum into cross margin account
    function crossDepositETH() external payable {
        Fund(fund()).depositToWETH{value: msg.value}();
        uint256 extinguishAmount =
            IMarginTrading(crossMarginTrading()).registerDeposit(
                msg.sender,
                WETH,
                msg.value
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(WETH, extinguishAmount);
            withdrawClaim(msg.sender, WETH, extinguishAmount);
        }
        emit AccountUpdated(msg.sender);
    }

    /// @notice withdraw deposits/earnings from cross margin account
    function crossWithdraw(address withdrawToken, uint256 withdrawAmount)
        external
    {
        IMarginTrading(crossMarginTrading()).registerWithdrawal(
            msg.sender,
            withdrawToken,
            withdrawAmount
        );
        Fund(fund()).withdraw(withdrawToken, msg.sender, withdrawAmount);
        emit AccountUpdated(msg.sender);
    }

    /// @notice withdraw ethereum from cross margin account
    function crossWithdrawETH(uint256 withdrawAmount) external {
        IMarginTrading(crossMarginTrading()).registerWithdrawal(
            msg.sender,
            WETH,
            withdrawAmount
        );
        Fund(fund()).withdrawETH(msg.sender, withdrawAmount);
        emit AccountUpdated(msg.sender);
    }

    /// @notice borrow into cross margin trading account
    function crossBorrow(address borrowToken, uint256 borrowAmount) external {
        Lending(lending()).registerBorrow(borrowToken, borrowAmount);
        IMarginTrading(crossMarginTrading()).registerBorrow(
            msg.sender,
            borrowToken,
            borrowAmount
        );

        stakeClaim(msg.sender, borrowToken, borrowAmount);
        emit AccountUpdated(msg.sender);
    }

    /// @notice convenience function to perform overcollateralized borrowing
    /// against a cross margin account.
    /// @dev caution: the account still has to have a positive balaance at the end
    /// of the withdraw. So an underwater account may not be able to withdraw
    function crossOvercollateralizedBorrow(
        address depositToken,
        uint256 depositAmount,
        address borrowToken,
        uint256 withdrawAmount
    ) external {
        Fund(fund()).depositFor(msg.sender, depositToken, depositAmount);

        Lending(lending()).registerBorrow(borrowToken, withdrawAmount);
        IMarginTrading(crossMarginTrading()).registerOvercollateralizedBorrow(
            msg.sender,
            depositToken,
            depositAmount,
            borrowToken,
            withdrawAmount
        );

        Fund(fund()).withdraw(borrowToken, msg.sender, withdrawAmount);
        stakeClaim(msg.sender, borrowToken, withdrawAmount);
        emit AccountUpdated(msg.sender);
    }

    /// @notice close an account that is no longer borrowing and return gains
    function crossCloseAccount() external {
        (address[] memory holdingTokens, uint256[] memory holdingAmounts) =
            IMarginTrading(crossMarginTrading()).getHoldingAmounts(msg.sender);

        // requires all debts paid off
        IMarginTrading(crossMarginTrading()).registerLiquidation(msg.sender);

        for (uint256 i; holdingTokens.length > i; i++) {
            Fund(fund()).withdraw(
                holdingTokens[i],
                msg.sender,
                holdingAmounts[i]
            );
        }

        emit AccountUpdated(msg.sender);
    }

    /// @notice entry point for swapping tokens held in cross margin account
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes32 amms,
        address[] calldata tokens,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        // calc fees
        uint256 fees = takeFeesFromInput(amountIn);

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib.getAmountsOut(
            amountIn - fees,
            amms,
            tokens
        );

        // checks that trader is within allowed lending bounds
        registerTrade(
            msg.sender,
            tokens[0],
            tokens[tokens.length - 1],
            amountIn,
            amounts[amounts.length - 1]
        );

        _fundSwapExactT4T(amounts, amountOutMin, pairs, tokens);
    }

    /// @notice entry point for swapping tokens held in cross margin account
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        bytes32 amms,
        address[] calldata tokens,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib.getAmountsIn(
            amountOut + takeFeesFromOutput(amountOut),
            amms,
            tokens
        );

        // checks that trader is within allowed lending bounds
        registerTrade(
            msg.sender,
            tokens[0],
            tokens[tokens.length - 1],
            amounts[0],
            amountOut
        );

        _fundSwapT4ExactT(amounts, amountInMax, pairs, tokens);
    }

    /// @dev helper function does all the work of telling other contracts
    /// about a cross margin trade
    function registerTrade(
        address trader,
        address inToken,
        address outToken,
        uint256 inAmount,
        uint256 outAmount
    ) internal {
        (uint256 extinguishAmount, uint256 borrowAmount) =
            IMarginTrading(crossMarginTrading()).registerTradeAndBorrow(
                trader,
                inToken,
                outToken,
                inAmount,
                outAmount
            );
        if (extinguishAmount > 0) {
            Lending(lending()).payOff(outToken, extinguishAmount);
            withdrawClaim(trader, outToken, extinguishAmount);
        }
        if (borrowAmount > 0) {
            Lending(lending()).registerBorrow(inToken, borrowAmount);
            stakeClaim(trader, inToken, borrowAmount);
        }

        emit AccountUpdated(trader);
    }

    /////////////
    // Helpers
    /////////////

    /// @dev internal helper swapping exact token for token on AMM
    function _fundSwapExactT4T(
        uint256[] memory amounts,
        uint256 amountOutMin,
        address[] memory pairs,
        address[] calldata tokens
    ) internal {
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "MarginRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        Fund(fund()).withdraw(tokens[0], pairs[0], amounts[0]);
        _swap(amounts, pairs, tokens, fund());
    }

    /// @notice make swaps on AMM using protocol funds, only for authorized contracts
    function authorizedSwapExactT4T(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes32 amms,
        address[] calldata tokens
    ) external returns (uint256[] memory amounts) {
        require(
            isAuthorizedFundTrader(msg.sender),
            "Calling contract is not authorized to trade with protocl funds"
        );
        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib.getAmountsOut(
            amountIn,
            amms,
            tokens
        );
        _fundSwapExactT4T(amounts, amountOutMin, pairs, tokens);
    }

    // @dev internal helper swapping exact token for token on on AMM
    function _fundSwapT4ExactT(
        uint256[] memory amounts,
        uint256 amountInMax,
        address[] memory pairs,
        address[] calldata tokens
    ) internal {
        require(
            amounts[0] <= amountInMax,
            "MarginRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        Fund(fund()).withdraw(tokens[0], pairs[0], amounts[0]);
        _swap(amounts, pairs, tokens, fund());
    }

    //// @notice swap protocol funds on AMM, only for authorized
    function authorizedSwapT4ExactT(
        uint256 amountOut,
        uint256 amountInMax,
        bytes32 amms,
        address[] calldata tokens
    ) external returns (uint256[] memory amounts) {
        require(
            isAuthorizedFundTrader(msg.sender),
            "Calling contract is not authorized to trade with protocl funds"
        );

        address[] memory pairs;
        (amounts, pairs) = UniswapStyleLib.getAmountsIn(
            amountOut,
            amms,
            tokens
        );
        _fundSwapT4ExactT(amounts, amountInMax, pairs, tokens);
    }

    function takeFeesFromOutput(uint256 amount)
        internal
        pure
        returns (uint256 fees)
    {
        fees = (mswapFeesPer10k * amount) / 10_000;
    }

    function takeFeesFromInput(uint256 amount)
        internal
        pure
        returns (uint256 fees)
    {
        fees = (mswapFeesPer10k * amount) / (10_000 + mswapFeesPer10k);
    }

    function getAmountsOut(
        uint256 inAmount,
        bytes32 amms,
        address[] calldata tokens
    ) external view returns (uint256[] memory amounts) {
        (amounts, ) = UniswapStyleLib.getAmountsOut(inAmount, amms, tokens);
    }

    function getAmountsIn(
        uint256 outAmount,
        bytes32 amms,
        address[] calldata tokens
    ) external view returns (uint256[] memory amounts) {
        (amounts, ) = UniswapStyleLib.getAmountsIn(outAmount, amms, tokens);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RoleAware.sol";
import "./MarginRouter.sol";
import "../libraries/UniswapStyleLib.sol";

/// Stores how many of token you could get for 1k of peg
struct TokenPrice {
    uint256 lastUpdated;
    uint256 priceFP;
    address[] liquidationTokens;
    bytes32 amms;
    address[] inverseLiquidationTokens;
    bytes32 inverseAmms;
}

struct VolatilitySetting {
    uint256 priceUpdateWindow;
    uint256 updateRatePermil;
    uint256 voluntaryUpdateWindow;
}

struct PairPrice {
    uint256 cumulative;
    uint256 lastUpdated;
    uint256 priceFP;
}

/// @title The protocol features several mechanisms to prevent vulnerability to
/// price manipulation:
/// 1) global exposure caps on all tokens which need to be raised gradually
///    during the process of introducing a new token, making attacks unprofitable
///    due to lack  of scale
/// 2) Exponential moving average with cautious price update. Prices for estimating
///    how much a trader can borrow need not be extremely current and precise, mainly
///    they must be resilient against extreme manipulation
/// 3) Liquidators may not call from a contract address, to prevent extreme forms of
///    of front-running and other price manipulation.
abstract contract PriceAware is RoleAware {
    uint256 constant FP64 = 2**64;
    address public immutable peg;

    mapping(address => TokenPrice) public tokenPrices;
    mapping(address => mapping(address => PairPrice)) public pairPrices;
    /// update window in blocks

    // TODO
    uint256 public priceUpdateWindow = 40 minutes;
    uint256 public voluntaryUpdateWindow = 5 minutes;

    uint256 public UPDATE_RATE_PERMIL = 400;
    VolatilitySetting[] public volatilitySettings;

    constructor(address _peg) {
        peg = _peg;
    }

    /// Set window for price updates
    function setPriceUpdateWindow(uint16 window, uint256 voluntaryWindow)
        external
        onlyOwnerExec
    {
        priceUpdateWindow = window;
        voluntaryUpdateWindow = voluntaryWindow;
    }

    /// Add a new volatility setting
    function addVolatilitySetting(
        uint256 _priceUpdateWindow,
        uint256 _updateRatePermil,
        uint256 _voluntaryUpdateWindow
    ) external onlyOwnerExec {
        volatilitySettings.push(
            VolatilitySetting({
                priceUpdateWindow: _priceUpdateWindow,
                updateRatePermil: _updateRatePermil,
                voluntaryUpdateWindow: _voluntaryUpdateWindow
            })
        );
    }

    /// Choose a volatitlity setting
    function chooseVolatilitySetting(uint256 index)
        external
        onlyOwnerExecDisabler
    {
        VolatilitySetting storage vs = volatilitySettings[index];
        if (vs.updateRatePermil > 0) {
            UPDATE_RATE_PERMIL = vs.updateRatePermil;
            priceUpdateWindow = vs.priceUpdateWindow;
            voluntaryUpdateWindow = vs.voluntaryUpdateWindow;
        }
    }

    /// Set rate for updates
    function setUpdateRate(uint256 rate) external onlyOwnerExec {
        UPDATE_RATE_PERMIL = rate;
    }

    function getCurrentPriceInPeg(address token, uint256 inAmount)
        internal
        returns (uint256)
    {
        return getCurrentPriceInPeg(token, inAmount, false);
    }

    function getCurrentPriceInPeg(
        address token,
        uint256 inAmount,
        bool voluntary
    ) public returns (uint256 priceInPeg) {
        if (token == peg) {
            return inAmount;
        } else {
            TokenPrice storage tokenPrice = tokenPrices[token];

            uint256 timeDelta = block.timestamp - tokenPrice.lastUpdated;
            if (
                timeDelta > priceUpdateWindow ||
                tokenPrice.priceFP == 0 ||
                (voluntary && timeDelta > voluntaryUpdateWindow)
            ) {
                // update the currently cached price
                uint256 priceUpdateFP;
                priceUpdateFP = getPriceByPairs(
                    tokenPrice.liquidationTokens,
                    tokenPrice.amms
                );
                _setPriceVal(tokenPrice, priceUpdateFP, UPDATE_RATE_PERMIL);
            }

            priceInPeg = (inAmount * tokenPrice.priceFP) / FP64;
        }
    }

    /// Get view of current price of token in peg
    function viewCurrentPriceInPeg(address token, uint256 inAmount)
        public
        view
        returns (uint256 priceInPeg)
    {
        if (token == peg) {
            return inAmount;
        } else {
            TokenPrice storage tokenPrice = tokenPrices[token];
            uint256 priceFP = tokenPrice.priceFP;

            priceInPeg = (inAmount * priceFP) / FP64;
        }
    }

    function _setPriceVal(
        TokenPrice storage tokenPrice,
        uint256 updateFP,
        uint256 weightPerMil
    ) internal {
        tokenPrice.priceFP =
            (tokenPrice.priceFP *
                (1000 - weightPerMil) +
                updateFP *
                weightPerMil) /
            1000;

        tokenPrice.lastUpdated = block.timestamp;
    }

    /// add path from token to current liquidation peg
    function setLiquidationPath(bytes32 amms, address[] memory tokens)
        external
        onlyOwnerExecActivator
    {
        address token = tokens[0];

        if (token != peg) {
            TokenPrice storage tokenPrice = tokenPrices[token];

            tokenPrice.amms = amms;

            tokenPrice.liquidationTokens = tokens;
            tokenPrice.inverseLiquidationTokens = new address[](tokens.length);

            bytes32 inverseAmms;

            for (uint256 i = 0; tokens.length - 1 > i; i++) {
                initPairPrice(tokens[i], tokens[i + 1], amms[i]);

                bytes32 shifted =
                    bytes32(amms[i]) >> ((tokens.length - 2 - i) * 8);

                inverseAmms = inverseAmms | shifted;
            }

            tokenPrice.inverseAmms = inverseAmms;

            for (uint256 i = 0; tokens.length > i; i++) {
                tokenPrice.inverseLiquidationTokens[i] = tokens[
                    tokens.length - i - 1
                ];
            }

            tokenPrice.priceFP = getPriceByPairs(tokens, amms);
            tokenPrice.lastUpdated = block.timestamp;
        }
    }

    function liquidateToPeg(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return amount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(marginRouter()).authorizedSwapExactT4T(
                    amount,
                    0,
                    tP.amms,
                    tP.liquidationTokens
                );

            uint256 outAmount = amounts[amounts.length - 1];

            return outAmount;
        }
    }

    function liquidateFromPeg(address token, uint256 targetAmount)
        internal
        returns (uint256)
    {
        if (token == peg) {
            return targetAmount;
        } else {
            TokenPrice storage tP = tokenPrices[token];
            uint256[] memory amounts =
                MarginRouter(marginRouter()).authorizedSwapT4ExactT(
                    targetAmount,
                    type(uint256).max,
                    tP.amms,
                    tP.inverseLiquidationTokens
                );

            return amounts[0];
        }
    }

    function getPriceByPairs(address[] memory tokens, bytes32 amms)
        internal
        returns (uint256 priceFP)
    {
        priceFP = FP64;
        for (uint256 i; i < tokens.length - 1; i++) {
            address inToken = tokens[i];
            address outToken = tokens[i + 1];

            address pair =
                amms[i] == 0
                    ? UniswapStyleLib.pairForUni(inToken, outToken)
                    : UniswapStyleLib.pairForSushi(inToken, outToken);

            PairPrice storage pairPrice = pairPrices[pair][inToken];

            uint256 timeDelta = block.timestamp - pairPrice.lastUpdated;

            if (timeDelta > voluntaryUpdateWindow) {
                // we are in business
                (address token0, ) =
                    UniswapStyleLib.sortTokens(inToken, outToken);

                uint256 cumulative =
                    inToken == token0
                        ? IUniswapV2Pair(pair).price0CumulativeLast()
                        : IUniswapV2Pair(pair).price1CumulativeLast();

                if (pairPrice.cumulative == cumulative) {
                    // nothing happened
                    priceFP = (priceFP * pairPrice.priceFP) / FP64;
                } else {
                    // something did happen
                    uint256 pairPriceFP =
                        (FP64 * (cumulative - pairPrice.cumulative)) /
                            timeDelta;
                    pairPrice.priceFP = pairPriceFP;

                    priceFP = (priceFP * pairPriceFP) / FP64;

                    pairPrice.cumulative = cumulative;
                }

                pairPrice.lastUpdated = block.timestamp;
            } else {
                priceFP = (priceFP * pairPrice.priceFP) / FP64;
            }
        }
    }

    function initPairPrice(
        address inToken,
        address outToken,
        bytes1 amm
    ) internal {
        address pair =
            amm == 0
                ? UniswapStyleLib.pairForUni(inToken, outToken)
                : UniswapStyleLib.pairForSushi(inToken, outToken);

        (uint112 reserve0, uint112 reserve1, ) =
            IUniswapV2Pair(pair).getReserves();

        PairPrice storage pairPrice = pairPrices[pair][inToken];
        (address token0, ) = UniswapStyleLib.sortTokens(inToken, outToken);

        if (inToken == token0) {
            pairPrice.priceFP = (FP64 * reserve1) / reserve0;
            pairPrice.cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        } else {
            pairPrice.priceFP = (FP64 * reserve0) / reserve1;
            pairPrice.cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
        }

        pairPrice.lastUpdated = block.timestamp;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./Roles.sol";

/// @title Role management behavior
/// Main characters are for service discovery
/// Whereas roles are for access control
contract RoleAware {
    Roles public immutable roles;
    mapping(uint256 => address) public mainCharacterCache;
    mapping(address => mapping(uint256 => bool)) public roleCache;

    constructor(address _roles) {
        require(_roles != address(0), "Please provide valid roles address");
        roles = Roles(_roles);
    }

    modifier noIntermediary() {
        require(
            msg.sender == tx.origin,
            "Currently no intermediaries allowed for this function call"
        );
        _;
    }

    // @dev Throws if called by any account other than the owner or executor
    modifier onlyOwnerExec() {
        require(
            owner() == msg.sender || executor() == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    modifier onlyOwnerExecDisabler() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                disabler() == msg.sender,
            "Caller is not the owner, executor or authorized disabler"
        );
        _;
    }

    modifier onlyOwnerExecActivator() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                isTokenActivator(msg.sender),
            "Caller is not the owner, executor or authorized activator"
        );
        _;
    }

    function updateRoleCache(uint256 role, address contr) public virtual {
        roleCache[contr][role] = roles.getRole(role, contr);
    }

    function updateMainCharacterCache(uint256 role) public virtual {
        mainCharacterCache[role] = roles.mainCharacters(role);
    }

    function owner() internal view returns (address) {
        return roles.owner();
    }

    function executor() internal returns (address) {
        return roles.executor();
    }

    function disabler() internal view returns (address) {
        return mainCharacterCache[DISABLER];
    }

    function fund() internal view returns (address) {
        return mainCharacterCache[FUND];
    }

    function lending() internal view returns (address) {
        return mainCharacterCache[LENDING];
    }

    function marginRouter() internal view returns (address) {
        return mainCharacterCache[MARGIN_ROUTER];
    }

    function crossMarginTrading() internal view returns (address) {
        return mainCharacterCache[CROSS_MARGIN_TRADING];
    }

    function feeController() internal view returns (address) {
        return mainCharacterCache[FEE_CONTROLLER];
    }

    function price() internal view returns (address) {
        return mainCharacterCache[PRICE_CONTROLLER];
    }

    function admin() internal view returns (address) {
        return mainCharacterCache[ADMIN];
    }

    function incentiveDistributor() internal view returns (address) {
        return mainCharacterCache[INCENTIVE_DISTRIBUTION];
    }

    function tokenAdmin() internal view returns (address) {
        return mainCharacterCache[TOKEN_ADMIN];
    }

    function isBorrower(address contr) internal view returns (bool) {
        return roleCache[contr][BORROWER];
    }

    function isFundTransferer(address contr) internal view returns (bool) {
        return roleCache[contr][FUND_TRANSFERER];
    }

    function isMarginTrader(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_TRADER];
    }

    function isFeeSource(address contr) internal view returns (bool) {
        return roleCache[contr][FEE_SOURCE];
    }

    function isMarginCaller(address contr) internal view returns (bool) {
        return roleCache[contr][MARGIN_CALLER];
    }

    function isLiquidator(address contr) internal view returns (bool) {
        return roleCache[contr][LIQUIDATOR];
    }

    function isAuthorizedFundTrader(address contr)
        internal
        view
        returns (bool)
    {
        return roleCache[contr][AUTHORIZED_FUND_TRADER];
    }

    function isIncentiveReporter(address contr) internal view returns (bool) {
        return roleCache[contr][INCENTIVE_REPORTER];
    }

    function isTokenActivator(address contr) internal view returns (bool) {
        return roleCache[contr][TOKEN_ACTIVATOR];
    }

    function isStakePenalizer(address contr) internal view returns (bool) {
        return roleCache[contr][STAKE_PENALIZER];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDependencyController.sol";

// we chose not to go with an enum
// to make this list easy to extend
uint256 constant FUND_TRANSFERER = 1;
uint256 constant MARGIN_CALLER = 2;
uint256 constant BORROWER = 3;
uint256 constant MARGIN_TRADER = 4;
uint256 constant FEE_SOURCE = 5;
uint256 constant LIQUIDATOR = 6;
uint256 constant AUTHORIZED_FUND_TRADER = 7;
uint256 constant INCENTIVE_REPORTER = 8;
uint256 constant TOKEN_ACTIVATOR = 9;
uint256 constant STAKE_PENALIZER = 10;

uint256 constant FUND = 101;
uint256 constant LENDING = 102;
uint256 constant MARGIN_ROUTER = 103;
uint256 constant CROSS_MARGIN_TRADING = 104;
uint256 constant FEE_CONTROLLER = 105;
uint256 constant PRICE_CONTROLLER = 106;
uint256 constant ADMIN = 107;
uint256 constant INCENTIVE_DISTRIBUTION = 108;
uint256 constant TOKEN_ADMIN = 109;

uint256 constant DISABLER = 1001;
uint256 constant DEPENDENCY_CONTROLLER = 1002;

/// @title Manage permissions of contracts and ownership of everything
/// owned by a multisig wallet (0xEED9D1c6B4cdEcB3af070D85bfd394E7aF179CBd) during
/// beta and will then be transfered to governance
/// https://github.com/marginswap/governance
contract Roles is Ownable {
    mapping(address => mapping(uint256 => bool)) public roles;
    mapping(uint256 => address) public mainCharacters;

    constructor() Ownable() {
        // token activation from the get-go
        roles[msg.sender][TOKEN_ACTIVATOR] = true;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwnerExecDepController() {
        require(
            owner() == msg.sender ||
                executor() == msg.sender ||
                mainCharacters[DEPENDENCY_CONTROLLER] == msg.sender,
            "Roles: caller is not the owner"
        );
        _;
    }

    function giveRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = true;
    }

    function removeRole(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        roles[actor][role] = false;
    }

    function setMainCharacter(uint256 role, address actor)
        external
        onlyOwnerExecDepController
    {
        mainCharacters[role] = actor;
    }

    function getRole(uint256 role, address contr) external view returns (bool) {
        return roles[contr][role];
    }

    /// @dev current executor
    function executor() public returns (address exec) {
        address depController = mainCharacters[DEPENDENCY_CONTROLLER];
        if (depController != address(0)) {
            exec = IDependencyController(depController).currentExecutor();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IDependencyController {
    function currentExecutor() external returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMarginTrading {
    function registerDeposit(
        address trader,
        address token,
        uint256 amount
    ) external returns (uint256 extinguishAmount);

    function registerWithdrawal(
        address trader,
        address token,
        uint256 amount
    ) external;

    function registerBorrow(
        address trader,
        address token,
        uint256 amount
    ) external;

    function registerTradeAndBorrow(
        address trader,
        address inToken,
        address outToken,
        uint256 inAmount,
        uint256 outAmount
    ) external returns (uint256 extinguishAmount, uint256 borrowAmount);

    function registerOvercollateralizedBorrow(
        address trader,
        address depositToken,
        uint256 depositAmount,
        address borrowToken,
        uint256 withdrawAmount
    ) external;

    function registerLiquidation(address trader) external;

    function getHoldingAmounts(address trader)
        external
        view
        returns (
            address[] memory holdingTokens,
            uint256[] memory holdingAmounts
        );

    function getBorrowAmounts(address trader)
        external
        view
        returns (address[] memory borrowTokens, uint256[] memory borrowAmounts);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

library UniswapStyleLib {
    address constant UNISWAP_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "Identical address!");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address!");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) =
            IUniswapV2Pair(pair).getReserves();

        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1_000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1_000;

        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint256 amountIn,
        bytes32 amms,
        address[] memory tokens
    ) internal view returns (uint256[] memory amounts, address[] memory pairs) {
        require(tokens.length >= 2, "token path too short");

        amounts = new uint256[](tokens.length);
        amounts[0] = amountIn;

        pairs = new address[](tokens.length - 1);

        for (uint256 i; i < tokens.length - 1; i++) {
            address inToken = tokens[i];
            address outToken = tokens[i + 1];

            address pair =
                amms[i] == 0
                    ? pairForUni(inToken, outToken)
                    : pairForSushi(inToken, outToken);
            pairs[i] = pair;

            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(pair, inToken, outToken);

            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint256 amountOut,
        bytes32 amms,
        address[] memory tokens
    ) internal view returns (uint256[] memory amounts, address[] memory pairs) {
        require(tokens.length >= 2, "token path too short");

        amounts = new uint256[](tokens.length);
        amounts[amounts.length - 1] = amountOut;

        pairs = new address[](tokens.length - 1);

        for (uint256 i = tokens.length - 1; i > 0; i--) {
            address inToken = tokens[i - 1];
            address outToken = tokens[i];

            address pair =
                amms[i - 1] == 0
                    ? pairForUni(inToken, outToken)
                    : pairForSushi(inToken, outToken);
            pairs[i - 1] = pair;

            (uint256 reserveIn, uint256 reserveOut) =
                getReserves(pair, inToken, outToken);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForUni(address tokenA, address tokenB)
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_FACTORY,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    function pairForSushi(address tokenA, address tokenB)
        internal
        pure
        returns (address pair)
    {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            SUSHI_FACTORY,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }
}

