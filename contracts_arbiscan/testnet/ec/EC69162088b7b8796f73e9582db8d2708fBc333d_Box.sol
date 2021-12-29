/**
 *Submitted for verification at arbiscan.io on 2021-12-27
*/

contract Box {
  event ValueSet(uint256 value);

  uint256 public value;

  function setValue(uint256 _value) virtual public {
    value = _value;
    emit ValueSet(value);
  }
}