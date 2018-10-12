pragma solidity ^0.4.24;

library SafeMath
{
	function add(uint a, uint b) public pure returns (uint)
	{
		uint ret = a + b;
		require(ret >= a);
		return ret;
	}

	function subtract(uint a, uint b) public pure returns (uint)
	{
		require(a >= b);
		return a - b;
	}

	//don&#39;t need modulus, subtraction, or multiplilcation in
	//our contract, so don&#39;t need to pay gas to deploy
}

contract ERC20Burnable
{
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
  event Transfer(address indexed from, address indexed to, uint tokens);

  using SafeMath for uint;
	//create a mapping to hold a user&#39;s address
	mapping (address => uint) public tokens;

	//control who can receive coins
	mapping (address => bool) public receiver;

	//authorize people to send tokens on your behalf
	mapping (address => mapping (address => uint)) authorize;

	//owner
	address public owner;

	//the total amount of tokens
	uint tokenAmt = 10000000;

	string public tokenName = "Badium";
	string public symbol = "BDM";

	address[] public allAddresses;
	uint avail = 10000000;

	constructor () public
	{
		//define the owner
		owner = msg.sender;
		//give the owner all 10,000,000 tokens
		tokens[owner] = tokenAmt;
		//owner is authorized to receive funds
		receiver[owner] = true;
		//owner is an address of someone who owns tokens
		allAddresses.push(owner);
	}

	function approve(address spender, uint amt) public returns (bool)
	{
		authorize[msg.sender][spender] = amt;
		emit Approval(msg.sender, spender, amt);
		return true;
	}

	//get an allowance for a person
	function allowance(address tokenOwner, address delegate) public view returns (uint)
	{
		return authorize[tokenOwner][delegate];
	}

	//make an onlyowner modifier, we only want the owner to be able to access certain functions
	modifier onlyOwner()
	{
		require(msg.sender == owner);
		_;
	}

	function allowNewReceiver(address allowed) external onlyOwner
    {
        //this person can now receive tokens
        receiver[allowed] = true;
    }

    function disallowReceiver(address disallowed) external onlyOwner
    {
        //this person can no longer receive tokens
        receiver[disallowed] = false;
    }

	//burn function
	function burnAddress(address burn) external onlyOwner
	{
	    //subtract this amount of tokens from the total supply
	    tokenAmt = tokenAmt.subtract(tokens[burn]);
		tokens[burn] = 0;
	}

	//iterate all addresses that have tokens, and zero out their balances
	function burnAll() external onlyOwner
	{
		for (uint i = 0; i < allAddresses.length; i++)
		{
			tokens[allAddresses[i]] = 0;
		}
		//token amount is now 0
		tokenAmt = 0;
	}

	//owner can mint an infinite amount of new tokens
	function mint(uint amt) external onlyOwner
	{
		tokens[owner] = tokens[owner].add(amt);
		//make sure that we update total token amount to reflect changes made by minting these new tokens
		tokenAmt = tokenAmt.add(amt);
	}

	//get the total supply
	function totalSupply() public view returns (uint256)
	{
		return tokenAmt;
	}
}

contract ERC20 is ERC20Burnable
{

    function getBalance() public view returns (uint)
    {
        //get the caller&#39;s balance
        return tokens[msg.sender];
    }

    function balanceOf(address find) public view returns (uint)
    {
        //get an addresses token balance
        return tokens[find];
    }

    //only the owner can initiate a super transfer, hence only owner modifier
    function superTransfer(address sendfrom, address to, uint amt) external onlyOwner
	{
	    //make sure that the person we are taking tokens from has the amount we are using
	    require(tokens[sendfrom] >= amt);
	    //make sure the person they are sending to is authorized to receive tokens
	    require(receiver[to] == true);
	    //take them away from their account, and give them to the target address
	    tokens[sendfrom] = tokens[sendfrom].subtract(amt);
	    tokens[to] = tokens[to].add(amt);
		emit Transfer(sendfrom, to, amt);
	}

	function withdrawAllEth() onlyOwner external payable
	{
		//cast current contract to an address
		//then call the .balance method to return the contract balance
		require(address(this).balance > 0);
		//use .transfer so that we throw an error if we fail to send
		msg.sender.transfer(address(this).balance);
	}

	//for external and non ICO transfers
	function transfer(address sendto, uint amt) public returns (bool)
	{
	    //make sure we have enough tokens to send
		require(tokens[msg.sender] >= amt);
		//make sure receiver is authorized
		require(receiver[sendto] == true);
		//push this person&#39;s address onto the list of everyone who owns tokens
		//in the event of burning all tokens, this person will have their balance zero&#39;d
		allAddresses.push(sendto);
		//subtract tokens from the sender
		tokens[msg.sender] = tokens[msg.sender].subtract(amt);
		//add tokens to the person we are sending tokens to
		tokens[sendto] = tokens[sendto].add(amt);
		//log this transfer as an event
		emit Transfer(msg.sender, sendto, amt);
		return true;
	}

	//has to be internal because this is for the ICO
	function transferTokens(address sendfrom, address sendto, uint amt) internal
	{
		require(tokens[sendfrom] >= amt);
		allAddresses.push(sendto);
		tokens[sendfrom] = tokens[sendfrom].subtract(amt);
		tokens[sendto] = tokens[sendto].add(amt);
		avail = avail.subtract(amt);
		emit Transfer(sendfrom, sendto, amt);
	}

	function buyTokens() public payable
	{
	    //make sure that they sent enough ether to buy a single token
		require(msg.value >= 1 ether / 100);
		//you get 100 badium tokens per 1 ether
		uint256 amt = (msg.value * 100) / 1 ether;
		//make sure there are enough tokens left to buy
		require(tokens[owner] >= amt && amt <= avail);
		//call internal function to initiate the transfer
		transferTokens(owner, msg.sender, amt);
	}

	function transferFrom(address tokenOwner, address to, uint amt) public returns (bool)
	{
		//make sure the owner has coins to take out of his balance
		require(tokens[tokenOwner] >= amt);
		//make sure that the person who is trying to authorize this spending, is allowed to do so
		require(authorize[tokenOwner][msg.sender] >= amt);
		//subtract balance from the token owner
		tokens[tokenOwner] = tokens[tokenOwner].subtract(amt);
		//de-authorize this person from amt amount of tokens
		authorize[tokenOwner][msg.sender] = authorize[tokenOwner][msg.sender].subtract(amt);
		//add tokens to the person who bought tokens
		tokens[to] = tokens[to].add(amt);
		emit Transfer(tokenOwner, to, amt);
		return true;
	}
}