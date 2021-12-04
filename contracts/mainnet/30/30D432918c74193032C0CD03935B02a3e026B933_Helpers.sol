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