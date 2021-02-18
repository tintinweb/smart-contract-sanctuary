// File: contracts/SafeMath.sol

pragma solidity 0.6.0;


/// @dev Math operations with safety checks that revert on error
library SafeMath {
    /// @dev Multiplies two numbers, reverts on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'MUL_ERROR');

        return c;
    }

    /// @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = a / b;
        return c;
    }

    /// @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SUB_ERROR');
        uint256 c = a - b;
        return c;
    }

    /// @dev Adds two numbers, reverts on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'ADD_ERROR');
        return c;
    }

    /// @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'MOD_ERROR');
        return a % b;
    }
}

interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TRC20 is ITRC20{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint256 private _totalBurnt;

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function totalBurnt() public view returns (uint256) {
        return _totalBurnt;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), 'from cannot be address(0)');
        require(to != address(0), 'to cannot be address(0)');

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        _totalBurnt = _totalBurnt.add(value);

        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import "./CNR.sol";

contract RiseTest is TRC20 {

    function mint(address _addr, uint256 _amount) public {
        _mint(_addr, _amount);
    }
}