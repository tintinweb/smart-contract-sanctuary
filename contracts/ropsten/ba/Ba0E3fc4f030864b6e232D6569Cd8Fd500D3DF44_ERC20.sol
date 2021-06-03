pragma solidity ^0.4.0 <=0.7.0;

import "./IERC20.sol";
import "./safemath.sol";

contract ERC20 is IERC20 { // 721
    
    using SafeMath for uint256;
        
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
        
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _price;
    string private _creator;
    
    constructor() public {
            
    _name = "TRADER";
    _symbol = "TRAD";
    _decimals = 18;
    _totalSupply = 100000000000000000000000000 ;
    _creator= "Daniel Cruz - BitcoinHomeBroker.com";
    // the game's account balance:
    _balances[msg.sender] = _totalSupply;
 
    }
    
    function price() public view returns (string memory) {
        //return _price;
    }
            
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    
    
    /**
         * @dev Daniel Cruz BitcoinHomeBroker.com 
         * Returns the number of decimals used to get its user representation.
         * For example, if `decimals` equals `2`, a balance of `505` tokens should
         * be displayed to a user as `5,05` (`505 / 10 ** 2`).
         
        *
         * Tokens usually opt for a value of 18, imitating the relationship between
         * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
         * called.
         *
         
        * NOTE: This information is only used for _display_ purposes: it in
         * no way affects any of the arithmetic of the contract, including
         * {IERC20-balanceOf} and {IERC20-transfer}.
         */
        
    
    function decimals() public view returns (uint8) {
            
        return _decimals;
        
    }
    
        
    
        /**
         * @dev See {IERC20-totalSupply}.
         */
        
    
    function totalSupply() public view returns (uint256) {
            
        return _totalSupply;
        
    }
    
    
    
        /**
         * @dev See {IERC20-balanceOf}.
         */
        
    
    function balanceOf(address account) external view returns (uint256) {
            
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
        
    
    function transfer(address recipient, uint256 amount) public returns (bool) {

        address(recipient).send(amount);
        _balances[msg.sender] -= amount;

        return true;
        
    }
    
    
    
        /**
         * @dev See {IERC20-allowance}.
         */
        
    
    function allowance(address owner, address spender) public view returns (uint256) {
            
        return _allowances[owner][spender];
        
    }
    
        
    
        /**
         * @dev See {IERC20-approve}.
         *
         * Requirements:
         *
         * - `spender` cannot be the zero address.
         */
        
    
    function approve(address spender, uint256 amount) public returns (bool) {
                
        approve(spender, amount);
                
        return true;
        
    }
    
    
    
        /**
         * @dev See {IERC20-transferFrom}.
         *
         * Emits an {Approval} event indicating the updated allowance. This is not
         * required by the EIP. See the note at the beginning of {ERC20};
         *
             
        * Requirements:
         * - `sender` and `recipient` cannot be the zero address.
         * - `sender` must have a balance of at least `amount`.
         * - the caller must have allowance for ``sender``'s tokens of at least
         
         * `amount`.
         */
        
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
            
        //transfer(sender, recipient, amount);
                
        //approve(sender, _allowances[sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
                
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
            
        //_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            
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
           
        // _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
            
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
        
                
        //_beforeTokenTransfer(sender, recipient, amount);
        
                
        //_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
                
        //_balances[recipient] = _balances[recipient].add(amount);
                
        emit Transfer(sender, recipient, amount);
        
    }
    
    
    
        /** @dev Creates `amount` tokens and assigns them to `account`, increasing
         * the total supply.
         *
         * Emits a {Transfer} event with `from` set to the zero address.
         *
         * Requirements
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
         * Requirements
         *
         
    * - `account` cannot be the zero address.
         * - `account` must have at least `amount` tokens.
         */
        
    
    function _burn(address account, uint256 amount) internal {
            
    
        require(account != address(0), "ERC20: burn from the zero address");
        
                
        //_beforeTokenTransfer(account, address(0), amount);
        
                
        //_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
                
        //_totalSupply = _totalSupply.sub(amount);
                
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
        
    
    function _approve(address owner, address spender, uint256 amount) internal {
            
        require(owner != address(0), "ERC20: approve from the zero address");
                
        require(spender != address(0), "ERC20: approve to the zero address");
        
                
        _allowances[owner][spender] = amount;
                
        emit Approval(owner, spender, amount);
        
    }
    
    
        /**
         * @dev Sets {decimals} to a value other than the default one of 18.
         *
         * WARNING: This function should only be called from the constructor. Most
        
         * applications that interact with token contracts will not expect
         * {decimals} to ever change, and may work incorrectly if it does.
         */
        
    
    function _setupDecimals(uint8 decimals_) internal {
            
        _decimals = decimals_;
        
    }
    
    
    
        /**
         * @dev Hook that is called before any transfer of tokens. This includes
         * minting and burning.
         *
         * Calling conditions:
         *
         * - when `from` and `to` are both 
    non-zero, `amount` of ``from``'s tokens
         * will be to transferred to `to`.
         * - when `from` is zero, `amount` tokens will be minted for `to`.
         * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     
        * - `from` and `to` are never both zero.
         *
         * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
         */
        
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }
    

        
}