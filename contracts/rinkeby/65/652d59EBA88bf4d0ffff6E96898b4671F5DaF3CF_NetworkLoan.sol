// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../../market/liquidator/IGovLiquidator.sol";
import "../../admin/interfaces/IGovWorldAdminRegistry.sol";
import "../../admin/interfaces/IGovWorldProtocolRegistry.sol";
import "../../admin/interfaces/IGovWorldTierLevel.sol";
import "../../interfaces/IDexFactory.sol";
import "../../interfaces/IDexPair.sol";
import "../../interfaces/IERC20Extras.sol";
import "../base/NetworkLoanBase.sol";
import "../library/NetworkLoanData.sol";
import "../../oracle/IGovPriceConsumer.sol";
import "../../interfaces/IUniswapSwapInterface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NetworkLoan is
    NetworkLoanBase,
    PausableUpgradeable,
    OwnableUpgradeable
{
    //Load library structs into contract
    using NetworkLoanData for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IGovLiquidator govWorldLiquidator;
    IGovWorldProtocolRegistry govWorldProtocolRegistry;
    IGovWorldTierLevel govWorldTierLevel;
    IGovPriceConsumer govPriceConsumer;
    IGovWorldAdminRegistry govAdminRegistry;

    uint256 public loanId;

    uint256 private loanActivateLimit;
    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public loanLendLimit;

    uint256 ltvPercentage;

    function initialize(
        address _govWorldLiquidator,
        address _govWorldProtocolRegistry,
        address _govWorldTierLevel,
        address _govPriceConsumer,
        address _govAdminRegistry
    ) external initializer {
        __Ownable_init();
        govWorldLiquidator = IGovLiquidator(_govWorldLiquidator);
        govWorldProtocolRegistry = IGovWorldProtocolRegistry(
            _govWorldProtocolRegistry
        );
        govWorldTierLevel = IGovWorldTierLevel(_govWorldTierLevel);
        govPriceConsumer = IGovPriceConsumer(_govPriceConsumer);
        govAdminRegistry = IGovWorldAdminRegistry(_govAdminRegistry);
        loanId = 0;
        ltvPercentage = 125;
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
    @dev function to create Single || Multi (ERC20) Loan Offer by the BORROWER

    */
    function createLoan(NetworkLoanData.LoanDetails memory loanDetails)
        public
        payable
        whenNotPaused
    {
        uint256 newLoanId = _getNextLoanId();

        require(
            loanDetails.paybackAmount == 0,
            "GNM: payback amount should be zero"
        );
        require(msg.value > 0 ether, "GNM: Loan Amount Invalid");
        require(
            govWorldProtocolRegistry.isStableApproved(
                loanDetails.borrowStableCoin
            ),
            "GTM: not approved stable coin"
        );

        loanDetails.collateralAmount = msg.value;

        uint256 collatetralInBorrowed = this.getAltCoinPriceinStable(
            loanDetails.borrowStableCoin,
            loanDetails.collateralAmount
        );

        uint256 ltv = this.calculateLTV(
            loanDetails.collateralAmount,
            loanDetails.borrowStableCoin,
            loanDetails.loanAmountInBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            collatetralInBorrowed,
            msg.sender
        );

        require(
            loanDetails.loanAmountInBorrowed <= maxLtv,
            "GNM: LTV not allowed."
        );
        require(
            ltv > ltvPercentage,
            "GNM: Can not create loan at liquidation level."
        );

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
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanIdAdjusted].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot adjusted"
        );
        require(
            borrowerOffers[_loanIdAdjusted].borrower == msg.sender,
            "GNM, Only Borrow Adjust Loan"
        );

        uint256 collatetralInBorrowed = this.getAltCoinPriceinStable(
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            _newLoanAmountBorrowed
        );
        uint256 ltv = this.calculateLTV(
            borrowerOffers[_loanIdAdjusted].collateralAmount,
            borrowerOffers[_loanIdAdjusted].borrowStableCoin,
            _newLoanAmountBorrowed
        );
        uint256 maxLtv = this.getMaxLoanAmount(
            collatetralInBorrowed,
            msg.sender
        );

        require(_newLoanAmountBorrowed <= maxLtv, "GNM: LTV not allowed.");
        require(
            ltv > ltvPercentage,
            "GNM: can not adjust loan to liquidation level."
        );

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
    function loanOfferCancel(uint256 _loanId) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, Loan cannot be cancel"
        );
        require(
            borrowerOffers[_loanId].borrower == msg.sender,
            "GNM, Only Borrow can cancel"
        );

        payable(msg.sender).transfer(borrowerOffers[_loanId].collateralAmount);
        // delete borrowerOffers[_loanId];
        borrowerOffers[_loanId].loanStatus = NetworkLoanData
            .LoanStatus
            .CANCELLED;
        emit LoanOfferCancel(
            _loanId,
            msg.sender,
            borrowerOffers[_loanId].loanStatus
        );
    }

    /**
    @dev function for lender to activate loan offer by the borrower
    @param _loanId loan id which is going to be activated
    @param _stableCoinAmount amount of stable coin requested by the borrower
     */
    function activateLoan(
        uint256 _loanId,
        uint256 _stableCoinAmount,
        bool _autoSell
    ) public whenNotPaused {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE,
            "GNM, not inactive"
        );
        require(
            borrowerOffers[_loanId].borrower != msg.sender,
            "GNM, self activation forbidden"
        );
        require(
            borrowerOffers[_loanId].loanAmountInBorrowed == _stableCoinAmount,
            "GNM, insufficient amount"
        );

        if (!whitelistAddress[msg.sender]) {
            require(
                loanLendLimit[msg.sender] + 1 <= loanActivateLimit,
                "GTM: you cannot lend more loans"
            );
            loanLendLimit[msg.sender]++;
        }

        //approve function to check if it is done through smart contract or from front end, in case of increasing loanAmountInBorrowed

        uint256 apyFee = this.getAPYFee(borrowerOffers[_loanId]);
        uint256 platformFee = (borrowerOffers[loanId].loanAmountInBorrowed *
            (govWorldProtocolRegistry.getGovPlatformFee())) / (10000);
        uint256 loanAmountAfterCut = borrowerOffers[loanId]
            .loanAmountInBorrowed - (apyFee + platformFee);

        stableCoinAPYFee[address(this)] =
            stableCoinAPYFee[address(this)] +
            (apyFee + platformFee);

        require(
            (apyFee + loanAmountAfterCut + platformFee) ==
                borrowerOffers[loanId].loanAmountInBorrowed,
            "GLM, invalid amount"
        );

        //approving  from the front end
        //keep the APYFEE  to govworld  before  transfering the stable coins to borrower.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                msg.sender,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed
            );
        //loan amount send to borrower
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(borrowerOffers[_loanId].borrower, loanAmountAfterCut);
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.ACTIVE;

        //push active loan ids to the lendersactivatedloanIds mapping
        lenderActivatedLoanIds[msg.sender].push(_loanId);

        //activated loan id to the lender details
        activatedLoanByLenders[_loanId] = NetworkLoanData.LenderDetails({
            lender: payable(msg.sender),
            activationLoanTimeStamp: block.timestamp,
            autoSell: _autoSell
        });

        emit LoanOfferActivated(
            _loanId,
            msg.sender,
            _stableCoinAmount,
            _autoSell
        );
    }

    function getTotalPaybackAmount(uint256 _loanId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassed = block.timestamp -
            (activatedLoanByLenders[_loanId].activationLoanTimeStamp);
        uint256 loanTermLengthPassedInDays = loanTermLengthPassed / 86400;
        require(
            loanTermLengthPassedInDays <= loanDetails.termsLengthInDays,
            "GNM: Loan already paybacked or liquidated."
        );

        uint256 apyFeeOriginal = this.getAPYFee(loanDetails);
        uint256 earnedAPYFee = ((loanDetails.loanAmountInBorrowed *
            loanDetails.apyOffer) /
            10000 /
            365) * loanTermLengthPassedInDays;
        uint256 unEarnedAPYFee = apyFeeOriginal - earnedAPYFee;

        return (
            loanDetails.loanAmountInBorrowed + earnedAPYFee,
            earnedAPYFee,
            unEarnedAPYFee
        );
    }

    /**
    @dev payback loan full by the borrower to the lender

     */
    function fullLoanPaybackEarly(uint256 _loanId) internal {
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (uint256 finalPaybackAmounttoLender, uint256 earnedAPYFee, ) = this
            .getTotalPaybackAmount(_loanId);

        stableCoinAPYFee[address(this)] =
            stableCoinAPYFee[address(this)] -
            earnedAPYFee;

        //we will first transfer the loan payback amount from borrower to the contract address.
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransferFrom(
                borrowerOffers[_loanId].borrower,
                address(this),
                borrowerOffers[_loanId].loanAmountInBorrowed -
                    borrowerOffers[_loanId].paybackAmount
            );
        IERC20Upgradeable(borrowerOffers[_loanId].borrowStableCoin)
            .safeTransfer(lenderDetails.lender, finalPaybackAmounttoLender);

        //contract will the repay staked collateral  to the borrower after receiving the loan payback amount
        payable(msg.sender).transfer(borrowerOffers[_loanId].collateralAmount);

        borrowerOffers[_loanId].paybackAmount = finalPaybackAmounttoLender;
        borrowerOffers[_loanId].loanStatus = NetworkLoanData.LoanStatus.CLOSED;
        emit FullLoanPaybacked(
            _loanId,
            msg.sender,
            NetworkLoanData.LoanStatus.CLOSED
        );
    }

    /**
    @dev  loan payback partial
    if _paybackAmount is equal to the total loan amount in stable coins the loan concludes as full payback
     */
    function payback(uint256 _loanId, uint256 _paybackAmount)
        public
        whenNotPaused
    {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        require(
            borrowerOffers[_loanId].borrower == payable(msg.sender),
            "GNM, not borrower"
        );
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active"
        );
        require(
            _paybackAmount > 0 &&
                _paybackAmount <= borrowerOffers[_loanId].loanAmountInBorrowed,
            "GNM: Invalid Loan Amount"
        );
        uint256 totalPayback = _paybackAmount + loanDetails.paybackAmount;
        if (totalPayback >= loanDetails.loanAmountInBorrowed) {
            fullLoanPaybackEarly(_loanId);
        } else {
            uint256 remainingLoanAmount = loanDetails.loanAmountInBorrowed -
                totalPayback;
            uint256 newLtv = this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                remainingLoanAmount
            );
            require(newLtv > ltvPercentage, "GNM: new LTV exceeds threshold.");
            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransferFrom(
                payable(msg.sender),
                address(this),
                _paybackAmount
            );
            borrowerOffers[_loanId].paybackAmount =
                borrowerOffers[_loanId].paybackAmount +
                _paybackAmount;
            loanDetails.loanStatus = NetworkLoanData.LoanStatus.ACTIVE;
            emit PartialLoanPaybacked(
                loanId,
                _paybackAmount,
                payable(msg.sender)
            );
        }
    }

    /**
    @dev liquidate call from the gov world liquidator
    @param _loanId loan id to check if its liqudation pending or loan term ended
     */
    function liquidateLoan(uint256 _loanId)
        public
        payable
        onlyLiquidatorRole(msg.sender)
    {
        require(
            borrowerOffers[_loanId].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE,
            "GNM, not active"
        );
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];

        (, uint256 earnedAPYFee, ) = this.getTotalPaybackAmount(_loanId);

        require(this.isLiquidationPending(_loanId), "GNM: Liquidation Error");

        if (lenderDetails.autoSell == true) {
            // loanDetails.collateralAmount == msg.value;
            address[] memory path = new address[](2);
            path[0] = govPriceConsumer.WETHAddress();
            path[1] = loanDetails.borrowStableCoin;

            (uint256 amountIn, uint256 amountOut) = govPriceConsumer
                .getNetworkCoinSwapData(
                    govPriceConsumer.WETHAddress(),
                    loanDetails.collateralAmount,
                    loanDetails.borrowStableCoin
                );

            IUniswapSwapInterface swapInterface = IUniswapSwapInterface(
                govPriceConsumer.getSwapInterfaceForETH()
            );
            swapInterface.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountIn
            }(amountOut, path, address(this), block.timestamp + 5 minutes);

            uint256 autosellFeeinStable = this.getautosellAPYFee(
                loanDetails.loanAmountInBorrowed,
                govWorldProtocolRegistry.getAutosellPercentage(),
                loanDetails.termsLengthInDays
            );
            uint256 finalAmountToLender = (loanDetails.loanAmountInBorrowed +
                earnedAPYFee) - (autosellFeeinStable);

            IERC20Upgradeable(loanDetails.borrowStableCoin).safeTransfer(
                lenderDetails.lender,
                finalAmountToLender
            );

            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;
            emit AutoLiquidated(_loanId, NetworkLoanData.LoanStatus.LIQUIDATED);
        } else {
            //send collateral  to the lender

            uint256 thresholdFeeinStable = (loanDetails.loanAmountInBorrowed *
                govWorldProtocolRegistry.getThresholdPercentage()) / 10000;
            uint256 lenderAmountinStable = earnedAPYFee + thresholdFeeinStable;

            //network loan market will the repay staked collateral  to the borrower
            uint256 collateralAmountinStable = this.getAltCoinPriceinStable(
                loanDetails.borrowStableCoin,
                loanDetails.collateralAmount
            );

            if (collateralAmountinStable <= loanDetails.loanAmountInBorrowed) {
                payable(msg.sender).transfer(collateralAmountinStable);
            } else if (
                collateralAmountinStable > loanDetails.loanAmountInBorrowed
            ) {
                uint256 exceedAltcoinValue = this.getStablePriceinAltcoin(
                    loanDetails.borrowStableCoin,
                    collateralAmountinStable - loanDetails.loanAmountInBorrowed
                );
                uint256 collateralToLender = loanDetails.collateralAmount -
                    exceedAltcoinValue;
                payable(msg.sender).transfer(collateralToLender);
            }

            IERC20Upgradeable(loanDetails.borrowStableCoin).transfer(
                lenderDetails.lender,
                lenderAmountinStable
            );
            borrowerOffers[_loanId].loanStatus = NetworkLoanData
                .LoanStatus
                .LIQUIDATED;
            emit LiquidatedCollaterals(
                _loanId,
                NetworkLoanData.LoanStatus.LIQUIDATED
            );
        }
    }

    function getMaxLoanAmount(uint256 collateralInBorrowed, address borrower)
        external
        view
        returns (uint256)
    {
        TierData memory tierData = govWorldTierLevel.getTierDatabyGovBalance(
            borrower
        );
        return (collateralInBorrowed * tierData.loantoValue) / 100;
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
    @dev function to get altcoin amount in stable coin.
    @param _stableCoin of the altcoin
    @param _collateralAmount amount of altcoin
     */
    function getAltCoinPriceinStable(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view override returns (uint256) {
        uint256 collateralAmountinStable;
        if (
            govPriceConsumer.isChainlinFeedEnabled(
                govPriceConsumer.WETHAddress()
            ) && govPriceConsumer.isChainlinFeedEnabled(_stableCoin)
        ) {
            int256 collateralChainlinkUsd = govPriceConsumer
                .getNetworkPriceFromChainlinkinUSD();
            uint256 collateralUsd = (uint256(collateralChainlinkUsd) *
                _collateralAmount) / 8;
            (
                int256 priceFromChainLinkinStable,
                uint8 stableDecimals
            ) = govPriceConsumer.getLatestUsdPriceFromChainlink(_stableCoin);
            collateralAmountinStable =
                collateralAmountinStable +
                ((collateralUsd / (uint256(priceFromChainLinkinStable))) *
                    (stableDecimals));
            return collateralAmountinStable;
        } else {
            collateralAmountinStable =
                collateralAmountinStable +
                (
                    govPriceConsumer.getDexTokenPrice(
                        _stableCoin,
                        govPriceConsumer.WETHAddress(),
                        _collateralAmount
                    )
                );
            return collateralAmountinStable;
        }
    }

    //function to get stablecoin price in altcoin
    function getStablePriceinAltcoin(
        address _stableCoin,
        uint256 _collateralAmount
    ) external view returns (uint256) {
        return
            govPriceConsumer.getDexTokenPrice(
                govPriceConsumer.WETHAddress(),
                _stableCoin,
                _collateralAmount
            );
    }

    /**
    @dev functino to get the LTV of the loan amount in borrowed of the staked colletral 
    @param _loanId loan ID for which ltv is getting
     */
    function getLtv(uint256 _loanId) external view override returns (uint256) {
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];
        return
            this.calculateLTV(
                loanDetails.collateralAmount,
                loanDetails.borrowStableCoin,
                loanDetails.loanAmountInBorrowed - (loanDetails.paybackAmount)
            );
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
    ) external view returns (uint256) {
        //IERC20Extras stableDecimnals = IERC20Extras(stkaedCollateral);
        uint256 totalCollateralInBorrowed;

        uint256 priceofCollateral = this.getAltCoinPriceinStable(
            _borrowed,
            _stakedCollateralAmount
        );
        totalCollateralInBorrowed =
            totalCollateralInBorrowed +
            (priceofCollateral);

        return (totalCollateralInBorrowed * 100) / _loanAmount;
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
        NetworkLoanData.LenderDetails
            memory lenderDetails = activatedLoanByLenders[_loanId];
        NetworkLoanData.LoanDetails memory loanDetails = borrowerOffers[
            _loanId
        ];

        uint256 loanTermLengthPassedInDays = (block.timestamp -
            lenderDetails.activationLoanTimeStamp) / 86400;

        // @dev get LTV
        uint256 calulatedLTV = this.getLtv(_loanId);
        //@dev the collateral is less than liquidation threshold percentage/loan term length end ok for liquidation
        // @dev loanDetails.termsLengthInDays + 1 is which we are giving extra time to the borrower to payback the collateral
        if (
            calulatedLTV <= this.getLTVPercentage() ||
            (loanTermLengthPassedInDays > loanDetails.termsLengthInDays + 1)
        ) return true;
        else return false;
    }

    function getLoansLength() public view returns (uint256) {
        return loanOfferIds.length;
    }

    //loans available to be shown on narket place
    function getInActiveLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (
                borrowerOffers[i].loanStatus ==
                NetworkLoanData.LoanStatus.INACTIVE
            ) {
                count++;
            }
        }
        return count;
    }

    /**
    @dev function to get the next loan id after creating the loan offer in  case
     */
    function _getNextLoanId() private view returns (uint256) {
        return loanId + 1;
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
    function getborrowerOffers(uint256 _loanId)
        public
        view
        returns (NetworkLoanData.LoanDetails memory)
    {
        return borrowerOffers[_loanId];
    }

    /**
    @dev get activated loan details of the lender, termslength and autosell boolean (true or false)
     */
    function getActivatedLoanDetails(uint256 _loanId)
        public
        view
        returns (NetworkLoanData.LenderDetails memory)
    {
        return activatedLoanByLenders[_loanId];
    }

    /**
    @dev get lenders activated loan Ids 
    @param _lender address of the lender to check if activated loan ids exists*/
    function getLenderActivatedLoanOfferIds(address _lender)
        public
        view
        returns (uint256[] memory)
    {
        return lenderActivatedLoanIds[_lender];
    }

    /**
    @dev get activated loan offers count */
    function getActiveLoansLength() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < loanOfferIds.length; i++) {
            if (
                borrowerOffers[i].loanStatus ==
                NetworkLoanData.LoanStatus.ACTIVE
            ) {
                count++;
            }
        }
        return count;
    }

    function getNetworkBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    //only super admin can withdraw coins
    function withdrawCoin(
        uint256 _withdrawAmount,
        address payable _walletAddress
    ) public onlySuperAdmin(msg.sender) {
        require(
            _withdrawAmount <= address(this).balance,
            "GNL: Amount Invalid"
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
            _withdrawAmount <=
                IERC20Upgradeable(_tokenAddress).balanceOf(address(this)),
            "GNL: Amount Invalid"
        );
        IERC20Upgradeable(_tokenAddress).safeTransfer(
            _walletAddress,
            _withdrawAmount
        );
        emit WithdrawToken(_tokenAddress, _walletAddress, _withdrawAmount);
    }

    function getLTVPercentage() external view override returns (uint256) {
        return ltvPercentage;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

interface IDexFactory {
    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IDexPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
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

import "../library/NetworkLoanData.sol";
import "../interfaces/INetworkLoan.sol";

abstract contract NetworkLoanBase is INetworkLoan {
    //Load library structs into contract
    using NetworkLoanData for *;
    using NetworkLoanData for bytes32;

    //saves the transaction hash of the create loan offer transaction as loanId
    //saves information in loanOffers when createLoan is called
    mapping(uint256 => NetworkLoanData.LoanDetails) public borrowerOffers;

    //mapping saves the information of the lender across the active loanId
    mapping(uint256 => NetworkLoanData.LenderDetails)
        public activatedLoanByLenders;

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
    function getAPYFee(NetworkLoanData.LoanDetails memory _loanDetails)
        external
        pure
        override
        returns (uint256)
    {
        // APY Fee Formula
        return
            ((_loanDetails.loanAmountInBorrowed * _loanDetails.apyOffer) /
                10000 /
                365) * _loanDetails.termsLengthInDays;
    }

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external pure override returns (uint256) {
        // APY Fee Formula
        return ((loanAmount * autosellAPY) / 10000 / 365) * loanterminDays;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library NetworkLoanData {
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
        //user choose terms length in days
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct ChainlinkDataFeed {
    AggregatorV3Interface usdPriceAggrigator;
    bool enabled;
    uint256 decimals;
}

interface IGovPriceConsumer {
    event PriceFeedAdded(
        address indexed token,
        address usdPriceAggrigator,
        bool enabled,
        uint256 decimals
    );
    event PriceFeedAddedBulk(
        address[] indexed tokens,
        address[] chainlinkFeedAddress,
        bool[] enabled,
        uint256[] decimals
    );
    event PriceFeedRemoved(address indexed token);

    /**
     * Use chainlink PriceAggrigator to fetch prices of the already added feeds.
     */
    function getLatestUsdPriceFromChainlink(address priceFeedToken)
        external
        view
        returns (int256, uint8);

    /**
    @dev multiple token prices fetch
    @param priceFeedToken multi token price fetch
    */
    function getLatestUsdPricesFromChainlink(address[] memory priceFeedToken)
        external
        view
        returns (
            address[] memory tokens,
            int256[] memory prices,
            uint8[] memory decimals
        );

    function getNetworkPriceFromChainlinkinUSD() external view returns (int256);

    function getSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    function getNetworkCoinSwapData(
        address _collateralToken,
        uint256 _collateralAmount,
        address _borrowStableCoin
    ) external view returns (uint256, uint256);

    function getSwapInterface(address _collateralTokenAddress)
        external
        view
        returns (address);

    function getSwapInterfaceForETH() external view returns (address);

    /**
     * @dev How  much worth alt is in terms of stable coin passed (e.g. X ALT =  ? STABLE COIN)
     * @param _stable address of stable coin
     * @param _alt address of alt coin
     * @param _amount address of alt
     */
    function getDexTokenPrice(
        address _stable,
        address _alt,
        uint256 _amount
    ) external view returns (uint256);

    //check wether token feed for this token is enabled or not
    function isChainlinFeedEnabled(address _tokenAddress)
        external
        view
        returns (bool);

    function getusdPriceAggrigators(address _tokenAddress)
        external
        view
        returns (ChainlinkDataFeed memory);

    function getAllChainlinkAggiratorsContract()
        external
        view
        returns (address[] memory);

    function getAllGovAggiratorsTokens()
        external
        view
        returns (address[] memory);

    function WETHAddress() external view returns (address);

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
        address _borrowedToken,
        uint256 _loanAmount
    ) external view returns (uint256);

    function getSUNTokenPrice(
        address _claimToken,
        address _stable,
        address _sunToken,
        uint256 _amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IUniswapSwapInterface {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

    /**
    @dev function that will get AutoSell APY fee of the loan amount
     */
    function getautosellAPYFee(
        uint256 loanAmount,
        uint256 autosellAPY,
        uint256 loanterminDays
    ) external returns (uint256);

    function getLTVPercentage() external view returns (uint256);

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
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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