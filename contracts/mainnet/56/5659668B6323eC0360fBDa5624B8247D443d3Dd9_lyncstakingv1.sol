// SPDX-License-Identifier: MIT

    /**
     * LYNC Network
     * https://lync.network
     *
     * Additional details for contract and wallet information:
     * https://lync.network/tracking/
     *
     * The cryptocurrency network designed for passive token rewards for its community.
     */

pragma solidity ^0.7.0;

import "./lynctoken.sol";

contract LYNCStakingV1 {

  //Enable SafeMath
  using SafeMath for uint256;

    address public owner;
    address public contractAddress;
    uint256 public totalRewards = 0;
    uint256 public totalRewardsClaimed = 0;
    uint256 public totalStakedV1 = 0;
    uint256 public oneDay = 86400;          // in seconds
    uint256 public SCALAR = 1e18;           // multiplier
    uint256 public minimumTokenStake = 98;  // takes into account transfer fee
    uint256 public endOfStakeFee = 4;       // 4% including 1% tx fee = approx 5%

    LYNCToken public tokenContract;

    //Events
	event Stake(address _from, uint256 tokens);
	event Unstake(address _to, uint256 tokens);
	event UnstakeFee(address _to, uint256 tokens);
	event CollectRewards(address _to, uint256 tokens);

	//User data
	struct Staker {
		uint256 staked;
		uint256 poolAtLastClaim;
		uint256 userTimeStamp;
	}

    //Mappings
    mapping(address => Staker) stakers;

    //On deployment
    constructor(LYNCToken _tokenContract) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        contractAddress = address(this);
    }

    //MulDiv functions : source https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    function mulDiv(uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod(x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }

    //Required for MulDiv
    function fullMul(uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod(x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }

    //Return current reward pool unclaimed
    function rewardPoolBalance() public view returns(uint256) {
        return tokenContract.balanceOf(address(this)).sub(totalStakedV1);
    }

    //Return staker information
    function stakerInformation(address _stakerAddress) public view returns(uint256, uint256, uint256) {
        return (stakers[_stakerAddress].staked, stakers[_stakerAddress].poolAtLastClaim, stakers[_stakerAddress].userTimeStamp);
    }

    //Stake tokens
    function stakeTokens(uint256 _numberOfTokens) external returns (bool) {

        //Check if user is already staking
        if(stakers[msg.sender].staked == 0) {

            //Require minimum stake
            require(_numberOfTokens > (minimumTokenStake * SCALAR), "Not enough tokens to start staking");

            //Transfer tokens and update data
            require(tokenContract.transferFrom(msg.sender, address(this), _numberOfTokens));
            stakers[msg.sender].poolAtLastClaim = totalRewards;
            stakers[msg.sender].userTimeStamp = block.timestamp;
        } else {

            //Transfer tokens
            require(tokenContract.transferFrom(msg.sender, address(this), _numberOfTokens));
        }

        //Update staking totals
        uint256 _feeAmount = (_numberOfTokens.mul(tokenContract.feePercent())).div(100);
        uint256 _stakedAfterFee = _numberOfTokens.sub(_feeAmount);

        //Update data
        stakers[msg.sender].staked = (stakers[msg.sender].staked).add(_stakedAfterFee);
        totalStakedV1 = totalStakedV1.add(_stakedAfterFee);
        totalRewards = rewardPoolBalance().add(totalRewardsClaimed);

        emit Stake(msg.sender, _numberOfTokens);
        return true;
    }

    //Unstake tokens
    function unstakeTokens() external returns (bool) {

        //Minus 4% fee for unstaking
        uint256 _stakedTokens = stakers[msg.sender].staked;
        uint256 _feeAmount = (_stakedTokens.mul(endOfStakeFee)).div(100);
        uint256 _unstakeTokens = (stakers[msg.sender].staked).sub(_feeAmount);

        //Send stakers tokens and remove from total staked
        require(tokenContract.transfer(msg.sender, _unstakeTokens));
        totalStakedV1 = totalStakedV1.sub(_stakedTokens);

        //Update data
        stakers[msg.sender].staked = 0;
        stakers[msg.sender].poolAtLastClaim = 0;
        stakers[msg.sender].userTimeStamp = 0;
        totalRewards = rewardPoolBalance().add(totalRewardsClaimed);

        emit Unstake(msg.sender, _unstakeTokens);
        emit UnstakeFee(msg.sender, _feeAmount);
        return true;
    }

    //Claim current token rewards
    function claimRewards() external returns (bool) {

        totalRewards = rewardPoolBalance().add(totalRewardsClaimed);
        require(stakers[msg.sender].staked > 0, "You do not have any tokens staked");
        require(block.timestamp > (stakers[msg.sender].userTimeStamp + oneDay), "You can only claim 24 hours after staking and once every 24 hours");

        //Calculated user share of reward pool since last claim
        uint256 _poolSinceLastClaim = totalRewards.sub(stakers[msg.sender].poolAtLastClaim);
        uint256 _rewardPercent = mulDiv(stakers[msg.sender].staked, 10000, totalStakedV1);
        uint256 _rewardToClaim = mulDiv(_poolSinceLastClaim, _rewardPercent, 10000);

        //Send tokens
        require(tokenContract.transfer(msg.sender, _rewardToClaim));

        //Update data
        stakers[msg.sender].poolAtLastClaim = totalRewards;
        stakers[msg.sender].userTimeStamp = block.timestamp;
        totalRewardsClaimed = totalRewardsClaimed.add(_rewardToClaim);
        totalRewards = rewardPoolBalance().add(totalRewardsClaimed);

        emit CollectRewards(msg.sender, _rewardToClaim);
        return true;
    }

    //Update the minimum tokens to start staking
    function updateStakeMinimum(uint256 _minimumTokenStake) public onlyOwner {
        minimumTokenStake = _minimumTokenStake;
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only current owner can call this function");
        _;
    }
}
