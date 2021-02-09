/*
  Copyright 2019,2020 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
pragma solidity ^0.6.11;

import "PuzzleSubmission.sol";
import "ProgramHashMgmt.sol";
import "IFactRegistry.sol";

contract CairoPuzzleSubmission is ProgramHashMgmt, PuzzleSubmission {
    event SuccessfulSubmission(
        bytes32 programHash,
        address submitter,
        uint256 timestap,
        string submitterName,
        address rewardAddress
    );

    IFactRegistry cairoVerifier;

    constructor(address verifierAddress) public {
        cairoVerifier = IFactRegistry(verifierAddress);
    }

    function getSubmittersCount(bytes32 programHash) public
        view
        returns(uint256)
    {
        return submissionLists[programHash].length;
    }

    /*
      Provides the submission details of the submitter in the n-th place for the given puzzle.
      The place is zero based.
    */
    function getNthPlace(bytes32 programHash, uint256 place)
        external
        view
        returns(address, address, string memory, uint256)
    {
        require(isRegisteredPuzzle(programHash), "PROGRAM_HASH_DOES_NOT_BELONG_TO_A_PUZZLE");
        require(place < getSubmittersCount(programHash) , "INDEX_ERROR");
        SubmissionDetails storage submission = submissionLists[programHash][place];
        return (
            submission.sender,
            submission.rewardAddress,
            submission.submitterName,
            submission.timestamp);
    }

    /*
      Registers a puzzle solution.
      This function should be called only after the GPS fact is successfully registered on-chain.
      You can use calcSubmissionFact to get the value of the fact expected by this contract,
      and make sure it's registered on the GPS contract, using its isValid() method.

      rewardAddress - The Ethereum MAINNET address, to which rewards should be sent.
      submitterName - The name of the submitter.
      programHash - The program hash of the puzzle.
    */
    function submitPuzzleSolution(
        address rewardAddress,
        string calldata submitterName,
        bytes32 programHash)
        external
    {
        require(isRegisteredPuzzle(programHash), "PROGRAM_HASH_DOES_NOT_BELONG_TO_A_PUZZLE");
        bytes32 submissionFact = calcSubmissionFact(programHash, msg.sender);
        require(cairoVerifier.isValid(submissionFact), "CAIRO_FACT_NOT_REGISTERED_IN_GPS_CONTRACT");
        require(
            submitters[programHash][msg.sender] == 0,
            "REQUESTED_REGISTRATION_ALREADY_PERFORMED");
        recordSubmission(rewardAddress, submitterName, programHash);

        emit SuccessfulSubmission(
            programHash,
            msg.sender,
            block.timestamp,
            submitterName,
            rewardAddress);
    }

    function calcSubmissionFact(bytes32 programHash, address sender)
        public
        pure
        returns(bytes32)
    {
        bytes32 senderHash = keccak256(abi.encode(uint256(sender)));
        return keccak256(abi.encode(programHash, senderHash));
    }
}