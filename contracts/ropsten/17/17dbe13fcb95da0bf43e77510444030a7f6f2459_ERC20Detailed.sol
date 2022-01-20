/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

pragma solidity ^0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {

    /**
    * @dev Subtracts two numbers, reverts on overflow.
    */
    function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
        assert(y <= x);
        uint256 z = x - y;
        return z;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert(z >= x);
        return z;
    }
	
	/**
    * @dev Integer division of two numbers, reverts on division by zero.
    */
    function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x / y;
        return z;
    }
    
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */	
    function safeMul(uint256 x, uint256 y) internal pure returns (uint256) {    
        if (x == 0) {
            return 0;
        }
    
        uint256 z = x * y;
        assert(z / x == y);
        return z;
    }

    /**
    * @dev Returns the integer percentage of the number.
    */
    function safePerc(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }
        
        uint256 z = x * y;
        assert(z / x == y);    
        z = z / 10000; // percent to hundredths
        return z;
    }

    /**
    * @dev Returns the minimum value of two numbers.
    */	
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x <= y ? x : y;
        return z;
    }

    /**
    * @dev Returns the maximum value of two numbers.
    */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x >= y ? x : y;
        return z;
    }
}

 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface ERC20I {

  function balanceOf(address _owner) external view returns (uint256);

  function totalSupply() external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool success);
  
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender, uint256 _value) external returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20 
 */
contract ERC20 is ERC20I, SafeMath {
	
  uint256 totalSupply_;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  /** 
   * @dev Total Supply
   * @return totalSupply_ 
   */  
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  /** 
   * @dev Tokens balance
   * @param _owner holder address
   * @return balance amount 
   */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
  
  /** 
   * @dev Tranfer tokens to address
   * @param _to dest address
   * @param _value tokens amount
   * @return transfer result
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));
    require(balances[msg.sender] >= _value);
    
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /** 
   * @dev Token allowance
   * @param _owner holder address
   * @param _spender spender address
   * @return remain amount
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**    
   * @dev Transfer tokens from one address to another
   * @param _from source address
   * @param _to dest address
   * @param _value tokens amount
   * @return transfer result
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));
    require(balances[_from] >= _value);
    require(allowed[_from][msg.sender] >= _value);
    
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }
  
  /** 
   * @dev Approve transfer
   * @param _spender holder address
   * @param _value tokens amount
   * @return result  
   */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function mint(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));

        totalSupply_ = safeAdd(totalSupply_,_value);
        balances[_to] = safeAdd(balances[_to],_value);
        emit Transfer(address(0), _to, _value);
    }
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}