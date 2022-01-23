/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

pragma solidity >=0.5.0;

contract EthBalanceGetter {
    function balanceOf(address account) external view returns (uint256) {
        return account.balance;
    }
}