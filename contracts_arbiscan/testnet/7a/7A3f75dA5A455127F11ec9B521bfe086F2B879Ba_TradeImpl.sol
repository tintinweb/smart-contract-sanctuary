pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";

import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";
import { IStakeble } from "../interface/IStakeble.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { PnlLib } from "../lib/Pnl.sol";

library TradeImpl {
    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;

    //against stack too deep error
    struct PositionParams {
        IMarket _market;
        address _account;
        int256 _collateral;
        int256 _leverage;
        bool _isLong;
        int256 _slippage;
    }

    struct TraderUpdate{
        int256 _notional;
        int256 _initialPrice;
        int256 _fundingPaid;
        bool _isActive;
        bool _isLong;
    }

    struct PosInfo{
        int256 _notional;
        int256 _collateral;
        int256 _unrealizedPnl;
        int256 _priceBeforeChange;
    }

    function openPosition(
        StorageStripsLib.State storage state,
        PositionParams memory posParams
    ) public {        
        require(posParams._collateral > 0, "COLLATERAL_LEQ_0");

        StorageStripsLib.Position storage prevPosition = state.checkPosition(posParams._market, posParams._account);
        
        require(prevPosition.lastChangeBlock != block.number, "SAME_BLOCK_ACTION_DENIED");

        int256 slippage = 0;
        int256 rewardedNotional = posParams._collateral * posParams._leverage;

        if (prevPosition.isActive == false){
            //There is no active position - just open new
           slippage = _open(state,
                                posParams,
                                false);  //not merge
        }else{
            if (posParams._isLong != prevPosition.isLong){    // opposite?
                
                //check if it's opposite close
                int256 notional = posParams._collateral * posParams._leverage;
                if (notional == prevPosition.notional){     // the same but opposite, just close current
                    slippage = _liquidateWholeOrCloseRatio(state,
                                                prevPosition,
                                                posParams._market,
                                                SignedBaseMath.oneDecimal());
                }else{  //netting
                    slippage = _netPosition(state,
                        posParams,
                        prevPosition
                    );

                }
            }else{  //the same side, it's aggregation
                slippage = _aggregate(state, 
                            posParams,
                            prevPosition);
            }
        }
        _requireSlippage(posParams._slippage, slippage);

        if (IStakeble(address(posParams._market)).isRewardable()){
            address rewarder = IRewardable(address(posParams._market)).getRewarder();
            IRewarder(rewarder).rewardTrader(posParams._account, rewardedNotional);
        }
    }



    function closePosition(
        StorageStripsLib.State storage state,
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) public {
        require(_closeRatio > 0 && _closeRatio <= SignedBaseMath.oneDecimal(), "WRONG_CLOSE_RATIO");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);
        
        int256 notional = position.notional;
        require(position.lastChangeBlock != block.number, "SAME_BLOCK_ACTION_DENIED");

        //ALWAYS check the full position first
        _requireMargin(state, 
                position, 
                _market,
                SignedBaseMath.oneDecimal());

        if (_closeRatio != SignedBaseMath.oneDecimal()){
            notional = notional.muld(_closeRatio);
        }

        int256 slippage = _close(state,
                                position,
                                _market,
                                _closeRatio);

        _requireSlippage(_slippage, slippage);
        if (IStakeble(address(_market)).isRewardable()){
            address rewarder = IRewardable(address(_market)).getRewarder();
            IRewarder(rewarder).rewardTrader(msg.sender, notional);
        }

        if (position.isActive){
            _requireMargin(state, 
                    position, 
                    _market,
                    SignedBaseMath.oneDecimal());
        }
    }


    function liquidatePosition(
        StorageStripsLib.State storage state,
        IMarket _market,
        address account
    ) public {
        //trader can't liquidate it's own position
        require(account != msg.sender, "TRADER_CANTBE_LIQUIDATOR");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        account);


        (int256 total_pnl,
         int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    position,
                                                    SignedBaseMath.oneDecimal(),          // you can't partly close if full position is for liquidation
                                                    false);  // based on Exit price
                
        require(marginRatio <= state.getLiquidationRatio(), "MARGIN_OK");
        

        _liquidate(state,
                    _market,
                    msg.sender,
                    position);
    }


    function addCollateral(
        StorageStripsLib.State storage state,
        IMarket _market, 
        int256 collateral
    ) internal {
        require(collateral > 0, "COLLATERAL_LT_0");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);

                //Get collateral on STRIPS balance
        _receiveCollateral(state,
                            msg.sender, 
                            collateral);

        state.addCollateral(position,
                            collateral);

        _requireMargin(state,
                        position,
                        _market,
                        SignedBaseMath.oneDecimal());
    }

    function removeCollateral(
        StorageStripsLib.State storage state,
        IMarket _market, 
        int256 collateral
    ) internal {
        require(collateral > 0, "COLLATERAL_LT_0");

        StorageStripsLib.Position storage position = state.getPosition(_market,
                                                                        msg.sender);

        require(collateral < position.collateral, "CANT_REMOVE_ALL");

        state.removeCollateral(position, 
                                collateral);

        _returnCollateral(state,
                            msg.sender, 
                            collateral);
        
        _requireMargin(state,
                        position,
                        _market,
                        SignedBaseMath.oneDecimal());

    }

    /*
    **************************************************************************
    *   Different netting AMM scenarios and Unrealized PNL
     **************************************************************************
    */

    function ammPositionUpdate(
        StorageStripsLib.State storage state,
        IMarket _market,
        TraderUpdate memory _traderUpdate
    ) private {
        StorageStripsLib.Position storage ammPosition = state.checkPosition(_market, address(_market));

        if (ammPosition.isActive == false){
            if (_traderUpdate._isActive == false){
                //trader closed the position, and we didn't have amm position
                return; // do nothing
            }
            bool traderRevertedSide = !_traderUpdate._isLong; //here for not too deep stack error

            //it's the new position, just open
            state.setPosition(
                _market, 
                address(_market), 
                traderRevertedSide,  //revert position 
                0,                      // for amm we don't have collateral 
                _traderUpdate._notional, 
                _traderUpdate._initialPrice, 
                false);
        }else{
            _ammCummulateFundingPnl(state, 
                                    ammPosition,
                                    _market);

            int256 ammNotional = ammPosition.notional;
            int256 ammUpdatedNotional = ammNotional;
            
            bool ammSide = ammPosition.isLong;
            bool newSide = ammSide;

            bool traderRevertedSide = !_traderUpdate._isLong; //here for not too deep stack error

            int256 closeNotional = _traderUpdate._notional;
            if (_traderUpdate._isActive == false){
                closeNotional *= -1;
            }

            //Trader open/change position
            if (ammSide == traderRevertedSide){
                //the same side
                ammUpdatedNotional += closeNotional;
                if (ammUpdatedNotional < 0){
                    ammUpdatedNotional *= -1;
                    newSide = !ammSide;
                }
            }else{
                int256 diff = ammNotional - closeNotional;        
            
                if (diff >= 0){
                    //the same side
                    ammUpdatedNotional = diff;
                } else {
                    //change side
                    ammUpdatedNotional = 0 - diff; 
                    newSide = !ammSide;
                }
            }

            if (_traderUpdate._isActive == false){
                ammPosition.unrealizedPnl += _traderUpdate._fundingPaid;
            }

            int256 t = _traderUpdate._notional.muld(_traderUpdate._initialPrice);
            if (_traderUpdate._isActive == true && _traderUpdate._isLong == false){
                t *= -1;
            }else if(_traderUpdate._isActive == false && _traderUpdate._isLong == true){
                t *= -1;
            }

            if (ammUpdatedNotional != 0){

                //Last time it was closed
                int256 a = ammPosition.initialPrice.muld(ammNotional);
                if (ammNotional == 0){
                    a = ammPosition.zeroParameter;
                }else{
                    if (ammSide == false){
                        a *= -1;
                    }
                }


                int256 divTo = ammUpdatedNotional;
                if (newSide == false){
                    divTo *= -1;
                }

                ammPosition.initialPrice = (a - t).divd(divTo);
            }else{
                
                int256 mulTo = ammNotional;
                if (ammSide == false){
                    mulTo *= -1;
                }
                ammPosition.savedTradingPnl = (_traderUpdate._initialPrice - ammPosition.initialPrice).muld(mulTo).divd(_traderUpdate._initialPrice);
                ammPosition.zeroParameter = ammPosition.initialPrice.muld(mulTo) - t; 
            }

    
            ammPosition.notional = ammUpdatedNotional;
            ammPosition.isLong = newSide;
        }
    }

    
    function _ammCummulateFundingPnl(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage ammPosition,
        IMarket _market
    ) private {
        //ONLY once pre block
        if (ammPosition.initialBlockNumber == block.number){
            return;
        }
        ammPosition.initialBlockNumber = block.number;


        ammPosition.lastNotional = ammPosition.notional;
        ammPosition.lastIsLong = ammPosition.isLong;
        ammPosition.lastInitialPrice = ammPosition.initialPrice;

        ammPosition.unrealizedPnl = PnlLib.getAmmFundingPnl(state, 
                                                            _market, 
                                                            ammPosition);
        
        ammPosition.initialTimestamp = block.timestamp;
        ammPosition.cummulativeIndex = _market.currentOracleIndex();

    }



    /*
    **************************************************************************
    *   Different netting scenarios
    **************************************************************************
    */

    function _netPosition(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        StorageStripsLib.Position storage prevPosition
    ) private returns (int256) {
        int256 notional = posParams._collateral * posParams._leverage;
        int256 prevNotional = prevPosition.notional;
        int256 diff = notional - prevNotional;
        // Is itpartly close?
        if (diff < 0){
            int256 closeRatio = notional.divd(prevNotional);

            // If position for liquidation, the AMM will liquidate it
            // In other way it will be partly close
            return _liquidateWholeOrCloseRatio(state,
                                        prevPosition,
                                        posParams._market,
                                        closeRatio);
        }


        // Is the new position bigger?
        if (diff > 0){

            //STEP 1: close prev(long10: return collateral+profit)
            int256 slippage = _liquidateWholeOrCloseRatio(state,
                                        prevPosition,
                                        posParams._market,
                                        SignedBaseMath.oneDecimal());
            /*
            *   open short(5K)
            *   We need to save the same proportion
            *   diff / (collateral - x) = leverage
            *   
            *   x = collateral - diff/leverage
            *   adjCollateral = collateral - collateral + diff/leverage = difd/leverage 
            */
            posParams._collateral = diff.divd(posParams._leverage.toDecimal());

            slippage += _open(state, 
                                posParams, 
                                false);  //not a merge
            
            return slippage;
        }

        require(true == false, "UNKNOWN_NETTING");
    }


    function _aggregate(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        StorageStripsLib.Position storage prevPosition
    ) private returns (int256) {
        //We save ONLY funding_pnl
        prevPosition.unrealizedPnl += PnlLib.getFundingUnrealizedPnl(state, 
                                                            posParams._market, 
                                                            prevPosition, 
                                                            SignedBaseMath.oneDecimal(), 
                                                            true);  //based on CURRENT_MARKET_PRICE
        return _open(state,
                    posParams,
                    true);  // it's a merge
    }


    function _liquidateWholeOrCloseRatio(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage _position,
        IMarket _market,
        int256 _closeRatio
    ) private returns (int256 slippage){

        (,int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    _position,
                                                    SignedBaseMath.oneDecimal(),          // you can't partly close if full position is for liquidation
                                                    false); // Based on exit price


        if (marginRatio <= state.getLiquidationRatio()){
            //If it's opposite close we can liquidate
            _liquidate(state,
                        _market,
                        address(_market),
                        _position
            );
            slippage = 0;
        }else{
            slippage = _close(state,
                                    _position,
                                    _market,
                                    _closeRatio); //the whole position
        }
    }


    /*
    ****************************************************
    * OPEN/CLOSE/LIQUIDATE implementation
    ****************************************************
    */

    //not safe, all checks should be outside
    function _close(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        IMarket _market,
        int256 _closeRatio
    ) private returns (int256 slippage) {
        //we need to use closePrice here after the position will be closed
        (int256 funding_pnl,
        int256 trading_pnl,
        int256 traderPnl) = PnlLib.getAllUnrealizedPnl(state,
                                                    _market,
                                                    position,
                                                    _closeRatio,
                                                    false);

        int256 marketPnl = 0 - traderPnl;


        PosInfo memory pos_info = PosInfo({
            _notional:position.notional,
            _collateral:position.collateral,
            _unrealizedPnl:position.unrealizedPnl,
            _priceBeforeChange:_market.currentPrice()
        });

        if (_closeRatio != SignedBaseMath.oneDecimal()){
            pos_info._notional = pos_info._notional.muld(_closeRatio);
            pos_info._collateral = pos_info._collateral.muld(_closeRatio);
            pos_info._unrealizedPnl = pos_info._unrealizedPnl.muld(_closeRatio);
        }

        int256 closePrice = _market.closePosition(position.isLong, 
                                                    pos_info._notional);
        slippage = (closePrice - pos_info._priceBeforeChange).divd(pos_info._priceBeforeChange);
        if (slippage < 0){
            slippage *= -1;
        }


        // something went wrong, don't allow close positions
        require(closePrice > 0, "CLOSEPRICE_BROKEN");

        //Pay position Fee
        //expectedClosePrice
        _payPositionFee(state,
                        _market, 
                        msg.sender, 
                        pos_info._notional, 
                        closePrice);


        if (marketPnl > 0){
            //PROFIT: trader pays to Market from collateral

            if (marketPnl > pos_info._collateral){
                marketPnl = pos_info._collateral;
            }

            _payProfitOnPositionClose(state,
                                    _market,
                                    address(this),
                                    marketPnl);
            int256 left = pos_info._collateral - marketPnl;
            if (left > 0){
                _returnCollateral(state,
                                    msg.sender, 
                                    left);
            }
        }
        else if (marketPnl < 0){
            //LOSS: market pays to trader from liquidity

            int256 liquidity = _market.getLiquidity();
            if (liquidity < traderPnl){
                int256 debt = traderPnl - liquidity;
                _borrowInsurance(state,
                                    address(_market), 
                                    debt);
            }

            state.withdrawFromMarket(_market,
                                        msg.sender,
                                        traderPnl);
            _returnCollateral(state,
                                msg.sender,
                                pos_info._collateral);
        }
        else if (marketPnl == 0){
            //ZERO: just return collateral to trader
            _returnCollateral(state,
                                msg.sender,
                                pos_info._collateral);
        }


        int256 paid_funding = funding_pnl;
        if (position.isLong == false){
            paid_funding*= -1;
        }

        ammPositionUpdate(state,
                _market,
                TraderUpdate({
                    _notional:pos_info._notional,
                    _isLong: position.isLong,
                    _initialPrice:position.initialPrice,
                    _fundingPaid:paid_funding,
                    _isActive:false
                }));

        _unsetPostion(state,
                    position,
                    pos_info._notional,
                    pos_info._collateral,
                    _closeRatio,
                    pos_info._unrealizedPnl);
    }

    function _open(
        StorageStripsLib.State storage state,
        PositionParams memory posParams,
        bool merge
    ) private returns (int256 slippage) {
        int256 notional = posParams._collateral * posParams._leverage;

        _requireNotional(posParams._market,
                        notional);

        int256 currentPrice = posParams._market.currentPrice();
        int256 openPrice = posParams._market.openPosition(posParams._isLong, notional);

        slippage = (openPrice - currentPrice).divd(currentPrice);
        if (slippage < 0){
            slippage *= -1;
        }

        // something went wrong, don't allow open positions
        require(openPrice > 0, "OPEN_PRICE_LTE_0");
        
        state.setPosition(
            posParams._market,
            posParams._account,
            posParams._isLong,
            posParams._collateral,
            notional,
            openPrice,
            merge
        );

    

        //Get collateral on STRIPS balance
        _receiveCollateral(state,
                            posParams._account, 
                            posParams._collateral);

        //Send fee to Market and Insurance Balance, it will change liquidity
        _payPositionFee(state,
                        posParams._market, 
                        posParams._account, 
                        notional, 
                        openPrice);
        
        StorageStripsLib.Position storage position = state.getPosition(posParams._market, posParams._account);
        ammPositionUpdate(state,
                posParams._market,
                TraderUpdate({
                    _notional:notional,
                    _isLong:posParams._isLong,
                    _initialPrice:position.entryPrice,
                    _fundingPaid:0,
                    _isActive:true
                }));
    
        
        //Always check margin after any open
        _requireMargin(state,
                position,
                posParams._market,
                SignedBaseMath.oneDecimal());


    }

    function _liquidate(
        StorageStripsLib.State storage state,
        IMarket _market,
        address _liquidator,
        StorageStripsLib.Position storage position
    ) private {
        //The closePrice after the notional removed should be USED

        (int256 ammFee,
        int256 liquidatorFee,
        int256 insuranceFee,
        int256 funding_pnl_on_liquidation) = PnlLib.calcLiquidationFee(state,
                                                        _market, 
                                                        position);

        int256 closePrice = _market.closePosition(position.isLong, 
                                                    position.notional);
        
        require(closePrice > 0, "CLOSE_PRICE_ERROR");


        //Calc how much debt we need to borrow for all possible situations
        int256 debt = 0; 
        if (insuranceFee < 0){
            debt += 0 - insuranceFee;
            
            insuranceFee = 0; //We don't pay insuranceFee
        }

        int256 liquidity = _market.getLiquidity() + debt;

        // If not enough then we borrow only for amm and liquidator
        // It's ok to borrow more than we need - then we will have enough for the next time. But logic will be simpler.
        if (liquidity < (ammFee + liquidatorFee)){
            debt = debt + ammFee + liquidatorFee - liquidity;
            
            insuranceFee = 0; // We don't pay insurance

        }
        // we have a little bit to pay to insurance but we DON'T borrow
        else if(liquidity < (ammFee + liquidatorFee + insuranceFee)) 
        {
            insuranceFee = liquidity - ammFee - liquidatorFee;
            if (insuranceFee <= 0){
                insuranceFee = 0; //Just don't pay fee in this case
            }
        }
        
        /*EVERYTHING paid from collateral:
        * 1. Market fee - paid from strips balance to market
        * 2. Insurance fee - paid from strips balance to insurance
        * 3. Liquidator fee - paid from strips balance to liquidator (we use _returnCollateral)
        */
        if (debt > 0) {
            _borrowInsurance(state,
                            address(this), 
                            debt);//SO if we need to borrow we borrow to STRIPS balance, to keep logic unified

        }

        state.depositToMarket(_market, address(this), ammFee); //pay to Market

        if (insuranceFee > 0){
            state.depositToInsurance(address(this), insuranceFee); //pay to Insurance
        }
        _returnCollateral(state,
                        _liquidator, 
                        liquidatorFee); // pay to liquidator

        
        
        if (position.isLong == false){
            funding_pnl_on_liquidation*= -1;
        }
        ammPositionUpdate(state,
                _market,
                TraderUpdate({
                    _notional:position.notional,
                    _isLong:position.isLong,
                    _initialPrice:position.initialPrice,
                    _fundingPaid:funding_pnl_on_liquidation,
                    _isActive:false
                }));

        if (IStakeble(address(_market)).isRewardable()){
            address rewarder = IRewardable(address(_market)).getRewarder();
            IRewarder(rewarder).rewardTrader(position.trader, position.notional);
        }


        //ALWAYS CLOSE here: no need to read from storage, that's why 0
        _unsetPostion(state,
                    position,
                    0,
                    0,
                    SignedBaseMath.oneDecimal(),
                    0);
        
        position.isLiquidated = true;
    }

    /*
    *
    *   HELPERS
    *
    */
    function _unsetPostion(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        int256 notional,
        int256 collateral,
        int256 _closeRatio,
        int256 unrealizedPaid
    ) private {
        if (_closeRatio == SignedBaseMath.oneDecimal()){
            state.unsetPosition(position);
        }else{
            
            //It's just partly close
            state.partlyClose(
                position,
                collateral,
                notional,
                unrealizedPaid      
            );
        }
    }


    function _requireMargin(
        StorageStripsLib.State storage state,
        StorageStripsLib.Position storage position,
        IMarket _market,
        int256 _closeRatio
    ) private view {
        (,int256 marginRatio) = PnlLib.getMarginRatio(state,
                                                    _market,
                                                    position,
                                                    _closeRatio,
                                                    false);  // based on Exit Price always

        // Trader can't close position for liquidation                                            
        _requireMarginRatio(state, 
                            marginRatio);
    }


    function _requireMarginRatio(
        StorageStripsLib.State storage state,
        int256 marginRatio
    ) private view {
        require(marginRatio >= state.getLiquidationRatio(), "NOT_ENOUGH_MARGIN");
    }

    function _requireSlippage(
        int256 _requested,
        int256 _current
    ) private {
        require(_requested >= _current, "SLIPPAGE_EXCEEDED");
    }


    function _requireNotional(
        IMarket _market,
        int256 notional
    ) private returns (int256) {
        require(notional > 0, "NOTIONAL_LT_0");

        int256 maxNotional = _market.maxNotional();


        require(notional <= maxNotional, "NOTIONAL_GT_MAX");

        return maxNotional;
    }


    function _receiveCollateral(
        StorageStripsLib.State storage state,
        address _from, 
        int256 _amount
    )private returns (int256) {
        SafeERC20.safeTransferFrom(state.tradingToken, 
                                _from, 
                                address(this), 
                                uint(_amount));
    }

    function _returnCollateral(
        StorageStripsLib.State storage state,
        address _to, 
        int256 _amount
    )private returns (int256) {
        SafeERC20.safeTransfer(state.tradingToken, 
                                _to, 
                                uint(_amount));
    }

    function _payProfitOnPositionClose(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _from,
        int256 _amount
    ) private {
        int256 insuranceFee = _amount.muld(state.riskParams.insuranceProfitOnPositionClosed);
        int256 marketFee =_amount - insuranceFee;
        require(insuranceFee > 0 && marketFee > 0, "FEE_CALC_ERROR");
        state.depositToMarket(_market, 
                                _from, 
                                marketFee);

        //Pay fee to insurance fund
        state.depositToInsurance(_from, 
                                    insuranceFee);


    }

    //TODO: Can we store all the money on Strips? And just keep balances.
    // The only advantage is that Insurance money is safe in case of hack
    function _payPositionFee(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _from, 
        int256 _notional, 
        int256 _price
    ) private returns (int256 marketFee, int256 insuranceFee, int256 daoFee) {

        (marketFee, insuranceFee, daoFee) = PnlLib.calcPositionFee(state, 
                                                            _notional, 
                                                            _price);


        require(marketFee > 0 && insuranceFee > 0, "FEE_CALC_ERROR");

        state.depositToMarket(_market, 
                                _from, 
                                marketFee);
        
        //Pay fee to insurance fund
        state.depositToInsurance(_from, 
                                insuranceFee);

        //TODO: implement DAO here
        state.depositToDao(_from,
                            daoFee);
    }

    function _borrowInsurance(
        StorageStripsLib.State storage state,
        address _to, 
        int256 _amount         
    ) private {

        state.withdrawFromInsurance(_to, _amount);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";

interface IMarket {
    function getLongs() external view returns (int256);
    function getShorts() external view returns (int256);

    function priceChange(int256 notional, bool isLong) external view returns (int256);
    function currentPrice() external view returns (int256);
    function oraclePrice() external view returns (int256);
    
    function getAssetOracle() external view returns (address);
    function getPairOracle() external view returns (address);
    function currentOracleIndex() external view returns (uint256);

    function getPrices() external view returns (int256 marketPrice, int256 oraclePrice);    
    function getLiquidity() external view returns (int256);
    function getPartedLiquidity() external view returns (int256 tradingLiquidity, int256 stakingLiquidity);

    function openPosition(
        bool isLong,
        int256 notional
    ) external returns (int256 openPrice);

    function closePosition(
        bool isLong,
        int256 notional
    ) external returns (int256);

    function maxNotional() external view returns (int256);
}

pragma solidity ^0.8.0;

import { IMarket } from "./IMarket.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IInsuranceFund } from "./IInsuranceFund.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";

import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { IStripsEvents } from "../lib/events/Strips.sol";

interface IStrips is IStripsEvents 
{

    /*
        State actions
     */
    enum StateActionType {
        ClaimRewards
    }

    /*request */
    struct ClaimRewardsParams {
        address account;
    }

    struct StateActionArgs {
        StateActionType actionType;
        bytes data;
    }


    /*
        View actions
     */
    enum ViewActionType {
        GetOracles,
        GetMarkets,
        CalcFeeAndSlippage,
        GetPosition,
        CalcClose,
        CalcRewards
    }

    /*request */
    struct CalcRewardsParams {
        address account;
    }
    /*response */
    struct CalcRewardsData {
        address account;
        int256 rewardsTotal;
    }


    /*request */
    struct CalcCloseParams {
        address market;
        address account;
        int256 closeRatio;
    }
    /*response */
    struct CalcCloseData {
        address market;
        int256 minimumMargin;
        int256 pnl;
        int256 marginLeft;
        int256 fee;
        int256 slippage;
        int256 whatIfPrice;
    }

    /*
        request 
        response: PositionParams or revert
    */
    struct GetPositionParams {
        address market;
        address account;
    }


    /*request */
    struct FeeAndSlippageParams {
        address market;
        int256 notional;
        int256 collateral;
        bool isLong;
    }

    /* response */
    struct FeeAndSlippageData{
        address market;
        int256 marketRate;
        int256 oracleRate;
        
        int256 fee;
        int256 whatIfPrice;
        int256 slippage;

        int256 minimumMargin;
        int256 estimatedMargin;
    }


    struct ViewActionArgs {
        ViewActionType actionType;
        bytes data;
    }


    /*
        Admin actions
     */

    enum AdminActionType {
        AddMarket,   
        AddOracle,  
        RemoveOracle,  
        ChangeOracle,
        SetInsurance,
        ChangeRisk
    }

    struct AddMarketParams{
        address market;
    }

    struct AddOracleParams{
        address oracle;
        int256 keeperReward;
    }

    struct RemoveOracleParams{
        address oracle;
    }

    struct ChangeOracleParams{
        address oracle;
        int256 newReward;
    }

    struct SetInsuranceParams{
        address insurance;
    }

    struct ChangeRiskParams{
        StorageStripsLib.RiskParams riskParams;
    }


    struct AdminActionArgs {
        AdminActionType actionType;
        bytes data;
    }



    /*
        Events
     */
    event LogNewMarket(
        address indexed market
    );

    event LogPositionUpdate(
        address indexed account,
        IMarket indexed market,
        PositionParams params
    );

    struct PositionParams {
        // true - for long, false - for short
        bool isLong;
        // is this position closed or not
        bool isActive;
        // is this position liquidated or not
        bool isLiquidated;

        //position size in USDC
        int256 notional;
        //collateral size in USDC
        int256 collateral;
        //initial price for position
        int256 initialPrice;
    }

    struct PositionData {
        //address of the market
        IMarket market;
        // total pnl - real-time profit or loss for this position
        int256 pnl;

        // this pnl is calculated based on whatIfPrice
        int256 pnlWhatIf;
        
        // current margin ratio of the position
        int256 marginRatio;
        PositionParams positionParams;
    }

    struct AssetData {
        bool isInsurance;
        
        address asset;
         // Address of SLP/SIP token
        address slpToken;

        int256 marketPrice;
        int256 oraclePrice;

        int256 maxNotional;
        int256 tvl;
        int256 apy;

        int256 minimumMargin;
    }

    struct StakingData {
         //Market or Insurance address
        address asset; 

        // collateral = slp amount
        uint256 totalStaked;
    }

    /**
     * @notice Struct that keep real-time trading data
     */
    struct TradingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        PositionData[] positionData;
    }

    /**
     * @notice Struct that keep real-time staking data
     */
    struct StakingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        StakingData[] stakingData;
    }

    /**
     * @notice Struct that keep staking and trading data
     */
    struct AllInfo {
        TradingInfo tradingInfo;
        StakingInfo stakingInfo;
    }

    function open(
        IMarket _market,
        bool isLong,
        int256 collateral,
        int256 leverage,
        int256 slippage
    ) external;

    function close(
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) external;

    function changeCollateral(
        IMarket _market,
        int256 collateral,
        bool isAdd
    ) external;

    function ping() external;
    function getPositionsCount() external view returns (uint);
    function getPositionsForLiquidation(uint _start, uint _length) external view returns (StorageStripsLib.PositionMeta[] memory);
    function liquidatePosition(IMarket _market, address account) external;
    function payKeeperReward(address keeper) external;

    /*
        Strips getters functions for Trader
     */
    function assetPnl(address _asset) external view returns (int256);
    function getLpOracle() external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IInsuranceFund {
    function withdraw(address _to, int256 _amount) external;

    function getLiquidity() external view returns (int256);
    function getPartedLiquidity() external view returns (int256 usdcLiquidity, int256 lpLiquidity);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IRewarder {
    event TradingRewardClaimed(
        address indexed user, 
        int256 amount
    );

    event StakingRewardClaimed(
        address indexed user, 
        int256 amount
    );

    struct InitParams {
        uint256 periodLength;
        uint256 washTime;

        IERC20 slpToken;
        IERC20 strpToken;

        address stripsProxy;
        address dao;
        address admin;

        int256 rewardTotalPerSecTrader;
        int256 rewardTotalPerSecStaker;
    }

    function claimStakingReward(address _staker) external;
    function claimTradingReward(address _trader) external;

    function totalStakerReward(address _staker) external view returns (int256 reward);
    function totalTradeReward(address _trader) external view returns (int256 reward);

    function rewardStaker(address _staker) external;
    function rewardTrader(address _trader, int256 _notional) external;

    function currentTradingReward() external view returns(int256);
    function currentStakingReward() external view returns (int256);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";
import { IRewarder } from "./IRewarder.sol";

interface IRewardable {
    function createRewarder(IRewarder.InitParams memory _params) external;
    function getRewarder() external view returns (address);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IStakeble is IStakebleEvents {
    event LiquidityChanged(
        address indexed asset,
        address indexed changer,
        string indexed action,
        
        int256 totalLiquidity,
        int256 currentStakedPnl,
        int256 stakerInitialStakedPnl,
        int256 stakerTotalCollateral
    );

    event TokenAdded(
        address indexed asset,
        address indexed token
    );

    event LogStakeChanged(
        address indexed asset,
        address indexed changer,
        bool isStake,
        
        int256 burnedSlp,
        int256 unstakeLp,
        int256 unstakeUsdc,

        int256 lp_fee,
        int256 usdc_fee
    );
    function createSLP(IStripsLpToken.TokenParams memory _params) external;
    function totalStaked() external view returns (int256);
    function isInsurance() external view returns (bool);
    function liveTime() external view returns (uint);

    function getSlpToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getTradingToken() external view returns (address);
    function getStrips() external view returns (address);

    function ensureFunds(int256 amount) external;
    function stake(int256 amount) external;
    function unstake(int256 amount) external;

    function approveStrips(IERC20 _token, int256 _amount) external;
    function externalLiquidityChanged() external;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

    function isRewardable() external view returns (bool);

    function changeSushiRouter(address _router) external;
    function getSushiRouter() external view returns (address);

    function getStrp() external view returns (address);
}

pragma solidity ^0.8.0;

// We are using 0.8.0 with safemath inbuilt
// Need to implement mul and div operations only
// We have 18 for decimal part and  58 for integer part. 58+18 = 76 + 1 bit for sign
// so the maximum is 10**58.10**18 (should be enough :) )

library SignedBaseMath {
    uint8 constant DECIMALS = 18;
    int256 constant BASE = 10**18;
    int256 constant BASE_PERCENT = 10**16;

    /*Use this to convert USDC 6 decimals to 18 decimals */
    function to18Decimal(int256 x, uint8 tokenDecimals) internal pure returns (int256) {
        require(tokenDecimals < DECIMALS);
        return x * int256(10**(DECIMALS - tokenDecimals));
    }

    /*Use this to convert USDC 18 decimals back to original 6 decimal and send it */
    function from18Decimal(int256 x, uint8 tokenDecimals) internal pure returns (int256) {
        require(tokenDecimals < DECIMALS);
        return x / int256(10**(DECIMALS - tokenDecimals));
    }


    function toDecimal(int256 x, uint8 decimals) internal pure returns (int256) {
        return x * int256(10**decimals);
    }

    function toDecimal(int256 x) internal pure returns (int256) {
        return x * BASE;
    }

    function oneDecimal() internal pure returns (int256) {
        return 1 * BASE;
    }

    function tenPercent() internal pure returns (int256) {
        return 10 * BASE_PERCENT;
    }

    function ninetyPercent() internal pure returns (int256) {
        return 90 * BASE_PERCENT;
    }

    function onpointOne() internal pure returns (int256) {
        return 110 * BASE_PERCENT;
    }


    function onePercent() internal pure returns (int256) {
        return 1 * BASE_PERCENT;
    }

    function muld(int256 x, int256 y) internal pure returns (int256) {
        return _muld(x, y, DECIMALS);
    }

    function divd(int256 x, int256 y) internal pure returns (int256) {
        if (y == 1){
            return x;
        }
        return _divd(x, y, DECIMALS);
    }

    function _muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    function _divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / y;
    }

    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


library StorageStripsLib {
    using SignedBaseMath for int256;
    
    struct MarketData {
        bool created;

        //TODO: any data about the
    }

    struct Position {
        IMarket market; //can be removed
        address trader;

        int256 initialPrice; //will become avg on _aggregation
        int256 entryPrice;   // always the "new market price"
        int256 prevAvgPrice; 

        int256 collateral; 
        int256 notional; 

        uint256 initialTimestamp;
        uint256 cummulativeIndex; 
        uint256 initialBlockNumber;
        uint256 posIndex;           // use this to find position by index
        uint256 lastChangeBlock;

        int256 unrealizedPnl;   //used to save funding_pnl for aggregation
        
        //TODO: refactor this
        bool isLong;
        bool isActive;
        bool isLiquidated;  
        
        //used only for AMM
        bool isAmm;
        int256 savedTradingPnl;    // use this to deal with div to zero when ammUpdatedNotional == 0
        int256 zeroParameter;
        int256 lastNotional;      // for amm we calculate funding based on notional from prev block always
        int256 lastInitialPrice;  // for amm
        bool lastIsLong;

        int256 oraclePriceUsed;
    }

    struct RiskParams {
        int256 fundFeeRatio; //the part of fee that goes to Fee Fund. insuranceFeeRatio = 1 - fundFeeRatio 
        int256 daoFeeRatio;

        int256 liquidatorFeeRatio; // used to calc the liquidator reward insuranceLiquidationFeeRatio = 1 - liquidatorFeeRatio
        int256 marketFeeRatio; // used to calc market ratio on Liquidation
        int256 insuranceProfitOnPositionClosed;

        int256 liquidationMarginRatio; // the minimum possible margin ratio.
        int256 minimumPricePossible; //use this when calculate fee
    }

    struct OracleData {
        bool isActive;
        int256 keeperReward; 
    }

    /*Use this struct for fast access to position */
    struct PositionMeta {
        bool isActive; // is Position active

        address _account; 
        IMarket _market;
        uint _posIndex;
    }


    //GENERAL STATE - keep aligned on update
    struct State {
        address dao;
        bool isSuspended;

        /*Markets data */
        IMarket[] allMarkets;
        mapping (IMarket => MarketData) markets;

        /*Traders data */
        address[] allAccounts; // never pop
        mapping (address => bool) existingAccounts; // so to not add twice, and have o(1) check for addin

        mapping (address => mapping(IMarket => Position)) accounts; 
        
        uint[] allIndexes;  // if we need to loop through all positions we use this array. Reorder it to imporove effectivenes
        mapping (uint => PositionMeta) indexToPositionMeta;
        uint256 currentPositionIndex; //index of the latest created position

        /*Oracles */
        address[] allOracles;
        mapping(address => OracleData) oracles;

        /*Strips params */
        RiskParams riskParams;
        IInsuranceFund insuranceFund;
        IERC20 tradingToken;

        // last ping timestamp
        uint256 lastAlive;
        // the time interval during which contract methods are available that are marked with a modifier ifAlive
        uint256 keepAliveInterval;

        address lpOracle;
    }

    /*
        Oracles routines
    */
    function addOracle(
        State storage state,
        address _oracle,
        int256 _keeperReward
    ) internal {
        require(state.oracles[_oracle].isActive == false, "ORACLE_EXIST");
        
        state.oracles[_oracle].keeperReward = _keeperReward;
        state.oracles[_oracle].isActive = true;

        state.allOracles.push(_oracle);
    }

    function removeOracle(
        State storage state,
        address _oracle
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].isActive = false;
    }


    function changeOracleReward(
        State storage state,
        address _oracle,
        int256 _newReward
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].keeperReward = _newReward;
    }


    /*
    *******************************************************
    *   getters/setters for adding/removing data to state
    *******************************************************
    */

    function setInsurance(
        State storage state,
        IInsuranceFund _insurance
    ) internal
    {
        require(address(_insurance) != address(0), "ZERO_INSURANCE");
        require(address(state.insuranceFund) == address(0), "INSURANCE_EXIST");

        state.insuranceFund = _insurance;
    }

    function getMarket(
        State storage state,
        IMarket _market
    ) internal view returns (MarketData storage market) {
        market = state.markets[_market];
        require(market.created == true, "NO_MARKET");
    }

    function addMarket(
        State storage state,
        IMarket _market
    ) internal {
        MarketData storage market = state.markets[_market];
        require(market.created == false, "MARKET_EXIST");

        state.markets[_market].created = true;
        state.allMarkets.push(_market);
    }

    function setRiskParams(
        State storage state,
        RiskParams memory _riskParams
    ) internal{
        state.riskParams = _riskParams;
    }



    // Not optimal 
    function checkPosition(
        State storage state,
        IMarket _market,
        address account
    ) internal view returns (Position storage){
        return state.accounts[account][_market];
    }

    // Not optimal 
    function getPosition(
        State storage state,
        IMarket _market,
        address _account
    ) internal view returns (Position storage position){
        position = state.accounts[_account][_market];
        require(position.isActive == true, "NO_POSITION");
    }

    function setPosition(
        State storage state,
        IMarket _market,
        address account,
        bool isLong,
        int256 collateral,
        int256 notional,
        int256 initialPrice,
        bool merge
    ) internal returns (uint256 index) {
        
        /*TODO: remove this */
        if (state.existingAccounts[account] == false){
            state.allAccounts.push(account); 
            state.existingAccounts[account] = true;
        }
        Position storage _position = state.accounts[account][_market];

        /*
            Update PositionMeta for faster itterate over positions.
            - it MUST be trader position
            - it should be closed or liquidated. 

            We DON'T update PositionMeta if it's merge of the position
         */
        if (address(_market) != account && _position.isActive == false)
        {            
            /*First ever position for this account-_market setup index */
            if (_position.posIndex == 0){
                if (state.currentPositionIndex == 0){
                    state.currentPositionIndex = 1;  // posIndex started from 1, to be able to do check above
                }

                _position.posIndex = state.currentPositionIndex;

                state.allIndexes.push(_position.posIndex);
                state.indexToPositionMeta[_position.posIndex] = PositionMeta({
                    isActive: true,
                    _account: account,
                    _market: _market,
                    _posIndex: _position.posIndex
                });

                /*INCREMENT index only if unique position was created */
                state.currentPositionIndex += 1;                
            }else{
                /*We don't change index if it's old position, just need to activate it */
                state.indexToPositionMeta[_position.posIndex].isActive = true;
            }
        }

        index = _position.posIndex;

        _position.trader = account;
        _position.lastChangeBlock = block.number;
        _position.isActive = true;
        _position.isLiquidated = false;

        _position.isLong = isLong;
        _position.market = _market;
        _position.cummulativeIndex = _market.currentOracleIndex();
        _position.initialTimestamp = block.timestamp;
        _position.initialBlockNumber = block.number;
        _position.entryPrice = initialPrice;

        int256 avgPrice = initialPrice;
        int256 prevAverage = _position.prevAvgPrice;
        if (prevAverage != 0){
            int256 prevNotional = _position.notional; //save 1 read
            avgPrice =(prevAverage.muld(prevNotional) + initialPrice.muld(notional)).divd(notional + prevNotional);
        }
        
        
        _position.prevAvgPrice = avgPrice;

        
        if (merge == true){
            _position.collateral +=  collateral; 
            _position.notional += notional;
            _position.initialPrice = avgPrice;
        }else{
            _position.collateral = collateral;
            _position.notional = notional;
            _position.initialPrice = initialPrice;
            
            //It's AMM need to deal with that in other places        
            if (address(_market) == account){
                _position.isAmm = true;
                _position.lastNotional = notional;
                _position.lastInitialPrice = initialPrice;
            }
        }
    }

    function unsetPosition(
        State storage state,
        Position storage _position
    ) internal {
        if (_position.isActive == false){
            return;
        } 

        /*
            Position is fully closed or liquidated, NEED to update PositionMeta 
            BUT
            we never reset the posIndex
        */
        state.indexToPositionMeta[_position.posIndex].isActive = false;

        _position.lastChangeBlock = block.number;
        _position.isActive = false;

        _position.entryPrice = 0;
        _position.collateral = 0; 
        _position.notional = 0; 
        _position.initialPrice = 0;
        _position.cummulativeIndex = 0;
        _position.initialTimestamp = 0;
        _position.initialBlockNumber = 0;
        _position.unrealizedPnl = 0;
        _position.prevAvgPrice = 0;
    }

    function partlyClose(
        State storage state,
        Position storage _position,
        int256 collateral,
        int256 notional,
        int256 unrealizedPaid
    ) internal {
        _position.collateral -= collateral; 
        _position.notional -= notional;
        _position.unrealizedPnl -= unrealizedPaid;
        _position.lastChangeBlock = block.number;
    }

    /*
    *******************************************************
    *******************************************************
    *   Liquidation related functions
    *******************************************************
    *******************************************************
    */
    function getLiquidationRatio(
        State storage state
    ) internal view returns (int256){
        return state.riskParams.liquidationMarginRatio;
    }


    //Integrity check outside
    function addCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral += collateral;
    }

    function removeCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral -= collateral;
        
        require(_position.collateral >= 0, "COLLATERAL_TOO_BIG");
    }



    /*
    *******************************************************
    *   Funds view/transfer utils
    *******************************************************
    */
    function depositToDao(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");
        require(state.dao != address(0), "ZERO_DAO");
        
        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken,
                                        state.dao, 
                                        uint(_amount));

        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        state.dao, 
                                        uint(_amount));
        }

    }

    function depositToMarket(
        State storage state,
        IMarket _market,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(_market), 
                                        uint(_amount));

        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(_market), 
                                        uint(_amount));
        }

        IStakeble(address(_market)).externalLiquidityChanged();

        IStakeble(address(_market)).changeTradingPnl(_amount);
    }
    
    function withdrawFromMarket(
        State storage state,
        IMarket _market,
        address _to,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        IStakeble(address(_market)).ensureFunds(_amount);

        IStakeble(address(_market)).approveStrips(state.tradingToken, _amount);
        SafeERC20.safeTransferFrom(state.tradingToken, 
                                    address(_market), 
                                    _to, 
                                    uint(_amount));

        IStakeble(address(_market)).externalLiquidityChanged();

        IStakeble(address(_market)).changeTradingPnl(0 - _amount);
    }

    function depositToInsurance(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }

        IStakeble(address(state.insuranceFund)).externalLiquidityChanged();

        IStakeble(address(state.insuranceFund)).changeTradingPnl(_amount);

    }
    
    function withdrawFromInsurance(
        State storage state,
        address _to,
        int256 _amount
    ) internal {
        
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        IStakeble(address(state.insuranceFund)).ensureFunds(_amount);

        state.insuranceFund.withdraw(_to, _amount);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(0 - _amount);
    }


}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";

import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageStripsLib } from "./StorageStrips.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library PnlLib {
    int256 constant ANN_PERIOD_SEC = 31536000;

    using SignedBaseMath for int256;
    using StorageStripsLib for StorageStripsLib.State;
    using StorageMarketLib for StorageMarketLib.State;

    // To not have stack too deep error
    struct PosInfo {
        bool isLong;
        int256 initialPrice;
        uint256 cummulativeIndex;
        int256 notional;
        int256 unrealizedPnl;
    }

    struct AmmPosInfo {
        int256 notional;        
        int256 initialPrice;
        bool lastIsLong;
    }


    function getMarginRatio(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage _position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 total_pnl, int256 marginRatio) {
         total_pnl = calcUnrealizedPnl(state,
                                        _market,
                                        _position,
                                        _notionalRatio,
                                        is_market_price);
        
        //traderPnl already calculated for right ratio
        if (_notionalRatio == SignedBaseMath.oneDecimal()){
            marginRatio = (_position.collateral + total_pnl).divd(_position.notional);
        }else{
            int256 full_pnl = calcUnrealizedPnl(state,
                                        _market,
                                        _position,
                                        SignedBaseMath.oneDecimal(),
                                        is_market_price);
                                        
            // Margin ratio after partly close
            marginRatio = (_position.collateral.muld(SignedBaseMath.oneDecimal() - _notionalRatio) + full_pnl - total_pnl).divd(_position.notional.muld(SignedBaseMath.oneDecimal() - _notionalRatio));
        }
    }

    function getFundingUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
        return funding_pnl;
    }

    
    function calcUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
        return total_pnl;
    }

    function getAmmTotalPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
        return total_pnl;
    }


    function getAmmFundingPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256) {
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
        return funding_pnl;
    }


    function getAmmAllPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl) {
        (funding_pnl,
            trading_pnl,
            total_pnl) = calcAmmPnlParts(state, 
                                        _market, 
                                        position);
    }

    function getAllUnrealizedPnl(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl) {
        (funding_pnl,
            trading_pnl,
            total_pnl) = calcPnlParts(state, 
                                        _market, 
                                        position,
                                        _notionalRatio,
                                        is_market_price);
    }


    //It can calc partlyPnl 
    function calcPnlParts(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position,
        int256 _notionalRatio,
        bool is_market_price
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl)
    {
        
        PosInfo memory pos_info;

        //Save gas on reading
        pos_info.isLong = position.isLong;
        pos_info.initialPrice = position.initialPrice;
        pos_info.notional = position.notional;
        pos_info.unrealizedPnl = position.unrealizedPnl;
        if (_notionalRatio != SignedBaseMath.oneDecimal()){
            pos_info.notional = pos_info.notional.muld(_notionalRatio);
            pos_info.unrealizedPnl = pos_info.unrealizedPnl.muld(_notionalRatio);
        }

        

        int256 _price;

        if (is_market_price == true){
            _price = _market.currentPrice();
        }else{
            _price = _market.priceChange(0 - pos_info.notional, 
                                            pos_info.isLong);
        }
        
        //DONE: after 24-June discussion
        trading_pnl = pos_info.notional.muld(_price - pos_info.initialPrice).divd(_price);


                //scalar - in seconds since epoch
        int256 time_elapsed = int256(block.timestamp - position.initialTimestamp);

        //we have funding_pnl ONLY for next block
        if (time_elapsed > 0){
            int256 oracle_avg = calcOracleAverage(_market, position.cummulativeIndex);

            int256 proportion = time_elapsed.toDecimal().divd(ANN_PERIOD_SEC.toDecimal());      

            //DONE: after 24-June discussion
            funding_pnl = pos_info.notional.muld(oracle_avg.muld(time_elapsed.toDecimal())) - pos_info.notional.muld(pos_info.initialPrice.muld(proportion));
        }

        funding_pnl += pos_info.unrealizedPnl;

        if (pos_info.isLong){
            total_pnl = funding_pnl + trading_pnl;
        }else{
            total_pnl = 0 - trading_pnl - funding_pnl;
        }
    }

    function calcAmmPnlParts(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage ammPosition
    ) internal view returns (int256 funding_pnl,
                            int256 trading_pnl,
                            int256 total_pnl)
    {

        int256 _price = _market.currentPrice();


        //trading calcs always based on current notional
        trading_pnl = ammPosition.notional.muld(_price - ammPosition.initialPrice).divd(_price);
        if (ammPosition.notional == 0){
            trading_pnl = ammPosition.savedTradingPnl;
        }

        AmmPosInfo memory amm_info = AmmPosInfo({
            notional:ammPosition.lastNotional,      
            initialPrice:ammPosition.lastInitialPrice,
            lastIsLong:ammPosition.lastIsLong
        });


        if (ammPosition.initialBlockNumber != block.number){
            amm_info.notional = ammPosition.notional;
            amm_info.initialPrice = ammPosition.initialPrice;
            amm_info.lastIsLong = ammPosition.isLong;
        }

        int256 time_elapsed = int256(block.timestamp - ammPosition.initialTimestamp);

        int256 instantFunding;
        if (time_elapsed > 0){
            int256 oracle_avg;

            oracle_avg = calcOracleAverage(_market, ammPosition.cummulativeIndex);

            int256 proportion = time_elapsed.toDecimal().divd(ANN_PERIOD_SEC.toDecimal());     

            instantFunding = amm_info.notional.muld(oracle_avg.muld(time_elapsed.toDecimal())) - amm_info.notional.muld(amm_info.initialPrice.muld(proportion));
            
            //SUPER carefull here - we need to know the PREVIOUS sign if we calc based on historical value
            if (ammPosition.lastIsLong == false){
                instantFunding *= -1;
            }

            
            
        }


        funding_pnl = instantFunding + ammPosition.unrealizedPnl;


        //BUT here we are using current isLong of amm
        if (ammPosition.notional == 0){
            total_pnl = funding_pnl + trading_pnl;
        }
        else if (ammPosition.isLong == true){
            total_pnl = funding_pnl + trading_pnl;
        }else{
            total_pnl = 0 - trading_pnl + funding_pnl;
        }

    }



    function calcOracleAverage(
        IMarket _market,
        uint256 fromIndex
    ) internal view returns (int256) {        
        return IAssetOracle(_market.getAssetOracle()).calcOracleAverage(fromIndex);
    }

    function calcPositionParams(
        StorageStripsLib.State storage state,
        IMarket _market, 
        address _account, 
        bool is_market_price
    ) internal view returns (int256 funding_pnl, 
                            int256 trading_pnl,
                            int256 total_pnl,
                            int256 margin_ratio)
    {
        StorageStripsLib.Position storage _position = state.getPosition(_market, _account);

        (funding_pnl,
          trading_pnl,
          total_pnl) = calcPnlParts(state, 
                                    _market, 
                                    _position,
                                    SignedBaseMath.oneDecimal(),
                                    is_market_price);
        
        margin_ratio = (_position.collateral + total_pnl).divd(_position.notional);
    }

    /*
    *
    *   FEE CALCULATIOSN
    *
    */

    function calcLiquidationFee(
        StorageStripsLib.State storage state,
        IMarket _market,
        StorageStripsLib.Position storage position
    ) internal view returns (int256 ammFee,
                            int256 liquidatorFee,
                            int256 insuranceFee,
                            int256 funding_pnl_liquidated)
    {

        //we calc PNL based on price after the position is closed
        (int256 funding_pnl,
            int256 trading_pnl,
            int256 unrealizedPnl) = getAllUnrealizedPnl(state,
                                                _market, 
                                                position,
                                                SignedBaseMath.oneDecimal(),
                                                false);


        funding_pnl_liquidated = funding_pnl;

        if (unrealizedPnl < 0){
            unrealizedPnl *= -1;
        }

        int256 netEquity = position.collateral - unrealizedPnl;

        //Market and liquidator Fee are always the same
        ammFee = unrealizedPnl.muld(state.riskParams.marketFeeRatio);
        liquidatorFee = unrealizedPnl.muld(state.riskParams.liquidatorFeeRatio);

        //easy to read is more important than optimization now
        int256 insuranceFeeRatio = SignedBaseMath.oneDecimal() - state.riskParams.liquidatorFeeRatio - state.riskParams.marketFeeRatio;

        insuranceFee = unrealizedPnl.muld(insuranceFeeRatio);

        insuranceFee += netEquity;
    }

    function calcPositionFee(
        StorageStripsLib.State storage state,
        int256 _notional,
        int256 _price
    ) internal view returns (int256 fee, int256 iFee, int256 daoFee) {
        int256 calcPrice = _price;
        if (calcPrice < state.riskParams.minimumPricePossible){
            calcPrice = state.riskParams.minimumPricePossible;
        }

        int256 baseFee = calcPrice.muld(_notional).muld(SignedBaseMath.onePercent());

        int256 ammFeeRatio = state.riskParams.fundFeeRatio;
        int256 daoFeeRatio = state.riskParams.daoFeeRatio;
        int256 iFeeRatio = SignedBaseMath.oneDecimal() - ammFeeRatio - daoFeeRatio;

        require((ammFeeRatio + daoFeeRatio + iFeeRatio) <= SignedBaseMath.oneDecimal(), "FEE_SUM_GT_1");

        fee = ammFeeRatio.muld(baseFee);
        daoFee = daoFeeRatio.muld(baseFee);
        iFee = iFeeRatio.muld(baseFee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IStrips } from "../interface/IStrips.sol";

interface IStripsLpToken is IERC20 {
    struct TokenParams {
        address stripsProxy;
        address pairOracle;

        address tradingToken;
        address stakingToken; 

        int256 penaltyPeriod;
        int256 penaltyFee;
    }

    struct ProfitParams{
        int256 unstakeAmountLP;
        int256 unstakeAmountERC20;

        int256 stakingProfit;   
        int256 stakingFee;

        int256 penaltyLeft;
        uint256 totalStaked;

        int256 lpPrice;

        int256 lpProfit;
        int256 usdcLoss;
    }

    function getParams() external view returns (TokenParams memory);
    function getBurnableToken() external view returns (address);
    function getPairPrice() external view returns (int256);
    function checkOwnership() external view returns (address);

    function totalPnl() external view returns (int256 usdcTotal, int256 lpTotal);

    function accumulatePnl() external;
    function saveProfit(address staker) external;
    function mint(address staker, uint256 amount) external;
    function burn(address staker, uint256 amount) external;

    function calcFeeLeft(address staker) external view returns (int256 feeShare, int256 periodLeft);
    function calcProfit(address staker, uint256 amount) external view returns (ProfitParams memory);

    function claimProfit(address staker, uint256 amount) external returns (int256 stakingProfit, int256 tradingProfit);
    function setPenaltyFee(int256 _fee) external;
    function setParams(TokenParams memory _params) external;
    function canUnstake(address staker, uint256 amount) external view;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

}

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IStripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        CheckInsuranceParams params
    );

    struct CheckInsuranceParams{
        int256 lpLiquidity;
        int256 usdcLiquidity;
        uint256 sipTotalSupply;
    }

    // ============ Structs ============

    struct CheckParams{
        /*Integrity Checks */        
        int256 marketPrice;
        int256 oraclePrice;
        int256 tradersTotalPnl;
        int256 uniLpPrice;
        
        /*Market params */
        bool ammIsLong;
        int256 ammTradingPnl;
        int256 ammFundingPnl;
        int256 ammTotalPnl;
        int256 ammNotional;
        int256 ammInitialPrice;
        int256 ammEntryPrice;
        int256 ammTradingLiquidity;
        int256 ammStakingLiquidity;
        int256 ammTotalLiquidity;

        /*Trading params */
        bool isLong;
        int256 tradingPnl;
        int256 fundingPnl;
        int256 totalPnl;
        int256 marginRatio;
        int256 collateral;
        int256 notional;
        int256 initialPrice;
        int256 entryPrice;

        /*Staking params */
        int256 slpTradingPnl;
        int256 slpStakingPnl;
        int256 slpTradingCummulativePnl;
        int256 slpStakingCummulativePnl;
        int256 slpTradingPnlGrowth;
        int256 slpStakingPnlGrowth;
        int256 slpTotalSupply;

        int256 stakerInitialStakingPnl;
        int256 stakerInitialTradingPnl;
        uint256 stakerInitialBlockNum;
        int256 stakerUnrealizedStakingProfit;
        int256 stakerUnrealizedTradingProfit;

        /*Rewards params */
        int256 tradingRewardsTotal; 
        int256 stakingRewardsTotal;
    }
}

library StripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        IStripsEvents.CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        IStripsEvents.CheckInsuranceParams params
    );


    function logCheckData(address _account,
                            address _market, 
                            IStripsEvents.CheckParams memory _params) internal {
        
        emit LogCheckData(_account,
                        _market,
                        _params);
    }

    function logCheckInsuranceData(address insurance,
                                    IStripsEvents.CheckInsuranceParams memory _params) internal {
        
        emit LogCheckInsuranceData(insurance,
                                    _params);
    }

}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IAssetOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function calcOracleAverage(uint256 fromIndex) external view returns (int256);
}

pragma solidity ^0.8.0;

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRewarder } from "../interface/IRewarder.sol";

library StorageMarketLib {
    using SignedBaseMath for int256;

    /* Params that are set on contract creation */
    struct InitParams {
        IStrips stripsProxy;
        IAssetOracle assetOracle;
        IUniswapLpOracle pairOracle;

        int256 initialPrice;
        int256 burningCoef;

        IUniswapV2Pair stakingToken;
        IERC20 tradingToken;
        IERC20 strpToken;       
    }

    //Need to care about align here 
    struct State {
        address dao;

        InitParams params;
        IStripsLpToken slpToken;
        IRewarder rewarder;

        int256 totalLongs; //Real notional 
        int256 totalShorts; //Real notional
        
        int256 demand; //included proportion
        int256 supply; //included proportion
        
        int256 ratio;
        int256 _prevLiquidity;
        bool isSuspended;

        address sushiRouter;
        uint createdAt;
    }

    function pairPrice(
        State storage state
    ) internal view returns (int256){
        return state.params.pairOracle.getPrice();
    }

    //If required LP price conversions should be made here
    function calcStakingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.stakingToken.balanceOf(address(this)));
    }

    function calcTradingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.tradingToken.balanceOf(address(this)));
    }

    function getLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        return stakingLiquidity + calcTradingLiqudity(state);
    }

    //Should return the scalar
    //TODO: change to stackedLiquidity + total_longs_pnl + total_shorts_pnl
    function maxNotional(
        State storage state
    ) internal view returns (int256) {
        int256 _liquidity = getLiquidity(state);

        if (_liquidity <= 0){
            return 0;
        }
        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 exposure = state.totalLongs - state.totalShorts;
        if (exposure < 0){
            exposure *= -1;
        }

        //10% now. TODO: allow setup via Params
        return (_liquidity + unrealizedPnl - exposure).muld(10 * SignedBaseMath.onePercent());
    }


    function getPrices(
        State storage state
    ) internal view returns (int256 marketPrice, int256 oraclePrice){
        marketPrice = currentPrice(state);

        oraclePrice = IAssetOracle(state.params.assetOracle).getPrice();
    }

    function currentPrice(
        State storage state
    ) internal view returns (int256) {
        return state.params.initialPrice.muld(state.ratio);
    }


    function oraclePrice(
        State storage state
    ) internal view returns (int256) {
        return IAssetOracle(state.params.assetOracle).getPrice();
    }

    function approveStrips(
        State storage state,
        IERC20 _token,
        int256 _amount
    ) internal {
        require(_amount > 0, "BAD_AMOUNT");

        SafeERC20.safeApprove(_token, 
                                address(state.params.stripsProxy), 
                                uint(_amount));
    }
    
    function _updateRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal
    {
        int256 _liquidity = getLiquidity(state); 
        if (state._prevLiquidity == 0){
            state.supply = _liquidity.divd(SignedBaseMath.oneDecimal() + state.ratio);
            state.demand = state.supply.muld(state.ratio);
            state._prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - state._prevLiquidity;

        state.demand += (_longAmount + diff.muld(state.ratio.divd(SignedBaseMath.oneDecimal() + state.ratio)));
        state.supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + state.ratio));
        if (state.demand <= 0 || state.supply <= 0){
            require(0 == 1, "SUSPENDED");
        }

        state.ratio = state.demand.divd(state.supply);
        state._prevLiquidity = _liquidity;
    }


    // we need this to be VIEW to use for priceChange calculations
    function _whatIfRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal view returns (int256){
        int256 ratio = state.ratio;
        int256 supply = state.supply;
        int256 demand = state.demand;
        int256 prevLiquidity = state._prevLiquidity;

        int256 _liquidity = getLiquidity(state);
        
        if (prevLiquidity == 0){
            supply = _liquidity.divd(SignedBaseMath.oneDecimal() + ratio);
            demand = supply.muld(ratio);
            prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - prevLiquidity;

        demand += (_longAmount + diff.muld(ratio.divd(SignedBaseMath.oneDecimal() + ratio)));
        supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + ratio));
        if (demand <= 0 || supply <= 0){
            require(0 == 1, "SUSPENDED");
        }

        return demand.divd(supply);
    }
}

interface IStakebleEvents {
    event LogUnstake(
        address indexed asset,
        address indexed staker,

        int256 slpAmount,
        int256 stakingProfit,
        int256 tradingProfit
    );
}

library StakebleEvents {
    event LogUnstake(
        address indexed asset,
        address indexed staker,

        int256 slpAmount,
        int256 stakingProfit,
        int256 tradingProfit
    );

    function logUnstakeData(address _asset,
                            address _staker,
                            int256 _slpAmount,
                            int256 _stakingProfit,
                            int256 _tradingProfit) internal {
        
        emit LogUnstake(_asset,
                        _staker,

                        _slpAmount,
                        _stakingProfit,
                        _tradingProfit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
}