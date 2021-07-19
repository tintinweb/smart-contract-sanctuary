// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";

// SSBD Token - Same Same But Different Token
// LP token of any token + its elite counterpart
// Use this to create a bridge to an Elite / Rooted token pair
// Give elite token fees to this contract
// compound the rewards into more SSBD LPs for stakers

// Staking contract for Tether / eTether LP on MATIC network
// Help provide an entry and exit path to upTether
// Compound your Lps with the collected fees
contract SSBDStakingToken is ERC20("SSBD Tether", "SSBDUSDT"), TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public immutable SSBDLpToken;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IUniswapV2Router02 immutable uniswapV2Router;    

    constructor(IERC20 _SSBDLpToken, IERC31337 _elite, IERC20 _base, IUniswapV2Router02 _uniswapV2Router) 
    {
        SSBDLpToken = _SSBDLpToken;
        elite = _elite;
        base = _base;
        uniswapV2Router = _uniswapV2Router;

        _base.safeApprove(address(_uniswapV2Router), uint256(-1));
        _base.safeApprove(address(_elite), uint256(-1));
        _elite.approve(address(_uniswapV2Router), uint256(-1));
        _SSBDLpToken.approve(address(_uniswapV2Router), uint256(-1));        
    }

    function compoundLP() public {
        uint256 half = elite.balanceOf(address(this)).div(2);
        elite.withdrawTokens(half);
        uniswapV2Router.addLiquidity(address(elite), address(base), half, half, 0, 0, address(this), block.timestamp);
        elite.depositTokens(base.balanceOf(address(this)));
    }

    // Stake eliteSSBDLpToken, get staking shares
    function stake(uint256 amount) public 
    {
        uint256 totalSSBD = SSBDLpToken.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalSSBD == 0) 
        {
            _mint(msg.sender, amount);
        } 
        else 
        {
            uint256 mintAmount = amount.mul(totalShares).div(totalSSBD);
            _mint(msg.sender, mintAmount);
        }

        SSBDLpToken.transferFrom(msg.sender, address(this), amount);
    }

    // Unstake shares, claim back eliteSSBDLpToken
    function unstake(uint256 share) public 
    {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = share.mul(SSBDLpToken.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, share);
        SSBDLpToken.transfer(msg.sender, unstakeAmount);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this) && address(token) != address(SSBDLpToken); 
    }
}