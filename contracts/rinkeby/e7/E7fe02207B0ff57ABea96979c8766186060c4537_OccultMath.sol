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


  //Slice
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