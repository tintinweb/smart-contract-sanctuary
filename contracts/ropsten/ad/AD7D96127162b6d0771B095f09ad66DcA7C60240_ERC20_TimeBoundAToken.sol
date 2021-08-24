// SPDX-License-Identifier: MIT
// Assignment#3B-1_ERC20_CappedToken, submitted by PIAIC114977 
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20_TimeBoundAToken is IERC20{
    
    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //       Owner               Spender    allowance
    mapping (address => mapping (address => uint256)) private _allowances;
 

    //the amount of tokens in existence
    uint256 private _totalSupply;
    
    uint256 public releaseTime;
    

    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint public decimals;
    
    // events
    event releaseTimeSet(bool success, uint256 releaseTime);
    
    /**
    * Function modifier to restrict Owner's transactions.
    */
    modifier ownerOnly(){
        require(owner == msg.sender, "TB-A-Token: Only contract owner allowed");
        _;
    }
    
    modifier Timelock(){
        require(block.timestamp >= releaseTime, "TB-A-Token:Token is locked, wait till release time");
        _;
    }
     

    constructor () {
        name = "ERC20_TimeBoundAToken";
        symbol = "TB-A-Token";
        decimals = 18;  //1  - 1000 PKR 1 = 100 Paisa 2 decimal
        owner = msg.sender;
     
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
    function transfer(address recipient, uint256 amount) public virtual override Timelock() returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "TB-A-Token: transfer from the zero address");
        require(recipient != address(0), "TB-A-Token: transfer to the zero address");
        require(_balances[sender] > amount,"TB-A-Token: transfer amount exceeds balance");

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
        require(tokenOwner != address(0), "TB-A-Token:: approve from the zero address");
        require(spender != address(0), "TB-A-Token:: approve to the zero address");
        
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
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override Timelock() returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender]; //how much allowed
        require(_allowance > amount, "TB-A-Token: transfer amount exceeds allowance");
        
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
     * Function to set the release time for transfer and transferFrom functions
     * - www.unixtimestamp.com (for converting time into unix time)
     * block.timestamp (uint): current block timestamp as seconds since unix epoch
     * Requirements:
     * - releaseTime must be unix time
     * - _releaseTime must be valid and in the future
     */
     function setReleaseTime(uint _releaseTime) public ownerOnly() returns(bool){
         require(block.timestamp < _releaseTime, "TB-A-Token: releaseTime must be valid and represent future time");
         
         releaseTime = _releaseTime;
         
         emit releaseTimeSet(true, _releaseTime);
         
         return true;
     }
}