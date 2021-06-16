/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicERC20 is IERC20 {
    using SafeMath for uint256; //protect against integer overflow attack
    string public constant name = "Test Token";
    string public constant symbol = "TToken";
    uint8 public constant decimals = 18;
    uint256 total_supply;
    mapping(address => uint256) balances; //token contract tracks balances in state
    mapping(address => mapping (address => uint256)) allowed;

    constructor(uint256 total) public {
        total_supply = total;
        balances[msg.sender] = total_supply;
    }
    
    function totalSupply() public override view returns (uint256) {
        return total_supply;
    }

    function balanceOf(address token_owner) public override view returns (uint256) {
        return balances[token_owner];
    }

    function transfer(address receiver, uint256 num_tokens) public override returns (bool) {
        require(num_tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(num_tokens);
        balances[receiver] = balances[receiver].add(num_tokens);
        emit Transfer(msg.sender, receiver, num_tokens);
        return true;
    }

    function approve(address delegate, uint256 num_tokens) public override returns (bool) {
        allowed[msg.sender][delegate] = num_tokens;
        emit Approval(msg.sender, delegate, num_tokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 num_tokens) public override returns (bool) {
        require(num_tokens <= balances[owner]);
        require(num_tokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(num_tokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(num_tokens);
        balances[buyer] = balances[buyer].add(num_tokens);
        emit Transfer(owner, buyer, num_tokens);
        return true;
    }
}