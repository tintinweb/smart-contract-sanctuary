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

contract ITwoKeyExchangeRateContract {
    function getBaseToTargetRate(string _currency) public view returns (uint);
    function getStableCoinTo2KEYQuota(address stableCoinAddress) public view returns (uint,uint);
    function getStableCoinToUSDQuota(address stableCoin) public view returns (uint);
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

contract ITwoKeyFeeManagerStorage is IStructuredStorage {

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

contract TwoKeyFeeManager is Upgradeable, ITwoKeySingletonUtils {
    /**
     * This contract will store the fees and users registration debts
     * Depending of user role, on some actions 2key.network will need to deduct
     * users contribution amount / earnings / proceeds, in order to cover transactions
     * paid by 2key.network for users registration
     */
    using SafeMath for *;

    bool initialized;
    ITwoKeyFeeManagerStorage PROXY_STORAGE_CONTRACT;

    //Debt will be stored in ETH
    string constant _userPlasmaToDebtInETH = "userPlasmaToDebtInETH";

    //This refferrs only to registration debt
    string constant _isDebtSubmitted = "isDebtSubmitted";
    string constant _totalDebtsInETH = "totalDebtsInETH";

    string constant _totalPaidInETH = "totalPaidInETH";
    string constant _totalPaidInDAI = "totalPaidInDAI";
    string constant _totalPaidIn2Key = "totalPaidIn2Key";

    string constant _totalWithdrawnInETH = "totalWithdrawnInETH";
    string constant _eth2KeyRateOnWhichDebtWasPaidPerCampaign = "eth2KeyRateOnWhichDebtWasPaidPerCampaign";

    /**
     * Modifier which will allow only completely verified and validated contracts to call some functions
     */
    modifier onlyAllowedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry("TwoKeyCampaignValidator");
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }

    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        require(msg.sender == twoKeyAdmin);
        _;
    }

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorage
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyFeeManagerStorage(_proxyStorage);

        initialized = true;
    }



    function setDebtInternal(
        address _plasmaAddress,
        uint _registrationFee
    )
    internal
    {
        // Generate the key for debt
        bytes32 keyHashForUserDebt = keccak256(_userPlasmaToDebtInETH, _plasmaAddress);

        // Get current debt
        uint currentDebt = PROXY_STORAGE_CONTRACT.getUint(keyHashForUserDebt);

        // Add on current debt new debt
        PROXY_STORAGE_CONTRACT.setUint(keyHashForUserDebt,currentDebt.add(_registrationFee));

        //Get the key for the total debts in eth
        bytes32 key = keccak256(_totalDebtsInETH);

        //Get the total debts from storage contract and increase by _registrationFee
        uint totalDebts = _registrationFee.add(PROXY_STORAGE_CONTRACT.getUint(key));

        //Set new value for totalDebts
        PROXY_STORAGE_CONTRACT.setUint(key, totalDebts);
    }

    /**
     * @notice          Function which will be used to add additional debts for user
     *                  such as re-registration, and probably more things in the future
     *
     * @param           _plasmaAddress is user plasma address
     * @param           _debtAmount is the amount of debt we're adding to current debt
     * @param           _debtType is selector which will restrict that same debt is submitted
     *                  multiple times
     */
    function addDebtForUser(
        address _plasmaAddress,
        uint _debtAmount,
        string _debtType
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));

        bytes32 keyHashForDebtType = keccak256(_plasmaAddress, _debtType);

        require(PROXY_STORAGE_CONTRACT.getBool(keyHashForDebtType) == false);

        PROXY_STORAGE_CONTRACT.setBool(keyHashForDebtType, true);

        setDebtInternal(_plasmaAddress, _debtAmount);
    }


    /**
     * @notice          Function which will submit registration fees
     *                  It can be called only once par _address
     * @param           _plasmaAddress is the address of the user
     * @param           _registrationFee is the amount paid for the registration
     */
    function setRegistrationFeeForUser(
        address _plasmaAddress,
        uint _registrationFee
    )
    public
    {
        //Check that this function can be called only by TwoKeyEventSource
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"));

        // Generate the key for the storage
        bytes32 keyHashIsDebtSubmitted = keccak256(_isDebtSubmitted, _plasmaAddress);

        //Check that for this user we have never submitted the debt in the past
        require(PROXY_STORAGE_CONTRACT.getBool(keyHashIsDebtSubmitted) == false);

        //Set that debt is submitted
        PROXY_STORAGE_CONTRACT.setBool(keyHashIsDebtSubmitted, true);

        setDebtInternal(_plasmaAddress, _registrationFee);
    }

    /**
     * @notice          Function to check for the user if registration debt is submitted
     * @param           _plasmaAddress is users plasma address
     */
    function isRegistrationDebtSubmittedForTheUser(
        address _plasmaAddress
    )
    public
    view
    returns (bool)
    {
        bytes32 keyHashIsDebtSubmitted = keccak256(_isDebtSubmitted, _plasmaAddress);
        return PROXY_STORAGE_CONTRACT.getBool(keyHashIsDebtSubmitted);
    }

    /**
     * @notice          Function where maintainer can set debts per user
     * @param           usersPlasmas is the array of user plasma addresses
     * @param           fees is the array containing fees which 2key paid for user
     * Only maintainer is eligible to call this function.
     */
    function setRegistrationFeesForUsers(
        address [] usersPlasmas,
        uint [] fees
    )
    public
    onlyMaintainer
    {
        uint i = 0;
        uint total = 0;
        // Iterate through all addresses and store the registration fees paid for them
        for(i = 0; i < usersPlasmas.length; i++) {
            // Generate the key for the storage
            bytes32 keyHashIsDebtSubmitted = keccak256(_isDebtSubmitted, usersPlasmas[i]);

            //Check that for this user we have never submitted the debt in the past
            require(PROXY_STORAGE_CONTRACT.getBool(keyHashIsDebtSubmitted) == false);

            //Set that debt is submitted
            PROXY_STORAGE_CONTRACT.setBool(keyHashIsDebtSubmitted, true);

            PROXY_STORAGE_CONTRACT.setUint(keccak256(_userPlasmaToDebtInETH, usersPlasmas[i]), fees[i]);

            total = total.add(fees[i]);
        }

        // Increase total debts
        bytes32 key = keccak256(_totalDebtsInETH);
        uint totalDebts = total.add(PROXY_STORAGE_CONTRACT.getUint(key));
        PROXY_STORAGE_CONTRACT.setUint(key, totalDebts);
    }



    /**
     * @notice          Getter where we can check how much ETH user owes to 2key.network for his registration
     * @param           _userPlasma is user plasma address
     */
    function getDebtForUser(
        address _userPlasma
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_userPlasmaToDebtInETH, _userPlasma));
    }


    /**
     * @notice          Function to check if user has some debts and if yes, take them from _amount
     * @param           _plasmaAddress is the plasma address of the user
     * @param           _debtPaying is the part or full debt user is paying
     */
    function payDebtWhenConvertingOrWithdrawingProceeds(
        address _plasmaAddress,
        uint _debtPaying
    )
    public
    payable
    onlyAllowedContracts
    {
        bytes32 keyHashForDebt = keccak256(_userPlasmaToDebtInETH, _plasmaAddress);
        uint totalDebtForUser = PROXY_STORAGE_CONTRACT.getUint(keyHashForDebt);

        PROXY_STORAGE_CONTRACT.setUint(keyHashForDebt, totalDebtForUser.sub(_debtPaying));

        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        ITwoKeyAdmin(twoKeyAdmin).addFeesCollectedInCurrency.value(msg.value)("ETH", msg.value);

        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDebtEvent(
            _plasmaAddress,
            _debtPaying,
            false,
            "ETH"
        );
    }

    function payDebtWithDAI(
        address _plasmaAddress,
        uint _totalDebtDAI,
        uint _debtAmountPaidDAI
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange"));

        bytes32 keyHashForDebt = keccak256(_userPlasmaToDebtInETH, _plasmaAddress);
        uint totalDebtForUser = PROXY_STORAGE_CONTRACT.getUint(keyHashForDebt);

        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        ITwoKeyAdmin(twoKeyAdmin).addFeesCollectedInCurrency("DAI", _debtAmountPaidDAI);

        totalDebtForUser = totalDebtForUser.sub(totalDebtForUser.mul(_debtAmountPaidDAI.mul(10**18).div(_totalDebtDAI)).div(10**18));
        PROXY_STORAGE_CONTRACT.setUint(keyHashForDebt, totalDebtForUser);


        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDebtEvent(
            _plasmaAddress,
            _debtAmountPaidDAI,
            false,
            "DAI"
        );

    }

    function payDebtWith2KeyV2(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy
    )
    public
    onlyAllowedContracts
    {
        address _twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");
        payDebtWith2KeyV2Internal(_beneficiaryPublic,_plasmaAddress,_amountOf2keyForRewards,_twoKeyEconomy,_twoKeyAdmin);
    }

    function payDebtWith2KeyV2(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy,
        address _twoKeyAdmin
    )
    public
    onlyAllowedContracts
    {
        payDebtWith2KeyV2Internal(_beneficiaryPublic,_plasmaAddress,_amountOf2keyForRewards,_twoKeyEconomy,_twoKeyAdmin);
    }

    function payDebtWith2KeyV2Internal(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards,
        address _twoKeyEconomy,
        address _twoKeyAdmin
    )
    internal
    {
        uint usersDebtInEth = getDebtForUser(_plasmaAddress);
        uint amountToPay = 0;

        if(usersDebtInEth > 0) {

            // Get Eth 2 2Key rate for this contract
            uint ethTo2key = getEth2KeyRateOnWhichDebtWasPaidForCampaign(msg.sender);

            // If Eth 2 2Key rate doesn't exist for this contract calculate it
            if(ethTo2key == 0) {
                ethTo2key = setEth2KeyRateOnWhichDebtGetsPaid(msg.sender);
            }

            // 2KEY / ETH
            uint debtIn2Key = (usersDebtInEth.mul(ethTo2key)).div(10**18); // ETH * (2KEY / ETH) = 2KEY

            // This is the initial amount he has to pay
            amountToPay = debtIn2Key;

            if (_amountOf2keyForRewards > debtIn2Key){
                if(_amountOf2keyForRewards < 3 * debtIn2Key) {
                    amountToPay = debtIn2Key / 2;
                }
            }
            else {
                amountToPay = _amountOf2keyForRewards / 4;
            }

            // Emit event that debt is paid it's inside this if because if there's no debt it will just continue and transfer all tokens to the influencer
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDebtEvent(
                _plasmaAddress,
                amountToPay,
                false,
                "2KEY"
            );


            // Update if there's any leftover with debt
            bytes32 keyHashForDebt = keccak256(_userPlasmaToDebtInETH, _plasmaAddress);
            usersDebtInEth = usersDebtInEth.sub(usersDebtInEth.mul(amountToPay.mul(10**18).div(debtIn2Key)).div(10**18));
            PROXY_STORAGE_CONTRACT.setUint(keyHashForDebt, usersDebtInEth);
        }

        ITwoKeyAdmin(_twoKeyAdmin).addFeesCollectedInCurrency("2KEY", amountToPay);
        // Take tokens from campaign contract
        IERC20(_twoKeyEconomy).transferFrom(msg.sender, _twoKeyAdmin, amountToPay);
        // Transfer tokens - debt to influencer
        IERC20(_twoKeyEconomy).transferFrom(msg.sender, _beneficiaryPublic, _amountOf2keyForRewards.sub(amountToPay));
    }



    function calculateEth2KeyRate()
    internal
    view
    returns (uint)
    {
        address upgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        uint contractID = IUpgradableExchange(upgradableExchange).getContractId(msg.sender);
        uint ethTo2key = IUpgradableExchange(upgradableExchange).getEth2KeyAverageRatePerContract(contractID);

        // If there's no existing rate at the moment, compute it
        if(ethTo2key == 0) {
            //This means that budget for this campaign was added directly as 2KEY
            /**
             1 eth = 200$
             1 2KEY = 0.06 $

             200 = 0.06 * x
             x = 200 / 0.06
             x = 3333,333333333
             1 eth = 3333,333333 2KEY
             */
            uint eth_usd = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract")).
            getBaseToTargetRate("USD");

            // get current 2key rate
            uint twoKey_usd = IUpgradableExchange(upgradableExchange).sellRate2key();

            // Compute rates at this particular moment
            ethTo2key = eth_usd.mul(10**18).div(twoKey_usd);
        }
        return ethTo2key;
    }



    function payDebtWith2Key(
        address _beneficiaryPublic,
        address _plasmaAddress,
        uint _amountOf2keyForRewards
    )
    public
    onlyAllowedContracts
    {
        uint usersDebtInEth = getDebtForUser(_plasmaAddress);
        uint amountToPay = 0;

        if(usersDebtInEth > 0) {

            // Get Eth 2 2Key rate for this contract
            uint ethTo2key = getEth2KeyRateOnWhichDebtWasPaidForCampaign(msg.sender);

            // If Eth 2 2Key rate doesn't exist for this contract calculate it
            if(ethTo2key == 0) {
                ethTo2key = setEth2KeyRateOnWhichDebtGetsPaid(msg.sender);
            }

            // 2KEY / ETH
            uint debtIn2Key = (usersDebtInEth.mul(ethTo2key)).div(10**18); // ETH * (2KEY / ETH) = 2KEY

            // This is the initial amount he has to pay
            amountToPay = debtIn2Key;

            if (_amountOf2keyForRewards > debtIn2Key){
                if(_amountOf2keyForRewards < 3 * debtIn2Key) {
                    amountToPay = debtIn2Key / 2;
                }
            }
            else {
                amountToPay = _amountOf2keyForRewards / 4;
            }

            // Emit event that debt is paid it's inside this if because if there's no debt it will just continue and transfer all tokens to the influencer
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDebtEvent(
                _plasmaAddress,
                amountToPay,
                false,
                "2KEY"
            );


            // Get keyhash for debt
            bytes32 keyHashForDebt = keccak256(_userPlasmaToDebtInETH, _plasmaAddress);

            bytes32 keyHashTotalPaidIn2Key = keccak256(_totalPaidIn2Key);

            // Set total paid in DAI
            PROXY_STORAGE_CONTRACT.setUint(keyHashTotalPaidIn2Key, amountToPay.add(PROXY_STORAGE_CONTRACT.getUint(keyHashTotalPaidIn2Key)));

            usersDebtInEth = usersDebtInEth - usersDebtInEth.mul(amountToPay.mul(10**18).div(debtIn2Key)).div(10**18);

            PROXY_STORAGE_CONTRACT.setUint(keyHashForDebt, usersDebtInEth);
        }

        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        // Take tokens from campaign contract
        IERC20(twoKeyEconomy).transferFrom(msg.sender, address(this), _amountOf2keyForRewards);
        // Transfer tokens - debt to influencer
        IERC20(twoKeyEconomy).transfer(_beneficiaryPublic, _amountOf2keyForRewards.sub(amountToPay));
    }


    function getEth2KeyRateOnWhichDebtWasPaidForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(keccak256(_eth2KeyRateOnWhichDebtWasPaidPerCampaign,campaignAddress));
    }

    function setEth2KeyRateOnWhichDebtGetsPaid(
        address campaignAddress
    )
    internal
    returns (uint)
    {
        uint rate = calculateEth2KeyRate();
        PROXY_STORAGE_CONTRACT.setUint(keccak256(_eth2KeyRateOnWhichDebtWasPaidPerCampaign,campaignAddress), rate);
        return rate;
    }

    /**
     * @notice          Function to get status of the debts
     */
    function getDebtsSummary()
    public
    view
    returns (uint,uint,uint,uint)
    {
        uint totalDebtsInEth = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalDebtsInETH));
        uint totalPaidInEth = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidInETH));
        uint totalPaidInDAI = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidInDAI));
        uint totalPaidIn2Key = PROXY_STORAGE_CONTRACT.getUint(keccak256(_totalPaidIn2Key));

        return (
            totalDebtsInEth,
            totalPaidInEth,
            totalPaidInDAI,
            totalPaidIn2Key
        );
    }


    function withdrawEtherCollected()
    public
    onlyTwoKeyAdmin
    returns (uint)
    {
        uint balance = address(this).balance;

        bytes32 keyHash = keccak256(_totalWithdrawnInETH);
        PROXY_STORAGE_CONTRACT.setUint(keyHash, balance.add(PROXY_STORAGE_CONTRACT.getUint(keyHash)));

        (msg.sender).transfer(balance);

        return balance;
    }

    function withdraw2KEYCollected()
    public
    onlyTwoKeyAdmin
    returns (uint)
    {
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        uint balance = IERC20(twoKeyEconomy).balanceOf(address(this));

        IERC20(twoKeyEconomy).transfer(msg.sender, balance);
        return balance;
    }

    function withdrawDAICollected(
        address _dai
    )
    public
    onlyTwoKeyAdmin
    returns (uint)
    {
        uint balance = IERC20(_dai).balanceOf(address(this));

        IERC20(_dai).transfer(msg.sender, balance);
        return balance;
    }

}