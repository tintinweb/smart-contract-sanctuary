/**
 *Submitted for verification at BscScan.com on 2021-09-21
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


// File contracts/oracle/interfaces/IOSWAP_OracleFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleFactory is IOSWAP_FactoryBase {
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);
    event OracleScores(address indexed oracle, uint256 score);
    event Whitelisted(address indexed who, bool allow);

    function oracleLiquidityProvider() external view returns (address);

    function tradeFee() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function feePerDelegator() external view returns (uint256);
    function protocolFeeTo() external view returns (address);

    function securityScoreOracle() external view returns (address);
    function minOracleScore() external view returns (uint256);

    function oracles(address token0, address token1) external view returns (address oracle);
    function minLotSize(address token) external view returns (uint256);
    function isOracle(address) external view returns (bool);
    function oracleScores(address oracle) external view returns (uint256);

    function whitelisted(uint256) external view returns (address);
    function whitelistedInv(address) external view returns (uint256);
    function isWhitelisted(address) external returns (bool);

    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external;

    function setOracle(address from, address to, address oracle) external;
    function addOldOracleToNewPair(address from, address to, address oracle) external;
    function setTradeFee(uint256) external;
    function setProtocolFee(uint256) external;
    function setFeePerDelegator(uint256 _feePerDelegator) external;
    function setProtocolFeeTo(address) external;
    function setSecurityScoreOracle(address, uint256) external;
    function setMinLotSize(address token, uint256 _minLotSize) external;

    function updateOracleScore(address oracle) external;

    function whitelistedLength() external view returns (uint256);
    function allWhiteListed() external view returns(address[] memory list, bool[] memory allowed);
    function setWhiteList(address _who, bool _allow) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle, uint256 _tradeFee, uint256 _protocolFee);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
}


// File contracts/oracle/interfaces/IOSWAP_OracleScoreOracleAdaptor.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleScoreOracleAdaptor {
    function oracleAddress() external view returns (address);
    function getSecurityScore(address oracle) external view returns (uint);
}


// File contracts/oracle/interfaces/IOSWAP_OracleAdaptor.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
    function getLatestPrice(address from, address to, bytes calldata payload) external view returns (uint256 price);
    function decimals() external view returns (uint8);
}


// File contracts/libraries/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/libraries/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/oracle/OSWAP_OracleFactory.sol


pragma solidity =0.6.11;





contract OSWAP_OracleFactory is OSWAP_FactoryBase, IOSWAP_OracleFactory, Ownable { 

    uint256 constant FEE_BASE = 10 ** 5;

    address public override oracleLiquidityProvider;

    uint256 public override tradeFee;
    uint256 public override protocolFee;
    uint256 public override feePerDelegator;
    address public override protocolFeeTo;

    address public override securityScoreOracle;
    uint256 public override minOracleScore;

    // Oracle
    mapping (address => mapping (address => address)) public override oracles;
    mapping (address => uint256) public override minLotSize;
    mapping (address => bool) public override isOracle;
    mapping (address => uint256) public override oracleScores;

    address[] public override whitelisted;
    mapping (address => uint256) public override whitelistedInv;
    mapping (address => bool) public override isWhitelisted; 

    constructor(address _governance, address _pairCreator, uint256 _tradeFee, uint256 _protocolFee, uint256 _feePerDelegator, address _protocolFeeTo) public 
        OSWAP_FactoryBase(_governance, _pairCreator)
    {
        require(_tradeFee <= FEE_BASE, "INVALID_TRADE_FEE");
        require(_protocolFee <= FEE_BASE, "INVALID_PROTOCOL_FEE");

        tradeFee = _tradeFee;
        protocolFee = _protocolFee;
        feePerDelegator = _feePerDelegator;
        protocolFeeTo = _protocolFeeTo;

        emit ParamSet("tradeFee", bytes32(tradeFee));
        emit ParamSet("protocolFee", bytes32(protocolFee));
        emit ParamSet("feePerDelegator", bytes32(feePerDelegator));
        emit ParamSet("protocolFeeTo", bytes32(bytes20(protocolFeeTo)));
    }
    // only set at deployment time
    function setOracleLiquidityProvider(address _oracleRouter, address _oracleLiquidityProvider) external override onlyOwner {
        require(oracleLiquidityProvider == address(0), "OracleLiquidityProvider already set");
        oracleLiquidityProvider = _oracleLiquidityProvider;

        if (whitelisted.length==0 || whitelisted[whitelistedInv[_oracleRouter]] != _oracleRouter) {
            whitelistedInv[_oracleRouter] = whitelisted.length; 
            whitelisted.push(_oracleRouter);
        }
        isWhitelisted[_oracleRouter] = true;
        emit Whitelisted(_oracleRouter, true);        
    }

    // add new oracle not seen before or update an oracle for an existing pair
    function setOracle(address tokenA, address tokenB, address oracle) external override {
        changeOracle(tokenA, tokenB, oracle);
    }
    // add existing/already seen oracle to new pair with lower quorum
    function addOldOracleToNewPair(address tokenA, address tokenB, address oracle) external override {
        require(oracles[tokenA][tokenB] == address(0), "oracle already set");
        require(isOracle[oracle], "oracle not seen");
        changeOracle(tokenA, tokenB, oracle);
    }
    function changeOracle(address tokenA, address tokenB, address oracle) private onlyVoting {
        require(tokenA < tokenB, "Invalid address pair order");
        require(IOSWAP_OracleAdaptor(oracle).isSupported(tokenA, tokenB), "Pair not supported by oracle");
        oracles[tokenA][tokenB] = oracle;
        oracles[tokenB][tokenA] = oracle;
        isOracle[oracle] = true;
        emit OracleAdded(tokenA, tokenB, oracle);
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
    function setFeePerDelegator(uint256 _feePerDelegator) external override onlyVoting {
        feePerDelegator = _feePerDelegator;
        emit ParamSet("feePerDelegator", bytes32(feePerDelegator));
    }
    function setProtocolFeeTo(address _protocolFeeTo) external override onlyVoting {
        protocolFeeTo = _protocolFeeTo;
        emit ParamSet("protocolFeeTo", bytes32(bytes20(protocolFeeTo)));
    }
    function setSecurityScoreOracle(address _securityScoreOracle, uint256 _minOracleScore) external override onlyVoting {
        require(_minOracleScore <= 100, "Invalid security score");
        securityScoreOracle = _securityScoreOracle;
        minOracleScore = _minOracleScore;
        emit ParamSet2("securityScoreOracle", bytes32(bytes20(securityScoreOracle)), bytes32(minOracleScore));
    }
    function setMinLotSize(address token, uint256 _minLotSize) external override onlyVoting {
        minLotSize[token] = _minLotSize;
        emit ParamSet2("minLotSize", bytes32(bytes20(token)), bytes32(_minLotSize));
    }

    function updateOracleScore(address oracle) external override {
        require(isOracle[oracle], "Oracle Adaptor not found");
        uint256 score = IOSWAP_OracleScoreOracleAdaptor(securityScoreOracle).getSecurityScore(oracle);
        oracleScores[oracle] = score;
        emit OracleScores(oracle, score);
    }

    function whitelistedLength() external view override returns (uint256) {
        return whitelisted.length;
    }
    function allWhiteListed() external view override returns(address[] memory list, bool[] memory allowed) {
        list = whitelisted;
        uint256 length = list.length;
        allowed = new bool[](length);
        for (uint256 i = 0 ; i < length ; i++) {
            allowed[i] = isWhitelisted[whitelisted[i]];
        }
    }
    function setWhiteList(address _who, bool _allow) external override onlyVoting {
        if (whitelisted.length==0 || whitelisted[whitelistedInv[_who]] != _who) {
            whitelistedInv[_who] = whitelisted.length; 
            whitelisted.push(_who);
        }
        isWhitelisted[_who] = _allow;
        emit Whitelisted(_who, _allow);
    }

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view override returns (address oracle_, uint256 tradeFee_, uint256 protocolFee_) {
        require(isLive, 'GLOBALLY PAUSED');
        address oracle = checkAndGetOracle(tokenA, tokenB);
        return (oracle, tradeFee, protocolFee);
    }

    function checkAndGetOracle(address tokenA, address tokenB) public view override returns (address oracle) {
        require(tokenA < tokenB, 'Address must be sorted');
        oracle = oracles[tokenA][tokenB];
        require(oracle != address(0), 'No oracle found');
        uint256 score = oracleScores[oracle];
        require(score >= minOracleScore, 'Oracle score too low');
    }
}