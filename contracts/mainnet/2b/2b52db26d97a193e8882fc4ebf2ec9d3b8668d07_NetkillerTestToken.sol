pragma solidity ^0.4.25;

/******************************************/
/*       Netkiller Mini TOKEN             */
/******************************************/
/* Author netkiller <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ff919a8b949693939a8dbf928c91d19c9092">[email&#160;protected]</a>>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-09-26 Test Token          */
/******************************************/

contract NetkillerTestToken {
    address public owner;

    string public name;
    string public symbol;
    uint public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint decimalUnits
    ) public {
        owner = msg.sender;
        name = tokenName; 
        symbol = tokenSymbol; 
        decimals = decimalUnits;
        totalSupply = initialSupply * 10 ** uint256(decimals); 
        balanceOf[msg.sender] = totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function setSupply(uint256 _initialSupply) onlyOwner public{
        totalSupply = _initialSupply * 10 ** uint256(decimals);
    }
    function setName(string _name) onlyOwner public{
        name = _name;
    }
    function setSymbol(string _symbol) onlyOwner public{
        symbol = _symbol;
    }
    function setDecimals(uint _decimals) onlyOwner public{
        decimals = _decimals;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
 
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0));                        // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}