/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

/**
 *Subm"SPDX-License-Identifier: mit
*/
pragma solidity ^0.7.5;

interface erc20 {
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);    
}

interface erc20Validation {
    function balanceOf(address _address, address _tokenAddress) external view returns (uint balance);    
}

contract bscswap
{	

address public _owner;

uint public fee;
uint public feeDecimals;

address public payoutAddress;

modifier onlyOwner(){
    require(msg.sender == _owner);
     _;
}
	
constructor() {
	_owner = msg.sender;
	feeDecimals = 1000000;
}

event AddTokenEvent(address indexed _tokenAddress);
event SetForSaleEvent(address indexed _seller, address indexed _tokenAddress, uint _balance, uint _weiPriceUnitToken, bool update);
event RemovedFromSaleEvent(address indexed _seller, address indexed _tokenAddress);
event SoldEvent(address indexed _seller, address indexed _buyer, address indexed _tokenAddress, uint256 _balance, uint _weiPriceUnitToken, uint _totalPrice, uint _fee);

mapping (address => address) public SecondaryValidation;
mapping (address => mapping (address => uint)) public weiPriceUnitTokenList;

function SetForSale(address tokenAddress, uint weiPriceUnitToken) public
{	
	if (weiPriceUnitToken == 0) revert('price cannot be zero');
		
	erc20 token = erc20(tokenAddress);
	uint balance = token.balanceOf(msg.sender);
	
	if (SecondaryValidation[tokenAddress] != 0x0000000000000000000000000000000000000000)
	{
		erc20Validation vc = erc20Validation(SecondaryValidation[tokenAddress]);
		balance = vc.balanceOf(msg.sender, tokenAddress);
	}
	
	if (balance == 0) revert('balance cannot be zero');
	if (token.allowance(msg.sender, address(this)) < balance) revert('approve not granted');
	
	if (weiPriceUnitTokenList[msg.sender][tokenAddress] == 0)
	{
		emit AddTokenEvent(tokenAddress);
		emit SetForSaleEvent(msg.sender, tokenAddress, balance, weiPriceUnitToken, false);
	}
	else
	{
		emit SetForSaleEvent(msg.sender, tokenAddress, balance, weiPriceUnitToken, true);
	}
	
	weiPriceUnitTokenList[msg.sender][tokenAddress] = weiPriceUnitToken;
}

function Buy(address seller, address tokenAddress) public payable
{	
	if (seller == msg.sender) revert('buyer and seller cannot be the same');
	
	erc20 token = erc20(tokenAddress);
	uint allowance = getAvailableBalanceForSale(seller, tokenAddress);
	
	uint sellerPrice = weiPriceUnitTokenList[seller][tokenAddress] * allowance / 10**token.decimals();
	uint buyFee = fee * sellerPrice / feeDecimals;
	
	if ((msg.value != sellerPrice + buyFee) || msg.value == 0) revert('Price sent not correct');
	
	token.transferFrom(seller, msg.sender, allowance);
	
	if(!payable(seller).send(sellerPrice)) revert('Error while sending payment to seller');	
	
	emit SoldEvent(seller, msg.sender, tokenAddress, allowance, weiPriceUnitTokenList[seller][tokenAddress], (sellerPrice + buyFee), buyFee);
	
	weiPriceUnitTokenList[seller][tokenAddress] = 0;
}

function RemoveFromSale(address tokenAddress, bool checkAllowance) public
{
	if (getTokenAllowance(msg.sender, tokenAddress) > 0 && checkAllowance) revert('Approve Needs to be Removed First');
	if (weiPriceUnitTokenList[msg.sender][tokenAddress] != 0)
	{		
		weiPriceUnitTokenList[msg.sender][tokenAddress] = 0;
		emit RemovedFromSaleEvent(msg.sender, tokenAddress);
	}
	else
	{
		revert('Token not set for sale');
	}
}

function getWeiPriceUnitTokenList(address seller, address tokenAddress) public view returns(uint) 
{
	return weiPriceUnitTokenList[seller][tokenAddress];
}

function getFinalPrice(address seller, address tokenAddress) public view returns(uint) 
{
	erc20 token = erc20(tokenAddress);
	uint allowance = getAvailableBalanceForSale(seller, tokenAddress);
	uint sellerPrice = weiPriceUnitTokenList[seller][tokenAddress] * allowance / 10**token.decimals();
	uint buyFee = fee * sellerPrice / feeDecimals;
	return sellerPrice + buyFee;
}

function getFinalPriceWithoutFee(address seller, address tokenAddress) public view returns(uint) 
{
	erc20 token = erc20(tokenAddress);
	uint allowance = getAvailableBalanceForSale(seller, tokenAddress);
	uint sellerPrice = weiPriceUnitTokenList[seller][tokenAddress] * allowance / 10**token.decimals();
	return sellerPrice;
}

function getTokenAllowance(address seller, address tokenAddress) public view returns(uint)
{
	erc20 token = erc20(tokenAddress);
	return token.allowance(seller, address(this));
}

function getAvailableBalanceForSale(address seller, address tokenAddress) public view returns(uint)
{
	uint allowance = erc20(tokenAddress).allowance(seller, address(this));
	if (SecondaryValidation[tokenAddress] == 0x0000000000000000000000000000000000000000)
	{
	    uint balance = erc20(tokenAddress).balanceOf(seller);
		if (balance > allowance)
			return allowance;
		else
			return balance;		
	}
	else
	{	
		uint balance = erc20Validation(SecondaryValidation[tokenAddress]).balanceOf(seller, tokenAddress);
		if (balance > allowance)
			return allowance;
		else
			return balance;
	}
}

function setForSaleBalance(address seller, address tokenAddress) public view returns(uint)
{
	if (SecondaryValidation[tokenAddress] == 0x0000000000000000000000000000000000000000)
	{
	    return erc20(tokenAddress).balanceOf(seller);			
	}
	else
	{	
		return erc20Validation(SecondaryValidation[tokenAddress]).balanceOf(seller, tokenAddress);		
	}
}

function setSecondaryValidation(address tokenAddress, address validationContractAddress) public onlyOwner
{
	SecondaryValidation[tokenAddress] = validationContractAddress;
}

function setFee(uint _fee) public onlyOwner
{
	fee = _fee;
}

function setPayoutAddress(address _address) public onlyOwner
{
	payoutAddress = _address;
}

function setFeeDecimals(uint _feeDecimals) public onlyOwner
{
	feeDecimals = _feeDecimals;
}

function approvePayout() public
{
	if(!payable(payoutAddress).send(address(this).balance)) revert('Error while sending payment');	
}
}