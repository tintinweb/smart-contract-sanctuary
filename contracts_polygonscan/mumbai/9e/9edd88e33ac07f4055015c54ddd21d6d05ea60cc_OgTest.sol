/**
 *Submitted for verification at polygonscan.com on 2021-09-06
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


contract OgTest is SysCtrl, IERC721 {

    using SafeMath for uint256;

    /**
     * Event emitted when minting a new NFT.
     */
    event AxieBirthed(uint indexed AxieID, address indexed owner, uint256 dna, uint256 laidEgg, uint256 bornAt, address indexed NestVia);

    event AxieIncubator(uint indexed AxieID, uint256 dna, uint256 dataGame, uint256 bornAt, address indexed NestVia);
    event AxieSpawned(uint indexed AxieID, uint256 dna, uint256 dataGame, address indexed NestVia);
    event AxieGame(uint indexed AxieID, uint256 dataGame, address indexed NestVia);

    /**
     * Event emitted when a trade is executed.
     */
    event Trade(bytes32 indexed hash, address indexed maker, address taker, uint makerWei, uint[] makerIds, uint takerWei, uint[] takerIds);

    /**
     * Event emitted when ETH is deposited into the contract.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * Event emitted when ETH is withdrawn from the contract.
     */
    event Withdraw(address indexed account, uint amount);

    /**
     * Event emitted when a trade offer is cancelled.
     */
    event OfferCancelled(bytes32 hash);

    /**
     * Event emitted when the public sale begins.
     */
    //event SaleBegins();

    /**
     * Event emitted when the community grant period ends.
     */
    //event CommunityGrantEnds();

    struct AxieStruct {
        uint256 dna;
        uint256 dataGame;  // Laid egg date until birth. Eggs cannot participate in the game
        uint256 bornAt;
        //bytes32 name;
        //uint256 parents;
        /* OBS Criar um campo guardar dados dos pais e o nome do axie */
    }

    mapping (uint256 => AxieStruct) public axies;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping (uint256 => address) internal idToOwner;

    //mapping (uint256 => uint256) public creatorNftMints;

    mapping (uint256 => address) internal idToApproval;

    mapping (address => mapping (address => bool)) internal ownerToOperators;

    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    string internal nftName = "Test";
    string internal nftSymbol = unicode"⚇";
    string internal uriPrefix = "https://localhost:8080/metadata/";


    uint256 public currentAxie = 0;

    //// Random index assignment
    uint internal nonce = 0;


    //// Market
    mapping (address => uint256) public ethBalance;
    mapping (bytes32 => bool) public cancelledOffers;

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

    function getAxie(uint256 _axieId) external view validNFToken(_axieId) returns(address,uint256,uint256,uint256) {
         AxieStruct storage _axie = axies[_axieId];
         return(idToOwner[_axieId],_axie.dna,_axie.dataGame,_axie.bornAt);
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
     * @param _tokenId Id for which we want uri.
     * @return _tokenId URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(uriPrefix, toString(_tokenId)));
    }





    //// MARKET

    struct Offer {
        address maker;
        address taker;
        uint256 makerWei;
        uint256[] makerIds;
        uint256 takerWei;
        uint256[] takerIds;
        uint256 expiry;
        uint256 salt;
    }

    function hashOffer(Offer memory offer) private pure returns (bytes32){
        return keccak256(abi.encode(
                    offer.maker,
                    offer.taker,
                    offer.makerWei,
                    keccak256(abi.encodePacked(offer.makerIds)),
                    offer.takerWei,
                    keccak256(abi.encodePacked(offer.takerIds)),
                    offer.expiry,
                    offer.salt
                ));
    }

    function hashToSign(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt) public pure returns (bytes32) {
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        return hashOffer(offer);
    }

    function hashToVerify(Offer memory offer) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOffer(offer)));
    }

    function verify(address signer, bytes32 hash, bytes memory signature) internal pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        return signer == ecrecover(hash, v, r, s);
    }

    function tradeValid(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt, bytes memory signature) view public returns (bool) {
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        // Check for cancellation
        bytes32 hash = hashOffer(offer);
        require(cancelledOffers[hash] == false, "Trade offer was cancelled.");
        // Verify signature
        bytes32 verifyHash = hashToVerify(offer);
        require(verify(offer.maker, verifyHash, signature), "Signature not valid.");
        // Check for expiry
        require(block.timestamp < offer.expiry, "Trade offer expired.");
        // Only one side should ever have to pay, not both
        require(makerWei == 0 || takerWei == 0, "Only one side of trade must pay.");
        // At least one side should offer tokens
        require(makerIds.length > 0 || takerIds.length > 0, "One side must offer tokens.");
        // Make sure the maker has funded the trade
        require(ethBalance[offer.maker] >= offer.makerWei, "Maker does not have sufficient balance.");
        // Ensure the maker owns the maker tokens
        for (uint i = 0; i < offer.makerIds.length; i++) {
            require(idToOwner[offer.makerIds[i]] == offer.maker, "At least one maker token doesn't belong to maker.");
        }
        // If the taker can be anybody, then there can be no taker tokens
        if (offer.taker == address(0)) {
            // If taker not specified, then can't specify IDs
            require(offer.takerIds.length == 0, "If trade is offered to anybody, cannot specify tokens from taker.");
        } else {
            // Ensure the taker owns the taker tokens
            for (uint i = 0; i < offer.takerIds.length; i++) {
                require(idToOwner[offer.takerIds[i]] == offer.taker, "At least one taker token doesn't belong to taker.");
            }
        }
        return true;
    }

    function cancelOffer(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt) external {
        require(maker == msg.sender, "Only the maker can cancel this offer.");
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        bytes32 hash = hashOffer(offer);
        cancelledOffers[hash] = true;
        emit OfferCancelled(hash);
    }

    function acceptTrade(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt, bytes memory signature) external payable reentrancyGuard {
        require(!marketPaused, "Market is paused.");
        require(msg.sender != maker, "Can't accept ones own trade.");
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        if (msg.value > 0) {
            ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
            emit Deposit(msg.sender, msg.value);
        }
        require(offer.taker == address(0) || offer.taker == msg.sender, "Not the recipient of this offer.");
        require(tradeValid(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt, signature), "Trade not valid.");
        require(ethBalance[msg.sender] >= offer.takerWei, "Insufficient funds to execute trade.");
        // Transfer ETH
        ethBalance[offer.maker] = ethBalance[offer.maker].sub(offer.makerWei);
        ethBalance[msg.sender] = ethBalance[msg.sender].add(offer.makerWei);
        ethBalance[msg.sender] = ethBalance[msg.sender].sub(offer.takerWei);
        ethBalance[offer.maker] = ethBalance[offer.maker].add(offer.takerWei);
        // Transfer maker ids to taker (msg.sender)
        for (uint i = 0; i < makerIds.length; i++) {
            _transfer(msg.sender, makerIds[i]);
        }
        // Transfer taker ids to maker
        for (uint i = 0; i < takerIds.length; i++) {
            _transfer(maker, takerIds[i]);
        }
        // Prevent a replay attack on this offer
        bytes32 hash = hashOffer(offer);
        cancelledOffers[hash] = true;
        emit Trade(hash, offer.maker, msg.sender, offer.makerWei, offer.makerIds, offer.takerWei, offer.takerIds);
    }

    function withdraw(uint amount) external reentrancyGuard {
        require(amount <= ethBalance[msg.sender]);
        ethBalance[msg.sender] = ethBalance[msg.sender].sub(amount);
        (bool success, ) = msg.sender.call{value:amount}("");
        require(success);
        emit Withdraw(msg.sender, amount);
    }

    function deposit() external payable {
        ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }
}