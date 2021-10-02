/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

/**
 * Minimal interface to Cryptopunks for verifying ownership during Community Grant.
 */
/*
interface Cryptopunks {
    function punkIndexToAddress(uint index) external view returns(address);
}
*/
interface ERC721TokenReceiver
{
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


  modifier onlyMint() {
    require(communityMinter[_msgSender()], "Only for mint contract group");
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
    require(communityGame[_msgSender()], "Only for Axies DNA Scientist");
    _;
  }

  function addGame(address _new) public onlyAdmin {
      communityGame[_new] = true;
  }

  function removeGame(address _remove) public onlyAdmin {
      communityGame[_remove] = false;
  }


  function sOriginGrant(address _new) external onlyAdmin {
        originGrant = _new;
  }

  function sOriginTrade(uint256 _originTrade) external onlyAdmin {
        originTrade = _originTrade;
  }

  function pauseMarket(bool _paused) external onlyAdmin {
        marketPaused = _paused;
  }

}

contract OgProfile {
    
    event Profile(address indexed user, bytes32 indexed name, bytes32 ipfs);

    struct ProfileStruct {
        bytes32 name;
        bytes32 ipfs;  // IPFS Hash
    }
    mapping (address => ProfileStruct) public profile;
    mapping (bytes32 => address) public profileName;
   
    function setProfileName(bytes32 _name) external {
        require((profileName[_name] == address(0) || profileName[_name] == msg.sender),"Names must be unique");
        ProfileStruct storage _profile = profile[msg.sender];
        _profile.name = _name;
        profileName[_name] = msg.sender;

        emit Profile(msg.sender,_name,"");
    }

    function setProfile(bytes32 _name, bytes32 _ipfs) external {
        require((profileName[_name] == address(0) || profileName[_name] == msg.sender),"Names must be unique");
        ProfileStruct storage _profile = profile[msg.sender];
        _profile.name = _name;
        _profile.ipfs = _ipfs;
        profileName[_name] = msg.sender;
        emit Profile(msg.sender,_name,_ipfs);
    }
}


contract OgTest is SysCtrl, IERC721 {

    using SafeMath for uint256;

    /**
     * Event emitted when minting a new NFT.
     */
    event AxieBirthed(uint indexed axieId, address indexed owner, uint256 dna, uint256 laidEgg, uint256 bornAt, address indexed nestVia);

    event AxieIncubator(uint indexed AxieId, uint256 dna, uint256 dataGame, uint256 bornAt, address indexed NestVia);
    event AxieSpawned(uint indexed AxieId, uint256 dna, uint256 dataGame, address indexed NestVia);
    event AxieGame(uint indexed AxieId, uint256 dataGame, address indexed NestVia);

    event AxieOffered(address indexed owner, uint256 indexed axieId, uint256 minValue, address indexed toAddress);

    event AxieBid(address indexed owner, uint256 indexed axieId, uint256 value, uint256 countOffer);
   
    event AxieBought(address indexed from, address indexed to, uint256 indexed axieId, uint256 value, uint256 countOffer, bool buyNow);

    event CancelSell(uint256 indexed _axieId, address indexed seller, uint256 countOffer);
   
    event CancelBid(uint256 indexed _axieId, address indexed bidder, uint256 countOffer);


    /**
     * Event emitted when MATIC is deposited into the contract.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * Event emitted when MATIC is withdrawn from the contract.
     */
    event Withdraw(address indexed account, uint amount);


    struct AxieStruct {
        uint256 dna;
        uint256 dataGame;  // Laid egg date until birth. Eggs cannot participate in the game
        uint256 bornAt;
        uint256 parents;
        bytes32 name;
        /* OBS - Criar funcao para criar nome e SCI alterar parents*/
    }

    struct Offer {
        address seller;
        uint256 minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
        uint256 countOffer;
    }

    struct Bid {
        address bidder;
        uint256 value;
        uint256 countOffer;
    }

    struct Balances {
        uint256 available;
        uint256 trade;
    }

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping (uint256 => AxieStruct) public axies;
    mapping (uint256 => Offer) public axieForSale;
    mapping (uint256 => Bid) public axieBids;
    mapping (address => Balances) public balances;

    mapping (uint256 => address) internal idToOwner;

    mapping (uint256 => address) internal idToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Test";
    string internal nftSymbol = unicode"⚇";
    string internal uriPrefix = "https://localhost:8080/metadata/";


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
        //beneficiary = _beneficiary;
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
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function birthAxie(address _to, uint256 _dna, uint256 _bornAt) external onlyMint returns (uint256) {
        require(_bornAt > block.timestamp,"Premature birth is not allowed");
        return _mint(_to, _dna, _bornAt);
    }

    // V Morphing automatic
    
    function incubatorAxie(uint256 _axieId, uint256 _dna, uint256 _dataGame) external onlyDNAScientist validNFToken(_axieId) {
        AxieStruct storage _axie = axies[_axieId];
        require(_axie.bornAt <= block.timestamp,"It's not birth time yet");
        _axie.dna = _dna;
        _axie.dataGame = _dataGame>0?_dataGame:_axie.dataGame;
        _axie.bornAt = block.timestamp;
        emit AxieIncubator(_axieId, _dna, _axie.dataGame, _axie.bornAt, _msgSender());
    }

    function dnaSpawned(uint256 _axieId, uint256 _dna, uint256 _dataGame) external onlyDNAScientist validNFToken(_axieId) {
        AxieStruct storage _axie = axies[_axieId];
        _axie.dna = _dna>0?_dna:_axie.dna;
        _axie.dataGame = _dataGame>0?_dataGame:_axie.dataGame;
        emit AxieSpawned(_axieId, _axie.dna, _axie.dataGame, _msgSender());
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
    }
    
    function _mint(address _to, uint256 _dna, uint256 _bornAt) internal returns (uint) {
        require(_to != address(0), "Cannot mint to 0x0.");

        currentAxie++;
        _addNFToken(_to, currentAxie);

        AxieStruct storage _axie = axies[currentAxie];
        _axie.dna = _dna;
        _axie.dataGame = block.timestamp;
        _axie.bornAt = _bornAt;
        
        emit AxieBirthed(currentAxie, _to, _dna, _axie.dataGame, _bornAt, _msgSender());
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

    function getAxie(uint256 _axieId) external view validNFToken(_axieId) returns(address,uint256,uint256,uint256,uint256,bytes32) {
         AxieStruct storage _axie = axies[_axieId];

         return(idToOwner[_axieId],_axie.dna,_axie.dataGame,_axie.bornAt,_axie.parents,_axie.name);
    }

    function isEgg(uint256 _axieId) public view validNFToken(_axieId) returns(bool _isEgg) {
         if(axies[_axieId].dna < 512 || axies[_axieId].bornAt > block.timestamp)
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

    
    // New Market

    
    function offerAxieForSale(uint256 _axieId, uint256 _minSalePrice) external validNFToken(_axieId) onlyOwner(_axieId) {
         _offerAxieForSale(_axieId, _minSalePrice, address(0x0));
    }

    /**
      @dev Offers a axie for sale to a specific address
      @param _axieId - Axie for sell
      @param _minSalePrice - Minimum value for sale
      @param _toAddress - Specific address for sell
    */
    function offerAxieForSaleToAddress(uint256 _axieId, uint256 _minSalePrice, address _toAddress) external validNFToken(_axieId) onlyOwner(_axieId) {
        _offerAxieForSale(_axieId, _minSalePrice, _toAddress);
    }

   /**
      @dev Buy a punk offered for sale
      @param _axieId - Axie to bid/buy
    */
    function bidForAxie(uint256 _axieId, uint256 _value) external payable validNFToken(_axieId) reentrancyGuard {
        Offer memory offer = axieForSale[_axieId];
        Bid memory bidExisting = axieBids[_axieId];
        
        require(_value > 0,"Bid value cannot be zero");
        require(offer.minValue > 0, "Axie not actually for sale");
        require(offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender, "Axie not supposed to be sold to this user");
        require(_value > bidExisting.value && (balances[msg.sender].available+msg.value) >= _value,"Insufficient funds to execute bid");
        require(offer.seller == idToOwner[_axieId],"Seller no longer owner of axie");
       
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
           makerSell(offer.seller,msg.sender,_axieId,offer.minValue,true);
        } else {
            balances[msg.sender].available = balances[msg.sender].available.sub(_value);
            balances[msg.sender].trade = balances[msg.sender].trade.add(_value);
            axieBids[_axieId] = Bid(msg.sender, _value, offer.countOffer);
            emit AxieBid(msg.sender,_axieId, _value, offer.countOffer);   
        }   
    }


    function acceptBidForAxie(uint _axieId, uint _minPrice) public validNFToken(_axieId) onlyOwner(_axieId) reentrancyGuard {
        Offer memory offer = axieForSale[_axieId];
        Bid memory bid = axieBids[_axieId];
        require(bid.value > 0,"Bid not valid");
        require(bid.value >= _minPrice,"Bid less than the minimum accepted");
        require(bid.countOffer == offer.countOffer,"Bid not valid, other Offer");

        makerSell(msg.sender, bid.bidder, _axieId, bid.value, false);
    }

    function cancelSell(uint _axieId) external validNFToken(_axieId) onlyOwner(_axieId) reentrancyGuard {
        Offer memory offer = axieForSale[_axieId];
        Bid memory bidExisting = axieBids[_axieId];
        
        // refund Bids existing
        if(bidExisting.value > 0){
            balances[bidExisting.bidder].available = balances[bidExisting.bidder].available.add(bidExisting.value);
            balances[bidExisting.bidder].trade = balances[bidExisting.bidder].trade.sub(bidExisting.value);
        }

        axieForSale[_axieId] = Offer(address(0), 0, address(0), 0);
        axieBids[_axieId] = Bid(address(0), 0, 0);

        emit CancelSell(_axieId, msg.sender, offer.countOffer);

    }

    function cancelBid(uint _axieId) external validNFToken(_axieId) {
     
        Bid memory bidExisting = axieBids[_axieId];

        require(bidExisting.bidder == msg.sender,"Bidder no longer owner of bid");
        
        balances[bidExisting.bidder].available = balances[bidExisting.bidder].available.add(bidExisting.value);
        balances[bidExisting.bidder].trade = balances[bidExisting.bidder].trade.sub(bidExisting.value);

        axieBids[_axieId] = Bid(address(0), 0, 0);
        emit CancelBid(_axieId, msg.sender, bidExisting.countOffer);

    }

    /* Internal functions */

   /**
      @dev Offers a axie for sale
      @param _axieId - Axie for sell
      @param _minSalePrice - Minimum value for sale
      @param _toAddress - Specific address for sell or 0x0 for all
    */
    function _offerAxieForSale(uint256 _axieId, uint256 _minSalePrice, address _toAddress) private {
        Bid memory bidExisting = axieBids[_axieId];

        require(_minSalePrice > 0,"Minimum price cannot be zero");

        if (_minSalePrice <= bidExisting.value) {
            makerSell(msg.sender, bidExisting.bidder, _axieId, bidExisting.value, false);
        } else {
            axieForSale[_axieId] = Offer(msg.sender, _minSalePrice, _toAddress, block.number);
            emit AxieOffered(msg.sender, _axieId, _minSalePrice, _toAddress);
        }
    }



    // Adcionar a comissao na funcao abaixo
    function makerSell(address _from, address _to, uint256 _axieId, uint256 _value, bool _buyNow) private reentrancyGuard {
        
        uint256 countOffer = axieForSale[_axieId].countOffer;

        axieForSale[_axieId] = Offer(address(0), 0, address(0), 0);
        axieBids[_axieId] = Bid(address(0), 0, 0);

        uint256 commission = (_value.div(10000)).mul(originTrade);

        balances[_from].available = balances[_from].available.add(_value.sub(commission));
        balances[_to].trade = balances[_to].trade.sub(_value);
       
        (bool success, ) = originGrant.call{value:commission}("");
        require(success);

        emit AxieBought(_from, _to, _axieId, _value, countOffer, _buyNow);
        _transfer(_to, _axieId);
    }


    function withdraw(uint256 amount) external reentrancyGuard {
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