// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "SafeMath.sol";
import "Ownable.sol";
import "Initializable.sol";
import "IIdeaToken.sol";
import "IIdeaTokenFactory.sol";
import "IInterestManager.sol";
import "IIdeaTokenExchange.sol";

/**
 * @title IdeaTokenExchange
 * @author Alexander Schlindwein
 *
 * Exchanges Dai <-> IdeaTokens using a bonding curve. Sits behind a proxy
 */
contract IdeaTokenExchange is IIdeaTokenExchange, Initializable, Ownable {
    using SafeMath for uint256;

    // Stored for every IdeaToken and market.
    // Keeps track of the amount of invested dai in this token, and the amount of investment tokens (e.g. cDai).
    struct ExchangeInfo {
        // The amount of Dai collected by trading
        uint dai;
        // The amount of "investment tokens", e.g. cDai
        uint invested; 
    }

    uint constant FEE_SCALE = 10000;

    // The address authorized to set token and platform owners.
    // It is only allowed to change these when the current owner is not set (zero address).
    // Using such an address allows an external program to make authorization calls without having to go through the timelock.
    address _authorizer;

    // The amount of "investment tokens" for the collected trading fee, e.g. cDai 
    uint _tradingFeeInvested; 
    // The address which receives the trading fee when withdrawTradingFee is called
    address _tradingFeeRecipient;

    // marketID => owner. The owner of a platform.
    // This address is allowed to withdraw platform fee.
    // When allInterestToPlatform=true then this address can also withdraw the platform interest
    mapping(uint => address) _platformOwner;

    // marketID => amount. The amount of "investment tokens" for the collected platform fee, e.g. cDai
    mapping(uint => uint) _platformFeeInvested;
    

    // marketID => ExchangeInfo. Stores ExchangeInfo structs for platforms
    mapping(uint => ExchangeInfo) _platformsExchangeInfo;

    // IdeaToken address => owner. The owner of an IdeaToken.
    // This address is allowed to withdraw the interest for an IdeaToken
    mapping(address => address) _tokenOwner;
    // IdeaToken address => ExchangeInfo. Stores ExchangeInfo structs for IdeaTokens
    mapping(address => ExchangeInfo) _tokensExchangeInfo;

    // IdeaTokenFactory contract
    IIdeaTokenFactory _ideaTokenFactory;
    // InterestManager contract
    IInterestManager _interestManager;
    // Dai contract
    IERC20 _dai;

    // IdeaToken address => bool. Whether or not to disable all fee collection for a specific IdeaToken.
    mapping(address => bool) _tokenFeeKillswitch;

    event NewTokenOwner(address ideaToken, address owner);
    event NewPlatformOwner(uint marketID, address owner);

    event InvestedState(uint marketID, address ideaToken, uint dai, uint daiInvested, uint tradingFeeInvested, uint platformFeeInvested, uint volume);
    
    event PlatformInterestRedeemed(uint marketID, uint investmentToken, uint daiRedeemed);
    event TokenInterestRedeemed(address ideaToken, uint investmentToken, uint daiRedeemed);
    event TradingFeeRedeemed(uint daiRedeemed);
    event PlatformFeeRedeemed(uint marketID, uint daiRedeemed);
    
    /**
     * Initializes the contract
     *
     * @param owner The owner of the contract
     * @param tradingFeeRecipient The address of the recipient of the trading fee
     * @param interestManager The address of the InterestManager
     * @param dai The address of Dai
     */
    function initialize(address owner,
                        address authorizer,
                        address tradingFeeRecipient,
                        address interestManager,
                        address dai) external initializer {
        require(authorizer != address(0) &&
                tradingFeeRecipient != address(0) &&
                interestManager != address(0) &&
                dai != address(0),
                "invalid-params");

        setOwnerInternal(owner); // Checks owner to be non-zero
        _authorizer = authorizer;
        _tradingFeeRecipient = tradingFeeRecipient;
        _interestManager = IInterestManager(interestManager);
        _dai = IERC20(dai);
    }

    /**
     * Burns IdeaTokens in exchange for Dai
     *
     * @param ideaToken The IdeaToken to sell
     * @param amount The amount of IdeaTokens to sell
     * @param minPrice The minimum allowed price in Dai for selling `amount` IdeaTokens
     * @param recipient The recipient of the redeemed Dai
     */
    function sellTokens(address ideaToken, uint amount, uint minPrice, address recipient) external override {

        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByTokenAddress(ideaToken);
        require(marketDetails.exists, "token-not-exist");
        uint marketID = marketDetails.id;

        CostAndPriceAmounts memory amounts = getPricesForSellingTokens(marketDetails, IERC20(ideaToken).totalSupply(), amount, _tokenFeeKillswitch[ideaToken]);

        require(amounts.total >= minPrice, "below-min-price");
        require(IIdeaToken(ideaToken).balanceOf(msg.sender) >= amount, "insufficient-tokens");
        
        IIdeaToken(ideaToken).burn(msg.sender, amount);

        _interestManager.accrueInterest();

        ExchangeInfo storage exchangeInfo;
        if(marketDetails.allInterestToPlatform) {
            exchangeInfo = _platformsExchangeInfo[marketID];
        } else {
            exchangeInfo = _tokensExchangeInfo[ideaToken];
        }

        uint tradingFeeInvested;
        uint platformFeeInvested;
        uint invested;
        uint dai;
        {
        uint totalRedeemed = _interestManager.redeem(address(this), amounts.total);
        uint tradingFeeRedeemed = _interestManager.underlyingToInvestmentToken(amounts.tradingFee);
        uint platformFeeRedeemed = _interestManager.underlyingToInvestmentToken(amounts.platformFee);

        invested = exchangeInfo.invested.sub(totalRedeemed.add(tradingFeeRedeemed).add(platformFeeRedeemed));
        exchangeInfo.invested = invested;
        tradingFeeInvested = _tradingFeeInvested.add(tradingFeeRedeemed);
        _tradingFeeInvested = tradingFeeInvested;
        platformFeeInvested = _platformFeeInvested[marketID].add(platformFeeRedeemed);
        _platformFeeInvested[marketID] = platformFeeInvested;
        dai = exchangeInfo.dai.sub(amounts.raw);
        exchangeInfo.dai = dai;
        }

        emit InvestedState(marketID, ideaToken, dai, invested, tradingFeeInvested, platformFeeInvested, amounts.raw);
        require(_dai.transfer(recipient, amounts.total), "dai-transfer");
    }


    /**
     * Returns the price for selling IdeaTokens
     *
     * @param ideaToken The IdeaToken to sell
     * @param amount The amount of IdeaTokens to sell
     *
     * @return The price in Dai for selling `amount` IdeaTokens
     */
    function getPriceForSellingTokens(address ideaToken, uint amount) external view override returns (uint) {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByTokenAddress(ideaToken);
        return getPricesForSellingTokens(marketDetails, IERC20(ideaToken).totalSupply(), amount, _tokenFeeKillswitch[ideaToken]).total;
    }

    /**
     * Calculates each price related to selling tokens
     *
     * @param marketDetails The market details
     * @param supply The existing supply of the IdeaToken
     * @param amount The amount of IdeaTokens to sell
     *
     * @return total cost, raw cost and trading fee
     */
    function getPricesForSellingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) public pure override returns (CostAndPriceAmounts memory) {
        
        uint rawPrice = getRawPriceForSellingTokens(marketDetails.baseCost,
                                                    marketDetails.priceRise,
                                                    marketDetails.hatchTokens,
                                                    supply,
                                                    amount);

        uint tradingFee = 0;
        uint platformFee = 0;

        if(!feesDisabled) {
            tradingFee = rawPrice.mul(marketDetails.tradingFeeRate).div(FEE_SCALE);
            platformFee = rawPrice.mul(marketDetails.platformFeeRate).div(FEE_SCALE);
        }   
        
        uint totalPrice = rawPrice.sub(tradingFee).sub(platformFee);

        return CostAndPriceAmounts({
            total: totalPrice,
            raw: rawPrice,
            tradingFee: tradingFee,
            platformFee: platformFee
        });
    }

    /**
     * Returns the price for selling tokens without any fees applied
     *
     * @param baseCost The baseCost of the token
     * @param priceRise The priceRise of the token
     * @param hatchTokens The amount of hatch tokens
     * @param supply The current total supply of the token
     * @param amount The amount of IdeaTokens to sell
     *
     * @return The price selling `amount` IdeaTokens without any fees applied
     */
    function getRawPriceForSellingTokens(uint baseCost, uint priceRise, uint hatchTokens, uint supply, uint amount) internal pure returns (uint) {

        uint hatchPrice = 0;
        uint updatedAmount = amount;
        uint updatedSupply;

        if(supply.sub(amount) < hatchTokens) {

            if(supply <= hatchTokens) {
                return baseCost.mul(amount).div(10**18);
            }

            // No SafeMath required because supply - amount < hatchTokens
            uint tokensInHatch = hatchTokens - (supply - amount);
            hatchPrice = baseCost.mul(tokensInHatch).div(10**18);
            updatedAmount = amount.sub(tokensInHatch);
            // No SafeMath required because supply >= hatchTokens
            updatedSupply = supply - hatchTokens;
        } else {
            // No SafeMath required because supply >= hatchTokens
            updatedSupply = supply - hatchTokens;
        }

        uint priceAtSupply = baseCost.add(priceRise.mul(updatedSupply).div(10**18));
        uint priceAtSupplyMinusAmount = baseCost.add(priceRise.mul(updatedSupply.sub(updatedAmount)).div(10**18));
        uint average = priceAtSupply.add(priceAtSupplyMinusAmount).div(2);
    
        return hatchPrice.add(average.mul(updatedAmount).div(10**18));
    }

    /**
     * Mints IdeaTokens in exchange for Dai
     *
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     * @param fallbackAmount The fallback amount to buy in case the price changed
     * @param cost The maximum allowed cost in Dai
     * @param recipient The recipient of the bought IdeaTokens
     */
    function buyTokens(address ideaToken, uint amount, uint fallbackAmount, uint cost, address recipient) external override {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByTokenAddress(ideaToken);
        require(marketDetails.exists, "token-not-exist");
        uint marketID = marketDetails.id;

        uint supply = IERC20(ideaToken).totalSupply();
        bool feesDisabled = _tokenFeeKillswitch[ideaToken];
        uint actualAmount = amount;

        CostAndPriceAmounts memory amounts = getCostsForBuyingTokens(marketDetails, supply, actualAmount, feesDisabled);

        if(amounts.total > cost) {
            actualAmount = fallbackAmount;
            amounts = getCostsForBuyingTokens(marketDetails, supply, actualAmount, feesDisabled);
    
            require(amounts.total <= cost, "slippage");
        }

        
        require(_dai.allowance(msg.sender, address(this)) >= amounts.total, "insufficient-allowance");
        require(_dai.transferFrom(msg.sender, address(_interestManager), amounts.total), "dai-transfer");
        
        _interestManager.accrueInterest();
        _interestManager.invest(amounts.total);


        ExchangeInfo storage exchangeInfo;
        if(marketDetails.allInterestToPlatform) {
            exchangeInfo = _platformsExchangeInfo[marketID];
        } else {
            exchangeInfo = _tokensExchangeInfo[ideaToken];
        }

        exchangeInfo.invested = exchangeInfo.invested.add(_interestManager.underlyingToInvestmentToken(amounts.raw));
        uint tradingFeeInvested = _tradingFeeInvested.add(_interestManager.underlyingToInvestmentToken(amounts.tradingFee));
        _tradingFeeInvested = tradingFeeInvested;
        uint platformFeeInvested = _platformFeeInvested[marketID].add(_interestManager.underlyingToInvestmentToken(amounts.platformFee));
        _platformFeeInvested[marketID] = platformFeeInvested;
        exchangeInfo.dai = exchangeInfo.dai.add(amounts.raw);
    
        emit InvestedState(marketID, ideaToken, exchangeInfo.dai, exchangeInfo.invested, tradingFeeInvested, platformFeeInvested, amounts.total);
        IIdeaToken(ideaToken).mint(recipient, actualAmount);
    }

    /**
     * Returns the cost for buying IdeaTokens
     *
     * @param ideaToken The IdeaToken to buy
     * @param amount The amount of IdeaTokens to buy
     *
     * @return The cost in Dai for buying `amount` IdeaTokens
     */
    function getCostForBuyingTokens(address ideaToken, uint amount) external view override returns (uint) {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByTokenAddress(ideaToken);

        return getCostsForBuyingTokens(marketDetails, IERC20(ideaToken).totalSupply(), amount, _tokenFeeKillswitch[ideaToken]).total;
    }

    /**
     * Calculates each cost related to buying tokens
     *
     * @param marketDetails The market details
     * @param supply The existing supply of the IdeaToken
     * @param amount The amount of IdeaTokens to buy
     *
     * @return total cost, raw cost, trading fee, platform fee
     */
    function getCostsForBuyingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) public pure override returns (CostAndPriceAmounts memory) {
        uint rawCost = getRawCostForBuyingTokens(marketDetails.baseCost,
                                                 marketDetails.priceRise,
                                                 marketDetails.hatchTokens,
                                                 supply,
                                                 amount);

        uint tradingFee = 0;
        uint platformFee = 0;

        if(!feesDisabled) {
            tradingFee = rawCost.mul(marketDetails.tradingFeeRate).div(FEE_SCALE);
            platformFee = rawCost.mul(marketDetails.platformFeeRate).div(FEE_SCALE);
        }
        
        uint totalCost = rawCost.add(tradingFee).add(platformFee);

        return CostAndPriceAmounts({
            total: totalCost,
            raw: rawCost,
            tradingFee: tradingFee,
            platformFee: platformFee
        });
    }

    /**
     * Returns the cost for buying tokens without any fees applied
     *
     * @param baseCost The baseCost of the token
     * @param priceRise The priceRise of the token
     * @param hatchTokens The amount of hatch tokens
     * @param supply The current total supply of the token
     * @param amount The amount of IdeaTokens to buy
     *
     * @return The cost buying `amount` IdeaTokens without any fees applied
     */
    function getRawCostForBuyingTokens(uint baseCost, uint priceRise, uint hatchTokens, uint supply, uint amount) internal pure returns (uint) {

        uint hatchCost = 0;
        uint updatedAmount = amount;
        uint updatedSupply;

        if(supply < hatchTokens) {
            // No SafeMath required because supply < hatchTokens
            uint remainingHatchTokens = hatchTokens - supply;

            if(amount <= remainingHatchTokens) {
                return baseCost.mul(amount).div(10**18);
            }

            hatchCost = baseCost.mul(remainingHatchTokens).div(10**18);
            updatedSupply = 0;
            // No SafeMath required because remainingHatchTokens < amount
            updatedAmount = amount - remainingHatchTokens;
        } else {
            // No SafeMath required because supply >= hatchTokens
            updatedSupply = supply - hatchTokens;
        }

        uint priceAtSupply = baseCost.add(priceRise.mul(updatedSupply).div(10**18));
        uint priceAtSupplyPlusAmount = baseCost.add(priceRise.mul(updatedSupply.add(updatedAmount)).div(10**18));
        uint average = priceAtSupply.add(priceAtSupplyPlusAmount).div(2);

        return hatchCost.add(average.mul(updatedAmount).div(10**18));
    }

    /**
     * Withdraws available interest for a publisher
     *
     * @param token The token from which the generated interest is to be withdrawn
     */
    function withdrawTokenInterest(address token) external override {
        require(_tokenOwner[token] == msg.sender, "not-authorized");
        _interestManager.accrueInterest();

        uint interestPayable = getInterestPayable(token);
        if(interestPayable == 0) {
            return;
        }

        ExchangeInfo storage exchangeInfo = _tokensExchangeInfo[token];
        exchangeInfo.invested = exchangeInfo.invested.sub(_interestManager.redeem(msg.sender, interestPayable));

        emit TokenInterestRedeemed(token, exchangeInfo.invested, interestPayable);
    }

    /**
     * Returns the interest available to be paid out for a token
     *
     * @param token The token from which the generated interest is to be withdrawn
     *
     * @return The interest available to be paid out
     */
    function getInterestPayable(address token) public view override returns (uint) {
        ExchangeInfo storage exchangeInfo = _tokensExchangeInfo[token];
        return _interestManager.investmentTokenToUnderlying(exchangeInfo.invested).sub(exchangeInfo.dai);
    }

    /**
     * Sets an address as owner of a token, allowing the address to withdraw interest
     *
     * @param token The token for which to authorize an address
     * @param owner The address to be set as owner
     */
    function setTokenOwner(address token, address owner) external override {
        address sender = msg.sender;
        address current = _tokenOwner[token];

        require((current == address(0) && (sender == _owner || sender == _authorizer)) ||
                (current != address(0) && (sender == _owner || sender == current)),
                "not-authorized");

        _tokenOwner[token] = owner;

        emit NewTokenOwner(token, owner);
    }

    /**
     * Withdraws available interest for a platform
     *
     * @param marketID The market id from which the generated interest is to be withdrawn
     */
    function withdrawPlatformInterest(uint marketID) external override {
        address sender = msg.sender;

        require(_platformOwner[marketID] == sender, "not-authorized");
        _interestManager.accrueInterest();

        uint platformInterestPayable = getPlatformInterestPayable(marketID);
        if(platformInterestPayable == 0) {
            return;
        }

        ExchangeInfo storage exchangeInfo = _platformsExchangeInfo[marketID];
        exchangeInfo.invested = exchangeInfo.invested.sub(_interestManager.redeem(sender, platformInterestPayable));

        emit PlatformInterestRedeemed(marketID, exchangeInfo.invested, platformInterestPayable);
    }

    /**
     * Returns the interest available to be paid out for a platform
     *
     * @param marketID The market id from which the generated interest is to be withdrawn
     *
     * @return The interest available to be paid out
     */
    function getPlatformInterestPayable(uint marketID) public view override returns (uint) {
        ExchangeInfo storage exchangeInfo = _platformsExchangeInfo[marketID];
        return _interestManager.investmentTokenToUnderlying(exchangeInfo.invested).sub(exchangeInfo.dai);
    }

    /**
     * Withdraws available platform fee
     *
     * @param marketID The market from which the generated platform fee is to be withdrawn
     */
    function withdrawPlatformFee(uint marketID) external override {
        address sender = msg.sender;
    
        require(_platformOwner[marketID] == sender, "not-authorized");
        _interestManager.accrueInterest();

        uint platformFeePayable = getPlatformFeePayable(marketID);
        if(platformFeePayable == 0) {
            return;
        }

        _platformFeeInvested[marketID] = 0;
        _interestManager.redeem(sender, platformFeePayable);

        emit PlatformFeeRedeemed(marketID, platformFeePayable);
    }

    /**
     * Returns the platform fee available to be paid out
     *
     * @param marketID The market from which the generated interest is to be withdrawn
     *
     * @return The platform fee available to be paid out
     */
    function getPlatformFeePayable(uint marketID) public view override returns (uint) {
        return _interestManager.investmentTokenToUnderlying(_platformFeeInvested[marketID]);
    }

    /**
     * Authorizes an address as owner of a platform/market, which is allowed to withdraw platform fee and platform interest
     *
     * @param marketID The market for which to authorize an address
     * @param owner The address to be authorized
     */
    function setPlatformOwner(uint marketID, address owner) external override {
        address sender = msg.sender;
        address current = _platformOwner[marketID];

        require((current == address(0) && (sender == _owner || sender == _authorizer)) ||
                (current != address(0) && (sender == _owner || sender == current)),
                "not-authorized");
        
        _platformOwner[marketID] = owner;

        emit NewPlatformOwner(marketID, owner);
    }

    /**
     * Withdraws available trading fee
     */
    function withdrawTradingFee() external override {

        uint invested = _tradingFeeInvested;
        if(invested == 0) {
            return;
        }

        _interestManager.accrueInterest();

        _tradingFeeInvested = 0;
        uint redeem = _interestManager.investmentTokenToUnderlying(invested);
        _interestManager.redeem(_tradingFeeRecipient, redeem);

        emit TradingFeeRedeemed(redeem);
    }

    /**
     * Returns the trading fee available to be paid out
     *
     * @return The trading fee available to be paid out
     */
    function getTradingFeePayable() public view override returns (uint) {
        return _interestManager.investmentTokenToUnderlying(_tradingFeeInvested);
    }

    /**
     * Sets the authorizer address
     *
     * @param authorizer The new authorizer address
     */
    function setAuthorizer(address authorizer) external override onlyOwner {
        require(authorizer != address(0), "invalid-params");
        _authorizer = authorizer;
    }

    /**
     * Returns whether or not fees are disabled for a specific IdeaToken
     *
     * @param ideaToken The IdeaToken
     *
     * @return Whether or not fees are disabled for a specific IdeaToken
     */
    function isTokenFeeDisabled(address ideaToken) external view override returns (bool) {
        return _tokenFeeKillswitch[ideaToken];
    }

    /**
     * Sets the fee killswitch for an IdeaToken
     *
     * @param ideaToken The IdeaToken
     * @param set Whether or not to enable the killswitch
     */
    function setTokenFeeKillswitch(address ideaToken, bool set) external override onlyOwner {
        _tokenFeeKillswitch[ideaToken] = set;
    }

    /**
     * Sets the IdeaTokenFactory address. Only required once for deployment
     *
     * @param factory The address of the IdeaTokenFactory 
     */
    function setIdeaTokenFactoryAddress(address factory) external onlyOwner {
        require(address(_ideaTokenFactory) == address(0));
        _ideaTokenFactory = IIdeaTokenFactory(factory);
    }
}