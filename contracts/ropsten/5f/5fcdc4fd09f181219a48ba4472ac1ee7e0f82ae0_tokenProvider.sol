pragma solidity ^0.4.24;
// Made By Yoondae - ydwinha@gmail.com - https://blog.naver.com/ydwinha

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a / b;

        return c;  
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);

        return c;
    }
}

contract OwnerHelper
{
    address public owner;

    event OwnerTransferPropose(address indexed _from, address indexed _to);

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    constructor() public
    {
        owner = msg.sender;
    }

    function transferOwnership(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != address(0x0));
        owner = _to;
        emit OwnerTransferPropose(owner, _to);
    }

}

contract ERC20Interface
{
    function totalSupply() constant public returns (uint _supply);
    function balanceOf( address _who ) public view returns (uint _value);
}

contract tokenProvider is ERC20Interface, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    address public wallet;
    uint constant private E18 = 1000000000000000000;
    uint public maxSupply = 100000000 * E18;
    uint public totalSupply = 0;
    uint public tokenPerEther = 1000;

    uint public etherReceived = 0;

    mapping (address => uint) internal balances;

    constructor() public
    {
        name = &quot;testTokenProvider&quot;;
        decimals = 18;
        symbol = &quot;TTP&quot;;
        totalSupply = 0;
        
        owner = msg.sender;
        wallet = msg.sender;
    }
    
    function () payable public
    {
        buyCoin();
    }
    
    function buyCoin() private
    {
        uint tokens = msg.value.mul(tokenPerEther);
        
        require(maxSupply >= totalSupply.add(tokens));
        
        totalSupply = totalSupply.add(tokens);
        etherReceived = etherReceived.add(msg.value);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        
        wallet.transfer(address(this).balance);
    }
    
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) public view returns (uint) 
    {
        return balances[_who];
    }
}