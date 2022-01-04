// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @dev Note that this is a very stripped down ERC-721 knock-off with gas savings as the highest priority. Some features may be unsafe or missing.

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               let input := mload(dataPtr)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        return result;
    }
}

struct Telegram {
    address from;
    bytes32 line1;
    bytes32 line2;
    bytes32 line3;
    bytes32 line4;
}

contract MPOTelegraph {
    address private owner;
    uint256 public PRICE = 1000000000000000; // 0.001 eth
    string public name = "Metaversal Post Office Telegraph";
    string public symbol = "MPOT";

    constructor() {
        owner = msg.sender;
    }

    // ERC721 --------------------------------------------------------------->>
    mapping(uint256 => address) private ownership;
    mapping(uint256 => Telegram) private metadata;
    mapping(uint256 => address) private approvedForToken;
    mapping(address => mapping(address => bool)) private approvedForAll;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 _tokenId) public view virtual returns (address) {
        return ownership[_tokenId];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        require(msg.sender == ownership[_tokenId] || msg.sender == getApproved(_tokenId) || isApprovedForAll(ownership[_tokenId], msg.sender), "Unauthorized");
        require(ownership[_tokenId] == _from, "The from address does not own this token"); 

        // Clear approvals from the previous owner
        approvedForToken[_tokenId] = address(0);

        ownership[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _candidate, uint256 _tokenId) public virtual {
        require(msg.sender == ownership[_tokenId] || isApprovedForAll(ownership[_tokenId], msg.sender), "Unauthorized");
        approvedForToken[_tokenId] = _candidate;
        emit Approval(ownership[_tokenId], _candidate, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view virtual returns (address) {
        return approvedForToken[_tokenId];
    }

    function setApprovalForAll(address _candidate, bool _approved) public virtual {
        approvedForAll[msg.sender][_candidate] = _approved;
        emit ApprovalForAll(msg.sender, _candidate, _approved);
    }

    function isApprovedForAll(address _owner, address _candidate) public view virtual returns (bool) {
        return approvedForAll[_owner][_candidate];
    }

    // UNSAFE - USE AT OWN RISK
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public { transferFrom(_from, _to, _tokenId); }
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) public { transferFrom(_from, _to, _tokenId); }
    
    // Ignored
    function balanceOf(address _owner) public view virtual returns (uint256) { return 0; }
    // <<--------------------------------------------------------------- ERC721

    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        // string memory svg = string(generateSVG(_tokenId));
        string memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="-25 -25 400 400"><text>Hello world</text></svg>';
        string memory _json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                    '{"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'"}'
                    )
                )
            )
        );

        string memory _output = string(
            abi.encodePacked('data:application/json;base64,', _json)
        );
        return _output;
    }
    // <<------------------------------------------------------- ERC721Metadata


    // ERC165 --------------------------------------------------------------->>
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == 0x80ac58cd || // IERC721
            _interfaceId == 0x5b5e139f || // IERC721Metadata
            _interfaceId == 0x01ffc9a7; // IERC165
    }
    // <<--------------------------------------------------------------- ERC165

    // Other functions ------------------------------------------------------>>

    function mint(uint256 id, address to, string calldata line1, string calldata line2, string calldata line3, string calldata line4) public payable {
        require(msg.value >= PRICE, "Send more ETH");
        require(ownership[id] == address(0), "ID already in use");

        ownership[id] = to;
        metadata[id] = Telegram(msg.sender, s2b32(line1),s2b32(line2),s2b32(line3),s2b32(line4));

        emit Transfer(address(0), to, id);
    }

    function reply(uint256 burnId, string calldata line1, string calldata line2, string calldata line3, string calldata line4) public {
        require(msg.sender == ownership[burnId] || msg.sender == getApproved(burnId) || isApprovedForAll(ownership[burnId], msg.sender), "Unauthorized");

        emit Transfer(ownership[burnId], address(0), burnId);
        ownership[burnId] = metadata[burnId].from;
        emit Transfer(address(0), metadata[burnId].from, burnId);
        metadata[burnId] = Telegram(msg.sender, s2b32(line1),s2b32(line2),s2b32(line3),s2b32(line4));
    }

    // Required by etherscan.io
    function totalSupply() public view virtual returns (uint256) {
        return 0;
    }

    function withdraw() public payable {
        (bool success, ) = payable(owner).call{value: msg.value}("");
        require(success, "Could not transfer money to contractOwner");
    }

    function s2b32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function b322s(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
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

    function hashToString(bytes32 value) public pure returns(string memory) 
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function generateSVG(uint256 id) private view returns (bytes memory) {
        bytes memory lines = abi.encodePacked(
            b322s(metadata[id].line1),
            '</tspan></tspan><tspan x="0" dy="20"><tspan class="muted">></tspan><tspan>',
            b322s(metadata[id].line2),
            '</tspan></tspan><tspan x="0" dy="20"><tspan class="muted">></tspan><tspan>',
            b322s(metadata[id].line3),
            '</tspan></tspan><tspan x="0" dy="20"><tspan class="muted">></tspan><tspan>',
            b322s(metadata[id].line4)
        );

        bytes memory start = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="-25 -25 400 400"><style>.text {font-family: sans-serif; fill: #B6412A; font-size: 10px;} .content{font-family: monospace; fill: #149CA5; font-size: 14px; font-weight: 700} .muted {fill: #1B3450; font-weight: 500;} .title {font-family: sans-serif; font-weight: 900; fill: #B6412A; font-size: 13px;} .metadata {font-family: monospace; fill: #0087A3; font-size: 10px; font-weight: 700} .subtitle {font-size: 18px;} .tiny {font-size: 8px } .fineprint {font-size: 6px }</style><rect x="-25" y="-25" width="425" height="425" fill="#A7C4C2" /><g transform="translate(0,50)"><rect width="350" height="250" fill="#0D141F" class="base" filter="url(#f2)" rx="4" ry="4"/><g transform="translate(80,40)"><text class="title">METAVERSAL POST OFFICE</text><line x1="17" y1="3" x2="160" y2="3" stroke="#B6412A"/><text class="title subtitle" x="35" y="20">TELEGRAPH</text></g><g transform="translate(10,18)"><text class="text" x="0" y="0">No.</text><text class="metadata" x="20" y="0">', 
            uint2str(id),
            '</text><line x1="17" y1="3" x2="60" y2="3" stroke="#B6412A"/></g><g transform="translate(270,18)"><text class="text" x="0" y="0">Block</text><text class="metadata" x="30" y="0">',
            uint2str(block.number),
            '</text><line x1="27" y1="3" x2="75" y2="3" stroke="#B6412A"/></g><g transform="translate(287,27)"><text class="text" x="0" y="5">Block Stamp</text><polygon points="0,8 0,53, 55,53, 55,8" fill="none" stroke="#1B3450" stroke-dasharray="3"/><g transform="translate(-1,4) scale(1,1)"><g transform="translate(25,25) rotate(-30)  scale(0.3,0.3)"><polygon points="0,-60 -35,0 0,20 35,0" fill="none" stroke="#0087A3" stroke-width="3px"/><polygon points="-35,0 0,20 35,0 0,-20" fill="none" stroke="#0087A3" stroke-width="3px"/><polygon points="-35,10 0,60 35,10 0,30" fill="none" stroke="#0087A3"stroke-width="3px"/></g><text class="metadata tiny"><textPath href="#stamp">',
            hashToString(bytes32(blockhash(block.number-1)))
        );

        bytes memory middle = abi.encodePacked(
            '</textPath><animateTransform attributeType="XML" attributeName="transform" type="rotate" from="0 25 25" to="360 25 25"  dur="10s" repeatCount="indefinite" /></text><path fill="none" d="M -2,25 A 27 27 0 1 0 -2,24.5 z" stroke="#0087A3" stroke-width="1" /></g></g><g transform="translate(0,100)"><g transform="translate(10,-10)"><text class="text" x="0" y="0">From</text><text class="metadata" x="28" y="0">',
            hashToString(bytes32(uint256(uint160(metadata[id].from)))),
            '</text><line x1="25" y1="3" x2="110" y2="3" stroke="#B6412A"/></g><g transform="translate(240,-10)"><text class="text" x="0" y="0">To</text><text class="metadata" x="15" y="0">',
            hashToString(bytes32(uint256(uint160(ownership[id])))),
            '</text><line x1="12" y1="3" x2="100" y2="3" stroke="#B6412A"/></g><g transform="translate(0,0)"><line x1="5" y1="0" x2="345" y2="0" stroke="#B6412A"/><line x1="40" y1="0" x2="40" y2="145" stroke="#B6412A"/><g transform="translate(55,20)"><text class="text content" x="0" y="-20"><tspan x="0" dy="20"><tspan class="muted">></tspan><tspan>'
        );

        return abi.encodePacked(
            start,
            middle,
            lines,
            '</tspan></tspan></text><g transform="translate(0,119)"><text class="text fineprint" x="0" y="0">FOR ONE FREE RESPONSE TO THIS TELEGRAM, VISIT THE METAVERAL POST OFFICE OR</text><text class="text fineprint" x="0" y="6">WWW.METAVERSALPOST.IO WITH THE WALLET OWNING THIS NON-FUNGIBLE TELEGRAM.</text></g></g></g></g></g><defs><path id="stamp" fill="none" d="M 0,25 A 25 25 0 1 0 0,24.99 z" /><filter id="f2" x="-0.1" y="-0.1" width="200%" height="200%"><feOffset result="offOut" in="SourceAlpha" dx="0" dy="0" /><feGaussianBlur result="blurOut" in="offOut" stdDeviation="10" /><feBlend in="SourceGraphic" in2="blurOut" mode="normal" /></filter></defs></svg>'
        );

    }

    // <<----------------------------------------------------- Other functions
}