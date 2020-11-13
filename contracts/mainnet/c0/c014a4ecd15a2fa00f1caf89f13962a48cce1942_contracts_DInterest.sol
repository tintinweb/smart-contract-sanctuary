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
// Contact: zefram@baconlabs.dev
contract DInterest is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using DecMath for uint256;
    using SafeERC20 for ERC20;
    using Address for address;

    // Constants
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant ONE = 10**18;

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
    }
    Deposit[] internal deposits;
    uint256 public latestFundedDepositID; // the ID of the most recently created deposit that was funded
    uint256 public unfundedUserDepositAmount; // the deposited stablecoin amount whose deficit hasn't been funded

    // Funding data
    // Each funding has an ID used in the fundingNFT, which is equal to its index in `fundingList` plus 1
    struct Funding {
        // deposits with fromDepositID < ID <= toDepositID are funded
        uint256 fromDepositID;
        uint256 toDepositID;
        uint256 recordedFundedDepositAmount;
        uint256 recordedMoneyMarketIncomeIndex;
    }
    Funding[] internal fundingList;

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
        uint256 deficitAmount,
        uint256 mintMPHAmount
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
                recordedMoneyMarketIncomeIndex: incomeIndex
            })
        );

        // Update relevant values
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
        uint256 totalDepositToFund = 0;
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
                totalDepositToFund = totalDepositToFund.add(
                    depositEntry.amount
                );
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
                recordedFundedDepositAmount: totalDepositToFund,
                recordedMoneyMarketIncomeIndex: incomeIndex
            })
        );

        // Update relevant values
        latestFundedDepositID = toDepositID;
        unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
            totalDepositToFund
        );

        _fund(totalDeficit);
    }

    /**
        Public getters
     */

    function calculateInterestAmount(
        uint256 depositAmount,
        uint256 depositPeriodInSeconds
    ) public returns (uint256 interestAmount) {
        (, uint256 moneyMarketInterestRatePerSecond) = interestOracle
            .updateAndQuery();
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

    function surplus() public returns (bool isNegative, uint256 surplusAmount) {
        uint256 totalValue = moneyMarket.totalValue();
        uint256 totalOwed = totalDeposit.add(totalInterestOwed);
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
        uint256 currentDepositValue = depositEntry
            .amount
            .mul(currentMoneyMarketIncomeIndex)
            .div(depositEntry.initialMoneyMarketIncomeIndex);
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
        emit ESetParamAddress(msg.sender, "interestOracle", newValue);
    }

    function setRewards(address newValue) external onlyOwner {
        require(newValue.isContract(), "DInterest: not contract");
        moneyMarket.setRewards(newValue);
        emit ESetParamAddress(msg.sender, "moneyMarket.rewards", newValue);
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
        require(newValue <= MaxDepositAmount, "DInterest: invalid value");
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
        // Cannot deposit 0
        require(amount > 0, "DInterest: Deposit amount is 0");

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

        // Update funding related data
        uint256 id = deposits.length.add(1);
        unfundedUserDepositAmount = unfundedUserDepositAmount.add(amount);

        // Calculate interest
        uint256 interestAmount = calculateInterestAmount(amount, depositPeriod);
        require(interestAmount > 0, "DInterest: interestAmount == 0");

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.add(interestAmount);

        // Mint MPH for msg.sender
        uint256 mintMPHAmount = mphMinter.mintDepositorReward(
            msg.sender,
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
                mintMPHAmount: mintMPHAmount
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

        // Take back MPH
        uint256 takeBackMPHAmount = mphMinter.takeBackDepositorReward(
            msg.sender,
            depositEntry.mintMPHAmount,
            early
        );

        // Update totalDeposit
        totalDeposit = totalDeposit.sub(depositEntry.amount);

        // Update totalInterestOwed
        totalInterestOwed = totalInterestOwed.sub(depositEntry.interestOwed);

        // Burn depositNFT
        depositNFT.burn(depositID);

        uint256 feeAmount;
        uint256 withdrawAmount;
        if (early) {
            // Withdraw the principal of the deposit from money market
            withdrawAmount = depositEntry.amount;
        } else {
            // Withdraw the principal & the interest from money market
            feeAmount = feeModel.getFee(depositEntry.interestOwed);
            withdrawAmount = depositEntry.amount.add(depositEntry.interestOwed);
        }
        withdrawAmount = moneyMarket.withdraw(withdrawAmount);

        (bool depositIsNegative, uint256 depositSurplus) = surplusOfDeposit(
            depositID
        );

        // If deposit was funded, payout interest to funder
        if (depositIsFunded(depositID)) {
            Funding storage f = _getFunding(fundingID);
            require(
                depositID > f.fromDepositID && depositID <= f.toDepositID,
                "DInterest: Deposit not funded by fundingID"
            );
            uint256 currentMoneyMarketIncomeIndex = moneyMarket.incomeIndex();
            require(
                currentMoneyMarketIncomeIndex > 0,
                "DInterest: currentMoneyMarketIncomeIndex == 0"
            );
            uint256 interestAmount = f
                .recordedFundedDepositAmount
                .mul(currentMoneyMarketIncomeIndex)
                .div(f.recordedMoneyMarketIncomeIndex)
                .sub(f.recordedFundedDepositAmount);

            // Update funding values
            f.recordedFundedDepositAmount = f.recordedFundedDepositAmount.sub(
                depositEntry.amount
            );
            f.recordedMoneyMarketIncomeIndex = currentMoneyMarketIncomeIndex;

            // Send interest to funder
            uint256 transferToFunderAmount = (early && depositIsNegative)
                ? interestAmount.add(depositSurplus)
                : interestAmount;
            if (transferToFunderAmount > 0) {
                transferToFunderAmount = moneyMarket.withdraw(
                    transferToFunderAmount
                );
                stablecoin.safeTransfer(
                    fundingNFT.ownerOf(fundingID),
                    transferToFunderAmount
                );
            }
        } else {
            // Remove deposit from future deficit fundings
            unfundedUserDepositAmount = unfundedUserDepositAmount.sub(
                depositEntry.amount
            );

            // Record remaining surplus
            depositEntry.finalSurplusIsNegative = depositIsNegative;
            depositEntry.finalSurplusAmount = depositSurplus;
        }

        // Send `withdrawAmount - feeAmount` stablecoin to `msg.sender`
        stablecoin.safeTransfer(msg.sender, withdrawAmount.sub(feeAmount));

        // Send `feeAmount` stablecoin to feeModel beneficiary
        stablecoin.safeTransfer(feeModel.beneficiary(), feeAmount);

        // Emit event
        emit EWithdraw(
            msg.sender,
            depositID,
            fundingID,
            early,
            takeBackMPHAmount
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

        // Mint MPH for msg.sender
        uint256 mintMPHAmount = mphMinter.mintFunderReward(
            msg.sender,
            totalDeficit
        );

        // Emit event
        uint256 fundingID = fundingList.length;
        emit EFund(msg.sender, fundingID, totalDeficit, mintMPHAmount);
    }
}
