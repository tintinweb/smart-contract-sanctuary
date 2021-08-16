/**
 *Submitted for verification at BscScan.com on 2021-08-15
*/

/**
 *Submitted for verification at BscScan.com on 2020-09-14
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Disperse {
    event LogUint(string, uint);
    function disperseEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0) {
            LogUint("bslance", balance);
            msg.sender.transfer(balance);
        }
    }

    function disperseToken(IERC20 token, address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function test(IERC20 token, address sender, address receiver, uint256 value) external {
            require(token.transferFrom(sender, receiver, value));
    }
}