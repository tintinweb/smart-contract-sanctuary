// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Governed} from "./Governance.sol";
import {Initializable} from "./libraries/Upgradability.sol";

interface ICore {
    /// @dev Thrown when trying to set platform fees that don't sum up to one.
    /// @param stabilizationFee The stabilization fee that was tried to set.
    /// @param exchangeFee The stabilization fee that was tried to set.
    /// @param developmentFee The stabilization fee that was tried to set.
    error BaksDAOPlatformFeesDontSumUpToOne(uint256 stabilizationFee, uint256 exchangeFee, uint256 developmentFee);

    event PriceOracleUpdated(address priceOracle, address newPriceOracle);

    event BaksUpdated(address baks, address newBaks);
    event VoiceUpdated(address voice, address newVoice);

    event BankUpdated(address bank, address newBank);
    event DepositaryUpdated(address depositary, address newDepositary);
    event ExchangeFundUpdated(address exchangeFund, address newExchangeFund);
    event DevelopmentFundUpdated(address developmentFund, address newDevelopmentFund);

    event OperatorUpdated(address operator, address newOperator);
    event LiquidatorUpdated(address liquidator, address newLiquidator);

    event InterestUpdated(uint256 interest, uint256 newInterest);
    event MinimumPrincipalAmountUpdated(uint256 minimumPrincipalAmount, uint256 newMinimumPrincipalAmount);
    event StabilityFeeUpdated(uint256 stabilityFee, uint256 newStabilityFee);
    event RebalancingThresholdUpdated(uint256 rebalancingThreshold, uint256 newRebalancingThreshold);
    event PlatformFeesUpdated(
        uint256 stabilizationFee,
        uint256 newStabilizationFee,
        uint256 exchangeFee,
        uint256 newExchangeFee,
        uint256 developmentFee,
        uint256 newDevelopmentFee
    );
    event MarginCallLoanToValueRatioUpdated(uint256 marginCallLoanToValueRatio, uint256 newMarginCallLoanToValueRatio);
    event LiquidationLoanToValueRatioUpdated(
        uint256 liqudationLoanToValueRatio,
        uint256 newLiquidationLoanToValueRatio
    );

    event MinimumMagisterDepositAmountUpdated(
        uint256 minimumMagisterDepositAmount,
        uint256 newMinimumMagisterDepositAmount
    );
    event WorkFeeUpdated(uint256 workFee, uint256 newWorkFee);
    event EarlyWithdrawalPeriodUpdated(uint256 earlyWithdrawalPeriod, uint256 newEarlyWithdrawalPeriod);
    event EarlyWithdrawalFeeUpdated(uint256 earlyWithdrawalFee, uint256 newEarlyWithdrawalFee);

    event ServicingThresholdUpdated(uint256 servicingThreshold, uint256 newServicingThreshold);
    event MinimumLiquidityUpdated(uint256 minimumLiquidity, uint256 newMinimumLiquidity);

    function wrappedNativeCurrency() external view returns (address);

    function uniswapV2Router() external view returns (address);

    function priceOracle() external view returns (address);

    function baks() external view returns (address);

    function voice() external view returns (address);

    function bank() external view returns (address);

    function depositary() external view returns (address);

    function exchangeFund() external view returns (address);

    function developmentFund() external view returns (address);

    function operator() external view returns (address);

    function liquidator() external view returns (address);

    function interest() external view returns (uint256);

    function minimumPrincipalAmount() external view returns (uint256);

    function stabilityFee() external view returns (uint256);

    function stabilizationFee() external view returns (uint256);

    function exchangeFee() external view returns (uint256);

    function developmentFee() external view returns (uint256);

    function marginCallLoanToValueRatio() external view returns (uint256);

    function liquidationLoanToValueRatio() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function minimumMagisterDepositAmount() external view returns (uint256);

    function workFee() external view returns (uint256);

    function earlyWithdrawalPeriod() external view returns (uint256);

    function earlyWithdrawalFee() external view returns (uint256);

    function servicingThreshold() external view returns (uint256);

    function minimumLiquidity() external view returns (uint256);
}

contract Core is Initializable, Governed, ICore {
    uint256 internal constant ONE = 100e16;

    address public override wrappedNativeCurrency;
    address public override uniswapV2Router;

    address public override priceOracle;

    address public override baks;
    address public override voice;

    address public override bank;
    address public override depositary;
    address public override exchangeFund;
    address public override developmentFund;

    // Roles
    address public override operator;
    address public override liquidator;

    // Bank parameters
    uint256 public override interest;
    uint256 public override minimumPrincipalAmount;
    uint256 public override stabilityFee;
    uint256 public override stabilizationFee;
    uint256 public override exchangeFee;
    uint256 public override developmentFee;
    uint256 public override marginCallLoanToValueRatio;
    uint256 public override liquidationLoanToValueRatio;
    uint256 public override rebalancingThreshold;

    // Depositary parameters
    uint256 public override minimumMagisterDepositAmount;
    uint256 public override workFee;
    uint256 public override earlyWithdrawalPeriod;
    uint256 public override earlyWithdrawalFee;

    // Exchange fund parameters
    uint256 public override servicingThreshold;
    uint256 public override minimumLiquidity;

    function initialize(
        address _wrappedNativeCurrency,
        address _uniswapV2Router,
        address _operator,
        address _liquidator
    ) external initializer {
        setGovernor(msg.sender);

        wrappedNativeCurrency = _wrappedNativeCurrency;
        uniswapV2Router = _uniswapV2Router;

        operator = _operator;
        liquidator = _liquidator;

        interest = 11e16; // 11 %
        minimumPrincipalAmount = 50e18; // 50 BAKS
        stabilityFee = 15e15; // 1,5 %
        stabilizationFee = 85e16; // 85 %
        exchangeFee = 15e16; // 15 %
        developmentFee = 0;
        marginCallLoanToValueRatio = 75e16; // 75 %
        liquidationLoanToValueRatio = 83e16; // 83 %
        rebalancingThreshold = 1e16; // 1 %

        minimumMagisterDepositAmount = 50000e18; // 50000 BAKS
        workFee = 2e16; // 2 %
        earlyWithdrawalPeriod = 72 hours;
        earlyWithdrawalFee = 1e15; // 0,1 %

        servicingThreshold = 1e16; // 1%
        minimumLiquidity = 50000e18; // 50000 BAKS
    }

    function setPriceOracle(address newPriceOracle) external onlyGovernor {
        emit PriceOracleUpdated(priceOracle, newPriceOracle);
        priceOracle = newPriceOracle;
    }

    function setBaks(address newBaks) external onlyGovernor {
        emit BaksUpdated(baks, newBaks);
        baks = newBaks;
    }

    function setVoice(address newVoice) external onlyGovernor {
        emit VoiceUpdated(voice, newVoice);
        voice = newVoice;
    }

    function setBank(address newBank) external onlyGovernor {
        emit BankUpdated(bank, newBank);
        bank = newBank;
    }

    function setDepositary(address newDepositary) external onlyGovernor {
        emit DepositaryUpdated(depositary, newDepositary);
        depositary = newDepositary;
    }

    function setExchangeFund(address newExchangeFund) external onlyGovernor {
        emit ExchangeFundUpdated(exchangeFund, newExchangeFund);
        exchangeFund = newExchangeFund;
    }

    function setDevelopmentFund(address newDevelopmentFund) external onlyGovernor {
        emit DevelopmentFundUpdated(developmentFund, newDevelopmentFund);
        developmentFund = newDevelopmentFund;
    }

    function setOperator(address newOperator) external onlyGovernor {
        emit OperatorUpdated(operator, newOperator);
        operator = newOperator;
    }

    function setLiquidator(address newLiquidator) external onlyGovernor {
        emit LiquidatorUpdated(liquidator, newLiquidator);
        liquidator = newLiquidator;
    }

    function setInterest(uint256 newInterest) external onlyGovernor {
        emit InterestUpdated(interest, newInterest);
        interest = newInterest;
    }

    function setMinimumPrincipalAmount(uint256 newMinimumPrincipalAmount) external onlyGovernor {
        emit StabilityFeeUpdated(minimumPrincipalAmount, newMinimumPrincipalAmount);
        minimumPrincipalAmount = newMinimumPrincipalAmount;
    }

    function setStabilityFee(uint256 newStabilityFee) external onlyGovernor {
        emit StabilityFeeUpdated(stabilityFee, newStabilityFee);
        stabilityFee = newStabilityFee;
    }

    function setPlatformFees(
        uint256 newStabilizationFee,
        uint256 newExchangeFee,
        uint256 newDevelopmentFee
    ) external onlyGovernor {
        if (newStabilizationFee + newExchangeFee + newDevelopmentFee != ONE) {
            revert BaksDAOPlatformFeesDontSumUpToOne(newStabilizationFee, newExchangeFee, newDevelopmentFee);
        }
        emit PlatformFeesUpdated(
            stabilizationFee,
            newStabilizationFee,
            exchangeFee,
            newExchangeFee,
            developmentFee,
            newDevelopmentFee
        );
        stabilizationFee = newStabilizationFee;
        exchangeFee = newExchangeFee;
        developmentFee = newDevelopmentFee;
    }

    function setMarginCallLoanToValueRatio(uint256 newMarginCallLoanToValueRatio) external onlyGovernor {
        emit MarginCallLoanToValueRatioUpdated(marginCallLoanToValueRatio, newMarginCallLoanToValueRatio);
        marginCallLoanToValueRatio = newMarginCallLoanToValueRatio;
    }

    function setLiquidationLoanToValueRatio(uint256 newLiquidationLoanToValueRatio) external onlyGovernor {
        emit LiquidationLoanToValueRatioUpdated(liquidationLoanToValueRatio, newLiquidationLoanToValueRatio);
        liquidationLoanToValueRatio = newLiquidationLoanToValueRatio;
    }

    function setRebalancingThreshold(uint256 newRebalancingThreshold) external onlyGovernor {
        emit RebalancingThresholdUpdated(rebalancingThreshold, newRebalancingThreshold);
        rebalancingThreshold = newRebalancingThreshold;
    }

    function setMinimumMagisterDepositAmount(uint256 newMinimumMagisterDepositAmount) external onlyGovernor {
        emit MinimumMagisterDepositAmountUpdated(minimumMagisterDepositAmount, newMinimumMagisterDepositAmount);
        minimumMagisterDepositAmount = newMinimumMagisterDepositAmount;
    }

    function setWorkFee(uint256 newWorkFee) external onlyGovernor {
        emit WorkFeeUpdated(workFee, newWorkFee);
        workFee = newWorkFee;
    }

    function setEarlyWithdrawalPeriod(uint256 newEarlyWithdrawalPeriod) external onlyGovernor {
        emit EarlyWithdrawalPeriodUpdated(earlyWithdrawalPeriod, newEarlyWithdrawalPeriod);
        earlyWithdrawalPeriod = newEarlyWithdrawalPeriod;
    }

    function setEarlyWithdrawalFee(uint256 newEarlyWithdrawalFee) external onlyGovernor {
        emit EarlyWithdrawalFeeUpdated(earlyWithdrawalFee, newEarlyWithdrawalFee);
        earlyWithdrawalFee = newEarlyWithdrawalFee;
    }

    function setServicingThreshold(uint256 newServicingThreshold) external onlyGovernor {
        emit ServicingThresholdUpdated(servicingThreshold, newServicingThreshold);
        servicingThreshold = newServicingThreshold;
    }

    function setMinimumLiquidity(uint256 newMinimumLiquidity) external onlyGovernor {
        emit MinimumLiquidityUpdated(minimumLiquidity, newMinimumLiquidity);
        minimumLiquidity = newMinimumLiquidity;
    }
}

abstract contract CoreInside {
    ICore public core;

    error BaksDAOOnlyDepositaryAllowed();

    modifier onlyDepositary() {
        if (msg.sender != address(core.depositary())) {
            revert BaksDAOOnlyDepositaryAllowed();
        }
        _;
    }

    function initializeCoreInside(ICore _core) internal {
        core = _core;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

error GovernedOnlyGovernorAllowedToCall();
error GovernedOnlyPendingGovernorAllowedToCall();
error GovernedGovernorZeroAddress();
error GovernedCantGoverItself();

abstract contract Governed {
    address public governor;
    address public pendingGovernor;

    event PendingGovernanceTransition(address indexed governor, address indexed newGovernor);
    event GovernanceTransited(address indexed governor, address indexed newGovernor);

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert GovernedOnlyGovernorAllowedToCall();
        }
        _;
    }

    function transitGovernance(address newGovernor, bool force) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert GovernedGovernorZeroAddress();
        }
        if (newGovernor == address(this)) {
            revert GovernedCantGoverItself();
        }

        pendingGovernor = newGovernor;
        if (!force) {
            emit PendingGovernanceTransition(governor, newGovernor);
        } else {
            setGovernor(newGovernor);
        }
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernor) {
            revert GovernedOnlyPendingGovernorAllowedToCall();
        }

        governor = pendingGovernor;
        emit GovernanceTransited(governor, pendingGovernor);
    }

    function setGovernor(address newGovernor) internal {
        governor = newGovernor;
        emit GovernanceTransited(governor, newGovernor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error CallToNonContract(address target);

library Address {
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.call(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function delegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        if (!isContract(target)) {
            revert CallToNonContract(target);
        }

        (bool success, bytes memory returnData) = target.delegatecall(data);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(account)
        }

        return codeSize > 0;
    }

    function verifyCallResult(
        bool success,
        bytes memory returnData,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returnData;
        } else {
            if (returnData.length > 0) {
                assembly {
                    let returnDataSize := mload(returnData)
                    revert(add(returnData, 32), returnDataSize)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Address.sol";

error EIP1967ImplementationIsNotContract(address implementation);
error ContractAlreadyInitialized();
error OnlyProxyCallAllowed();
error OnlyCurrentImplementationAllowed();

library EIP1967 {
    using Address for address;

    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Upgraded(address indexed newImplementation);

    function upgradeTo(address newImplementation) internal {
        if (!newImplementation.isContract()) {
            revert EIP1967ImplementationIsNotContract(newImplementation);
        }

        assembly {
            sstore(IMPLEMENTATION_SLOT, newImplementation)
        }

        emit Upgraded(newImplementation);
    }

    function getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

contract Proxy {
    using Address for address;

    constructor(address implementation, bytes memory data) {
        EIP1967.upgradeTo(implementation);
        implementation.delegateCall(data, "Proxy: construction failed");
    }

    receive() external payable {
        delegateCall();
    }

    fallback() external payable {
        delegateCall();
    }

    function delegateCall() internal {
        address implementation = EIP1967.getImplementation();

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

abstract contract Upgradeable {
    address private immutable self = address(this);

    modifier onlyProxy() {
        if (address(this) == self) {
            revert OnlyProxyCallAllowed();
        }
        if (EIP1967.getImplementation() != self) {
            revert OnlyCurrentImplementationAllowed();
        }
        _;
    }

    function upgradeTo(address newImplementation) public virtual onlyProxy {
        EIP1967.upgradeTo(newImplementation);
    }
}

abstract contract Initializable {
    bool private initializing;
    bool private initialized;

    modifier initializer() {
        if (!initializing && initialized) {
            revert ContractAlreadyInitialized();
        }

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }
}