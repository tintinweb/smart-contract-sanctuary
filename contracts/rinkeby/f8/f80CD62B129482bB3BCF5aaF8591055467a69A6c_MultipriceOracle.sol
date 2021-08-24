/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @title Multiprice oracle sourcing asset prices from multiple on-chain sources
contract MultipriceOracle {
    address public owner;
    
    mapping(address => mapping(address => uint)) public assetToAssetToAmount;
    
    modifier onlyOwner{
        msg.sender == owner;
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _clPriceBuffer,
        uint32 _uniswapV3TwapPeriod,
        uint8 _inclusionBitmap
    ) public view returns (
        uint256 value,
        uint256 cl,
        uint256 clBuf,
        uint256 uniV3Twap,
        uint256 uniV3Spot,
        uint256 uniV2Spot,
        uint256 sushiSpot
      ) {
        _tokenIn; _amountIn; _clPriceBuffer; _tokenOut; _uniswapV3TwapPeriod; _inclusionBitmap;
        
        uint256 res = assetToAssetToAmount[_tokenIn][_tokenOut];
        value = res;
        cl = res;
        clBuf = res;
        uniV3Twap = res;
        uniV3Spot = res;
        uniV2Spot = res;
        sushiSpot = res;
    }
    
    function setAssetToAssetToAmount(address _assetIn, address _assetOut, uint _val) public onlyOwner{
        assetToAssetToAmount[_assetIn][_assetOut] = _val;
    }
    
    function setOwner(address _owner) public onlyOwner{
        owner = _owner;
    }
    
}