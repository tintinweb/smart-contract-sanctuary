/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.5.0;


contract Ether {
    function balanceOf(address wallet) external view returns (uint256) {
        return wallet.balance;
    }
}