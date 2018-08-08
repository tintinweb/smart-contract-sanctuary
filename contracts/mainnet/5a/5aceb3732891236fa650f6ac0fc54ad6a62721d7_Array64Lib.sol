pragma solidity ^0.4.13;

/**
 * @title Array64 Library
 * @author Majoolr.io
 *
 * version 1.0.0
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Array64 Library provides a few utility functions to work with
 * storage uint64[] types in place. Majoolr works on open source projects in
 * the Ethereum community with the purpose of testing, documenting, and deploying
 * reusable code onto the blockchain to improve security and usability of smart
 * contracts. Majoolr also strives to educate non-profits, schools, and other
 * community members about the application of blockchain technology.
 * For further information: majoolr.io
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library Array64Lib {

  /// @dev Sum vector
  /// @param self Storage array containing uint256 type variables
  /// @return sum The sum of all elements, does not check for overflow
  function sumElements(uint64[] storage self) constant returns(uint64 sum) {
    uint256 term;
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,4)))

        switch mod(i,4)
        case 1 {
          for { let j := 0 } lt(j, 2) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 2 {
          for { let j := 0 } lt(j, 4) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 3 {
          for { let j := 0 } lt(j, 6) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }

        term := and(0x000000000000000000000000000000000000000000000000ffffffffffffffff,term)
        sum := add(term,sum)

      }
    }
  }

  /// @dev Returns the max value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return maxValue The highest value in the array
  function getMax(uint64[] storage self) constant returns(uint64 maxValue) {
    uint256 term;
    assembly {
      mstore(0x60,self_slot)
      maxValue := 0

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,4)))

        switch mod(i,4)
        case 1 {
          for { let j := 0 } lt(j, 2) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 2 {
          for { let j := 0 } lt(j, 4) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 3 {
          for { let j := 0 } lt(j, 6) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }

        term := and(0x000000000000000000000000000000000000000000000000ffffffffffffffff,term)
        switch lt(maxValue, term)
        case 1 {
          maxValue := term
        }
      }
    }
  }

  /// @dev Returns the minimum value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return minValue The highest value in the array
  function getMin(uint64[] storage self) constant returns(uint64 minValue) {
    uint256 term;
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,4)))

        switch mod(i,4)
        case 1 {
          for { let j := 0 } lt(j, 2) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 2 {
          for { let j := 0 } lt(j, 4) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }
        case 3 {
          for { let j := 0 } lt(j, 6) { j := add(j, 1) } {
            term := div(term,4294967296)
          }
        }

        term := and(0x000000000000000000000000000000000000000000000000ffffffffffffffff,term)

        switch eq(i,0)
        case 1 {
          minValue := term
        }
        switch gt(minValue, term)
        case 1 {
          minValue := term
        }
      }
    }
  }

  /// @dev Finds the index of a given value in an array
  /// @param self Storage array containing uint256 type variables
  /// @param value The value to search for
  /// @param isSorted True if the array is sorted, false otherwise
  /// @return found True if the value was found, false otherwise
  /// @return index The index of the given value, returns 0 if found is false
  function indexOf(uint64[] storage self, uint64 value, bool isSorted) constant
           returns(bool found, uint256 index) {
    if (isSorted) {
        uint256 high = self.length - 1;
        uint256 mid = 0;
        uint256 low = 0;
        while (low <= high) {
          mid = (low+high)/2;
          if (self[mid] == value) {
            found = true;
            index = mid;
            low = high + 1;
          } else if (self[mid] < value) {
            low = mid + 1;
          } else {
            high = mid - 1;
          }
        }
    } else {
      for (uint256 i = 0; i<self.length; i++) {
        if (self[i] == value) {
          found = true;
          index = i;
          i = self.length;
        }
      }
    }
  }

  /// @dev Utility function for heapSort
  /// @param index The index of child node
  /// @return pI The parent node index
  function getParentI(uint256 index) constant private returns (uint256 pI) {
    uint256 i = index - 1;
    pI = i/2;
  }

  /// @dev Utility function for heapSort
  /// @param index The index of parent node
  /// @return lcI The index of left child
  function getLeftChildI(uint256 index) constant private returns (uint256 lcI) {
    uint256 i = index * 2;
    lcI = i + 1;
  }

  /// @dev Sorts given array in place
  /// @param self Storage array containing uint256 type variables
  function heapSort(uint64[] storage self) {
    uint256 end = self.length - 1;
    uint256 start = getParentI(end);
    uint256 root = start;
    uint256 lChild;
    uint256 rChild;
    uint256 swap;
    uint64 temp;
    while(start >= 0){
      root = start;
      lChild = getLeftChildI(start);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end+1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
      if(start == 0)
        break;
      else
        start = start - 1;
    }
    while(end > 0){
      temp = self[end];
      self[end] = self[0];
      self[0] = temp;
      end = end - 1;
      root = 0;
      lChild = getLeftChildI(0);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end + 1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
    }
  }
}