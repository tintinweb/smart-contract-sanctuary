/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

contract A{
  struct info {
    uint a;
    uint b;
    uint boost;
    uint[5] boosts;
  }
  mapping(uint8=>info) public data;
  
  constructor() public {
  }
  function setData(uint8 _index, uint _a, uint _b, uint _boost, uint[5] memory _boosts) public {
    info memory _info;
    _info.a = _a;
    _info.b = _b;
    _info.boost = _boost;
    _info.boosts = _boosts;
    data[_index] = _info;
  }
  function deleteData(uint8 _index) public {
    delete data[_index];
  }
}