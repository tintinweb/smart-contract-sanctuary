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

contract IKyberNetworkProxy {
    function swapEtherToToken(
        ERC20 token,
        uint minConversionRate
    )
    public
    payable
    returns(uint);

    function swapTokenToToken(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        uint minConversionRate
    )
    public
    returns (uint);

    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
    public
    view
    returns (uint expectedRate, uint slippageRate);
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

contract ITwoKeyFactory {
    function addressToCampaignType(address _key) public view returns (string);
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

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] path) external view returns (uint[] memory amounts);
}

contract IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] path,
        address to,
        uint deadline
    ) external;
}

contract ITwoKeyUpgradableExchangeStorage is IStructuredStorage{

}

library GetCode {
    function at(address _addr) internal view returns (bytes o_code) {
        assembly {
        // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
            o_code := mload(0x40)
        // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
            mstore(o_code, size)
        // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}

library PriceDiscovery {


    using SafeMath for uint;



    /**
     * @notice          Function to calculate token price based on amount of tokens in the pool
     *                  currently and initial worth of pool in USD
     *
     * @param           poolInitialAmountInUSD (wei) is the amount how much all tokens in pool should be worth
     * @param           amountOfTokensLeftInPool (wei) is the amount of tokens left in the pool after somebody
     *                  bought them
     * @return          new token price in USD  -> in wei units
     */
    function recalculatePrice(
        uint poolInitialAmountInUSD,
        uint amountOfTokensLeftInPool
    )
    public
    pure
    returns (uint)
    {
        return (poolInitialAmountInUSD.mul(10**18)).div(amountOfTokensLeftInPool);

    }


    /**
     * @notice          Function to calculate how many iterations to recompute price we need
     *
     * @param           amountOfUSDSpendingForBuyingTokens is the dollar amount user is spending
     *                  to buy the tokens
     * @param           tokenPriceBeforeBuying is the price of the token when user expressed
     *                  a will to buy the tokens
     * @param           totalAmountOfTokensInThePool is the amount of the tokens that are currently present in the pool
     *
     * @dev             All input values are in WEI units
     *
     * @return          tuple containing number of iterations and how many dollars will be spent per iteration
     */
    function calculateNumberOfIterationsNecessary(
        uint amountOfUSDSpendingForBuyingTokens,
        uint tokenPriceBeforeBuying,
        uint totalAmountOfTokensInThePool
    )
    public
    pure
    returns (uint, uint)
    {
        uint ONE_WEI = 10**18;
        uint HUNDRED_WEI = 100*(10**18);

        uint numberOfIterations = 1;

        if(amountOfUSDSpendingForBuyingTokens > HUNDRED_WEI) {
            uint amountOfTokensToBeBought;
            uint percentageOfThePoolWei;

            /**
             Function to calculate how many tokens will be bought and how much percentage is that
             out of the current pool supply
             */
            (amountOfTokensToBeBought, percentageOfThePoolWei) = calculatePercentageOfThePoolWei(
                amountOfUSDSpendingForBuyingTokens,
                tokenPriceBeforeBuying,
                totalAmountOfTokensInThePool
            );


            if(percentageOfThePoolWei < ONE_WEI) {
                // Case less than 1%
                numberOfIterations = 5;

            } else if(percentageOfThePoolWei < ONE_WEI.mul(10)) {
                // Case between 1% and 10%
                numberOfIterations = 10;
            } else if(percentageOfThePoolWei < ONE_WEI.mul(30)) {
                // Case between 10% and 30%
                numberOfIterations = 30;
            } else {
                // Cases where 30% or above
                numberOfIterations = 100;
            }
        }

        return (numberOfIterations, amountOfUSDSpendingForBuyingTokens.div(numberOfIterations));
    }


    /**
     * @notice          Function to calculate how many tokens would be bought in case the token price
     *                  is static, and how many in percentage is that out of the pool amount
     *
     * @param           usdAmountSpendingToBuyTokens is the amount of dollars user is spending for
     *                  buying tokens
     * @param           tokenPriceBeforeBuying is the price of the token at the moment of
     *                  purchase initialization
     * @param           totalAmountOfTokensInThePool is the total amount of the tokens in the pool at
     *                  the moment
     *
     * @dev             All input values are in WEI units
     */
    function calculatePercentageOfThePoolWei(
        uint usdAmountSpendingToBuyTokens,
        uint tokenPriceBeforeBuying,
        uint totalAmountOfTokensInThePool
    )
    public
    pure
    returns (uint,uint)
    {
        uint HUNDRED_WEI = 100*(10**18);

        // Amount of tokens that user would receive in case he bought for the whole money at initial price
        uint amountOfTokensToBeBought = usdAmountSpendingToBuyTokens.mul(10**18).div(tokenPriceBeforeBuying);
        // Percentage of the current amount in the pool in tokens user is buying
        uint percentageOfThePoolWei = amountOfTokensToBeBought.mul(HUNDRED_WEI).div(totalAmountOfTokensInThePool);

        return (amountOfTokensToBeBought, percentageOfThePoolWei);
    }


    /**
     * @notice          Function to calculate total tokens user will get and what will be the new
     *                  price after his purchase of tokens is done
     *
     * @param           amountOfUSDSpendingForBuyingTokens is the dollar amount user is spending
     * @param           tokenPriceBeforeBuying is the price of the token before purchase
     * @param           totalAmountOfTokensInThePool is the total amount of the tokens in the pool atm
     * @param           poolInitialWorthUSD is how much all 2KEY tokens in the pool should be worth together
     *
     * @dev             All input values are in WEI units
     */
    function calculateTotalTokensUserIsGetting(
        uint amountOfUSDSpendingForBuyingTokens,
        uint tokenPriceBeforeBuying,
        uint totalAmountOfTokensInThePool,
        uint poolInitialWorthUSD
    )
    public
    pure
    returns (uint,uint)
    {
        uint totalTokensBought;

        uint numberOfIterations;
        uint amountBuyingPerIteration;

        (numberOfIterations, amountBuyingPerIteration) = calculateNumberOfIterationsNecessary(
            amountOfUSDSpendingForBuyingTokens,
            tokenPriceBeforeBuying,
            totalAmountOfTokensInThePool
        );

        uint index;
        uint amountOfTokensReceived;
        uint newPrice = tokenPriceBeforeBuying;

        // We're looping here without any issues because number of iterations is limited to maximal 100
        for(index = 0; index < numberOfIterations; index ++) {
            // Function which will calculate the amount of tokens we got for specific iteration
            // and also besides that what will be the new token price
            (amountOfTokensReceived, newPrice, totalAmountOfTokensInThePool) = calculateAmountOfTokensPerIterationAndNewPrice(
                totalAmountOfTokensInThePool,
                newPrice,
                amountBuyingPerIteration,
                poolInitialWorthUSD
            );
            // Update total tokens which user have bought
            totalTokensBought = totalTokensBought.add(amountOfTokensReceived);
        }

        return (totalTokensBought, newPrice);
    }


    /**
     * @notice          Function which will be used always when we're buying tokens from upgradable exchange
     *                  and will take care of calculations of tokens to be bought, average token price paid
     *                  in this purchase, and what will be the new token price after purchase
     *
     * @param           amountOfUSDSpendingForBuyingTokens is the dollar amount user is spending
     * @param           tokenPriceBeforeBuying is the price of the token before purchase
     * @param           totalAmountOfTokensInThePool is the total amount of the tokens in the pool atm
     * @param           poolInitialWorthUSD is how much all 2KEY tokens in the pool should be worth together
     *
     * @dev             All input values are in WEI units
     */
    function buyTokensFromExchangeRealignPrice(
        uint amountOfUSDSpendingForBuyingTokens,
        uint tokenPriceBeforeBuying,
        uint totalAmountOfTokensInThePool,
        uint poolInitialWorthUSD
    )
    public
    pure
    returns (uint,uint,uint)
    {
        uint totalTokensBought;
        uint newTokenPrice;

        (totalTokensBought, newTokenPrice) = calculateTotalTokensUserIsGetting(
            amountOfUSDSpendingForBuyingTokens,
            tokenPriceBeforeBuying,
            totalAmountOfTokensInThePool,
            poolInitialWorthUSD
        );

        uint averageTokenPriceForPurchase = amountOfUSDSpendingForBuyingTokens.mul(10**18).div(totalTokensBought);

        return (totalTokensBought, averageTokenPriceForPurchase, newTokenPrice);
    }


    /**
     * @notice          Function to calculate amount of tokens per iteration and what will be the new price
     * @param           totalAmountOfTokensInThePool is the total amount of tokens in the pool at the moment
     * @param           tokenPrice is the price of the token at the moment
     * @param           iterationAmount is the amount user is spending in this iteration
     */
    function calculateAmountOfTokensPerIterationAndNewPrice(
        uint totalAmountOfTokensInThePool,
        uint tokenPrice,
        uint iterationAmount,
        uint poolInitialWorthUSD
    )
    public
    pure
    returns (uint,uint,uint)
    {
        // Calculate amount of tokens user is getting
        uint amountOfTokens = iterationAmount.mul(10**18).div(tokenPrice);
        // Calculate the new price for the pool
        uint tokensLeftInThePool = totalAmountOfTokensInThePool.sub(amountOfTokens);
        // The new price after the tokens are being bought
        uint newPrice = recalculatePrice(poolInitialWorthUSD, tokensLeftInThePool);

        return (amountOfTokens,newPrice,tokensLeftInThePool);
    }
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

contract TwoKeyUpgradableExchange is Upgradeable, ITwoKeySingletonUtils {

    using SafeMath for uint256;

    bool initialized;
    address constant ETH_TOKEN_ADDRESS = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    string constant _twoKeyCampaignValidator = "TwoKeyCampaignValidator";
    string constant _twoKeyEconomy = "TwoKeyEconomy";
    string constant _twoKeyExchangeRateContract = "TwoKeyExchangeRateContract";
    string constant _twoKeyAdmin = "TwoKeyAdmin";
    string constant _kyberNetworkProxy = "KYBER_NETWORK_PROXY";
    string constant _kyberReserveContract = "KYBER_RESERVE_CONTRACT";


    ITwoKeyUpgradableExchangeStorage public PROXY_STORAGE_CONTRACT;



    /**
     * @notice          This event will be fired every time a withdraw is executed
     */
    event WithdrawExecuted(
        address caller,
        address beneficiary,
        uint stableCoinsReserveBefore,
        uint stableCoinsReserveAfter,
        uint etherBalanceBefore,
        uint etherBalanceAfter,
        uint stableCoinsToWithdraw,
        uint twoKeyAmount
    );


    event HedgedEther (
        uint _daisReceived,
        uint _ratio,
        uint _numberOfContracts
    );

    /**
     * @notice          Constructor of the contract, can be called only once
     *
     * @param           _daiAddress is the address of DAI on ropsten
     * @param           _kyberNetworkProxyAddress is the address of Kyber network contract
     * @param           _twoKeySingletonesRegistry is the address of TWO_KEY_SINGLETON_REGISTRY
     * @param           _proxyStorageContract is the address of proxy of storage contract
     */
    function setInitialParams(
        address _daiAddress,
        address _kyberNetworkProxyAddress,
        address _twoKeySingletonesRegistry,
        address _proxyStorageContract
    )
    external
    {
        require(initialized == false);

        TWO_KEY_SINGLETON_REGISTRY = _twoKeySingletonesRegistry;
        PROXY_STORAGE_CONTRACT = ITwoKeyUpgradableExchangeStorage(_proxyStorageContract);
        setUint(keccak256("spreadWei"), 3**16); // 3% wei

        setUint(keccak256("sellRate2key"),6 * (10**16));// When anyone send Ether to contract, 2key in exchange will be calculated on it's sell rate
        setUint(keccak256("numberOfContracts"), 0); //Number of contracts which have interacted with this contract through buyTokens function

        setAddress(keccak256(_kyberNetworkProxy), _kyberNetworkProxyAddress);

        initialized = true;
    }


    /**
     * @notice          Modifier which will validate if contract is allowed to buy tokens
     */
    modifier onlyValidatedContracts {
        address twoKeyCampaignValidator = getAddressFromTwoKeySingletonRegistry(_twoKeyCampaignValidator);
        require(ITwoKeyCampaignValidator(twoKeyCampaignValidator).isCampaignValidated(msg.sender) == true);
        _;
    }


    /**
     * @notice          Modifier which will validate if msg sender is TwoKeyAdmin contract
     */
    modifier onlyTwoKeyAdmin {
        address twoKeyAdmin = getAddressFromTwoKeySingletonRegistry(_twoKeyAdmin);
        require(msg.sender == twoKeyAdmin);
        _;
    }


    /**
     * @dev             Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     *                  Use `super` in contracts that inherit from Crowdsale to extend their validations.
     *
     * @param           _beneficiary Address performing the token purchase
     * @param           _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    private
    {
        require(_weiAmount != 0);
    }


    /**
     * @dev             Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param           _beneficiary Address performing the token purchase
     * @param           _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        //Take the address of token from storage
        address tokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
        ERC20(tokenAddress).transfer(_beneficiary, _tokenAmount);
    }


    /**
     * @dev             Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param           _beneficiary Address receiving the tokens
     * @param           _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
    internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    /**
     * @notice          Function to calculate how much pnercentage will be deducted from values
     */
    function calculatePercentageToDeduct(
        uint _ethWeiHedged,
        uint _sumOfAmounts
    )
    internal
    view
    returns (uint)
    {
        return _ethWeiHedged.mul(10**18).div(_sumOfAmounts);
    }


    /**
     * @notice          Function to calculate ratio between eth and dai in WEI's
     */
    function calculateRatioBetweenDAIandETH(
        uint _ethWeiHedged,
        uint _daiReceived
    )
    internal
    view
    returns (uint)
    {
        return _daiReceived.mul(10**18).div(_ethWeiHedged);
    }


    /**
     * @notice          Setter for EthWeiAvailableToHedge
     * @param           _contractID is the ID of the contract
     * @param           _msgValue is the amount sent
     */
    function updateEthWeiAvailableToHedge(
        uint _contractID,
        uint _msgValue
    )
    internal {
        // Update EthWeiAvailableToHedge per contract
        bytes32 ethWeiAvailableToHedgeKeyHash = keccak256("ethWeiAvailableToHedge", _contractID);
        setUint(ethWeiAvailableToHedgeKeyHash, getUint(ethWeiAvailableToHedgeKeyHash).add(_msgValue));
    }


    /**
     * @notice          Function to register new contract with corresponding ID
     * @param           _contractAddress is the address of the contract we're adding
     */
    function addNewContract(
        address _contractAddress
    )
    internal
    returns (uint)
    {
        // Get number of currently different contracts and increment by 1
        uint numberOfContractsExisting = numberOfContracts();
        uint id = numberOfContractsExisting.add(1);

        bytes32 keyHashContractAddressToId = keccak256("contractAddressToId", _contractAddress);
        bytes32 keyHashIdToContractAddress = keccak256("idToContractAddress", id);

        // Set mappings id=>contractAddress and contractAddress=>id
        setUint(keyHashContractAddressToId, id);
        setAddress(keyHashIdToContractAddress, _contractAddress);

        // Increment number of existing contracts
        setUint(keccak256("numberOfContracts"), id);

        // Return contract ID
        return id;
    }


    /**
     * @notice          Function to emit an event, created separately because of stack depth
     */
    function emitEventWithdrawExecuted(
        address _beneficiary,
        uint _stableCoinsOnContractBefore,
        uint _stableCoinsAfter,
        uint _etherBalanceOnContractBefore,
        uint _stableCoinUnits,
        uint twoKeyUnits
    )
    internal
    {
        emit WithdrawExecuted(
            msg.sender,
            _beneficiary,
            _stableCoinsOnContractBefore,
            _stableCoinsAfter,
            _etherBalanceOnContractBefore,
            this.balance,
            _stableCoinUnits,
            twoKeyUnits
        );
    }


    /**
     * @notice          Internal function to get uint from storage contract
     *
     * @param           key is the to which value is allocated in storage
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


    /**
     * @notice          Internal function to set uint on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (uint) we're saving in the state
     */
    function setUint(
        bytes32 key,
        uint value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setUint(key, value);
    }


    /**
     * @notice          Internal function to get bool from storage contract
     *
     * @param           key is the to which value is allocated in storage
     */
    function getBool(
        bytes32 key
    )
    internal
    view
    returns (bool)
    {
        return PROXY_STORAGE_CONTRACT.getBool(key);
    }


    /**
     * @notice          Internal function to set boolean on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (boolean) we're saving in the state
     */
    function setBool(
        bytes32 key,
        bool value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setBool(key,value);
    }


    /**
     * @notice          Internal function to get address from storage contract
     *
     * @param           key is the to which value is allocated in storage
     */
    function getAddress(
        bytes32 key
    )
    internal
    view
    returns (address)
    {
        return PROXY_STORAGE_CONTRACT.getAddress(key);
    }


    /**
     * @notice          Internal function to set address on the storage contract
     *
     * @param           key is the key to which value is (will be) allocated in storage
     * @param           value is the value (address) we're saving in the state
     */
    function setAddress(
        bytes32 key,
        address value
    )
    internal
    {
        PROXY_STORAGE_CONTRACT.setAddress(key, value);
    }


    /**
     * @notice          Function to get eth received from contract for specific contract ID
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function ethReceivedFromContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("ethReceivedFromContract", _contractID));
    }


    /**
     * @notice          Function to get how many 2keys are sent to selected contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function sent2keyToContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("sent2keyToContract", _contractID));
    }


    /**
     * @notice          Function to get how much ethWei hedged per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function ethWeiHedgedPerContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("ethWeiHedgedPerContract", _contractID));
    }


    /**
     * @notice          Function to determine how many dai received from hedging per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function daiWeiReceivedFromHedgingPerContract(
        uint _contractID
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiReceivedFromHedgingPerContract", _contractID));
    }


    /**
     * @notice          Function to report that 2KEY tokens are withdrawn from the network
     *
     * @param           amountOfTokensWithdrawn is the amount of tokens he wants to withdraw
     * @param           _contractID is the id of the contract
     */
    function report2KEYWithdrawnFromNetworkInternal(
        uint amountOfTokensWithdrawn,
        uint _contractID
    )
    internal
    {
        bytes32 _daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw",_contractID);
        bytes32 _daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");

        uint _daiWeiAvailable = daiWeiAvailableToWithdraw(_contractID);
        uint _daiWeiToReduceFromAvailableAndFillReserve = getUSDStableCoinAmountFrom2keyUnits(amountOfTokensWithdrawn, _contractID);

        uint _daiWeiAvailableToFill2keyReserveCurrently = daiWeiAvailableToFill2KEYReserve();

        setUint(_daiWeiAvailableToFill2KEYReserveKeyHash, _daiWeiAvailableToFill2keyReserveCurrently.add(_daiWeiToReduceFromAvailableAndFillReserve));
        setUint(_daiWeiAvailableToWithdrawKeyHash, _daiWeiAvailable.sub(_daiWeiToReduceFromAvailableAndFillReserve));

        // Emit the event that DAI is released
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDAIReleasedAsIncome(
            msg.sender,
            _daiWeiToReduceFromAvailableAndFillReserve
        );
    }

    function updateWithdrawOrReservePoolDependingOnCampaignType(
        uint contractID,
        uint _daisReceived,
        address twoKeyFactory
    )
    internal
    {
        address campaignAddress = getContractAddressFromID(contractID);
        string memory campaignType = ITwoKeyFactory(twoKeyFactory).addressToCampaignType(campaignAddress);
        if(keccak256("CPC_PUBLIC") == keccak256(campaignType)) {
            // Means everything gets immediately released to support filling reserve
            bytes32 daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");
            setUint(daiWeiAvailableToFill2KEYReserveKeyHash, _daisReceived.add(getUint(daiWeiAvailableToFill2KEYReserveKeyHash)));
        } else {
            // Means funds are being able to withdrawn by influencers
            bytes32 daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw", contractID);
            setUint(daiWeiAvailableToWithdrawKeyHash, daiWeiAvailableToWithdraw(contractID).add(_daisReceived));
        }
    }

    /**
     * @notice          Internal function created to update specific values, separated because of stack depth
     *
     * @param           _daisReceived is the amount of received dais
     * @param           _hedgedEthWei is the amount of ethWei hedged
     * @param           _afterHedgingAvailableEthWei is the amount available after hedging
     * @param           _contractID is the ID of the contract
     */
    function updateAccountingValues(
        uint _daisReceived,
        uint _hedgedEthWei,
        uint _afterHedgingAvailableEthWei,
        uint _contractID
    )
    internal
    {
        bytes32 ethWeiAvailableToHedgeKeyHash = keccak256("ethWeiAvailableToHedge", _contractID);
        bytes32 ethWeiHedgedPerContractKeyHash = keccak256("ethWeiHedgedPerContract", _contractID);
        bytes32 daiWeiReceivedFromHedgingPerContractKeyHash = keccak256("daiWeiReceivedFromHedgingPerContract",_contractID);

        setUint(daiWeiReceivedFromHedgingPerContractKeyHash, daiWeiReceivedFromHedgingPerContract(_contractID).add(_daisReceived));
        setUint(ethWeiHedgedPerContractKeyHash, ethWeiHedgedPerContract(_contractID).add(_hedgedEthWei));
        setUint(ethWeiAvailableToHedgeKeyHash, _afterHedgingAvailableEthWei);
    }

    /**
     * @notice          Function to reduce amount of dai available to be withdrawn from selected contract
     *
     * @param           contractAddress is the address of the contract
     * @param           daiAmount is the amount of dais
     */
    function reduceDaiWeiAvailableToWithdraw(
        address contractAddress,
        uint daiAmount
    )
    internal
    {
        uint contractId = getContractId(contractAddress);
        bytes32 keyHashDaiWeiAvailableToWithdraw = keccak256('daiWeiAvailableToWithdraw', contractId);
        setUint(keyHashDaiWeiAvailableToWithdraw, daiWeiAvailableToWithdraw(contractId).sub(daiAmount));
    }


    /**
     * @notice          Function to pay Fees to a manager and transfer the tokens forward to the referrers
     *
     * @param           _beneficiary is the address who's receiving tokens
     * @param           _contractId is the id of the contract
     * @param           _totalStableCoins is the total amount of DAIs
     */
    function payFeesToManagerAndTransferTokens(
        address _beneficiary,
        uint _contractId,
        uint _totalStableCoins,
        ERC20 dai
    )
    internal
    {
        address _userPlasma = ITwoKeyReg(getAddressFromTwoKeySingletonRegistry("TwoKeyRegistry")).getEthereumToPlasma(_beneficiary);
        // Handle if there's any existing debt
        address twoKeyFeeManager = getAddressFromTwoKeySingletonRegistry("TwoKeyFeeManager");
        uint usersDebtInEth = ITwoKeyFeeManager(twoKeyFeeManager).getDebtForUser(_userPlasma);
        uint amountToPay = 0;

        if(usersDebtInEth > 0) {
            uint eth2DAI = getEth2DaiAverageExchangeRatePerContract(_contractId); // DAI / ETH
            uint totalDebtInDAI = (usersDebtInEth.mul(eth2DAI)).div(10**18); // ETH * (DAI/ETH) = DAI

            amountToPay = totalDebtInDAI;

            if (_totalStableCoins > totalDebtInDAI){
                if(_totalStableCoins < 3 * totalDebtInDAI) {
                    amountToPay = totalDebtInDAI / 2;
                }
            }
            else {
                amountToPay = _totalStableCoins / 4;
            }

            // Funds are going to admin
            dai.transfer(getAddressFromTwoKeySingletonRegistry("TwoKeyAdmin"), amountToPay);
            ITwoKeyFeeManager(twoKeyFeeManager).payDebtWithDAI(_userPlasma, totalDebtInDAI, amountToPay);
        }

        dai.transfer(_beneficiary, _totalStableCoins.sub(amountToPay)); // Transfer the rest of the DAI to users
    }


    /**
     * @notice          Function to calculate available to hedge sum on all contracts
     */
    function calculateSumOnContracts(
        uint startIndex,
        uint endIndex
    )
    public
    view
    returns (uint)
    {
        uint sumOfAmounts = 0; //Will represent total sum we have on the contract
        uint i;

        // Sum all amounts on all contracts
        for(i=startIndex; i<=endIndex; i++) {
            sumOfAmounts = sumOfAmounts.add(ethWeiAvailableToHedge(i));
        }
        return sumOfAmounts;
    }


    /**
     * @notice          Function to get contract id, if return 0 means contract is not existing
     */
    function getContractId(
        address _contractAddress
    )
    public
    view
    returns (uint) {
        bytes32 keyHashContractAddressToId = keccak256("contractAddressToId", _contractAddress);
        uint id = getUint(keyHashContractAddressToId);
        return id;
    }


    /**
     * @notice          Function to get amount of the tokens user will receive
     *
     * @param           _weiAmount Value in wei to be converted into tokens
     *
     * @return          Number of tokens that can be purchased with the specified _weiAmount
     */
    function getTokenAmountToBeSold(
        uint256 _weiAmount
    )
    public
    view
    returns (uint256,uint256,uint256)
    {
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        uint rate = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getBaseToTargetRate("USD");
        uint dollarAmountWei = _weiAmount.mul(rate).div(10**18);

        return get2KEYTokenPriceAndAmountOfTokensReceiving(dollarAmountWei);
    }


    /**
     * @notice          Function to calculate how many stable coins we can get for specific amount of 2keys
     *
     * @dev             This is happening in case we're receiving (buying) 2key
     *
     * @param           _2keyAmount is the amount of 2keys sent to the contract
     * @param           _campaignID is the ID of the campaign
     */
    function getUSDStableCoinAmountFrom2keyUnits(
        uint256 _2keyAmount,
        uint _campaignID
    )
    public
    view
    returns (uint256)
    {
        uint activeHedgeRate = get2KEY2DAIHedgedRate(_campaignID);

        uint hundredPercent = 10**18;
        uint rateWithSpread = activeHedgeRate.mul(hundredPercent.sub(spreadWei())).div(10**18);
        uint amountOfDAIs = _2keyAmount.mul(rateWithSpread).div(10**18);

        return amountOfDAIs;
    }


    function getMore2KeyTokensForRebalancingV1(
        uint amountOfTokensRequested
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));
        _processPurchase(msg.sender, amountOfTokensRequested);
    }

    function returnTokensBackToExchangeV1(
        uint amountOfTokensToReturn
    )
    public
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));
        // Take the tokens from the contract
        IERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy)).transferFrom(
            msg.sender,
            address(this),
            amountOfTokensToReturn
        );
    }


    /**
     * @notice          Function to buyTokens from TwoKeyUpgradableExchange
     * @param           _beneficiary is the address which will receive the tokens
     * @return          amount of tokens bought
     */
    function buyTokens(
        address _beneficiary
    )
    public
    payable
    onlyValidatedContracts
    returns (uint,uint)
    {
        _preValidatePurchase(_beneficiary, msg.value);

        uint totalTokensBought;
        uint averageTokenPriceForPurchase;
        uint newTokenPrice;

        (totalTokensBought, averageTokenPriceForPurchase, newTokenPrice) = getTokenAmountToBeSold(msg.value);


        set2KEYSellRateInternal(newTokenPrice);

        // check if contract is first time interacting with this one
        uint contractId = getContractId(msg.sender);

        // Check if the contract exists
        if(contractId == 0) {
            contractId = addNewContract(msg.sender);
        }

        setHedgingInformationAndContractStats(
            contractId,
            totalTokensBought,
            msg.value
        );

        _processPurchase(_beneficiary, totalTokensBought);

        return (totalTokensBought, averageTokenPriceForPurchase);
    }

    function buyTokensWithERC20(
        uint amountOfTokens,
        address tokenAddress
    )
    public
    returns (uint,uint)
    {
        require(msg.sender == getAddressFromTwoKeySingletonRegistry("TwoKeyBudgetCampaignsPaymentsHandler"));

        uint totalTokensBought;
        uint averageTokenPriceForPurchase;
        uint newTokenPrice;

        // Increment amount of this stable tokens to fill reserve
        addStableCoinsAvailableToFillReserve(amountOfTokens, tokenAddress);

        uint amountInUSDOfPurchase = computeAmountInUsd(amountOfTokens, tokenAddress);

        // Process price discovery, buy tokens, and get new price
        (totalTokensBought, averageTokenPriceForPurchase, newTokenPrice) = get2KEYTokenPriceAndAmountOfTokensReceiving(amountInUSDOfPurchase);

        // Set new token price
        set2KEYSellRateInternal(newTokenPrice);

        // Transfer tokens
        _processPurchase(msg.sender, totalTokensBought);

        // Return amount of tokens received and average token price for purchase
        return (totalTokensBought, averageTokenPriceForPurchase);
    }

    function computeAmountInUsd(
        uint amountInTokenDecimals,
        address tokenAddress
    )
    internal
    view
    returns (uint)
    {
        // Get the address of twoKeyExchangeRateContract
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        // Get stable coin to dollar rate
        uint tokenToUsd = ITwoKeyExchangeRateContract(twoKeyExchangeRateContract).getStableCoinToUSDQuota(tokenAddress);

        // Get token decimals
        uint tokenDecimals = IERC20(tokenAddress).decimals();

        uint oneEth = 10 ** 18;

        return amountInTokenDecimals.mul(oneEth.div(10 ** tokenDecimals)).mul(tokenToUsd).div(oneEth);
    }



    /**
     * @notice          Internal function to update the state in case tokens were bought for influencers
     *yes
     * @param           contractID is the ID of the contract
     * @param           amountOfTokensBeingSentToContract is the amount of 2KEY tokens being sent to the contract
     * @param           purchaseAmountETH is the amount of ETH spent to purchase tokens
     */
    function setHedgingInformationAndContractStats(
        uint contractID,
        uint amountOfTokensBeingSentToContract,
        uint purchaseAmountETH
    )
    internal
    {
        // Update how much ether we received from msg.sender contract
        bytes32 ethReceivedFromContractKeyHash = keccak256("ethReceivedFromContract", contractID);
        setUint(ethReceivedFromContractKeyHash, ethReceivedFromContract(contractID).add(purchaseAmountETH));

        // Update how much 2KEY tokens we sent to msg.sender contract
        bytes32 sent2keyToContractKeyHash = keccak256("sent2keyToContract", contractID);
        setUint(sent2keyToContractKeyHash, sent2keyToContract(contractID).add(amountOfTokensBeingSentToContract));

        updateEthWeiAvailableToHedge(contractID, purchaseAmountETH);

    }

    function set2KEYSellRateInternal(
        uint newRate
    )
    internal
    {
        setUint(
            keccak256("sellRate2key"),
            newRate
        );
    }

    function setStableCoinsAvailableToFillReserve(
        uint amountOfStableCoins,
        address stableCoinAddress
    )
    internal
    {
        bytes32 key = keccak256("stableCoinToAmountAvailableToFillReserve", stableCoinAddress);

        setUint(
            key,
            amountOfStableCoins
        );
    }


    function addStableCoinsAvailableToFillReserve(
        uint amountOfStableCoins,
        address stableCoinAddress
    )
    internal
    {
        bytes32 key = keccak256("stableCoinToAmountAvailableToFillReserve", stableCoinAddress);

        uint currentBalance = getUint(key);
        setUint(
            key,
            currentBalance.add(amountOfStableCoins)
        );
    }

    function getAvailableAmountToFillReserveInternal(
        address tokenAddress
    )
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("stableCoinToAmountAvailableToFillReserve", tokenAddress));
    }

    /**
     * @notice          Function to get array containing how much of the tokens are available to fill reserve
     * @param           stableCoinAddresses is array of stable coin
     */
    function getAvailableAmountToFillReserve(
        address [] stableCoinAddresses
    )
    public
    view
    returns (uint[])
    {
        uint numberOfTokens = stableCoinAddresses.length;
        uint[] memory availableAmounts = new uint[](numberOfTokens);

        uint i;
        for(i=0; i<numberOfTokens; i++) {
            availableAmounts[i] = getAvailableAmountToFillReserveInternal(stableCoinAddresses[i]);
        }

        return availableAmounts;
    }


    function releaseAllDAIFromContractToReserve()
    public
    onlyValidatedContracts
    {
        uint _contractID = getContractId(msg.sender);
        bytes32 _daiWeiAvailableToWithdrawKeyHash = keccak256("daiWeiAvailableToWithdraw",_contractID);
        bytes32 _daiWeiAvailableToFill2KEYReserveKeyHash = keccak256("daiWeiAvailableToFill2KEYReserve");

        uint _daiWeiAvailableToWithdrawAndFillReserve = daiWeiAvailableToWithdraw(_contractID);

        uint _daiWeiAvailableToFill2keyReserveCurrently = daiWeiAvailableToFill2KEYReserve();

        setUint(_daiWeiAvailableToFill2KEYReserveKeyHash, _daiWeiAvailableToFill2keyReserveCurrently.add(_daiWeiAvailableToWithdrawAndFillReserve));
        setUint(_daiWeiAvailableToWithdrawKeyHash, 0);

        // Emit the event that DAI is released
        ITwoKeyEventSource(getAddressFromTwoKeySingletonRegistry("TwoKeyEventSource")).emitDAIReleasedAsIncome(
            msg.sender,
            _daiWeiAvailableToWithdrawAndFillReserve
        );

    }

    /**
     * @notice          Function which will be called every time by campaign when referrer select to withdraw directly 2key token
     *
     * @param           amountOfTokensWithdrawn is the amount of tokens he wants to withdraw
     */
    function report2KEYWithdrawnFromNetwork(
        uint amountOfTokensWithdrawn
    )
    public
    onlyValidatedContracts
    {
        uint _contractID = getContractId(msg.sender);
        if(ethReceivedFromContract(_contractID) > 0 ) {
            report2KEYWithdrawnFromNetworkInternal(amountOfTokensWithdrawn, _contractID);
        }
    }


    /**
     * @notice          Function to get expected rate from Kyber contract
     * @param           amountSrcWei is the amount we'd like to exchange
     * @param           srcToken is the address of src token we want to swap
     * @param           destToken is the address of destination token we want to get
     * @return          if the value is 0 that means we can't
     */
    function getKyberExpectedRate(
        uint amountSrcWei,
        address srcToken,
        address destToken
    )
    public
    view
    returns (uint)
    {
        address kyberProxyContract = getAddress(keccak256(_kyberNetworkProxy));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        ERC20 src = ERC20(srcToken);
        ERC20 dest = ERC20(destToken);

        uint minConversionRate;
        (minConversionRate,) = proxyContract.getExpectedRate(src, dest, amountSrcWei);

        return minConversionRate;
    }


    /**
     * @notice          Function to relay demand of stable coins we have in exchange to
     *                  uniswap exchange.
     * @param           stableCoinsAddresses is array of addresses of stable coins we're going to swap
     * @param           amounts are corresponding amounts of tokens that are going to be swapped.
     */
    function swapStableCoinsAvailableToFillReserveFor2KEY(
        address [] stableCoinsAddresses,
        uint [] amounts
    )
    public
    onlyMaintainer
    {
        uint numberOfTokens = stableCoinsAddresses.length;
        uint i;

        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        // Create a path array
        address [] memory path = new address[](3);

        for (i = 0; i < numberOfTokens; i++) {
            // Load the token address
            address tokenAddress = stableCoinsAddresses[i];

            // Get how much is available to fill reserve
            uint availableForReserve = getAvailableAmountToFillReserveInternal(tokenAddress);

            // Require that amount wanted to swap is less or equal to amount present in reserve
            require(amounts[i] <= availableForReserve);

            uint amountToSwap = amounts[i];

            // Reduce amount used to swap from available in reserve
            setStableCoinsAvailableToFillReserve(
                availableForReserve.sub(amountToSwap),
                tokenAddress
            );

            // Approve uniswap router to take tokens from the contract
            IERC20(tokenAddress).approve(
                uniswapRouter,
                amountToSwap
            );

            // Override always the path array
            path[0] = tokenAddress;
            path[1] = IUniswapV2Router02(uniswapRouter).WETH();
            path[2] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");

            // Get minimum received
            uint minimumToReceive = uniswapPriceDiscover(
                uniswapRouter,
                amountToSwap,
                path
            );

            // Execute swap
            IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(
                amountToSwap,
                minimumToReceive.mul(97).div(100), // Allow 3 percent to drop
                path,
                address(this),
                block.timestamp + (10 minutes)
            );
        }
    }


    /**
     * @notice          Function to start hedging some ether amount
     * @param           amountToBeHedged is the amount we'd like to hedge
     * @dev             only maintainer can call this function
     */
    function startHedging(
        uint amountToBeHedged,
        uint approvedMinConversionRate
    )
    public
    onlyMaintainer
    {
        ERC20 dai = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"));

        if(amountToBeHedged > address(this).balance) {
            amountToBeHedged = address(this).balance;
        }

        address kyberProxyContract = getAddress(keccak256(_kyberNetworkProxy));
        IKyberNetworkProxy proxyContract = IKyberNetworkProxy(kyberProxyContract);

        // Get minimal conversion rate for the swap of ETH->DAI token
        uint minConversionRate = getKyberExpectedRate(amountToBeHedged, ETH_TOKEN_ADDRESS, address(dai));

        require(minConversionRate >= approvedMinConversionRate.mul(95).div(100)); //Means our rate can be at most same as their rate, because they're giving the best rate
        uint stableCoinUnits = proxyContract.swapEtherToToken.value(amountToBeHedged)(dai,minConversionRate);
        // Get the ratio between ETH and DAI for this hedging
        uint ratio = calculateRatioBetweenDAIandETH(amountToBeHedged, stableCoinUnits);
        //Emit event with important data
        emit HedgedEther(stableCoinUnits, ratio, numberOfContracts());
    }


    function calculateHedgedAndReceivedForDefinedChunk(
        uint numberOfContractsCurrently,
        uint amountHedged,
        uint stableCoinsReceived,
        uint startIndex,
        uint endIndex
    )
    public
    view
    returns (uint,uint)
    {
        //We're calculating sum on contracts between start and end index
        uint sumInRange = calculateSumOnContracts(startIndex,endIndex);
        //Now we need how much was hedged from this contracts between start and end index
        uint stableCoinsReceivedForThisChunkOfContracts = (sumInRange.mul(stableCoinsReceived)).div(amountHedged);
        // Returning for this piece of contracts
        return (sumInRange, stableCoinsReceivedForThisChunkOfContracts);
    }

    /**
     * @notice          Function to reduce available amount to hedge and increase available DAI to withdraw
     *
     * @param           _ethWeiHedgedForThisChunk is how much eth was hedged
     * @param           _daiReceivedForThisChunk is how much DAI's we got for that hedging
     */
    function reduceHedgedAmountFromContractsAndIncreaseDaiAvailable(
        uint _ethWeiHedgedForThisChunk,
        uint _daiReceivedForThisChunk,
        uint _ratio,
        uint _startIndex,
        uint _endIndex
    )
    public
    onlyMaintainer
    {
        uint i;
        uint percentageToDeductWei = calculatePercentageToDeduct(_ethWeiHedgedForThisChunk, _ethWeiHedgedForThisChunk); // Percentage to deduct in WEI (less than 1)
        address twoKeyFactory = getAddressFromTwoKeySingletonRegistry("TwoKeyFactory");
        for(i=_startIndex; i<=_endIndex; i++) {
            if(ethWeiAvailableToHedge(i) > 0) {
                uint beforeHedgingAvailableEthWeiForContract = ethWeiAvailableToHedge(i);
                uint hundredPercentWei = 10**18;
                uint afterHedgingAvailableEthWei = beforeHedgingAvailableEthWeiForContract.mul(hundredPercentWei.sub(percentageToDeductWei)).div(10**18);

                uint hedgedEthWei = beforeHedgingAvailableEthWeiForContract.sub(afterHedgingAvailableEthWei);
                uint daisReceived = hedgedEthWei.mul(_ratio).div(10**18);
                updateWithdrawOrReservePoolDependingOnCampaignType(i, daisReceived, twoKeyFactory);
                updateAccountingValues(daisReceived, hedgedEthWei, afterHedgingAvailableEthWei, i);
            }
        }
    }


    /**
     * @notice          Function which will be called by 2key campaigns if user wants to withdraw his earnings in stableCoins
     *
     * @param           _twoKeyUnits is the amount of 2key tokens which will be taken from campaign
     * @param           _beneficiary is the user who will receive the tokens
     */
    function buyStableCoinWith2key(
        uint _twoKeyUnits,
        address _beneficiary
    )
    public
    onlyValidatedContracts
    {
        ERC20 dai = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI"));
        ERC20 token = ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy));

        uint contractId = getContractId(msg.sender); // Get the contract ID

        uint stableCoinUnits = getUSDStableCoinAmountFrom2keyUnits(_twoKeyUnits, contractId); // Calculate how much stable coins he's getting
        uint etherBalanceOnContractBefore = this.balance; // get ether balance on contract
        uint stableCoinsOnContractBefore = dai.balanceOf(address(this)); // get dai balance on contract

        reduceDaiWeiAvailableToWithdraw(msg.sender, stableCoinUnits); // reducing amount of DAI available for withdrawal

        emitEventWithdrawExecuted(
            _beneficiary,
            stableCoinsOnContractBefore,
            stableCoinsOnContractBefore.sub(stableCoinUnits),
            etherBalanceOnContractBefore,
            stableCoinUnits,
            _twoKeyUnits
        );

        token.transferFrom(msg.sender, address(this), _twoKeyUnits); //Take all 2key tokens from campaign contract
        payFeesToManagerAndTransferTokens(_beneficiary, contractId, stableCoinUnits, dai);
    }


    /**
     * @notice          Function to return number of campaign contracts (different) interacted with this contract
     */
    function numberOfContracts()
    public
    view
    returns (uint)
    {
        return getUint(keccak256("numberOfContracts"));
    }


    /**
     * @notice          Function to get 2key to DAI hedged rate
     *
     * @param           _contractID is the ID of the contract we're fetching this rate (avg)
     */
    function get2KEY2DAIHedgedRate(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getEth2DaiAverageExchangeRatePerContract(_contractID).mul(10**18).div(getEth2KeyAverageRatePerContract(_contractID));
    }

    /**
     * @notice          Function to get Eth2DAI average exchange rate per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function getEth2DaiAverageExchangeRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        uint ethWeiHedgedPerContractByNow = ethWeiHedgedPerContract(_contractID); //total hedged
        uint daiWeiReceivedFromHedgingPerContractByNow = daiWeiReceivedFromHedgingPerContract(_contractID); //total received
        // Average weighted by eth
        return daiWeiReceivedFromHedgingPerContractByNow.mul(10**18).div(ethWeiHedgedPerContractByNow); //dai/eth
    }


    /**
     * @notice          Function to get Eth22key average exchange rate per contract
     *
     * @param           _contractID is the ID of the contract we're requesting information
     */
    function getEth2KeyAverageRatePerContract(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        uint ethReceivedFromContractByNow = ethReceivedFromContract(_contractID);
        uint sent2keyToContractByNow = sent2keyToContract(_contractID);
        if(sent2keyToContractByNow == 0 || ethReceivedFromContractByNow == 0) {
            return 0;
        }
        // Average weighted by eth 2key/eth
        return sent2keyToContractByNow.mul(10**18).div(ethReceivedFromContractByNow);
    }


    /**
     * @notice          Function to check how much dai is available to fill reserve
     */
    function daiWeiAvailableToFill2KEYReserve()
    public
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiAvailableToFill2KEYReserve"));
    }


    /**
     * @notice          Getter for mapping "daiWeiAvailableToWithdraw" (per contract)
     */
    function daiWeiAvailableToWithdraw(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256("daiWeiAvailableToWithdraw", _contractID));
    }


    /**
     * @notice          Getter for "mapping" ethWeiAvailableToHedge (per contract)
     */
    function ethWeiAvailableToHedge(
        uint _contractID
    )
    public
    view
    returns (uint)
    {
        return getUint(keccak256("ethWeiAvailableToHedge", _contractID));
    }


    /**
     * @notice          Getter wrapping all information about income/outcome for every contract
     * @param           _contractAddress is the main campaign address
     */
    function getAllStatsForContract(
        address _contractAddress
    )
    public
    view
    returns (uint,uint,uint,uint,uint,uint)
    {
        uint _contractID = getContractId(_contractAddress);
        return (
            ethWeiAvailableToHedge(_contractID),
            daiWeiAvailableToWithdraw(_contractID),
            daiWeiReceivedFromHedgingPerContract(_contractID),
            ethWeiHedgedPerContract(_contractID),
            sent2keyToContract(_contractID),
            ethReceivedFromContract(_contractID)
        );
    }


    /**
     * @notice          Getter function to check if campaign has been hedged ever
     *                  Assuming that this function regarding flow will be called at point where there must be
     *                  executed conversions, and in that case, if there are no any ETH received from contract,
     *                  that means that this campaign is not hedgeable
     *
     * @param           _contractAddress is the campaign address
     */
    function isCampaignHedgeable(
        address _contractAddress
    )
    public
    view
    returns (bool)
    {
        uint _contractID = getContractId(_contractAddress);
        return ethReceivedFromContract(_contractID) > 0 ? true : false;
    }


    /**
     * @notice          Function to get contract address from it's ID
     * @param           contractID is the ID assigned to contract
     */
    function getContractAddressFromID(
        uint contractID
    )
    internal
    view
    returns (address)
    {
        return getAddress(keccak256("idToContractAddress", contractID));
    }


    /**
     * @notice          Getter to check how much is pool worth in USD
     */
    function poolWorthUSD(
        uint amountOfTokensInThePool,
        uint averagePriceFrom3MainSources
    )
    internal
    view
    returns (uint)
    {
        return (averagePriceFrom3MainSources.mul(amountOfTokensInThePool).div(10 ** 18));
    }


    /**
     * @notice          Getter to get spreadWei value
     */
    function spreadWei()
    internal
    view
    returns (uint)
    {
        return getUint(keccak256("spreadWei"));
    }

    /**
     * @notice          Function to be used to fetch 2KEY-DAI rate from uniswap
     * @notice          amountToSwap is in wei value
     * @param           path is the path of swap (TOKEN_A - TOKEN_B) or (TOKEN_A - WETH - TOKEN_B)
     */
    function uniswapPriceDiscover(
        address uniswapRouter,
        uint amountToSwap,
        address [] path
    )
    public
    view
    returns (uint)
    {
        uint[] memory amountsOut = new uint[](2);

        amountsOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(
            amountToSwap,
            path
        );

        return amountsOut[1];
    }

    /**
     * @notice          Getter for 2key sell rate
     */
    function sellRate2key()
    public
    view
    returns (uint)
    {
        address twoKeyExchangeRateContract = getAddressFromTwoKeySingletonRegistry(_twoKeyExchangeRateContract);

        address [] memory path = new address[](2);
        address uniswapRouter = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("UniswapV2Router02");

        path[0] = getNonUpgradableContractAddressFromTwoKeySingletonRegistry("TwoKeyEconomy");
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();

        // Represents how much 1 2KEY is worth ETH
        uint rateFromUniswap = uniswapPriceDiscover(uniswapRouter, 10 ** 18, path);

        // Rate from ETH-USD oracle
        uint eth_usdRate = ITwoKeyExchangeRateContract(getAddressFromTwoKeySingletonRegistry("TwoKeyExchangeRateContract"))
            .getBaseToTargetRate("USD");


        // Rate computed by combination of ChainLink oracle (ETH-USD) and Uniswap (2KEY-ETH)

        // Which will represent final 2KEY-USD rate
        uint finalRate = rateFromUniswap.mul(eth_usdRate).div(10**18);

        uint rateFromContract = getUint(keccak256("sellRate2key"));

        return (finalRate.add(rateFromContract)).div(2);
    }


    function withdrawDAIAvailableToFill2KEYReserve(
        uint amountOfDAI
    )
    public
    onlyTwoKeyAdmin
    returns (uint)
    {
        uint daiWeiAvailableToFill2keyReserve = daiWeiAvailableToFill2KEYReserve();
        if(amountOfDAI == 0) {
            amountOfDAI = daiWeiAvailableToFill2keyReserve;
        } else {
            require(amountOfDAI <= daiWeiAvailableToFill2keyReserve);
        }

        ERC20(getNonUpgradableContractAddressFromTwoKeySingletonRegistry("DAI")).transfer(msg.sender, amountOfDAI);
        bytes32 key = keccak256("daiWeiAvailableToFill2KEYReserve");

        // Set that there's not DAI to fill reserve anymore
        setUint(key, daiWeiAvailableToFill2keyReserve.sub(amountOfDAI));

        // Return how much have been withdrawn
        return amountOfDAI;
    }

    /**
     * @notice          Function to get amount of 2KEY receiving, new token price, and average price per token
     *i
     * @param           purchaseAmountUSDWei is the amount of USD user is spending to buy tokens
     */
    function get2KEYTokenPriceAndAmountOfTokensReceiving(
        uint purchaseAmountUSDWei
    )
    public
    view
    returns (uint,uint,uint)
    {
        uint currentPrice = sellRate2key();

        // In case 0 USD is inputted, return 0 as bought, and current price as average and new.
        if(purchaseAmountUSDWei == 0) {
            return (0, currentPrice, currentPrice);
        }

        uint balanceOfTokens = getPoolBalanceOf2KeyTokens();

        return PriceDiscovery.buyTokensFromExchangeRealignPrice(
            purchaseAmountUSDWei,
            currentPrice,
            balanceOfTokens,
            poolWorthUSD(balanceOfTokens, currentPrice)
        );
    }


    function getPoolBalanceOf2KeyTokens()
    internal
    view
    returns (uint)
    {
        address tokenAddress = getNonUpgradableContractAddressFromTwoKeySingletonRegistry(_twoKeyEconomy);
        return ERC20(tokenAddress).balanceOf(address(this));
    }


    /**
     * @notice          Fallback function to handle incoming ether
     */
    function()
    public
    payable
    {

    }

}