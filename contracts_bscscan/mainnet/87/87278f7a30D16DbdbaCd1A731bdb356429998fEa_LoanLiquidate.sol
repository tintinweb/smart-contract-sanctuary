/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


import "../core/State.sol";
import "../events/LoanClosingsEvents.sol";
import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../mixins/LiquidationHelper.sol";
import "../swaps/SwapsUser.sol";
import "../interfaces/ILoanPool.sol";
import "../mixins/RewardHelper.sol";

import "../openzeppelin/v2/access/Roles.sol";

import '../interfaces/IERC20.sol';
import '../interfaces/IWbase.sol';
import '../interfaces/IWbaseERC20.sol';
import '../external/uniswap/interfaces/IUniswapV2Router02.sol';

import '../external/uniswap/UniswapV2Library.sol';

contract LoanLiquidate is LoanClosingsEvents, VaultController, InterestUser, SwapsUser, LiquidationHelper, RewardHelper {
    uint256 constant internal MONTH = 365 days / 12;
    //0.00001 BTC, would be nicer in State.sol, but would require a redeploy of the complete protocol, so adding it here instead
    //because it's not shared state anyway and only used by this contract
    uint256 constant public paySwapExcessToBorrowerThreshold = 10000000000000;

    using Roles for Roles.Role;
    Roles.Role private _liquidators;


    // IUniswapV2Router02 private pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    // address private pancakeRouter  = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IUniswapV2Router02 private PancakeRouter;
    // address  private pancakeFactory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;


    address constant private WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant private BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address private tokenPaired;


    enum CloseTypes {
        Deposit,
        Liquidation
    }

    constructor() public {}


    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target
    )
        external
        onlyOwner
    {
        _setTarget(this.setParams.selector, target);
        _setTarget(this.getVersion.selector, target);
        _setTarget(this.setLiquidator.selector, target);
        _setTarget(this.renounceLiquidator.selector, target);
        _setTarget(this.isLiquidator.selector, target);
        _setTarget(this.liquidate.selector, target);
    }

    modifier onlyLiquidator() {
        require(isLiquidator(_msgSender()), "DOES_NOT_HAVE_LIQUIDATOR_ROLE");
        _;
    }

  

    function setParams(
        address _pancakeRouter,
        address _tokenPaired
    )
        external
        onlyOwner
    {
        PancakeRouter = IUniswapV2Router02(_pancakeRouter);
        tokenPaired = _tokenPaired;
    } 


    function getVersion()
        public view returns (uint)
    {
        return 2;
    }

    function setLiquidator(
        address liquidator
    )
        external
        onlyOwner
    {
        _liquidators.add(liquidator);
        
    }

    function renounceLiquidator(
        address liquidator
    )
        external
        onlyOwner
    {
        _liquidators.remove(liquidator);
        
    }

    function isLiquidator(address account) public view returns (bool) {
        return _liquidators.has(account);
    }
    /**
     * liquidates a loan. the caller needs to approve the closeAmount prior to calling.
     * Will not liquidate more than is needed to restore the desired margin (maintenance +5%).
     * @param loanId the ID of the loan to liquidate
     * @param receiver the receiver of the seized amount
     * @param closeAmount the amount to close in loanTokens
     * */
    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        nonReentrant
        onlyLiquidator
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            uint256 excessSeizedAmount,
            address seizedToken,
            uint256 profitAmount
        )
    {

        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        (uint256 currentMargin, ) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );


        if( loanLocal.endTimestamp<now && currentMargin > loanParamsLocal.maintenanceMargin ) {
            return _liquidateHealthy(
                loanId,
                receiver,
                closeAmount               
            );

        } else {

            return _liquidateUnhealthy(
                loanId,
                receiver,
                closeAmount
            );

        }

    }


    /**
     * internal function for liquidating a loan.
     * @param loanId the ID of the loan to liquidate
     * @param receiver the receiver of the seized amount
     * @param closeAmount the amount to close in loanTokens
     * */
    function _liquidateUnhealthy(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            uint256 excessSeizedAmount,
            address seizedToken,
            uint256 profitAmount
        )
    {
        excessSeizedAmount = 0;
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(loanParamsLocal.id != 0, "loanParams not exists");

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin <= loanParamsLocal.maintenanceMargin,
            "healthy position"
        );

        loanCloseAmount = closeAmount;

        //amounts to restore the desired margin (maintencance + 5%)
        (uint256 maxLiquidatable, uint256 maxSeizable,) = _getLiquidationAmounts(
            loanLocal.principal,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate
        );

        if (loanCloseAmount < maxLiquidatable) {
            seizedAmount = maxSeizable
                .mul(loanCloseAmount)
                .div(maxLiquidatable);
        } else if (loanCloseAmount > maxLiquidatable) {
            // adjust down the close amount to the max
            loanCloseAmount = maxLiquidatable;
            seizedAmount = maxSeizable;
        } else {
            seizedAmount = maxSeizable;
        }
        

        require(loanCloseAmount != 0, "nothing to liquidate");

        seizedToken = loanParamsLocal.collateralToken;


        profitAmount = _startArbitrage(
            loanId,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanCloseAmount,
            seizedAmount
        );


        // liquidator deposits the principal being closed
        _returnPrincipalWithCollateral(
            loanParamsLocal.loanToken,
            address(this),
            loanCloseAmount
        );

        // a portion of the principal is repaid to the lender out of interest refunded
        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );

        if (loanCloseAmount > loanCloseAmountLessInterest) {
            // full interest refund goes to the borrower
            _withdrawAsset(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmountLessInterest != 0) {
            // The lender always gets back an ERC20 (even wbase), so we call withdraw directly rather than
            // use the _withdrawAsset helper function
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }


        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            seizedAmount,
            0,  //collateralRepayingAmount
            collateralToLoanRate,
            0, // collateralToLoanSwapRate
            currentMargin,
            CloseTypes.Liquidation
        );
    }

    function _liquidateHealthy(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            uint256 excessSeizedAmount,
            address seizedToken,
            uint256 profitAmount

        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed"); // pass

        require(loanParamsLocal.id != 0, "loanParams not exists");// pass

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        

        loanCloseAmount = closeAmount;

        // //amounts to restore the desired margin (maintencance + 5%)
        (uint256 maxLiquidatable, uint256 maxSeizable,) = _getHealthyLiquidationAmounts(
            loanLocal.principal,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate
        );

        require(
            loanCloseAmount >= maxLiquidatable,
            "close amount must excess unhealthty position level"
        );


        // adjust down the close amount to the max
        loanCloseAmount = maxLiquidatable;


        seizedAmount = loanCloseAmount
            .mul(
                liquidationIncentivePercent
                    .add(10**20)
            );

        seizedAmount = seizedAmount
            .div(collateralToLoanRate)
            .div(100);


        excessSeizedAmount =  maxSeizable - seizedAmount;

        require(loanCloseAmount != 0, "nothing to liquidate");


        seizedToken = loanParamsLocal.collateralToken;
        
        profitAmount = _startArbitrage(
            loanId,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanCloseAmount,
            seizedAmount
        );



        // liquidator deposits the principal being closed
        _returnPrincipalWithCollateral(
            loanParamsLocal.loanToken,
            address(this),
            loanCloseAmount
        );

        // a portion of the principal is repaid to the lender out of interest refunded
        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );

        if (loanCloseAmount > loanCloseAmountLessInterest) {
            // full interest refund goes to the borrower
            _withdrawAsset(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmountLessInterest != 0) {
            // The lender always gets back an ERC20 (even wbase), so we call withdraw directly rather than
            // use the _withdrawAsset helper function
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }



        if (excessSeizedAmount != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(excessSeizedAmount);

            _withdrawAsset(
                seizedToken,
                loanLocal.borrower,
                excessSeizedAmount
            );

        }

        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            seizedAmount,
            excessSeizedAmount,  //collateralRepayingAmount
            collateralToLoanRate,
            0, // collateralToLoanSwapRate
            currentMargin,
            CloseTypes.Liquidation
        );
    }


    function _startArbitrage(
        bytes32 loanId,
        address loanToken,
        address collateralToken,
        uint256 loanCloseAmount,
        uint256 seizedAmount
    )
        private

        returns (
            uint256 profitAmount
        )
    {

        Loan storage loanLocal = loans[loanId];

        if (seizedAmount != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(seizedAmount);

            uint256 loanAmountOut = _swapCollateralToLoan(
                collateralToken,
                loanToken,
                seizedAmount,
                loanCloseAmount
             );

            require(loanAmountOut > loanCloseAmount, "Slippage eats all profit : To fix transfer collateral to protocol contract");

            profitAmount = loanAmountOut - loanCloseAmount;

            IERC20(loanToken).transfer(msg.sender, profitAmount);

        }


    }


    function _swapCollateralToLoan(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutRequired
    )
        private
        returns (uint256 loanAmountOut)
    {


        IERC20 LoanToken = IERC20(address(tokenIn));


        LoanToken.approve(address(PancakeRouter),amountIn);


        // For case in which WBNB is collateral
        if ( tokenIn == WBNB || tokenOut == WBNB ) {

            address[] memory wbnbpath = new address[](2);            

            wbnbpath[0] = tokenIn;
            wbnbpath[1] = tokenOut;

            loanAmountOut = PancakeRouter.swapExactTokensForTokens(
                amountIn, 
                amountOutRequired, 
                wbnbpath, 
                address(this), 
                block.timestamp
            )[1];

        } else {

            //best price via WBNB path
            address[] memory erc20path = new address[](3);


            erc20path[0] = tokenIn; 
            erc20path[1] = tokenPaired; //WBNB or BUSD
            erc20path[2] = tokenOut;

            loanAmountOut = PancakeRouter.swapExactTokensForTokens(
                amountIn, 
                amountOutRequired, 
                erc20path, 
                address(this), 
                block.timestamp
            )[2];
        }

  }





    
    /**
     * @dev computes the interest which needs to be refunded to the borrower based on the amount he's closing and either
     * subtracts it from the amount which still needs to be paid back (in case outstanding amount > interest) or withdraws the
     * excess to the borrower (in case interest > outstanding).
     * @param loanLocal the loan
     * @param loanParamsLocal the loan params
     * @param loanCloseAmount the amount to be closed (base for the computation)
     * @param receiver the address of the receiver (usually the borrower)
     * */
    function _settleInterestToPrincipal(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        address receiver //Notice
    )
        internal
        returns (uint256)
    {
        uint256 loanCloseAmountLessInterest = loanCloseAmount;

        //compute the interest which neeeds to be refunded to the borrower (because full interest is paid on loan )
        uint256 interestRefundToBorrower = _settleInterest(
            loanParamsLocal,
            loanLocal,
            loanCloseAmountLessInterest
        );

        uint256 interestAppliedToPrincipal;
        //if the outstanding loan is bigger than the interest to be refunded, reduce the amount to be paid back / closed by the interest
        if (loanCloseAmountLessInterest >= interestRefundToBorrower) {
            // apply all of borrower interest refund torwards principal
            interestAppliedToPrincipal = interestRefundToBorrower;

            // principal needed is reduced by this amount
            loanCloseAmountLessInterest -= interestRefundToBorrower;

            // no interest refund remaining
            interestRefundToBorrower = 0;
        } else {//if the interest refund is bigger than the outstanding loan, the user needs to get back the interest
            // principal fully covered by excess interest
            interestAppliedToPrincipal = loanCloseAmountLessInterest;

            // amount refunded is reduced by this amount
            interestRefundToBorrower -= loanCloseAmountLessInterest;

            // principal fully covered by excess interest
            loanCloseAmountLessInterest = 0;

            if (interestRefundToBorrower != 0) {
                // refund overage
                _withdrawAsset(
                    loanParamsLocal.loanToken,
                    receiver,
                    interestRefundToBorrower
                );
            }
        }

        //pay the interest to the lender
        //note: this is a waste of gas, because the loanCloseAmountLessInterest is withdrawn to the lender, too. It could be done at once.
        if (interestAppliedToPrincipal != 0) {
            // The lender always gets back an ERC20 (even wbase), so we call withdraw directly rather than
            // use the _withdrawAsset helper function
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                interestAppliedToPrincipal
            );
        }

        return loanCloseAmountLessInterest;
    }

    // The receiver always gets back an ERC20 (even wbase)
    function _returnPrincipalWithCollateral(
        address loanToken,
        address receiver,
        uint256 principalNeeded)
        internal
    {
        if (principalNeeded != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    address(this),
                    receiver,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wbaseToken), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wbaseToken.deposit.value(principalNeeded)();
                if (receiver != address(this)) {
                    vaultTransfer(
                        loanToken,
                        address(this),
                        receiver,
                        principalNeeded
                    );
                }
                if (msg.value > principalNeeded) {
                    // refund overage
                    Address.sendValue(
                        msg.sender,
                        msg.value - principalNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }
    
    /**
     * @dev checks if the amount of the asset to be transfered is worth the transfer fee
     * @param asset the asset to be transfered
     * @param amount the amount to be transfered
     * @return True if the amount is bigger than the threshold
     * */
    function worthTheTransfer(address asset, uint256 amount) internal returns (bool){
        (uint256 rbtcRate, uint256 rbtcPrecision) = IPriceFeeds(priceFeeds).queryRate(asset, address(wbaseToken));
        uint256 amountInRbtc = amount.mul(rbtcRate).div(rbtcPrecision);
        emit swapExcess(amountInRbtc > paySwapExcessToBorrowerThreshold, amount, amountInRbtc, paySwapExcessToBorrowerThreshold);
        return amountInRbtc > paySwapExcessToBorrowerThreshold;
    }
    




    // withdraws asset to receiver
    function _withdrawAsset(
        address assetToken,
        address receiver, //Notice
        uint256 assetAmount)
        internal
    {
        if (assetAmount != 0) {
            if (assetToken == address(wbaseToken)) {
                vaultEtherWithdraw(
                    receiver,
                    assetAmount
                );
            } else {
                vaultWithdraw(
                    assetToken,
                    receiver,
                    assetAmount
                );
            }
        }
    }

    function _finalizeClose(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        address _priceFeeds = priceFeeds;
        uint256 currentMargin;
        uint256 collateralToLoanRate;

        // this is still called even with full loan close to return collateralToLoanRate
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            )
        );
        assembly {
            if eq(success, 1) {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        }
        //// Note: We can safely skip the margin check if closing via closeWithDeposit or if closing the loan in full by any method ////
        require(
            closeType == CloseTypes.Deposit ||
            loanLocal.principal == 0 || // loan fully closed
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralCloseAmount,
            0,
            collateralToLoanRate,
            collateralToLoanSwapRate,
            currentMargin,
            closeType
        );
    }

    function _closeLoan(
        Loan storage loanLocal,
        uint256 loanCloseAmount)
        internal
        returns (uint256)
    {
        require(loanCloseAmount != 0, "nothing to close");

        if (loanCloseAmount == loanLocal.principal) {
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
        } else {
            loanLocal.principal = loanLocal.principal
                .sub(loanCloseAmount);
        }
    }

    function _settleInterest(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 closePrincipal)
        internal
        returns (uint256)
    {
        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.endTimestamp) {
            interestTime = loanLocal.endTimestamp;
        }

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            interestTime
        );

        uint256 owedPerDayRefund;
        if (closePrincipal < loanLocal.principal) {
            owedPerDayRefund = loanInterestLocal.owedPerDay
                .mul(closePrincipal)
                .div(loanLocal.principal);
        } else {
            owedPerDayRefund = loanInterestLocal.owedPerDay;
        }

        // update stored owedPerDay
        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .sub(owedPerDayRefund);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .sub(owedPerDayRefund);

        // update borrower interest
        uint256 interestRefundToBorrower = loanLocal.endTimestamp
            .sub(interestTime);
        interestRefundToBorrower = interestRefundToBorrower
            .mul(owedPerDayRefund);
        interestRefundToBorrower = interestRefundToBorrower
            .div(1 days);

        if (closePrincipal < loanLocal.principal) {
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
                .sub(interestRefundToBorrower);
        } else {
            loanInterestLocal.depositTotal = 0;
        }

        // update remaining lender interest values
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(closePrincipal);

        uint256 owedTotal = lenderInterestLocal.owedTotal;
        lenderInterestLocal.owedTotal = owedTotal > interestRefundToBorrower ?
            owedTotal - interestRefundToBorrower :
            0;

        return interestRefundToBorrower;
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralRepayingAmount,
        uint256 collateralToLoanRate,
        uint256 collateralToLoanSwapRate,
        uint256 currentMargin,
        CloseTypes closeType)
        internal
    {
        if (closeType == CloseTypes.Deposit) {
            emit CloseWithDeposit(
                loanLocal.borrower,                             // user (borrower)
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                msg.sender,                                     // closer
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        }  else { // closeType == CloseTypes.Liquidation
            emit Liquidate(
                loanLocal.borrower,                             // user (borrower)
                msg.sender,                                     // liquidator
                loanLocal.id,                                   // loanId
                loanLocal.lender,                               // lender
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralRepayingAmount,                       // collateralRepayingAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "./Objects.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../openzeppelin/v2/utils/ReentrancyGuard.sol";
import "../openzeppelin/v2/ownership/Ownable.sol";
import "../openzeppelin/v2/math/SafeMath.sol";
import "../interfaces/IWbaseERC20.sol";


contract State is Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    address public priceFeeds;                                                          // handles asset reference price lookups
    address public swapsImpl;                                                           // handles asset swaps using dex liquidity
    address public thaifiSwapContractRegistryAddress;                                       // contract registry address of the thaifi swap network

    mapping (bytes4 => address) public logicTargets;                                    // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                             // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                                  // loanParamsId => LoanParams

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;                // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;              // borrower => orderParamsId => Order

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;            // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest;     // lender => loanToken => LenderInterest object
    mapping (bytes32 => LoanInterest) public loanInterest;                              // loanId => LoanInterest object

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                           // implementations set
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                            // active loans set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;       // lender loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;     // borrow loans set
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;    // user loan params set

    address public feesController;                                                      // address controlling fee withdrawals

    uint256 public lendingFeePercent = 10**19; // 10% fee                               // fee taken from lender interest payments
    mapping (address => uint256) public lendingFeeTokensHeld;                           // total interest fees received and not withdrawn per asset
    mapping (address => uint256) public lendingFeeTokensPaid;                           // total interest fees withdraw per asset (lifetime fees = lendingFeeTokensHeld + lendingFeeTokensPaid)

    uint256 public tradingFeePercent = 15 * 10**16; // 0.15% fee                        // fee paid for each trade
    mapping (address => uint256) public tradingFeeTokensHeld;                           // total trading fees received and not withdrawn per asset
    mapping (address => uint256) public tradingFeeTokensPaid;                           // total trading fees withdraw per asset (lifetime fees = tradingFeeTokensHeld + tradingFeeTokensPaid)

    uint256 public borrowingFeePercent = 9 * 10**16; // 0.09% fee                       // origination fee paid for each loan
    mapping (address => uint256) public borrowingFeeTokensHeld;                         // total borrowing fees received and not withdrawn per asset
    mapping (address => uint256) public borrowingFeeTokensPaid;                         // total borrowing fees withdraw per asset (lifetime fees = borrowingFeeTokensHeld + borrowingFeeTokensPaid)

    uint256 public protocolTokenHeld;                                                   // current protocol token deposit balance
    uint256 public protocolTokenPaid;                                                   // lifetime total payout of protocol token

    uint256 public affiliateFeePercent = 30 * 10**18; // 30% fee share                  // fee share for affiliate program

    uint256 public liquidationIncentivePercent = 15 * 10**18; // 5% collateral discount  // discount on collateral for liquidators

    mapping (address => address) public loanPoolToUnderlying;                            // loanPool => underlying
    mapping (address => address) public underlyingToLoanPool;                            // underlying => loanPool
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                               // loan pools set

    mapping (address => bool) public supportedTokens;                                    // supported tokens for swaps

    uint256 public maxDisagreement = 5 * 10**18;                                         // % disagreement between swap rate and reference rate

    uint256 public sourceBuffer = 10000;                                                 // used as buffer for swap source amount estimations

    uint256 public maxSwapSize = 50 ether;                                               // maximum support swap size in BTC

    mapping(address => uint256) public borrowerNonce;                                    // nonce per borrower. used for loan id creation.

    uint256 public rolloverBaseReward = 16800000000000;                                  // Rollover transaction costs around 0.0000168 rBTC, it is denominated in wBASE
    uint256 public rolloverFlexFeePercent = 0.1 ether;                                   // 0.1%

    IWbaseERC20 public wbaseToken;
    address public protocolTokenAddress;

    uint256 public feeRebatePercent = 50 * 10**18; // 50% fee rebate                     // potocolToken reward to user, it is worth % of trading/borrowing fee

    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanClosingsEvents {

    // topic0: 0x6349c1a02ec126f7f4fc6e6837e1859006e90e9901635c442d29271e77b96fb6
    event CloseWithDeposit(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address closer,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    // topic0: 0x2ed7b29b4ca95cf3bb9a44f703872a66e6aa5e8f07b675fa9a5c124a1e5d7352
    event CloseWithSwap(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address collateralToken,
        address loanToken,
        address closer,
        uint256 positionCloseSize,
        uint256 loanCloseAmount,
        uint256 exitPrice, // one unit of collateralToken, denominated in loanToken
        uint256 currentLeverage
    );

    // topic0: 0x46fa03303782eb2f686515f6c0100f9a62dabe587b0d3f5a4fc0c822d6e532d3
    event Liquidate(
        address indexed user,
        address indexed liquidator,
        bytes32 indexed loanId,
        address lender,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralRepayingAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );
    
    event swapExcess(
        bool shouldRefund, 
        uint amount, 
        uint amountInRbtc, 
        uint threshold
    );
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../core/State.sol";


contract VaultController is State {
    using SafeERC20 for IERC20;

    event VaultDeposit(
        address indexed asset,
        address indexed from,
        uint256 amount
    );
    event VaultWithdraw(
        address indexed asset,
        address indexed to,
        uint256 amount
    );

    function vaultEtherDeposit(
        address from,
        uint256 value)
        internal
    {
        IWbaseERC20 _wbaseToken = wbaseToken;
        _wbaseToken.deposit.value(value)();

        emit VaultDeposit(
            address(_wbaseToken),
            from,
            value
        );
    }

    function vaultEtherWithdraw(
        address to, //notice
        uint256 value)
        internal
    {
        if (value != 0) {
            IWbaseERC20 _wbaseToken = wbaseToken;
            uint256 balance = address(this).balance;
            if (value > balance) {
                _wbaseToken.withdraw(value - balance);
            }
            Address.sendValue(to, value);

            emit VaultWithdraw(
                address(_wbaseToken),
                to,
                value
            );
        }
    }

    function vaultDeposit(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransferFrom(
                from,
                address(this),
                value
            );

            emit VaultDeposit(
                token,
                from,
                value
            );
        }
    }

    function vaultWithdraw(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransfer(
                to,
                value
            );

            emit VaultWithdraw(
                token,
                to,
                value
            );
        }
    }

    function vaultTransfer(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            if (from == address(this)) {
                IERC20(token).safeTransfer(
                    to,
                    value
                );
            } else {
                IERC20(token).safeTransferFrom(
                    from,
                    to,
                    value
                );
            }
        }
    }

    function vaultApprove(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
            IERC20(token).safeApprove(to, 0);
        }
        IERC20(token).safeApprove(to, value);
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../core/State.sol";
import "../mixins/VaultController.sol";
import "./FeesHelper.sol";


contract InterestUser is VaultController, FeesHelper {
    using SafeERC20 for IERC20;

    function _payInterest(
        address lender, // Notice
        address interestToken)
        internal
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[lender][interestToken];

        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay != 0 && lenderInterestLocal.updatedTimestamp != 0) {
            interestOwedNow = block.timestamp
                .sub(lenderInterestLocal.updatedTimestamp)
                .mul(lenderInterestLocal.owedPerDay)
                .div(86400);

            if (interestOwedNow > lenderInterestLocal.owedTotal)
	            interestOwedNow = lenderInterestLocal.owedTotal;

            if (interestOwedNow != 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal
                    .add(interestOwedNow);
                lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
                    .sub(interestOwedNow);

                _payInterestTransfer(
                    lender,
                    interestToken,
                    interestOwedNow
                );
            }
        }

        lenderInterestLocal.updatedTimestamp = block.timestamp;
    }

    function _payInterestTransfer(
        address lender, // Notice
        address interestToken,
        uint256 interestOwedNow)
        internal
    {
        uint256 lendingFee = interestOwedNow
            .mul(lendingFeePercent)
            .div(10**20);

        _payLendingFee(
            lender,
            interestToken,
            lendingFee
        );

        // transfers the interest to the lender, less the interest fee
        vaultWithdraw(
            interestToken,
            lender,
            interestOwedNow
                .sub(lendingFee)
        );
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";


contract LiquidationHelper is State {
    
    /**
     * computes how much needs to be liquidated in order to restore the desired margin (maintenance + 5%)
     * @param principal total borrowed amount (in loan tokens)
     * @param collateral the collateral (in collateral tokens)
     * @param currentMargin the current margin
     * @param maintenanceMargin the maintenance (minimum) margin
     * @param collateralToLoanRate the exchange rate from collateral to loan tokens
     * */
    function _getLiquidationAmounts(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate)
        internal
        view
        returns (uint256 maxLiquidatable, uint256 maxSeizable, uint256 incentivePercent)
    {
        incentivePercent = liquidationIncentivePercent;
        if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable, incentivePercent);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral, currentMargin);
        }

        uint256 desiredMargin = maintenanceMargin
            .add(5 ether); // 5 percentage points above maintenance

        // maxLiquidatable = ((1 + desiredMargin)*principal - collateralToLoanRate*collateral) / (desiredMargin - 0.05)
        maxLiquidatable = desiredMargin
            .add(10**20)
            .mul(principal)
            .div(10**20);
        maxLiquidatable = maxLiquidatable
            .sub(
                collateral
                    .mul(collateralToLoanRate)
                    .div(10**18)
            );
        maxLiquidatable = maxLiquidatable
            .mul(10**20)
            .div(
                desiredMargin
                    .sub(incentivePercent)
            );
        if (maxLiquidatable > principal) {
            maxLiquidatable = principal;
        }

        // maxSeizable = maxLiquidatable * (1 + incentivePercent) / collateralToLoanRate
        maxSeizable = maxLiquidatable
            .mul(
                incentivePercent
                    .add(10**20)
            );
        maxSeizable = maxSeizable
            .div(collateralToLoanRate)
            .div(100);
        if (maxSeizable > collateral) {
            maxSeizable = collateral;
        }

        return (maxLiquidatable, maxSeizable, incentivePercent);
    }


    /**
     * computes how much needs to be liquidated in order to restore the desired margin (maintenance + 5%)
     * @param principal total borrowed amount (in loan tokens)
     * @param collateral the collateral (in collateral tokens)
     * @param currentMargin the current margin
     * @param maintenanceMargin the maintenance (minimum) margin
     * @param collateralToLoanRate the exchange rate from collateral to loan tokens
     * */
    function _getHealthyLiquidationAmounts(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate)
        internal
        view
        returns (uint256 maxLiquidatable, uint256 maxSeizable, uint256 incentivePercent)
    {
        incentivePercent = liquidationIncentivePercent;

        if (collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable, incentivePercent);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral, currentMargin);
        }

        return (principal, collateral, incentivePercent);
    }



}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "../mixins/FeesHelper.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 sourceToDestSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this), // receiver
                address(this), // returnToSender
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );

        // will revert if swap size too large
        _checkSwapSize(sourceToken, sourceTokenAmountUsed);

        // will revert if disagreement found
        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool, // bypassFee
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        //addrs[0]: sourceToken
        //addrs[1]: destToken
        //addrs[2]: receiver
        //addrs[3]: returnToSender
        //addrs[4]: user
        //vals[0]:  minSourceTokenAmount
        //vals[1]:  maxSourceTokenAmount
        //vals[2]:  requiredDestTokenAmount

        require(vals[0] != 0 || vals[1] != 0, "min or max source token amount needs to be set");

        if (vals[1] == 0) {
            vals[1] = vals[0];
        }
        require(vals[0] <= vals[1], "sourceAmount larger than max");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) { // bypassFee
            if (vals[2] == 0) {
                // condition: vals[0] will always be used as sourceAmount

                tradingFee = _getTradingFee(vals[0]);
                if (tradingFee != 0) {
                    _payTradingFee(
                        addrs[4], // user
                        loanId,
                        addrs[0], // sourceToken
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .sub(tradingFee);
                }
            } else {
                // condition: unknown sourceAmount will be used

                tradingFee = _getTradingFee(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2]
                        .add(tradingFee);
                }
            }
        }
        
        require(loanDataBytes.length == 0, "invalid state");

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall_internal(
            addrs,
            vals
        );


        if (vals[2] == 0) {
            // there's no minimum destTokenAmount, but all of vals[0] (minSourceTokenAmount) must be spent
            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed
                    .add(tradingFee);
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than vals[1] (maxSourceTokenAmount)
            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4], // user
                    loanId, // loanId,
                    addrs[1], // destToken
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived
                    .sub(tradingFee);
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).internalSwap.selector,
            addrs[0], // sourceToken
            addrs[1], // destToken
            addrs[2], // receiverAddress
            addrs[3], // returnToSenderAddress
            vals[0],  // minSourceTokenAmount
            vals[1],  // maxSourceTokenAmount
            vals[2]   // requiredDestTokenAmount
        );

        bool success;
        (success, data) = swapsImpl.delegatecall(data);
        require(success, "swap failed");

        assembly {
            destTokenAmountReceived := mload(add(data, 32))
            sourceTokenAmountUsed := mload(add(data, 64))
        }
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256 destTokenAmount)
    {

        destTokenAmount = ISwapsImpl(swapsImpl).internalExpectedRate(
            sourceToken,
            destToken,
            sourceTokenAmount,
            thaifiSwapContractRegistryAddress
        );
    }

    function _checkSwapSize(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wbaseToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface ILoanPool {
    function tokenPrice()
        external
        view
        returns (uint256 price);

    function borrowInterestRate()
        external
        view
        returns (uint256);

    function totalAssetSupply()
        external
        view
        returns (uint256);
}

pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";

contract RewardHelper is State {
    using SafeMath for uint256;

    /**
     * @dev returns base fee + flex fee
     */
    function _getRolloverReward(address collateralToken, address loanToken, uint256 positionSize)
        view
        internal
        returns (uint256 reward)
    {

        uint256 positionSizeInCollateralToken =
            IPriceFeeds(priceFeeds).queryReturn(loanToken, collateralToken, positionSize);
        uint256 rolloverBaseRewardInCollateralToken =
            IPriceFeeds(priceFeeds).queryReturn(address(wbaseToken), collateralToken, rolloverBaseReward);

        return rolloverBaseRewardInCollateralToken.mul(2) // baseFee
                .add(positionSizeInCollateralToken.mul(rolloverFlexFeePercent).div(10 ** 20)); // flexFee = 0.1% of position size
    }
}

pragma solidity ^0.5.17;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


contract IERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface IWbase {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "./IWbase.sol";
// import "../openzeppelin/v2/token/ERC20/IERC20.sol";
import "./IERC20.sol";



contract IWbaseERC20 is IWbase, IERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;


interface IUniswapV2Router02 {
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
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
// pragma solidity ^0.6.6;


import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import "../../openzeppelin/v2/math/SafeMath.sol";


library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        // (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        // (uint reserve0, uint reserve1,) = IUniswapV2Pair(address(IUniswapV2Factory(factory).getPair(tokenA, tokenB))).getReserves();
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(address(IUniswapV2Factory(factory).getPair(tokenB, tokenA))).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./objects/LoanStruct.sol";
import "./objects/LoanParamsStruct.sol";
import "./objects/OrderStruct.sol";
import "./objects/LenderInterestStruct.sol";
import "./objects/LoanInterestStruct.sol";


contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

/**
 * @dev Library for managing loan sets
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;`.
 *
 */
library EnumerableBytes32Set {

    struct Bytes32Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) index;
        bytes32[] values;
    }

    /**
     * @dev Add an address value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return addBytes32(set, value);
    }

    /**
     * @dev Add a value to a set. O(1).
     * Returns false if the value was already in the set.
     */
    function addBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (!contains(set, value)){
            set.index[value] = set.values.push(value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes an address value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeAddress(Bytes32Set storage set, address addrvalue)
        internal
        returns (bool)
    {
        bytes32 value;
        assembly {
            value := addrvalue
        }
        return removeBytes32(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     * Returns false if the value was not present in the set.
     */
    function removeBytes32(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        if (contains(set, value)){
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set.values[lastIndex];

                // Move the last value to the index where the deleted value is
                set.values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted value
            delete set.index[value];

            // Delete the old entry for the moved value
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns an array with all values in the set. O(N).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Bytes32Set storage set, uint256 start, uint256 count)
        internal
        view
        returns (bytes32[] memory output)
    {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes32[](end-start);
        for (uint256 i; i < end-start; i++) {
            output[i] = set.values[i+start];
        }
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Bytes32Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.values.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return set.values[index];
    }
}

pragma solidity >=0.5.0 <0.6.0;


/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

    /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
    /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
    uint256 internal constant REENTRANCY_GUARD_FREE = 1;

    /// @dev Constant for locked guard state
    uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

    /**
    * @dev We use a single lock for the whole contract.
    */
    uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * If you mark a function `nonReentrant`, you should also
    * mark it `external`. Calling one `nonReentrant` function from
    * another is not supported. Instead, you can implement a
    * `private` function doing the actual work, and an `external`
    * wrapper marked as `nonReentrant`.
    */
    modifier nonReentrant() {
        require(reentrancyLock == REENTRANCY_GUARD_FREE, "nonReentrant");
        reentrancyLock = REENTRANCY_GUARD_LOCKED;
        _;
        reentrancyLock = REENTRANCY_GUARD_FREE;
    }

}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
    //Notice
    function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanStruct {
    struct Loan {
        bytes32 id;                 // id of the loan
        bytes32 loanParamsId;       // the linked loan params id
        bytes32 pendingTradesId;    // the linked pending trades id
        bool active;                // if false, the loan has been fully closed
        uint256 principal;          // total borrowed amount outstanding
        uint256 collateral;         // total collateral escrowed for the loan
        uint256 startTimestamp;     // loan start time
        uint256 endTimestamp;       // for active loans, this is the expected loan end time, for in-active loans, is the actual (past) end time
        uint256 startMargin;        // initial margin when the loan opened
        uint256 startRate;          // reference rate when the loan opened for converting collateralToken to loanToken
        address borrower;           // borrower of this loan
        address lender;             // lender of this loan
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanParamsStruct {
    struct LoanParams {
        bytes32 id;                 // id of loan params object
        bool active;                // if false, this object has been disabled by the owner and can't be used for future loans
        address owner;              // owner of this object
        address loanToken;          // the token being loaned
        address collateralToken;    // the required collateral token
        uint256 minInitialMargin;   // the minimum allowed initial margin
        uint256 maintenanceMargin;  // an unhealthy loan when current margin is at or below this value
        uint256 maxLoanTerm;        // the maximum term for new loans (0 means there's no max term)
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract OrderStruct {
    struct Order {
        uint256 lockedAmount;           // escrowed amount waiting for a counterparty
        uint256 interestRate;           // interest rate defined by the creator of this order
        uint256 minLoanTerm;            // minimum loan term allowed
        uint256 maxLoanTerm;            // maximum loan term allowed
        uint256 createdTimestamp;       // timestamp when this order was created
        uint256 expirationTimestamp;    // timestamp when this order expires
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding of asset
        uint256 owedPerDay;         // interest owed per day for all loans of asset
        uint256 owedTotal;          // total interest owed for all loans of asset (assuming they go to full term)
        uint256 paidTotal;          // total interest paid so far for asset
        uint256 updatedTimestamp;   // last update
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interest owed per day for loan
        uint256 depositTotal;       // total escrowed interest for loan
        uint256 updatedTimestamp;   // last update
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../../../interfaces/IERC20.sol";


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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */

    //Notice : payable added to fix
    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/FeesEvents.sol";
import "../mixins/ProtocolTokenUser.sol";


contract FeesHelper is State, ProtocolTokenUser, FeesEvents {
    using SafeERC20 for IERC20;

    // calculate trading fee
    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .div(10**20);
    }

    // calculate loan origination fee
    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .div(10**20);
    }
    
    /**
     * @dev settles the trading fee and pays the token reward to the user.
     * @param user the address to send the reward to
     * @param loanId the Id of the associated loan - used for logging only.
     * @param feeToken the address of the token in which the trading fee is paid
     * */
    function _payTradingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (tradingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .add(tradingFee);

            emit PayTradingFee(
                user,
                feeToken,
                loanId,
                tradingFee
            );
            
            //pay the token reward to the user
            _payFeeReward(
                user,
                loanId,
                feeToken,
                tradingFee
            );
        }
    }
    
    /**
     * @dev settles the borrowing fee and pays the token reward to the user.
     * @param user the address to send the reward to
     * @param loanId the Id of the associated loan - used for logging only.
     * @param feeToken the address of the token in which the borrowig fee is paid
     * @param borrowingFee the height of the fee
     * */
    function _payBorrowingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (borrowingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .add(borrowingFee);

            emit PayBorrowingFee(
                user,
                feeToken,
                loanId,
                borrowingFee
            );
            //pay the token reward to the user
            _payFeeReward(
                user,
                loanId,
                feeToken,
                borrowingFee
            );
        }
    }

    /**
     * @dev settles the lending fee (based on the interest). Pays no token reward to the user.
     * @param user the address to send the reward to
     * @param feeToken the address of the token in which the lending fee is paid
     * @param lendingFee the height of the fee
     * */
    function _payLendingFee(
        address user, // Notice
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (lendingFee != 0) {
            //increase the storage variable keeping track of the accumulated fees
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .add(lendingFee);

            emit PayLendingFee(
                user,
                feeToken,
                lendingFee
            );

             //// NOTE: Lenders do not receive a fee reward ////
        }
    }

    // settles and pays borrowers based on the fees generated by their interest payments
    function _settleFeeRewardForInterestExpense(
        LoanInterest storage loanInterestLocal,
        bytes32 loanId,
        address feeToken,
        address user,
        uint256 interestTime)
        internal
    {
        // this represents the fee generated by a borrower's interest payment
        uint256 interestExpenseFee = interestTime
            .sub(loanInterestLocal.updatedTimestamp)
            .mul(loanInterestLocal.owedPerDay)
            .div(86400)
            .mul(lendingFeePercent)
            .div(10**20);

        loanInterestLocal.updatedTimestamp = interestTime;

        if (interestExpenseFee != 0) {
            _payFeeReward(
                user,
                loanId,
                feeToken,
                interestExpenseFee
            );
        }
    }


    /**
     * @dev pays the potocolToken reward to user. The reward is worth 50% of the trading/borrowing fee.
     * @param user the address to send the reward to
     * @param loanId the Id of the associeated loan - used for logging only.
     * @param feeToken the address of the token in which the trading/borrowig fee was paid
     * @param feeAmount the height of the fee
     * */
    function _payFeeReward(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 feeAmount)
        internal
    {
        uint256 rewardAmount;
        address _priceFeeds = priceFeeds;
        //note: this should be refactored.
        //calculate the reward amount, querying the price feed
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).queryReturn.selector,
                feeToken,
                protocolTokenAddress, // price rewards using BZRX price rather than vesting token price
                feeAmount
                .mul(feeRebatePercent)
                .div(10**20)  
            )
        );
        assembly {
            if eq(success, 1) {
                rewardAmount := mload(add(data, 32))
            }
        }

        if (rewardAmount != 0) {
            address rewardToken;
            (rewardToken, success) = _withdrawProtocolToken(
                user,
                rewardAmount
            );
            if (success) {
                protocolTokenPaid = protocolTokenPaid
                    .add(rewardAmount);

                emit EarnReward(
                    user,
                    rewardToken,
                    loanId,
                    rewardAmount
                );
            }
        }
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IPriceFeeds {
    function queryRate(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 rate, uint256 precision);

    function queryPrecision(
        address sourceToken,
        address destToken)
        external
        view
        returns (uint256 precision);

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        external
        view
        returns (uint256 destAmount);

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        external
        view
        returns (uint256 sourceToDestSwapRate);

    function amountInEth(
        address Token,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256);
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract FeesEvents {
    event PayLendingFee(
        address indexed payer,
        address indexed token,
        uint256 amount
    );

    event PayTradingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event PayBorrowingFee(
        address indexed payer,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );

    event EarnReward(
        address indexed receiver,
        address indexed token,
        bytes32 indexed loanId,
        uint256 amount
    );
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/v2/token/ERC20/SafeERC20.sol";


contract ProtocolTokenUser is State {
    using SafeERC20 for IERC20;

    function _withdrawProtocolToken(
        address receiver,
        uint256 amount)
        internal
        returns (address, bool)
    {
        uint256 withdrawAmount = amount;

        uint256 tokenBalance = protocolTokenHeld;
        if (withdrawAmount > tokenBalance) {
            withdrawAmount = tokenBalance;
        }
        if (withdrawAmount == 0) {
            return (protocolTokenAddress, false);
        }

        protocolTokenHeld = tokenBalance
            .sub(withdrawAmount);

        IERC20(protocolTokenAddress).safeTransfer(
            receiver,
            withdrawAmount
        );

        return (protocolTokenAddress, true);
    }
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract SwapsEvents {
    event LoanSwap(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event ExternalSwap(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}

/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface ISwapsImpl {
    function internalSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed);

    function internalExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount,
        address optionalContractAddress)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
// pragma solidity ^0.6.6;


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

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
// pragma solidity ^0.6.6;


interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}