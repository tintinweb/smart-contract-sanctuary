//SourceUnit: degree.sol

pragma solidity 0.5.12;

interface ITRC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function allowance(address owner, address spender) external view returns(uint256);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TRC20 is ITRC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);

        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns(bool) {
        _approve(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns(bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        if(allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }

        _transfer(from, to, value);

        return true;
    }
}

contract DEGREE is TRC20 {
    address public owner;
    bool public stopmint;

    modifier onlyOnwer() {
        require(msg.sender == owner, "DCT: ACCESS_DENIED");
        _;
    }

    constructor() public {
        owner = msg.sender;

        name = "DEGREE CRYPTO TOKEN";
        symbol = "DCT";
        decimals = 18;
    }

    function mint(address to, uint256 value) external onlyOnwer {
        require(!stopmint, "DCT: MINT_ALREADY_STOPED");

        _mint(to, value);
    }

    function burn(uint256 value) external onlyOnwer {
        require(balanceOf[msg.sender] >= value, "DCT: INSUFFICEINT_FUNDS");

        _burn(msg.sender, value);
    }

    function stopMint() external onlyOnwer {
        require(!stopmint, "DCT: MINT_ALREADY_STOPED");

        stopmint = true;
    }
}