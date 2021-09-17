/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

/**
██████╗░██╗░██████╗██████╗░███████╗███╗░░██╗░██████╗███████╗██████╗░
██╔══██╗██║██╔════╝██╔══██╗██╔════╝████╗░██║██╔════╝██╔════╝██╔══██╗
██║░░██║██║╚█████╗░██████╔╝█████╗░░██╔██╗██║╚█████╗░█████╗░░██████╔╝
██║░░██║██║░╚═══██╗██╔═══╝░██╔══╝░░██║╚████║░╚═══██╗██╔══╝░░██╔══██╗
██████╔╝██║██████╔╝██║░░░░░███████╗██║░╚███║██████╔╝███████╗██║░░██║
╚═════╝░╚═╝╚═════╝░╚═╝░░░░░╚══════╝╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝

by Conductive Research 

We bring together everything that’s required to build token utility

Work with us 👉 https://www.conductiveresearch.com

Follow us on twitter: @0xConductive

*/

pragma solidity ^0.4.25;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Dispenser {
    function dispenseEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function dispenseToken(IERC20 token, address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function dispenseTokenSimple(IERC20 token, address[] recipients, uint256[] values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}