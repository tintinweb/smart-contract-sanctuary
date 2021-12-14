// SPDX-License-Identifier: ISC

pragma solidity ^0.8.7;
pragma abicoder v2;

library SVGUtils {

  function checkCoordinates(uint xPoint, uint yPoint) public pure returns (bool) {
    if ((xPoint > 170 && xPoint < 394) && ( yPoint > 170 && yPoint < 394)) {
      return false;
    }
    return true;
  }

  function uint2str(uint i_, uint decimals_) public pure returns (string memory _uintAsString) { // only 1 decimal
    if (i_ == 0) {
      return "0";
    }
    uint j = i_;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    if (len != 1 && decimals_ > 0) {
      len ++;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    uint index = 0;
    if(len == 1 && decimals_ > 0) {
      bstr = new bytes(3);
      bstr[0] = bytes1(uint8(48));
      bstr[1] = bytes1(uint8(46));
      bstr[2] = bytes1((48 + uint8(i_ - i_ / 10 * 10)));
    } else {
      while (i_ != 0) {
        k = k-1;
        if (index == decimals_ && index != 0) {
          bstr[k] = bytes1(uint8(46));
          k = k-1;
        }
        uint8 temp = (48 + uint8(i_ - i_ / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        i_ /= 10;
        index ++;
      }
    }
    return string(bstr);
  }
}