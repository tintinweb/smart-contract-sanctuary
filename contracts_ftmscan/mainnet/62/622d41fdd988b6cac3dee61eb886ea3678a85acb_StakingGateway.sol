/**
 *Submitted for verification at FtmScan.com on 2022-01-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}
interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
interface ICurvePool{
    function get_virtual_price() external view returns(uint);
    function calc_token_amount(uint[2] memory _amounts, bool _is_deposit) external view returns(uint);
    function balances(uint i) external view returns(uint);
    function totalSupply() external view returns (uint);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns(uint);
    function balanceOf(address account) external view returns (uint);
}
interface IStakingRewards {
    // Views

    function balanceOf(address account) external view returns (uint);

    function earned(address account) external view returns (uint);

    function getRewardForDuration() external view returns (uint);

    function lastTimeRewardApplicable() external view returns (uint);

    function rewardPerToken() external view returns (uint);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint);

    function rewardRate() external view returns(uint);

    function periodFinish() external view returns(uint);

    function rewardsDuration() external view returns(uint);

    // Mutative

    function exit() external;

    function getReward() external;

    function stake(uint amount) external;

    function withdraw(uint amount) external;
}
contract StakingGateway{
    using SafeMath for uint;
    IStakingRewards public constant stakingRewards=IStakingRewards(0x51a251e04753C4382071D9daA00fA3F165E824Fb);
    ICurvePool public constant hugsPool=ICurvePool(0xDC371bB71dE3a8E50683E7eb596690Db9D0365Cc);
    ICurvePool public constant c2pool=ICurvePool(0x27E611FD27b276ACbd5Ffd632E5eAEBEC9761E40);

    function getStakingInfo(address wallet,uint amount) external view returns(
        uint _tvl,//1e18
        uint _apr,//1e8
        uint _begin,
        uint _finish,
        uint _optimalHugsAmount,
        uint _optimalDaiAmount,
        uint _optimalUsdcAmount,
        uint _hugsWithdrawAmount,
        uint _daiWithdrawAmount,
        uint _usdcWithdrawAmount,
        uint _earnedRewardAmount
    ){
        _tvl = stakingRewards.totalSupply().mul(hugsPool.get_virtual_price()).div(1e18);
        _apr = stakingRewards.rewardRate().mul(31536000).mul(assetPrice()).div(_tvl);
        _finish = stakingRewards.periodFinish();
        _begin =_finish.sub(stakingRewards.rewardsDuration());
        (_optimalHugsAmount,_optimalDaiAmount,_optimalUsdcAmount)=calOptimal(amount);
        (_hugsWithdrawAmount,_daiWithdrawAmount,_usdcWithdrawAmount,_earnedRewardAmount)=calWithdrawAndEarned(wallet);
    }
    function calWithdrawAndEarned(address wallet) public view returns(
        uint _hugsWithdrawAmount,
        uint _daiWithdrawAmount,
        uint _usdcWithdrawAmount,
        uint _earnedRewardAmount){
        uint bal=stakingRewards.balanceOf(wallet);
        _hugsWithdrawAmount=hugsPool.calc_withdraw_one_coin(bal,0);
        uint daiusdc=hugsPool.calc_withdraw_one_coin(bal,1);
        _daiWithdrawAmount=c2pool.calc_withdraw_one_coin(daiusdc,0);
        _usdcWithdrawAmount=c2pool.calc_withdraw_one_coin(daiusdc,1);
        _earnedRewardAmount=stakingRewards.earned(wallet);
    }
    function calOptimal(uint amount) public view returns(uint _optimalHugs,uint _optimalDai,uint _optimalUsdc){
        if(amount==0)return(0,0,0);
        uint hugs=hugsPool.balances(0);//1e18
        uint daiusdc=hugsPool.balances(1);//1e18
        uint dai=daiusdc.mul(c2pool.balances(0)).div(c2pool.totalSupply());//1e18
        uint usdc=daiusdc.mul(c2pool.balances(1)).div(c2pool.totalSupply()).mul(1e12);//1e18
        uint ntotal=hugs.add(dai).add(usdc).add(amount);
        uint nhugs=ntotal.div(2);
        uint ndai=ntotal.div(4);
        //uint nusdc=ntotal.sub(nhugs).sub(ndai);
        if(nhugs>=amount.add(hugs)) _optimalHugs=amount;
        else if(nhugs<=hugs) _optimalHugs=0;
        else _optimalHugs=nhugs.sub(hugs);
        if(ndai>=amount.add(dai)) _optimalDai=amount;
        else if(ndai<=dai) _optimalDai=0;
        else _optimalDai=ndai.sub(dai);
        if(amount>=_optimalHugs.add(_optimalDai)) _optimalUsdc=amount.sub(_optimalHugs).sub(_optimalDai);
        else _optimalUsdc=0;
    }
    function calPoolToken(uint hugsAmount,uint daiAmount,uint usdcAmount) public view returns(uint poolTokenAmount){
        uint[2] memory tokens;
        tokens[0]=daiAmount;
        tokens[1]=usdcAmount;
        uint daiusdcAmount=c2pool.calc_token_amount(tokens,true);
        tokens[0]=hugsAmount;
        tokens[1]=daiusdcAmount;
        poolTokenAmount=hugsPool.calc_token_amount(tokens,true);
    }
    //percentage 1e8 100%=1=1e8
    function calBonusOrSlipage(uint hugsAmount,uint daiAmount,uint usdcAmount) external view returns(uint percentage){
        uint lpAmount=calPoolToken(hugsAmount,daiAmount,usdcAmount);
        percentage=lpAmount.mul(hugsPool.get_virtual_price()).div(1e10).div(hugsAmount.add(daiAmount).add(usdcAmount.mul(1e12)));//1e8
    }
    function assetPrice() public view returns (uint) {
        ( , int price, , , ) = AggregatorV3Interface(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc).latestRoundData();
        return uint(price);
    }
}