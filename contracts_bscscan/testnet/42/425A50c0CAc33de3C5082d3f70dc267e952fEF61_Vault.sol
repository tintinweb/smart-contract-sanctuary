/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.6;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user)
        internal
        view
        returns (uint256)
    {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!safeApprove"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!safeTransfer"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!safeTransferFrom"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        // solhint-disable-next-line no-call-value
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

interface IWorker {
    /// @dev Work on a (potentially new) position. Optionally send token back to Vault.
    function work(
        uint256 id,
        address user,
        uint256 debt,
        bytes calldata data
    ) external;

    /// @dev Re-invest whatever the worker is working on.
    function reinvest() external;

    /// @dev Return the amount of wei to get back if we are to liquidate the position.
    function health(uint256 id) external view returns (uint256);

    /// @dev Liquidate the given position to token. Send all token back to its Vault.
    function liquidate(uint256 id) external;

    /// @dev SetStretegy that be able to executed by the worker.
    function setStrategyOk(address[] calldata strats, bool isOk) external;

    /// @dev Set address that can be reinvest
    function setReinvestorOk(address[] calldata reinvestor, bool isOk) external;

    /// @dev LP token holds by worker
    function lpToken() external view returns (IPancakePair);

    /// @dev Base Token that worker is working on
    function baseToken() external view returns (address);

    /// @dev Farming Token that worker is working on
    function farmingToken() external view returns (address);
}

interface IWNativeRelayer {
    function withdraw(uint256 _amount) external;
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

interface IVaultConfig {
    /// @dev Return minimum BaseToken debt size per position.
    function minDebtSize() external view returns (uint256);

    /// @dev Return the interest rate per second, using 1e18 as denom.
    function getInterestRate(uint256 debt, uint256 floating)
        external
        view
        returns (uint256);

    /// @dev Return the address of wrapped native token.
    function getWrappedNativeAddr() external view returns (address);

    /// @dev Return the address of wNative relayer.
    function getWNativeRelayer() external view returns (address);

    /// @dev Return the address of fair launch contract.
    function getFairLaunchAddr() external view returns (address);

    /// @dev Return the bps rate for reserve pool.
    function getReservePoolBps() external view returns (uint256);

    /// @dev Return the bps rate for Avada Kill caster.
    function getKillBps() external view returns (uint256);

    /// @dev Return if the caller is whitelisted.
    function whitelistedCallers(address caller) external returns (bool);

    /// @dev Return if the caller is whitelisted.
    function whitelistedLiquidators(address caller) external returns (bool);

    /// @dev Return if the given strategy is approved.
    function approvedAddStrategies(address addStrats) external returns (bool);

    /// @dev Return whether the given address is a worker.
    function isWorker(address worker) external view returns (bool);

    /// @dev Return whether the given worker accepts more debt. Revert on non-worker.
    function acceptDebt(address worker) external view returns (bool);

    /// @dev Return the work factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
    function workFactor(address worker, uint256 debt)
        external
        view
        returns (uint256);

    /// @dev Return the kill factor for the worker + BaseToken debt, using 1e4 as denom. Revert on non-worker.
    function killFactor(address worker, uint256 debt)
        external
        view
        returns (uint256);

    /// @dev Return the kill factor for the worker + BaseToken debt without checking isStable, using 1e4 as denom. Revert on non-worker.
    function rawKillFactor(address worker, uint256 debt)
        external
        view
        returns (uint256);

    /// @dev Return the portion of reward that will be transferred to treasury account after successfully killing a position.
    function getKillTreasuryBps() external view returns (uint256);

    /// @dev Return the address of treasury account
    function getTreasuryAddr() external view returns (address);

    /// @dev Return if worker is stable
    function isWorkerStable(address worker) external view returns (bool);

    /// @dev Return if reserve that worker is working with is consistent
    function isWorkerReserveConsistent(address worker)
        external
        view
        returns (bool);
}

interface IVault {
    /// @dev Return the total ERC20 entitled to the token holders. Be careful of unaccrued interests.
    function totalToken() external view returns (uint256);

    /// @dev Add more ERC20 to the bank. Hope to get some good returns.
    function deposit(uint256 amountToken) external payable;

    /// @dev Withdraw ERC20 from the bank by burning the share tokens.
    function withdraw(uint256 share) external;

    /// @dev Request funds from user through Vault
    function requestFunds(address targetedToken, uint256 amount) external;

    function token() external view returns (address);
}

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


interface IFairLaunch {
    function poolLength() external view returns (uint256);

    function addPool(
        uint256 _allocPoint,
        address _stakeToken,
        bool _withUpdate
    ) external;

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function pendingAlpaca(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function updatePool(uint256 _pid) external;

    function deposit(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdraw(
        address _for,
        uint256 _pid,
        uint256 _amount
    ) external;

    function withdrawAll(address _for, uint256 _pid) external;

    function harvest(uint256 _pid) external;
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

interface IDebtToken {
    function setOkHolders(address[] calldata _okHolders, bool _isOk) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     
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
}


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
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

    constructor() internal {
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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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

    uint256[49] private __gap;
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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

    function __ERC20_init(string memory name, string memory symbol)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol)
        internal
        initializer
    {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
        _transfer(_msgSender(), recipient, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
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
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
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

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _setupDecimals(uint8 decimals_) internal {
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

    uint256[44] private __gap;
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

contract Vault is
    IVault,
    ERC20UpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    OwnableUpgradeSafe
{
    /// @notice Libraries
    using SafeToken for address;
    using SafeMath for uint256;

    /// @notice Events
    event AddDebt(uint256 indexed id, uint256 debtShare);
    event RemoveDebt(uint256 indexed id, uint256 debtShare);
    event Work(uint256 indexed id, uint256 loan);
    event Kill(
        uint256 indexed id,
        address indexed killer,
        address owner,
        uint256 posVal,
        uint256 debt,
        uint256 prize,
        uint256 left
    );
    event AddCollateral(
        uint256 indexed id,
        uint256 amount,
        uint256 healthBefore,
        uint256 healthAfter
    );

    /// @dev Flags for manage execution scope
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private constant _NO_ID = uint256(-1);
    address private constant _NO_ADDRESS = address(1);

    /// @dev Temporay variables to manage execution scope
    uint256 public _IN_EXEC_LOCK;
    uint256 public POSITION_ID;
    address public STRATEGY;

    /// @dev Attributes for Vault
    /// token - address of the token to be deposited in this pool
    /// name - name of the ibERC20
    /// symbol - symbol of ibERC20
    /// decimals - decimals of ibERC20, this depends on the decimal of the token
    /// debtToken - just a simple ERC20 token for staking with FairLaunch
    address public override token;
    address public debtToken;

    struct Position {
        address worker;
        address owner;
        uint256 debtShare;
    }

    IVaultConfig public config;
    mapping(uint256 => Position) public positions;
    uint256 public nextPositionID;
    uint256 public fairLaunchPoolId;

    uint256 public vaultDebtShare;
    uint256 public vaultDebtVal;
    uint256 public lastAccrueTime;
    uint256 public reservePool;

    /// @dev Require that the caller must be an EOA account if not whitelisted.
    modifier onlyEOAorWhitelisted() {
        if (!config.whitelistedCallers(msg.sender)) {
            require(msg.sender == tx.origin, "not eoa");
        }
        _;
    }

    /// @dev Require that the caller must be an EOA account if not whitelisted.
    modifier onlyWhitelistedLiqudators() {
        require(
            config.whitelistedLiquidators(msg.sender),
            "!whitelisted liquidator"
        );
        _;
    }

    /// @dev Get token from msg.sender
    modifier transferTokenToVault(uint256 value) {
        if (msg.value != 0) {
            require(
                token == config.getWrappedNativeAddr(),
                "baseToken is not wNative"
            );
            require(value == msg.value, "value != msg.value");
            IWETH(config.getWrappedNativeAddr()).deposit{value: msg.value}();
        } else {
            SafeToken.safeTransferFrom(token, msg.sender, address(this), value);
        }
        _;
    }

    /// @dev Ensure that the function is called with the execution scope
    modifier inExec() {
        require(POSITION_ID != _NO_ID, "not within execution scope");
        require(STRATEGY == msg.sender, "not from the strategy");
        require(_IN_EXEC_LOCK == _NOT_ENTERED, "in exec lock");
        _IN_EXEC_LOCK = _ENTERED;
        _;
        _IN_EXEC_LOCK = _NOT_ENTERED;
    }

    /// @dev Add more debt to the bank debt pool.
    modifier accrue(uint256 value) {
        if (now > lastAccrueTime) {
            uint256 interest = pendingInterest(value);
            uint256 toReserve = interest.mul(config.getReservePoolBps()).div(
                10000
            );
            reservePool = reservePool.add(toReserve);
            vaultDebtVal = vaultDebtVal.add(interest);
            lastAccrueTime = now;
        }
        _;
    }

    function initialize(
        IVaultConfig _config,
        address _token,
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        address _debtToken
    ) external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        ReentrancyGuardUpgradeSafe.__ReentrancyGuard_init();
        ERC20UpgradeSafe.__ERC20_init(_name, _symbol);
        _setupDecimals(_decimals);

        nextPositionID = 1;
        config = _config;
        lastAccrueTime = now;
        token = _token;

        fairLaunchPoolId = uint256(-1);

        debtToken = _debtToken;

        SafeToken.safeApprove(
            debtToken,
            config.getFairLaunchAddr(),
            uint256(-1)
        );

        // free-up execution scope
        _IN_EXEC_LOCK = _NOT_ENTERED;
        POSITION_ID = _NO_ID;
        STRATEGY = _NO_ADDRESS;
    }

    /// @dev Return the pending interest that will be accrued in the next call.
    /// @param value Balance value to subtract off address(this).balance when called from payable functions.
    function pendingInterest(uint256 value) public view returns (uint256) {
        if (now > lastAccrueTime) {
            uint256 timePast = now.sub(lastAccrueTime);
            uint256 balance = SafeToken.myBalance(token).sub(value);
            uint256 ratePerSec = config.getInterestRate(vaultDebtVal, balance);
            return ratePerSec.mul(vaultDebtVal).mul(timePast).div(1e18);
        } else {
            return 0;
        }
    }

    /// @dev Return the Token debt value given the debt share. Be careful of unaccrued interests.
    /// @param debtShare The debt share to be converted.
    function debtShareToVal(uint256 debtShare) public view returns (uint256) {
        if (vaultDebtShare == 0) return debtShare; // When there's no share, 1 share = 1 val.
        return debtShare.mul(vaultDebtVal).div(vaultDebtShare);
    }

    /// @dev Return the debt share for the given debt value. Be careful of unaccrued interests.
    /// @param debtVal The debt value to be converted.
    function debtValToShare(uint256 debtVal) public view returns (uint256) {
        if (vaultDebtShare == 0) return debtVal; // When there's no share, 1 share = 1 val.
        return debtVal.mul(vaultDebtShare).div(vaultDebtVal);
    }

    /// @dev Return Token value and debt of the given position. Be careful of unaccrued interests.
    /// @param id The position ID to query.
    function positionInfo(uint256 id) external view returns (uint256, uint256) {
        Position storage pos = positions[id];
        return (IWorker(pos.worker).health(id), debtShareToVal(pos.debtShare));
    }

    /// @dev Return the total token entitled to the token holders. Be careful of unaccrued interests.
    function totalToken() public view override returns (uint256) {
        return SafeToken.myBalance(token).add(vaultDebtVal).sub(reservePool);
    }

    /// @dev Add more token to the lending pool. Hope to get some good returns.
    function deposit(uint256 amountToken)
        external
        payable
        override
        transferTokenToVault(amountToken)
        accrue(amountToken)
        nonReentrant
    {
        _deposit(amountToken);
    }

    function _deposit(uint256 amountToken) internal {
        uint256 total = totalToken().sub(amountToken);
        uint256 share = total == 0
            ? amountToken
            : amountToken.mul(totalSupply()).div(total);
        _mint(msg.sender, share);
        require(totalSupply() > 1e17, "no tiny shares");
    }

    /// @dev Withdraw token from the lending and burning ibToken.
    function withdraw(uint256 share) external override accrue(0) nonReentrant {
        uint256 amount = share.mul(totalToken()).div(totalSupply());
        _burn(msg.sender, share);
        _safeUnwrap(msg.sender, amount);
        require(totalSupply() > 1e17, "no tiny shares");
    }

    /// @dev Request Funds from user through Vault
    function requestFunds(address targetedToken, uint256 amount)
        external
        override
        inExec
    {
        SafeToken.safeTransferFrom(
            targetedToken,
            positions[POSITION_ID].owner,
            msg.sender,
            amount
        );
    }

    /// @dev Mint & deposit debtToken on behalf of farmers
    /// @param id The ID of the position
    /// @param amount The amount of debt that the position holds
    function _fairLaunchDeposit(uint256 id, uint256 amount) internal {
        if (amount > 0) {
            IDebtToken(debtToken).mint(address(this), amount);
            IFairLaunch(config.getFairLaunchAddr()).deposit(
                positions[id].owner,
                fairLaunchPoolId,
                amount
            );
        }
    }

    /// @dev Withdraw & burn debtToken on behalf of farmers
    /// @param id The ID of the position
    function _fairLaunchWithdraw(uint256 id) internal {
        if (positions[id].debtShare > 0) {
            // Note: Do this way because we don't want to fail open, close, or kill position
            // if cannot withdraw from FairLaunch somehow. 0xb5c5f672 is a signature of withdraw(address,uint256,uint256)
            (bool success, ) = config.getFairLaunchAddr().call(
                abi.encodeWithSelector(
                    0xb5c5f672,
                    positions[id].owner,
                    fairLaunchPoolId,
                    positions[id].debtShare
                )
            );
            if (success)
                IDebtToken(debtToken).burn(
                    address(this),
                    positions[id].debtShare
                );
        }
    }

    /// @dev Transfer to "to". Automatically unwrap if BTOKEN is WBNB
    /// @param to The address of the receiver
    /// @param amount The amount to be withdrawn
    function _safeUnwrap(address to, uint256 amount) internal {
        if (token == config.getWrappedNativeAddr()) {
            SafeToken.safeTransfer(token, config.getWNativeRelayer(), amount);
            IWNativeRelayer(uint160(config.getWNativeRelayer())).withdraw(
                amount
            );
            SafeToken.safeTransferETH(to, amount);
        } else {
            SafeToken.safeTransfer(token, to, amount);
        }
    }

    /// @dev addCollateral to the given position.
    /// @param id The ID of the position to add collaterals.
    /// @param amount The amount of BTOKEN to be added to the position
    /// @param goRogue If on skip worker stability check, else only check reserve consistency.
    /// @param data The calldata to pass along to the worker for more working context.
    function addCollateral(
        uint256 id,
        uint256 amount,
        bool goRogue,
        bytes calldata data
    )
        external
        payable
        onlyEOAorWhitelisted
        transferTokenToVault(amount)
        accrue(amount)
        nonReentrant
    {
        require(fairLaunchPoolId != uint256(-1), "poolId not set");
        require(id != 0, "no id 0");

        // 1. Load position from state & sanity check
        Position storage pos = positions[id];
        address worker = pos.worker;
        uint256 healthBefore = IWorker(worker).health(id);
        require(id < nextPositionID, "bad position id");
        require(pos.owner == msg.sender, "!position owner");
        require(healthBefore != 0, "!active position");
        // 2. Book execution scope variables. Check if the given strategy is known add strat.
        POSITION_ID = id;
        (STRATEGY, ) = abi.decode(data, (address, bytes));
        require(config.approvedAddStrategies(STRATEGY), "!approved strat");
        // 3. If not goRouge then check worker stability, else only check reserve consistency.
        if (!goRogue) require(config.isWorkerStable(worker), "worker !stable");
        else
            require(
                config.isWorkerReserveConsistent(worker),
                "reserve !consistent"
            );
        // 4. Getting required info.
        uint256 debt = debtShareToVal(pos.debtShare);
        // 5. Perform add collateral according to the strategy.
        uint256 beforeBEP20 = SafeToken.myBalance(token).sub(amount);
        SafeToken.safeTransfer(token, worker, amount);
        IWorker(worker).work(id, msg.sender, debt, data);
        uint256 healthAfter = IWorker(worker).health(id);
        uint256 back = SafeToken.myBalance(token).sub(beforeBEP20);
        // 6. Sanity check states after perform add collaterals
        // - if not goRouge then check worker stability else only check reserve consistency.
        // - back must be 0 as it is adding collateral only. No BTOKEN needed to be returned.
        // - healthAfter must more than before.
        // - debt ratio must below kill factor - 1%
        if (!goRogue) require(config.isWorkerStable(worker), "worker !stable");
        else
            require(
                config.isWorkerReserveConsistent(worker),
                "reserve !consistent"
            );
        require(back == 0, "back !0");
        require(healthAfter > healthBefore, "health !increase");
        uint256 killFactor = config.rawKillFactor(pos.worker, debt);
        require(
            debt.mul(10000) <= healthAfter.mul(killFactor.sub(100)),
            "debtRatio > killFactor margin"
        );
        // 7. Release execution scope
        POSITION_ID = _NO_ID;
        STRATEGY = _NO_ADDRESS;
        // 8. Emit event
        emit AddCollateral(id, amount, healthBefore, healthAfter);
    }

    /// @dev Create a new farming position to unlock your yield farming potential.
    /// @param id The ID of the position to unlock the earning. Use ZERO for new position.
    /// @param worker The address of the authorized worker to work for this position.
    /// @param principalAmount The anout of Token to supply by user.
    /// @param borrowAmount The amount of Token to borrow from the pool.
    /// @param maxReturn The max amount of Token to return to the pool.
    /// @param data The calldata to pass along to the worker for more working context.
    function work(
        uint256 id,
        address worker,
        uint256 principalAmount,
        uint256 borrowAmount,
        uint256 maxReturn,
        bytes calldata data
    )
        external
        payable
        onlyEOAorWhitelisted
        transferTokenToVault(principalAmount)
        accrue(principalAmount)
        nonReentrant
    {
        require(fairLaunchPoolId != uint256(-1), "poolId not set");
        // 1. Sanity check the input position, or add a new position of ID is 0.
        Position storage pos;
        if (id == 0) {
            id = nextPositionID++;
            pos = positions[id];
            pos.worker = worker;
            pos.owner = msg.sender;
        } else {
            pos = positions[id];
            require(id < nextPositionID, "bad position id");
            require(pos.worker == worker, "bad position worker");
            require(pos.owner == msg.sender, "not position owner");
            _fairLaunchWithdraw(id);
        }
        emit Work(id, borrowAmount);
        // Update execution scope variables
        POSITION_ID = id;
        (STRATEGY, ) = abi.decode(data, (address, bytes));
        // 2. Make sure the worker can accept more debt and remove the existing debt.
        require(config.isWorker(worker), "not a worker");
        require(
            borrowAmount == 0 || config.acceptDebt(worker),
            "worker not accept more debt"
        );
        uint256 debt = _removeDebt(id).add(borrowAmount);
        // 3. Perform the actual work, using a new scope to avoid stack-too-deep errors.
        uint256 back;
        {
            uint256 sendBEP20 = principalAmount.add(borrowAmount);
            require(
                sendBEP20 <= SafeToken.myBalance(token),
                "insufficient funds in the vault"
            );
            uint256 beforeBEP20 = SafeToken.myBalance(token).sub(sendBEP20);
            SafeToken.safeTransfer(token, worker, sendBEP20);
            IWorker(worker).work(id, msg.sender, debt, data);
            back = SafeToken.myBalance(token).sub(beforeBEP20);
        }
        // 4. Check and update position debt.
        uint256 lessDebt = Math.min(debt, Math.min(back, maxReturn));
        debt = debt.sub(lessDebt);
        if (debt > 0) {
            require(debt >= config.minDebtSize(), "too small debt size");
            uint256 health = IWorker(worker).health(id);
            uint256 workFactor = config.workFactor(worker, debt);
            require(
                health.mul(workFactor) >= debt.mul(10000),
                "bad work factor"
            );
            _addDebt(id, debt);
            _fairLaunchDeposit(id, pos.debtShare);
        }
        // 5. Release execution scope
        POSITION_ID = _NO_ID;
        STRATEGY = _NO_ADDRESS;
        // 6. Return excess token back.
        if (back > lessDebt) {
            _safeUnwrap(msg.sender, back.sub(lessDebt));
        }
    }

    /// @dev Kill the given to the position. Liquidate it immediately if killFactor condition is met.
    /// @param id The position ID to be killed.
    function kill(uint256 id)
        external
        onlyWhitelistedLiqudators
        accrue(0)
        nonReentrant
    {
        require(fairLaunchPoolId != uint256(-1), "poolId not set");
        // 1. Verify that the position is eligible for liquidation.
        Position storage pos = positions[id];
        require(pos.debtShare > 0, "no debt");
        // 2. Distribute ALPACAs in FairLaunch to owner
        _fairLaunchWithdraw(id);
        uint256 debt = _removeDebt(id);
        uint256 health = IWorker(pos.worker).health(id);
        uint256 killFactor = config.killFactor(pos.worker, debt);
        require(health.mul(killFactor) < debt.mul(10000), "can't liquidate");
        // 3. Perform liquidation and compute the amount of token received.
        uint256 beforeToken = SafeToken.myBalance(token);
        IWorker(pos.worker).liquidate(id);
        uint256 back = SafeToken.myBalance(token).sub(beforeToken);

        uint256 liquidatorPrize = back.mul(config.getKillBps()).div(10000);
        uint256 tresauryFees = back.mul(config.getKillTreasuryBps()).div(10000);
        uint256 prize = liquidatorPrize.add(tresauryFees);
        uint256 rest = back.sub(prize);
        // 4. Clear position debt and return funds to liquidator and position owner.
        if (liquidatorPrize > 0) {
            _safeUnwrap(msg.sender, liquidatorPrize);
        }

        if (tresauryFees > 0) {
            _safeUnwrap(config.getTreasuryAddr(), tresauryFees);
        }

        uint256 left = rest > debt ? rest - debt : 0;
        if (left > 0) {
            _safeUnwrap(pos.owner, left);
        }

        emit Kill(id, msg.sender, pos.owner, health, debt, prize, left);
    }

    /// @dev Internal function to add the given debt value to the given position.
    function _addDebt(uint256 id, uint256 debtVal) internal {
        Position storage pos = positions[id];
        uint256 debtShare = debtValToShare(debtVal);
        pos.debtShare = pos.debtShare.add(debtShare);
        vaultDebtShare = vaultDebtShare.add(debtShare);
        vaultDebtVal = vaultDebtVal.add(debtVal);
        emit AddDebt(id, debtShare);
    }

    /// @dev Internal function to clear the debt of the given position. Return the debt value.
    function _removeDebt(uint256 id) internal returns (uint256) {
        Position storage pos = positions[id];
        uint256 debtShare = pos.debtShare;
        if (debtShare > 0) {
            uint256 debtVal = debtShareToVal(debtShare);
            pos.debtShare = 0;
            vaultDebtShare = vaultDebtShare.sub(debtShare);
            vaultDebtVal = vaultDebtVal.sub(debtVal);
            emit RemoveDebt(id, debtShare);
            return debtVal;
        } else {
            return 0;
        }
    }

    /// @dev Update bank configuration to a new address. Must only be called by owner.
    /// @param _config The new configurator address.
    function updateConfig(IVaultConfig _config) external onlyOwner {
        config = _config;
    }

    function setFairLaunchPoolId(uint256 _poolId) external onlyOwner {
        SafeToken.safeApprove(
            debtToken,
            config.getFairLaunchAddr(),
            uint256(-1)
        );
        fairLaunchPoolId = _poolId;
    }

    /// @dev Withdraw BaseToken reserve for underwater positions to the given address.
    /// @param to The address to transfer BaseToken to.
    /// @param value The number of BaseToken tokens to withdraw. Must not exceed `reservePool`.
    function withdrawReserve(address to, uint256 value)
        external
        onlyOwner
        nonReentrant
    {
        reservePool = reservePool.sub(value);
        SafeToken.safeTransfer(token, to, value);
    }

    /// @dev Reduce BaseToken reserve, effectively giving them to the depositors.
    /// @param value The number of BaseToken reserve to reduce.
    function reduceReserve(uint256 value) external onlyOwner {
        reservePool = reservePool.sub(value);
    }

    /// @dev Fallback function to accept BNB.
    receive() external payable {}
}