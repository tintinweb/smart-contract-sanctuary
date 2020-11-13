pragma solidity 0.5.17;

library StackLib {
  function stackPeek(uint256[] storage _array) internal view returns (uint256) {
    require(_array.length > 0, "No value to peek, array is empty");
    return (_array[_array.length - 1]);
  }

  function stackPush(uint256[] storage _array, uint256 _element) public {
    _array.push(_element);
  }

  function stackPop(uint256[] storage _array) internal returns (uint256) {
    require(_array.length > 0, "No value to pop, array is empty");
    uint256 value = _array[_array.length - 1];
    _array.length -= 1;
    return value;
  }

  function getSize(uint256[] storage _array) internal view returns (uint256) {
    return _array.length;
  }
}
