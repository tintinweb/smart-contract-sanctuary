// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./IERC20.sol";

contract LP_Staking2 {
  // balances are stored as uint240 so the structs take up one storage
  // slot instead of two
  struct User {
    bool has_prerewards;
    uint8 epoch_start;
    uint240 balance;
  }

  struct Epoch {
    uint8 epoch_number;
    uint240 balance;
  }

  struct Prereward {
    address user;
    uint240 amount;
  }

  uint256 public immutable staking_start;
  uint256 public immutable staking_end;

  uint256 public immutable epoch_seconds;
  uint8 public immutable epoch_count;

  uint256 public immutable epoch_reward;

  IERC20 public immutable trusted_lp_token;
  IERC20 public immutable trusted_reward_token;

  Epoch[] public epochs;
  mapping (address => User) public users;

  mapping (address => uint240) public prerewards;

  // Precision here is arbitrary atm. Needs to be worked out based on
  // max supply of LP tokens. Read this as '24 bits', as we use bit shift
  // to move the precision up and down in the rewards calculation
  uint256 constant PRECISION = 24;

  address controller;

  constructor (
    address lp_token_address,
    address reward_token_address,
    uint8 _epoch_count,
    uint256 _epoch_seconds,
    uint256 _epoch_reward
  ) {
    staking_start = block.timestamp;
    staking_end = block.timestamp + _epoch_count * _epoch_seconds;

    epoch_count = _epoch_count;
    epoch_seconds = _epoch_seconds;
    epoch_reward = _epoch_reward;

    trusted_lp_token = IERC20(lp_token_address);
    trusted_reward_token = IERC20(reward_token_address);

    // We add the first epoch as our base-case.
    // I believe this could be optimised to just manipulate the length
    // of epochs
    epochs.push(Epoch(0, 0));

    controller = msg.sender;
  }

  function get_current_epoch_number () public view returns (uint8) {
    if (block.timestamp > staking_end) return epoch_count;

    return uint8((block.timestamp - staking_start) / epoch_seconds);
  }

  function total_staked_for_user (address user) external view returns (uint256) {
    return uint256(users[user].balance);
  }

  function get_available_reward (address user) external view returns (uint256) {
    return _reward_balance(user);
  }

  function total_staked () external view returns (uint256) {
    return uint256(epochs[epochs.length - 1].balance);
  }

  function init_prerewards (Prereward[] calldata arr) external only_controller {
    for (uint idx = 0; idx < arr.length; idx++) {
      Prereward calldata pr = arr[idx];

      users[pr.user].has_prerewards = true;
      prerewards[pr.user] = pr.amount;
    }
  }

  function stake (uint240 value) external returns (bool) {
    require(value > 0);
    User storage user = users[msg.sender];
    require(user.balance == 0);

    uint8 epoch_number = get_current_epoch_number();
    require(epoch_number < epoch_count);

    Epoch storage latest_epoch = epochs[epochs.length - 1];
    // Check for overflow before we mutate anything
    require(type(uint248).max - latest_epoch.balance >= value);

    require(trusted_lp_token.transferFrom(msg.sender, address(this), value));

    user.epoch_start = epoch_number;
    user.balance = value;

    if (latest_epoch.epoch_number == epoch_number) {
      latest_epoch.balance += value;
    } else {
      epochs.push(Epoch(epoch_number, latest_epoch.balance + value));
    }

    return true;
  }

  function unstake () external returns (bool) {
    User storage user = users[msg.sender];
    uint240 balance = user.balance;
    require(balance > 0);
    uint256 reward = _reward_balance(msg.sender);

    // This is the tricky part about working with epochs, so please read
    // carefully. We have to remember that the array of epochs is always
    // in order of increasing epoch_number, but can have gaps between
    // epochs, eg: [e0, e2, e3, e7]. Epochs are only inserted when someone
    // stakes or unstakes, which allows us to make some assumptions below.
    // From hereon forward, withdrawing rewards is the same as staking, as
    // that operation essentially moves up the time a user started staking to
    // the previous epoch.
    //
    // When looking at eg. e0, the balance is actually the total balance
    // staked for the next epoch, as you will only get rewarded for full
    // epochs. When the epoch counter increments (by virtue of time),
    // the latest epoch is simply "drawn forward", as the balance must
    // have been the same until someone decided to either stake or
    // unstake, at which point a new epoch struct must be created and
    // the balance updated.
    uint8 epoch_number = get_current_epoch_number();
    uint256 epoch_len = epochs.length;
    Epoch storage latest_epoch = epochs[epoch_len - 1];

    // Rewards are paid for full epochs which have been staked, which gives a
    // couple of scenarios:
    //
    // 1. User stakes in e0 and unstakes in e0, giving no reward
    // 2. User stakes in e0 and unstakes in e1, giving no reward
    // 3. user stakes in e0 and unstakes in eN, giving rewards for e1 to e(N-1)
    //    both of those epochs incluseive.
    //
    // This means that unless we are in case 1. above, we have to change the
    // balance of two epochs for the ratio of user balance to total balance, to
    // be fair. This is a little subtle, but we need this as we draw balances
    // forward into epochs that have not vested yet, however we do not want to
    // compensate someone for joining the end of e0 and leaving at the start of
    // e1

    // When unstaking we have two overarching cases to cover:
    //  1. The user staked and unstaked in the latest epoch
    //  2. The user staked in a previous epoch than the latest

    // Here we cover case 1. which is the simplest, since the epoch that
    // the user staked in, is also the one they unstake in. `epoch_start`
    // can be set by `stake` and `withdraw_rewards`, however the latter
    // will always set it in the past, hence the strict equality can
    // never be true in that case. Therefore we know that the two can
    // only be equal, if in fact the user staked and unstaked in the
    // same epoch
    if (epoch_number == user.epoch_start) {
      latest_epoch.balance -= balance;
    }
    // Now we get to case 2. where the user staked in any previous epoch
    // and we have fix more than one epoch balance
    else {

      // Let's explain the situation. We can have a couple of complicated
      // cases here, but remember that epochs are always in order.
      //
      // 1. Zero epochs have elapsed since someone either staked or unstaked
      // 2. One epoch has elapsed since someone either staked or unstaked
      // 3. Two or more epochs have elapsed since someone staked or unstaked


      // We're at the latest epoch
      if (latest_epoch.epoch_number == epoch_number) {
        latest_epoch.balance -= balance;

        // We need to look at the previous epoch
        // There must be at least two epochs, since the latest epoch
        // is not the one the user staked in, but the earlies epoch someone could
        // stake is e0, so we must have at least e0 and e1 (or any other combination)
        Epoch storage previous_epoch = epochs[epoch_len - 2];
        // We were lucky and they were in sequence
        if (previous_epoch.epoch_number == epoch_number - 1) {
          previous_epoch.balance -= balance;
        }
        // We have to duplicate the latest epoch and fix it up
        else {
          // This part is very subtle
          // We essentially clone the latest epoch by pushing it on
          epochs.push(latest_epoch);
          // then decrement the 2nd to last epoch to have two in sequence
          latest_epoch.epoch_number--;
          // We do not need to decrement the balance, as that was done
          // before duplicating

          // Example:
          // We have: [..., e6, e8]
          // We then push: [..., e6, e8, e8]
          // And then decr: [..., e6, e8--, e8]
          // To get: [..., e6, e7, e8]
        }
      }
      // We're just one short
      else if (latest_epoch.epoch_number == epoch_number - 1) {
        // Again we can duplicate the epoch after decrementing the balance
        latest_epoch.balance -= balance;
        epochs.push(Epoch(epoch_number, latest_epoch.balance));
      }
      // We're way in the past and can add both new epochs
      else {
        epochs.push(Epoch(epoch_number - 1, latest_epoch.balance - balance));
        epochs.push(Epoch(epoch_number, latest_epoch.balance - balance));
      }
    }

    // Deleting the user gives a gas refund, and there's no reason to keep their
    // state
    if (user.has_prerewards) {
      delete prerewards[msg.sender];
    }

    delete users[msg.sender];

    require(trusted_lp_token.transfer(msg.sender, balance));
    require(trusted_reward_token.transfer(msg.sender, reward));
    return true;
  }

  function withdraw_rewards () external returns (bool) {
    uint256 reward = _reward_balance(msg.sender);
    if (reward == 0) return true;

    uint8 epoch_number = get_current_epoch_number();
    User storage user = users[msg.sender];
    // First condition here ensures we don't underflow, as the user may
    // be able to withdraw rewards that come from prerewards. 2nd condition
    // indirectly checks that the rewards were in fact prerewards
    if (epoch_number > 0 && user.balance > 0) {
      user.epoch_start = epoch_number - 1;
    }

    if (user.has_prerewards) {
      user.has_prerewards = false;
      delete prerewards[msg.sender];
    }

    require(trusted_reward_token.transfer(msg.sender, reward));
    return true;
  }

  function _reward_balance (address _user) internal view returns (uint256) {
    uint256 staking_reward = 0;
    User memory user = users[_user];

    if (user.has_prerewards) {
      staking_reward += prerewards[_user];
    }

    // We know that zero user balance, means no rewards
    if (user.balance == 0) return staking_reward;

    uint8 epoch_number = get_current_epoch_number();
    // We also know that at least one full epoch must elaps for there to be
    // any rewards. Eg. stake at t0, does not give any rewards until t2
    if (epoch_number <= user.epoch_start) return staking_reward;

    uint epoch_len = epochs.length - 1;
    Epoch memory epoch_u = epochs[epoch_len];
    // The next check is kept for completeness but is redundant. If any execution
    // can make it to this step, the balance cannot by definiton be zero, because
    // some user must have balance
    // if (epoch_u.balance == 0) return 0;

    // By the rules of how rewards are calculated, we only pay rewards for elapsed
    // epochs, so if we are looking at the current epoch, we must go back before
    // that. This can happen if someone stakes or unstakes before we calculate
    // rewards
    if (epoch_u.epoch_number == epoch_number) {
      epoch_len--;
      epoch_u = epochs[epoch_len];
    }

    // If the latest epoch is not the one that just elapsed, it means we must
    // be looking at a gap, eg. we are at e6, but the array is [e0], so we must
    // create a "fake" e5, and "push back" e0 into the array
    if (epoch_u.epoch_number < epoch_number - 1) {
      epoch_len++; // "push back", so we look at this epoch again in the loop
      epoch_u = Epoch(epoch_number - 1, epoch_u.balance); // create the fake epoch
    }

    // We can sum up just part of the calculation, as other parts are constant
    uint256 aggregate_reward_share = 0;

    // We use a while loop here as Solidity has a bug where it will decrement
    // below zero before checking the condition, causing the new overflow
    // protection to revert
    uint idx = epoch_len;
    while (epoch_u.epoch_number > user.epoch_start) {
      Epoch memory epoch_l = epochs[idx - 1];

      // Since withdraw_rewards might set the `epoch_start` to something that
      // does not exist, we may have to add a fake epoch here
      if (epoch_l.epoch_number < user.epoch_start) {
        epoch_l = Epoch(user.epoch_start, epoch_l.balance);
        idx = 0; // defer break
      }

      uint256 epochSpan = uint256(epoch_u.epoch_number - epoch_l.epoch_number);

      // user.balance is constant, however precision errors arise if moved outside
      // the loop. `<< PRECISION` is the same as `* 2**PRECISION` but cheaper
      aggregate_reward_share += ((user.balance * epochSpan) << PRECISION) / epoch_l.balance;

      if (idx == 0) break;

      // swap places
      epoch_u = epoch_l;
      // This can never underflow, as the break above will always trigger at the
      // latest on e0
      idx--;
    }

    staking_reward += (aggregate_reward_share * epoch_reward) >> PRECISION;

    return staking_reward;
  }

  function emergency_refund (address[] calldata _users) external only_controller {
    uint240 total_balance = 0;
    for (uint idx = 0; idx < _users.length; idx++) {
      address addr = _users[idx];
      uint240 balance = users[addr].balance;
      total_balance += balance;

      delete users[addr];
      require(trusted_lp_token.transfer(addr, balance));
    }

    uint8 epoch_number = get_current_epoch_number();
    Epoch storage latest_epoch = epochs[epochs.length - 1];
    if (latest_epoch.epoch_number == epoch_number) {
      latest_epoch.balance -= total_balance;
      return;
    }

    epochs.push(Epoch(epoch_number, latest_epoch.balance - total_balance));
  }

  function set_controller(address new_controller) external only_controller {
    require(new_controller != address(0));
    controller = new_controller;
  }

  modifier only_controller () {
    require(msg.sender == controller);
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

