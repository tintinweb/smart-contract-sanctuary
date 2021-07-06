/**
 *Submitted for verification at Etherscan.io on 2021-07-06
*/

// Dependency file: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Root file: contracts/MockContract.sol

pragma solidity ^0.8.5;

// import '/Users/szymon.szlachtowicz/Documents/ethworks/status-community-dapp/node_modules/@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
// import '/Users/szymon.szlachtowicz/Documents/ethworks/status-community-dapp/node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';

contract MockContract {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    uint256 constant VOTING_LENGTH = 1000;

    enum VoteType {
        REMOVE,
        ADD
    }

    struct VotingRoom {
        uint256 startBlock;
        uint256 endAt;
        VoteType voteType;
        bool finalized;
        address community;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 roomNumber;
        mapping(address => bool) voted;
        address[] voters;
    }

    event VotingRoomStarted(uint256 roomId);
    event VotingRoomFinalized(uint256 roomId);

    uint256 private latestVoting = 1;
    mapping(uint256 => VotingRoom) public votingRoomMap;
    mapping(address => uint256) public communityVotingId;

    uint256[] public activeVotingRooms;
    mapping(uint256 => uint256) private indexOfActiveVotingRooms;

    function getCommunityVoting(address publicKey)
        public
        view
        returns (
            uint256 startBlock,
            uint256 endAt,
            VoteType voteType,
            bool finalized,
            address community,
            uint256 totalVotesFor,
            uint256 totalVotesAgainst,
            uint256 roomNumber
        )
    {
        require(communityVotingId[publicKey] > 0, 'vote not found');
        require(votingRoomMap[communityVotingId[publicKey]].endAt > block.timestamp, 'vote ended');
        startBlock = votingRoomMap[communityVotingId[publicKey]].startBlock;
        endAt = votingRoomMap[communityVotingId[publicKey]].endAt;
        voteType = votingRoomMap[communityVotingId[publicKey]].voteType;
        finalized = votingRoomMap[communityVotingId[publicKey]].finalized;
        community = votingRoomMap[communityVotingId[publicKey]].community;
        totalVotesFor = votingRoomMap[communityVotingId[publicKey]].totalVotesFor;
        totalVotesAgainst = votingRoomMap[communityVotingId[publicKey]].totalVotesAgainst;
        roomNumber = votingRoomMap[communityVotingId[publicKey]].roomNumber;
    }

    function getActiveVotingRooms() public view returns (uint256[] memory) {
        return activeVotingRooms;
    }

    function listRoomVoters(uint256 roomId) public view returns (address[] memory) {
        return votingRoomMap[roomId].voters;
    }

    function initializeVotingRoom(VoteType voteType, address publicKey) public {
        require(communityVotingId[publicKey] == 0, 'vote already ongoing');

        VotingRoom storage newVotingRoom = votingRoomMap[latestVoting];
        newVotingRoom.startBlock = block.number;
        newVotingRoom.endAt = block.timestamp.add(VOTING_LENGTH);
        newVotingRoom.voteType = voteType;
        newVotingRoom.community = publicKey;
        newVotingRoom.roomNumber = latestVoting;
        communityVotingId[publicKey] = latestVoting;

        activeVotingRooms.push(latestVoting);
        indexOfActiveVotingRooms[latestVoting] = activeVotingRooms.length;

        emit VotingRoomStarted(latestVoting++);
    }

    function finalizeVotingRoom(uint256 roomId) public {
        require(roomId > 0, 'vote not found');
        require(roomId < latestVoting, 'vote not found');
        require(votingRoomMap[roomId].finalized == false, 'vote already finalized');
        require(votingRoomMap[roomId].endAt < block.timestamp, 'vote still ongoing');
        votingRoomMap[roomId].finalized = true;
        communityVotingId[votingRoomMap[roomId].community] = 0;

        uint256 index = indexOfActiveVotingRooms[roomId];
        if (index == 0) return;
        index--;
        if (activeVotingRooms.length > 1) {
            activeVotingRooms[index] = activeVotingRooms[activeVotingRooms.length - 1];
            indexOfActiveVotingRooms[activeVotingRooms[index]] = index + 1;
        }
        activeVotingRooms.pop();

        emit VotingRoomFinalized(roomId);
    }

    struct SignedVote {
        address voter;
        uint256 roomIdAndType;
        uint256 sntAmount;
        bytes32 r;
        bytes32 vs;
    }
    event VoteCast(uint256 roomId, address voter);

    function castVotes(SignedVote[] calldata votes) public {
        for (uint256 i = 0; i < votes.length; i++) {
            SignedVote calldata vote = votes[i];
            bytes32 hashed = keccak256(
                abi.encodePacked('\x19Ethereum Signed Message:\n84', vote.voter, vote.roomIdAndType, vote.sntAmount)
            );
            if (hashed.recover(abi.encode(vote.r, vote.vs)) == vote.voter) {
                uint256 roomId = vote.roomIdAndType >> 1;
                require(roomId > 0, 'vote not found');
                require(roomId < latestVoting, 'vote not found');
                VotingRoom storage room = votingRoomMap[roomId];
                require(room.endAt > block.timestamp, 'vote closed');
                if (room.voted[vote.voter] == false) {
                    if (vote.roomIdAndType & 1 == 1) {
                        room.totalVotesFor = room.totalVotesFor.add(vote.sntAmount);
                    } else {
                        room.totalVotesAgainst = room.totalVotesAgainst.add(vote.sntAmount);
                    }
                    room.voters.push(vote.voter);
                    room.voted[vote.voter] = true;
                    emit VoteCast(roomId, vote.voter);
                }
            }
        }
    }
}