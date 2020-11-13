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
///@notice this contract swaps between two assets utilizing various liquidity pools.

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/ownership/Ownable.sol

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
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

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
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

interface IBFactory {
    function isBPool(address b) external view returns (bool);
}

interface IBpool {
    function isPublicSwap() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function getSpotPrice(address tokenIn, address tokenOut)
        external
        view
        returns (uint256 spotPrice);
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

interface ICurve {
    function underlying_coins(int128 index) external view returns (address);

    function coins(int128 index) external view returns (address);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface ICompound {
    function markets(address cToken)
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);

    function underlying() external returns (address);
}

interface ICompoundToken {
    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface ICompoundEther {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);
}

interface IIearn {
    function token() external view returns (address);

    function calcPoolValueInToken() external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}

interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

interface IAaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getLendingPoolCore() external view returns (address payable);
}

interface IAaveLendingPool {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;
}

contract Zapper_Swap_General_V1_3 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    IUniswapRouter02 private constant uniswapRouter = IUniswapRouter02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider = IAaveLendingPoolAddressesProvider(
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
    );

    IBFactory private constant BalancerFactory = IBFactory(
        0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
    );

    address private constant renBTCCurveSwapContract = address(
        0x93054188d876f558f4a66B2EF1d97d16eDf0895B
    );

    address private constant sBTCCurveSwapContract = address(
        0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714
    );

    IWETH private constant wethContract = IWETH(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    address private constant ETHAddress = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    mapping(address => address) public cToken;
    mapping(address => address) public yToken;
    mapping(address => address) public aToken;

    bool public stopped = false;

    constructor() public {
        //mapping for cETH
        cToken[address(
            0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5
        )] = ETHAddress;
    }

    /**
	@notice This function adds c token addresses to a mapping
	@dev For cETH token, mapping is already added in constructor
    @param _cToken token address of c-token for given underlying asset
		 */
    function addCToken(address[] memory _cToken) public onlyOwner {
        for (uint256 i = 0; i < _cToken.length; i++) {
            cToken[_cToken[i]] = ICompound(_cToken[i]).underlying();
        }
    }

    /**
	@notice This function adds y token addresses to a mapping
    @param _yToken token address of y-token
		*/
    function addYToken(address[] memory _yToken) public onlyOwner {
        for (uint256 i = 0; i < _yToken.length; i++) {
            yToken[_yToken[i]] = IIearn(_yToken[i]).token();
        }
    }

    /**
	@notice This function adds a token addresses to a mapping
    @param _aToken token address of a-token for given underlying asset
		 */
    function addAToken(address[] memory _aToken) public onlyOwner {
        for (uint256 i = 0; i < _aToken.length; i++) {
            aToken[_aToken[i]] = IAToken(_aToken[i]).underlyingAssetAddress();
        }
    }

    /**
    @notice This function is used swap tokens using multiple exchanges
    @param toWhomToIssue address to which tokens should be sent after swap
	@param path token addresses indicating the conversion path
	@param amountIn amount of tokens to swap
    @param minTokenOut min amount of expected tokens
    @param withPool indicates the exchange and its sequence we want to swap from
    @param poolData pool or token addresses needed for swapping tokens according to the exchange
	@param starts indicates the index of path array for each swap
    @return amount of tokens received after swap
     */
    function MultiExchangeSwap(
        address payable toWhomToIssue,
        address[] calldata path,
        uint256 amountIn,
        uint256 minTokenOut,
        uint8[] calldata starts,
        uint8[] calldata withPool,
        address[] calldata poolData
    )
        external
        payable
        nonReentrant
        stopInEmergency
        returns (uint256 tokensBought)
    {
        require(toWhomToIssue != address(0), "Invalid receiver address");
        require(path[0] != path[path.length - 1], "Cannot swap same tokens");

        tokensBought = _swap(
            path,
            _getTokens(path[0], amountIn),
            starts,
            withPool,
            poolData
        );

        require(tokensBought >= minTokenOut, "High Slippage");
        _sendTokens(toWhomToIssue, path[path.length - 1], tokensBought);
    }

    //swap function
    function _swap(
        address[] memory path,
        uint256 tokensToSwap,
        uint8[] memory starts,
        uint8[] memory withPool,
        address[] memory poolData
    ) internal returns (uint256) {
        address _to;
        uint8 poolIndex = 0;
        address[] memory _poolData;
        address _from = path[starts[0]];

        for (uint256 index = 0; index < withPool.length; index++) {
            uint256 endIndex = index == withPool.length.sub(1)
                ? path.length - 1
                : starts[index + 1];

            _to = path[endIndex];

            {
                if (withPool[index] == 2) {
                    _poolData = _getPath(path, starts[index], endIndex + 1);
                } else {
                    _poolData = new address[](1);
                    _poolData[0] = poolData[poolIndex++];
                }
            }

            tokensToSwap = _swapFromPool(
                _from,
                _to,
                tokensToSwap,
                withPool[index],
                _poolData
            );

            _from = _to;
        }
        return tokensToSwap;
    }

    /**
    @notice This function is used swap tokens using multiple exchanges
    @param fromToken token addresses to swap from
	@param toToken token addresses to swap into
	@param amountIn amount of tokens to swap
    @param withPool indicates the exchange we want to swap from
    @param poolData pool or token addresses needed for swapping tokens according to the exchange
	@return amount of tokens received after swap
     */
    function _swapFromPool(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 withPool,
        address[] memory poolData
    ) internal returns (uint256) {
        require(fromToken != toToken, "Cannot swap same tokens");
        require(withPool <= 3, "Invalid Exchange");

        if (withPool == 1) {
            return
                _swapWithBalancer(poolData[0], fromToken, toToken, amountIn, 1);
        } else if (withPool == 2) {
            return
                _swapWithUniswapV2(fromToken, toToken, poolData, amountIn, 1);
        } else if (withPool == 3) {
            return _swapWithCurve(poolData[0], fromToken, toToken, amountIn, 1);
        }
    }

    /**
	@notice This function returns part of the given array 
    @param addresses address array to copy from
	@param _start start index
	@param _end end index
    @return addressArray copied from given array
		 */
    function _getPath(
        address[] memory addresses,
        uint256 _start,
        uint256 _end
    ) internal pure returns (address[] memory addressArray) {
        uint256 len = _end.sub(_start);
        require(len > 1, "ERR_UNIV2_PATH");
        addressArray = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            if (
                addresses[_start + i] == address(0) ||
                addresses[_start + i] == ETHAddress
            ) {
                addressArray[i] = address(wethContract);
            } else {
                addressArray[i] = addresses[_start + i];
            }
        }
    }

    function _sendTokens(
        address payable toWhomToIssue,
        address token,
        uint256 amount
    ) internal {
        if (token == ETHAddress || token == address(0)) {
            toWhomToIssue.transfer(amount);
        } else {
            IERC20(token).safeTransfer(toWhomToIssue, amount);
        }
    }

    function _swapWithBalancer(
        address bpoolAddress,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minTokenOut
    ) internal returns (uint256 tokenBought) {
        require(BalancerFactory.isBPool(bpoolAddress), "Invalid balancer pool");

        IBpool bpool = IBpool(bpoolAddress);
        require(bpool.isPublicSwap(), "Swap not allowed for this pool");

        address _to = toToken;
        if (fromToken == address(0)) {
            wethContract.deposit.value(amountIn)();
            fromToken = address(wethContract);
        } else if (toToken == address(0)) {
            _to = address(wethContract);
        }
        require(bpool.isBound(fromToken), "From Token not bound");
        require(bpool.isBound(_to), "To Token not bound");

        //approve it to exchange address
        IERC20(fromToken).safeApprove(bpoolAddress, amountIn);

        //swap tokens
        (tokenBought, ) = bpool.swapExactAmountIn(
            fromToken,
            amountIn,
            _to,
            minTokenOut,
            uint256(-1)
        );

        if (toToken == address(0)) {
            wethContract.withdraw(tokenBought);
        }
    }

    function _swapWithUniswapV2(
        address fromToken,
        address toToken,
        address[] memory path,
        uint256 amountIn,
        uint256 minTokenOut
    ) internal returns (uint256 tokenBought) {
        //unwrap & approve it to router contract
        uint256 tokensUnwrapped = amountIn;
        address _fromToken = fromToken;
        if (fromToken != address(0)) {
            (tokensUnwrapped, _fromToken) = _unwrap(fromToken, amountIn);
            IERC20(_fromToken).safeApprove(
                address(uniswapRouter),
                tokensUnwrapped
            );
        }

        //swap and transfer tokens
        if (fromToken == address(0)) {
            tokenBought = uniswapRouter.swapExactETHForTokens.value(
                tokensUnwrapped
            )(minTokenOut, path, address(this), deadline)[path.length - 1];
        } else if (toToken == address(0)) {
            tokenBought = uniswapRouter.swapExactTokensForETH(
                tokensUnwrapped,
                minTokenOut,
                path,
                address(this),
                deadline
            )[path.length - 1];
        } else {
            tokenBought = uniswapRouter.swapExactTokensForTokens(
                tokensUnwrapped,
                minTokenOut,
                path,
                address(this),
                deadline
            )[path.length - 1];
        }
    }

    function _swapWithCurve(
        address curveExchangeAddress,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 minTokenOut
    ) internal returns (uint256 tokenBought) {
        require(
            curveExchangeAddress != address(0),
            "ERR_Invaid_curve_exchange"
        );
        ICurve curveExchange = ICurve(curveExchangeAddress);

        (uint256 tokensUnwrapped, address _fromToken) = _unwrap(
            fromToken,
            amountIn
        );

        //approve it to exchange address
        IERC20(_fromToken).safeApprove(curveExchangeAddress, tokensUnwrapped);

        int128 i;
        int128 j;

        //swap tokens
        if (
            curveExchangeAddress == renBTCCurveSwapContract ||
            curveExchangeAddress == sBTCCurveSwapContract
        ) {
            int128 length = (curveExchangeAddress == renBTCCurveSwapContract)
                ? 2
                : 3;

            for (int128 index = 0; index < length; index++) {
                if (curveExchange.coins(index) == _fromToken) {
                    i = index;
                } else if (curveExchange.coins(index) == toToken) {
                    j = index;
                }
            }

            curveExchange.exchange(i, j, tokensUnwrapped, minTokenOut);
        } else {
            address compCurveSwapContract = address(
                0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56
            );
            address usdtCurveSwapContract = address(
                0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C
            );

            int128 length = 4;
            if (curveExchangeAddress == compCurveSwapContract) {
                length = 2;
            } else if (curveExchangeAddress == usdtCurveSwapContract) {
                length = 3;
            }

            for (int128 index = 0; index < length; index++) {
                if (curveExchange.underlying_coins(index) == _fromToken) {
                    i = index;
                } else if (curveExchange.underlying_coins(index) == toToken) {
                    j = index;
                }
            }

            curveExchange.exchange_underlying(
                i,
                j,
                tokensUnwrapped,
                minTokenOut
            );
        }

        if (toToken == ETHAddress || toToken == address(0)) {
            tokenBought = address(this).balance;
        } else {
            tokenBought = IERC20(toToken).balanceOf(address(this));
        }
    }

    function unwrapWeth(
        address payable _toWhomToIssue,
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        uint256 minTokens
    )
        public
        stopInEmergency
        returns (uint256 tokensUnwrapped, address toToken)
    {
        require(_toWhomToIssue != address(0), "Invalid receiver address");
        require(
            _FromTokenContractAddress == address(wethContract),
            "Only unwraps WETH, use unwrap() for other tokens"
        );

        uint256 initialEthbalance = address(this).balance;

        uint256 tokensToSwap = _getTokens(
            _FromTokenContractAddress,
            tokens2Trade
        );

        wethContract.withdraw(tokensToSwap);
        tokensUnwrapped = address(this).balance.sub(initialEthbalance);
        toToken = address(0);

        require(tokensUnwrapped >= minTokens, "High Slippage");

        //transfer
        _sendTokens(_toWhomToIssue, toToken, tokensUnwrapped);
    }

    function unwrap(
        address payable _toWhomToIssue,
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        uint256 minTokens
    )
        public
        stopInEmergency
        returns (uint256 tokensUnwrapped, address toToken)
    {
        require(_toWhomToIssue != address(0), "Invalid receiver address");
        uint256 tokensToSwap = _getTokens(
            _FromTokenContractAddress,
            tokens2Trade
        );

        (tokensUnwrapped, toToken) = _unwrap(
            _FromTokenContractAddress,
            tokensToSwap
        );

        require(tokensUnwrapped >= minTokens, "High Slippage");

        //transfer
        _sendTokens(_toWhomToIssue, toToken, tokensUnwrapped);
    }

    function _unwrap(address _FromTokenContractAddress, uint256 tokens2Trade)
        internal
        returns (uint256 tokensUnwrapped, address toToken)
    {
        uint256 initialEthbalance = address(this).balance;

        if (cToken[_FromTokenContractAddress] != address(0)) {
            require(
                ICompoundToken(_FromTokenContractAddress).redeem(
                    tokens2Trade
                ) == 0,
                "Error in unwrapping"
            );
            toToken = cToken[_FromTokenContractAddress];
            if (toToken == ETHAddress) {
                tokensUnwrapped = address(this).balance;
                tokensUnwrapped = tokensUnwrapped.sub(initialEthbalance);
            } else {
                tokensUnwrapped = IERC20(toToken).balanceOf(address(this));
            }
        } else if (yToken[_FromTokenContractAddress] != address(0)) {
            IIearn(_FromTokenContractAddress).withdraw(tokens2Trade);
            toToken = IIearn(_FromTokenContractAddress).token();
            tokensUnwrapped = IERC20(toToken).balanceOf(address(this));
        } else if (aToken[_FromTokenContractAddress] != address(0)) {
            IAToken(_FromTokenContractAddress).redeem(tokens2Trade);
            toToken = IAToken(_FromTokenContractAddress)
                .underlyingAssetAddress();
            if (toToken == ETHAddress) {
                tokensUnwrapped = address(this).balance;
                tokensUnwrapped = tokensUnwrapped.sub(initialEthbalance);
            } else {
                tokensUnwrapped = IERC20(toToken).balanceOf(address(this));
            }
        } else {
            toToken = _FromTokenContractAddress;
            tokensUnwrapped = tokens2Trade;
        }
    }

    function wrap(
        address payable _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade,
        uint256 minTokens,
        uint256 _wrapInto
    ) public payable stopInEmergency returns (uint256 tokensWrapped) {
        require(_toWhomToIssue != address(0), "Invalid receiver address");
        require(_wrapInto <= 3, "Invalid to Token");
        uint256 tokensToSwap = _getTokens(
            _FromTokenContractAddress,
            tokens2Trade
        );

        tokensWrapped = _wrap(
            _FromTokenContractAddress,
            _ToTokenContractAddress,
            tokensToSwap,
            _wrapInto
        );

        require(tokensWrapped >= minTokens, "High Slippage");

        //transfer tokens
        _sendTokens(_toWhomToIssue, _ToTokenContractAddress, tokensWrapped);
    }

    function _wrap(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade,
        uint256 _wrapInto
    ) internal returns (uint256 tokensWrapped) {
        //weth
        if (_wrapInto == 0) {
            require(
                _FromTokenContractAddress == address(0),
                "Cannot wrap into WETH"
            );
            require(
                _ToTokenContractAddress == address(wethContract),
                "Invalid toToken"
            );

            wethContract.deposit.value(tokens2Trade)();
            return tokens2Trade;
        } else if (_wrapInto == 1) {
            //Compound
            if (_FromTokenContractAddress == address(0)) {
                ICompoundEther(_ToTokenContractAddress).mint.value(
                    tokens2Trade
                )();
            } else {
                IERC20(_FromTokenContractAddress).safeApprove(
                    address(_ToTokenContractAddress),
                    tokens2Trade
                );
                ICompoundToken(_ToTokenContractAddress).mint(tokens2Trade);
            }
        } else if (_wrapInto == 2) {
            //IEarn
            IERC20(_FromTokenContractAddress).safeApprove(
                address(_ToTokenContractAddress),
                tokens2Trade
            );
            IIearn(_ToTokenContractAddress).deposit(tokens2Trade);
        } else {
            // Aave
            if (_FromTokenContractAddress == address(0)) {
                IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                    .deposit
                    .value(tokens2Trade)(ETHAddress, tokens2Trade, 0);
            } else {
                //approve lending pool core
                IERC20(_FromTokenContractAddress).safeApprove(
                    address(lendingPoolAddressProvider.getLendingPoolCore()),
                    tokens2Trade
                );

                //get lending pool and call deposit
                IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                    .deposit(_FromTokenContractAddress, tokens2Trade, 0);
            }
        }
        tokensWrapped = IERC20(_ToTokenContractAddress).balanceOf(
            address(this)
        );
    }

    function _getTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            return msg.value;
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.safeTransfer(owner(), qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}