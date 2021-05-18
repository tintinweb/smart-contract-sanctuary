/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract BallotGarageISEP {
    uint256 constant LEADING = 0;
    uint256 constant MEMBER  = 1;
    uint256 constant LEAVING  = 2;
    uint256 private constant ONE = 10 ** 18;
    address private owner;
    uint256 public startTime; /* 16 april 2021 10h CET - time before which no vote can be registered */
    uint256 public endTime; /* 16 april 2021 18h CET - time after which no vote can be registered anymore,
    based on unix epoch */
    bytes32[] public candidateNames; // = [bytes32("JFCope"), bytes32("Fillon"), bytes32("Vote blanc")];
    mapping (bytes32 => uint256[3]) public candidateScores;
    uint256[3] public expectedNumberOfVoters;
    

    /* warning : if many candidates with the same name are sent, last one
    will overwrite the others */
    constructor(uint256 _startTime, uint256 _endTime, bytes32[] memory _candidateNames, uint256[3] memory _expectedNumberOfVoters) {
        require(_startTime < _endTime, "end time of the ballot must be after the start time");
        require(_endTime > block.timestamp, "end time of the ballot must be in the future");
        require(_candidateNames.length >= 2,
          "no ballot can be created with less than 2 candidates");

        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
        candidateNames = _candidateNames;
        expectedNumberOfVoters = _expectedNumberOfVoters;

        for (uint i = 0; i < candidateNames.length; i++){
            require(candidateNames[i][0] != 0,
              "every candidate must have a defined name");
        }
    }

    //contract core

    //modifiers
    modifier onlyOwner(){
        require(msg.sender == owner, "function reserved to the contract owner");
        _;
    }
    
    function getCandidateScore(bytes32 _candidateName) public view returns(uint256){
        uint256[3] memory scorePartsByWeight;
        
        if (expectedNumberOfVoters[LEADING] > 0)
            scorePartsByWeight[LEADING] = (ONE * 55 * candidateScores[_candidateName][LEADING]) / (100 * expectedNumberOfVoters[LEADING]);
    
        if (expectedNumberOfVoters[MEMBER] > 0)
            scorePartsByWeight[MEMBER] = (ONE * 35 * candidateScores[_candidateName][MEMBER]) / (100 * expectedNumberOfVoters[MEMBER]);

        if (expectedNumberOfVoters[LEAVING] > 0)
            scorePartsByWeight[LEAVING] = (ONE * 10 * candidateScores[_candidateName][LEAVING]) / (100 * expectedNumberOfVoters[LEAVING]);
        
        return(scorePartsByWeight[LEADING] + scorePartsByWeight[MEMBER] + scorePartsByWeight[LEAVING]);
    }

    //warning: doesn't check if candidate actually exists
    function vote(bytes32 _candidateName, uint8 weightCode) public onlyOwner{
        require(block.timestamp >= startTime, "ballot has not yet started");
        require(block.timestamp < endTime, "ballot must still be open");
        require(weightCode >= 0 && weightCode < 3, "incorrect weightCode");

        candidateScores[_candidateName][weightCode]++;
    }
}