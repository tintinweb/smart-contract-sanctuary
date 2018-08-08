pragma solidity ^0.4.11;

interface IERC20 {
    //function totalSupply() public constant returns (uint256 totalSupply);
    function balanceOf(address _owner) external constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address _spender, uint256 _value);
}

contract SafeMath {
    
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
}

contract StandardToken is IERC20 {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    SafeMath safeMath = new SafeMath();

    function StandardToken() public payable {

    }

    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_value > 0 && balances[msg.sender] >= _value);
        balances[msg.sender] = safeMath.sub(balances[msg.sender], _value);
        balances[_to] = safeMath.add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_value > 0 && allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeMath.sub(balances[_from], _value);
        balances[_to] = safeMath.add(balances[_to], _value);
        allowed[_from][msg.sender] = safeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address _spender, uint256 _value);
}

contract OwnableToken is StandardToken {
    
    address internal owner;
    
    uint public totalSupply = 10000000000 * 10 ** 8;
    
    function OwnableToken() public payable {

    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit OwnershipTransfer(owner, _newOwner);
    }
    
    function account(address _from, address _to, uint256 _value) onlyOwner public {
        require(_from != address(0) && _to != address(0));
        require(_value > 0 && balances[_from] >= _value);
        balances[_from] = safeMath.sub(balances[_from], _value);
        balances[_to] = safeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }
    
    function make(uint256 _value) public payable onlyOwner returns (bool success) {
        require(_value > 0x0);

        balances[msg.sender] = safeMath.add(balances[msg.sender], _value);
        totalSupply = safeMath.add(totalSupply, _value);
        emit Make(_value);
        return true;
    }
    
    function burn(uint256 _value) public payable onlyOwner returns (bool success) {
        require(_value > 0x0);
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeMath.sub(balances[msg.sender], _value);
        totalSupply = safeMath.sub(totalSupply, _value);
        emit Burn(_value);
        return true;
    }
    
    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);
    event Make(uint256 value);
    event Burn(uint256 value);
}

contract HTL is OwnableToken {
    
    string public constant symbol = "HTL";
    string public constant name = "HT Charge Link";
    uint8 public constant decimals = 8;
    
    function HTL() public payable {
        owner = 0xbd9ccc7bfd2dc00b59bdbe8898b5b058a31e853e;
        balances[owner] = 10000000000 * 10 ** 8;
    }
}