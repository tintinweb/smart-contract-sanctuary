/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        uint256 c = a+b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a,uint256 b) internal pure returns (uint256){
        require( b <= a,"SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        if(a == 0) {
            return 0;
        }
        uint256 c = a*b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;        
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // return div(a,b,"SafeMath: division by zero");
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modu by zero");
        return a % b;
    }
}

contract AppleToken is IERC20 {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8  private _decimal;
    uint256 private _totalSupply;
    mapping (address => uint256) private _balanceOf;
    mapping (address => mapping(address => uint256)) private _allowances;

    constructor(string memory name,string memory symbol,uint8 decimal,uint256 initSupply) public {
        _name = name;
        _symbol = symbol;
        _decimal = decimal;
        _totalSupply = initSupply*(10**uint256(decimal));
        _balanceOf[msg.sender] = _totalSupply;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimal;
    }
    
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balanceOf[account];
    }

    function transfer(address recipient,uint256 amount) external override returns (bool) {
        _transfer(msg.sender,recipient,amount);
        return true;
    }

    function _transfer(address sender,address recipient,uint256 amount) internal {
        require(sender != address(0),"ERC20: tranfer from the zero address");
        require(recipient != address(0),"ERC20: tranfer to the zero address");

        _balanceOf[sender] = _balanceOf[sender].sub(amount);
        _balanceOf[recipient] = _balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender,spender,amount);
        return true;
    } 

    function _approve(address owner,address spender,uint256 amount) internal {
        require(owner != address(0),"ERC20: tranfer from the zero address");
        require(spender != address(0),"ERC20: tranfer to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner,spender,amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender,recipient,amount);
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount));
        return true;
    }  

    function increaseAllowance(address spender,uint256 amount) public returns (bool) {
        _approve(msg.sender,spender,_allowances[msg.sender][spender].add(amount));
        return true;
    }

    function decreaseAllowance(address spender,uint256 amount) public returns (bool) {
        _approve(msg.sender,spender,_allowances[msg.sender][spender].sub(amount));
        return true;
    }

}