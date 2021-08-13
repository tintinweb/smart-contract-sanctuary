/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity >=0.7.0 <0.9.0;

library SafeMath { // Only relevant functions
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256)   {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}



contract SueToken {
    using SafeMath for uint256;
    uint256 totalSupply_;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    string public constant name_ = "SueToken";

    constructor(uint256 total) {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_;
    }
    
    function name() public pure returns(string memory) {
        return name_;
    }
    
    function symbol() public pure returns (string memory) {
        return "SUE";
    }
    function decimals() public pure returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address addr) public view returns(uint256) {
        return balances[addr];
    }
    
    function transfer(address dst, uint256 amount) public returns(bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[dst] += amount;
        emit Transfer(msg.sender, dst, amount);
        return true;
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens)  public returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool) {
        
    
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        balances[from] = balances[from].sub(tokens);
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}