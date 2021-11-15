// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '../interfaces/IPoolFactory.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/IYield.sol';
import '../interfaces/IRepayment.sol';
import '../interfaces/ISavingsAccount.sol';
import '../SavingsAccount/SavingsAccountUtil.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IExtension.sol';
import '../interfaces/IPoolToken.sol';
import '../interfaces/IVerification.sol';

/**
 * @title Pool contract with Methods related to Pool
 * @notice Implements the functions related to Pool
 * @author Sublime
 */
contract Pool is Initializable, IPool, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum LoanStatus {
        COLLECTION, //denotes collection period
        ACTIVE, // denotes the active loan
        CLOSED, // Loan is repaid and closed
        CANCELLED, // Cancelled by borrower
        DEFAULTED, // Repayment defaulted by  borrower
        TERMINATED // Pool terminated by admin
    }

    address PoolFactory;

    /**
     * @notice instance of IPooltoken
     */
    IPoolToken public poolToken;

    struct LendingDetails {
        uint256 interestWithdrawn;
        uint256 marginCallEndTime;
        uint256 extraLiquidityShares;
    }

    // Pool constants
    struct PoolConstants {
        address borrower;
        uint256 borrowAmountRequested;
        uint256 loanStartTime;
        uint256 loanWithdrawalDeadline;
        address borrowAsset;
        uint256 idealCollateralRatio;
        uint256 volatilityThreshold;
        uint256 borrowRate;
        uint256 noOfRepaymentIntervals;
        uint256 repaymentInterval;
        address collateralAsset;
        address poolSavingsStrategy; // invest contract
        address lenderVerifier;
    }

    struct PoolVars {
        uint256 baseLiquidityShares;
        uint256 extraLiquidityShares;
        LoanStatus loanStatus;
        uint256 penaltyLiquidityAmount;
    }

    /**
     * @notice used to keep track of lenders' details
     */
    mapping(address => LendingDetails) public lenders;

    /**
     * @notice object of type PoolConstants
     */
    PoolConstants public poolConstants;

    /**
     * @notice object of type PoolVars
     */
    PoolVars public poolVars;

    /**
     * @notice Emitted when pool is cancelled either on borrower request or insufficient funds collected
     */
    event PoolCancelled();

    /**
     * @notice Emitted when pool is terminated by admin
     */
    event PoolTerminated();

    /**
     * @notice Emitted when pool is closed after repayments are complete
     */
    event PoolClosed();

    // borrower and sharesReceived might not be necessary

    /**
     * @notice emitted when borrower posts collateral
     * @param borrower address of the borrower
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event CollateralAdded(address borrower, uint256 amount, uint256 sharesReceived);

    // borrower and sharesReceived might not be necessary

    /**
     * @notice emitted when borrower posts collateral after a margin call
     * @param borrower address of the borrower
     * @param lender lender who margin called
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event MarginCallCollateralAdded(address borrower, address lender, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower withdraws excess collateral
     * @param borrower address of borrower
     * @param amount amount of collateral withdrawn
     */
    event CollateralWithdrawn(address borrower, uint256 amount);

    /**
     * @notice emitted when lender supplies liquidity to a pool
     * @param amountSupplied amount that was supplied
     * @param lenderAddress address of the lender. allows for delegation of lending
     */
    event LiquiditySupplied(uint256 amountSupplied, address lenderAddress);

    /**
     * @notice emitted when borrower withdraws loan
     * @param amount tokens the borrower withdrew
     */
    event AmountBorrowed(uint256 amount);

    /**
     * @notice emitted when lender withdraws from borrow pool
     * @param amount amount that lender withdraws from borrow pool
     * @param lenderAddress address to which amount is withdrawn
     */
    event LiquidityWithdrawn(uint256 amount, address lenderAddress);

    /**
     * @notice emitted when lender exercises a margin/collateral call
     * @param lenderAddress address of the lender who exercises margin calls
     */
    event MarginCalled(address lenderAddress);

    /**
     * @notice emitted when collateral backing lender is liquidated because of a margin call
     * @param liquidator address that calls the liquidateForLender() function
     * @param lender lender who initially exercised the margin call
     * @param _tokenReceived amount received by liquidator denominated in collateral asset
     */
    event LenderLiquidated(address liquidator, address lender, uint256 _tokenReceived);

    /**
     * @notice emitted when a pool is liquidated for missing repayment
     * @param liquidator address of the liquidator
     */
    event PoolLiquidated(address liquidator);

    /**
     * @notice checks if the _user is pool's valid borrower
     * @param _user address of the borrower
     */
    modifier onlyBorrower(address _user) {
        require(_user == poolConstants.borrower, '1');
        _;
    }

    /**
     * @notice checks if the _lender is pool's valid lender
     * @param _lender address of the lender
     */
    modifier isLender(address _lender) {
        require(poolToken.balanceOf(_lender) != 0, '2');
        _;
    }

    /**
     * @notice checks if the msg.sender is pool's valid owner
     */
    modifier onlyOwner() {
        require(msg.sender == IPoolFactory(PoolFactory).owner(), '3');
        _;
    }

    /**
     * @notice checks if the msg.sender is pool's latest extension implementation
     */
    modifier onlyExtension() {
        require(msg.sender == IPoolFactory(PoolFactory).extension(), '5');
        _;
    }

    /**
     * @notice checks if the msg.sender is pool's latest repayment implementation
     */
    modifier OnlyRepaymentImpl() {
        require(msg.sender == IPoolFactory(PoolFactory).repaymentImpl(), '25');
        _;
    }

    /**
     * @notice initializing the pool and adding initial collateral
     * @param _borrowAmountRequested the amount of borrow asset requested by the borrower
     * @param _volatilityThreshold Maximum volatility that collateral ratio can go down before liquidation
     * @param _borrower address of the borrower
     * @param _borrowAsset address of the borrow asset
     * @param _collateralAsset address of the collateral asset
     * @param _idealCollateralRatio the ideal collateral ratio of the pool
     * @param _borrowRate the borrow rate as specified by borrower
     * @param _repaymentInterval the interval between to repayments
     * @param _noOfRepaymentIntervals number of repayments to be done by borrower
     * @param _poolSavingsStrategy address of the savings strategy preferred
     * @param _collateralAmount amount of collateral to be deposited by the borrower
     * @param _transferFromSavingsAccount if true, collateral is transferred from msg.sender's savings account, if false, it is transferred from their wallet
     * @param _loanWithdrawalDuration time interval for the borrower to withdraw the lent amount in borrow asset
     * @param _collectionPeriod time interval where lender lend into the borrow pool
     */
    function initialize(
        uint256 _borrowAmountRequested,
        uint256 _borrowRate,
        address _borrower,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _idealCollateralRatio,
        uint256 _volatilityThreshold,
        uint256 _repaymentInterval,
        uint256 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        uint256 _loanWithdrawalDuration,
        uint256 _collectionPeriod
    ) external payable initializer {
        PoolFactory = msg.sender;
        poolConstants.borrowAsset = _borrowAsset;
        poolConstants.idealCollateralRatio = _idealCollateralRatio;
        poolConstants.volatilityThreshold = _volatilityThreshold;
        poolConstants.collateralAsset = _collateralAsset;
        poolConstants.poolSavingsStrategy = _poolSavingsStrategy;
        poolConstants.borrowAmountRequested = _borrowAmountRequested;
        _initialDeposit(_borrower, _collateralAmount, _transferFromSavingsAccount);
        poolConstants.borrower = _borrower;
        poolConstants.borrowRate = _borrowRate;
        poolConstants.noOfRepaymentIntervals = _noOfRepaymentIntervals;
        poolConstants.repaymentInterval = _repaymentInterval;

        poolConstants.loanStartTime = block.timestamp.add(_collectionPeriod);
        poolConstants.loanWithdrawalDeadline = block.timestamp.add(_collectionPeriod).add(_loanWithdrawalDuration);
    }

    /*
     * @notice Each pool has a unique pool token deployed by PoolFactory, lender verifier to filter lender is also set by PoolFactory
     * @param _poolToken address of the PoolToken contract deployed for a loan request
     * @param _lenderVerifier address of the verifier with which lender should be verified
     */
    function setConstants(address _poolToken, address _lenderVerifier) external override {
        require(msg.sender == PoolFactory, '6');
        poolConstants.lenderVerifier = _lenderVerifier;
        poolToken = IPoolToken(_poolToken);
    }

    /**
     * @notice add collateral to a pool
     * @param _amount amount of collateral to be deposited denominated in collateral aseset
     * @param _transferFromSavingsAccount if true, collateral is transferred from msg.sender's savings account, if false, it is transferred from their wallet
     */
    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) public payable override {
        require(_amount != 0, '7');
        _depositCollateral(msg.sender, _amount, _transferFromSavingsAccount);
    }

    /**
     * @notice called when borrow pool is initialized to make initial collateral deposit
     * @param _borrower address of the borrower
     * @param _amount amount of collateral getting deposited denominated in collateral asset
     * @param _transferFromSavingsAccount if true, collateral is transferred from msg.sender's savings account, if false, it is transferred from their wallet
     */
    function _initialDeposit(
        address _borrower,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) internal {
        uint256 _equivalentCollateral = getEquivalentTokens(
            poolConstants.borrowAsset,
            poolConstants.collateralAsset,
            poolConstants.borrowAmountRequested
        );
        require(_amount >= poolConstants.idealCollateralRatio.mul(_equivalentCollateral).div(1e30), '36');
        _depositCollateral(_borrower, _amount, _transferFromSavingsAccount);
    }

    /**
     * @notice internal function used to deposit collateral from _borrower to pool
     * @param _depositor address transferring the collateral
     * @param _amount amount of collateral to be transferred denominated in collateral asset
     * @param _transferFromSavingsAccount if true, collateral is transferred from _sender's savings account, if false, it is transferred from _sender's wallet
     */
    function _depositCollateral(
        address _depositor,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) internal nonReentrant {
        uint256 _sharesReceived = _deposit(
            _transferFromSavingsAccount,
            true,
            poolConstants.collateralAsset,
            _amount,
            poolConstants.poolSavingsStrategy,
            _depositor,
            address(this)
        );
        poolVars.baseLiquidityShares = poolVars.baseLiquidityShares.add(_sharesReceived);
        emit CollateralAdded(_depositor, _amount, _sharesReceived);
    }

    /**
     * @notice internal function used to get amount of collateral deposited to the pool
     * @param _fromSavingsAccount if true, collateral is transferred from _sender's savings account, if false, it is transferred from _sender's wallet
     * @param _toSavingsAccount if true, collateral is transferred to pool's savings account, if false, it is withdrawn from _sender's savings account
     * @param _asset address of the asset to be deposited
     * @param _amount amount of tokens to be deposited in the pool
     * @param _poolSavingsStrategy address of the saving strategy used for collateral deposit
     * @param _depositFrom address which makes the deposit
     * @param _depositTo address to which the tokens are deposited
     * @return _sharesReceived number of equivalent shares for given _asset
     */
    function _deposit(
        bool _fromSavingsAccount,
        bool _toSavingsAccount,
        address _asset,
        uint256 _amount,
        address _poolSavingsStrategy,
        address _depositFrom,
        address _depositTo
    ) internal returns (uint256 _sharesReceived) {
        if (_fromSavingsAccount) {
            _sharesReceived = SavingsAccountUtil.depositFromSavingsAccount(
                ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount()),
                _depositFrom,
                _depositTo,
                _amount,
                _asset,
                _poolSavingsStrategy,
                true,
                _toSavingsAccount
            );
        } else {
            _sharesReceived = SavingsAccountUtil.directDeposit(
                ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount()),
                _depositFrom,
                _depositTo,
                _amount,
                _asset,
                _toSavingsAccount,
                _poolSavingsStrategy
            );
        }
    }

    /**
     * @notice used to add extra collateral deposit during margin calls
     * @param _lender the address of the _lender who has requested for margin call
     * @param _amount amount of tokens requested for the margin call
     * @param _transferFromSavingsAccount if true, collateral is transferred from borrower's savings account, if false, it is transferred from borrower's wallet
     */
    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) external payable override nonReentrant {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, '9');

        require(getMarginCallEndTime(_lender) >= block.timestamp, '10');

        require(_amount != 0, '11');

        uint256 _sharesReceived = _deposit(
            _transferFromSavingsAccount,
            true,
            poolConstants.collateralAsset,
            _amount,
            poolConstants.poolSavingsStrategy,
            msg.sender,
            address(this)
        );

        poolVars.extraLiquidityShares = poolVars.extraLiquidityShares.add(_sharesReceived);

        lenders[_lender].extraLiquidityShares = lenders[_lender].extraLiquidityShares.add(_sharesReceived);

        if (getCurrentCollateralRatio(_lender) >= poolConstants.idealCollateralRatio) {
            delete lenders[_lender].marginCallEndTime;
        }

        emit MarginCallCollateralAdded(msg.sender, _lender, _amount, _sharesReceived);
    }

    /**
     * @notice used by the borrower to withdraw tokens from the pool when loan is active
     */
    function withdrawBorrowedAmount() external override onlyBorrower(msg.sender) nonReentrant {
        LoanStatus _poolStatus = poolVars.loanStatus;
        uint256 _tokensLent = poolToken.totalSupply();
        require(
            _poolStatus == LoanStatus.COLLECTION &&
                poolConstants.loanStartTime < block.timestamp &&
                block.timestamp < poolConstants.loanWithdrawalDeadline,
            '12'
        );
        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        require(_tokensLent >= _poolFactory.minBorrowFraction().mul(poolConstants.borrowAmountRequested).div(10**30), '13');

        poolVars.loanStatus = LoanStatus.ACTIVE;
        uint256 _currentCollateralRatio = getCurrentCollateralRatio();
        require(
            _currentCollateralRatio >=
                poolConstants.idealCollateralRatio.sub(poolConstants.volatilityThreshold),
            '14'
        );

        uint256 _noOfRepaymentIntervals = poolConstants.noOfRepaymentIntervals;
        uint256 _repaymentInterval = poolConstants.repaymentInterval;
        IRepayment(_poolFactory.repaymentImpl()).initializeRepayment(
            _noOfRepaymentIntervals,
            _repaymentInterval,
            poolConstants.borrowRate,
            poolConstants.loanStartTime,
            poolConstants.borrowAsset
        );
        IExtension(_poolFactory.extension()).initializePoolExtension(_repaymentInterval);

        address _borrowAsset = poolConstants.borrowAsset;
        (uint256 _protocolFeeFraction, address _collector) = _poolFactory.getProtocolFeeData();
        uint256 _protocolFee = _tokensLent.mul(_protocolFeeFraction).div(10**30);
        delete poolConstants.loanWithdrawalDeadline;

        SavingsAccountUtil.transferTokens(_borrowAsset, _protocolFee, address(this), _collector);
        SavingsAccountUtil.transferTokens(_borrowAsset, _tokensLent.sub(_protocolFee), address(this), msg.sender);

        emit AmountBorrowed(_tokensLent);
    }

    /**
     * @notice internal function used to withdraw all collateral tokens from the pool (minus penalty)
     * @param _receiver address which receives all the collateral tokens
     * @param _penalty amount of penalty incurred by the borrower when pool is cancelled
     */
    function _withdrawAllCollateral(address _receiver, uint256 _penalty) internal {
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        address _collateralAsset = poolConstants.collateralAsset;
        uint256 _collateralShares = 0;
        if (poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares) > _penalty) {
            _collateralShares = poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares).sub(_penalty);
        }
        uint256 _collateralTokens = _collateralShares;
        if (_poolSavingsStrategy != address(0)) {
            _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralShares, _collateralAsset);
        }
        poolVars.baseLiquidityShares = _penalty;
        delete poolVars.extraLiquidityShares;

        uint256 _sharesReceived;
        if (_collateralShares != 0) {
            ISavingsAccount _savingsAccount = ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount());
            _sharesReceived = SavingsAccountUtil.savingsAccountTransfer(
                _savingsAccount,
                address(this),
                _receiver,
                _collateralTokens,
                _collateralAsset,
                _poolSavingsStrategy
            );
        }
        emit CollateralWithdrawn(_receiver, _sharesReceived);
    }

    /**
     * @notice used by lender to supply liquidity to a borrow pool
     * @param _lender address of the lender
     * @param _amount amount of liquidity supplied by the _lender
     * @param _fromSavingsAccount if true, collateral is transferred from _lender's savings account, if false, it is transferred from _lender's wallet
     */
    function lend(
        address _lender,
        uint256 _amount,
        bool _fromSavingsAccount
    ) external payable nonReentrant {
        address _lenderVerifier = poolConstants.lenderVerifier;
        if (_lenderVerifier != address(0)) {
            require(IVerification(IPoolFactory(PoolFactory).userRegistry()).isUser(_lender, _lenderVerifier), 'invalid lender');
        }
        require(poolVars.loanStatus == LoanStatus.COLLECTION, '15');
        require(block.timestamp < poolConstants.loanStartTime, '16');
        uint256 _borrowAmountNeeded = poolConstants.borrowAmountRequested;
        uint256 _lentAmount = poolToken.totalSupply();
        if (_amount.add(_lentAmount) > _borrowAmountNeeded) {
            _amount = _borrowAmountNeeded.sub(_lentAmount);
        }

        address _borrowToken = poolConstants.borrowAsset;
        _deposit(_fromSavingsAccount, false, _borrowToken, _amount, address(0), msg.sender, address(this));
        poolToken.mint(_lender, _amount);
        emit LiquiditySupplied(_amount, _lender);
    }

    /**
     * @notice used to transfer borrow pool tokens among lenders
     * @param _from address of the lender who sends the borrow pool tokens
     * @param _to addres of the lender who receives the borrow pool tokens
     * @param _amount amount of borrow pool tokens transfered
     */
    function beforeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public override nonReentrant {
        require(msg.sender == address(poolToken));
        require(getMarginCallEndTime(_from) == 0, '18');
        require(getMarginCallEndTime(_to) == 0, '19');

        //Withdraw repayments for user
        _withdrawRepayment(_from);
        _withdrawRepayment(_to);

        //transfer extra liquidity shares
        uint256 _liquidityShare = lenders[_from].extraLiquidityShares;
        if (_liquidityShare == 0) return;

        uint256 toTransfer = _liquidityShare;
        if (_amount != poolToken.balanceOf(_from)) {
            toTransfer = (_amount.mul(_liquidityShare)).div(poolToken.balanceOf(_from));
        }

        lenders[_from].extraLiquidityShares = lenders[_from].extraLiquidityShares.sub(toTransfer);

        lenders[_to].extraLiquidityShares = lenders[_to].extraLiquidityShares.add(toTransfer);
    }

    function _calculatePenaltyTime(uint256 _loanStartTime, uint256 _loanWithdrawalDeadline) internal returns (uint256) {
        uint256 _penaltyTime = poolConstants.repaymentInterval;
        if (block.timestamp > _loanStartTime) {
            uint256 _penaltyEndTime = block.timestamp;
            if (block.timestamp > _loanWithdrawalDeadline) {
                _penaltyEndTime = _loanWithdrawalDeadline;
            }
            _penaltyTime = _penaltyTime.add(_penaltyEndTime.sub(_loanStartTime));
        }
        return _penaltyTime;
    }

    /**
     * @notice used to cancel pool when the minimum borrow amount is not met
     */
    function cancelPool() external {
        LoanStatus _poolStatus = poolVars.loanStatus;
        require(_poolStatus == LoanStatus.COLLECTION, 'CP1');
        uint256 _loanStartTime = poolConstants.loanStartTime;
        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);

        if (_loanStartTime < block.timestamp && poolToken.totalSupply() < _poolFactory.minBorrowFraction().mul(poolConstants.borrowAmountRequested).div(10**30)) {
            return _cancelPool(0);
        }

        uint256 _loanWithdrawalDeadline = poolConstants.loanWithdrawalDeadline;

        if (_loanWithdrawalDeadline > block.timestamp) {
            require(msg.sender == poolConstants.borrower, 'CP2');
        }
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralLiquidityShare = poolVars.baseLiquidityShares;
        uint256 _penaltyTime = _calculatePenaltyTime(_loanStartTime, _loanWithdrawalDeadline);
        uint256 _cancelPenaltyMultiple = _poolFactory.poolCancelPenaltyFraction();
        uint256 penalty = _cancelPenaltyMultiple
            .mul(poolConstants.borrowRate)
            .mul(_collateralLiquidityShare)
            .div(10**30)
            .mul(_penaltyTime)
            .div(365 days)
            .div(10**30);
        _cancelPool(penalty);
    }

    /**
     * @notice internal function to cancel borrow pool
     * @param _penalty amount to be paid as penalty to cancel pool
     */
    function _cancelPool(uint256 _penalty) internal {
        poolVars.loanStatus = LoanStatus.CANCELLED;
        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(poolConstants.borrower, _penalty);
        poolToken.pause();
        emit PoolCancelled();
    }

    /**
     * @notice used to liquidate the penalty amount when pool is calcelled
     * @dev _receiveLiquidityShares doesn't matter when _toSavingsAccount is true
     * @param _toSavingsAccount if true, liquidity transfered to lender's savings account. If false, liquidity transfered to lender's wallet
     * @param _receiveLiquidityShare if true, equivalent liquidity tokens are withdrawn. If false, assets are withdrawn
     */
    function liquidateCancelPenalty(bool _toSavingsAccount, bool _receiveLiquidityShare) external nonReentrant {
        require(poolVars.loanStatus == LoanStatus.CANCELLED, '');
        require(poolVars.penaltyLiquidityAmount == 0, '');
        address _poolFactory = PoolFactory;
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        address _collateralAsset = poolConstants.collateralAsset;
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralTokens = poolVars.baseLiquidityShares;
        if (_poolSavingsStrategy != address(0)) {
            _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralTokens, _collateralAsset);
        }
        uint256 _liquidationTokens = correspondingBorrowTokens(
            _collateralTokens,
            _poolFactory,
            IPoolFactory(_poolFactory).liquidatorRewardFraction()
        );
        poolVars.penaltyLiquidityAmount = _liquidationTokens;
        SavingsAccountUtil.transferTokens(poolConstants.borrowAsset, _liquidationTokens, msg.sender, address(this));
        _withdraw(
            _toSavingsAccount,
            _receiveLiquidityShare,
            poolConstants.collateralAsset,
            poolConstants.poolSavingsStrategy,
            _collateralTokens
        );
    }

    /**
     * @notice used to terminate the pool
     */
    function terminatePool() external onlyOwner {
        _withdrawAllCollateral(msg.sender, 0);
        poolToken.pause();
        poolVars.loanStatus = LoanStatus.TERMINATED;
        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        emit PoolTerminated();
    }

    /**
     * @notice called to close the loan after repayment of principal
     */
    function closeLoan() external payable override nonReentrant OnlyRepaymentImpl {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, '22');

        poolVars.loanStatus = LoanStatus.CLOSED;

        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(poolConstants.borrower, 0);
        poolToken.pause();

        emit PoolClosed();
    }

    // Note - Only when closed, cancelled or terminated, lender can withdraw
    //burns all shares and returns total remaining repayments along with provided liquidity
    /**
     * @notice used to return total remaining repayments along with provided liquidity to the lender
     */
    function withdrawLiquidity() external isLender(msg.sender) nonReentrant {
        LoanStatus _loanStatus = poolVars.loanStatus;

        require(
            _loanStatus == LoanStatus.CLOSED ||
                _loanStatus == LoanStatus.CANCELLED ||
                _loanStatus == LoanStatus.DEFAULTED ||
                _loanStatus == LoanStatus.TERMINATED,
            '24'
        );

        //gets amount through liquidity shares
        uint256 _actualBalance = poolToken.balanceOf(msg.sender);
        uint256 _toTransfer = _actualBalance;

        if (_loanStatus == LoanStatus.DEFAULTED || _loanStatus == LoanStatus.TERMINATED) {
            uint256 _totalAsset;
            if (poolConstants.borrowAsset != address(0)) {
                _totalAsset = IERC20(poolConstants.borrowAsset).balanceOf(address(this));
            } else {
                _totalAsset = address(this).balance;
            }
            //assuming their will be no tokens in pool in any case except liquidation (to be checked) or we should store the amount in liquidate()
            _toTransfer = _toTransfer.mul(_totalAsset).div(poolToken.totalSupply());
        }

        if (_loanStatus == LoanStatus.CANCELLED) {
            _toTransfer = _toTransfer.add(_toTransfer.mul(poolVars.penaltyLiquidityAmount).div(poolToken.totalSupply()));
        }

        if (_loanStatus == LoanStatus.CLOSED) {
            //transfer repayment
            _withdrawRepayment(msg.sender);
        }
        //to add transfer if not included in above (can be transferred with liquidity)
        poolToken.burn(msg.sender, _actualBalance);

        //transfer liquidity provided
        SavingsAccountUtil.transferTokens(poolConstants.borrowAsset, _toTransfer, address(this), msg.sender);

        // TODO: Something wrong in the below event. Please have a look
        emit LiquidityWithdrawn(_toTransfer, msg.sender);
    }

    /**
     * @dev function is executed by lender to exercise margin call
     * @dev It will revert in case collateral ratio is not below expected value
     * or the lender has already called it.
     */

    function requestMarginCall() external isLender(msg.sender) {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, '4');

        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        require(getMarginCallEndTime(msg.sender) == 0, 'RMC1');
        uint256 _idealCollateralRatio = poolConstants.idealCollateralRatio;
        require(
            _idealCollateralRatio >
                getCurrentCollateralRatio(msg.sender).add(poolConstants.volatilityThreshold),
            '26'
        );

        lenders[msg.sender].marginCallEndTime = block.timestamp.add(_poolFactory.marginCallDuration());

        emit MarginCalled(msg.sender);
    }

    /**
     * @notice used to get the interest accrued till current time in the current loan duration
     * @return ineterest accrued till current time
     */
    function interestToPay() public view returns (uint256) {
        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        (uint256 _loanDurationCovered, uint256 _interestPerSecond) = IRepayment(_poolFactory.repaymentImpl()).getInterestCalculationVars(
            address(this)
        );
        uint256 _currentBlockTime = block.timestamp.mul(10**30);
        uint256 _loanDurationTillNow = _currentBlockTime.sub(poolConstants.loanStartTime.mul(10**30));
        if (_loanDurationTillNow <= _loanDurationCovered) {
            return 0;
        }
        uint256 _interestAccrued = _interestPerSecond.mul(_loanDurationTillNow.sub(_loanDurationCovered)).div(10**60);

        return _interestAccrued;
    }

    /**
     * @notice used to calculate the collateral ratio
     * @param _balance the principal amount lent
     * @param _liquidityShares amount of collateral tokens available
     * @return _ratio the collateral ratio
     */
    function calculateCollateralRatio(uint256 _balance, uint256 _liquidityShares) public returns (uint256 _ratio) {
        uint256 _interest = interestToPay().mul(_balance).div(poolToken.totalSupply());
        address _collateralAsset = poolConstants.collateralAsset;
        address _strategy = poolConstants.poolSavingsStrategy;
        uint256 _currentCollateralTokens = _strategy == address(0)
            ? _liquidityShares
            : IYield(_strategy).getTokensForShares(_liquidityShares, _collateralAsset);
        uint256 _equivalentCollateral = getEquivalentTokens(_collateralAsset, poolConstants.borrowAsset, _currentCollateralTokens);
        _ratio = _equivalentCollateral.mul(10**30).div(_balance.add(_interest));
    }

    /**
     * @notice used to get the current collateral ratio of the borrow pool
     * @return _ratio the current collateral ratio of the borrow pool
     */
    function getCurrentCollateralRatio() public returns (uint256 _ratio) {
        uint256 _liquidityShares = poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares);

        _ratio = calculateCollateralRatio(poolToken.totalSupply(), _liquidityShares);
    }

    /**
     * @notice used to get the current collateral ratio of a lender
     * @return _ratio the current collateral ratio of the lender
     */
    function getCurrentCollateralRatio(address _lender) public returns (uint256 _ratio) {
        uint256 _balanceOfLender = poolToken.balanceOf(_lender);
        uint256 _liquidityShares = (poolVars.baseLiquidityShares.mul(_balanceOfLender).div(poolToken.totalSupply())).add(
            lenders[_lender].extraLiquidityShares
        );

        return (calculateCollateralRatio(_balanceOfLender, _liquidityShares));
    }

    /**
     * @notice used to liquidate the pool if the borrower has defaulted
     * @param _fromSavingsAccount if true, collateral is transferred from sender's savings account, if false, it is transferred from sender's wallet
     * @param _toSavingsAccount if true, liquidity transfered to sender's savings account. If false, liquidity transfered to sender's wallet
     * @param _recieveLiquidityShare if true, equivalent liquidity tokens are withdrawn. If false, assets are withdrawn
     */
    function liquidatePool(
        bool _fromSavingsAccount,
        bool _toSavingsAccount,
        bool _recieveLiquidityShare
    ) external payable nonReentrant {
        LoanStatus _currentPoolStatus = poolVars.loanStatus;
        address _poolFactory = PoolFactory;
        if (
            _currentPoolStatus != LoanStatus.DEFAULTED &&
            IRepayment(IPoolFactory(_poolFactory).repaymentImpl()).didBorrowerDefault(address(this))
        ) {
            _currentPoolStatus = LoanStatus.DEFAULTED;
            poolVars.loanStatus = _currentPoolStatus;
        }
        require(_currentPoolStatus == LoanStatus.DEFAULTED, 'Pool::liquidatePool - No reason to liquidate the pool');
        address _collateralAsset = poolConstants.collateralAsset;
        address _borrowAsset = poolConstants.borrowAsset;
        uint256 _collateralLiquidityShare = poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares);
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;

        uint256 _collateralTokens = _collateralLiquidityShare;
        if (_poolSavingsStrategy != address(0)) {
            _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralLiquidityShare, _collateralAsset);
        }
        uint256 _poolBorrowTokens = correspondingBorrowTokens(
            _collateralTokens,
            _poolFactory,
            IPoolFactory(_poolFactory).liquidatorRewardFraction()
        );
        delete poolVars.extraLiquidityShares;
        delete poolVars.baseLiquidityShares;

        _deposit(_fromSavingsAccount, false, _borrowAsset, _poolBorrowTokens, address(0), msg.sender, address(this));
        _withdraw(_toSavingsAccount, _recieveLiquidityShare, _collateralAsset, _poolSavingsStrategy, _collateralTokens);
        emit PoolLiquidated(msg.sender);
    }

    /**
     * @notice internal function used to withdraw tokens
     * @param _toSavingsAccount if true, liquidity transfered to receiver's savings account. If false, liquidity transfered to receiver's wallet
     * @param _recieveLiquidityShare if true, equivalent liquidity tokens are withdrawn. If false, assets are withdrawn
     * @param _asset address of the asset to be withdrawn
     * @param _poolSavingsStrategy address of the saving strategy used for collateral deposit
     * @param _amountInTokens amount of tokens to be withdrawn from the pool
     * @return amount of equivalent shares from given asset
     */
    function _withdraw(
        bool _toSavingsAccount,
        bool _recieveLiquidityShare,
        address _asset,
        address _poolSavingsStrategy,
        uint256 _amountInTokens
    ) internal returns (uint256) {
        ISavingsAccount _savingsAccount = ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount());
        return
            SavingsAccountUtil.depositFromSavingsAccount(
                _savingsAccount,
                address(this),
                msg.sender,
                _amountInTokens,
                _asset,
                _poolSavingsStrategy,
                _recieveLiquidityShare,
                _toSavingsAccount
            );
    }

    /**
     * @notice used to ensure if a lender can be liquidated
     * @param _lender address of the lender to be liquidated
     */
    function _canLenderBeLiquidated(address _lender) internal {
        require((poolVars.loanStatus == LoanStatus.ACTIVE) && (block.timestamp > poolConstants.loanWithdrawalDeadline), '27');
        uint256 _marginCallEndTime = lenders[_lender].marginCallEndTime;
        require(getMarginCallEndTime(_lender) != 0, 'No margin call has been called.');
        require(_marginCallEndTime < block.timestamp, '28');

        require(
            poolConstants.idealCollateralRatio.sub(poolConstants.volatilityThreshold) >
                getCurrentCollateralRatio(_lender),
            '29'
        );
        require(poolToken.balanceOf(_lender) != 0, '30');
    }

    /**
     * @notice used to add extra liquidity shares to lender's share
     * @param _lender address of the lender to be liquidated
     * @return _lenderCollateralLPShare share of the lender in collateral tokens
     * @return _lenderBalance balance of lender in pool tokens
     */
    function _updateLenderSharesDuringLiquidation(address _lender)
        internal
        returns (uint256 _lenderCollateralLPShare, uint256 _lenderBalance)
    {
        uint256 _poolBaseLPShares = poolVars.baseLiquidityShares;
        _lenderBalance = poolToken.balanceOf(_lender);

        uint256 _lenderBaseLPShares = (_poolBaseLPShares.mul(_lenderBalance)).div(poolToken.totalSupply());
        uint256 _lenderExtraLPShares = lenders[_lender].extraLiquidityShares;
        poolVars.baseLiquidityShares = _poolBaseLPShares.sub(_lenderBaseLPShares);
        poolVars.extraLiquidityShares = poolVars.extraLiquidityShares.sub(_lenderExtraLPShares);

        _lenderCollateralLPShare = _lenderBaseLPShares.add(_lenderExtraLPShares);
    }

    /**
     * @notice internal function to liquidate lender of the borrow pool
     * @param _fromSavingsAccount if true, collateral is transferred from lender's savings account, if false, it is transferred from lender's wallet
     * @param _lender address of the lender to be liquidated
     * @param _lenderCollateralTokens share of the lender in collateral tokens
     */
    function _liquidateForLender(
        bool _fromSavingsAccount,
        address _lender,
        uint256 _lenderCollateralTokens
    ) internal {
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;

        address _poolFactory = PoolFactory;
        uint256 _lenderLiquidationTokens = correspondingBorrowTokens(
            _lenderCollateralTokens,
            _poolFactory,
            IPoolFactory(_poolFactory).liquidatorRewardFraction()
        );

        address _borrowAsset = poolConstants.borrowAsset;
        _deposit(_fromSavingsAccount, false, _borrowAsset, _lenderLiquidationTokens, _poolSavingsStrategy, msg.sender, _lender);

        _withdrawRepayment(_lender);
    }

    /**
     * @notice used to liquidate lender and burn lender's shares
     * @param _lender address of the lender to be liquidated
     * @param _fromSavingsAccount if true, collateral is transferred from lender's savings account, if false, it is transferred from lender's wallet
     * @param _toSavingsAccount if true, liquidity transfered to receiver's savings account. If false, liquidity transfered to receiver's wallet
     * @param _recieveLiquidityShare if true, equivalent liquidity tokens are withdrawn. If false, assets are withdrawn
     */
    function liquidateForLender(
        address _lender,
        bool _fromSavingsAccount,
        bool _toSavingsAccount,
        bool _recieveLiquidityShare
    ) public payable nonReentrant {
        _canLenderBeLiquidated(_lender);

        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        (uint256 _lenderCollateralLPShare, uint256 _lenderBalance) = _updateLenderSharesDuringLiquidation(_lender);

        uint256 _lenderCollateralTokens = _lenderCollateralLPShare;
        if (_poolSavingsStrategy != address(0)) {
            _lenderCollateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(
                _lenderCollateralLPShare,
                poolConstants.collateralAsset
            );
        }

        _liquidateForLender(_fromSavingsAccount, _lender, _lenderCollateralTokens);

        uint256 _amountReceived = _withdraw(
            _toSavingsAccount,
            _recieveLiquidityShare,
            poolConstants.collateralAsset,
            _poolSavingsStrategy,
            _lenderCollateralTokens
        );
        poolToken.burn(_lender, _lenderBalance);
        delete lenders[_lender];
        emit LenderLiquidated(msg.sender, _lender, _amountReceived);
    }

    /**
     * @notice used to get corresponding borrow tokens for given collateral tokens
     * @param _totalCollateralTokens amount of collateral tokens
     * @param _poolFactory address of the pool
     * @param _fraction Incentivizing fraction for the liquidator
     * @return corresponding borrow tokens for collateral tokens
     */
    function correspondingBorrowTokens(
        uint256 _totalCollateralTokens,
        address _poolFactory,
        uint256 _fraction
    ) public view returns (uint256) {
        IPoolFactory _PoolFactory = IPoolFactory(_poolFactory);
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(_PoolFactory.priceOracle()).getLatestPrice(
            poolConstants.collateralAsset,
            poolConstants.borrowAsset
        );
        return _totalCollateralTokens.mul(_ratioOfPrices).div(10**_decimals).mul(uint256(10**30).sub(_fraction)).div(10**30);
    }

    /**
     * @notice used to get the interest per second on the principal amount
     * @param _principal amount of principal lent
     * @return interest accrued on the principal in a second
     */
    function interestPerSecond(uint256 _principal) public view returns (uint256) {
        uint256 _interest = ((_principal).mul(poolConstants.borrowRate)).div(365 days);
        return _interest;
    }

    /**
     * @notice used to get the interest per period on the principal amount
     * @param _balance amount of principal lent
     * @return interest accrued on the principal in a period
     */
    function interestPerPeriod(uint256 _balance) public view returns (uint256) {
        return (interestPerSecond(_balance).mul(poolConstants.repaymentInterval));
    }

    /**
     * @notice used to get the current repayment period for the borrow pool
     * @return current repayment period
     */
    function calculateCurrentPeriod() public view returns (uint256) {
        uint256 _currentPeriod = (block.timestamp.sub(poolConstants.loanStartTime, '34')).div(poolConstants.repaymentInterval);
        return _currentPeriod;
    }

    /**
     * @notice internal function used to get the withdrawable amount for a _lender
     * @param _lender address of the _lender
     * @return amount of withdrawable token from the borrow pool
     */
    function calculateRepaymentWithdrawable(address _lender) public view returns (uint256) {
        uint256 _totalRepaidAmount = IRepayment(IPoolFactory(PoolFactory).repaymentImpl()).getTotalRepaidAmount(address(this));

        uint256 _amountWithdrawable = (poolToken.balanceOf(_lender).mul(_totalRepaidAmount).div(poolToken.totalSupply())).sub(
            lenders[_lender].interestWithdrawn
        );

        return _amountWithdrawable;
    }

    /**
     * @notice used to get the withdrawable amount of borrow token for a lender
     */
    function withdrawRepayment() external isLender(msg.sender) nonReentrant {
        _withdrawRepayment(msg.sender);
    }

    /**
     * @notice internal function used to withdraw borrow asset from the pool by _lender
     * @param _lender address of the _lender
     */
    function _withdrawRepayment(address _lender) internal {
        uint256 _amountToWithdraw = calculateRepaymentWithdrawable(_lender);

        if (_amountToWithdraw == 0) {
            return;
        }
        lenders[_lender].interestWithdrawn = lenders[_lender].interestWithdrawn.add(_amountToWithdraw);

        SavingsAccountUtil.transferTokens(poolConstants.borrowAsset, _amountToWithdraw, address(this), _lender);
    }

    /**
     * @notice used to get the end time for a margin call
     * @param _lender address of the lender who has requested a margin call
     * @return the time at which the margin call ends
     */
    function getMarginCallEndTime(address _lender) public view override returns (uint256) {
        uint256 _marginCallDuration = IPoolFactory(PoolFactory).marginCallDuration();
        uint256 _marginCallEndTime = lenders[_lender].marginCallEndTime;

        if (block.timestamp > _marginCallEndTime.add(_marginCallDuration.mul(2))) {
            _marginCallEndTime = 0;
        }
        return _marginCallEndTime;
    }

    /**
     * @notice used to get the total pool tokens available
     * @return amount of pool tokens available in the pool
     */
    function getTokensLent() public view override returns (uint256) {
        return poolToken.totalSupply();
    }

    /**
     * @notice used to get the balance details of a _lender
     * @param _lender address of the _lender
     * @return amount of pool tokens available with the _lender
     * @return amount of pool tokens available in the pool
     */
    function getBalanceDetails(address _lender) public view override returns (uint256, uint256) {
        IPoolToken _poolToken = poolToken;
        return (_poolToken.balanceOf(_lender), _poolToken.totalSupply());
    }

    /**
     * @notice used to get the loan status of the borrow pool
     * @return integer respresenting loan status
     */
    function getLoanStatus() public view override returns (uint256) {
        return uint256(poolVars.loanStatus);
    }

    /**
     * @notice used to receive ethers from savings accounts
     */
    receive() external payable {
        // require(msg.sender == IPoolFactory(PoolFactory).savingsAccount(), '35');
    }

    /**
     * @notice used to get the equivalent amount of tokens from source to target tokens
     * @param _source address of the tokens to be converted
     * @param _target address of target conversion token
     * @param _amount amount of tokens to be converted
     * @return the equivalent amount of target tokens for given source tokens
     */
    function getEquivalentTokens(
        address _source,
        address _target,
        uint256 _amount
    ) public view returns (uint256) {
        (uint256 _price, uint256 _decimals) = IPriceOracle(IPoolFactory(PoolFactory).priceOracle()).getLatestPrice(_source, _target);
        return _amount.mul(_price).div(10**_decimals);
    }

    /**
     * @notice used to get the address of the borrower of the pool
     * @return address of the borrower
     */
    function borrower() external view override returns (address) {
        return poolConstants.borrower;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IPoolFactory {
    function savingsAccount() external view returns (address);

    function owner() external view returns (address);

    function poolRegistry(address pool) external view returns (bool);

    function priceOracle() external view returns (address);

    function extension() external view returns (address);

    function repaymentImpl() external view returns (address);

    function userRegistry() external view returns (address);

    function collectionPeriod() external view returns (uint256);

    function matchCollateralRatioInterval() external view returns (uint256);

    function marginCallDuration() external view returns (uint256);

    function minBorrowFraction() external view returns (uint256);

    function gracePeriodPenaltyFraction() external view returns (uint256);

    function liquidatorRewardFraction() external view returns (uint256);

    function votingPassRatio() external view returns (uint256);

    function poolCancelPenaltyFraction() external view returns (uint256);

    function getProtocolFeeData() external view returns (uint256, address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

interface IPriceOracle {
    function getLatestPrice(address num, address den) external view returns (uint256, uint256);

    function doesFeedExist(address token1, address token2) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IYield {
    /**
     * @dev emitted when tokens are locked
     * @param user the address of user, tokens locked for
     * @param investedTo the address of contract to invest in
     * @param lpTokensReceived the amount of shares received
     **/
    event LockedTokens(address user, address investedTo, uint256 lpTokensReceived);

    /**
     * @dev emitted when tokens are unlocked/redeemed
     * @param investedTo the address of contract invested in
     * @param collateralReceived the amount of underlying asset received
     **/
    event UnlockedTokens(address investedTo, uint256 collateralReceived);

    event UnlockedShares(address asset, uint256 sharesReleased);

    event SavingsAccountUpdated(address savingsAccount);

    /**
     * @dev Used to get liquidity token address from asset address
     * @param asset the address of underlying token
     * @return tokenAddress address of liquidity token
     **/
    function liquidityToken(address asset) external view returns (address tokenAddress);

    /**
     * @dev Used to lock tokens in available protocol
     * @param user the address of user locking tokens
     * @param asset the address of token to invest
     * @param amount the amount of asset
     * @return sharesReceived amount of shares received
     **/
    function lockTokens(
        address user,
        address asset,
        uint256 amount
    ) external payable returns (uint256 sharesReceived);

    /**
     * @dev Used to unlock tokens from available protocol
     * @param asset the address of underlying token
     * @param amount the amount of liquidity shares to unlock
     * @return tokensReceived amount of tokens received
     **/
    function unlockTokens(address asset, uint256 amount) external returns (uint256 tokensReceived);

    function unlockShares(address asset, uint256 amount) external returns (uint256 received);

    /**
     * @dev Used to get amount of underlying tokens for current number of shares
     * @param shares the amount of shares
     * @param asset the address of token locked
     * @return amount amount of underlying tokens
     **/
    function getTokensForShares(uint256 shares, address asset) external returns (uint256 amount);

    function getSharesForTokens(uint256 amount, address asset) external returns (uint256 shares);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

interface IRepayment {
    function initializeRepayment(
        uint256 numberOfTotalRepayments,
        uint256 repaymentInterval,
        uint256 borrowRate,
        uint256 loanStartTime,
        address lentAsset
    ) external;

    /*
    function calculateRepayAmount(address poolID)
        external
        view
        returns (uint256);
    */

    function getTotalRepaidAmount(address poolID) external view returns (uint256);

    //function getRepaymentPeriodCovered(address poolID) external view returns(uint256);
    //function getRepaymentOverdue(address poolID) external view returns(uint256);
    //function repaymentExtended(address poolID) external;

    function getInterestCalculationVars(address poolID) external view returns (uint256, uint256);

    //function getOngoingLoanInterval(address poolID) external view returns(uint256);

    function getCurrentLoanInterval(address poolID) external view returns (uint256);

    function instalmentDeadlineExtended(address _poolID, uint256 _period) external;

    function didBorrowerDefault(address _poolID) external view returns (bool);

    function getGracePeriodFraction() external view returns (uint256);

    function getNextInstalmentDeadline(address _poolID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ISavingsAccount {
    //events
    event Deposited(address user, uint256 amount, address token, address strategy);
    event StrategySwitched(address user, address token, address currentStrategy, address newStrategy);
    event Withdrawn(address from, address to, uint256 amountReceived, address token, address strategy);
    event WithdrawnAll(address user, uint256 tokenReceived, address token);
    event Approved(address token, address from, address to, uint256 amount);
    event Transfer(address token, address strategy, address from, address to, uint256 amount);
    event CreditLineUpdated(address _updatedCreditLine);
    event StrategyRegistryUpdated(address _updatedStrategyRegistry);

    event CreditLineAllowanceRefreshed(address token, address from, uint256 amount);

    function deposit(
        uint256 amount,
        address token,
        address strategy,
        address to
    ) external payable returns (uint256 sharesReceived);

    /**
     * @dev Used to switch saving strategy of an token
     * @param currentStrategy initial strategy of token
     * @param newStrategy new strategy to invest
     * @param token address of the token
     * @param amount amount of **liquidity shares** to be reinvested
     */
    function switchStrategy(
        uint256 amount,
        address token,
        address currentStrategy,
        address newStrategy
    ) external;

    /**
     * @dev Used to withdraw token from Saving Account
     * @param withdrawTo address to which token should be sent
     * @param amount amount of liquidity shares to withdraw
     * @param token address of the token to be withdrawn
     * @param strategy strategy from where token has to withdrawn(ex:- compound,Aave etc)
     * @param withdrawShares boolean indicating to withdraw in liquidity share or underlying token
     */
    function withdraw(
        uint256 amount,
        address token,
        address strategy,
        address payable withdrawTo,
        bool withdrawShares
    ) external returns (uint256);

    function withdrawAll(address _token) external returns (uint256 tokenReceived);

    function approve(
        uint256 amount,
        address token,
        address to
    ) external;

    function increaseAllowance(
        uint256 amount,
        address token,
        address to
    ) external;

    function decreaseAllowance(
        uint256 amount,
        address token,
        address to
    ) external;

    function transfer(
        uint256 amount,
        address token,
        address poolSavingsStrategy,
        address to
    ) external returns (uint256);

    function transferFrom(
        uint256 amount,
        address token,
        address poolSavingsStrategy,
        address from,
        address to
    ) external returns (uint256);

    function balanceInShares(
        address user,
        address token,
        address strategy
    ) external view returns (uint256);

    function increaseAllowanceToCreditLine(
        uint256 amount,
        address token,
        address from
    ) external;

    function withdrawFrom(
        uint256 amount,
        address token,
        address strategy,
        address from,
        address payable to,
        bool withdrawShares
    ) external returns (uint256 amountReceived);

    function getTotalTokens(address _user, address _token) external returns (uint256 _totalTokens);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import '../interfaces/ISavingsAccount.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

library SavingsAccountUtil {
    using SafeERC20 for IERC20;

    function depositFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _token,
        address _strategy,
        bool _withdrawShares,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        if (_toSavingsAccount) {
            return savingsAccountTransfer(_savingsAccount, _from, _to, _amount, _token, _strategy);
        } else {
            return withdrawFromSavingsAccount(_savingsAccount, _from, _to, _amount, _token, _strategy, _withdrawShares);
        }
    }

    function directDeposit(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _token,
        bool _toSavingsAccount,
        address _strategy
    ) internal returns (uint256) {
        if (_toSavingsAccount) {
            return directSavingsAccountDeposit(_savingsAccount, _from, _to, _amount, _token, _strategy);
        } else {
            return transferTokens(_token, _amount, _from, _to);
        }
    }

    function directSavingsAccountDeposit(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _token,
        address _strategy
    ) internal returns (uint256 _sharesReceived) {
        transferTokens(_token, _amount, _from, address(this));
        uint256 _ethValue;
        if (_token == address(0)) {
            _ethValue = _amount;
        } else {
            address _approveTo = _strategy;
            if (_strategy == address(0)) {
                _approveTo = address(_savingsAccount);
            }
            IERC20(_token).safeApprove(_approveTo, _amount);
        }
        _sharesReceived = _savingsAccount.deposit{value: _ethValue}(_amount, _token, _strategy, _to);
    }

    function savingsAccountTransfer(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _token,
        address _strategy
    ) internal returns (uint256) {
        if (_from == address(this)) {
            _savingsAccount.transfer(_amount, _token, _strategy, _to);
        } else {
            _savingsAccount.transferFrom(_amount, _token, _strategy, _from, _to);
        }
        return _amount;
    }

    function withdrawFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _token,
        address _strategy,
        bool _withdrawShares
    ) internal returns (uint256 _amountReceived) {
        if (_from == address(this)) {
            _amountReceived = _savingsAccount.withdraw(_amount, _token, _strategy, payable(_to), _withdrawShares);
        } else {
            _amountReceived = _savingsAccount.withdrawFrom(_amount, _token, _strategy, _from, payable(_to), _withdrawShares);
        }
    }

    function transferTokens(
        address _token,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        if (_token == address(0)) {
            require(msg.value >= _amount, 'ethers provided should be greater than _amount');

            if (_to != address(this)) {
                (bool success, ) = payable(_to).call{value: _amount}('');
                require(success, 'Transfer failed');
            }
            if (msg.value > _amount) {
                (bool success, ) = payable(address(msg.sender)).call{value: msg.value - _amount}('');
                require(success, 'Transfer failed');
            } else if (msg.value != _amount) {
                revert('Insufficient Ether');
            }
            return _amount;
        }
        if (_from == address(this)) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            //pool
            IERC20(_token).safeTransferFrom(_from, _to, _amount);
        }
        return _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

interface IPool {
    function getLoanStatus() external view returns (uint256);

    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) external payable;

    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _isDirect
    ) external payable;

    function withdrawBorrowedAmount() external;

    function beforeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function setConstants(address _poolToken, address _lenderVerifier) external;

    function borrower() external returns (address);

    function getMarginCallEndTime(address _lender) external returns (uint256);

    //function grantExtension() external returns (uint256); adding updateNextDuePeriodAfterExtension() for replacement
    //function updateNextDuePeriodAfterExtension() external returns (uint256);

    function getBalanceDetails(address _lender) external view returns (uint256, uint256);

    function getTokensLent() external view returns (uint256);

    function closeLoan() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IExtension {
    function initializePoolExtension(uint256 _repaymentInterval) external;

    function closePoolExtension() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolToken is IERC20 {
    function burn(address user, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function pause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IVerification {
    function isUser(address _user, address _verifier) external view returns (bool);

    function registerMasterAddress(address _masterAddress, bool _isMasterLinked) external;

    function unregisterMasterAddress(address _masterAddress, address _verifier) external;
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

pragma solidity >=0.6.2 <0.8.0;

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

