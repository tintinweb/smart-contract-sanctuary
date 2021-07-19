/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;



contract pseudoPancakePair{
    
    address public owner;
    address public proposedOwner;
    
    address public token0; //  Torch
    address public token1; // USDT

    uint112 private reserve0;           
    uint112 private reserve1;
    uint32  private blockTimestampLast;
    
    modifier onlyOwner{
        require(msg.sender == owner, "Not permitted!!!");
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner{
        proposedOwner = newOwner;
    }
    
    function claimOwnership() public{
        require(msg.sender==proposedOwner,"must be proposedOwner");
        owner = proposedOwner;
        proposedOwner = address(0);
    }
    
    
    constructor(){
        owner = msg.sender;
    }
    
    // set token pair, TII as token0 and USDT as token1 
    function setTokens(address token0_, address token1_) public onlyOwner{
        token0 = token0_;
        token1 = token1_;
    }
    
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }
    
    
    function setReserves(uint112 r0, uint112 r1)public onlyOwner{
        reserve0 = r0;
        reserve1 = r1;
    }
    
    
    
    
    
}