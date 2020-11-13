pragma solidity ^0.6.0;

interface IMVDFunctionalityProposalManager {
    function newProposal(string calldata codeName, address location, string calldata methodSignature, string calldata returnAbiParametersArray, string calldata replaces) external returns(address);
    function checkProposal(address proposalAddress) external;
    function getProxy() external view returns (address);
    function setProxy() external;
    function isValidProposal(address proposal) external view returns (bool);
}