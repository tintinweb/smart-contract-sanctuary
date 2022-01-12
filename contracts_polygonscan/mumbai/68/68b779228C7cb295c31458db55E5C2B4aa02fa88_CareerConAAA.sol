/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// File: base64-sol/base64.sol


// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


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

// File: @rari-capital/solmate/src/utils/ReentrancyGuard.sol

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}

// File: @rari-capital/solmate/src/tokens/ERC721.sol

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/CareerConAAA.sol

/// @title CareerCon AAA (ccAAA)
/// @notice Genesis CareerCon AAA Collection
/// @author Giovanni Di Siena
/// @custom:security-contact [email protected]
contract CareerConAAA is ERC721, ReentrancyGuard {
    using Strings for uint256;

    /// @notice The current token counter value.
    uint8 public tokenIds = 0;

    /// @notice The maximum supply of tokens.
    /// @dev Must be less than type(uint8).max == 255.
    uint8 public immutable MAX_SUPPLY;

    /// @notice The price per token.
    uint256 public price;

    /// @notice The hundo multisig address.
    address public hundoMultiSig;

    /// @notice A mapping of token id to backer name.
    /// @dev For use in imageURI generation.
    mapping(uint8 => string) private _backerNames;

    /* events */
    /// @notice Emitted when the proceeds from sales are withdrawn to multisig.
    /// @param _proceeds The balance withdrawn.
    event FundsWithdrawn(uint256 _proceeds);

    /// @notice Emitted when the hundo multisig address is updated.
    /// @param _hundoMultiSig The new multisig address.
    event MultiSigUpdated(address _hundoMultiSig);

    /// @notice Emitted when the reserve price is updated.
    /// @param _price The new reserve price.
    event PriceUpdated(uint256 _price);

    /// @notice Emitted when a token is minted, reserving AAA access to CareerCon '22.
    /// @param _account The user who initiated the call to reserve.
    /// @param _tokenId The id of the minted token.
    /// @param _imageURI The base64-encoded image uri of the minted token.
    event Reserved(
        address indexed _account,
        uint256 _tokenId,
        string _imageURI
    );

    /* modifiers */
    /// @notice Requires that the calling address is the hundo multisig only.
    modifier onlyHundo() {
        require(msg.sender == hundoMultiSig, "Only hundo");

        _;
    }

    /// @notice Creates a new ERC-721 contract that accepts token data and a
    /// list of seed investors whose tokens will be held by the hundo multi-sig.
    /// @param _maxSupply The maximum supply of tokens.
    /// @param _price The price per token.
    /// @param _name The token name.
    /// @param _symbol The token symbol.
    /// @param _reservedSeedInvestors A list of reserved seed investors.
    /// @param _hundoMultiSig The hundo multisig address.
    constructor(
        uint8 _maxSupply,
        uint256 _price,
        string memory _name,
        string memory _symbol,
        string[] memory _reservedSeedInvestors,
        address _hundoMultiSig
    ) ERC721(_name, _symbol) {
        MAX_SUPPLY = _maxSupply;
        price = _price;
        hundoMultiSig = _hundoMultiSig;
        for (uint8 i = 0; i < _reservedSeedInvestors.length; i++) {
            _mintReceipt(_hundoMultiSig, _reservedSeedInvestors[i]);
        }
    }

    /// @notice The receive function, to be executed on plain Ether transfers.
    receive() external payable {}

    /// @notice Allows a user to mint, reserving AAA access to CareerCon '22.
    /// @param _backerName The name the user wishes to have displayed on their fully on-chain SVG.
    function reserve(string calldata _backerName)
        external
        payable
        nonReentrant
    {
        require(tokenIds < MAX_SUPPLY, "Sale ended");
        require(msg.value >= price, "Insufficient payment");
        _mintReceipt(msg.sender, _backerName);
    }

    /// @notice Withdraws the proceeds from sales to multisig.
    function withdrawProceeds() external {
        uint256 proceeds = address(this).balance;
        require(proceeds > 0, "No balance");
        (bool sent, ) = hundoMultiSig.call{value: proceeds}("");
        require(sent, "Withdraw failed");
        emit FundsWithdrawn(proceeds);
    }

    /* multisig */
    /// @notice Updates the hundo multisig address, callable only by the existing multisig.
    /// @param _hundoMultiSig The updated hundo multisig address.
    function updateHundoMultiSigAddress(address _hundoMultiSig)
        external
        onlyHundo
    {
        require(_hundoMultiSig != address(0), "Invalid address");
        hundoMultiSig = _hundoMultiSig;
        emit MultiSigUpdated(_hundoMultiSig);
    }

    /// @notice Updates the reserve price, callable only by the existing multisig.
    /// @param _price The updated reserve price.
    function updatePrice(uint256 _price) external onlyHundo {
        price = _price;
        emit PriceUpdated(_price);
    }

    /* public view */
    /// @notice Returns the token uri for a specific token id.
    /// @param _tokenId The token to be queried.
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        uri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "',
                            string(
                                abi.encodePacked(
                                    "CareerCon AAA #",
                                    _tokenId.toString()
                                )
                            ),
                            '", "description": "Access All Areas pass to CareerCon 2022.", ',
                            '"attributes": [{"trait_type": "Collection", "value": "Genesis"}, {"trait_type": "CareerCon", "value": "2022"}, {"trait_type": "Admission", "value": "AAA"}], ',
                            '"animation_url": "https://ipfs.io/ipfs/bafybeibs4bhu6fl6xv7etd7ze4km5x6vvlve446jzweiskomh2rfbra4ae", ',
                            '"image_data":"',
                            _formatImageURI(uint8(_tokenId)),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    /* internal */
    /// @notice Performs the minting of a token to the given account, for use internally
    /// @param _account The receiving account.
    /// @param _backerName The name to be displayed on the fully on-chain SVG.
    function _mintReceipt(address _account, string memory _backerName)
        internal
    {
        // This will never overflow as the maximum supply is limited to < 255
        unchecked {
            tokenIds++;
        }
        _backerNames[tokenIds] = _backerName;
        _safeMint(_account, uint256(tokenIds));
        emit Reserved(_account, tokenIds, _formatImageURI(tokenIds));
    }

    /// @notice Formats the image uri for a specific token id.
    /// @param _tokenId The token to be queried.
    function _formatImageURI(uint8 _tokenId)
        internal
        view
        returns (string memory imageURI)
    {
        imageURI = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg id='CareerConAAA' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='595' height='841'>",
                            "<defs><style>.cls-1{fill:#eae331;font-family:Courier New;font-size:24px}.cls-2{font-size:18px;font-family:Impact;letter-spacing:.03em}.cls-3{font-size:108px;font-family:Impact}</style></defs>",
                            "<rect class='cls-1' width='100%' height='100%'/>",
                            "<text class='cls-3' y='50' transform='translate(300)'>",
                            "<tspan x='0' text-anchor='middle' dy='100'>HUNDO100</tspan><tspan x='0' text-anchor='middle' dy='250'>ACCESS</tspan><tspan x='0' text-anchor='middle' dy='100'>ALL</tspan><tspan x='0' text-anchor='middle' dy='100'>AREAS</tspan><tspan class='cls-2' x='0' text-anchor='middle' dy='-370'>THIS PASS GRANTS</tspan><tspan class='cls-2' x='0' text-anchor='middle' dy='25'>",
                            _backerNames[_tokenId],
                            "</tspan></text><rect x='35%' y='700' width='30%' height='6%'/>",
                            "<text class='cls-2' dy='730' text-anchor='middle'>",
                            "<tspan class='cls-1' x='300' y='2'>ADMIT ONE</tspan></text></svg>"
                        )
                    )
                )
            )
        );
    }
}