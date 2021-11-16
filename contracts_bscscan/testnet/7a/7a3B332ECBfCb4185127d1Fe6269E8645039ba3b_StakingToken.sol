// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract StakingToken is ERC20("Baby Santa Staking", "xBST"), TokensRecoverable
{
    using SafeMath for uint256;
    IERC20 public immutable rooted;
    IERC20 public immutable payoutToken;

    constructor(IERC20 _rooted, IERC20 _payoutToken) 
    {
        rooted = _rooted;
        payoutToken = _payoutToken;
    }

    // Stake rooted, get staking shares
    function stake(uint256 amount) public 
    {
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalPayout = payoutToken.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalRooted == 0 || totalPayout == 0) 
        {
            _mint(msg.sender, amount);
        } 
        else 
        {
            uint256 mintAmount = amount.mul(totalShares).div(totalRooted + totalPayout);
            _mint(msg.sender, mintAmount);
        }

        rooted.transferFrom(msg.sender, address(this), amount);
    }

    // Unstake shares, claim back rooted
    function unstake(uint256 share) public 
    {
        uint256 totalShares = this.totalSupply();
        uint256 totalRooted = rooted.balanceOf(address(this));
        uint256 totalPayout = payoutToken.balanceOf(address(this));

        uint256 rootedUnstakeAmount = share.div(totalShares).mul(totalRooted);
        uint256 payoutUnstakeAmount = share.div(totalShares).mul(totalPayout);

        _burn(msg.sender, share);
        rooted.transfer(msg.sender, rootedUnstakeAmount);
        payoutToken.transfer(msg.sender, payoutUnstakeAmount);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this) && address(token) != address(rooted) && address(token) != address(payoutToken); 
    }
}