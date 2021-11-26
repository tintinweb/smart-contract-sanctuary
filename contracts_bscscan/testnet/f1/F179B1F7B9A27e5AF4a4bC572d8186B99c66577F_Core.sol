// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {Initializable} from "./libraries/Upgradability.sol";
import {Governed} from "./Governance.sol";

/// @dev Thrown when trying to set platform fees that don't sum up to one.
/// @param stabilizationFee The stabilization fee that was tried to set.
/// @param exchangeFee The stabilization fee that was tried to set.
/// @param developmentFee The stabilization fee that was tried to set.
error BaksDAOPlatformFeesDontSumUpToOne(uint256 stabilizationFee, uint256 exchangeFee, uint256 developmentFee);

interface ICore {
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

    event ServicingThresholdUpdated(uint256 servicingThreshold, uint256 newServicingThreshold);
    event MinimumLiquidityUpdated(uint256 minimumLiquidity, uint256 newMinimumLiquidity);

    event PriceOracleUpdated(address priceOracle, address newPriceOracle);
    event BankUpdated(address bank, address newBank);
    event DepositaryUpdated(address depositary, address newDepositary);
    event ExchangeFundUpdated(address exchangeFund, address newExchangeFund);
    event DevelopmentFundUpdated(address developmentFund, address newDevelopmentFund);

    function minimumPrincipalAmount() external view returns (uint256);

    function stabilityFee() external view returns (uint256);

    function stabilizationFee() external view returns (uint256);

    function exchangeFee() external view returns (uint256);

    function developmentFee() external view returns (uint256);

    function marginCallLoanToValueRatio() external view returns (uint256);

    function liquidationLoanToValueRatio() external view returns (uint256);

    function rebalancingThreshold() external view returns (uint256);

    function servicingThreshold() external view returns (uint256);

    function minimumLiquidity() external view returns (uint256);

    function priceOracle() external view returns (address);

    function bank() external view returns (address);

    function depositary() external view returns (address);

    function exchangeFund() external view returns (address);

    function developmentFund() external view returns (address);
}

contract Core is Initializable, Governed, ICore {
    uint256 internal constant ONE = 100e16;

    uint256 public override minimumPrincipalAmount;
    uint256 public override stabilityFee;
    uint256 public override stabilizationFee;
    uint256 public override exchangeFee;
    uint256 public override developmentFee;
    uint256 public override marginCallLoanToValueRatio;
    uint256 public override liquidationLoanToValueRatio;
    uint256 public override rebalancingThreshold;

    uint256 public override servicingThreshold;
    uint256 public override minimumLiquidity;

    address public override priceOracle;
    address public override bank;
    address public override depositary;
    address public override exchangeFund;
    address public override developmentFund;

    function initialize() external initializer {
        setGovernor(msg.sender);

        minimumPrincipalAmount = 50e18; // 50 BAKS
        stabilityFee = 3e16; // 3 %
        stabilizationFee = 85e16; // 85 %
        exchangeFee = 15e16; // 15 %
        developmentFee = 0;
        marginCallLoanToValueRatio = 75e16; // 75 %
        liquidationLoanToValueRatio = 83e16; // 83 %
        rebalancingThreshold = 1e16; // 1 %

        servicingThreshold = 1e16; // 1%
        minimumLiquidity = 50000e18; // 50000 BAKS
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

    function setServicingThreshold(uint256 newServicingThreshold) external onlyGovernor {
        emit ServicingThresholdUpdated(servicingThreshold, newServicingThreshold);
        servicingThreshold = newServicingThreshold;
    }

    function setMinimumLiquidity(uint256 newMinimumLiquidity) external onlyGovernor {
        emit MinimumLiquidityUpdated(minimumLiquidity, newMinimumLiquidity);
        minimumLiquidity = newMinimumLiquidity;
    }

    function setBank(address newBank) external onlyGovernor {
        emit BankUpdated(bank, newBank);
        bank = newBank;
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