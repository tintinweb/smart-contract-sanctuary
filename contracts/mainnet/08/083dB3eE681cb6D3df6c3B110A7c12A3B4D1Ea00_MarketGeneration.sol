// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract MarketGeneration is TokensRecoverable, IMarketGeneration
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping (address => mapping (uint8 => uint256)) public override contributionPerRound;
    mapping (address => uint256) public override totalContribution;
    mapping (uint8 => uint256) public override totalContributionPerRound;
    mapping (address => uint256) public override referralPoints;
    mapping (uint8 => bool) public disabledRounds;
    uint256 public override totalReferralPoints;
    address public immutable devAddress;

    bool public isActive;

    IERC20 immutable baseToken;
    IMarketDistribution public marketDistribution;
    uint256 refundsAllowedUntil;
    uint8 constant public override buyRoundsCount = 3;
    uint256 constant public hardCap = 1234567890000;

    constructor (IERC20 _baseToken, address _devAddress)
    {
        baseToken = _baseToken;
        devAddress = _devAddress;
    }

    modifier active()
    {
        require (isActive, "Distribution not active");
        _;
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

    function disableBuyRound(uint8 round, bool disabled) public ownerOnly() active()
    {
        require (round > 0 && round <= buyRoundsCount, "Round must be 1 to 3");
        disabledRounds[round] = disabled;
    }

    function complete() public ownerOnly() active()
    {
        require (block.timestamp >= refundsAllowedUntil, "Refund period is still active");
        isActive = false;
        if (baseToken.balanceOf(address(this)) == 0) { return; }

        baseToken.safeApprove(address(marketDistribution), uint256(-1));

        marketDistribution.distribute();
    }

    function allowRefunds() public ownerOnly() active()
    {
        isActive = false;
        refundsAllowedUntil = uint256(-1);
    }

    function refund(uint256 amount) private
    {
        baseToken.safeTransfer(msg.sender, amount);
            
        totalContribution[msg.sender] = 0;           

        for (uint8 round = 1; round <= buyRoundsCount; round++)
        {
            uint256 amountPerRound = contributionPerRound[msg.sender][round];
            if (amountPerRound > 0)
            {
                contributionPerRound[msg.sender][round] = 0;
                totalContributionPerRound[round] -= amountPerRound;
            }
        }

        uint256 refPoints = referralPoints[msg.sender];
       
        if (refPoints > 0)
        {
            totalReferralPoints -= refPoints;
            referralPoints[msg.sender] = 0;
        }
    }

    function claim() public 
    {
        uint256 amount = totalContribution[msg.sender];

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

    function claimReferralRewards() public
    {
        require (referralPoints[msg.sender] > 0, "No rewards to claim");
        
        uint256 refShare = referralPoints[msg.sender];
        referralPoints[msg.sender] = 0;
        marketDistribution.claimReferralRewards(msg.sender, refShare);
    }

    function contribute(uint256 amount, uint8 round, address referral) public active() 
    {
        require (round > 0 && round <= buyRoundsCount, "Round must be 1 to 3");
        require (!disabledRounds[round], "Round is disabled");
        require (baseToken.balanceOf(address(this)) < hardCap, "Hard Cap reached");

        baseToken.safeTransferFrom(msg.sender, address(this), amount);

        if (referral == address(0) || referral == msg.sender) 
        {
            referralPoints[devAddress] +=amount;
            totalReferralPoints += amount;
        }
        else 
        {
            referralPoints[msg.sender] += amount;
            referralPoints[referral] += amount;
            totalReferralPoints +=(amount + amount);
        }

        totalContribution[msg.sender] += amount;
        contributionPerRound[msg.sender][round] += amount;
        totalContributionPerRound[round] += amount;
    }
}