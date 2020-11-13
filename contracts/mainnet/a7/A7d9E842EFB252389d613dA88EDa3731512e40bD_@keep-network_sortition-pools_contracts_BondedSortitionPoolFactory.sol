pragma solidity 0.5.17;

import "./BondedSortitionPool.sol";
import "./api/IBonding.sol";
import "./api/IStaking.sol";

/// @title Bonded Sortition Pool Factory
/// @notice Factory for the creation of new bonded sortition pools.
contract BondedSortitionPoolFactory {
  /// @notice Creates a new bonded sortition pool instance.
  /// @return Address of the new bonded sortition pool contract instance.
  function createSortitionPool(
    IStaking stakingContract,
    IBonding bondingContract,
    uint256 minimumStake,
    uint256 initialMinimumBond,
    uint256 poolWeightDivisor
  ) public returns (address) {
    return
      address(
        new BondedSortitionPool(
          stakingContract,
          bondingContract,
          minimumStake,
          initialMinimumBond,
          poolWeightDivisor,
          msg.sender
        )
      );
  }
}
