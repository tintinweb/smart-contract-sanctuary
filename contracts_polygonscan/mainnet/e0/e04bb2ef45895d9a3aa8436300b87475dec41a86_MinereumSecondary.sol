/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

pragma solidity ^0.6.0;

//This contract is a secondary helper contract for Minereum Polygon.
//It only displays your MNEP balance.
//To execute any operations (transfer, upgrade, etc.) you must use the main MNEP contract: 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 

interface genesisCalls {
  function AllowAddressToDestroyGenesis ( address _from, address _address ) external;
  function AllowReceiveGenesisTransfers ( address _from ) external;
  function BurnTokens ( address _from, uint256 mneToBurn ) external returns ( bool success );
  function RemoveAllowAddressToDestroyGenesis ( address _from ) external;
  function RemoveAllowReceiveGenesisTransfers ( address _from ) external;
  function RemoveGenesisAddressFromSale ( address _from ) external;
  function SetGenesisForSale ( address _from, uint256 weiPrice ) external;
  function TransferGenesis ( address _from, address _to ) external;
  function UpgradeToLevel2FromLevel1 ( address _address, uint256 weiValue ) external;
  function UpgradeToLevel3FromDev ( address _address ) external;
  function UpgradeToLevel3FromLevel1 ( address _address, uint256 weiValue ) external;
  function UpgradeToLevel3FromLevel2 ( address _address, uint256 weiValue ) external;
  function availableBalanceOf ( address _address ) external view returns ( uint256 Balance );
  function balanceOf ( address _address ) external view returns ( uint256 balance );
  function deleteAddressFromGenesisSaleList ( address _address ) external;
  function isAnyGenesisAddress ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel1 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel2 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel2Or3 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel3 ( address _address ) external view returns ( bool success );
  function ownerGenesis (  ) external view returns ( address );
  function ownerGenesisBuys (  ) external view returns ( address );
  function ownerMain (  ) external view returns ( address );
  function ownerNormalAddress (  ) external view returns ( address );
  function ownerStakeBuys (  ) external view returns ( address );
  function ownerStakes (  ) external view returns ( address );
  function setGenesisCallerAddress ( address _caller ) external returns ( bool success );
  function setOwnerGenesisBuys (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakeBuys (  ) external;
  function setOwnerStakes (  ) external;
  function BurnGenesisAddresses ( address _from, address[] calldata _genesisAddressesToBurn ) external;
}

contract MinereumSecondary { 
string public name; 
string public symbol; 
uint8 public decimals; 

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event LogStakeHolderSends(address indexed to, uint balance, uint amountToSend);
event LogFailedStakeHolderSends(address indexed to, uint balance, uint amountToSend);
event StakeTransfer(address indexed from, address indexed to, uint256 value);

genesisCalls public gn;
uint totalSupplyConst = 100000000000000000;
uint circulatingSupplyConst = 0;

address public updaterAddress = 0x0000000000000000000000000000000000000000;
address public genesisCallerAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
address public payoutOwner = 0x0000000000000000000000000000000000000000;
bool public payoutBlocked = false;
address payable public secondaryPayoutAddress = 0x0000000000000000000000000000000000000000;

modifier onlyOwner(){
    require(msg.sender == updaterAddress);
     _;
}

constructor(address _genesisCallsAddress) public {
name = "polygon.minereum.com"; 
symbol = "MNEP"; 
decimals = 8; 
setUpdater();
gn = genesisCalls(_genesisCallsAddress);
}

function registerAddressesValue(address[] memory _addressList, uint _value) public {
	uint i = 0;
	
	if (msg.sender != genesisCallerAddress) revert(); 
	
	while(i < _addressList.length)
	{
		emit Transfer(address(this), _addressList[i], _value);
		i++;
	}
}

function reloadGenesis(address _address) public { if (msg.sender == updaterAddress)	{gn = genesisCalls(_address); } else revert();}
function reloadSupply(uint total, uint circulating) public { if (msg.sender == updaterAddress)	{ totalSupplyConst = total; circulatingSupplyConst = circulating; } else revert();}
function reloadGenesisCaller(address caller) public { if (msg.sender == updaterAddress)	{ genesisCallerAddress = caller; } else revert();}


function setPayoutOwner(address _address) public
{
	if(msg.sender == updaterAddress)
		payoutOwner = _address;
	else
		revert();
}

function setSecondaryPayoutAddress(address payable _address) public
{
	if(msg.sender == payoutOwner)
		secondaryPayoutAddress = _address;
	else
		revert();
}

function SetBlockPayouts(bool toBlock) public
{
	if(msg.sender == payoutOwner)
	{
		payoutBlocked = toBlock;
	}
}


function currentEthBlock() public view returns (uint256 blockNumber) 
{
	return block.number;
}

function currentBlock() public view returns (uint256 blockNumber)
{
	return 0;
}

function availableBalanceOf(address _address) public view returns (uint256 Balance)
{
	return gn.availableBalanceOf(_address);
}

function totalSupply() public view returns (uint256 TotalSupply)
{	
	return totalSupplyConst;
}

function circulatingSupply() public view returns (uint256)
{
   return circulatingSupplyConst;
}

function transfer(address _to, uint256 _value)  public { 
revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to tansfer MNEP');
if (_to == address(this)) revert('if (_to == address(this))');
emit Transfer(msg.sender, _to, _value); 
}

function transferReserved(address _from, address _to, uint256 _value) public onlyOwner { 
emit Transfer(_from, _to, _value); 
}

function DestroyGenesisAddressLevel1() public {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578');
	if (gn.isGenesisAddressLevel1(msg.sender))
	{
		emit Transfer(msg.sender, 0x0000000000000000000000000000000000000000, balanceOf(msg.sender));
	}
	else
	{
		revert('Address not Genesis Level 1');
	}
}

function Bridge(address _address, uint _amount) public {
	revert();	
}

function transferFrom(
        address _from,
        address _to,
        uint256 _amount
) public returns (bool success) {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to transfer MNEP');
        return false;    
}

function approve(address _spender, uint256 _amount) public returns (bool success) {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to transfer MNEP');
    return false;
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to transfer MNEP');
    return 0;
}

function balanceOf(address _address) public view returns (uint256 balance) {
	return gn.balanceOf(_address);
}

function stakeBalanceOf(address _address) public view returns (uint256 balance) {
	return 0;
}

function TransferGenesis(address _to) public {
	revert('To transfer MNEP use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578');
	emit Transfer(msg.sender, _to, balanceOf(msg.sender));	
	if (_to == address(this)) revert('if (_to == address(this))');	
	gn.TransferGenesis(msg.sender, _to);	
}

function SetGenesisForSale(uint256 weiPrice) public {	
	
}

function AllowReceiveGenesisTransfers() public { 
	
}

function RemoveAllowReceiveGenesisTransfers() public { 
	
}

function RemoveGenesisAddressFromSale() public { 
	
}

function AllowAddressToDestroyGenesis(address _address) public  { 
	
}

function RemoveAllowAddressToDestroyGenesis() public { 
	
}

function UpgradeToLevel2FromLevel1() public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	gn.UpgradeToLevel2FromLevel1(msg.sender, msg.value);
}

function UpgradeToLevel3FromLevel1() public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	gn.UpgradeToLevel3FromLevel1(msg.sender, msg.value);
}

function UpgradeToLevel3FromLevel2() public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	gn.UpgradeToLevel3FromLevel2(msg.sender, msg.value);
}

function UpgradeToLevel3FromDev() public {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	gn.UpgradeToLevel3FromDev(msg.sender);
}

function UpgradeOthersToLevel2FromLevel1(address[] memory _addresses) public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	uint count = _addresses.length;
	uint i = 0;
	while (i < count)
	{
		i++;
	}
}

function UpgradeOthersToLevel3FromLevel1(address[] memory _addresses) public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	uint count = _addresses.length;
	uint i = 0;
	while (i < count)
	{
		i++;
	}
}

function UpgradeOthersToLevel3FromLevel2(address[] memory _addresses) public payable {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	uint count = _addresses.length;
	
	uint i = 0;
	while (i < count)
	{
	
		i++;
	}
}

function UpgradeOthersToLevel3FromDev(address[] memory _addresses) public {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578 to upgrade MNEP');
	uint count = _addresses.length;	
	uint i = 0;
	while (i < count)
	{
		
		i++;
	}
}

function BuyGenesisAddress(address payable _address) public payable
{
	
}

function SetNormalAddressForSale(uint256 weiPricePerMNE) public {	
	
}

function RemoveNormalAddressFromSale() public
{
	
}

function BuyNormalAddress(address payable _address) public payable{
	
}

function setBalanceNormalAddress(address _address, uint256 _balance) public
{
	
}

function ContractTransferAllFundsOut() public
{
	//in case of hack, funds can be transfered out to another addresses and transferred to the stake holders from there
	if (payoutBlocked)
		if(!secondaryPayoutAddress.send(address(this).balance)) revert();
}

function PayoutStakeHolders() public {
	
}

function stopSetup() public returns (bool success)
{
	return false;
}

function BurnTokens(uint256 mneToBurn) public returns (bool success) {	
	return false;
}

function SetStakeForSale(uint256 priceInWei) public
{	
	
}

function RemoveStakeFromSale() public {
	
}

function StakeTransferMNE(address _to, uint256 _value) public {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578');
}

function BurnGenesisAddresses(address[] memory _genesisAddressesToBurn) public
{
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578');
}

function StakeTransferGenesis(address _to, uint256 _value, address[] memory _genesisAddressesToBurn) public {
	revert('Use the main contract 0x0B91B07bEb67333225A5bA0259D55AeE10E3A578');
}

function setBalanceStakes(address _address, uint256 balance) public {
	
}

function BuyGenesisLevel1FromNormal(address payable _address) public payable {
	
}

function BuyGenesisLevel2FromNormal(address payable _address) public payable{
	
}

function BuyGenesisLevel3FromNormal(address payable _address) public payable{
	
}

function BuyStakeMNE(address payable _address) public payable {
	
}

function BuyStakeGenesis(address payable _address, address[] memory _genesisAddressesToBurn) public payable {
	
}

function Payment() public payable {
	
}

function BuyLuckyDrawTickets(uint256[] memory max) public payable {
	
}

function ExternalFunction1(uint256 _amountToStake, address[] memory _addressList, uint256[] memory uintList) public {
	
}

function isAnyGenesisAddress(address _address) public view returns (bool success) {
	return gn.isAnyGenesisAddress(_address);
}

function isGenesisAddressLevel1(address _address) public view returns (bool success) {
	return gn.isGenesisAddressLevel1(_address);
}

function isGenesisAddressLevel2(address _address) public view returns (bool success) {
	return gn.isGenesisAddressLevel2(_address);
}

function isGenesisAddressLevel3(address _address) public view returns (bool success) {
	return gn.isGenesisAddressLevel3(_address);
}

function isGenesisAddressLevel2Or3(address _address) public view returns (bool success) {
	return gn.isGenesisAddressLevel2Or3(_address);
}
}