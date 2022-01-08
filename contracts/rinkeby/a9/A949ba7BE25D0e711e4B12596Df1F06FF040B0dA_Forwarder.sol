/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity ^0.4.23;

contract ERC20Interface {

function balanceOf(address tokenOwner) public view returns (uint balance);
function transferForm(address from,address to, uint tokens) public returns (bool success);

event Transfer(address indexed from, address indexed to, uint tokens);
}

/**
 * Contract that will forward any incoming Ether to the creator of the contract
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address public parentAddress;

  mapping (bytes => bool) private _signatures;
  mapping(address => uint256) public nonces;

event TransferForm(address indexed from, address indexed to, uint tokens);
  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the parent address
   */
  function() public payable {
    // throws on failure
    parentAddress.transfer(msg.value);
    
  }


  function transferPreSigned(
        bytes _signature,
        address _contractAddress,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        returns (bool)
    {
       
        require(_to != address(0));
        require(_signatures[_signature] == false);
        
        bytes32 hashedTx = transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);
        parentAddress= recover(hashedTx, _signature);
        
        ERC20Interface instance = ERC20Interface(_contractAddress);
        uint256 forwarderBalance = instance.balanceOf(parentAddress);
        if (forwarderBalance > _value || forwarderBalance == 0) {
        return false;
        }
        
        instance.transferForm(parentAddress,_to, forwarderBalance);
        emit TransferForm(parentAddress, _to,  forwarderBalance);


        nonces[msg.sender] = _nonce;
        _signatures[_signature] = true;

      
        return true;
    }

 
    function transferPreSignedHashing(
        address _token,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        pure
        returns (bytes32)
    {
        
        return keccak256(abi.encodePacked(_token, _to, _value, _fee, _nonce));
    }

    /**
     * @notice Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(hash, v, r, s);
      }
    }


}