/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

/*
A contract of
   ____     __     __    _____    _____  
  (    )   (_ \   / _)  (_   _)  / ___/  
  / /\ \     \ \_/ /      | |   ( (__    
 ( (__) )     \   /       | |    ) __)   
  )    (      / _ \       | |   ( (      
 /  /\  \   _/ / \ \_    _| |__  \ \___  
/__(  )__\ (__/   \__)  /_____(   \____\ 
                                  Origin

Core Contract

www.axieorigin.com
docs.axieorigin.com
[email protected]

Axie Origin Foundation                
*/

pragma solidity 0.8.8;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

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

abstract contract SysCtrl is Context {

  address public communityAdmin;
  address public originGrant = address(0x0);
  uint256 public originTrade = 425;
  uint256 public lockTBid = (6*60*60);            
  bool public marketPaused = false;

  mapping (address => bool) public communityMinter;
  mapping (address => bool) public dnaScientist;
  mapping (address => bool) public communityGame;

  constructor() {
      communityAdmin = _msgSender();
  }

  modifier onlyAdmin() {
    require(_msgSender() == communityAdmin, "Only for admin community");
    _;
  }

  function sAdmin(address _new) public onlyAdmin {
    communityAdmin = _new;
  }

  modifier onlyMinter() {
    require(communityMinter[_msgSender()], "Only for minter contract group");
    _;
  }

  function addMinter(address _new) public onlyAdmin {
      communityMinter[_new] = true;
  }

  function removeMinter(address _remove) public onlyAdmin {
      communityMinter[_remove] = false;
  }

  modifier onlyDNAScientist() {
    require(dnaScientist[_msgSender()], "Only for Axies DNA Scientist");
    _;
  }

  function addScientist(address _new) public onlyAdmin {
      dnaScientist[_new] = true;
  }

  function removeScientist(address _remove) public onlyAdmin {
      dnaScientist[_remove] = false;
  }

  modifier onlyGame() {
    require(communityGame[_msgSender()], "Only for Axie Game Ctrl");
    _;
  }

  function addGame(address _new) public onlyAdmin {
      communityGame[_new] = true;
  }

  function removeGame(address _remove) public onlyAdmin {
      communityGame[_remove] = false;
  }

  function setting(address _originGrant, uint256 _originTrade, uint256 _lockTBid) external onlyAdmin {
      if(_originGrant != address(0)) originGrant = _originGrant;
      if(_originTrade > 0) originTrade = _originTrade;
      if(_lockTBid > 0) lockTBid = _lockTBid;
  }
      
  function pauseMarket(bool _paused) external onlyAdmin {
        marketPaused = _paused;
  }

}

abstract contract OriginProfile {
    
    event Profile(address indexed user, bytes32 indexed name, bytes32 ipfs);

    struct ProfileStruct {
        bytes32 name;
        bytes32 ipfs;  // IPFS Hash
    }

    mapping (address => ProfileStruct) public profile;
    mapping (bytes32 => address) public profileName;
   
    function setProfileName(bytes32 _name) external {
        require((profileName[_name] == address(0) || profileName[_name] == msg.sender), "Names must be unique");
        ProfileStruct storage _profile = profile[msg.sender];
       
        // clear old name
        profileName[_profile.name] = address(0);

        _profile.name = _name;
        profileName[_name] = msg.sender;

        emit Profile(msg.sender,_name,"");
    }

    function setProfile(bytes32 _name, bytes32 _ipfs) external {
        require((profileName[_name] == address(0) || profileName[_name] == msg.sender), "Names must be unique");
        ProfileStruct storage _profile = profile[msg.sender];
       
        // clear old name
        profileName[_profile.name] = address(0);

        _profile.name = _name;
        _profile.ipfs = _ipfs;
        profileName[_name] = msg.sender;
        emit Profile(msg.sender,_name,_ipfs);
    }
}

contract AxieOrigin is SysCtrl, OriginProfile, IERC721 {

    using SafeMath for uint256;

    event AxieBirthed(uint indexed axieId, address indexed owner, uint256 dna, uint256 laidEgg, uint256 bornAt, uint256 parents, address indexed nestVia);
    event AxieMorph(uint indexed AxieId, uint256 dna, uint256 dataGame, uint256 bornAt, address indexed NestVia);
    event AxieSpawned(uint indexed AxieId, uint256 dna, uint256 dataGame, uint256 parents, uint256 bornAt, address indexed NestVia);
    event AxieGame(uint indexed AxieId, uint256 dataGame, address indexed NestVia);
    event AxieOffered(address indexed owner, uint256 indexed axieId, uint256 minValue, address indexed toAddress);
    event AxieBid(address indexed owner, uint256 indexed axieId, uint256 value, uint256 countOffer, uint256 lockBid);
    event AxieBought(address indexed from, address indexed to, uint256 indexed axieId, uint256 value, uint256 countOffer, bool buyNow);
    event CancelOffer(uint256 indexed axieId, address indexed seller, uint256 countOffer);
    event CancelBid(uint256 indexed axieId, address indexed bidder, uint256 countOffer);
    event axieName(uint256 indexed axieId, bytes32 indexed name, address owner);
    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);

    struct AxieStruct {
        uint256 dna;
        uint256 dataGame;   // Laid egg date until birth. Eggs cannot participate in the game
        uint256 bornAt;
        uint256 parents;
        bytes32 name;
    }

    struct Offer {
        address seller;
        uint256 minValue;       // in Matic
        address onlySellTo;     // specify to sell only to a specific person
        uint256 countOffer;
    }

    struct Bid {
        address bidder;
        uint256 value;
        uint256 countOffer;
        uint256 lockBid;        
    }

    struct Balances {
        uint256 available;
        uint256 trade;
    }

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping (uint256 => AxieStruct) internal axies;
    mapping (uint256 => Offer) public axieForSale;
    mapping (uint256 => Bid) public axieBids;
    mapping (address => Balances) public balances;

    mapping (uint256 => address) internal idToOwner;
    mapping (uint256 => address) internal idToApproval;
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    mapping(address => uint256[]) internal ownerToIds;
    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Axie Origin";
    string internal nftSymbol = unicode"⚇";
    string internal uriPrefix = "https://api.axieorigin.com/metadata/";

    uint256 public currentAxie = 0;

    bool private reentrancyLock = false;
    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "Cannot operate.");
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender], "Cannot transfer."
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Invalid token.");
        _;
    }

    modifier onlyOwner(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender, "Not the owner of this Axie");
        _;
    }

    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

    function setURI(string memory _uri) public onlyAdmin {
      uriPrefix = _uri;
    }


    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Wrong from address.");
        require(_to != address(0), "Cannot send to 0x0.");
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external override canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) external view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];

        _cancelOffer(_tokenId);
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    //////////////////////////
    //// Axie Origin Sys  ////
    //////////////////////////

    function birthAxie(address _to, uint256 _dna, uint256 _bornAt, uint256 _parents) external onlyMinter returns (uint256) {
        require(_bornAt > block.timestamp,"Premature birth is not allowed");
        return _mint(_to, _dna, _bornAt, _parents);
    }

    // Manual Morphing
    function axieMorph(uint256 _axieId, uint256 _dna, uint256 _dataGame) external onlyDNAScientist validNFToken(_axieId) {
        AxieStruct storage _axie = axies[_axieId];
        require(_axie.bornAt <= block.timestamp,"It's not birth time yet");
        _axie.dna = _dna;
        _axie.dataGame = _dataGame>0?_dataGame:_axie.dataGame;
        _axie.bornAt = block.timestamp;
        emit AxieMorph(_axieId, _dna, _axie.dataGame, _axie.bornAt, _msgSender());
    }

    function dnaSpawned(uint256 _axieId, uint256 _dna, uint256 _dataGame, uint256 _parents, uint256 _bornAt) external onlyDNAScientist validNFToken(_axieId) {
        AxieStruct storage _axie = axies[_axieId];
        _axie.dna = _dna>0?_dna:_axie.dna;
        _axie.dataGame = _dataGame>0?_dataGame:_axie.dataGame;
        _axie.parents = _parents>0?_parents:_axie.parents;
        _axie.bornAt = _bornAt>0?_bornAt:_axie.bornAt;
        emit AxieSpawned(_axieId, _axie.dna, _axie.dataGame, _parents, _bornAt, _msgSender());
    }

    function gameChange(uint256 _axieId, uint256 _dataGame) external onlyGame validNFToken(_axieId) {
        AxieStruct storage _axie = axies[_axieId];
        require(!isEgg(_axieId),"Only adult Axies can play");
        _axie.dataGame = _dataGame;
        emit AxieGame(_axieId, _axie.dataGame, _msgSender());
    }

    function registerAxie(uint256 _axieId, bytes32 _name) external validNFToken(_axieId) onlyOwner(_axieId){
        require(!isEgg(_axieId),"Only adult Axies can register");
        AxieStruct storage _axie = axies[_axieId];
        require(_axie.name == '',"This axie has already been registered");
        _axie.name = _name;
        emit axieName(_axieId, _name, _msgSender());
    }
   
    function _addBreed(uint256 _axieId) internal validNFToken(_axieId) returns(uint256 breed){
       AxieStruct storage _axie = axies[_axieId];
       uint momdad = uint256(uint96(_axie.parents));
       breed = uint256(uint8(_axie.parents>>96));
       breed++;
       _axie.parents = uint256(momdad);
       _axie.parents |= breed<<96;  
    }
    
    function _getParents(uint256 _axieId) internal view validNFToken(_axieId) returns (uint256 mom, uint256 dad, uint256 breed) {
       AxieStruct storage _axie = axies[_axieId];
       mom   = uint256(uint48(_axie.parents));
       dad   = uint256(uint48(_axie.parents>>48));
       breed = uint256(uint8(_axie.parents>>96));
    }
    
    function _mint(address _to, uint256 _dna, uint256 _bornAt, uint256 parents) internal returns (uint) {
        require(_to != address(0), "Cannot mint to 0x0.");

        currentAxie++;
        _addNFToken(_to, currentAxie);

        AxieStruct storage _axie = axies[currentAxie];
        _axie.dna = _dna;
        _axie.dataGame = block.timestamp;
        _axie.bornAt = _bornAt;
        _axie.parents = parents;

        if(parents > 0){
          _addBreed(uint256(uint48(_axie.parents)));
          _addBreed(uint256(uint48(_axie.parents>>48)));
        }
        
        emit AxieBirthed(currentAxie, _to, _dna, _axie.dataGame, _bornAt, parents, _msgSender());
        emit Transfer(address(0), _to, currentAxie);
        return currentAxie;
    }
    
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), "Cannot add, already owned.");
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, "Incorrect owner.");
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, "Incorrect owner.");
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return currentAxie;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index >= 0 && index < currentAxie);
        return index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    function getAxie(uint256 _axieId) external view validNFToken(_axieId) returns(
        address _owner,
        uint256 _dna,
        uint256 _dataGame,
        uint256 _bornAt,
        uint256 _mon,
        uint256 _dad,
        uint256 _breed,
        bytes32 _name,
        uint256 _minValue
    ) {
         AxieStruct memory _axie = axies[_axieId];
         Offer memory offer = axieForSale[_axieId];
         _owner = idToOwner[_axieId];
         _dna = _axie.dna;
         _dataGame = _axie.dataGame;
         _bornAt = _axie.bornAt;
         (_mon,_dad,_breed) = _getParents(_axieId);
         _name = _axie.name;
         _minValue = offer.minValue;
    }

    function isEgg(uint256 _axieId) public view validNFToken(_axieId) returns(bool _isEgg) {
         if(axies[_axieId].dna < 1024 || axies[_axieId].bornAt > block.timestamp)
             _isEgg = true;
         return(_isEgg);
    }

    //// Metadata

    /**
      * @dev Converts a `uint256` to its ASCII `string` representation.
      */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return _name Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _axieId Id for which we want uri.
     * @return _tokenId URI of _tokenId.
     */
    function tokenURI(uint256 _axieId) external view validNFToken(_axieId) returns (string memory) {
        return string(abi.encodePacked(uriPrefix, toString(_axieId)));
    }

    
    //////////////////////////
    //// Marketplace      ////
    //////////////////////////

    function offerAxieForSale(uint256 _axieId, uint256 _minSalePrice) external validNFToken(_axieId) onlyOwner(_axieId) reentrancyGuard {
        require(!marketPaused);
         _offerAxieForSale(_axieId, _minSalePrice, address(0x0));
    }

    function offerAxieForSaleToAddress(uint256 _axieId, uint256 _minSalePrice, address _toAddress) external validNFToken(_axieId) onlyOwner(_axieId) reentrancyGuard{
       require(!marketPaused);
        _offerAxieForSale(_axieId, _minSalePrice, _toAddress);
    }

    function bidForAxie(uint256 _axieId, uint256 _value) external payable validNFToken(_axieId) reentrancyGuard {
        require(!marketPaused);
        Offer memory offer = axieForSale[_axieId];
        Bid memory bidExisting = axieBids[_axieId];
        
        require(_value > 0,"Bid value cannot be zero");
        require(offer.minValue > 0, "Axie not actually for sale");
        require(offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender, "Axie not supposed to be sold to this user");
        require(_value > bidExisting.value && (balances[msg.sender].available+msg.value) >= _value,"Insufficient funds to execute bid");
        require(offer.seller == idToOwner[_axieId], "Seller no longer owner of axie");
       
        // Make deposit
        if(msg.value > 0) {
            balances[msg.sender].available = balances[msg.sender].available.add(msg.value);
            emit Deposit(msg.sender, msg.value);
        }

        // refund value old bid
        if(bidExisting.value > 0){
            balances[bidExisting.bidder].available = balances[bidExisting.bidder].available.add(bidExisting.value);
            balances[bidExisting.bidder].trade = balances[bidExisting.bidder].trade.sub(bidExisting.value);
        }

        if(_value >= offer.minValue){
           balances[msg.sender].available = balances[msg.sender].available.sub(offer.minValue);
           balances[msg.sender].trade = balances[msg.sender].trade.add(offer.minValue);
           _makerSell(offer.seller,msg.sender,_axieId,offer.minValue,true);
        } else {
            balances[msg.sender].available = balances[msg.sender].available.sub(_value);
            balances[msg.sender].trade = balances[msg.sender].trade.add(_value);
            axieBids[_axieId] = Bid(msg.sender, _value, offer.countOffer,block.timestamp+lockTBid);
            emit AxieBid(msg.sender,_axieId, _value, offer.countOffer,block.timestamp+lockTBid);   
        }   
    }

    function acceptBidForAxie(uint _axieId, uint _minPrice) public validNFToken(_axieId) onlyOwner(_axieId) reentrancyGuard {
        require(!marketPaused);
        Bid memory bid = axieBids[_axieId];
        require(bid.value > 0,"Bid not valid");
        require(bid.value >= _minPrice,"Bid less than the minimum accepted");
        _makerSell(msg.sender, bid.bidder, _axieId, bid.value, false);
    }

    function cancelOffer(uint _axieId) external validNFToken(_axieId) onlyOwner(_axieId) {
        require(!marketPaused);
        _cancelOffer(_axieId);
    }

    function cancelBid(uint _axieId) external validNFToken(_axieId) {
        require(!marketPaused);
        require(axieBids[_axieId].bidder == msg.sender,"Bidder no longer owner of bid");
        require(axieBids[_axieId].lockBid <= block.timestamp,"Time term not reached");
        _cancelBid(_axieId);
    }

    function _cancelOffer(uint _axieId) private {
        Offer memory offer = axieForSale[_axieId];
        if(offer.minValue > 0) {
            _cancelBid(_axieId);
            emit CancelOffer(_axieId, offer.seller, offer.countOffer);
            axieForSale[_axieId] = Offer(address(0), 0, address(0), 0);
        }
    }

    function _cancelBid(uint _axieId) private {
        Bid memory bidExisting = axieBids[_axieId];
        if(bidExisting.value > 0) {
            balances[bidExisting.bidder].available = balances[bidExisting.bidder].available.add(bidExisting.value);
            balances[bidExisting.bidder].trade = balances[bidExisting.bidder].trade.sub(bidExisting.value);
            axieBids[_axieId] = Bid(address(0), 0, 0, 0);
            emit CancelBid(_axieId, bidExisting.bidder, bidExisting.countOffer);
        }
    }

    function _offerAxieForSale(uint256 _axieId, uint256 _minSalePrice, address _toAddress) private {
        Bid memory bidExisting = axieBids[_axieId];

        require(_minSalePrice > 0,"Minimum price cannot be zero");

        if (_minSalePrice <= bidExisting.value) {
            _makerSell(msg.sender, bidExisting.bidder, _axieId, bidExisting.value, false);
        } else {
            axieForSale[_axieId] = Offer(msg.sender, _minSalePrice, _toAddress, block.number);
            emit AxieOffered(msg.sender, _axieId, _minSalePrice, _toAddress);
        }
    }

    function _makerSell(address _from, address _to, uint256 _axieId, uint256 _value, bool _buyNow) private {
        
        uint256 countOffer = axieForSale[_axieId].countOffer;

        axieForSale[_axieId] = Offer(address(0), 0, address(0), 0);
        axieBids[_axieId] = Bid(address(0), 0, 0, 0);

        uint256 commission = (_value.div(10000)).mul(originTrade);

        balances[_from].available = balances[_from].available.add(_value.sub(commission));
        balances[_to].trade = balances[_to].trade.sub(_value);
       
        (bool success, ) = originGrant.call{value:commission}("");
        require(success);

        emit AxieBought(_from, _to, _axieId, _value, countOffer, _buyNow);
        _transfer(_to, _axieId);
    }

    function withdraw(uint256 amount) external reentrancyGuard {
        require(!marketPaused);
        require(amount <= balances[msg.sender].available);
        balances[msg.sender].available = balances[msg.sender].available.sub(amount);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
    }

    function deposit() external payable {
        balances[msg.sender].available = balances[msg.sender].available.add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}

// End of Axie Origin Core contrat