// SPDX-License-Identifier: MIT

// https://kanon.art - K21
// https://daemonica.io
//
//
//                                   [email protected]@@@@@@@@@@$$$
//                               [email protected]@@@@@$$$$$$$$$$$$$$##
//                           $$$$$$$$$$$$$$$$$#########***
//                        $$$$$$$$$$$$$$$#######**!!!!!!
//                     ##$$$$$$$$$$$$#######****!!!!=========
//                   ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                 *#################*#***!*!!======;;;:::
//                ################********!!!!====;;;:::~~~~~
//              **###########******!!!!!!==;;;;::~~~--,,,-~
//             ***########*#*******!*!!!!====;;;::::~~-,,......,-
//            ******#**********!*!!!!=!===;;::~~~-,........
//           ***************!*!!!!====;;:::~~-,,..........
//         !************!!!!!!===;;::~~--,............
//         !!!*****!!*!!!!!===;;:::~~--,,..........
//        =!!!!!!!!!=!==;;;::~~-,,...........
//        =!!!!!!!!!====;;;;:::~~--,........
//       ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//       ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//       ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//      :;;==========;;;;;;::::~~~--,,[email protected]@$$##*!=;:~-.
//      :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//       :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//       :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//       ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//        ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//         -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//          ---~~~-----,,,,,........,---,.
//           ,,--------,,,,,,.........
//             .,,,,,,,,,,,,......
//                ...............
//                    .........

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

import "./IERC721Custodian.sol";

import "./OccultMath.sol";
import "./Entity.sol";
import "./Base64.sol";
import "./Helpers.sol";


interface IXe_ntity {
  function cast(address _hodler, uint256 _entityId, uint256 _tick) external returns (uint256);
}

/**
 * @title Daemonica Xe_ntity contract
 * @author @0xAnimist
 * @notice Orchestrates the casting and binding of n-dimensional Daemonica xe_entities
 */
contract Xe_ntity is ERC721Enumerable, ReentrancyGuard, Ownable {

  IEntity entity;
  IERC721Custodian custodian;
  bool public bindable = false;

  address public artist;
  uint256 public offering;
  bool public initialized = false;
  uint256 public artistBalance = 0;
  uint256 public ownerBalance = 0;

  string private tic = "*";
  string private nthPrimeOpen = "`   `";
  string private nthPrimeClose = "     ";
  string private deplexToken = "ha";
  string private ROW_DELIMITER = "no";
  string private COL_DELIMITER = "ys";


  /*
   *  "Quasiparticle of intensive multiplicity. Tics (or castings) are intrinsically
   *  several components of autonomously numbering anorganic populations, propagating
   *  by contagion between segmentary divisions in the order of nature. Ticks –
   *  as nonqualitative differentially-decomposable counting marks – each designate
   *  a multitude comprehended as a singular variation in tic(k)-density."
   *  -Ccru, *Ccru: Writings 1997-2003*, Time Spiral Press
   */
  struct Cast {
    uint256 tick;
    uint256 entityId;
  }
  mapping (uint256 => Cast) public castings;


  /** @notice Only the Daemonica entity contract can call function
    */
  modifier onlyEntity() {
    require(msg.sender == address(entity), "onlyEntity");//TODO _msgSender()
    _;
  }


  /** @notice Only the Daemonica xe_ntity hodler can call function
    */
  modifier onlyHodler(uint256 _xe_ntityId) {
    require(_exists(_xe_ntityId), "does not exist");
    require(ownerOf(_xe_ntityId) == _msgSender(), "not hodler");
    _;
  }


  /** @notice Returns the attributes of the xe_ntity with _tokenId
    * @param _tokenId The _tokenId of the xe_ntity
    * @return Attributes for rendering with tokenURI
    */
  function packAttributes(uint256 _tokenId) public view returns (string memory) {
    return string(abi.encodePacked(
      '"attributes": [{ "entity": ',
      Helpers.toString(castings[_tokenId].entityId),
      '},{ "tick": ',
      Helpers.toString(castings[_tokenId].entityId),
      '}],'
    ));
  }


  /**  @notice Calculates and returns base64 encoded xe_ntity metadata and image SVG
    *  encoded using Tic Xenotation from the OccultMath library
    *  @param _tokenId tokenId of the xe_ntity to render
    */
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
     string memory X = "";

     if(_exists(_tokenId)){
       uint8[8][8] memory theta;
       (theta,,) = entity.getTick(castings[_tokenId].entityId, castings[_tokenId].tick);

       uint8[8][8] memory antiTheta = OccultMath.syzygy888(theta, entity.getModulo());

       for(uint8 i = 0; i < 8; i++){
         for(uint8 j = 0; j < 8; j++){
           X = string(abi.encodePacked(
             X,
             OccultMath.encodeTX(antiTheta[i][j], tic, nthPrimeOpen, nthPrimeClose, deplexToken),
             COL_DELIMITER
           ));
         }
         X = string(abi.encodePacked(X, ROW_DELIMITER));
       }
     }else{
       X = "not yet cast";
     }

     string memory prefix = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 666 888"><style>.xen { color: black; font-family: serif; font-size: 19px; line-height: 19px; white-space: break-spaces; }</style><rect width="100%" height="100%" fill="red" /><foreignObject x="90" y="90" width="486" height="798" class="xen"><div xmlns="http://www.w3.org/1999/xhtml">';

     string memory postfix = '</div></foreignObject></svg>';

     string memory output = string(abi.encodePacked(prefix, X, postfix));

     string memory json = Base64.encode(
       bytes(
         string(
           abi.encodePacked(
             '{"name": "Xe_ntity #',
             Helpers.toString(_tokenId),
             '", "description": "Functions are secularized incantations as code. A Xe_ntity is X where X(entity) = entity^. Participants that own an entity can cast a xe_ntity from it, transforming the entity in the process. *Ens divinum cognoscibile per inspirationem est subiectum*=?",',
             packAttributes(_tokenId),
             '"image": "data:image/svg+xml;base64,',
             Base64.encode(bytes(output)), '"}'
           )
         )
       )
     );

     return string(abi.encodePacked('data:application/json;base64,', json));

  }

  /**  @notice Casts an entity with a xe_ntity, minting the xe_ntity
    *  @param _hodler Owner of the entity
    *  @param _entityId tokenId of the entity to cast
    *  @param _tick 3d time parameter that chronicles how many casts the entity has undergone
    */
  function cast(address _hodler, uint256 _entityId, uint256 _tick) external nonReentrant onlyEntity returns (uint256){
    _safeMint(_hodler, totalSupply()+1);//start at 1
    castings[totalSupply()] = Cast(_tick, _entityId);
    return totalSupply();
  }


  /**  @notice Binds the ownership of a xe_ntity to another ERC721 NFT
    * @param _xe_ntityId The tokenId of the xe_ntity to bind
    * @param _guardianContract The ERC721 guardian contract
    * @param _guardianTokenId The tokenId of a ERC721 guardian token
    */
  function bind(
    uint256 _xe_ntityId,
    address _guardianContract,
    uint256 _guardianTokenId
  ) public payable {
    bind(_xe_ntityId, _guardianContract, _guardianTokenId, "");
  }


  /**  @notice Binds the ownership of a xe_ntity to another ERC721 NFT with a message
    * @param _xe_ntityId The tokenId of the xe_ntity to bind
    * @param _guardianContract The ERC721 guardian contract
    * @param _guardianTokenId The tokenId of a ERC721 guardian token
    * @param _data The message
    */
  function bind(
    uint256 _xe_ntityId,
    address _guardianContract,
    uint256 _guardianTokenId,
    bytes memory _data
  ) public payable nonReentrant {
    require(bindable, "not bindable");
    require(_msgSender() == ownerOf(_xe_ntityId), "not yours to bind");
    require(msg.value >= offering, "insufficient offering");

    custodian.bind(address(this), _xe_ntityId, _guardianContract, _guardianTokenId, _data);

    ownerBalance += msg.value/2;
    artistBalance += (msg.value - (msg.value/2));
  }


  /** @notice Unbinds the xe_ntity from the guardian NFT, giving the guardian
    * token owner the ownership of the xe_ntity
    * @param _xe_ntityId The tokenId of the bound xe_ntity
    */
  function unbind(
    uint256 _xe_ntityId
  ) public payable {
    unbind(_xe_ntityId, "");
  }


  /** @notice Unbinds the xe_ntity from the guardian NFT with a message, giving
    * the guardian token owner the ownership of the xe_ntity
    * @param _xe_ntityId The tokenId of the bound xe_ntity
    * @param _data The message
    */
  function unbind(
    uint256 _xe_ntityId,
    bytes memory _data
  ) public payable nonReentrant {
    require(_msgSender() == custodian.getGuardianOwner(address(this), _xe_ntityId), "not yours to unbind");
    require(msg.value >= offering, "insufficient offering");

    custodian.unbind(address(this), _xe_ntityId, _data);

    ownerBalance += msg.value/2;
    artistBalance += (msg.value - (msg.value/2));
  }


  /** @notice Returns the guardian token contract and tokenId for a given xe_ntity
    * @param _xe_ntityId The tokenId of the bound xe_ntity
    * @return The contract address of the guardian token
    * @return The tokenId of the guardian token
    */
  function getGuardianToken(
    uint256 _xe_ntityId
  ) external view returns (address, uint256) {
    return custodian.getGuardianToken(address(this), _xe_ntityId);
  }


  /** @notice Returns the owner address of a guardian token
    * @param _xe_ntityId The tokenId of the bound xe_ntity
    * @return The Ethereum address of the guardian token's owner
    */
  function getGuardianOwner(
    uint256 _xe_ntityId
  ) external view returns (address) {
    return custodian.getGuardianOwner(address(this), _xe_ntityId);
  }


  /** @notice Returns the message sent by the source NFT owner when they put it
    * into guardianship
    * @param _xe_ntityId The tokenId of the bound xe_ntity
    * @return The message
    */
  function getBindingMessage(
    uint256 _xe_ntityId
  ) external view returns (bytes memory) {
    return custodian.getBindingMessage(address(this), _xe_ntityId);
  }

  /** @notice Sets the address of the guardian contract and initiates binding
    * @param _custodianAddress The Ethereum address of the guardian contract
    * @param _bindable The new value of the bindable flag
    */
  function setCustodian(address _custodianAddress, bool _bindable) external onlyOwner {
    custodian = IERC721Custodian(_custodianAddress);
    bindable = _bindable;
  }


  /** @notice Allows owner or artist to withdraw available balance
    */
  function withdrawAvailableBalance() external nonReentrant {
    if(_msgSender() == owner()){
      uint256 b = ownerBalance;
      ownerBalance = 0;
      payable(_msgSender()).transfer(b);
    }else if(_msgSender() == artist){
      uint256 b = artistBalance;
      artistBalance = 0;
      payable(_msgSender()).transfer(b);
    }
  }

  /**  @notice Initializes the Entity interface
    *  @param _entityAddress address of the Entity contract
    */
  function initialize(address _entityAddress) external onlyOwner {
    require(!initialized, "already initialized");
    entity = IEntity(_entityAddress);
    initialized = true;
  }


  /**  @notice Xe_ntity constructor
    *  @param _artist address of the artist
    *  @param _offering cost of binding a xe_ntity
    */
  constructor(address _artist, uint256 _offering) ERC721("Daemonic Xe_ntities", "XEN0") Ownable() {
    artist = _artist;
    offering = _offering;
  }

}