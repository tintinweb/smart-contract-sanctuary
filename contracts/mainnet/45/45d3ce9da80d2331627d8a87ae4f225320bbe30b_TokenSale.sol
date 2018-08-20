pragma solidity ^0.4.24;
contract YellowBetterToken
{
    string public constant name = "Yellow Better";
    string public constant symbol = "YBT";
    uint8 public constant decimals = 18;
    uint public constant _totalSupply = 2000000000000000000000000000;
    uint public totalSupply = _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed, address indexed, uint);
    event Approval(address indexed, address indexed, uint);
    event Burn(address indexed, uint);
    constructor()
    {
        balances[msg.sender] = totalSupply;
    }
    function sub(uint a, uint b) private pure returns (uint)
    {
        require(a >= b);
        return a - b;
    }
    function balanceOf(address tokenOwner) view returns (uint)
    {
        return balances[tokenOwner];
    }
    function transfer(address to, uint tokens) returns (bool)
    {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) returns (bool)
    {
        // subtract tokens from both balance and allowance, fail if any is smaller
        balances[from] = sub(balances[from], tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) returns (bool)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) view returns (uint)
    {
        return allowed[tokenOwner][spender];
    }
    function burn(uint tokens)
    {
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        totalSupply -= tokens;
        emit Burn(msg.sender, tokens);
    }
}
contract TokenSale
{
    address public creator;
    address public tokenContract;
    uint public tokenPrice; // in wei
    uint public deadline;
    constructor(address source)
    {
        creator = msg.sender;
        tokenContract = source;
    }
    function setPrice(uint price)
    {
        if (msg.sender == creator) tokenPrice = price;
    }
    function setDeadline(uint timestamp)
    {
        if (msg.sender == creator) deadline = timestamp;
    }
    function buyTokens(address beneficiary) payable
    {
        require(
            block.timestamp < deadline
            && tokenPrice > 0
            && YellowBetterToken(tokenContract).transfer(beneficiary, 1000000000000000000 * msg.value / tokenPrice));
    }
    function payout()
    {
        creator.transfer(this.balance);
    }
}