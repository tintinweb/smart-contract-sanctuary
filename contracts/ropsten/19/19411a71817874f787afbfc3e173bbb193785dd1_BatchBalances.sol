/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

pragma solidity ^0.6.0;

interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);
}

contract BatchBalances {

    /* Get account eth balances */
    function balancesOf(address[] memory addrs) public view returns (uint256 blockNumber, uint256 totalBalance, uint256[] memory balances) {
        balances = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            balances[i] = addrs[i].balance;
            totalBalance += balances[i];
        }
        blockNumber = block.number;
    }

    /* Get account token balances */
    function tokenBalancesOf(IERC20 _token, address[] memory addrs) public view returns (uint256 blockNumber, uint256 totalBalance, uint256[] memory balances) {
        balances = new uint256[](addrs.length);
        for (uint256 i = 0; i < addrs.length; i++) {
            balances[i] = _token.balanceOf(addrs[i]);
            totalBalance += balances[i];
        }
        blockNumber = block.number;
    }
}