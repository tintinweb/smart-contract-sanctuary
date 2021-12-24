// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.10;

import "./Context.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IHyperDeFi.sol";
import "./IHyperDeFiBuffer.sol";


contract HyperDeFiBuffer is Context, IHyperDeFiBuffer {
    address            private constant  _BLACK_HOLE = address(0xdead);
    IHyperDeFi         private constant  _TOKEN      = IHyperDeFi(0x99999999f678F56beF0Da5EB96F4c1300Cf8D69a);
    IUniswapV2Router02 private immutable _DEX;
    IERC20             private immutable _USD;
    IERC20             private immutable _WRAP;
    uint8              private           _decimals;


    constructor () {
        _decimals = _TOKEN.decimals();

        address dex;
        address usd;

        (dex, usd) = _TOKEN.getBufferConfigs();
        
        _DEX          = IUniswapV2Router02(dex);
        _USD          = IERC20(usd);
        _WRAP         = IERC20(_DEX.WETH());
    }

    function USD() public view returns (address) {
        return address(_WRAP);
    }

    function metaUSD() public view returns (string memory name, string memory symbol, uint8 decimals) {
        name = _USD.name();
        symbol = _USD.symbol();
        decimals = _USD.decimals();
    }

    function metaWRAP() public view returns (string memory name, string memory symbol, uint8 decimals) {
        name = _WRAP.name();
        symbol = _WRAP.symbol();
        decimals = _WRAP.decimals();
    }

    function priceToken2WRAP() public view returns (uint256 price) {
        address[] memory path = new address[](2);
        
        path[0] = address(_TOKEN);
        path[1] = address(_WRAP);
        
        price = _DEX.getAmountsOut(10 ** _decimals, path)[1];
    }

    function priceToken2USD() public view returns (uint256 price) {
        address[] memory path = new address[](3);
        
        path[0] = address(_TOKEN);
        path[1] = address(_WRAP);
        path[2] = address(_USD);

        price = _DEX.getAmountsOut(10 ** _decimals, path)[2];
    }

    function priceWRAP2USD() public view returns (uint256 price) {
        address[] memory path = new address[](2);
        
        path[0] = address(_WRAP);
        path[1] = address(_USD);

        price = _DEX.getAmountsOut(1e18, path)[1];
    }
    
    function swapIntoLiquidity(uint256 amount) external override {
        require(_msgSender() == address(_TOKEN), "Buffer: caller is not the `HyperDeFi` contract");

        // path
        address[] memory path = new address[](2);
        path[0] = address(_TOKEN);
        path[1] = address(_WRAP);

        // swap half amount to WRAP
        uint256 half = amount / 2;
        _DEX.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            half,
            0,
            path,
            address(this),
            block.timestamp
        );

        // add liquidity
        uint256 WRAPBalance = _WRAP.balanceOf(address(this));
        _WRAP.approve(address(_DEX), WRAPBalance);
        _DEX.addLiquidity(
            address(_TOKEN),
            address(_WRAP),
            _TOKEN.balanceOf(address(this)),
            WRAPBalance,
            0,
            0,
            _BLACK_HOLE,
            block.timestamp
        );

        // swap remaining WRAP to HyperDeFi, then send to black-hole
        uint256 WRAP0 = _WRAP.balanceOf(address(this));
        if (0 < WRAP0) {
            path[0] = address(_WRAP);
            path[1] = address(_TOKEN);
            
            uint256 amountSwap = _DEX.getAmountsOut(WRAP0, path)[1];
            if (0 < amountSwap) {
                _DEX.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    WRAP0,
                    0,
                    path,
                    _BLACK_HOLE,
                    block.timestamp
                );
            }
        }
    }
}