/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

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

contract marketSIHandlerDataStorage is marketSIHandlerDataStorageInterface {
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
		require(msg.sender == owner, "onlyOwner function");
		_;
	}

	modifier onlySIHandler {
		address msgSender = msg.sender;
		require((msgSender == SIHandlerAddr) || (msgSender == owner), "onlySIHandler function");
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

	function updateRewardPerBlockStorage(uint256 _rewardPerBlock) onlySIHandler external override returns (bool)
	{
		marketRewardInfo.rewardPerBlock = _rewardPerBlock;
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

	function setMarketRewardInfo(uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardPerBlock) onlySIHandler external override returns (bool)
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

	function setUserRewardInfo(address userAddr, uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardAmount) onlySIHandler external override returns (bool)
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