// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;

import "./LPTokenWrapper.sol";
import "./IDung.sol";

contract MegadungCompost is LPTokenWrapper, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IDung;

    IDung public dung;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Harvested(address indexed user);

    constructor (IDung _dung, IUniswapV2Pair _lptoken)
        LPTokenWrapper(_lptoken)
    {
        dung  = _dung;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(1e18)
                .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public {
        _getReward();
        emit Harvested(msg.sender);
    }

    function _getReward() internal updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            dung.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward, uint256 duration)
        external
        onlyOwner
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    /**
     * @dev returns calculated APY in current moment
     *
     * To get Human readable percent - divide result by 100.
     * APY means how much DUNG you can earn, if you will stake
     * LP tokens with total price of 1 DUNG if compost duration
     * will be 1 year and there will no changes in DUNG price
     * and staked LP token count.
    */
    function apy() external view returns (uint) {

        if (periodFinish < block.timestamp) {
            // time is finished - no earnings
            return 0;
        }

        uint stakedLP = totalSupply();
        if (stakedLP == 0) {
            // no staked tokens - infinite APY
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }

        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = lptoken.getReserves();
        uint256 totalSupplyLP = lptoken.totalSupply();

        uint DungPerLP; // 1 LP price in ETH currency
        if (lptoken.token0() == address(dung)) {
            DungPerLP = 2 ether * (uint256)(reserve0)/totalSupplyLP; // DUNG value + ETH value in 1 LP
        } else {
            DungPerLP = 2 ether * (uint256)(reserve1)/totalSupplyLP; // DUNG value + ETH value in 1 LP
        }

        uint stakedLpInDung = stakedLP*DungPerLP / 1 ether; // total staked LP token count in DUNG currency

        uint earnedDungPerYear = rewardRate * 365 days; // total pool earns per year
        uint earnerDungPerYearForStakedDung = 10000 * earnedDungPerYear / stakedLpInDung;

        return earnerDungPerYearForStakedDung;
    }

}