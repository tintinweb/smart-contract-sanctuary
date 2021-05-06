pragma solidity =0.6.6;
// pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Enumerable.sol";

contract NFT is Ownable, ERC1155, ERC1155Enumerable {
    string public name;
    string public symbol;

    mapping(uint256 => bool) public mintedMap;

    /**
     * Multiple NFTs may share a URI so this allows a many to one map without
     * needing to store the URI multiple times. The `0` uriCounter is reserved
     * for the empty URI (which falls back to the ERC1155 default
     * implementation).
     */
    uint256 uriCounter = 1;
    mapping(uint256 => uint256) public tokentoUriId;
    mapping(uint256 => string) public uriIdToString;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public Ownable() ERC1155(_uri) {
        updateDetails(_name, _symbol);
    }

    /* ONLY OWNER FUNCTIONS ***************************************************/

    function updateDetails(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
    }

    /**
     * [owner] Mint new tokens. Once minted, no more of that token can be
     * minted.
     */
    function mint(
        uint256[] memory _ids,
        uint256[] memory _amounts,
        string memory _uri
    ) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];
            require(!mintedMap[id], "TOKEN_ID_ALREADY_EXISTS");

            mintedMap[id] = true;

            _mintEnumerable(_msgSender(), id, amount, "");
        }

        // Update URI for the token IDs.
        if (bytes(_uri).length != 0) {
            uriIdToString[uriCounter] = _uri;

            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 id = _ids[i];
                tokentoUriId[id] = uriCounter;
                emit URI(_uri, id);
            }

            uriCounter += 1;
        }
    }

    /** [owner] Update the URI of all tokens. */
    function updateURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    /** [owner] Update the URI of a token. Set to "" to clear. */
    function updateTokenURI(uint256 _id, string memory _uri) public onlyOwner {
        if (bytes(_uri).length != 0) {
            uriIdToString[uriCounter] = _uri;

            tokentoUriId[_id] = uriCounter;
            uriCounter += 1;
        } else {
            tokentoUriId[_id] = 0;
        }

        emit URI(_uri, _id);
    }

    /* VIEW ONLY FUNCTIONS ****************************************************/

    /**
     * Override the uri to return the value in the uriMap, falling back to the
     * URI pattern.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        // return string(abi.encodePacked(_uri, _id.toString(), ".json"));

        string memory lookup = uriIdToString[tokentoUriId[_id]];
        if (bytes(lookup).length != 0) {
            return lookup;
        }

        return ERC1155.uri(_id);
    }
}