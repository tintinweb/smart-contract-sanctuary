// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./RootKitTransferGate.sol";
import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./ILiquidityController.sol";
import "./IFloorCalculator.sol";


contract LiquidityController is TokensRecoverable, ILiquidityController

{
    using SafeMath for uint256;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IERC20 immutable rootedEliteLP;
    IERC20 immutable rootedBaseLP;
    IFloorCalculator calculator;
    RootKitTransferGate gate;
    mapping (address => bool) public liquidityControllers;

    constructor(IUniswapV2Router02 _uniswapV2Router, IERC20 _base, IERC20 _rootedToken, IERC31337 _elite, IFloorCalculator _calculator, RootKitTransferGate _gate)
    {
        uniswapV2Router = _uniswapV2Router;
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Factory = _uniswapV2Factory;
        
        base = _base;       
        gate = _gate;
        elite = _elite;
        rooted = _rootedToken;
        calculator = _calculator;

        IERC20 _rootedBaseLP = IERC20(_uniswapV2Factory.getPair(address(_base), address(_rootedToken)));
        IERC20 _rootedEliteLP = IERC20(_uniswapV2Factory.getPair(address(_elite), address(_rootedToken)));

        _base.approve(address(_uniswapV2Router), uint256(-1));
        _base.approve(address(_elite), uint256(-1));
        _elite.approve(address(_uniswapV2Router), uint256(-1));       
        _rootedToken.approve(address(_uniswapV2Router), uint256(-1));       
        _rootedBaseLP.approve(address(_uniswapV2Router), uint256(-1));       
        _rootedEliteLP.approve(address(_uniswapV2Router), uint256(-1));

        rootedBaseLP = _rootedBaseLP;
        rootedEliteLP = _rootedEliteLP;
    }
    
    function setCalculatorAndGate(IFloorCalculator _calculator, RootKitTransferGate _gate) public ownerOnly(){
        calculator = _calculator;
        gate = _gate;
    }
    
    function setLiquidityController(address controlAddress, bool controller) public ownerOnly(){
        liquidityControllers[controlAddress] = controller;
    }

    modifier liquidityControllerOnly(){
        require(liquidityControllers[msg.sender], "Not a Liquidity Controller");
        _;
    }

    function balancePriceBase(uint256 amount) public override liquidityControllerOnly() {
        amount = buyRootedToken(address(base), amount);
        amount = sellRootedToken(address(elite), amount);
        elite.withdrawTokens(amount);
    }

    function balancePriceElite(uint256 amount) public override liquidityControllerOnly() {
        elite.depositTokens(amount);
        amount = buyRootedToken(address(elite), amount);
        amount = sellRootedToken(address(base), amount);
    }

    function removeBuyAndTax(uint256 amount, address token, uint16 tax, uint256 time) public override liquidityControllerOnly() {
        gate.setUnrestricted(true);
        amount = removeLiq(token, amount);
        buyRootedToken(token, amount);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }

    function buyAndTax(address token, uint256 amountToSpend, uint16 tax, uint256 time) public override liquidityControllerOnly() { 
        buyRootedToken(token, amountToSpend);
        gate.setDumpTax(tax, time);
    }

    function sweepFloor() public override liquidityControllerOnly() {
        elite.sweepFloor(address(this));
    }

    function zapEliteToBase(uint256 liquidity) public override liquidityControllerOnly() {
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(elite), liquidity);
        elite.withdrawTokens(liquidity);
        addLiq(address(base), liquidity);
        gate.setUnrestricted(false);
    }

    function zapBaseToElite(uint256 liquidity) public override liquidityControllerOnly() {
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(base), liquidity);
        elite.depositTokens(liquidity);
        addLiq(address(elite), liquidity);
        gate.setUnrestricted(false);
    }

    function wrapToElite(uint256 baseAmount) public override liquidityControllerOnly() {
        elite.depositTokens(baseAmount);
    }
    
    function unwrapElite(uint256 eliteAmount) public override liquidityControllerOnly() {
       elite.withdrawTokens(eliteAmount);
    }

    function addLiquidity(address eliteOrBase, uint256 baseAmount) public override liquidityControllerOnly() {
        gate.setUnrestricted(true);
        addLiq(eliteOrBase, baseAmount);
        gate.setUnrestricted(false);
    }

    function removeLiquidity (address eliteOrBase, uint256 tokens) public override liquidityControllerOnly() {
        gate.setUnrestricted(true);
        removeLiq(eliteOrBase, tokens);
        gate.setUnrestricted(false);
    }

    function buyRooted(address token, uint256 amountToSpend) public override liquidityControllerOnly() {
        buyRootedToken(token, amountToSpend);
    }
    
    function sellRooted(address token, uint256 amountToSpend) public override liquidityControllerOnly() {
        sellRootedToken(token, amountToSpend);
    }

    function addLiq(address eliteOrBase, uint256 baseAmount) internal {
        uniswapV2Router.addLiquidity(address(eliteOrBase), address(rooted), baseAmount, rooted.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }
    function removeLiq(address eliteOrBase, uint256 tokens) internal returns (uint256) {
        (tokens,) = uniswapV2Router.removeLiquidity(address(eliteOrBase), address(rooted), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }
    function buyRootedToken(address token, uint256 amountToSpend) internal returns (uint256) {
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, buyPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1]; 
        return amountToSpend;
    }
    function sellRootedToken(address token, uint256 amountToSpend) internal returns (uint256) {
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, sellPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1]; 
        return amountToSpend;
    }
    function buyPath(address token) internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rooted);
        return path;
    }
    function sellPath(address token) internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(token);
        return path;
    }
}