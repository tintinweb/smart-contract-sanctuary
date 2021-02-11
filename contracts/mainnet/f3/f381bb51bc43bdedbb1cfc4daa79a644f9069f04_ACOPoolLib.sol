pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IACOPoolStrategy.sol";
import "./IACOFactory.sol";
import "./IACOToken.sol";
import "./ILendingPool.sol";

library ACOPoolLib {
	using SafeMath for uint256;
	
	struct OpenPositionData {
        uint256 underlyingPrice;
        uint256 baseVolatility;
        uint256 underlyingPriceAdjustPercentage;
        uint256 fee;
        uint256 underlyingPrecision;
        address strategy;
        address acoFactory;
	    address acoToken;
	}
	
	struct QuoteData {
		bool isCall;
        uint256 tokenAmount; 
		address underlying;
		address strikeAsset;
		uint256 strikePrice; 
		uint256 expiryTime;
		address lendingToken;
		address strategy;
		uint256 baseVolatility;
		uint256 fee;
		uint256 minExpiration;
		uint256 maxExpiration;
		uint256 tolerancePriceBelow;
		uint256 tolerancePriceAbove;
		uint256 underlyingPrice;
		uint256 underlyingPrecision;
	}
	
	struct OpenPositionExtraData {
        bool isCall;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 tokenAmount;
	    address underlying;
        address strikeAsset; 
	}
	
	uint256 public constant PERCENTAGE_PRECISION = 100000;
	
	function name(address underlying, address strikeAsset, bool isCall) public view returns(string memory) {
        return string(abi.encodePacked(
            "ACO POOL WRITE ",
            _getAssetSymbol(underlying),
            "-",
            _getAssetSymbol(strikeAsset),
            "-",
            (isCall ? "CALL" : "PUT")
        ));
    }
    
	function acoStrikePriceIsValid(
		uint256 tolerancePriceBelow,
		uint256 tolerancePriceAbove,
		uint256 strikePrice, 
		uint256 price
	) public pure returns(bool) {
		return (tolerancePriceBelow == 0 && tolerancePriceAbove == 0) ||
			(tolerancePriceBelow == 0 && strikePrice > price.mul(PERCENTAGE_PRECISION.add(tolerancePriceAbove)).div(PERCENTAGE_PRECISION)) ||
			(tolerancePriceAbove == 0 && strikePrice < price.mul(PERCENTAGE_PRECISION.sub(tolerancePriceBelow)).div(PERCENTAGE_PRECISION)) ||
			(strikePrice >= price.mul(PERCENTAGE_PRECISION.sub(tolerancePriceBelow)).div(PERCENTAGE_PRECISION) && 
			 strikePrice <= price.mul(PERCENTAGE_PRECISION.add(tolerancePriceAbove)).div(PERCENTAGE_PRECISION));
	}

	function acoExpirationIsValid(uint256 acoExpiryTime, uint256 minExpiration, uint256 maxExpiration) public view returns(bool) {
		return acoExpiryTime >= block.timestamp.add(minExpiration) && acoExpiryTime <= block.timestamp.add(maxExpiration);
	}

    function getBaseAssetsWithdrawWithLocked(
        uint256 shares,
        address underlying,
        address strikeAsset,
        bool isCall,
        uint256 totalSupply,
        address lendingToken
    ) public view returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn
    ) {
		uint256 underlyingBalance = _getPoolBalanceOf(underlying);
		uint256 strikeAssetBalance;
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
		}
		
		underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
    }
    
    function getBaseWithdrawNoLockedData(
        uint256 shares,
        uint256 totalSupply,
        bool isCall,
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance, 
        uint256 collateralLockedRedeemable
    ) public pure returns(
        uint256 underlyingWithdrawn,
		uint256 strikeAssetWithdrawn,
		bool isPossible
    ) {
		uint256 collateralAmount = shares.mul(collateralBalance).div(totalSupply);
		
		if (isCall) {
			underlyingWithdrawn = collateralAmount;
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
			isPossible = (collateralAmount <= underlyingBalance.add(collateralLockedRedeemable));
		} else {
			strikeAssetWithdrawn = collateralAmount;
			underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
			isPossible = (collateralAmount <= strikeAssetBalance.add(collateralLockedRedeemable));
		}
    }
    
    function getAmountToLockedWithdraw(
        uint256 shares, 
        uint256 totalSupply, 
        address lendingToken,
        address underlying, 
        address strikeAsset, 
        bool isCall
    ) public view returns(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn
    ) {
		uint256 underlyingBalance = _getPoolBalanceOf(underlying);
		uint256 strikeAssetBalance;
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
		}
		
		underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
    }
    
    function getAmountToNoLockedWithdraw(
        uint256 shares, 
        uint256 totalSupply,
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance,
        uint256 collateralBalance,
        uint256 minCollateral,
        bool isCall
    ) public pure returns(
        uint256 underlyingWithdrawn, 
        uint256 strikeAssetWithdrawn
    ) {
		uint256 collateralAmount = shares.mul(collateralBalance).div(totalSupply);
		require(collateralAmount >= minCollateral, "ACOPoolLib: The minimum collateral was not satisfied");

        if (isCall) {
			require(collateralAmount <= underlyingBalance, "ACOPoolLib: Collateral balance is not sufficient");
			underlyingWithdrawn = collateralAmount;
			strikeAssetWithdrawn = strikeAssetBalance.mul(shares).div(totalSupply);
        } else {
			require(collateralAmount <= strikeAssetBalance, "ACOPoolLib: Collateral balance is not sufficient");
			strikeAssetWithdrawn = collateralAmount;
			underlyingWithdrawn = underlyingBalance.mul(shares).div(totalSupply);
		}
    }
    
	function getBaseCollateralData(
	    address lendingToken,
	    address underlying,
	    address strikeAsset,
	    bool isCall,
	    uint256 underlyingPrice,
	    uint256 underlyingPriceAdjustPercentage,
	    uint256 underlyingPrecision,
	    bool isDeposit
    ) public view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance
    ) {
		underlyingBalance = _getPoolBalanceOf(underlying);
		
		if (isCall) {
		    strikeAssetBalance = _getPoolBalanceOf(strikeAsset);
			collateralBalance = underlyingBalance;
			if (isDeposit && strikeAssetBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, underlyingPriceAdjustPercentage, false); 
				collateralBalance = collateralBalance.add(strikeAssetBalance.mul(underlyingPrecision).div(priceAdjusted));
			}
		} else {
		    strikeAssetBalance = _getPoolBalanceOf(lendingToken);
			collateralBalance = strikeAssetBalance;
			if (isDeposit && underlyingBalance > 0) {
				uint256 priceAdjusted = _getUnderlyingPriceAdjusted(underlyingPrice, underlyingPriceAdjustPercentage, true); 
				collateralBalance = collateralBalance.add(underlyingBalance.mul(priceAdjusted).div(underlyingPrecision));
			}
		}
	}
	
	function getOpenPositionCollateralBalance(OpenPositionData memory data) public view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        OpenPositionExtraData memory extraData = _getOpenPositionCollateralExtraData(data.acoToken, data.acoFactory);
        (collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _getOpenPositionCollateralBalance(data, extraData);
    }
    
    function quote(QuoteData memory data) public view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        require(data.expiryTime > block.timestamp, "ACOPoolLib: ACO token expired");
        require(acoExpirationIsValid(data.expiryTime, data.minExpiration, data.maxExpiration), "ACOPoolLib: Invalid ACO token expiration");
		require(acoStrikePriceIsValid(data.tolerancePriceBelow, data.tolerancePriceAbove, data.strikePrice, data.underlyingPrice), "ACOPoolLib: Invalid ACO token strike price");

        uint256 collateralAvailable;
        (collateralAmount, collateralAvailable) = _getOrderSizeData(data.tokenAmount, data.underlying, data.isCall, data.strikePrice, data.lendingToken, data.underlyingPrecision);
        uint256 calcPrice;
        (calcPrice, volatility) = _strategyQuote(data.strategy, data.underlying, data.strikeAsset, data.isCall, data.strikePrice, data.expiryTime, data.underlyingPrice, data.baseVolatility, collateralAmount, collateralAvailable);
        (swapPrice, protocolFee) = _setSwapPriceAndFee(calcPrice, data.tokenAmount, data.fee, data.underlyingPrecision);
    }
    
    
    function _getCollateralAmount(
		uint256 tokenAmount,
		uint256 strikePrice,
		bool isCall,
		uint256 underlyingPrecision
	) private pure returns(uint256) {
        if (isCall) {
            return tokenAmount;
        } else if (tokenAmount > 0) {
            return tokenAmount.mul(strikePrice).div(underlyingPrecision);
        } else {
            return 0;
        }
    }
    
    function _getOrderSizeData(
        uint256 tokenAmount,
        address underlying,
        bool isCall,
        uint256 strikePrice,
        address lendingToken,
        uint256 underlyingPrecision
    ) private view returns(
        uint256 collateralAmount, 
        uint256 collateralAvailable
    ) {
        if (isCall) {
            collateralAvailable = _getPoolBalanceOf(underlying);
            collateralAmount = tokenAmount; 
        } else {
            collateralAvailable = _getPoolBalanceOf(lendingToken);
            collateralAmount = _getCollateralAmount(tokenAmount, strikePrice, isCall, underlyingPrecision);
            require(collateralAmount > 0, "ACOPoolLib: The token amount is too small");
        }
        require(collateralAmount <= collateralAvailable, "ACOPoolLib: Insufficient liquidity");
    }
    
	function _strategyQuote(
        address strategy,
		address underlying,
		address strikeAsset,
		bool isCall,
		uint256 strikePrice,
        uint256 expiryTime,
        uint256 underlyingPrice,
		uint256 baseVolatility,
        uint256 collateralAmount,
        uint256 collateralAvailable
    ) private view returns(uint256 swapPrice, uint256 volatility) {
        (swapPrice, volatility) = IACOPoolStrategy(strategy).quote(IACOPoolStrategy.OptionQuote(
			underlyingPrice,
            underlying, 
            strikeAsset, 
            isCall, 
            strikePrice, 
            expiryTime, 
            baseVolatility, 
            collateralAmount, 
            collateralAvailable
        ));
    }
    
    function _setSwapPriceAndFee(
        uint256 calcPrice, 
        uint256 tokenAmount, 
        uint256 fee,
        uint256 underlyingPrecision
    ) private pure returns(uint256 swapPrice, uint256 protocolFee) {
        
        swapPrice = calcPrice.mul(tokenAmount).div(underlyingPrecision);
        
        if (fee > 0) {
            protocolFee = swapPrice.mul(fee).div(PERCENTAGE_PRECISION);
			swapPrice = swapPrice.add(protocolFee);
        }
        require(swapPrice > 0, "ACOPoolLib: Invalid quoted price");
    }
    
    function _getOpenPositionCollateralExtraData(address acoToken, address acoFactory) private view returns(OpenPositionExtraData memory extraData) {
        (address underlying, address strikeAsset, bool isCall, uint256 strikePrice, uint256 expiryTime) = IACOFactory(acoFactory).acoTokenData(acoToken);
        uint256 tokenAmount = IACOToken(acoToken).currentCollateralizedTokens(address(this));
        extraData = OpenPositionExtraData(isCall, strikePrice, expiryTime, tokenAmount, underlying, strikeAsset);
    }
    
	function _getOpenPositionCollateralBalance(
		OpenPositionData memory data,
		OpenPositionExtraData memory extraData
	) private view returns(
	    uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        collateralLocked = _getCollateralAmount(extraData.tokenAmount, extraData.strikePrice, extraData.isCall, data.underlyingPrecision);
        
        if (extraData.expiryTime > block.timestamp) {
    		(uint256 price,) = _strategyQuote(data.strategy, extraData.underlying, extraData.strikeAsset, extraData.isCall, extraData.strikePrice, extraData.expiryTime, data.underlyingPrice, data.baseVolatility, 0, 1);
    		if (data.fee > 0) {
    		    price = price.mul(PERCENTAGE_PRECISION.add(data.fee)).div(PERCENTAGE_PRECISION);
    		}
    		if (extraData.isCall) {
    			uint256 priceAdjusted = _getUnderlyingPriceAdjusted(data.underlyingPrice, data.underlyingPriceAdjustPercentage, false); 
    			collateralOnOpenPosition = price.mul(extraData.tokenAmount).div(priceAdjusted);
    		} else {
    			collateralOnOpenPosition = price.mul(extraData.tokenAmount).div(data.underlyingPrecision);
    		}
        } else {
            collateralLockedRedeemable = collateralLocked;
        }
	}
	
	function _getUnderlyingPriceAdjusted(uint256 underlyingPrice, uint256 underlyingPriceAdjustPercentage, bool isMaximum) private pure returns(uint256) {
		if (isMaximum) {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.add(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		} else {
			return underlyingPrice.mul(PERCENTAGE_PRECISION.sub(underlyingPriceAdjustPercentage)).div(PERCENTAGE_PRECISION);
		}
    }
    
    function _getPoolBalanceOf(address asset) private view returns(uint256) {
        if (asset == address(0)) {
            return address(this).balance;
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
            require(success, "ACOPoolLib::_getAssetBalanceOf");
            return abi.decode(returndata, (uint256));
        }
    }
    
    function _getAssetSymbol(address asset) private view returns(string memory) {
        if (asset == address(0)) {
            return "ETH";
        } else {
            (bool success, bytes memory returndata) = asset.staticcall(abi.encodeWithSelector(0x95d89b41));
            require(success, "ACOPoolLib::_getAssetSymbol");
            return abi.decode(returndata, (string));
        }
    }
}