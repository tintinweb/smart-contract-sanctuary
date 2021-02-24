/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

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
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract implements one click removal of liquidity from Uniswap V2 pools, receiving ETH, ERC tokens or both.

pragma solidity ^0.5.5;

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

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract UniswapV2_ZapOut_General_V3 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    bool public stopped = false;
    uint256 public goodwill;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;

    address
        private constant ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    IUniswapV2Router02 private constant uniswapV2Router = IUniswapV2Router02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    address private constant wethTokenAddress = address(
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit) public {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice Zap out in a pair of tokens
    @param _FromUniPoolAddress The uniswap pair address to zapout
    @param _IncomingLP The amount of LP
    @param affiliate Affiliate address
    @return the amount of pair tokens received after zapout
     */
    function ZapOut2PairToken(
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        address affiliate
    )
        public
        nonReentrant
        stopInEmergency
        returns (uint256 amountA, uint256 amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(_FromUniPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _IncomingLP
        );

        IERC20(_FromUniPoolAddress).safeApprove(
            address(uniswapV2Router),
            _IncomingLP
        );

        if (token0 == wethTokenAddress || token1 == wethTokenAddress) {
            address _token = token0 == wethTokenAddress ? token1 : token0;
            (amountA, amountB) = uniswapV2Router.removeLiquidityETH(
                _token,
                _IncomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill = _subtractGoodwill(
                _token,
                amountA,
                affiliate
            );
            uint256 ethGoodwill = _subtractGoodwill(
                ETHAddress,
                amountB,
                affiliate
            );

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA.sub(tokenGoodwill));
            Address.sendValue(msg.sender, amountB.sub(ethGoodwill));
        } else {
            (amountA, amountB) = uniswapV2Router.removeLiquidity(
                token0,
                token1,
                _IncomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill = _subtractGoodwill(
                token0,
                amountA,
                affiliate
            );
            uint256 tokenBGoodwill = _subtractGoodwill(
                token1,
                amountB,
                affiliate
            );

            // send tokens
            IERC20(token0).safeTransfer(
                msg.sender,
                amountA.sub(tokenAGoodwill)
            );
            IERC20(token1).safeTransfer(
                msg.sender,
                amountB.sub(tokenBGoodwill)
            );
        }
        emit zapOut(msg.sender, _FromUniPoolAddress, token0, amountA);
        emit zapOut(msg.sender, _FromUniPoolAddress, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param _ToTokenContractAddress The ERC20 token to zapout in (address(0x00) if ether)
    @param _FromUniPoolAddress The uniswap pair address to zapout from
    @param _IncomingLP The amount of LP to remove.
    @param _minTokensRec indicates the minimum amount of tokens to receive
    @param _swapTarget indicates the execution target for swap.
    @param swap1Data DEX swap data
    @param swap2Data DEX swap data
    @param affiliate Affiliate address 
    @return the amount of eth/tokens received after zapout
     */
    function ZapOut(
        address _ToTokenContractAddress,
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        uint256 _minTokensRec,
        address[] memory _swapTarget,
        bytes memory swap1Data,
        bytes memory swap2Data,
        address affiliate
    ) public nonReentrant stopInEmergency returns (uint256 tokenBought) {
        //transfer goodwill and reoves liquidity
        (uint256 amountA, uint256 amountB) = _removeLiquidity(
            _FromUniPoolAddress,
            _IncomingLP
        );

        //swaps tokens to token
        tokenBought = _swapTokens(
            _FromUniPoolAddress,
            amountA,
            amountB,
            _ToTokenContractAddress,
            _swapTarget,
            swap1Data,
            swap2Data
        );
        require(tokenBought >= _minTokensRec, "High slippage");

        emit zapOut(
            msg.sender,
            _FromUniPoolAddress,
            _ToTokenContractAddress,
            tokenBought
        );

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (_ToTokenContractAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokenBought,
                affiliate
            );

            msg.sender.transfer(tokenBought.sub(totalGoodwillPortion));
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                _ToTokenContractAddress,
                tokenBought,
                affiliate
            );

            IERC20(_ToTokenContractAddress).safeTransfer(
                msg.sender,
                tokenBought.sub(totalGoodwillPortion)
            );
        }

        return tokenBought.sub(totalGoodwillPortion);
    }

    /**
    @notice Zap out in a pair of tokens with permit
    @param _FromUniPoolAddress indicates the liquidity pool
    @param _IncomingLP indicates the amount of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @param _permitData indicates the encoded permit data, which contains owner, spender, value, deadline, v,r,s values. 
    @return  amountA - indicates the amount received in token0, amountB - indicates the amount received in token1 
    */
    function ZapOut2PairTokenWithPermit(
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        address affiliate,
        bytes calldata _permitData
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        // permit
        (bool success, ) = _FromUniPoolAddress.call(_permitData);
        require(success, "Could Not Permit");

        (amountA, amountB) = ZapOut2PairToken(
            _FromUniPoolAddress,
            _IncomingLP,
            affiliate
        );
    }

    /**
    @notice Zap out in a signle token with permit
    @param _ToTokenContractAddress indicates the toToken address to which tokens to convert.
    @param _FromUniPoolAddress indicates the liquidity pool
    @param _IncomingLP indicates the amount of LP to remove from pool
    @param _minTokensRec indicatest the minimum amount of toTokens to receive
    @param _permitData indicates the encoded permit data, which contains owner, spender, value, deadline, v,r,s values. 
    @param _swapTarget indicates the execution target for swap.
    @param swap1Data DEX swap data
    @param swap2Data DEX swap data
    @param affiliate Affiliate address to share fees
    */
    function ZapOutWithPermit(
        address _ToTokenContractAddress,
        address _FromUniPoolAddress,
        uint256 _IncomingLP,
        uint256 _minTokensRec,
        bytes memory _permitData,
        address[] memory _swapTarget,
        bytes memory swap1Data,
        bytes memory swap2Data,
        address affiliate
    ) public stopInEmergency returns (uint256) {
        // permit
        (bool success, ) = _FromUniPoolAddress.call(_permitData);
        require(success, "Could Not Permit");

        return (
            ZapOut(
                _ToTokenContractAddress,
                _FromUniPoolAddress,
                _IncomingLP,
                _minTokensRec,
                _swapTarget,
                swap1Data,
                swap2Data,
                affiliate
            )
        );
    }

    function _removeLiquidity(address _FromUniPoolAddress, uint256 _IncomingLP)
        internal
        returns (uint256 amountA, uint256 amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        //get pair tokens
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(_FromUniPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _IncomingLP
        );

        IERC20(_FromUniPoolAddress).safeApprove(
            address(uniswapV2Router),
            _IncomingLP
        );

        //remove liquidity
        (amountA, amountB) = uniswapV2Router.removeLiquidity(
            token0,
            token1,
            _IncomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amountA > 0 && amountB > 0, "Insufficient Liquidity");
    }

    function _swapTokens(
        address _FromUniPoolAddress,
        uint256 _amountA,
        uint256 _amountB,
        address _toToken,
        address[] memory _swapTarget,
        bytes memory swap1Data,
        bytes memory swap2Data
    ) internal returns (uint256 tokensBought) {
        require(_swapTarget.length == 2, "Invalid data for 0x swap");

        address token0 = IUniswapV2Pair(_FromUniPoolAddress).token0();
        address token1 = IUniswapV2Pair(_FromUniPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == _toToken) {
            tokensBought = tokensBought.add(_amountA);
        } else {
            //swap token using 0x swap
            tokensBought = tokensBought.add(
                _fillQuote(
                    token0,
                    _toToken,
                    _amountA,
                    _swapTarget[0],
                    swap1Data
                )
            );
        }

        //swap token1 to toToken
        if (token1 == _toToken) {
            tokensBought = tokensBought.add(_amountB);
        } else {
            //swap token using 0x swap
            tokensBought = tokensBought.add(
                _fillQuote(
                    token1,
                    _toToken,
                    _amountB,
                    _swapTarget[1],
                    swap2Data
                )
            );
        }
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            IERC20 fromToken = IERC20(_fromTokenAddress);
            fromToken.safeApprove(address(_swapTarget), 0);
            fromToken.safeApprove(address(_swapTarget), _amount);
        }

        uint256 initialBalance = _toToken == address(0)
            ? address(this).balance
            : IERC20(_toToken).balanceOf(address(this));

        (bool success, ) = _swapTarget.call.value(valueToSend)(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _toToken == address(0)
            ? (address(this).balance).sub(initialBalance)
            : IERC20(_toToken).balanceOf(address(this)).sub(initialBalance);

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
    @notice this method returns the amount of tokens received in underlying tokens after removal of liquidity.
    @param _FromUniPoolAddress indicates the liquidity pool.
    @param _tokenA indicates the tokenA of pool
    @param _tokenB indicates the tokenB of pool
    @param _liquidity indicates the amount of liquidity to remove.
    @return  amountA - indicates the amount removed in token0, amountB - indicates the amount removed in token1 
    */
    function removeLiquidityReturn(
        address _FromUniPoolAddress,
        address _tokenA,
        address _tokenB,
        uint256 _liquidity
    ) external view returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);

        (uint256 amount0, uint256 amount1) = _getBurnAmount(
            _FromUniPoolAddress,
            pair,
            _tokenA,
            _tokenB,
            _liquidity
        );

        (address token0, ) = _sortTokens(_tokenA, _tokenB);

        (amountA, amountB) = _tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);

        require(amountA >= 1, "UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= 1, "UniswapV2Router: INSUFFICIENT_B_AMOUNT");
    }

    function _sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    function _getBurnAmount(
        address _FromUniPoolAddress,
        IUniswapV2Pair pair,
        address _token0,
        address _token1,
        uint256 _liquidity
    ) internal view returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(_token0).balanceOf(_FromUniPoolAddress);
        uint256 balance1 = IERC20(_token1).balanceOf(_FromUniPoolAddress);

        uint256 _totalSupply = pair.totalSupply();

        amount0 = _liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"
        );
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (!whitelisted && goodwill > 0) {
            totalGoodwillPortion = SafeMath.div(
                SafeMath.mul(amount, goodwill),
                10000
            );

            if (affiliates[affiliate]) {
                uint256 affiliatePortion = totalGoodwillPortion
                    .mul(affiliateSplit)
                    .div(100);
                affiliateBalance[affiliate][token] = affiliateBalance[affiliate][token]
                    .add(affiliatePortion);
                totalAffiliateBalance[token] = totalAffiliateBalance[token].add(
                    affiliatePortion
                );
            }
        }
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
    }

    function ownerWithdrawTokens(address[] calldata tokens) external onlyOwner {
        // withdraw goodwill share + extra tokens if any sent
        // prevent owner from withdrawing affiliate share

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance.sub(
                    totalAffiliateBalance[tokens[i]]
                );
                Address.sendValue(Address.toPayable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this)).sub(
                    totalAffiliateBalance[tokens[i]]
                );
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]]
                .sub(tokenBal);

            if (tokens[i] == ETHAddress) {
                Address.sendValue(msg.sender, tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}