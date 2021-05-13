// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeDecimalMath} from "./SafeDecimalMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import "./interfaces/IConjure.sol";
import "./interfaces/IConjureFactory.sol";
import "./interfaces/IConjureRouter.sol";

/// @author Conjure Finance Team
/// @title EtherCollateral
/// @notice Contract to create a collateral system for conjure
/// @dev Fork of https://github.com/Synthetixio/synthetix/blob/develop/contracts/EtherCollateralsUSD.sol and adopted
contract EtherCollateral is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    // ========== CONSTANTS ==========
    uint256 internal constant ONE_THOUSAND = 1e18 * 1000;
    uint256 internal constant ONE_HUNDRED = 1e18 * 100;
    uint256 internal constant ONE_HUNDRED_TEN = 1e18 * 110;

    // ========== SETTER STATE VARIABLES ==========

    // The ratio of Collateral to synths issued
    uint256 public collateralizationRatio;

    // Minting fee for issuing the synths
    uint256 public issueFeeRate;

    // Minimum amount of ETH to create loan preventing griefing and gas consumption. Min 0.05 ETH
    uint256 public constant minLoanCollateralSize = 10 ** 18 / 20;

    // Maximum number of loans an account can create
    uint256 public constant accountLoanLimit = 50;

    // Liquidation ratio when loans can be liquidated
    uint256 public liquidationRatio;

    // Liquidation penalty when loans are liquidated. default 10%
    uint256 public constant liquidationPenalty = 10 ** 18 / 10;

    // ========== STATE VARIABLES ==========

    // The total number of synths issued by the collateral in this contract
    uint256 public totalIssuedSynths;

    // Total number of loans ever created
    uint256 public totalLoansCreated;

    // Total number of open loans
    uint256 public totalOpenLoanCount;

    // Synth loan storage struct
    struct SynthLoanStruct {
        // Account that created the loan
        address payable account;
        // Amount (in collateral token ) that they deposited
        uint256 collateralAmount;
        // Amount (in synths) that they issued to borrow
        uint256 loanAmount;
        // Minting Fee
        uint256 mintingFee;
        // When the loan was created
        uint256 timeCreated;
        // ID for the loan
        uint256 loanID;
        // When the loan was paid back (closed)
        uint256 timeClosed;
    }

    // Users Loans by address
    mapping(address => SynthLoanStruct[]) public accountsSynthLoans;

    // Account Open Loan Counter
    mapping(address => uint256) public accountOpenLoanCounter;

    // address of the conjure contract (which represents the asset)
    address payable public arbasset;

    // the address of the collateral contract factory
    address public _factoryContract;

    // bool indicating if the asset is closed (no more opening loans and deposits)
    // this is set to true if the asset price reaches 0
    bool public assetClosed;

    // address of the owner
    address public owner;

    // ========== EVENTS ==========

    event IssueFeeRateUpdated(uint256 issueFeeRate);
    event LoanLiquidationOpenUpdated(bool loanLiquidationOpen);
    event LoanCreated(address indexed account, uint256 loanID, uint256 amount);
    event LoanClosed(address indexed account, uint256 loanID);
    event LoanLiquidated(address indexed account, uint256 loanID, address liquidator);
    event LoanPartiallyLiquidated(
        address indexed account,
        uint256 loanID,
        address liquidator,
        uint256 liquidatedAmount,
        uint256 liquidatedCollateral
    );
    event CollateralDeposited(address indexed account, uint256 loanID, uint256 collateralAmount, uint256 collateralAfter);
    event CollateralWithdrawn(address indexed account, uint256 loanID, uint256 amountWithdrawn, uint256 collateralAfter);
    event LoanRepaid(address indexed account, uint256 loanID, uint256 repaidAmount, uint256 newLoanAmount);
    event AssetClosed();
    event NewOwner(address newOwner);

    constructor() {
        // Don't allow implementation to be initialized.
        _factoryContract = address(1);
    }

    // modifier for only owner
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view for modifier
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    /**
     * @dev initializes the clone implementation and the EtherCollateral contract
     *
     * @param _asset the asset with which the EtherCollateral contract is linked
     * @param _owner the owner of the asset
     * @param _factoryAddress the address of the conjure factory for later fee sending
     * @param _mintingFeeRatio array which holds the minting fee and the c-ratio
    */
    function initialize(
        address payable _asset,
        address _owner,
        address _factoryAddress,
        uint256[2] memory _mintingFeeRatio
    )
    external
    {
        require(_factoryContract == address(0), "already initialized");
        require(_factoryAddress != address(0), "factory can not be null");
        require(_owner != address(0), "_owner can not be null");
        require(_asset != address(0), "_asset can not be null");
        // c-ratio greater 100 and less or equal 1000
        require(_mintingFeeRatio[1] <= ONE_THOUSAND, "C-Ratio Too high");
        require(_mintingFeeRatio[1] > ONE_HUNDRED_TEN, "C-Ratio Too low");

        arbasset = _asset;
        owner = _owner;
        setIssueFeeRateInternal(_mintingFeeRatio[0]);
        _factoryContract = _factoryAddress;
        collateralizationRatio = _mintingFeeRatio[1];
        liquidationRatio = _mintingFeeRatio[1] / 100;
    }

    // ========== SETTERS ==========

    /**
     * @dev lets the owner change the contract owner
     *
     * @param _newOwner the new owner address of the contract
    */
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0), "_newOwner can not be null");
    
        owner = _newOwner;
        emit NewOwner(_newOwner);
    }

    /**
     * @dev Sets minting fee of the asset internal function
     *
     * @param _issueFeeRate the new minting fee
    */
    function setIssueFeeRateInternal(uint256 _issueFeeRate) internal {
        // max 2.5% fee for minting
        require(_issueFeeRate <= 250, "Minting fee too high");

        issueFeeRate = _issueFeeRate;
        emit IssueFeeRateUpdated(issueFeeRate);
    }

    /**
     * @dev Sets minting fee of the asset
     *
     * @param _issueFeeRate the new minting fee
    */
    function setIssueFeeRate(uint256 _issueFeeRate) external onlyOwner {
        // fee can only be lowered
        require(_issueFeeRate <= issueFeeRate, "Fee can only be lowered");

        setIssueFeeRateInternal(_issueFeeRate);
    }

    /**
     * @dev Sets the assetClosed indicator if loan opening is allowed or not
     * Called by the Conjure contract if the asset price reaches 0.
     *
    */
    function setAssetClosed() external {
        require(msg.sender == arbasset, "Only Conjure contract can call");
        assetClosed = true;
        emit AssetClosed();
    }

    /**
     * @dev Gets all the contract information currently in use
     * array indicating which tokens had their prices updated.
     *
     * @return _collateralizationRatio the current C-Ratio
     * @return _issuanceRatio the percentage of 100/ C-ratio e.g. 100/150 = 0.6666666667
     * @return _issueFeeRate the minting fee for a new loan
     * @return _minLoanCollateralSize the minimum loan collateral value
     * @return _totalIssuedSynths the total of all issued synths
     * @return _totalLoansCreated the total of all loans created
     * @return _totalOpenLoanCount the total of open loans
     * @return _ethBalance the current balance of the contract
    */
    function getContractInfo()
    external
    view
    returns (
        uint256 _collateralizationRatio,
        uint256 _issuanceRatio,
        uint256 _issueFeeRate,
        uint256 _minLoanCollateralSize,
        uint256 _totalIssuedSynths,
        uint256 _totalLoansCreated,
        uint256 _totalOpenLoanCount,
        uint256 _ethBalance
    )
    {
        _collateralizationRatio = collateralizationRatio;
        _issuanceRatio = issuanceRatio();
        _issueFeeRate = issueFeeRate;
        _minLoanCollateralSize = minLoanCollateralSize;
        _totalIssuedSynths = totalIssuedSynths;
        _totalLoansCreated = totalLoansCreated;
        _totalOpenLoanCount = totalOpenLoanCount;
        _ethBalance = address(this).balance;
    }

    /**
     * @dev Gets the value of of 100 / collateralizationRatio.
     * e.g. 100/150 = 0.6666666667
     *
    */
    function issuanceRatio() public view returns (uint256) {
        // this rounds so you get slightly more rather than slightly less
        return ONE_HUNDRED.divideDecimalRound(collateralizationRatio);
    }

    /**
     * @dev Gets the amount of synths which can be issued given a certain loan amount
     *
     * @param collateralAmount the given ETH amount
     * @return the amount of synths which can be minted with the given collateral amount
    */
    function loanAmountFromCollateral(uint256 collateralAmount) public view returns (uint256) {
        return collateralAmount
        .multiplyDecimal(issuanceRatio())
        .multiplyDecimal(syntharb().getLatestETHUSDPrice())
        .divideDecimal(syntharb().getLatestPrice());
    }

    /**
     * @dev Gets the collateral amount needed (in ETH) to mint a given amount of synths
     *
     * @param loanAmount the given loan amount
     * @return the amount of collateral (in ETH) needed to open a loan for the synth amount
    */
    function collateralAmountForLoan(uint256 loanAmount) public view returns (uint256) {
        return
        loanAmount
        .multiplyDecimal(collateralizationRatio
        .divideDecimalRound(syntharb().getLatestETHUSDPrice())
        .multiplyDecimal(syntharb().getLatestPrice()))
        .divideDecimalRound(ONE_HUNDRED);
    }

    /**
     * @dev Gets the minting fee given the account address and the loanID
     *
     * @param _account the opener of the loan
     * @param _loanID the loan id
     * @return the minting fee of the loan
    */
    function getMintingFee(address _account, uint256 _loanID) external view returns (uint256) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        return synthLoan.mintingFee;
    }

    /**
    * @dev Gets the amount to liquidate which can potentially fix the c ratio given this formula:
     * r = target issuance ratio
     * D = debt balance
     * V = Collateral
     * P = liquidation penalty
     * Calculates amount of synths = (D - V * r) / (1 - (1 + P) * r)
     *
     * If the C-Ratio is greater than Liquidation Ratio + Penalty in % then the C-Ratio can be fixed
     * otherwise a greater number is returned and the debtToCover from the calling function is used
     *
     * @param debtBalance the amount of the loan or debt to calculate in USD
     * @param collateral the amount of the collateral in USD
     *
     * @return the amount to liquidate to fix the C-Ratio if possible
     */
    function calculateAmountToLiquidate(uint debtBalance, uint collateral) public view returns (uint) {
        uint unit = SafeDecimalMath.unit();

        uint dividend = debtBalance.sub(collateral.divideDecimal(liquidationRatio));
        uint divisor = unit.sub(unit.add(liquidationPenalty).divideDecimal(liquidationRatio));

        return dividend.divideDecimal(divisor);
    }

    /**
     * @dev Gets all open loans by a given account address
     *
     * @param _account the opener of the loans
     * @return all open loans by ID in form of an array
    */
    function getOpenLoanIDsByAccount(address _account) external view returns (uint256[] memory) {
        SynthLoanStruct[] memory synthLoans = accountsSynthLoans[_account];

        uint256[] memory _openLoanIDs = new uint256[](synthLoans.length);
        uint256 j;

        for (uint i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].timeClosed == 0) {
                _openLoanIDs[j++] = synthLoans[i].loanID;
            }
        }

        // Change the list size of the array in place
        assembly {
            mstore(_openLoanIDs, j)
        }

        // Return the resized array
        return _openLoanIDs;
    }

    /**
     * @dev Gets all details about a certain loan
     *
     * @param _account the opener of the loans
     * @param _loanID the ID of a given loan
     * @return account the opener of the loan
     * @return collateralAmount the amount of collateral in ETH
     * @return loanAmount the loan amount
     * @return timeCreated the time the loan was initially created
     * @return loanID the ID of the loan
     * @return timeClosed the closure time of the loan (if closed)
     * @return totalFees the minting fee of the loan
    */
    function getLoan(address _account, uint256 _loanID)
    external
    view
    returns (
        address account,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 timeCreated,
        uint256 loanID,
        uint256 timeClosed,
        uint256 totalFees
    )
    {
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);
        account = synthLoan.account;
        collateralAmount = synthLoan.collateralAmount;
        loanAmount = synthLoan.loanAmount;
        timeCreated = synthLoan.timeCreated;
        loanID = synthLoan.loanID;
        timeClosed = synthLoan.timeClosed;
        totalFees = synthLoan.mintingFee;
    }

    /**
     * @dev Gets the current C-Ratio of a loan
     *
     * @param _account the opener of the loan
     * @param _loanID the loan ID
     * @return loanCollateralRatio the current C-Ratio of the loan
    */
    function getLoanCollateralRatio(address _account, uint256 _loanID) external view returns (uint256 loanCollateralRatio) {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_account, _loanID);

        (loanCollateralRatio,  ) = _loanCollateralRatio(synthLoan);
    }

    /**
     * @dev Gets the current C-Ratio of a loan by _loan struct
     *
     * @param _loan the loan struct
     * @return loanCollateralRatio the current C-Ratio of the loan
     * @return collateralValue the current value of the collateral in USD
    */
    function _loanCollateralRatio(SynthLoanStruct memory _loan)
    internal
    view
    returns (
        uint256 loanCollateralRatio,
        uint256 collateralValue
    )
    {
        uint256 loanAmountWithAccruedInterest = _loan.loanAmount.multiplyDecimal(syntharb().getLatestPrice());

        collateralValue = _loan.collateralAmount.multiplyDecimal(syntharb().getLatestETHUSDPrice());
        loanCollateralRatio = collateralValue.divideDecimal(loanAmountWithAccruedInterest);
    }


    // ========== PUBLIC FUNCTIONS ==========

    /**
     * @dev Public function to open a new loan in the system
     *
     * @param _loanAmount the amount of synths a user wants to take a loan for
     * @return loanID the ID of the newly created loan
    */
    function openLoan(uint256 _loanAmount)
    external
    payable
    nonReentrant
    returns (uint256 loanID) {
        // asset must be open
        require(!assetClosed, "Asset closed");
        // Require ETH sent to be greater than minLoanCollateralSize
        require(
            msg.value >= minLoanCollateralSize,
            "Not enough ETH to create this loan. Please see the minLoanCollateralSize"
        );

        // Each account is limited to creating 50 (accountLoanLimit) loans
        require(accountsSynthLoans[msg.sender].length < accountLoanLimit, "Each account is limited to 50 loans");

        // Calculate issuance amount based on issuance ratio
        syntharb().updatePrice();
        uint256 maxLoanAmount = loanAmountFromCollateral(msg.value);

        // Require requested _loanAmount to be less than maxLoanAmount
        // Issuance ratio caps collateral to loan value at 120%
        require(_loanAmount <= maxLoanAmount, "Loan amount exceeds max borrowing power");

        uint256 ethForLoan = collateralAmountForLoan(_loanAmount);
        uint256 mintingFee = _calculateMintingFee(msg.value);
        require(msg.value >= ethForLoan + mintingFee, "Not enough funds sent to cover fee and collateral");

        // Get a Loan ID
        loanID = _incrementTotalLoansCounter();

        // Create Loan storage object
        SynthLoanStruct memory synthLoan = SynthLoanStruct({
        account: msg.sender,
        collateralAmount: msg.value - mintingFee,
        loanAmount: _loanAmount,
        mintingFee: mintingFee,
        timeCreated: block.timestamp,
        loanID: loanID,
        timeClosed: 0
        });

        // Record loan in mapping to account in an array of the accounts open loans
        accountsSynthLoans[msg.sender].push(synthLoan);

        // Increment totalIssuedSynths
        totalIssuedSynths = totalIssuedSynths.add(_loanAmount);

        // Issue the synth (less fee)
        syntharb().mint(msg.sender, _loanAmount);
        
        // Tell the Dapps a loan was created
        emit LoanCreated(msg.sender, loanID, _loanAmount);

        // Fee distribution. Mint the fees into the FeePool and record fees paid
        if (mintingFee > 0) {
            // conjureRouter gets 25% of the fee
            address payable conjureRouter = IConjureFactory(_factoryContract).getConjureRouter();
            uint256 feeToSend = mintingFee / 4;

            IConjureRouter(conjureRouter).deposit{value:feeToSend}();
            arbasset.transfer(mintingFee.sub(feeToSend));
        }
    }

    /**
     * @dev Function to close a loan
     * calls the internal _closeLoan function with the false parameter for liquidation
     * to mark it as a non liquidation close
     *
     * @param loanID the ID of the loan a user wants to close
    */
    function closeLoan(uint256 loanID) external nonReentrant  {
        _closeLoan(msg.sender, loanID, false);
    }

    /**
     * @dev Add ETH collateral to an open loan
     *
     * @param account the opener of the loan
     * @param loanID the ID of the loan
    */
    function depositCollateral(address account, uint256 loanID) external payable {
        // asset must be open
        require(!assetClosed, "Asset closed for deposit collateral");
        require(msg.value > 0, "Deposit amount must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 totalCollateral = synthLoan.collateralAmount.add(msg.value);

        _updateLoanCollateral(synthLoan, totalCollateral);

        // Tell the Dapps collateral was added to loan
        emit CollateralDeposited(account, loanID, msg.value, totalCollateral);
    }

    /**
     * @dev Withdraw ETH collateral from an open loan
     * the C-Ratio after should not be less than the Liquidation Ratio
     *
     * @param loanID the ID of the loan
     * @param withdrawAmount the amount to withdraw from the current collateral
    */
    function withdrawCollateral(uint256 loanID, uint256 withdrawAmount) external nonReentrant  {
        require(withdrawAmount > 0, "Amount to withdraw must be greater than 0");

        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(msg.sender, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 collateralAfter = synthLoan.collateralAmount.sub(withdrawAmount);

        SynthLoanStruct memory loanAfter = _updateLoanCollateral(synthLoan, collateralAfter);

        // require collateral ratio after to be above the liquidation ratio
        (uint256 collateralRatioAfter, ) = _loanCollateralRatio(loanAfter);

        require(collateralRatioAfter > liquidationRatio, "Collateral ratio below liquidation after withdraw");
        
        // Tell the Dapps collateral was added to loan
        emit CollateralWithdrawn(msg.sender, loanID, withdrawAmount, loanAfter.collateralAmount);

        // transfer ETH to msg.sender
        msg.sender.transfer(withdrawAmount);
    }

    /**
     * @dev Repay synths to fix C-Ratio
     *
     * @param _loanCreatorsAddress the address of the loan creator
     * @param _loanID the ID of the loan
     * @param _repayAmount the amount of synths to be repaid
    */
    function repayLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _repayAmount
    ) external  {
        // check msg.sender has sufficient funds to pay
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _repayAmount, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        uint256 loanAmountAfter = synthLoan.loanAmount.sub(_repayAmount);

        // burn funds from msg.sender for repaid amount
        syntharb().burn(msg.sender, _repayAmount);

        // decrease issued synths
        totalIssuedSynths = totalIssuedSynths.sub(_repayAmount);

        // update loan with new total loan amount, record accrued interests
        _updateLoan(synthLoan, loanAmountAfter);

        emit LoanRepaid(_loanCreatorsAddress, _loanID, _repayAmount, loanAmountAfter);
    }

    /**
     * @dev Liquidate loans at or below issuance ratio
     * if the liquidation amount is greater or equal to the owed amount it will also trigger a closure of the loan
     *
     * @param _loanCreatorsAddress the address of the loan creator
     * @param _loanID the ID of the loan
     * @param _debtToCover the amount of synths the liquidator wants to cover
    */
    function liquidateLoan(
        address _loanCreatorsAddress,
        uint256 _loanID,
        uint256 _debtToCover
    ) external nonReentrant  {
        // check msg.sender (liquidator's wallet) has sufficient
        require(IERC20(address(syntharb())).balanceOf(msg.sender) >= _debtToCover, "Not enough balance");

        SynthLoanStruct memory synthLoan = _getLoanFromStorage(_loanCreatorsAddress, _loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        (uint256 collateralRatio, uint256 collateralValue) = _loanCollateralRatio(synthLoan);

        // get prices
        syntharb().updatePrice();
        uint currentPrice = syntharb().getLatestPrice();
        uint currentEthUsdPrice = syntharb().getLatestETHUSDPrice();

        require(collateralRatio < liquidationRatio, "Collateral ratio above liquidation ratio");

        // calculate amount to liquidate to fix ratio including accrued interest
        // multiply the loan amount times current price in usd
        // collateralValue is already in usd nomination
        uint256 liquidationAmountUSD = calculateAmountToLiquidate(
            synthLoan.loanAmount.multiplyDecimal(currentPrice),
            collateralValue
        );

        // calculate back the synth amount from the usd nomination
        uint256 liquidationAmount = liquidationAmountUSD.divideDecimal(currentPrice);

        // cap debt to liquidate
        uint256 amountToLiquidate = liquidationAmount < _debtToCover ? liquidationAmount : _debtToCover;

        // burn funds from msg.sender for amount to liquidate
        syntharb().burn(msg.sender, amountToLiquidate);

        // decrease issued totalIssuedSynths
        totalIssuedSynths = totalIssuedSynths.sub(amountToLiquidate);

        // Collateral value to redeem in ETH
        uint256 collateralRedeemed = amountToLiquidate.multiplyDecimal(currentPrice).divideDecimal(currentEthUsdPrice);

        // Add penalty in ETH
        uint256 totalCollateralLiquidated = collateralRedeemed.multiplyDecimal(
            SafeDecimalMath.unit().add(liquidationPenalty)
        );

        // update remaining loanAmount less amount paid and update accrued interests less interest paid
        _updateLoan(synthLoan, synthLoan.loanAmount.sub(amountToLiquidate));

        // indicates if we need a full closure
        bool close;

        if (synthLoan.collateralAmount <= totalCollateralLiquidated) {
            close = true;
            // update remaining collateral on loan
            _updateLoanCollateral(synthLoan, 0);
            totalCollateralLiquidated = synthLoan.collateralAmount;
        }
        else {
            // update remaining collateral on loan
            _updateLoanCollateral(synthLoan, synthLoan.collateralAmount.sub(totalCollateralLiquidated));
        }

        // check if we have a full closure here
        if (close) {
            // emit loan liquidation event
            emit LoanLiquidated(
                _loanCreatorsAddress,
                _loanID,
                msg.sender
            );
            _closeLoan(synthLoan.account, synthLoan.loanID, true);
        } else {
            // emit loan liquidation event
            emit LoanPartiallyLiquidated(
                _loanCreatorsAddress,
                _loanID,
                msg.sender,
                amountToLiquidate,
                totalCollateralLiquidated
            );
        }

        // Send liquidated ETH collateral to msg.sender
        msg.sender.transfer(totalCollateralLiquidated);
    }

    // ========== PRIVATE FUNCTIONS ==========

    /**
     * @dev Internal function to close open loans
     *
     * @param account the account which opened the loan
     * @param loanID the ID of the loan to close
     * @param liquidation bool representing if its a user close or a liquidation close
    */
    function _closeLoan(
        address account,
        uint256 loanID,
        bool liquidation
    ) private {
        // Get the loan from storage
        SynthLoanStruct memory synthLoan = _getLoanFromStorage(account, loanID);

        // Check loan exists and is open
        _checkLoanIsOpen(synthLoan);

        // Record loan as closed
        _recordLoanClosure(synthLoan);

        if (!liquidation) {
            uint256 repayAmount = synthLoan.loanAmount;

            require(
                IERC20(address(syntharb())).balanceOf(msg.sender) >= repayAmount,
                "You do not have the required Synth balance to close this loan."
            );

            // Decrement totalIssuedSynths
            totalIssuedSynths = totalIssuedSynths.sub(synthLoan.loanAmount);

            // Burn all Synths issued for the loan + the fees
            syntharb().burn(msg.sender, repayAmount);
        }

        uint256 remainingCollateral = synthLoan.collateralAmount;

        // Tell the Dapps
        emit LoanClosed(account, loanID);

        // Send remaining collateral to loan creator
        synthLoan.account.transfer(remainingCollateral);
    }

    /**
     * @dev gets a loan struct from the storage
     *
     * @param account the account which opened the loan
     * @param loanID the ID of the loan to close
     * @return synthLoan the loan struct given the input parameters
    */
    function _getLoanFromStorage(address account, uint256 loanID) private view returns (SynthLoanStruct memory synthLoan) {
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == loanID) {
                synthLoan = synthLoans[i];
                break;
            }
        }
    }

    /**
     * @dev updates the loan amount of a loan
     *
     * @param _synthLoan the synth loan struct representing the loan
     * @param _newLoanAmount the new loan amount to update the loan
    */
    function _updateLoan(
        SynthLoanStruct memory _synthLoan,
        uint256 _newLoanAmount
    ) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].loanAmount = _newLoanAmount;
            }
        }
    }

    /**
     * @dev updates the collateral amount of a loan
     *
     * @param _synthLoan the synth loan struct representing the loan
     * @param _newCollateralAmount the new collateral amount to update the loan
     * @return synthLoan the loan struct given the input parameters
    */
    function _updateLoanCollateral(SynthLoanStruct memory _synthLoan, uint256 _newCollateralAmount)
    private
    returns (SynthLoanStruct memory synthLoan) {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[_synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == _synthLoan.loanID) {
                synthLoans[i].collateralAmount = _newCollateralAmount;
                synthLoan = synthLoans[i];
            }
        }
    }

    /**
     * @dev records the closure of a loan
     *
     * @param synthLoan the synth loan struct representing the loan
    */
    function _recordLoanClosure(SynthLoanStruct memory synthLoan) private {
        // Get storage pointer to the accounts array of loans
        SynthLoanStruct[] storage synthLoans = accountsSynthLoans[synthLoan.account];
        for (uint256 i = 0; i < synthLoans.length; i++) {
            if (synthLoans[i].loanID == synthLoan.loanID) {
                // Record the time the loan was closed
                synthLoans[i].timeClosed = block.timestamp;
            }
        }

        // Reduce Total Open Loans Count
        totalOpenLoanCount = totalOpenLoanCount.sub(1);
    }

    /**
     * @dev Increments all global counters after a loan creation
     *
     * @return the amount of total loans created
    */
    function _incrementTotalLoansCounter() private returns (uint256) {
        // Increase the total Open loan count
        totalOpenLoanCount = totalOpenLoanCount.add(1);
        // Increase the total Loans Created count
        totalLoansCreated = totalLoansCreated.add(1);
        // Return total count to be used as a unique ID.
        return totalLoansCreated;
    }

    /**
     * @dev calculates the minting fee given the 100+ x% of eth collateral and returns x
     * e.g. input 1.02 ETH fee is set to 2% returns 0.02 ETH as the minting fee
     *
     * @param _ethAmount the amount of eth of the collateral
     * @param mintingFee the fee which is being distributed to the creator and the factory
    */
    function _calculateMintingFee(uint256 _ethAmount) private view returns (uint256 mintingFee) {
        if (issueFeeRate == 0) {
            mintingFee = 0;
        } else {
            mintingFee = _ethAmount.divideDecimalRound(10000 + issueFeeRate).multiplyDecimal(issueFeeRate);
        }

    }

    /**
     * @dev checks if a loan is pen in the system
     *
     * @param _synthLoan the synth loan struct representing the loan
    */
    function _checkLoanIsOpen(SynthLoanStruct memory _synthLoan) internal pure {
        require(_synthLoan.loanID > 0, "Loan does not exist");
        require(_synthLoan.timeClosed == 0, "Loan already closed");
    }

    /* ========== INTERNAL VIEWS ========== */

    /**
     * @dev Gets the interface of the synthetic asset
    */
    function syntharb() internal view returns (IConjure) {
        return IConjure(arbasset);
    }
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
 pragma solidity 0.7.6;

// Libraries
import "@openzeppelin/contracts/math/SafeMath.sol";


// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjure
/// @notice Interface for interacting with the Conjure Contracts
interface IConjure {
    /**
     * @dev lets the EtherCollateral contract instance burn synths
     *
     * @param account the account address where the synths should be burned
     * @param amount the amount to be burned
    */
    function burn(address account, uint amount) external;

    /**
     * @dev lets the EtherCollateral contract instance mint new synths
     *
     * @param account the account address where the synths should be minted to
     * @param amount the amount to be minted
    */
    function mint(address account, uint amount) external;

    /**
     * @dev gets the latest ETH USD Price from the given oracle
     *
     * @return the current eth usd price
    */
    function getLatestETHUSDPrice() external view returns (uint);

    /**
     * @dev sets the latest price of the synth in USD by calculation
    */
    function updatePrice() external;

    /**
     * @dev gets the latest recorded price of the synth in USD
     *
     * @return the last recorded synths price
    */
    function getLatestPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureFactory
/// @notice Interface for interacting with the ConjureFactory Contract
interface IConjureFactory {

    /**
     * @dev gets the current conjure router
     *
     * @return the current conjure router
    */
    function getConjureRouter() external returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/// @author Conjure Finance Team
/// @title IConjureRouter
/// @notice Interface for interacting with the ConjureRouter Contract
interface IConjureRouter {

    /**
     * @dev calls the deposit function
    */
    function deposit() external payable;
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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
  "libraries": {
    "contracts/SafeDecimalMath.sol": {
      "SafeDecimalMath": "0x8afbec6329faaaa1e267052210104b3d3ab0c163"
    }
  }
}