/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

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
    function add(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x + y) >= x, "SafeMath: MATH_ADD_OVERFLOW");
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require((z = x - y) <= x, "SafeMath: MATH_SUB_UNDERFLOW");
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: MATH_MUL_OVERFLOW");
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

contract WMUSIC is TRC20 {
    address public owner;
    bool public stopmint;

    modifier onlyOnwer() {
        require(msg.sender == owner, "WMUSIC: ACCESS_DENIED");
        _;
    }

    constructor() public {
        owner = msg.sender;

        name = "Wave Music";
        symbol = "WMUSIC";
        decimals = 18;
    }

    function mint(address to, uint256 value) external onlyOnwer {
        require(!stopmint, "WMUSIC: MINT_ALREADY_STOPED");

        _mint(to, value);
    }

    function burn(uint256 value) external onlyOnwer {
        require(balanceOf[msg.sender] >= value, "WMUSIC: INSUFFICEINT_FUNDS");

        _burn(msg.sender, value);
    }

    function stopMint() external onlyOnwer {
        require(!stopmint, "WMUSIC: MINT_ALREADY_STOPED");

        stopmint = true;
    }
}