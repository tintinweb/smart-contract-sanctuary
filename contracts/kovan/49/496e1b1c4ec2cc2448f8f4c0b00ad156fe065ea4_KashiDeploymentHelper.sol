/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IKashiPair {
    function updateExchangeRate() external returns (bool updated, uint256 rate);
}

interface IBentoBox {
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (IKashiPair cloneAddress);
}

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title KashiDeploymentHelper
contract KashiDeploymentHelper {
    IBentoBox immutable public bentoBox;

    constructor(IBentoBox _bentoBox) public {
        bentoBox = _bentoBox;
    }
    function deploy(address masterContract, bytes calldata initData, bool useCreate2) public returns (address) {
        IKashiPair clone = bentoBox.deploy(masterContract, initData, useCreate2);
        clone.updateExchangeRate();
    }
}