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
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";

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
  * @notice "Daemonica generates an ever-changing 8 x 8 numerical matrix from base64-encoded
  * onchain art. Each matrix is associated with an "Entity," which in turn can cast "Xe_ntities."
  * The n dimensional relationships that exist within and between each Entity and Xe_ntity can be
  * freely interpreted and understood. Use Daemonica however you wish." –artist
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

  /** @notice Refunds a dimAdder if owner has to delete the dim the added in case
    * of emergency
    * @param  _symbol Symbol of the dim being removed that needs refunding
    */
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


  /** @notice Allows owner to remove a dim and refund the dimAdder
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
  function getTau(address _hodler) public view returns (string[] memory){
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
    * @param _artist The Ethereum address of the artist
    */
  constructor (address _artist) {
    artist = _artist;
  }


}