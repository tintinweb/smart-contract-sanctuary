/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity 0.8.7;

interface IERC20Metadata {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract BatchBalance {
    function balanceFor(address[] memory _tokens, address _account)
        external
        view
        returns (uint256[] memory balances, uint256[] memory decimals)
    {
        balances = new uint256[](_tokens.length);
        decimals = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            balances[i] = IERC20Metadata(_tokens[i]).balanceOf(_account);
            decimals[i] = IERC20Metadata(_tokens[i]).decimals();
        }
        return (balances, decimals);
    }
}