//SourceUnit: TRC20.sol

pragma solidity >=0.5.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c <= a, "SafeMath: subtraction overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b > 0, "SafeMath: division by zero");
        uint16 c = a / b;
        return c;
    }
}
pragma solidity >=0.5.12;

contract Ownable {
    address payable _owner;
    event OwnershipTransfer(address indexed oldOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransfer(address(0), msg.sender);
    }

    function owner() public view returns (address payable) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransfer(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
}
pragma solidity >=0.5.12;

contract NCT is Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 decimal
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimal);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;
        decimals=decimal;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0), "GToken:transfer from the zero address");
        require(
            balanceOf[_from] >= _value,
            "GToken:You don't have enough assets"
        );
        require(
            balanceOf[_to] + _value > balanceOf[_to],
            "GToken:Assets overflow"
        );

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(
            _value <= allowance[_from][msg.sender],
            "GToken:Insufficient convertible assets"
        );
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(
            _spender != address(0),
            "GToken: Approve from the zero address"
        );
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool) {
        require(
            balanceOf[msg.sender] >= _value,
            "GToken: Shortage of available assets"
        );
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool) {
        require(
            balanceOf[_from] >= _value,
            "GToken:Shortage of available assets"
        );
        require(
            _value <= allowance[_from][msg.sender],
            "GToken:Shortage of available assets"
        );
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}