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
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";


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

   /**  @notice Returns current tick for an entity with _tokenId
     *  @param  _tokenId  TokenId of the entity
     *  @return The current tick
     */
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



  /**  @notice Entity constructor
    *  @param _artist address of the artist
    *  @param _entitySupply initial supply of entities
    *  @param _modulo puts a ceiling on entity matrix values
    *  @param _offering cost of animo/minting an entity and 1/10 cost of casting an entity and minting a xe_ntity
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