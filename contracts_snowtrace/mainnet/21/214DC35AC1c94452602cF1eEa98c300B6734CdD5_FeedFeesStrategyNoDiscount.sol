// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract FeedFeesStrategyNoDiscount {
    /***************
     ** Functions **
     ***************/

    /**
     * @notice Get discount basis point based on user shares of token's total supply
     * @param _user: An address of user
     * @return uint256 discount in basis point
     */
    function getDiscountBP(address _user) external pure returns (uint256) {
        return 0;
    }
}