/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.11;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    event PoolCreated(
        address indexed pool,
        address indexed delegate,
        address liquidityAsset,
        address stakeAsset,
        address liquidityLocker,
        address stakeLocker,
        uint256 stakingFee,
        uint256 delegateFee,
        uint256 liquidityCap,
        string  name,
        string  symbol
    );

    function createPool(
        address liquidityAsset,
        address stakeAsset,
        address slFactory,
        address llFactory,
        uint256 stakingFee,
        uint256 delegateFee,
        uint256 liquidityCap
    ) external returns (address poolAddress) {
        

        string memory name   = "Maple Pool Token";
        string memory symbol = "MPL-LP";
        poolAddress = 0x735C5229B6EdC09650E2011b3cCB04de106b7961;
        
        emit PoolCreated(
            poolAddress,
            msg.sender,
            liquidityAsset,
            stakeAsset,
            poolAddress,
            poolAddress,
            stakingFee,
            delegateFee,
            liquidityCap,
            name,
            symbol
        );
    }
}