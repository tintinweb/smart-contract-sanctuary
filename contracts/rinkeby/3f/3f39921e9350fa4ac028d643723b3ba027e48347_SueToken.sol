/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract SueToken {
    uint256 totalSupply_;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    string public constant name = "SueToken";
    string public constant symbol = "SUE";
    uint8 public constant decimals = 18;

    constructor(uint256 total) {
       totalSupply_ = total;
       balances[msg.sender] = totalSupply_;
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
        balances[from] -= tokens;
        balances[to] += tokens;
        allowed[from][msg.sender] -= tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
}