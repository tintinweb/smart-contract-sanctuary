/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract CalypsoPay {
    event PayETH(uint256 amount, address companyAddress, uint id);
    event PayToken(address tokenAddress, uint256 amount, address companyAddress, uint id);


    function pay_ETH(address companyAddress, uint id) payable external {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = companyAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit PayETH(msg.value, companyAddress, id);
    }

    function pay_Token(address tokenAddress, uint256 amount, address companyAddress, uint id) external {
        IERC20 token = IERC20(tokenAddress);

        bool sent = token.transferFrom(address(this), companyAddress, amount);
        require(sent, "Failed to send Token");

        emit PayToken(tokenAddress, amount, companyAddress, id);
    }


}