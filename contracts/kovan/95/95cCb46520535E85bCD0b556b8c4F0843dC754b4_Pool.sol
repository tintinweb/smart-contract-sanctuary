// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20PausableUpgradeable.sol';
import '../interfaces/IPoolFactory.sol';
import '../interfaces/IPriceOracle.sol';
import '../interfaces/IYield.sol';
import '../interfaces/IRepayment.sol';
import '../interfaces/ISavingsAccount.sol';
import '../SavingsAccount/SavingsAccountUtil.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IExtension.sol';
import '../interfaces/IVerification.sol';

/**
 * @title Pool contract with Methods related to Pool
 * @notice Implements the functions related to Pool
 * @author Sublime
 */
contract Pool is Initializable, ERC20PausableUpgradeable, IPool, ReentrancyGuard {
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

    address poolFactory;

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
        uint256 borrowRate;
        uint256 noOfRepaymentIntervals;
        uint256 repaymentInterval;
        address collateralAsset;
        address poolSavingsStrategy; // invest contract
        address lenderVerifier;
    }

    struct PoolVariables {
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
     * @notice object of type PoolVariables
     */
    PoolVariables public poolVariables;

    /**
     * @notice checks if the _user is pool's valid borrower
     * @param _user address of the borrower
     */
    modifier onlyBorrower(address _user) {
        require(_user == poolConstants.borrower, 'OB1');
        _;
    }

    /**
     * @notice checks if the _lender is pool's valid lender
     * @param _lender address of the lender
     */
    modifier isLender(address _lender) {
        require(balanceOf(_lender) != 0, 'IL1');
        _;
    }

    /**
     * @notice checks if the msg.sender is pool's valid owner
     */
    modifier onlyOwner() {
        require(msg.sender == IPoolFactory(poolFactory).owner(), 'OO1');
        _;
    }

    /**
     * @notice checks if the msg.sender is pool's latest repayment implementation
     */
    modifier onlyRepaymentImpl() {
        require(msg.sender == IPoolFactory(poolFactory).repaymentImpl(), 'OR1');
        _;
    }

    /**
     * @notice initializing the pool and adding initial collateral
     * @param _borrowAmountRequested the amount of borrow asset requested by the borrower
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
        uint256 _repaymentInterval,
        uint256 _noOfRepaymentIntervals,
        address _poolSavingsStrategy,
        uint256 _collateralAmount,
        bool _transferFromSavingsAccount,
        address _lenderVerifier,
        uint256 _loanWithdrawalDuration,
        uint256 _collectionPeriod
    ) external payable initializer {
        poolFactory = msg.sender;
        poolConstants.borrowAsset = _borrowAsset;
        poolConstants.idealCollateralRatio = _idealCollateralRatio;
        poolConstants.collateralAsset = _collateralAsset;
        poolConstants.poolSavingsStrategy = _poolSavingsStrategy;
        poolConstants.borrowAmountRequested = _borrowAmountRequested;
        _initialDeposit(_borrower, _collateralAmount, _transferFromSavingsAccount);
        poolConstants.borrower = _borrower;
        poolConstants.borrowRate = _borrowRate;
        poolConstants.noOfRepaymentIntervals = _noOfRepaymentIntervals;
        poolConstants.repaymentInterval = _repaymentInterval;
        poolConstants.lenderVerifier = _lenderVerifier;

        poolConstants.loanStartTime = block.timestamp.add(_collectionPeriod);
        poolConstants.loanWithdrawalDeadline = block.timestamp.add(_collectionPeriod).add(_loanWithdrawalDuration);
        __ERC20_init('Pool Tokens', 'PT');
    }

    /**
     * @notice add collateral to a pool
     * @param _amount amount of collateral to be deposited denominated in collateral asset
     * @param _transferFromSavingsAccount if true, collateral is transferred from msg.sender's savings account, if false, it is transferred from their wallet
     */
    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) external payable override {
        require(_amount != 0, 'DC1');
        require(balanceOf(msg.sender) == 0, 'DC2');
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
        require(_amount >= poolConstants.idealCollateralRatio.mul(_equivalentCollateral).div(1e30), 'ID1');
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
        poolVariables.baseLiquidityShares = poolVariables.baseLiquidityShares.add(_sharesReceived);
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
                ISavingsAccount(IPoolFactory(poolFactory).savingsAccount()),
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
                ISavingsAccount(IPoolFactory(poolFactory).savingsAccount()),
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
        require(poolVariables.loanStatus == LoanStatus.ACTIVE, 'ACMC1');
        require(balanceOf(msg.sender) == 0, 'ACMC2');
        require(getMarginCallEndTime(_lender) >= block.timestamp, 'ACMC3');

        require(_amount != 0, 'ACMC4');

        uint256 _sharesReceived = _deposit(
            _transferFromSavingsAccount,
            true,
            poolConstants.collateralAsset,
            _amount,
            poolConstants.poolSavingsStrategy,
            msg.sender,
            address(this)
        );

        poolVariables.extraLiquidityShares = poolVariables.extraLiquidityShares.add(_sharesReceived);

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
        LoanStatus _poolStatus = poolVariables.loanStatus;
        uint256 _tokensLent = totalSupply();
        require(
            _poolStatus == LoanStatus.COLLECTION &&
                poolConstants.loanStartTime < block.timestamp &&
                block.timestamp < poolConstants.loanWithdrawalDeadline,
            'WBA1'
        );
        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
        require(_tokensLent >= _poolFactory.minBorrowFraction().mul(poolConstants.borrowAmountRequested).div(10**30), 'WBA2');

        poolVariables.loanStatus = LoanStatus.ACTIVE;
        uint256 _currentCollateralRatio = getCurrentCollateralRatio();
        require(_currentCollateralRatio >= poolConstants.idealCollateralRatio, 'WBA3');

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
        if (poolVariables.baseLiquidityShares.add(poolVariables.extraLiquidityShares) > _penalty) {
            _collateralShares = poolVariables.baseLiquidityShares.add(poolVariables.extraLiquidityShares).sub(_penalty);
        }
        // uint256 _collateralTokens = _collateralShares;
        uint256 _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralShares, _collateralAsset);

        poolVariables.baseLiquidityShares = _penalty;
        delete poolVariables.extraLiquidityShares;

        uint256 _sharesReceived;
        if (_collateralShares != 0) {
            ISavingsAccount _savingsAccount = ISavingsAccount(IPoolFactory(poolFactory).savingsAccount());
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
        address _borrower = poolConstants.borrower;
        require(_lender != _borrower && _borrower != msg.sender, 'L1');
        if (_lenderVerifier != address(0)) {
            require(IVerification(IPoolFactory(poolFactory).userRegistry()).isUser(_lender, _lenderVerifier), 'L2');
        }
        require(poolVariables.loanStatus == LoanStatus.COLLECTION && block.timestamp < poolConstants.loanStartTime, 'L3');
        uint256 _borrowAmountNeeded = poolConstants.borrowAmountRequested;
        uint256 _lentAmount = totalSupply();
        if (_amount.add(_lentAmount) > _borrowAmountNeeded) {
            _amount = _borrowAmountNeeded.sub(_lentAmount);
        }

        address _borrowToken = poolConstants.borrowAsset;
        _deposit(
            _fromSavingsAccount,
            false,
            _borrowToken,
            _amount,
            IPoolFactory(poolFactory).noStrategyAddress(),
            msg.sender,
            address(this)
        );
        _mint(_lender, _amount);
        emit LiquiditySupplied(_amount, _lender);
    }

    /**
     * @notice used to transfer borrow pool tokens among lenders
     * @param _from address of the lender who sends the borrow pool tokens
     * @param _to addres of the lender who receives the borrow pool tokens
     * @param _amount amount of borrow pool tokens transfered
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        if (_to != address(0)) {
            require(!paused(), 'TT1');
        }
        require(_to != poolConstants.borrower, 'TT2');

        if (_from == address(0) || _to == address(0)) {
            return;
        }
        require(getMarginCallEndTime(_from) == 0, 'TT3');
        require(getMarginCallEndTime(_to) == 0, 'TT4');

        //Withdraw repayments for user
        _withdrawRepayment(_from);
        _withdrawRepayment(_to);

        IExtension(IPoolFactory(poolFactory).extension()).removeVotes(_from, _to, _amount);

        //transfer extra liquidity shares
        uint256 _liquidityShare = lenders[_from].extraLiquidityShares;
        if (_liquidityShare == 0) return;

        uint256 toTransfer = _liquidityShare;
        if (_amount != balanceOf(_from)) {
            toTransfer = (_amount.mul(_liquidityShare)).div(balanceOf(_from));
        }

        lenders[_from].extraLiquidityShares = lenders[_from].extraLiquidityShares.sub(toTransfer);

        lenders[_to].extraLiquidityShares = lenders[_to].extraLiquidityShares.add(toTransfer);
    }

    function _calculatePenaltyTime(uint256 _loanStartTime, uint256 _loanWithdrawalDeadline) internal view returns (uint256) {
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
        LoanStatus _poolStatus = poolVariables.loanStatus;
        require(_poolStatus == LoanStatus.COLLECTION, 'CP1');
        uint256 _loanStartTime = poolConstants.loanStartTime;
        IPoolFactory _poolFactory = IPoolFactory(poolFactory);

        if (
            _loanStartTime < block.timestamp &&
            totalSupply() < _poolFactory.minBorrowFraction().mul(poolConstants.borrowAmountRequested).div(10**30)
        ) {
            return _cancelPool(0);
        }

        uint256 _loanWithdrawalDeadline = poolConstants.loanWithdrawalDeadline;

        if (_loanWithdrawalDeadline > block.timestamp) {
            require(msg.sender == poolConstants.borrower, 'CP2');
        }
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralLiquidityShare = poolVariables.baseLiquidityShares;
        uint256 _penaltyTime = _calculatePenaltyTime(_loanStartTime, _loanWithdrawalDeadline);
        uint256 _cancelPenaltyMultiple = _poolFactory.poolCancelPenaltyMultiple();
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
        poolVariables.loanStatus = LoanStatus.CANCELLED;
        IExtension(IPoolFactory(poolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(poolConstants.borrower, _penalty);
        _pause();
        emit PoolCancelled();
    }

    /**
     * @notice used to liquidate the penalty amount when pool is calcelled
     * @dev _receiveLiquidityShares doesn't matter when _toSavingsAccount is true
     * @param _toSavingsAccount if true, liquidity transfered to lender's savings account. If false, liquidity transfered to lender's wallet
     * @param _receiveLiquidityShare if true, equivalent liquidity tokens are withdrawn. If false, assets are withdrawn
     */
    function liquidateCancelPenalty(bool _toSavingsAccount, bool _receiveLiquidityShare) external nonReentrant {
        require(poolVariables.loanStatus == LoanStatus.CANCELLED, 'LCP1');
        require(poolVariables.penaltyLiquidityAmount == 0, 'LCP2');
        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        address _collateralAsset = poolConstants.collateralAsset;
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralTokens = poolVariables.baseLiquidityShares;
        _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralTokens, _collateralAsset);

        uint256 _liquidationTokens = correspondingBorrowTokens(
            _collateralTokens,
            _poolFactory.priceOracle(),
            _poolFactory.liquidatorRewardFraction()
        );
        poolVariables.penaltyLiquidityAmount = _liquidationTokens;
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
     * @dev kill switch for owner to terminate the pool
     */
    function terminatePool() external onlyOwner {
        _withdrawAllCollateral(msg.sender, 0);
        _pause();
        poolVariables.loanStatus = LoanStatus.TERMINATED;
        IExtension(IPoolFactory(poolFactory).extension()).closePoolExtension();
        emit PoolTerminated();
    }

    /**
     * @notice called to close the loan after repayment of principal
     */
    function closeLoan() external payable override nonReentrant onlyRepaymentImpl {
        require(poolVariables.loanStatus == LoanStatus.ACTIVE, 'CL1');

        poolVariables.loanStatus = LoanStatus.CLOSED;

        IExtension(IPoolFactory(poolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(poolConstants.borrower, 0);
        _pause();

        emit PoolClosed();
    }

    /**
     * @notice used to return total remaining repayments along with provided liquidity to the lender
     * @dev burns all shares and returns total remaining repayments along with provided liquidity
     */
    function withdrawLiquidity() external isLender(msg.sender) nonReentrant {
        LoanStatus _loanStatus = poolVariables.loanStatus;

        require(
            _loanStatus == LoanStatus.CLOSED ||
                _loanStatus == LoanStatus.CANCELLED ||
                _loanStatus == LoanStatus.DEFAULTED ||
                _loanStatus == LoanStatus.TERMINATED,
            'WL1'
        );

        //gets amount through liquidity shares
        uint256 _actualBalance = balanceOf(msg.sender);
        uint256 _toTransfer = _actualBalance;

        if (_loanStatus == LoanStatus.DEFAULTED || _loanStatus == LoanStatus.TERMINATED) {
            uint256 _totalAsset;
            if (poolConstants.borrowAsset != address(0)) {
                _totalAsset = IERC20(poolConstants.borrowAsset).balanceOf(address(this));
            } else {
                _totalAsset = address(this).balance;
            }
            //assuming their will be no tokens in pool in any case except liquidation (to be checked) or we should store the amount in liquidate()
            _toTransfer = _toTransfer.mul(_totalAsset).div(totalSupply());
        }

        if (_loanStatus == LoanStatus.CANCELLED) {
            _toTransfer = _toTransfer.add(_toTransfer.mul(poolVariables.penaltyLiquidityAmount).div(totalSupply()));
        }

        if (_loanStatus == LoanStatus.CLOSED) {
            //transfer repayment
            _withdrawRepayment(msg.sender);
        }
        //to add transfer if not included in above (can be transferred with liquidity)
        _burn(msg.sender, _actualBalance);

        //transfer liquidity provided
        SavingsAccountUtil.transferTokens(poolConstants.borrowAsset, _toTransfer, address(this), msg.sender);

        emit LiquidityWithdrawn(_toTransfer, msg.sender);
    }

    /**
     * @notice function is executed by lender to exercise margin call
     * @dev It will revert in case collateral ratio is not below expected value
     * or the lender has already called it.
     */

    function requestMarginCall() external isLender(msg.sender) {
        require(poolVariables.loanStatus == LoanStatus.ACTIVE, 'RMC1');

        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
        require(getMarginCallEndTime(msg.sender) == 0, 'RMC2');
        require(poolConstants.idealCollateralRatio > getCurrentCollateralRatio(msg.sender), 'RMC3');

        lenders[msg.sender].marginCallEndTime = block.timestamp.add(_poolFactory.marginCallDuration());

        emit MarginCalled(msg.sender);
    }

    /**
     * @notice used to get the interest accrued till current time in the current loan duration
     * @return ineterest accrued till current time
     */
    function interestToPay() public view returns (uint256) {
        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
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
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @param _balance the principal amount lent
     * @param _liquidityShares amount of collateral tokens available
     * @return _ratio the collateral ratio
     */
    function calculateCollateralRatio(uint256 _balance, uint256 _liquidityShares) public returns (uint256 _ratio) {
        uint256 _interest = interestToPay().mul(_balance).div(totalSupply());
        address _collateralAsset = poolConstants.collateralAsset;
        address _strategy = poolConstants.poolSavingsStrategy;
        uint256 _currentCollateralTokens = IYield(_strategy).getTokensForShares(_liquidityShares, _collateralAsset);

        uint256 _equivalentCollateral = getEquivalentTokens(_collateralAsset, poolConstants.borrowAsset, _currentCollateralTokens);
        _ratio = _equivalentCollateral.mul(10**30).div(_balance.add(_interest));
    }

    /**
     * @notice used to get the current collateral ratio of the borrow pool
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @return _ratio the current collateral ratio of the borrow pool
     */
    function getCurrentCollateralRatio() public returns (uint256 _ratio) {
        uint256 _liquidityShares = poolVariables.baseLiquidityShares.add(poolVariables.extraLiquidityShares);

        _ratio = calculateCollateralRatio(totalSupply(), _liquidityShares);
    }

    /**
     * @notice used to get the current collateral ratio of a lender
     * @dev is a view function for the protocol itself, but isn't view because of getTokensForShares which is not view
     * @return _ratio the current collateral ratio of the lender
     */
    function getCurrentCollateralRatio(address _lender) public returns (uint256 _ratio) {
        uint256 _balanceOfLender = balanceOf(_lender);
        uint256 _liquidityShares = (poolVariables.baseLiquidityShares.mul(_balanceOfLender).div(totalSupply())).add(
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
        LoanStatus _currentPoolStatus = poolVariables.loanStatus;
        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
        require(_currentPoolStatus == LoanStatus.ACTIVE, 'LP1');
        require(IRepayment(_poolFactory.repaymentImpl()).didBorrowerDefault(address(this)), 'LP2');
        poolVariables.loanStatus = LoanStatus.DEFAULTED;

        address _collateralAsset = poolConstants.collateralAsset;
        address _borrowAsset = poolConstants.borrowAsset;
        uint256 _collateralLiquidityShare = poolVariables.baseLiquidityShares.add(poolVariables.extraLiquidityShares);
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;

        uint256 _collateralTokens = _collateralLiquidityShare;
        _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_collateralLiquidityShare, _collateralAsset);

        uint256 _poolBorrowTokens = correspondingBorrowTokens(
            _collateralTokens,
            _poolFactory.priceOracle(),
            _poolFactory.liquidatorRewardFraction()
        );
        delete poolVariables.extraLiquidityShares;
        delete poolVariables.baseLiquidityShares;

        _deposit(_fromSavingsAccount, false, _borrowAsset, _poolBorrowTokens, _poolFactory.noStrategyAddress(), msg.sender, address(this));
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
        ISavingsAccount _savingsAccount = ISavingsAccount(IPoolFactory(poolFactory).savingsAccount());
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
        require((poolVariables.loanStatus == LoanStatus.ACTIVE) && (block.timestamp > poolConstants.loanWithdrawalDeadline), 'CLBL1');
        uint256 _marginCallEndTime = lenders[_lender].marginCallEndTime;
        require(getMarginCallEndTime(_lender) != 0, 'CLBL2');
        require(_marginCallEndTime < block.timestamp, 'CLBL3');

        require(poolConstants.idealCollateralRatio > getCurrentCollateralRatio(_lender), 'CLBL4');
        require(balanceOf(_lender) != 0, 'CLBL5');
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
        uint256 _poolBaseLPShares = poolVariables.baseLiquidityShares;
        _lenderBalance = balanceOf(_lender);

        uint256 _lenderBaseLPShares = (_poolBaseLPShares.mul(_lenderBalance)).div(totalSupply());
        uint256 _lenderExtraLPShares = lenders[_lender].extraLiquidityShares;
        poolVariables.baseLiquidityShares = _poolBaseLPShares.sub(_lenderBaseLPShares);
        poolVariables.extraLiquidityShares = poolVariables.extraLiquidityShares.sub(_lenderExtraLPShares);

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

        IPoolFactory _poolFactory = IPoolFactory(poolFactory);
        uint256 _lenderLiquidationTokens = correspondingBorrowTokens(
            _lenderCollateralTokens,
            _poolFactory.priceOracle(),
            _poolFactory.liquidatorRewardFraction()
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
    ) external payable nonReentrant {
        _canLenderBeLiquidated(_lender);

        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        (uint256 _lenderCollateralLPShare, uint256 _lenderBalance) = _updateLenderSharesDuringLiquidation(_lender);

        uint256 _lenderCollateralTokens = _lenderCollateralLPShare;
        _lenderCollateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(_lenderCollateralLPShare, poolConstants.collateralAsset);

        _liquidateForLender(_fromSavingsAccount, _lender, _lenderCollateralTokens);

        uint256 _amountReceived = _withdraw(
            _toSavingsAccount,
            _recieveLiquidityShare,
            poolConstants.collateralAsset,
            _poolSavingsStrategy,
            _lenderCollateralTokens
        );
        _burn(_lender, _lenderBalance);
        delete lenders[_lender];
        emit LenderLiquidated(msg.sender, _lender, _amountReceived);
    }

    /**
     * @notice used to get corresponding borrow tokens for given collateral tokens
     * @param _totalCollateralTokens amount of collateral tokens
     * @param _priceOracle address of the pool
     * @param _fraction Incentivizing fraction for the liquidator
     * @return corresponding borrow tokens for collateral tokens
     */
    function correspondingBorrowTokens(
        uint256 _totalCollateralTokens,
        address _priceOracle,
        uint256 _fraction
    ) public view returns (uint256) {
        (uint256 _ratioOfPrices, uint256 _decimals) = IPriceOracle(_priceOracle).getLatestPrice(
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
    function interestPerPeriod(uint256 _balance) external view returns (uint256) {
        return (interestPerSecond(_balance).mul(poolConstants.repaymentInterval));
    }

    /**
     * @notice used to get the current repayment period for the borrow pool
     * @return current repayment period
     */
    function calculateCurrentPeriod() external view returns (uint256) {
        uint256 _currentPeriod = (block.timestamp.sub(poolConstants.loanStartTime, '34')).div(poolConstants.repaymentInterval);
        return _currentPeriod;
    }

    /**
     * @notice internal function used to get the withdrawable amount for a _lender
     * @param _lender address of the _lender
     * @return amount of withdrawable token from the borrow pool
     */
    function calculateRepaymentWithdrawable(address _lender) public view returns (uint256) {
        uint256 _totalRepaidAmount = IRepayment(IPoolFactory(poolFactory).repaymentImpl()).getTotalRepaidAmount(address(this));

        uint256 _amountWithdrawable = (balanceOf(_lender).mul(_totalRepaidAmount).div(totalSupply())).sub(
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
        uint256 _marginCallDuration = IPoolFactory(poolFactory).marginCallDuration();
        uint256 _marginCallEndTime = lenders[_lender].marginCallEndTime;

        if (block.timestamp > _marginCallEndTime.add(_marginCallDuration.mul(2))) {
            _marginCallEndTime = 0;
        }
        return _marginCallEndTime;
    }

    /**
     * @notice used to get the balance details of a _lender
     * @param _lender address of the _lender
     * @return amount of pool tokens available with the _lender
     * @return amount of pool tokens available in the pool
     */
    function getBalanceDetails(address _lender) external view override returns (uint256, uint256) {
        return (balanceOf(_lender), totalSupply());
    }

    /**
     * @notice used to get the loan status of the borrow pool
     * @return integer respresenting loan status
     */
    function getLoanStatus() external view override returns (uint256) {
        return uint256(poolVariables.loanStatus);
    }

    /**
     * @notice used to receive ethers from savings accounts
     */
    receive() external payable {}

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
        (uint256 _price, uint256 _decimals) = IPriceOracle(IPoolFactory(poolFactory).priceOracle()).getLatestPrice(_source, _target);
        return _amount.mul(_price).div(10**_decimals);
    }

    /**
     * @notice used to get the address of the borrower of the pool
     * @return address of the borrower
     */
    function borrower() external view override returns (address) {
        return poolConstants.borrower;
    }

    /**
     * @notice used to total supply of pool tokens for the pool
     * @return total supply of pool tokens
     */
    function totalSupply() public view override(ERC20Upgradeable, IPool) returns (uint256) {
        return ERC20Upgradeable.totalSupply();
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

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IPoolFactory {
    /**
     * @notice emitted when a Pool is created
     * @param pool the address of the Pool
     * @param borrower the address of the borrower who created the pool
     */
    event PoolCreated(address indexed pool, address indexed borrower);

    /**
     * @notice emitted when the init function definition Pool.sol logic is updated
     * @param updatedSelector the new init function definition for the Pool logic contract
     */
    event PoolInitSelectorUpdated(bytes4 updatedSelector);

    /**
     * @notice emitted when the Pool.sol logic is updated
     * @param updatedPoolLogic the address of the new Pool logic contract
     */
    event PoolLogicUpdated(address indexed updatedPoolLogic);

    /**
     * @notice emitted when the user registry is updated
     * @param updatedBorrowerRegistry address of the contract storing the user registry
     */
    event UserRegistryUpdated(address indexed updatedBorrowerRegistry);

    /**
     * @notice emitted when the strategy registry is updated
     * @param updatedStrategyRegistry address of the contract storing the updated strategy registry
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    /**
     * @notice emitted when the Repayments.sol logic is updated
     * @param updatedRepaymentImpl the address of the new implementation of the Repayments logic
     */
    event RepaymentImplUpdated(address indexed updatedRepaymentImpl);

    /**
     * @notice emitted when the PriceOracle.sol is updated
     * @param updatedPriceOracle address of the new implementation of the PriceOracle
     */
    event PriceOracleUpdated(address indexed updatedPriceOracle);

    /**
     * @notice emitted when the Extension.sol is updated
     * @param updatedExtension address of the new implementation of the Extension
     */
    event ExtensionImplUpdated(address indexed updatedExtension);

    /**
     * @notice emitted when the SavingsAccount.sol is updated
     * @param savingsAccount address of the new implementation of the SavingsAccount
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

    /**
     * @notice emitted when the collection period parameter for Pools is updated
     * @param updatedCollectionPeriod the new value of the collection period for Pools
     */
    event CollectionPeriodUpdated(uint256 updatedCollectionPeriod);

    /**
     * @notice emitted when the loan withdrawal parameter for Pools is updated
     * @param updatedLoanWithdrawalDuration the new value of the loan withdrawal period for Pools
     */
    event LoanWithdrawalDurationUpdated(uint256 updatedLoanWithdrawalDuration);

    /**
     * @notice emitted when the marginCallDuration variable is updated
     * @param updatedMarginCallDuration Duration (in seconds) for which a margin call is active
     */
    event MarginCallDurationUpdated(uint256 updatedMarginCallDuration);

    /**
     * @notice emitted when miBorrowFraction variable is updated
     * @param updatedMinBorrowFraction Updated value of miBorrowFraction
     */
    event MinBorrowFractionUpdated(uint256 updatedMinBorrowFraction);

    /**
     * @notice emitted when liquidatorRewardFraction variable is updated
     * @param updatedLiquidatorRewardFraction updated value of liquidatorRewardFraction
     */
    event LiquidatorRewardFractionUpdated(uint256 updatedLiquidatorRewardFraction);

    /**
     * @notice emitted when poolCancelPenaltyMultiple variable is updated
     * @param updatedPoolCancelPenaltyMultiple updated value of poolCancelPenaltyMultiple
     */
    event PoolCancelPenaltyMultipleUpdated(uint256 updatedPoolCancelPenaltyMultiple);

    /**
     * @notice emitted when fee that protocol changes for pools is updated
     * @param updatedProtocolFee updated value of protocolFeeFraction
     */
    event ProtocolFeeFractionUpdated(uint256 updatedProtocolFee);

    /**
     * @notice emitted when address which receives fee that protocol changes for pools is updated
     * @param updatedProtocolFeeCollector updated value of protocolFeeCollector
     */
    event ProtocolFeeCollectorUpdated(address updatedProtocolFeeCollector);

    /**
     * @notice emitted when threhsolds for one of the parameters (poolSizeLimit, collateralRatioLimit, borrowRateLimit, repaymentIntervalLimit, noOfRepaymentIntervalsLimit) is updated
     * @param limitType specifies the parameter whose limits are being updated
     * @param max maximum threshold value for limitType
     * @param min minimum threshold value for limitType
     */
    event LimitsUpdated(string indexed limitType, uint256 max, uint256 min);

    /**
     * @notice emitted when the list of supported borrow assets is updated
     * @param borrowToken address of the borrow asset
     * @param isSupported true if borrowToken is a valid borrow asset, false if borrowToken is an invalid borrow asset
     */
    event BorrowTokenUpdated(address indexed borrowToken, bool isSupported);

    /**
     * @notice emitted when the list of supported collateral assets is updated
     * @param collateralToken address of the collateral asset
     * @param isSupported true if collateralToken is a valid collateral asset, false if collateralToken is an invalid collateral asset
     */
    event CollateralTokenUpdated(address indexed collateralToken, bool isSupported);

    /**
     * @notice emitted when no strategy address in the pool is updated
     * @param noStrategy address of noYield contract
     */
    event NoStrategyUpdated(address noStrategy);

    function savingsAccount() external view returns (address);

    function owner() external view returns (address);

    function poolRegistry(address pool) external view returns (bool);

    function priceOracle() external view returns (address);

    function extension() external view returns (address);

    function repaymentImpl() external view returns (address);

    function userRegistry() external view returns (address);

    function collectionPeriod() external view returns (uint256);

    function loanWithdrawalDuration() external view returns (uint256);

    function marginCallDuration() external view returns (uint256);

    function minBorrowFraction() external view returns (uint256);

    function liquidatorRewardFraction() external view returns (uint256);

    function poolCancelPenaltyMultiple() external view returns (uint256);

    function getProtocolFeeData() external view returns (uint256, address);

    function noStrategyAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

interface IPriceOracle {
    /**
     * @notice emitted when chainlink price feed for a token is updated
     * @param token address of token for which price feed is updated
     * @param priceOracle address of the updated price feed for the token
     */
    event ChainlinkFeedUpdated(address indexed token, address indexed priceOracle);

    /**
     * @notice emitted when uniswap price feed for a token pair is updated
     * @param token1 address of numerator address in price feed
     * @param token2 address of denominator address in price feed
     * @param feedId unique id for the token pair irrespective of the order of tokens
     * @param pool address of the pool from which price feed can be queried
     */
    event UniswapFeedUpdated(address indexed token1, address indexed token2, bytes32 feedId, address indexed pool);

    /**
     * @notice emitted when price averaging window for uniswap price feeds is updated
     * @param uniswapPriceAveragingPeriod period during which uniswap prices are averaged over to avoid attacks
     */
    event UniswapPriceAveragingPeriodUpdated(uint32 uniswapPriceAveragingPeriod);

    function getLatestPrice(address num, address den) external view returns (uint256, uint256);

    function doesFeedExist(address token1, address token2) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IYield {
    /**
     * @dev emitted when tokens are locked
     * @param user the address of user, tokens locked for
     * @param investedTo the address of contract to invest in
     * @param lpTokensReceived the amount of shares received
     **/
    event LockedTokens(address indexed user, address indexed investedTo, uint256 lpTokensReceived);

    /**
     * @dev emitted when tokens are unlocked/redeemed
     * @param investedTo the address of contract invested in
     * @param collateralReceived the amount of underlying asset received
     **/
    event UnlockedTokens(address indexed investedTo, uint256 collateralReceived);

    /**
     * @notice emitted when a shares are unlocked from yield
     * @param asset address of the base token for which shares are being withdrawn
     * @param sharesReleased amount of shares unlocked
     */
    event UnlockedShares(address indexed asset, uint256 sharesReleased);

    /**
     * @notice emitted when savings account address is updated
     * @param savingsAccount updated address of the savings account contract
     */
    event SavingsAccountUpdated(address indexed savingsAccount);

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
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRepayment {
    /// @notice Event emitted when interest for the loann is partially repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when all interest for the pool is repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaymentComplete(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when pricipal is repaid
    /// @param poolID The address of the pool to which principal was paid
    /// @param repayAmount Amount being repayed
    event PrincipalRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when Grace penalty and interest for previous period is completely repaid
    /// @param poolID The address of the pool to which repayment was made
    /// @param repayAmount Amount being repayed
    event GracePenaltyRepaid(address indexed poolID, uint256 repayAmount);

    /// @notice Event emitted when repayment for extension is completely done
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being re-payed by the borrower
    event ExtensionRepaid(address indexed poolID, uint256 repayAmount); // Made during current period interest repayment

    /// @notice Event to denote changes in the configurations of the pool factory
    /// @param poolFactory updated pool factory address
    event PoolFactoryUpdated(address indexed poolFactory);

    /// @notice Event to denote changes in the configurations of the Grace Penalty Rate
    /// @param gracePenaltyRate updated gracePenaltyRate
    event GracePenaltyRateUpdated(uint256 indexed gracePenaltyRate);

    /// @notice Event to denote changes in the configurations of the Grace Period Fraction
    /// @param gracePeriodFraction updated gracePeriodFraction
    event GracePeriodFractionUpdated(uint256 indexed gracePeriodFraction);

    function initializeRepayment(
        uint256 numberOfTotalRepayments,
        uint256 repaymentInterval,
        uint256 borrowRate,
        uint256 loanStartTime,
        address lentAsset
    ) external;

    function getTotalRepaidAmount(address poolID) external view returns (uint256);

    function getInterestCalculationVars(address poolID) external view returns (uint256, uint256);

    function getCurrentLoanInterval(address poolID) external view returns (uint256);

    function instalmentDeadlineExtended(address _poolID) external;

    function didBorrowerDefault(address _poolID) external view returns (bool);

    function getGracePeriodFraction() external view returns (uint256);

    function getNextInstalmentDeadline(address _poolID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ISavingsAccount {
    /**
     * @notice emitted when tokens are deposited into savings account
     * @param user address of user depositing the tokens
     * @param sharesReceived amount of shares received for deposit
     * @param token address of token that is deposited
     * @param strategy strategy into which tokens are deposited
     */
    event Deposited(address indexed user, uint256 sharesReceived, address indexed token, address indexed strategy);

    /**
     * @notice emitted when tokens are switched from one strategy to another
     * @param user address of user switching strategies
     * @param token address of token for which strategies are switched
     * @param sharesDecreasedInCurrentStrategy shares decreased in current strategy
     * @param sharesIncreasedInNewStrategy shares increased in new strategy
     * @param currentStrategy address of the strategy from which tokens are switched
     * @param newStrategy address of the strategy to which tokens are switched
     */
    event StrategySwitched(
        address indexed user,
        address indexed token,
        uint256 sharesDecreasedInCurrentStrategy,
        uint256 sharesIncreasedInNewStrategy,
        address currentStrategy,
        address indexed newStrategy
    );

    /**
     * @notice emitted when tokens are withdrawn from savings account
     * @param from address of user from which tokens are withdrawn
     * @param to address of user to which tokens are withdrawn
     * @param sharesWithdrawn amount of shares withdrawn
     * @param token address of token that is withdrawn
     * @param strategy strategy into which tokens are withdrawn
     */
    event Withdrawn(address indexed from, address indexed to, uint256 sharesWithdrawn, address indexed token, address strategy);

    /**
     * @notice emitted when all tokens are withdrawn
     * @param user address of user withdrawing tokens
     * @param tokenReceived amount of tokens withdrawn
     * @param token address of the token withdrawn
     */
    event WithdrawnAll(address indexed user, uint256 tokenReceived, address indexed token);

    /**
     * @notice emitted when tokens are approved
     * @param token address of token approved
     * @param from address of user from who tokens are approved
     * @param to address of user to whom tokens are approved
     * @param amount amount of tokens approved
     */
    event Approved(address indexed token, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when tokens are transferred
     * @param token address of token transferred
     * @param strategy address of strategy from which tokens are transferred
     * @param from address of user from whom tokens are transferred
     * @param to address of user to whom tokens are transferred
     * @param amount amount of tokens transferred
     */
    event Transfer(address indexed token, address strategy, address indexed from, address indexed to, uint256 amount);

    /**
     * @notice emitted when credit line address is updated
     * @param updatedCreditLine updated credit line contract address
     */
    event CreditLineUpdated(address indexed updatedCreditLine);

    /**
     * @notice emitted when strategy registry is updated
     * @param updatedStrategyRegistry updated strategy registry address
     */
    event StrategyRegistryUpdated(address indexed updatedStrategyRegistry);

    /**
     * @notice emitted when credit line allowance is refreshed
     * @param token token for which allowance is increased
     * @param from address of user from whcih allowance is increased
     * @param amount amount of tokens by which allowance is increased
     */
    event CreditLineAllowanceRefreshed(address indexed token, address indexed from, address indexed to, uint256 amount);

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
     * @param amount amount of tokens to be reinvested
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
     * @param amount amount of tokens to withdraw
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
pragma solidity 0.7.6;

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
pragma solidity 0.7.6;

interface IPool {
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

    /**
     * @notice emitted when borrower posts collateral
     * @param borrower address of the borrower
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event CollateralAdded(address indexed borrower, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower posts collateral after a margin call
     * @param borrower address of the borrower
     * @param lender lender who margin called
     * @param amount amount denominated in collateral asset
     * @param sharesReceived shares received after transferring collaterla to pool savings strategy
     */
    event MarginCallCollateralAdded(address indexed borrower, address indexed lender, uint256 amount, uint256 sharesReceived);

    /**
     * @notice emitted when borrower withdraws excess collateral
     * @param borrower address of borrower
     * @param amount amount of collateral withdrawn
     */
    event CollateralWithdrawn(address indexed borrower, uint256 amount);

    /**
     * @notice emitted when lender supplies liquidity to a pool
     * @param amountSupplied amount that was supplied
     * @param lenderAddress address of the lender. allows for delegation of lending
     */
    event LiquiditySupplied(uint256 amountSupplied, address indexed lenderAddress);

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
    event LiquidityWithdrawn(uint256 amount, address indexed lenderAddress);

    /**
     * @notice emitted when lender exercises a margin/collateral call
     * @param lenderAddress address of the lender who exercises margin calls
     */
    event MarginCalled(address indexed lenderAddress);

    /**
     * @notice emitted when collateral backing lender is liquidated because of a margin call
     * @param liquidator address that calls the liquidateForLender() function
     * @param lender lender who initially exercised the margin call
     * @param _tokenReceived amount received by liquidator denominated in collateral asset
     */
    event LenderLiquidated(address indexed liquidator, address indexed lender, uint256 _tokenReceived);

    /**
     * @notice emitted when a pool is liquidated for missing repayment
     * @param liquidator address of the liquidator
     */
    event PoolLiquidated(address indexed liquidator);

    function getLoanStatus() external view returns (uint256);

    function depositCollateral(uint256 _amount, bool _transferFromSavingsAccount) external payable;

    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _isDirect
    ) external payable;

    function withdrawBorrowedAmount() external;

    function borrower() external returns (address);

    function getMarginCallEndTime(address _lender) external returns (uint256);

    function getBalanceDetails(address _lender) external view returns (uint256, uint256);

    function totalSupply() external view returns (uint256);

    function closeLoan() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IExtension {
    /**
     * @notice emitted when the Voting Pass Ratio parameter for Pools is updated
     * @param votingPassRatio the new value of the voting pass threshold for  Pools
     */
    event VotingPassRatioUpdated(uint256 votingPassRatio);

    /**
     * @notice emitted when the pool factory is updated in extension
     * @param poolFactory updated address of pool factory
     */
    event PoolFactoryUpdated(address indexed poolFactory);

    /**
     * @notice emitted when an extension is requested by a borrower for Pools
     * @param extensionVoteEndTime the value of the vote end time for the requested extension
     */
    event ExtensionRequested(uint256 extensionVoteEndTime);

    /**
     * @notice emitted when the requested extension for Pools is approved
     * @param poolID the address of the pool for which extension passed
     */
    event ExtensionPassed(address poolID);

    /**
     * @notice emitted when the lender for Pools has voted on extension request
     * @param lender address of the lender who voted
     * @param totalExtensionSupport the value of the total extension support for the Pools
     * @param lastVoteTime the last time the lender has voted on an extension request
     */
    event LenderVoted(address indexed lender, uint256 totalExtensionSupport, uint256 lastVoteTime);

    function initializePoolExtension(uint256 _repaymentInterval) external;

    function closePoolExtension() external;

    function removeVotes(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IVerification {
    /// @notice Event emitted when a verifier is added as valid by admin
    /// @param verifier The address of the verifier contract to be added
    event VerifierAdded(address indexed verifier);

    /// @notice Event emitted when a verifier is to be marked as invalid by admin
    /// @param verifier The address of the verified contract to be marked as invalid
    event VerifierRemoved(address indexed verifier);

    /// @notice Event emitted when a master address is verified by a valid verifier
    /// @param masterAddress The masterAddress which is verifier by the verifier
    /// @param verifier The verifier which verified the masterAddress
    /// @param isMasterLinked Boolean that specifies if the master address is added as linked address as well. Only linked addresses are considered valid
    event UserRegistered(address indexed masterAddress, address indexed verifier, bool indexed isMasterLinked);

    /// @notice Event emitted when a master address is marked as invalid/unregisterd by a valid verifier
    /// @param masterAddress The masterAddress which is unregistered
    /// @param verifier The verifier which verified the masterAddress
    /// @param unregisteredBy The msg.sender by which the user was unregistered
    event UserUnregistered(address indexed masterAddress, address indexed verifier, address indexed unregisteredBy);

    /// @notice Event emitted when an address is linked to masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address is linked
    event AddressLinked(address indexed linkedAddress, address indexed masterAddress);

    /// @notice Event emitted when an address is unlinked from a masterAddress
    /// @param linkedAddress The address which is linked to masterAddress
    /// @param masterAddress The masterAddress to which address was linked
    event AddressUnlinked(address indexed linkedAddress, address indexed masterAddress);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
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