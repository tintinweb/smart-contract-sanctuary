/**
 *Submitted for verification at Etherscan.io on 2020-07-26
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ICurve {
    function get_virtual_price() external view returns (uint256 out);
    function underlying_coins(int128 tokenId) external view returns (address token);
    function calc_token_amount(uint256[4] calldata amounts, bool deposit) external view returns (uint256 amount);
    function get_dy(int128 sellTokenId, int128 buyTokenId, uint256 sellTokenAmt) external view returns (uint256 buyTokenAmt);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
}

interface IStakingRewards {
  function balanceOf(address) external view returns (uint256);
  function earned(address) external view returns (uint256);
}

contract Resolver {
    function getPosition(
        address user,
        TokenInterface curveToken,
        IStakingRewards stakingPool,
        TokenInterface rewardToken
    ) public view returns (
        uint userBal,
        uint rewardsEarned,
        uint stakedBal,
        uint rewardBal
    ) {
        userBal = curveToken.balanceOf(user);
        // Staking Details.
        (stakedBal, rewardsEarned, rewardBal) = getStakingPosition(user, stakingPool, rewardToken);
    }

    function getStakingPosition(address user, IStakingRewards stakingPool, TokenInterface rewardToken) public view returns (
        uint stakedBal,
        uint rewardsEarned,
        uint rewardBal
    ) {
        stakedBal = stakingPool.balanceOf(user);
        rewardsEarned = stakingPool.earned(user);
        rewardBal = rewardToken.balanceOf(user);
    }

    struct StatsData {
        uint userBal;
        uint rewardsEarned;
        uint stakedBal;
        uint rewardBal;
    }
    function getPositions(
        address[] memory users,
        TokenInterface curveToken,
        IStakingRewards stakingPool,
        TokenInterface rewardToken
    ) public view returns (StatsData[] memory) {
        StatsData[] memory data = new StatsData[](users.length);
        for (uint i = 0; i < users.length; i++) {
            (
                uint userBal,
                uint rewardsEarned,
                uint stakedBal,
                uint rewardBal
            ) = getPosition(users[i], curveToken, stakingPool, rewardToken);
            data[i] = StatsData(
                userBal,
                rewardsEarned,
                stakedBal,
                rewardBal
            );
        }
        return data;
    }

    function getPrice(ICurve curvePool) public view returns(uint price) {
        return curvePool.get_virtual_price();
    }
}