/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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

contract SHP {

  function balanceOfAt(
    address owner,
    uint256 blockNumber
  ) public pure returns (uint256) {
    require(owner != address(0x0), "invalid address");
    require(blockNumber > 0, "invalid block");
    return 100000 ether;
  }

  function totalSupplyAt(
    uint256 blockNumber
  ) public pure returns (uint256) {
    require(blockNumber > 0, "invalid block");
    return 32000000 ether;
  }
}

/// @title ERC20 Vesting
/// @author Vega Protocol
/// @notice This contract manages the vesting of the Vega V2 ERC20 token
contract VegaVesting {

  event Lien_Applied(address indexed user, uint256 amount);
  event Tokens_Withdrawn(address indexed user, uint8 tranche_id, uint256 amount);
  event Tranche_Created(uint8 indexed tranche_id, uint256 cliff_start, uint256 duration);
  event Tranche_Balance_Added(address indexed user, uint8 indexed tranche_id, uint256 amount);
  event Tranche_Balance_Removed(address indexed user, uint8 indexed tranche_id, uint256 amount);
  event Stake_Deposited(address indexed user, uint256 amount, bytes32 vega_public_key);
  event Stake_Removed(address indexed user, uint256 amount);
  event Stake_Removed_In_Anger(address indexed user, uint256 amount);
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

  /// @param token_v1_address Vega's already deployed v1 ERC20 token address
  /// @param token_v2_address Vega's v2 ERC20 token and the token being vested here
  /// @dev emits Controller_Set event
  constructor(address token_v1_address, address token_v2_address) {
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
  mapping(address => address) public user_migrations;

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

  /// @notice this function allows the beneficiary of some tokens to propose a new address to become the beneficiary
  /// @notice the beneficiary is only updated when the new address is confirmed by calling confirm_new_user
  function request_user_migration(address new_user) public {
    require(user_stats[msg.sender].total_in_all_tranches > 0, "This user has nothing to move");
    user_migrations[new_user] = msg.sender;
  }

  /// @notice this function allows the proposed user to accept a migration of tokens
  function confirm_user_migration() public {
    require(user_migrations[msg.sender] != address(0x0));
    user_stats[msg.sender].total_in_all_tranches = user_stats[user_migrations[msg.sender]].total_in_all_tranches;
    user_stats[msg.sender].lien = user_stats[user_migrations[msg.sender]].lien;
    for(uint8 i=1; i<tranche_count; i++) {
      user_stats[msg.sender].tranche_balances[i] = user_stats[user_migrations[msg.sender]].tranche_balances[i];
    }
    delete user_stats[user_migrations[msg.sender]];
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
      user_stats[user].tranche_balances[0].total_deposited += bal;
      user_stats[user].total_in_all_tranches += bal;
      v1_migrated[user] = true;
    }
    require(user_stats[user].tranche_balances[0].total_deposited >= amount);
    user_stats[user].tranche_balances[0].total_deposited -= amount;
    user_stats[user].tranche_balances[tranche_id].total_deposited += amount;
    emit Tranche_Balance_Removed(user, 0, amount);
    emit Tranche_Balance_Added(user, tranche_id, amount);
  }

  /// @notice this view returns the balance of the given tranche for the given user
  /// @notice tranche 0 balance of a non-v1_migrated user will return user's v1 token balance as they are pre-issued to the current hodlers
  /// @param user Target user address
  /// @param tranche_id target tranche
  /// @return balance of target tranche of user
  function get_tranche_balance(address user, uint8 tranche_id) public view returns(uint256) {
    if(tranche_id == 0 && !v1_migrated[user]){
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
      return IERC20(v1_address).balanceOf(user);
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
    require(tranche_id != 0);
    uint256 to_withdraw = get_vested_for_tranche(msg.sender, tranche_id);
    require(user_stats[msg.sender].total_in_all_tranches - to_withdraw >=  user_stats[msg.sender].lien);
    user_stats[msg.sender].tranche_balances[tranche_id].total_claimed += to_withdraw;
    user_stats[msg.sender].total_in_all_tranches -= to_withdraw;
    total_locked -= to_withdraw;
    require(IERC20(v2_address).transfer(msg.sender, to_withdraw));
    emit Tranche_Balance_Removed(msg.sender, tranche_id, to_withdraw);
  }

  /// @notice This function will put a lien on the user who runs this function
  /// @dev Emits Stake_Deposited event if successful
  /// @param amount Amount of tokens to stake
  /// @param vega_public_key Target Vega public key to be credited with the stake lock
  function stake_tokens(uint256 amount, bytes32 vega_public_key) public {
    require(user_stats[msg.sender].lien + amount > user_stats[msg.sender].lien);
    require(user_total_all_tranches(msg.sender) >= user_stats[msg.sender].lien + amount);
    //user applies this to themselves which only multisig control can remove
    user_stats[msg.sender].lien += amount;
    emit Stake_Deposited(msg.sender, amount, vega_public_key);
  }

  /// @notice This function will remove the lien from the user who runs this function
  /// @notice clears "amount" of lien
  /// @dev emits Stake_Removed event if successful
  /// @param amount Amount of tokens to remove from Staking
  function remove_stake(uint256 amount) public {
    /// @dev TODO add multisigControl IFF needed
    user_stats[msg.sender].lien -= amount;
    emit Stake_Removed(msg.sender, amount);
  }

  /// @notice This function allows the controller to permit the given address to issue the given Amount
  /// @notice Target users MUST have a zero (0) permitted issuance balance (try revoke_issuer)
  /// @dev emits Issuer_Permitted event
  /// @param issuer Target address to be allowed to issue given amount
  /// @param amount Number of tokens issuer is permitted to issue
  function permit_issuer(address issuer, uint256 amount) public only_controller {
    /// @notice revoke is required first to stop a simple double allowance attack
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
    permitted_issuance[new_controller] = 0;
    emit Controller_Set(new_controller);
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


contract VEGA_Pool is Ownable {

  uint256 public constant EXEPECTED_VEGA = 422000 ether; // 18 decimal places
  uint256 public constant EQUITY_RATIO = 2500; // 25%

  uint256 public assignSharesCutoff;
  uint256 public equityTokens;
  uint256 public equityTokensRedeemed;
  uint256 public preferentialTokens;
  uint256 public preferentialTokensRedeemed;

  address public preferentialAddress;

  bool public initialized = false;

  SHP public shp;
  IERC20 public vega;
  VegaVesting public vegaVesting;

  uint256 public referenceBlock;

  bool public voteComplete = false;
  bool public approveDistribution = false;

  mapping(address => uint256) public equityShares;
  mapping(address => bool) public permittedEquityHolders;
  mapping(uint256 => address) public equityHolders;
  mapping(address => int8) public distributionVotes;
  mapping(address => bool) public shpTokensRedeemed;

  uint256 public totalEquityHolders;
  uint256 public totalShares;
  uint256 public totalVotes;
  int256 public voteOutcome;
  uint256 public shpRedemptionCount;

  // This modifier makes sure the contract has been initialized
  modifier requireInitialized() {
     require(initialized, "Contract is not initialized.");
     _;
  }

  // This modifier makes sure the contract is not initialized
  modifier notInitialized() {
     require(!initialized, "Contract has been initialized.");
     _;
  }

  receive() external payable { }

  /**
  * This function allows equity holders to vote on whether tokens should
  * remain theirs, or whether they should be made available for redemption
  * by SHP token holders.
  *
  * If they vote to allow SHP token holders to redeem VEGA from the contract
  * then SHP token holders will be able to call the claimTokens function
  * and the amount of VEGA will be calculated based on their SHP holding
  * at the reference Ethereum block.
  *
  * Once the vote has been successfully completed, if the equity holders vote
  * AGAINST distrubiton, they will be able to redeem tokens by calling
  * redeemTokensViaEquity. If they vote FOR distribution they will not be
  * able to redeem any tokens. Instead SHP token holders will be able to
  * redeem tokens by calling claimTokens.
  *
  * _vote   the user's vote (1 = for, -1 = against)
  **/
  function castVote(int8 _vote) requireInitialized public {
    require(block.timestamp > assignSharesCutoff,
      "Cannot vote whilst shares can still be assigned.");
    require(distributionVotes[msg.sender] == 0,
      "You have already cast your vote.");
    require(_vote == 1 || _vote == -1,
      "Vote must be 1 or -1");
    require(voteComplete == false,
      "Voting has already concluded.");
    require(equityShares[msg.sender] > 0,
      "You cannot vote without equity shares.");
    int256 weight = int256(getUserEquity(msg.sender));
    distributionVotes[msg.sender] = _vote;
    totalVotes += 1;
    voteOutcome += (_vote * weight);
    if(totalVotes == totalEquityHolders) {
      voteComplete = true;
      approveDistribution = voteOutcome > 0;
    }
  }

  /**
  * This function withdraws any vested tokens and redeems the preferential
  * tokens if they have not already been redeemed.
  **/
  function syncTokens() requireInitialized internal {
    withdrawVestedTokens();
    if(preferentialTokens > preferentialTokensRedeemed) {
      redeemPreferentialTokens();
    }
  }

  /**
  * This function allows users that held SHP at the reference Ethereum block
  * to claim VEGA from the smart contract, provided the equity holders have
  * voted to permit them to do so.
  *
  * If permitted to do so, the equityTokens will be made available to users
  * in direct proportion to the SHP held (divided by total supply) at the
  * reference block.
  **/
  function claimTokens() requireInitialized public {
    require(approveDistribution, "Distribution is not approved");
    syncTokens();
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot claim until preferential tokens are redeemed.");
    uint256 shpBalance = shp.balanceOfAt(msg.sender, referenceBlock);
    require(shpTokensRedeemed[msg.sender] == false,
      "SHP holder already claimed tokens.");
    uint256 vegaBalance = vega.balanceOf(address(this));
    require(shpRedemptionCount > 0 || vegaBalance >= equityTokens,
      "Cannot claim until all equity tokens are fully vested.");
    uint256 shpSupply = shp.totalSupplyAt(referenceBlock);
    uint256 mod = 1000000000000;
    uint256 tokenAmount = (((shpBalance * mod) / shpSupply) *
      equityTokens) / mod;
    vega.transfer(msg.sender, tokenAmount);
    equityTokensRedeemed += tokenAmount;
    shpTokensRedeemed[msg.sender] = true;
    shpRedemptionCount += 1;
  }

  /**
  * This function allows the owner to withdraw any ERC20 which is not VEGA
  * from the contract at-will. This can be used to redeem staking rewards,
  * or other ERC20s which might end up in this contract by mistake, or by
  * something like an airdrop.
  *
  * _tokenAddress    the contract address for the ERC20
  **/
  function withdrawArbitraryTokens(
    address _tokenAddress
  ) requireInitialized onlyOwner public {
    require(_tokenAddress != address(vega),
      "VEGA cannot be withdrawn at-will.");
    IERC20 token = IERC20(_tokenAddress);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
  * This function performs the same role as withdrawArbitraryTokens, except
  * it is used to withdraw ETH.
  **/
  function withdrawEther() requireInitialized onlyOwner public {
    payable(owner()).transfer(address(this).balance);
  }

  /**
  * This function can be called by anybody and it withdraws unlocked
  * VEGA tokens from the vesting contract. The tokens are transferred
  * to this contract, which allows them to be redeemed by the rightful owner
  * when they call one of the redemption functions.
  **/
  function withdrawVestedTokens() requireInitialized internal {
    for(uint8 i = 1; i < vegaVesting.tranche_count(); i++) {
      if(vegaVesting.get_vested_for_tranche(address(this), i) > 0) {
        vegaVesting.withdraw_from_tranche(i);
      }
    }
  }

  /**
  * This function allows the owner to issue equity to new users. This is done
  * by assigning an absolute number of shares, which in turn dilutes all
  * existing share holders.
  *
  * _holder    the Ethereum address of the equity holder
  * _amount    the number of shares to be assigned to the holder
  **/
  function issueEquity(
    address _holder,
    uint256 _amount
  ) requireInitialized onlyOwner public {
    require(permittedEquityHolders[_holder],
      "The holder must be permitted to own equity.");
    require(assignSharesCutoff > block.timestamp,
      "The cutoff has passed for assigning shares.");
    if(equityShares[_holder] == 0) {
      equityHolders[totalEquityHolders] = _holder;
      totalEquityHolders += 1;
    }
    totalShares += _amount;
    equityShares[_holder] += _amount;
  }

  /**
  * This function allows the preferential tokens to be distributed to the
  * rightful owner. This function can be called by anybody.
  **/
  function redeemPreferentialTokens() requireInitialized public {
    require(preferentialTokens > preferentialTokensRedeemed,
      "All preferntial tokens have been redeemed.");
    uint256 availableTokens = preferentialTokens - preferentialTokensRedeemed;
    withdrawVestedTokens();
    uint256 vegaBalance = vega.balanceOf(address(this));
    if(availableTokens > vegaBalance) {
      availableTokens = vegaBalance;
    }
    vega.transfer(preferentialAddress, availableTokens);
    preferentialTokensRedeemed += availableTokens;
  }

  /**
  * This function distributes tokens to equity holders based on the amount
  * of shares they own.
  *
  * Anybody can call this function in order to ensure all of the tokens are
  * distributed when it becomes eligible to do so.
  **/
  function redeemTokensViaEquity() requireInitialized public {
    require(totalShares > 0, "There are are no equity holders");
    require(assignSharesCutoff < block.timestamp,
      "Tokens cannot be redeemed whilst equity can still be assigned.");
    syncTokens();
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot redeem via equity until all preferential tokens are collected.");
    require(voteComplete, "Cannot redeem via equity until vote is completed.");
    require(approveDistribution == false,
      "Tokens can only be redeemed by SHP holders.");
    uint256 availableTokens = equityTokens - equityTokensRedeemed;
    uint256 vegaBalance = vega.balanceOf(address(this));
    if(availableTokens > vegaBalance) {
      availableTokens = vegaBalance;
    }
    for(uint256 i = 0; i < totalEquityHolders; i++) {
      uint256 tokensToRedeem = (availableTokens *
        getUserEquity(equityHolders[i])) / 10000;
      vega.transfer(equityHolders[i], tokensToRedeem);
      equityTokensRedeemed += tokensToRedeem;
    }
  }

  /**
  * This function allows anybody to redeem excess VEGA to the owner's wallet
  * provided the following conditions are met:
  *
  * 1) No equity shares exist, which happens under two scenarios:
  *      a) They are never issued in the first place
  *      b) They are burnt after redeeming VEGA
  * 2) The cut-off for assigning equity shares is in the past
  *
  * This function transfers the entire VEGA balance held by the
  * smart contract at execution time.
  **/
  function redeemExcessTokens() requireInitialized public {
    if(totalEquityHolders > 0) {
      require(equityTokens == equityTokensRedeemed,
        "Cannot redeem excess tokens until equity tokens are collected.");
    }
    require(preferentialTokens == preferentialTokensRedeemed,
      "Cannot redeem excess tokens until preferential tokens are collected.");
    withdrawVestedTokens();
    vega.transfer(owner(), vega.balanceOf(address(this)));
  }

  /**
  * This function calculates the equity of the specified user
  *
  * _holder    the Ethereum address of the equity holder
  **/
  function getUserEquity(
    address _holder
  ) public view returns(uint256) {
    return (equityShares[_holder] * 10000) / totalShares;
  }

  /**
  * This function allows the contract to be initialized only once.
  * We do not use the constructor, because the Vega vesting contract needs to
  * know the address of this smart contract when it is deployed. Therefore,
  * this contract needs to be deployed, and then updated with the address of
  * the Vega vesting contract afterwards.
  *
  * _vegaAdress           the Ethereum address of the VEGA token contract
  * _vegaVestingAddress   the Ethereum address of Vega's vesting contract
  * _preferentialAddress  Ethereum address for preferential tokens
  * _holders              an array of permitted equity holders
  * _assignSharesCutoff   timestamp after which shares cannot be assigned
  * _referenceBlock       the Ethereum block to lookup SHP balances with
  * _shpTokenAddress      the Ethereum address for SHP token contract
  **/
  function initialize(
    address _vegaAddress,
    address _vegaVestingAddress,
    address _preferentialAddress,
    address[] memory _holders,
    uint256 _assignSharesCutoff,
    uint256 _referenceBlock,
    address _shpTokenAddress
  ) public onlyOwner notInitialized {
    vega = IERC20(_vegaAddress);
    shp = SHP(_shpTokenAddress);
    vegaVesting = VegaVesting(_vegaVestingAddress);
    uint256 totalTokens = vegaVesting.user_total_all_tranches(address(this));
    preferentialAddress = _preferentialAddress;
    assignSharesCutoff = _assignSharesCutoff;
    referenceBlock = _referenceBlock;
    require(totalTokens >= EXEPECTED_VEGA,
      "The balance at the vesting contract is too low.");
    for(uint8 x = 0; x < _holders.length; x++) {
      permittedEquityHolders[_holders[x]] = true;
    }
    equityTokens = (totalTokens * EQUITY_RATIO) / 10000;
    preferentialTokens = totalTokens - equityTokens;
    initialized = true;
  }
}