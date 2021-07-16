//SourceUnit: LuxeSweep.sol

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
    internal
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


contract LuxeSweep is TRC20 {

    string public name="LUXE";
    string public symbol="LUXE";
    uint public decimals=6;
    bool public locked;
    address public divContract;
    address public owner;
    constructor() public {
        _totalSupply = 100000000e6;
        uint256 initialSupply = _totalSupply;
        _balances[msg.sender]=initialSupply;
        locked = true;
        owner = msg.sender;
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
        // require(divContract == address(0), "Div contract can be set only once");
        divContract = _divContract;
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