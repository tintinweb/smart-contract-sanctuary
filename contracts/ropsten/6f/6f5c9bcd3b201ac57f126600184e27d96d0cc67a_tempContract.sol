/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract tempContract {
  uint256[] public var_array;
  mapping(uint256=>uint256) public _mapping;
  constructor() public {
    
  }
  function addElement(uint256 _elem) public {
    var_array.push(_elem);
    _mapping[_elem] = _elem*100;
  }
  function arraylength() public view returns(uint256) {
    return var_array.length;
  }
  function getMappingElement(uint256 index_) public view returns(uint256) {
    return _mapping[index_];
  }
  function resetArray() public {
    for(uint256 i=0;i<var_array.length;i++) {
      delete _mapping[i];
    }
    delete var_array;
  }
}