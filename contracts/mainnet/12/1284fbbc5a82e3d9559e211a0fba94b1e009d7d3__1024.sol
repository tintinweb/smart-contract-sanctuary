pragma solidity 0.8.9;

import "./VRFConsumerBase.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

// SPDX-License-Identifier: CC0

contract _1024 is ERC721, Ownable, VRFConsumerBase {
    /*

         ██  ██████  ██████  ██   ██ 
        ███ ██  ████      ██ ██   ██ 
         ██ ██ ██ ██  █████  ███████ 
         ██ ████  ██ ██           ██ 
         ██  ██████  ███████      ██ 
        yet another nft experiment,
        this time with randomness.
        
        every 1024 seconds, 1024 randomly
        selected addresses can mint 1 erc721
        token
        
        there is a max of 1024 tokens, although
        i do not expect many to be minted in general
        
        frontend might eventually
        become available @ https://1024.gallery
        
        enjoy
    */
    
    uint256 public seed;
    mapping (uint => uint) public mintTick;
    
    constructor()
        ERC721("1024", unicode"2¹⁰")
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    { }
    
    function requestSeed() external onlyOwner {
        require(seed == 0, 'randomness is filled');
        requestRandomness(0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, 2 * 10 ** 18);
    }
    
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(seed == 0, 'randomness is filled');
        seed = randomness;
    }

    function mint(uint256 tokenId) public {
        require(confirmEligibility(msg.sender, tokenId), 'not eligible');
        mintTick[tokenId] = this.tick();
        _safeMint(msg.sender, tokenId);
    }
    
    
    function tick() external view virtual returns (uint) {
        return uint(block.timestamp / 1024) * 1024;
    }
    
    // calculating stuff here 
    
    function currentlyEligible(uint _index) external view virtual returns (address) {
        require(_index >= 0 && _index < 1024, 'invalid index');
        require(seed != 0, 'randomness not provided');
        uint256 hash = uint256(keccak256(abi.encodePacked(seed, this.tick(), _index)));
        // there is probably a cleaner way to get
        // the 160 most significant bits, but this "just works"
        return address(uint160(bytes20(bytes32(hash))));
    }
    
    function calculateValues(uint _tick, uint _idx) internal view virtual returns (uint96) {
        uint256 rand = uint256(keccak256(abi.encodePacked(seed, _tick, _idx)));
        return uint96(rand);
    }
    
    function confirmEligibility(address _addr, uint _idx) internal view virtual returns (bool) {
        return _addr == this.currentlyEligible(_idx);
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toHexColor(uint24 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint i = 0; i < 6; i++) {
            buffer[6 - 1 - i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }

        return string(abi.encodePacked('#', buffer));
    }
    
    
    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(mintTick[tokenId] != 0, 'this token does not exist');

        string[17] memory parts;
        uint96 colors = calculateValues(mintTick[tokenId], tokenId);
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1024 1024">';
        
        parts[1] = '<rect x="256" y="256" width="256" height="256" style="fill:';
        parts[2] = toHexColor(uint24(colors & 0xffffff));
        parts[3] = '" />';
        colors /= 2 ** 24;
        
        parts[4] = '<rect x="512" y="256" width="256" height="256" style="fill:';
        parts[5] = toHexColor(uint24(colors & 0xffffff));
        parts[6] = '" />';
        colors /= 2 ** 24;
        
        parts[7] = '<rect x="256" y="512" width="256" height="256" style="fill:';
        parts[8] = toHexColor(uint24(colors & 0xffffff));
        parts[9] = '" />';
        colors /= 2 ** 24;

        parts[10] = '<rect x="512" y="512" width="256" height="256" style="fill:';
        parts[11] = toHexColor(uint24(colors & 0xffffff));
        parts[12] = '" />';
        
        parts[13] = '<text x="512" y="832" dominant-baseline="middle" style="font-size: 64px" text-anchor="middle">';
        parts[14] = Strings.toString(mintTick[tokenId]);
        parts[15] = '</text>';
        
        parts[16] = '<script type="text/javascript">document.querySelector("text").textContent = new Date(document.querySelector("text").textContent * 1000).toGMTString()</script></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "', Strings.toString(tokenId), '", "description": "this nft was (roughly) born at ', Strings.toString(mintTick[tokenId]), unicode' unix time (± 1024)", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}