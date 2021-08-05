pragma solidity >0.5.99 <0.8.0;

import "./Owner.sol";
import "./SafeMath.sol";
import "./ERC20Interface.sol";



contract Coins is ERC20Interface,SafeMath,Owner
{
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 private totalsupply;


    mapping(address => uint256) Balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() public
    {
        name = "WOW Coin";
        symbol = "WOW";
        decimals = 18;
        totalsupply = 1000000000 * 10**decimals;
        Balances[msg.sender] = totalsupply;
    }


    function totalSupply() public view override returns (uint256)
    {
        return totalsupply;
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance)
    {
        return Balances[tokenOwner];
    }

    function allowance(address from, address who) isFreezelisted(from) public override view returns (uint remaining)
    {
        return allowed[from][who];
    }

    function transfer(address to, uint tokens) isFreezelisted(msg.sender) public override returns (bool success)
    {
        Balances[msg.sender] = safeSub(Balances[msg.sender],tokens);
        Balances[to] = safeAdd(Balances[to],tokens);
       emit Transfer(msg.sender,to,tokens);
        return true;
    }

    function approve(address to, uint tokens) isFreezelisted(msg.sender) public override returns (bool success)
    {
        allowed[msg.sender][to] = tokens;
        emit Approval(msg.sender,to,tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) isFreezelisted(from) public override returns (bool success)
    {
        require(allowed[from][msg.sender] >= tokens ,"Not sufficient allowance");
        Balances[from] = safeSub(Balances[from],tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender],tokens);
        Balances[to] = safeAdd(Balances[to],tokens);
        emit Transfer(from,to,tokens);
        return true;
    }

}