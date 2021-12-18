// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";  
import "./IERC20.sol";
import "./Whitelist.sol";

contract MarketGeneration is TokensRecoverable, IMarketGeneration, Whitelist
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping (address => uint256) public override contribution;
    uint256 public override totalContribution;
    address public immutable devAddress;    

    bool public isActive;

    IERC20 public baseToken;
    IMarketDistribution public marketDistribution;
    uint256 public refundsAllowedUntil;

    constructor(address _devAddress)
    {
        devAddress = _devAddress;
    }

    modifier active()
    {
        require (isActive, "Distribution not active");
        _;
    }

    function init(IERC20 _baseToken) public ownerOnly()
    {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");
        baseToken = _baseToken;
    }

    function activate(IMarketDistribution _marketDistribution) public ownerOnly()
    {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");        
        require (address(_marketDistribution) != address(0));
        marketDistribution = _marketDistribution;
        isActive = true;
    }

    function setMarketDistribution(IMarketDistribution _marketDistribution) public ownerOnly() active()
    {
        require (address(_marketDistribution) != address(0), "Invalid market distribution");
        if (_marketDistribution == marketDistribution) { return; }
        marketDistribution = _marketDistribution;

        // Give everyone 1 day to claim refunds if they don't approve of the new distributor
        refundsAllowedUntil = block.timestamp + 86400;
    }

    function complete(
        uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent) public ownerOnly() active()
    {
        require (block.timestamp >= refundsAllowedUntil, "Refund period is still active");
        isActive = false;
        if (baseToken.balanceOf(address(this)) == 0) { return; }
        
        baseToken.safeApprove(address(marketDistribution), uint256(-1));

        marketDistribution.distribute(
        _preBuyForReferralsPercent, 
        _preBuyForContributorsPercent, 
        _preBuyForMarketStabilizationPercent);
    }

    function allowRefunds() public ownerOnly() active()
    {
        isActive = false;
        refundsAllowedUntil = uint256(-1);
    }

    function refund(uint256 amount) private
    {
        (bool success,) = msg.sender.call{ value: amount }("");
        require (success, "Refund transfer failed");  
          
        totalContribution -= amount;
        contribution[msg.sender] = 0;
    }

    function claim() public 
    {
        uint256 amount = contribution[msg.sender];

        require (amount > 0, "Nothing to claim");
        
        if (refundsAllowedUntil > block.timestamp) 
        {
            refund(amount);
        }
        else 
        {
            marketDistribution.claim(msg.sender);
        }
    }

    function contribute(uint256 amount) public active() onlyWhitelisted() 
    {
        require(contribution[msg.sender] <= whitelist[msg.sender].maxContribution, 'Maximum amount contributed');
        require(contribution[msg.sender] + amount <= whitelist[msg.sender].maxContribution, 'Contribution goes over limit');

        baseToken.safeTransferFrom(msg.sender, address(this), amount);

        contribution[msg.sender] += amount;
        totalContribution += amount;
    }

    
}