/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the erc token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Rewards is Context, Ownable {
  using SafeMath for uint256;
  
  struct RewardClaim {
    /* Account Key & Signature */
    address accountKey;
    uint128 gameUuid;
    uint256 oldBalance;
    uint256 newBalance;
    string signature;
  }
  
  // Game UUID > Balance
  mapping (uint128 => uint256) private _gameTotalSupply;
  
  // Game UUID > Balance
  mapping (uint128 => uint256) private _gameRemainingSupply;
  
  // Account > Running Balance
  mapping (address => uint256) private _balances;
  
  BATLToken _rewardToken;
  address _rewardTokenAddress;
  
  // Total Game Supply (All Games)
  uint256 private _totalGameSupply;
  
  // Total Rewarded Supply (All Games)
  uint256 private _totalRemainingGameSupply;

  /**
   * Event for a Reward Claim
   */
  event RewardClaimed(address indexed receiver, address indexed account, uint256 value);

  /**
   * Event for a Reward Withdrawal
   */
  event RewardWithdrawn(address indexed receiver, uint256 value);
  
  /**
   * Event for a Game Supply Update
   */
  event GameSupplyUpdated(uint128 indexed gameUuid, uint256 totalSupply, uint256 remainingSupply);

  constructor(address rewardToken) {
    _rewardTokenAddress = rewardToken;
    _rewardToken = BATLToken(rewardToken);
  }
  
  /**
   * @dev Returns the contract owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }
  
  /**
   * Increase Game Supply Function
   */
  function increaseGameSupply(uint128 gameUuid, uint256 value) public onlyOwner returns (uint256[2] memory) {
      // Add to total supply (for game)
      _gameTotalSupply[gameUuid] = _gameTotalSupply[gameUuid].add(value);
      
      // Add to remaining supply (for game)
      _gameRemainingSupply[gameUuid] = _gameRemainingSupply[gameUuid].add(value);
      
      emit GameSupplyUpdated(gameUuid, _gameTotalSupply[gameUuid], _gameRemainingSupply[gameUuid]);
      
      // Add to total supply (for all games)
      _totalGameSupply = _totalGameSupply.add(_gameTotalSupply[gameUuid]);
      
      // Add to remaining supply (for all games)
      _totalRemainingGameSupply = _totalRemainingGameSupply.add(value);
      
      return [
          _gameTotalSupply[gameUuid],
          _gameRemainingSupply[gameUuid]
      ];
  }
  
  /**
   * Decrease Game Supply Function
   */
  function decreaseGameSupply(uint128 gameUuid, uint256 value) public onlyOwner returns (uint256[2] memory) {
      require(value > 0, "Decrease Game Supply: Value must be greater than 0");
      
      // If the remaining supply is less than the decrease
      // Then we want to set the total supply to be what is already available
      // 
      
      /*
      * Scenario 1 - Decrease less than remaining
      *
      * Total Supply = 1000
      * Total Remaining = 100
      * 
      * Decrease = 1000
      * 
      * Remaining Supply < Decrease
      * Total Supply = 1000 - 100 = 900
      * Remaining Supply = 0
      *
      * Scenario 2 - Decrease greater than or equal to remaining
      *
      * Total Supply = 1000
      * Total Remaining = 500
      * 
      * Decrease = 500
      * 
      * Remaining Supply >= Decrease
      * Total Supply = 1000 - 500 = 500
      * Remaining Supply = 500 - 500 = 0
      *
      * Scenario 2.1 - Decrease greater than or equal to remaining
      *
      * Total Supply = 1000
      * Total Remaining = 500
      * 
      * Decrease = 300
      * 
      * Remaining Supply >= Decrease
      * Total Supply = 1000 - 300 = 700
      * Remaining Supply = 500 - 300 = 200
      *
      */
      
      if(_gameRemainingSupply[gameUuid] < value) { // If the remaining supply is less than the reduction
        // Decrease total supply (equal to the current remaining supply)
        _gameTotalSupply[gameUuid] = _gameTotalSupply[gameUuid].sub(_gameRemainingSupply[gameUuid]);
        
        // Decrease remaining supply (zero this out)
        _gameRemainingSupply[gameUuid] = 0;
        
        // Decrease total supply (for all games)
        _totalGameSupply = _totalGameSupply.sub(_gameRemainingSupply[gameUuid]);
        
        // Decrease remaining supply (for all games)
        if(_totalRemainingGameSupply < value) {
            // If the total remaining supply is less than the value (zero it out)
            _totalRemainingGameSupply = 0;
        } else {
            // Otherwise decrease it normally
            _totalRemainingGameSupply = _totalRemainingGameSupply.sub(_gameRemainingSupply[gameUuid]);
        }
      } else { // If we have enough remaining supply
        // Decrease total supply (for game)
        _gameTotalSupply[gameUuid] = _gameTotalSupply[gameUuid].sub(value);
      
        // Decrease remaining supply (for game)
        _gameRemainingSupply[gameUuid] = _gameRemainingSupply[gameUuid].sub(value);
        
        // Decrease total supply (for all games)
        _totalGameSupply = _totalGameSupply.sub(value);
        
        // Decrease remaining supply (for all games)
        _totalRemainingGameSupply = _totalRemainingGameSupply.sub(value);
      }
      
      emit GameSupplyUpdated(gameUuid, _gameTotalSupply[gameUuid], _gameRemainingSupply[gameUuid]);
      
      return [
          _gameTotalSupply[gameUuid],
          _gameRemainingSupply[gameUuid]
      ];
  }
  
  /**
   * Claim Reward via Hash & Signature
   */
  function claimReward(RewardClaim[] memory rewardClaims) public returns (uint256) {
    // Receiver of Reward Tokens
    address receiver = _msgSender();
    
    // For transfer at the end
    uint256 totalReward = 0;
    
    for (uint i=0; i<rewardClaims.length; i++) {
        RewardClaim memory rewardClaim = rewardClaims[i];
        
        bool signatureVerified = VerifySignature.verify(
            rewardClaim.accountKey,
            receiver,
            rewardClaim.gameUuid,
            rewardClaim.oldBalance,
            rewardClaim.newBalance,
            rewardClaim.signature
        );
        
        // New Balance must be Greater than the Old
        require(
            rewardClaim.newBalance > rewardClaim.oldBalance, 
            "Rewards: New Balance must be Greater than Old Balance"
        );
        
        // Verify that the Signature Matches
        require(
            signatureVerified, 
            "Rewards: Signature Invalid"
        );
        
        // Verify that the balance hasn't changed since the hash was generated.
        require(
            _balances[rewardClaim.accountKey] == rewardClaim.oldBalance, 
            "Rewards: Balance Changed Since Hash Generated"
        );
        
        // Get Reward (newBalance - oldBalance)
        uint256 reward = rewardClaim.newBalance.sub(rewardClaim.oldBalance);
        
        // Check that we have enough Game Supply
        _gameRemainingSupply[rewardClaim.gameUuid] = _gameRemainingSupply[rewardClaim.gameUuid].sub(reward, "Rewards: Not enough Game Supply Available");
        
        // Add to Historical Balances
        _balances[rewardClaim.accountKey] = _balances[rewardClaim.accountKey].add(reward);
        
        // Verify that the new Balance 
        require(
            _balances[rewardClaim.accountKey] == rewardClaim.newBalance, 
            "Rewards: New Balance is not in Expected State"
        );
        
        // Add to Total Reward (for Transfer at the end)
        totalReward = totalReward.add(reward);
    
        // Emit Success Claimed (for Account & Receiver)
        emit RewardClaimed(receiver, rewardClaim.accountKey, reward);
    }
        
    // Emit Success (for Receiver)
    emit RewardWithdrawn(receiver, totalReward);
    
    _rewardToken.transfer(receiver, totalReward);
    
    return totalReward;
  }
  
  /**
   * Total Rewards Claimed by Account
   */
  function accountBalance(address accountKey) external view returns (uint256) {
    return _balances[accountKey];
  }
  
  /**
   * Retrieve Game Supply
   */
  function gameTotalSupply(uint128 gameUuid) external view returns (uint256) {
    return _gameTotalSupply[gameUuid];
  }
  
  /**
   * Retrieve Game Remaining Supply
   */
  function gameRemainingSupply(uint128 gameUuid) external view returns (uint256) {
    return _gameRemainingSupply[gameUuid];
  }
  
  /**
   * Retrieve Game Rewarded Supply
   */
  function gameRewardedSupply(uint128 gameUuid) external view returns (uint256) {
    return _gameTotalSupply[gameUuid].sub(_gameRemainingSupply[gameUuid]);
  }
  
  /**
   * Retrieve Total Game Supply
   */
  function totalGameSupply() external view returns (uint256) {
    return _totalGameSupply;
  }
  
  /**
   * Retrieve Total Game Remaining Supply
   */
  function totalRemainingGameSupply() external view returns (uint256) {
    return _totalRemainingGameSupply;
  }
  
  /**
   * Retrieve Total Game Rewarded Supply
   */
  function totalRewardedGameSupply() external view returns (uint256) {
    return _totalGameSupply.sub(_totalRemainingGameSupply);
  }
  
  /*
   * Return Tokens back to Owner (useful if a contract upgrade takes place)
   */
  function transferBackToOwner() public onlyOwner returns (uint256) {
    address selfAddress = address(this);
    uint256 balanceOfContract = _rewardToken.balanceOf(selfAddress);
    _rewardToken.transfer(owner(), balanceOfContract);
    return balanceOfContract;
  }
}

contract BATLToken is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() {
    _name = "Battle Credits";
    _symbol = "BATL";
    _decimals = 18;
    _totalSupply = 0;
  }

  /**
   * @dev Returns the erc token owner.
   */
  function getOwner() external view override returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view override returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {ERC20-totalSupply}.
   */
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {ERC20-balanceOf}.
   */
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {ERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {ERC20-allowance}.
   */
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {ERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {ERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {ERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {ERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   * - `account` cannot be the zero address.
   */
  function mint(address account, uint256 amount) public onlyOwner returns (bool) {
    _mint(account, amount);
    return true;
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function burn(address account, uint256 amount) public onlyOwner returns (bool) {
    _burn(account, amount);
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
  }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

library VerifySignature {
    function getMessageHash(
        address _signer, address _for, uint128 _context, uint256 _amount, uint256 _amount2
    )
        internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_signer, _for, _context, _amount, _amount2));
    }
    
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal pure returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ECDSA.recover(_ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig)
        internal pure returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function hexStrToBytes(string memory _hexStr) internal pure returns (bytes memory)
    {
        //Check hex string is valid
        if (bytes(_hexStr)[0] != '0' ||
        bytes(_hexStr)[1] != 'x' ||
        bytes(_hexStr).length % 2 != 0 ||
        bytes(_hexStr).length < 4)
        {
            revert("hexStrToBytes: invalid input");
        }

        bytes memory bytes_array = new bytes((bytes(_hexStr).length - 2) / 2);

        for (uint i = 2; i < bytes(_hexStr).length; i += 2)
        {
            uint8 tetrad1 = 16;
            uint8 tetrad2 = 16;

            //left digit
            if (uint8(bytes(_hexStr)[i]) >= 48 && uint8(bytes(_hexStr)[i]) <= 57)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 48;

            //right digit
            if (uint8(bytes(_hexStr)[i + 1]) >= 48 && uint8(bytes(_hexStr)[i + 1]) <= 57)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 48;

            //left A->F
            if (uint8(bytes(_hexStr)[i]) >= 65 && uint8(bytes(_hexStr)[i]) <= 70)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 65 + 10;

            //right A->F
            if (uint8(bytes(_hexStr)[i + 1]) >= 65 && uint8(bytes(_hexStr)[i + 1]) <= 70)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 65 + 10;

            //left a->f
            if (uint8(bytes(_hexStr)[i]) >= 97 && uint8(bytes(_hexStr)[i]) <= 102)
                tetrad1 = uint8(bytes(_hexStr)[i]) - 97 + 10;

            //right a->f
            if (uint8(bytes(_hexStr)[i + 1]) >= 97 && uint8(bytes(_hexStr)[i + 1]) <= 102)
                tetrad2 = uint8(bytes(_hexStr)[i + 1]) - 97 + 10;

            //Check all symbols are allowed
            if (tetrad1 == 16 || tetrad2 == 16)
                revert("hexStrToBytes: invalid input");

            bytes_array[i / 2 - 1] = byte(16 * tetrad1 + tetrad2);
        }

        return bytes_array;
    }
    
    function verify(
        address _signer,
        address _for,
        uint128 _context,
        uint256 _amount,
        uint256 _amount2,
        string memory textSignature
    )
        internal pure returns (bool)
    {
        bytes32 messageHash = getMessageHash(_signer, _for, _context, _amount, _amount2);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        bytes memory signature = hexStrToBytes(textSignature);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}