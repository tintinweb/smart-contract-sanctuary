// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ehash_library.sol";

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
    constructor () internal {
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

contract EHashBaseToken is ERC20, Pausable, Ownable {
    /**
     * @dev Initialize the contract give all tokens to the deployer
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(_msgSender(), _initialSupply * (10 ** uint256(_decimals)));
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
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
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account,amount);
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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "EHashToken: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
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
     * @dev Batch transfer amount to recipient
     * @notice that excessive gas consumption causes transaction revert
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length > 0, "EHashToken: least one recipient address");
        require(recipients.length == amounts.length, "EHashToken: number of recipient addresses does not match the number of tokens");

        for(uint256 i = 0; i < recipients.length; ++i) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }
}


contract EHashToken is EHashBaseToken, ReentrancyGuard{
    using SafeMath for uint256;
    using Address for address payable;

    // @dev a revenue share multiplier to avert divison downflow.
    uint256 internal constant REVENUE_SHARE_MULTIPLIER = 1e18;
    
    // @dev update period in secs for revenue distribution.
    uint256 public updatePeriod = 30;

    // @dev for tracking of holders' claimable revenue.
    mapping (address => uint256) internal _revenueBalance;
    
    // @dev for tracking of holders' claimed revenue.
    mapping (address => uint256) internal _revenueClaimed;
    
    /// @dev RoundData always kept for each round.
    struct RoundData {
        uint256 accTokenShare;     // accumulated unit ehash share for each settlement.
        uint256 roundEthers;    // total ethers received in this round. 
    }
    
    /// @dev round index mapping to RoundData.
    mapping (uint => RoundData) private _rounds;
    
    /// @dev mark token holders' highest settled revenue round.
    mapping (address => uint) private _settledRevenueRounds;
    
    /// @dev a monotonic increasing round index, STARTS FROM 1
    uint private _currentRound = 1;
    
    /// @dev expected next update time
    uint private _nextUpdate = block.timestamp + updatePeriod;

    /// @dev manager's address
    address payable managerAddress;

    /// @dev Revenue Claiming log
    event Claim(address indexed account, uint256 amount);
    
    /// @dev Update log
    event Update(uint256 AccTokenShare, uint256 RoundEthers);

    /// @dev Received log
    event Received(address indexed account, uint256 amount);
    
    /// @dev Settle Log
    event Settle(address indexed account, uint LastSettledRound, uint256 Revenue);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) 
        EHashBaseToken(_name, _symbol, _decimals, _initialSupply)
        public {
    }
    
    // @dev tryUpdate function
    modifier tryUpdate() {
        if (block.timestamp > _nextUpdate) {
            update();
        }
        _;
    }
    
    /**
     * @notice set manager's address
     */
    function setManagerAddress(address payable account) external onlyOwner {
        require (account != address(0), "0 address");
        managerAddress = account;
    }
    
    /** 
     * @notice set update period
     */
    function setUpdatePeriod(uint nsecs) external onlyOwner {
        require (nsecs > 0," period should be positive");
        updatePeriod = nsecs;
    }
    
    /**
     * @notice get manager's address
     */
     function getManagerAddress() external view returns(address) {
         return managerAddress;
     }
    
    /**
     * @notice default ether receiving function 
     */
    receive() external payable tryUpdate {
        _rounds[_currentRound].roundEthers += msg.value;
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice check unclaimed revenue 
     */
    function checkUnclaimedRevenue(address account) public view returns(uint256 revenue) {
        uint256 accountTokens = balanceOf(account);
        uint lastSettledRound = _settledRevenueRounds[account];

        uint256 roundRevenue = _rounds[_currentRound-1].accTokenShare.sub(_rounds[lastSettledRound].accTokenShare)
                                    .mul(accountTokens)
                                    .div(REVENUE_SHARE_MULTIPLIER);  // NOTE: div by REVENUE_SHARE_MULTIPLIER

        return _revenueBalance[account].add(roundRevenue);
    }
    
    /**
     * @notice get user's life-time gain
     */
    function checkTotalRevenue(address account) external view returns(uint256 revenue) {
        return checkUnclaimedRevenue(account) + _revenueClaimed[account];
    }
    
    /**
     * @notice get round N information
     */
    function getRoundData(uint round) external view returns(uint256 accTokenShare, uint256 roundEthers) {
        return (_rounds[round].accTokenShare, _rounds[round].roundEthers);
    }
    
    /**
     * @notice get current round
     */
    function getCurrentRound() external view returns(uint round) {
        return _currentRound;
    }

    /**
     * @notice token holders claim revenue
     */
    function claim() external whenNotPaused {
        // settle un-distributed revenue in rounds to _revenueBalance;
        _settleRevenue(msg.sender);

        // revenue balance change
        uint256 revenue = _revenueBalance[msg.sender];
        _revenueBalance[msg.sender] = 0; // zero sender's balance
        
        // transfer ETH to msg.sender
        msg.sender.sendValue(revenue);
        
        // record claimed revenue
        _revenueClaimed[msg.sender] += revenue;
        
        // log
        emit Claim(msg.sender, revenue);
    }
    
     /**
     * @notice settle revenue in rounds to _revenueBalance, 
     * settle revenue happens before any token exchange such as ERC20-transfer,mint,burn,
     * and active claim();
     */
    function _settleRevenue(address account) internal tryUpdate {
        uint256 accountTokens = balanceOf(account);
        uint lastSettledRound = _settledRevenueRounds[account];
        
        uint256 roundRevenue = _rounds[_currentRound-1].accTokenShare.sub(_rounds[lastSettledRound].accTokenShare)
                                    .mul(accountTokens)
                                    .div(REVENUE_SHARE_MULTIPLIER);  // NOTE: div by REVENUE_SHARE_MULTIPLIER

        // mark highest settled round revenue claimed.
        _settledRevenueRounds[account] = _currentRound - 1;
        // set back balance to storage
        _revenueBalance[account] += roundRevenue;
        // log
        emit Settle(account, _settledRevenueRounds[account], _revenueBalance[account]);
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
        require(!paused(), "EHash: token transfer while paused");
        
        // handle revenue settlement before token number changes.
        if (from != address(0)) {
            _settleRevenue(from);
        }
        
        if (to != address(0)) {
            _settleRevenue(to);
        }
        
        super._beforeTokenTransfer(from, to, amount);
    }
    
    
    /**
     * @dev update function to settle rounds shifting and rounds share.
     */
    function update() internal nonReentrant {
        require (block.timestamp > _nextUpdate, "period not expired");
        require (managerAddress != address(0), "manager address has not set");
        
        // rules:
        // 80% of ethers in this round belongs to all token holders
        //  roundEthers * 80% / totalSupply()
        // and, 20% of ethers belongs to manager
        uint256 roundEthers = _rounds[_currentRound].roundEthers;
        uint256 managerRevenue = roundEthers.mul(20).div(100);
        uint256 holdersEthers = roundEthers.sub(managerRevenue);
        
        // send to manager
        managerAddress.sendValue(managerRevenue);
        
        // substract manager's revenue
        
        // set accmulated holder's share
        _rounds[_currentRound].accTokenShare = _rounds[_currentRound-1].accTokenShare
                                                .add(
                                                    holdersEthers
                                                    .mul(REVENUE_SHARE_MULTIPLIER) // NOTE: multiplied by REVENUE_SHARE_MULTIPLIER here
                                                    .div(totalSupply())
                                                );

        // log                                            
        emit Update(_rounds[_currentRound].accTokenShare, _rounds[_currentRound].roundEthers);
        
        // next round setting                                 
        _currentRound++;
        _nextUpdate = block.timestamp + updatePeriod;
    }
}