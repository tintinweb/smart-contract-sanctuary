// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./RootKitTransferGate.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";
import "./IVault.sol";
import "./IFloorCalculator.sol";

contract Vault is TokensRecoverable, IVault
{
    using SafeMath for uint256;

    IUniswapV2Router02 immutable uniswapRouter;
    IUniswapV2Factory immutable uniswapFactory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IERC20 rootedEliteLP;
    IERC20 rootedBaseLP;
    IFloorCalculator public calculator;
    RootKitTransferGate public gate;
    mapping(address => bool) public seniorVaultManager;

    constructor(IERC20 _base, IERC31337 _elite, IERC20 _rooted, IFloorCalculator _calculator, RootKitTransferGate _gate, IUniswapV2Router02 _uniswapRouter) 
    {        
        base = _base;
        elite = _elite;
        rooted = _rooted;
        calculator = _calculator;
        gate = _gate;
        uniswapRouter = _uniswapRouter;
        uniswapFactory = IUniswapV2Factory(_uniswapRouter.factory());
        
        _base.approve(address(_elite), uint256(-1));
        _base.approve(address(_uniswapRouter), uint256(-1));
        _rooted.approve(address(_uniswapRouter), uint256(-1));
        _elite.approve(address(_uniswapRouter), uint256(-1));        
    }

    function setupPools() public ownerOnly() {
        rootedBaseLP = IERC20(uniswapFactory.getPair(address(base), address(rooted)));
        rootedBaseLP.approve(address(uniswapRouter), uint256(-1));
       
        rootedEliteLP = IERC20(uniswapFactory.getPair(address(elite), address(rooted)));
        rootedEliteLP.approve(address(uniswapRouter), uint256(-1));
    }

    modifier seniorVaultManagerOnly()
    {
        require(seniorVaultManager[msg.sender], "Not a Senior Vault Manager");
        _;
    }

    // Owner function to enable other contracts or addresses to use the Vault
    function setSeniorVaultManager(address managerAddress, bool allow) public ownerOnly()
    {
        seniorVaultManager[managerAddress] = allow;
    }

    function setCalculatorAndGate(IFloorCalculator _calculator, RootKitTransferGate _gate) public ownerOnly()
    {
        calculator = _calculator;
        gate = _gate;
    }

    // Removes liquidity, buys from either pool, sets a temporary dump tax
    function removeBuyAndTax(uint256 amount, uint256 minAmountOut, address token, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        amount = removeLiq(token, amount);
        buyRootedToken(token, amount, minAmountOut);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }

    // Use Base tokens held by this contract to buy from the Base Pool and sell in the Elite Pool
    function balancePriceBase(uint256 amount, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        amount = buyRootedToken(address(base), amount, 0);
        amount = sellRootedToken(address(elite), amount, minAmountOut);
        elite.withdrawTokens(amount);
    }

    // Use Base tokens held by this contract to buy from the Elite Pool and sell in the Base Pool
    function balancePriceElite(uint256 amount, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        elite.depositTokens(amount);
        amount = buyRootedToken(address(elite), amount, 0);
        amount = sellRootedToken(address(base), amount, minAmountOut);
    }

    // Uses value in the controller to buy
    function buyAndTax(address token, uint256 amountToSpend, uint256 minAmountOut, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        buyRootedToken(token, amountToSpend, minAmountOut);
        gate.setDumpTax(tax, time);
    }

    // Sweeps the Base token under the floor to this address
    function sweepFloor() public override seniorVaultManagerOnly()
    {
        elite.sweepFloor(address(this));
    }

    // Move liquidity from Elite pool --->> Base pool
    function zapEliteToBase(uint256 liquidity) public override seniorVaultManagerOnly() 
    {       
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(elite), liquidity);
        elite.withdrawTokens(liquidity);
        addLiq(address(base), liquidity);
        gate.setUnrestricted(false);
    }

    // Move liquidity from Base pool --->> Elite pool
    function zapBaseToElite(uint256 liquidity) public override seniorVaultManagerOnly() 
    {
        gate.setUnrestricted(true);
        liquidity = removeLiq(address(base), liquidity);
        elite.depositTokens(liquidity);
        addLiq(address(elite), liquidity);
        gate.setUnrestricted(false);
    }

    function wrapToElite(uint256 baseAmount) public override seniorVaultManagerOnly() 
    {
        elite.depositTokens(baseAmount);
    }

    function unwrapElite(uint256 eliteAmount) public override seniorVaultManagerOnly() 
    {
        elite.withdrawTokens(eliteAmount);
    }

    function addLiquidity(address eliteOrBase, uint256 baseAmount) public override seniorVaultManagerOnly() 
    {
        gate.setUnrestricted(true);
        addLiq(eliteOrBase, baseAmount);
        gate.setUnrestricted(false);
    }

    function removeLiquidity(address eliteOrBase, uint256 tokens) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        removeLiq(eliteOrBase, tokens);
        gate.setUnrestricted(false);
    }

    function buyRooted(address token, uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        buyRootedToken(token, amountToSpend, minAmountOut);
    }

    function sellRooted(address token, uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        sellRootedToken(token, amountToSpend, minAmountOut);
    }

    function addLiq(address eliteOrBase, uint256 baseAmount) internal 
    {
        uniswapRouter.addLiquidity(address(eliteOrBase), address(rooted), baseAmount, rooted.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function removeLiq(address eliteOrBase, uint256 tokens) internal returns (uint256)
    {
        (tokens, ) = uniswapRouter.removeLiquidity(address(eliteOrBase), address(rooted), tokens, 0, 0, address(this), block.timestamp);
        return tokens;
    }

    function buyRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, buyPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function sellRootedToken(address token, uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, sellPath(token), address(this), block.timestamp);
        amountToSpend = amounts[1];
        return amountToSpend;
    }

    function buyPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rooted);
        return path;
    }

    function sellPath(address token) internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(token);
        return path;
    }
}