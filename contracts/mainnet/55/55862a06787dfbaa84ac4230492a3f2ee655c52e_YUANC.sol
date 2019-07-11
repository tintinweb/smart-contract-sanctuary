/**
 *Submitted for verification at Etherscan.io on 2019-07-07
*/

pragma solidity 0.5.10;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 
// 
// ----------------------------------------------------------------------------

contract YUANC is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "Yuanc";
    string public constant symbol = "YUC";
    uint8  public constant decimals = 18;
    
    uint constant public _decimals18 = uint(10) ** decimals;
    uint public _totalSupply = 888888888888 * _decimals18;
    
    event Burn(address indexed burner, uint256 value);

    constructor() public { 
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

// ----------------------------------------------------------------------------
// mappings for implementing ERC20 
// ERC20 standard functions
// ----------------------------------------------------------------------------
    
    // Balances for each account
    mapping(address => uint) balances;
    
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    // Get the token balance for account `tokenOwner`
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _toAddress, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        addToBalance(_toAddress, _tokens);
        emit Transfer(_from, _toAddress, _tokens);
    }
    
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _add, uint _tokens) public returns (bool success) {
        require(_add != address(0));
        require(_tokens <= balances[msg.sender]);
        _transfer(msg.sender, _add, _tokens);
        return true;
    }

    /*
        Allow `spender` to withdraw from your account, multiple times, 
        up to the `tokens` amount.If this function is called again it 
        overwrites the current allowance with _value.
    */
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /*
        Send `tokens` amount of tokens from address `from` to address `to`
        The transferFrom method is used for a withdraw workflow, 
        allowing contracts to send tokens on your behalf, 
        for example to "deposit" to a contract address and/or to charge
        fees in sub-currencies; the command should fail unless the _from 
        account has deliberately authorized the sender of the message via
        some mechanism; we propose these standardized APIs for approval:
    */
    function transferFrom(address from, address _toAddr, uint tokens) public returns (bool success) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, _toAddr, tokens);
        return true;
    }
    

    // address not null
    modifier addressNotNull(address _addr){
        require(_addr != address(0));
        _;
    }

    // Add to balance
    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }
	
	 /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /* Burn token */
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }
    
    
    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

}