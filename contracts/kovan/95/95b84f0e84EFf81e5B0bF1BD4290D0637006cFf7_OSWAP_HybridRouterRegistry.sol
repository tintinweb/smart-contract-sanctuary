/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// Sources flattened with hardhat v2.6.3 https://hardhat.org

// File contracts/router/interfaces/IOSWAP_HybridRouterRegistry.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.6.11;

interface IOSWAP_HybridRouterRegistry {
    event ProtocolRegister(address indexed factory, bytes32 name, uint256 fee, uint256 feeBase, uint256 typeCode);
    event PairRegister(address indexed factory, address indexed pair, address token0, address token1);
    event CustomPairRegister(address indexed pair, uint256 fee, uint256 feeBase, uint256 typeCode);

    struct Protocol {
        bytes32 name;
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }
    struct Pair {
        address factory;
        address token0;
        address token1;
    }
    struct CustomPair {
        uint256 fee;
        uint256 feeBase;
        uint256 typeCode;
    }


    function protocols(address) external view returns (
        bytes32 name,
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function pairs(address) external view returns (
        address factory,
        address token0,
        address token1
    );
    function customPairs(address) external view returns (
        uint256 fee,
        uint256 feeBase,
        uint256 typeCode
    );
    function protocolList(uint256) external view returns (address);
    function protocolListLength() external view returns (uint256);

    function governance() external returns (address);

    function registerProtocol(bytes32 _name, address _factory, uint256 _fee, uint256 _feeBase, uint256 _typeCode) external;

    function registerPair(address token0, address token1, address pairAddress, uint256 fee, uint256 feeBase, uint256 typeCode) external;
    function registerPairByIndex(address _factory, uint256 index) external;
    function registerPairsByIndex(address _factory, uint256[] calldata index) external;
    function registerPairByTokens(address _factory, address _token0, address _token1) external;
    function registerPairByTokensV3(address _factory, address _token0, address _token1, uint256 pairIndex) external;
    function registerPairsByTokens(address _factory, address[] calldata _token0, address[] calldata _token1) external;
    function registerPairsByTokensV3(address _factory, address[] calldata _token0, address[] calldata _token1, uint256[] calldata pairIndex) external;
    function registerPairByAddress(address _factory, address pairAddress) external;
    function registerPairsByAddress(address _factory, address[] memory pairAddress) external;
    function registerPairsByAddress2(address[] memory _factory, address[] memory pairAddress) external;

    function getPairTokens(address[] calldata pairAddress) external view returns (address[] memory token0, address[] memory token1);
    function getTypeCode(address pairAddress) external view returns (uint256 typeCode);
    function getFee(address pairAddress) external view returns (uint256 fee, uint256 feeBase);
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


// File contracts/gov/interfaces/IOAXDEX_VotingExecutor.sol


pragma solidity =0.6.11;

interface IOAXDEX_VotingExecutor {
    function execute(bytes32[] calldata params) external;
}


// File contracts/router/OSWAP_HybridRouterRegistry.sol


pragma solidity =0.6.11;




interface IFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}
interface IFactoryV3 {
    function getPair(address tokenA, address tokenB, uint256 index) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}

interface IPair {
    function token0() external returns (address);
    function token1() external returns (address);
}

contract OSWAP_HybridRouterRegistry is Ownable, IOSWAP_HybridRouterRegistry, IOAXDEX_VotingExecutor {

    modifier onlyVoting() {
        require(IOAXDEX_Governance(governance).isVotingExecutor(msg.sender), "Not from voting");
        _; 
    }

    mapping (address => Pair) public override pairs;
    mapping (address => CustomPair) public override customPairs;
    mapping (address => Protocol) public override protocols;
    address[] public override protocolList;

    address public override governance;

    constructor(address _governance) public {
        governance = _governance;
    }

    function protocolListLength() public override view returns (uint256) {
        return protocolList.length;
    }

    function init(bytes32[] calldata _name, address[] calldata _factory, uint256[] calldata _fee, uint256[] calldata _feeBase, uint256[] calldata _typeCode) external onlyOwner {
        require(protocolList.length == 0 , "Already init");
        uint256 length = _name.length;
        require(length == _factory.length && _factory.length == _fee.length && _fee.length == _typeCode.length, "length not match");
        for (uint256 i = 0 ; i < length ; i++) {
            _registerProtocol(_name[i], _factory[i], _fee[i], _feeBase[i], _typeCode[i]);
        }
    }
    function execute(bytes32[] calldata params) external override {
        require(IOAXDEX_Governance(governance).isVotingContract(msg.sender), "Not from voting");
        require(params.length > 1, "Invalid length");
        bytes32 name = params[0];
        if (params.length == 6) {
            if (name == "registerProtocol") {
                _registerProtocol(params[1], address(bytes20(params[2])), uint256(params[3]), uint256(params[4]), uint256(params[5]));
                return;
            }
        } else if (params.length == 7) {
            if (name == "registerPair") {
                _registerPair(address(bytes20(params[1])), address(bytes20(params[2])), address(bytes20(params[3])), uint256(params[4]), uint256(params[5]), uint256(params[6]));
                return;
            }
        }
        revert("Invalid parameters");
    }
    function registerProtocol(bytes32 _name, address _factory, uint256 _fee, uint256 _feeBase, uint256 _typeCode) external override onlyVoting {
        _registerProtocol(_name, _factory, _fee, _feeBase, _typeCode);
    }
    // register protocol with standard trade fee
    function _registerProtocol(bytes32 _name, address _factory, uint256 _fee, uint256 _feeBase, uint256 _typeCode) internal {
        require(_factory > address(0), "Invalid protocol address");
        require(_fee <= _feeBase, "Fee too large");
        require(_feeBase > 0, "Protocol not regconized");
        protocols[_factory] = Protocol({
            name: _name,
            fee: _fee,
            feeBase: _feeBase,
            typeCode: _typeCode
        });
        protocolList.push(_factory);
        emit ProtocolRegister(_factory, _name, _fee, _feeBase, _typeCode);
    }

    // register individual pair
    function registerPair(address token0, address token1, address pairAddress, uint256 fee, uint256 feeBase, uint256 typeCode) external override onlyVoting {
        _registerPair(token0, token1, pairAddress, fee, feeBase, typeCode);
    }
    function _registerPair(address token0, address token1, address pairAddress, uint256 fee, uint256 feeBase, uint256 typeCode) internal {
        require(token0 > address(0), "Invalid token address");
        require(token0 < token1, "Invalid token order");
        require(pairAddress > address(0), "Invalid pair address");
        // require(token0 == IPair(pairAddress).token0());
        // require(token1 == IPair(pairAddress).token1());
        require(fee <= feeBase, "Fee too large");
        require(feeBase > 0, "Protocol not regconized");

        pairs[pairAddress].factory = address(0);
        pairs[pairAddress].token0 = token0;
        pairs[pairAddress].token1 = token1;
        customPairs[pairAddress].fee = fee;
        customPairs[pairAddress].feeBase = feeBase;
        customPairs[pairAddress].typeCode = typeCode;
        emit PairRegister(address(0), pairAddress, token0, token1);
        emit CustomPairRegister(pairAddress, fee, feeBase, typeCode);
    }

    // register pair with registered protocol
    function registerPairByIndex(address _factory, uint256 index) external override {
        require(protocols[_factory].typeCode > 0, "Protocol not regconized");
        address pairAddress = IFactory(_factory).allPairs(index);
        _registerPair(_factory, pairAddress);
    }
    function registerPairsByIndex(address _factory, uint256[] calldata index) external override {
        require(protocols[_factory].typeCode > 0, "Protocol not regconized");
        uint256 length = index.length;
        for (uint256 i = 0 ; i < length ; i++) {
            address pairAddress = IFactory(_factory).allPairs(index[i]);
            _registerPair(_factory, pairAddress);
        }
    }
    function registerPairByTokens(address _factory, address _token0, address _token1) external override {
        require(protocols[_factory].typeCode > 0 && protocols[_factory].typeCode < 3, "Invalid type");
        address pairAddress = IFactory(_factory).getPair(_token0, _token1);
        _registerPair(_factory, pairAddress);
    }

    function registerPairByTokensV3(address _factory, address _token0, address _token1, uint256 pairIndex) external override {
        require(protocols[_factory].typeCode == 3, "Invalid type");
        address pairAddress = IFactoryV3(_factory).getPair(_token0, _token1, pairIndex);
        _registerPair(_factory, pairAddress);
    }
    function registerPairsByTokens(address _factory, address[] calldata _token0, address[] calldata _token1) external override {
        require(protocols[_factory].typeCode > 0 && protocols[_factory].typeCode < 3, "Invalid type");
        uint256 length = _token0.length;
        require(length == _token1.length, "array length not match");
        for (uint256 i = 0 ; i < length ; i++) {
            address pairAddress = IFactory(_factory).getPair(_token0[i], _token1[i]);
            _registerPair(_factory, pairAddress);
        }
    }
    function registerPairsByTokensV3(address _factory, address[] calldata _token0, address[] calldata _token1, uint256[] calldata _pairIndex) external override {
        require(protocols[_factory].typeCode == 3, "Invalid type");
        uint256 length = _token0.length;
        require(length == _token1.length, "array length not match");
        for (uint256 i = 0 ; i < length ; i++) {
            address pairAddress = IFactoryV3(_factory).getPair(_token0[i], _token1[i], _pairIndex[i]);
            _registerPair(_factory, pairAddress);
        }
    }
    function registerPairByAddress(address _factory, address pairAddress) external override {
        require(protocols[_factory].typeCode > 0 && protocols[_factory].typeCode < 3, "Protocol not regconized");
        _registerPair(_factory, pairAddress);
    }
    function registerPairsByAddress(address _factory, address[] memory pairAddress) external override {
        require(protocols[_factory].typeCode > 0 && protocols[_factory].typeCode < 3, "Protocol not regconized");
        uint256 length = pairAddress.length;
        for (uint256 i = 0 ; i < length ; i++) {
            _registerPair(_factory, pairAddress[i]);
        }
    }
    function registerPairsByAddress2(address[] memory _factory, address[] memory pairAddress) external override {
        uint256 length = pairAddress.length;
        require(length == _factory.length, "array length not match");
        for (uint256 i = 0 ; i < length ; i++) {
            require(protocols[_factory[i]].typeCode > 0 && protocols[_factory[i]].typeCode < 3, "Protocol not regconized");
            _registerPair(_factory[i], pairAddress[i]);
        }
    }

    function _registerPair(address _factory, address pairAddress) internal {
        require(pairAddress > address(0), "Invalid pair address/Pair not found");
        address token0 = IPair(pairAddress).token0();
        address token1 = IPair(pairAddress).token1();
        require(token0 < token1, "Invalid tokens order");
        pairs[pairAddress].factory = _factory;
        pairs[pairAddress].token0 = token0;
        pairs[pairAddress].token1 = token1;
        emit PairRegister(_factory, pairAddress, token0, token1);
    }

    function getPairTokens(address[] calldata pairAddress) external override view returns (address[] memory token0, address[] memory token1) {
        uint256 length = pairAddress.length;
        token0 = new address[](length);
        token1 = new address[](length);
        for (uint256 i = 0 ; i < length ; i++) {
            Pair storage pair = pairs[pairAddress[i]];
            token0[i] = pair.token0;
            token1[i] = pair.token1;
        }
    }
    // caller needs to check if typeCode = 0 (or other invalid value)
    function getTypeCode(address pairAddress) external override view returns (uint256 typeCode) {
        address factory = pairs[pairAddress].factory;
        if (factory != address(0)) {
            typeCode = protocols[factory].typeCode;
        } else {
            typeCode = customPairs[pairAddress].typeCode;
        }
    }
    // if getFee() is called without prior getTypeCode(), caller needs to check if feeBase = 0
    function getFee(address pairAddress) external override view returns (uint256 fee, uint256 feeBase) {
        address factory = pairs[pairAddress].factory;
        if (factory != address(0)) {
            fee = protocols[factory].fee;
            feeBase = protocols[factory].feeBase;
        } else {
            feeBase = customPairs[pairAddress].feeBase;
            fee = customPairs[pairAddress].fee;
        }
    }
}