//SourceUnit: TronDeFiToken.sol

pragma solidity ^0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract TRC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
    function burn(uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
}

contract StandardToken is TRC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender], "Insufficient allowed");
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_from != address(0), "Address is null");
        require(_to != address(0), "Address is null");
        require(_value <= balances[_from], "Insufficient balance");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract TronDeFiToken is StandardToken {
    string   public name;
    string   public symbol;
    uint256  public decimals;

    address funds1;
    address funds2;

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply, address _funds1, address _funds2) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;
        funds1 = _funds1;
        funds2 = _funds2;
    }

    function exchange() public payable returns (bool) {
        require(msg.value >= 1000 trx, "A minimum of 1000 TRX to exchange TDF");

        uint256 funds1_amount = msg.value * 80 / 100;
        uint256 funds2_amount = msg.value - funds1_amount;

        require((funds1_amount + funds2_amount) == msg.value);

        address(uint160(funds1)).transfer(funds1_amount);
        address(uint160(funds2)).transfer(funds2_amount);
        
        return _transfer(address(this), msg.sender, msg.value);
    }

    function query_account(address addr)public view returns(uint256, uint256) {
        return (balances[addr], addr.balance);
    }
}