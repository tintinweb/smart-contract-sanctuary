// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/admininterfaces/IGovWorldAdminRegistry.sol";
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
    IGovWorldAdminRegistry govAdminRegistry;
    
    uint256 public loanIdNFT = 0;

    constructor(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel,
        address _govAdminRegistry
    ) {
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(_govWorldProtocolRegistry);
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
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
    @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    @param  loanDetailsNFT includes the following struct
    */
    function createLoan(NftLoanData.LoanDetailsNFT memory loanDetailsNFT)
        public
        {
        uint256 newLoanIdNFT = _getNextLoanIdNFT();

        require((loanDetailsNFT.stakedCollateralNFTsAddress.length == loanDetailsNFT.stakedCollateralNFTId.length) == (loanDetailsNFT.stakedCollateralNFTId.length == loanDetailsNFT.stakedNFTPrice.length),"GLM: Length not equal");
        require(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType || NftLoanData.LoanType.MULTI_NFT == loanDetailsNFT.loanType,"GLM: Invalid Loan Type");
        if(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType) { //for single tokens collateral length must be one.
            require(loanDetailsNFT.stakedCollateralNFTsAddress.length == 1,"GLM: MULTI-NFTs not allowed");
        }
        TierData memory  tierData = govWorldTierLevel.getTierDatabyGovBalanceorNFTAddress(loanDetailsNFT.stakedCollateralNFTsAddress, msg.sender);
        require(tierData.singleNFT || tierData.multiNFT, "GLM: Not Eligible");
        uint256 collatetralInBorrowed = 0;
        for(uint256 index =  0 ; index < loanDetailsNFT.stakedNFTPrice.length ; index ++){
            collatetralInBorrowed +=  loanDetailsNFT.stakedNFTPrice[index];
        }

        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, loanDetailsNFT.stakedCollateralNFTsAddress,   msg.sender);
        require(loanDetailsNFT.loanAmountInBorrowed <= maxLtv, "GLM: LTV not allowed.");
        
        //create uniquie loan hash
        borrowerloanOffersNFTs[msg.sender].push(newLoanIdNFT);
        loanOfferIdsNFTs.push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        for(uint256 i  = 0 ; i  <  loanDetailsNFT.stakedCollateralNFTsAddress.length ; i++){
            //borrower will approved the tokens staking as collateral
            require(IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).getApproved(loanDetailsNFT.stakedCollateralNFTId[i]) == address(this), "GLM: Approval Error");
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
        
        // delete loanOffersNFT[_nftloanId]; //not deleting from (just changing status to CANCELLED)
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

        uint256 maxLtv = this.getMaxLtv(collatetralInBorrowed, loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress,  msg.sender);
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

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[_nftloanId];

        require(loanDetailsNFT.loanType == NftLoanData.LoanType.SINGLE_NFT || loanDetailsNFT.loanType == NftLoanData.LoanType.MULTI_NFT,"GLM: Invalid Loan Type");
        require(loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.INACTIVE, "GLM, loan should be InActive");
        require(loanDetailsNFT.borrower != msg.sender, "GLM, only Lenders can Active");
        require(loanDetailsNFT.loanAmountInBorrowed == _stableCoinAmount, "GLM, amount not equal to borrow amount");
        
        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
        //checking again the collateral tokens approval from the borrower
        //contract will now hold the staked collateral tokens
        for(uint256 i  = 0 ; i  <  loanDetailsNFT.stakedCollateralNFTsAddress.length; i++){
            require(IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).getApproved(loanDetailsNFT.stakedCollateralNFTId[i]) == address(this), "GLM: Approval Error");
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).safeTransferFrom(loanDetailsNFT.borrower, address(this), loanDetailsNFT.stakedCollateralNFTId[i]);
        }

        uint256 apyFee = this.getAPYFeeNFT(loanDetailsNFT);
        uint platformFee = loanDetailsNFT.loanAmountInBorrowed.mul(govWorldProtocolRegistry.getGovPlatformFee()).div(100);
        uint loanAmountAfterCut = loanDetailsNFT.loanAmountInBorrowed.sub(apyFee+platformFee);
        stableCoinAPYFeeFromNFT[loanDetailsNFT.borrowStableCoin] =  stableCoinAPYFeeFromNFT[loanDetailsNFT.borrowStableCoin].add(apyFee+platformFee);

        require((apyFee + loanAmountAfterCut + platformFee)  == loanDetailsNFT.loanAmountInBorrowed, "GLM, invalid amount");

        //approving stable token from the front end
        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(msg.sender, address(this), loanDetailsNFT.loanAmountInBorrowed);
        //loan amount send to borrower
        IERC20(loanDetailsNFT.borrowStableCoin).transfer(loanDetailsNFT.borrower, loanAmountAfterCut);
        //TODO below lin admin fee transfer will be removed ask by client
        // IERC20(loanDetailsNFT.borrowStableCoin).transfer((govWorldProtocolRegistry.getAdminFeeWallet()), (platformFee.mul(govWorldProtocolRegistry.getAdminWalletPercentage()).div(100)));
        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoansNFTs[msg.sender].push(_nftloanId);

        //activated loan id to the lender details
        activatedNFTLoanOffers[_nftloanId] =  NftLoanData.LenderDetailsNFT({
		lender: msg.sender,
		activationLoanTimeStamp:  1625041113   // TODO block.timestamp actual block.timestamp
        });

        emit NFTLoanOfferActivated(
            _nftloanId,
            msg.sender,
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

        uint256 loanTermLengthPassed = block.timestamp.sub(activatedNFTLoanOffers[_nftLoanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400); //86400 == 1 day
        require(loanTermLengthPassedInDays <= loanDetailsNFT.termsLengthInDays, "GLM: Loan already paybacked or liquidated.");
        
        uint256 earnedAPY = ((loanDetailsNFT.loanAmountInBorrowed.mul(loanDetailsNFT.apyOffer).div(100)).div(365)).mul(loanTermLengthPassedInDays);
        
        uint256 finalAmounttoLender = loanDetailsNFT.loanAmountInBorrowed + earnedAPY;

        require(earnedAPY <= stableCoinAPYFeeFromNFT[address(this)], "GLM: Loan Market should have enough balance");
        stableCoinAPYFeeFromNFT[address(this)] = stableCoinAPYFeeFromNFT[address(this)].sub(earnedAPY);

        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(loanDetailsNFT.borrower, address(this), loanDetailsNFT.loanAmountInBorrowed);
        IERC20(loanDetailsNFT.borrowStableCoin).transfer(activatedNFTLoanOffers[_nftLoanId].lender, finalAmounttoLender);

        // if(NftLoanData.LoanType.SINGLE_NFT  == loanDetailsNFT.loanType) {//for single NFT collateral length must be one.
        //     require(loanDetailsNFT.stakedCollateralNFTsAddress.length == 1,"GLM: Multi-NFTs not allowed");
        // }
       
        //loop through all staked collateral nft tokens.
        for(uint256 i  = 0 ; i  <  loanDetailsNFT.stakedCollateralNFTsAddress.length ; i++){
            //contract will the repay staked collateral tokens to the borrower
           IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i]).safeTransferFrom(address(this), msg.sender, loanDetailsNFT.stakedCollateralNFTId[i]);
        }   

        loanOffersNFT[_nftLoanId].loanStatus = NftLoanData.LoanStatus.CLOSED;

        emit NFTLoanPaybacked(_nftLoanId, borrower, NftLoanData.LoanStatus.CLOSED);

    }

     /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateBorrowerNFT(uint256 _loanId) public onlyLiquidatorRole(msg.sender) {
        
        require(loanOffersNFT[_loanId].loanStatus == NftLoanData.LoanStatus.ACTIVE, "GLM, loan should be Active");
        NftLoanData.LoanDetailsNFT memory loanDetails = loanOffersNFT[_loanId];
        NftLoanData.LenderDetailsNFT memory lenderDetails = activatedNFTLoanOffers[_loanId];

        uint256 loanTermLengthPassed = block.timestamp.sub(lenderDetails.activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed.div(86400);
        require(loanTermLengthPassedInDays > loanDetails.termsLengthInDays, "GNM: Collaterals not ready for liquidation");

        //send collateral nfts to the lender
        for(uint256 i  = 0 ; i  <  loanDetails.stakedCollateralNFTsAddress.length ; i++){
         //contract will the repay staked collateral tokens to the borrower
        IERC721(loanDetails.stakedCollateralNFTsAddress[i]).safeTransferFrom(address(this),lenderDetails.lender, loanDetails.stakedCollateralNFTId[i]);  
        loanOffersNFT[_loanId].loanStatus = NftLoanData.LoanStatus.LIQUIDATED;
        
        } 
        emit AutoLiquidatedNFT(_loanId, NftLoanData.LoanStatus.LIQUIDATED);
    
    }

    //only super admin can withdraw coins
    function withdrawCoin( uint256 _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        require(_withdrawAmount <= address(this).balance, "GNM: Amount Invalid");
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }
    //only super admin can withdraw tokens
    function withdrawToken(address _tokenAddress, uint256 _withdrawAmount, address payable _walletAddress) public onlySuperAdmin(msg.sender) {
        require(_withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)), "GNM: Amount Invalid");
        IERC20(_tokenAddress).transfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    /**
    @dev function to get max loan amount borrower can get as per his staked collateral nfts */
    function getMaxLtv(uint256 collateralInBorrowed, address[] memory _nftContracts, address borrower)
        external
        view
        returns(uint256)
        {
        TierData memory  tierData = govWorldTierLevel.getTierDatabyGovBalanceorNFTAddress(_nftContracts, borrower);
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

    function getNetworkBalance(address _address) public view returns (uint) {
        return _address.balance;
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
        uint256[] memory activeOfferIds = new uint256[](loanOfferIdsNFTs.length);
        for (uint256 i = 0; i < loanOfferIdsNFTs.length; i++) {
            NftLoanData.LoanDetailsNFT memory details = loanOffersNFT[i];
            if (uint256(details.loanStatus) == _status) {
                activeOfferIds[i] = i;
            }
        }
        return activeOfferIds;
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

// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

import "../library/TokenLoanData.sol";

interface IGovLiquidator {

    event NewLiquidatorApproved(address indexed _newLiquidator, bool _liquidatorAccess);

    event AutoLiquidated(uint256 _loanId, TokenLoanData.LoanStatus loanStatus);

    event LiquidatedCollaterals(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );

    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

    function liquidateLoan(uint256 _loanId) external;
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

    event NewAdminApproved(address indexed _newAdmin, address indexed _addByAdmin, uint8 indexed _key);
    event NewAdminApprovedByAll(address indexed _newAdmin, AdminAccess _adminAccess);
    event AdminRemovedByAll(address indexed _admin, address indexed _removedByAdmin);
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
    address dexRouter;
    bool isSP;
    bool isReversedLoan;
    uint256 tokenLimitPerReverseLoan;
    address gToken;
    bool isMint;
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
        bool isSp,
        bool isReversedLoan,
        uint256 tokenLimitPerReverseLoan,
        address gToken
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

    function getTierNamebyWalletAddress(address userWalletAddress) external view returns (bytes32 tierLevel);

    function getTierDatabyGovBalanceorNFTAddress(address[] memory nftContract, address userWallet) external view returns (TierData memory _tierData);

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

import "../library/NftLoanData.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/INftMarket.sol";

abstract contract NftMarketBase is INftMarket {
    //Load library structs into contract
    using NftLoanData for *;
    using NftLoanData for bytes32;
    using SafeMath for uint256;

    //Single NFT or Multi NFT loan offers mapping
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

// SPDX-License-Identifier: agpl-3.0

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

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );
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