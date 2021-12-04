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


  /** @notice Returns a sacred syllable from a host of languages, ancient and
    * contemporary, based on the _index
    * @param _index The index value from 0-88
    * @return The sacred syllable ngram
    */
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


  /** @notice Pseudorandomly selects and punctuates an ngram
    * @param _tokenId The _tokenId of the token name to reveal
    * @param _index The index of the ngram (for names with > 1 ngram)
    * @return The resulting ngram
    */
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


  /** @notice Reveals the name of a token
    * @param _tokenId The _tokenId of the token name to reveal
    * @return The name of _tokenId
    */
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


/** @title Daemonica helper functions
  * @author @0xAnimist
  * @notice Misc support for Daemonica contract suite
  */
library Helpers{

  /** @notice Converts boolean to a string
    * @param  value The boolean value
    * @return A string that reads "true" or "false"
    */
  function boolToString(bool value) public pure returns (string memory) {
    if(value){
      return "true";
    }else{
      return "false";
    }
  }

  /** @notice Converts uint256 to a string
    * @param  value The uint256 value
    * @return A string that represents the numerical value of the input
    */
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

  /** @notice Converts uint8 to a string
    * @param  value The uint8 value
    * @return A string that represents the numerical value of the input
    */
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



  /** @notice Returns a _delimiter delimited string of all the values in an 8 uint8 long array
    * @param  _array Array of uint8 values to concatenate
    * @param  _delimiter String to delimit each value
    * @return Concatenated string of all the values delimited by _delimiter
    */
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

  /** @notice Compares two strings
    * @param  _a First string to compare
    * @param  _b Second string to compare
    * @return True if equal, false if not
    */
  function compareStrings(string memory _a, string memory _b) public pure returns (bool) {
    return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b))));
  }


  /** @notice Returns a substring of the given string
    * @param  str The string
    * @param  startIndex Starting index determining the substring to return
    * @param  endIndex Ending index determining the substring to return
    * @return Substring parsed from the string
    */
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


  /** @notice Returns a pseudorandom number from a string input
    * @param  input A string to seed the pseudorandom number generator
    * @return  A pseudorandom uint256 number based on the input string
    */
  function random(string memory input) internal pure returns (uint256) {
      return uint256(keccak256(abi.encodePacked(input)));
  }


}