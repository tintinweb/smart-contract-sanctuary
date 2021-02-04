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

contract ITether {
    function transferFrom(address _from, address _to, uint256 _value) external;

    function transfer(address _to, uint256 _value) external;
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

contract ITwoKeyBudgetCampaignsPaymentsHandlerStorage is IStructuredStorage{

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

contract TwoKeyBudgetCampaignsPaymentsHandler is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for *;

    /**
     * State variables
     * TO BE EXPANDED
     */

    string constant _campaignPlasma2initialBudget2Key = "campaignPlasma2initialBudget2Key";
    string constant _campaignPlasma2isCampaignEnded = "campaignPlasma2isCampaignEnded";
    string constant _campaignPlasma2contractor = "campaignPlasma2contractor";

    string constant _campaignPlasma2isBudgetedWith2KeyDirectly = "campaignPlasma2isBudgetedWith2KeyDirectly";
    string constant _campaignPlasma2StableCoinAddress = "campaignPlasma2StableCoinAddress";
    string constant _campaignPlasma2rebalancingRatio = "campaignPlasma2rebalancingRatio";
    string constant _campaignPlasma2initialRate = "campaignPlasma2initalRate";
    string constant _campaignPlasma2bountyPerConversion2KEY = "campaignPlasma2bountyPerConversion2KEY";
    string constant _campaignPlasma2amountOfStableCoins = "campaignPlasma2amountOfStableCoins";
    string constant _numberOfDistributionCycles = "numberOfDistributionCycles";
    string constant _distributionCycleToTotalDistributed = "_distributionCycleToTotalDistributed";
    string constant _campaignPlasma2ReferrerRewardsTotal = "campaignPlasma2ReferrerRewardsTotal";
    string constant _campaignPlasmaToModeratorEarnings = "campaignPlasmaToModeratorEarnings";
    string constant _campaignPlasmaToLeftOverForContractor = "campaignPlasmaToLeftOverForContractor";
    string constant _campaignPlasmaToLeftoverWithdrawnByContractor = "campaignPlasmaToLeftoverWithdrawnByContractor";
    string constant _feePerCycleIdPerReferrer = "feePerCycleIdPerReferrer";

    ITwoKeyBudgetCampaignsPaymentsHandlerStorage public PROXY_STORAGE_CONTRACT;

    bool initialized;

    function setInitialParams(
        address _twoKeySingletonRegistry,
        address _proxyStorageContract
    )
    public
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyBudgetCampaignsPaymentsHandlerStorage(_proxyStorageContract);

        initialized = true;
    }

    /**
     * ------------------------------------
     *          Contractor actions
     * ------------------------------------
     */

    /**
     * @notice          Function which will be used in order to add inventory for campaign
     *                  directly with 2KEY tokens. In order to make this
     *                  transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOf2KEYTokens is the amount of 2KEY tokens user adds to budget
     */
    function addInventory2KEY(
        address campaignPlasma,
        uint amountOf2KEYTokens,
        uint bountyPerConversionFiat
    )
    public
    {
        // Require that budget is not previously set and assign amount of 2KEY tokens
        requireBudgetNotSetAndSetBudget(campaignPlasma, amountOf2KEYTokens);
        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        // Get 2KEY sell rate at the moment
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // calculate bounty per conversion 2KEY
        uint bountyPerConversion2KEY = bountyPerConversionFiat.mul(10**18).div(rate);

        // Calculate and set bounty per conversion in 2KEY units
        setUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma),
            bountyPerConversion2KEY
        );

        // Set rate at which 2KEY is put to campaign
        setUint(
            keccak256(_campaignPlasma2initialRate, campaignPlasma),
            rate
        );

        // Set that campaign is budgeted directly with 2KEY tokens
        setBool(
            keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma),
            true
        );

        // Take 2KEY tokens from the contractor
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transferFrom(
            msg.sender,
            address(this),
            amountOf2KEYTokens
        );
    }

    /**
     * @notice          Function which will be used in order to add inventory for campaign
     *                  directly with stable coin tokens. In order to make this
     *                  transfer secure,
     *                  user will firstly have to approve this contract to take from him
     *                  amount of tokens and then call contract function which will execute
     *                  transferFrom action. This function can be called only once.
     *
     * @param           campaignPlasma is the plasma campaign address which is user adding inventory for.
     * @param           amountOfStableCoins is the amount of stable coins user adds to budget
     * @param           tokenAddress is stableCoinAddress
     */
    function addInventory(
        address campaignPlasma,
        uint amountOfStableCoins,
        uint bountyPerConversionFiat,
        address tokenAddress
    )
    public
    {
        // Set that contractor is the msg.sender of this method for the campaign passed
        setAddress(keccak256(_campaignPlasma2contractor, campaignPlasma), msg.sender);

        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");

        // Handle case for Tether due to different ERC20 interface it has
        if (tokenAddress == getNonUpgradableContractAddressFromTwoKeySingletonRegistry("USDT")) {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            ITether(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfStableCoins
            );
        } else {
            // Take stable coins from the contractor and directly transfer them to upgradable exchange
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                twoKeyUpgradableExchange,
                amountOfStableCoins
            );
        }


        uint totalTokensBought;
        uint tokenPrice;

        // Buy tokens
        (totalTokensBought, tokenPrice) = IUpgradableExchange(twoKeyUpgradableExchange).buyTokensWithERC20(amountOfStableCoins, tokenAddress);

        // Calculate and set bounty per conversion in 2KEY units
        uint bountyPerConversion2KEY = bountyPerConversionFiat.mul(10 ** 18).div(tokenPrice);

        // Require that budget is not previously set and set initial budget to amount of 2KEY tokens
        requireBudgetNotSetAndSetBudget(campaignPlasma, totalTokensBought);

        // SSTORE 20k gas * 3 = 60k 3x uint ==> 256 bytes * 3 * 8 =  6144 gas
        // 375 gas + 5 gas for each byte
        // 10%   60000 - 6144 = 53856 saving

        setUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma),
            bountyPerConversion2KEY
        );

        setUint(
            keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma),
            amountOfStableCoins
        );

        // Set stable coin which is used to budget campaign
        setAddress(
            keccak256(_campaignPlasma2StableCoinAddress, campaignPlasma),
            tokenAddress
        );

        // Set the rate at which we have bought 2KEY tokens
        setUint(
            keccak256(_campaignPlasma2initialRate, campaignPlasma),
            tokenPrice
        );
    }


    /**
     * @notice          Function where contractor can withdraw if there's any leftover on his campaign
     * @param           campaignPlasmaAddress is plasma address of campaign
     */
    function withdrawLeftoverForContractor(
        address campaignPlasmaAddress
    )
    public
    {
        // Require that this function is possible to call only by contractor
        require(
            getAddress(keccak256(_campaignPlasma2contractor,campaignPlasmaAddress)) == msg.sender
        );

        // Get the leftover for contractor
        uint leftoverForContractor = getUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasmaAddress)
        );

        // Check that he has some leftover which can be zero in case that campaign is not ended yet
        require(leftoverForContractor > 0);

        // Generate key if contractor have withdrawn his leftover for specific campaign
        bytes32 key = keccak256(_campaignPlasmaToLeftoverWithdrawnByContractor, campaignPlasmaAddress);

        // Require that he didn't withdraw it
        require(getBool(key) == false);

        // State that now he has withdrawn the tokens.
        setBool(key, true);

        transfer2KEY(
            msg.sender,
            leftoverForContractor
        );
    }


    /**
     * ------------------------------------
     *          Maintainer actions
     * ------------------------------------
     */

    /**
     * @notice          Function to end selected budget campaign by maintainer, and perform
     *                  actions regarding rebalancing, reserving tokens, and distributing
     *                  moderator earnings, as well as calculating leftover for contractor
     *
     * @param           campaignPlasma is the plasma address of the campaign
     * @param           totalAmountForReferrerRewards is the total amount before rebalancing referrers earned
     * @param           totalAmountForModeratorRewards is the total amount moderator earned before rebalancing
     */
    function endCampaignReserveTokensAndRebalanceRates(
        address campaignPlasma,
        uint totalAmountForReferrerRewards,
        uint totalAmountForModeratorRewards
    )
    public
    onlyMaintainer
    {
        // Generate key for storage variable isCampaignEnded
        bytes32 keyIsCampaignEnded = keccak256(_campaignPlasma2isCampaignEnded, campaignPlasma);

        // Require that campaign is not ended yet
        require(getBool(keyIsCampaignEnded) == false);

        // End campaign
        setBool(keyIsCampaignEnded, true);

        // Get how many tokens were inserted at the beginning
        uint initialBountyForCampaign = getInitialBountyForCampaign(campaignPlasma);

        // Rebalancing everything except referrer rewards
        uint amountToRebalance = initialBountyForCampaign.sub(totalAmountForReferrerRewards);

        // Amount after rebalancing is initially amount to rebalance
        uint amountAfterRebalancing = amountToRebalance;

        // Initially rebalanced moderator rewards are total moderator rewards
        uint rebalancedModeratorRewards = totalAmountForModeratorRewards;

        // Initial ratio is 1
        uint rebalancingRatio = 10**18;

        if(getIsCampaignBudgetedDirectlyWith2KEY(campaignPlasma) == false) {
            // If budget added as stable coin we do rebalancing
            (amountAfterRebalancing, rebalancingRatio)
                = rebalanceRates(
                    getInitial2KEYRateForCampaign(campaignPlasma),
                    amountToRebalance
            );

            rebalancedModeratorRewards = totalAmountForModeratorRewards.mul(rebalancingRatio).div(10**18);
        }

        uint leftoverForContractor = amountAfterRebalancing.sub(rebalancedModeratorRewards);

        // Set moderator earnings for this campaign and immediately distribute them
        setAndDistributeModeratorEarnings(campaignPlasma, rebalancedModeratorRewards);

        // Set total amount to use for referrers
        setUint(
            keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma),
            totalAmountForReferrerRewards
        );

        // Leftover for contractor
        setUint(
            keccak256(_campaignPlasmaToLeftOverForContractor, campaignPlasma),
            leftoverForContractor
        );

        // Set rebalancing ratio for campaign
        setRebalancingRatioForCampaign(campaignPlasma, rebalancingRatio);

        // Emit an event to checksum all the balances per campaign
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource"))
            .emitEndedBudgetCampaign(
                campaignPlasma,
                leftoverForContractor,
                rebalancedModeratorRewards
            );
    }


    /**
     * @notice          Function to distribute rewards between influencers, increment global cycle id,
     *                  and update how much rewards are ever being distributed from this contract
     *
     * @param           influencers is the array of influencers
     * @param           balances is the array of corresponding balances for the influencers above
     *
     */
    function pushAndDistributeRewardsBetweenInfluencers(
        address [] influencers,
        uint [] balances,
        uint nonRebalancedTotalPayout,
        uint rebalancedTotalPayout,
        uint cycleId,
        uint feePerReferrerIn2KEY
    )
    public
    onlyMaintainer
    {
        // Get the address of 2KEY token
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        // Get the address of twoKeyUpgradableExchange contract
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Total distributed in cycle
        uint totalDistributed;
        // Iterator
        uint i;

        uint difference;
        // Leads to we need to return some tokens back to Upgradable Exchange
        if(nonRebalancedTotalPayout > rebalancedTotalPayout) {
            difference = nonRebalancedTotalPayout.sub(rebalancedTotalPayout);
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, difference);
            IUpgradableExchange(twoKeyUpgradableExchange).returnTokensBackToExchangeV1(difference);
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitRebalancedRewards(
                cycleId,
                difference,
                "RETURN_TOKENS_TO_EXCHANGE"
            );
        } else if (nonRebalancedTotalPayout < rebalancedTotalPayout) {
            // Leads to we need to get more tokens from Upgradable Exchange
            difference = rebalancedTotalPayout.sub(nonRebalancedTotalPayout);
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancingV1(difference);
            ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitRebalancedRewards(
                cycleId,
                difference,
                "GET_TOKENS_FROM_EXCHANGE"
            );
        }

        uint numberOfReferrers = influencers.length;

        // Iterate through all influencers, distribute them rewards, and account amount received per cycle id
        for (i = 0; i < numberOfReferrers; i++) {
            // Require that referrer earned more than fees
            require(balances[i] > feePerReferrerIn2KEY);
            // Sub fee per referrer from balance to pay
            uint balance = balances[i].sub(feePerReferrerIn2KEY);
            // Transfer required tokens to influencer
            IERC20(twoKeyEconomy).transfer(influencers[i], balance);
            // Sum up to totalDistributed to referrers
            totalDistributed = totalDistributed.add(balance);
        }


        transferFeesToAdmin(feePerReferrerIn2KEY, numberOfReferrers, twoKeyEconomy);


        // Set how much is total distributed per distribution cycle
        setUint(
            keccak256(_distributionCycleToTotalDistributed, cycleId),
            totalDistributed
        );
    }


    /**
     * ------------------------------------------------
     *        Internal functions performing logic operations
     * ------------------------------------------------
     */

    /**
     * @notice          Function to transfer fees taken from referrer rewards to admin contract
     * @param           feePerReferrer is fee taken per referrer equaling 0.5$ in 2KEY at the moment
     * @param           numberOfReferrers is number of referrers being rewarded in this cycle
     * @param           twoKeyEconomy is 2KEY token contract
     */
    function transferFeesToAdmin(
        uint feePerReferrer,
        uint numberOfReferrers,
        address twoKeyEconomy
    )
    internal
    {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        IERC20(twoKeyEconomy).transfer(
            twoKeyAdmin,
            feePerReferrer.mul(numberOfReferrers)
        );

        // Update in admin tokens receiving from fees
        ITwoKeyAdmin(twoKeyAdmin).updateTokensReceivedFromDistributionFees(feePerReferrer.mul(numberOfReferrers));
    }


    /**
     * @notice          Function to set how many tokens are being distributed to moderator
     *                  as well as distribute them.
     * @param           campaignPlasma is the plasma address of selected campaign
     * @param           rebalancedModeratorRewards is the amount for moderator after rebalancing
     */
    function setAndDistributeModeratorEarnings(
        address campaignPlasma,
        uint rebalancedModeratorRewards
    )
    internal
    {
        // Account amount moderator earned on this campaign
        setUint(
            keccak256(_campaignPlasmaToModeratorEarnings, campaignPlasma),
            rebalancedModeratorRewards
        );

        // Get twoKeyAdmin address
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin");

        // Transfer 2KEY tokens to moderator
        transfer2KEY(
            twoKeyAdmin,
            rebalancedModeratorRewards
        );

        // Update moderator on received tokens so it can proceed distribution to TwoKeyDeepFreezeTokenPool
        ITwoKeyAdmin(twoKeyAdmin).updateReceivedTokensAsModeratorPPC(rebalancedModeratorRewards, campaignPlasma);
    }

    /**
     * @notice          Function to require that initial budget is not set, which
     *                  will prevent any way of adding inventory to specific campaigns
     *                  after it's first time added
     * @param           campaignPlasma is campaign plasma address
     */
    function requireBudgetNotSetAndSetBudget(
        address campaignPlasma,
        uint amount2KEYTokens
    )
    internal
    {

        bytes32 keyHashForInitialBudget = keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma);
        // Require that initial budget is not being added, since it can be done only once.
        require(getUint(keyHashForInitialBudget) == 0);
        // Set initial budget added
        setUint(keyHashForInitialBudget, amount2KEYTokens);
    }

    function rebalanceRates(
        uint initial2KEYRate,
        uint amountOfTokensToRebalance
    )
    internal
    returns (uint,uint)
    {

        // Load twoKeyEconomy address
        address twoKeyEconomy = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        // Load twoKeyUpgradableExchange address
        address twoKeyUpgradableExchange = getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange");
        // Take the current usd to 2KEY rate against we're rebalancing contractor leftover and moderator rewards
        uint usd2KEYRateWeiNow = IUpgradableExchange(twoKeyUpgradableExchange).sellRate2key();

        // Ratio is initial rate divided by new rate, so if rate went up, this will be less than 1
        uint rebalancingRatio = initial2KEYRate.mul(10**18).div(usd2KEYRateWeiNow);

        // Calculate new rebalanced amount of tokens
        uint rebalancedAmount = amountOfTokensToRebalance.mul(rebalancingRatio).div(10**18);

        // If price went up, leads to ratio is going to be less than 10**18
        if(rebalancingRatio < 10**18) {
            // Calculate how much tokens should be given back to exchange
            uint tokensToGiveBackToExchange = amountOfTokensToRebalance.sub(rebalancedAmount);
            // Approve upgradable exchange to take leftover back
            IERC20(twoKeyEconomy).approve(twoKeyUpgradableExchange, tokensToGiveBackToExchange);
            // Call the function to release all DAI for this contract to reserve and to take approved amount of 2key back to liquidity pool
            IUpgradableExchange(twoKeyUpgradableExchange).returnTokensBackToExchangeV1(tokensToGiveBackToExchange);
        }
        // Otherwise we assume that price went down, which leads that ratio will be greater than 10**18
        else  {
            uint tokensToTakeFromExchange = rebalancedAmount.sub(amountOfTokensToRebalance);
            // Get more tokens we need
            IUpgradableExchange(twoKeyUpgradableExchange).getMore2KeyTokensForRebalancingV1(tokensToTakeFromExchange);
        }
        // Return new rebalanced amount as well as ratio against which rebalancing was done.
        return (rebalancedAmount, rebalancingRatio);
    }


    /**
     * ------------------------------------------------
     *        Internal getters and setters
     * ------------------------------------------------
     */

    function getUint(
        bytes32 key
    )
    internal
    view
    returns (uint)
    {
        return PROXY_STORAGE_CONTRACT.getUint(key);
    }

    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key,value);
    }

    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }

    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }

    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }

    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key,value);
    }

    function equals(
        string a,
        string b
    )
    internal
    pure
    returns (bool) {
        return keccak256(a) == keccak256(b) ? true : false;
    }


    /**
     * @notice          Function whenever called, will increment number of distribution cycles
     */
    function incrementNumberOfDistributionCycles()
    internal
    {
        bytes32 key = keccak256(_numberOfDistributionCycles);
        setUint(key,getUint(key) + 1);
    }


    /**
     * @notice 			Function to transfer 2KEY tokens
     *
     * @param			receiver is the address of tokens receiver
     * @param			amount is the amount of tokens to be transfered
     */
    function transfer2KEY(
        address receiver,
        uint amount
    )
    internal
    {
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy")).transfer(
            receiver,
            amount
        );
    }

    /**
     * @notice          Internal setter function to store how much stable coins were
     *                  added to fund this campaign
     * @param           campaignPlasma is plasma campaign address
     * @param           amountOfStableCoins is the amount used for campaign funding
     */
    function setAmountOfStableCoinsUsedToFundCampaign(
        address campaignPlasma,
        uint amountOfStableCoins
    )
    internal
    {
        setUint(
            keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma),
            amountOfStableCoins
        );
    }

    function setRebalancingRatioForCampaign(
        address campaignPlasma,
        uint rebalancingRatio
    )
    internal
    {
        setUint(
            keccak256(_campaignPlasma2rebalancingRatio, campaignPlasma),
            rebalancingRatio
        );
    }


    /**
     * ------------------------------------------------
     *              Public getters
     * ------------------------------------------------
     */

    /**
     * @notice          Function to return rebalancing ratio for specific campaign,
     *                  in case campaign was funded with 2KEY will return 1 ETH as neutral
     * @param           campaignPlasma is plasma campaign address
     */
    function getRebalancingRatioForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        uint ratio = getUint(keccak256(_campaignPlasma2rebalancingRatio, campaignPlasma));
        return  ratio != 0 ? ratio : 10**18;
    }

    /**
     * @notice          Function to get number of distribution cycles ever
     */
    function getNumberOfCycles()
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_numberOfDistributionCycles));
    }


    /**
     * @notice          Function to get how much was initial bounty for selected camapaign in 2KEY tokens
     *
     * @param           campaignPlasma is the plasma address of the campaign
     */
    function getInitialBountyForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2initialBudget2Key, campaignPlasma));
    }


    /**
     * @notice          Function to retrieve the initial rate at which 2KEY tokens were bought if
     *                  were bought at all. Otherwise it returns 0.
     * @param           campaignPlasma is plasma address of the campaign
     */
    function getInitial2KEYRateForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2initialRate, campaignPlasma));
    }


    /**
     * @notice          Function to get how much is distributed in cycle
     * @param           cycleId is the ID of that cycle
     */
    function getTotalDistributedInCycle(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_distributionCycleToTotalDistributed, cycleId));
    }


    /**
     * @notice          Function to get moderator rebalanced earnings for this campaign
     * @param           campaignAddress is plasma campaign address
     */
    function getModeratorEarningsRebalancedForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint)
    {
        return (
            getUint(keccak256(_campaignPlasmaToModeratorEarnings, campaignAddress)) //moderator earnings)
        );
    }


    /**
     * @notice          Function to get contractor rebalanced leftover for campaign
     * @param           campaignAddress is plasma campaign address
     */
    function getContractorRebalancedLeftoverForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint)
    {
        return (
            getUint(keccak256(_campaignPlasmaToLeftOverForContractor, campaignAddress)) // contractor leftover
        );
    }


    /**
     * @notice          Function to get moderator earnings and contractor leftover after we rebalanced campaign
     * @param           campaignAddress is the address of campaign
     */
    function getModeratorEarningsAndContractorLeftoverRebalancedForCampaign(
        address campaignAddress
    )
    public
    view
    returns (uint,uint)
    {
        return (
            getModeratorEarningsRebalancedForCampaign(campaignAddress),
            getContractorRebalancedLeftoverForCampaign(campaignAddress)
        );
    }

    function getIfLeftoverForCampaignIsWithdrawn(
        address campaignPlasma
    )
    public
    view
    returns (bool)
    {
        bool isWithdrawn = getBool(keccak256(_campaignPlasmaToLeftoverWithdrawnByContractor, campaignPlasma));
        return isWithdrawn;
    }

    function getNonRebalancedReferrerRewards(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2ReferrerRewardsTotal, campaignPlasma));
    }

    /**
     * @notice          Function to get balance of stable coins on this contract
     * @param           stableCoinsAddresses is the array of stable coins addresses we want to fetch
     *                  balances for
     */
    function getBalanceOfStableCoinsOnContract(
        address [] stableCoinsAddresses
    )
    public
    view
    returns (uint[])
    {
        uint len = stableCoinsAddresses.length;
        uint [] memory balances = new uint[](len);
        uint i;
        for(i = 0; i < len; i++) {
            balances[i] = IERC20(stableCoinsAddresses[i]).balanceOf(address(this));
        }
        return balances;
    }


    /**
     * @notice          Function to check amount of stable coins used to func ppc campaign
     * @param           campaignPlasma is campaign plasma address
     */
    function getAmountOfStableCoinsUsedToFundCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_campaignPlasma2amountOfStableCoins, campaignPlasma));
    }

    /**
     * @notice          Function to return bounty per conversion in 2KEY tokens
     * @param           campaignPlasma is plasma campaign of address requested
     */
    function getBountyPerConversion2KEY(
        address campaignPlasma
    )
    public
    view
    returns (uint)
    {
        return getUint(
            keccak256(_campaignPlasma2bountyPerConversion2KEY, campaignPlasma)
        );
    }

    /**
     * @notice          Function to check if campaign is budgeted directly with 2KEY
     */
    function getIsCampaignBudgetedDirectlyWith2KEY(
        address campaignPlasma
    )
    public
    view
    returns (bool)
    {
        return getBool(keccak256(_campaignPlasma2isBudgetedWith2KeyDirectly, campaignPlasma));
    }

    function getStableCoinAddressUsedToFundCampaign(
        address campaignPlasma
    )
    public
    view
    returns (address)
    {
        return getAddress(keccak256(_campaignPlasma2StableCoinAddress, campaignPlasma));
    }

    /**
     * @notice          Function to return summary related to specific campaign
     * @param           campaignPlasma is plasma campaign of address
     */
    function getCampaignSummary(
        address campaignPlasma
    )
    public
    view
    returns (bytes)
    {
        return (
            abi.encodePacked(
                getInitialBountyForCampaign(campaignPlasma),
                getBountyPerConversion2KEY(campaignPlasma),
                getAmountOfStableCoinsUsedToFundCampaign(campaignPlasma),
                getInitial2KEYRateForCampaign(campaignPlasma),
                getContractorRebalancedLeftoverForCampaign(campaignPlasma),
                getModeratorEarningsRebalancedForCampaign(campaignPlasma),
                getRebalancingRatioForCampaign(campaignPlasma),
                getNonRebalancedReferrerRewards(campaignPlasma),
                getIfLeftoverForCampaignIsWithdrawn(campaignPlasma)
        )
        );
    }

    /**
     * @notice          Function to fetch inital params computed while adding inventory
     * @param           campaignPlasma is the plasma address of the campaign being requested
     */
    function getInitialParamsForCampaign(
        address campaignPlasma
    )
    public
    view
    returns (uint,uint,uint,bool,address)
    {
        return (
            getInitialBountyForCampaign(campaignPlasma), // initial bounty for campaign
            getBountyPerConversion2KEY(campaignPlasma), // bounty per conversion in 2KEY tokens
            getInitial2KEYRateForCampaign(campaignPlasma), // rate at the moment of inventory adding
            getIsCampaignBudgetedDirectlyWith2KEY(campaignPlasma), // Get if campaign is funded directly with 2KEY
            getCampaignContractor(campaignPlasma) // get contractor of campaign
        );
    }

    function getCampaignContractor(
        address campaignAddress
    )
    public
    view
    returns (address)
    {
        return getAddress(keccak256(_campaignPlasma2contractor, campaignAddress));
    }

    /**
     *
     */
    function getRequiredBudget2KEY(
        string fiatCurrency,
        uint fiatBudgetAmount
    )
    public
    view
    returns (uint)
    {
        // GET 2KEY - USD rate
        uint rate = IUpgradableExchange(getAddressFromTwoKeySingletonRegistry("TwoKeyUpgradableExchange")).sellRate2key();

        // For now ignore fiat currency assuming it's USD always
        return fiatBudgetAmount.mul(10 ** 18).div(rate);
    }

    function getFeePerCycleIdPerReferrer(
        uint cycleId
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256(_feePerCycleIdPerReferrer, cycleId));
    }

}