/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at BscScan.com on 2020-10-09
*/

pragma solidity ^0.5.0;

contract BatchGetter {
    constructor() public {}

    function balancesOf(address[] calldata addresses)
        external view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }
}