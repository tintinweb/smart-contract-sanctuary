pragma solidity ^0.4.24;

// Cryptocurrency Lab https://open.kakao.com/o/gwIZCsK

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

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract TokenController is OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    uint public totalSupply;
    uint public maxSupply;
    
    mapping (address => uint) internal payTokens;
    mapping (uint => address) internal countAddresses;
    
    uint public addressesLength;
    uint public ethPerToken;
    uint public tokenDecimals;
    
    bool public payLock;

    constructor() public
    {
        owner = msg.sender;
        countAddresses[0] = msg.sender;
        payTokens[msg.sender] = 0;
        
        name = &quot;SafeShareOne&quot;;
        decimals = 18;
        symbol = &quot;SSO&quot;;
        
        totalSupply = 0;
        maxSupply = 50.5 ether;
        
        addressesLength = 1;
        ethPerToken = 1;
        payLock = false;
    }
    
    function () payable public
    {
        require(totalSupply.add(msg.value) <= maxSupply);
        require(payLock == false);
        
        if(payTokens[msg.sender] == 0)
        {
            addressesLength = addressesLength.add(1);
            countAddresses[addressesLength] = msg.sender;
        }
        
        uint tokens = 99;
        tokens = tokens.mul(msg.value).div(100);
        
        payTokens[msg.sender] = payTokens[msg.sender].add(tokens);
        payTokens[owner] = payTokens[owner].add(msg.value - tokens);
        totalSupply = totalSupply.add(msg.value);
        
        owner.transfer(address(this).balance);
    }
    
    function totalSupply() constant public returns (uint) 
    {
        return totalSupply;
    }
    
    function balanceOf(address _who) public view returns (uint) 
    {
        return payTokens[_who];
    }
    
    function setMaxSupply(uint _value) onlyOwner public
    {
        maxSupply = _value;
    }
    
    function setPayLock(bool _lock) onlyOwner public
    {
        payLock = _lock;
    }
    
    function setEthPerToken(uint amount) onlyOwner public
    {
        require(ethPerToken != amount);
        ethPerToken = amount;
    }
    
    function setTokenDecimals(uint _decimals) onlyOwner public
    {
        require(_decimals <= 18 || _decimals > 0);
        ethPerToken = ( ethPerToken.div(1 ether) ).mul(10 ** _decimals);
    }
    
    function tokenWithdraw(address tokenAddress, uint amount, uint _decimals) onlyOwner public
    {
        uint value = amount * ( 10 ** _decimals );
        
        if(tokenAddress == address(0))
        {
            require(owner.send(value));
        }
        else
        {
            require (Token(tokenAddress).transfer(owner, value));
        }
    }
    
    function tokenMultiTransfer(address tokenAddress) onlyOwner public
    {
        for(uint i = 0; i <= addressesLength; i++)
        {
            address pAddress = countAddresses[i];
            if(payTokens[pAddress] > 0)
            {
                uint tokens = ethPerToken.mul(payTokens[pAddress]);
                
                Token(tokenAddress).transfer(pAddress, tokens);

                totalSupply = totalSupply.sub(payTokens[pAddress]);
                payTokens[pAddress] = 0;
            }
        }
    }
}