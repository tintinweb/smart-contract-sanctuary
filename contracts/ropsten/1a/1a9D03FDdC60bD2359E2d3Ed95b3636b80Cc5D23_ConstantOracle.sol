/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity =0.6.6;

contract ConstantOracle {
    
    // note this will always return 0 before update has been called successfully for the first time.
    function getData() external pure returns (uint amountOut) {
        amountOut = 1000000000000000000;
    }
    
}