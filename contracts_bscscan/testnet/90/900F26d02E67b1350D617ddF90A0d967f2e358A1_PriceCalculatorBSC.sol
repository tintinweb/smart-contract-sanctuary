// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

import "./IPancakePair.sol";
import "./IPancakeFactory.sol";
import "./AggregatorV3Interface.sol";
import "./IPriceCalculator.sol";


contract PriceCalculatorBSC is IPriceCalculator, OwnableUpgradeable {
    using SafeMath for uint;

    address public constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address public constant CAKE = 0x7f5C7233553ea53666397bDCa6D4d21152394783;
    address public constant BUNNY = 0x0D5B2dFFF4B95B5BD99Bc2D3ac462223574CD986;
    address public constant VAI = 0x4BD17003473389A42DAF6a0a729f6Fdb328BbBd7;
    address public constant BUSD = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    IPancakeFactory private constant factory = IPancakeFactory(0xa7809A889FB61585B49Bc36aD6a34B31c0C681E4);
    
    //note: bloodmoon
    //there are no chainlink oracle on bsc testnet,so when u need bnbPriceFeed,use a default price of bnb-usd
    //in 2021.8.17 which is 429
    
    //2021.8.21 use chainlink
    AggregatorV3Interface private constant bnbPriceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);

    /* ========== STATE VARIABLES ========== */

    mapping(address => address) private pairTokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        setPairToken(VAI, BUSD);
    }

    /* ========== Restricted Operation ========== */

    function setPairToken(address asset, address pairToken) public onlyOwner {
        pairTokens[asset] = pairToken;
    }

    /* ========== Value Calculation ========== */

    function priceOfBNB() view public returns (uint) {
        //note: bloodmoon
        (, int price, , ,) = bnbPriceFeed.latestRoundData();
        //in chainlink oracel contract price is not exactly match ,which have been adjusted
        return uint(price).mul(1e10);
    }

    function priceOfCake() view public returns (uint) {
        (, uint cakePriceInUSD) = valueOfAsset(CAKE, 1e18);
        return cakePriceInUSD;
    }

    function priceOfBunny() view public returns (uint) {
        (, uint bunnyPriceInUSD) = valueOfAsset(BUNNY, 1e18);
        return bunnyPriceInUSD;
    }

    function pricesInUSD(address[] memory assets) public view override returns (uint[] memory) {
        uint[] memory prices = new uint[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            (, uint valueInUSD) = valueOfAsset(assets[i], 1e18);
            prices[i] = valueInUSD;
        }
        return prices;
    }

    function valueOfAsset(address asset, uint amount) public view override returns (uint valueInBNB, uint valueInUSD) {
        if (asset == address(0) || asset == WBNB) {
            valueInBNB = amount;
            valueInUSD = amount.mul(priceOfBNB()).div(1e18);
        }
        else if (keccak256(abi.encodePacked(IPancakePair(asset).symbol())) == keccak256("Cake-LP")) {
            if (IPancakePair(asset).token0() == WBNB || IPancakePair(asset).token1() == WBNB) {
                valueInBNB = amount.mul(IBEP20(WBNB).balanceOf(address(asset))).mul(2).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            } else {
                uint balanceToken0 = IBEP20(IPancakePair(asset).token0()).balanceOf(asset);
                (uint token0PriceInBNB,) = valueOfAsset(IPancakePair(asset).token0(), 1e18);

                valueInBNB = amount.mul(balanceToken0).mul(2).mul(token0PriceInBNB).div(1e18).div(IPancakePair(asset).totalSupply());
                valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
            }
        }
        else {
            address pairToken = pairTokens[asset] == address(0) ? WBNB : pairTokens[asset];
            address pair = factory.getPair(asset, pairToken);
            valueInBNB = IBEP20(pairToken).balanceOf(pair).mul(amount).div(IBEP20(asset).balanceOf(pair));
            if (pairToken != WBNB) {
                (uint pairValueInBNB,) = valueOfAsset(pairToken, 1e18);
                valueInBNB = valueInBNB.mul(pairValueInBNB).div(1e18);
            }
            valueInUSD = valueInBNB.mul(priceOfBNB()).div(1e18);
        }
    }
}