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

import "./Base64.sol";
import "./Helpers.sol";
import "./Sacred.sol";



/** @title Daemonica Manifest library
  * @author @0xAnimist
  * @notice Manifests Daemonica entities
  */
library Manifest {

   string public constant DELIMITER = " ";


   /** @notice Packs numerical matrix values into a DELIMITER-delimited string
     * @param _theta The 8 x 8 matrix of uint8 values
     * @return String representation of the matrix
     */
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


   /** @notice Packs an entity's attributes into a string for rendering as metadata
     * @param _tau The dims of an entity at the given moment in 3d time
     * @param _tick The tick value of an entity at the given moment in 3d time
     */
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


   /** @notice Manifests a Daemonica entity
     * @param _tokenId The _tokenId of the entity to render
     * @param _theta The matrix of frequency values of the entity at the given moment in 3d time
     * @param _tau The dims of an entity at the given moment in 3d time
     * @param _tick The tick value of an entity at the given moment in 3d time
     * @param _newday The corresponding block.timestamp to the given moment in 3d time
     */
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