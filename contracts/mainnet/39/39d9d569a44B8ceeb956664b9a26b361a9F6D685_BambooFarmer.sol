// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import "./uniswapv2/interfaces/IUniswapV2Factory.sol";


// This contract trades tokens collected from fees for BAMBOO, and sends them to BambooField and BambooVault
// As specified in the whitepaper, this contract collects 0.1% of fees and divides 0.06% for BambooVault and 0.04 for BambooField, that rewards past and present liquidity providers

contract BambooFarmer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Factory public factory;
    address public field;
    address public bamboo;
    address public weth;
    // The only dev address
    address public vaultSetter;
    address public vault;

    constructor(IUniswapV2Factory _factory, address _field, address _bamboo, address _weth, address _vaultSetter) {
        factory = _factory;
        bamboo = _bamboo;
        field = _field;
        weth = _weth;
        vaultSetter = _vaultSetter;
    }

    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "must use EOA");
        _;
    }

    function convert(address token0, address token1) public onlyEOA{
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        uint256 pairBalance = pair.balanceOf(address(this));
        if (vault != address(0)) {
            // If vault is set, send 60 to vault 40 to BambooField
            uint256 amountDev = pairBalance.mul(60).div(100);
            pairBalance = pairBalance.sub(amountDev);
            _safeTransfer(address(pair), vault, amountDev);
        }
        // Convert the rest to the original tokens
        pair.transfer(address(pair), pairBalance);
        pair.burn(address(this));
        // First we convert everything to WETH
        uint256 wethAmount = _toWETH(token0) + _toWETH(token1);
        // Then we convert the WETH to Bamboo
        _toBAMBOO(wethAmount);
    }

    // Converts token passed as an argument to WETH
    function _toWETH(address token) internal returns (uint256) {
        // If the passed token is Bamboo, don't convert anything
        if (token == bamboo) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, field, amount);
            return 0;
        }
        // If the passed token is WETH, don't convert anything
        if (token == weth) {
            uint amount = IERC20(token).balanceOf(address(this));
            _safeTransfer(token, factory.getPair(weth, bamboo), amount);
            return amount;
        }
        // If the target pair doesn't exist, don't convert anything
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token, weth));
        if (address(pair) == address(0)) {
            return 0;
        }
        // Choose the correct reserve to swap from
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == token ? (reserve0, reserve1) : (reserve1, reserve0);
        // Calculate information required to swap
        uint amountIn = IERC20(token).balanceOf(address(this));
        uint amountInWithFee = amountIn.mul(1000-pair.fee());
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == token ? (uint(0), amountOut) : (amountOut, uint(0));
        // Swap the token for WETH
        _safeTransfer(token, address(pair), amountIn);
        pair.swap(amount0Out, amount1Out, factory.getPair(weth, bamboo), new bytes(0));
        return amountOut;
    }

    // Converts WETH to Bamboo
    function _toBAMBOO(uint256 amountIn) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(weth, bamboo));
        // Choose WETH as input token
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        (uint reserveIn, uint reserveOut) = token0 == weth ? (reserve0, reserve1) : (reserve1, reserve0);
        // Calculate information required to swap
        uint amountInWithFee = amountIn.mul(1000-pair.fee());
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        (uint amount0Out, uint amount1Out) = token0 == weth ? (uint(0), amountOut) : (amountOut, uint(0));
        // Swap WETH for Bamboo
        pair.swap(amount0Out, amount1Out, field, new bytes(0));
    }

    // Wrapper for safeTransfer
    function _safeTransfer(address token, address to, uint256 amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    function setVault(address _vault) external {
        require(msg.sender == vaultSetter, 'setVault: FORBIDDEN');
        vault = _vault;
    }

    function setVaultSetter(address _vaultSetter) external {
        require(msg.sender == vaultSetter, 'setVault: FORBIDDEN');
        vaultSetter = _vaultSetter;
    }
}