/**
 *Submitted for verification at Etherscan.io on 2021-02-02
*/

pragma solidity >0.4.99 <0.6.0;

contract Create2 {

  function computeAddress(bytes memory code, uint256 salt) public view returns(address) {
    uint8 prefix = 0xff;
    bytes32 initCodeHash = keccak256(abi.encodePacked(code));
    bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
    return address(uint160(uint256(hash)));
  }

}