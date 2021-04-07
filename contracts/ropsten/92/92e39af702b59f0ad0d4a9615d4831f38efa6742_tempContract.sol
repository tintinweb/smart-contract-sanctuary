/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

contract tempContract {
  uint256[] public var_array;
  
  constructor() public {
    
  }
  function addElement(uint256 _elem) public {
    var_array.push(_elem);
  }
  function resetArray() public {
    delete var_array;
  }
}