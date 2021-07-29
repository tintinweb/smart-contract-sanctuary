/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

// import "../../contracts/interfaces/IIdentity.sol";

contract Ransom {
    // Maps a request_hash (hash of the victimId and filenames) to a boolean (was it requested).
    mapping (bytes32 => bool) public requests;

    // Maps a response_hash (hash of the requestId and file keys) to a boolean.
    mapping (bytes32 => bool) public responses;

    // Maps honest attacker address to locked funds per request hash.
    mapping (address => mapping (bytes32 => uint256)) public payments;

    // Logs a new request by a new user
    event LogNewRequest(
        uint256 victimId,
        string[] fileNames,
        bytes32 requestHash
    );

    event LogFileKeys(
        bytes32 responseHash,
        bytes32[] fileKeys
    );

    event LogPaymentSubmitted(
        bytes32 responseHash,
        address attackerAddress,
        uint256 amount
    );

    event LogVictimKey(
        bytes32 responseHash,
        bytes32 victimKey
    );

    /**
      The Ransom contract constructor.
      It does nothing!
   */
    constructor() public { }

    function requestFileKeys(uint256 victimId, string[] calldata fileNames) external returns (bytes32) {
        // Compute request's hash.
        bytes32 requestHash = keccak256(abi.encode(victimId, fileNames));
        // Assert it was not requested before.
        require(!requests[requestHash], "REQUEST ALREADY EXIST");
        requests[requestHash] = true;
        emit LogNewRequest(victimId, fileNames, requestHash);
        return requestHash;
    }

    function submitFileKeys(uint256 victimId, string[] calldata fileNames, bytes32[] calldata sentFileKeys) external
        returns (bytes32) {
        // Compute request's hash.
        bytes32 requestHash = keccak256(abi.encode(victimId, fileNames));
        require(requests[requestHash], "INVALID REQUEST HASH");
        bytes32 responseHash = keccak256(abi.encode(requestHash, sentFileKeys));
        responses[responseHash] = true;
        emit LogFileKeys(responseHash, sentFileKeys);
        return responseHash;
    }

    function submitPayment(bytes32 responseHash, address honestAttacker) external payable {
        require(responses[responseHash], "INVALID RESPONSE HASH");
	    // TODO(Tom): time lock allowing the victim to get back funds.
        payments[honestAttacker][responseHash] += msg.value;
        emit LogPaymentSubmitted(responseHash, honestAttacker, msg.value);
    }

    function claimPayment(uint256 victimId, bytes32 victimKey, string[] calldata fileNames, bytes32[] calldata sentFileKeys) external {
        // Compute request's hash.
        bytes32 requestHash = keccak256(abi.encode(victimId, fileNames));
        require(requests[requestHash], "INVALID REQUEST HASH");
        bytes32 responseHash = keccak256(abi.encode(requestHash, sentFileKeys));
        require(responses[responseHash], "INVALID RESPONSE HASH");
        for(uint i=0; i < fileNames.length; i++){
            require(
                calculateFileKey(victimKey, fileNames[i]) == sentFileKeys[i],
                "INVALID VICTIM KEY"
            );
        }
        msg.sender.transfer(payments[msg.sender][responseHash]);
        emit LogVictimKey(responseHash, victimKey);
    }

    function calculateFileKey(bytes32 victimKey, string memory fileName)
    public pure returns (bytes32){
        bytes32 fileKey = keccak256(abi.encodePacked(victimKey, fileName));
        return fileKey;
    }
}