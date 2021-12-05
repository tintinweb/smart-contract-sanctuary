// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*

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
* SOFTWARE.
*/

//import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
//import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./SafeMath.sol";
import "./SafeBEP20.sol";
import "./OwnableUpgradeable.sol";

import "./IPancakePair.sol";
import "./IPancakeRouter02.sol";
import "./IZap.sol";
import "./IWMATIC.sol";

contract ZapPolygon is IZap, OwnableUpgradeable {
    using SafeMath for uint;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANT VARIABLES ========== */

    address private constant BRL = 0x479D3214079C38eD9ab296D96b88bFe23EEd0002;
    address private constant BUNNY = 0x4C16f69302CcB511c5Fac682c7626B9eF0Dc126a;
    address private constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    address private constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address private constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address private constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant QUICK = 0x831753DD7087CaC61aB5644b308642cc1c33Dc13;
    address private constant BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private constant ETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address private constant AAVE = 0xD6DF932A45C0f255f85145f286eA0b292B21C90B;
    address private constant LINK = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;

    IPancakeRouter02 private constant ROUTER = IPancakeRouter02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) private notFlip;
    mapping(address => address) private routePairAddresses;
    address[] public tokens;

    /* ========== INITIALIZER ========== */

    function initialize() external initializer {
        __Ownable_init();
        require(owner() != address(0), "Zap: owner must be set");

        setNotFlip(WMATIC);
        setNotFlip(BRL);
        setNotFlip(BUNNY);
        setNotFlip(DAI);
        setNotFlip(USDC);
        setNotFlip(USDT);
        setNotFlip(BTC);
        setNotFlip(ETH);
        setNotFlip(QUICK);
        setNotFlip(AAVE);
        setNotFlip(LINK);

        setRoutePairAddress(WMATIC, BRL);
        setRoutePairAddress(WMATIC, ETH);
        setRoutePairAddress(WMATIC, BTC);
        setRoutePairAddress(WMATIC, USDC);        
        setRoutePairAddress(WMATIC, USDT);
        setRoutePairAddress(WMATIC, DAI);
        setRoutePairAddress(WMATIC, QUICK);
        setRoutePairAddress(WMATIC, AAVE);
        setRoutePairAddress(WMATIC, LINK);

        setRoutePairAddress(USDC, USDT);
        setRoutePairAddress(DAI, USDT);
        setRoutePairAddress(USDC, DAI);
        setRoutePairAddress(USDC, ETH);
        setRoutePairAddress(USDC, QUICK);
        setRoutePairAddress(USDC, AAVE);
        setRoutePairAddress(USDC, LINK);
        setRoutePairAddress(USDC, BRL);

        setRoutePairAddress(ETH, USDT);
        setRoutePairAddress(ETH, DAI);
        setRoutePairAddress(ETH, AAVE);
        setRoutePairAddress(ETH, QUICK);

        setRoutePairAddress(BTC, ETH);
        setRoutePairAddress(BTC, USDC);
        setRoutePairAddress(BTC, LINK);
        setRoutePairAddress(LINK, ETH);
        setRoutePairAddress(LINK, QUICK);

        setRoutePairAddress(BUNNY, ETH);
        setRoutePairAddress(BUNNY, QUICK);
        setRoutePairAddress(BRL, ETH);
    }

    receive() external payable {}

    /* ========== View Functions ========== */

    function isFlip(address _address) public view returns (bool) {
        return !notFlip[_address];
    }

    function covers(address _token) public view override returns (bool) {
        return notFlip[_token];
    }

    function routePair(address _address) external view returns (address) {
        return routePairAddresses[_address];
    }

    /* ========== External Functions ========== */

    function zapInToken(
        address _from,
        uint amount,
        address _to
    ) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (isFlip(_to)) {
            IPancakePair pair = IPancakePair(_to);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (_from == token0 || _from == token1) {
                // swap half amount for other
                address other = _from == token0 ? token1 : token0;
                _approveTokenIfNeeded(other);
                uint sellAmount = amount.div(2);
                uint otherAmount = _swap(_from, sellAmount, other, address(this));
                pair.skim(address(this));
                ROUTER.addLiquidity(
                    _from,
                    other,
                    amount.sub(sellAmount),
                    otherAmount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                uint maticAmount;
                if (_from == WMATIC) {
                    IWMATIC(WMATIC).withdraw(amount);
                    maticAmount = amount;
                } else {
                    maticAmount = _swapTokenForMATIC(_from, amount, address(this));
                }

                _swapMATICToFlip(_to, maticAmount, msg.sender);
            }
        } else {
            _swap(_from, amount, _to, msg.sender);
        }
    }

    function zapIn(address _to) external payable override {
        _swapMATICToFlip(_to, msg.value, msg.sender);
    }

    function zapOut(address _from, uint amount) external override {
        IBEP20(_from).safeTransferFrom(msg.sender, address(this), amount);
        _approveTokenIfNeeded(_from);

        if (!isFlip(_from)) {
            _swapTokenForMATIC(_from, amount, msg.sender);
        } else {
            IPancakePair pair = IPancakePair(_from);
            address token0 = pair.token0();
            address token1 = pair.token1();

            if (pair.balanceOf(_from) > 0) {
                pair.burn(address(this));
            }

            if (token0 == WMATIC || token1 == WMATIC) {
                ROUTER.removeLiquidityETH(
                    token0 != WMATIC ? token0 : token1,
                    amount,
                    0,
                    0,
                    msg.sender,
                    block.timestamp
                );
            } else {
                ROUTER.removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp);
            }
        }
    }

    /* ========== Private Functions ========== */

    function _approveTokenIfNeeded(address token) private {
        if (IBEP20(token).allowance(address(this), address(ROUTER)) == 0) {
            IBEP20(token).safeApprove(address(ROUTER), uint(-1));
        }
    }

    function _swapMATICToFlip(
        address flip,
        uint amount,
        address receiver
    ) private {
        if (!isFlip(flip)) {
            _swapMATICForToken(flip, amount, receiver);
        } else {
            // flip
            IPancakePair pair = IPancakePair(flip);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (token0 == WMATIC || token1 == WMATIC) {
                address token = token0 == WMATIC ? token1 : token0;
                uint swapValue = amount.div(2);
                uint tokenAmount = _swapMATICForToken(token, swapValue, address(this));

                _approveTokenIfNeeded(token);
                pair.skim(address(this));
                ROUTER.addLiquidityETH{ value: amount.sub(swapValue) }(
                    token,
                    tokenAmount,
                    0,
                    0,
                    receiver,
                    block.timestamp
                );
            } else {
                uint swapValue = amount.div(2);
                uint token0Amount = _swapMATICForToken(token0, swapValue, address(this));
                uint token1Amount = _swapMATICForToken(token1, amount.sub(swapValue), address(this));

                _approveTokenIfNeeded(token0);
                _approveTokenIfNeeded(token1);
                pair.skim(address(this));
                ROUTER.addLiquidity(token0, token1, token0Amount, token1Amount, 0, 0, receiver, block.timestamp);
            }
        }
    }

    function _swapMATICForToken(
        address token,
        uint value,
        address receiver
    ) private returns (uint) {
        address[] memory path;

        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = WMATIC;
            path[1] = routePairAddresses[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WMATIC;
            path[1] = token;
        }

        uint[] memory amounts = ROUTER.swapExactETHForTokens{ value: value }(0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swapTokenForMATIC(
        address token,
        uint amount,
        address receiver
    ) private returns (uint) {
        address[] memory path;
        if (routePairAddresses[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routePairAddresses[token];
            path[2] = WMATIC;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WMATIC;
        }
        uint[] memory amounts = ROUTER.swapExactTokensForETH(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    function _swap(
        address _from,
        uint amount,
        address _to,
        address receiver
    ) private returns (uint) {
        address intermediate = routePairAddresses[_from];
        if (intermediate == address(0)) {
            intermediate = routePairAddresses[_to];
        }

        address[] memory path;
        if (intermediate != address(0) && (_from == WMATIC || _to == WMATIC)) {
            // [WMATIC, QUICK, X] or [X, QUICK, WMATIC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (intermediate != address(0) && (_from == intermediate || _to == intermediate)) {
            // [BTC, ETH] or [ETH, BTC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] == routePairAddresses[_to]) {
            // [BTC, ETH, DAI] or [DAI, ETH, BTC]
            path = new address[](3);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = _to;
        } else if (
            routePairAddresses[_from] != address(0) &&
            routePairAddresses[_to] != address(0) &&
            routePairAddresses[_from] != routePairAddresses[_to]
        ) {
            // routePairAddresses[xToken] = xRoute
            // [X, BTC, ETH, USDC, Y]
            path = new address[](5);
            path[0] = _from;
            path[1] = routePairAddresses[_from];
            path[2] = WMATIC;
            path[3] = routePairAddresses[_to];
            path[4] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_from] != address(0)) {
            // [BTC, ETH, WMATIC, QUICK]
            path = new address[](4);
            path[0] = _from;
            path[1] = intermediate;
            path[2] = WMATIC;
            path[3] = _to;
        } else if (intermediate != address(0) && routePairAddresses[_to] != address(0)) {
            // [QUICK, WMATIC, ETH, BTC]
            path = new address[](4);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = intermediate;
            path[3] = _to;
        } else if (_from == WMATIC || _to == WMATIC) {
            // [WMATIC, QUICK] or [QUICK, WMATIC]
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            // [QUICK, WMATIC, X] or [X, WMATIC, QUICK]
            path = new address[](3);
            path[0] = _from;
            path[1] = WMATIC;
            path[2] = _to;
        }

        uint[] memory amounts = ROUTER.swapExactTokensForTokens(amount, 0, path, receiver, block.timestamp);
        return amounts[amounts.length - 1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setRoutePairAddress(address asset, address route) public onlyOwner {
        routePairAddresses[asset] = route;
    }

    function setNotFlip(address token) public onlyOwner {
        bool needPush = notFlip[token] == false;
        notFlip[token] = true;
        if (needPush) {
            tokens.push(token);
        }
    }

    function removeToken(uint i) external onlyOwner {
        address token = tokens[i];
        notFlip[token] = false;
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function sweep() external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint amount = IBEP20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForMATIC(token, amount, owner());
            }
        }
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }

        IBEP20(token).transfer(owner(), IBEP20(token).balanceOf(address(this)));
    }
}