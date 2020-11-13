/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./Address.sol";
import "./Erc20Interface.sol";

/**
 * @title SafeErc20.sol
 * @author Paul Razvan Berg
 * @notice Wraps around Erc20 operations that throw on failure (when the token contract
 * returns false). Tokens that return no value (and instead revert or throw
 * on failure) are also supported, non-reverting calls are assumed to be successful.
 *
 * To use this library you can add a `using SafeErc20 for Erc20Interface;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 *
 * @dev Forked from OpenZeppelin
 * https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.1.0/contracts/utils/Address.sol
 */
library SafeErc20 {
    using Address for address;

    /**
     * INTERNAL FUNCTIONS
     */

    function safeTransfer(
        Erc20Interface token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        Erc20Interface token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * PRIVATE FUNCTIONS
     */

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it cannot be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(Erc20Interface token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = functionCallWithValue(address(token), data, "ERR_SAFE_ERC20_LOW_LEVEL_CALL");
        if (returndata.length > 0) {
            /* Return data is optional. */
            require(abi.decode(returndata, (bool)), "ERR_SAFE_ERC20_ERC20_OPERATION");
        }
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(target.isContract(), "ERR_SAFE_ERC20_CALL_TO_NON_CONTRACT");

        /* solhint-disable-next-line avoid-low-level-calls */
        (bool success, bytes memory returndata) = target.call(data);
        if (success) {
            return returndata;
        } else {
            /* Look for revert reason and bubble it up if present */
            if (returndata.length > 0) {
                /* The easiest way to bubble the revert reason is using memory via assembly. */

                /* solhint-disable-next-line no-inline-assembly */
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
