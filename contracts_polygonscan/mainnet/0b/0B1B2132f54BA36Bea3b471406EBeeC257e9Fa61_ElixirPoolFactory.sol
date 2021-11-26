/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// File: interfaces/IPool.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @title Illuvium Pool
 *
 * @notice An abstraction representing a pool, see IlluviumPoolBase for details
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
interface IPool {
    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of stake with its amount, weight and term (time interval)
     */
    struct Deposit {
        // @dev token amount staked
        uint256 tokenAmount;
        // @dev stake weight
        uint256 weight;
        // @dev liquid percentage;
        uint256 liquidPercentage;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
        // @dev indicates if the stake was created as a yield reward
        bool isYield;
    }

    function eli() external view returns (address);

    function poolToken() external view returns (address);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function pendingYieldRewards(address _user) external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _user, uint256 _depositId)
        external
        view
        returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function stake(uint256 _amount, uint64 _lockedUntil) external;

    function unstake(uint256 _depositId, uint256 _amount) external;

    function sync() external;

    function processRewards() external;

    function setWeight(uint32 _weight) external;
}

// File: interfaces/IFactory.sol

pragma solidity 0.8.2;

interface IFactory {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function endBlock() external view returns (uint32);

    function eliPerBlock() external view returns (uint192);

    function totalWeight() external view returns (uint32);

    function transferYieldTo(
        address _to,
        uint256 _amount,
        uint256 _liquidRewardAmount
    ) external;

    function unstakeBurnFee(address _tokenAddress)
        external
        view
        returns (uint256);

    function burnAddress() external view returns (address);

    function shouldUpdateRatio() external view returns (bool);

    function updateELIPerBlock() external;

    function getPoolAddress(address poolToken) external view returns (address);

    function owner() external view returns (address);

    function maximumRewardLock() external view returns (uint256);

    function minimumRewardLock() external view returns (uint256);

    function poolExists(address) external view returns (bool);
}

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// File: interfaces/ICorePool.sol

pragma solidity 0.8.2;


interface ICorePool is IPool {
    function vaultRewardsPerToken() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);

    function stakeAsPool(
        address _staker,
        uint256 _amount,
        uint256 _liquidPercent,
        uint256 _lockTime
    ) external;

    function receiveVaultRewards(uint256 _amount) external;
}

// File: contracts/ReentrancyGuard.sol

// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/ReentrancyGuard.sol
// #24a0bc23cfe3fbc76f8f2510b78af1e948ae6651

pragma solidity 0.8.2;

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

    constructor() {
        _status = _NOT_ENTERED;
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: interfaces/IERC20.sol

pragma solidity 0.8.2;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: utils/Address.sol

pragma solidity 0.8.2;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: utils/SafeERC20.sol

pragma solidity 0.8.2;



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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/ElixirPoolBase.sol

pragma solidity 0.8.2;






/**
 * @title Elixir Pool Base
 *
 * @notice An abstract contract containing common logic for any pool,
 *      be it a flash pool (temporary pool like SNX) or a core pool (permanent pool like ELIXIR/ETH or ELIXIR pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (IFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - ELIXIR token address
 *          - pool token address, it can be ELIXIR token address, ELIXIR/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 10% for ELIXIR pool and 90% for ELIXIR/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For ELIXIR Pool we use 100 as weight and for ELIXIR/ETH pool - 900.
 *
 */
abstract contract ElixirPoolBase is IPool, ReentrancyGuard {
    address public override eli;
    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked amount
        uint256 tokenAmount;
        //@dev Total Liquid Staked Amount
        uint256 liquidAmount;
        // @dev Total weight
        uint256 totalWeight;
        // @dev Liquid weight;
        uint256 liquidWeight;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev Auxiliary variable for vault rewards calculation
        uint256 subVaultRewards;
        // @dev An array of holder's deposits
        Deposit[] deposits;
    }

    address[] public history;
    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory IFactory instance
    IFactory public factory;

    /// @dev Link to the pool token instance, for example ELIXIR or ELIXIR/ETH pair
    address public override poolToken;

    /// @dev Pool weight, 100 for ELIXIR pool or 900 for ELIXIR/ETH
    uint32 public override weight;

    /// @dev Block number of the last yield distribution event
    uint64 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e6 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e6
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e6
     */
    uint256 internal WEIGHT_MULTIPLIER = 1e6;

    /** @dev Stake weight for Liquid Guys (its 1/10 of Normal Weight Multiplier)
     */
    uint256 internal LIQUID_MULTIPLIER = 1e5;

    /**
     * @dev When we know beforehand that staking is done for a year, and fraction of the year locked is one,
     *      we use simplified calculation and use the following constant instead previos one
     */
    uint256 internal YEAR_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;

    /**
     * @dev Rewards per weight are stored multiplied by 1e12, as integers.
     */
    uint256 internal REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);

    /**
     * @dev Fired in _updateStakeLock() and updateStakeLock()
     *
     * @param _by an address which performed an operation
     * @param depositId updated deposit ID
     * @param lockedFrom deposit locked from value
     * @param lockedUntil updated deposit locked until value
     */
    event StakeLockUpdated(
        address indexed _by,
        uint256 depositId,
        uint64 lockedFrom,
        uint64 lockedUntil
    );

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(
        address indexed _by,
        uint256 yieldRewardsPerWeight,
        uint64 lastYieldDistribution
    );

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(
        address indexed _by,
        address indexed _to,
        uint256 amount
    );

    /**
     * @dev Fired in setWeight()
     *
     * @param _by an address which performed an operation, always a factory
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(
        address indexed _by,
        uint32 _fromVal,
        uint32 _toVal
    );

    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _eli ELI ERC20 Token ElixirERC20 address
     * @param _factory Pool factory IFactory instance/address
     * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _eli,
        IFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight
    ) {
        require(
            address(_factory) != address(0),
            "ELIXIR Pool fct address not set"
        );
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock > 0, "init block not set");
        require(_weight > 0, "pool weight not set");

        // save the inputs into internal state variables
        eli = _eli;
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
    }

    function initConfig(
        address _eli,
        IFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight
    ) internal {
        eli = _eli;
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;
        lastYieldDistribution = _initBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker)
        external
        view
        override
        returns (uint256)
    {
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = factory.endBlock();
            uint256 multiplier = blockNumber() > endBlock
                ? endBlock - lastYieldDistribution
                : blockNumber() - lastYieldDistribution;
            uint256 eliRewards = (multiplier * weight * factory.eliPerBlock()) /
                factory.totalWeight();

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight =
                rewardToWeight(eliRewards, usersLockingWeight) +
                yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        // based on the rewards per weight value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = weightToReward(
            user.totalWeight,
            newYieldRewardsPerWeight
        ) - user.subYieldRewards;

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId)
        external
        view
        override
        returns (Deposit memory)
    {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user)
        external
        view
        override
        returns (uint256)
    {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     */
    function stake(uint256 _amount, uint64 _lockUntil) external override {
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockUntil, false, 0);
        history.push(msg.sender);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(uint256 _depositId, uint256 _amount) external override {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
        history.push(msg.sender);
    }

    /**
     * @notice Extends locking period for a given deposit
     *
     * @dev Requires new lockedUntil value to be:
     *      higher than the current one, and
     *      in the future, but
     *      no more than 1 year in the future
     *
     * @param depositId updated deposit ID
     * @param lockedUntil updated deposit locked until value
     */
    function updateStakeLock(uint256 depositId, uint64 lockedUntil) external {
        // sync and call processRewards
        _sync();
        _processRewards(msg.sender, false);
        // delegate call to an internal function
        _updateStakeLock(msg.sender, depositId, lockedUntil);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     */
    function processRewards() external virtual override {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint32 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == address(factory), "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(msg.sender, weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker)
        internal
        view
        returns (uint256 pending)
    {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return
            weightToReward(user.totalWeight, yieldRewardsPerWeight) -
            user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockUntil stake period as unix timestamp; zero means no locking
     * @param _isYield a flag indicating if that stake is created to store yield reward
     *      from the previously unstaked stake
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockUntil,
        bool _isYield,
        uint256 _liquidPercent
    ) internal virtual {
        // validate the inputs
        require(_amount > 0, "zero amount");
        require(
            _lockUntil == 0 ||
                (_lockUntil > now256() && _lockUntil - now256() <= 365 days),
            "invalid lock interval"
        );

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        // in most of the cases added amount `addedAmount` is simply `_amount`
        // however for deflationary tokens this can be different

        // read the current balance
        uint256 previousBalance = IERC20(poolToken).balanceOf(address(this));
        // transfer `_amount`; note: some tokens may get burnt here
        transferPoolTokenFrom(address(msg.sender), address(this), _amount);
        // read new balance, usually this is just the difference `previousBalance - _amount`
        uint256 newBalance = IERC20(poolToken).balanceOf(address(this));
        // calculate real amount taking into account deflation
        uint256 addedAmount = newBalance - previousBalance;

        // set the `lockFrom` and `lockUntil` taking into account that
        // zero value for `_lockUntil` means "no locking" and leads to zero values
        // for both `lockFrom` and `lockUntil`
        uint64 lockFrom = _lockUntil > 0 ? uint64(now256()) : 0;
        uint64 lockUntil = _lockUntil;

        uint256 weightMultiplier = _lockUntil > 0
            ? WEIGHT_MULTIPLIER
            : LIQUID_MULTIPLIER;

        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil - lockFrom) * weightMultiplier) /
            365 days +
            weightMultiplier) * addedAmount;

        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit = Deposit({
            tokenAmount: addedAmount,
            weight: stakeWeight,
            liquidPercentage: _isYield ? _liquidPercent : 0,
            lockedFrom: lockFrom,
            lockedUntil: lockUntil,
            isYield: _isYield
        });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        // update user record
        user.tokenAmount += addedAmount;
        user.totalWeight += stakeWeight;
        if (_lockUntil == 0) {
            user.liquidAmount += addedAmount;
            user.liquidWeight += stakeWeight;
        }
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            yieldRewardsPerWeight
        );

        // update global variable
        usersLockingWeight += stakeWeight;

        // emit an event
        emit Staked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];
        // deposit structure may get deleted, so we save isYield flag to be able to use it
        bool isYield = stakeDeposit.isYield;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 stakeWeightMultiplier = stakeDeposit.lockedUntil == 0
            ? LIQUID_MULTIPLIER
            : WEIGHT_MULTIPLIER;
        uint256 newWeight = (((stakeDeposit.lockedUntil -
            stakeDeposit.lockedFrom) * stakeWeightMultiplier) /
            365 days +
            stakeWeightMultiplier) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount - _amount == 0) {
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        if (stakeDeposit.lockedUntil == 0) {
            user.liquidAmount -= _amount;
            user.liquidWeight = user.liquidWeight - previousWeight + newWeight;
        }
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(
            user.totalWeight,
            yieldRewardsPerWeight
        );

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // if the deposit was created by the pool itself as a yield reward
        if (isYield) {
            // transfer the yield via the factory
            uint256 liquidRewardAmount = (_amount *
                stakeDeposit.liquidPercentage) / 100;
            factory.transferYieldTo(msg.sender, _amount, liquidRewardAmount);
        } else {
            uint256 _burnAmount = (_amount *
                factory.unstakeBurnFee(poolToken)) / 100;
            // otherwise just return tokens back to holder
            if (_burnAmount > 0) {
                transferPoolToken(factory.burnAddress(), _burnAmount);
            }
            if (_burnAmount < _amount) {
                transferPoolToken(msg.sender, _amount - _burnAmount);
            }
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updateELIPerBlock`
     */
    function _sync() internal virtual {
        // update ELIXIR per block value in factory if required
        if (factory.shouldUpdateRatio()) {
            factory.updateELIPerBlock();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = factory.endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = uint64(blockNumber());
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock
            ? endBlock
            : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;
        uint256 eliPerBlock = factory.eliPerBlock();

        // calculate the reward
        uint256 eliReward = (blocksPassed * eliPerBlock * weight) /
            factory.totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += rewardToWeight(eliReward, usersLockingWeight);
        lastYieldDistribution = uint64(currentBlock);

        // emit an event
        emit Synchronized(
            msg.sender,
            yieldRewardsPerWeight,
            lastYieldDistribution
        );
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated and optionally re-staked
     */
    function _processRewards(address _staker, bool _withUpdate)
        internal
        virtual
        returns (uint256 pendingYield)
    {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        if (poolToken == eli) {
            // calculate pending yield weight,
            // 2e6 is the bonus weight when staking for 1 year
            uint256 depositWeight = pendingYield * YEAR_STAKE_WEIGHT_MULTIPLIER;

            // if the pool is ELIXIR Pool - create new ELIXIR deposit
            // and save it - push it into deposits array
            Deposit memory newDeposit = Deposit({
                tokenAmount: pendingYield,
                lockedFrom: uint64(now256()),
                lockedUntil: uint64(now256() + getRewardLockPeriod(_staker)), // staking yield for Reward Lock Period
                weight: depositWeight,
                liquidPercentage: (user.liquidWeight * 100) / user.totalWeight,
                isYield: true
            });
            user.deposits.push(newDeposit);

            // update user record
            user.tokenAmount += pendingYield;
            user.totalWeight += depositWeight;

            // update global variable
            usersLockingWeight += depositWeight;
        } else {
            // for other pools - stake as pool
            address eliPool = factory.getPoolAddress(eli);
            ICorePool(eliPool).stakeAsPool(
                _staker,
                pendingYield,
                (user.liquidWeight * 100) / user.totalWeight,
                getRewardLockPeriod(_staker)
            );
        }

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = weightToReward(
                user.totalWeight,
                yieldRewardsPerWeight
            );
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }

    /**
     * @dev See updateStakeLock()
     *
     * @param _staker an address to update stake lock
     * @param _depositId updated deposit ID
     * @param _lockedUntil updated deposit locked until value
     */
    function _updateStakeLock(
        address _staker,
        uint256 _depositId,
        uint64 _lockedUntil
    ) internal {
        // validate the input time
        require(_lockedUntil > now256(), "lock should be in the future");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        // validate the input against deposit structure
        require(_lockedUntil > stakeDeposit.lockedUntil, "invalid new lock");

        // verify locked from and locked until values
        if (stakeDeposit.lockedFrom == 0) {
            require(
                _lockedUntil - now256() <= 365 days,
                "max lock period is 365 days"
            );
            stakeDeposit.lockedFrom = uint64(now256());
        } else {
            require(
                _lockedUntil - stakeDeposit.lockedFrom <= 365 days,
                "max lock period is 365 days"
            );
        }

        // update locked until value, calculate new weight
        stakeDeposit.lockedUntil = _lockedUntil;
        uint256 newWeight = (((stakeDeposit.lockedUntil -
            stakeDeposit.lockedFrom) * WEIGHT_MULTIPLIER) /
            365 days +
            WEIGHT_MULTIPLIER) * stakeDeposit.tokenAmount;

        // save previous weight
        uint256 previousWeight = stakeDeposit.weight;
        // update weight
        stakeDeposit.weight = newWeight;

        // update user total weight and global locking weight
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // emit an event
        emit StakeLockUpdated(
            _staker,
            _depositId,
            stakeDeposit.lockedFrom,
            _lockedUntil
        );
    }

    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      ELIXIR reward value, applying the 10^12 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight ELIXIR reward per weight
     * @return reward value normalized to 10^12
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight)
        public
        view
        returns (uint256)
    {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward ELIXIR value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward ELIXIR value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight)
        public
        view
        returns (uint256)
    {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolToken(address _to, uint256 _value)
        internal
        nonReentrant
    {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal nonReentrant {
        // just delegate call to the target
        SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
    }

    /** @dev Get History Length */
    function getHistoryLength() external view returns (uint256) {
        return history.length;
    }

    /** @dev Clearing History for more updates */
    function clearHistory() external {
        require(msg.sender == factory.owner(), "access denied");
        delete history;
    }

    function setConfiguration(
        uint256 _rewardPerWeightMultiplier,
        uint256 _yearStakeWeightMultiplier,
        uint256 _weightMultiplier,
        uint256 _liquidMultiplier
    ) external {
        require(msg.sender == factory.owner(), "access denied");
        REWARD_PER_WEIGHT_MULTIPLIER = _rewardPerWeightMultiplier;
        YEAR_STAKE_WEIGHT_MULTIPLIER = _yearStakeWeightMultiplier;
        WEIGHT_MULTIPLIER = _weightMultiplier;
        LIQUID_MULTIPLIER = _liquidMultiplier;
    }

    function setInitialSettings(address _factory, address _poolToken) external {
        require(msg.sender == factory.owner(), "access denied");
        factory = IFactory(_factory);
        poolToken = _poolToken;
    }

    /** @dev Get Reward Lock Time */
    function getRewardLockPeriod(address _staker)
        public
        view
        returns (uint256)
    {
        User storage user = users[_staker];
        if (user.tokenAmount == 0) {
            return factory.maximumRewardLock();
        }

        uint256 i;
        uint256 totalSum = 0;
        for (i = 0; i < user.deposits.length; i++) {
            Deposit storage stakeDeposit = user.deposits[i];
            if (!stakeDeposit.isYield) {
                totalSum =
                    totalSum +
                    stakeDeposit.tokenAmount *
                    (stakeDeposit.lockedUntil - stakeDeposit.lockedFrom);
            }
        }
        uint256 averageLocked = factory.maximumRewardLock() -
            totalSum /
            user.tokenAmount;
        if (averageLocked < factory.minimumRewardLock()) {
            return factory.minimumRewardLock();
        }
        if (averageLocked > factory.maximumRewardLock()) {
            return factory.maximumRewardLock();
        }
        return averageLocked;
    }
}

// File: contracts/ElixirCorePool.sol

pragma solidity 0.8.2;



/**
 * @title Elixir Core Pool
 *
 * @notice Core pools represent permanent pools like ELIXIR or ELIXIR/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See ElixirPoolBase for more details
 *
 */
contract ElixirCorePool is ElixirPoolBase, Initializable {
    /// @dev Link to deployed ElixirVault instance
    address public vault;

    /// @dev Used to calculate vault rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public vaultRewardsPerWeight;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are ELIXIR (ELIXIR core pool) or ELIXIR/ETH pair (LP core pool)
    /// @dev For LP core pool this value doesnt' count for ELIXIR tokens received as Vault rewards
    ///      while for ELIXIR core pool it does count for such tokens as well
    uint256 public poolTokenReserve;

    /**
     * @dev Fired in receiveVaultRewards()
     *
     * @param _by an address that sent the rewards, always a vault
     * @param amount amount of tokens received
     */
    event VaultRewardsReceived(address indexed _by, uint256 amount);

    /**
     * @dev Fired in _processVaultRewards() and dependent functions, like processRewards()
     *
     * @param _by an address which executed the function
     * @param _to an address which received a reward
     * @param amount amount of reward received
     */
    event VaultRewardsClaimed(
        address indexed _by,
        address indexed _to,
        uint256 amount
    );

    /**
     * @dev Fired in setVault()
     *
     * @param _by an address which executed the function, always a factory owner
     */
    event VaultUpdated(address indexed _by, address _fromVal, address _toVal);

    /**
     * @dev Creates/deploys an instance of the core pool
     *
     * @param _eli ELI ERC20 Token ElixirERC20 address
     * @param _factory Pool factory ElixirPoolFactory instance/address
     * @param _poolToken token the pool operates on, for example ELIXIR or ELIXIR/ETH pair
     * @param _initBlock initial block used to calculate the rewards
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _eli,
        IFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight
    ) ElixirPoolBase(_eli, _factory, _poolToken, _initBlock, _weight) {}

    function initialize(
        address _eli,
        IFactory _factory,
        address _poolToken,
        uint64 _initBlock,
        uint32 _weight
    ) public initializer {
        super.initConfig(_eli, _factory, _poolToken, _initBlock, _weight);
    }

    /**
     * @notice Calculates current vault rewards value available for address specified
     *
     * @dev Performs calculations based on current smart contract state only,
     *      not taking into account any additional time/blocks which might have passed
     *
     * @param _staker an address to calculate vault rewards value for
     * @return pending calculated vault reward value for the given address
     */
    function pendingVaultRewards(address _staker)
        public
        view
        returns (uint256 pending)
    {
        User memory user = users[_staker];

        return
            weightToReward(user.totalWeight, vaultRewardsPerWeight) -
            user.subVaultRewards;
    }

    /**
     * @dev Executed only by the factory owner to Set the vault
     *
     * @param _vault an address of deployed ElixirVault instance
     */
    function setVault(address _vault) external {
        // verify function is executed by the factory owner
        require(factory.owner() == msg.sender, "access denied");

        // verify input is set
        require(_vault != address(0), "zero input");

        // emit an event
        emit VaultUpdated(msg.sender, vault, _vault);

        // update vault address
        vault = _vault;
    }

    /**
     * @dev Executed by the vault to transfer vault rewards ELIXIR from the vault
     *      into the pool
     *
     * @dev This function is executed only for ELIXIR core pools
     *
     * @param _rewardsAmount amount of ELIXIR rewards to transfer into the pool
     */
    function receiveVaultRewards(uint256 _rewardsAmount) external {
        require(msg.sender == vault, "access denied");
        // return silently if there is no reward to receive
        if (_rewardsAmount == 0) {
            return;
        }
        require(usersLockingWeight > 0, "zero locking weight");

        transferEliFrom(msg.sender, address(this), _rewardsAmount);

        vaultRewardsPerWeight += rewardToWeight(
            _rewardsAmount,
            usersLockingWeight
        );

        // update `poolTokenReserve` only if this is a ELIXIR Core Pool
        if (poolToken == eli) {
            poolTokenReserve += _rewardsAmount;
        }

        emit VaultRewardsReceived(msg.sender, _rewardsAmount);
    }

    /**
     * @notice Service function to calculate and pay pending vault and yield rewards to the sender
     *
     * @dev Internally executes similar function `_processRewards` from the parent smart contract
     *      to calculate and pay yield rewards; adds vault rewards processing
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     */
    function processRewards() external override {
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed internally by the pool itself (from the parent `ElixirPoolBase` smart contract)
     *      as part of yield rewards processing logic (`ElixirPoolBase._processRewards` function)
     *
     * @param _staker an address which stakes (the yield reward)
     * @param _amount amount to be staked (yield reward amount)
     */
    function stakeAsPool(
        address _staker,
        uint256 _amount,
        uint256 _liquidPercent,
        uint256 _rewardLockPeriod
    ) external {
        require(factory.poolExists(msg.sender), "access denied");
        _sync();
        User storage user = users[_staker];
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }
        uint256 depositWeight = _amount * YEAR_STAKE_WEIGHT_MULTIPLIER;
        Deposit memory newDeposit = Deposit({
            tokenAmount: _amount,
            lockedFrom: uint64(now256()),
            lockedUntil: uint64(now256() + _rewardLockPeriod),
            weight: depositWeight,
            liquidPercentage: _liquidPercent,
            isYield: true
        });
        user.tokenAmount += _amount;
        user.totalWeight += depositWeight;
        user.deposits.push(newDeposit);

        usersLockingWeight += depositWeight;

        user.subYieldRewards = weightToReward(
            user.totalWeight,
            yieldRewardsPerWeight
        );
        user.subVaultRewards = weightToReward(
            user.totalWeight,
            vaultRewardsPerWeight
        );

        // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
        poolTokenReserve += _amount;
    }

    /**
     * @inheritdoc ElixirPoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockedUntil,
        bool _isYield,
        uint256 _liquidPercent
    ) internal override {
        super._stake(_staker, _amount, _lockedUntil, _isYield, _liquidPercent);
        User storage user = users[_staker];
        user.subVaultRewards = weightToReward(
            user.totalWeight,
            vaultRewardsPerWeight
        );

        poolTokenReserve += _amount;
    }

    /**
     * @inheritdoc ElixirPoolBase
     *
     * @dev Additionally to the parent smart contract, updates vault rewards of the holder,
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(
            stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil,
            "deposit not yet unlocked"
        );
        poolTokenReserve -= _amount;
        super._unstake(_staker, _depositId, _amount);
        user.subVaultRewards = weightToReward(
            user.totalWeight,
            vaultRewardsPerWeight
        );
    }

    /**
     * @inheritdoc ElixirPoolBase
     *
     * @dev Additionally to the parent smart contract, processes vault rewards of the holder,
     *      and for ELIXIR pool updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _processRewards(address _staker, bool _withUpdate)
        internal
        override
        returns (uint256 pendingYield)
    {
        _processVaultRewards(_staker);
        pendingYield = super._processRewards(_staker, _withUpdate);

        // update `poolTokenReserve` only if this is a ELIXIR Core Pool
        if (poolToken == eli) {
            poolTokenReserve += pendingYield;
        }
    }

    /**
     * @dev Used internally to process vault rewards for the staker
     *
     * @param _staker address of the user (staker) to process rewards for
     */
    function _processVaultRewards(address _staker) private {
        User storage user = users[_staker];
        uint256 pendingVaultClaim = pendingVaultRewards(_staker);
        if (pendingVaultClaim == 0) return;
        // read ELIXIR token balance of the pool via standard ERC20 interface
        uint256 eliBalance = IERC20(eli).balanceOf(address(this));
        require(
            eliBalance >= pendingVaultClaim,
            "contract ELI balance too low"
        );

        // update `poolTokenReserve` only if this is a ELIXIR Core Pool
        if (poolToken == eli) {
            // protects against rounding errors
            poolTokenReserve -= pendingVaultClaim > poolTokenReserve
                ? poolTokenReserve
                : pendingVaultClaim;
        }

        user.subVaultRewards = weightToReward(
            user.totalWeight,
            vaultRewardsPerWeight
        );

        // transfer fails if pool ELIXIR balance is not enough - which is a desired behavior
        transferEli(_staker, pendingVaultClaim);

        emit VaultRewardsClaimed(msg.sender, _staker, pendingVaultClaim);
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferEli(address _to, uint256 _value) internal nonReentrant {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(eli), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     */
    function transferEliFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal nonReentrant {
        // just delegate call to the target
        SafeERC20.safeTransferFrom(IERC20(eli), _from, _to, _value);
    }
}

// File: utils/Ownable.sol

pragma solidity 0.8.2;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msg.sender;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: utils/ERC20.sol

pragma solidity 0.8.2;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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

// Copied from Open Zeppelin

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @notice Token creator is responsible for creating (minting)
     *      tokens to an arbitrary address
     * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
     *      (calling `mint` function)
     */
    uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

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
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/ElixirPoolFactory.sol

pragma solidity 0.8.2;






/**
 * @title Elixir Pool Factory
 *
 * @notice ELI Pool Factory manages Elixir Yield farming pools, provides a single
 *      public interface to access the pools, provides an interface for the pools
 *      to mint yield rewards, access pool-related info, update weights, etc.
 *
 * @notice The factory is authorized (via its owner) to register new pools, change weights
 *      of the existing pools, removing the pools (by changing their weights to zero)
 *
 * @dev The factory requires ROLE_TOKEN_CREATOR permission on the ELI token to mint yield
 *      (see `transferYieldTo` function)
 *
 * @author Pedro Bergamini, reviewed by Basil Gorin
 */
contract ElixirPoolFactory is Ownable {
    /**
     * @dev Smart contract unique identifier, a random number
     * @dev Should be regenerated each time smart contact source code is changed
     *      and changes smart contract itself is to be redeployed
     * @dev Generated using https://www.random.org/bytes/
     */
    address public eli;
    address public start;

    /// @dev Unstaking Burn Fee for each pool
    mapping(address => uint256) public unstakeBurnFee;

    /// @dev Auxiliary data structure used only in getPoolData() view function
    struct PoolData {
        // @dev pool token address (like ELI)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for ELI pools, 800 for ELI/ETH pools - set during deployment)
        uint32 weight;
    }

    /**
     * @dev ELI/block determines yield farming reward base
     *      used by the yield pools controlled by the factory
     */
    uint192 public eliPerBlock;

    /**
     * @dev Percent of Reward Reduce Per Block
     */
    uint192 public rewardReducePercent = 97;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion
     */
    uint32 public totalWeight;

    /**
     * @dev ELI/block decreases by 3% every blocks/update (set to 91252 blocks during deployment);
     *      an update is triggered by executing `updateELIPerBlock` public function
     */
    uint32 public blocksPerUpdate;

    /**
     * @dev End block is the last block when ELI/block can be decreased;
     *      it is implied that yield farming stops after that block
     */
    uint32 public endBlock;

    /** @dev Burn Address */
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    /** @dev Burn Percentage */
    uint256 public burnFee = 250; // 2.5% of Liquid Reward will be burned

    /** @dev Maximum Reward Lock Period */
    uint256 public maximumRewardLock = 365 days;
    uint256 public minimumRewardLock = 30 days;

    /**
     * @dev Each time the ELI/block ratio gets updated, the block number
     *      when the operation has occurred gets recorded into `lastRatioUpdate`
     * @dev This block number is then used to check if blocks/update `blocksPerUpdate`
     *      has passed when decreasing yield reward by 3%
     */
    uint32 public lastRatioUpdate;

    /// @dev Maps pool token address (like ELI) -> pool address (like core pool instance)
    mapping(address => address) public pools;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag
    mapping(address => bool) public poolExists;

    /**
     * @dev Fired in createPool() and registerPool()
     *
     * @param _by an address which executed an action
     * @param poolToken pool token address (like ELI)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     */
    event PoolRegistered(
        address indexed _by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight
    );

    /**
     * @dev Fired in changePoolWeight()
     *
     * @param _by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event WeightUpdated(
        address indexed _by,
        address indexed poolAddress,
        uint32 weight
    );

    /**
     * @dev Fired in updateELIPerBlock()
     *
     * @param _by an address which executed an action
     * @param newEliPerBlock new ELI/block value
     */
    event EliRatioUpdated(address indexed _by, uint256 newEliPerBlock);

    /**
     * @dev Creates/deploys a factory instance
     *
     * @param _eli ELI ERC20 token address
     * @param _eliPerBlock initial ELI/block value for rewards
     * @param _blocksPerUpdate how frequently the rewards gets updated (decreased by 3%), blocks
     * @param _initBlock block number to measure _blocksPerUpdate from
     * @param _endBlock block number when farming stops and rewards cannot be updated anymore
     */
    constructor(
        address _eli,
        uint192 _eliPerBlock,
        uint32 _blocksPerUpdate,
        uint32 _initBlock,
        uint32 _endBlock
    ) {
        // verify the inputs are set
        require(_eliPerBlock > 0, "ELI/block not set");
        require(_blocksPerUpdate > 0, "blocks/update not set");
        require(_initBlock > 0, "init block not set");
        require(
            _endBlock > _initBlock,
            "invalid end block: must be greater than init block"
        );

        // save the inputs into internal state variables
        eli = _eli;
        eliPerBlock = _eliPerBlock;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Given a pool token retrieves corresponding pool address
     *
     * @dev A shortcut for `pools` mapping
     *
     * @param poolToken pool token address (like ELI) to query pool address for
     * @return pool address for the token specified
     */
    function getPoolAddress(address poolToken) external view returns (address) {
        // read the mapping and return
        return pools[poolToken];
    }

    /**
     * @notice Reads pool information for the pool defined by its pool token address,
     *      designed to simplify integration with the front ends
     *
     * @param _poolToken pool token address to query pool information for
     * @return pool information packed in a PoolData struct
     */
    function getPoolData(address _poolToken)
        public
        view
        returns (PoolData memory)
    {
        // get the pool address from the mapping
        address poolAddr = pools[_poolToken];

        // throw if there is no pool registered for the token specified
        require(poolAddr != address(0), "pool not found");

        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        uint32 weight = IPool(poolAddr).weight();

        // create the in-memory structure and return it
        return
            PoolData({
                poolToken: poolToken,
                poolAddress: poolAddr,
                weight: weight
            });
    }

    /**
     * @dev Verifies if `blocksPerUpdate` has passed since last ELI/block
     *      ratio update and if ELI/block reward can be decreased by 3%
     *
     * @return true if enough time has passed and `updateELIPerBlock` can be executed
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if yield farming period has ended
        if (blockNumber() > endBlock) {
            // ELI/block reward cannot be updated anymore
            return false;
        }

        // check if blocks/update (91252 blocks) have passed since last update
        return blockNumber() >= lastRatioUpdate + blocksPerUpdate;
    }

    /**
     * @dev Creates a core pool (ElixirCorePool) and registers it within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolToken pool token address (like ELI, or ELI/ETH pair)
     * @param initBlock init block to be used for the pool created
     * @param weight weight of the pool to be created
     */
    function createPool(
        address poolToken,
        uint64 initBlock,
        uint32 weight
    ) external virtual onlyOwner {
        // create/deploy new core pool instance
        IPool pool = new ElixirCorePool(
            eli,
            IFactory(address(this)),
            poolToken,
            initBlock,
            weight
        );

        // register it within a factory
        registerPool(address(pool));
    }

    /**
     * @dev Registers an already deployed pool instance within the factory
     *
     * @dev Can be executed by the pool factory owner only
     *
     * @param poolAddr address of the already deployed pool instance
     */
    function registerPool(address poolAddr) public onlyOwner {
        // read pool information from the pool smart contract
        // via the pool interface (IPool)
        address poolToken = IPool(poolAddr).poolToken();
        uint32 weight = IPool(poolAddr).weight();

        // ensure that the pool is not already registered within the factory
        require(
            pools[poolToken] == address(0),
            "this pool is already registered"
        );

        // create pool structure, register it within the factory
        pools[poolToken] = poolAddr;
        poolExists[poolAddr] = true;
        // update total pool weight of the factory
        totalWeight += weight;

        // emit an event
        emit PoolRegistered(msg.sender, poolToken, poolAddr, weight);
    }

    /**
     * @notice Decreases ELI/block reward by 3%, can be executed
     *      no more than once per `blocksPerUpdate` blocks
     */
    function updateELIPerBlock() external {
        // checks if ratio can be updated i.e. if blocks/update (91252 blocks) have passed
        require(shouldUpdateRatio(), "too frequent");

        // decreases ELI/block reward by RewardReducePercent
        eliPerBlock = (eliPerBlock * rewardReducePercent) / 100;

        // set current block as the last ratio update block
        lastRatioUpdate = uint32(blockNumber());

        // emit an event
        emit EliRatioUpdated(msg.sender, eliPerBlock);
    }

    /**
     * @dev Transfer ELI tokens; executed by ELI Pool only
     *
     * @dev Requires factory to have ROLE_TOKEN_CREATOR permission
     *      on the ELI ERC20 token instance
     *
     * @param _to an address to mint tokens to
     * @param _amount amount of ELI tokens to mint
     */
    function transferYieldTo(
        address _to,
        uint256 _amount,
        uint256 _liquidRewardAmount
    ) external {
        // verify that sender is a pool registered withing the factory
        require(poolExists[msg.sender], "access denied");

        uint256 burnAmount = (_liquidRewardAmount * burnFee) / 10000;

        require(_amount > burnAmount, "burn amount is big");

        uint256 rewardAmount = _amount - burnAmount;

        IERC20(eli).transfer(burnAddress, burnAmount);
        // send ELI tokens as required
        IERC20(eli).transfer(_to, rewardAmount);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner
     *
     * @param poolAddr address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address poolAddr, uint32 weight)
        external
        onlyOwner
    {
        // recalculate total weight
        totalWeight = totalWeight + weight - IPool(poolAddr).weight();

        // set the new pool weight
        IPool(poolAddr).setWeight(weight);

        // emit an event
        emit WeightUpdated(msg.sender, poolAddr, weight);
    }

    /** @dev set burn fee function */
    function setBurnFee(uint256 _burnFee) external onlyOwner {
        burnFee = _burnFee;
    }

    /** @dev set reward lock period */

    function setRewardLockLimit(uint256 _minLock, uint256 _maxLock)
        external
        onlyOwner
    {
        minimumRewardLock = _minLock;
        maximumRewardLock = _maxLock;
    }

    function setAddresses(address _eli, address _start) external onlyOwner {
        eli = _eli;
        start = _start;
    }

    function setUnstakeBurnFee(address _poolToken, uint256 _burnFee)
        external
        onlyOwner
    {
        unstakeBurnFee[_poolToken] = _burnFee;
    }

    function setGeneralInfo(
        address _eli,
        uint192 _eliPerBlock,
        uint192 _rewardReducePercent,
        uint32 _blocksPerUpdate,
        uint32 _initBlock,
        uint32 _endBlock
    ) external onlyOwner {
        // save the inputs into internal state variables
        eli = _eli;
        eliPerBlock = _eliPerBlock;
        rewardReducePercent = _rewardReducePercent;
        blocksPerUpdate = _blocksPerUpdate;
        lastRatioUpdate = _initBlock;
        endBlock = _endBlock;
    }

    function emergencyWithdraw(address _to) external onlyOwner {
        IERC20(eli).transfer(_to, IERC20(eli).balanceOf(address(this)));
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }
}