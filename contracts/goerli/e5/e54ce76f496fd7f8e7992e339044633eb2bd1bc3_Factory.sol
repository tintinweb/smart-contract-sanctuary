/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity >0.4.99 <0.6.0;

contract Factory {
  event Deployed(address addr, uint256 salt);

  function deploy(bytes memory code, uint256 salt) public {
    address addr;

    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    emit Deployed(addr, salt);
  }

  function getCreate2Address(bytes memory code, uint256 salt) public view returns (address) {
      bytes32 rawAddress = keccak256(abi.encodePacked(
                                bytes1(0xff), address(this), salt,
                                bytes32(keccak256(code))));
                    
        return address(bytes20(rawAddress << 96));
  }
}