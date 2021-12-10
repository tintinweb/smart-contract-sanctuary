/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IInvestor {
    function borrowFulfill(
        uint256,
        bytes32,
        bytes memory
    ) external;
}

/// @dev for TESTING ONLY
contract HardcodedCreditScores {

    mapping(uint256 => uint16) private creditScores;
    mapping(uint16 => uint256) public LTV;
    mapping(bytes32 => requestObject) callerIDs;
    uint256 private nonce = 0;

    struct requestObject {
        uint256 loanID;
        uint256 tokenID;
        bytes32 hash;
        bytes signature;
        address investor;
    }

    function getCurrentScore(uint256 tokenId) public view returns (uint16) {
        return (creditScores[tokenId]);
    }

    function getLatestScore(
        uint256 tokenId,
        uint256 loanID,
        bytes32 hash,
        bytes memory signature
    ) public returns (uint16) {
        callerIDs[keccak256(abi.encodePacked(nonce))] = requestObject(
            loanID,
            tokenId,
            hash,
            signature,
            msg.sender
        );
        fulfill(keccak256(abi.encodePacked(nonce)), 5);
        nonce++;
    }

    function fulfill(bytes32 _requestId, uint16 _score) public {
        requestObject memory c = callerIDs[_requestId];
        creditScores[c.tokenID] = _score;
        // makes borrow fulfill optional
        if (c.loanID != 0) {
            IInvestor(c.investor).borrowFulfill(c.loanID, c.hash, c.signature);
        }
    }

    function setLTV(uint8 _score, uint256 _ltv) external {
        LTV[_score] = _ltv;
    }
}