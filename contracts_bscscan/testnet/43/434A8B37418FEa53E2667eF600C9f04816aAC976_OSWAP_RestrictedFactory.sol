/**
 *Submitted for verification at BscScan.com on 2021-10-18
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


// File contracts/restricted/interfaces/IOSWAP_RestrictedFactory.sol


pragma solidity =0.6.11;

interface IOSWAP_RestrictedFactory is IOSWAP_PausableFactory { 

    event PairCreated(address indexed token0, address indexed token1, address pair, uint newPairSize, uint newSize);
    event Shutdowned();
    event Restarted();
    event PairShutdowned(address indexed pair);
    event PairRestarted(address indexed pair);
    event ParamSet(bytes32 name, bytes32 value);
    event ParamSet2(bytes32 name, bytes32 value1, bytes32 value2);
    event OracleAdded(address indexed token0, address indexed token1, address oracle);

    function whitelistFactory() external view returns (address);
    function pairCreator() external returns (address);
    function configStore() external returns (address);

    function tradeFee() external returns (uint256);
    function protocolFee() external returns (uint256);
    function protocolFeeTo() external returns (address);

    function getPair(address tokenA, address tokenB, uint256 i) external returns (address pair);
    function pairIdx(address pair) external returns (uint256 i);
    function allPairs(uint256 i) external returns (address pair);

    function restrictedLiquidityProvider() external returns (address);
    function oracles(address tokenA, address tokenB) external returns (address oracle);
    function isOracle(address oracle) external returns (bool);

    function init(address _restrictedLiquidityProvider) external;
    function getCreateAddresses() external view returns (address _governance, address _whitelistFactory, address _restrictedLiquidityProvider, address _configStore);

    function pairLength(address tokenA, address tokenB) external view returns (uint256);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setOracle(address tokenA, address tokenB, address oracle) external;
    function addOldOracleToNewPair(address tokenA, address tokenB, address oracle) external;

    function isPair(address pair) external view returns (bool);

    function setTradeFee(uint256 _tradeFee) external;
    function setProtocolFee(uint256 _protocolFee) external;
    function setProtocolFeeTo(address _protocolFeeTo) external;

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view returns (address oracle_, uint256 tradeFee_, uint256 protocolFee_);
    function checkAndGetOracle(address tokenA, address tokenB) external view returns (address oracle);
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


// File contracts/oracle/interfaces/IOSWAP_OracleAdaptor2.sol


pragma solidity =0.6.11;

interface IOSWAP_OracleAdaptor2 {
    function isSupported(address from, address to) external view returns (bool supported);
    function getRatio(address from, address to, uint256 fromAmount, uint256 toAmount, address trader, bytes calldata payload) external view returns (uint256 numerator, uint256 denominator);
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


// File contracts/restricted/OSWAP_RestrictedFactory.sol


pragma solidity =0.6.11;






contract OSWAP_RestrictedFactory is IOSWAP_RestrictedFactory, OSWAP_PausableFactory, Ownable { 

    modifier onlyVoting() {
        require(IOAXDEX_Governance(governance).isVotingExecutor(msg.sender), "Not from voting");
        _; 
    }

    uint256 constant FEE_BASE = 10 ** 5;

    address public override immutable whitelistFactory;
    address public override immutable pairCreator;
    address public override immutable configStore;

    uint256 public override tradeFee;
    uint256 public override protocolFee;
    address public override protocolFeeTo;

    mapping(address => mapping(address => address[])) public override getPair;
    mapping(address => uint256) public override pairIdx;
    address[] public override allPairs;

    address public override restrictedLiquidityProvider;
    mapping (address => mapping (address => address)) public override oracles;
    mapping (address => bool) public override isOracle;

    constructor(address _governance, address _whitelistFactory, address _pairCreator, address _configStore, uint256 _tradeFee, uint256 _protocolFee, address _protocolFeeTo) OSWAP_PausableFactory(_governance) public {
        whitelistFactory = _whitelistFactory;
        pairCreator = _pairCreator;
        configStore = _configStore;
        tradeFee = _tradeFee;
        protocolFee = _protocolFee;
        protocolFeeTo = _protocolFeeTo;
    }
    // only set at deployment time
    function init(address _restrictedLiquidityProvider) external override onlyOwner {
        require(restrictedLiquidityProvider == address(0), "RestrictedLiquidityProvider already set");
        restrictedLiquidityProvider = _restrictedLiquidityProvider;
    }

    function getCreateAddresses() external override view returns (address _governance, address _whitelistFactory, address _restrictedLiquidityProvider, address _configStore) {
        return (governance, whitelistFactory, restrictedLiquidityProvider, configStore);
    }

    function pairLength(address tokenA, address tokenB) external override view returns (uint256) {
        return getPair[tokenA][tokenB].length;
    }
    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    // support multiple pairs
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');

        bytes32 salt = keccak256(abi.encodePacked(token0, token1, getPair[token0][token1].length));
        // bytes4(keccak256(bytes('createPair(bytes32)')));
        (bool success, bytes memory data) = pairCreator.delegatecall(abi.encodeWithSelector(0xED25A5A2, salt));
        require(success, "Failed to create pair");
        (pair) = abi.decode(data, (address));
        IOSWAP_PairBase(pair).initialize(token0, token1);

        getPair[token0][token1].push(pair);
        getPair[token1][token0].push(pair); // populate mapping in the reverse direction
        pairIdx[pair] = allPairs.length;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, getPair[token0][token1].length, allPairs.length);
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
        require(IOSWAP_OracleAdaptor2(oracle).isSupported(tokenA, tokenB), "Pair not supported by oracle");
        oracles[tokenA][tokenB] = oracle;
        oracles[tokenB][tokenA] = oracle;
        isOracle[oracle] = true;
        emit OracleAdded(tokenA, tokenB, oracle);
    }

    function isPair(address pair) external override view returns (bool) {
        return allPairs.length != 0 && allPairs[pairIdx[pair]] == pair;
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

    function checkAndGetOracleSwapParams(address tokenA, address tokenB) external view override returns (address oracle_, uint256 tradeFee_, uint256 protocolFee_) {
        require(isLive, 'GLOBALLY PAUSED');
        address oracle = checkAndGetOracle(tokenA, tokenB);
        return (oracle, tradeFee, protocolFee);
    }
    function checkAndGetOracle(address tokenA, address tokenB) public view override returns (address oracle) {
        require(tokenA < tokenB, 'Address must be sorted');
        oracle = oracles[tokenA][tokenB];
        require(oracle != address(0), 'No oracle found');
        // FIXME:
        // uint256 score = oracleScores[oracle];
        // require(score >= minOracleScore, 'Oracle score too low');
    }
}