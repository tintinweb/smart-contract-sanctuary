/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

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

contract ITwoKeyEventSourceEvents {
    // This 2 functions will be always in the interface since we need them very often
    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);

    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external;

    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external;

    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external;

    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external;

    function priceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    )
    external;

    function userRegistered(
        string _name,
        address _address,
        string _fullName,
        string _email,
        string _username_walletName
    )
    external;

    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external;


    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public;


}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeySingletoneRegistryFetchAddress {
    function getContractProxyAddress(string _contractName) public view returns (address);
    function getNonUpgradableContractAddress(string contractName) public view returns (address);
    function getLatestCampaignApprovedVersion(string campaignType) public view returns (string);
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

contract ITwoKeyFactoryStorage is IStructuredStorage {

}

contract ITwoKeySingletonUtils {

    address public TWO_KEY_SINGLETON_REGISTRY;

    // Modifier to restrict method calls only to maintainers
    modifier onlyMaintainer {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry("TwoKeyMaintainersRegistry");
        require(ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(msg.sender));
        _;
    }

    /**
     * @notice Function to get any singleton contract proxy address from TwoKeySingletonRegistry contract
     * @param contractName is the name of the contract we're looking for
     */
    function getAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getContractProxyAddress(contractName);
    }

    function getNonUpgradableContractAddressFromTwoKeySingletonRegistry(
        string contractName
    )
    internal
    view
    returns (address)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getNonUpgradableContractAddress(contractName);
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

contract Upgradeable is UpgradeabilityStorage {
    /**
     * @dev Validates the caller is the versions registry.
     * @param sender representing the address deploying the initial behavior of the contract
     */
    function initialize(address sender) public payable {
        require(msg.sender == address(registry));
    }
}

contract TwoKeyFactory is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    string constant _addressToCampaignType = "addressToCampaignType";
    string constant _twoKeyEventSource = "TwoKeyEventSource";
    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";

    ITwoKeyFactoryStorage PROXY_STORAGE_CONTRACT;

    event ProxyForCampaign(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    );

    event ProxyForDonationCampaign(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    );


    /**
     * @notice Function to set initial parameters for the contract
     * @param _twoKeySingletonRegistry is the address of singleton registry contract
     */
    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = ITwoKeySingletoneRegistryFetchAddress(_twoKeySingletonRegistry);
        PROXY_STORAGE_CONTRACT = ITwoKeyFactoryStorage(_proxyStorage);
        initialized = true;
    }

    function getLatestApprovedCampaignVersion(
        string campaignType
    )
    public
    view
    returns (string)
    {
        return ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY)
            .getLatestCampaignApprovedVersion(campaignType);
    }

    function createProxyForCampaign(
        string campaignType,
        string campaignName
    )
    internal
    returns (address)
    {
        ProxyCampaign proxy = new ProxyCampaign(
            campaignName,
            getLatestApprovedCampaignVersion(campaignType),
            address(TWO_KEY_SINGLETON_REGISTRY)
        );
        return address(proxy);
    }


    /**
     * @notice Function used to deploy all necessary proxy contracts in order to use the campaign.
     * @dev This function will handle all necessary actions which should be done on the contract
     * in order to make them ready to work. Also, we've been unfortunately forced to use arrays
     * as arguments since the stack is not deep enough to handle this amount of input information
     * since this method handles kick-start of 3 contracts
     * @param addresses is array of addresses needed [assetContractERC20,moderator]
     * @param valuesConversion is array containing necessary values to start conversion handler contract
     * @param valuesLogicHandler is array of values necessary to start logic handler contract
     * @param values is array containing values necessary to start campaign contract
     * @param _currency is the main currency token price is set
     * @param _nonSingletonHash is the hash of non-singleton contracts active with responding
     * 2key-protocol version at the moment
     */
    function createProxiesForAcquisitions(
        address[] addresses,
        uint[] valuesConversion,
        uint[] valuesLogicHandler,
        uint[] values,
        string _currency,
        string _nonSingletonHash
    )
    public
    payable
    {

        //Deploy proxy for Acquisition contract
        address proxyAcquisition = createProxyForCampaign("TOKEN_SELL","TwoKeyAcquisitionCampaignERC20");

        //Deploy proxy for ConversionHandler contract
        address proxyConversions = createProxyForCampaign("TOKEN_SELL","TwoKeyConversionHandler");

        //Deploy proxy for TwoKeyAcquisitionLogicHandler contract
        address proxyLogicHandler = createProxyForCampaign("TOKEN_SELL","TwoKeyAcquisitionLogicHandler");

        //Deploy proxy for TwoKeyPurchasesHandler contract
        address proxyPurchasesHandler = createProxyForCampaign("TOKEN_SELL","TwoKeyPurchasesHandler");


        IHandleCampaignDeployment(proxyPurchasesHandler).setInitialParamsPurchasesHandler(
            valuesConversion,
            msg.sender,
            addresses[0],
            getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource),
            proxyConversions
        );

        // Set initial arguments inside Conversion Handler contract
        IHandleCampaignDeployment(proxyConversions).setInitialParamsConversionHandler(
            valuesConversion,
            proxyAcquisition,
            proxyPurchasesHandler,
            msg.sender,
            addresses[0], //ERC20 address
            TWO_KEY_SINGLETON_REGISTRY
        );

        // Set initial arguments inside Logic Handler contract
        IHandleCampaignDeployment(proxyLogicHandler).setInitialParamsLogicHandler(
            valuesLogicHandler,
            _currency,
            addresses[0], //asset contract erc20
            addresses[1], // moderator
            msg.sender,
            proxyAcquisition,
            address(TWO_KEY_SINGLETON_REGISTRY),
            proxyConversions
        );

        // Set initial arguments inside AcquisitionCampaign contract
        IHandleCampaignDeployment(proxyAcquisition).setInitialParamsCampaign(
            address(TWO_KEY_SINGLETON_REGISTRY),
            address(proxyLogicHandler),
            address(proxyConversions),
            addresses[1], //moderator
            addresses[0], //asset contract
            msg.sender, //contractor
            getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy"),
            values
        );

        // Validate campaign so it will be approved to interact (and write) to/with our singleton contracts
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateAcquisitionCampaign(proxyAcquisition, _nonSingletonHash);

        setAddressToCampaignType(proxyAcquisition, "TOKEN_SELL");

        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .acquisitionCampaignCreated(
            proxyLogicHandler,
            proxyConversions,
            proxyAcquisition,
            proxyPurchasesHandler,
            plasmaOf(msg.sender)
        );
    }


    /**
     * @notice Function to deploy proxy contracts for donation campaigns
     */
    function createProxiesForDonationCampaign(
        address _moderator,
        uint [] numberValues,
        bool [] booleanValues,
        string _currency,
        string tokenName,
        string tokenSymbol,
        string nonSingletonHash
    )
    public
    {

        // Deploying a proxy contract for donations
        address proxyDonationCampaign = createProxyForCampaign("DONATION","TwoKeyDonationCampaign");

        //Deploying a proxy contract for donation conversion handler
        address proxyDonationConversionHandler = createProxyForCampaign("DONATION","TwoKeyDonationConversionHandler");

        //Deploying a proxy contract for donation logic handler
        address proxyDonationLogicHandler = createProxyForCampaign("DONATION","TwoKeyDonationLogicHandler");

        IHandleCampaignDeployment(proxyDonationLogicHandler).setInitialParamsDonationLogicHandler(
            numberValues,
            _currency,
            msg.sender,
            _moderator,
            TWO_KEY_SINGLETON_REGISTRY,
            proxyDonationCampaign,
            proxyDonationConversionHandler
        );

        // Set initial parameters under Donation conversion handler
        IHandleCampaignDeployment(proxyDonationConversionHandler).setInitialParamsDonationConversionHandler(
            tokenName,
            tokenSymbol,
            _currency,
            msg.sender, //contractor
            proxyDonationCampaign,
            address(TWO_KEY_SINGLETON_REGISTRY)
        );
//
        // Set initial parameters under Donation campaign contract
        IHandleCampaignDeployment(proxyDonationCampaign).setInitialParamsDonationCampaign(
            msg.sender, //contractor
            _moderator, //moderator address
            TWO_KEY_SINGLETON_REGISTRY,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            numberValues,
            booleanValues
        );

        // Validate campaign
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateDonationCampaign(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            nonSingletonHash
        );

        setAddressToCampaignType(proxyDonationCampaign, "DONATION");

        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .donationCampaignCreated(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            plasmaOf(msg.sender)
        );
    }

    function createProxyForCPCCampaign(
        string _url,
        uint _bountyPerConversion,
        address _mirrorCampaignOnPlasma,
        string _nonSingletonHash
    )
    public
    {
        address proxyCPC = createProxyForCampaign("CPC_PUBLIC","TwoKeyCPCCampaign");

        IHandleCampaignDeployment(proxyCPC).setInitialParamsCPCCampaign(
            msg.sender,
            TWO_KEY_SINGLETON_REGISTRY,
            _url,
            _mirrorCampaignOnPlasma,
            _bountyPerConversion,
            getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")
        );

        setAddressToCampaignType(proxyCPC, "CPC_PUBLIC");

        //Validate campaign
        ITwoKeyCampaignValidator(getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator))
        .validateCPCCampaign(
            proxyCPC,
            _nonSingletonHash
        );

        //Emit event that TwoKeyCPCCampaign contract is created
        ITwoKeyEventSourceEvents(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource))
        .cpcCampaignCreated(
            proxyCPC,
            plasmaOf(msg.sender)
        );
    }

    /**
     * @notice internal function to set address to campaign type
     * @param _campaignAddress is the address of campaign
     * @param _campaignType is the type of campaign (String)
     */
    function setAddressToCampaignType(address _campaignAddress, string _campaignType) internal {
        bytes32 keyHash = keccak256(_addressToCampaignType, _campaignAddress);
        PROXY_STORAGE_CONTRACT.setString(keyHash, _campaignType);
    }

    /**
     * @notice Function working as a getter
     * @param _key is the address of campaign
     */
    function addressToCampaignType(address _key) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_addressToCampaignType, _key));
    }

    function plasmaOf(address _address) internal view returns (address) {
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
        address plasma = ITwoKeyEventSourceEvents(twoKeyEventSource).plasmaOf(_address);
        return plasma;
    }



}

contract UpgradeabilityCampaignStorage {

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

contract ProxyCampaign is Proxy, UpgradeabilityCampaignStorage {

    constructor (string _contractName, string _version, address twoKeySingletonRegistry) public {
        _implementation = ITwoKeySingletonesRegistry(twoKeySingletonRegistry).getVersion(_contractName, _version);
    }
}

contract UpgradeableCampaign is UpgradeabilityCampaignStorage {

}