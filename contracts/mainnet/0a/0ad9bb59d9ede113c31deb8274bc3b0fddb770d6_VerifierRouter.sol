pragma solidity >=0.5.0 <=0.5.15;

import "./Ownable.sol";
import "./VerifierList.sol";

contract VerifierRouter is Ownable {
    VerifierList private verifierListContract;

    mapping(string => string) public routes;

    constructor(address _verifierListContract) public {
        verifierListContract = VerifierList(_verifierListContract);
    }

    function setVerifier(address _verifierListContract) external onlyOwner {
        verifierListContract = VerifierList(_verifierListContract);
    }

    function setRoute(string memory source, string memory target) public onlyOwner {
        routes[source] = target;
    }

    function verifierList(uint256 index) external view returns (string memory) {
        return verifierListContract.verifierList(index);
    }

    function verifiers(string memory verifierID) public view returns (address owner, string memory typeOfVerifier,string memory verifierParams,bool isCreated) {
        string memory targetVerifierID = verifierID;
        if (keccak256(abi.encodePacked(routes[verifierID])) != keccak256(abi.encodePacked(""))){
            targetVerifierID = routes[verifierID];
        }

        return verifierListContract.verifiers(targetVerifierID);
    }

    function getVerifierListCount() external view returns (uint256 verifierListCount) {
        return verifierListContract.getVerifierListCount();
    }
}