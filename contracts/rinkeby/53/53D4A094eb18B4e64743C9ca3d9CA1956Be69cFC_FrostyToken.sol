pragma solidity >=0.5.0 < 0.6.0;

import "./Owned.sol";

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint balance);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function transfer(address _to, uint _tokens) external returns (bool success);
    function approve(address _spender, uint _tokens) external returns (bool success);
    function transferFrom(address _from, address _to, uint _tokens) external returns (bool success);
    event Transfer(address indexed _from, address indexed _to, uint _tokens);
    event Approval(address indexed _owner, address indexed _spender, uint _tokens);
}

contract FrostyToken is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    uint public _totalSupply;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Frosty Token";
        symbol = "FRST";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        
        balances[0xA35513E8c108e11A4295B5977592aD0BBB67a12a] = _totalSupply;
        emit Transfer(address(0), 0xA35513E8c108e11A4295B5977592aD0BBB67a12a, _totalSupply);
    }
    
    // Generates a public event on the blockchain that will notify clients
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );
    
    // This notifies clients about the amount burnt
    event Burn(
        address indexed from, 
        uint value
    );                                                                                          
    
    // Generates a public event on the blockchain that will notify clients
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );
    
    // This creates an array with all balances
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
  
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }
    
    /**
     * Internal transfer, can only be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0x0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) >= balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }
    
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint _value) public returns(bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
     * Returns the amount of tokens approved by the owner that can be transferred to the spender's account
     */
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    /**
     * Get the token balance for account `tokenOwner`
     */
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    /** 
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0x0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
    
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value is the amount of token to burn
     */
    function burn(uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint _value) public returns (bool success) {
        require(balances[_from] >= _value);                
        require(_value <= allowed[_from][msg.sender]); 
        balances[_from] =  balances[_from].sub(_value);                        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);             
        _totalSupply = _totalSupply.sub(_value);                             
        emit Burn(_from, _value);
        return true;
    }
    
    /**
     * Owner can transfer out any accidentally sent ERC20 tokens
     */

    function transferAnyERC20Token(address _tokenAddress, uint _tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }
    
}

pragma solidity >=0.5.0 < 0.6.0;

/**
 * @title Owned
 * Copied from OpenZeppelin/openzeppelin-contracts/blob/master/contracts/ownership/Ownable.sol
 * @dev The Owned contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
  
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

/**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  
    constructor() public {
        owner = msg.sender;
    }

/**
  * @dev Throws if called by any account other than the owner.
  */
  
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

/**
 * @dev Allows the current owner to transfer control of the contract to a newOwner.
 * @param _newOwner is the address to transfer ownership to.
 */
 
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner); 
    }
}

