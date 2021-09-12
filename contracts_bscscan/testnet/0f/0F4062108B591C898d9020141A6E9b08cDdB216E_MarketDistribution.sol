// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IMarketDistribution.sol";
import "./IMarketGeneration.sol";
import "./RootedToken.sol";
import "./RootedTransferGate.sol";
import "./TokensRecoverable.sol";
import "./SafeMath.sol";
import "./IERC31337.sol";
import "./IERC20.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./SafeERC20.sol";

contract MarketDistribution is TokensRecoverable, IMarketDistribution
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public override distributionComplete;

    address public gangsterDistillery;
    IMarketGeneration public marketGeneration;
    IPancakeRouter02 pancakeRouter;
    IPancakeFactory pancakeFactory;
    RootedToken public rootedToken;
    IERC31337 public eliteToken;
    IERC20 public baseToken;
    address public immutable devAddress;
    address public oneshotController;

    address public teamAddress;

    address public liquidityController;
    IPancakePair public rootedEliteLP;
    IPancakePair public rootedBaseLP;

    uint256 public constant rootedTokenSupply = 1e26; // 100 mil
    uint256 public totalBaseTokenCollected;
    uint256 public totalBoughtForContributors;
    mapping (address => uint256) public claimTime;
    mapping (address => uint256) public totalClaim;
    mapping (address => uint256) public remainingClaim;
    uint256 public totalBoughtForReferrals;
    
    uint256 public recoveryDate = block.timestamp + 2592000; // 1 Month
    
    uint16 public devCutPercent;
    uint16 public preBuyForReferralsPercent;
    uint16 public preBuyForContributorsPercent;
    uint16 public preBuyForMarketStabilizationPercent;
    uint256 public override vestingPeriodStartTime;
    uint256 public override vestingPeriodEndTime; 
    uint256 public vestingDuration;
    uint256 public rootedBottom;

    constructor(address _devAddress, address _teamAddress, address _oneshotController)
    {
        devAddress = _devAddress;
        teamAddress = _teamAddress;
        oneshotController = _oneshotController;
    }

    function init(
        RootedToken _rootedToken, 
        IERC31337 _eliteToken, 
        address _gangsterDistillery,
        address _liquidityController,
        IPancakeRouter02 _pancakeRouter, 
        IMarketGeneration _marketGeneration,
        uint256 _vestingDuration, 
        uint16 _devCutPercent, 
        uint16 _preBuyForReferralsPercent, 
        uint16 _preBuyForContributorsPercent, 
        uint16 _preBuyForMarketStabilizationPercent) public ownerOnly()
    {        
        rootedToken = _rootedToken;
        eliteToken = _eliteToken;
        gangsterDistillery = _gangsterDistillery;
        baseToken = _eliteToken.wrappedToken();
        liquidityController = _liquidityController;
        pancakeRouter = _pancakeRouter;
        pancakeFactory = IPancakeFactory(_pancakeRouter.factory());
        marketGeneration = _marketGeneration;
        vestingDuration = _vestingDuration;
        devCutPercent = _devCutPercent;
        preBuyForReferralsPercent = _preBuyForReferralsPercent;
        preBuyForContributorsPercent = _preBuyForContributorsPercent;
        preBuyForMarketStabilizationPercent = _preBuyForMarketStabilizationPercent;
    }

    function setupEliteRooted() public
    {
        rootedEliteLP = IPancakePair(pancakeFactory.getPair(address(eliteToken), address(rootedToken)));
        if (address(rootedEliteLP) == address(0)) 
        {
            rootedEliteLP = IPancakePair(pancakeFactory.createPair(address(eliteToken), address(rootedToken)));
            require (address(rootedEliteLP) != address(0));
        }
    }

    function setupBaseRooted() public
    {
        rootedBaseLP = IPancakePair(pancakeFactory.getPair(address(baseToken), address(rootedToken)));
        if (address(rootedBaseLP) == address(0)) 
        {
            rootedBaseLP = IPancakePair(pancakeFactory.createPair(address(baseToken), address(rootedToken)));
            require (address(rootedBaseLP) != address(0));
        }
    }

    function completeSetup() public ownerOnly()
    {   
        require (address(rootedEliteLP) != address(0), "Rooted Elite pool is not created");
        require (address(rootedBaseLP) != address(0), "Rooted Base pool is not created");   

        eliteToken.approve(address(pancakeRouter), uint256(-1));
        rootedToken.approve(address(pancakeRouter), uint256(-1));
        baseToken.safeApprove(address(pancakeRouter), uint256(-1));
        baseToken.safeApprove(address(eliteToken), uint256(-1));
        rootedBaseLP.approve(address(pancakeRouter), uint256(-1));
        rootedEliteLP.approve(address(pancakeRouter), uint256(-1));
    }

    // baseToken = WBNB
    function distribute() public override {
        require (msg.sender == address(marketGeneration), "Unauthorized");
        require (!distributionComplete, "Distribution complete");
   
        vestingPeriodStartTime = block.timestamp;
        vestingPeriodEndTime = block.timestamp + vestingDuration;
        distributionComplete = true;
        totalBaseTokenCollected = baseToken.balanceOf(address(marketGeneration));
        baseToken.safeTransferFrom(msg.sender, address(this), totalBaseTokenCollected);  

        RootedTransferGate gate = RootedTransferGate(address(rootedToken.transferGate()));

        gate.setUnrestricted(true);
        rootedToken.mint(rootedTokenSupply);

        rootedToken.transfer(oneshotController, rootedTokenSupply.mul(15).div(100));

        createRootedEliteLiquidity();

        eliteToken.sweepFloor(address(this));        
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
                
        buyTheBottom();
        preBuyForReferrals();
        preBuyForContributors();
        sellTheTop();

        // WBNB
        uint256 totalBase = totalBaseTokenCollected * devCutPercent / 10000;

        baseToken.transfer(oneshotController, totalBase);
        baseToken.transfer(liquidityController, baseToken.balanceOf(address(this)));

        createRootedBaseLiquidity();

        gate.setUnrestricted(false);
    }   
   
    
    function createRootedEliteLiquidity() private {
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
        pancakeRouter.addLiquidity(address(eliteToken), address(rootedToken), eliteToken.balanceOf(address(this)), rootedToken.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function buyTheBottom() private {
        uint256 amount = totalBaseTokenCollected * preBuyForMarketStabilizationPercent / 10000;  
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);        
        rootedBottom = amounts[1];
    }

    function sellTheTop() private {
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(rootedBottom, 0, rootedElitePath(), address(this), block.timestamp);
        uint256 eliteAmount = amounts[1];
        eliteToken.withdrawTokens(eliteAmount);
    }   
    
    function preBuyForReferrals() private {
        uint256 amount = totalBaseTokenCollected * preBuyForReferralsPercent / 10000;
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        totalBoughtForReferrals = amounts[1];
    }

    function preBuyForContributors() private {
        uint256 preBuyAmount = totalBaseTokenCollected * preBuyForContributorsPercent / 10000;
        uint256 eliteBalance = eliteToken.balanceOf(address(this));
        uint256 amount = preBuyAmount > eliteBalance ? eliteBalance : preBuyAmount;
        uint256[] memory amounts = pancakeRouter.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        totalBoughtForContributors = amounts[1];
    }

    function createRootedBaseLiquidity() private {
        uint256 elitePerLpToken = eliteToken.balanceOf(address(rootedEliteLP)).mul(1e18).div(rootedEliteLP.totalSupply());
        uint256 lpAmountToRemove = baseToken.balanceOf(address(eliteToken)).mul(1e18).div(elitePerLpToken);
        
        (uint256 eliteAmount, uint256 rootedAmount) = pancakeRouter.removeLiquidity(address(eliteToken), address(rootedToken), lpAmountToRemove, 0, 0, address(this), block.timestamp);
        
        uint256 baseInElite = baseToken.balanceOf(address(eliteToken));
        uint256 baseAmount = eliteAmount > baseInElite ? baseInElite : eliteAmount;       
        
        eliteToken.withdrawTokens(baseAmount);
        pancakeRouter.addLiquidity(address(baseToken), address(rootedToken), baseAmount, rootedAmount, 0, 0, liquidityController, block.timestamp);
        rootedEliteLP.transfer(liquidityController, rootedEliteLP.balanceOf(address(this)));
        eliteToken.transfer(liquidityController, eliteToken.balanceOf(address(this)));
    }

    function eliteRootedPath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(eliteToken);
        path[1] = address(rootedToken);
        return path;
    }

    function rootedElitePath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(eliteToken);
        return path;
    }
    
    function getTotalClaim(address account) public view returns (uint256) {
        uint256 contribution = marketGeneration.contribution(account);
        return contribution == 0 ? 0 : contribution.mul(totalBoughtForContributors).div(marketGeneration.totalContribution());
    }

    function getReferralClaim(address account) public view returns (uint256) {
        uint256 referralShare = marketGeneration.referralPoints(account);
        return referralShare == 0 ? 0 : referralShare.mul(totalBoughtForReferrals).div(marketGeneration.totalReferralPoints());
    }

    function claim(address account) public override {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        if (totalClaim[account] == 0){
            totalClaim[account] = remainingClaim[account] = getTotalClaim(account);
        }

        uint256 share = totalClaim[account];
        uint256 endTime = vestingPeriodEndTime > block.timestamp ? block.timestamp : vestingPeriodEndTime;

        require (claimTime[account] < endTime, "Already claimed");

        uint256 claimStartTime = claimTime[account] == 0 ? vestingPeriodStartTime : claimTime[account];
        share = (endTime.sub(claimStartTime)).mul(share).div(vestingDuration);
        claimTime[account] = block.timestamp;
        remainingClaim[account] -= share;
        rootedToken.transfer(account, share);
    }

    function claimReferralRewards(address account, uint256 referralShare) public override {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        uint256 share = referralShare.mul(totalBoughtForReferrals).div(marketGeneration.totalReferralPoints());
        rootedToken.transfer(account, share);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) {
        return block.timestamp > recoveryDate || token != rootedToken;
    }
}