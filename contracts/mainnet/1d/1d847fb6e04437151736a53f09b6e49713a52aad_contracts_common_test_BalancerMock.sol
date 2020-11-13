pragma solidity ^0.6.0;

import "../interfaces/Balancer.sol";


/**
 * @title Balancer Mock
 */
contract BalancerMock is Balancer {
    uint256 price = 0;

    // these params arent used in the mock, but this is to maintain compatibility with balancer API
    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external
        virtual
        override
        view
        returns (uint256 spotPrice)
    {
        return price;
    }

    // this is not a balancer call, but for testing for changing price.
    function setPrice(uint256 newPrice) external {
        price = newPrice;
    }
}
