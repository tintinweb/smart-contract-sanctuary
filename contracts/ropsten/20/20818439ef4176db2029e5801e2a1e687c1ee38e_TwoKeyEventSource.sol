/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

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

contract ITwoKeyAdmin {
    function getDefaultIntegratorFeePercent() public view returns (uint);
    function getDefaultNetworkTaxPercent() public view returns (uint);
    function getTwoKeyRewardsReleaseDate() external view returns(uint);
    function updateReceivedTokensAsModerator(uint amountOfTokens) public;
    function updateReceivedTokensAsModeratorPPC(uint amountOfTokens, address campaignPlasma) public;
    function addFeesCollectedInCurrency(string currency, uint amount) public payable;

    function updateTokensReceivedFromDistributionFees(uint amountOfTokens) public;
}

contract ITwoKeyCampaignValidator {
    function isCampaignValidated(address campaign) public view returns (bool);
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public;
    function validateDonationCampaign(address campaign, address donationConversionHandler, address donationLogicHandler, string nonSingletonHash) public;
    function validateCPCCampaign(address campaign, string nonSingletonHash) public;
}

contract ITwoKeyFeeManager {
    function payDebtWhenConvertingOrWithdrawingProceeds(address _plasmaAddress, uint _debtPaying) public payable;
    function getDebtForUser(address _userPlasma) public view returns (uint);
    function payDebtWithDAI(address _plasmaAddress, uint _totalDebt, uint _debtPaid) public;
    function payDebtWith2Key(address _beneficiaryPublic, address _plasmaAddress, uint _amountOf2keyForRewards) public;
    function payDebtWith2KeyV2(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy,
        address _twoKeyAdmin
    ) public;
    function setRegistrationFeeForUser(address _plasmaAddress, uint _registrationFee) public;
    function addDebtForUser(address _plasmaAddress, uint _debtAmount, string _debtType) public;
    function withdrawEtherCollected() public returns (uint);
    function withdraw2KEYCollected() public returns (uint);
    function withdrawDAICollected(address _dai) public returns (uint);
}

contract ITwoKeyMaintainersRegistry {
    function checkIsAddressMaintainer(address _sender) public view returns (bool);
    function checkIsAddressCoreDev(address _sender) public view returns (bool);

    function addMaintainers(address [] _maintainers) public;
    function addCoreDevs(address [] _coreDevs) public;
    function removeMaintainers(address [] _maintainers) public;
    function removeCoreDevs(address [] _coreDevs) public;
}

contract ITwoKeyReg {
    function addTwoKeyEventSource(address _twoKeyEventSource) public;
    function changeTwoKeyEventSource(address _twoKeyEventSource) public;
    function addWhereContractor(address _userAddress, address _contractAddress) public;
    function addWhereModerator(address _userAddress, address _contractAddress) public;
    function addWhereReferrer(address _userAddress, address _contractAddress) public;
    function addWhereConverter(address _userAddress, address _contractAddress) public;
    function getContractsWhereUserIsContractor(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsModerator(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsRefferer(address _userAddress) public view returns (address[]);
    function getContractsWhereUserIsConverter(address _userAddress) public view returns (address[]);
    function getTwoKeyEventSourceAddress() public view returns (address);
    function addName(string _name, address _sender, string _fullName, string _email, bytes signature) public;
    function addNameByUser(string _name) public;
    function getName2Owner(string _name) public view returns (address);
    function getOwner2Name(address _sender) public view returns (string);
    function getPlasmaToEthereum(address plasma) public view returns (address);
    function getEthereumToPlasma(address ethereum) public view returns (address);
    function checkIfTwoKeyMaintainerExists(address _maintainer) public view returns (bool);
    function getUserData(address _user) external view returns (bytes);
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

contract ITwoKeyEventSourceStorage is IStructuredStorage {

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

contract TwoKeyEventSource is Upgradeable, ITwoKeySingletonUtils {

    bool initialized;

    ITwoKeyEventSourceStorage public PROXY_STORAGE_CONTRACT;


    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyFactory = "TwoKeyFactory";
    string constant _twoKeyRegistry = "TwoKeyRegistry";
    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _twoKeyExchangeRateContract = "TwoKeyExchangeRateContract";
    string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";
    string constant _deepFreezeTokenPool = "TwoKeyDeepFreezeTokenPool";

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    /**
     * Modifier which will allow only TwoKeyCampaignValidator to make some calls
     */
    modifier onlyTwoKeyCampaignValidator {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(msg.sender == twoKeyCampaignValidator);
        _;
    }

    /**
     * @notice Function to set initial params in the contract
     * @param _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY contract
     * @param _proxyStorage is the address of proxy of storage contract
     */
    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _proxyStorage
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyEventSourceStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * Events which will be emitted during use of system
     * All events are emitted from this contract
     * Every event is monitored in GraphQL
     */

    event Created(
        address _campaign,
        address _owner,
        address _moderator
    );

    event Joined(
        address _campaign,
        address _from,
        address _to
    );

    event Converted(
        address _campaign,
        address _converter,
        uint256 _amount
    );

    event ConvertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    );

    event ConvertedDonation(
        address _campaign,
        address _converterPlasma,
        uint _conversionAmount,
        uint _conversionId
    );

    event Rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    );

    event Cancelled(
        address _campaign,
        address _converter,
        uint256 _indexOrAmount
    );

    event Rejected(
        address _campaign,
        address _converter
    );

    event UpdatedPublicMetaHash(
        uint timestamp,
        string value
    );

    event UpdatedData(
        uint timestamp,
        uint value,
        string action
    );

    event ReceivedEther(
        address _sender,
        uint value
    );

    event AcquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    );

    event DonationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    );

    event CPCCampaignCreated(
        address proxyCPCCampaign,
        address contractor //Contractor public address
    );

    event PriceUpdated(
        bytes32 _currency,
        uint newRate,
        uint _timestamp,
        address _updater
    );

    event UserRegistered(
        string _handle,
        address _address
    );

    event Executed(
        address campaignAddress,
        address converterPlasmaAddress,
        uint conversionId,
        uint tokens
    );

    event TokenWithdrawnFromPurchasesHandler(
        address campaignAddress,
        uint conversionID,
        uint tokensAmountWithdrawn
    );

    event Debt (
        address plasmaAddress,
        uint weiAmount,
        bool addition, //If true means debt increasing otherwise it means that event emitted when user paid part of the debt
        string currency
    );

    event ReceivedTokensAsModerator(
        address campaignAddress,
        uint amountOfTokens
    );

    event ReceivedTokensDeepFreezeTokenPool(
        address campaignAddress,
        uint amountOfTokens
    );

    event HandleChanged(
        address userPlasmaAddress,
        string newHandle
    );

    event DaiReleased(
        address contractSenderAddress,
        uint amountOfDAI
    );

    event RebalancedRatesEvent (
        uint priceAtBeginning,
        uint priceAtRebalancingTime,
        uint ratio,
        uint amountOfTokensTransferedInAction,
        string actionPerformedWithUpgradableExchange
    );

    event EndedBudgetCampaign (
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    );

    event RebalancedRewards(
        uint cycleId,
        uint amountOfTokens,
        string action
    );

    event UserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    );

    /**
     * @notice Function to emit created event every time campaign is created
     * @param _campaign is the address of the deployed campaign
     * @param _owner is the contractor address of the campaign
     * @param _moderator is the address of the moderator in campaign
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function created(
        address _campaign,
        address _owner,
        address _moderator
    )
    external
    onlyTwoKeyCampaignValidator
    {
        emit Created(_campaign, _owner, _moderator);
    }

    /**
     * @notice Function to emit created event every time someone has joined to campaign
     * @param _campaign is the address of the deployed campaign
     * @param _from is the address of the referrer
     * @param _to is the address of person who has joined
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function joined(
        address _campaign,
        address _from,
        address _to
    )
    external
    onlyAllowedContracts
    {
        emit Joined(_campaign, _from, _to);
    }

    /**
     * @notice Function to emit converted event
     * @param _campaign is the address of main campaign contract
     * @param _converter is the address of converter during the conversion
     * @param _conversionAmount is conversion amount
     */
    function converted(
        address _campaign,
        address _converter,
        uint256 _conversionAmount
    )
    external
    onlyAllowedContracts
    {
        emit Converted(_campaign, _converter, _conversionAmount);
    }

    function rejected(
        address _campaign,
        address _converter
    )
    external
    onlyAllowedContracts
    {
        emit Rejected(_campaign, _converter);
    }


    /**
     * @notice Function to emit event every time conversion gets executed
     * @param _campaignAddress is the main campaign contract address
     * @param _converterPlasmaAddress is the address of converter plasma
     * @param _conversionId is the ID of conversion, unique per campaign
     */
    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external
    onlyAllowedContracts
    {
        emit Executed(_campaignAddress, _converterPlasmaAddress, _conversionId, tokens);
    }


    /**
     * @notice Function to emit created event every time conversion happened under AcquisitionCampaign
     * @param _campaign is the address of the deployed campaign
     * @param _converterPlasma is the converter address
     * @param _baseTokens is the amount of tokens bought
     * @param _bonusTokens is the amount of bonus tokens received
     * @param _conversionAmount is the amount of conversion
     * @param _isFiatConversion is flag representing if conversion is either FIAT or ETHER
     * @param _conversionId is the id of conversion
     * @dev this function updates values in TwoKeyRegistry contract
     */
    function convertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedAcquisition(
            _campaign,
            _converterPlasma,
            _baseTokens,
            _bonusTokens,
            _conversionAmount,
            _isFiatConversion,
            _conversionId
        );
    }



    /**
     * @notice Function to emit created event every time conversion happened under DonationCampaign
     * @param _campaign is the address of main campaign contract
     * @param _converterPlasma is the address of the converter
     * @param _conversionAmount is the amount of conversion
     * @param _conversionId is the id of conversion
     */
    function convertedDonation(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external
    onlyAllowedContracts
    {
        emit ConvertedDonation(
            _campaign,
            _converterPlasma,
            _conversionAmount,
            _conversionId
        );
    }

    /**
     * @notice Function to emit created event every time bounty is distributed between influencers
     * @param _campaign is the address of the deployed campaign
     * @param _to is the reward receiver
     * @param _amount is the reward amount
     */
    function rewarded(
        address _campaign,
        address _to,
        uint256 _amount
    )
    external
    onlyAllowedContracts
    {
        emit Rewarded(_campaign, _to, _amount);
    }

    /**
     * @notice Function to emit created event every time campaign is cancelled
     * @param _campaign is the address of the cancelled campaign
     * @param _converter is the address of the converter
     * @param _indexOrAmount is the amount of campaign
     */
    function cancelled(
        address  _campaign,
        address _converter,
        uint256 _indexOrAmount
    )
    external
    onlyAllowedContracts
    {
        emit Cancelled(_campaign, _converter, _indexOrAmount);
    }

    /**
     * @notice Function to emit event every time someone starts new Acquisition campaign
     * @param proxyLogicHandler is the address of TwoKeyAcquisitionLogicHandler proxy deployed by TwoKeyFactory
     * @param proxyConversionHandler is the address of TwoKeyConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyAcquisitionCampaign is the address of TwoKeyAcquisitionCampaign proxy deployed by TwoKeyFactory
     * @param proxyPurchasesHandler is the address of TwoKeyPurchasesHandler proxy deployed by TwoKeyFactory
     */
    function acquisitionCampaignCreated(
        address proxyLogicHandler,
        address proxyConversionHandler,
        address proxyAcquisitionCampaign,
        address proxyPurchasesHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit AcquisitionCampaignCreated(
            proxyLogicHandler,
            proxyConversionHandler,
            proxyAcquisitionCampaign,
            proxyPurchasesHandler,
            contractor
        );
    }

    /**
     * @notice Function to emit event every time someone starts new Donation campaign
     * @param proxyDonationCampaign is the address of TwoKeyDonationCampaign proxy deployed by TwoKeyFactory
     * @param proxyDonationConversionHandler is the address of TwoKeyDonationConversionHandler proxy deployed by TwoKeyFactory
     * @param proxyDonationLogicHandler is the address of TwoKeyDonationLogicHandler proxy deployed by TwoKeyFactory
     */
    function donationCampaignCreated(
        address proxyDonationCampaign,
        address proxyDonationConversionHandler,
        address proxyDonationLogicHandler,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit DonationCampaignCreated(
            proxyDonationCampaign,
            proxyDonationConversionHandler,
            proxyDonationLogicHandler,
            contractor
        );
    }


    /**
     * @notice Function to emit event every time someone starts new CPC campaign
     * @param proxyCPC is the proxy address of CPC campaign
     * @param contractor is the PUBLIC address of campaign contractor
     */
    function cpcCampaignCreated(
        address proxyCPC,
        address contractor
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFactory));
        emit CPCCampaignCreated(
            proxyCPC,
            contractor
        );
    }

    /**
     * @notice Function which will emit event PriceUpdated every time that happens under TwoKeyExchangeRateContract
     * @param _currency is the hexed string of currency name
     * @param _newRate is the new rate
     * @param _timestamp is the time of updating
     * @param _updater is the maintainer address which performed this call
     */
    function priceUpdated(
        bytes32 _currency,
        uint _newRate,
        uint _timestamp,
        address _updater
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract));
        emit PriceUpdated(_currency, _newRate, _timestamp, _updater);
    }

    /**
     * @notice Function to emit event every time user is registered
     * @param _handle is the handle of the user
     * @param _address is the address of the user
     */
    function userRegistered(
        string _handle,
        address _address,
        uint _registrationFee
    )
    external
    {
        require(isAddressMaintainer(msg.sender) == true);
        ITwoKeyFeeManager(getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager")).setRegistrationFeeForUser(_address, _registrationFee);
        emit UserRegistered(_handle, _address);
        emit Debt(_address, _registrationFee, true, "ETH");
    }

    function addAdditionalDebtForUser(
        address _plasmaAddress,
        uint _debtAmount,
        string _debtType
    )
    public
    {
        require(isAddressMaintainer(msg.sender) == true);
        ITwoKeyFeeManager(getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager")).addDebtForUser(_plasmaAddress, _debtAmount, _debtType);
        emit Debt(_plasmaAddress, _debtAmount, true, "ETH");
    }

    /**
     * @notice Function which will emit every time some debt is increased or paid
     * @param _plasmaAddress is the address of the user we are increasing/decreasing debt for
     * @param _amount is the amount of ETH he paid/increased
     * @param _isAddition is stating either debt increased or paid
     */
    function emitDebtEvent(
        address _plasmaAddress,
        uint _amount,
        bool _isAddition,
        string _currency
    )
    external
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager"));
        emit Debt(
            _plasmaAddress,
            _amount,
            _isAddition,
            _currency
        );
    }

    /**
     * @notice Function which will be called by TwoKeyAdmin every time it receives 2KEY tokens
     * as a moderator on TwoKeyCampaigns
     * @param _campaignAddress is the address of the campaign sending tokens
     * @param _amountOfTokens is the amount of tokens sent
     */
    function emitReceivedTokensAsModerator(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin));
        emit ReceivedTokensAsModerator(
            _campaignAddress,
            _amountOfTokens
        );
    }

    /**
     * @notice Function which will be called by TwoKeyDeepFreezeTokenPool every time it receives 2KEY tokens
     * from moderator rewards on the conversion event
     * @param _campaignAddress is the address of the campaign sending tokens
     * @param _amountOfTokens is the amount of tokens sent
     */
    function emitReceivedTokensToDeepFreezeTokenPool(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry(_deepFreezeTokenPool));
        emit ReceivedTokensDeepFreezeTokenPool(
            _campaignAddress,
            _amountOfTokens
        );
    }


    /**
     * @notice Function which will emit an event every time somebody performs
     * withdraw of bought tokens in AcquisitionCampaign contracts
     * @param _campaignAddress is the address of main campaign contract
     * @param _conversionID is the unique ID of conversion inside one campaign
     * @param _tokensAmountWithdrawn is the amount of tokens user withdrawn
     */
    function tokensWithdrawnFromPurchasesHandler(
        address _campaignAddress,
        uint _conversionID,
        uint _tokensAmountWithdrawn
    )
    external
    onlyAllowedContracts
    {
        emit TokenWithdrawnFromPurchasesHandler(_campaignAddress, _conversionID, _tokensAmountWithdrawn);
    }


    function emitRebalancedRatesEvent(
        uint priceAtBeginning,
        uint priceAtRebalancingTime,
        uint ratio,
        uint amountOfTokensTransferedInAction,
        string actionPerformedWithUpgradableExchange
    )
    external
    onlyAllowedContracts
    {
        emit RebalancedRatesEvent(
            priceAtBeginning,
            priceAtRebalancingTime,
            ratio,
            amountOfTokensTransferedInAction,
            actionPerformedWithUpgradableExchange
        );
    }

    function emitHandleChangedEvent(
        address _userPlasmaAddress,
        string _newHandle
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry"));

        emit HandleChanged(
            _userPlasmaAddress,
            _newHandle
        );
    }


    /**
     * @notice          Function to emit an event whenever DAI is released as an income
     *
     * @param           _campaignContractAddress is campaign contract address
     * @param           _amountOfDAI is the amount of DAI being released
     */
    function emitDAIReleasedAsIncome(
        address _campaignContractAddress,
        uint _amountOfDAI
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange"));

        emit DaiReleased(
            _campaignContractAddress,
            _amountOfDAI
        );
    }

    function emitEndedBudgetCampaign(
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    )
    public
    {
        require (msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        emit EndedBudgetCampaign(
            campaignPlasmaAddress,
            contractorLeftover,
            moderatorEarningsDistributed
        );
    }


    function emitRebalancedRewards(
        uint cycleId,
        uint difference,
        string action
    )
    public
    {
        require (msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        emit RebalancedRewards(
            cycleId,
            difference,
            action
        );
    }


    /**
     * @notice          Function which will emit event that user have withdrawn network earnings
     * @param           user is the address of the user
     * @param           amountOfTokens is the amount of tokens user withdrawn as network earnings
     */
    function emitUserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyParticipationMiningPool"));

        emit UserWithdrawnNetworkEarnings(
            user,
            amountOfTokens
        );
    }


    /**
     * @notice Function to check adequate plasma address for submitted eth address
     * @param me is the ethereum address we request corresponding plasma address for
     */
    function plasmaOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry);
        address plasma = ITwoKeyReg(twoKeyRegistry).getEthereumToPlasma(me);
        if (plasma != address(0)) {
            return plasma;
        }
        return me;
    }

    /**
     * @notice Function to determine ethereum address of plasma address
     * @param me is the plasma address of the user
     * @return ethereum address
     */
    function ethereumOf(
        address me
    )
    public
    view
    returns (address)
    {
        address twoKeyRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry);
        address ethereum = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(me);
        if (ethereum != address(0)) {
            return ethereum;
        }
        return me;
    }

    /**
     * @notice Address to check if an address is maintainer in TwoKeyMaintainersRegistry
     * @param _maintainer is the address we're checking this for
     */
    function isAddressMaintainer(
        address _maintainer
    )
    public
    view
    returns (bool)
    {
        address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
        bool _isMaintainer = ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).checkIsAddressMaintainer(_maintainer);
        return _isMaintainer;
    }

    /**
     * @notice In default TwoKeyAdmin will be moderator and his fee percentage per conversion is predefined
     */
    function getTwoKeyDefaultIntegratorFeeFromAdmin()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        uint integratorFeePercentage = ITwoKeyAdmin(twoKeyAdmin).getDefaultIntegratorFeePercent();
        return integratorFeePercentage;
    }

    /**
     * @notice Function to get default network tax percentage
     */
    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint)
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        uint networkTaxPercent = ITwoKeyAdmin(twoKeyAdmin).getDefaultNetworkTaxPercent();
        return networkTaxPercent;
    }
}