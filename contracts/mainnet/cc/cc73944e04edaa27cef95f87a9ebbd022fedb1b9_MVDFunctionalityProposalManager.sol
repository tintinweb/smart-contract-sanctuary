pragma solidity ^0.6.0;

import "./IMVDFunctionalityProposalManager.sol";
import "./IMVDProxy.sol";
import "./MVDFunctionalityProposal.sol";
import "./IMVDFunctionalitiesManager.sol";

contract MVDFunctionalityProposalManager is IMVDFunctionalityProposalManager {

    address private _proxy;

    mapping(address => bool) private _proposals;

    modifier onlyProxy() {
        require(msg.sender == address(_proxy), "Only Proxy can call this functionality");
        _;
    }

    function newProposal(string memory codeName, address location, string memory methodSignature, string memory returnAbiParametersArray, string memory replaces) public override onlyProxy returns(address) {
        return setProposal(codeName, location, methodSignature, replaces, address(new MVDFunctionalityProposal(codeName, location, methodSignature, returnAbiParametersArray, replaces, _proxy)));
    }

    function preconditionCheck(string memory codeName, address location, string memory methodSignature, string memory replaces) private view {

        bool hasCodeName = !compareStrings(codeName, "");
        bool hasReplaces = !compareStrings(replaces, "");

        require((hasCodeName || !hasCodeName && !hasReplaces) ? location != address(0) : true, "Cannot have zero address for functionality to set or one time functionality to call");

        require(location == address(0) || !compareStrings(methodSignature, ""), "Cannot have empty string for methodSignature");

        require(hasCodeName || hasReplaces ? true : compareStrings(methodSignature, "callOneTime(address)"), "One Time Functionality method signature allowed is callOneTime(address)");

        IMVDFunctionalitiesManager functionalitiesManager = IMVDFunctionalitiesManager(IMVDProxy(_proxy).getMVDFunctionalitiesManagerAddress());

        require(hasCodeName && functionalitiesManager.hasFunctionality(codeName) ? compareStrings(codeName, replaces) : true, "codeName is already used by another functionality");

        require(hasReplaces ? functionalitiesManager.hasFunctionality(replaces) : true, "Cannot replace unexisting or inactive functionality");
    }

    function setProposal(string memory codeName, address location, string memory methodSignature, string memory replaces, address proposalAddress) private returns(address) {

        preconditionCheck(codeName, location, methodSignature, replaces);

        _proposals[proposalAddress] = true;

        return proposalAddress;
    }

    function checkProposal(address proposalAddress) public override onlyProxy {
        require(_proposals[proposalAddress], "Unauthorized Access!");

        IMVDFunctionalityProposal proposal = IMVDFunctionalityProposal(proposalAddress);

        uint256 surveyEndBlock = proposal.getSurveyEndBlock();

        require(surveyEndBlock > 0, "Survey was not started!");

        require(!proposal.isDisabled(), "Proposal is disabled!");

        if(!proposal.isVotesHardCapReached()) {
            require(block.number >= surveyEndBlock, "Survey is still running!");
        }

        require(!proposal.isTerminated(), "Survey already terminated!");
    }

    function isValidProposal(address proposal) public override view returns (bool) {
        return _proposals[proposal];
    }

    function getProxy() public override view returns (address) {
        return _proxy;
    }

    function setProxy() public override {
        require(_proxy == address(0) || _proxy == msg.sender, _proxy != address(0) ? "Proxy already set!" : "Only Proxy can toggle itself!");
        _proxy = _proxy == address(0) ?  msg.sender : address(0);
    }

    function compareStrings(string memory a, string memory b) private pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}