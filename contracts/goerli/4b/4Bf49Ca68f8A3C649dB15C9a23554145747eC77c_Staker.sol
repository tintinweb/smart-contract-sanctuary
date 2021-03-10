// Contract to define tokens for rewards and staking

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";

contract RewardToken {

    using SafeMath for uint256;

    // Token definition
    string public name = "Preston's Token";
    string public symbol = "PRES";
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Direct transfer from msg.sender
    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance.");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    // assign allowance to a delegate
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    // delegate transfer.
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    // mint tokens
    function _mint(address to, uint256 value) internal returns (bool success) {
        require(msg.sender != address(0), "Invalid address");
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
        return true;
    }

    // burn tokens
    function _burn(address from, uint256 value) internal returns (bool success) {
        require(msg.sender != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance to burn");
        totalSupply = totalSupply.sub(value);
        balanceOf[from] = balanceOf[from].sub(value);
        emit Transfer(from, address(0), value);
        return true;
    }
}

// Contract to possess staked tokens and to distribute rewards.

pragma solidity ^0.6.0;

import "./libs/SafeMath.sol";
import "./RewardToken.sol";

contract Staker is RewardToken {

    using SafeMath for uint256;

    address public owner;
    uint256 public stake_ids;
    mapping(uint256 => StakeProfile) public stakers; // keeps track of stakers.
    mapping(address => uint256) public addrToId; // associates IDs with staker address.
    uint256 public totalRewardRate = 100; // a total of 100 rewards generated per minute to be distributed proportionally to all stakers.
    uint256 private totalStake;

    event Staked(address user, uint256 amount);
    event Unstaked(address user, uint256 amount);

    /**
    * @dev Struct to keep record of staker profile.
    */
    struct StakeProfile {
        uint256 id;
        uint256 staked_amount; // the amount of token locked for staking.
        uint256 reward_earned;
        uint256 starting_date;
        address addr;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Function to calculate the reward.
    */
    function calculateReward(uint256 id, uint256 durationInMin) public view returns(uint256 reward) {
        uint totalReward = totalRewardRate.mul(durationInMin);
        uint staked = stakers[id].staked_amount;
        // solidity does not support floating numbers.
        uint percent = (staked.mul(100)).div(totalStake);
        reward = (totalReward.mul(percent)).div(100);
        return reward;
    }

    /**
    * @dev updates rewards. (Does not mint new tokens until withdrawal)
    */
    modifier updateReward(uint256 id) {
        require(stakers[id].staked_amount > 0, "Insufficient staked amount.");
        uint duration = now.sub(stakers[id].starting_date);
        uint durationInMin = duration.div(60);
        stakers[id].reward_earned = calculateReward(id, durationInMin);
        _;
    }

    /**
    * @dev Function to provide ICO/AirDrop capability for owners.
    */
    function airdrop(address recipient, uint256 amount) public returns(bool success) {
        require(msg.sender == owner, "Not the owner");
        _mint(recipient, amount);
        return true;
    }

    /**
    * @dev Function to allow stakers to deposit tokens to stake, requires a minimum of 100 tokens.
    * @return Staker ID.
    */
    function deposit(uint256 amount) public returns(uint256) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance.");
        require(amount >= 100, "Amount is below the minimum stake requirement.");
        require((msg.sender != owner) && (msg.sender != address(0)), "Owner or invaid address."); // TEMP

        StakeProfile storage staker = stakers[addrToId[msg.sender]];
        _burn(msg.sender, amount);

        totalStake = totalStake.add(amount);

        emit Staked(msg.sender, amount);

        // check if the profile already exists.
        if (staker.id > 0) {
            staker.staked_amount = staker.staked_amount.add(amount);
            return staker.id;
        }
        else {
            stake_ids = stake_ids.add(1);
            StakeProfile memory newStaker = StakeProfile(stake_ids, amount, 0, now, msg.sender);
            addrToId[msg.sender] = stake_ids;
            stakers[stake_ids] = newStaker;
            return stake_ids;
        }
    }

    /**
     * @dev Function to withdraw.
     */
    function withdraw(uint256 id) public updateReward(id) returns (bool success) {
        require(msg.sender == stakers[id].addr, "Not the staker, unauthorized caller.");
        require(stakers[id].reward_earned > 0 || stakers[id].staked_amount >= 100, "Insufficient gains.");
        // mint new tokens for rewards earned.
        if (stakers[id].reward_earned > 0) {
            _mint(stakers[id].addr, stakers[id].reward_earned);
        }
        // transfer stake.
        _mint(stakers[id].addr, stakers[id].staked_amount);

        uint amount = stakers[id].reward_earned.add(stakers[id].staked_amount);
        emit Unstaked(stakers[id].addr, amount);

        delete addrToId[stakers[id].addr];
        delete stakers[id];

        return true;
    }
}

pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}