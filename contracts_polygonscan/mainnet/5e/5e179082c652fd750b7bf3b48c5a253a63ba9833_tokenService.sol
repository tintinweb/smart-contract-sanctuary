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
  function NormalAddressBuyPricePerMNE ( address ) external view returns ( uint256 );
  function NormalAddressBuyPricePerMNESet ( address _address, uint256 _NormalAddressBuyPricePerMNE ) external;
  function NormalAddressFeeCount (  ) external view returns ( uint256 );
  function NormalAddressFeeCountSet ( uint256 _NormalAddressFeeCount ) external;
  function NormalAddressSalesCount (  ) external view returns ( uint256 );
  function NormalAddressSalesCountSet ( uint256 _NormalAddressSalesCount ) external;
  function NormalAddressSalesPriceCount (  ) external view returns ( uint256 );
  function NormalAddressSalesPriceCountSet ( uint256 _NormalAddressSalesPriceCount ) external;
  function NormalBalanceImported (  ) external view returns ( uint256 );
  function NormalBalanceImportedSet ( uint256 _NormalBalanceImported ) external;
  function NormalImportedAmountCount (  ) external view returns ( uint256 );
  function NormalImportedAmountCountSet ( uint256 _NormalImportedAmountCount ) external;
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
  function availableBalance (  ) external view returns ( uint256 );
  function availableBalanceSet ( uint256 _availableBalance ) external;
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
  function normalAddressesForSaleIndex ( address ) external view returns ( uint256 );
  function normalAddressesForSaleIndexSet ( address _address, uint256 _normalAddressesForSaleIndex ) external;
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
  function setOwnerBaseTransfers (  ) external;
  function setupRunning (  ) external view returns ( bool );
  function setupRunningSet ( bool _setupRunning ) external;
  function stakeBalances ( address ) external view returns ( uint256 );
  function stakeBalancesSet ( address _address, uint256 _stakeBalances ) external;
  function stakeBuyPrice ( address ) external view returns ( uint256 );
  function stakeBuyPriceSet ( address _address, uint256 _stakeBuyPrice ) external;
  function stakeDecimals (  ) external view returns ( uint256 );
  function stakeDecimalsSet ( address _from, uint256 _stakeDecimals ) external;
  function stakeHoldersImported (  ) external view returns ( uint256 );
  function stakeHoldersImportedSet ( uint256 _stakeHoldersImported ) external;
  function stakeHoldersListIndex ( address ) external view returns ( uint256 );
  function stakeHoldersListIndexSet ( address _address, uint256 _stakeHoldersListIndex ) external;
  function stakeMneBurnCount (  ) external view returns ( uint256 );
  function stakeMneBurnCountSet ( uint256 _stakeMneBurnCount ) external;
  function stakeMneTransferBurnCount (  ) external view returns ( uint256 );
  function stakeMneTransferBurnCountSet ( uint256 _stakeMneTransferBurnCount ) external;
  function stakesForSaleIndex ( address ) external view returns ( uint256 );
  function stakesForSaleIndexSet ( address _address, uint256 _stakesForSaleIndex ) external;
  function tokenCreated ( address, uint256 ) external view returns ( address );
  function tokenCreatedSet ( address _address, address _tokenCreated ) external;
  function tokenICOCreated ( address, uint256 ) external view returns ( address );
  function tokenICOCreatedSet ( address _address, address _tokenICOCreated ) external;
  function totalMaxAvailableAmount (  ) external view returns ( uint256 );
  function totalMaxAvailableAmountSet ( uint256 _totalMaxAvailableAmount ) external;
  function totalPaidStakeHolders (  ) external view returns ( uint256 );
  function totalPaidStakeHoldersSet ( uint256 _totalPaidStakeHolders ) external;
  function transferStakeGenesisCount (  ) external view returns ( uint256 );
  function transferStakeGenesisCountSet ( uint256 _transferStakeGenesisCount ) external;
  function transferStakeMNECount (  ) external view returns ( uint256 );
  function transferStakeMNECountSet ( uint256 _transferStakeMNECount ) external;
  function GenesisDiscount ( address ) external view returns ( bool );
}

interface genesis {
  function availableBalanceOf ( address _address ) external view returns ( uint256 Balance );  
  function balanceOf ( address _address ) external view returns ( uint256 balance );
  function isAnyGenesisAddress ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel1 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel2 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel2Or3 ( address _address ) external view returns ( bool success );
  function isGenesisAddressLevel3 ( address _address ) external view returns ( bool success );
}

interface Minereum {
  function Payment (  ) payable external;  
  function transferReserved(address _from, address _to, uint256 _value) external;
}

contract tokenService
{
	
address public ownerMain = 0x0000000000000000000000000000000000000000;	
address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
function updaterSetOwnerMain(address _address) public {if (tx.origin == updaterAddress) ownerMain = _address; else revert();}

event Level2UpgradeHistory(address indexed from);
event Level3UpgradeHistory(address indexed from);
event BridgeEvent(address indexed from, uint amount);

function setOwnerMain() public {
	if (tx.origin == updaterAddress)
	{
		ownerMain = msg.sender;
        mne = Minereum(ownerMain);
	}
	else
		revert();
}

modifier onlyOwner(){
    require(msg.sender == ownerMain);
     _;
}

publicCalls public pc;
genesis public gn;
Minereum public mne;

uint public startDate = 1631045086;
uint public blocksPerDay = 28600;
uint public prevGenesisCount;
uint public prevDestroyGenesisCount;
bool public bridgeActive = false;
uint public bridgeStartDate = 1631045086;
uint public totalBridged = 0;
uint public maxDailyBridge = 3000000000000;
mapping (uint => uint) public bridgeDailyClaim;
address public bridgeAddress = 0x0000000000000000000000000000000000000000;
bool public makeBalanceVisibleAllowed = true;
mapping (address => uint) public balanceVisibleTriggered;

	
constructor(address _publicCallsAddress, address _genesisAddress) public {
setUpdater();
pc = publicCalls(_publicCallsAddress);
pc.setOwnerTokenService();
gn = genesis(_genesisAddress);
}

function reloadGenesis(address _address) public
{
	if (msg.sender == updaterAddress)
	{
		gn = genesis(_address);		
	}
	else revert();
}

function bridgeActiveSet(bool _value, uint _maxDailyBridge, uint _bridgeStartDate) public
{
	if (msg.sender == updaterAddress)
	{
		bridgeActive = _value;
		maxDailyBridge = _maxDailyBridge;
		bridgeStartDate = _bridgeStartDate;
	}
	else revert();
}

function setBridgeAddress(address _address) public
{
	if(msg.sender == updaterAddress)
		bridgeAddress = _address;
	else
		revert();
}

function setupRunningActive(bool _value) public
{
	if (msg.sender == updaterAddress)
	{
		pc.setupRunningSet(_value);
	}
	else revert();
}

function reloadPublicCalls(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pc = publicCalls(_address); pc.setOwnerTokenService();} else revert();}

function DestroyGenesisAddressLevel1(address _address) public onlyOwner {
	if (pc.isGenesisAddressForSale(_address)) revert('Remove Your Address From Sale First');		
	uint256 _balanceToDestroy = gn.balanceOf(_address);
	pc.isGenesisAddressSet(_address, 1);	
	pc.balancesSet(_address, 0);
	pc.initialBlockCountPerAddressSet(_address, 0);
	pc.isGenesisAddressForSaleSet(_address, false);
	pc.genesisBuyPriceSet(_address, 0);		
	pc.allowAddressToDestroyGenesisSet(_address, 0x0000000000000000000000000000000000000000);
	pc.GenesisDestroyCountStakeSet(pc.GenesisDestroyCountStake() + 1);
	pc.GenesisDestroyedSet(pc.GenesisDestroyed() + 1);
	pc.GenesisDestroyAmountCountSet(pc.GenesisDestroyAmountCount() + _balanceToDestroy);	
}

function MakeBalanceVisible() public {
	if (makeBalanceVisibleAllowed == false) revert('functionality not active');
	if (gn.isAnyGenesisAddress(msg.sender) && balanceVisibleTriggered[msg.sender] == 0)
	{
		mne.transferReserved(address(mne), msg.sender, 0);
		balanceVisibleTriggered[msg.sender] = 1;
	}
	else
	{
		revert();
	}
}

function Bridge(address _sender, address _address, uint _amount) public onlyOwner {
	if (gn.isAnyGenesisAddress(_address)) revert('Address cannot be Genesis');
	if (pc.isNormalAddressForSale(_address)) revert('Address cannot be set for Sale');
	if (bridgeActive == false) revert('Bridge not active');
	if (_sender != bridgeAddress) revert('invalid caller');
	uint currentPeriod = (block.timestamp - bridgeStartDate) / 86400;
	if (bridgeDailyClaim[currentPeriod] + _amount > maxDailyBridge) revert('Bridge Daily Limit Reached');
	bridgeDailyClaim[currentPeriod] += _amount;
	totalBridged += _amount;
	pc.balancesSet(_address, pc.balances(_address) + _amount);
	emit BridgeEvent(_address, _amount);
}

function UpdateGenesisAddressCount (uint value) public
{
	if (msg.sender == pc.genesisCallerAddress())
	{
		prevGenesisCount = pc.genesisAddressCount();
		pc.genesisAddressCountSet(value);
	}
	else
	{
		revert();
	}
}

function UpdateGenesisDestroyAmountCount (uint value) public
{
	if (msg.sender == pc.genesisCallerAddress())
	{
		prevDestroyGenesisCount = pc.GenesisDestroyAmountCount();
		pc.GenesisDestroyAmountCountSet(value);
	}
	else
	{
		revert();
	}
}

function UpdateStartDate (uint value) public
{
	if (msg.sender == pc.genesisCallerAddress())
	{
		startDate = value;
	}
	else
	{
		revert();
	}
}

function UpdateBlocksPerDay (uint value) public
{
	if (msg.sender == pc.genesisCallerAddress())
	{
		blocksPerDay = value;
	}
	else
	{
		revert();
	}
}

function UpdateMakeBalanceVisibleAllowed (bool value) public
{
	if (msg.sender == pc.genesisCallerAddress())
	{
		makeBalanceVisibleAllowed = value;
	}
	else
	{
		revert();
	}
}

function circulatingSupply() public view returns (uint256)
{
    uint256 totalGenesisLevel3 = pc.level3ActivationsFromLevel1Count() + pc.level3ActivationsFromLevel2Count() + pc.level3ActivationsFromDevCount();
    uint256 daysSinceLaunch = (now - startDate) / 86400;
	return pc.NormalImportedAmountCount() + (totalGenesisLevel3 * pc.genesisRewardPerBlock() * blocksPerDay * daysSinceLaunch) - pc.mneBurned();
}

function getStakeMNEFeeBuy(address _add) public view returns (uint256 price)
{
	uint256 mneFee = pc.amountOfMNEToBuyStakes()*pc.stakeBalances(_add) * 100 / pc.stakeDecimals();
	if (mneFee < pc.amountOfMNEToBuyStakes())
		mneFee = pc.amountOfMNEToBuyStakes();
	return mneFee;
}

function getStakeGenesisFeeBuy(address _add) public view returns (uint256 price)
{
	uint256 genesisAddressFee = pc.amountOfGenesisToBuyStakes()*pc.stakeBalances(_add) * 100 / pc.stakeDecimals();
	if (genesisAddressFee < pc.amountOfGenesisToBuyStakes())
	genesisAddressFee = pc.amountOfGenesisToBuyStakes();
	return genesisAddressFee;
}

function UpgradeToLevel2FromLevel1WithDiscount() public payable {
	if (pc.GenesisDiscount(msg.sender) == false) revert();
	if (gn.isGenesisAddressLevel1(msg.sender) && !pc.isGenesisAddressForSale(msg.sender))
	{
		if (msg.value != pc.ethFeeToUpgradeToLevel2() / 2) revert('(weiValue != pc.ethFeeToUpgradeToLevel2() / 2)');
		pc.initialBlockCountPerAddressSet(msg.sender, block.number);
		pc.isGenesisAddressSet(msg.sender, 2);	
		pc.balancesSet(msg.sender, pc.genesisSupplyPerAddress());
		pc.level2ActivationsFromLevel1CountSet(pc.level2ActivationsFromLevel1Count()+1);
		emit Level2UpgradeHistory(msg.sender);
		mne.Payment.value(msg.value)();
	}
	else
	{
		revert();
	}
}

function UpgradeToLevel3FromLevel1WithDiscount() public payable {
	if (pc.GenesisDiscount(msg.sender) == false) revert();
	if (gn.isGenesisAddressLevel1(msg.sender) && !pc.isGenesisAddressForSale(msg.sender))
	{
		uint256 totalFee = (pc.ethFeeToUpgradeToLevel2() + pc.ethFeeToUpgradeToLevel3());
		if (msg.value != totalFee / 2) revert('(weiValue != totalFee / 2)');
		pc.initialBlockCountPerAddressSet(msg.sender, block.number);
		pc.isGenesisAddressSet(msg.sender, 3);	
		pc.balancesSet(msg.sender, pc.genesisSupplyPerAddress());
		pc.level3ActivationsFromLevel1CountSet(pc.level3ActivationsFromLevel1Count()+1);		
		emit Level3UpgradeHistory(msg.sender);
		mne.Payment.value(msg.value)();
	}
	else
	{
		revert();
	}
}

function UpgradeToLevel3FromLevel2WithDiscount() public payable {
	if (pc.GenesisDiscount(msg.sender) == false) revert();
	if (gn.isGenesisAddressLevel2(msg.sender) && !pc.isGenesisAddressForSale(msg.sender))
	{
		if (msg.value != pc.ethFeeToUpgradeToLevel3() / 2) revert('(weiValue != pc.ethFeeToUpgradeToLevel3() / 2)');
		pc.isGenesisAddressSet(msg.sender, 3);	
		pc.level3ActivationsFromLevel2CountSet(pc.level3ActivationsFromLevel2Count()+1);
		emit Level3UpgradeHistory(msg.sender);
		mne.Payment.value(msg.value)();
	}
	else
	{
		revert();
	}
}

function isDiscountValid(address _address) public view returns (bool result) {
	return pc.GenesisDiscount(_address);	
}
}