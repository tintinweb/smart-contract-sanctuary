pragma solidity 0.5.17;

/// @title GrantStakingPolicy
/// @notice A staking policy defines the function `getStakeableAmount`
/// which calculates how many tokens may be staked from a token grant.
contract GrantStakingPolicy {
    function getStakeableAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff,
        uint256 withdrawn) public view returns (uint256);
}
