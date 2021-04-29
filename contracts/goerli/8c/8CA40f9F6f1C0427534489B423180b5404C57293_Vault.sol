/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public  onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

contract Vault is Context, Ownable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint256 constant internal DISTRIBUTION_MULTIPLIER = 2 ** 64;

    address public farm;

    mapping(address => uint) public stakeValue;
    mapping(address => int) public stakerPayouts;

    uint public totalDistributions;
    uint public totalStaked;
    uint public totalStakers;
    uint public profitPerShare;
    uint private emptyStakeTokens; //These are eth given to the contract when there are no stakers.

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
    
    modifier onlyFarm {
        require(msg.sender == farm, "Only Farm");
        _;
    }

    constructor(address _farm) public {
        farm = _farm;
    }

    function initialize() external onlyFarm {
        startTime = now;
    }

    function stake(address account, uint amount) public whenStakingActive onlyFarm {
        if (stakeValue[account] == 0) totalStakers = totalStakers.add(1);
        _addStake(account, amount);
        emit OnStake(account, amount);
    }

    function unstake(address account, uint amount) external whenStakingActive onlyFarm {
        // if rounding errors occur
        if(amount > stakeValue[account]){
            amount = stakeValue[account];
        }
        // Update staker's history
        _updateCheckpointValueAtNow(
        stakeValueHistory[account],
        stakeValue[account],
        stakeValue[account].sub(amount)
        );

        // Update total staked history
        _updateCheckpointValueAtNow(
        totalStakedHistory,
        totalStaked,
        totalStaked.sub(amount)
        );
        
        //must withdraw all dividends, to prevent overflows
        withdraw(account,dividendsOf(account));
        if (stakeValue[account] == amount) totalStakers = totalStakers.sub(1);
        totalStaked = totalStaked.sub(amount);
        stakeValue[account] = stakeValue[account].sub(amount);

        stakerPayouts[account] = uintToInt(profitPerShare.mul(stakeValue[account]));
        
        emit OnUnstake(account, amount);
    }

    function withdrawEarnings() external {
         withdraw(msg.sender,dividendsOf(msg.sender));
    }

    function withdraw(address account, uint amount) private whenStakingActive {
        require(dividendsOf(account) >= amount, "Invalid withdraw.");
        stakerPayouts[account] = stakerPayouts[account] + uintToInt(amount.mul(DISTRIBUTION_MULTIPLIER));
        address(uint160(account)).transfer(amount);
        emit OnWithdraw(account, amount);
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

    function _addStake(address account, uint _amount) internal {
        // Update staker's history
        _updateCheckpointValueAtNow(
        stakeValueHistory[account],
        stakeValue[account],
        stakeValue[account].add(_amount)
        );

        // Update total staked history
        _updateCheckpointValueAtNow(
        totalStakedHistory,
        totalStaked,
        totalStaked.add(_amount)
        );

        totalStaked = totalStaked.add(_amount);
        stakeValue[account] = stakeValue[account].add(_amount);
        
        uint payout = profitPerShare.mul(_amount);
        stakerPayouts[account] = stakerPayouts[account] + uintToInt(payout);
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
      Checkpoint storage genesis = checkpoints[checkpoints.length++];
      genesis.fromBlock = uint128(block.number - 1);
      genesis.value = uint128(_oldValue);
    }

    if (checkpoints[checkpoints.length - 1].fromBlock < block.number) {
      Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
      newCheckPoint.fromBlock = uint128(block.number);
      newCheckPoint.value = uint128(_value);
    } else {
      Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
      oldCheckPoint.value = uint128(_value);
    }
  }
  
  function getUserInfo(address account) external view
    returns(uint vaultShares, uint bnbEarned, uint totalShareHolders, uint totalShares, uint bnbDistributed) {
      vaultShares = stakeValue[account];
      bnbEarned = dividendsOf(account);
      totalShareHolders = totalStakers;
      totalShares = totalStaked;
      bnbDistributed = totalDistributions;
  }
  
}