// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/admininterfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/NftMarketBase.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract NftMarket is NftMarketBase, ERC721Holder {
    //Load library structs into contract
    using NftLoanData for *;
    using SafeMath for uint256;
    using SafeMath for  uint8;

    IGovLiquidator govWorldLiquidator;
    IGovWorldProtocolRegistry govWorldProtocolRegistry;
    IGovWorldTierLevel govWorldTierLevel;
    
    uint256 public loanIdNFT = 0;

    constructor(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel
    ) {
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(_govWorldProtocolRegistry);
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
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
    @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    @param  loanDetailsNFT includes the following struct
    */
    function createLoanOfferNFT(NftLoanData.LoanDetailsNFT memory loanDetailsNFT)
        public
        {
        uint256 newLoanIdNFT = _getNextLoanIdNFT();

        require((loanDetailsNFT.stakedCollateralNFTsAddress.length == loanDetailsNFT.stakedCollateralNFTId.length) == (loanDetailsNFT.stakedCollateralNFTId.length == loanDetailsNFT.stakedNFTPrice.length),"GLM: Length not equal");
        require(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType || NftLoanData.LoanType.MULTI_NFT == loanDetailsNFT.loanType,"GLM: Invalid Loan Type");
        // if(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType) { //for single tokens collateral length must be one.
        //     require(loanDetailsNFT.stakedCollateralNFTsAddress.length == 1,"GLM: MULTI-NFTs not allowed");
        // }

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanDetailsNFT.stakedNFTPrice.length ; index ++){
            collatetralInBorrowed +=  loanDetailsNFT.stakedNFTPrice[index];
        }

        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);
        require(loanDetailsNFT.loanAmountInBorrowed <= maxLtv, "GLM: LTV not allowed.");
        
        //create uniquie loan hash
        borrowerloanOffersNFTs[msg.sender].push(newLoanIdNFT);
        loanOfferIdsNFTs.push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        for(uint256 i  = 0 ; i  <  loanDetailsNFT.stakedCollateralNFTsAddress.length ; i++){
            //contract will now hold the staked collateral tokens
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).safeTransferFrom(msg.sender, address(this), loanDetailsNFT.stakedCollateralNFTId[i]);
        }
        loanOffersNFT[newLoanIdNFT] = NftLoanData.LoanDetailsNFT(
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.loanType,
            NftLoanData.LoanStatus.INACTIVE,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.isInsured,
            msg.sender,
            loanDetailsNFT.borrowStableCoin
        );
        
        emit LoanOfferCreatedNFT(loanOffersNFT[newLoanIdNFT]);

        _incrementLoanIdNFT();
    }

    /**
    @dev function to cancel the created laon offer for token type Single || Multi NFT Colletrals
    @param _nftloanId loan Id which is being cancelled/removed, will delete all the loan details from the mapping
     */
    function nftloanOfferCancel(uint256 _nftloanId) public {

        require(loanOffersNFT[_nftloanId].loanType == NftLoanData.LoanType.SINGLE_NFT || loanOffersNFT[_nftloanId].loanType == NftLoanData.LoanType.MULTI_NFT,"GLM: Invalid Loan Type");
        require(loanOffersNFT[_nftloanId].loanStatus == NftLoanData.LoanStatus.INACTIVE, "GLM, cannot be cancel");
        require(loanOffersNFT[_nftloanId].borrower == msg.sender, "GLM, Only Borrow can cancel Loan");
        
        for(uint i =0; i < loanOffersNFT[_nftloanId].stakedCollateralNFTsAddress.length; i++) {
            
            IERC721(loanOffersNFT[_nftloanId].stakedCollateralNFTsAddress[i]).safeTransferFrom(address(this), msg.sender, loanOffersNFT[_nftloanId].stakedCollateralNFTId[i]);
        }
        // delete loanOffersNFT[_nftloanId]; //not deleting from just cancelling
        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.CANCELLED;

        emit LoanOfferCancelNFT(_nftloanId, msg.sender, loanOffersNFT[_nftloanId].loanStatus);

        
    }

    /**
    @dev function to adjust already created loan offer, while in inactive state
    @param  _nftloanIdAdjusted, the existing loan id which is being adjusted while in inactive state
    @param _newLoanAmountBorrowed, the new loan amount borrower is requesting
    @param _newTermsLengthInDays, borrower changing the loan term in days
    @param _newAPYOffer, percentage of the APY offer borrower is adjusting for the lender
    @param _isPrivate, boolena value of true if private otherwise false
    @param _isInsured, isinsured true or false
     */
    function nftLoanOfferAdjusted(
        uint256 _nftloanIdAdjusted,
        uint256 _newLoanAmountBorrowed,
        uint56 _newTermsLengthInDays,
        uint32 _newAPYOffer,
        bool _isPrivate,
        bool _isInsured
        ) public {
        
        require(loanOffersNFT[_nftloanIdAdjusted].loanType == NftLoanData.LoanType.SINGLE_NFT || loanOffersNFT[_nftloanIdAdjusted].loanType == NftLoanData.LoanType.MULTI_NFT,"GLM: Invalid Loan Type");
        require(loanOffersNFT[_nftloanIdAdjusted].loanStatus == NftLoanData.LoanStatus.INACTIVE, "GLM, Loan cannot adjusted");
        require(loanOffersNFT[_nftloanIdAdjusted].borrower == msg.sender, "GLM, Only Borrow Adjust Loan");

        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice.length ; index ++){
            collatetralInBorrowed +=  loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice[index];
        }

        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, msg.sender);
        require(loanOffersNFT[_nftloanIdAdjusted].loanAmountInBorrowed <= maxLtv, "GLM: LTV not allowed.");

        loanOffersNFT[_nftloanIdAdjusted] = NftLoanData.LoanDetailsNFT(
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTId,
            loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice,
            _newLoanAmountBorrowed,
            _newAPYOffer,
            loanOffersNFT[_nftloanIdAdjusted].loanType,
            NftLoanData.LoanStatus.INACTIVE,
            _newTermsLengthInDays,
            _isPrivate,
            _isInsured,
            msg.sender,
            loanOffersNFT[_nftloanIdAdjusted].borrowStableCoin
            
        );
        
        emit NFTLoanOfferAdjusted(_nftloanIdAdjusted);

    }

     /**
    @dev function for lender to activate loan offer by the borrower
    @param _nftloanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateNFTLoan(uint256 _nftloanId, uint256 _stableCoinAmount) public {

        address lenderAddress = msg.sender;

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[_nftloanId];

        require(loanDetailsNFT.loanType == NftLoanData.LoanType.SINGLE_NFT || loanDetailsNFT.loanType == NftLoanData.LoanType.MULTI_NFT,"GLM: Invalid Loan Type");
        require(loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.INACTIVE, "GLM, loan should be InActive");
        require(loanDetailsNFT.borrower != lenderAddress, "GLM, only Lenders can Active");
        require(loanDetailsNFT.loanAmountInBorrowed == _stableCoinAmount, "GLM, amount not equal to borrow amount");
        
        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
    
        uint256 apyFee = this.getAPYFeeNFT(loanDetailsNFT);
        uint256 loanAmountAfterAPYFee = loanDetailsNFT.loanAmountInBorrowed.sub(apyFee);

        stableCoinAPYFeeFromNFT[address(this)] += apyFee;

        //approving token from the front end
        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(lenderAddress, address(this), apyFee);
        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(lenderAddress, loanDetailsNFT.borrower, loanAmountAfterAPYFee);
        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoansNFTs[lenderAddress].push(_nftloanId);

        //activated loan id to the lender details
        activatedNFTLoanOffers[_nftloanId] =  NftLoanData.LenderDetailsNFT({
		lender: lenderAddress,
		activationLoanTimeStamp:  1625041113   // block.timestamp actual block.timestamp
        });

        emit NFTLoanOfferActivated(
            _nftloanId,
            lenderAddress,
            loanDetailsNFT.loanAmountInBorrowed,
            loanDetailsNFT.termsLengthInDays,
            loanDetailsNFT.apyOffer,
            loanDetailsNFT.stakedCollateralNFTsAddress,
            loanDetailsNFT.stakedCollateralNFTId,
            loanDetailsNFT.stakedNFTPrice,
            loanDetailsNFT.loanType,
            loanDetailsNFT.isPrivate,
            loanDetailsNFT.borrowStableCoin);

    }

     /**
    @dev payback loan full by the borrower to the lender

     */
    function nftLoanPaybackBeforeTermEnd(uint256 _nftLoanId) public {

        address borrower = msg.sender;

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[_nftLoanId];

        require(loanDetailsNFT.loanType == NftLoanData.LoanType.SINGLE_NFT || loanDetailsNFT.loanType == NftLoanData.LoanType.MULTI_NFT,"GLM: Invalid Loan Type");
        require(loanDetailsNFT.borrower == borrower, "GLM, only borrower can payback");
        require(loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.ACTIVE, "GLM, loan should be Active");

        // if(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType) {//for single NFT collateral length must be one.
        //     require(loanDetailsNFT.stakedCollateralNFTsAddress.length == 1,"GLM: Multi-NFTs not allowed");
        // }
       
        //loop through all staked collateral nft tokens.
        for(uint256 i  = 0 ; i  <  loanDetailsNFT.stakedCollateralNFTsAddress.length ; i++){
            //contract will the repay staked collateral tokens to the borrower
           IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).safeTransferFrom(address(this), msg.sender, loanDetailsNFT.stakedCollateralNFTId[i]);
        }   

        uint256 loanTermLengthPassed = block.timestamp - activatedNFTLoanOffers[_nftLoanId].activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400); //86400 == 1 day
        require(loanTermLengthPassedInDays <= loanDetailsNFT.termsLengthInDays, "GLM: Loan already paybacked or liquidated.");
        
        uint256 apyFeeOriginal = this.getAPYFeeNFT(loanDetailsNFT);
        uint256 apyFeeBeforeLoanTermLengthEnd = ((loanDetailsNFT.loanAmountInBorrowed.mul(loanDetailsNFT.apyOffer).div(100)).div(365)).mul(loanTermLengthPassedInDays);

        uint256 unEarnedAPYFee =  apyFeeOriginal - apyFeeBeforeLoanTermLengthEnd;
        uint256 unEarnedAPYPerForLender = govWorldProtocolRegistry.getUnearnedAPYPercentageForLender();
        
        uint256 finalPaybackAmounttoLender = loanDetailsNFT.loanAmountInBorrowed + apyFeeBeforeLoanTermLengthEnd  + (unEarnedAPYFee.mul(unEarnedAPYPerForLender).div(100));

        require(apyFeeBeforeLoanTermLengthEnd <= stableCoinAPYFeeFromNFT[address(this)], "GLM: Loan Market should have enough balance");
        stableCoinAPYFeeFromNFT[address(this)] -= apyFeeBeforeLoanTermLengthEnd;

        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(loanDetailsNFT.borrower, address(this), finalPaybackAmounttoLender);
        IERC20(loanDetailsNFT.borrowStableCoin).transfer(activatedNFTLoanOffers[_nftLoanId].lender, finalPaybackAmounttoLender);
        loanOffersNFT[_nftLoanId].loanStatus = NftLoanData.LoanStatus.CLOSED;

        emit NFTLoanPaybacked(_nftLoanId, borrower, NftLoanData.LoanStatus.CLOSED);

    }

     /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateBorrowerNFT(uint256 _loanId) public onlyLiquidatorRole(msg.sender) {
        
        NftLoanData.LoanDetailsNFT memory loanDetails = loanOffersNFT[_loanId];
        NftLoanData.LenderDetailsNFT memory lenderDetails = activatedNFTLoanOffers[_loanId];

        uint256 loanTermLengthPassed = block.timestamp - lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays > loanDetails.termsLengthInDays, "GTM: Collaterals not ready for liquidation");

        //send collateral nfts to the lender
        for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralNFTsAddress.length ; i++){
         //contract will the repay staked collateral tokens to the borrower
        IERC721(loanDetails.stakedCollateralNFTsAddress[i]).safeTransferFrom(address(this),lenderDetails.lender, loanDetails.stakedCollateralNFTId[i]);  
        loanOffersNFT[_loanId].loanStatus = NftLoanData.LoanStatus.LIQUIDATED;
        
        }

           
        emit AutoLiquidatedNFT(_loanId, NftLoanData.LoanStatus.LIQUIDATED);
    
    }

    /**
    @dev function to get max loan amount borrower can get as per his staked collateral nfts */
    function getMaxLtv(uint256 collateralInBorrowed,address borrower)
        external
        view
        returns(uint256)
        {
        TierData memory  tierData = govWorldTierLevel.getTierDatabyGovBalance(borrower);
        return (collateralInBorrowed.mul(tierData.loantoValue).div(100));
    }

    /**
    @dev function to get the next nft loan Id after creating the loan offer in NFT case
     */
    function _getNextLoanIdNFT() public view returns (uint256) {
        return loanIdNFT.add(1);
    }

    /**
    @dev returns the current loan id of the nft loans
     */
    function getCurrentLoanIdNFT() public view returns(uint256) {
        return loanIdNFT;
    }

   /**
    @dev will increment loan id after creating loan offer
     */
    function _incrementLoanIdNFT() private {
        loanIdNFT++;
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

interface  IERC20Extras{
    function decimals() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../library/NftLoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/INftMarket.sol";

abstract contract NftMarketBase is INftMarket {
    //Load library structs into contract
    using NftLoanData for *;
    using NftLoanData for bytes32;
    using SafeMath for uint256;

    //Single NFT or Multi NFT loan offers mapping
    //saves information of NFT in loanOffersNFT when createLoanOfferERC721 is called
    mapping(uint256 => NftLoanData.LoanDetailsNFT) public loanOffersNFT;

    //mapping saves the information of the lender across the active NFT Loan Ids
    mapping(uint256 => NftLoanData.LenderDetailsNFT) public activatedNFTLoanOffers;

    //array of all loan offer ids of the NFT tokens.
    uint256[] public loanOfferIdsNFTs;

    //mapping of borrower address to the loan Ids of the NFT.
    mapping(address => uint256[]) borrowerloanOffersNFTs;

    //mapping address of the lender to the activated loan offers of NFT
    mapping(address => uint256[]) lenderActivatedLoansNFTs;

    //mapping address stable to the APY Fee of stable
    mapping(address => uint256) public stableCoinAPYFeeFromNFT;

      /**
    @dev function that will get APY fee of the loan amount in borrower
     */
    function getAPYFeeNFT(NftLoanData.LoanDetailsNFT memory _loanDetailsNFT) external pure returns(uint256) {

        // APY Fee Formula
        uint256 apyFee = ((_loanDetailsNFT.loanAmountInBorrowed.mul(_loanDetailsNFT.apyOffer).div(100)).div(365)).mul(_loanDetailsNFT.termsLengthInDays);

        return apyFee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NftLoanData {
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
		SINGLE_NFT,
		MULTI_NFT
	}

	struct LenderDetailsNFT {
		address lender;
		uint256 activationLoanTimeStamp;
	}
	
	struct LoanDetailsNFT {

		//single nft or multi nft addresses
		address[] stakedCollateralNFTsAddress;
		//single nft id or multinft id
		uint256[] stakedCollateralNFTId;
		//single nft price or multi nft price //price fetch from the opensea or rarible
		uint256[] stakedNFTPrice;

		//total Loan Amount in USD
		uint256 loanAmountInBorrowed;
		//borrower given apy percentage
		uint32 apyOffer;

		//Single NFT and multiple staked NFT
		LoanType loanType;
		//current status of the loan
		LoanStatus loanStatus;
		//user choose terms length in days TODO define validations
		uint56 termsLengthInDays;
		//private loans will not appear on loan market
		bool isPrivate;
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
import "../library/NftLoanData.sol";

interface INftMarket {


    event LoanOfferCreatedNFT(NftLoanData.LoanDetailsNFT _loanDetailsNFT);

    event NFTLoanOfferActivated(
        uint256 nftLoanId,
        address _lender,
        uint256 _loanAmount,
        uint256 _termsLengthInDays,
        uint256 _APYOffer,
        address[] stakedCollateralNFTsAddress,
		uint256[] stakedCollateralNFTId,
		uint256[] stakedNFTPrice,
        NftLoanData.LoanType _loanType,
        bool _isPrivate,
        address _borrowStableCoin
    );

    event NFTLoanOfferAdjusted(uint256 nftloanId);

    event LoanOfferCancelNFT(
        uint256 nftloanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event NFTLoanPaybacked(
        uint256 nftLoanId,
        address _borrower,
        NftLoanData.LoanStatus loanStatus
    );

    event AutoLiquidatedNFT(uint256 nftLoanId, NftLoanData.LoanStatus loanStatus);

    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}