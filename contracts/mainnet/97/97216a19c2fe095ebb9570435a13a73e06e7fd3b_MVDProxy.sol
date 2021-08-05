pragma solidity ^0.6.0;

import "./IMVDProxy.sol";
import "./IMVDFunctionalityProposalManager.sol";
import "./IMVDFunctionalityProposal.sol";
import "./IERC20.sol";
import "./IMVDFunctionalityModelsManager.sol";
import "./ICommonUtilities.sol";
import "./IMVDFunctionalitiesManager.sol";
import "./IMVDWallet.sol";
import "./IERC721.sol";

contract MVDProxy is IMVDProxy {

    address[] private _delegates;

    constructor(address votingTokenAddress, address functionalityProposalManagerAddress, address stateHolderAddress, address functionalityModelsManagerAddress, address functionalitiesManagerAddress, address walletAddress, address doubleProxyAddress) public {
        if(votingTokenAddress == address(0)) {
            return;
        }
        init(votingTokenAddress, functionalityProposalManagerAddress, stateHolderAddress, functionalityModelsManagerAddress, functionalitiesManagerAddress, walletAddress, doubleProxyAddress);
    }

    function init(address votingTokenAddress, address functionalityProposalManagerAddress, address stateHolderAddress, address functionalityModelsManagerAddress, address functionalitiesManagerAddress, address walletAddress, address doubleProxyAddress) public override {

        require(_delegates.length == 0, "Init already called!");

        _delegates = new address[](7);

        IMVDProxyDelegate(_delegates[0] = votingTokenAddress).setProxy();

        IMVDProxyDelegate(_delegates[1] = functionalityProposalManagerAddress).setProxy();

        IMVDProxyDelegate(_delegates[2] = stateHolderAddress).setProxy();

        _delegates[3] = functionalityModelsManagerAddress;

        IMVDProxyDelegate(_delegates[4] = functionalitiesManagerAddress).setProxy();

        IMVDProxyDelegate(_delegates[5] = walletAddress).setProxy();

        IMVDProxyDelegate(_delegates[6] = doubleProxyAddress).setProxy();
    }

    receive() external payable {
        revert("No Eth Accepted");
    }

    function getDelegates() public override view returns(address[] memory) {
        return _delegates;
    }

    function getToken() public override view returns(address) {
        return _delegates[0];
    }

    function getMVDFunctionalityProposalManagerAddress() public override view returns(address) {
        return _delegates[1];
    }

    function getStateHolderAddress() public override view returns(address) {
        return _delegates[2];
    }

    function getMVDFunctionalityModelsManagerAddress() public override view returns(address) {
        return _delegates[3];
    }

    function getMVDFunctionalitiesManagerAddress() public override view returns(address) {
        return _delegates[4];
    }

    function getMVDWalletAddress() public override view returns(address) {
        return _delegates[5];
    }

    function getDoubleProxyAddress() public override view returns(address) {
        return _delegates[6];
    }

    function flushToWallet(address tokenAddress, bool is721, uint256 tokenId) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Unauthorized action!");
        if(tokenAddress == address(0)) {
            payable(_delegates[5]).transfer(payable(address(this)).balance);
            return;
        }
        if(is721) {
            IERC721(tokenAddress).transferFrom(address(this), _delegates[5], tokenId);
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        token.transfer(_delegates[5], token.balanceOf(address(this)));
    }

    function setDelegate(uint256 position, address newAddress) public override returns(address oldAddress) {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Unauthorized action!");
        require(newAddress != address(0), "Cannot set void address!");
        if(position == 5) {
            IMVDWallet(_delegates[5]).setNewWallet(payable(newAddress), _delegates[0]);
        }
        oldAddress = _delegates[position];
        _delegates[position] = newAddress;
        if(position != 3) {
            IMVDProxyDelegate(oldAddress).setProxy();
            IMVDProxyDelegate(newAddress).setProxy();
        }
        emit DelegateChanged(position, oldAddress, newAddress);
    }

    function changeProxy(address newAddress, bytes memory initPayload) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Unauthorized action!");
        require(newAddress != address(0), "Cannot set void address!");
        for(uint256 i = 0; i < _delegates.length; i++) {
            if(i != 3) {
                IMVDProxyDelegate(_delegates[i]).setProxy();
            }
        }
        _delegates = new address[](0);
        emit ProxyChanged(newAddress);
        (bool response,) = newAddress.call(initPayload);
        require(response, "New Proxy initPayload failed!");
    }

    function isValidProposal(address proposal) public override view returns (bool) {
        return IMVDFunctionalityProposalManager(_delegates[1]).isValidProposal(proposal);
    }

    function isAuthorizedFunctionality(address functionality) public override view returns(bool) {
        return IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(functionality);
    }

    function newProposal(string memory codeName, bool emergency, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string memory methodSignature, string memory returnAbiParametersArray, bool isInternal, bool needsSender, string memory replaces) public override returns(address proposalAddress) {
        emergencyBehavior(emergency);

        IMVDFunctionalityModelsManager(_delegates[3]).checkWellKnownFunctionalities(codeName, submitable, methodSignature, returnAbiParametersArray, isInternal, needsSender, replaces);

        IMVDFunctionalitiesManager functionalitiesManager = IMVDFunctionalitiesManager(_delegates[4]);

        IMVDFunctionalityProposal proposal = IMVDFunctionalityProposal(proposalAddress = IMVDFunctionalityProposalManager(_delegates[1]).newProposal(codeName, location, methodSignature, returnAbiParametersArray, replaces));
        proposal.setCollateralData(emergency, sourceLocation, sourceLocationId, submitable, isInternal, needsSender, msg.sender, functionalitiesManager.hasFunctionality("getVotesHardCap") ? toUint256(read("getVotesHardCap", "")) : 0);

        if(functionalitiesManager.hasFunctionality("onNewProposal")) {
            submit("onNewProposal", abi.encode(proposalAddress));
        }

        if(!IMVDFunctionalitiesManager(_delegates[4]).hasFunctionality("startProposal") || !IMVDFunctionalitiesManager(_delegates[4]).hasFunctionality("disableProposal")) {
            proposal.start();
        }

        emit Proposal(proposalAddress);
    }

    function emergencyBehavior(bool emergency) private {
        if(!emergency) {
            return;
        }
        (address loc, , string memory meth,,) = IMVDFunctionalitiesManager(_delegates[4]).getFunctionalityData("getEmergencySurveyStaking");
        (, bytes memory payload) = loc.staticcall(abi.encodeWithSignature(meth));
        uint256 staking = toUint256(payload);
        if(staking > 0) {
            IERC20(_delegates[0]).transferFrom(msg.sender, address(this), staking);
        }
    }

    function startProposal(address proposalAddress) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Unauthorized action!");
        (address location,,,,) = IMVDFunctionalitiesManager(_delegates[4]).getFunctionalityData("startProposal");
        require(location == msg.sender, "Only startProposal Functionality can enable a delayed proposal");
        require(IMVDFunctionalityProposalManager(_delegates[1]).isValidProposal(proposalAddress), "Invalid Proposal Address!");
        IMVDFunctionalityProposal(proposalAddress).start();
    }

    function disableProposal(address proposalAddress) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Unauthorized action!");
        (address location,,,,) = IMVDFunctionalitiesManager(_delegates[4]).getFunctionalityData("disableProposal");
        require(location == msg.sender, "Only disableProposal Functionality can disable a delayed proposal");
        IMVDFunctionalityProposal(proposalAddress).disable();
    }

    function transfer(address receiver, uint256 value, address token) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Only functionalities can transfer Proxy balances!");
        IMVDWallet(_delegates[5]).transfer(receiver, value, token);
    }

    function transfer721(address receiver, uint256 tokenId, bytes memory data, bool safe, address token) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Only functionalities can transfer Proxy balances!");
        IMVDWallet(_delegates[5]).transfer(receiver, tokenId, data, safe, token);
    }

    function setProposal() public override {

        IMVDFunctionalityProposalManager(_delegates[1]).checkProposal(msg.sender);

        emit ProposalCheck(msg.sender);

        IMVDFunctionalitiesManager functionalitiesManager = IMVDFunctionalitiesManager(_delegates[4]);

        (address addressToCall,,string memory methodSignature,,) = functionalitiesManager.getFunctionalityData("checkSurveyResult");

        (bool surveyResult, bytes memory response) = addressToCall.staticcall(abi.encodeWithSignature(methodSignature, msg.sender));

        surveyResult = toUint256(response) > 0;

        bool collateralCallResult = true;
        (addressToCall,,methodSignature,,) = functionalitiesManager.getFunctionalityData("proposalEnd");
        if(addressToCall != address(0)) {
            functionalitiesManager.setCallingContext(addressToCall);
            (collateralCallResult,) = addressToCall.call(abi.encodeWithSignature(methodSignature, msg.sender, surveyResult));
            functionalitiesManager.clearCallingContext();
        }

        IMVDFunctionalityProposal proposal = IMVDFunctionalityProposal(msg.sender);

        uint256 staking = 0;
        address tokenAddress = _delegates[0];
        address walletAddress = _delegates[5];

        if(proposal.isEmergency()) {
            (addressToCall,,methodSignature,,) = functionalitiesManager.getFunctionalityData("getEmergencySurveyStaking");
            (, response) = addressToCall.staticcall(abi.encodeWithSignature(methodSignature));
            staking = toUint256(response);
        }

        if(!surveyResult) {
            if(collateralCallResult) {
                proposal.set();
                emit ProposalSet(msg.sender, surveyResult);
                if(staking > 0) {
                    IERC20(tokenAddress).transfer(walletAddress, staking);
                }
            }
            return;
        }

        if(collateralCallResult) {
            try functionalitiesManager.setupFunctionality(msg.sender) returns(bool managerResult) {
                collateralCallResult = managerResult;
            } catch {
                collateralCallResult = false;
            }
        }

        if(collateralCallResult) {
            proposal.set();
            emit ProposalSet(msg.sender, surveyResult);
            if(staking > 0) {
                IERC20(tokenAddress).transfer(surveyResult ? proposal.getProposer() : walletAddress, staking);
            }
        }
    }

    function read(string memory codeName, bytes memory data) public override view returns(bytes memory returnData) {

        (address location, bytes memory payload) = IMVDFunctionalitiesManager(_delegates[4]).preConditionCheck(codeName, data, 0, msg.sender, 0);

        bool ok;
        (ok, returnData) = location.staticcall(payload);

        require(ok, "Failed to read from functionality");
    }

    function submit(string memory codeName, bytes memory data) public override payable returns(bytes memory returnData) {

        if(msg.value > 0) {
            payable(_delegates[5]).transfer(msg.value);
        }

        IMVDFunctionalitiesManager manager = IMVDFunctionalitiesManager(_delegates[4]);
        (address location, bytes memory payload) = manager.preConditionCheck(codeName, data, 1, msg.sender, msg.value);

        bool changed = manager.setCallingContext(location);

        bool ok;
        (ok, returnData) = location.call(payload);

        if(changed) {
            manager.clearCallingContext();
        }
        require(ok, "Failed to submit functionality");
    }

    function callFromManager(address location, bytes memory payload) public override returns(bool, bytes memory) {
        require(msg.sender == _delegates[4], "Only Functionalities Manager can call this!");
        return location.call(payload);
    }

    function emitFromManager(string memory codeName, address proposal, string memory replaced, address replacedSourceLocation, uint256 replacedSourceLocationId, address location, bool submitable, string memory methodSignature, bool isInternal, bool needsSender, address proposalAddress) public override {
        require(msg.sender == _delegates[4], "Only Functionalities Manager can call this!");
        emit FunctionalitySet(codeName, proposal, replaced, replacedSourceLocation, replacedSourceLocationId, location, submitable, methodSignature, isInternal, needsSender, proposalAddress);
    }

    function emitEvent(string memory eventSignature, bytes memory firstIndex, bytes memory secondIndex, bytes memory data) public override {
        require(IMVDFunctionalitiesManager(_delegates[4]).isAuthorizedFunctionality(msg.sender), "Only authorized functionalities can emit events!");
        emit Event(eventSignature, keccak256(firstIndex), keccak256(secondIndex), data);
    }

    function compareStrings(string memory a, string memory b) private pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function toUint256(bytes memory bs) internal pure returns(uint256 x) {
        if(bs.length >= 32) {
            assembly {
                x := mload(add(bs, add(0x20, 0)))
            }
        }
    }
}

interface IMVDProxyDelegate {
    function setProxy() external;
}