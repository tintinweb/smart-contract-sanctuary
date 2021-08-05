/**
 *Submitted for verification at Etherscan.io on 2020-12-01
*/

pragma solidity ^0.6.0;

interface external1 {
  function TransferGenesis ( address _from, address _to ) external;  
  function setOwnershipTransferContract() external;
}

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
  function setGenesisAddress ( address _from, address _address ) external;
  function setGenesisAddressArray ( address _from, address[] calldata _addressList ) external;
  function setGenesisAddressDevArray ( address _from, address[] calldata _addressList ) external;
  function setGenesisCallerAddress ( address _caller ) external returns ( bool success );
  function setOwnerGenesisBuys (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakeBuys (  ) external;
  function setOwnerStakes (  ) external;
  function setOwnerBaseTransfers (  ) external;
  function setOwnerExternal1 (  ) external;
  function stopSetup ( address _from ) external returns ( bool success );
}

interface minereum {
  function Payment () payable external;
}

contract Level1OwnershipExchange
{

external1 public ext1;
genesisCalls public gn;

minereum public mneAddress;
	
function reloadExternal1(address _address) public { if (msg.sender == updaterAddress)	{ext1 = external1(_address); ext1.setOwnershipTransferContract(); } else revert();}

function reloadGenesis(address _address) public { if (msg.sender == updaterAddress)	{gn = genesisCalls(_address); } else revert();}

function reloadFee(uint _fee) public { if (msg.sender == updaterAddress)	{ fee = _fee; } else revert();}

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}

constructor(address _genesisCallsAddress, address _external1Address) public {
setUpdater();
ext1 = external1(_external1Address); 
ext1.setOwnershipTransferContract();
gn = genesisCalls(_genesisCallsAddress); 
mneAddress = minereum(0x426CA1eA2406c07d75Db9585F22781c096e3d0E0);
}	


mapping (address => bool) public isLevel1SetForOwnershipSale; 
mapping (address => uint256) public level1OwnewshipSalePrice; 
mapping (address => bool) public wasEverSetForSale; 
mapping (address => bool) public wasEverRemovedForSale; 
uint public fee = 20;
uint public countSales = 0;
uint public countSetForSale = 0;
uint public countRemoveForSale = 0;

event Level1OwnershipTransfer(address indexed sellet, address indexed buyer);

function setLevel1AddressForOwnershipSale(uint weiPrice) public {
	if (weiPrice == 0) revert('Price cannot be 0');
	
	if (!gn.isGenesisAddressLevel1(msg.sender)) revert('Not level 1');
	
	if (isLevel1SetForOwnershipSale[msg.sender]) revert('Already Set For Ownership Sale');
	
	isLevel1SetForOwnershipSale[msg.sender] = true;
	level1OwnewshipSalePrice[msg.sender] = weiPrice;	
	countSetForSale++;
	wasEverSetForSale[msg.sender] = true;
}

function removeLevel1AddressForOwnershipSale() public {
	if (isLevel1SetForOwnershipSale[msg.sender])
	{
		isLevel1SetForOwnershipSale[msg.sender] = false;
		level1OwnewshipSalePrice[msg.sender] = 0;	
		countRemoveForSale++;
		wasEverRemovedForSale[msg.sender] = true;
	}
	else
	{
		revert('Adderss not set for ownership sale');
	}
}

function getIsLevel1SetForOwnershipSale(address _address) public view returns (bool) {
	return isLevel1SetForOwnershipSale[_address];	
}

function getLevel1OwnershipSalePrice(address _address) public view returns (uint) {
	return level1OwnewshipSalePrice[_address];	
}

function getLevel1OwnershipSalePriceWithFee(address _address) public view returns (uint) {
	uint feeAmount = level1OwnewshipSalePrice[_address] * fee / 100;
	return level1OwnewshipSalePrice[_address] + feeAmount;	
}

function BuyLevel1Ownership(address _seller) payable public { 
	if (!isLevel1SetForOwnershipSale[_seller]) revert('Address Not Set For Ownership Sale');
	if (level1OwnewshipSalePrice[_seller] == 0) revert('Price cannot be 0');

	if 	(msg.value == getLevel1OwnershipSalePriceWithFee(_seller))
	{	
		mneAddress.Payment.value(getLevel1OwnershipSalePriceWithFee(_seller) - getLevel1OwnershipSalePrice(_seller))();
		
		if (!payable(_seller).send(getLevel1OwnershipSalePrice(_seller))) revert('Error While Executing Payment.');	
		
		ext1.TransferGenesis(_seller, msg.sender);		
		isLevel1SetForOwnershipSale[_seller] = false;
		level1OwnewshipSalePrice[_seller] = 0;			
		emit Level1OwnershipTransfer(_seller, msg.sender);
		countSales++;
	}
	else
	{
		revert('Value not correct');
	}
}
}