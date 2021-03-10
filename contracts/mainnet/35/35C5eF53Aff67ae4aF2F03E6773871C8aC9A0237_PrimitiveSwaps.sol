// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Connector
 * @author  Primitive
 * @notice  Low-level abstract contract for Primitive Connectors to inherit from.
 * @dev     @primitivefi/[email protected]
 */

// Open Zeppelin
import {Context} from "@openzeppelin/contracts/GSN/Context.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// Primitive
import {CoreLib, IOption} from "../libraries/CoreLib.sol";
import {
    IPrimitiveConnector,
    IPrimitiveRouter,
    IWETH
} from "../interfaces/IPrimitiveConnector.sol";

abstract contract PrimitiveConnector is IPrimitiveConnector, Context {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data

    IWETH internal _weth; // Canonical WETH9
    IPrimitiveRouter internal _primitiveRouter; // The PrimitiveRouter contract which executes calls.
    mapping(address => mapping(address => bool)) internal _approved; // Stores approvals for future checks.

    // ===== Constructor =====

    constructor(address weth_, address primitiveRouter_) public {
        _weth = IWETH(weth_);
        _primitiveRouter = IPrimitiveRouter(primitiveRouter_);
        checkApproval(weth_, primitiveRouter_); // Approves this contract's weth to be spent by router.
    }

    /**
     * @notice  Reverts if the `option` is not registered in the PrimitiveRouter contract.
     * @dev     Any `option` which is deployed from the Primitive Registry can be registered with the Router.
     * @param   option The Primitive Option to check if registered.
     */
    modifier onlyRegistered(IOption option) {
        require(
            _primitiveRouter.getRegisteredOption(address(option)),
            "PrimitiveSwaps: EVIL_OPTION"
        );
        _;
    }

    // ===== External =====

    /**
     * @notice  Approves the `spender` to pull `token` from this contract.
     * @dev     This contract does not hold funds, infinite approvals cannot be exploited for profit.
     * @param   token The token to approve spending for.
     * @param   spender The address to allow to spend `token`.
     */
    function checkApproval(address token, address spender)
        public
        override
        returns (bool)
    {
        if (!_approved[token][spender]) {
            IERC20(token).safeApprove(spender, uint256(-1));
            _approved[token][spender] = true;
        }
        return true;
    }

    // ===== Internal =====

    /**
     * @notice  Deposits `msg.value` into the Weth contract for Weth tokens.
     * @return  Whether or not ether was deposited into Weth.
     */
    function _depositETH() internal returns (bool) {
        if (msg.value > 0) {
            _weth.deposit.value(msg.value)();
            return true;
        }
        return false;
    }

    /**
     * @notice  Uses this contract's balance of Weth to withdraw Ether and send it to `getCaller()`.
     */
    function _withdrawETH() internal returns (bool) {
        uint256 quantity = IERC20(address(_weth)).balanceOf(address(this));
        if (quantity > 0) {
            // Withdraw ethers with weth.
            _weth.withdraw(quantity);
            // Send ether.
            (bool success, ) = getCaller().call.value(quantity)("");
            // Revert is call is unsuccessful.
            require(success, "Connector: ERR_SENDING_ETHER");
            return success;
        }
        return true;
    }

    /**
     * @notice  Calls the Router to pull `token` from the getCaller() and send them to this contract.
     * @dev     This eliminates the need for users to approve the Router and each connector.
     * @param   token The token to pull from `getCaller()` into this contract.
     * @param   quantity The amount of `token` to pull into this contract.
     * @return  Whether or not the `token` was transferred into this contract.
     */
    function _transferFromCaller(address token, uint256 quantity)
        internal
        returns (bool)
    {
        if (quantity > 0) {
            _primitiveRouter.transferFromCaller(token, quantity);
            return true;
        }
        return false;
    }

    /**
     * @notice  Pushes this contract's balance of `token` to `getCaller()`.
     * @dev     getCaller() is the original `msg.sender` of the Router's `execute` fn.
     * @param   token The token to transfer to `getCaller()`.
     * @return  Whether or not the `token` was transferred to `getCaller()`.
     */
    function _transferToCaller(address token) internal returns (bool) {
        uint256 quantity = IERC20(token).balanceOf(address(this));
        if (quantity > 0) {
            IERC20(token).safeTransfer(getCaller(), quantity);
            return true;
        }
        return false;
    }

    /**
     * @notice  Calls the Router to pull `token` from the getCaller() and send them to this contract.
     * @dev     This eliminates the need for users to approve the Router and each connector.
     * @param   token The token to pull from `getCaller()`.
     * @param   quantity The amount of `token` to pull.
     * @param   receiver The `to` address to send `quantity` of `token` to.
     * @return  Whether or not `token` was transferred to `receiver`.
     */
    function _transferFromCallerToReceiver(
        address token,
        uint256 quantity,
        address receiver
    ) internal returns (bool) {
        if (quantity > 0) {
            _primitiveRouter.transferFromCallerToReceiver(token, quantity, receiver);
            return true;
        }
        return false;
    }

    /**
     * @notice  Uses this contract's balance of underlyingTokens to mint optionTokens to this contract.
     * @param   optionToken The Primitive Option to mint.
     * @return  (uint, uint) (longOptions, shortOptions)
     */
    function _mintOptions(IOption optionToken) internal returns (uint256, uint256) {
        address underlying = optionToken.getUnderlyingTokenAddress();
        _transferBalanceToReceiver(underlying, address(optionToken)); // Sends to option contract
        return optionToken.mintOptions(address(this));
    }

    /**
     * @notice  Uses this contract's balance of underlyingTokens to mint optionTokens to `receiver`.
     * @param   optionToken The Primitive Option to mint.
     * @param   receiver The address that will received the minted long and short optionTokens.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function _mintOptionsToReceiver(IOption optionToken, address receiver)
        internal
        returns (uint256, uint256)
    {
        address underlying = optionToken.getUnderlyingTokenAddress();
        _transferBalanceToReceiver(underlying, address(optionToken)); // Sends to option contract
        return optionToken.mintOptions(receiver);
    }

    /**
     * @notice  Pulls underlying tokens from `getCaller()` to option contract, then invokes mintOptions().
     * @param   optionToken The option token to mint.
     * @param   quantity The amount of option tokens to mint.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function _mintOptionsFromCaller(IOption optionToken, uint256 quantity)
        internal
        returns (uint256, uint256)
    {
        require(quantity > 0, "ERR_ZERO");
        _transferFromCallerToReceiver(
            optionToken.getUnderlyingTokenAddress(),
            quantity,
            address(optionToken)
        );
        return optionToken.mintOptions(address(this));
    }

    /**
     * @notice  Multi-step operation to close options.
     *          1. Transfer balanceOf `redeem` option token to the option contract.
     *          2. If NOT expired, pull `option` tokens from `getCaller()` and send to option contract.
     *          3. Invoke `closeOptions()` to burn the options and release underlyings to this contract.
     * @return  The amount of underlyingTokens released to this contract.
     */
    function _closeOptions(IOption optionToken) internal returns (uint256) {
        address redeem = optionToken.redeemToken();
        uint256 short = IERC20(redeem).balanceOf(address(this));
        uint256 long = IERC20(address(optionToken)).balanceOf(getCaller());
        uint256 proportional = CoreLib.getProportionalShortOptions(optionToken, long);
        // IF user has more longs than proportional shorts, close the `short` amount.
        if (proportional > short) {
            proportional = short;
        }

        // If option is expired, transfer the amt of proportional thats larger.
        if (optionToken.getExpiryTime() >= now) {
            // Transfers the max proportional amount of short options to option contract.
            IERC20(redeem).safeTransfer(address(optionToken), proportional);
            // Pulls the max amount of long options and sends to option contract.
            _transferFromCallerToReceiver(
                address(optionToken),
                CoreLib.getProportionalLongOptions(optionToken, proportional),
                address(optionToken)
            );
        } else {
            // If not expired, transfer all redeem in balance.
            IERC20(redeem).safeTransfer(address(optionToken), short);
        }
        uint outputUnderlyings;
        if(proportional > 0) {
            (, ,  outputUnderlyings) = optionToken.closeOptions(address(this));
        }
        return outputUnderlyings;
    }

    /**
     * @notice  Multi-step operation to exercise options.
     *          1. Transfer balanceOf `strike` token to option contract.
     *          2. Transfer `amount` of options to exercise to option contract.
     *          3. Invoke `exerciseOptions()` and specify `getCaller()` as the receiver.
     * @dev     If the balanceOf `strike` and `amount` of options are not in correct proportions, call will fail.
     * @param   optionToken The option to exercise.
     * @param   amount The quantity of options to exercise.
     */
    function _exerciseOptions(IOption optionToken, uint256 amount)
        internal
        returns (uint256, uint256)
    {
        address strike = optionToken.getStrikeTokenAddress();
        _transferBalanceToReceiver(strike, address(optionToken));
        IERC20(address(optionToken)).safeTransfer(address(optionToken), amount);
        return optionToken.exerciseOptions(getCaller(), amount, new bytes(0));
    }

    /**
     * @notice  Transfers this contract's balance of Redeem tokens and invokes the redemption function.
     * @param   optionToken The optionToken to redeem, not the redeem token itself.
     */
    function _redeemOptions(IOption optionToken) internal returns (uint256) {
        address redeem = optionToken.redeemToken();
        _transferBalanceToReceiver(redeem, address(optionToken));
        return optionToken.redeemStrikeTokens(getCaller());
    }

    /**
     * @notice  Utility function to transfer this contract's balance of `token` to `receiver`.
     * @param   token The token to transfer.
     * @param   receiver The address that receives the token.
     * @return  Returns the quantity of `token` transferred.
     */
    function _transferBalanceToReceiver(address token, address receiver)
        internal
        returns (uint256)
    {
        uint256 quantity = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(receiver, quantity);
        return quantity;
    }

    // ===== Fallback =====

    receive() external payable {
        assert(_msgSender() == address(_weth)); // only accept ETH via fallback from the WETH contract
    }

    // ===== View =====

    /**
     * @notice  Returns the Weth contract address.
     */
    function getWeth() public view override returns (IWETH) {
        return _weth;
    }

    /**
     * @notice  Returns the state variable `_CALLER` in the Primitive Router.
     */
    function getCaller() public view override returns (address) {
        return _primitiveRouter.getCaller();
    }

    /**
     * @notice  Returns the Primitive Router contract address.
     */
    function getPrimitiveRouter() public view override returns (IPrimitiveRouter) {
        return _primitiveRouter;
    }

    /**
     * @notice  Returns whether or not `spender` is approved to spend `token`, from this contract.
     */
    function isApproved(address token, address spender)
        public
        view
        override
        returns (bool)
    {
        return _approved[token][spender];
    }
}

// SPDX-License-Identifier: MIT

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Swaps Lib
 * @author  Primitive
 * @notice  Library for calculating different proportions of long and short option tokens.
 * @dev     @primitivefi/[email protected]
 */

import {IOption} from "@primitivefi/contracts/contracts/option/interfaces/ITrader.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

library CoreLib {
    using SafeMath for uint256; // Reverts on math underflows/overflows

    /**
     * @dev     Calculates the proportional quantity of long option tokens per short option token.
     * @notice  For each long option token, there is quoteValue / baseValue quantity of short option tokens.
     * @param   optionToken The Option to use to calculate proportional amounts. Each option has different proportions.
     * @param   short The amount of short options used to calculate the proportional amount of long option tokens.
     * @return  The proportional amount of long option tokens based on `short`.
     */
    function getProportionalLongOptions(IOption optionToken, uint256 short)
        internal
        view
        returns (uint256)
    {
        return short.mul(optionToken.getBaseValue()).div(optionToken.getQuoteValue());
    }

    /**
     * @dev     Calculates the proportional quantity of short option tokens per long option token.
     * @notice  For each short option token, there is baseValue / quoteValue quantity of long option tokens.
     * @param   optionToken The Option to use to calculate proportional amounts. Each option has different proportions.
     * @param   long The amount of long options used to calculate the proportional amount of short option tokens.
     * @return  The proportional amount of short option tokens based on `long`.
     */
    function getProportionalShortOptions(IOption optionToken, uint256 long)
        internal
        view
        returns (uint256)
    {
        return long.mul(optionToken.getQuoteValue()).div(optionToken.getBaseValue());
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {IPrimitiveRouter} from "../interfaces/IPrimitiveRouter.sol";
import {IWETH} from "../interfaces/IWETH.sol";

interface IPrimitiveConnector {
    // ===== External =====

    function checkApproval(address token, address spender) external returns (bool);

    // ===== View =====

    function getWeth() external view returns (IWETH);

    function getCaller() external view returns (address);

    function getPrimitiveRouter() external view returns (IPrimitiveRouter);

    function isApproved(address token, address spender) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

pragma solidity 0.6.2;

import { IOption } from "./IOption.sol";

interface ITrader {
    function safeMint(
        IOption optionToken,
        uint256 mintQuantity,
        address receiver
    ) external returns (uint256, uint256);

    function safeExercise(
        IOption optionToken,
        uint256 exerciseQuantity,
        address receiver
    ) external returns (uint256, uint256);

    function safeRedeem(
        IOption optionToken,
        uint256 redeemQuantity,
        address receiver
    ) external returns (uint256);

    function safeClose(
        IOption optionToken,
        uint256 closeQuantity,
        address receiver
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function safeUnwind(
        IOption optionToken,
        uint256 unwindQuantity,
        address receiver
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IOption is IERC20 {
    function mintOptions(address receiver) external returns (uint256, uint256);

    function exerciseOptions(
        address receiver,
        uint256 outUnderlyings,
        bytes calldata data
    ) external returns (uint256, uint256);

    function redeemStrikeTokens(address receiver) external returns (uint256);

    function closeOptions(address receiver)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function redeemToken() external view returns (address);

    function getStrikeTokenAddress() external view returns (address);

    function getUnderlyingTokenAddress() external view returns (address);

    function getBaseValue() external view returns (uint256);

    function getQuoteValue() external view returns (uint256);

    function getExpiryTime() external view returns (uint256);

    function underlyingCache() external view returns (uint256);

    function strikeCache() external view returns (uint256);

    function factory() external view returns (address);

    function getCacheBalances() external view returns (uint256, uint256);

    function getAssetAddresses()
        external
        view
        returns (
            address,
            address,
            address
        );

    function getParameters()
        external
        view
        returns (
            address _underlyingToken,
            address _strikeToken,
            address _redeemToken,
            uint256 _base,
            uint256 _quote,
            uint256 _expiry
        );

    function initRedeemToken(address _redeemToken) external;

    function updateCacheBalances() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

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
    constructor (string memory name, string memory symbol) public {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {
    IOption,
    IERC20
} from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";
import {
    IRegistry
} from "@primitivefi/contracts/contracts/option/interfaces/IRegistry.sol";
import {IWETH} from "./IWETH.sol";

interface IPrimitiveRouter {
    // ===== Admin =====

    function halt() external;

    // ===== Registration =====
    function setRegisteredOptions(address[] calldata optionAddresses)
        external
        returns (bool);

    function setRegisteredConnectors(
        address[] calldata connectors,
        bool[] calldata isValid
    ) external returns (bool);

    // ===== Operations =====

    function transferFromCaller(address token, uint256 amount) external returns (bool);

    function transferFromCallerToReceiver(
        address token,
        uint256 amount,
        address receiver
    ) external returns (bool);

    // ===== Execution =====

    function executeCall(address connector, bytes calldata params) external payable;

    // ==== View ====

    function getWeth() external view returns (IWETH);

    function getRoute() external view returns (address);

    function getCaller() external view returns (address);

    function getRegistry() external view returns (IRegistry);

    function getRegisteredOption(address option) external view returns (bool);

    function getRegisteredConnector(address connector) external view returns (bool);

    function apiVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

interface IRegistry {
    function pauseDeployments() external;

    function unpauseDeployments() external;

    function deployOption(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external returns (address);

    function setOptionFactory(address optionFactory_) external;

    function setRedeemFactory(address redeemFactory_) external;

    function optionFactory() external returns (address);

    function redeemFactory() external returns (address);

    function verifyToken(address tokenAddress) external;

    function verifyExpiry(uint256 expiry) external;

    function unverifyToken(address tokenAddress) external;

    function unverifyExpiry(uint256 expiry) external;

    function calculateOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external view returns (address);

    function getOptionAddress(
        address underlyingToken,
        address strikeToken,
        uint256 base,
        uint256 quote,
        uint256 expiry
    ) external view returns (address);

    function isVerifiedOption(address optionAddress)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Connector TEST
 * @author  Primitive
 * @notice  Low-level abstract contract for Primitive Connectors to inherit from.
 * @dev     @primitivefi/[email protected]
 */

import {PrimitiveConnector, IOption} from "../connectors/PrimitiveConnector.sol";

contract ConnectorTest is PrimitiveConnector {
    event Log(address indexed caller);

    constructor(address weth_, address primitiveRouter_)
        public
        PrimitiveConnector(weth_, primitiveRouter_)
    {}

    function depositETH() external payable returns (bool) {
        emit Log(getCaller());
        return _depositETH();
    }

    function withdrawETH() external returns (bool) {
        emit Log(getCaller());
        return _withdrawETH();
    }

    function transferFromCaller(address token, uint256 quantity) external returns (bool) {
        emit Log(getCaller());
        return _transferFromCaller(token, quantity);
    }

    function transferToCaller(address token) external returns (bool) {
        emit Log(getCaller());
        return _transferToCaller(token);
    }

    function transferFromCallerToReceiver(
        address token,
        uint256 quantity,
        address receiver
    ) external returns (bool) {
        emit Log(getCaller());
        return _transferFromCallerToReceiver(token, quantity, receiver);
    }

    function mintOptions(IOption optionToken, uint256 quantity)
        external
        returns (uint256, uint256)
    {
        emit Log(getCaller());
        _transferFromCaller(optionToken.getUnderlyingTokenAddress(), quantity);
        return _mintOptions(optionToken);
    }

    function mintOptionsToReceiver(
        IOption optionToken,
        uint256 quantity,
        address receiver
    ) external returns (uint256, uint256) {
        emit Log(getCaller());
        _transferFromCaller(optionToken.getUnderlyingTokenAddress(), quantity);
        return _mintOptionsToReceiver(optionToken, receiver);
    }

    function mintOptionsFromCaller(IOption optionToken, uint256 quantity)
        external
        returns (uint256, uint256)
    {
        emit Log(getCaller());
        return _mintOptionsFromCaller(optionToken, quantity);
    }

    function closeOptions(IOption optionToken, uint256 short) external returns (uint256) {
        emit Log(getCaller());
        _transferFromCaller(optionToken.redeemToken(), short);
        return _closeOptions(optionToken);
    }

    function exerciseOptions(
        IOption optionToken,
        uint256 amount,
        uint256 strikeAmount
    ) external returns (uint256, uint256) {
        _transferFromCaller(optionToken.getStrikeTokenAddress(), strikeAmount);
        _transferFromCaller(address(optionToken), amount);
        emit Log(getCaller());
        return _exerciseOptions(optionToken, amount);
    }

    function redeemOptions(IOption optionToken, uint256 short)
        external
        returns (uint256)
    {
        _transferFromCaller(optionToken.redeemToken(), short);
        emit Log(getCaller());
        return _redeemOptions(optionToken);
    }

    function transferBalanceToReceiver(address token, address receiver)
        external
        returns (uint256)
    {
        emit Log(getCaller());
        return _transferBalanceToReceiver(token, receiver);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Router
 * @author  Primitive
 * @notice  Swap option tokens on Uniswap & Sushiswap venues.
 * @dev     @primitivefi/[email protected]
 */

// Open Zeppelin
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Uniswap
import {
    IUniswapV2Callee
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
// Primitive
import {
    IPrimitiveSwaps,
    IUniswapV2Router02,
    IUniswapV2Factory,
    IUniswapV2Pair,
    IOption,
    IERC20Permit
} from "../interfaces/IPrimitiveSwaps.sol";
import {PrimitiveConnector} from "./PrimitiveConnector.sol";
import {SwapsLib, SafeMath} from "../libraries/SwapsLib.sol";

interface DaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract PrimitiveSwaps is
    PrimitiveConnector,
    IPrimitiveSwaps,
    IUniswapV2Callee,
    ReentrancyGuard
{
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    event Initialized(address indexed from); // Emitted on deployment.
    event Buy(
        address indexed from,
        address indexed option,
        uint256 quantity,
        uint256 premium
    );
    event Sell(
        address indexed from,
        address indexed option,
        uint256 quantity,
        uint256 payout
    );

    IUniswapV2Factory private _factory; // The Uniswap V2 _factory contract to get pair addresses from
    IUniswapV2Router02 private _router; // The Uniswap contract used to interact with the protocol

    modifier onlySelf() {
        require(_msgSender() == address(this), "PrimitiveSwaps: NOT_SELF");
        _;
    }

    // ===== Constructor =====
    constructor(
        address weth_,
        address primitiveRouter_,
        address factory_,
        address router_
    ) public PrimitiveConnector(weth_, primitiveRouter_) {
        _factory = IUniswapV2Factory(factory_);
        _router = IUniswapV2Router02(router_);
        emit Initialized(_msgSender());
    }

    // ===== Swap Operations =====

    /**
     * @notice  IMPORTANT: amountOutMin parameter is the price to swap shortOptionTokens to underlyingTokens.
     *          IMPORTANT: If the ratio between shortOptionTokens and underlyingTokens is 1:1, then only the swap fee (0.30%) has to be paid.
     * @dev     Opens a longOptionToken position by minting long + short tokens, then selling the short tokens.
     * @param   optionToken The option address.
     * @param   amountOptions The quantity of longOptionTokens to purchase.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Whether or not the call succeeded.
     */
    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Executes the same as `openFlashLong`, but calls `permit` to pull underlying tokens.
     */
    function openFlashLongWithPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        IERC20Permit(underlying).permit(
            getCaller(),
            address(_primitiveRouter),
            maxPremium,
            deadline,
            v,
            r,
            s
        );
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Executes the same as `openFlashLongWithPermit`, but for DAI.
     */
    function openFlashLongWithDAIPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        DaiPermit(underlying).permit(
            getCaller(),
            address(_primitiveRouter),
            IERC20Permit(underlying).nonces(getCaller()),
            deadline,
            true,
            v,
            r,
            s
        );
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashMintShortOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens.
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                maxPremium // Total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @notice  Uses Ether to pay to purchase the option tokens.
     *          IMPORTANT: amountOutMin parameter is the price to swap shortOptionTokens to underlyingTokens.
     *          IMPORTANT: If the ratio between shortOptionTokens and underlyingTokens is 1:1, then only the swap fee (0.30%) has to be paid.
     * @dev     Opens a longOptionToken position by minting long + short tokens, then selling the short tokens.
     * @param   optionToken The option address.
     * @param   amountOptions The quantity of longOptionTokens to purchase.
     */
    function openFlashLongWithETH(IOption optionToken, uint256 amountOptions)
        external
        payable
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (bool)
    {
        require(msg.value > 0, "PrimitiveSwaps: ZERO"); // Fail early if no Ether was sent.
        // Calls pair.swap(), and executes `flashMintShortOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, address underlying, ) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            underlying, // Token to swap to, i.e. receive optimistically.
            amountOptions, // Amount of underlying to optimistically receive to mint options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes(
                            "flashMintShortOptionsThenSwapWithETH(address,uint256,uint256)"
                        )
                    )
                ),
                optionToken, // Option token to mint with flash loaned tokens
                amountOptions, // Quantity of underlyingTokens from flash loan to use to mint options.
                msg.value // total price paid (in underlyingTokens) for selling shortOptionTokens.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @dev     Closes a longOptionToken position by flash swapping in redeemTokens,
     *          closing the option, and paying back in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, this function will cost the caller to close the option, for no gain.
     * @param   optionToken The address of the longOptionTokens to close.
     * @param   amountRedeems The quantity of redeemTokens to borrow to close the options.
     * @param   minPayout The minimum payout of underlyingTokens sent out to the user.
     */
    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashCloseLongOptionsThenSwap` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, , address redeem) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            redeem, // Token to swap to, i.e. receive optimistically.
            amountRedeems, // Amount of underlying to optimistically receive to close options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes("flashCloseLongOptionsThenSwap(address,uint256,uint256)")
                    )
                ),
                optionToken, // Option token to close with flash loaned redeemTokens.
                amountRedeems, // Quantity of redeemTokens from flash loan to use to close options.
                minPayout // Total remaining underlyingTokens after flash loan is paid.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    /**
     * @dev     Closes a longOptionToken position by flash swapping in redeemTokens,
     *          closing the option, and paying back in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, this function will cost the caller to close the option, for no gain.
     * @param   optionToken The address of the longOptionTokens to close.
     * @param   amountRedeems The quantity of redeemTokens to borrow to close the options.
     * @param   minPayout The minimum payout of underlyingTokens sent out to the user.
     */
    function closeFlashLongForETH(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external override nonReentrant onlyRegistered(optionToken) returns (bool) {
        // Calls pair.swap(), and executes `flashCloseLongOptionsThenSwapForETH` in the `uniswapV2Callee` callback.
        (IUniswapV2Pair pair, , address redeem) = getOptionPair(optionToken);
        SwapsLib._flashSwap(
            pair, // Pair to flash swap from.
            redeem, // Token to swap to, i.e. receive optimistically.
            amountRedeems, // Amount of underlying to optimistically receive to close options with.
            abi.encodeWithSelector( // Start: Function to call in the callback.
                bytes4(
                    keccak256(
                        bytes(
                            "flashCloseLongOptionsThenSwapForETH(address,uint256,uint256)"
                        )
                    )
                ),
                optionToken, // Option token to close with flash loaned redeemTokens.
                amountRedeems, // Quantity of redeemTokens from flash loan to use to close options.
                minPayout // Total remaining underlyingTokens after flash loan is paid.
            ) // End: Function to call in the callback.
        );
        return true;
    }

    // ===== Flash Callback Functions =====

    /**
     * @notice  Callback function executed in a UniswapV2Pair.swap() call for `openFlashLong`.
     * @dev     Pays underlying token `premium` for `quantity` of `optionAddress` tokens.
     * @param   optionAddress The address of the Option contract.
     * @param   quantity The quantity of options to mint using borrowed underlyingTokens.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Returns (amount, premium) of options purchased for total premium price.
     */
    function flashMintShortOptionsThenSwap(
        address optionAddress,
        uint256 quantity,
        uint256 maxPremium
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Mint option and redeem tokens to this contract.
        _mintOptions(optionToken);
        // Get the repayment amounts.
        (uint256 premium, uint256 redeemPremium) =
            SwapsLib.repayOpen(_router, optionToken, quantity);
        // If premium is non-zero and non-negative (most cases), send underlyingTokens to the pair as payment (premium).
        if (premium > 0) {
            // Check for users to not pay over their max desired value.
            require(maxPremium >= premium, "PrimitiveSwaps: MAX_PREMIUM");
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Push underlying tokens back to the pair as repayment.
            _transferFromCallerToReceiver(underlying, premium, address(pair));
        }
        // Pay pair in redeem tokens.
        if (redeemPremium > 0) {
            IERC20(redeem).safeTransfer(address(pair), redeemPremium);
        }
        // Return tokens to `getCaller()`.
        _transferToCaller(redeem);
        _transferToCaller(optionAddress);
        emit Buy(getCaller(), optionAddress, quantity, premium);
        return (quantity, premium);
    }

    /**
     * @notice  Callback function executed in a UniswapV2Pair.swap() call for `openFlashLongWithETH`.
     * @dev     Pays `premium` in ether for `quantity` of `optionAddress` tokens.
     * @param   optionAddress The address of the Option contract.
     * @param   quantity The quantity of options to mint using borrowed underlyingTokens.
     * @param   maxPremium The maximum quantity of underlyingTokens to pay for the optionTokens.
     * @return  Returns (amount, premium) of options purchased for total premium price.
     */
    function flashMintShortOptionsThenSwapWithETH(
        address optionAddress,
        uint256 quantity,
        uint256 maxPremium
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        require(underlying == address(_weth), "PrimitiveSwaps: NOT_WETH"); // Ensure Weth Call.
        // Mint option and redeem tokens to this contract.
        _mintOptions(optionToken);
        // Get the repayment amounts.
        (uint256 premium, uint256 redeemPremium) =
            SwapsLib.repayOpen(_router, optionToken, quantity);
        // If premium is non-zero and non-negative (most cases), send underlyingTokens to the pair as payment (premium).
        if (premium > 0) {
            // Check for users to not pay over their max desired value.
            require(maxPremium >= premium, "PrimitiveSwaps: MAX_PREMIUM");
            // Wrap exact Ether amount of `premium`.
            _weth.deposit.value(premium)();
            // Transfer Weth to pair to pay for premium.
            IERC20(address(_weth)).safeTransfer(address(pair), premium);
            // Return remaining Ether to caller.
            _withdrawETH();
        }
        // Pay pair in redeem.
        if (redeemPremium > 0) {
            IERC20(redeem).safeTransfer(address(pair), redeemPremium);
        }
        // Return tokens to `getCaller()`.
        _transferToCaller(redeem);
        _transferToCaller(optionAddress);
        emit Buy(getCaller(), optionAddress, quantity, premium);
        return (quantity, premium);
    }

    /**
     * @dev     Sends shortOptionTokens to _msgSender(), and pays back the UniswapV2Pair in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, the `to` address is liable for negative payouts *if* that occurs.
     * @param   optionAddress The address of the longOptionTokes to close.
     * @param   flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
     * @param   minPayout The minimum payout of underlyingTokens sent to the `to` address.
     */
    function flashCloseLongOptionsThenSwap(
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Close the options, releasing underlying tokens to this contract.
        uint256 outputUnderlyings = _closeOptions(optionToken);
        // Get repay amounts.
        (uint256 payout, uint256 cost, uint256 outstanding) =
            SwapsLib.repayClose(_router, optionToken, flashLoanQuantity);
        if (payout > 0) {
            cost = outputUnderlyings.sub(payout);
        }
        // Pay back the pair in underlyingTokens.
        if (cost > 0) {
            IERC20(underlying).safeTransfer(address(pair), cost);
        }
        if (outstanding > 0) {
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Revert if the minPayout is less than or equal to the underlyingPayment of 0.
            // There is 0 underlyingPayment in the case that outstanding > 0.
            // This code branch can be successful by setting `minPayout` to 0.
            // This means the user is willing to pay to close the position.
            require(minPayout <= payout, "PrimitiveSwaps: NEGATIVE_PAYOUT");
            _transferFromCallerToReceiver(underlying, outstanding, address(pair));
        }
        // If payout is non-zero and non-negative, send it to the `getCaller()` address.
        if (payout > 0) {
            // Revert if minPayout is greater than the actual payout.
            require(payout >= minPayout, "PrimitiveSwaps: MIN_PREMIUM");
            _transferToCaller(underlying);
        }
        emit Sell(getCaller(), optionAddress, flashLoanQuantity, payout);
        return (payout, cost);
    }

    /**
     * @dev     Sends shortOptionTokens to _msgSender(), and pays back the UniswapV2Pair in underlyingTokens.
     * @notice  IMPORTANT: If minPayout is 0, the `getCaller()` address is liable for negative payouts *if* that occurs.
     * @param   optionAddress The address of the longOptionTokes to close.
     * @param   flashLoanQuantity The quantity of shortOptionTokens borrowed to use to close longOptionTokens.
     * @param   minPayout The minimum payout of underlyingTokens sent to the `to` address.
     */
    function flashCloseLongOptionsThenSwapForETH(
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout
    ) public onlySelf onlyRegistered(IOption(optionAddress)) returns (uint256, uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        require(underlying == address(_weth), "PrimitiveSwaps: NOT_WETH");
        // Close the options, releasing underlying tokens to this contract.
        _closeOptions(optionToken);
        // Get repay amounts.
        (uint256 payout, uint256 cost, uint256 outstanding) =
            SwapsLib.repayClose(_router, optionToken, flashLoanQuantity);
        // Pay back the pair in underlyingTokens.
        if (cost > 0) {
            IERC20(underlying).safeTransfer(address(pair), cost);
        }
        if (outstanding > 0) {
            // Pull underlyingTokens from the `getCaller()` to pay the remainder of the flash swap.
            // Revert if the minPayout is less than or equal to the underlyingPayment of 0.
            // There is 0 underlyingPayment in the case that outstanding > 0.
            // This code branch can be successful by setting `minPayout` to 0.
            // This means the user is willing to pay to close the position.
            require(minPayout <= payout, "PrimitiveSwaps: NEGATIVE_PAYOUT");
            _transferFromCallerToReceiver(underlying, outstanding, address(pair));
        }
        // If payout is non-zero and non-negative, send it to the `getCaller()` address.
        if (payout > 0) {
            // Revert if minPayout is greater than the actual payout.
            require(payout >= minPayout, "PrimitiveSwaps: MIN_PREMIUM");
            _withdrawETH(); // Unwrap's this contract's balance of Weth and sends Ether to `getCaller()`.
        }
        emit Sell(getCaller(), optionAddress, flashLoanQuantity, payout);
        return (payout, cost);
    }

    // ===== Flash Loans =====

    /**
     * @dev     The callback function triggered in a UniswapV2Pair.swap() call when the `data` parameter has data.
     * @param   sender The original _msgSender() of the UniswapV2Pair.swap() call.
     * @param   amount0 The quantity of token0 received to the `to` address in the swap() call.
     * @param   amount1 The quantity of token1 received to the `to` address in the swap() call.
     * @param   data The payload passed in the `data` parameter of the swap() call.
     */
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override(IPrimitiveSwaps, IUniswapV2Callee) {
        assert(
            _msgSender() ==
                _factory.getPair(
                    IUniswapV2Pair(_msgSender()).token0(),
                    IUniswapV2Pair(_msgSender()).token1()
                )
        ); // Ensure that _msgSender() is actually a V2 pair.
        require(sender == address(this), "PrimitiveSwaps: NOT_SENDER"); // Ensure called by this contract.
        (bool success, bytes memory returnData) = address(this).call(data); // Execute the callback.
        (uint256 amountA, uint256 amountB) = abi.decode(returnData, (uint256, uint256));
        require(
            success && (returnData.length == 0 || amountA > 0 || amountB > 0),
            "PrimitiveSwaps: CALLBACK"
        );
    }

    // ===== View =====

    /**
     * @notice  Gets the UniswapV2Router02 contract address.
     */
    function getRouter() public view override returns (IUniswapV2Router02) {
        return _router;
    }

    /**
     * @notice  Gets the UniswapV2Factory contract address.
     */
    function getFactory() public view override returns (IUniswapV2Factory) {
        return _factory;
    }

    /**
     * @notice  Fetchs the Uniswap Pair for an option's redeemToken and underlyingToken params.
     * @param   option The option token to get the corresponding UniswapV2Pair market.
     * @return  The pair address, as well as the tokens of the pair.
     */
    function getOptionPair(IOption option)
        public
        view
        override
        returns (
            IUniswapV2Pair,
            address,
            address
        )
    {
        address redeem = option.redeemToken();
        address underlying = option.getUnderlyingTokenAddress();
        IUniswapV2Pair pair = IUniswapV2Pair(_factory.getPair(redeem, underlying));
        return (pair, underlying, redeem);
    }

    /**
     * @dev     Calculates the effective premium, denominated in underlyingTokens, to buy `quantity` of `optionToken`s.
     * @notice  UniswapV2 adds a 0.3009027% fee which is applied to the premium as 0.301%.
     *          IMPORTANT: If the pair's reserve ratio is incorrect, there could be a 'negative' premium.
     *          Buying negative premium options will pay out redeemTokens.
     *          An 'incorrect' ratio occurs when the (reserves of redeemTokens / strike ratio) >= reserves of underlyingTokens.
     *          Implicitly uses the `optionToken`'s underlying and redeem tokens for the pair.
     * @param   optionToken The optionToken to get the premium cost of purchasing.
     * @param   quantity The quantity of long option tokens that will be purchased.
     * @return  (uint, uint) Returns the `premium` to buy `quantity` of `optionToken` and the `negativePremium`.
     */
    function getOpenPremium(IOption optionToken, uint256 quantity)
        public
        view
        override
        returns (uint256, uint256)
    {
        return SwapsLib.getOpenPremium(_router, optionToken, quantity);
    }

    /**
     * @dev     Calculates the effective premium, denominated in underlyingTokens, to sell `optionToken`s.
     * @param   optionToken The optionToken to get the premium cost of purchasing.
     * @param   quantity The quantity of short option tokens that will be closed.
     * @return  (uint, uint) Returns the `premium` to sell `quantity` of `optionToken` and the `negativePremium`.
     */
    function getClosePremium(IOption optionToken, uint256 quantity)
        public
        view
        override
        returns (uint256, uint256)
    {
        return SwapsLib.getClosePremium(_router, optionToken, quantity);
    }
}

// SPDX-License-Identifier: MIT

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

    constructor () internal {
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

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {
    IUniswapV2Factory
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IOption} from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

interface IPrimitiveSwaps {
    // ==== External Functions ====

    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium
    ) external returns (bool);

    function openFlashLongWithPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function openFlashLongWithDAIPermit(
        IOption optionToken,
        uint256 amountOptions,
        uint256 maxPremium,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function openFlashLongWithETH(IOption optionToken, uint256 amountOptions)
        external
        payable
        returns (bool);

    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external returns (bool);

    function closeFlashLongForETH(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external returns (bool);

    // ===== Callback =====

    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    // ==== View ====

    function getRouter() external view returns (IUniswapV2Router02);

    function getFactory() external view returns (IUniswapV2Factory);

    function getOptionPair(IOption option)
        external
        view
        returns (
            IUniswapV2Pair,
            address,
            address
        );

    function getOpenPremium(IOption optionToken, uint256 quantity)
        external
        view
        returns (uint256, uint256);

    function getClosePremium(IOption optionToken, uint256 quantity)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Swaps Lib
 * @author  Primitive
 * @notice  Library for Swap Logic for Uniswap AMM.
 * @dev     @primitivefi/[email protected]
 */

import {
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {CoreLib, IOption, SafeMath} from "./CoreLib.sol";

library SwapsLib {
    using SafeMath for uint256; // Reverts on math underflows/overflows

    /**
     * @notice  Passes in `params` to the UniswapV2Pair.swap() function to trigger the callback.
     * @param   pair The Uniswap Pair to call.
     * @param   token The token in the Pair to swap to, and thus optimistically receive.
     * @param   amount The quantity of `token`s to optimistically receive first.
     * @param   params  The data to call from this contract, using the `uniswapV2Callee` callback.
     * @return  Whether or not the swap() call suceeded.
     */
    function _flashSwap(
        IUniswapV2Pair pair,
        address token,
        uint256 amount,
        bytes memory params
    ) internal returns (bool) {
        // Receives `amount` of `token` to this contract address.
        uint256 amount0Out = pair.token0() == token ? amount : 0;
        uint256 amount1Out = pair.token0() == token ? 0 : amount;
        // Execute the callback function in params.
        pair.swap(amount0Out, amount1Out, address(this), params);
        return true;
    }

    /**
     * @notice  Gets the amounts to pay out, pay back, and outstanding cost.
     * @param   router The UniswapV2Router02 to use for calculating `amountsOut`.
     * @param   optionToken The option token to use for fetching its corresponding Uniswap Pair.
     * @param   redeemAmount The quantity of REDEEM tokens, with `quoteValue` units, needed to close the options.
     */
    function repayClose(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 redeemAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Outstanding is the cost remaining, should be 0 in most cases.
        // Payout is the `premium` that the original caller receives in underlyingTokens.
        (uint256 payout, uint256 outstanding) =
            getClosePremium(router, optionToken, redeemAmount);

        // In most cases there will be an underlying payout, which is subtracted from the redeemAmount.
        uint256 cost = CoreLib.getProportionalLongOptions(optionToken, redeemAmount);
        if (payout > 0) {
            cost = cost.sub(payout);
        }
        return (payout, cost, outstanding);
    }

    /**
     * @notice  Returns the swap amounts required to return to repay the flash loan used to open a long position.
     * @param   router The UniswapV2Router02 to use for calculating `amountsOut`.
     * @param   optionToken The option token to use for fetching its corresponding Uniswap Pair.
     * @param   underlyingAmount The quantity of UNDERLYING tokens, with `baseValue` units, needed to open the options.
     */
    function repayOpen(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 underlyingAmount
    ) internal view returns (uint256, uint256) {
        // Premium is the `underlyingTokens` required to buy the `optionToken`.
        // ExtraRedeems is the `redeemTokens` that are remaining.
        // If `premium` is not 0, `extraRedeems` should be 0, else `extraRedeems` is the payout (a negative premium).
        (uint256 premium, uint256 extraRedeems) =
            getOpenPremium(router, optionToken, underlyingAmount);

        uint256 redeemPremium =
            CoreLib.getProportionalShortOptions(optionToken, underlyingAmount);

        if (extraRedeems > 0) {
            redeemPremium = redeemPremium.sub(extraRedeems);
        }
        return (premium, redeemPremium);
    }

    /**
     * @dev    Calculates the effective premium, denominated in underlyingTokens, to buy `quantity` of `optionToken`s.
     * @notice UniswapV2 adds a 0.3009027% fee which is applied to the premium as 0.301%.
     *         IMPORTANT: If the pair's reserve ratio is incorrect, there could be a 'negative' premium.
     *         Buying negative premium options will pay out redeemTokens.
     *         An 'incorrect' ratio occurs when the (reserves of redeemTokens / strike ratio) >= reserves of underlyingTokens.
     *         Implicitly uses the `optionToken`'s underlying and redeem tokens for the pair.
     * @param  router The UniswapV2Router02 contract.
     * @param  optionToken The optionToken to get the premium cost of purchasing.
     * @param  quantity The quantity of long option tokens that will be purchased.
     */
    function getOpenPremium(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 quantity
    )
        internal
        view
        returns (
            /* override */
            uint256,
            uint256
        )
    {
        // longOptionTokens are opened by doing a swap from redeemTokens to underlyingTokens effectively.
        address[] memory path = new address[](2);
        path[0] = optionToken.redeemToken();
        path[1] = optionToken.getUnderlyingTokenAddress();

        // `quantity` of underlyingTokens are output from the swap.
        // They are used to mint options, which will mint `quantity` * quoteValue / baseValue amount of redeemTokens.
        uint256 redeemsMinted =
            CoreLib.getProportionalShortOptions(optionToken, quantity);

        // The loanRemainderInUnderlyings will be the amount of underlyingTokens that are needed from the original
        // transaction caller in order to pay the flash swap.
        // IMPORTANT: THIS IS EFFECTIVELY THE PREMIUM PAID IN UNDERLYINGTOKENS TO PURCHASE THE OPTIONTOKEN.
        uint256 loanRemainderInUnderlyings;

        // Economically, negativePremiumPaymentInRedeems value should always be 0.
        // In the case that we minted more redeemTokens than are needed to pay back the flash swap,
        // (short -> underlying is a positive trade), there is an effective negative premium.
        // In that case, this function will send out `negativePremiumAmount` of redeemTokens to the original caller.
        // This means the user gets to keep the extra redeemTokens for free.
        // Negative premium amount is the opposite difference of the loan remainder: (paid - flash loan amount)
        uint256 negativePremiumPaymentInRedeems;

        // Since the borrowed amount is underlyingTokens, and we are paying back in redeemTokens,
        // we need to see how much redeemTokens must be returned for the borrowed amount.
        // We can find that value by doing the normal swap math, getAmountsIn will give us the amount
        // of redeemTokens are needed for the output amount of the flash loan.
        // IMPORTANT: amountsIn[0] is how many short tokens we need to pay back.
        // This value is most likely greater than the amount of redeemTokens minted.
        uint256[] memory amountsIn = router.getAmountsIn(quantity, path);
        uint256 redeemsRequired = amountsIn[0]; // the amountIn of redeemTokens based on the amountOut of `quantity`.
        // If redeemsMinted is greater than redeems required, there is a cost of 0, implying a negative premium.
        uint256 redeemCostRemaining =
            redeemsRequired > redeemsMinted ? redeemsRequired.sub(redeemsMinted) : 0;
        // If there is a negative premium, calculate the quantity of remaining redeemTokens after the `redeemsMinted` is spent.
        negativePremiumPaymentInRedeems = redeemsMinted > redeemsRequired
            ? redeemsMinted.sub(redeemsRequired)
            : 0;

        // In most cases, there will be an outstanding cost (assuming we minted less redeemTokens than the
        // required amountIn of redeemTokens for the swap).
        if (redeemCostRemaining > 0) {
            // The user won't want to pay back the remaining cost in redeemTokens,
            // because they borrowed underlyingTokens to mint them in the first place.
            // So instead, we get the quantity of underlyingTokens that could be paid instead.
            // We can calculate this using normal swap math.
            // getAmountsOut will return the quantity of underlyingTokens that are output,
            // based on some input of redeemTokens.
            // The input redeemTokens is the remaining redeemToken cost, and the output
            // underlyingTokens is the proportional amount of underlyingTokens.
            // amountsOut[1] is then the outstanding flash loan value denominated in underlyingTokens.
            uint256[] memory amountsOut = router.getAmountsOut(redeemCostRemaining, path);

            // Returning withdrawn tokens to the pair has a fee of .003 / .997 = 0.3009027% which must be applied.
            loanRemainderInUnderlyings = (
                amountsOut[1].mul(100000).add(amountsOut[1].mul(301))
            )
                .div(100000);
        }
        return (loanRemainderInUnderlyings, negativePremiumPaymentInRedeems);
    }

    /**
     * @dev    Calculates the effective premium, denominated in underlyingTokens, to sell `optionToken`s.
     * @param  router The UniswapV2Router02 contract.
     * @param  optionToken The optionToken to get the premium cost of purchasing.
     * @param  quantity The quantity of short option tokens that will be closed.
     */
    function getClosePremium(
        IUniswapV2Router02 router,
        IOption optionToken,
        uint256 quantity
    )
        internal
        view
        returns (
            /* override */
            uint256,
            uint256
        )
    {
        // longOptionTokens are closed by doing a swap from underlyingTokens to redeemTokens.
        address[] memory path = new address[](2);
        path[0] = optionToken.getUnderlyingTokenAddress();
        path[1] = optionToken.redeemToken();
        uint256 outputUnderlyings =
            CoreLib.getProportionalLongOptions(optionToken, quantity);
        // The loanRemainder will be the amount of underlyingTokens that are needed from the original
        // transaction caller in order to pay the flash swap.
        uint256 loanRemainder;

        // Economically, underlyingPayout value should always be greater than 0, or this trade shouldn't be made.
        // If an underlyingPayout is greater than 0, it means that the redeemTokens borrowed are worth less than the
        // underlyingTokens received from closing the redeemToken<>optionTokens.
        // If the redeemTokens are worth more than the underlyingTokens they are entitled to,
        // then closing the redeemTokens will cost additional underlyingTokens. In this case,
        // the transaction should be reverted. Or else, the user is paying extra at the expense of
        // rebalancing the pool.
        uint256 underlyingPayout;

        // Since the borrowed amount is redeemTokens, and we are paying back in underlyingTokens,
        // we need to see how much underlyingTokens must be returned for the borrowed amount.
        // We can find that value by doing the normal swap math, getAmountsIn will give us the amount
        // of underlyingTokens are needed for the output amount of the flash loan.
        // IMPORTANT: amountsIn 0 is how many underlyingTokens we need to pay back.
        // This value is most likely greater than the amount of underlyingTokens received from closing.
        uint256[] memory amountsIn = router.getAmountsIn(quantity, path);

        uint256 underlyingsRequired = amountsIn[0]; // the amountIn required of underlyingTokens based on the amountOut of flashloanQuantity
        // If outputUnderlyings (received from closing) is greater than underlyings required,
        // there is a positive payout.
        underlyingPayout = outputUnderlyings > underlyingsRequired
            ? outputUnderlyings.sub(underlyingsRequired)
            : 0;

        // If there is a negative payout, calculate the remaining cost of underlyingTokens.
        uint256 underlyingCostRemaining =
            underlyingsRequired > outputUnderlyings
                ? underlyingsRequired.sub(outputUnderlyings)
                : 0;

        // In the case that there is a negative payout (additional underlyingTokens are required),
        // get the remaining cost into the `loanRemainder` variable and also check to see
        // if a user is willing to pay the negative cost. There is no rational economic incentive for this.
        if (underlyingCostRemaining > 0) {
            loanRemainder = underlyingCostRemaining;
        }
        return (underlyingPayout, loanRemainder);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity >=0.5.0;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Liquidity
 * @author  Primitive
 * @notice  Manage liquidity on Uniswap & Sushiswap Venues.
 * @dev     @primitivefi/[email protected]
 */

// Open Zeppelin
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Interfaces
import {
    IPrimitiveLiquidity,
    IUniswapV2Router02,
    IUniswapV2Factory,
    IUniswapV2Pair,
    IERC20Permit,
    IOption
} from "../interfaces/IPrimitiveLiquidity.sol";
// Primitive
import {PrimitiveConnector} from "./PrimitiveConnector.sol";
import {CoreLib, SafeMath} from "../libraries/CoreLib.sol";

interface DaiPermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract PrimitiveLiquidity is PrimitiveConnector, IPrimitiveLiquidity, ReentrancyGuard {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    event Initialized(address indexed from); // Emitted on deployment.
    event AddLiquidity(address indexed from, address indexed option, uint256 sum);
    event RemoveLiquidity(address indexed from, address indexed option, uint256 sum);

    IUniswapV2Factory private _factory; // The Uniswap V2 factory contract to get pair addresses from.
    IUniswapV2Router02 private _router; // The Uniswap Router contract used to interact with the protocol.

    // ===== Constructor =====
    constructor(
        address weth_,
        address primitiveRouter_,
        address factory_,
        address router_
    ) public PrimitiveConnector(weth_, primitiveRouter_) {
        _factory = IUniswapV2Factory(factory_);
        _router = IUniswapV2Router02(router_);
        emit Initialized(_msgSender());
    }

    // ===== Liquidity Operations =====

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting redeemTokens with underlyingTokens.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the "getCaller()" address.
     *          underlyingToken -> redeemToken -> UNI-V2.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with redeemTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithUnderlying(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        public
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        address underlying = IOption(optionAddress).getUnderlyingTokenAddress();
        // Pulls total = (quantityOptions + amountBMax) of underlyingTokens from `getCaller()` to this contract.
        {
            uint256 sum = quantityOptions.add(amountBMax);
            _transferFromCaller(underlying, sum);
        }
        // Pushes underlyingTokens to option contract and mints option + redeem tokens to this contract.
        IERC20(underlying).safeTransfer(optionAddress, quantityOptions);
        (, uint256 outputRedeems) = IOption(optionAddress).mintOptions(address(this));

        {
            // scope for adding exact liquidity, avoids stack too deep errors
            IOption optionToken = IOption(optionAddress);
            address redeem = optionToken.redeemToken();
            AddAmounts memory params;
            params.amountAMax = outputRedeems;
            params.amountBMax = amountBMax;
            params.amountAMin = outputRedeems;
            params.amountBMin = amountBMin;
            params.deadline = deadline;
            // Approves Uniswap V2 Pair pull tokens from this contract.
            checkApproval(redeem, address(_router));
            checkApproval(underlying, address(_router));
            // Adds liquidity to Uniswap V2 Pair and returns liquidity shares to the "getCaller()" address.
            (amountA, amountB, liquidity) = _addLiquidity(redeem, underlying, params);
            // Check for exact liquidity provided.
            assert(amountA == outputRedeems);
            // Return remaining tokens
            _transferToCaller(underlying);
            _transferToCaller(redeem);
            _transferToCaller(address(optionToken));
        }
        {
            // scope for event, avoids stack too deep errors
            address a0 = optionAddress;
            uint256 q0 = quantityOptions;
            uint256 q1 = amountBMax;
            emit AddLiquidity(getCaller(), a0, q0.add(q1));
        }
        return (amountA, amountB, liquidity);
    }

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting shortOptionTokens with underlyingTokens.
     *          Doesn't check for registered optionAddress because the returned function does.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the "getCaller()" address.
     *          underlyingToken -> redeemToken -> UNI-V2. Uses permit so user does not need to `approve()` our contracts.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with shortOptionTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithUnderlyingWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IERC20Permit underlying =
            IERC20Permit(IOption(optionAddress).getUnderlyingTokenAddress());
        uint256 sum = quantityOptions.add(amountBMax);
        underlying.permit(getCaller(), address(_primitiveRouter), sum, deadline, v, r, s);
        return
            addShortLiquidityWithUnderlying(
                optionAddress,
                quantityOptions,
                amountBMax,
                amountBMin,
                deadline
            );
    }

    /**
     * @dev     Doesn't check for registered optionAddress because the returned function does.
     * @notice  Specialized function for `permit` calling on Put options (DAI).
     */
    function addShortLiquidityDAIWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DaiPermit dai = DaiPermit(IOption(optionAddress).getUnderlyingTokenAddress());
        address caller = getCaller();
        dai.permit(
            caller,
            address(_primitiveRouter),
            IERC20Permit(address(dai)).nonces(caller),
            deadline,
            true,
            v,
            r,
            s
        );
        return
            addShortLiquidityWithUnderlying(
                optionAddress,
                quantityOptions,
                amountBMax,
                amountBMin,
                deadline
            );
    }

    /**
     * @dev     Adds redeemToken liquidity to a redeem<>underlyingToken pair by minting shortOptionTokens with underlyingTokens.
     * @notice  Pulls underlying tokens from `getCaller()` and pushes UNI-V2 liquidity tokens to the `getCaller()` address.
     *          underlyingToken -> redeemToken -> UNI-V2.
     * @param   optionAddress The address of the optionToken to get the redeemToken to mint then provide liquidity for.
     * @param   quantityOptions The quantity of underlyingTokens to use to mint option + redeem tokens.
     * @param   amountBMax The quantity of underlyingTokens to add with shortOptionTokens to the Uniswap V2 Pair.
     * @param   amountBMin The minimum quantity of underlyingTokens expected to provide liquidity with.
     * @param   deadline The timestamp to expire a pending transaction.
     * @return  Returns (amountA, amountB, liquidity) amounts.
     */
    function addShortLiquidityWithETH(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        payable
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            msg.value >= quantityOptions.add(amountBMax),
            "PrimitiveLiquidity: INSUFFICIENT"
        );

        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        address underlying = IOption(optionAddress).getUnderlyingTokenAddress();
        require(underlying == address(_weth), "PrimitiveLiquidity: NOT_WETH");

        _depositETH(); // Wraps `msg.value` to Weth.
        // Pushes Weth to option contract and mints option + redeem tokens to this contract.
        IERC20(underlying).safeTransfer(optionAddress, quantityOptions);
        (, uint256 outputRedeems) = IOption(optionAddress).mintOptions(address(this));

        {
            // scope for adding exact liquidity, avoids stack too deep errors
            IOption optionToken = IOption(optionAddress);
            address redeem = optionToken.redeemToken();
            AddAmounts memory params;
            params.amountAMax = outputRedeems;
            params.amountBMax = amountBMax;
            params.amountAMin = outputRedeems;
            params.amountBMin = amountBMin;
            params.deadline = deadline;

            // Approves Uniswap V2 Pair pull tokens from this contract.
            checkApproval(redeem, address(_router));
            checkApproval(underlying, address(_router));
            // Adds liquidity to Uniswap V2 Pair.
            (amountA, amountB, liquidity) = _addLiquidity(redeem, underlying, params);
            assert(amountA == outputRedeems); // Check for exact liquidity provided.
            // Return remaining tokens and ether.
            _withdrawETH();
            _transferToCaller(redeem);
            _transferToCaller(address(optionToken));
        }
        {
            // scope for event, avoids stack too deep errors
            address a0 = optionAddress;
            uint256 q0 = quantityOptions;
            uint256 q1 = amountBMax;
            emit AddLiquidity(getCaller(), a0, q0.add(q1));
        }
        return (amountA, amountB, liquidity);
    }

    struct AddAmounts {
        uint256 amountAMax;
        uint256 amountBMax;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
    }

    /**
     * @notice  Calls UniswapV2Router02.addLiquidity() function using this contract's tokens.
     * @param   tokenA The first token of the Uniswap Pair to add as liquidity.
     * @param   tokenB The second token of the Uniswap Pair to add as liquidity.
     * @param   params The amounts specified to be added as liquidity. Adds exact short options.
     * @return  Returns (amountTokenA, amountTokenB, liquidity) amounts.
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        AddAmounts memory params
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return
            _router.addLiquidity(
                tokenA,
                tokenB,
                params.amountAMax,
                params.amountBMax,
                params.amountAMin,
                params.amountBMin,
                getCaller(),
                params.deadline
            );
    }

    /**
     * @dev     Combines Uniswap V2 Router "removeLiquidity" function with Primitive "closeOptions" function.
     * @notice  Pulls UNI-V2 liquidity shares with shortOption<>underlying token, and optionTokens from `getCaller()`.
     *          Then closes the longOptionTokens and withdraws underlyingTokens to the `getCaller()` address.
     *          Sends underlyingTokens from the burned UNI-V2 liquidity shares to the `getCaller()` address.
     *          UNI-V2 -> optionToken -> underlyingToken.
     * @param   optionAddress The address of the option that will be closed from burned UNI-V2 liquidity shares.
     * @param   liquidity The quantity of liquidity tokens to pull from `getCaller()` and burn.
     * @param   amountAMin The minimum quantity of shortOptionTokens to receive from removing liquidity.
     * @param   amountBMin The minimum quantity of underlyingTokens to receive from removing liquidity.
     * @return  Returns the sum of the removed underlying tokens.
     */
    function removeShortLiquidityThenCloseOptions(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    )
        public
        override
        nonReentrant
        onlyRegistered(IOption(optionAddress))
        returns (uint256)
    {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, address underlying, address redeem) =
            getOptionPair(optionToken);
        // Gets amounts struct.
        RemoveAmounts memory params;
        params.liquidity = liquidity;
        params.amountAMin = amountAMin;
        params.amountBMin = amountBMin;
        // Pulls lp tokens from `getCaller()` and pushes them to the pair in preparation to invoke `burn()`.
        _transferFromCallerToReceiver(address(pair), liquidity, address(pair));
        // Calls `burn` on the `pair`, returning amounts to this contract.
        (, uint256 underlyingAmount) = _removeLiquidity(pair, redeem, underlying, params);
        uint256 underlyingProceeds = _closeOptions(optionToken); // Returns amount of underlying tokens released.
        // Return remaining tokens/ether.
        _withdrawETH(); // Unwraps Weth and sends ether to `getCaller()`.
        _transferToCaller(redeem); // Push any remaining redeemTokens from removing liquidity (dust).
        _transferToCaller(underlying); // Pushes underlying token to `getCaller()`.
        uint256 sum = underlyingProceeds.add(underlyingAmount); // Total underlyings sent to `getCaller()`.
        emit RemoveLiquidity(getCaller(), address(optionToken), sum);
        return sum;
    }

    /**
     * @notice  Pulls LP tokens, burns them, removes liquidity, pull option token, burns then, pushes all underlying tokens.
     * @dev     Uses permit to pull LP tokens.
     * @param   optionAddress The address of the option that will be closed from burned UNI-V2 liquidity shares.
     * @param   liquidity The quantity of liquidity tokens to pull from _msgSender() and burn.
     * @param   amountAMin The minimum quantity of shortOptionTokens to receive from removing liquidity.
     * @param   amountBMin The minimum quantity of underlyingTokens to receive from removing liquidity.
     * @param   deadline The timestamp to expire a pending transaction and `permit` call.
     * @return  Returns the sum of the removed underlying tokens.
     */
    function removeShortLiquidityThenCloseOptionsWithPermit(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256) {
        IOption optionToken = IOption(optionAddress);
        (IUniswapV2Pair pair, , ) = getOptionPair(optionToken);
        pair.permit(getCaller(), address(_primitiveRouter), liquidity, deadline, v, r, s);
        return
            removeShortLiquidityThenCloseOptions(
                address(optionToken),
                liquidity,
                amountAMin,
                amountBMin
            );
    }

    struct RemoveAmounts {
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    /**
     * @notice  Calls `UniswapV2Pair.burn(address(this))` to burn LP tokens for pair tokens.
     * @param   pair The UniswapV2Pair contract to burn LP tokens of.
     * @param   tokenA The first token of the pair.
     * @param   tokenB The second token of the pair.
     * @param   params The amounts to specify the amount to remove and minAmounts to withdraw.
     * @return  Returns (amountTokenA, amountTokenB) which is (redeem, underlying) amounts.
     */
    function _removeLiquidity(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB,
        RemoveAmounts memory params
    ) internal returns (uint256, uint256) {
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (address token0, ) = CoreLib.sortTokens(tokenA, tokenB);
        (uint256 amountA, uint256 amountB) =
            tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= params.amountAMin, "PrimitiveLiquidity: INSUFFICIENT_A");
        require(amountB >= params.amountBMin, "PrimitiveLiquidity: INSUFFICIENT_B");
        return (amountA, amountB);
    }

    // ===== View =====

    /**
     * @notice  Gets the UniswapV2Router02 contract address.
     */
    function getRouter() public view override returns (IUniswapV2Router02) {
        return _router;
    }

    /**
     * @notice  Gets the UniswapV2Factory contract address.
     */
    function getFactory() public view override returns (IUniswapV2Factory) {
        return _factory;
    }

    /**
     * @notice  Fetchs the Uniswap Pair for an option's redeemToken and underlyingToken params.
     * @param   option The option token to get the corresponding UniswapV2Pair market.
     * @return  The pair address, as well as the tokens of the pair.
     */
    function getOptionPair(IOption option)
        public
        view
        override
        returns (
            IUniswapV2Pair,
            address,
            address
        )
    {
        address redeem = option.redeemToken();
        address underlying = option.getUnderlyingTokenAddress();
        IUniswapV2Pair pair = IUniswapV2Pair(_factory.getPair(redeem, underlying));
        return (pair, underlying, redeem);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {
    IUniswapV2Factory
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IOption} from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

interface IPrimitiveLiquidity {
    // ==== External ====

    function addShortLiquidityWithUnderlying(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function addShortLiquidityWithETH(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256,
            uint256,
            uint256
        );

    function addShortLiquidityWithUnderlyingWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function addShortLiquidityDAIWithPermit(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeShortLiquidityThenCloseOptions(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256);

    function removeShortLiquidityThenCloseOptionsWithPermit(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256);

    // ==== View ====

    function getRouter() external view returns (IUniswapV2Router02);

    function getFactory() external view returns (IUniswapV2Factory);

    function getOptionPair(IOption option)
        external
        view
        returns (
            IUniswapV2Pair,
            address,
            address
        );
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   TestERC20
 * @author  Primitive
 * @notice  An opinionated ERC20 with `permit` to use ONLY for testing.
 * @dev     @primitivefi/[email protected]
 */

import {IERC20Permit} from "../interfaces/IERC20Permit.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract TestERC20 {
    using SafeMath for uint256;

    string public name = "Test Token";
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) public {
        name = name_;
        symbol = symbol_;
        _mint(msg.sender, initialSupply);
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name_)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Primitive: EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Primitive: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Router
 * @author  Primitive
 * @notice  Contract to execute Primitive Connector functions.
 * @dev     @primitivefi/[email protected]
 */

// Open Zeppelin
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {
    IPrimitiveRouter,
    IRegistry,
    IOption,
    IERC20,
    IWETH
} from "./interfaces/IPrimitiveRouter.sol";

/**
 * @notice  Used to execute calls on behalf of the Router contract.
 * @dev     Changes `msg.sender` context so the Router is not `msg.sender`.
 */
contract Route {
    function executeCall(address target, bytes calldata params) external payable {
        (bool success, bytes memory returnData) = target.call.value(msg.value)(params);
        require(success, "Route: EXECUTION_FAIL");
    }
}

contract PrimitiveRouter is IPrimitiveRouter, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data.
    using SafeMath for uint256; // Reverts on math underflows/overflows.

    // Constants
    address private constant _NO_CALLER = address(0x0); // Default state for `_CALLER`.

    // Events
    event Initialized(address indexed from); // Emmitted on deployment
    event Executed(address indexed from, address indexed to, bytes params);
    event RegisteredOptions(address[] indexed options);
    event RegisteredConnectors(address[] indexed connectors, bool[] registered);

    // State variables
    IRegistry private _registry; // The Primitive Registry which deploys Option clones.
    IWETH private _weth; // Canonical WETH9
    Route private _route; // Intermediary to do connector.call() from.
    address private _CONNECTOR = _NO_CALLER; // If _EXECUTING, the `connector` of the execute call param.
    address private _CALLER = _NO_CALLER; // If _EXECUTING, the orginal `_msgSender()` of the execute call.
    bool private _EXECUTING; // True if the `executeCall` function was called.

    // Whitelisted mappings
    mapping(address => bool) private _registeredConnectors;
    mapping(address => bool) private _registeredOptions;

    /**
     * @notice  A mutex to use during an `execute` call.
     * @dev     Checks to make sure the `_CONNECTOR` in state is the `msg.sender`.
     *          Checks to make sure a `_CALLER` was set.
     *          Fails if this modifier is triggered by an external call.
     *          Fails if this modifier is triggered by calling a function without going through `executeCall`.
     */
    modifier isExec() {
        require(_CONNECTOR == _msgSender(), "Router: NOT_CONNECTOR");
        require(_CALLER != _NO_CALLER, "Router: NO_CALLER");
        require(!_EXECUTING, "Router: IN_EXECUTION");
        _EXECUTING = true;
        _;
        _EXECUTING = false;
    }

    // ===== Constructor =====

    constructor(address weth_, address registry_) public {
        require(address(_weth) == address(0x0), "Router: INITIALIZED");
        _route = new Route();
        _weth = IWETH(weth_);
        _registry = IRegistry(registry_);
        emit Initialized(_msgSender());
    }

    // ===== Pausability =====

    /**
     * @notice  Halts use of `executeCall`, and other functions that change state.
     */
    function halt() external override onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    // ===== Registration =====

    /**
     * @notice  Checks option against Primitive Registry. If from Registry, registers as true.
     *          NOTE: Purposefully does not have `onlyOwner` modifier.
     * @dev     Sets `optionAddresses` to true in the whitelisted options mapping, if from Registry.
     * @param   optionAddresses The array of option addresses to update.
     */
    function setRegisteredOptions(address[] calldata optionAddresses)
        external
        override
        returns (bool)
    {
        uint256 len = optionAddresses.length;
        for (uint256 i = 0; i < len; i++) {
            address option = optionAddresses[i];
            require(isFromPrimitiveRegistry(IOption(option)), "Router: EVIL_OPTION");
            _registeredOptions[option] = true;
        }
        emit RegisteredOptions(optionAddresses);
        return true;
    }

    /**
     * @notice  Allows the `owner` to set whitelisted connector contracts.
     * @dev     Sets `connectors` to `isValid` in the whitelisted connectors mapping.
     * @param   connectors The array of option addresses to update.
     * @param   isValid Whether or not the optionAddress is registered.
     */
    function setRegisteredConnectors(address[] memory connectors, bool[] memory isValid)
        public
        override
        onlyOwner
        returns (bool)
    {
        uint256 len = connectors.length;
        require(len == isValid.length, "Router: LENGTHS");
        for (uint256 i = 0; i < len; i++) {
            address connector = connectors[i];
            bool status = isValid[i];
            _registeredConnectors[connector] = status;
        }
        emit RegisteredConnectors(connectors, isValid);
        return true;
    }

    /**
     * @notice  Checks an option against the Primitive Registry.
     * @param   option The IOption token to check.
     * @return  Whether or not the option was deployed from the Primitive Registry.
     */
    function isFromPrimitiveRegistry(IOption option) internal view returns (bool) {
        return (address(option) ==
            _registry.getOptionAddress(
                option.getUnderlyingTokenAddress(),
                option.getStrikeTokenAddress(),
                option.getBaseValue(),
                option.getQuoteValue(),
                option.getExpiryTime()
            ) &&
            address(option) != address(0));
    }

    // ===== Operations =====

    /**
     * @notice  Transfers ERC20 tokens from the executing `_CALLER` to the executing `_CONNECTOR`.
     * @param   token The address of the ERC20.
     * @param   amount The amount of ERC20 to transfer.
     * @return  Whether or not the transfer succeeded.
     */
    function transferFromCaller(address token, uint256 amount)
        public
        override
        isExec
        whenNotPaused
        returns (bool)
    {
        IERC20(token).safeTransferFrom(
            getCaller(), // Account to pull from
            _msgSender(), // The connector
            amount
        );
        return true;
    }

    /**
     * @notice  Transfers ERC20 tokens from the executing `_CALLER` to an arbitrary address.
     * @param   token The address of the ERC20.
     * @param   amount The amount of ERC20 to transfer.
     * @return  Whether or not the transfer succeeded.
     */
    function transferFromCallerToReceiver(
        address token,
        uint256 amount,
        address receiver
    ) public override isExec whenNotPaused returns (bool) {
        IERC20(token).safeTransferFrom(
            getCaller(), // Account to pull from
            receiver,
            amount
        );
        return true;
    }

    // ===== Execute =====

    /**
     * @notice  Executes a call with `params` to the target `connector` contract from `_route`.
     * @param   connector The Primitive Connector module to call.
     * @param   params The encoded function data to use.
     */
    function executeCall(address connector, bytes calldata params)
        external
        payable
        override
        whenNotPaused
    {
        require(_registeredConnectors[connector], "Router: INVALID_CONNECTOR");
        _CALLER = _msgSender();
        _CONNECTOR = connector;
        _route.executeCall.value(msg.value)(connector, params);
        _CALLER = _NO_CALLER;
        _CONNECTOR = _NO_CALLER;
        emit Executed(_msgSender(), connector, params);
    }

    // ===== Fallback =====

    receive() external payable whenNotPaused {
        assert(_msgSender() == address(_weth)); // only accept ETH via fallback from the WETH contract
    }

    // ===== View =====

    /**
     * @notice  Returns the IWETH contract address.
     */
    function getWeth() public view override returns (IWETH) {
        return _weth;
    }

    /**
     * @notice  Returns the Route contract which executes functions on behalf of this contract.
     */
    function getRoute() public view override returns (address) {
        return address(_route);
    }

    /**
     * @notice  Returns the `_CALLER` which is set to `_msgSender()` during an `executeCall` invocation.
     */
    function getCaller() public view override returns (address) {
        return _CALLER;
    }

    /**
     * @notice  Returns the Primitive Registry contract address.
     */
    function getRegistry() public view override returns (IRegistry) {
        return _registry;
    }

    /**
     * @notice  Returns a bool if `option` is registered or not.
     * @param   option The address of the Option to check if registered.
     */
    function getRegisteredOption(address option) external view override returns (bool) {
        return _registeredOptions[option];
    }

    /**
     * @notice  Returns a bool if `connector` is registered or not.
     * @param   connector The address of the Connector contract to check if registered.
     */
    function getRegisteredConnector(address connector)
        external
        view
        override
        returns (bool)
    {
        return _registeredConnectors[connector];
    }

    /**
     * @notice  Returns the NPM package version and github version of this contract.
     * @dev     For the npm package: @primitivefi/v1-connectors
     *          For the repository: github.com/primitivefinance/primitive-v1-connectors
     * @return  The apiVersion string.
     */
    function apiVersion() public pure override returns (string memory) {
        return "2.0.0";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

import {IOption} from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";
import {IERC20Permit} from "./IERC20Permit.sol";

interface IPrimitiveCore {
    // ===== External =====

    function safeMintWithETH(IOption optionToken)
        external
        payable
        returns (uint256, uint256);

    function safeMintWithPermit(
        IOption optionToken,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256, uint256);

    function safeExerciseWithETH(IOption optionToken)
        external
        payable
        returns (uint256, uint256);

    function safeExerciseForETH(IOption optionToken, uint256 exerciseQuantity)
        external
        returns (uint256, uint256);

    function safeRedeemForETH(IOption optionToken, uint256 redeemQuantity)
        external
        returns (uint256);

    function safeCloseForETH(IOption optionToken, uint256 closeQuantity)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT
// Copyright 2021 Primitive Finance
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

pragma solidity 0.6.2;

/**
 * @title   Primitive Core
 * @author  Primitive
 * @notice  A Connector with Ether abstractions for Primitive Option tokens.
 * @dev     @primitivefi/[email protected]
 */

// Open Zeppelin
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// Primitive
import {CoreLib, SafeMath} from "../libraries/CoreLib.sol";
import {IPrimitiveCore, IERC20Permit, IOption} from "../interfaces/IPrimitiveCore.sol";
import {PrimitiveConnector} from "./PrimitiveConnector.sol";

contract PrimitiveCore is PrimitiveConnector, IPrimitiveCore, ReentrancyGuard {
    using SafeERC20 for IERC20; // Reverts when `transfer` or `transferFrom` erc20 calls don't return proper data
    using SafeMath for uint256; // Reverts on math underflows/overflows

    event Initialized(address indexed from); // Emmitted on deployment
    event Minted(
        address indexed from,
        address indexed option,
        uint256 longQuantity,
        uint256 shortQuantity
    );
    event Exercised(address indexed from, address indexed option, uint256 quantity);
    event Redeemed(address indexed from, address indexed option, uint256 quantity);
    event Closed(address indexed from, address indexed option, uint256 quantity);

    // ===== Constructor =====

    constructor(address weth_, address primitiveRouter_)
        public
        PrimitiveConnector(weth_, primitiveRouter_)
    {
        emit Initialized(_msgSender());
    }

    // ===== Weth Abstraction =====

    /**
     * @dev     Mints msg.value quantity of options and "quote" (option parameter) quantity of redeem tokens.
     * @notice  This function is for options that have WETH as the underlying asset.
     * @param   optionToken The address of the option token to mint.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function safeMintWithETH(IOption optionToken)
        external
        payable
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (uint256, uint256)
    {
        require(msg.value > 0, "PrimitiveCore: ERR_ZERO");
        address caller = getCaller();
        _depositETH(); // Deposits `msg.value` to Weth contract.
        (uint256 long, uint256 short) = _mintOptionsToReceiver(optionToken, caller);
        emit Minted(caller, address(optionToken), long, short);
        return (long, short);
    }

    /**
     * @dev     Mints "amount" quantity of options and "quote" (option parameter) quantity of redeem tokens.
     * @notice  This function is for options that have an EIP2612 (permit) enabled token as the underlying asset.
     * @param   optionToken The address of the option token to mint.
     * @param   amount The quantity of options to mint.
     * @param   deadline The timestamp which expires the `permit` call.
     * @return  (uint, uint) Returns the (long, short) option tokens minted
     */
    function safeMintWithPermit(
        IOption optionToken,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (uint256, uint256)
    {
        // Permit minting using the caller's underlying tokens.
        IERC20Permit(optionToken.getUnderlyingTokenAddress()).permit(
            getCaller(),
            address(_primitiveRouter),
            amount,
            deadline,
            v,
            r,
            s
        );
        (uint256 long, uint256 short) = _mintOptionsFromCaller(optionToken, amount);
        emit Minted(getCaller(), address(optionToken), long, short);
        return (long, short);
    }

    /**
     * @dev     Swaps msg.value of strikeTokens (ethers) to underlyingTokens.
     *          Uses the strike ratio as the exchange rate. Strike ratio = base / quote.
     *          Msg.value (quote units) * base / quote = base units (underlyingTokens) to withdraw.
     * @notice  This function is for options with WETH as the strike asset.
     *          Burns option tokens, accepts ethers, and pushes out underlyingTokens.
     * @param   optionToken The address of the option contract.
     */
    function safeExerciseWithETH(IOption optionToken)
        public
        payable
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (uint256, uint256)
    {
        require(msg.value > 0, "PrimitiveCore: ZERO");

        _depositETH(); // Deposits `msg.value` to Weth contract.

        uint256 long = CoreLib.getProportionalLongOptions(optionToken, msg.value);
        _transferFromCaller(address(optionToken), long); // Pull option tokens.

        // Pushes option tokens and weth (strike asset), receives underlying tokens.
        emit Exercised(getCaller(), address(optionToken), long);
        return _exerciseOptions(optionToken, long);
    }

    /**
     * @dev     Swaps strikeTokens to underlyingTokens, WETH, which is converted to ethers before withdrawn.
     *          Uses the strike ratio as the exchange rate. Strike ratio = base / quote.
     * @notice  This function is for options with WETH as the underlying asset.
     *          Burns option tokens, pulls strikeTokens, and pushes out ethers.
     * @param   optionToken The address of the option contract.
     * @param   exerciseQuantity Quantity of optionTokens to exercise.
     */
    function safeExerciseForETH(IOption optionToken, uint256 exerciseQuantity)
        public
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (uint256, uint256)
    {
        address underlying = optionToken.getUnderlyingTokenAddress();
        address strike = optionToken.getStrikeTokenAddress();
        uint256 strikeQuantity =
            CoreLib.getProportionalShortOptions(optionToken, exerciseQuantity);
        // Pull options and strike assets from `getCaller()` and send to option contract.
        _transferFromCallerToReceiver(
            address(optionToken),
            exerciseQuantity,
            address(optionToken)
        );
        _transferFromCallerToReceiver(strike, strikeQuantity, address(optionToken));

        // Release underlying tokens by invoking `exerciseOptions()`
        (uint256 strikesPaid, uint256 options) =
            optionToken.exerciseOptions(address(this), exerciseQuantity, new bytes(0));
        _withdrawETH(); // Unwraps this contract's balance of Weth and sends to `getCaller()`.
        emit Exercised(getCaller(), address(optionToken), exerciseQuantity);
        return (strikesPaid, options);
    }

    /**
     * @dev     Burns redeem tokens to withdraw strike tokens (ethers) at a 1:1 ratio.
     * @notice  This function is for options that have WETH as the strike asset.
     *          Converts WETH to ethers, and withdraws ethers to the receiver address.
     * @param   optionToken The address of the option contract.
     * @param   redeemQuantity The quantity of redeemTokens to burn.
     */
    function safeRedeemForETH(IOption optionToken, uint256 redeemQuantity)
        public
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (uint256)
    {
        // Require the strike token to be Weth.
        address redeem = optionToken.redeemToken();
        // Pull redeem tokens from `getCaller()` and send to option contract.
        _transferFromCallerToReceiver(redeem, redeemQuantity, address(optionToken));
        uint256 short = optionToken.redeemStrikeTokens(address(this));
        _withdrawETH(); // Unwraps this contract's balance of Weth and sends to `getCaller()`.
        emit Redeemed(getCaller(), address(optionToken), redeemQuantity);
        return short;
    }

    /**
     * @dev Burn optionTokens and redeemTokens to withdraw underlyingTokens (ethers).
     * @notice This function is for options with WETH as the underlying asset.
     * WETH underlyingTokens are converted to ethers before being sent to receiver.
     * The redeemTokens to burn is equal to the optionTokens * strike ratio.
     * inputOptions = inputRedeems / strike ratio = outUnderlyings
     * @param optionToken The address of the option contract.
     * @param closeQuantity Quantity of optionTokens to burn and an input to calculate how many redeems to burn.
     */
    function safeCloseForETH(IOption optionToken, uint256 closeQuantity)
        public
        override
        nonReentrant
        onlyRegistered(optionToken)
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address redeem = optionToken.redeemToken();
        uint256 short = CoreLib.getProportionalShortOptions(optionToken, closeQuantity);
        // Pull redeem tokens from `getCaller()` and send to option contract.
        _transferFromCallerToReceiver(redeem, short, address(optionToken));
        // Pull options if not expired, and send to option contract.
        if (optionToken.getExpiryTime() >= now) {
            _transferFromCallerToReceiver(
                address(optionToken),
                closeQuantity,
                address(optionToken)
            );
        }
        // Release underlyingTokens by invoking `closeOptions()`
        (uint256 inputRedeems, uint256 inputOptions, uint256 outUnderlyings) =
            optionToken.closeOptions(address(this));

        _withdrawETH(); // Unwraps this contract's balance of Weth and sends to `getCaller()`.
        emit Closed(getCaller(), address(optionToken), closeQuantity);
        return (inputRedeems, inputOptions, outUnderlyings);
    }
}