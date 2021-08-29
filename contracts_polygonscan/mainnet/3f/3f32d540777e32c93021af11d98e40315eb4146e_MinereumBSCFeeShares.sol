/**
 *Submitted for verification at polygonscan.com on 2021-08-29
*/

pragma solidity ^0.7.5;

contract MinereumBSCFeeShares { 

event BuyFeeSharesEvent(address indexed from, uint256 value, uint256 price, uint256 totalPrice);

uint256 public price = 30000000000000000000;

uint256 public sharesForSale = 500;
uint256 public sharesSold = 0;
address owner;

mapping (address => uint256) public amounts;

address[] feeShareHolders;

constructor() {
	owner = msg.sender;
}

function BuyFeeShares(uint amount) payable public
{
	uint256 totalPrice = amount * price;
	
	if (amount > sharesForSale || amount == 0) revert('invalid amount');
	if (msg.value != totalPrice) revert('value sent not correct');	
	
	sharesSold += amount;
	sharesForSale -= amount;

	if (amounts[msg.sender] == 0)	
		feeShareHolders.push(msg.sender);
	
	amounts[msg.sender] += amount;
	
	emit BuyFeeSharesEvent(msg.sender, amount, price, totalPrice);
}

function TransferFunds() public
{
	if (msg.sender == owner)
	{
		if(!payable(owner).send(address(this).balance)) revert('Error while sending payment');	
	}
}

function UpdateValues(uint256 _price, uint256 _sharesForSale) public
{
	if (msg.sender == owner)
	{
		price = _price;
		sharesForSale = _sharesForSale;
	}
}

function GetAmount(address _address) view public returns (uint256)
{
	return amounts[_address];
}

function GetFeeShareHolders() view public returns (address[] memory)
{
	return feeShareHolders;
}

function GetFeeShareHoldersAt(uint256 i) view public returns (address)
{
	return feeShareHolders[i];
}

function GetFeeShareHoldersLength() view public returns (uint256)
{
	return feeShareHolders.length;
}
}