// contracts/Genesis.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
// import "./ERC721URIStorage.sol";
// import "./Helper.sol";
import "./ECDSA.sol";

// , ERC721URIStorage
contract Genesis is ERC721Enumerable {
    /*
  ________                            .__        
 /  _____/  ____   ____   ____   _____|__| ______
/   \  ____/ __ \ /    \_/ __ \ /  ___/  |/  ___/
\    \_\  \  ___/|   |  \  ___/ \___ \|  |\___ \ 
 \______  /\___  >___|  /\___  >____  >__/____  >
        \/     \/     \/     \/     \/        \/ 
*/

    using ECDSA for bytes32;

    //uint256s
    uint256 maxSupply = 200;

    //address
    address _owner;
    bool public paused = false;

    address private signerAddressPublic;
    /*
    address payable public treasury;

    uint private _priceOne = 0;

    uint256 public presaleWindow = 24 hours; // 24 hours presale period
    uint256 public presaleStartTime = 1634342400; // 16th October 0800 SGT
    uint256 public publicSaleStartTime = 1634443200; // 17th October 1200 SGT

    // manual toggle for presale and public sale //
    bool public presaleOpen = false;
    bool public publicSaleOpen = true;

    mapping(address => uint256) private publicAddressMintedAmount; // number of NFT minted for each wallet during public sale
    mapping(address => uint256) private presaleAddressMintedAmount; // number of NFT minted for each wallet during presale
    mapping(address => bool) public whitelistedAddresses; // all address of whitelisted OGs
    */

    struct SvgMetadata {
        bytes styles;
        bytes pixels;
    }
    mapping(uint256 => SvgMetadata) public svgMetadataMaps;

    mapping(bytes => bool) private _nonceUsed; // nonce was used to mint already

    /*
    uint256 public nftPerAddressLimitPublic = 3; // maximum number of mint per wallet for public sale
    uint256 public nftPerAddressLimitPresale = 3; // maximum number of mint per wallet for presale
    */

    // bytes pixels;

    constructor() ERC721("Genesis", "GEN") {
        _owner = msg.sender;
        setSignerAddressPublic(_owner);
        // treasury = payable(_owner);
    }

    /*
    function setPriceOne(uint mintPrice) external onlyOwner {
        _priceOne = mintPrice;
    }

    // dev team mint
    function devMint(string memory _tokenURI) public onlyOwner {
        require(!paused); // contract is not paused
        uint256 supply = totalSupply(); // get current mintedAmount
        require(supply + 1 <= maxSupply); // total mint amount exceeded supply, try lowering amount
        _safeMint(msg.sender, supply + 1);
        _setTokenURI(supply + 1, _tokenURI);
    }

    // presale mint
    function presaleMint(
        string memory _tokenURI
    ) public payable {
        require(!paused); // contract is paused
        require((isPresaleOpen() || presaleOpen)); // presale has not started or it has ended
        require(whitelistedAddresses[msg.sender]); // you are not in the whitelist"
        uint256 supply = totalSupply();
        require(
            presaleAddressMintedAmount[msg.sender] + 1 <=
            nftPerAddressLimitPresale
        ); // you can only mint a maximum of two nft during presale
        require(msg.value >= _priceOne); // not enought ether sent for mint amount

        (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
        require(success); // not able to forward msg value to treasury

        presaleAddressMintedAmount[msg.sender]++;
        _safeMint(msg.sender, supply + 1);
        _setTokenURI(supply + 1, _tokenURI);
    }
    */

    //*************** INTERNAL FUNCTIONS ******************//
    function isSignedBySigner(
        address sender,
        bytes memory nonce,
        bytes memory signature,
        address signerAddress
    ) private pure returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddress == hash.recover(signature);
    }

    function setSignerAddressPublic(address publicSignerAddress)
        public
        onlyOwner
    {
        signerAddressPublic = publicSignerAddress;
    }

    function publicMint(
        // SvgMetadata memory svgMetadata
        // bytes memory _tokenURI
        // bytes memory nonce,
        // bytes memory signature
        bytes memory styles,
        bytes memory pixels
    ) public payable {
        require(!paused);
        // require((isPublicSaleOpen() || publicSaleOpen)); // public sale has not started

        /*
        require(!_nonceUsed[nonce]); // nonce was used
        require(
            isSignedBySigner(msg.sender, nonce, signature, signerAddressPublic)
        ); // "invalid signature"
        */

        /*
        require(
            publicAddressMintedAmount[msg.sender] + 1 <=
            nftPerAddressLimitPublic
        ); // You have exceeded max amount of mints
        */
        
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply); // all have been minted
        // require(msg.value >= _priceOne); // must send correct price

        if (msg.value>0) {
            // (bool success, ) = treasury.call{ value: msg.value }(""); // forward amount to treasury wallet
            (bool success, ) = payable(_owner).call{ value: msg.value }(""); // forward amount to treasury wallet
            require(success); // not able to forward msg value to treasury        
        }

        // publicAddressMintedAmount[msg.sender]++;
        _safeMint(msg.sender, supply + 1);
        // _nonceUsed[nonce] = true;
        // _setTokenURI(supply + 1, string(_tokenURI));
        // svgMetadataMaps[supply + 1] = svgMetadata;
        svgMetadataMaps[supply + 1] = SvgMetadata(
            styles,
            pixels
        );

    }

    // ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Genesis #',
                                    Strings.toString(tokenId),
                                    '", "description": "A genesis on-chain collection of 120 handcrafted 8-bit shoes living in the Ethereum blockchain. NO JPEGS, NO IPFS, all shoes visuals are code base and store straight in the smart contract.", "image": "data:image/svg+xml;base64,',
                                    Base64.encode(
                                        // bytes(ERC721URIStorage.tokenURI(tokenId))
                                        bytes(getSVG2(tokenId))
                                    ),
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
        // return ERC721URIStorage.tokenURI(tokenId);
    }

    /*
    function setPixels(bytes memory _pixels) public {
        pixels = _pixels;
    }
    function getPixels() public view returns (bytes memory) {
        return pixels;
    }
    function getPixelsLength() public view returns (string memory) {
        return Strings.toString(uint256(pixels.length));
    }

    function getSVG() public view returns (string memory) {
        string memory svgString;
        string memory styleString;
        for (uint16 j = 0; j < pixels.length; j=j+2) {
            svgString = string(
                abi.encodePacked(
                    svgString,
                    "<rect class='c",
                    "' x='",
                    Strings.toString(uint8(pixels[j])),
                    "' y='",
                    Strings.toString(uint8(pixels[j+1])),
                    "'/>"
                )
            );
        }

        svgString = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 10"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #mouse-svg{shape-rendering: crispedges;}",
                styleString,
                "</style></svg>"
            )
        );

        return svgString;
    }
    */

    function getSVG2(uint256 tokenId) public view returns (string memory) {
        // bool[30][10] memory _pixels;
        string memory rects;
        /*
        _pixels = [[false,false,false,false,false,false,false,false,true,true,true,false,false,false,false,false,false,false,false,true,true,true,false,false,false,false,false,false,false,false],[false,false,false,false,false,false,false,false,true,true,true,true,true,true,false,false,true,true,true,true,true,true,false,false,false,false,false,false,false,false],[false,false,false,false,false,false,false,false,true,true,true,true,true,true,false,false,true,true,true,true,true,true,false,false,false,false,false,false,false,false],[false,false,false,false,false,false,false,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,false,false,false,false,false,false,false],[false,false,false,false,false,false,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,false,false,false,false,false,false],[false,false,false,false,true,true,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,true,false,false,false,false],[false,false,true,true,true,true,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,true,true,true,false,false],[false,true,true,true,true,true,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,false],[true,true,true,true,true,true,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,true],[false,true,true,true,true,true,true,true,true,true,true,true,true,true,false,false,true,true,true,true,true,true,true,true,true,true,true,true,true,false]];
        */
        bytes memory _pixels_bytes = hex"00e01c0003f3f0000fcfc0007f3f8003fcff003ff3ff03ffcfff1fff3ffefffcfffdfff3ffe0";

        bytes memory _class; // = hex"00020202020000020202020101020202020002020202020202020202020200020201010102020101010202000002020000000001010000000002020000020200000100000100000100000100000202000000000002020001010100000000010101000202000000000202020202020202000000000000000000000202020202020202040303030303030303030303030303030303030303030303030303040404040404040404040404040404040404040404040404040404";
        SvgMetadata memory svgMetadata = svgMetadataMaps[tokenId];

        _class = svgMetadata.pixels;
        bytes memory _class2 = new bytes(_class.length*2);
        for (uint i=0;i<_class.length;i++) {
            _class2[i*2] = bytes1(uint8(_class[i]) >> 4);
            _class2[i*2+1] = bytes1(uint8(_class[i]) & 15);
        }

        uint z = 0;
        uint _pixels_bytes_i = 0;
        uint _pixels_byte;
        uint _pixels_byte_i = 8;
        uint _pixels_val = 0;

        for (uint y=0;y<10;y++) {
            for (uint x=0;x<30;x++) {
                if (_pixels_byte_i==8) {
                    _pixels_byte = uint8(_pixels_bytes[_pixels_bytes_i]);
                    _pixels_bytes_i++;
                    _pixels_byte_i = 0;
                }
                _pixels_val = uint1a8.get(_pixels_byte, 7-_pixels_byte_i);
                _pixels_byte_i++;

                // if (_pixels[y][x]) {
                if (_pixels_val==1) {

                    rects = string(abi.encodePacked(rects, 
                        "<rect class='c",
                        Strings.toString(uint8(_class2[z])),
                        "' x='",
                        Strings.toString(x),
                        "' y='",
                        Strings.toString(y),
                        "'/>"
                    ));
                    z++;
                }
            }
        }

        string memory svgStyles;
        bytes memory styles;
        styles = svgMetadata.styles;
        for(uint i=0;i<styles.length;i=i+3) {
            svgStyles = string(abi.encodePacked(
                svgStyles,
                ".c",
                Strings.toString(i/3),
                "{fill:#",
                toHexString(abi.encodePacked(styles[i],styles[i+1],styles[i+2])),
                // Helper.substring(string(styles), i, i+3),
                ";}"
            ));
        }

        // styles = ["#ece8e5","#232826","#b61725","#fff","#a43443"];

        /*
        for (uint i=0;i<5;i++) {
            svgStyles = string(abi.encodePacked(
                svgStyles,
                ".c",
                Strings.toString(i),
                "{fill:",
                _styles[i],
                ";}"
            ));
        }
        */

        string[5] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 10"><defs><style>.a{filter:url(#a);}rect{width:1px;height:1px}';
        parts[1] = svgStyles;
        parts[2] = '</style><filter id="a" name="dropshadow"><feGaussianBlur stdDeviation="0.5" in="SourceAlpha"/><feOffset result="offsetblur"/><feComponentTransfer><feFuncA slope="0.3" type="linear"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter></defs><g class="a">';
        parts[3] = rects;
        parts[4] = '</g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));

        return output;

    }


    function toHexString(bytes memory data) public pure returns (string memory) {
        bytes memory res = new bytes(data.length * 2);
        bytes memory alphabet = "0123456789abcdef";
        for (uint i = 0; i < data.length; i++) {
            res[i*2 + 0] = alphabet[uint256(uint8(data[i])) >> 4];
            res[i*2 + 1] = alphabet[uint256(uint8(data[i])) & 15];
        }
        return string(abi.encodePacked(res));
    }

    /*
    function toBinaryString(bytes memory data) public pure returns (string memory) {
        bytes memory output = new bytes((data.length*8));
        for (uint8 j = 0; j<data.length;j++) {
            uint8 n = uint8(data[j]);
            for (uint8 i = 0; i < 8; i++) {
                output[((j+1)*8)-i-1] = (n % 2 == 1)?bytes1("1"):bytes1("0");
                n /= 2;
            }
        }
        return string(output);
    }
    */

    /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    */

    /*
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        return ERC721URIStorage._burn(tokenId);
    }
    */

    /*
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /*
    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= publicSaleStartTime;
    }

    function setPublicSaleOpen(bool _publicSaleOpen) public onlyOwner {
        publicSaleOpen = _publicSaleOpen;
    }

    function setPresaleOpen(bool _presaleOpen) public onlyOwner {
        presaleOpen = _presaleOpen;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }

    function whitelistUsers(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistedAddresses[_users[i]] = true;
        }
    }

    function isPresaleOpen() public view returns (bool) {
        return
        block.timestamp >= presaleStartTime &&
        block.timestamp < (presaleStartTime + presaleWindow);
    }
    */

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    /*
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }
    */

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    /*
    function toString(uint256 value) internal pure returns (string memory) {
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
    */

    /*
    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
    */


}

library uint1a8 { // provides the equivalent of uint8[32]
    uint constant bits = 1;
    uint constant elements = 8;
    // must ensure that bits * elements <= 256
   
    uint constant range = 1 << bits;
    uint constant max = range - 1;    // get function    
    function get(uint va, uint index) internal pure returns (uint) {
        require(index < elements);
        return (va >> (bits * index)) & max;
    }
    
    // set function    
    function set(uint va, uint index, uint ev) internal pure 
    returns (uint) {
        require(index < elements);
        // require(value < range);
        index *= bits;
        return (va & ~(max << index)) | (ev << index);
    }
}