/**
 *Submitted for verification at BscScan.com on 2021-12-22
*/

// SPDX-License-Identifier: DONOTCOPY


pragma solidity ^0.8.10;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

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

contract DEF is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public alloweds;

    string public name = "Baby Deflationary";
    string public symbol = "BDEF";
    uint public decimals = 33;
    uint private maxAmountDiv = 25;
    uint256 public totalSupply = 10000 * 10 ** decimals;
    uint256 public _maxAmount = totalSupply.div(maxAmountDiv);
        
    address private myself;
    
    constructor() {
        myself = msg.sender;
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }
    

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return alloweds[owner][spender];
    }

    function _transfer(address from, address to, uint256 value) private returns (bool success) {
        if (from != myself && to != myself)
            require(value <= _maxAmount, "Transfer amount exceeds the _maxAmount.");

        uint256 amountToSub;
        uint256 amountToTransfer;

        if (from != myself || to != myself) {
            amountToSub = value.div(40); // 2.5% partial
            amountToTransfer = value.sub( amountToSub.mul(2) ); // 5.0% total
        
            balances[from] = balances[from].sub( amountToSub.mul(2) );
            balances[myself] = balances[myself].add( amountToSub ); // dev - partial

            totalSupply = totalSupply.sub( amountToSub ); // to /dev/null :D
            _maxAmount = totalSupply.div(maxAmountDiv);            
        } 
        else {
            amountToTransfer = value;

            balances[from] = balances[from].sub( value );
        }

        //balances[address(0)] = balances[address(0)].add( amountToSub ); // burn
        

        balances[to] = balances[to].add( amountToTransfer );
        return true;
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");

        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(alloweds[from][msg.sender] >= value, "allowance too low");

        _transfer(from, to, value);
        emit Transfer(from, to, value);
        return true;   
    }

    function approve(address spender, uint value) public returns (bool) {
        alloweds[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }

}