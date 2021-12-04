// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


import "./OccultMath.sol";
import "./Base64.sol";
import "./Daemonica.sol";
import "./Manifest.sol";
import "./Xe_ntity.sol";
import "./Helpers.sol";
import "./Sacred.sol";


interface IEntity is IERC721Enumerable, IERC721Metadata {
  function getModulo() external view returns (uint8);
  function getTick(uint256 _tokenId, uint256 _tick) external view returns (uint8[8][8] memory, string[] memory, uint256);
}


/** @title Daemonica Entity contract
  * @author @0xAnimist
  * @notice Orchestrates the manifestation of n-dimensional Daemonica entities
  */
contract Entity is ERC721Enumerable, ReentrancyGuard, Ownable {

  bool public initialized = false;

  IDaemonica daemonica;
  IXe_ntity xe_ntity;

  address public artist;
  uint256 public artistBalance = 0;
  uint256 public ownerBalance = 0;

  bool public publicsale = false;
  uint256 public maxperhodler = 3;
  uint256 public maxperanimo = 3;

  uint256 public entitySupply;
  uint256 public ownerArtistQuota = 320;
  uint256 public ownerArtistClaimed = 0;
  uint256 public maxEntities = 4108;//4428-320
  uint8 public modulo;
  uint256 public offering;

  struct Tick {
    uint256 newday;//timestamp
    uint256 xe_ntityId;//0 for self
    string[] tau;//dims
  }

  mapping (uint256 => Tick[]) public ticks;



   /** @notice Xe_ntity interface loaded on initialization
     */
   modifier onlyInitialized() {
     require(initialized, "not initialized");
     _;
   }


   /**  @notice Set the value of the publicsale flag
     *  @dev Only owner
     *  @param _publicsale New value of the publicsale flag
     *  @param _maxperhodler New value of the per-address maximum
     *  @param _maxperanimo New value of the per-animo maximum
     */
   function setSaleTerms(bool _publicsale, uint256 _maxperhodler, uint256 _maxperanimo) external onlyOwner {
     _publicsale = _publicsale;
     maxperhodler = _maxperhodler;
     maxperanimo = _maxperanimo;
   }

   /**  @notice Increase the total entity supply up to a limit maxEntities - artistQuota - ownerQuota
     *  @dev Only owner
     *  @param _addition Number of entities to add
     */
   function increaseSupply(uint256 _addition) external onlyOwner {
     require((_addition + entitySupply) <= 4108, "too many");
     entitySupply += _addition;
   }


   /**  @notice Returns modulo state variable
     *  @return modulo
     */
   function getModulo() external view returns (uint8){
     return modulo;
   }

   function getTickCount(uint256 _tokenId) public view returns (uint256){
     if(_exists(_tokenId)){
       return (ticks[_tokenId].length - 1);
     }else{
       return 0;
     }
   }

   /**  @notice Returns an entity's theta and tau for a given tick value
     *  @dev  Future tick values are returned with the present value of tau
     *  @param  _tokenId tokenId of the entity
     *  @param  _tick Tick value
     *  @return theta values (8x8 matrix of numbers from 0 to modulo)
     *  @return tau array of dims
     */
   function getTick(uint256 _tokenId, uint256 _tick) public view returns (uint8[8][8] memory, string[] memory, uint256) {
     string[] memory tau;
     uint8[8][8] memory theta;
     uint256 newday;

     //future ticks default to present
     if(!_exists(_tokenId)){
       //require(_tick == 0, "no future without animo");
       tau = daemonica.getTau(address(0));
       newday = 0;
       theta = daemonica.getTheta(_tokenId, modulo, tau);
       return (theta, tau, newday);
     }else{
       if(_tick < getTickCount(_tokenId)){//all past ticks
         tau = ticks[_tokenId][_tick].tau;
         newday = ticks[_tokenId][_tick].newday;
       }else{//current and future ticks
         tau = daemonica.getTau(ownerOf(_tokenId));//all current and future ticks use current tau
         newday = block.timestamp;
       }
     }

     theta = daemonica.getTheta(_tokenId, modulo, tau);

     for(uint256 i = 0; i < _tick; i++){
       theta = OccultMath.sub888(theta, OccultMath.syzygy888(theta, modulo));
     }

     return (theta, tau, newday);
   }



   /**  @notice Calculates and returns base64 encoded entity metadata and image SVG
     *  @dev Uses the Manifest library
     *  @param _tokenId tokenId of the entity to render
     */
   function tokenURI(uint256 _tokenId) override public view returns (string memory) {
     return tokenURI(_tokenId, getTickCount(_tokenId));
   }



   /**  @notice Calculates and returns base64 encoded entity metadata and image SVG for a given moment in the entity's timeline
     *  @dev Uses the Manifest library
     *  @param _tokenId tokenId of the entity to render
     *  @param _tick Moment in the entity's timeline to render
     */
   function tokenURI(uint256 _tokenId, uint256 _tick) public view returns (string memory) {
     uint8[8][8] memory theta;
     string[] memory tau;
     uint256 newday;

     if(_exists(_tokenId)){
       (theta, tau, newday) = getTick(_tokenId, _tick);
       return Manifest.entity(_tokenId, theta, tau, _tick, newday);
     }else{
       tau = daemonica.getTau(address(0));
       theta = daemonica.getTheta(_tokenId, modulo, tau);
       return Manifest.entity(_tokenId, theta, tau, 0, 0);
     }
   }

   /**  @notice Mints the next available entity if msg.sender and msg.value qualifies
     */
  function animo() external payable {
    animoMulti(1);
  }


   /**  @notice Mints the next available _n entities if msg.sender and msg.value qualifies
     *  @dev _n is gated by maxperanimo and maxperhodler
     *  @param _n The number of entities to mint
     */
  function animoMulti(uint256 _n) public payable nonReentrant {
    if(_msgSender() == owner()){
      require((ownerArtistClaimed + _n) < ownerArtistQuota, "no more, owner and artist");
    }else{
      if(maxperanimo > 0){
        require(_n <= maxperanimo, "too many at one time");
      }
      require((totalSupply() + _n) <= entitySupply, "no more");
      require((offering * _n) <= msg.value, "insufficient offering");
      require(daemonica.isQualified(_msgSender()), "must hodl >= 1 qualified token");
      if(maxperhodler > 0){//maxperhodler == 0 == unlimited
        require((balanceOf(_msgSender()) + _n) <= maxperhodler, "quota exceeded");
      }
      ownerBalance += msg.value/2;
      artistBalance += (msg.value - (msg.value/2));
    }

    for(uint256 i = 0; i < _n; i++){
      _safeMint(_msgSender(), totalSupply());//start at 0
      ticks[totalSupply()-1].push(Tick(block.timestamp, 0, daemonica.getTau(_msgSender())));
    }

  }


  /**  @notice Casts an entity with a xe_ntity
    *  @param _tokenId tokenId of the entity to cast
    */
  function cast(uint256 _tokenId) external payable nonReentrant onlyInitialized {
    require(offering / 10 <= msg.value, "offer up");
    require(ownerOf(_tokenId) == _msgSender(), "not hodler");//also throws if !_exists()

    string[] memory tau = daemonica.getTau(_msgSender());
    uint256 xe_ntityId = xe_ntity.cast(_msgSender(), _tokenId, (ticks[_tokenId].length-1));
    ticks[_tokenId].push(Tick(block.timestamp, xe_ntityId, tau));

    ownerBalance += msg.value/2;
    artistBalance += (msg.value - msg.value/2);
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


  /**  @notice Initializes the Xe_ntity interface
    *  @param _xe_ntityAddress address of the Xe_ntity contract
    */
  function initialize(address _xe_ntityAddress) external onlyOwner {
    require(!initialized, "already initialized");
    xe_ntity = IXe_ntity(_xe_ntityAddress);
    initialized = true;
  }



  /**  @notice Daemonica constructor for initializing state variables and Daemonica dimensions
    *  @param _artist address of the artist
    *  @param _entitySupply initial supply of entities
    *  @param _modulo puts a ceiling on entity matrix values
    *  @param _offering cost of minting an entity and 1/8 cost of casting an entity and a xe_ntity
    *  @param _daemonicaAddress address of the Daemonica contract
    */
  constructor(
    address _artist,
    uint256 _entitySupply,
    uint256 _modulo,
    uint256 _offering,
    address _daemonicaAddress
  ) ERC721("Daemonican Entities", "DAE0") Ownable() {
      //STATE
      artist = address(_artist);
      entitySupply = _entitySupply;
      modulo = uint8(_modulo);
      offering = _offering;
      daemonica = IDaemonica(_daemonicaAddress);
  }

}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";

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



  modifier onlyEntity() {
    require(msg.sender == address(entity), "onlyEntity");//TODO _msgSender()
    _;
  }


  modifier onlyHodler(uint256 _xe_ntityId) {
    require(_exists(_xe_ntityId), "does not exist");
    require(ownerOf(_xe_ntityId) == _msgSender(), "not hodler");
    _;
  }


  function packAttributes(uint256 _tokenId) public view returns (string memory) {
    return string(abi.encodePacked(
      '"attributes": [{ "entity": ',
      Helpers.toString(castings[_tokenId].entityId),
      '},{ "tick": ',
      Helpers.toString(castings[_tokenId].entityId),
      '}],'
    ));
  }


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


  function cast(address _hodler, uint256 _entityId, uint256 _tick) external nonReentrant onlyEntity returns (uint256){
    _safeMint(_hodler, totalSupply()+1);//start at 1
    castings[totalSupply()] = Cast(_tick, _entityId);
    return totalSupply();
  }


  function bind(
    uint256 _xe_ntityId,
    address _guardianContract,
    uint256 _guardianTokenId
  ) public payable {
    bind(_xe_ntityId, _guardianContract, _guardianTokenId, "");
  }

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


  function unbind(
    uint256 _xe_ntityId
  ) public payable {
    unbind(_xe_ntityId, "");
  }

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

  function getGuardianToken(
    uint256 _xe_ntityId
  ) external view returns (address, uint256) {
    return custodian.getGuardianToken(address(this), _xe_ntityId);
  }

  function getGuardianOwner(
    uint256 _xe_ntityId
  ) external view returns (address) {
    return custodian.getGuardianOwner(address(this), _xe_ntityId);
  }

  function getBindingMessage(
    uint256 _xe_ntityId
  ) external view returns (bytes memory) {
    return custodian.getBindingMessage(address(this), _xe_ntityId);
  }

  function setCustodian(address _custodianAddress, bool _bindable) external onlyOwner {
    custodian = IERC721Custodian(_custodianAddress);
    bindable = _bindable;
  }



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

  function initialize(address _entityAddress) external onlyOwner {
    require(!initialized, "already initialized");
    entity = IEntity(_entityAddress);
    initialized = true;
  }


  constructor(address _artist, uint256 _offering) ERC721("Daemonic Xe_ntities", "XEN0") Ownable() {
    artist = _artist;
    offering = _offering;
  }

}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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

import "./Helpers.sol";


/*
 * @title Sacred contract
 * @author @0xAnimist
 * @notice Used for pseudorandomly assigning sacred names
 */
library Sacred {

  uint8 public constant tokensPerName = 4;
  uint8 public constant totalNgrams = 89;
  string public constant nameDelimiter = ".";



  function ngram(uint8 _index) public pure returns (string memory) {
    string[totalNgrams] memory ngrams = [
      //Sanskrit sacred seeds
      "\u0101\u1E25",//birth of the universe
      "o\u1E43",//opening syllable
      "h\u016B\u1E43",//closing syllable
      "dh\u012B\u1E25",//perfect wisdom
      "pha\u1E6D",//ancient magical word
      "au",//Sanskrit, "o"

      //Sanskrit consonants, Egyptian and Maori terms
      "akh",//Egyptian
      "ua",//Egyptian: "one who becomes eight" / "growth comes to be"
      "kh",//Egyptian: "pool of water rises up"
      "qet",//Egyptian: fire, grain, Serpent, "pedestal gives circle"
      "ka",//Sanskrit, Egypt
      "kha",//Sanskrit
      "ba",//Sanskrit, Egypt
      "bha",//Sanskrit
      "la",//Sanskrit
      "\u1E6Da",//Sanskrit
      "\u1E6Dha",//Sanskrit
      "pa",//Sanskrit, Maori
      "pha",//Sanskrit
      "ga",//Sanskrit
      "gha",//Sanskrit
      "ja",//Sanskrit
      "jha",//Sanskrit
      "\u1E0Da",//Sanskrit
      "\u1E0Dha",//Sanskrit
      "\u00F1a",//Sanskrit
      "ya",//Sanskrit, Dogon
      "ra",//Sanskrit, Egyptian
      "\u015Ba",//Sanskrit

      //Dogon
      "\u0119mm\u0119",//from female sorghum
      "p\u014D",//digitaria
      "sigi",//Sigui, Sirius
      "tolo",//star

      //Angels
      "el",
      "ael",
      "iel",
      "al",
      "iah",
      "vehu",
      "jel",
      "nik",
      "sit",
      "man",
      "leu",

      //Goetia
      "mon",
      "eth",
      "deus",
      "aga",
      "bar",
      "ast",
      "mur",
      "ion",
      "tri",
      "nab",
      "ius",

      //Faerie
      "tit",
      "mabd",
      "elf",
      "gno",
      "tua",
      "d\u00E9",
      "aos",
      "s\u00ED",

      //Q'ero
      "ayni",
      "hua",
      "nee",
      "ska",

      //Greek
      "nym",
      "pan",
      "syb",

      //Urbit
      "zod",
      "bin",
      "ryx",

      //Chinese
      "tian",
      "ren",
      "jing",
      "dao",
      "zhi",
      "ye",
      "xu",
      "shi",
      "gu\u01D0",

      //Shintoism
      "ama",
      "chi",
      "edo",
      "gi",
      "kon",
      "oni",
      "sei"
    ];

    return ngrams[_index];
  }


  function pluckNGram(uint256 _tokenId, uint256 _index) public pure returns (string memory) {
      uint256 rand = Helpers.random(string(abi.encodePacked(Helpers.toString(_index), Helpers.toString(_tokenId))));
      string memory output = ngram(uint8(rand % totalNgrams));
      //punctuate pseudorandomly
      if(_index < (tokensPerName - 1)){
        uint256 daemonicPotential  = rand % 33;
        if (daemonicPotential >= 13) {
            output = string(abi.encodePacked(output, nameDelimiter));
        }
      }

      return output;
  }


  function callBy(uint256 _tokenId) public pure returns (string memory) {
    string memory name = "";

    for(uint i = 0; i < tokensPerName; i++){
      name = string(abi.encodePacked(name, pluckNGram(_tokenId, i)));
    }

    return name;
  }


}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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


/*
 * @title OccultMath library
 * @author @0xAnimist
 * @notice Unsafe Math
 */
library OccultMath {

  string public constant defaultTic = ":";
  string public constant defaultNthPrimeOpen = "(";
  string public constant defaultNthPrimeClose = ")";
  string public constant defaultDeplex = "-P";

  struct Index {
    uint8 i;
    uint8 j;
  }



  function slice(uint256[] memory _array, uint256 _length) public pure returns (uint256[] memory){
    uint256[] memory output = new uint256[](_length);

    for (uint256 i = 0; i < _length; i++) {
        output[i] = _array[i];
    }

    return output;
  }



  function sqrt(uint256 y) public pure returns (uint256 z) {
      if (y > 3) {
          z = y;
          uint256 x = y / 2 + 1;
          while (x < z) {
              z = x;
              x = (y / x + x) / 2;
          }
      } else if (y != 0) {
          z = 1;
      }
  }



  function smallestFactor(uint _number) public pure returns (uint256){
    require(_number >= 2, "Number must be greater than or equal to 2");

    if((_number % 2) == 0){
      return 2;
    }

    uint end = sqrt(_number);

		for(uint i = 3; i <= end; i += 2) {
			if (_number % i == 0)
				return i;
		}
		return _number;
	}



  function factorize(uint256 _number) public pure returns (uint256[] memory){
    uint n = _number;
    uint[] memory factors = new uint[](100);
    uint len = 0;

		while (n > 1) {
			uint smallest = smallestFactor(n);
      require(len < 100, "factor overflow");
      factors[len] = smallest;
      len = len + 1;
      n = n / smallest;
		}

    uint[] memory output = slice(factors, len);

		return output;
  }


  function listPrimes(uint256 _first, uint256 _last) public pure returns (uint256[] memory){
    // Validate input and initialize storage for primes
    require(_first > 1, "The starting number must be a positive integer greater than 1");
    require(_last > _first, "The range of search values must be greater than 0");

    uint firstPrime = 2;

    uint len = _last - firstPrime + 1;
    uint256[] memory list = new uint256[](len);

    // Generate list of all natural numbers in [_first, _first+_total]
    for(uint i = 0; i < len; i++){
      list[i] = i + firstPrime;
    }

    // Find primes and eliminate their multiples
    uint256 limit = sqrt(len);
    for(uint256 i = 0; i <= limit; i++) {
      if(list[i] != 0) {
        for(uint256 pos = i + list[i]; pos < len; pos += list[i]) {
          list[pos] = 0;
        }
      }
    }

    uint256 primesTotal = 0;
    uint256 primesIndex = 0;

    for(uint256 i = 0; i < len; i++){
      if(list[i] != 0){
        primesTotal++;
      }
    }

    uint256[] memory primesList = new uint256[](primesTotal);

    // Populate primes[] with all prime numbers in order
    for (uint256 i = 0; i < len; i++) {
      if(list[i] != 0){
        primesList[primesIndex++] = list[i];
      }
    }

    // Trim primes from given start and return
    if (_first != 2) {
      uint returnTotal = 0;
      for(uint i = 0; i < primesTotal; i++){
        if(primesList[i] >= _first){
          returnTotal = returnTotal + 1;
        }
      }

      uint256[] memory sliced = new uint256[](returnTotal);
      uint diff = primesTotal - returnTotal;

      for (uint256 i = 0; i < returnTotal; i++) {
        sliced[i] = primesList[i+diff];
      }
      return sliced;
    }

    return primesList;
  }




  function syzygy888(uint8[8][8] memory _entity, uint8 _base) public pure returns (uint8[8][8] memory) {
    uint8[8][8] memory pair;
    for(uint8 i = 0; i < 8; i++){
      for(uint8 j = 0; j < 8; j++){
        require(_entity[i][j] < _base, "entity value out of range");
        pair[i][j] = _base - 1 - _entity[i][j];
      }
    }
    return pair;
  }

  function getSyzygyPartner8(uint8 _i, uint8 _base) public pure returns (uint8) {
    require(_i <= _base, "pair out of range");
    return _base - 1 - _i;
  }

  function sub888(uint8[8][8] memory _a, uint8[8][8] memory _b) public pure returns (uint8[8][8] memory) {
    uint8[8][8] memory diff;
    for(uint8 i = 0; i < 8; i++){
      for(uint8 j = 0; j < 8; j++){
        if(_a[i][j] >= _b[i][j]){
          diff[i][j] = _a[i][j] - _b[i][j];
        }else{
          diff[i][j] = _b[i][j] - _a[i][j];
        }
      }
    }
    return diff;

  }


  //TIC XENOTATION ENCODING
  //Implements a customizable version of D.C. Barker's Tic Xenotation
  function encodeTX(uint256 _number) public view returns (string memory) {
    return encodeTX(_number, defaultTic, defaultNthPrimeOpen, defaultNthPrimeClose, defaultDeplex);
  }



  function encodeTX(
    uint256 _number,
    string memory tic,//canonically ":"
    string memory nthPrimeOpen,//canonically "("
    string memory nthPrimeClose,//canonically ")"
    string memory deplexToken//canonically "-P"
  ) public view returns (string memory) {
    //zero
    if(_number == 0){
      return string(abi.encodePacked(nthPrimeOpen, nthPrimeOpen, deplexToken, nthPrimeClose, nthPrimeClose, tic));
    }

    //one
    if(_number == 1){
      return string(abi.encodePacked(nthPrimeOpen, deplexToken, nthPrimeClose, tic));
    }

    //1st prime
    if(_number == 2){
      return tic;
    }

    //2nd prime
    if(_number == 3){
      return string(abi.encodePacked(nthPrimeOpen, tic, nthPrimeClose));
    }

    //initialize primes
    uint256[] memory primes = listPrimes(2, _number);

    //initialize hyprimes
    uint256[] memory hyprimes = new uint256[](primes[primes.length-1]+1);
    for(uint256 i = 0; i < primes.length; i++){
      hyprimes[primes[i]] = i+1; //+1 because primes is 0-based array and hyprimes is 1-based
    }

    if(primes[primes.length-1] == _number){//ie. if _number is prime it would be the last in the primes array
      //nth prime
      uint256 ordinate = hyprimes[_number];

      string memory output;

      if(hyprimes[ordinate] != 0){//ie. if ordinate is prime
        //_number is hyprime
        output = string(
          abi.encodePacked(
            encodeTX(
              ordinate,
              tic,
              nthPrimeOpen,
              nthPrimeClose,
              deplexToken
            )));
      }else{
        //_number is !hyprime
        uint[] memory ordinateFactors = factorize(ordinate);

        for(uint i = 0; i < ordinateFactors.length; i++){
          output = string(
            abi.encodePacked(
              encodeTX(
                ordinateFactors[i],
                tic,
                nthPrimeOpen,
                nthPrimeClose,
                deplexToken
              ), output));
        }
      }
      return string(abi.encodePacked(nthPrimeOpen, output, nthPrimeClose));
    }else{
      uint[] memory factors = factorize(_number);
      string memory output = encodeTX(
        factors[0],
        tic,
        nthPrimeOpen,
        nthPrimeClose,
        deplexToken
      );

      for(uint i = 1; i < factors.length; i++){
        //encode left to right from the largest factor to the smallest
        output = string(
          abi.encodePacked(
            encodeTX(
              factors[i],
              tic,
              nthPrimeOpen,
              nthPrimeClose,
              deplexToken
            ), output));
      }

      return output;
    }
  }





  function getGEMATRIX() public pure returns (uint8[8][8] memory){

    uint8[8][8] memory GEMATRIX = [
      [ 65,  66,  67,  68,  69,  70,  71,  72], // A B C D E F G H
      [ 73,  74,  75,  76,  77,  78,  79,  80], // I J K L M N O P
      [ 81,  82,  83,  84,  85,  86,  87,  88], // Q R S T U V W X
      [ 89,  90,  97,  98,  99, 100, 101, 102], // Y Z a b c d e f
      [103, 104, 105, 106, 107, 108, 109, 110], // g h i j k l m n
      [111, 112, 113, 114, 115, 116, 117, 118], // o p q r s t u v
      [119, 120, 121, 122,  48,  49,  50,  51], // w x y z 0 1 2 3
      [ 52,  53,  54,  55,  56,  57,  43,  47]  // 4 5 6 7 8 9 + /
    ];

    return GEMATRIX;
  }



  function sixtyFourier(bytes[] memory _tokenURIs, uint8 _modulo) public pure returns (uint8[8][8] memory) {
    require(_modulo <= 256, "Mod > 2^8");//modulo cannot exceed max value of uint8
    uint8[8][8] memory GEMATRIX = getGEMATRIX();

    //build a linear index of the GEMATRIX
    Index[] memory index = new Index[](123);//122 is the highest value in the GEMATRIX

    //fill in the index values that point on map
    for(uint8 i = 0; i < 8; i++){
      for(uint8 j = 0; j < 8; j++){
        index[GEMATRIX[i][j]] = Index(i,j);
      }
    }

    //construct the frequency cipher
    uint8[8][8] memory frequencies;
    uint8 zero = 0;

    for(uint8 t = 0; t < _tokenURIs.length; t++){

      for(uint256 b = 0; b < _tokenURIs[t].length; b++){
        uint8 char = uint8(bytes1(_tokenURIs[t][b]));
        if(char != 61){//skip "="
          uint8 i = index[char].i;//TODO plex variable down uint8 i = index[uint8(_tokenURIs[t][d])].i
          uint8 j = index[char].j;//TODO plex variable down uint8 j = index[uint8(_tokenURIs[t][d])].j;

          //map frequency onto a _modulo-degree circle
          //since we are counting one-by-one, this is equivalent to % _modulo
          if(frequencies[i][j] == (_modulo - 1)){
            frequencies[i][j] = zero;
          }else{
            frequencies[i][j]++;
          }
        }

      }
    }

    return frequencies;
  }


  function isBase64Character(bytes1 _c) public pure returns (bool) {
    uint8 _cint = uint8(_c);
    //+
    if(_cint == 43 || _cint == 47){//+/
      return true;
    }else if(_cint >= 48 && _cint <= 57){//0-9
      return true;
    }else if(_cint >= 65 && _cint <= 90){//A-Z
      return true;
    }else if(_cint >= 97 && _cint <= 122) {//a-z
      return true;
    }
    return false;
  }


  function isValidBase64String(string memory _string) public pure returns (bool) {
    bytes memory data = bytes(_string);
    require( (data.length % 4) == 0, "!= %4");

    for (uint i = 0; i < data.length; i++) {
      bytes1 c = data[i];
      if(!isBase64Character(c)){
        if(i >= (data.length - 3)){//last two bytes may be = for padding
          if(uint8(c) != 61){//=
            return false;
          }
        }else{
          return false;
        }
      }
    }
    return true;
  }



}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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

import "./Base64.sol";
import "./Helpers.sol";
import "./Sacred.sol";



/** @title Daemonica Manifest library
  * @author @0xAnimist
  * @notice Manifests Daemonica entities
  */
library Manifest {


  string public constant DELIMITER = " ";

   function packSvg(uint8[8][8] memory _theta) public pure returns (string memory) {
     string[17] memory parts;
     parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 666 888"><style>.en { fill: #973036; font-family: serif; font-size: 30px; letter-spacing: 3px; white-space: pre; text-align: justify; text-justify: inter-word;}</style><rect width="100%" height="100%" fill="black"/><text y="150" class="en">';

     parts[1] = Helpers.stringifyRow(_theta[0], DELIMITER);//row 0

     parts[2] = '</text><text y="195" class="en">';

     parts[3] = Helpers.stringifyRow(_theta[1], DELIMITER);//row 1

     parts[4] = '</text><text y="240" class="en">';

     parts[5] = Helpers.stringifyRow(_theta[2], DELIMITER);//row 2

     parts[6] = '</text><text y="285" class="en">';

     parts[7] = Helpers.stringifyRow(_theta[3], DELIMITER);//row 3

     parts[8] = '</text><text y="330" class="en">';

     parts[9] = Helpers.stringifyRow(_theta[4], DELIMITER);//row 4

     parts[10] = '</text><text y="375" class="en">';

     parts[11] = Helpers.stringifyRow(_theta[5], DELIMITER);//row 5

     parts[12] = '</text><text y="420" class="en">';

     parts[13] = Helpers.stringifyRow(_theta[6], DELIMITER);//row 6

     parts[14] = '</text><text y="465" class="en">';

     parts[15] = Helpers.stringifyRow(_theta[7], DELIMITER);//row 7

     parts[16] = '</text></svg>';

     string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
     output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

     return output;
   }


   function packAttributes(string[] memory _tau, uint256 _tick) public pure returns (string memory) {
     string memory attributes = string(abi.encodePacked(
       '"attributes": [{ "tick": ',
       Helpers.toString(_tick),
       '},{ "trait_type": "dimensions", "value": ',
       Helpers.toString(_tau.length),
       '}'
     ));

     if(_tau.length > 0){
       for(uint8 i = 0; i < _tau.length-1; i++){
         attributes = string(abi.encodePacked(attributes, ',{ "trait_type": "dimension", "value": "', _tau[i], '"}'));
       }
       return string(abi.encodePacked(attributes, ',{ "trait_type": "dimension", "value": "', _tau[_tau.length-1], '"}],'));
     }else{
       return string(abi.encodePacked(attributes, '],'));
     }
   }



   function entity(
     uint256 _tokenId,
     uint8[8][8] memory _theta,
     string[] memory _tau,
     uint256 _tick,
     uint256 _newday
   ) public pure returns (string memory) {
     string memory svg = packSvg(_theta);

     string memory attributes;

     if(_newday > 0){
       attributes = string(abi.encodePacked(
         '"manifested": ',
         Helpers.toString(_newday),
         ',',
         attributes,
         packAttributes(_tau, _tick)
       ));
     }else{
       attributes = string(abi.encodePacked('"manifested": 0,'));
     }

     string memory json = Base64.encode(
       bytes(
         string(
           abi.encodePacked(
             '{"name": "',
             Sacred.callBy(_tokenId),
             '", "description": "Daemonican entity ',
             Helpers.toString(_tokenId),
             '\u002F8888: ',
             '\u03BE = Xi, *in intentione recta*. Ludwig Wittgenstein used \u03BE as a variable in Tractatus Logico-Philosophicus to represent aspects of his \u201Cpropositions\u201D. He was a mystic who hid his incantations in his philosophy, like how 6.522 + 2.003 = 7. A Daemonican entity is also a proposition, *qualitas occulta*.',
             '", ',
             attributes,
             '"image": "data:image/svg+xml;base64,',
             Base64.encode(bytes(svg)), '"}'
           )
         )
       )
     );

     return string(abi.encodePacked('data:application/json;base64,', json));
   }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERC-721 Enumerable Non-Fungible Token Standard, optional binding extension
 */
interface IERC721Custodian is IERC721 {

  function getGuardianToken(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external view returns (address, uint256);

  function getGuardianOwner(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external view returns (address);

  function getBindingMessage(
    address _sourceContract,
    uint256 _xe_ntityId
  ) external view returns (bytes memory);

  function bind(
    address _sourceContract,
    uint256 _sourceTokenId,
    address _guardianContract,
    uint256 _guardianTokenId
  ) external;

  function bind(
    address _sourceContract,
    uint256 _sourceTokenId,
    address _guardianContract,
    uint256 _guardianTokenId,
    bytes memory _data
  ) external;


  function unbind(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external;

  function unbind(
    address _sourceContract,
    uint256 _sourceTokenId,
    bytes memory _data
  ) external;

}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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



library Helpers{

  function boolToString(bool value) public pure returns (string memory) {
    if(value){
      return "true";
    }else{
      return "false";
    }
  }

  function toString(uint256 value) public pure returns (string memory) {
  // Inspired by OraclizeAPI's implementation - MIT license
  // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
      while (value != 0) {
          digits -= 1;
          buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
          value /= 10;
      }
      return string(buffer);
  }

  //@notice   uint8 implementation of the uint256 toString function above
  function toString8(uint8 value) public pure returns (string memory) {
    if (value == 0) {
      return "00";
    }

    uint8 temp = value;
    uint8 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer;
    if(digits == 1){
      buffer = new bytes(2);
      buffer[0] = bytes1(uint8(48));
      buffer[1] = bytes1(uint8(48 + uint8(value % 10)));
    }else{
      buffer = new bytes(digits);
      while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint8(value % 10)));
        value /= 10;
      }
    }

    return string(buffer);
  }


  //@notice   returns a _delimiter delimited string of all the values in a uint8 array
  function stringifyRow(uint8[8] memory _array, string memory _delimiter) internal pure returns (string memory) {
    string memory output = string(abi.encodePacked(
      '<tspan x="153">',toString8(_array[0]),'</tspan>',_delimiter,
      '<tspan x="198">',toString8(_array[1]),'</tspan>',_delimiter,
      '<tspan x="243">',toString8(_array[2]),'</tspan>',_delimiter
    ));

    output = string(abi.encodePacked(
      output,
      '<tspan x="288">',toString8(_array[3]),'</tspan>',_delimiter,
      '<tspan x="333">',toString8(_array[4]),'</tspan>',_delimiter,
      '<tspan x="378">',toString8(_array[5]),'</tspan>',_delimiter
    ));

    return string(abi.encodePacked(
      output,
      '<tspan x="423">',toString8(_array[6]),'</tspan>',_delimiter,
      '<tspan x="468">',toString8(_array[7]),'</tspan>',_delimiter
    ));
  }


  function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
  }

  //@notice:  returns a substring of the given string
  function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory) {
      bytes memory strBytes = bytes(str);
      if(endIndex == 0){
        endIndex = strBytes.length;
      }
      bytes memory result = new bytes(endIndex-startIndex);
      for(uint i = startIndex; i < endIndex; i++) {
          result[i-startIndex] = strBytes[i];
      }
      return string(result);
  }

  //@notice   returns a pseudorandom number
  function random(string memory input) internal pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(input)));
  }


}

// SPDX-License-Identifier: MIT

// https://kanon.art - K21
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

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./OccultMath.sol";
import "./Helpers.sol";


interface IBase64 is IERC721Enumerable, IERC721Metadata {}

interface IDaemonica {
  function getTau(address _hodler) external view returns (string[] memory);
  function getTheta(uint256 _tokenId, uint8 _modulo, string[] memory _tau) external view returns (uint8[8][8] memory);
  function isQualified(address _hodler) external view returns (bool);
}


/** @title Daemonica contract
  * @author @0xAnimist
  * @notice Daemonica generates an ever-changing 8 x 8 numerical matrix from base64-encoded onchain art. Each matrix is associated with an "Entity," which in turn can cast "Xe.ntities." The n dimensional relationships that exist within and between each Entity and Xe.ntity can be freely interpreted and understood. Use Daemonica however you wish.
  */
contract Daemonica is Ownable, ReentrancyGuard {

  uint8 public totalDims = 0;

  uint8 public totalAddedDims = 0;
  uint8 public maxAddableDims = 128;
  mapping (string => address) public dimAdder;


  uint8 public totalOwnerAddedDims = 0;
  uint8 public maxOwnerAddableDims = 128;
  bool public presale = true;

  address public artist;
  uint256 public artistBalance = 0;
  uint256 public ownerBalance = 0;

  mapping (string => IBase64) private dims;
  mapping (uint8 => string) private symbolStringByIndex;
  mapping (string => uint8) private symbolIndexByString;


  /** @notice Allows only the artist to broadcast a message
    * @param  _artist Artists's address
    * @param  _message Artist's message
    */
  event Broadcast(address indexed _artist, string _message);


  /** @notice Only the artist can call function
    */
  modifier onlyArtist() {
    require(artist == _msgSender(), "caller is not the artist");
    _;
  }

  /** @notice Only the artist or owner can call function
    */
  modifier onlyAdmin() {
    require(artist == _msgSender() || owner() == _msgSender(), "caller is not the artist or owner");
    _;
  }


  /** @notice Requires dim with symbol _symbol to be initialized
    * @param  _symbol Symbol associated with the dim's contract
    */
  modifier dimExists(string memory _symbol) {
    require(Helpers.compareStrings(symbolStringByIndex[symbolIndexByString[_symbol]],_symbol), "dim not exist");
    _;
  }


  /** @notice Allows only the artist to broadcast a message
    * @param  _message Artist's message
    */
  function artistBroadcast(string memory _message) external onlyArtist {
    emit Broadcast(msg.sender, _message);
  }


  /** @notice Allows the owner to set the presale flag
    * @param  _value the new value
    */
  function setPresale(bool _value) external onlyOwner {
    presale = _value;
  }


  /** @notice Returns lists of all dims by symbol and address
    * @dev    different contracts with the same symbol cannot be registered, only the first registered will be accepted
    * @return string array of each dim symbol
    * @return address array of each dim contract address
    */
  function getDims() external view returns (string[] memory, address[] memory) {
    string[] memory symbols = new string[](totalDims);
    address[] memory addresses = new address[](totalDims);
    for(uint8 i = 0; i < totalDims; i++){
      symbols[i] = symbolStringByIndex[i];
      addresses[i] = address(dims[symbols[i]]);
    }
    return (symbols, addresses);
  }


  /** @notice Registers a new dim
    * @dev    different contracts with the same symbol cannot be registered, only the first registered will be accepted
    * @param  _address  Contract address of dim to register
    */
  function registerDim(address _address) internal {
    IBase64 dim = IBase64(_address);

    //name the new dim symbolically and increment the dims counter
    string memory symbol = dim.symbol();
    require(!Helpers.compareStrings(dim.symbol(), ""), "requires symbol");
    require(!Helpers.compareStrings(symbolStringByIndex[symbolIndexByString[symbol]],symbol), "symbol already registered");

    //ensure the new dim is base64 encoded
    require(isValidLootverseURI(dim.tokenURI(1)));//test it against the first token

    symbolStringByIndex[totalDims] = symbol;
    symbolIndexByString[symbol] = totalDims;
    totalDims++;

    dims[symbol] = dim;
    dimAdder[symbol] = _msgSender();
  }


  /** @notice Allows owner to add a dim with a quota of maxOwnerAddableDims
    * @param  _address  Contract address of dim to register
    */
  function adminAddDim(address _address) external onlyAdmin {
    require(totalOwnerAddedDims < maxOwnerAddableDims, "owner quota exceeded");
    registerDim(_address);
    totalOwnerAddedDims++;
  }


  /** @notice Anyone can add a valid dim for 1 ether
    * @param  _address  Contract address of dim to register
    */
  function addDim(address _address) external payable nonReentrant {
    require(!presale, "not yet");
    require(msg.value >= 1 ether, "costs 1 eth");
    require(totalAddedDims < maxAddableDims, "public quota exceeded");
    registerDim(_address);
    totalAddedDims++;
    ownerBalance += msg.value/2;
    artistBalance += msg.value/2;//TODO (msg.value - msg.value/2);
  }

  function refund(string memory _symbol) internal {
    require(address(this).balance >= 1 ether, "owner cannot afford refund");
    payable(dimAdder[_symbol]).transfer(1 ether);

    uint256 half = (1 ether)/2;
    if(ownerBalance >= half){
      if(artistBalance >= half){
        ownerBalance -= half;
        artistBalance -= half;
      }else{
        ownerBalance -= (1 ether) - artistBalance;
        artistBalance = 0;
      }
    }else{
      artistBalance -= (1 ether) - ownerBalance;
      ownerBalance = 0;
    }
  }


  /** @notice Allows owner to remove a dim
    * @dev  Emergency use only
    * @param  _symbol Symbol of the dim to remove
    */
  function adminRemoveDim(string memory _symbol) external onlyAdmin dimExists(_symbol) {
    require(totalDims > 0, "no dims");

    refund(_symbol);

    delete(dims[_symbol]);//delete the interface
    //refactor the mappings
    for(uint8 i = symbolIndexByString[_symbol]; i < totalDims; i++){
      symbolStringByIndex[i] = symbolStringByIndex[i+1];
      symbolIndexByString[symbolStringByIndex[i]] = i;
    }
    //delete the mappings
    delete(symbolIndexByString[_symbol]);
    delete(symbolStringByIndex[totalDims]);
    //decrement the count
    totalDims--;


  }


  /** @notice Returns true if the given tokenURI() return value has a valid base64 header, payload, and its contract has a valid symbol
    * @param  _str  Return value from tokenURI() to test
    * @return  true or false
    */
  function isValidLootverseURI(string memory _str) internal pure returns (bool) {
    require(Helpers.compareStrings("data:application/json;base64,", Helpers.substring(_str, 0, 29)), 'Invalid prefix');
    string memory payload = Helpers.substring(_str, 29, 0);
    require( OccultMath.isValidBase64String(payload), "non-base64 chars");
    return true;
  }


  /** @notice Returns true if _hodler holds tokens from any dim in _animolist
    * @param  _hodler would be _hodler
    * @return True or false
    */
  function isQualified(address _hodler) external view returns (bool){
    for(uint8 i = 0; i < totalDims; i++){
      if(dims[symbolStringByIndex[i]].balanceOf(_hodler) > 0){
        return true;
      }
    }
    return false;
  }


  /** @notice 𝜏 = tau, a rarely used Greek symbol, *facta bruta* :( 𝜏 symbolizes  ( life | regeneration | resurrection | the power to find new life paths or choices )+. A striking phonetic relationship exists between 𝜏 and "tao", the Chinese term for ( the way | the true path | inner compass )+. *Hic et nunc*, the Daemonican way is death * life, or θ𝜏=X(ξ).
    * @dev    Returns any dims in which the _hodler owns at least one token of any tokenId
    * @param  _hodler entity hodler
    * @return A string array of the symbols of one or more tokens from each dim held by the hodler
    */
  function getTau(address _hodler) public view returns (string[] memory){//, uint256 _tokenId) public view returns (string[] memory, uint8){
    string[] memory tau;
    uint8 count = 0;

    if(_hodler == address(0)){//no hodler, default to first dim
      tau = new string[](1);
      tau[count++] = symbolStringByIndex[0];
      return tau;
    }else{
      tau = new string[](totalDims);

      for(uint8 i = 0; i < totalDims; i++){
        if(dims[symbolStringByIndex[i]].balanceOf(_hodler) > 0){
          tau[count++] = symbolStringByIndex[i];
        }
      }

      if(count == 0){//default to first dim
        string[] memory output = new string[](1);
        output[0] = symbolStringByIndex[0];
        return output;
      }else{//splice to length
        string[] memory output = new string[](count);
        for(uint8 i = 0; i < count; i++){
          output[i] = tau[i];
        }
        return output;
      }
    }
  }


  /** @notice θ = theta, symbol of change in angle or rotation. *Thanatos* (death) hides in this symbol. There is no ξ without θ, no *existentialia* without change. θ is also therefore a talismanic sign for passage to the “underworld”, to a realm closer to life’s origins.
    * @dev    Returns theta, the 8x8 base-_modulo frequency matrix of an entity
    * @param  _tokenId  tokenId of the entity being queried
    * @param  _modulo   caps all values at base-_modulo
    * @param  _tau      tau is the dimensions of _tokenId's hodler
    */
  function getTheta(uint256 _tokenId, uint8 _modulo, string[] memory _tau) external view returns (uint8[8][8] memory) {
    bytes[] memory bytePayloads = new bytes[](_tau.length);

    for(uint8 i = 0; i < _tau.length; i++){
      bytePayloads[i] = bytes(Helpers.substring(dims[_tau[i]].tokenURI(_tokenId), 29, 0));
    }

    uint8[8][8] memory thetas = OccultMath.sixtyFourier(bytePayloads, _modulo);

    return thetas;
  }


  /** @notice Allows owner to withdraw available balance
    */
  function ownerWithdrawAvailableBalance() public nonReentrant onlyOwner {
      uint256 b = ownerBalance;
      ownerBalance = 0;
      payable(msg.sender).transfer(b);
  }

  /** @notice Allows artist to withdraw available balance
    */
  function artistWithdrawAvailableBalance() public nonReentrant onlyArtist {
      uint256 b = artistBalance;
      artistBalance = 0;
      payable(msg.sender).transfer(b);
  }


  /** @notice Daemonica constructor
    */
  constructor (address _artist) {
    artist = _artist;
  }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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