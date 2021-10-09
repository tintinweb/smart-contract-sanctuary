// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './IERC20.sol';

contract TOKEN is IERC20{

    address public owner; 
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private _totalSupply; 
     
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
   

    constructor () {
        name = "HASAN-TOKEN";
        symbol = "HT";
        decimals = 18;  
        owner = msg.sender;
           
        _totalSupply = 1000000 * 10**decimals;  
        _balances[owner] = _totalSupply;
        
         
        emit Transfer(address(this),owner,_totalSupply);
     }
      
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), " transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(_balances[sender] > amount,"transfer amount exceeds balance");

         
        _balances[sender] = _balances[sender] - amount;
      
        _balances[recipient] = _balances[recipient] + amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    
    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender]; 
    }

     
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), " approve from the zero address");
        require(spender != address(0), "approve to the zero address");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

     
    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender]; 
        require(_allowance > amount, "transfer amount exceeds allowance");
        
         
        _allowance = _allowance - amount;
        
        _balances[tokenOwner] =_balances[tokenOwner] - amount; 
        
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(tokenOwner, recipient, amount);
        
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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