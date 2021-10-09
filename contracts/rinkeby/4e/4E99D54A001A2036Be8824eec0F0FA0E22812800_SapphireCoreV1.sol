// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {BaseERC20} from "../token/BaseERC20.sol";
import {IERC20} from "../token/IERC20.sol";
import {IERC20Metadata} from "../token/IERC20Metadata.sol";
import {SafeERC20} from "../lib/SafeERC20.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "../lib/Math.sol";
import {Adminable} from "../lib/Adminable.sol";
import {Address} from "../lib/Address.sol";
import {Bytes32} from "../lib/Bytes32.sol";
import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";
import {ISyntheticTokenV2} from "../token/ISyntheticTokenV2.sol";

import {SapphireTypes} from "./SapphireTypes.sol";
import {SapphireCoreStorage} from "./SapphireCoreStorage.sol";
import {SapphireAssessor} from "./SapphireAssessor.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

contract SapphireCoreV1 is Adminable, SapphireCoreStorage {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using Address for address;
    using Bytes32 for bytes32;

    /* ========== Events ========== */

    event ActionsOperated(
        SapphireTypes.Action[] _actions,
        SapphireTypes.ScoreProof _scoreProof,
        address indexed _user
    );

    event LiquidationFeesUpdated(
        uint256 _liquidationUserRatio,
        uint256 _liquidationArcRatio
    );

    event LimitsUpdated(
        uint256 _totalBorrowLimit,
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum
    );

    event IndexUpdated(
        uint256 _newIndex,
        uint256 _lastUpdateTime
    );

    event InterestRateUpdated(uint256 _value);

    event OracleUpdated(address _oracle);

    event PauseStatusUpdated(bool _pauseStatus);

    event InterestSetterUpdated(address _newInterestSetter);

    event PauseOperatorUpdated(address _newPauseOperator);

    event AssessorUpdated(address _newAssessor);

    event CollateralRatiosUpdated(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    );

    event FeeCollectorUpdated(
        address _feeCollector
    );

    event TokensWithdrawn(
        address indexed _token,
        address _destination,
        uint256 _amount
    );

    event ProofProtocolSet(string _protocol);

    /* ========== Admin Setters ========== */

    /**
     * @dev Initialize the protocol with the appropriate parameters. Can only be called once.
     *      IMPORTANT: the contract assumes the collateral contract is to be trusted.
     *      Make sure this is true before calling this function.
     *
     * @param _collateralAddress    The address of the collateral to be used
     * @param _syntheticAddress     The address of the synthetic token proxy
     * @param _oracleAddress        The address of the IOracle conforming contract
     * @param _interestSetter       The address which can update interest rates
     * @param _pauseOperator        The address which can pause the contract
     * @param _assessorAddress,     The address of assessor contract conforming ISapphireAssessor,
     *                              which provides credit score functionality
     * @param _feeCollector         The address of the ARC fee collector when a liquidation occurs
     * @param _highCollateralRatio  High limit of how much collateral is needed to borrow
     * @param _lowCollateralRatio   Low limit of how much collateral is needed to borrow
     * @param _liquidationUserRatio   How much is a user penalized if they go below their c-ratio
     * @param _liquidationArcRatio    How much of the liquidation profit should ARC take
     */
    function init(
        address _collateralAddress,
        address _syntheticAddress,
        address _oracleAddress,
        address _interestSetter,
        address _pauseOperator,
        address _assessorAddress,
        address _feeCollector,
        uint256 _highCollateralRatio,
        uint256 _lowCollateralRatio,
        uint256 _liquidationUserRatio,
        uint256 _liquidationArcRatio
    )
        external
        onlyAdmin
    {
        require(
            collateralAsset == address(0),
            "SapphireCoreV1: cannot re-initialize contract"
        );

        require(
            _collateralAddress != address(0),
            "SapphireCoreV1: collateral is required"
        );

        require(
            _syntheticAddress != address(0),
            "SapphireCoreV1: synthetic is required"
        );

        require(
            _collateralAddress.isContract() &&
            _syntheticAddress.isContract(),
            "SapphireCoreV1: collateral or synthetic are not contracts"
        );

        paused          = true;
        borrowIndex     = BASE;
        indexLastUpdate = currentTimestamp();
        collateralAsset = _collateralAddress;
        syntheticAsset  = _syntheticAddress;
        interestSetter  = _interestSetter;
        pauseOperator   = _pauseOperator;
        feeCollector    = _feeCollector;
        _proofProtocol   = "arcx.creditScore";

        IERC20Metadata collateral   = IERC20Metadata(collateralAsset);
        uint8 collateralDecimals    = collateral.decimals();

        require(
            collateralDecimals <= 18,
            "SapphireCoreV1: collateral has more than 18 decimals"
        );

        precisionScalar = 10 ** (18 - uint256(collateralDecimals));

        setAssessor(_assessorAddress);
        setOracle(_oracleAddress);
        setCollateralRatios(_lowCollateralRatio, _highCollateralRatio);
        _setFees(_liquidationUserRatio, _liquidationArcRatio);
    }

    /**
     * @dev Set the instance of the oracle to report prices from. Must conform to IOracle.sol
     *
     * @notice Can only be called by the admin
     *
     * @param _oracleAddress The address of the IOracle instance
     */
    function setOracle(
        address _oracleAddress
    )
        public
        onlyAdmin
    {
        require(
            _oracleAddress.isContract(),
            "SapphireCoreV1: oracle is not a contract"
        );

        require(
            _oracleAddress != address(oracle),
            "SapphireCoreV1: the same oracle is already set"
        );

        oracle = ISapphireOracle(_oracleAddress);
        emit OracleUpdated(_oracleAddress);
    }

    /**
     * @dev Set low and high collateral ratios of collateral value to debt.
     *
     * @notice Can only be called by the admin.
     *
     * @param _lowCollateralRatio The minimal allowed ratio expressed up to 18 decimal places
     * @param _highCollateralRatio The maximum allowed ratio expressed up to 18 decimal places
     */
    function setCollateralRatios(
        uint256 _lowCollateralRatio,
        uint256 _highCollateralRatio
    )
        public
        onlyAdmin
    {
        require(
            _lowCollateralRatio <= _highCollateralRatio,
            "SapphireCoreV1: high c-ratio is lower than the low c-ratio"
        );

        require(
            _lowCollateralRatio >= BASE,
            "SapphireCoreV1: collateral ratio has to be at least 1"
        );

        require(
            (_lowCollateralRatio != lowCollateralRatio) ||
            (_highCollateralRatio != highCollateralRatio),
            "SapphireCoreV1: the same ratios are already set"
        );

        lowCollateralRatio = _lowCollateralRatio;
        highCollateralRatio = _highCollateralRatio;

        emit CollateralRatiosUpdated(lowCollateralRatio, highCollateralRatio);
    }

    /**
     * @dev Set the fees in the system.
     *
     * @notice Can only be called by the admin.
     *
     * @param _liquidationUserRatio   Determines the penalty a user must pay by discounting
     *                              their collateral price to provide a profit incentive for liquidators
     * @param _liquidationArcRatio    The percentage of the profit earned from the liquidation, which feeCollector earns.
     */
    function setFees(
        uint256 _liquidationUserRatio,
        uint256 _liquidationArcRatio
    )
        public
        onlyAdmin
    {
        require(
            (_liquidationUserRatio != liquidationUserRatio) ||
            (_liquidationArcRatio != liquidationArcRatio),
            "SapphireCoreV1: the same fees are already set"
        );

        _setFees(_liquidationUserRatio, _liquidationArcRatio);
    }

    /**
     * @dev Set the limits of the system to ensure value can be capped.
     *
     * @notice Can only be called by the admin
     *
     * @param _totalBorrowLimit   Maximum amount of borrowed amount that can be held in the system.
     * @param _vaultBorrowMinimum The minimum allowed borrow amount for vault
     * @param _vaultBorrowMaximum The maximum allowed borrow amount for vault
     */
    function setLimits(
        uint256 _totalBorrowLimit,
        uint256 _vaultBorrowMinimum,
        uint256 _vaultBorrowMaximum
    )
        public
        onlyAdmin
    {
        require(
            _vaultBorrowMinimum <= _vaultBorrowMaximum &&
            _vaultBorrowMaximum <= _totalBorrowLimit,
            "SapphireCoreV1: required condition is vaultMin <= vaultMax <= totalLimit"
        );

        require(
            (_totalBorrowLimit != totalBorrowLimit) ||
            (_vaultBorrowMinimum != vaultBorrowMinimum) ||
            (_vaultBorrowMaximum != vaultBorrowMaximum),
            "SapphireCoreV1: the same limits are already set"
        );

        vaultBorrowMinimum = _vaultBorrowMinimum;
        vaultBorrowMaximum = _vaultBorrowMaximum;
        totalBorrowLimit = _totalBorrowLimit;

        emit LimitsUpdated(totalBorrowLimit, vaultBorrowMinimum, vaultBorrowMaximum);
    }

    /**
     * @dev Set the address which can set interest rate
     *
     * @notice Can only be called by the admin
     *
     * @param _interestSetter The address of the new interest rate setter
     */
    function setInterestSetter(
        address _interestSetter
    )
        external
        onlyAdmin
    {
        require(
            _interestSetter != interestSetter,
            "SapphireCoreV1: cannot set the same interest setter"
        );

        interestSetter = _interestSetter;
        emit InterestSetterUpdated(interestSetter);
    }

    function setPauseOperator(
        address _pauseOperator
    )
        external
        onlyAdmin
    {
        require(
            _pauseOperator != pauseOperator,
            "SapphireCoreV1: the same pause operator is already set"
        );

        pauseOperator = _pauseOperator;
        emit PauseOperatorUpdated(pauseOperator);
    }

    function setAssessor(
        address _assessor
    )
        public
        onlyAdmin
    {
        require(
            _assessor.isContract(),
            "SapphireCoreV1: the address is not a contract"
        );

        require(
            _assessor != address(assessor),
            "SapphireCoreV1: the same assessor is already set"
        );

        assessor = ISapphireAssessor(_assessor);
        emit AssessorUpdated(_assessor);
    }

    function setFeeCollector(
        address _newFeeCollector
    )
        external
        onlyAdmin
    {
        require(
            _newFeeCollector != address(feeCollector),
            "SapphireCoreV1: the same fee collector is already set"
        );

        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(feeCollector);
    }

    function setPause(
        bool _value
    )
        external
    {
        require(
            msg.sender == pauseOperator,
            "SapphireCoreV1: caller is not the pause operator"
        );

        require(
            _value != paused,
            "SapphireCoreV1: cannot set the same pause value"
        );

        paused = _value;
        emit PauseStatusUpdated(paused);
    }

    /**
     * @dev Update the interest rate of the protocol. Since this rate is compounded
     *      every second rather than being purely linear, the calculate for r is expressed
     *      as the following (assuming you want 5% APY):
     *
     *      r^N = 1.05
     *      since N = 365 * 24 * 60 * 60 (number of seconds in a year)
     *      r = 1.000000001547125957863212...
     *      rate = 1547125957 (r - 1e18 decimal places solidity value)
     *
     * @notice Can only be called by the interest setter of the protocol and the maximum
     *         rate settable is 99% (21820606489)
     *
     * @param _interestRate The interest rate expressed per second
     */
    function setInterestRate(
        uint256 _interestRate
    )
        external
    {

        require(
            msg.sender == interestSetter,
            "SapphireCoreV1: caller is not interest setter"
        );

        require(
            _interestRate < 21820606489,
            "SapphireCoreV1: interest rate cannot be more than 99% - 21820606489"
        );

        interestRate = _interestRate;
        emit InterestRateUpdated(interestRate);
    }

    function setProofProtocol(
        bytes32 _protocol
    )
        external
        onlyAdmin
    {
        _proofProtocol = _protocol;

        emit ProofProtocolSet(_proofProtocol.toString());
    }

    /* ========== Public Functions ========== */

    /**
     * @dev Deposits the given `_amount` of collateral to the `msg.sender`'s vault.
     *
     * @param _amount The amount of collateral to deposit
     * @param _scoreProof The credit score proof - optional
     */
    function deposit(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            SapphireTypes.Operation.Deposit,
            address(0)
        );

        executeActions(actions, _scoreProof);
    }

    function withdraw(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _scoreProof);
    }

    /**
     * @dev Borrow against an existing position
     *
     * @param _amount The amount of synthetic to borrow
     * @param _scoreProof The credit score proof - mandatory
     */
    function borrow(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            SapphireTypes.Operation.Borrow,
            address(0)
        );

        executeActions(actions, _scoreProof);
    }

    function repay(
        uint256 _amount,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            _amount,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        executeActions(actions, _scoreProof);
    }

    /**
     * @dev Repays the entire debt and withdraws the all the collateral
     *
     * @param _scoreProof The credit score proof - optional
     */
    function exit(
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](2);
        SapphireTypes.Vault memory vault = vaults[msg.sender];

        uint256 repayAmount = _denormalizeBorrowAmount(vault.borrowedAmount, true);

        // Repay outstanding debt
        actions[0] = SapphireTypes.Action(
            repayAmount,
            SapphireTypes.Operation.Repay,
            address(0)
        );

        // Withdraw all collateral
        actions[1] = SapphireTypes.Action(
            vault.collateralAmount,
            SapphireTypes.Operation.Withdraw,
            address(0)
        );

        executeActions(actions, _scoreProof);
    }

    /**
     * @dev Liquidate a user's vault. When this process occurs you're essentially
     *      purchasing the user's debt at a discount in exchange for the collateral
     *      they have deposited inside their vault.
     *
     * @param _owner the owner of the vault to liquidate
     * @param _scoreProof The credit score proof (optional)
     */
    function liquidate(
        address _owner,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        SapphireTypes.Action[] memory actions = new SapphireTypes.Action[](1);
        actions[0] = SapphireTypes.Action(
            0,
            SapphireTypes.Operation.Liquidate,
            _owner
        );

        executeActions(actions, _scoreProof);
    }

    /**
     * @dev All other user-called functions use this function to execute the
     *      passed actions. This function first updates the indexes before
     *      actually executing the actions.
     *
     * @param _actions      An array of actions to execute
     * @param _scoreProof   The credit score proof of the user that calls this
     *                      function
     */
    function executeActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        public
    {
        require(
            !paused,
            "SapphireCoreV1: the contract is paused"
        );

        require(
            _actions.length > 0,
            "SapphireCoreV1: there must be at least one action"
        );

        require (
            _scoreProof.protocol == _proofProtocol,
            "SapphireCoreV1: incorrect proof protocol"
        );

        // Update the index to calculate how much interest has accrued
        updateIndex();

        // Get the c-ratio and current price if necessary. The current price only be >0 if
        // it's required by an action
        (
            uint256 assessedCRatio,
            uint256 currentPrice
        ) = _getVariablesForActions(_actions, _scoreProof);

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            if (action.operation == SapphireTypes.Operation.Deposit) {
                _deposit(action.amount);

            } else if (action.operation == SapphireTypes.Operation.Withdraw){
                _withdraw(action.amount, assessedCRatio, currentPrice);

            } else if (action.operation == SapphireTypes.Operation.Borrow) {
                _borrow(action.amount, assessedCRatio, currentPrice);

            }  else if (action.operation == SapphireTypes.Operation.Repay) {
                _repay(msg.sender, msg.sender, action.amount);

            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
                _liquidate(action.userToLiquidate, currentPrice, assessedCRatio);
            }
        }

        emit ActionsOperated(
            _actions,
            _scoreProof,
            msg.sender
        );
    }

    function updateIndex()
        public
        returns (uint256)
    {
        if (indexLastUpdate == currentTimestamp()) {
            return borrowIndex;
        }

        borrowIndex = currentBorrowIndex();
        indexLastUpdate = currentTimestamp();

        emit IndexUpdated(borrowIndex, indexLastUpdate);

        return borrowIndex;
    }

    /* ========== Public Getters ========== */

    function accumulatedInterest()
        public
        view
        returns (uint256)
    {
        return interestRate.mul(currentTimestamp().sub(indexLastUpdate));
    }

    function currentBorrowIndex()
        public
        view
        returns (uint256)
    {
        return borrowIndex.mul(accumulatedInterest()).div(BASE).add(borrowIndex);
    }

    function getProofProtocol()
        external
        view
        returns (string memory)
    {
        return _proofProtocol.toString();
    }

    /**
     * @dev Check if the vault is collateralized or not
     *
     * @param _owner The owner of the vault
     * @param _currentPrice The current price of the collateral
     * @param _assessedCRatio The assessed collateral ratio of the owner
     */
    function isCollateralized(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio
    )
        public
        view
        returns (bool)
    {
        SapphireTypes.Vault memory vault = vaults[_owner];

        if (vault.borrowedAmount == 0) {
            return true;
        }

        uint256 currentCRatio = calculateCollateralRatio(
            vault.borrowedAmount,
            vault.collateralAmount,
            _currentPrice
        );

        return currentCRatio >= _assessedCRatio;
    }

    /* ========== Developer Functions ========== */

    /**
     * @dev Returns current block's timestamp
     *
     * @notice This function is introduced in order to properly test time delays in this contract
     */
    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Calculate how much collateralRatio you would have
     *      with a certain borrow and collateral amount
     *
     * @param _borrowedAmount   The borrowed amount expressed as a uint256 (NOT principal)
     * @param _collateralAmount The amount of collateral, in its original decimals
     * @param _collateralPrice  What price do you want to calculate the inverse at
     * @return                  The calculated c-ratio
     */
    function calculateCollateralRatio(
        uint256 _borrowedAmount,
        uint256 _collateralAmount,
        uint256 _collateralPrice
    )
        public
        view
        returns (uint256)
    {
        return _collateralAmount
            .mul(precisionScalar)
            .mul(_collateralPrice)
            .div(_borrowedAmount);
    }

    /* ========== Private Functions ========== */

    /**
     * @dev Normalize the given borrow amount by dividing it with the borrow index.
     *      It is used when manipulating with other borrow values
     *      in order to take in account current borrowIndex.
     */
    function _normalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        uint256 currentBIndex = currentBorrowIndex();

        if (_roundUp) {
            return Math.roundUpDiv(_amount, currentBIndex);
        }

        return _amount
            .mul(BASE)
            .div(currentBIndex);
    }

    /**
     * @dev Multiply the given amount by the borrow index. Used to convert
     *      borrow amounts back to their real value.
     */
    function _denormalizeBorrowAmount(
        uint256 _amount,
        bool _roundUp
    )
        private
        view
        returns (uint256)
    {
        if (_amount == 0) return _amount;

        if (_roundUp) {
            return Math.roundUpMul(_amount, currentBorrowIndex());
        }

        return _amount
            .mul(currentBorrowIndex())
            .div(BASE);
    }

    /**
     * @dev Deposits the collateral amount in the user's vault
     */
    function _deposit(
        uint256 _amount
    )
        private
    {
        // Record deposit
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        if (_amount == 0) {
            return;
        }

        vault.collateralAmount = vault.collateralAmount.add(_amount);

        totalCollateral = totalCollateral.add(_amount);

        // Execute transfer
        IERC20 collateralAsset = IERC20(collateralAsset);
        SafeERC20.safeTransferFrom(
            collateralAsset,
            msg.sender,
            address(this),
            _amount
        );
    }

    /**
     * @dev Withdraw the collateral amount in the user's vault, then ensures
     *      the withdraw amount is not greater than the deposited collateral.
     *      Afterwards ensure that collateral limit is not smaller than returned
     *      from assessor one.
     */
    function _withdraw(
        uint256 _amount,
        uint256 _assessedCRatio,
        uint256 _collateralPrice
    )
        private
    {
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        require(
            vault.collateralAmount >= _amount,
            "SapphireCoreV1: cannot withdraw more collateral than the vault balance"
        );

        vault.collateralAmount = vault.collateralAmount.sub(_amount);

        // if we don't have debt we can withdraw as much as we want.
        if (vault.borrowedAmount > 0) {
            uint256 collateralRatio = calculateCollateralRatio(
                _denormalizeBorrowAmount(vault.borrowedAmount, true),
                vault.collateralAmount,
                _collateralPrice
            );

            require(
                collateralRatio >= _assessedCRatio,
                "SapphireCoreV1: the vault will become undercollateralized"
            );
        }

        // Change total collateral amount
        totalCollateral = totalCollateral.sub(_amount);

        // Execute transfer
        IERC20 collateralAsset = IERC20(collateralAsset);
        SafeERC20.safeTransfer(collateralAsset, msg.sender, _amount);
    }

    /**
     * @dev Borrows synthetic against the user's vault. It ensures the vault
     *      still maintains the required collateral ratio
     *
     * @param _amount           The amount of synthetic to borrow, in 18 decimals
     * @param _assessedCRatio   The assessed c-ratio for user's credit score
     * @param _collateralPrice  The current collateral price
     */
    function _borrow(
        uint256 _amount,
        uint256 _assessedCRatio,
        uint256 _collateralPrice
    )
        private
    {
        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[msg.sender];

        uint256 denormalizedBorrowAmount = _denormalizeBorrowAmount(vault.borrowedAmount, true);

        // Ensure the vault is collateralized if the borrow action succeeds
        uint256 collateralRatio = calculateCollateralRatio(
            denormalizedBorrowAmount
                .add(_amount),
            vault.collateralAmount,
            _collateralPrice
        );

        require(
            collateralRatio >= _assessedCRatio,
            "SapphireCoreV1: the vault will become undercollateralized"
        );

        // Calculate actual vault borrow amount
        uint256 actualVaultBorrowAmount = denormalizedBorrowAmount;

        // Calculate new actual vault borrow amount
        uint256 _newActualVaultBorrowAmount = actualVaultBorrowAmount.add(_amount);

        // Calculate new normalized vault borrow amount
        uint256 _newNormalizedVaultBorrowAmount = _normalizeBorrowAmount(_newActualVaultBorrowAmount, true);

        // Record borrow amount (update vault and total amount)
        totalBorrowed = totalBorrowed.sub(vault.borrowedAmount).add(_newNormalizedVaultBorrowAmount);
        vault.borrowedAmount = _newNormalizedVaultBorrowAmount;

        // Do not borrow more than the maximum vault borrow amount
        require(
            _newActualVaultBorrowAmount <= vaultBorrowMaximum,
            "SapphireCoreV1: borrowed amount cannot be greater than vault limit"
        );

        // Do not borrow if amount is smaller than limit
        require(
            _newActualVaultBorrowAmount >= vaultBorrowMinimum,
            "SapphireCoreV1: borrowed amount cannot be less than limit"
        );

        require(
            _denormalizeBorrowAmount(totalBorrowed, true) <= totalBorrowLimit,
            "SapphireCoreV1: borrowed amount cannot be greater than limit"
        );

        // Mint tokens
        ISyntheticTokenV2(syntheticAsset).mint(
            msg.sender,
            _amount
        );
    }

    /**
     * @dev Repays the given `_amount` of the synthetic back
     *
     * @param _owner The owner of the vault
     * @param _repayer The person who repays the debt
     * @param _amount The amount to repay
     */
    function _repay(
        address _owner,
        address _repayer,
        uint256 _amount
    )
        private
    {
        // Get the user's vault
        SapphireTypes.Vault storage vault = vaults[_owner];

        // Calculate actual vault borrow amount
        uint256 actualVaultBorrowAmount = _denormalizeBorrowAmount(vault.borrowedAmount, true);

        require(
            _amount <= actualVaultBorrowAmount,
            "SapphireCoreV1: there is not enough debt to repay"
        );

        // Calculate new vault's borrowed amount
        uint256 _newBorrowAmount = _normalizeBorrowAmount(actualVaultBorrowAmount.sub(_amount), true);

        // Update total borrow amount
        totalBorrowed = totalBorrowed.sub(vault.borrowedAmount).add(_newBorrowAmount);

        // Update vault
        vault.borrowedAmount = _newBorrowAmount;

        // Transfer tokens to the core
        ISyntheticTokenV2(syntheticAsset).transferFrom(
            _repayer,
            address(this),
            _amount
        );
        // Destroy `_amount` of tokens tokens that the core owns
        ISyntheticTokenV2(syntheticAsset).destroy(
            _amount
        );
    }

    function _liquidate(
        address _owner,
        uint256 _currentPrice,
        uint256 _assessedCRatio
    )
        private
    {
        // CHECKS:
        // 1. Ensure that the position is valid (check if there is a non-0x0 owner)
        // 2. Ensure that the position is indeed undercollateralized

        // EFFECTS:
        // 1. Calculate the liquidation price based on the liquidation penalty
        // 2. Calculate the amount of collateral to be sold based on the entire debt
        //    in the vault
        // 3. If the discounted collateral is more than the amount in the vault, limit
        //    the sale to that amount
        // 4. Decrease the owner's debt
        // 5. Decrease the owner's collateral

        // INTEGRATIONS
        // 1. Transfer the debt to pay from the liquidator to the core
        // 2. Destroy the debt to be paid
        // 3. Transfer the user portion of the collateral sold to the msg.sender
        // 4. Transfer Arc's portion of the profit to the fee collector

        // --- CHECKS ---

        require(
            _owner != address(0),
            "SapphireCoreV1: position owner cannot be address 0"
        );

        SapphireTypes.Vault storage vault = vaults[_owner];

        // Ensure that the vault is not collateralized
        require(
            !isCollateralized(
                _owner,
                _currentPrice,
                _assessedCRatio
            ),
            "SapphireCoreV1: vault is collateralized"
        );

        // --- EFFECTS ---

        // Get the liquidation price of the asset (discount for liquidator)
        uint256 liquidationPriceRatio = BASE.sub(liquidationUserRatio);
        uint256 liquidationPrice = Math.roundUpMul(_currentPrice, liquidationPriceRatio);

        // Calculate the amount of collateral to be sold based on the entire debt
        // in the vault
        uint256 debtToRepay = _denormalizeBorrowAmount(vault.borrowedAmount, true);

        // Do a rounded up operation of
        // debtToRepay / LiquidationFee / precisionScalar
        uint256 collateralToSell = Math.roundUpDiv(debtToRepay, liquidationPrice)
            .add(precisionScalar.sub(1))
            .div(precisionScalar);

        // If the discounted collateral is more than the amount in the vault, limit
        // the sale to that amount
        if (collateralToSell > vault.collateralAmount) {
            collateralToSell = vault.collateralAmount;
            // Calculate the new debt to repay
            debtToRepay = collateralToSell
                .mul(precisionScalar)
                .mul(liquidationPrice)
                .div(BASE);
        }

        // Calculate the profit made in USD
        uint256 valueCollateralSold = collateralToSell
            .mul(precisionScalar)
            .mul(_currentPrice)
            .div(BASE);

        // Total profit in dollar amount
        uint256 profit = valueCollateralSold.sub(debtToRepay);

        // Calculate the ARC share
        uint256 arcShare = profit
            .mul(liquidationArcRatio)
            .div(liquidationPrice)
            .div(precisionScalar);

        // Calculate liquidator's share
        uint256 liquidatorCollateralShare = collateralToSell.sub(arcShare);

        // Update owner's vault
        vault.collateralAmount = vault.collateralAmount
            .sub(collateralToSell);

        // --- INTEGRATIONS ---

        // Repay the debt
        _repay(
            _owner,
            msg.sender,
            debtToRepay
        );

        // Transfer user collateral
        IERC20 collateralAsset = IERC20(collateralAsset);
        SafeERC20.safeTransfer(
            collateralAsset,
            msg.sender,
            liquidatorCollateralShare
        );

        // Transfer Arc's share of collateral
        SafeERC20.safeTransfer(
            collateralAsset,
            feeCollector,
            arcShare
        );
    }

    /**
     * @dev Gets the required variables for the actions passed, if needed. The credit score
     *      will be assessed if there is at least one action. The oracle price will only be
     *      fetched if there is at least one borrow or liquidate actions.
     *
     * @param _actions      the actions that are about to be ran
     * @param _scoreProof   the credit score proof
     * @return              the assessed c-ratio and the current collateral price
     */
    function _getVariablesForActions(
        SapphireTypes.Action[] memory _actions,
        SapphireTypes.ScoreProof memory _scoreProof
    )
        private
        returns (uint256, uint256)
    {
        uint256 assessedCRatio;
        uint256 collateralPrice;
        uint256 collateralPriceTimestamp;

        bool mandatoryProof = false;
        bool needsCollateralPrice = false;

        // Check if the score proof has an address. If it's address zero,
        // replace it with msg.sender. This is to prevent users from borrowing
        // after having already registered a score on chain

        if (_scoreProof.account == address(0)) {
            _scoreProof.account = msg.sender;
        }

        for (uint256 i = 0; i < _actions.length; i++) {
            SapphireTypes.Action memory action = _actions[i];

            if (action.operation == SapphireTypes.Operation.Borrow ||
                action.operation == SapphireTypes.Operation.Liquidate
            ) {
                if (action.operation == SapphireTypes.Operation.Liquidate) {
                    mandatoryProof = true;
                }

                needsCollateralPrice = true;

            } else if (action.operation == SapphireTypes.Operation.Withdraw) {
                needsCollateralPrice = true;
            }

            /**
            * Ensure the credit score proof refers to the correct account given
            * the action.
            */
            if (action.operation == SapphireTypes.Operation.Borrow ||
                action.operation == SapphireTypes.Operation.Withdraw
            ) {
                require(
                    _scoreProof.account == msg.sender,
                    "SapphireCoreV1: proof.account must match msg.sender"
                );
            } else if (action.operation == SapphireTypes.Operation.Liquidate) {
                require(
                    _scoreProof.account == action.userToLiquidate,
                    "SapphireCoreV1: proof.account does not match the user to liquidate"
                );
            }
        }

        if (needsCollateralPrice) {
            require(
                address(oracle) != address(0),
                "SapphireCoreV1: the oracle is not set"
            );

            // Collateral price denominated in 18 decimals
            (collateralPrice, collateralPriceTimestamp) = oracle.fetchCurrentPrice();

            require(
                _isOracleNotOutdated(collateralPriceTimestamp),
                "SapphireCoreV1: the oracle has stale prices"
            );

            require(
                collateralPrice > 0,
                "SapphireCoreV1: the oracle returned a price of 0"
            );
        }

        if (address(assessor) == address(0) || _actions.length == 0) {
            assessedCRatio = highCollateralRatio;
        } else {
            assessedCRatio = assessor.assess(
                lowCollateralRatio,
                highCollateralRatio,
                _scoreProof,
                mandatoryProof
            );
        }

        return (assessedCRatio, collateralPrice);
    }

    function _setFees(
        uint256 _liquidationUserRatio,
        uint256 _liquidationArcRatio
    )
        private
    {
        require(
            _liquidationUserRatio <= BASE &&
            _liquidationArcRatio <= BASE,
            "SapphireCoreV1: fees cannot be more than 100%"
        );

        liquidationUserRatio = _liquidationUserRatio;
        liquidationArcRatio = _liquidationArcRatio;
        emit LiquidationFeesUpdated(liquidationUserRatio, liquidationArcRatio);
    }

    /**
     * @dev Returns true if oracle is not outdated
     */
    function _isOracleNotOutdated(
        uint256 _oracleTimestamp
    )
        internal
        view
        returns (bool)
    {
        return _oracleTimestamp >= currentTimestamp().sub(60 * 60 * 12);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import {SafeMath} from "../lib/SafeMath.sol";

import {IERC20Metadata} from "./IERC20Metadata.sol";
import {Permittable} from "./Permittable.sol";

/**
 * @title ERC20 Token
 *
 * Basic ERC20 Implementation
 */
contract BaseERC20 is IERC20Metadata, Permittable {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint8   internal _decimals;
    uint256 private _totalSupply;

    string  internal _name;
    string  internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (
        string memory name,
        string memory symbol,
        uint8         decimals
    )
        public
        Permittable(name, "1")
    {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name()
        public
        view
        returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()
        public
        view
        returns (string memory)
    {
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
    function decimals()
        public
        view
        returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    )
        public
        view
        returns (uint256)
    {
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
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
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
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );

        return true;
    }

    /**
    * @dev Approve by signature.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
    {
        _permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
        _approve(owner, spender, value);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
    {
        require(
            sender != address(0),
            "ERC20: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _balances[sender] = _balances[sender].sub(amount);

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
    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
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
    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
        external
        view
        returns (uint256);

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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
contract IERC20Metadata is IERC20 {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.5.16;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solium-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

pragma solidity ^0.5.16;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";

/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a
            .mul(BASE)
            .add(b.sub(1))
            .div(b);
    }

    /**
     * @dev Performs a * b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a
            .mul(b)
            .add(BASE.sub(1))
            .div(BASE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import { Storage } from "./Storage.sol";

/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

library Bytes32 {

    function toString(
        bytes32 _bytes
    )
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes[i] != 0; i++) {
            bytesArray[i] = _bytes[i];
        }
        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface ISapphireOracle {

    /**
     * @notice Fetches the current price of the asset
     *
     * @return The price in 18 decimals and the timestamp when
     *         the price was updated and the decimals of the asset
     */
    function fetchCurrentPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {IERC20} from "./IERC20.sol";

import {Amount} from "../lib/Amount.sol";

interface ISyntheticTokenV2 {

    function mint(
        address to,
        uint256 value
    )
        external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    function destroy(
        uint256 _value
    )
        external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 borrowedAmount;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        Operation operation;
        address userToLiquidate;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

import {SapphireTypes} from "./SapphireTypes.sol";

contract SapphireCoreStorageV1 {

    /* ========== Constants ========== */

    uint256 constant BASE = 10**18;

    /* ========== Public Variables ========== */

    /**
     * @notice Determines whether the contract is paused or not
     */
    bool public paused;

    /**
     * @dev The details about a vault, identified by the address of the owner
     */
    mapping (address => SapphireTypes.Vault) public vaults;

    /**
    * @dev The high/default collateral ratio for an untrusted borrower.
    */
    uint256 public highCollateralRatio;

    /**
    * @dev The lowest collateral ratio for an untrusted borrower.
    */
    uint256 public lowCollateralRatio;

    /**
     * @dev How much should the liquidation penalty be, expressed as a percentage
     *      with 18 decimals
     */
    uint256 public liquidationUserRatio;

    /**
     * @dev How much of the profit acquired from a liquidation should ARC receive
     */
    uint256 public liquidationArcRatio;

    /**
    * @dev The assessor that will determine the collateral-ratio.
    */
    ISapphireAssessor public assessor;

    /**
    * @dev The address which collects fees when liquidations occur.
    */
    address public feeCollector;

    /**
     * @dev The instance of the oracle that reports prices for the collateral
     */
    ISapphireOracle public oracle;

    /**
     * @dev If a collateral asset is used that has less than 18 decimal places
     *      a precision scalar is required to calculate the correct values.
     */
    uint256 public precisionScalar;

    /**
     * @dev The actual address of the collateral used for this core system.
     */
    address public collateralAsset;

    /**
     * @dev The address of the synthetic token where this core is approved to mint from
     */
    address public syntheticAsset;

    /**
    * @dev The actual amount of collateral provided to the protocol.
    *      This amount will be multiplied by the precision scalar if the token
    *      has less than 18 decimals precision.
    */
    uint256 public totalCollateral;

    /**
     * @dev An account of the total amount being borrowed by all depositors. This includes
     *      the amount of interest accrued.
     */
    uint256 public totalBorrowed;

    /**
     * @dev The accumulated borrow index. Each time a borrows, their borrow amount is expressed
     *      in relation to the borrow index.
     */
    uint256 public borrowIndex;

    /**
     * @dev The last time the updateIndex() function was called. This helps to determine how much
     *      interest has accrued in the contract since a user interacted with the protocol.
     */
    uint256 public indexLastUpdate;

    /**
     * @dev The interest rate charged to borrowers. Expressed as the interest rate per second and 18 d.p
     */
    uint256 public interestRate;

    /**
     * @notice Which address can set interest rates for this contract
     */
    address public interestSetter;

    /**
     * @dev The address that can call `setPause()`
     */
    address public pauseOperator;

    /**
     * @dev The maximum amount which can be borrowed within a contract. This includes
     *      the amount of interest accrued.
     */
    uint256 public totalBorrowLimit;

    /**
     * @dev The minimum amount which has to be borrowed by a vault. This includes
     *      the amount of interest accrued.
     */
    uint256 public vaultBorrowMinimum;

    /**
     * @dev The maximum amount which has to be borrowed by a vault. This includes
     *      the amount of interest accrued.
     */
    uint256 public vaultBorrowMaximum;

    /* ========== Internal Variables ========== */

    /**
     * @dev The protocol value to be used in the score proofs
     */
    bytes32 internal _proofProtocol;
}

// solium-disable-next-line no-empty-blocks
contract SapphireCoreStorage is SapphireCoreStorageV1 {}

// SPDX-License-Identifier: MIT
// prettier-ignore

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {Ownable} from "../lib/Ownable.sol";
import {Address} from "../lib/Address.sol";
import {PassportScoreVerifiable} from "../lib/PassportScoreVerifiable.sol";
import {SapphireTypes} from "./SapphireTypes.sol";
import {ISapphireMapper} from "./ISapphireMapper.sol";
import {ISapphirePassportScores} from "./ISapphirePassportScores.sol";
import {ISapphireAssessor} from "./ISapphireAssessor.sol";

contract SapphireAssessor is Ownable, ISapphireAssessor, PassportScoreVerifiable {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Variables ========== */

    ISapphireMapper public mapper;

    uint16 public maxScore;

    /* ========== Events ========== */

    event MapperSet(address _newMapper);

    event PassportScoreContractSet(address _newCreditScoreContract);

    event Assessed(
        address _account,
        uint256 _assessedValue
    );

    event MaxScoreSet(uint16 _maxScore);

    /* ========== Constructor ========== */

    constructor(
        address _mapper,
        address _passportScores,
        uint16 _maxScore
    )
        public
    {
        require(
            _mapper.isContract() &&
            _passportScores.isContract(),
            "SapphireAssessor: The mapper and the passport scores must be valid contracts"
        );

        mapper = ISapphireMapper(_mapper);
        passportScoresContract = ISapphirePassportScores(_passportScores);
        setMaxScore(_maxScore);
    }

    /* ========== Public Functions ========== */

    /**
     * @notice  Takes a lower and upper bound, and based on the user's credit score
     *          and given its proof, returns the appropriate value between these bounds.
     *
     * @param _lowerBound       The lower bound
     * @param _upperBound       The upper bound
     * @param _scoreProof       The score proof
     * @param _isScoreRequired  The flag, which require the proof of score if the account already
                                has a score
     * @return A value between the lower and upper bounds depending on the credit score
     */
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired
    )
        public
        checkScoreProof(_scoreProof, _isScoreRequired, false)
        returns (uint256)
    {
        require(
            _upperBound > 0,
            "SapphireAssessor: The upper bound cannot be zero"
        );

        require(
            _lowerBound < _upperBound,
            "SapphireAssessor: The lower bound must be smaller than the upper bound"
        );

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        // If the proof is passed, use the score from the score proof since at this point
        // the proof should be verified if the score is > 0
        uint256 result = mapper.map(
            isProofPassed ? _scoreProof.score : 0,
            maxScore,
            _lowerBound,
            _upperBound
        );

        require(
            result >= _lowerBound &&
            result <= _upperBound,
            "SapphireAssessor: The mapper returned a value out of bounds"
        );

        emit Assessed(_scoreProof.account, result);

        return result;
    }

    function setMapper(
        address _mapper
    )
        external
        onlyOwner
    {
        require(
            _mapper.isContract(),
            "SapphireAssessor: _mapper is not a contract"
        );

        require(
            _mapper != address(mapper),
            "SapphireAssessor: The same mapper is already set"
        );

        mapper = ISapphireMapper(_mapper);

        emit MapperSet(_mapper);
    }

    function setPassportScoreContract(
        address _creditScore
    )
        external
        onlyOwner
    {
        require(
            _creditScore.isContract(),
            "SapphireAssessor: _creditScore is not a contract"
        );

        require(
            _creditScore != address(passportScoresContract),
            "SapphireAssessor: The same credit score contract is already set"
        );

        passportScoresContract = ISapphirePassportScores(_creditScore);

        emit PassportScoreContractSet(_creditScore);
    }

    function setMaxScore(
        uint16 _maxScore
    )
        public
        onlyOwner
    {
        require(
            _maxScore > 0,
            "SapphireAssessor: max score cannot be zero"
        );

        maxScore = _maxScore;

        emit MaxScoreSet(_maxScore);
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        revert("SapphireAssessor: cannot renounce ownership");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphireAssessor {
    function assess(
        uint256 _lowerBound,
        uint256 _upperBound,
        SapphireTypes.ScoreProof calldata _scoreProof,
        bool _isScoreRequired
    )
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

contract Permittable {

    /* ============ Variables ============ */

    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public nonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* solium-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    constructor(
        string memory name,
        string memory version
    )
        public
    {
        DOMAIN_SEPARATOR = _initDomainSeparator(name, version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _initDomainSeparator(
        string memory name,
        string memory version
    )
        internal
        view
        returns (bytes32)
    {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *      Caution: If an owner signs a permit with no deadline, the corresponding spender
    *      can call permit at any time in the future to mess with the nonce, invalidating
    *      signatures to other spenders, possibly making their transactions fail.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(
            deadline == 0 || deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    nonces[owner]++,
                    deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "Permittable: Signature invalid"
        );

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "../lib/Math.sol";

library Amount {

    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // A Principal Amount is an amount that's been adjusted by an index

    struct Principal {
        bool sign; // true if positive
        uint256 value;
    }

    function zero()
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: false,
            value: 0
        });
    }

    function sub(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        return add(a, negative(b));
    }

    function add(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (Principal memory)
    {
        Principal memory result;

        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Principal memory a,
        Principal memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Principal memory a
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: !a.sign,
            value: a.value
        });
    }

    function calculateAdjusted(
        Principal memory a,
        uint256 index
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(a.value, index, BASE);
    }

    function calculatePrincipal(
        uint256 value,
        uint256 index,
        bool sign
    )
        internal
        pure
        returns (Principal memory)
    {
        return Principal({
            sign: sign,
            value: Math.getPartial(value, BASE, index)
        });
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Address} from "./Address.sol";

import {ISapphirePassportScores} from "../sapphire/ISapphirePassportScores.sol";
import {SapphireTypes} from "../sapphire/SapphireTypes.sol";

/**
 * @dev Provides the ability of verifying users' credit scores
 */
contract PassportScoreVerifiable {

    using Address for address;

    ISapphirePassportScores public passportScoresContract;

    /**
     * @dev Verifies that the proof is passed if the score is required, and
     *      validates it.
     *      Additionally, it checks the proof validity if `scoreProof` has a score > 0
     */
    modifier checkScoreProof(
        SapphireTypes.ScoreProof memory _scoreProof,
        bool _isScoreRequired,
        bool _enforceSameCaller
    ) {
        if (_scoreProof.account != address(0) && _enforceSameCaller) {
            require (
                msg.sender == _scoreProof.account,
                "PassportScoreVerifiable: proof does not belong to the caller"
            );
        }

        bool isProofPassed = _scoreProof.merkleProof.length > 0;

        if (_isScoreRequired || isProofPassed || _scoreProof.score > 0) {
            passportScoresContract.verify(_scoreProof);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface ISapphireMapper {

    /**
     * @notice Maps the `_score` to a value situated between
     * the given lower and upper bounds
     *
     * @param _score The user's credit score to use for the mapping
     * @param _scoreMax The maximum value the score can be
     * @param _lowerBound The lower bound
     * @param _upperBound The upper bound
     */
    function map(
        uint256 _score,
        uint256 _scoreMax,
        uint256 _lowerBound,
        uint256 _upperBound
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import {SapphireTypes} from "./SapphireTypes.sol";

interface ISapphirePassportScores {
    function updateMerkleRoot(bytes32 newRoot) external;

    function setMerkleRootUpdater(address merkleRootUpdater) external;

    /**
     * Reverts if proof is invalid
     */
    function verify(SapphireTypes.ScoreProof calldata proof) external view returns(bool);

    function setMerkleRootDelay(uint256 delay) external;

    function setPause(bool status) external;
}