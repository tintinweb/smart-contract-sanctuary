pragma solidity ^0.4.21;

interface token {
  function transfer(address receiver, uint amount) external;
}

contract IOXDistribution {
    
    address public owner;
    mapping(uint256 => bool) public claimers;
    token public ioxToken;
    
    event Signer(address signer); 
    
    function IOXDistribution(address tokenAddress) public {
        owner = msg.sender;
        ioxToken = token(tokenAddress);
    }
    
    function claim(uint256 claimer, uint256 amount, bytes sig) public {
        bytes32 message = prefixed(keccak256(claimer, amount, this));
        emit Signer(ecrecovery(message, sig));
        require(ecverify(message, sig, owner));
        require(!claimers[claimer]);
        claimers[claimer] = true;    
        ioxToken.transfer(msg.sender, amount *10**18);
    }

    // Destroy contract and reclaim leftover funds.
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(msg.sender);
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hash);
    }
    
    function ecrecovery(bytes32 hash, bytes sig) internal pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      require(sig.length == 65);

      assembly {
        r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := and(mload(add(sig, 65)), 255)
      }

      if (v < 27) {
        v += 27;
      }

      if (v != 27 && v != 28) {
        return 0;
      }

      return ecrecover(hash, v, r, s);
    }

    function ecverify(bytes32 hash, bytes sig, address signer) internal pure returns (bool) {
      return signer == ecrecovery(hash, sig);
    }

}