/**
 *Submitted for verification at Etherscan.io on 2020-05-02
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
  function genesisAddressesForSaleLevel1SetAt ( uint256 i, address _address ) external;
  function genesisAddressesForSaleLevel2 ( uint256 ) external view returns ( address );
  function genesisAddressesForSaleLevel2Length (  ) external view returns ( uint256 len );
  function genesisAddressesForSaleLevel2Set ( address _genesisAddressesForSaleLevel2 ) external;
  function genesisAddressesForSaleLevel2SetAt ( uint256 i, address _address ) external;
  function genesisAddressesForSaleLevel3 ( uint256 ) external view returns ( address );
  function genesisAddressesForSaleLevel3Length (  ) external view returns ( uint256 len );
  function genesisAddressesForSaleLevel3Set ( address _genesisAddressesForSaleLevel3 ) external;
  function genesisAddressesForSaleLevel3SetAt ( uint256 i, address _address ) external;
  function normalAddressesForSale ( uint256 ) external view returns ( address );
  function normalAddressesForSaleLength (  ) external view returns ( uint256 len );
  function normalAddressesForSaleSet ( address _normalAddressesForSale ) external;
  function normalAddressesForSaleSetAt ( uint256 i, address _address ) external;
  function ownerGenesis (  ) external view returns ( address );
  function ownerGenesisBuys (  ) external view returns ( address );
  function ownerMain (  ) external view returns ( address );
  function ownerNormalAddress (  ) external view returns ( address );
  function ownerStakeBuys (  ) external view returns ( address );
  function ownerStakes (  ) external view returns ( address );
  function setOwnerGenesis (  ) external;
  function setOwnerGenesisBuys (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakeBuys (  ) external;
  function setOwnerStakes (  ) external;
  function stakeHoldersList ( uint256 ) external view returns ( address );
  function stakeHoldersListAt ( uint256 i, address _address ) external;
  function stakeHoldersListLength (  ) external view returns ( uint256 len );
  function stakeHoldersListSet ( address _stakeHoldersList ) external;
  function stakesForSale ( uint256 ) external view returns ( address );
  function stakesForSaleLength (  ) external view returns ( uint256 len );
  function stakesForSaleSet ( address _stakesForSale ) external;
  function stakesForSaleSetAt ( uint256 i, address _address ) external;
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
  function setGenesisCallerAddress ( address _caller ) external returns ( bool success );
  function setOwnerGenesisBuys (  ) external;
  function setOwnerMain (  ) external;
  function setOwnerNormalAddress (  ) external;
  function setOwnerStakeBuys (  ) external;
  function setOwnerStakes (  ) external;
  function BurnGenesisAddresses ( address _from, address[] calldata _genesisAddressesToBurn ) external;
}

interface normalAddress {
  function BuyNormalAddress ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );
  function RemoveNormalAddressFromSale ( address _address ) external;
  function setBalanceNormalAddress ( address _from, address _address, uint256 balance ) external;
  function SetNormalAddressForSale ( address _from, uint256 weiPricePerMNE ) external;
  function setOwnerMain (  ) external;
  function ownerMain (  ) external view returns ( address );
}

interface stakes {
  function RemoveStakeFromSale ( address _from ) external;
  function SetStakeForSale ( address _from, uint256 priceInWei ) external;
  function StakeTransferGenesis ( address _from, address _to, uint256 _value, address[] calldata _genesisAddressesToBurn ) external;
  function StakeTransferMNE ( address _from, address _to, uint256 _value ) external returns ( uint256 _mneToBurn );
  function ownerMain (  ) external view returns ( address );
  function setBalanceStakes ( address _from, address _address, uint256 balance ) external;
  function setOwnerMain (  ) external;
}

interface stakeBuys {
  function BuyStakeGenesis ( address _from, address _address, address[] calldata _genesisAddressesToBurn, uint256 _msgvalue ) external returns ( uint256 _feesToPayToSeller );
  function BuyStakeMNE ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _mneToBurn, uint256 _feesToPayToSeller );
  function ownerMain (  ) external view returns ( address );
  function setOwnerMain (  ) external;
}

interface genesisBuys {
  function BuyGenesisLevel1FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );
  function BuyGenesisLevel2FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );
  function BuyGenesisLevel3FromNormal ( address _from, address _address, uint256 _msgvalue ) external returns ( uint256 _totalToSend );
  function ownerMain (  ) external view returns ( address );
  function setOwnerMain (  ) external;
}

interface tokenService {
  function CreateToken ( address _from, uint256 _msgvalue ) external returns ( uint256 _mneToBurn, address _contract );
  function CreateTokenICO ( address _from, uint256 _msgvalue ) external returns ( uint256 _mneToBurn, address _contract );
  function ownerMain (  ) external view returns ( address );
  function setOwnerMain (  ) external;
}

interface baseTransfers {
	function setOwnerMain (  ) external;
	function transfer ( address _from, address _to, uint256 _value ) external;
	function transferFrom ( address _sender, address _from, address _to, uint256 _amount ) external returns ( bool success );
	function stopSetup ( address _from ) external returns ( bool success );
	function totalSupply (  ) external view returns ( uint256 TotalSupply );
}

interface mneStaking {
	function startStaking(address _sender, uint256 _amountToStake, address[] calldata _addressList, uint256[] calldata uintList) external;
}

interface luckyDraw {
	function BuyTickets(address _sender, uint256[] calldata _max) payable external returns ( uint256 );
}

interface externalService {
	function externalFunction(address _sender, address[] calldata _addressList, uint256[] calldata _uintList) payable external returns ( uint256 );
}

interface externalReceiver {
	function externalFunction(address _sender, uint256 _mneAmount, address[] calldata _addressList, uint256[] calldata _uintList) payable external;
}

contract Minereum { 
string public name; 
string public symbol; 
uint8 public decimals; 

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event LogStakeHolderSends(address indexed to, uint balance, uint amountToSend);
event LogFailedStakeHolderSends(address indexed to, uint balance, uint amountToSend);
event TokenCreation(address indexed from, address contractAdd);
event TokenCreationICO(address indexed from, address  contractAdd);
event StakeTransfer(address indexed from, address indexed to, uint256 value);

publicCalls public pc;
publicArrays public pa;
genesisCalls public gn;
normalAddress public na;
stakes public st;
stakeBuys public stb;
genesisBuys public gnb;
tokenService public tks;
baseTransfers public bst;
mneStaking public mneStk;
luckyDraw public lkd;
externalService public extS1;
externalService public extS2;
externalReceiver public extR1;

address public updaterAddress = 0x0000000000000000000000000000000000000000;
function setUpdater() public {if (updaterAddress == 0x0000000000000000000000000000000000000000) updaterAddress = msg.sender; else revert();}
address public payoutOwner = 0x0000000000000000000000000000000000000000;
bool public payoutBlocked = false;
address payable public secondaryPayoutAddress = 0x0000000000000000000000000000000000000000;

constructor(address _publicCallsAddress, address _publicArraysAddress, address _genesisCallsAddress, address _normalAddressAddress,
 address _stakesAddress, address _stakesBuysAddress,address _genesisBuysAddress, address _tokenServiceAddress, address _baseTransfersAddress) public {
name = "Minereum"; 
symbol = "MNE"; 
decimals = 8; 
setUpdater();
pc = publicCalls(_publicCallsAddress);
pc.setOwnerMain();
pa = publicArrays(_publicArraysAddress);
pa.setOwnerMain();
gn = genesisCalls(_genesisCallsAddress);
gn.setOwnerMain();
na = normalAddress(_normalAddressAddress);
na.setOwnerMain();
st = stakes(_stakesAddress);
st.setOwnerMain();
stb = stakeBuys(_stakesBuysAddress);
stb.setOwnerMain();
gnb = genesisBuys(_genesisBuysAddress);
gnb.setOwnerMain();
tks = tokenService(_tokenServiceAddress);
tks.setOwnerMain();
bst = baseTransfers(_baseTransfersAddress);
bst.setOwnerMain();
}

function reloadGenesis(address _address) public { if (msg.sender == updaterAddress)	{gn = genesisCalls(_address); gn.setOwnerMain(); } else revert();}
function reloadNormalAddress(address _address) public { if (msg.sender == updaterAddress)	{na = normalAddress(_address); na.setOwnerMain(); } else revert();}
function reloadStakes(address _address) public { if (msg.sender == updaterAddress)	{st = stakes(_address); st.setOwnerMain(); } else revert();}
function reloadStakeBuys(address _address) public { if (msg.sender == updaterAddress)	{stb = stakeBuys(_address); stb.setOwnerMain(); } else revert();}
function reloadGenesisBuys(address _address) public { if (msg.sender == updaterAddress)	{gnb = genesisBuys(_address); gnb.setOwnerMain(); } else revert();}
function reloadTokenService(address _address) public { if (msg.sender == updaterAddress)	{tks = tokenService(_address); tks.setOwnerMain(); } else revert();}
function reloadBaseTransfers(address _address) public { if (msg.sender == updaterAddress)	{bst = baseTransfers(_address); bst.setOwnerMain(); } else revert();}
function reloadPublicCalls(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pc = publicCalls(_address); pc.setOwnerMain();} else revert();}
function reloadPublicArrays(address _address, uint code) public { if (!(code == 1234)) revert();  if (msg.sender == updaterAddress)	{pa = publicArrays(_address); pa.setOwnerMain();} else revert();}
function loadMNEStaking(address _address) public { if (msg.sender == updaterAddress)	{mneStk = mneStaking(_address); } else revert();}
function loadLuckyDraw(address _address) public { if (msg.sender == updaterAddress)	{lkd = luckyDraw(_address); } else revert();}

function externalService1(address _address) public { if (msg.sender == updaterAddress)	{extS1 = externalService(_address); } else revert();}
function externalService2(address _address) public { if (msg.sender == updaterAddress)	{extS2 = externalService(_address); } else revert();}

function externalReceiver1(address _address) public { if (msg.sender == updaterAddress)	{extR1 = externalReceiver(_address); } else revert();}


function setPayoutOwner() public
{
	if(payoutOwner == 0x0000000000000000000000000000000000000000)
		payoutOwner = msg.sender;
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
	return block.number - pc.initialBlockCount();
}

function availableBalanceOf(address _address) public view returns (uint256 Balance)
{
	return gn.availableBalanceOf(_address);
}

function totalSupply() public view returns (uint256 TotalSupply)
{	
	return bst.totalSupply();
}

function transfer(address _to, uint256 _value)  public { 
if (_to == address(this)) revert('if (_to == address(this))');
bst.transfer(msg.sender, _to, _value);
emit Transfer(msg.sender, _to, _value); 
}

function transferFrom(
        address _from,
        address _to,
        uint256 _amount
) public returns (bool success) {
		bool result = bst.transferFrom(msg.sender, _from, _to, _amount);
        if (result) emit Transfer(_from, _to, _amount);
        return result;    
}

function approve(address _spender, uint256 _amount) public returns (bool success) {
    pc.allowedSet(msg.sender,_spender, _amount);
    emit Approval(msg.sender, _spender, _amount);
    return true;
}

function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return pc.allowed(_owner,_spender);
}

function balanceOf(address _address) public view returns (uint256 balance) {
	return gn.balanceOf(_address);
}

function stakeBalanceOf(address _address) public view returns (uint256 balance) {
	return pc.stakeBalances(_address);
}

function TransferGenesis(address _to) public {
	emit Transfer(msg.sender, _to, balanceOf(msg.sender));	
	if (_to == address(this)) revert('if (_to == address(this))');	
	gn.TransferGenesis(msg.sender, _to);	
}

function SetGenesisForSale(uint256 weiPrice) public {	
	gn.SetGenesisForSale(msg.sender, weiPrice);
}

function AllowReceiveGenesisTransfers() public { 
	gn.AllowReceiveGenesisTransfers(msg.sender);
}

function RemoveAllowReceiveGenesisTransfers() public { 
	gn.RemoveAllowReceiveGenesisTransfers(msg.sender);
}

function RemoveGenesisAddressFromSale() public { 
	gn.RemoveGenesisAddressFromSale(msg.sender);
}

function AllowAddressToDestroyGenesis(address _address) public  { 
	gn.AllowAddressToDestroyGenesis(msg.sender, _address);
}

function RemoveAllowAddressToDestroyGenesis() public { 
	gn.RemoveAllowAddressToDestroyGenesis(msg.sender);
}

function UpgradeToLevel2FromLevel1() public payable {
	gn.UpgradeToLevel2FromLevel1(msg.sender, msg.value);
}

function UpgradeToLevel3FromLevel1() public payable {
	gn.UpgradeToLevel3FromLevel1(msg.sender, msg.value);
}

function UpgradeToLevel3FromLevel2() public payable {
	gn.UpgradeToLevel3FromLevel2(msg.sender, msg.value);
}

function UpgradeToLevel3FromDev() public {
	gn.UpgradeToLevel3FromDev(msg.sender);
}

function UpgradeOthersToLevel2FromLevel1(address[] memory _addresses) public payable {
	uint count = _addresses.length;
	if (msg.value != (pc.ethFeeToUpgradeToLevel2()*count)) revert('(msg.value != pc.ethFeeToUpgradeToLevel2()*count)');
	uint i = 0;
	while (i < count)
	{
		gn.UpgradeToLevel2FromLevel1(_addresses[i], pc.ethFeeToUpgradeToLevel2());
		i++;
	}
}

function UpgradeOthersToLevel3FromLevel1(address[] memory _addresses) public payable {
	uint count = _addresses.length;
	if (msg.value != ((pc.ethFeeToUpgradeToLevel2() + pc.ethFeeToUpgradeToLevel3())*count)) revert('(weiValue != ((msg.value + pc.ethFeeToUpgradeToLevel3())*count))');
	uint i = 0;
	while (i < count)
	{
		gn.UpgradeToLevel3FromLevel1(_addresses[i], (pc.ethFeeToUpgradeToLevel2() + pc.ethFeeToUpgradeToLevel3()));
		i++;
	}
}

function UpgradeOthersToLevel3FromLevel2(address[] memory _addresses) public payable {
	uint count = _addresses.length;
	if (msg.value != (pc.ethFeeToUpgradeToLevel3()*count)) revert('(msg.value != (pc.ethFeeToUpgradeToLevel3()*count))');
	uint i = 0;
	while (i < count)
	{
		gn.UpgradeToLevel3FromLevel2(_addresses[i], pc.ethFeeToUpgradeToLevel3());
		i++;
	}
}

function UpgradeOthersToLevel3FromDev(address[] memory _addresses) public {
	uint count = _addresses.length;	
	uint i = 0;
	while (i < count)
	{
		gn.UpgradeToLevel3FromDev(_addresses[i]);
		i++;
	}
}

function BuyGenesisAddress(address payable _address) public payable
{
	if (gn.isGenesisAddressLevel1(_address))
		BuyGenesisLevel1FromNormal(_address);
	else if (gn.isGenesisAddressLevel2(_address))
		BuyGenesisLevel2FromNormal(_address);
	else if (gn.isGenesisAddressLevel3(_address))
		BuyGenesisLevel3FromNormal(_address);
	else
		revert('Address not for sale');
}

function SetNormalAddressForSale(uint256 weiPricePerMNE) public {	
	na.SetNormalAddressForSale(msg.sender, weiPricePerMNE);
}

function RemoveNormalAddressFromSale() public
{
	na.RemoveNormalAddressFromSale(msg.sender);
}

function BuyNormalAddress(address payable _address) public payable{
	emit Transfer(_address, msg.sender, balanceOf(_address));
	uint256 feesToPayToSeller = na.BuyNormalAddress(msg.sender, address(_address), msg.value);				
	if(!_address.send(feesToPayToSeller)) revert('(!_address.send(feesToPayToSeller))');		
}

function setBalanceNormalAddress(address _address, uint256 _balance) public
{
	na.setBalanceNormalAddress(msg.sender, _address, _balance);
	emit Transfer(address(this), _address, _balance); 
}

function ContractTransferAllFundsOut() public
{
	//in case of hack, funds can be transfered out to another addresses and transferred to the stake holders from there
	if (payoutBlocked)
		if(!secondaryPayoutAddress.send(address(this).balance)) revert();
}

function PayoutStakeHolders() public {
	require(msg.sender == tx.origin); //For security reasons this line is to prevent smart contract calls
	if (payoutBlocked) revert('Payouts Blocked'); //In case of hack, payouts can be blocked
	uint contractBalance = address(this).balance;
	if (!(contractBalance > 0)) revert('(!(contractBalance > 0))');
	uint i;
	uint max;
	
	i = 0;
	max = pa.stakeHoldersListLength();

	while (i < max)
	{
		address payable add = payable(pa.stakeHoldersList(i));
		uint balance = pc.stakeBalances(add);
		uint amountToSend = contractBalance * balance / pc.stakeDecimals();
		if (amountToSend > 0)
		{
			if (!add.send(amountToSend))
				emit LogFailedStakeHolderSends(add, balance, amountToSend);
			else
			{
				pc.totalPaidStakeHoldersSet(pc.totalPaidStakeHolders() + amountToSend);				
			}			
		}
		i++;
	}
}

function stopSetup() public returns (bool success)
{
	return bst.stopSetup(msg.sender);
}

function BurnTokens(uint256 mneToBurn) public returns (bool success) {	
	gn.BurnTokens(msg.sender, mneToBurn);
	emit Transfer(msg.sender, 0x0000000000000000000000000000000000000000, mneToBurn);
	return true;
}

function SetStakeForSale(uint256 priceInWei) public
{	
	st.SetStakeForSale(msg.sender, priceInWei);
}

function RemoveStakeFromSale() public {
	st.RemoveStakeFromSale(msg.sender);
}

function StakeTransferMNE(address _to, uint256 _value) public {
	if (_to == address(this)) revert('if (_to == address(this))');
	BurnTokens(st.StakeTransferMNE(msg.sender, _to, _value));
	emit StakeTransfer(msg.sender, _to, _value); 
}

function BurnGenesisAddresses(address[] memory _genesisAddressesToBurn) public
{
	uint i = 0;	
	while(i < _genesisAddressesToBurn.length)
	{
		emit Transfer(_genesisAddressesToBurn[i], 0x0000000000000000000000000000000000000000, balanceOf(_genesisAddressesToBurn[i]));
		i++;
	}
	gn.BurnGenesisAddresses(msg.sender, _genesisAddressesToBurn);	
}

function StakeTransferGenesis(address _to, uint256 _value, address[] memory _genesisAddressesToBurn) public {
	if (_to == address(this)) revert('if (_to == address(this))');
	uint i = 0;	
	while(i < _genesisAddressesToBurn.length)
	{
		emit Transfer(_genesisAddressesToBurn[i], 0x0000000000000000000000000000000000000000, balanceOf(_genesisAddressesToBurn[i]));
		i++;
	}
	st.StakeTransferGenesis(msg.sender, _to, _value, _genesisAddressesToBurn);	
	emit StakeTransfer(msg.sender, _to, _value); 
}

function setBalanceStakes(address _address, uint256 balance) public {
	st.setBalanceStakes(msg.sender, _address, balance);
}

function BuyGenesisLevel1FromNormal(address payable _address) public payable {
	emit Transfer(_address, msg.sender, balanceOf(_address));
	uint256 feesToPayToSeller = gnb.BuyGenesisLevel1FromNormal(msg.sender, address(_address), msg.value);
	if(!_address.send(feesToPayToSeller)) revert('(!_address.send(feesToPayToSeller))');				
}

function BuyGenesisLevel2FromNormal(address payable _address) public payable{
	emit Transfer(_address, msg.sender, balanceOf(_address));
	uint256 feesToPayToSeller = gnb.BuyGenesisLevel2FromNormal(msg.sender, address(_address), msg.value);	
	if(!_address.send(feesToPayToSeller)) revert('(!_address.send(feesToPayToSeller))');	
}

function BuyGenesisLevel3FromNormal(address payable _address) public payable{
	emit Transfer(_address, msg.sender, balanceOf(_address));
	uint256 feesToPayToSeller = gnb.BuyGenesisLevel3FromNormal(msg.sender, address(_address), msg.value);	
	if(!_address.send(feesToPayToSeller)) revert('(!_address.send(feesToPayToSeller))');		
}

function BuyStakeMNE(address payable _address) public payable {
	uint256 balanceToSend = pc.stakeBalances(_address);
	(uint256 mneToBurn, uint256 feesToPayToSeller) = stb.BuyStakeMNE(msg.sender, address(_address), msg.value);
	BurnTokens(mneToBurn);
	if(!_address.send(feesToPayToSeller)) revert('(!_address.send(feesToPayToSeller))');	
	emit StakeTransfer(_address, msg.sender, balanceToSend); 
}

function BuyStakeGenesis(address payable _address, address[] memory _genesisAddressesToBurn) public payable {
	uint256 balanceToSend = pc.stakeBalances(_address);
	uint i = 0;
	while(i < _genesisAddressesToBurn.length)
	{
		emit Transfer(_genesisAddressesToBurn[i], 0x0000000000000000000000000000000000000000, balanceOf(_genesisAddressesToBurn[i]));
		i++;
	}
	uint256 feesToPayToSeller = stb.BuyStakeGenesis(msg.sender, address(_address), _genesisAddressesToBurn, msg.value);
	if(!_address.send(feesToPayToSeller)) revert();		
	emit StakeTransfer(_address, msg.sender, balanceToSend); 
}

function CreateToken() public payable {
	(uint256 _mneToBurn, address tokenAdderss) = tks.CreateToken(msg.sender, msg.value);
	BurnTokens(_mneToBurn);
	emit TokenCreation(msg.sender, tokenAdderss);
}

function CreateTokenICO() public payable {
	(uint256 _mneToBurn, address tokenAdderss) = tks.CreateTokenICO(msg.sender, msg.value);
	BurnTokens(_mneToBurn);
	emit TokenCreationICO(msg.sender, tokenAdderss);
}

function Payment() public payable {
	
}

function BuyLuckyDrawTickets(uint256[] memory max) public payable {
	uint256 _mneToBurn = lkd.BuyTickets.value(msg.value)(msg.sender, max);
	if (_mneToBurn > 0) BurnTokens(_mneToBurn);
}

function Staking(uint256 _amountToStake, address[] memory _addressList, uint256[] memory uintList) public {
	if (_amountToStake > 0)
	{
		bst.transfer(msg.sender, address(mneStk), _amountToStake);
		emit Transfer(msg.sender, address(mneStk), _amountToStake); 
	}
	mneStk.startStaking(msg.sender, _amountToStake, _addressList, uintList);
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

function registerAddresses(address[] memory _addressList) public {
	uint i = 0;
	if (pc.setupRunning() && msg.sender == pc.genesisCallerAddress())
	{
		while(i < _addressList.length)
		{
			emit Transfer(address(this), _addressList[i], gn.balanceOf(_addressList[i]));
			i++;
		}
	}
	else 
	{
		revert();
	}
}

function ethFeeToUpgradeToLevel2Set(uint256 _ethFeeToUpgradeToLevel2) public {pc.ethFeeToUpgradeToLevel2Set(msg.sender, _ethFeeToUpgradeToLevel2);}
function ethFeeToUpgradeToLevel3Set(uint256 _ethFeeToUpgradeToLevel3) public {pc.ethFeeToUpgradeToLevel3Set(msg.sender, _ethFeeToUpgradeToLevel3);}
function ethFeeToBuyLevel1Set(uint256 _ethFeeToBuyLevel1) public {pc.ethFeeToBuyLevel1Set(msg.sender, _ethFeeToBuyLevel1);}
function ethFeeForSellerLevel1Set(uint256 _ethFeeForSellerLevel1) public {pc.ethFeeForSellerLevel1Set(msg.sender, _ethFeeForSellerLevel1);}
function ethFeeForTokenSet(uint256 _ethFeeForToken) public {pc.ethFeeForTokenSet(msg.sender, _ethFeeForToken);}
function ethFeeForTokenICOSet(uint256 _ethFeeForTokenICO) public {pc.ethFeeForTokenICOSet(msg.sender, _ethFeeForTokenICO);}
function ethPercentFeeGenesisExchangeSet(uint256 _ethPercentFeeGenesisExchange) public {pc.ethPercentFeeGenesisExchangeSet(msg.sender, _ethPercentFeeGenesisExchange);}
function ethPercentFeeNormalExchangeSet(uint256 _ethPercentFeeNormalExchange) public {pc.ethPercentFeeNormalExchangeSet(msg.sender, _ethPercentFeeNormalExchange);}
function ethPercentStakeExchangeSet(uint256 _ethPercentStakeExchange) public {pc.ethPercentStakeExchangeSet(msg.sender, _ethPercentStakeExchange);}
function amountOfGenesisToBuyStakesSet(uint256 _amountOfGenesisToBuyStakes) public {pc.amountOfGenesisToBuyStakesSet(msg.sender, _amountOfGenesisToBuyStakes);}
function amountOfMNEToBuyStakesSet(uint256 _amountOfMNEToBuyStakes) public {pc.amountOfMNEToBuyStakesSet(msg.sender, _amountOfMNEToBuyStakes);}
function amountOfMNEForTokenSet(uint256 _amountOfMNEForToken) public {pc.amountOfMNEForTokenSet(msg.sender, _amountOfMNEForToken);}
function amountOfMNEForTokenICOSet(uint256 _amountOfMNEForTokenICO) public {pc.amountOfMNEForTokenICOSet(msg.sender, _amountOfMNEForTokenICO);}
function amountOfMNEToTransferStakesSet(uint256 _amountOfMNEToTransferStakes) public {pc.amountOfMNEToTransferStakesSet(msg.sender, _amountOfMNEToTransferStakes);}
function amountOfGenesisToTransferStakesSet(uint256 _amountOfGenesisToTransferStakes) public {pc.amountOfGenesisToTransferStakesSet(msg.sender, _amountOfGenesisToTransferStakes);}
function stakeDecimalsSet(uint256 _stakeDecimals) public {pc.stakeDecimalsSet(msg.sender, _stakeDecimals);}


function ServiceFunction1(address[] memory _addressList, uint256[] memory _uintList) public payable {
	uint256 _mneToBurn = extS1.externalFunction.value(msg.value)(msg.sender, _addressList, _uintList);
	if (_mneToBurn > 0) BurnTokens(_mneToBurn);	
}

function ServiceFunction2(address[] memory _addressList, uint256[] memory _uintList) public payable {
	uint256 _mneToBurn = extS2.externalFunction.value(msg.value)(msg.sender, _addressList, _uintList);
	if (_mneToBurn > 0) BurnTokens(_mneToBurn);	
}


function ReceiverFunction1(uint256 _mneAmount, address[] memory _addressList, uint256[] memory _uintList) public payable {
	if (_mneAmount > 0)
	{
		bst.transfer(msg.sender, address(extR1), _mneAmount);
		emit Transfer(msg.sender, address(extR1), _mneAmount); 
	}
	extR1.externalFunction.value(msg.value)(msg.sender, _mneAmount, _addressList, _uintList);	
}
}