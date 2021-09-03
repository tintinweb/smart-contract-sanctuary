/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Verify {
    address private owner_;
    address private validator_;
    mapping(bytes32 => bool) private isUsed;

    constructor() public {
        owner_ = msg.sender;
        validator_ = msg.sender;
    }

    function setValidator(address validator) public {
        require(msg.sender == owner_, "only owner");
        validator_ = validator;
    }

    function verify(
        uint256 _saleNum,
        uint256 _amount,
        bytes32 _sHash,
        bytes memory _sign
    ) public {
        require(_sign.length == 65, "invalid signature length");

        bytes32 _hash =
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(
                        abi.encodePacked(
                            "PRESALEMONEYFTW",
                            _saleNum,
                            _amount,
                            _sHash
                        )
                    )
                )
            );

        require(isUsed[_hash] == false, "used token");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }

        require(ecrecover(_hash, v, r, s) == validator_, "unknown sign");
        isUsed[_hash] = true;
    }
}