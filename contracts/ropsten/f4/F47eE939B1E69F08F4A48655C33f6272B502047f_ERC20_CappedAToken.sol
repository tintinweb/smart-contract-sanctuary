// SPDX-License-Identifier: MIT
// Assignment#3B-1_ERC20_CappedToken, submitted by PIAIC114977 
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20_CappedAToken is IERC20{
    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //       Owner               Spender    allowance
    mapping (address => mapping (address => uint256)) private _allowances;
 

    //the amount of tokens in existence
    uint256 private _totalSupply;
    
    uint256 private _cap;

    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint public decimals;
    
    // events
    event tokensMinted(bool success, uint256 amount);
    
    // modifier for owner transctions only
    modifier ownerOnly(){
        require(msg.sender == owner, "C-A-Token: Only Token owner allowed");
        _;
    }

    constructor () {
        name = "ERC20_CappedAToken";
        symbol = "C-A-Token";
        decimals = 18;  //1  - 1000 PKR 1 = 100 Paisa 2 decimal
        owner = msg.sender;
        _cap = 2000000 * 10**decimals;
        
        //1 million tokens to be generated
        _totalSupply = 1000000 * 10**decimals; //exponenctial farmola
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "C-A-Token: transfer from the zero address");
        require(recipient != address(0), "C-A-Token: transfer to the zero address");
        require(_balances[sender] > amount,"C-A-Token: transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender] - amount;
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender]; //return allowed amount
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "C-A-Token: approve from the zero address");
        require(spender != address(0), "C-A-Token: approve to the zero address");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
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
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender]; //how much allowed
        require(_allowance > amount, "C-A-Token: transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance - amount;
        
        //--- start transfer execution -- 
        
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner] - amount; 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
    
    /**
     * This function will allow owner to Mint more tokens and check that total supply doesnot exceeds the capped limit
     * 
     * Requirements:
     * - the caller must be Owner of Contract
     * - amount should be valid incremental value.
     */
    
    function mint(uint256 amount) public ownerOnly returns(bool){
        require(amount > 0, "C-A-Token:Amount should be valid");
        require(_totalSupply + amount <= _cap,"C-A-Token:The minted token should not be exceeded from the Capped limit");
        
        _balances[owner] = _balances[owner] + amount;
        _totalSupply = _totalSupply + amount;
        
        emit tokensMinted(true, amount);
        emit Transfer(address(this),owner,amount);
        
        return true;
    }
    
}