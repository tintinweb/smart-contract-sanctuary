// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract TERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowances;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), 'ERC20.approve: to 0 address');
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), 'ERC20.transfer: to 0 address');
        require(balances[msg.sender] >= amount, 'ERC20.transfer: amount exceeds balance');
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0), 'ERC20.transferFrom: to 0 address');
        require(balances[from] >= amount, 'ERC20.transferFrom: amount exceeds balance');

        if (msg.sender != from && allowances[from][msg.sender] != type(uint256).max) {
            require(allowances[from][msg.sender] >= amount, 'ERC20.transferFrom: amount exceeds allowance');
            uint256 newAllowance = allowances[from][msg.sender] - amount;
            _approve(from, msg.sender, newAllowance);
        }

        _transfer(from, to, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public {
        balances[account] += amount;
        totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public {
        balances[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

}