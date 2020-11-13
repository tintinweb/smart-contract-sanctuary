// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { Address } from './Address.sol';

import { ICustodian } from './Interfaces.sol';
import { Owned } from './Owned.sol';
import { AssetTransfers } from './AssetTransfers.sol';


/**
 * @notice The Custodian contract. Holds custody of all deposited funds for whitelisted Exchange
 * contract with minimal additional logic
 */
contract Custodian is ICustodian, Owned {
  // Events //

  /**
   * @notice Emitted on construction and when Governance upgrades the Exchange contract address
   */
  event ExchangeChanged(address oldExchange, address newExchange);
  /**
   * @notice Emitted on construction and when Governance replaces itself by upgrading the Governance contract address
   */
  event GovernanceChanged(address oldGovernance, address newGovernance);

  address _exchange;
  address _governance;

  /**
   * @notice Instantiate a new Custodian
   *
   * @dev Sets `owner` and `admin` to `msg.sender`. Sets initial values for Exchange and Governance
   * contract addresses, after which they can only be changed by the currently set Governance contract
   * itself
   *
   * @param exchange Address of deployed Exchange contract to whitelist
   * @param governance ddress of deployed Governance contract to whitelist
   */
  constructor(address exchange, address governance) public Owned() {
    require(Address.isContract(exchange), 'Invalid exchange contract address');
    require(
      Address.isContract(governance),
      'Invalid governance contract address'
    );

    _exchange = exchange;
    _governance = governance;

    emit ExchangeChanged(address(0x0), exchange);
    emit GovernanceChanged(address(0x0), governance);
  }

  /**
   * @notice ETH can only be sent by the Exchange
   */
  receive() external override payable onlyExchange {}

  /**
   * @notice Withdraw any asset and amount to a target wallet
   *
   * @dev No balance checking performed
   *
   * @param wallet The wallet to which assets will be returned
   * @param asset The address of the asset to withdraw (ETH or ERC-20 contract)
   * @param quantityInAssetUnits The quantity in asset units to withdraw
   */
  function withdraw(
    address payable wallet,
    address asset,
    uint256 quantityInAssetUnits
  ) external override onlyExchange {
    AssetTransfers.transferTo(wallet, asset, quantityInAssetUnits);
  }

  /**
   * @notice Load address of the currently whitelisted Exchange contract
   *
   * @return The address of the currently whitelisted Exchange contract
   */
  function loadExchange() external override view returns (address) {
    return _exchange;
  }

  /**
   * @notice Sets a new Exchange contract address
   *
   * @param newExchange The address of the new whitelisted Exchange contract
   */
  function setExchange(address newExchange) external override onlyGovernance {
    require(Address.isContract(newExchange), 'Invalid contract address');

    address oldExchange = _exchange;
    _exchange = newExchange;

    emit ExchangeChanged(oldExchange, newExchange);
  }

  /**
   * @notice Load address of the currently whitelisted Governance contract
   *
   * @return The address of the currently whitelisted Governance contract
   */
  function loadGovernance() external override view returns (address) {
    return _governance;
  }

  /**
   * @notice Sets a new Governance contract address
   *
   * @param newGovernance The address of the new whitelisted Governance contract
   */
  function setGovernance(address newGovernance)
    external
    override
    onlyGovernance
  {
    require(Address.isContract(newGovernance), 'Invalid contract address');

    address oldGovernance = _governance;
    _governance = newGovernance;

    emit GovernanceChanged(oldGovernance, newGovernance);
  }

  // RBAC //

  modifier onlyExchange() {
    require(msg.sender == _exchange, 'Caller must be Exchange contract');
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == _governance, 'Caller must be Governance contract');
    _;
  }
}
