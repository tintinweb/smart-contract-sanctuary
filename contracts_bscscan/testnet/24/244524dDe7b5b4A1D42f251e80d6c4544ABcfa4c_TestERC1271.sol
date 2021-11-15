/*

  << TestERC1271 >>

*/

pragma solidity 0.7.5;

import "./lib/EIP1271.sol";

contract TestERC1271 is ERC1271 {

    bytes4 constant internal SIGINVALID = 0x00000000;

    address internal owner;

    /**
     * Set a new owner (for testing)
     *
     * @param ownerAddr Address of owner
     */
    function setOwner (address ownerAddr)
        public
    {
        owner = ownerAddr;
    }

    /**
     * Check if a signature is valid
     *
     * @param _data Data signed over
     * @param _signature Encoded signature
     * @return magicValue Magic value if valid, zero-value otherwise
     */
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature)
        override
        public
        view
        returns (bytes4 magicValue)
    {
        bytes32 hash = abi.decode(_data, (bytes32));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(_signature, (uint8, bytes32, bytes32));
        if (owner == ecrecover(hash, v, r, s)) {
            return MAGICVALUE;
        } else {
            return SIGINVALID;
        }
    }

}

/*

  << EIP 1271 >>

*/

pragma solidity 0.7.5;

abstract contract ERC1271 {

  // bytes4(keccak256("isValidSignature(bytes,bytes)")
  bytes4 constant internal MAGICVALUE = 0x20c13b0b;

  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param _data Arbitrary length data signed on the behalf of address(this)
   * @param _signature Signature byte array associated with _data
   *
   * MUST return the bytes4 magic value 0x20c13b0b when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */
  function isValidSignature(
      bytes memory _data,
      bytes memory _signature)
      virtual
      public
      view
      returns (bytes4 magicValue);
}

