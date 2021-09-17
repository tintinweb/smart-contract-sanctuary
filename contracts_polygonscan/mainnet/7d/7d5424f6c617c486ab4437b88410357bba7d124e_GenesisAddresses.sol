/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

pragma solidity ^0.6.0;

interface publicCalls {
  function GenesisDestroyAmountCount (  ) external view returns ( uint256 );
  function GenesisDestroyAmountCountSet ( uint256 _GenesisDestroyAmountCount ) external;
  function GenesisDestroyCountStake (  ) external view returns ( uint256 );
  function GenesisDestroyCountStakeSet ( uint256 _GenesisDestroyCountStake ) external;
  function GenesisDestroyed (  ) external view returns ( uint256 );
  function GenesisDestroyedSet ( uint256 _GenesisDestroyed ) external;
  function allowAddressToDestroyGenesis ( address ) external view returns ( address );
  function allowAddressToDestroyGenesisSet ( address _address, address _allowAddressToDestroyGenesis ) external;
  function allowReceiveGenesisTransfers ( address ) external view returns ( bool );
  function allowReceiveGenesisTransfersSet ( address _address, bool _allowReceiveGenesisTransfers ) external;
  function allowed ( address, address ) external view returns ( uint256 );
  function allowedSet ( address _address, address _spender, uint256 _amount ) external;
  function amountOfGenesisToBuyStakes (  ) external view returns ( uint256 );
  function amountOfGenesisToBuyStakesSet ( address _from, uint256 _amountOfGenesisToBuyStakes ) external;
  function amountOfGenesisToTransferStakes (  ) external view returns ( uint256 );
  function amountOfGenesisToTransferStakesSet ( address _from, uint256 _amountOfGenesisToTransferStakes ) external;
  function amountOfMNEForToken (  ) external view returns ( uint256 );
  function amountOfMNEForTokenICO (  ) external view returns ( uint256 );
  function amountOfMNEForTokenICOSet ( address _from, uint256 _amountOfMNEForTokenICO ) external;
  function amountOfMNEForTokenSet ( address _from, uint256 _amountOfMNEForToken ) external;
  function amountOfMNEToBuyStakes (  ) external view returns ( uint256 );
  function amountOfMNEToBuyStakesSet ( address _from, uint256 _amountOfMNEToBuyStakes ) external;
  function amountOfMNEToTransferStakes (  ) external view returns ( uint256 );
  function amountOfMNEToTransferStakesSet ( address _from, uint256 _amountOfMNEToTransferStakes ) external;
  function balances ( address ) external view returns ( uint256 );
  function balancesSet ( address _address, uint256 _balances ) external;
  function buyStakeGenesisCount (  ) external view returns ( uint256 );
  function buyStakeGenesisCountSet ( uint256 _buyStakeGenesisCount ) external;
  function buyStakeMNECount (  ) external view returns ( uint256 );
  function buyStakeMNECountSet ( uint256 _buyStakeMNECount ) external;
  function ethFeeForSellerLevel1 (  ) external view returns ( uint256 );
  function ethFeeForSellerLevel1Set ( address _from, uint256 _ethFeeForSellerLevel1 ) external;
  function ethFeeForToken (  ) external view returns ( uint256 );
  function ethFeeForTokenICO (  ) external view returns ( uint256 );
  function ethFeeForTokenICOSet ( address _from, uint256 _ethFeeForTokenICO ) external;
  function ethFeeForTokenSet ( address _from, uint256 _ethFeeForToken ) external;
  function ethFeeToBuyLevel1 (  ) external view returns ( uint256 );
  function ethFeeToBuyLevel1Set ( address _from, uint256 _ethFeeToBuyLevel1 ) external;
  function ethFeeToUpgradeToLevel2 (  ) external view returns ( uint256 );
  function ethFeeToUpgradeToLevel2Set ( address _from, uint256 _ethFeeToUpgradeToLevel2 ) external;
  function ethFeeToUpgradeToLevel3 (  ) external view returns ( uint256 );
  function ethFeeToUpgradeToLevel3Set ( address _from, uint256 _ethFeeToUpgradeToLevel3 ) external;
  function ethPercentFeeGenesisExchange (  ) external view returns ( uint256 );
  function ethPercentFeeGenesisExchangeSet ( address _from, uint256 _ethPercentFeeGenesisExchange ) external;
  function ethPercentFeeNormalExchange (  ) external view returns ( uint256 );
  function ethPercentFeeNormalExchangeSet ( address _from, uint256 _ethPercentFeeNormalExchange ) external;
  function ethPercentStakeExchange (  ) external view returns ( uint256 );
  function ethPercentStakeExchangeSet ( address _from, uint256 _ethPercentStakeExchange ) external;
  function genesisAddressCount (  ) external view returns ( uint256 );
  function genesisAddressCountSet ( uint256 _genesisAddressCount ) external;
  function genesisAddressesForSaleLevel1Index ( address ) external view returns ( uint256 );
  function genesisAddressesForSaleLevel1IndexSet ( address _address, uint256 _genesisAddressesForSaleLevel1Index ) external;
  function genesisAddressesForSaleLevel2Index ( address ) external view returns ( uint256 );
  function genesisAddressesForSaleLevel2IndexSet ( address _address, uint256 _genesisAddressesForSaleLevel2Index ) external;
  function genesisAddressesForSaleLevel3Index ( address ) external view returns ( uint256 );
  function genesisAddressesForSaleLevel3IndexSet ( address _address, uint256 _genesisAddressesForSaleLevel3Index ) external;
  function genesisBuyPrice ( address ) external view returns ( uint256 );
  function genesisBuyPriceSet ( address _address, uint256 _genesisBuyPrice ) external;
  function genesisCallerAddress (  ) external view returns ( address );
  function genesisCallerAddressSet ( address _genesisCallerAddress ) external;
  function genesisInitialSupply ( address ) external view returns ( uint256 );
  function genesisInitialSupplySet ( address _address, uint256 _genesisInitialSupply ) external;
  function genesisRewardPerBlock (  ) external view returns ( uint256 );
  function genesisSalesCount (  ) external view returns ( uint256 );
  function genesisSalesCountSet ( uint256 _genesisSalesCount ) external;
  function genesisSalesPriceCount (  ) external view returns ( uint256 );
  function genesisSalesPriceCountSet ( uint256 _genesisSalesPriceCount ) external;
  function genesisSupplyPerAddress (  ) external view returns ( uint256 );
  function genesisTransfersCount (  ) external view returns ( uint256 );
  function genesisTransfersCountSet ( uint256 _genesisTransfersCount ) external;
  function initialBlockCount (  ) external view returns ( uint256 );
  function initialBlockCountPerAddress ( address ) external view returns ( uint256 );
  function initialBlockCountPerAddressSet ( address _address, uint256 _initialBlockCountPerAddress ) external;
  function initialBlockCountSet ( uint256 _initialBlockCount ) external;
  function isGenesisAddress ( address ) external view returns ( uint8 );
  function isGenesisAddressForSale ( address ) external view returns ( bool );
  function isGenesisAddressForSaleSet ( address _address, bool _isGenesisAddressForSale ) external;
  function isGenesisAddressSet ( address _address, uint8 _isGenesisAddress ) external;
  function isNormalAddressForSale ( address ) external view returns ( bool );
  function isNormalAddressForSaleSet ( address _address, bool _isNormalAddressForSale ) external;
  function level2ActivationsFromLevel1Count (  ) external view returns ( uint256 );
  function level2ActivationsFromLevel1CountSet ( uint256 _level2ActivationsFromLevel1Count ) external;
  function level3ActivationsFromDevCount (  ) external view returns ( uint256 );
  function level3ActivationsFromDevCountSet ( uint256 _level3ActivationsFromDevCount ) external;
  function level3ActivationsFromLevel1Count (  ) external view returns ( uint256 );
  function level3ActivationsFromLevel1CountSet ( uint256 _level3ActivationsFromLevel1Count ) external;
  function level3ActivationsFromLevel2Count (  ) external view returns ( uint256 );
  function level3ActivationsFromLevel2CountSet ( uint256 _level3ActivationsFromLevel2Count ) external;
  function maxBlocks (  ) external view returns ( uint256 );
  function mneBurned (  ) external view returns ( uint256 );
  function mneBurnedSet ( uint256 _mneBurned ) external;
  function overallSupply (  ) external view returns ( uint256 );
  function overallSupplySet ( uint256 _overallSupply ) external;
  function ownerGenesis (  ) external view returns ( address );
  function ownerGenesisBuys (  ) external view returns ( address );
  function ownerMain (  ) external view returns ( address );
  function ownerNormalAddress (  ) external view returns ( address );
  function ownerStakeBuys (  ) external view returns ( address );
  function ownerStakes (  ) external view returns ( address );
  function ownerTokenService (  ) external view returns ( address );
  function setOwnerGenesis (  ) external;
  function setOwnerGenesisBuys (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakeBuys (  ) external;
  function setOwnerStakes (  ) external;
  function setOwnerTokenService (  ) external;
  function setupRunning (  ) external view returns ( bool );
  function setupRunningSet ( bool _setupRunning ) external;
}

interface publicArrays {
  function Level1TradeHistoryAmountETH ( uint256 ) external view returns ( uint256 );
  function Level1TradeHistoryAmountETHFee ( uint256 ) external view returns ( uint256 );
  function Level1TradeHistoryAmountETHFeeLength (  ) external view returns ( uint256 len );
  function Level1TradeHistoryAmountETHFeeSet ( uint256 _Level1TradeHistoryAmountETHFee ) external;
  function Level1TradeHistoryAmountETHLength (  ) external view returns ( uint256 len );
  function Level1TradeHistoryAmountETHSet ( uint256 _Level1TradeHistoryAmountETH ) external;
  function Level1TradeHistoryAmountMNE ( uint256 ) external view returns ( uint256 );
  function Level1TradeHistoryAmountMNELength (  ) external view returns ( uint256 len );
  function Level1TradeHistoryAmountMNESet ( uint256 _Level1TradeHistoryAmountMNE ) external;
  function Level1TradeHistoryBuyer ( uint256 ) external view returns ( address );
  function Level1TradeHistoryBuyerLength (  ) external view returns ( uint256 len );
  function Level1TradeHistoryBuyerSet ( address _Level1TradeHistoryBuyer ) external;
  function Level1TradeHistoryDate ( uint256 ) external view returns ( uint256 );
  function Level1TradeHistoryDateLength (  ) external view returns ( uint256 len );
  function Level1TradeHistoryDateSet ( uint256 _Level1TradeHistoryDate ) external;
  function Level1TradeHistorySeller ( uint256 ) external view returns ( address );
  function Level1TradeHistorySellerLength (  ) external view returns ( uint256 len );
  function Level1TradeHistorySellerSet ( address _Level1TradeHistorySeller ) external;
  function Level2TradeHistoryAmountETH ( uint256 ) external view returns ( uint256 );
  function Level2TradeHistoryAmountETHFee ( uint256 ) external view returns ( uint256 );
  function Level2TradeHistoryAmountETHFeeLength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryAmountETHFeeSet ( uint256 _Level2TradeHistoryAmountETHFee ) external;
  function Level2TradeHistoryAmountETHLength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryAmountETHSet ( uint256 _Level2TradeHistoryAmountETH ) external;
  function Level2TradeHistoryAmountMNE ( uint256 ) external view returns ( uint256 );
  function Level2TradeHistoryAmountMNELength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryAmountMNESet ( uint256 _Level2TradeHistoryAmountMNE ) external;
  function Level2TradeHistoryAvailableAmountMNE ( uint256 ) external view returns ( uint256 );
  function Level2TradeHistoryAvailableAmountMNELength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryAvailableAmountMNESet ( uint256 _Level2TradeHistoryAvailableAmountMNE ) external;
  function Level2TradeHistoryBuyer ( uint256 ) external view returns ( address );
  function Level2TradeHistoryBuyerLength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryBuyerSet ( address _Level2TradeHistoryBuyer ) external;
  function Level2TradeHistoryDate ( uint256 ) external view returns ( uint256 );
  function Level2TradeHistoryDateLength (  ) external view returns ( uint256 len );
  function Level2TradeHistoryDateSet ( uint256 _Level2TradeHistoryDate ) external;
  function Level2TradeHistorySeller ( uint256 ) external view returns ( address );
  function Level2TradeHistorySellerLength (  ) external view returns ( uint256 len );
  function Level2TradeHistorySellerSet ( address _Level2TradeHistorySeller ) external;
  function Level3TradeHistoryAmountETH ( uint256 ) external view returns ( uint256 );
  function Level3TradeHistoryAmountETHFee ( uint256 ) external view returns ( uint256 );
  function Level3TradeHistoryAmountETHFeeLength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryAmountETHFeeSet ( uint256 _Level3TradeHistoryAmountETHFee ) external;
  function Level3TradeHistoryAmountETHLength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryAmountETHSet ( uint256 _Level3TradeHistoryAmountETH ) external;
  function Level3TradeHistoryAmountMNE ( uint256 ) external view returns ( uint256 );
  function Level3TradeHistoryAmountMNELength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryAmountMNESet ( uint256 _Level3TradeHistoryAmountMNE ) external;
  function Level3TradeHistoryAvailableAmountMNE ( uint256 ) external view returns ( uint256 );
  function Level3TradeHistoryAvailableAmountMNELength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryAvailableAmountMNESet ( uint256 _Level3TradeHistoryAvailableAmountMNE ) external;
  function Level3TradeHistoryBuyer ( uint256 ) external view returns ( address );
  function Level3TradeHistoryBuyerLength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryBuyerSet ( address _Level3TradeHistoryBuyer ) external;
  function Level3TradeHistoryDate ( uint256 ) external view returns ( uint256 );
  function Level3TradeHistoryDateLength (  ) external view returns ( uint256 len );
  function Level3TradeHistoryDateSet ( uint256 _Level3TradeHistoryDate ) external;
  function Level3TradeHistorySeller ( uint256 ) external view returns ( address );
  function Level3TradeHistorySellerLength (  ) external view returns ( uint256 len );
  function Level3TradeHistorySellerSet ( address _Level3TradeHistorySeller ) external;
  function deleteGenesisAddressesForSaleLevel1 (  ) external;
  function deleteGenesisAddressesForSaleLevel2 (  ) external;
  function deleteGenesisAddressesForSaleLevel3 (  ) external;
  function deleteNormalAddressesForSale (  ) external;
  function deleteStakeHoldersList (  ) external;
  function deleteStakesForSale (  ) external;
  function genesisAddressesForSaleLevel1 ( uint256 ) external view returns ( address );
  function genesisAddressesForSaleLevel1Length (  ) external view returns ( uint256 len );
  function genesisAddressesForSaleLevel1Set ( address _genesisAddressesForSaleLevel1 ) external;
  function genesisAddressesForSaleLevel2 ( uint256 ) external view returns ( address );
  function genesisAddressesForSaleLevel2Length (  ) external view returns ( uint256 len );
  function genesisAddressesForSaleLevel2Set ( address _genesisAddressesForSaleLevel2 ) external;
  function genesisAddressesForSaleLevel3 ( uint256 ) external view returns ( address );
  function genesisAddressesForSaleLevel3Length (  ) external view returns ( uint256 len );
  function genesisAddressesForSaleLevel3Set ( address _genesisAddressesForSaleLevel3 ) external;
  function ownerGenesis (  ) external view returns ( address );
  function ownerMain (  ) external view returns ( address );
  function ownerNormalAddress (  ) external view returns ( address );
  function ownerStakes (  ) external view returns ( address );
  function setOwnerGenesis (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakes (  ) external;
  function genesisAddressesForSaleLevel1SetAt(uint i, address _address) external;
  function genesisAddressesForSaleLevel2SetAt(uint i, address _address) external;
  function genesisAddressesForSaleLevel3SetAt(uint i, address _address) external;
}

contract GenesisAddresses
{
address public ownerMain = 0x0000000000000000000000000000000000000000;
address public ownerStakes = 0x0000000000000000000000000000000000000000;
address public ownerNormalAddress = 0x0000000000000000000000000000000000000000;
address public ownerGenesisBuys = 0x0000000000000000000000000000000000000000;
address public ownerStakeBuys = 0x0000000000000000000000000000000000000000;
address public ownerBaseTransfers = 0x0000000000000000000000000000000000000000;
address public external1 = 0x0000000000000000000000000000000000000000;

event GenesisAddressTransfer(address indexed from, address indexed to, uint256 supply);
event GenesisAddressSale(address indexed from, address indexed to, uint256 price, uint256 supply);
event GenesisBuyPriceHistory(address indexed from, uint256 price, uint8 genesisType);
event GenesisRemoveGenesisSaleHistory(address indexed from);
event AllowDestroyHistory(address indexed from, address indexed to);
event Level2UpgradeHistory(address indexed from);
event Level3UpgradeHistory(address indexed from);
event GenesisLevel1ForSaleHistory(address indexed from);
event GenesisRemoveSaleHistory(address indexed from);
event RemoveAllowDestroyHistory(address indexed from);
event ReceiveGenesisTransfersAllow(address indexed _address);
event RemoveReceiveGenesisTransfersAllow(address indexed _address);
event Burn(address indexed _owner, uint256 _value);

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updaterSetOwnerMain(address _address) public {if (tx.origin == updaterAddress) ownerMain = _address; else revert();}
function updaterSetOwnerStakes(address _address) public {if (tx.origin == updaterAddress) ownerStakes = _address; else revert();}
function updaterSetOwnerNormalAddress(address _address) public {if (tx.origin == updaterAddress) ownerNormalAddress = _address; else revert();}
function updaterSetOwnerGenesisBuys(address _address) public {if (tx.origin == updaterAddress) ownerGenesisBuys = _address; else revert();}
function updaterSetOwnerStakeBuys(address _address) public {if (tx.origin == updaterAddress) ownerStakeBuys = _address; else revert();}
function updaterSetOwnerBaseTransfers(address _address) public {if (tx.origin == updaterAddress) ownerBaseTransfers = _address; else revert();}

function setOwnerBaseTransfers() public {
	if (tx.origin == updaterAddress)
		ownerBaseTransfers = msg.sender;
	else
		revert();
}

function setOwnerMain() public {
	if (tx.origin == updaterAddress)
		ownerMain = msg.sender;
	else
		revert();
}

function setOwnerStakes() public {
	if (tx.origin == updaterAddress)
		ownerStakes = msg.sender;
	else
		revert();
}

function setOwnerNormalAddress() public {
	if (tx.origin == updaterAddress)
		ownerNormalAddress = msg.sender;
	else
		revert();
}

function setOwnerGenesisBuys() public {
	if (tx.origin == updaterAddress)
		ownerGenesisBuys = msg.sender;
	else
		revert();
}

function setOwnerStakeBuys() public {
	if (tx.origin == updaterAddress)
		ownerStakeBuys = msg.sender;
	else
		revert();
}

function setOwnerExternal1() public {
	if (tx.origin == updaterAddress)
		external1 = msg.sender;
	else
		revert();
}

modifier onlyOwner(){
    require(msg.sender == ownerMain || msg.sender == ownerStakes || msg.sender == ownerNormalAddress || msg.sender == ownerGenesisBuys || msg.sender == ownerStakeBuys || msg.sender == ownerBaseTransfers || msg.sender == external1);
     _;
}


publicCalls public pc;
publicArrays public pa;

constructor(address _publicCallsAddress, address _publicArraysAddress) public {
setUpdater();
pc = publicCalls(_publicCallsAddress);
pc.setOwnerGenesis();
pa = publicArrays(_publicArraysAddress);
pa.setOwnerGenesis();
}

function reloadPublicCalls(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pc = publicCalls(_address); pc.setOwnerGenesis();} else revert();}
function reloadPublicArrays(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pa = publicArrays(_address); pa.setOwnerGenesis();} else revert();}

function isAnyGenesisAddress(address _address) public view returns (bool success) {
	if (pc.isGenesisAddress(_address) == 0 || pc.isGenesisAddress(_address) > 1)
		return true;
	else
		return false;
}

function isGenesisAddressLevel1(address _address) public view returns (bool success) {
	if (pc.isGenesisAddress(_address) == 0)
		return true;
	else
		return false;
}

function isGenesisAddressLevel2(address _address) public view returns (bool success) {
	if (pc.isGenesisAddress(_address) == 2)
		return true;
	else
		return false;
}

function isGenesisAddressLevel3(address _address) public view returns (bool success) {
	if (pc.isGenesisAddress(_address) == 3)
		return true;
	else
		return false;
}

function isGenesisAddressLevel2Or3(address _address) public view returns (bool success) {
	if (pc.isGenesisAddress(_address) == 2 || pc.isGenesisAddress(_address) == 3)
		return true;
	else
		return false;
}

function TransferGenesis(address _from, address _to) public onlyOwner { 
	if (!isGenesisAddressLevel2Or3(_from)) revert('(!isGenesisAddressLevel2Or3(_from))');
	
	if (!(_from != _to)) revert('(!(_from != _address))');
	
	if (!pc.allowReceiveGenesisTransfers(_to)) revert('(!pc.allowReceiveGenesisTransfers(_to))');
	
	if (pc.isGenesisAddressForSale(_from)) revert('(pc.isGenesisAddressForSale(_from))');
	
	if (balanceOf(_to) > 0) revert('(balanceOf(_to) > 0)');
	
	if (isAnyGenesisAddress(_to)) revert('(isAnyGenesisAddress(_to))');	
		
	pc.balancesSet(_to, pc.balances(_from)); 
	pc.balancesSet(_from, 0);
	pc.initialBlockCountPerAddressSet(_to, pc.initialBlockCountPerAddress(_from));
	pc.initialBlockCountPerAddressSet(_from, 0);
	pc.isGenesisAddressSet(_to, pc.isGenesisAddress(_from));
	pc.isGenesisAddressSet(_from, 1);
	pc.genesisBuyPriceSet(_from, 0);
	pc.isGenesisAddressForSaleSet(_from, false);	
	pc.allowAddressToDestroyGenesisSet(_to, 0x0000000000000000000000000000000000000000);
	pc.allowAddressToDestroyGenesisSet(_from, 0x0000000000000000000000000000000000000000);
	pc.allowReceiveGenesisTransfersSet(_from, false);
	pc.allowReceiveGenesisTransfersSet(_to, false);
	pc.genesisTransfersCountSet(pc.genesisTransfersCount() + 1);
	emit GenesisAddressTransfer(_from, _to, pc.balances(_to));
}

function SetGenesisForSale(address _from, uint256 weiPrice) public onlyOwner {
	
	if (weiPrice < 10 && isGenesisAddressLevel2Or3(msg.sender)) revert('weiPrice < 10 && isGenesisAddressLevel2Or3(msg.sender)');
	
	if (!isAnyGenesisAddress(_from)) revert('(!isAnyGenesisAddress(_from))');
	
	if (pc.isGenesisAddressForSale(_from)) revert('(pc.isGenesisAddressForSale(_from))');
	
	if (balanceOf(_from) == 0) revert('(balanceOf(_from) == 0)');
	
	if (isGenesisAddressLevel2Or3(_from)) 
	{
		if (weiPrice > 0)
		{
			pc.genesisBuyPriceSet(_from, weiPrice);	
			if (isGenesisAddressLevel3(_from))
			{
				pa.genesisAddressesForSaleLevel3Set(_from);
				pc.genesisAddressesForSaleLevel3IndexSet(_from, pa.genesisAddressesForSaleLevel3Length() - 1);	
			}
			else
			{
				pa.genesisAddressesForSaleLevel2Set(_from);
				pc.genesisAddressesForSaleLevel2IndexSet(_from, pa.genesisAddressesForSaleLevel2Length() - 1);	
			}	
			emit GenesisBuyPriceHistory(_from, weiPrice, pc.isGenesisAddress(_from));			
		}
		else
			revert('Price cannot be 0');
	}	
	else if (isGenesisAddressLevel1(_from))
	{
		pa.genesisAddressesForSaleLevel1Set(_from);
		pc.genesisAddressesForSaleLevel1IndexSet(_from, pa.genesisAddressesForSaleLevel1Length() - 1);			
		emit GenesisLevel1ForSaleHistory(_from);
	}
	
	pc.isGenesisAddressForSaleSet(_from, true);

}

function deleteAddressFromGenesisSaleList(address _address) public onlyOwner {
		if (isGenesisAddressLevel1(_address))
		{
			uint lastIndex = pa.genesisAddressesForSaleLevel1Length() - 1;
			if (lastIndex > 0)
			{
				address lastIndexAddress = pa.genesisAddressesForSaleLevel1(lastIndex);
				pc.genesisAddressesForSaleLevel1IndexSet(lastIndexAddress, pc.genesisAddressesForSaleLevel1Index(_address));
				pa.genesisAddressesForSaleLevel1SetAt(pc.genesisAddressesForSaleLevel1Index(_address), lastIndexAddress);				
			}
			pc.genesisAddressesForSaleLevel1IndexSet(_address, 0);
			pa.deleteGenesisAddressesForSaleLevel1();
		}
		else if (isGenesisAddressLevel2(_address))
		{
			uint lastIndex = pa.genesisAddressesForSaleLevel2Length() - 1;
			if (lastIndex > 0)
			{
				address lastIndexAddress = pa.genesisAddressesForSaleLevel2(lastIndex);
				pc.genesisAddressesForSaleLevel2IndexSet(lastIndexAddress, pc.genesisAddressesForSaleLevel2Index(_address));
				pa.genesisAddressesForSaleLevel2SetAt(pc.genesisAddressesForSaleLevel2Index(_address),lastIndexAddress);				
			}
			pc.genesisAddressesForSaleLevel2IndexSet(_address, 0);
			pa.deleteGenesisAddressesForSaleLevel2();
		}
		else if (isGenesisAddressLevel3(_address))
		{
			uint lastIndex = pa.genesisAddressesForSaleLevel3Length() - 1;
			if (lastIndex > 0)
			{
				address lastIndexAddress = pa.genesisAddressesForSaleLevel3(lastIndex);
				pc.genesisAddressesForSaleLevel3IndexSet(lastIndexAddress, pc.genesisAddressesForSaleLevel3Index(_address));
				pa.genesisAddressesForSaleLevel3SetAt(pc.genesisAddressesForSaleLevel3Index(_address), lastIndexAddress);				
			}
			pc.genesisAddressesForSaleLevel3IndexSet(_address, 0);
			pa.deleteGenesisAddressesForSaleLevel3();
		}		
}

function AllowReceiveGenesisTransfers(address _from) public onlyOwner { 
	if (isGenesisAddressLevel1(_from))
		revert('ERROR: You must destroy your Level 1 first');
	else if (isAnyGenesisAddress(_from))
		revert('if (isAnyGenesisAddress(_from))');
	
	if (pc.allowReceiveGenesisTransfers(_from)) revert('pc.allowReceiveGenesisTransfers(_from)');
	pc.allowReceiveGenesisTransfersSet(_from, true);
	emit ReceiveGenesisTransfersAllow(_from);
}

function RemoveAllowReceiveGenesisTransfers(address _from) public onlyOwner { 
	pc.allowReceiveGenesisTransfersSet(_from,false);
	emit RemoveReceiveGenesisTransfersAllow(_from);
}

function RemoveGenesisAddressFromSale(address _from) public onlyOwner{ 
	if (!isAnyGenesisAddress(_from)) revert('(!isAnyGenesisAddress(_from))');
	if (!pc.isGenesisAddressForSale(_from)) revert('!pc.isGenesisAddressForSale(_from))');
	pc.genesisBuyPriceSet(_from, 0);
	pc.isGenesisAddressForSaleSet(_from, false);	
	deleteAddressFromGenesisSaleList(_from);	
	emit GenesisRemoveSaleHistory(_from);	
}

function AllowAddressToDestroyGenesis(address _from, address _address) public onlyOwner { 
	if (!isGenesisAddressLevel3(_from)) revert('(!isGenesisAddressLevel3(_from))');
	if (pc.isGenesisAddressForSale(_from)) revert('(pc.isGenesisAddressForSale(_from))');	
	pc.allowAddressToDestroyGenesisSet(_from, _address);
	emit AllowDestroyHistory(_from, _address);	
}

function RemoveAllowAddressToDestroyGenesis(address _from) public onlyOwner { 
	pc.allowAddressToDestroyGenesisSet(_from, 0x0000000000000000000000000000000000000000);
	emit RemoveAllowDestroyHistory(_from);			
}

function UpgradeToLevel2FromLevel1(address _address, uint256 weiValue) public onlyOwner {
	if (isGenesisAddressLevel1(_address) && !pc.isGenesisAddressForSale(_address))
	{
		if (weiValue != pc.ethFeeToUpgradeToLevel2()) revert('(weiValue != pc.ethFeeToUpgradeToLevel2())');
		pc.initialBlockCountPerAddressSet(_address, block.number);
		pc.isGenesisAddressSet(_address, 2);	
		pc.balancesSet(_address, pc.genesisSupplyPerAddress());
		pc.level2ActivationsFromLevel1CountSet(pc.level2ActivationsFromLevel1Count()+1);
		emit Level2UpgradeHistory(_address);
	}
	else
	{
		revert();
	}
}

function UpgradeToLevel3FromLevel1(address _address, uint256 weiValue) public onlyOwner {
	if (isGenesisAddressLevel1(_address) && !pc.isGenesisAddressForSale(_address))
	{
		uint256 totalFee = (pc.ethFeeToUpgradeToLevel2() + pc.ethFeeToUpgradeToLevel3());
		if (weiValue != totalFee) revert('(weiValue != totalFee)');
		pc.initialBlockCountPerAddressSet(_address, block.number);
		pc.isGenesisAddressSet(_address, 3);	
		pc.balancesSet(_address, pc.genesisSupplyPerAddress());
		pc.level3ActivationsFromLevel1CountSet(pc.level3ActivationsFromLevel1Count()+1);		
		emit Level3UpgradeHistory(_address);
	}
	else
	{
		revert();
	}
}

function UpgradeToLevel3FromLevel2(address _address, uint256 weiValue) public onlyOwner {
	if (isGenesisAddressLevel2(_address) && !pc.isGenesisAddressForSale(_address))
	{
		if (weiValue != pc.ethFeeToUpgradeToLevel3()) revert('(weiValue != pc.ethFeeToUpgradeToLevel3())');
		pc.isGenesisAddressSet(_address, 3);	
		pc.level3ActivationsFromLevel2CountSet(pc.level3ActivationsFromLevel2Count()+1);
		emit Level3UpgradeHistory(_address);
	}
	else
	{
		revert();
	}
}

function UpgradeToLevel3FromDev(address _address) public onlyOwner {
	if (pc.isGenesisAddress(_address) == 4 && !pc.isGenesisAddressForSale(_address))
	{
		pc.initialBlockCountPerAddressSet(_address, block.number);
		pc.isGenesisAddressSet(_address, 3);	
		pc.balancesSet(_address, pc.genesisSupplyPerAddress());
		pc.level3ActivationsFromDevCountSet(pc.level3ActivationsFromDevCount()+1);		
		emit Level3UpgradeHistory(_address);
	}
	else
	{
		revert();
	}
}

function availableBalanceOf(address _address) public view returns (uint256 Balance)
{
	if (isGenesisAddressLevel2Or3(_address))
	{
		uint minedBlocks = block.number - pc.initialBlockCountPerAddress(_address);
		
		if (minedBlocks >= pc.maxBlocks()) return pc.balances(_address);
				
		return pc.balances(_address) - (pc.genesisSupplyPerAddress() - (pc.genesisRewardPerBlock()*minedBlocks));
	}
	else if (isGenesisAddressLevel1(_address) || pc.isGenesisAddress(_address) == 4)
		return 0;
	else
		return pc.balances(_address);
}

function balanceOf(address _address) public view returns (uint256 balance) {
	if (isGenesisAddressLevel1(_address) || pc.isGenesisAddress(_address) == 4)
		return pc.genesisSupplyPerAddress();
	else
		return pc.balances(_address);
}

function BurnTokens(address _from, uint256 mneToBurn) public onlyOwner returns (bool success)
{
	if (pc.isGenesisAddressForSale(_from)) revert('RemoveFromSaleFirst');
	
	if (pc.isNormalAddressForSale(_from)) revert('RemoveFromSaleFirst');
	
	if (availableBalanceOf(_from) >= mneToBurn)
	{
		pc.balancesSet(_from, pc.balances(_from) - mneToBurn);
		pc.mneBurnedSet(pc.mneBurned() + mneToBurn);
		emit Burn(_from, mneToBurn);			
	}
	else
	{
		revert();
	}
	return true;
}

function BurnGenesisAddresses(address _from, address[] memory _genesisAddressesToBurn) public onlyOwner {
	uint8 i = 0;	
	while(i < _genesisAddressesToBurn.length)
	{
		if (pc.allowAddressToDestroyGenesis(_genesisAddressesToBurn[i]) != _from) revert('AllowDestroy not set');
		if (pc.isGenesisAddressForSale(_genesisAddressesToBurn[i])) revert('Must remove from sale');
		if (!isGenesisAddressLevel3(_genesisAddressesToBurn[i])) revert('not level 3');
		pc.isGenesisAddressSet(_genesisAddressesToBurn[i], 1);
		uint256 _balanceToDestroy = pc.balances(_genesisAddressesToBurn[i]);
		pc.balancesSet(_genesisAddressesToBurn[i], 0);
		pc.initialBlockCountPerAddressSet(_genesisAddressesToBurn[i], 0);
		pc.isGenesisAddressForSaleSet(_genesisAddressesToBurn[i], false);
		pc.genesisBuyPriceSet(_genesisAddressesToBurn[i], 0);		
		pc.allowAddressToDestroyGenesisSet(_genesisAddressesToBurn[i], 0x0000000000000000000000000000000000000000);
		pc.GenesisDestroyCountStakeSet(pc.GenesisDestroyCountStake() + 1);
		pc.GenesisDestroyedSet(pc.GenesisDestroyed() + 1);
		pc.GenesisDestroyAmountCountSet(pc.GenesisDestroyAmountCount() + _balanceToDestroy);
		i++;
	}
}
}