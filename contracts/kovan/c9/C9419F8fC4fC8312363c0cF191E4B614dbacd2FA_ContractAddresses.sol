// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IContractRegistry } from "./interfaces/IContractRegistry.sol";
import { IContractAddresses } from "./interfaces/IContractAddresses.sol";


contract ContractAddresses is IContractAddresses
{
  IContractRegistry private constant _registry = IContractRegistry(0x669032dF00b7DEd42fF5e894e484c58301E5574b);


  function getRegistry () external pure returns (address)
  {
    return address(_registry);
  }

  function vault () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("Vault"));
  }

  function oracle () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("Oracle"));
  }

  function tokenRegistry () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("TokenRegistry"));
  }

  function coordinator () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("Coordinator"));
  }

  function depositManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("DepositManager"));
  }

  function borrowManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("BorrowManager"));
  }

  function stakingManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("StakingManager"));
  }

  function feeManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("FeeManager"));
  }

  function rewardManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("RewardManager"));
  }

  function collateralizationManager () external view override returns (address)
  {
    return _registry.getLatestImplementation(keccak256("CollateralizationManager"));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IContractRegistry
{
  function getLatestImplementation (bytes32 key) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface IContractAddresses
{
  function vault () external view returns (address);

  function oracle () external view returns (address);

  function tokenRegistry () external view returns (address);

  function coordinator () external view returns (address);

  function depositManager () external view returns (address);

  function borrowManager () external view returns (address);

  function feeManager () external view returns (address);

  function stakingManager () external view returns (address);

  function rewardManager () external view returns (address);

  function collateralizationManager () external view returns (address);
}