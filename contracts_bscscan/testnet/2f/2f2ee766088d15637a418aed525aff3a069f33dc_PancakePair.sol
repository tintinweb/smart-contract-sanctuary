/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

contract PancakePair {
    
    address public token0;
    address public token1;
    
    uint112 private reserve0=4e18;         
    uint112 private reserve1=1e8;         

    constructor(address _token0, address _token1)
    {
        token0 = _token0;
        token1 = _token1;
    }
    
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = uint32(block.timestamp % 2**32);
    }
    
    function update(uint112 _reserve0, uint112 _reserve1) public {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }
    
}