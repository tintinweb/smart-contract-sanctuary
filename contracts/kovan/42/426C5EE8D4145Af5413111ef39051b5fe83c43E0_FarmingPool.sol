// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./libraries/Exponential.sol";
import "./libraries/IterableLoanMap.sol";
import "./interfaces/IAdapter.sol";
import "./interfaces/IBtoken.sol";
import "./interfaces/IFarmingPool.sol";
import "./interfaces/ITreasuryPool.sol";

contract FarmingPool is Pausable, ReentrancyGuard, IFarmingPool {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Exponential for uint256;
    using IterableLoanMap for IterableLoanMap.RateToLoanMap;

    struct RepaymentDetails {
        uint256 underlyingAssetInvested;
        uint256 profit;
        uint256 taxAmount;
        uint256 depositPrincipal;
        uint256 payableInterest;
        uint256 loanPrincipalToRepay;
        uint256 amountToReceive;
    }

    uint256 public constant ROUNDING_TOLERANCE = 9999999999 wei;
    uint256 public constant NUM_FRACTION_BITS = 64;
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant DAYS_IN_YEAR = 365;
    uint256 public constant SECONDS_IN_YEAR = SECONDS_IN_DAY * DAYS_IN_YEAR;
    // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
    // slither-disable-next-line too-many-digits
    uint256 public constant INTEREST_RATE_SLOPE_1 = 0x5555555555555555; // 1/3 in unsigned 64.64 fixzed-point number
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-too-similar
    // slither-disable-next-line similar-names,too-many-digits
    uint256 public constant INTEREST_RATE_SLOPE_2 = 0xF0000000000000000; // 15 in unsigned 64.64 fixed-point number
    uint256 public constant INTEREST_RATE_INTEGER_POINT_1 = 10;
    // slither-disable-next-line similar-names
    uint256 public constant INTEREST_RATE_INTEGER_POINT_2 = 25;
    uint256 public constant PERCENT_100 = 100;
    // slither-disable-next-line too-many-digits
    uint256 public constant UTILISATION_RATE_POINT_1 = 0x320000000000000000; // 50% in unsigned 64.64 fixed-point number
    // slither-disable-next-line similar-names,too-many-digits
    uint256 public constant UTILISATION_RATE_POINT_2 = 0x5F0000000000000000; // 95% in unsigned 64.64 fixed-point number

    string public name;
    address public governanceAccount;
    address public underlyingAssetAddress;
    address public btokenAddress;
    address public treasuryPoolAddress;
    address public insuranceFundAddress;
    address public adapterAddress;
    uint256 public leverageFactor;
    uint256 public liquidationPenalty; // as percentage in unsigned integer
    uint256 public taxRate; // as percentage in unsigned integer

    uint256 public totalUnderlyingAsset;
    uint256 public totalInterestEarned;

    mapping(address => uint256) private _totalTransferToAdapter;
    mapping(address => IterableLoanMap.RateToLoanMap) private _farmerLoans;
    IterableLoanMap.RateToLoanMap private _poolLoans;

    constructor(
        string memory name_,
        address underlyingAssetAddress_,
        address btokenAddress_,
        address treasuryPoolAddress_,
        address insuranceFundAddress_,
        uint256 leverageFactor_,
        uint256 liquidationPenalty_,
        uint256 taxRate_
    ) {
        require(
            underlyingAssetAddress_ != address(0),
            "0 underlying asset address"
        );
        require(btokenAddress_ != address(0), "0 BToken address");
        require(treasuryPoolAddress_ != address(0), "0 treasury pool address");
        require(
            insuranceFundAddress_ != address(0),
            "0 insurance fund address"
        );
        require(leverageFactor_ >= 1, "leverage factor < 1");
        require(liquidationPenalty_ <= 100, "liquidation penalty > 100%");
        require(taxRate_ <= 100, "tax rate > 100%");

        name = name_;
        governanceAccount = msg.sender;
        underlyingAssetAddress = underlyingAssetAddress_;
        btokenAddress = btokenAddress_;
        treasuryPoolAddress = treasuryPoolAddress_;
        insuranceFundAddress = insuranceFundAddress_;
        leverageFactor = leverageFactor_;
        liquidationPenalty = liquidationPenalty_;
        taxRate = taxRate_;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "unauthorized");
        _;
    }

    function addLiquidity(uint256 amount) external override nonReentrant {
        require(amount > 0, "0 amount");
        require(!paused(), "paused");
        require(
            IERC20(underlyingAssetAddress).balanceOf(msg.sender) >= amount,
            "insufficient underlying asset"
        );

        uint256 utilisationRate =
            ITreasuryPool(treasuryPoolAddress).getUtilisationRate(); // in unsigned 64.64-bit fixed point number
        uint256 integerNominalAnnualRate =
            getBorrowNominalAnnualRate(utilisationRate);
        uint256 transferAmount = amount.mul(leverageFactor);
        _totalTransferToAdapter[msg.sender] = _totalTransferToAdapter[
            msg.sender
        ]
            .add(transferAmount);
        uint256 loanAmount = transferAmount.sub(amount);

        updateLoansForDeposit(
            _farmerLoans[msg.sender],
            integerNominalAnnualRate,
            loanAmount
        );
        updateLoansForDeposit(_poolLoans, integerNominalAnnualRate, loanAmount);

        totalUnderlyingAsset = totalUnderlyingAsset.add(amount);

        IERC20(underlyingAssetAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        ITreasuryPool(treasuryPoolAddress).loan(loanAmount);

        bool isApproved =
            IERC20(underlyingAssetAddress).approve(
                adapterAddress,
                transferAmount
            );
        require(isApproved, "approve failed");
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-events
        uint256 receiveQuantity =
            IAdapter(adapterAddress).depositUnderlyingToken(transferAmount);

        emit AddLiquidity(
            msg.sender,
            underlyingAssetAddress,
            amount,
            receiveQuantity,
            block.timestamp
        );

        IBtoken(btokenAddress).mint(msg.sender, receiveQuantity);
    }

    function removeLiquidity(uint256 requestedAmount)
        external
        override
        nonReentrant
    {
        require(requestedAmount > 0, "0 requested amount");
        require(!paused(), "paused");

        (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        ) = removeLiquidityFor(msg.sender, requestedAmount);

        emit RemoveLiquidity(
            msg.sender,
            underlyingAssetAddress,
            requestedAmount,
            actualAmount,
            receiveQuantity,
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest,
            repaymentDetails.taxAmount,
            actualAmountToReceive,
            outstandingInterest,
            block.timestamp
        );

        {
            // scope to avoid stack too deep errors
            bool isApproved =
                IERC20(underlyingAssetAddress).approve(
                    treasuryPoolAddress,
                    repaymentDetails.loanPrincipalToRepay.add(
                        repaymentDetails.payableInterest
                    )
                );
            require(isApproved, "approve failed");
        }

        ITreasuryPool(treasuryPoolAddress).repay(
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest
        );
        IBtoken(btokenAddress).burn(msg.sender, actualAmount);
        IERC20(underlyingAssetAddress).safeTransfer(
            insuranceFundAddress,
            repaymentDetails.taxAmount
        );
        IERC20(underlyingAssetAddress).safeTransfer(
            msg.sender,
            actualAmountToReceive
        );
    }

    function liquidate(address account)
        external
        override
        nonReentrant
        onlyBy(governanceAccount)
    {
        require(account != address(0), "0 account");

        uint256 farmerBtokenBalance = IBtoken(btokenAddress).balanceOf(account);
        require(farmerBtokenBalance > 0, "insufficient BToken");

        (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        ) = removeLiquidityFor(account, farmerBtokenBalance);

        uint256 penalty =
            actualAmountToReceive.mul(liquidationPenalty).div(PERCENT_100);
        uint256 finalAmountToReceive = actualAmountToReceive.sub(penalty);

        emit LiquidateFarmer(
            msg.sender,
            underlyingAssetAddress,
            account,
            farmerBtokenBalance,
            actualAmount,
            receiveQuantity,
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest,
            repaymentDetails.taxAmount,
            penalty,
            finalAmountToReceive,
            outstandingInterest,
            block.timestamp
        );

        {
            // scope to avoid stack too deep errors
            bool isApproved =
                IERC20(underlyingAssetAddress).approve(
                    treasuryPoolAddress,
                    repaymentDetails.loanPrincipalToRepay.add(
                        repaymentDetails.payableInterest
                    )
                );
            require(isApproved, "approve failed");
        }

        ITreasuryPool(treasuryPoolAddress).repay(
            repaymentDetails.loanPrincipalToRepay,
            repaymentDetails.payableInterest
        );
        IBtoken(btokenAddress).burn(account, actualAmount);
        IERC20(underlyingAssetAddress).safeTransfer(
            insuranceFundAddress,
            repaymentDetails.taxAmount.add(penalty)
        );
        IERC20(underlyingAssetAddress).safeTransfer(
            account,
            finalAmountToReceive
        );
    }

    function computeBorrowerInterestEarning()
        external
        override
        onlyBy(treasuryPoolAddress)
        returns (uint256 borrowerInterestEarning)
    {
        require(!paused(), "paused");

        (
            ,
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) = accrueInterestForLoan(_poolLoans);

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );

        borrowerInterestEarning = getInterestEarning(poolSortedLoans);

        updateLoansForPoolComputeInterest(
            poolIntegerInterestRates,
            poolSortedLoans
        );

        emit ComputeBorrowerInterestEarning(
            borrowerInterestEarning,
            block.timestamp
        );
    }

    function setGovernanceAccount(address newGovernanceAccount)
        external
        onlyBy(governanceAccount)
    {
        require(newGovernanceAccount != address(0), "0 governance account");

        governanceAccount = newGovernanceAccount;
    }

    function setTreasuryPoolAddress(address newTreasuryPoolAddress)
        external
        onlyBy(governanceAccount)
    {
        require(
            newTreasuryPoolAddress != address(0),
            "0 treasury pool address"
        );

        treasuryPoolAddress = newTreasuryPoolAddress;
    }

    function setAdapterAddress(address newAdapterAddress)
        external
        onlyBy(governanceAccount)
    {
        require(newAdapterAddress != address(0), "0 adapter address");

        adapterAddress = newAdapterAddress;
    }

    function setLiquidationPenalty(uint256 liquidationPenalty_)
        external
        onlyBy(governanceAccount)
    {
        require(liquidationPenalty_ <= 100, "liquidation penalty > 100%");

        liquidationPenalty = liquidationPenalty_;
    }

    function pause() external onlyBy(governanceAccount) {
        _pause();
    }

    function unpause() external onlyBy(governanceAccount) {
        _unpause();
    }

    function getTotalTransferToAdapterFor(address account)
        external
        view
        override
        returns (uint256 totalTransferToAdapter)
    {
        require(account != address(0), "zero account");

        totalTransferToAdapter = _totalTransferToAdapter[account];
    }

    function getLoansAtLastAccrualFor(address account)
        external
        view
        override
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        )
    {
        require(account != address(0), "zero account");

        uint256 numEntries = _farmerLoans[account].length();
        interestRates = new uint256[](numEntries);
        principalsOnly = new uint256[](numEntries);
        principalsWithInterest = new uint256[](numEntries);
        lastAccrualTimestamps = new uint256[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (uint256 interestRate, IterableLoanMap.Loan memory farmerLoan) =
                _farmerLoans[account].at(i);

            interestRates[i] = interestRate;
            principalsOnly[i] = farmerLoan._principalOnly;
            principalsWithInterest[i] = farmerLoan._principalWithInterest;
            lastAccrualTimestamps[i] = farmerLoan._lastAccrualTimestamp;
        }
    }

    function getPoolLoansAtLastAccrual()
        external
        view
        override
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        )
    {
        uint256 numEntries = _poolLoans.length();
        interestRates = new uint256[](numEntries);
        principalsOnly = new uint256[](numEntries);
        principalsWithInterest = new uint256[](numEntries);
        lastAccrualTimestamps = new uint256[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (uint256 interestRate, IterableLoanMap.Loan memory poolLoan) =
                _poolLoans.at(i);

            interestRates[i] = interestRate;
            principalsOnly[i] = poolLoan._principalOnly;
            principalsWithInterest[i] = poolLoan._principalWithInterest;
            lastAccrualTimestamps[i] = poolLoan._lastAccrualTimestamp;
        }
    }

    function estimateBorrowerInterestEarning()
        external
        view
        override
        returns (uint256 borrowerInterestEarning)
    {
        (
            ,
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) = accrueInterestForLoan(_poolLoans);

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );

        borrowerInterestEarning = getInterestEarning(poolSortedLoans);
    }

    function needToLiquidate(address account, uint256 liquidationThreshold)
        external
        view
        override
        returns (
            bool isLiquidate,
            uint256 accountRedeemableUnderlyingTokens,
            uint256 threshold
        )
    {
        require(account != address(0), "zero account");
        uint256 accountBtokenBalance =
            IBtoken(btokenAddress).balanceOf(account);
        require(accountBtokenBalance > 0, "insufficient BToken");

        (
            uint256 farmerOutstandingInterest,
            uint256[] memory farmerIntegerInterestRates,
            IterableLoanMap.Loan[] memory farmerSortedLoans
        ) = accrueInterestForLoan(_farmerLoans[account]);

        require(
            farmerIntegerInterestRates.length == farmerSortedLoans.length,
            "farmer len diff"
        );

        accountRedeemableUnderlyingTokens = IAdapter(adapterAddress)
            .getRedeemableUnderlyingTokensFor(accountBtokenBalance);

        RepaymentDetails memory repaymentDetails =
            calculateRepaymentDetails(
                account,
                accountBtokenBalance,
                accountRedeemableUnderlyingTokens,
                farmerOutstandingInterest
            );

        isLiquidate = false;
        threshold = repaymentDetails
            .loanPrincipalToRepay
            .add(repaymentDetails.taxAmount)
            .add(repaymentDetails.payableInterest)
            .mul(liquidationThreshold.add(PERCENT_100))
            .div(PERCENT_100);
        if (accountRedeemableUnderlyingTokens < threshold) {
            isLiquidate = true;
        }
    }

    /**
     * @dev Returns the borrow nominal annual rate round down to nearest integer
     *
     * @param utilisationRate as percentage in unsigned 64.64-bit fixed point number
     * @return integerInterestRate as percentage round down to nearest integer
     */
    function getBorrowNominalAnnualRate(uint256 utilisationRate)
        public
        pure
        returns (uint256 integerInterestRate)
    {
        // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
        // slither-disable-next-line too-many-digits
        require(utilisationRate <= 0x640000000000000000, "> 100%");

        if (utilisationRate <= UTILISATION_RATE_POINT_1) {
            integerInterestRate = INTEREST_RATE_INTEGER_POINT_1;
        } else if (utilisationRate < UTILISATION_RATE_POINT_2) {
            uint256 pointSlope =
                utilisationRate.sub(UTILISATION_RATE_POINT_1).mul(
                    INTEREST_RATE_SLOPE_1
                ) >> (NUM_FRACTION_BITS * 2);

            integerInterestRate = pointSlope.add(INTEREST_RATE_INTEGER_POINT_1);
        } else {
            uint256 pointSlope =
                utilisationRate.sub(UTILISATION_RATE_POINT_2).mul(
                    INTEREST_RATE_SLOPE_2
                ) >> (NUM_FRACTION_BITS * 2);

            integerInterestRate = pointSlope.add(INTEREST_RATE_INTEGER_POINT_2);
        }
    }

    /**
     * @dev Returns the accrue per second compound interest, reverts if overflow
     *
     * @param presentValue in wei
     * @param nominalAnnualRate as percentage in unsigned integer
     * @param numSeconds in unsigned integer
     * @return futureValue in wei
     */
    function accruePerSecondCompoundInterest(
        uint256 presentValue,
        uint256 nominalAnnualRate,
        uint256 numSeconds
    ) public pure returns (uint256 futureValue) {
        require(nominalAnnualRate <= 100, "> 100%");

        uint256 exponent =
            numSeconds.mul(
                (
                    ((
                        nominalAnnualRate.add(SECONDS_IN_YEAR.mul(PERCENT_100))
                    ) << NUM_FRACTION_BITS)
                        .div(SECONDS_IN_YEAR.mul(PERCENT_100))
                )
                    .logBase2()
            );

        futureValue =
            exponent.expBase2().mul(presentValue) >>
            NUM_FRACTION_BITS;
    }

    /**
     * @dev Returns the seconds since last accrual
     *
     * @param currentTimestamp in seconds
     * @param lastAccrualTimestamp in seconds
     * @return secondsSinceLastAccrual
     * @return accrualTimestamp in seconds
     */
    function getSecondsSinceLastAccrual(
        uint256 currentTimestamp,
        uint256 lastAccrualTimestamp
    )
        public
        pure
        returns (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp)
    {
        require(
            currentTimestamp >= lastAccrualTimestamp,
            "current before last"
        );

        secondsSinceLastAccrual = currentTimestamp.sub(lastAccrualTimestamp);
        accrualTimestamp = currentTimestamp;
    }

    function accrueInterestForLoan(
        IterableLoanMap.RateToLoanMap storage rateToLoanMap
    )
        private
        view
        returns (
            uint256 outstandingInterest,
            uint256[] memory integerInterestRates,
            IterableLoanMap.Loan[] memory sortedLoans
        )
    {
        bool[] memory interestRateExists = new bool[](PERCENT_100 + 1);
        IterableLoanMap.Loan[] memory loansByInterestRate =
            new IterableLoanMap.Loan[](PERCENT_100 + 1);

        uint256 numEntries = rateToLoanMap.length();
        integerInterestRates = new uint256[](numEntries);
        sortedLoans = new IterableLoanMap.Loan[](numEntries);
        outstandingInterest = 0;

        for (uint256 i = 0; i < numEntries; i++) {
            (
                uint256 integerNominalAnnualRate,
                IterableLoanMap.Loan memory loan
            ) = rateToLoanMap.at(i);

            (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp) =
                getSecondsSinceLastAccrual(
                    block.timestamp,
                    loan._lastAccrualTimestamp
                );

            loan._lastAccrualTimestamp = accrualTimestamp;

            if (
                loan._principalWithInterest > 0 && secondsSinceLastAccrual > 0
            ) {
                loan._principalWithInterest = accruePerSecondCompoundInterest(
                    loan._principalWithInterest,
                    integerNominalAnnualRate,
                    secondsSinceLastAccrual
                );
            }

            outstandingInterest = outstandingInterest
                .add(loan._principalWithInterest)
                .sub(loan._principalOnly);

            loansByInterestRate[integerNominalAnnualRate] = loan;
            interestRateExists[integerNominalAnnualRate] = true;
        }

        uint256 index = 0;
        for (
            uint256 rate = INTEREST_RATE_INTEGER_POINT_1;
            rate <= PERCENT_100;
            rate++
        ) {
            if (interestRateExists[rate]) {
                integerInterestRates[index] = rate;
                sortedLoans[index] = loansByInterestRate[rate];
                index++;
            }
        }
    }

    function accrueInterestBasedOnInterestRates(
        IterableLoanMap.RateToLoanMap storage rateToLoanMap,
        uint256[] memory inIntegerInterestRates
    )
        private
        view
        returns (
            uint256[] memory outIntegerInterestRates,
            IterableLoanMap.Loan[] memory outSortedLoans
        )
    {
        uint256 numEntries = inIntegerInterestRates.length;
        outIntegerInterestRates = new uint256[](numEntries);
        outSortedLoans = new IterableLoanMap.Loan[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            (bool keyExists, IterableLoanMap.Loan memory loan) =
                rateToLoanMap.tryGet(inIntegerInterestRates[i]);

            (uint256 secondsSinceLastAccrual, uint256 accrualTimestamp) =
                getSecondsSinceLastAccrual(
                    block.timestamp,
                    keyExists ? loan._lastAccrualTimestamp : block.timestamp
                );

            loan._lastAccrualTimestamp = accrualTimestamp;

            if (
                loan._principalWithInterest > 0 && secondsSinceLastAccrual > 0
            ) {
                loan._principalWithInterest = accruePerSecondCompoundInterest(
                    loan._principalWithInterest,
                    inIntegerInterestRates[i],
                    secondsSinceLastAccrual
                );
            }

            outIntegerInterestRates[i] = inIntegerInterestRates[i];
            outSortedLoans[i] = loan;
        }
    }

    function calculateRepaymentDetails(
        address farmerAccount,
        uint256 btokenAmount,
        uint256 underlyingAssetQuantity,
        uint256 outstandingInterest
    ) public view returns (RepaymentDetails memory repaymentDetails) {
        uint256 totalTransferToAdapter = _totalTransferToAdapter[farmerAccount];
        // https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        // slither-disable-next-line divide-before-multiply
        uint256 underlyingAssetInvested =
            btokenAmount.mul(totalTransferToAdapter).div(
                IBtoken(btokenAddress).balanceOf(farmerAccount)
            );
        repaymentDetails.underlyingAssetInvested = underlyingAssetInvested;

        repaymentDetails.profit = 0;
        repaymentDetails.taxAmount = 0;
        if (underlyingAssetQuantity > underlyingAssetInvested) {
            repaymentDetails.profit = underlyingAssetQuantity.sub(
                underlyingAssetInvested
            );
            repaymentDetails.taxAmount = repaymentDetails
                .profit
                .mul(taxRate)
                .div(PERCENT_100);
        }

        uint256 depositPrincipal = underlyingAssetInvested.div(leverageFactor);
        repaymentDetails.depositPrincipal = depositPrincipal;
        // slither-disable-next-line divide-before-multiply
        repaymentDetails.payableInterest = outstandingInterest
            .mul(underlyingAssetInvested)
            .div(totalTransferToAdapter);
        repaymentDetails.loanPrincipalToRepay = underlyingAssetInvested.sub(
            depositPrincipal
        );

        repaymentDetails.amountToReceive = underlyingAssetQuantity
            .sub(repaymentDetails.loanPrincipalToRepay)
            .sub(repaymentDetails.taxAmount)
            .sub(repaymentDetails.payableInterest);
    }

    function removeLiquidityFor(address account, uint256 requestedAmount)
        private
        returns (
            RepaymentDetails memory repaymentDetails,
            uint256 actualAmount,
            uint256 receiveQuantity,
            uint256 actualAmountToReceive,
            uint256 outstandingInterest
        )
    {
        require(account != address(0), "0 account");
        require(requestedAmount > 0, "0 requested amount");
        uint256 farmerTotalTransferToAdapter = _totalTransferToAdapter[account];
        require(farmerTotalTransferToAdapter > 0, "no transfer");
        require(
            IBtoken(btokenAddress).balanceOf(account) >= requestedAmount,
            "insufficient BToken"
        );

        (
            uint256 farmerOutstandingInterest,
            uint256[] memory farmerIntegerInterestRates,
            IterableLoanMap.Loan[] memory farmerSortedLoans
        ) = accrueInterestForLoan(_farmerLoans[account]);

        outstandingInterest = farmerOutstandingInterest;

        require(
            farmerIntegerInterestRates.length == farmerSortedLoans.length,
            "farmer len diff"
        );

        (
            uint256[] memory poolIntegerInterestRates,
            IterableLoanMap.Loan[] memory poolSortedLoans
        ) =
            accrueInterestBasedOnInterestRates(
                _poolLoans,
                farmerIntegerInterestRates
            );

        require(
            poolIntegerInterestRates.length == poolSortedLoans.length,
            "pool len diff"
        );
        require(
            farmerIntegerInterestRates.length ==
                poolIntegerInterestRates.length,
            "farmer/pool len diff"
        );

        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-2
        // https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-3
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        (actualAmount, receiveQuantity) = IAdapter(adapterAddress)
            .redeemWrappedToken(requestedAmount);
        require(
            actualAmount <= requestedAmount,
            "actual greater than requested amount"
        );

        repaymentDetails = calculateRepaymentDetails(
            account,
            actualAmount,
            receiveQuantity,
            farmerOutstandingInterest
        );

        _totalTransferToAdapter[account] = farmerTotalTransferToAdapter.sub(
            repaymentDetails.underlyingAssetInvested
        );

        totalInterestEarned = totalInterestEarned.add(
            repaymentDetails.payableInterest
        );

        updateLoansForFarmerAndPoolWithdraw(
            account,
            farmerIntegerInterestRates,
            farmerSortedLoans,
            poolSortedLoans,
            repaymentDetails
        );

        {
            // scope to avoid stack too deep errors
            uint256 underlyingAssetAmount = totalUnderlyingAsset;
            if (
                underlyingAssetAmount < repaymentDetails.depositPrincipal &&
                repaymentDetails.depositPrincipal.sub(underlyingAssetAmount) <
                ROUNDING_TOLERANCE
            ) {
                totalUnderlyingAsset = 0;
            } else {
                totalUnderlyingAsset = underlyingAssetAmount.sub(
                    repaymentDetails.depositPrincipal
                );
            }
        }

        actualAmountToReceive = repaymentDetails.amountToReceive;
        {
            // scope to avoid stack too deep errors
            uint256 farmingPoolUnderlyingAssetBalance =
                IERC20(underlyingAssetAddress).balanceOf(address(this));
            if (
                farmingPoolUnderlyingAssetBalance < actualAmountToReceive &&
                actualAmountToReceive.sub(farmingPoolUnderlyingAssetBalance) <
                ROUNDING_TOLERANCE
            ) {
                actualAmountToReceive = farmingPoolUnderlyingAssetBalance;
            }
        }
    }

    function getInterestEarning(IterableLoanMap.Loan[] memory poolSortedLoans)
        private
        pure
        returns (uint256 interestEarning)
    {
        interestEarning = 0;
        for (uint256 index = 0; index < poolSortedLoans.length; index++) {
            interestEarning = interestEarning
                .add(poolSortedLoans[index]._principalWithInterest)
                .sub(poolSortedLoans[index]._principalOnly);
        }
    }

    function updateLoansForDeposit(
        IterableLoanMap.RateToLoanMap storage loans,
        uint256 integerNominalAnnualRate,
        uint256 loanAmount
    ) private {
        (bool keyExists, IterableLoanMap.Loan memory loan) =
            loans.tryGet(integerNominalAnnualRate);

        uint256 secondsSinceLastAccrual = 0;
        uint256 accrualTimestamp = block.timestamp;
        if (keyExists) {
            (
                secondsSinceLastAccrual,
                accrualTimestamp
            ) = getSecondsSinceLastAccrual(
                block.timestamp,
                loan._lastAccrualTimestamp
            );
        }

        uint256 presentValue = loan._principalWithInterest;
        uint256 futureValue = presentValue;
        if (presentValue > 0 && secondsSinceLastAccrual > 0) {
            futureValue = accruePerSecondCompoundInterest(
                presentValue,
                integerNominalAnnualRate,
                secondsSinceLastAccrual
            );
        }

        loan._principalOnly = loan._principalOnly.add(loanAmount);
        loan._principalWithInterest = futureValue.add(loanAmount);
        loan._lastAccrualTimestamp = accrualTimestamp;

        // https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
        // slither-disable-next-line unused-return
        loans.set(integerNominalAnnualRate, loan);
    }

    function updateLoansForFarmerAndPoolWithdraw(
        address farmerAccount,
        uint256[] memory integerInterestRates,
        IterableLoanMap.Loan[] memory farmerSortedLoans,
        IterableLoanMap.Loan[] memory poolSortedLoans,
        RepaymentDetails memory repaymentDetails
    ) private {
        require(integerInterestRates.length > 0, "integerInterestRates len");
        require(
            farmerSortedLoans.length == integerInterestRates.length,
            "farmerSortedLoans len"
        );
        require(
            poolSortedLoans.length == integerInterestRates.length,
            "poolSortedLoans len"
        );

        uint256 repayPrincipalRemaining = repaymentDetails.loanPrincipalToRepay;
        uint256 repayPrincipalWithInterestRemaining =
            repaymentDetails.loanPrincipalToRepay.add(
                repaymentDetails.payableInterest
            );

        for (uint256 index = integerInterestRates.length; index > 0; index--) {
            if (repayPrincipalRemaining > 0) {
                if (
                    farmerSortedLoans[index - 1]._principalOnly >=
                    repayPrincipalRemaining
                ) {
                    farmerSortedLoans[index - 1]
                        ._principalOnly = farmerSortedLoans[index - 1]
                        ._principalOnly
                        .sub(repayPrincipalRemaining);

                    poolSortedLoans[index - 1]._principalOnly = poolSortedLoans[
                        index - 1
                    ]
                        ._principalOnly
                        .sub(repayPrincipalRemaining);

                    repayPrincipalRemaining = 0;
                } else {
                    poolSortedLoans[index - 1]._principalOnly = poolSortedLoans[
                        index - 1
                    ]
                        ._principalOnly
                        .sub(farmerSortedLoans[index - 1]._principalOnly);

                    repayPrincipalRemaining = repayPrincipalRemaining.sub(
                        farmerSortedLoans[index - 1]._principalOnly
                    );

                    farmerSortedLoans[index - 1]._principalOnly = 0;
                }
            }

            if (repayPrincipalWithInterestRemaining > 0) {
                if (
                    farmerSortedLoans[index - 1]._principalWithInterest >=
                    repayPrincipalWithInterestRemaining
                ) {
                    farmerSortedLoans[index - 1]
                        ._principalWithInterest = farmerSortedLoans[index - 1]
                        ._principalWithInterest
                        .sub(repayPrincipalWithInterestRemaining);

                    if (
                        poolSortedLoans[index - 1]._principalWithInterest <
                        repayPrincipalWithInterestRemaining &&
                        repayPrincipalWithInterestRemaining.sub(
                            poolSortedLoans[index - 1]._principalWithInterest
                        ) <
                        ROUNDING_TOLERANCE
                    ) {
                        poolSortedLoans[index - 1]._principalWithInterest = 0;
                    } else {
                        poolSortedLoans[index - 1]
                            ._principalWithInterest = poolSortedLoans[index - 1]
                            ._principalWithInterest
                            .sub(repayPrincipalWithInterestRemaining);
                    }

                    repayPrincipalWithInterestRemaining = 0;
                } else {
                    if (
                        poolSortedLoans[index - 1]._principalWithInterest <
                        farmerSortedLoans[index - 1]._principalWithInterest &&
                        farmerSortedLoans[index - 1]._principalWithInterest.sub(
                            poolSortedLoans[index - 1]._principalWithInterest
                        ) <
                        ROUNDING_TOLERANCE
                    ) {
                        poolSortedLoans[index - 1]._principalWithInterest = 0;
                    } else {
                        poolSortedLoans[index - 1]
                            ._principalWithInterest = poolSortedLoans[index - 1]
                            ._principalWithInterest
                            .sub(
                            farmerSortedLoans[index - 1]._principalWithInterest
                        );
                    }

                    repayPrincipalWithInterestRemaining = repayPrincipalWithInterestRemaining
                        .sub(
                        farmerSortedLoans[index - 1]._principalWithInterest
                    );

                    farmerSortedLoans[index - 1]._principalWithInterest = 0;
                }
            }

            if (
                farmerSortedLoans[index - 1]._principalOnly > 0 ||
                farmerSortedLoans[index - 1]._principalWithInterest > 0
            ) {
                // https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
                // slither-disable-next-line unused-return
                _farmerLoans[farmerAccount].set(
                    integerInterestRates[index - 1],
                    farmerSortedLoans[index - 1]
                );
            } else {
                // slither-disable-next-line unused-return
                _farmerLoans[farmerAccount].remove(
                    integerInterestRates[index - 1]
                );
            }

            if (
                poolSortedLoans[index - 1]._principalOnly > 0 ||
                poolSortedLoans[index - 1]._principalWithInterest > 0
            ) {
                // slither-disable-next-line unused-return
                _poolLoans.set(
                    integerInterestRates[index - 1],
                    poolSortedLoans[index - 1]
                );
            } else {
                // slither-disable-next-line unused-return
                _poolLoans.remove(integerInterestRates[index - 1]);
            }
        }
    }

    function updateLoansForPoolComputeInterest(
        uint256[] memory integerInterestRates,
        IterableLoanMap.Loan[] memory poolSortedLoans
    ) private {
        require(
            poolSortedLoans.length == integerInterestRates.length,
            "poolSortedLoans len"
        );

        for (uint256 index = 0; index < integerInterestRates.length; index++) {
            if (
                poolSortedLoans[index]._principalOnly > 0 ||
                poolSortedLoans[index]._principalWithInterest > 0
            ) {
                // slither-disable-next-line unused-return
                _poolLoans.set(
                    integerInterestRates[index],
                    poolSortedLoans[index]
                );
            } else {
                // slither-disable-next-line unused-return
                _poolLoans.remove(integerInterestRates[index]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Library for calculating exponential of unsigned 64.64-bit fixed-point numbers
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using Exponential for uint256;
 * }
 * ```
 */
library Exponential {
    using SafeMath for uint256;

    uint256 private constant _MAX_UINT256_64_64 =
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 private constant _EXP2_OUT_FRACTION_BITS = 64;
    uint256 private constant _EXP2_OUT_INTEGER_BITS = 64;

    uint256 private constant _EXP2_FRACTION_MASK =
        2**(_EXP2_OUT_FRACTION_BITS - 1);
    uint256 private constant _EXP2_IN_MAX_EXPONENT =
        _EXP2_OUT_INTEGER_BITS << _EXP2_OUT_FRACTION_BITS;
    uint256 private constant _EXP2_SCALE =
        2**(_EXP2_OUT_INTEGER_BITS + _EXP2_OUT_FRACTION_BITS - 1);

    // _EXP2_MAGIC_FACTOR_x = 2**(2**(-x)) represented as 128 fraction bits fixed-point number
    uint256 private constant _EXP2_MAGIC_FACTOR_FRACTION_BITS = 128;
    uint256 private constant _EXP2_MAGIC_FACTOR_01 =
        0x16A09E667F3BCC908B2FB1366EA957D3E;
    // https://github.com/crytic/slither/wiki/Detector-Documentation#variable-names-too-similar
    // https://github.com/crytic/slither/wiki/Detector-Documentation#too-many-digits
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_02 =
        0x1306FE0A31B7152DE8D5A46305C85EDEC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_03 =
        0x1172B83C7D517ADCDF7C8C50EB14A791F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_04 =
        0x10B5586CF9890F6298B92B71842A98363;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_05 =
        0x1059B0D31585743AE7C548EB68CA417FD;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_06 =
        0x102C9A3E778060EE6F7CACA4F7A29BDE8;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_07 =
        0x10163DA9FB33356D84A66AE336DCDFA3F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_08 =
        0x100B1AFA5ABCBED6129AB13EC11DC9543;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_09 =
        0x10058C86DA1C09EA1FF19D294CF2F679B;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_10 =
        0x1002C605E2E8CEC506D21BFC89A23A00F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_11 =
        0x100162F3904051FA128BCA9C55C31E5DF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_12 =
        0x1000B175EFFDC76BA38E31671CA939725;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_13 =
        0x100058BA01FB9F96D6CACD4B180917C3D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_14 =
        0x10002C5CC37DA9491D0985C348C68E7B3;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_15 =
        0x1000162E525EE054754457D5995292026;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_16 =
        0x10000B17255775C040618BF4A4ADE83FC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_17 =
        0x1000058B91B5BC9AE2EED81E9B7D4CFAB;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_18 =
        0x100002C5C89D5EC6CA4D7C8ACC017B7C9;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_19 =
        0x10000162E43F4F831060E02D839A9D16D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_20 =
        0x100000B1721BCFC99D9F890EA06911763;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_21 =
        0x10000058B90CF1E6D97F9CA14DBCC1628;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_22 =
        0x1000002C5C863B73F016468F6BAC5CA2B;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_23 =
        0x100000162E430E5A18F6119E3C02282A5;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_24 =
        0x1000000B1721835514B86E6D96EFD1BFE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_25 =
        0x100000058B90C0B48C6BE5DF846C5B2EF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_26 =
        0x10000002C5C8601CC6B9E94213C72737A;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_27 =
        0x1000000162E42FFF037DF38AA2B219F06;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_28 =
        0x10000000B17217FBA9C739AA5819F44F9;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_29 =
        0x1000000058B90BFCDEE5ACD3C1CEDC823;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_30 =
        0x100000002C5C85FE31F35A6A30DA1BE50;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_31 =
        0x10000000162E42FF0999CE3541B9FFFCF;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_32 =
        0x100000000B17217F80F4EF5AADDA45554;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_33 =
        0x10000000058B90BFBF8479BD5A81B51AD;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_34 =
        0x1000000002C5C85FDF84BD62AE30A74CC;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_35 =
        0x100000000162E42FEFB2FED257559BDAA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_36 =
        0x1000000000B17217F7D5A7716BBA4A9AE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_37 =
        0x100000000058B90BFBE9DDBAC5E109CCE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_38 =
        0x10000000002C5C85FDF4B15DE6F17EB0D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_39 =
        0x1000000000162E42FEFA494F1478FDE05;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_40 =
        0x10000000000B17217F7D20CF927C8E94C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_41 =
        0x1000000000058B90BFBE8F71CB4E4B33D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_42 =
        0x100000000002C5C85FDF477B662B26945;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_43 =
        0x10000000000162E42FEFA3AE53369388C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_44 =
        0x100000000000B17217F7D1D351A389D40;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_45 =
        0x10000000000058B90BFBE8E8B2D3D4EDE;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_46 =
        0x1000000000002C5C85FDF4741BEA6E77E;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_47 =
        0x100000000000162E42FEFA39FE95583C2;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_48 =
        0x1000000000000B17217F7D1CFB72B45E1;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_49 =
        0x100000000000058B90BFBE8E7CC35C3F0;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_50 =
        0x10000000000002C5C85FDF473E242EA38;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_51 =
        0x1000000000000162E42FEFA39F02B772C;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_52 =
        0x10000000000000B17217F7D1CF7D83C1A;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_53 =
        0x1000000000000058B90BFBE8E7BDCBE2E;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_54 =
        0x100000000000002C5C85FDF473DEA871F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_55 =
        0x10000000000000162E42FEFA39EF44D91;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_56 =
        0x100000000000000B17217F7D1CF79E949;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_57 =
        0x10000000000000058B90BFBE8E7BCE544;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_58 =
        0x1000000000000002C5C85FDF473DE6ECA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_59 =
        0x100000000000000162E42FEFA39EF366F;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_60 =
        0x1000000000000000B17217F7D1CF79AFA;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_61 =
        0x100000000000000058B90BFBE8E7BCD6D;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_62 =
        0x10000000000000002C5C85FDF473DE6B2;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_63 =
        0x1000000000000000162E42FEFA39EF358;
    // slither-disable-next-line similar-names,too-many-digits
    uint256 private constant _EXP2_MAGIC_FACTOR_64 =
        0x10000000000000000B17217F7D1CF79AB;

    uint256 private constant _LOG2_OUT_FRACTION_BITS = 64;
    uint256 private constant _LOG2_OUT_INTEGER_BITS = 64;

    uint256 private constant _LOG2_BITSHIFT_64 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 1;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_32 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 2;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_16 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 3;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_08 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 4;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_04 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 5;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_02 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 6;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_BITSHIFT_01 =
        (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) >> 7;

    uint256 private constant _LOG2_FRACTION_MASK =
        1 << (_LOG2_OUT_FRACTION_BITS - 1);
    uint256 private constant _LOG2_IN_MAX_ARG =
        1 << (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS);

    uint256 private constant _LOG2_THRESHOLD_64 = 1 << _LOG2_BITSHIFT_64;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_32 = 1 << _LOG2_BITSHIFT_32;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_16 = 1 << _LOG2_BITSHIFT_16;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_08 = 1 << _LOG2_BITSHIFT_08;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_04 = 1 << _LOG2_BITSHIFT_04;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_02 = 1 << _LOG2_BITSHIFT_02;
    // slither-disable-next-line similar-names
    uint256 private constant _LOG2_THRESHOLD_01 = 1 << _LOG2_BITSHIFT_01;

    /**
     * @dev Returns the base 2 exponential of self, reverts if overflow
     *
     * @param self unsigned 6.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function expBase2(uint256 self) internal pure returns (uint256) {
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_FRACTION_MASK == 0x8000000000000000,
            "Exponential: fraction mask"
        );
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_IN_MAX_EXPONENT == 0x400000000000000000,
            "Exponential: max exponent"
        );
        // slither-disable-next-line too-many-digits
        require(
            _EXP2_SCALE == 0x80000000000000000000000000000000,
            "Exponential: scale"
        );

        require(self < _EXP2_IN_MAX_EXPONENT, "Exponential: overflow");

        uint256[_EXP2_OUT_FRACTION_BITS] memory magicFactors =
            [
                _EXP2_MAGIC_FACTOR_01,
                _EXP2_MAGIC_FACTOR_02,
                _EXP2_MAGIC_FACTOR_03,
                _EXP2_MAGIC_FACTOR_04,
                _EXP2_MAGIC_FACTOR_05,
                _EXP2_MAGIC_FACTOR_06,
                _EXP2_MAGIC_FACTOR_07,
                _EXP2_MAGIC_FACTOR_08,
                _EXP2_MAGIC_FACTOR_09,
                _EXP2_MAGIC_FACTOR_10,
                _EXP2_MAGIC_FACTOR_11,
                _EXP2_MAGIC_FACTOR_12,
                _EXP2_MAGIC_FACTOR_13,
                _EXP2_MAGIC_FACTOR_14,
                _EXP2_MAGIC_FACTOR_15,
                _EXP2_MAGIC_FACTOR_16,
                _EXP2_MAGIC_FACTOR_17,
                _EXP2_MAGIC_FACTOR_18,
                _EXP2_MAGIC_FACTOR_19,
                _EXP2_MAGIC_FACTOR_20,
                _EXP2_MAGIC_FACTOR_21,
                _EXP2_MAGIC_FACTOR_22,
                _EXP2_MAGIC_FACTOR_23,
                _EXP2_MAGIC_FACTOR_24,
                _EXP2_MAGIC_FACTOR_25,
                _EXP2_MAGIC_FACTOR_26,
                _EXP2_MAGIC_FACTOR_27,
                _EXP2_MAGIC_FACTOR_28,
                _EXP2_MAGIC_FACTOR_29,
                _EXP2_MAGIC_FACTOR_30,
                _EXP2_MAGIC_FACTOR_31,
                _EXP2_MAGIC_FACTOR_32,
                _EXP2_MAGIC_FACTOR_33,
                _EXP2_MAGIC_FACTOR_34,
                _EXP2_MAGIC_FACTOR_35,
                _EXP2_MAGIC_FACTOR_36,
                _EXP2_MAGIC_FACTOR_37,
                _EXP2_MAGIC_FACTOR_38,
                _EXP2_MAGIC_FACTOR_39,
                _EXP2_MAGIC_FACTOR_40,
                _EXP2_MAGIC_FACTOR_41,
                _EXP2_MAGIC_FACTOR_42,
                _EXP2_MAGIC_FACTOR_43,
                _EXP2_MAGIC_FACTOR_44,
                _EXP2_MAGIC_FACTOR_45,
                _EXP2_MAGIC_FACTOR_46,
                _EXP2_MAGIC_FACTOR_47,
                _EXP2_MAGIC_FACTOR_48,
                _EXP2_MAGIC_FACTOR_49,
                _EXP2_MAGIC_FACTOR_50,
                _EXP2_MAGIC_FACTOR_51,
                _EXP2_MAGIC_FACTOR_52,
                _EXP2_MAGIC_FACTOR_53,
                _EXP2_MAGIC_FACTOR_54,
                _EXP2_MAGIC_FACTOR_55,
                _EXP2_MAGIC_FACTOR_56,
                _EXP2_MAGIC_FACTOR_57,
                _EXP2_MAGIC_FACTOR_58,
                _EXP2_MAGIC_FACTOR_59,
                _EXP2_MAGIC_FACTOR_60,
                _EXP2_MAGIC_FACTOR_61,
                _EXP2_MAGIC_FACTOR_62,
                _EXP2_MAGIC_FACTOR_63,
                _EXP2_MAGIC_FACTOR_64
            ];

        uint256 mask = _EXP2_FRACTION_MASK;
        uint256 result = _EXP2_SCALE;

        for (uint256 i = 0; i < _EXP2_OUT_FRACTION_BITS; i++) {
            if ((self & mask) > 0) {
                result =
                    (result * magicFactors[i]) >>
                    _EXP2_MAGIC_FACTOR_FRACTION_BITS;
            }

            mask >>= 1;
        }

        require(mask == 0, "Exponential: unexpected mask");

        result >>=
            _EXP2_OUT_INTEGER_BITS -
            1 -
            (self >> _EXP2_OUT_FRACTION_BITS);
        require(result <= _MAX_UINT256_64_64, "Exponential: exceed");

        return result;
    }

    /**
     * @dev Returns the base 2 logarithm of self, reverts if self <= 0
     *
     * @param self unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function logBase2(uint256 self) internal pure returns (uint256) {
        require(_LOG2_BITSHIFT_64 == 64, "Exponential: bitshift 64");
        require(_LOG2_BITSHIFT_32 == 32, "Exponential: bitshift 32");
        require(_LOG2_BITSHIFT_16 == 16, "Exponential: bitshift 16");
        require(_LOG2_BITSHIFT_08 == 8, "Exponential: bitshift 8");
        require(_LOG2_BITSHIFT_04 == 4, "Exponential: bitshift 4");
        require(_LOG2_BITSHIFT_02 == 2, "Exponential: bitshift 2");
        require(_LOG2_BITSHIFT_01 == 1, "Exponential: bitshift 1");

        // slither-disable-next-line too-many-digits
        require(
            _LOG2_FRACTION_MASK == 0x8000000000000000,
            "Exponential: fraction mask"
        );
        // slither-disable-next-line too-many-digits
        require(
            _LOG2_IN_MAX_ARG == 0x100000000000000000000000000000000,
            "Exponential: max arg"
        );
        // slither-disable-next-line too-many-digits
        require(
            _LOG2_THRESHOLD_64 == 0x10000000000000000,
            "Exponential: threshold 64"
        );
        // slither-disable-next-line too-many-digits
        require(_LOG2_THRESHOLD_32 == 0x100000000, "Exponential: threshold 32");
        require(_LOG2_THRESHOLD_16 == 0x10000, "Exponential: threshold 16");
        require(_LOG2_THRESHOLD_08 == 0x100, "Exponential: threshold 8");
        require(_LOG2_THRESHOLD_04 == 0x10, "Exponential: threshold 4");
        require(_LOG2_THRESHOLD_02 == 0x4, "Exponential: threshold 2");
        require(_LOG2_THRESHOLD_01 == 0x2, "Exponential: threshold 1");

        require(self > 0, "Exponential: zero");
        require(self < _LOG2_IN_MAX_ARG, "Exponential: overflow");

        uint256 leftover = self;
        uint256 intResult = 0;

        if (leftover >= _LOG2_THRESHOLD_64) {
            leftover >>= _LOG2_BITSHIFT_64;
            intResult += _LOG2_BITSHIFT_64;
        }

        if (leftover >= _LOG2_THRESHOLD_32) {
            leftover >>= _LOG2_BITSHIFT_32;
            intResult += _LOG2_BITSHIFT_32;
        }

        if (leftover >= _LOG2_THRESHOLD_16) {
            leftover >>= _LOG2_BITSHIFT_16;
            intResult += _LOG2_BITSHIFT_16;
        }

        if (leftover >= _LOG2_THRESHOLD_08) {
            leftover >>= _LOG2_BITSHIFT_08;
            intResult += _LOG2_BITSHIFT_08;
        }

        if (leftover >= _LOG2_THRESHOLD_04) {
            leftover >>= _LOG2_BITSHIFT_04;
            intResult += _LOG2_BITSHIFT_04;
        }

        if (leftover >= _LOG2_THRESHOLD_02) {
            leftover >>= _LOG2_BITSHIFT_02;
            intResult += _LOG2_BITSHIFT_02;
        }

        if (leftover >= _LOG2_THRESHOLD_01) {
            intResult += _LOG2_BITSHIFT_01;
        }

        uint256 result =
            (intResult - _LOG2_OUT_FRACTION_BITS) << _LOG2_OUT_FRACTION_BITS;
        uint256 scalex =
            self <<
                (_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS - 1).sub(
                    intResult
                );
        for (uint256 mask = _LOG2_FRACTION_MASK; mask > 0; mask >>= 1) {
            scalex *= scalex;
            uint256 bit =
                scalex >>
                    ((_LOG2_OUT_INTEGER_BITS + _LOG2_OUT_FRACTION_BITS) *
                        2 -
                        1);
            scalex >>=
                _LOG2_OUT_INTEGER_BITS +
                _LOG2_OUT_FRACTION_BITS -
                1 +
                bit;
            result += mask * bit;
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using IterableLoanMap for IterableLoanMap.RateToLoanMap;
 *
 *     // Declare a set state variable
 *     IterableLoanMap.RateToLoanMap private myMap;
 * }
 * ```
 *
 * Only maps of type `uint256 -> Loan` (`RateToLoanMap`) are
 * supported.
 */
library IterableLoanMap {
    struct Loan {
        uint256 _principalOnly;
        uint256 _principalWithInterest;
        uint256 _lastAccrualTimestamp;
    }

    struct LoanMapEntry {
        uint256 _key;
        Loan _value;
    }

    struct RateToLoanMap {
        // Storage of map keys and values
        LoanMapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        RateToLoanMap storage self,
        uint256 key,
        Loan memory value
    ) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = self._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            self._entries.push(LoanMapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            self._indexes[key] = self._entries.length;
            return true;
        } else {
            self._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(RateToLoanMap storage self, uint256 key)
        internal
        returns (bool)
    {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = self._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = self._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            LoanMapEntry storage lastEntry = self._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            self._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            self._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            self._entries.pop();

            // Delete the index for the deleted slot
            delete self._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function contains(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(RateToLoanMap storage self)
        internal
        view
        returns (uint256)
    {
        return self._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(RateToLoanMap storage self, uint256 index)
        internal
        view
        returns (uint256, Loan memory)
    {
        require(
            self._entries.length > index,
            "IterableLoanMap: index out of bounds"
        );

        LoanMapEntry storage entry = self._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to return the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (bool, Loan memory)
    {
        uint256 keyIndex = self._indexes[key];
        if (keyIndex == 0)
            return (
                false,
                Loan({
                    _principalOnly: 0,
                    _principalWithInterest: 0,
                    _lastAccrualTimestamp: 0
                })
            ); // Equivalent to contains(map, key)
        return (true, self._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function get(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (Loan memory)
    {
        uint256 keyIndex = self._indexes[key];
        require(keyIndex != 0, "IterableLoanMap: nonexistent key"); // Equivalent to contains(map, key)
        return self._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IAdapter {
    /*
     * @return The wrapped token price in underlying (18 decimal places).
     */
    function getWrappedTokenPriceInUnderlying() external view returns (uint256);

    function getTotalRedeemableUnderlyingTokens()
        external
        view
        returns (uint256);

    function getRedeemableUnderlyingTokensFor(uint256 amount)
        external
        view
        returns (uint256);

    function depositUnderlyingToken(uint256 amount) external returns (uint256);

    function redeemWrappedToken(uint256 maxAmount)
        external
        returns (uint256 actualAmount, uint256 quantity);

    event DepositUnderlyingToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 underlyingAssetAmount,
        uint256 wrappedTokenQuantity,
        address operator,
        uint256 timestamp
    );

    event RedeemWrappedToken(
        address indexed underlyingAssetAddress,
        address indexed wrappedTokenAddress,
        uint256 maxWrappedTokenAmount,
        uint256 actualWrappedTokenAmount,
        uint256 underlyingAssetQuantity,
        address operator,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBtoken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IFarmingPool {
    function addLiquidity(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function liquidate(address account) external;

    function computeBorrowerInterestEarning()
        external
        returns (uint256 borrowerInterestEarning);

    function estimateBorrowerInterestEarning()
        external
        view
        returns (uint256 borrowerInterestEarning);

    function getTotalTransferToAdapterFor(address account)
        external
        view
        returns (uint256 totalTransferToAdapter);

    function getLoansAtLastAccrualFor(address account)
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function getPoolLoansAtLastAccrual()
        external
        view
        returns (
            uint256[] memory interestRates,
            uint256[] memory principalsOnly,
            uint256[] memory principalsWithInterest,
            uint256[] memory lastAccrualTimestamps
        );

    function needToLiquidate(address account, uint256 liquidationThreshold)
        external
        view
        returns (
            bool isLiquidate,
            uint256 accountRedeemableUnderlyingTokens,
            uint256 threshold
        );

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 amount,
        uint256 receiveQuantity,
        uint256 timestamp
    );

    event RemoveLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event LiquidateFarmer(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed farmerAccount,
        uint256 requestedAmount,
        uint256 actualAmount,
        uint256 adapterTransfer,
        uint256 loanPrincipalToRepay,
        uint256 payableInterest,
        uint256 taxAmount,
        uint256 liquidationPenalty,
        uint256 receiveQuantity,
        uint256 outstandingInterest,
        uint256 timestamp
    );

    event ComputeBorrowerInterestEarning(
        uint256 borrowerInterestEarning,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ITreasuryPool {
    function estimateLtokensFor(uint256 amount) external view returns (uint256);

    function estimateUnderlyingAssetsFor(uint256 amount)
        external
        view
        returns (uint256);

    function getTotalUnderlyingAssetAvailable() external view returns (uint256);

    function getUtilisationRate() external view returns (uint256);

    function addLiquidity(uint256 amount) external;

    function loan(uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function redeemProviderReward(uint256 fromEpoch, uint256 toEpoch) external;

    function redeemTeamReward(uint256 fromEpoch, uint256 toEpoch) external;

    function repay(uint256 principal, uint256 interest) external;

    event AddLiquidity(
        address indexed account,
        address indexed underlyingAssetAddress,
        address indexed ltokenAddress,
        uint256 underlyingAssetToken,
        uint256 ltokenAmount,
        uint256 timestamp
    );

    event Loan(uint256 amount, address operator, uint256 timestamp);

    event RemoveLiquidity(
        address indexed account,
        address indexed ltokenAddress,
        address indexed underlyingAssetAddress,
        uint256 ltokenToken,
        uint256 underlyingAssetAmount,
        uint256 timestamp
    );

    event RedeemProviderReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event RedeemTeamReward(
        address indexed account,
        uint256 indexed fromEpoch,
        uint256 indexed toEpoch,
        address rewardTokenAddress,
        uint256 amount,
        uint256 timestamp
    );

    event Repay(
        uint256 principal,
        uint256 interest,
        address operator,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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