//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC20.sol";
import "./IStake.sol";

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