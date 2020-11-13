pragma solidity 0.5.17;

import "./AbstractSortitionPool.sol";
import "./RNG.sol";
import "./api/IStaking.sol";
import "./api/IBonding.sol";
import "./DynamicArray.sol";

/// @title Bonded Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed and bonding requirements.
/// @dev Keeping pool up to date cannot be done eagerly as proliferation of
/// privileged customers could be used to perform DOS attacks by increasing the
/// cost of such updates. When a sortition pool prospectively selects an
/// operator, the selected operator’s eligibility status and weight needs to be
/// checked and, if necessary, updated in the sortition pool. If the changes
/// would be detrimental to the operator, the operator selection is performed
/// again with the updated input to ensure correctness.
/// The pool should specify a reasonable minimum bondable value for operators
/// trying to join the pool, to prevent griefing the selection.
contract BondedSortitionPool is AbstractSortitionPool {
  using DynamicArray for DynamicArray.UintArray;
  using DynamicArray for DynamicArray.AddressArray;
  using RNG for RNG.State;

  struct PoolParams {
    IStaking stakingContract;
    uint256 minimumStake;
    IBonding bondingContract;
    // Defines the minimum unbounded value the operator needs to have to be
    // eligible to join and stay in the sortition pool. Operators not
    // satisfying minimum bondable value are removed from the pool.
    uint256 minimumBondableValue;
    // Bond required from each operator for the currently pending group
    // selection. If operator does not have at least this unbounded value,
    // it is skipped during the selection.
    uint256 requestedBond;
    // The weight divisor in the pool can differ from the minimum stake
    uint256 poolWeightDivisor;
    address owner;
  }

  PoolParams poolParams;

  constructor(
    IStaking _stakingContract,
    IBonding _bondingContract,
    uint256 _minimumStake,
    uint256 _minimumBondableValue,
    uint256 _poolWeightDivisor,
    address _poolOwner
  ) public {
    require(_minimumStake > 0, "Minimum stake cannot be zero");

    poolParams = PoolParams(
      _stakingContract,
      _minimumStake,
      _bondingContract,
      _minimumBondableValue,
      0,
      _poolWeightDivisor,
      _poolOwner
    );
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed and bonding requirements. All operators
  /// in the group are unique.
  ///
  /// If there are not enough operators in a pool to form a group or not
  /// enough operators are eligible for work selection given the bonding
  /// requirements, the function fails.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @param minimumStake The current minimum stake value
  /// @param bondValue Size of the requested bond per operator
  function selectSetGroup(
    uint256 groupSize,
    bytes32 seed,
    uint256 minimumStake,
    uint256 bondValue
  ) public returns (address[] memory) {
    PoolParams memory params = initializeSelectionParams(
      minimumStake,
      bondValue
    );
    require(msg.sender == params.owner, "Only owner may select groups");
    uint256 paramsPtr;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      paramsPtr := params
    }
    return generalizedSelectGroup(groupSize, seed, paramsPtr, true);
  }

  /// @notice Sets the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool. The pool should specify
  /// a reasonable minimum requirement for operators trying to join the pool
  /// to prevent griefing group selection.
  /// @param minimumBondableValue The minimum bondable value required from the
  /// operator.
  function setMinimumBondableValue(uint256 minimumBondableValue) public {
    require(
      msg.sender == poolParams.owner,
      "Only owner may update minimum bond value"
    );

    poolParams.minimumBondableValue = minimumBondableValue;
  }

  /// @notice Returns the minimum bondable value required from the operator
  /// so that it is eligible to be in the pool.
  function getMinimumBondableValue() public view returns (uint256) {
    return poolParams.minimumBondableValue;
  }

  function initializeSelectionParams(uint256 minimumStake, uint256 bondValue)
    internal
    returns (PoolParams memory params)
  {
    params = poolParams;

    if (params.requestedBond != bondValue) {
      params.requestedBond = bondValue;
    }

    if (params.minimumStake != minimumStake) {
      params.minimumStake = minimumStake;
      poolParams.minimumStake = minimumStake;
    }

    return params;
  }

  // Return the eligible weight of the operator,
  // which may differ from the weight in the pool.
  // Return 0 if ineligible.
  function getEligibleWeight(address operator) internal view returns (uint256) {
    address ownerAddress = poolParams.owner;
    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = poolParams.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // Don't query stake if bond is insufficient.
    if (bondableValue < poolParams.minimumBondableValue) {
      return 0;
    }

    uint256 eligibleStake = poolParams.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // but only if eligibleStake >= minimumStake.
    // Ethereum uint256 division performs implicit floor
    // If eligibleStake < poolWeightDivisor, return 0 = ineligible.
    if (eligibleStake < poolParams.minimumStake) {
      return 0;
    }
    return (eligibleStake / poolParams.poolWeightDivisor);
  }

  function decideFate(
    uint256 leaf,
    DynamicArray.AddressArray memory, // `selected`, for future use
    uint256 paramsPtr
  ) internal view returns (Fate memory) {
    PoolParams memory params;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      params := paramsPtr
    }
    address operator = leaf.operator();
    uint256 leafWeight = leaf.weight();

    if (!isLeafInitialized(leaf)) {
      return Fate(Decision.Skip, 0);
    }

    address ownerAddress = params.owner;

    // Get the amount of bondable value available for this pool.
    // We only care that this covers one single bond
    // regardless of the weight of the operator in the pool.
    uint256 bondableValue = params.bondingContract.availableUnbondedValue(
      operator,
      ownerAddress,
      address(this)
    );

    // If unbonded value is insufficient for the operator to be in the pool,
    // delete the operator.
    if (bondableValue < params.minimumBondableValue) {
      return Fate(Decision.Delete, 0);
    }
    // If unbonded value is sufficient for the operator to be in the pool
    // but it is not sufficient for the current selection, skip the operator.
    if (bondableValue < params.requestedBond) {
      return Fate(Decision.Skip, 0);
    }

    uint256 eligibleStake = params.stakingContract.eligibleStake(
      operator,
      ownerAddress
    );

    // Weight = floor(eligibleStake / poolWeightDivisor)
    // Ethereum uint256 division performs implicit floor
    uint256 eligibleWeight = eligibleStake / params.poolWeightDivisor;

    if (eligibleWeight < leafWeight || eligibleStake < params.minimumStake) {
      return Fate(Decision.Delete, 0);
    }
    return Fate(Decision.Select, 0);
  }
}
