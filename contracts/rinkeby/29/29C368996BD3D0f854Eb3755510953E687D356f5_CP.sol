// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Render.sol';
import './Token.sol';

//

/////////////////////////////////////////////////////////////////////////////////
//                                              ,--,                           //
//                                           ,---.'|                           //
//    ,----..     ,---,,-.----.     ,----..  |   | :       ,---,.  .--.--.     //
//   /   /   \ ,`--.' |\    /  \   /   /   \ :   : |     ,'  .' | /  /    '.   //
//  |   :     :|   :  :;   :    \ |   :     :|   ' :   ,---.'   ||  :  /`. /   //
//  .   |  ;. /:   |  '|   | .\ : .   |  ;. /;   ; '   |   |   .';  |  |--`    //
//  .   ; /--` |   :  |.   : |: | .   ; /--` '   | |__ :   :  |-,|  :  ;_      //
//  ;   | ;    '   '  ;|   |  \ : ;   | ;    |   | :.'|:   |  ;/| \  \    `.   //
//  |   : |    |   |  ||   : .  / |   : |    '   :    ;|   :   .'  `----.   \  //
//  .   | '___ '   :  ;;   | |  \ .   | '___ |   |  ./ |   |  |-,  __ \  \  |  //
//  '   ; : .'||   |  '|   | ;\  \'   ; : .'|;   : ;   '   :  ;/| /  /`--'  /  //
//  '   | '/  :'   :  |:   ' | \.''   | '/  :|   ,/    |   |    \'--'.     /   //
//  |   :    / ;   |.' :   : :-'  |   :    / '---'     |   :   .'  `--'---'    //
//   \   \ .'  '---'   |   |.'     \   \ .'            |   | ,'                //
//    `---`            `---'        `---`              `----'                  //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////

//

/// @title The Circles Project
/// @author loset.eth
/// @notice an SVG Project on Ethereum
contract CP is ERC721Enumerable, Ownable {
    // token data

    mapping(uint256 => bytes32) public dataByTokenId;

    // contract-level parameters

    uint256 public contractImage;
    uint256 public sellerFeeBasisPoints;
    address public feeRecipient;

    // Render and Token contracts

    Render immutable render;
    // Token immutable token;

    /// @notice only permits the owner of the token to call the method
    modifier onlyHolder(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    constructor(address _render) ERC721('The Circles Project', 'TCP') {
        render = Render(_render);
        // token = new Token(address(this), owner());
        feeRecipient = owner();
        // set sellerFeeBasisPoints = 500 or 5%
        // owner can change
        sellerFeeBasisPoints = 500;
    }

    /// @notice fetch the token metadata
    /// @param _tokenId, the tokenId whose metadata to return
    /// @return string, the corresponding data of the token
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_tokenId < totalSupply());
        return render.tokenURI(_tokenId, dataByTokenId[_tokenId]);
    }

    /// @notice fetch the contract-level metadata
    /// @return string, the base64-encoded metadata of the contract
    function contractURI() public view returns (string memory) {
        return
            render.contractURI(
                'The Circles Project',
                'Generative On-Chain Circles. \\nPurchase CPT on Uniswap.',
                address(this), // _cpAddress
                address(0), // _cptAddress
                'https://ipfs.io/ipfs/QmTnTDtHbWGsBWGCNodsRpXAf3NRv6wMWADvRAkVJBWWFv?filename=main.svg', // pinned header image
                'https://loset.info',
                sellerFeeBasisPoints,
                feeRecipient
            );
    }

    /// @notice set contract-level parameters
    /// @param _sellerFeeBasisPoints seller fee basis points = %*100
    /// @param _feeRecipient the fee recipient
    function setContractLevelParameters(
        uint256 _sellerFeeBasisPoints,
        address _feeRecipient
    ) public onlyOwner {
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
        feeRecipient = _feeRecipient;
    }

    /// @notice mint a new token
    function mint() public onlyOwner {
        // costs 1 CPT
        // does not require approve
        // token.spend(msg.sender);

        bytes32 random = keccak256(
            abi.encode(msg.sender, block.timestamp, totalSupply())
        );

        // derive randomized token data
        bytes32 data = deriveData(random);

        // store the data
        dataByTokenId[totalSupply()] = data;

        // mint the token
        _safeMint(msg.sender, totalSupply());
    }

    /// @notice derive token data from a random seed
    /// @dev generates in from 1 to 6 circles
    /// @dev with fill color and radius for each
    /// @dev plus a background color
    /// @dev schema is [bg_color, number_of_circles, circle_1_radius, circle_1_fill, ..., circle_n_radius, circle_n_fill]
    /// @dev with n \in [1,6]
    /// @param _random, the _random seed
    function deriveData(bytes32 _random)
        internal
        pure
        returns (bytes32 result)
    {
        assembly {
            // load free pointer
            result := mload(0x40)
            // increment free pointer
            mstore(0x40, add(result, 32))
            // get pointer for writing
            let dataPtr := result
            // background color as an index from 0 to 146
            mstore8(dataPtr, mod(_random, 147))
            // skip length field
            dataPtr := add(dataPtr, 1)
            // number of circles
            let n := 0
            // 5 rounds of circles
            // radii from 1 to 1 + 5*25 = 126
            for {
                let r := 1
            } lt(r, 127) {
                r := add(r, 25)
            } {
                // skip circles 1/2 of the time
                switch mod(_random, 2)
                case 0 {
                    // increment n
                    n := add(n, 1)
                    // radius
                    dataPtr := add(dataPtr, 1)
                    _random := shr(8, _random)
                    // add _random % 20 to radius
                    mstore8(dataPtr, add(r, mod(_random, 20)))

                    // color
                    dataPtr := add(dataPtr, 1)
                    _random := shr(8, _random)
                    // take random % 147 for color
                    mstore8(dataPtr, mod(_random, 147))
                }
                case 1 {
                    // advance random 2 bytes
                    _random := shr(16, _random)
                }
            }
            // if we havent added any circles by the sixth
            if or(eq(n, 0), mod(_random, 2)) {
                n := add(n, 1)
                dataPtr := add(dataPtr, 1)
                _random := shr(8, _random)
                // add _random % 20 to final radius = 1 + 6*25 = 151
                mstore8(dataPtr, add(151, mod(_random, 20)))

                // color
                dataPtr := add(dataPtr, 1)
                _random := shr(8, _random)
                // take random % 147 for color
                mstore8(dataPtr, mod(_random, 147))
            }
            // store number of circles in second byte
            mstore8(add(result, 1), n)
            // load the result
            result := mload(result)
        }
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './OpenSVG.sol';
import './Libraries/Filter.sol';

/// @title Render
/// @author loset.eth
/// @notice Utility functions for rendering The Circles Project SVG's and metadata
contract Render {
    OpenSVG immutable openSVG;

    constructor(address _openSVG) {
        openSVG = OpenSVG(_openSVG);
    }

    /// @notice get the token metadata
    /// @param _tokenId, the tokenId whose metadata to return
    /// @param _data, the corresponding data of the token
    function tokenURI(uint256 _tokenId, bytes32 _data)
        public
        view
        returns (string memory)
    {
        return
            openSVG.encode(
                parseTokenName('CirclesProject', _tokenId, 3), // name
                parseTokenDescription('The Circles Project', _tokenId, 3), // description
                getAttributes(_data), // metadata attributes
                getSvg(_data) // svg data
            );
    }

    /// @notice get the contract-level metadata
    function contractURI(
        string memory _name,
        string memory _description,
        address _cpAddress,
        address _cptAddress,
        string memory _headerImage,
        string memory _externalLink,
        uint256 _sellerFeeBasisPoints,
        address _owner
    ) external view returns (string memory) {
        return
            openSVG.encodeContractLevel(
                _name, // name
                parseContractDescription(_description, _cpAddress, _cptAddress), // description
                _headerImage, // contract-level image uri
                _externalLink, // external link
                _sellerFeeBasisPoints, // seller fee basis points
                _owner // fee recipient
            );
    }

    /// @notice parses the name of the token
    function parseTokenName(
        string memory _name,
        uint256 _tokenId,
        uint8 _digits
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _name,
                    openSVG.tokenIdToString(_tokenId, _digits)
                )
            );
    }

    function parseContractDescription(
        string memory _description,
        address _cpAddress,
        address _cptAddress
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _description,
                    'Contract address: ',
                    openSVG.addressToString(_cpAddress),
                    ' CirclesProjectToken address: ',
                    openSVG.addressToString(_cptAddress),
                    ' ',
                    'Edition out of 1000'
                )
            );
    }

    /// @notice parses the description of the token
    function parseTokenDescription(
        string memory _name,
        uint256 _tokenId,
        uint8 _digits
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _name,
                    ' ',
                    openSVG.tokenIdToString(_tokenId, _digits),
                    '/999'
                )
            );
    }

    /// @notice fetch the base64 svg data corresponding to a token's data
    /// @param _data, the data of the token
    function getSvg(bytes32 _data) internal view returns (string memory) {
        return openSVG.svg(getSvgElements(_data), ['350', '350']);
    }

    /// @notice get stringified array of metadata attributes/traits
    /// @dev ex: [{ "trait_type": "traitTypeName", "value": "traitValue"}]
    /// @param _data, bytes32 token data
    /// @return string, the stringified array of trait_types and values
    function getAttributes(bytes32 _data)
        internal
        view
        returns (string memory)
    {
        // the string values of the attributes
        // up to 6 circles each with radius and fill
        // plus the background color in position 12
        bytes memory attributes;
        // number of circles
        uint8 n = uint8(_data[1]);
        for (uint8 i = 0; i < n; i += 1) {
            attributes = abi.encodePacked(
                attributes,
                openSVG.traitNumber(
                    circleTraitType(i, 'radius'),
                    parseRadius(_data[2 * i + 2])
                ),
                ',',
                openSVG.trait(
                    circleTraitType(i, 'fill'),
                    parseColor(_data[2 * i + 3])
                ),
                ','
            );
        }
        // append background color, append number of circles, close array
        // watch for commas
        attributes = abi.encodePacked(
            '[',
            openSVG.traitNumber('number_of_circles', openSVG.uint8toString(n)),
            ',',
            attributes,
            openSVG.trait('background_color', parseColor(_data[0])),
            ']'
        );

        return string(attributes);
    }

    /// @notice get the children of the top-level <svg> element as a string
    /// @param _data, bytes32 token data
    /// @return string, string of svg elements
    function getSvgElements(bytes32 _data)
        internal
        view
        returns (string memory)
    {
        bytes memory result;
        // number of circles
        uint8 n = uint8(_data[1]);
        // circles
        for (uint8 i = 0; i < n; i += 1) {
            string[6] memory circleAttributes = [
                '175', // cx
                '175', // cy
                parseRadius(_data[2 * i + 2]), // r
                '', // stroke
                '', // stroke-width
                parseColor(_data[2 * i + 3]) // fill-color
            ];
            result = abi.encodePacked(Svg.circle(circleAttributes), result);
        }

        // background rectangle
        string[10] memory rectAttributes = [
            '',
            '',
            '5', // rx
            '5', // ry
            '100%', // width
            '100%', // height
            '',
            '',
            parseColor(_data[0]), // background-color
            ''
        ];
        result = abi.encodePacked(
            Filter.getFilter(),
            Svg.rect(rectAttributes),
            result
        );
        return string(result);
    }

    // UTIL

    /// @notice converts bytes1 radius data to string
    function parseRadius(bytes1 _data) internal view returns (string memory) {
        return openSVG.bytes1toString(_data);
    }

    /// @notice converts a bytes1 color data to string
    function parseColor(bytes1 _data) internal view returns (string memory) {
        return openSVG.getColor(uint8(_data));
    }

    /// @notice converts an index and string type to circle trait_type name
    /// @dev ex: 'circle_5_width'
    function circleTraitType(uint256 _index, bytes memory _type)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'circle_',
                    openSVG.uint256toString(_index),
                    '_',
                    _type
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @title The Circles Project Token
/// @notice redeemable 1-1 for The Circles Project NFT
contract Token is ERC20 {
    address immutable cp;
    uint256 constant maxSupply = 999 ether;
    uint256 constant costToMint = 1 ether;

    /// @notice only permits CP contract to call method
    modifier onlyCP() {
        require(msg.sender == cp);
        _;
    }

    constructor(address _cp, address _recipient)
        ERC20('The Circles Project Token', 'CPT')
    {
        cp = _cp;
        _mint(_recipient, maxSupply);
    }

    /// @notice spend 1 CPT to mint token
    function spend(address _sender) external onlyCP {
        _burn(_sender, costToMint);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './Libraries/Color.sol';
import './Libraries/Svg.sol';
import './Libraries/Util.sol';
import './Libraries/Metadata.sol';

/// @title OpenSVG
/// @author loset.eth
/// @notice Composable functions for creation of on-chain SVG's and corresponding metadata
contract OpenSVG {
    // METADATA
    function encode(
        string memory _name,
        string memory _description,
        string memory _attributes,
        string memory _svg
    ) external pure returns (string memory) {
        return Metadata.encode(_name, _description, _attributes, _svg);
    }

    function encodeContractLevel(
        string memory _name,
        string memory _description,
        string memory _image,
        string memory _externalLink,
        uint256 _sellerFeeBasisPoints,
        address _feeRecipient
    ) external pure returns (string memory) {
        return
            Metadata.encodeContractLevel(
                _name,
                _description,
                _image,
                _externalLink,
                _sellerFeeBasisPoints,
                _feeRecipient
            );
    }

    function trait(string memory _type, string memory _value)
        external
        pure
        returns (bytes memory)
    {
        return Metadata.trait(_type, _value);
    }

    function traitNumber(string memory _type, string memory _value)
        external
        pure
        returns (bytes memory)
    {
        return Metadata.traitNumber(_type, _value);
    }

    // COLOR
    function getColor(uint256 _index) external pure returns (string memory) {
        return Color.getColor(_index);
    }

    // SVG
    function svg(string memory _elements, string[2] memory _attributes)
        external
        pure
        returns (string memory)
    {
        return Svg.svg(_elements, _attributes);
    }

    //TEXT
    function text(string[4] memory _attributes, string memory _contents)
        external
        pure
        returns (string memory)
    {
        return Svg.text(_attributes, _contents);
    }

    //RECT
    function rect(string[10] memory _attributes)
        external
        pure
        returns (string memory)
    {
        return Svg.rect(_attributes);
    }

    // CIRCLE

    function circle(string[6] memory _attributes)
        external
        pure
        returns (string memory)
    {
        return Svg.circle(_attributes);
    }

    // UTIL

    function tokenIdToString(uint256 _tokenId, uint8 _digits)
        external
        pure
        returns (string memory)
    {
        return Util.tokenIdToString(_tokenId, _digits);
    }

    function addressToString(address _address)
        external
        pure
        returns (string memory)
    {
        return Util.addressToString(_address);
    }

    function uint256toString(uint256 _value)
        external
        pure
        returns (string memory)
    {
        return Util.uint256toString(_value);
    }

    function uint8toString(uint8 _value) external pure returns (string memory) {
        return Util.uint8toString(_value);
    }

    function bytes1toString(bytes1 _value)
        external
        pure
        returns (string memory)
    {
        return Util.bytes1toString(_value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Filter {
    function getFilter() internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<style>',
                'circle {',
                'filter: url(#shadows);',
                '}',
                '</style>',
                '<filter id="shadows" filterUnits="userSpaceOnUse" x="0" y="0" height="350" width="350">',
                '<feFlood flood-color="black" flood-opacity=".3" />',
                '<feComposite operator="in" in2="SourceGraphic" />',
                '<feGaussianBlur stdDeviation="2" />',
                '<feOffset dx="-0" dy="0" />',
                '<feComposite operator="out" in2="SourceGraphic" result="dropShadow" />',
                '<feOffset in="SourceGraphic" dx="-10" dy="10" result="offset" />',
                '<feComposite operator="out" in="SourceGraphic" in2="offset" result="crescent" />',
                '<feFlood flood-color="white" flood-opacity=".5" />',
                '<feComposite operator="in" in2="crescent" />',
                '<feGaussianBlur stdDeviation="40" />',
                '<feGaussianBlur stdDeviation="40" />',
                '<feComposite operator="in" in2="SourceGraphic" result="broadWhite" />',
                '<feOffset in="SourceGraphic" dx="-1" dy="1" result="offset" />',
                '<feComposite operator="out" in="SourceGraphic" in2="offset" result="crescent" />',
                '<feFlood flood-color="white" flood-opacity=".5" />',
                '<feComposite operator="in" in2="crescent" />',
                '<feGaussianBlur stdDeviation="3" />',
                '<feComposite operator="in" in2="SourceGraphic" />',
                '<feComposite operator="in" in2="SourceGraphic" result="narrowWhite" />',
                '<feOffset in="SourceGraphic" dx="4" dy="-4" result="offset" />',
                '<feComposite operator="out" in="SourceGraphic" in2="offset" result="crescent" />',
                '<feFlood flood-color="black" flood-opacity=".3" />',
                '<feComposite operator="in" in2="crescent" />',
                '<feGaussianBlur stdDeviation="10" />',
                '<feComposite operator="in" in2="SourceGraphic" result="narrowBlack" />',
                '<feOffset in="SourceGraphic" dx="40" dy="-40" result="offset" />',
                '<feComposite operator="out" in="SourceGraphic" in2="offset" result="crescent" />',
                '<feFlood flood-color="black" flood-opacity=".1" />',
                '<feComposite operator="in" in2="crescent" />',
                '<feGaussianBlur stdDeviation="100" />',
                '<feGaussianBlur stdDeviation="100" />',
                '<feComposite operator="in" in2="SourceGraphic" result="broadBlack" />',
                '<feMerge>',
                '<feMergeNode in="dropShadow" />',
                '<feMergeNode in="SourceGraphic" />',
                '<feMergeNode in="narrowWhite" />',
                '<feMergeNode in="broadWhite" />',
                '<feMergeNode in="narrowBlack" />',
                '<feMergeNode in="broadBlack" />',
                '</feMerge>',
                '</filter>'
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Color {
    function getColor(uint256 _index) internal pure returns (string memory) {
        string[147] memory colors = [
            'palegoldenrod',
            'mintcream',
            'darkmagenta',
            'bisque',
            'powderblue',
            'tan',
            'gold',
            'lightcoral',
            'greenyellow',
            'mediumblue',
            'seagreen',
            'mediumvioletred',
            'royalblue',
            'snow',
            'papayawhip',
            'dimgray',
            'darkslategrey',
            'darkgray',
            'darkcyan',
            'seashell',
            'burlywood',
            'lavender',
            'olive',
            'darkgoldenrod',
            'darkgrey',
            'navy',
            'darksalmon',
            'forestgreen',
            'yellow',
            'lightseagreen',
            'coral',
            'darkgreen',
            'navajowhite',
            'linen',
            'darkorchid',
            'brown',
            'ghostwhite',
            'sandybrown',
            'goldenrod',
            'floralwhite',
            'green',
            'lightskyblue',
            'lightsalmon',
            'lightgoldenrodyellow',
            'darkslateblue',
            'mediumspringgreen',
            'lightgrey',
            'skyblue',
            'lightgreen',
            'azure',
            'deeppink',
            'purple',
            'aqua',
            'pink',
            'paleturquoise',
            'limegreen',
            'lemonchiffon',
            'black',
            'palevioletred',
            'mistyrose',
            'crimson',
            'steelblue',
            'lawngreen',
            'grey',
            'cadetblue',
            'maroon',
            'turquoise',
            'thistle',
            'darkkhaki',
            'wheat',
            'mediumaquamarine',
            'darkslategray',
            'lime',
            'darkblue',
            'slateblue',
            'chartreuse',
            'slategrey',
            'violet',
            'blue',
            'antiquewhite',
            'palegreen',
            'indianred',
            'orangered',
            'tomato',
            'chocolate',
            'mediumpurple',
            'ivory',
            'lavenderblush',
            'deepskyblue',
            'salmon',
            'lightgray',
            'lightblue',
            'darkseagreen',
            'khaki',
            'mediumorchid',
            'fuchsia',
            'mediumslateblue',
            'gray',
            'silver',
            'whitesmoke',
            'red',
            'peru',
            'lightcyan',
            'lightslategray',
            'beige',
            'plum',
            'slategray',
            'cornsilk',
            'gainsboro',
            'darkolivegreen',
            'lightslategrey',
            'honeydew',
            'darkviolet',
            'yellowgreen',
            'oldlace',
            'cornflowerblue',
            'mediumseagreen',
            'saddlebrown',
            'darkorange',
            'darkturquoise',
            'blanchedalmond',
            'dodgerblue',
            'cyan',
            'darkred',
            'rosybrown',
            'lightyellow',
            'olivedrab',
            'springgreen',
            'moccasin',
            'lightsteelblue',
            'midnightblue',
            'sienna',
            'blueviolet',
            'aliceblue',
            'teal',
            'dimgrey',
            'aquamarine',
            'white',
            'mediumturquoise',
            'orange',
            'peachpuff',
            'lightpink',
            'magenta',
            'indigo',
            'hotpink',
            'firebrick',
            'orchid'
        ];
        return colors[_index % colors.length];
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Svg {
    // SVG

    function svg(string memory _elements, string[2] memory _attributes)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg ',
                    'version="1.1" ',
                    'xmlns="http://www.w3.org/2000/svg" ',
                    'preserveAspectRatio="xMinYMin meet" ',
                    svgViewbox(_attributes),
                    'color-interpolation-filters="sRGB"'
                    '>',
                    _elements,
                    '</svg>'
                )
            );
    }

    function svgViewbox(string[2] memory _attributes)
        internal
        pure
        returns (bytes memory)
    {
        // attributes = [width, height]
        bytes memory result = abi.encodePacked(
            'viewBox="0 0 ',
            _attributes[0],
            ' ',
            _attributes[1],
            '" '
        );

        return result;
    }

    // TEXT

    function text(string[4] memory _attributes, string memory _contents)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<text ',
                    textAttributes(_attributes),
                    '>',
                    _contents,
                    '</text>'
                )
            );
    }

    function textAttributes(string[4] memory _values)
        internal
        pure
        returns (string memory)
    {
        string[4] memory attributeNames = ['x', 'y', 'class', 'style'];

        bytes memory result;
        for (uint256 i = 0; i < attributeNames.length; i++) {
            // skip if null
            if (bytes(_values[i]).length > 0)
                result = appendSvgAttribute(
                    result,
                    attributeNames[i],
                    _values[i]
                );
        }
        return string(result);
    }

    // RECT

    function rect(string[10] memory _attributes)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked('<rect ', rectAttributes(_attributes), '/>')
            );
    }

    function rectAttributes(string[10] memory _values)
        internal
        pure
        returns (string memory)
    {
        string[10] memory attributeNames = [
            'x',
            'y',
            'rx',
            'ry',
            'width',
            'height',
            'stroke',
            'stroke-width',
            'fill',
            'style'
        ];

        bytes memory result;
        for (uint256 i = 0; i < _values.length; i++) {
            if (bytes(_values[i]).length > 0)
                result = appendSvgAttribute(
                    result,
                    attributeNames[i],
                    _values[i]
                );
        }
        return string(result);
    }

    // CIRCLE

    function circle(string[6] memory _attributes)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<circle ',
                    circleAttributes(_attributes),
                    '/>'
                )
            );
    }

    function circleAttributes(string[6] memory _values)
        internal
        pure
        returns (string memory)
    {
        string[6] memory attributeNames = [
            'cx',
            'cy',
            'r',
            'stroke',
            'stroke-width',
            'fill'
        ];

        bytes memory result;
        for (uint256 i = 0; i < 6; i++) {
            if (bytes(_values[i]).length > 0)
                result = appendSvgAttribute(
                    result,
                    attributeNames[i],
                    _values[i]
                );
        }
        return string(result);
    }

    // UTIL

    function appendSvgAttribute(
        bytes memory _attributes,
        string memory _name,
        string memory _value
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_attributes, _name, '="', _value, '" ');
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Svg Project Util Library
/// @notice Utility functions for Svg Project
library Util {
    /// @notice converts a bytes1 considered as a uint to string
    /// @param _value, bytes1, considered as uint
    /// @return _result, the resulting string
    function bytes1toString(bytes1 _value)
        internal
        pure
        returns (string memory)
    {
        return uint256toString(uint256(uint8(_value)));
    }

    /// @notice converts a uint8 to string
    /// @param _value, uint8, the value to convert
    /// @return _result, the resulting string
    function uint8toString(uint8 _value) internal pure returns (string memory) {
        return uint256toString(uint256(_value));
    }

    /// @notice converts a tokenId to string and pads to _digits digits
    /// @dev tokenId must be less than 10**_digits
    /// @param _tokenId, uint256, the tokenId
    /// @param _digits, uint8, the number of digits to pad to
    /// @return result the resulting string
    function tokenIdToString(uint256 _tokenId, uint8 _digits)
        internal
        pure
        returns (string memory result)
    {
        uint256 max = 10**_digits;
        require(_tokenId < max, 'tokenId not less than 10**_digits');
        // add leading zeroes
        result = uint256toString(_tokenId + max);
        assembly {
            // cut off one character
            result := add(result, 1)
            // store new length = _digits
            mstore(result, _digits)
        }
    }

    /// @notice converts a uint256 to string
    /// @param _value, uint256, the value to convert
    /// @return result the resulting string
    function uint256toString(uint256 _value)
        internal
        pure
        returns (string memory result)
    {
        if (_value == 0) return '0';

        assembly {
            // largest uint = 2^256-1 has 78 digits
            // reserve 110 = 78 + 32 bytes of data in memory
            // (first 32 are for string length)

            // get 110 bytes of free memory
            result := add(mload(0x40), 110)
            mstore(0x40, result)

            // keep track of digits
            let digits := 0

            for {

            } gt(_value, 0) {

            } {
                // increment digits
                digits := add(digits, 1)
                // go back one byte
                result := sub(result, 1)
                // compute ascii char
                let c := add(mod(_value, 10), 48)
                // store byte
                mstore8(result, c)
                // advance to next digit
                _value := div(_value, 10)
            }
            // go back 32 bytes
            result := sub(result, 32)
            // store the length
            mstore(result, digits)
        }
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory result)
    {
        string memory table = '0123456789abcdef';

        assembly {
            // get 42 + 32 = 74 bytes of free memory
            result := mload(0x40)
            mstore(0x40, add(result, 74))
            // write length
            mstore(result, 42)
            // move to first byte
            let resultPtr := add(result, 32)

            // will be using least significant byte of each mload
            let tablePtr := add(table, 1)

            // write two bytes '0x' at most significant digits
            mstore8(resultPtr, 48)
            resultPtr := add(resultPtr, 1)
            mstore8(resultPtr, 120)
            resultPtr := add(resultPtr, 1)

            // 160 bits = 20 bytes = 40 chars
            // start at 12 bc its encoded as 32 bytes
            for {
                let i := 12
            } lt(i, 32) {
                i := add(i, 1)
            } {
                let c := byte(i, _address)
                // first 4 bits
                let c1 := shr(4, c)
                // second 4 bits
                let c2 := and(0x0f, c)

                mstore8(resultPtr, mload(add(tablePtr, c1)))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, c2)))
                resultPtr := add(resultPtr, 1)
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import './Base64.sol';
import './Util.sol';

library Metadata {
    function encode(
        string memory _name,
        string memory _description,
        string memory _attributes,
        string memory _svg
    ) internal pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{',
            keyValue('name', _name),
            ',',
            keyValue('description', _description),
            ',',
            keyValueNoQuotes('attributes', _attributes),
            ',',
            keyValue('image', encodeSvg(_svg)),
            '}'
        );

        return encodeJson(metadata);
    }

    function encodeContractLevel(
        string memory _name,
        string memory _description,
        string memory _image,
        string memory _externalLink,
        uint256 _seller_fee_basis_points,
        address _fee_recipient
    ) internal pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{',
            keyValue('name', _name),
            ',',
            keyValue('description', _description),
            ',',
            keyValue('image', _image),
            ',',
            keyValue('external_link', _externalLink),
            ',',
            keyValueNoQuotes(
                'seller_fee_basis_points',
                Util.uint256toString(_seller_fee_basis_points)
            ),
            ',',
            keyValue('fee_recipient', Util.addressToString(_fee_recipient)),
            '}'
        );

        return encodeJson(metadata);
    }

    function encodeJson(bytes memory _json)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(_json)
                )
            );
    }

    function encodeSvg(string memory _svg)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'data:image/svg+xml;base64,',
                    Base64.encode(bytes(_svg))
                )
            );
    }

    function trait(string memory _traitType, string memory _value)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{',
                keyValue('trait_type', _traitType),
                ',',
                keyValue('value', _value),
                '}'
            );
    }

    function traitNumber(string memory _traitType, string memory _value)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '{',
                keyValue('trait_type', _traitType),
                ',',
                keyValueNoQuotes('value', _value),
                ','
                '"display_type": "number"',
                '}'
            );
    }

    function keyValue(string memory _key, string memory _value)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked('"', _key, '":"', _value, '"');
    }

    function keyValueNoQuotes(string memory _key, string memory _value)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked('"', _key, '":', _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}