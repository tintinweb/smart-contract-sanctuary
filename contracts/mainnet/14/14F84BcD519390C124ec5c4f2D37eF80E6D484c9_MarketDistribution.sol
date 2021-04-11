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
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./SafeERC20.sol";

/*
Introducing the Market Generation Event:

Allows full and permanent liquidity locking
of all raised funds with no commitment to LPs. 
Using ERC-31337 we get ALL the raised funds
back from liquidity if we lock all the raised
token with all the supply of the new token and
there is no ability to mint.

- Raise with any token
- All raised funds get locked forever
- ERC-31337 sweeps back all locked value
- Recovered value buys from the new market
- Any length vesting period
- Built in referral system

Phases:
    Initializing
        Call setupEliteRooted()
        Call setupBaseRooted() 
        Call completeSetup()
        
    Call distribute() to:
        Transfer all rootedToken to this contract
        Take all BaseToken + rootedToken and create a market
        Sweep the floor
        Buy rootedToken for the groups
        Move liquidity from elite pool to create standard pool
        Begin the vesting period with a linier unlock

    Complete
        Everyone can call claim() to receive their tokens (via the liquidity generation contract)
*/

contract MarketDistribution is TokensRecoverable, IMarketDistribution
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public override distributionComplete;

    IMarketGeneration immutable public marketGeneration;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    RootedToken immutable public rootedToken;
    IERC31337 immutable public eliteToken;
    IERC20 immutable public baseToken;
    address immutable devAddress;

    IUniswapV2Pair public rootedEliteLP;
    IUniswapV2Pair public rootedBaseLP;

    uint256 public totalBaseTokenCollected;
    mapping (uint8 => uint256) public totalRootedTokenBoughtPerRound;
    mapping (address => uint256) public claimTime;
    mapping (address => uint256) public totalOwed;
    uint256 public totalBoughtForReferrals;
    
    uint256 public recoveryDate = block.timestamp + 2592000; // 1 Month
    
    uint16 constant public devCutPercent = 1000; // 10%
    uint16 constant public preBuyForReferralsPercent = 200; // 2%
    uint16 constant public preBuyForMarketManipulationPercent = 800; // 8%
    uint256 public override vestingPeriodStartTime;
    uint256 public override vestingPeriodEndTime; 
    uint256 public vestingDuration = 600000 seconds; // ~6.9 days
    uint256 public rootedBottom;

    constructor(RootedToken _rootedToken, IERC31337 _eliteToken, IMarketGeneration _marketGeneration, IUniswapV2Router02 _uniswapV2Router, address _devAddress)
    {
        require (address(_rootedToken) != address(0));

        rootedToken = _rootedToken;        
        eliteToken = _eliteToken;
        uniswapV2Router = _uniswapV2Router;
        marketGeneration = _marketGeneration;

        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        baseToken = _eliteToken.wrappedToken();
        devAddress = _devAddress;
    }

    function setupEliteRooted() public
    {
        rootedEliteLP = IUniswapV2Pair(uniswapV2Factory.getPair(address(eliteToken), address(rootedToken)));
        if (address(rootedEliteLP) == address(0)) 
        {
            rootedEliteLP = IUniswapV2Pair(uniswapV2Factory.createPair(address(eliteToken), address(rootedToken)));
            require (address(rootedEliteLP) != address(0));
        }
    }

    function setupBaseRooted() public
    {
        rootedBaseLP = IUniswapV2Pair(uniswapV2Factory.getPair(address(baseToken), address(rootedToken)));
        if (address(rootedBaseLP) == address(0)) 
        {
            rootedBaseLP = IUniswapV2Pair(uniswapV2Factory.createPair(address(baseToken), address(rootedToken)));
            require (address(rootedBaseLP) != address(0));
        }
    }

    function completeSetup() public ownerOnly()
    {   
        require (address(rootedEliteLP) != address(0), "Rooted Elite pool is not created");
        require (address(rootedBaseLP) != address(0), "Rooted Base pool is not created");   

        eliteToken.approve(address(uniswapV2Router), uint256(-1));
        rootedToken.approve(address(uniswapV2Router), uint256(-1));
        baseToken.safeApprove(address(uniswapV2Router), uint256(-1));
        baseToken.safeApprove(address(eliteToken), uint256(-1));
        rootedBaseLP.approve(address(uniswapV2Router), uint256(-1));
        rootedEliteLP.approve(address(uniswapV2Router), uint256(-1));
    }

    function distribute() public override
    {
        require (msg.sender == address(marketGeneration), "Unauthorized");
        require (!distributionComplete, "Distribution complete");
   
        vestingPeriodStartTime = block.timestamp;
        vestingPeriodEndTime = block.timestamp + vestingDuration;
        distributionComplete = true;
        totalBaseTokenCollected = baseToken.balanceOf(address(marketGeneration));
        baseToken.safeTransferFrom(msg.sender, address(this), totalBaseTokenCollected);  

        RootedTransferGate gate = RootedTransferGate(address(rootedToken.transferGate()));

        gate.setUnrestricted(true);
        rootedToken.mint(totalBaseTokenCollected);

        createRootedEliteLiquidity();

        eliteToken.sweepFloor(address(this));

        uint256 devCut = totalBaseTokenCollected * devCutPercent / 10000;
        baseToken.safeTransfer(devAddress, devCut);
        
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
                
        buyTheBottom();        
        preBuyForReferrals();
        preBuyForGroups();

        eliteToken.transfer(devAddress, eliteToken.balanceOf(address(this))); // upFund, send direct to Liquidity Controller in future

        sellTheTop(); 
        createRootedBaseLiquidity();

        gate.setUnrestricted(false);
    }   
    
    function createRootedEliteLiquidity() private
    {
        // Create Rooted/Elite LP 
        eliteToken.depositTokens(baseToken.balanceOf(address(this)));
        uniswapV2Router.addLiquidity(address(eliteToken), address(rootedToken), eliteToken.balanceOf(address(this)), rootedToken.totalSupply(), 0, 0, address(this), block.timestamp);
    }

    function buyTheBottom() private
    {
        uint256 amount = totalBaseTokenCollected * preBuyForMarketManipulationPercent / 10000;  
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        uint256 rootedAmout = amounts[1];
        rootedToken.transfer(devAddress, rootedAmout.div(2));
        rootedBottom = rootedToken.balanceOf(address(this));
    }

    function sellTheTop() private
    {
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(rootedBottom, 0, rootedElitePath(), address(this), block.timestamp);
        uint256 eliteAmount = amounts[1];
        eliteToken.withdrawTokens(eliteAmount);
        baseToken.safeTransfer(devAddress, eliteAmount);
    }   
    
    function preBuyForReferrals() private 
    {
        uint256 amount = totalBaseTokenCollected * preBuyForReferralsPercent / 10000;
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
        totalBoughtForReferrals = amounts[1];
    }

    function preBuyForGroups() private 
    {          
        for (uint8 round = 1; round <= marketGeneration.buyRoundsCount(); round++)
        {
            uint256 totalRound = marketGeneration.totalContributionPerRound(round);
            uint256 buyPercent = round * 3000; // 10000 = 100%
            uint256 roundBuy = totalRound * buyPercent / 10000;

            if (roundBuy > 0)
            {   
                uint256 eliteBalance = eliteToken.balanceOf(address(this));
                uint256 amount = roundBuy > eliteBalance ? eliteBalance : roundBuy;      
                uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amount, 0, eliteRootedPath(), address(this), block.timestamp);
                totalRootedTokenBoughtPerRound[round] = amounts[1];
            }            
        }
    }

    function createRootedBaseLiquidity() private
    {
        uint256 elitePerLpToken = eliteToken.balanceOf(address(rootedEliteLP)).mul(1e18).div(rootedEliteLP.totalSupply());
        uint256 lpAmountToRemove = baseToken.balanceOf(address(eliteToken)).mul(1e18).div(elitePerLpToken);
        
        (uint256 eliteAmount, uint256 rootedAmount) = uniswapV2Router.removeLiquidity(address(eliteToken), address(rootedToken), lpAmountToRemove, 0, 0, address(this), block.timestamp);
        
        uint256 baseInElite = baseToken.balanceOf(address(eliteToken));
        uint256 baseAmount = eliteAmount > baseInElite ? baseInElite : eliteAmount;       
        
        eliteToken.withdrawTokens(baseAmount);
        uniswapV2Router.addLiquidity(address(baseToken), address(rootedToken), baseAmount, rootedAmount, 0, 0, address(this), block.timestamp);

        rootedBaseLP.transfer(devAddress, rootedBaseLP.balanceOf(address(this)));
        rootedEliteLP.transfer(devAddress, rootedEliteLP.balanceOf(address(this)));
    }

    function eliteRootedPath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(eliteToken);
        path[1] = address(rootedToken);
        return path;
    }

    function rootedElitePath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(eliteToken);
        return path;
    }
    
    function getTotalOwed(address account) private view returns (uint256)
    {
        uint256 total;

        for (uint8 round = 1; round <= marketGeneration.buyRoundsCount(); round++)
        {
            uint256 contribution = marketGeneration.contributionPerRound(account, round);

            if (contribution > 0)
            {
                uint256 totalRound = marketGeneration.totalContributionPerRound(round);
                uint256 share = contribution.mul(totalRootedTokenBoughtPerRound[round]) / totalRound;
                total = total + share;
            }
        }
        
        return total;
    }

    function claim(address account) public override 
    {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        if (totalOwed[account] == 0)
        {
            totalOwed[account] = getTotalOwed(account);
        }

        uint256 share = totalOwed[account];
        uint256 endTime = vestingPeriodEndTime > block.timestamp ? block.timestamp : vestingPeriodEndTime;

        require (claimTime[account] < endTime, "Already claimed");

        uint256 claimStartTime = claimTime[account] == 0 ? vestingPeriodStartTime : claimTime[account];
        share = (endTime.sub(claimStartTime)).mul(share).div(vestingDuration);
        claimTime[account] = block.timestamp;
        rootedToken.transfer(account, share);
    }

    function claimReferralRewards(address account, uint256 referralShare) public override 
    {
        require (distributionComplete, "Distribution is not completed");
        require (msg.sender == address(marketGeneration), "Unauthorized");

        uint256 share = referralShare.mul(totalBoughtForReferrals).div(marketGeneration.totalReferralPoints());
        rootedToken.transfer(account, share);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return block.timestamp > recoveryDate || token != rootedToken;
    }
}