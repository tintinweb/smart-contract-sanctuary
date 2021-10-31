/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: MIT

// SVG exporter for Etholvants - 0x1fFF1e9e963f07AC4486503E5a35e71f4e9Fb9FD

pragma solidity ^0.8.0;


interface IEtholvants {
	function getCellPositions(
        uint256 tokenId,
        uint256 cursor,
        uint256 limit
    ) external view returns (uint256, uint256[] memory);
	function getNumCells(uint256 tokenId) external view returns (uint256);
	function getSize(uint256 numCells) external pure returns (uint256);
}

contract EtholvantsSVG {
	address public etholvants = 0x1fFF1e9e963f07AC4486503E5a35e71f4e9Fb9FD;

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

	/**
     * @dev returns the SVG representation of the Etholvant.
	 *  result is paginated.
     *  pass cursor as 0 at the beginning.
     *  cursor will be returned 0 at the end.
     */
	function getTokenSVG(uint tokenId, uint cursor, uint limit) public view returns (uint, string memory) {
		uint[] memory cells;
		string memory svg;
		IEtholvants ethol = IEtholvants(etholvants);
		uint numCells = ethol.getNumCells(tokenId);
		uint size = ethol.getSize(numCells);

		if (cursor == 0) {
			string memory sizeStr = uint2str(size);
			svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ', sizeStr, ' ', sizeStr, '"><path d="'));
		}
		(cursor, cells) = ethol.getCellPositions(tokenId, cursor, limit);
		for (uint i=0; i<cells.length; i++) {
			uint x = cells[i] % size;
			uint y = cells[i] / size;
			svg = string(abi.encodePacked(svg, 'M', uint2str(x), ',', uint2str(y), 'v1h1v-1'));
		}

		if (cursor == 0) {
			svg = string(abi.encodePacked(svg, '"/></svg>'));
		}
		return (cursor, svg);
	}
}