//SourceUnit: MatchToken.sol

pragma solidity >=0.4.23 <0.6.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); 
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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

contract TRC20 is ITRC20 {
    using SafeMath for uint256;
    mapping (address => uint256)  _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function _transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}

contract MatchToken is TRC20 {
    using SafeMath for uint256;
    string public name="MATCH";
    string public symbol="MATCH";

    uint public decimals=6;
    bool public locked;
    address public owner;

    // addresses for token dividends playerdiv, luxe, gamedev, channelpartner
    // prizespromotion
    address public diceAddress;
    address public divContract;
    // mapping (address => uint256) public balances;
    uint256 public _minedSupply;

    event Mined(
        address player,
        address minedBy,
        uint256 amount
    );

    constructor(address _diceAddress) public {
        _totalSupply = 120000000e6;
        _minedSupply = 0;
        locked = true;
        owner = msg.sender;
        diceAddress = _diceAddress;
        _balances[diceAddress] = 0;
        divContract = address(0);
    }
    
    function unlockFunds() external {
        require(owner == msg.sender, "Only owner can unlock funds");
        locked = false;
    }
    function lockFunds() external {
        require(owner == msg.sender, "Only owner can unlock funds");
        locked = true;
    }
    
    function changeOwner(address newOwner) external {
        require(owner == msg.sender, "Only owner can change the ownership");
        owner = newOwner;
    }

    function setDivContract(address _divContract) external {
        require(owner == msg.sender, "Only owner can set div contract");
        // require(divContract == address(0), "Div Contract can be set only once");
        divContract = _divContract;
    }

    function updateGameContract(address _gameContract) external {
        require(owner == msg.sender, "Only owner can set div contract");
        // require(divContract == address(0), "Div Contract can be set only once");
        diceAddress = _gameContract;
    }
    
    //mine tokens, that only can be done from rollcontract, or owner for offchain games
    function mine(address _player, uint256 value) public {
        require(msg.sender == diceAddress || msg.sender == owner, "Only Game contract or admin can mine token");
        require(_minedSupply.add(value) <= _totalSupply, "All tokens are mined");
        _balances[_player] = _balances[_player].add(value);
        _minedSupply = _minedSupply.add(value);
        emit Mined(_player, msg.sender, value);
    }
    
    
    function transfer( address to, uint256 value) external returns(bool){
        require( !locked || owner == msg.sender || msg.sender == divContract, "tokens locked" );
        _transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) external returns(bool){
        require( !locked || owner == msg.sender || msg.sender == divContract, "tokens locked" );
        _transferFrom(from, to, value);
        return true;
    }
}