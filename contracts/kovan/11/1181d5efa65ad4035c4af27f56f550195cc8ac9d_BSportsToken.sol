/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IAuthorizationManager{
    function isOwner() external view returns(bool);
    function isCFO() external view returns(bool);
    function isCTO() external view returns(bool);
    function isDEV() external view returns(bool);
    function isOPT() external view returns(bool);
    function getWithdrawAddress() external view returns(address);
    function doSuperWithdraw() external returns(bool);
}

contract AuthorizationManager is IAuthorizationManager {
    // version
    bytes32 public version = "v3.0.0 Pro, Jun/29/2021";
    // the owner of this constract, isn't creator.
    address public owner;
    // owner tobe appointed on constructor.
    // owner appoints cfo and cto.

    // Asset manager to set withdraw address, 
    // Tech manager to appoint DEVs and OPTs, 
    // dev to deploy new constract,
    // operate to control the constract.
    // NONE=0, CFO=1, CTO=2, DEV=3, OPT=4 
    enum Roles {NONE, CFO, CTO, DEV, OPT}
    struct Actor {
        address addr;
        Roles role;
        bool valid;
    }
    mapping(address => Actor) public authorized;

    address public defaultWithdrawAddress;
  
    event EventAuthorizedAdd(address senderAddr, address authorAddr);
    event EventAuthorizedRemove(address senderAddr, address authorAddr);
    event DebugLog(string title, string log);

    // Auth step 1: deploy and init owner.
    constructor(address _owner) public {
        owner = _owner;
        defaultWithdrawAddress = _owner;
        appointRole( _owner, Roles.CTO);
    }

    // ---------------------
    function checkOwner() private view returns(bool) {
        //这个条件会强制让子合约中的auths实例无法
        //通过身份校验，owner级别必须直接操作
        require(msg.sender == tx.origin,"origin unauthorized! ERR:001");
        require(tx.origin == owner,"sender unauthorized! ERR:002");
        return true;
    }
    function checkAuth(Roles _role) private view returns(bool) {
        require(authorized[tx.origin].role == _role 
             && authorized[tx.origin].valid == true, "sender unauthorized! ERR:003");
        return true;
    }

    function isOwner() override public view returns(bool){
        if( true == checkOwner() ) return true;
        else return false;
    }

    function isCFO() override public view returns(bool){
        if( true == checkAuth(Roles.CFO) ) return true;
        else return false;
    }
    
    function isCTO() override public view returns(bool){
        if( true == checkAuth(Roles.CTO) ) return true;
        else return false;
    }
    
    function isDEV() override public view returns(bool){
        if( true == checkAuth(Roles.DEV) ) return true;
        else return false;
    }
    
    function isOPT() override public view returns(bool){
        if( true == checkAuth(Roles.OPT) ) return true;
        else return false;
    }
    
    // ---------------------
    function appointRole(address _addr, Roles _role) private returns(bool){
        require(_addr != address(0),"address error! ERR:005");
        if(authorized[_addr].valid == false){
            authorized[_addr].addr = _addr;
            authorized[_addr].role = _role;
            authorized[_addr].valid = true;
            return true;
        }
        return false;
    }
    function dismissRole(address _addr, Roles _role) private returns(bool){
        require(_addr != address(0),"address error! ERR:006");
        if(authorized[_addr].role == _role){
            authorized[_addr].addr = address(0);
            authorized[_addr].role = Roles.NONE;
            authorized[_addr].valid = false;
            return true;
        }
        return false;
    }
    
    // Auth setp 2: owner to appoint role CFO.
    function appointCFO(address _addr) external returns(bool){
        require(checkOwner(), "unvaild auth!");
        return appointRole(_addr, Roles.CFO);
    }
    function dismissCFO(address _addr) external returns(bool){
        require(checkOwner(), "unvaild auth!");
        return dismissRole(_addr, Roles.CFO);
    }
    
    // Auth setp 3: owner to appoint role CTO.
    function appointCTO(address _addr) external returns(bool){
        require(checkOwner(), "unvaild auth!");
        return appointRole(_addr, Roles.CTO);
    }
    function dismissCTO(address _addr) external returns(bool){
        require(checkOwner(), "unvaild auth!");
        return dismissRole(_addr, Roles.CTO);
    }
    
    // Auth setp 4: cto to appoint role dev.
    function appointDEV(address _addr) external returns(bool){
        require(checkAuth(Roles.CTO), "unvaild auth!");
        return appointRole(_addr, Roles.DEV);
    }
    function dismissDEV(address _addr) external returns(bool){
        require(checkAuth(Roles.CTO), "unvaild auth!");
        return dismissRole(_addr, Roles.DEV);
    }
    
    // Auth setp 4: cto to appoint role dev.
    function appointOPT(address _addr) external returns(bool){
        require(checkAuth(Roles.CTO), "unvaild auth!");
        return appointRole(_addr, Roles.OPT);
    }
    function dismissOPT(address _addr) external returns(bool){
        require(checkAuth(Roles.CTO), "unvaild auth!");
        return dismissRole(_addr, Roles.OPT);
    }
    
    // ---------------------
    //The rights for CFO:
    //set withdraw address
    function setWithdraw(address _addr) external returns(bool){
        require(checkAuth(Roles.CFO), "unvaild auth!");
        require(_addr != address(0),"address error!");
        defaultWithdrawAddress = _addr;
        emit WithdrawLog("setWithdraw", defaultWithdrawAddress, 0);
        return true;
    }

    function setWithdrawOnlyOwner() external returns(bool){
        require(checkOwner(), "unvaild auth!");
        defaultWithdrawAddress = owner;
        emit WithdrawLog("setWithdrawOnlyOwner", defaultWithdrawAddress, 0);
        return true;
    }
    
    function getWithdrawAddress() external view override returns(address){
       return defaultWithdrawAddress;
    }

    //---------------
    event WithdrawLog(string title,address newAddress, uint256 value);
    function doSuperWithdraw() external override returns(bool) {
        require(checkAuth(Roles.CFO), "unvaild auth!");
        uint256 _amount = address(this).balance;
        emit WithdrawLog("doSuperWithdraw", defaultWithdrawAddress, _amount);
        payable(address(defaultWithdrawAddress)).transfer(_amount);
    }
}


contract Auth {
    bool reviewStatus; 
    address private CEO; 
    address private CFO;
 
    constructor(address _ceoAddr) public {
        require(_ceoAddr != address(0),"_ceoAddr address error!");
	    CEO = _ceoAddr;
	    CFO = msg.sender;
	    reviewStatus = false;
    }

    //auth for owner to transfer, burn, freeze, unfreeze 
    modifier onlyOwnerNeedReview(){
        if(CFO == msg.sender){
	         require(reviewStatus == true, "ops not reviewed.");
	         reviewStatus = false;
        }
        _; 
    }

    //setting:
    function reviewTrue() external returns(string memory) {
	require(CEO == msg.sender, "No auth");
	reviewStatus = true;
	return "review : true.";
    } 
    
    //setting:
    function reviewFalse() external returns(string memory){
	require(CEO == msg.sender, "No auth");
	reviewStatus = false;
	return "review : false.";
    } 
	    
}

interface IERC20 {
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
   * @dev Returns the ERC token owner.
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
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
 
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


contract BSportsToken is Context, IERC20, Auth {
  using SafeMath for uint256;

  address public _owner;
  mapping (address => uint256) private _balances;
  mapping (address => uint256) private _freezeOf;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(
      address _ceoAddr) Auth(_ceoAddr) public {
    _name = "LUT TOKEN";
    _symbol = "LUT";
    _decimals = 18;
    _totalSupply = 1000000000000000000000000000;
    _balances[msg.sender] = _totalSupply;
    _owner = msg.sender;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
  
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

  function getOwner() external override view returns (address) {
    return _owner;
  }
  
  /**
   * @dev Returns the token decimals.
   */
  function decimals() external override view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external override view returns (string memory) {
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