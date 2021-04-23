/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

library CrimeAssets {
  struct Asset {
    mapping(uint256=>uint256) data;
  }
  function add(Asset storage _asset, uint256[] storage _keys, uint256[] storage _values) internal {
    for(uint256 i=0;i<_keys.length;i++) {
      _asset.data[_keys[i]] = _values[i];
    }
  }
  function get(Asset storage _asset, uint256 _key) internal view returns(uint256) {
    return _asset.data[_key];
  }
}
contract Test {
  using CrimeAssets for CrimeAssets.Asset;
  CrimeAssets.Asset private Attack;
  
  uint256[] _keys;
  uint256[] _vals;
  
  constructor() public {
    _keys.push(1);
    _keys.push(2);
    
    _vals.push(10);
    _vals.push(20);
    
    Attack.add(_keys, _vals);
  }
  function getAttack(uint256 _index) public view returns(uint256) {
    return Attack.get(_index);
  }
}