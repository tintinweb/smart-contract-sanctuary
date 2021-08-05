/***
 *
 * 
 *  Project: XXX
 *  Website: XXX
 *  Contract: MOX bucks
 *  
 *  Description: Fixed parity token
 * 
 */
 
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IMOX.sol"; 
 
/**
 * @dev Implementation of the {IERC20} interface. 
 *
 */
contract MOXbucks is Context, IERC20Metadata, Ownable { 
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 public DIST_PERC = 5; //5% goes to MOXshares holders
    
    address private _owner;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _nftContractAddress;
    address private _sharesContractAddress;
    address private _additionalContract;
    
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;
    
    mapping (address => bool) public _isCurrentOwner;
    address[] public currentOwners; 

    
    IERC20 private sharesContract;
    /**
     * @dev Sets the values for {name}, {symbol} and {owner}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initialSupply_, address MOXsharesContract) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = initialSupply_;
        _balances[msg.sender] = initialSupply_;
        _owner = msg.sender;
        sharesContract = IERC20(MOXsharesContract);
        
        _isCurrentOwner[msg.sender] = true;
        currentOwners.push(msg.sender); 
        
        emit Transfer(address(0), msg.sender, initialSupply_);
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        //uint256 currentAllowance = _allowances[sender][_msgSender()];
        //require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        //_approve(sender, _msgSender(), currentAllowance - amount);
       
        if ((msg.sender != _nftContractAddress) && (msg.sender != _additionalContract)) {
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        
        if (msg.sender == _nftContractAddress)
        {
            //verify if not excluded shares holder
            //modify bucks balances
            //for (uint256 i = 0; i < _sharesContractAddress.currentOwners.length; i++) {
            //    if (! _sharesContractAddress._isExcluded(_sharesContractAddress.currentOwners[i])) {
            //        _balances[_sharesContractAddress.currentOwners[i]] =  _balances[_sharesContractAddress.currentOwners[i]] + _balances[_sharesContractAddress.currentOwners[i]].mul(DIST_PERC).div(100); 
            //    }
            //    }
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
     * @dev Burns a quantity of tokens held by the caller.
     *
     * Emits an {Transfer} event to 0 address
     *
     */
    function burn(uint256 burnQuantity) public virtual override returns (bool) {
        _burn(msg.sender, burnQuantity);
        return true;
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
     * @dev Set NFT address
     */
    function setNFTContractAddress(address nftAddress) public onlyOwner{
        _nftContractAddress = nftAddress;
    }
    
     /**
     * @dev Set shares address
     */
    function setSharesContractAddress(address sharesAddress) public onlyOwner{
        _sharesContractAddress = sharesAddress;
    }
    
    /**
     * @dev Set additional contract address
     */
    function setAdditionalContractAddress (address contractAddress) public onlyOwner {
        _additionalContract = contractAddress;
    }
    
    /**
     * @dev Mints daily tokens assigned to a NFT array. Returns the minted quantity.
     */
    function mintOnlyByOwner(uint256 qty) public onlyOwner {
        _mint(msg.sender, qty); 
    }
    
    /**
     * @dev Public (only owner) function. Edits the distribution percent.
     *
     */ 
    function changeDistPerc(uint256 newPerc) public onlyOwner {
        DIST_PERC = newPerc;
    }
    
    
    /**
     * @dev Public function that shows whether an address is a shares holder or not.
     *
     */ 
    function isCurrentOwner(address account) external view returns (bool) {
        return _isCurrentOwner[account];
    } 
    
    /**
     * @dev Allows only the shares contract to interact.
     *
     */ 
    modifier onlySharesContract() {
        require(msg.sender == _sharesContractAddress);
        _;
    }
    
    /**
     * @dev Includes an address into the currentOwners array.
     *
     */ 
    function includeCurrentOwner(address account) external  {
        //require(!_isCurrentOwner[account], "Owner is already included");
        _isCurrentOwner[account] = true;
        currentOwners.push(account);
    }

    /**
     * @dev Excludes an address from the currentOwners array.
     *
     */ 
     function excludeCurrentOwner(address account)  external onlySharesContract() {
        require(_isCurrentOwner[account], "Owner is already excluded");
        for (uint256 i = 0; i < currentOwners.length; i++) {
            if (currentOwners[i] == account) {
                currentOwners[i] = currentOwners[currentOwners.length - 1];
                _isCurrentOwner[account] = false;
                currentOwners.pop();
                break;
            }
        }
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