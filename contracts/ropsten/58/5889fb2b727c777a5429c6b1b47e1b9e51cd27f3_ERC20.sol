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

	//don&#39;t need modulus, division, or multiplication
	//in our contract, so don&#39;t need to pay gas to deploy these functions
}

contract ERC20Burnable
{
    using SafeMath for uint;
	//create a mapping to hold a user&#39;s address
	mapping (address => uint) public tokens;

	//control who can receive coins
	mapping (address => bool) public receiver;

	//owner
	address public owner;

	//the total amount of tokens
	uint tokenAmt = 10000000;

	string public tokenName = "Badium";

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
		//owner is part of all addresses
		allAddresses.push(owner);
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
		tokens[burn] = 0;
	}

	//iterate all addresses that have tokens, and zero out their balances
	function burnAll() external onlyOwner
	{
		for (uint i = 0; i < allAddresses.length; i++)
		{
			tokens[allAddresses[i]] = 0;
		}
	}

	function mint(uint amt) external onlyOwner
	{
		//import safemath and use safemath later to prevent underflows
		tokens[owner] = tokens[owner].add(amt);
	}
}

contract ERC20 is ERC20Burnable
{

    function getBalance() public view returns (uint)
    {
        //get the caller&#39;s balance
        return tokens[msg.sender];
    }

    function getBalanceOf(address find) public view returns (uint)
    {
        //get an addresses token balance
        return tokens[find];
    }

    //only the owner can initiate a super transfer, hence only owner modifier
    function superTransfer(address sendfrom, address to, uint amt) external onlyOwner
	{
	    //make sure that the person we are taking tokens from has the amount we are using
	    require(tokens[sendfrom] >= amt);
	    //take them away from their account, and give them to the target address
	    tokens[sendfrom] = tokens[to].subtract(amt);
	    tokens[to] = tokens[to].add(amt);
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
	function transfer(address sendto, uint amt) public
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
	}

	//has to be internal because this is for the ICO
	function transferTokens(address sendfrom, address sendto, uint amt) internal
	{
		require(tokens[sendfrom] >= amt);
		allAddresses.push(sendto);
		tokens[sendfrom] = tokens[sendfrom].subtract(amt);
		tokens[sendto] = tokens[sendto].add(amt);
		avail = avail.subtract(amt);
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
}