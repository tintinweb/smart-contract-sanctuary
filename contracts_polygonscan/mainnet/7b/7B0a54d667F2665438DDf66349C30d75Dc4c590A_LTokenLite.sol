// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../interface/ILTokenLite.sol";
import "./ERC20.sol";

contract LTokenLite is ILTokenLite, ERC20 {

    address _pool;

    modifier _pool_() {
        require(msg.sender == _pool, 'LToken: only pool');
        _;
    }

    constructor (string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function pool() public override view returns (address) {
        return _pool;
    }

    function setPool(address newPool) public override {
        require(newPool != address(0), 'LToken: setPool to 0 address');
        require(_pool == address(0) || msg.sender == _pool, 'LToken: setPool not allowed');
        _pool = newPool;
    }

    function mint(address account, uint256 amount) public override _pool_ {
        require(account != address(0), 'LToken: mint to 0 address');

        _balances[account] += amount;
        _totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public override _pool_ {
        require(_balances[account] >= amount, 'LToken: burn amount exceeds balance');

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC20.sol';

interface ILTokenLite is IERC20 {

    function pool() external view returns (address);

    function setPool(address newPool) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../interface/IERC20.sol';

contract ERC20 is IERC20 {

    string _name;

    string _symbol;

    uint8 constant _decimals = 18;

    uint256 _totalSupply;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowances;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), 'ERC20.approve: to 0 address');
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), 'ERC20.transfer: to 0 address');
        require(_balances[msg.sender] >= amount, 'ERC20.transfer: amount exceeds balance');
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(to != address(0), 'ERC20.transferFrom: to 0 address');
        require(_balances[from] >= amount, 'ERC20.transferFrom: amount exceeds balance');

        if (msg.sender != from && _allowances[from][msg.sender] != type(uint256).max) {
            require(_allowances[from][msg.sender] >= amount, 'ERC20.transferFrom: amount exceeds allowance');
            uint256 newAllowance = _allowances[from][msg.sender] - amount;
            _approve(from, msg.sender, newAllowance);
        }

        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}