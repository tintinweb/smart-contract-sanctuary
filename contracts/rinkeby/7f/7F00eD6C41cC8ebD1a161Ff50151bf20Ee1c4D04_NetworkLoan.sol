// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldAdminRegistry.sol";
import "../../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/admininterfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IDexFactory.sol";
import "../../interfaces/IDexPair.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/NetworkLoanBase.sol";
import "../library/NetworkLoanData.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";

contract NetworkLoan is NetworkLoanBase {
    //Load library structs into contract
    using NetworkLoanData for *;
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
    }

    receive() external payable {}


    //modifier: only liquidators can liqudate pending liquidation calls
    modifier onlyLiquidatorRole(address liquidator) {
        require(
            govWorldLiquidator.isLiquidateAccess(liquidator),
            "GNM: Not a Gov Liquidator."
        );
        _;
    }

    //modifier: only super admin can withdraw contract balance
    modifier onlySuperAdmin(address superAdmin) {
        require(
            govAdminRegistry.isSuperAdminAccess(superAdmin),
            "GNM: Not a Gov Super Admin."
        );
        _;
    }
    

    /**
    @dev function to create Single || Multi (ERC20) Loan Offer by the BORROWER

    */
     function createLoan(NetworkLoanData.LoanDetails memory loanDetails)
        public
        payable
        {
        uint256 newLoanId = _getNextLoanId();

        require(loanDetails.paybackAmount == 0, "GNM: payback amount should be zero");
        require(msg.value > 0 ether, "GNM: Loan Amount Invalid");
        loanDetails.collateralAmount = msg.value;

        uint256 collatetralInBorrowed = this.getAltCoinPriceinStable(loanDetails.borrowStableCoin, loanDetails.collateralAmount);

        uint256 ltv  = this.calculateLTV(loanDetails.collateralAmount, loanDetails.borrowStableCoin, loanDetails.loanAmountInBorrowed);
        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);

        require(loanDetails.loanAmountInBorrowed <= maxLtv, "GNM: LTV not allowed.");
        require(ltv > 125, "GNM: Can not create loan at liquidation level.");

        //create uniquie loan hash for partial funding of loan
        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
             
        payable(address(this)).transfer(loanDetails.collateralAmount);


       borrowerOffers[newLoanId] = NetworkLoanData.LoanDetails(
            loanDetails.loanAmountInBorrowed,
            loanDetails.termsLengthInDays,
            loanDetails.apyOffer,
            loanDetails.isPrivate,
            loanDetails.isInsured,
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            loanDetails.paybackAmount
        );
       
        emit LoanOfferCreated(borrowerOffers[newLoanId]);
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
        
        require(borrowerOffers[_loanIdAdjusted].loanStatus == NetworkLoanData.LoanStatus.INACTIVE, "GNM, Loan cannot adjusted");
        require(borrowerOffers[_loanIdAdjusted].borrower == msg.sender, "GNM, Only Borrow Adjust Loan");

        uint256 collatetralInBorrowed = this.getAltCoinPriceinStable(borrowerOffers[_loanIdAdjusted].borrowStableCoin,_newLoanAmountBorrowed);
        uint256 ltv  = this.calculateLTV(borrowerOffers[_loanIdAdjusted].collateralAmount, borrowerOffers[_loanIdAdjusted].borrowStableCoin, _newLoanAmountBorrowed);
        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);
        
        require(_newLoanAmountBorrowed <= maxLtv, "GNM: LTV not allowed.");
        require(ltv > 125, "GNM: can not adjust loan to liquidation level.");

        borrowerOffers[_loanIdAdjusted] = NetworkLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            _isPrivate,
            _isInsured,
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            NetworkLoanData.LoanStatus.INACTIVE,
            payable(msg.sender),
            borrowerOffers[_loanIdAdjusted].paybackAmount
            
        );
        
        emit LoanOfferAdjusted(borrowerOffers[_loanIdAdjusted]);

    }


    /**
    @dev function to cancel the created laon offer for  type Single || Multi  Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public {

        require(borrowerOffers[_loanId].loanStatus == NetworkLoanData.LoanStatus.INACTIVE , "GNM, Loan cannot be cancel");
        require(borrowerOffers[_loanId].borrower == msg.sender, "GNM, Only Borrow can cancel");
        
        payable(msg.sender).transfer(borrowerOffers[_loanId].collateralAmount);        
        // delete borrowerOffers[_loanId];
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CANCELLED;
        emit LoanOfferCancel(_loanId, msg.sender, borrowerOffers[_loanId].loanStatus);
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoan(uint256 _loanId, uint256 _stableCoinAmount, bool _autoSell) public {

        require(borrowerOffers[_loanId].loanStatus == NetworkLoanData.LoanStatus.INACTIVE, "GNM, not inactive");
        require(borrowerOffers[_loanId].borrower != msg.sender, "GNM, self activation forbidden");
        require(borrowerOffers[_loanId].loanAmountInBorrowed == _stableCoinAmount, "GNM, insufficient amount");
        
        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
    
        uint256 apyFee = this.getAPYFee(borrowerOffers[_loanId]);
        uint256 loanAmountAfterAPYFee = borrowerOffers[_loanId].loanAmountInBorrowed.sub(apyFee);

        stableCoinAPYFee[address(this)] =  stableCoinAPYFee[address(this)].add(apyFee);

        //approving  from the front end
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        IERC20(borrowerOffers[_loanId].borrowStableCoin).transferFrom(msg.sender, address(this), apyFee);
        //loan amount send to borrower
        IERC20(borrowerOffers[_loanId].borrowStableCoin).transferFrom(msg.sender, borrowerOffers[_loanId].borrower, loanAmountAfterAPYFee);
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(_loanId);

        //activated loan id to the lender details
        activatedLoanByLenders[_loanId] =  NetworkLoanData.LenderDetails({
		    lender: payable(msg.sender),
            activationLoanTimeStamp: 1627798736,       //block.timestamp, //TODO change time to block.timestamp
            autoSell: _autoSell
        });

        emit LoanOfferActivated(_loanId, msg.sender, _stableCoinAmount,_autoSell);
    }

    function getTotalPaybackAmount(uint256 _loanId) external view returns (uint256, uint256) {

        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[_loanId];
        
        uint256 loanTermLengthPassed = block.timestamp.sub(activatedLoanByLenders[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays <= loanDetails.termsLengthInDays, "GNM: Loan already paybacked or liquidated.");
        
        uint256 apyFeeOriginal = this.getAPYFee(loanDetails);
        uint256 apyFeeBeforeLoanTermLengthEnd = ((loanDetails.loanAmountInBorrowed.mul(loanDetails.apyOffer).div(100)).div(365)).mul(loanTermLengthPassedInDays);
        
        uint256 unEarnedAPYFee =  apyFeeOriginal.sub(apyFeeBeforeLoanTermLengthEnd);
        uint256 unEarnedAPYPerForLender = govWorldProtocolRegistry.getUnearnedAPYPercentageForLender();

        return 
        (loanDetails.loanAmountInBorrowed.add(apyFeeBeforeLoanTermLengthEnd).add(unEarnedAPYFee.mul(unEarnedAPYPerForLender).div(100)),apyFeeBeforeLoanTermLengthEnd);  
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
       
        
        //contract will the repay staked collateral  to the borrower
        payable(msg.sender).transfer(borrowerOffers[_loanId].collateralAmount);
      
        NetworkLoanData.LenderDetails memory lenderDetails = activatedLoanByLenders[_loanId];

        (uint256 finalPaybackAmounttoLender,uint256 apyFeeBeforeLoanTermLengthEnd) = this.getTotalPaybackAmount(_loanId);

        stableCoinAPYFee[address(this)] = stableCoinAPYFee[address(this)].sub(apyFeeBeforeLoanTermLengthEnd);

        IERC20(borrowerOffers[_loanId].borrowStableCoin).transferFrom(borrowerOffers[_loanId].borrower, address(this), borrowerOffers[_loanId].loanAmountInBorrowed);
        IERC20(borrowerOffers[_loanId].borrowStableCoin).transfer(lenderDetails.lender, finalPaybackAmounttoLender);
        borrowerOffers[_loanId].paybackAmount = finalPaybackAmounttoLender;
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CLOSED;
        emit FullLoanPaybacked(_loanId, msg.sender, NetworkLoanData.LoanStatus.CLOSED);

    }

    /**
    @dev  loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public {
    
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[_loanId];

        require(borrowerOffers[_loanId].borrower == payable(msg.sender), "GNM, not borrower");
        require(borrowerOffers[_loanId].loanStatus == NetworkLoanData.LoanStatus.ACTIVE, "GNM, not active");
        require(_paybackAmount > 0  && _paybackAmount <= borrowerOffers[_loanId].loanAmountInBorrowed, "GNM: Invalid Loan Amount");
        uint256 totalPayback = _paybackAmount.add(loanDetails.paybackAmount);
        if(totalPayback >=  loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        } 
        else
        {   
            uint256 remainingLoanAmount =  loanDetails.loanAmountInBorrowed.sub(totalPayback);
            uint256 newLtv  = this.calculateLTV(loanDetails.collateralAmount, loanDetails.borrowStableCoin, remainingLoanAmount);
            require(newLtv > 125, "GNM: new LTV exceeds threshold.");
            IERC20(loanDetails.borrowStableCoin).transferFrom(payable(msg.sender), address(this), _paybackAmount);
            borrowerOffers[_loanId].paybackAmount = borrowerOffers[_loanId].paybackAmount.add(_paybackAmount);
            loanDetails.loanStatus = NetworkLoanData.LoanStatus.ACTIVE;
            emit PartialLoanPaybacked(loanId, _paybackAmount, payable(msg.sender));
        }
         
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateLoan(uint256 _loanId) public payable onlyLiquidatorRole(msg.sender) {
        
        require(borrowerOffers[_loanId].loanStatus == NetworkLoanData.LoanStatus.ACTIVE, "GNM, not active");
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[_loanId];
        NetworkLoanData.LenderDetails memory lenderDetails = activatedLoanByLenders[_loanId];

        uint256 loanTermLengthPassed = block.timestamp.sub(lenderDetails.activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);

        require(this.isLiquidationPending(_loanId) || (loanTermLengthPassedInDays > loanDetails.termsLengthInDays), "GNM: Liquidation Error");

        if(lenderDetails.autoSell  == true) {
            
            // loanDetails.collateralAmount == msg.value;
            address[] memory path = new  address[](2);
            path[0] = govPriceConsumer.WETHAddress();
            path[1] = loanDetails.borrowStableCoin;

            (uint amountIn, uint amountOut) = govPriceConsumer.getSwapData(govPriceConsumer.WETHAddress(),loanDetails.collateralAmount,loanDetails.borrowStableCoin);
                
            IUniswapSwapInterface swapInterface = IUniswapSwapInterface(govPriceConsumer.getSwapInterface());
            swapInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(amountOut, path, address(this), block.timestamp + 5 minutes);
            IERC20(loanDetails.borrowStableCoin).transfer(lenderDetails.lender, amountOut);

            borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.LIQUIDATED;
            emit AutoLiquidated(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral  to the lender
                //contract will the repay staked collateral  to the borrower
                payable(lenderDetails.lender).transfer(loanDetails.collateralAmount);
                borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.LIQUIDATED;
                emit LiquidatedCollaterals(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
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
     * @dev Returns ERC20  current all loan offer ids for a borrower
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
            NetworkLoanData.LoanDetails memory details = borrowerOffers[i];
            if (uint256(details.loanStatus) == _status) {
                activeOfferIds[i] = i;
            }
        }
        return activeOfferIds;
    }

    /**
    @dev function to get altcoin amount in stable coin.
    @param _stableCoin of the altcoin
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin, 
        uint256 _collateralAmount
        ) external view override returns(uint256) 
        {
    
        uint256 collateralAmountinStable;
        if(govPriceConsumer.isChainlinFeedEnabled(govPriceConsumer.WETHAddress()) && govPriceConsumer.isChainlinFeedEnabled(_stableCoin)) {
               
                (int collateralChainlinkUsd) = govPriceConsumer.getNetworkPriceFromChainlinkinUSD();
                uint256 collateralUsd = (uint256(collateralChainlinkUsd) * _collateralAmount).div(8); 
                (int priceFromChainLinkinStable, uint8 stableDecimals) = govPriceConsumer.getLatestUsdPriceFromChainlink(_stableCoin);
                collateralAmountinStable = collateralAmountinStable.add(collateralUsd.div(uint256(priceFromChainLinkinStable)).mul(stableDecimals));
                return collateralAmountinStable;
        }
        else {
                collateralAmountinStable = collateralAmountinStable.add(govPriceConsumer.getDexTokenPrice(_stableCoin, govPriceConsumer.WETHAddress(), _collateralAmount));
                return collateralAmountinStable;
        } 
        
    }


    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral 
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId)
        external
        view
        override
        returns (uint256)
        {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[_loanId];
        return this.calculateLTV(loanDetails.collateralAmount, loanDetails.borrowStableCoin, loanDetails.loanAmountInBorrowed.sub(loanDetails.paybackAmount));
    }


  /**
    @dev Calculates LTV based on dex  price
    @param _stakedCollateralAmount amount of staked collateral of Network Coin
    @param _loanAmount total borrower loan amount in borrowed .
     */
    function calculateLTV(
        uint256 _stakedCollateralAmount, 
        address _borrowed,
        uint256 _loanAmount
    )
        external
        view
        returns (uint256)
    {
        //IERC20Extras stableDecimnals = IERC20Extras(stkaedCollateral);
        uint256 totalCollateralInBorrowed;
        
        uint256 priceofCollateral = this.getAltCoinPriceinStable(_borrowed,_stakedCollateralAmount);
        totalCollateralInBorrowed = totalCollateralInBorrowed.add(priceofCollateral); 

        return (totalCollateralInBorrowed.mul(100)).div(_loanAmount);
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
            if (borrowerOffers[i].loanStatus == NetworkLoanData.LoanStatus.INACTIVE) {
                count++;
            }
        }
        return count;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in  case
     */
    function _getNextLoanId() private view returns (uint256) {
        return loanId.add(1);
    }

    /**
    @dev returns the current loan id which will be assigned to the next createLoan
     */
    function getCurrentLoanId() public view returns (uint256) {
        return loanId;
    }

    /**
    @dev get loan details of the single or multi-
     */
    function getborrowerOffers(uint256 _loanId) public view returns(NetworkLoanData.LoanDetails memory) {
        return borrowerOffers[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId) public view returns(NetworkLoanData.LenderDetails memory ) {
        return activatedLoanByLenders[_loanId];
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
            if (borrowerOffers[i].loanStatus == NetworkLoanData.LoanStatus.ACTIVE) {
                count++;
            }
        }
        return count;
    }

    function getNetworkBalance(address _address) public view returns (uint) {
        return _address.balance;
    }

    //only super admin can withdraw coins
    function withdrawCoin( uint _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        
        require(_withdrawAmount <= address(this).balance, "GNL: Amount Invalid");
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
        
    }

    //only super admin can withdraw tokens
    function withdrawToken(address _tokenAddress, uint _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        
        require(_withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)));
        IERC20(_tokenAddress).transfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    //swap testing TODO will remove this function
    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateloantesting(uint256 _loanId) public payable onlyLiquidatorRole(msg.sender) {
        
        require(borrowerOffers[_loanId].loanStatus == NetworkLoanData.LoanStatus.ACTIVE, "GLM, not active");

        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[_loanId];
        NetworkLoanData.LenderDetails memory lenderDetails = activatedLoanByLenders[_loanId];

        if(lenderDetails.autoSell  == true) {
            
            // loanDetails.collateralAmount == msg.value;
            address[] memory path = new  address[](2);
            path[0] = govPriceConsumer.WETHAddress();
            path[1] = loanDetails.borrowStableCoin;

            (uint amountIn, uint amountOut) = govPriceConsumer.getSwapData(govPriceConsumer.WETHAddress(),loanDetails.collateralAmount,loanDetails.borrowStableCoin);
                
            IUniswapSwapInterface swapInterface = IUniswapSwapInterface(govPriceConsumer.getSwapInterface());
            // payable(address(swapInterface)).transfer(loanDetails.collateralAmount);
            IERC20(govPriceConsumer.WETHAddress()).approve(address(swapInterface), amountOut);
            swapInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(amountOut, path, address(this), block.timestamp + 5 minutes);
            IERC20(loanDetails.borrowStableCoin).transfer(lenderDetails.lender, amountOut);

            borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.LIQUIDATED;
            emit AutoLiquidated(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral  to the lender
                //contract will the repay staked collateral  to the borrower
                payable(lenderDetails.lender).transfer(loanDetails.collateralAmount);
                borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.LIQUIDATED;
                emit LiquidatedCollaterals(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        }
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

 struct LiquidatorAccess {
        bool liquidateRole;
    }

interface IGovLiquidator {

    event NewLiquidatorApproved(address indexed _newLiquidator, LiquidatorAccess _liquidatorRole);

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
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

// SPDX-License-Identifier: agpl-3.0


pragma solidity ^0.8.0;
pragma abicoder v2;

import "../library/NetworkLoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/INetworkLoan.sol";

abstract contract NetworkLoanBase is INetworkLoan {
    //Load library structs into contract
    using NetworkLoanData for *;
    using NetworkLoanData for bytes32;
    using SafeMath for uint256;

    //saves the transaction hash of the create loan offer transaction as loanId
    //saves information in loanOffers when createLoan is called
    mapping(uint256 => NetworkLoanData.LoanDetails) public borrowerOffers;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => NetworkLoanData.LenderDetails) public activatedLoanByLenders;

    //array of all loan offer ids of the ERC20 tokens.
    uint256[] public loanOfferIds;

    //erc20 tokens loan offer mapping
    mapping(address => uint256[]) borrowerloanOfferIds;

    //mapping address of lender to the loan Ids
    mapping(address => uint256[]) lenderActivatedLoanIds;

    //mapping address stable to the APY Fee of stable
    mapping(address => uint256) public stableCoinAPYFee;

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails) external pure override returns(uint256) {
        // APY Fee Formula
        return ((_loanDetails.loanAmountInBorrowed.mul(_loanDetails.apyOffer).div(100)).div(365)).mul(_loanDetails.termsLengthInDays);

        
    }

    
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NetworkLoanData {
    using SafeMath for uint256;

    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED,
        TERMINATED
    }

    struct LenderDetails {
        address payable lender;
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
        //private loans will not appear on loan market
        bool isPrivate;
        //Future use flag to insure funds as they go to protocol.
        bool isInsured;
        uint256 collateralAmount;
        address borrowStableCoin;
        //current status of the loan
        LoanStatus loanStatus;
        //borrower's address
        address payable borrower;
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

    function getAllChainlinAggiratorsContract() external view returns(address[] memory);

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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "../library/NetworkLoanData.sol";

interface INetworkLoan {
    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);

    event LoanOfferCreated(NetworkLoanData.LoanDetails _loanDetails);

    event LoanOfferAdjusted(NetworkLoanData.LoanDetails _loanDetails);

    event LoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancel(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event FullLoanPaybacked(
        uint256 loanId,
        address _borrower,
        NetworkLoanData.LoanStatus loanStatus
    );

    event PartialLoanPaybacked(
        uint256 loanId,
        uint256 paybackAmount,
        address _borrower
    );

    event AutoLiquidated(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event LiquidatedCollaterals(
        uint256 _loanId,
        NetworkLoanData.LoanStatus loanStatus
    );

    event WithdrawalNetworkCoin(
        address indexed _receiver,
        uint256 _withdrawAmount
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