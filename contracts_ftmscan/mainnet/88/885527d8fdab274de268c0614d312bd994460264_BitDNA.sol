// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract BitDNA is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;

    ERC20 public token;
    uint public price;
    mapping(uint => uint) private tokenDnas;
    
    constructor(ERC20 token_, string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        token = token_;
    }

    event NewPrice(uint price);

    function claim(uint256 tokenId) external nonReentrant {
        _safeMint(_msgSender(), tokenId);
        tokenDnas[tokenId] = random(tokenId);
        if (price == 0) return;
        token.safeTransferFrom(_msgSender(), address(this), price);
    }

    // 更新价格
    function updatePrice(uint _price) external onlyOwner {
        price = _price;
        emit NewPrice(_price);
    }

    // 归集
    function collect() external onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    // 获取DNA
    function dna(uint tokenId) external view returns (string memory) {
        return Strings.toString(tokenDnas[tokenId]);
    }

    // 获取二进制DNA
    function binaryDna(uint tokenId) external view returns (string memory) {
        return toString(toUintsByRadix(tokenDnas[tokenId], 2, 256));
    }

    // 获取二进制DNA片段
    function binaryDnaPart(uint tokenId, uint8 firstIndex, uint8 lastIndex) external view returns (string memory) {
        return toString(getUintsPart(toUintsByRadix(tokenDnas[tokenId], 2, 256), firstIndex, lastIndex));
    }

    // tokenURI
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint[] memory uintsExp16 = toUintsByRadix(tokenDnas[tokenId], 2 ** 16, 16);    // 先切为16段整数（值范围0 -> 2**16-1）
        string[7] memory subParts;

        // 拼svg
        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        for (uint i = 0; i < uintsExp16.length; i++) {
            subParts[0] = '<text x="10" y="';
            subParts[1] = Strings.toString((i + 1) * 20);
            subParts[2] = '" class="base">[';
            subParts[3] = toString(toUintsByRadix(uintsExp16[i], 10, 5));
            subParts[4] = '] ';
            subParts[5] = toString(toUintsByRadix(uintsExp16[i], 2, 16));              // 再将每段切为16段整数（值范围0 -> 1）
            subParts[6] = '</text>';
            output = string(abi.encodePacked(output, subParts[0], subParts[1], subParts[2], subParts[3], subParts[4], subParts[5], subParts[6]));
        }
        output = string(abi.encodePacked(output, '</svg>'));
        
        // 拼json + mini type
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "DNA #', Strings.toString(tokenId), '", "description": "", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }



    // ******************************************* 内部 ***********************************************

    // 内部：二进制数字数组转字符串
    function toString(uint[] memory binaryUints) internal pure returns (string memory)  {
        bytes memory binaryBytes = new bytes(binaryUints.length);
        for (uint i = 0; i < binaryUints.length; i++) {
            binaryBytes[i] = bytes1(uint8(48 + binaryUints[i]));
        }
        return string(binaryBytes);
    }

    // 内部：数字转任意进制
    function toUintsByRadix(uint value, uint radix, uint length) internal pure returns (uint[] memory) {
        uint[] memory hexUints = new uint[](length);
        for (uint i = length; i > 0; i--) {
            hexUints[i - 1] = value % radix;
            value /= radix;
        }
        return hexUints;
    }

    // 内部：取二进制数字数组片段
    function getUintsPart(uint[] memory uints, uint8 firstIndex, uint8 lastIndex) internal pure returns (uint[] memory) {
        require(lastIndex < uints.length);
        require(firstIndex <= lastIndex);
        uint[] memory uintsPart = new uint[](lastIndex - firstIndex + 1);
        for (uint i = firstIndex; i <= lastIndex; i++) {
            uintsPart[i - firstIndex] = uints[i];
        }
        return uintsPart;
    }

    // 内部：随机数(hash)
    function random(uint tokenId) internal view returns (uint) {
        return uint256(
            keccak256(
                abi.encodePacked (
                    tokenId,
                    block.timestamp,
                    block.difficulty
                )
            )
        );
    }

}