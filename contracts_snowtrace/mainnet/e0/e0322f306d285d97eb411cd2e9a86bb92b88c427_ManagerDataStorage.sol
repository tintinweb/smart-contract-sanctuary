/**
 *Submitted for verification at snowtrace.io on 2021-12-02
*/

// File: contracts/interfaces/IManagerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's manager data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IManagerDataStorage  {
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

// File: contracts/context/BlockContext.sol



pragma solidity 0.6.12;

/**
 * @title BiFi's BlockContext contract
 * @notice BiFi getter Contract for Block Context Information
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract BlockContext {
    function _blockContext() internal view returns(uint256 context) {
        // block number chain
        // context = block.number;

        // block timestamp chain
        context = block.timestamp;
    }
}

// File: contracts/marketManager/managerDataStorage/ManagerDataStorage.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's manager data storage contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract ManagerDataStorage is IManagerDataStorage, ManagerDataStorageErrors, BlockContext {
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
		require((msgSender == managerAddr) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	constructor () public
	{
		owner = msg.sender;
		uint256 this_block_number = _blockContext();

		globalRewardPerBlock = 0;
		globalRewardDecrement = 1;
		globalRewardTotalAmount = 0;

		alphaRate = 2 * (10 ** 17);

		alphaLastUpdated = this_block_number;
		rewardParamUpdated = this_block_number;
		interestRewardLastUpdated = this_block_number;
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
		require(_managerAddr != address(0), NULL_ADDRESS);
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