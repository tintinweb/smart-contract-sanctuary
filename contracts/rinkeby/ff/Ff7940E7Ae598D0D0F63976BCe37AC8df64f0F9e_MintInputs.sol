/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

pragma solidity >=0.8.9;

interface HTokenLike {
    function balanceOf(address account) external view returns (uint256);
}

interface HifiPoolLike {
    function getNormalizedUnderlyingReserves() external view returns (uint256);
    function hToken() external view returns (HTokenLike);
    function underlyingPrecisionScalar() external view returns (uint256);
}

function denormalize(uint256 amount, uint256 precisionScalar) pure returns (uint256 denormalizedAmount) {
    unchecked {
        denormalizedAmount = precisionScalar != 1 ? amount / precisionScalar : amount;
    }
}

function normalize(uint256 amount, uint256 precisionScalar) pure returns (uint256 normalizedAmount) {
    normalizedAmount = precisionScalar != 1 ? amount * precisionScalar : amount;
}
    
contract MintInputs {
    HifiPoolLike public hifiPool;
    
    constructor(HifiPoolLike hifiPool_) {
        hifiPool = hifiPool_;
    }
    
    function getHTokenRequired(uint256 underlyingOffered) external view returns (uint256 hTokenRequired) {
        HTokenLike hToken = hifiPool.hToken();
        uint256 hTokenReserves = hToken.balanceOf(address(hifiPool));
        uint256 normalizedUnderlyingOffered = normalize(underlyingOffered, hifiPool.underlyingPrecisionScalar());
        uint256 normalizedUnderlyingReserves = hifiPool.getNormalizedUnderlyingReserves();
        hTokenRequired = (hTokenReserves * normalizedUnderlyingOffered) / normalizedUnderlyingReserves;
    }
    
    function getUnderlyingRequired(uint256 hTokenOut) external view returns (uint256 underlyingRequired) {
        HTokenLike hToken = hifiPool.hToken();
        uint256 normalizedUnderlyingReserves = hifiPool.getNormalizedUnderlyingReserves();
        uint256 hTokenReserves = hToken.balanceOf(address(hifiPool));
        uint256 normalizedUnderlyingRequired = (normalizedUnderlyingReserves * hTokenOut) / hTokenReserves;
        underlyingRequired = denormalize(normalizedUnderlyingRequired, hifiPool.underlyingPrecisionScalar());
    }
}