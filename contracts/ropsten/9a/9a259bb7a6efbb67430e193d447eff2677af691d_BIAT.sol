pragma solidity 0.4.25;


library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);
        uint256 c = _a / _b;

        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract BIAT is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) private allowed;

    uint256 private totalSupply_ = 15000000 * 10 ** 4;

    address crowdsale;
    bool crowdsaleIsSet;

    string public constant name = "Bet It All Token";
    string public constant symbol = "BIAT";
    uint8 public constant decimals = 4;

    constructor() public {
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function setAddressOfCrowdsale(address _address) external onlyOwner {
        require(_address != 0x0 && !crowdsaleIsSet);
        crowdsale = _address;
        crowdsaleIsSet = true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function _mint(address account, uint256 value) internal {
        require(account != 0);
        totalSupply_ = totalSupply_.add(value);
        balances[account] = balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function mint(address to, uint256 value) public returns (bool) {
        require(msg.sender == crowdsale);
        _mint(to, value);
        return true;
    }
}


contract Crowdsale is Ownable {
    using SafeMath for uint256;

    address public multisig;

    BIAT public token;

    uint public rate = 200;

    bool public paused;

    uint hardcapBIAT = 20000000 * 10 ** 4;

    event Purchased(address indexed _addr, uint _amount);

    modifier isNotOnPause() {
        require(!paused);
        _;
    }

    constructor(address _BIAT, address _multisig) public {
        require(_BIAT != 0);
        token = BIAT(_BIAT);
        multisig = _multisig;
    }

    function() external payable {
        buyTokens();
    }

    function buyTokens() public isNotOnPause payable {

        uint256 amount = msg.value.mul(rate).div(10 ** 14);

        if (token.totalSupply() + amount > hardcapBIAT) {
            amount = hardcapBIAT - token.totalSupply();
            uint256 cash = amount.mul(10 ** 14).div(rate);
            uint256 cashBack = msg.value.sub(cash);
            multisig.transfer(cash);
            msg.sender.transfer(cashBack);
            paused = true;
        } else {
            multisig.transfer(msg.value);
        }

        token.mint(msg.sender, amount);
        emit Purchased(msg.sender, amount);
    }

    function getMyBalanceBIAT() external view returns(uint256) {
        return token.balanceOf(msg.sender);
    }
}