/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

contract IERC20 {
    function balanceOf(
        address whom
    )
    external
    view
    returns (uint);


    function transfer(
        address _to,
        uint256 _value
    )
    external
    returns (bool);


    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    returns (bool);



    function approve(
        address _spender,
        uint256 _value
    )
    public
    returns (bool);



    function decimals()
    external
    view
    returns (uint);


    function symbol()
    external
    view
    returns (string);


    function name()
    external
    view
    returns (string);


    function freezeTransfers()
    external;


    function unfreezeTransfers()
    external;
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

contract ITwoKeyEventSource {

    function ethereumOf(address me) public view returns (address);
    function plasmaOf(address me) public view returns (address);
    function isAddressMaintainer(address _maintainer) public view returns (bool);
    function getTwoKeyDefaultIntegratorFeeFromAdmin() public view returns (uint);
    function joined(address _campaign, address _from, address _to) external;
    function rejected(address _campaign, address _converter) external;

    function convertedAcquisition(
        address _campaign,
        address _converterPlasma,
        uint256 _baseTokens,
        uint256 _bonusTokens,
        uint256 _conversionAmount,
        bool _isFiatConversion,
        uint _conversionId
    )
    external;

    function getTwoKeyDefaultNetworkTaxPercent()
    public
    view
    returns (uint);

    function convertedDonation(
        address _campaign,
        address _converterPlasma,
        uint256 _conversionAmount,
        uint256 _conversionId
    )
    external;

    function executed(
        address _campaignAddress,
        address _converterPlasmaAddress,
        uint _conversionId,
        uint tokens
    )
    external;

    function tokensWithdrawnFromPurchasesHandler(
        address campaignAddress,
        uint _conversionID,
        uint _tokensAmountWithdrawn
    )
    external;

    function emitDebtEvent(
        address _plasmaAddress,
        uint _amount,
        bool _isAddition,
        string _currency
    )
    external;

    function emitReceivedTokensToDeepFreezeTokenPool(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitReceivedTokensAsModerator(
        address _campaignAddress,
        uint _amountOfTokens
    )
    public;

    function emitDAIReleasedAsIncome(
        address _campaignContractAddress,
        uint _amountOfDAI
    )
    public;

    function emitEndedBudgetCampaign(
        address campaignPlasmaAddress,
        uint contractorLeftover,
        uint moderatorEarningsDistributed
    )
    public;


    function emitUserWithdrawnNetworkEarnings(
        address user,
        uint amountOfTokens
    )
    public;

    function emitRebalancedRewards(
        uint cycleId,
        uint difference,
        string action
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

contract ITwoKeyDeepFreezeTokenPoolStorage is IStructuredStorage {

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

contract TokenPool is Upgradeable, ITwoKeySingletonUtils {

    bool initialized = false;

    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _twoKeyEconomy = "TwoKeyEconomy";

    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin);
        _;
    }

    /**
     * @notice Function to retrieve the balance of tokens on the contract
     */
    function getContractBalance()
    public
    view
    returns (uint)
    {
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
        return IERC20(twoKeyEconomy).balanceOf(address(this));
    }

    /**
     * @notice Function to transfer tokens
     */
    function transferTokens(
        address receiver,
        uint amount
    )
    internal
    {
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
        IERC20(twoKeyEconomy).transfer(receiver,amount);
    }

}

contract TwoKeyDeepFreezeTokenPool is TokenPool {

    ITwoKeyDeepFreezeTokenPoolStorage public PROXY_STORAGE_CONTRACT;

    string constant _tokensReleaseDate = "tokensReleaseDate";
    string constant _tokensReceivedFromModeratorRewards = "tokensReceivedFromModeratorRewards";

    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyEventSource = "TwoKeyEventSource";

    address public twoKeyParticipationMiningPool;

    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    function setInitialParams(
        address _twoKeySingletonesRegistry,
        address _twoKeyParticipationMiningPool,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;

        PROXY_STORAGE_CONTRACT = ITwoKeyDeepFreezeTokenPoolStorage(_proxyStorage);
        twoKeyParticipationMiningPool = _twoKeyParticipationMiningPool;

        PROXY_STORAGE_CONTRACT.setUint(keccak256(_tokensReleaseDate), block.timestamp + 10 * (1 years));

        initialized = true;
    }

    /**
     * @notice Function can transfer tokens only after 10 years to community token pool
     * @param amount is the amount of tokens we're sending
     * @dev only two key admin can issue a call to this method
     */
    function transferTokensToCommunityPool(
        uint amount
    )
    public
    onlyTwoKeyAdmin
    {
        uint tokensReleaseDate = PROXY_STORAGE_CONTRACT.getUint(keccak256(_tokensReleaseDate));

        require(getContractBalance() >= amount);
        require(block.timestamp > tokensReleaseDate);
        super.transferTokens(twoKeyParticipationMiningPool,amount);
    }

    function updateReceivedTokensForSuccessfulConversions(
        uint amountOfTokens,
        address campaignAddress
    )
    public
    onlyTwoKeyAdmin
    {
        bytes32 keyHashTotalRewards = keccak256(_tokensReceivedFromModeratorRewards);
        PROXY_STORAGE_CONTRACT.setUint(keyHashTotalRewards, amountOfTokens + (PROXY_STORAGE_CONTRACT.getUint(keyHashTotalRewards)));

        //Emit event through TwoKeyEventSource for the campaign
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource)).emitReceivedTokensToDeepFreezeTokenPool(campaignAddress, amountOfTokens);
    }


}