/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.4.24;

contract IHandleCampaignDeployment {

    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyAcquisitionCampaign contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyAcquisitionCampaignERC20.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsCampaign(
        address _twoKeySingletonesRegistry,
        address _twoKeyAcquisitionLogicHandler,
        address _conversionHandler,
        address _moderator,
        address _assetContractERC20,
        address _contractor,
        address _twoKeyEconomy,
        uint [] values
    ) public;

    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyAcquisitionLogicHandler contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyAcquisitionLogicHandler.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsLogicHandler(
        uint [] values,
        string _currency,
        address _assetContractERC20,
        address _moderator,
        address _contractor,
        address _acquisitionCampaignAddress,
        address _twoKeySingletoneRegistry,
        address _twoKeyConversionHandler
    ) public;

    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyConversionHandler contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyConversionHandler.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsConversionHandler(
        uint [] values,
        address _twoKeyAcquisitionCampaignERC20,
        address _twoKeyPurchasesHandler,
        address _contractor,
        address _assetContractERC20,
        address _twoKeySingletonRegistry
    ) public;


    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyPurchasesHandler contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyPurchasesHandler.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsPurchasesHandler(
        uint[] values,
        address _contractor,
        address _assetContractERC20,
        address _twoKeyEventSource,
        address _proxyConversionHandler
    ) public;


    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyDonationCampaign contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyDonationCampaign.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsDonationCampaign(
        address _contractor,
        address _moderator,
        address _twoKeySingletonRegistry,
        address _twoKeyDonationConversionHandler,
        address _twoKeyDonationLogicHandler,
        uint [] numberValues,
        bool [] booleanValues
    ) public;

    /**
     * @notice Function which will be used as simulation for constructor under TwoKeyDonationConversionHandler contract
     * @dev This is just an interface of the function, the actual logic
     * is implemented under TwoKeyDonationConversionHandler.sol contract
     * This function can be called only once per proxy address
     */
    function setInitialParamsDonationConversionHandler(
        string tokenName,
        string tokenSymbol,
        string _currency,
        address _contractor,
        address _twoKeyDonationCampaign,
        address _twoKeySingletonRegistry
    ) public;


    function setInitialParamsDonationLogicHandler(
        uint[] numberValues,
        string currency,
        address contractor,
        address moderator,
        address twoKeySingletonRegistry,
        address twoKeyDonationCampaign,
        address twokeyDonationConversionHandler
    ) public;


    function setInitialParamsCPCCampaign(
        address _contractor,
        address _twoKeySingletonRegistry,
        string _url,
        address _mirrorCampaignOnPlasma,
        uint _bountyPerConversion,
        address _twoKeyEconomy
    )
    public;
}

contract IStructuredStorage {

    function setProxyLogicContractAndDeployer(address _proxyLogicContract, address _deployer) external;
    function setProxyLogicContract(address _proxyLogicContract) external;

    // *** Getter Methods ***
    function getUint(bytes32 _key) external view returns(uint);
    function getString(bytes32 _key) external view returns(string);
    function getAddress(bytes32 _key) external view returns(address);
    function getBytes(bytes32 _key) external view returns(bytes);
    function getBool(bytes32 _key) external view returns(bool);
    function getInt(bytes32 _key) external view returns(int);
    function getBytes32(bytes32 _key) external view returns(bytes32);

    // *** Getter Methods For Arrays ***
    function getBytes32Array(bytes32 _key) external view returns (bytes32[]);
    function getAddressArray(bytes32 _key) external view returns (address[]);
    function getUintArray(bytes32 _key) external view returns (uint[]);
    function getIntArray(bytes32 _key) external view returns (int[]);
    function getBoolArray(bytes32 _key) external view returns (bool[]);

    // *** Setter Methods ***
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setAddress(bytes32 _key, address _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // *** Setter Methods For Arrays ***
    function setBytes32Array(bytes32 _key, bytes32[] _value) external;
    function setAddressArray(bytes32 _key, address[] _value) external;
    function setUintArray(bytes32 _key, uint[] _value) external;
    function setIntArray(bytes32 _key, int[] _value) external;
    function setBoolArray(bytes32 _key, bool[] _value) external;

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteAddress(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
}

contract ITwoKeyCampaignValidator {
    function isCampaignValidated(address campaign) public view returns (bool);
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public;
    function validateDonationCampaign(address campaign, address donationConversionHandler, address donationLogicHandler, string nonSingletonHash) public;
    function validateCPCCampaign(address campaign, string nonSingletonHash) public;
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

interface ITwoKeySingletonesRegistry {

    /**
    * @dev This event will be emitted every time a new proxy is created
    * @param proxy representing the address of the proxy created
    */
    event ProxyCreated(address proxy);


    /**
    * @dev This event will be emitted every time a new implementation is registered
    * @param version representing the version name of the registered implementation
    * @param implementation representing the address of the registered implementation
    * @param contractName is the name of the contract we added new version
    */
    event VersionAdded(string version, address implementation, string contractName);

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string _contractName, string version, address implementation) public;

    /**
    * @dev Tells the address of the implementation for a given version
    * @param _contractName is the name of the contract we're querying
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string _contractName, string version) public view returns (address);
}

contract TwoKeySingletonRegistryAbstract is ITwoKeySingletonesRegistry {

    address public deployer;

    string congress;
    string maintainersRegistry;

    mapping (string => mapping(string => address)) internal versions;

    mapping (string => address) contractNameToProxyAddress;
    mapping (string => string) contractNameToLatestAddedVersion;
    mapping (string => address) nonUpgradableContractToAddress;
    mapping (string => string) campaignTypeToLastApprovedVersion;


    event ProxiesDeployed(
        address logicProxy,
        address storageProxy
    );

    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress[maintainersRegistry];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    modifier onlyCoreDev {
        address twoKeyMaintainersRegistry = contractNameToProxyAddress[maintainersRegistry];
        require(msg.sender == deployer || ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressCoreDev(msg.sender));
        _;
    }

    /**
     * @dev Tells the address of the implementation for a given version
     * @param version to query the implementation of
     * @return address of the implementation registered for the given version
     */
    function getVersion(
        string contractName,
        string version
    )
    public
    view
    returns (address)
    {
        return versions[contractName][version];
    }



    /**
     * @notice Gets the latest contract version
     * @param contractName is the name of the contract
     * @return string representation of the last version
     */
    function getLatestAddedContractVersion(
        string contractName
    )
    public
    view
    returns (string)
    {
        return contractNameToLatestAddedVersion[contractName];
    }


    /**
     * @notice Function to get address of non-upgradable contract
     * @param contractName is the name of the contract
     */
    function getNonUpgradableContractAddress(
        string contractName
    )
    public
    view
    returns (address)
    {
        return nonUpgradableContractToAddress[contractName];
    }

    /**
     * @notice Function to return address of proxy for specific contract
     * @param _contractName is the name of the contract we'd like to get proxy address
     * @return is the address of the proxy for the specific contract
     */
    function getContractProxyAddress(
        string _contractName
    )
    public
    view
    returns (address)
    {
        return contractNameToProxyAddress[_contractName];
    }

    /**
     * @notice Function to get latest campaign approved version
     * @param campaignType is type of campaign
     */
    function getLatestCampaignApprovedVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return campaignTypeToLastApprovedVersion[campaignType];
    }


    /**
     * @notice Function to add non upgradable contract in registry of all contracts
     * @param contractName is the name of the contract
     * @param contractAddress is the contract address
     * @dev only maintainer can issue call to this method
     */
    function addNonUpgradableContractToAddress(
        string contractName,
        address contractAddress
    )
    public
    onlyCoreDev
    {
        require(nonUpgradableContractToAddress[contractName] == 0x0);
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }

    /**
     * @notice Function in case of hard fork, or congress replacement
     * @param contractName is the name of contract we want to add
     * @param contractAddress is the address of contract
     */
    function changeNonUpgradableContract(
        string contractName,
        address contractAddress
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        nonUpgradableContractToAddress[contractName] = contractAddress;
    }


    /**
     * @dev Registers a new version with its implementation address
     * @param version representing the version name of the new implementation to be registered
     * @param implementation representing the address of the new implementation to be registered
     */
    function addVersion(
        string contractName,
        string version,
        address implementation
    )
    public
    onlyCoreDev
    {
        require(implementation != address(0)); //Require that version implementation is not 0x0
        require(versions[contractName][version] == 0x0); //No overriding of existing versions
        versions[contractName][version] = implementation; //Save the version for the campaign
        contractNameToLatestAddedVersion[contractName] = version;
        emit VersionAdded(version, implementation, contractName);
    }

    function addVersionDuringCreation(
        string contractLogicName,
        string contractStorageName,
        address contractLogicImplementation,
        address contractStorageImplementation,
        string version
    )
    public
    {
        require(msg.sender == deployer);
        bytes memory logicVersion = bytes(contractNameToLatestAddedVersion[contractLogicName]);
        bytes memory storageVersion = bytes(contractNameToLatestAddedVersion[contractStorageName]);

        require(logicVersion.length == 0 && storageVersion.length == 0); //Requiring that this is first time adding a version
        require(keccak256(version) == keccak256("1.0.0")); //Requiring that first version is 1.0.0

        versions[contractLogicName][version] = contractLogicImplementation; //Storing version
        versions[contractStorageName][version] = contractStorageImplementation; //Storing version

        contractNameToLatestAddedVersion[contractLogicName] = version; // Mapping latest contract name to the version
        contractNameToLatestAddedVersion[contractStorageName] = version; //Mapping latest contract name to the version
    }

    /**
     * @notice Internal function to deploy proxy for the contract
     * @param contractName is the name of the contract
     * @param version is the new version
     */
    function deployProxy(
        string contractName,
        string version
    )
    internal
    returns (address)
    {
        UpgradeabilityProxy proxy = new UpgradeabilityProxy(contractName, version);
        contractNameToProxyAddress[contractName] = proxy;
        emit ProxyCreated(proxy);
        return address(proxy);
    }

    /**
     * @notice Function to upgrade contract to new version
     * @param contractName is the name of the contract
     * @param version is the new version
     */
    function upgradeContract(
        string contractName,
        string version
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        address proxyAddress = getContractProxyAddress(contractName);
        address _impl = getVersion(contractName, version);

        UpgradeabilityProxy(proxyAddress).upgradeTo(contractName, version, _impl);
    }

    /**
     * @notice Function to approve campaign version per type during it's creation
     * @param campaignType is the type of campaign we want to approve during creation
     */
    function approveCampaignVersionDuringCreation(
        string campaignType
    )
    public
    onlyCoreDev
    {
        bytes memory campaign = bytes(campaignTypeToLastApprovedVersion[campaignType]);

        require(campaign.length == 0);

        campaignTypeToLastApprovedVersion[campaignType] = "1.0.0";
    }

    /**
     * @notice Function to approve selected version for specific type of campaign
     * @param campaignType is the type of campaign
     * @param versionToApprove is the version for that type we want to approve
     */
    function approveCampaignVersion(
        string campaignType,
        string versionToApprove
    )
    public
    {
        require(msg.sender == nonUpgradableContractToAddress[congress]);
        campaignTypeToLastApprovedVersion[campaignType] = versionToApprove;
    }

    /**
     * @dev Creates an upgradeable proxy for both Storage and Logic
     * @param version representing the first version to be set for the proxy
     */
    function createProxy(
        string contractName,
        string contractNameStorage,
        string version
    )
    public
    {
        require(msg.sender == deployer);
        require(contractNameToProxyAddress[contractName] == address(0));
        address logicProxy = deployProxy(contractName, version);
        address storageProxy = deployProxy(contractNameStorage, version);

        IStructuredStorage(storageProxy).setProxyLogicContractAndDeployer(logicProxy, msg.sender);
        emit ProxiesDeployed(logicProxy, storageProxy);
    }

    /**
     * @notice Function to transfer deployer privileges to another address
     * @param _newOwner is the new contract "owner" (called deployer in this case)
     */
    function transferOwnership(
        address _newOwner
    )
    public
    {
        require(msg.sender == deployer);
        deployer = _newOwner;
    }



}

contract TwoKeySingletonesRegistry is TwoKeySingletonRegistryAbstract {

    constructor()
    public
    {
        deployer = msg.sender;
        congress = "TwoKeyCongress";
        maintainersRegistry = "TwoKeyMaintainersRegistry";
    }

}

contract Proxy {


    // Gives the possibility to delegate any call to a foreign implementation.


    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract UpgradeabilityStorage {
    // Versions registry
    ITwoKeySingletonesRegistry internal registry;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

contract UpgradabilityProxyAcquisition is Proxy, UpgradeabilityStorage {

    constructor (string _contractName, string _version) public {
        registry = ITwoKeySingletonesRegistry(msg.sender);
        _implementation = registry.getVersion(_contractName, _version);
    }
}

contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {

    //TODO: Add event through event source whenever someone calls upgradeTo
    /**
    * @dev Constructor function
    */
    constructor (string _contractName, string _version) public {
        registry = ITwoKeySingletonesRegistry(msg.sender);
        _implementation = registry.getVersion(_contractName, _version);
    }

    /**
    * @dev Upgrades the implementation to the requested version
    * @param _version representing the version name of the new implementation to be set
    */
    function upgradeTo(string _contractName, string _version, address _impl) public {
        require(msg.sender == address(registry));
        require(_impl != address(0));
        _implementation = _impl;
    }

}

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}