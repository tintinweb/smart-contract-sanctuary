/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.4.13;

contract IGetImplementation {
    function implementation()
    public
    view
    returns (address);
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

contract ITwoKeyCampaign {

    function getNumberOfUsersToContractor(
        address _user
    )
    public
    view
    returns (uint);

    function getReceivedFrom(
        address _receiver
    )
    public
    view
    returns (address);

    function balanceOf(
        address _owner
    )
    public
    view
    returns (uint256);

    function getReferrerCut(
        address me
    )
    public
    view
    returns (uint256);

    function getReferrerPlasmaBalance(
        address _influencer
    )
    public
    view
    returns (uint);

    function updateReferrerPlasmaBalance(
        address _influencer,
        uint _balance
    )
    public;

    function updateModeratorRewards(
        uint moderatorTokens
    )
    public;

    address public logicHandler;
    address public conversionHandler;

}

contract ITwoKeyCampaignPublicAddresses {
    address public twoKeySingletonesRegistry;
    address public contractor; //contractor address
    address public moderator; //moderator address
    function publicLinkKeyOf(address me) public view returns (address);
}

contract ITwoKeyConversionHandler {

    bool public isFiatConversionAutomaticallyApproved;
    address public twoKeyPurchasesHandler;

    function supportForCreateConversion(
        address _converterAddress,
        uint256 _conversionAmount,
        uint256 _maxReferralRewardETHWei,
        bool isConversionFiat,
        bool _isAnonymous,
        uint conversionAmountCampaignCurrency
    )
    public
    returns (uint);

    function executeConversion(
        uint _conversionId
    )
    public;


    function getConverterConversionIds(
        address _converter
    )
    external
    view
    returns (uint[]);


    function getConverterPurchasesStats(
        address _converter
    )
    public
    view
    returns (uint,uint,uint);


    function getStateForConverter(
        address _converter
    )
    public
    view
    returns (bytes32);

    function getMainCampaignContractAddress()
    public
    view
    returns (address);

}

contract ITwoKeyDonationCampaign {
    address public logicHandler;
    function buyTokensForModeratorRewards(
        uint moderatorFee
    )
    public;

    function buyTokensAndDistributeReferrerRewards(
        uint256 _maxReferralRewardETHWei,
        address _converter,
        uint _conversionId
    )
    public
    returns (uint);

    function updateReferrerPlasmaBalance(address _influencer, uint _balance) public;
    function updateContractorProceeds(uint value) public;
    function sendBackEthWhenConversionCancelledOrRejected(address _cancelledConverter, uint _conversionAmount) public;
}

contract ITwoKeyDonationCampaignFetchAddresses {
    address public twoKeyDonationConversionHandler;
    address public twoKeyDonationCampaign;
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

contract ITwoKeyCampaignValidatorStorage is IStructuredStorage {

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

contract TwoKeyCampaignValidator is Upgradeable, ITwoKeySingletonUtils {

    /**
     * Storage keys are stored on the top. Here they are in order to avoid any typos
     */
    string constant _isCampaignValidated = "isCampaignValidated";
    string constant _campaign2NonSingletonHash = "campaign2NonSingletonHash";

    /**
     * Keys for the addresses we're accessing
     */
    string constant _twoKeyFactory = "TwoKeyFactory";
    string constant _twoKeyEventSource = "TwoKeyEventSource";


    bool initialized;

    // Pointer to the PROXY storage contract
    ITwoKeyCampaignValidatorStorage public PROXY_STORAGE_CONTRACT;

    /**
     * @notice Function to set initial parameters in this contract
     * @param _twoKeySingletoneRegistry is the address of TwoKeySingletoneRegistry contract
     * @param _proxyStorage is the address of proxy of storage contract
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyCampaignValidatorStorage(_proxyStorage);

        initialized = true;
    }

    // Modifier which will make function throw if caller is not TwoKeyFactory proxy contract
    modifier onlyTwoKeyFactory {
        address twoKeyFactory = getAddressFromTwoKeySingletonRegistry(_twoKeyFactory);
        require(msg.sender == twoKeyFactory);
        _;
    }

    /**
     * @notice Function which will make newly created campaign validated
     * @param campaign is the address of the campaign
     * @param nonSingletonHash is the non singleton hash at the moment of campaign creation
     */
    function validateAcquisitionCampaign(
        address campaign,
        string nonSingletonHash
    )
    public
    onlyTwoKeyFactory
    {
        address conversionHandler = ITwoKeyCampaign(campaign).conversionHandler();
        address logicHandler = ITwoKeyCampaign(campaign).logicHandler();
        address purchasesHandler = ITwoKeyConversionHandler(conversionHandler).twoKeyPurchasesHandler();

        //Whitelist all campaign associated contracts
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated, conversionHandler), true);
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated, logicHandler), true);
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated, purchasesHandler), true);
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated,campaign), true);
        PROXY_STORAGE_CONTRACT.setString(keccak256(_campaign2NonSingletonHash,campaign), nonSingletonHash);

        emitCreatedEvent(campaign);
    }

    /**
     * @notice Function which will make newly created campaign validated
     * @param campaign is the campaign address
     * @dev Validates all the required stuff, if the campaign is not validated, it can't update our singletones
     */
    function validateDonationCampaign(
        address campaign,
        address donationConversionHandler,
        address donationLogicHandler,
        string nonSingletonHash
    )
    public
    onlyTwoKeyFactory
    {
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated,campaign), true);
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated,donationConversionHandler), true);
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated,donationLogicHandler), true);

        PROXY_STORAGE_CONTRACT.setString(keccak256(_campaign2NonSingletonHash,campaign), nonSingletonHash);

        emitCreatedEvent(campaign);
    }

    function validateCPCCampaign(
        address campaign,
        string nonSingletonHash
    )
    public
    onlyTwoKeyFactory
    {
        PROXY_STORAGE_CONTRACT.setBool(keccak256(_isCampaignValidated,campaign), true);
        PROXY_STORAGE_CONTRACT.setString(keccak256(_campaign2NonSingletonHash,campaign), nonSingletonHash);

        //Emit event that is created with moderator contractor and campaign address
        emitCreatedEvent(campaign);
    }


    /**
     * @notice Function which will return either is or not one of the campaign contracts validated
     * @param campaign is any contract deployed during any campaign creation through TwoKeyFactory
     */
    function isCampaignValidated(address campaign) public view returns (bool) {
        bytes32 hashKey = keccak256(_isCampaignValidated, campaign);
        return PROXY_STORAGE_CONTRACT.getBool(hashKey);
    }

    /**
     * @notice Function which is serving as getter for non-singleton hash at the time of campaign creation
     * @param campaign is the address of strictly main campaign contract (TwoKeyAcquisitionCampaignERC20, TwoKeyDonationCampaign for now)
     */
    function campaign2NonSingletonHash(address campaign) public view returns (string) {
        return PROXY_STORAGE_CONTRACT.getString(keccak256(_campaign2NonSingletonHash, campaign));
    }

    /**
     * @notice Function to emit event on TwoKeyEventSource contract
     */
    function emitCreatedEvent(address campaign) internal {
        address contractor = ITwoKeyCampaignPublicAddresses(campaign).contractor();
        address moderator = ITwoKeyCampaignPublicAddresses(campaign).moderator();

        //Get the event source address
        address twoKeyEventSource = getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource);
        // Emit event
        ITwoKeyEventSourceEvents(twoKeyEventSource).created(campaign,contractor,moderator);
    }
}