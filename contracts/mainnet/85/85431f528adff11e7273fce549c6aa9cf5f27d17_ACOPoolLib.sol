pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IACOPoolStrategy.sol";
import "./IACOFactory.sol";
import "./IACOToken.sol";
import "./ILendingPool.sol";
import "./IACOPool2.sol";

library ACOPoolLib {
	using SafeMath for uint256;
	
	struct OpenPositionData {
	    bool isDeposit;
	    bool isCall;
	    uint256 underlyingPrice;
	    uint256 baseVolatility;
	    uint256 underlyingPriceAdjustPercentage;
	    uint256 withdrawOpenPositionPenalty;
	    uint256 fee;
	    uint256 underlyingPrecision;
	    address underlying;
	    address strikeAsset;
	    address strategy;
	    address acoFactory;
	    address lendingToken;
	}
	
	struct QuoteData {
		address lendingToken;
		address strategy;
		uint256 baseVolatility;
		uint256 fee;
		uint256 underlyingPrice;
		uint256 underlyingPrecision;
		AcoData acoData;
		IACOPool2.PoolAcoPermissionConfigV2 acoPermissionConfig;
	}
	
	struct AcoData {
        bool isCall;
        uint256 strikePrice; 
        uint256 expiryTime;
        uint256 tokenAmount;
	    address underlying;
        address strikeAsset; 
	}
	
	uint256 public constant PERCENTAGE_PRECISION = 100000;
	
	function name(
        address underlying, 
        address strikeAsset, 
        bool isCall, 
        uint256 poolId
    ) public view returns(string memory) {
        return string(abi.encodePacked(
            "ACO POOL WRITE ",
            _getAssetSymbol(underlying),
            "-",
            _getAssetSymbol(strikeAsset),
            "-",
            (isCall ? "CALL #" : "PUT #"),
            _formatNumber(poolId)
        ));
    }
    
    function acoStrikeAndExpirationIsValid(
		uint256 strikePrice, 
        uint256 acoExpiryTime, 
		uint256 underlyingPrice,
        IACOPool2.PoolAcoPermissionConfigV2 memory acoPermissionConfig
    ) public view returns(bool) {
        return _acoExpirationIsValid(acoExpiryTime, acoPermissionConfig) && _acoStrikePriceIsValid(strikePrice, underlyingPrice, acoPermissionConfig);
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
    
    function quote(QuoteData memory data) public view returns(
        uint256 swapPrice, 
        uint256 protocolFee, 
        uint256 volatility, 
        uint256 collateralAmount
    ) {
        AcoData memory acoData = data.acoData;
        require(_acoExpirationIsValid(acoData.expiryTime, data.acoPermissionConfig), "ACOPoolLib: Invalid ACO token expiration");
		require(_acoStrikePriceIsValid(acoData.strikePrice, data.underlyingPrice, data.acoPermissionConfig), "ACOPoolLib: Invalid ACO token strike price");

        uint256 collateralAvailable;
        (collateralAmount, collateralAvailable) = _getOrderSizeData(data.lendingToken, data.underlyingPrecision, acoData);
        uint256 calcPrice;
        (calcPrice, volatility) = _strategyQuote(data.strategy, data.underlyingPrice, data.baseVolatility, collateralAmount, collateralAvailable, acoData);
        (swapPrice, protocolFee) = _setSwapPriceAndFee(calcPrice, acoData.tokenAmount, data.fee, data.underlyingPrecision);
    }

	function getCollateralData(OpenPositionData memory data, address[] memory openAcos) public view returns(
        uint256 underlyingBalance, 
        uint256 strikeAssetBalance, 
        uint256 collateralBalance,
        uint256 collateralLocked,
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		(underlyingBalance, strikeAssetBalance, collateralBalance) = _getBaseCollateralData(
            data.isDeposit, 
            data.underlying,
            data.strikeAsset,
            data.isCall,
            data.underlyingPrice,
            data.lendingToken,
            data.underlyingPriceAdjustPercentage,
            data.underlyingPrecision);
            
		(collateralLocked, collateralOnOpenPosition, collateralLockedRedeemable) = _poolOpenPositionCollateralBalance(data, openAcos);
	}

    function _formatNumber(uint256 value) internal pure returns(string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 digits;
        uint256 temp = value;
        while (temp != 0) {
            temp /= 10;
            digits++;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        for (uint256 i = 0; i < digits; ++i) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
	
	function _getBaseCollateralData(
	    bool isDeposit,
	    address underlying,
	    address strikeAsset,
	    bool isCall,
	    uint256 underlyingPrice,
	    address lendingToken,
	    uint256 underlyingPriceAdjustPercentage,
	    uint256 underlyingPrecision
	) internal view returns(
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

	function _poolOpenPositionCollateralBalance(OpenPositionData memory data, address[] memory openAcos) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
		for (uint256 i = 0; i < openAcos.length; ++i) {
			address acoToken = openAcos[i];
            
            (uint256 locked, uint256 openPosition, uint256 lockedRedeemable) = _getOpenPositionCollateralBalance(acoToken, data);
            
            collateralLocked = collateralLocked.add(locked);
            collateralOnOpenPosition = collateralOnOpenPosition.add(openPosition);
            collateralLockedRedeemable = collateralLockedRedeemable.add(lockedRedeemable);
		}
		if (!data.isDeposit) {
			collateralOnOpenPosition = collateralOnOpenPosition.mul(PERCENTAGE_PRECISION.add(data.withdrawOpenPositionPenalty)).div(PERCENTAGE_PRECISION);
		}
	}
	
	function _getOpenPositionCollateralBalance(address acoToken, OpenPositionData memory data) internal view returns(
        uint256 collateralLocked, 
        uint256 collateralOnOpenPosition,
        uint256 collateralLockedRedeemable
    ) {
        AcoData memory acoData = _getOpenPositionCollateralExtraData(acoToken, data.acoFactory);
        collateralLocked = _getCollateralAmount(acoData.tokenAmount, acoData.strikePrice, acoData.isCall, data.underlyingPrecision);
        
        if (acoData.expiryTime > block.timestamp) {
    		(uint256 price,) = _strategyQuote(data.strategy, data.underlyingPrice, data.baseVolatility, 0, 1, acoData);
    		if (data.fee > 0) {
    		    price = price.mul(PERCENTAGE_PRECISION.add(data.fee)).div(PERCENTAGE_PRECISION);
    		}
    		if (acoData.isCall) {
    			uint256 priceAdjusted = _getUnderlyingPriceAdjusted(data.underlyingPrice, data.underlyingPriceAdjustPercentage, false); 
    			collateralOnOpenPosition = price.mul(acoData.tokenAmount).div(priceAdjusted);
    		} else {
    			collateralOnOpenPosition = price.mul(acoData.tokenAmount).div(data.underlyingPrecision);
    		}
        } else {
            collateralLockedRedeemable = collateralLocked;
        }
    }
    
	function _acoStrikePriceIsValid(
		uint256 strikePrice, 
		uint256 underlyingPrice,
		IACOPool2.PoolAcoPermissionConfigV2 memory acoPermissionConfig
	) internal pure returns(bool) {
	    return (
	        _validatePricePercentageTolerance(strikePrice, underlyingPrice, acoPermissionConfig.tolerancePriceBelowMin, false, true) &&
	        _validatePricePercentageTolerance(strikePrice, underlyingPrice, acoPermissionConfig.tolerancePriceBelowMax, false, false) &&
	        _validatePricePercentageTolerance(strikePrice, underlyingPrice, acoPermissionConfig.tolerancePriceAboveMin, true, false) &&
	        _validatePricePercentageTolerance(strikePrice, underlyingPrice, acoPermissionConfig.tolerancePriceAboveMax, true, true) &&
	        (acoPermissionConfig.minStrikePrice <= strikePrice) &&
	        (acoPermissionConfig.maxStrikePrice == 0 || acoPermissionConfig.maxStrikePrice >= strikePrice)
        );
	}
	
	function _validatePricePercentageTolerance(
	    uint256 strikePrice, 
	    uint256 underlyingPrice, 
	    int256 tolerance, 
	    bool isAbove,
	    bool shouldBeLesser
    ) internal pure returns(bool) {
        if (tolerance < int256(0)) {
            return true;
        } else {
            uint256 value;
            if (isAbove) {
                value = underlyingPrice.mul(PERCENTAGE_PRECISION.add(uint256(tolerance))).div(PERCENTAGE_PRECISION);
            } else {
                value = underlyingPrice.mul(PERCENTAGE_PRECISION.sub(uint256(tolerance))).div(PERCENTAGE_PRECISION);
            }
            if (shouldBeLesser) {
                return strikePrice <= value;
            } else {
                return strikePrice >= value;
            }
        }
    }

	function _acoExpirationIsValid(uint256 acoExpiryTime, IACOPool2.PoolAcoPermissionConfigV2 memory acoPermissionConfig) internal view returns(bool) {
		return acoExpiryTime >= block.timestamp.add(acoPermissionConfig.minExpiration) && acoExpiryTime <= block.timestamp.add(acoPermissionConfig.maxExpiration);
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
        address lendingToken,
        uint256 underlyingPrecision,
        AcoData memory acoData
    ) private view returns(
        uint256 collateralAmount, 
        uint256 collateralAvailable
    ) {
        if (acoData.isCall) {
            collateralAvailable = _getPoolBalanceOf(acoData.underlying);
            collateralAmount = acoData.tokenAmount; 
        } else {
            collateralAvailable = _getPoolBalanceOf(lendingToken);
            collateralAmount = _getCollateralAmount(acoData.tokenAmount, acoData.strikePrice, acoData.isCall, underlyingPrecision);
            require(collateralAmount > 0, "ACOPoolLib: The token amount is too small");
        }
        require(collateralAmount <= collateralAvailable, "ACOPoolLib: Insufficient liquidity");
    }
    
	function _strategyQuote(
        address strategy,
        uint256 underlyingPrice,
		uint256 baseVolatility,
        uint256 collateralAmount,
        uint256 collateralAvailable,
        AcoData memory acoData
    ) private view returns(uint256 swapPrice, uint256 volatility) {
        (swapPrice, volatility) = IACOPoolStrategy(strategy).quote(IACOPoolStrategy.OptionQuote(
			underlyingPrice,
            acoData.underlying, 
            acoData.strikeAsset, 
            acoData.isCall, 
            acoData.strikePrice, 
            acoData.expiryTime, 
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
    
    function _getOpenPositionCollateralExtraData(address acoToken, address acoFactory) private view returns(AcoData memory acoData) {
        (address underlying, address strikeAsset, bool isCall, uint256 strikePrice, uint256 expiryTime) = IACOFactory(acoFactory).acoTokenData(acoToken);
        uint256 tokenAmount = IACOToken(acoToken).currentCollateralizedTokens(address(this));
        acoData = AcoData(isCall, strikePrice, expiryTime, tokenAmount, underlying, strikeAsset);
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