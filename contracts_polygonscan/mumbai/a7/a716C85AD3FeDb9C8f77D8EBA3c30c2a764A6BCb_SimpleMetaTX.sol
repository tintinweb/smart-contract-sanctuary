// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;
import "./ECDSA.sol";

contract SimpleMetaTX {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function setOwner(address _owner) public {
    owner = _owner;
  }

  // metaTX
  using ECDSA for bytes32;
  event METATX(address indexed delegate, bytes32 hash);

  function process(address _signer, bytes memory _sig, bytes32 _hash) private returns (bool) {
    emit METATX(msg.sender, _hash);
    return _hash.toEthSignedMessageHash().recover(_sig) == _signer;
  }

  function verify(
    address _signer,
    bytes memory _sig,
    uint256 _timeStamp,
    bytes memory _encodeWithSelector) internal returns (bool) {
    return process(
      _signer, _sig, keccak256(abi.encodePacked(_encodeWithSelector, _timeStamp))
    );
  }

  function setOwner(bytes memory _sig, address _signer, address _owner, uint256 _timeStamp) public {
    require (verify(_signer, _sig, _timeStamp, abi.encodeWithSelector(bytes4(0x13af4035), _owner)), "");
    owner = _owner;
  }

}