/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

interface IERC721 {
    function getTokenDetails(uint256 index) external view returns (uint32 aType, uint32 customDetails, uint32 lastTx, uint32 lastPayment, uint256 initialvalue, string memory coin);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

contract MarketFees {
    IERC721 nftContract;
    struct FeeFactor {
        uint256 mulFactor;
        uint256 divFactor;
    }
    mapping (uint32 => bool) public zerofeeAssets;
    mapping (address => FeeFactor) public tokenFee;
    
    uint256 public ethFeeFactor;

    mapping (uint8 => address) public managers;
    mapping (bytes32 => bool) public executedTask;
    uint16 public taskIndex;

    modifier isManager() {
        require(managers[0] == msg.sender || managers[1] == msg.sender || managers[2] == msg.sender, "Not manager");
        _;
    }

    constructor() {
        nftContract = IERC721(0xB20217bf3d89667Fa15907971866acD6CcD570C8);
        zerofeeAssets[24] = true;
        managers[0] = msg.sender;
        managers[1] = 0xeA50CE6EBb1a5E4A8F90Bfb35A2fb3c3F0C673ec;
        managers[2] = 0xB1A951141F1b3A16824241f687C3741459E33225;
    }
    
    
    function calcByToken(address _seller, address _token, uint256 _amount) public view returns (uint256 fee) {
        if (tokenFee[_token].mulFactor == 0) {
            return (0);
        } else {
            if (checkZeroFeeAsset(_seller)) {
                return (0);
            } else {
                return ((_amount*tokenFee[_token].mulFactor)/tokenFee[_token].divFactor);
            }
        }
        
    }
    
    function checkZeroFeeAsset(address _seller) private view returns (bool free) {
        uint256 assetCount = nftContract.balanceOf(_seller);
        bool freeTrade;
  
        for (uint i=0; i<assetCount; i++) {
            (uint32 assetType,,,,,) = (nftContract.getTokenDetails(nftContract.tokenOfOwnerByIndex(_seller, i)));
            if (zerofeeAssets[assetType] == true) {
                freeTrade = true;
                break;
            }
        }
        return (freeTrade);
    }
    
    function calcByEth(address _seller, uint256 _amount) public view returns (uint256 fee) {
        if (ethFeeFactor == 0) {
            return (0);
        } else {
            if (checkZeroFeeAsset(_seller)) {
                return (0);
            } else {
                return ((_amount*ethFeeFactor)/1000);
            }
        }
    }
    
    function setTokenFee(address _token, uint256 _mulFactor, uint256 _divFactor, bytes memory _sig) public isManager {
        uint8 mId = 1;
        bytes32 taskHash = keccak256(abi.encode(_token, _mulFactor, _divFactor, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        tokenFee[_token].mulFactor = _mulFactor;
        tokenFee[_token].divFactor = _divFactor;
    }
    
    function setEthFee(uint256 _fee, bytes memory _sig) public isManager {
        uint8 mId = 2;
        bytes32 taskHash = keccak256(abi.encode(_fee, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        ethFeeFactor = _fee;
    }
    
    function verifyApproval(bytes32 _taskHash, bytes memory _sig) private {
        require(executedTask[_taskHash] == false, "Task already executed");
        address mSigner = ECDSA.recover(ECDSA.toEthSignedMessageHash(_taskHash), _sig);
        require(mSigner == managers[0] || mSigner == managers[1] || mSigner == managers[2], "Invalid signature"  );
        require(mSigner != msg.sender, "Signature from different managers required");
        executedTask[_taskHash] = true;
        taskIndex += 1;
    }
    
    function changeManager(address _manager, uint8 _index, bytes memory _sig) public isManager {
        require(_index >= 0 && _index <= 2, "Invalid index");
        uint8 mId = 100;
        bytes32 taskHash = keccak256(abi.encode(_manager, taskIndex, mId));
        verifyApproval(taskHash, _sig);
        managers[_index] = _manager;
    }
    
}