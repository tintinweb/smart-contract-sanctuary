/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity ^0.4.13;

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _ocwner, address _spender) public view returns (uint256);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

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

contract IKyberReserveInterface {

    // Pricing contract
    uint public collectedFeesInTwei;
    // Pricing contract
    function resetCollectedFees() public;
    // Pricing contract
    function setLiquidityParams(
        uint _rInFp,
        uint _pMinInFp,
        uint _numFpBits,
        uint _maxCapBuyInWei,
        uint _maxCapSellInWei,
        uint _feeInBps,
        uint _maxTokenToEthRateInPrecision,
        uint _minTokenToEthRateInPrecision
    ) public;

    function withdraw(ERC20 token, uint amount, address destination) public returns(bool);
    function disableTrade() public returns (bool);
    function enableTrade() public returns (bool);
    function withdrawEther(uint amount, address sendTo) external;
    function withdrawToken(ERC20 token, uint amount, address sendTo) external;
    function setContracts(address _kyberNetwork, address _conversionRates, address _sanityRates) public;
    function getDestQty(ERC20 src, ERC20 dest, uint srcQty, uint rate) public view returns(uint);
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

contract ITwoKeyCampaignValidator {
    function isCampaignValidated(address campaign) public view returns (bool);
    function validateAcquisitionCampaign(address campaign, string nonSingletonHash) public;
    function validateDonationCampaign(address campaign, address donationConversionHandler, address donationLogicHandler, string nonSingletonHash) public;
    function validateCPCCampaign(address campaign, string nonSingletonHash) public;
}

contract ITwoKeyDeepFreezeTokenPool {
    function updateReceivedTokensForSuccessfulConversions(
        uint amount,
        address campaignAddress
    )
    public;
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

contract IUpgradableExchange {

    function buyRate2key() public view returns (uint);
    function sellRate2key() public view returns (uint);

    function buyTokensWithERC20(
        uint amountOfTokens,
        address tokenAddress
    )
    public
    returns (uint,uint);

    function buyTokens(
        address _beneficiary
    )
    public
    payable
    returns (uint,uint);

    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    payable;

    function report2KEYWithdrawnFromNetwork(
        uint amountOfTokensWithdrawn
    )
    public;

    function getEth2DaiAverageExchangeRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function getContractId(
        address _contractAddress
    )
    public
    view
    returns (uint);

    function getEth2KeyAverageRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint);

    function returnLeftoverAfterRebalancing(
        uint amountOf2key
    )
    public;


    function getMore2KeyTokensForRebalancing(
        uint amountOf2KeyRequested
    )
    public
    view
    returns (uint);


    function releaseAllDAIFromContractToReserve()
    public;

    function setKyberReserveInterfaceContractAddress(
        address kyberReserveContractAddress
    )
    public;

    function setSpreadWei(
        uint newSpreadWei
    )
    public;

    function withdrawDAIAvailableToFill2KEYReserve(
        uint amountOfDAI
    )
    public
    returns (uint);

    function returnTokensBackToExchangeV1(
        uint amountOfTokensToReturn
    )
    public;


    function getMore2KeyTokensForRebalancingV1(
        uint amountOfTokensRequested
    )
    public;
}

contract ITwoKeyAdminStorage is IStructuredStorage {

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    require(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    require(c >= _a);
    return c;
  }
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

contract TwoKeyAdmin is Upgradeable, ITwoKeySingletonUtils {

	using SafeMath for *;


	/**
	 * Storage keys are stored on the top. Here they are in order to avoid any typos
	 */
	string constant _twoKeyIntegratorDefaultFeePercent = "twoKeyIntegratorDefaultFeePercent";
	string constant _twoKeyNetworkTaxPercent = "twoKeyNetworkTaxPercent";
	string constant _twoKeyTokenRate = "twoKeyTokenRate";
	string constant _rewardReleaseAfter = "rewardReleaseAfter";

    /**
     * Accounting necessary stuff
     */

    //Income to ADMIN
    string constant _rewardsReceivedAsModeratorTotal = "rewardsReceivedAsModeratorTotal";
    string constant _moderatorEarningsPerCampaign = "moderatorEarningsPerCampaign";
    string constant _feesFromFeeManagerCollectedInCurrency = "feesFromFeeManagerCollectedInCurrency";
	string constant _feesCollectedFromKyber = "feesCollectedFromKyber";
	string constant _daiCollectedFromUpgradableExchange = "daiCollectedFromUpgradableExchange";
	string constant _feesCollectedFromDistributionRewards = "feesCollectedFromDistributionRewards";


	// Withdrawals from ADMIN
	string constant _amountWithdrawnFromModeratorEarningsPool = "amountWithdrawnFromModeratorEarningsPool";
	string constant _amountWithdrawnFromFeeManagerPoolInCurrency = "amountWithdrawnFromFeeManagerPoolInCurrency";
	string constant _amountWithdrawnFromKyberFeesPool = "amountWithdrawnFromKyberFeesPool";
	string constant _amountWithdrawnFromCollectedDaiFromUpgradableExchange = "amountWithdrawnFromCollectedDaiFromUpgradableExchange";
	string constant _amountWithdrawnFromCollectedDistributionRewards = "amountWithdrawnFromCollectedDistributionRewards";

	/**
     * Keys for the addresses we're accessing
     */
	string constant _twoKeyCongress = "TwoKeyCongress";
	string constant _twoKeyUpgradableExchange = "TwoKeyUpgradableExchange";
	string constant _twoKeyRegistry = "TwoKeyRegistry";
	string constant _twoKeyEconomy = "TwoKeyEconomy";
	string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
	string constant _twoKeyEventSource = "TwoKeyEventSource";
	string constant _twoKeyFeeManager = "TwoKeyFeeManager";
	string constant _twoKeyMaintainersRegistry = "TwoKeyMaintainersRegistry";
	string constant _DAI_TOKEN = "DAI";

	bool initialized = false;


	ITwoKeyAdminStorage public PROXY_STORAGE_CONTRACT; 			//Pointer to storage contract


	/**
	 * @notice 			Modifier which throws if caller is not TwoKeyCongress
	 */
	modifier onlyTwoKeyCongress {
		require(msg.sender == getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyCongress));
	    _;
	}

	modifier onlyTwoKeyBudgetCampaignsPaymentsHandler {
		address twoKeyBudgetCampaignsPaymentsHandler = getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler");
		require(msg.sender == twoKeyBudgetCampaignsPaymentsHandler);
		_;
	}

	/**
	 * @notice 			Modifier which throws if the campaign contract sending request is not validated
	 * 					by TwoKeyCampaignValidator contract
	 */
	modifier onlyAllowedContracts {
		address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
		require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
		_;
	}


	/**
	 * @notice			Modifier which throws if the contract sending request is not
	 *					TwoKeyFeeManager contract
	 */
	modifier onlyTwoKeyFeeManager {
		require(msg.sender == getAddressFromTwoKeySingletonRegistry(_twoKeyFeeManager));
		_;
	}


    /**
     * @notice 			Function to set initial parameters in the contract including singletones
     *
     * @param 			_twoKeySingletonRegistry is the singletons registry contract address
     * @param 			_proxyStorageContract is the address of proxy for storage for this contract
     *
     * @dev 			This function can be called only once, which will be done immediately after deployment.
     */
    function setInitialParams(
		address _twoKeySingletonRegistry,
		address _proxyStorageContract,
		uint _twoKeyTokenReleaseDate
    )
	public
	{
        require(initialized == false);

		TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
		PROXY_STORAGE_CONTRACT = ITwoKeyAdminStorage(_proxyStorageContract);

		setUint(_twoKeyIntegratorDefaultFeePercent,2);
		setUint(_twoKeyNetworkTaxPercent,25);
		setUint(_rewardReleaseAfter, _twoKeyTokenReleaseDate);

        initialized = true;
    }


    /**
     * @notice 			Function where only TwoKeyCongress can transfer ether to an address
     *
     * @dev 			We're recurring to address different from address 0 and value is in WEI
     *
     * @param 			to is representing receiver's address
     * @param 			amount of ether to be transferred

     */
	function transferEtherByAdmins(
		address to,
		uint256 amount
	)
	external
	onlyTwoKeyCongress
	{
		require(to != address(0));
		to.transfer(amount);
	}


	/**
	 * @notice 			Function to forward call from congress to the Maintainers Registry and add core devs
	 *
	 * @param 			_coreDevs is the array of core devs to be added to the system
	 */
	function addCoreDevsToMaintainerRegistry(
		address [] _coreDevs
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).addCoreDevs(_coreDevs);
	}


	/**
	 * @notice 			Function to forward call from congress to the Maintainers Registry and add maintainers
	 *
	 * @param 			_maintainers is the array of core devs to be added to the system
	 */
	function addMaintainersToMaintainersRegistry(
		address [] _maintainers
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).addMaintainers(_maintainers);
	}


	/**
	 * @notice 			Function to forward call from congress to the Maintainers Registry and remove core devs
	 *
	 * @param 			_coreDevs is the array of core devs to be removed from the system
	 */
	function removeCoreDevsFromMaintainersRegistry(
		address [] _coreDevs
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).removeCoreDevs(_coreDevs);
	}


	/**
	 * @notice 			Function to forward call from congress to the Maintainers Registry and remove maintainers
	 *
	 * @param 			_maintainers is the array of maintainers to be removed from the system
	 */
	function removeMaintainersFromMaintainersRegistry(
		address [] _maintainers
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyMaintainersRegistry = getAddressFromTwoKeySingletonRegistry(_twoKeyMaintainersRegistry);
		ITwoKeyMaintainersRegistry(twoKeyMaintainersRegistry).removeMaintainers(_maintainers);
	}



	/**
	 * @notice 			Function to freeze all transfers for 2KEY token
	 *					Which means that no one transfer of ERC20 2KEY can be performed
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function freezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).freezeTransfers();
	}


	/**
	 * @notice 			Function to unfreeze all transfers for 2KEY token
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function unfreezeTransfersInEconomy()
	external
	onlyTwoKeyCongress
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		IERC20(twoKeyEconomy).unfreezeTransfers();
	}


	/**
	 * @notice 			Function to transfer 2key tokens from the admin contract
	 * @dev 			only TwoKeyCongress can call this function
	 * @param 			_to is address representing tokens receiver
	 * @param 			_amount is the amount of tokens to be transferred
 	 */
    function transfer2KeyTokens(
		address _to,
		uint256 _amount
	)
	external
	onlyTwoKeyCongress
	returns (bool)
	{
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		bool completed = IERC20(twoKeyEconomy).transfer(_to, _amount);
		return completed;
	}

	/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	 *                                                                               *
	 *				ACCOUNTING (BOOKKEEPING) NECESSARY STUFF                         *
	 *                                                                               *
	 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	/**
	 * @notice			Function to update whenever some funds are arriving to TwoKeyAdmin
	 *					from TwoKeyFeeManager contract
	 *
	 * @param			currency is in which currency contract received asset
	 * @param			amount is the amount which is received
	 */
	function addFeesCollectedInCurrency(
		string currency,
		uint amount
	)
	public
	payable
	onlyTwoKeyFeeManager
	{
		bytes32 key = keccak256(_feesFromFeeManagerCollectedInCurrency, currency);
		uint feesCollectedFromFeeManagerInCurrency = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, feesCollectedFromFeeManagerInCurrency.add(amount));
	}


	//	/**
	//	 * @notice			Function to handle and update state every time there's an
	//	 *					income from Kyber network fees
	//	 *
	//	 * @param			amount is the amount contract have received from there
	//	 */
	//	function addFeesCollectedFromKyber(
	//		uint amount
	//	)
	//	internal
	//	{
	//		bytes32 key = keccak256(_feesCollectedFromKyber);
	//		uint feesCollectedFromKyber = PROXY_STORAGE_CONTRACT.getUint(key);
	//		PROXY_STORAGE_CONTRACT.setUint(key, feesCollectedFromKyber.add(amount));
	//	}

	//	/**
	//	 * @notice			Function to withdraw fees collected on Kyber contract to Admin contract
	//	 *
	//	 * @param			reserveContract	is the address of kyber reserve contract for 2KEY token
	//	 * @param			pricingContract is the address of kyber pricing contract for 2KEY token
	//	 */
	//	function withdrawFeesFromKyber(
	//		address reserveContract,
	//		address pricingContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		disableTradeInKyberInternal(reserveContract);
	//		uint availableFees = getKyberAvailableFeesOnReserve(pricingContract);
	//		withdrawTokensFromKyberReserveInternal(
	//			reserveContract,
	//			ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)),
	//			availableFees,
	//			address(this)
	//		);
	//		resetFeesCounterOnKyberContract(pricingContract);
	//		enableTradeInKyberInternal(reserveContract);
	//		addFeesCollectedFromKyber(availableFees);
	//	}


	/**
	 * @notice 			Function to withdraw DAI we have on TwoKeyUpgradableExchange contract
	 *
	 * @param			_amountOfTokens is the amount of the tokens we're willing to withdraw
	 *
	 * @dev 			Restricted only to TwoKeyCongress contract
	 */
	function withdrawDAIAvailableToFillReserveFromUpgradableExchange(
		uint _amountOfTokens
	)
	external
	onlyTwoKeyCongress
	{
		address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry(_twoKeyUpgradableExchange);
		uint collectedDAI = IUpgradableExchange(twoKeyUpgradableExchange).withdrawDAIAvailableToFill2KEYReserve(_amountOfTokens);

		bytes32 key = keccak256(_daiCollectedFromUpgradableExchange);
		uint _amountWithdrawnCurrently = PROXY_STORAGE_CONTRACT.getUint(key);
		PROXY_STORAGE_CONTRACT.setUint(key, _amountWithdrawnCurrently.add(collectedDAI));
	}

	/**
	 * @notice			Function to withdraw moderator earnings from TwoKeyAdmin contract
	 * 					If 0 is passed as amountToBeWithdrawn, everything available will
	 *					be withdrawn
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens which will be withdrawn
	 */
	function withdrawModeratorEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint moderatorEarningsReceived = getAmountOfTokensReceivedAsModerator();
		uint moderatorEarningsWithdrawn = getAmountOfTokensWithdrawnFromModeratorEarnings();

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = moderatorEarningsReceived.sub(moderatorEarningsWithdrawn);
		} else {
			require(amountToBeWithdrawn <= moderatorEarningsReceived.sub(moderatorEarningsWithdrawn));
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToBeWithdrawn);

		bytes32 keyHash = keccak256(_amountWithdrawnFromModeratorEarningsPool);
		PROXY_STORAGE_CONTRACT.setUint(keyHash, moderatorEarningsWithdrawn.add(amountToBeWithdrawn));
	}

//	function burnModeratorEarnings()
	//TODO: Add function to BURN moderator earnings from Admin (send to 0x0)
	//TODO: For all WITHDRAW funnels if amountToBeWithdrawn = 0 then withdraw/burn everything which is there
	function withdrawFeeManagerEarningsFromAdmin(
		address beneficiary,
		string currency,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{

		uint feeManagerEarningsInCurrency = getAmountCollectedFromFeeManagerInCurrency(currency);
		uint feeManagerEarningsWithdrawn = getAmountWithdrawnFromFeeManagerEarningsInCurrency(currency);

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = feeManagerEarningsInCurrency.sub(feeManagerEarningsWithdrawn);
		} else {
			require(feeManagerEarningsInCurrency.sub(feeManagerEarningsWithdrawn) >= amountToBeWithdrawn);
		}

		if(keccak256(currency) == keccak256("ETH")) {
			beneficiary.transfer(amountToBeWithdrawn);
		} else {
			transferTokens(currency, beneficiary, amountToBeWithdrawn);
		}
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromFeeManagerPoolInCurrency,currency), feeManagerEarningsWithdrawn.add(amountToBeWithdrawn));
	}

	/**
	 * @notice			Function to withdraw earnings collected from Kyber fees from Admin contract
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens to be withdrawn
	 */
	function withdrawKyberFeesEarningsFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint kyberTotalReceived = getAmountCollectedFromKyber();
		uint kyberTotalWithdrawn = getAmountWithdrawnFromKyberEarnings();

		if(amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = kyberTotalReceived.sub(kyberTotalWithdrawn);
		} else {
			require(amountToBeWithdrawn <= kyberTotalReceived.sub(kyberTotalWithdrawn));
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToBeWithdrawn);

		PROXY_STORAGE_CONTRACT.setUint(
			keccak256(_amountWithdrawnFromKyberFeesPool),
			kyberTotalWithdrawn.add(amountToBeWithdrawn)
		);
	}

	/**
	 * @notice 			Function to withdraw DAI collected from UpgradableExchange from Admin
	 *
	 * @param			beneficiary is the address which is receiving tokens
	 * @param			amountToBeWithdrawn is the amount of tokens to be withdrawns
	 */
	function withdrawUpgradableExchangeDaiCollectedFromAdmin(
		address beneficiary,
		uint amountToBeWithdrawn
	)
	public
	onlyTwoKeyCongress
	{
		uint totalDAICollectedFromPool = getAmountCollectedInDAIFromUpgradableExchange();
		uint totalDAIWithdrawnFromPool = getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings();

		if (amountToBeWithdrawn == 0) {
			amountToBeWithdrawn = totalDAICollectedFromPool.sub(totalDAIWithdrawnFromPool);
		} else {
			require(totalDAIWithdrawnFromPool.add(amountToBeWithdrawn) <= totalDAICollectedFromPool);
		}

		transferTokens(_DAI_TOKEN, beneficiary, amountToBeWithdrawn);

		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromCollectedDaiFromUpgradableExchange), totalDAIWithdrawnFromPool.add(amountToBeWithdrawn));
	}

	function withdrawFeesCollectedFromDistributionRewards(
		address beneficiary,
		uint amountToWithdraw
	)
	public
	onlyTwoKeyCongress
	{
		uint totalFeesCollected = getAmountOfTokensReceivedFromDistributionFees();
		uint totalFeesWithdrawn = getAmountOfTokensWithdrawnFromDistributionFees();

		if (amountToWithdraw == 0) {
			amountToWithdraw = totalFeesCollected.sub(totalFeesWithdrawn);
		} else {
			require(totalFeesWithdrawn.add(amountToWithdraw) <= totalFeesCollected);
		}

		transferTokens(_twoKeyEconomy, beneficiary, amountToWithdraw);
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_amountWithdrawnFromCollectedDistributionRewards), totalFeesWithdrawn.add(amountToWithdraw));
	}

	/**
	 * @notice			Function for PPC campaigns to update received tokens
	 */
	function updateReceivedTokensAsModeratorPPC(
		uint amountOfTokens,
		address campaignPlasma
	)
	public
	onlyTwoKeyBudgetCampaignsPaymentsHandler
	{
		updateTokensReceivedAsModeratorInternal(amountOfTokens, campaignPlasma);
	}

	/**
	 * @notice			Function to update tokens received from distribution fees
	 * @param			amountOfTokens is the amount of tokens to be sent to admin
	 */
	function updateTokensReceivedFromDistributionFees(
		uint amountOfTokens
	)
	public
	onlyTwoKeyBudgetCampaignsPaymentsHandler
	{
		uint amountCollected = getAmountOfTokensReceivedFromDistributionFees();

        PROXY_STORAGE_CONTRACT.setUint(
            keccak256(_feesCollectedFromDistributionRewards),
            amountCollected.add(amountOfTokens)
        );
    }


    /**
     * @notice 			Function which will be used take the tokens from the campaign and distribute
     * 					them between itself and TwoKeyDeepFreezeTokenPool
     *
     * @param			amountOfTokens is the amount of the tokens which are for moderator rewards
      */
    function updateReceivedTokensAsModerator(
        uint amountOfTokens
    )
	public
	onlyAllowedContracts
	{
		uint moderatorTokens = updateTokensReceivedAsModeratorInternal(amountOfTokens, msg.sender);
		//Update moderator earnings to campaign
		ITwoKeyCampaign(msg.sender).updateModeratorRewards(moderatorTokens);
	}

	function updateTokensReceivedAsModeratorInternal(
		uint amountOfTokens,
		address campaignAddress
	)
	internal
	returns (uint)
	{
		// Network fee which will be taken from moderator
		uint networkFee = getDefaultNetworkTaxPercent();

		uint moderatorTokens = amountOfTokens.mul(100 - networkFee).div(100);

		bytes32 keyHashTotalRewards = keccak256(_rewardsReceivedAsModeratorTotal);
		PROXY_STORAGE_CONTRACT.setUint(keyHashTotalRewards, moderatorTokens.add((PROXY_STORAGE_CONTRACT.getUint(keyHashTotalRewards))));

		//Emit event through TwoKeyEventSource for the campaign
		ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry(_twoKeyEventSource)).emitReceivedTokensAsModerator(campaignAddress, moderatorTokens);

		//Now update twoKeyDeepFreezeTokenPool
		address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
		address deepFreezeTokenPool = getAddressFromTwoKeySingletonRegistry("TwoKeyDeepFreezeTokenPool");

		uint tokensForDeepFreezeTokenPool = amountOfTokens.sub(moderatorTokens);

		//Transfer tokens to deep freeze token pool
		transferTokens(_twoKeyEconomy, deepFreezeTokenPool, tokensForDeepFreezeTokenPool);

		//Update contract on receiving tokens
		ITwoKeyDeepFreezeTokenPool(deepFreezeTokenPool).updateReceivedTokensForSuccessfulConversions(tokensForDeepFreezeTokenPool, campaignAddress);

		// Compute the hash for the storage for moderator earnings per campaign
		bytes32 keyHashEarningsPerCampaign = keccak256(_moderatorEarningsPerCampaign, campaignAddress);
		// Take the current earnings
		uint currentEarningsForThisCampaign = PROXY_STORAGE_CONTRACT.getUint(keyHashEarningsPerCampaign);
		// Increase them by earnings added now and store
		PROXY_STORAGE_CONTRACT.setUint(keyHashEarningsPerCampaign, currentEarningsForThisCampaign.add(moderatorTokens));

		return moderatorTokens;
	}


	//    /**
	//     * @notice          Function to call setLiquidityParams on LiquidityConversionRates.sol
	//     *                  contract, it can be called only by TwoKeyAdmin.sol contract
	//     *
	//     * @param           liquidityConversionRatesContractAddress is the address of liquidity conversion rates contract
	//                        the right address depending on environment can be found in configurationFiles/kyberAddresses.json
	//                        It's named "pricing" in the json object
	//     */
	//	function setLiquidityParametersInKyber(
	//        address liquidityConversionRatesContractAddress,
	//        uint _rInFp,
	//        uint _pMinInFp,
	//        uint _numFpBits,
	//        uint _maxCapBuyInWei,
	//        uint _maxCapSellInWei,
	//        uint _feeInBps,
	//        uint _maxTokenToEthRateInPrecision,
	//        uint _minTokenToEthRateInPrecision
	//	)
	//	public
	//	onlyTwoKeyCongress
	//	{
	//        // Call on the contract set liquidity params
	//        IKyberReserveInterface(liquidityConversionRatesContractAddress).setLiquidityParams(
	//            _rInFp,
	//            _pMinInFp,
	//            _numFpBits,
	//            _maxCapBuyInWei,
	//            _maxCapSellInWei,
	//            _feeInBps,
	//            _maxTokenToEthRateInPrecision,
	//            _minTokenToEthRateInPrecision
	//        );
	//	}
	//
	//
	//	/**
	//	 * @notice			Contract to disable trade through Kyber
	//	 *
	//	 * @param			reserveContract is the address of reserve contract
	//	 */
	//	function disableTradeInKyber(
	//		address reserveContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		disableTradeInKyberInternal(reserveContract);
	//	}
	//
	//	function disableTradeInKyberInternal(
	//		address reserveContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(reserveContract).disableTrade();
	//	}
	//
	//
	//	/**
	//	 * @notice			Contract to enable trade through Kyber
	//	 *
	//	 * @param			reserveContract is the address of reserve contract
	//	 */
	//	function enableTradeInKyber(
	//		address reserveContract
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		enableTradeInKyberInternal(reserveContract);
	//	}
	//
	//	function enableTradeInKyberInternal(
	//		address reserveContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(reserveContract).enableTrade();
	//	}
	//
	//	function getKyberAvailableFeesOnReserve(
	//		address pricingContract
	//	)
	//	internal
	//	view
	//	returns (uint)
	//	{
	//		return IKyberReserveInterface(pricingContract).collectedFeesInTwei();
	//	}
	//
	//
	//	function resetFeesCounterOnKyberContract(
	//		address pricingContract
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(pricingContract).resetCollectedFees();
	//	}
	//
	//
	//    /**
	//     * @notice          Function to call withdraw on KyberReserve.sol contract
	//     *                  It can be only called by TwoKeyAdmin.sol contract
	//     *
	//     * @param           kyberReserveContractAddress is the address of kyber reserve contract
	//     *                  right address depending on environment can be found in configurationFiles/kyberAddresses.json
	//                        It's named "reserve" in the json object.
	//     */
	//    function withdrawTokensFromKyberReserve(
	//        address kyberReserveContractAddress,
	//        ERC20 tokenToWithdraw,
	//        uint amountToBeWithdrawn,
	//        address receiverAddress
	//    )
	//    external
	//    onlyTwoKeyCongress
	//    {
	//		withdrawTokensFromKyberReserveInternal(
	//			kyberReserveContractAddress,
	//			tokenToWithdraw,
	//			amountToBeWithdrawn,
	//			receiverAddress
	//		);
	//    }

	//	/**
	//	 * @notice			Function to set contracts on Kyber, mostly used to swap from their
	//	 *					staging and production environments
	//	 *
	//	 * @param			kyberReserveContractAddress is our reserve contract address
	//	 * @param			kyberNetworkAddress is the address of kyber network
	//	 * @param			conversionRatesContractAddress is the address of conversion rates contract
	//	 * @param			sanityRatesContractAddress is the address of sanity rates contract
	//	 */
	//	function setContractsKyber(
	//		address kyberReserveContractAddress,
	//		address kyberNetworkAddress,
	//		address conversionRatesContractAddress,
	//		address sanityRatesContractAddress
	//	)
	//	external
	//	onlyTwoKeyCongress
	//	{
	//		IKyberReserveInterface(kyberReserveContractAddress).setContracts(
	//			kyberNetworkAddress,
	//			conversionRatesContractAddress,
	//			sanityRatesContractAddress
	//		);
	//	}

	//
	//	function withdrawTokensFromKyberReserveInternal(
	//		address kyberReserveContractAddress,
	//		ERC20 tokenToWithdraw,
	//		uint amountToBeWithdrawn,
	//		address receiverAddress
	//	)
	//	internal
	//	{
	//		IKyberReserveInterface(kyberReserveContractAddress).withdrawToken(
	//			tokenToWithdraw,
	//			amountToBeWithdrawn,
	//			receiverAddress
	//		);
	//	}


	/**
	 * @notice 			Function to get uint from the storage
	 *
	 * @param 			key is the name of the key in the storages
	 */
	function getUint(
		string key
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(key));
	}


	/**
	 * @notice 			Setter for all integers we'd like to store
	 *
	 * @param 			key is the key (var name)
	 * @param 			value is the value of integer we'd like to store
	 */
	function setUint(
		string key,
		uint value
	)
	internal
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(key), value);
	}


	/**
	 * @notice 			Getter for moderator earnings per campaign
	 *
	 * @param 			_campaignAddress is the address of the campaign we're searching for moderator earnings
 	 */
	function getModeratorEarningsPerCampaign(
		address _campaignAddress
	)
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_moderatorEarningsPerCampaign, _campaignAddress));
	}


	/**
	 * @notice 			Function to return the release date when 2KEY token can be withdrawn from the
	 * 					network
	 */
	function getTwoKeyRewardsReleaseDate()
	external
	view
	returns(uint)
	{
		return getUint(_rewardReleaseAfter);
	}


	/**
	 * @notice			Getter for default moderator percent he takes
 	 */
	function getDefaultIntegratorFeePercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyIntegratorDefaultFeePercent);
	}



	/**
	 * @notice 			Getter for network tax percent which is taken from moderator
	 */
	function getDefaultNetworkTaxPercent()
	public
	view
	returns (uint)
	{
		return getUint(_twoKeyNetworkTaxPercent);
	}



	/**
	 * @notice			Setter in case TwoKeyCongress decides to change integrator fee percent
	 */
	function setDefaultIntegratorFeePercent(
		uint newFeePercent
	)
	external
	onlyTwoKeyCongress
	{
		PROXY_STORAGE_CONTRACT.setUint(keccak256(_twoKeyIntegratorDefaultFeePercent),newFeePercent);
	}


	/**
	 * @notice 			Getter to check how many total tokens TwoKeyAdmin received as a moderator from
	 *					various campaign contracts running on 2key.network
	 */
    function getAmountOfTokensReceivedAsModerator()
    public
    view
    returns (uint)
    {
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_rewardsReceivedAsModeratorTotal));
	}

	function getAmountOfTokensReceivedFromDistributionFees()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesCollectedFromDistributionRewards));
	}

	function getAmountOfTokensWithdrawnFromDistributionFees()
	public
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromCollectedDistributionRewards));
	}

	function getAmountCollectedFromFeeManagerInCurrency(
		string currency
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesFromFeeManagerCollectedInCurrency, currency));
	}

	function getAmountCollectedFromKyber()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_feesCollectedFromKyber));
	}


	function getAmountCollectedInDAIFromUpgradableExchange()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_daiCollectedFromUpgradableExchange));
	}


	function getAmountOfTokensWithdrawnFromModeratorEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromModeratorEarningsPool));
	}

	function getAmountWithdrawnFromFeeManagerEarningsInCurrency(
		string currency
	)
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromFeeManagerPoolInCurrency,currency));
	}

	function getAmountWithdrawnFromKyberEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromKyberFeesPool));
	}

	function getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings()
	internal
	view
	returns (uint)
	{
		return PROXY_STORAGE_CONTRACT.getUint(keccak256(_amountWithdrawnFromCollectedDaiFromUpgradableExchange));
	}

	function transferTokens(
		string token,
		address beneficiary,
		uint amount
	)
	internal
	{
		IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(token)).transfer(
			beneficiary,
			amount
		);
	}

	function getAccountingReport()
	public
	view
	returns (bytes)
	{
		return (
			abi.encodePacked(
				getAmountOfTokensReceivedAsModerator(),
				getAmountCollectedFromFeeManagerInCurrency("DAI"),
				getAmountCollectedFromFeeManagerInCurrency("ETH"),
				getAmountCollectedFromFeeManagerInCurrency("2KEY"),
				getAmountCollectedFromKyber(),
				getAmountCollectedInDAIFromUpgradableExchange(),
				getAmountOfTokensReceivedFromDistributionFees(),
				getAmountOfTokensWithdrawnFromModeratorEarnings(),
				getAmountWithdrawnFromKyberEarnings(),
				getAmountWithdrawnFromCollectedDAIUpgradableExchangeEarnings(),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("DAI"),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("ETH"),
				getAmountWithdrawnFromFeeManagerEarningsInCurrency("2KEY"),
				getAmountOfTokensWithdrawnFromDistributionFees()
			)
		);
	}


	/**
	 * @notice Free ether is always accepted :)
 	 */
	function()
	external
	payable
	{

	}

}