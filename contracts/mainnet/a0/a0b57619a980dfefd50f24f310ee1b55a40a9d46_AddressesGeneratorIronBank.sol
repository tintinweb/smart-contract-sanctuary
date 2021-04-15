/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/*******************************************************
 *                       Interfaces                    *
 *******************************************************/
interface IUnitroller {
    function getAllMarkets() external view returns (address[] memory);
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
contract AddressesGeneratorIronBank is Manageable {
    mapping(address => bool) public assetDeprecated; // Support for deprecating assets. If an asset is deprecated it will not appear is results
    uint256 public numberOfDeprecatedAssets; // Used to keep track of the number of deprecated assets for an adapter
    address[] public positionSpenderAddresses; // A settable list of spender addresses with which to fetch asset allowances
    IUnitroller public registry; // The registry is used to fetch the list of assets

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
        registry = IUnitroller(_registryAddress);
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
     * Set registry address
     */
    function setRegistryAddress(address _registryAddress) public onlyManagers {
        require(_registryAddress != address(0), "Missing registry address");
        registry = IUnitroller(_registryAddress);
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
                typeId: "IRON_BANK_MARKET",
                categoryId: "LENDING"
            });
    }

    /**
     * Fetch the total number of assets
     */
    function assetsLength() public view returns (uint256) {
        return registry.getAllMarkets().length - numberOfDeprecatedAssets;
    }

    /**
     * Fetch all asset addresses
     */
    function assetsAddresses() public view returns (address[] memory) {
        address[] memory originalAddresses = registry.getAllMarkets();
        uint256 _numberOfAssets = originalAddresses.length;
        uint256 _filteredAssetsLength = assetsLength();
        if (_numberOfAssets == _filteredAssetsLength) {
            return originalAddresses;
        }
        uint256 currentAssetIdx;
        for (uint256 assetIdx = 0; assetIdx < _numberOfAssets; assetIdx++) {
            address currentAssetAddress = originalAddresses[assetIdx];
            bool assetIsNotDeprecated =
                assetDeprecated[currentAssetAddress] == false;
            if (assetIsNotDeprecated) {
                originalAddresses[currentAssetIdx] = currentAssetAddress;
                currentAssetIdx++;
            }
        }
        bytes memory encodedAddresses = abi.encode(originalAddresses);
        assembly {
            // Manually truncate the filtered list
            mstore(add(encodedAddresses, 0x40), _filteredAssetsLength)
        }
        address[] memory filteredAddresses =
            abi.decode(encodedAddresses, (address[]));

        return filteredAddresses;
    }
}