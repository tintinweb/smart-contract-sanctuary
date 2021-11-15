// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/IYield.sol";
import "../interfaces/IRepayment.sol";
import "../interfaces/ISavingsAccount.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IExtension.sol";
import "../interfaces/IPoolToken.sol";

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
    IPoolToken public poolToken;

    struct LendingDetails {
        uint256 principalWithdrawn;
        uint256 interestWithdrawn;
        uint256 lastVoteTime;
        uint256 marginCallEndTime;
        uint256 extraLiquidityShares;
    }

    // Pool constants
    struct PoolConstants {
        address borrower;
        uint256 borrowAmountRequested;
        uint256 minborrowAmount;
        uint256 loanStartTime;
        uint256 loanWithdrawalDeadline;
        address borrowAsset;
        uint256 idealCollateralRatio;
        uint256 borrowRate;
        uint256 noOfRepaymentIntervals;
        uint256 repaymentInterval;
        address collateralAsset;
        address poolSavingsStrategy; // invest contract
    }

    struct PoolVars {
        uint256 baseLiquidityShares;
        uint256 extraLiquidityShares;
        LoanStatus loanStatus;
        uint256 noOfGracePeriodsTaken;
        uint256 nextDuePeriod;
        uint256 penalityLiquidityShares;
        uint256 penalityLiquidityAmount;
    }

    mapping(address => LendingDetails) public lenders;
    PoolConstants public poolConstants;
    PoolVars public poolVars;

    /// @notice Emitted when pool is cancelled either on borrower request or insufficient funds collected
    event OpenBorrowPoolCancelled();

    /// @notice Emitted when pool is terminated by admin
    event OpenBorrowPoolTerminated();

    /// @notice Emitted when pool is closed after repayments are complete
    event OpenBorrowPoolClosed();

    event CollateralAdded(
        address borrower,
        uint256 amount,
        uint256 sharesReceived
    );
    event MarginCallCollateralAdded(
        address borrower,
        address lender,
        uint256 amount,
        uint256 sharesReceived
    );
    event CollateralWithdrawn(address borrower, uint256 amount);
    event LiquiditySupplied(uint256 amountSupplied, address lenderAddress);
    event AmountBorrowed(uint256 amount);
    event LiquidityWithdrawn(uint256 amount, address lenderAddress);
    event MarginCalled(address lenderAddress);
    event LoanDefaulted();
    event LenderLiquidated(
        address liquidator,
        address lender,
        uint256 _tokenReceived
    );
    event PoolLiquidated(address liquidator);

    modifier OnlyBorrower(address _user) {
        require(_user == poolConstants.borrower, "1");
        _;
    }

    modifier isLender(address _lender) {
        require(poolToken.balanceOf(_lender) != 0, "2");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == IPoolFactory(PoolFactory).owner(), "3");
        _;
    }

    modifier onlyExtension {
        require(msg.sender == IPoolFactory(PoolFactory).extension(), "5");
        _;
    }

    function initialize(
        uint256 _borrowAmountRequested,
        uint256 _minborrowAmount,
        address _borrower,
        address _borrowAsset,
        address _collateralAsset,
        uint256 _idealCollateralRatio,
        uint256 _borrowRate,
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
        poolConstants.collateralAsset = _collateralAsset;
        poolConstants.poolSavingsStrategy = _poolSavingsStrategy;
        poolConstants.borrowAmountRequested = _borrowAmountRequested;

        _initialDeposit(
            _borrower,
            _collateralAmount,
            _transferFromSavingsAccount
        );

        poolConstants.borrower = _borrower;
        poolConstants.minborrowAmount = _minborrowAmount;
        poolConstants.borrowRate = _borrowRate;
        poolConstants.noOfRepaymentIntervals = _noOfRepaymentIntervals;
        poolConstants.repaymentInterval = _repaymentInterval;

        poolConstants.loanStartTime = block.timestamp.add(_collectionPeriod);
        poolConstants.loanWithdrawalDeadline = block
            .timestamp
            .add(_collectionPeriod)
            .add(_loanWithdrawalDuration);
    }

    function setPoolToken(address _poolToken) external override {
        require(msg.sender == PoolFactory, "6");
        poolToken = IPoolToken(_poolToken);
    }

    function depositCollateral(
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) public payable override {
        require(_amount != 0, "7");
        _depositCollateral(msg.sender, _amount, _transferFromSavingsAccount);
    }

    function _initialDeposit(
        address _borrower,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) internal {
        uint256 _equivalentCollateral =
            getEquivalentTokens(
                poolConstants.borrowAsset,
                poolConstants.collateralAsset,
                poolConstants.borrowAmountRequested
            );
        require(
            _amount >=
                poolConstants
                    .idealCollateralRatio
                    .mul(_equivalentCollateral)
                    .div(1e8),
            "36"
        );

        _depositCollateral(_borrower, _amount, _transferFromSavingsAccount);
    }

    function _depositCollateral(
        address _borrower,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) internal {
        uint256 _sharesReceived =
            _deposit(
                _transferFromSavingsAccount,
                true,
                poolConstants.collateralAsset,
                _amount,
                poolConstants.poolSavingsStrategy,
                _borrower,
                address(this)
            );

        poolVars.baseLiquidityShares = poolVars.baseLiquidityShares.add(
            _sharesReceived
        );
        emit CollateralAdded(_borrower, _amount, _sharesReceived);
    }

    function _depositFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        address _strategy,
        bool _withdrawShares,
        bool _toSavingsAccount
    ) internal returns (uint256) {
        if (_toSavingsAccount) {
            return
                _savingsAccountTransfer(
                    _savingsAccount,
                    _from,
                    _to,
                    _amount,
                    _asset,
                    _strategy
                );
        } else {
            return
                _withdrawFromSavingsAccount(
                    _savingsAccount,
                    _from,
                    _to,
                    _amount,
                    _asset,
                    _strategy,
                    _withdrawShares
                );
        }
    }

    function _directDeposit(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        bool _toSavingsAccount,
        address _strategy
    ) internal returns (uint256) {
        if (_toSavingsAccount) {
            return
                _directSavingsAccountDeposit(
                    _savingsAccount,
                    _from,
                    _to,
                    _amount,
                    _asset,
                    _strategy
                );
        } else {
            return _pullTokens(_asset, _amount, _from, _to);
        }
    }

    function _directSavingsAccountDeposit(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        address _strategy
    ) internal returns (uint256 _sharesReceived) {
        _pullTokens(_asset, _amount, _from, _to);
        uint256 _ethValue;
        if (_asset == address(0)) {
            _ethValue = _amount;
        } else {
            IERC20(_asset).safeApprove(_strategy, _amount);
        }
        _sharesReceived = _savingsAccount.depositTo{value: _ethValue}(
            _amount,
            _asset,
            _strategy,
            _to
        );
    }

    function _savingsAccountTransfer(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        address _strategy
    ) internal returns (uint256) {
        if (_from == address(this)) {
            _savingsAccount.transfer(_asset, _to, _strategy, _amount);
        } else {
            _savingsAccount.transferFrom(
                _asset,
                _from,
                _to,
                _strategy,
                _amount
            );
        }
        return _amount;
    }

    function _withdrawFromSavingsAccount(
        ISavingsAccount _savingsAccount,
        address _from,
        address _to,
        uint256 _amount,
        address _asset,
        address _strategy,
        bool _withdrawShares
    ) internal returns (uint256 _amountReceived) {
        if (_from == address(this)) {
            _amountReceived = _savingsAccount.withdraw(
                payable(_to),
                _amount,
                _asset,
                _strategy,
                _withdrawShares
            );
        } else {
            _amountReceived = _savingsAccount.withdrawFrom(
                _from,
                payable(_to),
                _amount,
                _asset,
                _strategy,
                _withdrawShares
            );
        }
    }

    function _pullTokens(
        address _asset,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (uint256) {
        if (_asset == address(0)) {
            require(msg.value >= _amount, "");
            if (_to != address(this)) {
                payable(_to).transfer(_amount);
            }
            if (msg.value != _amount) {
                payable(address(msg.sender)).transfer(msg.value.sub(_amount));
            }
            return _amount;
        }

        IERC20(_asset).transferFrom(_from, _to, _amount);
        return _amount;
    }

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
            _sharesReceived = _depositFromSavingsAccount(
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
            _sharesReceived = _directDeposit(
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

    function addCollateralInMarginCall(
        address _lender,
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) external payable override {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, "9");

        require(lenders[_lender].marginCallEndTime >= block.timestamp, "10");

        require(_amount != 0, "11");

        uint256 _sharesReceived =
            _deposit(
                _transferFromSavingsAccount,
                true,
                poolConstants.collateralAsset,
                _amount,
                poolConstants.poolSavingsStrategy,
                msg.sender,
                address(this)
            );

        poolVars.extraLiquidityShares = poolVars.extraLiquidityShares.add(
            _sharesReceived
        );

        lenders[_lender].extraLiquidityShares = lenders[_lender]
            .extraLiquidityShares
            .add(_sharesReceived);

        if (
            getCurrentCollateralRatio(_lender) >=
            poolConstants.idealCollateralRatio
        ) {
            delete lenders[_lender].marginCallEndTime;
        }

        emit MarginCallCollateralAdded(
            msg.sender,
            _lender,
            _amount,
            _sharesReceived
        );
    }

    function withdrawBorrowedAmount()
        external
        override
        OnlyBorrower(msg.sender)
        nonReentrant
    {
        LoanStatus _poolStatus = poolVars.loanStatus;
        uint256 _tokensLent = poolToken.totalSupply();
        require(
            _poolStatus == LoanStatus.COLLECTION &&
                poolConstants.loanStartTime < block.timestamp,
            "12"
        );
        require(_tokensLent >= poolConstants.minborrowAmount, "");

        poolVars.loanStatus = LoanStatus.ACTIVE;
        uint256 _currentCollateralRatio = getCurrentCollateralRatio();

        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        require(
            _currentCollateralRatio >=
                poolConstants.idealCollateralRatio.sub(
                    _poolFactory.collateralVolatilityThreshold()
                ),
            "13"
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
        IExtension(_poolFactory.extension()).initializePoolExtension(
            _repaymentInterval
        );
        _withdrawFromSavingsAccount(
            ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount()),
            address(this),
            msg.sender,
            _tokensLent,
            poolConstants.borrowAsset,
            address(0),
            false
        );

        delete poolConstants.loanWithdrawalDeadline;
        emit AmountBorrowed(_tokensLent);
    }

    function _withdrawAllCollateral(uint256 _penality) internal {
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        address _collateralAsset = poolConstants.collateralAsset;
        uint256 _collateralShares =
            poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares).sub(
                _penality
            );

        uint256 _collateralTokens = _collateralShares;
        if (_poolSavingsStrategy != address(0)) {
            _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(
                _collateralShares,
                _collateralAsset
            );
        }

        uint256 _sharesReceived;
        if (_collateralShares != 0) {
            ISavingsAccount _savingsAccount =
                ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount());
            _sharesReceived = _savingsAccountTransfer(
                _savingsAccount,
                address(this),
                msg.sender,
                _collateralTokens,
                _collateralAsset,
                _poolSavingsStrategy
            );
        }
        emit CollateralWithdrawn(msg.sender, _sharesReceived);
        delete poolVars.baseLiquidityShares;
        delete poolVars.extraLiquidityShares;
    }

    function lend(
        address _lender,
        uint256 _amountLent,
        bool _fromSavingsAccount
    ) external payable nonReentrant {
        require(poolVars.loanStatus == LoanStatus.COLLECTION, "15");
        require(block.timestamp < poolConstants.loanStartTime, "16");
        uint256 _amount = _amountLent;
        uint256 _borrowAmountNeeded = poolConstants.borrowAmountRequested;
        uint256 _lentAmount = poolToken.totalSupply();
        if (_amountLent.add(_lentAmount) > _borrowAmountNeeded) {
            _amount = _borrowAmountNeeded.sub(_lentAmount);
        }

        address _borrowToken = poolConstants.borrowAsset;
        _deposit(
            _fromSavingsAccount,
            true,
            _borrowToken,
            _amount,
            poolConstants.poolSavingsStrategy,
            msg.sender,
            address(this)
        );
        poolToken.mint(_lender, _amount);
        emit LiquiditySupplied(_amount, _lender);
    }

    function beforeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public override {
        require(msg.sender == address(poolToken));
        require(lenders[_from].marginCallEndTime == 0, "18");
        require(lenders[_to].marginCallEndTime == 0, "19");

        //Withdraw repayments for user
        _withdrawRepayment(_from, true);
        _withdrawRepayment(_to, true);

        //transfer extra liquidity shares
        uint256 _liquidityShare = lenders[_from].extraLiquidityShares;
        if (_liquidityShare == 0) return;

        uint256 toTransfer = _liquidityShare;
        if (_amount != poolToken.balanceOf(_from)) {
            toTransfer = (_amount.mul(_liquidityShare)).div(
                poolToken.balanceOf(_from)
            );
        }

        lenders[_from].extraLiquidityShares = lenders[_from]
            .extraLiquidityShares
            .sub(toTransfer);

        lenders[_to].extraLiquidityShares = lenders[_to]
            .extraLiquidityShares
            .add(toTransfer);
    }

    function cancelPool() external {
        LoanStatus _poolStatus = poolVars.loanStatus;
        require(_poolStatus == LoanStatus.COLLECTION, "");

        if (
            poolConstants.loanStartTime < block.timestamp &&
            poolToken.totalSupply() < poolConstants.minborrowAmount
        ) {
            return _cancelPool(0);
        }

        if (poolConstants.loanWithdrawalDeadline > block.timestamp) {
            require(msg.sender == poolConstants.borrower, "");
        }
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralLiquidityShare = poolVars.baseLiquidityShares;
        uint256 penality =
            IPoolFactory(PoolFactory)
                .poolCancelPenalityFraction()
                .mul(_collateralLiquidityShare)
                .div(10**8);
        _cancelPool(penality);
    }

    function _cancelPool(uint256 _penality) internal {
        poolVars.loanStatus = LoanStatus.CANCELLED;
        poolVars.penalityLiquidityShares = _penality;
        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(_penality);
        poolToken.pause();
        emit OpenBorrowPoolCancelled();
    }

    function liquidateCancelPenality(
        bool _toSavingsAccount,
        bool _receiveLiquidityShare
    ) external {
        require(poolVars.loanStatus == LoanStatus.CANCELLED, "");
        require(poolVars.penalityLiquidityAmount == 0, "");
        address _poolFactory = PoolFactory;
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        uint256 _penalityLiquidityShares = poolVars.penalityLiquidityShares;
        address _collateralAsset = poolConstants.collateralAsset;
        // note: extra liquidity shares are not applicable as the loan never reaches active state
        uint256 _collateralLiquidityShare = poolVars.baseLiquidityShares;
        uint256 _liquidationTokens =
            correspondingBorrowTokens(
                _collateralLiquidityShare,
                _poolFactory,
                IPoolFactory(_poolFactory).poolCancelPenalityFraction()
            );
        IERC20(poolConstants.borrowAsset).transferFrom(
            msg.sender,
            address(this),
            _liquidationTokens
        );
        poolVars.penalityLiquidityAmount = _liquidationTokens;
        uint256 _penalityCollateral;
        if (!_receiveLiquidityShare) {
            _penalityCollateral = _poolSavingsStrategy == address(0)
                ? _penalityLiquidityShares
                : IYield(_poolSavingsStrategy).getTokensForShares(
                    _penalityLiquidityShares,
                    _collateralAsset
                );
        }
        _withdraw(
            _toSavingsAccount,
            _receiveLiquidityShare,
            poolConstants.collateralAsset,
            poolConstants.poolSavingsStrategy,
            _penalityLiquidityShares
        );
    }

    function terminateOpenBorrowPool() external onlyOwner {
        // TODO: Add delay before the transfer to admin can happen
        _withdrawAllCollateral(0);
        poolToken.pause();
        poolVars.loanStatus = LoanStatus.TERMINATED;
        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        emit OpenBorrowPoolTerminated();
    }

    function closeLoan() external payable OnlyBorrower(msg.sender) {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, "22");
        require(poolVars.nextDuePeriod == 0, "23");

        uint256 _principleToPayback = poolToken.totalSupply();
        address _borrowAsset = poolConstants.borrowAsset;

        _pullTokens(
            _borrowAsset,
            _principleToPayback,
            msg.sender,
            address(this)
        );

        poolVars.loanStatus = LoanStatus.CLOSED;

        IExtension(IPoolFactory(PoolFactory).extension()).closePoolExtension();
        _withdrawAllCollateral(0);
        poolToken.pause();

        emit OpenBorrowPoolClosed();
    }

    // Note - Only when closed, cancelled or terminated, lender can withdraw
    //burns all shares and returns total remaining repayments along with provided liquidity
    function withdrawLiquidity() external isLender(msg.sender) nonReentrant {
        LoanStatus _loanStatus = poolVars.loanStatus;

        require(
            _loanStatus == LoanStatus.CLOSED ||
                _loanStatus == LoanStatus.CANCELLED ||
                _loanStatus == LoanStatus.DEFAULTED,
            "24"
        );

        //get total repayments collected as per loan status (for closed, it returns 0)
        // uint256 _due = calculateRepaymentWithdrawable(msg.sender);

        //gets amount through liquidity shares
        uint256 _balance = poolToken.balanceOf(msg.sender);
        if (_loanStatus == LoanStatus.DEFAULTED) {
            uint256 _totalAsset;
            if (poolConstants.borrowAsset != address(0)) {
                _totalAsset = IERC20(poolConstants.borrowAsset).balanceOf(
                    address(this)
                );
            } else {
                _totalAsset = address(this).balance;
            }

            //assuming their will be no tokens in pool in any case except liquidation (to be checked) or we should store the amount in liquidate()
            _balance = _balance.mul(_totalAsset).div(poolToken.totalSupply());
        }

        if (_loanStatus == LoanStatus.CANCELLED) {
            _balance = _balance.add(
                _balance.mul(poolVars.penalityLiquidityAmount).div(
                    poolToken.totalSupply()
                )
            );
        }

        // _due = _balance.add(_due);

        // lenders[msg.sender].amountWithdrawn = lenders[msg.sender]
        //     .amountWithdrawn
        //     .add(_due);
        delete lenders[msg.sender].principalWithdrawn;

        //transfer repayment
        _withdrawRepayment(msg.sender, true);
        //to add transfer if not included in above (can be transferred with liquidity)

        poolToken.burn(msg.sender, _balance);
        //transfer liquidity provided
        _tokenTransfer(poolConstants.borrowAsset, msg.sender, _balance);

        // TODO: Something wrong in the below event. Please have a look
        poolToken.burn(msg.sender, _balance);
        emit LiquidityWithdrawn(_balance, msg.sender);
    }

    /**
     * @dev This function is executed by lender to exercise margin call
     * @dev It will revert in case collateral ratio is not below expected value
     * or the lender has already called it.
     */

    function requestMarginCall() external isLender(msg.sender) {
        require(poolVars.loanStatus == LoanStatus.ACTIVE, "4");

        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        require(
            poolConstants.idealCollateralRatio >
                getCurrentCollateralRatio(msg.sender).add(
                    _poolFactory.collateralVolatilityThreshold()
                ),
            "26"
        );

        lenders[msg.sender].marginCallEndTime = block.timestamp.add(
            _poolFactory.marginCallDuration()
        );

        emit MarginCalled(msg.sender);
    }

    // function transferRepayImpl(address repayment) external onlyOwner {}

    // function transferLenderImpl(address lenderImpl) external onlyOwner {
    //     require(lenderImpl != address(0), "Borrower: Lender address");
    //     _lender = lenderImpl;
    // }

    // event PoolLiquidated(bytes32 poolHash, address liquidator, uint256 amount);
    // //todo: add more details here
    // event Liquidated(address liquidator, address lender);

    // function amountPerPeriod() public view returns (uint256) {}

    function interestTillNow(uint256 _balance) public view returns (uint256) {
        uint256 _totalSupply = poolToken.totalSupply();
        uint256 _interestPerPeriod = interestPerPeriod(_balance);

        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);

        (uint256 _repaymentPeriodCovered, uint256 _repaymentOverdue) =
            IRepayment(_poolFactory.repaymentImpl()).getInterestCalculationVars(
                address(this)
            );

        uint256 _interestAccruedThisPeriod =
            (
                (block.timestamp).sub(poolConstants.loanStartTime).sub(
                    _repaymentPeriodCovered.mul(
                        poolConstants.repaymentInterval
                    ),
                    "Nothing to repay"
                )
            )
                .mul(_interestPerPeriod);

        uint256 _totalInterest =
            (_interestAccruedThisPeriod.add(_repaymentOverdue))
                .mul(_balance)
                .div(_totalSupply);
        return _totalInterest;
    }

    function calculateCollateralRatio(
        uint256 _balance,
        uint256 _liquidityShares
    ) public returns (uint256 _ratio) {
        uint256 _interest = interestTillNow(_balance);
        address _collateralAsset = poolConstants.collateralAsset;

        (uint256 _ratioOfPrices, uint256 _decimals) =
            IPriceOracle(IPoolFactory(PoolFactory).priceOracle())
                .getLatestPrice(_collateralAsset, poolConstants.borrowAsset);

        uint256 _currentCollateralTokens =
            poolConstants.poolSavingsStrategy == address(0)
                ? _liquidityShares
                : IYield(poolConstants.poolSavingsStrategy).getTokensForShares(
                    _liquidityShares,
                    _collateralAsset
                );

        _ratio = (
            _currentCollateralTokens.mul(_ratioOfPrices).div(10**_decimals)
        )
            .div(_balance.add(_interest));
    }

    function getCurrentCollateralRatio() public returns (uint256 _ratio) {
        uint256 _liquidityShares =
            poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares);

        _ratio = calculateCollateralRatio(
            poolToken.totalSupply(),
            _liquidityShares
        );
    }

    function getCurrentCollateralRatio(address _lender)
        public
        returns (uint256 _ratio)
    {
        uint256 _balanceOfLender = poolToken.balanceOf(_lender);
        uint256 _liquidityShares =
            (
                poolVars.baseLiquidityShares.mul(_balanceOfLender).div(
                    poolToken.totalSupply()
                )
            )
                .add(lenders[_lender].extraLiquidityShares);

        return (calculateCollateralRatio(_balanceOfLender, _liquidityShares));
    }

    function liquidatePool(
        bool _fromSavingsAccount,
        bool _toSavingsAccount,
        bool _recieveLiquidityShare
    ) external payable nonReentrant {
        LoanStatus _currentPoolStatus;
        address _poolFactory = PoolFactory;
        if (poolVars.loanStatus != LoanStatus.DEFAULTED) {
            _currentPoolStatus = checkRepayment();
        }
        require(
            _currentPoolStatus == LoanStatus.DEFAULTED,
            "Pool::liquidatePool - No reason to liquidate the pool"
        );

        address _collateralAsset = poolConstants.collateralAsset;
        address _borrowAsset = poolConstants.borrowAsset;
        uint256 _collateralLiquidityShare =
            poolVars.baseLiquidityShares.add(poolVars.extraLiquidityShares);
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;

        uint256 _collateralTokens = _collateralLiquidityShare;
        if (_poolSavingsStrategy != address(0)) {
            _collateralTokens = IYield(_poolSavingsStrategy).getTokensForShares(
                _collateralLiquidityShare,
                _collateralAsset
            );
        }

        uint256 _poolBorrowTokens =
            correspondingBorrowTokens(
                _collateralTokens,
                _poolFactory,
                IPoolFactory(_poolFactory).liquidatorRewardFraction()
            );

        _deposit(
            _fromSavingsAccount,
            false,
            _borrowAsset,
            _poolBorrowTokens,
            address(0),
            msg.sender,
            address(this)
        );

        _withdraw(
            _toSavingsAccount,
            _recieveLiquidityShare,
            _collateralAsset,
            _poolSavingsStrategy,
            _collateralTokens
        );

        delete poolVars.extraLiquidityShares;
        delete poolVars.baseLiquidityShares;
        emit PoolLiquidated(msg.sender);
    }

    function _withdraw(
        bool _toSavingsAccount,
        bool _recieveLiquidityShare,
        address _asset,
        address _poolSavingsStrategy,
        uint256 _amountInTokens
    ) internal returns (uint256) {
        ISavingsAccount _savingsAccount =
            ISavingsAccount(IPoolFactory(PoolFactory).savingsAccount());
        return
            _depositFromSavingsAccount(
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

    // TODO: Can this function be made public view ?
    function _canLenderBeLiquidated(address _lender) internal {
        require(
            (poolVars.loanStatus == LoanStatus.ACTIVE) &&
                (block.timestamp > poolConstants.loanWithdrawalDeadline),
            "27"
        );
        uint256 _marginCallEndTime = lenders[_lender].marginCallEndTime;
        require(_marginCallEndTime != 0, "No margin call has been called.");
        require(_marginCallEndTime < block.timestamp, "28");

        require(
            poolConstants.idealCollateralRatio.sub(
                IPoolFactory(PoolFactory).collateralVolatilityThreshold()
            ) > getCurrentCollateralRatio(_lender),
            "29"
        );
        require(poolToken.balanceOf(_lender) != 0, "30");
    }

    function updateLenderSharesDuringLiquidation(address _lender)
        internal
        returns (uint256 _lenderCollateralLPShare, uint256 _lenderBalance)
    {
        uint256 _poolBaseLPShares = poolVars.baseLiquidityShares;
        _lenderBalance = poolToken.balanceOf(_lender);

        uint256 _lenderBaseLPShares =
            (_poolBaseLPShares.mul(_lenderBalance)).div(
                poolToken.totalSupply()
            );
        uint256 _lenderExtraLPShares = lenders[_lender].extraLiquidityShares;
        poolVars.baseLiquidityShares = _poolBaseLPShares.sub(
            _lenderBaseLPShares
        );
        poolVars.extraLiquidityShares = poolVars.extraLiquidityShares.sub(
            _lenderExtraLPShares
        );

        _lenderCollateralLPShare = _lenderBaseLPShares.add(
            _lenderExtraLPShares
        );
    }

    function _liquidateLender(
        bool _fromSavingsAccount,
        address _lender,
        uint256 _lenderCollateralShare
    ) internal {
        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;

        address _poolFactory = PoolFactory;
        uint256 _lenderLiquidationTokens =
            correspondingBorrowTokens(_lenderCollateralShare, _poolFactory, 0);

        address _borrowAsset = poolConstants.borrowAsset;
        _deposit(
            _fromSavingsAccount,
            false,
            _borrowAsset,
            _lenderLiquidationTokens,
            _poolSavingsStrategy,
            msg.sender,
            _lender
        );

        _withdrawRepayment(_lender, true);
    }

    function liquidateLender(
        address _lender,
        bool _fromSavingsAccount,
        bool _toSavingsAccount,
        bool _recieveLiquidityShare
    ) public payable nonReentrant {
        _canLenderBeLiquidated(_lender);

        address _poolSavingsStrategy = poolConstants.poolSavingsStrategy;
        (uint256 _lenderCollateralLPShare, uint256 _lenderBalance) =
            updateLenderSharesDuringLiquidation(_lender);

        uint256 _lenderCollateralShare = _lenderCollateralLPShare;
        if (_poolSavingsStrategy != address(0)) {
            _lenderCollateralShare = IYield(_poolSavingsStrategy)
                .getTokensForShares(
                _lenderCollateralLPShare,
                poolConstants.collateralAsset
            );
        }

        _liquidateLender(_fromSavingsAccount, _lender, _lenderCollateralShare);

        uint256 _amountReceived =
            _withdraw(
                _toSavingsAccount,
                _recieveLiquidityShare,
                poolConstants.collateralAsset,
                _poolSavingsStrategy,
                _lenderCollateralShare
            );
        poolToken.burn(_lender, _lenderBalance);
        delete lenders[_lender];
        emit LenderLiquidated(msg.sender, _lender, _amountReceived);
    }

    function correspondingBorrowTokens(
        uint256 _totalCollateralTokens,
        address _poolFactory,
        uint256 _fraction
    ) public view returns (uint256) {
        IPoolFactory _PoolFactory = IPoolFactory(_poolFactory);
        (uint256 _ratioOfPrices, uint256 _decimals) =
            IPriceOracle(_PoolFactory.priceOracle()).getLatestPrice(
                poolConstants.collateralAsset,
                poolConstants.borrowAsset
            );
        return
            _totalCollateralTokens
                .mul(_ratioOfPrices)
                .mul(uint256(10**8).sub(_fraction))
                .div(10**8)
                .div(10**_decimals);
    }

    function checkRepayment() public returns (LoanStatus) {
        IPoolFactory _poolFactory = IPoolFactory(PoolFactory);
        uint256 _gracePeriodPenaltyFraction =
            _poolFactory.gracePeriodPenaltyFraction();
        uint256 _defaultDeadline =
            getNextDueTime().add(
                _gracePeriodPenaltyFraction.mul(poolConstants.repaymentInterval)
            );
        if (block.timestamp > _defaultDeadline) {
            poolVars.loanStatus = LoanStatus.DEFAULTED;
            IExtension(_poolFactory.extension()).closePoolExtension();
            return (LoanStatus.DEFAULTED);
        }
        return (poolVars.loanStatus);
    }

    function getNextDueTimeIfBorrower(address _borrower)
        external
        view
        override
        OnlyBorrower(_borrower)
        returns (uint256)
    {
        return getNextDueTime();
    }

    function getNextDueTime() public view returns (uint256) {
        return
            (poolVars.nextDuePeriod.mul(poolConstants.repaymentInterval)).add(
                poolConstants.loanStartTime
            );
    }

    function interestPerSecond(uint256 _principle)
        public
        view
        returns (uint256)
    {
        uint256 _interest =
            ((_principle).mul(poolConstants.borrowRate)).div(365 days);
        return _interest;
    }

    function interestPerPeriod(uint256 _balance) public view returns (uint256) {
        return (
            interestPerSecond(_balance).mul(poolConstants.repaymentInterval)
        );
    }

    function calculateCurrentPeriod() public view returns (uint256) {
        uint256 _currentPeriod =
            (block.timestamp.sub(poolConstants.loanStartTime, "34")).div(
                poolConstants.repaymentInterval
            );
        return _currentPeriod;
    }

    function calculateRepaymentWithdrawable(address _lender)
        internal
        view
        returns (uint256)
    {
        uint256 _totalRepaidAmount =
            IRepayment(IPoolFactory(PoolFactory).repaymentImpl())
                .getTotalRepaidAmount(address(this));

        uint256 _amountWithdrawable =
            (
                poolToken.balanceOf(_lender).mul(_totalRepaidAmount).div(
                    poolToken.totalSupply()
                )
            )
                .sub(lenders[_lender].interestWithdrawn);

        return _amountWithdrawable;
    }

    // Withdraw Repayment, Also all the extra state variables are added here only for the review

    function withdrawRepayment(bool _withdrawToSavingsAccount)
        external
        isLender(msg.sender)
    {
        _withdrawRepayment(msg.sender, _withdrawToSavingsAccount);
    }

    function _withdrawRepayment(address _lender, bool _withdrawToSavingsAccount)
        internal
    {
        uint256 _amountToWithdraw = calculateRepaymentWithdrawable(_lender);
        address _poolSavingsStrategy = address(0); //add defaultStrategy

        if (_amountToWithdraw == 0) {
            return;
        }

        _withdraw(
            _withdrawToSavingsAccount,
            false,
            poolConstants.borrowAsset,
            _poolSavingsStrategy,
            _amountToWithdraw
        );
        lenders[_lender].interestWithdrawn = lenders[_lender]
            .interestWithdrawn
            .add(_amountToWithdraw);
    }

    function getNextDuePeriod() external view override returns (uint256) {
        return poolVars.nextDuePeriod;
    }

    function getMarginCallEndTime(address _lender)
        external
        view
        override
        returns (uint256)
    {
        return lenders[_lender].marginCallEndTime;
    }

    function getTotalSupply() public view override returns (uint256) {
        return poolToken.totalSupply();
    }

    function getBalanceDetails(address _lender)
        public
        view
        override
        returns (uint256, uint256)
    {
        IPoolToken _poolToken = poolToken;
        return (_poolToken.balanceOf(_lender), _poolToken.totalSupply());
    }

    function grantExtension()
        external
        override
        onlyExtension
        returns (uint256)
    {
        uint256 _nextDuePeriod = poolVars.nextDuePeriod.add(1);
        poolVars.nextDuePeriod = _nextDuePeriod;
        return _nextDuePeriod;
    }

    function getLoanStatus() public view override returns (uint256) {
        return uint256(poolVars.loanStatus);
    }

    function _tokenTransfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_token != address(0)) {
            IERC20(poolConstants.borrowAsset).safeTransfer(_to, _amount);
        } else {
            payable(_to).transfer(_amount);
        }
    }

    receive() external payable {
        require(msg.sender == IPoolFactory(PoolFactory).savingsAccount(), "35");
    }

    function getEquivalentTokens(
        address _source,
        address _target,
        uint256 _amount
    ) public view returns (uint256) {
        (uint256 _price, uint256 _decimals) =
            IPriceOracle(IPoolFactory(PoolFactory).priceOracle())
                .getLatestPrice(_source, _target);
        return _amount.mul(_price).div(10**_decimals);
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

    function openBorrowPoolRegistry(address pool) external view returns (bool);

    function priceOracle() external view returns (address);

    function extension() external view returns (address);

    function repaymentImpl() external view returns (address);

    function collectionPeriod() external view returns (uint256);

    function matchCollateralRatioInterval() external view returns (uint256);

    function marginCallDuration() external view returns (uint256);

    function collateralVolatilityThreshold() external view returns (uint256);

    function gracePeriodPenaltyFraction() external view returns (uint256);

    function liquidatorRewardFraction() external view returns (uint256);

    function votingPassRatio() external view returns (uint256);

    function gracePeriodFraction() external view returns (uint256);

    function poolCancelPenalityFraction() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

interface IPriceOracle {
    function getLatestPrice(address num, address den)
        external
        view
        returns (uint256, uint256);

    function doesFeedExist(address btoken, address ctoken)
        external
        view
        returns (bool);
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
    event LockedTokens(
        address user,
        address investedTo,
        uint256 lpTokensReceived
    );

    /**
     * @dev emitted when tokens are unlocked/redeemed
     * @param investedTo the address of contract invested in
     * @param collateralReceived the amount of underlying asset received
     **/
    event UnlockedTokens(address investedTo, uint256 collateralReceived);

    event UnlockedShares(address asset, uint256 sharesReleased);

    /**
     * @dev Used to get liquidity token address from asset address
     * @param asset the address of underlying token
     * @return tokenAddress address of liquidity token
     **/
    function liquidityToken(address asset)
        external
        view
        returns (address tokenAddress);

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
    function unlockTokens(address asset, uint256 amount)
        external
        returns (uint256 tokensReceived);

    function unlockShares(address asset, uint256 amount)
        external
        returns (uint256 received);

    /**
     * @dev Used to get amount of underlying tokens for current number of shares
     * @param shares the amount of shares
     * @param asset the address of token locked
     * @return amount amount of underlying tokens
     **/
    function getTokensForShares(uint256 shares, address asset)
        external
        returns (uint256 amount);

    function getSharesForTokens(uint256 amount, address asset)
        external
        returns (uint256 shares);
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

    function calculateRepayAmount(address poolID)
        external
        view
        returns (uint256);

    function getTotalRepaidAmount(address poolID)
        external
        view
        returns (uint256);

    //function getRepaymentPeriodCovered(address poolID) external view returns(uint256);
    //function getRepaymentOverdue(address poolID) external view returns(uint256);
    function repaymentExtended(address poolID) external;

    function getInterestCalculationVars(address poolID)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ISavingsAccount {
    //events
    event Deposited(
        address user,
        uint256 amount,
        address asset,
        address strategy
    );
    event StrategySwitched(
        address user,
        address asset,
        address currentStrategy,
        address newStrategy
    );
    event Withdrawn(
        address from,
        address to,
        uint256 amountReceived,
        address token,
        address strategy
    );
    event WithdrawnAll(address user, uint256 tokenReceived, address asset);
    event Approved(address token, address from, address to, uint256 amount);
    event Transfer(
        address token,
        address strategy,
        address from,
        address to,
        uint256 amount
    );

    event CreditLineAllowanceRefreshed(
        address token,
        address from,
        uint256 amount
    );

    function depositTo(
        uint256 amount,
        address asset,
        address strategy,
        address to
    ) external payable returns (uint256 sharesReceived);

    /**
     * @dev Used to switch saving strategy of an asset
     * @param currentStrategy initial strategy of asset
     * @param newStrategy new strategy to invest
     * @param asset address of the asset
     * @param amount amount of **liquidity shares** to be reinvested
     */
    function switchStrategy(
        address currentStrategy,
        address newStrategy,
        address asset,
        uint256 amount
    ) external;

    /**
     * @dev Used to withdraw asset from Saving Account
     * @param withdrawTo address to which asset should be sent
     * @param amount amount of liquidity shares to withdraw
     * @param asset address of the asset to be withdrawn
     * @param strategy strategy from where asset has to withdrawn(ex:- compound,Aave etc)
     * @param withdrawShares boolean indicating to withdraw in liquidity share or underlying token
     */
    function withdraw(
        address payable withdrawTo,
        uint256 amount,
        address asset,
        address strategy,
        bool withdrawShares
    ) external returns (uint256);

    function withdrawAll(address _asset)
        external
        returns (uint256 tokenReceived);

    function approve(
        address token,
        address to,
        uint256 amount
    ) external;

    function transfer(
        address token,
        address to,
        address poolSavingsStrategy,
        uint256 amount
    ) external returns (uint256);

    function transferFrom(
        address token,
        address from,
        address to,
        address poolSavingsStrategy,
        uint256 amount
    ) external returns (uint256);

    function userLockedBalance(
        address user,
        address asset,
        address strategy
    ) external view returns (uint256);

    function approveFromToCreditLine(
        address token,
        address from,
        uint256 amount
    ) external;

    function withdrawFrom(
        address from,
        address payable to,
        uint256 amount,
        address asset,
        address strategy,
        bool withdrawShares
    ) external returns (uint256 amountReceived);

    function getTotalAsset(address _user, address _asset)
        external
        returns (uint256 _totalTokens);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

interface IPool {
    function getLoanStatus() external view returns (uint256);

    function depositCollateral(
        uint256 _amount,
        bool _transferFromSavingsAccount
    ) external payable;

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

    function setPoolToken(address _poolToken) external;

    //function borrower() external returns(address);

    function getNextDuePeriod() external returns (uint256);

    function getMarginCallEndTime(address _lender) external returns (uint256);

    function getNextDueTimeIfBorrower(address _borrower)
        external
        view
        returns (uint256);

    function grantExtension() external returns (uint256);

    function getBalanceDetails(address _lender)
        external
        view
        returns (uint256, uint256);

    function getTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IExtension {
    function initializePoolExtension(uint256 _repaymentInterval) external;

    function closePoolExtension() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolToken is IERC20 {
    function burn(address user, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function pause() external;
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

