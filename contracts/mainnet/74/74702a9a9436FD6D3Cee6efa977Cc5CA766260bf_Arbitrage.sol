// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Arbitrage is TokensRecoverable
{
    IERC20 public immutable baseToken;
    IERC31337 public immutable eliteToken;
    IERC20 public immutable rootedToken;
    IERC20 public immutable baseRootedPair;
    IERC20 public immutable eliteRootedPair;
    IUniswapV2Router02 public immutable uniswapV2Router;

    mapping (address => bool) public arbitrageurs;

    event Profit(uint256 _value);

    constructor(IERC20 _baseToken, IERC31337 _eliteToken, IERC20 _rootedToken, IUniswapV2Router02 _uniswapV2Router)
    {
        baseToken = _baseToken;
        eliteToken = _eliteToken;
        rootedToken = _rootedToken;
        uniswapV2Router = _uniswapV2Router;

        IERC20 _baseRootedPair = IERC20(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_baseToken), address(_rootedToken)));
        IERC20 _eliteRootedPair = IERC20(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_eliteToken), address(_rootedToken)));

        baseRootedPair = _baseRootedPair;
        eliteRootedPair = _eliteRootedPair;

        _baseToken.approve(address(_uniswapV2Router), uint256(-1));
        _eliteToken.approve(address(_uniswapV2Router), uint256(-1));
        _rootedToken.approve(address(_uniswapV2Router), uint256(-1));
        _baseToken.approve(address(_eliteToken), uint256(-1));
    }    

    modifier arbitrageurOnly()
    {
        require(arbitrageurs[msg.sender], "Not an arbitrageur");
        _;
    }

    function setArbitrageur(address arbitrageur, bool allow) public ownerOnly()
    {
        arbitrageurs[arbitrageur] = allow;
    }

    function balancePriceBase(uint256 baseAmount) public arbitrageurOnly() 
    {
        uint256 rootedAmount = buyRootedToken(address(baseToken), baseAmount);      
        uint256 eliteAmount = sellRootedToken(address(eliteToken), rootedAmount);
        require(eliteAmount > baseAmount, "No profit");
        eliteToken.withdrawTokens(eliteAmount);
        emit Profit(eliteAmount - baseAmount);
    }

    function balancePriceElite(uint256 eliteAmount) public arbitrageurOnly() 
    {
        eliteToken.depositTokens(eliteAmount);
        uint256 rootedAmount = buyRootedToken(address(eliteToken), eliteAmount);
        uint256 baseAmount = sellRootedToken(address(baseToken), rootedAmount);
        require(baseAmount > eliteAmount, "No profit");
        emit Profit(baseAmount - eliteAmount);
    }

    function buyRootedToken(address token, uint256 amountToSpend) private returns (uint256) 
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(rootedToken);
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp);
        return amounts[1];
    }

    function sellRootedToken(address token, uint256 amountToSpend) private returns (uint256) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(token);
        uint256[] memory amounts = uniswapV2Router.getAmountsOut(amountToSpend, path);   
        amounts = uniswapV2Router.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp);    
        return amounts[1];
    }
}