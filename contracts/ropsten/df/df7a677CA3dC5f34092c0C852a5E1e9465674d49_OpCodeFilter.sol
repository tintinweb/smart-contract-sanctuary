//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
//import "hardhat/console.sol";

contract OpCodeFilter {
    // Contract takes runtime bytecode and strips out non-opcode bytes.
    bytes constant hexAlphabet = "0123456789abcdef";

    constructor() {}

function opCodesFromChecker(address target) internal view returns (bytes memory onlyOpcodes) {
    // Get size of runtime code at destination
    uint256 size;
    assembly { size := extcodesize(target) }
    require(size > 0, "No code at target.");
    
    // Reserve memory for that size, populate using extcodecopy.
    // Get code at the target and the location data starts and ends in memory.
    uint256 dataStart;
    bytes memory extcode = new bytes(size);
    // The start of the data is the memory object (variable name) + 0x20 to skip the length.
    // [0x20,0x21------>end] === [length, data]
    assembly {
      dataStart := add(extcode, 0x20)
      extcodecopy(target, dataStart, 0, size)
    }
    uint256 dataEnd = dataStart + size;
    require (dataEnd > dataStart, "SafeMath: addition overflow.");
    
    // Look for any reachable, impermissible opcodes.
    bool reachable = true;
    uint256 op;
    bytes memory filtered = new bytes(size);
    uint256 filteredCount; // Current number of valid opcodes
    
    // Loop over runtime bytecode
    for (uint256 i = dataStart; i < dataEnd; i++) {
      // Get opcode (as integer)
      assembly { op := shr(0xf8, mload(i)) }
      // Record the opcode, as it appears.
      // If currently in unreachable code/data, recognise JUMPDEST (91).
      if (reachable || (op==91)){ // <--- New      
        filtered[filteredCount*2] =   hexAlphabet[(op/16)%16]; // e.g. the '5' in 0x52
        filtered[filteredCount*2+1] = hexAlphabet[op%16]; // e.g. the '2' in 0x52
        filteredCount += 1;

        // if PUSHN, move i past data
        if (op > 95 && op < 128) {
          i += (op - 95);
        }
          continue;
      }
      
      // Check the opcode if it is reachable (i.e. not a constant or metadata).
      if (reachable) {
        // If execution is halted, mark opcodes that follow as unreachable.
        if (
          op == 254 || // invalid
          op == 243 || // return
          op == 253 || // revert
          op == 86  || // jump
          op == 0      // stop
        ) {   
          reachable = false;
          continue;
        }

      } else if (op == 91) { // jumpdest
        // Whenever a JUMPDEST is found, mark opcodes that follow as reachable. 
        reachable = true;
      }
    }
    
    return (filtered);
  }

  function fetchCode(address _addr) private view returns (bytes memory o_code) 
  { assembly {
      let size := extcodesize(_addr) 
      o_code := mload(0x40) 
      mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f)))) 
      mstore(o_code, size) 
      extcodecopy(_addr, add(o_code, 0x20), 0, size)
      }  
  }

  function getFiltered(address target) public view returns (string memory strOpcodes) {
      bytes memory mystr1 = 'An opcode <';
      string memory opCodesOnly = string(abi.encodePacked(opCodesFromChecker(target)));
      bytes memory mystr2 = '> sandwich';      
      return (string(abi.encodePacked(mystr1,opCodesOnly,mystr2)));
  }
}

