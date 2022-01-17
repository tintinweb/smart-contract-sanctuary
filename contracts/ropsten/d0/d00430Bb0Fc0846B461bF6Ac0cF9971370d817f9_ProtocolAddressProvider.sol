// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IProtocolAddressProvider.sol';
import './storage/ProtocolAddressProviderStorage.sol';

pragma solidity ^0.8.4;

/// @title ProtocolAddressProvider
/// @notice ProtocolAddressProvider contract manages the addresses of the protocol components
/// The owner who can manage this contract is currently EOA, but the owner role will be delegated to
/// the multi-sig wallets when the protocol operating units are fully stabilized
contract ProtocolAddressProvider is
  Ownable,
  IProtocolAddressProvider,
  ProtocolAddressProviderStorage
{
  constructor() {}

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check Initializing process cannot be executed twice
  /// @custom:check Only owner can initialize
  /// @custom:effect set roles with given params
  /// @custom:interaction emit `ProtocolAddressProviderInitialized` event
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external override onlyOwner {
    require(_addresses[GUARDIAN] == address(0), 'Already initialized');
    _addresses[GUARDIAN] = guardian;
    _addresses[LIQUIDATION_MANAGER] = liquidationManager;
    _addresses[LOAN_MANAGER] = loanManager;
    _addresses[INCENTIVE_MANAGER] = incentiveManager;
    _addresses[GOVERNANCE] = governance;
    _addresses[COUNCIL] = council;
    _addresses[CORE] = core;
    _addresses[TREASURY] = treasury;

    emit ProtocolAddressProviderInitialized(
      guardian,
      liquidationManager,
      loanManager,
      incentiveManager,
      governance,
      council,
      core,
      treasury
    );
  }

  /// @inheritdoc IProtocolAddressProvider
  function getGuardian() external view override returns (address guardian) {
    return _addresses[GUARDIAN];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getLiquidationManager() external view override returns (address liquidationManager) {
    return _addresses[LIQUIDATION_MANAGER];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getLoanManager() external view override returns (address loanManager) {
    return _addresses[LOAN_MANAGER];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getIncentiveManager() external view override returns (address incentiveManager) {
    return _addresses[INCENTIVE_MANAGER];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getGovernance() external view override returns (address governance) {
    return _addresses[GOVERNANCE];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getCouncil() external view override returns (address council) {
    return _addresses[COUNCIL];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getCore() external view override returns (address core) {
    return _addresses[CORE];
  }

  /// @inheritdoc IProtocolAddressProvider
  function getProtocolTreasury() external view override returns (address protocolTreasury) {
    return _addresses[TREASURY];
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[LIQUIDATION_MANAGER] = liquidationManager`
  /// @custom:interaction - emit event
  function updateLiquidationManager(address liquidationManager) external override onlyOwner {
    _addresses[LIQUIDATION_MANAGER] = liquidationManager;
    emit UpdateLiquidationManager(liquidationManager);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[LOAN_MANAGER] = loanManager`
  /// @custom:interaction - emit event
  function updateLoanManager(address loanManager) external override onlyOwner {
    _addresses[LOAN_MANAGER] = loanManager;
    emit UpdateLoanManager(loanManager);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[INCENTIVE_MANAGER] = incentiveManager`
  /// @custom:interaction - emit event
  function updateIncentiveManager(address incentiveManager) external override onlyOwner {
    _addresses[INCENTIVE_MANAGER] = incentiveManager;
    emit UpdateIncentiveManager(incentiveManager);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[GOVERNANCE] = governance`
  /// @custom:interaction - emit event
  function updateGovernance(address governance) external override onlyOwner {
    _addresses[GOVERNANCE] = governance;
    emit UpdateGovernance(governance);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[COUNCIL] = council`
  /// @custom:interaction - emit event
  function updateCouncil(address council) external override onlyOwner {
    _addresses[COUNCIL] = council;
    emit UpdateCouncil(council);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[CORE] = core`
  /// @custom:interaction - emit event
  function updateCore(address core) external override onlyOwner {
    _addresses[CORE] = core;
    emit UpdateCore(core);
  }

  /// @inheritdoc IProtocolAddressProvider
  /// @custom:check - `msg.sender` must be authorized
  /// @custom:effect - set `_addresses[CORE] = core`
  /// @custom:interaction - emit event
  function updateTreasury(address treasury) external override onlyOwner {
    _addresses[TREASURY] = treasury;
    emit UpdateTreasury(treasury);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error OnlyGovernance();
error OnlyGuardian();
error OnlyCouncil();
error OnlyCore();

interface IProtocolAddressProvider {
  /// @notice emitted when liquidationManager address updated
  event UpdateLiquidationManager(address liquidationManager);

  /// @notice emitted when loanManager address updated
  event UpdateLoanManager(address loanManager);

  /// @notice emitted when incentiveManager address updated
  event UpdateIncentiveManager(address incentiveManager);

  /// @notice emitted when governance address updated
  event UpdateGovernance(address governance);

  /// @notice emitted when council address updated
  event UpdateCouncil(address council);

  /// @notice emitted when core address updated
  event UpdateCore(address core);

  /// @notice emitted when treasury address updated
  event UpdateTreasury(address treasury);

  /// @notice emitted when protocol address provider initialized
  event ProtocolAddressProviderInitialized(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treausury
  );

  /// @notice ProtocolAddressProvider should be initialized after deploying protocol contracts finished.
  /// @param guardian guardian
  /// @param liquidationManager liquidationManager
  /// @param loanManager loanManager
  /// @param incentiveManager incentiveManager
  /// @param governance governance
  /// @param council council
  /// @param core core
  /// @param treasury treasury
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external;

  /// @notice This function returns the address of the guardian
  /// @return guardian The address of the protocol guardian
  function getGuardian() external view returns (address guardian);

  /// @notice This function returns the address of liquidationManager contract
  /// @return liquidationManager The address of liquidationManager contract
  function getLiquidationManager() external view returns (address liquidationManager);

  /// @notice This function returns the address of LoanManager contract
  /// @return loanManager The address of LoanManager contract
  function getLoanManager() external view returns (address loanManager);

  /// @notice This function returns the address of incentiveManager contract
  /// @return incentiveManager The address of incentiveManager contract
  function getIncentiveManager() external view returns (address incentiveManager);

  /// @notice This function returns the address of governance contract
  /// @return governance The address of governance contract
  function getGovernance() external view returns (address governance);

  /// @notice This function returns the address of council contract
  /// @return council The address of council contract
  function getCouncil() external view returns (address council);

  /// @notice This function returns the address of core contract
  /// @return core The address of core contract
  function getCore() external view returns (address core);

  /// @notice This function returns the address of protocolTreasury contract
  /// @return protocolTreasury The address of protocolTreasury contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function updates the address of liquidationManager contract
  /// @param liquidationManager The address of liquidationManager contract to update
  function updateLiquidationManager(address liquidationManager) external;

  /// @notice This function updates the address of LoanManager contract
  /// @param loanManager The address of LoanManager contract to update
  function updateLoanManager(address loanManager) external;

  /// @notice This function updates the address of incentiveManager contract
  /// @param incentiveManager The address of incentiveManager contract to update
  function updateIncentiveManager(address incentiveManager) external;

  /// @notice This function updates the address of governance contract
  /// @param governance The address of governance contract to update
  function updateGovernance(address governance) external;

  /// @notice This function updates the address of council contract
  /// @param council The address of council contract to update
  function updateCouncil(address council) external;

  /// @notice This function updates the address of core contract
  /// @param core The address of core contract to update
  function updateCore(address core) external;

  /// @notice This function updates the address of treasury contract
  /// @param treasury The address of treasury contract to update
  function updateTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract ProtocolAddressProviderStorage {
  /// @notice Liquidation manager contract
  bytes32 public LIQUIDATION_MANAGER = keccak256('LIQUIDATION_MANAGER');

  /// @notice Loan manager contract
  bytes32 public LOAN_MANAGER = keccak256('LOAN_MANAGER');

  /// @notice Incentive manager contract
  bytes32 public INCENTIVE_MANAGER = keccak256('INCENTIVE_MANAGER');

  /// @notice Governance for the protocol
  bytes32 public GOVERNANCE = keccak256('GOVERNANCE');

  /// @notice Elyfi Core contract
  bytes32 public CORE = keccak256('CORE');

  /// @notice Representatives elected to the council governance for approving loan
  bytes32 public COUNCIL = keccak256('COUNCIL');

  /// @notice Multi-sig wallet for protocol emergency
  bytes32 public GUARDIAN = keccak256('GUARDIAN');

  /// @notice Protocol Treasury
  bytes32 public TREASURY = keccak256('TREASURY');

  mapping(bytes32 => address) internal _addresses;
}