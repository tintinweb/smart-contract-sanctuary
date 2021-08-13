/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// File: @openzeppelin/contracts/introspection/IERC165.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.2;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.2;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.2;


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

// File: @openzeppelin/contracts/utils/Strings.sol

// spd-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// File: contracts/NFTLotteryURI.sol

// spd-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.8;




/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {let i := 0} lt(i, len) {} {
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

interface ILotteryInfo {
  function prizeAddress() external view returns (address);
  function prizeId() external view returns (uint256);
  function startDate() external view returns (uint64);
  function endDate() external view returns (uint64);
  function minTicketsToSell() external view returns (uint32);
  function maxTickets() external view returns (uint32);
}

contract NFTLotteryURI {

  string[] private hexAlphabet = ["0", "1","2","3","4","5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];

  using Strings for uint256;

  function tokenURI(uint256 id) external view returns (string memory) {
    string memory name = getLotteryName(msg.sender);
    return string(
      abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(
      bytes(
      abi.encodePacked(
          '{"name":"', name, ' ticket #', id.toString(),
          '", "description":"', 'A lottery ticket for ', name,
          '", "image": "',
          'data:image/svg+xml;base64,',
          getSVG(msg.sender, id),
          '"}'
    )))));
  }

  function getLotteryName(address a) public view returns (string memory) {
    ILotteryInfo lottery = ILotteryInfo(a);
    return string(abi.encodePacked(IERC721Metadata(lottery.prizeAddress()).name(), " #", lottery.prizeId().toString()));
  }

  function getSVG(address a, uint256 id) public view returns (string memory) {
    uint256 time = block.timestamp;
    if (time > ILotteryInfo(a).endDate()) {
      time = ILotteryInfo(a).endDate();
    }
    uint256 supply = IERC721Enumerable(a).totalSupply();
    if (IERC721Enumerable(a).totalSupply() > ILotteryInfo(a).minTicketsToSell()) {
      supply = ILotteryInfo(a).minTicketsToSell();
    }
    bytes memory svg = createTicket(a, id, time, supply);
    return Base64.encode(svg);
  }

  function createTicket(address a, uint256 id, uint256 time, uint256 supply) public view returns (bytes memory) {
    return abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000"><style>.big {font: bold 3rem monospace; } .small {font: bold 1.5rem monospace}</style><rect width="900" height="400" x="50" y="50" fill="#fff" stroke-width="20" stroke="black"/>',
    createGradient(a, id),
    '<text x="80" y="110" class="big">', getLotteryName(a), '</text>',
    createSaleBlock(a, supply),
    createTimeBlock(a, time),
    '</svg>'
    );
  }

  function createSaleBlock(address a, uint256 supply) public view returns (string memory) {
    return string(
      abi.encodePacked(
    '<text x="80" y="170" class="small">Tickets sold:', IERC721Enumerable(a).totalSupply().toString(), '</text>',
    '<text x="450" y="170" class="small">Min:', uint256(ILotteryInfo(a).minTicketsToSell()).toString(), '</text>',
    '<text x="670" y="170" class="small">Max:', uint256(ILotteryInfo(a).maxTickets()).toString(), '</text>',
    '<rect width="', ((700 * supply) / ILotteryInfo(a).minTicketsToSell()).toString(), '" height="40" x="80" y="190" fill="url(#g)" />',
    '<text x="810" y="220" class="small">', (supply*100 / ILotteryInfo(a).minTicketsToSell()).toString(),'%</text>'
    ));
  }

  function createTimeBlock(address a, uint256 time) public view returns (string memory) {
    return string(
      abi.encodePacked(
    '<text x="80" y="300" class="small">Current time:', block.timestamp.toString(), '</text>',
    '<text x="500" y="300" class="small">End time:', uint256(ILotteryInfo(a).endDate()).toString(), '</text>',
    '<rect width="', ((700 * (time - ILotteryInfo(a).startDate())) / (ILotteryInfo(a).endDate() - ILotteryInfo(a).startDate())).toString(), '" height="40" x="80" y="320" fill="url(#g2)" />',
    '<text x="810" y="350" class="small">', ((time - ILotteryInfo(a).startDate())*100 / (ILotteryInfo(a).endDate() - ILotteryInfo(a).startDate())).toString(), '%</text>'
    ));
  }

  function randHex(uint256 rng) public view returns (string memory) {
    uint256 i1 = rng % 16;
    uint256 i2 = uint256(keccak256(abi.encodePacked(rng, i1))) % 16;
    uint256 i3 = uint256(keccak256(abi.encodePacked(rng, i2))) % 16;
    uint256 i4 = uint256(keccak256(abi.encodePacked(rng, i3))) % 16;
    uint256 i5 = uint256(keccak256(abi.encodePacked(rng, i4))) % 16;
    uint256 i6 = uint256(keccak256(abi.encodePacked(rng, i5))) % 16;
    return string(abi.encodePacked(
      hexAlphabet[i1],
      hexAlphabet[i2],
      hexAlphabet[i3],
      hexAlphabet[i4],
      hexAlphabet[i5],
      hexAlphabet[i6]
    ));
  }

  function createGradient(address a, uint256 id) public view returns (string memory) {
    uint256 color1 = uint256(keccak256(abi.encodePacked(a, id)));
    uint256 color2 = uint256(keccak256(abi.encodePacked(color1, a, id)));
    uint256 color3 = uint256(keccak256(abi.encodePacked(color2, a, id)));
    uint256 color4 = uint256(keccak256(abi.encodePacked(color3, a, id)));
    string memory svg = string(abi.encodePacked(
      '<defs>',
      gradientDef(randHex(color1), randHex(color2), randHex(color3), randHex(color4), "g", 4),
      gradientDef(randHex(color1*color2), randHex(color2*color3), randHex(color3*color4), randHex(color4*color1), "g2", 3),
      '</defs>'
    ));
    return svg;
  }

  function gradientDef(string memory color1, string memory color2, string memory color3, string memory color4, string memory gradientId, uint256 time) public view returns (string memory) {
    return string(abi.encodePacked(
      '<linearGradient id="',gradientId,'"><stop offset="0%" stop-color="#',
      color1,
      '"><animate attributeName="stop-color" values="#',color1,';#',color2,';#',color1,'" dur="', time.toString(), 's" repeatCount="indefinite"/></stop><stop offset="100%" stop-color="#',
      color3,
      '"><animate attributeName="stop-color" values="#',color3,';#',color4,';#',color3,'" dur="', time.toString(), 's" repeatCount="indefinite"/></stop></linearGradient>'
    ));
  }
}