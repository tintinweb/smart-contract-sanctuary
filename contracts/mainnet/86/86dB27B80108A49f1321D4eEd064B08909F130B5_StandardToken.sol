pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

}

// The Contract is Standard Token Issue Template.
//
// @Author: Tim Mars
// @Date: 2018.7.15
// @Seealso: ERC20 Token
//
contract StandardToken {
    
    // === Event ===
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);


    // === Defined ===
    using SafeMath for uint;
 
    // --- ERC20 Token Section ---
    uint8 constant public decimals = 6; // **** decimals ****
    uint constant public totalSupply = 1*10**(8+6);  // 100 Million **** decimals ****
    string constant public name = "Standard Token Template Token";
    string constant public symbol = "MNT";
    
    address public owner;
    bool public frozen = false; // 
    
    mapping(address => uint) ownerance; // Owner Balance
    mapping(address => mapping(address => uint)) public allowance; // Allower Balance
    
    // === Modifier ===
    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotFrozen() {
        require(!frozen);
        _;
    }

    modifier hasEnoughBalance(uint _amount) {
        require(ownerance[msg.sender] >= _amount);
        require(ownerance[msg.sender] + _amount >= ownerance[msg.sender]); // Overflow detected
        _;
    }

    modifier hasAllowBalance(address _owner, address _allower, uint _amount) {
        require(allowance[_owner][_allower] >= _amount);
        _;
    }

    modifier isNotEmpty(address _addr, uint _value) {
        require(_addr != address(0));
        require(_value != 0);
        _;
    }

    modifier isValidAddress {
        assert(0x0 != msg.sender);
        _;
    }

    // === Constructor ===
    constructor() public {
        owner = msg.sender;
        ownerance[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    // --- ERC20 Token Section ---
    function approve(address _spender, uint _value) 
        isValidAddress
        isNotFrozen
        public returns (bool success) 
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0); // must spend to 0 where pre approve balance.
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) 
        isValidAddress
        isNotFrozen
        public returns (bool success) 
    {
        require(ownerance[_from] >= _value);
        require(ownerance[_to] + _value >= ownerance[_to]);
        require(allowance[_from][msg.sender] >= _value);
        ownerance[_to] = ownerance[_to].add(_value);
        ownerance[_from] = ownerance[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public
        constant returns (uint balance) 
    {
        balance = ownerance[_owner];
        return balance;
    }
    

    function transfer(address _to, uint _value) public
        isNotFrozen
        isValidAddress
        isNotEmpty(_to, _value)
        hasEnoughBalance(_value)
        returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[_to] = ownerance[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
 
    // --- Owner Section ---
    function transferOwner(address _newOwner) 
        isOwner
        public returns (bool success)
    {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
        return true;
    }
    
    function freeze() 
        isOwner
        public returns (bool success)
    {
        frozen = true;
        return true;
    }
    
    function unfreeze() 
        isOwner
        public returns (bool success)
    {
        frozen = false;
        return true;
    }
    
    function burn(uint _value)
        isNotFrozen
        isOwner
        hasEnoughBalance(_value)
        public returns (bool success)
    {
        ownerance[msg.sender] = ownerance[msg.sender].sub(_value);
        ownerance[0x0] = ownerance[0x0].add(_value);
        emit Transfer(msg.sender, 0x0, _value);
        return true;
    }
    
  
}