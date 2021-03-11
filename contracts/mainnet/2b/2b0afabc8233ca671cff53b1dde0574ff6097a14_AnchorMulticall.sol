/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

//SPDX-License-Identifier: None

// File contracts/interfaces/IComptroller.sol

pragma solidity ^0.8.0;

interface IComptroller {
    function getAccountLiquidity(address account) external view returns (uint256, uint256, uint256);
}


// File contracts/AnchorMulticall.sol

pragma solidity ^0.8.0;
contract AnchorMulticall {
    IComptroller public comptroller =
        IComptroller(0x4dCf7407AE5C07f8681e1659f626E114A7667339);

    function getAccountsLiquidity(address[] calldata accounts)
        external
        view
        returns (uint256[] memory statuses)
    {
        statuses = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            (, , uint256 shortfall) =
                comptroller.getAccountLiquidity(accounts[i]);
            statuses[i] = shortfall;
        }
    }
}