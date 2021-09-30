// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.0;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '../interfaces/IPool.sol';
import '../interfaces/IPoolFactory.sol';
import '../interfaces/IRepayment.sol';

/**
 * @title Repayments contract
 * @dev For accuracy considering base itself as (10**30)
 * @notice Implements the functions related to repayments (payments that
 * have to made by the borrower back to the pool)
 * @author Sublime
 */
contract Repayments is Initializable, IRepayment, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal _owner;
    IPoolFactory poolFactory;
    address savingsAccount;

    enum LoanStatus {
        COLLECTION, //denotes collection period
        ACTIVE, // denotes the active loan
        CLOSED, // Loan is repaid and closed
        CANCELLED, // Cancelled by borrower
        DEFAULTED, // Repaymennt defaulted by  borrower
        TERMINATED // Pool terminated by admin
    }

    uint256 votingPassRatio;
    uint256 gracePenaltyRate;
    uint256 gracePeriodFraction; // fraction of the repayment interval
    uint256 constant yearInSeconds = 365 days;

    struct RepaymentState {
        uint256 repaidAmount;
        bool isLoanExtensionActive;
        uint256 loanDurationCovered;
        uint256 loanExtensionPeriod; // period for which the extension was granted, ie, if loanExtensionPeriod is 7 * 10**30, 7th instalment can be repaid by 8th instalment deadline
    }

    struct RepaymentInfo {
        uint256 numberOfTotalRepayments; // using it to check if RepaymentDetails Exists as repayment Interval!=0 in any case
        uint256 gracePenaltyRate;
        uint256 gracePeriodFraction;
        uint256 loanDuration;
        uint256 repaymentInterval;
        uint256 borrowRate;
        uint256 loanStartTime;
        address repayAsset;
    }

    mapping(address => RepaymentState) public repayState;
    mapping(address => RepaymentInfo) public repayInfo;

    /// @notice Event emitted when interest for the loann is partially repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaid(address poolID, uint256 repayAmount);

    /// @notice Event emitted when all interest for the pool is repaid
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being repayed
    event InterestRepaymentComplete(address poolID, uint256 repayAmount);


    /// @notice Event emitted when pricipal is repaid
    /// @param poolID The address of the pool to which principal was paid
    /// @param repayAmount Amount being repayed
    event PrincipalRepaid(address poolID, uint256 repayAmount);

    /// @notice Event emitted when Grace penalty and interest for previous period is completely repaid
    /// @param poolID The address of the pool to which repayment was made
    /// @param repayAmount Amount being repayed
    event GracePenaltyRepaid(address poolID, uint256 repayAmount);

    /// @notice Event emitted when repayment for extension is partially done
    /// @param poolID The address of the pool to which the partial repayment was made
    /// @param repayAmount Amount being repayed
    event PartialExtensionRepaid(address poolID, uint256 repayAmount);

    /// @notice Event emitted when repayment for extension is completely done
    /// @param poolID The address of the pool to which interest was paid
    /// @param repayAmount Amount being re-payed by the borrower
    event ExtensionRepaymentComplete(address poolID, uint256 repayAmount); // Made during current period interest repayment

    /// @notice Event to denote changes in the configurations of the pool factory
    event PoolFactoryUpdated(address poolFactory);

    /// @notice Event to denote changes in the configurations of the Grace Penalty Rate
    event GracePenaltyRateUpdated(uint256 gracePenaltyRate);

    /// @notice Event to denote changes in the configurations of the Grace Period Fraction
    event GracePeriodFractionUpdated(uint256 gracePeriodFraction);

    /// @notice determines if the pool is active or not based on whether repayments have been started by the
    ///borrower for this particular pool or not
    /// @dev mapping(address => repayInfo) public repayInfo is imported from RepaymentStorage.sol
    /// @param _poolID address of the pool for which we want to test statu
    modifier isPoolInitialized(address _poolID) {
        require(repayInfo[_poolID].numberOfTotalRepayments != 0, 'Pool is not Initiliazed');
        _;
    }

    /// @notice modifier used to determine whether the current pool is valid or not
    /// @dev poolRegistry from IPoolFactory interface returns a bool
    modifier onlyValidPool() {
        require(poolFactory.poolRegistry(msg.sender), 'Repayments::onlyValidPool - Invalid Pool');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == poolFactory.owner(), 'Not owner');
        _;
    }

    /// @notice Initializes the contract (similar to a constructor)
    /// @dev Since we cannot use constructors when using OpenZeppelin Upgrades, we use the initialize function
    ///and the initializer modifier makes sure that this function is called only once
    /// @param _poolFactory The address of the pool factory
    /// @param _gracePenaltyRate The penalty rate levied in the grace period
    /// @param _gracePeriodFraction The fraction of repayment interval that will be allowed as grace period
    function initialize(
        address _poolFactory,
        uint256 _gracePenaltyRate,
        uint256 _gracePeriodFraction
    ) public initializer {
        _updatePoolFactory(_poolFactory);
        _updateGracePenaltyRate(_gracePenaltyRate);
        _updateGracePeriodFraction(_gracePeriodFraction);
    }

    function updatePoolFactory(address _poolFactory) public onlyOwner {
        _updatePoolFactory(_poolFactory);
    }

    function _updatePoolFactory(address _poolFactory) internal {
        require(_poolFactory != address(0), '0 address not allowed');
        poolFactory = IPoolFactory(_poolFactory);
        emit PoolFactoryUpdated(_poolFactory);
    }

    function updateGracePeriodFraction(uint256 _gracePeriodFraction) public onlyOwner {
        _updateGracePeriodFraction(_gracePeriodFraction);
    }

    function _updateGracePeriodFraction(uint256 _gracePeriodFraction) internal {
        gracePeriodFraction = _gracePeriodFraction;
        emit GracePeriodFractionUpdated(_gracePeriodFraction);
    }

    function updateGracePenaltyRate(uint256 _gracePenaltyRate) public onlyOwner {
        _updateGracePenaltyRate(_gracePenaltyRate);
    }

    function _updateGracePenaltyRate(uint256 _gracePenaltyRate) internal {
        gracePenaltyRate = _gracePenaltyRate;
        emit GracePenaltyRateUpdated(_gracePenaltyRate);
    }

    /// @notice For a valid pool, the repayment schedule is being initialized here
    /// @dev Imported from RepaymentStorage.sol repayInfo is a mapping(address => repayInfo)
    /// @param numberOfTotalRepayments The total number of repayments that will be required from the borrower
    /// @param repaymentInterval Intervals after which repayment will be due
    /// @param borrowRate The rate at which lending took place
    /// @param loanStartTime The starting time of the loan
    /// @param lentAsset The address of the asset that was lent (basically a ERC20 token address)
    function initializeRepayment(
        uint256 numberOfTotalRepayments,
        uint256 repaymentInterval,
        uint256 borrowRate,
        uint256 loanStartTime,
        address lentAsset
    ) external override onlyValidPool {
        repayInfo[msg.sender].gracePenaltyRate = gracePenaltyRate;
        repayInfo[msg.sender].gracePeriodFraction = gracePeriodFraction;
        repayInfo[msg.sender].numberOfTotalRepayments = numberOfTotalRepayments;
        repayInfo[msg.sender].loanDuration = repaymentInterval.mul(numberOfTotalRepayments).mul(10**30);
        repayInfo[msg.sender].repaymentInterval = repaymentInterval.mul(10**30);
        repayInfo[msg.sender].borrowRate = borrowRate;
        repayInfo[msg.sender].loanStartTime = loanStartTime.mul(10**30);
        repayInfo[msg.sender].repayAsset = lentAsset;
    }

    /*
     * @notice returns the number of repayment intervals that have been repaid,
     * if repayment interval = 10 secs, loan duration covered = 55 secs, repayment intervals covered = 5
     * @param _poolID address of the pool
     * @return scaled interest per second
     */

    function getInterestPerSecond(address _poolID) public view returns (uint256) {
        uint256 _activePrincipal = IPool(_poolID).getTokensLent();
        uint256 _interestPerSecond = _activePrincipal.mul(repayInfo[_poolID].borrowRate).div(yearInSeconds);
        return _interestPerSecond;
    }

    /// @notice This function determines the number of completed instalments
    /// @param _poolID The address of the pool for which we want the completed instalments
    /// @return scaled instalments completed
    function getInstalmentsCompleted(address _poolID) public view returns (uint256) {
        uint256 _repaymentInterval = repayInfo[_poolID].repaymentInterval;
        uint256 _loanDurationCovered = repayState[_poolID].loanDurationCovered;
        uint256 _instalmentsCompleted = _loanDurationCovered.div(_repaymentInterval).mul(10**30); // dividing exponents, returns whole number rounded down

        return _instalmentsCompleted;
    }

    /// @notice This function determines the interest that is due for the borrower till the current instalment deadline
    /// @param _poolID The address of the pool for which we want the interest
    /// @return scaled interest due till instalment deadline
    function getInterestDueTillInstalmentDeadline(address _poolID) public view returns (uint256) {
        uint256 _interestPerSecond = getInterestPerSecond(_poolID);
        uint256 _nextInstalmentDeadline = getNextInstalmentDeadline(_poolID);
        uint256 _loanDurationCovered = repayState[_poolID].loanDurationCovered;
        uint256 _interestDueTillInstalmentDeadline = (
            _nextInstalmentDeadline.sub(repayInfo[_poolID].loanStartTime).sub(_loanDurationCovered)
        ).mul(_interestPerSecond).div(10**30);
        return _interestDueTillInstalmentDeadline;
    }

    /// @notice This function determines the timestamp of the next instalment deadline
    /// @param _poolID The address of the pool for which we want the next instalment deadline
    /// @return timestamp before which next instalment ends
    function getNextInstalmentDeadline(address _poolID) public view override returns (uint256) {
        uint256 _instalmentsCompleted = getInstalmentsCompleted(_poolID);
        if (_instalmentsCompleted == repayInfo[_poolID].numberOfTotalRepayments) {
            return 0;
        }
        uint256 _loanExtensionPeriod = repayState[_poolID].loanExtensionPeriod;
        uint256 _repaymentInterval = repayInfo[_poolID].repaymentInterval;
        uint256 _loanStartTime = repayInfo[_poolID].loanStartTime;
        uint256 _nextInstalmentDeadline;

        if (_loanExtensionPeriod > _instalmentsCompleted) {
            _nextInstalmentDeadline = ((_instalmentsCompleted.add(10**30).add(10**30)).mul(_repaymentInterval).div(10**30)).add(
                _loanStartTime
            );
        } else {
            _nextInstalmentDeadline = ((_instalmentsCompleted.add(10**30)).mul(_repaymentInterval).div(10**30)).add(_loanStartTime);
        }
        return _nextInstalmentDeadline;
    }

    /// @notice This function determine the current instalment interval
    /// @param _poolID The address of the pool for which we want the current instalment interval
    /// @return scaled instalment interval
    function getCurrentInstalmentInterval(address _poolID) public view returns (uint256) {
        uint256 _instalmentsCompleted = getInstalmentsCompleted(_poolID);
        return _instalmentsCompleted.add(10**30);
    }

    /// @notice This function determines the current (loan) interval
    /// @dev adding 10**30 to add 1. Considering base itself as (10**30)
    /// @param _poolID The address of the pool for which we want the current loan interval
    /// @return scaled current loan interval
    function getCurrentLoanInterval(address _poolID) external view override returns (uint256) {
        uint256 _loanStartTime = repayInfo[_poolID].loanStartTime;
        uint256 _currentTime = block.timestamp.mul(10**30);
        uint256 _repaymentInterval = repayInfo[_poolID].repaymentInterval;
        uint256 _currentInterval = ((_currentTime.sub(_loanStartTime)).mul(10**30).div(_repaymentInterval)).add(10**30);

        return _currentInterval;
    }

    /// @notice Check if grace penalty is applicable or not
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool for which we want to inquire if grace penalty is applicable or not
    /// @return boolean value indicating if applicable or not
    function isGracePenaltyApplicable(address _poolID) public view returns (bool) {
        //uint256 _loanStartTime = repayInfo[_poolID].loanStartTime;
        uint256 _repaymentInterval = repayInfo[_poolID].repaymentInterval;
        uint256 _currentTime = block.timestamp.mul(10**30);
        uint256 _gracePeriodFraction = repayInfo[_poolID].gracePeriodFraction;
        uint256 _nextInstalmentDeadline = getNextInstalmentDeadline(_poolID);
        uint256 _gracePeriodDeadline = _nextInstalmentDeadline.add(_gracePeriodFraction.mul(_repaymentInterval).div(10**30));

        require(_currentTime <= _gracePeriodDeadline, 'Borrower has defaulted');

        if (_currentTime <= _nextInstalmentDeadline) return false;
        else return true;
    }

    /// @notice Checks if the borrower has defaulted
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool from which borrower borrowed
    /// @return bool indicating whether the borrower has defaulted
    function didBorrowerDefault(address _poolID) public view override returns (bool) {
        uint256 _repaymentInterval = repayInfo[_poolID].repaymentInterval;
        uint256 _currentTime = block.timestamp.mul(10**30);
        uint256 _gracePeriodFraction = repayInfo[_poolID].gracePeriodFraction;
        uint256 _nextInstalmentDeadline = getNextInstalmentDeadline(_poolID);
        uint256 _gracePeriodDeadline = _nextInstalmentDeadline.add(_gracePeriodFraction.mul(_repaymentInterval).div(10**30));
        if (_currentTime > _gracePeriodDeadline) return true;
        else return false;
    }

    /// @notice Determines entire interest remaining to be paid for the loan issued to the borrower
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool for which we want to calculate remaining interest
    /// @return interest remaining
    function getInterestLeft(address _poolID) public view returns (uint256) {
        uint256 _interestPerSecond = getInterestPerSecond((_poolID));
        uint256 _loanDurationLeft = repayInfo[_poolID].loanDuration.sub(repayState[_poolID].loanDurationCovered);
        uint256 _interestLeft = _interestPerSecond.mul(_loanDurationLeft).div(10**30); // multiplying exponents

        return _interestLeft;
    }

    /// @notice Given there is no loan extension, find the overdue interest after missing the repayment deadline
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool
    /// @return interest amount that is overdue
    function getInterestOverdue(address _poolID) public view returns (uint256) {
        require(repayState[_poolID].isLoanExtensionActive == true, 'No overdue');
        uint256 _instalmentsCompleted = getInstalmentsCompleted(_poolID);
        uint256 _interestPerSecond = getInterestPerSecond(_poolID);
        uint256 _interestOverdue = (
            (
                (_instalmentsCompleted.add(10**30)).mul(repayInfo[_poolID].repaymentInterval).div(10**30).sub(
                    repayState[_poolID].loanDurationCovered
                )
            )
        ).mul(_interestPerSecond).div(10**30);
        return _interestOverdue;
    }

    /// @notice Used to for your overdues, grace penalty and interest
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool
    /// @param _amount amount repaid by the borrower
    function repay(address _poolID, uint256 _amount) public payable nonReentrant isPoolInitialized(_poolID) {
        IPool _pool = IPool(_poolID);
        _amount = _amount * 10**30;
        uint256 _loanStatus = _pool.getLoanStatus();
        require(_loanStatus == 1, 'Repayments:repayInterest Pool should be active.');

        uint256 _amountRequired = 0;
        uint256 _interestPerSecond = getInterestPerSecond(_poolID);
        // First pay off the overdue

        if (repayState[_poolID].isLoanExtensionActive == true) {
            uint256 _interestOverdue = getInterestOverdue(_poolID);

            if (_amount >= _interestOverdue) {
                _amount = _amount.sub(_interestOverdue);
                _amountRequired = _amountRequired.add(_interestOverdue);
                repayState[_poolID].isLoanExtensionActive = false; // deactivate loan extension flag
                repayState[_poolID].loanDurationCovered = (getInstalmentsCompleted(_poolID).add(10**30))
                    .mul(repayInfo[_poolID].repaymentInterval)
                    .div(10**30);
                emit ExtensionRepaymentComplete(_poolID, _interestOverdue);
            } else {
                _amountRequired = _amountRequired.add(_amount);
                repayState[_poolID].loanDurationCovered = repayState[_poolID].loanDurationCovered.add(
                    _amount.mul(10**30).div(_interestPerSecond)
                );
                emit PartialExtensionRepaid(_poolID, _amount);
                _amount = 0;
            }
        }
        // Second pay off the interest
        if (_amount != 0) {
            uint256 _interestLeft = getInterestLeft(_poolID);
            bool _isBorrowerLate = isGracePenaltyApplicable(_poolID);

            // adding grace penalty if applicable
            if (_isBorrowerLate) {
                uint256 _penalty = repayInfo[_poolID].gracePenaltyRate.mul(getInterestDueTillInstalmentDeadline(_poolID)).div(
                    10**30
                );
                _amount = _amount.sub(_penalty);
                _amountRequired = _amountRequired.add(_penalty);
                emit GracePenaltyRepaid(_poolID, _penalty);
            }

            if (_amount < _interestLeft) {
                uint256 _loanDurationCovered = _amount.mul(10**30).div(_interestPerSecond); // dividing exponents
                repayState[_poolID].loanDurationCovered = repayState[_poolID].loanDurationCovered.add(_loanDurationCovered);
                _amountRequired = _amountRequired.add(_amount);
                emit InterestRepaid(_poolID, _amount);
            } else {
                repayState[_poolID].loanDurationCovered = repayInfo[_poolID].loanDuration; // full interest repaid
                _amount = _amount.sub(_interestLeft);
                _amountRequired = _amountRequired.add(_interestLeft);
                emit InterestRepaymentComplete(_poolID, _amount);
            }
        }
        address _asset = repayInfo[_poolID].repayAsset;

        require(_amountRequired != 0, 'Repayments::repayAmount not necessary');
        _amountRequired = _amountRequired.div(10**30);
        repayState[_poolID].repaidAmount = repayState[_poolID].repaidAmount.add(_amountRequired);

        if (_asset == address(0)) {
            require(_amountRequired <= msg.value, 'Repayments::repayAmount amount does not match message value.');
            (bool success, ) = payable(address(_poolID)).call{value: _amountRequired}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, _poolID, _amountRequired);
        }

        if (_asset == address(0)) {
            if (msg.value > _amountRequired) {
                (bool success, ) = payable(address(msg.sender)).call{value: msg.value.sub(_amountRequired)}('');
                require(success, 'Transfer failed');
            }
        }
    }

    /// @notice Used to pay off the principal of the loan, once the overdues and interests are repaid
    /// @dev (10**30) is included to maintain the accuracy of the arithmetic operations
    /// @param _poolID address of the pool
    function repayPrincipal(address payable _poolID) public payable nonReentrant isPoolInitialized(_poolID) {
        IPool _pool = IPool(_poolID);
        uint256 _loanStatus = _pool.getLoanStatus();
        require(_loanStatus == 1, 'Repayments:repayPrincipal Pool should be active');

        require(repayState[_poolID].isLoanExtensionActive == false, 'Repayments:repayPrincipal Repayment overdue unpaid');

        require(
            repayInfo[_poolID].loanDuration == repayState[_poolID].loanDurationCovered,
            'Repayments:repayPrincipal Unpaid interest'
        );

        uint256 _amount = _pool.getTokensLent();

        address _asset = repayInfo[_poolID].repayAsset;

        if (_asset == address(0)) {
            require(_amount == msg.value, 'Repayments::repayAmount amount does not match message value.');
            (bool success, ) = _poolID.call{value: _amount}('');
            require(success, 'Transfer failed');
        } else {
            IERC20(_asset).safeTransferFrom(msg.sender, _poolID, _amount);
        }
        emit PrincipalRepaid(_poolID, _amount);

        IPool(_poolID).closeLoan();
    }

    /// @notice Returns the total amount that has been repaid by the borrower till now
    /// @param _poolID address of the pool
    /// @return total amount repaid
    function getTotalRepaidAmount(address _poolID) external view override returns (uint256) {
        return repayState[_poolID].repaidAmount;
    }

    /// @notice This function activates the instalment deadline
    /// @param _poolID address of the pool for which deadline is extended
    /// @param _period period for which the deadline is extended
    function instalmentDeadlineExtended(address _poolID, uint256 _period) external override {
        require(msg.sender == poolFactory.extension(), 'Repayments::repaymentExtended - Invalid caller');

        repayState[_poolID].isLoanExtensionActive = true;
        repayState[_poolID].loanExtensionPeriod = _period;
    }

    /// @notice Returns the loanDurationCovered till now and the interest per second which will help in interest calculation
    /// @param _poolID address of the pool for which we want to calculate interest
    /// @return Loan Duration Covered and the interest per second
    function getInterestCalculationVars(address _poolID) external view override returns (uint256, uint256) {
        uint256 _interestPerSecond = getInterestPerSecond(_poolID);
        return (repayState[_poolID].loanDurationCovered, _interestPerSecond);
    }

    /// @notice Returns the fraction of repayment interval decided as the grace period fraction
    /// @return grace period fraction
    function getGracePeriodFraction() external view override returns (uint256) {
        return gracePeriodFraction;
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

{
  "optimizer": {
    "enabled": true,
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}