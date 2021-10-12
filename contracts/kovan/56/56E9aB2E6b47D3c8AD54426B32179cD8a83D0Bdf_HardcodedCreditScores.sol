/// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract HardcodedCreditScores{
    mapping(address => uint8) public creditScores;
    mapping(uint8 => uint) public LTV;

    function setScore(address _who, uint8 _score) external{
        require(_score <= 10 && _score > 0, "score is between 1 and 10");
        creditScores[_who] = _score;
    }

    function setLTV(uint8 _score, uint _ltv) external{
        LTV[_score] = _ltv;
    }


}