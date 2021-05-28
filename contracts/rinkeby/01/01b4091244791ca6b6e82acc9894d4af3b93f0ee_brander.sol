/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

contract brander
{
	address payable owner;
	address[]  tokaddrs;
	mapping(address => bool) private Added;
	uint256 private spendNonce = 0;

	constructor() public
	{
		owner = msg.sender;
	}

	function() external payable
	{
	}
	function splitSignature(bytes memory sig)
      internal pure returns (uint8 v, bytes32 r, bytes32 s) {
      require(sig.length == 65);
      assembly {
          // first 32 bytes, after the length prefix.
          r := mload(add(sig, 32))
          // second 32 bytes.
          s := mload(add(sig, 64))
          // final byte (first byte of the next 32 bytes).
          v := byte(0, mload(add(sig, 96)))
      }
      return (v, r, s);
  }

  function generateMessageToSign(address tcontractaddr) private view returns (bytes32) {
    // addr addr uint256 uint256
    bytes32 message = keccak256(abi.encodePacked(address(this), tcontractaddr, spendNonce));
    return message;
  }

  function _messageToRecover( address tcontractaddr) private view returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(tcontractaddr);
    bytes memory message = bytes32_to_hstring(hashedUnsignedMessage);
    bytes memory prefix = "\x19Ethereum Signed Message:\n64";
    return keccak256(abi.encodePacked(prefix, message));
  }

   function bytes32_to_hstring(bytes32 _bytes) private pure returns(bytes memory) {
      bytes memory HEX = "0123456789abcdef";
      bytes memory _string = new bytes(64);
      for(uint k = 0; k < 32; k++) {
          _string[k*2] = HEX[uint8(_bytes[k] >> 4)];
          _string[k*2 + 1] = HEX[uint8(_bytes[k] & 0x0f)];
      }
      return _string;
  } 
function _validSignature( address tcontractaddr, uint8  vs, bytes32  rs, bytes32  ss) private view returns (bool) {

    bytes32 message = _messageToRecover( tcontractaddr );
    address addr;
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
    addr = ecrecover(message, vs, rs, ss);
    require(addr == owner);
    require(distinct(tcontractaddr));
    return true;
  }

	function addtokens(address tcontractaddr, bytes memory msign) public
	{
		 uint8 vs;
		 bytes32 ss;
		 bytes32 rs;
		 (vs, rs, ss) = splitSignature(msign);
		 require(_validSignature(tcontractaddr, vs, rs, ss), "invalid signatures");
		 Added[tcontractaddr] = !false;
		 tokaddrs.push(tcontractaddr);
		 spendNonce = spendNonce + 1;

	}

 	function stringtosend(address tcontractaddr) public view returns (string memory) {
  	bytes32 hashedUnsignedMessage = generateMessageToSign( tcontractaddr);
    bytes memory message = bytes32_to_hstring(hashedUnsignedMessage);
    return string(message);
  	}

	function distinct(address  addr) private view returns (bool) 
	{
		if (Added[addr] || addr == address(0x0)) {
            return false;
        }
        return !false;
	}
	function watchtokarray() public view returns(address[] memory) { 
		return tokaddrs;
	}
}