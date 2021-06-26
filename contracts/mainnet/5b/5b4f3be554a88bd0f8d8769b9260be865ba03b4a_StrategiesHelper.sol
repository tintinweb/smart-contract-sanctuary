/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: MIT

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
    
    function doHealthCheck() external view returns (bool);
    
    function healthCheck() external view returns (address);
}

interface IAddressesGenerator {
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
    address public addressesGeneratorAddress;
    address public helperAddress;
    address public ownerAddress;

    struct StrategyMetadata {
        string name;
        address id;
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
        bool doHealthCheck;
        address healthCheckAddress;
    }

    constructor(address _addressesGeneratorAddress, address _helperAddress) {
        addressesGeneratorAddress = _addressesGeneratorAddress;
        helperAddress = _helperAddress;
        ownerAddress = msg.sender;
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
        return assetsStrategiesAddresses().length;
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
     function assetsStrategiesAddresses() public view returns (address[] memory) {
        address[] memory _assetsAddresses = IAddressesGenerator(addressesGeneratorAddress).assetsAddresses();
        return assetsStrategiesAddresses(_assetsAddresses);
     }

    /**
     * Fetch all strategy addresses given an array of vaults
     */
    function assetsStrategiesAddresses(address[] memory _assetsAddresses)
        public
        view
        returns (address[] memory)
    {
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
            IHelper(helperAddress).mergeAddresses(_strategiesForAssets);
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
        address[] memory _assetsAddresses = IAddressesGenerator(addressesGeneratorAddress).assetsAddresses();
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
            StrategyMetadata memory _strategy = strategy(strategyAddress);
            _strategies[strategyIdx] = _strategy;
        }
        return _strategies;
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
        return strategies(_assetsStrategiesAddresses);
    }
    
    
    function assetsStrategies(address[] memory _assetsAddresses)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        return strategies(assetsStrategiesAddresses(_assetsAddresses));
    }
    
    
    /**
     * Fetch metadata for a strategy given a strategy address
     */
    function strategy(address strategyAddress)
        public
        view
        returns (StrategyMetadata memory)
    {
        IV2Strategy _strategy = IV2Strategy(strategyAddress);
        bool _doHealthCheck;
        address _healthCheckAddress;
        try _strategy.doHealthCheck() {
            _doHealthCheck = _strategy.doHealthCheck();
        } catch {}
        try _strategy.healthCheck() {
             _healthCheckAddress = _strategy.healthCheck();
        } catch {}
        return
            StrategyMetadata({
                name: _strategy.name(),
                id: strategyAddress,
                apiVersion: _strategy.apiVersion(),
                strategist: _strategy.strategist(),
                rewards: _strategy.rewards(),
                vault: _strategy.vault(),
                keeper: _strategy.keeper(),
                want: _strategy.want(),
                emergencyExit: _strategy.emergencyExit(),
                isActive: _strategy.isActive(),
                delegatedAssets: _strategy.delegatedAssets(),
                estimatedTotalAssets: _strategy.estimatedTotalAssets(),
                doHealthCheck: _doHealthCheck,
                healthCheckAddress: _healthCheckAddress
            });
    }

    /**
     * Fetch metadata for strategies given an array of strategy addresses
     */
    function strategies(address[] memory _strategiesAddresses)
        public
        view
        returns (StrategyMetadata[] memory)
    {
        uint256 numberOfStrategies = _strategiesAddresses.length;
        StrategyMetadata[] memory _strategies =
            new StrategyMetadata[](numberOfStrategies);
        for (
            uint256 strategyIdx = 0;
            strategyIdx < numberOfStrategies;
            strategyIdx++
        ) {
            address strategyAddress = _strategiesAddresses[strategyIdx];
            StrategyMetadata memory _strategy = strategy(strategyAddress);
            _strategies[strategyIdx] = _strategy;
        }
        return _strategies;
    }
    
    /**
     * Allow storage slots to be manually updated
     */
    function updateSlot(bytes32 slot, bytes32 value) external {
        require(msg.sender == ownerAddress, "Caller is not the owner");
        assembly {
            sstore(slot, value)
        }
    }
}