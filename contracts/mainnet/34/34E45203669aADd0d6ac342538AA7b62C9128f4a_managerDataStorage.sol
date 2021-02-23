/**
 *Submitted for verification at Etherscan.io on 2021-02-23
*/

// File: contracts/interfaces/managerDataStorageInterface.sol

pragma solidity 0.6.12;

interface managerDataStorageInterface  {
	function getGlobalRewardPerBlock() external view returns (uint256);
	function setGlobalRewardPerBlock(uint256 _globalRewardPerBlock) external returns (bool);

	function getGlobalRewardDecrement() external view returns (uint256);
	function setGlobalRewardDecrement(uint256 _globalRewardDecrement) external returns (bool);

	function getGlobalRewardTotalAmount() external view returns (uint256);
	function setGlobalRewardTotalAmount(uint256 _globalRewardTotalAmount) external returns (bool);

	function getAlphaRate() external view returns (uint256);
	function setAlphaRate(uint256 _alphaRate) external returns (bool);

	function getAlphaLastUpdated() external view returns (uint256);
	function setAlphaLastUpdated(uint256 _alphaLastUpdated) external returns (bool);

	function getRewardParamUpdateRewardPerBlock() external view returns (uint256);
	function setRewardParamUpdateRewardPerBlock(uint256 _rewardParamUpdateRewardPerBlock) external returns (bool);

	function getRewardParamUpdated() external view returns (uint256);
	function setRewardParamUpdated(uint256 _rewardParamUpdated) external returns (bool);

	function getInterestUpdateRewardPerblock() external view returns (uint256);
	function setInterestUpdateRewardPerblock(uint256 _interestUpdateRewardPerblock) external returns (bool);

	function getInterestRewardUpdated() external view returns (uint256);
	function setInterestRewardUpdated(uint256 _interestRewardLastUpdated) external returns (bool);

	function setTokenHandler(uint256 handlerID, address handlerAddr) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address);

	function getTokenHandlerID(uint256 index) external view returns (uint256);

	function getTokenHandlerAddr(uint256 handlerID) external view returns (address);
	function setTokenHandlerAddr(uint256 handlerID, address handlerAddr) external returns (bool);

	function getTokenHandlerExist(uint256 handlerID) external view returns (bool);
	function setTokenHandlerExist(uint256 handlerID, bool exist) external returns (bool);

	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);
	function setTokenHandlerSupport(uint256 handlerID, bool support) external returns (bool);

	function setLiquidationManagerAddr(address _liquidationManagerAddr) external returns (bool);
	function getLiquidationManagerAddr() external view returns (address);

	function setManagerAddr(address _managerAddr) external returns (bool);
}

// File: contracts/marketManager/managerDataStorage/managerDataStorage.sol

pragma solidity 0.6.12;

contract managerDataStorage is managerDataStorageInterface {
	address payable owner;

	address managerAddr;

	address liquidationManagerAddr;

	struct TokenHandler {
		address addr;
		bool support;
		bool exist;
	}

	uint256 globalRewardPerBlock;

	uint256 globalRewardDecrement;

	uint256 globalRewardTotalAmount;

	uint256 alphaRate;

	uint256 alphaLastUpdated;

	uint256 rewardParamUpdateRewardPerBlock;

	uint256 rewardParamUpdated;

	uint256 interestUpdateRewardPerblock;

	uint256 interestRewardLastUpdated;

	mapping(uint256 => TokenHandler) tokenHandlers;

	/* handler Array */
	uint256[] private tokenHandlerList;

	modifier onlyManager {
		address msgSender = msg.sender;
		require((msgSender == managerAddr) || (msgSender == owner), "onlyManager function");
		_;
	}

	modifier onlyOwner {
		require(msg.sender == owner, "onlyOwner function");
		_;
	}

	constructor () public
	{
		owner = msg.sender;
		globalRewardPerBlock = 0x478291c1a0e982c98;
		globalRewardDecrement = 0x7ba42eb3bfc;
		globalRewardTotalAmount = (4 * 100000000) * (10 ** 18);
		alphaRate = 2 * (10 ** 17);
		alphaLastUpdated = block.number;
		/*
		            rewardParamUpdateRewardPerBlock = 1u * (10u ** 17u); // == 0.1
		            rewardParamUpdated = block.getNumber();

		            interestUpdateRewardPerblock = 5u * (10u ** 16u); // == 0.05
		            interestRewardLastUpdated = block.getNumber();
		            */
	}

	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	function getGlobalRewardPerBlock() external view override returns (uint256)
	{
		return globalRewardPerBlock;
	}

	function setGlobalRewardPerBlock(uint256 _globalRewardPerBlock) onlyManager external override returns (bool)
	{
		globalRewardPerBlock = _globalRewardPerBlock;
		return true;
	}

	function getGlobalRewardDecrement() external view override returns (uint256)
	{
		return globalRewardDecrement;
	}

	function setGlobalRewardDecrement(uint256 _globalRewardDecrement) onlyManager external override returns (bool)
	{
		globalRewardDecrement = _globalRewardDecrement;
		return true;
	}

	function getGlobalRewardTotalAmount() external view override returns (uint256)
	{
		return globalRewardTotalAmount;
	}

	function setGlobalRewardTotalAmount(uint256 _globalRewardTotalAmount) onlyManager external override returns (bool)
	{
		globalRewardTotalAmount = _globalRewardTotalAmount;
		return true;
	}

	function getAlphaRate() external view override returns (uint256)
	{
		return alphaRate;
	}

	function setAlphaRate(uint256 _alphaRate) onlyOwner external override returns (bool)
	{
		alphaRate = _alphaRate;
		return true;
	}

	function getAlphaLastUpdated() external view override returns (uint256)
	{
		return alphaLastUpdated;
	}

	function setAlphaLastUpdated(uint256 _alphaLastUpdated) onlyOwner external override returns (bool)
	{
		alphaLastUpdated = _alphaLastUpdated;
		return true;
	}

	function getRewardParamUpdateRewardPerBlock() external view override returns (uint256)
	{
		return rewardParamUpdateRewardPerBlock;
	}

	function setRewardParamUpdateRewardPerBlock(uint256 _rewardParamUpdateRewardPerBlock) onlyOwner external override returns (bool)
	{
		rewardParamUpdateRewardPerBlock = _rewardParamUpdateRewardPerBlock;
		return true;
	}

	function getRewardParamUpdated() external view override returns (uint256)
	{
		return rewardParamUpdated;
	}

	function setRewardParamUpdated(uint256 _rewardParamUpdated) onlyManager external override returns (bool)
	{
		rewardParamUpdated = _rewardParamUpdated;
		return true;
	}

	function getInterestUpdateRewardPerblock() external view override returns (uint256)
	{
		return interestUpdateRewardPerblock;
	}

	function setInterestUpdateRewardPerblock(uint256 _interestUpdateRewardPerblock) onlyOwner external override returns (bool)
	{
		interestUpdateRewardPerblock = _interestUpdateRewardPerblock;
		return true;
	}

	function getInterestRewardUpdated() external view override returns (uint256)
	{
		return interestRewardLastUpdated;
	}

	function setInterestRewardUpdated(uint256 _interestRewardLastUpdated) onlyManager external override returns (bool)
	{
		interestRewardLastUpdated = _interestRewardLastUpdated;
		return true;
	}

	function setManagerAddr(address _managerAddr) onlyOwner external override returns (bool)
	{
		_setManagerAddr(_managerAddr);
		return true;
	}

	function _setManagerAddr(address _managerAddr) internal returns (bool)
	{
		require(_managerAddr != address(0), "error: manager address null");
		managerAddr = _managerAddr;
		return true;
	}

	function setLiquidationManagerAddr(address _liquidationManagerAddr) onlyManager external override returns (bool)
	{
		liquidationManagerAddr = _liquidationManagerAddr;
		return true;
	}

	function getLiquidationManagerAddr() external view override returns (address)
	{
		return liquidationManagerAddr;
	}

	function setTokenHandler(uint256 handlerID, address handlerAddr) onlyManager external override returns (bool)
	{
		TokenHandler memory handler;
		handler.addr = handlerAddr;
		handler.exist = true;
		handler.support = true;
		/* regist Storage*/
		tokenHandlers[handlerID] = handler;
		tokenHandlerList.push(handlerID);
	}

	function setTokenHandlerAddr(uint256 handlerID, address handlerAddr) onlyOwner external override returns (bool)
	{
		tokenHandlers[handlerID].addr = handlerAddr;
		return true;
	}

	function setTokenHandlerExist(uint256 handlerID, bool exist) onlyOwner external override returns (bool)
	{
		tokenHandlers[handlerID].exist = exist;
		return true;
	}

	function setTokenHandlerSupport(uint256 handlerID, bool support) onlyManager external override returns (bool)
	{
		tokenHandlers[handlerID].support = support;
		return true;
	}

	function getTokenHandlerInfo(uint256 handlerID) external view override returns (bool, address)
	{
		return (tokenHandlers[handlerID].support, tokenHandlers[handlerID].addr);
	}

	function getTokenHandlerAddr(uint256 handlerID) external view override returns (address)
	{
		return tokenHandlers[handlerID].addr;
	}

	function getTokenHandlerExist(uint256 handlerID) external view override returns (bool)
	{
		return tokenHandlers[handlerID].exist;
	}

	function getTokenHandlerSupport(uint256 handlerID) external view override returns (bool)
	{
		return tokenHandlers[handlerID].support;
	}

	function getTokenHandlerID(uint256 index) external view override returns (uint256)
	{
		return tokenHandlerList[index];
	}

	function getOwner() public view returns (address)
	{
		return owner;
	}
}