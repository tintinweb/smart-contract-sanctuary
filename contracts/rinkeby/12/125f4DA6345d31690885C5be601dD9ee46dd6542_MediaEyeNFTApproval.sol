// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMediaEyeNFT {
    function setApprovalForAll(address operator, bool approved) external;
}

contract MediaEyeNFTApproval {
    function setApprovalForAllMultiple(address[] memory _tokens, address[] memory _operators, bool[] memory _approved) external {
        require(_tokens.length == _approved.length, "Length of token and approved arrays must be equal");
        require(_tokens.length > 0, "Must have at least one token");
        require(_operators.length > 0, "Must have at least one operator");

        for (uint i = 0; i < _operators.length; i++) {
            for (uint j = 0; j < _tokens.length; j++) {
                IMediaEyeNFT(_tokens[j]).setApprovalForAll(_operators[i], _approved[j]);
            }
        }
    }
}