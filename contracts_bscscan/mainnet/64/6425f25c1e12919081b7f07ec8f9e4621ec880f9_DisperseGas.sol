/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/


pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract DisperseGas {
    function disperseEther(address[] recipients, uint256 value) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function disperseToken(IERC20 token, address[] recipients, uint256 value) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += value;
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], value));
    }
}