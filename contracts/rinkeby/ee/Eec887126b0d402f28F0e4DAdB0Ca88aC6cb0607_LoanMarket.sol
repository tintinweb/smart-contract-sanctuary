// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./LoanData.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./admin/GovWorldAdminRegistry.sol";
import "./admin/GovWorldProtocolRegistry.sol";
import "./admin/GovWorldTierLevel.sol";
import "./interfaces/IDexFactory.sol";
import "./interfaces/IDexPair.sol";
import "./interfaces/IERC20Extras.sol";
import "./LoanMarketBase.sol";
import "hardhat/console.sol";

contract LoanMarket is LoanMarketBase {
    //Load library structs into contract
    using LoanData for *;
    using LoanData for bytes32;
    using SafeMath for uint256;
    using SafeMath for  uint8;

    GovWorldAdminRegistry govWorldAdminRegistry;
    GovWorldProtocolRegistry govWorldProtocolRegistry;
    GovWorldTierLevel govWorldTierLevel;

    IDexFactory dexFactory;
    uint256 public loanId = 0;
    uint256 public partialLoanId = 1;

    //mapping address stable to the APY Fee of stable
    mapping(address => uint256) public stableCoinAPYFee;

    //mapping address of the borrower to the partial Amount funded
    mapping(address => uint256) public amountFundedPartial;
 
    constructor(
        address _govWorldAdminRegistry,
        address _govWorldProtocolRegistry,
        address _dexFactory,
        address _govWorldTierLevel
    ) {
        govWorldAdminRegistry = GovWorldAdminRegistry(_govWorldAdminRegistry);
        govWorldProtocolRegistry = GovWorldProtocolRegistry(_govWorldProtocolRegistry);
        govWorldTierLevel = GovWorldTierLevel(_govWorldTierLevel);
        dexFactory = IDexFactory(_dexFactory);
        loanId = 0;
    }

    

    /**
    @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER

    */
     function createLoanOfferToken(LoanData.LoanDetails memory loanDetails)
        public
        {
        uint256 newLoanId = _getNextLoanId();

        require(loanDetails.stakedCollateralTokens.length == loanDetails.stakedCollateralAmounts.length,"GLM: Tokens and amounts length must be same");
        require(LoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType || LoanData.LoanType.MULTI_TOKEN == loanDetails.loanType,"GLM: Invalid Loan Type");
        if(LoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType) {//for single tokens collateral length must be one.
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


        LoanData.LoanDetails memory loanDetailsERC20 = LoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.loanType,
            loanDetails.isPrivate,
            loanDetails.isPartialFunding,
            loanDetails.isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            LoanData.LoanStatus.INACTIVE,
            msg.sender
        );
        
        loanOffersToken[newLoanId]  = loanDetailsERC20;
        //openLoanOfferKeys.push(openLoanOfferKeys);
       
        emit LoanOfferCreatedToken(loanOffersToken[newLoanId]);

        _incrementLoanId();
    }

    /**
    @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    @param _loanAmountInBorrowed, loan amount borrower want to offer to the lender
    @param _termsLengthInDays, loan term countdown
    @param _apyOffer, APY Percentage offer to the lender
    @param _loanType, Type of the loan SINGLE_NFT || MULTI_NFT
    @param _isPrivate, Loan Private can be share through random link privately or Public which will show on loan marketplace
    @param _isPartialFunding, borrower allow lender for the activation of loan partially or fully funded
    @param _isInsured, is an insured or not True || False
    @param _stakedCollateralERC721, addressed of the staked collateral approved by the GOV Admins
    @param _stakedCollateralTokenId, the amount of the staked colletral borrower is staking
    @param _stakedNFTPrice Price of the NFT token fetch from the OPENSEA || RARIBLE ||FOUNDATION APP (AIRNFT Marketplace in case of Binance Smart Chain)
    @param _borrowStableCoin any stable coin address USDT || DAI || USDC || TUSD || PAX || BUSD

     */
    function createLoanOfferNFT(
        uint256 _loanAmountInBorrowed,
        uint32 _termsLengthInDays,
        uint32 _apyOffer,
        LoanData.LoanType _loanType,
        bool _isPrivate,
        bool _isPartialFunding,
        bool _isInsured,
        address[] memory _stakedCollateralERC721,
		uint256[] memory _stakedCollateralTokenId,
		uint256[] memory _stakedNFTPrice,
        address _borrowStableCoin
        )
        public
        {
        uint256 newLoanId = _getNextLoanId(); // TODO

       
        require((_stakedCollateralERC721.length == _stakedCollateralTokenId.length) == (_stakedCollateralTokenId.length == _stakedNFTPrice.length),"GLM: NFT Address, TokenIds and prices length must be same");
        require(LoanData.LoanType.SINGLE_NFT  == _loanType || LoanData.LoanType.MULTI_NFT == _loanType,"GLM: Invalid Loan Type");
        if(LoanData.LoanType.SINGLE_NFT  == _loanType) { //for single tokens collateral length must be one.
            require(_stakedCollateralERC721.length == 1,"GLM: MULTI-NFTs not allowed in SINGLE NFT loan type.");
        }
        
        require(this._isLtvUnderTier(newLoanId), "GLM: LTV Exceeds Tier Level Limit");

        //create uniquie loan hash
        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  _stakedCollateralERC721.length ; i++){
            //contract will now hold the staked collateral tokens
            IERC721(_stakedCollateralERC721[i]).safeTransferFrom(msg.sender, address(this), _stakedCollateralTokenId[i]);
        }
        LoanData.LoanDetailsERC721 memory LoanDetailsERC721 = LoanData.LoanDetailsERC721(
            _stakedCollateralERC721,
            _stakedCollateralTokenId,
            _stakedNFTPrice,
            _loanAmountInBorrowed,
            _apyOffer,
            _loanType,
            LoanData.LoanStatus.INACTIVE,
            _termsLengthInDays,
            _isPrivate,
            _isPartialFunding,
            _isInsured,
            msg.sender,
            _borrowStableCoin
        );
        
        loanOffersNFT[newLoanId]  = LoanDetailsERC721;
        //openLoanOfferKeys.push(openLoanOfferKeys);
       
        emit LoanOfferCreatedNFT(
            newLoanId,
            msg.sender, 
            _stakedCollateralERC721, 
            _stakedCollateralTokenId,
            _stakedNFTPrice, 
            _isPrivate,
            _isPartialFunding,
            _borrowStableCoin
        );

        _incrementLoanId();
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _loanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isPartialFunding, if borrower is setting the option of partial funding for the lender, True means partial funding allowed otherwise full funding from the lender
    @param _isInsured, isinsured true or false
     */
    function tokenLoanOfferAdjusted(
        uint256 _loanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isPartialFunding,
        bool _isInsured
        ) public {
        
        require(loanOffersToken[_loanIdAdjusted].loanType == LoanData.LoanType.SINGLE_TOKEN || loanOffersToken[_loanIdAdjusted].loanType == LoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(_isTokenLoanIDExists(_loanIdAdjusted), "GLM, Loan not existed, Loan cannot be adjusted");
        require(_isLoanInactive(_loanIdAdjusted), "GLM, Loan is Active, cannot be adjusted");
        require(loanOffersToken[_loanIdAdjusted].borrower == msg.sender, "GLM, Only Borrow Adjust Loan");
        
        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts.length ; index ++){
            collatetralInBorrowed+=  this.getTokenPriceInBorrowed(loanOffersToken[_loanIdAdjusted].borrowStableCoin, loanOffersToken[_loanIdAdjusted].stakedCollateralTokens[index], loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts[index]);
        }

        uint256 ltv  = this.calculateLTV(loanOffersToken[_loanIdAdjusted].stakedCollateralAmounts, loanOffersToken[_loanIdAdjusted].stakedCollateralTokens, loanOffersToken[_loanIdAdjusted].borrowStableCoin, _newLoanAmountBorrowed);
        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);

        require(collatetralInBorrowed <= maxLtv, "GLM: LTV not allowed.");
        require(ltv > 125, "GLM: Can not adjust loan to liquidation level.");

        LoanData.LoanDetails memory oldLoanDetails = loanOffersToken[_loanIdAdjusted];

        loanOffersToken[_loanIdAdjusted] = LoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            oldLoanDetails.loanType,
            _isPrivate,
            _isPartialFunding,
            _isInsured,
            oldLoanDetails.stakedCollateralTokens,
            oldLoanDetails.stakedCollateralAmounts,
            oldLoanDetails.borrowStableCoin,
            LoanData.LoanStatus.INACTIVE,
            msg.sender
            
        );
        
        emit LoanOfferAdjustedToken(loanOffersToken[_loanIdAdjusted]);

    }


    /**
    @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function tokenloanOfferCancel(uint256 _loanId) public {

        require(loanOffersToken[_loanId].loanType == LoanData.LoanType.SINGLE_TOKEN || loanOffersToken[_loanId].loanType == LoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(_isTokenLoanIDExists(_loanId), "GLM, Loan not existed, Loan cannot be cancel");
        require(_isLoanInactive(_loanId), "GLM, cannot be cancel");
        require(loanOffersToken[_loanId].borrower == msg.sender, "GLM, Only Borrow can cancel Loan");

        LoanData.LoanDetails memory loanDetailsToken = loanOffersToken[_loanId];
        
        for(uint i =0; i < loanDetailsToken.stakedCollateralTokens.length; i++) {
            
            IERC20(loanDetailsToken.stakedCollateralTokens[i]).transfer(msg.sender, loanDetailsToken.stakedCollateralAmounts[i]);

        }
        
        // delete loanOffersToken[_loanId];
        loanOffersToken[_loanId].loanStatus = LoanData.LoanStatus.CANCELLED;

        emit LoanOfferCancelToken(_loanId, msg.sender, loanOffersToken[_loanId].loanStatus);

        
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoanFullToken(uint256 _loanId, uint256 _stableCoinAmount, bool _autoSell) public {

        address lenderAddress = msg.sender;

        LoanData.LoanDetails memory loanDetailsToken = loanOffersToken[_loanId];

        require(loanDetailsToken.loanType == LoanData.LoanType.SINGLE_TOKEN || loanDetailsToken.loanType == LoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(_isTokenLoanIDExists(_loanId), "GLM, Loan not existed, Loan cannot be adjusted");
        require(loanDetailsToken.loanStatus == LoanData.LoanStatus.INACTIVE, "GLM, Loan Should be InActive at this stage.");
        require(loanDetailsToken.borrower != lenderAddress, "GLM, Only Lenders Can Active Loan");
        require(loanDetailsToken.loanAmountInBorrowed == _stableCoinAmount, "GLM, stable coin amount must equal to borrower loan amount requested");
        require(loanDetailsToken.isPartialFunding == false, "GLM, Not a 100% Full Loan Offer");
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        
        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
    
        uint256 apyFee = _getAPYFee(_loanId);
        uint256 LoanAmountAfterAPYFee = loanDetailsToken.loanAmountInBorrowed.sub(apyFee);

        stableCoinAPYFee[loanDetailsToken.borrowStableCoin] += apyFee;

        //approving token from the front end
        IERC20(loanDetailsToken.borrowStableCoin).transferFrom(lenderAddress, address(this), apyFee);
        IERC20(loanDetailsToken.borrowStableCoin).transferFrom(lenderAddress, loanDetailsToken.borrower, LoanAmountAfterAPYFee); //TODO APY FEE CUT AFTER LOAN ACTIVATION
        loanOffersToken[_loanId].loanStatus = LoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[lenderAddress].push(_loanId);

        //activated loan id to the lender details
        activatedLoanOffersFull[_loanId] =  LoanData.LenderDetails({
		lender: lenderAddress,
		activationLoanTimeStamp: block.timestamp + (loanDetailsToken.termsLengthInDays * 1 days),
	    autoSell: _autoSell
        });

        emit TokenLoanOfferActivated(_loanId, lenderAddress, loanDetailsToken.loanAmountInBorrowed, loanDetailsToken.termsLengthInDays, loanDetailsToken.apyOffer, loanDetailsToken.stakedCollateralTokens, loanDetailsToken.stakedCollateralAmounts, loanDetailsToken.loanType, loanDetailsToken.isPrivate, loanDetailsToken.isPartialFunding, loanDetailsToken.borrowStableCoin);

    }

    /**
    @dev partial function to fund loan amount to borrower partially 25%, 50%, 75%
     */
    // function partialLoanOfferToken(uint256 _parentLoanId, uint256 _partialAmount) public {

    //     LoanData.LoanDetails memory partialLoanDetails = loanOffersToken[_parentLoanId];
    //     address lenderAddress = msg.sender;

    //     // require()
    //     require(partialLoanDetails.loanType == LoanData.LoanType.SINGLE_TOKEN || partialLoanDetails.loanType == LoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
    //     require(_isTokenLoanIDExists(_parentLoanId), "GLM, Loan not existed, Loan cannot be adjusted");
    //     require(partialLoanDetails.borrower != lenderAddress, "GLM, Only Lenders Can Active Loan");
    //     require(partialLoanDetails.isPartialFunding == true, "GLM, Not a partial Loan Offer");
    //     require(partialLoanDetails.loanStatus == LoanData.LoanStatus.INACTIVE, "GLM, Loan Should be InActive at this stage.");

    //     uint256 _25PercentofLoan = (partialLoanDetails.loanAmountInBorrowed.mul(25)).div(100);
    //     uint256 _50PercentofLoan = (partialLoanDetails.loanAmountInBorrowed.mul(50)).div(100);
    //     uint256 _75PercentofLoan = (partialLoanDetails.loanAmountInBorrowed.mul(75)).div(100);

    //     require(
    //         _partialAmount == _25PercentofLoan ||
    //         _partialAmount == _50PercentofLoan ||
    //         _partialAmount == _75PercentofLoan, "GLM, Loan Amount Should be Partial 25% or 50% or 75%");

    //     if(_25PercentofLoan == _partialAmount) {

    //         partialLoanId;
    //         //partial loan offer mapping
    //         partialLoanOffers[_parentLoanId].push(partialLoanId);


    //     }

    //     if(_50PercentofLoan == _partialAmount) {
            
    //     }

    //     if(_75PercentofLoan == _partialAmount) {

    //     }
    // }

    /**
    @dev payback loan full by the borrower to the lender

     */

    function loanPaybackBeforeTermEnd(uint256 _loanId) public {

        LoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        address borrower = msg.sender;

        // require()
        require(loanDetails.loanType == LoanData.LoanType.SINGLE_TOKEN || loanDetails.loanType == LoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(_isTokenLoanIDExists(_loanId), "GLM, Loan not existed, Loan cannot be payback.");
        require(loanDetails.borrower == borrower, "GLM, Only Borrower can get back their own Loan.");
        require(loanDetails.isPartialFunding == false, "GLM, Should Not a partial Loan Offer.");
        require(loanDetails.loanStatus == LoanData.LoanStatus.ACTIVE, "GLM, Loan Should be Active at this stage.");

        if(LoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType) {//for single tokens collateral length must be one.
            require(loanDetails.stakedCollateralTokens.length == 1,"GLM: Multi-tokens not allowed in SINGLE TOKEN loan type.");
        }
        require(this.isLiquidationPending(_loanId), "GLM: Can not get back staked collaterals Amount at liquidation..");

        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){
            //contract will the staked collateral tokens to the borrower after cutting APY FEE.
           IERC20(loanDetails.stakedCollateralTokens[i]).transfer(msg.sender, loanDetails.stakedCollateralAmounts[i]);
        }   

        LoanData.LenderDetails memory lenderDetails = activatedLoanOffersFull[_loanId];
        require(block.timestamp <= lenderDetails.activationLoanTimeStamp, "GLM: Loan already paybacked or liquidated.");

        IERC20(loanDetails.borrowStableCoin).transferFrom(loanDetails.borrower, lenderDetails.lender, loanDetails.loanAmountInBorrowed);
        loanDetails.loanStatus = LoanData.LoanStatus.CLOSED;

    }


    /**
    @dev function  */
    function _isLtvUnderTier(uint256 _ltv) external view returns (bool) {
        TierData memory tierData = govWorldTierLevel.getTierDatabyGovBalance(
            msg.sender
        );
        uint256 maxTierLtvForUser = tierData.loantoValue;
        if (_ltv > maxTierLtvForUser) return true;
        else return false;
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
            LoanData.LoanDetails memory details = loanOffersToken[i];
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
            uint256 resD = res0 * (10**token0Decimals);
            return (_altAmount.mul(resD.div(res1*token0Decimals))); // return amount of alt needed to buy 1 stable
        } else {
            uint256 resD = res1 * (10**token1Decimals);
            return (_altAmount.mul(resD.div(res0*token0Decimals))); // return amount of alt needed to buy 1 stable
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
        LoanData.LoanDetails memory loanDetails = loanOffersToken[_loanId];
        //get individual collateral tokens for the loan id
        uint256[] memory stakedCollateralAmounts = loanDetails
            .stakedCollateralAmounts;
        address[] memory stakedCollateralTokens = loanDetails
            .stakedCollateralTokens;
        //IERC20Extras stableDecimnals = IERC20Extras(stkaedCollateralTokens);
        address borrowedToken = loanDetails.borrowStableCoin;
        return this.calculateLTV(stakedCollateralAmounts, stakedCollateralTokens, borrowedToken, loanDetails.loanAmountInBorrowed);
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
        uint256 totalCollateralInBorrowedToken = 0;
        for (uint256 i = 0; i < _stakedCollateralAmounts.length; i++) {
            //get price of collateral token in terms of loan stable coin.
            //get amounbt of alt to buy 1 stable
            uint256 collateralPriceInBorrowed = this.getTokenPriceInBorrowed(
                _borrowedToken,
                _stakedCollateralTokens[i],
                _stakedCollateralAmounts[i]
            );
            totalCollateralInBorrowedToken = totalCollateralInBorrowedToken.add(
                    collateralPriceInBorrowed
                );
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

    function getLoansLength() public view returns (uint256) {
        return loanOfferIds.length;
    }

    //loans available to be shown on narket place
    function getInActiveLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.INACTIVE) {
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
    @dev will increment loan id after creating loan offer
     */
    function _incrementLoanId() private {
        loanId++;
    }

    /**
    @dev get apy fee in public function
    @param _loanId for which APY fee is calculated
     */
    
    function getAPYFee(uint256 _loanId) public view returns(uint _APYFee) {
        return _getAPYFee(_loanId);
    }

    /**
    @dev get loan details of the single or multi-token
     */
    function getLoanOffersToken(uint256 _loanId) public view returns(LoanData.LoanDetails memory) {
        return loanOffersToken[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId) public view returns(LoanData.LenderDetails memory ) {
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
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.ACTIVE) {
                count++;
            }
        }
        return count;
    }

    /**
    @dev get closed loan offers count */
    function getClosedLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.CLOSED) {
                count++;
            }
        }
        return count;
    }


     /**
    @dev get closed loan offers count */
    function getCancelledLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.CANCELLED) {
                count++;
            }
        }
        return count;
    }

     /**
    @dev get closed loan offers count */
    function getLiquidatedLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.LIQUIDATED) {
                count++;
            }
        }
        return count;
    }


     /**
    @dev get closed loan offers count */
    function getTerminatedLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOffersToken[i].loanStatus == LoanData.LoanStatus.TERMINATED) {
                count++;
            }
        }
        return count;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

library LoanData {

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
		MULTI_TOKEN,
		SINGLE_NFT,
		MULTI_NFT
	}

	struct NftData {
		address contractAddress;
		bytes32 tokenId;
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
		//Single-ERC20, Multiple staked ERC20, Single NFT and multiple staked NFT
		LoanType loanType;
		//private loans will not appear on loan market
		bool isPrivate;
		//will allow lender to fund in 25%, 50%, 75% or 100% or original loan amount
		bool isPartialFunding;
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
    }


	struct LoanDetailsERC721 {

		//single nft or multi nft addresses
		address[] stakedCollateralERC721;
		//single nft id or multinft id
		uint256[] stakedCollateralTokenId;
		//single nft price or multi nft price //price fetch from the opensea or rarible
		uint256[] stakedNFTPrice;

		//total Loan Amount in USD
		uint256 loanAmountInBorrowed;
		//borrower given apy percentage
		uint32 apyOffer;
		
		//for future use of reverse loan
		//LoanCategory loanCategory;

		//Single NFT and multiple staked NFT
		LoanType loanType;
		//current status of the loan
		LoanStatus loanStatus;
		//user choose terms length in days TODO define validations
		uint56 termsLengthInDays;
		//private loans will not appear on loan market
		bool isPrivate;
		//will allow lender to fund in 25%, 50%, 75% or 100% or original loan amount
		bool isPartialFunding;
		//Future use flag to insure funds as they go to protocol.
		bool isInsured;
		//borrower's address
		address borrower;
		//borrower stable coin
		address borrowStableCoin;
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
import "./GovWorldAdminBase.sol";

contract GovWorldAdminRegistry is GovWorldAdminBase {

    constructor(
        address _admin1,
        address _admin2,
        address _admin3
    ) {
        //owner becomes the default admin.
        _makeDefaultApproved(
            _admin1,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true
            )
        );
        _makeDefaultApproved(
            _admin2,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true
            )
        );
        _makeDefaultApproved(
            _admin3,
            AdminAccess(
                true, true, true, true,
                true, true, true, true,
                true, true, true, true
            )
        );
    }

    /**
     * @dev Checks if a given _newAdmin is approved by all other already approved amins
     * @param _newAdmin Address of the new admin
     */
    function isApprovedByAll(address _newAdmin) external view returns (bool) {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _approvedByAdmins = approvedByAdmins[_newAdmin];
        //get All admins with add govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (approvedAdminRoles[allApprovedAdmins[i]].addGovAdmin ) {
                bool isPresent = false;
                for (uint256 j = 0; j < _approvedByAdmins.length; j++) {
                    if (_approvedByAdmins[j] == allApprovedAdmins[i]) {
                        isPresent = true;
                    }
                }
                if (!isPresent) return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks if a given _admin is removed by all other already approved amins
     * @param _admin Address of the new admin
     */
    function isRemovedByAll(address _admin) external view returns (bool) {
        //following two loops check if all currenctly
        //removedAdminRoles are present in removedbyAdmins of the _admin
        //loop all existing admins removedBy array
        address[] memory _removedByAdmins = removedByAdmins[_admin];
        //get All admins with only edit govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin &&
                allApprovedAdmins[i] != _admin
            ) {
                bool isPresent = false;
                for (uint256 j = 0; j < _removedByAdmins.length; j++) {
                    if (_removedByAdmins[j] == allApprovedAdmins[i]) {
                        isPresent = true;
                    }
                }
                if (!isPresent) return false;
            }
        }
        return true;
    }

    /**
     * @dev Checks if a given _admin is approved for editby all other already approved amins
     * @param _admin Address of the new admin
     */
    function isEditedByAll(address _admin) external view returns (bool) {
        //following two loops check if all currenctly
        //approvedAdminRoles are present in approvebyAdmins of the _newAdmin
        //loop all existing admins approvedBy array
        address[] memory _editedByAdmins = editedByAdmins[_admin];
        //get All admins with add govAdmin rights
        for (uint256 i = 0; i < allApprovedAdmins.length; i++) {
            if (
                approvedAdminRoles[allApprovedAdmins[i]].editGovAdmin && 
                allApprovedAdmins[i] != _admin  //all but yourself.
                ) {
                bool isPresent = false;
                //needs to check availability for all allowed admins to approve in editByAdmins.
                for (uint256 j = 0; j < _editedByAdmins.length; j++) {
                    if (_editedByAdmins[j] == allApprovedAdmins[i]) {
                        isPresent = true;
                    }
                }
                //if either one of allowed  admins dont approve return false.
                if (!isPresent) return false;
            }
        }
        //admin edited by all allowed admins.
        return true;
    }

    /**
     * @dev makes _newAdmin an approved admin if there is only one curernt admin _newAdmin becomes
     * becomes approved as it is and if currently more then 1 admins then approveAddedAdmin needs to be
     * called  by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function addAdmin(address _newAdmin, AdminAccess memory _adminAccess)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        //the GovAdmin cannot add himself as admin again
        require(_newAdmin != msg.sender, "GAR: Cannot add himself again, you already an Admin");
        //the admin that is adding _newAdmin must not already have approved.
        require(allApprovedAdmins.length > 2, "GAR: addDefaultAdmin as onwer first. ");
        require(_notApproved(_newAdmin, msg.sender), "GAR: Admin already approved this admin.");
        require(!_addressExists(_newAdmin, pendingAddedAdminKeys) ,"GAR: Admin already pending for add approval" );

        //this admin is now in the pending list.
        _makePending(_newAdmin, _adminAccess);
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _newAdmin Address of the new admin
     */
    function approveAddedAdmin(address _newAdmin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(_newAdmin != msg.sender, "GAR: Can not self approve");
        //the admin that is adding _newAdmin must not already have approved.
        require(
            _notApproved(_newAdmin, msg.sender),
            "GAR: Admin already approved this admin."
        );
        require(_addressExists(_newAdmin, pendingAddedAdminKeys),"GAR: Non Pending admin can not be approved.");
       
        approvedByAdmins[_newAdmin].push(msg.sender);
        emit NewAdminApproved(_newAdmin, msg.sender);

        //if the _newAdmin is approved by all other admins
        if (this.isApprovedByAll(_newAdmin)) {
            //no need for approvedby anymore
            delete approvedByAdmins[_newAdmin];
            //making this admin approved.
            _makeApproved(_newAdmin, pendingAddedAdminRoles[_newAdmin]);
            //no  need  for pending  role now
            delete pendingAddedAdminRoles[_newAdmin];
        }
    }

    /**
     * @dev any admin can reject the pending admin during the approval process and one rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectAddAdmin(address _admin)
        external
        onlyAddGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectAddAdmin himself");
        require(_addressExists(_admin, pendingAddedAdminKeys),"GAR: Non Pending admin can not be rejected.");
        //the admin that is adding _newAdmin must not already have approved.
        require(_notApproved(_admin, msg.sender),"GAR: Can not remove admin, you already approved.");
       
        //only with the reject of one admin call delete roles from mapping
        delete pendingAddedAdminRoles[_admin];
        for(uint256 i = 0; i < approvedByAdmins[_admin].length; i++){
            approvedByAdmins[_admin].pop();
        }
        _removePendingAddedIndex(_getIndex(_admin, pendingAddedAdminKeys));

        //delete admin roles from approved mapping
        delete approvedByAdmins[_admin];

        emit AddAdminRejected(_admin, msg.sender);
    }

    /**
     * @dev any admin can reject the pending admin during the edit approval process and one rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectEditAdmin for himself");
        require(_addressExists(_admin, pendingEditAdminKeys),"GAR: Non Pending admin can not be rejected.");
        require(editedByAdmins[_admin].length > 0, "GAR: Not available for rejection");
        //the admin that is adding _newAdmin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Can not remove admin, you already approved.");
       
        //if the _newAdmin is approved by all other admins
        delete pendingEditAdminRoles[_admin];
        _removePendingEditIndex(_getIndex(_admin, pendingEditAdminKeys));

        for(uint256 i = 0; i < editedByAdmins[_admin].length; i++){
            editedByAdmins[_admin].pop();
        }
        delete editedByAdmins[_admin];

        emit EditAdminRejected(_admin, msg.sender);
    }
    /**
     * @dev any admin can reject the pending admin during the approval process and once rejection means
     * not pending anymore.
     * @param _admin Address of the new admin
     */
    function rejectRemoveAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call rejectRemoveAdmin for himself");
        require(_addressExists(_admin, pendingRemoveAdminKeys),"GAR: Non Pending admin can not be rejected.");
        require(removedByAdmins[_admin].length > 0, "GAR: Not available for rejection");
        require(
            _notRemoved(_admin, msg.sender),
            "GAR: Can not reject remove. You already approved. "
        );
        //remove from pending removal mapping
        delete pendingRemovedAdminRoles[_admin];
        _removePendingRemoveIndex(_getIndex(_admin, pendingRemoveAdminKeys));
        //remove from removeByAdmins
        //this identifies removedByAll
        for(uint256 i = 0; i < removedByAdmins[_admin].length; i++){
            removedByAdmins[_admin].pop();
        }
        delete removedByAdmins[_admin];

        emit RemoveAdminRejected(_admin, msg.sender);
    }

    /**
    @dev Get all Approved Admins 
     */
    function getAllApproved() public view returns (address[] memory) {
        return allApprovedAdmins;
    }

    /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingAddedAdminKeys() public view returns(address[] memory) {
        return pendingAddedAdminKeys;
    }

     /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingEditAdminKeys() public view returns(address[] memory) {
        return pendingEditAdminKeys;
    }

     /**
    @dev Get all Pending Added Admin Keys */
    function getAllPendingRemoveAdminKeys() public view returns(address[] memory) {
        return pendingRemoveAdminKeys;
    }

    /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _addedAdmin address of the approved/proposed added admin.
     */
    function getApprovedByAdmins(address _addedAdmin) public view returns(address[] memory) {
        return approvedByAdmins[_addedAdmin];
    }

    /**
    @dev Get all edit by admins addresses
     */
    function getEditbyAdmins(address _editAdmin) public view returns(address[] memory) {
        return editedByAdmins[_editAdmin];
    }

      /**
    @dev Get all admin addresses which approved the address in the parameter
    @param _removedAdmin address of the approved/proposed added admin.
     */
    function getRemovedByAdmins(address _removedAdmin) public view returns(address[] memory) {
        return removedByAdmins[_removedAdmin];
    }


    /**
    @dev Get pending edit admin roles
     */
    function getpendingEditAdminRoles(address _editAdmin) public view returns(AdminAccess memory) {
        return pendingEditAdminRoles[_editAdmin];
    }
    /**
     * @dev Initiate process of removal of admin,
     * in case there is only one admin removal is done instantly.
     * If there are more then one admin all must call removePendingAdmin.
     * @param _admin Address of the admin requested to be removed
     */
    function removeAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call removeAdmin for himself");
        //the admin that is removing _admin must not already have approved.
        require(_notRemoved(_admin, msg.sender),"GAR: Admin already removed this admin. ");
        require(allApprovedAdmins.length > 3, "Can not remove last remaining 3 admin.");
        require(!_addressExists(_admin, pendingRemoveAdminKeys) ,"GAR: Admin already pending for remove approval" );
        //if length is 1 there is only one admin and he/she is removing another admin
        //this admin is now in the pending list.
        _makePendingForRemove(_admin);        
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveAddedAdmin are complete the admin auto becomes the approved admin
     * @param _admin Address of the new admin
     */
    function approveRemovedAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call approveRemovedAdmin for himself");
        //the admin that is adding _admin must not already have approved.
        require(_notRemoved(_admin, msg.sender),"GAR: Admin already approved this admin.");
        require(_admin != msg.sender, "GAR: Can not self remove");
        require(_addressExists(_admin, pendingRemoveAdminKeys),"GAR: Non Pending admin can not be approved.");

        removedByAdmins[_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isRemovedByAll(_admin)) {
            // _admin is now an approved admin.
            _removeAdmin(_admin);
        } else {
            emit RemoveAdminForApprove(_admin, msg.sender);
        }
    }

    /**
     * @dev Initiate process of edit of an admin,
     * If there are more then one admin all must call approveEditAdmin
     * @param _admin Address of the admin requested to be removed
     */
    function editAdmin(address _admin, AdminAccess memory _adminAccess)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not edit roles for himself");
        //the admin that is removing _admin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Admin already approved for edit. ");
        require(!_addressExists(_admin, pendingEditAdminKeys) ,"GAR: Admin already pending for edit approval" );

        //this admin is now in the pending for edit list.
        _makePendingForEdit(_admin, _adminAccess);        
    }

    /**
     * @dev call approved the admin which is already added to pending by other admin
     * if all current admins call approveEditAdmin are complete the admin edits become active
     * @param _admin Address of the new admin
     */
    function approveEditAdmin(address _admin)
        external
        onlyEditGovAdminRole(msg.sender)
    {
        require(_admin != msg.sender, "GAR: Can not call approveEditAdmin for himself");
        require(_addressExists(_admin, pendingEditAdminKeys),"GAR: Non Pending admin can not be approved.");
        //the admin that is adding _admin must not already have approved.
        require(_notEdited(_admin, msg.sender),"GAR: Admin already approved this admin.");
        editedByAdmins[_admin].push(msg.sender);

        //if the _admin is approved by all other admins for removal
        if (this.isEditedByAll(_admin)) {
            // _admin is now an approved admin.
            _editAdmin(_admin);
        } else {
            emit EditAdminApproved(_admin, msg.sender);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GovWorldAdminRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./GovWorldProtocolBase.sol";

contract GovWorldProtocolRegistry is GovWorldProtocolBase {
    using Address for address;
    GovWorldAdminRegistry govAdminRegistry;

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        require(
            govAdminRegistry.isAddTokenRole(admin) == true,
            "GovProtocolRegistry: msg.sender not add token admin."
        );
        _;
    }
    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        require(
            govAdminRegistry.isEditTokenRole(admin) == true,
            "GovProtocolRegistry: msg.sender not edit token admin."
        );
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        require(
            govAdminRegistry.isAddSpAccess(admin) == true,
            "GovProtocolRegistry: No admin right to add Strategic Partner"
        );
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        require(
            govAdminRegistry.isEditSpAccess(admin) == true,
            "GovProtocolRegistry: No admin right to update or remove Strategic Partner"
        );
        _;
    }

    constructor(address _govAdminRegistry) {
        govAdminRegistry = GovWorldAdminRegistry(_govAdminRegistry);
    }

    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param marketData struct of the _tokenAddress
    */
    function addToken(address _tokenAddress, Market memory marketData)
        external
        override
        onlyAddTokenRole(msg.sender)
    {
        //checking Token Contract have not already added
        require(
            !this.isTokenApproved(_tokenAddress),
            "GPL: already added Token Contract"
        );

        _addToken(_tokenAddress, marketData);
    }

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
    // ) external override onlyAddTokenRole(msg.sender) {
    //     require(
    //         IERC721(_nftContract).ownerOf(_nftTokenId) != address(0),
    //         "invalid token"
    //     );
    //     _addNFT(_nftPlatform, _nftContract, _nftTokenId);
    //     emit NFTAdded(_nftPlatform, _nftContract, _nftTokenId);
    // }

    /**
    @dev function adding bulk nfts contract with their token IDs to the approvedNfts mapping
    @param _nftPlatfrom  platform like opensea or rarible
    @param _nftContracts  addresses of the nftContracts
    @param _nftTokenIds token ids of the nftContracts
     */
    // function addBulkNFT(
    //     bytes32 _nftPlatfrom,
    //     address[] memory _nftContracts,
    //     uint256[] memory _nftTokenIds
    // ) external override onlyAddTokenRole(msg.sender) {
    //     require(
    //         _nftContracts.length == _nftTokenIds.length,
    //         "NFT Contract Address and Token IDs Length must be equal"
    //     );
    //     _addBulkNFT(_nftPlatfrom, _nftContracts, _nftTokenIds);
    // }

    /**
     *@dev function to update the token market data
     *@param _tokenAddress to check if it exit in the array and mapping
     *@param _marketData struct to update the token market
     */
     function updateToken(address _tokenAddress, Market memory _marketData)
        external
        override
        onlyEditTokenRole(msg.sender)
    {
        require(
            this.isTokenApproved(_tokenAddress),
            "GPR: cannot update the token data, add new token address first"
        );

        _updateToken(_tokenAddress, _marketData);
    }

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetoken(address _removeTokenAddress)
        external override
        onlyEditTokenRole(msg.sender)
    {
        require(
            this.isTokenApproved(_removeTokenAddress),
            "GPR: cannot remove the token address, does not exist"
        );
        delete approvedTokens[_removeTokenAddress];

        _removeToken(_removeTokenAddress);

        emit TokenRemoved(_removeTokenAddress);
    }

    /**
     *@dev function which remove NFT key from array and data from the mapping
     *@param _nftContract nft Contract address to be removed
     *@param _nftTokenId token id to be removed
     */

    // function removeNFT(address _nftContract, uint256 _nftTokenId)
    //     external override
    //     onlyEditTokenRole(msg.sender)
    // {
    //     require(
    //         IERC721(_nftContract).ownerOf(_nftTokenId) != address(0),
    //         "invalid token"
    //     );
    //     bytes32 nftHash = getNftHash(_nftContract, _nftTokenId);

    //     //checking NFT Contract
    //     require(
    //         this.isAddedNft(nftHash),
    //         "GPL: cannot remove NFT, add nft token id first"
    //     );
    //     _removeNFTKey(_getIndex(nftHash));

    //     delete approvedNFTs[nftHash];
    //     emit NFTRemoved(
    //         approvedNFTs[nftHash].platform,
    //         _nftContract,
    //         _nftTokenId
    //     );
    // }

    /**
    *@dev function which remove bulk NFTs key from array and data from mapping
    @param _nftContract array of nft contract address to be removed
    @param _nftTokenId array of token id to be removed
     */

    // function removeBulkNFTs(
    //     address[] memory _nftContract,
    //     uint256[] memory _nftTokenId
    // ) external override onlyEditTokenRole(msg.sender) {
    //     require(
    //         _nftContract.length == _nftTokenId.length,
    //         "NFT Contract Address and Token IDs Length must be equal"
    //     );
    //     for (uint256 i = 0; i < _nftContract.length; i++) {
    //         require(
    //             IERC721(_nftContract[i]).ownerOf(_nftTokenId[i]) != address(0),
    //             "invalid token"
    //         );
    //         bytes32 nftHash = getNftHash(_nftContract[i], _nftTokenId[i]);

    //         require(
    //             this.isAddedNft(nftHash),
    //             "GPL: cannot remove NFT, add nft token id first"
    //         );
    //         delete approvedNFTs[nftHash];

    //         _removeNFTKey(_getIndex(nftHash));
    //     }
    // }

    /**
    @dev add sp wallet to the mapping approvedSps
    @param _tokenAddress token contract address
    @param _walletAddress sp wallet address to add  
    */

    function addSp(address _tokenAddress, address _walletAddress)
        external override
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            !_isAlreadyAddedSp(_walletAddress),
            "GovProtocolRegistry: SP Already Approved"
        );
        _addSp(_tokenAddress, _walletAddress);
    }

    /**
    @dev remove sp wallet from mapping
    @param _tokenAddress token address as a key to remove sp
    @param _removeWalletAddress sp wallet address to be removed 
    */

    function removeSp(address _tokenAddress, address _removeWalletAddress)
        external override
        onlyEditSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            _isAlreadyAddedSp(_removeWalletAddress),
            "GPR: cannot remove the SP, does not exist"
        );

        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _removeWalletAddress) {
                // delete approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
            }
        }

        emit SPWalletRemoved(_tokenAddress, _removeWalletAddress);
    }

     /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        external override
        onlyAddSpRole(msg.sender)
    {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );

        _addBulkSps(_tokenAddress, _walletAddress);
    }

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
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        require(
            _isAlreadyAddedSp(_oldWalletAddress),
            "GPR: cannot update the wallet address, token address not exist or not a SP"
        );

        require(
            _isAlreadyAddedSpFromMapping(_tokenAddress, _oldWalletAddress),
            "GPR: Wallet Address not exist"
        );

        _updateSp(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

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
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );
        _updateBulkSps(_tokenAddress, _oldWalletAddress, _newWalletAddress);
    }

    /**
    *@dev function which remove bulk wallet address and key
    @param _tokenAddress check across this token address
    @param _removeWalletAddress array of wallet addresses to be removed
     */

    function removeBulkSps(
        address _tokenAddress,
        address[] memory _removeWalletAddress
    ) external override onlyEditSpRole(msg.sender) {
        require(
            approvedTokens[_tokenAddress].isSP,
            "Sorry, this token is not a Strategic Partner"
        );

        for (uint256 i = 0; i < _removeWalletAddress.length; i++) {
            require(
                _isAlreadyAddedSp(_removeWalletAddress[i]),
                "GPR: cannot remove the SP, does not exist, not in array"
            );

            require(
                _isAlreadyAddedSpFromMapping(
                    _tokenAddress,
                    _removeWalletAddress[i]
                ),
                "GPR: cannot remove the SP, does not exist, not in mapping"
            );

            // delete approvedSps[_tokenAddress][i];
            //remove SP key from the mapping
            _removeSpKey(_getIndexofAddressfromArray(_removeWalletAddress[i]));

            //also remove SP key from specific token address
            _removeSpKeyfromMapping(
                _getIndexofAddressfromArray(_tokenAddress),
                _tokenAddress
            );
        }
    }

    /** Public functions of the Gov Protocol Contract */

    /**
    @dev get all approved tokens from the allapprovedTokenContracts
     */
    function getallApprovedTokens() public view returns (address[] memory) {
        return allapprovedTokenContracts;
    }

    // /**
    // @dev get hashes of all approved nft contracts + token Ids
    //  */
    // function getAllApprovedNFTContracts()
    //     public
    //     view
    //     returns (bytes32[] memory)
    // {
    //     return allapprovedNFTContracts;
    // }

    /**
    @dev get data of single approved token address return Market Struct
     */
    function getSingleApproveToken(address _tokenAddress)
        public
        view
        returns (Market memory)
    {
        return approvedTokens[_tokenAddress];
    }

    // /**
    // @dev get data of single approved nft hash
    //  */
    // function getSingleApproveNFT(bytes32 _hash)
    //     public
    //     view
    //     returns (NFTData memory)
    // {
    //     return approvedNFTs[_hash];
    // }

    /**
    @dev get all approved Sp wallets
     */
    function getAllApprovedSPs() external view returns (address[] memory) {
        return allApprovedSps;
    } 

    /**
    @dev get wallet addresses of single tokenAddress 
    */
    function getSingleTokenSps(address _tokenAddress)
        public
        view
        returns (address[] memory)
    {
        return approvedSps[_tokenAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GovWorldAdminRegistry.sol";
import "./admininterfaces/IGovWorldTierLevel.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovWorldTierLevel is IGovWorldTierLevel {
    using SafeMath for uint256;

    //list of new tier levels
    mapping(bytes32 => TierData) public tierLevels;

    //list of all added tier levels. Stores the key for mapping => tierLevels
    bytes32[] allTierLevelKeys;

    GovWorldAdminRegistry govAdminRegistry;
    address govToken;

    constructor(
        address _govAdminRegistry,
        address _govTokenAddress,
        bytes32 _bronze,
        bytes32 _silver,
        bytes32 _gold,
        bytes32 _platinum,
        bytes32 _allStar
    ) {
        //TODO add tier levels according to default tier levels by client
        govAdminRegistry = GovWorldAdminRegistry(_govAdminRegistry);
        govToken = _govTokenAddress;

        _addTierLevel(
            _bronze,
            TierData(
                15000e18,
                30,
                false,
                false,
                true,
                false,
                true,
                false,
                false,
                false
            )
        );
        _addTierLevel(
            _silver,
            TierData(
                30000e18,
                40,
                false,
                false,
                true,
                true,
                true,
                false,
                false,
                false
            )
        );
        _addTierLevel(
            _gold,
            TierData(
                75000e18,
                50,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        _addTierLevel(
            _platinum,
            TierData(
                150000e18,
                70,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
        _addTierLevel(
            _allStar,
            TierData(
                300000e18,
                70,
                true,
                true,
                true,
                true,
                true,
                true,
                true,
                true
            )
        );
    }

    modifier onlyEditTierLevelRole(address admin) {
        require(
            govAdminRegistry.isEditAdminAccessGranted(admin),
            "GTL: No admin right to add or remove tier level."
        );
        _;
    }

    //external functions

    /**
    @dev external function to add new tier level (keys with their access values)
    @param _newTierLevel must be a new tier key in bytes32
    @param _tierData access variables of the each Tier Level
     */
    function addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        external
        override
        onlyEditTierLevelRole(msg.sender)
    {
        //admin have not already added new tier level
        require(
            !_isAlreadyTierLevel(_newTierLevel),
            "GTL: already added tier level"
        );
        require(
            _tierData.govHoldings >
                tierLevels[allTierLevelKeys[maxGovTierLevel()]].govHoldings,
            "GovHolding Should be greater then last tier level Gov Holdings"
        );
        //adding tier level called by the admin
        _addTierLevel(_newTierLevel, _tierData);
    }

    /**
    @dev external function to update the existing tier level, also check if it is already added or not
    @param _updatedTierLevelKey existing tierlevel key
    @param _newTierData new data for the updateding Tier level
     */
    function updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) external override onlyEditTierLevelRole(msg.sender) {
        require(
            _isAlreadyTierLevel(_updatedTierLevelKey),
            "GovWorldTier: cannot update Tier, create new tier first"
        );
        _updateTierLevel(_updatedTierLevelKey, _newTierData);

        // console.log('TierLevels => %d', allTierLevelKeys.length);
    }

    /**
    @dev remove tier level key as well as from mapping
    @param _existingTierLevel tierlevel hash in bytes32
     */
    function removeTierLevel(bytes32 _existingTierLevel)
        external
        override
        onlyEditTierLevelRole(msg.sender)
    {
        require(
            _isAlreadyTierLevel(_existingTierLevel),
            "GovWorldTier: cannot remove, Tier Level not exist"
        );
        delete tierLevels[_existingTierLevel];
        emit TierLevelRemoved(_existingTierLevel);
        
        _removeTierLevelKey(_getIndex(_existingTierLevel));
    }

    /**
    @dev this function add new tier level if not exist and update tier level if already exist.
     */
    function saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) external override onlyEditTierLevelRole(msg.sender) {
        require(
            _tierLevelKeys.length == _newTierData.length,
            "New Tier Keys and TierData length must be equal"
        );
        _saveTierLevel(_tierLevelKeys, _newTierData);
    }

    //public functions

    /**
     * @dev get all the Tier Level Keys from the allTierLevelKeys array
     */
    function getAllTierLevels() public view returns (bytes32[] memory) {
        return allTierLevelKeys;
    }

    /**
     * @dev get Single Tier Level Data
     */
    function getSingleTierData(bytes32 _tierLevelKey)
        public
        view
        returns (TierData memory)
    {
        return tierLevels[_tierLevelKey];
    }

    //internal functions

    /**
     * @dev makes _new a pendsing adnmin for approval to be given by all current admins
     * @param _newTierLevel value type of the New Tier Level in bytes
     * @param _tierData access variables for _newadmin
     */

    function _addTierLevel(bytes32 _newTierLevel, TierData memory _tierData)
        internal
    {
        //new Tier is added to the mapping tierLevels
        tierLevels[_newTierLevel] = _tierData;

        //new Tier Key for mapping tierLevel
        allTierLevelKeys.push(_newTierLevel);
        emit TierLevelAdded(_newTierLevel, _tierData);
    }

    /**
     * @dev Checks if a given _newTierLevel is already added by the admin.
     * @param _newTierLevel value of the new tier
     */
    function _isAlreadyTierLevel(bytes32 _newTierLevel)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _newTierLevel) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev update already created tier level
     * @param _updatedTierLevelKey key value type of the already created Tier Level in bytes
     * @param _newTierData access variables for updating the Tier Level
     */

    function _updateTierLevel(
        bytes32 _updatedTierLevelKey,
        TierData memory _newTierData
    ) internal {
        //update Tier Level to the updatedTier
        uint256 currentIndex = _getIndex(_updatedTierLevelKey);
        uint256 lowerLimit = 0;
        uint256 upperLimit = _newTierData.govHoldings.add(10);
        if (currentIndex > 0) {
            lowerLimit = tierLevels[allTierLevelKeys[currentIndex - 1]]
                .govHoldings;
        }
        if (currentIndex < allTierLevelKeys.length - 1)
            upperLimit = tierLevels[allTierLevelKeys[currentIndex + 1]]
                .govHoldings;

        require(
            _newTierData.govHoldings < upperLimit &&
                _newTierData.govHoldings > lowerLimit,
            "Gov Holding Should be in range of previous and next tier level"
        );

        tierLevels[_updatedTierLevelKey] = _newTierData;
        emit TierLevelUpdated(_updatedTierLevelKey, _newTierData);
    }

    /**
     * @dev remove tier level
     * @param index already existing tierlevel index
     */
    function _removeTierLevelKey(uint256 index) internal {
        if (allTierLevelKeys.length != 1) {
            for (uint256 i = index; i < allTierLevelKeys.length - 1; i++) {
                allTierLevelKeys[i] = allTierLevelKeys[i + 1];
            }
        }
        allTierLevelKeys.pop();

    }

    /**
    @dev internal function for the save tier level, which will update and add tier level at a time
     */
    function _saveTierLevel(
        bytes32[] memory _tierLevelKeys,
        TierData[] memory _newTierData
    ) internal {
        for (uint256 i = 0; i < _tierLevelKeys.length; i++) {
            if (!_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _addTierLevel(_tierLevelKeys[i], _newTierData[i]);
            } else if (_isAlreadyTierLevel(_tierLevelKeys[i])) {
                _updateTierLevel(_tierLevelKeys[i], _newTierData[i]);
            }
        }
    }

    /**
    @dev this function returns the index of the maximum govholding tier level
     */
    function maxGovTierLevel() public view returns (uint256) {
        uint256 max = tierLevels[allTierLevelKeys[0]].govHoldings;
        uint256 maxIndex = 0;

        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (tierLevels[allTierLevelKeys[i]].govHoldings > max) {
                maxIndex = i;
                max = tierLevels[allTierLevelKeys[i]].govHoldings;
            }
        }

        return maxIndex;
    }

    /**
    @dev get index of the tierLevel from the allTierLevel array
    @param _tierLevel hash of the tier level
     */
    function _getIndex(bytes32 _tierLevel)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < allTierLevelKeys.length; i++) {
            if (allTierLevelKeys[i] == _tierLevel) {
                return i;
            }
        }
    }

    /**
    @dev this function returns the tierLevel data by user's Gov Token Balance
    @param userWalletAddress user address for check tier level data
     */
    function getTierDatabyGovBalance(address userWalletAddress)
        public
        view
        returns (TierData memory _tierData)
    {
        //govToken.transfer(recipient, amount);
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress);
        require(
            userGovBalance >= 15000e18,
            "User Balance is too low, Not Eligible for any Tier Level"
        );
        for (uint256 i = 1; i < allTierLevelKeys.length; i++) {
            if (
                (userGovBalance >=
                    tierLevels[allTierLevelKeys[i - 1]].govHoldings) &&
                (userGovBalance < tierLevels[allTierLevelKeys[i]].govHoldings)
            ) {
                return tierLevels[allTierLevelKeys[i - 1]];
            } else if (
                userGovBalance >=
                tierLevels[allTierLevelKeys[allTierLevelKeys.length - 1]]
                    .govHoldings
            ) {
                return
                    tierLevels[allTierLevelKeys[allTierLevelKeys.length - 1]];
            }
        }
    }

    /**
    @dev this function returns the tierLevel Name by user's Gov Token Balance
    @param userWalletAddress user address for check tier level name
     */
    function getTierNamebyGovToken(address userWalletAddress)
        public
        view
        returns (bytes32 tierLevel)
    {
        //govToken.transfer(recipient, amount);
        uint256 userGovBalance = IERC20(govToken).balanceOf(userWalletAddress);
        console.log("user Blanace in contract %d", userGovBalance);

        require(
            userGovBalance >= 15000e18,
            "User Balance is too low, Not Eligible for any Tier Level"
        );
        for (uint256 i = 1; i < allTierLevelKeys.length; i++) {
            if (
                (userGovBalance >=
                    tierLevels[allTierLevelKeys[i - 1]].govHoldings) &&
                (userGovBalance < tierLevels[allTierLevelKeys[i]].govHoldings)
            ) {
                return allTierLevelKeys[i - 1];
            } else if (
                userGovBalance >=
                tierLevels[allTierLevelKeys[allTierLevelKeys.length - 1]]
                    .govHoldings
            ) {
                return allTierLevelKeys[allTierLevelKeys.length - 1];
            }
        }
    }

    function stringToBytes32(string memory _string)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_string, 32))
        }
    }
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

import "./LoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ILoanMarket.sol";

abstract contract LoanMarketBase is ILoanMarket {
    //Load library structs into contract
    using LoanData for *;
    using LoanData for bytes32;
    using SafeMath for uint256;

    //saves the transaction hash of the create loan offer transaction as loanId
    //saves information in loanOffers when createLoanOffer is called
    //TODO create mapping borrower.address-> loanId=> LoanDetails
    mapping(uint256 => LoanData.LoanDetails) public loanOffersToken;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => LoanData.LenderDetails) public activatedLoanOffersFull;

    //Single NFT or Multi NFT loan offers mapping
    //saves information of NFT in loanOffersNFT when createLoanOfferERC721 is called
    mapping(uint256 => LoanData.LoanDetailsERC721) public loanOffersNFT;

    //what borrower with which loan offers.
    uint256[] public loanOfferIds;

    mapping(address => uint256[]) borrowerloanOfferIds;

    //mapping address of lender to the loan Ids
    mapping(address => uint256[]) lenderActivatedLoanIds;

    //what loanofferids are partially funded with which loan offers.
    mapping(uint256 => uint256[]) partialLoanOffers;


    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function _getAPYFee(uint256 _loanId) internal view returns(uint256) {

        LoanData.LoanDetails storage loanDetailsToken = loanOffersToken[_loanId];

        // APY Fee Formula
        uint256 apyFee = ((loanDetailsToken.loanAmountInBorrowed.mul(loanDetailsToken.apyOffer).div(100)).div(365)).mul(loanDetailsToken.termsLengthInDays);

        return apyFee;
    } 

    //function to check if loan ID exists
    function _isTokenLoanIDExists(uint256 _loanId) internal view returns(bool) {
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (loanOfferIds[i] == _loanId) {
                return true;
            }
        }
        return false;
    }

    //function to check if loan not active
    // LoanStatus  ACTIVE=0, INACTIVE=1, CLOSED=2, CANCELLED=3, LIQUIDATED=4, TERMINATED=5
    function _isLoanInactive(uint _loanId) internal view returns(bool) {
         
            if (loanOffersToken[_loanId].loanStatus == LoanData.LoanStatus.INACTIVE) { //check if loan status is Inactive
                return true;
            } else
        return false;
    }

    /**
    @dev function to check if loan funding partial or full allowed
    @param _loanId the loanId for which we are checking partial or full funding status 
     */
    function _isLoanPartial(uint256 _loanId) internal view returns (bool) {
       
        if(loanOffersToken[_loanId].isPartialFunding) {
            return true;
        } else {
            return false;   
        }
    }



}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
contract GovWorldAdminBase is Ownable {
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
    }

    //list of already approved admins.
    mapping(address => AdminAccess) public approvedAdminRoles;

    //list of all approved admin addresses. Stores the key for mapping approvedAdminRoles
    address[] allApprovedAdmins;

    //list of pending admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingAddedAdminRoles;
    address [] public pendingAddedAdminKeys;

    //list of pending removed admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingRemovedAdminRoles;
    address [] public pendingRemoveAdminKeys;

    //list of pending edit admins to be approved by already approved admins.
    mapping(address => AdminAccess) public pendingEditAdminRoles;
    address [] public pendingEditAdminKeys;

    //a list of admins approved by other admins.
    mapping(address => address[]) public approvedByAdmins;

    //a list of admins removed by other admins.
    mapping(address => address[]) public removedByAdmins;

    //a list of admins updated by other admins.
    mapping(address => address[]) public editedByAdmins;

    // access-modifier for adding gov admin
    modifier onlyAddGovAdminRole(address _admin) {
        require(approvedAdminRoles[_admin].addGovAdmin,"GAR: onlyAddGovAdminRole can add admin.");
        _;
    }

    // access-modifier for editing gov admin
    modifier onlyEditGovAdminRole(address _admin) {
        require(approvedAdminRoles[_admin].editGovAdmin,"GAR: OnlyEditGovAdminRole can edit or remove admin.");
        _;
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

    /**
     * @dev Checks if a given _newAdmin is not approved by the _approvedBy admin.
     * @param _newAdmin Address of the new admin
     * @param _approvedBy Address of the existing admin that may have approved _newAdmin already.
     */
    function _notApproved(address _newAdmin, address _approvedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < approvedByAdmins[_newAdmin].length; i++) {
            if (approvedByAdmins[_newAdmin][i] == _approvedBy) {
                return false; //approved
            }
        }
        return true; //not approved
    }

    /**
     * @dev Checks if a given _admin is not removed by the _removedBy admin.
     * @param _admin Address of the new admin
     * @param _removedBy Address of the existing admin that may have removed _admin already.
     */
    function _notRemoved(address _admin, address _removedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < removedByAdmins[_admin].length; i++) {
            if (removedByAdmins[_admin][i] == _removedBy) {
                return false; //removed
            }
        }
        return true; //not removed
    }

    /**
     * @dev Checks if a given _admin is not edited by the _removedBy admin.
     * @param _admin Address of the edit admin
     * @param _editedBy Address of the existing admin that may have approved edit for _admin already.
     */
    function _notEdited(address _admin, address _editedBy)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < editedByAdmins[_admin].length; i++) {
            if (editedByAdmins[_admin][i] == _editedBy) {
                console.log("_admin  %s", _editedBy);
                return false; //removed
            }
        }
        return true; //not removed
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeDefaultApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {

        //no need for approved by admin for the new  admin anymore.
        delete approvedByAdmins[_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }

    /**
     * @dev makes _newAdmin an approved admin and emits the event
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makeApproved(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //no need for approved by admin for the new  admin anymore.
        delete approvedByAdmins[_newAdmin];
        // _newAdmin is now an approved admin.
        approvedAdminRoles[_newAdmin] = _adminAccess;
        //new key for mapping approvedAdminRoles
        allApprovedAdmins.push(_newAdmin);
        _removePendingAddedIndex(_getIndex(_newAdmin, pendingAddedAdminKeys));
        emit NewAdminApprovedByAll(_newAdmin, _adminAccess);
    }
    

    /**
     * @dev makes _newAdmin a pendsing adnmin for approval to be given by all current admins
     * @param _newAdmin Address of the new admin
     * @param _adminAccess access variables for _newadmin
     */
    function _makePending(address _newAdmin, AdminAccess memory _adminAccess)
        internal
    {
        //the admin who is adding the new admin is approving _newAdmin by default
        approvedByAdmins[_newAdmin].push(msg.sender);

        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingAddedAdminRoles[_newAdmin] = _adminAccess;
        pendingAddedAdminKeys.push(_newAdmin);
        emit NewAdminApproved(_newAdmin, msg.sender);
    }


    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _removeAdmin(address _admin) internal {
        // _admin is now a removed admin.
        delete approvedAdminRoles[_admin];
        delete removedByAdmins[_admin];
        
        //remove key for mapping approvedAdminRoles
        _removeIndex(_getIndex(_admin, allApprovedAdmins));
        _removePendingRemoveIndex(_getIndex(_admin, pendingRemoveAdminKeys));
        emit AdminRemovedByAll(_admin, msg.sender);
    }

    /**
     * @dev makes _newAdmin an removed admin and emits the event
     * @param _admin Address of the new admin
     */
    function _editAdmin(address _admin) internal {
        // _admin is now an removed admin.

        approvedAdminRoles[_admin] = pendingEditAdminRoles[_admin];

        delete editedByAdmins[_admin];
        delete pendingEditAdminRoles[_admin];
        _removePendingEditIndex(_getIndex(_admin, pendingEditAdminKeys));

        emit AdminEditedApprovedByAll(_admin, approvedAdminRoles[_admin]);
    }


    function _removeIndex(uint index) internal {

        for (uint256 i = index; i < allApprovedAdmins.length - 1; i++) {
            allApprovedAdmins[i] = allApprovedAdmins[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length - 1];
        allApprovedAdmins.pop();
        
    }

    function _removePendingAddedIndex(uint index) internal {
        for (uint256 i = index; i < pendingAddedAdminKeys.length - 1; i++) {
            pendingAddedAdminKeys[i] = pendingAddedAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length - 1];
        pendingAddedAdminKeys.pop();
    }


    function _removePendingEditIndex(uint index) internal {
        for (uint256 i = index; i < pendingEditAdminKeys.length - 1; i++) {
            pendingEditAdminKeys[i] = pendingEditAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length - 1];
        pendingEditAdminKeys.pop();
    }


    function _removePendingRemoveIndex(uint index) internal {
        for (uint256 i = index; i < pendingRemoveAdminKeys.length - 1; i++) {
            pendingRemoveAdminKeys[i] = pendingRemoveAdminKeys[i + 1];
        }
        // allApprovedAdmins[index] = allApprovedAdmins[allApprovedAdmins.length - 1];
        pendingRemoveAdminKeys.pop();
    }
    /**
     * @dev makes _admin a pendsing adnmin for approval to be given by
     * all current admins for removing this admnin.
     * @param _admin Address of the new admin
     */
    function _makePendingForRemove(address _admin) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        removedByAdmins[_admin].push(msg.sender);
        pendingRemoveAdminKeys.push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingRemovedAdminRoles[_admin] = approvedAdminRoles[_admin];

        emit RemoveAdminForApprove(_admin, msg.sender);
    }

    /**
     * @dev makes _admin a pendsing adnmin for approval to be given by
     * all current admins for editing this admnin.
     * @param _admin Address of the new admin.
     * @param _newAccess Address of the new admin.
     */
    function _makePendingForEdit(address _admin, AdminAccess memory _newAccess) internal {
        //the admin who is adding the new admin is approving _newAdmin by default
        editedByAdmins[_admin].push(msg.sender);
        pendingEditAdminKeys.push(_admin);
        //add _newAdmin to pendingAddedAdminRoles for approval  by all other current.
        pendingEditAdminRoles[_admin] = _newAccess;

        emit EditAdminApproved(_admin, msg.sender);
    }

    function _removeKey(address _valueToFindAndRemove, address[] memory from) 
        internal
        pure
        returns(address [] memory) 
    {
        address[] memory auxArray;
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] != _valueToFindAndRemove) {
                auxArray[i] = from[i];
            }
        }
        from = auxArray;
        return from;
    }

    function _getIndex(address _valueToFindAndRemove, address [] memory from)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFindAndRemove) {
                return i;
            }
        }
    }

    function _addressExists(address _valueToFind, address [] memory from)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < from.length; i++) {
            if (from[i] == _valueToFind) {
                return true;
            }
        }
        return false;
    }
   
    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool)
    {
        if (approvedAdminRoles[admin].editGovAdmin == true) return true;

        return false;
    }

    //using this function externally in other Smart Contracts
    function isAddTokenRole(address admin) external view returns (bool) {
        return approvedAdminRoles[admin].addToken;
    }

    //using this function externally in other Smart Contracts
    function isEditTokenRole(address admin) external view returns (bool) {
        return approvedAdminRoles[admin].editToken;
    }

    //using this function externally in other Smart Contracts
    function isAddSpAccess(address admin) external view returns (bool) {
             return approvedAdminRoles[admin].addSp;

    }

    //using this function externally in other Smart Contracts
    function isEditSpAccess(address admin) external view returns(bool) {
       return approvedAdminRoles[admin].editSp;
    }
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./admininterfaces/IGovWorldProtocolRegistry.sol";
import "./../token/GToken.sol";
import "./../interfaces/IERC20Extras.sol";
import "hardhat/console.sol";

/// @author IdeoFuzion Team
/// @title GovWorld Protocol Registry Base Contract

abstract contract GovWorldProtocolBase is IGovWorldProtocolRegistry{
    using Address for address;

    //tokenAddress => spWalletAddress 
    mapping(address => address[]) public approvedSps;
    // array of all approved SP Wallet Addresses
    address[] public allApprovedSps;

    //tokenContractAddress => Market struct 
    mapping(address => Market) public approvedTokens;

    //nftcontract + tokenId(bytes32 hash) => NFTData struct
    // mapping(bytes32 => NFTData) public approvedNFTs;

    //array of all approved token contracts
    address[] allapprovedTokenContracts;

    //array of all approved NFT Contract with TokenID
    // bytes32[] allapprovedNFTContracts;

    
    // /**  
    // @dev check function if NFT Contract address is already added or not
    // @param _hashofContractandTokenId check by hash of NFT token and its contract
    // @return return true if already added NFT else return false
    // */
    // function isAddedNft(bytes32 _hashofContractandTokenId)
    //     external
    //     view
    //     returns (bool)
    // {
    //     for (uint256 i = 0; i < allapprovedNFTContracts.length; i++) {
    //         if (allapprovedNFTContracts[i] == _hashofContractandTokenId) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    /** Internal functions of the Gov Protocol Contract */
    /**
    @dev function to add token market data
    @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    @param marketData struct object to be added in approvedTokens mapping
     */

    function _addToken(address _tokenAddress, Market memory marketData)
        internal
    {
       
        //adding marketData to the approvedToken mapping
        if(marketData.isSP){
            //TODO  need  go deploy gToken for this approved Strategic Partner token.
            IERC20Extras spToken = IERC20Extras(_tokenAddress);
            string memory gTokenName = string(abi.encodePacked("g", spToken.name()));
            string memory gTokenSymbol = string(abi.encodePacked("g", spToken.symbol()));
            marketData.gToken = address(new GToken(gTokenName, gTokenSymbol, _tokenAddress));
            approvedTokens[_tokenAddress] = marketData;      
        } else {
            approvedTokens[_tokenAddress] = Market(marketData.isSP, marketData.isReversedLoan, marketData.tokenLimitPerReverseLoan, address(0x0));
        }

       
        //push _tokenAddress as a key to the allapprovedToken array
        allapprovedTokenContracts.push(_tokenAddress);
        emit TokenAdded(_tokenAddress);
    }

    // /**
    // @dev function to add nft data to the approvedNFTs mapping
    // @param _nftPlatform name of the platform like rarible, opensea in bytes32
    // @param _nftContract contract address of the NFT tokenID
    // @param _nftTokenId NFT tokenId add to the approvedNFTs mapping
    //  */
    // function _addNFT(
    //     bytes32 _nftPlatform,
    //     address _nftContract,
    //     uint256 _nftTokenId
    // ) internal {
    //     bytes32 nftHash = this.getNftHash(_nftContract, _nftTokenId);
    //     require(!this.isAddedNft(nftHash), "GPR: NFT already Added.");
    //     //adding NFTData to the approvedNFT mapping and hash of contract and tokenid as key
    //     approvedNFTs[nftHash] = NFTData({
    //         platform: _nftPlatform,
    //         nftContractAddress: _nftContract,
    //         nftTokenId: _nftTokenId
    //     });

    //     allapprovedNFTContracts.push(nftHash);
    // }

    // /**
    // @dev function to add multiple nfts to the approvedNFTs mapping
    // @param _nftPlatform name of the platform like rarible, opensea in bytes32
    // @param _nftContracts array of contract addresss of the NFT tokenIDs
    // @param _nftTokenIds array of NFT TokenIds to be added to approvedNFTs
    //  */
    // function _addBulkNFT(
    //     bytes32 _nftPlatform,
    //     address[] memory _nftContracts,
    //     uint256[] memory _nftTokenIds
    // ) internal {
    //     for (uint256 i = 0; i < _nftTokenIds.length; i++) {
    //         //making nft + contract address hash of each contract and nft token id though loop
    //         bytes32 nftHash = this.getNftHash(
    //             _nftContracts[i],
    //             _nftTokenIds[i]
    //         );
    //         //checking NFT Contract and Token ID
    //         require(!this.isAddedNft(nftHash), "GPR: NFT already Added.");
    //         _addNFT(_nftPlatform, _nftContracts[i], _nftTokenIds[i]);
    //     }
    //     emit BulkNFTAdded(_nftPlatform, _nftContracts, _nftTokenIds);
    // }

    /**
    @dev function to update the token market data
    @param _tokenAddress ERC20 token contract address as a key for approvedTokens mapping
    @param _marketData struct object to be added in approvedTokens mapping
     */
    function _updateToken(address _tokenAddress, Market memory _marketData)
        internal
    {
        //update Token Data  to the approvedTokens mapping
        //adding marketData to the approvedToken mapping
        Market storage oldMarketData = approvedTokens[_tokenAddress];
       
        if(_marketData.isSP){
            approvedTokens[_tokenAddress] = Market(_marketData.isSP, _marketData.isReversedLoan, _marketData.tokenLimitPerReverseLoan, oldMarketData.gToken);   
        } else {
            approvedTokens[_tokenAddress] = Market(_marketData.isSP, _marketData.isReversedLoan, _marketData.tokenLimitPerReverseLoan, address(0x0));
        }

        emit TokenUpdated(_tokenAddress, _marketData);
    }

    /**
    @dev function to remove token key from the allapprovedtokens array
    @param _tokenAddress removing token address from array
     */
    function _removeToken(address _tokenAddress) internal {
        address[] memory auxArray = new address[](
            allapprovedTokenContracts.length - 1
        );
        for (uint256 i = 0; i < allapprovedTokenContracts.length; i++) {
            if (allapprovedTokenContracts[i] != _tokenAddress) {
                auxArray[i] = allapprovedTokenContracts[i];
            }
        }
        allapprovedTokenContracts = auxArray;
    }

    // /**
    // @dev remove NFTKey from index of the hash of contract + nft token id
    // @param index index of the hash of nft + contract 
    //  */
    // function _removeNFTKey(uint256 index) internal {
    //     // if (index > allapprovedNFTContracts.length) return;
    //     if (allapprovedNFTContracts.length != 1) {
    //         for (
    //             uint256 i = index;
    //             i < allapprovedNFTContracts.length - 1;
    //             i++
    //         ) {
    //             allapprovedNFTContracts[i] = allapprovedNFTContracts[i + 1];
    //         }
    //     }
    //     allapprovedNFTContracts.pop();
    // }

    // /**
    // @dev find index of nft contract and tokenid, the bytes32 hash from the allapprovedNFTs array
    // @param _valueToFindAndRemove hash of the nft token and contract 
    //  */
    // function _getIndex(bytes32 _valueToFindAndRemove)
    //     internal
    //     view
    //     returns (uint256 index)
    // {
    //     for (uint256 i = 0; i < allapprovedNFTContracts.length; i++) {
    //         if (allapprovedNFTContracts[i] == _valueToFindAndRemove) {
    //             return i;
    //         }
    //     }
    // }

    //helper function to get nft contract + tokenid hash
    // /**
    // @dev get hash of the nftTokenId and contract address of NFT
    // @param _nftContract contract address of the NFT token
    // @param _tokenId token id of the nftContract
    //  */
    // function getNftHash(address _nftContract, uint256 _tokenId)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     bytes32 hash = keccak256(abi.encodePacked(_nftContract, _tokenId));
    //     return hash;
    // }

     /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allapprovedTokenContracts.length; i++) {
            if (allapprovedTokenContracts[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }


    /**
    @dev internal function to add Strategic Partner Wallet Address to the approvedSps mapping
    @param _tokenAddress contract address of the approvedToken Sp
    @param _walletAddress sp wallet address added to the approvedSps
     */
    function _addSp(address _tokenAddress, address _walletAddress) internal {
        // add the sp wallet address to the approvedSps mapping
        approvedSps[_tokenAddress].push(_walletAddress);

        // push sp _walletAddress to allApprovedSps array
        allApprovedSps.push(_walletAddress);

        emit SPWalletAdded(_tokenAddress, _walletAddress);
    }

    

    /** 
    @dev check if _walletAddress is already added Sp in array
    @param _walletAddress wallet address checking 
    */

    function _isAlreadyAddedSp(address _walletAddress)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < allApprovedSps.length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }

    /**
    @dev checking the approvedSps mapping if already walletAddress
    @param _tokenAddress contract address of the approvedToken Sp
    @param _walletAddress wallet address of the approved Sp 
    */
    function _isAlreadyAddedSpFromMapping(
        address _tokenAddress,
        address _walletAddress
    ) internal view returns (bool) {
        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _walletAddress) {
                return true;
            }
        }
        return false;
    }
    
    /**
    @dev remove the Sp token address from the allapprovedsps array
    @param index index of the sp address being removed from the allApprovedSps
     */
    function _removeSpKey(uint256 index) internal {
        for (uint256 i = index; i < allApprovedSps.length - 1; i++) {
            allApprovedSps[i] = allApprovedSps[i + 1];
        }
        allApprovedSps.pop();
    }

    /**
    @dev remove Sp wallet address from the approvedSps mapping across specific tokenaddress
    @param index of the approved wallet sp
    @param _tokenAddress token contract address of the approvedToken sp
     */
    function _removeSpKeyfromMapping(uint256 index, address _tokenAddress)
        internal
    {
        for (
            uint256 i = index;
            i < approvedSps[_tokenAddress].length - 1;
            i++
        ) {
            approvedSps[_tokenAddress][i] = approvedSps[_tokenAddress][i + 1];
        }
        approvedSps[_tokenAddress].pop();
    }

    /**
    @dev getting index of sp from the allApprovedSps array
    @param _walletAddress getting this wallet address index  */
    function _getIndexofAddressfromArray(address _walletAddress)
        internal
        view
        returns (uint256 index)
    {
        for (uint256 i = 0; i < allApprovedSps.length; i++) {
            if (allApprovedSps[i] == _walletAddress) {
                return i;
            }
        }
    }

    /**
    @dev get index of the wallet from the approvedSps mapping
    @param tokenAddress token contract address
    @param _walletAddress getting this wallet address index
    */
    function _getWalletIndexfromMapping(
        address tokenAddress,
        address _walletAddress
    ) internal view returns (uint256 index) {
        for (uint256 i = 0; i < approvedSps[tokenAddress].length; i++) {
            if (approvedSps[tokenAddress][i] == _walletAddress) {
                return i;
            }
        }
    }


    /**
    @dev adding bulk sp wallet address to the approvedSps
    @param _tokenAddress token contract address as a key for sp wallets
    @param _walletAddress sp wallet addresses adding to the approvedSps mapping
     */
    function _addBulkSps(address _tokenAddress, address[] memory _walletAddress)
        internal
    {
        for (uint256 i = 0; i < _walletAddress.length; i++) {
            //checking Wallet if already added
            require(
                !_isAlreadyAddedSp(_walletAddress[i]),
                "one or more wallet addresses already added in allapprovedSps array"
            );

            require(
                !_isAlreadyAddedSpFromMapping(_tokenAddress, _walletAddress[i]),
                "One or More Wallet addresses already in mapping"
            );

            approvedSps[_tokenAddress].push(_walletAddress[i]);
            allApprovedSps.push(_walletAddress[i]);
        }

        emit BulkSpWalletAdded(_tokenAddress, _walletAddress);
    }

    
    /**
    @dev internal function to update Sp wallet Address, 
    doing it by removing old wallet first then add new wallet address
    @param _tokenAddress token contract address as a key to update sp wallet
    @param _oldWalletAddress old SP wallet address
    @param _newWalletAddress new SP wallet address
    
     */
    function _updateSp(
        address _tokenAddress,
        address _oldWalletAddress,
        address _newWalletAddress
    ) internal {
        //update wallet addres to the approved Sps mapping

        for (uint256 i = 0; i < approvedSps[_tokenAddress].length; i++) {
            if (approvedSps[_tokenAddress][i] == _oldWalletAddress) {
                // delete approvedSps[_tokenAddress][i];
                _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress));
                _removeSpKeyfromMapping(
                    _getIndexofAddressfromArray(approvedSps[_tokenAddress][i]),
                    _tokenAddress
                );
                approvedSps[_tokenAddress].push(_newWalletAddress);
                allApprovedSps.push(_newWalletAddress);
            }
        }

        emit SPWalletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    
    /**
    @dev update bulk SP wallets to the approvedSps
    @param _tokenAddress token contract address being updated
    @param _oldWalletAddress  array of old sp wallets 
    @param _newWalletAddress  array of the new sp wallets
     */
    function _updateBulkSps(
        address _tokenAddress,
        address[] memory _oldWalletAddress,
        address[] memory _newWalletAddress
    ) internal {
        require(
            _oldWalletAddress.length == _newWalletAddress.length,
            "GPR: Length of old and new wallet should be equal"
        );

        for (uint256 i = 0; i < _oldWalletAddress.length; i++) {
            //checking Wallet if already added
            require(
                _isAlreadyAddedSp(_oldWalletAddress[i]),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in array"
            );

            require(
                _isAlreadyAddedSpFromMapping(
                    _tokenAddress,
                    _oldWalletAddress[i]
                ),
                "GPR: cannot update the wallet addresses, token address not exist or not a SP, not in mapping"
            );

            // delete approvedSps[_tokenAddress][i];
            _removeSpKey(_getIndexofAddressfromArray(_oldWalletAddress[i]));
            _removeSpKeyfromMapping(
                _getWalletIndexfromMapping(_tokenAddress, _oldWalletAddress[i]),
                _tokenAddress
            );
            approvedSps[_tokenAddress].push(_newWalletAddress[i]);
            allApprovedSps.push(_newWalletAddress[i]);
        }

        emit BulkSpWAlletUpdated(
            _tokenAddress,
            _oldWalletAddress,
            _newWalletAddress
        );
    }

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

    event TokenAdded(address indexed tokenAddress);
    event TokenUpdated(address tokenAddress, Market _marketData);
    // event NFTAdded(bytes32 nftPlatform, address indexed nftContract, uint256 indexed tokenId);
    event TokenRemoved(address indexed tokenAddress);
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
    function addToken(address _tokenAddress, Market memory _market) external;

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
    function updateToken(address _tokenAddress, Market memory _marketData)
        external;

    /**
     *@dev function which remove tokenaddress from array and data from the mapping
     *@param _removeTokenAddress the key to remove
     */
    function removetoken(address _removeTokenAddress) external;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "hardhat/console.sol";

struct VestingWallet {
    address wallet;
    uint256 totalAmount;
    uint256 dayAmount;
    uint256 startDay;
    uint256 afterDays;
    bool nonLinear;
}
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GToken is Ownable, ERC20Burnable {

    using SafeMath for uint256;
    IERC20 spToken;
    
    /**
     * Setup the initial supply and types of vesting schemas
     **/

    constructor(string memory _name, string memory _symbol, address _spToken) ERC20(_name, _symbol) {
        spToken  = IERC20(_spToken);
    }

    function getMaxTotalSupply()
        public view returns (uint256)
    {
        return spToken.totalSupply();
    }

    function _mint(address account, uint256 amount) internal override {
        uint256 totalSupply = super.totalSupply();
        require(
            getMaxTotalSupply() >= totalSupply.add(amount),
            "Maximum supply exceeded!"
        );
        super._mint(account, amount);
    }
 
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./LoanData.sol";

interface ILoanMarket {

    function getLtv(uint256 _loanId)
        view
        external
        returns(uint256);

    function isLiquidationPending(uint256 _loanId)
        view 
        external
        returns(bool);



    event LoanOfferCreatedToken(
       LoanData.LoanDetails _loanDetails
    );

    event LoanOfferCreatedNFT(
        uint256 loanId,
        address  _borrower, 
        address[] _collateralERC721, 
        uint256[] _collateralERC721TokenId,
        uint256[] _nftPrice,
        bool _isPrivate,
        bool _isPartialFunding,
        address _borrowStableCoin
    );

    event LoanOfferAdjustedToken(
        LoanData.LoanDetails _loanDetails

    );

    event TokenLoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _loanAmount,
        uint256 _termsLengthInDays,
        uint256 _APYOffer,
        address[] _collateralTokens, 
        uint256[] _collateralAmounts, 
        LoanData.LoanType _loanType,
        bool _isPrivate,
        bool _isPartialFunding,
        address _borrowStableCoin
    );

    event LoanOfferCancelToken(
        uint256 loanId,
        address _borrower,
        LoanData.LoanStatus loanStatus
    );


    
}

