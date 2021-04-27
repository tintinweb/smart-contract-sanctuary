// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "SafeMath.sol";
import "ZeroCopySink.sol";
import "ZeroCopySource.sol";
import "IERC721.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "IPolyNFTLockProxy.sol";

contract PolyNFTQuery {
    using SafeMath for uint;

    function getAndCheckTokenUrl(address asset, address user, uint tokenId) public view returns (bool, string memory) {
        string memory url = "";
        address owner = IERC721(asset).ownerOf(tokenId);
        if (user != owner || user == address(0)) {
            return (false, url);
        }

        url = IERC721Metadata(asset).tokenURI(tokenId);
        return (true, url);
    }

    // getTokensByIndex index start from 0
    function getOwnerTokensByIndex(address asset, address owner, uint start, uint length) public view returns (bool, bytes memory) {
        bytes memory buff;
        if (length == 0 || length > 10) {
            return (false, buff);
        }

        uint total = IERC721(asset).balanceOf(owner);
        if (total == 0 || start >= total) {
            return (false, buff);
        }        
        uint end = _calcEndIndex(start, length, total);

        IERC721Metadata meta = IERC721Metadata(asset);
        IERC721Enumerable enu = IERC721Enumerable(asset);
        for (uint index = start; index <= end; index++) {
            uint tokenId = enu.tokenOfOwnerByIndex(owner, index);
            string memory url = meta.tokenURI(tokenId);
            buff = _serializeProfile(buff, tokenId, url);
        }
        return (true, buff);
    }

    // getTokensByIndex index start from 0
    function getTokensByIds(address asset, bytes calldata args) public view returns (bool, bytes memory) {
        uint off = 0;
        uint tokenId = 0;
        uint length = 0;
        bytes memory buff;

        (length, off) = ZeroCopySource.NextUint256(args, off);
        if (length == 0 || length > 10) {
            return (false, buff);
        }

        IERC721Metadata meta = IERC721Metadata(asset);
        for (uint index = 0; index < length; index++) {
            (tokenId, off) = ZeroCopySource.NextUint256(args, off);
            string memory url = meta.tokenURI(tokenId);
            buff = _serializeProfile(buff, tokenId, url);
        }
        return (true, buff);
    }

    function getFilterTokensByIndex(address asset, address ignore, uint start, uint length) public view returns (bool, bytes memory) {
        bytes memory buff;
        if (length == 0 || length > 10) {
            return (false, buff);
        }

        IERC721Metadata meta = IERC721Metadata(asset);
        IERC721Enumerable enu = IERC721Enumerable(asset);
        IERC721 erc = IERC721(asset);
        
        uint256 total = enu.totalSupply();
        if (total == 0 || start >= total) {
            return (false, buff);
        }

        uint end = _calcEndIndex(start, length, total);
        while(start <= end && end < total) {
            uint tokenId = enu.tokenByIndex(start);
            start = start + 1;
            address owner = erc.ownerOf(tokenId);
            if (owner == ignore) {
                end = end + 1;
                continue;
            }
            string memory url = meta.tokenURI(tokenId);
            buff = _serializeProfile(buff, tokenId, url);
        }
        return (true, buff);
    }

    function _serializeProfile(bytes memory buff, uint tokenId, string memory url) internal pure returns (bytes memory) {
        buff = abi.encodePacked(
            buff,
            ZeroCopySink.WriteUint256(tokenId),
            ZeroCopySink.WriteVarBytes(bytes(url))
        );
        return buff;
    }

    function _calcEndIndex(uint start, uint length, uint total) internal pure returns (uint) {
        uint end = start + length - 1;
        if (end >= total) {
            end = total - 1;
        }
        return end;
    }
}