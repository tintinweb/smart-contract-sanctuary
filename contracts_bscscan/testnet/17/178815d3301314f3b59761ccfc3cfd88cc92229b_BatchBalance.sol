/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity 0.8.7;

interface IBalance {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract BatchBalance {
    function balanceOf(address[] memory _tokens, address _account)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            balances[i] = IBalance(_tokens[i]).balanceOf(_account);
        }
        return balances;
    }
}