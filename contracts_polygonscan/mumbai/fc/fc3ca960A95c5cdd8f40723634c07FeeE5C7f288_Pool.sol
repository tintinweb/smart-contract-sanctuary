// SPDX-License-Identifier: MIT
/// @dev size: 23.836 Kbytes
pragma solidity ^0.8.0;

import "./Lender.sol";
import "./Borrower.sol";
import "./PoolToken.sol";
import "../InterestRate/InterestRateModel.sol";

import "../security/Ownable.sol";

import "../Controller/ControllerInterface.sol";
import { IERC20Metadata } from "../ERC20/IERC20.sol";

contract Pool is Ownable, Lendable, Borrowable {
    string public name;

    bool public isInitialized;

    ControllerInterface public controller;
    IERC20Metadata public stableCoin;

    enum Access {
        Public,
        Private
    }
    uint8 public access;

    event AccessChanged(uint8 newAccess);

    constructor() {}

    function initialize(address _admin, address _stableCoin, string memory _name, uint256 _minDeposit, Access _access) external {
        _initialize(_admin, _stableCoin, _name, _minDeposit, _access);
    }

    function _initialize(address _admin, address _stableCoin, string memory _name, uint256 _minDeposit, Access _access) internal nonReentrant {
        isInitialized = true;

        name = _name;
        minDeposit = _minDeposit;
        access = uint8(_access);

        // Set the admin address
        owner = _admin;

        // set the controller
        controller = ControllerInterface(msg.sender);

        // Set the stable coin contract
        stableCoin = IERC20Metadata(_stableCoin);

        lpToken = new PoolToken("PoolToken", stableCoin.symbol());
    }

    function changeAccess(Access _access) external onlyOwner {
        access = uint8(_access);
        emit AccessChanged(access);
    }

    /// lender override methods
    function lend(uint256 amount) external returns (uint256) {
        return lendInternal(msg.sender, amount);
    }

    function redeem(uint256 tokens) external returns (uint256) {
        return redeemInternal(msg.sender, 0, tokens);
    }

    function redeemUnderlying(uint256 amount) external returns (uint256) {
        return redeemInternal(msg.sender, amount, 0);
    }

    function _transferTokens(address from, address to, uint256 amount) internal override returns (bool) {
        require(stableCoin.balanceOf(from) >= amount, toString(Error.INSUFFICIENT_FUNDS));
        if (from == address(this)) {
            require(stableCoin.transfer(to, amount), toString(Error.TRANSFER_FAILED));
        } else {
            require(stableCoin.transferFrom(from, to, amount), toString(Error.TRANSFER_FAILED));
        }
        return true;
    }

    function getCash() public override virtual view returns (uint256) {
        return stableCoin.balanceOf(address(this));
    }

    function lendAllowed(address _pool, address _lender, uint256 _amount) internal override returns (uint256) {
        return controller.lendAllowed(_pool, _lender, _amount);
    }

    function redeemAllowed(address _pool, address _redeemer, uint256 _tokenAmount) internal override returns (uint256) {
        return controller.redeemAllowed(_pool, _redeemer, _tokenAmount);
    }

    // borrower override methods
    struct CreditLineLocalVars {
        uint256 allowed;
        uint256 assetValue;
        uint256 borrowCap;
        uint256 interestRate;
        uint256 advanceRate;
        uint256 maturity;
    }
    function createCreditLine(uint256 tokenId) external nonReentrant returns (uint256) {
        CreditLineLocalVars memory vars;
        (
            vars.allowed, 
            vars.assetValue, 
            vars.maturity, 
            vars.interestRate, 
            vars.advanceRate
        ) = controller.createCreditLineAllowed(address(this), msg.sender, tokenId);
        if (vars.allowed != 0) {
            return uint256(Error.CONTROLLER_CREATE_REJECTION);
        }

        vars.borrowCap = vars.assetValue * vars.advanceRate / 100;
        return createCreditLineInternal(msg.sender, tokenId, vars.borrowCap, vars.interestRate, vars.maturity);
    }

    function closeCreditLine(uint256 loanId) external nonReentrant returns (uint256) {
        return closeCreditLineInternal(msg.sender, loanId);
    }

    function redeemAsset(uint256 tokenId) internal override returns (uint256) {
        controller.assetsFactory().markAsRedeemed(tokenId);
        return uint256(Error.NO_ERROR);
    }

    struct UnlockLocalVars {
        MathError mathErr;
        uint256 lockedAsset;
    }
    function unlockAsset(uint256 loanId) external nonReentrant returns (uint256) {
        UnlockLocalVars memory vars;

        (vars.mathErr, vars.lockedAsset) = unlockAssetInternal(msg.sender, loanId);
        ErrorReporter.check((uint256(vars.mathErr)));

        controller.assetsFactory().transferFrom(address(this), msg.sender, vars.lockedAsset);
        return uint256(Error.NO_ERROR);
    }

    function borrow(uint256 loanId, uint256 amount) external returns (uint256) {
        return borrowInternal(loanId, msg.sender, amount);
    }

    function repay(uint256 loanId, uint256 amount) external returns (uint256) {
        return repayInternal(loanId, msg.sender, msg.sender, amount);
    }

    function repayBehalf(address borrower, uint256 loanId, uint256 amount) external returns (uint256) {
        return repayInternal(loanId, msg.sender, borrower, amount);
    }

    function getTotalBorrowBalance() public virtual override(Lendable, Borrowable) view returns (uint256) {
        uint256 total;
        for (uint8 i = 0; i < creditLines.length; i++) {
            total += borrowBalanceSnapshot(i);
        }
        return total;
    }

    struct BorrowIndexLocalVars {
        MathError mathErr;
        uint256 blockNumber;
        uint256 accrualBlockNumber;
        uint256 priorBorrowIndex;
        uint256 newBorrowIndex;
        uint256 borrowRateMantissa;
        uint256 blockDelta;
        Exp interestFactor;
    }
    function getBorrowIndex(uint256 loanId) public override view returns (uint256) {
        CreditLine storage creditLine = creditLines[loanId];
        BorrowIndexLocalVars memory vars;

        vars.accrualBlockNumber = creditLine.accrualBlockNumber;
        vars.priorBorrowIndex = creditLine.borrowIndex;
        vars.blockNumber = getBlockNumber();

        /* Short-circuit accumulating 0 interest */
        if (vars.accrualBlockNumber == vars.blockNumber || vars.accrualBlockNumber == 0) {
            return vars.priorBorrowIndex;
        }

        vars.borrowRateMantissa = controller.interestRateModel().getBorrowRate(creditLine.interestRate);
        (vars.mathErr, vars.blockDelta) = subUInt(vars.blockNumber, vars.accrualBlockNumber);
        ErrorReporter.check((uint256(vars.mathErr)));

        (vars.mathErr, vars.interestFactor) = mulScalar(Exp({mantissa: vars.borrowRateMantissa}), vars.blockDelta);
        ErrorReporter.check((uint256(vars.mathErr)));

        (vars.mathErr, vars.newBorrowIndex) = mulScalarTruncateAddUInt(vars.interestFactor, vars.priorBorrowIndex, vars.priorBorrowIndex);
        ErrorReporter.check((uint256(vars.mathErr)));

        return vars.newBorrowIndex;
    }

    struct PenaltyIndexLocalVars {
        MathError mathErr;
        uint256 fee;
        uint256 principal;
        uint256 daysDelta;
        uint256 interestBlocksPerYear;
        uint256 penaltyIndex;
        uint256 penaltyAmount;
        uint256 accrualTimestamp;
        uint256 timestamp;
    }
    function getPenaltyIndexAndFee(uint256 loanId) public override view returns(uint256, uint256) {
        PenaltyInfo storage _penaltyInfo = penaltyInfo[loanId];

        if (creditLines[loanId].isClosed) {
            return (0, 0);
        }

        PenaltyIndexLocalVars memory vars;
        InterestRateModel.GracePeriod[] memory _gracePeriod;

        uint256 day = 24 * 60 * 60;
        vars.principal = creditLines[loanId].principal;
        vars.accrualTimestamp = _penaltyInfo.timestamp;
        vars.penaltyIndex = _penaltyInfo.index;
        vars.timestamp = getBlockTimestamp();

        (_gracePeriod, vars.interestBlocksPerYear) = controller.interestRateModel().getGracePeriodSnapshot();
        for(uint8 i=0; i < _gracePeriod.length; i++) {
            uint256 _start = _gracePeriod[i].start * day + _penaltyInfo.maturity;
            uint256 _end = _gracePeriod[i].end * day + _penaltyInfo.maturity;

            if (vars.timestamp >= _start) {
                if(vars.timestamp > _end) {
                    vars.daysDelta = _calculateDaysDelta(_end, vars.accrualTimestamp, _start, day);
                } else {
                    vars.daysDelta = _calculateDaysDelta(vars.timestamp, vars.accrualTimestamp, _start, day);
                }

                vars.penaltyIndex = calculatePenaltyIndexPerPeriod(_gracePeriod[i].fee, vars.interestBlocksPerYear, vars.daysDelta, vars.penaltyIndex);
                (vars.mathErr, vars.fee) = mulScalarTruncateAddUInt(Exp({mantissa: vars.penaltyIndex }), vars.principal, vars.fee);
                ErrorReporter.check((uint256(vars.mathErr)));
            }
        }

        if (vars.fee > 0) {
            (vars.mathErr, vars.penaltyAmount) = subUInt(vars.fee, vars.principal);
            ErrorReporter.check((uint256(vars.mathErr)));
        }
        return (vars.penaltyIndex, vars.penaltyAmount);
    }

    function _calculateDaysDelta(uint256 timestamp, uint256 acrrualTimestamp, uint256 _start, uint256 day) internal pure returns (uint256) {
        MathError mathErr;
        uint256 daysDelta;
        if (acrrualTimestamp > _start) {
            (mathErr, daysDelta) = subThenDivUInt(timestamp, acrrualTimestamp, day);
            ErrorReporter.check((uint256(mathErr)));
        } else {
            (mathErr, daysDelta) = subThenDivUInt(timestamp, _start, day);
            ErrorReporter.check((uint256(mathErr)));
        }
        return daysDelta;
    }

    function calculatePenaltyIndexPerPeriod(uint fee, uint256 blockPerYear, uint256 daysDelta, uint256 currentPenaltyIndex) internal pure returns (uint256) {
        Exp memory simpleInterestFactor;
        MathError mathErr;
        uint256 penaltyIndex;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa: fee / blockPerYear }), daysDelta);
        ErrorReporter.check((uint256(mathErr)));

        (mathErr, penaltyIndex) = mulScalarTruncateAddUInt(simpleInterestFactor, currentPenaltyIndex, currentPenaltyIndex);
        ErrorReporter.check((uint256(mathErr)));

        return penaltyIndex;
    }

    struct TransferLocalVars {
        MathError mathError;
        uint256 feesMantissa;
        uint256 feesAmount;
        uint256 amountWithoutFees;
    }
    function _transferTokensOnBorrow(address from, address to, uint256 amount) internal override returns (bool) {
        require(stableCoin.balanceOf(from) >= amount, toString(Error.INSUFFICIENT_FUNDS));

        TransferLocalVars memory vars;

        vars.feesMantissa = controller.provisionPool().getFeesPercent();

        (vars.mathError, vars.feesAmount) = mulScalarTruncate(Exp({ mantissa: vars.feesMantissa }), amount);
        ErrorReporter.check(uint256(vars.mathError));

        (vars.mathError, vars.amountWithoutFees) = subUInt(amount, vars.feesAmount);
        ErrorReporter.check(uint256(vars.mathError));

        require(stableCoin.transfer(to, vars.amountWithoutFees), toString(Error.TRANSFER_FAILED));
        require(stableCoin.transfer(controller.provisionPool.address, vars.feesAmount), toString(Error.TRANSFER_IN_RESERVE_POOL_FAILED));
        return true;
    }

    function _transferTokensOnRepay(address from, address to, uint256 amount, uint256 penaltyAmount) internal override returns (bool) {
        require(_transferTokens(from, to, amount), toString(Error.TRANSFER_FAILED));

        if (penaltyAmount > 0) {
            return _transferTokens(to, controller.provisionPool.address, penaltyAmount);
        }
        return true;
    }

    function borrowAllowed(address _pool, address _lender, uint256 _amount) internal override returns (uint256) {
        return controller.borrowAllowed(_pool, _lender, _amount);
    }

    function repayAllowed(address _pool, address _payer, address _borrower, uint256 _amount) internal override returns (uint256) {
        return controller.repayAllowed(_pool, _payer, _borrower, _amount);
    }

    function getBlockNumber() public virtual override view returns(uint256) {
        return block.number;
    }

    function getBlockTimestamp() public virtual override view returns(uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoolToken.sol";

import "../security/ReentrancyGuard.sol";
import "../utils/NonZeroAddressGuard.sol";
import { ErrorReporter, TokenErrorReporter } from "../utils/ErrorReporter.sol";
import "../utils/Exponential.sol";

abstract contract Lendable is ReentrancyGuard, NonZeroAddressGuard, Exponential, TokenErrorReporter {

    uint256 internal constant initialExchangeRate = 2e16;
    uint256 public minDeposit;

    PoolToken public lpToken;

    event Lend(address indexed account, uint256 amount, uint256 tokensAmount);
    event Redeem(address indexed account, uint256 amount, uint256 tokensAmount);

    struct LendLocalVars {
        MathError mathErr;
        uint256 exchangeRateMantissa;
        uint256 mintedTokens;
    }

    function lendInternal(address lender, uint256 amount) internal nonReentrant nonZeroAddress(lender) returns(uint256) {
        require(amount >= minDeposit, toString(Error.AMOUNT_LOWER_THAN_MIN_DEPOSIT));
        uint256 allowed = lendAllowed(address(this), lender, amount);
        require(allowed == 0, ErrorReporter.uint2str(allowed));

        LendLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateInternal();
        ErrorReporter.check(uint256(vars.mathErr));

        require(_transferTokens(lender, address(this), amount));

        (vars.mathErr, vars.mintedTokens) = divScalarByExpTruncate(amount, Exp({mantissa: vars.exchangeRateMantissa}));
        ErrorReporter.check(uint256(vars.mathErr));
        
        lpToken.mint(lender, vars.mintedTokens);

        emit Lend(lender, amount, vars.mintedTokens);
        return uint256(Error.NO_ERROR);
    }

    struct RedeemLocalVars {
        MathError mathErr;
        uint256 exchangeRateMantissa;
        uint256 redeemTokens;
        uint256 redeemAmount;
    }

    function redeemInternal(address redeemer, uint256 _amount, uint256 _tokenAmount) internal nonReentrant returns(uint256) {
        require(_amount == 0 || _tokenAmount == 0, "one of _amount or _tokenAmount must be zero");

        RedeemLocalVars memory vars;

        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateInternal();
        ErrorReporter.check(uint256(vars.mathErr));


        if (_tokenAmount > 0) {
            vars.redeemTokens = _tokenAmount;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa: vars.exchangeRateMantissa}), _tokenAmount);
            ErrorReporter.check(uint256(vars.mathErr));
        } else {
            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(_amount, Exp({mantissa: vars.exchangeRateMantissa}));
            ErrorReporter.check(uint256(vars.mathErr));

            vars.redeemAmount = _amount;
        }

        uint256 allowed = redeemAllowed(address(this), redeemer, vars.redeemTokens);
        require(allowed == 0, ErrorReporter.uint2str(allowed));

        require(balanceOf(redeemer) >= vars.redeemTokens, toString(Error.AMOUNT_HIGHER));
        require(this.getCash() >= vars.redeemAmount, toString(Error.NOT_ENOUGH_CASH));

        lpToken.burnFrom(redeemer, vars.redeemTokens);
        _transferTokens(address(this), redeemer, vars.redeemAmount);

        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens);
        return uint256(Error.NO_ERROR);
    }

    function exchangeRate() public view returns (uint256) {
        (MathError err, uint256 result) = exchangeRateInternal();
        ErrorReporter.check(uint256(err));
        return result;
    }

    function exchangeRateInternal() internal view returns (MathError, uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return (MathError.NO_ERROR, initialExchangeRate);
        } else {
            Exp memory _exchangeRate;

            uint256 totalCash = getCash();
            uint256 totalBorrowed = getTotalBorrowBalance();

            (MathError mathErr, uint256 cashPlusBorrows) = addUInt(totalCash, totalBorrowed);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }
            
            (mathErr, _exchangeRate) = getExp(cashPlusBorrows, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, _exchangeRate.mantissa);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return lpToken.balanceOf(account);
    }

    function balanceOfUnderlying(address owner) external view returns (uint256) {
        Exp memory _exchangeRate = Exp({ mantissa: exchangeRate() });
        (MathError mErr, uint balance) = mulScalarTruncate(_exchangeRate, balanceOf(owner));
        ErrorReporter.check(uint256(mErr));
        return balance;
    }

    function totalSupply() public virtual view returns (uint256) {
        return lpToken.totalSupply();
    }

    function getCash() public virtual view returns (uint256);
    function getTotalBorrowBalance() public virtual view returns (uint256);

    function _transferTokens(address from, address to, uint256 amount) internal virtual returns (bool);

    function lendAllowed(address _pool, address _lender, uint256 _amount) internal virtual returns (uint256);
    function redeemAllowed(address _pool, address _redeemer, uint256 _tokenAmount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../security/ReentrancyGuard.sol";
import "../utils/NonZeroAddressGuard.sol";
import { ErrorReporter, TokenErrorReporter } from "../utils/ErrorReporter.sol";

import "../utils/Exponential.sol";
import "../utils/Counters.sol";

abstract contract Borrowable is ReentrancyGuard, NonZeroAddressGuard, Exponential, TokenErrorReporter {
    using Counters for Counters.Counter;

    Counters.Counter private _loanIds;

    struct CreditLine {
        address borrower;
        uint256 borrowCap;
        uint256 borrowIndex;
        uint256 principal;
        uint256 lockedAsset;
        uint256 interestRate;
        uint256 accrualBlockNumber;
        bool isClosed;
    }

    struct PenaltyInfo {
        uint256 maturity;
        uint256 index;
        uint256 timestamp;
        bool isOpened;
    }

    CreditLine[] public creditLines;
    mapping(uint256 => PenaltyInfo) public penaltyInfo;

    mapping(uint256 => bool) public lockedAssetsIds;
    mapping(address => uint256[]) internal loansIdsByAddress;

    event CreditLineOpened(uint256 indexed loanId, uint256 indexed tokenId, address borrower, uint256 amount, uint256 maturity, uint256 interestRate);
    event CreditLineClosed(uint256 indexed loanId);
    event Borrowed(uint256 indexed loanId, uint256 _amount);
    event Repayed(uint256 indexed loanId, uint256 _amount, uint256 penaltyAmount);
    event AssetUnlocked(uint256 indexed tokenId);

    modifier onlyIfActive(uint256 _loanId, address borrower_) {
        _isActive(_loanId, borrower_);
        _;
    }

    function _isActive(uint256 _loanId, address borrower_) internal view {
        require(creditLines[_loanId].isClosed == false, toString(Error.LOAN_IS_ALREADY_CLOSED));
        require(creditLines[_loanId].borrower == borrower_, toString(Error.WRONG_BORROWER));
    }

    function totalPrincipal() public virtual view returns (uint256) {
        uint256 total = 0;
        for (uint8 i = 0; i < creditLines.length; i++) {
            total += creditLines[i].principal;
        }
        return total;
    }

    function totalInterestRate() public virtual view returns (uint256) {
        uint256 total = 0;
        for (uint8 i = 0; i < creditLines.length; i++) {
            total += creditLines[i].interestRate;
        }
        if (total != 0){
            return total / creditLines.length;
        }
        return total;
    }

    /** @dev used by rewards contract */
    function getBorrowerTotalPrincipal(address _borrower) external view returns (uint256) {
        uint256 balance;

        for(uint8 i=0; i < loansIdsByAddress[_borrower].length; i++) {
            uint256 loanId = loansIdsByAddress[_borrower][i];

            uint256 principal = creditLines[loanId].principal;
            bool penaltyStarted = penaltyInfo[loanId].isOpened;
            balance += penaltyStarted ? 0 : principal;
        }
        return balance;
    }

    function getBorrowerBalance(address _borrower) external view returns (uint256) {
        uint256 balance;

        for(uint8 i=0; i < loansIdsByAddress[_borrower].length; i++) {
            balance += borrowBalanceSnapshot(loansIdsByAddress[_borrower][i]);
        }
        return balance;
    }

    function borrowerSnapshot(uint256 loanId) external view returns (uint256, uint256) {
        (,uint256 penaltyAmount) = getPenaltyIndexAndFee(loanId);
        return (borrowBalanceSnapshot(loanId), penaltyAmount);
    }

    function getBorrowerLoans(address _borrower) external view returns(uint256[] memory) {
        return loansIdsByAddress[_borrower];
    }

    function createCreditLineInternal(address borrower, uint256 tokenId, uint256 borrowCap, uint256 interestRate, uint256 maturity) internal returns (uint256) {
        require(lockedAssetsIds[tokenId] == false, toString(Error.LOAN_ASSET_ALREADY_USED));
        uint256 loanId = _loanIds.current();
        _loanIds;

        lockedAssetsIds[tokenId] = true;
        loansIdsByAddress[borrower].push(loanId);

        creditLines.push(CreditLine({
            borrower: borrower,
            borrowCap: borrowCap,
            borrowIndex: mantissaOne,
            principal: 0,
            lockedAsset: tokenId,
            interestRate: interestRate,
            accrualBlockNumber: getBlockNumber(),
            isClosed: false
        }));

        penaltyInfo[loanId] = PenaltyInfo({
            maturity: maturity,
            index: mantissaOne,
            timestamp: maturity + 30 days,
            isOpened: false
        });

        emit CreditLineOpened(loanId, tokenId, borrower, borrowCap, maturity, interestRate);

        _loanIds.increment();
        return uint256(Error.NO_ERROR);
    }

    function closeCreditLineInternal(address borrower, uint256 loanId) internal onlyIfActive(loanId, borrower) returns (uint256) {
        CreditLine storage creditLine = creditLines[loanId];
        require(creditLine.principal == 0, "Debt should be 0");

        lockedAssetsIds[creditLine.lockedAsset] = false;
        creditLine.isClosed = true;
        delete penaltyInfo[loanId];

        emit CreditLineClosed(loanId);
        return redeemAsset(creditLine.lockedAsset);
    }

    function unlockAssetInternal(address borrower, uint256 loanId) internal returns (MathError, uint256) {
        CreditLine storage creditLine = creditLines[loanId];

        require(creditLine.borrower == borrower, toString(Error.WRONG_BORROWER));
        require(creditLine.isClosed == true, toString(Error.LOAN_IS_NOT_CLOSED));

        uint256 lockedAsset = creditLine.lockedAsset;
        // remove loan from the list
        delete creditLines[loanId];
        delete penaltyInfo[loanId];

        emit AssetUnlocked(lockedAsset);
        return (MathError.NO_ERROR, lockedAsset);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint256 availableAmount;
        uint256 currentBorrowBalance;
        uint256 newBorrowIndex;
        uint256 newPrincipal;
        uint256 currentTimestamp;
    }
    function borrowInternal(uint256 loanId, address borrower, uint256 amount) internal nonReentrant onlyIfActive(loanId, borrower) returns (uint256) {
        uint256 allowed = borrowAllowed(address(this), borrower, amount);
        require(allowed == 0, ErrorReporter.uint2str(allowed));
        
        CreditLine storage creditLine = creditLines[loanId];
        BorrowLocalVars memory vars;

        vars.currentTimestamp = getBlockTimestamp();
        require(vars.currentTimestamp < penaltyInfo[loanId].maturity, toString(Error.LOAN_IS_OVERDUE));

        (vars.mathErr, vars.availableAmount) = subUInt(creditLine.borrowCap, creditLine.principal);
        ErrorReporter.check(uint256(vars.mathErr));
        require(vars.availableAmount >= amount, toString(Error.INSUFFICIENT_FUNDS));

        vars.currentBorrowBalance = borrowBalanceSnapshot(loanId);
        vars.newBorrowIndex = getBorrowIndex(loanId);

        (vars.mathErr, vars.newPrincipal) = addUInt(vars.currentBorrowBalance, amount);
        require(vars.mathErr == MathError.NO_ERROR, "borrow: principal failed");

        creditLine.principal = vars.newPrincipal;
        creditLine.borrowIndex = vars.newBorrowIndex;
        creditLine.accrualBlockNumber = getBlockNumber();

        assert(_transferTokensOnBorrow(address(this), borrower, amount));
        emit Borrowed(loanId, amount);

        return uint256(Error.NO_ERROR);
    }

    struct RepayLocalVars {
        MathError mathErr;
        uint256 currentBorrowBalance;
        uint256 actualRepayAmount;
        uint256 penaltyIndex;
        uint256 penaltyAmount;
    }
    function repayInternal(uint256 loanId, address payer, address borrower, uint256 amount) internal onlyIfActive(loanId, borrower) nonReentrant returns (uint256) {
        uint256 allowed = repayAllowed(address(this), payer, borrower, amount);
        require(allowed == 0, toString(Error.CONTROLLER_REPAY_REJECTION));

        CreditLine storage creditLine = creditLines[loanId];
        PenaltyInfo storage _penaltyInfo = penaltyInfo[loanId];
        RepayLocalVars memory vars;

        vars.currentBorrowBalance = borrowBalanceSnapshot(loanId);
        (vars.penaltyIndex, vars.penaltyAmount) = getPenaltyIndexAndFee(loanId);

        if (vars.penaltyIndex - 1e18 > 1) {
            if (!_penaltyInfo.isOpened) {
                _penaltyInfo.isOpened = true;
            }
            _penaltyInfo.timestamp = getBlockTimestamp();
            (vars.mathErr, vars.actualRepayAmount) = addUInt(vars.currentBorrowBalance, vars.penaltyAmount);
            require(vars.mathErr == MathError.NO_ERROR, "repay: penalty amount failed");
        } else {
            vars.actualRepayAmount = vars.currentBorrowBalance;
        }

        if (amount == type(uint256).max) {
            amount = vars.actualRepayAmount;
        }
        require(vars.actualRepayAmount >= amount, toString(Error.AMOUNT_HIGHER));

        (vars.mathErr, creditLine.principal) = subUInt(vars.actualRepayAmount, amount);
        require(vars.mathErr == MathError.NO_ERROR, "repay: principal failed");
        
        creditLine.borrowIndex = getBorrowIndex(loanId);
        creditLine.accrualBlockNumber = getBlockNumber();
        _penaltyInfo.index = vars.penaltyIndex;

        assert(_transferTokensOnRepay(payer, address(this), amount, vars.penaltyAmount));
        
        emit Repayed(loanId, amount, vars.penaltyAmount);
        if (creditLine.principal == 0) {
            require(closeCreditLineInternal(borrower, loanId) == 0, "close failed");
        }

        return uint256(Error.NO_ERROR);
    }
    
    struct BorrowBalanceLocalVars {
        MathError mathErr;
        uint256 principalTimesIndex;
        uint256 borrowBalance;
        uint256 borrowIndex;
    }
    function borrowBalanceSnapshot(uint256 loanId) internal view returns (uint256) {
        CreditLine storage creditLine = creditLines[loanId];
        if(creditLine.principal == 0) {
            return 0;
        }

        BorrowBalanceLocalVars memory vars;

        vars.borrowIndex = getBorrowIndex(loanId);
        (vars.mathErr, vars.principalTimesIndex) = mulUInt(creditLine.principal, vars.borrowIndex);
        require(vars.mathErr == MathError.NO_ERROR, "principal times failed");

        (vars.mathErr, vars.borrowBalance) = divUInt(vars.principalTimesIndex, creditLine.borrowIndex);
        require(vars.mathErr == MathError.NO_ERROR, "borrowBalance failed");

        return vars.borrowBalance;
    }

    function _transferTokensOnBorrow(address from, address to, uint256 amount) internal virtual returns (bool);
    function _transferTokensOnRepay(address from, address to, uint256 amount, uint256 penaltyAmount) internal virtual returns (bool);

    function borrowAllowed(address _pool, address _borrower, uint256 _amount) internal virtual returns (uint256);
    function repayAllowed(address _pool, address _payer, address _borrower, uint256 _amount) internal virtual returns (uint256);
    function redeemAsset(uint256 tokenId) internal virtual returns (uint256);

    function getBorrowIndex(uint256 loanId) public virtual view returns (uint256);
    function getTotalBorrowBalance() public virtual view returns (uint256);
    function getPenaltyIndexAndFee(uint256 loanId) public virtual view returns (uint256, uint256);
    function getBlockNumber() public virtual returns(uint256);
    function getBlockTimestamp() public virtual returns(uint256);
}

// SPDX-License-Identifier: MIT
/// @dev size: 2.947 Kbytes
pragma solidity ^0.8.0;

import "../ERC20/ERC20Mintable.sol";

contract PoolToken is ERC20Mintable {
    /**
    * @dev Prefix for token symbol
    */
    string internal constant prefix = "lp";
    
    constructor(
        string memory name, 
        string memory underlyingSymbol
        ) ERC20Mintable(name, createPoolTokenSymbol(underlyingSymbol)) {}

    function createPoolTokenSymbol(string memory symbol) internal pure returns (string memory){
        return string(abi.encodePacked(prefix, symbol));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title InterestRateModel Interface
  * @author Amplify
  */
abstract contract InterestRateModel {
	bool public isInterestRateModel = true;

    struct GracePeriod {
        uint256 fee;
        uint256 start;
        uint256 end;
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows)`
     * @param cash The amount of cash in the pool
     * @param borrows The amount of borrows in the pool
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(uint256 cash, uint256 borrows) external virtual pure returns (uint256);

    /**
     * @notice Calculates the borrow rate for a given interest rate and GracePeriod length
     * @param interestRate The interest rate as a percentage number between [0, 100]
     * @return The borrow rate as a mantissa between  [0, 1e18]
     */
    function getBorrowRate(uint256 interestRate) external virtual view returns (uint256);

    /**
     * @notice Calculates the penalty fee for a given days range
     * @param index The index of the grace period record
     * @return The penalty fee as a mantissa between [0, 1e18]
     */
    function getPenaltyFee(uint8 index) external virtual view returns (uint256);

    /**
     * @notice Returns the penalty stages array
     */
    function getGracePeriod() external virtual view returns (GracePeriod[] memory);
    function getGracePeriodSnapshot() external virtual view returns (GracePeriod[] memory, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

    /// @notice owner address set on construction
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership role
     * @notice Changes the owner of this contract to a new address
     * @dev Only owner
     * @param _newOwner beneficiary to vest remaining tokens to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must be non-zero");
        
        address currentOwner = owner;
        require(_newOwner != currentOwner, "New owner cannot be the current owner");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../InterestRate/InterestRateModel.sol";
import "../Asset/AssetInterface.sol";
import "../LossProvisionPool/LossProvisionInterface.sol";
import { IERC20 } from "../ERC20/IERC20.sol";

abstract contract ControllerInterface {
    // Policy hooks
    function lendAllowed(address pool, address lender, uint256 amount) external virtual returns (uint256);
    function redeemAllowed(address pool, address redeemer, uint256 tokens) external virtual returns (uint256);
    function borrowAllowed(address pool, address borrower, uint256 amount) external virtual returns (uint256);
    function repayAllowed(address pool, address payer, address borrower, uint256 amount) external virtual returns (uint256);
    function createCreditLineAllowed(address pool, address borrower, uint256 collateralAsset) external virtual returns (uint256, uint256, uint256, uint256, uint256);


    function provisionPool() external virtual view returns (LossProvisionInterface);
    function interestRateModel() external virtual view returns (InterestRateModel);
    function assetsFactory() external virtual view returns (AssetInterface);
    function amptToken() external virtual view returns (IERC20);
    
    function containsStableCoin(address _stableCoin) external virtual view returns (bool);
    function getStableCoins() external virtual view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20Base {
    function balanceOf(address owner) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
}

interface IERC20 is IERC20Base {
    function totalSupply() external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity ^0.8.0;

abstract contract NonZeroAddressGuard {

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address must be non-zero");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        CONTROLLER_LEND_REJECTION,
        CONTROLLER_REDEEM_REJECTION,
        CONTROLLER_BORRROW_REJECTION,
        CONTROLLER_REPAY_REJECTION,
        CONTROLLER_CREATE_REJECTION,
        INSUFFICIENT_FUNDS,
        AMOUNT_LOWER_THAN_0,
        AMOUNT_HIGHER,
        AMOUNT_LOWER_THAN_MIN_DEPOSIT,
        NOT_ENOUGH_CASH,
        LOAN_HAS_DEBT,
        LOAN_IS_OVERDUE,
        LOAN_IS_NOT_CLOSED,
        LOAN_ASSET_ALREADY_USED,
        LOAN_IS_ALREADY_CLOSED,
        LOAN_PENALTY_NOT_PAYED,
        WRONG_BORROWER,
        TRANSFER_FAILED,
        TRANSFER_IN_RESERVE_POOL_FAILED,
        POOL_NOT_FOUND
    }

    event Failure(uint256 error, uint256 detail);

    function fail(Error err, uint256 info) internal returns (uint256) {
        emit Failure(uint256(err), info);

        return uint256(err);
    }

    function toString(Error err) internal pure returns (string memory) {
        return ErrorReporter.uint2str(uint256(err));
    }
}

contract ControllerErrorReporter {
    enum Error {
        NO_ERROR,
        POOL_NOT_ACTIVE,
        BORROW_CAP_EXCEEDED,
        NOT_ALLOWED_TO_CREATE_CREDIT_LINE,
        BORROWER_NOT_CREATED,
        BORROWER_IS_WHITELISTED,
        BORROWER_NOT_WHITELISTED,
        ALREADY_WHITELISTED,
        INVALID_OWNER,
        MATURITY_DATE_EXPIRED,
        ASSET_REDEEMED,
        AMPT_TOKEN_TRANSFER_FAILED,
        LENDER_NOT_WHITELISTED,
        BORROWER_NOT_MEMBER,
        LENDER_NOT_CREATED
    }

    event Failure(uint256 error, uint256 detail);

    function fail(Error err) internal returns (uint256) {
        emit Failure(uint256(err), 0);

        return uint256(err);
    }

    function toString(Error err) internal pure returns (string memory) {
        return ErrorReporter.uint2str(uint256(err));
    }
}

library ErrorReporter {
    function check(uint256 err) internal pure {
        require(err == 0, uint2str(uint256(err)));
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CarefulMath.sol";

abstract contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant halfScale = expScale / 2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    function truncate(Exp memory exp) pure internal returns(uint) {
        return exp.mantissa / expScale;
    }

     function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }
        return addUInt(truncate(product), addend);
    }

    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

abstract contract ERC20Mintable is ERC20Burnable {
    address internal _admin;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _admin = msg.sender;
    }

    function mint(address to, uint256 amount) public virtual {
        require(msg.sender == _admin, "ERC20: must have admin role to mint");
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

abstract contract ERC20Burnable is ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

     function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract CarefulMath {

    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    function mulUInt(uint a, uint b) internal pure returns(MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    function mulThenAddUInt(uint a, uint b, uint c) internal pure returns(MathError, uint) {
        (MathError err, uint mul) = mulUInt(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(mul, c);
    }

    function divUInt(uint a, uint b) internal pure returns(MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    function subUInt(uint a, uint b) internal pure returns(MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    function subThenDivUInt(uint a, uint b, uint c) internal pure returns(MathError, uint) {
        (MathError err, uint sub) = subUInt(a, b);

        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return divUInt(sub, c);
    }

    function addUInt(uint a, uint b) internal pure returns(MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721/IERC721.sol";

abstract contract AssetInterface is IERC721 {
    bool public isAssetsFactory = true;

    function getTokenInfo(uint256 _tokenId) external virtual view returns (uint256, uint256, uint256, uint256, string memory, string memory, address, bool);
    function markAsRedeemed(uint256 tokenId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LossProvisionInterface {
    bool public isLossProvision = true;

    /**
     * @notice Calculates the percentage of the loan's principal that is paid as fee: `(lossProvisionFee + buyBackProvisionFee)`
     * @return The total fees percentage as a mantissa between [0, 1e18]
     */
    function getFeesPercent() external virtual view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}