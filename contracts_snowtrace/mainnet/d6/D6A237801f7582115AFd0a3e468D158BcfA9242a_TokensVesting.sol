// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";

contract TokensVesting {
  using SafeMath for uint;

  struct Vesting {
    uint256 totalTokens;
    uint256 lastClaimTime;
    uint256 vestingFinishTime;
    uint256 claimedTokens;
  }

  ERC20 public voucher;
  ERC20 public token;
  uint256 public totalVestingTime; 
  uint256 public startTime;
  uint256 public exchangeRate;


  mapping(address => Vesting) public vestings;

  /**
  *@dev contructor
  *@param _voucher address of aOTWO
  *@param _token address of OTWO
  *@param _totalVestingTime length of the vesting period (7 days)
  *@param _startTime time when users can start vesting their tokens
  *@param _exchangeRate decimals difference between voucher and token
  */
  constructor(
    address _voucher,
    address _token,
    uint256 _totalVestingTime,
    uint256 _startTime,
    uint256 _exchangeRate
  ) public {
    voucher = ERC20(_voucher);
    token = ERC20(_token);
    totalVestingTime = _totalVestingTime;
    startTime = _startTime;
    exchangeRate = 10 ** _exchangeRate;
  }


  /**
  *@dev begin vesting by locking up vouchers; can only be called once per address
  */
  function beginVesting() external {
    Vesting storage userVesting = vestings[msg.sender];

    require(block.timestamp >= startTime, 'Vesting not began');
    require(userVesting.totalTokens == 0, 'Already vesting');

    uint256 totalVoucher = voucher.balanceOf(msg.sender);
    voucher.transferFrom(msg.sender, address(this), totalVoucher);
    
    vestings[msg.sender] = Vesting({
        totalTokens: totalVoucher,
        lastClaimTime: block.timestamp,
        vestingFinishTime: block.timestamp.add(totalVestingTime),
        claimedTokens: 0
    });

  }

  /**
  *@dev claim unlocked tokens
  */
  function claimTokens() external {
    Vesting storage userVesting = vestings[msg.sender];

    require(userVesting.totalTokens > 0, 'Nothing to vest');

    if (userVesting.lastClaimTime <= userVesting.vestingFinishTime) {
        uint256 tokensRedeemable = redeemable(msg.sender);
        token.transfer(msg.sender, tokensRedeemable);
        userVesting.lastClaimTime = block.timestamp;
        userVesting.claimedTokens = tokensRedeemable.add(userVesting.claimedTokens);
    }
  }

  /**
  *@dev return number of tokens unlocked
  */
  function redeemable(address receiver) public view returns(uint256) {
    Vesting memory userVesting = vestings[receiver];

    // // All tokens released
    if (Math.min(block.timestamp, userVesting.vestingFinishTime) < userVesting.lastClaimTime) {
      return 0;
    }

    return userVesting.totalTokens.mul(
        Math.min(block.timestamp, userVesting.vestingFinishTime).sub(userVesting.lastClaimTime)
        .mul(1e10)
        .div(totalVestingTime)
    ).div(1e10)
    .div(exchangeRate);
  }
}