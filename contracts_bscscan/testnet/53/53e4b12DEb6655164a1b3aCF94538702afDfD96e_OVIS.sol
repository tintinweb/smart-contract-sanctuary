/**
 *Submitted for verification at BscScan.com on 2021-12-02
*/

// File: contracts/lib/Utils.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

library Utils {
    enum Roles {
        USER,
        JOURNALIST,
        EDITOR,
        FACTCHECKER,
        ADMIN,
        MINTER
    }

    enum SuggestionType {
        COMMUNITY,
        STORY
    }

    struct Journalist {
        address jAddress;
        uint256 due;
    }

    struct Editor {
        address eAddress;
        uint256 due;
        Utils.EditorDecision decision;
    }

    struct FactChecker {
        address fcAddress;
        uint256 due;
    }

    struct SuggestionStake {
        uint256 oStake;
        uint256 jStake;
        uint256 eStake;
        uint256 tStake;
    }

        struct CSuggestionStake {
        uint256 tStake;
        uint256 _15Reward;
        uint256 _51Reward;
    }

    struct Suggestions {
        string uuid;
        address createdBy;
        Journalist journalist;
        Editor editor;
        FactChecker[3] fCs;
        Utils.FactCheckerDecision[3] fcPoll;
        Utils.Status status;
    }

    struct CommunitySuggestion {
        string uuid;
        address createdBy;
        Utils.Status cStatus;
        uint256 tVotes;
    }

    enum Status {
        SUBMITTED,
        CLAIMED,
        FILED,
        EDITORCLAIMED,
        EDITED,
        FACTCHECKED,
        PUBLISHED,
        SUPPORTED,
        ADOPTED
    }

    enum EditorDecision {
        NONETAKEN, // 0
        APPROVED, // 1
        REQUESTEDIT, // 2
        REJECTED // 3
    }

    enum FactCheckerDecision {
        NONETAKEN,
        APPROVED,
        REJECTED
    }

    enum ERROR {
        NONCE_REUSED,
        CREATOR_JOURNALIST_CONFLICT,
        CREATOR_EDITOR_CONFLICT,
        CREATOR_FACTCHECKER_CONFLICT,
        JOURNALIST_EDITOR_CONFLICT,
        JOURNALIST_FACTCHECKER_CONFLICT,
        EDITOR_FACTCHECKER_CONFLICT,
        FACTCHECKER_JOURNALIST_CONFLICT,
        JOURNALIST_NOT_AUTHORIZED,
        ZERO_ADDRESS,
        INVALID_SIGNATURE,
        ALREADY_CLAIMED,
        ALREADY_EXIST,
        ALREADY_FILED,
        ALREADY_ENROLLED,
        STAKE_ERROR,
        SUGGESTION_NOT_FOUND,
        VOTE_ADOPTED,
        INCREASE_CLAIMED,
        INCREASE_FILED,
        EDITOR_NOT_AUTHORIZED,
        INCREASE_DECIDED,
        NOT_CREATOR,
        EDITOR_DECISION_TAKEN,
        CANT_PUBLISH,
        POLL_COMPROMISED,
        CANT_ENROLL,
        ZERO_STAKE,
        REWARD_ERROR,
        FC_QUEUE_FULL,
        FC_NOT_AUTHORIZED,
        PAYMENT_FAILED
    }
}

// File: contracts/IOVIS.sol

interface IOVIS {
    struct Signature {
        string message;
        string nonce;
        bytes signature;
    }

    function submitSuggestion(string memory sID, uint256 _stake)
        external
        returns (bool);

    function getSuggestion(string memory sID)
        external
        returns (Utils.Suggestions memory);

    function getCSuggestion(string memory sID)
        external
        returns (Utils.CommunitySuggestion memory);

    function submitCommunitySuggestion(string memory sID, uint256 _stake)
        external
        returns (bool);

    function voteCommunitySuggestion(
        string memory sID,
        uint256 amount,
        uint256 message,
        bytes calldata signature
    ) external returns (bool);

    function claimSuggestionAsJournalist(
        string memory sID,
        uint256 amount,
        uint256 dueDate,
        Signature calldata _signature
    ) external returns (bool);

    function claimSuggestionAsEditor(
        string memory sID,
        uint256 amount,
        uint256 dueDate,
        Signature calldata _signature
    ) external returns (bool);

    /**
     * @dev Emitted when `suggestionUUID` is submitted by (`from`) with stake (`amount`)
     *
     * Note that `amount` should be 5<x<100.
     */
    event SuggestionSubmitted(
        address indexed from,
        string suggestionUUID,
        uint256 amount
    );

    /**
     * @dev Emitted when community suggestion `suggestionUUID` is submitted by (`from`) with stake (`amount`)
     *
     * Note that `amount` should be 5<x<100.
     */
    event CommunitySuggestionSubmitted(
        address indexed submittedBy,
        string suggestionUUID,
        uint256 amount
    );

    event CommunitySupported(string suggestionUUID);
    event CommunityAdopted(string suggestionUUID);

    /**
     * @dev Emitted when `suggestionUUID` is claimed by (`journalist`) with stake (`amount`)
     *
     * Note that `amount` should be 5<x<100.
     */

    event SuggestionClaimed(
        address indexed journalist,
        string suggestionUUID,
        uint256 amount,
        uint256 dueDate
    );

    /**
     * @dev Emitted when `suggestionUUID` is filed by `journalist`.
     *
     */
    event SuggestionDraftFiled(
        address indexed journalist,
        string suggestionUUID
    );

    /**
     * @dev Emitted when previlaged user `editor` stakes `amount` for
     * `suggestionUUID`.
     */
    event EditorClaimedSuggestion(
        address indexed claimedBy,
        string suggestionUUID,
        uint256 amount,
        uint256 dueDate
    );

    event EditorRequestedChanges(
        address indexed decisionBy,
        string suggestionUUID
    );

    event EditorApproved(address indexed decisionBy, string suggestionUUID);
    event EditorRejected(address indexed decisionBy, string suggestionUUID);

    event FactCheckerEnrolled(
        address indexed enrolledBy,
        string suggestionUUID,
        uint256 dueDate
    );

    event FCApproved(address indexed approvedBy, string suggestionUUID);
    event FCRejected(address indexed rejectedBy, string suggestionUUID);

    event FactChecked(
        string suggestionUUID,
        Utils.FactCheckerDecision finalDecision
    );

    event SuggestionPublished(string suggestionUUID, uint256 timeStamp);

    event TruthTokenPurchased(address boughtBy, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are staked for a vote account (`by`) on
     * suggestion (`suggestionUUID`).
     *
     * Note that `amount` should be 5<x<100.
     *
     */
    event Voted(address indexed by, string suggestionUUID, uint256 amount);
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

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

// File: contracts/IOSWENTStake.sol

interface IOSWENTStake {
    struct Signature {
        string message;
        string nonce;
        bytes signature;
    }

    function getCommunityAddress() external view returns (address);

    function getMinStake() external view returns (uint256);

    function setMinStake(uint256 _minStake) external;

    function getMaxStake() external view returns (uint256);

    function setMaxStake(uint256 _maxStake) external;

    function getStake(string memory sID)
        external
        view
        returns (Utils.SuggestionStake memory);

    function getUStake(address account, string memory sID)
        external
        view
        returns (uint256);

    function getCommunityStake(string memory sID)
        external
        view
        returns (Utils.CSuggestionStake memory);

    function getUCommunityStake(address account, string memory sID)
        external
        view
        returns (uint256);

    function getTruthTokenAddress() external view returns (address);

    function stake(
        address account,
        string memory sID,
        uint256 amount,
        Utils.SuggestionType sType
    ) external returns (bool);

    function increaseStake(
        address account,
        string memory sID,
        uint256 amount,
        Utils.SuggestionType sType,
        Utils.Roles role
    ) external returns (bool);

    function roleStake(
        address by,
        string memory sID,
        uint256 amount,
        Utils.Roles role
    ) external returns (bool);

    function getJStake(string memory sID) external view returns (uint256);

    function removeJStake(string memory sID) external returns (bool);

    function calculateReward(string memory sID, uint256 percent)
        external
        view
        returns (uint256);

    function transferReward15(address recipient, string memory sID)
        external
        returns (bool);

    function transferReward51(address recipient, string memory sID)
        external
        returns (bool);

    /**
     * @dev Emitted when `amount` tokens are staked from account (`from`) on
     * suggestion (`sID`).
     *
     * Note that `amount` should be 5<x<100.
     *
     */
    event Staked(address indexed from, string sID, uint256 amount);

    event Rewarded(address indexed to, string sID, uint256 amount);

    /**
     * @dev Emitted when previlaged user `by` adds stake (`amount`) for
     * `sID`.
     */

    event StakeIncreased(
        address indexed by,
        string sID,
        uint256 amount,
        Utils.Roles role
    );
}

// File: contracts/lib/Messages.sol

library ErrorMessages {
    struct Error {
        string message;
    }

    function messageStorage()
        internal
        pure
        returns (Error storage errorMessage)
    {
        bytes32 position = keccak256("message.storage");
        assembly {
            errorMessage.slot := position
        }
    }

    function getError(Utils.ERROR eType)
        internal
        returns (Error storage errorMessage)
    {
        Error storage eMSG = messageStorage();
        if (eType == Utils.ERROR.NONCE_REUSED) {
            eMSG.message = "Nonce has been reused";
        } else if (eType == Utils.ERROR.INVALID_SIGNATURE) {
            eMSG.message = "Invalid signature";
        } else if (eType == Utils.ERROR.ZERO_ADDRESS) {
            eMSG.message = "Address cannot be the zero.";
        } else if (eType == Utils.ERROR.SUGGESTION_NOT_FOUND) {
            eMSG.message = "Suggestion not found.";
        } else if (eType == Utils.ERROR.ALREADY_EXIST) {
            eMSG.message = "Suggestion is already exists.";
        } else if (eType == Utils.ERROR.ALREADY_CLAIMED) {
            eMSG.message = "Suggestion is already claimed.";
        } else if (eType == Utils.ERROR.ALREADY_FILED) {
            eMSG.message = "Suggestion is already filed.";
        } else if (eType == Utils.ERROR.ALREADY_ENROLLED) {
            eMSG.message = "You already enrolled this suggestion.";
        } else if (eType == Utils.ERROR.CREATOR_JOURNALIST_CONFLICT) {
            eMSG
                .message = "Creator and Journalist cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.CREATOR_EDITOR_CONFLICT) {
            eMSG
                .message = "Creator and Editor cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.CREATOR_FACTCHECKER_CONFLICT) {
            eMSG
                .message = "Creator and Fact Checker cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.JOURNALIST_EDITOR_CONFLICT) {
            eMSG
                .message = "Journalist and Editor cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.JOURNALIST_FACTCHECKER_CONFLICT) {
            eMSG
                .message = "Journalist and Fact Checker cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.EDITOR_FACTCHECKER_CONFLICT) {
            eMSG
                .message = "Editor and Fact Checker cannot be the same for a suggestion.";
        } else if (eType == Utils.ERROR.FACTCHECKER_JOURNALIST_CONFLICT) {
            eMSG
                .message = "FC cannot claim the same suggestion as a journalist.";
        } else if (eType == Utils.ERROR.JOURNALIST_NOT_AUTHORIZED) {
            eMSG.message = "You are not the journalist for this suggestion.";
        } else if (eType == Utils.ERROR.STAKE_ERROR) {
            eMSG.message = "Error in staking.";
        } else if (eType == Utils.ERROR.VOTE_ADOPTED) {
            eMSG.message = "You can't vote an adopted suggestion.";
        } else if (eType == Utils.ERROR.INCREASE_FILED) {
            eMSG
                .message = "You can't increase your stake after the suggestion is filed.";
        } else if (eType == Utils.ERROR.INCREASE_CLAIMED) {
            eMSG
                .message = "You can't increase your stake after the suggestion is claimed.";
        } else if (eType == Utils.ERROR.EDITOR_NOT_AUTHORIZED) {
            eMSG.message = "You are not the editor for this suggestion.";
        } else if (eType == Utils.ERROR.INCREASE_DECIDED) {
            eMSG
                .message = "You can't increase your stake after the editor decision is made.";
        } else if (eType == Utils.ERROR.NOT_CREATOR) {
            eMSG.message = "This suggestion not belongs to you.";
        } else if (eType == Utils.ERROR.EDITOR_DECISION_TAKEN) {
            eMSG.message = "The decision is already taken.";
        } else if (eType == Utils.ERROR.CANT_PUBLISH) {
            eMSG.message = "You can't publish this draft now.";
        } else if (eType == Utils.ERROR.POLL_COMPROMISED) {
            eMSG.message = "Poll have been compromised already.";
        } else if (eType == Utils.ERROR.CANT_ENROLL) {
            eMSG.message = "You can't enroll for this draft now.";
        } else if (eType == Utils.ERROR.ZERO_STAKE) {
            eMSG.message = "Stake amount cannot be 0";
        } else if (eType == Utils.ERROR.REWARD_ERROR) {
            eMSG.message = "Failed in transferring reward.";
        } else if (eType == Utils.ERROR.FC_QUEUE_FULL) {
            eMSG.message = "Fact Checker queue is full.";
        } else if (eType == Utils.ERROR.FC_NOT_AUTHORIZED) {
            eMSG.message = "You are not enrolled for this suggestion";
        } else if (eType == Utils.ERROR.PAYMENT_FAILED) {
            eMSG.message = "Payment Failed.";
        }

        return eMSG;
    }
}

// File: contracts/OVIS.sol

contract OVIS is IOVIS, Ownable {
    mapping(string => Utils.Suggestions) private _suggestions;
    mapping(string => Utils.CommunitySuggestion) private _cSuggestions;

    mapping(string => bool) private _nonces;

    address cAddress;
    IOSWENTStake private ovisStake;

    modifier validateSignature(Signature calldata _signature) {
        require(
            !_nonces[_signature.nonce],
            ErrorMessages.getError(Utils.ERROR.NONCE_REUSED).message
        );
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(_signature.message, _signature.nonce))
        );

        address signer = ECDSA.recover(
            ethSignedMessageHash,
            _signature.signature
        );
        if (signer != cAddress) {
            revert(
                ErrorMessages.getError(Utils.ERROR.INVALID_SIGNATURE).message
            );
        }
        _;
    }

    modifier isClaimable(string memory sID) {
        if (block.timestamp < _suggestions[sID].journalist.due) {
            revert(ErrorMessages.getError(Utils.ERROR.ALREADY_CLAIMED).message);
        }
        _;
    }

    modifier isDuePassed(string memory sID) {
        if (block.timestamp > _suggestions[sID].journalist.due) {
            revert(
                ErrorMessages
                    .getError(Utils.ERROR.JOURNALIST_NOT_AUTHORIZED)
                    .message
            );
        }
        _;
    }

    function _isEnrolledAlready(string memory sID)
        internal
        virtual
        returns (bool, uint8)
    {
        uint8 slot;
        bool isEnrolled;
        for (uint8 index = 1; index <= 3; index++) {
            if (_msgSender() == _suggestions[sID].fCs[index - 1].fcAddress) {
                isEnrolled = true;
                slot = index;
            }
        }
        return (isEnrolled, slot);
    }

    function _isPollCompromised(string memory sID)
        internal
        virtual
        returns (
            bool,
            int8,
            int8
        )
    {
        int8 approved = 0;
        int8 rejected = 0;
        for (uint8 index = 0; index < 3; index++) {
            if (
                _suggestions[sID].fcPoll[index] ==
                Utils.FactCheckerDecision.APPROVED
            ) {
                approved += 1;
            } else if (
                _suggestions[sID].fcPoll[index] ==
                Utils.FactCheckerDecision.REJECTED
            ) {
                rejected += 1;
            }
        }
        return (
            (approved == 2 || rejected == -2) ? true : false,
            approved,
            rejected
        );
    }

    function _cycleUser(string memory sID, Utils.Roles forRole)
        internal
        virtual
    {
        if (forRole == Utils.Roles.JOURNALIST) {
            require(
                _msgSender() != _suggestions[sID].createdBy,
                ErrorMessages
                    .getError(Utils.ERROR.CREATOR_JOURNALIST_CONFLICT)
                    .message
            );
            require(
                _msgSender() != _suggestions[sID].editor.eAddress,
                ErrorMessages
                    .getError(Utils.ERROR.JOURNALIST_EDITOR_CONFLICT)
                    .message
            );

            (bool isEnrolled, ) = _isEnrolledAlready(sID);
            require(
                !isEnrolled,
                ErrorMessages
                    .getError(Utils.ERROR.JOURNALIST_FACTCHECKER_CONFLICT)
                    .message
            );
        }
        if (forRole == Utils.Roles.EDITOR) {
            require(
                _msgSender() != _suggestions[sID].createdBy,
                ErrorMessages
                    .getError(Utils.ERROR.CREATOR_EDITOR_CONFLICT)
                    .message
            );

            require(
                _msgSender() != _suggestions[sID].journalist.jAddress,
                ErrorMessages
                    .getError(Utils.ERROR.JOURNALIST_EDITOR_CONFLICT)
                    .message
            );

            require(
                _suggestions[sID].editor.eAddress == address(0),
                ErrorMessages.getError(Utils.ERROR.ALREADY_CLAIMED).message
            );
        }
        if (forRole == Utils.Roles.FACTCHECKER) {
            (bool isEnrolled, ) = _isEnrolledAlready(sID);
            require(
                !isEnrolled,
                ErrorMessages.getError(Utils.ERROR.ALREADY_ENROLLED).message
            );
            require(
                _msgSender() != _suggestions[sID].createdBy,
                ErrorMessages
                    .getError(Utils.ERROR.CREATOR_FACTCHECKER_CONFLICT)
                    .message
            );
        }
    }

    constructor(address _stakeContract, address _communityAddress) {
        require(
            _stakeContract != address(0),
            ErrorMessages.getError(Utils.ERROR.ZERO_ADDRESS).message
        );
        require(
            _communityAddress != address(0),
            ErrorMessages.getError(Utils.ERROR.ZERO_ADDRESS).message
        );
        cAddress = _communityAddress;
        ovisStake = IOSWENTStake(_stakeContract);
    }

    function submitSuggestion(string memory _sID, uint256 _stake)
        public
        virtual
        override
        returns (bool)
    {
        require(
            bytes(_suggestions[_sID].uuid).length == 0,
            ErrorMessages.getError(Utils.ERROR.ALREADY_EXIST).message
        );

        ovisStake.roleStake(_msgSender(), _sID, _stake, Utils.Roles.USER);

        Utils.Suggestions storage newSuggestion = _suggestions[_sID];
        newSuggestion.uuid = _sID;
        newSuggestion.createdBy = _msgSender();
        newSuggestion.status = Utils.Status.SUBMITTED;

        _suggestions[_sID] = newSuggestion;
        emit SuggestionSubmitted(_msgSender(), _sID, _stake);

        return true;
    }

    function vote(string memory sID, uint256 amount) public returns (bool) {
        ovisStake.stake(_msgSender(), sID, amount, Utils.SuggestionType.STORY);

        emit Voted(_msgSender(), sID, amount);
        return true;
    }

    function submitCommunitySuggestion(string memory sID, uint256 stakeAmount)
        public
        override
        returns (bool)
    {
        require(
            bytes(_cSuggestions[sID].uuid).length == 0,
            ErrorMessages.getError(Utils.ERROR.ALREADY_EXIST).message
        );

        ovisStake.stake(
            _msgSender(),
            sID,
            stakeAmount,
            Utils.SuggestionType.COMMUNITY
        );

        _cSuggestions[sID] = Utils.CommunitySuggestion({
            uuid: sID,
            createdBy: _msgSender(),
            cStatus: Utils.Status.SUBMITTED,
            tVotes: 0
        });
        emit CommunitySuggestionSubmitted(_msgSender(), sID, stakeAmount);

        return true;
    }

    function voteCommunitySuggestion(
        string memory sID,
        uint256 amount,
        uint256 message,
        bytes calldata signature
    ) public override returns (bool) {
        require(
            bytes(_cSuggestions[sID].uuid).length != 0,
            ErrorMessages.getError(Utils.ERROR.SUGGESTION_NOT_FOUND).message
        );

        require(
            _cSuggestions[sID].cStatus != Utils.Status.ADOPTED,
            ErrorMessages.getError(Utils.ERROR.VOTE_ADOPTED).message
        );

        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            keccak256(abi.encodePacked(message))
        );

        address signer = ECDSA.recover(ethSignedMessageHash, signature);
        require(
            signer == cAddress,
            ErrorMessages.getError(Utils.ERROR.INVALID_SIGNATURE).message
        );

        ovisStake.stake(_msgSender(), sID, amount, Utils.SuggestionType.STORY);

        if (
            message > 15 &&
            (_cSuggestions[sID].cStatus == Utils.Status.SUBMITTED)
        ) {
            _cSuggestions[sID].cStatus = Utils.Status.SUPPORTED;
            emit CommunitySupported(sID);
            ovisStake.transferReward15(_cSuggestions[sID].createdBy, sID);
        }

        if (message > 51) {
            _cSuggestions[sID].cStatus = Utils.Status.ADOPTED;
            emit CommunityAdopted(sID);
            ovisStake.transferReward51(_cSuggestions[sID].createdBy, sID);
        }

        emit Voted(_msgSender(), sID, amount);

        return true;
    }

    function increaseSubmissionStake(
        string memory sID,
        uint256 amount,
        Utils.SuggestionType sType
    ) public returns (bool) {
        if (sType == Utils.SuggestionType.STORY) {
            require(
                _suggestions[sID].createdBy == _msgSender(),
                ErrorMessages.getError(Utils.ERROR.NOT_CREATOR).message
            );
            require(
                _suggestions[sID].status == Utils.Status.SUBMITTED,
                ErrorMessages.getError(Utils.ERROR.INCREASE_CLAIMED).message
            );
            ovisStake.increaseStake(
                _msgSender(),
                sID,
                amount,
                Utils.SuggestionType.STORY,
                Utils.Roles.USER
            );
        } else {
            require(
                _cSuggestions[sID].createdBy == _msgSender(),
                ErrorMessages.getError(Utils.ERROR.NOT_CREATOR).message
            );
            require(
                _cSuggestions[sID].cStatus == Utils.Status.SUBMITTED,
                ErrorMessages.getError(Utils.ERROR.INCREASE_CLAIMED).message
            );
            ovisStake.increaseStake(
                _msgSender(),
                sID,
                amount,
                Utils.SuggestionType.COMMUNITY,
                Utils.Roles.USER
            );
        }

        return true;
    }

    function claimSuggestionAsJournalist(
        string memory sID,
        uint256 amount,
        uint256 due,
        Signature calldata signature
    )
        public
        override
        validateSignature(signature)
        returns (bool)
    {
        _nonces[signature.nonce] = true;
        require(
            bytes(_suggestions[sID].uuid).length != 0,
            ErrorMessages.getError(Utils.ERROR.SUGGESTION_NOT_FOUND).message
        );
        _cycleUser(sID, Utils.Roles.JOURNALIST);

        ovisStake.roleStake(_msgSender(), sID, amount, Utils.Roles.JOURNALIST);
        _suggestions[sID].journalist = Utils.Journalist({
            jAddress: _msgSender(),
            due: due
        });
        _suggestions[sID].status = Utils.Status.CLAIMED;

        emit SuggestionClaimed(_msgSender(), sID, amount, due);

        return true;
    }

    function claimSuggestionAsEditor(
        string memory sID,
        uint256 amount,
        uint256 due,
        Signature calldata signature
    ) public override returns (bool) {
        _nonces[signature.nonce] = true;
        _cycleUser(sID, Utils.Roles.EDITOR);

        ovisStake.roleStake(_msgSender(), sID, amount, Utils.Roles.EDITOR);
        _suggestions[sID].editor = Utils.Editor({
            eAddress: _msgSender(),
            due: due,
            decision: Utils.EditorDecision.NONETAKEN
        });

        _suggestions[sID].status = Utils.Status.EDITORCLAIMED;

        emit EditorClaimedSuggestion(_msgSender(), sID, amount, due);
        return true;
    }

    function fileSuggestionDraft(string memory sID)
        public
        isDuePassed(sID)
        returns (bool)
    {
        if (
            _suggestions[sID].editor.decision !=
            Utils.EditorDecision.REQUESTEDIT &&
            _suggestions[sID].status != Utils.Status.CLAIMED
        ) {
            revert(ErrorMessages.getError(Utils.ERROR.ALREADY_FILED).message);
        }

        require(
            _suggestions[sID].journalist.jAddress == _msgSender(),
            ErrorMessages
                .getError(Utils.ERROR.JOURNALIST_NOT_AUTHORIZED)
                .message
        );

        if (
            _suggestions[sID].editor.decision == Utils.EditorDecision.NONETAKEN
        ) {
            _suggestions[sID].status = Utils.Status.FILED;
        } else {
            _suggestions[sID].status = Utils.Status.EDITORCLAIMED;
            _suggestions[sID].editor.decision = Utils.EditorDecision.NONETAKEN;
        }

        emit SuggestionDraftFiled(_msgSender(), sID);

        return true;
    }

    function addStakeAsJournalist(string memory sID, uint256 amount)
        public
        returns (bool)
    {
        require(
            _suggestions[sID].journalist.jAddress == _msgSender(),
            ErrorMessages
                .getError(Utils.ERROR.JOURNALIST_NOT_AUTHORIZED)
                .message
        );

        require(
            _suggestions[sID].status == Utils.Status.CLAIMED,
            ErrorMessages.getError(Utils.ERROR.INCREASE_FILED).message
        );

        ovisStake.increaseStake(
            _msgSender(),
            sID,
            amount,
            Utils.SuggestionType.STORY,
            Utils.Roles.JOURNALIST
        );

        return true;
    }

    function addStakeAsEditor(string memory sID, uint256 amount)
        public
        returns (bool)
    {
        require(
            _suggestions[sID].editor.eAddress == _msgSender(),
            ErrorMessages.getError(Utils.ERROR.EDITOR_NOT_AUTHORIZED).message
        );

        require(
            _suggestions[sID].status == Utils.Status.EDITORCLAIMED,
            ErrorMessages.getError(Utils.ERROR.INCREASE_DECIDED).message
        );

        ovisStake.increaseStake(
            _msgSender(),
            sID,
            amount,
            Utils.SuggestionType.STORY,
            Utils.Roles.EDITOR
        );

        return true;
    }

    function submitEditorDecision(
        string memory sID,
        Utils.EditorDecision decision
    ) public returns (bool) {
        require(
            _suggestions[sID].editor.eAddress == _msgSender(),
            ErrorMessages.getError(Utils.ERROR.EDITOR_NOT_AUTHORIZED).message
        );
        require(
            _suggestions[sID].status == Utils.Status.EDITORCLAIMED,
            ErrorMessages.getError(Utils.ERROR.EDITOR_DECISION_TAKEN).message
        );

        _suggestions[sID].editor.decision = decision;

        if (decision == Utils.EditorDecision.APPROVED) {
            _suggestions[sID].status = Utils.Status.EDITED;
            emit EditorApproved(_msgSender(), sID);
        } else if (decision == Utils.EditorDecision.REJECTED) {
            ovisStake.removeJStake(sID);

            _suggestions[sID].status = Utils.Status.SUBMITTED;
            _suggestions[sID].journalist.due = 0;

            emit EditorRejected(_msgSender(), sID);
        } else {
            emit EditorRequestedChanges(_msgSender(), sID);
        }

        return true;
    }

    function _getAvailableFCSlot(string memory sID)
        internal
        virtual
        returns (uint256 _slot)
    {
        for (uint8 index = 1; index <= 3; index++) {
            if (
                (address(0) == _suggestions[sID].fCs[index - 1].fcAddress) &&
                (_slot == uint8(0))
            ) {
                _slot = index;
            }
        }
    }

    function _resetFCDecisions(string memory sID)
        internal
        virtual
        returns (bool)
    {
        for (uint8 index = 1; index <= 3; index++) {
            _suggestions[sID].fcPoll[index - 1] = Utils
                .FactCheckerDecision
                .NONETAKEN;
        }
        return true;
    }

    function enrollFactChecker(
        string memory sID,
        uint256 amount,
        Signature calldata _signature
    ) public returns (bool) {
        _nonces[_signature.nonce] = true;

        (bool isCompromised, , ) = _isPollCompromised(sID);
        require(
            !isCompromised,
            ErrorMessages.getError(Utils.ERROR.POLL_COMPROMISED).message
        );

        _cycleUser(sID, Utils.Roles.FACTCHECKER);

        require(
            _suggestions[sID].status == Utils.Status.EDITED,
            ErrorMessages.getError(Utils.ERROR.CANT_ENROLL).message
        );

        uint256 _slot = _getAvailableFCSlot(sID);

        require(
            _slot != 0,
            ErrorMessages.getError(Utils.ERROR.FC_QUEUE_FULL).message
        );

        ovisStake.roleStake(_msgSender(), sID, amount, Utils.Roles.FACTCHECKER);
        uint256 _dueDate = block.timestamp + 5 days;

        _suggestions[sID].fCs[_slot - 1] = Utils.FactChecker(
            _msgSender(),
            _dueDate
        );

        emit FactCheckerEnrolled(_msgSender(), sID, _dueDate);

        return true;
    }

    function submitDecisionAsFactChecker(
        string memory sID,
        Utils.FactCheckerDecision decision
    ) public returns (bool) {
        (bool status, uint8 index) = _isEnrolledAlready(sID);
        require(
            status,
            ErrorMessages.getError(Utils.ERROR.FC_NOT_AUTHORIZED).message
        );

        require(
            _suggestions[sID].fcPoll[index - 1] ==
                Utils.FactCheckerDecision.NONETAKEN,
            ErrorMessages.getError(Utils.ERROR.INCREASE_DECIDED).message
        );

        _suggestions[sID].fcPoll[index - 1] = decision;
        if (decision == Utils.FactCheckerDecision.APPROVED) {
            _suggestions[sID].fcPoll[index - 1] = decision;
            emit FCApproved(_msgSender(), sID);
        } else if (decision == Utils.FactCheckerDecision.REJECTED) {
            _suggestions[sID].fcPoll[index - 1] = decision;
            emit FCRejected(_msgSender(), sID);
        }
        (, int8 approved, int8 rejected) = _isPollCompromised(sID);

        if (approved == 2) {
            _suggestions[sID].status = Utils.Status.FACTCHECKED;
            emit FactChecked(sID, Utils.FactCheckerDecision.APPROVED);
        } else if (rejected == 2) {
            _suggestions[sID].status = Utils.Status.SUBMITTED;
            _suggestions[sID].journalist.due = 0;
            _resetFCDecisions(sID);
            emit FactChecked(sID, Utils.FactCheckerDecision.REJECTED);
        }

        return true;
    }

    function publishSuggestion(string memory sID)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _suggestions[sID].status == Utils.Status.FACTCHECKED,
            ErrorMessages.getError(Utils.ERROR.CANT_PUBLISH).message
        );

        //TODO - Implement reward system.
        _suggestions[sID].status = Utils.Status.PUBLISHED;
        emit SuggestionPublished(sID, block.timestamp);
        return true;
    }

    function getSuggestion(string memory sID)
        public
        view
        override
        returns (Utils.Suggestions memory)
    {
        return _suggestions[sID];
    }

    function getCSuggestion(string memory sID)
        public
        view
        override
        returns (Utils.CommunitySuggestion memory)
    {
        return _cSuggestions[sID];
    }
}