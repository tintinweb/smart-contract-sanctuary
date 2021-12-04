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