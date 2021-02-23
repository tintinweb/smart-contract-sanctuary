/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// File: contracts/interfaces/marketSIHandlerDataStorageInterface.sol

pragma solidity 0.6.12;

interface marketSIHandlerDataStorageInterface  {
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function updateRewardPerBlockStorage(uint256 _rewardPerBlock) external returns (bool);

	function getRewardInfo(address userAddr) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);
	function setMarketRewardInfo(uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardPerBlock) external returns (bool);

	function getUserRewardInfo(address userAddr) external view returns (uint256, uint256, uint256);
	function setUserRewardInfo(address userAddr, uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardAmount) external returns (bool);

	function getBetaRate() external view returns (uint256);
	function setBetaRate(uint256 _betaRate) external returns (bool);
}

// File: contracts/Errors.sol

pragma solidity 0.6.12;

contract Modifier {
    string internal constant ONLY_OWNER = "O";
    string internal constant ONLY_MANAGER = "M";
    string internal constant CIRCUIT_BREAKER = "emergency";
}

contract ManagerModifier is Modifier {
    string internal constant ONLY_HANDLER = "H";
    string internal constant ONLY_LIQUIDATION_MANAGER = "LM";
    string internal constant ONLY_BREAKER = "B";
}

contract HandlerDataStorageModifier is Modifier {
    string internal constant ONLY_BIFI_CONTRACT = "BF";
}

contract SIDataStorageModifier is Modifier {
    string internal constant ONLY_SI_HANDLER = "SI";
}

contract HandlerErrors is Modifier {
    string internal constant USE_VAULE = "use value";
    string internal constant USE_ARG = "use arg";
    string internal constant EXCEED_LIMIT = "exceed limit";
    string internal constant NO_LIQUIDATION = "no liquidation";
    string internal constant NO_LIQUIDATION_REWARD = "no enough reward";
    string internal constant NO_EFFECTIVE_BALANCE = "not enough balance";
    string internal constant TRANSFER = "err transfer";
}

contract SIErrors is Modifier { }

contract InterestErrors is Modifier { }

contract LiquidationManagerErrors is Modifier {
    string internal constant NO_DELINQUENT = "not delinquent";
}

contract ManagerErrors is ManagerModifier {
    string internal constant REWARD_TRANSFER = "RT";
    string internal constant UNSUPPORTED_TOKEN = "UT";
}

contract OracleProxyErrors is Modifier {
    string internal constant ZERO_PRICE = "price zero";
}

contract RequestProxyErrors is Modifier { }

contract ManagerDataStorageErrors is ManagerModifier {
    string internal constant NULL_ADDRESS = "err addr null";
}

// File: contracts/marketHandler/marketHandlerDataStorage/marketSIHandlerDataStorage.sol

pragma solidity 0.6.12;

contract marketSIHandlerDataStorage is marketSIHandlerDataStorageInterface, SIDataStorageModifier {
	bool emergency;

	address owner;

	address SIHandlerAddr;

	MarketRewardInfo marketRewardInfo;

	mapping(address => UserRewardInfo) userRewardInfo;

	struct MarketRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardPerBlock;
	}

	struct UserRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardAmount;
	}

	uint256 betaRate;

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlySIHandler {
		address msgSender = msg.sender;
		require((msgSender == SIHandlerAddr) || (msgSender == owner), ONLY_SI_HANDLER);
		_;
	}

	modifier circuitBreaker {
		address msgSender = msg.sender;
		require((!emergency) || (msgSender == owner), CIRCUIT_BREAKER);
		_;
	}

	constructor (address _SIHandlerAddr) public
	{
		owner = msg.sender;
		SIHandlerAddr = _SIHandlerAddr;
		betaRate = 5 * (10 ** 17);
		marketRewardInfo.rewardLaneUpdateAt = block.number;
	}

	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = _owner;
		return true;
	}

	function setCircuitBreaker(bool _emergency) onlySIHandler external override returns (bool)
	{
		emergency = _emergency;
		return true;
	}

	function setSIHandlerAddr(address _SIHandlerAddr) onlyOwner public returns (bool)
	{
		SIHandlerAddr = _SIHandlerAddr;
		return true;
	}

	function updateRewardPerBlockStorage(uint256 _rewardPerBlock) onlySIHandler circuitBreaker external override returns (bool)
	{
		marketRewardInfo.rewardPerBlock = _rewardPerBlock;
		return true;
	}

	function getSIHandlerAddr() public view returns (address)
	{
		return SIHandlerAddr;
	}

	function getRewardInfo(address userAddr) external view override returns (uint256, uint256, uint256, uint256, uint256, uint256)
	{
		MarketRewardInfo memory market = marketRewardInfo;
		UserRewardInfo memory user = userRewardInfo[userAddr];
		return (market.rewardLane, market.rewardLaneUpdateAt, market.rewardPerBlock, user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount);
	}

	function getMarketRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		MarketRewardInfo memory vars = marketRewardInfo;
		return (vars.rewardLane, vars.rewardLaneUpdateAt, vars.rewardPerBlock);
	}

	function setMarketRewardInfo(uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardPerBlock) onlySIHandler circuitBreaker external override returns (bool)
	{
		MarketRewardInfo memory vars;
		vars.rewardLane = _rewardLane;
		vars.rewardLaneUpdateAt = _rewardLaneUpdateAt;
		vars.rewardPerBlock = _rewardPerBlock;
		marketRewardInfo = vars;
		return true;
	}

	function getUserRewardInfo(address userAddr) external view override returns (uint256, uint256, uint256)
	{
		UserRewardInfo memory vars = userRewardInfo[userAddr];
		return (vars.rewardLane, vars.rewardLaneUpdateAt, vars.rewardAmount);
	}

	function setUserRewardInfo(address userAddr, uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardAmount) onlySIHandler circuitBreaker external override returns (bool)
	{
		UserRewardInfo memory vars;
		vars.rewardLane = _rewardLane;
		vars.rewardLaneUpdateAt = _rewardLaneUpdateAt;
		vars.rewardAmount = _rewardAmount;
		userRewardInfo[userAddr] = vars;
		return true;
	}

	function getBetaRate() external view override returns (uint256)
	{
		return betaRate;
	}

	function setBetaRate(uint256 _betaRate) onlyOwner external override returns (bool)
	{
		betaRate = _betaRate;
		return true;
	}
}