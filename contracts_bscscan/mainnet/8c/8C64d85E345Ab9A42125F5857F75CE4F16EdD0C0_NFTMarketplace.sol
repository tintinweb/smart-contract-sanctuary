/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
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
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _setOwner(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the marketplace contract.
 */
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @dev signature of external (deployed) contract for NFT publishing (ERC721)
 * only methods we will use, needed for us to communicate with Cyclops token (which is ERC721)
 */
interface ICyclopsTokens {
  function mint(address to, uint256 tokenId, string calldata uri) external;
  function ownerOf(uint256 tokenId) external view returns (address);
  function burn(uint256 tokenId) external;
  function tokenURI(uint256 tokenId) external view returns(string memory);
}

//Cytr in functions names - Cytr is internal name for payment token, this contract
//is published on BSC and Cytr == ETNA token
//if function names will be changed - you need to change also frontend & backend
//i.e. unneeded time spend
contract NFTMarketplace is Ownable {
  modifier onlyPriceManager() {
    require(msg.sender == _price_manager,
      "only price manager can call this function");
    _;
  }

  modifier onlyOwnerOrPriceManager() {
    require(msg.sender == _price_manager || msg.sender == owner(),
      "Only price manager or owner can call this function");
    _;
  }

  /**
  * @dev not bullet-proof check, but additional measure, actually we require specific (contract) address,
  * which is key (see onlyBankContract)
  */
  function isContract(address _addr) internal view returns (bool){
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  modifier notContract(){
    require(!isContract(msg.sender),
      "external contracts are not allowed");
    _;
  }

  //external NFT publishing contract
  ICyclopsTokens internal _nftContract;
  IERC20 internal _etnaTokenContract; //ETNA

  address internal _price_manager;

  bool internal _internal_prices = true;
  uint256 internal _price_curve = 5; //5%

  uint32 constant BAD_NFT_PROFILE_ID = 9999999;
  uint256 constant BAD_PRICE = 0;
  string constant BAD_URL = '';
  uint32 constant UNLIMITED = 9999999;

  /**
   * @dev 'database' to store profiles of NFTs
   */
  struct NFTProfile {
    uint32 id;
    uint256 price; //in ETNA, i.e. 1,678 ETNA last 18 digits are decimals
    uint256 sell_price; //in ETNA i.e. 1,678 ETNA last 18 digits are decimals
    string url;
    uint32 limit;
  }

  NFTProfile[] public nftProfiles;

  uint256 internal _nextTokenId;
  uint256 internal _oldContractMaxId;
  mapping (uint32 => uint256) _nftProfileIndexes; // index by profile ID
  mapping (uint32 => uint256) _nftProfileMinted; // minted tokens number by profile ID
  mapping (uint256 => uint32) _nftProfileIdsByTokenId; // profile ID by tokenId
  mapping (bytes32 => uint32) _nftProfileIdsByUrl; // profile ID by tokenId
  mapping (uint32 => mapping (address => bool)) _availableForMinting; // Allowed for minting NFTs

  /**
  * @dev Events
  */
  //buy from us
  event Minted(uint32 profileID, uint256 tokenId, address wallet, uint256 curPrice);
  //buy back from user
  event Burned(uint32 profileID, uint256 tokenId, address wallet, uint256 curSellPrice);

  //admin events - ETNA tokens/ether deposit/withdrawal
  event TokensDeposited(uint256 amount, address wallet);
  event TokensWithdrawn(uint256 amount, address wallet);
  event AdminMinted(uint32 profileID, uint256 tokenId, address wallet, uint256 curPrice);
  event AdminBurned(uint32 profileID, uint256 tokenId, uint256 curSellPrice);

  event AirdropMinted(uint32 profileID, uint256 tokenId, address wallet, uint256 curPrice);

  /**
   * @dev Contract constructor.
   */
  constructor(address newNftContractAddress, address newERC20Address, uint256 oldContractMaxId) {
    require(newNftContractAddress != address(0), 'NFT contract address should not be zero');
    require(newERC20Address != address(0), 'ERC20 contract address should not be zero');
    _price_manager = owner();
    _nftContract = ICyclopsTokens(newNftContractAddress);   //NFT minting interface
    _etnaTokenContract = IERC20(newERC20Address);       //ETNA interface
    _oldContractMaxId = oldContractMaxId;
  }

  /**
   * @dev Set price manager
   */
  function setPriceManagerRight(address newPriceManager) external onlyOwner returns (bool) {
    require(newPriceManager != address(0), 'Price manager address should not be zero');
    _price_manager = newPriceManager;
    return true;
  }


  function getPriceManager() public view returns(address){
    return _price_manager;
  }

  function setInternalPriceCurve() external onlyOwnerOrPriceManager returns (bool) {
    _internal_prices = true;
    return true;
  }

  function setExternalPriceCurve() external onlyOwnerOrPriceManager returns (bool) {
    _internal_prices = false;
    return true;
  }

  function isPriceCurveInternal() public view returns (bool) {
    return _internal_prices;
  }

  function setPriceCurve(uint256 new_curve) external onlyOwnerOrPriceManager returns (bool) {
    _price_curve = new_curve;
    return true;
  }

  function getPriceCurve() public view returns (uint256) {
    return _price_curve;
  }

  /**
  * @dev setter/getter for ERC20 linked to exchange (current) smartcontract
  */
  function setPaymentToken (address newERC20Contract) external onlyOwner returns (bool) {
    require(newERC20Contract != address(0), 'ERC20 contract address should not be zero');
    _etnaTokenContract = IERC20(newERC20Contract);
    return true;
  }

  function getPaymentToken() external view returns (address) {
    return address(_etnaTokenContract);
  }

  /**
  * @dev setter/getter for NFT publisher linked to 'marketplace' smartcontract
  */
  function setNFTContract(address newNFTContract) external onlyOwner returns(bool) {
    require(newNFTContract != address(0), 'NFT contract address should not be zero');
    _nftContract = ICyclopsTokens(newNFTContract);
    return true;
  }

  function getNFTContract() external view returns(address){
    return address(_nftContract);
  }

  /**
   * @dev getter for _nextTokenId
   */
  function getNextTokenId() external  view returns (uint256){
    return _nextTokenId;
  }

  /**
  * @dev setter for _nextTokenId
  */
  function setNextTokenId(uint256 setId) external onlyOwnerOrPriceManager returns(bool) {
    _nextTokenId = setId;
    return true;
  }

  /**
  * @dev getter for nftProfiles.length
  */
  function getProfilesNumber() external view returns(uint256) {
    return nftProfiles.length;
  }

  /**
   * @dev adds 'record' to 'database'
   * @param profileID, unique id of profiles
   * @param price, price of NFT assets which will be generated based on profile
   * @param sell_price, when we will buy out from owner (burn)
   * @param url, url of NFT assets which will be generated based on profile
   */
  function addNFTProfile(
    uint32 profileID, uint256 price, uint256 sell_price, string calldata url, uint32 limit
  ) external onlyOwnerOrPriceManager returns (bool) {
    NFTProfile memory temp = NFTProfile(profileID, price, sell_price, url, limit);
    require(_nftProfileIndexes[profileID] == 0, 'This profile ID is already in use');
    bytes32 urlHash = keccak256(bytes(url));
    require(_nftProfileIdsByUrl[urlHash] == 0, 'This url is already in use');
    nftProfiles.push(temp);
    _nftProfileIndexes[profileID] = nftProfiles.length;
    _nftProfileIdsByUrl[urlHash] = profileID;

    return true;
  }

  /**
   * @dev removes 'record' to 'database'
   * @param profileID (profile id)
   *
   */
  function removeNFTProfileAtId(uint32 profileID) external onlyOwnerOrPriceManager returns (bool) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    require(_nftProfileMinted[profileID] == 0, 'This profile can not be removed');
    removeNFTProfileAtIndex(_nftProfileIndexes[profileID] - 1);
    delete _nftProfileIndexes[profileID];

    return true;
  }

  /**
   * @dev removes 'record' to 'database'
   * @param index, record number (from 0)
   *
   */
  function removeNFTProfileAtIndex(uint256 index) internal {
    if (index >= nftProfiles.length) return;
    _nftProfileIdsByUrl[keccak256(bytes(nftProfiles[index].url))] = 0;
    if (index < nftProfiles.length - 1) {
      nftProfiles[index] = nftProfiles[nftProfiles.length - 1];
      _nftProfileIndexes[nftProfiles[index].id] = index + 1;
    }
    nftProfiles.pop();
  }

  /**
   * @dev replaces 'record' in the 'database'
   * @param profileID, unique id of profile
   * @param price, price of NFT assets which will be generated based on profile
   * @param sell_price, sell price (back to owner) of NFT assets when owner sell to us (and we burn)
   * @param url, url of NFT assets which will be generated based on profile
   */
  function replaceNFTProfileAtId(
    uint32 profileID,
    uint256 price,
    uint256 sell_price,
    string calldata url,
    uint32 limit
  ) external onlyOwnerOrPriceManager returns (bool) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    bytes32 urlHash = keccak256(bytes(url));
    require(_nftProfileIdsByUrl[urlHash] == 0 || _nftProfileIdsByUrl[urlHash] == profileID, 'This url is already in use');
    uint256 index = _nftProfileIndexes[profileID] - 1;
    _nftProfileIdsByUrl[keccak256(bytes(nftProfiles[index].url))] = 0;
    _nftProfileIdsByUrl[urlHash] = profileID;
    nftProfiles[index] = NFTProfile(profileID, price, sell_price, url, limit);

    return true;
  }

  /**
   * @dev return array of strings is not supported by solidity, we return ids & prices
   */
  function viewNFTProfilesPrices() external view
  returns (uint32[] memory, uint256[] memory, uint256[] memory) {
    uint32[] memory ids = new uint32[](nftProfiles.length);
    uint256[] memory prices = new uint256[](nftProfiles.length);
    uint256[] memory sell_prices = new uint256[](nftProfiles.length);
    for (uint i = 0; i < nftProfiles.length; i++){
      ids[i] = nftProfiles[i].id;
      prices[i] = nftProfiles[i].price;
      sell_prices[i] = nftProfiles[i].sell_price;
    }
    return (ids, prices, sell_prices);
  }


  /**
  * @dev return price, sell_price & url for profile by profileID
  */
  function viewNFTProfileDetails(uint32 profileID) external view
  returns(uint256, uint256, string memory, uint32) {
    if (_nftProfileIndexes[profileID] == 0) return (BAD_PRICE, BAD_PRICE, BAD_URL, UNLIMITED);
    uint256 index = _nftProfileIndexes[profileID] - 1;
    return (
    nftProfiles[index].price,
    nftProfiles[index].sell_price,
    nftProfiles[index].url,
    nftProfiles[index].limit
    );
  }

  /**
   * @dev get price by profileID from 'database'
   * @param profileID, unique id of profiles
   */
  function getPriceById(uint32 profileID) external  view returns (uint256) {
    if (_nftProfileIndexes[profileID] == 0) return BAD_PRICE;
    return nftProfiles[_nftProfileIndexes[profileID] - 1].price;
  }

  /**
   * @dev get sell price by profileID from 'database'
   * @param profileID, unique id of profiles
   */
  function getSellPriceById(uint32 profileID) external  view returns (uint256) {
    if (_nftProfileIndexes[profileID] == 0) return BAD_PRICE;
    return nftProfiles[_nftProfileIndexes[profileID] - 1].sell_price;
  }

  /**
  * @dev set new price for asset (profile of NFT), price for which customer can buy
  * @param profileID, unique id of profiles
  */
  function setPriceById(uint32 profileID, uint256 new_price) external onlyOwnerOrPriceManager
  returns (bool) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    nftProfiles[_nftProfileIndexes[profileID] - 1].price = new_price;
    return true;
  }

  /**
  * @dev set new sell (buy back) price for asset (profile of NFT),
  * price for which customer can sell to us
  * @param profileID, unique id of profiles
  */
  function setSellPriceById(uint32 profileID, uint256 new_price) external onlyOwnerOrPriceManager
  returns (bool) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    nftProfiles[_nftProfileIndexes[profileID] - 1].sell_price = new_price;
    return true;
  }

  // for optimization, function to update both prices
  function updatePricesById(uint32 profileID, uint256 new_price, uint256 new_sell_price)
  external onlyOwnerOrPriceManager returns (bool) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    uint256 index = _nftProfileIndexes[profileID] - 1;
    nftProfiles[index].price = new_price;
    nftProfiles[index].sell_price = new_sell_price;
    return true;
  }

  /**
   * @dev get url by profileID from 'database'
   * @param profileID, unique id of profiles
   */
  function getUrlById(uint32 profileID) external view returns (string memory) {
    if (_nftProfileIndexes[profileID] == 0) return BAD_URL;
    return nftProfiles[_nftProfileIndexes[profileID] - 1].url;
  }

  function getLimitById(uint32 profileID) external view returns (uint32) {
    if (_nftProfileIndexes[profileID] == 0) return UNLIMITED;
    return nftProfiles[_nftProfileIndexes[profileID] - 1].limit;
  }

  /**
   * @dev accepts payment only in ETNA(!) for mint NFT & calls external contract
   * it is public function, i.e called by buyer via dApp
   * buyer selects profile (profileID), provides own wallet address (to)
   * and dApp provides available tokenId (for flexibility its calculation is not automatic on
   * smart contract level, but it is possible to implement) - > _nftContract.totalSupply()+1
   * why not recommended: outsite of smart contract with multiple simultaneous customers we can
   * instanteneusly on level of backend determinte next free id.
   * on CyclopsTokens smartcontract level it can be only calculated correctly after mint transaction is confirmed
   * here utility function is implemented which is used by backend ,getNextTokenId()
   * it is also possible to use setNextTokenId function (by owner) to reset token id if needed
   * normal use is dApp requests next token id (tid = getNextTokenId()) and after that
   * calls publicMint(profile, to, tid)
   * it allows different dApps use different token ids areas
   * like   dapp1: tid = getNextTokenId() + 10000
   *    dapp2: tid = getNextTokenId() + 20000
   */
  function buyNFT (      //'buy' == mint NFT token function, provides NFT token in exchange of ETNA
    uint32 profileID     //id of NFT profile
  ) external notContract returns (uint256) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    uint256 index = _nftProfileIndexes[profileID] - 1;
    require (nftProfiles[index].limit > 0, "The limit is over");
    nftProfiles[index].limit --;
    uint256 curPrice = nftProfiles[index].price;
    _nextTokenId ++;
    _nftProfileMinted[profileID] ++;
    _nftProfileIdsByTokenId[_nextTokenId] = profileID;
    require(_etnaTokenContract.transferFrom(msg.sender, address(this), curPrice));
    _nftContract.mint(msg.sender, _nextTokenId, nftProfiles[index].url);

    if (_internal_prices) {
      nftProfiles[index].price *= _price_curve + 100;
      nftProfiles[index].price /= 100;
      nftProfiles[index].sell_price *= _price_curve + 100;
      nftProfiles[index].sell_price /= 100;
    }

    emit Minted(profileID, _nextTokenId, msg.sender, curPrice);

    return _nextTokenId;
  }

  /**
    * @dev method allows collectible owner to sell it back for sell price
    * collectible is burned, amount of sell price returned to owner of collectible
    * tokenId -> profileID -> sell price
    */
  function sellNFTBack (uint256 tokenId) external notContract returns (bool) { //'sell' == burn, burns and returns ETNA to user
    require(_nftContract.ownerOf(tokenId) == msg.sender, "Ownership validation failed");
    uint32 profileID = _getProfileIdByTokenId(tokenId);
    require(profileID > 0, "NFT profile ID not found");
    uint256 index = _nftProfileIndexes[profileID] - 1;
    uint256 sellPrice = nftProfiles[index].sell_price;

    require(_etnaTokenContract.balanceOf(address(this)) >= sellPrice, "Insufficient ETNA on contract");
    if (_nftProfileIdsByTokenId[tokenId] > 0) delete _nftProfileIdsByTokenId[tokenId];
    nftProfiles[index].limit ++;
    _nftProfileMinted[profileID] --;
    _nftContract.burn(tokenId);
    if (_internal_prices) { //if we manage price curve internally
      nftProfiles[index].price *= 100 - _price_curve;
      nftProfiles[index].price /= 100;
      nftProfiles[index].sell_price *= 100 - _price_curve;
      nftProfiles[index].sell_price /= 100;
    }
    emit Burned(profileID, tokenId, msg.sender, sellPrice);

    require(_etnaTokenContract.transfer(msg.sender,  sellPrice), 'ETNA payment failed');
    return true;
  }

  function adminMint (   // mint for free as admin
    uint32 profileID,    // id of NFT profile
    address to,            //where to deliver
    uint256 tokenId          // tokenId
  ) external onlyOwnerOrPriceManager returns (uint256) {
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    require(_nftProfileIdsByTokenId[tokenId] == 0, 'NFT with this ID already exists');
    try _nftContract.ownerOf(tokenId) returns (address) {
      revert('NFT with this ID already exists');
    } catch {}
    require(to != address(0), 'Receiver address should not be zero');
    uint256 index = _nftProfileIndexes[profileID] - 1;
    _nftProfileMinted[profileID] ++;
    _nftProfileIdsByTokenId[tokenId] = profileID;
    _nftContract.mint(to, tokenId, nftProfiles[index].url);
    emit AdminMinted(profileID, tokenId, to, nftProfiles[index].price);

    return tokenId; //success, return generated tokenId (works if called by another contract)
  }

  function adminBurn (uint256 tokenId) external  onlyOwnerOrPriceManager
  returns(bool) {  //burn as admin
    uint32 profileID = _getProfileIdByTokenId(tokenId);
    require(profileID > 0, "NFT profile ID not found");
    uint256 index = _nftProfileIndexes[profileID] - 1;
    uint256 sellPrice = nftProfiles[index].sell_price;
    _nftProfileMinted[profileID] --;
    if (_nftProfileIdsByTokenId[tokenId] > 0) delete _nftProfileIdsByTokenId[tokenId];
    _nftContract.burn(tokenId);
    emit AdminBurned(profileID, tokenId, sellPrice);

    return true;
  }

  function _getTokenUrlById(uint256 tokenId) internal view returns(string memory) {
    try _nftContract.tokenURI(tokenId) returns (string memory url) {
      return url;
    } catch {}
    return BAD_URL;
  }

  function _getProfileIdByTokenId(uint256 tokenId) internal view returns(uint32) {
    if (_nftProfileIdsByTokenId[tokenId] == 0) {
      if (tokenId > _oldContractMaxId) return BAD_NFT_PROFILE_ID;
      string memory url = _getTokenUrlById(tokenId);
      return getProfileIdbyUrl(url);
    }
    return _nftProfileIdsByTokenId[tokenId];
  }

  function getProfileIdByTokenId(uint256 tokenId) external view returns(uint32) {
    return _getProfileIdByTokenId(tokenId);
  }

  function getProfileIdbyUrl(string memory url) public  view returns (uint32) {
    bytes32 urlHash = keccak256(bytes(url));
    if (_nftProfileIdsByUrl[urlHash] == 0) return BAD_NFT_PROFILE_ID;
    return _nftProfileIdsByUrl[urlHash];
  }

  function getTokenPriceByTokenId (uint256 tokenId) public view returns(uint256) {
    uint32 profileID = _getProfileIdByTokenId(tokenId);
    if (profileID == 0) return BAD_PRICE;
    if (profileID == BAD_NFT_PROFILE_ID) return BAD_PRICE;
    return nftProfiles[profileID - 1].sell_price;
  }

  /**
  * @dev returns contract tokens balance
  */
  function getContractTokensBalance() external view returns (uint256) {
    return _etnaTokenContract.balanceOf(address(this));
  }

  function depositTokens(uint256 amount) external onlyOwner returns (bool) {
    require(amount > 0, "Amount should be greater than zero");
    require(_etnaTokenContract.transferFrom(msg.sender, address(this), amount),
      'Etna payment failed');
    emit TokensDeposited(amount, owner());

    return true;
  }

  function withdrawTokens(address to, uint256 amount) external onlyOwner
  returns (bool) {
    require(amount > 0, "Amount should be greater than zero");
    require(to != address(0), 'Receiver address should not be zero');
    require(_etnaTokenContract.balanceOf(address(this)) >= amount,
      'Amount can not be greater than contract balance');
    require(_etnaTokenContract.transfer(to, amount), 'ETNA payment failed');
    emit TokensWithdrawn(amount, to);

    return true;
  }

  function getOldContractMaxId() external view returns(uint256) {
    return _oldContractMaxId;
  }

  function getOldContractMaxId(uint256 oldContractMaxId) external onlyOwner returns(bool) {
    _oldContractMaxId = oldContractMaxId;
    return true;
  }

  function allowMinting(uint32[] calldata profileIDs, address[] calldata recipients) external
    onlyOwnerOrPriceManager returns(bool) {
    require(profileIDs.length == recipients.length, 'Arrays should be of the same length');
    for (uint256 i = 0; i < profileIDs.length; i ++) {
      if (_nftProfileIndexes[profileIDs[i]] == 0) continue;
      _availableForMinting[profileIDs[i]][recipients[i]] = true;
    }
    return true;
  }

  function checkMintingAvailability(uint32 profileID, address recipient) external view returns (bool) {
    return _availableForMinting[profileID][recipient];
  }

  function mintAvailableNFT(uint32 profileID) external returns (uint256) {
    require(_availableForMinting[profileID][msg.sender], 'This NFT is not available for withdraw');
    require(_nftProfileIndexes[profileID] > 0, 'Profile with this ID does not exist');
    uint256 index = _nftProfileIndexes[profileID] - 1;

    _nextTokenId ++;
    _nftProfileMinted[profileID] ++;
    _nftProfileIdsByTokenId[_nextTokenId] = profileID;
    _availableForMinting[profileID][msg.sender] = false;
    _nftContract.mint(msg.sender, _nextTokenId, nftProfiles[index].url);
    emit AirdropMinted(profileID, _nextTokenId, msg.sender, nftProfiles[index].price);

    return _nextTokenId;
  }
}