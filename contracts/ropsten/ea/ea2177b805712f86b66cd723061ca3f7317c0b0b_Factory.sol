/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// create2  playground by @pldespaigne
// based on contract written by @miguelmota & @ricmoo

pragma solidity >0.4.99 <0.6.0;

contract Factory {
  event Deployed(address addr, uint256 salt);

  function deploy(bytes memory code, uint256 salt) public returns(address) {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    emit Deployed(addr, salt);
    return addr;
  }
  
  function computeAddress(bytes memory code, uint256 salt) public view returns(address) {
    uint8 prefix = 0xff;
    bytes32 initCodeHash = keccak256(abi.encodePacked(code));
    bytes32 hash = keccak256(abi.encodePacked(prefix, address(this), salt, initCodeHash));
    return address(uint160(uint256(hash)));
  }
}