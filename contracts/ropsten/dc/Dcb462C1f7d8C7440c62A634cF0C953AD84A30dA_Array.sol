/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Array  {
    //  init an array
    uint[] public arr;
    uint[] public arr2 = [1,2,3];
    
    //  Fixed sized array ,all elements to 0
    uint[10] public myFixedSizeArr;

    //  return single element
    function get(uint i) public view returns (uint) {
        return arr[i];
    }

    //  Solidity can return the entire array
    //  avoided for arrays that can grow in length
    function getArr() public view returns (uint[] memory) {
        return arr;
    }

    //  Append to array
    function push(uint i) public {
        arr.push(i);
    }

    //  remove last element from array
    function pop() public {
        arr.pop();
    }

    function getLength() public view returns (uint) {
        return arr.length;
    }

    //  delete does not change the array length
    //  it resets the value at index to its default value
    function remove(uint index) public {
        delete arr[index];
    }

    //  create array in memory ,only fixed size allowed
    function createMemArr() external {
        uint[] memory a = new uint[](5);
    }
}