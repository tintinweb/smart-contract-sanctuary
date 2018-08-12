pragma solidity ^0.4.22;

contract AbstractPublicResolver {
    function addr(bytes32 node) public view returns (address);
}

contract AbstractENS {
    function owner(bytes32 node) public view returns (address);
    function resolver(bytes32 node) public view returns (AbstractPublicResolver);
}

contract FireflyVault {
    AbstractENS _ens;
    address _owner;
    int256 _nonce;
    
    event Sent(address, uint256, int256);
    event Received(address, uint256);
    
    constructor(address ens, address owner) public {
      _ens = AbstractENS(ens); 
      _owner = owner;
      _nonce = -1;
    }
    
    function () payable public {
        require(msg.data.length==0);
        emit Received(msg.sender, msg.value);
    }
    
    function changeOwner(address owner) public {
        require(_owner == msg.sender);
        _owner = owner;
    }

    function namehash(bytes32 name) public pure returns (bytes32) {
        // 
        assembly {
             mstore(0, 0)

             if iszero(byte(0, name)) {
                 return(0, 32)
             }

             let scratch := mload(0x40)
             mstore8(add(scratch, 1), 0x2e)
             mstore(add(scratch, 2), name)

             // Find the end of the null-terminated bstring
             let back := add(scratch, 33)
             let front := sub(back, 1)
             for { } gt(front, scratch) { } {
                 switch byte(0, mload(front))
                     case 0x00 {
                         back := front
                     }
                     case 0x2e {
                         mstore(32, sha3(add(front, 1), sub(sub(back, front), 1)))
                         mstore(0, sha3(0, 64))
                         back := front
                     }
                 front := sub(front, 1)
             }

             return(0, 32)
        }
}
        
    function sendTransaction(address toAddress, uint256 val, int256 nonce) public {
        require(msg.sender == _owner);
        require(_nonce < nonce);
        _nonce = nonce;
        toAddress.transfer(val);
        emit Sent(toAddress, val, nonce);
    }
    
    function sendTransaction(bytes32 ensName, uint256 val, int256 nonce) public {
        require(msg.sender == _owner);
        require(_nonce < nonce);
        _nonce = nonce;
        
        bytes32 nodehash = namehash(ensName);
        AbstractPublicResolver resolver = _ens.resolver(nodehash);
        address addr = resolver.addr(nodehash);
        require(addr != address(0), "ENS name resolved to null addr");
        addr.transfer(val);
        emit Sent(addr, val, nonce);
    }
    
    
}