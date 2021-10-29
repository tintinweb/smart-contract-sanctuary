// SPDX-License-Identifier: MIT

/*
    Created by DeNet

    Proof Of Storage  - Consensus for Decentralized Storage.
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IUserStorage.sol";
import "./interfaces/IPayments.sol";
import "./interfaces/INodeNFT.sol";


// TODO: sha256 => keccak256
contract CryptoProofs {
    event WrongError(bytes32 wrong_hash);

    uint256 public base_difficulty;

    constructor(uint256 _baseDifficulty) {
        base_difficulty = _baseDifficulty;
    }

    function isValidSign(
        address _signer,
        bytes memory message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 65) {
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return _signer == ecrecover(sha256(message), v, r, s);
    }

    // TODO: transform merkle proof verification to efficient as OZ
    function isValidMerkleTreeProof(
        bytes32 _root_hash,
        bytes32[] calldata proof
    ) public pure returns (bool) {
        bytes32 next_proof = 0;
        for (uint32 i = 0; i < proof.length / 2; i++) {
            next_proof = sha256(
                abi.encodePacked(proof[i * 2], proof[i * 2 + 1])
            );
            if (proof.length - 1 > i * 2 + 3) {
                if (
                    proof[i * 2 + 2] == next_proof &&
                    proof[i * 2 + 3] == next_proof
                ) {
                    return false;
                }
            } else if (proof.length - 1 > i * 2 + 2) {
                if (proof[i * 2 + 2] != next_proof) {
                    return false;
                }
            }
        }
        return _root_hash == next_proof;
    }

    function isMatchDifficulty(uint256 _proof, uint256 _targetDifficulty)
        public
        view
        returns (bool)
    {
        if (_proof % base_difficulty < _targetDifficulty) {
            return true;
        }
        return false;
    }

    function getBlockNumber() public view returns (uint32) {
        return uint32(block.number);
    }

     // Show Proof for Test
    function getProof(bytes calldata _file, address _sender, uint256 _block_number) public view returns(bytes memory, bytes32) {
        bytes memory _packed = abi.encodePacked(_file, _sender, blockhash(_block_number));
        bytes32 _proof = sha256(_packed);
        return (_packed, _proof);
    }

    function getBlockHash(uint32 _n) public view returns (bytes32) {
        return blockhash(_n);
    }

    function getDifficulty() public view returns(uint256) {
        return base_difficulty;
    }
}

contract Depositable {
    using SafeMath for uint;

    address public paymentsAddress;
    uint256 public maxDepositPerUser = 1000000; // 1 USDC
    uint256 public timeLimit = 604800; // 7 days
    
    mapping(address => mapping(uint32 => uint256)) public limitReached; // time 

    constructor (address _payments) {
        paymentsAddress = _payments;
    }

    function getAvailableDeposit(address _user, uint256 _amount, uint32 _curDate) public view returns (uint256) {
        if (limitReached[_user][_curDate] + _amount >=maxDepositPerUser) {
            return maxDepositPerUser.sub(limitReached[_user][_curDate]);
        }
        return _amount;
    }

    function makeDeposit(address _token, uint256 _amount) public {

        /* Checking Limits */
        uint32 curDate = uint32(block.timestamp.div(timeLimit));
        _amount = getAvailableDeposit(msg.sender, _amount, curDate);
        require(_amount > 0, "Reached deposit limit for this period");

        limitReached[msg.sender][curDate] = limitReached[msg.sender][curDate].add(_amount);
        IPayments _payment = IPayments(paymentsAddress);
        _payment.depositToLocal(msg.sender, _token, _amount);
    }

    function closeDeposit(address _token) public {
        IPayments _payment = IPayments(paymentsAddress);
        _payment.closeDeposit(msg.sender, _token);
    }
}

contract ProofOfStorage is Ownable, CryptoProofs, Depositable {
    using SafeMath for uint;

    address public user_storage_address;
    uint256 private _max_blocks_after_proof = 100;
    address public node_nft_address = address(0);
    
    /*
        This Parametr using to get amount of reward per one mined block.

        Formula (60 * 60 * 24 * 365) / AvBlockTime

        For Ethereum - 2102400
        For Matic - 15768000
        For BSC - 6307200

    */
    uint256 public REWARD_DIFFICULTY = 15768000;  

    constructor(
        address _storage_address,
        address _payments,
        uint256 _baseDifficulty
    ) CryptoProofs(_baseDifficulty) Depositable(_payments) {
        user_storage_address = _storage_address;
    }

    function setNodeNFTAddress(address _new) public onlyOwner {
        node_nft_address = _new;
    }

    function updateRewardDifficulty(uint256 _new) public onlyOwner {
        REWARD_DIFFICULTY = _new;
    }

    function sendProof(
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) public {
        sendProofFrom(
            msg.sender,
            _user_address,
            _block_number,
            _user_root_hash,
            _user_root_hash_nonce,
            _user_signature,
            _file,
            merkleProof
        );
    }

    function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) public {
        // TODO: switch to keccak256
        address signer = ECDSA.recover(
            sha256(abi.encodePacked(
                _user_root_hash,
                uint256(_user_root_hash_nonce)
            )),
            _user_signature
        );
        require(_user_address == signer);

        _sendProofFrom(
            _node_address,
            _user_address,
            _block_number,
            _user_root_hash,
            _user_root_hash_nonce,
            _file,
            merkleProof
        );
    }

    function _updateRootHash(
        address _user,
        address _updater,
        bytes32 new_hash,
        uint64 new_nonce
    ) private {
        bytes32 _cur_user_root_hash;
        uint256 _cur_user_root_hash_nonce;
        (_cur_user_root_hash, _cur_user_root_hash_nonce) = getUserRootHash(
            _user
        );

        require(new_nonce >= _cur_user_root_hash_nonce, "Too old root hash");

        // update root hash if it needed
        if (new_hash != _cur_user_root_hash) {
            _updateLastRootHash(_user, new_hash, new_nonce, _updater);
        }
    }

    function verifyFileProof(
        address _sender,
        bytes calldata _file,
        uint32 _block_number,
        uint256 _blocks_complited
    ) public view returns (bool) {
        require (blockhash(_block_number) != 0x0, "Wrong blockhash");

        bytes32 _file_proof = sha256(
            abi.encodePacked(_file, _sender, blockhash(_block_number))
        );
        return isMatchDifficulty(uint256(_file_proof), _blocks_complited);
    }
    function _checkoutNFT(address _proofer) internal { 
        if (node_nft_address != address(0)) {
            IDeNetNodeNFT NFT = IDeNetNodeNFT(node_nft_address);
            uint timeFromLastProof = block.timestamp - NFT.getLastUpdateByAddress(_proofer);
            /* 
                100% = 4320000
                2% = 86400 (1 day)

                Difficulty += 0-2% per proof if it faster than one day
            */
            if (timeFromLastProof <= 86400) {
                base_difficulty = base_difficulty.mul(4320000 + (86400 - timeFromLastProof)).div(4320000);
            } else {
                timeFromLastProof = timeFromLastProof % 86400;
                base_difficulty = base_difficulty.mul(8640000 - (86400 - timeFromLastProof)).div(8640000);
            }

            /* 
                100% = 8640000
                1% = 86400
                difficulty -= 0-1% (pseudo randomly) per proof if it slower than one day
            */
            NFT.addSuccessProof(_proofer);
        }
    }
    function _sendProofFrom(
        address _proofer,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_root_hash_nonce,
        bytes calldata _file,
        bytes32[] calldata merkleProof
    ) private {
        // not need, with using signature checking
        require(
            _proofer != address(0) && _user_address != address(0),
            "address can't be zero"
        );

        // warning test function without checking  DigitalSIgnature from User SEnding File
        _updateRootHash(
            _user_address,
            _proofer,
            _user_root_hash,
            _user_root_hash_nonce
        );

        bytes32 _file_hash = sha256(_file);
        (
            address _token_to_pay,
            uint256 _amount_returns,
            uint256 _blocks_complited
        ) = getUserRewardInfo(_user_address);

        require(
            _block_number > block.number - _max_blocks_after_proof,
            "Too old proof"
        );
        require(
            isValidMerkleTreeProof(_user_root_hash, merkleProof),
            "Wrong merkleProof"
        );
        require(
            verifyFileProof(
                _proofer,
                _file,
                _block_number,
                _blocks_complited
            ),
            "Not match difficulty"
        );
        require(
            _file_hash == merkleProof[0] || _file_hash == merkleProof[1],
            "not found _file_hash in merkleProof"
        );

        _takePay(_token_to_pay, _user_address, _proofer, _amount_returns);
        _updateLastBlockNumber(_user_address, uint32(block.number));
        _checkoutNFT(_proofer);
    }

    function setUserPlan(address _token) public {
        IUserStorage _storage = IUserStorage(user_storage_address);
        _storage.setUserPlan(msg.sender, _token);
    }

    /*
     Returns info about user reward for ProofOfStorage

        # Input
            @_user - User Address

        # Output
            @_token_ddress - Token Address
            @_amount - Total Token Amount for PoS
            @_cur_block - Last Proof Block
    */
    function getUserRewardInfo(address _user)
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        IPayments _payment = IPayments(paymentsAddress);

        IUserStorage _storage = IUserStorage(user_storage_address);
        address _tokenPay = _storage.getUserPayToken(_user);
        uint256 _userBalance = _payment.getBalance(_tokenPay, _user);

        uint256 _amountPerBlock = _userBalance / REWARD_DIFFICULTY; 
        uint256 _lastBlockNumber = _storage.getUserLastBlockNumber(_user);
        uint256 _proovedBlocks = block.number - _lastBlockNumber;
        uint256 _amountReturns = _proovedBlocks * _amountPerBlock;

        return (_tokenPay, _amountReturns, _proovedBlocks);
    }

    function _takePay(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        IPayments _payment = IPayments(paymentsAddress);
        _payment.localTransferFrom(_token, _from, _to, _amount);
    }

    function getUserRootHash(address _user)
        public
        view
        returns (bytes32, uint256)
    {
        IUserStorage _storage = IUserStorage(user_storage_address);
        return _storage.getUserRootHash(_user);
    }

    function _updateLastBlockNumber(address _user_address, uint32 _block_number)
        private
    {
        IUserStorage _storage = IUserStorage(user_storage_address);
        _storage.updateLastBlockNumber(_user_address, _block_number);
    }

    function _updateLastRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _nonce,
        address _updater
    ) private {
        IUserStorage _storage = IUserStorage(user_storage_address);
        _storage.updateRootHash(
            _user_address,
            _user_root_hash,
            _nonce,
            _updater
        );
    }

    function updateBaseDifficulty(uint256 _new_difficulty) public onlyOwner {
        base_difficulty = _new_difficulty;
    }


    /* 
        test for AUTOTEST
    */
    function admin_set_user_data(address _from, address _user, address _token, uint256 _amount) public onlyOwner {
        IUserStorage _storage = IUserStorage(user_storage_address);
        _storage.setUserPlan(_user, _token);
        IPayments _payment = IPayments(paymentsAddress);
        _payment.localTransferFrom(_token, _from, _user, _amount);
    }

    function changeSystemAddresses(
        address _storage_address,
        address _payments_address
    ) public onlyOwner {
        user_storage_address = _storage_address;
        paymentsAddress = _payments_address;
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/
pragma solidity ^0.8.0;

interface ISimpleINFT {
    // Create or Transfer Node
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Return amount of Nodes by owner
    function balanceOf(address owner) external view returns (uint256);

    // Return Token ID by Node address
    function getNodeIDByAddress(address _node) external view returns (uint256);

    // Return owner address by Token ID
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMetaData {
    // Create or Update Node
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ipAddress,
        uint16 port
    );

    // Structure for Node
    struct DeNetNode{
        uint8[4] ipAddress; // for example [127,0,0,1]
        uint16 port;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 updatesCount;
        uint256 rank;
    }

    // Return Node info by token ID;
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);    
}

interface IDeNetNodeNFT {
     function totalSupply() external view returns (uint256);

     // PoS Only can ecevute
     function addSuccessProof(address _nodeOwner) external;

     function getLastUpdateByAddress(address _user) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IPayments {
    event LocalTransferFrom(
        address indexed _token,
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event RegisterToken(
        address indexed _token,
        uint256 indexed _id
    );

    function getBalance(address _token, address _address)
        external
        view
        returns (uint256 result);

    function localTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function depositToLocal(
        address _user_address,
        address _token,
        uint256 _amount
    ) external;

    function closeDeposit(address _user_address, address _token) external;
}

// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity ^0.8.0;


interface IUserStorage {
    event ChangeRootHash(
        address indexed user_address,
        address indexed node_address,
        bytes32 new_root_hash
    );

    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );

    event ChangePaymentMethod(
        address indexed user_address,
        address indexed token
    );

    function getUserPayToken(address _user_address)
        external
        view
        returns (address);

    function getUserLastBlockNumber(address _user_address)
        external
        view
        returns (uint32);

    function getUserRootHash(address _user_address)
        external
        view
        returns (bytes32, uint256);

    function updateRootHash(
        address _user_address,
        bytes32 _user_root_hash,
        uint64 _nonce,
        address _updater
    ) external;

    function updateLastBlockNumber(address _user_address, uint32 _block_number) external;

    function setUserPlan(address _user_address, address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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
            return; // no error: do nothing
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

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
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

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}