// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";

contract Arbitrage is TokensRecoverable
{
    IERC20 public immutable baseToken;
    IERC31337 public immutable eliteToken;
    IERC20 public immutable rootedToken;
    IERC20 public immutable baseRootedPair;
    IERC20 public immutable eliteRootedPair;
    IPancakeRouter02 public immutable pancakeRouter;

    mapping (address => bool) public arbitrageurs;

    event Profit(uint256 _value);

    constructor(IERC20 _baseToken, IERC31337 _eliteToken, IERC20 _rootedToken, IPancakeRouter02 _pancakeRouter)
    {
        baseToken = _baseToken;
        eliteToken = _eliteToken;
        rootedToken = _rootedToken;
        pancakeRouter = _pancakeRouter;

        IERC20 _baseRootedPair = IERC20(IPancakeFactory(_pancakeRouter.factory()).getPair(address(_baseToken), address(_rootedToken)));
        IERC20 _eliteRootedPair = IERC20(IPancakeFactory(_pancakeRouter.factory()).getPair(address(_eliteToken), address(_rootedToken)));

        baseRootedPair = _baseRootedPair;
        eliteRootedPair = _eliteRootedPair;

        _baseToken.approve(address(_pancakeRouter), uint256(-1));
        _eliteToken.approve(address(_pancakeRouter), uint256(-1));
        _rootedToken.approve(address(_pancakeRouter), uint256(-1));
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
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp);
        return amounts[1];
    }

    function sellRootedToken(address token, uint256 amountToSpend) private returns (uint256) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(token);
        uint256[] memory amounts = pancakeRouter.getAmountsOut(amountToSpend, path);   
        amounts = pancakeRouter.swapExactTokensForTokens(amountToSpend, 0, path, address(this), block.timestamp);    
        return amounts[1];
    }
}