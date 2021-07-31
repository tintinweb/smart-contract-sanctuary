/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

pragma solidity ^0.4.2;

contract Election {
    string public candidateName;

    function Election () public {
        candidateName = "Candidate 1";
    }

    function setCandidate (string _name) public {
        candidateName = _name;
    }
}