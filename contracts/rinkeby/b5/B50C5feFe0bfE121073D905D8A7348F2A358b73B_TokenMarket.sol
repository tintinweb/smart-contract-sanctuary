// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldAdminRegistry.sol";
import "../../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/admininterfaces/IGovWorldTierLevel.sol";
import "../liquidator/IGovLiquidator.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/TokenMarketBase.sol";
import "../library/TokenLoanData.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "../../claimtoken/IGovClaimToken.sol";

interface IGToken{  
    function mint(address account, uint256 amount) external ;
    function burnFrom(address account, uint256 amount) external;
}


contract TokenMarket is TokenMarketBase {
    //Load library structs into contract
    using TokenLoanData for *;
    using SafeMath for uint256;

    address public liquidatorContract;

    address govWorldLiquidator;
    address govWorldProtocolRegistry;
    address govWorldTierLevel;
    address govPriceConsumer;
    address govAdminRegistry;
    address govClaimToken;
    
    uint256 public loanId = 0;
    uint256 constant EXPO = 1e18;
    uint256 constant BASE = 100 * EXPO;
    
    constructor(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel,
        address _govPriceConsumer,
        address _govAdminRegistry,
        address _govClaimToken
    ) {
        govWorldLiquidator = _govWorldLiquidator;
        govWorldProtocolRegistry = _govWorldProtocolRegistry;
        govWorldTierLevel = _govWorldTierLevel;
        govPriceConsumer = _govPriceConsumer;
        govAdminRegistry = _govAdminRegistry;
        liquidatorContract = _govWorldLiquidator;
        govClaimToken = _govClaimToken;

        loanId = 0;
    }

    receive() external payable {}

    /**
    @dev function to create Single || Multi Token(ERC20) Loan Offer by the BORROWER
    */
     function createLoan(TokenLoanData.LoanDetails memory loanDetails)
        public
        {
        uint256 newLoanId = loanId.add(1);
        require(loanDetails.stakedCollateralTokens.length == loanDetails.stakedCollateralAmounts.length && loanDetails.stakedCollateralTokens.length  == loanDetails.isMintSp.length,"GLM: Tokens and amounts length must be same");
        require(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType || TokenLoanData.LoanType.MULTI_TOKEN == loanDetails.loanType,"GLM: Invalid Loan Type");
        require(loanDetails.paybackAmount == 0, "GLM: payback amount should be zero");
        TierData memory  tierData = IGovWorldTierLevel(govWorldTierLevel).getTierDatabyGovBalance(msg.sender);
        require(tierData.singleToken || tierData.multiToken, "GLM: Not Eligible");
        if(TokenLoanData.LoanType.SINGLE_TOKEN  == loanDetails.loanType) {//for single tokens collateral length must be one.
            require(loanDetails.stakedCollateralTokens.length == 1,"GLM: Multi-tokens not allowed in SINGLE TOKEN loan type.");
        }

        uint256 collatetralInBorrowed = 0;
        IGovPriceConsumer _priceConsumer = IGovPriceConsumer(govPriceConsumer);

        for(uint256 index =  0 ; index < loanDetails.stakedCollateralAmounts.length ; index ++){
             address claimToken = IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[index]);
             if(IGovClaimToken(govClaimToken).isClaimToken(claimToken)) {
                 collatetralInBorrowed = collatetralInBorrowed.add(_priceConsumer.getSUNTokenPrice(claimToken, loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]));
             } else {
                 collatetralInBorrowed = collatetralInBorrowed.add(_priceConsumer.getAltCoinPriceinStable(loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]));
             }
        }
        uint256 ltv  = _priceConsumer.calculateLTV(loanDetails.stakedCollateralAmounts, loanDetails.stakedCollateralTokens, loanDetails.borrowStableCoin, loanDetails.loanAmountInBorrowed);
        uint256 maxLtv = IGovWorldTierLevel(govWorldTierLevel).getMaxLtv(collatetralInBorrowed, msg.sender);

        require(loanDetails.loanAmountInBorrowed <= maxLtv, "GLM: LTV not allowed.");
        require(ltv > 125, "GLM: Can not create loan at liquidation level.");

        //create uniquie loan hash for partial funding of loan
        borrowerloanOfferIds[msg.sender].push(newLoanId);
        loanOfferIds.push(newLoanId);
        //loop through all staked collateral tokens.
        for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralTokens.length ; i++){
            address claimToken = IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[i]);
            require(IGovWorldProtocolRegistry(govWorldProtocolRegistry).isTokenApproved(loanDetails.stakedCollateralTokens[i]) || IGovClaimToken(govClaimToken).isClaimToken(claimToken),"GLM: One or more tokens not approved.");
            require(loanDetails.isMintSp[i] == false, "GLM: mint error");
            uint256 allowance =  IERC20(loanDetails.stakedCollateralTokens[i]).allowance(msg.sender, address(this));
            require( allowance >= loanDetails.stakedCollateralAmounts[i],"GLM: Transfer amount exceeds allowance.");
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
            loanDetails.paybackAmount,
            loanDetails.isMintSp
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
        
        TokenLoanData.LoanDetails memory loanDetails = loanOffersToken[_loanIdAdjusted];

        require(loanDetails.loanType == TokenLoanData.LoanType.SINGLE_TOKEN || loanDetails.loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(loanDetails.loanStatus == TokenLoanData.LoanStatus.INACTIVE, "GLM, Loan cannot adjusted");
        require(loanDetails.borrower == msg.sender, "GLM, Only Borrow Adjust Loan");

        IGovPriceConsumer _priceConsumer = IGovPriceConsumer(govPriceConsumer);

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanDetails.stakedCollateralAmounts.length ; index ++){
             address claimToken = IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanDetails.stakedCollateralTokens[index]);
             if(IGovClaimToken(govClaimToken).isClaimToken(claimToken)) {
                 collatetralInBorrowed = collatetralInBorrowed.add(_priceConsumer.getSUNTokenPrice(claimToken, loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]));
             } else {
                 collatetralInBorrowed = collatetralInBorrowed.add(_priceConsumer.getAltCoinPriceinStable(loanDetails.borrowStableCoin, loanDetails.stakedCollateralTokens[index], loanDetails.stakedCollateralAmounts[index]));
             }
        }

        uint256 ltv  = IGovPriceConsumer(govPriceConsumer).calculateLTV(loanDetails.stakedCollateralAmounts, loanDetails.stakedCollateralTokens, loanDetails.borrowStableCoin, _newLoanAmountBorrowed);
        uint256 maxLtv = IGovWorldTierLevel(govWorldTierLevel).getMaxLtv(collatetralInBorrowed, msg.sender);
        
        require(_newLoanAmountBorrowed <= maxLtv, "GLM: LTV not allowed.");
        require(ltv > 125, "GLM: can not adjust loan to liquidation level.");

        loanDetails = TokenLoanData.LoanDetails(
            _newLoanAmountBorrowed,
            _newTermsLengthInDays,
            _newAPYOffer,
            loanDetails.loanType,
            _isPrivate,
            _isInsured,
            loanDetails.stakedCollateralTokens,
            loanDetails.stakedCollateralAmounts,
            loanDetails.borrowStableCoin,
            TokenLoanData.LoanStatus.INACTIVE,
            msg.sender,
            loanDetails.paybackAmount,
            loanDetails.isMintSp
            
        );
        
        emit LoanOfferAdjustedToken(loanDetails);

    }


    /**
    @dev function to cancel the created laon offer for token type Single || Multi Token Colletrals
    @param _loanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function loanOfferCancel(uint256 _loanId) public {
        require(loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.SINGLE_TOKEN || loanOffersToken[_loanId].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: Invalid Loan Type");
        require(loanOffersToken[_loanId].loanStatus == TokenLoanData.LoanStatus.INACTIVE , "GLM, Loan cannot be cancel");
        require(loanOffersToken[_loanId].borrower == msg.sender, "GLM, Only Borrow can cancel");

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
        
        // address claimToken = IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanOffersToken[loanIds[i]].stakedCollateralTokens[i]);
        
        if(IGovClaimToken(govClaimToken).isClaimToken(IGovClaimToken(govClaimToken).getClaimTokenofSUNToken(loanOffersToken[loanIds[i]].stakedCollateralTokens[i]))) {
            require(_autoSell[i] == false, "GTM: autosell should be false for SUN Collateral Token"); 
        }

        require(loanOffersToken[loanIds[i]].loanType == TokenLoanData.LoanType.SINGLE_TOKEN 
            || loanOffersToken[loanIds[i]].loanType == TokenLoanData.LoanType.MULTI_TOKEN,"GLM: invalid loan type");
        require(loanOffersToken[loanIds[i]].loanStatus == TokenLoanData.LoanStatus.INACTIVE, "GLM, not inactive");
        require(loanOffersToken[loanIds[i]].borrower != msg.sender, "GLM, self activation forbidden");
        require( loanOffersToken[loanIds[i]].loanAmountInBorrowed == stableCoinAmounts[i], "GLM, insufficient amount");
        require(loanIds.length == stableCoinAmounts.length && loanIds.length == _autoSell.length, "GLM: length not match");        
        
        uint apyFee = this.getAPYFee(loanOffersToken[loanIds[i]]);
        uint platformFee = loanOffersToken[loanIds[i]].loanAmountInBorrowed.mul(IGovWorldProtocolRegistry(govWorldProtocolRegistry).getGovPlatformFee()).div(10000);
        uint loanAmountAfterCut = loanOffersToken[loanIds[i]].loanAmountInBorrowed.sub(apyFee+platformFee);
        stableCoinAPYFeeFromToken[loanOffersToken[loanIds[i]].borrowStableCoin] =  stableCoinAPYFeeFromToken[loanOffersToken[loanIds[i]].borrowStableCoin].add(apyFee+platformFee);
        
        require((apyFee + loanAmountAfterCut + platformFee)  == loanOffersToken[loanIds[i]].loanAmountInBorrowed, "GLM, invalid amount");
        
        //checking again the collateral tokens approval from the borrower
        //contract will now hold the staked collateral tokens
        for(uint256 k  = 0 ; k  <  loanOffersToken[loanIds[i]].stakedCollateralTokens.length; k++){
            uint256 allowance =  IERC20(loanOffersToken[loanIds[i]].stakedCollateralTokens[k]).allowance(loanOffersToken[loanIds[i]].borrower, address(this)); //TODO change approval address in testing file
            require( allowance >= loanOffersToken[loanIds[i]].stakedCollateralAmounts[k],"GLM: Transfer amount exceeds allowance.");
            
            IERC20(loanOffersToken[loanIds[i]].stakedCollateralTokens[k]).transferFrom(loanOffersToken[loanIds[i]].borrower, govWorldLiquidator, loanOffersToken[loanIds[i]].stakedCollateralAmounts[k]);

            Market memory  market = IGovWorldProtocolRegistry(govWorldProtocolRegistry).getSingleApproveToken(loanOffersToken[loanIds[i]].stakedCollateralTokens[k]);
            IGToken gtoken = IGToken(market.gToken);
            
            if(market.isSP && market.isMint) {
                gtoken.mint(loanOffersToken[loanIds[i]].borrower, loanOffersToken[loanIds[i]].stakedCollateralAmounts[k]);
                loanOffersToken[loanIds[i]].isMintSp[i] = true;
            }
        }
        
        //approving token from the front end
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transferFrom(msg.sender, address(this), loanOffersToken[loanIds[i]].loanAmountInBorrowed);

        // APY Fee transfer to the liquidator contract
        IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transfer(govWorldLiquidator, apyFee);

        //loan amount send to borrower
        IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transfer(loanOffersToken[loanIds[i]].borrower, loanAmountAfterCut);
        //TODO below line, admin fee will be removed, as asked by client 
        // IERC20(loanOffersToken[loanIds[i]].borrowStableCoin).transfer((govWorldProtocolRegistry.getAdminFeeWallet()), (platformFee.mul(govWorldProtocolRegistry.getAdminWalletPercentage()).div(100)));
        loanOffersToken[loanIds[i]].loanStatus = TokenLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(loanIds[i]);

        //activated loan id to the lender details
        activatedLoanOffersFull[loanIds[i]] =  TokenLoanData.LenderDetails({
		    lender: msg.sender,
            activationLoanTimeStamp: 1636522952,       // should be block.timestamp, //TODO change time to block.timestamp
            autoSell: _autoSell[i]
        });

        emit TokenLoanOfferActivated(loanIds[i], msg.sender, stableCoinAmounts[i],_autoSell[i]);
        }

    }

    /**
    @dev token loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount) public {
        require(
            loanOffersToken[_loanId].borrower == msg.sender,
            "GTM: caller not a borrower."
        );
        IGovLiquidator(govWorldLiquidator).payback(_loanId, _paybackAmount);   
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateLoan(uint256 _loanId) public {
        require(
            IGovLiquidator(govWorldLiquidator).isLiquidateAccess(msg.sender),
            "GTM: Not a Gov Liquidator."
        );
        IGovLiquidator(govWorldLiquidator).liquidateLoan(_loanId);
    }
    


    //TODO withdraw functions are commented due to code size error
    //only super admin can withdraw coins
    function withdrawCoin( uint256 _withdrawAmount, address payable _walletAddress) public {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(msg.sender),
            "GTM: Not a Gov Super Admin."
        );
        require(_withdrawAmount <= address(this).balance, "GTM: Amount Invalid");
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    //only super admin can withdraw tokens
    function withdrawToken(address _tokenAddress, uint256 _withdrawAmount, address payable _walletAddress) public{
         require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(msg.sender),
            "GTM: Not a Gov Super Admin."
         );
        require(_withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)), "GTM: Amount Invalid");
        IERC20(_tokenAddress).transfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    /**
    //  * @dev Returns get all loan offers.
    //  * @param _status LoanStatus  ACTIVE=0, INACTIVE=1, CLOSED=2, CANCELLED=3, LIQUIDATED=4, TERMINATED=5
    //  */
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
    @dev returns the current loan id which will be assigned to the next createLoan
    */
    function getCurrentLoanId() public view returns (uint256) {
        return loanId;
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId) public view override returns(TokenLoanData.LenderDetails memory ) {
        return activatedLoanOffersFull[_loanId];
    }

    /**
    @dev get loan details of the single or multi-token
    */
    function getLoanOffersToken(uint256 _loanId) public view override returns(TokenLoanData.LoanDetails memory) {
         return loanOffersToken[_loanId];
     }
    
    /**
    @dev swap tokens by the token market contract
     */
    function swapCollateralTokens(
        address collateralToken,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline
    ) 
        external 
        override 
    {
        require(msg.sender == liquidatorContract, 'GTM: Not Token Market!');
        IUniswapSwapInterface swapInterface = IUniswapSwapInterface(IGovPriceConsumer(govPriceConsumer).getSwapInterface(collateralToken));
        IERC20(collateralToken).approve(address(swapInterface), amountIn);
        swapInterface.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOut, path, to, deadline);
    }

    /**
    @dev transfer token to the liquidator contract
     */
    function transferCollateral(address _collateralToken, address _to, uint256 _amount) external override {
        require(msg.sender == liquidatorContract, 'GTM: Not Token Market!');
        require(_amount <= IERC20(_collateralToken).balanceOf(address(this)), "GTM: amount error");
        IERC20(_collateralToken).transfer(_to, _amount);
    }

    function getStableCoinAPYFeeinContract(address _stableCoin) external view override returns (uint256) {
        return stableCoinAPYFeeFromToken[_stableCoin];
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

import "../library/TokenLoanData.sol";

interface IGovLiquidator {
    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);
    function liquidateLoan(uint256 _loanId) external;
    function getLtv(uint256 _loanId) external view returns (uint256);
    function isLiquidationPending(uint256 _loanId) external view returns (bool);
    function payback(uint256 _loanId, uint256 _paybackAmount) external;
 

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
    address dexRouter;
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
    bool isClaimToken;
}


interface IGovWorldProtocolRegistry {
    
    
    /** external functions of the Gov Protocol Contract */
    /**
    @dev function to add token to approvedTokens mapping
    *@param _tokenAddress of the new token Address
    *@param  _market of the _tokenAddress
    */
    function addTokens(address[] memory _tokenAddress, Market[] memory _market)
        external;

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

    function getGovPlatformFee() external view returns(uint256);
    function getThresholdPercentage() external view returns(uint256);
    function getAutosellPercentage() external view returns(uint256);

    function getAdminWalletPercentage() external view returns(uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getTokenMarket() external view returns(address[] memory);

    function getAdminFeeWallet() external view returns(address);

    function getSingleTokenSps(address _tokenAddress) external view returns (address[] memory);

    function isAddedSPWallet(
        address _tokenAddress,
        address _walletAddress
    ) external view returns (bool);
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

    function getTierNamebyWalletAddress(address userWalletAddress) external view returns (bytes32 tierLevel);

    function getTierDatabyGovBalanceorNFTAddress(address[] memory nftContract, address userWallet) external view returns (TierData memory _tierData);

    function getMaxLtv(uint256 collateralInBorrowed,address borrower) external view returns(uint256);
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
        return ((_loanDetails.loanAmountInBorrowed.mul(_loanDetails.apyOffer).div(10000)).div(365)).mul(_loanDetails.termsLengthInDays);  
    }

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(uint loanAmount, uint autosellAPY, uint256 loanterminDays) external pure override returns(uint256) {
        // APY Fee Formula
        return ((loanAmount.mul(autosellAPY).div(10000)).div(365)).mul(loanterminDays);  
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
		bool[] isMintSp;
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
    
    function getSwapInterface(address _collateralTokenAddress) external view returns (address);

    function getSwapInterfaceForETH() external view returns (address);

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

    function getAltCoinPriceinStable(
        address _stableCoin,
        address _altCoin,
        uint256 _collateralAmount
    ) external view returns (uint256);

    function getClaimTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
        ) external view returns (uint256);

    function calculateLTV(
        uint256[] memory _stakedCollateralAmounts, 
        address[] memory _stakedCollateralTokens, 
        address  _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

     function getSUNTokenPrice(
         address _claimToken,
         address _stable,
         address _sunToken,
         uint256 _amount) 
        external view returns(uint256);

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

struct ClaimTokenData {
        address[] sunTokens;
        uint256[] sunTokenPricePercentage;
        address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
}

interface IGovClaimToken {
    function isClaimToken(address _claimTokenAddress)
        external
        view
        returns (bool);

    function getClaimTokensData(address _claimTokenAddress) external view returns (ClaimTokenData memory);

    function getClaimTokenofSUNToken(address _sunToken) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;
import "../library/TokenLoanData.sol";

interface ITokenMarket {


    /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFee(TokenLoanData.LoanDetails memory _loanDetails)
        external
        returns (uint256);
    
    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(uint loanAmount, uint autosellAPY, uint256 loanterminDays) 
        external
        returns(uint256);

     /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId) external view returns(TokenLoanData.LenderDetails memory );

    /**
    @dev get loan details of the single or multi-token
    */
    function getLoanOffersToken(uint256 _loanId) external view returns(TokenLoanData.LoanDetails memory);

    // function getTotalPaybackAmount(uint256 _loanId) external view returns (uint256, uint256, uint256);

    function getStableCoinAPYFeeinContract(address _stableCoin) external view returns (uint256);

    function swapCollateralTokens(
        address collateralToken,
        uint256 amountIn,
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline) external;

    function transferCollateral(address _collateralToken, address _to, uint256 _amount) external;

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
        address _lender,
        uint256 _paybackAmount,
        TokenLoanData.LoanStatus loanStatus,
        uint256 _earnedAPY
    );

    event PartialTokensLoanPaybacked(
        uint256 loanId,
        address _borrower,
        address _lender,
        uint256 paybackAmount
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