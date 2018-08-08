pragma solidity ^0.4.11;

/**
 * @title Array Utilities Library
 * @author Majoolr.io
 *
 * version 1.0.1
 * Copyright (c) 2017 Majoolr, LLC
 * The MIT License (MIT)
 * https://github.com/Majoolr/ethereum-libraries/blob/master/LICENSE
 *
 * The Array Utilities Library provides a few utility functions to work with
 * storage arrays in place. Majoolr works on open source projects in the Ethereum
 * community with the purpose of testing, documenting, and deploying reusable
 * code onto the blockchain to improve security and usability of smart
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

library ArrayUtilsLib {

  /// @dev Sum vector
  /// @param self Storage array containing uint256 type variables
  /// @return sum The sum of all elements, does not check for overflow
  function sumElements(uint256[] storage self) constant returns(uint256 sum){
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        sum := add(sload(add(sha3(0x60,0x20),i)),sum)
      }
    }
  }

  /// @dev Returns the max value in an array.
  /// @param self Storage array containing uint256 type variables
  /// @return maxValue The highest value in the array
  function getMax(uint256[] storage self) constant returns(uint256 maxValue) {
    assembly {
      mstore(0x60,self_slot)
      maxValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch lt(sload(add(sha3(0x60,0x20),i)), maxValue)
        case 0 {
          maxValue := sload(add(sha3(0x60,0x20),i))
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
  function indexOf(uint256[] storage self, uint256 value, bool isSorted) constant
           returns(bool found, uint256 index) {
    assembly{
      mstore(0x60,self_slot)
      let low := 0
      let high := sub(sload(self_slot),1)
      let mid := 0
      jumpi(unsorted, iszero(isSorted))
      sorted:
        jumpi(done, gt(low,high))
        mid := div(add(low,high),2)
        jumpi(setH, lt(value,sload(add(sha3(0x60,0x20),mid))))
        jumpi(setL, gt(value,sload(add(sha3(0x60,0x20),mid))))
        found := 1
        index := mid
        jump(done)
        setH:
          high := sub(mid,1)
          jump(sorted)
        setL:
          low := add(mid,1)
          jump(sorted)
      unsorted:
        jumpi(loop, iszero(eq(sload(add(sha3(0x60,0x20),low)), value)))
        found := 1
        index := low
        jump(done)
        loop:
          low := add(low,1)
          jumpi(unsorted, lt(low, sload(self_slot)))
      done:
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
  function heapSort(uint256[] storage self) {
    uint256 end = self.length - 1;
    uint256 start = getParentI(end);
    uint256 root = start;
    uint256 lChild;
    uint256 rChild;
    uint256 swap;
    uint256 temp;
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