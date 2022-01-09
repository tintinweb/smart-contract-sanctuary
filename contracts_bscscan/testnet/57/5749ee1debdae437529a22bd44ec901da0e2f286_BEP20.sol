/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: Unlicensed
//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 bsc testnet router
pragma solidity >=0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract BEP20{
    
    using SafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public immutable totalSupply;
    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;//owner=>caller=>amount

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        uint256 supply = _totalSupply * (10**_decimals);
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
    }

    function _transfer(address from, address to, uint256 amount) private{
        require(balanceOf[from]>=amount,"insuffficient balance");
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].sub(amount);
        emit Transfer(from,to,amount);
    }

    function transfer(address to, uint256 amount) external{
        _transfer(msg.sender,to,amount);
    }

    function approve(address spender, uint256 amount) external{
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender,amount);
    }

    function transferFrom(address owner, uint256 amount)external{
        require(allowance[owner][msg.sender] >= amount,"amount exceeds allowance");
        allowance[owner][msg.sender] = allowance[owner][msg.sender].sub(amount);
    }
}