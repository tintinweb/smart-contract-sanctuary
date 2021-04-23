/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

library CrimeAssets {
  struct Asset {
    mapping(uint256=>uint256) values;
    mapping(uint256=>uint256) costs;
    uint256[] indexes;
  }
  function set(Asset storage _asset, uint256 _index, uint256 _value, uint256 _cost) internal {
    _asset.values[_index] = _value;
    _asset.costs[_index] = _cost;
    if ( isNew(_asset, _index) ) {
      _asset.indexes.push(_index);
    }
  }
  function get(Asset storage _asset, uint256 _index) internal view returns (uint256, uint256) {
    return (_asset.values[_index], _asset.costs[_index]);
  }
  function remove(Asset storage _asset, uint256 _index) internal {
    require(isNew(_asset, _index) == false, "Error: invalid index.");
    for(uint256 i=0;i<_asset.indexes.length;i++) {
      if ( _asset.indexes[i] == _index ) delete _asset.indexes[i];
    }
    delete _asset.values[_index];
    delete _asset.costs[_index];
  }
  function isNew(Asset storage _asset, uint256 _index) internal view returns (bool) {
    for(uint256 i=0;i<_asset.indexes.length;i++) {
      if ( _asset.indexes[i] == _index ) return false;
    }
    return true;
  }
}
contract Test {
  using CrimeAssets for CrimeAssets.Asset;
  CrimeAssets.Asset private Attack;
  CrimeAssets.Asset private Defense;
  constructor() public {
    Attack.set(1, 10, 500);
    Attack.set(2, 20, 600);
    Attack.set(3, 30, 700);
    Attack.remove(2);
    
    Defense.set(1, 100, 5000);
    Defense.set(2, 200, 6000);
    Defense.set(3, 300, 7000);
    Defense.remove(1);
  }
  function getAttack(uint256 _index) public view returns(uint256, uint256) {
    return Attack.get(_index);
  }
  function getAttackIndexes() public view returns(uint256[] memory _indexes) {
    _indexes = Attack.indexes;
  }
  function getDefense(uint256 _index) public view returns(uint256, uint256) {
    return Defense.get(_index);
  }
  function getDefenseIndexes() public view returns(uint256[] memory _indexes) {
    _indexes = Defense.indexes;
  }
}