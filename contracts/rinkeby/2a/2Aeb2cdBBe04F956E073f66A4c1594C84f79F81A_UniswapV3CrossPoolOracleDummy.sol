/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title UniswapV3 oracle with ability to query across an intermediate liquidity pool
contract UniswapV3CrossPoolOracleDummy {
    uint value;
    address owner;
    
    modifier onlyOwner{
        msg.sender == owner;
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function assetToEth(
        address _tokenIn,
        uint256 _amountIn,
        uint32 _twapPeriod
    ) public view returns (uint256 ethAmountOut) {
        _tokenIn; _amountIn; _twapPeriod;
        return value;
    }

    function ethToAsset(
        uint256 _ethAmountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        _ethAmountIn; _tokenOut; _twapPeriod;
        return value;
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) public view returns (uint256 amountOut) {
        _tokenIn; _amountIn; _tokenOut; _twapPeriod;
        return value;
    }

    function assetToAssetThruRoute(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod,
        address _routeThruToken,
        uint24[2] memory _poolFees
    ) public view returns (uint256 amountOut) {
        _tokenIn; _amountIn; _tokenOut; _twapPeriod; _routeThruToken; _poolFees;
        return value;
    }

    function setValue(uint _val) public onlyOwner{
        value = _val;
    }
    
    function setOwner(address _owner) public onlyOwner{
        owner = _owner;
    }
    
}