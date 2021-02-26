/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// File: contracts/interfaces/marketManagerInterface.sol

pragma solidity 0.6.12;

interface marketManagerInterface  {
	function setBreakerTable(address _target, bool _status) external returns (bool);

	function getCircuitBreaker() external view returns (bool);
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);

	function handlerRegister(uint256 handlerID, address tokenHandlerAddr) external returns (bool);

	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getTokenHandlerPrice(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);

	function getTokenHandlersLength() external view returns (uint256);
	function setTokenHandlersLength(uint256 _tokenHandlerLength) external returns (bool);

	function getTokenHandlerID(uint256 index) external view returns (uint256);
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view returns (uint256);

	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view returns (uint256, uint256);

	function getUserTotalIntraCreditAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserLimitIntraAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserCollateralizableAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);

	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);

	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view returns (uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) external returns (uint256);

	function setLiquidationManager(address liquidationManagerAddr) external returns (bool);

	function rewardClaimAll(address payable userAddr) external returns (bool);

	function updateRewardParams(address payable userAddr) external returns (bool);
	function interestUpdateReward() external returns (bool);
	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);

	function setOracleProxy(address oracleProxyAddr) external returns (bool);

	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool);
	function ownerRewardTransfer(uint256 _amount) external returns (bool);
}

// File: contracts/interfaces/proxyContractInterface.sol

pragma solidity 0.6.12;

interface proxyContractInterface  {
	function handlerProxy(bytes memory data) external returns (bool, bytes memory);
	function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
	function siProxy(bytes memory data) external returns (bool, bytes memory);
	function siViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/front/callProxy.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title BiFi's proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract callProxyManagerCallProxyHandlerCallProxyMarketCallProxyUserCallProxySISafeMath  {
	marketManagerInterface callProxyManager_marketManager;

	struct callProxyHandler_ProxyInfo {
		bool result;
		bytes returnData;
		bytes data;
		bytes proxyData;
	}

	struct callProxyMarket_HandlerAsset {
		uint256 handlerID;
		address handlerAddr;
		uint256 tokenPrice;
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 depositInterestRate;
		uint256 borrowInterestRate;
	}

	struct callProxyUser_UserHandlerAsset {
		uint256 handlerID;
		address handlerAddr;
		uint256 tokenPrice;
		uint256 depositAmount;
		uint256 borrowAmount;
		uint256 depositInterestAmount;
		uint256 borrowInterestAmount;
		uint256 depositInterestRate;
		uint256 borrowInterestRate;
		uint256 borrowLimit;
		uint256 userMaxWithdrawAmount;
		uint256 userMaxBorrowAmount;
		uint256 userMaxRepayAmount;
		uint256 limitOfAction;
	}

	struct callProxyUser_UserAsset {
		uint256 userTotalBorrowLimitAsset;
		uint256 userTotalMarginCallLimitAsset;
		uint256 userDepositCreditAsset;
		uint256 userBorrowCreditAsset;
	}

	uint256 callProxySI_blocksPerDay = 6646;

	struct callProxySI_HandlerInfo {
		bool support;
		address tokenHandlerAddr;
		string tokenName;
		uint256 betaRate;
		uint256 betaBaseTotal;
	}

	struct callProxySI_MarketRewardInfo {
		uint256 handlerID;
		uint256 tokenPrice;
		uint256 dailyReward;
		uint256 claimedReward;
		uint256 depositReward;
		uint256 borrowReward;
	}

	struct callProxySI_GlobalRewardInfo {
		uint256 totalReward;
		uint256 dailyReward;
		uint256 claimedReward;
		uint256 remainReward;
	}

	struct callProxySI_ManagerGlobalReward {
		uint256 perBlock;
		uint256 decrement;
		uint256 totalAmount;
		uint256 claimableReward;
	}

	struct callProxySI_HandlerMarketReward {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardPerBlock;
	}

	struct callProxySI_UserReward {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardAmount;
	}

	uint256 constant safeMath_unifiedPoint = 10 ** 18;

	constructor (address _marketManagerAddr) public
	{
		callProxyManager_marketManager = marketManagerInterface(_marketManagerAddr);
	}

	function callProxyManager_getTokenHandlerInfo(uint256 handlerID) public view returns (bool, address, string memory)
	{
		return callProxyManager_marketManager.getTokenHandlerInfo(handlerID);
	}

	function callProxyManager_getManagerAddr() public view returns (address)
	{
		return address(callProxyManager_marketManager);
	}

	function callProxyManager_getTokenPrice(uint256 handlerID) public view returns (uint256)
	{
		return callProxyManager_marketManager.getTokenHandlerPrice(handlerID);
	}

	function callProxyManager_getUserTotalIntraCreditAsset(address payable userAddr) public view returns (uint256, uint256)
	{
		return callProxyManager_marketManager.getUserTotalIntraCreditAsset(userAddr);
	}

	function callProxyManager_getTokenHandlersLength() public view returns (uint256)
	{
		return callProxyManager_marketManager.getTokenHandlersLength();
	}

	function callProxyManager_getTokenHandlerID(uint256 index) public view returns (uint256)
	{
		return callProxyManager_marketManager.getTokenHandlerID(index);
	}

	function callProxyManager_getGlobalRewardInfo() public view returns (uint256, uint256, uint256)
	{
		return callProxyManager_marketManager.getGlobalRewardInfo();
	}

	function callProxyManager_getCircuitBreaker() public view returns (bool)
	{
		return callProxyManager_marketManager.getCircuitBreaker();
	}

	function callProxyManager_getUserLimitIntraAsset(address payable userAddr) public view returns (uint256, uint256)
	{
		return callProxyManager_marketManager.getUserLimitIntraAsset(userAddr);
	}

	function callProxyHandler_getUserAmount(address tokenHandlerAddr, address payable userAddr) public view returns (uint256, uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserAmount(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256, uint256));
	}

	function callProxyHandler_getDepositTotalAmount(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getDepositTotalAmount()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getBorrowTotalAmount(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getBorrowTotalAmount()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getUserMaxWithdrawAmount(address tokenHandlerAddr, address payable userAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserMaxWithdrawAmount(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getUserMaxBorrowAmount(address tokenHandlerAddr, address payable userAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserMaxBorrowAmount(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getUserMaxRepayAmount(address tokenHandlerAddr, address payable userAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserMaxRepayAmount(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getUserAmountWithInterest(address tokenHandlerAddr, address payable userAddr) public view returns (uint256, uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserAmountWithInterest(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256, uint256));
	}

	function callProxyHandler_getSIRandBIR(address tokenHandlerAddr) public view returns (uint256, uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getSIRandBIR()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256, uint256));
	}

	function callProxyHandler_getMarketRewardInfo(address tokenHandlerAddr) public view returns (uint256, uint256, uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getMarketRewardInfo()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.siViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256, uint256, uint256));
	}

	function callProxyHandler_getUserRewardInfo(address tokenHandlerAddr, address payable userAddr) public view returns (uint256, uint256, uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getUserRewardInfo(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.siViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256, uint256, uint256));
	}

	function callProxyHandler_getBetaRate(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getBetaRate()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.siViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getBetaRateBaseTotalAmount(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getBetaRateBaseTotalAmount()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.siViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getBetaRateBaseUserAmount(address tokenHandlerAddr, address payable userAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getBetaRateBaseUserAmount(address)", userAddr);
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.siViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getBorrowLimit(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getTokenHandlerBorrowLimit()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyHandler_getLimitOfAction(address tokenHandlerAddr) public view returns (uint256)
	{
		callProxyHandler_ProxyInfo memory proxyInfo;
		proxyContractInterface tokenHandler = proxyContractInterface(tokenHandlerAddr);
		proxyInfo.data = abi.encodeWithSignature("getLimitOfAction()");
		(proxyInfo.result, proxyInfo.returnData) = tokenHandler.handlerViewProxy(proxyInfo.data);
		require(proxyInfo.result, string(proxyInfo.returnData));
		return abi.decode(proxyInfo.returnData, (uint256));
	}

	function callProxyMarket_getMarket() public view returns (callProxyMarket_HandlerAsset[] memory, bool)
	{
		uint256 tokenHandlerLength = callProxyManager_getTokenHandlersLength();
		callProxyMarket_HandlerAsset[] memory handlerAssets = new callProxyMarket_HandlerAsset[](tokenHandlerLength);
		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			bool support;
			address handlerAddr;
			string memory tokenName;
			(support, handlerAddr, tokenName) = callProxyManager_getTokenHandlerInfo(handlerID);
			if (!support)
			{
				continue;
			}

			handlerAssets[handlerID].tokenPrice = callProxyManager_getTokenPrice(handlerID);
			handlerAssets[handlerID].depositTotalAmount = callProxyHandler_getDepositTotalAmount(handlerAddr);
			handlerAssets[handlerID].borrowTotalAmount = callProxyHandler_getBorrowTotalAmount(handlerAddr);
			(handlerAssets[handlerID].depositInterestRate, handlerAssets[handlerID].borrowInterestRate) = callProxyHandler_getSIRandBIR(handlerAddr);
			handlerAssets[handlerID].handlerID = handlerID;
			handlerAssets[handlerID].handlerAddr = handlerAddr;
		}

		return (handlerAssets, callProxyManager_getCircuitBreaker());
	}

	function callProxyUser_getUser(address payable userAddr) public view returns (callProxyUser_UserHandlerAsset[] memory, callProxyUser_UserAsset memory)
	{
		callProxyUser_UserAsset memory userAsset;
		(userAsset.userTotalBorrowLimitAsset, userAsset.userTotalMarginCallLimitAsset) = callProxyManager_getUserLimitIntraAsset(userAddr);
		(userAsset.userDepositCreditAsset, userAsset.userBorrowCreditAsset) = callProxyManager_getUserTotalIntraCreditAsset(userAddr);
		uint256 tokenHandlerLength = callProxyManager_getTokenHandlersLength();
		callProxyUser_UserHandlerAsset[] memory userHandlerAssets = new callProxyUser_UserHandlerAsset[](tokenHandlerLength);
		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			bool support;
			address tokenHandlerAddr;
			string memory tokenName;
			(support, tokenHandlerAddr, tokenName) = callProxyManager_getTokenHandlerInfo(handlerID);
			if (!support)
			{
				continue;
			}

			userHandlerAssets[handlerID].handlerID = handlerID;
			userHandlerAssets[handlerID].tokenPrice = callProxyManager_getTokenPrice(handlerID);
			(userHandlerAssets[handlerID].depositAmount, userHandlerAssets[handlerID].borrowAmount) = callProxyHandler_getUserAmount(tokenHandlerAddr, userAddr);
			(userHandlerAssets[handlerID].depositInterestRate, userHandlerAssets[handlerID].borrowInterestRate) = callProxyHandler_getSIRandBIR(tokenHandlerAddr);
			(userHandlerAssets[handlerID].depositInterestAmount, userHandlerAssets[handlerID].borrowInterestAmount) = callProxyHandler_getUserAmountWithInterest(tokenHandlerAddr, userAddr);
			/* multi actions in 1 blocks */
			if (userHandlerAssets[handlerID].depositAmount > userHandlerAssets[handlerID].depositInterestAmount)
			{
				userHandlerAssets[handlerID].depositInterestAmount = 0;
			}
			else
			{
				userHandlerAssets[handlerID].depositInterestAmount = userHandlerAssets[handlerID].depositInterestAmount - userHandlerAssets[handlerID].depositAmount;
			}

			if (userHandlerAssets[handlerID].borrowAmount > userHandlerAssets[handlerID].borrowInterestAmount)
			{
				userHandlerAssets[handlerID].borrowInterestAmount = 0;
			}
			else
			{
				userHandlerAssets[handlerID].borrowInterestAmount = userHandlerAssets[handlerID].borrowInterestAmount - userHandlerAssets[handlerID].borrowAmount;
			}

			userHandlerAssets[handlerID].handlerAddr = tokenHandlerAddr;
			userHandlerAssets[handlerID].borrowLimit = callProxyHandler_getBorrowLimit(tokenHandlerAddr);
			userHandlerAssets[handlerID].userMaxWithdrawAmount = callProxyHandler_getUserMaxWithdrawAmount(tokenHandlerAddr, userAddr);
			userHandlerAssets[handlerID].userMaxBorrowAmount = callProxyHandler_getUserMaxBorrowAmount(tokenHandlerAddr, userAddr);
			userHandlerAssets[handlerID].userMaxRepayAmount = callProxyHandler_getUserMaxRepayAmount(tokenHandlerAddr, userAddr);
			userHandlerAssets[handlerID].limitOfAction = callProxyHandler_getLimitOfAction(tokenHandlerAddr);
		}

		return (userHandlerAssets, userAsset);
	}

	function callProxySI_getSI(address payable userAddr) public view returns (address, callProxySI_MarketRewardInfo[] memory, callProxySI_GlobalRewardInfo memory, uint256)
	{
		callProxySI_HandlerInfo memory handlerInfo;
		callProxySI_GlobalRewardInfo memory globalRewardInfo;
		callProxySI_ManagerGlobalReward memory managerGlobalReward;
		(managerGlobalReward.perBlock, managerGlobalReward.decrement, managerGlobalReward.totalAmount) = callProxyManager_getGlobalRewardInfo();
		globalRewardInfo.totalReward = 400000000 * (10 ** 18);
		globalRewardInfo.dailyReward = safeMath_mul(managerGlobalReward.perBlock, callProxySI_blocksPerDay);
		globalRewardInfo.remainReward = managerGlobalReward.totalAmount;
		globalRewardInfo.claimedReward = globalRewardInfo.totalReward - globalRewardInfo.remainReward;
		uint256 tokenHandlerLength = callProxyManager_getTokenHandlersLength();
		callProxySI_MarketRewardInfo[] memory marketRewardInfo = new callProxySI_MarketRewardInfo[](tokenHandlerLength);
		for (uint256 handlerID = 0; handlerID < tokenHandlerLength; handlerID++)
		{
			(handlerInfo.support, handlerInfo.tokenHandlerAddr, handlerInfo.tokenName) = callProxyManager_getTokenHandlerInfo(handlerID);
			if (!handlerInfo.support)
			{
				continue;
			}

			callProxySI_HandlerMarketReward memory handlerMarketReward;
			(handlerMarketReward.rewardLane, handlerMarketReward.rewardLaneUpdateAt, handlerMarketReward.rewardPerBlock) = callProxyHandler_getMarketRewardInfo(handlerInfo.tokenHandlerAddr);
			managerGlobalReward.claimableReward = safeMath_add(managerGlobalReward.claimableReward, callProxySI_rewardClaimView(handlerInfo.tokenHandlerAddr, userAddr, handlerMarketReward.rewardLane, handlerMarketReward.rewardLaneUpdateAt, handlerMarketReward.rewardPerBlock));
			handlerInfo.betaRate = callProxyHandler_getBetaRate(handlerInfo.tokenHandlerAddr);
			handlerInfo.betaBaseTotal = callProxyHandler_getBetaRateBaseTotalAmount(handlerInfo.tokenHandlerAddr);
			marketRewardInfo[handlerID].handlerID = handlerID;
			marketRewardInfo[handlerID].tokenPrice = callProxyManager_getTokenPrice(handlerID);
			marketRewardInfo[handlerID].dailyReward = safeMath_mul(handlerMarketReward.rewardPerBlock, callProxySI_blocksPerDay);
			marketRewardInfo[handlerID].claimedReward = 0;
			if (handlerInfo.betaBaseTotal == 0)
			{
				marketRewardInfo[handlerID].depositReward = 0;
				marketRewardInfo[handlerID].borrowReward = 0;
			}
			else
			{
				uint256 rewardUnit = safeMath_unifiedMul(safeMath_unifiedDiv(10 ** 18, handlerInfo.betaBaseTotal), marketRewardInfo[handlerID].dailyReward);
				marketRewardInfo[handlerID].depositReward = safeMath_unifiedMul(handlerInfo.betaRate, rewardUnit);
				marketRewardInfo[handlerID].borrowReward = safeMath_unifiedMul(safeMath_sub(10 ** 18, handlerInfo.betaRate), rewardUnit);
			}

		}

		return (callProxyManager_getManagerAddr(), marketRewardInfo, globalRewardInfo, managerGlobalReward.claimableReward);
	}

	function callProxySI_rewardClaimView(address handlerAddr, address payable userAddr, uint256 marketRewardLane, uint256 marketRewardLaneUpdateAt, uint256 marketRewardPerBlock) public view returns (uint256)
	{
		callProxySI_UserReward memory userReward;
		(userReward.rewardLane, userReward.rewardLaneUpdateAt, userReward.rewardAmount) = callProxyHandler_getUserRewardInfo(handlerAddr, userAddr);
		uint256 deltaBlocks = safeMath_sub(block.number, marketRewardLaneUpdateAt);
		uint256 lane = callProxySI_calcLane(handlerAddr, marketRewardLane, marketRewardPerBlock, deltaBlocks);
		uint256 uncollectedReward = callProxySI_calcRewardAmount(handlerAddr, lane, userReward.rewardLane, userAddr);
		uint256 totalReward = safeMath_add(userReward.rewardAmount, uncollectedReward);
		return totalReward;
	}

	function callProxySI_calcLane(address handlerAddr, uint256 currentLane, uint256 rewardPerBlock, uint256 deltaBlocks) internal view returns (uint256)
	{
		uint256 betaRateBaseTotalAmount = callProxyHandler_getBetaRateBaseTotalAmount(handlerAddr);
		if (betaRateBaseTotalAmount != 0)
		{
			uint256 distance = safeMath_mul(deltaBlocks, safeMath_unifiedDiv(rewardPerBlock, betaRateBaseTotalAmount));
			return safeMath_add(currentLane, distance);
		}
		else
		{
			return currentLane;
		}

	}

	function callProxySI_calcRewardAmount(address handlerAddr, uint256 lane, uint256 userLane, address payable userAddr) internal view returns (uint256)
	{
		uint256 betaRateBaseUserAmount = callProxyHandler_getBetaRateBaseUserAmount(handlerAddr, userAddr);
		return safeMath_unifiedMul(betaRateBaseUserAmount, safeMath_sub(lane, userLane));
	}

	function safeMath_add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "add overflow");
		return c;
	}

	function safeMath_sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__sub(a, b, "sub overflow");
	}

	function safeMath_mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__mul(a, b);
	}

	function safeMath_div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__div(a, b, "div by zero");
	}

	function safeMath_mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__mod(a, b, "mod by zero");
	}

	function safeMath__sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function safeMath__mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function safeMath__div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function safeMath__mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b != 0, errorMessage);
		return a % b;
	}

	function safeMath_unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__div(safeMath__mul(a, safeMath_unifiedPoint), b, "unified div by zero");
	}

	function safeMath_unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return safeMath__div(safeMath__mul(a, b), safeMath_unifiedPoint, "unified mul by zero");
	}

	function safeMath_signedAdd(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a + b;
		require(((b >= 0) && (c >= a)) || ((b < 0) && (c < a)), "SignedSafeMath: addition overflow");
		return c;
	}

	function safeMath_signedSub(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a - b;
		require(((b >= 0) && (c <= a)) || ((b < 0) && (c > a)), "SignedSafeMath: subtraction overflow");
		return c;
	}
}