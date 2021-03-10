// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./RootedToken.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./RootedTransferGate.sol";
import "./UniswapV2Library.sol";
import "./EliteToken.sol";
import "./SafeMath.sol";
import "./IPonzoMaBobberReKETH.sol";
import "./IERC31337.sol";
import "./IFloorCalculator.sol";


contract PonzoMaBobberReKETH is TokensRecoverable, IPonzoMaBobberReKETH

    /*
        Rooted-Ponzo-Ma-BobberV69.sol
        Status: Fully functional ReKETH Edition     
        Calibration: Saving the day
        
        The Ponzo-Ma-Bobber is a contract with access to critical system control
        functions and liquidity tokens for ERC31337 / rooted token sets. it uses
        the ERC-31337 sweeper functionality to streamline forced unit-value gain


        Created by @ProfessorPonzo
    */

{
    using SafeMath for uint256;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    ERC31337 elite;
    IERC20 rootedEliteLP;
    IERC20 rootedBaseLP;
    IFloorCalculator calculator;
    RootedTransferGate gate;
    mapping (address => bool) public infinitePumpers;

    constructor(IUniswapV2Router02 _uniswapV2Router, IERC20 _base, IERC20 _rootedToken, ERC31337 _elite, IFloorCalculator _calculator, RootedTransferGate _gate)
    {
        uniswapV2Router = _uniswapV2Router;
        rooted = _rootedToken;
        calculator = _calculator;
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Factory = _uniswapV2Factory;
        base = _base;       
        gate = _gate;
        elite = _elite;

        _base.approve(address(_uniswapV2Router), uint256(-1));
        _base.approve(address(_elite), uint256(-1));
        _rootedToken.approve(address(_uniswapV2Router), uint256(-1));
        rootedBaseLP = IERC20(_uniswapV2Factory.getPair(address(_base), address(_rootedToken)));
        rootedBaseLP.approve(address(_uniswapV2Router), uint256(-1));
        _elite.approve(address(_uniswapV2Router), uint256(-1));
        rootedEliteLP = IERC20(_uniswapV2Factory.getPair(address(_elite), address(_rootedToken)));
        rootedEliteLP.approve(address(_uniswapV2Router), uint256(-1));

    }

    function balancePriceBase(uint256 amount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        uint256 startingBalance = base.balanceOf(address(this));
        amount = buyRootedToken(address(base), amount);
        amount = sellRootedToken(address(elite), amount);
        elite.withdrawTokens(amount);
        require(startingBalance <= base.balanceOf(address(this)));
    }

    function balancePriceElite(uint256 amount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        uint256 startingBalance = base.balanceOf(address(this));
        elite.depositTokens(amount);
        amount = buyRootedToken(address(elite), amount);
        amount = sellRootedToken(address(base), amount);
        require(startingBalance <= base.balanceOf(address(this)));
    }

        // The Pump Button is really fun
    function setInfinitePumper(address pumper, bool infinite) public ownerOnly() {
        infinitePumpers[pumper] = infinite;
    }
        // Removes liquidity and buys from either pool 
    function pumpItPonzo (uint256 PUMPIT, address token, uint16 tax, uint256 time) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        PUMPIT = removeLiq(token, PUMPIT);
        buyRootedToken(token, PUMPIT);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }
    function pumpRooted(address token, uint256 amountToSpend, uint16 tax, uint256 time) public override { //setDumpTax(uint16 _startTaxRate, uint256 _durationInSeconds)
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        buyRootedToken(token, amountToSpend);
        gate.setDumpTax(tax, time);
    }

        // Sweeps the Base token under the floor to this address
    function sweepTheFloor() public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        elite.sweepFloor(address(this));
    }
        // Move liquidity from Elite pool --->> Base pool
    function zapEliteToBase(uint256 liquidity) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(elite), liquidity);
        elite.withdrawTokens(liquidity);
        addLiq(address(base), liquidity);
        gate.setUnrestricted(false);
    }
        // Move liquidity from Base pool --->> Elite pool
    function zapBaseToElite(uint256 liquidity) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(base), liquidity);
        elite.depositTokens(liquidity);
        addLiq(address(elite), liquidity);
        gate.setUnrestricted(false);
    }
    function wrapToElite(uint256 baseAmount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        elite.depositTokens(baseAmount);
    }
    function unwrapElite(uint256 eliteAmount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        elite.withdrawTokens(eliteAmount);
    }
    function addLiquidity(address eliteOrBase, uint256 baseAmount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        addLiq(eliteOrBase, baseAmount);
        gate.setUnrestricted(false);
    }
    function removeLiquidity (address eliteOrBase, uint256 tokens) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        removeLiq(eliteOrBase, tokens);
        gate.setUnrestricted(false);
    }
    function buyRooted(address token, uint256 amountToSpend) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        buyRootedToken(token, amountToSpend);
    }
    function sellRooted(address token, uint256 amountToSpend) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
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