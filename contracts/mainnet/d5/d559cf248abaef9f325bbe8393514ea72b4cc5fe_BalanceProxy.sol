/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity 0.8.4;


interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256 balance);
}


interface BalanceProxyInterface {
    function balance(address account) external view returns (uint256 balance);
    function balanceOf(ERC20Interface token, address account) external view returns (uint256 balance);
}


contract BalanceProxy is BalanceProxyInterface {
    function balance(address account) external view override returns (uint256 balance) {
        balance = account.balance;
    }

    function balanceOf(ERC20Interface token, address account) external view override returns (uint256 balance) {
        balance = token.balanceOf(account);
    }
}