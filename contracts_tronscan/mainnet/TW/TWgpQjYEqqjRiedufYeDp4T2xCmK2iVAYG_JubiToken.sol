//SourceUnit: JT.sol

pragma solidity ^0.5.0;

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed _from, address indexed _to);
}

contract JubiToken is Token {
    address private contractOwner;
    string public name;
    uint8 public decimals;
    string public symbol;

    constructor() public {
        totalSupply = 1000000*(10**18);
        balances[msg.sender] = totalSupply;

        name = "Jubi Token";
        decimals = 18;
        symbol = "JT";
        contractOwner = msg.sender;
    }

    function owner() public view returns (address) {
        return contractOwner;
    }

    modifier onlyOwner {
        require(contractOwner == msg.sender, "ERC20: caller is not the owner");
        _;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != address(0x0));

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 value) public {
        require(balances[msg.sender] >= value, "ERC20: amount insufficient");

        totalSupply -= value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, address(0), value);
    }

    function release(address _to, uint256 amount) public onlyOwner {
        balances[_to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), msg.sender, amount);
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping(address => uint256)) allowed;
}