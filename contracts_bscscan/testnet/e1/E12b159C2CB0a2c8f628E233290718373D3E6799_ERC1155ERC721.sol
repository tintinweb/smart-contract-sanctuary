// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./SuperOperators.sol";
import "../eip1155/IERC1155.sol";
import "../eip1155/IERC1155Receiver.sol";
import "../eip721/IERC721.sol";
import "../eip721/IERC721Receiver.sol";
import "../libraries/Address.sol";
import "../libraries/ObjectLib32.sol";
// import "hardhat/console.sol";

contract ERC1155ERC721 is SuperOperators, IERC1155, IERC721 {
    using Address for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    uint256 private constant CREATOR_OFFSET_MULTIPLIER =
        uint256(2)**(256 - 160);
    uint256 private constant IS_NFT_OFFSET_MULTIPLIER =
        uint256(2)**(256 - 160 - 1);
    uint256 private constant PACK_ID_OFFSET_MULTIPLIER =
        uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 private constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER =
        uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 private constant NFT_INDEX_OFFSET = 63;

    uint256 private constant IS_NFT =
        0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 private constant NOT_IS_NFT =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant NFT_INDEX =
        0x00000000000000000000000000000000000000007FFFFFFF8000000000000000;
    uint256 private constant NOT_NFT_INDEX =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;
    uint256 private constant URI_ID =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 private constant PACK_ID =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 private constant PACK_INDEX =
        0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 private constant PACK_NUM_FT_TYPES =
        0x00000000000000000000000000000000000000000000000000000000007FF800;

    uint256 private constant MAX_SUPPLY = uint256(2)**32 - 1;
    uint256 private constant MAX_PACK_SIZE = uint256(2)**11;

    event CreatorshipTransfer(
        address indexed original,
        address indexed from,
        address indexed to
    );

    mapping(address => uint256) private _numNFTPerAddress; // erc721
    mapping(uint256 => uint256) private _owners; // erc721
    mapping(address => mapping(uint256 => uint256)) private _packedTokenBalance; // erc1155
    mapping(address => mapping(address => bool)) private _operatorsForAll; // erc721 and erc1155
    mapping(uint256 => address) private _erc721operators; // erc721
    mapping(uint256 => bytes32) private _metadataHash; // erc721 and erc1155
    mapping(uint256 => bytes) private _rarityPacks; // rarity configuration per packs (2 bits per Asset)
    mapping(uint256 => uint32) private _nextCollectionIndex; // extraction

    mapping(address => address) private _creatorship; // creatorship transfer

    mapping(address => bool) private _bouncers; // the contracts allowed to mint
    mapping(address => bool) private _metaTransactionContracts; // native meta-transaction support

    address private _bouncerAdmin;

    bool internal _init;

    function init(
        address metaTransactionContract,
        address admin,
        address bouncerAdmin
    ) public {
        require(!_init, "ALREADY_INITIALISED");
        _init = true;
        _metaTransactionContracts[metaTransactionContract] = true;
        _admin = admin;
        _bouncerAdmin = bouncerAdmin;
        emit MetaTransactionProcessor(metaTransactionContract, true);
    }

    event BouncerAdminChanged(address oldBouncerAdmin, address newBouncerAdmin);

    /// @notice Returns the current administrator in charge of minting rights.
    /// @return the current minting administrator in charge of minting rights.
    function getBouncerAdmin() external view returns (address) {
        return _bouncerAdmin;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(
            msg.sender == _bouncerAdmin,
            "only bouncerAdmin can change"
        );
        emit BouncerAdminChanged(_bouncerAdmin, newBouncerAdmin);
        _bouncerAdmin = newBouncerAdmin;
    }

    event Bouncer(address bouncer, bool enabled);

    /// @notice Enable or disable the ability of `bouncer` to mint tokens (minting bouncer rights).
    /// @param bouncer address that will be given/removed minting bouncer rights.
    /// @param enabled set whether the address is enabled or disabled as a minting bouncer.
    function setBouncer(address bouncer, bool enabled) external {
        require(
            msg.sender == _bouncerAdmin,
            "only bouncerAdmin can setup"
        );
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) external view returns (bool) {
        return _bouncers[who];
    }

    event MetaTransactionProcessor(
        address metaTransactionProcessor,
        bool enabled
    );

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(
        address metaTransactionProcessor,
        bool enabled
    ) external {
        require(
            msg.sender == _admin,
            "only admin can setup"
        );
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who)
        external
        view
        returns (bool)
    {
        return _metaTransactionContracts[who];
    }

    /// @notice mint a token type for `creator` on slot `packId`.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param rarity rarity power of the token.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return id of the newly minted token type.

    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external payable returns (uint256 id) {
        // require(hash != 0, "hash is zero");
        // require(_bouncers[msg.sender], "only bouncer allowed to mint");
        require(owner != address(0), "destination is zero address");
        id = generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        _mint(hash, supply, rarity, msg.sender, owner, id, data, false);
    }

    function generateTokenId(
        address creator,
        uint256 supply,
        uint40 packId,
        uint16 numFTs,
        uint16 packIndex
    ) internal pure returns (uint256) {
        require(supply > 0 && supply <= MAX_SUPPLY, "invalid supply");

        return
            uint256(uint160(creator)) *
            CREATOR_OFFSET_MULTIPLIER + // CREATOR
            (supply == 1 ? uint256(1) * IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT (1) or FT (0) // IS_NFT
            uint256(packId) *
            PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // PACk_ID
            numFTs *
            PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack // PACK_NUM_FT_TYPES
            packIndex; // packIndex (position in the pack) // PACK_INDEX
    }

    function _mint(
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address operator,
        address owner,
        uint256 id,
        bytes memory data,
        bool extraction
    ) internal {
        uint256 uriId = id & URI_ID;
        if (!extraction) {
            require(uint256(_metadataHash[uriId]) == 0, "id already used");
            _metadataHash[uriId] = hash;
            require(rarity < 4, "rarity >= 4");
            bytes memory pack = new bytes(1);
            pack[0] = bytes1(rarity * 64);
            _rarityPacks[uriId] = pack;
        }
        if (supply == 1) {
            // ERC721
            _numNFTPerAddress[owner]++;
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        } else {
            (uint256 bin, uint256 index) = id.getTokenBinIndex();
            _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin]
                .updateTokenBalance(
                    index,
                    supply,
                    ObjectLib32.Operations.REPLACE
                );
        }

        emit TransferSingle(operator, address(0), owner, id, supply);
        require(
            _checkERC1155AndCallSafeTransfer(
                operator,
                address(0),
                owner,
                id,
                supply,
                data,
                false,
                false
            ),
            "transfer rejected"
        );
    }

    /// @notice mint multiple token types for `creator` on slot `packId`.
    /// @param creator address of the creator of the tokens.
    /// @param packId unique packId for the tokens.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of each token type in the files: 0.json, 1.json, 2.json, etc...
    /// @param supplies number of tokens minted for each token type.
    /// @param rarityPack rarity power of each token types packed into 2 bits each.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return ids of each newly minted token types.
    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids) {
        require(hash != 0, "hash is zero");
        require(_bouncers[msg.sender], "only bouncer allowed to mint");
        require(owner != address(0), "destination is zero address");
        uint16 numNFTs;
        (ids, numNFTs) = allocateIds(
            creator,
            supplies,
            rarityPack,
            packId,
            hash
        );
        _mintBatches(supplies, owner, ids, numNFTs);
        completeMultiMint(msg.sender, owner, ids, supplies, data);
    }

    function allocateIds(
        address creator,
        uint256[] memory supplies,
        bytes memory rarityPack,
        uint40 packId,
        bytes32 hash
    ) internal returns (uint256[] memory ids, uint16 numNFTs) {
        require(supplies.length > 0, "supplies.length == 0");
        require(supplies.length <= MAX_PACK_SIZE, "too big batch");
        (ids, numNFTs) = generateTokenIds(creator, supplies, packId);
        uint256 uriId = ids[0] & URI_ID;
        require(uint256(_metadataHash[uriId]) == 0, "id already used");
        _metadataHash[uriId] = hash;
        _rarityPacks[uriId] = rarityPack;
    }

    function generateTokenIds(
        address creator,
        uint256[] memory supplies,
        uint40 packId
    ) internal pure returns (uint256[] memory, uint16) {
        uint16 numTokenTypes = uint16(supplies.length);
        uint256[] memory ids = new uint256[](numTokenTypes);
        uint16 numNFTs = 0;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            if (numNFTs == 0) {
                if (supplies[i] == 1) {
                    numNFTs = uint16(numTokenTypes - i);
                }
            } else {
                require(supplies[i] == 1, "NFTs need to be put at the end");
            }
        }
        uint16 numFTs = numTokenTypes - numNFTs;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            ids[i] = generateTokenId(creator, supplies[i], packId, numFTs, i);
        }
        return (ids, numNFTs);
    }

    function completeMultiMint(
        address operator,
        address owner,
        uint256[] memory ids,
        uint256[] memory supplies,
        bytes memory data
    ) internal {
        emit TransferBatch(operator, address(0), owner, ids, supplies);
        require(
            _checkERC1155AndCallSafeBatchTransfer(
                operator,
                address(0),
                owner,
                ids,
                supplies,
                data
            ),
            "transfer rejected"
        );
    }

    function _mintBatches(
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids,
        uint16 numNFTs
    ) internal {
        uint16 offset = 0;
        while (offset < supplies.length - numNFTs) {
            _mintBatch(offset, supplies, owner, ids);
            offset += 8;
        }
        // deal with NFT last. they do not care of balance packing
        if (numNFTs > 0) {
            _mintNFTs(uint16(supplies.length - numNFTs), numNFTs, owner, ids);
        }
    }

    function _mintNFTs(
        uint16 offset,
        uint32 numNFTs,
        address owner,
        uint256[] memory ids
    ) internal {
        for (uint16 i = 0; i < numNFTs; i++) {
            uint256 id = ids[i + offset];
            _owners[id] = uint256(uint160(owner));
            emit Transfer(address(0), owner, id);
        }
        _numNFTPerAddress[owner] += numNFTs;
    }

    function _mintBatch(
        uint16 offset,
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids
    ) internal {
        uint256 firstId = ids[offset];
        (uint256 bin, uint256 index) = firstId.getTokenBinIndex();
        uint256 balances = _packedTokenBalance[owner][bin];
        for (uint256 i = 0; i < 8 && offset + i < supplies.length; i++) {
            uint256 j = offset + i;
            if (supplies[j] > 1) {
                balances = balances.updateTokenBalance(
                    index + i,
                    supplies[j],
                    ObjectLib32.Operations.REPLACE
                );
            } else {
                break;
            }
        }
        _packedTokenBalance[owner][bin] = balances;
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal returns (bool metaTx) {
        require(to != address(0), "destination is zero address");
        require(from != address(0), "from is zero address");
        metaTx = _metaTransactionContracts[msg.sender];
        bool authorized = from == msg.sender ||
            metaTx ||
            _superOperators[msg.sender] ||
            _operatorsForAll[from][msg.sender];

        if (id & IS_NFT > 0) {
            require(
                authorized || _erc721operators[id] == msg.sender,
                "Operator not approved"
            );
            if (value > 0) {
                require(value == 1, "cannot transfer nft");
                _numNFTPerAddress[from]--;
                _numNFTPerAddress[to]++;
                _owners[id] = uint256(uint160(to));
                if (_erc721operators[id] != address(0)) {
                    // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                    _erc721operators[id] = address(0);
                }
                emit Transfer(from, to, id);
            }
        } else {
            require(authorized, "Operator not approved");
            if (value > 0) {
                // if different owners it will fails
                (uint256 bin, uint256 index) = id.getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin]
                    .updateTokenBalance(
                        index,
                        value,
                        ObjectLib32.Operations.SUB
                    );
                _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin]
                    .updateTokenBalance(
                        index,
                        value,
                        ObjectLib32.Operations.ADD
                    );
            }
        }

        emit TransferSingle(metaTx ? from : msg.sender, from, to, id, value);
    }

    /// @notice Transfers `value` tokens of type `id` from  `from` to `to`  (with safety call).
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param id the token type transfered.
    /// @param value amount of token transfered.
    /// @param data aditional data accompanying the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        if (id & IS_NFT > 0) {
            require(_ownerOf(id) == from, "not owner");
        }
        bool metaTx = _transferFrom(from, to, id, value);
        require(
            _checkERC1155AndCallSafeTransfer(
                metaTx ? from : msg.sender,
                from,
                to,
                id,
                value,
                data,
                false,
                false
            ),
            "erc1155 transfer rejected"
        );
    }

    /// @notice Transfers `values` tokens of type `ids` from  `from` to `to` (with safety call).
    /// @dev call data should be optimized to order ids so packedBalance can be used efficiently.
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param ids ids of each token type transfered.
    /// @param values amount of each token type transfered.
    /// @param data aditional data accompanying the transfer.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(
            ids.length == values.length,
            "Inconsistent array length"
        );
        require(to != address(0), "destination is zero address");
        require(from != address(0), "from is zero address");
        bool metaTx = _metaTransactionContracts[msg.sender];
        bool authorized = from == msg.sender ||
            metaTx ||
            _superOperators[msg.sender] ||
            _operatorsForAll[from][msg.sender]; // solium-disable-line max-len

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(metaTx ? from : msg.sender, from, to, ids, values);
        require(
            _checkERC1155AndCallSafeBatchTransfer(
                metaTx ? from : msg.sender,
                from,
                to,
                ids,
                values,
                data
            ),
            "erc1155 transfer rejected"
        );
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bool authorized
    ) internal {
        uint256 numItems = ids.length;
        uint256 bin;
        uint256 index;
        uint256 balFrom;
        uint256 balTo;

        uint256 lastBin;
        uint256 numNFTs = 0;
        for (uint256 i = 0; i < numItems; i++) {
            if (ids[i] & IS_NFT > 0) {
                require(
                    authorized || _erc721operators[ids[i]] == msg.sender,
                    "Operator not approved"
                );
                if (values[i] > 0) {
                    require(
                        values[i] == 1,
                        "cannot transfer nft"
                    );
                    require(_ownerOf(ids[i]) == from, "not owner");
                    numNFTs++;
                    _owners[ids[i]] = uint256(uint160(to));
                    if (_erc721operators[ids[i]] != address(0)) {
                        // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                        _erc721operators[ids[i]] = address(0);
                    }
                    emit Transfer(from, to, ids[i]);
                }
            } else {
                require(authorized, "Operator not approved");
                if (from == to) {
                    _checkEnoughBalance(from, ids[i], values[i]);
                } else if (values[i] > 0) {
                    (bin, index) = ids[i].getTokenBinIndex();
                    if (lastBin == 0) {
                        lastBin = bin;
                        balFrom = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[from][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.SUB
                        );
                        balTo = ObjectLib32.updateTokenBalance(
                            _packedTokenBalance[to][bin],
                            index,
                            values[i],
                            ObjectLib32.Operations.ADD
                        );
                    } else {
                        if (bin != lastBin) {
                            _packedTokenBalance[from][lastBin] = balFrom;
                            _packedTokenBalance[to][lastBin] = balTo;
                            balFrom = _packedTokenBalance[from][bin];
                            balTo = _packedTokenBalance[to][bin];
                            lastBin = bin;
                        }

                        balFrom = balFrom.updateTokenBalance(
                            index,
                            values[i],
                            ObjectLib32.Operations.SUB
                        );
                        balTo = balTo.updateTokenBalance(
                            index,
                            values[i],
                            ObjectLib32.Operations.ADD
                        );
                    }
                }
            }
        }
        if (numNFTs > 0 && from != to) {
            _numNFTPerAddress[from] -= numNFTs;
            _numNFTPerAddress[to] += numNFTs;
        }

        if (bin != 0 && from != to) {
            _packedTokenBalance[from][bin] = balFrom;
            _packedTokenBalance[to][bin] = balTo;
        }
    }

    function _checkEnoughBalance(
        address from,
        uint256 id,
        uint256 value
    ) internal view {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(
            _packedTokenBalance[from][bin].getValueInBin(index) >= value,
            "can't substract more than there"
        );
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        // do not check for existence, balance is zero if never minted
        // require(wasEverMinted(id), "token was never minted");
        if (id & IS_NFT > 0) {
            if (_ownerOf(id) == owner) {
                return 1;
            } else {
                return 0;
            }
        }
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice Get the balance of `owners` for each token type `ids`.
    /// @param owners the addresses of the token holders queried.
    /// @param ids ids of each token type to query.
    /// @return the balance of each `owners` for each token type `ids`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(
            owners.length == ids.length,
            "Inconsistent array length"
        );
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
        return balances;
    }

    /// @notice Get the creator of the token type `id`.
    /// @param id the id of the token to get the creator of.
    /// @return the creator of the token type `id`.
    function creatorOf(uint256 id) external view returns (address) {
        require(wasEverMinted(id), "token was never minted");
        address originalCreator = address(
            uint160(id / CREATOR_OFFSET_MULTIPLIER)
        );
        address newCreator = _creatorship[originalCreator];
        if (newCreator != address(0)) {
            return newCreator;
        }
        return originalCreator;
    }

    /// @notice Transfers creatorship of `original` from `sender` to `to`.
    /// @param sender address of current registered creator.
    /// @param original address of the original creator whose creation are saved in the ids themselves.
    /// @param to address which will be given creatorship for all tokens originally minted by `original`.
    function transferCreatorship(
        address sender,
        address original,
        address to
    ) external {
        require(
            msg.sender == sender ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender],
            "require meta approval"
        );
        require(sender != address(0), "sender is zero address");
        require(to != address(0), "destination is zero address");
        address current = _creatorship[original];
        if (current == address(0)) {
            current = original;
        }
        require(current != to, "current == to");
        require(current == sender, "current != sender");
        if (to == original) {
            _creatorship[original] = address(0);
        } else {
            _creatorship[original] = to;
        }
        emit CreatorshipTransfer(original, current, to);
    }

    /// @notice Enable or disable approval for `operator` to manage all `sender`'s tokens.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender address which grant approval.
    /// @param operator address which will be granted rights to transfer all token owned by `sender`.
    /// @param approved whether to approve or revoke.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(
            msg.sender == sender ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender],
            "require meta approval"
        );
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Enable or disable approval for `operator` to manage all of the caller's tokens.
    /// @param operator address which will be granted rights to transfer all tokens of the caller.
    /// @param approved whether to approve or revoke
    function setApprovalForAll(address operator, bool approved)
        external
        override(IERC721, IERC1155)
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(sender != address(0), "sender is zero address");
        require(sender != operator, "sender = operator");
        require(operator != address(0), "operator is zero address");
        require(
            !_superOperators[operator],
            "super operator can't have"
        );
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice isApprovedForAll the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return isOperator = true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        external
        view
        override(IERC721, IERC1155)
        returns (bool isOperator)
    {
        require(owner != address(0), "owner is zero address");
        require(operator != address(0), "operator is zero address");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice balanceOf Count all NFTs assigned to `owner`.
    /// @param owner address for whom to query the balance.
    /// @return balance the number of NFTs owned by `owner`, possibly zero.
    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        require(owner != address(0), "owner is zero address");
        return _numNFTPerAddress[owner];
    }

    /// @notice ownerOf Find the owner of an NFT.
    /// @param id the identifier for an NFT.
    /// @return owner the address of the owner of the NFT.
    function ownerOf(uint256 id)
        external
        view
        override
        returns (address owner)
    {
        owner = _ownerOf(id);
        require(owner != address(0), "NFT does not exist");
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return address(uint160(_owners[id]));
    }

    /// @notice Change or reaffirm the approved address for an NFT for `sender`.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender the sender granting control.
    /// @param operator the address to approve as NFT controller.
    /// @param id the NFT to approve.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        address owner = _ownerOf(id);
        require(sender != address(0), "sender is zero address");
        require(
            msg.sender == sender ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender] ||
                _operatorsForAll[sender][msg.sender],
            "require operators"
        ); // solium-disable-line max-len
        require(owner == sender, "not owner");
        _erc721operators[id] = operator;
        emit Approval(owner, operator, id);
    }

    /// @notice approve Change or reaffirm the approved address for an NFT.
    /// @param operator the address to approve as NFT controller.
    /// @param id the id of the NFT to approve.
    function approve(address operator, uint256 id) external override {
        address owner = _ownerOf(id);
        require(owner != address(0), "NFT does not exist");
        require(
            owner == msg.sender ||
                _superOperators[msg.sender] ||
                _operatorsForAll[owner][msg.sender],
            "not authorized"
        );
        _erc721operators[id] = operator;
        emit Approval(owner, operator, id);
    }

    /// @notice getApproved address for a single NFT.
    /// @param id the NFT to find the approved address for.
    /// @return operator the approved address for this NFT, or the zero address if there is none.
    function getApproved(uint256 id)
        external
        view
        override
        returns (address operator)
    {
        require(_ownerOf(id) != address(0), "NFT does not exist");
        return _erc721operators[id];
    }

    /// @notice transferFrom ownership of an NFT.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        require(_ownerOf(id) == from, "not owner");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(
                metaTx ? from : msg.sender,
                from,
                to,
                id,
                1,
                "",
                true,
                false
            ),
            "erc1155 transfer rejected"
        );
    }

    /// @notice safeTransferFrom the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice safeTransferFrom the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    /// @param data additional data with no specified format, sent in call to `to`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        require(_ownerOf(id) == from, "not owner");
        bool metaTx = _transferFrom(from, to, id, 1);
        require(
            _checkERC1155AndCallSafeTransfer(
                metaTx ? from : msg.sender,
                from,
                to,
                id,
                1,
                data,
                true,
                true
            ),
            "erc721/erc1155 transfer rejected"
        );
    }

    /// @notice name : A descriptive name for the collection of tokens in this contract.
    /// @return _name of the tokens.
    function name() external pure returns (string memory _name) {
        return "FORBIT's ASSETs";
    }

    /// @notice symbol : An abbreviated name for the collection of tokens in this contract.
    /// @return _symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Gives the rarity power of a particular token type.
    /// @param id the token type to get the rarity of.
    /// @return the rarity power(between 0 and 3).
    function rarityId(uint256 id) public view returns (uint256) {
        require(wasEverMinted(id), "token was never minted");
        bytes storage rarityPack = _rarityPacks[id & URI_ID];
        uint256 packIndex = id & PACK_INDEX;
        if (packIndex / 4 >= rarityPack.length) {
            return 0;
        } else {
            uint8 pack = uint8(rarityPack[packIndex / 4]);
            uint8 i = (3 - uint8(packIndex % 4)) * 2;
            return (pack / (uint8(2)**i)) % 4;
        }
    }

    /// @notice Gives the collection a specific token belongs to.
    /// @param id the token to get the collection of.
    /// @return the collection the NFT is part of.
    function collectionOf(uint256 id) public view returns (uint256) {
        require(_ownerOf(id) != address(0), "NFT does not exist");
        uint256 collectionId = id & NOT_NFT_INDEX & NOT_IS_NFT;
        require(
            wasEverMinted(collectionId),
            "no collection minted"
        );
        return collectionId;
    }

    /// @notice Return wether the id is a collection
    /// @param id collectionId to check.
    /// @return whether the id is a collection.
    function isCollection(uint256 id) public view returns (bool) {
        uint256 collectionId = id & NOT_NFT_INDEX & NOT_IS_NFT;
        return wasEverMinted(collectionId);
    }

    /// @notice Gives the index at which an NFT was minted in a collection : first of a collection get the zero index.
    /// @param id the token to get the index of.
    /// @return the index/order at which the token `id` was minted in a collection.
    function collectionIndexOf(uint256 id) public view returns (uint256) {
        collectionOf(id); // this check if id and collection indeed was ever minted
        return uint32((id & NFT_INDEX) >> NFT_INDEX_OFFSET);
    }

    function toFullURI(bytes32 hash, uint256 id)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "ipfs://bafybei",
                    hash2base32(hash),
                    "/",
                    uint2str(id & PACK_INDEX),
                    ".json"
                )
            );
    }

    function wasEverMinted(uint256 id) public view returns (bool) {
        if ((id & IS_NFT) > 0) {
            return _owners[id] != 0;
        } else {
            return
                ((id & PACK_INDEX) <
                    ((id & PACK_NUM_FT_TYPES) /
                        PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
                _metadataHash[id & URI_ID] != 0;
        }
    }

    /// @notice check whether a packId/numFT tupple has been used
    /// @param creator for which creator
    /// @param packId the packId to check
    /// @param numFTs number of Fungible Token in that pack (can reuse packId if different)
    /// @return whether the pack has already been used
    function isPackIdUsed(
        address creator,
        uint40 packId,
        uint16 numFTs
    ) external view returns (bool) {
        uint256 uriId = uint256(uint160(creator)) *
            CREATOR_OFFSET_MULTIPLIER + // CREATOR
            uint256(packId) *
            PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // PACk_ID
            numFTs *
            PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER; // number of fungible token in the pack // PACK_NUM_FT_TYPES
        return _metadataHash[uriId] != 0;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given token.
    /// @param id token to get the uri of.
    /// @return URI string
    function uri(uint256 id) public view returns (string memory) {
        require(wasEverMinted(id), "token was never minted"); // prevent returning invalid uri
        return toFullURI(_metadataHash[id & URI_ID], id);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param id token to get the uri of.
    /// @return URI string
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0), "NFT does not exist");
        return toFullURI(_metadataHash[id & URI_ID], id);
    }

    bytes32 private constant BASE32_ALPHABET =
        0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash)
        private
        pure
        returns (string memory _uintAsString)
    {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = BASE32_ALPHABET[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = BASE32_ALPHABET[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }

        return string(bstr);
    }

    /// @notice Query if a contract implements interface `id`.
    /// @param id the interface identifier, as specified in ERC-165.
    /// @return `true` if the contract implements `id`.
    function supportsInterface(bytes4 id)
        external
        pure
        override
        returns (bool)
    {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x80ac58cd || // ERC721
            id == 0x5b5e139f || // ERC721 metadata
            id == 0x0e89341c; // ERC1155 metadata
    }

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    function checkIsERC1155Receiver(address _contract)
        internal
        view
        returns (bool)
    {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(
            ERC165ID,
            ERC1155_IS_RECEIVER
        );
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(
                10000,
                _contract,
                call_ptr,
                call_size,
                output,
                0x20
            ) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    function _checkERC1155AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data,
        bool erc721,
        bool erc721Safe
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        if (erc721) {
            if (!checkIsERC1155Receiver(to)) {
                if (erc721Safe) {
                    return
                        _checkERC721AndCallSafeTransfer(
                            operator,
                            from,
                            to,
                            id,
                            data
                        );
                }
                return true;
            }
        }
        return
            IERC1155Receiver(to).onERC1155Received(
                operator,
                from,
                id,
                value,
                data
            ) == ERC1155_RECEIVED;
    }

    function _checkERC1155AndCallSafeBatchTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155Receiver(to).onERC1155BatchReceived(
            operator,
            from,
            ids,
            values,
            data
        );
        return (retval == ERC1155_BATCH_RECEIVED);
    }

    function _checkERC721AndCallSafeTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal returns (bool) {
        // following not required as this function is always called as part of ERC1155 checks that include such check already
        // if (!to.isContract()) {
        //     return true;
        // }
        return (IERC721Receiver(to).onERC721Received(
            operator,
            from,
            id,
            data
        ) == ERC721_RECEIVED);
    }

    event Extraction(uint256 indexed fromId, uint256 toId);
    event AssetUpdate(uint256 indexed fromId, uint256 toId);

    function _burnERC1155(
        address operator,
        address from,
        uint256 id,
        uint32 amount
    ) internal {
        (uint256 bin, uint256 index) = (id).getTokenBinIndex();
        _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin]
            .updateTokenBalance(index, amount, ObjectLib32.Operations.SUB);
        emit TransferSingle(operator, from, address(0), id, amount);
    }

    function _burnERC721(
        address operator,
        address from,
        uint256 id
    ) internal {
        require(from == _ownerOf(id), "not owner");
        _owners[id] = 2**160; // equivalent to zero address when casted but ensure we track minted status
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
        emit TransferSingle(operator, from, address(0), id, 1);
    }

    /// @notice Burns `amount` tokens of type `id`.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burn(uint256 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    /// @notice Burns `amount` tokens of type `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(from != address(0), "from is zero address");
        require(
            msg.sender == from ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "require meta approval"
        );
        _burn(from, id, amount);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        if ((id & IS_NFT) > 0) {
            require(amount == 1, "can only burn one NFT");
            _burnERC721(
                _metaTransactionContracts[msg.sender] ? from : msg.sender,
                from,
                id
            );
        } else {
            require(amount > 0 && amount <= MAX_SUPPLY, "invalid amount");
            _burnERC1155(
                _metaTransactionContracts[msg.sender] ? from : msg.sender,
                from,
                id,
                uint32(amount)
            );
        }
    }

    /// @notice Upgrades an NFT with new metadata and rarity.
    /// @param from address which own the NFT to be upgraded.
    /// @param id the NFT that will be burnt to be upgraded.
    /// @param packId unqiue packId for the token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the new token type in the file 0.json.
    /// @param newRarity rarity power of the new NFT.
    /// @param to address which will receive the NFT.
    /// @param data bytes to be transmitted as part of the minted token.
    /// @return the id of the newly minted NFT.
    function updateERC721(
        address from,
        uint256 id,
        uint40 packId,
        bytes32 hash,
        uint8 newRarity,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        require(hash != 0, "hash is zero");
        require(
            _bouncers[msg.sender],
            "only bouncer allowed"
        );
        require(to != address(0), "destination is zero address");
        require(from != address(0), "from is zero address");

        _burnERC721(msg.sender, from, id);

        uint256 newId = generateTokenId(from, 1, packId, 0, 0);
        _mint(hash, 1, newRarity, msg.sender, to, newId, data, false);
        emit AssetUpdate(id, newId);
        return newId;
    }

    /// @notice extractERC721 an EIP-721 NFT from an EIP-1155 token.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId of the newly minted NFT.
    function extractERC721(uint256 id, address to)
        external
        returns (uint256 newId)
    {
        return _extractERC721From(msg.sender, msg.sender, id, to);
    }

    /// @notice extractERC721From an EIP-721 NFT from an EIP-1155 token.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId of the newly minted NFT.
    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId) {
        bool metaTx = _metaTransactionContracts[msg.sender];
        require(
            msg.sender == sender ||
                metaTx ||
                _superOperators[msg.sender] ||
                _operatorsForAll[sender][msg.sender],
            "require meta approval"
        );
        return _extractERC721From(metaTx ? sender : msg.sender, sender, id, to);
    }

    function _extractERC721From(
        address operator,
        address sender,
        uint256 id,
        address to
    ) internal returns (uint256 newId) {
        require(to != address(0), "destination is zero address");
        require(id & IS_NFT == 0, "Not an ERC1155 Token");
        uint32 tokenCollectionIndex = _nextCollectionIndex[id];
        newId = id + IS_NFT + (tokenCollectionIndex) * 2**NFT_INDEX_OFFSET;
        _nextCollectionIndex[id] = tokenCollectionIndex + 1;
        _burnERC1155(operator, sender, id, 1);
        _mint(_metadataHash[id & URI_ID], 1, 0, operator, to, newId, "", true);
        emit Extraction(id, newId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../utils/Admin.sol";

contract SuperOperators is Admin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(
            msg.sender == _admin,
            "only admin is allowed"
        );
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll1155(
        address indexed account,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../utils/SafeMath.sol";

library ObjectLib32 {
    using SafeMath for uint256;
    enum Operations {
        ADD,
        SUB,
        REPLACE
    }
    // Constants regarding bin or chunk sizes for balance packing
    uint256 internal constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 internal constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
     * @dev Return the bin number and index within that bin where ID is
     * @param tokenId Object type
     * @return bin uint256, index uint256 (Bin number, ID's index within that bin)
     */
    function getTokenBinIndex(uint256 tokenId)
        internal
        pure
        returns (uint256 bin, uint256 index)
    {
        bin = (tokenId * TYPES_BITS_SIZE) / 256;
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(
                binBalances,
                index,
                objectBalance.add(amount)
            );
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(
                objectBalance >= amount,
                "can't substract more than there"
            );
            newBinBalance = writeValueInBin(
                binBalances,
                index,
                objectBalance.sub(amount)
            );
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index)
        internal
        pure
        returns (uint256)
    {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(
            amount < 2**TYPES_BITS_SIZE,
            "Amount is too large"
        );

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

contract Admin {
    address internal _admin;

    event AdminChanged(address oldAdmin, address newAdmin);

    /// @notice gives the current administrator of this contract.
    /// @return the current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @notice change the administrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin allowed");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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