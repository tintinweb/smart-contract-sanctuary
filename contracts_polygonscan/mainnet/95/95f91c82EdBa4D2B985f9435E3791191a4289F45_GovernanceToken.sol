// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./openzeppelin/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovernanceToken is Ownable, ERC20 {
  using SafeMath for uint256;

  address public voteMachineAddress;
  address public DAOAddress;

  address[] internal stakeholders;

  mapping(address => uint256) internal stakes;

  mapping(address => uint256[2][]) public vestingSchedules;

  
  mapping (address =>bool) public isStakeholder;
  uint256 public numberOfStakeholders;
  uint256 public totalStakes;
  uint256 public constant maxVestingEntries = 52*3;



  constructor () ERC20("Issuaa Protocol Token", "IPT") {    
    
  }

  /**
  * @notice A method that sets the address of the vote machine contract.
  * @param _address Address of the vote machine contract.
  */
  function setVoteMachineAddress(
    address _address
    ) 
    external 
    onlyOwner 
    {
    voteMachineAddress = _address;
    }

  /**
  * @notice A method that sets the address of the DAO contract.
  * @param _address Address of the DAO contract.
  */
  function setDAOAddress(
    address _address
    ) 
    external 
    onlyOwner 
    {
    DAOAddress = _address;
    }


  /**
  * @notice A method that mints new governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  */
  function mint(
    address _address, 
    uint256 _amount
    ) 
    external 
    onlyOwner 
    {
  	_mint(_address, _amount);
  }

  /**
  * @notice A method that mints and automatically vests new governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  *        _time Time for which the stake is locked
  */
  function mintAndVest(
    address _address,
    uint256 _amount, 
    uint256 _time
    ) 
    external 
    onlyOwner 
    {
    require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
    require (vestingSchedules[_address].length<maxVestingEntries,"TOO_MANY_VESTING_ENTRIES");

    if (stakes[_address] == 0) {
      isStakeholder[_address] = true;
      numberOfStakeholders = numberOfStakeholders + 1;
    }
    stakes[_address] = stakes[_address].add(_amount);
  	vestingSchedules[_address].push([block.timestamp.add(_time),_amount]);
  }

  /**
  * @notice A method that transfers and vests governance tokens.
  * @param _address Address that receives the staked and vesting governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  *        _time Time for which the stake is locked
  */
  function transferAndVest(
    address _address, 
    uint256 _amount,
    uint256 _time
    )
    external
    {
      require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
      require (vestingSchedules[_address].length<10,"TOO_MANY_VESTING_ENTRIES");
      require (_amount > 999 * (10**18),'AMOUNT_TOO_LOW');
      _burn(msg.sender, _amount);
      if (stakes[_address] == 0) {
        isStakeholder[_address] = true;
        numberOfStakeholders = numberOfStakeholders + 1;
      }
      stakes[_address] = stakes[_address].add(_amount);
      vestingSchedules[_address].push([block.timestamp.add(_time),_amount]);

    }
  



  /**
  * @notice A method that burns governance tokens. Can only be called by the owner.
  * @param _address Address that receives the governance tokens.
  *        _amount Amount to governance tokens to be minted in WEI.
  */
  function burn(
    address _address,
    uint256 _amount
    ) 
    external 
    onlyOwner {
    _burn(_address, _amount);
  }

  

  

  /**
  * @notice A method to retrieve the stake for a stakeholder.
  * @param _stakeholder The stakeholder to retrieve the stake for.
  * @return uint256 The amount of wei staked.
  */
  function stakeOf(
    address _stakeholder
    )
  	public
    view
    returns(uint256)
  	{
     	return stakes[_stakeholder];
  }

  /**
  * @notice A method to the aggregated stakes from all stakeholders.
  * @return uint256 The aggregated stakes from all stakeholders.
  */
  /*function totalStakes()
   	public
   	view
   	returns(uint256)
  	{
   	uint256 _totalStakes = 0;
   	for (uint256 s = 0; s < stakeholders.length; s += 1){
    	_totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
   	}
   	return _totalStakes;
  }
  */

  /**
  * @notice A method for a stakeholder to create a stake.
  * @param _stake The size of the stake to be created.
  */
  function createStake(
    uint256 _stake
    )
  	public
  	{
       	_burn(msg.sender, _stake);
       	if(stakes[msg.sender] == 0) {
          isStakeholder[msg.sender] = true;
          numberOfStakeholders = numberOfStakeholders + 1;
        }
       	stakes[msg.sender] = stakes[msg.sender].add(_stake);
        totalStakes = totalStakes + _stake;
  }


  /**
  * @notice A method for a stakeholder to remove a stake.
  * @param _stake The size of the stake to be removed.
  */
  function removeStake(
    uint256 _stake
    )
  	public
  	{
   	uint256 freeStake = stakes[msg.sender] - getVestingStake(msg.sender);
   	
   	require (freeStake >= _stake,'Not enough free stake');

   	stakes[msg.sender] = stakes[msg.sender].sub(_stake);
   	if(stakes[msg.sender] == 0) {
      isStakeholder[msg.sender] = false;
      numberOfStakeholders = numberOfStakeholders - 1;
    }
   	_mint(msg.sender, _stake);

   	for (uint256 i = 0; i < vestingSchedules[msg.sender].length; i += 1){
  		if(vestingSchedules[msg.sender][i][0] < block.timestamp) {
        vestingSchedules[msg.sender][i] = vestingSchedules[msg.sender][vestingSchedules[msg.sender].length-1];
        vestingSchedules[msg.sender].pop();
        
      }
  	}

    totalStakes = totalStakes - _stake;
  }

  /**
  * @notice A method to get the vesting schedule of a stakeholder
  * @param _stakeholder The address of the the stakeholder
  */
  function vestingSchedule(
    address _stakeholder
    )
  	public
  	view
  	returns(uint256[2][] memory)
  	{
   	uint256[2][] memory schedule = vestingSchedules[_stakeholder];
   	return schedule;
  }
   		
  /**
  * @notice A method to get the currently vesting stake of a stakeholder
  * @param _address The address of the the stakeholder
  */
 	function getVestingStake(
    address _address
    )
 		public
 		view
 		returns (uint256)
 		{
		uint256[2][] memory schedule = vestingSchedule(_address);
 		uint256 vestedStake = 0;
 		for (uint256 i=0; i < schedule.length;i++){
 		  if (schedule[i][0] > block.timestamp) {vestedStake = vestedStake.add(schedule[i][1]);}
 		  }
 		return vestedStake;
 	}


  /**
  * @notice A method to increase the minimum vesting period to a given timestamp.
  * @param _address The address of the the stakeholder
  *        _timestamp The time until when the vesting is prolonged
  */
  function setMinimumVestingPeriod(
    address _address,
    uint256 _timestamp
    )
    internal
    {
    require (_timestamp < block.timestamp + 731 days,"VESTING_PERIOD_TOO_LONG");
    uint256[2][] memory schedule = vestingSchedule(_address);
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] < _timestamp && schedule[i][0] > block.timestamp) {vestingSchedules[_address][i][0] = _timestamp;}
      }
    }


  /**
  * @notice A method to get the locked stake of a stakeholder at a given time
  * @param _address The address of the the stakeholder
  * @param _time The time in the future
  */
  function getFutureLockedStake(
    address _address, 
    uint256 _time
    )
    public
    view
    returns (uint256)
    {
    uint256[2][] memory schedule = vestingSchedule(_address);
    uint256 lockedStake = 0;
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] > _time) {lockedStake = lockedStake.add(schedule[i][1]);}
      }
    return lockedStake;
  }

 	/**
  * @notice A method for a stakeholder to lock a stake.
  * @param _stake The size of the stake to be vested.
  		 _time The time until the stake becomes free again in seconds
  */
  /**
 	function lockStake(
    uint256 _stake, 
    uint256 _time
    )
  	public
 		{
    require (_time < 731 days,"VESTING_PERIOD_TOO_LONG");
    uint256[2][] memory schedule = vestingSchedule(msg.sender);
    uint256 lockedStake = 0;
    for (uint256 i=0; i>schedule.length;i++){
   	  if (schedule[i][0] > block.timestamp) {lockedStake = lockedStake.add(schedule[i][1]);}
   	  
    }
    uint256  currentStake = stakeOf(msg.sender);
    uint256  unlockedStake = currentStake.sub(lockedStake);
    require (unlockedStake >= _stake,'Not enough free stake available');
    vestingSchedules[msg.sender].push([block.timestamp.add(_time),_stake]);
  }
  **/

  /**
  * @notice A method for that locks a stake during a voting process.
  * @param
    _address Address that will locks its stake 
    _stake The size of the stake to be locked.
    _timestamp The timestamp of the time until the stake is locked
  */
  function lockStakeForVote(
    address _address, 
    uint256 _timestamp
    )
    external
    {
    require (msg.sender == voteMachineAddress || msg.sender == DAOAddress,"NOT_VM_ADRESS");
    uint256[2][] memory schedule = vestingSchedule(_address);
    uint256 lockedStake = 0;
    for (uint256 i=0; i < schedule.length;i++){
      if (schedule[i][0] > block.timestamp) {lockedStake = lockedStake.add(schedule[i][1]);}
      
    }
    uint256  currentStake = stakeOf(_address);
    uint256  unlockedStake = currentStake.sub(lockedStake);
    vestingSchedules[_address].push([_timestamp,unlockedStake]);
    setMinimumVestingPeriod(_address,_timestamp);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
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

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
//import "./IERC20.sol";
//import "./IERC20Metadata.sol";
//import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

