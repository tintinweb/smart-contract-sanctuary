pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../TokenStakingEscrow.sol";
import "../../utils/OperatorParams.sol";


/// @notice TokenStaking contract library allowing to perform two-step stake
/// top-ups for existing delegations.
/// Top-up is a two-step process: it is initiated with a declared top-up value
/// and after waiting for at least the initialization period it can be
/// committed.
library TopUps {
    using SafeMath for uint256;
    using OperatorParams for uint256;

    event TopUpInitiated(address indexed operator, uint256 topUp);
    event TopUpCompleted(address indexed operator, uint256 newAmount);

    struct TopUp {
        uint256 amount;
        uint256 createdAt;
    }

    struct Storage {
        // operator -> TopUp
        mapping(address => TopUp) topUps;
    }

    /// @notice Performs top-up in one step when stake is not yet initialized by
    /// adding the top-up amount to the stake and resetting stake initialization
    /// time counter.
    /// @dev This function should be called only for not yet initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    /// @return New value of parameters. It should be updated for the operator
    /// in the staking contract.
    function instantComplete(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public returns (uint256 newParams) {
        // Stake is not yet initialized so we don't need to check if the
        // operator is not undelegating - initializing and undelegating at the
        // same time is not possible. We do however, need to check whether the
        // operator has not canceled its previous stake for that operator,
        // depositing the stake it in the escrow. We do not want to allow
        // resurrecting operators with cancelled stake by top-ups.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        uint256 newAmount = operatorParams.getAmount().add(value);
        newParams = operatorParams.setAmountAndCreationTimestamp(
            newAmount,
            block.timestamp
        );

        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Initiates top-up of the given value for tokens delegated to
    /// the provided operator. If there is an existing top-up still
    /// initializing, top-up values are summed up and initialization period
    /// is set to the current block timestamp.
    /// @dev This function should be called only for active operators with
    /// initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    function initiate(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public {
        // Stake is initialized, the operator is still active so we need
        // to check if it's not undelegating.
        require(!isUndelegating(operatorParams), "Stake undelegated");
        // We also need to check if the stake for the operator is not already
        // in the escrow because it's been previously cancelled.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        TopUp memory awaiting = self.topUps[operator];
        self.topUps[operator] = TopUp(awaiting.amount.add(value), now);
        emit TopUpInitiated(operator, value);
    }

    /// @notice Commits the top-up if it passed the initialization period.
    /// Tokens are added to the stake once the top-up is committed.
    /// @param operator Operator The operator with a pending stake top-up.
    /// @param initializationPeriod Stake initialization period.
    function commit(
        Storage storage self,
        address operator,
        uint256 operatorParams,
        uint256 initializationPeriod
    ) public returns (uint256 newParams) {
        TopUp memory topUp = self.topUps[operator];
        require(topUp.amount > 0, "No top up to commit");
        require(
            now > topUp.createdAt.add(initializationPeriod),
            "Stake is initializing"
        );

        uint256 newAmount = operatorParams.getAmount().add(topUp.amount);
        newParams = operatorParams.setAmount(newAmount);

        delete self.topUps[operator];
        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Cancels pending, initiating top-up. If there is no initiating
    /// top-up for the operator, function does nothing. This function should be
    /// used when the stake is recovered to return tokens from a pending,
    /// initiating top-up.
    /// @param operator Operator The operator from which the stake is recovered.
    function cancel(
        Storage storage self,
        address operator
    ) public returns (uint256) {
        TopUp memory topUp = self.topUps[operator];
        if (topUp.amount == 0) {
            return 0;
        }

        delete self.topUps[operator];
        return topUp.amount;
    }

    /// @notice Returns true if the given operatorParams indicate that the
    /// operator is undelegating its stake or that it completed stake
    /// undelegation.
    /// @param operatorParams Parameters of the operator, as stored in the
    /// staking contract.
    function isUndelegating(uint256 operatorParams)
        internal view returns (bool) {
        uint256 undelegatedAt = operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }
}
