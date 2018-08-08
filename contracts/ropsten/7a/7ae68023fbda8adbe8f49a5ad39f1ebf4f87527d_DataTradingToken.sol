pragma solidity ^0.4.18;

/**
 * @title ERC20Interface
 * @dev Standart version of ERC20 interface
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
    function Ownable() public {
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
 * @title DataTradingToken
 * @dev Implemantation of the DataTrading token
 */
contract DataTradingToken is Ownable, ERC20Interface {
    string public constant symbol = "DTT";
    string public constant name = "DataTrading Token";
    uint8 public constant decimals = 18;
    uint256 private _unmintedTokens = 360000000*uint(10)**decimals;
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
      
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
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
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
        
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender
     * @param _spender The address which will spend the funds
     * @param _value The amount of tokens to be spent
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
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
     * @dev Mint DataTrading tokens. No more than 360,000,000 DTT can be minted
     * @param _target The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     */    
    function mintTokens(address _target, uint256 _mintedAmount) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        return true;
    }
    
    /**
     * @dev Mint DataTrading tokens and aproves the passed address to spend the minted amount of tokens
     * No more than 360,000,000 DTT can be minted
     * @param _target The address to which new tokens will be minted
     * @param _mintedAmount The amout of tokens to be minted
     * @param _spender The address which will spend minted funds
     */ 
    function mintTokensWithApproval(address _target, uint256 _mintedAmount, address _spender) public onlyOwner returns (bool success){
        require(_mintedAmount <= _unmintedTokens);
        balances[_target] += _mintedAmount;
        _unmintedTokens -= _mintedAmount;
        totalSupply += _mintedAmount;
        allowed[_target][_spender] += _mintedAmount;
        return true;
    }
    
    /**
     * @dev Decrease amount of DataTrading tokens that can be minted
     * @param _burnedAmount The amout of unminted tokens to be burned
     */ 
    function burnUnmintedTokens(uint256 _burnedAmount) public onlyOwner returns (bool success){
        require(_burnedAmount <= _unmintedTokens);
        _unmintedTokens -= _burnedAmount;
        return true;
    }
}