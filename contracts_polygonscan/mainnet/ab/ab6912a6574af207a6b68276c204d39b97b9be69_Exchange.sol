// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Address } from './Address.sol';

import { Asset } from './Structs.sol';
import { AssetTransfers } from './AssetTransfers.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { IERC20 } from './Interfaces.sol';

/**
 * @notice Library helper functions for reading from a registry of asset descriptors indexed by address and symbol
 */
library AssetRegistry {
  struct Storage {
    mapping(address => Asset) assetsByAddress;
    // Mapping value is array since the same symbol can be re-used for a different address
    // (usually as a result of a token swap or upgrade)
    mapping(string => Asset[]) assetsBySymbol;
    // Blockchain-specific native asset symbol
    string nativeAssetSymbol;
  }

  // Admin //

  function registerToken(
    AssetRegistry.Storage storage self,
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external {
    require(decimals <= 32, 'Token cannot have more than 32 decimals');
    require(
      tokenAddress != IERC20(address(0x0)) &&
        Address.isContract(address(tokenAddress)),
      'Invalid token address'
    );
    // The string type does not have a length property so cast to bytes to check for empty string
    require(bytes(symbol).length > 0, 'Invalid token symbol');
    require(
      !self.assetsByAddress[address(tokenAddress)].isConfirmed,
      'Token already finalized'
    );

    self.assetsByAddress[address(tokenAddress)] = Asset({
      exists: true,
      assetAddress: address(tokenAddress),
      symbol: symbol,
      decimals: decimals,
      isConfirmed: false,
      confirmedTimestampInMs: 0
    });
  }

  function confirmTokenRegistration(
    AssetRegistry.Storage storage self,
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external {
    Asset memory asset = self.assetsByAddress[address(tokenAddress)];
    require(asset.exists, 'Unknown token');
    require(!asset.isConfirmed, 'Token already finalized');
    require(isStringEqual(asset.symbol, symbol), 'Symbols do not match');
    require(asset.decimals == decimals, 'Decimals do not match');

    asset.isConfirmed = true;
    asset.confirmedTimestampInMs = uint64(block.timestamp * 1000); // Block timestamp is in seconds, store ms
    self.assetsByAddress[address(tokenAddress)] = asset;
    self.assetsBySymbol[symbol].push(asset);
  }

  function addTokenSymbol(
    AssetRegistry.Storage storage self,
    IERC20 tokenAddress,
    string calldata symbol
  ) external {
    Asset memory asset = self.assetsByAddress[address(tokenAddress)];
    require(
      asset.exists && asset.isConfirmed,
      'Registration of token not finalized'
    );
    require(
      !isStringEqual(symbol, self.nativeAssetSymbol),
      'Symbol reserved for native asset'
    );

    // This will prevent swapping assets for previously existing orders
    uint64 msInOneSecond = 1000;
    asset.confirmedTimestampInMs = uint64(block.timestamp * msInOneSecond);

    self.assetsBySymbol[symbol].push(asset);
  }

  function skim(address tokenAddress, address feeWallet) external {
    require(Address.isContract(tokenAddress), 'Invalid token address');

    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    AssetTransfers.transferTo(payable(feeWallet), tokenAddress, balance);
  }

  // Accessors //

  function loadBalanceInAssetUnitsByAddress(
    AssetRegistry.Storage storage self,
    address wallet,
    address assetAddress,
    BalanceTracking.Storage storage balanceTracking
  ) external view returns (uint256) {
    require(wallet != address(0x0), 'Invalid wallet address');

    Asset memory asset = loadAssetByAddress(self, assetAddress);
    return
      AssetUnitConversions.pipsToAssetUnits(
        loadBalanceInPipsFromMigrationSourceIfNeeded(
          wallet,
          assetAddress,
          balanceTracking
        ),
        asset.decimals
      );
  }

  function loadBalanceInAssetUnitsBySymbol(
    AssetRegistry.Storage storage self,
    address wallet,
    string calldata assetSymbol,
    BalanceTracking.Storage storage balanceTracking
  ) external view returns (uint256) {
    require(wallet != address(0x0), 'Invalid wallet address');

    Asset memory asset =
      loadAssetBySymbol(self, assetSymbol, getCurrentTimestampInMs());
    return
      AssetUnitConversions.pipsToAssetUnits(
        loadBalanceInPipsFromMigrationSourceIfNeeded(
          wallet,
          asset.assetAddress,
          balanceTracking
        ),
        asset.decimals
      );
  }

  function loadBalanceInPipsByAddress(
    address wallet,
    address assetAddress,
    BalanceTracking.Storage storage balanceTracking
  ) external view returns (uint64) {
    require(wallet != address(0x0), 'Invalid wallet address');

    return
      loadBalanceInPipsFromMigrationSourceIfNeeded(
        wallet,
        assetAddress,
        balanceTracking
      );
  }

  function loadBalanceInPipsBySymbol(
    Storage storage self,
    address wallet,
    string calldata assetSymbol,
    BalanceTracking.Storage storage balanceTracking
  ) external view returns (uint64) {
    require(wallet != address(0x0), 'Invalid wallet address');

    address assetAddress =
      loadAssetBySymbol(self, assetSymbol, getCurrentTimestampInMs())
        .assetAddress;
    return
      loadBalanceInPipsFromMigrationSourceIfNeeded(
        wallet,
        assetAddress,
        balanceTracking
      );
  }

  function loadBalanceInPipsFromMigrationSourceIfNeeded(
    address wallet,
    address assetAddress,
    BalanceTracking.Storage storage balanceTracking
  ) private view returns (uint64) {
    BalanceTracking.Balance memory balance =
      balanceTracking.balancesByWalletAssetPair[wallet][assetAddress];

    if (
      !balance.isMigrated &&
      address(balanceTracking.migrationSource) != address(0x0)
    ) {
      return
        balanceTracking.migrationSource.loadBalanceInPipsByAddress(
          wallet,
          assetAddress
        );
    }

    return balance.balanceInPips;
  }

  /**
   * @dev Resolves an asset address into corresponding Asset struct
   *
   * @param assetAddress Ethereum address of asset
   */
  function loadAssetByAddress(Storage storage self, address assetAddress)
    internal
    view
    returns (Asset memory)
  {
    if (assetAddress == address(0x0)) {
      return getEthAsset(self.nativeAssetSymbol);
    }

    Asset memory asset = self.assetsByAddress[assetAddress];
    require(
      asset.exists && asset.isConfirmed,
      'No confirmed asset found for address'
    );

    return asset;
  }

  /**
   * @dev Resolves a asset symbol into corresponding Asset struct
   *
   * @param symbol Asset symbol, e.g. 'IDEX'
   * @param timestampInMs Milliseconds since Unix epoch, usually parsed from a UUID v1 order nonce.
   * Constrains symbol resolution to the asset most recently confirmed prior to timestampInMs. Reverts
   * if no such asset exists
   */
  function loadAssetBySymbol(
    Storage storage self,
    string memory symbol,
    uint64 timestampInMs
  ) internal view returns (Asset memory) {
    if (isStringEqual(self.nativeAssetSymbol, symbol)) {
      return getEthAsset(self.nativeAssetSymbol);
    }

    Asset memory asset;
    if (self.assetsBySymbol[symbol].length > 0) {
      for (uint8 i = 0; i < self.assetsBySymbol[symbol].length; i++) {
        if (
          self.assetsBySymbol[symbol][i].confirmedTimestampInMs <= timestampInMs
        ) {
          asset = self.assetsBySymbol[symbol][i];
        }
      }
    }
    require(
      asset.exists && asset.isConfirmed,
      'No confirmed asset found for symbol'
    );

    return asset;
  }

  // Util //

  function getCurrentTimestampInMs() internal view returns (uint64) {
    uint64 msInOneSecond = 1000;

    return uint64(block.timestamp) * msInOneSecond;
  }

  /**
   * @dev ETH is modeled as an always-confirmed Asset struct for programmatic consistency
   */
  function getEthAsset(string memory nativeAssetSymbol)
    private
    pure
    returns (Asset memory)
  {
    return Asset(true, address(0x0), nativeAssetSymbol, 18, true, 0);
  }

  // See https://solidity.readthedocs.io/en/latest/types.html#bytes-and-strings-as-arrays
  function isStringEqual(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { IERC20 } from './Interfaces.sol';

/**
 * @notice This library provides helper utilities for transfering assets in and out of contracts.
 * It further validates ERC-20 compliant balance updates in the case of token assets
 */
library AssetTransfers {
  /**
   * @dev Transfers tokens from a wallet into a contract during deposits. `wallet` must already
   * have called `approve` on the token contract for at least `tokenQuantity`. Note this only
   * applies to tokens since ETH is sent in the deposit transaction via `msg.value`
   */
  function transferFrom(
    address wallet,
    IERC20 tokenAddress,
    address to,
    uint256 quantityInAssetUnits
  ) internal {
    uint256 balanceBefore = tokenAddress.balanceOf(to);

    // Because we check for the expected balance change we can safely ignore the return value of transferFrom
    tokenAddress.transferFrom(wallet, to, quantityInAssetUnits);

    uint256 balanceAfter = tokenAddress.balanceOf(to);
    require(
      balanceAfter - balanceBefore == quantityInAssetUnits,
      'Token contract returned transferFrom success without expected balance change'
    );
  }

  /**
   * @dev Transfers ETH or token assets from a contract to a wallet when withdrawing or removing liquidity
   */
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
        balanceAfter - balanceBefore == quantityInAssetUnits,
        'Token contract returned transfer success without expected balance change'
      );
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @notice Library helpers for converting asset quantities between asset units and pips
 */
library AssetUnitConversions {
  function pipsToAssetUnits(uint64 quantityInPips, uint8 assetDecimals)
    internal
    pure
    returns (uint256)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      return uint256(quantityInPips) * (uint256(10)**(assetDecimals - 8));
    }
    return uint256(quantityInPips) / (uint256(10)**(8 - assetDecimals));
  }

  function assetUnitsToPips(uint256 quantityInAssetUnits, uint8 assetDecimals)
    internal
    pure
    returns (uint64)
  {
    require(assetDecimals <= 32, 'Asset cannot have more than 32 decimals');

    uint256 quantityInPips;
    // Exponents cannot be negative, so divide or multiply based on exponent signedness
    if (assetDecimals > 8) {
      quantityInPips =
        quantityInAssetUnits /
        (uint256(10)**(assetDecimals - 8));
    } else {
      quantityInPips =
        quantityInAssetUnits *
        (uint256(10)**(8 - assetDecimals));
    }
    require(quantityInPips < 2**64, 'Pip quantity overflows uint64');

    return uint64(quantityInPips);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { Constants } from './Constants.sol';
import { OrderSide } from './Enums.sol';
import { PoolTradeHelpers } from './PoolTradeHelpers.sol';
import {
  Asset,
  HybridTrade,
  LiquidityAddition,
  LiquidityChangeExecution,
  LiquidityRemoval,
  Order,
  OrderBookTrade,
  PoolTrade,
  Withdrawal
} from './Structs.sol';
import { IExchange, ILiquidityProviderToken } from './Interfaces.sol';

library BalanceTracking {
  using AssetRegistry for AssetRegistry.Storage;
  using PoolTradeHelpers for PoolTrade;

  struct Balance {
    bool isMigrated;
    uint64 balanceInPips;
  }

  struct Storage {
    mapping(address => mapping(address => Balance)) balancesByWalletAssetPair;
    // Predecessor Exchange contract from which to lazily migrate balances
    IExchange migrationSource;
  }

  // Depositing //

  function updateForDeposit(
    Storage storage self,
    address wallet,
    address assetAddress,
    uint64 quantityInPips
  ) internal returns (uint64 newBalanceInPips) {
    Balance storage balance =
      loadBalanceAndMigrateIfNeeded(self, wallet, assetAddress);
    balance.balanceInPips += quantityInPips;

    return balance.balanceInPips;
  }

  // Trading //

  /**
   * @dev Updates buyer, seller, and fee wallet balances for both assets in trade pair according to
   * trade parameters
   */
  function updateForOrderBookTrade(
    Storage storage self,
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory trade,
    address feeWallet
  ) internal {
    Balance storage balance;

    // Seller gives base asset including fees
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      sell.walletAddress,
      trade.baseAssetAddress
    );
    balance.balanceInPips -= trade.grossBaseQuantityInPips;
    // Buyer receives base asset minus fees
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      buy.walletAddress,
      trade.baseAssetAddress
    );
    balance.balanceInPips += trade.netBaseQuantityInPips;

    // Buyer gives quote asset including fees
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      buy.walletAddress,
      trade.quoteAssetAddress
    );
    balance.balanceInPips -= trade.grossQuoteQuantityInPips;
    // Seller receives quote asset minus fees
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      sell.walletAddress,
      trade.quoteAssetAddress
    );
    balance.balanceInPips += trade.netQuoteQuantityInPips;

    // Maker fee to fee wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      trade.makerFeeAssetAddress
    );
    balance.balanceInPips += trade.makerFeeQuantityInPips;
    // Taker fee to fee wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      trade.takerFeeAssetAddress
    );
    balance.balanceInPips += trade.takerFeeQuantityInPips;
  }

  function updateForPoolTrade(
    Storage storage self,
    Order memory order,
    PoolTrade memory poolTrade,
    address feeWallet
  ) internal {
    Balance storage balance;

    // Debit from order wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      order.walletAddress,
      poolTrade.getOrderDebitAssetAddress(order.side)
    );
    balance.balanceInPips -= poolTrade.getOrderDebitQuantityInPips(order.side);
    // Credit to order wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      order.walletAddress,
      poolTrade.getOrderCreditAssetAddress(order.side)
    );
    balance.balanceInPips += poolTrade.calculateOrderCreditQuantityInPips(
      order.side
    );

    // Fee wallet receives protocol fee from asset debited from order wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      poolTrade.getOrderDebitAssetAddress(order.side)
    );
    balance.balanceInPips += poolTrade.takerProtocolFeeQuantityInPips;
    // Fee wallet receives gas fee from asset credited to order wallet
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      poolTrade.getOrderCreditAssetAddress(order.side)
    );
    balance.balanceInPips += poolTrade.takerGasFeeQuantityInPips;

    // Liquidity pool reserves are updated in LiquidityPoolRegistry
  }

  function updateForHybridTradeFees(
    Storage storage self,
    HybridTrade memory hybridTrade,
    address takerWallet,
    address feeWallet
  ) internal {
    Balance storage balance;
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      hybridTrade.orderBookTrade.takerFeeAssetAddress
    );
    balance.balanceInPips += hybridTrade.takerGasFeeQuantityInPips;

    balance = loadBalanceAndMigrateIfNeeded(
      self,
      takerWallet,
      hybridTrade.orderBookTrade.takerFeeAssetAddress
    );
    balance.balanceInPips -=
      hybridTrade.takerGasFeeQuantityInPips +
      hybridTrade.poolTrade.takerPriceCorrectionFeeQuantityInPips;

    // Liquidity pool reserves are updated in LiquidityPoolRegistry
  }

  // Withdrawing //

  function updateForWithdrawal(
    Storage storage self,
    Withdrawal memory withdrawal,
    address assetAddress,
    address feeWallet
  ) internal returns (uint64 newExchangeBalanceInPips) {
    Balance storage balance;

    balance = loadBalanceAndMigrateIfNeeded(
      self,
      withdrawal.walletAddress,
      assetAddress
    );
    // Reverts if balance is overdrawn
    balance.balanceInPips -= withdrawal.grossQuantityInPips;
    newExchangeBalanceInPips = balance.balanceInPips;

    if (withdrawal.gasFeeInPips > 0) {
      balance = loadBalanceAndMigrateIfNeeded(self, feeWallet, assetAddress);

      balance.balanceInPips += withdrawal.gasFeeInPips;
    }
  }

  // Wallet exits //

  function updateForExit(
    Storage storage self,
    address wallet,
    address assetAddress
  ) internal returns (uint64 previousExchangeBalanceInPips) {
    Balance storage balance;

    balance = loadBalanceAndMigrateIfNeeded(self, wallet, assetAddress);
    previousExchangeBalanceInPips = balance.balanceInPips;

    require(previousExchangeBalanceInPips > 0, 'No balance for asset');

    balance.balanceInPips = 0;
  }

  // Liquidity pools //

  function updateForAddLiquidity(
    Storage storage self,
    LiquidityAddition memory addition,
    LiquidityChangeExecution memory execution,
    address feeWallet,
    address custodianAddress,
    ILiquidityProviderToken liquidityProviderToken
  ) internal returns (uint64 outputLiquidityInPips) {
    // Base gross debit
    Balance storage balance =
      loadBalanceAndMigrateIfNeeded(
        self,
        addition.wallet,
        execution.baseAssetAddress
      );
    balance.balanceInPips -= execution.grossBaseQuantityInPips;

    // Base fee credit
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      execution.baseAssetAddress
    );
    balance.balanceInPips +=
      execution.grossBaseQuantityInPips -
      execution.netBaseQuantityInPips;

    // Quote gross debit

    balance = loadBalanceAndMigrateIfNeeded(
      self,
      addition.wallet,
      execution.quoteAssetAddress
    );
    balance.balanceInPips -= execution.grossQuoteQuantityInPips;

    // Quote fee credit
    balance = loadBalanceAndMigrateIfNeeded(
      self,
      feeWallet,
      execution.quoteAssetAddress
    );
    balance.balanceInPips +=
      execution.grossQuoteQuantityInPips -
      execution.netQuoteQuantityInPips;

    // Only add output assets to wallet's balances in the Exchange if Custodian is target
    if (addition.to == custodianAddress) {
      balance = loadBalanceAndMigrateIfNeeded(
        self,
        addition.wallet,
        address(liquidityProviderToken)
      );
      balance.balanceInPips += execution.liquidityInPips;
    } else {
      outputLiquidityInPips = execution.liquidityInPips;
    }
  }

  function updateForRemoveLiquidity(
    Storage storage self,
    LiquidityRemoval memory removal,
    LiquidityChangeExecution memory execution,
    address feeWallet,
    address custodianAddress,
    ILiquidityProviderToken liquidityProviderToken
  )
    internal
    returns (
      uint64 outputBaseAssetQuantityInPips,
      uint64 outputQuoteAssetQuantityInPips
    )
  {
    Balance storage balance;

    // Base asset updates
    {
      // Only add output assets to wallet's balances in the Exchange if Custodian is target
      if (removal.to == custodianAddress) {
        // Base net credit
        balance = loadBalanceAndMigrateIfNeeded(
          self,
          removal.wallet,
          execution.baseAssetAddress
        );
        balance.balanceInPips += execution.netBaseQuantityInPips;
      } else {
        outputBaseAssetQuantityInPips = execution.netBaseQuantityInPips;
      }

      // Base fee credit
      balance = loadBalanceAndMigrateIfNeeded(
        self,
        feeWallet,
        execution.baseAssetAddress
      );
      balance.balanceInPips +=
        execution.grossBaseQuantityInPips -
        execution.netBaseQuantityInPips;
    }

    // Quote asset updates
    {
      // Only add output assets to wallet's balances in the Exchange if Custodian is target
      if (removal.to == custodianAddress) {
        // Quote net credit
        balance = loadBalanceAndMigrateIfNeeded(
          self,
          removal.wallet,
          execution.quoteAssetAddress
        );
        balance.balanceInPips += execution.netQuoteQuantityInPips;
      } else {
        outputQuoteAssetQuantityInPips = execution.netQuoteQuantityInPips;
      }

      // Quote fee credit
      balance = loadBalanceAndMigrateIfNeeded(
        self,
        feeWallet,
        execution.quoteAssetAddress
      );
      balance.balanceInPips +=
        execution.grossQuoteQuantityInPips -
        execution.netQuoteQuantityInPips;
    }

    // Pair token burn
    {
      balance = loadBalanceAndMigrateIfNeeded(
        self,
        removal.wallet,
        address(liquidityProviderToken)
      );
      balance.balanceInPips -= execution.liquidityInPips;
    }
  }

  // Helpers //

  function loadBalanceAndMigrateIfNeeded(
    Storage storage self,
    address wallet,
    address assetAddress
  ) private returns (Balance storage) {
    Balance storage balance =
      self.balancesByWalletAssetPair[wallet][assetAddress];

    if (!balance.isMigrated && address(self.migrationSource) != address(0x0)) {
      balance.balanceInPips = self.migrationSource.loadBalanceInPipsByAddress(
        wallet,
        assetAddress
      );
      balance.isMigrated = true;
    }

    return balance;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @dev See GOVERNANCE.md for descriptions of fixed parameters and fees
 */

library Constants {
  // 100 basis points/percent * 100 percent/total
  uint64 public constant basisPointsInTotal = 100 * 100;

  uint64 public constant depositIndexNotSet = 2**64 - 1;

  uint8 public constant liquidityProviderTokenDecimals = 18;

  // 1 week at 3s/block
  uint256 public constant maxChainPropagationPeriod = (7 * 24 * 60 * 60) / 3;

  // 20%
  uint64 public constant maxFeeBasisPoints = 20 * 100;

  // Pool reserve balance ratio above which price dips below 1 pip and can no longer be represented
  uint64 public constant maxLiquidityPoolReserveRatio = 10**8;

  // Pool reserve balance below which prices can no longer be represented with full pip precision
  uint64 public constant minLiquidityPoolReserveInPips = 10**8;

  // 2%
  uint64 public constant maxPoolInputFeeBasisPoints = 2 * 100;

  // 5%
  uint64 public constant maxPoolOutputAdjustmentBasisPoints = 5 * 100;

  // 1%
  uint64 public constant maxPoolPriceCorrectionBasisPoints = 1 * 100;

  // To convert integer pips to a fractional price shift decimal left by the pip precision of 8
  // decimals places
  uint64 public constant pipPriceMultiplier = 10**8;

  uint8 public constant signatureHashVersion = 3;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

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
  constructor(address exchange, address governance) Owned() {
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
  receive() external payable override onlyExchange {}

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
  function loadExchange() external view override returns (address) {
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
  function loadGovernance() external view override returns (address) {
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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetTransfers } from './AssetTransfers.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { ICustodian, IERC20 } from './Interfaces.sol';
import {
  Asset,
  LiquidityAdditionDepositResult,
  LiquidityRemovalDepositResult
} from './Structs.sol';

library Depositing {
  using AssetRegistry for AssetRegistry.Storage;
  using BalanceTracking for BalanceTracking.Storage;

  /**
   * @dev delegatecall entry point for `Exchange` when depositing native or token assets
   */
  function deposit(
    address wallet,
    Asset memory asset,
    uint256 quantityInAssetUnits,
    ICustodian custodian,
    BalanceTracking.Storage storage balanceTracking
  )
    public
    returns (
      uint64 quantityInPips,
      uint64 newExchangeBalanceInPips,
      uint256 newExchangeBalanceInAssetUnits
    )
  {
    return
      depositAsset(
        wallet,
        asset,
        quantityInAssetUnits,
        custodian,
        balanceTracking
      );
  }

  function depositLiquidityReserves(
    address wallet,
    address assetA,
    address assetB,
    uint256 quantityAInAssetUnits,
    uint256 quantityBInAssetUnits,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) internal returns (LiquidityAdditionDepositResult memory result) {
    Asset memory asset;

    asset = assetRegistry.loadAssetByAddress(assetA);
    result.assetASymbol = asset.symbol;
    (
      result.assetAQuantityInPips,
      result.assetANewExchangeBalanceInPips,
      result.assetANewExchangeBalanceInAssetUnits
    ) = depositAsset(
      wallet,
      asset,
      quantityAInAssetUnits,
      custodian,
      balanceTracking
    );

    asset = assetRegistry.loadAssetByAddress(assetB);
    result.assetBSymbol = asset.symbol;
    (
      result.assetBQuantityInPips,
      result.assetBNewExchangeBalanceInPips,
      result.assetBNewExchangeBalanceInAssetUnits
    ) = depositAsset(
      wallet,
      asset,
      quantityBInAssetUnits,
      custodian,
      balanceTracking
    );
  }

  function depositLiquidityTokens(
    address wallet,
    address liquidityProviderToken,
    uint256 quantityInAssetUnits,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) internal returns (LiquidityRemovalDepositResult memory result) {
    Asset memory asset =
      assetRegistry.loadAssetByAddress(liquidityProviderToken);
    result.assetSymbol = asset.symbol;
    result.assetAddress = liquidityProviderToken;

    (
      result.assetQuantityInPips,
      result.assetNewExchangeBalanceInPips,
      result.assetNewExchangeBalanceInAssetUnits
    ) = depositAsset(
      wallet,
      asset,
      quantityInAssetUnits,
      custodian,
      balanceTracking
    );
  }

  function depositAsset(
    address wallet,
    Asset memory asset,
    uint256 quantityInAssetUnits,
    ICustodian custodian,
    BalanceTracking.Storage storage balanceTracking
  )
    internal
    returns (
      uint64 quantityInPips,
      uint64 newExchangeBalanceInPips,
      uint256 newExchangeBalanceInAssetUnits
    )
  {
    quantityInPips = AssetUnitConversions.assetUnitsToPips(
      quantityInAssetUnits,
      asset.decimals
    );
    require(quantityInPips > 0, 'Quantity is too low');

    // Convert from pips back into asset units to remove any fractional amount that is too small
    // to express in pips. If the asset is ETH, this leftover fractional amount accumulates as dust
    // in the `Exchange` contract. If the asset is a token the `Exchange` will call `transferFrom`
    // without this fractional amount and there will be no dust
    uint256 quantityInAssetUnitsWithoutFractionalPips =
      AssetUnitConversions.pipsToAssetUnits(quantityInPips, asset.decimals);

    // Forward the funds to the `Custodian`
    if (asset.assetAddress == address(0x0)) {
      // If the asset is ETH then the funds were already assigned to the `Exchange` via msg.value.
      AssetTransfers.transferTo(
        payable(address(custodian)),
        asset.assetAddress,
        quantityInAssetUnitsWithoutFractionalPips
      );
    } else {
      // If the asset is a token,  call the transferFrom function on the token contract for the
      // pre-approved asset quantity
      AssetTransfers.transferFrom(
        wallet,
        IERC20(asset.assetAddress),
        payable(address(custodian)),
        quantityInAssetUnitsWithoutFractionalPips
      );
    }

    // Update balance with actual transferred quantity
    newExchangeBalanceInPips = balanceTracking.updateForDeposit(
      wallet,
      asset.assetAddress,
      quantityInPips
    );
    newExchangeBalanceInAssetUnits = AssetUnitConversions.pipsToAssetUnits(
      newExchangeBalanceInPips,
      asset.decimals
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @notice Enums definitions
 */

// Liquidity pools //

enum LiquidityChangeOrigination { OnChain, OffChain }

enum LiquidityChangeType { Addition, Removal }

enum LiquidityChangeState { NotInitiated, Initiated, Executed }

// Order book //

enum OrderSelfTradePrevention {
  // Decrement and cancel
  dc,
  // Cancel oldest
  co,
  // Cancel newest
  cn,
  // Cancel both
  cb
}

enum OrderSide { Buy, Sell }

enum OrderTimeInForce {
  // Good until cancelled
  gtc,
  // Good until time
  gtt,
  // Immediate or cancel
  ioc,
  // Fill or kill
  fok
}

enum OrderType {
  Market,
  Limit,
  LimitMaker,
  StopLoss,
  StopLossLimit,
  TakeProfit,
  TakeProfitLimit
}

// Withdrawals //

enum WithdrawalType { BySymbol, ByAddress }

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Address } from './Address.sol';

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { Constants } from './Constants.sol';
import { Depositing } from './Depositing.sol';
import { LiquidityPools } from './LiquidityPools.sol';
import { LiquidityPoolAdmin } from './LiquidityPoolAdmin.sol';
import { NonceInvalidations } from './NonceInvalidations.sol';
import { Owned } from './Owned.sol';
import { Trading } from './Trading.sol';
import { UUID } from './UUID.sol';
import { Withdrawing } from './Withdrawing.sol';
import { LiquidityChangeOrigination, OrderSide } from './Enums.sol';
import {
  ICustodian,
  IERC20,
  IExchange,
  ILiquidityProviderToken,
  IWETH9
} from './Interfaces.sol';
import {
  Asset,
  HybridTrade,
  LiquidityAddition,
  LiquidityAdditionDepositResult,
  LiquidityChangeExecution,
  LiquidityMigration,
  LiquidityPool,
  LiquidityRemoval,
  LiquidityRemovalDepositResult,
  NonceInvalidation,
  Order,
  OrderBookTrade,
  PoolTrade,
  Withdrawal
} from './Structs.sol';

/**
 * @notice The Exchange contract. Implements all deposit, trade, and withdrawal logic and
 * associated balance tracking
 *
 * @dev The term `asset` refers collectively to ETH and ERC-20 tokens, the term `token` refers only
 * to the latter
 */
contract Exchange is IExchange, Owned {
  using AssetRegistry for AssetRegistry.Storage;
  using BalanceTracking for BalanceTracking.Storage;
  using LiquidityPools for LiquidityPools.Storage;
  using LiquidityPoolAdmin for LiquidityPools.Storage;
  using NonceInvalidations for mapping(address => NonceInvalidation);

  // Events //

  /**
   * @notice Emitted when an admin changes the Chain Propagation Period tunable parameter with
   * `setChainPropagationPeriod`
   */
  event ChainPropagationPeriodChanged(uint256 previousValue, uint256 newValue);
  /**
   * @notice Emitted when a user deposits ETH with `depositEther` or a token with
   * `depositTokenByAddress` or `depositTokenBySymbol`
   */
  event Deposited(
    uint64 index,
    address wallet,
    address assetAddress,
    string assetSymbol,
    uint64 quantityInPips,
    uint64 newExchangeBalanceInPips,
    uint256 newExchangeBalanceInAssetUnits
  );
  /**
   * @notice Emitted when the Dispatcher Wallet submits a hybrid trade for execution with
   * `executeHybridTrade`
   */
  event HybridTradeExecuted(
    address buyWallet,
    address sellWallet,
    string baseAssetSymbol,
    string quoteAssetSymbol,
    uint64 orderBookBaseQuantityInPips,
    uint64 orderBookQuoteQuantityInPips,
    uint64 poolBaseQuantityInPips,
    uint64 poolQuoteQuantityInPips,
    uint64 totalBaseQuantityInPips,
    uint64 totalQuoteQuantityInPips,
    OrderSide takerSide
  );
  /**
   * @notice Emitted when a user initiates an Add Liquidity request via `addLiquidity` or
   * `addLiquidityETH`
   */
  event LiquidityAdditionInitiated(
    address wallet,
    address assetA,
    address assetB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  );
  /**
   * @notice Emitted when the Dispatcher Wallet submits a liquidity addition for execution with
   * `executeAddLiquidity`
   */
  event LiquidityAdditionExecuted(
    address wallet,
    address baseAssetAddress,
    address quoteAssetAddress,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips,
    uint64 liquidityInPips
  );
  /**
   * @notice Emitted when a
   */
  event LiquidityPoolCreated(
    address baseAssetAddress,
    address quoteAssetAddress,
    address liquidityProviderToken
  );
  /**
   * @notice Emitted when an Admin switches liquidity pool asset direction via
   * `reverseLiquidityPoolAssets`
   */
  event LiquidityPoolAssetsReversed(
    address originalBaseAssetAddress,
    address originalQuoteAssetAddress
  );
  /**
   * @notice Emitted when a user initiates a Remove Liquidity request via `removeLiquidity` or
   * `removeLiquidityETH`
   */
  event LiquidityRemovalInitiated(
    address wallet,
    address assetA,
    address assetB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  );
  /**
   * @notice Emitted when the Dispatcher Wallet submits a liquidity removal for execution with
   * `executeRemoveLiquidity`
   */
  event LiquidityRemovalExecuted(
    address wallet,
    address baseAssetAddress,
    address quoteAssetAddress,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips,
    uint64 liquidityInPips
  );
  /**
   * @notice Emitted when the Dispatcher Wallet submits a trade for execution with
   * `executeOrderBookTrade`
   */
  event OrderBookTradeExecuted(
    address buyWallet,
    address sellWallet,
    string baseAssetSymbol,
    string quoteAssetSymbol,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips,
    OrderSide takerSide
  );
  /**
   * @notice Emitted when a user invalidates an order nonce with `invalidateOrderNonce`
   */
  event OrderNonceInvalidated(
    address wallet,
    uint128 nonce,
    uint128 timestampInMs,
    uint256 effectiveBlockNumber
  );
  /**
   * @notice Emitted when the Dispatcher Wallet submits a pool trade for execution with
   * `executePoolTrade`
   */
  event PoolTradeExecuted(
    address wallet,
    string baseAssetSymbol,
    string quoteAssetSymbol,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips,
    OrderSide takerSide
  );
  /**
   * @notice Emitted when an admin adds a symbol to a previously registered and confirmed token
   * via `addTokenSymbol`
   */
  event TokenSymbolAdded(IERC20 assetAddress, string assetSymbol);
  /**
   * @notice Emitted when a user invokes the Exit Wallet mechanism with `exitWallet`
   */
  event WalletExited(address wallet, uint256 effectiveBlockNumber);
  /**
   * @notice Emitted when a user withdraws liquidity reserve assets through the Exit Wallet
   * mechanism with `removeLiquidityExit`
   */
  event WalletExitLiquidityRemoved(
    address wallet,
    address baseAssetAddress,
    address quoteAssetAddress,
    uint64 baseAssetQuantityInPips,
    uint64 quoteAssetQuantityInPips
  );
  /**
   * @notice Emitted when a user withdraws an asset balance through the Exit Wallet mechanism with
   * `withdrawExit`
   */
  event WalletExitWithdrawn(
    address wallet,
    address assetAddress,
    uint64 quantityInPips
  );
  /**
   * @notice Emitted when a user clears the exited status of a wallet previously exited with
   * `exitWallet`
   */
  event WalletExitCleared(address wallet);
  /**
   * @notice Emitted when the Dispatcher Wallet submits a withdrawal with `withdraw`
   */
  event Withdrawn(
    address wallet,
    address assetAddress,
    string assetSymbol,
    uint64 quantityInPips,
    uint64 newExchangeBalanceInPips,
    uint256 newExchangeBalanceInAssetUnits
  );

  // Internally used structs //

  struct WalletExit {
    bool exists;
    uint256 effectiveBlockNumber;
  }

  // Storage //

  // Asset registry data
  AssetRegistry.Storage _assetRegistry;
  // Balance tracking
  BalanceTracking.Storage _balanceTracking;
  // CLOB - mapping of order wallet hash => isComplete
  mapping(bytes32 => bool) _completedOrderHashes;
  // CLOB - mapping of wallet => last invalidated timestampInMs
  mapping(address => NonceInvalidation) _nonceInvalidations;
  // CLOB - mapping of order hash => filled quantity in pips
  mapping(bytes32 => uint64) _partiallyFilledOrderQuantitiesInPips;
  // Custodian
  ICustodian _custodian;
  // Deposit index
  uint64 public _depositIndex;
  // Exits
  mapping(address => WalletExit) public _walletExits;
  // Liquidity pools
  address _liquidityMigrator;
  LiquidityPools.Storage _liquidityPools;
  // Withdrawals - mapping of withdrawal wallet hash => isComplete
  mapping(bytes32 => bool) _completedWithdrawalHashes;
  // Tunable parameters
  uint256 _chainPropagationPeriod;
  address _dispatcherWallet;
  address _feeWallet;

  /**
   * @notice Instantiate a new `Exchange` contract
   *
   * @dev Sets `_balanceMigrationSource` to first argument, and `_owner` and `_admin` to
   * `msg.sender`
   */
  constructor(
    IExchange balanceMigrationSource,
    address feeWallet,
    string memory nativeAssetSymbol
  ) Owned() {
    require(
      address(balanceMigrationSource) == address(0x0) ||
        Address.isContract(address(balanceMigrationSource)),
      'Invalid migration source'
    );
    _balanceTracking.migrationSource = balanceMigrationSource;

    setFeeWallet(feeWallet);

    _assetRegistry.nativeAssetSymbol = nativeAssetSymbol;

    // Deposits must be manually enabled via `setDepositIndex`
    _depositIndex = Constants.depositIndexNotSet;
  }

  /**
   * @notice Sets the address of the `Custodian` contract
   *
   * @dev The `Custodian` accepts `Exchange` and `Governance` addresses in its constructor, after
   * which they can only be changed by the `Governance` contract itself. Therefore the `Custodian`
   * must be deployed last and its address set here on an existing `Exchange` contract. This value
   * is immutable once set and cannot be changed again
   *
   * @param newCustodian The address of the `Custodian` contract deployed against this `Exchange`
   * contract's address
   */
  function setCustodian(ICustodian newCustodian) external onlyAdmin {
    require(
      _custodian == ICustodian(payable(address(0x0))),
      'Custodian can only be set once'
    );
    require(Address.isContract(address(newCustodian)), 'Invalid address');

    _custodian = newCustodian;
  }

  /**
   * @notice Enable depositing assets into the Exchange by setting the current deposit index from
   * the old Exchange contract's value
   *
   * @dev The Whistler Exchange does not expose its `_depositIndex` making this manual migration
   * necessary. If this Exchange is not upgraded from Whistler, call this function with
   * `newDepositIndex` set to 0. This value cannot be changed again once set
   *
   * @param newDepositIndex The value of `_depositIndex` currently set on the old Exchange contract
   */
  function setDepositIndex(uint64 newDepositIndex) external onlyAdmin {
    require(
      _depositIndex == Constants.depositIndexNotSet,
      'Can only be set once'
    );
    require(
      newDepositIndex != Constants.depositIndexNotSet,
      'Invalid deposit index'
    );

    _depositIndex = newDepositIndex;
  }

  /*** Tunable parameters ***/

  /**
   * @notice Sets a new Chain Propagation Period - the block delay after which order nonce
   * invalidations and wallet exits go into effect
   *
   * @param newChainPropagationPeriod The new Chain Propagation Period expressed as a number of
   * blocks. Must be less than `Constants.maxChainPropagationPeriod`
   */
  function setChainPropagationPeriod(uint256 newChainPropagationPeriod)
    external
    onlyAdmin
  {
    require(
      newChainPropagationPeriod < Constants.maxChainPropagationPeriod,
      'New period greater than max'
    );

    uint256 oldChainPropagationPeriod = _chainPropagationPeriod;
    _chainPropagationPeriod = newChainPropagationPeriod;

    emit ChainPropagationPeriodChanged(
      oldChainPropagationPeriod,
      newChainPropagationPeriod
    );
  }

  /**
   * @notice Sets the address of the Fee wallet
   *
   * @dev Trade and Withdraw fees will accrue in the `_balances` mappings for this wallet
   * @dev Visibility public instead of external to allow invocation from `constructor`
   *
   * @param newFeeWallet The new Fee wallet. Must be different from the current one
   */
  function setFeeWallet(address newFeeWallet) public onlyAdmin {
    require(newFeeWallet != address(0x0), 'Invalid wallet address');
    require(newFeeWallet != _feeWallet, 'Must be different from current');

    _feeWallet = newFeeWallet;
  }

  /**
   * @notice Sets the address of the `Migrator` contract
   *
   * @param newMigrator The new Migrator contract. Must be different from the current one
   */
  function setMigrator(address newMigrator) external onlyAdmin {
    require(Address.isContract(address(newMigrator)), 'Invalid address');
    require(
      newMigrator != _liquidityMigrator,
      'Must be different from current'
    );

    _liquidityMigrator = newMigrator;
  }

  // Accessors //

  /**
   * @notice Load a wallet's balance by asset address, in asset units
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in asset units of asset at `assetAddress` currently
   * deposited by `wallet`
   */
  function loadBalanceInAssetUnitsByAddress(
    address wallet,
    address assetAddress
  ) external view returns (uint256) {
    return
      _assetRegistry.loadBalanceInAssetUnitsByAddress(
        wallet,
        assetAddress,
        _balanceTracking
      );
  }

  /**
   * @notice Load a wallet's balance by asset symbol, in asset units
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetSymbol The asset symbol to load the wallet's balance for
   *
   * @return The quantity denominated in asset units of asset `assetSymbol` currently deposited
   * by `wallet`
   */
  function loadBalanceInAssetUnitsBySymbol(
    address wallet,
    string calldata assetSymbol
  ) external view returns (uint256) {
    return
      _assetRegistry.loadBalanceInAssetUnitsBySymbol(
        wallet,
        assetSymbol,
        _balanceTracking
      );
  }

  /**
   * @notice Load a wallet's balance by asset address, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset at `assetAddress` currently deposited by
   * `wallet`
   */
  function loadBalanceInPipsByAddress(address wallet, address assetAddress)
    external
    view
    override
    returns (uint64)
  {
    return
      AssetRegistry.loadBalanceInPipsByAddress(
        wallet,
        assetAddress,
        _balanceTracking
      );
  }

  /**
   * @notice Load a wallet's balance by asset symbol, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetSymbol The asset symbol to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset with `assetSymbol` currently deposited by
   * `wallet`
   */
  function loadBalanceInPipsBySymbol(
    address wallet,
    string calldata assetSymbol
  ) external view returns (uint64) {
    return
      _assetRegistry.loadBalanceInPipsBySymbol(
        wallet,
        assetSymbol,
        _balanceTracking
      );
  }

  /**
   * @notice Load the address of the Custodian contract
   *
   * @return The address of the Custodian contract
   */
  function loadCustodian() external view override returns (ICustodian) {
    return _custodian;
  }

  /**
   * @notice Load the address of the Fee wallet
   *
   * @return The address of the Fee wallet
   */
  function loadFeeWallet() external view returns (address) {
    return _feeWallet;
  }

  /**
   * @notice Load the internally-tracked liquidity pool descriptor for a base-quote asset pair
   *
   * @return A `LiquidityPool` struct encapsulating the current state of the internally-tracked
   * liquidity pool for the given base-quote asset pair. Reverts if no such pool exists
   */
  function loadLiquidityPoolByAssetAddresses(
    address baseAssetAddress,
    address quoteAssetAddress
  ) external view returns (LiquidityPool memory) {
    return
      _liquidityPools.loadLiquidityPoolByAssetAddresses(
        baseAssetAddress,
        quoteAssetAddress
      );
  }

  /**
   * @notice Load the address of the Migrator contract
   *
   * @return The address of the Migrator contract
   */
  function loadLiquidityMigrator() external view returns (address) {
    return _liquidityMigrator;
  }

  /**
   * @notice Load the quantity filled so far for a partially filled orders
   *
   * @dev Invalidating an order nonce will not clear partial fill quantities for earlier orders
   * because
   * the gas cost would potentially be unbound
   *
   * @param orderHash The order hash as originally signed by placing wallet that uniquely
   * identifies an order
   *
   * @return For partially filled orders, the amount filled so far in pips. For orders in all other
   * states, 0
   */
  function loadPartiallyFilledOrderQuantityInPips(bytes32 orderHash)
    external
    view
    returns (uint64)
  {
    return _partiallyFilledOrderQuantitiesInPips[orderHash];
  }

  // Depositing //

  /**
   * @notice DO NOT send assets directly to the `Exchange`, instead use the appropriate deposit
   * function
   *
   * @dev Internally used to unwrap WETH during liquidity pool migrations via
   * `migrateLiquidityPool`. The sender is only required to be a contract rather than locking it
   * to a particular WETH instance to allow for migrating from multiple pools that use different
   * WETH contracts
   */
  receive() external payable {
    require(Address.isContract(msg.sender), 'Use depositEther');
  }

  /**
   * @notice Deposit ETH
   */
  function depositEther() external payable {
    deposit(
      msg.sender,
      _assetRegistry.loadAssetByAddress(address(0x0)),
      msg.value
    );
  }

  /**
   * @notice Deposit `IERC20` compliant tokens
   *
   * @param tokenAddress The token contract address
   * @param quantityInAssetUnits The quantity to deposit. The sending wallet must first call the
   * `approve` method on the token contract for at least this quantity first
   */
  function depositTokenByAddress(
    address tokenAddress,
    uint256 quantityInAssetUnits
  ) external {
    Asset memory asset = _assetRegistry.loadAssetByAddress(tokenAddress);

    require(address(tokenAddress) != address(0x0), 'Use depositEther');

    deposit(msg.sender, asset, quantityInAssetUnits);
  }

  /**
   * @notice Deposit `IERC20` compliant tokens
   *
   * @param assetSymbol The case-sensitive symbol string for the token
   * @param quantityInAssetUnits The quantity to deposit. The sending wallet must first call the
   * `approve` method on the token contract for at least this quantity first
   */
  function depositTokenBySymbol(
    string memory assetSymbol,
    uint256 quantityInAssetUnits
  ) external {
    Asset memory asset =
      _assetRegistry.loadAssetBySymbol(
        assetSymbol,
        AssetRegistry.getCurrentTimestampInMs()
      );

    require(address(asset.assetAddress) != address(0x0), 'Use depositEther');

    deposit(msg.sender, asset, quantityInAssetUnits);
  }

  function deposit(
    address wallet,
    Asset memory asset,
    uint256 quantityInAssetUnits
  ) private {
    // Deposits are disabled until `setDepositIndex` is called successfully
    require(_depositIndex != Constants.depositIndexNotSet, 'Deposits disabled');

    // Calling exitWallet disables deposits immediately on mining, in contrast to withdrawals and
    // trades which respect the Chain Propagation Period given by `effectiveBlockNumber` via
    // `isWalletExitFinalized`
    require(!_walletExits[wallet].exists, 'Wallet exited');

    (
      uint64 quantityInPips,
      uint64 newExchangeBalanceInPips,
      uint256 newExchangeBalanceInAssetUnits
    ) =
      Depositing.deposit(
        wallet,
        asset,
        quantityInAssetUnits,
        _custodian,
        _balanceTracking
      );

    _depositIndex++;

    emit Deposited(
      _depositIndex,
      wallet,
      asset.assetAddress,
      asset.symbol,
      quantityInPips,
      newExchangeBalanceInPips,
      newExchangeBalanceInAssetUnits
    );
  }

  // Trades //

  /**
   * @notice Settles a trade between two orders submitted and matched off-chain
   *
   * @param buy An `Order` struct encoding the parameters of the buy-side order (receiving base,
   * giving quote)
   * @param sell An `Order` struct encoding the parameters of the sell-side order (giving base,
   * receiving quote)
   * @param orderBookTrade An `OrderBookTrade` struct encoding the parameters of this trade
   * execution of the two orders
   */
  function executeOrderBookTrade(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory orderBookTrade
  ) external onlyDispatcher {
    require(
      !isWalletExitFinalized(buy.walletAddress),
      'Buy wallet exit finalized'
    );
    require(
      !isWalletExitFinalized(sell.walletAddress),
      'Sell wallet exit finalized'
    );

    Trading.executeOrderBookTrade(
      buy,
      sell,
      orderBookTrade,
      _feeWallet,
      _assetRegistry,
      _balanceTracking,
      _completedOrderHashes,
      _nonceInvalidations,
      _partiallyFilledOrderQuantitiesInPips
    );

    emit OrderBookTradeExecuted(
      buy.walletAddress,
      sell.walletAddress,
      orderBookTrade.baseAssetSymbol,
      orderBookTrade.quoteAssetSymbol,
      orderBookTrade.grossBaseQuantityInPips,
      orderBookTrade.grossQuoteQuantityInPips,
      orderBookTrade.makerSide == OrderSide.Buy ? OrderSide.Sell : OrderSide.Buy
    );
  }

  /**
   * @notice Settles a trade between pool liquidity and an order submitted and matched off-chain
   *
   * @param order An `Order` struct encoding the parameters of the taker order
   * @param poolTrade A `PoolTrade` struct encoding the parameters of this trade execution between
   * the order and pool liquidity
   */
  function executePoolTrade(Order memory order, PoolTrade memory poolTrade)
    external
    onlyDispatcher
  {
    require(
      !isWalletExitFinalized(order.walletAddress),
      'Order wallet exit finalized'
    );

    Trading.executePoolTrade(
      order,
      poolTrade,
      _feeWallet,
      _assetRegistry,
      _liquidityPools,
      _balanceTracking,
      _completedOrderHashes,
      _nonceInvalidations,
      _partiallyFilledOrderQuantitiesInPips
    );

    emit PoolTradeExecuted(
      order.walletAddress,
      poolTrade.baseAssetSymbol,
      poolTrade.quoteAssetSymbol,
      poolTrade.grossBaseQuantityInPips,
      poolTrade.grossQuoteQuantityInPips,
      order.side
    );
  }

  /**
   * @notice Settles a trade between pool liquidity and two order submitted and matched off-chain.
   * The taker order is filled by pool liquidity up to the maker order price and the remainder of
   * the taker order quantity is then filled by the maker order
   *
   * @param buy An `Order` struct encoding the parameters of the buy-side order (receiving base,
   * giving quote)
   * @param sell An `Order` struct encoding the parameters of the sell-side order (giving base,
   * receiving quote)
   * @param hybridTrade A `HybridTrade` struct encoding the parameters of this trade execution
   * between the two orders and pool liquidity
   */
  function executeHybridTrade(
    Order memory buy,
    Order memory sell,
    HybridTrade memory hybridTrade
  ) external onlyDispatcher {
    // OrderBook trade validations
    require(
      !isWalletExitFinalized(buy.walletAddress),
      'Buy wallet exit finalized'
    );
    require(
      !isWalletExitFinalized(sell.walletAddress),
      'Sell wallet exit finalized'
    );

    Trading.executeHybridTrade(
      buy,
      sell,
      hybridTrade,
      _feeWallet,
      _assetRegistry,
      _liquidityPools,
      _balanceTracking,
      _completedOrderHashes,
      _nonceInvalidations,
      _partiallyFilledOrderQuantitiesInPips
    );

    emit HybridTradeExecuted(
      buy.walletAddress,
      sell.walletAddress,
      hybridTrade.orderBookTrade.baseAssetSymbol,
      hybridTrade.orderBookTrade.quoteAssetSymbol,
      hybridTrade.orderBookTrade.grossBaseQuantityInPips,
      hybridTrade.orderBookTrade.grossQuoteQuantityInPips,
      hybridTrade.poolTrade.grossBaseQuantityInPips,
      hybridTrade.poolTrade.grossQuoteQuantityInPips,
      hybridTrade.orderBookTrade.grossBaseQuantityInPips +
        hybridTrade.poolTrade.grossBaseQuantityInPips,
      hybridTrade.orderBookTrade.grossQuoteQuantityInPips +
        hybridTrade.poolTrade.grossQuoteQuantityInPips,
      hybridTrade.orderBookTrade.makerSide == OrderSide.Buy
        ? OrderSide.Sell
        : OrderSide.Buy
    );
  }

  // Withdrawing //

  /**
   * @notice Settles a user withdrawal submitted off-chain. Calls restricted to currently
   * whitelisted Dispatcher wallet
   *
   * @param withdrawal A `Withdrawal` struct encoding the parameters of the withdrawal
   */
  function withdraw(Withdrawal memory withdrawal) public onlyDispatcher {
    require(!isWalletExitFinalized(withdrawal.walletAddress), 'Wallet exited');

    (
      uint64 newExchangeBalanceInPips,
      uint256 newExchangeBalanceInAssetUnits,
      address assetAddress,
      string memory assetSymbol
    ) =
      Withdrawing.withdraw(
        withdrawal,
        _custodian,
        _feeWallet,
        _assetRegistry,
        _balanceTracking,
        _completedWithdrawalHashes
      );

    emit Withdrawn(
      withdrawal.walletAddress,
      assetAddress,
      assetSymbol,
      withdrawal.grossQuantityInPips,
      newExchangeBalanceInPips,
      newExchangeBalanceInAssetUnits
    );
  }

  // Liquidity pools //

  /**
   * @notice Create a new internally tracked liquidity pool and associated LP token
   *
   * @param baseAssetAddress The base asset address
   * @param quoteAssetAddress The quote asset address
   */
  function createLiquidityPool(
    address baseAssetAddress,
    address quoteAssetAddress
  ) external onlyAdmin {
    _liquidityPools.createLiquidityPool(
      baseAssetAddress,
      quoteAssetAddress,
      _assetRegistry
    );
  }

  /**
   * @notice Migrate reserve assets into an internally tracked liquidity pool and mint the
   * specified quantity of the associated LP token. If the pool and LP token do not already exist
   * then create new ones
   *
   * @dev This function should be called by a Migrator contract associated with a Farm by invoking
   * the `migrate` function on a Farm instance, passing in the `pid` of a pool holding tokens
   * compliant with the `IUniswapV2Pair` interface. The Migrator will then liquidate all tokens
   * held in the pool by calling the `burn` function on the Pair contract, transfer the output
   * reserve assets to the Exchange, and call this function. The Exchange then mints the
   * `desiredQuantity` of the new IDEX LP tokens back to the Migrator. This `desiredLiquidity`
   * should be exactly equal to the asset unit quantity of Pair tokens originally deposited in the
   * Farm pool
   *
   * @param token0 The address of `token0` in the Pair contract being migrated
   * @param token1 The address of `token1` in the Pair contract being migrated
   * @param isToken1Quote If true, maps `token0` to the base asset and `token1` to the quote asset
   * in the internally tracked pool; otherwise maps `token1` to base and `token0` to quote
   * @param desiredLiquidity The quantity of asset units of the new LP token to mint back to the
   * Migrator
   * @param to Recipient of the liquidity tokens
   *
   * @return liquidityProviderToken The address of the liquidity provider ERC-20 token representing
   * liquidity in the internally-tracked pool corresponding to the asset pair
   */

  function migrateLiquidityPool(
    address token0,
    address token1,
    bool isToken1Quote,
    uint256 desiredLiquidity,
    address to,
    address payable WETH
  ) external onlyMigrator returns (address liquidityProviderToken) {
    liquidityProviderToken = _liquidityPools.migrateLiquidityPool(
      LiquidityMigration(
        token0,
        token1,
        isToken1Quote,
        desiredLiquidity,
        to,
        IWETH9(WETH)
      ),
      _custodian,
      _assetRegistry
    );
  }

  /**
   * @notice Reverse the base and quote assets in an internally tracked liquidity pool
   *
   * @param baseAssetAddress The base asset address
   * @param quoteAssetAddress The quote asset address
   */
  function reverseLiquidityPoolAssets(
    address baseAssetAddress,
    address quoteAssetAddress
  ) external onlyAdmin {
    _liquidityPools.reverseLiquidityPoolAssets(
      baseAssetAddress,
      quoteAssetAddress
    );

    emit LiquidityPoolAssetsReversed(baseAssetAddress, quoteAssetAddress);
  }

  /**
   * @notice Adds liquidity to a ERC-20⇄ERC-20 pool
   *
   * @dev To cover all possible scenarios, `msg.sender` should have already given the Exchange an
   * allowance of at least `amountADesired`/`amountBDesired` on `tokenA`/`tokenB`
   *
   * @param tokenA The contract address of the desired token
   * @param tokenB The contract address of the desired token
   * @param amountADesired The amount of `tokenA` to add as liquidity if the B/A price is <=
   * `amountBDesired`/`amountADesired` (A depreciates)
   * @param amountBDesired The amount of `tokenB` to add as liquidity if the A/B price is <=
   * `amountADesired`/`amountBDesired` (B depreciates)
   * @param amountAMin Bounds the extent to which the B/A price can go up. Must be <=
   * `amountADesired`
   * @param amountBMin Bounds the extent to which the A/B price can go up. Must be <=
   * `amountBDesired`
   * @param to Recipient of the liquidity tokens
   * @param deadline Unix timestamp in seconds after which the transaction will revert
   */
  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external {
    // Calling exitWallet disables on-chain add liquidity initiation immediately on mining, in
    // contrast to withdrawals, trades, and liquidity change executions which respect the Chain
    // Propagation Period given by `effectiveBlockNumber` via `isWalletExitFinalized`
    require(!_walletExits[msg.sender].exists, 'Wallet exited');

    LiquidityAdditionDepositResult memory result =
      _liquidityPools.addLiquidity(
        LiquidityAddition(
          Constants.signatureHashVersion,
          LiquidityChangeOrigination.OnChain,
          0,
          msg.sender,
          tokenA,
          tokenB,
          amountADesired,
          amountBDesired,
          amountAMin,
          amountBMin,
          to,
          deadline,
          bytes('')
        ),
        _custodian,
        _assetRegistry,
        _balanceTracking
      );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      tokenA,
      result.assetASymbol,
      result.assetAQuantityInPips,
      result.assetANewExchangeBalanceInPips,
      result.assetANewExchangeBalanceInAssetUnits
    );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      tokenB,
      result.assetBSymbol,
      result.assetBQuantityInPips,
      result.assetBNewExchangeBalanceInPips,
      result.assetBNewExchangeBalanceInAssetUnits
    );

    emit LiquidityAdditionInitiated(
      msg.sender,
      tokenA,
      tokenB,
      amountADesired,
      amountBDesired,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  /**
   * @notice Adds liquidity to a ERC-20⇄ETH pool
   *
   * @dev To cover all possible scenarios, `msg.sender` should have already given the router an
   * allowance of at least `amountTokenDesired` on `token`. `msg.value` is treated as
   * `amountETHDesired`
   *
   * @param token The contract address of the desired token
   * @param amountTokenDesired The amount of token to add as liquidity if the ETH/token
   * price is <= `msg.value`/`amountTokenDesired` (token depreciates)
   * @param amountTokenMin The amount of ETH to add as liquidity if the token/ETH
   * price is <= `amountTokenDesired`/`msg.value` (ETH depreciates)
   * @param amountETHMin Bounds the extent to which the token/ETH price can go up. Must be
   * <= `msg.value`
   * @param to Recipient of the liquidity tokens
   * @param deadline Unix timestamp in seconds after which the transaction will revert
   */
  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external payable {
    // Calling exitWallet disables on-chain add liquidity initiation immediately on mining, in
    // contrast to withdrawals, trades, and liquidity change executions which respect the Chain
    // Propagation Period given by `effectiveBlockNumber` via `isWalletExitFinalized`
    require(!_walletExits[msg.sender].exists, 'Wallet exited');

    LiquidityAdditionDepositResult memory result =
      _liquidityPools.addLiquidity(
        LiquidityAddition(
          Constants.signatureHashVersion,
          LiquidityChangeOrigination.OnChain,
          0,
          msg.sender,
          token,
          address(0x0),
          amountTokenDesired,
          msg.value,
          amountTokenMin,
          amountETHMin,
          to,
          deadline,
          bytes('')
        ),
        _custodian,
        _assetRegistry,
        _balanceTracking
      );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      token,
      result.assetASymbol,
      result.assetAQuantityInPips,
      result.assetANewExchangeBalanceInPips,
      result.assetANewExchangeBalanceInAssetUnits
    );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      address(0x0),
      result.assetBSymbol,
      result.assetBQuantityInPips,
      result.assetBNewExchangeBalanceInPips,
      result.assetBNewExchangeBalanceInAssetUnits
    );

    emit LiquidityAdditionInitiated(
      msg.sender,
      token,
      address(0x0),
      amountTokenDesired,
      msg.value,
      amountTokenMin,
      amountETHMin,
      to,
      deadline
    );
  }

  /**
   * @notice Settles a liquidity addition by transferring deposited assets from wallet balances to
   * pool reserves and minting LP tokens
   *
   * @param addition A `LiquidityAddition` struct encoding the parameters of the addition requested
   * by the user either on-chain via `addLiquidity` or `addLiquidityETH` or off-chain via
   * ECDSA-signed API request
   * @param execution A `LiquidityChangeExecution` struct encoding the parameters of this liquidity
   * addition execution that meets the terms of the request
   */
  function executeAddLiquidity(
    LiquidityAddition calldata addition,
    LiquidityChangeExecution calldata execution
  ) external onlyDispatcher {
    require(!isWalletExitFinalized(addition.wallet), 'Wallet exit finalized');

    _liquidityPools.executeAddLiquidity(
      addition,
      execution,
      _feeWallet,
      address(_custodian),
      _balanceTracking
    );

    emit LiquidityAdditionExecuted(
      addition.wallet,
      execution.baseAssetAddress,
      execution.quoteAssetAddress,
      execution.grossBaseQuantityInPips,
      execution.grossQuoteQuantityInPips,
      execution.liquidityInPips
    );
  }

  /**
   * @notice Removes liquidity from an ERC-20⇄ERC-20 pool
   *
   * @dev `msg.sender` should have already given the Exchange an allowance of at least `liquidity`
   * on the pool
   *
   * @param tokenA The contract address of the desired token
   * @param tokenB The contract address of the desired token
   * @param liquidity The amount of liquidity tokens to remove
   * @param amountAMin The minimum amount of `tokenA` that must be received
   * @param amountBMin The minimum amount of `tokenB` that must be received
   * @param to Recipient of the underlying assets
   * @param deadline Unix timestamp in seconds after which the transaction will revert
   */

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) public {
    // Calling exitWallet disables on-chain remove liquidity initiation immediately on mining, in
    // contrast to withdrawals, trades, and liquidity change executions which respect the Chain
    // Propagation Period given by `effectiveBlockNumber` via `isWalletExitFinalized`
    require(!_walletExits[msg.sender].exists, 'Wallet exited');

    LiquidityRemovalDepositResult memory result =
      _liquidityPools.removeLiquidity(
        LiquidityRemoval(
          Constants.signatureHashVersion,
          LiquidityChangeOrigination.OnChain,
          0,
          msg.sender,
          tokenA,
          tokenB,
          liquidity,
          amountAMin,
          amountBMin,
          payable(to),
          deadline,
          bytes('')
        ),
        _custodian,
        _assetRegistry,
        _balanceTracking
      );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      result.assetAddress,
      result.assetSymbol,
      result.assetQuantityInPips,
      result.assetNewExchangeBalanceInPips,
      result.assetNewExchangeBalanceInAssetUnits
    );

    emit LiquidityRemovalInitiated(
      msg.sender,
      tokenA,
      tokenB,
      liquidity,
      amountAMin,
      amountBMin,
      to,
      deadline
    );
  }

  /**
   * @notice Removes liquidity from an ERC-20⇄ETH pool and receive ETH
   *
   * @dev `msg.sender` should have already given the Exchange an allowance of at least `liquidity`
   * on the pool
   *
   * @param token token The contract address of the desired token
   * @param token liquidity The amount of liquidity tokens to remove
   * @param token amountTokenMin The minimum amount of token that must be received
   * @param token amountETHMin The minimum amount of ETH that must be received
   * @param to Recipient of the underlying assets
   * @param deadline Unix timestamp in seconds after which the transaction will revert
   */
  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external {
    // Calling exitWallet disables on-chain remove liquidity initiation immediately on mining, in
    // contrast to withdrawals, trades, and liquidity change executions which respect the Chain
    // Propagation Period given by `effectiveBlockNumber` via `isWalletExitFinalized`
    require(!_walletExits[msg.sender].exists, 'Wallet exited');

    LiquidityRemovalDepositResult memory result =
      _liquidityPools.removeLiquidity(
        LiquidityRemoval(
          Constants.signatureHashVersion,
          LiquidityChangeOrigination.OnChain,
          0,
          msg.sender,
          token,
          address(0x0),
          liquidity,
          amountTokenMin,
          amountETHMin,
          payable(to),
          deadline,
          bytes('')
        ),
        _custodian,
        _assetRegistry,
        _balanceTracking
      );

    emit Deposited(
      ++_depositIndex,
      msg.sender,
      result.assetAddress,
      result.assetSymbol,
      result.assetQuantityInPips,
      result.assetNewExchangeBalanceInPips,
      result.assetNewExchangeBalanceInAssetUnits
    );

    emit LiquidityRemovalInitiated(
      msg.sender,
      token,
      address(0x0),
      liquidity,
      amountTokenMin,
      amountETHMin,
      payable(to),
      deadline
    );
  }

  /**
   * @notice Settles a liquidity removal by burning deposited LP tokens and transferring reserve
   * assets from pool reserves to the recipient
   *
   * @param removal A `LiquidityRemoval` struct encoding the parameters of the removal requested
   * by the user either 1) on-chain via `removeLiquidity` or `removeLiquidityETH`, 2) off-chain via
   * ECDSA-signed API request, or 3) requested by the Dispatcher wallet itself in case the wallet
   * has exited and its liquidity positions must be liquidated automatically
   * @param execution A `LiquidityChangeExecution` struct encoding the parameters of this liquidity
   * removal execution that meets the terms of the request
   */
  function executeRemoveLiquidity(
    LiquidityRemoval calldata removal,
    LiquidityChangeExecution calldata execution
  ) external onlyDispatcher {
    _liquidityPools.executeRemoveLiquidity(
      removal,
      execution,
      _walletExits[removal.wallet].exists,
      ICustodian(_custodian),
      _feeWallet,
      _assetRegistry,
      _balanceTracking
    );

    emit LiquidityRemovalExecuted(
      removal.wallet,
      execution.baseAssetAddress,
      execution.quoteAssetAddress,
      execution.grossBaseQuantityInPips,
      execution.grossQuoteQuantityInPips,
      execution.liquidityInPips
    );
  }

  /**
   * @notice Remove liquidity from a pool immediately without the need for Dispatcher wallet
   * settlement. The wallet must be exited and the Chain Propagation Period must have already
   * passed since calling `exitWallet`. The LP tokens must already be deposited in the Exchange
   *
   * @param baseAssetAddress The base asset address
   * @param quoteAssetAddress The quote asset address
   */
  function removeLiquidityExit(
    address baseAssetAddress,
    address quoteAssetAddress
  ) external {
    require(isWalletExitFinalized(msg.sender), 'Wallet exit not finalized');

    (
      uint64 outputBaseAssetQuantityInPips,
      uint64 outputQuoteAssetQuantityInPips
    ) =
      _liquidityPools.removeLiquidityExit(
        baseAssetAddress,
        quoteAssetAddress,
        ICustodian(_custodian),
        _balanceTracking
      );

    emit WalletExitLiquidityRemoved(
      msg.sender,
      baseAssetAddress,
      quoteAssetAddress,
      outputBaseAssetQuantityInPips,
      outputQuoteAssetQuantityInPips
    );
  }

  // Wallet exits //

  /**
   * @notice Flags the sending wallet as exited, immediately disabling deposits and on-chain
   * intitiation of liquidity changes upon mining. After the Chain Propagation Period passes
   * trades, withdrawals, and liquidity change executions are also disabled for the wallet,
   * and assets may then be withdrawn one at a time via `withdrawExit`
   */
  function exitWallet() external {
    require(!_walletExits[msg.sender].exists, 'Wallet already exited');

    _walletExits[msg.sender] = WalletExit(
      true,
      block.number + _chainPropagationPeriod
    );

    emit WalletExited(msg.sender, block.number + _chainPropagationPeriod);
  }

  /**
   * @notice Withdraw the entire balance of an asset for an exited wallet. The Chain Propagation
   * Period must have already passed since calling `exitWallet`
   *
   * @param assetAddress The address of the asset to withdraw
   */
  function withdrawExit(address assetAddress) external {
    require(isWalletExitFinalized(msg.sender), 'Wallet exit not finalized');

    // Update wallet balance
    uint64 previousExchangeBalanceInPips =
      Withdrawing.withdrawExit(
        assetAddress,
        _custodian,
        _assetRegistry,
        _balanceTracking
      );

    emit WalletExitWithdrawn(
      msg.sender,
      assetAddress,
      previousExchangeBalanceInPips
    );
  }

  /**
   * @notice Clears exited status of sending wallet. Upon mining immediately enables
   * deposits, trades, and withdrawals by sending wallet
   */
  function clearWalletExit() external {
    require(isWalletExitFinalized(msg.sender), 'Wallet exit not finalized');

    delete _walletExits[msg.sender];

    emit WalletExitCleared(msg.sender);
  }

  function isWalletExitFinalized(address wallet) internal view returns (bool) {
    WalletExit storage exit = _walletExits[wallet];
    return exit.exists && exit.effectiveBlockNumber <= block.number;
  }

  // Invalidation //

  /**
   * @notice Invalidate all order nonces with a timestampInMs lower than the one provided
   *
   * @param nonce A Version 1 UUID. After calling and once the Chain Propagation Period has
   * elapsed, `executeOrderBookTrade` will reject order nonces from this wallet with a
   * timestampInMs component lower than the one provided
   */
  function invalidateOrderNonce(uint128 nonce) external {
    (uint64 timestampInMs, uint256 effectiveBlockNumber) =
      _nonceInvalidations.invalidateOrderNonce(nonce, _chainPropagationPeriod);

    emit OrderNonceInvalidated(
      msg.sender,
      nonce,
      timestampInMs,
      effectiveBlockNumber
    );
  }

  // Asset registry //

  /**
   * @notice Initiate registration process for a token asset. Only `IERC20` compliant tokens can be
   * added - ETH is hardcoded in the registry
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract to add
   * @param symbol The symbol identifying the token asset
   * @param decimals The decimal precision of the token
   */
  function registerToken(
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external onlyAdmin {
    _assetRegistry.registerToken(tokenAddress, symbol, decimals);
  }

  /**
   * @notice Finalize registration process for a token asset. All parameters must exactly match a
   * previous call to `registerToken`
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract to add
   * @param symbol The symbol identifying the token asset
   * @param decimals The decimal precision of the token
   */
  function confirmTokenRegistration(
    IERC20 tokenAddress,
    string calldata symbol,
    uint8 decimals
  ) external onlyAdmin {
    _assetRegistry.confirmTokenRegistration(tokenAddress, symbol, decimals);
  }

  /**
   * @notice Add a symbol to a token that has already been registered and confirmed
   *
   * @param tokenAddress The address of the `IERC20` compliant token contract the symbol will
   * identify
   * @param symbol The symbol identifying the token asset
   */
  function addTokenSymbol(IERC20 tokenAddress, string calldata symbol)
    external
    onlyAdmin
  {
    _assetRegistry.addTokenSymbol(tokenAddress, symbol);
    emit TokenSymbolAdded(tokenAddress, symbol);
  }

  /**
   * @notice Loads an asset descriptor struct by its symbol and timestamp
   *
   * @dev Since multiple token addresses can potentially share the same symbol (in case of a token
   * swap/contract upgrade) the provided `timestampInMs` is compared against each asset's
   * `confirmedTimestampInMs` to uniquely determine the newest asset for the symbol at that point
   * in time
   *
   * @param assetSymbol The asset's symbol
   * @param timestampInMs Point in time used to disambiguate multiple tokens with same symbol
   *
   * @return A `Asset` record describing the asset
   */
  function loadAssetBySymbol(string calldata assetSymbol, uint64 timestampInMs)
    external
    view
    returns (Asset memory)
  {
    return _assetRegistry.loadAssetBySymbol(assetSymbol, timestampInMs);
  }

  // Dispatcher whitelisting //

  /**
   * @notice Sets the wallet whitelisted to dispatch transactions calling the
   * `executeOrderBookTrade`, `executePoolTrade`, `executeHybridTrade`, `withdraw`,
   * `executeAddLiquidity`, and `executeRemoveLiquidity` functions
   *
   * @param newDispatcherWallet The new whitelisted dispatcher wallet. Must be different from the
   * current one
   */
  function setDispatcher(address newDispatcherWallet) external onlyAdmin {
    require(newDispatcherWallet != address(0x0), 'Invalid wallet address');
    require(
      newDispatcherWallet != _dispatcherWallet,
      'Must be different from current'
    );
    _dispatcherWallet = newDispatcherWallet;
  }

  /**
   * @notice Clears the currently set whitelisted dispatcher wallet, effectively disabling calling
   * the `executeOrderBookTrade`, `executePoolTrade`, `executeHybridTrade`, `withdraw`,
   * `executeAddLiquidity`, and `executeRemoveLiquidity` functions until a new wallet is set with
   * `setDispatcher`
   */
  function removeDispatcher() external onlyAdmin {
    _dispatcherWallet = address(0x0);
  }

  modifier onlyDispatcher() {
    require(msg.sender == _dispatcherWallet, 'Caller is not dispatcher');
    _;
  }

  // Migrator whitelisting //

  modifier onlyMigrator() {
    require(msg.sender == _liquidityMigrator, 'Caller is not Migrator');
    _;
  }

  // Asset skimming //

  /**
   * @notice Sends tokens mistakenly sent directly to the `Exchange` to the fee wallet (the
   * `receive` function rejects ETH except when wrapping/unwrapping)
   */
  function skim(address tokenAddress) external onlyAdmin {
    AssetRegistry.skim(tokenAddress, _feeWallet);
  }

  // Exchange upgrades //

  /**
   * @notice Following an Exchange upgrade via the Governance contract, this function allows the
   * new Exchange to reclaim blockchain storage by cleanup up old balance tracking
   */
  function cleanupWalletBalance(address wallet, address assetAddress) external {
    address currentExchange = ICustodian(_custodian).loadExchange();
    require(msg.sender == currentExchange, 'Caller is not Exchange');

    delete _balanceTracking.balancesByWalletAssetPair[wallet][assetAddress];
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { ERC20 } from './ERC20.sol';

contract FaucetToken is ERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 private _maximumSupply;
  uint256 private _numTokensReleasedByFaucet;

  uint256 constant INITIAL_SUPPLY = 10**12;
  uint256 constant MAX_SUPPLY = 10**15;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint256 numTokensReleasedByFaucet
  ) ERC20('', '') {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;

    _numTokensReleasedByFaucet =
      numTokensReleasedByFaucet *
      10**uint256(decimals_);
    _maximumSupply = MAX_SUPPLY * 10**uint256(decimals_);

    _mint(msg.sender, INITIAL_SUPPLY * 10**uint256(decimals_));
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  function faucet(address wallet) public {
    require(wallet != address(0), 'Invalid wallet');
    require(totalSupply() < _maximumSupply, 'Max supply exceeded');

    _mint(wallet, _numTokensReleasedByFaucet);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Address } from './Address.sol';

import { ICustodian } from './Interfaces.sol';
import { Owned } from './Owned.sol';

contract Governance is Owned {
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
  constructor(uint256 blockDelay) Owned() {
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
    require(
      _custodian == ICustodian(payable(address(0x0))),
      'Custodian can only be set once'
    );
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
      block.number + _blockDelay
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
      block.number + _blockDelay
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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { ECDSA } from './ECDSA.sol';

import { Constants } from './Constants.sol';
import { LiquidityChangeType, WithdrawalType } from './Enums.sol';
import {
  LiquidityAddition,
  LiquidityRemoval,
  Order,
  Withdrawal
} from './Structs.sol';

/**
 * @notice Library helpers for building hashes and verifying wallet signatures
 */
library Hashing {
  function isSignatureValid(
    bytes32 hash,
    bytes memory signature,
    address signer
  ) internal pure returns (bool) {
    return
      ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature) == signer;
  }

  // Hash construction //

  function getLiquidityAdditionHash(LiquidityAddition memory addition)
    internal
    pure
    returns (bytes32)
  {
    require(
      addition.signatureHashVersion == Constants.signatureHashVersion,
      'Signature hash version invalid'
    );

    return
      keccak256(
        abi.encodePacked(
          addition.signatureHashVersion,
          uint8(LiquidityChangeType.Addition),
          uint8(addition.origination),
          addition.nonce,
          addition.wallet,
          addition.assetA,
          addition.assetB,
          addition.amountADesired,
          addition.amountBDesired,
          addition.amountAMin,
          addition.amountBMin,
          addition.to,
          addition.deadline
        )
      );
  }

  function getLiquidityRemovalHash(LiquidityRemoval memory removal)
    internal
    pure
    returns (bytes32)
  {
    require(
      removal.signatureHashVersion == Constants.signatureHashVersion,
      'Signature hash version invalid'
    );

    return
      keccak256(
        abi.encodePacked(
          removal.signatureHashVersion,
          uint8(LiquidityChangeType.Removal),
          uint8(removal.origination),
          removal.nonce,
          removal.wallet,
          removal.assetA,
          removal.assetB,
          removal.liquidity,
          removal.amountAMin,
          removal.amountBMin,
          removal.to,
          removal.deadline
        )
      );
  }

  /**
   * @dev As a gas optimization, base and quote symbols are passed in separately and combined to
   * verify the wallet hash, since this is cheaper than splitting the market symbol into its two
   * constituent asset symbols
   */
  function getOrderHash(
    Order memory order,
    string memory baseSymbol,
    string memory quoteSymbol
  ) internal pure returns (bytes32) {
    require(
      order.signatureHashVersion == Constants.signatureHashVersion,
      'Signature hash version invalid'
    );
    // Placing all the fields in a single `abi.encodePacked` call causes a `stack too deep` error
    return
      keccak256(
        abi.encodePacked(
          abi.encodePacked(
            order.signatureHashVersion,
            order.nonce,
            order.walletAddress,
            string(abi.encodePacked(baseSymbol, '-', quoteSymbol)),
            uint8(order.orderType),
            uint8(order.side),
            // Ledger qtys and prices are in pip, but order was signed by wallet owner with decimal
            // values
            pipToDecimal(order.quantityInPips)
          ),
          abi.encodePacked(
            order.isQuantityInQuote,
            order.limitPriceInPips > 0
              ? pipToDecimal(order.limitPriceInPips)
              : '',
            order.stopPriceInPips > 0
              ? pipToDecimal(order.stopPriceInPips)
              : '',
            order.clientOrderId,
            uint8(order.timeInForce),
            uint8(order.selfTradePrevention),
            order.cancelAfter
          )
        )
      );
  }

  function getWithdrawalHash(Withdrawal memory withdrawal)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encodePacked(
          withdrawal.nonce,
          withdrawal.walletAddress,
          // Ternary branches must resolve to the same type, so wrap in idempotent encodePacked
          withdrawal.withdrawalType == WithdrawalType.BySymbol
            ? abi.encodePacked(withdrawal.assetSymbol)
            : abi.encodePacked(withdrawal.assetAddress),
          pipToDecimal(withdrawal.grossQuantityInPips),
          withdrawal.autoDispatchEnabled
        )
      );
  }

  /**
   * @dev Converts an integer pip quantity back into the fixed-precision decimal pip string
   * originally signed by the wallet. For example, 1234567890 becomes '12.34567890'
   */
  function pipToDecimal(uint256 pips) private pure returns (string memory) {
    // Inspired by https://github.com/provable-things/ethereum-api/blob/831f4123816f7a3e57ebea171a3cdcf3b528e475/oraclizeAPI_0.5.sol#L1045-L1062
    uint256 copy = pips;
    uint256 length;
    while (copy != 0) {
      length++;
      copy /= 10;
    }
    if (length < 9) {
      length = 9; // a zero before the decimal point plus 8 decimals
    }
    length++; // for the decimal point

    bytes memory decimal = new bytes(length);
    for (uint256 i = length; i > 0; i--) {
      if (length - i == 8) {
        decimal[i - 1] = bytes1(uint8(46)); // period
      } else {
        decimal[i - 1] = bytes1(uint8(48 + (pips % 10)));
        pips /= 10;
      }
    }
    return string(decimal);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { HybridTrade } from './Structs.sol';

library HybridTradeHelpers {
  /**
   * @dev Total fees paid by taker from received asset across orderbook and pool trades. Does not
   * include pool input fees nor pool output adjustment
   */
  function calculateTakerFeeQuantityInPips(HybridTrade memory self)
    internal
    pure
    returns (uint64)
  {
    return
      self.takerGasFeeQuantityInPips +
      self.orderBookTrade.takerFeeQuantityInPips;
  }

  /**
   * @dev Gross quantity received by taker
   */
  function calculateTakerGrossReceivedQuantityInPips(HybridTrade memory self)
    internal
    pure
    returns (uint64)
  {
    return (
      self.orderBookTrade.takerFeeAssetAddress ==
        self.orderBookTrade.baseAssetAddress
        ? self.orderBookTrade.grossBaseQuantityInPips +
          self.poolTrade.grossBaseQuantityInPips
        : self.orderBookTrade.grossQuoteQuantityInPips +
          self.poolTrade.grossQuoteQuantityInPips
    );
  }

  /**
   * @dev Gross quantity received by maker
   */
  function getMakerGrossQuantityInPips(HybridTrade memory self)
    internal
    pure
    returns (uint64)
  {
    return
      self.orderBookTrade.takerFeeAssetAddress ==
        self.orderBookTrade.baseAssetAddress
        ? self.orderBookTrade.grossQuoteQuantityInPips
        : self.orderBookTrade.grossBaseQuantityInPips;
  }

  /**
   * @dev Net quantity received by maker
   */
  function getMakerNetQuantityInPips(HybridTrade memory self)
    internal
    pure
    returns (uint64)
  {
    return
      self.orderBookTrade.takerFeeAssetAddress ==
        self.orderBookTrade.baseAssetAddress
        ? self.orderBookTrade.netQuoteQuantityInPips
        : self.orderBookTrade.netBaseQuantityInPips;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { Constants } from './Constants.sol';
import { HybridTradeHelpers } from './HybridTradeHelpers.sol';
import { OrderBookTradeValidations } from './OrderBookTradeValidations.sol';
import { OrderSide } from './Enums.sol';
import { PoolTradeHelpers } from './PoolTradeHelpers.sol';
import { PoolTradeValidations } from './PoolTradeValidations.sol';
import { Validations } from './Validations.sol';
import {
  Asset,
  HybridTrade,
  Order,
  OrderBookTrade,
  NonceInvalidation,
  PoolTrade
} from './Structs.sol';

library HybridTradeValidations {
  using AssetRegistry for AssetRegistry.Storage;
  using HybridTradeHelpers for HybridTrade;
  using PoolTradeHelpers for PoolTrade;

  function validateHybridTrade(
    Order memory buy,
    Order memory sell,
    HybridTrade memory hybridTrade,
    AssetRegistry.Storage storage assetRegistry,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) internal view returns (bytes32 buyHash, bytes32 sellHash) {
    require(
      buy.walletAddress != sell.walletAddress,
      'Self-trading not allowed'
    );

    require(
      hybridTrade.orderBookTrade.baseAssetAddress ==
        hybridTrade.poolTrade.baseAssetAddress &&
        hybridTrade.orderBookTrade.quoteAssetAddress ==
        hybridTrade.poolTrade.quoteAssetAddress,
      'Mismatched trade assets'
    );
    validateFees(hybridTrade);

    // Order book trade validations
    Validations.validateOrderNonces(buy, sell, nonceInvalidations);
    (buyHash, sellHash) = OrderBookTradeValidations.validateOrderSignatures(
      buy,
      sell,
      hybridTrade.orderBookTrade
    );
    OrderBookTradeValidations.validateAssetPair(
      buy,
      sell,
      hybridTrade.orderBookTrade,
      assetRegistry
    );
    OrderBookTradeValidations.validateLimitPrices(
      buy,
      sell,
      hybridTrade.orderBookTrade
    );

    // Pool trade validations
    Order memory takerOrder =
      hybridTrade.orderBookTrade.makerSide == OrderSide.Buy ? sell : buy;
    PoolTradeValidations.validateLimitPrice(takerOrder, hybridTrade.poolTrade);
  }

  function validatePoolPrice(
    Order memory makerOrder,
    uint64 baseAssetReserveInPips,
    uint64 quoteAssetReserveInPips
  ) internal pure {
    if (
      makerOrder.side == OrderSide.Buy &&
      Validations.isLimitOrderType(makerOrder.orderType)
    ) {
      // Price of pool must not be better (lower) than resting buy price
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          baseAssetReserveInPips,
          makerOrder.limitPriceInPips
        ) <= quoteAssetReserveInPips,
        'Pool marginal buy price exceeded'
      );
    }

    if (
      makerOrder.side == OrderSide.Sell &&
      Validations.isLimitOrderType(makerOrder.orderType)
    ) {
      // Price of pool must not be better (higher) than resting sell price
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          baseAssetReserveInPips,
          makerOrder.limitPriceInPips
          // Allow additional pip buffers for integer rounding
        ) +
          1 >=
          quoteAssetReserveInPips - 1,
        'Pool marginal sell price exceeded'
      );
    }
  }

  function validateFees(HybridTrade memory hybridTrade) private pure {
    require(
      hybridTrade.poolTrade.takerGasFeeQuantityInPips == 0,
      'Non-zero pool gas fee'
    );

    // Validate maker fee on orderbook trade
    uint64 grossQuantityInPips = hybridTrade.getMakerGrossQuantityInPips();
    require(
      Validations.isFeeQuantityValid(
        (grossQuantityInPips - hybridTrade.getMakerNetQuantityInPips()),
        grossQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive maker fee'
    );

    OrderSide takerOrderSide =
      hybridTrade.orderBookTrade.makerSide == OrderSide.Buy
        ? OrderSide.Sell
        : OrderSide.Buy;

    // Validate taker fees across orderbook and pool trades
    grossQuantityInPips = hybridTrade
      .calculateTakerGrossReceivedQuantityInPips();
    require(
      Validations.isFeeQuantityValid(
        hybridTrade.poolTrade.calculatePoolOutputAdjustment(takerOrderSide),
        grossQuantityInPips,
        Constants.maxPoolOutputAdjustmentBasisPoints
      ),
      'Excessive pool output adjustment'
    );
    require(
      Validations.isFeeQuantityValid(
        hybridTrade.calculateTakerFeeQuantityInPips(),
        grossQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive taker fee'
    );

    // Validate price correction, if present
    if (hybridTrade.poolTrade.takerPriceCorrectionFeeQuantityInPips > 0) {
      // Price correction only allowed for hybrid trades with a taker sell
      require(
        hybridTrade.orderBookTrade.makerSide == OrderSide.Buy,
        'Price correction not allowed'
      );

      // Do not allow quote output with a price correction as the latter is effectively a negative
      // net quote output
      require(
        hybridTrade.poolTrade.netQuoteQuantityInPips == 0,
        'Quote out not allowed with price correction'
      );

      grossQuantityInPips = hybridTrade
        .poolTrade
        .getOrderGrossReceivedQuantityInPips(takerOrderSide);
      if (
        hybridTrade.poolTrade.takerPriceCorrectionFeeQuantityInPips >
        grossQuantityInPips
      ) {
        require(
          Validations.isFeeQuantityValid(
            hybridTrade.poolTrade.takerPriceCorrectionFeeQuantityInPips -
              grossQuantityInPips,
            grossQuantityInPips,
            Constants.maxPoolPriceCorrectionBasisPoints
          ),
          'Excessive price correction'
        );
      }
    }

    Validations.validatePoolTradeInputFees(
      takerOrderSide,
      hybridTrade.poolTrade
    );
    Validations.validateOrderBookTradeFees(hybridTrade.orderBookTrade);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Order, OrderBookTrade, Withdrawal } from './Structs.sol';

/**
 * @notice Interface of the ERC20 standard as defined in the EIP, but with no return values for
 * transfer and transferFrom. By asserting expected balance changes when calling these two methods
 * we can safely ignore their return values. This allows support of non-compliant tokens that do not
 * return a boolean. See https://github.com/ethereum/solidity/issues/4116
 */
interface IERC20 {
  /**
   * @notice Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @notice Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @notice Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external;

  /**
   * @notice Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @notice Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Most implementing contracts return a boolean value indicating whether the operation succeeded, but
   * we ignore this and rely on asserting balance changes instead
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @notice Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @notice Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @notice Interface to Custodian contract. Used by Exchange and Governance contracts for internal
 * delegate calls
 */
interface ICustodian {
  /**
   * @notice ETH can only be sent by the Exchange
   */
  receive() external payable;

  /**
   * @notice Withdraw any asset and amount to a target wallet
   *
   * @dev No balance checking performed
   *
   * @param wallet The wallet to which assets will be returned
   * @param asset The address of the asset to withdraw (native asset or ERC-20 contract)
   * @param quantityInAssetUnits The quantity in asset units to withdraw
   */
  function withdraw(
    address payable wallet,
    address asset,
    uint256 quantityInAssetUnits
  ) external;

  /**
   * @notice Load address of the currently whitelisted Exchange contract
   *
   * @return The address of the currently whitelisted Exchange contract
   */
  function loadExchange() external view returns (address);

  /**
   * @notice Sets a new Exchange contract address
   *
   * @param newExchange The address of the new whitelisted Exchange contract
   */
  function setExchange(address newExchange) external;

  /**
   * @notice Load address of the currently whitelisted Governance contract
   *
   * @return The address of the currently whitelisted Governance contract
   */
  function loadGovernance() external view returns (address);

  /**
   * @notice Sets a new Governance contract address
   *
   * @param newGovernance The address of the new whitelisted Governance contract
   */
  function setGovernance(address newGovernance) external;
}

/**
 * @notice Interface to Whistler Exchange contract
 *
 * @dev Used for lazy balance migrations from old to new Exchange after upgrade
 */
interface IExchange {
  /**
   * @notice Load a wallet's balance by asset address, in pips
   *
   * @param wallet The wallet address to load the balance for. Can be different from `msg.sender`
   * @param assetAddress The asset address to load the wallet's balance for
   *
   * @return The quantity denominated in pips of asset at `assetAddress` currently deposited by `wallet`
   */
  function loadBalanceInPipsByAddress(address wallet, address assetAddress)
    external
    view
    returns (uint64);

  /**
   * @notice Load the address of the Custodian contract
   *
   * @return The address of the Custodian contract
   */
  function loadCustodian() external view returns (ICustodian);
}

interface ILiquidityProviderToken {
  function custodian() external returns (ICustodian);

  function baseAssetAddress() external returns (address);

  function quoteAssetAddress() external returns (address);

  function baseAssetSymbol() external returns (string memory);

  function quoteAssetSymbol() external returns (string memory);

  function token0() external returns (address);

  function token1() external returns (address);

  function burn(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external;

  function mint(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external;

  function reverseAssets() external;
}

interface IWETH9 is IERC20 {
  receive() external payable;

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { LiquidityChangeExecution } from './Structs.sol';

library LiquidityChangeExecutionHelpers {
  /**
   * @dev Quantity in pips of gross base quantity sent to fee wallet
   */
  function calculateBaseFeeQuantityInPips(LiquidityChangeExecution memory self)
    internal
    pure
    returns (uint64)
  {
    return self.grossBaseQuantityInPips - self.netBaseQuantityInPips;
  }

  /**
   * @dev Quantity in pips of gross quote quantity sent to fee wallet
   */
  function calculateQuoteFeeQuantityInPips(LiquidityChangeExecution memory self)
    internal
    pure
    returns (uint64)
  {
    return self.grossQuoteQuantityInPips - self.netQuoteQuantityInPips;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { Constants } from './Constants.sol';
import { IERC20 } from './Interfaces.sol';
import {
  LiquidityChangeExecutionHelpers
} from './LiquidityChangeExecutionHelpers.sol';
import { LiquidityPoolHelpers } from './LiquidityPoolHelpers.sol';
import { Validations } from './Validations.sol';
import {
  LiquidityAddition,
  LiquidityChangeExecution,
  LiquidityPool,
  LiquidityRemoval
} from './Structs.sol';

library LiquidityChangeExecutionValidations {
  using LiquidityChangeExecutionHelpers for LiquidityChangeExecution;
  using LiquidityPoolHelpers for LiquidityPool;

  function validateLiquidityAddition(
    LiquidityAddition memory addition,
    LiquidityChangeExecution memory execution,
    LiquidityPool memory pool
  ) internal view {
    require(
      ((execution.baseAssetAddress == addition.assetA &&
        execution.quoteAssetAddress == addition.assetB) ||
        (execution.baseAssetAddress == addition.assetB &&
          execution.quoteAssetAddress == addition.assetA)),
      'Asset address mismatch'
    );

    (
      uint256 minBaseInAssetUnits,
      uint256 desiredBaseInAssetUnits,
      uint256 minQuoteInAssetUnits,
      uint256 desiredQuoteInAssetUnits
    ) =
      execution.baseAssetAddress == addition.assetA
        ? (
          addition.amountAMin,
          addition.amountADesired,
          addition.amountBMin,
          addition.amountBDesired
        )
        : (
          addition.amountBMin,
          addition.amountBDesired,
          addition.amountAMin,
          addition.amountADesired
        );
    (uint64 minBase, uint64 maxBase, uint64 minQuote, uint64 maxQuote) =
      (
        AssetUnitConversions.assetUnitsToPips(
          minBaseInAssetUnits,
          pool.baseAssetDecimals
        ),
        AssetUnitConversions.assetUnitsToPips(
          desiredBaseInAssetUnits,
          pool.baseAssetDecimals
        ),
        AssetUnitConversions.assetUnitsToPips(
          minQuoteInAssetUnits,
          pool.quoteAssetDecimals
        ),
        AssetUnitConversions.assetUnitsToPips(
          desiredQuoteInAssetUnits,
          pool.quoteAssetDecimals
        )
      );

    require(
      execution.grossBaseQuantityInPips >= minBase,
      'Min base quantity not met'
    );
    require(
      execution.grossBaseQuantityInPips <= maxBase,
      'Desired base quantity exceeded'
    );
    require(
      execution.grossQuoteQuantityInPips >= minQuote,
      'Min quote quantity not met'
    );
    require(
      execution.grossQuoteQuantityInPips <= maxQuote,
      'Desired quote quantity exceeded'
    );

    require(
      execution.liquidityInPips > 0 &&
        execution.liquidityInPips ==
        pool.calculateOutputLiquidityInPips(
          execution.netBaseQuantityInPips,
          execution.netQuoteQuantityInPips
        ),
      'Invalid liquidity minted'
    );

    validateLiquidityChangeExecutionFees(execution);
  }

  function validateLiquidityRemoval(
    LiquidityRemoval memory removal,
    LiquidityChangeExecution memory execution,
    LiquidityPool memory pool
  ) internal view {
    require(
      ((execution.baseAssetAddress == removal.assetA &&
        execution.quoteAssetAddress == removal.assetB) ||
        (execution.baseAssetAddress == removal.assetB &&
          execution.quoteAssetAddress == removal.assetA)),
      'Asset address mismatch'
    );

    require(
      execution.grossBaseQuantityInPips > 0 &&
        execution.grossQuoteQuantityInPips > 0,
      'Gross quantities must be nonzero'
    );

    (uint256 minBaseInAssetUnits, uint256 minQuoteInAssetUnits) =
      execution.baseAssetAddress == removal.assetA
        ? (removal.amountAMin, removal.amountBMin)
        : (removal.amountBMin, removal.amountAMin);
    (uint64 minBase, uint64 minQuote) =
      (
        AssetUnitConversions.assetUnitsToPips(
          minBaseInAssetUnits,
          pool.baseAssetDecimals
        ),
        AssetUnitConversions.assetUnitsToPips(
          minQuoteInAssetUnits,
          pool.quoteAssetDecimals
        )
      );

    require(
      execution.grossBaseQuantityInPips >= minBase,
      'Min base quantity not met'
    );
    require(
      execution.grossQuoteQuantityInPips >= minQuote,
      'Min quote quantity not met'
    );

    require(
      execution.liquidityInPips ==
        AssetUnitConversions.assetUnitsToPips(
          removal.liquidity,
          Constants.liquidityProviderTokenDecimals
        ),
      'Invalid liquidity burned'
    );

    (
      uint256 expectedBaseAssetQuantityInPips,
      uint256 expectedQuoteAssetQuantityInPips
    ) = pool.calculateOutputAssetQuantitiesInPips(execution.liquidityInPips);

    require(
      execution.grossBaseQuantityInPips == expectedBaseAssetQuantityInPips,
      'Invalid base quantity'
    );
    require(
      execution.grossQuoteQuantityInPips == expectedQuoteAssetQuantityInPips,
      'Invalid quote quantity'
    );

    validateLiquidityChangeExecutionFees(execution);
  }

  function validateLiquidityChangeExecutionFees(
    LiquidityChangeExecution memory execution
  ) private pure {
    require(
      Validations.isFeeQuantityValid(
        execution.calculateBaseFeeQuantityInPips(),
        execution.grossBaseQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive base fee'
    );
    require(
      Validations.isFeeQuantityValid(
        execution.calculateQuoteFeeQuantityInPips(),
        execution.grossQuoteQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive quote fee'
    );
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetTransfers } from './AssetTransfers.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { Constants } from './Constants.sol';
import { LiquidityPools } from './LiquidityPools.sol';
import { LiquidityProviderToken } from './LiquidityProviderToken.sol';
import { Validations } from './Validations.sol';
import {
  ICustodian,
  IERC20,
  ILiquidityProviderToken,
  IWETH9
} from './Interfaces.sol';

import { Asset, LiquidityMigration, LiquidityPool } from './Structs.sol';

library LiquidityPoolAdmin {
  using AssetRegistry for AssetRegistry.Storage;

  function createLiquidityPool(
    LiquidityPools.Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress,
    AssetRegistry.Storage storage assetRegistry
  ) public returns (address liquidityProviderToken) {
    {
      return
        address(
          createLiquidityPoolByAssetAddresses(
            self,
            baseAssetAddress,
            quoteAssetAddress,
            assetRegistry
          )
            .liquidityProviderToken
        );
    }
  }

  function migrateLiquidityPool(
    LiquidityPools.Storage storage self,
    LiquidityMigration memory migration,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry
  ) public returns (address liquidityProviderToken) {
    require(
      AssetUnitConversions.assetUnitsToPips(
        migration.desiredLiquidity,
        Constants.liquidityProviderTokenDecimals
      ) > 0,
      'Desired liquidity too low'
    );

    {
      // Map Pair token reserve addresses to provided market base/quote addresses
      (
        address baseAssetAddress,
        address quoteAssetAddress,
        uint256 baseAssetQuantityInAssetUnits,
        uint256 quoteAssetQuantityInAssetUnits
      ) = transferMigratedTokenReservesToCustodian(migration, custodian);

      LiquidityPool storage pool;
      pool = loadOrCreateLiquidityPoolByAssetAddresses(
        self,
        baseAssetAddress,
        quoteAssetAddress,
        assetRegistry
      );
      liquidityProviderToken = address(pool.liquidityProviderToken);

      {
        // Convert transferred reserve amounts to pips and store
        pool.baseAssetReserveInPips += AssetUnitConversions.assetUnitsToPips(
          baseAssetQuantityInAssetUnits,
          pool.baseAssetDecimals
        );
        require(pool.baseAssetReserveInPips > 0, 'Insufficient base quantity');

        pool.quoteAssetReserveInPips += AssetUnitConversions.assetUnitsToPips(
          quoteAssetQuantityInAssetUnits,
          pool.quoteAssetDecimals
        );
        require(
          pool.quoteAssetReserveInPips > 0,
          'Insufficient quote quantity'
        );

        Validations.validatePoolReserveRatio(pool);
      }

      // Mint desired liquidity to Farm to complete migration
      ILiquidityProviderToken(liquidityProviderToken).mint(
        address(this),
        migration.desiredLiquidity,
        baseAssetQuantityInAssetUnits,
        quoteAssetQuantityInAssetUnits,
        migration.to
      );
    }
  }

  function reverseLiquidityPoolAssets(
    LiquidityPools.Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress
  ) public {
    LiquidityPool memory pool =
      LiquidityPools.loadLiquidityPoolByAssetAddresses(
        self,
        baseAssetAddress,
        quoteAssetAddress
      );

    delete self.poolsByAddresses[baseAssetAddress][quoteAssetAddress];
    self.poolsByAddresses[quoteAssetAddress][baseAssetAddress] = pool;

    (
      pool.baseAssetReserveInPips,
      pool.baseAssetDecimals,
      pool.quoteAssetReserveInPips,
      pool.quoteAssetDecimals
    ) = (
      pool.quoteAssetReserveInPips,
      pool.quoteAssetDecimals,
      pool.baseAssetReserveInPips,
      pool.baseAssetDecimals
    );
    pool.liquidityProviderToken.reverseAssets();
  }

  // Helpers //

  function loadOrCreateLiquidityPoolByAssetAddresses(
    LiquidityPools.Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress,
    AssetRegistry.Storage storage assetRegistry
  ) private returns (LiquidityPool storage pool) {
    pool = self.poolsByAddresses[baseAssetAddress][quoteAssetAddress];

    if (!pool.exists) {
      pool = createLiquidityPoolByAssetAddresses(
        self,
        baseAssetAddress,
        quoteAssetAddress,
        assetRegistry
      );
    }
  }

  function createLiquidityPoolByAssetAddresses(
    LiquidityPools.Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress,
    AssetRegistry.Storage storage assetRegistry
  ) private returns (LiquidityPool storage pool) {
    // Use bidirectional mapping to require uniqueness of pools by asset pair regardless of
    // base-quote positions
    require(
      address(
        self.liquidityProviderTokensByAddress[baseAssetAddress][
          quoteAssetAddress
        ]
      ) == address(0x0),
      'Pool already exists'
    );

    // Create internally-tracked liquidity pool
    pool = self.poolsByAddresses[baseAssetAddress][quoteAssetAddress];
    pool.exists = true;

    // Store asset decimals to avoid redundant asset registry lookups
    Asset memory asset;
    asset = assetRegistry.loadAssetByAddress(baseAssetAddress);
    string memory baseAssetSymbol = asset.symbol;
    pool.baseAssetDecimals = asset.decimals;
    asset = assetRegistry.loadAssetByAddress(quoteAssetAddress);
    string memory quoteAssetSymbol = asset.symbol;
    pool.quoteAssetDecimals = asset.decimals;

    // Create an LP token contract tied to this market. Construct salt from byte-sorted assets to
    // maintain a stable address if asset direction is reversed via `reverseLiquidityPoolAssets`
    bytes32 salt =
      keccak256(
        baseAssetAddress < quoteAssetAddress
          ? abi.encodePacked(baseAssetAddress, quoteAssetAddress)
          : abi.encodePacked(quoteAssetAddress, baseAssetAddress)
      );
    ILiquidityProviderToken liquidityProviderToken =
      new LiquidityProviderToken{ salt: salt }(
        baseAssetAddress,
        quoteAssetAddress,
        baseAssetSymbol,
        quoteAssetSymbol
      );

    // Store LP token address in both pair directions to allow lookup by unordered asset pairs
    // during on-chain initiated liquidity removals
    self.liquidityProviderTokensByAddress[baseAssetAddress][
      quoteAssetAddress
    ] = ILiquidityProviderToken(liquidityProviderToken);
    self.liquidityProviderTokensByAddress[quoteAssetAddress][
      baseAssetAddress
    ] = ILiquidityProviderToken(liquidityProviderToken);

    // Associate the newly created LP token contract with the pool
    pool.liquidityProviderToken = ILiquidityProviderToken(
      liquidityProviderToken
    );

    // Build an asset descriptor for the new LP token and add it to the registry. There is no need
    // to validate against it already existing as the preceeding CREATE2 will revert on duplicate
    // asset pairs
    Asset memory lpTokenAsset =
      Asset({
        exists: true,
        assetAddress: address(liquidityProviderToken),
        symbol: string(
          abi.encodePacked('ILP-', baseAssetSymbol, '-', quoteAssetSymbol)
        ),
        decimals: Constants.liquidityProviderTokenDecimals,
        isConfirmed: true,
        confirmedTimestampInMs: uint64(block.timestamp * 1000) // Block timestamp is in seconds, store ms
      });
    assetRegistry.assetsByAddress[lpTokenAsset.assetAddress] = lpTokenAsset;
    assetRegistry.assetsBySymbol[lpTokenAsset.symbol].push(lpTokenAsset);
  }

  function transferMigratedTokenReservesToCustodian(
    LiquidityMigration memory migration,
    ICustodian custodian
  )
    private
    returns (
      address baseAssetAddress,
      address quoteAssetAddress,
      uint256 baseAssetQuantityInAssetUnits,
      uint256 quoteAssetQuantityInAssetUnits
    )
  {
    // Obtain reserve amounts sent to the Exchange
    uint256 reserve0 = IERC20(migration.token0).balanceOf(address(this));
    uint256 reserve1 = IERC20(migration.token1).balanceOf(address(this));
    // Transfer reserves to Custodian and unwrap WETH if needed
    transferMigratedTokenReserveToCustodian(
      migration.token0,
      reserve0,
      migration.WETH,
      custodian
    );
    transferMigratedTokenReserveToCustodian(
      migration.token1,
      reserve1,
      migration.WETH,
      custodian
    );

    address unwrappedToken0 =
      migration.token0 == address(migration.WETH)
        ? address(0x0)
        : migration.token0;
    address unwrappedToken1 =
      migration.token1 == address(migration.WETH)
        ? address(0x0)
        : migration.token1;

    return
      migration.isToken1Quote
        ? (unwrappedToken0, unwrappedToken1, reserve0, reserve1)
        : (unwrappedToken1, unwrappedToken0, reserve1, reserve0);
  }

  function transferMigratedTokenReserveToCustodian(
    address token,
    uint256 reserve,
    IWETH9 WETH,
    ICustodian custodian
  ) private {
    // Unwrap WETH
    if (token == address(WETH)) {
      WETH.withdraw(reserve);
      AssetTransfers.transferTo(
        payable(address(custodian)),
        address(0x0),
        reserve
      );
    } else {
      AssetTransfers.transferTo(payable(address(custodian)), token, reserve);
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { Constants } from './Constants.sol';
import { IERC20 } from './Interfaces.sol';
import { LiquidityPool } from './Structs.sol';
import { Math } from './Math.sol';

library LiquidityPoolHelpers {
  function calculateCurrentPoolPriceInPips(LiquidityPool memory self)
    internal
    pure
    returns (uint64)
  {
    if (self.baseAssetReserveInPips == 0) {
      return 0;
    }

    return
      Math.multiplyPipsByFraction(
        Constants.pipPriceMultiplier,
        self.quoteAssetReserveInPips,
        self.baseAssetReserveInPips
      );
  }

  /**
   * @dev Calculate reserve asset quantities to remove from a pool for a given liquidity amount
   */
  function calculateOutputAssetQuantitiesInPips(
    LiquidityPool memory self,
    uint64 liquidityToBurnInPips
  )
    internal
    view
    returns (
      uint64 outputBaseAssetQuantityInPips,
      uint64 outputQuoteAssetQuantityInPips
    )
  {
    uint64 totalLiquidityInPips =
      AssetUnitConversions.assetUnitsToPips(
        IERC20(address(self.liquidityProviderToken)).totalSupply(),
        Constants.liquidityProviderTokenDecimals
      );

    // Use fraction of total liquidity burned to calculate proportionate base amount out
    outputBaseAssetQuantityInPips = Math.multiplyPipsByFraction(
      self.baseAssetReserveInPips,
      liquidityToBurnInPips,
      totalLiquidityInPips
    );
    // Calculate quote amount out that maintains the current pool price given above base amount out
    outputQuoteAssetQuantityInPips =
      self.quoteAssetReserveInPips -
      Math.multiplyPipsByFraction(
        self.baseAssetReserveInPips - outputBaseAssetQuantityInPips,
        calculateCurrentPoolPriceInPips(self),
        Constants.pipPriceMultiplier,
        true
      );
  }

  /**
   * @dev Calculate LP token quantity to mint for given reserve asset quantities
   */
  function calculateOutputLiquidityInPips(
    LiquidityPool memory self,
    uint64 baseQuantityInPips,
    uint64 quoteQuantityInPips
  ) internal view returns (uint64 outputLiquidityInPips) {
    uint256 totalSupplyInAssetUnits =
      IERC20(address(self.liquidityProviderToken)).totalSupply();

    // For initial deposit use geometric mean of reserve quantities
    if (totalSupplyInAssetUnits == 0) {
      // There is no need to check for uint64 overflow since sqrt(max * max) = max
      return
        uint64(Math.sqrt(uint256(baseQuantityInPips) * quoteQuantityInPips));
    }

    uint64 totalLiquidityInPips =
      AssetUnitConversions.assetUnitsToPips(
        totalSupplyInAssetUnits,
        Constants.liquidityProviderTokenDecimals
      );

    return
      Math.min(
        Math.multiplyPipsByFraction(
          totalLiquidityInPips,
          baseQuantityInPips,
          self.baseAssetReserveInPips
        ),
        Math.multiplyPipsByFraction(
          totalLiquidityInPips,
          quoteQuantityInPips,
          self.quoteAssetReserveInPips
        )
      );
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetTransfers } from './AssetTransfers.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { Constants } from './Constants.sol';
import { Depositing } from './Depositing.sol';
import { Hashing } from './Hashing.sol';
import {
  LiquidityChangeExecutionValidations
} from './LiquidityChangeExecutionValidations.sol';
import { LiquidityPoolHelpers } from './LiquidityPoolHelpers.sol';
import { LiquidityProviderToken } from './LiquidityProviderToken.sol';
import { PoolTradeHelpers } from './PoolTradeHelpers.sol';
import { Validations } from './Validations.sol';
import { Withdrawing } from './Withdrawing.sol';
import {
  ICustodian,
  IERC20,
  ILiquidityProviderToken,
  IWETH9
} from './Interfaces.sol';
import {
  LiquidityChangeOrigination,
  LiquidityChangeState,
  LiquidityChangeType,
  OrderSide
} from './Enums.sol';
import {
  Asset,
  LiquidityAddition,
  LiquidityAdditionDepositResult,
  LiquidityChangeExecution,
  LiquidityPool,
  LiquidityRemoval,
  LiquidityRemovalDepositResult,
  PoolTrade
} from './Structs.sol';

library LiquidityPools {
  using AssetRegistry for AssetRegistry.Storage;
  using BalanceTracking for BalanceTracking.Storage;
  using LiquidityPoolHelpers for LiquidityPool;
  using PoolTradeHelpers for PoolTrade;

  struct Storage {
    mapping(address => mapping(address => ILiquidityProviderToken)) liquidityProviderTokensByAddress;
    mapping(address => mapping(address => LiquidityPool)) poolsByAddresses;
    mapping(bytes32 => LiquidityChangeState) changes;
  }

  uint64 public constant MINIMUM_LIQUIDITY = 10**3;

  // Add liquidity //

  function addLiquidity(
    Storage storage self,
    LiquidityAddition memory addition,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) public returns (LiquidityAdditionDepositResult memory) {
    require(addition.deadline >= block.timestamp, 'IDEX: EXPIRED');

    bytes32 hash = Hashing.getLiquidityAdditionHash(addition);
    require(
      self.changes[hash] == LiquidityChangeState.NotInitiated,
      'Already initiated'
    );
    self.changes[hash] = LiquidityChangeState.Initiated;

    // Transfer assets to Custodian and credit balances
    return
      Depositing.depositLiquidityReserves(
        addition.wallet,
        addition.assetA,
        addition.assetB,
        addition.amountADesired,
        addition.amountBDesired,
        custodian,
        assetRegistry,
        balanceTracking
      );
  }

  function executeAddLiquidity(
    Storage storage self,
    LiquidityAddition memory addition,
    LiquidityChangeExecution memory execution,
    address feeWallet,
    address custodianAddress,
    BalanceTracking.Storage storage balanceTracking
  ) external {
    ILiquidityProviderToken liquidityProviderToken =
      validateAndUpdateForLiquidityAddition(self, addition, execution);

    // Debit wallet Pair token balance and credit fee wallet reserve asset balances
    balanceTracking.updateForAddLiquidity(
      addition,
      execution,
      feeWallet,
      custodianAddress,
      liquidityProviderToken
    );
  }

  function validateAndUpdateForLiquidityAddition(
    Storage storage self,
    LiquidityAddition memory addition,
    LiquidityChangeExecution memory execution
  ) private returns (ILiquidityProviderToken liquidityProviderToken) {
    {
      bytes32 hash = Hashing.getLiquidityAdditionHash(addition);
      LiquidityChangeState state = self.changes[hash];

      if (addition.origination == LiquidityChangeOrigination.OnChain) {
        require(
          state == LiquidityChangeState.Initiated,
          'Not executable from on-chain'
        );
      } else {
        require(
          state == LiquidityChangeState.NotInitiated,
          'Not executable from off-chain'
        );
        require(
          Hashing.isSignatureValid(hash, addition.signature, addition.wallet),
          'Invalid signature'
        );
      }
      self.changes[hash] = LiquidityChangeState.Executed;
    }

    LiquidityPool storage pool =
      loadLiquidityPoolByAssetAddresses(
        self,
        execution.baseAssetAddress,
        execution.quoteAssetAddress
      );
    liquidityProviderToken = pool.liquidityProviderToken;

    LiquidityChangeExecutionValidations.validateLiquidityAddition(
      addition,
      execution,
      pool
    );

    validateAndUpdateReservesForLiquidityAddition(pool, execution);

    // Mint LP tokens to destination wallet
    liquidityProviderToken.mint(
      addition.wallet,
      AssetUnitConversions.pipsToAssetUnits(
        execution.liquidityInPips,
        Constants.liquidityProviderTokenDecimals
      ),
      AssetUnitConversions.pipsToAssetUnits(
        execution.netBaseQuantityInPips,
        pool.baseAssetDecimals
      ),
      AssetUnitConversions.pipsToAssetUnits(
        execution.netQuoteQuantityInPips,
        pool.quoteAssetDecimals
      ),
      addition.to
    );
  }

  // Remove liquidity //

  function removeLiquidity(
    Storage storage self,
    LiquidityRemoval memory removal,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) public returns (LiquidityRemovalDepositResult memory) {
    require(removal.deadline >= block.timestamp, 'IDEX: EXPIRED');

    bytes32 hash = Hashing.getLiquidityRemovalHash(removal);
    require(
      self.changes[hash] == LiquidityChangeState.NotInitiated,
      'Already initiated'
    );
    self.changes[hash] = LiquidityChangeState.Initiated;

    // Resolve LP token address
    address liquidityProviderToken =
      address(
        loadLiquidityProviderTokenByAssetAddresses(
          self,
          removal.assetA,
          removal.assetB
        )
      );

    // Transfer LP tokens to Custodian and credit balances
    return
      Depositing.depositLiquidityTokens(
        removal.wallet,
        liquidityProviderToken,
        removal.liquidity,
        custodian,
        assetRegistry,
        balanceTracking
      );
  }

  function executeRemoveLiquidity(
    Storage storage self,
    LiquidityRemoval memory removal,
    LiquidityChangeExecution memory execution,
    bool isWalletExited,
    ICustodian custodian,
    address feeWallet,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) public {
    ILiquidityProviderToken liquidityProviderToken =
      validateAndUpdateForLiquidityRemoval(
        self,
        removal,
        execution,
        isWalletExited
      );

    Withdrawing.withdrawLiquidity(
      removal,
      execution,
      custodian,
      feeWallet,
      liquidityProviderToken,
      assetRegistry,
      balanceTracking
    );
  }

  function validateAndUpdateForLiquidityRemoval(
    Storage storage self,
    LiquidityRemoval memory removal,
    LiquidityChangeExecution memory execution,
    bool isWalletExited
  ) private returns (ILiquidityProviderToken liquidityProviderToken) {
    {
      // Following a wallet exit the Dispatcher can liquidate the wallet's liquidity pool positions
      // without the need for the wallet itself to first initiate the removal. Without this
      // mechanism, the wallet could change the pool's price at any time following the exit by
      // calling `removeLiquidityExit` and cause the reversion of pending pool settlements from the
      // Dispatcher
      if (!isWalletExited) {
        bytes32 hash = Hashing.getLiquidityRemovalHash(removal);
        LiquidityChangeState state = self.changes[hash];

        if (removal.origination == LiquidityChangeOrigination.OnChain) {
          require(
            state == LiquidityChangeState.Initiated,
            'Not executable from on-chain'
          );
        } else {
          require(
            state == LiquidityChangeState.NotInitiated,
            'Not executable from off-chain'
          );
          require(
            Hashing.isSignatureValid(hash, removal.signature, removal.wallet),
            'Invalid signature'
          );
        }
        self.changes[hash] = LiquidityChangeState.Executed;
      }
    }

    LiquidityPool storage pool =
      loadLiquidityPoolByAssetAddresses(
        self,
        execution.baseAssetAddress,
        execution.quoteAssetAddress
      );
    liquidityProviderToken = pool.liquidityProviderToken;

    LiquidityChangeExecutionValidations.validateLiquidityRemoval(
      removal,
      execution,
      pool
    );

    // Debit pool reserves
    pool.baseAssetReserveInPips -= execution.grossBaseQuantityInPips;
    pool.quoteAssetReserveInPips -= execution.grossQuoteQuantityInPips;

    liquidityProviderToken.burn(
      removal.wallet,
      AssetUnitConversions.pipsToAssetUnits(
        execution.liquidityInPips,
        Constants.liquidityProviderTokenDecimals
      ),
      AssetUnitConversions.pipsToAssetUnits(
        execution.grossBaseQuantityInPips,
        pool.baseAssetDecimals
      ),
      AssetUnitConversions.pipsToAssetUnits(
        execution.grossQuoteQuantityInPips,
        pool.quoteAssetDecimals
      ),
      removal.to
    );
  }

  // Exit liquidity //

  function removeLiquidityExit(
    Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress,
    ICustodian custodian,
    BalanceTracking.Storage storage balanceTracking
  )
    public
    returns (
      uint64 outputBaseAssetQuantityInPips,
      uint64 outputQuoteAssetQuantityInPips
    )
  {
    LiquidityPool storage pool =
      loadLiquidityPoolByAssetAddresses(
        self,
        baseAssetAddress,
        quoteAssetAddress
      );

    uint64 liquidityToBurnInPips =
      balanceTracking.updateForExit(
        msg.sender,
        address(pool.liquidityProviderToken)
      );

    // Calculate output asset quantities
    (outputBaseAssetQuantityInPips, outputQuoteAssetQuantityInPips) = pool
      .calculateOutputAssetQuantitiesInPips(liquidityToBurnInPips);
    uint256 outputBaseAssetQuantityInAssetUnits =
      AssetUnitConversions.pipsToAssetUnits(
        outputBaseAssetQuantityInPips,
        pool.baseAssetDecimals
      );
    uint256 outputQuoteAssetQuantityInAssetUnits =
      AssetUnitConversions.pipsToAssetUnits(
        outputQuoteAssetQuantityInPips,
        pool.quoteAssetDecimals
      );

    // Debit pool reserves
    pool.baseAssetReserveInPips -= outputBaseAssetQuantityInPips;
    pool.quoteAssetReserveInPips -= outputQuoteAssetQuantityInPips;

    // Burn deposited Pair tokens
    pool.liquidityProviderToken.burn(
      msg.sender,
      AssetUnitConversions.pipsToAssetUnits(
        liquidityToBurnInPips,
        Constants.liquidityProviderTokenDecimals
      ),
      outputBaseAssetQuantityInAssetUnits,
      outputQuoteAssetQuantityInAssetUnits,
      msg.sender
    );

    // Transfer reserve assets to wallet
    custodian.withdraw(
      payable(msg.sender),
      baseAssetAddress,
      outputBaseAssetQuantityInAssetUnits
    );
    custodian.withdraw(
      payable(msg.sender),
      quoteAssetAddress,
      outputQuoteAssetQuantityInAssetUnits
    );
  }

  // Trading //

  function updateReservesForPoolTrade(
    Storage storage self,
    PoolTrade memory poolTrade,
    OrderSide orderSide
  )
    internal
    returns (uint64 baseAssetReserveInPips, uint64 quoteAssetReserveInPips)
  {
    LiquidityPool storage pool =
      loadLiquidityPoolByAssetAddresses(
        self,
        poolTrade.baseAssetAddress,
        poolTrade.quoteAssetAddress
      );

    uint128 initialProduct =
      uint128(pool.baseAssetReserveInPips) *
        uint128(pool.quoteAssetReserveInPips);
    uint128 updatedProduct;

    if (orderSide == OrderSide.Buy) {
      pool.baseAssetReserveInPips -= poolTrade.getPoolDebitQuantityInPips(
        orderSide
      );
      pool.quoteAssetReserveInPips += poolTrade
        .calculatePoolCreditQuantityInPips(orderSide);

      updatedProduct =
        uint128(pool.baseAssetReserveInPips) *
        uint128(
          pool.quoteAssetReserveInPips - poolTrade.takerPoolFeeQuantityInPips
        );
    } else {
      pool.baseAssetReserveInPips += poolTrade
        .calculatePoolCreditQuantityInPips(orderSide);
      if (poolTrade.takerPriceCorrectionFeeQuantityInPips > 0) {
        // Add the taker sell's price correction fee to the pool - there is no quote output
        pool.quoteAssetReserveInPips += poolTrade
          .takerPriceCorrectionFeeQuantityInPips;
      } else {
        pool.quoteAssetReserveInPips -= poolTrade.getPoolDebitQuantityInPips(
          orderSide
        );
      }

      updatedProduct =
        uint128(
          pool.baseAssetReserveInPips - poolTrade.takerPoolFeeQuantityInPips
        ) *
        uint128(pool.quoteAssetReserveInPips);
    }

    // Constant product will increase when there are fees collected
    require(
      updatedProduct >= initialProduct,
      'Constant product cannot decrease'
    );

    // Disallow either ratio to dip below the minimum as prices can no longer be represented with
    // full pip precision
    require(
      pool.baseAssetReserveInPips >= Constants.minLiquidityPoolReserveInPips,
      'Base reserves below min'
    );
    require(
      pool.quoteAssetReserveInPips >= Constants.minLiquidityPoolReserveInPips,
      'Quote reserves below min'
    );
    Validations.validatePoolReserveRatio(pool);

    return (pool.baseAssetReserveInPips, pool.quoteAssetReserveInPips);
  }

  // Helpers //

  function loadLiquidityPoolByAssetAddresses(
    Storage storage self,
    address baseAssetAddress,
    address quoteAssetAddress
  ) internal view returns (LiquidityPool storage pool) {
    pool = self.poolsByAddresses[baseAssetAddress][quoteAssetAddress];
    require(pool.exists, 'No pool for address pair');
  }

  function loadLiquidityProviderTokenByAssetAddresses(
    Storage storage self,
    address assetA,
    address assetB
  ) private view returns (ILiquidityProviderToken liquidityProviderToken) {
    liquidityProviderToken = self.liquidityProviderTokensByAddress[assetA][
      assetB
    ];
    require(
      address(liquidityProviderToken) != address(0x0),
      'No LP token for address pair'
    );
  }

  function validateAndUpdateReservesForLiquidityAddition(
    LiquidityPool storage pool,
    LiquidityChangeExecution memory execution
  ) private {
    uint64 initialPrice = pool.calculateCurrentPoolPriceInPips();

    // Credit pool reserves
    pool.baseAssetReserveInPips += execution.netBaseQuantityInPips;
    pool.quoteAssetReserveInPips += execution.netQuoteQuantityInPips;

    // Require pool price to remain constant on addition. Skip this validation if either reserve is
    // below the minimum as prices can no longer be represented with full pip precision
    if (initialPrice == 0) {
      // First liquidity addition to empty pool establishes price which must within max ratio
      Validations.validatePoolReserveRatio(pool);
    } else if (
      pool.baseAssetReserveInPips >= Constants.minLiquidityPoolReserveInPips &&
      pool.quoteAssetReserveInPips >= Constants.minLiquidityPoolReserveInPips
    ) {
      uint64 updatedPrice = pool.calculateCurrentPoolPriceInPips();
      require(initialPrice == updatedPrice, 'Pool price cannot change');
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { Address } from './Address.sol';
import { ERC20 } from './ERC20.sol';

import { Constants } from './Constants.sol';
import {
  ICustodian,
  IExchange,
  IERC20,
  ILiquidityProviderToken
} from './Interfaces.sol';

/**
 * @notice Liquidity Provider ERC-20 token contract
 *
 * @dev Reference OpenZeppelin implementation with whitelisted minting and burning
 */
contract LiquidityProviderToken is ERC20, ILiquidityProviderToken {
  // Used to whitelist Exchange-only functions by loading address of current Exchange from Custodian
  ICustodian public override custodian;

  // Base and quote asset addresses provided only for informational purposes
  address public override baseAssetAddress;
  address public override quoteAssetAddress;
  string public override baseAssetSymbol;
  string public override quoteAssetSymbol;

  /**
   * @notice Emitted when the Exchange mints new LP tokens to a wallet via `mint`
   */
  event Mint(
    address indexed sender,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits
  );
  /**
   * @notice Emitted when the Exchange burns a wallet's LP tokens via `burn`
   */
  event Burn(
    address indexed sender,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address indexed to
  );

  modifier onlyExchange() {
    require(msg.sender == custodian.loadExchange(), 'Caller is not Exchange');
    _;
  }

  /**
   * @notice Instantiate a new `LiquidityProviderToken` contract
   *
   * @dev Should be called by the Exchange via a CREATE2 op to generate stable deterministic
   * addresses and setup whitelist for `onlyExchange`-restricted functions. Asset addresses and
   * symbols are stored for informational purposes
   *
   * @param _baseAssetAddress The base asset address
   * @param _quoteAssetAddress The quote asset address
   * @param _baseAssetSymbol The base asset symbol
   * @param _quoteAssetSymbol The quote asset symbol
   */

  constructor(
    address _baseAssetAddress,
    address _quoteAssetAddress,
    string memory _baseAssetSymbol,
    string memory _quoteAssetSymbol
  ) ERC20('', 'IDEX-LP') {
    custodian = IExchange(msg.sender).loadCustodian();
    require(address(custodian) != address(0x0), 'Invalid Custodian address');

    // Assets cannot be equal
    require(
      _baseAssetAddress != _quoteAssetAddress,
      'Assets must be different'
    );

    // Each asset must be the native asset or contract
    require(
      _baseAssetAddress == address(0x0) ||
        Address.isContract(_baseAssetAddress),
      'Invalid base asset'
    );
    require(
      _quoteAssetAddress == address(0x0) ||
        Address.isContract(_quoteAssetAddress),
      'Invalid quote asset'
    );

    baseAssetAddress = _baseAssetAddress;
    quoteAssetAddress = _quoteAssetAddress;
    baseAssetSymbol = _baseAssetSymbol;
    quoteAssetSymbol = _quoteAssetSymbol;
  }

  /**
   * @notice Returns the name of the token
   */
  function name() public view override returns (string memory) {
    return
      string(
        abi.encodePacked('IDEX LP: ', baseAssetSymbol, '-', quoteAssetSymbol)
      );
  }

  /**
   * @notice Returns the address of the base-quote pair asset with the lower sort order
   */
  function token0() external view override returns (address) {
    return
      baseAssetAddress < quoteAssetAddress
        ? baseAssetAddress
        : quoteAssetAddress;
  }

  /**
   * @notice Returns the address of the base-quote pair asset with the higher sort order
   */
  function token1() external view override returns (address) {
    return
      baseAssetAddress < quoteAssetAddress
        ? quoteAssetAddress
        : baseAssetAddress;
  }

  /**
   * @notice Burns LP tokens by removing them from `wallet`'s balance and total supply
   */
  function burn(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external override onlyExchange {
    _burn(address(custodian), liquidity);

    emit Burn(
      wallet,
      baseAssetQuantityInAssetUnits,
      quoteAssetQuantityInAssetUnits,
      to
    );
  }

  /**
   * @notice Mints LP tokens by adding them to `wallet`'s balance and total supply
   */
  function mint(
    address wallet,
    uint256 liquidity,
    uint256 baseAssetQuantityInAssetUnits,
    uint256 quoteAssetQuantityInAssetUnits,
    address to
  ) external override onlyExchange {
    _mint(to, liquidity);

    emit Mint(
      wallet,
      baseAssetQuantityInAssetUnits,
      quoteAssetQuantityInAssetUnits
    );
  }

  /**
   * @notice Reverses the asset pair represented by this token by swapping `baseAssetAddress` with
   * `quoteAssetAddress` and `baseAssetSymbol` with `quoteAssetSymbol`
   */
  function reverseAssets() external override onlyExchange {
    // Assign swapped values to intermediate values first as Solidity won't allow multiple storage
    // writes in a single statement
    (
      address _baseAssetAddress,
      address _quoteAssetAddress,
      string memory _baseAssetSymbol,
      string memory _quoteAssetSymbol
    ) =
      (quoteAssetAddress, baseAssetAddress, quoteAssetSymbol, baseAssetSymbol);
    (baseAssetAddress, quoteAssetAddress, baseAssetSymbol, quoteAssetSymbol) = (
      _baseAssetAddress,
      _quoteAssetAddress,
      _baseAssetSymbol,
      _quoteAssetSymbol
    );
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

library Math {
  function multiplyPipsByFraction(
    uint64 multiplicand,
    uint64 fractionDividend,
    uint64 fractionDivisor
  ) internal pure returns (uint64) {
    return
      multiplyPipsByFraction(
        multiplicand,
        fractionDividend,
        fractionDivisor,
        false
      );
  }

  function multiplyPipsByFraction(
    uint64 multiplicand,
    uint64 fractionDividend,
    uint64 fractionDivisor,
    bool roundUp
  ) internal pure returns (uint64) {
    uint256 dividend = uint256(multiplicand) * fractionDividend;
    uint256 result = dividend / fractionDivisor;
    if (roundUp && dividend % fractionDivisor > 0) {
      result += 1;
    }
    require(result < 2**64, 'Pip quantity overflows uint64');

    return uint64(result);
  }

  function min(uint64 x, uint64 y) internal pure returns (uint64 z) {
    z = x < y ? x : y;
  }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

// IGNORE This is generated by Truffle
// https://www.trufflesuite.com/docs/truffle/getting-started/running-migrations#initial-migration

pragma solidity 0.8.4;

contract Migrations {
  address public owner;
  uint256 public last_completed_migration;

  constructor() {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint256 completed) public restricted {
    last_completed_migration = completed;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { NonceInvalidation } from './Structs.sol';
import { UUID } from './UUID.sol';

library NonceInvalidations {
  function invalidateOrderNonce(
    mapping(address => NonceInvalidation) storage self,
    uint128 nonce,
    uint256 chainPropagationPeriod
  ) external returns (uint64 timestampInMs, uint256 effectiveBlockNumber) {
    timestampInMs = UUID.getTimestampInMsFromUuidV1(nonce);
    // Enforce a maximum skew for invalidating nonce timestamps in the future so the user doesn't
    // lock their wallet from trades indefinitely
    require(timestampInMs < getOneDayFromNowInMs(), 'Nonce timestamp too high');

    if (self[msg.sender].exists) {
      require(
        self[msg.sender].timestampInMs < timestampInMs,
        'Nonce timestamp invalidated'
      );
      require(
        self[msg.sender].effectiveBlockNumber <= block.number,
        'Last invalidation not finalized'
      );
    }

    // Changing the Chain Propagation Period will not affect the effectiveBlockNumber for this invalidation
    effectiveBlockNumber = block.number + chainPropagationPeriod;
    self[msg.sender] = NonceInvalidation(
      true,
      timestampInMs,
      effectiveBlockNumber
    );
  }

  function getOneDayFromNowInMs() private view returns (uint64) {
    uint64 secondsInOneDay = 24 * 60 * 60; // 24 hours/day * 60 min/hour * 60 seconds/min
    uint64 msInOneSecond = 1000;

    return (uint64(block.timestamp) + secondsInOneDay) * msInOneSecond;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { Constants } from './Constants.sol';
import { OrderSide } from './Enums.sol';
import { Hashing } from './Hashing.sol';
import { UUID } from './UUID.sol';
import { Validations } from './Validations.sol';
import { Asset, Order, OrderBookTrade, NonceInvalidation } from './Structs.sol';

library OrderBookTradeValidations {
  using AssetRegistry for AssetRegistry.Storage;

  function validateOrderBookTrade(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory trade,
    AssetRegistry.Storage storage assetRegistry,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) internal view returns (bytes32, bytes32) {
    require(
      buy.walletAddress != sell.walletAddress,
      'Self-trading not allowed'
    );

    // Order book trade validations
    validateAssetPair(buy, sell, trade, assetRegistry);
    validateLimitPrices(buy, sell, trade);
    Validations.validateOrderNonces(buy, sell, nonceInvalidations);
    (bytes32 buyHash, bytes32 sellHash) =
      validateOrderSignatures(buy, sell, trade);
    validateFees(trade);

    return (buyHash, sellHash);
  }

  function validateAssetPair(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory trade,
    AssetRegistry.Storage storage assetRegistry
  ) internal view {
    require(
      trade.baseAssetAddress != trade.quoteAssetAddress,
      'Trade assets must be different'
    );

    // Fee asset validation
    require(
      (trade.makerFeeAssetAddress == trade.baseAssetAddress &&
        trade.takerFeeAssetAddress == trade.quoteAssetAddress) ||
        (trade.makerFeeAssetAddress == trade.quoteAssetAddress &&
          trade.takerFeeAssetAddress == trade.baseAssetAddress),
      'Fee assets mismatch trade pair'
    );

    validateAssetPair(buy, trade, assetRegistry);
    validateAssetPair(sell, trade, assetRegistry);
  }

  function validateAssetPair(
    Order memory order,
    OrderBookTrade memory trade,
    AssetRegistry.Storage storage assetRegistry
  ) internal view {
    uint64 timestampInMs = UUID.getTimestampInMsFromUuidV1(order.nonce);
    Asset memory baseAsset =
      assetRegistry.loadAssetBySymbol(trade.baseAssetSymbol, timestampInMs);
    Asset memory quoteAsset =
      assetRegistry.loadAssetBySymbol(trade.quoteAssetSymbol, timestampInMs);

    require(
      baseAsset.assetAddress == trade.baseAssetAddress &&
        quoteAsset.assetAddress == trade.quoteAssetAddress,
      'Order symbol address mismatch'
    );
  }

  function validateLimitPrices(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory trade
  ) internal pure {
    require(
      trade.grossBaseQuantityInPips > 0,
      'Base quantity must be greater than zero'
    );
    require(
      trade.grossQuoteQuantityInPips > 0,
      'Quote quantity must be greater than zero'
    );

    if (Validations.isLimitOrderType(buy.orderType)) {
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          trade.grossBaseQuantityInPips,
          buy.limitPriceInPips
        ) >= trade.grossQuoteQuantityInPips,
        'Buy order limit price exceeded'
      );
    }

    if (Validations.isLimitOrderType(sell.orderType)) {
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          trade.grossBaseQuantityInPips,
          sell.limitPriceInPips
        ) <= trade.grossQuoteQuantityInPips,
        'Sell order limit price exceeded'
      );
    }
  }

  function validateOrderSignatures(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory trade
  ) internal pure returns (bytes32, bytes32) {
    bytes32 buyOrderHash =
      validateOrderSignature(
        buy,
        trade.baseAssetSymbol,
        trade.quoteAssetSymbol
      );
    bytes32 sellOrderHash =
      validateOrderSignature(
        sell,
        trade.baseAssetSymbol,
        trade.quoteAssetSymbol
      );

    return (buyOrderHash, sellOrderHash);
  }

  function validateOrderSignature(
    Order memory order,
    string memory baseAssetSymbol,
    string memory quoteAssetSymbol
  ) internal pure returns (bytes32) {
    bytes32 orderHash =
      Hashing.getOrderHash(order, baseAssetSymbol, quoteAssetSymbol);

    require(
      Hashing.isSignatureValid(
        orderHash,
        order.walletSignature,
        order.walletAddress
      ),
      order.side == OrderSide.Buy
        ? 'Invalid wallet signature for buy order'
        : 'Invalid wallet signature for sell order'
    );

    return orderHash;
  }

  function validateFees(OrderBookTrade memory trade) private pure {
    uint64 makerTotalQuantityInPips =
      trade.makerFeeAssetAddress == trade.baseAssetAddress
        ? trade.grossBaseQuantityInPips
        : trade.grossQuoteQuantityInPips;
    require(
      Validations.isFeeQuantityValid(
        trade.makerFeeQuantityInPips,
        makerTotalQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive maker fee'
    );

    uint64 takerTotalQuantityInPips =
      trade.takerFeeAssetAddress == trade.baseAssetAddress
        ? trade.grossBaseQuantityInPips
        : trade.grossQuoteQuantityInPips;
    require(
      Validations.isFeeQuantityValid(
        trade.takerFeeQuantityInPips,
        takerTotalQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive taker fee'
    );

    Validations.validateOrderBookTradeFees(trade);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * @notice Mixin that provide separate owner and admin roles for RBAC
 */
abstract contract Owned {
  address immutable _owner;
  address _admin;

  modifier onlyOwner {
    require(msg.sender == _owner, 'Caller must be owner');
    _;
  }
  modifier onlyAdmin {
    require(msg.sender == _admin, 'Caller must be admin');
    _;
  }

  /**
   * @notice Sets both the owner and admin roles to the contract creator
   */
  constructor() {
    _owner = msg.sender;
    _admin = msg.sender;
  }

  /**
   * @notice Sets a new whitelisted admin wallet
   *
   * @param newAdmin The new whitelisted admin wallet. Must be different from the current one
   */
  function setAdmin(address newAdmin) external onlyOwner {
    require(newAdmin != address(0x0), 'Invalid wallet address');
    require(newAdmin != _admin, 'Must be different from current admin');

    _admin = newAdmin;
  }

  /**
   * @notice Clears the currently whitelisted admin wallet, effectively disabling any functions requiring
   * the admin role
   */
  function removeAdmin() external onlyOwner {
    _admin = address(0x0);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { OrderSide } from './Enums.sol';
import { PoolTrade } from './Structs.sol';

library PoolTradeHelpers {
  /**
   * @dev Address of asset order wallet is receiving from pool
   */
  function getOrderCreditAssetAddress(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (address) {
    return
      orderSide == OrderSide.Buy
        ? self.baseAssetAddress
        : self.quoteAssetAddress;
  }

  /**
   * @dev Address of asset order wallet is giving to pool
   */
  function getOrderDebitAssetAddress(PoolTrade memory self, OrderSide orderSide)
    internal
    pure
    returns (address)
  {
    return
      orderSide == OrderSide.Buy
        ? self.quoteAssetAddress
        : self.baseAssetAddress;
  }

  /**
   * @dev Quantity in pips of asset that order wallet is receiving from pool
   */
  function calculateOrderCreditQuantityInPips(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return
      (
        orderSide == OrderSide.Buy
          ? self.netBaseQuantityInPips
          : self.netQuoteQuantityInPips
      ) - self.takerGasFeeQuantityInPips;
  }

  /**
   * @dev Quantity in pips of asset that order wallet is giving to pool
   */
  function getOrderDebitQuantityInPips(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return
      orderSide == OrderSide.Buy
        ? self.grossQuoteQuantityInPips
        : self.grossBaseQuantityInPips;
  }

  /**
   * @dev Quantity in pips of asset that pool receives from order wallet
   */
  function calculatePoolCreditQuantityInPips(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return
      (
        orderSide == OrderSide.Buy
          ? self.netQuoteQuantityInPips
          : self.netBaseQuantityInPips
      ) + self.takerPoolFeeQuantityInPips;
  }

  /**
   * @dev Quantity in pips of asset that leaves pool as output
   */
  function getPoolDebitQuantityInPips(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return (
      orderSide == OrderSide.Buy
        ? self.netBaseQuantityInPips // Pool gives net base asset plus taker gas fee
        : self.netQuoteQuantityInPips // Pool gives net quote asset plus taker gas fee
    );
  }

  /**
   * @dev Gross quantity received by order wallet
   */
  function getOrderGrossReceivedQuantityInPips(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return
      orderSide == OrderSide.Buy
        ? self.grossBaseQuantityInPips
        : self.grossQuoteQuantityInPips;
  }

  function calculatePoolOutputAdjustment(
    PoolTrade memory self,
    OrderSide orderSide
  ) internal pure returns (uint64) {
    return
      getOrderGrossReceivedQuantityInPips(self, orderSide) -
      getPoolDebitQuantityInPips(self, orderSide);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { Constants } from './Constants.sol';
import { OrderSide } from './Enums.sol';
import { PoolTradeHelpers } from './PoolTradeHelpers.sol';
import { UUID } from './UUID.sol';
import { Validations } from './Validations.sol';
import { Asset, Order, NonceInvalidation, PoolTrade } from './Structs.sol';

library PoolTradeValidations {
  using AssetRegistry for AssetRegistry.Storage;
  using PoolTradeHelpers for PoolTrade;

  function validatePoolTrade(
    Order memory order,
    PoolTrade memory poolTrade,
    AssetRegistry.Storage storage assetRegistry,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) internal view returns (bytes32 orderHash) {
    orderHash = Validations.validateOrderSignature(
      order,
      poolTrade.baseAssetSymbol,
      poolTrade.quoteAssetSymbol
    );
    validateAssetPair(order, poolTrade, assetRegistry);
    validateLimitPrice(order, poolTrade);
    Validations.validateOrderNonce(order, nonceInvalidations);
    validateFees(order.side, poolTrade);
  }

  function validateAssetPair(
    Order memory order,
    PoolTrade memory poolTrade,
    AssetRegistry.Storage storage assetRegistry
  ) internal view {
    require(
      poolTrade.baseAssetAddress != poolTrade.quoteAssetAddress,
      'Trade assets must be different'
    );

    uint64 timestampInMs = UUID.getTimestampInMsFromUuidV1(order.nonce);
    Asset memory baseAsset =
      assetRegistry.loadAssetBySymbol(poolTrade.baseAssetSymbol, timestampInMs);
    Asset memory quoteAsset =
      assetRegistry.loadAssetBySymbol(
        poolTrade.quoteAssetSymbol,
        timestampInMs
      );

    require(
      baseAsset.assetAddress == poolTrade.baseAssetAddress &&
        quoteAsset.assetAddress == poolTrade.quoteAssetAddress,
      'Order symbol address mismatch'
    );
  }

  function validateLimitPrice(Order memory order, PoolTrade memory poolTrade)
    internal
    pure
  {
    require(
      poolTrade.grossBaseQuantityInPips > 0,
      'Base quantity must be greater than zero'
    );
    require(
      poolTrade.grossQuoteQuantityInPips > 0,
      'Quote quantity must be greater than zero'
    );

    if (
      order.side == OrderSide.Buy &&
      Validations.isLimitOrderType(order.orderType)
    ) {
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          poolTrade.grossBaseQuantityInPips,
          order.limitPriceInPips
        ) >= poolTrade.grossQuoteQuantityInPips,
        'Buy order limit price exceeded'
      );
    }

    if (
      order.side == OrderSide.Sell &&
      Validations.isLimitOrderType(order.orderType)
    ) {
      require(
        Validations.calculateImpliedQuoteQuantityInPips(
          poolTrade.grossBaseQuantityInPips - 1,
          order.limitPriceInPips
        ) <= poolTrade.grossQuoteQuantityInPips,
        'Sell order limit price exceeded'
      );
    }
  }

  function validateFees(OrderSide orderSide, PoolTrade memory poolTrade)
    private
    pure
  {
    require(
      Validations.isFeeQuantityValid(
        poolTrade.calculatePoolOutputAdjustment(orderSide),
        poolTrade.getOrderGrossReceivedQuantityInPips(orderSide),
        Constants.maxPoolOutputAdjustmentBasisPoints
      ),
      'Excessive pool output adjustment'
    );

    require(
      Validations.isFeeQuantityValid(
        poolTrade.takerGasFeeQuantityInPips,
        poolTrade.getOrderGrossReceivedQuantityInPips(orderSide),
        Constants.maxFeeBasisPoints
      ),
      'Excessive gas fee'
    );

    // Price correction only allowed for hybrid trades with a taker sell
    require(
      poolTrade.takerPriceCorrectionFeeQuantityInPips == 0,
      'Price correction not allowed'
    );

    Validations.validatePoolTradeInputFees(orderSide, poolTrade);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { ILiquidityProviderToken, IWETH9 } from './Interfaces.sol';
import {
  LiquidityChangeOrigination,
  OrderSelfTradePrevention,
  OrderSide,
  OrderTimeInForce,
  OrderType,
  WithdrawalType
} from './Enums.sol';

/**
 * @notice Struct definitions
 */

/**
 * @notice State tracking for a hybrid liquidity pool
 *
 * @dev Base and quote asset decimals are denormalized here to avoid extra loads from
 * `AssetRegistry.Storage`
 */
struct LiquidityPool {
  // Flag to distinguish from empty struct
  bool exists;
  uint64 baseAssetReserveInPips;
  uint8 baseAssetDecimals;
  uint64 quoteAssetReserveInPips;
  uint8 quoteAssetDecimals;
  ILiquidityProviderToken liquidityProviderToken;
}

/**
 * @dev Internal struct capturing user-initiated liquidity addition request parameters
 */
struct LiquidityAddition {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // Distinguishes between liquidity additions initated on- or off- chain
  LiquidityChangeOrigination origination;
  // UUIDv1 unique to wallet
  uint128 nonce;
  address wallet;
  address assetA;
  address assetB;
  uint256 amountADesired;
  uint256 amountBDesired;
  uint256 amountAMin;
  uint256 amountBMin;
  address to;
  uint256 deadline;
  bytes signature;
}

/**
 * @notice Internally used struct, return type from `LiquidityPools.addLiquidity`
 */
struct LiquidityAdditionDepositResult {
  string assetASymbol;
  uint64 assetAQuantityInPips;
  uint64 assetANewExchangeBalanceInPips;
  uint256 assetANewExchangeBalanceInAssetUnits;
  string assetBSymbol;
  uint64 assetBQuantityInPips;
  uint64 assetBNewExchangeBalanceInPips;
  uint256 assetBNewExchangeBalanceInAssetUnits;
}

/**
 * @notice Internally used struct, return type from `LiquidityPools.removeLiquidity`
 */
struct LiquidityRemovalDepositResult {
  address assetAddress;
  string assetSymbol;
  uint64 assetQuantityInPips;
  uint64 assetNewExchangeBalanceInPips;
  uint256 assetNewExchangeBalanceInAssetUnits;
}

/**
 * @dev Internal struct capturing user-initiated liquidity removal request parameters
 */
struct LiquidityRemoval {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // Distinguishes between liquidity additions initated on- or off- chain
  LiquidityChangeOrigination origination;
  uint128 nonce;
  address wallet;
  address assetA;
  address assetB;
  uint256 liquidity;
  uint256 amountAMin;
  uint256 amountBMin;
  address payable to;
  uint256 deadline;
  bytes signature;
}

/**
 * @notice Argument type to `Exchange.executeAddLiquidity` and `Exchange.executeRemoveLiquidity`
 */
struct LiquidityChangeExecution {
  address baseAssetAddress;
  address quoteAssetAddress;
  uint64 liquidityInPips;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // Net amount of base asset sent to pool for additions or received by wallet for removals
  uint64 netBaseQuantityInPips;
  // Net amount of quote asset sent to pool for additions or received by wallet for removals
  uint64 netQuoteQuantityInPips;
}

/**
 * @notice Internally used struct, argument type to `LiquidityPoolAdmin.migrateLiquidityPool`
 */
struct LiquidityMigration {
  address token0;
  address token1;
  bool isToken1Quote;
  uint256 desiredLiquidity;
  address to;
  IWETH9 WETH;
}

/**
 * @notice Internally used struct capturing wallet order nonce invalidations created via `invalidateOrderNonce`
 */
struct NonceInvalidation {
  bool exists;
  uint64 timestampInMs;
  uint256 effectiveBlockNumber;
}

/**
 * @notice Return type for `Exchange.loadAssetBySymbol`, and `Exchange.loadAssetByAddress`; also
 * used internally by `AssetRegistry`
 */
struct Asset {
  // Flag to distinguish from empty struct
  bool exists;
  // The asset's address
  address assetAddress;
  // The asset's symbol
  string symbol;
  // The asset's decimal precision
  uint8 decimals;
  // Flag set when asset registration confirmed. Asset deposits, trades, or withdrawals only
  // allowed if true
  bool isConfirmed;
  // Timestamp as ms since Unix epoch when isConfirmed was asserted
  uint64 confirmedTimestampInMs;
}

/**
 * @notice Argument type for `Exchange.executeOrderBookTrade` and `Hashing.getOrderWalletHash`
 */
struct Order {
  // Must equal `Constants.signatureHashVersion`
  uint8 signatureHashVersion;
  // UUIDv1 unique to wallet
  uint128 nonce;
  // Wallet address that placed order and signed hash
  address walletAddress;
  // Type of order
  OrderType orderType;
  // Order side wallet is on
  OrderSide side;
  // Order quantity in base or quote asset terms depending on isQuantityInQuote flag
  uint64 quantityInPips;
  // Is quantityInPips in quote terms
  bool isQuantityInQuote;
  // For limit orders, price in decimal pips * 10^8 in quote terms
  uint64 limitPriceInPips;
  // For stop orders, stop loss or take profit price in decimal pips * 10^8 in quote terms
  uint64 stopPriceInPips;
  // Optional custom client order ID
  string clientOrderId;
  // TIF option specified by wallet for order
  OrderTimeInForce timeInForce;
  // STP behavior specified by wallet for order
  OrderSelfTradePrevention selfTradePrevention;
  // Cancellation time specified by wallet for GTT TIF order
  uint64 cancelAfter;
  // The ECDSA signature of the order hash as produced by Hashing.getOrderWalletHash
  bytes walletSignature;
}

/**
 * @notice Argument type for `Exchange.executeOrderBookTrade` specifying execution parameters for matching orders
 */
struct OrderBookTrade {
  // Base asset symbol
  string baseAssetSymbol;
  // Quote asset symbol
  string quoteAssetSymbol;
  // Base asset address
  address baseAssetAddress;
  // Quote asset address
  address quoteAssetAddress;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // Net amount of base asset received by buy side wallet after fees
  uint64 netBaseQuantityInPips;
  // Net amount of quote asset received by sell side wallet after fees
  uint64 netQuoteQuantityInPips;
  // Asset address for liquidity maker's fee
  address makerFeeAssetAddress;
  // Asset address for liquidity taker's fee
  address takerFeeAssetAddress;
  // Fee paid by liquidity maker
  uint64 makerFeeQuantityInPips;
  // Fee paid by liquidity taker, inclusive of gas fees
  uint64 takerFeeQuantityInPips;
  // Execution price of trade in decimal pips * 10^8 in quote terms
  uint64 priceInPips;
  // Which side of the order (buy or sell) the liquidity maker was on
  OrderSide makerSide;
}

/**
 * @notice Argument type for `Exchange.executePoolTrade` specifying execution parameters for an
 * order against pool liquidity
 */
struct PoolTrade {
  // Base asset symbol
  string baseAssetSymbol;
  // Quote asset symbol
  string quoteAssetSymbol;
  // Base asset address
  address baseAssetAddress;
  // Quote asset address
  address quoteAssetAddress;
  // Gross amount including fees of base asset executed
  uint64 grossBaseQuantityInPips;
  // Gross amount including fees of quote asset executed
  uint64 grossQuoteQuantityInPips;
  // If wallet is buy side, net amount of quote input to pool used to calculate output; otherwise,
  // net amount of base asset leaving pool
  uint64 netBaseQuantityInPips;
  // If wallet is buy side, net amount of base input to pool used to calculate output; otherwise,
  // net amount of quote asset leaving pool
  uint64 netQuoteQuantityInPips;
  // Fee paid by liquidity taker to pool from sent asset
  uint64 takerPoolFeeQuantityInPips;
  // Fee paid by liquidity taker to fee wallet from sent asset
  uint64 takerProtocolFeeQuantityInPips;
  // Fee paid by liquidity taker to fee wallet from received asset
  uint64 takerGasFeeQuantityInPips;
  // Fee paid by liquidity taker sell to pool taken from pool's quote asset output
  uint64 takerPriceCorrectionFeeQuantityInPips;
}

struct HybridTrade {
  OrderBookTrade orderBookTrade;
  PoolTrade poolTrade;
  // Fee paid by liquidity taker to fee wallet from received asset
  uint64 takerGasFeeQuantityInPips;
}

/**
 * @notice Argument type for `Exchange.withdraw` and `Hashing.getWithdrawalWalletHash`
 */
struct Withdrawal {
  // Distinguishes between withdrawals by asset symbol or address
  WithdrawalType withdrawalType;
  // UUIDv1 unique to wallet
  uint128 nonce;
  // Address of wallet to which funds will be returned
  address payable walletAddress;
  // Asset symbol
  string assetSymbol;
  // Asset address
  address assetAddress; // Used when assetSymbol not specified
  // Withdrawal quantity
  uint64 grossQuantityInPips;
  // Gas fee deducted from withdrawn quantity to cover dispatcher tx costs
  uint64 gasFeeInPips;
  // Not currently used but reserved for future use. Must be true
  bool autoDispatchEnabled;
  // The ECDSA signature of the withdrawal hash as produced by Hashing.getWithdrawalWalletHash
  bytes walletSignature;
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { HybridTradeValidations } from './HybridTradeValidations.sol';
import { LiquidityPools } from './LiquidityPools.sol';
import { OrderBookTradeValidations } from './OrderBookTradeValidations.sol';
import { PoolTradeHelpers } from './PoolTradeHelpers.sol';
import { PoolTradeValidations } from './PoolTradeValidations.sol';
import { Validations } from './Validations.sol';
import { OrderSide, OrderType } from './Enums.sol';
import {
  HybridTrade,
  Order,
  OrderBookTrade,
  NonceInvalidation,
  PoolTrade
} from './Structs.sol';

library Trading {
  using AssetRegistry for AssetRegistry.Storage;
  using BalanceTracking for BalanceTracking.Storage;
  using LiquidityPools for LiquidityPools.Storage;
  using PoolTradeHelpers for PoolTrade;

  function executeOrderBookTrade(
    Order memory buy,
    Order memory sell,
    OrderBookTrade memory orderBookTrade,
    address feeWallet,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(address => NonceInvalidation) storage nonceInvalidations,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) public {
    (bytes32 buyHash, bytes32 sellHash) =
      OrderBookTradeValidations.validateOrderBookTrade(
        buy,
        sell,
        orderBookTrade,
        assetRegistry,
        nonceInvalidations
      );

    updateOrderFilledQuantities(
      buy,
      buyHash,
      sell,
      sellHash,
      orderBookTrade,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );

    balanceTracking.updateForOrderBookTrade(
      buy,
      sell,
      orderBookTrade,
      feeWallet
    );
  }

  function executePoolTrade(
    Order memory order,
    PoolTrade memory poolTrade,
    address feeWallet,
    AssetRegistry.Storage storage assetRegistry,
    LiquidityPools.Storage storage liquidityPoolRegistry,
    BalanceTracking.Storage storage balanceTracking,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(address => NonceInvalidation) storage nonceInvalidations,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) public {
    bytes32 orderHash =
      PoolTradeValidations.validatePoolTrade(
        order,
        poolTrade,
        assetRegistry,
        nonceInvalidations
      );

    updateOrderFilledQuantity(
      order,
      orderHash,
      poolTrade.grossBaseQuantityInPips,
      poolTrade.grossQuoteQuantityInPips,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );

    balanceTracking.updateForPoolTrade(order, poolTrade, feeWallet);
    liquidityPoolRegistry.updateReservesForPoolTrade(poolTrade, order.side);
  }

  function executeHybridTrade(
    Order memory buy,
    Order memory sell,
    HybridTrade memory hybridTrade,
    address feeWallet,
    AssetRegistry.Storage storage assetRegistry,
    LiquidityPools.Storage storage liquidityPoolRegistry,
    BalanceTracking.Storage storage balanceTracking,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(address => NonceInvalidation) storage nonceInvalidations,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) public {
    (bytes32 buyHash, bytes32 sellHash) =
      HybridTradeValidations.validateHybridTrade(
        buy,
        sell,
        hybridTrade,
        assetRegistry,
        nonceInvalidations
      );

    executeHybridTradePoolComponent(
      buy,
      sell,
      buyHash,
      sellHash,
      hybridTrade,
      feeWallet,
      liquidityPoolRegistry,
      balanceTracking,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );

    {
      // Order book trade
      updateOrderFilledQuantities(
        buy,
        buyHash,
        sell,
        sellHash,
        hybridTrade.orderBookTrade,
        completedOrderHashes,
        partiallyFilledOrderQuantitiesInPips
      );

      balanceTracking.updateForOrderBookTrade(
        buy,
        sell,
        hybridTrade.orderBookTrade,
        feeWallet
      );
    }

    {
      address takerWallet =
        hybridTrade.orderBookTrade.makerSide == OrderSide.Buy
          ? sell.walletAddress
          : buy.walletAddress;
      balanceTracking.updateForHybridTradeFees(
        hybridTrade,
        takerWallet,
        feeWallet
      );
    }
  }

  function executeHybridTradePoolComponent(
    Order memory buy,
    Order memory sell,
    bytes32 buyHash,
    bytes32 sellHash,
    HybridTrade memory hybridTrade,
    address feeWallet,
    LiquidityPools.Storage storage liquidityPoolRegistry,
    BalanceTracking.Storage storage balanceTracking,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) private {
    (Order memory makerOrder, Order memory takerOrder, bytes32 takerOrderHash) =
      hybridTrade.orderBookTrade.makerSide == OrderSide.Buy
        ? (buy, sell, sellHash)
        : (sell, buy, buyHash);

    updateOrderFilledQuantity(
      takerOrder,
      takerOrderHash,
      hybridTrade.poolTrade.grossBaseQuantityInPips,
      hybridTrade.poolTrade.grossQuoteQuantityInPips,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );

    balanceTracking.updateForPoolTrade(
      takerOrder,
      hybridTrade.poolTrade,
      feeWallet
    );

    (uint64 baseAssetReserveInPips, uint64 quoteAssetReserveInPips) =
      liquidityPoolRegistry.updateReservesForPoolTrade(
        hybridTrade.poolTrade,
        takerOrder.side
      );

    HybridTradeValidations.validatePoolPrice(
      makerOrder,
      baseAssetReserveInPips,
      quoteAssetReserveInPips
    );
  }

  function updateOrderFilledQuantities(
    Order memory buy,
    bytes32 buyHash,
    Order memory sell,
    bytes32 sellHash,
    OrderBookTrade memory orderBookTrade,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) private {
    // Buy side
    updateOrderFilledQuantity(
      buy,
      buyHash,
      orderBookTrade.grossBaseQuantityInPips,
      orderBookTrade.grossQuoteQuantityInPips,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );
    // Sell side
    updateOrderFilledQuantity(
      sell,
      sellHash,
      orderBookTrade.grossBaseQuantityInPips,
      orderBookTrade.grossQuoteQuantityInPips,
      completedOrderHashes,
      partiallyFilledOrderQuantitiesInPips
    );
  }

  // Update filled quantities tracking for order to prevent over- or double-filling orders
  function updateOrderFilledQuantity(
    Order memory order,
    bytes32 orderHash,
    uint64 grossBaseQuantityInPips,
    uint64 grossQuoteQuantityInPips,
    mapping(bytes32 => bool) storage completedOrderHashes,
    mapping(bytes32 => uint64) storage partiallyFilledOrderQuantitiesInPips
  ) private {
    require(!completedOrderHashes[orderHash], 'Order double filled');

    // Total quantity of above filled as a result of all trade executions, including this one
    uint64 newFilledQuantityInPips;

    // Market orders can express quantity in quote terms, and can be partially filled by multiple
    // limit maker orders necessitating tracking partially filled amounts in quote terms to
    // determine completion
    if (order.isQuantityInQuote) {
      require(
        isMarketOrderType(order.orderType),
        'Order quote quantity only valid for market orders'
      );
      newFilledQuantityInPips =
        grossQuoteQuantityInPips +
        partiallyFilledOrderQuantitiesInPips[orderHash];
    } else {
      // All other orders track partially filled quantities in base terms
      newFilledQuantityInPips =
        grossBaseQuantityInPips +
        partiallyFilledOrderQuantitiesInPips[orderHash];
    }

    uint64 quantityInPips = order.quantityInPips;
    require(newFilledQuantityInPips <= quantityInPips, 'Order overfilled');
    if (newFilledQuantityInPips < quantityInPips) {
      // If the order was partially filled, track the new filled quantity
      partiallyFilledOrderQuantitiesInPips[orderHash] = newFilledQuantityInPips;
    } else {
      // If the order was completed, delete any partial fill tracking and instead track its completion
      // to prevent future double fills
      delete partiallyFilledOrderQuantitiesInPips[orderHash];
      completedOrderHashes[orderHash] = true;
    }
  }

  function isMarketOrderType(OrderType orderType) private pure returns (bool) {
    return
      orderType == OrderType.Market ||
      orderType == OrderType.StopLoss ||
      orderType == OrderType.TakeProfit;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

/**
 * Library helper for extracting timestamp component of Version 1 UUIDs
 */
library UUID {
  /**
   * Extracts the timestamp component of a Version 1 UUID. Used to make time-based assertions
   * against a wallet-privided nonce
   */
  function getTimestampInMsFromUuidV1(uint128 uuid)
    internal
    pure
    returns (uint64 msSinceUnixEpoch)
  {
    // https://tools.ietf.org/html/rfc4122#section-4.1.2
    uint128 version = (uuid >> 76) & 0x0000000000000000000000000000000F;
    require(version == 1, 'Must be v1 UUID');

    // Time components are in reverse order so shift+mask each to reassemble
    uint128 timeHigh = (uuid >> 16) & 0x00000000000000000FFF000000000000;
    uint128 timeMid = (uuid >> 48) & 0x00000000000000000000FFFF00000000;
    uint128 timeLow = (uuid >> 96) & 0x000000000000000000000000FFFFFFFF;
    uint128 nsSinceGregorianEpoch = (timeHigh | timeMid | timeLow);
    // Gregorian offset given in seconds by https://www.wolframalpha.com/input/?i=convert+1582-10-15+UTC+to+unix+time
    msSinceUnixEpoch = uint64(nsSinceGregorianEpoch / 10000) - 12219292800000;

    return msSinceUnixEpoch;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { Constants } from './Constants.sol';
import { Hashing } from './Hashing.sol';
import { IERC20 } from './Interfaces.sol';
import { Math } from './Math.sol';
import { UUID } from './UUID.sol';
import { OrderSide, OrderType } from './Enums.sol';
import {
  Asset,
  LiquidityPool,
  Order,
  OrderBookTrade,
  NonceInvalidation,
  PoolTrade,
  Withdrawal
} from './Structs.sol';

library Validations {
  using AssetRegistry for AssetRegistry.Storage;

  /**
   * @dev Perform fee validations common to both orderbook-only and hybrid trades. Does not
   * validate if fees are excessive as taker fee structure differs between these trade types
   *
   */
  function validateOrderBookTradeFees(OrderBookTrade memory trade)
    internal
    pure
  {
    require(
      trade.netBaseQuantityInPips +
        (
          trade.makerFeeAssetAddress == trade.baseAssetAddress
            ? trade.makerFeeQuantityInPips
            : trade.takerFeeQuantityInPips
        ) ==
        trade.grossBaseQuantityInPips,
      'Orderbook base fees unbalanced'
    );
    require(
      trade.netQuoteQuantityInPips +
        (
          trade.makerFeeAssetAddress == trade.quoteAssetAddress
            ? trade.makerFeeQuantityInPips
            : trade.takerFeeQuantityInPips
        ) ==
        trade.grossQuoteQuantityInPips,
      'Orderbook quote fees unbalanced'
    );
  }

  function validateOrderNonce(
    Order memory order,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) internal view {
    require(
      UUID.getTimestampInMsFromUuidV1(order.nonce) >
        loadLastInvalidatedTimestamp(order.walletAddress, nonceInvalidations),
      'Order nonce timestamp too low'
    );
  }

  function validateOrderNonces(
    Order memory buy,
    Order memory sell,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) internal view {
    require(
      UUID.getTimestampInMsFromUuidV1(buy.nonce) >
        loadLastInvalidatedTimestamp(buy.walletAddress, nonceInvalidations),
      'Buy order nonce timestamp too low'
    );
    require(
      UUID.getTimestampInMsFromUuidV1(sell.nonce) >
        loadLastInvalidatedTimestamp(sell.walletAddress, nonceInvalidations),
      'Sell order nonce timestamp too low'
    );
  }

  function validateOrderSignature(
    Order memory order,
    string memory baseAssetSymbol,
    string memory quoteAssetSymbol
  ) internal pure returns (bytes32) {
    bytes32 orderHash =
      Hashing.getOrderHash(order, baseAssetSymbol, quoteAssetSymbol);

    require(
      Hashing.isSignatureValid(
        orderHash,
        order.walletSignature,
        order.walletAddress
      ),
      order.side == OrderSide.Buy
        ? 'Invalid wallet signature for buy order'
        : 'Invalid wallet signature for sell order'
    );

    return orderHash;
  }

  function validatePoolReserveRatio(LiquidityPool memory pool) internal pure {
    (uint64 sortedReserve0, uint64 sortedReserve1) =
      pool.baseAssetReserveInPips <= pool.quoteAssetReserveInPips
        ? (pool.baseAssetReserveInPips, pool.quoteAssetReserveInPips)
        : (pool.quoteAssetReserveInPips, pool.baseAssetReserveInPips);
    require(
      uint256(sortedReserve0) * Constants.maxLiquidityPoolReserveRatio >=
        sortedReserve1,
      'Exceeded max reserve ratio'
    );
  }

  /**
   * @dev Perform fee validations common to both pool-only and hybrid trades
   */
  function validatePoolTradeInputFees(
    OrderSide orderSide,
    PoolTrade memory poolTrade
  ) internal pure {
    // Buy order sends quote as pool input, receives base as pool output; sell order sends base as
    // pool input, receives quote as pool output
    (uint64 netInputQuantityInPips, uint64 grossInputQuantityInPips) =
      orderSide == OrderSide.Buy
        ? (poolTrade.netQuoteQuantityInPips, poolTrade.grossQuoteQuantityInPips)
        : (poolTrade.netBaseQuantityInPips, poolTrade.grossBaseQuantityInPips);

    require(
      netInputQuantityInPips +
        poolTrade.takerPoolFeeQuantityInPips +
        poolTrade.takerProtocolFeeQuantityInPips ==
        grossInputQuantityInPips,
      'Pool input fees unbalanced'
    );
    require(
      Validations.isFeeQuantityValid(
        grossInputQuantityInPips - netInputQuantityInPips,
        grossInputQuantityInPips,
        Constants.maxPoolInputFeeBasisPoints
      ),
      'Excessive pool input fee'
    );
  }

  function validateWithdrawalSignature(Withdrawal memory withdrawal)
    internal
    pure
    returns (bytes32)
  {
    bytes32 withdrawalHash = Hashing.getWithdrawalHash(withdrawal);

    require(
      Hashing.isSignatureValid(
        withdrawalHash,
        withdrawal.walletSignature,
        withdrawal.walletAddress
      ),
      'Invalid wallet signature'
    );

    return withdrawalHash;
  }

  // Utils //

  function calculateImpliedQuoteQuantityInPips(
    uint64 baseQuantityInPips,
    uint64 limitPriceInPips
  ) internal pure returns (uint64) {
    return
      Math.multiplyPipsByFraction(
        baseQuantityInPips,
        limitPriceInPips,
        Constants.pipPriceMultiplier
      );
  }

  function loadLastInvalidatedTimestamp(
    address walletAddress,
    mapping(address => NonceInvalidation) storage nonceInvalidations
  ) private view returns (uint64) {
    if (
      nonceInvalidations[walletAddress].exists &&
      nonceInvalidations[walletAddress].effectiveBlockNumber <= block.number
    ) {
      return nonceInvalidations[walletAddress].timestampInMs;
    }

    return 0;
  }

  function isFeeQuantityValid(
    uint64 fee,
    uint64 total,
    uint64 max
  ) internal pure returns (bool) {
    uint64 feeBasisPoints = (fee * Constants.basisPointsInTotal) / total;
    return feeBasisPoints <= max;
  }

  function isLimitOrderType(OrderType orderType) internal pure returns (bool) {
    return
      orderType == OrderType.Limit ||
      orderType == OrderType.LimitMaker ||
      orderType == OrderType.StopLossLimit ||
      orderType == OrderType.TakeProfitLimit;
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.8.4;

import { AssetRegistry } from './AssetRegistry.sol';
import { AssetUnitConversions } from './AssetUnitConversions.sol';
import { BalanceTracking } from './BalanceTracking.sol';
import { Constants } from './Constants.sol';
import { UUID } from './UUID.sol';
import { Validations } from './Validations.sol';
import { WithdrawalType } from './Enums.sol';
import {
  Asset,
  LiquidityChangeExecution,
  LiquidityRemoval,
  Withdrawal
} from './Structs.sol';
import { ICustodian, ILiquidityProviderToken } from './Interfaces.sol';

library Withdrawing {
  using AssetRegistry for AssetRegistry.Storage;
  using BalanceTracking for BalanceTracking.Storage;

  function withdraw(
    Withdrawal memory withdrawal,
    ICustodian custodian,
    address feeWallet,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking,
    mapping(bytes32 => bool) storage completedWithdrawalHashes
  )
    public
    returns (
      uint64 newExchangeBalanceInPips,
      uint256 newExchangeBalanceInAssetUnits,
      address assetAddress,
      string memory assetSymbol
    )
  {
    // Validations
    require(
      Validations.isFeeQuantityValid(
        withdrawal.gasFeeInPips,
        withdrawal.grossQuantityInPips,
        Constants.maxFeeBasisPoints
      ),
      'Excessive withdrawal fee'
    );
    bytes32 withdrawalHash =
      Validations.validateWithdrawalSignature(withdrawal);
    require(
      !completedWithdrawalHashes[withdrawalHash],
      'Hash already withdrawn'
    );

    // If withdrawal is by asset symbol (most common) then resolve to asset address
    Asset memory asset =
      withdrawal.withdrawalType == WithdrawalType.BySymbol
        ? assetRegistry.loadAssetBySymbol(
          withdrawal.assetSymbol,
          UUID.getTimestampInMsFromUuidV1(withdrawal.nonce)
        )
        : assetRegistry.loadAssetByAddress(withdrawal.assetAddress);

    assetSymbol = asset.symbol;
    assetAddress = asset.assetAddress;

    // Update wallet balances
    newExchangeBalanceInPips = balanceTracking.updateForWithdrawal(
      withdrawal,
      asset.assetAddress,
      feeWallet
    );
    newExchangeBalanceInAssetUnits = AssetUnitConversions.pipsToAssetUnits(
      newExchangeBalanceInPips,
      asset.decimals
    );

    // Transfer funds from Custodian to wallet
    uint256 netAssetQuantityInAssetUnits =
      AssetUnitConversions.pipsToAssetUnits(
        withdrawal.grossQuantityInPips - withdrawal.gasFeeInPips,
        asset.decimals
      );
    custodian.withdraw(
      withdrawal.walletAddress,
      asset.assetAddress,
      netAssetQuantityInAssetUnits
    );

    // Replay prevention
    completedWithdrawalHashes[withdrawalHash] = true;
  }

  function withdrawExit(
    address assetAddress,
    ICustodian custodian,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) external returns (uint64 previousExchangeBalanceInPips) {
    // Update wallet balance
    previousExchangeBalanceInPips = balanceTracking.updateForExit(
      msg.sender,
      assetAddress
    );

    // Transfer asset from Custodian to wallet
    Asset memory asset = assetRegistry.loadAssetByAddress(assetAddress);
    uint256 balanceInAssetUnits =
      AssetUnitConversions.pipsToAssetUnits(
        previousExchangeBalanceInPips,
        asset.decimals
      );
    ICustodian(custodian).withdraw(
      payable(msg.sender),
      assetAddress,
      balanceInAssetUnits
    );
  }

  function withdrawLiquidity(
    LiquidityRemoval memory removal,
    LiquidityChangeExecution memory execution,
    ICustodian custodian,
    address feeWallet,
    ILiquidityProviderToken liquidityProviderToken,
    AssetRegistry.Storage storage assetRegistry,
    BalanceTracking.Storage storage balanceTracking
  ) internal {
    (
      uint64 outputBaseAssetQuantityInPips,
      uint64 outputQuoteAssetQuantityInPips
    ) =
      balanceTracking.updateForRemoveLiquidity(
        removal,
        execution,
        feeWallet,
        address(custodian),
        liquidityProviderToken
      );

    Asset memory asset;
    if (outputBaseAssetQuantityInPips > 0) {
      asset = assetRegistry.loadAssetByAddress(execution.baseAssetAddress);
      custodian.withdraw(
        removal.to,
        execution.baseAssetAddress,
        AssetUnitConversions.pipsToAssetUnits(
          outputBaseAssetQuantityInPips,
          asset.decimals
        )
      );
    }
    if (outputQuoteAssetQuantityInPips > 0) {
      asset = assetRegistry.loadAssetByAddress(execution.quoteAssetAddress);
      custodian.withdraw(
        removal.to,
        execution.quoteAssetAddress,
        AssetUnitConversions.pipsToAssetUnits(
          outputQuoteAssetQuantityInPips,
          asset.decimals
        )
      );
    }
  }
}