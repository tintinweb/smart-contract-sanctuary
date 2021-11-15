// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IHashes } from "./IHashes.sol";
import { LibDeactivateToken } from "./LibDeactivateToken.sol";
import { LibEIP712 } from "./LibEIP712.sol";
import { LibSignature } from "./LibSignature.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Hashes
 * @author DEX Labs
 * @notice This contract handles the Hashes ERC-721 token.
 */
contract Hashes is IHashes, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /// @notice version for this Hashes contract
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    /// @notice activationFee The fee to activate (and the payment to deactivate)
    ///         a governance class hash that wasn't reserved. This is the initial
    ///         minting fee.
    uint256 public immutable override activationFee;

    /// @notice locked The lock status of the contract. Once locked, the contract
    ///         will never be unlocked. Locking prevents the transfer of ownership.
    bool public locked;

    /// @notice mintFee Minting fee.
    uint256 public mintFee;

    /// @notice reservedAmount Number of Hashes reserved.
    uint256 public reservedAmount;

    /// @notice governanceCap Number of Hashes qualifying for governance.
    uint256 public governanceCap;

    /// @notice nonce Monotonically-increasing number (token ID).
    uint256 public nonce;

    /// @notice baseTokenURI The base of the token URI.
    string public baseTokenURI;

    bytes internal constant TABLE = "0123456789abcdef";

    /// @notice A checkpoint for marking vote count from given block.
    struct Checkpoint {
        uint32 id;
        uint256 votes;
    }

    /// @notice deactivated A record of tokens that have been deactivated by token ID.
    mapping(uint256 => bool) public deactivated;

    /// @notice lastProposalIds A record of the last recorded proposal IDs by an address.
    mapping(address => uint256) public lastProposalIds;

    /// @notice checkpoints A record of votes checkpoints for each account, by index.
    mapping(address => mapping(uint256 => Checkpoint)) public checkpoints;

    /// @notice numCheckpoints The number of checkpoints for each account.
    mapping(address => uint256) public numCheckpoints;

    mapping(uint256 => bytes32) nonceToHash;

    mapping(uint256 => bool) redeemed;

    /// @notice Emitted when governance class tokens are activated.
    event Activated(address indexed owner, uint256 indexed tokenId);

    /// @notice Emitted when governance class tokens are deactivated.
    event Deactivated(address indexed owner, uint256 indexed tokenId, uint256 proposalId);

    /// @notice Emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice Emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /// @notice Emitted when a Hash was generated/minted
    event Generated(address artist, uint256 tokenId, string phrase);

    /// @notice Emitted when a reserved Hash was redemed
    event Redeemed(address artist, uint256 tokenId, string phrase);

    // @notice Emitted when the base token URI is updated
    event BaseTokenURISet(string baseTokenURI);

    // @notice Emitted when the mint fee is updated
    event MintFeeSet(uint256 indexed fee);

    /**
     * @notice Constructor for the Hashes token. Initializes the state.
     * @param _mintFee Minting fee
     * @param _reservedAmount Reserved number of Hashes
     * @param _governanceCap Number of hashes qualifying for governance
     * @param _baseTokenURI The initial base token URI.
     */
    constructor(uint256 _mintFee, uint256 _reservedAmount, uint256 _governanceCap, string memory _baseTokenURI) ERC721("Hashes", "HASH") Ownable() {
        reservedAmount = _reservedAmount;
        activationFee = _mintFee;
        mintFee = _mintFee;
        governanceCap = _governanceCap;
        for (uint i = 0; i < reservedAmount; i++) {
            // Compute and save the hash (temporary till redemption)
            nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender()));
            // Mint the token
            _safeMint(_msgSender(), nonce++);
        }
        baseTokenURI = _baseTokenURI;
    }

    /**
     * @notice Allows the owner to lock ownership. This prevents ownership from
     *         ever being transferred in the future.
     */
    function lock() external onlyOwner {
        require(!locked, "Hashes: can't lock twice.");
        locked = true;
    }

    /**
     * @dev An overridden version of `transferOwnership` that checks to see if
     *      ownership is locked.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        require(!locked, "Hashes: can't transfer ownership when locked.");
        super.transferOwnership(_newOwner);
    }

    /**
     * @notice Allows governance to update the base token URI.
     * @param _baseTokenURI The new base token URI.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @notice Allows governance to update the fee to mint a hash.
     * @param _mintFee The fee to mint a hash.
     */
    function setMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
        emit MintFeeSet(_mintFee);
    }

    /**
     * @notice Allows a token ID owner to activate their governance class token.
     * @return activationCount The amount of tokens that were activated.
     */
    function activateTokens() external payable nonReentrant returns (uint256 activationCount) {
        // Activate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(msg.sender); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && deactivated[tokenId]) {
                deactivated[tokenId] = false;
                activationCount++;

                // Emit an activation event.
                emit Activated(msg.sender, tokenId);
            }
        }

        // Increase the sender's governance power.
        _moveDelegates(address(0), msg.sender, activationCount);

        // Ensure that sufficient ether was provided to pay the activation fee.
        // If a sufficient amount was provided, send it to the owner. Refund the
        // sender with the remaining amount of ether.
        bool sent;
        uint256 requiredFee = activationFee.mul(activationCount);
        require(msg.value >= requiredFee, "Hashes: must pay adequate fee to activate hash.");
        (sent,) = owner().call{value: requiredFee}("");
        require(sent, "Hashes: couldn't pay owner the activation fee.");
        if (msg.value > requiredFee) {
            (sent,) = msg.sender.call{value: msg.value - requiredFee}("");
            require(sent, "Hashes: couldn't refund sender with the remaining ether.");
        }

        return activationCount;
    }

    /**
     * @notice Allows the owner to process a series of deactivations from governance
     *         class tokens owned by a single holder. The owner is responsible for
     *         handling payment once deactivations have been finalized.
     * @param _tokenOwner The owner of the hashes to deactivate.
     * @param _proposalId The proposal ID that this deactivation is related to.
     * @param _signature The signature to prove the owner wants to deactivate
     *        their holdings.
     * @return deactivationCount The amount of tokens that were deactivated.
     */
    function deactivateTokens(address _tokenOwner, uint256 _proposalId, bytes memory _signature) external override nonReentrant onlyOwner returns (uint256 deactivationCount) {
        // Ensure that the token owner has approved the deactivation.
        require(lastProposalIds[_tokenOwner] < _proposalId, "Hashes: can't re-use an old proposal ID.");
        lastProposalIds[_tokenOwner] = _proposalId;
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name(), version, getChainId(), address(this));
        bytes32 deactivateHash =
            LibDeactivateToken.getDeactivateTokenHash(
                LibDeactivateToken.DeactivateToken({ proposalId: _proposalId }),
                eip712DomainHash
            );
        require(LibSignature.getSignerOfHash(deactivateHash, _signature) == _tokenOwner, "Hashes: The token owner must approve the deactivation.");

        // Deactivate as many tokens as possible.
        for (uint256 i = 0; i < balanceOf(_tokenOwner); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_tokenOwner, i);
            if (tokenId >= reservedAmount && tokenId < governanceCap && !deactivated[tokenId]) {
                deactivated[tokenId] = true;
                deactivationCount++;

                // Emit a deactivation event.
                emit Deactivated(_tokenOwner, tokenId, _proposalId);
            }
        }

        // Decrease the voter's governance power.
        _moveDelegates(_tokenOwner, address(0), deactivationCount);

        return deactivationCount;
    }

    /**
     * @notice Generate a new Hashes token provided a phrase. This
     *         function generates/saves a hash, mints the token, and
     *         transfers the minting fee to the HashesDAO when
     *         applicable.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function generate(string memory _phrase) external nonReentrant payable {
        // Ensure that the hash can be generated.
        require(bytes(_phrase).length > 0, "Hashes: Can't generate hash with the empty string.");

        // Ensure token minter is passing in a sufficient minting fee.
        require(msg.value >= mintFee, "Hashes: Must pass sufficient mint fee.");

        // Compute and save the hash
        nonceToHash[nonce] = keccak256(abi.encodePacked(nonce, _msgSender(), _phrase));

        // Mint the token
        _safeMint(_msgSender(), nonce++);

        uint256 mintFeePaid;
        if (mintFee > 0) {
            // If the minting fee is non-zero

            // Send the fee to HashesDAO.
            (bool sent,) = owner().call{value: mintFee}("");
            require(sent, "Hashes: failed to send ETH to HashesDAO");

            // Set the mintFeePaid to the current minting fee
            mintFeePaid = mintFee;
        }

        if (msg.value > mintFeePaid) {
            // If minter passed ETH value greater than the minting
            // fee paid/computed above

            // Refund the remaining ether balance to the sender. Since there are no
            // other payable functions, this remainder will always be the senders.
            (bool sent,) = _msgSender().call{value: msg.value - mintFeePaid}("");
            require(sent, "Hashes: failed to refund ETH.");
        }

        if (nonce == governanceCap) {
            // Set mint fee to 0 now that governance cap has been hit.
            // The minting fee can only be increased from here via
            // governance.
            mintFee = 0;
        }

        emit Generated(_msgSender(), nonce - 1, _phrase);
    }

    /**
     * @notice Redeem a reserved Hashes token. Any may redeem a
     *         reserved Hashes token so long as they hold the token
     *         and this particular token hasn't been redeemed yet.
     *         Redemption lets an owner of a reserved token to
     *         modify the phrase as they choose.
     * @param _tokenId Token ID.
     * @param _phrase Phrase used as part of hashing inputs.
     */
    function redeem(uint256 _tokenId, string memory _phrase) external nonReentrant {
        // Ensure redeemer is the token owner.
        require(_msgSender() == ownerOf(_tokenId), "Hashes: must be owner.");

        // Ensure that redeemed token is a reserved token.
        require(_tokenId < reservedAmount, "Hashes: must be a reserved token.");

        // Ensure the token hasn't been redeemed before.
        require(!redeemed[_tokenId], "Hashes: already redeemed.");

        // Mark the token as redeemed.
        redeemed[_tokenId] = true;

        // Update the hash.
        nonceToHash[_tokenId] = keccak256(abi.encodePacked(_tokenId, _msgSender(), _phrase));

        emit Redeemed(_msgSender(), _tokenId, _phrase);
    }

    /**
     * @notice Verify the validity of a Hash token given its inputs.
     * @param _tokenId Token ID for Hash token.
     * @param _minter Minter's (or redeemer's) Ethereum address.
     * @param _phrase Phrase used at time of generation/redemption.
     * @return Whether the Hash token's hash saved given this token ID
     *         matches the inputs provided.
     */
    function verify(uint256 _tokenId, address _minter, string memory _phrase) external override view returns (bool) {
        // Enforce the normal hashes regularity conditions before verifying.
        if (_tokenId >= nonce || _minter == address(0) || bytes(_phrase).length == 0) {
            return false;
        }

        // Verify the provided phrase.
        return nonceToHash[_tokenId] == keccak256(abi.encodePacked(_tokenId, _minter, _phrase));
    }

    /**
     * @notice Retrieve token URI given a token ID.
     * @param _tokenId Token ID.
     * @return Token URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        // Ensure that the token ID is valid and that the hash isn't empty.
        require(_tokenId < nonce, "Hashes: Can't provide a token URI for a non-existent hash.");

        // Return the base token URI concatenated with the token ID.
        return string(abi.encodePacked(baseTokenURI, _toDecimalString(_tokenId)));
    }

    /**
     * @notice Retrieve hash given a token ID.
     * @param _tokenId Token ID.
     * @return Hash associated with this token ID.
     */
    function getHash(uint256 _tokenId) external override view returns (bytes32) {
        return nonceToHash[_tokenId];
    }

    /**
     * @notice Gets the current votes balance.
     * @param _account The address to get votes balance.
     * @return The number of current votes.
     */
    function getCurrentVotes(address _account) external view returns (uint256) {
        uint256 numCheckpointsAccount = numCheckpoints[_account];
        return numCheckpointsAccount > 0 ? checkpoints[_account][numCheckpointsAccount - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param _account The address of the account to check
     * @param _blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address _account, uint256 _blockNumber) external override view returns (uint256) {
        require(_blockNumber < block.number, "Hashes: block not yet determined.");

        uint256 numCheckpointsAccount = numCheckpoints[_account];
        if (numCheckpointsAccount == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[_account][numCheckpointsAccount - 1].id <= _blockNumber) {
            return checkpoints[_account][numCheckpointsAccount - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[_account][0].id > _blockNumber) {
            return 0;
        }

        // Perform binary search to find the most recent token holdings
        // leading to a measure of voting power
        uint256 lower = 0;
        uint256 upper = numCheckpointsAccount - 1;
        while (upper > lower) {
            // ceil, avoiding overflow
            uint256 center = upper - (upper - lower) / 2;
            Checkpoint memory cp = checkpoints[_account][center];
            if (cp.id == _blockNumber) {
                return cp.votes;
            } else if (cp.id < _blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[_account][lower].votes;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (tokenId < governanceCap && !deactivated[tokenId]) {
            // If Hashes token is in the governance class, transfer voting rights
            // from `from` address to `to` address.
            _moveDelegates(from, to, 1);
        }
    }

    function _moveDelegates(
        address _initDel,
        address _finDel,
        uint256 _amount
    ) internal {
        if (_initDel != _finDel && _amount > 0) {
            // Initial delegated address is different than final
            // delegated address and nonzero number of votes moved
            if (_initDel != address(0)) {
                // If we are not minting a new token

                uint256 initDelNum = numCheckpoints[_initDel];

                // Retrieve and compute the old and new initial delegate
                // address' votes
                uint256 initDelOld = initDelNum > 0 ? checkpoints[_initDel][initDelNum - 1].votes : 0;
                uint256 initDelNew = initDelOld.sub(_amount);
                _writeCheckpoint(_initDel, initDelOld, initDelNew);
            }

            if (_finDel != address(0)) {
                // If we are not burning a token
                uint256 finDelNum = numCheckpoints[_finDel];

                // Retrieve and compute the old and new final delegate
                // address' votes
                uint256 finDelOld = finDelNum > 0 ? checkpoints[_finDel][finDelNum - 1].votes : 0;
                uint256 finDelNew = finDelOld.add(_amount);
                _writeCheckpoint(_finDel, finDelOld, finDelNew);
            }
        }
    }

    function _writeCheckpoint(
        address _delegatee,
        uint256 _oldVotes,
        uint256 _newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "Hashes: exceeds 32 bits.");
        uint256 delNum = numCheckpoints[_delegatee];
        if (delNum > 0 && checkpoints[_delegatee][delNum - 1].id == blockNumber) {
            // If latest checkpoint is current block, edit in place
            checkpoints[_delegatee][delNum - 1].votes = _newVotes;
        } else {
            // Create a new id, vote pair
            checkpoints[_delegatee][delNum] = Checkpoint({ id: blockNumber, votes: _newVotes });
            numCheckpoints[_delegatee] = delNum.add(1);
        }

        emit DelegateVotesChanged(_delegatee, _oldVotes, _newVotes);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _toDecimalString(uint256 _value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (_value == 0) {
            return "0";
        }
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
            _value /= 10;
        }
        return string(buffer);
    }

    function _toHexString(uint256 _value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(66);
        buffer[0] = bytes1("0");
        buffer[1] = bytes1("x");
        for (uint256 i = 0; i < 64; i++) {
            buffer[65 - i] = bytes1(TABLE[_value % 16]);
            _value /= 16;
        }
        return string(buffer);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(address _owner, uint256 _proposalId, bytes memory _signature) external returns (uint256);
    function activationFee() external view returns (uint256);
    function verify(uint256 _tokenId, address _minter, string memory _phrase) external view returns (bool);
    function getHash(uint256 _tokenId) external view returns (bytes32);
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDeactivateToken {
    struct DeactivateToken {
        uint256 proposalId;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_TOKEN_HASH = keccak256(abi.encodePacked(
    //        "DeactivateToken(",
    //        "uint256 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH =
        0xe6c775d77ef8ec84277aad8c3f9e3fa051e3ca07ea28a40e99a1fdf5b8cc0709;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateTokenHash(DeactivateToken memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateToken(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateToken(DeactivateToken memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_TOKEN_SCHEMA_HASH;

        assembly {
            // Assert deactivate offset (this is an internal error that should never be triggered)
            if lt(_deactivate, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_deactivate, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.6;

library LibEIP712 {
    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 internal constant _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return result EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32 result) {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// solhint-disable max-line-length
/**
 * @notice A library for validating signatures.
 * @dev Much of this file was taken from the LibSignature implementation found at:
 *      https://github.com/0xProject/protocol/blob/development/contracts/zero-ex/contracts/src/features/libs/LibSignature.sol
 */
// solhint-enable max-line-length
library LibSignature {
    // Exclusive upper limit on ECDSA signatures 'R' values. The valid range is
    // given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);

    // Exclusive upper limit on ECDSA signatures 'S' values. The valid range is
    // given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /**
     * @dev Retrieve the signer of a signature. Throws if the signature can't be
     *      validated.
     * @param _hash The hash that was signed.
     * @param _signature The signature.
     * @return The recovered signer address.
     */
    function getSignerOfHash(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "LibSignature: Signature length must be 65 bytes.");

        // Get the v, r, and s values from the signature.
        uint8 v = uint8(_signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 0x21))
            s := mload(add(_signature, 0x41))
        }

        // Enforce the signature malleability restrictions.
        validateSignatureMalleabilityLimits(v, r, s);

        // Recover the signature without pre-hashing.
        address recovered = ecrecover(_hash, v, r, s);

        // `recovered` can be null if the signature values are out of range.
        require(recovered != address(0), "LibSignature: Bad signature data.");
        return recovered;
    }

    /**
     * @notice Validates the malleability limits of an ECDSA signature.
     *
     *         Context:
     *
     *         EIP-2 still allows signature malleability for ecrecover(). Remove
     *         this possibility and make the signature unique. Appendix F in the
     *         Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf),
     *         defines the valid range for r in (282): 0 < r < secp256k1n, the
     *         valid range for s in (283): 0 < s < secp256k1n ÷ 2 + 1, and for v
     *         in (284): v ∈ {27, 28}. Most signatures from current libraries
     *         generate a unique signature with an s-value in the lower half order.
     *
     *         If your library generates malleable signatures, such as s-values
     *         in the upper range, calculate a new s-value with
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1
     *         and flip v from 27 to 28 or vice versa. If your library also
     *         generates signatures with 0/1 for v instead 27/28, add 27 to v to
     *         accept these malleable signatures as well.
     *
     * @param _v The v value of the signature.
     * @param _r The r value of the signature.
     * @param _s The s value of the signature.
     */
    function validateSignatureMalleabilityLimits(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure {
        // Ensure the r, s, and v are within malleability limits. Appendix F of
        // the Yellow Paper stipulates that all three values should be checked.
        require(uint256(_r) < ECDSA_SIGNATURE_R_LIMIT, "LibSignature: r parameter of signature is invalid.");
        require(uint256(_s) < ECDSA_SIGNATURE_S_LIMIT, "LibSignature: s parameter of signature is invalid.");
        require(_v == 27 || _v == 28, "LibSignature: v parameter of signature is invalid.");
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Hashes } from "./Hashes.sol";

contract TestHashes is Hashes(1000000000000000000, 100, 1000, "https://example.com/") {
    function setNonce(uint256 _nonce) public nonReentrant {
        nonce = _nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { IHashes } from "./IHashes.sol";
import { LibBytes } from "./LibBytes.sol";
import { LibDeactivateAuthority } from "./LibDeactivateAuthority.sol";
import { LibEIP712 } from "./LibEIP712.sol";
import { LibSignature } from "./LibSignature.sol";
import { LibVeto } from "./LibVeto.sol";
import { LibVoteCast } from "./LibVoteCast.sol";
import { MathHelpers } from "./MathHelpers.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./MathHelpers.sol";

/**
 * @title HashesDAO
 * @author DEX Labs
 * @notice This contract handles governance for the HashesDAO and the
 *         Hashes ERC-721 token ecosystem.
 */
contract HashesDAO is Ownable {
    using SafeMath for uint256;
    using MathHelpers for uint256;
    using LibBytes for bytes;

    /// @notice name for this Governance apparatus
    string public constant name = "HashesDAO"; // solhint-disable-line const-name-snakecase

    /// @notice version for this Governance apparatus
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    // Hashes ERC721 token
    IHashes hashesToken;

    // A boolean reflecting whether or not the authority system is still active.
    bool public authoritiesActive;
    // The minimum number of votes required for any authority actions.
    uint256 public quorumAuthorities;
    // Authority status by address.
    mapping(address => bool) authorities;
    // Proposal struct by ID
    mapping(uint256 => Proposal) proposals;
    // Latest proposal IDs by proposer address
    mapping(address => uint128) latestProposalIds;
    // Whether transaction hash is currently queued
    mapping(bytes32 => bool) queuedTransactions;
    // Max number of operations/actions a proposal can have
    uint32 public immutable proposalMaxOperations;
    // Number of blocks after a proposal is made that voting begins
    // (e.g. 1 block)
    uint32 public immutable votingDelay;
    // Number of blocks voting will be held
    // (e.g. 17280 blocks ~ 3 days of blocks)
    uint32 public immutable votingPeriod;
    // Time window (s) a successful proposal must be executed,
    // otherwise will be expired, measured in seconds
    // (e.g. 1209600 seconds)
    uint32 public immutable gracePeriod;
    // Minimum number of for votes required, even if there's a
    // majority in favor
    // (e.g. 100 votes)
    uint32 public immutable quorumVotes;
    // Minimum Hashes token holdings required to create a proposal
    // (e.g. 2 votes)
    uint32 public immutable proposalThreshold;
    // Time (s) proposals must be queued before executing
    uint32 public immutable timelockDelay;
    // Total number of proposals
    uint128 proposalCount;

    struct Proposal {
        bool canceled;
        bool executed;
        address proposer;
        uint32 delay;
        uint128 id;
        uint256 eta;
        uint256 forVotes;
        uint256 againstVotes;
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        uint256[] values;
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(
        uint128 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice Emitted when a vote has been cast on a proposal
    event VoteCast(address indexed voter, uint128 indexed proposalId, bool support, uint256 votes);

    /// @notice Emitted when the authority system is deactivated.
    event AuthoritiesDeactivated();

    /// @notice Emitted when a proposal has been canceled
    event ProposalCanceled(uint128 indexed id);

    /// @notice Emitted when a proposal has been executed
    event ProposalExecuted(uint128 indexed id);

    /// @notice Emitted when a proposal has been queued
    event ProposalQueued(uint128 indexed id, uint256 eta);

    /// @notice Emitted when a proposal has been vetoed
    event ProposalVetoed(uint128 indexed id, uint256 quorum);

    /// @notice Emitted when a proposal action has been canceled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /**
     * @dev Makes functions only accessible when the authority system is still
     *      active.
     */
    modifier onlyAuthoritiesActive() {
        require(authoritiesActive, "HashesDAO: authorities must be active.");
        _;
    }

    /**
     * @notice Constructor for the HashesDAO. Initializes the state.
     * @param _hashesToken The hashes token address. This is the contract that
     *        will be called to check for governance membership.
     * @param _authorities A list of authorities that are able to veto
     *        governance proposals. Authorities can revoke their status, but
     *        new authorities can never be added.
     * @param _proposalMaxOperations Max number of operations/actions a
     *        proposal can have
     * @param _votingDelay Number of blocks after a proposal is made
     *        that voting begins.
     * @param _votingPeriod Number of blocks voting will be held.
     * @param _gracePeriod Period in which a successful proposal must be
     *        executed, otherwise will be expired.
     * @param _timelockDelay Time (s) in which a successful proposal
     *        must be in the queue before it can be executed.
     * @param _quorumVotes Minimum number of for votes required, even
     *        if there's a majority in favor.
     * @param _proposalThreshold Minimum Hashes token holdings required
     *        to create a proposal
     */
    constructor(
        IHashes _hashesToken,
        address[] memory _authorities,
        uint32 _proposalMaxOperations,
        uint32 _votingDelay,
        uint32 _votingPeriod,
        uint32 _gracePeriod,
        uint32 _timelockDelay,
        uint32 _quorumVotes,
        uint32 _proposalThreshold
    )
    Ownable()
    {
        hashesToken = _hashesToken;

        // Set initial variable values
        authoritiesActive = true;
        quorumAuthorities = _authorities.length / 2 + 1;
        address lastAuthority;
        for (uint256 i = 0; i < _authorities.length; i++) {
            require(lastAuthority < _authorities[i], "HashesDAO: authority addresses should monotonically increase.");
            lastAuthority = _authorities[i];
            authorities[_authorities[i]] = true;
        }
        proposalMaxOperations = _proposalMaxOperations;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        gracePeriod = _gracePeriod;
        timelockDelay = _timelockDelay;
        quorumVotes = _quorumVotes;
        proposalThreshold = _proposalThreshold;
    }

    /* solhint-disable ordering */
    receive() external payable {

    }

    /**
     * @notice This function allows participants who have sufficient
     *         Hashes holdings to create new proposals up for vote. The
     *         proposals contain the ordered lists of on-chain
     *         executable calldata.
     * @param _targets Addresses of contracts involved.
     * @param _values Values to be passed along with the calls.
     * @param _signatures Function signatures.
     * @param _calldatas Calldata passed to the function.
     * @param _description Text description of proposal.
     */
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint128) {
        // Ensure proposer has sufficient token holdings to propose
        require(
            hashesToken.getPriorVotes(msg.sender, block.number.sub(1)) >= proposalThreshold,
            "HashesDAO: proposer votes below proposal threshold."
        );
        require(
            _targets.length == _values.length &&
            _targets.length == _signatures.length &&
            _targets.length == _calldatas.length,
            "HashesDAO: proposal function information parity mismatch."
        );
        require(_targets.length != 0, "HashesDAO: must provide actions.");
        require(_targets.length <= proposalMaxOperations, "HashesDAO: too many actions.");

        if (latestProposalIds[msg.sender] != 0) {
            // Ensure proposer doesn't already have one active/pending
            ProposalState proposersLatestProposalState =
                state(latestProposalIds[msg.sender]);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "HashesDAO: one live proposal per proposer, found an already active proposal."
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "HashesDAO: one live proposal per proposer, found an already pending proposal."
            );
        }

        // Proposal voting starts votingDelay after proposal is made
        uint256 startBlock = block.number.add(votingDelay);

        // Increment count of proposals
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.delay = timelockDelay;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = startBlock.add(votingPeriod);

        // Update proposer's latest proposal
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            startBlock,
            startBlock.add(votingPeriod),
            _description
        );
        return newProposal.id;
    }

    /**
     * @notice This function allows any participant to queue a
     *         successful proposal for execution. Proposals are deemed
     *         successful if there is a simple majority (and more for
     *         votes than the minimum quorum) at the end of voting.
     * @param _proposalId Proposal id.
     */
    function queue(uint128 _proposalId) external {
        // Ensure proposal has succeeded (i.e. the voting period has
        // ended and there is a simple majority in favor and also above
        // the quorum
        require(
            state(_proposalId) == ProposalState.Succeeded,
            "HashesDAO: proposal can only be queued if it is succeeded."
        );
        Proposal storage proposal = proposals[_proposalId];

        // Establish eta of execution, which is a number of seconds
        // after queuing at which point proposal can actually execute
        uint256 eta = block.timestamp.add(proposal.delay);
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            // Ensure proposal action is not already in the queue
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    eta
                )
            );
            require(!queuedTransactions[txHash], "HashesDAO: proposal action already queued at eta.");
            queuedTransactions[txHash] = true;
            emit QueueTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        // Set proposal eta timestamp after which it can be executed
        proposal.eta = eta;
        emit ProposalQueued(_proposalId, eta);
    }

    /**
     * @notice This function allows any participant to execute a
     *         queued proposal. A proposal in the queue must be in the
     *         queue for the delay period it was proposed with prior to
     *         executing, allowing the community to position itself
     *         accordingly.
     * @param _proposalId Proposal id.
     */
    function execute(uint128 _proposalId) external payable {
        // Ensure proposal is queued
        require(
            state(_proposalId) == ProposalState.Queued,
            "HashesDAO: proposal can only be executed if it is queued."
        );
        Proposal storage proposal = proposals[_proposalId];
        // Ensure proposal has been in the queue long enough
        require(block.timestamp >= proposal.eta, "HashesDAO: proposal hasn't finished queue time length.");

        // Ensure proposal hasn't been in the queue for too long
        require(block.timestamp <= proposal.eta.add(gracePeriod), "HashesDAO: transaction is stale.");

        proposal.executed = true;

        // Loop through each of the actions in the proposal
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            require(queuedTransactions[txHash], "HashesDAO: transaction hasn't been queued.");

            queuedTransactions[txHash] = false;

            // Execute action
            bytes memory callData;
            require(bytes(proposal.signatures[i]).length != 0, "HashesDAO: Invalid function signature.");
            callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            // solium-disable-next-line security/no-call-value
            (bool success, ) = proposal.targets[i].call{ value: proposal.values[i] }(callData);

            require(success, "HashesDAO: transaction execution reverted.");

            emit ExecuteTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice This function allows any participant to cancel any non-
     *         executed proposal. It can be canceled if the proposer's
     *         token holdings has dipped below the proposal threshold
     *         at the time of cancellation.
     * @param _proposalId Proposal id.
     */
    function cancel(uint128 _proposalId) external {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure proposer's token holdings has dipped below the
        // proposer threshold, leaving their proposal subject to
        // cancellation
        require(
            hashesToken.getPriorVotes(proposal.proposer, block.number.sub(1)) < proposalThreshold,
            "HashesDAO: proposer above threshold."
        );

        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice This function allows participants to cast either in
     *         favor or against a particular proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     */
    function castVote(uint128 _proposalId, bool _support, bool _deactivate, bytes memory _deactivateSignature) external {
        return _castVote(msg.sender, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice This function allows participants to cast votes with
     *         offline signatures in favor or against a particular
     *         proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     * @param _signature Signature
     */
    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature,
        bytes memory _signature
    ) external {
        // EIP712 hashing logic
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 voteCastHash =
        LibVoteCast.getVoteCastHash(
            LibVoteCast.VoteCast({ proposalId: _proposalId, support: _support, deactivate: _deactivate }),
            eip712DomainHash
        );

        // Recover the signature and EIP712 hash
        address recovered = LibSignature.getSignerOfHash(voteCastHash, _signature);

        // Cast the vote and return the result
        return _castVote(recovered, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice Allows the authorities to veto a proposal.
     * @param _proposalId The ID of the proposal to veto.
     * @param _signatures The signatures of the authorities.
     */
    function veto(uint128 _proposalId, bytes[] memory _signatures) external onlyAuthoritiesActive {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure that a sufficient amount of authorities have signed to veto
        // this proposal.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 vetoHash =
            LibVeto.getVetoHash(
                LibVeto.Veto({ proposalId: _proposalId }),
                eip712DomainHash
            );
        _verifyAuthorityAction(vetoHash, _signatures);

        // Cancel the proposal.
        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash =
            keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalVetoed(_proposalId, _signatures.length);
    }

    /**
     * @notice Allows a quorum of authorities to deactivate the authority
     *         system. This operation can only be performed once and will
     *         prevent all future actions undertaken by the authorities.
     * @param _signatures The authority signatures to use to deactivate.
     * @param _authorities A list of authorities to delete. This isn't
     *        security-critical, but it allows the state to be cleaned up.
     */
    function deactivateAuthorities(bytes[] memory _signatures, address[] memory _authorities) external onlyAuthoritiesActive {
        // Ensure that a sufficient amount of authorities have signed to
        // deactivate the authority system.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 deactivateHash =
            LibDeactivateAuthority.getDeactivateAuthorityHash(
                LibDeactivateAuthority.DeactivateAuthority({ support: true }),
                eip712DomainHash
            );
        _verifyAuthorityAction(deactivateHash, _signatures);

        // Deactivate the authority system.
        authoritiesActive = false;
        quorumAuthorities = 0;
        for (uint256 i = 0; i < _authorities.length; i++) {
            authorities[_authorities[i]] = false;
        }

        emit AuthoritiesDeactivated();
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the actions involved in a given proposal.
     * @param _proposalId Proposal id.
     * @return targets Addresses of contracts involved.
     * @return values Values to be passed along with the calls.
     * @return signatures Function signatures.
     * @return calldatas Calldata passed to the function.
     */
    function getActions(uint128 _proposalId)
    external
    view
    returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice This function allows any participant to retrieve the authority
     *         status of an arbitrary address.
     * @param _authority The address to check.
     * @return The authority status of the address.
     */
    function getAuthorityStatus(address _authority) external view returns (bool) {
        return authorities[_authority];
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the receipt for a given proposal and voter.
     * @param _proposalId Proposal id.
     * @param _voter Voter address.
     * @return Voter receipt.
     */
    function getReceipt(uint128 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /**
     * @notice This function gets a proposal from an ID.
     * @param _proposalId Proposal id.
     * @return Proposal attributes.
     */
    function getProposal(uint128 _proposalId)
    external
    view
    returns (
        bool,
        bool,
        address,
        uint32,
        uint128,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.canceled,
            proposal.executed,
            proposal.proposer,
            proposal.delay,
            proposal.id,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.eta,
            proposal.startBlock,
            proposal.endBlock
        );
    }

    /**
     * @notice This function gets whether a proposal action transaction
     *         hash is queued or not.
     * @param _txHash Proposal action tx hash.
     * @return Is proposal action transaction hash queued or not.
     */
    function getIsQueuedTransaction(bytes32 _txHash) external view returns (bool) {
        return queuedTransactions[_txHash];
    }

    /**
     * @notice This function gets the proposal count.
     * @return Proposal count.
     */
    function getProposalCount() external view returns (uint128) {
        return proposalCount;
    }

    /**
     * @notice This function gets the latest proposal ID for a user.
     * @param _proposer Proposer's address.
     * @return Proposal ID.
     */
    function getLatestProposalId(address _proposer) external view returns (uint128) {
        return latestProposalIds[_proposer];
    }

    /**
     * @notice This function retrieves the status for any given
     *         proposal.
     * @param _proposalId Proposal id.
     * @return Status of proposal.
     */
    function state(uint128 _proposalId) public view returns (ProposalState) {
        require(proposalCount >= _proposalId && _proposalId > 0, "HashesDAO: invalid proposal id.");
        Proposal storage proposal = proposals[_proposalId];

        // Note the 3rd conditional where we can escape out of the vote
        // phase if the for or against votes exceeds the skip remaining
        // voting threshold
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(gracePeriod)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function _castVote(
        address _voter,
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) internal {
        // Sanity check the input.
        require(!(_support && _deactivate), "HashesDAO: can't support and deactivate simultaneously.");

        require(state(_proposalId) == ProposalState.Active, "HashesDAO: voting is closed.");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];

        // Ensure voter has not already voted
        require(!receipt.hasVoted, "HashesDAO: voter already voted.");

        // Obtain the token holdings (voting power) for participant at
        // the time voting started. They may have gained or lost tokens
        // since then, doesn't matter.
        uint256 votes = hashesToken.getPriorVotes(_voter, proposal.startBlock);

        // Ensure voter has nonzero voting power
        require(votes > 0, "HashesDAO: voter has no voting power.");
        if (_support) {
            // Increment the for votes in favor
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            // Increment the against votes
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        // Set receipt attributes based on cast vote parameters
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        // If necessary, deactivate the voter's hashes tokens.
        if (_deactivate) {
            uint256 deactivationCount = hashesToken.deactivateTokens(_voter, _proposalId, _deactivateSignature);
            if (deactivationCount > 0) {
                // Transfer the voter the activation fee for each of the deactivated tokens.
                (bool sent,) = _voter.call{value: hashesToken.activationFee().mul(deactivationCount)}("");
                require(sent, "Hashes: couldn't re-pay the token owner after deactivating hashes.");
            }
        }

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    /**
     * @dev Verifies a submission from authorities. In particular, this
     *      validates signatures, authorization status, and quorum.
     * @param _hash The message hash to use during recovery.
     * @param _signatures The authority signatures to verify.
     */
    function _verifyAuthorityAction(bytes32 _hash, bytes[] memory _signatures) internal view {
        address lastAddress;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address recovered = LibSignature.getSignerOfHash(_hash, _signatures[i]);
            require(lastAddress < recovered, "HashesDAO: recovered addresses should monotonically increase.");
            require(authorities[recovered], "HashesDAO: recovered addresses should be authorities.");
            lastAddress = recovered;
        }
        require(_signatures.length >= quorumAuthorities / 2 + 1, "HashesDAO: veto quorum was not reached.");
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.6;

library LibBytes {
    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    ) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        require(from <= to, "FROM_LESS_THAN_TO_REQUIRED");
        require(to <= b.length, "TO_LESS_THAN_LENGTH_REQUIRED");

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        require(from <= to, "FROM_LESS_THAN_TO_REQUIRED");
        require(to <= b.length, "TO_LESS_THAN_LENGTH_REQUIRED");

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "GREATER_THAN_ZERO_LENGTH_REQUIRED");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Pops the last 20 bytes off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The 20 byte address that was popped off.
    function popLast20Bytes(bytes memory b) internal pure returns (address result) {
        require(b.length >= 20, "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED");

        // Store last 20 bytes.
        result = readAddress(b, b.length - 20);

        assembly {
            // Subtract 20 from byte array length.
            let newLen := sub(mload(b), 20)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    ) internal pure {
        require(
            b.length >= index + 20, // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    ) internal pure {
        require(b.length >= index + 32, "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    ) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "GREATER_OR_EQUAL_TO_4_LENGTH_REQUIRED");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Reads an unpadded bytes2 value from a position in a byte array.
    /// @param b Byte array containing a bytes2 value.
    /// @param index Index in byte array of bytes2 value.
    /// @return result bytes2 value from byte array.
    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "GREATER_OR_EQUAL_TO_2_LENGTH_REQUIRED");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes2 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Reads nested bytes from a specific position.
    /// @dev NOTE: the returned value overlaps with the input value.
    ///            Both should be treated as immutable.
    /// @param b Byte array containing nested bytes.
    /// @param index Index of nested bytes.
    /// @return result Nested bytes.
    function readBytesWithLength(bytes memory b, uint256 index) internal pure returns (bytes memory result) {
        // Read length of nested bytes
        uint256 nestedBytesLength = readUint256(b, index);
        index += 32;

        // Assert length of <b> is valid, given
        // length of nested bytes
        require(b.length >= index + nestedBytesLength, "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED");

        // Return a pointer to the byte array as it exists inside `b`
        assembly {
            result := add(b, index)
        }
        return result;
    }

    /// @dev Inserts bytes at a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes to insert.
    function writeBytesWithLength(
        bytes memory b,
        uint256 index,
        bytes memory input
    ) internal pure {
        // Assert length of <b> is valid, given
        // length of input
        require(
            b.length >= index + 32 + input.length, // 32 bytes to store length
            "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED"
        );

        // Copy <input> into <b>
        memCopy(
            b.contentAddress() + index,
            input.rawAddress(), // includes length of <input>
            input.length + 32 // +32 bytes to store <input> length
        );
    }

    /// @dev Performs a deep copy of a byte array onto another byte array of greater than or equal length.
    /// @param dest Byte array that will be overwritten with source bytes.
    /// @param source Byte array to copy onto dest bytes.
    function deepCopyBytes(bytes memory dest, bytes memory source) internal pure {
        uint256 sourceLen = source.length;
        // Dest length must be >= source length, or some bytes would not be copied.
        require(dest.length >= sourceLen, "GREATER_OR_EQUAL_TO_SOURCE_BYTES_LENGTH_REQUIRED");
        memCopy(dest.contentAddress(), source.contentAddress(), sourceLen);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDeactivateAuthority {
    struct DeactivateAuthority {
        bool support;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_AUTHORITY_HASH = keccak256(abi.encodePacked(
    //        "DeactivateAuthority(",
    //        "bool support",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH =
        0x17dec47eaa269b80dfd59f06648e0096c5e96c83185c6a1be1c71cf853a79a40;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateAuthorityHash(DeactivateAuthority memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateAuthority(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateAuthority(DeactivateAuthority memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH;

        assembly {
            // Assert deactivate offset (this is an internal error that should never be triggered)
            if lt(_deactivate, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_deactivate, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVeto {
    struct Veto {
        uint128 proposalId; // Proposal ID
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VETO_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "Veto(",
    //        "uint128 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VETO_SCHEMA_HASH =
        0x634b7f2828b36c241805efe02eca7354b65d9dd7345300a9c3fca91c0b028ad7;

    /// @dev Calculates Keccak-256 hash of the veto.
    /// @param _veto The veto structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return vetoHash Keccak-256 EIP712 hash of the veto.
    function getVetoHash(Veto memory _veto, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 vetoHash)
    {
        vetoHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVeto(_veto));
        return vetoHash;
    }

    /// @dev Calculates EIP712 hash of the veto.
    /// @param _veto The veto structure.
    /// @return result EIP712 hash of the veto.
    function hashVeto(Veto memory _veto) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VETO_SCHEMA_HASH;

        assembly {
            // Assert veto offset (this is an internal error that should never be triggered)
            if lt(_veto, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_veto, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVoteCast {
    struct VoteCast {
        uint128 proposalId; // Proposal ID
        bool support; // Support
        bool deactivate; // Deactivation preference
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VOTE_CAST_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "VoteCast(",
    //        "uint128 proposalId,",
    //        "bool support,",
    //        "bool deactivate",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VOTE_CAST_SCHEMA_HASH =
        0xe2e736baec1b33e622ec76a499ffd32b809860cc499f4d543162d229e795be74;

    /// @dev Calculates Keccak-256 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return voteCastHash Keccak-256 EIP712 hash of the vote cast.
    function getVoteCastHash(VoteCast memory _voteCast, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 voteCastHash)
    {
        voteCastHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVoteCast(_voteCast));
        return voteCastHash;
    }

    /// @dev Calculates EIP712 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @return result EIP712 hash of the vote cast.
    function hashVoteCast(VoteCast memory _voteCast) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VOTE_CAST_SCHEMA_HASH;

        assembly {
            // Assert vote cast offset (this is an internal error that should never be triggered)
            if lt(_voteCast, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_voteCast, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 128)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
library MathHelpers {
    using SafeMath for uint256;

    function proportion256(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return uint256(a).mul(b).div(c);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

