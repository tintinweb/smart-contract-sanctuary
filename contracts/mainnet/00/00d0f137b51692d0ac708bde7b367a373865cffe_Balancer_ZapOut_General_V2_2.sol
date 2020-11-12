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
///@notice This contract adds removes liquidity from Balancer Pools into ETH/ERC/Underlying Tokens.
// SPDX-License-Identifier: GPLv2

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

// File: contracts/Balancer/Balancer_ZapOut_General_V2_2.sol

pragma solidity ^0.5.12;

interface IBFactory_Balancer_Unzap_V1_1 {
    function isBPool(address b) external view returns (bool);
}

interface IBPool_Balancer_Unzap_V1_1 {
    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external payable returns (uint256 tokenAmountOut);

    function totalSupply() external view returns (uint256);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isBound(address t) external view returns (bool);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function getBalance(address token) external view returns (uint256);
}

interface IuniswapFactory_Balancer_Unzap_V1_1 {
    function getExchange(address token)
        external
        view
        returns (address exchange);
}

interface Iuniswap_Balancer_Unzap_V1_1 {
    // converting ERC20 to ERC20 and transfer
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);

    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);

    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);

    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

library TransferHelper {
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
            "TransferHelper: APPROVE_FAILED"
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
            "TransferHelper: TRANSFER_FAILED"
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
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
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

contract Balancer_ZapOut_General_V2_2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    bool private stopped = false;
    uint16 public goodwill;
    address
        private constant zgoodwillAddress = 0xE737b6AfEC2320f616297e59445b60a11e3eF75F;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    IUniswapRouter02 private constant uniswapRouter = IUniswapRouter02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    IBFactory_Balancer_Unzap_V1_1
        private constant BalancerFactory = IBFactory_Balancer_Unzap_V1_1(
        0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
    );

    address
        private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    event Zapout(
        address _toWhomToIssue,
        address _fromBalancerPoolAddress,
        address _toTokenContractAddress,
        uint256 _OutgoingAmount
    );

    constructor(uint16 _goodwill) public {
        goodwill = _goodwill;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
    @notice This function is used for zapping out of balancer pools
    @param _ToTokenContractAddress The token in which we want zapout (for ethers, its zero address)
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _IncomingBPT The quantity of balancer pool tokens
    @param _minTokensRec slippage user wants
    @return success or failure
    */
    function EasyZapOut(
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        uint256 _minTokensRec
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        require(
            BalancerFactory.isBPool(_FromBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        address _FromTokenAddress;
        if (
            IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            )
        ) {
            _FromTokenAddress = _ToTokenContractAddress;
        } else if (
            _ToTokenContractAddress == address(0) &&
            IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress).isBound(
                wethTokenAddress
            )
        ) {
            _FromTokenAddress = wethTokenAddress;
        } else {
            _FromTokenAddress = _getBestDeal(
                _FromBalancerPoolAddress,
                _IncomingBPT
            );
        }
        return (
            _performZapOut(
                msg.sender,
                _ToTokenContractAddress,
                _FromBalancerPoolAddress,
                _IncomingBPT,
                _FromTokenAddress,
                _minTokensRec
            )
        );
    }

    /**
    @notice This method is called by ZapOut and EasyZapOut()
    @param _toWhomToIssue is the address of user
    @param _ToTokenContractAddress is the address of the token to which you want to convert to
    @param _FromBalancerPoolAddress the address of the Balancer Pool from which you want to ZapOut
    @param _IncomingBPT is the quantity of Balancer Pool tokens that the user wants to ZapOut
    @param _IntermediateToken is the token to which the Balancer Pool should be Zapped Out
    @notice this is only used if the outgoing token is not amongst the Balancer Pool tokens
    @return success or failure
    */
    function _performZapOut(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _IntermediateToken,
        uint256 _minTokensRec
    ) internal returns (uint256) {
        //transfer goodwill
        uint256 goodwillPortion = _transferGoodwill(
            _FromBalancerPoolAddress,
            _IncomingBPT
        );

        require(
            IERC20(_FromBalancerPoolAddress).transferFrom(
                msg.sender,
                address(this),
                SafeMath.sub(_IncomingBPT, goodwillPortion)
            )
        );

        if (
            IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            )
        ) {
            return (
                _directZapout(
                    _FromBalancerPoolAddress,
                    _ToTokenContractAddress,
                    _toWhomToIssue,
                    SafeMath.sub(_IncomingBPT, goodwillPortion),
                    _minTokensRec
                )
            );
        }

        //exit balancer
        uint256 _returnedTokens = _exitBalancer(
            _FromBalancerPoolAddress,
            _IntermediateToken,
            SafeMath.sub(_IncomingBPT, goodwillPortion)
        );

        if (_ToTokenContractAddress == address(0)) {
            uint256 ethBought = _token2Eth(
                _IntermediateToken,
                _returnedTokens,
                _toWhomToIssue
            );

            require(ethBought >= _minTokensRec, "High slippage");
            emit Zapout(
                _toWhomToIssue,
                _FromBalancerPoolAddress,
                _ToTokenContractAddress,
                ethBought
            );
            return ethBought;
        } else {
            uint256 tokenBought = _token2Token(
                _IntermediateToken,
                _toWhomToIssue,
                _ToTokenContractAddress,
                _returnedTokens
            );
            require(tokenBought >= _minTokensRec, "High slippage");

            emit Zapout(
                _toWhomToIssue,
                _FromBalancerPoolAddress,
                _ToTokenContractAddress,
                tokenBought
            );
            return tokenBought;
        }
    }

    /**
    @notice This function is used for zapping out of balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _ToTokenContractAddress The token in which we want to zapout (for ethers, its zero address)
    @param _toWhomToIssue The address of user
    @param tokens2Trade The quantity of balancer pool tokens
    @return success or failure
    */
    function _directZapout(
        address _FromBalancerPoolAddress,
        address _ToTokenContractAddress,
        address _toWhomToIssue,
        uint256 tokens2Trade,
        uint256 _minTokensRec
    ) internal returns (uint256 returnedTokens) {
        returnedTokens = _exitBalancer(
            _FromBalancerPoolAddress,
            _ToTokenContractAddress,
            tokens2Trade
        );

        require(returnedTokens >= _minTokensRec, "High slippage");

        emit Zapout(
            _toWhomToIssue,
            _FromBalancerPoolAddress,
            _ToTokenContractAddress,
            returnedTokens
        );

        IERC20(_ToTokenContractAddress).transfer(
            _toWhomToIssue,
            returnedTokens
        );
    }

    /**
    @notice This function is used to calculate and transfer goodwill
    @param _tokenContractAddress Token address in which goodwill is deducted
    @param tokens2Trade The total amount of tokens to be zapped out
    @return The amount of goodwill deducted
    */
    function _transferGoodwill(
        address _tokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 goodwillPortion) {
        if (goodwill == 0) {
            return 0;
        }

        goodwillPortion = SafeMath.div(
            SafeMath.mul(tokens2Trade, goodwill),
            10000
        );

        require(
            IERC20(_tokenContractAddress).transferFrom(
                msg.sender,
                zgoodwillAddress,
                goodwillPortion
            ),
            "Error in transferring BPT:1"
        );
        return goodwillPortion;
    }

    /**
    @notice This function finds best token from the final tokens of balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _IncomingBPT The amount of balancer pool token to covert
    @return The token address having max liquidity
     */
    function _getBestDeal(
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT
    ) internal view returns (address _token) {
        //get token list
        address[] memory tokens = IBPool_Balancer_Unzap_V1_1(
            _FromBalancerPoolAddress
        )
            .getFinalTokens();

        uint256 maxEth;

        for (uint256 index = 0; index < tokens.length; index++) {
            //get token for given bpt amount
            uint256 tokensForBPT = _getBPT2Token(
                _FromBalancerPoolAddress,
                _IncomingBPT,
                tokens[index]
            );

            //get eth value for each token
            if (tokens[index] != wethTokenAddress) {
                if (
                    UniSwapV2FactoryAddress.getPair(
                        tokens[index],
                        wethTokenAddress
                    ) == address(0)
                ) {
                    continue;
                }

                address[] memory path = new address[](2);
                path[0] = tokens[index];
                path[1] = wethTokenAddress;
                uint256 ethReturned = uniswapRouter.getAmountsOut(
                    tokensForBPT,
                    path
                )[1];

                //get max eth value
                if (maxEth < ethReturned) {
                    maxEth = ethReturned;
                    _token = tokens[index];
                }
            } else {
                //get max eth value
                if (maxEth < tokensForBPT) {
                    maxEth = tokensForBPT;
                    _token = tokens[index];
                }
            }
        }
    }

    /**
    @notice This function gives the amount of tokens on zapping out from given BPool
    @param _FromBalancerPoolAddress Address of balancer pool to zapout from
    @param _IncomingBPT The amount of BPT to zapout
    @param _toToken Address of token to zap out with
    @return Amount of ERC token
     */
    function _getBPT2Token(
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _toToken
    ) internal view returns (uint256 tokensReturned) {
        uint256 totalSupply = IBPool_Balancer_Unzap_V1_1(
            _FromBalancerPoolAddress
        )
            .totalSupply();
        uint256 swapFee = IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress)
            .getSwapFee();
        uint256 totalWeight = IBPool_Balancer_Unzap_V1_1(
            _FromBalancerPoolAddress
        )
            .getTotalDenormalizedWeight();
        uint256 balance = IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress)
            .getBalance(_toToken);
        uint256 denorm = IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress)
            .getDenormalizedWeight(_toToken);

        tokensReturned = IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress)
            .calcSingleOutGivenPoolIn(
            balance,
            denorm,
            totalSupply,
            totalWeight,
            _IncomingBPT,
            swapFee
        );
    }

    /**
    @notice This function is used to zap out of the given balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _ToTokenContractAddress The Token address which will be zapped out
    @param _amount The amount of token for zapout
    @return The amount of tokens received after zap out
     */
    function _exitBalancer(
        address _FromBalancerPoolAddress,
        address _ToTokenContractAddress,
        uint256 _amount
    ) internal returns (uint256 returnedTokens) {
        require(
            IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress).isBound(
                _ToTokenContractAddress
            ),
            "Token not bound"
        );

        uint256 minTokens = _getBPT2Token(
            _FromBalancerPoolAddress,
            _amount,
            _ToTokenContractAddress
        );
        minTokens = SafeMath.div(SafeMath.mul(minTokens, 98), 100);

        returnedTokens = IBPool_Balancer_Unzap_V1_1(_FromBalancerPoolAddress)
            .exitswapPoolAmountIn(_ToTokenContractAddress, _amount, minTokens);

        require(returnedTokens > 0, "Error in exiting balancer pool");
    }

    /**
    @notice This function is used to swap tokens
    @param _FromTokenContractAddress The token address to swap from
    @param _ToWhomToIssue The address to transfer after swap
    @param _ToTokenContractAddress The token address to swap to
    @param tokens2Trade The quantity of tokens to swap
    @return The amount of tokens returned after swap
     */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToWhomToIssue,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        TransferHelper.safeApprove(
            _FromTokenContractAddress,
            address(uniswapRouter),
            tokens2Trade
        );

        if (_FromTokenContractAddress != wethTokenAddress) {
            address[] memory path = new address[](3);
            path[0] = _FromTokenContractAddress;
            path[1] = wethTokenAddress;
            path[2] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(
                tokens2Trade,
                1,
                path,
                _ToWhomToIssue,
                deadline
            )[path.length - 1];
        } else {
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(
                tokens2Trade,
                1,
                path,
                _ToWhomToIssue,
                deadline
            )[path.length - 1];
        }

        require(tokenBought > 0, "Error in swapping ERC: 1");
    }

    /**
    @notice This function is used to swap tokens to eth
    @param _FromTokenContractAddress The token address to swap from
    @param tokens2Trade The quantity of tokens to swap
    @param _toWhomToIssue The address to transfer after swap
    @return The amount of ether returned after swap
     */
    function _token2Eth(
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        address payable _toWhomToIssue
    ) internal returns (uint256 ethBought) {
        if (_FromTokenContractAddress == wethTokenAddress) {
            IWETH(wethTokenAddress).withdraw(tokens2Trade);
            _toWhomToIssue.transfer(tokens2Trade);
            return tokens2Trade;
        }

        IERC20(_FromTokenContractAddress).approve(
            address(uniswapRouter),
            tokens2Trade
        );

        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = wethTokenAddress;
        ethBought = uniswapRouter.swapExactTokensForETH(
            tokens2Trade,
            1,
            path,
            _toWhomToIssue,
            deadline
        )[path.length - 1];

        require(ethBought > 0, "Error in swapping Eth: 1");
    }

    function set_new_goodwill(uint16 _new_goodwill) public onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill < 10000,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner(), qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = owner().toPayable();
        _to.transfer(contractBalance);
    }

    function() external payable {}
}