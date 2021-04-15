/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IV2Registry {
    function numTokens() external view returns (uint256);

    function numVaults(address token) external view returns (uint256);

    function tokens(uint256 tokenIdx) external view returns (address);

    function latestVault(address token) external view returns (address);

    function vaults(address token, uint256 tokenIdx)
        external
        view
        returns (address);
}

interface ManagementList {
    function isManager(address accountAddress) external returns (bool);
}

/*******************************************************
 *                     Management List                 *
 *******************************************************/

contract Manageable {
    ManagementList public managementList;

    constructor(address _managementListAddress) {
        managementList = ManagementList(_managementListAddress);
    }

    modifier onlyManagers() {
        bool isManager = managementList.isManager(msg.sender);
        require(isManager, "ManagementList: caller is not a manager");
        _;
    }
}

/*******************************************************
 *                    Generator Logic                  *
 *******************************************************/
contract AddressesGenerator_VAULT_V2 is Manageable {
    mapping(address => bool) public assetDeprecated; // Support for deprecating assets. If an asset is deprecated it will not appear is results
    uint256 public numberOfDeprecatedAssets; // Used to keep track of the number of deprecated assets for an adapter
    address[] public positionSpenderAddresses; // A settable list of spender addresses with which to fetch asset allowances
    IV2Registry public registry; // The registry is used to fetch the list of vaults and migration data

    /**
     * Information about the generator
     */
    struct GeneratorInfo {
        address id; // Generator address
        string typeId; // Generator typeId (for example "VAULT_V2" or "IRON_BANK_MARKET")
        string categoryId; // Generator categoryId (for example "VAULT")
    }

    /**
     * Configure generator
     */
    constructor(address _registryAddress, address _managementListAddress)
        Manageable(_managementListAddress)
    {
        require(
            _managementListAddress != address(0),
            "Missing management list address"
        );
        require(_registryAddress != address(0), "Missing registry address");
        registry = IV2Registry(_registryAddress);
    }

    /**
     * Deprecate or undeprecate an asset. Deprecated assets will not appear in any adapter or generator method call responses
     */
    function setAssetDeprecated(address assetAddress, bool newDeprecationStatus)
        public
        onlyManagers
    {
        bool currentDeprecationStatus = assetDeprecated[assetAddress];
        if (currentDeprecationStatus == newDeprecationStatus) {
            revert("Generator: Unable to change asset deprecation status");
        }
        if (newDeprecationStatus == true) {
            numberOfDeprecatedAssets++;
        } else {
            numberOfDeprecatedAssets--;
        }
        assetDeprecated[assetAddress] = newDeprecationStatus;
    }

    /**
     * Set position spender addresses. Used by `adapter.assetAllowances(address,address)`.
     */
    function setPositionSpenderAddresses(address[] memory addresses)
        public
        onlyManagers
    {
        positionSpenderAddresses = addresses;
    }

    /**
     * Fetch a list of position spender addresses
     */
    function getPositionSpenderAddresses()
        external
        view
        returns (address[] memory)
    {
        return positionSpenderAddresses;
    }

    /**
     * Fetch generator info
     */
    function generatorInfo() public view returns (GeneratorInfo memory) {
        return
            GeneratorInfo({
                id: address(this),
                typeId: "VAULT_V2",
                categoryId: "VAULT"
            });
    }

    /**
     * Fetch the total number of assets
     */
    function assetsLength() public view returns (uint256) {
        uint256 numTokens = registry.numTokens();
        uint256 numVaults;
        for (uint256 tokenIdx = 0; tokenIdx < numTokens; tokenIdx++) {
            address currentToken = registry.tokens(tokenIdx);
            uint256 numVaultsForToken = registry.numVaults(currentToken);
            numVaults += numVaultsForToken;
        }
        return numVaults - numberOfDeprecatedAssets;
    }

    /**
     * Fetch all asset addresses
     */
    function assetsAddresses() public view returns (address[] memory) {
        uint256 numVaults = assetsLength();
        address[] memory _assetsAddresses = new address[](numVaults);
        uint256 numTokens = registry.numTokens();
        uint256 currentVaultIdx;
        for (uint256 tokenIdx = 0; tokenIdx < numTokens; tokenIdx++) {
            address currentTokenAddress = registry.tokens(tokenIdx);
            uint256 numVaultsForToken = registry.numVaults(currentTokenAddress);
            for (
                uint256 vaultTokenIdx = 0;
                vaultTokenIdx < numVaultsForToken;
                vaultTokenIdx++
            ) {
                address currentAssetAddress =
                    registry.vaults(currentTokenAddress, vaultTokenIdx);
                bool assetIsNotDeprecated =
                    assetDeprecated[currentAssetAddress] == false;
                if (assetIsNotDeprecated) {
                    _assetsAddresses[currentVaultIdx] = currentAssetAddress;
                    currentVaultIdx++;
                }
            }
        }
        return _assetsAddresses;
    }
}