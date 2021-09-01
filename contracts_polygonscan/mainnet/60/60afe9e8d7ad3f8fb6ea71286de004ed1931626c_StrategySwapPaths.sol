/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct StrategyPaths {
    address[] earnedToWmatic;
    address[] earnedToUsdc;
    address[] earnedToCrystl;
    address[] earnedToToken0;
    address[] earnedToToken1;
    address[] token0ToEarned;
    address[] token1ToEarned;
    address[] earnedToMaxi;
}

interface IUniPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

library StrategySwapPaths {
    
    address internal constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address internal constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    function buildAllPaths(StrategyPaths storage paths, address earnedAddress, address middleStep, address crystl, address want, address maxi) public {
            
        makeEarnedToWmaticPath(paths.earnedToWmatic, earnedAddress, middleStep);
        makeEarnedToXPath(paths.earnedToUsdc, paths.earnedToWmatic, USDC);
        makeEarnedToXPath(paths.earnedToCrystl, paths.earnedToWmatic, crystl);
        
        if (maxi != address(0))  makeEarnedToXPath(paths.earnedToMaxi, paths.earnedToWmatic, maxi);
        try IUniPair(want).token0() returns (address _token0) {
            address _token1 = IUniPair(want).token1();
            makeEarnedToXPath(paths.earnedToToken0, paths.earnedToWmatic, _token0);
            makeEarnedToXPath(paths.earnedToToken1, paths.earnedToWmatic, _token1);
            reverseArray(paths.token0ToEarned, paths.earnedToToken0);
            reverseArray(paths.token1ToEarned, paths.earnedToToken1);
        } catch {}

    }
    
    function makeEarnedToWmaticPath(address[] storage _path, address earnedAddress, address middleStep) public {

         _path.push(earnedAddress);
        
        if (earnedAddress == WMATIC) {
        } else if (middleStep == address(0)) {
            _path.push(WMATIC);
        } else {
            _path.push(middleStep);
            _path.push(WMATIC);
        }
    }
    function makeEarnedToXPath(address[] storage _path, address[] memory earnedToWmaticPath, address xToken) public {
        
        if (earnedToWmaticPath[0] == xToken) {
        } else if (earnedToWmaticPath[1] == xToken) {
            _path.push(earnedToWmaticPath[0]);
        } else {
            for (uint i; i < earnedToWmaticPath.length; i++) {
                _path.push(earnedToWmaticPath[i]);
            }
        }
        _path.push(xToken);
    }
    
    function reverseArray(address[] storage _reverse, address[] storage _array) internal {
        for (uint i; i < _array.length; i++) {
            _reverse.push(_array[_array.length - 1 - i]);
        }
    }
    
}