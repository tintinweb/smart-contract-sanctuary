// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import { Address } from './Address.sol';
import { ECDSA } from './ECDSA.sol';
import { IERC20 } from './IERC20.sol';
import {
  SafeMath as SafeMath256
} from './SafeMath.sol';

import { UUID } from './UUID.sol';
import { Owned } from './Owned.sol';

/**
 * @notice The EarningsEscrow contract. Holds custody of assets deposited into escrow
 * and distributes current earnings.
 */
contract EarningsEscrow is Owned {
  using SafeMath256 for uint256;

  /**
   * @notice Emitted when an admin withdraws assets from escrow with `withdrawEscrow`
   */
  event EscrowWithdrawn(uint256 quantity, uint256 newEscrowBalance);
  /**
   * @notice Emitted when an admin changes the Exchange wallet tunable parameter with `setExchange`
   */
  event ExchangeChanged(address previousValue, address newValue);
  /**
   * @notice Emitted when an earnings distribution is paid by calling `distribute`
   */
  event AssetsDistributed(
    address indexed wallet,
    uint256 quantity,
    uint256 totalQuantity,
    uint128 nonce
  );

  /**
   * @notice Emitted when this contract receives native asset for escrow
   */
  event NativeAssetEscrowed(address indexed from, uint256 quantity);

  /**
   * @notice Argument type for `distribute`
   */
  struct AssetDistribution {
    uint128 nonce;
    uint128 parentNonce;
    address walletAddress;
    address assetAddress;
    uint256 quantity;
    bytes exchangeSignature;
  }

  // The wallet currently whitelisted to sign earnings distributions
  address _exchangeWallet;
  // Mapping of wallet => nonce of last distribution
  mapping(address => uint128) _lastNonce;
  mapping(address => uint256) _totalDistributed;

  // Immutable constants //
  address public immutable _assetAddress;

  /**
   * @notice Instantiate a new EarningsEscrow
   *
   * @dev Sets `owner` and `admin` to `msg.sender` as well as the escrow asset address,
   * after which they cannot be changed
   *
   * @param distributionAssetAddress Address of the escrow asset
   */
  constructor(address distributionAssetAddress, address initialExchangeWallet)
    public
    Owned()
  {
    require(
      Address.isContract(address(distributionAssetAddress)) ||
        address(distributionAssetAddress) == address(0x0),
      'Invalid asset address'
    );

    _assetAddress = distributionAssetAddress;
    _exchangeWallet = initialExchangeWallet;
  }

  receive() external payable {
    emit NativeAssetEscrowed(msg.sender, msg.value);
  }

  /**
   * @notice Distribute earnings as authorized by the Exchange wallet
   *
   * @param distribution The distribution request data
   */
  function distribute(AssetDistribution memory distribution) public {
    require(distribution.walletAddress == msg.sender, 'Invalid caller');
    require(
      distribution.parentNonce != distribution.nonce,
      'Nonce must be different from parent'
    );
    require(
      distribution.parentNonce == _lastNonce[msg.sender],
      'Invalidated nonce'
    );
    require(
      distribution.parentNonce == 0 ||
        UUID.getTimestampInMsFromUuidV1(distribution.parentNonce) <
        UUID.getTimestampInMsFromUuidV1(distribution.nonce),
      'Nonce timestamp must be later than parent'
    );
    require(distribution.assetAddress == _assetAddress, 'Invalid asset address');

    bytes32 hash = getDistributionHash(distribution);
    require(
      isSignatureValid(hash, distribution.exchangeSignature, _exchangeWallet),
      'Invalid exchange signature'
    );

    _lastNonce[msg.sender] = distribution.nonce;
    transferTo(msg.sender, _assetAddress, distribution.quantity);
    _totalDistributed[msg.sender] = _totalDistributed[msg.sender].add(
      distribution.quantity
    );

    emit AssetsDistributed(
      msg.sender,
      distribution.quantity,
      _totalDistributed[msg.sender],
      distribution.nonce
    );
  }

  /**
   * @notice Load a wallet's last used distribution nonce
   *
   * @param wallet The wallet address to load the nonce for. Can be different from `msg.sender`
   *
   * @return The nonce of the last succesful distribution request for this wallet; 0 if no distributions have been made
   */
  function loadLastNonce(address wallet) external view returns (uint128) {
    require(wallet != address(0x0), 'Invalid wallet address');

    return _lastNonce[wallet];
  }

  /**
   * @notice Load a wallet's total cumulative distributions
   *
   * @param wallet The wallet address to load the total for. Can be different from `msg.sender`
   *
   * @return The total amount of distributions made to this wallet; 0 if no distributions have been made
   */
  function loadTotalDistributed(address wallet)
    external
    view
    returns (uint256)
  {
    require(wallet != address(0x0), 'Invalid wallet address');

    return _totalDistributed[wallet];
  }

  /**
   * @notice Withdraw assets previously assigned to escrow in this contract
   *
   * @param quantity The quantity of assets to withdraw
   */
  function withdrawEscrow(uint256 quantity) external onlyAdmin {
    transferTo(msg.sender, _assetAddress, quantity);
    if (_assetAddress == address(0x0)) {
      emit EscrowWithdrawn(quantity, address(this).balance);
    } else {
      emit EscrowWithdrawn(
        quantity,
        IERC20(_assetAddress).balanceOf(address(this))
      );
    }
  }

  // Exchange whitelisting //

  /**
   * @notice Sets the wallet whitelisted to sign earning distributions
   *
   * @param newExchangeWallet The new whitelisted Exchage wallet. Must be different from the current one
   */
  function setExchange(address newExchangeWallet) external onlyAdmin {
    require(newExchangeWallet != address(0x0), 'Invalid wallet address');
    require(
      newExchangeWallet != _exchangeWallet,
      'Must be different from current exchange'
    );
    address oldExchangeWallet = _exchangeWallet;
    _exchangeWallet = newExchangeWallet;

    emit ExchangeChanged(oldExchangeWallet, newExchangeWallet);
  }

  /**
   * @notice Clears the currently whitelisted Exchange wallet, effectively disabling the
   * `distribute` function until a new wallet is set with `setExchange`
   */
  function removeExchange() external onlyAdmin {
    emit ExchangeChanged(_exchangeWallet, address(0x0));
    _exchangeWallet = address(0x0);
  }

  function transferTo(
    address payable walletOrContract,
    address asset,
    uint256 quantityInAssetUnits
  ) internal {
    if (asset == address(0x0)) {
      require(
        walletOrContract.send(quantityInAssetUnits),
        'ETH transfer failed'
      );
    } else {
      uint256 balanceBefore = IERC20(asset).balanceOf(walletOrContract);

      // Because we check for the expected balance change we can safely ignore the return value of transfer
      IERC20(asset).transfer(walletOrContract, quantityInAssetUnits);

      uint256 balanceAfter = IERC20(asset).balanceOf(walletOrContract);
      require(
        balanceAfter.sub(balanceBefore) == quantityInAssetUnits,
        'Token contract returned transfer success without expected balance change'
      );
    }
  }

  function getDistributionHash(AssetDistribution memory distribution)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked(
          address(this),
          distribution.nonce,
          distribution.parentNonce,
          distribution.walletAddress,
          distribution.assetAddress,
          distribution.quantity
        )
      );
  }

  function getAssetAddress() external view returns (address) {
    return _assetAddress;
  }

  function isSignatureValid(
    bytes32 hash,
    bytes memory signature,
    address signer
  ) internal pure returns (bool) {
    return
      ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == signer;
  }
}