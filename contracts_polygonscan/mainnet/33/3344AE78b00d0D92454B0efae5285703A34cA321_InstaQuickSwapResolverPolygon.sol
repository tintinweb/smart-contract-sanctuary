// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title QuickSwap.
 * @dev Decentralized Exchange.
 */

import { Helpers, IQuickSwapRouter, IQuickSwapFactory, IQuickSwapPair, TokenInterface, PoolData } from "./helpers.sol";

abstract contract QuickswapResolver is Helpers {
    function getBuyAmount(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 slippage
    ) public view returns (uint256 buyAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        buyAmt = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 slippage
    ) public view returns (uint256 sellAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeEthAddress(buyAddr, sellAddr);
        sellAmt = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippageA,
        uint256 slippageB
    )
        public
        view
        returns (
            uint256 amountB,
            uint256 uniAmount,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IQuickSwapRouter router = IQuickSwapRouter(getQuickSwapAddr());
        IQuickSwapFactory factory = IQuickSwapFactory(router.factory());
        IQuickSwapPair lpToken = IQuickSwapPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        amountB = router.quote(amountA, reserveA, reserveB);

        uniAmount = mul(amountA, lpToken.totalSupply());
        uniAmount = uniAmount / reserveA;

        amountAMin = wmul(sub(WAD, slippageA), amountA);
        amountBMin = wmul(sub(WAD, slippageB), amountB);
    }

    function getSingleDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 uniAmt,
            uint256 minUniAmt
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IQuickSwapRouter router = IQuickSwapRouter(getQuickSwapAddr());
        IQuickSwapFactory factory = IQuickSwapFactory(router.factory());
        IQuickSwapPair lpToken = IQuickSwapPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 swapAmtA = calculateSwapInAmount(reserveA, amountA);

        amtB = getExpectedBuyAmt(address(_tokenB), address(_tokenA), swapAmtA);
        amtA = sub(amountA, swapAmtA);

        uniAmt = mul(amtA, lpToken.totalSupply());
        uniAmt = uniAmt / add(reserveA, swapAmtA);

        minUniAmt = wmul(sub(WAD, slippage), uniAmt);
    }

    function getDepositAmountNewPool(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 amtB
    ) public view returns (uint256 unitAmt) {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        IQuickSwapRouter router = IQuickSwapRouter(getQuickSwapAddr());
        address exchangeAddr = IQuickSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr == address(0), "pair-found.");
        uint256 _amtA18 = convertTo18(_tokenA.decimals(), amtA);
        uint256 _amtB18 = convertTo18(_tokenB.decimals(), amtB);
        unitAmt = wdiv(_amtB18, _amtA18);
    }

    function getWithdrawAmounts(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 unitAmtA,
            uint256 unitAmtB
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);
        (amtA, amtB) = _getWithdrawAmts(_tokenA, _tokenB, uniAmt);
        (unitAmtA, unitAmtB) = _getWithdrawUnitAmts(_tokenA, _tokenB, amtA, amtB, uniAmt, slippage);
    }

    struct TokenPair {
        address tokenA;
        address tokenB;
    }

    function getPositionByPair(address owner, TokenPair[] memory tokenPairs) public view returns (PoolData[] memory) {
        IQuickSwapRouter router = IQuickSwapRouter(getQuickSwapAddr());
        uint256 _len = tokenPairs.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            (TokenInterface tokenA, TokenInterface tokenB) = changeEthAddress(
                tokenPairs[i].tokenA,
                tokenPairs[i].tokenB
            );
            address exchangeAddr = IQuickSwapFactory(router.factory()).getPair(address(tokenA), address(tokenB));
            if (exchangeAddr != address(0)) {
                IQuickSwapPair lpToken = IQuickSwapPair(exchangeAddr);
                (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
                (reserveA, reserveB) = lpToken.token0() == address(tokenA)
                    ? (reserveA, reserveB)
                    : (reserveB, reserveA);

                uint256 lpAmount = lpToken.balanceOf(owner);
                uint256 totalSupply = lpToken.totalSupply();
                uint256 share = wdiv(lpAmount, totalSupply);
                uint256 amtA = wmul(reserveA, share);
                uint256 amtB = wmul(reserveB, share);
                poolData[i] = PoolData(
                    address(0),
                    address(0),
                    address(lpToken),
                    reserveA,
                    reserveB,
                    amtA,
                    amtB,
                    0,
                    0,
                    lpAmount,
                    totalSupply
                );
            }
            poolData[i].tokenA = tokenPairs[i].tokenA;
            poolData[i].tokenB = tokenPairs[i].tokenB;
            poolData[i].tokenABalance = tokenPairs[i].tokenA == getEthAddr() ? owner.balance : tokenA.balanceOf(owner);
            poolData[i].tokenBBalance = tokenPairs[i].tokenB == getEthAddr() ? owner.balance : tokenB.balanceOf(owner);
        }
        return poolData;
    }

    function getPosition(address owner, address[] memory lpTokens) public view returns (PoolData[] memory) {
        uint256 _len = lpTokens.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            address lpTokenAddr = lpTokens[i];
            poolData[i] = _getPoolData(lpTokenAddr, owner);
        }
        return poolData;
    }
}

contract InstaQuickSwapResolverPolygon is QuickswapResolver {
    string public constant name = "Quickswap-Resolver-v1.1";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { DSMath } from "./dsmath.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IQuickSwapRouter, IQuickSwapFactory, IQuickSwapPair, TokenInterface } from "./interfaces.sol";

library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

struct PoolData {
    address tokenA;
    address tokenB;
    address lpAddress;
    uint256 reserveA;
    uint256 reserveB;
    uint256 tokenAShareAmt;
    uint256 tokenBShareAmt;
    uint256 tokenABalance;
    uint256 tokenBBalance;
    uint256 lpAmount;
    uint256 totalSupply;
}

abstract contract Helpers is DSMath {
    using SafeMath for uint256;
    /**
     * @dev IQuickSwapRouter
     */
    IQuickSwapRouter internal constant router = IQuickSwapRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    function getExpectedBuyAmt(address[] memory paths, uint256 sellAmt) internal view returns (uint256 buyAmt) {
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function changeEthAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit{ value: amount }();
    }

    function convertWethToEth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function getTokenBal(TokenInterface token) internal view returns (uint256 _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getExpectedSellAmt(address[] memory paths, uint256 buyAmt) internal view returns (uint256 sellAmt) {
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function checkPair(address[] memory paths) internal view {
        address pair = IQuickSwapFactory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(address buyAddr, address sellAddr) internal pure returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmt,
        uint256 slippage
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _liquidity
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);

        _amtA = _amt == uint256(-1) ? getTokenBal(TokenInterface(tokenA)) : _amt;
        _amtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA)));

        bool isEth = address(_tokenA) == wethAddr;
        convertEthToWeth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertEthToWeth(isEth, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint256 minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint256 minAmtB = getMinAmount(_tokenB, _amtB, slippage);
        (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(tokenA, tokenB, _amt);
        {
            uint256 minAmtA = convert18ToDec(_tokenA.decimals(), wmul(unitAmtA, _uniAmt));
            uint256 minAmtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmtB, _uniAmt));
            (_amtA, _amtB) = router.removeLiquidity(
                address(_tokenA),
                address(_tokenB),
                _uniAmt,
                minAmtA,
                minAmtB,
                address(this),
                block.timestamp + 1
            );
        }

        bool isEth = address(_tokenA) == wethAddr;
        convertWethToEth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertWethToEth(isEth, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint256 _amt
    )
        internal
        returns (
            TokenInterface _tokenA,
            TokenInterface _tokenB,
            uint256 _uniAmt
        )
    {
        (_tokenA, _tokenB) = changeEthAddress(tokenA, tokenB);
        address exchangeAddr = IQuickSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == uint256(-1) ? uniToken.balanceOf(address(this)) : _amt;
        approve(uniToken, address(router), _uniAmt);
    }

    /** resolver part */
    /**
     * @dev get Ethereum address
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    /**
     * @dev Return quickswap router Address
     */
    function getQuickSwapAddr() internal pure returns (address) {
        return 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    }

    // function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    //     amt = (_amt / 10 ** (18 - _dec));
    // }

    // function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    //     amt = mul(_amt, 10 ** (18 - _dec));
    // }

    // function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
    //     _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
    //     _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    // }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt
    ) internal view returns (uint256 buyAmt) {
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt
    ) internal view returns (uint256 sellAmt) {
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint256 expectedAmt,
        TokenInterface sellAddr,
        uint256 sellAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmt) {
        uint256 _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint256 _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint256 expectedAmt,
        TokenInterface buyAddr,
        uint256 buyAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmt) {
        uint256 _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint256 _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

    function _getWithdrawUnitAmts(
        TokenInterface tokenA,
        TokenInterface tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmtA, uint256 unitAmtB) {
        uint256 _amtA = convertTo18(tokenA.decimals(), amtA);
        uint256 _amtB = convertTo18(tokenB.decimals(), amtB);
        unitAmtA = wdiv(_amtA, uniAmt);
        unitAmtA = wmul(unitAmtA, sub(WAD, slippage));
        unitAmtB = wdiv(_amtB, uniAmt);
        unitAmtB = wmul(unitAmtB, sub(WAD, slippage));
    }

    function _getWithdrawAmts(
        TokenInterface _tokenA,
        TokenInterface _tokenB,
        uint256 uniAmt
    ) internal view returns (uint256 amtA, uint256 amtB) {
        address exchangeAddr = IQuickSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");
        TokenInterface uniToken = TokenInterface(exchangeAddr);
        uint256 share = wdiv(uniAmt, uniToken.totalSupply());
        amtA = wmul(_tokenA.balanceOf(exchangeAddr), share);
        amtB = wmul(_tokenB.balanceOf(exchangeAddr), share);
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn) internal pure returns (uint256) {
        return
            Babylonian.sqrt(reserveIn.mul(userIn.mul(3988000).add(reserveIn.mul(3988009)))).sub(reserveIn.mul(1997)) /
            1994;
    }

    function _getTokenBalance(address token, address owner) internal view returns (uint256) {
        uint256 balance = token == wethAddr ? owner.balance : TokenInterface(token).balanceOf(owner);
        return balance;
    }

    function _getPoolData(address lpTokenAddr, address owner) internal view returns (PoolData memory pool) {
        IQuickSwapPair lpToken = IQuickSwapPair(lpTokenAddr);
        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (address tokenA, address tokenB) = (lpToken.token0(), lpToken.token1());
        uint256 lpAmount = lpToken.balanceOf(owner);
        uint256 totalSupply = lpToken.totalSupply();
        uint256 share = wdiv(lpAmount, totalSupply);
        uint256 amtA = wmul(reserveA, share);
        uint256 amtB = wmul(reserveB, share);
        pool = PoolData(
            tokenA == getAddressWETH() ? getEthAddr() : tokenA,
            tokenB == getAddressWETH() ? getEthAddr() : tokenB,
            address(lpToken),
            reserveA,
            reserveB,
            amtA,
            amtB,
            _getTokenBalance(tokenA, owner),
            _getTokenBalance(tokenB, owner),
            lpAmount,
            totalSupply
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IQuickSwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IQuickSwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IQuickSwapPair {
    function balanceOf(address owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);
}

interface TokenInterface {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}