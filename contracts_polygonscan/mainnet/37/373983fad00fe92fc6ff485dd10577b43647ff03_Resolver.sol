/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File contracts/interfaces/ITreasury.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getTombPrice() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;

    function allocateSeigniorage() external;
}


// File contracts/interfaces/IResolver.sol


interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}


// File contracts/Resolver.sol



contract Resolver is IResolver {

    address public treasury;

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 nextEpochPoint = ITreasury(treasury).nextEpochPoint();

        canExec = block.timestamp > nextEpochPoint;

        execPayload = abi.encodeWithSelector(
            ITreasury(treasury).allocateSeigniorage.selector
        );
    }
}