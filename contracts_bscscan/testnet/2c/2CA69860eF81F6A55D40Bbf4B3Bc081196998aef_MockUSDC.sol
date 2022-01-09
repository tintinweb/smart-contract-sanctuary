pragma solidity 0.6.2;

import '@uniswap/v2-core/contracts/interfaces/IERC20.sol';

import {MockERC20} from './MockERC20.sol';

contract MockUSDC is MockERC20 {
    constructor() public MockERC20('MockUSDC', 'MUSDC') {}
}

contract MockToken is MockERC20 {
    uint256 public price;
    address public usd;

    constructor(address _usd, uint256 _price) public MockERC20('Token', 'TOKEN') {
        usd = _usd;
        price = _price;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function setPrice(uint256 newPrice) public {
        price = newPrice;
    }

    function redeem(uint256 amount) public {
        IERC20(usd).transfer(msg.sender, amount * price);
        transferFrom(msg.sender, address(0), amount);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity 0.6.2;

// Only for testing purposes!!!
contract MockERC20 {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public constant decimals = 18;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory name_, string memory symbol_) public {
        name = name_;
        symbol = symbol_;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, 'ERC20: NOT enough tokens');
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= balanceOf[_from], 'ERC20: NOT enough tokens');
        require(_value <= allowance[_from][msg.sender], 'ERC20: NOT enough allowance tokens');
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address account, uint256 amount) public {
        require(account != address(0), 'ERC20: mint to the zero address');
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}