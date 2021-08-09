/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract BytesStorage {
    struct PixelData {
        bytes data;
        bytes32 h;
    }

    PixelData[] private pixeldb;
    mapping(bytes32 => PixelData) pixelmap;
    event NewPixelArt(uint256 index, bytes32 h);

    function hash(bytes calldata data) external pure returns (bytes32) {
        return sha256(data);
    }

    function store(bytes calldata data) external {
        bytes32 h = sha256(data);
        pixeldb.push(PixelData(data, h));
        emit NewPixelArt(pixeldb.length - 1, h);
    }

    function query(uint256 index) external view returns (bytes memory, bytes32) {
        PixelData memory p =  pixeldb[index];
        return (p.data, p.h);
    }

    function hashCheck(bytes32 h) external view returns (bool) {
        return pixelmap[h].h.length > 0; 
    }
}