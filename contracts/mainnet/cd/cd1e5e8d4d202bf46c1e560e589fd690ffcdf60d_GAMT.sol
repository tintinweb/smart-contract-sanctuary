pragma solidity ^0.4.24;

/**
 * @title ERC20Interface
 * @dev Standard version of ERC20 interface
 */
contract ERC20Interface {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` 
     * of the contract to the sender account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the current owner
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

/**
 * @title GAMT
 * @dev Implemantation of the GAMT token
 */
contract GAMT is Ownable, ERC20Interface {
    using SafeMath for uint256;
    
    string public constant symbol = "GAMT";
    string public constant name = "GAMT";
    uint8 public constant decimals = 18;
    uint256 private _unmintedTokens = 300000000 * uint(10) ** decimals;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed _address, uint256 _value);
    event Mint(address indexed _address, uint256 _value);
      
    /**
     * @dev Gets the balance of the specified address
     * @param _owner The address to query the the balance of
     * @return An uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    /**
     * @dev Transfer token to a specified address
     * @param _to The address to transfer to
     * @param _value The amount to be transferred
     */  
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    
    /**
     * @dev Transfer tokens from one address to another 
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value The amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        assert(balances[_to] + _value >= balances[_to]);
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub( _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender
     * @param _spender The address which will spend the funds
     * @param _value The amount of tokens to be spent
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * @dev Function to check the amount of tokens than an owner allowed to a spender
     * @param _owner The address which owns the funds
     * @param _spender The address which will spend the funds
     * @return A uint specifing the amount of tokens still avaible for the spender
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Mint GAMT tokens. No more than 300,000,000 GAMT can be minted
     * @param _account The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     */    
    function mintTokens(address _account, uint256 _mintedAmount) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        
        balances[_account] = balances[_account].add(_mintedAmount);
        _unmintedTokens = _unmintedTokens.sub(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        emit Mint(_account, _mintedAmount);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. 
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0.
     * Emits an Approval event.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Mint GAMT tokens and aproves the passed address to spend the minted amount of tokens
     * No more than 300,000,000 GAMT can be minted
     * @param _target The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     * @param _spender The address which will spend minted funds
     */ 
    function mintTokensWithApproval(address _target, uint256 _mintedAmount, address _spender) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        
        balances[_target] = balances[_target].add(_mintedAmount);
        _unmintedTokens = _unmintedTokens.sub(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        allowed[_target][_spender] = allowed[_target][_spender].add(_mintedAmount);
        emit Mint(_target, _mintedAmount);
        return true;
    }
    
    /**
     * @dev Decrease amount of GAMT tokens that can be minted
     * @param _burnedAmount The amount of unminted tokens to be burned
     */ 
    function burnUnmintedTokens(uint256 _burnedAmount) public onlyOwner returns (bool success){
        require(_burnedAmount <= _unmintedTokens);
        _unmintedTokens = _unmintedTokens.sub(_burnedAmount);
        emit Burn(msg.sender, _burnedAmount);
        return true;
    }
    

    /**
     * @dev Function that burns an amount of the token of a given
     * account.
     * @param _account The account whose tokens will be burnt.
     * @param _value The amount that will be burnt.
     */
    function burn(address _account, uint256 _value) onlyOwner public {
        require(_account != address(0));

        totalSupply = totalSupply.sub(_value);
        balances[_account] = balances[_account].sub(_value);
        
        emit Burn(_account, _value);

    }

    /**
     * @dev Function that burns an amount of the token of a given
     * account, deducting from the sender&#39;s allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param _account The account whose tokens will be burnt.
     * @param _value The amount that will be burnt.
     */
    function burnFrom(address _account, uint256 _value) onlyOwner public {
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_value);
        burn(_account, _value);
        
        emit Burn(_account, _value);
    }
    

    /**
     * @dev Returns the number of unminted token
     */
    function unmintedTokens() onlyOwner view public returns (uint256 tokens){
        return _unmintedTokens;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    assert(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    assert(c >= _a);

    return c;
  }
}