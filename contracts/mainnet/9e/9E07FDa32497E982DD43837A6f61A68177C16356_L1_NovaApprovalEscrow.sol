// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.7.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Escrow contract for relayers to approve input tokens to.
/// @dev Used by the L1_NovaExecutionManager to safely transfer tokens from relayers to strategies.
contract L1_NovaApprovalEscrow {
    /// @notice The address who is authorized to transfer tokens from the approval escrow.
    /// @dev Initializing it as msg.sender here is equivalent to setting it in the constructor.
    address public immutable ESCROW_ADMIN = msg.sender;

    /// @notice Transfers a token approved to the escrow.
    /// @notice Only the escrow admin can call this function.
    /// @param token The token to transfer.
    /// @param amount The amount of the token to transfer.
    /// @param sender The user who approved the token to the escrow.
    /// @param recipient The address to transfer the approved tokens to.
    /// @return A bool indicating if the transfer succeeded or not.
    function transferApprovedToken(
        address token,
        uint256 amount,
        address sender,
        address recipient
    ) external returns (bool) {
        // Ensure the caller is the escrow admin.
        require(ESCROW_ADMIN == msg.sender, "UNAUTHORIZED");

        // Transfer tokens from the sender to the recipient.
        (bool success, bytes memory returnData) = address(token).call(
            abi.encodeWithSelector(
                // The token to transfer:
                IERC20(token).transferFrom.selector,
                // The address who approved tokens to the escrow:
                sender,
                // The address who should receive the tokens:
                recipient,
                // The amount of tokens to transfer to the recipient:
                amount
            )
        );

        if (!success) {
            // If it reverted, return false
            // to indicate the transfer failed.
            return false;
        }

        if (returnData.length > 0) {
            // An abi-encoded bool takes up 32 bytes.
            if (returnData.length == 32) {
                // Return false to indicate failure if
                // the return data was not a positive bool.
                return abi.decode(returnData, (bool));
            } else {
                // It returned some data that was not a bool,
                // return false to indicate the transfer failed.
                return false;
            }
        }

        // If there was no failure,
        // return true to indicate success.
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

