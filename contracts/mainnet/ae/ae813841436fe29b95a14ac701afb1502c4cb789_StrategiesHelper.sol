/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

pragma solidity ^0.8.2;

interface IV2Strategy {
    function name() external view returns (string memory);

    function apiVersion() external view returns (string memory);

    function strategist() external view returns (address);

    function rewards() external view returns (address);

    function vault() external view returns (address);

    function keeper() external view returns (address);

    function want() external view returns (address);

    function emergencyExit() external view returns (bool);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);
}

interface IV2RegistryAdapter {
    function assetsAddresses() external view returns (address[] memory);
}

interface IV2Vault {
    function withdrawalQueue(uint256 arg0) external view returns (address);
}

interface IHelper {
    function mergeAddresses(address[][] memory addressesSets)
        external
        view
        returns (address[] memory);
}

contract StrategiesHelper {
    address public registryAdapterAddress;
    address public helperAddress;
    IV2RegistryAdapter registryAdapter;
    IHelper helper;

    struct StrategyMetadata {
        string name;
        string apiVersion;
        address strategist;
        address rewards;
        address vault;
        address keeper;
        address want;
        bool emergencyExit;
        bool isActive;
        uint256 delegatedAssets;
        uint256 estimatedTotalAssets;
    }

    constructor(address _registryAdapterAddress, address _helperAddress) {
        registryAdapterAddress = _registryAdapterAddress;
        registryAdapter = IV2RegistryAdapter(_registryAdapterAddress);
        helperAddress = _helperAddress;
        helper = IHelper(_helperAddress);
    }

    /**
     * Fetch metadata about a strategy given a strategy address
     */
    function assetStrategy(address strategyAddress)
        public
        view
        returns (StrategyMetadata memory)
    {
        IV2Strategy _strategy = IV2Strategy(strategyAddress);
        return
            StrategyMetadata({
                name: _strategy.name(),
                apiVersion: _strategy.apiVersion(),
                strategist: _strategy.strategist(),
                rewards: _strategy.rewards(),
                vault: _strategy.vault(),
                keeper: _strategy.keeper(),
                want: _strategy.want(),
                emergencyExit: _strategy.emergencyExit(),
                isActive: _strategy.isActive(),
                delegatedAssets: _strategy.delegatedAssets(),
                estimatedTotalAssets: _strategy.estimatedTotalAssets()
            });
    }

    /**
     * Fetch the number of strategies for a vault
     */
    function assetStrategiesLength(address assetAddress)
        public
        view
        returns (uint256)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 strategyIdx;
        while (true) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            if (strategyAddress == address(0)) {
                break;
            }
            strategyIdx++;
        }
        return strategyIdx;
    }

    /**
     * Fetch the total number of strategies for all vaults
     */
    function assetsStrategiesLength() public view returns (uint256) {
        address[] memory _assetsAddresses = registryAdapter.assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        uint256 _assetsStrategiesLength;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            uint256 _assetStrategiesLength =
                assetStrategiesLength(assetAddress);
            _assetsStrategiesLength += _assetStrategiesLength;
        }
        return _assetsStrategiesLength;
    }

    /**
     * Fetch strategy addresses given a vault address
     */
    function assetStrategiesAddresses(address assetAddress)
        public
        view
        returns (address[] memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 numberOfStrategies = assetStrategiesLength(assetAddress);
        address[] memory _strategiesAddresses =
            new address[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            _strategiesAddresses[strategyIdx] = strategyAddress;
        }
        return _strategiesAddresses;
    }

    /**
     * Fetch all strategy addresses for all vaults
     */
    function assetsStrategiesAddresses()
        public
        view
        returns (address[] memory)
    {
        address[] memory _assetsAddresses = registryAdapter.assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        address[][] memory _strategiesForAssets =
            new address[][](numberOfAssets);
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            address[] memory _assetStrategiessAddresses =
                assetStrategiesAddresses(assetAddress);
            _strategiesForAssets[assetIdx] = _assetStrategiessAddresses;
        }
        address[] memory mergedAddresses =
            helper.mergeAddresses(_strategiesForAssets);
        return mergedAddresses;
    }

    /**
     * Fetch total delegated balance for all strategies
     */
    function assetsStrategiesDelegatedBalance()
        external
        view
        returns (uint256)
    {
        address[] memory _assetsAddresses = registryAdapter.assetsAddresses();
        uint256 numberOfAssets = _assetsAddresses.length;
        uint256 assetsDelegatedBalance;
        for (uint256 assetIdx = 0; assetIdx < numberOfAssets; assetIdx++) {
            address assetAddress = _assetsAddresses[assetIdx];
            uint256 assetDelegatedBalance =
                assetStrategiesDelegatedBalance(assetAddress);
            assetsDelegatedBalance += assetDelegatedBalance;
        }
        return assetsDelegatedBalance;
    }

    /**
     * Fetch delegated balance for all of a vault's strategies
     */
    function assetStrategiesDelegatedBalance(address assetAddress)
        public
        view
        returns (uint256)
    {
        address[] memory _assetStrategiesAddresses =
            assetStrategiesAddresses(assetAddress);
        uint256 numberOfStrategies = _assetStrategiesAddresses.length;
        uint256 strategiesDelegatedBalance;
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _assetStrategiesAddresses[strategyIdx];
            IV2Strategy _strategy = IV2Strategy(strategyAddress);
            uint256 strategyDelegatedBalance = _strategy.delegatedAssets();
            strategiesDelegatedBalance += strategyDelegatedBalance;
        }
        return strategiesDelegatedBalance;
    }

    /**
     * Fetch metadata for all strategies scoped to a vault
     */
    function assetStrategies(address assetAddress)
        external
        view
        returns (StrategyMetadata[] memory)
    {
        IV2Vault vault = IV2Vault(assetAddress);
        uint256 numberOfStrategies = assetStrategiesLength(assetAddress);
        StrategyMetadata[] memory _strategies =
            new StrategyMetadata[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = vault.withdrawalQueue(strategyIdx);
            StrategyMetadata memory _strategy = assetStrategy(strategyAddress);
            _strategies[strategyIdx] = _strategy;
        }
        return _strategies;
    }

    /**
     * Fetch metadata for strategies given an array of strategy addresses
     */
    function assetsStrategies(address[] memory _assetsStrategiesAddresses)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        uint256 numberOfStrategies = _assetsStrategiesAddresses.length;
        StrategyMetadata[] memory strategies =
            new StrategyMetadata[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _assetsStrategiesAddresses[strategyIdx];
            StrategyMetadata memory strategy = assetStrategy(strategyAddress);
            strategies[strategyIdx] = strategy;
        }
        return strategies;
    }

    /**
     * Fetch metadata for all strategies
     */
    function assetsStrategies()
        external
        view
        returns (StrategyMetadata[] memory)
    {
        address[] memory _assetsStrategiesAddresses =
            assetsStrategiesAddresses();
        return assetsStrategies(_assetsStrategiesAddresses);
    }
}