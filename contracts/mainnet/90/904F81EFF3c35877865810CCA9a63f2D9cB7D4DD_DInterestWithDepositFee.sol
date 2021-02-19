pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./libs/DecMath.sol";
import "./moneymarkets/IMoneyMarket.sol";
import "./models/fee/IFeeModel.sol";
import "./models/interest/IInterestModel.sol";
import "./NFT.sol";
import "./rewards/MPHMinter.sol";
import "./models/interest-oracle/IInterestOracle.sol";

// DeLorean Interest -- It's coming back from the future!
// EL PSY CONGROO
// Author: Zefram Lou
// Contact: [email protected]
contract DInterest is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    // Constants
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant ONE = 10**18;
    uint256 internal constant EXTRA_PRECISION = 10**27; // used for sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex

    // User deposit data
    // Each deposit has an ID used in the depositNFT, which is equal to its index in `deposits` plus 1
    struct Deposit {
        uint256 amount; // Amount of stablecoin deposited
        uint256 maturationTimestamp; // Unix timestamp after which the deposit may be withdrawn, in seconds
        uint256 interestOwed; // Deficit incurred to the pool at time of deposit
        uint256 initialMoneyMarketIncomeIndex; // Money market's income index at time of deposit
        bool active; // True if not yet withdrawn, false if withdrawn
        bool finalSurplusIsNegative;
        uint256 finalSurplusAmount; // Surplus remaining after withdrawal
        uint256 mintMPHAmount; // Amount of MPH minted to user
        uint256 depositTimestamp; // Unix timestamp at time of deposit, in seconds
    }
    Deposit[] internal deposits;
    uint256 public latestFundedDepositID; // the ID of the most recently created deposit that was funded
    uint256 public unfundedUserDepositAmount; // the deposited stablecoin amount (plus interest owed) whose deficit hasn't been funded

    // Funding data
    // Each funding has an ID used in the fundingNFT, which is equal to its index in `fundingList` plus 1
    struct Funding {
        // deposits with fromDepositID < ID <= toDepositID are funded
        uint256 fromDepositID;
        uint256 toDepositID;
        uint256 recordedFundedDepositAmount; // the current stablecoin amount earning interest for the funder
        uint256 recordedMoneyMarketIncomeIndex; // the income index at the last update (creation or withdrawal)
        uint256 creationTimestamp; // Unix timestamp at time of deposit, in seconds
    }
    Funding[] internal fundingList;
    // the sum of (recordedFundedDepositAmount / recordedMoneyMarketIncomeIndex) of all fundings
    uint256
        public sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex;

    // Params
    uint256 public MinDepositPeriod; // Minimum deposit period, in seconds
    uint256 public MaxDepositPeriod; // Maximum deposit period, in seconds
    uint256 public MinDepositAmount; // Minimum deposit amount for each deposit, in stablecoins
    uint256 public MaxDepositAmount; // Maximum deposit amount for each deposit, in stablecoins

    // Instance variables
    uint256 public totalDeposit;
    uint256 public totalInterestOwed;

    // External smart contracts
    IMoneyMarket public moneyMarket;
    ERC20 public stablecoin;
    IFeeModel public feeModel;
    IInterestModel public interestModel;
    IInterestOracle public interestOracle;
    NFT public depositNFT;
    NFT public fundingNFT;
    MPHMinter public mphMinter;

    // Events
    event EDeposit(
        address indexed sender,
        uint256 indexed depositID,
        uint256 amount,
        uint256 maturationTimestamp,
        uint256 interestAmount,
        uint256 mintMPHAmount
    );
    event EWithdraw(
        address indexed sender,
        uint256 indexed depositID,
        uint256 indexed fundingID,
        bool early,
        uint256 takeBackMPHAmount
    );
    event EFund(
        address indexed sender,
        uint256 indexed fundingID,
        uint256 deficitAmount
    );
    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event ESetParamUint(
        address indexed sender,
        string indexed paramName,
        uint256 newValue
    );

    struct DepositLimit {
        uint256 MinDepositPeriod;
        uint256 MaxDepositPeriod;
        uint256 MinDepositAmount;
        uint256 MaxDepositAmount;
    }

    constructor(
        DepositLimit memory _depositLimit,
        address _moneyMarket, // Address of IMoneyMarket that's used for generating interest (owner must be set to this DInterest contract)
        address _stablecoin, // Address of the stablecoin used to store funds
        address _feeModel, // Address of the FeeModel contract that determines how fees are charged
        address _interestModel, // Address of the InterestModel contract that determines how much interest to offer
        address _interestOracle, // Address of the InterestOracle contract that provides the average interest rate
        address _depositNFT, // Address of the NFT representing ownership of deposits (owner must be set to this DInterest contract)
        address _fundingNFT, // Address of the NFT representing ownership of fundings (owner must be set to this DInterest contract)
        address _mphMinter // Address of the contract for handling minting MPH to users
    ) public {
        // Verify input addresses
        require(
            _moneyMarket.isContract() &&
                _stablecoin.isContract() &&
                _feeModel.isContract() &&
                _interestModel.isContract() &&
                _interestOracle.isContract() &&
                _depositNFT.isContract() &&
                _fundingNFT.isContract() &&
                _mphMinter.isContract(),
            "DInterest: An input address is not a contract"
        );

        moneyMarket = IMoneyMarket(_moneyMarket);
        stablecoin = ERC20(_stablecoin);
        feeModel = IFeeModel(_feeModel);
        interestModel = IInterestModel(_interestModel);
        interestOracle = IInterestOracle(_interestOracle);
        depositNFT = NFT(_depositNFT);
        fundingNFT = NFT(_fundingNFT);
        mphMinter = MPHMinter(_mphMinter);

        // Ensure moneyMarket uses the same stablecoin
        require(
            moneyMarket.stablecoin() == _stablecoin,
            "DInterest: moneyMarket.stablecoin() != _stablecoin"
        );

        // Ensure interestOracle uses the same moneyMarket
        require(
            interestOracle.moneyMarket() == _moneyMarket,
            "DInterest: interestOracle.moneyMarket() != _moneyMarket"
        );

        // Verify input uint256 parameters
        require(
            _depositLimit.MaxDepositPeriod > 0 &&
                _depositLimit.MaxDepositAmount > 0,
            "DInterest: An input uint256 is 0"
        );
        require(
            _depositLimit.MinDepositPeriod <= _depositLimit.MaxDepositPeriod,
            "DInterest: Invalid DepositPeriod range"
        );
        require(
            _depositLimit.MinDepositAmount <= _depositLimit.MaxDepositAmount,
            "DInterest: Invalid DepositAmount range"
        );

        MinDepositPeriod = _depositLimit.MinDepositPeriod;
        MaxDepositPeriod = _depositLimit.MaxDepositPeriod;
        MinDepositAmount = _depositLimit.MinDepositAmount;
        MaxDepositAmount = _depositLimit.MaxDepositAmount;
        totalDeposit = 0;
    }

    /**
        Public actions
     */

    function deposit(uint256 amount, uint256 maturationTimestamp)
        external
        nonReentrant
    {
        _deposit(amount, maturationTimestamp);
    }

    function withdraw(uint256 depositID, uint256 fundingID)
        external
        nonReentrant
    {
        _withdraw(depositID, fundingID, false);
    }

    function earlyWithdraw(uint256 depositID, uint256 fundingID)
        external
        nonReentrant
    {
        _withdraw(depositID, fundingID, true);
    }

    function multiDeposit(
        uint256[] calldata amountList,
        uint256[] calldata maturationTimestampList
    ) external nonReentrant {
        require(
            amountList.length == maturationTimestampList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < amountList.length; i = i.add(1)) {
            _deposit(amountList[i], maturationTimestampList[i]);
        }
    }

    function multiWithdraw(
        uint256[] calldata depositIDList,
        uint256[] calldata fundingIDList
    ) external nonReentrant {
        require(
            depositIDList.length == fundingIDList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _withdraw(depositIDList[i], fundingIDList[i], false);
        }
    }

    function multiEarlyWithdraw(
        uint256[] calldata depositIDList,
        uint256[] calldata fundingIDList
    ) external nonReentrant {
        require(
            depositIDList.length == fundingIDList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _withdraw(depositIDList[i], fundingIDList[i], true);
        }
    }

    /**
        Deficit funding
     */

    function fundAll() external nonReentrant {
        // Calculate current deficit
        (bool isNegative, uint256 deficit) = surplus();
        require(isNegative, "DInterest: No deficit available");
        require(
            !depositIsFunded(deposits.length),
            "DInterest: All deposits funded"
        );

        // Create funding struct
        uint256 incomeIndex = moneyMarket.incomeIndex();
        require(incomeIndex > 0, "DInterest: incomeIndex == 0");
        fundingList.push(
            Funding({
                fromDepositID: latestFundedDepositID,
                toDepositID: deposits.length,
                recordedFundedDepositAmount: unfundedUserDepositAmount,
                recordedMoneyMarketIncomeIndex: incomeIndex,
                creationTimestamp: now
            })
        );

        // Update relevant values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            unfundedUserDepositAmount.mul(EXTRA_PRECISION).div(incomeIndex)
        );
        latestFundedDepositID = deposits.length;
        unfundedUserDepositAmount = 0;

        _fund(deficit);
    }

    function fundMultiple(uint256 toDepositID) external nonReentrant {
        require(
            toDepositID > latestFundedDepositID,
            "DInterest: Deposits already funded"
        );
        require(
            toDepositID <= deposits.length,
            "DInterest: Invalid toDepositID"
        );

        (bool isNegative, uint256 surplus) = surplus();
        require(isNegative, "DInterest: No deficit available");

        uint256 totalDeficit = 0;
        uint256 totalSurplus = 0;
        uint256 totalDepositAndInterestToFund = 0;
        // Deposits with ID [latestFundedDepositID+1, toDepositID] will be funded
        for (
            uint256 id = latestFundedDepositID.add(1);
            id <= toDepositID;
            id = id.add(1)
        ) {
            Deposit storage depositEntry = _getDeposit(id);
            if (depositEntry.active) {
                // Deposit still active, use current surplus
                (isNegative, surplus) = surplusOfDeposit(id);
            } else {
                // Deposit has been withdrawn, use recorded final surplus
                (isNegative, surplus) = (
                    depositEntry.finalSurplusIsNegative,
                    depositEntry.finalSurplusAmount
                );
            }

            if (isNegative) {
                // Add on deficit to total
                totalDeficit = totalDeficit.add(surplus);
            } else {
                // Has surplus
                totalSurplus = totalSurplus.add(surplus);
            }

            if (depositEntry.active) {
                totalDepositAndInterestToFund = totalDepositAndInterestToFund
                    .add(depositEntry.amount)
                    .add(depositEntry.interestOwed);
            }
        }
        if (totalSurplus >= totalDeficit) {
            // Deposits selected have a surplus as a whole, revert
            revert("DInterest: Selected deposits in surplus");
        } else {
            // Deduct surplus from totalDeficit
            totalDeficit = totalDeficit.sub(totalSurplus);
        }

        // Create funding struct
        uint256 incomeIndex = moneyMarket.incomeIndex();
        require(incomeIndex > 0, "DInterest: incomeIndex == 0");
        fundingList.push(
            Funding({
                fromDepositID: latestFundedDepositID,
                toDepositID: toDepositID,
                recordedFundedDepositAmount: totalDepositAndInterestToFund,
                recordedMoneyMarketIncomeIndex: incomeIndex,
                creationTimestamp: now
            })
        );

        // Update relevant values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            totalDepositAndInterestToFund.mul(EXTRA_PRECISION).div(incomeIndex)
        );
        latestFundedDepositID = toDepositID;
        unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
            totalDepositAndInterestToFund
        );

        _fund(totalDeficit);
    }

    function payInterestToFunder(uint256 fundingID)
        external
        returns (uint256 interestAmount)
    {
        address funder = fundingNFT.ownerOf(fundingID);
        require(funder == msg.sender, "DInterest: not funder");
        Funding storage f = _getFunding(fundingID);
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        interestAmount = f
            .recordedFundedDepositAmount
            .mul(currentMoneyMarketIncomeIndex)
            .div(f.recordedMoneyMarketIncomeIndex)
            .sub(f.recordedFundedDepositAmount);

        // Update funding values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .sub(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );
        f.recordedMoneyMarketIncomeIndex = currentMoneyMarketIncomeIndex;
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );

        // Send interest to funder
        if (interestAmount > 0) {
            interestAmount = moneyMarket.withdraw(interestAmount);
            if (interestAmount > 0) {
                stablecoin.safeTransfer(funder, interestAmount);
            }
        }
    }

    /**
        Public getters
     */

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds
    ) public returns (uint256 interestAmount) {
        (, uint256 moneyMarketInterestRatePerSecond) =
            interestOracle.updateAndQuery();
        (bool surplusIsNegative, uint256 surplusAmount) = surplus();

        return
            interestModel.calculateInterestAmount(
                depositAmount,
                depositPeriodInSeconds,
                moneyMarketInterestRatePerSecond,
                surplusIsNegative,
                surplusAmount
            );
    }

    /**
        @notice Computes the floating interest amount owed to deficit funders, which will be paid out
                when a funded deposit is withdrawn.
                Formula: \sum_i recordedFundedDepositAmount_i * (incomeIndex / recordedMoneyMarketIncomeIndex_i - 1)
                = incomeIndex * (\sum_i recordedFundedDepositAmount_i / recordedMoneyMarketIncomeIndex_i)
                - (totalDeposit + totalInterestOwed - unfundedUserDepositAmount)
                where i refers to a funding
     */
    function totalInterestOwedToFunders()
        public
        returns (uint256 interestOwed)
    {
        uint256 currentValue =
            moneyMarket
                .incomeIndex()
                .mul(
                sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            )
                .div(EXTRA_PRECISION);
        uint256 initialValue =
            totalDeposit.add(totalInterestOwed).sub(unfundedUserDepositAmount);
        if (currentValue < initialValue) {
            return 0;
        }
        return currentValue.sub(initialValue);
    }

    function surplus() public returns (bool isNegative, uint256 surplusAmount) {
        uint256 totalValue = moneyMarket.totalValue();
        uint256 totalOwed =
            totalDeposit.add(totalInterestOwed).add(
                totalInterestOwedToFunders()
            );
        if (totalValue >= totalOwed) {
            // Locked value more than owed deposits, positive surplus
            isNegative = false;
            surplusAmount = totalValue.sub(totalOwed);
        } else {
            // Locked value less than owed deposits, negative surplus
            isNegative = true;
            surplusAmount = totalOwed.sub(totalValue);
        }
    }

    function surplusOfDeposit(uint256 depositID)
        public
        returns (bool isNegative, uint256 surplusAmount)
    {
        Deposit storage depositEntry = _getDeposit(depositID);
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        uint256 currentDepositValue =
            depositEntry.amount.mul(currentMoneyMarketIncomeIndex).div(
                depositEntry.initialMoneyMarketIncomeIndex
            );
        uint256 owed = depositEntry.amount.add(depositEntry.interestOwed);
        if (currentDepositValue >= owed) {
            // Locked value more than owed deposits, positive surplus
            isNegative = false;
            surplusAmount = currentDepositValue.sub(owed);
        } else {
            // Locked value less than owed deposits, negative surplus
            isNegative = true;
            surplusAmount = owed.sub(currentDepositValue);
        }
    }

    function depositIsFunded(uint256 id) public view returns (bool) {
        return (id <= latestFundedDepositID);
    }

    function depositsLength() external view returns (uint256) {
        return deposits.length;
    }

    function fundingListLength() external view returns (uint256) {
        return fundingList.length;
    }

    function getDeposit(uint256 depositID)
        external
        view
        returns (Deposit memory)
    {
        return deposits[depositID.sub(1)];
    }

    function getFunding(uint256 fundingID)
        external
        view
        returns (Funding memory)
    {
        return fundingList[fundingID.sub(1)];
    }

    function moneyMarketIncomeIndex() external returns (uint256) {
        return moneyMarket.incomeIndex();
    }

    /**
        Param setters
     */
    function setFeeModel(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        feeModel = IFeeModel(newValue);
        emit ESetParamAddress(msg.sender, "feeModel", newValue);
    }

    function setInterestModel(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        interestModel = IInterestModel(newValue);
        emit ESetParamAddress(msg.sender, "interestModel", newValue);
    }

    function setInterestOracle(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        interestOracle = IInterestOracle(newValue);
        require(
            interestOracle.moneyMarket() == address(moneyMarket),
            "DInterest: moneyMarket mismatch"
        );
        emit ESetParamAddress(msg.sender, "interestOracle", newValue);
    }

    function setRewards(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        moneyMarket.setRewards(newValue);
        emit ESetParamAddress(msg.sender, "moneyMarket.rewards", newValue);
    }

    function setMPHMinter(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        mphMinter = MPHMinter(newValue);
        emit ESetParamAddress(msg.sender, "mphMinter", newValue);
    }

    function setMinDepositPeriod(uint256 newValue) external onlyOwner {
        require(newValue <= MaxDepositPeriod, "DInterest: invalid value");
        MinDepositPeriod = newValue;
        emit ESetParamUint(msg.sender, "MinDepositPeriod", newValue);
    }

    function setMaxDepositPeriod(uint256 newValue) external onlyOwner {
        require(
            newValue >= MinDepositPeriod && newValue > 0,
            "DInterest: invalid value"
        );
        MaxDepositPeriod = newValue;
        emit ESetParamUint(msg.sender, "MaxDepositPeriod", newValue);
    }

    function setMinDepositAmount(uint256 newValue) external onlyOwner {
        require(
            newValue <= MaxDepositAmount && newValue > 0,
            "DInterest: invalid value"
        );
        MinDepositAmount = newValue;
        emit ESetParamUint(msg.sender, "MinDepositAmount", newValue);
    }

    function setMaxDepositAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= MinDepositAmount && newValue > 0,
            "DInterest: invalid value"
        );
        MaxDepositAmount = newValue;
        emit ESetParamUint(msg.sender, "MaxDepositAmount", newValue);
    }

    function setDepositNFTTokenURI(uint256 tokenId, string calldata newURI)
        external
        onlyOwner
    {
        depositNFT.setTokenURI(tokenId, newURI);
    }

    function setDepositNFTBaseURI(string calldata newURI) external onlyOwner {
        depositNFT.setBaseURI(newURI);
    }

    function setDepositNFTContractURI(string calldata newURI)
        external
        onlyOwner
    {
        depositNFT.setContractURI(newURI);
    }

    function setFundingNFTTokenURI(uint256 tokenId, string calldata newURI)
        external
        onlyOwner
    {
        fundingNFT.setTokenURI(tokenId, newURI);
    }

    function setFundingNFTBaseURI(string calldata newURI) external onlyOwner {
        fundingNFT.setBaseURI(newURI);
    }

    function setFundingNFTContractURI(string calldata newURI)
        external
        onlyOwner
    {
        fundingNFT.setContractURI(newURI);
    }

    /**
        Internal getters
     */

    function _getDeposit(uint256 depositID)
        internal
        view
        returns (Deposit storage)
    {
        return deposits[depositID.sub(1)];
    }

    function _getFunding(uint256 fundingID)
        internal
        view
        returns (Funding storage)
    {
        return fundingList[fundingID.sub(1)];
    }

    /**
        Internals
     */

    function _deposit(uint256 amount, uint256 maturationTimestamp) internal {
        // Ensure deposit amount is not more than maximum
        require(
            amount >= MinDepositAmount && amount <= MaxDepositAmount,
            "DInterest: Deposit amount out of range"
        );

        // Ensure deposit period is at least MinDepositPeriod
        uint256 depositPeriod = maturationTimestamp.sub(now);
        require(
            depositPeriod >= MinDepositPeriod &&
                depositPeriod <= MaxDepositPeriod,
            "DInterest: Deposit period out of range"
        );

        // Update totalDeposit
        totalDeposit = totalDeposit.add(amount);

        // Calculate interest
        uint256 interestAmount = calculateInterestAmount(amount, depositPeriod);
        require(interestAmount > 0, "DInterest: interestAmount == 0");

        // Update funding related data
        uint256 id = deposits.length.add(1);
        unfundedUserDepositAmount = unfundedUserDepositAmount.add(amount).add(
            interestAmount
        );

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.add(interestAmount);

        // Mint MPH for msg.sender
        uint256 mintMPHAmount =
            mphMinter.mintDepositorReward(
                msg.sender,
                amount,
                depositPeriod,
                interestAmount
            );

        // Record deposit data for `msg.sender`
        deposits.push(
            Deposit({
                amount: amount,
                maturationTimestamp: maturationTimestamp,
                interestOwed: interestAmount,
                initialMoneyMarketIncomeIndex: moneyMarket.incomeIndex(),
                active: true,
                finalSurplusIsNegative: false,
                finalSurplusAmount: 0,
                mintMPHAmount: mintMPHAmount,
                depositTimestamp: now
            })
        );

        // Transfer `amount` stablecoin to DInterest
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Lend `amount` stablecoin to money market
        stablecoin.safeIncreaseAllowance(address(moneyMarket), amount);
        moneyMarket.deposit(amount);

        // Mint depositNFT
        depositNFT.mint(msg.sender, id);

        // Emit event
        emit EDeposit(
            msg.sender,
            id,
            amount,
            maturationTimestamp,
            interestAmount,
            mintMPHAmount
        );
    }

    function _withdraw(
        uint256 depositID,
        uint256 fundingID,
        bool early
    ) internal {
        Deposit storage depositEntry = _getDeposit(depositID);

        // Verify deposit is active and set to inactive
        require(depositEntry.active, "DInterest: Deposit not active");
        depositEntry.active = false;

        if (early) {
            // Verify `now < depositEntry.maturationTimestamp`
            require(
                now < depositEntry.maturationTimestamp,
                "DInterest: Deposit mature, use withdraw() instead"
            );
            // Verify `now > depositEntry.depositTimestamp`
            require(
                now > depositEntry.depositTimestamp,
                "DInterest: Deposited in same block"
            );
        } else {
            // Verify `now >= depositEntry.maturationTimestamp`
            require(
                now >= depositEntry.maturationTimestamp,
                "DInterest: Deposit not mature"
            );
        }

        // Verify msg.sender owns the depositNFT
        require(
            depositNFT.ownerOf(depositID) == msg.sender,
            "DInterest: Sender doesn't own depositNFT"
        );

        // Restrict scope to prevent stack too deep error
        {
            // Take back MPH
            uint256 takeBackMPHAmount =
                mphMinter.takeBackDepositorReward(
                    msg.sender,
                    depositEntry.mintMPHAmount,
                    early
                );

            // Emit event
            emit EWithdraw(
                msg.sender,
                depositID,
                fundingID,
                early,
                takeBackMPHAmount
            );
        }

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.sub(depositEntry.interestOwed);

        // Fetch the income index & surplus before withdrawal, to prevent our withdrawal from
        // increasing the income index when the money market vault total supply is extremely small
        // (vault as in yEarn & Harvest vaults)
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        require(
            currentMoneyMarketIncomeIndex > 0,
            "DInterest: currentMoneyMarketIncomeIndex == 0"
        );
        (bool depositSurplusIsNegative, uint256 depositSurplus) =
            surplusOfDeposit(depositID);

        // Restrict scope to prevent stack too deep error
        {
            uint256 feeAmount;
            uint256 withdrawAmount;
            if (early) {
                // Withdraw the principal of the deposit from money market
                withdrawAmount = depositEntry.amount;
            } else {
                // Withdraw the principal & the interest from money market
                feeAmount = feeModel.getFee(depositEntry.interestOwed);
                withdrawAmount = depositEntry.amount.add(
                    depositEntry.interestOwed
                );
            }
            withdrawAmount = moneyMarket.withdraw(withdrawAmount);

            // Send `withdrawAmount - feeAmount` stablecoin to `msg.sender`
            stablecoin.safeTransfer(msg.sender, withdrawAmount.sub(feeAmount));

            // Send `feeAmount` stablecoin to feeModel beneficiary
            if (feeAmount > 0) {
                stablecoin.safeTransfer(feeModel.beneficiary(), feeAmount);
            }
        }

        // If deposit was funded, payout interest to funder
        if (depositIsFunded(depositID)) {
            _payInterestToFunder(
                fundingID,
                depositID,
                depositEntry.amount,
                depositEntry.maturationTimestamp,
                depositEntry.interestOwed,
                depositSurplusIsNegative,
                depositSurplus,
                currentMoneyMarketIncomeIndex,
                early
            );
        } else {
            // Remove deposit from future deficit fundings
            unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
                depositEntry.amount.add(depositEntry.interestOwed)
            );

            // Record remaining surplus
            depositEntry.finalSurplusIsNegative = depositSurplusIsNegative;
            depositEntry.finalSurplusAmount = depositSurplus;
        }
    }

    function _payInterestToFunder(
        uint256 fundingID,
        uint256 depositID,
        uint256 depositAmount,
        uint256 depositMaturationTimestamp,
        uint256 depositInterestOwed,
        bool depositSurplusIsNegative,
        uint256 depositSurplus,
        uint256 currentMoneyMarketIncomeIndex,
        bool early
    ) internal {
        Funding storage f = _getFunding(fundingID);
        require(
            depositID > f.fromDepositID && depositID <= f.toDepositID,
            "DInterest: Deposit not funded by fundingID"
        );
        uint256 interestAmount =
            f
                .recordedFundedDepositAmount
                .mul(currentMoneyMarketIncomeIndex)
                .div(f.recordedMoneyMarketIncomeIndex)
                .sub(f.recordedFundedDepositAmount);

        // Update funding values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .sub(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );
        f.recordedFundedDepositAmount = f.recordedFundedDepositAmount.sub(
            depositAmount.add(depositInterestOwed)
        );
        f.recordedMoneyMarketIncomeIndex = currentMoneyMarketIncomeIndex;
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );

        // Send interest to funder
        address funder = fundingNFT.ownerOf(fundingID);
        uint256 transferToFunderAmount =
            (early && depositSurplusIsNegative)
                ? interestAmount.add(depositSurplus)
                : interestAmount;
        if (transferToFunderAmount > 0) {
            transferToFunderAmount = moneyMarket.withdraw(
                transferToFunderAmount
            );
            if (transferToFunderAmount > 0) {
                stablecoin.safeTransfer(funder, transferToFunderAmount);
            }
        }

        // Mint funder rewards
        mphMinter.mintFunderReward(
            funder,
            depositAmount,
            f.creationTimestamp,
            depositMaturationTimestamp,
            interestAmount,
            early
        );
    }

    function _fund(uint256 totalDeficit) internal {
        // Transfer `totalDeficit` stablecoins from msg.sender
        stablecoin.safeTransferFrom(msg.sender, address(this), totalDeficit);

        // Deposit `totalDeficit` stablecoins into moneyMarket
        stablecoin.safeIncreaseAllowance(address(moneyMarket), totalDeficit);
        moneyMarket.deposit(totalDeficit);

        // Mint fundingNFT
        fundingNFT.mint(msg.sender, fundingList.length);

        // Emit event
        uint256 fundingID = fundingList.length;
        emit EFund(msg.sender, fundingID, totalDeficit);
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";

// Decimal math library
library DecMath {
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    function decmul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISION);
    }

    function decdiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISION).div(b);
    }
}

pragma solidity 0.5.17;

// Interface for money market protocols (Compound, Aave, bZx, etc.)
interface IMoneyMarket {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amountInUnderlying)
        external
        returns (uint256 actualAmountWithdrawn);

    function claimRewards() external; // Claims farmed tokens (e.g. COMP, CRV) and sends it to the rewards pool

    function totalValue() external returns (uint256); // The total value locked in the money market, in terms of the underlying stablecoin

    function incomeIndex() external returns (uint256); // Used for calculating the interest generated (e.g. cDai's price for the Compound market)

    function stablecoin() external view returns (address);

    function setRewards(address newValue) external;

    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
}

pragma solidity 0.5.17;

interface IFeeModel {
    function beneficiary() external view returns (address payable);

    function getFee(uint256 _txAmount)
        external
        pure
        returns (uint256 _feeAmount);
}

pragma solidity 0.5.17;

interface IInterestModel {
    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool surplusIsNegative,
        uint256 surplusAmount
    ) external view returns (uint256 interestAmount);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract NFT is ERC721Metadata("", ""), Ownable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    string internal _contractURI;
    string internal _tokenName;
    string internal _tokenSymbol;

    function init(
        address newOwner,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external {
        _transferOwnership(newOwner);
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);

        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _tokenSymbol;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setContractURI(string calldata newURI) external onlyOwner {
        _contractURI = newURI;
    }

    function setTokenURI(uint256 tokenId, string calldata newURI)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, newURI);
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _setBaseURI(newURI);
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "../../introspection/ERC165.sol";

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    *
    * _Available since v2.5.0._
    */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../drafts/Counters.sol";
import "../../introspection/ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

pragma solidity ^0.5.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

pragma solidity ^0.5.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

pragma solidity ^0.5.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.5.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./MPHToken.sol";
import "../models/issuance/IMPHIssuanceModel.sol";
import "./Vesting.sol";

contract MPHMinter is Ownable {
    using Address for address;
    using SafeMath for uint256;

    mapping(address => bool) public poolWhitelist;

    modifier onlyWhitelistedPool {
        require(poolWhitelist[msg.sender], "MPHMinter: sender not whitelisted");
        _;
    }

    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event WhitelistPool(
        address indexed sender,
        address pool,
        bool isWhitelisted
    );
    event MintDepositorReward(
        address indexed sender,
        address indexed to,
        uint256 depositorReward
    );
    event TakeBackDepositorReward(
        address indexed sender,
        address indexed from,
        uint256 takeBackAmount
    );
    event MintFunderReward(
        address indexed sender,
        address indexed to,
        uint256 funderReward
    );

    /**
        External contracts
     */
    MPHToken public mph;
    address public govTreasury;
    address public devWallet;
    IMPHIssuanceModel public issuanceModel;
    Vesting public vesting;

    constructor(
        address _mph,
        address _govTreasury,
        address _devWallet,
        address _issuanceModel,
        address _vesting
    ) public {
        mph = MPHToken(_mph);
        govTreasury = _govTreasury;
        devWallet = _devWallet;
        issuanceModel = IMPHIssuanceModel(_issuanceModel);
        vesting = Vesting(_vesting);
    }

    /**
        @notice Mints the MPH reward to a depositor upon deposit.
        @param  to The depositor
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  depositPeriodInSeconds The deposit's lock period in seconds
        @param  interestAmount The deposit's fixed-rate interest amount in the pool's stablecoins
        @return depositorReward The MPH amount to mint to the depositor
     */
    function mintDepositorReward(
        address to,
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 interestAmount
    ) external onlyWhitelistedPool returns (uint256) {
        if (mph.owner() != address(this)) {
            // not the owner of the MPH token, cannot mint
            emit MintDepositorReward(msg.sender, to, 0);
            return 0;
        }
    
        (
            uint256 depositorReward,
            uint256 devReward,
            uint256 govReward
        ) = issuanceModel.computeDepositorReward(
            msg.sender,
            depositAmount,
            depositPeriodInSeconds,
            interestAmount
        );
        if (depositorReward == 0 && devReward == 0 && govReward == 0) {
            return 0;
        }

        // mint and vest depositor reward
        mph.ownerMint(address(this), depositorReward);
        uint256 vestPeriodInSeconds = issuanceModel
            .poolDepositorRewardVestPeriod(msg.sender);
        if (vestPeriodInSeconds == 0) {
            // no vesting, transfer to `to`
            mph.transfer(to, depositorReward);
        } else {
            // vest the MPH to `to`
            mph.increaseAllowance(address(vesting), depositorReward);
            vesting.vest(to, depositorReward, vestPeriodInSeconds);
        }

        mph.ownerMint(devWallet, devReward);
        mph.ownerMint(govTreasury, govReward);

        emit MintDepositorReward(msg.sender, to, depositorReward);

        return depositorReward;
    }

    /**
        @notice Takes back MPH from depositor upon withdrawal.
                If takeBackAmount > devReward + govReward, the extra MPH should be burnt.
        @param  from The depositor
        @param  mintMPHAmount The MPH amount originally minted to the depositor as reward
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return takeBackAmount The MPH amount to take back from the depositor
     */
    function takeBackDepositorReward(
        address from,
        uint256 mintMPHAmount,
        bool early
    ) external onlyWhitelistedPool returns (uint256) {
        (
            uint256 takeBackAmount,
            uint256 devReward,
            uint256 govReward
        ) = issuanceModel.computeTakeBackDepositorRewardAmount(
            msg.sender,
            mintMPHAmount,
            early
        );
        if (takeBackAmount == 0 && devReward == 0 && govReward == 0) {
            return 0;
        }
        require(
            takeBackAmount >= devReward.add(govReward),
            "MPHMinter: takeBackAmount < devReward + govReward"
        );
        mph.transferFrom(from, address(this), takeBackAmount);
        mph.transfer(devWallet, devReward);
        mph.transfer(govTreasury, govReward);
        mph.burn(takeBackAmount.sub(devReward).sub(govReward));

        emit TakeBackDepositorReward(msg.sender, from, takeBackAmount);

        return takeBackAmount;
    }

    /**
        @notice Mints the MPH reward to a deficit funder upon withdrawal of an underlying deposit.
        @param  to The funder
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  fundingCreationTimestamp The timestamp of the funding's creation, in seconds
        @param  maturationTimestamp The maturation timestamp of the deposit, in seconds
        @param  interestPayoutAmount The interest payout amount to the funder, in the pool's stablecoins.
                                     Includes the interest from other funded deposits.
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return funderReward The MPH amount to mint to the funder
     */
    function mintFunderReward(
        address to,
        uint256 depositAmount,
        uint256 fundingCreationTimestamp,
        uint256 maturationTimestamp,
        uint256 interestPayoutAmount,
        bool early
    ) external onlyWhitelistedPool returns (uint256) {
        if (mph.owner() != address(this)) {
            // not the owner of the MPH token, cannot mint
            emit MintDepositorReward(msg.sender, to, 0);
            return 0;
        }

        (
            uint256 funderReward,
            uint256 devReward,
            uint256 govReward
        ) = issuanceModel.computeFunderReward(
            msg.sender,
            depositAmount,
            fundingCreationTimestamp,
            maturationTimestamp,
            interestPayoutAmount,
            early
        );
        if (funderReward == 0 && devReward == 0 && govReward == 0) {
            return 0;
        }

        // mint and vest funder reward
        mph.ownerMint(address(this), funderReward);
        uint256 vestPeriodInSeconds = issuanceModel.poolFunderRewardVestPeriod(
            msg.sender
        );
        if (vestPeriodInSeconds == 0) {
            // no vesting, transfer to `to`
            mph.transfer(to, funderReward);
        } else {
            // vest the MPH to `to`
            mph.increaseAllowance(address(vesting), funderReward);
            vesting.vest(to, funderReward, vestPeriodInSeconds);
        }
        mph.ownerMint(devWallet, devReward);
        mph.ownerMint(govTreasury, govReward);

        emit MintFunderReward(msg.sender, to, funderReward);

        return funderReward;
    }

    /**
        Param setters
     */
    function setGovTreasury(address newValue) external onlyOwner {
        require(newValue != address(0), "MPHMinter: 0 address");
        govTreasury = newValue;
        emit ESetParamAddress(msg.sender, "govTreasury", newValue);
    }

    function setDevWallet(address newValue) external onlyOwner {
        require(newValue != address(0), "MPHMinter: 0 address");
        devWallet = newValue;
        emit ESetParamAddress(msg.sender, "devWallet", newValue);
    }

    function setMPHTokenOwner(address newValue) external onlyOwner {
        require(newValue != address(0), "MPHMinter: 0 address");
        mph.transferOwnership(newValue);
        emit ESetParamAddress(msg.sender, "mphTokenOwner", newValue);
    }

    function setMPHTokenOwnerToZero() external onlyOwner {
        mph.renounceOwnership();
        emit ESetParamAddress(msg.sender, "mphTokenOwner", address(0));
    }

    function setIssuanceModel(address newValue) external onlyOwner {
        require(newValue.isContract(), "MPHMinter: not contract");
        issuanceModel = IMPHIssuanceModel(newValue);
        emit ESetParamAddress(msg.sender, "issuanceModel", newValue);
    }

    function setVesting(address newValue) external onlyOwner {
        require(newValue.isContract(), "MPHMinter: not contract");
        vesting = Vesting(newValue);
        emit ESetParamAddress(msg.sender, "vesting", newValue);
    }

    function setPoolWhitelist(address pool, bool isWhitelisted)
        external
        onlyOwner
    {
        require(pool.isContract(), "MPHMinter: pool not contract");
        poolWhitelist[pool] = isWhitelisted;
        emit WhitelistPool(msg.sender, pool, isWhitelisted);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract MPHToken is ERC20, ERC20Burnable, Ownable {
    string public constant name = "88mph.app";
    string public constant symbol = "MPH";
    uint8 public constant decimals = 18;
    
    bool public initialized;

    function init() public {
        require(!initialized, "MPHToken: initialized");
        initialized = true;

        _transferOwnership(msg.sender);
    }

    function ownerMint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity 0.5.17;

interface IMPHIssuanceModel {
    /**
        @notice Computes the MPH amount to reward to a depositor upon deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  depositPeriodInSeconds The deposit's lock period in seconds
        @param  interestAmount The deposit's fixed-rate interest amount in the pool's stablecoins
        @return depositorReward The MPH amount to mint to the depositor
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeDepositorReward(
        address pool,
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 interestAmount
    )
        external
        view
        returns (
            uint256 depositorReward,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice Computes the MPH amount to take back from a depositor upon withdrawal.
                If takeBackAmount > devReward + govReward, the extra MPH should be burnt.
        @param  pool The DInterest pool trying to mint reward
        @param  mintMPHAmount The MPH amount originally minted to the depositor as reward
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return takeBackAmount The MPH amount to take back from the depositor
                devReward The MPH amount from takeBackAmount to send to the dev wallet
                govReward The MPH amount from takeBackAmount to send to the gov treasury
     */
    function computeTakeBackDepositorRewardAmount(
        address pool,
        uint256 mintMPHAmount,
        bool early
    )
        external
        view
        returns (
            uint256 takeBackAmount,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice Computes the MPH amount to reward to a deficit funder upon withdrawal of an underlying deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  fundingCreationTimestamp The timestamp of the funding's creation, in seconds
        @param  maturationTimestamp The maturation timestamp of the deposit, in seconds
        @param  interestPayoutAmount The interest payout amount to the funder, in the pool's stablecoins.
                                     Includes the interest from other funded deposits.
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return funderReward The MPH amount to mint to the funder
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeFunderReward(
        address pool,
        uint256 depositAmount,
        uint256 fundingCreationTimestamp,
        uint256 maturationTimestamp,
        uint256 interestPayoutAmount,
        bool early
    )
        external
        view
        returns (
            uint256 funderReward,
            uint256 devReward,
            uint256 govReward
        );

    /**
        @notice The period over which the depositor reward will be vested, in seconds.
     */
    function poolDepositorRewardVestPeriod(address pool)
        external
        view
        returns (uint256 vestPeriodInSeconds);

    /**
        @notice The period over which the funder reward will be vested, in seconds.
     */
    function poolFunderRewardVestPeriod(address pool)
        external
        view
        returns (uint256 vestPeriodInSeconds);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Vesting {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Vest {
        uint256 amount;
        uint256 vestPeriodInSeconds;
        uint256 creationTimestamp;
        uint256 withdrawnAmount;
    }
    mapping(address => Vest[]) public accountVestList;

    IERC20 public token;

    constructor(address _token) public {
        token = IERC20(_token);
    }

    function vest(
        address to,
        uint256 amount,
        uint256 vestPeriodInSeconds
    ) external returns (uint256 vestIdx) {
        require(vestPeriodInSeconds > 0, "Vesting: vestPeriodInSeconds == 0");

        // transfer `amount` tokens from `msg.sender`
        token.safeTransferFrom(msg.sender, address(this), amount);

        // create vest object
        vestIdx = accountVestList[to].length;
        accountVestList[to].push(
            Vest({
                amount: amount,
                vestPeriodInSeconds: vestPeriodInSeconds,
                creationTimestamp: now,
                withdrawnAmount: 0
            })
        );
    }

    function withdrawVested(address account, uint256 vestIdx)
        external
        returns (uint256 withdrawnAmount)
    {
        // compute withdrawable amount
        withdrawnAmount = _getVestWithdrawableAmount(account, vestIdx);
        if (withdrawnAmount == 0) {
            return 0;
        }

        // update vest object
        uint256 recordedWithdrawnAmount = accountVestList[account][vestIdx]
            .withdrawnAmount;
        accountVestList[account][vestIdx]
            .withdrawnAmount = recordedWithdrawnAmount.add(withdrawnAmount);

        // transfer tokens to vest recipient
        token.safeTransfer(account, withdrawnAmount);
    }

    function getVestWithdrawableAmount(address account, uint256 vestIdx)
        external
        view
        returns (uint256)
    {
        return _getVestWithdrawableAmount(account, vestIdx);
    }

    function _getVestWithdrawableAmount(address account, uint256 vestIdx)
        internal
        view
        returns (uint256)
    {
        // read vest data
        Vest storage vest = accountVestList[account][vestIdx];
        uint256 vestFullAmount = vest.amount;
        uint256 vestCreationTimestamp = vest.creationTimestamp;
        uint256 vestPeriodInSeconds = vest.vestPeriodInSeconds;

        // compute vested amount
        uint256 vestedAmount;
        if (now >= vestCreationTimestamp.add(vestPeriodInSeconds)) {
            // vest period has passed, fully withdrawable
            vestedAmount = vestFullAmount;
        } else {
            // vest period has not passed, linearly unlock
            vestedAmount = vestFullAmount
                .mul(now.sub(vestCreationTimestamp))
                .div(vestPeriodInSeconds);
        }

        // deduct already withdrawn amount and return
        return vestedAmount.sub(vest.withdrawnAmount);
    }
}

pragma solidity 0.5.17;

interface IInterestOracle {
    function updateAndQuery() external returns (bool updated, uint256 value);

    function query() external view returns (uint256 value);

    function moneyMarket() external view returns (address);
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./libs/DecMath.sol";
import "./moneymarkets/IMoneyMarket.sol";
import "./models/fee/IFeeModel.sol";
import "./models/interest/IInterestModel.sol";
import "./NFT.sol";
import "./rewards/MPHMinter.sol";
import "./models/interest-oracle/IInterestOracle.sol";

// DeLorean Interest -- It's coming back from the future!
// EL PSY CONGROO
// Author: Zefram Lou
// Contact: [email protected]bs.dev
contract DInterestWithDepositFee is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    // Constants
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant ONE = 10**18;
    uint256 internal constant EXTRA_PRECISION = 10**27; // used for sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex

    // User deposit data
    // Each deposit has an ID used in the depositNFT, which is equal to its index in `deposits` plus 1
    struct Deposit {
        uint256 amount; // Amount of stablecoin deposited
        uint256 maturationTimestamp; // Unix timestamp after which the deposit may be withdrawn, in seconds
        uint256 interestOwed; // Deficit incurred to the pool at time of deposit
        uint256 initialMoneyMarketIncomeIndex; // Money market's income index at time of deposit
        bool active; // True if not yet withdrawn, false if withdrawn
        bool finalSurplusIsNegative;
        uint256 finalSurplusAmount; // Surplus remaining after withdrawal
        uint256 mintMPHAmount; // Amount of MPH minted to user
        uint256 depositTimestamp; // Unix timestamp at time of deposit, in seconds
    }
    Deposit[] internal deposits;
    uint256 public latestFundedDepositID; // the ID of the most recently created deposit that was funded
    uint256 public unfundedUserDepositAmount; // the deposited stablecoin amount (plus interest owed) whose deficit hasn't been funded

    // Funding data
    // Each funding has an ID used in the fundingNFT, which is equal to its index in `fundingList` plus 1
    struct Funding {
        // deposits with fromDepositID < ID <= toDepositID are funded
        uint256 fromDepositID;
        uint256 toDepositID;
        uint256 recordedFundedDepositAmount; // the current stablecoin amount earning interest for the funder
        uint256 recordedMoneyMarketIncomeIndex; // the income index at the last update (creation or withdrawal)
        uint256 creationTimestamp; // Unix timestamp at time of deposit, in seconds
    }
    Funding[] internal fundingList;
    // the sum of (recordedFundedDepositAmount / recordedMoneyMarketIncomeIndex) of all fundings
    uint256
        public sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex;

    // Params
    uint256 public MinDepositPeriod; // Minimum deposit period, in seconds
    uint256 public MaxDepositPeriod; // Maximum deposit period, in seconds
    uint256 public MinDepositAmount; // Minimum deposit amount for each deposit, in stablecoins
    uint256 public MaxDepositAmount; // Maximum deposit amount for each deposit, in stablecoins
    uint256 public DepositFee; // The deposit fee charged by the money market

    // Instance variables
    uint256 public totalDeposit;
    uint256 public totalInterestOwed;

    // External smart contracts
    IMoneyMarket public moneyMarket;
    ERC20 public stablecoin;
    IFeeModel public feeModel;
    IInterestModel public interestModel;
    IInterestOracle public interestOracle;
    NFT public depositNFT;
    NFT public fundingNFT;
    MPHMinter public mphMinter;

    // Events
    event EDeposit(
        address indexed sender,
        uint256 indexed depositID,
        uint256 amount,
        uint256 maturationTimestamp,
        uint256 interestAmount,
        uint256 mintMPHAmount
    );
    event EWithdraw(
        address indexed sender,
        uint256 indexed depositID,
        uint256 indexed fundingID,
        bool early,
        uint256 takeBackMPHAmount
    );
    event EFund(
        address indexed sender,
        uint256 indexed fundingID,
        uint256 deficitAmount
    );
    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event ESetParamUint(
        address indexed sender,
        string indexed paramName,
        uint256 newValue
    );

    struct DepositLimit {
        uint256 MinDepositPeriod;
        uint256 MaxDepositPeriod;
        uint256 MinDepositAmount;
        uint256 MaxDepositAmount;
        uint256 DepositFee;
    }

    constructor(
        DepositLimit memory _depositLimit,
        address _moneyMarket, // Address of IMoneyMarket that's used for generating interest (owner must be set to this DInterest contract)
        address _stablecoin, // Address of the stablecoin used to store funds
        address _feeModel, // Address of the FeeModel contract that determines how fees are charged
        address _interestModel, // Address of the InterestModel contract that determines how much interest to offer
        address _interestOracle, // Address of the InterestOracle contract that provides the average interest rate
        address _depositNFT, // Address of the NFT representing ownership of deposits (owner must be set to this DInterest contract)
        address _fundingNFT, // Address of the NFT representing ownership of fundings (owner must be set to this DInterest contract)
        address _mphMinter // Address of the contract for handling minting MPH to users
    ) public {
        // Verify input addresses
        require(
            _moneyMarket.isContract() &&
                _stablecoin.isContract() &&
                _feeModel.isContract() &&
                _interestModel.isContract() &&
                _interestOracle.isContract() &&
                _depositNFT.isContract() &&
                _fundingNFT.isContract() &&
                _mphMinter.isContract(),
            "DInterest: An input address is not a contract"
        );

        moneyMarket = IMoneyMarket(_moneyMarket);
        stablecoin = ERC20(_stablecoin);
        feeModel = IFeeModel(_feeModel);
        interestModel = IInterestModel(_interestModel);
        interestOracle = IInterestOracle(_interestOracle);
        depositNFT = NFT(_depositNFT);
        fundingNFT = NFT(_fundingNFT);
        mphMinter = MPHMinter(_mphMinter);

        // Ensure moneyMarket uses the same stablecoin
        require(
            moneyMarket.stablecoin() == _stablecoin,
            "DInterest: moneyMarket.stablecoin() != _stablecoin"
        );

        // Ensure interestOracle uses the same moneyMarket
        require(
            interestOracle.moneyMarket() == _moneyMarket,
            "DInterest: interestOracle.moneyMarket() != _moneyMarket"
        );

        // Verify input uint256 parameters
        require(
            _depositLimit.MaxDepositPeriod > 0 &&
                _depositLimit.MaxDepositAmount > 0,
            "DInterest: An input uint256 is 0"
        );
        require(
            _depositLimit.MinDepositPeriod <= _depositLimit.MaxDepositPeriod,
            "DInterest: Invalid DepositPeriod range"
        );
        require(
            _depositLimit.MinDepositAmount <= _depositLimit.MaxDepositAmount,
            "DInterest: Invalid DepositAmount range"
        );

        MinDepositPeriod = _depositLimit.MinDepositPeriod;
        MaxDepositPeriod = _depositLimit.MaxDepositPeriod;
        MinDepositAmount = _depositLimit.MinDepositAmount;
        MaxDepositAmount = _depositLimit.MaxDepositAmount;
        DepositFee = _depositLimit.DepositFee;
        totalDeposit = 0;
    }

    /**
        Public actions
     */

    function deposit(uint256 amount, uint256 maturationTimestamp)
        external
        nonReentrant
    {
        _deposit(amount, maturationTimestamp);
    }

    function withdraw(uint256 depositID, uint256 fundingID)
        external
        nonReentrant
    {
        _withdraw(depositID, fundingID, false);
    }

    function earlyWithdraw(uint256 depositID, uint256 fundingID)
        external
        nonReentrant
    {
        _withdraw(depositID, fundingID, true);
    }

    function multiDeposit(
        uint256[] calldata amountList,
        uint256[] calldata maturationTimestampList
    ) external nonReentrant {
        require(
            amountList.length == maturationTimestampList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < amountList.length; i = i.add(1)) {
            _deposit(amountList[i], maturationTimestampList[i]);
        }
    }

    function multiWithdraw(
        uint256[] calldata depositIDList,
        uint256[] calldata fundingIDList
    ) external nonReentrant {
        require(
            depositIDList.length == fundingIDList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _withdraw(depositIDList[i], fundingIDList[i], false);
        }
    }

    function multiEarlyWithdraw(
        uint256[] calldata depositIDList,
        uint256[] calldata fundingIDList
    ) external nonReentrant {
        require(
            depositIDList.length == fundingIDList.length,
            "DInterest: List lengths unequal"
        );
        for (uint256 i = 0; i < depositIDList.length; i = i.add(1)) {
            _withdraw(depositIDList[i], fundingIDList[i], true);
        }
    }

    /**
        Deficit funding
     */

    function fundAll() external nonReentrant {
        // Calculate current deficit
        (bool isNegative, uint256 deficit) = surplus();
        require(isNegative, "DInterest: No deficit available");
        require(
            !depositIsFunded(deposits.length),
            "DInterest: All deposits funded"
        );

        // Create funding struct
        uint256 incomeIndex = moneyMarket.incomeIndex();
        require(incomeIndex > 0, "DInterest: incomeIndex == 0");
        fundingList.push(
            Funding({
                fromDepositID: latestFundedDepositID,
                toDepositID: deposits.length,
                recordedFundedDepositAmount: unfundedUserDepositAmount,
                recordedMoneyMarketIncomeIndex: incomeIndex,
                creationTimestamp: now
            })
        );

        // Update relevant values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            unfundedUserDepositAmount.mul(EXTRA_PRECISION).div(incomeIndex)
        );
        latestFundedDepositID = deposits.length;
        unfundedUserDepositAmount = 0;

        _fund(deficit);
    }

    function fundMultiple(uint256 toDepositID) external nonReentrant {
        require(
            toDepositID > latestFundedDepositID,
            "DInterest: Deposits already funded"
        );
        require(
            toDepositID <= deposits.length,
            "DInterest: Invalid toDepositID"
        );

        (bool isNegative, uint256 surplus) = surplus();
        require(isNegative, "DInterest: No deficit available");

        uint256 totalDeficit = 0;
        uint256 totalSurplus = 0;
        uint256 totalDepositAndInterestToFund = 0;
        // Deposits with ID [latestFundedDepositID+1, toDepositID] will be funded
        for (
            uint256 id = latestFundedDepositID.add(1);
            id <= toDepositID;
            id = id.add(1)
        ) {
            Deposit storage depositEntry = _getDeposit(id);
            if (depositEntry.active) {
                // Deposit still active, use current surplus
                (isNegative, surplus) = surplusOfDeposit(id);
            } else {
                // Deposit has been withdrawn, use recorded final surplus
                (isNegative, surplus) = (
                    depositEntry.finalSurplusIsNegative,
                    depositEntry.finalSurplusAmount
                );
            }

            if (isNegative) {
                // Add on deficit to total
                totalDeficit = totalDeficit.add(surplus);
            } else {
                // Has surplus
                totalSurplus = totalSurplus.add(surplus);
            }

            if (depositEntry.active) {
                totalDepositAndInterestToFund = totalDepositAndInterestToFund
                    .add(depositEntry.amount)
                    .add(depositEntry.interestOwed);
            }
        }
        if (totalSurplus >= totalDeficit) {
            // Deposits selected have a surplus as a whole, revert
            revert("DInterest: Selected deposits in surplus");
        } else {
            // Deduct surplus from totalDeficit
            totalDeficit = totalDeficit.sub(totalSurplus);
        }

        // Create funding struct
        uint256 incomeIndex = moneyMarket.incomeIndex();
        require(incomeIndex > 0, "DInterest: incomeIndex == 0");
        fundingList.push(
            Funding({
                fromDepositID: latestFundedDepositID,
                toDepositID: toDepositID,
                recordedFundedDepositAmount: totalDepositAndInterestToFund,
                recordedMoneyMarketIncomeIndex: incomeIndex,
                creationTimestamp: now
            })
        );

        // Update relevant values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            totalDepositAndInterestToFund.mul(EXTRA_PRECISION).div(incomeIndex)
        );
        latestFundedDepositID = toDepositID;
        unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
            totalDepositAndInterestToFund
        );

        _fund(totalDeficit);
    }

    function payInterestToFunder(uint256 fundingID)
        external
        returns (uint256 interestAmount)
    {
        address funder = fundingNFT.ownerOf(fundingID);
        require(funder == msg.sender, "DInterest: not funder");
        Funding storage f = _getFunding(fundingID);
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        interestAmount = f
            .recordedFundedDepositAmount
            .mul(currentMoneyMarketIncomeIndex)
            .div(f.recordedMoneyMarketIncomeIndex)
            .sub(f.recordedFundedDepositAmount);

        // Update funding values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .sub(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );
        f.recordedMoneyMarketIncomeIndex = currentMoneyMarketIncomeIndex;
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );

        // Send interest to funder
        if (interestAmount > 0) {
            interestAmount = moneyMarket.withdraw(interestAmount);
            if (interestAmount > 0) {
                stablecoin.safeTransfer(funder, interestAmount);
            }
        }
    }

    /**
        Public getters
     */

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds
    ) public returns (uint256 interestAmount) {
        (, uint256 moneyMarketInterestRatePerSecond) =
            interestOracle.updateAndQuery();
        (bool surplusIsNegative, uint256 surplusAmount) = surplus();

        return
            interestModel.calculateInterestAmount(
                depositAmount,
                depositPeriodInSeconds,
                moneyMarketInterestRatePerSecond,
                surplusIsNegative,
                surplusAmount
            );
    }

    /**
        @notice Computes the floating interest amount owed to deficit funders, which will be paid out
                when a funded deposit is withdrawn.
                Formula: \sum_i recordedFundedDepositAmount_i * (incomeIndex / recordedMoneyMarketIncomeIndex_i - 1)
                = incomeIndex * (\sum_i recordedFundedDepositAmount_i / recordedMoneyMarketIncomeIndex_i)
                - (totalDeposit + totalInterestOwed - unfundedUserDepositAmount)
                where i refers to a funding
     */
    function totalInterestOwedToFunders()
        public
        returns (uint256 interestOwed)
    {
        uint256 currentValue =
            moneyMarket
                .incomeIndex()
                .mul(
                sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            )
                .div(EXTRA_PRECISION);
        uint256 initialValue =
            totalDeposit.add(totalInterestOwed).sub(unfundedUserDepositAmount);
        if (currentValue < initialValue) {
            return 0;
        }
        return currentValue.sub(initialValue);
    }

    function surplus() public returns (bool isNegative, uint256 surplusAmount) {
        uint256 totalValue = moneyMarket.totalValue();
        uint256 totalOwed =
            totalDeposit.add(totalInterestOwed).add(
                totalInterestOwedToFunders()
            );
        if (totalValue >= totalOwed) {
            // Locked value more than owed deposits, positive surplus
            isNegative = false;
            surplusAmount = totalValue.sub(totalOwed);
        } else {
            // Locked value less than owed deposits, negative surplus
            isNegative = true;
            surplusAmount = totalOwed.sub(totalValue);
        }
    }

    function surplusOfDeposit(uint256 depositID)
        public
        returns (bool isNegative, uint256 surplusAmount)
    {
        Deposit storage depositEntry = _getDeposit(depositID);
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        uint256 currentDepositValue =
            depositEntry.amount.mul(currentMoneyMarketIncomeIndex).div(
                depositEntry.initialMoneyMarketIncomeIndex
            );
        uint256 owed = depositEntry.amount.add(depositEntry.interestOwed);
        if (currentDepositValue >= owed) {
            // Locked value more than owed deposits, positive surplus
            isNegative = false;
            surplusAmount = currentDepositValue.sub(owed);
        } else {
            // Locked value less than owed deposits, negative surplus
            isNegative = true;
            surplusAmount = owed.sub(currentDepositValue);
        }
    }

    function depositIsFunded(uint256 id) public view returns (bool) {
        return (id <= latestFundedDepositID);
    }

    function depositsLength() external view returns (uint256) {
        return deposits.length;
    }

    function fundingListLength() external view returns (uint256) {
        return fundingList.length;
    }

    function getDeposit(uint256 depositID)
        external
        view
        returns (Deposit memory)
    {
        return deposits[depositID.sub(1)];
    }

    function getFunding(uint256 fundingID)
        external
        view
        returns (Funding memory)
    {
        return fundingList[fundingID.sub(1)];
    }

    function moneyMarketIncomeIndex() external returns (uint256) {
        return moneyMarket.incomeIndex();
    }

    /**
        Param setters
     */
    function setFeeModel(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        feeModel = IFeeModel(newValue);
        emit ESetParamAddress(msg.sender, "feeModel", newValue);
    }

    function setInterestModel(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        interestModel = IInterestModel(newValue);
        emit ESetParamAddress(msg.sender, "interestModel", newValue);
    }

    function setInterestOracle(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        interestOracle = IInterestOracle(newValue);
        require(
            interestOracle.moneyMarket() == address(moneyMarket),
            "DInterest: moneyMarket mismatch"
        );
        emit ESetParamAddress(msg.sender, "interestOracle", newValue);
    }

    function setRewards(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        moneyMarket.setRewards(newValue);
        emit ESetParamAddress(msg.sender, "moneyMarket.rewards", newValue);
    }

    function setMPHMinter(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        mphMinter = MPHMinter(newValue);
        emit ESetParamAddress(msg.sender, "mphMinter", newValue);
    }

    function setMinDepositPeriod(uint256 newValue) external onlyOwner {
        require(newValue <= MaxDepositPeriod, "DInterest: invalid value");
        MinDepositPeriod = newValue;
        emit ESetParamUint(msg.sender, "MinDepositPeriod", newValue);
    }

    function setMaxDepositPeriod(uint256 newValue) external onlyOwner {
        require(
            newValue >= MinDepositPeriod && newValue > 0,
            "DInterest: invalid value"
        );
        MaxDepositPeriod = newValue;
        emit ESetParamUint(msg.sender, "MaxDepositPeriod", newValue);
    }

    function setMinDepositAmount(uint256 newValue) external onlyOwner {
        require(
            newValue <= MaxDepositAmount && newValue > 0,
            "DInterest: invalid value"
        );
        MinDepositAmount = newValue;
        emit ESetParamUint(msg.sender, "MinDepositAmount", newValue);
    }

    function setMaxDepositAmount(uint256 newValue) external onlyOwner {
        require(
            newValue >= MinDepositAmount && newValue > 0,
            "DInterest: invalid value"
        );
        MaxDepositAmount = newValue;
        emit ESetParamUint(msg.sender, "MaxDepositAmount", newValue);
    }

    function setDepositFee(uint256 newValue) external onlyOwner {
        require(
            newValue < PRECISION,
            "DInterest: invalid value"
        );
        DepositFee = newValue;
        emit ESetParamUint(msg.sender, "DepositFee", newValue);
    }

    function setDepositNFTTokenURI(uint256 tokenId, string calldata newURI)
        external
        onlyOwner
    {
        depositNFT.setTokenURI(tokenId, newURI);
    }

    function setDepositNFTBaseURI(string calldata newURI) external onlyOwner {
        depositNFT.setBaseURI(newURI);
    }

    function setDepositNFTContractURI(string calldata newURI)
        external
        onlyOwner
    {
        depositNFT.setContractURI(newURI);
    }

    function setFundingNFTTokenURI(uint256 tokenId, string calldata newURI)
        external
        onlyOwner
    {
        fundingNFT.setTokenURI(tokenId, newURI);
    }

    function setFundingNFTBaseURI(string calldata newURI) external onlyOwner {
        fundingNFT.setBaseURI(newURI);
    }

    function setFundingNFTContractURI(string calldata newURI)
        external
        onlyOwner
    {
        fundingNFT.setContractURI(newURI);
    }

    /**
        Internal getters
     */

    function _getDeposit(uint256 depositID)
        internal
        view
        returns (Deposit storage)
    {
        return deposits[depositID.sub(1)];
    }

    function _getFunding(uint256 fundingID)
        internal
        view
        returns (Funding storage)
    {
        return fundingList[fundingID.sub(1)];
    }

    function _applyDepositFee(uint256 depositAmount)
        internal
        view
        returns (uint256)
    {
        return depositAmount.decmul(PRECISION.sub(DepositFee));
    }

    function _unapplyDepositFee(uint256 depositAmount)
        internal
        view
        returns (uint256)
    {
        return depositAmount.decdiv(PRECISION.sub(DepositFee));
    }

    /**
        Internals
     */

    function _deposit(uint256 amount, uint256 maturationTimestamp) internal {
        // Ensure deposit amount is not more than maximum
        require(
            amount >= MinDepositAmount && amount <= MaxDepositAmount,
            "DInterest: Deposit amount out of range"
        );

        // Ensure deposit period is at least MinDepositPeriod
        uint256 depositPeriod = maturationTimestamp.sub(now);
        require(
            depositPeriod >= MinDepositPeriod &&
                depositPeriod <= MaxDepositPeriod,
            "DInterest: Deposit period out of range"
        );

        // Apply fee to deposit amount
        uint256 amountAfterFee = _applyDepositFee(amount);

        // Update totalDeposit
        totalDeposit = totalDeposit.add(amountAfterFee);

        // Calculate interest
        uint256 interestAmount = calculateInterestAmount(amountAfterFee, depositPeriod);
        require(interestAmount > 0, "DInterest: interestAmount == 0");

        // Update funding related data
        uint256 id = deposits.length.add(1);
        unfundedUserDepositAmount = unfundedUserDepositAmount.add(amountAfterFee).add(
            interestAmount
        );

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.add(interestAmount);

        // Mint MPH for msg.sender
        uint256 mintMPHAmount =
            mphMinter.mintDepositorReward(
                msg.sender,
                amountAfterFee,
                depositPeriod,
                interestAmount
            );

        // Record deposit data for `msg.sender`
        deposits.push(
            Deposit({
                amount: amountAfterFee,
                maturationTimestamp: maturationTimestamp,
                interestOwed: interestAmount,
                initialMoneyMarketIncomeIndex: moneyMarket.incomeIndex(),
                active: true,
                finalSurplusIsNegative: false,
                finalSurplusAmount: 0,
                mintMPHAmount: mintMPHAmount,
                depositTimestamp: now
            })
        );

        // Transfer `amount` stablecoin to DInterest
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Lend `amount` stablecoin to money market
        stablecoin.safeIncreaseAllowance(address(moneyMarket), amount);
        moneyMarket.deposit(amount);

        // Mint depositNFT
        depositNFT.mint(msg.sender, id);

        // Emit event
        emit EDeposit(
            msg.sender,
            id,
            amountAfterFee,
            maturationTimestamp,
            interestAmount,
            mintMPHAmount
        );
    }

    function _withdraw(
        uint256 depositID,
        uint256 fundingID,
        bool early
    ) internal {
        Deposit storage depositEntry = _getDeposit(depositID);

        // Verify deposit is active and set to inactive
        require(depositEntry.active, "DInterest: Deposit not active");
        depositEntry.active = false;

        if (early) {
            // Verify `now < depositEntry.maturationTimestamp`
            require(
                now < depositEntry.maturationTimestamp,
                "DInterest: Deposit mature, use withdraw() instead"
            );
            // Verify `now > depositEntry.depositTimestamp`
            require(
                now > depositEntry.depositTimestamp,
                "DInterest: Deposited in same block"
            );
        } else {
            // Verify `now >= depositEntry.maturationTimestamp`
            require(
                now >= depositEntry.maturationTimestamp,
                "DInterest: Deposit not mature"
            );
        }

        // Verify msg.sender owns the depositNFT
        require(
            depositNFT.ownerOf(depositID) == msg.sender,
            "DInterest: Sender doesn't own depositNFT"
        );

        // Restrict scope to prevent stack too deep error
        {
            // Take back MPH
            uint256 takeBackMPHAmount =
                mphMinter.takeBackDepositorReward(
                    msg.sender,
                    depositEntry.mintMPHAmount,
                    early
                );

            // Emit event
            emit EWithdraw(
                msg.sender,
                depositID,
                fundingID,
                early,
                takeBackMPHAmount
            );
        }

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.sub(depositEntry.interestOwed);

        // Fetch the income index & surplus before withdrawal, to prevent our withdrawal from
        // increasing the income index when the money market vault total supply is extremely small
        // (vault as in yEarn & Harvest vaults)
        uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
        require(
            currentMoneyMarketIncomeIndex > 0,
            "DInterest: currentMoneyMarketIncomeIndex == 0"
        );
        (bool depositSurplusIsNegative, uint256 depositSurplus) =
            surplusOfDeposit(depositID);

        // Restrict scope to prevent stack too deep error
        {
            uint256 feeAmount;
            uint256 withdrawAmount;
            if (early) {
                // Withdraw the principal of the deposit from money market
                withdrawAmount = depositEntry.amount;
            } else {
                // Withdraw the principal & the interest from money market
                feeAmount = feeModel.getFee(depositEntry.interestOwed);
                withdrawAmount = depositEntry.amount.add(
                    depositEntry.interestOwed
                );
            }
            withdrawAmount = moneyMarket.withdraw(withdrawAmount);

            // Send `withdrawAmount - feeAmount` stablecoin to `msg.sender`
            stablecoin.safeTransfer(msg.sender, withdrawAmount.sub(feeAmount));

            // Send `feeAmount` stablecoin to feeModel beneficiary
            if (feeAmount > 0) {
                stablecoin.safeTransfer(feeModel.beneficiary(), feeAmount);
            }
        }

        // If deposit was funded, payout interest to funder
        if (depositIsFunded(depositID)) {
            _payInterestToFunder(
                fundingID,
                depositID,
                depositEntry.amount,
                depositEntry.maturationTimestamp,
                depositEntry.interestOwed,
                depositSurplusIsNegative,
                depositSurplus,
                currentMoneyMarketIncomeIndex,
                early
            );
        } else {
            // Remove deposit from future deficit fundings
            unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
                depositEntry.amount.add(depositEntry.interestOwed)
            );

            // Record remaining surplus
            depositEntry.finalSurplusIsNegative = depositSurplusIsNegative;
            depositEntry.finalSurplusAmount = depositSurplus;
        }
    }

    function _payInterestToFunder(
        uint256 fundingID,
        uint256 depositID,
        uint256 depositAmount,
        uint256 depositMaturationTimestamp,
        uint256 depositInterestOwed,
        bool depositSurplusIsNegative,
        uint256 depositSurplus,
        uint256 currentMoneyMarketIncomeIndex,
        bool early
    ) internal {
        Funding storage f = _getFunding(fundingID);
        require(
            depositID > f.fromDepositID && depositID <= f.toDepositID,
            "DInterest: Deposit not funded by fundingID"
        );
        uint256 interestAmount =
            f
                .recordedFundedDepositAmount
                .mul(currentMoneyMarketIncomeIndex)
                .div(f.recordedMoneyMarketIncomeIndex)
                .sub(f.recordedFundedDepositAmount);

        // Update funding values
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .sub(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );
        f.recordedFundedDepositAmount = f.recordedFundedDepositAmount.sub(
            depositAmount.add(depositInterestOwed)
        );
        f.recordedMoneyMarketIncomeIndex = currentMoneyMarketIncomeIndex;
        sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex = sumOfRecordedFundedDepositAndInterestAmountDivRecordedIncomeIndex
            .add(
            f.recordedFundedDepositAmount.mul(EXTRA_PRECISION).div(
                f.recordedMoneyMarketIncomeIndex
            )
        );

        // Send interest to funder
        address funder = fundingNFT.ownerOf(fundingID);
        uint256 transferToFunderAmount =
            (early && depositSurplusIsNegative)
                ? interestAmount.add(depositSurplus)
                : interestAmount;
        if (transferToFunderAmount > 0) {
            transferToFunderAmount = moneyMarket.withdraw(
                transferToFunderAmount
            );
            if (transferToFunderAmount > 0) {
                stablecoin.safeTransfer(funder, transferToFunderAmount);
            }
        }

        // Mint funder rewards
        mphMinter.mintFunderReward(
            funder,
            depositAmount,
            f.creationTimestamp,
            depositMaturationTimestamp,
            interestAmount,
            early
        );
    }

    function _fund(uint256 totalDeficit) internal {
        // Given the deposit fee, the funder needs to pay more than
        // the deficit to cover the deficit
        uint256 deficitWithFee = _unapplyDepositFee(totalDeficit);

        // Transfer `totalDeficit` stablecoins from msg.sender
        stablecoin.safeTransferFrom(msg.sender, address(this), deficitWithFee);

        // Deposit `totalDeficit` stablecoins into moneyMarket
        stablecoin.safeIncreaseAllowance(address(moneyMarket), deficitWithFee);
        moneyMarket.deposit(deficitWithFee);

        // Mint fundingNFT
        fundingNFT.mint(msg.sender, fundingList.length);

        // Emit event
        uint256 fundingID = fundingList.length;
        emit EFund(msg.sender, fundingID, deficitWithFee);
    }
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "../DInterest.sol";
import "../NFT.sol";
import "../rewards/MPHToken.sol";
import "../models/fee/IFeeModel.sol";

contract FractionalDeposit is ERC20, IERC721Receiver, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    bool public initialized;
    DInterest public pool;
    NFT public nft;
    MPHToken public mph;
    uint256 public nftID;
    uint256 public mintMPHAmount;
    bool public active;
    string public name;
    string public symbol;
    uint8 public decimals;

    event WithdrawDeposit();
    event RedeemShares(
        address indexed user,
        uint256 amountInShares,
        uint256 redeemStablecoinAmount
    );

    function init(
        address _owner,
        address _pool,
        address _mph,
        uint256 _nftID,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external {
        require(!initialized, "FractionalDeposit: initialized");
        initialized = true;

        _transferOwnership(_owner);
        pool = DInterest(_pool);
        mph = MPHToken(_mph);
        nft = NFT(pool.depositNFT());
        nftID = _nftID;
        active = true;
        name = _tokenName;
        symbol = _tokenSymbol;

        // ensure contract is owner of NFT
        require(
            nft.ownerOf(_nftID) == address(this),
            "FractionalDeposit: not deposit owner"
        );

        // mint tokens to owner
        DInterest.Deposit memory deposit = pool.getDeposit(_nftID);
        require(deposit.active, "FractionalDeposit: deposit inactive");
        uint256 rawInterestOwed = deposit.interestOwed;
        uint256 interestAfterFee = rawInterestOwed.sub(pool.feeModel().getFee(rawInterestOwed));
        uint256 initialSupply = deposit.amount.add(interestAfterFee);
        _mint(_owner, initialSupply);

        // transfer MPH from msg.sender
        mintMPHAmount = deposit.mintMPHAmount;
        mph.transferFrom(msg.sender, address(this), mintMPHAmount);

        // set decimals to be the same as the underlying stablecoin
        decimals = ERC20Detailed(address(pool.stablecoin())).decimals();
    }

    function withdrawDeposit(uint256 fundingID) external {
        _withdrawDeposit(fundingID);
    }

    function transferNFTToOwner() external {
        require(!active, "FractionalDeposit: deposit active");

        // transfer NFT to owner
        nft.safeTransferFrom(address(this), owner(), nftID);
    }

    function redeemShares(uint256 amountInShares, uint256 fundingID)
        external
        returns (uint256 redeemStablecoinAmount)
    {
        if (active) {
            // if deposit is still active, call withdrawDeposit()
            _withdrawDeposit(fundingID);
        }

        ERC20 stablecoin = pool.stablecoin();
        uint256 stablecoinBalance = stablecoin.balanceOf(address(this));
        redeemStablecoinAmount = amountInShares.mul(stablecoinBalance).div(
            totalSupply()
        );
        if (redeemStablecoinAmount > stablecoinBalance) {
            // prevent transferring too much
            redeemStablecoinAmount = stablecoinBalance;
        }

        // burn shares from sender
        _burn(msg.sender, amountInShares);

        // transfer pro rata withdrawn deposit
        stablecoin.safeTransfer(msg.sender, redeemStablecoinAmount);

        emit RedeemShares(msg.sender, amountInShares, redeemStablecoinAmount);
    }

    function _withdrawDeposit(uint256 fundingID) internal {
        require(active, "FractionalDeposit: deposit inactive");
        active = false;

        uint256 _nftID = nftID;

        // withdraw deposit from DInterest pool
        mph.increaseAllowance(address(pool.mphMinter()), mintMPHAmount);
        pool.withdraw(_nftID, fundingID);

        // return leftover MPH
        uint256 mphBalance = mph.balanceOf(address(this));
        if (mphBalance > 0) {
            mph.transfer(owner(), mphBalance);
        }

        emit WithdrawDeposit();
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        // only allow incoming transfer if not initialized
        require(!initialized, "FractionalDeposit: initialized");
        return this.onERC721Received.selector;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../libs/CloneFactory.sol";
import "./FractionalDeposit.sol";
import "../DInterest.sol";
import "../NFT.sol";
import "../rewards/MPHToken.sol";

contract FractionalDepositFactory is CloneFactory, IERC721Receiver {
    address public template;
    MPHToken public mph;

    event CreateClone(address _clone);

    constructor(address _template, address _mph) public {
        template = _template;
        mph = MPHToken(_mph);
    }

    function createFractionalDeposit(
        address _pool,
        uint256 _nftID,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external returns (FractionalDeposit) {
        FractionalDeposit clone = FractionalDeposit(createClone(template));

        // transfer NFT from msg.sender to clone
        DInterest pool = DInterest(_pool);
        NFT nft = NFT(pool.depositNFT());
        nft.safeTransferFrom(msg.sender, address(this), _nftID);
        nft.safeTransferFrom(address(this), address(clone), _nftID);

        // transfer MPH reward from msg.sender
        DInterest.Deposit memory deposit = pool.getDeposit(_nftID);
        uint256 mintMPHAmount = deposit.mintMPHAmount;
        mph.transferFrom(msg.sender, address(this), mintMPHAmount);
        mph.increaseAllowance(address(clone), mintMPHAmount);

        // initialize
        clone.init(
            msg.sender,
            _pool,
            address(mph),
            _nftID,
            _tokenName,
            _tokenSymbol
        );

        emit CreateClone(address(clone));
        return clone;
    }

    function isFractionalDeposit(address query) external view returns (bool) {
        return isClone(template, query);
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity 0.5.17;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../DInterest.sol";
import "./FractionalDeposit.sol";
import "./FractionalDepositFactory.sol";

// OpenZeppelin contract modified to support cloned contracts
contract ClonedReentrancyGuard {
    bool internal _notEntered;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

contract ZeroCouponBond is ERC20, ClonedReentrancyGuard, IERC721Receiver {
    using SafeERC20 for ERC20;

    bool public initialized;
    DInterest public pool;
    FractionalDepositFactory public fractionalDepositFactory;
    ERC20 public stablecoin;
    uint256 public maturationTimestamp;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Mint(
        address indexed sender,
        address indexed fractionalDepositAddress,
        uint256 amount
    );
    event RedeemFractionalDepositShares(
        address indexed sender,
        address indexed fractionalDepositAddress,
        uint256 fundingID
    );
    event RedeemStablecoin(address indexed sender, uint256 amount);

    function init(
        address _pool,
        address _fractionalDepositFactory,
        uint256 _maturationTimestamp,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external {
        require(!initialized, "ZeroCouponBond: initialized");
        initialized = true;

        _notEntered = true;
        pool = DInterest(_pool);
        fractionalDepositFactory = FractionalDepositFactory(
            _fractionalDepositFactory
        );
        stablecoin = pool.stablecoin();
        maturationTimestamp = _maturationTimestamp;
        name = _tokenName;
        symbol = _tokenSymbol;

        // set decimals to be the same as the underlying stablecoin
        decimals = ERC20Detailed(address(pool.stablecoin())).decimals();

        // infinite approval to fractional deposit factory to save gas during minting with NFT
        pool.depositNFT().setApprovalForAll(_fractionalDepositFactory, true);
        fractionalDepositFactory.mph().approve(
            _fractionalDepositFactory,
            uint256(-1)
        );
    }

    function mintWithDepositNFT(
        uint256 nftID,
        string calldata fractionalDepositName,
        string calldata fractionalDepositSymbol
    )
        external
        nonReentrant
        returns (
            uint256 zeroCouponBondsAmount,
            FractionalDeposit fractionalDeposit
        )
    {
        // ensure the deposit's maturation time is on or before that of the ZCB
        DInterest.Deposit memory depositStruct = pool.getDeposit(nftID);
        uint256 depositMaturationTimestamp = depositStruct.maturationTimestamp;
        require(
            depositMaturationTimestamp <= maturationTimestamp,
            "ZeroCouponBonds: maturation too late"
        );

        // transfer MPH from `msg.sender`
        MPHToken mph = fractionalDepositFactory.mph();
        mph.transferFrom(
            msg.sender,
            address(this),
            depositStruct.mintMPHAmount
        );

        // transfer deposit NFT from `msg.sender`
        NFT depositNFT = pool.depositNFT();
        depositNFT.safeTransferFrom(msg.sender, address(this), nftID);

        // call fractionalDepositFactory to create fractional deposit using NFT
        fractionalDeposit = fractionalDepositFactory.createFractionalDeposit(
            address(pool),
            nftID,
            fractionalDepositName,
            fractionalDepositSymbol
        );
        fractionalDeposit.transferOwnership(msg.sender);

        // mint zero coupon bonds to `msg.sender`
        zeroCouponBondsAmount = fractionalDeposit.totalSupply();
        _mint(msg.sender, zeroCouponBondsAmount);

        emit Mint(
            msg.sender,
            address(fractionalDeposit),
            zeroCouponBondsAmount
        );
    }

    function redeemFractionalDepositShares(
        address fractionalDepositAddress,
        uint256 fundingID
    ) external nonReentrant {
        FractionalDeposit fractionalDeposit =
            FractionalDeposit(fractionalDepositAddress);

        uint256 balance = fractionalDeposit.balanceOf(address(this));
        fractionalDeposit.redeemShares(balance, fundingID);

        emit RedeemFractionalDepositShares(
            msg.sender,
            fractionalDepositAddress,
            fundingID
        );
    }

    function redeemStablecoin(uint256 amount)
        external
        nonReentrant
        returns (uint256 actualRedeemedAmount)
    {
        require(now >= maturationTimestamp, "ZeroCouponBond: not mature");

        uint256 stablecoinBalance = stablecoin.balanceOf(address(this));
        actualRedeemedAmount = amount > stablecoinBalance
            ? stablecoinBalance
            : amount;

        // burn `actualRedeemedAmount` zero coupon bonds from `msg.sender`
        _burn(msg.sender, actualRedeemedAmount);

        // transfer `actualRedeemedAmount` stablecoins to `msg.sender`
        stablecoin.safeTransfer(msg.sender, actualRedeemedAmount);

        emit RedeemStablecoin(msg.sender, actualRedeemedAmount);
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libs/CloneFactory.sol";
import "./ZeroCouponBond.sol";

contract ZeroCouponBondFactory is CloneFactory {
    address public template;
    address public fractionalDepositFactory;

    event CreateClone(address _clone);

    constructor(address _template, address _fractionalDepositFactory) public {
        template = _template;
        fractionalDepositFactory = _fractionalDepositFactory;
    }

    function createZeroCouponBond(
        address _pool,
        uint256 _maturationTimetstamp,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external returns (ZeroCouponBond) {
        ZeroCouponBond clone = ZeroCouponBond(createClone(template));

        // initialize
        clone.init(
            _pool,
            fractionalDepositFactory,
            _maturationTimetstamp,
            _tokenName,
            _tokenSymbol
        );

        emit CreateClone(address(clone));
        return clone;
    }

    function isZeroCouponBond(address query) external view returns (bool) {
        return isClone(template, query);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/DecMath.sol";

contract ATokenMock is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 internal constant YEAR = 31556952; // Number of seconds in one Gregorian calendar year (365.2425 days)

    ERC20 public dai;
    uint256 public liquidityRate;
    uint256 public normalizedIncome;
    address[] public users;
    mapping(address => bool) public isUser;

    constructor(address _dai)
        public
        ERC20Detailed("aDAI", "aDAI", 18)
    {
        dai = ERC20(_dai);

        liquidityRate = 10 ** 26; // 10% APY
        normalizedIncome = 10 ** 27;
    }

    function mint(address _user, uint256 _amount) external {
        _mint(_user, _amount);
        if (!isUser[_user]) {
            users.push(_user);
            isUser[_user] = true;
        }
    }

    function burn(address _user, uint256 _amount) external {
        _burn(_user, _amount);
    }

    function mintInterest(uint256 _seconds) external {
        uint256 interest;
        address user;
        for (uint256 i = 0; i < users.length; i++) {
            user = users[i];
            interest = balanceOf(user).mul(_seconds).mul(liquidityRate).div(YEAR.mul(10**27));
            _mint(user, interest);
        }
        normalizedIncome = normalizedIncome.mul(_seconds).mul(liquidityRate).div(YEAR.mul(10**27)).add(normalizedIncome);
    }

    function setLiquidityRate(uint256 _liquidityRate) external {
        liquidityRate = _liquidityRate;
    }
}

/**
    Modified from https://github.com/bugduino/idle-contracts/blob/master/contracts/mocks/cDAIMock.sol
    at commit b85dafa8e55e053cb2d403fc4b28cfe86f2116d4

    Original license:
    Copyright 2020 Idle Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
 */

pragma solidity 0.5.17;

// interfaces
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract CERC20Mock is ERC20, ERC20Detailed {
    address public dai;

    uint256 internal _supplyRate;
    uint256 internal _exchangeRate;

    constructor(address _dai) public ERC20Detailed("cDAI", "cDAI", 8) {
        dai = _dai;
        uint256 daiDecimals = ERC20Detailed(_dai).decimals();
        _exchangeRate = 2 * (10**(daiDecimals + 8)); // 1 cDAI = 0.02 DAI
        _supplyRate = 45290900000; // 10% supply rate per year
    }

    function mint(uint256 amount) external returns (uint256) {
        require(
            ERC20(dai).transferFrom(msg.sender, address(this), amount),
            "Error during transferFrom"
        ); // 1 DAI
        _mint(msg.sender, (amount * 10**18) / _exchangeRate);
        return 0;
    }

    function redeemUnderlying(uint256 amount) external returns (uint256) {
        _burn(msg.sender, (amount * 10**18) / _exchangeRate);
        require(
            ERC20(dai).transfer(msg.sender, amount),
            "Error during transfer"
        ); // 1 DAI
        return 0;
    }

    function exchangeRateStored() external view returns (uint256) {
        return _exchangeRate;
    }

    function exchangeRateCurrent() external view returns (uint256) {
        return _exchangeRate;
    }

    function _setExchangeRateStored(uint256 _rate) external returns (uint256) {
        _exchangeRate = _rate;
    }

    function supplyRatePerBlock() external view returns (uint256) {
        return _supplyRate;
    }

    function _setSupplyRatePerBlock(uint256 _rate) external {
        _supplyRate = _rate;
    }
}

pragma solidity 0.5.17;

// interfaces
import "./ERC20Mock.sol";

contract ComptrollerMock {
    uint256 public constant CLAIM_AMOUNT = 10**18;
    ERC20Mock public comp;

    constructor (address _comp) public {
        comp = ERC20Mock(_comp);
    }

    function claimComp(address holder) external {
        comp.mint(holder, CLAIM_AMOUNT);
    }

    function getCompAddress() external view returns (address) {
        return address(comp);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract ERC20Mock is ERC20, ERC20Detailed("", "", 6) {
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount > 0, "ERC20Mock: amount 0");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: Rewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract IRewardDistributionRecipient is Ownable {
    mapping(address => bool) public isRewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(
            isRewardDistribution[_msgSender()],
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(
        address _rewardDistribution,
        bool _isRewardDistribution
    ) external onlyOwner {
        isRewardDistribution[_rewardDistribution] = _isRewardDistribution;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    constructor(address _stakeToken) public {
        stakeToken = IERC20(_stakeToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }
}

contract HarvestStakingMock is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public rewardToken;
    uint256 public constant DURATION = 7 days;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkStart {
        require(block.timestamp >= starttime, "Rewards: not start");
        _;
    }

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _starttime
    ) public LPTokenWrapper(_stakeToken) {
        rewardToken = IERC20(_rewardToken);
        starttime = _starttime;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Rewards: cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Rewards: cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        // https://sips.synthetix.io/sips/sip-77
        require(reward > 0, "Rewards: reward == 0");
        require(
            reward < uint256(-1) / 10**18,
            "Rewards: rewards too large, would lock"
        );
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity 0.5.17;

contract LendingPoolAddressesProviderMock {
    address internal pool;
    address internal core;

    function getLendingPool() external view returns (address) {
        return pool;
    }

    function setLendingPoolImpl(address _pool) external {
        pool = _pool;
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./ATokenMock.sol";

contract LendingPoolMock {
    mapping(address => address) internal reserveAToken;

    function setReserveAToken(address _reserve, address _aTokenAddress)
        external
    {
        reserveAToken[_reserve] = _aTokenAddress;
    }

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16
    ) external {
        // Transfer asset
        ERC20 token = ERC20(asset);
        token.transferFrom(msg.sender, address(this), amount);

        // Mint aTokens
        address aTokenAddress = reserveAToken[asset];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        aToken.mint(onBehalfOf, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        // Burn aTokens
        address aTokenAddress = reserveAToken[asset];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        aToken.burn(msg.sender, amount);

        // Transfer asset
        ERC20 token = ERC20(asset);
        token.transfer(to, amount);
    }

    // The equivalent of exchangeRateStored() for Compound cTokens
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256)
    {
        address aTokenAddress = reserveAToken[asset];
        ATokenMock aToken = ATokenMock(aTokenAddress);
        return aToken.normalizedIncome();
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/DecMath.sol";

contract VaultMock is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using DecMath for uint256;

    ERC20 public underlying;

    constructor(address _underlying) public ERC20Detailed("yUSD", "yUSD", 18) {
        underlying = ERC20(_underlying);
    }

    function deposit(uint256 tokenAmount) public {
        uint256 sharePrice = getPricePerFullShare();
        _mint(msg.sender, tokenAmount.decdiv(sharePrice));

        underlying.transferFrom(msg.sender, address(this), tokenAmount);
    }

    function withdraw(uint256 sharesAmount) public {
        uint256 sharePrice = getPricePerFullShare();
        uint256 underlyingAmount = sharesAmount.decmul(sharePrice);
        _burn(msg.sender, sharesAmount);

        underlying.transfer(msg.sender, underlyingAmount);
    }

    function getPricePerFullShare() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return 10**18;
        }
        return underlying.balanceOf(address(this)).decdiv(_totalSupply);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/DecMath.sol";

contract VaultWithDepositFeeMock is ERC20, ERC20Detailed {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 PRECISION = 10**18;

    ERC20 public underlying;
    uint256 public depositFee;
    uint256 public feeCollected;

    constructor(address _underlying, uint256 _depositFee)
        public
        ERC20Detailed("yUSD", "yUSD", 18)
    {
        underlying = ERC20(_underlying);
        depositFee = _depositFee;
    }

    function deposit(uint256 tokenAmount) public {
        uint256 sharePrice = getPricePerFullShare();
        uint256 shareAmountAfterFee = tokenAmount.decdiv(sharePrice).decmul(PRECISION.sub(depositFee));
        uint256 tokenFee = tokenAmount.decmul(depositFee);
        _mint(msg.sender, shareAmountAfterFee);

        underlying.transferFrom(msg.sender, address(this), tokenAmount);

        feeCollected = feeCollected.add(tokenFee);
    }

    function withdraw(uint256 sharesAmount) public {
        uint256 sharePrice = getPricePerFullShare();
        uint256 underlyingAmount = sharesAmount.decmul(sharePrice);
        _burn(msg.sender, sharesAmount);

        underlying.transfer(msg.sender, underlyingAmount);
    }

    function getPricePerFullShare() public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return 10**18;
        }
        return underlying.balanceOf(address(this)).sub(feeCollected).decdiv(_totalSupply);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./IFeeModel.sol";

contract PercentageFeeModel is IFeeModel, Ownable {
    using SafeMath for uint256;

    address payable public beneficiary;

    event SetBeneficiary(address newBeneficiary);

    constructor(address payable _beneficiary) public {
        beneficiary = _beneficiary;
    }

    function getFee(uint256 _txAmount)
        external
        pure
        returns (uint256 _feeAmount)
    {
        _feeAmount = _txAmount.div(5); // Precision is decreased by 1 decimal place
    }

    function setBeneficiary(address payable newValue) external onlyOwner {
        require(newValue != address(0), "PercentageFeeModel: 0 address");
        beneficiary = newValue;
        emit SetBeneficiary(newValue);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../moneymarkets/IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./IInterestOracle.sol";

contract EMAOracle is IInterestOracle {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    /**
        Immutable parameters
     */
    uint256 public UPDATE_INTERVAL;
    uint256 public UPDATE_MULTIPLIER;
    uint256 public ONE_MINUS_UPDATE_MULTIPLIER;

    /**
        Public variables
     */
    uint256 public emaStored;
    uint256 public lastIncomeIndex;
    uint256 public lastUpdateTimestamp;

    /**
        External contracts
     */
    IMoneyMarket public moneyMarket;

    constructor(
        uint256 _emaInitial,
        uint256 _updateInterval,
        uint256 _smoothingFactor,
        uint256 _averageWindowInIntervals,
        address _moneyMarket
    ) public {
        emaStored = _emaInitial;
        UPDATE_INTERVAL = _updateInterval;
        lastUpdateTimestamp = now;

        uint256 updateMultiplier = _smoothingFactor.div(_averageWindowInIntervals.add(1));
        UPDATE_MULTIPLIER = updateMultiplier;
        ONE_MINUS_UPDATE_MULTIPLIER = PRECISION.sub(updateMultiplier);

        moneyMarket = IMoneyMarket(_moneyMarket);
        lastIncomeIndex = moneyMarket.incomeIndex();
    }

    function updateAndQuery() public returns (bool updated, uint256 value) {
        uint256 timeElapsed = now - lastUpdateTimestamp;
        if (timeElapsed < UPDATE_INTERVAL) {
            return (false, emaStored);
        }

        // save gas by loading storage variables to memory
        uint256 _lastIncomeIndex = lastIncomeIndex;
        uint256 _emaStored = emaStored;

        uint256 newIncomeIndex = moneyMarket.incomeIndex();
        uint256 incomingValue = newIncomeIndex.sub(_lastIncomeIndex).decdiv(_lastIncomeIndex).div(timeElapsed);

        updated = true;
        value = incomingValue.mul(UPDATE_MULTIPLIER).add(_emaStored.mul(ONE_MINUS_UPDATE_MULTIPLIER)).div(PRECISION);
        emaStored = value;
        lastIncomeIndex = newIncomeIndex;
        lastUpdateTimestamp = now;
    }

    function query() public view returns (uint256 value) {
        return emaStored;
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../libs/DecMath.sol";

contract LinearInterestModel {
    using SafeMath for uint256;
    using DecMath for uint256;

    uint256 public constant PRECISION = 10**18;
    uint256 public IRMultiplier;

    constructor(uint256 _IRMultiplier) public {
        IRMultiplier = _IRMultiplier;
    }

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 moneyMarketInterestRatePerSecond,
        bool, /*surplusIsNegative*/
        uint256 /*surplusAmount*/
    ) external view returns (uint256 interestAmount) {
        // interestAmount = depositAmount * moneyMarketInterestRatePerSecond * IRMultiplier * depositPeriodInSeconds
        interestAmount = depositAmount
            .mul(PRECISION)
            .decmul(moneyMarketInterestRatePerSecond)
            .decmul(IRMultiplier)
            .mul(depositPeriodInSeconds)
            .div(PRECISION);
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../libs/DecMath.sol";
import "./IMPHIssuanceModel.sol";

contract MPHIssuanceModel01 is Ownable, IMPHIssuanceModel {
    using Address for address;
    using DecMath for uint256;
    using SafeMath for uint256;

    uint256 internal constant PRECISION = 10**18;

    /**
        @notice The multiplier applied when minting MPH for a pool's depositor reward.
                Unit is MPH-wei per depositToken-wei per second. (wei here is the smallest decimal place)
                Scaled by 10^18.
                NOTE: The depositToken's decimals matter! 
     */
    mapping(address => uint256) public poolDepositorRewardMintMultiplier;
    /**
        @notice The multiplier applied when taking back MPH from depositors upon withdrawal.
                No unit, is a proportion between 0 and 1.
                Scaled by 10^18.
     */
    mapping(address => uint256) public poolDepositorRewardTakeBackMultiplier;
    /**
        @notice The multiplier applied when minting MPH for a pool's funder reward.
                Unit is MPH-wei per depositToken-wei per second. (wei here is the smallest decimal place)
                Scaled by 10^18.
                NOTE: The depositToken's decimals matter! 
     */
    mapping(address => uint256) public poolFunderRewardMultiplier;
    /**
        @notice The period over which the depositor reward will be vested, in seconds.
     */
    mapping(address => uint256) public poolDepositorRewardVestPeriod;
    /**
        @notice The period over which the funder reward will be vested, in seconds.
     */
    mapping(address => uint256) public poolFunderRewardVestPeriod;

    /**
        @notice Multiplier used for calculating dev reward
     */
    uint256 public devRewardMultiplier;

    event ESetParamAddress(
        address indexed sender,
        string indexed paramName,
        address newValue
    );
    event ESetParamUint(
        address indexed sender,
        string indexed paramName,
        address indexed pool,
        uint256 newValue
    );

    constructor(uint256 _devRewardMultiplier) public {
        devRewardMultiplier = _devRewardMultiplier;
    }

    /**
        @notice Computes the MPH amount to reward to a depositor upon deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  depositPeriodInSeconds The deposit's lock period in seconds
        @param  interestAmount The deposit's fixed-rate interest amount in the pool's stablecoins
        @return depositorReward The MPH amount to mint to the depositor
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeDepositorReward(
        address pool,
        uint256 depositAmount,
        uint256 depositPeriodInSeconds,
        uint256 interestAmount
    )
        external
        view
        returns (
            uint256 depositorReward,
            uint256 devReward,
            uint256 govReward
        )
    {
        uint256 mintAmount = depositAmount.mul(depositPeriodInSeconds).decmul(
            poolDepositorRewardMintMultiplier[pool]
        );
        depositorReward = mintAmount;
        devReward = mintAmount.decmul(devRewardMultiplier);
        govReward = 0;
    }

    /**
        @notice Computes the MPH amount to take back from a depositor upon withdrawal.
                If takeBackAmount > devReward + govReward, the extra MPH should be burnt.
        @param  pool The DInterest pool trying to mint reward
        @param  mintMPHAmount The MPH amount originally minted to the depositor as reward
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return takeBackAmount The MPH amount to take back from the depositor
                devReward The MPH amount from takeBackAmount to send to the dev wallet
                govReward The MPH amount from takeBackAmount to send to the gov treasury
     */
    function computeTakeBackDepositorRewardAmount(
        address pool,
        uint256 mintMPHAmount,
        bool early
    )
        external
        view
        returns (
            uint256 takeBackAmount,
            uint256 devReward,
            uint256 govReward
        )
    {
        takeBackAmount = early
            ? mintMPHAmount
            : mintMPHAmount.decmul(poolDepositorRewardTakeBackMultiplier[pool]);
        devReward = 0;
        govReward = early ? 0 : takeBackAmount;
    }

    /**
        @notice Computes the MPH amount to reward to a deficit funder upon withdrawal of an underlying deposit.
        @param  pool The DInterest pool trying to mint reward
        @param  depositAmount The deposit amount in the pool's stablecoins
        @param  fundingCreationTimestamp The timestamp of the funding's creation, in seconds
        @param  maturationTimestamp The maturation timestamp of the deposit, in seconds
        @param  interestPayoutAmount The interest payout amount to the funder, in the pool's stablecoins.
                                     Includes the interest from other funded deposits.
        @param  early True if the deposit is withdrawn early, false if the deposit is mature
        @return funderReward The MPH amount to mint to the funder
                devReward The MPH amount to mint to the dev wallet
                govReward The MPH amount to mint to the gov treasury
     */
    function computeFunderReward(
        address pool,
        uint256 depositAmount,
        uint256 fundingCreationTimestamp,
        uint256 maturationTimestamp,
        uint256 interestPayoutAmount,
        bool early
    )
        external
        view
        returns (
            uint256 funderReward,
            uint256 devReward,
            uint256 govReward
        )
    {
        if (early) {
            return (0, 0, 0);
        }
        funderReward = maturationTimestamp > fundingCreationTimestamp
            ? depositAmount
                .mul(maturationTimestamp.sub(fundingCreationTimestamp))
                .decmul(poolFunderRewardMultiplier[pool])
            : 0;
        devReward = funderReward.decmul(devRewardMultiplier);
        govReward = 0;
    }

    /**
        Param setters
     */

    function setPoolDepositorRewardMintMultiplier(
        address pool,
        uint256 newMultiplier
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolDepositorRewardMintMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardMintMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolDepositorRewardTakeBackMultiplier(
        address pool,
        uint256 newMultiplier
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        require(
            newMultiplier <= PRECISION,
            "MPHIssuanceModel: invalid multiplier"
        );
        poolDepositorRewardTakeBackMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardTakeBackMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolFunderRewardMultiplier(address pool, uint256 newMultiplier)
        external
        onlyOwner
    {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolFunderRewardMultiplier[pool] = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "poolFunderRewardMultiplier",
            pool,
            newMultiplier
        );
    }

    function setPoolDepositorRewardVestPeriod(
        address pool,
        uint256 newVestPeriodInSeconds
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolDepositorRewardVestPeriod[pool] = newVestPeriodInSeconds;
        emit ESetParamUint(
            msg.sender,
            "poolDepositorRewardVestPeriod",
            pool,
            newVestPeriodInSeconds
        );
    }

    function setPoolFunderRewardVestPeriod(
        address pool,
        uint256 newVestPeriodInSeconds
    ) external onlyOwner {
        require(pool.isContract(), "MPHIssuanceModel: pool not contract");
        poolFunderRewardVestPeriod[pool] = newVestPeriodInSeconds;
        emit ESetParamUint(
            msg.sender,
            "poolFunderRewardVestPeriod",
            pool,
            newVestPeriodInSeconds
        );
    }

    function setDevRewardMultiplier(uint256 newMultiplier) external onlyOwner {
        require(
            newMultiplier <= PRECISION,
            "MPHIssuanceModel: invalid multiplier"
        );
        devRewardMultiplier = newMultiplier;
        emit ESetParamUint(
            msg.sender,
            "devRewardMultiplier",
            address(0),
            newMultiplier
        );
    }
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../IMoneyMarket.sol";
import "./imports/ILendingPool.sol";
import "./imports/ILendingPoolAddressesProvider.sol";

contract AaveMarket is IMoneyMarket, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    uint16 internal constant REFERRALCODE = 20; // Aave referral program code

    ILendingPoolAddressesProvider public provider; // Used for fetching the current address of LendingPool
    ERC20 public stablecoin;
    ERC20 public aToken;

    constructor(
        address _provider,
        address _aToken,
        address _stablecoin
    ) public {
        // Verify input addresses
        require(
            _provider.isContract() &&
                _aToken.isContract() &&
                _stablecoin.isContract(),
            "AaveMarket: An input address is not a contract"
        );

        provider = ILendingPoolAddressesProvider(_provider);
        stablecoin = ERC20(_stablecoin);
        aToken = ERC20(_aToken);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "AaveMarket: amount is 0");

        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Approve `amount` stablecoin to lendingPool
        stablecoin.safeIncreaseAllowance(address(lendingPool), amount);

        // Deposit `amount` stablecoin to lendingPool
        lendingPool.deposit(
            address(stablecoin),
            amount,
            address(this),
            REFERRALCODE
        );
    }

    function withdraw(uint256 amountInUnderlying)
        external
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(amountInUnderlying > 0, "AaveMarket: amountInUnderlying is 0");

        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());

        // Redeem `amountInUnderlying` aToken, since 1 aToken = 1 stablecoin
        // Transfer `amountInUnderlying` stablecoin to `msg.sender`
        lendingPool.withdraw(
            address(stablecoin),
            amountInUnderlying,
            msg.sender
        );

        return amountInUnderlying;
    }

    function claimRewards() external {}

    function totalValue() external returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function incomeIndex() external returns (uint256) {
        ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        return lendingPool.getReserveNormalizedIncome(address(stablecoin));
    }

    function setRewards(address newValue) external {}
}

pragma solidity 0.5.17;

// Aave lending pool interface
// Documentation: https://docs.aave.com/developers/the-core-protocol/lendingpool/ilendingpool
// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.5.17;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/ICERC20.sol";
import "./imports/IComptroller.sol";

contract CompoundERC20Market is IMoneyMarket, Ownable {
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    uint256 internal constant ERRCODE_OK = 0;

    ICERC20 public cToken;
    IComptroller public comptroller;
    address public rewards;
    ERC20 public stablecoin;

    constructor(
        address _cToken,
        address _comptroller,
        address _rewards,
        address _stablecoin
    ) public {
        // Verify input addresses
        require(
            _cToken.isContract() &&
                _comptroller.isContract() &&
                _rewards.isContract() &&
                _stablecoin.isContract(),
            "CompoundERC20Market: An input address is not a contract"
        );

        cToken = ICERC20(_cToken);
        comptroller = IComptroller(_comptroller);
        rewards = _rewards;
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "CompoundERC20Market: amount is 0");

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit `amount` stablecoin into cToken
        stablecoin.safeIncreaseAllowance(address(cToken), amount);
        require(
            cToken.mint(amount) == ERRCODE_OK,
            "CompoundERC20Market: Failed to mint cTokens"
        );
    }

    function withdraw(uint256 amountInUnderlying)
        external
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(
            amountInUnderlying > 0,
            "CompoundERC20Market: amountInUnderlying is 0"
        );

        // Withdraw `amountInUnderlying` stablecoin from cToken
        require(
            cToken.redeemUnderlying(amountInUnderlying) == ERRCODE_OK,
            "CompoundERC20Market: Failed to redeem"
        );

        // Transfer `amountInUnderlying` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, amountInUnderlying);

        return amountInUnderlying;
    }

    function claimRewards() external {
        comptroller.claimComp(address(this));
        ERC20 comp = ERC20(comptroller.getCompAddress());
        comp.safeTransfer(rewards, comp.balanceOf(address(this)));
    }

    function totalValue() external returns (uint256) {
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        // Amount of stablecoin units that 1 unit of cToken can be exchanged for, scaled by 10^18
        uint256 cTokenPrice = cToken.exchangeRateCurrent();
        return cTokenBalance.decmul(cTokenPrice);
    }

    function incomeIndex() external returns (uint256) {
        return cToken.exchangeRateCurrent();
    }

    /**
        Param setters
     */
    function setRewards(address newValue) external onlyOwner {
        require(newValue.isContract(), "CompoundERC20Market: not contract");
        rewards = newValue;
        emit ESetParamAddress(msg.sender, "rewards", newValue);
    }
}

pragma solidity 0.5.17;


// Compound finance ERC20 market interface
// Documentation: https://compound.finance/docs/ctokens
interface ICERC20 {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(address liquidator, address borrower, uint256 seizeTokens)
        external
        returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);
}

pragma solidity 0.5.17;


// Compound finance Comptroller interface
// Documentation: https://compound.finance/docs/comptroller
interface IComptroller {
    function claimComp(address holder) external;
    function getCompAddress() external view returns (address);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/ICERC20.sol";

contract CreamERC20Market is IMoneyMarket, Ownable {
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    uint256 internal constant ERRCODE_OK = 0;

    ICERC20 public cToken;
    ERC20 public stablecoin;

    constructor(address _cToken, address _stablecoin) public {
        // Verify input addresses
        require(
            _cToken.isContract() && _stablecoin.isContract(),
            "CreamERC20Market: An input address is not a contract"
        );

        cToken = ICERC20(_cToken);
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "CreamERC20Market: amount is 0");

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Deposit `amount` stablecoin into cToken
        stablecoin.safeIncreaseAllowance(address(cToken), amount);
        require(
            cToken.mint(amount) == ERRCODE_OK,
            "CreamERC20Market: Failed to mint cTokens"
        );
    }

    function withdraw(uint256 amountInUnderlying)
        external
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(
            amountInUnderlying > 0,
            "CreamERC20Market: amountInUnderlying is 0"
        );

        // Withdraw `amountInUnderlying` stablecoin from cToken
        require(
            cToken.redeemUnderlying(amountInUnderlying) == ERRCODE_OK,
            "CreamERC20Market: Failed to redeem"
        );

        // Transfer `amountInUnderlying` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, amountInUnderlying);

        return amountInUnderlying;
    }

    function claimRewards() external {}

    function totalValue() external returns (uint256) {
        uint256 cTokenBalance = cToken.balanceOf(address(this));
        // Amount of stablecoin units that 1 unit of cToken can be exchanged for, scaled by 10^18
        uint256 cTokenPrice = cToken.exchangeRateCurrent();
        return cTokenBalance.decmul(cTokenPrice);
    }

    function incomeIndex() external returns (uint256) {
        return cToken.exchangeRateCurrent();
    }

    /**
        Param setters
     */
    function setRewards(address newValue) external onlyOwner {}
}

pragma solidity 0.5.17;


// Compound finance ERC20 market interface
// Documentation: https://compound.finance/docs/ctokens
interface ICERC20 {
    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (uint256, uint256, uint256, uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(address liquidator, address borrower, uint256 seizeTokens)
        external
        returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/HarvestVault.sol";
import "./imports/HarvestStaking.sol";

contract HarvestMarket is IMoneyMarket, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    HarvestVault public vault;
    address public rewards;
    HarvestStaking public stakingPool;
    ERC20 public stablecoin;

    constructor(
        address _vault,
        address _rewards,
        address _stakingPool,
        address _stablecoin
    ) public {
        // Verify input addresses
        require(
            _vault.isContract() &&
                _rewards.isContract() &&
                _stakingPool.isContract() &&
                _stablecoin.isContract(),
            "HarvestMarket: An input address is not a contract"
        );

        vault = HarvestVault(_vault);
        rewards = _rewards;
        stakingPool = HarvestStaking(_stakingPool);
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "HarvestMarket: amount is 0");

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Approve `amount` stablecoin to vault
        stablecoin.safeIncreaseAllowance(address(vault), amount);

        // Deposit `amount` stablecoin to vault
        vault.deposit(amount);

        // Stake vault token balance into staking pool
        uint256 vaultShareBalance = vault.balanceOf(address(this));
        vault.approve(address(stakingPool), vaultShareBalance);
        stakingPool.stake(vaultShareBalance);
    }

    function withdraw(uint256 amountInUnderlying)
        external
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(
            amountInUnderlying > 0,
            "HarvestMarket: amountInUnderlying is 0"
        );

        // Withdraw `amountInShares` shares from vault
        uint256 sharePrice = vault.getPricePerFullShare();
        uint256 amountInShares = amountInUnderlying.decdiv(sharePrice);
        if (amountInShares > 0) {
            stakingPool.withdraw(amountInShares);
            vault.withdraw(amountInShares);
        }

        // Transfer stablecoin to `msg.sender`
        actualAmountWithdrawn = stablecoin.balanceOf(address(this));
        if (actualAmountWithdrawn > 0) {
            stablecoin.safeTransfer(msg.sender, actualAmountWithdrawn);
        }
    }

    function claimRewards() external {
        stakingPool.getReward();
        ERC20 rewardToken = ERC20(stakingPool.rewardToken());
        rewardToken.safeTransfer(rewards, rewardToken.balanceOf(address(this)));
    }

    function totalValue() external returns (uint256) {
        uint256 sharePrice = vault.getPricePerFullShare();
        uint256 shareBalance = vault.balanceOf(address(this)).add(stakingPool.balanceOf(address(this)));
        return shareBalance.decmul(sharePrice);
    }

    function incomeIndex() external returns (uint256) {
        return vault.getPricePerFullShare();
    }

    /**
        Param setters
     */
    function setRewards(address newValue) external onlyOwner {
        require(newValue.isContract(), "HarvestMarket: not contract");
        rewards = newValue;
        emit ESetParamAddress(msg.sender, "rewards", newValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface HarvestVault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface HarvestStaking {
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function rewardToken() external returns (address);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface Vault {
    function deposit(uint256) external;

    function withdraw(uint256) external;

    function getPricePerFullShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../IMoneyMarket.sol";
import "../../libs/DecMath.sol";
import "./imports/Vault.sol";

contract YVaultMarket is IMoneyMarket, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    Vault public vault;
    ERC20 public stablecoin;

    constructor(address _vault, address _stablecoin) public {
        // Verify input addresses
        require(
            _vault.isContract() && _stablecoin.isContract(),
            "YVaultMarket: An input address is not a contract"
        );

        vault = Vault(_vault);
        stablecoin = ERC20(_stablecoin);
    }

    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "YVaultMarket: amount is 0");

        // Transfer `amount` stablecoin from `msg.sender`
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);

        // Approve `amount` stablecoin to vault
        stablecoin.safeIncreaseAllowance(address(vault), amount);

        // Deposit `amount` stablecoin to vault
        vault.deposit(amount);
    }

    function withdraw(uint256 amountInUnderlying)
        external
        onlyOwner
        returns (uint256 actualAmountWithdrawn)
    {
        require(
            amountInUnderlying > 0,
            "YVaultMarket: amountInUnderlying is 0"
        );

        // Withdraw `amountInShares` shares from vault
        uint256 sharePrice = vault.getPricePerFullShare();
        uint256 amountInShares = amountInUnderlying.decdiv(sharePrice);
        if (amountInShares > 0) {
            vault.withdraw(amountInShares);
        }

        // Transfer stablecoin to `msg.sender`
        actualAmountWithdrawn = stablecoin.balanceOf(address(this));
        if (actualAmountWithdrawn > 0) {
            stablecoin.safeTransfer(msg.sender, actualAmountWithdrawn);
        }
    }

    function claimRewards() external {}

    function totalValue() external returns (uint256) {
        uint256 sharePrice = vault.getPricePerFullShare();
        uint256 shareBalance = vault.balanceOf(address(this));
        return shareBalance.decmul(sharePrice);
    }

    function incomeIndex() external returns (uint256) {
        return vault.getPricePerFullShare();
    }

    function setRewards(address newValue) external {}
}

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./libs/CloneFactory.sol";
import "./NFT.sol";

contract NFTFactory is CloneFactory {
    address public template;

    event CreateClone(address _clone);

    constructor(address _template) public {
        template = _template;
    }

    function createClone(
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external returns (NFT) {
        NFT clone = NFT(createClone(template));

        // initialize
        clone.init(
            msg.sender,
            _tokenName,
            _tokenSymbol
        );

        emit CreateClone(address(clone));
        return clone;
    }

    function isClone(address query) external view returns (bool) {
        return isClone(template, query);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "./OneSplitDumper.sol";
import "./withdrawers/CurveLPWithdrawer.sol";
import "./withdrawers/YearnWithdrawer.sol";

contract Dumper is OneSplitDumper, CurveLPWithdrawer, YearnWithdrawer {
    constructor(
        address _oneSplit,
        address _rewards,
        address _rewardToken
    ) public OneSplitDumper(_oneSplit, _rewards, _rewardToken) {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./imports/OneSplitAudit.sol";
import "../IRewards.sol";

contract OneSplitDumper is SignerRole {
    using SafeERC20 for IERC20;

    OneSplitAudit public oneSplit;
    IRewards public rewards;
    IERC20 public rewardToken;

    constructor(
        address _oneSplit,
        address _rewards,
        address _rewardToken
    ) public {
        oneSplit = OneSplitAudit(_oneSplit);
        rewards = IRewards(_rewards);
        rewardToken = IERC20(_rewardToken);
    }

    function getDumpParams(address tokenAddress, uint256 parts)
        external
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        (returnAmount, distribution) = oneSplit.getExpectedReturn(
            tokenAddress,
            address(rewardToken),
            tokenBalance,
            parts,
            0
        );
    }

    function dump(
        address tokenAddress,
        uint256 returnAmount,
        uint256[] calldata distribution
    ) external onlySigner {
        // dump token for rewardToken
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeIncreaseAllowance(address(oneSplit), tokenBalance);

        uint256 rewardTokenBalanceBefore = rewardToken.balanceOf(address(this));
        oneSplit.swap(
            tokenAddress,
            address(rewardToken),
            tokenBalance,
            returnAmount,
            distribution,
            0
        );
        uint256 rewardTokenBalanceAfter = rewardToken.balanceOf(address(this));
        require(
            rewardTokenBalanceAfter > rewardTokenBalanceBefore,
            "OneSplitDumper: receivedRewardTokenAmount == 0"
        );
    }

    function notify() external onlySigner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(address(rewards), balance);
        rewards.notifyRewardAmount(balance);
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

contract SignerRole is Context {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(_msgSender());
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(_msgSender());
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

interface OneSplitAudit {
    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution,
        uint256 flags
    ) external payable;

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns (uint256 returnAmount, uint256[] memory distribution);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

interface IRewards {
    function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../imports/Curve.sol";
import "../../IRewards.sol";

contract CurveLPWithdrawer is SignerRole {
    function curveWithdraw2(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[2] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw3(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[3] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw4(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[4] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdraw5(
        address lpTokenAddress,
        address curvePoolAddress,
        uint256[5] calldata minAmounts
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        ICurveFi curvePool = ICurveFi(curvePoolAddress);
        curvePool.remove_liquidity(lpTokenBalance, minAmounts);
    }

    function curveWithdrawOneCoin(
        address lpTokenAddress,
        address curvePoolAddress,
        int128 coinIndex,
        uint256 minAmount
    ) external onlySigner {
        IERC20 lpToken = IERC20(lpTokenAddress);
        uint256 lpTokenBalance = lpToken.balanceOf(address(this));
        Zap curvePool = Zap(curvePoolAddress);
        curvePool.remove_liquidity_one_coin(
            lpTokenBalance,
            coinIndex,
            minAmount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

interface ICurveFi {
    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[5] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external;

    function remove_liquidity(uint256 _amount, uint256[5] calldata amounts)
        external;
}

interface Zap {
    function remove_liquidity_one_coin(
        uint256,
        int128,
        uint256
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.5.17;

import "@openzeppelin/contracts/access/roles/SignerRole.sol";
import "../imports/yERC20.sol";

contract YearnWithdrawer is SignerRole {
    function yearnWithdraw(address yTokenAddress) external onlySigner {
        yERC20 yToken = yERC20(yTokenAddress);
        uint256 balance = yToken.balanceOf(address(this));
        yToken.withdraw(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.17;

// NOTE: Basically an alias for Vaults
interface yERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getPricePerFullShare() external view returns (uint256);
}

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/
* Synthetix: Rewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

pragma solidity 0.5.17;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract IRewardDistributionRecipient is Ownable {
    mapping(address => bool) public isRewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(
            isRewardDistribution[_msgSender()],
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(
        address _rewardDistribution,
        bool _isRewardDistribution
    ) external onlyOwner {
        isRewardDistribution[_rewardDistribution] = _isRewardDistribution;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    constructor(address _stakeToken) public {
        stakeToken = IERC20(_stakeToken);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakeToken.safeTransfer(msg.sender, amount);
    }
}

contract Rewards is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public rewardToken;
    uint256 public constant DURATION = 7 days;

    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier checkStart {
        require(block.timestamp >= starttime, "Rewards: not start");
        _;
    }

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _starttime
    ) public LPTokenWrapper(_stakeToken) {
        rewardToken = IERC20(_rewardToken);
        starttime = _starttime;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "Rewards: cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        updateReward(msg.sender)
        checkStart
    {
        require(amount > 0, "Rewards: cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        // https://sips.synthetix.io/sips/sip-77
        require(reward > 0, "Rewards: reward == 0");
        require(
            reward < uint256(-1) / 10**18,
            "Rewards: rewards too large, would lock"
        );
        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION);
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
    }
}

pragma solidity 0.5.17;

interface CurveZapIn {
    /**
        @notice This function adds liquidity to a Curve pool with ETH or ERC20 tokens
        @param toWhomToIssue The address to return the Curve LP tokens to
        @param fromToken The ERC20 token used for investment (address(0x00) if ether)
        @param swapAddress Curve swap address for the pool
        @param incomingTokenQty The amount of fromToken to invest
        @param minPoolTokens The minimum acceptable quantity of tokens to receive. Reverts otherwise
        @return Amount of Curve LP tokens received
    */
    function ZapIn(
        address toWhomToIssue,
        address fromToken,
        address swapAddress,
        uint256 incomingTokenQty,
        uint256 minPoolTokens
    ) external payable returns (uint256 crvTokensBought);
}

pragma solidity 0.5.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./imports/CurveZapIn.sol";
import "../DInterest.sol";
import "../NFT.sol";

contract ZapCurve is IERC721Receiver {
    using SafeERC20 for ERC20;

    modifier active {
        isActive = true;
        _;
        isActive = false;
    }

    CurveZapIn public constant zapper =
        CurveZapIn(0xf9A724c2607E5766a7Bbe530D6a7e173532F9f3a);
    bool public isActive;

    function zapCurveDeposit(
        address pool,
        address swapAddress,
        address inputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        uint256 maturationTimestamp
    ) external active {
        DInterest poolContract = DInterest(pool);
        ERC20 stablecoin = poolContract.stablecoin();
        NFT depositNFT = poolContract.depositNFT();

        // zap into curve
        uint256 outputTokenAmount =
            _zapTokenInCurve(
                swapAddress,
                inputToken,
                inputTokenAmount,
                minOutputTokenAmount
            );

        // create deposit
        stablecoin.safeIncreaseAllowance(pool, outputTokenAmount);
        poolContract.deposit(outputTokenAmount, maturationTimestamp);

        // transfer deposit NFT to msg.sender
        uint256 nftID = poolContract.depositsLength();
        depositNFT.safeTransferFrom(address(this), msg.sender, nftID);
    }

    function zapCurveFundAll(
        address pool,
        address swapAddress,
        address inputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount
    ) external active {
        DInterest poolContract = DInterest(pool);
        ERC20 stablecoin = poolContract.stablecoin();
        NFT fundingNFT = poolContract.fundingNFT();

        // zap into curve
        uint256 outputTokenAmount =
            _zapTokenInCurve(
                swapAddress,
                inputToken,
                inputTokenAmount,
                minOutputTokenAmount
            );

        // create funding
        stablecoin.safeIncreaseAllowance(pool, outputTokenAmount);
        poolContract.fundAll();

        // transfer funding NFT to msg.sender
        uint256 nftID = poolContract.fundingListLength();
        fundingNFT.safeTransferFrom(address(this), msg.sender, nftID);
    }

    function zapCurveFundMultiple(
        address pool,
        address swapAddress,
        address inputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        uint256 toDepositID
    ) external active {
        DInterest poolContract = DInterest(pool);
        ERC20 stablecoin = poolContract.stablecoin();
        NFT fundingNFT = poolContract.fundingNFT();

        // zap into curve
        uint256 outputTokenAmount =
            _zapTokenInCurve(
                swapAddress,
                inputToken,
                inputTokenAmount,
                minOutputTokenAmount
            );

        // create funding
        stablecoin.safeIncreaseAllowance(pool, outputTokenAmount);
        poolContract.fundMultiple(toDepositID);

        // transfer funding NFT to msg.sender
        uint256 nftID = poolContract.fundingListLength();
        fundingNFT.safeTransferFrom(address(this), msg.sender, nftID);
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        require(isActive, "ZapCurve: inactive");
        return this.onERC721Received.selector;
    }

    function _zapTokenInCurve(
        address swapAddress,
        address inputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount
    ) internal returns (uint256 outputTokenAmount) {
        ERC20 inputTokenContract = ERC20(inputToken);

        // transfer inputToken from msg.sender
        inputTokenContract.safeTransferFrom(
            msg.sender,
            address(this),
            inputTokenAmount
        );

        // zap inputToken into curve
        inputTokenContract.safeIncreaseAllowance(
            address(zapper),
            inputTokenAmount
        );
        outputTokenAmount = zapper.ZapIn(
            address(this),
            inputToken,
            swapAddress,
            inputTokenAmount,
            minOutputTokenAmount
        );
    }
}