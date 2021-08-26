/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

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
        return msg.data;
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
    mapping(address => uint256) private _balances;

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract TimeLockedWallet {
    address public creator;
    address public owner;
    address public originalOwner;
    address public beneficiary;
    uint256 public unlockTime;
    uint256 public createdAt;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*
the name is exactly the same as our contract name, 
it is the constructor and gets called only once when the contract is created.

if you were to change the name of the contract, 
this would become a normal function callable by anyone 
and form a backdoor in your contract like was the case in the Parity Multisig Wallet bug. 
Additionally, note that the case matters too, 
so if this function name were in lowercase it would also become a regular function
*/
    constructor(
        address _creator,
        address _owner,
        address _originalOwner,
        address _beneficiary,
        uint256 _unlockTime
    ) {
        creator = _creator;
        owner = _owner;
        originalOwner = _originalOwner;
        beneficiary = _beneficiary;
        unlockTime = _unlockTime;
        createdAt = block.timestamp;
    }

    // keep all the ether sent to this address
    /*
    fallback function. If someone sends any ETH to this contract, we will happily receive it. 
    The contract’s ETH balance will increase and it will trigger a Received event. 
    To enable any other functions to accept incoming ETH, you can mark them with the payable keyword.
    */
    fallback() external payable {
        Received(msg.sender, msg.value);
    }

    receive() external payable {
        Received(msg.sender, msg.value);
    }

    // callable by owner only, after specified time
    // this.balance returns the current ether balance of this contract.
    // msg.sender is the caller of this function
    function withdraw() public onlyOwner {
        require(block.timestamp >= unlockTime,  "Cannot withdraw, the wallet is locked...");
        //send all the balance
        //payable(msg.sender).transfer(address(this).balance);
        //Withdrew(msg.sender, address(this).balance);
        
        payable(beneficiary).transfer(address(this).balance);
        Withdrew(beneficiary, address(this).balance);
    }

 
    function updateUnlockTime(uint256 _newUnlockTime) public onlyOwner returns (uint, uint) {
        unlockTime = _newUnlockTime;
        
        return (1, unlockTime);
    }
    
    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract) public onlyOwner returns(uint, uint) {
        
        if (block.timestamp < unlockTime) return (0,0);
         
        ERC20 token = ERC20(_tokenContract);
        
        uint256 tokenBalance = token.balanceOf(address(this));
        
        if(tokenBalance >0) {
           token.transfer(beneficiary, tokenBalance);
           WithdrewTokens(_tokenContract, beneficiary, tokenBalance);
           
           return (1, tokenBalance);
        }
        else 
           return (1, 0);
    
    }

    function getSomeInfo()
        public
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (creator, owner, msg.sender, originalOwner, beneficiary, unlockTime, createdAt, address(this).balance, msg.sender == owner);
    }

    event Received(address from, uint256 amount);
    event Withdrew(address to, uint256 amount);
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}

contract TimeLockedWalletFactory {
    mapping(address => TimeLockedWallet[]) wallets;
    address originalOwner;
    address beneficiary;
    uint256 unlockTime;
    TimeLockedWallet timeLockedWallet;

  
    // view does not cost gas...
    function getWallets(address _originalOwner) public view returns (address[] memory) {
        
        address[] memory addr;
        
        for(uint j = 0; j < wallets[_originalOwner].length; j++) {
            addr[j] = address(wallets[_originalOwner][j]);
        }
        
        return (addr);
        
        //return wallets[_user];
    }

    function newTimeLockedWallet(address _originalOwner, address _beneficiary, uint256 _unlockTime)
        public
        payable
        returns (address wallet)
    {
        // Create new wallet.
        timeLockedWallet = new TimeLockedWallet(msg.sender, address(this), _originalOwner,  _beneficiary, _unlockTime);
        wallet = address(timeLockedWallet);
        originalOwner = _originalOwner;
        beneficiary = _beneficiary;
        unlockTime = _unlockTime;
        
        // Add wallet to owner's wallet list.
        wallets[_originalOwner].push(timeLockedWallet);

        // If owner is not the same as sender then add wallet to sender's wallets too.
        //if (msg.sender != address(this)) {
        //    wallets[address(this)].push(wallet);
        //}

        // Send ether from this transaction to the created wallet.
        //wallet.transfer(msg.value);

        // Emit event.
        //Created(wallet, msg.sender, _owner, block.timestamp, _unlockDate, msg.value);
        Created(wallet, msg.sender, address(this), block.timestamp, unlockTime, 0);
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _originalOwner, address fromWallet, address _tokenContract) public  returns(uint, uint) {
       
        //try to find the fromWallet
        
        for(uint i=0; i< wallets[_originalOwner].length; i++) {
            if(address(wallets[_originalOwner][i]) == fromWallet) {
                TimeLockedWallet wallet = wallets[_originalOwner][i];
                return wallet.withdrawTokens(_tokenContract);
            }
        }
        
        
       return (0, 0);
       
    }

    function updateUnlockTime(address _originalOwner, address fromWallet, uint256 _newUnlockTime) public  returns(uint, uint) {
       
        //try to find the fromWallet
        
        for(uint i=0; i< wallets[_originalOwner].length; i++) {
            if(address(wallets[_originalOwner][i]) == fromWallet) {
                TimeLockedWallet wallet = wallets[_originalOwner][i];
                return wallet.updateUnlockTime(_newUnlockTime);
            }
        }
        
        
       return (0, 0);
       
    }
    
  function getWalletInfo(address _originalOwner, address fromWallet) public view returns (address, address, address, address, address, uint256, uint256, uint256, bool) {
      
      
        for(uint i=0; i< wallets[_originalOwner].length; i++) {
            if(address(wallets[_originalOwner][i]) == fromWallet) {
                TimeLockedWallet wallet = wallets[_originalOwner][i];
                return wallet.getSomeInfo();
            }
        }
        
        return (address(0),address(0),address(0),address(0),address(0),0,0,0,false);
    }
    
   function getBalanceOf(address wallet, address _tokenContract) public view returns (uint256, uint256, address, address) {
        ERC20 token = ERC20(_tokenContract);
        
        uint256 tokenBalance = token.balanceOf(wallet);
        uint256 ownerBalance = token.balanceOf(beneficiary);
        
        // msg.sender is 0x0000000000000000000000000000000000000000
        return (tokenBalance, ownerBalance, msg.sender, beneficiary);
    }
    // Prevents accidental sending of ether to the factory
    receive() external payable {
        revert();
    }

    event Created(
        address wallet,
        address from,
        address to,
        uint256 createdAt,
        uint256 unlockDate,
        uint256 amount
    );
    
    event WithdrewTokens(address tokenContract, address to, uint256 amount);
}