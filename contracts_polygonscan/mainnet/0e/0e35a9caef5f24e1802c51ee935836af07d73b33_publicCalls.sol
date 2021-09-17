/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

pragma solidity ^0.6.0;
contract publicCalls { 

address public ownerMain = 0x0000000000000000000000000000000000000000;
address public ownerGenesis = 0x0000000000000000000000000000000000000000;
address public ownerStakes = 0x0000000000000000000000000000000000000000;
address public ownerNormalAddress = 0x0000000000000000000000000000000000000000;
address public ownerGenesisBuys = 0x0000000000000000000000000000000000000000;
address public ownerStakeBuys = 0x0000000000000000000000000000000000000000;
address public ownerTokenService = 0x0000000000000000000000000000000000000000;
address public ownerBaseTransfers = 0x0000000000000000000000000000000000000000;
address public external1 = 0x0000000000000000000000000000000000000000;
uint256 public genesisSupplyPerAddress = 300000 * 100000000;
uint256 public constant maxBlocks = 2000000000;
uint256 public genesisRewardPerBlock = genesisSupplyPerAddress / maxBlocks;
uint256 public initialBlockCount;
address public genesisCallerAddress;
uint256 public overallSupply;
uint256 public genesisSalesCount;
uint256 public genesisSalesPriceCount;
uint256 public genesisTransfersCount;
bool public setupRunning = true;
uint256 public genesisAddressCount;
uint256 public ethFeeToUpgradeToLevel2 = 75000000000000000000;
uint256 public ethFeeToUpgradeToLevel3 = 150000000000000000000;
uint256 public ethFeeToBuyLevel1 = 150000000000000000000;
uint256 public ethFeeForSellerLevel1 = 50000000000000000000;
uint256 public ethPercentFeeGenesisExchange = 10;
uint256 public ethPercentFeeNormalExchange = 10;
uint256 public ethPercentStakeExchange = 10;
uint256 public level2ActivationsFromLevel1Count = 0;
uint256 public level3ActivationsFromLevel1Count = 0;
uint256 public level3ActivationsFromLevel2Count = 0;
uint256 public level3ActivationsFromDevCount = 0;
uint256 public amountOfGenesisToBuyStakes = 2;
uint256 public amountOfMNEToBuyStakes = 100 * 100000000;
uint256 public amountOfMNEToTransferStakes = 0;
uint256 public amountOfGenesisToTransferStakes = 0;

uint256 public buyStakeMNECount = 0;
uint256 public stakeMneBurnCount = 0;
uint256 public stakeHoldersImported = 0;
uint256 public NormalBalanceImported = 0;
uint256 public NormalImportedAmountCount = 0;
uint256 public NormalAddressSalesCount = 0;
uint256 public NormalAddressSalesPriceCount = 0;
uint256 public NormalAddressSalesMNECount = 0;
uint256 public NormalAddressFeeCount = 0;
uint256 public GenesisDestroyCountStake = 0;
uint256 public GenesisDestroyed = 0;
uint256 public GenesisDestroyAmountCount = 0;
uint256 public transferStakeGenesisCount = 0;
uint256 public buyStakeGenesisCount = 0;
uint256 public stakeMneTransferBurnCount = 0;
uint256 public transferStakeMNECount = 0;
uint256 public mneBurned = 0;
uint256 public totalPaidStakeHolders = 0;
uint256 public stakeDecimals = 1000000000000000;
uint256 public genesisDiscountCount = 0;
uint256 public fromLevel1ToNormalCount = 0;

mapping (address => uint256) public balances; 
mapping (address => uint256) public stakeBalances; 
mapping (address => uint8) public isGenesisAddress; 
mapping (address => uint256) public genesisBuyPrice;
mapping (address => uint) public genesisAddressesForSaleLevel1Index;
mapping (address => uint) public genesisAddressesForSaleLevel2Index;
mapping (address => uint) public genesisAddressesForSaleLevel3Index;
mapping (address => uint) public normalAddressesForSaleIndex;
mapping (address => uint) public stakesForSaleIndex;
mapping (address => uint) public stakeHoldersListIndex;
mapping (address => uint256) public stakeBuyPrice;
mapping (address => mapping (address => uint256)) public allowed;
mapping (address => uint256) public initialBlockCountPerAddress;
mapping (address => uint256) public genesisInitialSupply;
mapping (address => bool) public allowReceiveGenesisTransfers;
mapping (address => bool) public isGenesisAddressForSale;
mapping (address => address) public allowAddressToDestroyGenesis;
mapping (address => bool) public isNormalAddressForSale;
mapping (address => uint256) public NormalAddressBuyPricePerMNE;
mapping (address => bool) public GenesisDiscount;

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updaterSetOwnerMain(address _address) public {if (tx.origin == updaterAddress) ownerMain = _address; else revert();}
function updaterSetOwnerGenesis(address _address) public {if (tx.origin == updaterAddress) ownerGenesis = _address; else revert();}
function updaterSetOwnerStakes(address _address) public {if (tx.origin == updaterAddress) ownerStakes = _address; else revert();}
function updaterSetOwnerNormalAddress(address _address) public {if (tx.origin == updaterAddress) ownerNormalAddress = _address; else revert();}
function updaterSetOwnerGenesisBuys(address _address) public {if (tx.origin == updaterAddress) ownerGenesisBuys = _address; else revert();}
function updaterSetOwnerStakeBuys(address _address) public {if (tx.origin == updaterAddress) ownerStakeBuys = _address; else revert();}
function updaterSetOwnerTokenService(address _address) public {if (tx.origin == updaterAddress) ownerTokenService = _address; else revert();}
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

function setOwnerTokenService() public {
	if (tx.origin == updaterAddress)
		ownerTokenService = msg.sender;
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
    require(msg.sender == ownerMain || msg.sender == ownerGenesis || msg.sender == ownerStakes || msg.sender == ownerNormalAddress || msg.sender == ownerGenesisBuys || msg.sender == ownerStakeBuys || msg.sender == ownerTokenService || msg.sender == ownerBaseTransfers || msg.sender == external1);
     _;
}

constructor() public
{
	setUpdater();
}

function setGenesisDiscountArrayDirect(address[] memory _addressList, bool active) public {
	if (setupRunning && msg.sender == genesisCallerAddress)
	{
		uint i = 0;
		while (i < _addressList.length)
		{
			GenesisDiscount[_addressList[i]] = active;
			
			if (active)
				genesisDiscountCount++;
			else
				genesisDiscountCount--;
			
			i++;
		}		
	}
	else
	{
		revert();
	}
}

function setGenesisAddressArrayDirect(address[] memory _addressList) public {
	if (setupRunning && msg.sender == genesisCallerAddress)
	{
		uint i = 0;
		while (i < _addressList.length)
		{
			isGenesisAddress[_addressList[i]] = 0;
			genesisAddressCount++;			
			i++;
		}
	}
	else
	{
		revert();
	}
}

function setGenesisAddressDevArrayDirect(address[] memory _addressList) public {
	if (setupRunning && msg.sender == genesisCallerAddress)
	{
		uint i = 0;
		while (i < _addressList.length)
		{
			isGenesisAddress[_addressList[i]] = 4;
			genesisAddressCount++;
			i++;
		}
	}
	else
	{
		revert();
	}
}

function setBalanceNormalAddressDirect(address _address, uint256 balance) public {
	if (setupRunning && msg.sender == genesisCallerAddress)
	{
		if (isGenesisAddress[_address] == 0 || isGenesisAddress[_address] > 1)
		{
			isGenesisAddress[_address] = 1;
			genesisAddressCount--;
		}
		
		balances[_address] = balance;
		NormalBalanceImported++;
		NormalImportedAmountCount += balance;
	}
	else
	{
		revert();
	}
}

function setGenesisCallerAddressDirect(address _address) public returns (bool success)
{
	if (msg.sender == updaterAddress)
		genesisCallerAddress = _address;
	else
		revert();
	
	return true;
}

function initialBlockCountSet(uint256 _initialBlockCount) public onlyOwner {initialBlockCount = _initialBlockCount;}
function genesisCallerAddressSet(address _genesisCallerAddress) public onlyOwner {genesisCallerAddress = _genesisCallerAddress;}
function overallSupplySet(uint256 _overallSupply) public onlyOwner {overallSupply = _overallSupply;}
function genesisSalesCountSet(uint256 _genesisSalesCount) public onlyOwner {genesisSalesCount = _genesisSalesCount;}
function genesisSalesPriceCountSet(uint256 _genesisSalesPriceCount) public onlyOwner {genesisSalesPriceCount = _genesisSalesPriceCount;}
function genesisTransfersCountSet(uint256 _genesisTransfersCount) public onlyOwner {genesisTransfersCount = _genesisTransfersCount;}
function setupRunningSet(bool _setupRunning) public onlyOwner {setupRunning = _setupRunning;}
function genesisAddressCountSet(uint256 _genesisAddressCount) public onlyOwner {genesisAddressCount = _genesisAddressCount;}

function ethFeeToUpgradeToLevel2Set(address _from, uint256 _ethFeeToUpgradeToLevel2) public onlyOwner {if (_from == genesisCallerAddress) ethFeeToUpgradeToLevel2 = _ethFeeToUpgradeToLevel2; else revert();}
function ethFeeToUpgradeToLevel3Set(address _from, uint256 _ethFeeToUpgradeToLevel3) public onlyOwner {if (_from == genesisCallerAddress)ethFeeToUpgradeToLevel3 = _ethFeeToUpgradeToLevel3; else revert();}
function ethFeeToBuyLevel1Set(address _from, uint256 _ethFeeToBuyLevel1) public onlyOwner {if (_from == genesisCallerAddress) ethFeeToBuyLevel1 = _ethFeeToBuyLevel1; else revert();}
function ethFeeForSellerLevel1Set(address _from, uint256 _ethFeeForSellerLevel1) public onlyOwner {if (_from == genesisCallerAddress) ethFeeForSellerLevel1 = _ethFeeForSellerLevel1; else revert();}
function ethPercentFeeGenesisExchangeSet(address _from, uint256 _ethPercentFeeGenesisExchange) public onlyOwner {if (_from == genesisCallerAddress) ethPercentFeeGenesisExchange = _ethPercentFeeGenesisExchange; else revert();}
function ethPercentFeeNormalExchangeSet(address _from, uint256 _ethPercentFeeNormalExchange) public onlyOwner {if (_from == genesisCallerAddress) ethPercentFeeNormalExchange = _ethPercentFeeNormalExchange; else revert();}
function ethPercentStakeExchangeSet(address _from, uint256 _ethPercentStakeExchange) public onlyOwner {if (_from == genesisCallerAddress) ethPercentStakeExchange = _ethPercentStakeExchange; else revert();}
function amountOfGenesisToBuyStakesSet(address _from, uint256 _amountOfGenesisToBuyStakes) public onlyOwner {if (_from == genesisCallerAddress) amountOfGenesisToBuyStakes = _amountOfGenesisToBuyStakes; else revert();}
function amountOfMNEToBuyStakesSet(address _from, uint256 _amountOfMNEToBuyStakes) public onlyOwner {if (_from == genesisCallerAddress) amountOfMNEToBuyStakes = _amountOfMNEToBuyStakes; else revert();}
function amountOfMNEToTransferStakesSet(address _from, uint256 _amountOfMNEToTransferStakes) public onlyOwner {if (_from == genesisCallerAddress) amountOfMNEToTransferStakes = _amountOfMNEToTransferStakes; else revert();}
function amountOfGenesisToTransferStakesSet(address _from, uint256 _amountOfGenesisToTransferStakes) public onlyOwner {if (_from == genesisCallerAddress) amountOfGenesisToTransferStakes = _amountOfGenesisToTransferStakes; else revert();}
function stakeDecimalsSet(address _from, uint256 _stakeDecimals) public onlyOwner {if (_from == genesisCallerAddress) {stakeDecimals = _stakeDecimals;} else revert();}

function level2ActivationsFromLevel1CountSet(uint256 _level2ActivationsFromLevel1Count) public onlyOwner {level2ActivationsFromLevel1Count = _level2ActivationsFromLevel1Count;}
function level3ActivationsFromLevel1CountSet(uint256 _level3ActivationsFromLevel1Count) public onlyOwner {level3ActivationsFromLevel1Count = _level3ActivationsFromLevel1Count;}
function level3ActivationsFromLevel2CountSet(uint256 _level3ActivationsFromLevel2Count) public onlyOwner {level3ActivationsFromLevel2Count = _level3ActivationsFromLevel2Count;}
function level3ActivationsFromDevCountSet(uint256 _level3ActivationsFromDevCount) public onlyOwner {level3ActivationsFromDevCount = _level3ActivationsFromDevCount;}
function buyStakeMNECountSet(uint256 _buyStakeMNECount) public onlyOwner {buyStakeMNECount = _buyStakeMNECount;}
function stakeMneBurnCountSet(uint256 _stakeMneBurnCount) public onlyOwner {stakeMneBurnCount = _stakeMneBurnCount;}
function stakeHoldersImportedSet(uint256 _stakeHoldersImported) public onlyOwner {stakeHoldersImported = _stakeHoldersImported;}
function NormalBalanceImportedSet(uint256 _NormalBalanceImported) public onlyOwner {NormalBalanceImported = _NormalBalanceImported;}
function NormalImportedAmountCountSet(uint256 _NormalImportedAmountCount) public onlyOwner {NormalImportedAmountCount = _NormalImportedAmountCount;}
function NormalAddressSalesCountSet(uint256 _NormalAddressSalesCount) public onlyOwner {NormalAddressSalesCount = _NormalAddressSalesCount;}
function NormalAddressSalesPriceCountSet(uint256 _NormalAddressSalesPriceCount) public onlyOwner {NormalAddressSalesPriceCount = _NormalAddressSalesPriceCount;}
function NormalAddressSalesMNECountSet(uint256 _NormalAddressSalesMNECount) public onlyOwner {NormalAddressSalesMNECount = _NormalAddressSalesMNECount;}
function NormalAddressFeeCountSet(uint256 _NormalAddressFeeCount) public onlyOwner {NormalAddressFeeCount = _NormalAddressFeeCount;}
function GenesisDestroyCountStakeSet(uint256 _GenesisDestroyCountStake) public onlyOwner {GenesisDestroyCountStake = _GenesisDestroyCountStake;}
function GenesisDestroyedSet(uint256 _GenesisDestroyed) public onlyOwner {GenesisDestroyed = _GenesisDestroyed;}
function GenesisDestroyAmountCountSet(uint256 _GenesisDestroyAmountCount) public onlyOwner {GenesisDestroyAmountCount = _GenesisDestroyAmountCount;}
function transferStakeGenesisCountSet(uint256 _transferStakeGenesisCount) public onlyOwner {transferStakeGenesisCount = _transferStakeGenesisCount;}
function buyStakeGenesisCountSet(uint256 _buyStakeGenesisCount) public onlyOwner {buyStakeGenesisCount = _buyStakeGenesisCount;}
function stakeMneTransferBurnCountSet(uint256 _stakeMneTransferBurnCount) public onlyOwner {stakeMneTransferBurnCount = _stakeMneTransferBurnCount;}
function transferStakeMNECountSet(uint256 _transferStakeMNECount) public onlyOwner {transferStakeMNECount = _transferStakeMNECount;}
function mneBurnedSet(uint256 _mneBurned) public onlyOwner {mneBurned = _mneBurned;}
function totalPaidStakeHoldersSet(uint256 _totalPaidStakeHolders) public onlyOwner {totalPaidStakeHolders = _totalPaidStakeHolders;}
function balancesSet(address _address,uint256 _balances) public onlyOwner {balances[_address] = _balances;}
function stakeBalancesSet(address _address,uint256 _stakeBalances) public onlyOwner {stakeBalances[_address] = _stakeBalances;}
function isGenesisAddressSet(address _address,uint8 _isGenesisAddress) public onlyOwner {isGenesisAddress[_address] = _isGenesisAddress;}
function genesisBuyPriceSet(address _address,uint256 _genesisBuyPrice) public onlyOwner {genesisBuyPrice[_address] = _genesisBuyPrice;}
function genesisAddressesForSaleLevel1IndexSet(address _address,uint _genesisAddressesForSaleLevel1Index) public onlyOwner {genesisAddressesForSaleLevel1Index[_address] = _genesisAddressesForSaleLevel1Index;}
function genesisAddressesForSaleLevel2IndexSet(address _address,uint _genesisAddressesForSaleLevel2Index) public onlyOwner {genesisAddressesForSaleLevel2Index[_address] = _genesisAddressesForSaleLevel2Index;}
function genesisAddressesForSaleLevel3IndexSet(address _address,uint _genesisAddressesForSaleLevel3Index) public onlyOwner {genesisAddressesForSaleLevel3Index[_address] = _genesisAddressesForSaleLevel3Index;}
function normalAddressesForSaleIndexSet(address _address,uint _normalAddressesForSaleIndex) public onlyOwner {normalAddressesForSaleIndex[_address] = _normalAddressesForSaleIndex;}
function stakesForSaleIndexSet(address _address,uint _stakesForSaleIndex) public onlyOwner {stakesForSaleIndex[_address] = _stakesForSaleIndex;}
function stakeHoldersListIndexSet(address _address,uint _stakeHoldersListIndex) public onlyOwner {stakeHoldersListIndex[_address] = _stakeHoldersListIndex;}
function stakeBuyPriceSet(address _address,uint256 _stakeBuyPrice) public onlyOwner {stakeBuyPrice[_address] = _stakeBuyPrice;}
function initialBlockCountPerAddressSet(address _address,uint256 _initialBlockCountPerAddress) public onlyOwner {initialBlockCountPerAddress[_address] = _initialBlockCountPerAddress;}
function genesisInitialSupplySet(address _address,uint256 _genesisInitialSupply) public onlyOwner {genesisInitialSupply[_address] = _genesisInitialSupply;}
function allowReceiveGenesisTransfersSet(address _address,bool _allowReceiveGenesisTransfers) public onlyOwner {allowReceiveGenesisTransfers[_address] = _allowReceiveGenesisTransfers;}
function isGenesisAddressForSaleSet(address _address,bool _isGenesisAddressForSale) public onlyOwner {isGenesisAddressForSale[_address] = _isGenesisAddressForSale;}
function allowAddressToDestroyGenesisSet(address _address,address _allowAddressToDestroyGenesis) public onlyOwner {allowAddressToDestroyGenesis[_address] = _allowAddressToDestroyGenesis;}
function isNormalAddressForSaleSet(address _address,bool _isNormalAddressForSale) public onlyOwner {isNormalAddressForSale[_address] = _isNormalAddressForSale;}
function NormalAddressBuyPricePerMNESet(address _address,uint256 _NormalAddressBuyPricePerMNE) public onlyOwner {NormalAddressBuyPricePerMNE[_address] = _NormalAddressBuyPricePerMNE;}
function allowedSet(address _address,address _spender, uint256 _amount) public onlyOwner { allowed[_address][_spender] = _amount; }
function fromLevel1ToNormalCountSet(uint256 _fromLevel1ToNormalCount) public onlyOwner {fromLevel1ToNormalCount = _fromLevel1ToNormalCount;}
}