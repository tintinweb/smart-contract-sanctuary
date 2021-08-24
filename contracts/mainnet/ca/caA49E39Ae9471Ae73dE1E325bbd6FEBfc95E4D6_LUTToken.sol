// SPDX-License-Identifier: MIT

import "SafeMath.sol";
import "SafeERC20.sol";

pragma solidity ^0.6.0;

contract Auth {
    uint8 reviewCount;
    address private CEO; 
    address private CFO;
 
    constructor(address _ceoAddr, address _cfoAddr) public {
        require(_ceoAddr != address(0),"_ceoAddr address error!");
	    CEO = _ceoAddr;
	    CFO = _cfoAddr;
        reviewCount  = 0;
    }

    //auth for owner to transfer, burn, freeze, unfreeze 
    modifier onlyOwnerNeedReview(){
        if(CFO == msg.sender){
	         require(reviewCount > 0, "ops not reviewed.");
	         reviewCount = reviewCount - 1;
        }
        _; 
    }

    //setting:
    function reviewTrue() external returns(string memory) {
        return reviewTrueMore(1);
    }
    function reviewTrueMore(uint8 _count) public returns(string memory) {
	    require(CEO == msg.sender, "No auth");
	    reviewCount = _count;
	    return "review : true.";
    } 
    
    //setting:
    function reviewFalse() external returns(string memory){
	    require(CEO == msg.sender, "No auth");
	    reviewCount = 0;
	    return "review : false.";
    } 
	    
}

contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
contract LUTToken is Context, IERC20, Auth {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public _owner;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _freezeOf;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(address _ceoAddr,address _cfoAddr) Auth(_ceoAddr, _cfoAddr) public {
      _name = "LUT TOKEN";
      _symbol = "LUT";
      _decimals = 18;
      _totalSupply = 1 * 1e9 * 1e18;
      _balances[_cfoAddr] = _totalSupply;
      _owner = _cfoAddr;
      emit Transfer(address(0), msg.sender, _totalSupply);
  }
  
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

  function getOwner() external view returns (address) {
    return _owner;
  }
  
  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account];
  }
  function freezeOf(address account) external view returns (uint256) {
    return _freezeOf[account];
  }

  /**
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
   
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {ERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
   
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {ERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
   
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
  function _transfer(address sender, address recipient, uint256 amount) internal onlyOwnerNeedReview {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
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
  function burn(address account, uint256 amount) public onlyOwnerNeedReview {
    require(account != address(0), "ERC20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

	
    /// @notice freeze `_value` token of '_addr' address
    /// @param _addr The address to be freezed
    /// @param _value The amount of token to be freezed
    function freeze(address _addr, uint256 _value) onlyOwnerNeedReview public {
        require(_owner == _msgSender());                //Check owner
        require(_balances[_addr] >= _value);         // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        _balances[_addr] = SafeMath.sub(_balances[_addr], _value);              // Subtract _value amount from balance of _addr address
        _freezeOf[_addr] = SafeMath.add(_freezeOf[_addr], _value);                // Add the same amount to freeze of _addr address
        emit Freeze(_addr, _value);
    }
	
    /// @notice unfreeze `_value` token of '_addr' address
    /// @param _addr The address to be unfreezed
    /// @param _value The amount of token to be unfreezed
    function unfreeze(address _addr, uint256 _value) onlyOwnerNeedReview public {
        require(_owner == _msgSender());                //Check owner
        require(_freezeOf[_addr] >= _value);          // Check if the sender has enough
		require(_value > 0);                         //Check _value is valid
        _freezeOf[_addr] = SafeMath.sub(_freezeOf[_addr], _value);                // Subtract _value amount from freeze of _addr address
		_balances[_addr] = SafeMath.add(_balances[_addr], _value);              // Add the same amount to balance of _addr address
        emit Unfreeze(_addr, _value);
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
}