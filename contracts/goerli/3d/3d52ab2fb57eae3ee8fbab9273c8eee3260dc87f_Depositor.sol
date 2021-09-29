pragma solidity ^0.8.0;

import "./IgnorantSender.sol";
import "./IERC20.sol";

contract Depositor {
  function getBytecode() public view returns (bytes memory) {
    bytes memory bytecode = type(IgnorantSender).creationCode;
    return abi.encodePacked(bytecode, abi.encode(address(this)));
  }

  function getAddress(bytes memory bytecode, uint salt) public view returns (address) {
    bytes32 hash = keccak256(
      abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
    );
    return address(uint160(uint(hash)));
  }

  function depositAddress(address depositor) public view returns (address) {
    return getAddress(getBytecode(), uint(uint160(depositor)));
  }

  function claimByIgnorance(address depositor, address token, uint amount) public {
    address addr;
    bytes memory bytecode = getBytecode();
    uint salt = uint(uint160(depositor));
    assembly {
      addr := create2(
        callvalue(),
        add(bytecode, 0x20),
        mload(bytecode),
        salt
      )

      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }
    IgnorantSender(addr).transferFunds(token, amount);
    // if we make it this far credit the user for the funds
  }

  function claimByTransfer(address depositor, address token) public {
    uint allowance = IERC20(token).allowance(depositor, address(this));
    IERC20(token).transferFrom(depositor, address(this), allowance);
  }
}