/**
 *Submitted for verification at USDerscan.io on 2020-10-09
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./VerifiedUSDVStorage.sol";	
import "./Proxiable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract LibraryLock is VerifiedUSDVStorage {
    // Ensures no one can manipulate the Logic Contract once it is deployed.	
    // PARITY WALLET HACK PREVENTION	

    modifier delegatedOnly() {	
        require(	
            initialized == true,	
            "The library is locked. No direct 'call' is allowed."	
        );	
        _;	
    }	
    function initialize() internal {	
        initialized = true;	
    }	
}

contract VerifiedUSDV is VerifiedUSDVStorage, Context, IERC20, Proxiable, LibraryLock {	
    using SafeMath for uint256;
    event CodeUpdated(address indexed newCode);	
    event AdminChanged(address admin);
    
    function initialize(uint256 _totalsupply) external {
        require(!initialized, "The library has already been initialized.");	
        LibraryLock.initialize();
        admin = msg.sender;
        _totalSupply = _totalsupply;
        _balances[msg.sender] = _totalSupply;
    }

    /// @dev Update the logic contract code	
    function updateCode(address newCode) external onlyOwner delegatedOnly {	
        updateCodeAddress(newCode);	
        emit CodeUpdated(newCode);	
    }

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
    function transfer(address recipient, uint256 amount) public virtual override isUserblackListed() returns (bool) {
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
    function approve(address spender, uint256 amount) public virtual override isUserblackListed() returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override isUserblackListed() returns (bool) {
        require(!checkIsUserBlackListed(sender),"sender is blacklisted");
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual isUserblackListed() returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual isUserblackListed() returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

    function mint(uint256 _amount) external onlyOwner{
        _mint(msg.sender,_amount);
    }

    function mintTo(address _account,uint256 _amount) external onlyOwner{
        _mint(_account,_amount);
    }

    function burn(uint256 _amount) external{
       _burn(msg.sender,_amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function checkIsUserBlackListed(address _user) public view returns(bool){
        return blackList[_user];
    }

    function blackListAddress(address _user ,bool _varaible) external onlyOwner{
         blackList[_user] = _varaible;
    }

    function TransferOwnerShip(address account) public onlyOwner() {
        require(account != address(0), "account cannot be zero address");
        require(msg.sender == admin, "you are not the admin");
        admin = account;
        emit AdminChanged(admin);
    }
    
    modifier isUserblackListed(){
        require(!blackList[msg.sender],"you are blackListed");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "you are not the admin");
        _;
    }
}