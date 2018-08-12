// ----------------------------------------------------------------------------
// BlackGold token contract
//
// (c) 2018 BlackGold
// ----------------------------------------------------------------------------

pragma solidity ^0.4.18;

contract SafeMath
{
	function safeAdd(uint a, uint b) public pure returns (uint c)
	{
		c = a + b;
		require(c >= a);
	}
	
	function safeSub(uint a, uint b) public pure returns (uint c)
	{
		require(b <= a);
		c = a - b;
	}
	
	function safeMul(uint a, uint b) public pure returns (uint c)
	{
		c = a * b;
		require(a == 0 || c / a == b);
	}
	
	function safeDiv(uint a, uint b) public pure returns (uint c)
	{
		require(b > 0);
		c = a / b;
	}
}


contract Owned
{
	address public owner;
	address public newOwner;
	
	event OwnershipTransferred
	(
		address indexed owner,
		address indexed newOwner
	);
	
	constructor() public
	{
		owner = msg.sender;
	}
	
	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
	}
	
	function transferOwnership(address _newOwner) onlyOwner public
	{
		newOwner = _newOwner;
	}
	
	function acceptOwnership() public
	{
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}


contract ERC20Interface
{
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer
	(
		address indexed from,
		address indexed to,
		uint tokens
	);
	
	event Approval
	(
		address indexed tokenOwner,
		address indexed spender,
		uint tokens
	);
}


contract StandardERC20Token is ERC20Interface, SafeMath
{
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	uint256 public totalSupply;
	
	mapping(address => bool) frozen;
	mapping(address => uint) balanceOfAddress;
	mapping(address => mapping(address => uint)) allowed;
	
	constructor(string _tokenName, string _tokenSymbol) public
	{
		name = _tokenName;
		symbol = _tokenSymbol;
	}
	
	function totalSupply() public view returns (uint)
	{
		return totalSupply - balanceOfAddress[address(0)];
	}
	
	function balanceOf(address tokenOwner) public view returns (uint balance)
	{
		return balanceOfAddress[tokenOwner];
	}
	
	function allowance(address tokenOwner, address spender) public view returns (uint remaining)
	{
		return allowed[tokenOwner][spender];
	}
	
	function transfer(address to, uint tokens) public returns (bool success)
	{
		require(to != address(0));
		require(!frozen[msg.sender]);
		require(!frozen[to]);
		balanceOfAddress[msg.sender] = safeSub(balanceOfAddress[msg.sender], tokens);
		balanceOfAddress[to] = safeAdd(balanceOfAddress[to], tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}
	
	function approve(address spender, uint tokens) public returns (bool success)
	{
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	
	function transferFrom(address from, address to, uint tokens) public returns (bool success)
	{
		require(to != address(0));
		require(!frozen[msg.sender]);
		require(!frozen[to]);
		balanceOfAddress[from] = safeSub(balanceOfAddress[from], tokens);
		allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
		balanceOfAddress[to] = safeAdd(balanceOfAddress[to], tokens);
		emit Transfer(from, to, tokens);
		return true;
	}

	function isFrozenAccount(address target) public constant returns (bool freezed)
	{
		return frozen[target];
	}
}


contract ICO is Owned
{
	uint public ethRatio = 0;
	uint public timeStart = 0;
	uint public timeEnd = 0;
	uint public raiseGoal = 0;
	uint public currentRaised = 0;

	event OpenSale
	(
		uint _start,
		uint _end,
		uint _tokensPerEth,
		uint _goal
	);
	
	event TokenSold
	(
	    address indexed buyer,
	    uint tokens
	);
	
	event SellTokenFalied
	(
	    address indexed buyer,
	    uint tokens,
	    string msg
	);

	function buyToken(address to, uint ethIn) internal returns (bool success);

	function isSaleOpen() public view returns (bool isOpen)
	{
		return (now >= timeStart && now <= timeEnd && ethRatio > 0 && raiseGoal > 0 && currentRaised < raiseGoal);
	}
	
	function openSale(uint _start, uint _end, uint _tokensPerEth, uint _goal) onlyOwner public returns (bool success)
	{
		require(_start > now);
		require(_end > now);
		require(_tokensPerEth > 0);
		require(_goal > 0);
		ethRatio = _tokensPerEth;
		timeStart = _start;
		timeEnd = _end;
		raiseGoal = _goal;
		currentRaised = 0;
		emit OpenSale(timeStart, timeEnd, ethRatio, raiseGoal);
		return true;
	}
	
	function calculateToken(uint ethIn) public view returns (uint tokenOut)
	{
		require(ethIn > 0);
		return (ethIn * ethRatio);
	}
}


contract BlackGoldToken is StandardERC20Token, ICO
{
	address public vault;
	address public wallet;
	bool public isBurnable = false;
	bool public isMintable = false;
	
	event FreezeAccount
	(
		address indexed target,
		bool freezed
	);

	event WalletChanged
	(
		address indexed oldWallet,
		address indexed newWallet
	);

	event BurnableChanged
	(
		bool oldSetting,
		bool newSetting
	);

	event MintableChanged
	(
		bool oldSetting,
		bool newSetting
	);

	event Burn
	(
		address indexed from,
		uint tokens
	);

	event Mint
	(
		address indexed to,
		uint tokens
	);
	
	constructor
	(
		string tokenName,
		string tokenSymbol,
		uint256 initialSupply,
		address _vault,
		address _wallet
	) StandardERC20Token(tokenName, tokenSymbol) public
	{
		require(vault == address(0));
		require(_vault != address(0));
		
		totalSupply = initialSupply * 10 ** uint256(decimals);
		vault = _vault;
		wallet = _wallet;
		balanceOfAddress[vault] = totalSupply;
	}

	function freezeAccount(address target) onlyOwner public
	{
		require(target != owner);
		frozen[target] = true;
		emit FreezeAccount(target, true);
	}

	function unfreezeAccount(address target) onlyOwner public
	{
		frozen[target] = false;
		emit FreezeAccount(target, false);
	}
	
	function setWallet(address newWallet) onlyOwner public
	{
		require(newWallet != address(0));
		emit WalletChanged(wallet, newWallet);
		wallet = newWallet;
	}

	function setBurnable(bool burnable) onlyOwner public
	{
		require(burnable != isBurnable);
		emit BurnableChanged(isBurnable, burnable);
		isBurnable = burnable;
	}

	function setMintable(bool mintable) onlyOwner public
	{
		require(mintable != isMintable);
		emit MintableChanged(isMintable, mintable);
		isMintable = mintable;
	}
	
	function mintToken(address deployAddress, uint tokens) onlyOwner public
	{
		require(isMintable);
		tokens = tokens * 10 ** uint256(decimals);
		balanceOfAddress[deployAddress] += tokens;
		totalSupply += tokens;
		emit Mint(deployAddress, tokens);
		emit Transfer(0, this, tokens);
		emit Transfer(this, deployAddress, tokens);
	}

	function burnToken(uint tokens) public returns (bool success)
	{
		require(isBurnable);
		tokens = tokens * 10 ** uint256(decimals);
		balanceOfAddress[msg.sender] = safeSub(balanceOfAddress[msg.sender], tokens);
		totalSupply -= tokens;
		emit Burn(msg.sender, tokens);
		return true;
	}
	
	function buyToken(address buyer, uint ethIn) internal returns (bool success)
	{
	    require(buyer != address(0));
	    require(ethIn > 0);
	    
	    uint soldTokens = calculateToken(ethIn);
	    
	    if(balanceOfAddress[this] < soldTokens)
	    {
	        revert();
	        emit SellTokenFalied(buyer, soldTokens, "Not enough tokens.");
	        return false;
	    } else {
	        if(ERC20Interface(this).transfer(buyer, soldTokens))
	        {
        	    //balanceOfAddress[msg.sender] = safeAdd(balanceOfAddress[msg.sender], soldTokens);
        	    //balanceOfAddress[vault] = safeSub(balanceOfAddress[vault], soldTokens);
        	    currentRaised += soldTokens;
        	    emit TokenSold(buyer, soldTokens);
        	    return true;
	        } else {
	            revert();
	            emit SellTokenFalied(buyer, soldTokens, "Transfer tokens to buyer failed.");
	            return false;
	        }
	    }
	}
	
	function () public payable
	{
	    if(isSaleOpen())
	        buyToken(msg.sender, msg.value);
	        
        wallet.transfer(msg.value);
	}
	
	function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success) {
		return ERC20Interface(tokenAddress).transfer(vault, tokens);
	}
}