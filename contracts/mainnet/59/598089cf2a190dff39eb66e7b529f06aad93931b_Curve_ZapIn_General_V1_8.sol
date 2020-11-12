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

pragma solidity ^0.5.0;

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

interface ICurveExchange {
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external;
}

interface IPool3CurveExchange {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;
}

interface IrenBtcCurveExchange {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;
}

interface IhBtcCurveExchange {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external;
}

interface IsBtcCurveExchange {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
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

contract Curve_ZapIn_General_V1_8 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    bool public stopped = false;
    uint16 public goodwill;
    address
        public zgoodwillAddress = 0xE737b6AfEC2320f616297e59445b60a11e3eF75F;
    using SafeERC20 for IERC20;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    IUniswapRouter02 private constant uniswapRouter = IUniswapRouter02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address
        private constant DaiTokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address
        private constant UsdcTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address
        private constant UsdtTokenAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address
        private constant sUSDCurveExchangeAddress = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address
        private constant sUSDCurvePoolTokenAddress = 0xC25a3A3b969415c80451098fa907EC722572917F;

    address
        private constant yCurveExchangeAddress = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address
        private constant yCurvePoolTokenAddress = 0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8;

    address
        private constant bUSDCurveExchangeAddress = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    address
        private constant bUSDCurvePoolTokenAddress = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;

    address
        private constant paxCurveExchangeAddress = 0xA50cCc70b6a011CffDdf45057E39679379187287;
    address
        private constant paxCurvePoolTokenAddress = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;

    address
        private constant pool3CurveExchangeAddress = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address
        private constant pool3CurvePoolTokenAddress = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

    address
        private constant renBtcCurveExchangeAddress = 0x93054188d876f558f4a66B2EF1d97d16eDf0895B;
    address
        private constant renBtcCurvePoolTokenAddress = 0x49849C98ae39Fff122806C06791Fa73784FB3675;

    address
        private constant sBtcCurveExchangeAddress = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;
    address
        private constant sBtcCurvePoolTokenAddress = 0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;

    address
        private constant hBtcCurveExchangeAddress = 0x4CA9b3063Ec5866A4B82E437059D2C43d1be596F;
    address
        private constant hBtcCurvePoolTokenAddress = 0xb19059ebb43466C323583928285a49f558E572Fd;

    IBalancer private BalWBTCPool = IBalancer(
        0x1efF8aF5D577060BA4ac8A29A13525bb0Ee2A3D5
    );

    address
        private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address
        private constant wbtcTokenAddress = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address
        private constant renBtcTokenAddress = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address
        private constant sBtcTokenAddress = 0xfE18be6b3Bd88A2D2A7f928d00292E7a9963CfC6;
    address
        private constant hBtcTokenAddress = 0x0316EB71485b0Ab14103307bf65a021042c6d380;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    mapping(address => address) internal exchange2Token;

    constructor(uint16 _goodwill) public {
        goodwill = _goodwill;
        exchange2Token[sUSDCurveExchangeAddress] = sUSDCurvePoolTokenAddress;
        exchange2Token[yCurveExchangeAddress] = yCurvePoolTokenAddress;
        exchange2Token[bUSDCurveExchangeAddress] = bUSDCurvePoolTokenAddress;
        exchange2Token[paxCurveExchangeAddress] = paxCurvePoolTokenAddress;
        exchange2Token[pool3CurveExchangeAddress] = pool3CurvePoolTokenAddress;

        exchange2Token[renBtcCurveExchangeAddress] = renBtcCurvePoolTokenAddress;
        exchange2Token[sBtcCurveExchangeAddress] = sBtcCurvePoolTokenAddress;
        exchange2Token[hBtcCurveExchangeAddress] = hBtcCurvePoolTokenAddress;

        approveToken();
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function approveToken() public {
        // dai approvals
        IERC20(DaiTokenAddress).safeApprove(
            sUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(DaiTokenAddress).safeApprove(yCurveExchangeAddress, uint256(-1));
        IERC20(DaiTokenAddress).safeApprove(
            bUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(DaiTokenAddress).safeApprove(
            paxCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(DaiTokenAddress).safeApprove(
            pool3CurveExchangeAddress,
            uint256(-1)
        );

        // usdc approvals
        IERC20(UsdcTokenAddress).safeApprove(
            sUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdcTokenAddress).safeApprove(
            yCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdcTokenAddress).safeApprove(
            bUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdcTokenAddress).safeApprove(
            paxCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdcTokenAddress).safeApprove(
            pool3CurveExchangeAddress,
            uint256(-1)
        );

        // usdt approvals
        IERC20(UsdtTokenAddress).safeApprove(
            sUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdtTokenAddress).safeApprove(
            yCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdtTokenAddress).safeApprove(
            bUSDCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdtTokenAddress).safeApprove(
            paxCurveExchangeAddress,
            uint256(-1)
        );
        IERC20(UsdtTokenAddress).safeApprove(
            pool3CurveExchangeAddress,
            uint256(-1)
        );
    }

    function ZapIn(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty,
        uint256 _minPoolTokens
    ) public payable stopInEmergency returns (uint256 crvTokensBought) {
        require(
            _curvePoolExchangeAddress == sUSDCurveExchangeAddress ||
                _curvePoolExchangeAddress == yCurveExchangeAddress ||
                _curvePoolExchangeAddress == bUSDCurveExchangeAddress ||
                _curvePoolExchangeAddress == paxCurveExchangeAddress ||
                _curvePoolExchangeAddress == pool3CurveExchangeAddress ||
                _curvePoolExchangeAddress == renBtcCurveExchangeAddress ||
                _curvePoolExchangeAddress == sBtcCurveExchangeAddress ||
                _curvePoolExchangeAddress == hBtcCurveExchangeAddress,
            "Invalid Curve Pool Address"
        );

        if (_IncomingTokenAddress == address(0)) {
            crvTokensBought = ZapInWithETH(
                _toWhomToIssue,
                _curvePoolExchangeAddress,
                _minPoolTokens
            );
        } else {
            crvTokensBought = ZapInWithERC20(
                _toWhomToIssue,
                _IncomingTokenAddress,
                _curvePoolExchangeAddress,
                _IncomingTokenQty,
                _minPoolTokens
            );
        }
    }

    function ZapInWithETH(
        address _toWhomToIssue,
        address _curvePoolExchangeAddress,
        uint256 _minPoolTokens
    ) internal stopInEmergency returns (uint256 crvTokensBought) {
        require(msg.value > 0, "Err: No ETH sent");

        if (
            _curvePoolExchangeAddress != sBtcCurveExchangeAddress &&
            _curvePoolExchangeAddress != renBtcCurveExchangeAddress &&
            _curvePoolExchangeAddress != hBtcCurveExchangeAddress
        ) {
            uint256 daiBought = _eth2Token(DaiTokenAddress, (msg.value).div(2));
            uint256 usdcBought = _eth2Token(
                UsdcTokenAddress,
                (msg.value).div(2)
            );
            crvTokensBought = _enter2Curve(
                _toWhomToIssue,
                daiBought,
                usdcBought,
                0,
                _curvePoolExchangeAddress,
                _minPoolTokens
            );
        } else {
            uint256 wbtcBought = _eth2WBTC(msg.value, false);
            crvTokensBought = _enter2BtcCurve(
                _toWhomToIssue,
                wbtcTokenAddress,
                _curvePoolExchangeAddress,
                wbtcBought,
                _minPoolTokens
            );
        }
    }

    function ZapInWithERC20(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty,
        uint256 _minPoolTokens
    ) internal stopInEmergency returns (uint256 crvTokensBought) {
        require(_IncomingTokenQty > 0, "Err: No ERC20 sent");

        IERC20(_IncomingTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _IncomingTokenQty
        );

        if (
            _curvePoolExchangeAddress == sBtcCurveExchangeAddress ||
            _curvePoolExchangeAddress == renBtcCurveExchangeAddress ||
            _curvePoolExchangeAddress == hBtcCurveExchangeAddress
        ) {
            if (
                _IncomingTokenAddress == wbtcTokenAddress ||
                _IncomingTokenAddress == renBtcTokenAddress ||
                _IncomingTokenAddress == sBtcTokenAddress ||
                _IncomingTokenAddress == hBtcTokenAddress
            ) {
                crvTokensBought = _enter2BtcCurve(
                    _toWhomToIssue,
                    _IncomingTokenAddress,
                    _curvePoolExchangeAddress,
                    _IncomingTokenQty,
                    _minPoolTokens
                );
            } else {
                // token to weth (via uniswapV2)
                uint256 wethBought = _token2Token(
                    _IncomingTokenAddress,
                    wethTokenAddress,
                    _IncomingTokenQty
                );

                // weth to wbtc (via balancer)
                uint256 wbtcBought = _eth2WBTC(wethBought, true);

                // enter curve with wbtc
                crvTokensBought = _enter2BtcCurve(
                    _toWhomToIssue,
                    wbtcTokenAddress,
                    _curvePoolExchangeAddress,
                    wbtcBought,
                    _minPoolTokens
                );
            }
        } else {
            uint256 daiBought;
            uint256 usdcBought;
            uint256 usdtBought;

            if (_IncomingTokenAddress == DaiTokenAddress) {
                daiBought = _IncomingTokenQty;
            } else if (_IncomingTokenAddress == UsdcTokenAddress) {
                usdcBought = _IncomingTokenQty;
            } else if (_IncomingTokenAddress == UsdtTokenAddress) {
                usdtBought = _IncomingTokenQty;
            } else {
                daiBought = _token2Token(
                    _IncomingTokenAddress,
                    DaiTokenAddress,
                    (_IncomingTokenQty).div(2)
                );
                usdcBought = _token2Token(
                    _IncomingTokenAddress,
                    UsdcTokenAddress,
                    (_IncomingTokenQty).div(2)
                );
            }

            crvTokensBought = _enter2Curve(
                _toWhomToIssue,
                daiBought,
                usdcBought,
                usdtBought,
                _curvePoolExchangeAddress,
                _minPoolTokens
            );
        }
    }

    function _enter2BtcCurve(
        address _toWhomToIssue,
        address _incomingBtcTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _incomingBtcTokenAmt,
        uint256 _minPoolTokens
    ) internal returns (uint256 crvTokensBought) {
        require(
            _incomingBtcTokenAddress == sBtcTokenAddress ||
                _incomingBtcTokenAddress == wbtcTokenAddress ||
                _incomingBtcTokenAddress == renBtcTokenAddress ||
                _incomingBtcTokenAddress == hBtcTokenAddress,
            "ERR: Incorrect BTC Token Address"
        );

        IERC20(_incomingBtcTokenAddress).safeApprove(
            _curvePoolExchangeAddress,
            _incomingBtcTokenAmt
        );


            address btcCurvePoolTokenAddress
         = exchange2Token[_curvePoolExchangeAddress];
        uint256 iniTokenBal = IERC20(btcCurvePoolTokenAddress).balanceOf(
            address(this)
        );
        // 0 = renBTC/hBTC, 1 = wBTC, 2 = sBTC
        if (_incomingBtcTokenAddress == wbtcTokenAddress) {
            if (_curvePoolExchangeAddress == renBtcCurveExchangeAddress) {
                IrenBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                    [0, _incomingBtcTokenAmt],
                    _minPoolTokens
                );
            } else if (_curvePoolExchangeAddress == hBtcCurveExchangeAddress) {
                IhBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                    [0, _incomingBtcTokenAmt],
                    _minPoolTokens
                );
            } else {
                IsBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                    [0, _incomingBtcTokenAmt, 0],
                    _minPoolTokens
                );
            }
        } else if (_incomingBtcTokenAddress == renBtcTokenAddress) {
            if (_curvePoolExchangeAddress == renBtcCurveExchangeAddress) {
                IrenBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                    [_incomingBtcTokenAmt, 0],
                    _minPoolTokens
                );
            } else {
                IsBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                    [_incomingBtcTokenAmt, 0, 0],
                    _minPoolTokens
                );
            }
        } else if (_incomingBtcTokenAddress == hBtcTokenAddress) {
            IhBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                [_incomingBtcTokenAmt, 0],
                _minPoolTokens
            );
        } else {
            IsBtcCurveExchange(_curvePoolExchangeAddress).add_liquidity(
                [0, 0, _incomingBtcTokenAmt],
                0
            );
        }
        crvTokensBought = (
            IERC20(btcCurvePoolTokenAddress).balanceOf(address(this))
        )
            .sub(iniTokenBal);
        require(
            crvTokensBought > _minPoolTokens,
            "Error less than min pool tokens"
        );

        IERC20(btcCurvePoolTokenAddress).safeTransfer(
            _toWhomToIssue,
            crvTokensBought
        );
    }

    function _enter2Curve(
        address _toWhomToIssue,
        uint256 daiBought,
        uint256 usdcBought,
        uint256 usdtBought,
        address _curvePoolExchangeAddress,
        uint256 _minPoolTokens
    ) internal returns (uint256 crvTokensBought) {
        // 0 = DAI, 1 = USDC, 2 = USDT, 3 = TUSD/sUSD
        address poolTokenAddress = exchange2Token[_curvePoolExchangeAddress];
        uint256 iniTokenBal = IERC20(poolTokenAddress).balanceOf(address(this));

        if (_curvePoolExchangeAddress == pool3CurveExchangeAddress) {
            IPool3CurveExchange(_curvePoolExchangeAddress).add_liquidity(
                [daiBought, usdcBought, usdtBought],
                _minPoolTokens
            );
        } else {
            ICurveExchange(_curvePoolExchangeAddress).add_liquidity(
                [daiBought, usdcBought, usdtBought, 0],
                _minPoolTokens
            );
        }

        crvTokensBought = (IERC20(poolTokenAddress).balanceOf(address(this)))
            .sub(iniTokenBal);
        require(
            crvTokensBought > _minPoolTokens,
            "Error less than min pool tokens"
        );

        uint256 goodwillPortion = SafeMath.div(
            SafeMath.mul(crvTokensBought, goodwill),
            10000
        );

        IERC20(poolTokenAddress).safeTransfer(
            zgoodwillAddress,
            goodwillPortion
        );

        IERC20(poolTokenAddress).safeTransfer(
            _toWhomToIssue,
            SafeMath.sub(crvTokensBought, goodwillPortion)
        );
    }

    function _eth2WBTC(uint256 ethReceived, bool fromWeth)
        internal
        returns (uint256 tokensBought)
    {
        if (!fromWeth) IWETH(wethTokenAddress).deposit.value(ethReceived)();

        IERC20(wethTokenAddress).safeApprove(address(BalWBTCPool), ethReceived);

        (tokensBought, ) = BalWBTCPool.swapExactAmountIn(
            wethTokenAddress,
            ethReceived,
            wbtcTokenAddress,
            0,
            uint256(-1)
        );
    }

    function _eth2Token(address _tokenContractAddress, uint256 ethReceived)
        internal
        returns (uint256 tokensBought)
    {
        require(
            _tokenContractAddress != wethTokenAddress,
            "ERR: Invalid Swap to ETH"
        );

        address[] memory path = new address[](2);
        path[0] = wethTokenAddress;
        path[1] = _tokenContractAddress;
        tokensBought = uniswapRouter.swapExactETHForTokens.value(ethReceived)(
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];
    }

    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        IERC20(_FromTokenContractAddress).safeApprove(
            address(uniswapRouter),
            tokens2Trade
        );

        if (_FromTokenContractAddress != wethTokenAddress) {
            if (_ToTokenContractAddress != wethTokenAddress) {
                address[] memory path = new address[](3);
                path[0] = _FromTokenContractAddress;
                path[1] = wethTokenAddress;
                path[2] = _ToTokenContractAddress;
                tokenBought = uniswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            } else {
                address[] memory path = new address[](2);
                path[0] = _FromTokenContractAddress;
                path[1] = wethTokenAddress;

                tokenBought = uniswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    address(this),
                    deadline
                )[path.length - 1];
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(
                tokens2Trade,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        }
    }

    function setNewBalWBTCPool(address _newBalWBTCPool) public onlyOwner {
        require(
            _newBalWBTCPool != address(0) &&
                _newBalWBTCPool != address(BalWBTCPool),
            "Invalid Pool"
        );
        BalWBTCPool = IBalancer(_newBalWBTCPool);
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        IERC20(_TokenAddress).safeTransfer(_owner, qty);
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill < 10000,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_new_zgoodwillAddress(address _new_zgoodwillAddress)
        public
        onlyOwner
    {
        zgoodwillAddress = _new_zgoodwillAddress;
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function() external payable {}
}