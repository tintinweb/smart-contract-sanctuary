// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/interfaces/IGovWorldAdminRegistry.sol";
import "../../admin/interfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/interfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/NftMarketBase.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NftMarket is
    NftMarketBase,
    ERC721Holder,
    PausableUpgradeable,
    OwnableUpgradeable
{
    //Load library structs into contract
    using NftLoanData for *;

    IGovLiquidator govWorldLiquidator;
    IGovWorldProtocolRegistry govWorldProtocolRegistry;
    IGovWorldTierLevel govWorldTierLevel;
    IGovWorldAdminRegistry govAdminRegistry;

    uint256 public loanIdNFT;

    uint256 private loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    function initialize(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel,
        address _govAdminRegistry
    ) external initializer {
        __Ownable_init();
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(
            _govWorldProtocolRegistry
        );
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
        govAdminRegistry = IGovWorldAdminRegistry(_govAdminRegistry);
        loanIdNFT = 0;
    }

    receive() external payable {}

    function setloanActivateLimit(uint256 _loansLimit) public {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                msg.sender
            ),
            "GTM: Not a Gov Super Admin."
        );
        require(_loansLimit > 0, "GTM: loanlimit error");
        loanActivateLimit = _loansLimit;
    }

    function setWhilelistAddress(address _lender) public {
        require(
            IGovWorldAdminRegistry(govAdminRegistry).isSuperAdminAccess(
                msg.sender
            ),
            "GTM: Not a Gov Super Admin."
        );
        require(_lender != address(0x0), "GTM: null address error");
        whitelistAddress[_lender] = true;
    }

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

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
    @dev function to create Single || Multi NFT Loan Offer by the BORROWER
    @param  loanDetailsNFT includes the following struct
    */
    function createLoan(NftLoanData.LoanDetailsNFT memory loanDetailsNFT)
        public
        whenNotPaused
    {
        uint256 newLoanIdNFT = _getNextLoanIdNFT();

        require(
            (loanDetailsNFT.stakedCollateralNFTsAddress.length ==
                loanDetailsNFT.stakedCollateralNFTId.length) ==
                (loanDetailsNFT.stakedCollateralNFTId.length ==
                    loanDetailsNFT.stakedNFTPrice.length),
            "GLM: Length not equal"
        );
        require(
            NftLoanData.LoanType.SINGLE_NFT == loanDetailsNFT.loanType ||
                NftLoanData.LoanType.MULTI_NFT == loanDetailsNFT.loanType,
            "GLM: Invalid Loan Type"
        );

        require(
            govWorldProtocolRegistry.isStableApproved(
                loanDetailsNFT.borrowStableCoin
            ),
            "GLM: not approved stable coin"
        );

        if (NftLoanData.LoanType.SINGLE_NFT == loanDetailsNFT.loanType) {
            //for single tokens collateral length must be one.
            require(
                loanDetailsNFT.stakedCollateralNFTsAddress.length == 1,
                "GLM: MULTI-NFTs not allowed"
            );
        }

        uint256 collatetralInBorrowed = 0;
        for (
            uint256 index = 0;
            index < loanDetailsNFT.stakedNFTPrice.length;
            index++
        ) {
            collatetralInBorrowed += loanDetailsNFT.stakedNFTPrice[index];
        }
        uint256 response = govWorldTierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            loanDetailsNFT.loanAmountInBorrowed,
            collatetralInBorrowed,
            loanDetailsNFT.stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
        //create uniquie loan hash
        borrowerloanOffersNFTs[msg.sender].push(newLoanIdNFT);
        loanOfferIdsNFTs.push(newLoanIdNFT);
        //loop through all staked collateral NFTs.
        for (
            uint256 i = 0;
            i < loanDetailsNFT.stakedCollateralNFTsAddress.length;
            i++
        ) {
            //borrower will approved the tokens staking as collateral
            require(
                IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                    .getApproved(loanDetailsNFT.stakedCollateralNFTId[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
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
    function nftloanOfferCancel(uint256 _nftloanId) public whenNotPaused {
        require(
            loanOffersNFT[_nftloanId].loanType ==
                NftLoanData.LoanType.SINGLE_NFT ||
                loanOffersNFT[_nftloanId].loanType ==
                NftLoanData.LoanType.MULTI_NFT,
            "GLM: Invalid Loan Type"
        );
        require(
            loanOffersNFT[_nftloanId].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, cannot be cancel"
        );
        require(
            loanOffersNFT[_nftloanId].borrower == msg.sender,
            "GLM, Only Borrow can cancel Loan"
        );

        // delete loanOffersNFT[_nftloanId]; //not deleting from (just changing status to CANCELLED)
        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.CANCELLED;

        emit LoanOfferCancelNFT(
            _nftloanId,
            msg.sender,
            loanOffersNFT[_nftloanId].loanStatus
        );
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
    ) public whenNotPaused {
        require(
            loanOffersNFT[_nftloanIdAdjusted].loanType ==
                NftLoanData.LoanType.SINGLE_NFT ||
                loanOffersNFT[_nftloanIdAdjusted].loanType ==
                NftLoanData.LoanType.MULTI_NFT,
            "GLM: Invalid Loan Type"
        );
        require(
            loanOffersNFT[_nftloanIdAdjusted].loanStatus ==
                NftLoanData.LoanStatus.INACTIVE,
            "GLM, Loan cannot adjusted"
        );
        require(
            loanOffersNFT[_nftloanIdAdjusted].borrower == msg.sender,
            "GLM, Only Borrow Adjust Loan"
        );

        uint256 collatetralInBorrowed = 0;
        for (
            uint256 index = 0;
            index < loanOffersNFT[_nftloanIdAdjusted].stakedNFTPrice.length;
            index++
        ) {
            collatetralInBorrowed += loanOffersNFT[_nftloanIdAdjusted]
                .stakedNFTPrice[index];
        }

        uint256 response = govWorldTierLevel.isCreateLoanNftUnderTier(
            msg.sender,
            _newLoanAmountBorrowed,
            collatetralInBorrowed,
            loanOffersNFT[_nftloanIdAdjusted].stakedCollateralNFTsAddress
        );
        require(response == 200, "NMT: Invalid tier loan");
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

        emit NFTLoanOfferAdjusted(loanOffersNFT[_nftloanIdAdjusted]);
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _nftloanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateNFTLoan(uint256 _nftloanId, uint256 _stableCoinAmount)
        public
        whenNotPaused
    {
        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftloanId
        ];

        require(
            loanDetailsNFT.loanType == NftLoanData.LoanType.SINGLE_NFT ||
                loanDetailsNFT.loanType == NftLoanData.LoanType.MULTI_NFT,
            "GLM: Invalid Loan Type"
        );
        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.INACTIVE,
            "GLM, loan should be InActive"
        );
        require(
            loanDetailsNFT.borrower != msg.sender,
            "GLM, only Lenders can Active"
        );
        require(
            loanDetailsNFT.loanAmountInBorrowed == _stableCoinAmount,
            "GLM, amount not equal to borrow amount"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed
        //checking again the collateral tokens approval from the borrower
        //contract will now hold the staked collateral tokens
        for (
            uint256 i = 0;
            i < loanDetailsNFT.stakedCollateralNFTsAddress.length;
            i++
        ) {
            require(
                IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                    .getApproved(loanDetailsNFT.stakedCollateralNFTId[i]) ==
                    address(this),
                "GLM: Approval Error"
            );
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    loanDetailsNFT.borrower,
                    address(this),
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }

        uint256 apyFee = this.getAPYFeeNFT(loanDetailsNFT);
        uint256 platformFee = (loanDetailsNFT.loanAmountInBorrowed *
            (govWorldProtocolRegistry.getGovPlatformFee())) / 10000;
        uint256 loanAmountAfterCut = loanDetailsNFT.loanAmountInBorrowed -
            apyFee +
            platformFee;
        stableCoinAPYFeeFromNFT[loanDetailsNFT.borrowStableCoin] =
            stableCoinAPYFeeFromNFT[loanDetailsNFT.borrowStableCoin] +
            apyFee +
            platformFee;

        require(
            (apyFee + loanAmountAfterCut + platformFee) ==
                loanDetailsNFT.loanAmountInBorrowed,
            "GLM, invalid amount"
        );

        //approving stable token from the front end
        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(
            msg.sender,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );
        //loan amount send to borrower
        IERC20(loanDetailsNFT.borrowStableCoin).transfer(
            loanDetailsNFT.borrower,
            loanAmountAfterCut
        );
        loanOffersNFT[_nftloanId].loanStatus = NftLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoansNFTs[msg.sender].push(_nftloanId);

        //activated loan id to the lender details
        activatedNFTLoanOffers[_nftloanId] = NftLoanData.LenderDetailsNFT({
            lender: msg.sender,
            activationLoanTimeStamp: block.timestamp
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
            loanDetailsNFT.borrowStableCoin
        );
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function nftLoanPaybackBeforeTermEnd(uint256 _nftLoanId)
        public
        whenNotPaused
    {
        address borrower = msg.sender;

        NftLoanData.LoanDetailsNFT memory loanDetailsNFT = loanOffersNFT[
            _nftLoanId
        ];

        require(
            loanDetailsNFT.loanType == NftLoanData.LoanType.SINGLE_NFT ||
                loanDetailsNFT.loanType == NftLoanData.LoanType.MULTI_NFT,
            "GLM: Invalid Loan Type"
        );
        require(
            loanDetailsNFT.borrower == borrower,
            "GLM, only borrower can payback"
        );
        require(
            loanDetailsNFT.loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );

        uint256 loanTermLengthPassed = block.timestamp -
            activatedNFTLoanOffers[_nftLoanId].activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400; //86400 == 1 day
        // require(loanTermLengthPassedInDays <= loanDetailsNFT.termsLengthInDays + 1, "GLM: Loan already paybacked or liquidated.");

        uint256 earnedAPY = ((loanDetailsNFT.loanAmountInBorrowed *
            loanDetailsNFT.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;

        uint256 finalAmounttoLender = loanDetailsNFT.loanAmountInBorrowed +
            earnedAPY;

        require(
            earnedAPY <= stableCoinAPYFeeFromNFT[address(this)],
            "GLM: Loan Market should have enough balance"
        );
        stableCoinAPYFeeFromNFT[address(this)] =
            stableCoinAPYFeeFromNFT[address(this)] -
            earnedAPY;

        IERC20(loanDetailsNFT.borrowStableCoin).transferFrom(
            loanDetailsNFT.borrower,
            address(this),
            loanDetailsNFT.loanAmountInBorrowed
        );
        IERC20(loanDetailsNFT.borrowStableCoin).transfer(
            activatedNFTLoanOffers[_nftLoanId].lender,
            finalAmounttoLender
        );

        //loop through all staked collateral nft tokens.
        for (
            uint256 i = 0;
            i < loanDetailsNFT.stakedCollateralNFTsAddress.length;
            i++
        ) {
            //contract will the repay staked collateral tokens to the borrower
            IERC721(loanDetailsNFT.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    msg.sender,
                    loanDetailsNFT.stakedCollateralNFTId[i]
                );
        }

        loanOffersNFT[_nftLoanId].loanStatus = NftLoanData.LoanStatus.CLOSED;

        emit NFTLoanPaybacked(
            _nftLoanId,
            borrower,
            NftLoanData.LoanStatus.CLOSED
        );
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateBorrowerNFT(uint256 _loanId)
        public
        onlyLiquidatorRole(msg.sender)
    {
        require(
            loanOffersNFT[_loanId].loanStatus == NftLoanData.LoanStatus.ACTIVE,
            "GLM, loan should be Active"
        );
        NftLoanData.LoanDetailsNFT memory loanDetails = loanOffersNFT[_loanId];
        NftLoanData.LenderDetailsNFT
            memory lenderDetails = activatedNFTLoanOffers[_loanId];

        uint256 loanTermLengthPassed = block.timestamp -
            lenderDetails.activationLoanTimeStamp;
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;
        require(
            loanTermLengthPassedInDays > loanDetails.termsLengthInDays,
            "GNM: Collaterals not ready for liquidation"
        );

        //send collateral nfts to the lender
        for (
            uint256 i = 0;
            i < loanDetails.stakedCollateralNFTsAddress.length;
            i++
        ) {
            //contract will the repay staked collateral tokens to the borrower
            IERC721(loanDetails.stakedCollateralNFTsAddress[i])
                .safeTransferFrom(
                    address(this),
                    lenderDetails.lender,
                    loanDetails.stakedCollateralNFTId[i]
                );
            loanOffersNFT[_loanId].loanStatus = NftLoanData
                .LoanStatus
                .LIQUIDATED;
        }
        emit AutoLiquidatedNFT(_loanId, NftLoanData.LoanStatus.LIQUIDATED);
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GNM: Amount Invalid"
        );
        payable(_walletAddress).transfer(_withdrawAmount);
        emit WithdrawNetworkCoin(_walletAddress, _withdrawAmount);
    }

    //only super admin can withdraw tokens
    function withdrawToken(
        address _tokenAddress,
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= IERC20(_tokenAddress).balanceOf(address(this)),
            "GNM: Amount Invalid"
        );
        IERC20(_tokenAddress).transfer(_walletAddress, _withdrawAmount);
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    /**
    @dev function to get the next nft loan Id after creating the loan offer in NFT case
     */
    function _getNextLoanIdNFT() public view returns (uint256) {
        return loanIdNFT + 1;
    }

    /**
    @dev returns the current loan id of the nft loans
     */
    function getCurrentLoanIdNFT() public view returns (uint256) {
        return loanIdNFT;
    }

    /**
    @dev will increment loan id after creating loan offer
     */
    function _incrementLoanIdNFT() private {
        loanIdNFT++;
    }

    function getNetworkBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.3;

import "../library/TokenLoanData.sol";

interface IGovLiquidator {
    //using this function externally in the Token and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

    function liquidateLoan(uint256 _loanId) external;

    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function payback(uint256 _loanId, uint256 _paybackAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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

    function isAddGovAdminRole(address admin) external view returns (bool);

    //using this function externally in Gov Tier Level Smart Contract
    function isEditAdminAccessGranted(address admin)
        external
        view
        returns (bool);

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
    function isSuperAdminAccess(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

enum TokenType {
    ISDEX,
    ISELITE,
    ISVIP
}

// Token Market Data
struct Market {
    address dexRouter;
    address gToken;
    bool isMint;
    TokenType tokenType;
    bool isTokenEnabledAsCollateral;
}

interface IGovWorldProtocolRegistry {
    /** 
    @dev check function if Token Contract address is already added 
    @param _tokenAddress token address */
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /**
    @dev check fundtion token enable for staking as collateral
    */

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getUnearnedAPYPercentageForLender()
        external
        view
        returns (uint256);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getAdminWalletPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSynthetticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getAdminFeeWallet() external view returns (address);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

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
}
struct SingleSPTierData {
    uint256 ltv;
    bool singleToken;
    bool multiToken;
    bool singleNft;
    bool multiNFT;
}

struct NFTTierData {
    address nftContract;
    bool isTraditional;
    address spToken;
    bytes32 traditionalTier;
    uint256 nftTier;
    address[] allowedNfts;
    address[] allowedSuns;
}

interface IGovWorldTierLevel {
    function getTierDatabyGovBalance(address userWalletAddress)
        external
        view
        returns (TierData memory _tierData);

    function getMaxLoanAmountToValue(
        uint256 _collateralTokeninStable,
        address _borrower
    ) external view returns (uint256);

    function isCreateLoanTokenUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);

    function isCreateLoanNftUnderTier(
        address _wallet,
        uint256 _loanAmount,
        uint256 collateralInBorrowed,
        address[] memory stakedCollateralTokens
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20Extras {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma abicoder v2;

import "../library/NftLoanData.sol";
import "../interfaces/INftMarket.sol";

abstract contract NftMarketBase is INftMarket {
    //Load library structs into contract
    using NftLoanData for *;
    using NftLoanData for bytes32;

    //Single NFT or Multi NFT loan offers mapping
    mapping(uint256 => NftLoanData.LoanDetailsNFT) public loanOffersNFT;

    //mapping saves the information of the lender across the active NFT Loan Ids
    mapping(uint256 => NftLoanData.LenderDetailsNFT)
        public activatedNFTLoanOffers;

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
    function getAPYFeeNFT(NftLoanData.LoanDetailsNFT memory _loanDetailsNFT)
        external
        pure
        returns (uint256)
    {
        // APY Fee Formula
        uint256 apyFee = ((_loanDetailsNFT.loanAmountInBorrowed *
            _loanDetailsNFT.apyOffer) /
            10000 /
            365) * _loanDetailsNFT.termsLengthInDays;
        return apyFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

pragma solidity ^0.8.3;

library TokenLoanData {
    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
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
        //user choose terms length in days
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library NftLoanData {
    enum LoanStatus {
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
        //user choose terms length in days
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

pragma solidity ^0.8.3;
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

    event NFTLoanOfferAdjusted(NftLoanData.LoanDetailsNFT _loanDetailsNFT);

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

    event AutoLiquidatedNFT(
        uint256 nftLoanId,
        NftLoanData.LoanStatus loanStatus
    );

    event WithdrawNetworkCoin(address walletAddress, uint256 withdrawAmount);

    event WithdrawToken(
        address tokenAddress,
        address walletAddress,
        uint256 withdrawAmount
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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