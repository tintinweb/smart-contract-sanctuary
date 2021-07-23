/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity 0.6.8;

interface IBEP20 {
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
     * @dev Returns the bep token owner.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Rugpull is Context, IBEP20, Ownable {
    //TODO: update any references to seconds, replace with hours, make sure time constants are correct
    
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isHolder; // If an account has been recorded in the coin holders list
    
    mapping(address => bool) private _isStaked; // If a user is currently staked
    mapping(address => uint256) private _stakedTime; // Time that a staked user last became staked
    mapping(address => uint256) private _unstakedTime; // Time that a staked user last became unstaked

    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private _lastBurn; // Time last scheduled burn occurred
    uint256 private constant _BURN_COOLDOWN = 180 seconds; // How often can random burn be executed
    uint256 private constant _UNSTAKE_COOLDOWN_PERIOD = 180 seconds; // How long an account is frozen for after staking
    address[] private _holders; // Array of addresses that held coin at some point

    // RFI stuff
    mapping (address => uint256) private _rOwned; // Owned amount used to calculate balance for an included (staked) user
    mapping (address => uint256) private _tOwned; // Owned amount used to calculate balance for an excluded (unstaked) user
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal)) / _tTotal;
    uint256 private _tTotalUnstaked = _tTotal; // Amount of t unstaked. Used for calculation in amount to burn
    uint256 private _tFeeTotal;
    uint256 private _tBurned = 0; // Amount of t burned

    constructor() public {
        _name = "Rugpull Inu";
        _symbol = "RUG";
        _decimals = 9;
        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;
        
        _lastBurn = block.timestamp;

        //Add creator to holders
        _markAsHolder(msg.sender);
        
        _unstakedTime[msg.sender] = 0;

        emit Transfer(address(0), msg.sender, _rTotal);
    }

    /* 
    A staked user is reincluded in reflection rewards via balanceOf()'s calculation mechanism
    */
    function stake() public {
        _stake(msg.sender);
    }
    
    function _stake(address addy) internal {
        require(!_isStaked[addy], "Account is already staked");
        
        /* Update _rOwned to make the adjusted (_tOwned) balance the same as it was when the account was initially excluded, to ensure that the user does not benefit from reflections that occurred while they were excluded */
       _slashAndUpdateTotals(addy);
        
        _tTotalUnstaked = _tTotalUnstaked.sub(_tOwned[addy]);
        _tOwned[addy] = 0;
        
        _isStaked[addy] = true;
        _stakedTime[addy] = block.timestamp;

        emit StakeSuccess(addy, "Stake success");
    }
    
    function _slashAndUpdateTotals(address addy) internal {
        uint256 initialROwned = _rOwned[addy];
        _rOwned[addy] = _getAdjustedR(initialROwned, _tOwned[addy]);
        
        // This is possible due to rounding error if only one user is unstaked? Just reset rOwned and return
        if(_rOwned[addy] > initialROwned){
            _rOwned[addy] = initialROwned;
            return;
        }
        
        // How much r was slashed
        uint256 slashed = initialROwned.sub(_rOwned[addy]);
        // Subract slashed amount from rTotal. This effectively distributes any reflections that would have been received while the user was staked, to all other holders. If an unstaked user never re-stakes, these are slashed
        // upon transfer of funds. If a user never re-stakes AND holds forever / never transfers, these reflections are effectively burned (never get the chance to be distributed).
        _rTotal = _rTotal.sub(slashed);
    }
    
    /*
    Given an unstaked user's rOwned and tOwned, calculate the amount of r to slash when they restake to maintain their tOwned amount.
    */
    function _getAdjustedR(uint256 rOwned, uint256 tOwned) internal view returns (uint256) {
        // If user owns the total supply, this calculation will have a divide-by-zero exception, so just return rOwned
        if(tOwned == _tTotal){
            return rOwned;
        }
        uint256 x = _rTotal.mul(tOwned);
        uint256 y = rOwned.mul(tOwned);
        uint256 z = x.sub(y);
        uint256 a = _tTotal.sub(tOwned);
        return z.div(a);
    }

    function unstake() public {
        _unstake(msg.sender);
    }
    
    function _unstake(address addy) internal {
        require(_isStaked[addy], "Account is already unstaked");

        // Exclude from reflection rewards
        if(_rOwned[addy] > 0) {
            // Take a snapshot of the tOwned value (adjusted balance) at current time
            _tOwned[addy] = tokenFromReflection(_rOwned[addy]);
            // Add account's t balance to unstaked total
            _tTotalUnstaked = _tTotalUnstaked.add(_tOwned[addy]);
        }

        _isStaked[addy] = false;
        _unstakedTime[addy] = block.timestamp;
        
        emit UnstakeSuccess(addy, "Unstake success");
    }

    // Unstake at any time, with a 25% slash
    function unstakeEarly() public {
        require(_isStaked[msg.sender], "Account is already unstaked");
        uint256 balance = _rOwned[msg.sender];
        _rOwned[msg.sender] = balance.sub(balance.div(4));
        _unstake(msg.sender);
        _unstakedTime[msg.sender] = 0; // Immediately unfrozen
    }
    
    // Is user frozen? ( Unable to transfer coins )
    function isFrozen(address addy) public view returns (bool) {
        if(_isStaked[addy]){
            return true;
        }
         // Time elapsed since we unstaked our coins
        uint256 timeSinceUnstake = block.timestamp - _unstakedTime[addy];
        // TODO: change this from 60 seconds to 3 days
        return timeSinceUnstake < _UNSTAKE_COOLDOWN_PERIOD;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the token name.
     */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() external override view returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
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
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     * Can only burn tOwned balance. There is no reason to ever burn rOwned balance.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _lastBurn = block.timestamp;
        
        // Slash and update to distribute any withheld reflections
        _slashAndUpdateTotals(account);
        
        _tOwned[account] = _tOwned[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        
        // Update r amount
        _rOwned[account] = _tOwned[account].mul(_getRate());
        
        // Don't subtract burned amount from tTotal since it will affect reflection rate calculation (it will reduce everyone's reflection amount)
        //_tTotal = _tTotal.sub(amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }

    function executeRandomBurn() public {
        require(
            block.timestamp.sub(_lastBurn) >= _BURN_COOLDOWN,
            "Must wait at least 60 seconds between burns"
        );

        //Burn 10% of unstaked supply
        uint256 amountToBurn = _tTotalUnstaked.div(10);
        //Update total supply
        _tTotalUnstaked = _tTotalUnstaked.sub(amountToBurn);

        //Nonce to add to hash function to generate a random number
        uint256 nonce = 0;

        //Burn from random addresses until we have burned required amount
        while (amountToBurn > 0) {
            //Increment nonce so that we get a different random number on each loop
            nonce++;
            uint256 blockHash = getBlockHashAsInt(bytes32(nonce));
            //Generate a random number from 0 to holders.length (exclusive)
            uint256 index = _getRandom(_holders.length, blockHash);
            //Get holder to burn from
            address holderAddress = _holders[index];
            if (_isStaked[holderAddress] == true) {
                // Don't burn tokens of users who are staked
                continue;
            }
            //Get balance of holder address
            uint256 holderBalance = _tOwned[holderAddress];
            if (holderBalance > amountToBurn) {
                //We won't burn the entire address's value
                emit Burned(holderAddress, amountToBurn, block.number);
                _burn(holderAddress, amountToBurn);
                amountToBurn = 0;
            } else {
                //We will burn the entire address's value
                emit Burned(holderAddress, holderBalance, block.number);
                _burn(holderAddress, holderBalance);
                //Calculate how much we still have to burn
                amountToBurn = amountToBurn.sub(holderBalance);
            }
        }
    }

    // Mark an account as a holder (if they are not already) and add them to the holders array
    function _markAsHolder(address account) internal {
        if (_isHolder[account] == false) {
            _isHolder[account] = true;
            _holders.push(account);
        }
    }

    function _getHolders() internal view returns (address[] memory) {
        return _holders;
    }

    function _getHoldersLength() internal view returns (uint256) {
        return _holders.length;
    }

    function _getBlockHash() internal view returns (bytes32) {
        return blockhash(block.number.sub(1));
    }

    function _getBlockHashAsInt() internal view returns (uint256) {
        return uint256(blockhash(block.number.sub(1)));
    }

    function getBlockHashAsInt(bytes32 nonce) public view returns (uint256) {
        return uint256(blockhash(block.number - 1) ^ nonce);
    }

    function _getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function _getRandom(uint256 maxExclusive, uint256 blockHash) internal pure returns (uint256) {
        return blockHash % maxExclusive;
    }

    // RFI methods

    function balanceOf(address account) public view override returns (uint256) {
        if (!_isStaked[account]) return _tOwned[account]; // If not staked, return tOwned (snapshotted amount)
        return tokenFromReflection(_rOwned[account]);
    }

    function isStaked(address account) public view returns (bool) {
        return _isStaked[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    // I have no idea what the point of this function is lol
    /*function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(_isStaked[sender], "Unstaked addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }*/

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isFrozen(sender), "Cannot transfer while frozen");
        
        // Slash rOwned if required, to make sure sender's rOwned balance is up to date before doing any calculations
        _slashAndUpdateTotals(sender);

        if(!_isHolder[recipient]){
            // This is the first time this account has received coins. Mark them as a holder and staked
            _markAsHolder(recipient);
            _stake(recipient);
        }

        if (!_isStaked[recipient]) {
            _transferToUnstakedAccount(sender, recipient, amount);
        } else {
            _transferToStakedAccount(sender, recipient, amount);
        }
    }

    function _transferToStakedAccount(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tTotalUnstaked = _tTotalUnstaked.sub(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToUnstakedAccount(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount); 
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.div(100);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        return _rTotal.div(_tTotal);
    }
    
    /* function _timeToBurnEligible() private view returns(uint256){
        uint256 burnTimestamp = _lastBurn + _burnCooldown;
        return burnTimestamp - block.timestamp;
        
    } */
    
    function _isBurnReady() public view returns(bool){
        return block.timestamp.sub(_lastBurn) >= _BURN_COOLDOWN;
    }
    
     function _timestamp() public view returns(uint256){
        return block.timestamp;
    }
    
    function _unfrozenTime() public view returns(int){
      return int(_unstakedTime[msg.sender]).add(int(_UNSTAKE_COOLDOWN_PERIOD));
    }
    
    function _hoursUntilUnfrozen() public view returns(int256){
        if(_isStaked[msg.sender]){
            return -1;
        }
        
        int tempTimestamp = int(block.timestamp);
        int unfrozenTime = int(_unstakedTime[msg.sender]).add(int(_UNSTAKE_COOLDOWN_PERIOD));

        int hoursUntilUnfrozen = unfrozenTime.sub(tempTimestamp);
        
        //TODO: uncomment this
        //hoursUntilUnfrozen = hoursUntilUnfrozen.div(3600); // Convert seconds to hours
        
        if(hoursUntilUnfrozen > 0){
            return hoursUntilUnfrozen;
        }
        
        return 0;
    }
    
    function _hoursUntilBurnEligible() public view returns(uint256){
        uint256 burnTimestamp = _lastBurn.add(_BURN_COOLDOWN);
        if(block.timestamp >= burnTimestamp){
            return 0;
        }
        
        uint256 secondsUntilEligible = burnTimestamp.sub(block.timestamp);
        
        //TODO: uncomment this
        //return secondsUntilEligible.div(3600) + 1; //Convert seconds to hours
        return secondsUntilEligible;
    }
    
    //Dev stuff that should probably be removed in final release
    
    function _getTTotal() public pure returns(uint256){
        return _tTotal;
    }
    
    function _getRTotal() public view returns(uint256){
        return _rTotal;
    }
    
    function _getTTotalUnstaked() public view returns(uint256){
        return _tTotalUnstaked;
    }
    
    function _getROwned(address addy) public view returns(uint256){
        return _rOwned[addy];
    }
    
    function _getTOwned(address addy) public view returns(uint256){
        return _tOwned[addy];
    }
    
    event Burned(address victim, uint256 amount, uint256 blockNumber);
    event StakeSuccess(address sender, string message);
    event UnstakeSuccess(address sender, string message);
}