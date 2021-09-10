/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

//SPDX-License-Identifier: MIT
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


/**
 * @dev Interface contains all of the events necessary for staking Vega token
 */
interface IStake {
  event Stake_Deposited(address indexed user, uint256 amount, bytes32 indexed vega_public_key);
  event Stake_Removed(address indexed user, uint256 amount, bytes32 indexed vega_public_key);
  event Stake_Transferred(address indexed from, uint256 amount, address indexed to, bytes32 indexed vega_public_key);

  /// @return the address of the token that is able to be staked
  function staking_token() external view returns (address);

  /// @param target Target address to check
  /// @param vega_public_key Target vega public key to check
  /// @return the number of tokens staked for that address->vega_public_key pair
  function stake_balance(address target, bytes32 vega_public_key) external view returns (uint256);


  /// @return total tokens staked on contract
  function total_staked() external view returns (uint256);
}

/// @title ERC20 Staking Bridge
/// @author Vega Protocol
/// @notice This contract manages the vesting of the Vega V2 ERC20 token
contract Vega_Staking_Bridge is IStake {
  address _staking_token;

  constructor(address token) {
    _staking_token = token;
  }

  /// @dev user => amount staked
  mapping(address => mapping(bytes32 => uint256)) stakes;

  /// @notice This stakes the given amount of tokens and credits them to the provided Vega public key
  /// @param amount Token amount to stake
  /// @param vega_public_key Target Vega public key to be credited with the stake
  /// @dev Emits Stake_Deposited event
  /// @dev User MUST run "approve" on token prior to running Stake
  function stake(uint256 amount, bytes32 vega_public_key) public {
    require(IERC20(_staking_token).transferFrom(msg.sender, address(this), amount));
    stakes[msg.sender][vega_public_key] += amount;
    emit Stake_Deposited(msg.sender, amount, vega_public_key);
  }

  /// @notice This removes specified amount of stake of available to user
  /// @dev Emits Stake_Removed event if successful
  /// @param amount Amount of tokens to remove from staking
  /// @param vega_public_key Target Vega public key from which to deduct stake
  function remove_stake(uint256 amount, bytes32 vega_public_key) public {
    stakes[msg.sender][vega_public_key] -= amount;
    require(IERC20(_staking_token).transfer(msg.sender, amount));
    emit Stake_Removed(msg.sender, amount, vega_public_key);
  }

  /// @notice This transfers all stake from the sender's address to the "new_address"
  /// @dev Emits Stake_Transfered event if successful
  /// @param amount Stake amount to transfer
  /// @param new_address Target ETH address to recieve the stake
  /// @param vega_public_key Target Vega public key to be credited with the transfer
  function transfer_stake(uint256 amount, address new_address, bytes32 vega_public_key) public {
    stakes[msg.sender][vega_public_key] -= amount;
    stakes[new_address][vega_public_key] += amount;
    emit Stake_Transferred(msg.sender, amount, new_address, vega_public_key);
  }

  /// @dev This is IStake.staking_token
  /// @return the address of the token that is able to be staked
  function staking_token() external override view returns (address) {
    return _staking_token;
  }

  /// @dev This is IStake.stake_balance
  /// @param target Target address to check
  /// @param vega_public_key Target vega public key to check
  /// @return the number of tokens staked for that address->vega_public_key pair
  function stake_balance(address target, bytes32 vega_public_key) external override view returns (uint256) {
    return  stakes[target][vega_public_key];
  }

  /// @dev This is IStake.total_staked
  /// @return total tokens staked on contract
  function total_staked() external override view returns (uint256) {
    return IERC20(_staking_token).balanceOf(address(this));
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