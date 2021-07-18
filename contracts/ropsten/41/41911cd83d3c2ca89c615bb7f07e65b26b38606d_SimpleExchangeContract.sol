/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: erc20_base.sol
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

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

// File: tokena.sol
contract TokenA is IERC20 {
    using SafeMath for uint256;
    
    string public _name;                    //'Token A';
    string public _symbol;                  //'TKNA';
    uint256 public _totalSupply;
    uint256 public _decimals;               //18;
    
    address public admin;
    
    mapping(address => uint256) public _balanceOf;
    
    mapping(address => mapping(address => uint256)) public _allowance;
    
    constructor(string memory _Tname, string memory _Tsymbol, uint256 _TtotalSupply, uint256 _Tdecimals) {
        _name = _Tname;
        _symbol = _Tsymbol;
        _totalSupply = _TtotalSupply;
        _decimals = _Tdecimals;
        _balanceOf[msg.sender] = _TtotalSupply;
        
        admin = msg.sender;
        
        emit Transfer(address(0), msg.sender, _TtotalSupply);    // Minting amount from the network
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) override public view returns (uint256) {
        return _balanceOf[account];
    }
    
    function transfer(address _to, uint256 _value) override public returns(bool success) {
        require(_to != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_balanceOf[msg.sender] >= _value, "Owner doesn't have enough balance to approve");
        
        _allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(_from != address(0), "Invalid address");
        
        require(_to != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_allowance[_from][msg.sender] >= _value, "You don't have the approval to spend this amount of tokens");
        
        require(_balanceOf[_from] >= _value, "From address doesn't have enough balance to transfer");
        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function mint(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can mint tokens");
        
        require(value > 0, "Invalid amount to mint");
        
        _totalSupply = _totalSupply.add(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        
        emit Transfer(address(0), to, value);
    }
    
    function burn(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can burn tokens");
        
        require(value > 0, "Invalid amount to burn");
        
        require(_totalSupply > 0, "Total Supply should be greater than 0");
        
        require(value <= _totalSupply, "Value cannot be greater than total supply of tokens");
        
        require(_balanceOf[to] >= value, "Not enough balance to burn");
        
        _totalSupply = _totalSupply.sub(value);
        _balanceOf[to] = _balanceOf[to].sub(value);
        
        emit Transfer(to, address(0), value);
    }
}

// File: tokenb.sol
contract TokenB is IERC20 {
    using SafeMath for uint256;
    
    string public _name;                    //'Token B';
    string public _symbol;                  //'TKNB';
    uint256 public _totalSupply;
    uint256 public _decimals;               //18;
    
    address public admin;
    
    mapping(address => uint256) public _balanceOf;
    
    mapping(address => mapping(address => uint256)) public _allowance;
    
    constructor(string memory _Tname, string memory _Tsymbol, uint256 _TtotalSupply, uint256 _Tdecimals) {
        _name = _Tname;
        _symbol = _Tsymbol;
        _totalSupply = _TtotalSupply;
        _decimals = _Tdecimals;
        _balanceOf[msg.sender] = _TtotalSupply;
        
        admin = msg.sender;
        
        emit Transfer(address(0), msg.sender, _TtotalSupply);    // Minting amount from the network
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) override public view returns (uint256) {
        return _balanceOf[account];
    }
    
    function transfer(address _to, uint256 _value) override public returns(bool success) {
        require(_to != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) override public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_balanceOf[msg.sender] >= _value, "Owner doesn't have enough balance to approve");
        
        _allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function allowance(address _owner, address _spender) override public view returns (uint256 remaining) {
        return _allowance[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        require(_from != address(0), "Invalid address");
        
        require(_to != address(0), "Invalid address");
        
        require(_value > 0, "Invalid amount");
        
        require(_allowance[_from][msg.sender] >= _value, "You don't have the approval to spend this amount of tokens");
        
        require(_balanceOf[_from] >= _value, "From address doesn't have enough balance to transfer");
        
        _balanceOf[_from] = _balanceOf[_from].sub(_value);
        _balanceOf[_to] = _balanceOf[_to].add(_value);
        
        _allowance[_from][msg.sender] = _allowance[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function mint(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can mint tokens");
        
        require(value > 0, "Invalid amount to mint");
        
        _totalSupply = _totalSupply.add(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        
        emit Transfer(address(0), to, value);
    }
    
    function burn(address to, uint256 value) public {
        require(msg.sender == admin, "Only creator of the contract can burn tokens");
        
        require(value > 0, "Invalid amount to burn");
        
        require(_totalSupply > 0, "Total Supply should be greater than 0");
        
        require(value <= _totalSupply, "Value cannot be greater than total supply of tokens");
        
        require(_balanceOf[to] >= value, "Not enough balance to burn");
        
        _totalSupply = _totalSupply.sub(value);
        _balanceOf[to] = _balanceOf[to].sub(value);
        
        emit Transfer(to, address(0), value);
    }
}

// File: stake.sol

/// @title Trading Smart Contract for Token A (TKNA) and Token B(TKNB)
/// @author Pooja Sharma
/// @notice This contract is used for trading of two simple ERC20 tokens
/// @dev All function calls are currently implemented without side effects
contract SimpleExchangeContract {
    using SafeMath for uint256;
    
    TokenA public tokenAAddress;
    TokenB public tokenBAddress;
    
    mapping(address => mapping(string => uint256)) public storedBalances;
    
    event Deposited(address indexed _user, uint256 _amount, string indexed _tokenSymbol);
    event Traded(address indexed _user, uint256 _amount, string indexed _fromToken, string indexed _toToken);
    event Withdraw(address indexed _user, uint256 indexed _amount, string indexed _tokenSymbol);
    
    constructor(TokenA _tokenAAddress, TokenB _tokenBAddress) {
        tokenAAddress = _tokenAAddress;
        tokenBAddress = _tokenBAddress;
    }
    
    // Before depositing, first Approve the SimpleExchangeContract contract 
    // so that it can transfer tokens from msg.sender to this contract
    
    /// @notice User can deposit his tokens into the contract
    /// @param _amount Amount to deposit
    /// @param _tokenSymbol Which token to deposit either TKNA or TKNB
    function deposit(uint256 _amount, string memory _tokenSymbol) public {
        require(_amount > 0, "Depositing amount should be greater thab 0");
        
        if((keccak256(bytes(_tokenSymbol)) == keccak256(bytes("TKNA")))) {
            require(TokenA(tokenAAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to deposit tokens");
            TokenA(tokenAAddress).transferFrom(msg.sender, address(this), _amount);
            
        } else if ((keccak256(bytes(_tokenSymbol)) == keccak256(bytes("TKNB")))) {
            require(TokenB(tokenBAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to deposit tokens");
            TokenB(tokenBAddress).transferFrom(msg.sender, address(this), _amount);
        }
        
        storedBalances[msg.sender][_tokenSymbol] = _amount;
        
        emit Deposited(msg.sender, _amount, _tokenSymbol);
    }
    
    
    /// @notice User can trade specific amount of TKNA to TKNB and vice versa
    /// @param _amount Amount to trade
    /// @param _fromToken Token sysbol user wants to trade from
    /// @param _fromToken Token sysbol user wants to trade to
    function trade(uint256 _amount, string memory _fromToken, string memory _toToken) public {
        require(_amount > 0, "Trading amount should be greater thab 0");
        
        if((keccak256(bytes(_fromToken)) == keccak256(bytes("TKNA")))) {
            require( TokenA(tokenAAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to trade tokens");
            
        } else if ((keccak256(bytes(_toToken)) == keccak256(bytes("TKNB")))) {
            require( TokenB(tokenBAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to trade tokens");
        }
        
        if((keccak256(bytes(_toToken)) == keccak256(bytes("TKNA")))) {
            require( TokenA(tokenAAddress).balanceOf(address(this)) >= _amount, "Exchange does not have enough balance to give traded tokens");
            TokenA(tokenAAddress).transfer(msg.sender, _amount);
            
        } else if ((keccak256(bytes(_toToken)) == keccak256(bytes("TKNB")))) {
            require( TokenB(tokenBAddress).balanceOf(address(this)) >= _amount, "Exchange does not have enough balance to give traded tokens");
            TokenB(tokenBAddress).transfer(msg.sender, _amount);
        }
        
        storedBalances[msg.sender][_fromToken] = storedBalances[msg.sender][_fromToken].sub(_amount);
       
        storedBalances[msg.sender][_toToken] = storedBalances[msg.sender][_toToken].add(_amount);
       
        emit Traded(msg.sender, _amount, _fromToken, _toToken);
    }

    
    /// @notice User can withdraw his previously deposited tokens from the exchange
    /// @param _amount Amount of tokens to withdraw
    /// @param _tokenSymbol Which token to withdraw either TKNA or TKNB
    function withdraw(uint256 _amount, string memory _tokenSymbol) public {
        require(_amount > 0, "Withdraw amount should be greater thab 0");
        
        require(storedBalances[msg.sender][_tokenSymbol] >= _amount, "Not enough balance to withdraw");
        
        if((keccak256(bytes(_tokenSymbol)) == keccak256(bytes("TKNA")))) {
            require(TokenA(tokenAAddress).balanceOf(address(this)) >= _amount, "Exchange does not have enough balance.");
            TokenA(tokenAAddress).transfer(msg.sender, _amount);
            
        } else if ((keccak256(bytes(_tokenSymbol)) == keccak256(bytes("TKNB")))) {
            require(TokenB(tokenBAddress).balanceOf(address(this)) >= _amount, "Exchange does not have enough balance.");
            TokenB(tokenBAddress).transfer(msg.sender, _amount);
        }
       
        storedBalances[msg.sender][_tokenSymbol] = storedBalances[msg.sender][_tokenSymbol].sub(_amount);
        
        emit Withdraw(msg.sender, _amount, _tokenSymbol);
    }
    
}