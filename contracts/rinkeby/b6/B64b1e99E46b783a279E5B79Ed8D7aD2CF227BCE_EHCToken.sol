// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require((allowance(_msgSender(), spender) == 0) || (amount == 0), "ERC20: change allowance use increaseAllowance or decreaseAllowance instead");
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
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @notice EHC token contract (ERC20)
 */
contract EHCToken is ERC20, Pausable, Ownable, IEHCToken {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
    // @dev The Asset contract as mining reward: ETH on bsc mainnet
    //IERC20 public immutable MiningAssetContract = IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);

    // dummy asset on rinkeby
    IERC20 public immutable MiningAssetContract = IERC20(0xDae124171F8aaFA6E64c802fb7e39Bb3e1bF2732);

    // @dev buy back & burn contract
    // this contract is replacable in case of bug in this contract
    //IBIMBuyBack public BurnBimContract = IBIMBuyBack(0xD18d7120dad561760e3841880447Ef4075D9FE29);

    // dummy contract on rinkeby
    IBIMBuyBack public BurnBimContract = IBIMBuyBack(0x4786a33C492d865fF5af11c7BA7D7Fc1bB17bC13);

    
    // @dev manager's address
    address public managerAddress;
    
    // @dev staking address
    address public stakingAddress;

   /**
     * @dev Emitted when an account is set mintable
     */
    event Mintable(address account);
    /**
     * @dev Emitted when an account is set unmintable
     */
    event Unmintable(address account);
    
    // @dev mintable group
    mapping(address => bool) public mintableGroup;
    
    modifier onlyMintableGroup() {
        require(mintableGroup[msg.sender], "EHC: not in mintable group");
        _;
    }

    mapping(address => TimeLock) private _timelock;

    event BlockTransfer(address indexed account);
    event AllowTransfer(address indexed account);

    struct TimeLock {
        uint256 releaseTime;
        uint256 amount;
    }

    /**
     * @dev Initialize the contract give all tokens to the deployer
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        setMintable(owner(), true);
        _mint(_msgSender(), _initialSupply * (10 ** uint256(_decimals)));
    }
    
    /**
     * @dev set or remove address to mintable group
     */
    function setMintable(address account, bool allow) public onlyOwner {
        mintableGroup[account] = allow;
        if (allow) {
            emit Mintable(account);
        }  else {
            emit Unmintable(account);
        }
    }

    /**
     * @notice set manager's address
     */
    function setManagerAddress(address account) external onlyOwner {
        require (account != address(0), "0 address");
        managerAddress = account;
    }
    
    /**
     * @notice set buyback's address
     */
    function setBuyBackAddress(address account) external onlyOwner {
        require (account != address(0), "0 address");
        BurnBimContract = IBIMBuyBack(account);
    }
    
    /**
     * @notice set staking's address
     */
    function setStakingAddress(address account) external onlyOwner {
        require (address(account) != address(0), "0 address");
        stakingAddress = account;
    }

    /**
     * @dev update function to distribute mining rewards
     */
    function distribute() external override {
        uint newRewards = MiningAssetContract.balanceOf(address(this));
        if (newRewards > 0) {
            uint stakingRewards = newRewards.mul(70).div(100);
            uint managerRewards = newRewards.mul(15).div(100);
            
            MiningAssetContract.safeTransfer(stakingAddress, stakingRewards);
            MiningAssetContract.safeTransfer(managerAddress, managerRewards);
            MiningAssetContract.safeTransfer(address(BurnBimContract), MiningAssetContract.balanceOf(address(this)));
            
            // call burn 
            BurnBimContract.burn();
        }
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
    function mint(address account, uint256 amount) public override onlyMintableGroup {
        _mint(account, amount);
        
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "EHC: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }


    /**
     * @dev View `account` locked information
     */
    function timelockOf(address account) public view returns(uint256 releaseTime, uint256 amount) {
        TimeLock memory timelock = _timelock[account];
        return (timelock.releaseTime, timelock.amount);
    }

    /**
     * @dev Release the specified `amount` of locked amount
     * @notice only Owner call
     */
    function release(address account, uint256 releaseAmount) public onlyOwner {
        require(account != address(0), "EHC: release zero address");

        TimeLock storage timelock = _timelock[account];
        timelock.amount = timelock.amount.sub(releaseAmount);
        if(timelock.amount == 0) {
            timelock.releaseTime = 0;
        }
    }

    /**
     * @dev Triggers stopped state.
     * @notice only Owner call
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * @notice only Owner call
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * @dev transfer with lock 
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - releaseTime.
     */
    function transferWithLock(address recipient, uint256 amount, uint256 releaseTime) public onlyOwner returns (bool) {
        require(recipient != address(0), "EHC: lockup zero address");
        require(releaseTime > block.timestamp, "EHC: release time before lock time");
        require(_timelock[recipient].releaseTime == 0, "EHC: already locked");

        TimeLock memory timelock = TimeLock({
            releaseTime : releaseTime,
            amount      : amount
        });
        _timelock[recipient] = timelock;
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Batch transfer amount to recipient
     * @notice that excessive gas consumption causes transaction revert
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length > 0, "EHC: least one recipient address");
        require(recipients.length == amounts.length, "EHC: number of recipient addresses does not match the number of tokens");

        for(uint256 i = 0; i < recipients.length; ++i) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     * - accounts must not trigger the locked `amount` during the locked period.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!paused(), "EHC: token transfer while paused");

        // Check whether the locked amount is triggered
        TimeLock storage timelock = _timelock[from];
        if(timelock.releaseTime != 0 && balanceOf(from).sub(amount) < timelock.amount) {
            require(block.timestamp >= timelock.releaseTime, "EHC: current time is before from account release time");

            // Update the locked `amount` if the current time reaches the release time
            timelock.amount = balanceOf(from).sub(amount);
            if(timelock.amount == 0) {
                timelock.releaseTime = 0;
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}