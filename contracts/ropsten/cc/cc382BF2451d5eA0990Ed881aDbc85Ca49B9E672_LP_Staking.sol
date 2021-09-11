/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


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


contract LP_Staking {
  constructor(address lp_token, address award_token, uint8 epoch_count, uint256 epoch_length_seconds, uint256 epoch_rewards){
    final_epoch = epoch_count;
    epoch_seconds = epoch_length_seconds;
    epoch_reward = epoch_rewards;
    staking_start = block.timestamp;
    lp_token_address = lp_token;
    award_token_address = award_token;
    staking_end = block.timestamp + (epoch_count * epoch_length_seconds);
    epochs.push(Epoch(0,0,0));
  }

  struct User {
    uint8 last_epoch_withdrawn;
    uint256 balance;
  }

  struct Epoch {
    uint256 balance;
    uint256 minimum_balance;
    uint8 epoch_number;
  }

  address public immutable lp_token_address;
  address public immutable award_token_address;
  uint256 public immutable staking_start;
  uint256 public immutable staking_end;
  uint256 public immutable epoch_seconds;
  uint256 public immutable epoch_reward;
  uint8 public immutable final_epoch;
  uint256 public constant precision = 2**48;

  Epoch[] public epochs;
  mapping(address=> User) public users;

  function get_current_epoch_number() public view returns(uint8){
    if(block.timestamp > staking_end){
      return final_epoch;
    }

    return uint8((block.timestamp - staking_start) / epoch_seconds);
  }

  function total_staked_for_user(address user) public view returns (uint256) {
    return users[user].balance;
  }
  function total_staked() public view returns (uint256) {
    return epochs[epochs.length -1].balance;
  }

  // NOTE user MUST run IERC20(lp_token_address).approve(this_contract, value) prior to running this
  function stake(uint256 value) public {
    require(users[msg.sender].balance == 0, "user must unstake before adding more");

    IERC20(lp_token_address).transferFrom(msg.sender, address(this), value);
    uint8 current_epoch_number = get_current_epoch_number();
    require(get_current_epoch_number() < final_epoch, "this staking contract has finished.");
    users[msg.sender].balance = value;
    users[msg.sender].last_epoch_withdrawn = current_epoch_number;
    // push new epoch
    if( epochs[epochs.length-1].epoch_number < current_epoch_number) {
      epochs.push(Epoch(epochs[epochs.length-1].balance, epochs[epochs.length-1].balance, current_epoch_number));
    }

    epochs[epochs.length-1].balance += value;

  }

  function unstake() public {
    //must unstake all, because maths


    withdraw_rewards();
    epochs[epochs.length-1].balance -= users[msg.sender].balance;
    if(epochs[epochs.length-1].balance < epochs[epochs.length-1].minimum_balance){
      epochs[epochs.length-1].minimum_balance = epochs[epochs.length-1].balance;
    }
    IERC20(lp_token_address).transfer(msg.sender, users[msg.sender].balance);
    delete(users[msg.sender]);
  }


  function get_available_reward(address account) public view returns(uint256) {
    uint256 final_award;
    uint8 epoch_span;
    uint256 epoch_percentage;

    uint8 current_epoch_number = get_current_epoch_number();
    User memory user = users[account];
    Epoch memory current_epoch = epochs[epochs.length -1];

    if(current_epoch_number == 0 || user.last_epoch_withdrawn == current_epoch_number || current_epoch.balance == 0){
      return 0;
    }
    uint8 epoch_idx;

    Epoch memory prev_epoch;
    if(current_epoch.epoch_number < current_epoch_number){
      // virtual epoch
      prev_epoch = current_epoch;
      current_epoch = Epoch(prev_epoch.balance,prev_epoch.balance, current_epoch_number);
      epoch_idx = uint8(epochs.length-1);
    } else {
       epoch_idx = uint8(epochs.length-2);
       prev_epoch = epochs[epoch_idx];
    }

    //-1 to exclude the current open epoch
    if(prev_epoch.epoch_number > user.last_epoch_withdrawn){
      epoch_span = (current_epoch_number - 1) - prev_epoch.epoch_number;
    } else {
      epoch_span = (current_epoch_number - 1) - user.last_epoch_withdrawn;
    }

    bool complete;
    for(;epoch_idx >= 0 ; epoch_idx--) {
      if(current_epoch.epoch_number == current_epoch_number){
        epoch_percentage = (user.balance * precision)/(prev_epoch.balance);
      } else {
        epoch_percentage = (user.balance * precision)/(current_epoch.minimum_balance);
      }
      final_award += ((epoch_reward * epoch_percentage * epoch_span) /precision);
      if(complete || epoch_idx == 0){
        break;
      }
      current_epoch = prev_epoch;
      prev_epoch = epochs[epoch_idx-1];
      if(prev_epoch.epoch_number > user.last_epoch_withdrawn){
        epoch_span = current_epoch.epoch_number - prev_epoch.epoch_number;
      } else {
        epoch_span = current_epoch.epoch_number - user.last_epoch_withdrawn;
        complete == true;
      }
    }
    return final_award;
  }


  function withdraw_rewards() public {
    require(users[msg.sender].balance > 0, "user has no staked balance");

    uint8 current_epoch_number = get_current_epoch_number();
    if(users[msg.sender].last_epoch_withdrawn == current_epoch_number || current_epoch_number == 0) {
      //there can be no rewards, so return
      return;
    }
    // push new epoch if appropriate
    if(epochs[epochs.length-1].epoch_number < current_epoch_number && current_epoch_number <= final_epoch) {
      epochs.push(Epoch(epochs[epochs.length-1].balance, epochs[epochs.length-1].balance, current_epoch_number));
    }

    uint256 final_award = get_available_reward(msg.sender);

    if(current_epoch_number == final_epoch){
      users[msg.sender].last_epoch_withdrawn = current_epoch_number;
    } else {
      users[msg.sender].last_epoch_withdrawn = current_epoch_number-1;
    }
    //transfer to user
    if(final_award > 0){
      IERC20(award_token_address).transfer(msg.sender, final_award);
    }
  }
}


/**
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWEMMMMMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMLOVEMMMMMMMMMMMMMMMMMMMMMM...............MMMMMMMMMMMMM
MMMMMMMMMMHIXELMMMMMMMMMMMM....................MMMMMNNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMM....................MMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMM88=........................+MMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMM....................MMMMM...MMMMMMMMMMMMMMM
MMMMMMMMMMMM.........................MM+..MMM....+MMMMMMMMMM
MMMMMMMMMNMM...................... ..MM?..MMM.. .+MMMMMMMMMM
MMMMNDDMM+........................+MM........MM..+MMMMMMMMMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................MMM
MMMMZ.............................+MM....................DDD
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MMMMZ.............................+MM..ZMMMMMMMMMMMMMMMMMMMM
MM..............................MMZ....ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM............................MM.......ZMMMMMMMMMMMMMMMMMMMM
MM......................ZMMMMM.......MMMMMMMMMMMMMMMMMMMMMMM
MM............... ......ZMMMMM.... ..MMMMMMMMMMMMMMMMMMMMMMM
MM...............MMMMM88~.........+MM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......$DDDDDDD.......$DDDDD..DDNMM..ZMMMMMMMMMMMMMMMMMMMM
MM.......ZMMMMMMM.......ZMMMMM..MMMMM..ZMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMM+.......MMMMM88NMMMMM..MMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM*/