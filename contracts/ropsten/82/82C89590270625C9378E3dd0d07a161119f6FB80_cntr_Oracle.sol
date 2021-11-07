/**
 *Submitted for verification at Etherscan.io on 2021-11-07
*/

interface umb_Validator {
  function verifyProofForBlock(
    uint256 _blockHeight,
    bytes32[] memory _proof,
    bytes memory _key,
    bytes memory _value) external returns (bool);
}

contract cntr_Oracle {
  address validator;
  address owner;
  bytes value;
  uint evId;
  event stateUpdated(uint indexed evId, string message);
  event storedValue(uint indexed evId, bytes value);

  constructor(
    address _validator,
    address _owner,
    uint256 _blockHeight,
    bytes32[] memory _proof,
    bytes memory _key,
    bytes memory _value
    ) {
    evId = 0;
    validator = _validator;
    owner = _owner;
    updateState(_blockHeight, _proof, _key, _value);
  }

  function updateState(
    uint256 _blockHeight,
    bytes32[] memory _proof,
    bytes memory _key,
    bytes memory _value
    ) public {
    require(msg.sender == owner);
    require(verifyData(_blockHeight, _proof, _key, _value));
    evId = evId + 1;
    value = _value;
    emit stateUpdated(evId, "State Updated Succesfully");
  }

  function verifyData(
    uint256 _blockHeight,
    bytes32[] memory _proof,
    bytes memory _key,
    bytes memory _value
    ) private returns (bool) {
    bool res = umb_Validator(validator).verifyProofForBlock(_blockHeight, _proof, _key, _value);
    return res;
  }

  function querryValue() public returns (bytes memory) {
    emit storedValue(evId, value);
    evId = evId + 1;
    return value;
  }
}