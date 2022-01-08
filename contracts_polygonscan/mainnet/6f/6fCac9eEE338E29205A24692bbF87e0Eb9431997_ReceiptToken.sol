// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

struct AppStorage {
    uint256 totalSupply;
    mapping(address => uint256) accounts;
    mapping(address => mapping(address => uint256)) allowances;
    address minter;
    string name;
    string symbol;
}

contract ReceiptToken {
    AppStorage s;

    uint256 constant MAX_UINT = uint256(-1);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor(
        address _minter,
        string memory _name,
        string memory _symbol
    ) {
        s.minter = _minter;
        s.name = _name;
        s.symbol = _symbol;
    }

    function setMinter(address _newMinter) external {
        require(msg.sender == s.minter, "Must be minter to change minter");
        s.minter = _newMinter;
    }

    function minter() external view returns (address) {
        return s.minter;
    }

    function name() external view returns (string memory) {
        return s.name;
    }

    function symbol() external view returns (string memory) {
        return s.symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return s.totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance_) {
        balance_ = s.accounts[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 fromBalance = s.accounts[msg.sender];
        require(fromBalance >= _value, "Not enough ReceiptToken to transfer");
        s.accounts[msg.sender] = fromBalance - _value;
        s.accounts[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 fromBalance = s.accounts[_from];
        if (msg.sender != _from) {
            uint256 l_allowance = s.allowances[_from][msg.sender];
            require(l_allowance >= _value, "Allowance not great enough to transfer ReceiptToken");
            if (l_allowance != MAX_UINT) {
                s.allowances[_from][msg.sender] = l_allowance - _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(fromBalance >= _value, "Not enough ReceiptToken to transfer");
        s.accounts[_from] = fromBalance - _value;
        s.accounts[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success_) {
        s.allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success_ = true;
    }

    function increaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = s.allowances[msg.sender][_spender];
        uint256 newAllowance = l_allowance + _value;
        require(newAllowance >= l_allowance, "ReceiptToken allowance increase overflowed");
        s.allowances[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function decreaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = s.allowances[msg.sender][_spender];
        require(l_allowance >= _value, "ReceiptToken allowance decreased below 0");
        l_allowance -= _value;
        s.allowances[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining_) {
        remaining_ = s.allowances[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) external {
        require(msg.sender == s.minter, "Must be minter to mint");
        s.accounts[_to] += _amount;
        s.totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(address _to, uint256 _amount) external {
        require(msg.sender == s.minter, "Must be minter to burn");
        uint256 bal = s.accounts[_to];
        require(bal >= _amount, "Can't burn more than person has");
        s.accounts[_to] = bal - _amount;
        s.totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
    }
}