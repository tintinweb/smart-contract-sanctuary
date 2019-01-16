pragma solidity ^0.4.25;

contract ERC20Basic {
   function balanceOf(address _who) public constant returns (uint256);
   function transfer(address _to, uint256 _value) public returns (bool);
   event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public constant returns (uint256);
    function approve(address _spender, uint256 _value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}


contract BasicToken is ERC20Basic {
    
    mapping (address => uint) balances;
    
    /**
     * @dev The balanceOf function returns the balance of the queried address. This is a constant time function as 
     * it has the &#39;view&#39; keyword meaning that this function can only read from the contract and not write to it. 
     * @param _who The address which will be queried
     * @return The total amount of tokens the address holds.
     * */
    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }
    
    
    /**
     * @dev function to transfer tokens from the msg.sender (i.e. the invoker of the function) to another address.
     * @param _to The receiving address
     * @param _value The amount of tokens to send 
     * @return true if the function executes successfully, false otherwise
     * */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        require(balanceOf(_to) > balanceOf(_to) + _value);
        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;  
    }
}


contract StandardToken is ERC20, BasicToken {
    
    mapping (address => mapping (address => uint)) public allowances;
    
    /**
     * @dev The allowance() funtion gets the total amount of tokens which an owner address has allowed a spender 
     * address to spend from the owner&#39;s balance.
     * @param _owner The address of the owner 
     * @param _spender The address of the spender 
     * @return The total allowance
     * */
    function allowance(address _owner, address _spender) public constant returns (uint256) {
        return allowances[_owner][_spender];
    }
    
    /**
     * @dev The approve() function lets the owner of tokens (i.e. the &#39;msg.sender&#39;) to allow a spender 
     * to spend up to a certain amount of tokens on behalf of the owner. 
     * @param _spender The address of the spender
     * @param _value The total amount of tokens to allow the spender to spend (hint, this can also be 0 if the owner wants to revoke the allownace of a spender)
     * @return true if the function executes successfully, false otherwise
     * */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    
    /**
     * @dev The transferFrom() function allows the spender (i.e the msg.sender) to transfer tokens from an 
     * owner which has previously approved the spender to transfer up to a certain amount of tokens from 
     * the owner&#39;s balance. 
     * @param _from This is the owner&#39;s address
     * @param _to The address which will be receiving the tokens
     * @param _value The total amount of tokens to transfer 
     * @return true if the function executes successfully, false otherwise
     * */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance(_from, msg.sender) >= _value);
        require(balanceOf(_from) >= _value);
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}


contract HackSussexCoin is StandardToken {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    constructor() public {
        name = "Hack Sussex Coin";
        symbol = "HSC";
        decimals = 18;
        totalSupply = 10000000e18; //10,000,000 tokens
        balances[msg.sender] = totalSupply;
        emit Transfer(address(this),msg.sender, totalSupply);
    }
}