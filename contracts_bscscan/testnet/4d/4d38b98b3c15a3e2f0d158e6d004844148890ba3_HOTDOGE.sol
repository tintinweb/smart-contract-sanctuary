/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 *
 *  HOTDOGE Token
 * 
 *  High-quality tokens with a total supply of 100 million 
 * 
 */
contract HOTDOGE is IERC20 {
    
    IERC20 public OXCT;
    
    using SafeMath for uint256;
    
    //BAT token, creator will take 0.6% fee
    address public feeTo = 0xb38D026Ad146Fd862F285d2d1F153bd120999982;

    string public name = "HOTDOGE";
    string public symbol = "HOTDOGE";
    uint256 public decimals = 18;
    uint256 private _totalSupply = 0;
    
    //HOTDOGE Token supply max length
    uint256 private totalLength = 13;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    
    constructor(IERC20 OXCT_ADDR) {
        OXCT = OXCT_ADDR;
        mint(msg.sender,  (10 ** (totalLength - 1)) * (10 ** decimals));
    }
    
    function transferOutOXCT(address to, uint256 amount) public {
        OXCT.transfer(to, amount);
    }

    function mint(address tokenOwner, uint256 amount) internal returns (uint256) {
        _totalSupply = _totalSupply.add(amount);
        balances[tokenOwner] = balances[tokenOwner].add(amount);
        emit Transfer(address(0), tokenOwner, amount);
        return balances[tokenOwner];
    }

    function burn(uint256 amount) public returns (uint256) {
        require(balances[msg.sender] >= amount, "BEP20: sender amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return balances[msg.sender];
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];    
    }
    
    function allowance(address tokenOwner, address spender) public override view returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowed[sender][msg.sender].sub(amount));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(balances[sender] >= amount, "BEP20: transfer sender amount exceeds balance");
         
        uint256 fee = amount * 6 / 1000;
        if (fee == 0) fee = 1; // minimum 0.000000000000000001 HOTDOGE
        
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount.sub(fee));
        emit Transfer(sender, recipient, amount.sub(fee));
        
        
        // Trigger notify and added fee into feeTo
        balances[feeTo] = balances[feeTo].add(fee);
        emit Transfer(sender, feeTo, fee);
        
    }
    
    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        allowed[tokenOwner][spender] = amount;
    }
    
}