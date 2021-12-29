/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256 _totalSupply);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface ERC223 {
    function transfer(address _to, uint256 _value, bytes calldata _data) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
}

abstract contract ERCReceivingContract {
    function ERC223ReceivingContract(address _mock) public {}
    function tokenFallback(address _from, uint256 _value, bytes calldata _data) public virtual;
}

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 1000;
    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) internal _allowances;

    constructor(string memory symbol, string memory name, uint8 decimals, uint256 totalSupply) {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function __name() public view returns (string memory) {
        return _name;
    }

    function __symbol() public view returns (string memory) {
        return _symbol;
    }

    function __decimals() public view returns (uint8) {
        return _decimals;
    }

    function __totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

contract MyFirstToken is Token("MFT", "My First Token", 18, 1000), ERC20, ERC223 {

    using SafeMath for uint256;

    constructor () {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _addr) override public view returns (uint256) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {

        if (_value > 0 && _value <= _balanceOf[msg.sender] && !isContract(_to)) {
            _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transfer(address _to, uint256 _value, bytes calldata _data) override external returns (bool) {
        if (_value > 0 && _value <= _balanceOf[msg.sender] && isContract(_to)) {
            _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to].add(_value);
            ERCReceivingContract _contract = ERCReceivingContract(_to);
            _contract.tokenFallback(msg.sender, _value, _data);
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        return false;
    }

    function isContract(address _addr) internal view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {

        if (_allowances[_from][msg.sender] > 0 && _value > 0 && _allowances[_from][msg.sender] >= _value 
        && _balanceOf[_from] >= _value) {
            _balanceOf[_from].sub(_value);
            _balanceOf[_to].add(_value);
            _allowances[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint256 _value) override public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override public view returns (uint256) {
        return _allowances[_owner][_spender];
    }
}