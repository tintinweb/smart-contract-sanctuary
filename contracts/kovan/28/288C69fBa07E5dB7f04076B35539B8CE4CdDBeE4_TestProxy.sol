// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

 enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

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


interface Vault {
    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest memory request
    ) external;
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
        string[] weights;
        string swapFeePercentage;
        address owner;
    }

    function readVault() external view returns (address, PoolSpecialization) {
        return Vault(VaultAddress).getPool(0xd413c9a395a028887f551cebe00f5df6ecbfbe830002000000000000000001ea);
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