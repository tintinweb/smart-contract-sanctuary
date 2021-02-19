// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./RootKit.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./RootKitTransferGate.sol";
import "./UniswapV2Library.sol";
import "./KETH.sol";
import "./SafeMath.sol";
import "./IPonzoMaBobberV696969.sol";
import "./IERC31337.sol";
import "./IFloorCalculator.sol";


contract PonzoMaBobberV696969 is TokensRecoverable, IPonzoMaBobberV696969

    /*
        Ponzo-Ma-BobberV69.sol
        Status: Fully functional Infinity Edition with kETH swapper
        Calibration: Pumping Rootkit
        
        The Ponzo-Ma-Bobber is a contract with access to critical system control
        functions and liquidity tokens for ROOT. It uses kETH and the ERC-31337 
        sweeper functionality to make upwards market manipulation less tiresome.

        Created by @ProfessorPonzo
    */

{
    using SafeMath for uint256;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    RootKit immutable rootKit;
    IWETH immutable weth;
    KETH keth;
    IERC20 IKETH;
    IERC20 rootKeth;
    IERC20 rootWeth;
    IFloorCalculator calculator;
    RootKitTransferGate gate;
    mapping (address => bool) public infinitePumpers;

    constructor(IUniswapV2Router02 _uniswapV2Router, IWETH _weth, RootKit _rootKit, IFloorCalculator _calculator, RootKitTransferGate _gate)
    {
        uniswapV2Router = _uniswapV2Router;
        rootKit = _rootKit;
        calculator = _calculator;
        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Factory = _uniswapV2Factory;
        weth = _weth;       
        gate = _gate;

        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        rootWeth = IERC20(_uniswapV2Factory.getPair(address(_weth), address(_rootKit)));
        rootWeth.approve(address(_uniswapV2Router), uint256(-1));

    }

    function updateKethLOL(KETH _keth) public ownerOnly(){
        keth = _keth;
        weth.approve(address(_keth), uint256(-1));
        _keth.approve(address(uniswapV2Router), uint256(-1));
        rootKeth = IERC20(uniswapV2Factory.getPair(address(keth), address(rootKit)));
        rootKeth.approve(address(uniswapV2Router), uint256(-1));
    }
        // The Pump Button is really fun, cant keep it all to myself
    function setInfinitePumper(address pumper, bool infinite) public ownerOnly() {
        infinitePumpers[pumper] = infinite;
    }
        // Removes liquidity and buys from either pool, ignores all Root 
    function pumpItPonzo (uint256 PUMPIT, address token) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        PUMPIT = removeLiq(token, PUMPIT);
        buyRoot(token, PUMPIT);
        gate.setUnrestricted(false);
    }
        // Sweeps the wETH under the floor to this address
    function sweepTheFloor() public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        keth.sweepFloor(address(this));
    }
        // Move liquidity from kETH --->> wETH
    function zapKethToWeth(uint256 liquidity) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(keth), liquidity);
        keth.withdrawTokens(liquidity);
        addLiq(address(weth), liquidity);
        gate.setUnrestricted(false);
    }
        // Move liquidity from wETH --->> kETH
    function zapWethToKeth(uint256 liquidity) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(weth), liquidity);
        keth.depositTokens(liquidity);
        addLiq(address(keth), liquidity);
        gate.setUnrestricted(false);
    }
    function wrapToKeth(uint256 wethAmount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        keth.depositTokens(wethAmount);
    }
    function unwrapKeth(uint256 kethAmount) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        keth.withdrawTokens(kethAmount);
    }
    function addLiquidity(address kethORweth, uint256 ethAmount) public override {
        gate.setUnrestricted(true);
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        addLiq(kethORweth, ethAmount);
        gate.setUnrestricted(false);
    }
    function removeLiquidity (address kethORweth, uint256 tokens) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        removeLiq(kethORweth, tokens);
        gate.setUnrestricted(false);
    }
    function buyRootKit(address token, uint256 amountToSpend) public override {
        gate.setUnrestricted(true);
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        buyRoot(token, amountToSpend);
        gate.setUnrestricted(false);
    }
    function sellRootKit(address token, uint256 amountToSpend) public override {
        require (msg.sender == owner || infinitePumpers[msg.sender], "You Wish!!!");
        gate.setUnrestricted(true);
        sellRoot(token, amountToSpend);
        gate.setUnrestricted(false);
    }
    function addLiq(address kethORweth, uint256 ethAmount) internal {
        uniswapV2Router.addLiquidity(address(kethORweth), address(rootKit), ethAmount, rootKit.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }
    function removeLiq(address kethORweth, uint256 tokens) internal returns (uint256) {
        (tokens,) = uniswapV2Router.removeLiquidity(address(kethORweth), address(rootKit), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }
    function buyRoot(address token, uint256 amountToSpend) internal {
        uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, buyPath(token), address(this), block.timestamp);
    }
    function sellRoot(address token, uint256 amountToSpend) internal {
        uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, sellPath(token), address(this), block.timestamp);
    }
    function buyPath(address token) internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rootKit);
        return path;
    }
    function sellPath(address token) internal view returns(address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(rootKit);
        path[1] = address(token);
        return path;
    }
}