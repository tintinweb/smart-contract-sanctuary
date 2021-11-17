pragma solidity 0.5.9;

import "./ERC1155ERC721.sol";
import "../contracts_common/Interfaces/ERC20.sol";
import "../contracts_common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../contracts_common/Libraries/SafeMathWithRequire.sol";

contract CommonMinter is MetaTransactionReceiver {
    using SafeMathWithRequire for uint256;

    uint256 _feePerCopy;

    ERC1155ERC721 _asset;
    mapping(address => bool) _minters;
    address _feeReceiver;
    ERC20 _sand;

    constructor(ERC1155ERC721 asset, ERC20 sand, uint256 feePerCopy, address admin, address feeReceiver)
        public
    {
        _sand = sand;
        _asset = asset;
        _feePerCopy = feePerCopy;
        _admin = admin;
        _feeReceiver = feeReceiver;
        _setMetaTransactionProcessor(address(sand), true);
    }

    /// @notice set the receiver of the proceeds
    /// @param newFeeReceiver address of the new fee receiver
    function setFeeReceiver(address newFeeReceiver) external {
        require(msg.sender == _admin, "only admin can change the receiver");
        _feeReceiver = newFeeReceiver;
    }

    /// @notice set the fee in Sand for each common Asset copies
    /// @param newFee new fee in Sand
    function setFeePerCopy(uint256 newFee) external {
        require(msg.sender == _admin, "only admin allowed to set fee");
        _feePerCopy = newFee;
    }

    /// @notice mint common Asset token by paying the Sand fee
    /// @param creator address creating the Asset, need to be the tx sender or meta tx signer
    /// @param packId unused packId that will let you predict the resulting tokenId
    /// @param hash cidv1 ipfs hash of the folder where 0.json file contains the metadata
    /// @param supply number of copies to mint, cost in Sand is relative it it
    /// @param owner address receiving the minted tokens
    /// @param data extra data
    /// @param feePerCopy fee in Sand for each copies
    function mintFor(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint32 supply,
        address owner,
        bytes calldata data,
        uint256 feePerCopy
    ) external returns (uint256 id) {
        require(creator == msg.sender || _metaTransactionContracts[msg.sender], "not authorized");
        require(feePerCopy == _feePerCopy, "invalid fee");
        require(_sand.transferFrom(creator, _feeReceiver, uint256(supply).mul(feePerCopy)), "failed to transfer SAND");
        return _asset.mint(creator, packId, hash, supply, 0, owner, data);
    }

    /// @notice mint multiple common Asset tokena by paying the Sand fee
    /// @param creator address creating the Asset, need to be the tx sender or meta tx signer
    /// @param packId unused packId that will let you predict the resulting tokenId
    /// @param hash cidv1 ipfs hash of the folder where 0.json file contains the metadata
    /// @param supplies number of copies to mint for each Asset, cost in Sand is relative it it
    /// @param owner address receiving the minted tokens
    /// @param data extra data
    /// @param feePerCopy fee in Sand for each copies
    function mintMultipleFor(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        address owner,
        bytes calldata data,
        uint256 feePerCopy
    ) external returns (uint256[] memory ids) {
        require(creator == msg.sender || _metaTransactionContracts[msg.sender], "not authorized");
        require(feePerCopy == _feePerCopy, "invalid fee");
        uint256 totalCopies = 0;
        uint256 numAssetTypes = supplies.length;
        for (uint256 i = 0; i < numAssetTypes; i++) {
            totalCopies = totalCopies.add(supplies[i]);
        }
        require(_sand.transferFrom(creator, _feeReceiver, totalCopies.mul(feePerCopy)), "failed to transfer SAND");
        return
            _asset.mintMultiple(
                creator,
                packId,
                hash,
                supplies,
                "",
                owner,
                data
            );
    }
}

pragma solidity 0.5.9;

import "../contracts_common/Interfaces/ERC1155.sol";
import "../contracts_common/Interfaces/ERC1155TokenReceiver.sol";

import "../contracts_common/Libraries/AddressUtils.sol";
import "../contracts_common/Libraries/ObjectLib32.sol";

import "../contracts_common/Interfaces/ERC721.sol";
import "../contracts_common/Interfaces/ERC721TokenReceiver.sol";

import "../contracts_common/BaseWithStorage/SuperOperators.sol";

contract ERC1155ERC721 is SuperOperators, ERC1155, ERC721 {
    using AddressUtils for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    uint256 private constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 private constant IS_NFT_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1);
    uint256 private constant PACK_ID_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 private constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 private constant NFT_INDEX_OFFSET = 63;

    uint256 private constant IS_NFT =            0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 private constant NOT_IS_NFT =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant NFT_INDEX =         0x00000000000000000000000000000000000000007FFFFFFF8000000000000000;
    uint256 private constant NOT_NFT_INDEX =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;
    uint256 private constant URI_ID =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 private constant PACK_ID =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 private constant PACK_INDEX =        0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 private constant PACK_NUM_FT_TYPES = 0x00000000000000000000000000000000000000000000000000000000007FF800;

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
    function getBouncerAdmin() external view returns(address) {
        return _bouncerAdmin;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(
            msg.sender == _bouncerAdmin,
            "only bouncerAdmin can change itself"
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
            "only bouncerAdmin can setup bouncers"
        );
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) external view returns(bool) {
        return _bouncers[who];
    }

    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) external {
        require(
            msg.sender == _admin,
            "only admin can setup metaTransactionProcessors"
        );
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns(bool) {
        return _metaTransactionContracts[who];
    }

    /// @notice Mint a token type for `creator` on slot `packId`.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param rarity rarity power of the token.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return the id of the newly minted token type.
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id) {
        require(hash != 0, "hash is zero");
        require(_bouncers[msg.sender], "only bouncer allowed to mint");
        require(owner != address(0), "destination is zero address");
        id = generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        _mint(
            hash,
            supply,
            rarity,
            msg.sender,
            owner,
            id,
            data,
            false
        );
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
            uint256(creator) * CREATOR_OFFSET_MULTIPLIER + // CREATOR
            (supply == 1 ? uint256(1) * IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT (1) or FT (0) // IS_NFT
            uint256(packId) * PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // PACk_ID
            numFTs * PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack // PACK_NUM_FT_TYPES
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
            _owners[id] = uint256(owner);
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

    /// @notice Mint multiple token types for `creator` on slot `packId`.
    /// @param creator address of the creator of the tokens.
    /// @param packId unique packId for the tokens.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of each token type in the files: 0.json, 1.json, 2.json, etc...
    /// @param supplies number of tokens minted for each token type.
    /// @param rarityPack rarity power of each token types packed into 2 bits each.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return the ids of each newly minted token types.
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
            _mintNFTs(
                uint16(supplies.length - numNFTs),
                numNFTs,
                owner,
                ids
            );
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
            _owners[id] = uint256(owner);
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
            if(value > 0) {
                require(value == 1, "cannot transfer nft if amount not 1");
                _numNFTPerAddress[from]--;
                _numNFTPerAddress[to]++;
                _owners[id] = uint256(to);
                if (_erc721operators[id] != address(0)) { // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                    _erc721operators[id] = address(0);
                }
                emit Transfer(from, to, id);
            }
        } else {
            require(authorized, "Operator not approved");
            if(value > 0) {
                // if different owners it will fails
                (uint256 bin, uint256 index) = id.getTokenBinIndex();
                _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin]
                    .updateTokenBalance(index, value, ObjectLib32.Operations.SUB);
                _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin]
                    .updateTokenBalance(index, value, ObjectLib32.Operations.ADD);
            }
        }

        emit TransferSingle(
            metaTx ? from : msg.sender,
            from,
            to,
            id,
            value
        );
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
    ) external {
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
    ) external {
        require(
            ids.length == values.length,
            "Inconsistent array length between args"
        );
        require(to != address(0), "destination is zero address");
        require(from != address(0), "from is zero address");
        bool metaTx = _metaTransactionContracts[msg.sender];
        bool authorized = from == msg.sender ||
            metaTx ||
            _superOperators[msg.sender] ||
            _operatorsForAll[from][msg.sender]; // solium-disable-line max-len

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(
            metaTx ? from : msg.sender,
            from,
            to,
            ids,
            values
        );
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
                if(values[i] > 0) {
                    require(values[i] == 1, "cannot transfer nft if amount not 1");
                    require(_ownerOf(ids[i]) == from, "not owner");
                    numNFTs++;
                    _owners[ids[i]] = uint256(to);
                    if (_erc721operators[ids[i]] != address(0)) { // TODO operatorEnabled flag optimization (like in ERC721BaseToken)
                        _erc721operators[ids[i]] = address(0);
                    }
                    emit Transfer(from, to, ids[i]);
                }
            } else {
                require(authorized, "Operator not approved");
                if (from == to) {
                    _checkEnoughBalance(from, ids[i], values[i]);
                } else if(values[i] > 0) {
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

    function _checkEnoughBalance(address from, uint256 id, uint256 value) internal {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(_packedTokenBalance[from][bin].getValueInBin(index) >= value, "can't substract more than there is");
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id)
        public
        view
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
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        require(
            owners.length == ids.length,
            "Inconsistent array length between args"
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
        address originalCreator = address(id / CREATOR_OFFSET_MULTIPLIER);
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
    function setApprovalForAll(address operator, bool approved) external {
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
            "super operator can't have their approvalForAll changed"
        );
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Queries the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool isOperator)
    {
        require(owner != address(0), "owner is zero address");
        require(operator != address(0), "operator is zero address");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Count all NFTs assigned to `owner`.
    /// @param owner address for whom to query the balance.
    /// @return the number of NFTs owned by `owner`, possibly zero.
    function balanceOf(address owner)
        external
        view
        returns (uint256 balance)
    {
        require(owner != address(0), "owner is zero address");
        return _numNFTPerAddress[owner];
    }

    /// @notice Find the owner of an NFT.
    /// @param id the identifier for an NFT.
    /// @return the address of the owner of the NFT.
    function ownerOf(uint256 id) external view returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NFT does not exist");
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return address(_owners[id]);
    }

    /// @notice Change or reaffirm the approved address for an NFT for `sender`.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender the sender granting control.
    /// @param operator the address to approve as NFT controller.
    /// @param id the NFT to approve.
    function approveFor(address sender, address operator, uint256 id)
        external
    {
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

    /// @notice Change or reaffirm the approved address for an NFT.
    /// @param operator the address to approve as NFT controller.
    /// @param id the id of the NFT to approve.
    function approve(address operator, uint256 id) external {
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

    /// @notice Get the approved address for a single NFT.
    /// @param id the NFT to find the approved address for.
    /// @return the approved address for this NFT, or the zero address if there is none.
    function getApproved(uint256 id)
        external
        view
        returns (address operator)
    {
        require(_ownerOf(id) != address(0), "NFT does not exist");
        return _erc721operators[id];
    }

    /// @notice Transfers ownership of an NFT.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function transferFrom(address from, address to, uint256 id) external {
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

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    function safeTransferFrom(address from, address to, uint256 id)
        external
    {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address.
    /// @param from the current owner of the NFT.
    /// @param to the new owner.
    /// @param id the NFT to transfer.
    /// @param data additional data with no specified format, sent in call to `to`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public {
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

    /// @notice A descriptive name for the collection of tokens in this contract.
    /// @return the name of the tokens.
    function name() external pure returns (string memory _name) {
        return "Sandbox's ASSETs";
    }

    /// @notice An abbreviated name for the collection of tokens in this contract.
    /// @return the symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Gives the rarity power of a particular token type.
    /// @param id the token type to get the rarity of.
    /// @return the rarity power(between 0 and 3).
    function rarity(uint256 id) public view returns (uint256) {
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
        require(wasEverMinted(collectionId), "no collection ever minted for that token");
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

    function wasEverMinted(uint256 id) public view returns(bool) {
        if ((id & IS_NFT) > 0) {
            return _owners[id] != 0;
        } else {
            return
                ((id & PACK_INDEX) < ((id & PACK_NUM_FT_TYPES) / PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
                _metadataHash[id & URI_ID] != 0;
        }
    }

    /// @notice check whether a packId/numFT tupple has been used
    /// @param creator for which creator
    /// @param packId the packId to check
    /// @param numFTs number of Fungible Token in that pack (can reuse packId if different)
    /// @return whether the pack has already been used
    function isPackIdUsed(address creator, uint40 packId, uint16 numFTs) external returns(bool) {
        uint256 uriId = uint256(creator) * CREATOR_OFFSET_MULTIPLIER + // CREATOR
            uint256(packId) * PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack) // PACk_ID
            numFTs * PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER; // number of fungible token in the pack // PACK_NUM_FT_TYPES
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

    bytes32 private constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;
    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash)
        private
        pure
        returns (string memory _uintAsString)
    {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
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
    function supportsInterface(bytes4 id) external view returns (bool) {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x80ac58cd || // ERC721
            id == 0x5b5e139f || // ERC721 metadata
            id == 0x0e89341c; // ERC1155 metadata
    }

    bytes4 constant ERC165ID = 0x01ffc9a7;
    function checkIsERC1155Receiver(address _contract)
        internal
        view
        returns (bool)
    {
        bool success;
        bool result;
        bytes memory call_data = abi.encodeWithSelector(
            ERC165ID,
            ERC1155_IS_RECEIVER
        );
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let call_ptr := add(0x20, call_data)
            let call_size := mload(call_data)
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
                } else {
                    return true;
                }
            }
        }
        return
            ERC1155TokenReceiver(to).onERC1155Received(
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
        bytes4 retval = ERC1155TokenReceiver(to).onERC1155BatchReceived(
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
        return (ERC721TokenReceiver(to).onERC721Received(
                operator,
                from,
                id,
                data
            ) ==
            ERC721_RECEIVED);
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

    function _burnERC721(address operator, address from, uint256 id)
        internal
    {
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
    function burnFrom(address from, uint256 id, uint256 amount) external {
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

    function _burn(address from, uint256 id, uint256 amount) internal {
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
    ) external returns(uint256) {
        require(hash != 0, "hash is zero");
        require(
            _bouncers[msg.sender],
            "only bouncer allowed to mint via update"
        );
        require(to != address(0), "destination is zero address");
        require(from != address(0), "from is zero address");

        _burnERC721(msg.sender, from, id);

        uint256 newId = generateTokenId(from, 1, packId, 0, 0);
        _mint(hash, 1, newRarity, msg.sender, to, newId, data, false);
        emit AssetUpdate(id, newId);
        return newId;
    }

    /// @notice Extracts an EIP-721 NFT from an EIP-1155 token.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return the id of the newly minted NFT.
    function extractERC721(uint256 id, address to)
        external
        returns (uint256 newId)
    {
        return _extractERC721From(msg.sender, msg.sender, id, to);
    }

    /// @notice Extracts an EIP-721 NFT from an EIP-1155 token.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return the id of the newly minted NFT.
    function extractERC721From(address sender, uint256 id, address to)
        external
        returns (uint256 newId)
    {
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

    function _extractERC721From(address operator, address sender, uint256 id, address to)
        internal
        returns (uint256 newId)
    {
        require(to != address(0), "destination is zero address");
        require(id & IS_NFT == 0, "Not an ERC1155 Token");
        uint32 tokenCollectionIndex = _nextCollectionIndex[id];
        newId = id +
            IS_NFT +
            (tokenCollectionIndex) *
            2**NFT_INDEX_OFFSET;
        _nextCollectionIndex[id] = tokenCollectionIndex + 1;
        _burnERC1155(operator, sender, id, 1);
        _mint(
            _metadataHash[id & URI_ID],
            1,
            0,
            operator,
            to,
            newId,
            "",
            true
        );
        emit Extraction(id, newId);
    }
}

pragma solidity ^0.5.2;

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
        require (msg.sender == _admin, "only admin allowed");
        _;
    }

}

pragma solidity ^0.5.2;

import "./Admin.sol";

contract MetaTransactionReceiver is Admin{

    mapping(address => bool) internal _metaTransactionContracts;
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @notice Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(
            msg.sender == _admin,
            "only admin can setup metaTransactionProcessors"
        );
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @notice check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns(bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity ^0.5.2;

import "./Admin.sol";

contract SuperOperators is Admin {

    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(
            msg.sender == _admin,
            "only admin is allowed to add super operators"
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

pragma solidity ^0.5.2;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface ERC1155 {

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id)
        external
        view
        returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

pragma solidity ^0.5.2;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param from      The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.5.2;

/**
 * @title ERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface ERC165 {
    /**
   * @notice Query if a contract implements interface `interfaceId`
   * @param interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool);
}

pragma solidity ^0.5.2;

import "./ERC20Basic.sol";

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
/* interface */
contract ERC20 is ERC20Basic {
    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender)
        public
        view
        returns (uint256);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.5.2;

/**
 * @title ERC20Basic DRAFT
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
/* interface */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.5.2;

import "./ERC165.sol";
import "./ERC721Events.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
/*interface*/
contract ERC721 is ERC165, ERC721Events {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //   function exists(uint256 tokenId) external view returns (bool exists);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(address from, address to, uint256 tokenId)
        external;
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.5.2;

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface ERC721Events {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// solhint-disable-next-line compiler-fixed
pragma solidity ^0.5.2;

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.5.2;

library AddressUtils {

    function toPayable(address _address) internal pure returns (address payable _payable) {
        return address(uint160(_address));
    }

    function isContract(address addr) internal view returns (bool) {
        // for accounts without code, i.e. `keccak256('')`:
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codehash;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

pragma solidity ^0.5.2;

import "./SafeMathWithRequire.sol";

library ObjectLib32 {
    using SafeMathWithRequire for uint256;
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
  * @dev Return the bin number and index within that bin where ID is
  * @param tokenId Object type
  * @return (Bin number, ID's index within that bin)
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
            require(objectBalance >= amount, "can't substract more than there is");
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
    function writeValueInBin(uint256 binValue, uint256 index, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        require(
            amount < 2**TYPES_BITS_SIZE,
            "Amount to write in bin is too large"
        );

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }

}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "undeflow");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "overflow");
        return c;
    }
}