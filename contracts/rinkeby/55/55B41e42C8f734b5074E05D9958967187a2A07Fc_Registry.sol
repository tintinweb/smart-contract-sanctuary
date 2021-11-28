// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { DataTypes } from "../../libraries/types/DataTypes.sol";

//  helper contracts
import { ModifiersController } from "./ModifiersController.sol";
import { RegistryProxy } from "./RegistryProxy.sol";

//  interfaces
import { IVault } from "../../interfaces/opty/IVault.sol";
import { IRegistry } from "../../interfaces/opty/IRegistry.sol";
import { Constants } from "../../utils/Constants.sol";

/**
 * @title Registry Contract
 * @author Opty.fi
 * @dev Contract to persit status of tokens,lpTokens,lp/cp and Vaults
 */
contract Registry is IRegistry, ModifiersController {
    using Address for address;
    using SafeMath for uint256;

    /**
     * @dev Set RegistryProxy to act as Registry
     * @param _registryProxy RegistryProxy Contract address to act as Registry
     */
    function become(RegistryProxy _registryProxy) external {
        require(msg.sender == _registryProxy.governance(), "!governance");
        require(_registryProxy.acceptImplementation() == 0, "!unauthorized");
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTreasury(address _treasury) external override onlyGovernance returns (bool) {
        require(_treasury != address(0), "!address(0)");
        treasury = _treasury;
        emit TransferTreasury(treasury, msg.sender);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setInvestStrategyRegistry(address _investStrategyRegistry) external override onlyOperator returns (bool) {
        require(_investStrategyRegistry != address(0), "!address(0)");
        require(_investStrategyRegistry.isContract(), "!isContract");
        investStrategyRegistry = _investStrategyRegistry;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setAPROracle(address _aprOracle) external override onlyOperator returns (bool) {
        require(_aprOracle != address(0), "!address(0)");
        require(_aprOracle.isContract(), "!isContract");
        aprOracle = _aprOracle;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setStrategyProvider(address _strategyProvider) external override onlyOperator returns (bool) {
        require(_strategyProvider != address(0), "!address(0)");
        require(_strategyProvider.isContract(), "!isContract");
        strategyProvider = _strategyProvider;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setRiskManager(address _riskManager) external override onlyOperator returns (bool) {
        require(_riskManager != address(0), "!address(0)");
        require(_riskManager.isContract(), "!isContract");
        riskManager = _riskManager;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setHarvestCodeProvider(address _harvestCodeProvider) external override onlyOperator returns (bool) {
        require(_harvestCodeProvider != address(0), "!address(0)");
        require(_harvestCodeProvider.isContract(), "!isContract");
        harvestCodeProvider = _harvestCodeProvider;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setStrategyManager(address _strategyManager) external override onlyOperator returns (bool) {
        require(_strategyManager != address(0), "!address(0)");
        require(_strategyManager.isContract(), "!isContract");
        strategyManager = _strategyManager;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setOPTY(address _opty) external override onlyOperator returns (bool) {
        require(_opty != address(0), "!address(0)");
        require(_opty.isContract(), "!isContract");
        opty = _opty;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setPriceOracle(address _priceOracle) external override onlyOperator returns (bool) {
        require(_priceOracle != address(0), "!address(0)");
        require(_priceOracle.isContract(), "!isContract");
        priceOracle = _priceOracle;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setOPTYStakingRateBalancer(address _optyStakingRateBalancer)
        external
        override
        onlyOperator
        returns (bool)
    {
        require(_optyStakingRateBalancer != address(0), "!address(0)");
        require(_optyStakingRateBalancer.isContract(), "!isContract");
        optyStakingRateBalancer = _optyStakingRateBalancer;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setODEFIVaultBooster(address _odefiVaultBooster) external override onlyOperator returns (bool) {
        require(_odefiVaultBooster != address(0), "!address(0)");
        require(_odefiVaultBooster.isContract(), "!isContract");
        odefiVaultBooster = _odefiVaultBooster;
        return true;
    }

    ///@TODO Add staking pool contract addresses

    /**
     * @inheritdoc IRegistry
     */
    function approveToken(address[] memory _tokens) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            _approveToken(_tokens[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveToken(address _token) external override onlyOperator returns (bool) {
        _approveToken(_token);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeToken(address[] memory _tokens) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            _revokeToken(_tokens[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeToken(address _token) external override onlyOperator returns (bool) {
        _revokeToken(_token);
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPool(address[] memory _pools) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _pools.length; _i++) {
            _approveLiquidityPool(_pools[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveLiquidityPool(address _pool) external override onlyOperator returns (bool) {
        _approveLiquidityPool(_pool);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeLiquidityPool(address[] memory _pools) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _pools.length; _i++) {
            _revokeLiquidityPool(_pools[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeLiquidityPool(address _pool) external override onlyOperator returns (bool) {
        _revokeLiquidityPool(_pool);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateLiquidityPool(DataTypes.PoolRate[] memory _poolRates)
        external
        override
        onlyRiskOperator
        returns (bool)
    {
        for (uint256 _i = 0; _i < _poolRates.length; _i++) {
            _rateLiquidityPool(_poolRates[_i].pool, _poolRates[_i].rate);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateLiquidityPool(address _pool, uint8 _rate) external override onlyRiskOperator returns (bool) {
        _rateLiquidityPool(_pool, _rate);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveCreditPool(address[] memory _pools) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _pools.length; _i++) {
            _approveCreditPool(_pools[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function approveCreditPool(address _pool) external override onlyOperator returns (bool) {
        _approveCreditPool(_pool);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeCreditPool(address[] memory _pools) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _pools.length; _i++) {
            _revokeCreditPool(_pools[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function revokeCreditPool(address _pool) external override onlyOperator returns (bool) {
        _revokeCreditPool(_pool);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateCreditPool(DataTypes.PoolRate[] memory _poolRates) external override onlyRiskOperator returns (bool) {
        for (uint256 _i = 0; _i < _poolRates.length; _i++) {
            _rateCreditPool(_poolRates[_i].pool, _poolRates[_i].rate);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function rateCreditPool(address _pool, uint8 _rate) external override onlyRiskOperator returns (bool) {
        _rateCreditPool(_pool, _rate);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setLiquidityPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters)
        external
        override
        onlyOperator
        returns (bool)
    {
        for (uint256 _i = 0; _i < _poolAdapters.length; _i++) {
            _setLiquidityPoolToAdapter(_poolAdapters[_i].pool, _poolAdapters[_i].adapter);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setLiquidityPoolToAdapter(address _pool, address _adapter) external override onlyOperator returns (bool) {
        _setLiquidityPoolToAdapter(_pool, _adapter);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTokensHashToTokens(address[][] memory _setOfTokens) external override onlyOperator returns (bool) {
        for (uint256 _i = 0; _i < _setOfTokens.length; _i++) {
            _setTokensHashToTokens(_setOfTokens[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTokensHashToTokens(address[] memory _tokens) external override onlyOperator returns (bool) {
        _setTokensHashToTokens(_tokens);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[] memory _underlyingAssets,
        uint256 _riskProfileCode,
        address _vault
    ) external override onlyOperator returns (bool) {
        _setUnderlyingAssetHashToRPToVaults(keccak256(abi.encodePacked(_underlyingAssets)), _riskProfileCode, _vault);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setWithdrawalFee(address _vault, uint256 _withdrawalFee)
        external
        override
        onlyFinanceOperator
        returns (bool)
    {
        require(_vault != address(0), "!address(0)");
        require(_vault.isContract(), "!isContract");
        require(
            _withdrawalFee >= withdrawalFeeRange.lowerLimit && _withdrawalFee <= withdrawalFeeRange.upperLimit,
            "!BasisRange"
        );
        vaultToVaultConfiguration[_vault].withdrawalFee = _withdrawalFee;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setWithdrawalFeeRange(DataTypes.WithdrawalFeeRange memory _withdrawalFeeRange)
        external
        override
        onlyFinanceOperator
        returns (bool)
    {
        require(
            _withdrawalFeeRange.lowerLimit >= 0 &&
                _withdrawalFeeRange.lowerLimit < _withdrawalFeeRange.upperLimit &&
                _withdrawalFeeRange.upperLimit <= 10000,
            "!BasisRange"
        );
        withdrawalFeeRange = _withdrawalFeeRange;
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setTreasuryShares(address _vault, DataTypes.TreasuryShare[] memory _treasuryShares)
        external
        override
        onlyFinanceOperator
        returns (bool)
    {
        require(_vault != address(0), "!address(0)");
        require(_vault.isContract(), "!isContract");
        require(_treasuryShares.length > 0, "length!>0");
        uint256 _sharesSum = 0;
        for (uint256 _i = 0; _i < _treasuryShares.length; _i++) {
            require(_treasuryShares[_i].treasury != address(0), "!address(0)");
            _sharesSum = _sharesSum.add(_treasuryShares[_i].share);
        }
        require(_sharesSum == vaultToVaultConfiguration[_vault].withdrawalFee, "FeeShares!=WithdrawalFee");

        //  delete the existing the treasury accounts if any to reset them
        if (vaultToVaultConfiguration[_vault].treasuryShares.length > 0) {
            delete vaultToVaultConfiguration[_vault].treasuryShares;
        }
        for (uint256 _i = 0; _i < _treasuryShares.length; _i++) {
            vaultToVaultConfiguration[_vault].treasuryShares.push(_treasuryShares[_i]);
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[][] memory _underlyingAssets,
        uint256[] memory _riskProfileCodes,
        address[][] memory _vaults
    ) external override onlyOperator returns (bool) {
        require(_riskProfileCodes.length == _vaults.length, "!Profileslength");
        for (uint256 _i = 0; _i < _vaults.length; _i++) {
            require(_vaults[_i].length == _underlyingAssets.length, "!VaultsLength");
            for (uint256 _j = 0; _j < _vaults[_i].length; _j++) {
                _setUnderlyingAssetHashToRPToVaults(
                    keccak256(abi.encodePacked(_underlyingAssets[_j])),
                    _riskProfileCodes[_i],
                    _vaults[_i][_j]
                );
            }
        }
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function discontinue(address _vault) external override onlyOperator returns (bool) {
        require(_vault != address(0), "!address(0)");
        require(_vault.isContract(), "!isContract");
        vaultToVaultConfiguration[_vault].discontinued = true;
        IVault(_vault).discontinue();
        emit LogDiscontinueVault(_vault, vaultToVaultConfiguration[_vault].discontinued, msg.sender);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function unpauseVaultContract(address _vault, bool _unpaused) external override onlyOperator returns (bool) {
        require(_vault != address(0), "!address(0)");
        require(_vault.isContract(), "!isContract");
        vaultToVaultConfiguration[_vault].unpaused = _unpaused;
        IVault(_vault).setUnpaused(vaultToVaultConfiguration[_vault].unpaused);
        emit LogUnpauseVault(_vault, vaultToVaultConfiguration[_vault].unpaused, msg.sender);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function updateRiskProfileBorrow(uint256 _riskProfileCode, bool _canBorrow)
        external
        override
        onlyRiskOperator
        returns (bool)
    {
        _updateRiskProfileBorrow(_riskProfileCode, _canBorrow);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        bool _canBorrow,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) external override onlyRiskOperator returns (bool) {
        _addRiskProfile(_riskProfileCode, _name, _symbol, _canBorrow, _poolRatingRange);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function addRiskProfile(
        uint256[] memory _riskProfileCodes,
        string[] memory _names,
        string[] memory _symbols,
        bool[] memory _canBorrow,
        DataTypes.PoolRatingsRange[] memory _poolRatingRanges
    ) external override onlyRiskOperator returns (bool) {
        require(_riskProfileCodes.length > 0, "!length>0");
        require(_riskProfileCodes.length == _poolRatingRanges.length, "!RP_PoolRatingsLength");
        require(_riskProfileCodes.length == _canBorrow.length, "!RP_canBorrowLength");
        require(_riskProfileCodes.length == _names.length, "!RP_namesLength");
        require(_riskProfileCodes.length == _symbols.length, "!RP_symbolsLength");

        for (uint256 _i = 0; _i < _riskProfileCodes.length; _i++) {
            _addRiskProfile(_riskProfileCodes[_i], _names[_i], _symbols[_i], _canBorrow[_i], _poolRatingRanges[_i]);
        }

        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        external
        override
        onlyRiskOperator
        returns (bool)
    {
        _updateRPPoolRatings(_riskProfileCode, _poolRatingRange);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function removeRiskProfile(uint256 _index) external override onlyRiskOperator returns (bool) {
        _removeRiskProfile(_index);
        return true;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokenHashes() public view override returns (bytes32[] memory) {
        return tokensHashIndexes;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashToTokenList(bytes32 _tokensHash) public view override returns (address[] memory) {
        return tokensHashToTokens[_tokensHash].tokens;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskProfileList() public view override returns (uint256[] memory) {
        return riskProfilesArray;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getVaultConfiguration(address _vault) public view override returns (DataTypes.VaultConfiguration memory) {
        return vaultToVaultConfiguration[_vault];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getInvestStrategyRegistry() public view override returns (address) {
        return investStrategyRegistry;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashIndexByHash(bytes32 _tokensHash) public view override returns (uint256) {
        return tokensHashToTokens[_tokensHash].index;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTokensHashByIndex(uint256 _index) public view override returns (bytes32) {
        return tokensHashIndexes[_index];
    }

    /**
     * @inheritdoc IRegistry
     */
    function isApprovedToken(address _token) public view override returns (bool) {
        return tokens[_token];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyProvider() public view override returns (address) {
        return strategyProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyManager() public view override returns (address) {
        return strategyManager;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getAprOracle() public view override returns (address) {
        return aprOracle;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskProfile(uint256 _riskProfileCode) public view override returns (DataTypes.RiskProfile memory) {
        return riskProfiles[_riskProfileCode];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskManager() public view override returns (address) {
        return riskManager;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getOPTYDistributor() public view override returns (address) {
        return optyDistributor;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getODEFIVaultBooster() external view override returns (address) {
        return odefiVaultBooster;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getGovernance() public view override returns (address) {
        return governance;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getFinanceOperator() public view override returns (address) {
        return financeOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getRiskOperator() public view override returns (address) {
        return riskOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyOperator() public view override returns (address) {
        return strategyOperator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getOperator() public view override returns (address) {
        return operator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getHarvestCodeProvider() public view override returns (address) {
        return harvestCodeProvider;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getOPTYStakingRateBalancer() public view override returns (address) {
        return optyStakingRateBalancer;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getLiquidityPool(address _pool) public view override returns (DataTypes.LiquidityPool memory) {
        return liquidityPools[_pool];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getStrategyConfiguration()
        public
        view
        override
        returns (DataTypes.StrategyConfiguration memory _strategyConfiguration)
    {
        _strategyConfiguration.investStrategyRegistry = investStrategyRegistry;
        _strategyConfiguration.strategyProvider = strategyProvider;
        _strategyConfiguration.aprOracle = aprOracle;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getVaultStrategyConfiguration()
        public
        view
        override
        returns (DataTypes.VaultStrategyConfiguration memory _vaultStrategyConfiguration)
    {
        _vaultStrategyConfiguration.strategyManager = strategyManager;
        _vaultStrategyConfiguration.riskManager = riskManager;
        _vaultStrategyConfiguration.optyDistributor = optyDistributor;
        _vaultStrategyConfiguration.odefiVaultBooster = odefiVaultBooster;
        _vaultStrategyConfiguration.operator = operator;
    }

    /**
     * @inheritdoc IRegistry
     */
    function getLiquidityPoolToAdapter(address _pool) public view override returns (address) {
        return liquidityPoolToAdapter[_pool];
    }

    /**
     * @inheritdoc IRegistry
     */
    function getTreasuryShares(address _vault) public view override returns (DataTypes.TreasuryShare[] memory) {
        return vaultToVaultConfiguration[_vault].treasuryShares;
    }

    function _approveToken(address _token) internal returns (bool) {
        require(_token != address(0), "!address(0)");
        require(_token.isContract(), "!isContract");
        require(!tokens[_token], "!tokens");
        tokens[_token] = true;
        emit LogToken(_token, tokens[_token], msg.sender);
        return true;
    }

    function _revokeToken(address _token) internal returns (bool) {
        require(tokens[_token], "!tokens");
        tokens[_token] = false;
        emit LogToken(_token, tokens[_token], msg.sender);
        return true;
    }

    function _approveLiquidityPool(address _pool) internal returns (bool) {
        require(_pool != address(0), "!address(0)");
        require(_pool.isContract(), "!isContract");
        require(!liquidityPools[_pool].isLiquidityPool, "!liquidityPools");
        liquidityPools[_pool].isLiquidityPool = true;
        emit LogLiquidityPool(_pool, liquidityPools[_pool].isLiquidityPool, msg.sender);
        return true;
    }

    function _revokeLiquidityPool(address _pool) internal returns (bool) {
        require(liquidityPools[_pool].isLiquidityPool, "!liquidityPools");
        liquidityPools[_pool].isLiquidityPool = false;
        emit LogLiquidityPool(_pool, liquidityPools[_pool].isLiquidityPool, msg.sender);
        return true;
    }

    function _rateLiquidityPool(address _pool, uint8 _rate) internal returns (bool) {
        require(liquidityPools[_pool].isLiquidityPool, "!liquidityPools");
        liquidityPools[_pool].rating = _rate;
        emit LogRateLiquidityPool(_pool, liquidityPools[_pool].rating, msg.sender);
        return true;
    }

    function _approveCreditPool(address _pool) internal returns (bool) {
        require(_pool != address(0), "!address(0)");
        require(_pool.isContract(), "!isContract");
        require(!creditPools[_pool].isLiquidityPool, "!creditPools");
        creditPools[_pool].isLiquidityPool = true;
        emit LogCreditPool(_pool, creditPools[_pool].isLiquidityPool, msg.sender);
        return true;
    }

    function _revokeCreditPool(address _pool) internal returns (bool) {
        require(creditPools[_pool].isLiquidityPool, "!creditPools");
        creditPools[_pool].isLiquidityPool = false;
        emit LogCreditPool(_pool, creditPools[_pool].isLiquidityPool, msg.sender);
        return true;
    }

    function _rateCreditPool(address _pool, uint8 _rate) internal returns (bool) {
        require(creditPools[_pool].isLiquidityPool, "!liquidityPools");
        creditPools[_pool].rating = _rate;
        emit LogRateCreditPool(_pool, creditPools[_pool].rating, msg.sender);
        return true;
    }

    function _setLiquidityPoolToAdapter(address _pool, address _adapter) internal returns (bool) {
        require(_adapter.isContract(), "!_adapter.isContract()");
        require(liquidityPools[_pool].isLiquidityPool || creditPools[_pool].isLiquidityPool, "!liquidityPools");
        liquidityPoolToAdapter[_pool] = _adapter;
        emit LogLiquidityPoolToAdapter(_pool, _adapter, msg.sender);
        return true;
    }

    function _setTokensHashToTokens(address[] memory _tokens) internal returns (bool) {
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            require(tokens[_tokens[_i]], "!tokens");
        }
        bytes32 _tokensHash = keccak256(abi.encodePacked(_tokens));
        require(_isNewTokensHash(_tokensHash), "!_isNewTokensHash");
        tokensHashIndexes.push(_tokensHash);
        tokensHashToTokens[_tokensHash].index = tokensHashIndexes.length - 1;
        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            tokensHashToTokens[_tokensHash].tokens.push(_tokens[_i]);
        }
        emit LogTokensToTokensHash(_tokensHash, msg.sender);
        return true;
    }

    function _setUnderlyingAssetHashToRPToVaults(
        bytes32 _underlyingAssetHash,
        uint256 _riskProfileCode,
        address _vault
    ) internal returns (bool) {
        require(_underlyingAssetHash != Constants.ZERO_BYTES32, "!underlyingAssetHash");
        require(_vault != address(0), "!address(0)");
        require(_vault.isContract(), "!isContract");
        require(riskProfiles[_riskProfileCode].exists, "!RP");
        underlyingAssetHashToRPToVaults[_underlyingAssetHash][_riskProfileCode] = _vault;
        emit LogUnderlyingAssetHashToRPToVaults(_underlyingAssetHash, _riskProfileCode, _vault, msg.sender);
        return true;
    }

    function _addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        bool _canBorrow,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) internal returns (bool) {
        require(!riskProfiles[_riskProfileCode].exists, "RP_already_exists");
        require(bytes(_name).length > 0, "RP_name_empty");
        require(bytes(_symbol).length > 0, "RP_symbol_empty");
        riskProfilesArray.push(_riskProfileCode);
        riskProfiles[_riskProfileCode].name = _name;
        riskProfiles[_riskProfileCode].symbol = _symbol;
        riskProfiles[_riskProfileCode].canBorrow = _canBorrow;
        riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit = _poolRatingRange.lowerLimit;
        riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit = _poolRatingRange.upperLimit;
        riskProfiles[_riskProfileCode].index = riskProfilesArray.length - 1;
        riskProfiles[_riskProfileCode].exists = true;

        emit LogRiskProfile(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].exists,
            riskProfiles[_riskProfileCode].canBorrow,
            msg.sender
        );
        emit LogRPPoolRatings(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit,
            riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit,
            msg.sender
        );
        return true;
    }

    function _updateRiskProfileBorrow(uint256 _riskProfileCode, bool _canBorrow) internal returns (bool) {
        require(riskProfiles[_riskProfileCode].exists, "!Rp_Exists");
        riskProfiles[_riskProfileCode].canBorrow = _canBorrow;
        emit LogRiskProfile(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].exists,
            riskProfiles[_riskProfileCode].canBorrow,
            msg.sender
        );
        return true;
    }

    function _updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        internal
        returns (bool)
    {
        require(riskProfiles[_riskProfileCode].exists, "!Rp_Exists");
        riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit = _poolRatingRange.lowerLimit;
        riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit = _poolRatingRange.upperLimit;
        emit LogRPPoolRatings(
            riskProfiles[_riskProfileCode].index,
            riskProfiles[_riskProfileCode].poolRatingsRange.lowerLimit,
            riskProfiles[_riskProfileCode].poolRatingsRange.upperLimit,
            msg.sender
        );
        return true;
    }

    function _removeRiskProfile(uint256 _index) internal returns (bool) {
        require(_index <= riskProfilesArray.length, "Invalid_Rp_index");
        uint256 _riskProfileCode = riskProfilesArray[_index];
        require(riskProfiles[_riskProfileCode].exists, "!Rp_Exists");
        riskProfiles[_riskProfileCode].exists = false;
        emit LogRiskProfile(
            _index,
            riskProfiles[_riskProfileCode].exists,
            riskProfiles[_riskProfileCode].canBorrow,
            msg.sender
        );
        return true;
    }

    /**
     * @dev Checks duplicate tokensHash
     * @param _hash Hash of the token address/addresses
     * @return A boolean value indicating whether duplicate _hash exists or not
     */
    function _isNewTokensHash(bytes32 _hash) internal view returns (bool) {
        if (tokensHashIndexes.length == 0) {
            return true;
        }
        return (tokensHashIndexes[tokensHashToTokens[_hash].index] != _hash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library Constants {
    /** @notice Zero value constant of bytes32 datatype */
    bytes32 public constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;

    /** @notice Decimals considered upto 10**18 */
    uint256 public constant WEI_DECIMAL = 10**18;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for Registry Contract
 * @author Opty.fi
 * @notice Interface of the opty.fi's protocol reegistry to store all the mappings, governance
 * operator, minter, strategist and all optyFi's protocol contract addresses
 */
interface IRegistry {
    /**
     * @notice Set the treasury accounts with their fee shares corresponding to vault contract
     * @param _vault Vault contract address
     * @param _treasuryShares Array of treasuries and their fee shares
     * @return Returns a boolean value indicating whether the operation succeeded
     */
    function setTreasuryShares(address _vault, DataTypes.TreasuryShare[] memory _treasuryShares)
        external
        returns (bool);

    /**
     * @notice Set the treasury's address for optyfi's earn protocol
     * @param _treasury Treasury's address
     * @return Returns a boolean value indicating whether the operation succeeded
     */
    function setTreasury(address _treasury) external returns (bool);

    /**
     * @notice Set the investStrategyRegistry contract address
     * @param _investStrategyRegistry InvestStrategyRegistry contract address
     * @return A boolean value indicating whether the operation succeeded
     */
    function setInvestStrategyRegistry(address _investStrategyRegistry) external returns (bool);

    /**
     * @notice Set the APROracle contract address
     * @param _aprOracle Address of APR Pracle contract to be set
     * @return A boolean value indicating whether the operation succeeded
     */
    function setAPROracle(address _aprOracle) external returns (bool);

    /**
     * @notice Set the StrategyProvider contract address
     * @param _strategyProvider Address of StrategyProvider Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setStrategyProvider(address _strategyProvider) external returns (bool);

    /**
     * @notice Set the RiskManager's contract address
     * @param _riskManager Address of RiskManager Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setRiskManager(address _riskManager) external returns (bool);

    /**
     * @notice Set the HarvestCodeProvider contract address
     * @param _harvestCodeProvider Address of HarvestCodeProvider Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setHarvestCodeProvider(address _harvestCodeProvider) external returns (bool);

    /**
     * @notice Set the StrategyManager contract address
     * @param _strategyManager Address of StrategyManager Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setStrategyManager(address _strategyManager) external returns (bool);

    /**
     * @notice Set the $OPTY token's contract address
     * @param _opty Address of Opty Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setOPTY(address _opty) external returns (bool);

    /**
     * @notice Set the PriceOracle contract address
     * @param _priceOracle Address of PriceOracle Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setPriceOracle(address _priceOracle) external returns (bool);

    /**
     * @notice Set the OPTYStakingRateBalancer contract address
     * @param _optyStakingRateBalancer Address of OptyStakingRateBalancer Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setOPTYStakingRateBalancer(address _optyStakingRateBalancer) external returns (bool);

    /**
     * @notice Set the ODEFIVaultBooster contract address
     * @dev Can only be called by the current governance
     * @param _odefiVaultBooster address of the ODEFIVaultBooster Contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setODEFIVaultBooster(address _odefiVaultBooster) external returns (bool);

    /**
     * @dev Sets multiple `_token` from the {tokens} mapping.
     * @notice Approves multiple tokens in one transaction
     * @param _tokens List of tokens to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveToken(address[] memory _tokens) external returns (bool);

    /**
     * @notice Approves the token provided
     * @param _token token to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveToken(address _token) external returns (bool);

    /**
     * @notice Disable multiple tokens in one transaction
     * @param _tokens List of tokens to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeToken(address[] memory _tokens) external returns (bool);

    /**
     * @notice Disable the token
     * @param _token token to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeToken(address _token) external returns (bool);

    /**
     * @notice Approves multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveLiquidityPool(address[] memory _pools) external returns (bool);

    /**
     * @notice For approving single liquidity pool
     * @param _pool liquidity/credit pool to approve
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveLiquidityPool(address _pool) external returns (bool);

    /**
     * @notice Revokes multiple liquidity pools in one transaction
     * @param _pools list of liquidity/credit pools to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeLiquidityPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Revokes the liquidity pool
     * @param _pool liquidity/credit pool to revoke
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeLiquidityPool(address _pool) external returns (bool);

    /**
     * @notice Sets multiple pool rates and liquidity pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateLiquidityPool(DataTypes.PoolRate[] memory _poolRates) external returns (bool);

    /**
     * @notice Sets the pool rate for the liquidity pool provided
     * @param _pool liquidityPool to map with its rating
     * @param _rate rate for the liquidityPool provided
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateLiquidityPool(address _pool, uint8 _rate) external returns (bool);

    /**
     * @notice Approves multiple credit pools in one transaction
     * @param _pools List of pools for approval to be considered as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveCreditPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Approves the credit pool
     * @param _pool credit pool address to be approved
     * @return A boolean value indicating whether the operation succeeded
     */
    function approveCreditPool(address _pool) external returns (bool);

    /**
     * @notice Revokes multiple credit pools in one transaction
     * @param _pools List of pools for revoking from being used as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeCreditPool(address[] memory _pools) external returns (bool);

    /**
     * @notice Revokes the credit pool
     * @param _pool pool for revoking from being used as creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function revokeCreditPool(address _pool) external returns (bool);

    /**
     * @notice Sets the multiple pool rates and credit pools provided
     * @param _poolRates List of pool rates ([_pool, _rate]) to set for creditPool
     * @return A boolean value indicating whether the operation succeeded
     */
    function rateCreditPool(DataTypes.PoolRate[] memory _poolRates) external returns (bool);

    /**
     * @notice Sets the pool rate for the credit pool provided
     * @param _pool creditPool to map with its rating
     * @param _rate rate for the creaditPool provided
     * @return A boolean value indicating whether the operation succeeded.
     */
    function rateCreditPool(address _pool, uint8 _rate) external returns (bool);

    /**
     * @notice Maps multiple liquidity pools to their protocol adapters
     * @param _poolAdapters List of [pool, adapter] pairs to set
     * @return A boolean value indicating whether the operation succeeded
     */
    function setLiquidityPoolToAdapter(DataTypes.PoolAdapter[] memory _poolAdapters) external returns (bool);

    /**
     * @notice Maps liquidity pool to its protocol adapter
     * @param _pool liquidityPool to map with its adapter
     * @param _adapter adapter for the liquidityPool provided
     * @return A boolean value indicating whether the operation succeeded
     */
    function setLiquidityPoolToAdapter(address _pool, address _adapter) external returns (bool);

    /**
     * @notice Maps multiple token pairs to their keccak256 hash
     * @param _setOfTokens List of mulitple token addresses to map with their (paired tokens) hashes
     * @return A boolean value indicating whether the operation succeeded
     */
    function setTokensHashToTokens(address[][] memory _setOfTokens) external returns (bool);

    /**
     * @notice Sets token pair to its keccak256 hash
     * @param _tokens List of token addresses to map with their hashes
     * @return A boolean value indicating whether the operation succeeded
     */
    function setTokensHashToTokens(address[] memory _tokens) external returns (bool);

    /**
     * @notice Maps the Vault contract with underlying assets and riskProfile
     * @param _vault Vault contract address
     * @param _riskProfileCode Risk profile mapped to the vault contract
     * @param _underlyingAssets List of token addresses to map with the riskProfile and Vault contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[] memory _underlyingAssets,
        uint256 _riskProfileCode,
        address _vault
    ) external returns (bool);

    /**
     * @notice Set the withdrawal fee's range
     * @param _withdrawalFeeRange the withdrawal fee's range
     * @return _success Returns a boolean value indicating whether the operation succeeded
     */
    function setWithdrawalFeeRange(DataTypes.WithdrawalFeeRange memory _withdrawalFeeRange)
        external
        returns (bool _success);

    /**
     * @notice Set the withdrawal fee for the vault contract
     * @param _vault Vault contract address
     * @param _withdrawalFee Withdrawal fee to be set for vault contract
     * @return _success Returns a boolean value indicating whether the operation succeeded
     */
    function setWithdrawalFee(address _vault, uint256 _withdrawalFee) external returns (bool _success);

    /**
     * @notice Maps mulitple underlying tokens to risk profiles to vault contracts address
     * @param _vaults List of Vault contract address
     * @param _riskProfileCodes List of Risk profile codes mapped to the vault contract
     * @param _underlyingAssets List of paired token addresses to map with the riskProfile and Vault contract
     * @return A boolean value indicating whether the operation succeeded
     */
    function setUnderlyingAssetHashToRPToVaults(
        address[][] memory _underlyingAssets,
        uint256[] memory _riskProfileCodes,
        address[][] memory _vaults
    ) external returns (bool);

    /**
     * @notice Discontinue the Vault contract from use permanently
     * @dev Once Vault contract is disconitnued, then it CAN NOT be re-activated for usage
     * @param _vault Vault address to discontinue
     * @return A boolean value indicating whether operation is succeeded
     */
    function discontinue(address _vault) external returns (bool);

    /**
     * @notice Pause/Unpause tha Vault contract for use temporarily during any emergency
     * @param _vault Vault contract address to pause
     * @param _unpaused A boolean value true to unpause vault contract and false for pause vault contract
     */
    function unpauseVaultContract(address _vault, bool _unpaused) external returns (bool);

    /**
     * @notice Adds the risk profile in Registry contract Storage
     * @param _riskProfileCode code of riskProfile
     * @param _name name of riskProfile
     * @param _symbol symbol of riskProfile
     * @param _canBorrow A boolean value indicating whether the riskProfile allows borrow step
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) supported by given risk profile
     * @return A boolean value indicating whether the operation succeeded
     */
    function addRiskProfile(
        uint256 _riskProfileCode,
        string memory _name,
        string memory _symbol,
        bool _canBorrow,
        DataTypes.PoolRatingsRange memory _poolRatingRange
    ) external returns (bool);

    /**
     * @notice Adds list of the risk profiles in Registry contract Storage in one transaction
     * @dev All parameters must be in the same order.
     * @param _riskProfileCodes codes of riskProfiles
     * @param _names names of riskProfiles
     * @param _symbols symbols of riskProfiles
     * @param _canBorrow List of boolean values indicating whether the riskProfile allows borrow step
     * @param _poolRatingRanges List of pool rating range supported by given list of risk profiles
     * @return A boolean value indicating whether the operation succeeded
     */
    function addRiskProfile(
        uint256[] memory _riskProfileCodes,
        string[] memory _names,
        string[] memory _symbols,
        bool[] memory _canBorrow,
        DataTypes.PoolRatingsRange[] memory _poolRatingRanges
    ) external returns (bool);

    /**
     * @notice Change the borrow permission for existing risk profile
     * @param _riskProfileCode Risk profile code (Eg: 1,2, and so on where 0 is reserved for 'no strategy')
     * to update with strategy steps
     * @param _canBorrow A boolean value indicating whether the riskProfile allows borrow step
     * @return A boolean value indicating whether the operation succeeded
     */
    function updateRiskProfileBorrow(uint256 _riskProfileCode, bool _canBorrow) external returns (bool);

    /**
     * @notice Update the pool ratings for existing risk profile
     * @param _riskProfileCode Risk profile code (Eg: 1,2, and so on where 0 is reserved for 'no strategy')
     * to update with pool rating range
     * @param _poolRatingRange pool rating range ([lowerLimit, upperLimit]) to update for given risk profile
     * @return A boolean value indicating whether the operation succeeded
     */
    function updateRPPoolRatings(uint256 _riskProfileCode, DataTypes.PoolRatingsRange memory _poolRatingRange)
        external
        returns (bool);

    /**
     * @notice Remove the existing risk profile in Registry contract Storage
     * @param _index Index of risk profile to be removed
     * @return A boolean value indicating whether the operation succeeded
     */
    function removeRiskProfile(uint256 _index) external returns (bool);

    /**
     * @notice Get the list of tokensHash
     * @return Returns the list of tokensHash.
     */
    function getTokenHashes() external view returns (bytes32[] memory);

    /**
     * @notice Get list of token given the tokensHash
     * @return Returns the list of tokens corresponding to tokensHash
     */
    function getTokensHashToTokenList(bytes32 _tokensHash) external view returns (address[] memory);

    /**
     * @notice Get the list of all the riskProfiles
     * @return Returns the list of all riskProfiles stored in Registry Storage
     */
    function getRiskProfileList() external view returns (uint256[] memory);

    /**
     * @notice Retrieve the StrategyManager contract address
     * @return Returns the StrategyManager contract address
     */
    function getStrategyManager() external view returns (address);

    /**
     * @notice Retrieve the StrategyProvider contract address
     * @return Returns the StrategyProvider contract address
     */
    function getStrategyProvider() external view returns (address);

    /**
     * @notice Retrieve the InvestStrategyRegistry contract address
     * @return Returns the InvestStrategyRegistry contract address
     */
    function getInvestStrategyRegistry() external view returns (address);

    /**
     * @notice Retrieve the RiskManager contract address
     * @return Returns the RiskManager contract address
     */
    function getRiskManager() external view returns (address);

    /**
     * @notice Retrieve the OPTYDistributor contract address
     * @return Returns the OPTYDistributor contract address
     */
    function getOPTYDistributor() external view returns (address);

    /**
     * @notice Retrieve the ODEFIVaultBooster contract address
     * @return Returns the ODEFIVaultBooster contract address
     */
    function getODEFIVaultBooster() external view returns (address);

    /**
     * @notice Retrieve the Governance address
     * @return Returns the Governance address
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Retrieve the FinanceOperator address
     * @return Returns the FinanceOperator address
     */
    function getFinanceOperator() external view returns (address);

    /**
     * @notice Retrieve the RiskOperator address
     * @return Returns the RiskOperator address
     */
    function getRiskOperator() external view returns (address);

    /**
     * @notice Retrieve the StrategyOperator address
     * @return Returns the StrategyOperator address
     */
    function getStrategyOperator() external view returns (address);

    /**
     * @notice Retrieve the Operator address
     * @return Returns the Operator address
     */
    function getOperator() external view returns (address);

    /**
     * @notice Retrieve the HarvestCodeProvider contract address
     * @return Returns the HarvestCodeProvider contract address
     */
    function getHarvestCodeProvider() external view returns (address);

    /**
     * @notice Retrieve the AprOracle contract address
     * @return Returns the AprOracle contract address
     */
    function getAprOracle() external view returns (address);

    /**
     * @notice Retrieve the OPTYStakingRateBalancer contract address
     * @return Returns the OPTYStakingRateBalancer contract address
     */
    function getOPTYStakingRateBalancer() external view returns (address);

    /**
     * @notice Get the configuration of vault contract
     * @return _vaultConfiguration Returns the configuration of vault contract
     */
    function getVaultConfiguration(address _vault)
        external
        view
        returns (DataTypes.VaultConfiguration memory _vaultConfiguration);

    /**
     * @notice Get the properties corresponding to riskProfile code provided
     * @return _riskProfile Returns the properties corresponding to riskProfile provided
     */
    function getRiskProfile(uint256) external view returns (DataTypes.RiskProfile memory _riskProfile);

    /**
     * @notice Get the index corresponding to tokensHash provided
     * @param _tokensHash Hash of token address/addresses
     * @return _index Returns the index corresponding to tokensHash provided
     */
    function getTokensHashIndexByHash(bytes32 _tokensHash) external view returns (uint256 _index);

    /**
     * @notice Get the tokensHash available at the index provided
     * @param _index Index at which you want to get the tokensHash
     * @return _tokensHash Returns the tokensHash available at the index provided
     */
    function getTokensHashByIndex(uint256 _index) external view returns (bytes32 _tokensHash);

    /**
     * @notice Get the rating and Is pool a liquidity pool for the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _liquidityPool Returns the rating and Is pool a liquidity pool for the _pool provided
     */
    function getLiquidityPool(address _pool) external view returns (DataTypes.LiquidityPool memory _liquidityPool);

    /**
     * @notice Get the configuration related to Strategy contracts
     * @return _strategyConfiguration Returns the configuration related to Strategy contracts
     */
    function getStrategyConfiguration()
        external
        view
        returns (DataTypes.StrategyConfiguration memory _strategyConfiguration);

    /**
     * @notice Get the contract address required as part of strategy by vault contract
     * @return _vaultStrategyConfiguration Returns the configuration related to Strategy for Vault contracts
     */
    function getVaultStrategyConfiguration()
        external
        view
        returns (DataTypes.VaultStrategyConfiguration memory _vaultStrategyConfiguration);

    /**
     * @notice Get the adapter address mapped to the _pool provided
     * @param _pool Liquidity Pool (like cDAI etc.) address
     * @return _adapter Returns the adapter address mapped to the _pool provided
     */
    function getLiquidityPoolToAdapter(address _pool) external view returns (address _adapter);

    /**
     * @notice Get the treasury accounts with their fee shares corresponding to vault contract
     * @param _vault Vault contract address
     * @return Returns Treasuries along with their fee shares
     */
    function getTreasuryShares(address _vault) external view returns (DataTypes.TreasuryShare[] memory);

    /**
     * @notice Check if the token is approved or not
     * @param _token Token address for which to check if it is approved or not
     * @return _isTokenApproved Returns a boolean for token approved or not
     */
    function isApprovedToken(address _token) external view returns (bool _isTokenApproved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for opty.fi's interest bearing vault
 * @author opty.fi
 * @notice Contains mix of permissioned and permissionless vault methods
 */
interface IVault {
    /**
     * @notice Set maximum standard deviation of vault value in a single block
     * @dev the maximum vault value jump is in percentage basis points set by governance
     * @param _maxVaultValueJump the standard deviation from a vault value in basis points
     * @return return true on successful setting of the max vault value jump
     */
    function setMaxVaultValueJump(uint256 _maxVaultValueJump) external returns (bool);

    /**
     * @notice Calculate the value of a vault share in underlying token
     * @dev It should only be called if the current strategy's last step is Curve
     * @return the underlying token worth a vault share is
     */
    function getPricePerFullShareWrite() external returns (uint256);

    /**
     * @notice Withdraw the underying asset of vault from previous strategy if any,
     *         claims and swaps the reward tokens for the underlying token
     *         performs batch minting of shares for users deposited previously without rebalance,
     *         deposits the assets into the new strategy if any or holds the same in the vault
     * @dev the vault will be charged to compensate gas fees if operator calls this function
     */
    function rebalance() external;

    /**
     * @notice Claim the rewards if any strategy have it and swap for underlying token
     * @param _investStrategyHash vault invest strategy hash
     */
    function harvest(bytes32 _investStrategyHash) external;

    /**
     * @notice A cheap function to deposit whole underlying token's balance
     * @dev this function does not rebalance, hence vault shares will be minted on the next rebalance
     */
    function userDepositAll() external;

    /**
     * @notice A cheap function to deposit _amount of underlying token to the vault
     * @dev the user will receive vault shares on next rebalance
     * @param _amount the amount of the underlying token to be deposited
     * @return returns true on successful depositing underlying token without rebalance
     */
    function userDeposit(uint256 _amount) external returns (bool);

    /**
     * @notice Deposit full balance in underlying token of the caller and rebalance
     * @dev the vault shares are minted right away
     */
    function userDepositAllRebalance() external;

    /**
     * @notice Deposit amount of underlying token of caller and rebalance
     * @dev the vault shares are minted right away
     * @param _amount the amount of the underlying token
     * @return returns true on successful deposit of the underlying token
     */
    function userDepositRebalance(uint256 _amount) external returns (bool);

    /**
     * @notice Redeem full balance of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault
     */
    function userWithdrawAllRebalance() external;

    /**
     * @notice Redeem the amount of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault
     * @param _redeemAmount the vault shares to redeem
     * @return bool returns true on successful redemption of the vault shares
     */
    function userWithdrawRebalance(uint256 _redeemAmount) external returns (bool);

    /**
     * @notice A cheap function to deposit whole underlying token's balance of caller
     * @dev the gas fees are paid in $CHI tokens and vault shares are minted on next rebalance
     */
    function userDepositAllWithCHI() external;

    /**
     * @notice A cheap function to deposit amount of underlying token's balance of caller
     * @dev the gas fees are paid in $CHI tokens and vault shares are minted on next rebalance
     * @param _amount the amount of underlying tokens to be deposited
     */
    function userDepositWithCHI(uint256 _amount) external;

    /**
     * @notice Deposit full balance in underlying token of the caller and rebalance
     * @dev the vault shares are minted right away and gas fees are paid in $CHI tokens
     */
    function userDepositAllRebalanceWithCHI() external;

    /**
     * @notice Deposit amount of underlying token of caller and rebalance
     * @dev the vault shares are minted right away and gas fees are paid in $CHI tokens
     * @param _amount the amount of the underlying token
     */
    function userDepositRebalanceWithCHI(uint256 _amount) external;

    /**
     * @notice Redeem full balance of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault and gas fees are paid in $CHI tokens
     */
    function userWithdrawAllRebalanceWithCHI() external;

    /**
     * @notice Redeem the amount of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault and gas fees are paid in $CHI tokens
     * @param _redeemAmount the amount of vault shares
     */
    function userWithdrawRebalanceWithCHI(uint256 _redeemAmount) external;

    /**
     * @notice Recall vault investments from current strategy, restricts deposits
     *         and allows redemption of the shares
     * @dev this function can be invoked by governance via registry
     */
    function discontinue() external;

    /**
     * @notice This function can temporarily restrict user from depositing
     *         or withdrawing assets to and from the vault
     * @dev this function can be invoked by governance via registry
     * @param _unpaused for invoking/revoking pause over the vault
     */
    function setUnpaused(bool _unpaused) external;

    /**
     * @notice Retrieve underlying token balance in the vault
     * @return The balance of underlying token in the vault
     */
    function balance() external view returns (uint256);

    /**
     * @notice Calculate the value of a vault share in underlying token
     * @return The underlying token worth a vault share is
     */
    function getPricePerFullShare() external view returns (uint256);

    /**
     * @notice Assign a risk profile name
     * @dev name of the risk profile should be approved by governance
     * @param _riskProfileCode code of the risk profile
     * @return returns true on successfully setting risk profile name.
     */
    function setRiskProfileCode(uint256 _riskProfileCode) external returns (bool);

    /**
     * @notice Assign the address of the underlying asset of the vault
     * @dev the underlying asset should be approved by the governance
     * @param _underlyingToken the address of the underlying asset
     * @return return true on successful persisting underlying asset address
     */
    function setToken(address _underlyingToken) external returns (bool);

    /**
     * @dev A helper function to validate the vault value will not be deviated from max vault value
     *      within the same block
     * @param _diff absolute difference between minimum and maximum vault value within a block
     * @param _currentVaultValue the underlying token balance of the vault
     * @return bool returns true if vault value jump is within permissible limits
     */
    function isMaxVaultValueJumpAllowed(uint256 _diff, uint256 _currentVaultValue) external view returns (bool);

    /**
     * @notice A function to be called in case vault needs to claim and harvest tokens in case a strategy
     *         provides multiple reward tokens
     * @param _codes Array of encoded data in bytes which acts as code to execute
     * @return return true on successful admin call
     */
    function adminCall(bytes[] memory _codes) external returns (bool);

    /**
     * @notice A function to get deposit queue
     * @return return queue
     */
    function getDepositQueue() external view returns (DataTypes.UserDepositOperation[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  helper contracts
import { RegistryStorage } from "./RegistryStorage.sol";
import { ModifiersController } from "./ModifiersController.sol";

/**
 * @title RegistryProxy Contract
 * @author Opty.fi
 * @dev Storage for the Registry is at this address,
 * while execution is delegated to the `registryImplementation`.
 * Registry should reference this contract as their controller.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract RegistryProxy is RegistryStorage, ModifiersController {
    /**
     * @notice Emitted when pendingComptrollerImplementation is changed
     * @param oldPendingImplementation Old Registry contract's implementation address which is still pending
     * @param newPendingImplementation New Registry contract's implementation address which is still pending
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingComptrollerImplementation is updated
     * @param oldImplementation Old Registry Contract's implementation address
     * @param newImplementation New Registry Contract's implementation address
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingGovernance is changed
     * @param oldPendingGovernance Old Governance's address which is still pending
     * @param newPendingGovernance New Governance's address which is still pending
     */
    event NewPendingGovernance(address oldPendingGovernance, address newPendingGovernance);

    /**
     * @notice Emitted when pendingGovernance is accepted, which means governance is updated
     * @param oldGovernance Old Governance's address
     * @param newGovernance New Governance's address
     */
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor() public {
        governance = msg.sender;
        setFinanceOperator(msg.sender);
        setRiskOperator(msg.sender);
        setStrategyOperator(msg.sender);
        setOperator(msg.sender);
        setOPTYDistributor(msg.sender);
    }

    /* solhint-disable */
    receive() external payable {
        revert();
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev Returns to external caller whatever implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = registryImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    /* solhint-disable */

    /*** Admin Functions ***/
    /**
     * @dev Set the registry contract as pending implementation initally
     * @param newPendingImplementation registry address to act as pending implementation
     */
    function setPendingImplementation(address newPendingImplementation) external onlyOperator {
        address oldPendingImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);
    }

    /**
     * @notice Accepts new implementation of registry
     * @dev Governance function for new implementation to accept it's role as implementation
     */
    function acceptImplementation() external returns (uint256) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(
            msg.sender == pendingRegistryImplementation && pendingRegistryImplementation != address(0),
            "!pendingRegistryImplementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = registryImplementation;
        address oldPendingImplementation = pendingRegistryImplementation;

        registryImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = address(0);

        emit NewImplementation(oldImplementation, registryImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);

        return uint256(0);
    }

    /**
     * @notice Transfers the governance rights
     * @dev The newPendingGovernance must call acceptGovernance() to finalize the transfer
     * @param newPendingGovernance New pending governance address
     */
    function setPendingGovernance(address newPendingGovernance) external onlyOperator {
        // Save current value, if any, for inclusion in log
        address oldPendingGovernance = pendingGovernance;

        // Store pendingGovernance with value newPendingGovernance
        pendingGovernance = newPendingGovernance;

        // Emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance)
        emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance);
    }

    /**
     * @notice Accepts transfer of Governance rights
     * @dev Governance function for pending governance to accept role and update Governance
     */
    function acceptGovernance() external returns (uint256) {
        require(msg.sender == pendingGovernance && msg.sender != address(0), "!pendingGovernance");

        // Save current values for inclusion in log
        address oldGovernance = governance;
        address oldPendingGovernance = pendingGovernance;

        // Store admin with value pendingGovernance
        governance = pendingGovernance;

        // Clear the pending value
        pendingGovernance = address(0);

        emit NewGovernance(oldGovernance, governance);
        emit NewPendingGovernance(oldPendingGovernance, pendingGovernance);
        return uint256(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

//  helper contracts
import { RegistryStorage } from "./RegistryStorage.sol";

//  interfaces
import { IModifiersController } from "../../interfaces/opty/IModifiersController.sol";

/**
 * @title ModifiersController Contract
 * @author Opty.fi
 * @notice Contract used by registry contract and acts as source of truth
 * @dev It manages operator, optyDistributor addresses as well as modifiers
 */
abstract contract ModifiersController is IModifiersController, RegistryStorage {
    using Address for address;

    /**
     * @inheritdoc IModifiersController
     */
    function setFinanceOperator(address _financeOperator) public override onlyGovernance {
        require(_financeOperator != address(0), "!address(0)");
        financeOperator = _financeOperator;
        emit TransferFinanceOperator(financeOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setRiskOperator(address _riskOperator) public override onlyGovernance {
        require(_riskOperator != address(0), "!address(0)");
        riskOperator = _riskOperator;
        emit TransferRiskOperator(riskOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setStrategyOperator(address _strategyOperator) public override onlyGovernance {
        require(_strategyOperator != address(0), "!address(0)");
        strategyOperator = _strategyOperator;
        emit TransferStrategyOperator(strategyOperator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOperator(address _operator) public override onlyGovernance {
        require(_operator != address(0), "!address(0)");
        operator = _operator;
        emit TransferOperator(operator, msg.sender);
    }

    /**
     * @inheritdoc IModifiersController
     */
    function setOPTYDistributor(address _optyDistributor) public override onlyGovernance {
        require(_optyDistributor != address(0), "!address(0)");
        optyDistributor = _optyDistributor;
        emit TransferOPTYDistributor(optyDistributor, msg.sender);
    }

    /**
     * @notice Modifier to check caller is governance or not
     */
    modifier onlyGovernance() {
        require(msg.sender == governance, "caller is not having governance");
        _;
    }

    /**
     * @notice Modifier to check caller is financeOperator or not
     */
    modifier onlyFinanceOperator() {
        require(msg.sender == financeOperator, "caller is not the finance operator");
        _;
    }

    /**
     * @notice Modifier to check caller is riskOperator or not
     */
    modifier onlyRiskOperator() {
        require(msg.sender == riskOperator, "caller is not the risk operator");
        _;
    }

    /**
     * @notice Modifier to check caller is operator or not
     */
    modifier onlyOperator() {
        require(msg.sender == operator, "caller is not the operator");
        _;
    }

    /**
     * @notice Modifier to check caller is optyDistributor or not
     */
    modifier onlyOptyDistributor() {
        require(msg.sender == optyDistributor, "caller is not the optyDistributor");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library DataTypes {
    /**
     * @notice Container for User Deposit/withdraw operations
     * @param account User's address
     * @param isDeposit True if it is deposit and false if it withdraw
     * @param value Amount to deposit/withdraw
     */
    struct UserDepositOperation {
        address account;
        uint256 value;
    }

    /**
     * @notice Container for token balance in vault contract in a specific block
     * @param actualVaultValue current balance of the vault contract
     * @param blockMinVaultValue minimum balance recorded for vault contract in the same block
     * @param blockMaxVaultValue maximum balance recorded for vault contract in the same block
     */
    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    /**
     * @notice Container for Strategy Steps used by Strategy
     * @param pool Liquidity Pool address
     * @param outputToken Output token of the liquidity pool
     * @param isBorrow If borrow is allowed or not for the liquidity pool
     */
    struct StrategyStep {
        address pool;
        address outputToken;
        bool isBorrow;
    }

    /**
     * @notice Container for pool's configuration
     * @param rating Rating of the liquidity pool
     * @param isLiquidityPool If pool is enabled as liquidity pool
     */
    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    /**
     * @notice Container for Strategy used by Vault contract
     * @param index Index at which strategy is stored
     * @param strategySteps StrategySteps consisting pool, outputToken and isBorrow
     */
    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    /**
     * @notice Container for all Tokens
     * @param index Index at which token is stored
     * @param tokens List of token addresses
     */
    struct Token {
        uint256 index;
        address[] tokens;
    }

    /**
     * @notice Container for pool and its rating
     * @param pool Address of liqudity pool
     * @param rate Value to be set as rate for the liquidity pool
     */
    struct PoolRate {
        address pool;
        uint8 rate;
    }

    /**
     * @notice Container for mapping the liquidity pool and adapter
     * @param pool liquidity pool address
     * @param adapter adapter contract address corresponding to pool
     */
    struct PoolAdapter {
        address pool;
        address adapter;
    }

    /**
     * @notice Container for having limit range for the pools
     * @param lowerLimit liquidity pool rate's lower limit
     * @param upperLimit liquidity pool rate's upper limit
     */
    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    /**
     * @notice Container for having limit range for withdrawal fee
     * @param lowerLimit withdrawal fee's lower limit
     * @param upperLimit withdrawal fee's upper limit
     */
    struct WithdrawalFeeRange {
        uint256 lowerLimit;
        uint256 upperLimit;
    }

    /**
     * @notice Container for containing risk Profile's configuration
     * @param index Index at which risk profile is stored
     * @param canBorrow True if borrow is allowed for the risk profile
     * @param poolRatingsRange Container for having limit range for the pools
     * @param exists if risk profile exists or not
     */
    struct RiskProfile {
        uint256 index;
        bool canBorrow;
        PoolRatingsRange poolRatingsRange;
        bool exists;
        string name;
        string symbol;
    }

    /**
     * @notice Container for holding percentage of reward token to hold and convert
     * @param hold reward token hold percentage in basis point
     * @param convert reward token convert percentage in basis point
     */
    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    /** @notice Named Constants for defining max exposure state */
    enum MaxExposure { Number, Pct }

    /** @notice Named Constants for defining default strategy state */
    enum DefaultStrategyState { Zero, CompoundOrAave }

    /**
     * @notice Container for persisting ODEFI contract's state
     * @param index The market's last index
     * @param timestamp The block number the index was last updated at
     */
    struct RewardsState {
        uint224 index;
        uint32 timestamp;
    }

    /**
     * @notice Container for Treasury accounts along with their shares
     * @param treasury treasury account address
     * @param share treasury's share in percentage from the withdrawal fee
     */
    struct TreasuryShare {
        address treasury;
        uint256 share; //  should be in basis eg: 5% means 500
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param discontinued If the vault contract is discontinued or not
     * @param unpaused If the vault contract is paused or unpaused
     * @param withdrawalFee withdrawal fee for a particular vault contract
     * @param treasuryShares Treasury accounts along with their shares
     */
    struct VaultConfiguration {
        bool discontinued;
        bool unpaused;
        uint256 withdrawalFee; //  should be in basis eg: 15% means 1500
        TreasuryShare[] treasuryShares;
    }

    /**
     * @notice Container for persisting all strategy related contract's configuration
     * @param investStrategyRegistry investStrategyRegistry contract address
     * @param strategyProvider strategyProvider contract address
     * @param aprOracle aprOracle contract address
     */
    struct StrategyConfiguration {
        address investStrategyRegistry;
        address strategyProvider;
        address aprOracle;
    }

    /**
     * @notice Container for persisting contract addresses required by vault contract
     * @param strategyManager strategyManager contract address
     * @param riskManager riskManager contract address
     * @param optyDistributor optyDistributor contract address
     * @param operator operator contract address
     */
    struct VaultStrategyConfiguration {
        address strategyManager;
        address riskManager;
        address optyDistributor;
        address odefiVaultBooster;
        address operator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

/* solhint-disable max-states-count */
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title RegistryAdminStorage Contract
 * @author Opty.fi
 * @dev Contract used to store registry's admin account
 */
contract RegistryAdminStorage {
    /**
     * @notice Governance of optyfi's earn protocol
     */
    address public governance;

    /**
     * @notice Finance operator of optyfi's earn protocol
     * @dev Handle functions having withdrawal fee, treasury and finance related logic
     */
    address public financeOperator;

    /**
     * @notice Risk operator of optyfi's earn protocol
     * @dev Handle functions for maintaining the risk profiles and rating of liquidity/credit pools
     */
    address public riskOperator;

    /**
     * @notice Strategy operator of optyfi's earn protocol
     * @dev Handle functions related to strategies/vault strategies to be used
     */
    address public strategyOperator;

    /**
     * @notice Operator of optyfi's earn protocol
     */
    address public operator;

    /**
     * @notice Treasury of optyfi's earn protocol
     */
    address public treasury;

    /**
     * @notice Distributor for OPTY token
     */
    address public optyDistributor;

    /**
     * @notice Pending governance for optyfi's earn protocol
     */
    address public pendingGovernance;

    /**
     * @notice Active brains of Registry
     */
    address public registryImplementation;

    /**
     * @notice Pending brains of Registry
     */
    address public pendingRegistryImplementation;

    /**
     * @notice notify when transfer operation of financeOperator occurs
     * @param financeOperator address of Finance operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferFinanceOperator(address indexed financeOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of riskOperator occurs
     * @param riskOperator address of Risk operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferRiskOperator(address indexed riskOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of strategyOperator occurs
     * @param strategyOperator address of Strategy operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferStrategyOperator(address indexed strategyOperator, address indexed caller);

    /**
     * @notice notify when transfer operation of operator occurs
     * @param operator address of Operator of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferOperator(address indexed operator, address indexed caller);

    /**
     * @notice notify when transfer operation of treasury occurs
     * @param treasury address of Treasury of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferTreasury(address indexed treasury, address indexed caller);

    /**
     * @notice notify when transfer operation of optyDistributor occurs
     * @param optyDistributor address of Opty distributor of optyfi's earn protocol
     * @param caller address of user who has called the respective function to trigger this event
     */
    event TransferOPTYDistributor(address indexed optyDistributor, address indexed caller);
}

/**
 * @title RegistryStorage Contract
 * @author Opty.fi
 * @dev Contract used to store registry's contract state variables and events
 */
contract RegistryStorage is RegistryAdminStorage {
    /**
     * @notice token address status which are approved or not
     */
    mapping(address => bool) public tokens;

    /**
     * @notice token data mapped to token/tokens address/addresses hash
     */
    mapping(bytes32 => DataTypes.Token) public tokensHashToTokens;

    /**
     * @notice liquidityPool address mapped to its struct having `pool`, `outputToken`, `isBorrow`
     */
    mapping(address => DataTypes.LiquidityPool) public liquidityPools;

    /**
     * @notice creaditPool address mapped to its struct having `pool`, `outputToken`, `isBorrow`
     */
    mapping(address => DataTypes.LiquidityPool) public creditPools;

    /**
     * @notice liquidityPool address mapped to its adapter
     */
    mapping(address => address) public liquidityPoolToAdapter;

    /**
     * @notice underlying asset (token address's hash) mapped to riskProfileCode and vault contract
     *         address for keeping track of all the vault contracts
     */
    mapping(bytes32 => mapping(uint256 => address)) public underlyingAssetHashToRPToVaults;

    /**
     * @dev riskProfileCode mapped to its struct `RiskProfile`
     */
    mapping(uint256 => DataTypes.RiskProfile) internal riskProfiles;

    /**
     * @notice vault contract address mapped to VaultConfiguration
     */
    mapping(address => DataTypes.VaultConfiguration) public vaultToVaultConfiguration;

    /**
     * @notice withdrawal fee's range
     */
    DataTypes.WithdrawalFeeRange public withdrawalFeeRange;

    /**
     * @notice List of all the tokenHashes
     */
    bytes32[] public tokensHashIndexes;

    /**
     * @notice List of all the riskProfiles
     */
    uint256[] public riskProfilesArray;

    /**
     * @notice strategyProvider contract address
     */
    address public strategyProvider;

    /**
     * @notice investStrategyRegistry contract address
     */
    address public investStrategyRegistry;

    /**
     * @notice riskManager contract address
     */
    address public riskManager;

    /**
     * @notice harvestCodeProvider contract address
     */
    address public harvestCodeProvider;

    /**
     * @notice strategyManager contract address
     */
    address public strategyManager;

    /**
     * @notice priceOracle contract address
     */
    address public priceOracle;

    /**
     * @notice opty contract address
     */
    address public opty;

    /**
     * @notice aprOracle contract address
     */
    address public aprOracle;

    /**
     * @notice optyStakingRateBalancer contract address
     */
    address public optyStakingRateBalancer;

    /**
     * @notice OD vaultBooster contract address
     */
    address public odefiVaultBooster;

    /**
     * @notice Emitted when token is approved or revoked
     * @param token Underlying Token's address which is approved or revoked
     * @param enabled Token is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogToken(address indexed token, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when pool is approved or revoked as liquidity pool
     * @param pool Liquidity Pool's address which is approved or revoked
     * @param enabled Liquidity Pool is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogLiquidityPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when pool is approved or revoked as credit pool
     * @param pool Credit Pool's address which is approved or revoked
     * @param enabled Credit pool is approved (true) or revoked (false)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogCreditPool(address indexed pool, bool indexed enabled, address indexed caller);

    /**
     * @notice Emitted when liquidity pool is rated
     * @param pool Liquidity Pool's address which is rated
     * @param rate Rating of Liquidity Pool set
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRateLiquidityPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @notice Emitted when credit pool is rated
     * @param pool Credit Pool's address which is rated
     * @param rate Rating of Credit Pool set
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRateCreditPool(address indexed pool, uint8 indexed rate, address indexed caller);

    /**
     * @notice Emitted when liquidity pool pool is assigned to adapter
     * @param pool Liquidity Pool's address which is mapped to the adapter
     * @param adapter Address of the respective OptyFi's defi-adapter contract which is mapped to the Liquidity Pool
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogLiquidityPoolToAdapter(address indexed pool, address indexed adapter, address indexed caller);

    /**
     * @notice Emitted when tokens are assigned to tokensHash
     * @param tokensHash Hash of the token/list of tokens mapped to the provided token/list of tokens
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogTokensToTokensHash(bytes32 indexed tokensHash, address indexed caller);

    /**
     * @dev Emitted when Discontinue over vault is activated
     * @param vault OptyFi's Vault contract address which is discontinued from being operational
     * @param discontinued Discontinue status (true) of OptyFi's Vault contract
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogDiscontinueVault(address indexed vault, bool indexed discontinued, address indexed caller);

    /**
     * @notice Emitted when Pause over vault is activated/deactivated
     * @param vault OptyFi's Vault contract address which is temporarily paused or unpaused
     * @param unpaused Unpause status of OptyFi's Vault contract - false (if paused) and true (if unpaused)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogUnpauseVault(address indexed vault, bool indexed unpaused, address indexed caller);

    /**
     * @notice Emitted when setUnderlyingAssetHashToRPToVaults function is called
     * @param underlyingAssetHash Underlying token's hash mapped to risk profile and OptyFi's Vault contract address
     * @param riskProfileCode Risk Profile Code used to map Underlying token hash and OptyFi's Vault contract address
     * @param vault OptyFi's Vault contract address
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogUnderlyingAssetHashToRPToVaults(
        bytes32 indexed underlyingAssetHash,
        uint256 indexed riskProfileCode,
        address indexed vault,
        address caller
    );

    /**
     * @notice Emitted when RiskProfile is added
     * @param index Index of an array at which risk profile is added
     * @param exists Status of risk profile if it exists (true) or not (false)
     * @param canBorrow Borrow is allowed (true) or not (false) for the specified risk profile
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRiskProfile(uint256 indexed index, bool indexed exists, bool indexed canBorrow, address caller);

    /**
     * @notice Emitted when Risk profile is added/updated
     * @param index Index of an array at which risk profile is added or updated
     * @param lowerLimit Lower limit of the pool for the specified risk profile
     * @param upperLimit Upper limit of the pool for the specified risk profile
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogRPPoolRatings(uint256 indexed index, uint8 indexed lowerLimit, uint8 indexed upperLimit, address caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title Interface for ModifiersController Contract
 * @author Opty.fi
 * @notice Interface used to authorize operator and minter accounts
 */
interface IModifiersController {
    /**
     * @notice Transfers financeOperator to a new account (`_financeOperator`)
     * @param _financeOperator address of financeOperator's account
     */
    function setFinanceOperator(address _financeOperator) external;

    /**
     * @notice Transfers riskOperator to a new account (`_riskOperator`)
     * @param _riskOperator address of riskOperator's account
     */
    function setRiskOperator(address _riskOperator) external;

    /**
     * @notice Transfers strategyOperator to a new account (`_strategyOperator`)
     * @param _strategyOperator address of strategyOperator's account
     */
    function setStrategyOperator(address _strategyOperator) external;

    /**
     * @notice Transfers operator to a new account (`_operator`)
     * @param _operator address of Operator's account
     */
    function setOperator(address _operator) external;

    /**
     * @notice Transfers optyDistributor to a new account (`_optyDistributor`)
     * @param _optyDistributor address of optyDistributor's account
     */
    function setOPTYDistributor(address _optyDistributor) external;
}