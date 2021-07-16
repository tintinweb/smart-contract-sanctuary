//SourceUnit: TGX.sol

pragma solidity 0.5.9;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: substraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract TGX {
    using SafeMath for uint256;

    string public constant name = "TGX Token";
    string public constant symbol = "TGX";
    uint256 public constant decimals = 8;
    uint256 public totalSupply = 0;
    address public owner;
    address public minter;
    uint256 public TIMELOCK = 1645920000; // 2022-02-27 00:00:00

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    mapping (address => bool) public locklist;
    mapping (address => bool) public whitelist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier transferable(address _from, address _to) {
        // If the LOCK_PERIOD is passed, the target is not in the locklist
        require(now >= TIMELOCK || whitelist[_from] || !locklist[_to], 'Transfer locked');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Permission denied');
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, 'Permission denied');
        _;
    }

    constructor() public {
        owner = msg.sender;

        // 500,000,000 TGX for sale
        _mint(msg.sender, 50000000000000000); // 500,000,000 TGX

        // 26,432,000 TGX for AMM
        _mint(msg.sender, 2643200000000000); // 26,432,000 TGX
    }

    function () external payable {
        revert();
    }

    function transfer(address payable _to, uint256 _value) external transferable(msg.sender, _to) returns (bool) {
        require(_to != address(0), "Cannot send to zero address");
        require(_to != address(this), "Cannot send to the token contract itself");
        require(balances[msg.sender] >= _value, "Insufficient fund");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) external transferable(_from, _to) returns (bool) {
        require(_to != address(0), "Cannot send to zero address");
        require(_to != address(this), "Cannot send to the token contract itfself");
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function addLocklist(address payable _addr) external onlyOwner returns (bool) {
        locklist[_addr] = true;
        return true;
    }

    function removeLocklist(address payable _addr) external onlyOwner returns (bool) {
        locklist[_addr] = false;
        return true;
    }

    function addWhitelist(address payable _addr) external onlyOwner returns (bool) {
        whitelist[_addr] = true;
        return true;
    }

    function removeWhitelist(address payable _addr) external onlyOwner returns (bool) {
        whitelist[_addr] = false;
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

    function setMinter(address _addr) public onlyOwner returns (bool) {
        minter = _addr;
        return true;
    }
    function mint(address payable _to, uint256 _amount) public onlyMinter returns (bool) {
        return _mint(_to, _amount);
    }

    function _mint(address payable _to, uint256 _amount) internal returns (bool) {
        address zeroAddress;
        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(zeroAddress, _to, _amount);
        return true;
    }

    function burn(uint256 _amount) public returns (bool) {
        address zeroAddress;
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        emit Transfer(msg.sender, zeroAddress, _amount);
        return true;
    }
}