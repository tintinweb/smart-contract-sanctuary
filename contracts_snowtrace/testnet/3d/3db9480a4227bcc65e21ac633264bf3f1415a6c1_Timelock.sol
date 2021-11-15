/**
 *Submitted for verification at testnet.snowtrace.io on 2021-11-08
*/

pragma solidity ^0.8.0;


library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; 
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        
        
        
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            
            
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            
            
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}




pragma solidity >=0.8.0;



contract Timelock {
    using ECDSA for bytes32;

    
    
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, bytes data, uint eta);
    event SignerWhitelistChange(address account, bool isWhite, bool oldStatus);

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;
    uint public deadline;

    
    
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;
    mapping (address => bool) public signerWhitelist;

    string public constant name = 'Timelock';
    
    bytes32 constant MULTISIG_TYPEHASH = 0x4ad212875ba25bb5756345c12f631cfb1cc570d754703f23542ff2cd204df03a;
    uint public threshold = 3;
    uint public nonce;
    bytes32 DOMAIN_SEPARATOR;


    constructor(uint delay_, address[] memory committees) {
        require(delay_ >= MINIMUM_DELAY, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        deadline = block.timestamp + 180 days;
        
        delay = delay_;
        DOMAIN_SEPARATOR = keccak256(abi.encode(keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                                            keccak256(bytes(name)),
                                            keccak256(bytes('1')),
                                            block.chainid,
                                            address(this)));
        
        signerWhitelist[committees[0]] = true;
        signerWhitelist[committees[1]] = true;
        signerWhitelist[committees[2]] = true;
        signerWhitelist[committees[3]] = true;
        signerWhitelist[committees[4]] = true;

        
        emit SignerWhitelistChange(committees[0], true, false);
        emit SignerWhitelistChange(committees[1], true, false);
        emit SignerWhitelistChange(committees[2], true, false);
        emit SignerWhitelistChange(committees[3], true, false);
        emit SignerWhitelistChange(committees[4], true, false);

    }

    receive() external payable { }
    fallback() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function setSignerWhitelist(address account, bool isWhite) public {
        require(msg.sender == address(this), "Call must come from Timelock.");
        require(signerWhitelist[account] != isWhite,"state can't be same");

        bool oldStatus = signerWhitelist[account];
        signerWhitelist[account] = isWhite;

        emit SignerWhitelistChange(account, isWhite, oldStatus);
    }


      function queueTransaction(address target, uint value, bytes memory data, uint eta) public returns (bytes32) {
        require(signerWhitelist[msg.sender], "Timelock::queueTransaction: Call must come from signerWhitelist.");
        require(eta >= getBlockTimestamp() + delay, "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, bytes memory data, uint eta) public {
        require(signerWhitelist[msg.sender], "Timelock::cancelTransaction: Call must come from signerWhitelist.");

        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, data, eta);
    }


    function executeTransaction(address target, uint value, bytes memory data, uint eta,uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) public payable returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta+ GRACE_PERIOD, "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        
        

        bytes memory returnData = execute(target,value,data,sigV,sigR,sigS);

        emit ExecuteTransaction(txHash, target, value, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        
        return block.timestamp;
    }

    function execute(address target, uint value, bytes memory data, uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) internal returns (bytes memory) {
        require(sigR.length == threshold, "error sig length");
        require(sigR.length == sigS.length && sigR.length == sigV.length);

        
        bytes32 txInputHash = keccak256(abi.encode(MULTISIG_TYPEHASH, target, value, keccak256(data), nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));
        address lastRecovered = address(0);
        for (uint i = 0; i < sigR.length; i++) {
            address signatory = digest.toEthSignedMessageHash().recover(sigV[i], sigR[i], sigS[i]);
            require(signatory > lastRecovered && signerWhitelist[signatory], "not match");
            lastRecovered = signatory;
        }
        nonce++;
        (bool success, bytes memory returnData) = target.call{value:value}(data);
        require(success, "Transaction execution reverted.");
        return returnData;
    }

    function executeImmediate(address target, uint value, bytes memory data, uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS) public payable returns (bytes memory) {
        require(sigR.length == threshold, "error sig length");
        require(sigR.length == sigS.length && sigR.length == sigV.length);
        require(block.timestamp < deadline,"out of deadline");

        
        bytes32 txInputHash = keccak256(abi.encode(MULTISIG_TYPEHASH, target, value, keccak256(data), nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));
        address lastRecovered = address(0);
        for (uint i = 0; i < sigR.length; i++) {
            address signatory = digest.toEthSignedMessageHash().recover(sigV[i], sigR[i], sigS[i]);
            require(signatory > lastRecovered && signerWhitelist[signatory], "not match");
            lastRecovered = signatory;
        }
        nonce++;
        (bool success, bytes memory returnData) = target.call{value:value}(data);
        require(success, "Transaction execution reverted.");
        return returnData;
    }
}