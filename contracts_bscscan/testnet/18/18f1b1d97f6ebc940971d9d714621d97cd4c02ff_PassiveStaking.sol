/**
 *Submitted for verification at BscScan.com on 2021-09-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
* @dev Interface of the BEP20 standard as defined in the EIP.
*/
interface IBEP20 {
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
    * Can only be called by the current owner.
    */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
* Passive Staking is made to change and improve DeFi sector for the better.
* Made by Heisenberg Soul
*/
contract PassiveStaking is Ownable, IBEP20 {
    mapping (address => uint256) private _stakingBalance;
    mapping (address => uint256) private _stakingFromBlock;
    mapping (address => uint256) private _stakingPool;
    mapping (address => uint256) private _rewardsRecieved;
    mapping (address => bool) private _isExcluded;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public initialSupply;
    uint256 private _totalSupply;

    uint256[] private _blocks;

    bool public stakingActivated;

    uint256 public stakingStartBlock;
    uint256 public rewardPerBlock = 2 * 10**16;
    uint256 public initialStakingPool;

    string private _name;
    string private _symbol;

    /**
    * @dev Sets the values for {name} and {symbol}.
    *
    * The defaut value of {decimals} is 18
    *
    * All two of these values are immutable: they can only be set once during
    * construction.
    */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        initialSupply = 1000000 * 10**18;
        _totalSupply = initialSupply;
        _stakingBalance[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
    * @dev Returns the name of the token.
    */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
    * @dev Returns the symbol of the token, usually a shorter version of the
    * name.
    */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    * For example, if `decimals` equals `2`, a balance of `505` tokens should
    * be displayed to a user as `5,05` (`505 / 10 ** 2`).
    *
    * Tokens usually opt for a value of 18, imitating the relationship between
    * Ether and Wei. This is the value {BEP20} uses, unless this function is
    * overridden;
    *
    * NOTE: This information is only used for _display_ purposes: it in
    * no way affects any of the arithmetic of the contract, including
    * {IBEP20-balanceOf} and {IBEP20-transfer}.
    */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
    * @dev See {IBEP20-totalSupply}.
    */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {IBEP20-balanceOf}.
    * If tokens received before an activation of passive staking then a token owner is staking from {initialStakingPool}
    */
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account] == true || stakingActivated == false) {
           return _stakingBalance[account];
        }
        uint256 poolReward = rewardPerBlock * (block.number - _blocks[_stakingFromBlock[account]]);
        if (_stakingFromBlock[account] == 0) {
            uint256 addressBalance = _stakingBalance[account] * (initialStakingPool + poolReward) / initialStakingPool;
            return addressBalance;
        } else {
            uint256 addressBalance = _stakingBalance[account] * (_stakingPool[account] + poolReward) / _stakingPool[account];
            return addressBalance;
        }
    }

    /**
    * @dev The power "button"
    */
    function stakingActivation() public onlyOwner {
        require(stakingActivated == false, "Passive Staking is already activated");
        stakingStartBlock = block.number;
        _blocks.push(stakingStartBlock);
        uint256 stakingPool = currentStakingPool();
        initialStakingPool = stakingPool;
        stakingActivated = true;
        _isExcluded[msg.sender] = true;
        _isExcluded[address(0)] = true;
    }

    /**
    * @notice Calculates current staking pool.
    * @dev stakingPool variable always updates on a full reward.
    * Address balance updates on a reward depending on a pool share.
    * The pool share will be constant if a token owner will send n-times his updated balance to himself.
    * If a transfer was made between two addresses then a sum of pool shares will be less on 1 (1**(-18) in usual form)
    * or equal to a sum of pool shares before the transfer.
    */
    function currentStakingPool() public view returns (uint256) {
        uint256 stakingPool = initialSupply + rewardPerBlock * (block.number - _blocks[0]);
        return stakingPool;
    }

   /**
   * @notice Excludes DEX contract address from passive staking to avoid problems with price.
   */
    function excludeContract(address account) public onlyOwner {
        require(_isContract(account) == true, "The address is not a contract");
        _isExcluded[account] = true;
    }

    /**
    * @notice Function for frontend.
    * @dev The function will return an error if passive staking is not activated.
    * To get accurate addressPoolShare (and non-zero value) we multiply on {rewardPerBlock}
    * and divide on the same value in the frontend.
    */
    function addressInfo(address account) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 stakingBalance = _stakingBalance[account];
        if (_isExcluded[account] == true) {
            return (stakingBalance, 0, 0, 0, 0, 0, 0);
        } else {
            uint256 stakingPeriod = block.number - _blocks[_stakingFromBlock[account]];
            uint256 currentReward = balanceOf(account) - stakingBalance;
            uint256 stakingPool;
            if (_stakingFromBlock[account] == 0) {
                stakingPool = initialStakingPool;
            } else {
                stakingPool = _stakingPool[account];
            }
            uint256 rewardsRecieved = currentReward + _rewardsRecieved[account];
            uint256 addressPoolShare = stakingBalance * rewardPerBlock / stakingPool;
            uint256 addressRewardPerBlock = stakingBalance * rewardPerBlock / stakingPool;
            return (stakingBalance, stakingPeriod, currentReward, stakingPool, rewardsRecieved, addressPoolShare, addressRewardPerBlock);
        }
    }

    /**
    * @dev See {IBEP20-transfer}.
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
    * @dev See {IBEP20-allowance}.
    */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @dev See {IBEP20-approve}.
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
    function burn(uint256 amount) public {
        address sender = _msgSender();
        _beforeTokenTransfer(sender, address(0), amount);

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "BEP20: burn amount exceeds balance");

        uint256 senderReward = senderBalance - _stakingBalance[sender];
        _stakingBalance[sender] = senderBalance - amount;
        _rewardsRecieved[sender] += senderReward;
        _totalSupply += senderReward;
        _totalSupply -= amount;

        if (stakingActivated == true) {
            uint256 stakingPool = currentStakingPool();
            _stakingPool[sender] = stakingPool;

            _blocks.push(block.number);
            _stakingFromBlock[sender] = _blocks.length - 1;
        }

        emit Transfer(sender, address(0), amount);
    }

    /**
    * @dev See {IBEP20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {BEP20}.
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
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
    * @dev Atomically increases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IBEP20-approve}.
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
    * problems described in {IBEP20-approve}.
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
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

        if (_isExcluded[sender] == true || stakingActivated == false) {
            _stakingBalance[sender] = senderBalance - amount;
            if (stakingActivated == true) {
                uint256 recipientBalance = balanceOf(recipient);
                uint256 recipientReward = recipientBalance - _stakingBalance[recipient];
                _stakingBalance[recipient] = recipientBalance + amount;
                _rewardsRecieved[recipient] += recipientReward;
                _totalSupply += recipientReward;

                uint256 stakingPool = currentStakingPool();
                _stakingPool[recipient] = stakingPool;

                _blocks.push(block.number);
                _stakingFromBlock[recipient] = _blocks.length - 1;
            } else {
                _stakingBalance[recipient] += amount;
            }

            emit Transfer(sender, recipient, amount);
        } else {
            uint256 senderReward = senderBalance - _stakingBalance[sender];
            _stakingBalance[sender] = senderBalance - amount;
            _rewardsRecieved[sender] += senderReward;
            _totalSupply += senderReward;

            if (sender != recipient) {
                uint256 recipientBalance = balanceOf(recipient);
                uint256 recipientReward = recipientBalance - _stakingBalance[recipient];
                _stakingBalance[recipient] = recipientBalance + amount;
                _rewardsRecieved[recipient] += recipientReward;
                _totalSupply += recipientReward;
            } else {
                _stakingBalance[recipient] += amount;
            }

            uint256 stakingPool = currentStakingPool();
            _stakingPool[sender] = stakingPool;
            _stakingPool[recipient] = stakingPool;

            _blocks.push(block.number);
            _stakingFromBlock[sender] = _blocks.length - 1;
            _stakingFromBlock[recipient] = _blocks.length - 1;

            emit Transfer(sender, recipient, amount);
        }
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
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
    * @dev Returns true if `account` is a contract.
    *
    * [IMPORTANT]
    * ====
    * It is unsafe to assume that an address for which this function returns
    * false is an externally-owned account (EOA) and not a contract.
    *
    * Among others, `isContract` will return false for the following
    * types of addresses:
    *
    *  - an externally-owned account
    *  - a contract in construction
    *  - an address where a contract will be created
    *  - an address where a contract lived, but was destroyed
    * ====
    */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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