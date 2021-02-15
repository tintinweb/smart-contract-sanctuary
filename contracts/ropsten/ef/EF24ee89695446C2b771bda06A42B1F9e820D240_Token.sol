/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function transfer(address to, uint amount) external returns (bool);
    
    function allowance(address account, address from) external view returns (uint256);
    function approve(address from, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed account, address indexed from, uint amount);
}

contract Token is ERC20Interface {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint public decimals;
    uint private total_supply;
    uint private max_total_supply;
    address public founder;
    mapping(address => uint) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (address => bool)) private _is_approved;
    
    modifier onlyFounder() {
        require(msg.sender == founder);
        _;
    }

    constructor() {
        name = "Social Life and Virgin Environment";
        symbol = "SLAVE";
        decimals = 18;
        total_supply = 80000 * 1000000000000000000;
        max_total_supply = 80000 * 1000000000000000000;
        founder = msg.sender;
        balances[founder] = total_supply;
    }
    
    function _approve(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(recipient != address(0), "ERC20: approve to the zero address");

        _is_approved[sender][recipient] = true;
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() override public view returns(uint) {
        return total_supply;
    }

    function maxTotalSupply() public view returns(uint) {
        return max_total_supply;
    }

    function balanceOf(address account) override public view returns (uint balance) {
        return balances[account];
    }
    
    function allowance(address _account, address _contract) override public view returns (uint256) {
        return _allowances[_account][_contract];
    }
    
    function isApproved(address _account, address _contract) public view returns (bool) {
        return _is_approved[_account][_contract];
    }
    
    function approve(address _contract, uint _amount) override public returns (bool) {
        _approve(msg.sender, _contract, _amount);
        return true;
    }

    function transfer(address recipient, uint amount) override public returns (bool) {
        require(balances[msg.sender] >= amount && amount > 0);
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _amount) override public returns (bool) {
        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, _allowances[_from][msg.sender].sub(_amount));
        return true;
    }
    
    function mint(address to, uint256 amount) public onlyFounder {
        require(total_supply.add(amount) < max_total_supply);
        total_supply = total_supply.add(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
    }
    
    function setNewFounder(address newAddress) public onlyFounder {
        founder = newAddress;
    }
}