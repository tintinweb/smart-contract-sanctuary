/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

pragma solidity ^0.6.0;
contract publicArrays { 

address public ownerMain = 0x0000000000000000000000000000000000000000;
address public ownerGenesis = 0x0000000000000000000000000000000000000000;
address public ownerStakes = 0x0000000000000000000000000000000000000000;
address public ownerNormalAddress = 0x0000000000000000000000000000000000000000;
address public ownerGenesisBuys = 0x0000000000000000000000000000000000000000;
address public ownerStakeBuys = 0x0000000000000000000000000000000000000000;
address public ownerBaseTransfers = 0x0000000000000000000000000000000000000000;
address public external1 = 0x0000000000000000000000000000000000000000;

address[] public Level1TradeHistorySeller;
address[] public Level1TradeHistoryBuyer;
uint[] public Level1TradeHistoryAmountMNE;
uint[] public Level1TradeHistoryAmountETH;
uint[] public Level1TradeHistoryAmountETHFee;
uint[] public Level1TradeHistoryDate;

address[] public Level2TradeHistorySeller;
address[] public Level2TradeHistoryBuyer;
uint[] public Level2TradeHistoryAmountMNE;
uint[] public Level2TradeHistoryAvailableAmountMNE;
uint[] public Level2TradeHistoryAmountETH;
uint[] public Level2TradeHistoryAmountETHFee;
uint[] public Level2TradeHistoryDate;

address[] public Level3TradeHistorySeller;
address[] public Level3TradeHistoryBuyer;
uint[] public Level3TradeHistoryAmountMNE;
uint[] public Level3TradeHistoryAvailableAmountMNE;
uint[] public Level3TradeHistoryAmountETH;
uint[] public Level3TradeHistoryAmountETHFee;
uint[] public Level3TradeHistoryDate;

address[] public StakeTradeHistorySeller;
address[] public StakeTradeHistoryBuyer;
uint[] public StakeTradeHistoryStakeAmount;
uint[] public StakeTradeHistoryETHPrice;
uint[] public StakeTradeHistoryETHFee;
uint[] public StakeTradeHistoryMNEGenesisBurned;
uint[] public StakeTradeHistoryDate;

address[] public MNETradeHistorySeller;
address[] public MNETradeHistoryBuyer;
uint[] public MNETradeHistoryAmountMNE;
uint[] public MNETradeHistoryAmountETH;
uint[] public MNETradeHistoryAmountETHFee;
uint[] public MNETradeHistoryDate;

address[] public genesisAddressesForSaleLevel1;
address[] public genesisAddressesForSaleLevel2;
address[] public genesisAddressesForSaleLevel3;
address[] public normalAddressesForSale;
address[] public stakesForSale;
address[] public stakeHoldersList;

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updaterSetOwnerMain(address _address) public {if (tx.origin == updaterAddress) ownerMain = _address; else revert();}
function updaterSetOwnerGenesis(address _address) public {if (tx.origin == updaterAddress) ownerGenesis = _address; else revert();}
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

function setOwnerGenesis() public {
	if (tx.origin == updaterAddress)
		ownerGenesis = msg.sender;
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
    require(msg.sender == ownerMain || msg.sender == ownerGenesis || msg.sender == ownerStakes || msg.sender == ownerNormalAddress || msg.sender == ownerGenesisBuys || msg.sender == ownerStakeBuys || msg.sender == ownerBaseTransfers || msg.sender == external1);
     _;
}

constructor() public 
{
	setUpdater();
}

function Level1TradeHistorySellerSet(address _Level1TradeHistorySeller) public onlyOwner {Level1TradeHistorySeller.push(_Level1TradeHistorySeller);}
function Level1TradeHistoryBuyerSet(address _Level1TradeHistoryBuyer) public onlyOwner {Level1TradeHistoryBuyer.push(_Level1TradeHistoryBuyer);}
function Level1TradeHistoryAmountMNESet(uint _Level1TradeHistoryAmountMNE) public onlyOwner {Level1TradeHistoryAmountMNE.push(_Level1TradeHistoryAmountMNE);}
function Level1TradeHistoryAmountETHSet(uint _Level1TradeHistoryAmountETH) public onlyOwner {Level1TradeHistoryAmountETH.push(_Level1TradeHistoryAmountETH);}
function Level1TradeHistoryAmountETHFeeSet(uint _Level1TradeHistoryAmountETHFee) public onlyOwner {Level1TradeHistoryAmountETHFee.push(_Level1TradeHistoryAmountETHFee);}
function Level1TradeHistoryDateSet(uint _Level1TradeHistoryDate) public onlyOwner {Level1TradeHistoryDate.push(_Level1TradeHistoryDate);}
function Level2TradeHistorySellerSet(address _Level2TradeHistorySeller) public onlyOwner {Level2TradeHistorySeller.push(_Level2TradeHistorySeller);}
function Level2TradeHistoryBuyerSet(address _Level2TradeHistoryBuyer) public onlyOwner {Level2TradeHistoryBuyer.push(_Level2TradeHistoryBuyer);}
function Level2TradeHistoryAmountMNESet(uint _Level2TradeHistoryAmountMNE) public onlyOwner {Level2TradeHistoryAmountMNE.push(_Level2TradeHistoryAmountMNE);}
function Level2TradeHistoryAvailableAmountMNESet(uint _Level2TradeHistoryAvailableAmountMNE) public onlyOwner {Level2TradeHistoryAvailableAmountMNE.push(_Level2TradeHistoryAvailableAmountMNE);}
function Level2TradeHistoryAmountETHSet(uint _Level2TradeHistoryAmountETH) public onlyOwner {Level2TradeHistoryAmountETH.push(_Level2TradeHistoryAmountETH);}
function Level2TradeHistoryAmountETHFeeSet(uint _Level2TradeHistoryAmountETHFee) public onlyOwner {Level2TradeHistoryAmountETHFee.push(_Level2TradeHistoryAmountETHFee);}
function Level2TradeHistoryDateSet(uint _Level2TradeHistoryDate) public onlyOwner {Level2TradeHistoryDate.push(_Level2TradeHistoryDate);}
function Level3TradeHistorySellerSet(address _Level3TradeHistorySeller) public onlyOwner {Level3TradeHistorySeller.push(_Level3TradeHistorySeller);}
function Level3TradeHistoryBuyerSet(address _Level3TradeHistoryBuyer) public onlyOwner {Level3TradeHistoryBuyer.push(_Level3TradeHistoryBuyer);}
function Level3TradeHistoryAmountMNESet(uint _Level3TradeHistoryAmountMNE) public onlyOwner {Level3TradeHistoryAmountMNE.push(_Level3TradeHistoryAmountMNE);}
function Level3TradeHistoryAvailableAmountMNESet(uint _Level3TradeHistoryAvailableAmountMNE) public onlyOwner {Level3TradeHistoryAvailableAmountMNE.push(_Level3TradeHistoryAvailableAmountMNE);}
function Level3TradeHistoryAmountETHSet(uint _Level3TradeHistoryAmountETH) public onlyOwner {Level3TradeHistoryAmountETH.push(_Level3TradeHistoryAmountETH);}
function Level3TradeHistoryAmountETHFeeSet(uint _Level3TradeHistoryAmountETHFee) public onlyOwner {Level3TradeHistoryAmountETHFee.push(_Level3TradeHistoryAmountETHFee);}
function Level3TradeHistoryDateSet(uint _Level3TradeHistoryDate) public onlyOwner {Level3TradeHistoryDate.push(_Level3TradeHistoryDate);}
function StakeTradeHistorySellerSet(address _StakeTradeHistorySeller) public onlyOwner {StakeTradeHistorySeller.push(_StakeTradeHistorySeller);}
function StakeTradeHistoryBuyerSet(address _StakeTradeHistoryBuyer) public onlyOwner {StakeTradeHistoryBuyer.push(_StakeTradeHistoryBuyer);}
function StakeTradeHistoryStakeAmountSet(uint _StakeTradeHistoryStakeAmount) public onlyOwner {StakeTradeHistoryStakeAmount.push(_StakeTradeHistoryStakeAmount);}
function StakeTradeHistoryETHPriceSet(uint _StakeTradeHistoryETHPrice) public onlyOwner {StakeTradeHistoryETHPrice.push(_StakeTradeHistoryETHPrice);}
function StakeTradeHistoryETHFeeSet(uint _StakeTradeHistoryETHFee) public onlyOwner {StakeTradeHistoryETHFee.push(_StakeTradeHistoryETHFee);}
function StakeTradeHistoryMNEGenesisBurnedSet(uint _StakeTradeHistoryMNEGenesisBurned) public onlyOwner {StakeTradeHistoryMNEGenesisBurned.push(_StakeTradeHistoryMNEGenesisBurned);}
function StakeTradeHistoryDateSet(uint _StakeTradeHistoryDate) public onlyOwner {StakeTradeHistoryDate.push(_StakeTradeHistoryDate);}
function MNETradeHistorySellerSet(address _MNETradeHistorySeller) public onlyOwner {MNETradeHistorySeller.push(_MNETradeHistorySeller);}
function MNETradeHistoryBuyerSet(address _MNETradeHistoryBuyer) public onlyOwner {MNETradeHistoryBuyer.push(_MNETradeHistoryBuyer);}
function MNETradeHistoryAmountMNESet(uint _MNETradeHistoryAmountMNE) public onlyOwner {MNETradeHistoryAmountMNE.push(_MNETradeHistoryAmountMNE);}
function MNETradeHistoryAmountETHSet(uint _MNETradeHistoryAmountETH) public onlyOwner {MNETradeHistoryAmountETH.push(_MNETradeHistoryAmountETH);}
function MNETradeHistoryAmountETHFeeSet(uint _MNETradeHistoryAmountETHFee) public onlyOwner {MNETradeHistoryAmountETHFee.push(_MNETradeHistoryAmountETHFee);}
function MNETradeHistoryDateSet(uint _MNETradeHistoryDate) public onlyOwner {MNETradeHistoryDate.push(_MNETradeHistoryDate);}
function genesisAddressesForSaleLevel1Set(address _genesisAddressesForSaleLevel1) public onlyOwner {genesisAddressesForSaleLevel1.push(_genesisAddressesForSaleLevel1);}
function genesisAddressesForSaleLevel2Set(address _genesisAddressesForSaleLevel2) public onlyOwner {genesisAddressesForSaleLevel2.push(_genesisAddressesForSaleLevel2);}
function genesisAddressesForSaleLevel3Set(address _genesisAddressesForSaleLevel3) public onlyOwner {genesisAddressesForSaleLevel3.push(_genesisAddressesForSaleLevel3);}
function normalAddressesForSaleSet(address _normalAddressesForSale) public onlyOwner {normalAddressesForSale.push(_normalAddressesForSale);}
function stakesForSaleSet(address _stakesForSale) public onlyOwner {stakesForSale.push(_stakesForSale);}
function stakeHoldersListSet(address _stakeHoldersList) public onlyOwner {stakeHoldersList.push(_stakeHoldersList);}
function Level1TradeHistorySellerLength() public view  returns (uint256 len) { return Level1TradeHistorySeller.length; }
function Level1TradeHistoryBuyerLength() public view  returns (uint256 len) { return Level1TradeHistoryBuyer.length; }
function Level1TradeHistoryAmountMNELength() public view  returns (uint256 len) { return Level1TradeHistoryAmountMNE.length; }
function Level1TradeHistoryAmountETHLength() public view  returns (uint256 len) { return Level1TradeHistoryAmountETH.length; }
function Level1TradeHistoryAmountETHFeeLength() public view  returns (uint256 len) { return Level1TradeHistoryAmountETHFee.length; }
function Level1TradeHistoryDateLength() public view  returns (uint256 len) { return Level1TradeHistoryDate.length; }
function Level2TradeHistorySellerLength() public view  returns (uint256 len) { return Level2TradeHistorySeller.length; }
function Level2TradeHistoryBuyerLength() public view  returns (uint256 len) { return Level2TradeHistoryBuyer.length; }
function Level2TradeHistoryAmountMNELength() public view  returns (uint256 len) { return Level2TradeHistoryAmountMNE.length; }
function Level2TradeHistoryAvailableAmountMNELength() public view  returns (uint256 len) { return Level2TradeHistoryAvailableAmountMNE.length; }
function Level2TradeHistoryAmountETHLength() public view  returns (uint256 len) { return Level2TradeHistoryAmountETH.length; }
function Level2TradeHistoryAmountETHFeeLength() public view  returns (uint256 len) { return Level2TradeHistoryAmountETHFee.length; }
function Level2TradeHistoryDateLength() public view  returns (uint256 len) { return Level2TradeHistoryDate.length; }
function Level3TradeHistorySellerLength() public view  returns (uint256 len) { return Level3TradeHistorySeller.length; }
function Level3TradeHistoryBuyerLength() public view  returns (uint256 len) { return Level3TradeHistoryBuyer.length; }
function Level3TradeHistoryAmountMNELength() public view  returns (uint256 len) { return Level3TradeHistoryAmountMNE.length; }
function Level3TradeHistoryAvailableAmountMNELength() public view  returns (uint256 len) { return Level3TradeHistoryAvailableAmountMNE.length; }
function Level3TradeHistoryAmountETHLength() public view  returns (uint256 len) { return Level3TradeHistoryAmountETH.length; }
function Level3TradeHistoryAmountETHFeeLength() public view  returns (uint256 len) { return Level3TradeHistoryAmountETHFee.length; }
function Level3TradeHistoryDateLength() public view  returns (uint256 len) { return Level3TradeHistoryDate.length; }
function StakeTradeHistorySellerLength() public view  returns (uint256 len) { return StakeTradeHistorySeller.length; }
function StakeTradeHistoryBuyerLength() public view  returns (uint256 len) { return StakeTradeHistoryBuyer.length; }
function StakeTradeHistoryStakeAmountLength() public view  returns (uint256 len) { return StakeTradeHistoryStakeAmount.length; }
function StakeTradeHistoryETHPriceLength() public view  returns (uint256 len) { return StakeTradeHistoryETHPrice.length; }
function StakeTradeHistoryETHFeeLength() public view  returns (uint256 len) { return StakeTradeHistoryETHFee.length; }
function StakeTradeHistoryMNEGenesisBurnedLength() public view  returns (uint256 len) { return StakeTradeHistoryMNEGenesisBurned.length; }
function StakeTradeHistoryDateLength() public view  returns (uint256 len) { return StakeTradeHistoryDate.length; }
function MNETradeHistorySellerLength() public view  returns (uint256 len) { return MNETradeHistorySeller.length; }
function MNETradeHistoryBuyerLength() public view  returns (uint256 len) { return MNETradeHistoryBuyer.length; }
function MNETradeHistoryAmountMNELength() public view  returns (uint256 len) { return MNETradeHistoryAmountMNE.length; }
function MNETradeHistoryAmountETHLength() public view  returns (uint256 len) { return MNETradeHistoryAmountETH.length; }
function MNETradeHistoryAmountETHFeeLength() public view  returns (uint256 len) { return MNETradeHistoryAmountETHFee.length; }
function MNETradeHistoryDateLength() public view  returns (uint256 len) { return MNETradeHistoryDate.length; }
function genesisAddressesForSaleLevel1Length() public view  returns (uint256 len) { return genesisAddressesForSaleLevel1.length; }
function genesisAddressesForSaleLevel2Length() public view  returns (uint256 len) { return genesisAddressesForSaleLevel2.length; }
function genesisAddressesForSaleLevel3Length() public view  returns (uint256 len) { return genesisAddressesForSaleLevel3.length; }
function normalAddressesForSaleLength() public view  returns (uint256 len) { return normalAddressesForSale.length; }
function stakesForSaleLength() public view  returns (uint256 len) { return stakesForSale.length; }
function stakeHoldersListLength() public view  returns (uint256 len) { return stakeHoldersList.length; }
function deleteGenesisAddressesForSaleLevel1() public onlyOwner { genesisAddressesForSaleLevel1.pop();}
function deleteGenesisAddressesForSaleLevel2() public onlyOwner { genesisAddressesForSaleLevel2.pop();}
function deleteGenesisAddressesForSaleLevel3() public onlyOwner { genesisAddressesForSaleLevel3.pop();}
function deleteNormalAddressesForSale() public onlyOwner { normalAddressesForSale.pop();}
function deleteStakesForSale() public onlyOwner { stakesForSale.pop();}
function deleteStakeHoldersList() public onlyOwner { stakeHoldersList.pop();}
function genesisAddressesForSaleLevel1SetAt(uint i, address _address) public onlyOwner { genesisAddressesForSaleLevel1[i] = _address;}
function genesisAddressesForSaleLevel2SetAt(uint i, address _address) public onlyOwner { genesisAddressesForSaleLevel2[i] = _address;}
function genesisAddressesForSaleLevel3SetAt(uint i, address _address) public onlyOwner { genesisAddressesForSaleLevel3[i] = _address;}
function normalAddressesForSaleSetAt(uint i, address _address) public onlyOwner { normalAddressesForSale[i] = _address;}
function stakesForSaleSetAt(uint i, address _address) public onlyOwner { stakesForSale[i] = _address;}
function stakeHoldersListAt(uint i, address _address) public onlyOwner { stakeHoldersList[i] = _address;}
}