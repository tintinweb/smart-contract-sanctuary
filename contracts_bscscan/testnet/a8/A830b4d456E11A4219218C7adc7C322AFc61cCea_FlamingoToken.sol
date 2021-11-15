// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";
import "./Staking.sol";


contract FlamingoToken is Context, Ownable, Staking {

  /**
   * @dev Public State Variables will automatically creates getter 
   * functions instead of hard coding relative functions
   */
  string public _name;
  string public _symbol;
  uint8 public _decimals;
  uint256 public _totalSupply;

  mapping(address => uint256) private _balances;

  /**
   * @dev mapping spender address over mapping of owner address
   * so spender can spend on behalf of owner
   * and be deductible from _allowance
   */
  mapping(address => mapping(address => uint256)) private _allowances;

  /**
   * @notice emitted after each time token has been moved around
   */
  event Transfer (address indexed from, address indexed to, uint256 value);

  /**
   * @notice  emitted on each approval 
   */
  event Approval ( address indexed owner, address indexed spender, uint256 value);

  

  constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_;
    _balances[msg.sender] = _totalSupply;
    

    emit Transfer(address(0), msg.sender, _totalSupply);
  }


  function getOwner() external view returns (address) {
    return owner();
  }

 
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    require(_allowances[sender][msg.sender] >= amount, "Flamingo: transfer exceeds allowance");
    _transfer(sender, recipient, amount);
    _approve( sender, msg.sender, _allowances[sender][msg.sender] - amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
    return true;
  }

  /**
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   * - `msg.sender` must be the token owner
   * - `_mintable` must be true
   */
  function mint(address account, uint256 amount) public onlyOwner returns (bool) {
    _mint(account, amount);
    return true;
  }

  /**
   * @dev Burn `amount` tokens and decreasing the total supply.
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
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "Flamingo: transfer from the zero address");
    require(recipient != address(0), "Flamingo: transfer to the zero address");
    require(_balances[sender] >= amount, "Flamingo: Transfer amount exceeds balance");
    _balances[sender] = _balances[sender] - amount;
    _balances[recipient] = _balances[recipient] + amount;
      
    emit Transfer(sender, recipient, amount);
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
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "Flamingo: approve from the zero address");
    require(spender != address(0), "Flamingo: approve to the zero address");
    _allowances[owner][spender] = amount;
    
    emit Approval(owner, spender, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *  - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "Flamingo: mint to the zero address");
    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "Flamingo: burn from the zero address");
    require(amount >= amount, "Flamingo: Burn amount excceds balance");
    _balances[account] = _balances[account] - amount;
    _totalSupply = _totalSupply - amount;
    
    emit Transfer(account, address(0), amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
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

  constructor() {
        _setOwner(_msgSender());
    }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
    }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Staking is a contract who is ment to be inherited by other
 * contracts to have staking capabilities
 */

contract Staking {

  /**
   * @dev storing each stake info. where user is the owner of the stake
   * amount is the stake value, since is a timestamp when staking begins,
   * and claimable is the  accumulated staking rewards*/
  struct Stake{
    address user;
    uint256 amount;
    uint256 since;
    uint256 claimable;
  }

  /**
   * @dev Stakers with active Stakes
   */
  struct Stakeholder{
    address user;
    Stake[] address_stakes;
  }

  /**
   * @dev Gives a Snapshot of StakingSummary of a specific account
   */
  struct StakingSummary{
    uint256 totalAmount;
    Stake[] stakes;
  }

  /**
   * @dev rewardPerHour is 0.1% for each staked token
   */
  uint256 internal rewardPerHour = 1000;
  /**
   * @dev an array of all stakes executed in the contract by all stakeholers
   */
  Stakeholder[] internal stakeholders;

  /**
   * @dev mapping the staker address(key/index) to the Stake in the stakes array
  */
  mapping (address => uint256) internal stakes;

  event Staked(address indexed user, uint256 amount, uint index, uint256 timestamp);

  constructor() {
    stakeholders.push();
  }

  function _addStakeholder(address staker) internal returns (uint256) {
    // Push an empty item to the array to make space for stakholder
    stakeholders.push();
    // Calculate the index of the last item in the array
    uint userIndex = stakeholders.length - 1;
    // Assign address to the new stakeholder
    stakeholders[userIndex].user = staker;
    // add the index to the stakeholders
    stakes[staker] = userIndex;
    return userIndex;
  }
  /**
   * @dev _Stake is used to make a stake for an sender. It will remove the amount 
   * staked from the stakers account and place those tokens inside a stake container StakeID 
   */
  function _stake(uint256 _amount) internal{
    // Simple check so that user does not stake 0
    require(_amount > 0, "Cannot stake nothing");
    // Mappings in solidity creates all values, but empty, so we can just check the address
    uint256 index = stakes[msg.sender];
    // block.timestamp = timestamp of the current block in seconds since the epoch
    uint256 timestamp = block.timestamp;
    // See if the staker already has a staked index or if its the first time
    if(index == 0){
      // This stakeholder stakes for the first time
      // We need to add him to the stakeHolders and also map it into the Index of the stakes
      // The index returned will be the index of the stakeholder in the stakeholders array
      index = _addStakeholder(msg.sender);
    }
    // Use the index to push a new Stake
    // push a newly created Stake with the current block timestamp.
    stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
    // Emit an event that the stake has occured
    emit Staked(msg.sender, _amount, index,timestamp);
  }

  /**
   * @dev calculateStakeReward is used to calculate how much a user should be rewarded for 
   * their stakes and the duration the stake has been active
   */
  function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
    // First calculate how long the stake has been active
    // Use current seconds since epoch - the seconds since epoch the stake was made
    // The output will be duration in SECONDS ,
    // We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
    // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
    // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
    // we then multiply each token by the hours staked , then divide by the rewardPerHour rate 
    return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
  }

  /**
   * @notice
   * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
   * Notice index of the stake is the users stake counter, starting at 0 for the first stake
   * Will return the amount to MINT onto the acount
   * Will also calculateStakeReward and reset timer
   */
  function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
    // Grab user_index which is the index to use to grab the Stake[]
    uint256 user_index = stakes[msg.sender];
    Stake memory current_stake = stakeholders[user_index].address_stakes[index];
    require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

    // Calculate available Reward first before we start modifying data
    uint256 reward = calculateStakeReward(current_stake);
    // Remove by subtracting the money unstaked 
    current_stake.amount = current_stake.amount - amount;
    // If stake is empty, 0, then remove it from the array of stakes
    if(current_stake.amount == 0){
      delete stakeholders[user_index].address_stakes[index];
    }else {
      // If not empty then replace the value of it
      stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
      // Reset timer of stake
      stakeholders[user_index].address_stakes[index].since = block.timestamp;
    }
    return amount+reward;
  }

  /**
   * @dev hasStake is used to check if a account has stakes and the total amount 
   * along with all the seperate stakes
   */
  function hasStake(address _staker) public view returns(StakingSummary memory){
    uint256 totalStakeAmount;
    StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
    for (uint256 s=0; s< summary.stakes.length; s+= 1){
      uint256 availableRewards = calculateStakeReward(summary.stakes[s]);
      summary.stakes[s].claimable = availableRewards;
      totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
    }
    summary.totalAmount = totalStakeAmount;
    return summary;
  }

}

