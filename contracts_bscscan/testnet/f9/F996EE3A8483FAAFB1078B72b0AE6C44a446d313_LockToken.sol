// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;


    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
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
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender];
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

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
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
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
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
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
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
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
    function _approve(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }
}



contract LockToken is ERC20, Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token;
    mapping(uint256 => uint16) public lockTokenBlockNumberAndRatios;
    uint256 constant denominator = 1000;
        
    struct LockRecord {
        address user;
        uint256 tokenAmount;
        uint256 lockTokenAmount;
        uint256 lockBlockNumber;
        uint256 unlockBlockNumber;
        bool unlocked;
    }
    
    uint256 public minimumLockAmount;
    // How much LockToken will get when staking 1 token without lock
    uint256 public stakeTokenRatio = 1000;
    // user token amount for staking without lock
    mapping(address => uint256) public userStakedToken;
    
    uint256 public totalTokenAmount;
    uint256 public totalLockTokenAmount;
    
    uint256 public currentLockId;
    uint256[] public allLockIds;
    
    mapping(address => uint256[]) public userLockRecordIds;
    mapping(uint256 => LockRecord) public lockRecords;
    
    // Total staked token balance including staked and locked
    mapping(address => uint256) public userTokenAmount;
    // Total LockToken balance including staked and locked
    mapping(address => uint256) public userLockTokenAmount;

    mapping(address => bool) public admins;
    bool checkAdmin;
    modifier onlyAdmin virtual {
        if (checkAdmin){
            require(admins[msg.sender] || msg.sender == owner()); 
        }
        _;
    }
    event Lock(address User, address ForUser, uint256 TokenAmount, uint256 LockTokenAmount, uint256 LockedBlockNumber);
    event Unlock(address User, uint256 LockRecordId, uint256 TokenAmount, uint256 LockTokenAmount);
            
    event Unstake(address User, uint256 TokenAmount, uint256 LockTokenAmount);

    constructor (string memory _name, string memory _symbol, IERC20 _token, uint256 _stakeTokenRatio) ERC20 (_name, _symbol) {
        token = _token;
        admins[msg.sender] = true;
        stakeTokenRatio = _stakeTokenRatio;
        checkAdmin = true;
    }
    
    function setAdmin(address _account, bool _isAdmin) external onlyOwner {
        admins[_account] = _isAdmin;
    }
    
    function setCheckAdmin(bool _checkAdmin) public onlyOwner{
        checkAdmin = _checkAdmin;
    }
    
    function setLockTokenBlockNumberAndRatio(uint256 _lockTokenBlockNumber, uint16 _lockTokenRatio) public onlyAdmin{

        lockTokenBlockNumberAndRatios[_lockTokenBlockNumber] = _lockTokenRatio;
    }
    function setMinimumLockQuantity(uint256 _minimumLockAmount) public onlyOwner {
        minimumLockAmount = _minimumLockAmount;
    }
        
    // lock token for LockToken
    function lock(address _forUser, uint256 _amount, uint256 _lockTokenBlockNumber) public onlyAdmin returns (uint256 _id) {
        require(_forUser != address(0), 'LockToken: _forUser can not be Zero');
        require(_amount >= minimumLockAmount, 'LockToken: token amount must be greater than minimumLockAmount');
        require(lockTokenBlockNumberAndRatios[_lockTokenBlockNumber] != 0, "LockToken: _lockTokenBlockNumber does not support!");
        
        //token.safeApprove(address(this), _amount);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 unlockBlock = block.number.add(_lockTokenBlockNumber);
        uint256 lockTokenAmount = _amount.mul(lockTokenBlockNumberAndRatios[_lockTokenBlockNumber]).div(denominator);
        //update token amount in address
        userTokenAmount[_forUser] = userTokenAmount[_forUser].add(_amount);
        totalTokenAmount = totalTokenAmount.add(_amount);
        totalLockTokenAmount = totalLockTokenAmount.add(lockTokenAmount);
        _id = ++currentLockId;
        lockRecords[_id].user = _forUser;
        lockRecords[_id].tokenAmount = _amount;
        lockRecords[_id].lockTokenAmount = lockTokenAmount;
        lockRecords[_id].lockBlockNumber = block.number;
        lockRecords[_id].unlockBlockNumber = unlockBlock;
        lockRecords[_id].unlocked = false;
        allLockIds.push(_id);
        userLockRecordIds[_forUser].push(_id);
        userLockTokenAmount[_forUser] = userLockTokenAmount[_forUser].add(lockTokenAmount);
        _mint(_forUser, lockTokenAmount);

        emit Lock(msg.sender, _forUser, _amount, lockTokenAmount, _lockTokenBlockNumber);
    }

    function unlock(address _forUser, uint256 _lockRecordId) public onlyAdmin {
        require(block.number >= lockRecords[_lockRecordId].unlockBlockNumber, 'LockToken: Tokens are still locked');
        require(_forUser == lockRecords[_lockRecordId].user, 'LockToken: only can be unlocked by user');
        require(!lockRecords[_lockRecordId].unlocked, 'LockToken: Tokens has already been unlocked');
        require(_balances[msg.sender] >= lockRecords[_lockRecordId].lockTokenAmount, "LockToken: LockToken balance is not enough!");
        token.safeTransfer(_forUser, lockRecords[_lockRecordId].tokenAmount);
        userLockTokenAmount[_forUser] = userLockTokenAmount[_forUser].sub(lockRecords[_lockRecordId].lockTokenAmount);
        _burn(msg.sender, lockRecords[_lockRecordId].lockTokenAmount);

        lockRecords[_lockRecordId].unlocked = true;

        //update token amount in address
        userTokenAmount[_forUser] = userTokenAmount[_forUser].sub(lockRecords[_lockRecordId].tokenAmount);
        totalLockTokenAmount = totalLockTokenAmount.sub(lockRecords[_lockRecordId].lockTokenAmount);
        totalTokenAmount = totalTokenAmount.sub(lockRecords[_lockRecordId].tokenAmount);

        //remove this id from user lock record ids
        uint256 i;
        uint256 j;
        //TODO error?
        for (j = 0; j < userLockRecordIds[lockRecords[_lockRecordId].user].length; j++) {
            if (userLockRecordIds[lockRecords[_lockRecordId].user][j] == _lockRecordId) {
                for (i = j; i < userLockRecordIds[lockRecords[_lockRecordId].user].length - 1; i++) {
                    userLockRecordIds[lockRecords[_lockRecordId].user][i] = userLockRecordIds[lockRecords[_lockRecordId].user][i + 1];
                }
                // TODO require?
                // userLockRecordIds[lockRecords[_lockRecordId].user].length--;
                userLockRecordIds[lockRecords[_lockRecordId].user].pop();
                break;
            }
        }
        emit Unlock(_forUser, _lockRecordId, lockRecords[_lockRecordId].tokenAmount, lockRecords[_lockRecordId].lockTokenAmount);
    }

    // stake token for LockToken without lock
    function stake(address _forUser, uint256 _tokenAmount) public onlyAdmin {
        require(stakeTokenRatio > 0, "LockToken: stake not supported");
        require(_tokenAmount >= minimumLockAmount, 'LockToken: token amount must be greater than minimumLockAmount');
        require(_tokenAmount > 0, "LockToken: amount must be greater than 0");
        //token.safeApprove(address(this), _tokenAmount);
        token.safeTransferFrom(msg.sender, address(this),_tokenAmount);
        
        uint256 lockTokenAmount = _tokenAmount.mul(stakeTokenRatio).div(denominator);
        
        userTokenAmount[_forUser] = userTokenAmount[_forUser].add(_tokenAmount);
        userStakedToken[_forUser] = userStakedToken[_forUser].add(_tokenAmount);
        _mint(_forUser, lockTokenAmount);
        userLockTokenAmount[_forUser] = userLockTokenAmount[_forUser].add(lockTokenAmount);
        
        totalTokenAmount = totalTokenAmount.add(_tokenAmount);
        totalLockTokenAmount = totalLockTokenAmount.add(lockTokenAmount);
        emit Lock(msg.sender, _forUser, _tokenAmount, lockTokenAmount, 0);
    }

    // unstake token for LockToken without lock
    function unstake(address _forUser, uint256 _tokenAmount) public onlyAdmin{
        require(stakeTokenRatio > 0, "LockToken: unstake not supported");
        require(userStakedToken[_forUser] >= _tokenAmount, "LockToken: unstake amount is greater than staked");
        
        uint256 lockTokenAmount = _tokenAmount.mul(stakeTokenRatio).div(denominator);
        
        require(_balances[msg.sender] >= lockTokenAmount, "LockToken: LockToken balance is not enough!");
        
        _burn(msg.sender, lockTokenAmount);
        userStakedToken[_forUser] = userStakedToken[_forUser].sub(_tokenAmount);
            
        userTokenAmount[_forUser] = userTokenAmount[_forUser].sub(_tokenAmount);
        userLockTokenAmount[_forUser] = userLockTokenAmount[_forUser].sub(lockTokenAmount);
                        
        totalLockTokenAmount = totalLockTokenAmount.sub(lockTokenAmount);
        totalTokenAmount = totalTokenAmount.sub(_tokenAmount);
        
        token.safeTransfer(_forUser, _tokenAmount);
        emit Unstake(_forUser, _tokenAmount, lockTokenAmount);
    }
        
    // get user's all staked token amount including lock and stake
    function getUserAllStakedToken(address _user) public view returns (uint256 _tokenAmount, uint256 _lockTokenAmount){
        return (userTokenAmount[_user], userLockTokenAmount[_user]);
    }

    function getUserLockRecordIds(address _user) view public returns (uint256[] memory _userLockRecordIds)
    {
        return userLockRecordIds[_user];
    }

    function getLockRecord(uint256 _id) view public returns (address _user, uint256 _tokenAmount, 
        uint256 _lockTokenAmount, uint256 _lockBlockNumber, uint256 _unlockBlockNumber, bool _unlocked)
    {
        LockRecord memory lockRecord = lockRecords[_id];
        return (lockRecord.user, lockRecord.tokenAmount, lockRecord.lockTokenAmount,
        lockRecord.lockBlockNumber, lockRecord.unlockBlockNumber, lockRecord.unlocked);
    }
}