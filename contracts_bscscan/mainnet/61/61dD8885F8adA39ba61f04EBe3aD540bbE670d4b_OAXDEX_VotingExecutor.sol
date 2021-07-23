/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/interfaces/IOAXDEX_VotingExecutor.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOAXDEX_VotingExecutor {
    function execute(bytes32[] calldata params) external;
}


// File contracts/interfaces/IOAXDEX_Governance.sol


pragma solidity =0.6.11;

interface IOAXDEX_Governance {

    struct NewStake {
        uint256 amount;
        uint256 timestamp;
    }
    struct VotingConfig {
        uint256 minExeDelay;
        uint256 minVoteDuration;
        uint256 maxVoteDuration;
        uint256 minOaxTokenToCreateVote;
        uint256 minQuorum;
    }

    event ParamSet(bytes32 indexed name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event AddVotingConfig(bytes32 name, 
        uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    event SetVotingConfig(bytes32 indexed configName, bytes32 indexed paramName, uint256 minExeDelay);

    event Stake(address indexed who, uint256 value);
    event Unstake(address indexed who, uint256 value);

    event NewVote(address indexed vote);
    event NewPoll(address indexed poll);
    event Vote(address indexed account, address indexed vote, uint256 option);
    event Poll(address indexed account, address indexed poll, uint256 option);
    event Executed(address indexed vote);
    event Veto(address indexed vote);

    function votingConfigs(bytes32) external view returns (uint256 minExeDelay,
        uint256 minVoteDuration,
        uint256 maxVoteDuration,
        uint256 minOaxTokenToCreateVote,
        uint256 minQuorum);
    function votingConfigProfiles(uint256) external view returns (bytes32);

    function oaxToken() external view returns (address);
    function freezedStake(address) external view returns (uint256 amount, uint256 timestamp);
    function stakeOf(address) external view returns (uint256);
    function totalStake() external view returns (uint256);

    function votingRegister() external view returns (address);
    function votingExecutor(uint256) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256);
    function isVotingExecutor(address) external view returns (bool);
    function admin() external view returns (address);
    function minStakePeriod() external view returns (uint256);

    function voteCount() external view returns (uint256);
    function votingIdx(address) external view returns (uint256);
    function votings(uint256) external view returns (address);


	function votingConfigProfilesLength() external view returns(uint256);
	function getVotingConfigProfiles(uint256 start, uint256 length) external view returns(bytes32[] memory profiles);
    function getVotingParams(bytes32) external view returns (uint256 _minExeDelay, uint256 _minVoteDuration, uint256 _maxVoteDuration, uint256 _minOaxTokenToCreateVote, uint256 _minQuorum);

    function setVotingRegister(address _votingRegister) external;
    function votingExecutorLength() external view returns (uint256);
    function initVotingExecutor(address[] calldata _setVotingExecutor) external;
    function setVotingExecutor(address _setVotingExecutor, bool _bool) external;
    function initAdmin(address _admin) external;
    function setAdmin(address _admin) external;
    function addVotingConfig(bytes32 name, uint256 minExeDelay, uint256 minVoteDuration, uint256 maxVoteDuration, uint256 minOaxTokenToCreateVote, uint256 minQuorum) external;
    function setVotingConfig(bytes32 configName, bytes32 paramName, uint256 paramValue) external;
    function setMinStakePeriod(uint _minStakePeriod) external;

    function stake(uint256 value) external;
    function unlockStake() external;
    function unstake(uint256 value) external;
    function allVotings() external view returns (address[] memory);
    function getVotingCount() external view returns (uint256);
    function getVotings(uint256 start, uint256 count) external view returns (address[] memory _votings);

    function isVotingContract(address votingContract) external view returns (bool);

    function getNewVoteId() external returns (uint256);
    function newVote(address vote, bool isExecutiveVote) external;
    function voted(bool poll, address account, uint256 option) external;
    function executed() external;
    function veto(address voting) external;
    function closeVote(address vote) external;
}


// File contracts/interfaces/IOAXDEX_Administrator.sol


pragma solidity =0.6.11;

interface IOAXDEX_Administrator {

    event SetMaxAdmin(uint256 maxAdmin);
    event AddAdmin(address admin);
    event RemoveAdmin(address admin);

    event VotedVeto(address indexed admin, address indexed votingContract, bool YorN);
    event VotedFactoryShutdown(address indexed admin, address indexed factory, bool YorN);
    event VotedFactoryRestart(address indexed admin, address indexed factory, bool YorN);
    event VotedPairShutdown(address indexed admin, address indexed pair, bool YorN);
    event VotedPairRestart(address indexed admin, address indexed pair, bool YorN);

    function governance() external view returns (address);
    function allAdmins() external view returns (address[] memory);
    function maxAdmin() external view returns (uint256);
    function admins(uint256) external view returns (address);
    function adminsIdx(address) external view returns (uint256);

    function vetoVotingVote(address, address) external view returns (bool);
    function factoryShutdownVote(address, address) external view returns (bool);
    function factoryRestartVote(address, address) external view returns (bool);
    function pairShutdownVote(address, address) external view returns (bool);
    function pairRestartVote(address, address) external view returns (bool);

    function setMaxAdmin(uint256 _maxAdmin) external;
    function addAdmin(address _admin) external;
    function removeAdmin(address _admin) external;

    function vetoVoting(address votingContract, bool YorN) external;
    function getVetoVotingVote(address votingContract) external view returns (bool[] memory votes);
    function executeVetoVoting(address votingContract) external;

    function factoryShutdown(address factory, bool YorN) external;
    function getFactoryShutdownVote(address factory) external view returns (bool[] memory votes);
    function executeFactoryShutdown(address factory) external;
    function factoryRestart(address factory, bool YorN) external;
    function getFactoryRestartVote(address factory) external view returns (bool[] memory votes);
    function executeFactoryRestart(address factory) external;

    function pairShutdown(address pair, bool YorN) external;
    function getPairShutdownVote(address pair) external view returns (bool[] memory votes);
    function executePairShutdown(address factory, address pair) external;
    function pairRestart(address pair, bool YorN) external;
    function getPairRestartVote(address pair) external view returns (bool[] memory votes);
    function executePairRestart(address factory, address pair) external;
}


// File contracts/OAXDEX_VotingExecutor.sol


pragma solidity =0.6.11;
contract OAXDEX_VotingExecutor is IOAXDEX_VotingExecutor {

    address public governance;
    address public admin;
    
    constructor(address _governance, address _admin) public {
        governance = _governance;
        admin = _admin;
    }

    function execute(bytes32[] calldata params) external override {
        require(IOAXDEX_Governance(governance).isVotingContract(msg.sender), "OAXDEX_VotingExecutor: Not from voting");
        bytes32 name = params[0];
        bytes32 param1 = params[1];
        // most frequenly used parameter comes first
        if (params.length == 4) {
            if (name == "setVotingConfig") {
                IOAXDEX_Governance(governance).setVotingConfig(param1, params[2], uint256(params[3]));
            } else {
                revert("OAXDEX_VotingExecutor: Unknown command");
            }
        } else if (params.length == 2) {
            if (name == "setMinStakePeriod") {
                IOAXDEX_Governance(governance).setMinStakePeriod(uint256(param1));
            } else if (name == "setMaxAdmin") {
                IOAXDEX_Administrator(admin).setMaxAdmin(uint256(param1));
            } else if (name == "addAdmin") {
                IOAXDEX_Administrator(admin).addAdmin(address(bytes20(param1)));
            } else if (name == "removeAdmin") {
                IOAXDEX_Administrator(admin).removeAdmin(address(bytes20(param1)));
            } else if (name == "setAdmin") {
                IOAXDEX_Governance(governance).setAdmin(address(bytes20(param1)));
            } else {
                revert("OAXDEX_VotingExecutor: Unknown command");
            }
        } else if (params.length == 3) {
            if (name == "setVotingExecutor") {
                IOAXDEX_Governance(governance).setVotingExecutor(address(bytes20(param1)), uint256(params[2])!=0);
            } else {
                revert("OAXDEX_VotingExecutor: Unknown command");
            }
        } else if (params.length == 7) {
            if (name == "addVotingConfig") {
                IOAXDEX_Governance(governance).addVotingConfig(param1, uint256(params[2]), uint256(params[3]), uint256(params[4]), uint256(params[5]), uint256(params[6]));
            } else {
                revert("OAXDEX_VotingExecutor: Unknown command");
            }
        } else {
            revert("OAXDEX_VotingExecutor: Invalid parameters");
        }
    }
}