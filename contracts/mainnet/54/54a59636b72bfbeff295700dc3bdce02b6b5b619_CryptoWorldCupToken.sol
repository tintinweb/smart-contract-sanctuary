pragma solidity ^0.4.23;

// Standard ERC721 functions import
contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

}

contract CryptoWorldCupToken is ERC721 {

  // ********************************************************************************************************
  //    EVENTS
  // ********************************************************************************************************
  // @dev events to catch with web3/js
  // ********************************************************************************************************

  /// @dev The NewPlayerCreated event is fired whenever a new Player comes into existence.
  event NewPlayerCreated(uint256 tokenId, uint256 id, string prename, string surname, address owner, uint256 price);

  /// @dev The PlayerWasSold event is fired whenever a token is sold.
  event PlayerWasSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string prename, string surname);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  ownership is assigned, including NewPlayerCreateds.
  event Transfer(address from, address to, uint256 tokenId);

  ///@dev Country won a game and all players prices increased by 5%
  event countryWonAndPlayersValueIncreased(string country, string prename, string surname);

  ///@dev New User has been registered
  event NewUserRegistered(string userName);

  // ********************************************************************************************************
  // Constants
  // ********************************************************************************************************
  // @dev Definition of constants
  // ********************************************************************************************************

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME = "CryptoWorldCup";
  string public constant SYMBOL = "CryptoWorldCupToken";

  //@dev network fee address
  address private netFee = 0x5e02f153d571C1FBB6851928975079812DF4c8cd;

  //@dev ether value to calculate the int-value prices
  uint256 public myFinneyValue =  100 finney;
  uint256 public myWeiValue = 1 wei;

  // presale boolean to enable selling
  bool public presaleIsRunning;

   uint256 public currentwealth;

   // The addresses of the accounts (or contracts) that can execute actions within each roles.
  address public ceoAddress;

  // ********************************************************************************************************
  // Tracking Variables
  // ********************************************************************************************************
  // @dev Needed for smoother web3 calls
  // ********************************************************************************************************
  uint256 public totalTxVolume = 0;
  uint256 public totalContractsAvailable = 0;
  uint256 public totalContractHolders = 0;
  uint256 public totalUsers = 0;

  // ********************************************************************************************************
  // Storage
  // ********************************************************************************************************
  // @dev Mappings for easier access
  // ********************************************************************************************************

  /// @dev A mapping from Player IDs to the address that owns them. All Players have
  ///  some valid owner address.
  mapping (uint256 => address) public PlayerIndexToOwner;

  // @dev A mapping from owner address to count of tokens that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.
  mapping (address => uint256) private ownershipTokenCount;

  /// @dev A mapping from PlayerIDs to an address that has been approved to call
  ///  transferFrom(). Each Player can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.
  mapping (uint256 => address) public PlayerIndexToApproved;

  // @dev A mapping from PlayerIDs to the price of the token.
  mapping (uint256 => uint256) private PlayerIndexToPrice;
  mapping (uint256 => uint256) private PlayerInternalIndexToGlobalIndex;

  //@dev A mapping from the UserIDs to the usernames.
  mapping (uint256 => address) private UserIDsToWallet;
  mapping (uint256 => string) private UserIDToUsername;
  mapping (address => uint256) private UserWalletToID;
  mapping (address => bool) private isUser;

  mapping (address => uint256) private addressWealth;

  mapping (address => bool) blacklist;

  mapping (uint256 => PlayerIDs) PlayerIDsToUniqueID;

  // ********************************************************************************************************
  // Individual datatypes
  // ********************************************************************************************************
  // @dev Structs to generate specific datatypes
  // ********************************************************************************************************
  struct Player {
    uint256 id;
    uint256 countryId;
    string country;
    string surname;
    string middlename;
    string prename;
    string position;
    uint256 age;
    uint64 offensive;
    uint64 defensive;
    uint64 totalRating;
    uint256 price;
    string pictureUrl;
    string flagUrl;
  }

  Player[] private players;

  struct User{
    uint256 id;
    address userAddress;
    string userName;
  }

  User[] private users;

  struct PlayerIDs {
        uint256 id;
        uint256 countryId;
  }

  PlayerIDs[] public PlayerIDsArrayForMapping;

  // ********************************************************************************************************
  // Access modifiers
  // ********************************************************************************************************
  // @dev No need for the same require anymore
  // ********************************************************************************************************
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

  modifier onlyDuringPresale(){
      require(presaleIsRunning);
      _;
  }

  // ********************************************************************************************************
  // Constructor & Needed stuff
  // ********************************************************************************************************
  // @dev Called exactly once during the creation of the contract
  // ********************************************************************************************************
  constructor() public {
    presaleIsRunning = true;
    ceoAddress = msg.sender;
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name() public pure returns (string) {
    return NAME;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

  // ********************************************************************************************************
  // ONLYCEO FUNKTIONS
  // ********************************************************************************************************
  // @dev All functions that are only executable by the owner of the contract
  // ********************************************************************************************************

  function endPresale() public onlyCEO{
    require(presaleIsRunning == true);
    presaleIsRunning = false;
  }


  function blackListUser(address _address) public onlyCEO{
      blacklist[_address] = true;
  }

  function deleteUser(address _address) public onlyCEO{

      uint256 userID = getUserIDByWallet(_address) + 1;
      delete users[userID];

      isUser[_address] = false;

      uint256 userIDForMappings = UserWalletToID[_address];

     delete UserIDsToWallet[userIDForMappings];
     delete UserIDToUsername[userIDForMappings];
     delete UserWalletToID[_address];

      totalUsers = totalUsers - 1;
  }

  function payout(address _to) public onlyCEO {
    _payout(_to);
  }

  // ********************************************************************************************************
  // ONLYCEO FUNCTIONS
  // ********************************************************************************************************
  // @dev All functions that are only executable by the owner of the contract
  // PLAYER CREATIN RELATED
  // ********************************************************************************************************

  function createPlayer(uint256 _id, uint256 _countryId, string _country, string _prename, string _middlename, string _surname, string _pictureUrl, string _flagUrl, address _owner, uint256 _price) public onlyCEO onlyDuringPresale{

    uint256 newPrice = SafeMath.mul(_price, myFinneyValue);

    Player memory _player = Player({
     id: _id,
     countryId: _countryId,
     country: _country,
     surname: _surname,
     middlename: _middlename,
     prename: _prename,
     price: newPrice,
     pictureUrl: _pictureUrl,
     flagUrl: _flagUrl,
     position: "",
     age: 0,
     offensive: 0,
     defensive: 0,
     totalRating: 0
    });

    uint256 newPlayerId = players.push(_player) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newPlayerId == uint256(uint32(newPlayerId)));

    emit NewPlayerCreated(newPlayerId, newPlayerId, _prename, _surname, _owner, _price);

    addMappingForPlayerIDs (newPlayerId, _id, _countryId );

    PlayerIndexToPrice[newPlayerId] = newPrice;
    PlayerInternalIndexToGlobalIndex[newPlayerId] = newPlayerId;

    currentwealth =   addressWealth[_owner];
    addressWealth[_owner] = currentwealth + newPrice;

    totalTxVolume = totalTxVolume + newPrice;

    // This will assign ownership, and also emit the Transfer event as
    // per ERC721 draft
    _transfer(address(0), _owner, newPlayerId);

    totalContractsAvailable = totalContractsAvailable;

    if(numberOfTokensOfOwner(_owner) == 0 || numberOfTokensOfOwner(_owner) == 1){
        totalContractHolders = totalContractHolders + 1;
    }
  }

  function deletePlayer (uint256 _uniqueID) public onlyCEO{
      uint256 arrayPos = _uniqueID + 1;
      address _owner = PlayerIndexToOwner[_uniqueID];

      currentwealth =   addressWealth[_owner];
    addressWealth[_owner] = currentwealth + priceOf(_uniqueID);

    totalContractsAvailable = totalContractsAvailable - 1;

    if(numberOfTokensOfOwner(_owner) != 0 || numberOfTokensOfOwner(_owner) == 1){
        totalContractHolders = totalContractHolders - 1;
    }

      delete players[arrayPos];
      delete PlayerIndexToOwner[_uniqueID];
      delete PlayerIndexToPrice[_uniqueID];

  }

  function adjustPriceOfCountryPlayersAfterWin(uint256 _tokenId) public onlyCEO {
    uint256 _price = SafeMath.mul(105, SafeMath.div(players[_tokenId].price, 100));
    uint256 playerInternalIndex = _tokenId;
    uint256 playerGlobalIndex = PlayerInternalIndexToGlobalIndex[playerInternalIndex];
    PlayerIndexToPrice[playerGlobalIndex] = _price;

    emit countryWonAndPlayersValueIncreased(players[_tokenId].country, players[_tokenId].prename, players[_tokenId].surname);
  }

  function adjustPriceAndOwnerOfPlayerDuringPresale(uint256 _tokenId, address _newOwner, uint256 _newPrice) public onlyCEO{
    require(presaleIsRunning);
    _newPrice = SafeMath.mul(_newPrice, myFinneyValue);
    PlayerIndexToPrice[_tokenId] = _newPrice;
    PlayerIndexToOwner[_tokenId] = _newOwner;
  }

  function addPlayerData(uint256 _playerId, uint256 _countryId, string _position, uint256 _age, uint64 _offensive, uint64 _defensive, uint64 _totalRating) public onlyCEO{

       uint256 _id = getIDMapping(_playerId, _countryId);

       players[_id].position = _position;
       players[_id].age = _age;
       players[_id].offensive = _offensive;
       players[_id].defensive = _defensive;
       players[_id].totalRating = _totalRating;
    }


    function addMappingForPlayerIDs (uint256 _uniquePlayerId, uint256 _playerId, uint256 _countryId ) private{

        PlayerIDs memory _playerIdStruct = PlayerIDs({
            id: _playerId,
            countryId: _countryId
        });

        PlayerIDsArrayForMapping.push(_playerIdStruct)-1;

        PlayerIDsToUniqueID[_uniquePlayerId] = _playerIdStruct;

    }

  // ********************************************************************************************************
  // Helper FUNCTIONS
  // ********************************************************************************************************
  // @dev All functions that make our life easier
  // ********************************************************************************************************

 /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

  function isUserBlacklisted(address _address) public view returns (bool){
      return blacklist[_address];
  }

   function getPlayerFrontDataForMarketPlaceCards(uint256 _tokenId) public view returns (
    uint256 _id,
    uint256 _countryId,
    string _country,
    string _surname,
    string _prename,
    uint256 _sellingPrice,
    string _picUrl,
    string _flagUrl
  ) {
    Player storage player = players[_tokenId];
    _id = player.id;
    _countryId = player.countryId;
    _country = player.country;
    _surname = player.surname;
    _prename = player.prename;
    _sellingPrice = PlayerIndexToPrice[_tokenId];
    _picUrl = player.pictureUrl;
    _flagUrl = player.flagUrl;

    return (_id, _countryId, _country, _surname, _prename, _sellingPrice, _picUrl, _flagUrl);

  }

    function getPlayerBackDataForMarketPlaceCards(uint256 _tokenId) public view returns (
    uint256 _id,
    uint256 _countryId,
    string _country,
    string _surname,
    string _prename,
    string _position,
    uint256 _age,
    uint64 _offensive,
    uint64 _defensive,
    uint64 _totalRating
  ) {
    Player storage player = players[_tokenId];
    _id = player.id;
    _countryId = player.countryId;
    _country = player.country;
    _surname = player.surname;
    _prename = player.prename;
    _age = player.age;

    _position = player.position;
    _offensive = player.offensive;
    _defensive = player.defensive;
    _totalRating = player.totalRating;

    return (_id, _countryId, _country, _surname, _prename, _position, _age, _offensive,_defensive, _totalRating);
  }

  /// For querying owner of token
  /// @param _tokenId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = PlayerIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return PlayerIndexToPrice[_tokenId];
  }

  function calcNetworkFee(uint256 _tokenId) public view returns (uint256 networkFee) {
    uint256 price = PlayerIndexToPrice[_tokenId];
    networkFee = SafeMath.div(price, 100);
    return networkFee;
  }

  function getLeaderBoardData(address _owner)public view returns (address _user, uint256 _token, uint _wealth){
      _user = _owner;
      _token = numberOfTokensOfOwner(_owner);
      _wealth = getWealthOfUser(_owner);
      return (_user, _token, _wealth);
  }

  // ********************************************************************************************************
  // GETTER FUNCTIONS
  // ********************************************************************************************************
  // @dev All functions that get us stuff
  // ********************************************************************************************************

  function getUserByID(uint256 _id) public view returns (address _wallet, string _username){
    _username = UserIDToUsername[_id];
    _wallet = UserIDsToWallet[_id];
    return (_wallet, _username);
  }

   function getUserWalletByID(uint256 _id) public view returns (address _wallet){
    _wallet = UserIDsToWallet[_id];
    return (_wallet);
  }

  function getUserNameByWallet(address _wallet) public view returns (string _username){
    require(isAlreadyUser(_wallet));
    uint256 _id = UserWalletToID[_wallet];
    _username = UserIDToUsername[_id];
    return _username;
  }

  function getUserIDByWallet(address _wallet) public view returns (uint256 _id){
    _id = UserWalletToID[_wallet];
    return _id;
  }

  function getUniqueIdOfPlayerByPlayerAndCountryID(uint256 _tokenId) public view returns (uint256 id){
      uint256 idOfPlyaer = players[_tokenId].id;
      return idOfPlyaer;
  }

  function getIDMapping (uint256 _playerId, uint256 _countryId) public view returns (uint256 _uniqueId){

        for (uint64 x=0; x<totalSupply(); x++){
            PlayerIDs memory _player = PlayerIDsToUniqueID[x];
            if(_player.id == _playerId && _player.countryId == _countryId){
                _uniqueId = x;
            }
        }

        return _uniqueId;
   }

  function getWealthOfUser(address _address) private view returns (uint256 _wealth){
    return addressWealth[_address];
  }

  // ********************************************************************************************************
  // PURCHASE FUNCTIONS
  // ********************************************************************************************************
  // @dev Purchase related stuff
  // ********************************************************************************************************

  function adjustAddressWealthOnSale(uint256 _tokenId, address _oldOwner, address _newOwner,uint256 _sellingPrice) private {
        uint256 currentOldOwnerWealth = addressWealth[_oldOwner];
        uint256 currentNewOwnerWealth = addressWealth[_newOwner];
        addressWealth[_oldOwner] = currentOldOwnerWealth - _sellingPrice;
        addressWealth[_newOwner] = currentNewOwnerWealth + PlayerIndexToPrice[_tokenId];
    }

  // Allows someone to send ether and obtain the token
  // HAS TOBE AMENDED SO THE FEE WILL SPLIT BETWEEN
  // 1. THE CURRENT OWNER OF THE CONTRACT
  // 2. THE PRIOR OWNERS OF THE CONTRACT
  // 3. (OPTIONAL) THE NETWORK FEE - BUT COULD BE OBSOLETE, IF WE ARE THE VERY FIRST OWNER OF EVERY CONTRACT
  function purchase(uint256 _tokenId) public payable {

    //check if presale is still running
    require(presaleIsRunning == false);

    address oldOwner = PlayerIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = PlayerIndexToPrice[_tokenId];
    uint256 payment = SafeMath.mul(99,(SafeMath.div(PlayerIndexToPrice[_tokenId],100)));
    uint256 networkFee  = calcNetworkFee(_tokenId);

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= sellingPrice);

    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    PlayerIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 110), 100);

    _transfer(oldOwner, newOwner, _tokenId);

    // Pay previous tokenOwner if owner is not contract
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment); //(1-0.06)
    }

    emit PlayerWasSold(_tokenId, sellingPrice, PlayerIndexToPrice[_tokenId], oldOwner, newOwner, players[_tokenId].prename, players[_tokenId].surname);

    msg.sender.transfer(purchaseExcess);

    //send network fee
    netFee.transfer(networkFee);

    totalTxVolume = totalTxVolume + msg.value;

    if(numberOfTokensOfOwner(msg.sender) == 1){
        totalContractHolders = totalContractHolders + 1;
    }

    if(numberOfTokensOfOwner(oldOwner) == 0){
        totalContractHolders = totalContractHolders - 1;
    }

    adjustAddressWealthOnSale(_tokenId, oldOwner, newOwner,sellingPrice);

  }

  /// @notice Allow pre-approved user to take ownership of a token
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = PlayerIndexToOwner[_tokenId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

  /// @param _owner The owner whose celebrity tokens we are interested in.
  /// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  ///  expensive (it walks the entire Players array looking for Players belonging to owner),
  ///  but it also returns a dynamic array, which is only supported for web3 calls, and
  ///  not contract-to-contract calls.
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
        // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalPlayers = totalSupply();
      uint256 resultIndex = 0;

      uint256 PlayerId;
      for (PlayerId = 0; PlayerId <= totalPlayers; PlayerId++) {
        if (PlayerIndexToOwner[PlayerId] == _owner) {
          result[resultIndex] = PlayerId;
          resultIndex++;
        }
      }
      return result;
    }
  }

  function numberOfTokensOfOwner(address _owner) private view returns(uint256 numberOfTokens){
      return tokensOfOwner(_owner).length;
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply() public view returns (uint256 total) {
    return players.length;
  }

  /// Owner initates the transfer of the token to another account
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

  /// Third-party initiates transfer of token from address _from to address _to
  /// @param _from The address for the token to be transferred from.
  /// @param _to The address for the token to be transferred to.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

  // ********************************************************************************************************
  // USER FUNCTIONS
  // ********************************************************************************************************
  // @dev User related stuff
  // ********************************************************************************************************
 /// For creating players

  function createNewUser(address _address, string _username) public {

    require(!blacklist[_address]);
    require(!isAlreadyUser(_address));

    uint256 userIdForMapping = users.length;

    User memory _user = User({
      id: userIdForMapping,
      userAddress: _address,
      userName: _username
    });


    uint256 newUserId = users.push(_user) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newUserId == uint256(uint32(newUserId)));

    emit NewUserRegistered(_username);

    UserIDsToWallet[userIdForMapping] = _address;
    UserIDToUsername[userIdForMapping] = _username;
    UserWalletToID[_address] = userIdForMapping;
    isUser[_address] = true;

    totalUsers = totalUsers + 1;
  }

  function isAlreadyUser(address _address) public view returns (bool status){
    if (isUser[_address]){
      return true;
    } else {
      return false;
    }
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }


  // ********************************************************************************************************
  //FIX FUNKTIONS
  // ********************************************************************************************************
  // @dev possibility to adjust single data fields of players during presale
  // ********************************************************************************************************

    function fixPlayerID(uint256 _uniqueID, uint256 _playerID) public onlyCEO onlyDuringPresale{
        players[_uniqueID].id = _playerID;
    }

      function fixPlayerCountryId(uint256 _uniqueID, uint256 _countryID) public onlyCEO onlyDuringPresale{
        players[_uniqueID].countryId = _countryID;
    }

    function fixPlayerCountryString(uint256 _uniqueID, string _country) public onlyCEO onlyDuringPresale{
        players[_uniqueID].country = _country;
    }

    function fixPlayerPrename(uint256 _uniqueID, string _prename) public onlyCEO onlyDuringPresale{
        players[_uniqueID].prename = _prename;
    }

    function fixPlayerMiddlename(uint256 _uniqueID, string _middlename) public onlyCEO onlyDuringPresale{
         players[_uniqueID].middlename = _middlename;
    }

    function fixPlayerSurname(uint256 _uniqueID, string _surname) public onlyCEO onlyDuringPresale{
         players[_uniqueID].surname = _surname;
    }

    function fixPlayerFlag(uint256 _uniqueID, string _flag) public onlyCEO onlyDuringPresale{
         players[_uniqueID].flagUrl = _flag;
    }

    function fixPlayerGraphic(uint256 _uniqueID, string _pictureUrl) public onlyCEO onlyDuringPresale{
         players[_uniqueID].pictureUrl = _pictureUrl;
    }



  // ********************************************************************************************************
  // LEGACY FUNCTIONS
  // ********************************************************************************************************
  // @dev
  // ********************************************************************************************************
 /// For creating players
  /*** PUBLIC FUNCTIONS ***/
  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    PlayerIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return PlayerIndexToApproved[_tokenId] == _to;
  }

  /// Check for token ownership
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == PlayerIndexToOwner[_tokenId];
  }

  /// For paying out balance on contract
  function _payout(address _to) private {
    if (_to == address(0)) {
        ceoAddress.transfer(address(this).balance);
    } else {
      _to.transfer(address(this).balance);
    }
  }

  /// @dev Assigns ownership of a specific Player to an address.
  function _transfer(address _from, address _to, uint256 _tokenId) private {
    // Since the number of Players is capped to 2^32 we can&#39;t overflow this
    ownershipTokenCount[_to]++;
    //transfer ownership
    PlayerIndexToOwner[_tokenId] = _to;

    // When creating new Players _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
      // clear any previously approved ownership exchange
      delete PlayerIndexToApproved[_tokenId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _tokenId);
  }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}