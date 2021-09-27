/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract XPOT {
    using SafeMath for uint256;

    string public constant name = "Human-Machine Interaction";
    string public constant symbol = "HMI";
    uint8 public constant decimals = 8;
    uint256 public constant transactionFees = 2000000;
    uint256 public constant totalSupply = 1_113_220e8;
    uint256 public constant totalAirDrop = 445_288e8;
    uint256 public actualAirDrop;
    uint256 internal constant MASK = type(uint256).max;
    address public owner;
    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event AirDrop(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != MASK) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            "_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "_transferTokens: cannot transfer to the zero address"
        );
        
        uint256 destroyAmount = amount.mul(transactionFees).div(1e8);
        balances[address(0)] = balances[address(0)].add(destroyAmount);
        emit Transfer(address(this), address(0), destroyAmount);
        
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount.sub(destroyAmount));
        emit Transfer(src, dst, amount);
    }
    
    function airDrop(address to, uint256 amount) public {
        require(msg.sender == owner && balances[msg.sender] >= amount && actualAirDrop.add(amount) <= totalAirDrop);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        actualAirDrop = actualAirDrop.add(amount);
        emit Transfer(address(this), to, amount);

        emit AirDrop(to, amount);
    }
}

library SafeMath {
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return sub(_a, _b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b <= _a, _errorMessage);
        uint256 c = _a - _b;
        return c;
    }

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        require(c / _a == _b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return div(_a, _b, "SafeMath: division by zero");
    }

    function div(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b > 0, _errorMessage);
        uint256 c = _a / _b;
        return c;
    }

    function mod(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return mod(_a, _b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 _a,
        uint256 _b,
        string memory _errorMessage
    ) internal pure returns (uint256) {
        require(_b != 0, _errorMessage);
        return _a % _b;
    }
}