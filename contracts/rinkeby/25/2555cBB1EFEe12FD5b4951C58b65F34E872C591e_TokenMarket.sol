// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/admininterfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IDexFactory.sol";
import "../../interfaces/IDexPair.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/TokenMarketBase.sol";
import "../library/TokenLoanData.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../oracle/IGovPriceConsumerV3.sol";

contract TokenMarket is TokenMarketBase {
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeMath for uint256;

    IGovLiquidator govWorldLiquidator;
    IGovWorldProtocolRegistry govWorldProtocolRegistry;
    IGovWorldTierLevel govWorldTierLevel;
    IDexFactory dexFactory;
    IUniswapV2Router02 uniswapRouterv2;
    IGovPriceConsumerV3 govPriceConsumerV3;
    
    uint256 public loanId = 0;
    address uniswapDexFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    constructor(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _dexFactory,
        address _uinswapRouterv2,
        address _govWorldTierLevel,
        address _govPriceConsumerV3
    ) {
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(_govWorldProtocolRegistry);
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
        dexFactory = IDexFactory(_dexFactory);
        uniswapRouterv2 = IUniswapV2Router02(_uinswapRouterv2);
        govPriceConsumerV3 = IGovPriceConsumerV3(_govPriceConsumerV3);

        loanId = 0;
    }


    //modifier: only liquidators can liqudate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            govWorldLiquidator.isLiquidateAccess(liquidator),
            "GTM: Not a Gov Liquidator."
        );
        _;
    }

    /**
    @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER

    */
     function createLoanOfferToken(TokenLoanData.LoanDetails memory loanDetails)
        public
        {
        uint256 newLoanId = _getNextLoanId();

        require(loanDetails.stakedCollateralTokens.length == loanDetails.stakedCollateralAmounts.length,"GLM: Tokens and amounts length must be same");
        require(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType || TokenLoanData.LoanType.MULTI_TOKEN == loanDetails.loanType,"GLM: Invalid Loan Type");
        require(loanDetails.paybackAmount == 0, "GLM: payback amount should be zero");
        if(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType) {//for single tokens collateral length must be one.
            require(loanDetails.stakedCollateralTokens.length == 1,"GLM: Multi-tokens not allowed in SINGLE TOKEN loan type.");
        }

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanDetails.stakedCollateralAmounts.length ; index ++){
            collatetralInBorrowed+=  this.getTokenPriceInBorrowed(loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]);
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
            //TODO remove aloowance check
            uint256 allowance =  IERC20(loanDetails.stakedCollateralTokens[i]).allowance(msg.sender, address(this));
            require( allowance >= loanDetails.stakedCollateralAmounts[i],"GLM: Transfer amount exceeds allowance.");
            //contract will now hold the staked collateral tokens
            IERC20(loanDetails.stakedCollateralTokens[i]).transferFrom(msg.sender, address(this), loanDetails.stakedCollateralAmounts[i]);
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
    function tokenLoanOfferAdjusted(
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
            collatetralInBorrowed+=  this.getTokenPriceInBorrowed(loanOffersToken[_loanIdAdjusted].borrowStableCoin, loanOffersToken[_loanIdAdjusted].stakedCollateralTokens[index], loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts[index]);
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
    function tokenloanOfferCancel(uint256 _loanId) public {
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
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoanFullToken(uint256 _loanId, uint256 _stableCoinAmount, bool _autoSell) public {

        require(loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.SINGLE_TOKEN 
            || loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: invalid loan type");
        require(loanOffersToken[_loanId].loanStatus == TokenLoanData.LoanStatus.INACTIVE, "GLM, not inactive");
        require(loanOffersToken[_loanId].borrower != msg.sender, "GLM, self activation forbidden");
        require( loanOffersToken[_loanId].loanAmountInBorrowed == _stableCoinAmount, "GLM, insufficient amount");
        
        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
    
        uint256 apyFee = this.getAPYFee(loanOffersToken[_loanId]);
        uint256 loanAmountAfterAPYFee = loanOffersToken[_loanId].loanAmountInBorrowed.sub(apyFee);

        stableCoinAPYFeeFromToken[address(this)] += apyFee;

        //approving token from the front end
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        IERC20(loanOffersToken[_loanId].borrowStableCoin).transferFrom(msg.sender, address(this), apyFee);
        //loan amount send to borrower
        IERC20(loanOffersToken[_loanId].borrowStableCoin).transferFrom(msg.sender, loanOffersToken[_loanId].borrower, loanAmountAfterAPYFee); //TODO APY FEE CUT AFTER LOAN ACTIVATION
        loanOffersToken[_loanId].loanStatus = TokenLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(_loanId);

        //activated loan id to the lender details
        activatedLoanOffersFull[_loanId] =  TokenLoanData.LenderDetails({
		    lender: msg.sender,
            activationLoanTimeStamp: 1627894578, //TODO change time to block.timestamp
            autoSell: _autoSell
        });

        emit TokenLoanOfferActivated(_loanId, msg.sender, _stableCoinAmount,_autoSell);
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
       
        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  loanOffersToken[_loanId].stakedCollateralTokens.length ; i++){
            //contract will the repay staked collateral tokens to the borrower
           IERC20(loanOffersToken[_loanId].stakedCollateralTokens[i]).transfer(msg.sender, loanOffersToken[_loanId].stakedCollateralAmounts[i]);
        }   

        TokenLoanData.LenderDetails memory lenderDetails = activatedLoanOffersFull[_loanId];

        uint256 loanTermLengthPassed = block.timestamp - lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays <= loanOffersToken[_loanId].termsLengthInDays, "GLM: Loan already paybacked or liquidated.");
        
        uint256 apyFeeOriginal = this.getAPYFee(loanOffersToken[_loanId]);
        uint256 apyFeeBeforeLoanTermLengthEnd = ((loanOffersToken[_loanId].loanAmountInBorrowed.mul(loanOffersToken[_loanId].apyOffer).div(100)).div(365)).mul(loanTermLengthPassedInDays);
        
        uint256 unEarnedAPYFee =  apyFeeOriginal - apyFeeBeforeLoanTermLengthEnd;
        uint256 unEarnedAPYPerForLender = govWorldProtocolRegistry.getUnearnedAPYPercentageForLender();

        uint256 finalPaybackAmounttoLender = loanOffersToken[_loanId].loanAmountInBorrowed + apyFeeBeforeLoanTermLengthEnd + (unEarnedAPYFee.mul(unEarnedAPYPerForLender).div(100)); 
        //TODO GOV LOAN MARKET FEE CUT HERE
        // require(apyFeeBeforeLoanTermLengthEnd <= stableCoinAPYFeeFromToken[address(this)], "GLM: APY Fee should less APY Fee on LoanMarket");

        stableCoinAPYFeeFromToken[address(this)] -= apyFeeBeforeLoanTermLengthEnd;

        IERC20(loanOffersToken[_loanId].borrowStableCoin).transferFrom(loanOffersToken[_loanId].borrower, address(this), finalPaybackAmounttoLender);
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
        address borrower = msg.sender;

        require(loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.SINGLE_TOKEN 
            || loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.MULTI_TOKEN,
            "GLM: Invalid Loan Type");
        require(loanOffersToken[_loanId].borrower == borrower, "GLM, not borrower");
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
            loanOffersToken[_loanId].paybackAmount += _paybackAmount;
            loanDetails.loanStatus = TokenLoanData.LoanStatus.ACTIVE;
            emit PartialTokensLoanPaybacked(loanId, _paybackAmount, borrower);
        }
         
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateBorrowerCollateral(uint256 _loanId) public onlyLiquidatorRole(msg.sender) {
        

        require(this.isLiquidationPending(_loanId), "GTM: Liquidation Error");

        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        TokenLoanData.LenderDetails memory lenderDetails = activatedLoanOffersFull[_loanId];

        uint256 loanTermLengthPassed = block.timestamp - lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays > loanDetails.termsLengthInDays, "GTM: Collaterals not ready for liquidation");

        if(lenderDetails.autoSell  == true) {

            for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){

            address[] memory path = new address[](2);
            path[0] = loanDetails.stakedCollateralTokens[i];
            path[1] = loanDetails.borrowStableCoin;

            //get pair address of the altcoin and stable address 
            address pair = dexFactory.getPair(loanDetails.stakedCollateralTokens[i], loanDetails.borrowStableCoin);

            (uint112 reserveIn,  uint112 reserveOut, uint32 blockTimestampLast) = IDexPair(pair).getReserves();

            uint amountOut = uniswapRouterv2.getAmountOut(loanDetails.stakedCollateralAmounts[i], reserveIn, reserveOut);
            uint amountIn = uniswapRouterv2.getAmountIn(amountOut, reserveIn, reserveOut);

        
            IERC20(loanDetails.stakedCollateralTokens[i]).approve(address(uniswapRouterv2), amountIn);

            uniswapRouterv2.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOut, path, address(this), block.timestamp + 5 minutes);

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


    function getMaxLtv(uint256 collateralInBorrowed,address borrower)
        external
        view
        returns(uint256)
    {
        TierData memory  tierData = govWorldTierLevel.getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed.mul(tierData.loantoValue).div(100));
    }

    /**
     * @dev Returns ERC20 Token current all loan offer ids for a borrower
     */
    function getBorrowerLoanOfferIds(address borrower)
        public
        view
        returns (uint256[] memory)
    {
        return borrowerloanOfferIds[borrower];
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
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _altAmount address of alt
     */
    function getTokenPriceInBorrowed(
        address _stable,
        address _alt,
        uint256 _altAmount
        ) external view returns (uint256) {
        IDexPair pair = IDexPair(
            IDexFactory(dexFactory).getPair(_stable, _alt)
        );
        uint256 token0Decimals = IERC20Extras(pair.token0()).decimals();
        uint256 token1Decimals = IERC20Extras(pair.token1()).decimals();
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        //identify the stablecoin out  of token0 and token1
        if (pair.token0() == _stable) {
            
            //TODO Decimal problem
            uint256 resD = res0 * (10**token0Decimals);
            return (_altAmount.mul(resD.div(res1))); // return amount of alt needed to buy 1 stable
        } else {
            //TODO Decimal Problem
            uint256 resD = res1 * (10**token1Decimals);
            return (_altAmount.mul(resD.div(res0))); // return amount of alt needed to buy 1 stable
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
        //IERC20Extras stableDecimnals = IERC20Extras(stkaedCollateralTokens);
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
        //IERC20Extras stableDecimnals = IERC20Extras(stkaedCollateralTokens);
        uint256 totalCollateralInBorrowedToken;

        int priceFromChainlinkinUSD;
        int priceFromChainLinkinStable;
        
        uint priceFromDex;

        uint8 decimals;

        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
        
           if(govPriceConsumerV3.isChainlinFeedEnabled(_stakedCollateralTokens[i])){
               
                 (priceFromChainlinkinUSD, decimals) = govPriceConsumerV3.getLatestUsdPriceFromChainlink(_stakedCollateralTokens[i]);
                 (priceFromChainLinkinStable, decimals) = govPriceConsumerV3.getLatestUsdPriceFromChainlink(_borrowedToken);
                 totalCollateralInBorrowedToken = totalCollateralInBorrowedToken.add(uint256(priceFromChainLinkinStable));
            }
            else {

                priceFromDex = govPriceConsumerV3.getDexTokenPrice(uniswapDexFactory, _borrowedToken, _stakedCollateralTokens[i], _stakedCollateralAmounts[i]);
                totalCollateralInBorrowedToken = totalCollateralInBorrowedToken.add(priceFromDex);
            }
            // //get price of collateral token in terms of loan stable coin.
            // //get amounbt of alt to buy 1 stable
            // uint256 collateralPriceInBorrowed = this.getTokenPriceInBorrowed(
            //     _borrowedToken,
            //     _stakedCollateralTokens[i],
            //     _stakedCollateralAmounts[i]
            // );
           
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

        if (ltv.div(1e18) <= 125)
            //the collateral is now 125% / ok for liquidation
            return true;
        else return false;
    }

    function getLoansLength() public view returns (uint256) {
        return loanOfferIds.length;
    }

    //loans available to be shown on narket place
    function getInActiveLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == TokenLoanData.LoanStatus.INACTIVE) {
                count++;
            }
        }
        return count;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in token case
     */
    function _getNextLoanId() public view returns (uint256) {
        return loanId.add(1);
    }

    /**
    @dev returns the current loan id which will be assigned to the next createloanoffer
     */
    function getCurrentLoanId() public view returns (uint256) {
        return loanId;
    }

    /**
    @dev get loan details of the single or multi-token
     */
    function getLoanOffersToken(uint256 _loanId) public view returns(TokenLoanData.LoanDetails memory) {
        return loanOffersToken[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId) public view returns(TokenLoanData.LenderDetails memory ) {
        return activatedLoanOffersFull[_loanId];
    }

    /**
    @dev get lenders activated loan Ids 
    @param _lender address of the lender to check if activated loan ids exists*/
    function getLenderActivatedLoanOfferIds(address _lender) public view returns(uint256[] memory) {
       return lenderActivatedLoanIds[_lender];
    }

    /**
    @dev get activated loan offers count */
    function getActiveLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == TokenLoanData.LoanStatus.ACTIVE) {
                count++;
            }
        }
        return count;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 struct LiquidatorAccess {
        bool liquidateRole;
    }

interface IGovLiquidator {

    event NewLiquidatorApproved(address indexed _newLiquidator, LiquidatorAccess _liquidatorRole);

    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

}

// SPDX-License-Identifier: MIT

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
        address[] indexed tokenAddress,
        Market[] indexed _marketData
    );
    event TokensUpdated(
        address[] indexed tokenAddress,
        Market[] indexed _marketData
    );
    // event NFTAdded(bytes32 nftPlatform, address indexed nftContract, uint256 indexed tokenId);
    event TokensRemoved(address[] indexed tokenAddress);
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
        address[] indexed walletAddresses
    );

    event SPWalletUpdated(
        address indexed tokenAddress,
        address indexed oldWalletAddress,
        address indexed newWalletAddress
    );

    event BulkSpWAlletUpdated(
        address indexed tokenAddress,
        address[] indexed oldWalletAddress,
        address[] indexed newWalletAddress
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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IDexFactory {
    
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  IERC20Extras{
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../library/TokenLoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ITokenMarket.sol";

abstract contract TokenMarketBase is ITokenMarket {
    //Load library structs into contract
    using TokenLoanData for *;
    using TokenLoanData for bytes32;
    using SafeMath for uint256;

    //saves the transaction hash of the create loan offer transaction as loanId
    //saves information in loanOffers when createLoanOffer is called
    //TODO create mapping borrower.address-> loanId=> LoanDetails
    mapping(uint256 => TokenLoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => TokenLoanData.LenderDetails) public activatedLoanOffersFull;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) borrowerloanOfferIds;

    //mapping address of lender to the loan Ids
    mapping(address => uint256[]) lenderActivatedLoanIds;

    //mapping address stable to the APY Fee of stable
    mapping(address => uint256) public stableCoinAPYFeeFromToken;

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(TokenLoanData.LoanDetails memory _loanDetails) external pure returns(uint256) {
        // APY Fee Formula
        return ((_loanDetails.loanAmountInBorrowed.mul(_loanDetails.apyOffer).div(100)).div(365)).mul(_loanDetails.termsLengthInDays);

        
    }

    
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

 struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IGovPriceConsumerV3 {

   
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
   
    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(address _dexFactory, address _stable, address _alt, uint256 _amount) external view returns (uint256);

    //check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../library/TokenLoanData.sol";

interface ITokenMarket {
    function getLtv(uint256 _loanId)
        view
        external
        returns(uint256);

    function isLiquidationPending(uint256 _loanId)
        view 
        external
        returns(bool);

    event LoanOfferCreatedToken(
       TokenLoanData.LoanDetails _loanDetailsToken
    );

    event LoanOfferAdjustedToken(
        TokenLoanData.LoanDetails _loanDetails

    );

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
    
    event LiquidatedCollaterals(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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

