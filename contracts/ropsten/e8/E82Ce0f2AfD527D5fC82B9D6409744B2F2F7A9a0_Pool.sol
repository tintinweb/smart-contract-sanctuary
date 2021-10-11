// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;


/// @notice DETF pool smart contract
/// @author D-ETF.com
/// @dev The Pool contract keeps all underlaying tokens of DETF token.
/// Contract allowed to do swaps and change the ratio of the underlaying token, after governance contract approval.
contract Pool {
    event Swapped(address srcToken, address destToken, uint256 actSrcAmount, uint256 actDestAmount);
    
    
    function swap(
        address srcToken,
        uint256 minPrice,
        address destToken
    ) public {
        
        uint256 actualSrcAmount = minPrice + 1;
        uint256 actualDestAmount = minPrice + 1;
        emit Swapped(srcToken, destToken, actualSrcAmount, actualDestAmount);
    }

    
}