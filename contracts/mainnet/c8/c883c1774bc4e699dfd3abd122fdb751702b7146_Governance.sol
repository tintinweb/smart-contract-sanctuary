// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { Address } from './Address.sol';
import {
  SafeMath as SafeMath256
} from './SafeMath.sol';

import { ICustodian } from './Interfaces.sol';
import { Owned } from './Owned.sol';


contract Governance is Owned {
  using SafeMath256 for uint256;

  /**
   * @notice Emitted when admin initiates upgrade of `Exchange` contract address on `Custodian` via
   * `initiateExchangeUpgrade`
   */
  event ExchangeUpgradeInitiated(
    address oldExchange,
    address newExchange,
    uint256 blockThreshold
  );
  /**
   * @notice Emitted when admin cancels previously started `Exchange` upgrade with `cancelExchangeUpgrade`
   */
  event ExchangeUpgradeCanceled(address oldExchange, address newExchange);
  /**
   * @notice Emitted when admin finalizes `Exchange` upgrade via `finalizeExchangeUpgrade`
   */
  event ExchangeUpgradeFinalized(address oldExchange, address newExchange);
  /**
   * @notice Emitted when admin initiates upgrade of `Governance` contract address on `Custodian` via
   * `initiateGovernanceUpgrade`
   */
  event GovernanceUpgradeInitiated(
    address oldGovernance,
    address newGovernance,
    uint256 blockThreshold
  );
  /**
   * @notice Emitted when admin cancels previously started `Governance` upgrade with `cancelGovernanceUpgrade`
   */
  event GovernanceUpgradeCanceled(address oldGovernance, address newGovernance);
  /**
   * @notice Emitted when admin finalizes `Governance` upgrade via `finalizeGovernanceUpgrade`, effectively replacing
   * this contract and rendering it non-functioning
   */
  event GovernanceUpgradeFinalized(
    address oldGovernance,
    address newGovernance
  );

  // Internally used structs //

  struct ContractUpgrade {
    bool exists;
    address newContract;
    uint256 blockThreshold;
  }

  // Storage //

  uint256 immutable _blockDelay;
  ICustodian _custodian;
  ContractUpgrade _currentExchangeUpgrade;
  ContractUpgrade _currentGovernanceUpgrade;

  /**
   * @notice Instantiate a new `Governance` contract
   *
   * @dev Sets `owner` and `admin` to `msg.sender`. Sets the values for `_blockDelay` governing `Exchange`
   * and `Governance` upgrades. This value is immutable, and cannot be changed after construction
   *
   * @param blockDelay The minimum number of blocks that must be mined after initiating an `Exchange`
   * or `Governance` upgrade before the upgrade may be finalized
   */
  constructor(uint256 blockDelay) public Owned() {
    _blockDelay = blockDelay;
  }

  /**
   * @notice Sets the address of the `Custodian` contract. The `Custodian` accepts `Exchange` and
   * `Governance` addresses in its constructor, after which they can only be changed by the
   * `Governance` contract itself. Therefore the `Custodian` must be deployed last and its address
   * set here on an existing `Governance` contract. This value is immutable once set and cannot be
   * changed again
   *
   * @param newCustodian The address of the `Custodian` contract deployed against this `Governance`
   * contract's address
   */
  function setCustodian(ICustodian newCustodian) external onlyAdmin {
    require(_custodian == ICustodian(0x0), 'Custodian can only be set once');
    require(Address.isContract(address(newCustodian)), 'Invalid address');

    _custodian = newCustodian;
  }

  // Exchange upgrade //

  /**
   * @notice Initiates `Exchange` contract upgrade proccess on `Custodian`. Once `blockDelay` has passed
   * the process can be finalized with `finalizeExchangeUpgrade`
   *
   * @param newExchange The address of the new `Exchange` contract
   */
  function initiateExchangeUpgrade(address newExchange) external onlyAdmin {
    require(Address.isContract(address(newExchange)), 'Invalid address');
    require(
      newExchange != _custodian.loadExchange(),
      'Must be different from current Exchange'
    );
    require(
      !_currentExchangeUpgrade.exists,
      'Exchange upgrade already in progress'
    );

    _currentExchangeUpgrade = ContractUpgrade(
      true,
      newExchange,
      block.number.add(_blockDelay)
    );

    emit ExchangeUpgradeInitiated(
      _custodian.loadExchange(),
      newExchange,
      _currentExchangeUpgrade.blockThreshold
    );
  }

  /**
   * @notice Cancels an in-flight `Exchange` contract upgrade that has not yet been finalized
   */
  function cancelExchangeUpgrade() external onlyAdmin {
    require(_currentExchangeUpgrade.exists, 'No Exchange upgrade in progress');

    address newExchange = _currentExchangeUpgrade.newContract;
    delete _currentExchangeUpgrade;

    emit ExchangeUpgradeCanceled(_custodian.loadExchange(), newExchange);
  }

  /**
   * @notice Finalizes the `Exchange` contract upgrade by changing the contract address on the `Custodian`
   * contract with `setExchange`. The number of blocks specified by `_blockDelay` must have passed since calling
   * `initiateExchangeUpgrade`
   *
   * @param newExchange The address of the new `Exchange` contract. Must equal the address provided to
   * `initiateExchangeUpgrade`
   */
  function finalizeExchangeUpgrade(address newExchange) external onlyAdmin {
    require(_currentExchangeUpgrade.exists, 'No Exchange upgrade in progress');
    require(
      _currentExchangeUpgrade.newContract == newExchange,
      'Address mismatch'
    );
    require(
      block.number >= _currentExchangeUpgrade.blockThreshold,
      'Block threshold not yet reached'
    );

    address oldExchange = _custodian.loadExchange();
    _custodian.setExchange(newExchange);
    delete _currentExchangeUpgrade;

    emit ExchangeUpgradeFinalized(oldExchange, newExchange);
  }

  // Governance upgrade //

  /**
   * @notice Initiates `Governance` contract upgrade proccess on `Custodian`. Once `blockDelay` has passed
   * the process can be finalized with `finalizeGovernanceUpgrade`
   *
   * @param newGovernance The address of the new `Governance` contract
   */
  function initiateGovernanceUpgrade(address newGovernance) external onlyAdmin {
    require(Address.isContract(address(newGovernance)), 'Invalid address');
    require(
      newGovernance != _custodian.loadGovernance(),
      'Must be different from current Governance'
    );
    require(
      !_currentGovernanceUpgrade.exists,
      'Governance upgrade already in progress'
    );

    _currentGovernanceUpgrade = ContractUpgrade(
      true,
      newGovernance,
      block.number.add(_blockDelay)
    );

    emit GovernanceUpgradeInitiated(
      _custodian.loadGovernance(),
      newGovernance,
      _currentGovernanceUpgrade.blockThreshold
    );
  }

  /**
   * @notice Cancels an in-flight `Governance` contract upgrade that has not yet been finalized
   */
  function cancelGovernanceUpgrade() external onlyAdmin {
    require(
      _currentGovernanceUpgrade.exists,
      'No Governance upgrade in progress'
    );

    address newGovernance = _currentGovernanceUpgrade.newContract;
    delete _currentGovernanceUpgrade;

    emit GovernanceUpgradeCanceled(_custodian.loadGovernance(), newGovernance);
  }

  /**
   * @notice Finalizes the `Governance` contract upgrade by changing the contract address on the `Custodian`
   * contract with `setGovernance`. The number of blocks specified by `_blockDelay` must have passed since calling
   * `initiateGovernanceUpgrade`.
   *
   * @dev After successfully calling this function, this contract will become useless since it is no
   * longer whitelisted in the `Custodian`
   *
   * @param newGovernance The address of the new `Governance` contract. Must equal the address provided to
   * `initiateGovernanceUpgrade`
   */
  function finalizeGovernanceUpgrade(address newGovernance) external onlyAdmin {
    require(
      _currentGovernanceUpgrade.exists,
      'No Governance upgrade in progress'
    );
    require(
      _currentGovernanceUpgrade.newContract == newGovernance,
      'Address mismatch'
    );
    require(
      block.number >= _currentGovernanceUpgrade.blockThreshold,
      'Block threshold not yet reached'
    );

    address oldGovernance = _custodian.loadGovernance();
    _custodian.setGovernance(newGovernance);
    delete _currentGovernanceUpgrade;

    emit GovernanceUpgradeFinalized(oldGovernance, newGovernance);
  }
}
