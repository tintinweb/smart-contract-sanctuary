pragma solidity ^0.4.18;

library SafeMath {
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a && c >= _b);
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a * _b;
        require(_a == 0 || c / _a == _b);
        return c;
    }
}

contract CoinXPToken {
    using SafeMath for uint256;

    string public constant version = "1.0";
    string public constant name = "CoinXP";
    uint8 public constant decimals = 18;
    string public constant symbol = "CXP";
    uint256 public totalSupply = 10000000000 * 10 ** uint(decimals);
    address public owner;
    address public destination;
    uint256 public ratio;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }
    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public frozen;
    mapping(address => mapping(address => uint256)) private allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed from, uint256 value);
    event AllocateAndFreeze(address sender, address indexed to, uint256 balance, uint256 freeze, uint256 totalFreeze);
    event Unfreeze(address sender, address indexed from, uint256 balance, uint256 unFreeze, uint256 totalFreeze);
    event Trade(address sender, uint256 eth, uint256 tokens);

    constructor(address _destination, uint256 _ratio) public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        destination = _destination;
        ratio = _ratio;
    }

    function transfer(address _to, uint256 _value) validAddress public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) validAddress public returns (bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) validAddress public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Burn or destroy tokens
    function burn(uint256 _value) validAddress public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_value > 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    // Allocate and freeze "_value" tokens to address "_to"
    function allocateAndFreeze(address _to, uint256 _value) isOwner public returns (bool success) {
        require(balanceOf[owner] >= _value);
        require(_value > 0);
        balanceOf[owner] = balanceOf[owner].sub(_value);
        frozen[_to] = frozen[_to].add(_value);
        emit AllocateAndFreeze(msg.sender, _to, balanceOf[_to], _value, frozen[_to]);
        return true;
    }

    // Unfreeze the frozen allocation
    function unfreeze(address _from, uint256 _value) isOwner public returns (bool success) {
        require(frozen[_from] >= _value);
        require(_value > 0);
        frozen[_from] = frozen[_from].sub(_value);
        balanceOf[_from] = balanceOf[_from].add(_value);
        emit Unfreeze(msg.sender, _from, balanceOf[_from], _value, frozen[_from]);
        return true;
    }

    // Transfer balance to owner
    function withdrawEther(uint256 _amount) isOwner public {
        destination.transfer(_amount);
    }

    // accept ether for CXP
    function() public payable {
        if (msg.value > 0) {
            destination.transfer(msg.value);
            uint256 _value = ratio.mul(msg.value);
            require(balanceOf[owner] >= _value);
            balanceOf[owner] = balanceOf[owner].sub(_value);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
            emit Trade(msg.sender, msg.value, _value);
        }
    }
}