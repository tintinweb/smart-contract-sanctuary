/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Sign {
    address VERIFY_ADDRESS = 0x70B3f80B88EDc8893d3364038CEdD6A0244B4a80;

    function verifyURISignature(
        string memory uri,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        uint256 len = getLength(uri);
        bytes memory encoded = encode(uri, len);
        bytes32 h = hash(encoded);
        return recoverAddress(h, v, r, s) == getVerifyAddress();
    }

    function getLength(string memory uri) public pure returns (uint256) {
        return bytes(uri).length;
    }

    function encode(string memory uri, uint256 len)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                uint2str(len),
                uri
            );
    }

    function hash(bytes memory value) public pure returns (bytes32) {
        return keccak256(value);
    }

    function recoverAddress(
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        return ecrecover(h, v, r, s);
    }

    function getVerifyAddress() public view returns (address) {
        return VERIFY_ADDRESS;
    }

    function uint2str(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}