// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper, nodar, suhail, seb, sumit, apoorv

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Curve stablecoin and BTC liquidity pools in one transaction with ETH or ERC tokens.

// File: Context.sol

pragma solidity ^0.5.5;

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
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: OpenZepplinOwnable.sol

pragma solidity ^0.5.0;

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
    address payable public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
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
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: OpenZepplinSafeMath.sol

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
// File: OpenZepplinIERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
// File: OpenZepplinReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor() internal {
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
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

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
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
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
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface IUniswapRouter02 {
    //get estimated amountOut
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    //token 2 token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    //eth 2 token
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    //token 2 eth
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface ICurveSwap {
    function coins(int128 arg0) external view returns (address);

    function underlying_coins(int128 arg0) external view returns (address);

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;
}

interface yERC20 {
    function deposit(uint256 _amount) external;
}

interface IBalancer {
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

contract Curve_ZapIn_General_V1_9 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bool public stopped = false;
    uint16 public goodwill = 0;
    address
        public zgoodwillAddress = 0xE737b6AfEC2320f616297e59445b60a11e3eF75F;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    IUniswapRouter02 private constant uniswapRouter = IUniswapRouter02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    IBalancer private BalWBTCPool = IBalancer(
        0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5
    );

    address
        private constant wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address
        private constant wbtcToken = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address
        public intermediateStable = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    struct Pool {
        address swapAddress;
        address tokenAddress;
        address[4] poolTokens;
        bool isMetaPool;
    }

    mapping(address => Pool) public curvePools;
    mapping(address => address) private metaPools; //Token address => swap address

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
    @notice This function adds liquidity to a Curve pool with ETH or ERC20 tokens
    @param toWhomToIssue The address to return the Curve LP tokens to
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param swapAddress Curve swap address for the pool
    @param incomingTokenQty The amount of fromToken to invest
    @param minPoolTokens The minimum acceptable quantity of tokens to receive. Reverts otherwise
    @return Amount of Curve LP tokens received
     */
    function ZapIn(
        address toWhomToIssue,
        address fromToken,
        address swapAddress,
        uint256 incomingTokenQty,
        uint256 minPoolTokens
    )
        external
        payable
        stopInEmergency
        nonReentrant
        returns (uint256 crvTokensBought)
    {
        uint256 toInvest;
        if (fromToken == address(0)) {
            require(msg.value > 0, "Error: ETH not sent");
            toInvest = msg.value;
        } else {
            require(msg.value == 0, "Error: ETH sent");
            require(incomingTokenQty > 0, "Error: Invalid ERC amount");
            IERC20(fromToken).safeTransferFrom(
                msg.sender,
                address(this),
                incomingTokenQty
            );
            toInvest = incomingTokenQty;
        }
        (bool isUnderlying, uint8 underlyingIndex) = _isUnderlyingToken(
            swapAddress,
            fromToken
        );
        if (isUnderlying) {
            crvTokensBought = _enterCurve(
                swapAddress,
                toInvest,
                underlyingIndex
            );
        } else {
            (uint256 tokensBought, uint8 index) = _getIntermediate(
                swapAddress,
                fromToken,
                toInvest
            );
            crvTokensBought = _enterCurve(swapAddress, tokensBought, index);
        }
        require(
            crvTokensBought > minPoolTokens,
            "Received less than minPoolTokens"
        );

        address poolTokenAddress = curvePools[swapAddress].tokenAddress;
        uint256 goodwillPortion;
        if (goodwill > 0) {
            goodwillPortion = SafeMath.div(
                SafeMath.mul(crvTokensBought, goodwill),
                10000
            );
            IERC20(poolTokenAddress).safeTransfer(
                zgoodwillAddress,
                goodwillPortion
            );
        }
        IERC20(poolTokenAddress).transfer(
            toWhomToIssue,
            SafeMath.sub(crvTokensBought, goodwillPortion)
        );
    }

    /**
    @notice This function swaps to an appropriate intermediate token to be used to add liquidity
    @param swapAddress Curve swap address for the pool
    @param fromToken The ERC20 token used for investment (address(0x00) if ether)
    @param amount The amount of fromToken to invest
    @return Amount of tokens (or LP) bought, token index for add_liquidity call
     */
    function _getIntermediate(
        address swapAddress,
        address fromToken,
        uint256 amount
    ) internal returns (uint256 tokensBought, uint8 index) {
        Pool memory pool2Enter = curvePools[swapAddress];
        address[4] memory poolTokens = pool2Enter.poolTokens;
        if (pool2Enter.isMetaPool) {
            for (uint8 i = 0; i < 4; i++) {
                if (metaPools[poolTokens[i]] != address(0)) {
                    address intermediateSwapAddress = metaPools[poolTokens[i]];
                    (
                        bool isUnderlying,
                        uint8 underlyingIndex
                    ) = _isUnderlyingToken(intermediateSwapAddress, fromToken);
                    if (isUnderlying) {
                        tokensBought = _enterCurve(
                            intermediateSwapAddress,
                            amount,
                            underlyingIndex
                        );
                        return (tokensBought, i);
                    }
                    uint256 intermediateTokenBought;
                    if (_isBtcPool(intermediateSwapAddress)) {
                        intermediateTokenBought = _token2Token(
                            fromToken,
                            wbtcToken,
                            amount
                        );
                        (, index) = _isUnderlyingToken(
                            intermediateSwapAddress,
                            wbtcToken
                        );
                    } else {
                        intermediateTokenBought = _token2Token(
                            fromToken,
                            intermediateStable,
                            amount
                        );
                        (, index) = _isUnderlyingToken(
                            intermediateSwapAddress,
                            intermediateStable
                        );
                    }
                    tokensBought = _enterCurve(
                        intermediateSwapAddress,
                        intermediateTokenBought,
                        index
                    );
                    return (tokensBought, i);
                }
            }
        } else {
            if (_isBtcPool(swapAddress)) {
                tokensBought = _token2Token(fromToken, wbtcToken, amount);
                (, index) = _isUnderlyingToken(swapAddress, wbtcToken);
                return (tokensBought, index);
            }
            tokensBought = _token2Token(fromToken, intermediateStable, amount);
            (, index) = _isUnderlyingToken(swapAddress, intermediateStable);
        }
    }

    /**
    @notice This function is used to swap ETH/ERC20 <> ETH/ERC20
    @param fromToken The token address to swap from. (0x00 for ETH)
    @param toToken The token address to swap to. (0x00 for ETH)
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address fromToken,
        address toToken,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (fromToken == address(0)) {
            address[] memory path = new address[](2);
            path[0] = wethToken;
            path[1] = toToken;
            tokenBought = uniswapRouter.swapExactETHForTokens.value(
                tokens2Trade
            )(1, path, address(this), deadline)[path.length - 1];
        } else {
            IERC20(fromToken).safeIncreaseAllowance(
                address(uniswapRouter),
                tokens2Trade
            );
            if (fromToken != wethToken) {
                // check output via tokenA -> tokenB
                address pairA = UniSwapV2FactoryAddress.getPair(
                    fromToken,
                    toToken
                );
                address[] memory pathA = new address[](2);
                pathA[0] = fromToken;
                pathA[1] = toToken;
                uint256 amtA;
                if (pairA != address(0)) {
                    amtA = uniswapRouter.getAmountsOut(tokens2Trade, pathA)[1];
                }

                // check output via tokenA -> weth -> tokenB
                address[] memory pathB = new address[](3);
                pathB[0] = fromToken;
                pathB[1] = wethToken;
                pathB[2] = toToken;

                uint256 amtB = uniswapRouter.getAmountsOut(
                    tokens2Trade,
                    pathB
                )[2];

                if (amtA >= amtB) {
                    tokenBought = uniswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        pathA,
                        address(this),
                        deadline
                    )[pathA.length - 1];
                } else {
                    tokenBought = uniswapRouter.swapExactTokensForTokens(
                        tokens2Trade,
                        1,
                        pathB,
                        address(this),
                        deadline
                    )[pathB.length - 1];
                }
            } else {
                address[] memory path = new address[](2);
                path[0] = wethToken;
                path[1] = toToken;
                tokenBought = uniswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        }
        require(tokenBought > 0, "Error Swapping Tokens");
    }

    /**
    @notice This function adds liquidity to a curve pool
    @param swapAddress Curve swap address for the pool
    @param amount The quantity of tokens being added as liquidity
    @param index The token index for the add_liquidity call
    @return tokenBought The quantity of curve LP tokens received
    */
    function _enterCurve(
        address swapAddress,
        uint256 amount,
        uint8 index
    ) internal returns (uint256 crvTokensBought) {
        address tokenAddress = curvePools[swapAddress].tokenAddress;
        uint256 iniTokenBal = IERC20(tokenAddress).balanceOf(address(this));
        address entryToken = curvePools[swapAddress].poolTokens[index];
        IERC20(entryToken).safeIncreaseAllowance(address(swapAddress), amount);
        uint256 numTokens = _getNumTokens(swapAddress);
        if (numTokens == 4) {
            uint256[4] memory amounts;
            amounts[index] = amount;
            ICurveSwap(swapAddress).add_liquidity(amounts, 0);
        } else if (numTokens == 3) {
            uint256[3] memory amounts;
            amounts[index] = amount;
            ICurveSwap(swapAddress).add_liquidity(amounts, 0);
        } else {
            uint256[2] memory amounts;
            amounts[index] = amount;
            ICurveSwap(swapAddress).add_liquidity(amounts, 0);
        }
        crvTokensBought = (IERC20(tokenAddress).balanceOf(address(this))).sub(
            iniTokenBal
        );
    }

    /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
    function _isBtcPool(address swapAddress) internal view returns (bool) {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint8 i = 0; i < 4; i++) {
            if (poolTokens[i] == wbtcToken) return true;
        }
        return false;
    }

    function _getNumTokens(address swapAddress)
        internal
        view
        returns (uint256 numTokens)
    {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        if (poolTokens[2] == address(0)) return 2;
        if (poolTokens[3] == address(0)) return 3;
        return 4;
    }

    function _isUnderlyingToken(
        address swapAddress,
        address fromTokenContractAddress
    ) internal view returns (bool, uint8) {
        address[4] memory poolTokens = getPoolTokens(swapAddress);
        for (uint8 i = 0; i < 4; i++) {
            if (poolTokens[i] == address(0)) return (false, 0);
            if (poolTokens[i] == fromTokenContractAddress) return (true, i);
        }
    }

    /**
    @notice This function adds a new supported pool
    @param swapAddress Curve swap address for the pool
    @param tokenAddress Curve token address for the pool
    @param poolTokens token (or LP) contract addresses of underlying tokens
    @dev poolTokens should be unwrapped tokens (e.g. DAI not yDAI)
    @dev poolTokens should use 0 address for pools with < 4 tokens
    @param isMetaPool true if pool contains a curve LP token as a pool token
    */
    function addPool(
        address swapAddress,
        address tokenAddress,
        address[4] calldata poolTokens,
        bool isMetaPool
    ) external onlyOwner {
        require(
            curvePools[swapAddress].swapAddress == address(0),
            "Pool exists"
        );
        Pool memory newPool = Pool(
            swapAddress,
            tokenAddress,
            poolTokens,
            isMetaPool
        );
        curvePools[swapAddress] = newPool;
        metaPools[tokenAddress] = swapAddress;
    }

    /**
    @notice This function updates an existing supported pool
    @param swapAddress Curve swap address for the pool
    @param tokenAddress Curve token address for the pool
    @param poolTokens token (or LP) contract addresses of underlying tokens
    @dev poolTokens should be unwrapped tokens (e.g. DAI not yDAI)
    @dev poolTokens should use 0 address for pools with < 4 tokens
    @param isMetaPool true if pool contains a curve LP token as a pool token
    */
    function updatePool(
        address swapAddress,
        address tokenAddress,
        address[4] calldata poolTokens,
        bool isMetaPool
    ) external onlyOwner {
        require(
            curvePools[swapAddress].swapAddress == swapAddress,
            "Pool doesn't exist"
        );
        Pool storage pool2Update = curvePools[swapAddress];
        pool2Update.tokenAddress = tokenAddress;
        pool2Update.poolTokens = poolTokens;
        pool2Update.isMetaPool = isMetaPool;
        metaPools[tokenAddress] = swapAddress;
    }

    /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return returns a 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
    function getPoolTokens(address swapAddress)
        public
        view
        returns (address[4] memory poolTokens)
    {
        poolTokens = curvePools[swapAddress].poolTokens;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) external onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        IERC20(_TokenAddress).safeTransfer(_owner, qty);
    }

    function set_new_goodwill(uint16 _new_goodwill) external onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill < 10000,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_zgoodwillAddress(address _new_zgoodwillAddress)
        external
        onlyOwner
    {
        zgoodwillAddress = _new_zgoodwillAddress;
    }

    function updateIntermediateStable(address newIntermediate)
        external
        onlyOwner
    {
        require(
            newIntermediate != intermediateStable,
            "Already using this intermediate"
        );
        intermediateStable = newIntermediate;
    }

    // - to Pause the contract
    function toggleContractActive() external onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() external onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}