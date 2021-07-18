// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IStakeContractFactory.sol";
import "../interfaces/IStakeTONProxyFactory.sol";

/// @title A factory that creates a stake contract that can stake TON
contract StakeTONFactory is IStakeContractFactory {
    address public stakeTONProxyFactory;
    address public stakeTONLogic;

    /// @dev constructor of StakeTONFactory
    /// @param _stakeTONProxyFactory the StakeTONProxyFactory address used in StakeTONFactory
    /// @param _stakeTONLogic the StakeTONLogic address used in StakeTONFactory
    constructor(address _stakeTONProxyFactory, address _stakeTONLogic) {
        require(
            _stakeTONProxyFactory != address(0) && _stakeTONLogic != address(0),
            "StakeTONFactory: zero"
        );
        stakeTONProxyFactory = _stakeTONProxyFactory;
        stakeTONLogic = _stakeTONLogic;
    }

    /// @dev Create a stake contract that can stake TON.
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _registry  the registry address
    /// @param _intdata the array of [saleStartBlock, startBlock, periodBlocks]
    /// @param owner  owner address
    /// @return contract address
    function create(
        address[4] memory _addr,
        address _registry,
        uint256[3] memory _intdata,
        address owner
    ) external override returns (address) {
        address proxy =
            IStakeTONProxyFactory(stakeTONProxyFactory).deploy(
                stakeTONLogic,
                _addr,
                _registry,
                _intdata,
                owner
            );

        require(proxy != address(0), "StakeTONFactory: proxy zero");

        return proxy;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IStakeContractFactory {
    /// @dev Create a stake contract that can stake TON.
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _registry  the registry address
    /// @param _intdata the array of [saleStartBlock, startBlock, periodBlocks]
    /// @param owner  owner address
    /// @return contract address
    function create(
        address[4] calldata _addr,
        address _registry,
        uint256[3] calldata _intdata,
        address owner
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IStakeTONProxyFactory {
    /// @dev Create a StakeTONProxy that can stake TON.
    /// @param _logic the logic contract address used in proxy
    /// @param _addr the array of [token, paytoken, vault, defiAddr]
    /// @param _registry the registry address
    /// @param _intdata the array of [saleStartBlock, startBlock, periodBlocks]
    /// @param owner  owner address
    /// @return contract address
    function deploy(
        address _logic,
        address[4] calldata _addr,
        address _registry,
        uint256[3] calldata _intdata,
        address owner
    ) external returns (address);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 100
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}