pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./NFT/CrimeMarketplace.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
import "./Governable.sol";
import "./CrimeCashGame.sol";
import "./CrimeCash.sol";
import "./libraries/CrimerLibrary.sol";
import "./Types/Crimer.sol";
import "./Types/CrimeNFT.sol";
import "./Types/NFTWeaponType.sol";
import "./Types/NFTPerkType.sol";
import "./NFT/CrimERC1155.sol";
import "./libraries/SafePercentageLibrary.sol";

contract CrimerInfoStorage { 
  using SafeMath for uint256;
  using SafePercentageLibrary for uint256;
  
  address public crimerInfo;

  Crimer[] private allCrimers;

  mapping(address=>Crimer) private crimers;
  mapping(uint8 => mapping(address=>mapping(address=>uint8))) private stolenCount;
  mapping(uint8=>mapping(address=>uint256)) private transactions;

  mapping(address => mapping(uint256 => bool)) isCrimerBoostExists;
  mapping(address => mapping(uint8 => bool)) private isCrimerBoughtProtectionAtRoundDay;

  modifier onlyFromCrimerInfo {
    require(msg.sender == crimerInfo, "Sender not a CrimerInfo");
    _;
  }

  constructor(address _crimerInfoAddress) public { 
    crimerInfo = _crimerInfoAddress;
  }

  /* crimers */
  function getCrimer(address _of) external view returns(Crimer memory _crimer){ 
    _crimer = crimers[_of];
  }
  function getAllCrimers() external view returns(Crimer[] memory _crimers){ 
    _crimers = allCrimers;
  }
  function getCrimersCount() external view returns(uint256){ 
    return allCrimers.length;
  }
  function crimerPushBoost(address _of, uint256 _assetId) external onlyFromCrimerInfo { 
    require(crimers[_of].exist, "Crimer is not exists");
    crimers[_of].boosts.push(_assetId);
    allCrimers[crimers[_of].index].boosts.push(_assetId);
  }
  function setCrimer(address _of, Crimer memory _val) external onlyFromCrimerInfo { 
    if(!crimers[_of].exist) { 
      _val.index = allCrimers.length;
      allCrimers.push(_val);
    }else { 
      _val.index = crimers[_of].index; 
      _val.boosts = crimers[_of].boosts;
      allCrimers[_val.index] = _val; 
      allCrimers[_val.index].boosts = _val.boosts;
    }
    crimers[_of] = _val;
    crimers[_of].boosts = _val.boosts;
  }
  
  /* stolenCount */
  function getStolenCount(uint8 _roundDay, address _defense, address _attack) external view returns (uint8){ 
    return stolenCount[_roundDay][_defense][_attack];
  }
  function setStolenCount(uint8 _roundDay, address _defense, address _attack, uint8 _val) external onlyFromCrimerInfo { 
    stolenCount[_roundDay][_defense][_attack] = _val;
  }
  function getStealCashCount(uint8 _roundDay, address[] calldata _crimers, address _crimer) external view  returns (uint256[] memory _stealCashLimits) { 
    _stealCashLimits = new uint256[](_crimers.length);
    for (uint i; i < _crimers.length; i++) 
      _stealCashLimits[i] = stolenCount[_roundDay][_crimers[i]][_crimer];
  }
  function incrementStolenCount(uint8 _roundDay, address _defense, address _attack) external onlyFromCrimerInfo { 
    stolenCount[_roundDay][_defense][_attack] = stolenCount[_roundDay][_defense][_attack] + 1;
  }

  /* crimer_addresses */  
  function getTransactions(uint8 _roundDay, address _of) external view returns (uint256){ 
    return transactions[_roundDay][_of];
  }
  function setTransactions(uint8 _roundDay, address _of, uint256 _value) external onlyFromCrimerInfo { 
    transactions[_roundDay][_of] = _value;
  } 
  function removeOneTransaction(uint256 _transactionsPerDay,uint8 _roundDay, address _sender) external onlyFromCrimerInfo {
    uint256 trans = transactions[_roundDay][_sender];
    require(trans < _transactionsPerDay, "you exceeded transactions amount");
    transactions[_roundDay][_sender] = trans + 1;
  }

  /* isCrimerBoostExists */
  function getIsCrimerBoostExists(address _crimer, uint256 _asset) external view returns (bool){ 
    return isCrimerBoostExists[_crimer][_asset];
  }
  function setIsCrimerBoostExists(address _crimer, uint256 _asset, bool _val) external onlyFromCrimerInfo { 
    isCrimerBoostExists[_crimer][_asset] = _val;
  }

  /* isCrimerBoughtProtectionAtRoundDay */
  function getIsCrimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) external view returns (bool){ 
    return isCrimerBoughtProtectionAtRoundDay[_crimer][_roundDay];
  }
  function setIsCrimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay, bool _val) external onlyFromCrimerInfo { 
    isCrimerBoughtProtectionAtRoundDay[_crimer][_roundDay] = _val;
  }
}

contract CrimerInfo is Governable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;
  using CrimerLibrary for Crimer;

  CrimerInfoStorage public crimerInfoStorage;
  CrimeMarketplace private immutable crimeMarketplace;
  CrimeCashGame public immutable gameEngine;
  CrimeCash public crimecashToken;
  address public _taxReceiverAddressFromSellingAssets;
  
  uint256 private constant topPowerCount = 50;
  uint256 private constant topCashCount = 50;
  uint256 private constant topReferralsCount = 25;

  uint256 private constant referralCashReward = 1000_00;
  uint256 private constant referralAttackReward = 500;

  uint256 private constant allBoostBoughtBonus = 157;

  uint8   private maxStolenCountLimit = 5;
  uint8   private maxBuyLimit = 10;
  uint256 private minLimit = 10;
  uint256 private maxLimit = 50;
  uint256 private initBank = 500;
  uint256 private initCash = 500;
  uint256 private initAttack = 750;
  uint256 private initDefense = 500;
  uint256 private initProtectedUntil = 15;
  uint8   private startCashMintAtRoundDay = 3;
  uint8   private cashMintAmountPercentage = 10;

  mapping(address => uint256[]) private currentlyActiveNFTWeapons;
  mapping(address => uint256[]) private currentlyActiveNFTPerks;

  uint256 public constant transactionsPerDay = 15;


  // dublicated from CrimeCashGame. Needed to save gas on external calls
  uint8   private roundDay; 
  bool    private isRoundOpening;
  bool    private isRoundFinished;
  
  event eventAddNewCrimer(address crimer, uint8 roundDay);
  event eventAddNewCrimerByReferral(address crimer, address byReferral, uint8 roundDay);
  event eventMoveToBank(address crimer, uint256 amount, uint8 roundDay);
  event eventMoveToCash(address crimer, uint256 amount, uint8 roundDay);
  event eventDeposit(address crimer, uint256 amount, uint8 roundDay);
  event eventClaim(address crimer, uint256 poolIndex, uint8 payout_mode, uint256 amount, uint8 roundDay);
  event eventWithdraw(address crimer, uint256 _amount, uint8 roundDay);
  event eventBuyAsset(address crimer, uint8 assetType, uint256 assetIndex, uint8 count, uint256 cost_amount, uint8 roundDay);
  event eventStealCash(address crimer, address other, uint256 stolenCash, uint256 stolenRate, uint8 roundDay);
  event stakeCashToken(uint256 poolIndex, address crimer, uint256 amount, uint8 roundDay);
  event untakeCashToken(uint256 poolIndex, address crimer, uint256 amount, uint8 roundDay);
   
  constructor(CrimeCashGame _gameEngine, CrimeMarketplace _crimeMarketplace, Storage _store) public Governable(_store) {
    require(address(_crimeMarketplace) != address(0), "Invalid Marketplace address");
    require(address(_gameEngine) != address(0), "Invalid Game engine address");

    gameEngine = _gameEngine;
    crimeMarketplace  = _crimeMarketplace;
    _taxReceiverAddressFromSellingAssets = _store.owner();
  }

  function setStorage(address _newStorageAddress) external {  
    onlyGameEngine();
    require(_newStorageAddress != address(0), "Invalid NewStorageAddress");

    crimerInfoStorage = CrimerInfoStorage(_newStorageAddress);
  }

  function setCrimeCash(address _newCrimeCash) external {  
    onlyGameEngine();
    require(_newCrimeCash != address(0), "Invalid NewCrimeCash");

    crimecashToken = CrimeCash(_newCrimeCash);
  }

  function updateGameState(uint8 _roundDay, bool _isRoundOpening, bool _isRoundFinished) external {
    onlyGameEngine();
    roundDay = _roundDay;
    isRoundOpening = _isRoundOpening;
    isRoundFinished = _isRoundFinished;
  }

  function getGameSettings() external view returns (
      uint8 _maxStolenCountLimit,
      uint8 _maxBuyLimit,
      uint256 _minLimit,
      uint256 _maxLimit,
      uint256 _initBank,
      uint256 _initCash,
      uint256 _initAttack,
      uint256 _initDefense,
      uint256 _initProtectedUntil,
      uint8 _startCashMintAtRoundDay,
      uint8 _cashMintAmountPercentage
  ){
    return  (
      maxStolenCountLimit,
      maxBuyLimit,
      minLimit,
      maxLimit,
      initBank,
      initCash,
      initAttack,
      initDefense,
      initProtectedUntil,
      startCashMintAtRoundDay,
      cashMintAmountPercentage
    );
  }

  function setGameSettings(uint256 _bank, uint256 _cash, uint256 _attack, uint256 _defense, uint256 _protectedUntil, uint256 _minLimit, uint256 _maxLimit, uint8 _maxStolenCountLimit, uint8 _maxBuyLimit, uint8 _startCashMintAtRoundDay, uint8 _cashMintAmountPercentage) external {
    onlyGovernance();
    require(_bank > 0 && _cash > 0 && _attack > 0 && _defense > 0 && _minLimit > 0 && _maxLimit > 0 && _maxBuyLimit > 0 && _maxStolenCountLimit > 0);

    initBank = _bank;
    initCash = _cash;
    initAttack = _attack;
    initDefense = _defense;
    initProtectedUntil = _protectedUntil;
    minLimit = _minLimit;
    maxLimit = _maxLimit;
    maxBuyLimit = _maxBuyLimit;
    maxStolenCountLimit = _maxStolenCountLimit;
    startCashMintAtRoundDay = _startCashMintAtRoundDay;
    cashMintAmountPercentage = _cashMintAmountPercentage;
  }

  function addReferralTo(address _addTo) external { 
    onlyGovernaneOrController();
    require(_addTo != _msgSender(), "Cannot add referral to controller");
    Crimer memory c = crimerInfoStorage.getCrimer(_addTo);
    require(c.exist, "Crimer doesn`t exist");
    c.bank = c.bank.add(referralCashReward);
    c.attack = c.attack.add(referralAttackReward);
    crimerInfoStorage.setCrimer(_addTo, c);
  }

  function createNewCrimer() external {
    onlyCrimer();
    _createNewCrimer(_msgSender());
    emit eventAddNewCrimer(_msgSender(), roundDay);
  }

  function createNewCrimerByReferral(address _byReferral) external {
    onlyCrimer();
    _createNewCrimerByReferral(_msgSender(), _byReferral);
  }

  function createNewCrimerByReferral(address _crimer, address _byReferral) external {
    onlyGovernaneOrController();
    require(_crimer != address(0), "Invalid crimer value");
    _createNewCrimerByReferral(_crimer, _byReferral);
  }

  function _createNewCrimerByReferral(address _crimer, address _byReferral) private {
    require(_crimer != _byReferral, "sender==ByRef");
    Crimer memory c = crimerInfoStorage.getCrimer(_byReferral);
    require(c.exist, "nonexist crimer");

    _createNewCrimer(_crimer);
    
    c.referrals = c.referrals.add(1);
    c.bank = c.bank.add(referralCashReward);
    c.attack = c.attack.add(referralAttackReward);

    // if user achives 2 referrals - he get 200% farming boost
    if(c.referrals == 2) c.boost = c.boost.add(200);

    crimerInfoStorage.setCrimer(_byReferral, c);
    emit eventAddNewCrimerByReferral(_crimer, _byReferral, roundDay);
  }

  function _createNewCrimer(address crimerAddress) private {
    Crimer memory c = crimerInfoStorage.getCrimer(crimerAddress);
    require(!c.exist, "Crimer is already exists");

    Crimer memory _crimer = Crimer({
      exist: true,
      userAddress: crimerAddress, 
      bank: initBank.mul(10**2),
      cash: initCash.mul(10**2),
      attack: initAttack,
      defense : initDefense,
      boost: 0,
      referrals : 0,
      protectedUntil : block.timestamp + (initProtectedUntil * 1 minutes),
      boosts: new uint256[](0),
      nftPerkAttackBoost: 0, 
      nftPerkDefenseBoost: 0, 
      nftPerkPowerBoost: 0, 
      nftPerkStakeBoost: 0,
      index: 0
    });

    crimerInfoStorage.setCrimer(crimerAddress, _crimer);

    // if some nfts from the previous game are still in inventory - apply them
    if(currentlyActiveNFTWeapons[crimerAddress].length != 0) { 
      _transferNftFrom(address(this), _msgSender(), currentlyActiveNFTWeapons[_msgSender()]);
      delete currentlyActiveNFTWeapons[crimerAddress];
    }

    if(currentlyActiveNFTPerks[crimerAddress].length != 0){
      _transferNftFrom(address(this), _msgSender(), currentlyActiveNFTPerks[_msgSender()]);
      delete currentlyActiveNFTPerks[crimerAddress];
    }

    crimecashToken.mint(address(this), initBank.add(initCash).mul(10**2));
  }

  function deposit(uint256 _amount) external {
    onlyCrimer();
    require(crimecashToken.balanceOf(_msgSender()) >= _amount, "lack ccash balance");
    require(crimecashToken.balanceOf(_msgSender()) + _amount >= crimecashToken.balanceOf(_msgSender()), "Overflow");
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());
    c.bank = c.bank.add(_amount);
    crimerInfoStorage.setCrimer(_msgSender(), c);
    crimecashToken.transferFrom(address(_msgSender()), address(this), _amount);
    emit eventDeposit(_msgSender(), _amount, roundDay);
  }
  function withdraw(uint256 _amount) external {
    onlyCrimer();
    require(crimecashToken.balanceOf(address(this)) >= _amount, "Not enough ccash");
    require(crimecashToken.balanceOf(address(this)) + _amount >= crimecashToken.balanceOf(address(this)), "Overflow");
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());
    require(c.bank >= _amount, "lack balance");
    
    c.bank = c.bank.sub(_amount);
    crimerInfoStorage.setCrimer(_msgSender(), c);

    crimecashToken.transfer(address(_msgSender()), _amount);
    emit eventWithdraw(_msgSender(), _amount, roundDay);
  }

  function moveToBank(uint256 _amount) external {
    onlyCrimer();
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());
    require(c.cash >= _amount, "Not enough balance. You were looted during transaction.");
    require(c.bank + _amount >= c.bank, "Overflow");
    crimerInfoStorage.removeOneTransaction(transactionsPerDay, roundDay, _msgSender());
    c.bank = c.bank.add(_amount);
    c.cash = c.cash.sub(_amount);
    crimerInfoStorage.setCrimer(_msgSender(), c);
    emit eventMoveToBank(_msgSender(), _amount, roundDay);
  }

  function moveToCash(uint256 _amount) external {
    onlyCrimer();
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());
    require(c.bank >= _amount, "Not enough balance to move fund");
    require(c.cash + _amount >= c.cash, "Overflow");

    crimerInfoStorage.removeOneTransaction(transactionsPerDay, roundDay, _msgSender());

    c.cash = c.cash.add(_amount);
    c.bank = c.bank.sub(_amount);
    crimerInfoStorage.setCrimer(_msgSender(), c);

    emit eventMoveToCash(_msgSender(), _amount, roundDay);
  }

  function getCurrentlyActiveNFTWeapons(address _of) external view returns(uint256[] memory) { 
    return currentlyActiveNFTWeapons[_of];
  }
  function getCurrentlyActiveNFTPerks(address _of) external view returns(uint256[] memory) { 
    return currentlyActiveNFTPerks[_of];
  }

  function setNfts(uint256[] calldata _nftWeaponIds, uint256[] calldata _nftPerkIds) external { 
    onlyCrimer();
    _setNFTWeapons(_nftWeaponIds);
    _setNFTPerks(_nftPerkIds);
  }

  function unsetAllNfts() external { 
    if(crimerInfoStorage.getCrimer(_msgSender()).exist) { 
      _deactivateNFTPerksAndTransfer(_msgSender());
      _deactivateNFTWeaponsAndTransfer(_msgSender());
    } else { 
      _transferNftFrom(address(this), _msgSender(), currentlyActiveNFTWeapons[_msgSender()]);
      _transferNftFrom(address(this), _msgSender(), currentlyActiveNFTPerks[_msgSender()]);
    }
  }

  function _setNFTPerks(uint256[] calldata _nftIds) private { 
    require(_nftIds.length <= gameEngine.maximumActiveNFTPerks() && _nftIds.length >= 0, "Exceeded NFT perks amount");

    _deactivateNFTPerksAndTransfer(_msgSender());

    if(_nftIds.length == 0) return;

   _transferNftFrom(_msgSender(), address(this), _nftIds);

    _applyPerksNFTBatch(_nftIds, _msgSender());
  }

  function _setNFTWeapons(uint256[] calldata _nftIds) private { 
    require(_nftIds.length <= gameEngine.maximumActiveNFTWeapons() && _nftIds.length >= 0, "Exceeded NFT weapons amount");

    _deactivateNFTWeaponsAndTransfer(_msgSender());

    if(_nftIds.length == 0) return;

    _transferNftFrom(_msgSender(), address(this), _nftIds);

    _applyWeaponsNFTBatch(_nftIds, _msgSender());
  }

  function setTaxReceiverAddressFromSellingAssetsAddress(address taxReceiverAddressFromSellingAssets) external {
    onlyOwner();
    _taxReceiverAddressFromSellingAssets = taxReceiverAddressFromSellingAssets;
  }

  function buyAsset(uint8 assetType, uint256 assetIndex, uint8 _count) external {
    onlyCrimer();
    uint256 _cost_amount;
    (uint256 power, uint256 cost, bool hasLimit) = gameEngine.getAsset(assetType, assetIndex);
    if (hasLimit) {
      require(_count <= maxBuyLimit, "Count>maxBuy");
    }
    _cost_amount = cost.mul(uint256(_count));

    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());

    require(c.cash >= _cost_amount, "Not enough balance. You were looted during transaction.");

    if ( assetType == 1 ) {
      c.attack = c.attack.add(power.mul(uint256(_count)));
    }
    else if ( assetType == 2 ) {
      c.defense = c.defense.add(power.mul(uint256(_count)));
    }
    else if ( assetType == 3 ) {
      require(_isAlreadyHasBoost(_msgSender(), assetIndex) == false, "This boost already bought");

      c.boost = c.boost.add(power);

      if(c.boosts.length + 1 >= 8)
        c.boost = c.boost.add(allBoostBoughtBonus);
      
      crimerInfoStorage.setIsCrimerBoostExists(_msgSender(),assetIndex,true);
      crimerInfoStorage.crimerPushBoost(_msgSender(), assetIndex);
    }
    else if ( assetType == 4) {
      require(_crimerBoughtProtectionAtRoundDay(_msgSender(), roundDay) == false, "You already bougth protection this day");

      crimerInfoStorage.setIsCrimerBoughtProtectionAtRoundDay(_msgSender(),roundDay, true);
      c.protectedUntil = block.timestamp + power;
    }
    else { 
      revert("Invalid asset type");
    }

    c.cash = c.cash.sub(_cost_amount);
    crimerInfoStorage.setCrimer(_msgSender(), c);

    if(roundDay >= startCashMintAtRoundDay)
    {
      uint256 burnAmountToPool = _cost_amount.mul(cashMintAmountPercentage).div(100);      
      crimecashToken.transfer(_taxReceiverAddressFromSellingAssets, burnAmountToPool);
    }
    
    emit eventBuyAsset(_msgSender(), assetType, assetIndex, _count, _cost_amount, roundDay);
  }

  function isAlreadyHasBoost(address _crimer, uint256 _boost) external view returns(bool) {
    return _isAlreadyHasBoost(_crimer, _boost);
  }

  function stealCash(address _crimer) external {
    onlyCrimer();
    uint8 currentRoundDay = roundDay;
    Crimer memory cStealOf = crimerInfoStorage.getCrimer(_crimer);
    Crimer memory cSender = crimerInfoStorage.getCrimer(_msgSender());

    require(cStealOf.protectedUntil <= block.timestamp, "Crimer protected now");
    require(crimerInfoStorage.getStolenCount(currentRoundDay, _crimer, _msgSender()) 
              < maxStolenCountLimit, "Hit max stolen for this player");

    require(cStealOf.cash >= 100, "Crimer's cash not enough to steal");
    require(cSender.totalAttack() > cStealOf.totalDefense(), 
            "Your attack is less than or equals crimer's defense");

    uint256 stolenRate = _random(_msgSender(), _crimer, maxLimit, minLimit, block.timestamp, block.difficulty, address(this));
    uint256 stolenCash = cStealOf.cash.mul(stolenRate).div(100);
    cStealOf.cash = cStealOf.cash.sub(stolenCash);
    crimerInfoStorage.incrementStolenCount(currentRoundDay, _crimer, _msgSender());
    cSender.cash = cSender.cash.add(stolenCash);

    crimerInfoStorage.setCrimer(_crimer, cStealOf);
    crimerInfoStorage.setCrimer(_msgSender(), cSender);

    emit eventStealCash(_msgSender(), _crimer, stolenCash, stolenRate, roundDay);
  }

  function stakeCash(uint256 _poolIndex, uint256 _amount) external {
    onlyCrimer();
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());

    require(c.bank >= _amount, "Not enough balance for staking");
    
    c.bank = c.bank.sub(_amount);    

    crimerInfoStorage.setCrimer(_msgSender(), c);

    gameEngine.stakeCash(_poolIndex, _msgSender(), _amount);
    emit stakeCashToken(_poolIndex, address(_msgSender()), _amount, roundDay);
  }

  function claim(uint256 _poolIndex, uint8 _payout_mode) external {
    onlyCrimer();
    PoolInfoData memory infoData = gameEngine.getCurrentRoundPoolByIndex(_poolIndex);

    require(infoData.openDay <= roundDay, "Pool not open");
    require(gameEngine.playerStakedBalanceCurrentRound(_poolIndex, _msgSender())>0, "staked balance 0");
    
    Crimer memory c = crimerInfoStorage.getCrimer(_msgSender());

    uint256 _amount = gameEngine.getClaimAmount(_poolIndex, _msgSender(), c.totalClaimBoost());

    gameEngine.onCCashRewardClaim(_poolIndex, _msgSender());

    if ( _payout_mode == 1 ) {
      c.bank = c.bank.add(_amount);
    }
    else {
      _amount = _amount.mul(2);
      c.cash = c.cash.add(_amount);
    }

    crimerInfoStorage.setCrimer(_msgSender(), c);

    crimecashToken.mint(address(this), _amount.mul(10**2));
    emit eventClaim(_msgSender(), _poolIndex, _payout_mode, _amount, roundDay);
  }

  function crimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) external view returns (bool){ 
    return _crimerBoughtProtectionAtRoundDay(_crimer, _roundDay);
  }
  
  function _transferNftFrom(address _from, address _to, uint256[] memory _ids) private { 
    CrimERC1155(crimeMarketplace).safeBatchTransferFrom(_from,_to, _ids, _createFilledArray(_ids.length, 1), "");
  }

  
  function _deactivateNFTPerksAndTransfer(address _of) private  { 
    _transferNftFrom(address(this), _of,  currentlyActiveNFTPerks[_of]);
    _deactivateNFTPerks(_of, currentlyActiveNFTPerks[_of]);
    delete currentlyActiveNFTPerks[_of];
  }

  function _deactivateNFTWeaponsAndTransfer(address _of) private  { 
    _transferNftFrom(address(this), _of, currentlyActiveNFTWeapons[_of]);
    _deactivateNFTWeapons(_of, currentlyActiveNFTWeapons[_of]);
    delete currentlyActiveNFTWeapons[_of];
  }

  function _deactivateNFTWeapons(address _of, uint256[] memory _currentlyActiveNFTWeapons) private { 
    for (uint256 index = 0; index < _currentlyActiveNFTWeapons.length; index++) {
      uint256 _activeWeaponId = _currentlyActiveNFTWeapons[index];
      CrimeNFT memory nft = crimeMarketplace.getNftById(_activeWeaponId);
      _unapplyWeaponNFT(nft, _of);  
    }
  }

  function _deactivateNFTPerks(address _of, uint256[] memory _currentlyActiveNFTPerks) private { 
    for (uint256 index = 0; index < _currentlyActiveNFTPerks.length; index++) {
      uint256 _activePerkId = _currentlyActiveNFTPerks[index];
      CrimeNFT memory nft = crimeMarketplace.getNftById(_activePerkId);
      _unapplyPerkNFT(nft, _of);  
    }
  }

  function _applyWeaponsNFTBatch(uint256[] memory _nftIds, address _applyTo) private { 
    for (uint256 index = 0; index < _nftIds.length; index++) {
      uint256 _nftId = _nftIds[index];

      CrimeNFT memory nft = crimeMarketplace.getNftById(_nftId);
      
      require(nft.isPerk == false, "NFT is a perk");
      require(nft.weaponType != NFTWeaponType.NOT_A_VALUE, "NFT is not a weapon");

      _applyWeaponNFT(nft, _applyTo);  
    }
  }

  function _applyPerksNFTBatch(uint256[] memory _nftIds, address _applyTo) private { 
    for (uint256 index = 0; index < _nftIds.length; index++) {
      uint256 _nftId = _nftIds[index];

      CrimeNFT memory nft = crimeMarketplace.getNftById(_nftId);
      
      require(nft.isPerk, "NFT is not a perk");
      require(nft.perkType != NFTPerkType.NOT_A_VALUE, "NFT perk type is invalid");

      _applyPerkNFT(nft, _applyTo);  
    }
  }
  
  function _applyWeaponNFT(CrimeNFT memory _nft, address _applyTo) private { 
    currentlyActiveNFTWeapons[_applyTo].push(_nft.id);

    Crimer memory c = crimerInfoStorage.getCrimer(_applyTo);

    if(_nft.weaponType == NFTWeaponType.Attack) {
      c.attack = c.attack.add(_nft.power);
    }
    else { 
      c.defense = c.defense.add(_nft.power);
    }

    crimerInfoStorage.setCrimer(_applyTo, c);
  }

  function _applyPerkNFT(CrimeNFT memory _nft, address _applyTo) private { 
    currentlyActiveNFTPerks[_applyTo].push(_nft.id);

    Crimer memory c = crimerInfoStorage.getCrimer(_applyTo);

    if (_nft.perkType == NFTPerkType.Attack) {
      c.nftPerkAttackBoost = c.nftPerkAttackBoost.add(_nft.power);
    }else if(_nft.perkType == NFTPerkType.Defense) { 
      c.nftPerkDefenseBoost = c.nftPerkDefenseBoost.add(_nft.power);
    }else if(_nft.perkType == NFTPerkType.Stake) { 
      c.nftPerkStakeBoost = c.nftPerkStakeBoost.add(_nft.power);
    } else {
      c.nftPerkPowerBoost = c.nftPerkPowerBoost.add(_nft.power);
    }

    crimerInfoStorage.setCrimer(_applyTo, c);
  }

  function _unapplyWeaponNFT(CrimeNFT memory _nft, address _applyTo) private { 
    Crimer memory c = crimerInfoStorage.getCrimer(_applyTo);

    if(_nft.weaponType == NFTWeaponType.Attack) {
      c.attack = c.attack.sub(_nft.power);
    }
    else { 
      c.defense = c.defense.sub(_nft.power);
    }

    crimerInfoStorage.setCrimer(_applyTo, c);
  }

  function _unapplyPerkNFT(CrimeNFT memory _nft, address _applyTo) private { 
    Crimer memory c = crimerInfoStorage.getCrimer(_applyTo);

    if (_nft.perkType == NFTPerkType.Attack) {
      c.nftPerkAttackBoost = c.nftPerkAttackBoost.sub(_nft.power);
    }else if(_nft.perkType == NFTPerkType.Defense) { 
      c.nftPerkDefenseBoost = c.nftPerkDefenseBoost.sub(_nft.power);
    }else if(_nft.perkType == NFTPerkType.Stake) { 
      c.nftPerkStakeBoost = c.nftPerkStakeBoost.sub(_nft.power);
    } else {
      c.nftPerkPowerBoost = c.nftPerkPowerBoost.sub(_nft.power);
    }

    crimerInfoStorage.setCrimer(_applyTo, c);
  }

  function _crimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) private view returns (bool){ 
    return crimerInfoStorage.getIsCrimerBoughtProtectionAtRoundDay(_crimer, _roundDay);
  }

  function _isAlreadyHasBoost(address _crimer, uint256 _boost) private view returns(bool) {
    return crimerInfoStorage.getIsCrimerBoostExists(_crimer, _boost);
  }

  function _createFilledArray(uint256 _size, uint256 _value) private pure returns (uint256[] memory arr) {
    arr = new uint256[](_size);
    for (uint256 i = 0; i < _size; i++) arr[i] = _value;
  }

  function _random(address stealer, address crimer, uint256 maxStealLimit, uint256 minStealLimit, uint256 bnow, uint256 bdifficulty, address thisAddress) private pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(bnow, bdifficulty, stealer, crimer, thisAddress))).mod(maxStealLimit.sub(minStealLimit))+minStealLimit;
  }

  function roundOpened() private view {
    require(isRoundOpening == true, "not opened round");
  } 

  function onlyCrimer() private view {
    require(
      !store.governance(_msgSender()) && 
      !store.controller(_msgSender()), 
      "owner/controller not allowed"
    );
    roundOpened();
  }
  function onlyGameEngine() private view {
    require(_msgSender() == address(gameEngine), "Sender is not a gameEngine");
  }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./CrimERC1155.sol";
import "../Types/CrimeNFT.sol";
import "../libraries/SafeMath.sol";
import "../libraries/RandomLibrary.sol";
import "../Types/NFTWeaponType.sol";
import "../Types/NFTPerkType.sol";
import "../CrimeGold.sol";
import "../CrimeCashGame.sol";
import "../Uniswap/IUniswapV2Pair.sol";
import "../Uniswap/IUniswapV2Router01.sol";
import "../Uniswap/IUniswapV2Factory.sol";

contract CrimeMarketplace is CrimERC1155 {
    using SafeMath for uint256;

    event RollRandomItem(address indexed winnerAddres,uint256 indexed weaponId);
    event ItemCreated(uint256 indexed weaponId);
    event MintNFTAssetToAddressById(uint256 indexed _idNft, address indexed _mintTo);
    

    // roundNumber => roundDay => rollsMade
    mapping(uint16 => mapping(uint8 => uint256)) public rollsAtDay;

    uint256 public randomWeaponRollCost;
    uint256 public randomPerkRollCost;

    uint256 private _nonce;
    uint256 private _totalAttackWeaponsChanceWeight;
    uint256 private _totalDefenseWeaponsChanceWeight;

    uint256 private _totalPerksChanceWeight;

    uint256[] private _weaponAttackNftIds;
    uint256[] private _weaponDefenseNftIds;
    uint256[] private _perkNftIds; 

    uint256 public immutable minGoldTokenEmissionPercentageToRoll;

    bool public isDefaultAssetsAdded;

    uint256 public maximumRollsPerDay = 250;
    
    NFTPerkType private _emptyPerkTypeStruct;

    NFTWeaponType private _emptyWeaponTypeStruct;

    IUniswapV2Router01  private _router;

    CrimeGold immutable private _cgold;

    CrimeCashGame immutable private crimeCashGame;
    

    function _transferCGoldPercent(uint256 priceInPercents) private {
        require(_getCgoldReserve() > 0, "Not enough liquidity");
        _cgold.transferFrom(_msgSender(), address(this), getPriceOfCgoldSupply(priceInPercents));
    }

    constructor(
        uint256 _randomWeaponRollCost, 
        uint256 _randomPerkRollCost,
        uint256 _minGoldTokenEmissionPercentageToRoll,
        IUniswapV2Router01 router,
        CrimeGold cgold,
        CrimeCashGame _crimeCashGame,
        Storage _store
    ) 
        public 
        CrimERC1155("CrimeCash NFT Marketplace", _store) 
    {
        randomWeaponRollCost = _randomWeaponRollCost;
        randomPerkRollCost = _randomPerkRollCost;
        _router = router;
        _cgold = cgold;
        crimeCashGame = _crimeCashGame;

        minGoldTokenEmissionPercentageToRoll = _minGoldTokenEmissionPercentageToRoll;
    }

    function setMaximumRollsPerDay(uint256 _rollsPerDay) external { 
        onlyGovernance();
        require(_rollsPerDay != 0, "Invalid RollsPerDay value");

        maximumRollsPerDay = _rollsPerDay;
    }

    function _getCgoldReserve() private view returns (uint256 reserve) {
        IUniswapV2Factory factory = IUniswapV2Factory(_router.factory());
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(_cgold), _router.WETH()));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        if (address(pair.token1()) == address(_cgold)) {
            reserve0 = reserve1;
        }
        return reserve0;
    }

    function getPriceOfCgoldSupply(uint256 percent) public view returns (uint256 price) {
        price = _getCgoldReserve().mul(percent).div(1000);
    }

    function getNftById(uint256 _id) external view returns(CrimeNFT memory) {
        require(_id < nfts.length, "Invalid NFT id");
        return nfts[_id];
    }

    function addDefaultAssets() external {
        onlyGovernance();
        require(!isDefaultAssetsAdded, "Default assets are already added");
        isDefaultAssetsAdded = true;
        uint256 id = nfts.length;

        // Weapons
        // Attack
        _addAsset(
            id, 
            "Knife", 
            "Knife", 
            "images/nft-0.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            300, 
            0
        );

        _addAsset(
            id + 1, 
            "Desert Eagle", 
            "Desert Eagle", 
            "images/nft-1.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            660, 
            0
        );

        _addAsset(
            id + 2, 
            "Colt M911", 
            "Colt M911", 
            "images/nft-2.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            1386, 
            20
        );

        _addAsset(
            id + 3, 
            "Revolver", 
            "Revolver", 
            "images/nft-3.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            3049, 
            15
        );

        _addAsset(
            id + 4, 
            "Uzi", 
            "Uzi", 
            "images/nft-4.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            6403, 
            12
        );

        _addAsset(
            id + 5, 
            "Shotgun", 
            "Shotgun", 
            "images/nft-5.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            14087, 
            10
        );

        _addAsset(
            id + 6, 
            "MP5k", 
            "MP5k", 
            "images/nft-6.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            29583, 
            8
        );

        _addAsset(
            id + 7, 
            "G36C", 
            "G36C", 
            "images/nft-7.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            65083, 
            7
        );

        _addAsset(
            id + 8, 
            "AK47", 
            "AK47", 
            "images/nft-8.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            136675, 
            7
        );

        _addAsset(
            id + 9, 
            "Sig Sauer MCX", 
            "Sig Sauer MCX", 
            "images/nft-9.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            300685, 
            6
        );

        _addAsset(
            id + 10, 
            "Beretta CX4 Storm", 
            "Beretta CX4 Storm", 
            "images/nft-10.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            661507, 
            5
        );

        _addAsset(
            id + 11, 
            "Bazooka", 
            "Bazooka", 
            "images/nft-11.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            1389165, 
            4
        );

        _addAsset(
            id + 12, 
            "Armed Jeep", 
            "Armed Jeep", 
            "images/nft-12.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            3056163, 
            3
        );

        _addAsset(
            id + 13, 
            "Attack Drone", 
            "Attack Drone", 
            "images/nft-13.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            6417942, 
            2
        );

        _addAsset(
            id + 14, 
            "Tank", 
            "Tank", 
            "images/nft-14.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Attack, 
            14119472, 
            1
        );

        // Defense
        _addAsset(
            id + 15, 
            "Pepperspray", 
            "Pepperspray", 
            "images/nft-15.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            250, 
            0
        );

        _addAsset(
            id + 16, 
            "Night Vision", 
            "Night Vision", 
            "images/nft-16.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            660, 
            0
        );

        _addAsset(
            id + 17, 
            "Bulletproof Vest", 
            "Bulletproof Vest", 
            "images/nft-17.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            1155, 
            20
        );

        _addAsset(
            id + 18, 
            "Flashbang", 
            "Flashbang", 
            "images/nft-18.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            2541, 
            15
        );

        _addAsset(
            id + 19, 
            "UAV Recon", 
            "UAV Recon", 
            "images/nft-19.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            5336, 
            12
        );

        _addAsset(
            id + 20, 
            "Claymore", 
            "Claymore", 
            "images/nft-20.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            11739, 
            10
        );

        _addAsset(
            id + 21, 
            "3 Bodyguards", 
            "3 Bodyguards", 
            "images/nft-6.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            24653, 
            8
        );

        _addAsset(
            id + 22, 
            "Spot (Boston Dynamics)", 
            "Spot (Boston Dynamics)", 
            "images/nft-22.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            54236, 
            7
        );

        _addAsset(
            id + 23, 
            "2 Rooftop snipers", 
            "2 Rooftop snipers", 
            "images/nft-23.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            113896, 
            7
        );

        _addAsset(
            id + 24, 
            "Underground bunker", 
            "Underground bunker", 
            "images/nft-24.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            250571, 
            6
        );

        _addAsset(
            id + 25, 
            "Weaponized Defense Drone", 
            "Weaponized Defense Drone", 
            "images/nft-25.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            551256, 
            5
        );

        _addAsset(
            id + 26, 
            "EMP Drone", 
            "EMP Drone", 
            "images/nft-26.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            1157637, 
            4
        );

        _addAsset(
            id + 27, 
            "Private Encrypted Satellite", 
            "Private Encrypted Satellite", 
            "images/nft-28.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            2546802, 
            3
        );

        _addAsset(
            id + 28, 
            "MQ-9 Reaper", 
            "MQ-9 Reaper", 
            "images/nft-28.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            5348285, 
            2
        );

        _addAsset(
            id + 29, 
            "US Government Protection", 
            "US Government Protection", 
            "images/nft-29.png", 
            false, 
            NFTPerkType.NOT_A_VALUE,
            NFTWeaponType.Defense, 
            11766227, 
            1
        );

        // Perks
        // Farming
        _addAsset(
            id + 30,
            "Farming 3%",
            "Farming 3%",
            "images/nft-30.png",
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            3,
            1250
        );

        _addAsset(
            id + 31,
            "Farming 5%",
            "Farming 5%",
            "images/nft-31.png", 
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            5,
            625
        );

        _addAsset(
            id + 32,
            "Farming 10%",
            "Farming 10%",
            "images/nft-32.png", 
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            10,
            375
        );

        _addAsset(
            id + 33,
            "Farming 20%",
            "Farming 20%",
            "images/nft-33.png", 
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            20,
            250
        );

        _addAsset(
            id + 34,
            "Farming 50%",
            "Farming 50%",
            "images/nft-34.png", 
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            50,
            100
        );

        _addAsset(
            id + 35,
            "DOUBLE FARMING 100%",
            "DOUBLE FARMING 100%",
            "images/nft-35.png", 
            true,
            NFTPerkType.Stake,
            NFTWeaponType.NOT_A_VALUE,
            100,
            25
        );

        // Attack
        _addAsset(
            id + 36,
            "Attack 1%",
            "Attack 1%",
            "images/nft-36.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            1,
            1500
        );

        _addAsset(
            id + 37,
            "Attack 2%",
            "Attack 2%",
            "images/nft-37.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            2,
            750
        );

        _addAsset(
            id + 38,
            "Attack 3%",
            "Attack 3%",
            "images/nft-38.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            3,
            450
        );

        _addAsset(
            id + 39,
            "Attack 4%",
            "Attack 4%",
            "images/nft-39.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            4,
            300
        );

        _addAsset(
            id + 40,
            "Attack 5%",
            "Attack 5%",
            "images/nft-40.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            5,
            120
        );

        _addAsset(
            id + 41,
            "Attack 10%",
            "Attack 10%",
            "images/nft-41.png", 
            true,
            NFTPerkType.Attack,
            NFTWeaponType.NOT_A_VALUE,
            10,
            30
        );

        // Defense
        _addAsset(
            id + 42,
            "Defense 1%",
            "Defense 1%",
            "images/nft-42.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            1,
            1500
        );

        _addAsset(
            id + 43,
            "Defense 2%",
            "Defense 2%",
            "images/nft-43.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            2,
            750
        );

        _addAsset(
            id + 44,
            "Defense 3%",
            "Defense 3%",
            "images/nft-44.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            3,
            450
        );

        _addAsset(
            id + 45,
            "Defense 4%",
            "Defense 4%",
            "images/nft-45.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            4,
            300
        );

        _addAsset(
            id + 46,
            "Defense 5%",
            "Defense 5%",
            "images/nft-46.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            5,
            120
        );

        _addAsset(
            id + 47,
            "Defense 10%",
            "Defense 10%",
            "images/nft-47.png", 
            true,
            NFTPerkType.Defense,
            NFTWeaponType.NOT_A_VALUE,
            10,
            30
        );

        // Total power
        _addAsset(
            id + 48,
            "Total power 1%",
            "Total power 1%",
           "images/nft-48.png", 
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            1,
            1500
        );

        _addAsset(
            id + 49,
            "Total power 2%",
            "Total power 2%",
           "images/nft-49.png", 
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            2,
            750
        );

        _addAsset(
            id + 50,
            "Total power 3%",
            "Total power 3%",
            "images/nft-50.png", 
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            3,
            450
        );

        _addAsset(
            id + 51,
            "Total power 4%",
            "Total power 4%",
            "images/nft-51.png",
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            4,
            300
        );

        _addAsset(
            id + 52,
            "Total power 5%",
            "Total power 5%",
            "images/nft-52.png", 
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            5,
            120
        );

        _addAsset(
            id + 53,
            "Total power 10%",
            "Total power 10%",
            "images/nft-53.png", 
            true,
            NFTPerkType.TotalPower,
            NFTWeaponType.NOT_A_VALUE,
            10,
            30
        );
    }

    function addPerk(
        string  calldata _name, 
        string  calldata _description,
        string  calldata _imageUrl,
        NFTPerkType _type,
        uint256 _power,
        uint256 _chanceWeight
    )
        external 
    {
        onlyGovernance();
        require(isDefaultAssetsAdded, "To add nft`s add default assets first");
        require(_type != NFTPerkType.NOT_A_VALUE, "Invalid perk type");
        require(_chanceWeight > 0,  "Chance weight must be > 0");

        uint256 weaponId = nfts.length;

        _addAsset(
            weaponId,
            _name, 
            _description, 
            _imageUrl, 
            true, 
            _type, 
            NFTWeaponType.NOT_A_VALUE, 
            _power, 
            _chanceWeight
        );

        emit ItemCreated(weaponId);
    } 

    function _addAsset(
        uint256 id,
        string memory name,
        string memory description,
        string memory image,
        bool isPerk,
        NFTPerkType perkType,
        NFTWeaponType weaponType,
        uint256 power,
        uint256 chanceWeight
    ) private {
        nfts.push(
            CrimeNFT({
                id: id, 
                name: name,
                description : description,
                image: image,
                isPerk: isPerk, 
                perkType: perkType, 
                weaponType: weaponType,
                power: power,
                from: isPerk 
                    ? _totalPerksChanceWeight 
                    : weaponType == NFTWeaponType.Attack 
                        ? _totalAttackWeaponsChanceWeight 
                        : _totalDefenseWeaponsChanceWeight,
                to: isPerk
                    ? _totalPerksChanceWeight.add(chanceWeight)
                    : weaponType == NFTWeaponType.Attack
                        ? _totalAttackWeaponsChanceWeight.add(chanceWeight)
                        : _totalDefenseWeaponsChanceWeight.add(chanceWeight)
            })
        );

        if (isPerk) { // if perk
            _totalPerksChanceWeight = _totalPerksChanceWeight.add(chanceWeight);
            _perkNftIds.push(id);
        } else if (weaponType == NFTWeaponType.Attack) { // if attack weapon
            _totalAttackWeaponsChanceWeight = _totalAttackWeaponsChanceWeight.add(chanceWeight);
            _weaponAttackNftIds.push(id);
        } else { // if defense weapon
            _totalDefenseWeaponsChanceWeight = _totalDefenseWeaponsChanceWeight.add(chanceWeight);
            _weaponDefenseNftIds.push(id);
        }
    }

    function addWeapon(
        string  calldata _name, 
        string  calldata _description,
        string  calldata _imageUrl,
        NFTWeaponType _type,
        uint256 _power,
        uint256 _chanceWeight
    )
        external 
    {
        onlyGovernance();
        require(isDefaultAssetsAdded, "To add nft`s add default assets first");
        require(_type != NFTWeaponType.NOT_A_VALUE, "Invalid weapon type");
        require(_chanceWeight > 0,  "Chance weight must be > 0");

        uint256 weaponId = nfts.length;

        _addAsset(
            weaponId,
            _name, 
            _description, 
            _imageUrl, 
            false, 
            NFTPerkType.NOT_A_VALUE, 
            _type, 
            _power, 
            _chanceWeight
        );

        emit ItemCreated(weaponId);
    }

    function rollRandomPerk() 
        external
        returns (uint256 winnerItemId) 
    {
        _transferCGoldPercent(10);
        _beforeItemRoll();
        require(_perkNftIds.length > 0, "No perks to roll");

        winnerItemId = _rollRandomItem(_msgSender(), _perkNftIds,_totalPerksChanceWeight);
        emit RollRandomItem(_msgSender(), winnerItemId);
    }

    function rollRandomWeapon() 
        external
        returns (uint256 winnerItemId)
    {
        _transferCGoldPercent(1);
        _beforeItemRoll();

        require(_weaponAttackNftIds.length > 0 || _weaponDefenseNftIds.length > 0 , "No weapons to roll");

        // 50% of rolling attack and 50% of rolling defense
        bool rollAttack =  RandomLibrary.random(_nonce, 2) == 1;

        winnerItemId = rollAttack ? 
                _rollRandomItem(_msgSender(), _weaponAttackNftIds,_totalAttackWeaponsChanceWeight) : 
                _rollRandomItem(_msgSender(), _weaponDefenseNftIds,_totalDefenseWeaponsChanceWeight);
        
        emit RollRandomItem(_msgSender(), winnerItemId);
    }
    
    function _rollRandomItem(address _mintTo, uint256[] storage _participatingIds, uint256 _participatingNftsTotalChanceWeight) private returns (uint256 _winnerItemId){
        _winnerItemId =  RandomLibrary.getRandomAsset(nfts, _participatingIds, _participatingNftsTotalChanceWeight, _nonce);
        _incrementNonce();
        _mint(_mintTo, _winnerItemId, 1, "");
    } 

    function _beforeItemRoll() private { 
        require(crimeCashGame.isRoundOpening(), "CrimeMarketplace: Round is not opened");
        uint16 roundNumber = crimeCashGame.roundNumber();
        uint8 roundDay = crimeCashGame.roundDay();

        require(rollsAtDay[roundNumber][roundDay] < maximumRollsPerDay, "CrimeMarketplace: Exceeded rolls for current day");
        rollsAtDay[roundNumber][roundDay] = rollsAtDay[roundNumber][roundDay].add(1);
    }   
    
    function _incrementNonce() private { 
        if(_nonce == RandomLibrary.MAX_UINT) _nonce = 0;
        _nonce = _nonce.add(1);  
    }

    function mintNFTAssetToAddressById(uint256 _idNft, address _mintTo) external {
        onlyGovernance();
        require(_idNft >= 0 && _idNft < nfts.length, "Invalid NFT id");
        _mint(_mintTo, _idNft, 1, "");
        emit MintNFTAssetToAddressById(_idNft, _mintTo);
    }
}

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.12;
import "./SafeMath.sol";
import "./Address.sol";
import "../ERC20/IERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        //(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        (bool success, bytes memory returndata) = target.call{value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.6.12;
import "./Storage.sol";
import "./Context.sol";

// File: contracts/Governable.sol

contract Governable is Context {

  Storage public store;

  constructor(Storage _store) public {
    require(address(_store) != address(0), "new storage shouldn't be empty");
    store = _store;
  }

  function onlyOwner() internal view{
    require(store.owner() == _msgSender(), "Not the owner");
  }

  function onlyGovernance() internal view{
    require(store.governance(_msgSender()), "Not governance");
  }

  function onlyController() internal view{
    require(store.controller(_msgSender()), "Not controller");
  }

  function onlyGovernaneOrController() internal view{
    require(store.controller(_msgSender()) || store.governance(_msgSender()) , "Not a owner/controller");
  }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./Governable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Address.sol";
import "./CrimeGold.sol";
import "./CrimerInfo.sol";
import "./factories/CrimeCashFactory.sol";
import "./factories/CrimerInfoFactory.sol";

struct PoolInfoData { 
  bool isCrimeCash;                    // is crimecash contract?

  IERC20 lpToken;                      // lptoken contract
  uint256 totalStaked;                 // total staked lp token amount
  uint256 stakers;                     // total staker count
  uint8   openDay;

  uint256[30] defaultApyRates;
  uint256[30] apyRates;

  bool exists;        
}

contract CrimeCashGame is Governable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Address for address;

  struct PoolInfo {
    PoolInfoData infoData;
    
    mapping(address=>bool) isStakerExists;
    mapping(address=>uint256) balances;  // each user's staked amount
    
    mapping(address=>uint256) lockedTokens;
    mapping(address=>uint8) lockedTokensRoundDay;
    uint256 totalStakedRoundDay;         // total staked lp token in specific round
    uint8 StakeLPRoundDay;

    mapping(address=> uint256) userConnectDay;
    mapping(uint8 => mapping(address => bool)) isRewardClaimedAtDay;
  } 

  uint16 public roundNumber;

  mapping(uint16 => PoolInfo[]) private pools;
  mapping(address => uint256) public cgoldRewards;

  CrimeGold private immutable crimegoldToken;
  CrimerInfoStorageFactory public crimerInfoStorageFactory;
  CrimeCashFactory public crimeCashFactory;
  CrimerInfo public crimerInfo;
  
  struct Asset {
    uint256 power;
    uint256 cost;
    bool hasLimit;
  }

  mapping(uint256=>Asset) Attack;
  mapping(uint256=>Asset) Defense;
  mapping(uint256=>Asset) Boost;
  mapping(uint256=>Asset) Protect;

  uint8 public roundDay;

  uint256 public roundStartTimestamp;

  bool    public isDefaultAssetsAdded;

  bool    public isRoundOpening;
  bool    public isRoundFinished;

  uint256 public goldRewardForCrimer = 970 * 1e18;
  
  uint256 public constant maximumActiveNFTWeapons = 5;
  uint256 public constant maximumActiveNFTPerks = 3;

  uint256[] private topPowerRewards = [
      1250, 750, 500, 200, 125, 100, 100,
      75, 75, 75, 50, 50, 50, 50, 50, 50,
      50, 50, 50, 50, 50, 50, 50, 50, 50,
      30, 30, 30, 30, 30, 30, 30, 30, 30,
      30, 30, 30, 30, 30, 30, 10, 10, 10, 
      10, 10, 10, 10, 10, 10, 10
  ];

  uint256[] private topCashRewards = [
      1000, 500, 300, 125, 100, 100, 100,
      75, 75, 75, 50, 50, 50, 50, 50, 50, 
      50, 50, 50, 50, 50, 50, 50, 50, 50, 
      30, 30, 30, 30, 30, 30, 30, 30, 30, 
      30, 30, 30, 30, 30, 30, 10, 10, 10, 
      10, 10, 10, 10, 10, 10, 10
  ];

  uint256[] private topReferralsRewards = [
      500, 250, 120, 80, 50, 30, 30, 30,
      30, 30, 20, 20, 20, 20, 20, 20, 20, 
      20, 20, 20, 10, 10, 10, 10, 10 
  ];

  uint256[30] private _defaultCrimCashPoolApyRates =
    [
      250, 250, 200, 150, 100, 75,
      50, 50, 25, 25, 25, 10, 10,
      10, 5, 5, 5, 5, 5, 5, 5, 5,
      5, 3, 3, 3, 3, 1, 1, 1
    ];
  uint256[30] private _defaultLpPoolApyRates = 
    [
      0, 0, 100_000_00, 250_000_00, 500_000_00, 750_000_00, 
      1_000_000_00, 1_250_000_00, 1_500_000_00, 1_750_000_00, 2_000_000_00, 
      2_250_000_00, 2_500_000_00, 2_750_000_00, 3_000_000_00, 3_500_000_00, 
      4_000_000_00, 4_500_000_00, 5_000_000_00, 6_000_000_00, 7_000_000_00, 
      8_000_000_00, 9_000_000_00, 10_000_000_00, 12_000_000_00, 14_000_000_00, 
      16_000_000_00, 18_000_000_00, 25_000_000_00, 25_000_000_00
    ];
  
  event eventStartRound(uint256 goldRewardForCrimer, uint8 roundDay, uint256 roundStartTimestamp, address newCrimerInfoStorage,address newCrimeCash, uint16 roundNumber);
  event eventUpdatedAsset(uint8 assetType, uint256 assetIndex, uint256 assetValue, uint256 assetCost);
  event eventDeletedAsset(uint8 assetType, uint256 assetIndex);
  event addNewPool(address tokenAddress);
  event removePool(uint256 poolIndex);
  
  event eventUpdateRoundDay(uint8 roundDay);
  event stakeLpToken(uint16 roundNumber, uint8 roundDay,uint256 poolIndex, address crimer, uint256 amount);
  event unstakeLpToken(uint16 roundNumber,uint8 roundDay, uint256 poolIndex, address crimer, uint256 amount);
  
  event eventGoldRewardClaimed(address crimer, uint256 amount);
  event eventFinishRound();

  constructor(CrimeGold _crimegold, CrimeCashFactory _crimeCashFactory, Storage _store) public Governable(_store) {
    require(address(_crimegold) != address(0), "Invalid CrimeGold address");
    require(address(_crimeCashFactory) != address(0), "Invalid CrimeCashFactory address");
    require(address(_store) != address(0), "Invalid Store address");

    crimeCashFactory = _crimeCashFactory;
    crimegoldToken = _crimegold;
  }

  function setCrimerInfoAddress(CrimerInfo _crimerInfo, CrimerInfoStorageFactory _crimerInfoStorageFactory) external {
    onlyGovernance();
    require(address(_crimerInfoStorageFactory) != address(0), "Invalid CrimerInfoStorageFactory address");
    require(address(_crimerInfo) != address(0), "Invalid CrimerInfo address");

    crimerInfoStorageFactory = _crimerInfoStorageFactory;
    crimerInfo = _crimerInfo;
  }

  function setGoldRewardForCrimers(uint256 _goldAmount) external {
    onlyGovernance();
    require(isRoundOpening == false, "Error: There is an opened round currently");
    goldRewardForCrimer = _goldAmount;
  }
  
  function addAsset(uint8 _type, uint256 _index, uint256 _value, uint256 _cost, bool _hasLimit) external {
    onlyGovernance();
    require(isRoundOpening == false, "Error: There is not an opened round currently");
    _addAsset(_type, _index, _value, _cost, _hasLimit);
  }

  function _addAsset(uint8 _type, uint256 _index, uint256 _value, uint256 _cost, bool _hasLimit) private {
    if ( _type == 1 ) Attack[_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
    if ( _type == 2 ) Defense[_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
    if ( _type == 3 ) Boost[_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
    if ( _type == 4 ) Protect[_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
    emit eventUpdatedAsset(_type, _index, _value, _cost);
  }

  function removeAsset(uint8 _type, uint256 _index) external {
    onlyGovernance();
    require(isRoundOpening == false, "Error: There is not an opened round currently");
    if ( _type == 1 ) delete Attack[_index];
    if ( _type == 2 ) delete Defense[_index];
    if ( _type == 3 ) delete Boost[_index];
    if ( _type == 4 ) delete Protect[_index];
    emit eventDeletedAsset(_type, _index);
  }
  function getAsset(uint8 _type, uint256 _index) external view returns(uint256 power, uint256 cost, bool hasLimit) {
    if ( _type == 1 ) { power = Attack[_index].power;  cost = Attack[_index].cost;  hasLimit = Attack[_index].hasLimit; }
    if ( _type == 2 ) { power = Defense[_index].power;  cost = Defense[_index].cost;  hasLimit = Defense[_index].hasLimit; }
    if ( _type == 3 ) { power = Boost[_index].power;  cost = Boost[_index].cost;  hasLimit = Boost[_index].hasLimit; }
    if ( _type == 4 ) { power = Protect[_index].power;  cost = Protect[_index].cost;  hasLimit = Protect[_index].hasLimit; }
  }
  
  /******************* pool-related functions start *******************/
  function addPool(bool isCrimeCash, address _lpToken, uint8 _openDay) external {
    onlyGovernance();
    _addPool(isCrimeCash, _lpToken, _openDay);
  }

  function setApyRate(uint256 _poolIndex, uint256[30] calldata _rates) external {
    onlyGovernance();
    _setApyRate(_poolIndex, _rates);
  }

  function ChangeFinalRewardForUsers(uint8 indexTypeReward, uint256[] calldata newRewardArray) external {
    require(!isRoundOpening, "Error: There is an opened round currently");
    onlyGovernance();

    if(indexTypeReward == 1)
      topPowerRewards = newRewardArray;
    else if(indexTypeReward == 2)
      topCashRewards = newRewardArray;
    else if(indexTypeReward == 3)
      topReferralsRewards = newRewardArray;
  }
  
  function getAllPools(uint16 _roundNumber) external view returns(PoolInfoData[] memory poolInfos){ 
    poolInfos = new PoolInfoData[](pools[_roundNumber].length);

    for (uint256 i = 0; i < poolInfos.length; i++)
      poolInfos[i] = pools[_roundNumber][i].infoData;
  }

  function getPoolByIndex(uint16 _roundNumber, uint256 _poolIndex) 
      external 
      view 
      returns (
        PoolInfoData memory poolInfo
      ) 
  { 
    return _getPoolByIndex(_roundNumber, _poolIndex);
  }

  function getCurrentRoundPoolByIndex(uint256 _poolIndex) 
      external 
      view 
      returns (
        PoolInfoData memory poolInfo
      ) 
  { 
    return _getPoolByIndex(roundNumber, _poolIndex);
  }

  function _getPoolByIndex(uint16 _roundNumber, uint256 _poolIndex) 
      private 
      view 
      returns (
        PoolInfoData memory poolInfo
      ) 
  { 
    return pools[_roundNumber][_poolIndex].infoData;
  }

  function deletePool(uint256 _poolIndex) external {
    onlyGovernance();
    require(_poolIndex < pools[roundNumber].length, "Error: Invalid pool index");
    require( pools[roundNumber][_poolIndex].infoData.exists == true, "Error: This pool doesn't exist" );
    
    pools[roundNumber][_poolIndex].infoData.exists = false;

    emit removePool(_poolIndex);
  }
  function getPoolsLength(uint16 _roundNumber) external view returns (uint256 length) { 
    return pools[_roundNumber].length;
  }
  function playerStakedBalance(uint16 _roundNumber, uint256 _poolIndex, address _crimer) external view returns(uint256) {
    return _playerStakedBalance(_roundNumber, _poolIndex, _crimer);
  }
  function playerStakedBalanceCurrentRound(uint256 _poolIndex, address _crimer) external view returns(uint256) {
    return _playerStakedBalance(roundNumber, _poolIndex, _crimer);
  }
  function _playerStakedBalance(uint16 _roundNumber, uint256 _poolIndex, address _crimer) private view returns(uint256) {
    return pools[_roundNumber][_poolIndex].balances[_crimer];
  }
  /***************************** Farm page function start *****************************/
  function stakeLp(uint256 _poolIndex, uint256 _amount) external notOwner {
    require(pools[roundNumber][_poolIndex].infoData.isCrimeCash == false, "Error: Not allowed lp staking");
    _calculateRewardCurrentRoundDay(roundNumber, _poolIndex, _msgSender());
    pools[roundNumber][_poolIndex].infoData.lpToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
    pools[roundNumber][_poolIndex].infoData.totalStaked = pools[roundNumber][_poolIndex].infoData.totalStaked.add(_amount);
    pools[roundNumber][_poolIndex].balances[address(_msgSender())] = pools[roundNumber][_poolIndex].balances[address(_msgSender())].add(_amount);

    _onStakeUpdateInfo(roundNumber, _poolIndex, _msgSender(),_amount);

    emit stakeLpToken(roundNumber, roundDay, _poolIndex, address(_msgSender()), _amount);
  }
  function stakeCash(uint256 _poolIndex, address _crimer, uint256 _amount) external fromCrimerInfo {
    require(pools[roundNumber][_poolIndex].infoData.isCrimeCash == true, "Error: Not allowed cash staking");
    require(roundDay >= pools[roundNumber][_poolIndex].infoData.openDay, "Error: pool is not opened yet");
    _calculateRewardCurrentRoundDay(roundNumber, _poolIndex, _crimer);
    pools[roundNumber][_poolIndex].infoData.totalStaked = pools[roundNumber][_poolIndex].infoData.totalStaked.add(_amount);
    pools[roundNumber][_poolIndex].balances[address(_crimer)] = pools[roundNumber][_poolIndex].balances[address(_crimer)].add(_amount);

    _onStakeUpdateInfo(roundNumber,_poolIndex, _crimer, _amount);
  }
  function unstake(uint16 _roundNumber, uint256 _poolIndex, uint256 _amount) external notOwner {
    require(pools[_roundNumber][_poolIndex].infoData.isCrimeCash == false, "invalid unstaking");
    require(pools[_roundNumber][_poolIndex].balances[address(_msgSender())] >= _amount, "insufficient balance");  

    PoolInfo memory info = pools[_roundNumber][_poolIndex];

    info.infoData.totalStaked = info.infoData.totalStaked.sub(_amount);
    pools[_roundNumber][_poolIndex].balances[address(_msgSender())] = pools[_roundNumber][_poolIndex].balances[address(_msgSender())].sub(_amount);
    info.infoData.lpToken.safeTransfer(address(_msgSender()), _amount);
    pools[_roundNumber][_poolIndex] = info;
    
    if(pools[roundNumber][_poolIndex].lockedTokens[_msgSender()] >= _amount)
      pools[roundNumber][_poolIndex].lockedTokens[_msgSender()] = pools[roundNumber][_poolIndex].lockedTokens[_msgSender()].sub(_amount);

    _onUnstakeUpdateInfo(_roundNumber,_poolIndex, _msgSender());

    emit unstakeLpToken(_roundNumber,  _roundNumber == roundNumber ? roundDay : 0, _poolIndex, address(_msgSender()), _amount);
  }
   
  function onCCashRewardClaim(uint256 _poolIndex, address _of) external fromCrimerInfo { 
    require(pools[roundNumber][_poolIndex].isRewardClaimedAtDay[roundDay][_of] == false, "Error: reward is already claimed");
    _calculateRewardCurrentRoundDay(roundNumber, _poolIndex, _of);
    pools[roundNumber][_poolIndex].isRewardClaimedAtDay[roundDay][_of] = true;
  }

  function finishRound(Crimer[] memory topCrimersByPower, Crimer[] memory topCrimersByCash, Crimer[] memory topCrimersByReferrals) external {
    onlyGovernaneOrController();
    require(roundDay == 30, "Not enough time has passed");

    _distributeGold(topCrimersByPower, topPowerRewards);
    _distributeGold(topCrimersByCash, topCashRewards);
    _distributeGold(topCrimersByReferrals, topReferralsRewards);

    _finishRound();
  }

  function getTopCrimersGold() external view returns (
    uint256[] memory byPower, 
    uint256[] memory byCash,
    uint256[] memory byReferral
  ) { 
    return (topPowerRewards, topCashRewards, topReferralsRewards);
  }

  function getClaimAmount(uint256 _poolIndex, address _crimer, uint256 _boost) external view returns(uint256) {
    require(roundDay >= 1 && roundDay <= 30, "Error: Invalid round day");
    
    uint256 lockedTokensToday;

    if(roundDay == pools[roundNumber][_poolIndex].lockedTokensRoundDay[_crimer])
      lockedTokensToday = pools[roundNumber][_poolIndex].lockedTokens[_crimer];

    if( roundDay == pools[roundNumber][_poolIndex].userConnectDay[_crimer] || 
        pools[roundNumber][_poolIndex].isRewardClaimedAtDay[roundDay][_crimer] == true || 
        pools[roundNumber][_poolIndex].balances[_crimer] == 0 || 
        lockedTokensToday >= pools[roundNumber][_poolIndex].balances[_crimer] ||
        pools[roundNumber][_poolIndex].infoData.totalStaked == 0) return 0;


    uint256 claimBalance = 0;
    
    PoolInfo storage pool = pools[roundNumber][_poolIndex];

    if (pool.infoData.isCrimeCash ) {
      claimBalance = pools[roundNumber][_poolIndex].balances[_crimer].sub(lockedTokensToday).mul(pools[roundNumber][_poolIndex].infoData.defaultApyRates[roundDay-1]).div(100);
    }
    else {
      uint256 totalStakedToday;
      if(roundDay == pools[roundNumber][_poolIndex].StakeLPRoundDay)
        totalStakedToday = pools[roundNumber][_poolIndex].totalStakedRoundDay;
      uint256 totalReward = pools[roundNumber][_poolIndex].infoData.apyRates[roundDay-1];
      uint256 stakers = pool.infoData.stakers;
      uint256 balance = pools[roundNumber][_poolIndex].balances[_crimer];
      uint256 liquid_share_rate = balance.sub(lockedTokensToday).mul(100_0000).div(pool.infoData.totalStaked.sub(totalStakedToday));
      uint256 reward = totalReward.mul(liquid_share_rate).div(100_0000);
      uint256 burnable_rate = 0;
      if (stakers >= 10000 ) {
        if ( liquid_share_rate >= 500000 ) {
          burnable_rate = 95;
        }
        else if ( liquid_share_rate >= 300000 ) {
          burnable_rate = 90;
        }
        else if ( liquid_share_rate >= 100000 ) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 50000 ) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if (stakers >= 1000 ) {
        if ( liquid_share_rate >= 500000 ) {
          burnable_rate = 90;
        }
        else if ( liquid_share_rate >= 300000 ) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 100000 ) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if (stakers >= 100 ) {
        if ( liquid_share_rate >= 500000) {
          burnable_rate = 80;
        }
        else if ( liquid_share_rate >= 300000 ) {
          burnable_rate = 50;
        }
        else if ( liquid_share_rate >= 100000 ) {
          burnable_rate = 20;
        }
        else {
          burnable_rate = 0;
        }
      }
      else {
        burnable_rate = 0;
      }
      claimBalance = reward.sub(reward.mul(burnable_rate).div(100));
    }
    claimBalance = claimBalance.add(claimBalance.mul(_boost).div(100));
    return claimBalance;
  }

  function claimCgoldReward() external { 
    require(cgoldRewards[_msgSender()] != 0, "No rewards available");
    require(crimegoldToken.balanceOf(address(this)) >= cgoldRewards[_msgSender()], "CrimeCashGame insufficient balance");
    uint256 rewardToClaim = cgoldRewards[_msgSender()];
    cgoldRewards[_msgSender()] = 0;
    crimegoldToken.transfer(_msgSender(), rewardToClaim);
    emit eventGoldRewardClaimed(_msgSender(), rewardToClaim);
  }
 
  //round-related functions
  function startRound() external {
    onlyGovernance();
    require(!isRoundOpening, "Error: There is an opened round currently");
    require(
        address(crimerInfoStorageFactory) != address(0) && 
        address(crimerInfo) != address(0), 
        "CrimerInfo address is not set" 
    );
  
    roundNumber += 1;

    isRoundOpening = true;
    isRoundFinished = false;
    
    roundStartTimestamp = block.timestamp;
    roundDay = 1;

    address newCrimerInfoStorage = crimerInfoStorageFactory.createInstance(address(crimerInfo));

    address[] memory initMinters = new address[](2);
    initMinters[0] = address(crimerInfo);
    initMinters[1] = store.owner();

    address newCrimeCash = crimeCashFactory.createInstance(store, initMinters);
    
    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished);
    crimerInfo.setStorage(newCrimerInfoStorage);
    crimerInfo.setCrimeCash(newCrimeCash);

    // add default CCASH pool
    _addPool(true, newCrimeCash, 1);

    emit eventStartRound(goldRewardForCrimer, roundDay, roundStartTimestamp, newCrimerInfoStorage,newCrimeCash, roundNumber);
  }
  
  function _distributeGold (
    Crimer[] memory _crimer,
    uint256[] memory _rewardsAmount
  ) private {
    uint256 _amount;
    for(uint256 i=0;i<_crimer.length;i++) {
      _amount = _rewardsAmount[i] * 10 ** 17;
      cgoldRewards[_crimer[i].userAddress] = cgoldRewards[_crimer[i].userAddress].add(_amount);
    }
  }
  function updateRoundDay() external {
    onlyGovernaneOrController();
    require(roundDay >= 1 && roundDay < 30, "Error: Invalid round day");

    roundDay += 1;
    
    for (uint256 i; i < pools[roundNumber].length; i++)
      _recalculateApyRates(roundNumber, i);

    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished);
    
    emit eventUpdateRoundDay(roundDay);
  }
  function _finishRound() private {
    require(isRoundOpening == true, "Error: There is not an opened round currently");
    require(roundDay == 30, "Error: current round day isn`t the last one");

    isRoundOpening = false;
    roundStartTimestamp = 0;
    roundDay = 0;
    isRoundFinished = true;

    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished);

    emit eventFinishRound();
  }

  function _updateCurrentDayLockedTokens(uint16 _roundNumber, uint8 _roundDay, uint256 _poolIndex, address _crimer, uint256 _amount) private { 
    pools[_roundNumber][_poolIndex].lockedTokens[_crimer] = pools[roundNumber][_poolIndex].lockedTokens[_crimer].add(_amount);
    pools[_roundNumber][_poolIndex].totalStakedRoundDay = pools[_roundNumber][_poolIndex].totalStakedRoundDay.add(_amount);
    pools[_roundNumber][_poolIndex].lockedTokensRoundDay[_crimer] = _roundDay;
    pools[_roundNumber][_poolIndex].StakeLPRoundDay = _roundDay;
  }
  
  function _onUnstakeUpdateInfo(uint16 _roundNumber, uint256 _poolIndex, address _crimer) private{ 
    if (pools[_roundNumber][_poolIndex].balances[_crimer] == 0) {
      pools[_roundNumber][_poolIndex].isStakerExists[_crimer] = false;

      if(pools[_roundNumber][_poolIndex].infoData.stakers > 0)
        pools[_roundNumber][_poolIndex].infoData.stakers = pools[_roundNumber][_poolIndex].infoData.stakers.sub(1);

      pools[_roundNumber][_poolIndex].userConnectDay[_crimer] = 0;
    }
  }

  function _onStakeUpdateInfo(uint16 _roundNumber, uint256 _poolIndex, address _crimer, uint256 _amount) private{ 
    _updateCurrentDayLockedTokens(_roundNumber, roundDay, _poolIndex, _crimer, _amount);

    if (!_isExistsPlayerInPool(_roundNumber, _poolIndex, _crimer) ) {
      pools[_roundNumber][_poolIndex].isStakerExists[_crimer] = true;
      pools[_roundNumber][_poolIndex].userConnectDay[_crimer] = roundDay;
      pools[_roundNumber][_poolIndex].infoData.stakers = pools[_roundNumber][_poolIndex].infoData.stakers.add(1);
    }
  }

  function _recalculateApyRates(uint16 _roundNumber, uint256 _poolIndex) private {
    if(pools[_roundNumber][_poolIndex].infoData.isCrimeCash == true) return;
    
    pools[_roundNumber][_poolIndex].infoData.apyRates[roundDay - 1] = 
      pools[_roundNumber][_poolIndex].infoData.defaultApyRates[roundDay - 1].add(
        pools[_roundNumber][_poolIndex].infoData.defaultApyRates[roundDay - 1]
          .mul(pools[_roundNumber][_poolIndex].infoData.stakers == 0 ? 0 : pools[_roundNumber][_poolIndex].infoData.stakers - 1) 
      );
  }

  function _calculateRewardCurrentRoundDay(uint16 _roundNumber, uint256 _poolIndex, address _crimer) private {
      if(roundDay != pools[_roundNumber][_poolIndex].lockedTokensRoundDay[_crimer]) {
        pools[roundNumber][_poolIndex].lockedTokens[_crimer] = 0;
        pools[_roundNumber][_poolIndex].lockedTokensRoundDay[_crimer] = 0;
      }
      if(roundDay != pools[_roundNumber][_poolIndex].StakeLPRoundDay)
        pools[_roundNumber][_poolIndex].totalStakedRoundDay = 0;
  }
  
  function _isExistsPlayerInPool(uint16 _roundNumber, uint256 _poolIndex, address _player) private view returns (bool) {
    return pools[_roundNumber][_poolIndex].isStakerExists[_player];
  }

  function addDefaultAssets(uint256 decimals) external {
    require(!isRoundOpening, "Round should not be started");
    require(!isDefaultAssetsAdded, "Default assets is already added");

    isDefaultAssetsAdded = true;

    uint256 precision = 10 ** decimals;
    
    _addAsset(1, 1, 300, precision.mul(500), true);
    _addAsset(1, 2, 660, precision.mul(1000), true);
    _addAsset(1, 3, 1386, precision.mul(2000), true);
    _addAsset(1, 4, 3049, precision.mul(4000), true);
    _addAsset(1, 5, 6403, precision.mul(8000), true);
    _addAsset(1, 6, 14087, precision.mul(16000), true);
    _addAsset(1, 7, 29583, precision.mul(32000), true);
    _addAsset(1, 8, 65083, precision.mul(104000), true);
    _addAsset(1, 9, 136675, precision.mul(328000), true);
    _addAsset(1, 10, 300685, precision.mul(756000), true);
    _addAsset(1, 11, 661507, precision.mul(1912000), true);
    _addAsset(1, 12, 1389165, precision.mul(8024000), true);
    _addAsset(1, 13, 3056163, precision.mul(22048000), true);
    _addAsset(1, 14, 6417942, precision.mul(54096000), true);
    _addAsset(1, 15, 14119472, precision.mul(108192000), false);

    _addAsset(2, 1, 250, precision.mul(300), true);
    _addAsset(2, 2, 550, precision.mul(600), true);
    _addAsset(2, 3, 1155, precision.mul(1200), true);
    _addAsset(2, 4, 2541, precision.mul(2400), true);
    _addAsset(2, 5, 5336, precision.mul(4800), true);
    _addAsset(2, 6, 11739, precision.mul(19200), true);
    _addAsset(2, 7, 24653, precision.mul(38400), true);
    _addAsset(2, 8, 54236, precision.mul(76800), true);
    _addAsset(2, 9, 113896, precision.mul(223600), true);
    _addAsset(2, 10, 250571, precision.mul(621600), true);
    _addAsset(2, 11, 551256, precision.mul(1843200), true);
    _addAsset(2, 12, 1157637, precision.mul(7686400), true);
    _addAsset(2, 13, 2546802, precision.mul(19372800), true);
    _addAsset(2, 14, 5348285, precision.mul(51745600), true);
    _addAsset(2, 15, 11766227, precision.mul(100000000), false);

    _addAsset(3, 1, 3, precision.mul(1000), false);
    _addAsset(3, 2, 5, precision.mul(10000), false);
    _addAsset(3, 3, 10, precision.mul(120000), false);
    _addAsset(3, 4, 15, precision.mul(900000), false);
    _addAsset(3, 5, 20, precision.mul(3000000), false);
    _addAsset(3, 6, 25, precision.mul(20000000), false);
    _addAsset(3, 7, 30, precision.mul(50000000), false);
    _addAsset(3, 8, 50, precision.mul(250000000), false);

    _addAsset(4, 1, 30, precision.mul(1000), false);
    _addAsset(4, 2, 60, precision.mul(10000), false);
    _addAsset(4, 3, 120, precision.mul(500000), false);
    _addAsset(4, 4, 300, precision.mul(10000000), false);
    _addAsset(4, 5, 600, precision.mul(50000000), false);
    _addAsset(4, 6, 900, precision.mul(100000000), false);
  }

  function _addPool(bool _isCrimeCash, address _lpToken, uint8 _openDay) private { 
    require(_openDay > 0 && _openDay < 30, "Error: Invalid opend day");
    require(_lpToken != address(0), "Error: Invalid lpToken address");
    PoolInfo memory _newPool;
    
    _newPool.infoData.exists = true;
    _newPool.infoData.lpToken =  IERC20(_lpToken);
    _newPool.infoData.totalStaked = 0;
    _newPool.infoData.isCrimeCash = _isCrimeCash;
    _newPool.infoData.openDay = _openDay;
    
    pools[roundNumber].push(_newPool);
    
    _setApyRate(
      pools[roundNumber].length - 1, // id of just created pool
      _isCrimeCash ? 
        _defaultCrimCashPoolApyRates : 
        _defaultLpPoolApyRates
    );

    _recalculateApyRates(roundNumber, pools[roundNumber].length - 1);

    emit addNewPool(_lpToken);
  }

  function _setApyRate(uint256 _poolIndex, uint256[30] memory _rates) private {
    pools[roundNumber][_poolIndex].infoData.defaultApyRates = _rates;
    pools[roundNumber][_poolIndex].infoData.apyRates = _rates;
  }

  modifier notOwner() {
    require(
      !store.governance(_msgSender()) && 
      !store.controller(_msgSender()), 
      "Error: owner/controller doesn't allow"
    );
    _;
  }

  modifier fromCrimerInfo() {
    require(_msgSender() == address(crimerInfo), "Error: Not allowed.");
    _;
  }
}

pragma solidity 0.6.12;
import "./ERC20/ERC20.sol";
import "./ERC20/ERC20Detailed.sol";
import "./ERC20/ERC20Mintable.sol";
import "./Governable.sol";
import "./Storage.sol";

contract CrimeCash is ERC20Detailed, ERC20Mintable, Governable {

  constructor(Storage _storage, address[] memory _initMinters) public ERC20Detailed("CrimeCash", "CCASH", 2) Governable(_storage) {
    // msg.sender should not be a minter
    renounceMinter();

    for (uint256 i; i < _initMinters.length; i++)
      _addMinter(_initMinters[i]);
  }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../Types/Crimer.sol";
import "./SafeMath.sol";
import "./SafePercentageLibrary.sol";

library CrimerLibrary {
    using SafePercentageLibrary for uint256;
    using SafeMath for uint256;

    function totalAttack(Crimer memory _crimer) internal pure returns (uint256) { 
        return 
            _crimer.attack
                .add(_crimer.attack.safePercentageFrom(_crimer.nftPerkAttackBoost)) 
                .add(_crimer.attack.safePercentageFrom(_crimer.nftPerkPowerBoost));
    }

    function totalDefense(Crimer memory _crimer) internal pure returns (uint256) { 
        return
            _crimer.defense
                .add(_crimer.defense.safePercentageFrom(_crimer.nftPerkDefenseBoost)) 
                .add(_crimer.defense.safePercentageFrom(_crimer.nftPerkPowerBoost));
    }

    function totalClaimBoost(Crimer memory _crimer) internal pure returns (uint256) { 
        return
            _crimer.boost
                .add(_crimer.nftPerkStakeBoost);
    }
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

struct Crimer {
    bool    exist;
    address userAddress;
    uint256 bank;
    uint256 cash;
    uint256 attack;
    uint256 defense;
    uint256 boost;
    uint256 referrals;
    uint256 protectedUntil;
    uint256[] boosts;


    // in percents. Parts per 100 (1% - 1)
    uint256 nftPerkAttackBoost;
    uint256 nftPerkDefenseBoost;
    uint256 nftPerkPowerBoost;
    uint256 nftPerkStakeBoost;

    uint256 index;
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../Types/NFTWeaponType.sol";
import "../Types/NFTPerkType.sol";

struct CrimeNFT {
    uint256 id;
    string name;
    string description;
    string image;
    bool isPerk;
    NFTPerkType perkType;
    NFTWeaponType weaponType;
    uint256 power;
    uint256 from;
    uint256 to;
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


enum NFTWeaponType { 
    NOT_A_VALUE,
    Attack,
    Defense
}

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


enum NFTPerkType { 
    NOT_A_VALUE,
    Attack,
    Defense,
    Stake,
    TotalPower
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "../libraries/Address.sol";
import "../Context.sol";
import "./ERC165.sol";
import "../libraries/SafeMath.sol";
import "../Types/CrimeNFT.sol";
import "../Governable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract CrimERC1155 is ERC165, IERC1155, Governable {
    using Address for address;
    using SafeMath for uint256;

    CrimeNFT[] public nfts;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string private _name;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory name, Storage _store) public Governable(_store) {
        _name = name;
    }

    function getName() external view returns (string memory) {
        return _name;
    }

    function getAllNfts() public view returns (CrimeNFT[] memory) {
        return nfts;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance.sub(amount);
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance.sub(amount);
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = _balances[ids[i]][to].add(amounts[i]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance.sub(amount);

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance.sub(amount);
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

pragma solidity ^0.6.2;

import "./SafeMath.sol";

library SafePercentageLibrary {
    using SafeMath for uint256;
    function safePercentageFrom(uint256 _total, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        if (_total == 0) return 0;
        return _total.mul(_percentage).div(_total);
    }
}

pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "../Types/CrimeNFT.sol";

library RandomLibrary {
    using SafeMath for uint256;

    uint256 public constant MAX_UINT = 2**256 - 1;

    function random(uint256 nonce, uint256 maxValue)
        internal
        view
        returns (uint256)
    {
        return
            _random(
                block.difficulty,
                block.timestamp,
                blockhash(block.number),
                nonce,
                maxValue
            );
    }

    function random(uint256 nonce) internal view returns (uint256) {
        return
            _random(
                block.difficulty,
                block.timestamp,
                blockhash(block.number),
                nonce,
                MAX_UINT
            );
    }

    function _random(
        uint256 _blockDiff,
        uint256 _timestamp,
        bytes32 _hash,
        uint256 nonce,
        uint256 maxValue
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_blockDiff, _timestamp, _hash, nonce)
                )
            ).mod(maxValue);
    }

    function getRandomAsset(
        CrimeNFT[] storage _assets,
        uint256[] storage _participatedIds,
        uint256 _totalWeigths,
        uint256 _nonce
    ) internal view returns (uint256 assetId) {
        uint256 rnd = random(_nonce, _totalWeigths);

        if(rnd == 0)
            rnd = 1;

        for (uint256 j; j < _participatedIds.length; j++) {
            uint256 i = _participatedIds[j];
            if (rnd >= _assets[i].from && rnd <= _assets[i].to) return i;
        }

        revert("Random failed");
    }
}

pragma solidity 0.6.12;
import "./Storage.sol";
import "./ERC20Upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ERC20Upgradeable/proxy/utils/Initializable.sol";
import "./ERC20Upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./ERC20Upgradeable/security/PausableUpgradeable.sol";

contract CrimeGold is Initializable, ERC20Upgradeable, PausableUpgradeable {
  mapping(address => bool) private _isExcludedFromBurn;

  address public pancakePair;
  uint256 public _burnRatePercent;

  using SafeMathUpgradeable for uint256;

  mapping(address => bool) public _isIncludeAddressPairBurn;

  function initialize(Storage _storage) public initializer {
    __ERC20_init("CrimeGold", "CRIME");
    __Pausable_init(_storage);

    _burnRatePercent = 25;

    _isExcludedFromBurn[_msgSender()] = true;

    _mint(msg.sender, 10000 * 10 ** 18);
    _pause();
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function transfer(address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint256 burnedAmount;

    if((pancakePair == recipient || _isIncludeAddressPairBurn[recipient]) && !_isExcludedFromBurn[sender]) { 
      burnedAmount = amount.mul(_burnRatePercent).div(10**2);
      _burn(sender, burnedAmount);
    }

    super._transfer(sender, recipient, amount.sub(burnedAmount));
  }

  function setAddressPairBurn(address _address, bool _isInclude) external {
    onlyOwner();
    _isIncludeAddressPairBurn[_address] = _isInclude;
  }

  function pause() external whenNotPaused {
    onlyOwner();
    _pause();
  }

  function unpause() external whenPaused {
    onlyOwner();
    _unpause();
  }
}

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.6.12;

import "./Context.sol";

contract Storage is Context {

  mapping (address => bool) public governance;
  mapping (address => bool) public controller;

  address immutable public owner;

  constructor() public {
    owner = _msgSender();
    governance[_msgSender()] = true;
    controller[_msgSender()] = true;
  }

  
  function setGovernance(address _governance, bool _isGovernance) external {
    require(_msgSender() == owner, "not an owner");
    require(_governance != _msgSender(), "governance cannot modify itself");
    governance[_governance] = _isGovernance;
  }

  function setController(address _controller, bool _isController) external {
    require(governance[_msgSender()], "not a governance");
    controller[_controller] = _isController;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.6.12;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.6.12;

/*
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

        /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.6.12;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
        /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.6.12;

import "../../Storage.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
import "../../GovernableUpgradable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable, GovernableUpgradable {

    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init(Storage _storage) internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __Governable_init(_storage);
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenNotPausedExceptGovernance() {
        if(!(msg.sender == store.owner() || store.governance(msg.sender)))
            require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.6.12;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.6.12;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

pragma solidity ^0.6.12;
import "./Storage.sol";
import "./ERC20Upgradeable/proxy/utils/Initializable.sol";

// File: contracts/Governable.sol

contract GovernableUpgradable is Initializable {
  Storage public store;

  function __Governable_init(Storage _store) public initializer {
    store = _store;
  }

  function onlyOwner() internal view{
    require(store.owner() == msg.sender, "Not the owner");
  }

  function onlyGovernance() internal view{
    require(store.governance(msg.sender), "Not governance");
  }

  function onlyController() internal view{
    require(store.controller(msg.sender), "Not controller");
  }

  function onlyGovernaneOrController() internal view{
    require(store.controller(msg.sender) || store.governance(msg.sender) , "Not a owner/controller");
  }
}

pragma solidity ^0.6.12;
import "../Storage.sol";
import "../CrimeCash.sol";

contract CrimeCashFactory { 
  function createInstance(Storage _storage, address[] memory _initMinters) external returns(address){ 
    return address(new CrimeCash(_storage, _initMinters));
  }  
}

pragma solidity ^0.6.12;

import "../CrimerInfo.sol";

contract CrimerInfoStorageFactory { 
  function createInstance(address _crimerInfo) external returns (address) {
    return address(new CrimerInfoStorage(_crimerInfo));
  }
}

/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.12;
import "../Context.sol";
import "./IERC20.sol";
import "../libraries/SafeMath.sol";

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.6.12;
import "./IERC20.sol";

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.6.12;
import "./ERC20.sol";
import "./MinterRole.sol";

// File: @openzeppelin/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) virtual public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

pragma solidity ^0.6.12;
import "../Context.sol";
import "../libraries/Roles.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) virtual public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

pragma solidity ^0.6.12;
// File: @openzeppelin/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}