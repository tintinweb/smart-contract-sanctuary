/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;


/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @param message The error msg
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y, string memory message) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }


    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
    /// @param x The numerator
    /// @param y The denominator
    /// @return z The product of x and y
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
      return x / y;
    }

}

contract DataLocationTest {
    
    using SafeMath for uint256;
    
   uint256 public i;
   uint256 public j;
   
   function seti(uint256 ii) public {
       i = ii;
   }
   
   function setj(uint256 jj) public {
       j = jj;
   }
   
   function getdiv () public view returns (uint256 z){
       return i.div(j);
   }
   function getmul () public view returns (uint256 z){
       return i.mul(j);
   }
   function getadd () public view returns (uint256 z){
       return i.add(j);
   }

}