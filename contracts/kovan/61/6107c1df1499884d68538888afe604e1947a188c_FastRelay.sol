/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// SPDX-License-Identifier: NLPL
pragma solidity ^0.8.0;

contract FastRelay {
    address admin;
    modifier auth {
        require(msg.sender == admin, "401 unauthorized");
        _;
    }

    mapping(address => uint256) public oracle;
    mapping(uint8 => address) public slot;

    function lift(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "400 bad request - zero address");
            oracle[a[i]] = 1;
        }
    }

    function drop(address[] calldata a) external auth {
        for (uint i = 0; i < a.length; i++) {
            oracle[a[i]] = 0;
        }
    }

    uint256 public bar = 2;

    function relay(
        address target_, bytes memory data_, address sender_, uint256 nonce_,
        uint8[] calldata v_, bytes32[] calldata r_, bytes32[] calldata s_) external returns (bytes memory res)
    {
        require(v_.length < bar, "400 bad request - bar too low");

        for (uint i = 0; i < bar; i++) {
            address signer = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(target_, data_, sender_, nonce_)))),
                v_[i], r_[i], s_[i]
            );
            require(oracle[signer] == 1, "400 bad request - unauthorized oracle");
        }

        (bool ok, bytes memory ret) = target_.call(data_);
        require(ok, "500 internal server error - relay call failed");

        return ret;
    }
}