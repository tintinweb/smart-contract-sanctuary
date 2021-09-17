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
  function tokenCreatedGet ( address ) external view returns ( address[] memory );
  function tokenCreatedSet ( address _address, address _tokenCreated ) external;
  function tokenICOCreated ( address, uint256 ) external view returns ( address );
  function tokenICOCreatedGet ( address ) external view returns ( address[] memory );
  function tokenICOCreatedSet ( address _address, address _tokenICOCreated ) external;
  function totalMaxAvailableAmount (  ) external view returns ( uint256 );
  function totalMaxAvailableAmountSet ( uint256 _totalMaxAvailableAmount ) external;
  function totalPaidStakeHolders (  ) external view returns ( uint256 );
  function totalPaidStakeHoldersSet ( uint256 _totalPaidStakeHolders ) external;
  function transferStakeGenesisCount (  ) external view returns ( uint256 );
  function transferStakeGenesisCountSet ( uint256 _transferStakeGenesisCount ) external;
  function transferStakeMNECount (  ) external view returns ( uint256 );
  function transferStakeMNECountSet ( uint256 _transferStakeMNECount ) external;
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
  function MNETradeHistoryAmountETH ( uint256 ) external view returns ( uint256 );
  function MNETradeHistoryAmountETHFee ( uint256 ) external view returns ( uint256 );
  function MNETradeHistoryAmountETHFeeLength (  ) external view returns ( uint256 len );
  function MNETradeHistoryAmountETHFeeSet ( uint256 _MNETradeHistoryAmountETHFee ) external;
  function MNETradeHistoryAmountETHLength (  ) external view returns ( uint256 len );
  function MNETradeHistoryAmountETHSet ( uint256 _MNETradeHistoryAmountETH ) external;
  function MNETradeHistoryAmountMNE ( uint256 ) external view returns ( uint256 );
  function MNETradeHistoryAmountMNELength (  ) external view returns ( uint256 len );
  function MNETradeHistoryAmountMNESet ( uint256 _MNETradeHistoryAmountMNE ) external;
  function MNETradeHistoryBuyer ( uint256 ) external view returns ( address );
  function MNETradeHistoryBuyerLength (  ) external view returns ( uint256 len );
  function MNETradeHistoryBuyerSet ( address _MNETradeHistoryBuyer ) external;
  function MNETradeHistoryDate ( uint256 ) external view returns ( uint256 );
  function MNETradeHistoryDateLength (  ) external view returns ( uint256 len );
  function MNETradeHistoryDateSet ( uint256 _MNETradeHistoryDate ) external;
  function MNETradeHistorySeller ( uint256 ) external view returns ( address );
  function MNETradeHistorySellerLength (  ) external view returns ( uint256 len );
  function MNETradeHistorySellerSet ( address _MNETradeHistorySeller ) external;
  function StakeTradeHistoryBuyer ( uint256 ) external view returns ( address );
  function StakeTradeHistoryBuyerLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryBuyerSet ( address _StakeTradeHistoryBuyer ) external;
  function StakeTradeHistoryDate ( uint256 ) external view returns ( uint256 );
  function StakeTradeHistoryDateLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryDateSet ( uint256 _StakeTradeHistoryDate ) external;
  function StakeTradeHistoryETHFee ( uint256 ) external view returns ( uint256 );
  function StakeTradeHistoryETHFeeLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryETHFeeSet ( uint256 _StakeTradeHistoryETHFee ) external;
  function StakeTradeHistoryETHPrice ( uint256 ) external view returns ( uint256 );
  function StakeTradeHistoryETHPriceLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryETHPriceSet ( uint256 _StakeTradeHistoryETHPrice ) external;
  function StakeTradeHistoryMNEGenesisBurned ( uint256 ) external view returns ( uint256 );
  function StakeTradeHistoryMNEGenesisBurnedLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryMNEGenesisBurnedSet ( uint256 _StakeTradeHistoryMNEGenesisBurned ) external;
  function StakeTradeHistorySeller ( uint256 ) external view returns ( address );
  function StakeTradeHistorySellerLength (  ) external view returns ( uint256 len );
  function StakeTradeHistorySellerSet ( address _StakeTradeHistorySeller ) external;
  function StakeTradeHistoryStakeAmount ( uint256 ) external view returns ( uint256 );
  function StakeTradeHistoryStakeAmountLength (  ) external view returns ( uint256 len );
  function StakeTradeHistoryStakeAmountSet ( uint256 _StakeTradeHistoryStakeAmount ) external;
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
  function normalAddressesForSale ( uint256 ) external view returns ( address );
  function normalAddressesForSaleLength (  ) external view returns ( uint256 len );
  function normalAddressesForSaleSet ( address _normalAddressesForSale ) external;
  function ownerGenesis (  ) external view returns ( address );
  function ownerMain (  ) external view returns ( address );
  function ownerNormalAddress (  ) external view returns ( address );
  function ownerStakes (  ) external view returns ( address );
  function setOwnerGenesis (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakes (  ) external;
  function stakeHoldersList ( uint256 ) external view returns ( address );
  function stakeHoldersListLength (  ) external view returns ( uint256 len );
  function stakeHoldersListSet ( address _stakeHoldersList ) external;
  function stakesForSale ( uint256 ) external view returns ( address );
  function stakesForSaleLength (  ) external view returns ( uint256 len );
  function stakesForSaleSet ( address _stakesForSale ) external;
  function genesisAddressesForSaleLevel1SetAt(uint i, address _address) external;
  function genesisAddressesForSaleLevel2SetAt(uint i, address _address) external;
  function genesisAddressesForSaleLevel3SetAt(uint i, address _address) external;
  function normalAddressesForSaleSetAt(uint i, address _address) external;
  function stakesForSaleSetAt(uint i, address _address) external;
  function stakeHoldersListAt(uint i, address _address) external;
}

interface genesis {
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
  function stopSetup ( address _from ) external returns ( bool success );
}



contract Lists {

publicCalls public pc;
publicArrays public pa;
genesis public gn;

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}

constructor(address _publicCallsAddress, address _publicArraysAddress, address _genesisAddress) public {
setUpdater();
pc = publicCalls(_publicCallsAddress);
pa = publicArrays(_publicArraysAddress);
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
function reloadPublicCalls(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pc = publicCalls(_address);} else revert();}
function reloadPublicArrays(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pa = publicArrays(_address);} else revert();}


	
function ListNormalAddressesForSale(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _normalAddress, uint[] memory _balance, uint[] memory _ETHPricePerMNE, uint[] memory _totalETHPrice){
if (_recordsLength > pa.normalAddressesForSaleLength())
       _recordsLength = pa.normalAddressesForSaleLength();
	
_normalAddress = new address[](_recordsLength);
_balance = new uint[](_recordsLength);
_ETHPricePerMNE = new uint[](_recordsLength);	
_totalETHPrice = new uint[](_recordsLength);

uint count = 0;
for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.normalAddressesForSaleLength(); i++){
    address _add = pa.normalAddressesForSale(i);
	_normalAddress[count] = _add;
	_balance[count] = gn.balanceOf(_add);
	_ETHPricePerMNE[count] = pc.NormalAddressBuyPricePerMNE(_add) + (pc.NormalAddressBuyPricePerMNE(_add) * pc.ethPercentFeeNormalExchange() / 100);
	_totalETHPrice[count] = _ETHPricePerMNE[count] * _balance[count] / 100000000;
    count++;
}    
}


function ListGenesisForSaleLevel1(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _genAddress, uint[] memory _balance, uint[] memory _ETHPrice){
	if (_recordsLength > pa.genesisAddressesForSaleLevel1Length())
       _recordsLength = pa.genesisAddressesForSaleLevel1Length();
    _genAddress = new address[](_recordsLength);
	_balance = new uint[](_recordsLength);
	_ETHPrice = new uint[](_recordsLength);	

	uint256 feesToPayToContract = pc.ethFeeToBuyLevel1();
	uint256 feesToPayToSeller = pc.ethFeeForSellerLevel1();
	uint256 feesGeneralToPayToContract = (feesToPayToContract + feesToPayToSeller) * pc.ethPercentFeeGenesisExchange() / 100;
		
	uint256 totalToSend = feesToPayToContract + feesToPayToSeller + feesGeneralToPayToContract;

    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.genesisAddressesForSaleLevel1Length(); i++){
        address _add = pa.genesisAddressesForSaleLevel1(i);
		_genAddress[count] = _add;
		_balance[count] = gn.balanceOf(_add);   
		_ETHPrice[count] = totalToSend; 		
        count++;
    }    
}

function ListGenesisForSaleLevel2(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _genAddress, uint[] memory _balance, uint[] memory _availableBalance, uint[] memory _ETHPrice){
	if (_recordsLength > pa.genesisAddressesForSaleLevel2Length())
       _recordsLength = pa.genesisAddressesForSaleLevel2Length();
    _genAddress = new address[](_recordsLength);
	_balance = new uint[](_recordsLength);
	_availableBalance = new uint[](_recordsLength);
	_ETHPrice = new uint[](_recordsLength);	
	
	uint256 feesToPayToContract = pc.ethFeeToUpgradeToLevel3();
    
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.genesisAddressesForSaleLevel2Length(); i++){
        address _add = pa.genesisAddressesForSaleLevel2(i);
		_genAddress[count] = _add;
		_balance[count] = gn.balanceOf(_add);   
		_availableBalance[count] = gn.availableBalanceOf(_add);
		
		uint256 feesToPayToSeller = pc.genesisBuyPrice(_add);
        uint256 feesGeneralToPayToContract = (feesToPayToContract + feesToPayToSeller) * pc.ethPercentFeeGenesisExchange() / 100;
	    uint256 totalToSend = feesToPayToContract + feesToPayToSeller + feesGeneralToPayToContract;
		
		_ETHPrice[count] = totalToSend; 		
        count++;
    }
}

function ListGenesisForSaleLevel3(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _genAddress, uint[] memory _balance, uint[] memory _availableBalance, uint[] memory _ETHPrice){
	if (_recordsLength > pa.genesisAddressesForSaleLevel3Length())
       _recordsLength = pa.genesisAddressesForSaleLevel3Length();
    _genAddress = new address[](_recordsLength);
	_balance = new uint[](_recordsLength);
	_availableBalance = new uint[](_recordsLength);
	_ETHPrice = new uint[](_recordsLength);	

	uint256 feesToPayToContract = 0;
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.genesisAddressesForSaleLevel3Length(); i++){
        address _add = pa.genesisAddressesForSaleLevel3(i);
		_genAddress[count] = _add;
		_balance[count] = gn.balanceOf(_add);   
		_availableBalance[count] = gn.availableBalanceOf(_add);
		
		uint256 feesToPayToSeller = pc.genesisBuyPrice(_add);
	    uint256 feesGeneralToPayToContract = (feesToPayToContract + feesToPayToSeller) * pc.ethPercentFeeGenesisExchange() / 100;
	    uint256 totalToSend = feesToPayToContract + feesToPayToSeller + feesGeneralToPayToContract;
		
		_ETHPrice[count] = totalToSend;
        count++;
    }    
}



function ListStakesForSale(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _stakeholders, uint[] memory _balance, uint[] memory _ETHPrice, uint[] memory _MNEFee, uint[] memory _GenesisAddressFee){
	if (_recordsLength > pa.stakesForSaleLength())
       _recordsLength = pa.stakesForSaleLength();
    _stakeholders = new address[](_recordsLength);
	_balance = new uint[](_recordsLength);
	_ETHPrice = new uint[](_recordsLength);
	_MNEFee = new uint[](_recordsLength);
	_GenesisAddressFee = new uint[](_recordsLength);

	uint256 feesToPayToContract = 0;
	
    
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.stakesForSaleLength(); i++){
        address _add = pa.stakesForSale(i);
		_stakeholders[count] = _add;
		_balance[count] = pc.stakeBalances(_add);   
		
		uint256 feesToPayToSeller = pc.stakeBuyPrice(_add);
	    uint256 feesGeneralToPayToContract = (feesToPayToContract + feesToPayToSeller) * pc.ethPercentStakeExchange() / 100;
        uint256 totalToSend = feesToPayToContract + feesToPayToSeller + feesGeneralToPayToContract;
		
		uint256 mneFee = pc.amountOfMNEToBuyStakes()*pc.stakeBalances(_add) * 100 / pc.stakeDecimals();
		if (mneFee < pc.amountOfMNEToBuyStakes())
			mneFee = pc.amountOfMNEToBuyStakes();
		
		uint256 genesisAddressFee = pc.amountOfGenesisToBuyStakes()*pc.stakeBalances(_add) * 100 / pc.stakeDecimals();
		if (genesisAddressFee < pc.amountOfGenesisToBuyStakes())
			genesisAddressFee = pc.amountOfGenesisToBuyStakes();
		
		_ETHPrice[count] = totalToSend;
		_MNEFee[count] = mneFee;
		_GenesisAddressFee[count] = genesisAddressFee;
        count++;
    }    
}

function ListStakeHolders(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _stakeHolders, uint[] memory _stakeBalance){
	if (_recordsLength > pa.stakeHoldersListLength())
       _recordsLength = pa.stakeHoldersListLength();
    _stakeHolders = new address[](_recordsLength);
	_stakeBalance = new uint[](_recordsLength);
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.stakeHoldersListLength(); i++){
        address _add = pa.stakeHoldersList(i);
		_stakeHolders[count] = _add;
		_stakeBalance[count] = pc.stakeBalances(_add);        
        count++;
    }    
}

function ListHistoryNormalAddressSale(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _seller,address[] memory _buyer,uint[] memory _amountMNE,uint[] memory _amountETH,uint[] memory _amountETHFee, uint[] memory _date){
	if (_recordsLength > pa.MNETradeHistorySellerLength())
       _recordsLength = pa.MNETradeHistorySellerLength();
	_seller = new address[](_recordsLength);
	_buyer = new address[](_recordsLength);
	_amountMNE = new uint[](_recordsLength);
	_amountETH = new uint[](_recordsLength);
	_amountETHFee = new uint[](_recordsLength);
	_date = new uint[](_recordsLength);
	
	uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.MNETradeHistorySellerLength(); i++){
        _seller[count] = pa.MNETradeHistorySeller(i);
		_buyer[count] = pa.MNETradeHistoryBuyer(i);
		_amountMNE[count] = pa.MNETradeHistoryAmountMNE(i);
		_amountETH[count] = pa.MNETradeHistoryAmountETH(i);
		_amountETHFee[count] = pa.MNETradeHistoryAmountETHFee(i);
		_date[count] = pa.MNETradeHistoryDate(i);
        count++;
    }    
}


function ListHistoryStakeSale(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _seller, address[] memory _buyer, uint[] memory _stakeAmount, uint[] memory _ETHPrice, uint[] memory _ETHFee, uint[] memory _MNEGenesisBurned, uint[] memory _date){
	if (_recordsLength > pa.StakeTradeHistorySellerLength())
       _recordsLength = pa.StakeTradeHistorySellerLength();
	_seller = new address[](_recordsLength);
	_buyer = new address[](_recordsLength);
	_stakeAmount = new uint[](_recordsLength);
	_ETHPrice = new uint[](_recordsLength);
	_ETHFee = new uint[](_recordsLength);
	_MNEGenesisBurned = new uint[](_recordsLength);
	_date = new uint[](_recordsLength);

    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.StakeTradeHistorySellerLength(); i++){
        _seller[count] = pa.StakeTradeHistorySeller(i);
		_buyer[count] = pa.StakeTradeHistoryBuyer(i);
		_stakeAmount[count] = pa.StakeTradeHistoryStakeAmount(i);
		_ETHPrice[count] = pa.StakeTradeHistoryETHPrice(i);
		_ETHFee[count] = pa.StakeTradeHistoryETHFee(i);
		_MNEGenesisBurned[count] = pa.StakeTradeHistoryMNEGenesisBurned(i);
		_date[count] = pa.StakeTradeHistoryDate(i);
        count++;
    }    
}


function ListHistoryGenesisSaleLevel1(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _seller, address[] memory _buyer, uint[] memory _amountMNE, uint[] memory _amountETH, uint[] memory _amountETHFee, uint[] memory _date){
	if (_recordsLength > pa.Level1TradeHistorySellerLength())
       _recordsLength = pa.Level1TradeHistorySellerLength();
    _seller = new address[](_recordsLength);
	_buyer = new address[](_recordsLength);
	_amountMNE = new uint[](_recordsLength);
	_amountETH = new uint[](_recordsLength);
	_amountETHFee = new uint[](_recordsLength);
	_date = new uint[](_recordsLength);
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.Level1TradeHistorySellerLength(); i++){
        _seller[count] = pa.Level1TradeHistorySeller(i);
		_buyer[count] = pa.Level1TradeHistoryBuyer(i);
		_amountMNE[count] = pa.Level1TradeHistoryAmountMNE(i);
		_amountETH[count] = pa.Level1TradeHistoryAmountETH(i);
		_amountETHFee[count] = pa.Level1TradeHistoryAmountETHFee(i);
		_date[count] = pa.Level1TradeHistoryDate(i);
        count++;
    }    
}

function ListHistoryGenesisSaleLevel2(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _seller, address[] memory _buyer, uint[] memory _amountMNE, uint[] memory _availableBalance,uint[] memory _amountETH, uint[] memory _amountETHFee, uint[] memory _date){
	if (_recordsLength > pa.Level2TradeHistorySellerLength())
       _recordsLength = pa.Level2TradeHistorySellerLength();
    _seller = new address[](_recordsLength);
	_buyer = new address[](_recordsLength);
	_amountMNE = new uint[](_recordsLength);
	_availableBalance = new uint[](_recordsLength);
	_amountETH = new uint[](_recordsLength);
	_amountETHFee = new uint[](_recordsLength);
	_date = new uint[](_recordsLength);
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.Level2TradeHistorySellerLength(); i++){
        _seller[count] = pa.Level2TradeHistorySeller(i);
		_buyer[count] = pa.Level2TradeHistoryBuyer(i);
		_amountMNE[count] = pa.Level2TradeHistoryAmountMNE(i);
		_availableBalance[count] = pa.Level2TradeHistoryAvailableAmountMNE(i);
		_amountETH[count] = pa.Level2TradeHistoryAmountETH(i);
		_amountETHFee[count] = pa.Level2TradeHistoryAmountETHFee(i);
		_date[count] = pa.Level2TradeHistoryDate(i);
        count++;
    }    
}

function ListHistoryGenesisSaleLevel3(uint _startingIndex, uint _recordsLength) public view returns (address[] memory _seller, address[] memory _buyer, uint[] memory _amountMNE, uint[] memory _availableBalance, uint[] memory _amountETH, uint[] memory _amountETHFee, uint[] memory _date){
	if (_recordsLength > pa.Level3TradeHistorySellerLength())
       _recordsLength = pa.Level3TradeHistorySellerLength();
    _seller = new address[](_recordsLength);
	_buyer = new address[](_recordsLength);
	_amountMNE = new uint[](_recordsLength);
	_availableBalance =  new uint[](_recordsLength);
	_amountETH = new uint[](_recordsLength);
	_amountETHFee = new uint[](_recordsLength);
	_date = new uint[](_recordsLength);
	
    uint count = 0;
	for(uint i = _startingIndex; i < (_startingIndex + _recordsLength) && i < pa.Level3TradeHistorySellerLength(); i++){
        _seller[count] = pa.Level3TradeHistorySeller(i);
		_buyer[count] = pa.Level3TradeHistoryBuyer(i);
		_amountMNE[count] = pa.Level3TradeHistoryAmountMNE(i);
		_availableBalance[count] = pa.Level3TradeHistoryAvailableAmountMNE(i);
		_amountETH[count] = pa.Level3TradeHistoryAmountETH(i);
		_amountETHFee[count] = pa.Level3TradeHistoryAmountETHFee(i);
		_date[count] = pa.Level3TradeHistoryDate(i);
        count++;
    }
}


function ListTokenCreationHistory(address _address) public view returns (address[] memory _contracts){
	return pc.tokenCreatedGet(_address);
}

function ListTokenICOCreationHistory(address _address) public view returns (address[] memory _contracts){
	return pc.tokenICOCreatedGet(_address);
}
}