/**
 *Submitted for verification at Etherscan.io on 2020-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract WaltContract {
    address public minter;
    string public constant name = "Walt";
    string public constant symbol = "WEM";
    uint8 public constant decimals = 18;  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Burn(address indexed burner, uint256 value);
    event FrozenFunds(address target, bool frozen);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;
    uint256 totalSupply_;
    using SafeMath for uint256;
   constructor(uint256 total) public {  
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
    minter = msg.sender;
    }  
    modifier onlyOwner {
        require(msg.sender == minter);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        minter = newOwner;
    }
    function totalSupply() public view returns (uint256) {
    return totalSupply_;
    }
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
       emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
    function transfer(address receiver, uint256 amount) public virtual returns (bool) {
         _transfer(msg.sender, receiver, amount);
        return true;
    }
      function _transfer(address sender, address receiver, uint256 amount) internal virtual {
        require(sender == msg.sender, "ERC20: transfer not from sender");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(receiver != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, receiver, amount);
        balances[sender] = balances[sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(sender, receiver, amount);
    }
    function mint(address receiver, uint amount) public {
      require(msg.sender == minter);
      totalSupply_ += amount;
      balances[receiver] += amount;
      emit Transfer(msg.sender, receiver, amount);
    }
    function burn(uint256 amount) external {
      _burn(msg.sender, amount);
    }
    function _burn(address account, uint256 amount) internal {
      require(amount != 0);
      require(amount <= balances[account]);
      totalSupply_ = totalSupply_.sub(amount);
      balances[account] = balances[account].sub(amount);
      emit Transfer(account, address(0), amount);
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}
library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}