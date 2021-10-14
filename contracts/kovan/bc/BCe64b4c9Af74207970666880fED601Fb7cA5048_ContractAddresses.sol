// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IContractRegistry } from "./interfaces/IContractRegistry.sol";
import { Contracts, IContractAddresses } from "./interfaces/IContractAddresses.sol";


contract ContractAddresses is IContractAddresses
{
  IContractRegistry private constant _REGISTRY = IContractRegistry(0x95981830AFbb7382BBC1Ea0fC163478fE2bB628C);


  function getRegistry () external pure returns (address)
  {
    return address(_REGISTRY);
  }

  function coordinatingContracts () external view override returns (Contracts memory)
  {
    return _REGISTRY.getCoordinatingContracts();
  }


  function vault () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("Vault"));
  }

  function oracle () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("Oracle"));
  }

  function tokenRegistry () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("TokenRegistry"));
  }

  function coordinator () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("Coordinator"));
  }

  function depositManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("DepositManager"));
  }

  function borrowManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("BorrowManager"));
  }

  function stakingManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("StakingManager"));
  }

  function feeManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("FeeManager"));
  }

  function rewardManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("RewardManager"));
  }

  function collateralizationManager () external view override returns (address)
  {
    return _REGISTRY.getContract(keccak256("CollateralizationManager"));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { Contracts } from "./IContractAddresses.sol";


interface IContractRegistry
{
  function getContract (bytes32 key) external view returns (address);

  function getCoordinatingContracts () external view returns (Contracts memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


struct Contracts
{
  address oracle;
  address coordinator;
  address tokenRegistry;
  address stakingManager;
  address feeManager;
  address rewardManager;
  address collateralizationManager;
}

interface IContractAddresses
{
  function coordinatingContracts () external view returns (Contracts memory);


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