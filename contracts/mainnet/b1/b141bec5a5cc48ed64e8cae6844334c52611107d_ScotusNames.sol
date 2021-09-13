/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC-721-like NFT + ERC-20/EIP-2612-like implementation.
contract ERC721like {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public name;
    
    string public symbol;
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    /*///////////////////////////////////////////////////////////////
                         PERMIT/EIP-2612-LIKE STORAGE
    //////////////////////////////////////////////////////////////*/
    
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
        
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;
    
    constructor(
        string memory _name,
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        // This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[msg.sender]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(msg.sender, to, tokenId); 
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address, address to, uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        
        require(
            msg.sender == owner 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[owner][msg.sender], 
            "NOT_APPROVED"
        );
        
        // This is safe because ownership is checked
        // against decrement, and sum of all user
        // balances can't exceed type(uint256).max!
        unchecked { 
            balanceOf[owner]--; 
        
            balanceOf[to]++;
        }
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        
        emit Transfer(owner, to, tokenId); 
    }
    
    function safetransferFrom(address, address to, uint256 tokenId) external {
        safetransferFrom(address(0), to, tokenId, "");
    }
    
    function safetransferFrom(address, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(address(0), to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    /*///////////////////////////////////////////////////////////////
                          PERMIT/EIP-2612-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        
        address owner = ownerOf[tokenId];
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonces[owner]++, deadline))
            )
        );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) 
                && recoveredAddress == owner
                || isApprovedForAll[owner][recoveredAddress], 
                "INVALID_PERMIT_SIGNATURE"
        );
        
        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);
    }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/
    
    function _mint(address to, uint256 tokenId) internal { 
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId); 
    }
}

/**
 * @title Scotus Names
 * @dev {ERC721} token built on Solmate (licensed under AGPL-3), Loot & Stage Names (licensed under MIT), including:
 *  - open, free token minting (creation)
 *  - URI autogeneration from svg
 *  - general legal engineering dopeness
 */
contract ScotusNames is
    ERC721like("Scotus Names", "SCOTUS")
{   
    string[] moji = [
        unicode"😀",
        unicode"🤣",
        unicode"😇",
        unicode"😜",
        unicode"🤪",
        unicode"🤭",
        unicode"🤐",
        unicode"😬",
        unicode"😏",
        unicode"😌",
        unicode"😷",
        unicode"🤒",
        unicode"🤯",
        unicode"🤠",
        unicode"🥳",
        unicode"😎",
        unicode"🤓",
        unicode"🧐",
        unicode"😲",
        unicode"🥱",
        unicode"😈",
        unicode"😶",
        unicode"🤨",
        unicode"🤔",
        unicode"🤧"
    ];
    
    string[] firstName = [
        "Bittah",
        "Tha",
        "Mad",
        "Master",
        "Dynamic",
        "E-ratic",
        "Wack",
        "Fearless",
        "Misunderstood",
        "Quiet",
        "Pesky",
        "Gentlemen",
        "Profound",
        "Respected",
        "Auteur",
        "Shriekin'",
        "Lucky",
        "Phantom",
        "Smilin'",
        "Thunderous",
        "Tuff",
        "Scratchin'",
        "Dope",
        "X-cessive",
        "X-pert",
        "Zexy",
        "Ruff",
        "Intellectual",
        "Unlucky",
        "Vizual",
        "Frenly",
        "Midnight",
        "Mighty",
        "Based",
        "Vamped",
        "Fiery",
        "Stoked",
        "Wholesome",
        "B-loved",
        "Sarkastik",
        "Glowing",
        "Irate",
        "Wicked",
        "Surly",
        "Amazing"
    ];
    
    string[] lastName = [
        "Roberts",
        "Thomas",
        "Breyer",
        "Alito",
        "Sotomayor",
        "Kagan",
        "Gorsuch",
        "Kavanaugh",
        "Barrett"
    ];
    
    string[] superPower = [
        "with power of Estoppel",
        "with power of Subpoena",
        "with power of Affidavit",
        "with power of Laches",
        "with power of Amendment",
        "with power of Livery of Seisin",
        "with power of Appeal",
        "with power of Jurisdiction",
        "with power of Discretion",
        "with power of Immunity",
        "with power of Abjudication",
        "with power of Abjuration",
        "with power of Damages",
        "with power of Preclusion",
        "with power of Res Judicata",
        "with power of Ejusdem Generis",
        "with power of Bird Law",
        "with power of Finding of Fact",
        "with power of Quasi in Rem",
        "with power of Quantum Meruit"
    ];
    
    string[] robeColor = [
        "in White Robes",
        "in White Robes",
        "in Black Robes",
        "in Black Robes",
        "in Purple Robes",
        "in Purple Robes",
        "in Red Robes",
        "in Red Robes",
        "in Pink Robes",
        "in Yellow Robes"
    ];
    
    function random(string memory input) private pure returns (uint256 rand) {
        rand = uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getMoji(uint256 tokenId) public view returns (string memory moj) {
        moj = pluck(tokenId, "MOJI", moji);
    }
    
    function getFirstName(uint256 tokenId) public view returns (string memory first) {
        first = pluck(tokenId, "FIRST", firstName);
    }
    
    function getLastName(uint256 tokenId) public view returns (string memory last) {
        last = pluck(tokenId, "LAST", lastName);
    }
    
    function getSuperPower(uint256 tokenId) public view returns (string memory power) {
        power = pluck(tokenId, "POWER", superPower);
    }
    
    function getRobeColor(uint256 tokenId) public view returns (string memory color) {
        color = pluck(tokenId, "COLOR", robeColor);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) private pure returns (string memory output) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        output = sourceArray[rand % sourceArray.length];
    }

    function tokenURI(uint256 tokenId) external view returns (string memory output) {
        string[11] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: yellow; font-family: lobster; font-size: 24px; }</style><rect width="100%" height="100%" fill="orchid" /><text x="300" y="90" class="base">';
        
        parts[1] = getMoji(tokenId);
        
        parts[2] = '</text><text x="10" y="180" class="base">';
        
        parts[3] = getFirstName(tokenId);

        parts[4] = '</text><text x="10" y="210" class="base">';
        
        parts[5] = getLastName(tokenId);
        
        parts[6] = '</text><text x="10" y="270" class="base">';
        
        parts[7] = getSuperPower(tokenId);
        
        parts[8] = '</text><text x="10" y="300" class="base">';
        
        parts[9] = getRobeColor(tokenId);

        parts[10] = '</text></svg>';
        
        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10]));
        
        string memory json = 
            Base64.encode(bytes(string(abi.encodePacked(
        '{"name": "SCOTUS #', toString(tokenId), '", "description": "Scotus Names are random onchain SCOTUS names based on Stage Names/Loot.", "attributes": [{"trait_type": "First Name","value": "', getFirstName(tokenId), '"}, {"trait_type": "Last Name","value": "', getLastName(tokenId), '"}, {"trait_type": "Super Power","value": "', getSuperPower(tokenId), '"}, {"trait_type": "Robe Color","value": "', getRobeColor(tokenId), '"}], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }
    
    function claim() external {
        totalSupply++;
        uint256 tokenId = totalSupply;
        require(tokenId < 421, "MAXED");
        _mint(msg.sender, tokenId);
    }
   
    function toString(uint256 value) private pure returns (string memory output) {
        // @dev Inspired by OraclizeAPI's implementation - MIT license -
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol.
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