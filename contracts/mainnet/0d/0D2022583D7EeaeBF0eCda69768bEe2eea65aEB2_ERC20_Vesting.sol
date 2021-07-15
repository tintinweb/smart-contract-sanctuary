/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-14
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


/// @title ERC20 Vesting
/// @author Vega Protocol
/// @notice This contract manages the vesting of the Vega V2 ERC20 token
contract ERC20_Vesting is IStake {

  event Tranche_Created(uint8 indexed tranche_id, uint256 cliff_start, uint256 duration);
  event Tranche_Balance_Added(address indexed user, uint8 indexed tranche_id, uint256 amount);
  event Tranche_Balance_Removed(address indexed user, uint8 indexed tranche_id, uint256 amount);
  event Issuer_Permitted(address indexed issuer, uint256 amount);
  event Issuer_Revoked(address indexed issuer);
  event Controller_Set(address indexed new_controller);

  /// @notice controller is similar to "owner" in other contracts
  address public controller;
  /// @notice tranche_count starts at 1 to cause tranche 0 (perma-lock) to exist as the default tranche
  uint8 public tranche_count = 1;
  /// @notice user => has been migrated
  mapping(address => bool) public v1_migrated;
  /// @notice user => user_stat struct
  mapping(address=> user_stat) public user_stats;

  /// @notice total_locked is the total amount of tokens "on" this contract that are locked into a tranche
  uint256 public total_locked;
  /// @notice v1_address is the address for Vega's v1 ERC20 token that has already been deployed
  address public v1_address; // mainnet = 0xD249B16f61cB9489Fe0Bb046119A48025545b58a;
  /// @notice v2_address is the address for Vega's v2 ERC20 token that replaces v1
  address public v2_address;
  /// @notice accuracy_scale is the multiplier to assist in integer division
  uint256 constant public accuracy_scale = 100000000000;
  /// @notice default_tranche_id is the tranche_id for the default tranche
  uint8 constant public default_tranche_id = 0;
  /// @dev total_staked_tokens is the number of tokens staked across all users
  uint256 total_staked_tokens;

  /****ADDRESS MIGRATION**/
  /// @notice new address => old address
  mapping(address => address) public address_migration;
  /*****/

  /// @param token_v1_address Vega's already deployed v1 ERC20 token address
  /// @param token_v2_address Vega's v2 ERC20 token and the token being vested here
  /// @dev emits Controller_Set event
  constructor(address token_v1_address, address token_v2_address, address[] memory old_addresses, address[] memory new_addresses) {
    require(old_addresses.length == new_addresses.length, "array length mismatch");

    for(uint8 map_idx = 0; map_idx < old_addresses.length; map_idx++) {
      /// @dev the following line prevents double-mapping attack
      require(!v1_migrated[old_addresses[map_idx]]);
      v1_migrated[old_addresses[map_idx]] = true;
      address_migration[new_addresses[map_idx]] = old_addresses[map_idx];
    }

    v1_address = token_v1_address;
    /// @notice this initializes the total_locked with the amount of already issued v1 VEGA ERC20 tokens
    total_locked = IERC20(token_v1_address).totalSupply() - IERC20(token_v1_address).balanceOf(token_v1_address);
    v2_address = token_v2_address;
    controller = msg.sender;
    emit Controller_Set(controller);
  }

  /// @notice tranche_balance has the params necessary to track what a user is owed in a single tranche
  /// @param total_deposited is the total number of tokens deposited into this single tranche for a single user
  /// @param total_claimed is the total number of tokens in this tranche that have been withdrawn
  struct tranche_balance {
      uint256 total_deposited;
      uint256 total_claimed;
  }

  /// @notice user_stat is a struct that holds all the details needed to handle a single user's vesting
  /// @param total_in_all_tranches is the total number of tokens currently in all tranches that have been migrated to v2
  /// @param lien total amount of locked tokens that have been marked for staking
  /// @param tranche_balances is a mapping of tranche_id => tranche_balance
  struct user_stat {
    uint256 total_in_all_tranches;
    uint256 lien;
    mapping (uint8 => tranche_balance) tranche_balances;
    mapping(bytes32 => uint256) stake;
  }

  /// @notice tranche is a struct that hold the details needed for calculating individual tranche vesting
  /// @param cliff_start is a timestamp after which vesting starts
  /// @param duration is the number of seconds after cliff_start until the tranche is 100% vested
  struct tranche {
    uint256 cliff_start;
    uint256 duration;
  }

  /// @notice tranche_id => tranche struct
  mapping(uint8 => tranche) public tranches;
  /// @notice issuer address => permitted issuance allowance
  mapping(address => uint256) public permitted_issuance;

  /// @notice this function allows the contract controller to create a tranche
  /// @notice tranche zero is perma-locked and already exists prior to running this function, making the first vesting tranche "tranche:1"
  /// @param cliff_start is a timestamp in seconds of when vesting begins for this tranche
  /// @param duration is the number of seconds after cliff_start that the tranche will be fully vested
  function create_tranche(uint256 cliff_start, uint256 duration) public only_controller {
    tranches[tranche_count] = tranche(cliff_start, duration);
    emit Tranche_Created(tranche_count, cliff_start, duration);
    /// @notice sol ^0.8 comes with auto-overflow protection
    tranche_count++;
  }

  /// @notice this function allows the conroller or permitted issuer to issue tokens from this contract itself (no tranches) into the specified tranche
  /// @notice tranche MUST be created
  /// @notice once assigned to a tranche, tokens can never be clawed back, but they can be reassigned IFF they are in tranche_id:0
  /// @param user The user being issued the tokens
  /// @param tranche_id the id of the target tranche
  /// @param amount number of tokens to be issued into tranche
  /// @dev emits Tranche_Balance_Added event
  function issue_into_tranche(address user, uint8 tranche_id, uint256 amount) public controller_or_issuer {
    require(tranche_id < tranche_count, "tranche_id out of bounds");
    if(permitted_issuance[msg.sender] > 0){
      /// @dev if code gets here, they are an issuer if not they must be the controller
      require(permitted_issuance[msg.sender] >= amount, "not enough permitted balance");
      require(user != msg.sender, "cannot issue to self");
      permitted_issuance[msg.sender] -= amount;
    }
    require( IERC20(v2_address).balanceOf(address(this)) - (total_locked + amount) >= 0, "contract token balance low" );

    /// @dev only runs once
    if(!v1_migrated[user]){
      uint256 bal = v1_bal(user);
      user_stats[user].tranche_balances[0].total_deposited += bal;
      user_stats[user].total_in_all_tranches += bal;
      v1_migrated[user] = true;
    }
    user_stats[user].tranche_balances[tranche_id].total_deposited += amount;
    user_stats[user].total_in_all_tranches += amount;
    total_locked += amount;
    emit Tranche_Balance_Added(user, tranche_id, amount);
  }


  /// @notice this function allows the controller to move tokens issued into tranche zero to the target tranche
  /// @notice can only be moved from tranche 0
  /// @param user The user being issued the tokens
  /// @param tranche_id the id of the target tranche
  /// @param amount number of tokens to be moved from tranche 0
  /// @dev emits Tranche_Balance_Removed event
  /// @dev emits Tranche_Balance_Added event
  function move_into_tranche(address user, uint8 tranche_id, uint256 amount) public only_controller {
    require(tranche_id > 0 && tranche_id < tranche_count);

    /// @dev only runs once
    if(!v1_migrated[user]){
      uint256 bal = v1_bal(user);
      user_stats[user].tranche_balances[default_tranche_id].total_deposited += bal;
      user_stats[user].total_in_all_tranches += bal;
      v1_migrated[user] = true;
    }
    require(user_stats[user].tranche_balances[default_tranche_id].total_deposited >= amount);
    user_stats[user].tranche_balances[default_tranche_id].total_deposited -= amount;
    user_stats[user].tranche_balances[tranche_id].total_deposited += amount;
    emit Tranche_Balance_Removed(user, default_tranche_id, amount);
    emit Tranche_Balance_Added(user, tranche_id, amount);
  }

  /// @notice this view returns the balance of the given tranche for the given user
  /// @notice tranche 0 balance of a non-v1_migrated user will return user's v1 token balance as they are pre-issued to the current hodlers
  /// @param user Target user address
  /// @param tranche_id target tranche
  /// @return balance of target tranche of user
  function get_tranche_balance(address user, uint8 tranche_id) public view returns(uint256) {
    if(tranche_id == default_tranche_id && !v1_migrated[user]){
      return v1_bal(user);
    } else {
      return user_stats[user].tranche_balances[tranche_id].total_deposited - user_stats[user].tranche_balances[tranche_id].total_claimed;
    }
  }

  /// @notice This view returns the amount that is currently vested in a given tranche
  /// @notice This does NOT take into account any current lien
  /// @param user Target user address
  /// @param tranche_id Target tranche
  /// @return number of tokens vested in the target tranche for the target user
  function get_vested_for_tranche(address user, uint8 tranche_id) public view returns(uint256) {
    if(block.timestamp < tranches[tranche_id].cliff_start){
      return 0;
    }
    else if(block.timestamp > tranches[tranche_id].cliff_start + tranches[tranche_id].duration || tranches[tranche_id].duration == 0){
      return user_stats[user].tranche_balances[tranche_id].total_deposited -  user_stats[user].tranche_balances[tranche_id].total_claimed;
    } else {
      return (((( accuracy_scale * (block.timestamp - tranches[tranche_id].cliff_start) )  / tranches[tranche_id].duration
          ) * user_stats[user].tranche_balances[tranche_id].total_deposited
        ) / accuracy_scale ) - user_stats[user].tranche_balances[tranche_id].total_claimed;
    }
  }

  /// @notice This view returns the balance remaining in Vega V1 for a given user
  /// @notice Once migrated, the balance will always return zero, hence "remaining"
  /// @param user Target user
  /// @return remaining v1 balance
  function v1_bal(address user) internal view returns(uint256) {
    if(!v1_migrated[user]){
      if(address_migration[user] != address(0)){
        return IERC20(v1_address).balanceOf(user) + IERC20(v1_address).balanceOf(address_migration[user]);
      } else {
        return IERC20(v1_address).balanceOf(user);
      }
    } else {
      return 0;
    }
  }

  /// @notice This view returns the current amount of tokens locked in all tranches
  /// @notice This includes remaining v1 balance
  /// @param user Target user
  /// @return the current amount of tokens for target user in all tranches
  function user_total_all_tranches(address user) public view returns(uint256){
    return user_stats[user].total_in_all_tranches + v1_bal(user);
  }

  /// @notice This function withdraws all the currently available vested tokens from the target tranche
  /// @notice This will not allow a user's total tranch balance to go below the user's lien amount
  /// @dev Emits Tranche_Balance_Removed event if successful
  /// @param tranche_id Id of target tranche
  function withdraw_from_tranche(uint8 tranche_id) public {
    require(tranche_id != default_tranche_id);
    uint256 to_withdraw = get_vested_for_tranche(msg.sender, tranche_id);
    require(user_stats[msg.sender].total_in_all_tranches - to_withdraw >=  user_stats[msg.sender].lien);
    user_stats[msg.sender].tranche_balances[tranche_id].total_claimed += to_withdraw;
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    user_stats[msg.sender].total_in_all_tranches -= to_withdraw;
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    total_locked -= to_withdraw;
    require(IERC20(v2_address).transfer(msg.sender, to_withdraw));
    emit Tranche_Balance_Removed(msg.sender, tranche_id, to_withdraw);
  }

  /// @notice This function allows the controller to assist the target user with their withdrawal. All the currently available vested tokens FOR THE TARGET will be withdrawn TO THE TARGET ADDRESS WALLET
  /// @notice This function exists in case of users using custodial wallets that are incapable of running "withdraw_from_tranche" but are still ERC20 compatable
  /// @notice ONLY the controller can run this function and it will only be ran at the target users request
  /// @notice This will not allow a user's total tranch balance to go below the user's lien amount
  /// @notice This function does not allow the controller to access any funds from other addresses or change which address is in control of any funds
  /// @dev Emits Tranche_Balance_Removed event if successful
  /// @param tranche_id Id of target tranche
  /// @param target Address with balance that needs the assist
  function assisted_withdraw_from_tranche(uint8 tranche_id, address target) public only_controller {
    require(tranche_id != default_tranche_id);
    uint256 to_withdraw = get_vested_for_tranche(target, tranche_id);
    require(user_stats[target].total_in_all_tranches - to_withdraw >=  user_stats[target].lien);
    user_stats[target].tranche_balances[tranche_id].total_claimed += to_withdraw;
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    user_stats[target].total_in_all_tranches -= to_withdraw;
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    total_locked -= to_withdraw;
    require(IERC20(v2_address).transfer(target, to_withdraw));
    emit Tranche_Balance_Removed(target, tranche_id, to_withdraw);
  }


  /// @notice This function will put a lien on the user who runs this function
  /// @dev Emits Stake_Deposited event if successful
  /// @param amount Amount of tokens to stake
  /// @param vega_public_key Target Vega public key to be credited with the stake lock
  function stake_tokens(uint256 amount, bytes32 vega_public_key) public {
    require(user_stats[msg.sender].lien + amount > user_stats[msg.sender].lien);
    require(user_total_all_tranches(msg.sender) >= user_stats[msg.sender].lien + amount);
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    user_stats[msg.sender].lien += amount;
    user_stats[msg.sender].stake[vega_public_key] += amount;
    total_staked_tokens += amount;
    emit Stake_Deposited(msg.sender, amount, vega_public_key);
  }

  /// @notice This function will remove the lien from the user who runs this function
  /// @notice clears "amount" of lien
  /// @dev emits Stake_Removed event if successful
  /// @param amount Amount of tokens to remove from Staking
  /// @param vega_public_key Target Vega public key from which to remove stake lock
  function remove_stake(uint256 amount, bytes32 vega_public_key) public {
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    user_stats[msg.sender].stake[vega_public_key] -= amount;
    /// @dev Solidity ^0.8 has overflow protection, if this next line overflows, the transaction will revert
    user_stats[msg.sender].lien -= amount;
    total_staked_tokens -= amount;
    emit Stake_Removed(msg.sender, amount, vega_public_key);
  }

  /// @notice This function allows the controller to permit the given address to issue the given Amount
  /// @notice Target users MUST have a zero (0) permitted issuance balance (try revoke_issuer)
  /// @dev emits Issuer_Permitted event
  /// @param issuer Target address to be allowed to issue given amount
  /// @param amount Number of tokens issuer is permitted to issue
  function permit_issuer(address issuer, uint256 amount) public only_controller {
    /// @notice revoke is required first to stop a simple double allowance attack
    require(amount > 0, "amount must be > 0");
    require(permitted_issuance[issuer] == 0, "issuer already permitted, revoke first");
    require(controller != issuer, "controller cannot be permitted issuer");
    permitted_issuance[issuer] = amount;
    emit Issuer_Permitted(issuer, amount);
  }

  /// @notice This function allows the controller to revoke issuance permission from given target
  /// @notice permitted_issuance must be greater than zero (0)
  /// @dev emits Issuer_Revoked event
  /// @param issuer Target address of issuer to be revoked
  function revoke_issuer(address issuer) public only_controller {
    require(permitted_issuance[issuer] != 0, "issuer already revoked");
    permitted_issuance[issuer] = 0;
    emit Issuer_Revoked(issuer);
  }

  /// @notice This function allows the controller to assign a new controller
  /// @dev Emits Controller_Set event
  /// @param new_controller Address of the new controller
  function set_controller(address new_controller) public only_controller {
    controller = new_controller;
    if(permitted_issuance[new_controller] > 0){
      permitted_issuance[new_controller] = 0;
      emit Issuer_Revoked(new_controller);
    }
    emit Controller_Set(new_controller);
  }

  /// @dev This is IStake.staking_token
  /// @return the address of the token that is able to be staked
  function staking_token() external override view returns (address) {
    return v2_address;
  }

  /// @dev This is IStake.stake_balance
  /// @param target Target address to check
  /// @param vega_public_key Target vega public key to check
  /// @return the number of tokens staked for that address->vega_public_key pair
  function stake_balance(address target, bytes32 vega_public_key) external override view returns (uint256) {
    return user_stats[target].stake[vega_public_key];
  }

  /// @dev This is IStake.total_staked
  /// @return total tokens staked on contract
  function total_staked() external override view returns (uint256) {
    return total_staked_tokens;
  }

  /// @notice this modifier requires that msg.sender is the controller of this contract
  modifier only_controller {
         require( msg.sender == controller, "not controller" );
         _;
  }

  /// @notice this modifier requires that msg.sender is the controller of this contract or has a permitted issuance remaining of more than zero (0)
  modifier controller_or_issuer {
         require( msg.sender == controller || permitted_issuance[msg.sender] > 0,"not controller or issuer" );
         _;
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