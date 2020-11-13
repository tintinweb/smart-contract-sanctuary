pragma solidity ^0.6.0;


/**
 * @title Interface for Balancer.
 * @dev This only contains the methods/events that we use in our contracts or offchain infrastructure.
 */
abstract contract Balancer {
    function getSpotPriceSansFee(address tokenIn, address tokenOut) external virtual view returns (uint256 spotPrice);
}
