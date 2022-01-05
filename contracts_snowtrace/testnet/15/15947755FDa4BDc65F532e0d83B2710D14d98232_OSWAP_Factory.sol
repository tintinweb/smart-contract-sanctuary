/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-05
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/commons/interfaces/IOSWAP_PausableFactory.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOSWAP_PausableFactory {
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);

    function governance() external view returns (address);

    function isLive() external returns (bool);
    function setLive(bool _isLive) external;
    function setLiveForPair(address pair, bool live) external;
}


// File contracts/commons/interfaces/IOSWAP_FactoryBase.sol


pragma solidity =0.6.11;

interface IOSWAP_FactoryBase is IOSWAP_PausableFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint newSize);

    function pairCreator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}


// File contracts/gov/interfaces/IOAXDEX_Governance.sol


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


// File contracts/commons/interfaces/IOSWAP_PausablePair.sol


pragma solidity =0.6.11;

interface IOSWAP_PausablePair {
    function isLive() external view returns (bool);
    function factory() external view returns (address);

    function setLive(bool _isLive) external;
}


// File contracts/commons/interfaces/IOSWAP_PairBase.sol


pragma solidity =0.6.11;

interface IOSWAP_PairBase is IOSWAP_PausablePair {
    function initialize(address toekn0, address toekn1) external;
}


// File contracts/commons/OSWAP_PausableFactory.sol


pragma solidity =0.6.11;



contract OSWAP_PausableFactory is IOSWAP_PausableFactory {

    modifier onlyShutdownAdminOrVoting() {
        require(IOAXDEX_Governance(governance).admin() == msg.sender ||
                IOAXDEX_Governance(governance).isVotingExecutor(msg.sender), 
                "Not from shutdown admin or voting");
        _; 
    }

    address public immutable override governance;

    bool public override isLive;

    constructor(address _governance) public {
        governance = _governance;
        isLive = true;
    }

    function setLive(bool _isLive) external override onlyShutdownAdminOrVoting {
        isLive = _isLive;
        if (isLive)
            emit Restarted();
        else
            emit Shutdowned();
    }
    function setLiveForPair(address pair, bool live) external override onlyShutdownAdminOrVoting {
        IOSWAP_PausablePair(pair).setLive(live);
        if (live)
            emit PairRestarted(pair);
        else
            emit PairShutdowned(pair);
    }
}


// File contracts/commons/OSWAP_FactoryBase.sol


pragma solidity =0.6.11;




contract OSWAP_FactoryBase is IOSWAP_FactoryBase, OSWAP_PausableFactory {
    modifier onlyVoting() {
        require(IOAXDEX_Governance(governance).isVotingExecutor(msg.sender), "Not from voting");
        _; 
    }

    address public override pairCreator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _governance, address _pairCreator) OSWAP_PausableFactory(_governance) public {
        pairCreator = _pairCreator;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'PAIR_EXISTS'); // single check is sufficient

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // bytes4(keccak256(bytes('createPair(bytes32)')));
        (bool success, bytes memory data) = pairCreator.delegatecall(abi.encodeWithSelector(0xED25A5A2, salt));
        require(success, "Failed to create pair");
        (pair) = abi.decode(data, (address));
        IOSWAP_PairBase(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}


// File contracts/amm/interfaces/IOSWAP_Factory.sol


pragma solidity =0.6.11;

interface IOSWAP_Factory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function protocolFeeParams() external view returns (uint256 _protocolFee, address _protocolFeeTo);

    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setProtocolFeeTo(address) external;
}


// File contracts/amm/OSWAP_Factory.sol


pragma solidity =0.6.11;


contract OSWAP_Factory is OSWAP_FactoryBase, IOSWAP_Factory {

    uint256 constant FEE_BASE = 10 ** 5;

    uint256 public override tradeFee;
    uint256 public override protocolFee;
    address public override protocolFeeTo;

    constructor(address _governance, address _pairCreator, uint256 _tradeFee, uint256 _protocolFee, address _protocolFeeTo) public 
        OSWAP_FactoryBase(_governance, _pairCreator)
    {
        require(_tradeFee <= FEE_BASE, "INVALID_TRADE_FEE");
        require(_protocolFee <= FEE_BASE, "INVALID_PROTOCOL_FEE");

        tradeFee = _tradeFee;
        protocolFee = _protocolFee;
        protocolFeeTo = _protocolFeeTo;

        emit ParamSet("tradeFee", bytes32(tradeFee));
        emit ParamSet("protocolFee", bytes32(protocolFee));
        emit ParamSet("protocolFeeTo", bytes32(bytes20(protocolFeeTo)));
    }

    function protocolFeeParams() external override view returns (uint256 _protocolFee, address _protocolFeeTo) {
        return (protocolFee, protocolFeeTo);
    }

    function setTradeFee(uint256 _tradeFee) external override onlyVoting {
        require(_tradeFee <= FEE_BASE, "INVALID_TRADE_FEE");
        tradeFee = _tradeFee;
        emit ParamSet("tradeFee", bytes32(tradeFee));
    }
    function setProtocolFee(uint256 _protocolFee) external override onlyVoting {
        require(_protocolFee <= FEE_BASE, "INVALID_PROTOCOL_FEE");
        protocolFee = _protocolFee;
        emit ParamSet("protocolFee", bytes32(protocolFee));
    }
    function setProtocolFeeTo(address _protocolFeeTo) external override onlyVoting {
        protocolFeeTo = _protocolFeeTo;
        emit ParamSet("protocolFeeTo", bytes32(bytes20(protocolFeeTo)));
    }
}