pragma solidity 0.4.21;

/**
 * @title Array8 Library
 * @author Modular Inc, https://modular.network
 *
 * version 1.2.0
 * Copyright (c) 2017 Modular, Inc
 * The MIT License (MIT)
 * https://github.com/Modular-Network/ethereum-libraries/blob/master/LICENSE
 *
 * The Array8 Library provides a few utility functions to work with
 * storage uint8[] types in place. Modular provides smart contract services
 * and security reviews for contract deployments in addition to working on open
 * source projects in the Ethereum community. Our purpose is to test, document,
 * and deploy reusable code onto the blockchain and improve both security and
 * usability. We also educate non-profits, schools, and other community members
 * about the application of blockchain technology.
 * For further information: modular.network
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library Array8Lib {

  /// @dev Sum vector
  /// @param self Storage array containing uint256 type variables
  /// @return sum The sum of all elements, does not check for overflow
  function sumElements(uint8[] storage self) public view returns(uint256 sum) {
    uint256 term;
    uint8 remainder;

    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,32)))

        remainder := mod(i,32)

        for { let j := 0 } lt(j, remainder) { j := add(j, 1) } {
          term := div(term,256)
        }

        term := and(0x00000000000000000000000000000000000000000000000000000000000000ff,term)
        sum := add(term,sum)

      }
    }
  }

  /// @dev Returns the max value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return maxValue The highest value in the array
  function getMax(uint8[] storage self) public view returns(uint8 maxValue) {
    uint256 term;
    uint8 remainder;

    assembly {
      mstore(0x60,self_slot)
      maxValue := 0

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,32)))

        remainder := mod(i,32)

        for { let j := 0 } lt(j, remainder) { j := add(j, 1) } {
          term := div(term,256)
        }

        term := and(0x00000000000000000000000000000000000000000000000000000000000000ff,term)
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
  function getMin(uint8[] storage self) public view returns(uint8 minValue) {
    uint256 term;
    uint8 remainder;

    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        term := sload(add(sha3(0x60,0x20),div(i,32)))

        remainder := mod(i,32)

        for { let j := 0 } lt(j, remainder) { j := add(j, 1) } {
          term := div(term,256)
        }

        term := and(0x00000000000000000000000000000000000000000000000000000000000000ff,term)
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
  function indexOf(uint8[] storage self, uint8 value, bool isSorted)
           public
           view
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
  function getParentI(uint256 index) private pure returns (uint256 pI) {
    uint256 i = index - 1;
    pI = i/2;
  }

  /// @dev Utility function for heapSort
  /// @param index The index of parent node
  /// @return lcI The index of left child
  function getLeftChildI(uint256 index) private pure returns (uint256 lcI) {
    uint256 i = index * 2;
    lcI = i + 1;
  }

  /// @dev Sorts given array in place
  /// @param self Storage array containing uint256 type variables
  function heapSort(uint8[] storage self) public {
    if(self.length > 1){
      uint256 end = self.length - 1;
      uint256 start = getParentI(end);
      uint256 root = start;
      uint256 lChild;
      uint256 rChild;
      uint256 swap;
      uint8 temp;
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

  /// @dev Removes duplicates from a given array.
  /// @param self Storage array containing uint256 type variables
  function uniq(uint8[] storage self) public returns (uint256 length) {
    bool contains;
    uint256 index;

    for (uint256 i = 0; i < self.length; i++) {
      (contains, index) = indexOf(self, self[i], false);

      if (i > index) {
        for (uint256 j = i; j < self.length - 1; j++){
          self[j] = self[j + 1];
        }

        delete self[self.length - 1];
        self.length--;
        i--;
      }
    }

    length = self.length;
  }
}