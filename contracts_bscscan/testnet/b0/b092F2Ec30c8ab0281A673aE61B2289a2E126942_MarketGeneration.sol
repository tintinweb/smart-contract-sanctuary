// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IWBNB.sol";

contract MarketGeneration is TokensRecoverable, IMarketGeneration {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping (address => uint256) public override contribution;
    mapping (address => uint256) public override referralPoints;

    uint256 public override totalReferralPoints;
    uint256 public override totalContribution;

    uint256 public startTime;
    uint256 public finishTime;

    address public immutable devAddress;

    bool public isActive;

    IERC20 public baseToken;
    IMarketDistribution public marketDistribution;
    uint256 public refundsAllowedUntil;

    event onContribute(address indexed _caller, uint256 _value, uint256 _timestamp);

    constructor(address _devAddress) {
        devAddress = _devAddress;
    }

    modifier active() {
        require (isActive, "Distribution not active");
        _;
    }

    function init(IERC20 _baseToken) public ownerOnly() {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");
        baseToken = _baseToken;
    }

    function activate(IMarketDistribution _marketDistribution) public ownerOnly() {
        require (!isActive && block.timestamp >= refundsAllowedUntil, "Already activated");        
        require (address(_marketDistribution) != address(0));
        marketDistribution = _marketDistribution;
        isActive = true;

        startTime = (block.timestamp * 1000);
        finishTime = ((block.timestamp + 7 days) * 1000);
    }

    function setMarketDistribution(IMarketDistribution _marketDistribution) public ownerOnly() active() {
        require (address(_marketDistribution) != address(0), "Invalid market distribution");
        if (_marketDistribution == marketDistribution) { return; }
        marketDistribution = _marketDistribution;

        // Give everyone 1 day to claim refunds if they don't approve of the new distributor
        refundsAllowedUntil = block.timestamp + 86400;
    }

    function complete() public ownerOnly() active() {
        require (block.timestamp >= refundsAllowedUntil, "Refund period is still active");

        isActive = false;
        if (address(this).balance == 0) { return; }
        
        IWBNB(address(baseToken)).deposit{ value: address(this).balance }();
        baseToken.safeApprove(address(marketDistribution), uint256(-1));

        marketDistribution.distribute();
    }

    function allowRefunds() public ownerOnly() active() {
        isActive = false;
        refundsAllowedUntil = uint256(-1);
    }

    function refund(uint256 amount) private {
        (bool success,) = msg.sender.call{ value: amount }("");
        require (success, "Refund transfer failed");  
          
        totalContribution -= amount;
        contribution[msg.sender] = 0;

        uint256 refPoints = referralPoints[msg.sender];

        if (refPoints > 0) {
            totalReferralPoints -= refPoints;
            referralPoints[msg.sender] = 0;
        }
    }

    function claim() public {
        uint256 amount = contribution[msg.sender];
        require (amount > 0, "Nothing to claim");
        
        if (refundsAllowedUntil > block.timestamp) {
            refund(amount);
        } else {
            marketDistribution.claim(msg.sender);
        }
    }

    function claimReferralRewards() public {
        require (referralPoints[msg.sender] > 0, "No rewards to claim");
        
        uint256 refShare = referralPoints[msg.sender];
        referralPoints[msg.sender] = 0;
        marketDistribution.claimReferralRewards(msg.sender, refShare);
    }

    function contribute(address referral) public payable active() {
        if (referral == address(0) || referral == msg.sender) {
            referralPoints[devAddress] += msg.value;
            totalReferralPoints += msg.value;
        } else {          
            totalReferralPoints +=(msg.value + msg.value);
        }

        contribution[msg.sender] += msg.value;
        totalContribution += msg.value;

        emit onContribute(msg.sender, msg.value, block.timestamp);
    }

    receive() external payable active() {
        contribute(address(0));
    }
}