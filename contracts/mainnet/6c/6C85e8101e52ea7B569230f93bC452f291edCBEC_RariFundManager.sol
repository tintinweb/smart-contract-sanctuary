/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/drafts/SignedSafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";

import "./RariFundManager.sol";
import "./lib/pools/DydxPoolController.sol";
import "./lib/pools/CompoundPoolController.sol";
import "./lib/pools/AavePoolController.sol";
import "./lib/pools/MStablePoolController.sol";
import "./lib/pools/FusePoolController.sol";
import "./lib/exchanges/MStableExchangeController.sol";
import "./lib/exchanges/UniswapExchangeController.sol";

import "./external/compound/CErc20.sol";

/**
 * @title RariFundController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice This contract handles deposits to and withdrawals from the liquidity pools that power the Rari Stable Pool as well as currency exchanges via 0x.
 */
contract RariFundController is Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /**
     * @dev Boolean to be checked on `upgradeFundController`.
     */
    bool public constant IS_RARI_FUND_CONTROLLER = true;

    /**
     * @dev Boolean that, if true, disables the primary functionality of this RariFundController.
     */
    bool private _fundDisabled;

    /**
     * @dev Address of the RariFundManager.
     */
    address private _rariFundManagerContract;

    /**
     * @dev Contract of the RariFundManager.
     */
    RariFundManager public rariFundManager;

    /**
     * @dev Address of the rebalancer.
     */
    address private _rariFundRebalancerAddress;

    /**
     * @dev Array of currencies supported by the fund.
     */
    string[] private _supportedCurrencies;

    /**
     * @dev Maps `_supportedCurrencies` items to their indexes.
     */
    mapping(string => uint8) public _currencyIndexes;

    /**
     * @dev Maps supported currency codes to their decimal precisions (number of digits after the decimal point).
     */
    mapping(string => uint256) private _currencyDecimals;

    /**
     * @dev Maps supported currency codes to ERC20 token contract addresses.
     */
    mapping(string => address) private _erc20Contracts;

    /**
     * @dev Enum for liqudity pools supported by Rari.
     */
    enum LiquidityPool { dYdX, Compound, Aave, mStable }

    /**
     * @dev Maps currency codes to arrays of supported pools.
     */
    mapping(string => uint8[]) private _poolsByCurrency;

    /**
     * @dev Constructor that sets supported ERC20 contract addresses and supported pools for each supported token.
     */
    function initialize() public initializer {
        // Initialize base contracts
        Ownable.initialize(msg.sender);
        
        // Add supported currencies
        addSupportedCurrency("DAI", 0x6B175474E89094C44Da98b954EedeAC495271d0F, 18);
        addPoolToCurrency("DAI", LiquidityPool.dYdX);
        addPoolToCurrency("DAI", LiquidityPool.Compound);
        addPoolToCurrency("DAI", LiquidityPool.Aave);
        addSupportedCurrency("USDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 6);
        addPoolToCurrency("USDC", LiquidityPool.dYdX);
        addPoolToCurrency("USDC", LiquidityPool.Compound);
        addPoolToCurrency("USDC", LiquidityPool.Aave);
        addSupportedCurrency("USDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7, 6);
        addPoolToCurrency("USDT", LiquidityPool.Compound);
        addPoolToCurrency("USDT", LiquidityPool.Aave);
        addSupportedCurrency("TUSD", 0x0000000000085d4780B73119b644AE5ecd22b376, 18);
        addPoolToCurrency("TUSD", LiquidityPool.Aave);
        addSupportedCurrency("BUSD", 0x4Fabb145d64652a948d72533023f6E7A623C7C53, 18);
        addPoolToCurrency("BUSD", LiquidityPool.Aave);
        addSupportedCurrency("sUSD", 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, 18);
        addPoolToCurrency("sUSD", LiquidityPool.Aave);
        addSupportedCurrency("mUSD", 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5, 18);
        addPoolToCurrency("mUSD", LiquidityPool.mStable);
    }

    /**
     * @dev Marks a token as supported by the fund and stores its decimal precision and ERC20 contract address.
     * @param currencyCode The currency code of the token.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param decimals The decimal precision (number of digits after the decimal point) of the token.
     */
    function addSupportedCurrency(string memory currencyCode, address erc20Contract, uint256 decimals) internal {
        _currencyIndexes[currencyCode] = uint8(_supportedCurrencies.length);
        _supportedCurrencies.push(currencyCode);
        _erc20Contracts[currencyCode] = erc20Contract;
        _currencyDecimals[currencyCode] = decimals;
    }

    /**
     * @dev Adds a supported pool for a token.
     * @param currencyCode The currency code of the token.
     * @param pool Pool ID to be supported.
     */
    function addPoolToCurrency(string memory currencyCode, LiquidityPool pool) internal {
        _poolsByCurrency[currencyCode].push(uint8(pool));
    }

    /**
     * @dev Sets or upgrades RariFundController by withdrawing all tokens from all pools and forwarding them from the old to the new.
     * @param newContract The address of the new RariFundController contract.
     */
    function upgradeFundController(address payable newContract) external onlyOwner {
        // Verify fund is disabled + verify new fund controller contract
        require(_fundDisabled, "This fund controller contract must be disabled before it can be upgraded.");
        require(RariFundController(newContract).IS_RARI_FUND_CONTROLLER(), "New contract does not have IS_RARI_FUND_CONTROLLER set to true.");

        // For each supported currency:
        for (uint256 i = 0; i < _supportedCurrencies.length; i++) {
            string memory currencyCode = _supportedCurrencies[i];

            // For each pool supported by this currency:
            for (uint256 j = 0; j < _poolsByCurrency[currencyCode].length; j++) {
                uint8 pool = _poolsByCurrency[currencyCode][j];

                // If the pool has any funds in this currency, withdraw it
                if (hasCurrencyInPool(pool, currencyCode)) {           
                    if (fuseAssets[pool][currencyCode] != address(0)) FusePoolController.transferAll(fuseAssets[pool][currencyCode], newContract); // Transfer Fuse cTokens directly
                    else _withdrawAllFromPool(pool, currencyCode);
                }
            }

            // Transfer all of this token to new fund controller
            IERC20 token = IERC20(_erc20Contracts[currencyCode]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) token.safeTransfer(newContract, balance);
        }
    }

    /**
     * @dev Sets or upgrades RariFundController by forwarding tokens from the old to the new.
     * @param newContract The address of the new RariFundController contract.
     * @param erc20Contract The ERC20 contract address of the token to forward.
     * @return Boolean indicating if the balance transferred was greater than 0.
     */
    function upgradeFundController(address payable newContract, address erc20Contract) external onlyOwner returns (bool) {
        // Verify fund is disabled + verify new fund controller contract
        require(_fundDisabled, "This fund controller contract must be disabled before it can be upgraded.");
        require(RariFundController(newContract).IS_RARI_FUND_CONTROLLER(), "New contract does not have IS_RARI_FUND_CONTROLLER set to true.");

        // Transfer all of this token to new fund controller
        IERC20 token = IERC20(erc20Contract);
        uint256 balance = token.balanceOf(address(this));
        if (balance <= 0) return false;
        token.safeTransfer(newContract, balance);
        return true;
    }

    /**
     * @dev Emitted when the RariFundManager of the RariFundController is set.
     */
    event FundManagerSet(address newAddress);

    /**
     * @dev Sets or upgrades the RariFundManager of the RariFundController.
     * @param newContract The address of the new RariFundManager contract.
     */
    function setFundManager(address newContract) external onlyOwner {
        // Approve maximum output tokens to RariFundManager
        for (uint256 i = 0; i < _supportedCurrencies.length; i++) {
            IERC20 token = IERC20(_erc20Contracts[_supportedCurrencies[i]]);
            if (_rariFundManagerContract != address(0)) token.safeApprove(_rariFundManagerContract, 0);
            if (newContract != address(0)) token.safeApprove(newContract, uint256(-1));
        }

        _rariFundManagerContract = newContract;
        rariFundManager = RariFundManager(_rariFundManagerContract);
        emit FundManagerSet(newContract);
    }

    /**
     * @dev Throws if called by any account other than the RariFundManager.
     */
    modifier onlyManager() {
        require(_rariFundManagerContract == msg.sender, "Caller is not the fund manager.");
        _;
    }

    /**
     * @dev Emitted when the rebalancer of the RariFundController is set.
     */
    event FundRebalancerSet(address newAddress);

    /**
     * @dev Sets or upgrades the rebalancer of the RariFundController.
     * @param newAddress The Ethereum address of the new rebalancer server.
     */
    function setFundRebalancer(address newAddress) external onlyOwner {
        _rariFundRebalancerAddress = newAddress;
        emit FundRebalancerSet(newAddress);
    }

    /**
     * @dev Throws if called by any account other than the rebalancer.
     */
    modifier onlyRebalancer() {
        require(_rariFundRebalancerAddress == msg.sender, "Caller is not the rebalancer.");
        _;
    }

    /**
     * @dev Emitted when the primary functionality of this RariFundController contract has been disabled.
     */
    event FundDisabled();

    /**
     * @dev Emitted when the primary functionality of this RariFundController contract has been enabled.
     */
    event FundEnabled();

    /**
     * @dev Disables primary functionality of this RariFundController so contract(s) can be upgraded.
     */
    function disableFund() external onlyOwner {
        require(!_fundDisabled, "Fund already disabled.");
        _fundDisabled = true;
        emit FundDisabled();
    }

    /**
     * @dev Enables primary functionality of this RariFundController once contract(s) are upgraded.
     */
    function enableFund() external onlyOwner {
        require(_fundDisabled, "Fund already enabled.");
        _fundDisabled = false;
        emit FundEnabled();
    }

    /**
     * @dev Throws if fund is disabled.
     */
    modifier fundEnabled() {
        require(!_fundDisabled, "This fund controller contract is disabled. This may be due to an upgrade.");
        _;
    }

    /**
     * @dev Returns `_poolsByCurrency[currencyCode]`. Used by `RariFundManager` and `RariFundProxy.getRawFundBalancesAndPrices`.
     */
    function getPoolsByCurrency(string calldata currencyCode) external view returns (uint8[] memory) {
        return _poolsByCurrency[currencyCode];
    }

    /**
     * @dev Returns the balances of all currencies supported by dYdX.
     * @return An array of ERC20 token contract addresses and a corresponding array of balances.
     */
    function getDydxBalances() external view returns (address[] memory, uint256[] memory) {
        return DydxPoolController.getBalances();
    }

    /**
     * @dev Returns the fund controller's balance of the specified currency in the specified pool (without checking `_poolsWithFunds` first).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `CompoundPoolController.getBalance`) potentially modifies the state.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token.
     */
    function _getPoolBalance(uint8 pool, string memory currencyCode) public returns (uint256) {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        if (pool == uint8(LiquidityPool.dYdX)) return DydxPoolController.getBalance(erc20Contract);
        else if (pool == uint8(LiquidityPool.Compound)) return CompoundPoolController.getBalance(erc20Contract);
        else if (pool == uint8(LiquidityPool.Aave)) return AavePoolController.getBalance(erc20Contract);
        else if (pool == uint8(LiquidityPool.mStable) && erc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) return MStablePoolController.getBalance();
        else if (fuseAssets[pool][currencyCode] != address(0)) return FusePoolController.getBalance(fuseAssets[pool][currencyCode]);
        else revert("Invalid pool index.");
    }

    /**
     * @dev Returns the fund controller's balance of the specified currency in the specified pool (checking `_poolsWithFunds` first to save gas).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `CompoundPoolController.getBalance`) potentially modifies the state.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token.
     */
    function getPoolBalance(uint8 pool, string memory currencyCode) public returns (uint256) {
        if (!_poolsWithFunds[currencyCode][pool]) return 0;
        return _getPoolBalance(pool, currencyCode);
    }

    /**
     * @dev Approves tokens to the specified pool without spending gas on every deposit.
     * Note that this function is vulnerable to the allowance double-spend exploit, as with the `approve` functions of the ERC20 contracts themselves. If you are concerned and setting exact allowances, make sure to set allowance to 0 on the client side before setting an allowance greater than 0.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token to be approved.
     * @param amount The amount of tokens to be approved.
     */
    function approveToPool(uint8 pool, string calldata currencyCode, uint256 amount) external fundEnabled onlyRebalancer {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        if (pool == uint8(LiquidityPool.dYdX)) DydxPoolController.approve(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Compound)) CompoundPoolController.approve(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Aave)) AavePoolController.approve(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.mStable) && erc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) return MStablePoolController.approve(amount);
        else if (fuseAssets[pool][currencyCode] != address(0)) FusePoolController.approve(fuseAssets[pool][currencyCode], erc20Contract, amount);
        else revert("Invalid pool index.");
    }

    /**
     * @dev Mapping of bools indicating the presence of funds to pool indexes to currency codes.
     */
    mapping(string => mapping(uint8 => bool)) _poolsWithFunds;

    /**
     * @dev Return a boolean indicating if the fund controller has funds in `currencyCode` in `pool`.
     * @param pool The index of the pool to check.
     * @param currencyCode The currency code of the token to check.
     */
    function hasCurrencyInPool(uint8 pool, string memory currencyCode) public view returns (bool) {
        return _poolsWithFunds[currencyCode][pool];
    }

    /**
     * @dev Referral code for Aave deposits.
     */
    uint16 _aaveReferralCode;

    /**
     * @dev Sets the referral code for Aave deposits.
     * @param referralCode The referral code.
     */
    function setAaveReferralCode(uint16 referralCode) external onlyOwner {
        _aaveReferralCode = referralCode;
    }

    /**
     * @dev Enum for pool allocation action types supported by Rari.
     */
    enum PoolAllocationAction { Deposit, Withdraw, WithdrawAll }

    /**
     * @dev Emitted when a deposit or withdrawal is made.
     * Note that `amount` is not set for `WithdrawAll` actions.
     */
    event PoolAllocation(PoolAllocationAction indexed action, uint8 indexed pool, string indexed currencyCode, uint256 amount);

    /**
     * @dev Deposits funds to the specified pool.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function depositToPool(uint8 pool, string calldata currencyCode, uint256 amount) external fundEnabled onlyRebalancer {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        if (pool == uint8(LiquidityPool.dYdX)) DydxPoolController.deposit(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Compound)) CompoundPoolController.deposit(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Aave)) AavePoolController.deposit(erc20Contract, amount, _aaveReferralCode);
        else if (pool == uint8(LiquidityPool.mStable) && erc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) MStablePoolController.deposit(amount);
        else if (fuseAssets[pool][currencyCode] != address(0)) FusePoolController.deposit(fuseAssets[pool][currencyCode], amount);
        else revert("Invalid pool index.");
        _poolsWithFunds[currencyCode][pool] = true;
        emit PoolAllocation(PoolAllocationAction.Deposit, pool, currencyCode, amount);
    }

    /**
     * @dev Internal function to withdraw funds from the specified pool.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function _withdrawFromPool(uint8 pool, string memory currencyCode, uint256 amount) internal {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        if (pool == uint8(LiquidityPool.dYdX)) DydxPoolController.withdraw(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Compound)) CompoundPoolController.withdraw(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.Aave)) AavePoolController.withdraw(erc20Contract, amount);
        else if (pool == uint8(LiquidityPool.mStable) && erc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) MStablePoolController.withdraw(amount);
        else if (fuseAssets[pool][currencyCode] != address(0)) FusePoolController.withdraw(fuseAssets[pool][currencyCode], amount);
        else revert("Invalid pool index.");
        emit PoolAllocation(PoolAllocationAction.Withdraw, pool, currencyCode, amount);
    }

    /**
     * @dev Withdraws funds from the specified pool.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdrawFromPool(uint8 pool, string calldata currencyCode, uint256 amount) external fundEnabled onlyRebalancer {
        _withdrawFromPool(pool, currencyCode, amount);
        _poolsWithFunds[currencyCode][pool] = _getPoolBalance(pool, currencyCode) > 0;
    }

    /**
     * @dev Withdraws funds from the specified pool (with optimizations based on the `all` parameter).
     * If we already know all funds are being withdrawn, we won't have to check again here in this function. 
     * If withdrawing all funds, we choose _withdrawFromPool or _withdrawAllFromPool based on estimated gas usage.
     * The value of `all` is trusted because `msg.sender` is always RariFundManager.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     * @param all Boolean indicating if all funds are being withdrawn.
     */
    function withdrawFromPoolOptimized(uint8 pool, string calldata currencyCode, uint256 amount, bool all) external fundEnabled onlyManager {
        all ? _withdrawAllFromPool(pool, currencyCode) : _withdrawFromPool(pool, currencyCode, amount);
        if (all) _poolsWithFunds[currencyCode][pool] = false;
    }

    /**
     * @dev Internal function to withdraw all funds from the specified pool.
     * @param pool The index of the pool.
     * @param currencyCode The ERC20 contract of the token to be withdrawn.
     */
    function _withdrawAllFromPool(uint8 pool, string memory currencyCode) internal {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        if (pool == uint8(LiquidityPool.dYdX)) DydxPoolController.withdrawAll(erc20Contract);
        else if (pool == uint8(LiquidityPool.Compound)) require(CompoundPoolController.withdrawAll(erc20Contract), "No Compound balance to withdraw from.");
        else if (pool == uint8(LiquidityPool.Aave)) require(AavePoolController.withdrawAll(erc20Contract), "No Aave balance to withdraw from.");
        else if (pool == uint8(LiquidityPool.mStable) && erc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) require(MStablePoolController.withdrawAll(), "No mStable balance to withdraw from.");
        else if (fuseAssets[pool][currencyCode] != address(0)) require(FusePoolController.withdrawAll(fuseAssets[pool][currencyCode]), "No Fuse pool balance to withdraw from.");
        else revert("Invalid pool index.");
        _poolsWithFunds[currencyCode][pool] = false;
        emit PoolAllocation(PoolAllocationAction.WithdrawAll, pool, currencyCode, 0);
    }

    /**
     * @dev Withdraws all funds from the specified pool.
     * @param pool The index of the pool.
     * @param currencyCode The ERC20 contract of the token to be withdrawn.
    */
    function withdrawAllFromPool(uint8 pool, string calldata currencyCode) external fundEnabled onlyRebalancer {
        _withdrawAllFromPool(pool, currencyCode);
    }

    /**
     * @dev Withdraws all funds from the specified pool (without requiring the fund to be enabled).
     * @param pool The index of the pool.
     * @param currencyCode The ERC20 contract of the token to be withdrawn.
     */
    function withdrawAllFromPoolOnUpgrade(uint8 pool, string calldata currencyCode) external onlyOwner {
        _withdrawAllFromPool(pool, currencyCode);
    }

    /**
     * @dev Enum for currency exchanges supported by Rari.
     */
    enum CurrencyExchange {
        ZeroEx, // No longer in use (kept to keep this enum backwards-compatible)
        mStable,
        Uniswap
    }

    /**
     * @dev Emitted when currencies are exchanged via 0x or mStable.
     * Note that `inputAmountUsd` and `outputAmountUsd` are not present when the input currency is not a supported stablecoin (i.e., when exchanging COMP via 0x).
     */
    event CurrencyTrade(string indexed inputCurrencyCode, string indexed outputCurrencyCode, uint256 inputAmount, uint256 inputAmountUsd, uint256 outputAmount, uint256 outputAmountUsd, CurrencyExchange indexed exchange);

    /**
     * @dev Per-trade and daily limit on exchange order slippage (scaled by 1e18) of supported stablecoins.
     */
    int256 private _exchangeLossRateLimit;

    /**
     * @dev Sets or upgrades the per-trade and daily limit on exchange order loss over raw total fund balance.
     * @param limit The per-trade and daily limit on exchange order loss over raw total fund balance (scaled by 1e18).
     */
    function setExchangeLossRateLimit(int256 limit) external onlyOwner {
        _exchangeLossRateLimit = limit;
    }

    /**
     * @dev Struct for a loss of funds due to a currency exchange (loss could be negative).
     */
    struct CurrencyExchangeLoss {
        uint256 timestamp;
        int256 lossRate;
    }

    /**
     * @dev Array of arrays containing 0x exchange order time and slippage (scaled by 1e18).
     */
    CurrencyExchangeLoss[] private _lossRateHistory;

    /**
     * @dev Gets currency code for `erc20Contract` if it maps to a valid supported currency code.
     */
    function getCurrencyCodeByErc20Contract(address erc20Contract) internal view returns (string memory) {
        for (uint256 i = 0; i < _supportedCurrencies.length; i++) if (_erc20Contracts[_supportedCurrencies[i]] == erc20Contract) return _supportedCurrencies[i];
        return "";
    }

    /**
     * @dev Market sell `inputAmount` via Uniswap (reverting if the output is not a supported stablecoin, there is not enough liquidity to sell `inputAmount`, `minOutputAmount` is not satisfied, or the 24-hour slippage limit is surpassed).
     * We should be able to make this function external and use calldata for all parameters, but Solidity does not support calldata structs (https://github.com/ethereum/solidity/issues/5479).
     * @param path The Uniswap V2 ERC20 token address path to use for the exchange.
     * @param inputAmount The amount of the input asset to sell/send.
     * @param minOutputAmount The minimum amount of the output asset to buy/receive.
     */
    function swapExactTokensForTokens(address[] calldata path, uint256 inputAmount, uint256 minOutputAmount) external fundEnabled onlyRebalancer {
        // Exchanges not supported if _exchangeLossRateLimit == min value for int256
        require(_exchangeLossRateLimit > int256(uint256(1) << 255), "Exchanges have been disabled.");

        // Check if input is a supported stablecoin and make sure output is a supported stablecoin
        string memory inputCurrencyCode = getCurrencyCodeByErc20Contract(path[0]);
        string memory outputCurrencyCode = getCurrencyCodeByErc20Contract(path[path.length - 1]);
        require(bytes(outputCurrencyCode).length > 0, "Output token is not a supported stablecoin.");

        // Get prices and raw fund balance before exchange
        uint256[] memory pricesInUsd;
        uint256 rawFundBalanceBeforeExchange;

        if (bytes(inputCurrencyCode).length > 0) {
            pricesInUsd = rariFundManager.rariFundPriceConsumer().getCurrencyPricesInUsd();
            rawFundBalanceBeforeExchange = rariFundManager.getRawFundBalance(pricesInUsd);
        }

        // Approve tokens
        UniswapExchangeController.approve(path[0], inputAmount);

        // Market sell
        uint256 outputAmount = UniswapExchangeController.swapExactTokensForTokens(inputAmount, minOutputAmount, path);

        // Check per-trade and 24-hour loss rate limit (if inputting a supported stablecoin)
        uint256 inputAmountUsd = 0;
        uint256 outputAmountUsd = 0;

        if (bytes(inputCurrencyCode).length > 0) {
            // Get amount in USD
            inputAmountUsd = toUsd(inputCurrencyCode, inputAmount, pricesInUsd);
            outputAmountUsd = toUsd(outputCurrencyCode, outputAmount, pricesInUsd);

            // Check loss rate limits
            handleExchangeLoss(inputAmountUsd, outputAmountUsd, rawFundBalanceBeforeExchange);
        }

        // Emit event
        emit CurrencyTrade(bytes(inputCurrencyCode).length > 0 ? inputCurrencyCode : ERC20Detailed(path[path.length - 1]).symbol(), outputCurrencyCode, inputAmount, inputAmountUsd, outputAmount, outputAmountUsd, CurrencyExchange.Uniswap);
    }

    /**
     * @dev Converts an amount to USD (scaled by 1e18).
     * @param currencyCode The currency code to convert.
     * @param amount The amount to convert.
     * @param pricesInUsd An array of prices in USD for all supported currencies (in order).
     * @return The equivalent USD amount (scaled by 1e18).
     */
    function toUsd(string memory currencyCode, uint256 amount, uint256[] memory pricesInUsd) internal view returns (uint256) {
        return amount.mul(pricesInUsd[_currencyIndexes[currencyCode]]).div(10 ** _currencyDecimals[currencyCode]);
    }

    /**
     * @dev Checks the validity of a trade given the 24-hour exchange loss rate limit; if breached, reverts; otherwise, logs the loss rate of the trade.
     * Note that while miners may be able to manipulate `block.timestamp` by up to 900 seconds, this small margin of error is acceptable.
     * @param inputAmountUsd The amount sold in USD (scaled by 1e18).
     * @param outputAmountUsd The amount bought in USD (scaled by 1e18).
     */
    function handleExchangeLoss(uint256 inputAmountUsd, uint256 outputAmountUsd, uint256 rawFundBalanceBeforeExchange) internal {
        // Calculate loss in USD
        int256 lossUsd = int256(inputAmountUsd).sub(int256(outputAmountUsd));

        // Check per-trade loss rate limit (equals daily loss rate limit)
        int256 tradeLossRateOnTrade = lossUsd.mul(1e18).div(int256(inputAmountUsd));
        require(tradeLossRateOnTrade <= _exchangeLossRateLimit, "This exchange would violate the per-trade loss rate limit.");
        
        // Check if sum of loss rates over the last 24 hours + this trade's loss rate > the limit
        int256 lossRateLastDay = 0;

        for (uint256 i = _lossRateHistory.length; i > 0; i--) {
            if (_lossRateHistory[i - 1].timestamp < block.timestamp.sub(86400)) break;
            lossRateLastDay = lossRateLastDay.add(_lossRateHistory[i - 1].lossRate);
        }

        int256 tradeLossRateOnFund = lossUsd.mul(1e18).div(int256(rawFundBalanceBeforeExchange));
        require(lossRateLastDay.add(tradeLossRateOnFund) <= _exchangeLossRateLimit, "This exchange would violate the 24-hour loss rate limit.");

        // Log loss rate in history
        _lossRateHistory.push(CurrencyExchangeLoss(block.timestamp, tradeLossRateOnFund));
    }

    /**
     * @dev Swaps tokens via mStable mUSD.
     * @param inputCurrencyCode The currency code of the input token to be sold.
     * @param outputCurrencyCode The currency code of the output token to be bought.
     * @param inputAmount The amount of input tokens to be sold.
     * @param minOutputAmount The minimum amount of output tokens to be bought.
     */
    function swapMStable(string calldata inputCurrencyCode, string calldata outputCurrencyCode, uint256 inputAmount, uint256 minOutputAmount) external fundEnabled onlyRebalancer {
        // Exchanges not supported if _exchangeLossRateLimit == min value for int256
        require(_exchangeLossRateLimit > int256(uint256(1) << 255), "Exchanges have been disabled.");

        // Input validation
        address inputErc20Contract = _erc20Contracts[inputCurrencyCode];
        address outputErc20Contract = _erc20Contracts[outputCurrencyCode];
        require(outputErc20Contract != address(0), "Invalid input currency code.");
        require(inputErc20Contract != address(0), "Invalid output currency code.");

        // Get prices and raw fund balance before exchange
        uint256[] memory pricesInUsd;
        uint256 rawFundBalanceBeforeExchange;
        pricesInUsd = rariFundManager.rariFundPriceConsumer().getCurrencyPricesInUsd();
        rawFundBalanceBeforeExchange = rariFundManager.getRawFundBalance(pricesInUsd);

        // Approve to mUSD
        MStableExchangeController.approve(inputErc20Contract, inputAmount);

        // Swap stablecoins via mUSD
        uint256 outputAmount = MStableExchangeController.swap(inputErc20Contract, outputErc20Contract, inputAmount, minOutputAmount);

        // Check 24-hour loss rate limit
        uint256 inputFilledAmountUsd = toUsd(inputCurrencyCode, inputAmount, pricesInUsd);
        uint256 outputFilledAmountUsd = toUsd(outputCurrencyCode, outputAmount, pricesInUsd);
        handleExchangeLoss(inputFilledAmountUsd, outputFilledAmountUsd, rawFundBalanceBeforeExchange);

        // Emit event
        emit CurrencyTrade(inputCurrencyCode, outputCurrencyCode, inputAmount, inputFilledAmountUsd, outputAmount, outputFilledAmountUsd, CurrencyExchange.mStable);
    }

    /**
     * @dev Claims mStable MTA rewards (if `all` is set, unlocks and claims locked rewards).
     * @param all If locked rewards should be unlocked and claimed.
     * @param first Index of the first array element to claim. Only applicable if `all` is true. Feed in the second value returned by the savings vault's `unclaimedRewards(address _account)` function.
     * @param last Index of the last array element to claim. Only applicable if `all` is true. Feed in the third value returned by the savings vault's `unclaimedRewards(address _account)` function.
     */
    function claimMStableRewards(bool all, uint256 first, uint256 last) external fundEnabled onlyRebalancer {
        MStablePoolController.claimRewards(all, first, last);
    }

    /**
     * @notice Fuse cToken contract addresses approved for deposits by the rebalancer.
     */
    mapping(uint8 => mapping(string => address)) public fuseAssets;

    /**
     * @dev Adds `cTokens` to `fuseAssets` (indexed by `pools` and `currencyCodes`).
     * @param pools The pool indexes.
     * @param currencyCodes The corresponding currency codes for `_fuseAssets`.
     * @param cTokens The Fuse cToken contract addresses.
     */
    function addFuseAssets(uint8[] calldata pools, string[][] calldata currencyCodes, address[][] calldata cTokens) external onlyOwner {
        require(pools.length > 0 && pools.length == currencyCodes.length && pools.length == cTokens.length, "Array parameter lengths must all be equal and greater than 0.");

        for (uint256 i = 0; i < pools.length; i++) {
            uint8 pool = pools[i];
            require(pool >= 100, "Pool index too low.");
            require(currencyCodes[i].length > 0 && currencyCodes[i].length == cTokens[i].length, "Nested array parameter lengths must all be equal and greater than 0.");

            for (uint256 j = 0; j < currencyCodes[i].length; j++) {
                address cToken = cTokens[i][j];
                string memory currencyCode = currencyCodes[i][j];
                require(fuseAssets[pool][currencyCode] == address(0), "cToken address already set for this currency code.");
                require(CErc20(cToken).underlying() == _erc20Contracts[currencyCode], "Underlying ERC20 token mismatch.");
                fuseAssets[pool][currencyCode] = cToken;
                _poolsByCurrency[currencyCode].push(pool);
            }
        }
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/drafts/SignedSafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "@0x/contracts-exchange-libs/contracts/src/LibOrder.sol";

import "./RariFundController.sol";
import "./RariFundToken.sol";
import "./RariFundPriceConsumer.sol";
import "./interfaces/IRariGovernanceTokenDistributor.sol";

/**
 * @title RariFundManager
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice This contract is the primary contract powering the Rari Stable Pool.
 * Anyone can deposit to the fund with deposit(string currencyCode, uint256 amount).
 * Anyone can withdraw their funds (with interest) from the fund with withdraw(string currencyCode, uint256 amount).
 */
contract RariFundManager is Initializable, Ownable {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeERC20 for IERC20;

    /**
     * @dev Boolean that, if true, disables the primary functionality of this RariFundManager.
     */
    bool public fundDisabled;

    /**
     * @dev Address of the RariFundController.
     */
    address payable private _rariFundControllerContract;

    /**
     * @dev Contract of the RariFundController.
     */
    RariFundController public rariFundController;

    /**
     * @dev Address of the RariFundToken.
     */
    address private _rariFundTokenContract;

    /**
     * @dev Contract of the RariFundToken.
     */
    RariFundToken public rariFundToken;

    /**
     * @dev Contract of the RariFundPriceConsumer.
     */
    RariFundPriceConsumer public rariFundPriceConsumer;

    /**
     * @dev Address of the RariFundProxy.
     */
    address private _rariFundProxyContract;

    /**
     * @dev Address of the rebalancer.
     */
    address private _rariFundRebalancerAddress;

    /**
     * @dev Array of currencies supported by the fund.
     */
    string[] private _supportedCurrencies;

    /**
     * @dev Maps `_supportedCurrencies` items to their indexes.
     */
    mapping(string => uint8) private _currencyIndexes;

    /**
     * @dev Maps supported currency codes to their decimal precisions (number of digits after the decimal point).
     */
    mapping(string => uint256) private _currencyDecimals;

    /**
     * @dev Maps supported currency codes to ERC20 token contract addresses.
     */
    mapping(string => address) private _erc20Contracts;

    /**
     * @dev UNUSED AFTER UPGRADE: Maps currency codes to arrays of supported pools.
     */
    mapping(string => RariFundController.LiquidityPool[]) private _poolsByCurrency;

    /**
     * @dev Initializer that sets supported ERC20 contract addresses and supported pools for each supported token.
     */
    function initialize() public initializer {
        // Initialize base contracts
        Ownable.initialize(msg.sender);
        
        // Add supported currencies
        addSupportedCurrency("DAI", 0x6B175474E89094C44Da98b954EedeAC495271d0F, 18);
        addSupportedCurrency("USDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 6);
        addSupportedCurrency("USDT", 0xdAC17F958D2ee523a2206206994597C13D831ec7, 6);
        addSupportedCurrency("TUSD", 0x0000000000085d4780B73119b644AE5ecd22b376, 18);
        addSupportedCurrency("BUSD", 0x4Fabb145d64652a948d72533023f6E7A623C7C53, 18);
        addSupportedCurrency("sUSD", 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51, 18);
        addSupportedCurrency("mUSD", 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5, 18);

        // Initialize raw fund balance cache (can't set initial values in field declarations with proxy storage)
        _rawFundBalanceCache = -1;
    }

    /**
     * @dev Marks a token as supported by the fund and stores its decimal precision and ERC20 contract address.
     * @param currencyCode The currency code of the token.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param decimals The decimal precision (number of digits after the decimal point) of the token.
     */
    function addSupportedCurrency(string memory currencyCode, address erc20Contract, uint256 decimals) internal {
        _currencyIndexes[currencyCode] = uint8(_supportedCurrencies.length);
        _supportedCurrencies.push(currencyCode);
        _erc20Contracts[currencyCode] = erc20Contract;
        _currencyDecimals[currencyCode] = decimals;
    }

    /**
     * @dev Emitted when RariFundManager is upgraded.
     */
    event FundManagerUpgraded(address newContract);

    /**
     * @dev Upgrades RariFundManager.
     * Sends data to the new contract and sets the new RariFundToken minter.
     * @param newContract The address of the new RariFundManager contract.
     */
    function upgradeFundManager(address newContract) external onlyOwner {
        require(fundDisabled, "This fund manager contract must be disabled before it can be upgraded.");

        // Pass data to the new contract
        FundManagerData memory data;

        data = FundManagerData(
            _netDeposits,
            _rawInterestAccruedAtLastFeeRateChange,
            _interestFeesGeneratedAtLastFeeRateChange,
            _interestFeesClaimed
        );

        RariFundManager(newContract).setFundManagerData(data);

        // Update RariFundToken minter
        if (_rariFundTokenContract != address(0)) {
            rariFundToken.addMinter(newContract);
            rariFundToken.renounceMinter();
        }

        emit FundManagerUpgraded(newContract);
    }

    /**
     * @dev Old RariFundManager contract authorized to migrate its data to the new one.
     */
    address private _authorizedFundManagerDataSource;

    /**
     * @dev Upgrades RariFundManager.
     * Authorizes the source for fund manager data (i.e., the old fund manager).
     * @param authorizedFundManagerDataSource Authorized source for data (i.e., the old fund manager).
     */
    function authorizeFundManagerDataSource(address authorizedFundManagerDataSource) external onlyOwner {
        _authorizedFundManagerDataSource = authorizedFundManagerDataSource;
    }

    /**
     * @dev Struct for data to transfer from the old RariFundManager to the new one.
     */
    struct FundManagerData {
        int256 netDeposits;
        int256 rawInterestAccruedAtLastFeeRateChange;
        int256 interestFeesGeneratedAtLastFeeRateChange;
        uint256 interestFeesClaimed;
    }

    /**
     * @dev Upgrades RariFundManager.
     * Sets data receieved from the old contract.
     * @param data The data from the old contract necessary to initialize the new contract.
     */
    function setFundManagerData(FundManagerData calldata data) external {
        require(_authorizedFundManagerDataSource != address(0) && msg.sender == _authorizedFundManagerDataSource, "Caller is not an authorized source.");
        _netDeposits = data.netDeposits;
        _rawInterestAccruedAtLastFeeRateChange = data.rawInterestAccruedAtLastFeeRateChange;
        _interestFeesGeneratedAtLastFeeRateChange = data.interestFeesGeneratedAtLastFeeRateChange;
        _interestFeesClaimed = data.interestFeesClaimed;
        _interestFeeRate = RariFundManager(_authorizedFundManagerDataSource).getInterestFeeRate();
        _withdrawalFeeRate = RariFundManager(_authorizedFundManagerDataSource).getWithdrawalFeeRate();
    }

    /**
     * @dev Emitted when the RariFundController of the RariFundManager is set or upgraded.
     */
    event FundControllerSet(address newContract);

    /**
     * @dev Sets or upgrades the RariFundController of the RariFundManager.
     * @param newContract The address of the new RariFundController contract.
     */
    function setFundController(address payable newContract) external onlyOwner {
        _rariFundControllerContract = newContract;
        rariFundController = RariFundController(_rariFundControllerContract);
        emit FundControllerSet(newContract);
    }

    /**
     * @dev Forwards tokens lost in the fund manager (in case of accidental transfer of funds to this contract).
     * @param erc20Contract The ERC20 contract address of the token to forward.
     * @param to The destination address to which the funds will be forwarded.
     * @return Boolean indicating success.
     */
    function forwardLostFunds(address erc20Contract, address to) external onlyOwner returns (bool) {
        IERC20 token = IERC20(erc20Contract);
        uint256 balance = token.balanceOf(address(this));
        if (balance <= 0) return false;
        token.safeTransfer(to, balance);
        return true;
    }

    /**
     * @dev Emitted when the RariFundToken of the RariFundManager is set.
     */
    event FundTokenSet(address newContract);

    /**
     * @dev Sets or upgrades the RariFundToken of the RariFundManager.
     * @param newContract The address of the new RariFundToken contract.
     */
    function setFundToken(address newContract) external onlyOwner {
        _rariFundTokenContract = newContract;
        rariFundToken = RariFundToken(_rariFundTokenContract);
        emit FundTokenSet(newContract);
    }

    /**
     * @dev Emitted when the RariFundProxy of the RariFundManager is set.
     */
    event FundProxySet(address newContract);

    /**
     * @dev Sets or upgrades the RariFundProxy of the RariFundManager.
     * @param newContract The address of the new RariFundProxy contract.
     */
    function setFundProxy(address newContract) external onlyOwner {
        _rariFundProxyContract = newContract;
        emit FundProxySet(newContract);
    }

    /**
     * @dev Throws if called by any account other than the RariFundProxy.
     */
    modifier onlyProxy() {
        require(_rariFundProxyContract == msg.sender, "Caller is not the RariFundProxy.");
        _;
    }

    /**
     * @dev Emitted when the rebalancer of the RariFundManager is set.
     */
    event FundRebalancerSet(address newAddress);

    /**
     * @dev Sets or upgrades the rebalancer of the RariFundManager.
     * @param newAddress The Ethereum address of the new rebalancer server.
     */
    function setFundRebalancer(address newAddress) external onlyOwner {
        _rariFundRebalancerAddress = newAddress;
        emit FundRebalancerSet(newAddress);
    }

    /**
     * @dev Throws if called by any account other than the rebalancer.
     */
    modifier onlyRebalancer() {
        require(_rariFundRebalancerAddress == msg.sender, "Caller is not the rebalancer.");
        _;
    }

    /**
     * @dev Emitted when the RariFundPriceConsumer of the RariFundManager is set.
     */
    event FundPriceConsumerSet(address newContract);

    /**
     * @dev Sets or upgrades the RariFundPriceConsumer of the RariFundManager.
     * @param newContract The address of the new RariFundPriceConsumer contract.
     */
    function setFundPriceConsumer(address newContract) external onlyOwner {
        rariFundPriceConsumer = RariFundPriceConsumer(newContract);
        emit FundPriceConsumerSet(newContract);
    }

    /**
     * @dev Emitted when the primary functionality of this RariFundManager contract has been disabled.
     */
    event FundDisabled();

    /**
     * @dev Emitted when the primary functionality of this RariFundManager contract has been enabled.
     */
    event FundEnabled();

    /**
     * @dev Disables/enables primary functionality of this RariFundManager so contract(s) can be upgraded.
     */
    function setFundDisabled(bool disabled) external onlyOwner {
        require(disabled != fundDisabled, "No change to fund enabled/disabled status.");
        fundDisabled = disabled;
        if (disabled) emit FundDisabled(); else emit FundEnabled();
    }

    /**
     * @dev Throws if fund is disabled.
     */
    modifier fundEnabled() {
        require(!fundDisabled, "This fund manager contract is disabled. This may be due to an upgrade.");
        _;
    }

    /**
     * @dev Boolean indicating if return values of `getPoolBalance` are to be cached.
     */
    bool _cachePoolBalances;

    /**
     * @dev Boolean indicating if dYdX balances returned by `getPoolBalance` are to be cached.
     */
    bool _cacheDydxBalances;

    /**
     * @dev Maps to currency codes to cached pool balances to pool indexes.
     */
    mapping(string => mapping(uint8 => uint256)) _poolBalanceCache;

    /**
     * @dev Cached array of dYdX token addresses.
     */
    address[] private _dydxTokenAddressesCache;

    /**
     * @dev Cached array of dYdX balances.
     */
    uint256[] private _dydxBalancesCache;

    /**
     * @dev Returns the fund controller's balance of the specified currency in the specified pool.
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `CompoundPoolController.getBalance`) potentially modifies the state.
     * @param pool The index of the pool.
     * @param currencyCode The currency code of the token.
     */
    function getPoolBalance(uint8 pool, string memory currencyCode) internal returns (uint256) {
        if (!rariFundController.hasCurrencyInPool(pool, currencyCode)) return 0;

        if (_cachePoolBalances || _cacheDydxBalances) {
            if (pool == uint8(RariFundController.LiquidityPool.dYdX)) {
                address erc20Contract = _erc20Contracts[currencyCode];
                require(erc20Contract != address(0), "Invalid currency code.");
                if (_dydxBalancesCache.length == 0) (_dydxTokenAddressesCache, _dydxBalancesCache) = rariFundController.getDydxBalances();
                for (uint256 i = 0; i < _dydxBalancesCache.length; i++) if (_dydxTokenAddressesCache[i] == erc20Contract) return _dydxBalancesCache[i];
                revert("Failed to get dYdX balance of this currency code.");
            } else if (_cachePoolBalances) {
                if (_poolBalanceCache[currencyCode][pool] == 0) _poolBalanceCache[currencyCode][pool] = rariFundController._getPoolBalance(pool, currencyCode);
                return _poolBalanceCache[currencyCode][pool];
            }
        }

        return rariFundController._getPoolBalance(pool, currencyCode);
    }

    /**
     * @dev Caches dYdX pool balances returned by `getPoolBalance` for the duration of the function.
     */
    modifier cacheDydxBalances() {
        bool cacheSetPreviously = _cacheDydxBalances;
        _cacheDydxBalances = true;
        _;

        if (!cacheSetPreviously) {
            _cacheDydxBalances = false;
            if (!_cachePoolBalances) _dydxBalancesCache.length = 0;
        }
    }

    /**
     * @dev Caches return values of `getPoolBalance` for the duration of the function.
     */
    modifier cachePoolBalances() {
        bool cacheSetPreviously = _cachePoolBalances;
        _cachePoolBalances = true;
        _;

        if (!cacheSetPreviously) {
            _cachePoolBalances = false;
            if (!_cacheDydxBalances) _dydxBalancesCache.length = 0;

            for (uint256 i = 0; i < _supportedCurrencies.length; i++) {
                string memory currencyCode = _supportedCurrencies[i];
                uint8[] memory poolsByCurrency = rariFundController.getPoolsByCurrency(currencyCode);
                for (uint256 j = 0; j < poolsByCurrency.length; j++) _poolBalanceCache[currencyCode][uint8(poolsByCurrency[j])] = 0;
            }
        }
    }

    /**
     * @notice Returns the fund's raw total balance (all RFT holders' funds + all unclaimed fees) of the specified currency.
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `RariFundController.getPoolBalance`) potentially modifies the state.
     * @param currencyCode The currency code of the balance to be calculated.
     */
    function getRawFundBalance(string memory currencyCode) public returns (uint256) {
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");

        IERC20 token = IERC20(erc20Contract);
        uint256 totalBalance = token.balanceOf(_rariFundControllerContract);
        uint8[] memory poolsByCurrency = rariFundController.getPoolsByCurrency(currencyCode);
        for (uint256 i = 0; i < poolsByCurrency.length; i++)
            totalBalance = totalBalance.add(getPoolBalance(poolsByCurrency[i], currencyCode));

        return totalBalance;
    }

    /**
     * @dev Caches the fund's raw total balance (all RFT holders' funds + all unclaimed fees) of all currencies in USD (scaled by 1e18).
     */
    int256 private _rawFundBalanceCache;

    /**
     * @notice Returns the fund's raw total balance (all RFT holders' funds + all unclaimed fees) of all currencies in USD (scaled by 1e18).
     * Returns `_rawFundBalanceCache` if set to save gas.
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getRawFundBalance() public returns (uint256) {
        if (_rawFundBalanceCache >= 0) return uint256(_rawFundBalanceCache);
        uint256[] memory pricesInUsd = rariFundPriceConsumer.getCurrencyPricesInUsd();
        return getRawFundBalance(pricesInUsd);
    }

    /**
     * @dev Returns the fund's raw total balance (all RFT holders' funds + all unclaimed fees) of all currencies in USD (scaled by 1e18).
     * Accepts prices in USD as a parameter to avoid calculating them every time.
     * Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getRawFundBalance(uint256[] memory pricesInUsd) public cacheDydxBalances returns (uint256) {
        uint256 totalBalance = 0;

        for (uint256 i = 0; i < _supportedCurrencies.length; i++) {
            string memory currencyCode = _supportedCurrencies[i];
            uint256 balance = getRawFundBalance(currencyCode);
            uint256 balanceUsd = balance.mul(pricesInUsd[i]).div(10 ** _currencyDecimals[currencyCode]);
            totalBalance = totalBalance.add(balanceUsd);
        }

        return totalBalance;
    }

    /**
     * @dev Caches the value of `getRawFundBalance()` for the duration of the function.
     */
    modifier cacheRawFundBalance() {
        bool cacheSetPreviously = _rawFundBalanceCache >= 0;
        if (!cacheSetPreviously) _rawFundBalanceCache = toInt256(getRawFundBalance());
        _;
        if (!cacheSetPreviously) _rawFundBalanceCache = -1;
    }

    /**
     * @notice Returns the fund's total investor balance (all RFT holders' funds but not unclaimed fees) of all currencies in USD (scaled by 1e18).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getFundBalance() public cacheRawFundBalance returns (uint256) {
        return getRawFundBalance().sub(getInterestFeesUnclaimed());
    }

    /**
     * @notice Returns the total balance in USD (scaled by 1e18) of `account`.
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     * @param account The account whose balance we are calculating.
     */
    function balanceOf(address account) external returns (uint256) {
        uint256 rftTotalSupply = rariFundToken.totalSupply();
        if (rftTotalSupply == 0) return 0;
        uint256 rftBalance = rariFundToken.balanceOf(account);
        uint256 fundBalanceUsd = getFundBalance();
        uint256 accountBalanceUsd = rftBalance.mul(fundBalanceUsd).div(rftTotalSupply);
        return accountBalanceUsd;
    }

    /**
     * @dev UNUSED AFTER UPGRADE: Fund balance limit in USD per Ethereum address.
     */
    uint256 private _accountBalanceLimitDefault;

    /**
     * @dev UNUSED AFTER UPGRADE: Maps user accounts to individual account balance limits (where 0 indicates the default while any negative value indicates 0).
     */
    mapping(address => int256) private _accountBalanceLimits;

    /**
     * @dev Maps currency codes to booleans indicating if they are accepted for deposits.
     */
    mapping(string => bool) private _acceptedCurrencies;

    /**
     * @notice Returns a boolean indicating if deposits in `currencyCode` are currently accepted.
     * @param currencyCode The currency code to check.
     */
    function isCurrencyAccepted(string memory currencyCode) public view returns (bool) {
        return _acceptedCurrencies[currencyCode];
    }

    /**
     * @dev UNUSED AFTER UPGRADE: Array of accepted currencies (only used by `getAcceptedCurrencies`).
     */
    string[] private _acceptedCurrenciesArray;

    /**
     * @notice Returns an array of currency codes currently accepted for deposits.
     */
    function getAcceptedCurrencies() external view returns (string[] memory) {
        uint256 arrayLength = 0;
        for (uint256 i = 0; i < _supportedCurrencies.length; i++) if (_acceptedCurrencies[_supportedCurrencies[i]]) arrayLength++;
        string[] memory acceptedCurrencies = new string[](arrayLength);
        uint256 index = 0;

        for (uint256 i = 0; i < _supportedCurrencies.length; i++) if (_acceptedCurrencies[_supportedCurrencies[i]]) {
            acceptedCurrencies[index] = _supportedCurrencies[i];
            index++;
        }

        return acceptedCurrencies;
    }

    /**
     * @dev Marks `currencyCodes` as accepted or not accepted.
     * @param currencyCodes The currency codes to mark as accepted or not accepted.
     * @param accepted An array of booleans indicating if each of `currencyCodes` is to be accepted.
     */
    function setAcceptedCurrencies(string[] calldata currencyCodes, bool[] calldata accepted) external onlyRebalancer {
        require (currencyCodes.length > 0 && currencyCodes.length == accepted.length, "Lengths of arrays must be equal and both greater than 0.");
        for (uint256 i = 0; i < currencyCodes.length; i++) _acceptedCurrencies[currencyCodes[i]] = accepted[i];
    }

    /**
     * @dev Emitted when funds have been deposited to RariFund.
     */
    event Deposit(string indexed currencyCode, address indexed sender, address indexed payee, uint256 amount, uint256 amountUsd, uint256 rftMinted);

    /**
     * @dev Emitted when funds have been withdrawn from RariFund.
     */
    event Withdrawal(string indexed currencyCode, address indexed sender, address indexed payee, uint256 amount, uint256 amountUsd, uint256 rftBurned, uint256 withdrawalFeeRate);

    /**
     * @notice Deposits funds from `msg.sender` to the Rari Stable Pool in exchange for RFT minted to `to`.
     * You may only deposit currencies accepted by the fund (see `isCurrencyAccepted(string currencyCode)`).
     * Please note that you must approve RariFundManager to transfer at least `amount`.
     * @param to The address that will receieve the minted RFT.
     * @param currencyCode The currency code of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function depositTo(address to, string memory currencyCode, uint256 amount) public fundEnabled {
        // Input validation
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        require(isCurrencyAccepted(currencyCode), "This currency is not currently accepted; please convert your funds to an accepted currency before depositing.");
        require(amount > 0, "Deposit amount must be greater than 0.");

        // Get currency prices
        uint256[] memory pricesInUsd = rariFundPriceConsumer.getCurrencyPricesInUsd();

        // Manually cache raw fund balance
        bool cacheSetPreviously = _rawFundBalanceCache >= 0;
        if (!cacheSetPreviously) _rawFundBalanceCache = toInt256(getRawFundBalance(pricesInUsd));

        // Get deposit amount in USD
        uint256 amountUsd = amount.mul(pricesInUsd[_currencyIndexes[currencyCode]]).div(10 ** _currencyDecimals[currencyCode]);

        // Calculate RFT to mint
        uint256 rftTotalSupply = rariFundToken.totalSupply();
        uint256 fundBalanceUsd = rftTotalSupply > 0 ? getFundBalance() : 0; // Only set if used
        uint256 rftAmount = 0;
        if (rftTotalSupply > 0 && fundBalanceUsd > 0) rftAmount = amountUsd.mul(rftTotalSupply).div(fundBalanceUsd);
        else rftAmount = amountUsd;
        require(rftAmount > 0, "Deposit amount is so small that no RFT would be minted.");

        // Update net deposits, transfer funds from msg.sender, mint RFT, and emit event
        _netDeposits = _netDeposits.add(int256(amountUsd));
        IERC20(erc20Contract).safeTransferFrom(msg.sender, _rariFundControllerContract, amount); // The user must approve the transfer of tokens beforehand
        require(rariFundToken.mint(to, rftAmount), "Failed to mint output tokens.");
        emit Deposit(currencyCode, msg.sender, to, amount, amountUsd, rftAmount);

        // Update _rawFundBalanceCache
        _rawFundBalanceCache = _rawFundBalanceCache.add(int256(amountUsd));

        // Update RGT distribution speeds
        IRariGovernanceTokenDistributor rariGovernanceTokenDistributor = rariFundToken.rariGovernanceTokenDistributor();
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number < rariGovernanceTokenDistributor.distributionEndBlock()) rariGovernanceTokenDistributor.refreshDistributionSpeeds(IRariGovernanceTokenDistributor.RariPool.Stable, getFundBalance());

        // Clear _rawFundBalanceCache
        if (!cacheSetPreviously) _rawFundBalanceCache = -1;
    }

    /**
     * @notice Deposits funds to the Rari Stable Pool in exchange for RFT.
     * You may only deposit currencies accepted by the fund (see `isCurrencyAccepted(string currencyCode)`).
     * Please note that you must approve RariFundManager to transfer at least `amount`.
     * @param currencyCode The currency code of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(string calldata currencyCode, uint256 amount) external {
        depositTo(msg.sender, currencyCode, amount);
    }

    /**
     * @dev Returns the amount of RFT to burn for a withdrawal (used by `_withdrawFrom`).
     * @param from The address from which RFT will be burned.
     * @param amountUsd The amount of the withdrawal in USD
     */
    function getRftBurnAmount(address from, uint256 amountUsd) internal returns (uint256) {
        uint256 rftTotalSupply = rariFundToken.totalSupply();
        uint256 fundBalanceUsd = getFundBalance();
        require(fundBalanceUsd > 0, "Fund balance is zero.");
        uint256 rftAmount = amountUsd.mul(rftTotalSupply).div(fundBalanceUsd);
        require(rftAmount <= rariFundToken.balanceOf(from), "Your RFT balance is too low for a withdrawal of this amount.");
        require(rftAmount > 0, "Withdrawal amount is so small that no RFT would be burned.");
        return rftAmount;
    }

    /**
     * @dev Internal function to withdraw funds from pools if necessary for `RariFundController` to hold at least `amount` of actual tokens.
     * This function was separated from `_withdrawFrom` to avoid the stack going too deep.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The minimum amount of tokens that must be held by `RariFundController` after withdrawing.
     */
    function withdrawFromPoolsIfNecessary(string memory currencyCode, uint256 amount) internal {
        // Check contract balance of token
        address erc20Contract = _erc20Contracts[currencyCode];
        uint256 contractBalance = IERC20(erc20Contract).balanceOf(_rariFundControllerContract);

        // Withdraw from pools if necessary
        uint8[] memory poolsByCurrency = rariFundController.getPoolsByCurrency(currencyCode);

        for (uint256 i = 0; i < poolsByCurrency.length; i++) {
            if (contractBalance >= amount) break;
            uint8 pool = poolsByCurrency[i];
            uint256 poolBalance = getPoolBalance(pool, currencyCode);
            if (poolBalance <= 0) continue;
            uint256 amountLeft = amount.sub(contractBalance);
            bool withdrawAll = amountLeft >= poolBalance;
            uint256 poolAmount = withdrawAll ? poolBalance : amountLeft;
            rariFundController.withdrawFromPoolOptimized(pool, currencyCode, poolAmount, withdrawAll);

            if (pool == uint8(RariFundController.LiquidityPool.dYdX)) {
                for (uint256 j = 0; j < _dydxBalancesCache.length; j++) if (_dydxTokenAddressesCache[j] == erc20Contract) _dydxBalancesCache[j] = poolBalance.sub(poolAmount);
            } else _poolBalanceCache[currencyCode][pool] = poolBalance.sub(poolAmount);

            contractBalance = contractBalance.add(poolAmount);
        }

        // Final check of amount <= contractBalance
        require(amount <= contractBalance, "Available balance not enough to cover amount even after withdrawing from pools.");
    }

    /**
     * @dev Internal function to withdraw funds from the Rari Stable Pool to `msg.sender` in exchange for RFT burned from `from`.
     * You may only withdraw currencies held by the fund (see `getRawFundBalance(string currencyCode)`).
     * Please note that you must approve RariFundManager to burn of the necessary amount of RFT.
     * @param from The address from which RFT will be burned.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     * @return The amount withdrawn after the fee.
     */
    function _withdrawFrom(address from, string memory currencyCode, uint256 amount, uint256[] memory pricesInUsd) internal fundEnabled cachePoolBalances returns (uint256) {
        // Input validation
        address erc20Contract = _erc20Contracts[currencyCode];
        require(erc20Contract != address(0), "Invalid currency code.");
        require(amount > 0, "Withdrawal amount must be greater than 0.");

        // Withdraw from pools if necessary
        withdrawFromPoolsIfNecessary(currencyCode, amount);

        // Manually cache raw fund balance
        bool cacheSetPreviously = _rawFundBalanceCache >= 0;
        if (!cacheSetPreviously) _rawFundBalanceCache = toInt256(getRawFundBalance(pricesInUsd));

        // Calculate withdrawal fee and amount after fee
        uint256 feeAmount = amount.mul(_withdrawalFeeRate).div(1e18);
        uint256 amountAfterFee = amount.sub(feeAmount);

        // Get withdrawal amount in USD
        uint256 amountUsd = amount.mul(pricesInUsd[_currencyIndexes[currencyCode]]).div(10 ** _currencyDecimals[currencyCode]);

        // Calculate RFT to burn
        uint256 rftAmount = getRftBurnAmount(from, amountUsd);

        // Update net deposits, burn RFT, transfer funds to msg.sender, transfer fee to _withdrawalFeeMasterBeneficiary, and emit event
        _netDeposits = _netDeposits.sub(int256(amountUsd));
        rariFundToken.fundManagerBurnFrom(from, rftAmount); // The user must approve the burning of tokens beforehand
        IERC20 token = IERC20(erc20Contract);
        token.safeTransferFrom(_rariFundControllerContract, msg.sender, amountAfterFee);
        token.safeTransferFrom(_rariFundControllerContract, _withdrawalFeeMasterBeneficiary, feeAmount);
        emit Withdrawal(currencyCode, from, msg.sender, amount, amountUsd, rftAmount, _withdrawalFeeRate);

        // Update _rawFundBalanceCache
        _rawFundBalanceCache = _rawFundBalanceCache.sub(int256(amountUsd));

        // Update RGT distribution speeds
        IRariGovernanceTokenDistributor rariGovernanceTokenDistributor = rariFundToken.rariGovernanceTokenDistributor();
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number < rariGovernanceTokenDistributor.distributionEndBlock()) rariGovernanceTokenDistributor.refreshDistributionSpeeds(IRariGovernanceTokenDistributor.RariPool.Stable, getFundBalance());

        // Clear _rawFundBalanceCache
        if (!cacheSetPreviously) _rawFundBalanceCache = -1;

        // Return amount after fee
        return amountAfterFee;
    }

    /**
     * @notice Withdraws funds from the Rari Stable Pool in exchange for RFT.
     * You may only withdraw currencies held by the fund (see `getRawFundBalance(string currencyCode)`).
     * Please note that you must approve RariFundManager to burn of the necessary amount of RFT.
     * @param currencyCode The currency code of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     * @return The amount withdrawn after the fee.
     */
    function withdraw(string calldata currencyCode, uint256 amount) external returns (uint256) {
        return _withdrawFrom(msg.sender, currencyCode, amount, rariFundPriceConsumer.getCurrencyPricesInUsd());
    }

    /**
     * @dev Withdraws multiple currencies from the Rari Stable Pool to `msg.sender` (RariFundProxy) in exchange for RFT burned from `from`.
     * You may only withdraw currencies held by the fund (see `getRawFundBalance(string currencyCode)`).
     * Please note that you must approve RariFundManager to burn of the necessary amount of RFT.
     * @param from The address from which RFT will be burned.
     * @param currencyCodes The currency codes of the tokens to be withdrawn.
     * @param amounts The amounts of the tokens to be withdrawn.
     * @return Array of amounts withdrawn after fees.
     */
    function withdrawFrom(address from, string[] calldata currencyCodes, uint256[] calldata amounts) external onlyProxy cachePoolBalances returns (uint256[] memory) {
        // Input validation
        require(currencyCodes.length > 0 && currencyCodes.length == amounts.length, "Lengths of currency code and amount arrays must be greater than 0 and equal.");
        uint256[] memory pricesInUsd = rariFundPriceConsumer.getCurrencyPricesInUsd();

        // Manually cache raw fund balance (no need to check if set previously because the function is external)
        _rawFundBalanceCache = toInt256(getRawFundBalance(pricesInUsd));

        // Make withdrawals
        uint256[] memory amountsAfterFees = new uint256[](currencyCodes.length);
        for (uint256 i = 0; i < currencyCodes.length; i++) amountsAfterFees[i] = _withdrawFrom(from, currencyCodes[i], amounts[i], pricesInUsd);

        // Reset _rawFundBalanceCache
        _rawFundBalanceCache = -1;

        // Return amounts withdrawn after fees
        return amountsAfterFees;
    }

    /**
     * @dev Net quantity of deposits to the fund (i.e., deposits - withdrawals).
     * On deposit, amount deposited is added to `_netDeposits`; on withdrawal, amount withdrawn is subtracted from `_netDeposits`.
     */
    int256 private _netDeposits;

    /**
     * @notice Returns the raw total amount of interest accrued by the fund as a whole (including the fees paid on interest) in USD (scaled by 1e18).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getRawInterestAccrued() public returns (int256) {
        return toInt256(getRawFundBalance()).sub(_netDeposits).add(toInt256(_interestFeesClaimed));
    }

    /**
     * @notice Returns the total amount of interest accrued by past and current RFT holders (excluding the fees paid on interest) in USD (scaled by 1e18).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getInterestAccrued() public returns (int256) {
        return toInt256(getFundBalance()).sub(_netDeposits);
    }

    /**
     * @dev The proportion of interest accrued that is taken as a service fee (scaled by 1e18).
     */
    uint256 private _interestFeeRate;

    /**
     * @dev Returns the fee rate on interest (proportion of raw interest accrued scaled by 1e18).
     */
    function getInterestFeeRate() public view returns (uint256) {
        return _interestFeeRate;
    }

    /**
     * @dev Sets the fee rate on interest.
     * @param rate The proportion of interest accrued to be taken as a service fee (scaled by 1e18).
     */
    function setInterestFeeRate(uint256 rate) external fundEnabled onlyOwner cacheRawFundBalance {
        require(rate != _interestFeeRate, "This is already the current interest fee rate.");
        require(rate <= 1e18, "The interest fee rate cannot be greater than 100%.");
        _depositFees();
        _interestFeesGeneratedAtLastFeeRateChange = getInterestFeesGenerated(); // MUST update this first before updating _rawInterestAccruedAtLastFeeRateChange since it depends on it 
        _rawInterestAccruedAtLastFeeRateChange = getRawInterestAccrued();
        _interestFeeRate = rate;
    }

    /**
     * @dev The amount of interest accrued at the time of the most recent change to the fee rate.
     */
    int256 private _rawInterestAccruedAtLastFeeRateChange;

    /**
     * @dev The amount of fees generated on interest at the time of the most recent change to the fee rate.
     */
    int256 private _interestFeesGeneratedAtLastFeeRateChange;

    /**
     * @notice Returns the amount of interest fees accrued by beneficiaries in USD (scaled by 1e18).
     * @dev Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getInterestFeesGenerated() public returns (int256) {
        int256 rawInterestAccruedSinceLastFeeRateChange = getRawInterestAccrued().sub(_rawInterestAccruedAtLastFeeRateChange);
        int256 interestFeesGeneratedSinceLastFeeRateChange = rawInterestAccruedSinceLastFeeRateChange.mul(int256(_interestFeeRate)).div(1e18);
        int256 interestFeesGenerated = _interestFeesGeneratedAtLastFeeRateChange.add(interestFeesGeneratedSinceLastFeeRateChange);
        return interestFeesGenerated;
    }

    /**
     * @dev The total claimed amount of interest fees.
     */
    uint256 private _interestFeesClaimed;

    /**
     * @dev Returns the total unclaimed amount of interest fees.
     * Ideally, we can add the `view` modifier, but Compound's `getUnderlyingBalance` function (called by `getRawFundBalance`) potentially modifies the state.
     */
    function getInterestFeesUnclaimed() public returns (uint256) {
        int256 interestFeesUnclaimed = getInterestFeesGenerated().sub(toInt256(_interestFeesClaimed));
        return interestFeesUnclaimed > 0 ? uint256(interestFeesUnclaimed) : 0;
    }

    /**
     * @dev The master beneficiary of fees on interest; i.e., the recipient of all fees on interest.
     */
    address private _interestFeeMasterBeneficiary;

    /**
     * @dev Sets the master beneficiary of interest fees.
     * @param beneficiary The master beneficiary of fees on interest; i.e., the recipient of all fees on interest.
     */
    function setInterestFeeMasterBeneficiary(address beneficiary) external fundEnabled onlyOwner {
        require(beneficiary != address(0), "Master beneficiary cannot be the zero address.");
        _interestFeeMasterBeneficiary = beneficiary;
    }

    /**
     * @dev Emitted when fees on interest are deposited back into the fund.
     */
    event InterestFeeDeposit(address beneficiary, uint256 amountUsd);

    /**
     * @dev Internal function to deposit all accrued fees on interest back into the fund on behalf of the master beneficiary.
     * @return Integer indicating success (0), no fees to claim (1), or no RFT to mint (2).
     */
    function _depositFees() internal fundEnabled cacheRawFundBalance returns (uint8) {
        // Input validation
        require(_interestFeeMasterBeneficiary != address(0), "Master beneficiary cannot be the zero address.");

        // Get and validate unclaimed interest fees
        uint256 amountUsd = getInterestFeesUnclaimed();
        if (amountUsd <= 0) return 1;

        // Calculate RFT amount to mint and validate
        uint256 rftTotalSupply = rariFundToken.totalSupply();
        uint256 rftAmount = 0;

        if (rftTotalSupply > 0) {
            uint256 fundBalanceUsd = getFundBalance();
            if (fundBalanceUsd > 0) rftAmount = amountUsd.mul(rftTotalSupply).div(fundBalanceUsd);
            else rftAmount = amountUsd;
        } else rftAmount = amountUsd;

        if (rftAmount <= 0) return 2;

        // Update claimed interest fees and net deposits, mint RFT, emit events, and return no error
        _interestFeesClaimed = _interestFeesClaimed.add(amountUsd);
        _netDeposits = _netDeposits.add(int256(amountUsd));
        require(rariFundToken.mint(_interestFeeMasterBeneficiary, rftAmount), "Failed to mint output tokens.");
        emit Deposit("USD", _interestFeeMasterBeneficiary, _interestFeeMasterBeneficiary, amountUsd, amountUsd, rftAmount);
        emit InterestFeeDeposit(_interestFeeMasterBeneficiary, amountUsd);

        // Update RGT distribution speeds
        IRariGovernanceTokenDistributor rariGovernanceTokenDistributor = rariFundToken.rariGovernanceTokenDistributor();
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number < rariGovernanceTokenDistributor.distributionEndBlock()) rariGovernanceTokenDistributor.refreshDistributionSpeeds(IRariGovernanceTokenDistributor.RariPool.Stable, getFundBalance());

        // Return no error
        return 0;
    }

    /**
     * @notice Deposits all accrued fees on interest back into the fund on behalf of the master beneficiary.
     * @return Boolean indicating success.
     */
    function depositFees() external onlyRebalancer {
        uint8 result = _depositFees();
        require(result == 0, result == 2 ? "Deposit amount is so small that no RFT would be minted." : "No new fees are available to claim.");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     * @param value The uint256 to convert.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev The current withdrawal fee rate (scaled by 1e18).
     */
    uint256 private _withdrawalFeeRate;

    /**
     * @dev The master beneficiary of withdrawal fees; i.e., the recipient of all withdrawal fees.
     */
    address private _withdrawalFeeMasterBeneficiary;

    /**
     * @dev Returns the withdrawal fee rate (proportion of every withdrawal taken as a service fee scaled by 1e18).
     */
    function getWithdrawalFeeRate() public view returns (uint256) {
        return _withdrawalFeeRate;
    }

    /**
     * @dev Sets the withdrawal fee rate.
     * @param rate The proportion of every withdrawal taken as a service fee (scaled by 1e18).
     */
    function setWithdrawalFeeRate(uint256 rate) external fundEnabled onlyOwner {
        require(rate != _withdrawalFeeRate, "This is already the current withdrawal fee rate.");
        require(rate <= 1e18, "The withdrawal fee rate cannot be greater than 100%.");
        _withdrawalFeeRate = rate;
    }

    /**
     * @dev Sets the master beneficiary of withdrawal fees.
     * @param beneficiary The master beneficiary of withdrawal fees; i.e., the recipient of all withdrawal fees.
     */
    function setWithdrawalFeeMasterBeneficiary(address beneficiary) external fundEnabled onlyOwner {
        require(beneficiary != address(0), "Master beneficiary cannot be the zero address.");
        _withdrawalFeeMasterBeneficiary = beneficiary;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

import "./external/mstable/IMasset.sol";

/**
 * @title RariFundPriceConsumer
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice RariFundPriceConsumer retrieves stablecoin prices from Chainlink's public price feeds (used by RariFundManager and RariFundController).
 */
contract RariFundPriceConsumer is Initializable, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Chainlink price feed for DAI/USD.
     */
    AggregatorV3Interface private _daiUsdPriceFeed;
    
    /**
     * @dev Chainlink price feed for ETH/USD.
     */
    AggregatorV3Interface private _ethUsdPriceFeed;

    /**
     * @dev Chainlink price feeds for ETH-based pairs.
     */
    mapping(string => AggregatorV3Interface) private _ethBasedPriceFeeds;

    /**
     * @dev mStable mUSD token address.
     */
    address constant private MUSD = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;

    /**
     * @dev Initializer that sets supported ERC20 contract addresses and price feeds for each supported token.
     */
    function initialize(bool _allCurrenciesPeggedTo1Usd) public initializer {
        // Initialize owner
        Ownable.initialize(msg.sender);

        // Initialize allCurrenciesPeggedTo1Usd
        allCurrenciesPeggedTo1Usd = _allCurrenciesPeggedTo1Usd;

        // Initialize price feeds
        _daiUsdPriceFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
        _ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        _ethBasedPriceFeeds["USDC"] = AggregatorV3Interface(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
        _ethBasedPriceFeeds["USDT"] = AggregatorV3Interface(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
        _ethBasedPriceFeeds["TUSD"] = AggregatorV3Interface(0x3886BA987236181D98F2401c507Fb8BeA7871dF2);
        _ethBasedPriceFeeds["BUSD"] = AggregatorV3Interface(0x614715d2Af89E6EC99A233818275142cE88d1Cfd);
        _ethBasedPriceFeeds["sUSD"] = AggregatorV3Interface(0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757);
    }

    /**
     * @dev Retrives the latest DAI/USD price.
     */
    function getDaiUsdPrice() internal view returns (uint256) {
        (, int256 price, , , ) = _daiUsdPriceFeed.latestRoundData();
        return price >= 0 ? uint256(price).mul(1e10) : 0;
    }

    /**
     * @dev Retrives the latest ETH/USD price.
     */
    function getEthUsdPrice() internal view returns (uint256) {
        (, int256 price, , , ) = _ethUsdPriceFeed.latestRoundData();
        return price >= 0 ? uint256(price).mul(1e10) : 0;
    }

    /**
     * @dev Retrives the latest price of an ETH-based pair.
     */
    function getPriceInEth(string memory currencyCode) internal view returns (uint256) {
        (, int256 price, , , ) = _ethBasedPriceFeeds[currencyCode].latestRoundData();
        return price >= 0 ? uint256(price) : 0;
    }

    /**
     * @dev Retrives the latest mUSD/USD price given the prices of the underlying bAssets.
     */
    function getMUsdUsdPrice(uint256[] memory bAssetUsdPrices) internal view returns (uint256) {
        (, IMasset.BassetData[] memory bAssetData) = IMasset(MUSD).getBassets();
        require(bAssetData.length == 4, "mUSD underlying bAsset data length not equal to bAsset USD prices length.");
        uint256 usdSupplyScaled = 0;
        for (uint256 i = 0; i < bAssetData.length; i++) usdSupplyScaled = usdSupplyScaled.add(uint256(bAssetData[i].vaultBalance).mul(uint256(bAssetData[i].ratio)).div(1e8).mul(bAssetUsdPrices[i]));
        return usdSupplyScaled.div(IERC20(MUSD).totalSupply());
    }

    /**
     * @notice Returns the price of each supported currency in USD (scaled by 1e18).
     */
    function getCurrencyPricesInUsd() external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](7);

        // If all pegged to $1
        if (allCurrenciesPeggedTo1Usd) {
            for (uint256 i = 0; i < 7; i++) prices[i] = 1e18;
            return prices;
        }

        // Get bAsset prices and mUSD price
        uint256 ethUsdPrice = getEthUsdPrice();
        prices[0] = getPriceInEth("sUSD").mul(ethUsdPrice).div(1e18);
        prices[1] = getPriceInEth("USDC").mul(ethUsdPrice).div(1e18);
        prices[2] = getDaiUsdPrice();
        prices[3] = getPriceInEth("USDT").mul(ethUsdPrice).div(1e18);
        prices[6] = getMUsdUsdPrice(prices);

        // Reorder bAsset prices to match _supportedCurrencies
        prices[5] = prices[0]; // Set prices[5] to sUSD
        prices[0] = prices[2]; // Set prices[0] to DAI
        prices[2] = prices[3]; // Set prices[2] to USDT

        // Get other prices
        prices[3] = getPriceInEth("TUSD").mul(ethUsdPrice).div(1e18);
        prices[4] = getPriceInEth("BUSD").mul(ethUsdPrice).div(1e18);

        // Return prices array
        return prices;
    }

    /**
     * @notice Boolean indicating if all currencies are stablecoins pegged to the value of $1.
     */
    bool public allCurrenciesPeggedTo1Usd;

    /**
     * @dev Admin function to peg all stablecoin prices to $1.
     */
    function set1UsdPegOnAllCurrencies(bool enabled) external onlyOwner {
        require(allCurrenciesPeggedTo1Usd != enabled, "$1 USD peg status already set to the requested value.");
        allCurrenciesPeggedTo1Usd = enabled;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol";

import "./interfaces/IRariGovernanceTokenDistributor.sol";

/**
 * @title RariFundToken
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice RariFundToken is the ERC20 token contract accounting for the ownership of RariFundController's funds.
 */
contract RariFundToken is Initializable, ERC20, ERC20Detailed, ERC20Mintable, ERC20Burnable {
    using SafeMath for uint256;

    /**
     * @dev Initializer for RariFundToken.
     */
    function initialize() public initializer {
        ERC20Detailed.initialize("Rari Stable Pool Token", "RSPT", 18);
        ERC20Mintable.initialize(msg.sender);
    }

    /**
     * @dev Contract of the RariGovernanceTokenDistributor.
     */
    IRariGovernanceTokenDistributor public rariGovernanceTokenDistributor;

    /**
     * @dev Emitted when the GovernanceTokenDistributorSet of the RariFundManager is set or upgraded.
     */
    event GovernanceTokenDistributorSet(address newContract);

    /**
     * @dev Sets or upgrades the RariGovernanceTokenDistributor of the RariFundToken. Caller must have the {MinterRole}.
     * @param newContract The address of the new RariGovernanceTokenDistributor contract.
     * @param force Boolean indicating if we should not revert on validation error.
     */
    function setGovernanceTokenDistributor(address payable newContract, bool force) external onlyMinter {
        if (!force && address(rariGovernanceTokenDistributor) != address(0)) {
            require(rariGovernanceTokenDistributor.disabled(), "The old governance token distributor contract has not been disabled. (Set `force` to true to avoid this error.)");
            require(newContract != address(0), "By default, the governance token distributor cannot be set to the zero address. (Set `force` to true to avoid this error.)");
        }

        rariGovernanceTokenDistributor = IRariGovernanceTokenDistributor(newContract);

        if (newContract != address(0)) {
            if (!force) require(block.number <= rariGovernanceTokenDistributor.distributionStartBlock(), "The distribution period has already started. (Set `force` to true to avoid this error.)");
            if (block.number < rariGovernanceTokenDistributor.distributionEndBlock()) rariGovernanceTokenDistributor.refreshDistributionSpeeds(IRariGovernanceTokenDistributor.RariPool.Stable);
        }

        emit GovernanceTokenDistributorSet(newContract);
    }

    /*
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     * @dev Claims RGT earned by the sender and `recipient` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balances).
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        // Claim RGT/set timestamp for initial transfer of RSPT to `recipient`
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) {
            rariGovernanceTokenDistributor.distributeRgt(_msgSender(), IRariGovernanceTokenDistributor.RariPool.Stable);
            if (balanceOf(recipient) > 0) rariGovernanceTokenDistributor.distributeRgt(recipient, IRariGovernanceTokenDistributor.RariPool.Stable);
            else rariGovernanceTokenDistributor.beforeFirstPoolTokenTransferIn(recipient, IRariGovernanceTokenDistributor.RariPool.Stable);
        }

        // Transfer RSPT and returns true
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /*
     * @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount` is then deducted from the caller's allowance.
     * @dev Claims RGT earned by `sender` and `recipient` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balances).
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) {
            // Claim RGT/set timestamp for initial transfer of RSPT to `recipient`
            rariGovernanceTokenDistributor.distributeRgt(sender, IRariGovernanceTokenDistributor.RariPool.Stable);
            if (balanceOf(recipient) > 0) rariGovernanceTokenDistributor.distributeRgt(recipient, IRariGovernanceTokenDistributor.RariPool.Stable);
            else rariGovernanceTokenDistributor.beforeFirstPoolTokenTransferIn(recipient, IRariGovernanceTokenDistributor.RariPool.Stable);
        }
    
        // Transfer RSPT, deduct from allowance, and return true
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply. Caller must have the {MinterRole}.
     * @dev Claims RGT earned by `account` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balance of the caller).
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) {
            // Claim RGT/set timestamp for initial transfer of RSPT to `account`
            if (balanceOf(account) > 0) rariGovernanceTokenDistributor.distributeRgt(account, IRariGovernanceTokenDistributor.RariPool.Stable);
            else rariGovernanceTokenDistributor.beforeFirstPoolTokenTransferIn(account, IRariGovernanceTokenDistributor.RariPool.Stable);
        }

        // Mint RSPT and return true
        _mint(account, amount);
        return true;
    }

    /*
     * @notice Destroys `amount` tokens from the caller, reducing the total supply.
     * @dev Claims RGT earned by `account` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balance of the caller).
     */
    function burn(uint256 amount) public {
        // Claim RGT, then burn RSPT
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) rariGovernanceTokenDistributor.distributeRgt(_msgSender(), IRariGovernanceTokenDistributor.RariPool.Stable);
        _burn(_msgSender(), amount);
    }

    /*
     * @notice Destroys `amount` tokens from `account`. `amount` is then deducted from the caller's allowance.
     * @dev Claims RGT earned by `account` beforehand (so RariGovernanceTokenDistributor can continue distributing RGT considering the new RSPT balance of `account`).
     */
    function burnFrom(address account, uint256 amount) public {
        // Claim RGT, then burn RSPT
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) rariGovernanceTokenDistributor.distributeRgt(account, IRariGovernanceTokenDistributor.RariPool.Stable);
        _burnFrom(account, amount);
    }

    /*
     * @dev Destroys `amount` tokens from `account`. Caller must have the {MinterRole}.
     */
    function fundManagerBurnFrom(address account, uint256 amount) public onlyMinter {
        // Claim RGT, then burn RSPT
        if (address(rariGovernanceTokenDistributor) != address(0) && block.number > rariGovernanceTokenDistributor.distributionStartBlock()) rariGovernanceTokenDistributor.distributeRgt(account, IRariGovernanceTokenDistributor.RariPool.Stable);
        _burn(account, amount);
    }
}

/**
 * Aave Protocol
 * Copyright (C) 2019 Aave
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details
 */

pragma solidity 0.5.17;

/**
 * @title Aave ERC20 AToken
 * @dev Implementation of the interest bearing token for the DLP protocol.
 * @author Aave
 */
contract AToken {
    /**
     * @dev redeems aToken for the underlying asset
     * @param _amount the amount being redeemed
     */
    function redeem(uint256 _amount) external;

    /**
     * @dev calculates the balance of the user, which is the
     * principal balance + interest generated by the principal balance + interest generated by the redirected balance
     * @param _user the user for which the balance is being calculated
     * @return the total balance of the user
     */
    function balanceOf(address _user) public view returns (uint256);
}

/**
 * Aave Protocol
 * Copyright (C) 2019 Aave
 * This program is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version.
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details
 */

pragma solidity 0.5.17;

/**
 * @title LendingPool contract
 * @notice Implements the actions of the LendingPool, and exposes accessory methods to fetch the users and reserve data
 * @author Aave
 */
contract LendingPool {
    /**
     * @dev deposits The underlying asset into the reserve. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param _reserve the address of the reserve
     * @param _amount the amount to be deposited
     * @param _referralCode integrators are assigned a referral code and can potentially receive rewards.
     */
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external payable;
}

/**
 * Copyright 2020 Compound Labs, Inc.
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

pragma solidity 0.5.17;

/**
 * @title Compound's CErc20 Contract
 * @notice CTokens which wrap an EIP-20 underlying
 * @author Compound
 */
interface CErc20 {
    function underlying() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function accrueInterest() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function transfer(address dst, uint256 amount) external returns (bool);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { Account } from "./lib/Account.sol";
import { Types } from "./lib/Types.sol";


/**
 * @title Getters
 * @author dYdX
 *
 * Public read-only functions that allow transparency into the state of Solo
 */
contract Getters {
    using Types for Types.Par;

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        Account.Info memory account
    )
        public
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        );
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { Account } from "./lib/Account.sol";
import { Actions } from "./lib/Actions.sol";


/**
 * @title Operation
 * @author dYdX
 *
 * Primary public function for allowing users and contracts to manage accounts within Solo
 */
contract Operation {
    /**
     * The main entry-point to Solo that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public;
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { Getters } from "./Getters.sol";
import { Operation } from "./Operation.sol";


/**
 * @title SoloMargin
 * @author dYdX
 *
 * Main contract that inherits from other contracts
 */
contract SoloMargin is
    Getters,
    Operation
{ }

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

/**
 * @title Account
 * @author dYdX
 *
 * Library of structs and functions that represent an account
 */
library Account {
    // Represents the unique key that specifies an account
    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";


/**
 * @title Actions
 * @author dYdX
 *
 * Library that defines and parses valid Actions
 */
library Actions {
    // ============ Enums ============

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    // ============ Structs ============

    /*
     * Arguments that are passed to Solo in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in Solo
 */
library Types {
    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    // ============ Par (Principal Amount) ============

    // Individual principal amount for an account
    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

pragma solidity 0.5.17;

interface IBoostedSavingsVault {
    /**
     * @dev Get the RAW balance of a given account
     * @param _account User for which to retrieve balance
     */
    function rawBalanceOf(address _account) external view returns (uint256);

    /**
     * @dev Stakes a given amount of the StakingToken for the sender
     * @param _amount Units of StakingToken
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Withdraws given stake amount from the pool
     * @param _amount Units of the staked token to withdraw
     */
    function withdraw(uint256 _amount) external;

    /**
     * @dev Claims only the tokens that have been immediately unlocked, not including
     * those that are in the lockers.
     */
    function claimReward() external;

    /**
     * @dev Claims all unlocked rewards for sender. Both immediately unlocked
     * rewards and also locked rewards past their time lock.
     * @param _first    Index of the first array element to claim
     * @param _last     Index of the last array element to claim
     */
    function claimRewards(uint256 _first, uint256 _last) external;

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (uint256 amount, uint256 first, uint256 last);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./MassetStructs.sol";

/**
 * @title IMasset
 * @dev   (Internal) Interface for interacting with Masset
 *        VERSION: 1.0
 *        DATE:    2020-05-05
 */
contract IMasset is MassetStructs {
    // Mint
    function mint(
        address _input,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 mintOutput);

    function mintMulti(
        address[] calldata _inputs,
        uint256[] calldata _inputQuantities,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 mintOutput);

    function getMintOutput(address _input, uint256 _inputQuantity)
        external
        view
        returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _mAssetQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity);

    function redeemMasset(
        uint256 _mAssetQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity)
        external
        view
        returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities
    ) external view returns (uint256 mAssetAmount);

    // Views
    function getBasket() external view returns (bool, bool);

    function getBasset(address _token)
        external
        view
        returns (BassetPersonal memory personal, BassetData memory data);

    function getBassets()
        external
        view
        returns (BassetPersonal[] memory personal, BassetData[] memory data);

    function bAssetIndexes(address) external view returns (uint8);

    // SavingsManager
    function collectInterest() external returns (uint256 swapFeesGained, uint256 newSupply);

    function collectPlatformInterest()
        external
        returns (uint256 mintAmount, uint256 newSupply);

    // Admin
    function setCacheSize(uint256 _cacheSize) external;

    function upgradeForgeValidator(address _newForgeValidator) external;

    function setFees(uint256 _swapFee, uint256 _redemptionFee) external;

    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    function migrateBassets(address[] calldata _bAssets, address _newIntegration) external;
}

pragma solidity 0.5.17;

/**
 * @title ISavingsContract
 */
contract ISavingsContract {
    uint256 public exchangeRate;
    mapping(address => uint256) public creditBalances;
    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued);
    function redeem(uint256 _amount) external returns (uint256 massetReturned);
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.5.17;

interface MassetStructs {
    struct BassetPersonal {
        // Address of the bAsset
        address addr;
        // Address of the bAsset
        address integrator;
        // An ERC20 can charge transfer fee, for example USDT, DGX tokens.
        bool hasTxFee; // takes a byte in storage
        // Status of the bAsset
        BassetStatus status;
    }

    struct BassetData {
        // 1 Basset * ratio / ratioScale == x Masset (relative value)
        // If ratio == 10e8 then 1 bAsset = 10 mAssets
        // A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
        uint128 ratio;
        // Amount of the Basset that is held in Collateral
        uint128 vaultBalance;
    }

    // Status of the Basset - has it broken its peg?
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    struct BasketState {
        bool undergoingRecol;
        bool failed;
    }

    struct InvariantConfig {
        uint256 a;
        WeightLimits limits;
    }

    struct WeightLimits {
        uint128 min;
        uint128 max;
    }

    struct AmpData {
        uint64 initialA;
        uint64 targetA;
        uint64 rampStartTime;
        uint64 rampEndTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.5.17;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.5.17;

import "./IUniswapV2Router01.sol";

contract IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.5.17;

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

/**
 * @title IRariGovernanceTokenDistributor
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @notice IRariGovernanceTokenDistributor is a simple interface for RariGovernanceTokenDistributor used by RariFundManager and RariFundToken.
 */
interface IRariGovernanceTokenDistributor {
    /**
     * @notice Enum for the Rari pools to which distributions are rewarded.
     */
    enum RariPool {
        Stable,
        Yield,
        Ethereum
    }

    /**
     * @notice Boolean indicating if this contract is disabled.
     */
    function disabled() external returns (bool);

    /**
     * @notice Starting block number of the distribution.
     */
    function distributionStartBlock() external returns (uint256);

    /**
     * @notice Ending block number of the distribution.
     */
    function distributionEndBlock() external returns (uint256);

    /**
     * @dev Updates RGT distribution speeds for each pool given one `pool` and its `newBalance` (only accessible by the RariFundManager corresponding to `pool`).
     * @param pool The pool whose balance should be refreshed.
     * @param newBalance The new balance of the pool to be refreshed.
     */
    function refreshDistributionSpeeds(RariPool pool, uint256 newBalance) external;

    /**
     * @notice Updates RGT distribution speeds for each pool given one `pool` whose balance should be refreshed.
     * @param pool The pool whose balance should be refreshed.
     */
    function refreshDistributionSpeeds(RariPool pool) external;

    /**
     * @dev Distributes all undistributed RGT earned by `holder` in `pool` (without reverting if no RGT is available to distribute).
     * @param holder The holder of RSPT, RYPT, or REPT whose RGT is to be distributed.
     * @param pool The Rari pool for which to distribute RGT.
     * @return The quantity of RGT distributed.
     */
    function distributeRgt(address holder, RariPool pool) external returns (uint256);

    /**
     * @dev Stores the RGT distributed per RSPT/RYPT/REPT right before `holder`'s first incoming RSPT/RYPT/REPT transfer since having a zero balance.
     * @param holder The holder of RSPT, RYPT, and/or REPT.
     * @param pool The Rari pool of the pool token.
     */
    function beforeFirstPoolTokenTransferIn(address holder, RariPool pool) external;
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/mstable/IMasset.sol";

/**
 * @title MStableExchangeController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles minting and redeeming of mStable's mUSD token.
 */
library MStableExchangeController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant private MUSD_TOKEN_CONTRACT = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    IMasset constant private _mUsdToken = IMasset(MUSD_TOKEN_CONTRACT);

    /**
     * @dev Approves tokens to the mUSD token contract without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to the mUSD token contract.
     */
    function approve(address erc20Contract, uint256 amount) external {
        IERC20 token = IERC20(erc20Contract);
        uint256 allowance = token.allowance(address(this), MUSD_TOKEN_CONTRACT);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(MUSD_TOKEN_CONTRACT, 0);
        token.safeApprove(MUSD_TOKEN_CONTRACT, amount);
        return;
    }

    /**
     * @dev Swaps the specified amount of the specified input token in exchange for the specified output token.
     * @param inputErc20Contract The ERC20 contract address of the input token to be exchanged for output tokens.
     * @param outputErc20Contract The ERC20 contract address of the output token to be exchanged from input tokens.
     * @param inputAmount The amount of input tokens to be exchanged for output tokens.
     * @param minOutputAmount The minimum amount of output tokens.
     * @return The amount of output tokens.
     */
    function swap(address inputErc20Contract, address outputErc20Contract, uint256 inputAmount, uint256 minOutputAmount) external returns (uint256) {
        require(inputAmount > 0, "Input amount must be greater than 0.");
        uint256 outputAmount;

        if (inputErc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) {
            outputAmount = _mUsdToken.redeem(outputErc20Contract, inputAmount, minOutputAmount, address(this));
            require(outputAmount > minOutputAmount, "Error calling redeem on mStable mUSD token: output bAsset amount not greater than minimum.");
        } else if (outputErc20Contract == 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5) {
            outputAmount = _mUsdToken.mint(inputErc20Contract, inputAmount, minOutputAmount, address(this));
            require(outputAmount > minOutputAmount, "Error calling mint on mStable mUSD token: output mUSD amount not greater than minimum.");
        } else {
            outputAmount = _mUsdToken.swap(inputErc20Contract, outputErc20Contract, inputAmount, minOutputAmount, address(this));
            require(outputAmount > minOutputAmount, "Error calling swap on mStable mUSD token: output bAsset amount not greater than minimum.");
        }

        return outputAmount;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/uniswap/IUniswapV2Router02.sol";

/**
 * @title UniswapExchangeController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles exchanges via Uniswap V2.
 */
library UniswapExchangeController {
    using SafeERC20 for IERC20;

    /**
     * @dev UniswapV2Router02 contract object.
     */
    IUniswapV2Router02 constant public UNISWAP_V2_ROUTER_02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    /**
     * @dev Gets allowance of the specified token to the Uniswap V2 router.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function allowance(address erc20Contract) external view returns (uint256) {
        return IERC20(erc20Contract).allowance(address(this), address(UNISWAP_V2_ROUTER_02));
    }

    /**
     * @dev Approves tokens to the Uniswap V2 router without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to the Uniswap V2 router.
     */
    function approve(address erc20Contract, uint256 amount) external {
        IERC20 token = IERC20(erc20Contract);
        uint256 _allowance = token.allowance(address(this), address(UNISWAP_V2_ROUTER_02));
        if (_allowance == amount) return;
        if (amount > 0 && _allowance > 0) token.safeApprove(address(UNISWAP_V2_ROUTER_02), 0);
        token.safeApprove(address(UNISWAP_V2_ROUTER_02), amount);
        return;
    }

    /**
     * @dev Swaps exact `inputAmount` of `path[0]` for at least `minOutputAmount` of `path[length - 1]` via `path`.
     * @param inputAmount The exact input amount of `path[0]` to be swapped from.
     * @param minOutputAmount The minimum output amount of `path[length - 1]` to be swapped to.
     * @param path The swap path for the Uniswap V2 router.
     * @return The actual output amount.
     */
    function swapExactTokensForTokens(uint256 inputAmount, uint256 minOutputAmount, address[] calldata path) external returns (uint256) {
        return UniswapExchangeController.UNISWAP_V2_ROUTER_02.swapExactTokensForTokens(inputAmount, minOutputAmount, path, address(this), block.timestamp)[path.length - 1];
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/aave/LendingPool.sol";
import "../../external/aave/AToken.sol";

/**
 * @title AavePoolController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from Aave liquidity pools.
 */
library AavePoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Aave LendingPool contract address.
     */
    address constant private LENDING_POOL_CONTRACT = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;

    /**
     * @dev Aave LendingPool contract object.
     */
    LendingPool constant private _lendingPool = LendingPool(LENDING_POOL_CONTRACT);

    /**
     * @dev Aave LendingPoolCore contract address.
     */
    address constant private LENDING_POOL_CORE_CONTRACT = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    /**
     * @dev Returns a token's aToken contract address given its ERC20 contract address.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getATokenContract(address erc20Contract) private pure returns (address) {
        if (erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d; // DAI => aDAI
        if (erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x9bA00D6856a4eDF4665BcA2C2309936572473B7E; // USDC => aUSDC
        if (erc20Contract == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0x71fc860F7D3A592A4a98740e39dB31d25db65ae8; // USDT => aUSDT
        if (erc20Contract == 0x0000000000085d4780B73119b644AE5ecd22b376) return 0x4DA9b813057D04BAef4e5800E36083717b4a0341; // TUSD => aTUSD
        if (erc20Contract == 0x4Fabb145d64652a948d72533023f6E7A623C7C53) return 0x6Ee0f7BB50a54AB5253dA0667B0Dc2ee526C30a8; // BUSD => aBUSD
        if (erc20Contract == 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51) return 0x625aE63000f46200499120B906716420bd059240; // sUSD => aSUSD
        else revert("Supported Aave aToken address not found for this token address.");
    }

    /**
     * @dev Returns the fund's balance of the specified currency in the Aave pool.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getBalance(address erc20Contract) external view returns (uint256) {
        AToken aToken = AToken(getATokenContract(erc20Contract));
        return aToken.balanceOf(address(this));
    }

    /**
     * @dev Approves tokens to Aave without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to Aave.
     */
    function approve(address erc20Contract, uint256 amount) external {
        IERC20 token = IERC20(erc20Contract);
        uint256 allowance = token.allowance(address(this), LENDING_POOL_CORE_CONTRACT);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(LENDING_POOL_CORE_CONTRACT, 0);
        token.safeApprove(LENDING_POOL_CORE_CONTRACT, amount);
        return;
    }

    /**
     * @dev Deposits funds to the Aave pool. Assumes that you have already approved >= the amount to Aave.
     * @param erc20Contract The ERC20 contract address of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     * @param referralCode Referral code.
     */
    function deposit(address erc20Contract, uint256 amount, uint16 referralCode) external {
        require(amount > 0, "Amount must be greater than 0.");
        _lendingPool.deposit(erc20Contract, amount, referralCode);
    }

    /**
     * @dev Withdraws funds from the Aave pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(address erc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        AToken aToken = AToken(getATokenContract(erc20Contract));
        aToken.redeem(amount);
    }

    /**
     * @dev Withdraws all funds from the Aave pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     * @return Boolean indicating success.
     */
    function withdrawAll(address erc20Contract) external returns (bool) {
        AToken aToken = AToken(getATokenContract(erc20Contract));
        uint256 balance = aToken.balanceOf(address(this));
        if (balance <= 0) return false;
        aToken.redeem(balance);
        return true;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/compound/CErc20.sol";

/**
 * @title CompoundPoolController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from dYdX liquidity pools.
 */
library CompoundPoolController {
    using SafeERC20 for IERC20;

    /**
     * @dev Returns a token's cToken contract address given its ERC20 contract address.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getCErc20Contract(address erc20Contract) private pure returns (address) {
        if (erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643; // DAI => cDAI
        if (erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 0x39AA39c021dfbaE8faC545936693aC917d5E7563; // USDC => cUSDC
        if (erc20Contract == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return 0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9; // USDT => cUSDT
        else revert("Supported Compound cToken address not found for this token address.");
    }

    /**
     * @dev Returns the fund's balance of the specified currency in the Compound pool.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getBalance(address erc20Contract) external returns (uint256) {
        return CErc20(getCErc20Contract(erc20Contract)).balanceOfUnderlying(address(this));
    }

    /**
     * @dev Approves tokens to Compound without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to Compound.
     */
    function approve(address erc20Contract, uint256 amount) external {
        address cErc20Contract = getCErc20Contract(erc20Contract);
        IERC20 token = IERC20(erc20Contract);
        uint256 allowance = token.allowance(address(this), cErc20Contract);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(cErc20Contract, 0);
        token.safeApprove(cErc20Contract, amount);
        return;
    }

    /**
     * @dev Deposits funds to the Compound pool. Assumes that you have already approved >= the amount to Compound.
     * @param erc20Contract The ERC20 contract address of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(address erc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        CErc20 cErc20 = CErc20(getCErc20Contract(erc20Contract));
        uint256 mintResult = cErc20.mint(amount);
        require(mintResult == 0, "Error calling mint on Compound cToken: error code not equal to 0.");
    }

    /**
     * @dev Withdraws funds from the Compound pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(address erc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        CErc20 cErc20 = CErc20(getCErc20Contract(erc20Contract));
        uint256 redeemResult = cErc20.redeemUnderlying(amount);
        require(redeemResult == 0, "Error calling redeemUnderlying on Compound cToken: error code not equal to 0.");
    }

    /**
     * @dev Withdraws all funds from the Compound pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     * @return Boolean indicating success.
     */
    function withdrawAll(address erc20Contract) external returns (bool) {
        CErc20 cErc20 = CErc20(getCErc20Contract(erc20Contract));
        uint256 balance = cErc20.balanceOf(address(this));
        if (balance <= 0) return false;
        uint256 redeemResult = cErc20.redeem(balance);
        require(redeemResult == 0, "Error calling redeem on Compound cToken: error code not equal to 0.");
        return true;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/dydx/SoloMargin.sol";
import "../../external/dydx/lib/Account.sol";
import "../../external/dydx/lib/Actions.sol";
import "../../external/dydx/lib/Types.sol";

/**
 * @title DydxPoolController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from dYdX liquidity pools.
 */
library DydxPoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev dYdX SoloMargin contract address.
     */
    address constant private SOLO_MARGIN_CONTRACT = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    /**
     * @dev dYdX SoloMargin contract object.
     */
    SoloMargin constant private _soloMargin = SoloMargin(SOLO_MARGIN_CONTRACT);

    /**
     * @dev Returns a token's dYdX market ID given its ERC20 contract address.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getMarketId(address erc20Contract) private pure returns (uint256) {
        if (erc20Contract == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return 2; // USDC
        if (erc20Contract == 0x6B175474E89094C44Da98b954EedeAC495271d0F) return 3; // DAI
        else revert("Supported dYdX market not found for this token address.");
    }

    /**
     * @dev Returns the fund's balances of all currencies supported by dYdX.
     * @return An array of ERC20 token contract addresses and a corresponding array of balances.
     */
    function getBalances() external view returns (address[] memory, uint256[] memory) {
        Account.Info memory account = Account.Info(address(this), 0);
        (address[] memory tokens, , Types.Wei[] memory weis) = _soloMargin.getAccountBalances(account);
        uint256[] memory balances = new uint256[](weis.length);
        for (uint256 i = 0; i < weis.length; i++) balances[i] = weis[i].sign ? weis[i].value : 0;
        return (tokens, balances);
    }

    /**
     * @dev Returns the fund's balance of the specified currency in the dYdX pool.
     * @param erc20Contract The ERC20 contract address of the token.
     */
    function getBalance(address erc20Contract) external view returns (uint256) {
        uint256 marketId = getMarketId(erc20Contract);
        Account.Info memory account = Account.Info(address(this), 0);
        (, , Types.Wei[] memory weis) = _soloMargin.getAccountBalances(account);
        return weis[marketId].sign ? weis[marketId].value : 0;
    }

    /**
     * @dev Approves tokens to dYdX without spending gas on every deposit.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to dYdX.
     */
    function approve(address erc20Contract, uint256 amount) external {
        IERC20 token = IERC20(erc20Contract);
        uint256 allowance = token.allowance(address(this), SOLO_MARGIN_CONTRACT);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(SOLO_MARGIN_CONTRACT, 0);
        token.safeApprove(SOLO_MARGIN_CONTRACT, amount);
        return;
    }

    /**
     * @dev Deposits funds to the dYdX pool. Assumes that you have already approved >= the amount to dYdX.
     * @param erc20Contract The ERC20 contract address of the token to be deposited.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(address erc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        uint256 marketId = getMarketId(erc20Contract);

        Account.Info memory account = Account.Info(address(this), 0);
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = account;

        Types.AssetAmount memory assetAmount = Types.AssetAmount(true, Types.AssetDenomination.Wei, Types.AssetReference.Delta, amount);
        bytes memory emptyData;

        Actions.ActionArgs memory action = Actions.ActionArgs(
            Actions.ActionType.Deposit,
            0,
            assetAmount,
            marketId,
            0,
            address(this),
            0,
            emptyData
        );

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        _soloMargin.operate(accounts, actions);
    }

    /**
     * @dev Withdraws funds from the dYdX pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(address erc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        uint256 marketId = getMarketId(erc20Contract);

        Account.Info memory account = Account.Info(address(this), 0);
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = account;

        Types.AssetAmount memory assetAmount = Types.AssetAmount(false, Types.AssetDenomination.Wei, Types.AssetReference.Delta, amount);
        bytes memory emptyData;

        Actions.ActionArgs memory action = Actions.ActionArgs(
            Actions.ActionType.Withdraw,
            0,
            assetAmount,
            marketId,
            0,
            address(this),
            0,
            emptyData
        );

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        _soloMargin.operate(accounts, actions);
    }

    /**
     * @dev Withdraws all funds from the dYdX pool.
     * @param erc20Contract The ERC20 contract address of the token to be withdrawn.
     */
    function withdrawAll(address erc20Contract) external {
        uint256 marketId = getMarketId(erc20Contract);

        Account.Info memory account = Account.Info(address(this), 0);
        Account.Info[] memory accounts = new Account.Info[](1);
        accounts[0] = account;

        Types.AssetAmount memory assetAmount = Types.AssetAmount(true, Types.AssetDenomination.Par, Types.AssetReference.Target, 0);
        bytes memory emptyData;

        Actions.ActionArgs memory action = Actions.ActionArgs(
            Actions.ActionType.Withdraw,
            0,
            assetAmount,
            marketId,
            0,
            address(this),
            0,
            emptyData
        );

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        actions[0] = action;

        _soloMargin.operate(accounts, actions);
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/compound/CErc20.sol";

/**
 * @title FusePoolController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from Fuse liquidity pools.
 */
library FusePoolController {
    using SafeERC20 for IERC20;

    /**
     * @dev Returns the fund's balance of the specified currency in the specified Fuse pool.
     * @param cErc20Contract The CErc20 contract address of the token.
     */
    function getBalance(address cErc20Contract) external returns (uint256) {
        return CErc20(cErc20Contract).balanceOfUnderlying(address(this));
    }

    /**
     * @dev Approves tokens to Fuse without spending gas on every deposit.
     * @param cErc20Contract The CErc20 contract address of the token.
     * @param erc20Contract The ERC20 contract address of the token.
     * @param amount Amount of the specified token to approve to Fuse.
     */
    function approve(address cErc20Contract, address erc20Contract, uint256 amount) external {
        IERC20 token = IERC20(erc20Contract);
        uint256 allowance = token.allowance(address(this), cErc20Contract);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(cErc20Contract, 0);
        token.safeApprove(cErc20Contract, amount);
        return;
    }

    /**
     * @dev Deposits funds to the Fuse pool. Assumes that you have already approved >= the amount to Fuse.
     * @param cErc20Contract The CErc20 contract address of the token.
     * @param amount The amount of tokens to be deposited.
     */
    function deposit(address cErc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        CErc20 cErc20 = CErc20(cErc20Contract);
        uint256 mintResult = cErc20.mint(amount);
        require(mintResult == 0, "Error calling mint on Fuse cToken: error code not equal to 0.");
    }

    /**
     * @dev Withdraws funds from the Fuse pool.
     * @param cErc20Contract The CErc20 contract address of the token.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdraw(address cErc20Contract, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        CErc20 cErc20 = CErc20(cErc20Contract);
        uint256 redeemResult = cErc20.redeemUnderlying(amount);
        require(redeemResult == 0, "Error calling redeemUnderlying on Fuse cToken: error code not equal to 0.");
    }

    /**
     * @dev Withdraws all funds from the Fuse pool.
     * @param cErc20Contract The CErc20 contract address of the token.
     * @return Boolean indicating success.
     */
    function withdrawAll(address cErc20Contract) external returns (bool) {
        CErc20 cErc20 = CErc20(cErc20Contract);
        uint256 balance = cErc20.balanceOf(address(this));
        if (balance <= 0) return false;
        uint256 redeemResult = cErc20.redeem(balance);
        require(redeemResult == 0, "Error calling redeem on Fuse cToken: error code not equal to 0.");
        return true;
    }

    /**
     * @dev Transfers all funds from the Fuse pool.
     * @param cErc20Contract The CErc20 contract address of the token.
     * @return Boolean indicating success.
     */
    function transferAll(address cErc20Contract, address newContract) external returns (bool) {
        CErc20 cErc20 = CErc20(cErc20Contract);
        uint256 balance = cErc20.balanceOf(address(this));
        if (balance <= 0) return false;
        require(cErc20.transfer(newContract, balance), "Error calling transfer on Fuse cToken.");
        return true;
    }
}

/**
 * COPYRIGHT © 2020 RARI CAPITAL, INC. ALL RIGHTS RESERVED.
 * Anyone is free to integrate the public (i.e., non-administrative) application programming interfaces (APIs) of the official Ethereum smart contract instances deployed by Rari Capital, Inc. in any application (commercial or noncommercial and under any license), provided that the application does not abuse the APIs or act against the interests of Rari Capital, Inc.
 * Anyone is free to study, review, and analyze the source code contained in this package.
 * Reuse (including deployment of smart contracts other than private testing on a private network), modification, redistribution, or sublicensing of any source code contained in this package is not permitted without the explicit permission of David Lucid of Rari Capital, Inc.
 * No one is permitted to use the software for any purpose other than those allowed by this license.
 * This license is liable to change at any time at the sole discretion of David Lucid of Rari Capital, Inc.
 */

pragma solidity 0.5.17;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import "../../external/mstable/ISavingsContract.sol";
import "../../external/mstable/IBoostedSavingsVault.sol";

/**
 * @title MStablePoolController
 * @author David Lucid <[email protected]> (https://github.com/davidlucid)
 * @dev This library handles deposits to and withdrawals from mStable liquidity pools.
 */
library MStablePoolController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev mStable mUSD ERC20 token contract address.
     */
    address constant private MUSD_TOKEN_CONTRACT = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;

    /**
     * @dev mStable SavingsContract contract address.
     */
    address constant private SAVINGS_CONTRACT = 0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;

    /**
     * @dev mStable SavingsContract contract object.
     */
    ISavingsContract constant private _savingsContract = ISavingsContract(SAVINGS_CONTRACT);

    /**
     * @dev mStable BoostedSavingsVault contract address.
     */
    address constant private SAVINGS_VAULT_CONTRACT = 0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B;

    /**
     * @dev mStable BoostedSavingsVault contract object.
     */
    IBoostedSavingsVault constant private _savingsVault = IBoostedSavingsVault(SAVINGS_VAULT_CONTRACT);

    /**
     * @dev Returns the fund's mUSD token balance supplied to the mStable savings contract.
     */
    function getBalance() external view returns (uint256) {
        return _savingsVault.rawBalanceOf(address(this)).mul(_savingsContract.exchangeRate()).div(1e18);
    }

    /**
     * @dev Approves mUSD tokens to the mStable savings contract and imUSD to the savings vault without spending gas on every deposit.
     * @param amount Amount of mUSD tokens to approve to the mStable savings contract.
     */
    function approve(uint256 amount) external {
        // Approve mUSD to the savings contract (imUSD)
        IERC20 token = IERC20(MUSD_TOKEN_CONTRACT);
        uint256 allowance = token.allowance(address(this), SAVINGS_CONTRACT);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(SAVINGS_CONTRACT, 0);
        token.safeApprove(SAVINGS_CONTRACT, amount);

        // Approve imUSD to the savings vault
        token = IERC20(SAVINGS_CONTRACT);
        allowance = token.allowance(address(this), SAVINGS_VAULT_CONTRACT);
        if (allowance == amount) return;
        if (amount > 0 && allowance > 0) token.safeApprove(SAVINGS_VAULT_CONTRACT, 0);
        token.safeApprove(SAVINGS_VAULT_CONTRACT, amount);
    }

    /**
     * @dev Deposits mUSD tokens to the mStable savings contract.
     * @param amount The amount of mUSD tokens to be deposited.
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        uint256 creditsIssued = _savingsContract.depositSavings(amount);
        require(creditsIssued > 0, "Error calling depositSavings on mStable savings contract: no credits issued.");
        _savingsVault.stake(creditsIssued);
    }

    /**
     * @dev Withdraws mUSD tokens from the mStable savings contract.
     * May withdraw slightly more than `amount` due to imperfect precision.
     * @param amount The amount of mUSD tokens to be withdrawn.
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0.");
        uint256 exchangeRate = _savingsContract.exchangeRate();
        uint256 credits = amount.mul(1e18).div(exchangeRate);
        if (credits.mul(exchangeRate).div(1e18) < amount) credits++; // Round up if necessary (i.e., if the division above left a remainder)
        _savingsVault.withdraw(credits);
        uint256 mAssetReturned = _savingsContract.redeem(credits);
        require(mAssetReturned > 0, "Error calling redeem on mStable savings contract: no mUSD returned.");
    }

    /**
     * @dev Withdraws all funds from the mStable savings contract.
     */
    function withdrawAll() external returns (bool) {
        uint256 creditBalance = _savingsVault.rawBalanceOf(address(this));
        if (creditBalance <= 0) return false;
        _savingsVault.withdraw(creditBalance);
        uint256 mAssetReturned = _savingsContract.redeem(creditBalance);
        require(mAssetReturned > 0, "Error calling redeem on mStable savings contract: no mUSD returned.");
        return true;
    }

    /**
     * @dev Claims mStable MTA rewards (if `all` is set, unlocks and claims locked rewards).
     * @param all If locked rewards should be unlocked and claimed.
     * @param first Index of the first array element to claim. Only applicable if `all` is true. Feed in the second value returned by the savings vault's `unclaimedRewards(address _account)` function.
     * @param last Index of the last array element to claim. Only applicable if `all` is true. Feed in the third value returned by the savings vault's `unclaimedRewards(address _account)` function.
     */
    function claimRewards(bool all, uint256 first, uint256 last) external {
        all ? _savingsVault.claimRewards(first, last) : _savingsVault.claimReward();
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;

import "@0x/contracts-utils/contracts/src/LibEIP712.sol";


library LibOrder {

    using LibOrder for Order;

    // Hash for the EIP712 Order Schema:
    // keccak256(abi.encodePacked(
    //     "Order(",
    //     "address makerAddress,",
    //     "address takerAddress,",
    //     "address feeRecipientAddress,",
    //     "address senderAddress,",
    //     "uint256 makerAssetAmount,",
    //     "uint256 takerAssetAmount,",
    //     "uint256 makerFee,",
    //     "uint256 takerFee,",
    //     "uint256 expirationTimeSeconds,",
    //     "uint256 salt,",
    //     "bytes makerAssetData,",
    //     "bytes takerAssetData,",
    //     "bytes makerFeeAssetData,",
    //     "bytes takerFeeAssetData",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_ORDER_SCHEMA_HASH =
        0xf80322eb8376aafb64eadf8f0d7623f22130fd9491a221e902b713cb984a7534;

    // A valid order remains fillable until it is expired, fully filled, or cancelled.
    // An order's status is unaffected by external factors, like account balances.
    enum OrderStatus {
        INVALID,                     // Default value
        INVALID_MAKER_ASSET_AMOUNT,  // Order does not have a valid maker asset amount
        INVALID_TAKER_ASSET_AMOUNT,  // Order does not have a valid taker asset amount
        FILLABLE,                    // Order is fillable
        EXPIRED,                     // Order has already expired
        FULLY_FILLED,                // Order is fully filled
        CANCELLED                    // Order has been cancelled
    }

    // solhint-disable max-line-length
    /// @dev Canonical order structure.
    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee;               // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }
    // solhint-enable max-line-length

    /// @dev Order information returned by `getOrderInfo()`.
    struct OrderInfo {
        OrderStatus orderStatus;                    // Status that describes order's validity and fillability.
        bytes32 orderHash;                    // EIP712 typed data hash of the order (see LibOrder.getTypedDataHash).
        uint256 orderTakerAssetFilledAmount;  // Amount of order that has already been filled.
    }

    /// @dev Calculates the EIP712 typed data hash of an order with a given domain separator.
    /// @param order The order structure.
    /// @return EIP712 typed data hash of the order.
    function getTypedDataHash(Order memory order, bytes32 eip712ExchangeDomainHash)
        internal
        pure
        returns (bytes32 orderHash)
    {
        orderHash = LibEIP712.hashEIP712Message(
            eip712ExchangeDomainHash,
            order.getStructHash()
        );
        return orderHash;
    }

    /// @dev Calculates EIP712 hash of the order struct.
    /// @param order The order structure.
    /// @return EIP712 hash of the order struct.
    function getStructHash(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_ORDER_SCHEMA_HASH;
        bytes memory makerAssetData = order.makerAssetData;
        bytes memory takerAssetData = order.takerAssetData;
        bytes memory makerFeeAssetData = order.makerFeeAssetData;
        bytes memory takerFeeAssetData = order.takerFeeAssetData;

        // Assembly for more efficiently computing:
        // keccak256(abi.encodePacked(
        //     EIP712_ORDER_SCHEMA_HASH,
        //     uint256(order.makerAddress),
        //     uint256(order.takerAddress),
        //     uint256(order.feeRecipientAddress),
        //     uint256(order.senderAddress),
        //     order.makerAssetAmount,
        //     order.takerAssetAmount,
        //     order.makerFee,
        //     order.takerFee,
        //     order.expirationTimeSeconds,
        //     order.salt,
        //     keccak256(order.makerAssetData),
        //     keccak256(order.takerAssetData),
        //     keccak256(order.makerFeeAssetData),
        //     keccak256(order.takerFeeAssetData)
        // ));

        assembly {
            // Assert order offset (this is an internal error that should never be triggered)
            if lt(order, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)
            let pos4 := add(order, 384)
            let pos5 := add(order, 416)

            // Backup
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)
            let temp4 := mload(pos4)
            let temp5 := mload(pos5)

            // Hash in place
            mstore(pos1, schemaHash)
            mstore(pos2, keccak256(add(makerAssetData, 32), mload(makerAssetData)))        // store hash of makerAssetData
            mstore(pos3, keccak256(add(takerAssetData, 32), mload(takerAssetData)))        // store hash of takerAssetData
            mstore(pos4, keccak256(add(makerFeeAssetData, 32), mload(makerFeeAssetData)))  // store hash of makerFeeAssetData
            mstore(pos5, keccak256(add(takerFeeAssetData, 32), mload(takerFeeAssetData)))  // store hash of takerFeeAssetData
            result := keccak256(pos1, 480)

            // Restore
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
            mstore(pos4, temp4)
            mstore(pos5, temp5)
        }
        return result;
    }
}

/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.9;


library LibEIP712 {

    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 constant internal _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    )
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
        internal
        pure
        returns (bytes32 result)
    {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "../Roles.sol";

contract MinterRole is Initializable, Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    function initialize(address sender) public initializer {
        if (!isMinter(sender)) {
            _addMinter(sender);
        }
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../GSN/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Initializable, Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Initializable, Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is Initializable, IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(string memory name, string memory symbol, uint8 decimals) public initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./ERC20.sol";
import "../../access/roles/MinterRole.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is Initializable, ERC20, MinterRole {
    function initialize(address sender) public initializer {
        MinterRole.initialize(sender);
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

    uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}