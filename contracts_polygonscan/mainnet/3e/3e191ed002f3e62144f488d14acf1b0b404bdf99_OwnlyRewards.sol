// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";
import "./Ownable.sol";

contract OwnlyRewards is ERC1155PresetMinterPauser, Ownable {
    string private _name;
    string private _symbol;

    constructor() ERC1155PresetMinterPauser("https://ownly.io/nft/rewards/api/") {
        _name = "Ownly Rewards";
        _symbol = "OWNLY";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(uri(tokenId), uint2str(tokenId)));
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
}