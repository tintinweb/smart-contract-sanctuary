pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./UriProviderInterface.sol";
import "./BlockchainCutiesERC1155Interface.sol";
import "./Operators.sol";

contract Proxy721_1155 is ERC721, Operators {

    BlockchainCutiesERC1155Interface public erc1155;

    UriProviderInterface public uriProvider;
    uint256 public nftType;
    string public nftName;
    string public nftSymbol;
    bool public canSetup = true;

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant public TYPE_NF_BIT = 1 << 255;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    modifier canBeStoredIn128Bits(uint256 _value) {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ERC721: id overflow");
        _;
    }

    function setup(
        BlockchainCutiesERC1155Interface _erc1155,
        UriProviderInterface _uriProvider,
        uint256 _nftType,
        string calldata _nftSymbol,
        string calldata _nftName
    ) external onlyOwner canBeStoredIn128Bits(_nftType) {
        require(canSetup, "Contract already initialized");
        erc1155 = _erc1155;
        uriProvider = _uriProvider;
        nftType = (_nftType << 128) | TYPE_NF_BIT;
        nftSymbol = _nftSymbol;
        nftName = _nftName;
    }

    function disableSetup() external onlyOwner {
        canSetup = false;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory) {
        return nftName;
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory) {
        return nftSymbol;
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256) {
        return _balanceOf(_owner);
    }

    function _balanceOf(address _owner) internal view returns (uint256) {
        require(_owner != address(0x0), "ERC721: zero address cannot be owner");
        return erc1155.balanceOf(_owner, nftType);
    }

    /// @notice Find the owner of an NFT
    /// @param _tokenIndex The index for an NFT with type nftType
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenIndex) external view returns (address) {
        return _ownerOf(_tokenIndex);
    }

    function _ownerOf(uint256 _tokenIndex) internal view returns (address) {
        return erc1155.ownerOf(_indexToId(_tokenIndex));
    }

    function _indexToId(uint256 _tokenIndex) internal view canBeStoredIn128Bits(_tokenIndex) returns (uint256) {
        return nftType | _tokenIndex;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenIndex) external view canBeStoredIn128Bits(_tokenIndex) returns (string memory) {
        return uriProvider.tokenURI(_tokenIndex);
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view returns (uint256) {
        return erc1155.totalSupplyNonFungible(nftType);
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < _totalSupply(), "ERC721: global index out of bounds");
        return _index - 1;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenIndex) {
        require(_index < _balanceOf(_owner), "ERC721: owner index out of bounds");
        return _ownedTokens[_owner][_index];
    }

    /// @notice Transfers a Token to another address. When transferring to a smart
    ///  contract, ensure that it is aware of ERC-721,
    /// otherwise the Token may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenIndex The ID of the Token to transfer.
    function transfer(address _to, uint256 _tokenIndex) external {
        _transfer(msg.sender, _to, _tokenIndex, "");
    }

    function _transfer(address _from, address _to, uint256 _tokenIndex, bytes memory data) internal {
        erc1155.proxyTransfer721(_from, _to, _indexToId(_tokenIndex), data);
    }

    function onTransfer(address _from, address _to, uint256 _nftIndex) external {
        require(msg.sender == address(erc1155), "ERC721: access denied");

        if (_from != address(0) && _from != _to) {
            _removeTokenFromOwnerEnumeration(_from, _nftIndex);
        }

        if (_to != _from) {
            _addTokenToOwnerEnumeration(_to, _nftIndex);
        }

        emit Transfer(_from, _to, _nftIndex);
    }

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Metadata =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('tokenURI(uint256)'));

    bytes4 internal constant INTERFACE_SIGNATURE_ERC721Enumerable =
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('tokenByIndex(uint256)')) ^
        bytes4(keccak256('tokenOfOwnerByIndex(address, uint256)'));

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
        interfaceID == 0x6466353c ||
        interfaceID == 0x80ac58cd || // ERC721
        interfaceID == INTERFACE_SIGNATURE_ERC721Metadata ||
        interfaceID == INTERFACE_SIGNATURE_ERC721Enumerable ||
        interfaceID == bytes4(keccak256('supportsInterface(bytes4)'));
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {
        _transfer(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _transfer(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transfer(_from, _to, _tokenId, "");
    }

    function approve(address, uint256) external {
        revert("ERC721: direct approve is not allowed");
    }

    function setApprovalForAll(address, bool) external {
        revert(("ERC721: direct approve for all is not allowed"));
    }

    function getApproved(uint256) external view returns (address) {
        return address(0x0);
    }

    function isApprovedForAll(address, address) external view returns (bool) {
        return false;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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

        uint256 lastTokenIndex = _balanceOf(from) - 1;
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
}