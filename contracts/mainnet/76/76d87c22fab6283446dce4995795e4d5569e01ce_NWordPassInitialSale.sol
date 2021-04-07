/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.5.0;

// Contract details
//
// Name      	: NWord Pass Initial Sale
// Token		: NWORD
// Rate 		: 0.001 ETH = 1 NWORD 

contract SafeMath
{
    function safeAdd(uint _a, uint _b) public pure returns (uint c) 
    {
        c = _a + _b;
        require(c >= _a);
    }

    function safeSub(uint _a, uint _b) public pure returns (uint c) 
    {
        require(_b <= _a);
        c = _a - _b;
    }

    function safeMul(uint _a, uint _b) public pure returns (uint c) 
    {
        c = _a * _b;
        require(_a == 0 || c / _a == _b);
    }

    function safeDiv(uint _a, uint _b) public pure returns (uint c) 
    {
        require(_b > 0);
        c = _a / _b;
    }
}

contract ERC20Interface
{
	function totalSupply() public view returns (uint256);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NWordPassInitialSale is SafeMath
{
	ERC20Interface nwordToken;

	address payable collectionWallet;

	uint256 public rate;

	uint256 public weiRaised;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	constructor() public
	{
		nwordToken = ERC20Interface(0xce122cAb7b014FF5a2abB8D62c3eDD2e22e56789);

		collectionWallet = 0x378F195FD87aE983209FBd788326e25dc9933d19;

		rate = 1000;
	}

	function () external payable
	{
		buyTokens(msg.sender);
	}

	function buyTokens(address beneficiary) public payable 
	{
		require(beneficiary != address(0));
		require(msg.value > 0);

		uint256 weiAmount = msg.value;

		uint256 tokenAmount = safeMul(weiAmount, rate);

		weiRaised = safeAdd(weiRaised, weiAmount);

		nwordToken.transfer(beneficiary, tokenAmount);

		emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokenAmount);

		collectionWallet.transfer(msg.value);
	}

	function availableTokens() public view returns (uint256)
	{
		return nwordToken.balanceOf(address(this));
	}

	function releaseTokens() public
	{
        require(msg.sender == collectionWallet);
        
        uint256 amount = nwordToken.balanceOf(address(this));
        
        nwordToken.transfer(collectionWallet, amount);
	}
}