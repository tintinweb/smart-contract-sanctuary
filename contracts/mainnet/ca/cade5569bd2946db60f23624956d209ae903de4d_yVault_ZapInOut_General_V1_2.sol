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
///@notice This contract adds/removes liquidity to/from yEarn Vaults using ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol

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
     *
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
     *
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
     *
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
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
}

// File: yVault_ZapInOut_General_V1_2.sol

pragma solidity ^0.6.0;

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

interface yVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);
}

interface ICurveZapInGeneral {
    function ZapIn(
        address _toWhomToIssue,
        address _IncomingTokenAddress,
        address _curvePoolExchangeAddress,
        uint256 _IncomingTokenQty,
        uint256 _minPoolTokens
    ) external payable returns (uint256 crvTokensBought);
}

interface ICurveZapOutGeneral {
    function ZapOut(
        address payable _toWhomToIssue,
        address _curveExchangeAddress,
        uint256 _tokenCount,
        uint256 _IncomingCRV,
        address _ToTokenAddress,
        uint256 _minToTokens
    ) external returns (uint256 ToTokensBought);
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

interface IAToken {
    function redeem(uint256 _amount) external;

    function underlyingAssetAddress() external returns (address);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract yVault_ZapInOut_General_V1_2 is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    bool public stopped = false;
    uint16 public goodwill;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    IUniswapRouter02 private constant uniswapRouter = IUniswapRouter02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );

    ICurveZapInGeneral public CurveZapInGeneral = ICurveZapInGeneral(
        0x456974dF1042bA7A46FD49512A8778Ac3B840A21
    );
    ICurveZapOutGeneral public CurveZapOutGeneral = ICurveZapOutGeneral(
        0x4bF331Aa2BfB0869315fB81a350d109F4839f81b
    );
    
    IAaveLendingPoolAddressesProvider
        private constant lendingPoolAddressProvider = IAaveLendingPoolAddressesProvider(
        0x24a42fD28C976A61Df5D00D0599C34c4f90748c8
    );

    address
        private yCurveExchangeAddress = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    address
        private constant ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address
        private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address
        private constant zgoodwillAddress = 0xE737b6AfEC2320f616297e59445b60a11e3eF75F;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    event Zapin(
        address _toWhomToIssue,
        address _toYVaultAddress,
        uint256 _Outgoing
    );

    event Zapout(
        address _toWhomToIssue,
        address _fromYVaultAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
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

    function updateCurveZapIn(address CurveZapInGeneralAddress)
        public
        onlyOwner
    {
        require(CurveZapInGeneralAddress != address(0), "Invalid Address");
        CurveZapInGeneral = ICurveZapInGeneral(CurveZapInGeneralAddress);
    }
    
    function updateCurveZapOut(address CurveZapOutGeneralAddress)
        public
        onlyOwner
    {
        require(CurveZapOutGeneralAddress != address(0), "Invalid Address");
        CurveZapOutGeneral = ICurveZapOutGeneral(CurveZapOutGeneralAddress);
    }

    /**
    @notice This function is used to add liquidity to yVaults
    @param _toWhomToIssue recipient address
    @param _toYVaultAddress The address of vault to add liquidity to
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _fromTokenAddress The token used for investment (address(0x00) if ether)
    @param _amount The amount of ERC to invest
    @param _minTokensSwapped for slippage
    @return yTokensRec
     */
    function ZapIn(
        address _toWhomToIssue,
        address _toYVaultAddress,
        uint16 _vaultType,
        address _fromTokenAddress,
        uint256 _amount,
        uint256 _minTokensSwapped
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        yVault vaultToEnter = yVault(_toYVaultAddress);
        address underlyingVaultToken = vaultToEnter.token();

        if (_fromTokenAddress == address(0)) {
            require(msg.value > 0, "ERR: No ETH sent");
        } else {
            require(_amount > 0, "Err: No Tokens Sent");
            require(msg.value == 0, "ERR: ETH sent with Token");

            TransferHelper.safeTransferFrom(
                _fromTokenAddress,
                msg.sender,
                address(this),
                _amount
            );
        }
        if (underlyingVaultToken == _fromTokenAddress) {
            IERC20(underlyingVaultToken).approve(
                address(vaultToEnter),
                _amount
            );
            vaultToEnter.deposit(_amount);
        } else {
            if (_vaultType == 2) {
                uint256 tokensBought;
                if (_fromTokenAddress == address(0)) {
                    tokensBought = CurveZapInGeneral.ZapIn{value: msg.value}(
                        address(this),
                        address(0),
                        yCurveExchangeAddress,
                        msg.value,
                        _minTokensSwapped
                    );
                } else {
                    IERC20(_fromTokenAddress).approve(
                        address(CurveZapInGeneral),
                        _amount
                    );
                    tokensBought = CurveZapInGeneral.ZapIn(
                        address(this),
                        _fromTokenAddress,
                        yCurveExchangeAddress,
                        _amount,
                        _minTokensSwapped
                    );
                }

                IERC20(underlyingVaultToken).approve(
                    address(vaultToEnter),
                    tokensBought
                );
                vaultToEnter.deposit(tokensBought);
            } else if (_vaultType == 1) {
                address underlyingAsset = IAToken(underlyingVaultToken)
                    .underlyingAssetAddress();

                uint256 tokensBought;
                if (_fromTokenAddress == address(0)) {
                    tokensBought = _eth2Token(
                        underlyingAsset,
                        _minTokensSwapped
                    );
                } else {
                    tokensBought = _token2Token(
                        _fromTokenAddress,
                        underlyingAsset,
                        _amount,
                        _minTokensSwapped
                    );
                }

                IERC20(underlyingAsset).approve(
                    lendingPoolAddressProvider.getLendingPoolCore(),
                    tokensBought
                );

                IAaveLendingPool(lendingPoolAddressProvider.getLendingPool())
                    .deposit(underlyingAsset, tokensBought, 0);

                uint256 aTokensBought = IERC20(underlyingVaultToken).balanceOf(
                    address(this)
                );
                IERC20(underlyingVaultToken).approve(
                    address(vaultToEnter),
                    aTokensBought
                );
                vaultToEnter.deposit(aTokensBought);
            } else {
                uint256 tokensBought;
                if (_fromTokenAddress == address(0)) {
                    tokensBought = _eth2Token(
                        underlyingVaultToken,
                        _minTokensSwapped
                    );
                } else {
                    tokensBought = _token2Token(
                        _fromTokenAddress,
                        underlyingVaultToken,
                        _amount,
                        _minTokensSwapped
                    );
                }

                IERC20(underlyingVaultToken).approve(
                    address(vaultToEnter),
                    tokensBought
                );
                vaultToEnter.deposit(tokensBought);
            }
        }

        uint256 yTokensRec = IERC20(address(vaultToEnter)).balanceOf(
            address(this)
        );

        //transfer goodwill
        uint256 goodwillPortion = _transferGoodwill(
            address(vaultToEnter),
            yTokensRec
        );

        IERC20(address(vaultToEnter)).transfer(
            _toWhomToIssue,
            yTokensRec.sub(goodwillPortion)
        );

        emit Zapin(
            _toWhomToIssue,
            address(vaultToEnter),
            yTokensRec.sub(goodwillPortion)
        );

        return (yTokensRec.sub(goodwillPortion));
    }

      /**
    @notice This function is used to add liquidity to yVaults
    @param _toWhomToIssue recipient address
    @param _ToTokenContractAddress The address of the token to withdraw
    @param _fromYVaultAddress The address of the vault to exit
    @param _vaultType Type of underlying token: 0 token; 1 aToken; 2 LP token
    @param _IncomingAmt The amount of vault tokens removed
    @param _minTokensRec for slippage
    @return toTokensReceived
     */  
    function ZapOut(
        address _toWhomToIssue,
        address _ToTokenContractAddress,
        address _fromYVaultAddress,
        uint16 _vaultType,
        uint256 _IncomingAmt,
        uint256 _minTokensRec
    ) public nonReentrant stopInEmergency returns (uint256) {
        yVault vaultToExit = yVault(_fromYVaultAddress);
        address underlyingVaultToken = vaultToExit.token();

        TransferHelper.safeTransferFrom(
            address(vaultToExit),
            msg.sender,
            address(this),
            _IncomingAmt
        );
        
        uint256 goodwillPortion = _transferGoodwill(
            address(vaultToExit),
            _IncomingAmt
        );

        vaultToExit.withdraw(_IncomingAmt.sub(goodwillPortion));
        uint256 underlyingReceived = IERC20(underlyingVaultToken).balanceOf(
            address(this)
        );
        
        uint256 toTokensReceived;
        if(_ToTokenContractAddress == underlyingVaultToken) {
            TransferHelper.safeTransfer(
                underlyingVaultToken,
                _toWhomToIssue,
                underlyingReceived
            );
            toTokensReceived = underlyingReceived;
        } else {
            if(_vaultType == 2) {
                // separate fx to avoid stack too deep error
                toTokensReceived = _withdrawFromCurve(
                    underlyingVaultToken,
                    underlyingReceived,
                    _toWhomToIssue,
                    _ToTokenContractAddress,
                    _minTokensRec
                );
            } else if(_vaultType == 1) {
                // unwrap atoken
                IAToken(underlyingVaultToken).redeem(underlyingReceived);
                address underlyingAsset = IAToken(underlyingVaultToken)
                        .underlyingAssetAddress();
                
                // swap
                if(_ToTokenContractAddress == address(0)) {
                    toTokensReceived = _token2Eth(
                        underlyingAsset,
                        underlyingReceived,
                        payable(_toWhomToIssue),
                        _minTokensRec
                    );
                } else {
                    toTokensReceived = _token2Token(
                        underlyingAsset,
                        _ToTokenContractAddress,
                        underlyingReceived,
                        _minTokensRec
                    );
                    TransferHelper.safeTransfer(
                        _ToTokenContractAddress,
                        _toWhomToIssue,
                        toTokensReceived
                    );
                }
            } else {
                if(_ToTokenContractAddress == address(0)) {
                    toTokensReceived = _token2Eth(
                        underlyingVaultToken,
                        underlyingReceived,
                        payable(_toWhomToIssue),
                        _minTokensRec
                    );
                } else {
                    toTokensReceived = _token2Token(
                        underlyingVaultToken,
                        _ToTokenContractAddress,
                        underlyingReceived,
                        _minTokensRec
                    );
                    
                    TransferHelper.safeTransfer(
                        _ToTokenContractAddress,
                        _toWhomToIssue,
                        toTokensReceived
                    );
                }
            }
        }
        
        emit Zapout(
            _toWhomToIssue,
            _fromYVaultAddress,
            _ToTokenContractAddress,
            toTokensReceived
        );
        
        return toTokensReceived;
    }
    
    function _withdrawFromCurve(
        address _yCurveToken,
        uint256 _tokenAmt,
        address _toWhomToIssue,
        address _ToTokenContractAddress,
        uint256 _minTokensRec
    ) internal returns(uint256) {
        TransferHelper.safeApprove(
                _yCurveToken,
                address(CurveZapOutGeneral),
                _tokenAmt
            );
            
        return(
            CurveZapOutGeneral.ZapOut(
                payable(_toWhomToIssue),
                yCurveExchangeAddress,
                4,
                _tokenAmt,
                _ToTokenContractAddress,
                _minTokensRec
            )
        );
    }

    /**
    @notice This function is used to swap eth for tokens
    @param _tokenContractAddress Token address which we want to buy
    @param minTokens recieved after swap for slippage
    @return tokensBought The quantity of token bought
     */
    function _eth2Token(address _tokenContractAddress, uint256 minTokens)
        internal
        returns (uint256 tokensBought)
    {
        if(_tokenContractAddress == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{value: msg.value}();
            return msg.value;
        }

        address[] memory path = new address[](2);
        path[0] = wethTokenAddress;
        path[1] = _tokenContractAddress;
        tokensBought = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];
        require(tokensBought >= minTokens, "ERR: High Slippage");
    }

    /**
    @notice This function is used to swap tokens
    @param _FromTokenContractAddress The token address to swap from
    @param _ToTokenContractAddress The token address to swap to
    @param tokens2Trade The amount of tokens to swap
    @param minTokens recieved after swap for slippage
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade,
        uint256 minTokens
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        TransferHelper.safeApprove(
            _FromTokenContractAddress,
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

        require(tokenBought > minTokens, "ERR: High Slippage");
    }
    
    function _token2Eth(
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        address payable _toWhomToIssue,
        uint256 minTokens
    ) internal returns (uint256) {
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
        uint256 ethBought = uniswapRouter.swapExactTokensForETH(
                            tokens2Trade,
                            1,
                            path,
                            _toWhomToIssue,
                            deadline
                        )[path.length - 1];
        
        require(ethBought > minTokens, "Error: High Slippage");
        return ethBought;
    }

    /**
    @notice This function is used to calculate and transfer goodwill
    @param _tokenContractAddress Token in which goodwill is deducted
    @param tokens2Trade The total amount of tokens to be zapped in
    @return goodwillPortion The quantity of goodwill deducted
     */
    function _transferGoodwill(
        address _tokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 goodwillPortion) {
        goodwillPortion = SafeMath.div(
            SafeMath.mul(tokens2Trade, goodwill),
            10000
        );

        if (goodwillPortion == 0) {
            return 0;
        }

        TransferHelper.safeTransfer(
            _tokenContractAddress,
            zgoodwillAddress,
            goodwillPortion
        );
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
        TransferHelper.safeTransfer(address(_TokenAddress), owner(), qty);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = payable(owner());
        _to.transfer(contractBalance);
    }
}