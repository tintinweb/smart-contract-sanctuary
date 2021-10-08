// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface LBPFactory {
    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        string[] memory weights,
        string memory swapFeePercentage,
        address owner,
        bool swapEnabledOnStart
    ) external returns (address);
}

contract TestProxy {
    address public constant VaultAddress = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    mapping(address => address) public poolOwner;

    address public immutable feeRecipient;
    address public immutable LBPFactoryAddress;

    constructor(address _feeRecipient, address _LBPFactoryAddress) {
        feeRecipient = _feeRecipient;
        LBPFactoryAddress = _LBPFactoryAddress;
    }

    struct PoolLBPFactoryConfig {
        string name;
        string symbol;
        address[] tokens;
        uint256[] amounts;
        string[] weights;
        string swapFeePercentage;
        address owner;
    }

    function noTransferCreateLBPFactoryFromProxy(PoolLBPFactoryConfig memory poolLBPFactoryConfig) external {
        address pool = LBPFactory(LBPFactoryAddress).create(
            poolLBPFactoryConfig.name,
            poolLBPFactoryConfig.symbol,
            poolLBPFactoryConfig.tokens,
            poolLBPFactoryConfig.weights,
            poolLBPFactoryConfig.swapFeePercentage,
            address(this), // owner set to this proxy
            false // swaps disabled on start
        );
        poolOwner[pool] = poolLBPFactoryConfig.owner;
    }
}