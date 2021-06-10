/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IProofOfHumanity {
    function addSubmissionManually(address[] calldata _submissionIDs, string[] calldata _evidence, string[] calldata _names) external;
    function removeSubmissionManually(address _submissionID) external;
}

contract GovernorProxy{
    IProofOfHumanity public PoH;
    address public owner = msg.sender;
    constructor(IProofOfHumanity _PoH) public {
        PoH = _PoH;
    }
    function addHumans(address[] calldata _submissionIDs, string[] calldata _evidences, string[] calldata _names) external {
        PoH.addSubmissionManually(_submissionIDs, _evidences, _names);
    }
    function removeHuman(address _submissionID) external {
        PoH.removeSubmissionManually(_submissionID);
    }
    function changePoH(IProofOfHumanity _PoH) external {
        require(msg.sender == owner);
        PoH = _PoH;
    }
    function executeGovernorCall(bytes calldata _data) external {
        require(msg.sender == owner);
        address(PoH).call(_data);
    }
}