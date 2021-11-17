// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldAdminRegistry.sol";
import "../../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/admininterfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IDexFactory.sol";
import "../../interfaces/IDexPair.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/TokenMarketBase.sol";
import "../library/TokenLoanData.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../token/GToken.sol";

contract TokenMarket is TokenMarketBase {
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeMath for uint256;

    IGovLiquidator govWorldLiquidator;
    IGovWorldProtocolRegistry govWorldProtocolRegistry;
    IGovWorldTierLevel govWorldTierLevel;
    IGovPriceConsumer govPriceConsumer;
    IGovWorldAdminRegistry govAdminRegistry;
    
    uint256 public loanId = 0;

    constructor(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel,
        address _govPriceConsumer,
        address _govAdminRegistry
    ) {
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(_govWorldProtocolRegistry);
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
        govPriceConsumer = IGovPriceConsumer(_govPriceConsumer);
        govAdminRegistry = IGovWorldAdminRegistry(_govAdminRegistry);

        loanId = 0;
    }

    receive() external payable {}

    //modifier: only liquidators can liqudate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            govWorldLiquidator.isLiquidateAccess(liquidator),
            "GTM: Not a Gov Liquidator."
        );
        _;
    }

    //modifier: only super admin can withdraw contract balance
    modifier onlySuperAdmin(address superAdmin) {
        require(
            govAdminRegistry.isSuperAdminAccess(superAdmin),
            "GTM: Not a Gov Super Admin."
        );
        _;
    }
    /**
    @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    */
     function createLoan(TokenLoanData.LoanDetails memory loanDetails)
        public
        {
        uint256 newLoanId = _getNextLoanId();

        require(loanDetails.stakedCollateralTokens.length == loanDetails.stakedCollateralAmounts.length,"GLM: Tokens and amounts length must be same");
        require(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType || TokenLoanData.LoanType.MULTI_TOKEN == loanDetails.loanType,"GLM: Invalid Loan Type");
        require(loanDetails.paybackAmount == 0, "GLM: payback amount should be zero");
        TierData memory  tierData = govWorldTierLevel.getTierDatabyGovBalance(msg.sender);
        require(tierData.singleToken || tierData.multiToken, "GLM: Not Eligible");
        if(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType) {//for single tokens collateral length must be one.
            require(loanDetails.stakedCollateralTokens.length == 1,"GLM: Multi-tokens not allowed in SINGLE TOKEN loan type.");
        }

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanDetails.stakedCollateralAmounts.length ; index ++){
            collatetralInBorrowed = collatetralInBorrowed.add(this.getAltCoinPriceinStable(loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]));
        }
        uint256 ltv  = this.calculateLTV(loanDetails.stakedCollateralAmounts, loanDetails.stakedCollateralTokens, loanDetails.borrowStableCoin, loanDetails.loanAmountInBorrowed);
        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);

        require(loanDetails.loanAmountInBorrowed <= maxLtv, "GLM: LTV not allowed.");
        require(ltv > 125, "GLM: Can not create loan at liquidation level.");

        //create uniquie loan hash for partial funding of loan
        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){
            require(govWorldProtocolRegistry.isTokenApproved(loanDetails.stakedCollateralTokens[i]),"GLM: One or more tokens not approved.");
            uint256 allowance =  IERC20(loanDetails.stakedCollateralTokens[i]).allowance(msg.sender, address(this));
            require( allowance >= loanDetails.stakedCollateralAmounts[i],"GLM: Transfer amount exceeds allowance.");
            //contract will now hold the staked collateral tokens
            IERC20(loanDetails.stakedCollateralTokens[i]).transferFrom(msg.sender, address(this), loanDetails.stakedCollateralAmounts[i]);

            // TODO uncomment gtoken functionality when on mainnet network
            // Market memory  market = govWorldProtocolRegistry.getSingleApproveToken(loanDetails.stakedCollateralTokens[i]);
            // GToken gtoken = GToken(market.gToken);
            
            // if(market.isSP) {
            //     gtoken.mint(loanDetails.borrower, loanDetails.stakedCollateralAmounts[i]);
            // }
        }
       loanOffersToken[newLoanId] = TokenLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.loanType,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            loanDetails.paybackAmount
        );
       
        emit LoanOfferCreatedToken(loanOffersToken[newLoanId]);
        loanId++;
    }


    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isInsured, isinsured true or false
     */
    function loanAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
        ) public {
        
        require(loanOffersToken[_loanIdAdjusted].loanType == TokenLoanData.LoanType.SINGLE_TOKEN || loanOffersToken[_loanIdAdjusted].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(loanOffersToken[_loanIdAdjusted].loanStatus == TokenLoanData.LoanStatus.INACTIVE, "GLM, Loan cannot adjusted");
        require(loanOffersToken[_loanIdAdjusted].borrower == msg.sender, "GLM, Only Borrow Adjust Loan");

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts.length ; index ++){
            collatetralInBorrowed = collatetralInBorrowed.add(this.getAltCoinPriceinStable(loanOffersToken[_loanIdAdjusted].borrowStableCoin, loanOffersToken[_loanIdAdjusted].stakedCollateralTokens[index], loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts[index]));
        }

        uint256 ltv  = this.calculateLTV(loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts, loanOffersToken[_loanIdAdjusted].stakedCollateralTokens, loanOffersToken[_loanIdAdjusted].borrowStableCoin, _newLoanAmountBorrowed);
        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);
        
        require(_newLoanAmountBorrowed <= maxLtv, "GLM: LTV not allowed.");
        require(ltv > 125, "GLM: can not adjust loan to liquidation level.");

        loanOffersToken[_loanIdAdjusted] = TokenLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            loanOffersToken[_loanIdAdjusted].loanType,
            _isPrivate,
            _isInsured,
            loanOffersToken[_loanIdAdjusted].stakedCollateralTokens,
            loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts,
            loanOffersToken[_loanIdAdjusted].borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            loanOffersToken[_loanIdAdjusted].paybackAmount
            
        );
        
        emit LoanOfferAdjustedToken(loanOffersToken[_loanIdAdjusted]);

    }


    /**
    @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public {
        require(loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.SINGLE_TOKEN || loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(loanOffersToken[_loanId].loanStatus == TokenLoanData.LoanStatus.INACTIVE , "GLM, Loan cannot be cancel");
        require(loanOffersToken[_loanId].borrower == msg.sender, "GLM, Only Borrow can cancel");
        for(uint i =0; i < loanOffersToken[_loanId].stakedCollateralTokens.length; i++) {
            IERC20(loanOffersToken[_loanId].stakedCollateralTokens[i]).transfer(msg.sender, loanOffersToken[_loanId].stakedCollateralAmounts[i]);
        }
        // delete loanOffersToken[_loanId];
        loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.CANCELLED;
        emit LoanOfferCancelToken(_loanId, msg.sender, loanOffersToken[_loanId].loanStatus);
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param loanIds array of loan ids which are going to be activated
    @param stableCoinAmounts amounts of stable coin requested by the borrower for the specific loan Id
    @param _autoSell if autosell, then loan will be autosell at the time of liquidation through the DEX
     */
    function activateLoan(uint256[] memory loanIds, uint256[] memory stableCoinAmounts, bool[] memory _autoSell) public {
        for(uint i=0; i < loanIds.length; i++) {
        require(loanOffersToken[loanIds[i]].loanType == TokenLoanData.LoanType.SINGLE_TOKEN 
            || loanOffersToken[loanIds[i]].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: invalid loan type");
        require(loanOffersToken[loanIds[i]].loanStatus == TokenLoanData.LoanStatus.INACTIVE, "GLM, not inactive");
        require(loanOffersToken[loanIds[i]].borrower != msg.sender, "GLM, self activation forbidden");
        require( loanOffersToken[loanIds[i]].loanAmountInBorrowed == stableCoinAmounts[i], "GLM, insufficient amount");
        require(loanIds.length == stableCoinAmounts.length && loanIds.length == _autoSell.length, "GLM: length not match");        
        
        uint apyFee = this.getAPYFee(loanOffersToken[loanIds[i]]);
        uint loanAmountAfterAPYFee = loanOffersToken[loanIds[i]].loanAmountInBorrowed.sub(apyFee);
        stableCoinAPYFeeFromToken[loanOffersToken[loanIds[i]].borrowStableCoin] =  stableCoinAPYFeeFromToken[loanOffersToken[loanIds[i]].borrowStableCoin].add(apyFee);
        
        require(apyFee + loanAmountAfterAPYFee == loanOffersToken[loanIds[i]].loanAmountInBorrowed, "GLM, invalid amount");
        //approving token from the front end
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transferFrom(msg.sender, address(this), apyFee);

        //loan amount send to borrower
        IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transferFrom(msg.sender, loanOffersToken[loanIds[i]].borrower, loanAmountAfterAPYFee);
        loanOffersToken[loanIds[i]].loanStatus = TokenLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(loanIds[i]);

        //activated loan id to the lender details
        activatedLoanOffersFull[loanIds[i]] =  TokenLoanData.LenderDetails({
		    lender: msg.sender,
            activationLoanTimeStamp: 1638178319,       //block.timestamp, //TODO change time to block.timestamp
            autoSell: _autoSell[i]
        });

        emit TokenLoanOfferActivated(loanIds[i], msg.sender, stableCoinAmounts[i],_autoSell[i]);
        }

    }

    function getTotalPaybackAmount(uint256 _loanId) external view returns (uint256, uint256) {

        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        
        uint256 loanTermLengthPassed = block.timestamp.sub(activatedLoanOffersFull[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays <= loanDetails.termsLengthInDays, "GLM: Loan already paybacked or liquidated.");
        
        uint256 apyFeeOriginal = this.getAPYFee(loanDetails);
        uint256 apyFeeAfterPlatformFeeCut = (apyFeeOriginal.mul(govWorldProtocolRegistry.getGovPlatformFee()).div(100));
        uint256 apyFeeBeforeLoanTermLengthEnd = ((loanDetails.loanAmountInBorrowed.mul(loanDetails.apyOffer).div(100)).div(365)).mul(loanTermLengthPassedInDays);
        
        uint256 unEarnedAPYFee = apyFeeAfterPlatformFeeCut.sub(apyFeeBeforeLoanTermLengthEnd);
        uint256 unEarnedAPYPercentageForLender = govWorldProtocolRegistry.getUnearnedAPYPercentageForLender();
        govWorldProtocolRegistry.getGovPlatformFee();
        return
        //lender also getting the some percentage of the unearned APY FEE //TODO to remove unEarnedPercentage or not??
        (loanDetails.loanAmountInBorrowed.add(apyFeeBeforeLoanTermLengthEnd).add(unEarnedAPYFee.mul(unEarnedAPYPercentageForLender).div(100)),apyFeeBeforeLoanTermLengthEnd);  
    }

    /**
    @dev payback loan full by the borrower to the lender
     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
       
        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  loanOffersToken[_loanId].stakedCollateralTokens.length ; i++){
            //contract will the repay staked collateral tokens to the borrower
           IERC20(loanOffersToken[_loanId].stakedCollateralTokens[i]).transfer(msg.sender, loanOffersToken[_loanId].stakedCollateralAmounts[i]);
           Market memory  market = govWorldProtocolRegistry.getSingleApproveToken(loanOffersToken[_loanId].stakedCollateralTokens[i]);
           GToken gtoken = GToken(market.gToken);
           if(market.isSP) {
                gtoken.burnFrom(loanOffersToken[_loanId].borrower, loanOffersToken[_loanId].stakedCollateralAmounts[i]);
            }
        }   
        TokenLoanData.LenderDetails memory lenderDetails = activatedLoanOffersFull[_loanId];
        (uint256 finalPaybackAmounttoLender,uint256 apyFeeBeforeLoanTermLengthEnd) = this.getTotalPaybackAmount(_loanId);
        stableCoinAPYFeeFromToken[address(this)] = stableCoinAPYFeeFromToken[address(this)].sub(apyFeeBeforeLoanTermLengthEnd);

        IERC20(loanOffersToken[_loanId].borrowStableCoin).transferFrom(loanOffersToken[_loanId].borrower, address(this), loanOffersToken[_loanId].loanAmountInBorrowed);
        IERC20(loanOffersToken[_loanId].borrowStableCoin).transfer(lenderDetails.lender, finalPaybackAmounttoLender);
        loanOffersToken[_loanId].paybackAmount = finalPaybackAmounttoLender;
        loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.CLOSED;
        emit FullTokensLoanPaybacked(_loanId, msg.sender, TokenLoanData.LoanStatus.CLOSED);
    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public {
    
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];

        require(loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.SINGLE_TOKEN 
            || loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.MULTI_TOKEN,
            "GLM: Invalid Loan Type");
        require(loanOffersToken[_loanId].borrower ==  msg.sender, "GLM, not borrower");
        require(loanOffersToken[_loanId].loanStatus == TokenLoanData.LoanStatus.ACTIVE, "GLM, not active");
        require(_paybackAmount > 0  && _paybackAmount <= loanOffersToken[_loanId].loanAmountInBorrowed, "GLM: Invalid Loan Amount");
        uint256 totalPayback = _paybackAmount.add(loanDetails.paybackAmount);
        if(totalPayback >=  loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        } 
        else
        {   
            uint256 remainingLoanAmount =  loanDetails.loanAmountInBorrowed.sub(totalPayback);
            uint256 newLtv  = this.calculateLTV(loanDetails.stakedCollateralAmounts, loanDetails.stakedCollateralTokens, loanDetails.borrowStableCoin, remainingLoanAmount);
            require(newLtv > 125, "GLM: new LTV exceeds threshold.");
            IERC20(loanDetails.borrowStableCoin).transferFrom(loanDetails.borrower, address(this), _paybackAmount);
            loanOffersToken[_loanId].paybackAmount = loanOffersToken[_loanId].paybackAmount.add(_paybackAmount);
            loanDetails.loanStatus = TokenLoanData.LoanStatus.ACTIVE;
            emit PartialTokensLoanPaybacked(loanId, _paybackAmount,  msg.sender);
        }     
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateLoan(uint256 _loanId) public onlyLiquidatorRole(msg.sender) {
        
        require(loanOffersToken[_loanId].loanStatus == TokenLoanData.LoanStatus.ACTIVE, "GLM, not active");
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        TokenLoanData.LenderDetails memory lenderDetails = activatedLoanOffersFull[_loanId];

        uint256 loanTermLengthPassed = block.timestamp.sub(lenderDetails.activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);

        // require(this.isLiquidationPending(_loanId) || (loanTermLengthPassedInDays > loanDetails.termsLengthInDays), "GTM: Liquidation Error"); TODO //uncomment this line

        if(lenderDetails.autoSell  == true) {
            for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){

                address[] memory path = new  address[](2);
                path[0] = loanDetails.stakedCollateralTokens[i];
                path[1] = loanDetails.borrowStableCoin;
                (uint amountIn, uint amountOut) = govPriceConsumer.getSwapData(loanDetails.stakedCollateralTokens[i],loanDetails.stakedCollateralAmounts[i],loanDetails.borrowStableCoin);
                
                IUniswapSwapInterface swapInterface = IUniswapSwapInterface(govPriceConsumer.getSwapInterface());
                IERC20(loanDetails.stakedCollateralTokens[i]).approve(address(swapInterface), amountIn);
                swapInterface.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOut, path, address(this), block.timestamp + 5 minutes);
                IERC20(loanDetails.borrowStableCoin).transfer(lenderDetails.lender, amountOut);
            }
            loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.LIQUIDATED;
            emit AutoLiquidated(_loanId, TokenLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral tokens to the lender
            for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){
                //contract will the repay staked collateral tokens to the borrower
                IERC20(loanDetails.stakedCollateralTokens[i]).transfer(lenderDetails.lender, loanDetails.stakedCollateralAmounts[i]);
                loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.LIQUIDATED;
                emit LiquidatedCollaterals(_loanId, TokenLoanData.LoanStatus.LIQUIDATED);
            } 
        }
    }

    //only super admin can withdraw coins
    function withdrawCoin( uint256 _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        require(_withdrawAmount <= address(this).balance, "GTM: Amount Invalid");
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }
    //only super admin can withdraw tokens
    function withdrawToken(address _tokenAddress, uint256 _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        require(_withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)), "GTM: Amount Invalid");
        IERC20(_tokenAddress).transfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    function getMaxLtv(uint256 collateralInBorrowed,address borrower)
        external
        view
        returns(uint256)
    {
        TierData memory tierData = govWorldTierLevel.getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed.mul(tierData.loantoValue).div(100));
    }

    /**
     * @dev Returns get all liquidated loan offers.
     * @param _status LoanStatus  ACTIVE=0, INACTIVE=1, CLOSED=2, CANCELLED=3, LIQUIDATED=4, TERMINATED=5
     */
    function getLoanOfferByStatus(uint256 _status)
        public
        view
        returns (uint256[] memory)
        {
        uint256[] memory activeOfferIds = new uint256[](loanOfferIds.length);
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            TokenLoanData.LoanDetails memory details = loanOffersToken[i];
            if (uint256(details.loanStatus) == _status) {
                activeOfferIds[i] = i;
            }
        }
        return activeOfferIds;
    }

    /**
    @dev function to get altcoin amount in stable coin.
    @param _stableCoin of the altcoin
    @param _altCoin address of the stable
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin, 
        address _altCoin, 
        uint256 _collateralAmount
        ) external view override returns(uint256) 
        {
    
        uint256 collateralAmountinStable;
        if(govPriceConsumer.isChainlinFeedEnabled(_altCoin) && govPriceConsumer.isChainlinFeedEnabled(_stableCoin)) {
               
                (int collateralChainlinkUsd, uint8 atlCoinDecimals) = govPriceConsumer.getLatestUsdPriceFromChainlink(_altCoin);
                uint256 collateralUsd = (uint256(collateralChainlinkUsd) * _collateralAmount).div(atlCoinDecimals); 
                (int priceFromChainLinkinStable, uint8 stableDecimals) = govPriceConsumer.getLatestUsdPriceFromChainlink(_stableCoin);
                collateralAmountinStable = collateralAmountinStable.add(collateralUsd.div(uint256(priceFromChainLinkinStable)).mul(stableDecimals));
                return collateralAmountinStable;
        }
        else {
                collateralAmountinStable = collateralAmountinStable.add(govPriceConsumer.getDexTokenPrice(_stableCoin, _altCoin, _collateralAmount));
                return collateralAmountinStable;
        } 
        
    }


    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral token
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId)
        external
        view
        override
        returns (uint256)
        {
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        //IERC20Extras stableDecimals = IERC20Extras(stkaedCollateralTokens);
        address borrowedToken = loanDetails.borrowStableCoin;
        return this.calculateLTV(stakedCollateralAmounts, stakedCollateralTokens, borrowedToken, loanDetails.loanAmountInBorrowed.sub(loanDetails.paybackAmount));
    }


  /**
    @dev Calculates LTV based on dex token price
    @param _stakedCollateralAmounts ttoken amounts
    @param _stakedCollateralTokens token contracts.
    @param _loanAmount total borrower loan amount in borrowed token.
     */
    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts, 
        address[] memory _stakedCollateralTokens, 
        address  _borrowedToken,
        uint256 _loanAmount
    )
        external
        view
        returns (uint256)
    {
        //IERC20Extras stableDecimals = IERC20Extras(stkaedCollateralTokens);
        uint256 totalCollateralInBorrowedToken;
        
        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
        
           uint256 priceofCollateral = this.getAltCoinPriceinStable(_borrowedToken, _stakedCollateralTokens[i], _stakedCollateralAmounts[i]);
           totalCollateralInBorrowedToken = totalCollateralInBorrowedToken.add(priceofCollateral); 
        }
        return
            (totalCollateralInBorrowedToken.mul(100)).div(
                _loanAmount
            );
    }
    
    /**
    @dev function to check the loan is pending for liqudation or not
    @param _loanId for which loan liquidation checking
     */
    function isLiquidationPending(uint256 _loanId)
        external
        view
        override
        returns (bool)
        {
        //get LTV
        uint256 ltv = this.getLtv(_loanId);

        if (ltv <= 125)
            //the collateral is now 125% / ok for liquidation
            return true;
        else return false;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in token case
     */
    function _getNextLoanId() private view returns (uint256) {
        return loanId.add(1);
    }

    /**
    // @dev returns the current loan id which will be assigned to the next createLoan
    //  */
    // function getCurrentLoanId() public view returns (uint256) {
    //     return loanId;
    // }

    // /**
    // @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
    //  */
    // function getActivatedLoanDetails(uint256 _loanId) public view returns(TokenLoanData.LenderDetails memory ) {
    //     return activatedLoanOffersFull[_loanId];
    // }

    // /**
    // @dev get loan details of the single or multi-token
    //  */
    // function getLoanOffersToken(uint256 _loanId) public view returns(TokenLoanData.LoanDetails memory) {
    //     return loanOffersToken[_loanId];
    // }

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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IGovLiquidator {

    event NewLiquidatorApproved(address indexed _newLiquidator, bool _liquidatorAccess);

    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGovWorldAdminRegistry {
    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;

        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    event NewAdminApproved(address indexed _newAdmin, address indexed _addByAdmin);
    event NewAdminApprovedByAll(address indexed _newAdmin, AdminAccess _adminAccess);
    event RemoveAdminForApprove(address indexed _admin, address indexed _removedByAdmin);
    event AdminRemovedByAll(address indexed _admin, address indexed _removedByAdmin);
    event EditAdminApproved(address indexed _admin,address indexed _editedByAdmin);
    event AdminEditedApprovedByAll(address indexed _admin, AdminAccess _adminAccess);
    event AddAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event EditAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event RemoveAdminRejected(address indexed _newAdmin, address indexed _rejectByAdmin);
    event SuperAdminOwnershipTransfer(address indexed _superAdmin, AdminAccess _adminAccess);
    
    function isAddGovAdminRole(address admin)external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns (bool);

    //using this function externally in other Smart Contracts
    function isEditAPYPerAccess(address admin) external view returns (bool);

     //using this function in loan smart contracts to withdraw network balance
    function isSuperAdminAccess(address admin) external view returns(bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

// Token Market Data
struct Market {
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
}

// NFT Data: Token on which Platform and what is the contract address
// struct NFTData {
//     bytes32 platform;
//     address nftContractAddress;
//     uint256 nftTokenId;
// }

interface IGovWorldProtocolRegistry {
    event TokensAdded(
        address indexed tokenAddress,
        Market indexed _marketData
    );
    event TokensUpdated(
        address indexed tokenAddress,
        Market indexed _marketData
    );
    // event NFTAdded(bytes32 nftPlatform, address indexed nftContract, uint256 indexed tokenId);
    event TokensRemoved(address indexed tokenAddress);
    // event BulkNFTAdded(
    //     bytes32 nftplatform,
    //     address[] indexed nftContracts,
    //     uint256[] indexed tokenIds
    // );
    // event NFTRemoved(
    //     bytes32 nftPlatform,
    //     address indexed nftContract,
    //     uint256 indexed nftTokenId
    // );
    // event BulkNFTRemoved(
    //     bytes32 nftplatform,
    //     address[] indexed nftContracts,
    //     uint256[] indexed tokenIds
    // );

    event SPWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    event BulkSpWalletAdded(
        address indexed tokenAddress,
        address indexed walletAddresses
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );
    event SPWalletRemoved(
        address indexed tokenAddress,
        address indexed walletAddress
    );

    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param  _market of the _tokenAddress
    */
    function addTokens(address[] memory _tokenAddress, Market[] memory _market)
        external;

    // /**
    // @dev function to add NFTs
    // @param  _nftPlatform type of the nft platfrom (opensea, rarible, binanceMarketplace etc)
    // @param  _nftContract contract address of the NFT Token
    // @param  _nftTokenId token id of the _nftcontract
    //  */

    // function addNFT(
    //     bytes32 _nftPlatform,
    //     address _nftContract,
    //     uint256 _nftTokenId
    // ) external;

    // /**
    // @dev function adding bulk nfts contract with their token IDs to the approvedNfts mapping
    // @param _nftPlatfrom  platform like opensea or rarible
    // @param _nftContracts  addresses of the nftContracts
    // @param _nftTokenIds token ids of the nftContracts
    //  */
    // function addBulkNFT(
    //     bytes32 _nftPlatfrom,
    //     address[] memory _nftContracts,
    //     uint256[] memory _nftTokenIds
    // ) external;

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
    function updateTokens(
        address[] memory _tokenAddress,
        Market[] memory _marketData
    ) external;

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetokens(address[] memory _removeTokenAddress) external;

    // /**
    //  *@dev function which remove NFT key from array and data from the mapping
    //  *@param _nftContract nft Contract address to be removed
    //  *@param _nftTokenId token id to be removed
    //  */

    // function removeNFT(address _nftContract, uint256 _nftTokenId) external;

    // /**
    // *@dev function which remove bulk NFTs key from array and data from mapping
    // @param _nftContract array of nft contract address to be removed
    // @param _nftTokenId array of token id to be removed
    //  */

    // function removeBulkNFTs(
    //     address[] memory _nftContract,
    //     uint256[] memory _nftTokenId
    // ) external;

    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress) external;

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external;

    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external;

    /**
     *@dev function to update the sp wallet
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _oldWalletAddress old wallet address to be updated
     *@param _newWalletAddress new wallet address
     */
    function updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) external;

    /**
    @dev external function update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) external;

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external;

    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getUnearnedAPYPercentageForGovLoanMarket()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns(uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getTokenMarket() external view returns(address[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

struct TierData {
        // Gov  Holdings to check if it lies in that tier
        uint256 govHoldings;
        // LTV percentage of the Gov Holdings
        uint8 loantoValue;
        //checks that if tier level have access
        bool govIntel;
        bool singleToken;
        bool multiToken;
        bool singleNFT;
        bool multiNFT;
        bool reverseLoan;
        bool _15PercentDiscount;
        bool _25PercentDiscount;
    }

interface IGovWorldTierLevel {
    
    event TierLevelAdded(bytes32 _newTierLevel, TierData _tierData);
    event TierLevelUpdated(bytes32 _updatetierLevel, TierData _tierData);
    event TierLevelRemoved(bytes32 _removedtierLevel);

    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external;

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external;

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel) external;

    /**
    @dev it should add and save tier levels at once
     */
    function saveTierLevel(bytes32[] memory _tierLevelKeys, TierData[] memory _newTierData)
    external;

    function getTierDatabyGovBalance(address userWalletAddress) external view returns (TierData memory _tierData);
    
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
interface IDexFactory {
    
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IDexPair {
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface  IERC20Extras{
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../library/TokenLoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ITokenMarket.sol";

abstract contract TokenMarketBase is ITokenMarket {
    //Load library structs into contract
    using TokenLoanData for *;
    using TokenLoanData for bytes32;
    using SafeMath for uint256;

    //saves the transaction hash of the create loan offer transaction as loanId
    mapping(uint256 => TokenLoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => TokenLoanData.LenderDetails) public activatedLoanOffersFull;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) borrowerloanOfferIds;

    //mapping address of lender => loan Ids
    mapping(address => uint256[]) lenderActivatedLoanIds;

    //mapping address stable => APY Fee in stable
    mapping(address => uint256) public stableCoinAPYFeeFromToken;

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(TokenLoanData.LoanDetails memory _loanDetails) external pure override returns(uint256) {
        // APY Fee Formula
        return ((_loanDetails.loanAmountInBorrowed.mul(_loanDetails.apyOffer).div(100)).div(365)).mul(_loanDetails.termsLengthInDays);  
    } 
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library TokenLoanData {
	using SafeMath for uint256;
	enum LoanStatus{
		ACTIVE,
		INACTIVE,
		CLOSED,
		CANCELLED,
		LIQUIDATED,
		TERMINATED
	}
	
	enum LoanType {
		SINGLE_TOKEN,
		MULTI_TOKEN
	}

	struct LenderDetails {
		address lender;
		uint256 activationLoanTimeStamp;
		bool autoSell;
	}
    
	struct LoanDetails {
		//total Loan Amount in Borrowed stable coin
		uint256 loanAmountInBorrowed;
		//user choose terms length in days TODO define validations
		uint256 termsLengthInDays;
		//borrower given apy percentage
		uint32 apyOffer;
		//Single-ERC20, Multiple staked ERC20,
		LoanType loanType;
		//private loans will not appear on loan market
		bool isPrivate;
		//will allow lender to fund in 25%, 50%, 75% or 100% or original loan amount
		// bool isPartialFunding; //REMOVED this variable was for lender.
		//Future use flag to insure funds as they go to protocol.
		bool isInsured;
		//single - or multi token collateral tokens wrt tokenAddress
		address[] stakedCollateralTokens;
		uint256[] stakedCollateralAmounts;
		address borrowStableCoin;
		//current status of the loan
		LoanStatus loanStatus;
		//borrower's address
		address borrower;

		uint256 paybackAmount;
    }


}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IGovPriceConsumer {

   
    event PriceFeedAdded(address indexed token, address usdPriceAggrigator, bool enabled, uint256 decimals);
    event PriceFeedAddedBulk(address[] indexed tokens, address[] chainlinkFeedAddress, bool[] enabled, uint256[] decimals);
    event PriceFeedRemoved(address indexed token);

    
    /**
     * Use chainlink PriceAggrigator to fetch prices of the already added feeds.
     */
    function getLatestUsdPriceFromChainlink(address priceFeedToken)  external view returns (int,uint8); 

    /**
    @dev multiple token prices fetch
    @param priceFeedToken multi token price fetch
    */
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken) external view returns (
            address[] memory tokens,  
            int[] memory prices,
            uint8[] memory decimals
        );

    function getNetworkPriceFromChainlinkinUSD() external view returns (int);

    function getSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view returns(uint,uint);

    function getNetworkCoinSwapData(
        address _collateralToken,
        uint256  _collateralAmount,
        address _borrowStableCoin
    ) external view returns(uint,uint);
    
    function getSwapInterface() external view returns (address);
    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(address _stable, address _alt, uint256 _amount) external view returns (uint256);

    //check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress) external view returns(bool);

    function getusdPriceAggrigators(address _tokenAddress) external view returns(ChainlinkDataFeed  memory);

    function getAllChainlinkAggiratorsContract() external view returns(address[] memory);

    function getAllGovAggiratorsTokens() external view returns(address[] memory);

    function WETHAddress() external view returns(address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IUniswapSwapInterface{
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

//SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./../interfaces/IERC20Extras.sol";

contract GToken is Ownable, ERC20, ERC20Burnable {

    using SafeMath for uint256;
    IERC20 spToken;
    IERC20Extras spTokenExtras;
    address private _tokenMarketContract;
    
    /**
     * Setup the initial supply and types of vesting schemas
     **/

    constructor(string memory _name, string memory _symbol, address _spToken) ERC20(_name, _symbol) {
        spToken  = IERC20(_spToken);
        spTokenExtras = IERC20Extras(_spToken);
    }

    function getMaxTotalSupply()
        public view returns (uint256)
    {
        return spToken.totalSupply();
    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        uint256 totalSupply = super.totalSupply();
        require(
            getMaxTotalSupply() >= totalSupply.add(amount),
            "Maximum supply exceeded!"
        );
        super._mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return spTokenExtras.decimals();
    }

}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "../library/TokenLoanData.sol";

interface ITokenMarket {
    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(TokenLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);

    event LoanOfferCreatedToken(TokenLoanData.LoanDetails _loanDetailsToken);

    event LoanOfferAdjustedToken(TokenLoanData.LoanDetails _loanDetails);

    event TokenLoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancelToken(
        uint256 loanId,
        address _borrower,
        TokenLoanData.LoanStatus loanStatus
    );

    event FullTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        TokenLoanData.LoanStatus loanStatus
    );

    event PartialTokensLoanPaybacked(
        uint256 loanId,
        uint256 paybackAmount,
        address _borrower
    );

    event AutoLiquidated(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);

    event LiquidatedCollaterals(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}