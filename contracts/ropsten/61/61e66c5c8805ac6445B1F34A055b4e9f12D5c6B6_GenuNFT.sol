// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./library/ERC721/ERC721Full.sol";
import "./library/ownership/OwnableAndPausable.sol";

/// @title GenuNFT
/// @author Genuino
contract GenuNFT is ERC721Full, OwnableAndPausable {
  /**
   * Data Structures and values
   */

  struct NftData{
    uint256 creationDate;
    string nfcSerialNumber;
    string rfidSerialNumber;
    string patchId;
  }

  struct TrackingStep{
    uint256 timestamp;
    string eventCode;
    string eventDescription;
    string location;
    string locationName;
    string publicData1;
    string publicData2;
  }

  uint256 internal _transferFee;
  uint256 internal _creationFeeETH;

  mapping(uint256 => TrackingStep[]) tokenTracking;

  NftData[] tokenDataStorage;

  //mapping da tokenId a BrandId
  mapping(uint256 => uint256) tokenCreatedBy;

  //Mapping da brandId a tokenIds[]
  mapping(uint256 => uint256[]) tokensCreatedByArray;

  mapping (address => bool) _brandWhiteList;
  mapping (uint256 => address) _brandAddresses;
  mapping (address => uint256) _brandIds;
  //_brandId = 0 means invalid brand
  uint256 totalBrands = 0;

  // mapping tra tokenId e bool
  mapping (uint256 => bool) _tokenTransferDisabled;

  // mapping tra nfcSerialNumber e tokenId
  mapping (string => uint256) _nfcSerialsNumber;

  // mapping tra rfidSerialNumber e tokenId
  mapping (string => uint256) _rfidSerialsNumber;

  // mapping tra patchId e tokenId
  mapping (string => uint256) _patchIds;

  uint256 tokenIdCounter;

  /**********************/

  /*
  * Events
  */
  event TokenCreated(uint256 indexed tokenId, address creatorAddress, string nfcSerialNumber);
  event TokenTransfered(uint256 indexed tokenId, address from, address to);
  event TokenInfoUpdated(uint256 indexed tokenId, address updatingAddress);
  event BrandCreated(uint256 indexed brandId, address brandAddress);
  event BrandModified(uint256 indexed brandId, address newBrandAddress);
  event TokenTransferUpdated(uint256 indexed tokenId, address tokenOwner, bool disabled);
  event TokenOwnershipTransfered(uint256 indexed tokenId, address fromAddress, address toAddress);
  event TrackingStepAdded(uint256 indexed tokenId, TrackingStep newStep);
  event TransferFeesUpdated(uint256 newETHFees);
  event CreationFeesUpdated(uint256 newETHFees);
  event FeeHasBeenWithdrawn(uint256 withdrawnBalanceETH, address toAddress);

  /*....*/

  /*********************/
  constructor() ERC721Full("GenuNFT - Staging", "GNFT-S") {
    addBrandAddress(msg.sender); //Genuino è un brand
  }

  /*
  * Internal functions for substitude modifiers
  */

  /**
  * @notice Check if caller is the contract owner 
  */
  function _isGenuino() internal view {
    require(msg.sender == _owner);
  }

  /**
   * @notice Check if caller is the contract owner or a brand
   */
  function _isGenuinoOrBrand() internal view {
    require(msg.sender == _owner || _brandWhiteList[msg.sender]);
  }

  /**
   * @notice Check if caller is the token owner
   */
  function _isTokenOwner(uint256 tokenId) internal view {
    require(msg.sender == ownerOf(tokenId));
  }

  /**
   * @notice Check if caller is the owner or a creator branf
   */
  function _isGenuinoOrCreatorBrand(uint256 tokenId) internal view {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    bool isCreator = _brandIds[msg.sender] != 0 && tokenCreatedBy[tokenId] == _brandIds[msg.sender];
    require(msg.sender == _owner || isCreator);
  }

  function _isNotPaused() internal view {
    require(_paused == false);
  }

  /*
   * Fee functions
   */

  /**
   * @dev update transfer fee
   * @param newFee the new fee to set
   */
  function updateTransferFee(uint256 newFee) public {
    _isGenuino();
    _transferFee = newFee;
    emit TransferFeesUpdated(_transferFee);
  }
  
  /**
   * @dev update creation fee
   * @param newFeeETH the new fee to set
   */
  function updateCreationFee(uint256 newFeeETH) public {
    _isGenuino();
    _creationFeeETH = newFeeETH;
    emit CreationFeesUpdated(_creationFeeETH);
  }
    
  /**
   * @dev withdraw fees
   */
  function withdrawFees() public {
    _isGenuino();
    uint256 balanceETH = address(this).balance;
    msg.sender.transfer(balanceETH);
    emit FeeHasBeenWithdrawn(balanceETH, msg.sender);
  }

  /*
   * NFT Token functions
   */

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public {
    _isGenuino();
    _transferOwnership(newOwner);
    _updateBrandAddress(1, newOwner);
  }

  /**
   * @dev Mint new token
   * @param tokenData the nft data
   */ 
  function createToken(NftData memory tokenData) public payable {
    _isNotPaused();
    _isGenuinoOrBrand();
    require(msg.value == _creationFeeETH, "ETH sent are not enough to create the token.");
    tokenDataStorage.push(tokenData);
    uint256 newTokenId = tokenIdCounter;
    tokenIdCounter++;
    _mint(msg.sender, newTokenId);
    uint256 brandId = _brandIds[msg.sender];
    tokenCreatedBy[newTokenId] = brandId;
    tokensCreatedByArray[brandId].push(newTokenId);
    _tokenTransferDisabled[newTokenId] = false;
    _nfcSerialsNumber[tokenData.nfcSerialNumber] = newTokenId;
    _rfidSerialsNumber[tokenData.rfidSerialNumber] = newTokenId;
    _patchIds[tokenData.patchId] = newTokenId;
    emit TokenCreated(newTokenId, msg.sender, tokenData.nfcSerialNumber);
  }

  /**
   * @dev Mint new tokens in batch
   * @param tokensData the nft datas
   */ 
  function createTokensInBatch(NftData[] memory tokensData) public payable {
    _isNotPaused();
    _isGenuinoOrBrand();
    for (uint i = 0; i < tokensData.length; i++) {
      _createToken(tokensData[i]);
    }
  }

  /** 
   * @notice Internal function to create token
   */
  function _createToken(NftData memory tokenData) internal {
    createToken(tokenData);
  }

  /**
   * @dev Mint new token with an initial step
   * @param tokenData the nft data
   * @param newStep the new tracking step 
   */ 
  function createTokenWithStep(NftData memory tokenData, TrackingStep memory newStep) public payable {
    _isNotPaused();
    _isGenuinoOrBrand();
    _createToken(tokenData);
    _addTrackingStep(tokenIdCounter - 1, newStep);
  }

  // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/1015
  /**
   * @dev transfer token 
   * @param from address
   * @param to address
   * @param tokenId the token id to transfer 
   */
  function transferFrom(address from, address to, uint256 tokenId) override public payable {
    _isNotPaused();
    _isTokenOwner(tokenId);
    require(!_tokenTransferDisabled[tokenId], "The token ownership transfer has been disabled by the token owner.");
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    require(msg.value == _transferFee, "ETH sent are not enough to transfer the token.");
    addTransferStep(tokenId);
    //IERC721 token = IERC721()
    _transferFrom(msg.sender, to, tokenId);
    emit TokenOwnershipTransfered(tokenId, from, to);
  }

  
  /**
   * @dev funzione che viene chiamata per aggiungere/aggiornare informazioni del token
   * @param tokenId the id of the token
   * @param tokenData Nft Data struct
   */
  function updateItemInfo(uint256 tokenId, NftData memory tokenData) public {
    _isNotPaused();
    _isGenuinoOrCreatorBrand(tokenId);
    tokenDataStorage[tokenId] = tokenData;
    emit TokenInfoUpdated(tokenId, msg.sender);
  }

  /**
   * @dev utente disabilita la possibilità di trasferire un token 
   * @param tokenId the token id to disable 
   */
  function disableTokenTransfer(uint256 tokenId) public {
    _isNotPaused();
    _isTokenOwner(tokenId);
    _tokenTransferDisabled[tokenId] = true;
    emit TokenTransferUpdated(tokenId, msg.sender, true);
  }

  /**
   * @dev utente riabilita la possibilità di trasferire un token 
   * @param tokenId the token id to resume 
   */
  function resumeTokenTransfer(uint256 tokenId) public {
    _isNotPaused();
    _isTokenOwner(tokenId);
    _tokenTransferDisabled[tokenId] = false;
    emit TokenTransferUpdated(tokenId, msg.sender, false);
  }

  /**
   * @dev check if the tokenId is trasferible
   * @param tokenId the token id to check
   */
  function isTrasferable(uint256 tokenId) public view returns(bool) {
    return !_tokenTransferDisabled[tokenId];
  }

  /**
   * @dev set base token URI
   * @param uri the new uri to set
   */
  function setBaseTokenURI(string memory uri) public {
    _isGenuino();
    _setBaseTokenURI(uri);
  }

  /*
   * Brand functions
   */

  /**
   * @param newBrandAddress address to update brand
   * @return total brands created
   */ 
  function addBrandAddress(address newBrandAddress) public returns(uint256) {
    _isGenuino();
    require(!_brandWhiteList[newBrandAddress], "A brand with this address already exists.");
    totalBrands += 1;
    _brandAddresses[totalBrands] = newBrandAddress;
    _brandWhiteList[newBrandAddress] = true;
    _brandIds[newBrandAddress] = totalBrands;
    emit BrandCreated(totalBrands, newBrandAddress);
    return totalBrands;
  }

  /**
   * @param brandId the id of the brand
   */ 
  function removeBrandAddress(uint256 brandId) public {
    _isGenuino();
    require(brandId != 1, "Genuino brand cannot be removed.");
    updateBrandAddress(brandId, address(0));
  }

  /**
   * @dev Internal function for updating brand address
   * @param brandId the id of the brand
   * @param newBrandAddress address to update brand
   */ 
  function updateBrandAddress(uint256 brandId, address newBrandAddress) public {
    _isGenuino();
    _updateBrandAddress(brandId, newBrandAddress);
  }

  /**
   * @param brandId the id of the brand
   * @param newBrandAddress address to update brand
   */ 
  function _updateBrandAddress(uint256 brandId, address newBrandAddress) internal {
    require(!_brandWhiteList[newBrandAddress], "A brand with this address already exists.");
    address oldAddress = _brandAddresses[brandId];
    _brandWhiteList[oldAddress] = false;
    _brandAddresses[brandId] = newBrandAddress;
    _brandIds[oldAddress] = 0;
    _brandIds[newBrandAddress] = brandId;
    if(newBrandAddress != address(0)) { //removeBrandAddress Case
      _brandWhiteList[newBrandAddress] = true;
    }
    emit BrandModified(brandId, newBrandAddress);
  }

  /*
   * Tracking Step functions
   */

  /**
   * @dev Aggiunge uno step durante il trasferimento del token
   * @param tokenId the token id
   */
  function addTransferStep(uint256 tokenId) internal {
    _isTokenOwner(tokenId);
    string memory location = ''; 
    string memory locationName = '';
    if (tokenTracking[tokenId].length > 0) {
      TrackingStep memory lastStep = tokenTracking[tokenId][tokenTracking[tokenId].length - 1];
      location = lastStep.location;
      locationName = lastStep.locationName;
    }
    TrackingStep memory newStep = TrackingStep(
      getTimestamp(),
      'UTO',
      '{ en-US:"Token Ownership Updated", it-IT:"Proprieta Del Token Aggiornata"}',
      location,
      locationName,
      '',
      ''
    );
    tokenTracking[tokenId].push(newStep);
    emit TrackingStepAdded(tokenId, newStep);
  }

  /**
   * @dev aggiorna la tappa del token
   * @param tokenId the token id
   * @param newStep the tracking step to added 
   */
  function addTrackingStep(uint256 tokenId, TrackingStep memory newStep) public {
    _isNotPaused();
    _isGenuinoOrCreatorBrand(tokenId);
    tokenTracking[tokenId].push(newStep);
    emit TrackingStepAdded(tokenId, newStep);
  }

  /** 
   * @notice Internal function to add a new tracking step
   */
  function _addTrackingStep(uint256 tokenId, TrackingStep memory newStep) internal {
      addTrackingStep(tokenId, newStep);
  }

  /**
   * @dev aggiorna le tappe del token
   * @param tokenId the token id
   * @param newSteps the tracking steps to added 
   */
  function addTrackingStepsInBatch(uint tokenId, TrackingStep[] memory newSteps) public {
    _isNotPaused();
    _isGenuinoOrCreatorBrand(tokenId);
    for(uint i = 0; i < newSteps.length; i++) {
      _addTrackingStep(tokenId, newSteps[i]);
    }
  }

  /**
   * @dev Aggiunge un tracking step con la nuova posizione
   * @param tokenId the token id
   * @param location the new location
   * @param locationName the new location name
   * @param publicData the public data 
   */
  function updateItemLocation(uint256 tokenId, string memory location, string memory locationName, string memory publicData) public {
    _isNotPaused();
    _isTokenOwner(tokenId);
    TrackingStep memory newStep = TrackingStep(
        getTimestamp(),
        'UIL',
        '{ en-US:"Location Updated", it-IT:"Posizione Aggiornata"}',
        location,
        locationName,
        '',
        publicData
    );
    tokenTracking[tokenId].push(newStep);
    emit TrackingStepAdded(tokenId, newStep);
  }

  /*
   * Getters
   */

  /**
   * @dev get creation fee
   * @return creation fees
   */
  function getCreationFee() public view returns(uint256) {
    return _creationFeeETH;
  }
    
  /**
   * @dev get transfer fee
   * @return transfer fees
   */
  function getTransferFee() public view returns(uint256) {
    return _transferFee;
  }
  
  /**
   * @dev retrieves all tokens created by brandId 
   * @param brandId brand id
   */ 
  function getTokensCreatedBy(uint256 brandId) public view returns(uint256[] memory){
    return tokensCreatedByArray[brandId];
  }

  /**
   * @return all tokens data
   */
  function getAllTokenData() public view returns(NftData[] memory){
    return tokenDataStorage;
  }

  /**
   * @dev get token by tokenId
   * @param tokenId tokenId to search
   * @return token NftData
   */
  function getTokenById(uint256 tokenId) public view returns(NftData memory){
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    return tokenDataStorage[tokenId];
  }

  /**
   * @dev get tracking steps by tokenId
   * @param tokenId tokenId to search
   * @return token TrackingStep[]
   */
  function getTokenTrackingStepById(uint256 tokenId) public view returns(TrackingStep[] memory){
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    return tokenTracking[tokenId];
  }

  /**
   * @return numbers of brands created
   */ 
  function getBrandsNumber() public view returns(uint256){
    return totalBrands;
  }

  /**
   * @param brandId brand id
   * @return brandId address
   */
  function getBrandAddress(uint256 brandId) public view returns(address){
    return _brandAddresses[brandId];
  }

  /**
   * @return all brands addresses
   */
  function getAllBrands() public view returns(address[] memory) {
    address[] memory allBrands = new address[](totalBrands+1);
    for(uint i = 0 ; i <= totalBrands ; i++){
      allBrands[i] = _brandAddresses[i];
    }
    return allBrands;
  }

  /**
   * @dev ritorna il token associato ad un nfc seriale
   * @param nfcSerialNumber the nfc serial number of the token
   * @return NftData
   * @return token id 
   */
  function getTokenByNfc(string memory nfcSerialNumber) public view returns(NftData memory, uint256) {
    uint256 tokenId = _nfcSerialsNumber[nfcSerialNumber];
    return (tokenDataStorage[tokenId], tokenId);
  }

  /**
   * @dev ritorna il token associato ad un rfid seriale
   * @param rfidSerialNumber the rfid serial number of the token
   * @return NftData
   * @return token id 
   */
  function getTokenByRfid(string memory rfidSerialNumber) public view returns(NftData memory, uint256) {
    uint256 tokenId = _rfidSerialsNumber[rfidSerialNumber];
    return (tokenDataStorage[tokenId], tokenId);
  }

  /**
   * @dev ritorna il token associato ad una patch id
   * @param patchId the patch id of the token
   * @return NftData
   * @return token id 
   */
  function getTokenByPatchId(string memory patchId) public view returns(NftData memory, uint256) {
    uint256 tokenId = _patchIds[patchId];
    return (tokenDataStorage[tokenId], tokenId);
  }

  /**
   * @notice retrieve timestamp of the current block 
   */
  function getTimestamp() public view returns (uint256) {
    return block.timestamp;
  }
}