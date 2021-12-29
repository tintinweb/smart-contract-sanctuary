/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.6.0 <0.9.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title MultiSender
 * @author Chandra Shekhar Choudhary
 * @dev need to create instance of erc20 contract
 */
contract MultiSenderERC20 {
    IERC20 erc20Instacne;

    /**
     * @notice This function is use to transfer erc20 token on multiple account at same time.
     * @dev need to create instance of erc20 contract
     * @param erc20 token address
     * @param receivers addresses of receivers
     * @param amounts token amounts to send
     */
    function SendeToMultiple(
        address erc20,
        address[] memory receivers,
        uint256[] memory amounts
    ) public {
        erc20Instacne = IERC20(erc20);
        require(
            receivers.length == amounts.length,
            "amount and reciver address length is not correct"
        );
        uint256 totalAmnt = sum(amounts);

        require(
            erc20Instacne.allowance(msg.sender, address(this)) >= totalAmnt,
            "insufficent allowance"
        );
        erc20Instacne.transferFrom(msg.sender, address(this), totalAmnt);

        for (uint256 i = 0; i < receivers.length; i++) {
            require(
                msg.sender != receivers[i] && receivers[i] != address(0),
                "receiver address is incorrect "
            );
            transferFromThis(erc20, receivers[i], amounts[i]);
        }
    }

    /**
     * @notice This function is use to calculate the sum of  amounts list .
     * @dev use this function in SendeToMultiple to calculate the sum of amounts
     * @param amounts token amounts to calculate the sum of amounts list
     */
    function sum(uint256[] memory amounts)
        private
        pure
        returns (uint256 retVal)
    {
        // the value of message should be exact of total amounts
        uint256 totalAmnt = 0;

        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }

        return totalAmnt;
    }

    /**
     * @notice This function is use to tranfer erc20Token from contract address.
     * @dev use this function in SendeToMultiple to transfer amounts in receivers list
     * @param erc20Token   erc20Token contract address
     * @param receiverAddr  recivers list
     * @param receiverAmnt  amounts list
     */
    function transferFromThis(
        address erc20Token,
        address receiverAddr,
        uint256 receiverAmnt
    ) private {
        erc20Instacne = IERC20(erc20Token);
        erc20Instacne.transfer(receiverAddr, receiverAmnt);
    }
}