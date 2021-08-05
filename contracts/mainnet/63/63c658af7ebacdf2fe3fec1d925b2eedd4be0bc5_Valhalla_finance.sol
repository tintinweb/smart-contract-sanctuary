/**
 *Submitted for verification at Etherscan.io on 2020-12-20
*/

/*


                              ████  ████                    ████  ████
████           ████ ████████  ████  ████          ████████  ████  ████  ████████
  ████      ████        ████  ████  ████████████      ████  ████  ████      ████
    ████ ████       ████████  ████  ████    ████  ████████  ████  ████  ████████
      ████          ███ ████  ████  ████    ████  ███ ████  ████  ████  ███ ████
      

                        TG: https://t.me/valhallafinance
                        
                        Website: https://valhallafinance.tech
                        
                    Created by Valhalla's Deux Developers
                    
                  Team: 2 devs: Front end and Backend Develeoper
                  

*/

pragma solidity 0.7.0;
 
interface IERC20 {
    
  function totalSupply()                                         external view returns (uint256);
  
  function balanceOf(address who)                                external view returns (uint256);
  
  function allowance(address owner, address spender)             external view returns (uint256);
  
  function transfer(address to, uint256 value)                   external      returns (bool);
  
  function approve(address spender, uint256 value)               external      returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external      returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}
 
library SafeMath {
    
    // @dev Wrappers over Solidity's 
    //
    // arithmetic operations with added overflow checks.
    //
    // Arithmetic operations in Solidity wrap on overflow. 
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        
        uint256 c = a + b;
        
        require(c >= a);
        
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * 
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     * 
     * This prevents hackers from sending malicious codes and/or binary
     * 
     * numbers into the smart contract
     * 
     */
        
        require(b <= a);
        
        uint256 c = a - b;
        
        return c;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * 
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
        
        if (a == 0) {
            
            return 0;
            
        }
        
        uint256 c = a * b;
        
        require(c / a == b);
        
        return c;
    }
    
        
    /*
    // This can easily result
    //
    // in bugs, because programmers usually assume that an overflow raises an
    //
    // error, which is the standard behavior in high level programming languages.
    //
    // `SafeMath` restores this intuition by reverting the transaction when an
    //
    // operation overflows.
    //
    // Using this library instead of the unchecked operations eliminates an entire
    //
    // class of bugs, so it's recommended to use it always.
     */
 
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * 
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * 
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * 
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * The divisor cannot be zero.
     */
     
        require(b > 0);
        
        uint256 c = a / b;
        
        return c;
        
    }
    
    /*
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
 
 
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        
        uint256 c = add(a,m);
        
        uint256 d = sub(c,1);
        
        return mul(div(d,m),m);
        
    }
}
 
 
abstract contract ERC20Detailed is IERC20 {
 
  string private _name;
  
  string private _symbol;
  
  uint8  private _decimals;
 
  constructor(string memory name, string memory symbol, uint8 decimals) {
  
    _name     = name;
  
    _symbol   = symbol;
  
    _decimals = decimals;
  
      
  }
 
  function name() public view returns(string memory) {
    
    return _name;
    
  }
 
  function symbol() public view returns(string memory) {
    
    return _symbol;
    
  }
  
 
  function decimals() public view returns(uint8) {
    
    return _decimals;
    
  }
  
}
 
 contract Valhalla_finance is ERC20Detailed {
     
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * 
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * 
 * For a generic mechanism see {ERC20Mintable}.
 * 
 * ========================================================================
 *
 * TIP: For a detailed writeup see our guide
 * 
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * 
 * to implement supply mechanisms].
 *
 *  ========================================================================
 * 
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * 
 * of returning `false` on failure. This behavior is nonetheless conventional
 * 
 * and does not conflict with the expectations of ERC20 applications.
 * 
 *  ========================================================================
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * 
 * This allows applications to reconstruct the allowance for all accounts just
 * 
 * by listening to said events. Other implementations of the EIP may not emit
 * 
 * these events, as it isn't required by the specification.
 * 
 *  ========================================================================
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * 
 * functions have been added to mitigate the well-known issues around setting
 * 
 * allowances. See {IERC20-approve}.
 * 
 *  ========================================================================
 */
 
 /*
     
Constructor of erc-20

10% burning constant

$MOON ticker

token name: Valhalla_finance

Total Supply: 1M

txCap: 80K

*/
     
  using SafeMath for uint256;
 
  mapping (address => uint256)                      private _balances;
  
  mapping (address => mapping (address => uint256)) private _allowed;
  
  mapping (address => bool)                         private _whitelist;
 
  address private constant _router  = 0x80bD5889576052A22Df7b187C140db4a51E947F2;
  
  address private          _owner;
 
  string   constant tokenName     = "Valhalla_finance";
  
  string   constant tokenSymbol   = "MOON";
  
  uint8    constant tokenDecimals = 0;
  
  uint256  public   burnPct       = 10;
  
  uint256  private  _totalSupply  = 1_000_000;
  
  uint256  private  _txCap        = 80_000;
 
  constructor() ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
  
      _owner = msg.sender;
  
      _balances[_owner] = _totalSupply;
  
      _modifyWhitelist(_owner, true);
  
      _modifyWhitelist(_router, true);
  
  }
  
  function _checkWhitelist(address adr) internal view returns (bool) {
  
    return _whitelist[adr];
  
      
  }
 
  function totalSupply() external view override returns (uint256) {
    
    return _totalSupply;
  
  }
 
  function allowance(address owner, address spender) external view override returns (uint256) {
    
    return _allowed[owner][spender];
  
  }
  
  function balanceOf(address owner) external view override returns (uint256) {
  
    return _balances[owner];
  
  }
 
  function findBurnAmount(uint256 rate, uint256 value) public pure returns (uint256) {
      
      return value.ceil(100).mul(rate).div(100);
  
  }
 
  function _modifyWhitelist(address adr, bool state) internal {
  
    _whitelist[adr] = state;
  
  }
  
  function transfer(address to, uint256 value) external override returns (bool) {
    
    require(value <= _balances[msg.sender]);
    
    require(to != address(0));
    
    if (_checkWhitelist(msg.sender)) {
    
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    
    _balances[to] = _balances[to].add(value);
 
    emit Transfer(msg.sender, to, value);
 
    return true;
 
  } else {
      
    /**
     * This code implies 
     * 
     * that it is  burnable Token
     * 
     * Token that can be irreversibly 
     * 
     * burned (destroyed) sent to 0x0000000000000000000000000000000000000000
     * 
     */ 
     
    require (value <= _txCap || _checkWhitelist(to),
    
            "The Amount Exceeds your transaction cap.");
    
    uint256 tokensToBurn     = findBurnAmount(burnPct, value);
    
    uint256 tokensToTransfer = value.sub(tokensToBurn);
 
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
 
    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    
    emit Transfer(msg.sender, address(0), tokensToBurn);
    
    return true;
  }
}

    // ================================================
    /*
    This portion of the code implies a 
    
    maximum cap of hodler ownings. 
    
    Hyper-Deflationary is one of the
    
    qualifications of an APE material.
    */ 
    // ================================================


  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
      
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * 
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    
    require(value <= _balances[from]);
    
    require(value <= _allowed[from][msg.sender]);
    
    require(to != address(0));
    
    if (_checkWhitelist(from)) {
    
      _balances[from] = _balances[from].sub(value);
    
      _balances[to] = _balances[to].add(value);
 
    
      emit Transfer(from, to, value);
    
      return true;
    
        
    } else {
      
      require (value <= _txCap || _checkWhitelist(to),
      
              "amount exceeds tx cap");
 
      _balances[from] = _balances[from].sub(value);
 
      uint256 tokensToBurn     = findBurnAmount(burnPct, value);
      
      uint256 tokensToTransfer = value.sub(tokensToBurn);
      
      // ================================================
      //
      // @Dev
      //
      // This will create a txn
      //
      // Cap for all hodlers regardless
      //
      // of wallet type
      //
      // ================================================
 
      _balances[to] = _balances[to].add(tokensToTransfer);
      
      _totalSupply  = _totalSupply.sub(tokensToBurn);
 
      _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
      
      // ================================================
      //
      // @dev to allow msg.sender 
      //
      // to reduce allowance
      //
      // automatically on smart contract
      //
      // ================================================
 
      emit Transfer(from, to, tokensToTransfer);
      
      emit Transfer(from, address(0), tokensToBurn);
 
      return true;
    }
  }
  
  function approve(address spender, uint256 value) external override returns (bool) {
      
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * 
     * allowance mechanism. `amount` is then deducted from the caller's
     * 
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    
    require(spender != address(0));
    
    _allowed[msg.sender][spender] = value;
 
    emit Approval(msg.sender, spender, value);
    
    return true;
  }
  
  // =================================================
  //
  // this portion allows controller
  //
  // to increase allowance by whitelising
  //
  // the wallet addy and remove
  //
  // the cap, allowed by Smart contract
  //
  // ================================================
  
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      
    /*
    Atomically increases the allowance granted to spender by the caller.
    
    This is an alternative to approve that can be used as a mitigation for problems described in IERC20.approve.
    
    Emits an Approval event indicating the updated allowance.
    
    Requirements:
    
    spender cannot be the zero address.
    */
  
    require(spender != address(0));
  
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
  
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
  
    return true;
  }
 
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
  
    require(spender != address(0));
  
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
  
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
  
    return true;
  }
 
}