// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import 'rainbow-bridge/contracts/eth/nearbridge/contracts/AdminControlled.sol';
import 'rainbow-bridge/contracts/eth/nearbridge/contracts/Borsh.sol';
import 'rainbow-bridge/contracts/eth/nearprover/contracts/ProofDecoder.sol';
import { INearProver, ProofKeeper } from './ProofKeeper.sol';

contract EthCustodian is ProofKeeper, AdminControlled {

    uint constant UNPAUSED_ALL = 0;
    uint constant PAUSED_DEPOSIT_TO_EVM = 1 << 0;
    uint constant PAUSED_DEPOSIT_TO_NEAR = 1 << 1;
    uint constant PAUSED_WITHDRAW = 1 << 2;

    event Deposited (
        address indexed sender,
        string recipient,
        uint256 amount,
        uint256 fee
    );

    event Withdrawn(
        address indexed recipient,
        uint128 amount
    );

    // Function output from burning nETH on Near side.
    struct BurnResult {
        uint128 amount;
        address recipient;
        address ethCustodian;
    }

    /// EthCustodian is linked to the EVM on NEAR side.
    /// It also links to the prover that it uses to withdraw the tokens.
    constructor(
        bytes memory nearEvm,
        INearProver prover,
        uint64 minBlockAcceptanceHeight,
        address _admin,
        uint pausedFlags
    )
        AdminControlled(_admin, pausedFlags)
        ProofKeeper(nearEvm, prover, minBlockAcceptanceHeight)
        public
    {
    }

    /// Deposits the specified amount of provided ETH (except from the relayer's fee) into the smart contract.
    /// `ethRecipientOnNear` - the ETH address of the recipient in NEAR EVM
    /// `fee` - the amount of fee that will be paid to the near-relayer in nETH.
    function depositToEVM(
        string memory ethRecipientOnNear, 
        uint256 fee
    )
        external
        payable
        pausable(PAUSED_DEPOSIT_TO_EVM)
    {
        require(
            fee < msg.value,
            'The fee cannot be bigger than the transferred amount.'
        );

        string memory separator = ':';
        string memory protocolMessage = string(
            abi.encodePacked(
                string(nearProofProducerAccount_),
                separator, ethRecipientOnNear
            )
        );

        emit Deposited(
            msg.sender, 
            protocolMessage, 
            msg.value, 
            fee
        );
    }

    /// Deposits the specified amount of provided ETH (except from the relayer's fee) into the smart contract.
    /// `nearRecipientAccountId` - the AccountID of the recipient in NEAR
    /// `fee` - the amount of fee that will be paid to the near-relayer in nETH.
    function depositToNear(
        string memory nearRecipientAccountId, 
        uint256 fee
    )
        external
        payable
        pausable(PAUSED_DEPOSIT_TO_NEAR)
    {
        require(
            fee < msg.value,
            'The fee cannot be bigger than the transferred amount.'
        );

        emit Deposited(
            msg.sender, 
            nearRecipientAccountId, 
            msg.value, 
            fee
        );
    }

    /// Withdraws the appropriate amount of ETH which is encoded in `proofData`
    function withdraw(
        bytes calldata proofData, 
        uint64 proofBlockHeight
    )
        external
        pausable(PAUSED_WITHDRAW)
    {
        ProofDecoder.ExecutionStatus memory status = _parseAndConsumeProof(proofData, proofBlockHeight);

        BurnResult memory result = _decodeBurnResult(status.successValue);
        require(
            result.ethCustodian == address(this),
            'Can only withdraw coins that were expected for the current contract'
        );
        payable(result.recipient).transfer(result.amount);
        emit Withdrawn(
            result.recipient,
            result.amount
        );
    }

    function _decodeBurnResult(bytes memory data)
        internal
        pure
        returns (BurnResult memory result)
    {
        Borsh.Data memory borshData = Borsh.from(data);
        result.amount = borshData.decodeU128();
        bytes20 recipient = borshData.decodeBytes20();
        result.recipient = address(uint160(recipient));
        bytes20 ethCustodian = borshData.decodeBytes20();
        result.ethCustodian = address(uint160(ethCustodian));
    }
}

pragma solidity ^0.6;

contract AdminControlled {
    address public admin;
    uint public paused;

    constructor(address _admin, uint flags) public {
        admin = _admin;
        paused = flags;
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier pausable(uint flag) {
        require((paused & flag) == 0 || msg.sender == admin);
        _;
    }

    function adminPause(uint flags) public onlyAdmin {
        paused = flags;
    }

    function adminSstore(uint key, uint value) public onlyAdmin {
        assembly {
            sstore(key, value)
        }
    }

    function adminSstoreWithMask(
        uint key,
        uint value,
        uint mask
    ) public onlyAdmin {
        assembly {
            let oldval := sload(key)
            sstore(key, xor(and(xor(value, oldval), mask), oldval))
        }
    }

    function adminSendEth(address payable destination, uint amount) public onlyAdmin {
        destination.transfer(amount);
    }

    function adminReceiveEth() public payable onlyAdmin {}

    function adminDelegatecall(address target, bytes memory data) public payable onlyAdmin returns (bytes memory) {
        (bool success, bytes memory rdata) = target.delegatecall(data);
        require(success);
        return rdata;
    }
}

pragma solidity ^0.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library Borsh {
    using SafeMath for uint256;

    struct Data {
        uint256 offset;
        bytes raw;
    }

    function from(bytes memory data) internal pure returns (Data memory) {
        return Data({offset: 0, raw: data});
    }

    modifier shift(Data memory data, uint256 size) {
        require(data.raw.length >= data.offset + size, "Borsh: Out of range");
        _;
        data.offset += size;
    }

    function finished(Data memory data) internal pure returns (bool) {
        return data.offset == data.raw.length;
    }

    function peekKeccak256(Data memory data, uint256 length) internal pure returns (bytes32 res) {
        return bytesKeccak256(data.raw, data.offset, length);
    }

    function bytesKeccak256(
        bytes memory ptr,
        uint256 offset,
        uint256 length
    ) internal pure returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            res := keccak256(add(add(ptr, 32), offset), length)
        }
    }

    function peekSha256(Data memory data, uint256 length) internal view returns (bytes32) {
        return bytesSha256(data.raw, data.offset, length);
    }

    function bytesSha256(
        bytes memory ptr,
        uint256 offset,
        uint256 length
    ) internal view returns (bytes32) {
        bytes32[1] memory result;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 0x02, add(add(ptr, 32), offset), length, result, 32))
        }
        return result[0];
    }

    function decodeU8(Data memory data) internal pure shift(data, 1) returns (uint8 value) {
        value = uint8(data.raw[data.offset]);
    }

    function decodeI8(Data memory data) internal pure shift(data, 1) returns (int8 value) {
        value = int8(data.raw[data.offset]);
    }

    function decodeU16(Data memory data) internal pure returns (uint16 value) {
        value = uint16(decodeU8(data));
        value |= (uint16(decodeU8(data)) << 8);
    }

    function decodeI16(Data memory data) internal pure returns (int16 value) {
        value = int16(decodeI8(data));
        value |= (int16(decodeI8(data)) << 8);
    }

    function decodeU32(Data memory data) internal pure returns (uint32 value) {
        value = uint32(decodeU16(data));
        value |= (uint32(decodeU16(data)) << 16);
    }

    function decodeI32(Data memory data) internal pure returns (int32 value) {
        value = int32(decodeI16(data));
        value |= (int32(decodeI16(data)) << 16);
    }

    function decodeU64(Data memory data) internal pure returns (uint64 value) {
        value = uint64(decodeU32(data));
        value |= (uint64(decodeU32(data)) << 32);
    }

    function decodeI64(Data memory data) internal pure returns (int64 value) {
        value = int64(decodeI32(data));
        value |= (int64(decodeI32(data)) << 32);
    }

    function decodeU128(Data memory data) internal pure returns (uint128 value) {
        value = uint128(decodeU64(data));
        value |= (uint128(decodeU64(data)) << 64);
    }

    function decodeI128(Data memory data) internal pure returns (int128 value) {
        value = int128(decodeI64(data));
        value |= (int128(decodeI64(data)) << 64);
    }

    function decodeU256(Data memory data) internal pure returns (uint256 value) {
        value = uint256(decodeU128(data));
        value |= (uint256(decodeU128(data)) << 128);
    }

    function decodeI256(Data memory data) internal pure returns (int256 value) {
        value = int256(decodeI128(data));
        value |= (int256(decodeI128(data)) << 128);
    }

    function decodeBool(Data memory data) internal pure returns (bool value) {
        value = (decodeU8(data) != 0);
    }

    function decodeBytes(Data memory data) internal pure returns (bytes memory value) {
        value = new bytes(decodeU32(data));
        for (uint i = 0; i < value.length; i++) {
            value[i] = byte(decodeU8(data));
        }
    }

    function decodeBytes32(Data memory data) internal pure shift(data, 32) returns (bytes32 value) {
        bytes memory raw = data.raw;
        uint256 offset = data.offset;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            value := mload(add(add(raw, 32), offset))
        }
    }

    function decodeBytes20(Data memory data) internal pure returns (bytes20 value) {
        for (uint i = 0; i < 20; i++) {
            value |= bytes20(byte(decodeU8(data)) & 0xFF) >> (i * 8);
        }
    }

    // Public key

    struct SECP256K1PublicKey {
        uint256 x;
        uint256 y;
    }

    function decodeSECP256K1PublicKey(Borsh.Data memory data) internal pure returns (SECP256K1PublicKey memory key) {
        key.x = decodeU256(data);
        key.y = decodeU256(data);
    }

    struct ED25519PublicKey {
        bytes32 xy;
    }

    function decodeED25519PublicKey(Borsh.Data memory data) internal pure returns (ED25519PublicKey memory key) {
        key.xy = decodeBytes32(data);
    }

    // Signature

    struct SECP256K1Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function decodeSECP256K1Signature(Borsh.Data memory data) internal pure returns (SECP256K1Signature memory sig) {
        sig.r = decodeBytes32(data);
        sig.s = decodeBytes32(data);
        sig.v = decodeU8(data);
    }

    struct ED25519Signature {
        bytes32[2] rs;
    }

    function decodeED25519Signature(Borsh.Data memory data) internal pure returns (ED25519Signature memory sig) {
        sig.rs[0] = decodeBytes32(data);
        sig.rs[1] = decodeBytes32(data);
    }
}

pragma solidity ^0.6;

import "../../nearbridge/contracts/Borsh.sol";
import "../../nearbridge/contracts/NearDecoder.sol";

library ProofDecoder {
    using Borsh for Borsh.Data;
    using ProofDecoder for Borsh.Data;
    using NearDecoder for Borsh.Data;

    struct FullOutcomeProof {
        ExecutionOutcomeWithIdAndProof outcome_proof;
        MerklePath outcome_root_proof; // TODO: now empty array
        BlockHeaderLight block_header_lite;
        MerklePath block_proof;
    }

    function decodeFullOutcomeProof(Borsh.Data memory data) internal view returns (FullOutcomeProof memory proof) {
        proof.outcome_proof = data.decodeExecutionOutcomeWithIdAndProof();
        proof.outcome_root_proof = data.decodeMerklePath();
        proof.block_header_lite = data.decodeBlockHeaderLight();
        proof.block_proof = data.decodeMerklePath();
    }

    struct BlockHeaderLight {
        bytes32 prev_block_hash;
        bytes32 inner_rest_hash;
        NearDecoder.BlockHeaderInnerLite inner_lite;
        bytes32 hash; // Computable
    }

    function decodeBlockHeaderLight(Borsh.Data memory data) internal view returns (BlockHeaderLight memory header) {
        header.prev_block_hash = data.decodeBytes32();
        header.inner_rest_hash = data.decodeBytes32();
        header.inner_lite = data.decodeBlockHeaderInnerLite();

        header.hash = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(header.inner_lite.hash, header.inner_rest_hash)),
                header.prev_block_hash
            )
        );
    }

    struct ExecutionStatus {
        uint8 enumIndex;
        bool unknown;
        bool failed;
        bytes successValue; /// The final action succeeded and returned some value or an empty vec.
        bytes32 successReceiptId; /// The final action of the receipt returned a promise or the signed
        /// transaction was converted to a receipt. Contains the receipt_id of the generated receipt.
    }

    function decodeExecutionStatus(Borsh.Data memory data)
        internal
        pure
        returns (ExecutionStatus memory executionStatus)
    {
        executionStatus.enumIndex = data.decodeU8();
        if (executionStatus.enumIndex == 0) {
            executionStatus.unknown = true;
        } else if (executionStatus.enumIndex == 1) {
            //revert("NearDecoder: decodeExecutionStatus failure case not implemented yet");
            // Can avoid revert since ExecutionStatus is latest field in all parent structures
            executionStatus.failed = true;
        } else if (executionStatus.enumIndex == 2) {
            executionStatus.successValue = data.decodeBytes();
        } else if (executionStatus.enumIndex == 3) {
            executionStatus.successReceiptId = data.decodeBytes32();
        } else {
            revert("NearDecoder: decodeExecutionStatus index out of range");
        }
    }

    struct ExecutionOutcome {
        bytes[] logs; /// Logs from this transaction or receipt.
        bytes32[] receipt_ids; /// Receipt IDs generated by this transaction or receipt.
        uint64 gas_burnt; /// The amount of the gas burnt by the given transaction or receipt.
        uint128 tokens_burnt; /// The total number of the tokens burnt by the given transaction or receipt.
        bytes executor_id; /// Hash of the transaction or receipt id that produced this outcome.
        ExecutionStatus status; /// Execution status. Contains the result in case of successful execution.
        bytes32[] merkelization_hashes;
    }

    function decodeExecutionOutcome(Borsh.Data memory data) internal view returns (ExecutionOutcome memory outcome) {
        outcome.logs = new bytes[](data.decodeU32());
        for (uint i = 0; i < outcome.logs.length; i++) {
            outcome.logs[i] = data.decodeBytes();
        }

        uint256 start = data.offset;
        outcome.receipt_ids = new bytes32[](data.decodeU32());
        for (uint i = 0; i < outcome.receipt_ids.length; i++) {
            outcome.receipt_ids[i] = data.decodeBytes32();
        }
        outcome.gas_burnt = data.decodeU64();
        outcome.tokens_burnt = data.decodeU128();
        outcome.executor_id = data.decodeBytes();
        outcome.status = data.decodeExecutionStatus();
        uint256 stop = data.offset;

        outcome.merkelization_hashes = new bytes32[](1 + outcome.logs.length);
        data.offset = start;
        outcome.merkelization_hashes[0] = data.peekSha256(stop - start);
        data.offset = stop;
        for (uint i = 0; i < outcome.logs.length; i++) {
            outcome.merkelization_hashes[i + 1] = sha256(outcome.logs[i]);
        }
    }

    struct ExecutionOutcomeWithId {
        bytes32 id; /// The transaction hash or the receipt ID.
        ExecutionOutcome outcome;
        bytes32 hash;
    }

    function decodeExecutionOutcomeWithId(Borsh.Data memory data)
        internal
        view
        returns (ExecutionOutcomeWithId memory outcome)
    {
        outcome.id = data.decodeBytes32();
        outcome.outcome = data.decodeExecutionOutcome();

        uint256 len = 1 + outcome.outcome.merkelization_hashes.length;
        outcome.hash = sha256(
            abi.encodePacked(
                uint8((len >> 0) & 0xFF),
                uint8((len >> 8) & 0xFF),
                uint8((len >> 16) & 0xFF),
                uint8((len >> 24) & 0xFF),
                outcome.id,
                outcome.outcome.merkelization_hashes
            )
        );
    }

    struct MerklePathItem {
        bytes32 hash;
        uint8 direction; // 0 = left, 1 = right
    }

    function decodeMerklePathItem(Borsh.Data memory data) internal pure returns (MerklePathItem memory item) {
        item.hash = data.decodeBytes32();
        item.direction = data.decodeU8();
        require(item.direction < 2, "ProofDecoder: MerklePathItem direction should be 0 or 1");
    }

    struct MerklePath {
        MerklePathItem[] items;
    }

    function decodeMerklePath(Borsh.Data memory data) internal pure returns (MerklePath memory path) {
        path.items = new MerklePathItem[](data.decodeU32());
        for (uint i = 0; i < path.items.length; i++) {
            path.items[i] = data.decodeMerklePathItem();
        }
    }

    struct ExecutionOutcomeWithIdAndProof {
        MerklePath proof;
        bytes32 block_hash;
        ExecutionOutcomeWithId outcome_with_id;
    }

    function decodeExecutionOutcomeWithIdAndProof(Borsh.Data memory data)
        internal
        view
        returns (ExecutionOutcomeWithIdAndProof memory outcome)
    {
        outcome.proof = data.decodeMerklePath();
        outcome.block_hash = data.decodeBytes32();
        outcome.outcome_with_id = data.decodeExecutionOutcomeWithId();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import 'rainbow-bridge/contracts/eth/nearprover/contracts/INearProver.sol';
import 'rainbow-bridge/contracts/eth/nearprover/contracts/ProofDecoder.sol';
import 'rainbow-bridge/contracts/eth/nearbridge/contracts/Borsh.sol';

contract ProofKeeper {
    using Borsh for Borsh.Data;
    using ProofDecoder for Borsh.Data;

    INearProver public prover_;
    bytes public nearProofProducerAccount_;

    /// Proofs from blocks that are below the acceptance height will be rejected.
    // If `minBlockAcceptanceHeight_` value is zero - proofs from block with any height are accepted.
    uint64 public minBlockAcceptanceHeight_;

    // OutcomeReciptId -> Used
    mapping(bytes32 => bool) public usedEvents_;

    constructor(
        bytes memory nearProofProducerAccount,
        INearProver prover,
        uint64 minBlockAcceptanceHeight
    ) 
        public 
    {
        require(
            nearProofProducerAccount.length > 0,
            'Invalid Near ProofProducer address'
        );
        require(
            address(prover) != address(0),
            'Invalid Near prover address'
        );

        nearProofProducerAccount_ = nearProofProducerAccount;
        prover_ = prover;
        minBlockAcceptanceHeight_ = minBlockAcceptanceHeight;
    }

    /// Parses the provided proof and consumes it if it's not already used.
    /// The consumed event cannot be reused for future calls.
    function _parseAndConsumeProof(
        bytes memory proofData, 
        uint64 proofBlockHeight
    )
        internal
        returns(ProofDecoder.ExecutionStatus memory result)
    {
        require(
            proofBlockHeight >= minBlockAcceptanceHeight_,
            'Proof is from the ancient block'
        );
        require(
            prover_.proveOutcome(proofData,proofBlockHeight),
            'Proof should be valid'
        );

        // Unpack the proof and extract the execution outcome.
        Borsh.Data memory borshData = Borsh.from(proofData);

        ProofDecoder.FullOutcomeProof memory fullOutcomeProof = 
        borshData.decodeFullOutcomeProof();
        
        require(
            borshData.finished(),
            'Argument should be exact borsh serialization'
        );

        bytes32 receiptId = 
        fullOutcomeProof.outcome_proof.outcome_with_id.outcome.receipt_ids[0];

        require(
            !usedEvents_[receiptId],
            'The burn event cannot be reused'
        );
        usedEvents_[receiptId] = true;

        require(
            keccak256(fullOutcomeProof.outcome_proof.outcome_with_id.outcome.executor_id) == 
            keccak256(nearProofProducerAccount_),
            'Can only withdraw coins from the linked proof producer on Near blockchain'
        );

        result = fullOutcomeProof.outcome_proof.outcome_with_id.outcome.status;
        require(
            !result.failed, 
            'Cannot use failed execution outcome for unlocking the tokens'
        );
        require(
            !result.unknown,
            'Cannot use unknown execution outcome for unlocking the tokens'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Borsh.sol";

library NearDecoder {
    using Borsh for Borsh.Data;
    using NearDecoder for Borsh.Data;

    struct PublicKey {
        uint8 enumIndex;
        Borsh.ED25519PublicKey ed25519;
        Borsh.SECP256K1PublicKey secp256k1;
    }

    function decodePublicKey(Borsh.Data memory data) internal pure returns (PublicKey memory key) {
        key.enumIndex = data.decodeU8();

        if (key.enumIndex == 0) {
            key.ed25519 = data.decodeED25519PublicKey();
        } else if (key.enumIndex == 1) {
            key.secp256k1 = data.decodeSECP256K1PublicKey();
        } else {
            revert("NearBridge: Only ED25519 and SECP256K1 public keys are supported");
        }
    }

    struct ValidatorStake {
        string account_id;
        PublicKey public_key;
        uint128 stake;
    }

    function decodeValidatorStake(Borsh.Data memory data) internal pure returns (ValidatorStake memory validatorStake) {
        validatorStake.account_id = string(data.decodeBytes());
        validatorStake.public_key = data.decodePublicKey();
        validatorStake.stake = data.decodeU128();
    }

    struct OptionalValidatorStakes {
        bool none;
        ValidatorStake[] validatorStakes;
        bytes32 hash; // Additional computable element
    }

    function decodeOptionalValidatorStakes(Borsh.Data memory data)
        internal
        view
        returns (OptionalValidatorStakes memory stakes)
    {
        stakes.none = (data.decodeU8() == 0);
        if (!stakes.none) {
            uint256 start = data.offset;

            stakes.validatorStakes = new ValidatorStake[](data.decodeU32());
            for (uint i = 0; i < stakes.validatorStakes.length; i++) {
                stakes.validatorStakes[i] = data.decodeValidatorStake();
            }

            uint256 stop = data.offset;
            data.offset = start;
            stakes.hash = data.peekSha256(stop - start);
            data.offset = stop;
        }
    }

    struct Signature {
        uint8 enumIndex;
        Borsh.ED25519Signature ed25519;
        Borsh.SECP256K1Signature secp256k1;
    }

    function decodeSignature(Borsh.Data memory data) internal pure returns (Signature memory sig) {
        sig.enumIndex = data.decodeU8();

        if (sig.enumIndex == 0) {
            sig.ed25519 = data.decodeED25519Signature();
        } else if (sig.enumIndex == 1) {
            sig.secp256k1 = data.decodeSECP256K1Signature();
        } else {
            revert("NearBridge: Only ED25519 and SECP256K1 signatures are supported");
        }
    }

    struct OptionalSignature {
        bool none;
        Signature signature;
    }

    function decodeOptionalSignature(Borsh.Data memory data) internal pure returns (OptionalSignature memory sig) {
        sig.none = (data.decodeU8() == 0);
        if (!sig.none) {
            sig.signature = data.decodeSignature();
        }
    }

    struct LightClientBlock {
        bytes32 prev_block_hash;
        bytes32 next_block_inner_hash;
        BlockHeaderInnerLite inner_lite;
        bytes32 inner_rest_hash;
        OptionalValidatorStakes next_bps;
        OptionalSignature[] approvals_after_next;
        bytes32 hash;
        bytes32 next_hash;
    }

    struct InitialValidators {
        ValidatorStake[] validator_stakes;
    }

    function decodeInitialValidators(Borsh.Data memory data)
        internal
        view
        returns (InitialValidators memory validators)
    {
        validators.validator_stakes = new ValidatorStake[](data.decodeU32());
        for (uint i = 0; i < validators.validator_stakes.length; i++) {
            validators.validator_stakes[i] = data.decodeValidatorStake();
        }
    }

    function decodeLightClientBlock(Borsh.Data memory data) internal view returns (LightClientBlock memory header) {
        header.prev_block_hash = data.decodeBytes32();
        header.next_block_inner_hash = data.decodeBytes32();
        header.inner_lite = data.decodeBlockHeaderInnerLite();
        header.inner_rest_hash = data.decodeBytes32();
        header.next_bps = data.decodeOptionalValidatorStakes();

        header.approvals_after_next = new OptionalSignature[](data.decodeU32());
        for (uint i = 0; i < header.approvals_after_next.length; i++) {
            header.approvals_after_next[i] = data.decodeOptionalSignature();
        }

        header.hash = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(header.inner_lite.hash, header.inner_rest_hash)),
                header.prev_block_hash
            )
        );

        header.next_hash = sha256(abi.encodePacked(header.next_block_inner_hash, header.hash));
    }

    struct BlockHeaderInnerLite {
        uint64 height; /// Height of this block since the genesis block (height 0).
        bytes32 epoch_id; /// Epoch start hash of this block's epoch. Used for retrieving validator information
        bytes32 next_epoch_id;
        bytes32 prev_state_root; /// Root hash of the state at the previous block.
        bytes32 outcome_root; /// Root of the outcomes of transactions and receipts.
        uint64 timestamp; /// Timestamp at which the block was built.
        bytes32 next_bp_hash; /// Hash of the next epoch block producers set
        bytes32 block_merkle_root;
        bytes32 hash; // Additional computable element
    }

    function decodeBlockHeaderInnerLite(Borsh.Data memory data)
        internal
        view
        returns (BlockHeaderInnerLite memory header)
    {
        header.hash = data.peekSha256(208);
        header.height = data.decodeU64();
        header.epoch_id = data.decodeBytes32();
        header.next_epoch_id = data.decodeBytes32();
        header.prev_state_root = data.decodeBytes32();
        header.outcome_root = data.decodeBytes32();
        header.timestamp = data.decodeU64();
        header.next_bp_hash = data.decodeBytes32();
        header.block_merkle_root = data.decodeBytes32();
    }
}

pragma solidity ^0.6;

interface INearProver {
    function proveOutcome(bytes calldata proofData, uint64 blockHeight) external view returns (bool);
}

