/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

// import "../../contracts/interfaces/IIdentity.sol";

contract Ransom {
    // Maps honest attacker address to locked funds per response hash.
    mapping (address => mapping (bytes32 => uint256)) public payments;

    // Maps client address to timestamp funds are locked per response hash.
    mapping (address => mapping (bytes32 => uint256)) public payment_time;

    event LogPaymentSubmitted(
        uint256 victimId,
        string[] fileNames,
        bytes32[] sentFileKeys,
        bytes32 challengeHash,
        address honestAttacker,
        uint256 amount
    );

    event LogVictimKey(
        bytes32 challengeHash,
        bytes32 victimKey
    );

    event LogPaymentRetrieved(
        bytes32 challengeHash,
        address clientAddress,
        uint256 amount
    );

    /**
      The Ransom contract constructor.
      It does nothing!
   */
    constructor() public { }

    function submitPayment(uint256 victimId, string[] calldata fileNames, bytes32[] calldata fileKeys, address honestAttacker) external payable {
        bytes32 challengeHash = keccak256(abi.encode(victimId, fileNames, fileKeys));
        require(payments[honestAttacker][challengeHash] == 0, "ALREADY PAID");
        payments[honestAttacker][challengeHash] = msg.value;
        payment_time[msg.sender][challengeHash] = block.timestamp;
        emit LogPaymentSubmitted(victimId, fileNames, fileKeys, challengeHash, honestAttacker, msg.value);
    }

    function claimPayment(uint256 victimId, bytes32 victimKey, string[] calldata fileNames, bytes32[] calldata fileKeys) external {
        // Assert victim key is valid with respect to the challenge.
        for(uint i=0; i < fileNames.length; i++){
            require(
                calculateFileKey(victimKey, fileNames[i]) == fileKeys[i],
                "INVALID VICTIM KEY"
            );
        }

        bytes32 challengeHash = keccak256(abi.encode(victimId, fileNames, fileKeys));
        msg.sender.transfer(payments[msg.sender][challengeHash]);
        delete payments[msg.sender][challengeHash];
        emit LogVictimKey(challengeHash, victimKey);
    }

    function retrievePayment(bytes32 challengeHash, address honestAttacker) external {
        require(0 < payment_time[msg.sender][challengeHash], "NOT YOUR MONEY");
        require(payment_time[msg.sender][challengeHash] + 1 weeks < block.timestamp, "FUNDS LOCKED");
        msg.sender.transfer(payments[honestAttacker][challengeHash]);
        delete payments[honestAttacker][challengeHash];
        emit LogPaymentRetrieved(challengeHash, msg.sender, payments[msg.sender][challengeHash]);
    }

    function calculateFileKey(bytes32 victimKey, string memory fileName)
    public pure returns (bytes32){
        bytes32 fileKey = keccak256(abi.encodePacked(victimKey, fileName));
        return fileKey;
    }
}