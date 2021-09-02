// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransactionCheckingLibrary.sol";

interface IERC20 {
    function transferFrom(
        address from, 
        address to, 
        uint value) 
        external returns (bool);

    function approve(
        address spender, 
        uint value) 
        external returns (bool);

    function transfer(
        address recipient, 
        uint amount) 
        external returns (bool);
}

interface IWETH {
    function deposit()
        external payable;
        
    function withdraw(uint) 
        external;

    function transfer(
        address to, 
        uint value) 
        external returns (bool);
}

contract Swap {
    using TransactionCheckingLibrary for *;
    
    IUniswapV2Router02 dfynRouter;
    IUniswapV2Router02 sushiRouter;
    IUniswapV2Router02 quickRouter;
    IWETH WETH;
    address immutable owner;
    bool private isSingleEth;
    bool private isMultiToSingleToken;
    address private inputToken;
    address private outputToken;
    string private errorMessage;
    uint[] private amount;

    constructor() 
    {
        owner = 0x05Fc1cCC2928081aFF97A7f9D2CF83C41dFd3C1f;
        dfynRouter = IUniswapV2Router02(0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429);
        sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        quickRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        errorMessage = "Tx Fail";
        amount = new uint[](2);
    }

    function _swapToken(IUniswapV2Router02 _router, uint _amountIn, address[] memory _path, address _to, address _tokenAddress, bool _isEth, uint _minimumAmountOut) private returns (uint[] memory amounts)
    {
        if (TransactionCheckingLibrary._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth && isMultiToSingleToken))
        {
            if (TransactionCheckingLibrary._isWrapUnwrap(_path[0], _path[1], dfynRouter.WETH(), sushiRouter.WETH()))
            {
                WETH = IWETH(_path[0]);
                WETH.deposit{value: _amountIn}();
                assert(WETH.transfer(msg.sender, _amountIn));
            }
            else
            {
                return _router.swapExactETHForTokens{value: _amountIn}(
                    _minimumAmountOut,
                    _path, 
                    _to, 
                    block.timestamp + 180
                );
            }
        }
        else 
        {
            IERC20(_tokenAddress).approve(address(_router), _amountIn+100000000000000000000);
            return _router.swapExactTokensForTokens(
                _amountIn,
                _minimumAmountOut,
                _path,
                _to,
                block.timestamp + 180
            );
        }
    }

    function _swapToETH(address _firstPath, address _secondPath, IUniswapV2Router02 _router, uint _amountIn, uint _minimumAmountOut) private
    {
        if (TransactionCheckingLibrary._isWrapUnwrap(_firstPath, _secondPath, dfynRouter.WETH(), sushiRouter.WETH()))
        {
            WETH = IWETH(_firstPath);
            WETH.withdraw(_amountIn);
            (bool success, ) = msg.sender.call{value: _amountIn}("");
            require(success, errorMessage);
        }
        else
        {
            uint _amount = ((_amountIn*uint(3))/uint(1000));
            _amountIn=_amountIn-_amount;
            IERC20(_firstPath).transfer(owner,_amount);

            IERC20(_firstPath).approve(address(_router), _amountIn);
            _router.swapExactTokensForETH(
                _amountIn,
                _minimumAmountOut,
                TransactionCheckingLibrary._path2(_firstPath, _secondPath),
                msg.sender,
                block.timestamp + 180
            );
        }
    }

    function _everySwapToEth(uint _amountIn, address _token, uint8 _swapRoute, uint[] memory _minimumAmountOut) private
    {
        IERC20(_token).transferFrom(msg.sender, address(this), _amountIn);

        // 1 => Dfyn
        if (_swapRoute == 1) 
        {
            _swapToETH(_token, dfynRouter.WETH(), dfynRouter, _amountIn, _minimumAmountOut[0]);
        }

        // 5 => Sushi
        else if (_swapRoute == 5) 
        {
            _swapToETH(_token, sushiRouter.WETH(), sushiRouter, _amountIn, _minimumAmountOut[0]);
        }

        // 9 => Quick
        else if (_swapRoute == 9) 
        {
            _swapToETH(_token, quickRouter.WETH(), quickRouter, _amountIn, _minimumAmountOut[0]);
        }
    }

    function _firstOption(IUniswapV2Router02 _router, uint _amountIn, bool _isEth, uint[] memory _minimumAmountOut) private
    {
        if (!TransactionCheckingLibrary._checkFirstOption(_router, _amountIn, _minimumAmountOut[0], inputToken, outputToken, TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH())))
        {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        _swapToken(_router, _amountIn, TransactionCheckingLibrary._path2(inputToken, outputToken), msg.sender, inputToken, _isEth, _minimumAmountOut[0]);
    }

    function _secondOption(address _secondPath, IUniswapV2Router02 _router, uint _amountIn, bool _isEth, uint[] memory _minimumAmountOut) private
    {
        if (!TransactionCheckingLibrary._checkSecondOption(_secondPath, _router, _amountIn, _minimumAmountOut[0], inputToken, outputToken, TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH())))
        {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        _swapToken(_router, _amountIn, TransactionCheckingLibrary._path3(inputToken, _secondPath, outputToken), msg.sender, inputToken, _isEth, _minimumAmountOut[0]);
    }

    function _thirdOption(address _secondPath, address _thirdPath, IUniswapV2Router02 _firstRouter, IUniswapV2Router02 _secondRouter, uint _amountIn, bool _isEth, uint[] memory _minimumAmountOut) private
    {
        if (!TransactionCheckingLibrary._checkThirdOption(_secondPath, _thirdPath, _firstRouter, _secondRouter, _amountIn, _minimumAmountOut[0], inputToken, outputToken, TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH())))
        {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        // Swap inputToken to dfynWMatic using dfynRouter
        amount = _swapToken(_firstRouter, _amountIn, TransactionCheckingLibrary._path2(inputToken, _secondPath), address(this), inputToken, _isEth, 0);
        // Swap dfynWMatic to sushiWMatic using dfynRouter
        amount = _swapToken(_firstRouter, amount[amount.length-1], TransactionCheckingLibrary._path2(_secondPath, _thirdPath), address(this), _secondPath, _isEth, 0);
        // Swap sushiWMatic to _tokenTarget using sushiRouter
        _swapToken(_secondRouter, amount[amount.length-1], TransactionCheckingLibrary._path2(_thirdPath, outputToken), msg.sender, _thirdPath, _isEth, _minimumAmountOut[2]);
    }

    function _forthOption(address _secondPath, address _thirdPath, IUniswapV2Router02 _firstRouter, IUniswapV2Router02 _secondRouter, uint _amountIn, bool _isEth, uint[] memory _minimumAmountOut) private
    {
        if (!TransactionCheckingLibrary._checkForthOption(_secondPath, _thirdPath, _firstRouter, _secondRouter, _amountIn, _minimumAmountOut[0], inputToken, outputToken, TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH())))
        {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        // Swap inputToken to sushiWMatic using sushiRouter
        amount = _swapToken(_firstRouter, _amountIn, TransactionCheckingLibrary._path2(inputToken, _secondPath), address(this), inputToken, _isEth, 0);
        // Swap sushiWMatic to dfynWMatic using dfynRouter
        amount = _swapToken(_secondRouter, amount[amount.length-1], TransactionCheckingLibrary._path2(_secondPath, _thirdPath), address(this), _secondPath, _isEth, 0);
        // Swap dfynWMatic to _tokenTarget using dfynRouter
        _swapToken(_secondRouter, amount[amount.length-1], TransactionCheckingLibrary._path2(_thirdPath, outputToken), msg.sender, _thirdPath, _isEth, _minimumAmountOut[2]);
    }

    function _fifthOption(address _secondPath, IUniswapV2Router02 _firstRouter, IUniswapV2Router02 _secondRouter, uint _amountIn, bool _isEth, uint[] memory _minimumAmountOut) private
    {
        if (!TransactionCheckingLibrary._checkFifthOption(_secondPath, _firstRouter, _secondRouter, _amountIn, _minimumAmountOut[0], inputToken, outputToken, TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH())))
        {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        // Swap inputToken to sushiWMatic using sushiRouter
        amount = _swapToken(_firstRouter, _amountIn, TransactionCheckingLibrary._path2(inputToken, _secondPath), address(this), inputToken, _isEth, 0);
        // Assume sushiWMatic = quickWMatic
        // Swap quickWMatic to _tokenTarget using quickRouter
        _swapToken(_secondRouter, amount[amount.length-1], TransactionCheckingLibrary._path2(_secondPath, outputToken), msg.sender, _secondPath, _isEth, _minimumAmountOut[1]);
    }

    function _returnBalance(bool _isEth, uint _amountIn) private
    {
        if (TransactionCheckingLibrary._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth && isMultiToSingleToken))
        {
            (bool ethSuccess, ) = msg.sender.call{value: _amountIn}("");
            require(ethSuccess, errorMessage);
        }
        else
        {
            require(IERC20(inputToken).transfer(msg.sender, _amountIn), errorMessage);
        }
    }

    function swap(uint[] memory _amountIn, address[] memory _token, uint8[] memory _swapRoute, bool[] memory _isEth, address _tokenTarget, bool _isMultiToSingleToken, bool _isSingleEth, uint[][] memory _minimumAmountOut) public payable
    {
        isSingleEth = _isSingleEth;
        isMultiToSingleToken = _isMultiToSingleToken;
        for (uint8 i = 0; i < _token.length; i++)
        {
            inputToken = TransactionCheckingLibrary._getToken(_token[i], _tokenTarget, _isMultiToSingleToken, _swapRoute[i], true, dfynRouter.WETH(), TransactionCheckingLibrary._isInputAllEth(isMultiToSingleToken, isSingleEth));
            outputToken = TransactionCheckingLibrary._getToken(_token[i], _tokenTarget, _isMultiToSingleToken, _swapRoute[i], false, dfynRouter.WETH(), TransactionCheckingLibrary._isInputAllEth(isMultiToSingleToken, isSingleEth));

            if (TransactionCheckingLibrary._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth[i] && isMultiToSingleToken))
            {
                if (!TransactionCheckingLibrary._isWrapUnwrap(inputToken, outputToken, dfynRouter.WETH(), sushiRouter.WETH()))
                {
                    uint _amount = ((_amountIn[i]*uint(3))/uint(1000));
                    _amountIn[i] = _amountIn[i]-((_amountIn[i]*uint(3))/uint(1000));
                    (bool success, ) = owner.call{value: _amount}("");
                    require(success, "Fee Transfer Failed");
                }
            }
            else if (!_isSingleEth && !_isMultiToSingleToken && _isEth[i])
            {
                _everySwapToEth(_amountIn[i], inputToken, _swapRoute[i], _minimumAmountOut[i]);
                continue;
            }
            else
            {
                IERC20(inputToken).transferFrom(msg.sender, address(this), _amountIn[i]);
                uint _amount = ((_amountIn[i]*uint(3))/uint(1000));
                _amountIn[i]=_amountIn[i]-((_amountIn[i]*uint(3))/uint(1000));
                IERC20(inputToken).transfer(owner,_amount);
            }

            // 1 => Dfyn
            if (_swapRoute[i] == 1) 
            {
                _firstOption(dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 2 => Dfyn to Dfyn
            else if (_swapRoute[i] == 2) 
            {
                _secondOption(dfynRouter.WETH(), dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 3 => Dfyn to Dfyn to Sushi
            else if (_swapRoute[i] == 3) 
            {
                _thirdOption(dfynRouter.WETH(), sushiRouter.WETH(), dfynRouter, sushiRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 4 => Dfyn to Dfyn to Quick
            else if (_swapRoute[i] == 4) 
            {
                _thirdOption(dfynRouter.WETH(), quickRouter.WETH(), dfynRouter, quickRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 5 => Sushi
            else if (_swapRoute[i] == 5) 
            {
                _firstOption(sushiRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 6 => Sushi to Sushi
            else if (_swapRoute[i] == 6) 
            {
                _secondOption(sushiRouter.WETH(), sushiRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 7 => Sushi to Dfyn to Dfyn
            else if (_swapRoute[i] == 7) 
            {
                _forthOption(sushiRouter.WETH(), dfynRouter.WETH(), sushiRouter, dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 8 => Sushi to Quick
            else if (_swapRoute[i] == 8) 
            {
                _fifthOption(sushiRouter.WETH(), sushiRouter, quickRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 9 => Quick
            else if (_swapRoute[i] == 9) 
            {
                _firstOption(quickRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 10 => Quick to Quick
            else if (_swapRoute[i] == 10) 
            {
                _secondOption(quickRouter.WETH(), quickRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 11 => Quick to Dfyn to Dfyn
            else if (_swapRoute[i] == 11) 
            {
                _forthOption(quickRouter.WETH(), dfynRouter.WETH(), quickRouter, dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 12 => Quick to Sushi
            else if (_swapRoute[i] == 12) 
            {
                _fifthOption(quickRouter.WETH(), quickRouter, sushiRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 13 => Sushi to Dfyn
            else if (_swapRoute[i] == 13) 
            {
                _fifthOption(sushiRouter.WETH(), sushiRouter, dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 14 => Quick to Dfyn
            else if (_swapRoute[i] == 14) 
            {
                _fifthOption(quickRouter.WETH(), quickRouter, dfynRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 15 => Dfyn to Sushi
            else if (_swapRoute[i] == 15) 
            {
                _fifthOption(sushiRouter.WETH(), dfynRouter, sushiRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }

            // 16 => Dfyn to Quick
            else if (_swapRoute[i] == 16) 
            {
                _fifthOption(quickRouter.WETH(), dfynRouter, quickRouter, _amountIn[i], _isEth[i], _minimumAmountOut[i]);
            }
        }
    }

    function swapToETH(uint[] memory _amountIn, address[] memory _token, uint8[] memory _swapRoute, uint[][] memory _minimumAmountOut) public 
    {
        for (uint i = 0; i < _token.length; i++) 
        {
            _everySwapToEth(_amountIn[i], _token[i], _swapRoute[i], _minimumAmountOut[i]);
        }
    }

    receive() payable external {}
}