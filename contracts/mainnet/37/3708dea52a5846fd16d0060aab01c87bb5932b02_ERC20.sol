pragma solidity ^0.6.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
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

contract MinterRole {
    bool private _initialized;
    address private _minter;

    constructor () internal {
        _initialized = false;
        _minter = msg.sender;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "Mintable: msg.sender does not have the Minter role");
        _;
    }

    function isMinter(address _addr) public view returns (bool) {
        return (_addr == _minter);
    }

    function setMinter(address _addr) public onlyMinter {
        //require(!_initialized);
        _minter = _addr;
        _initialized = true;
    }
}

contract ERC20 is MinterRole {
    using SafeMath for uint256;
    
    string public constant name = "ATEM";
    string public constant symbol = "ATEM";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 0;
    bool public frozen = false;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier isUnfrozen(){
        require(!frozen, "Transfer frozen.");
        _;
    }
    
    constructor() public {
        // Do nothing
    }

    function transfer(address _to, uint256 _value) external isUnfrozen returns (bool) {
        require(_to != address(0), "Cannot send to zero address");
        require(balances[msg.sender] >= _value, "Insufficient fund");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) external isUnfrozen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
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
    
    function mint(address payable _to, uint256 _value) external onlyMinter returns (bool) {
        balances[_to] = balances[_to].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(address(0), _to, _value);
    }

    function burn(uint256 _value) external returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient fund");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function freeze() external onlyMinter(){
        frozen = true;
    }

    function unfreeze() external onlyMinter(){
        frozen = false;
    }
}