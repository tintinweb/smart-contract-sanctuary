/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: GPL-3.0
//  pragma solidity >=0.7.0 <0.9.0;

pragma solidity 0.5.16;
 
 //
 
 interface MidderCoin {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
  * @dev Returns the token decimals.
  */
  function decimals() external view returns (uint8);

  /**
  * @dev Returns the token symbol.
  */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
  * @dev Returns the bep token owner.
  */
  function getOwner() external view returns (address);

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
//   function transfer(address recipient, uint256 amount) external returns (bool);

  /**
  * @dev Returns the remaining number of tokens that `spender` will be
  * allowed to spend on behalf of `owner` through {transferFrom}. This is
  * zero by default.
  *
  * This value changes when {approve} or {transferFrom} are called.
  */
//   function allowance(address _owner, address spender) external view returns (uint256);

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
//   function approve(address spender, uint256 amount) external returns (bool);

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


contract MidderCoinToken is MidderCoin {
    

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  address private owner;
    
    constructor() public{
        _name = "TrungTD NEW";
        _symbol = "TDT NEW";
        _decimals = 18;
        _totalSupply = 66000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
    
    }
    
    
    
    function getOwner() external view returns(address) {
        return owner;
    }
    
    function decimals() external view returns (uint8) {
        return _decimals;
    }
  
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function name() external view returns (string memory) {
        return _name;
    }
    
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        
        return _balances[account];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(sender != address(0), "MidderCoin: transfer from the zero address");
        require(recipient != address(0), "MidderCoin: transfer to the zero address");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        require(owner != address(0), "BEP20: approve from the zero address");
        require(recipient != address(0), "BEP20: approve to the zero address");    
        
         emit Approval(owner, recipient, amount);
        
    }
    
    
    
    
   
}