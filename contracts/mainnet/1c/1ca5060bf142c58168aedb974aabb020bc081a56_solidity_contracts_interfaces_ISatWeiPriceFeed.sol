pragma solidity 0.5.17;

import "../external/IMedianizer.sol";

/// @notice satoshi/wei price feed interface.
interface ISatWeiPriceFeed {
    /// @notice Get the current price of 1 satoshi in wei.
    /// @dev This does not account for any 'Flippening' event.
    /// @return The price of one satoshi in wei.
    function getPrice() external view returns (uint256);

    /// @notice add a new ETH/BTC meidanizer to the internal ethBtcFeeds array
    function addEthBtcFeed(IMedianizer _ethBtcFeed) external;
}
