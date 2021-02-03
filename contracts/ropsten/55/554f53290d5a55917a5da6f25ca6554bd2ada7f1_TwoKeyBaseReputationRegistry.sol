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

contract ITwoKeyAcquisitionLogicHandler {
    function canContractorWithdrawUnsoldTokens() public view returns (bool);
    bool public IS_CAMPAIGN_ACTIVE;
    function getEstimatedTokenAmount(uint conversionAmountETHWei, bool isFiatConversion) public view returns (uint, uint);
    function getReferrers(address customer) public view returns (address[]);
    function updateRefchainRewards(address _converter, uint _conversionId, uint totalBounty2keys) public;
    function getReferrerPlasmaTotalEarnings(address _referrer) public view returns (uint);
    function checkAllRequirementsForConversionAndTotalRaised(address converter, uint conversionAmount, bool isFiatConversion, uint debtPaid) external returns (bool,uint);
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

contract ITwoKeyBaseReputationRegistryStorage is IStructuredStorage {

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

contract TwoKeyBaseReputationRegistry is Upgradeable, ITwoKeySingletonUtils {

    /**
     * Storage keys are stored on the top. Here they are in order to avoid any typos
     */
    string constant _address2contractorGlobalReputationScoreWei = "address2contractorGlobalReputationScoreWei";
    string constant _address2converterGlobalReputationScoreWei = "address2converterGlobalReputationScoreWei";
    string constant _plasmaAddress2referrerGlobalReputationScoreWei = "plasmaAddress2referrerGlobalReputationScoreWei";

    /**
     * Keys for the addresses we're accessing
     */
    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyRegistry = "TwoKeyRegistry";
    bool initialized;

    ITwoKeyBaseReputationRegistryStorage public PROXY_STORAGE_CONTRACT;


    /**
     * @notice          Event which will be emitted every time reputation of a user
     *                  is getting changed. Either positive or negative.
     */
    event ReputationUpdated(
        address _plasmaAddress,
        string _role, //role in (CONTRACTOR,REFERRER,CONVERTER)
        string _type, // type in (MONETARY,BUDGET,FEEDBACK)
        int _points,
        address _campaignAddress
    );

    /**
     * @notice Since using singletone pattern, this is replacement for the constructor
     * @param _twoKeySingletoneRegistry is the address of registry of all singleton contracts
     */
    function setInitialParams(
        address _twoKeySingletoneRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletoneRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBaseReputationRegistryStorage(_proxyStorage);

        initialized = true;
    }

    /**
     * @notice Modifier to validate that the call is coming from validated campaign
     */
    modifier isCodeValid() {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    /**
     * @notice If the conversion executed event occured, 10 points for the converter and contractor + 10/distance to referrer
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param campaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionExecutedEvent(
        address converter,
        address contractor,
        address campaign
    )
    public
    isCodeValid
    {
        int initialRewardWei = 10*(10**18);

        updateContractorScore(contractor, initialRewardWei);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore + initialRewardWei);

        emit ReputationUpdated(
            plasmaOf(converter),
            "CONVERTER",
            "MONETARY",
            initialRewardWei,
            msg.sender
        );

        address[] memory referrers = getReferrers(converter, campaign);

        int j=0;
        int len = int(referrers.length) - 1;
        for(int i=len; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore + reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "MONETARY",
                reward,
                msg.sender
            );

            j++;
        }
    }

    /**
     * @notice If the conversion rejected event occured, giving penalty points
     * @param converter is the address of the converter
     * @param contractor is the address of the contractor
     * @param campaign is the address of the acquisition campaign so we can get referrers from there
     */
    function updateOnConversionRejectedEvent(
        address converter,
        address contractor,
        address campaign
    )
    public
    isCodeValid
    {
        int initialRewardWei = 5*(10**18);

        updateContractorScoreOnRejectedConversion(contractor, initialRewardWei);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, converter);
        int converterScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashConverterScore, converterScore - initialRewardWei);

        emit ReputationUpdated(
            plasmaOf(converter),
            "CONVERTER",
            "MONETARY",
            initialRewardWei * (-1),
            msg.sender
        );

        address[] memory referrers = getReferrers(converter, campaign);

        int j=0;
        for(int i=int(referrers.length)-1; i>=0; i--) {
            bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, referrers[uint(i)]);
            int referrerScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);
            int reward = initialRewardWei/(j+1);
            PROXY_STORAGE_CONTRACT.setInt(keyHashReferrerScore, referrerScore - reward);

            emit ReputationUpdated(
                referrers[uint(i)],
                "REFERRER",
                "MONETARY",
                reward*(-1),
                msg.sender
            );
            j++;
        }
    }

    function updateContractorScoreOnRejectedConversion(
        address contractor,
        int reward
    )
    internal
    {
        updateContractorScore(contractor, reward*(-1));
    }

    function updateContractorScore(
        address contractor,
        int reward
    )
    internal
    {
        bytes32 keyHashContractorScore = keccak256(_address2contractorGlobalReputationScoreWei, contractor);
        int contractorScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);
        PROXY_STORAGE_CONTRACT.setInt(keyHashContractorScore, contractorScore + reward);

        emit ReputationUpdated(
            plasmaOf(contractor),
            "CONTRACTOR",
            "MONETARY",
            reward,
            msg.sender
        );
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch logic handler address
     */
    function getLogicHandlerAddress(
        address campaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyCampaign(campaign).logicHandler();
    }

    /**
     * @notice Internal getter from Acquisition campaign to fetch conersion handler address
     */
    function getConversionHandlerAddress(
        address campaign
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyCampaign(campaign).conversionHandler();
    }


    /**
     * @notice Function to get all referrers in the chain for specific converter
     * @param converter is the converter we want to get referral chain
     * @param campaign is the acquisition campaign contract
     * @return array of addresses (referrers)
     */
    function getReferrers(
        address converter,
        address campaign
    )
    internal
    view
    returns (address[])
    {
        address logicHandlerAddress = getLogicHandlerAddress(campaign);
        return ITwoKeyAcquisitionLogicHandler(logicHandlerAddress).getReferrers(converter);
    }


    /**
     * @notice          Function to get reputation for user in case he's an influencer or converter
     */
    function getReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int,int)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress(_twoKeyRegistry);
        address ethereumAddress = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_plasmaAddress);

        bytes32 keyHashConverterScore = keccak256(_address2converterGlobalReputationScoreWei, ethereumAddress);
        int converterReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashConverterScore);

        bytes32 keyHashReferrerScore = keccak256(_plasmaAddress2referrerGlobalReputationScoreWei, _plasmaAddress);
        int referrerReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashReferrerScore);

        return (converterReputationScore, referrerReputationScore);
    }

    function getGlobalReputationForUser(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        int converterReputationScore;
        int referrerReputationScore;

        (converterReputationScore, referrerReputationScore) = getReputationForUser(_plasmaAddress);

        return (converterReputationScore + referrerReputationScore);
    }


    function getGlobalReputationForUsers(
        address [] plasmaAddresses
    )
    public
    view
    returns (int[])
    {
        uint len = plasmaAddresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getGlobalReputationForUser(plasmaAddresses[i]);
        }

        return (reputations);
    }

    /**
     * @notice          Function to get reputation for user in case he's contractor
     */
    function getReputationForContractor(
        address _plasmaAddress
    )
    public
    view
    returns (int)
    {
        address twoKeyRegistry = ITwoKeySingletoneRegistryFetchAddress(TWO_KEY_SINGLETON_REGISTRY).getContractProxyAddress(_twoKeyRegistry);
        address ethereumAddress = ITwoKeyReg(twoKeyRegistry).getPlasmaToEthereum(_plasmaAddress);

        bytes32 keyHashContractorScore = keccak256(_address2contractorGlobalReputationScoreWei, ethereumAddress);
        int contractorReputationScore = PROXY_STORAGE_CONTRACT.getInt(keyHashContractorScore);

        return (contractorReputationScore);
    }


    function getGlobalReputationForContractors(
        address [] plasmaAddresses
    )
    public
    view
    returns (int[])
    {
        uint len = plasmaAddresses.length;

        int [] memory reputations = new int[](len);

        uint i;

        for(i=0; i<len; i++) {
            reputations[i] = getReputationForContractor(plasmaAddresses[i]);
        }

        return (reputations);
    }

    function plasmaOf(
        address _address
    )
    internal
    view
    returns (address)
    {
        return ITwoKeyReg(getAddressFromTwoKeySingletonRegistry(_twoKeyRegistry)).getEthereumToPlasma(_address);
    }
}