// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";

contract SSBDBalancer is TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public immutable SSBDLpToken;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IUniswapV2Router02 immutable uniswapV2Router;
    address public immutable SSBDStaking;
    uint256 public compoundAmount;

    // This contract keeps a balance of elite token and the bringBalance function 
    // should be called by a bot after every swap event in the SSBD pool

    constructor(IERC20 _SSBDLpToken, IERC31337 _elite, IERC20 _base, IUniswapV2Router02 _uniswapV2Router, address _SSBDStaking) 
    {
        SSBDLpToken = _SSBDLpToken;
        elite = _elite;
        base = _base;
        uniswapV2Router = _uniswapV2Router;
        SSBDStaking = _SSBDStaking;

        _base.safeApprove(address(_uniswapV2Router), uint256(-1));
        _base.safeApprove(address(_elite), uint256(-1));
        _elite.approve(address(_uniswapV2Router), uint256(-1));
        _SSBDLpToken.approve(address(_uniswapV2Router), uint256(-1));        
    }

    function setProfitShare(uint256 _compoundAmount) public ownerOnly(){
        require (_compoundAmount < 100);
        compoundAmount = _compoundAmount;
    }

    function bringBalance() public {
        uint256 startingBalance = elite.balanceOf(address(this));
        uint256 amountA = base.balanceOf(address(SSBDLpToken));
        uint256 amountB = elite.balanceOf(address(SSBDLpToken));
        uint256 smallerAmount = amountA < amountB ? amountA : amountB;
        uint256 balanceAmount = (amountA + amountB).div(2).sub(smallerAmount);
        balanceAmount = balanceAmount > startingBalance ? startingBalance : balanceAmount;
        if (amountA < amountB) {
            elite.withdrawTokens(balanceAmount);
            uniswapV2Router.swapExactTokensForTokens(balanceAmount, 0, buyPathA(), address(this), block.timestamp);
        }
        else {
            uniswapV2Router.swapExactTokensForTokens(balanceAmount, 0, buyPathB(), address(this), block.timestamp);
        }
        elite.depositTokens(base.balanceOf(address(this)));
        uint256 finalBalance = elite.balanceOf(address(this));
        require (finalBalance > startingBalance);
        finalBalance = (finalBalance - startingBalance) * compoundAmount / 100; // % of profit to SSBD staking for compounding.
        elite.transfer(SSBDStaking, finalBalance);
    }

    function buyPathA() internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(base);
        path[1] = address(elite);
        return path;
    }

    function buyPathB() internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(elite);
        path[1] = address(base);
        return path;
    }
}