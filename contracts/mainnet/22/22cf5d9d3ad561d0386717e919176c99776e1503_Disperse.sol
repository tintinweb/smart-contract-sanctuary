/**
 *Submitted for verification at Etherscan.io on 2021-01-14
*/

pragma solidity ^0.6.12;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract Disperse {

    function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]*10**18));
    }
}