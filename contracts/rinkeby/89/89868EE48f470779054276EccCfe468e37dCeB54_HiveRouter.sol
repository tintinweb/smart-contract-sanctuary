//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IUniswapV2Pair} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {IERC20} from '@uniswap/v2-core/contracts/interfaces/IERC20.sol';
import {IWETH} from '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import {IVaultTransfers} from './interfaces/IVaultTransfers.sol';
contract HiveRouter {
    address public WETH;
    address public XBE;
    address public smallestTokenAddress;
    IUniswapV2Pair public pair;
    IVaultTransfers public hiveVault;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    constructor(address _vaultAddress, address _pair, address _WETH, address _XBE) {
        pair = IUniswapV2Pair(_pair);
        WETH = _WETH;
        XBE = _XBE;
        hiveVault = IVaultTransfers(_vaultAddress);
        smallestTokenAddress = _WETH < _XBE ? _WETH : _XBE;
    }

    function addLiquidity(uint256 _deadline, uint256 _tokenOutMin) public payable ensure(_deadline) {
        require(msg.value > 0, "ZERO_ETH");
        uint256 half = msg.value / 2;
        require( getAmountXBE(half, IERC20(WETH).balanceOf(address(pair)), IERC20(XBE).balanceOf(address(pair)) ) >= _tokenOutMin, "PRICE_CHANGED");
        uint256 XBEfromSwap = swapETHforXBE(half);
        (uint256 liquidityXBE, uint256 liquidityWETH, uint256 liquidityTokens) = _addLiquidity(XBEfromSwap, half);
        if (XBEfromSwap - liquidityXBE > 0) IERC20(XBE).transfer(msg.sender, XBEfromSwap - liquidityXBE);
        if (half - liquidityWETH > 0) payable(msg.sender).transfer( half - liquidityWETH);
        pair.approve(address(hiveVault), 0);
        pair.approve(address(hiveVault), liquidityTokens);
        pair.transfer(msg.sender, liquidityTokens);
        // hiveVault.depositFor(liquidityTokens, msg.sender);
    }
     
    function getMinSwapAmountXBE(uint256 _amountETH) public view returns(uint256) {
        return getAmountXBE(_amountETH, IERC20(WETH).balanceOf(address(pair)), IERC20(XBE).balanceOf(address(pair)) );
    }

    function swapETHforXBE(uint256 _amountETH) internal returns (uint256 amountXBE){
        uint256 reserveETH = IERC20(WETH).balanceOf(address(pair));
        uint256 reserveXBE = IERC20(XBE).balanceOf(address(pair));        
        amountXBE = getAmountXBE(_amountETH, reserveETH, reserveXBE);
        IWETH(WETH).deposit{value: _amountETH}();
        IWETH(WETH).transfer(address(pair), _amountETH);
        (uint256 amount0Out, uint256 amount1Out) = WETH == smallestTokenAddress ? (uint(0), amountXBE) : (amountXBE, uint(0));
        pair.swap(amount0Out, amount1Out , address(this), new bytes(0));
    }

    function getAmountXBE(uint256 _amountETH, uint256 _reserveETH, uint256 _reserveXBE) internal pure returns (uint) {
        uint256 amountInWithFee = _amountETH * 997;
        uint256 numerator = amountInWithFee * _reserveXBE;
        uint256 denominator = _reserveETH * 1000 + amountInWithFee;
        return numerator / denominator;
    }
    function _addLiquidity(
        uint256 _amountXBEdesired,
        uint256 _amountETHdesired 
        ) internal returns (uint256 liquidityXBE, uint256 liquidityETH, uint256 lpTokens) {    
        uint256 reserveETH = IERC20(WETH).balanceOf(address(pair));
        uint256 reserveXBE = IERC20(XBE).balanceOf(address(pair));
        uint256 amountETHOptimal = _amountXBEdesired * reserveETH / reserveXBE;    
        if (amountETHOptimal <= _amountETHdesired) {
            (liquidityXBE, liquidityETH) = (_amountXBEdesired, amountETHOptimal);
        } else {
            uint256 amountXBEOptimal = _amountETHdesired * reserveXBE / reserveETH;  
            require(amountXBEOptimal <= _amountXBEdesired);
            (liquidityXBE, liquidityETH) = (amountXBEOptimal, _amountETHdesired);
        }
        IERC20(XBE).transfer(address(pair), liquidityXBE);
        IWETH(WETH).deposit{value: liquidityETH}();
        IWETH(WETH).transfer(address(pair), liquidityETH);
        lpTokens = pair.mint(address(this));
    }

    receive() external payable {
        addLiquidity(block.timestamp + 1 minutes, 0);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity ^0.8.0;

interface IVaultTransfers {
  function deposit(uint256 _amount) external;
  function depositFor(uint256 _amount, address _for) external;
  function depositAll() external;
  function withdraw(uint256 _amount) external;
  function withdrawAll() external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}