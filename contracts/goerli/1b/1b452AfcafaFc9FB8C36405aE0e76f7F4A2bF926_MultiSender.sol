//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSender {
    event SendETH(address indexed from, address indexed to, uint256 amount);

    function sendETH(
        uint256[] memory amounts,
        address payable[] memory recipients
    ) public payable {
        require(
            amounts.length == recipients.length,
            "amounts length is not equal to recipients length"
        );

        uint256 totalPaid = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            totalPaid += amounts[i];
            require(
                msg.value <= totalPaid,
                "value payable in ether exceeds amount send to recipients"
            );
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Transfer failed.");
            emit SendETH(msg.sender, recipients[i], amounts[i]);
        }
    }

    function sendERC20(
        address[] memory tokenAddresses,
        uint256[] memory amounts,
        address payable[] memory recipients
    ) public {
        require(
            tokenAddresses.length == amounts.length,
            "tokens length is not equal to amounts length"
        );

        require(
            amounts.length == recipients.length,
            "amounts length is not equal to recipients length"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            bool success = token.transferFrom(
                msg.sender,
                recipients[i],
                amounts[i]
            );
            require(success, "Transfer failed.");
        }
    }

    function sendETHAndERC20(
        address[] memory tokenAddresses,
        uint256[] memory amounts,
        address payable[] memory recipients
    ) public payable {
        require(
            tokenAddresses.length == amounts.length,
            "tokens length is not equal to amounts length"
        );

        require(
            amounts.length == recipients.length,
            "amounts length is not equal to recipients length"
        );

        uint256 totalPaid = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (tokenAddresses[i] != address(0)) {
                IERC20 token = IERC20(tokenAddresses[i]);
                bool success = token.transferFrom(
                    msg.sender,
                    recipients[i],
                    amounts[i]
                );
                require(success, "Transfer failed.");
            } else {
                totalPaid += amounts[i];
                require(
                    msg.value <= totalPaid,
                    "value payable in ether exceeds amount send to recipients"
                );
                (bool success, ) = recipients[i].call{value: amounts[i]}("");
                require(success, "Transfer failed.");
                emit SendETH(msg.sender, recipients[i], amounts[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}