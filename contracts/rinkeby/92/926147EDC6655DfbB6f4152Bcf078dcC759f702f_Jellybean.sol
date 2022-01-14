// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

// Thank you m1guelpf
// https://github.com/m1guelpf/erc721-drop
import "./LilOwnable.sol";

// Thank you transmissions11
// https://github.com/Rari-Capital/solmate
// import "@rari-capital/solmate/src/tokens/ERC721.sol";
// import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

// Thank you OpenZeppelin
// import "@openzeppelin/contracts/utils/Strings.sol"; // kinda dont want to use Strings.  will replace later.

// // Thank you ENS?
// import '@ensdomains/ens-contracts/contracts/registry/ENS.sol';


import "./SVG.sol";

// import "hardhat/console.sol";

error DoesNotExist();
error NoTokensLeft();
error NotEnoughETH();

contract Jellybean is LilOwnable {

    // ERC721 mandated
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // local variables
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(uint256 => address) public minterOf;



    constructor() {
        name = "jtest";
        symbol = "jt";
    }

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
    ) public pure {
        require(0 == 1, "TRANSFER_NOT_ALLOWED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public pure {
        require(0 == 1, "TRANSFER_NOT_ALLOWED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public pure {
        require(0 == 1, "TRANSFER_NOT_ALLOWED");
    }

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

    function mint() external payable {
        _mint(msg.sender, totalSupply);
        minterOf[totalSupply] = ownerOf[totalSupply];
        totalSupply++;
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

    // function burn() external payable {
    //     _burn(msg.sender, totalSupply);
    //     minterOf[totalSupply] = ownerOf[totalSupply];
    //     totalSupply++;
    // }

    function tokenURI(uint256 id) public view returns (string memory) {
        if (ownerOf[id] == address(0)) revert DoesNotExist();

        string memory svgString = string(
            abi.encodePacked(
                SVG.svgStart(320, 240),
                "<style>.base { fill: black; font-family: serif; font-size: 12px; }</style>",
                SVG.svgRectStart(10,10,300,220,12,12,"slateblue"),
                SVG.svgRectEnd(),
                "<text x='50%' y='90%' class='base' dominant-baseline='middle' text-anchor='middle'>",
                "<animate attributeName='x' values='45%;55%;45%' dur='4s' repeatCount='indefinite' />",
                "0x",
                toAsciiString(minterOf[id]),
                "</text>",
                SVG.svgEnd()
            )
        );

        return SVG.buildSvg("NFT Name","NFT",svgString);
    }

    //https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    function withdraw() external {
        if (msg.sender != _owner) revert NotOwner();

        safeTransferETH(msg.sender, address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(LilOwnable)
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

error NotOwner();

abstract contract LilOwnable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "hardhat/console.sol";

library SVG {
    function svgStart(uint256 viewBoxWidth, uint256 viewBoxHeight) public pure returns (string memory)
    {
        return string( 
            abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ", 
            uint2str(viewBoxWidth), 
            " ",
            uint2str(viewBoxHeight), 
            "'>"
            ));
    }

    function svgEnd() public pure returns (string memory)
    {
        return string( 
            abi.encodePacked("</svg>"));
    }

    function svgRectStart(uint256 x, uint256 y, uint256 width, uint256 height, uint256 rx, uint256 ry, string memory fillColor) public pure returns (string memory)
    {
        return string( 
            abi.encodePacked(
                "<rect x='", 
                uint2str(x), 
                "' y='",
                uint2str(y),
                "' width='",
                uint2str(width), 
                "' height='",
                uint2str(height), 
                "' rx='",
                uint2str(rx), 
                "' ry='",
                uint2str(ry),
                "' fill='",
                fillColor, 
                "'>"
                ));
    }

    function svgRectEnd() public pure returns (string memory)
    {
        return string( 
            abi.encodePacked("</rect>"));
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
    }


    function buildSvg(string memory nftName, string memory nftDescription, string memory svgString) public pure returns (string memory)
    {
        // console.log("\n--------------------");
        // console.log(svgString);
        // console.log("--------------------\n");

        string memory imgEncoded = Base64.encode(bytes(svgString));
        // console.log("\n--------------------");
        // console.log(imgEncoded);
        // console.log("--------------------\n");

        string memory imgURI = string(abi.encodePacked('data:image/svg+xml;base64,', imgEncoded));
        // console.log("\n--------------------");
        // console.log(imgURI);
        // console.log("--------------------\n");

        string memory nftJson = string(abi.encodePacked('{"name": "', nftName, '", "description": "', nftDescription, '", "image": "', imgURI, '"}'));
        // console.log("\n--------------------");
        // console.log(nftJson);
        // console.log("--------------------\n");

        string memory nftEncoded = Base64.encode(bytes(nftJson));
        // console.log("\n--------------------");
        // console.log(nftEncoded);
        // console.log("--------------------\n");

        string memory finalURI = string(abi.encodePacked("data:application/json;base64,", nftEncoded));
        // console.log("\n--------------------");
        // console.log(finalURI);
        // console.log("--------------------\n");

        return finalURI;
    }

}

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