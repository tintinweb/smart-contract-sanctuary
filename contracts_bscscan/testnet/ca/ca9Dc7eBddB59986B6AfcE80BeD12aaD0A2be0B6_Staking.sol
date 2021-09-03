// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

library BasisPoints {
    using SafeMath for uint;

    uint constant private BASIS_POINTS = 10000;

    function mulBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint amt, uint bp) internal pure returns (uint) {
        require(bp > 0, "Cannot divide by zero.");
        if (amt == 0) return 0;
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint amt, uint bp) internal pure returns (uint) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

contract Staking is Context, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint constant internal DISTRIBUTION_MULTIPLIER = 2 ** 64;
    uint public tempLock = 10; // A short period of lock to prevent flash loan attacks
    IERC20 private token;

    mapping(address => uint) public stakeValue;
    mapping(address => int) public stakerPayouts;
    mapping(address => uint) private stakeTimes;
    uint public totalDistributions;
    uint public totalStaked;
    uint public totalStakers;
    uint public profitPerShare;
    uint private emptyStakeTokens; //These are ftm given to the contract when there are no stakers.

    uint public startTime;

    event OnDistribute(address sender, uint amountSent);
    event OnStake(address sender, uint amount);
    event OnUnstake(address sender, uint amount);
    event OnReinvest(address sender, uint amount);
    event OnWithdraw(address sender, uint amount);

    struct Checkpoint {
      uint128 fromBlock;
      uint128 value;
    }

    mapping(address => Checkpoint[]) internal stakeValueHistory;

    Checkpoint[] internal totalStakedHistory;

    modifier whenStakingActive {
        require(startTime != 0 && now > startTime, "Staking not yet started.");
        _;
    }

    constructor(IERC20 _token) public {
        token = _token;
    }

    function setStartTime(uint _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function stake(uint amount) public whenStakingActive {
        require(token.balanceOf(msg.sender) >= amount, "Cannot stake more Tokens than you hold unstaked.");
        require(block.number >= stakeTimes[msg.sender] + tempLock, "Can't stake or unstake multiple times in 5 blocks!");
        if (stakeValue[msg.sender] == 0) totalStakers = totalStakers.add(1);
        _addStake(amount);
        stakeTimes[msg.sender] = block.number;
        require(token.transferFrom(msg.sender, address(this), amount), "Stake failed due to failed transfer.");
        emit OnStake(msg.sender, amount);
    }

    function unstake(uint amount) external {
        require(stakeValue[msg.sender] >= amount, "Cannot unstake more Token than you have staked.");
        require(block.number >= stakeTimes[msg.sender] + tempLock, "Can't stake or unstake multiple times in 5 blocks!");
        stakeTimes[msg.sender] = block.number;
        // Update staker's history
        _updateCheckpointValueAtNow(
        stakeValueHistory[msg.sender],
        stakeValue[msg.sender],
        stakeValue[msg.sender].sub(amount)
        );

        // Update total staked history
        _updateCheckpointValueAtNow(
        totalStakedHistory,
        totalStaked,
        totalStaked.sub(amount)
        );
        
        //must withdraw all dividends, to prevent overflows
        withdraw(dividendsOf(msg.sender));
        if (stakeValue[msg.sender] == amount) totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].sub(amount);

        stakerPayouts[msg.sender] = uintToInt(profitPerShare.mul(stakeValue[msg.sender]));
        
        require(token.transferFrom(address(this), msg.sender, amount), "Unstake failed due to failed transfer.");
        emit OnUnstake(msg.sender, amount);
    }

    function withdraw(uint amount) public whenStakingActive {
        require(dividendsOf(msg.sender) >= amount, "Cannot withdraw more dividends than you have earned.");
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + uintToInt(amount.mul(DISTRIBUTION_MULTIPLIER));
        msg.sender.transfer(amount);
        emit OnWithdraw(msg.sender, amount);
    }

    function distribute() external payable {
        uint amount = msg.value;
        if(amount > 0){
            totalDistributions = totalDistributions.add(amount);
            _increaseProfitPerShare(amount);
            emit OnDistribute(msg.sender, amount);
        }
    }

    function dividendsOf(address staker) public view returns (uint) {
        int divPayout = uintToInt(profitPerShare.mul(stakeValue[staker]));
        require(divPayout >= stakerPayouts[staker], "dividend calc overflow");
        return uint(divPayout - stakerPayouts[staker])
            .div(DISTRIBUTION_MULTIPLIER);
    }

    function totalStakedAt(uint _blockNumber) public view returns(uint) {
        // If we haven't initialized history yet
        if (totalStakedHistory.length == 0) {
            // Use the existing value
            return totalStaked;
        } else {
            // Binary search history for the proper staked amount
            return _getCheckpointValueAt(
                totalStakedHistory,
                _blockNumber
            );
        }
    }

    function stakeValueAt(address _owner, uint _blockNumber) public view returns (uint) {
        // If we haven't initialized history yet
        if (stakeValueHistory[_owner].length == 0) {
            // Use the existing latest value
            return stakeValue[_owner];
        } else {
            // Binary search history for the proper staked amount
            return _getCheckpointValueAt(stakeValueHistory[_owner], _blockNumber);
        }
    }

    function uintToInt(uint val) internal pure returns (int) {
        if (val >= uint(-1).div(2)) {
            require(false, "Overflow. Cannot convert uint to int.");
        } else {
            return int(val);
        }
    }

    function _addStake(uint _amount) internal {
        // Update staker's history
        _updateCheckpointValueAtNow(
        stakeValueHistory[msg.sender],
        stakeValue[msg.sender],
        stakeValue[msg.sender].add(_amount)
        );

        // Update total staked history
        _updateCheckpointValueAtNow(
        totalStakedHistory,
        totalStaked,
        totalStaked.add(_amount)
        );

        totalStaked = totalStaked.add(_amount);
        stakeValue[msg.sender] = stakeValue[msg.sender].add(_amount);
        
        uint payout = profitPerShare.mul(_amount);
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + uintToInt(payout);
    }

    function _increaseProfitPerShare(uint amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount = amount.add(emptyStakeTokens);
                emptyStakeTokens = 0;
            }
            profitPerShare = profitPerShare.add(amount.mul(DISTRIBUTION_MULTIPLIER).div(totalStaked));
        } else {
            emptyStakeTokens = emptyStakeTokens.add(amount);
        }
    }

    function _getCheckpointValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint) {
    // This case should be handled by caller
    if (checkpoints.length == 0)
      return 0;

    // Use the latest checkpoint
    if (_block >= checkpoints[checkpoints.length-1].fromBlock)
      return checkpoints[checkpoints.length-1].value;

    // Use the oldest checkpoint
    if (_block < checkpoints[0].fromBlock)
      return checkpoints[0].value;

    // Binary search of the value in the array
    uint min = 0;
    uint max = checkpoints.length-1;
    while (max > min) {
      uint mid = (max + min + 1) / 2;
      if (checkpoints[mid].fromBlock<=_block) {
        min = mid;
      } else {
        max = mid-1;
      }
    }
    return checkpoints[min].value;
  }

  function _updateCheckpointValueAtNow(
    Checkpoint[] storage checkpoints,
    uint _oldValue,
    uint _value
  ) internal {
    require(_value <= uint128(-1));
    require(_oldValue <= uint128(-1));

    if (checkpoints.length == 0) {
      Checkpoint storage genesis;
      genesis.fromBlock = uint128(block.number - 1);
      genesis.value = uint128(_oldValue);
      checkpoints.push(genesis);
    }

    if (checkpoints[checkpoints.length - 1].fromBlock < block.number) {
      Checkpoint storage newCheckPoint;
      newCheckPoint.fromBlock = uint128(block.number);
      newCheckPoint.value = uint128(_value);
      checkpoints.push(newCheckPoint);
    } else {
      Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
      oldCheckPoint.value = uint128(_value);
    }
  }
  
}