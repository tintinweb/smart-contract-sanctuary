/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

pragma solidity ^0.4.23;

/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory18 {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target)<<16;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602b80600a3d3981f3363d3d373d3d3d363d71000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x26), 0x5af43d82803e903d91602957fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x35)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target)<<16;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7100000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1c), 0x5af43d82803e903d91602957fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2b)

      result := and(
        eq(mload(clone), mload(other)), 
        eq(mload(add(clone, 0x20)), mload(add(other, 0x20)))
      )
    }
  }
}