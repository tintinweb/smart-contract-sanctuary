pragma solidity ^0.6.0;

interface IMVDFunctionalityProposal {

    function init(string calldata codeName, address location, string calldata methodSignature, string calldata returnAbiParametersArray, string calldata replaces, address proxy) external;
    function setCollateralData(bool emergency, address sourceLocation, uint256 sourceLocationId, bool submitable, bool isInternal, bool needsSender, address proposer, uint256 votesHardCap) external;

    function getProxy() external view returns(address);
    function getCodeName() external view returns(string memory);
    function isEmergency() external view returns(bool);
    function getSourceLocation() external view returns(address);
    function getSourceLocationId() external view returns(uint256);
    function getLocation() external view returns(address);
    function isSubmitable() external view returns(bool);
    function getMethodSignature() external view returns(string memory);
    function getReturnAbiParametersArray() external view returns(string memory);
    function isInternal() external view returns(bool);
    function needsSender() external view returns(bool);
    function getReplaces() external view returns(string memory);
    function getProposer() external view returns(address);
    function getSurveyEndBlock() external view returns(uint256);
    function getSurveyDuration() external view returns(uint256);
    function isVotesHardCapReached() external view returns(bool);
    function getVotesHardCapToReach() external view returns(uint256);
    function toJSON() external view returns(string memory);
    function getVote(address addr) external view returns(uint256 accept, uint256 refuse);
    function getVotes() external view returns(uint256, uint256);
    function start() external;
    function disable() external;
    function isDisabled() external view returns(bool);
    function isTerminated() external view returns(bool);
    function accept(uint256 amount) external;
    function retireAccept(uint256 amount) external;
    function moveToAccept(uint256 amount) external;
    function refuse(uint256 amount) external;
    function retireRefuse(uint256 amount) external;
    function moveToRefuse(uint256 amount) external;
    function retireAll() external;
    function withdraw() external;
    function terminate() external;
    function set() external;

    event Accept(address indexed voter, uint256 amount);
    event RetireAccept(address indexed voter, uint256 amount);
    event MoveToAccept(address indexed voter, uint256 amount);
    event Refuse(address indexed voter, uint256 amount);
    event RetireRefuse(address indexed voter, uint256 amount);
    event MoveToRefuse(address indexed voter, uint256 amount);
    event RetireAll(address indexed voter, uint256 amount);
}