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