/**
 *Submitted for verification at polygonscan.com on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function getAmountsOut(
        uint amountIn, 
        address[] memory path) 
        external view returns (uint[] memory amounts);
}

contract TokenPrice {
    IUniswapV2Router02 dfynRouter;
    IUniswapV2Router02 sushiRouter;
    IUniswapV2Router02 quickRouter;
    address private ETH;
    address private WETH;

    constructor() 
    {
        ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        WETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        dfynRouter = IUniswapV2Router02(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429);
        sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        quickRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    }
    
    function getPrice(uint _amountIn, address[] memory _path) external view returns (uint[5] memory _result)
    {
        (
            uint _initialPrice,
            uint _price, 
            uint _targetPrice, 
            uint _dfynPrice, 
            uint _sushiPrice, 
            uint _quickPrice, 
            uint _route
        ) = (0,0,0,0,0,0,1);
        
        if (_path[0] == ETH)
        {
            // Dfyn
            _price = _getPriceInputWETH(dfynRouter, _amountIn, _path[1]);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 1;
            }
            if (_dfynPrice < _price)
            {
                _dfynPrice = _price;
            }

            // Sushi
            _price = _getPriceInputWETH(sushiRouter, _amountIn, _path[1]);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 5;
            }
            if (_sushiPrice < _price)
            {
                _sushiPrice = _price;
            }

            // Quick
            _price = _getPriceInputWETH(quickRouter, _amountIn, _path[1]);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 9;
            }
            if (_quickPrice < _price)
            {
                _quickPrice = _price;
            }
        }
        else
        {
            if (_path[0] != WETH && _path[1] != WETH)
            {
                // Dfyn Initial
                _initialPrice = _getPriceOutputWETH(dfynRouter, _amountIn, _path[0]);

                // Dfyn to Dfyn
                _price = _getPriceInputWETH(dfynRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 2;
                }
                if (_dfynPrice < _price)
                {
                    _dfynPrice = _price;
                }

                // Dfyn to Sushi
                _price = _getPriceInputWETH(sushiRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 15;
                }

                // Dfyn to Quick
                _price = _getPriceInputWETH(quickRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 16;
                }
    
                // Sushi Initial
                _initialPrice = _getPriceOutputWETH(sushiRouter, _amountIn, _path[0]);

                // Sushi to Dfyn
                _price = _getPriceInputWETH(dfynRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 13;
                }

                // Sushi to Sushi
                _price = _getPriceInputWETH(sushiRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 6;
                }
                if (_sushiPrice < _price)
                {
                    _sushiPrice = _price;
                }

                // Sushi to Quick
                _price = _getPriceInputWETH(quickRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 8;
                }

                // Quick Initial
                _initialPrice = _getPriceOutputWETH(quickRouter, _amountIn, _path[0]);

                // Quick to Dfyn
                _price = _getPriceInputWETH(dfynRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 14;
                }

                // Quick to Sushi
                _price = _getPriceInputWETH(sushiRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 12;
                }

                // Quick to Quick
                _price = _getPriceInputWETH(quickRouter, _initialPrice, _path[1]);
                if (_targetPrice < _price)
                {
                    _targetPrice = _price;
                    _route = 10;
                }
                if (_quickPrice < _price)
                {
                    _quickPrice = _price;
                }
            }
            
            // Dfyn
            _price = _getPrice(dfynRouter, _amountIn, _path);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 1;
            }
            if (_dfynPrice < _price)
            {
                _dfynPrice = _price;
            }

            // Sushi
            _price = _getPrice(sushiRouter, _amountIn, _path);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 5;
            }
            if (_sushiPrice < _price)
            {
                _sushiPrice = _price;
            }

            // Quick
            _price = _getPrice(quickRouter, _amountIn, _path);
            if (_targetPrice < _price)
            {
                _targetPrice = _price;
                _route = 9;
            }
            if (_quickPrice < _price)
            {
                _quickPrice = _price;
            }
        }
        
        _result = [_targetPrice, _dfynPrice, _sushiPrice, _quickPrice, _route];
    }
    
    function _getPrice(IUniswapV2Router02 _router, uint _amountIn, address[] memory _path) private view returns (uint _price)
    {
        try _router.getAmountsOut(_amountIn, _path) returns (uint[] memory amounts)
        {
            _price = amounts[1];
        }
        catch
        {
            _price = 0;
        }
    }
    
    function _getPriceInputWETH(IUniswapV2Router02 _router, uint _amountIn, address _path1) private view returns (uint _price)
    {
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _path1;
        
        try _router.getAmountsOut(_amountIn, _path) returns (uint[] memory amounts)
        {
            _price = amounts[1];
        }
        catch
        {
            _price = 0;
        }
    }
    
    function _getPriceOutputWETH(IUniswapV2Router02 _router, uint _amountIn, address _path0) private view returns (uint _price)
    {
        address[] memory _path = new address[](2);
        _path[0] = _path0;
        _path[1] = WETH;
        
        try _router.getAmountsOut(_amountIn, _path) returns (uint[] memory amounts)
        {
            _price = amounts[1];
        }
        catch
        {
            _price = 0;
        }
    }
}