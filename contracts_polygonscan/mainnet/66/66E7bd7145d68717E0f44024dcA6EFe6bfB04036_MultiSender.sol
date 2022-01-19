// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _value) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
}

contract MultiSender {
    function send(address[] memory addresses, uint256[] memory amounts)
        public
        payable
    {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(msg.value >= totalAmount, "Insufficient funds");

        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(amounts[i]);
        }
        if (msg.value > totalAmount) {
            payable(msg.sender).transfer(msg.value - totalAmount);
        }
    }

    function sendToken(
        address[] memory addresses,
        uint256[] memory amounts,
        address tokenAddress
    ) public {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        token.transferFrom(msg.sender, address(this), totalAmount);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], amounts[i]);
        }
    }
}