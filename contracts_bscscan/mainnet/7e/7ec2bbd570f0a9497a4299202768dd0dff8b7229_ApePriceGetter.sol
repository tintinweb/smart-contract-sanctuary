// SPDX-License-Identifier: GPL
pragma solidity ^0.8.6;

// This library provides simple price calculations for ApeSwap tokens, accounting
// for commonly used pairings. Will break if USDT, BUSD, or DAI goes far off peg.
// Should NOT be used as the sole oracle for sensitive calculations such as 
// liquidation, as it is vulnerable to manipulation by flash loans, etc. BETA
// SOFTWARE, PROVIDED AS IS WITH NO WARRANTIES WHATSOEVER.

// BSC mainnet version

interface IApePair { function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast); }

library ApePriceGetter {
    
    address public constant FACTORY = 0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6; //ApeFactory
    bytes32 public constant INITCODEHASH = hex'f4ccce374816856d11f00e4069e7cada164065686fbef53c6167a63ec2fd8c5b'; // for pairs created by ApeFactory
    
    //All returned prices calculated with this precision (18 decimals)
    uint public constant PRECISION = 1e18;
    
    //Token addresses
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address constant DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    
    //Ape LP addresses
    address constant BUSD_WBNB_PAIR = 0x51e6D27FA57373d8d4C256231241053a70Cb1d93; // busd is token1
    address constant DAI_WBNB_PAIR = 0xf3010261B58B2874639Ca2e860E9005E3Be5DE0b;  // dai is token0
    address constant USDT_WBNB_PAIR = 0x20bCC3b8a0091dDac2d0BC30F68E6CBb97de59Cd; // usdt is token0
    
    //returns the price of any token in USD based on the standard pairings (BNB/BUSD); zero on failure
    function getTokenPrice(address token) external view returns (uint) {
        if (token == WBNB) return getBNBPrice();
        if (token == BUSD || token == DAI || token == USDT) return PRECISION;
        
        return _getTokenPrice(token, getBNBPrice());
    }
    
    //returns the prices of multiple tokens, zero on failure
    function getTokenPrices(address[] calldata tokens) external view returns (uint[] memory prices) {
        prices = new uint[](tokens.length);
        uint bnbPrice = getBNBPrice();
        
        for (uint i; i < prices.length; i++) {
            address token = tokens[i];
            if (token == WBNB) prices[i] = bnbPrice;
            else if (token == BUSD || token == DAI || token == USDT) prices[i] = PRECISION;
            else prices[i] = _getTokenPrice(token, bnbPrice);
        }
    }
    
    //returns the current USD price of BNB based on stablecoin pairs
    function getBNBPrice() public view returns (uint) {
        (uint daiReserve, uint wbnbReserve0,) = IApePair(DAI_WBNB_PAIR).getReserves();
        (uint wbnbReserve1, uint busdReserve,) = IApePair(BUSD_WBNB_PAIR).getReserves();
        (uint usdtReserve, uint wbnbReserve2,) = IApePair(USDT_WBNB_PAIR).getReserves();
        uint wbnbTotal = wbnbReserve0 + wbnbReserve1 + wbnbReserve2;
        uint usdTotal = daiReserve + busdReserve + usdtReserve;
        
        return usdTotal * 1e18 / wbnbTotal; 
    }
    
    //calculation using a known bnb price
    function _getTokenPrice(address token, uint bnbPrice) internal view returns (uint) {
        address tokenWbnbPair = pairFor(token, WBNB);
        address tokenBusdPair = pairFor(token, BUSD);
        uint numTokens;
        uint pairedValue;
        
        if (isContract(tokenWbnbPair)) {
            (uint reserve0, uint reserve1,) = IApePair(tokenWbnbPair).getReserves();
            (uint reserveToken, uint reserveBNB) = token < WBNB ? (reserve0, reserve1) : (reserve1, reserve0);
            numTokens += reserveToken;
            pairedValue += reserveBNB * bnbPrice;
        }

        if (isContract(tokenBusdPair)) {
            (uint reserve0, uint reserve1,) = IApePair(tokenBusdPair).getReserves();
            (uint reserveToken, uint reserveBUSD) = token < BUSD ? (reserve0, reserve1) : (reserve1, reserve0);
            numTokens += reserveToken;
            pairedValue += reserveBUSD;
        }
        
        if (numTokens == 0) return 0;
        return pairedValue / numTokens;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) private pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                FACTORY,
                keccak256(abi.encodePacked(token0, token1)),
                INITCODEHASH
        )))));
    }
    
    //used with pairFor to quickly determine whether a pair exists
    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

}

