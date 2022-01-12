// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC1155.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./IERC1155_EXT.sol";

contract YarlooNftHub is IERC1155_EXT, ERC1155, Ownable {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public nextID = 1;

    mapping(uint256 => address) internal _tokenMaker;
    mapping(uint256 => uint256) internal _tokenInitAmount;

    mapping(uint256 => EnumerableSet.AddressSet) internal _tokenIdToOwners;
    mapping(address => EnumerableSet.UintSet) internal _ownedTokens;
    mapping(uint256 => string) internal _tokenIdToHash;
    mapping(string => uint256) public override getTokenIdFromHash;
    mapping(uint256 => uint256) internal _tokenInitAmountHandler;
    mapping(string => bool) internal existHash;
    mapping(uint256 => string) public keytype;

    event UpgradeNFT(uint256 _tokenId, string _newHash);

    constructor() ERC1155("https://ipfs.io/ipfs/") {
        // solhint-disable-previous-line no-empty-blocks
    }

    function mint(
        address to,
        uint256 value,
        string memory _hash,
        bytes memory data,
        string memory _keytype
    ) external override onlyOwner {
        require(!existHash[_hash], "Invalid hash");
        keytype[nextID] = _keytype;
        _mint(to, nextID, value, data);
        processSetHashFromMint(_hash);
    }

    function mintBatch(
        address to,
        uint256[] memory values,
        string[] memory _hash,
        bytes memory data,
        string memory _keytype
    ) external override onlyOwner {
        require(values.length > 0, "Values not greater than 0");
        require(
            values.length == _hash.length,
            "Hash and value length doesnt match"
        );
        uint256[] memory ids = new uint256[](_hash.length);
        for (uint256 i; i < _hash.length; ++i) {
            require(!existHash[_hash[i]], "Invalid hash");
            keytype[nextID] = _keytype;
            ids[i] = nextID;
            processSetHashFromMint(_hash[i]);
        }
        _mintBatch(to, ids, values, data);
    }

    function burn(uint256 id, uint256 value) public {
        require(_ownedTokens[_msgSender()].contains(id), "Not Token Owner");
        _burn(_msgSender(), id, value);
        burnHashHandler(id, value);
    }

    function upgradeNft(uint256 tokenId, string memory newHash)
        external
        onlyOwner
        returns (bool)
    {
        _tokenIdToHash[tokenId] = newHash;
        emit UpgradeNFT(tokenId, newHash);
        return true;
    }

    function mintUpdate(
        address to,
        uint256 _tokenID,
        uint256 value,
        bytes memory data
    ) external onlyOwner {
        require(_tokenID < nextID, "Should be a Valid Token ID");
        _mint(to, _tokenID, value, data);
    }

    function burnHashHandler(uint256 id, uint256 value) internal {
        _tokenInitAmountHandler[id] = _tokenInitAmountHandler[id] - value;
        if (_tokenInitAmountHandler[id] == 0) {
            string memory oldHash = _tokenIdToHash[id];
            delete getTokenIdFromHash[oldHash];
            delete existHash[oldHash];
            delete _tokenIdToHash[id];
            delete keytype[id];
        }
    }

    function ownerOf(address owner, uint256 id)
        external
        view
        override
        returns (bool)
    {
        return _ownedTokens[owner].contains(id);
    }

    function getHashFromTokenID(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenIdToHash[tokenId];
    }

    function getKeyTypeFromTokenID(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return keytype[tokenId];
    }

    function getTokenAmount(address owner)
        external
        view
        override
        returns (uint256)
    {
        return _ownedTokens[owner].length();
    }

    function getHashBatch(uint256[] memory tokenIds)
        external
        view
        returns (string[] memory)
    {
        string[] memory tokenHash = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenHash[i] = getHashFromTokenID(tokenIds[i]);
        }
        return tokenHash;
    }

    function getOwnersFromTokenId(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {
        uint256 index = _tokenIdToOwners[tokenId].length();
        address[] memory owners = new address[](index);
        for (uint256 i; i < index; i++) {
            owners[i] = _tokenIdToOwners[tokenId].at(i);
        }
        return owners;
    }

    function getTokenMaker(uint256 tokenId) external view returns (address) {
        return _tokenMaker[tokenId];
    }

    function getTokenInitAmount(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return _tokenInitAmount[tokenId];
    }

    function getAllTokenHash(address owner)
        external
        view
        returns (string[] memory)
    {
        uint256[] memory tokenIds = this.getAllTokenIds(owner);
        string[] memory tokenHash = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenHash[i] = getHashFromTokenID(tokenIds[i]);
        }
        return tokenHash;
    }

    function getAllTokenIds(address owner)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 index = _ownedTokens[owner].length();
        uint256[] memory tokenIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokenIds[i] = _ownedTokens[owner].at(i);
        }
        return tokenIds;
    }

    function processSetHashFromMint(string memory newHash) private {
        require(bytes(newHash).length > 0, "hash_ can not be empty string");
        setHashToTokenID(nextID, newHash);
        nextID++;
    }

    function setHashToTokenID(uint256 tokenId, string memory newHash) internal {
        _tokenIdToHash[tokenId] = newHash;
        existHash[newHash] = true;
        getTokenIdFromHash[newHash] = tokenId;
    }

    function updateTokenID(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        if (from == address(0)) {
            _tokenMaker[id] = to;
            _tokenInitAmount[id] = amount;
            _tokenInitAmountHandler[id] = amount;
        }

        if (from != address(0)) {
            uint256 fromBalance = balanceOf(from, id);
            if (amount == fromBalance) {
                _ownedTokens[from].remove(id);
                _tokenIdToOwners[id].remove(from);
            }
        }

        if (to != address(0)) {
            _ownedTokens[to].add(id);
            _tokenIdToOwners[id].add(to);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        operator;
        data;
        for (uint256 i = 0; i < ids.length; i++) {
            updateTokenID(from, to, ids[i], amounts[i]);
        }
    }
}