pragma solidity 0.5.17;

/// @notice A medianizer price feed.
/// @dev Based off the MakerDAO medianizer (https://github.com/makerdao/median)
interface IMedianizer {
    /// @notice Get the current price.
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    function read() external view returns (uint256);

    /// @notice Get the current price and check if the price feed is active
    /// @dev May revert if caller not whitelisted.
    /// @return Designated price with 18 decimal places.
    /// @return true if price is > 0, else returns false
    function peek() external view returns (uint256, bool);
}
