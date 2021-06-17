/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: contracts/SafeMath.sol
pragma solidity ^0.6.12;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

/**
 * @title BiFi's safe-math Contract
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
library SafeMath {
  uint256 internal constant unifiedPoint = 10 ** 18;
	/******************** Safe Math********************/
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "a");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "s");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "d");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a* b;
		require((c / a) == b, "m");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "d");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "m");
	}
}

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

// File: contracts/interfaces/IOracleProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's oracle proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IOracleProxy  {
	function getTokenPrice(uint256 tokenID) external view returns (uint256);

	function getOracleFeed(uint256 tokenID) external view returns (address, uint256);
	function setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals, bool needPriceConvert, uint256 priceConvertID) external returns (bool);
}

// File: contracts/interfaces/IERC20.sol
// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
pragma solidity 0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IObserver.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Observer interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IObserver {
    function getAlphaBaseAsset() external view returns (uint256[] memory);
    function setChainGlobalRewardPerblock(uint256 _idx, uint256 globalRewardPerBlocks) external returns (bool);
    function updateChainMarketInfo(uint256 _idx, uint256 chainDeposit, uint256 chainBorrow) external returns (bool);
}

// File: contracts/interfaces/IProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IProxy  {
	function handlerProxy(bytes memory data) external returns (bool, bytes memory);
	function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
	function siProxy(bytes memory data) external returns (bool, bytes memory);
	function siViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/interfaces/IMarketHandler.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market handler interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketHandler  {
	function setCircuitBreaker(bool _emergency) external returns (bool);
	function setCircuitBreakWithOwner(bool _emergency) external returns (bool);

	function getTokenName() external view returns (string memory);

	function ownershipTransfer(address payable newOwner) external returns (bool);

	function deposit(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);
	function withdraw(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function borrow(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
	function repay(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);

	function executeFlashloan(
		address receiverAddress,
		uint256 amount
  ) external returns (bool);

	function depositFlashloanFee(
		uint256 amount
	) external returns (bool);

  function convertUnifiedToUnderlying(uint256 unifiedTokenAmount) external view returns (uint256);
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 liquidationAmountWithReward, address payable liquidator) external returns (uint256);

	function getTokenHandlerLimit() external view returns (uint256, uint256);
  function getTokenHandlerBorrowLimit() external view returns (uint256);
	function getTokenHandlerMarginCallLimit() external view returns (uint256);
	function setTokenHandlerBorrowLimit(uint256 borrowLimit) external returns (bool);
	function setTokenHandlerMarginCallLimit(uint256 marginCallLimit) external returns (bool);

  function getTokenLiquidityAmountWithInterest(address payable userAddr) external view returns (uint256);

	function getUserAmountWithInterest(address payable userAddr) external view returns (uint256, uint256);
	function getUserAmount(address payable userAddr) external view returns (uint256, uint256);

	function getUserMaxBorrowAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxWithdrawAmount(address payable userAddr) external view returns (uint256);
	function getUserMaxRepayAmount(address payable userAddr) external view returns (uint256);

	function checkFirstAction() external returns (bool);
	function applyInterest(address payable userAddr) external returns (uint256, uint256);

	function reserveDeposit(uint256 unifiedTokenAmount) external payable returns (bool);
	function reserveWithdraw(uint256 unifiedTokenAmount) external returns (bool);

	function withdrawFlashloanFee(uint256 unifiedTokenAmount) external returns (bool);

	function getDepositTotalAmount() external view returns (uint256);
	function getBorrowTotalAmount() external view returns (uint256);

	function getSIRandBIR() external view returns (uint256, uint256);

  function getERC20Addr() external view returns (address);
}

// File: contracts/interfaces/IServiceIncentive.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's si interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IServiceIncentive  {
	function setCircuitBreakWithOwner(bool emergency) external returns (bool);
	function setCircuitBreaker(bool emergency) external returns (bool);

	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) external returns (bool);
	function updateRewardLane(address payable userAddr) external returns (bool);

	function getBetaRateBaseTotalAmount() external view returns (uint256);
	function getBetaRateBaseUserAmount(address payable userAddr) external view returns (uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);

	function getUserRewardInfo(address payable userAddr) external view returns (uint256, uint256, uint256);

	function claimRewardAmountUser(address payable userAddr) external returns (uint256);
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

// File: contracts/marketManager/ManagerSlot.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's Slot contract
 * @notice Manager Slot Definitions & Allocations
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract ManagerSlot is ManagerErrors {
	using SafeMath for uint256;

	address public owner;
	mapping(address => bool) operators;
	mapping(address => Breaker) internal breakerTable;

	bool public emergency = false;

	IManagerDataStorage internal dataStorageInstance;
	IOracleProxy internal oracleProxy;

	/* feat: manager reward token instance*/
	IERC20 internal rewardErc20Instance;

	IObserver public Observer;

	address public slotSetterAddr;
	address public handlerManagerAddr;
	address public flashloanAddr;

  // BiFi-X
  address public positionStorageAddr;
  address public nftAddr;

	uint256 public tokenHandlerLength;

  struct FeeRateParams {
    uint256 unifiedPoint;
    uint256 minimum;
    uint256 slope;
    uint256 discountRate;
  }

  struct HandlerFlashloan {
      uint256 flashFeeRate;
      uint256 discountBase;
      uint256 feeTotal;
  }

  mapping(uint256 => HandlerFlashloan) public handlerFlashloan;

	struct UserAssetsInfo {
		uint256 depositAssetSum;
		uint256 borrowAssetSum;
		uint256 marginCallLimitSum;
		uint256 depositAssetBorrowLimitSum;
		uint256 depositAsset;
		uint256 borrowAsset;
		uint256 price;
		uint256 callerPrice;
		uint256 depositAmount;
		uint256 borrowAmount;
		uint256 borrowLimit;
		uint256 marginCallLimit;
		uint256 callerBorrowLimit;
		uint256 userBorrowableAsset;
		uint256 withdrawableAsset;
	}

	struct Breaker {
		bool auth;
		bool tried;
	}

	struct ContractInfo {
		bool support;
		address addr;
    address tokenAddr;

    uint256 expectedBalance;
    uint256 afterBalance;

		IProxy tokenHandler;
		bytes data;

		IMarketHandler handlerFunction;
		IServiceIncentive siFunction;

		IOracleProxy oracleProxy;
		IManagerDataStorage managerDataStorage;
	}

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	modifier onlyHandler(uint256 handlerID) {
		_isHandler(handlerID);
		_;
	}

	modifier onlyOperators {
		address payable sender = msg.sender;
		require(operators[sender] || sender == owner);
		_;
	}

	function _isHandler(uint256 handlerID) internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getTokenHandlerAddr(handlerID)) || (msgSender == owner), ONLY_HANDLER);
	}

	modifier onlyLiquidationManager {
		_isLiquidationManager();
		_;
	}

	function _isLiquidationManager() internal view {
		address msgSender = msg.sender;
		require((msgSender == dataStorageInstance.getLiquidationManagerAddr()) || (msgSender == owner), ONLY_LIQUIDATION_MANAGER);
	}

	modifier circuitBreaker {
		_isCircuitBreak();
		_;
	}

	function _isCircuitBreak() internal view {
		require((!emergency) || (msg.sender == owner), CIRCUIT_BREAKER);
	}

	modifier onlyBreaker {
		_isBreaker();
		_;
	}

	function _isBreaker() internal view {
		require(breakerTable[msg.sender].auth, ONLY_BREAKER);
	}
}

// File: contracts/interfaces/IFlashloanReceiver.sol
pragma solidity 0.6.12;

interface IFlashloanReceiver {
    function executeOperation(
      address reserve,
      uint256 amount,
      uint256 fee,
      bytes calldata params
    ) external returns (bool);
}

// File: contracts/interfaces/utils/Bifi-X/IPositionStorage.sol
pragma solidity 0.6.12;
interface IPositionStorage {
  function createStrategy(address strategyLogic) external returns (bool);
  function setStrategy(uint256 strategyID, address strategyLogic) external returns (bool);
  function getStrategy(uint256 strategyID) external view returns (address);
  function newUserProduct(address user, address product) external returns (bool);
  function getUserProducts(address user) external view returns (address[] memory);
  function setFactory(address _factory) external returns (bool);
  function getNFTID(address product) external view returns (uint256);
}

// File: contracts/interfaces/utils/IERC721.sol
pragma solidity 0.6.12;

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface IERC721
{

  /**
   * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
   * assigned and queryable owner not equal to the zero address.
   * @return Total supply of NFTs.
   */
  function totalSupply()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
   * @param _index A counter less than `totalSupply()`.
   * @return Token id.
   */
  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function mint(
    address _to,
    uint256 _tokenId
  ) external ;

  /**
   * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
   * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
   * representing invalid NFTs.
   * @param _owner An address where we are interested in NFTs owned by them.
   * @param _index A counter less than `balanceOf(_owner)`.
   * @return Token id.
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);

}

// File: contracts/marketManager/ManagerFlashloan.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
* @title BiFi-X ManagerFlashloan contract
* @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
*/
contract ManagerFlashLoan is ManagerSlot {
  	event FlashLoan(address receiver, address asset, uint256 amount, uint256 fee);

    /**
    * @dev Withdraw accumulated flashloan fee
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @return Whether or not succeed
    */
    function withdrawFlashloanFee(uint256 handlerID) onlyOwner external returns (bool) {
      ContractInfo memory handlerInfo;
      (handlerInfo.support, handlerInfo.addr) = dataStorageInstance.getTokenHandlerInfo(handlerID);

      if(handlerInfo.support) {
        handlerInfo.tokenHandler = IProxy(handlerInfo.addr);

        (bool success, ) = handlerInfo.tokenHandler.handlerProxy(
              abi.encodeWithSelector(
                handlerInfo.handlerFunction
                .withdrawFlashloanFee.selector,
                handlerFlashloan[handlerID].feeTotal
              )
            );
        require(success);

        handlerFlashloan[handlerID].feeTotal = 0;
      }

      return true;
    }

    /**
    * @dev Execute flashloan
    * @param handlerID The ID of the token handler to borrow.
    * @param receiverAddress The address of receive callback contract
    * @param amount The amount of borrow through flashloan
    * @param params The encode metadata of user
    * @return Whether or not succeed
    */
    function flashloan(
      uint256 handlerID,
      address receiverAddress,
      uint256 amount,
      bytes calldata params
    ) external returns (bool) {
      return _flashloan(handlerID, receiverAddress, amount, params);
    }

    /**
    * @dev Execute flashloan
    * @param handlerID The ID of the token handler to borrow.
    * @param receiverAddress The address of receive callback contract
    * @param amount The amount of borrow through flashloan
    * @param params The encode metadata of user
    * @return Whether or not succeed
    */
    function _flashloan(
      uint256 handlerID,
      address receiverAddress,
      uint256 amount,
      bytes calldata params
    ) internal returns (bool) {
        ContractInfo memory handlerInfo;
        (handlerInfo.support, handlerInfo.addr) = dataStorageInstance.getTokenHandlerInfo(handlerID);

        require(handlerInfo.support);
        handlerInfo.tokenHandler = IProxy(handlerInfo.addr);

        // receiver to be called after the eth or token send is executed
        IFlashloanReceiver receiver = IFlashloanReceiver(receiverAddress);

        bool success;

        // get flashloan fee
        uint256 fee = _getFee(handlerID, amount);

        // memory before contract balance
        // for successfuly repay flashloan amount and fee
        (handlerInfo.tokenAddr, handlerInfo.expectedBalance) = _getThisBalance(handlerInfo, handlerID);
        handlerInfo.expectedBalance = handlerInfo.expectedBalance.add(_convertUnifiedToUnderlying(handlerInfo, amount)).add(_convertUnifiedToUnderlying(handlerInfo, fee));

        // send eth or token through handler
        (success, handlerInfo.data) = handlerInfo.tokenHandler.handlerProxy(
          abi.encodeWithSelector(
            handlerInfo.handlerFunction
            .executeFlashloan.selector,
            receiverAddress,
            amount
          )
        );
        // catch error in handler
        require(success);

        // call FlashloanReceiver executeOperation function
        success = receiver.executeOperation(handlerInfo.tokenAddr, _convertUnifiedToUnderlying(handlerInfo, amount), _convertUnifiedToUnderlying(handlerInfo, fee), params);
        require(success);

        // get contract balance after executeOperation function
        (, handlerInfo.afterBalance) = _getThisBalance(handlerInfo, handlerID);

        // handlerInfo.afterBalance gte than handlerInfo.expectedBalance
        // If the user has not made a successful repayment, occur revert
        require(handlerInfo.expectedBalance <= handlerInfo.afterBalance);

        if(handlerID == 0) { // coin case
          // payback: over repay amount
          if(handlerInfo.expectedBalance < handlerInfo.afterBalance){
            msg.sender.transfer(handlerInfo.afterBalance.sub(handlerInfo.expectedBalance));
          }
          // recovery liquidity
          payable(handlerInfo.addr).transfer(handlerInfo.expectedBalance);


        } else { // token case
          IERC20 token = IERC20(handlerInfo.tokenAddr);
          // payback: over repay amount
          if(handlerInfo.afterBalance > handlerInfo.expectedBalance){
            token.transfer(msg.sender, handlerInfo.afterBalance.sub(handlerInfo.expectedBalance));
          }
          // recovery liquidity
          token.transfer(handlerInfo.addr, handlerInfo.expectedBalance);
        }

        // fee store in manager slot
        handlerFlashloan[handlerID].feeTotal = handlerFlashloan[handlerID].feeTotal.add(fee);

        // fee to handler reserve
        (success, handlerInfo.data) = handlerInfo.tokenHandler.handlerProxy(
          abi.encodeWithSelector(
            handlerInfo.handlerFunction
            .depositFlashloanFee.selector,
            fee
          )
        );

        // if error in handler
        require(success);

        emit FlashLoan(receiverAddress, handlerInfo.addr, amount, fee);
        return true;
    }

    /**
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @return The amount of fee accumlated to handler
    */
    function getFeeTotal(uint256 handlerID) external view returns (uint256) {
      return handlerFlashloan[handlerID].feeTotal;
    }

    /**
    * @dev Get flashloan fee for flashloan amount
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @return The amount of fee for flashloan amount
    */
    function getFee(uint256 handlerID, uint256 amount) external view returns (uint256) {
      return _getFee(handlerID, amount);
    }

    /**
    * @dev Get flashloan fee for flashloan amount
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @param amount The amount of flashloan amount
    * @return The amount of fee for flashloan amount
    */
    function _getFee(uint256 handlerID, uint256 amount) internal view returns (uint256) {
      FeeRateParams memory feeRateParams;

      uint256 flashloanFeeRate = handlerFlashloan[handlerID].flashFeeRate;

       if(positionStorageAddr == address(0)) {
        return amount.unifiedMul(flashloanFeeRate);
      }

      // discount for BiFi-X User
      IPositionStorage positionStorage = IPositionStorage(positionStorageAddr);
      uint256 nftID = positionStorage.getNFTID(msg.sender);

      // msg.sender is BiFi-X Product
      if(nftID > 0) {
        IERC721 nft = IERC721(nftAddr);

        address originOwner = nft.ownerOf(nftID);
        uint256 bifiBalance = rewardErc20Instance.balanceOf(originOwner);
        if(bifiBalance >= handlerFlashloan[handlerID].discountBase) {
          // feeRate * (0.1 + 0.9 * min(1, discountBase / bifiAmount))
          feeRateParams.unifiedPoint = 10 ** 18;
          feeRateParams.minimum = 10 ** 17;
          feeRateParams.slope = feeRateParams.unifiedPoint - feeRateParams.minimum;

          feeRateParams.discountRate = _min(feeRateParams.unifiedPoint, handlerFlashloan[handlerID].discountBase.unifiedDiv(bifiBalance));

          flashloanFeeRate = flashloanFeeRate.unifiedMul(
            feeRateParams.minimum.add(feeRateParams.slope.unifiedMul(feeRateParams.discountRate))
          );
        }
      }

      return amount.unifiedMul(flashloanFeeRate);
    }

    /**
    * @dev Get flashloan fee for flashloan amount before make product(BiFi-X)
    * @param handlerID The ID of handler with accumulated flashloan fee
    * @param amount The amount of flashloan amount
    * @param bifiBalance The amount of Bifi amount
    * @return The amount of fee for flashloan amount
    */
    function getFeeFromArguments(uint256 handlerID, uint256 amount, uint256 bifiBalance) external view returns (uint256) {
      FeeRateParams memory feeRateParams;

      uint256 flashloanFeeRate = handlerFlashloan[handlerID].flashFeeRate;

      if(bifiBalance >= handlerFlashloan[handlerID].discountBase) {
        // feeRate * (0.1 + 0.9 * min(1, discountBase / bifiAmount))
        feeRateParams.unifiedPoint = 10 ** 18;
        feeRateParams.minimum = 10 ** 17;
        feeRateParams.slope = feeRateParams.unifiedPoint - feeRateParams.minimum;

        feeRateParams.discountRate = _min(feeRateParams.unifiedPoint, handlerFlashloan[handlerID].discountBase.unifiedDiv(bifiBalance));

        flashloanFeeRate = flashloanFeeRate.unifiedMul(
          feeRateParams.minimum.add(feeRateParams.slope.unifiedMul(feeRateParams.discountRate))
        );
      }

      return amount.unifiedMul(flashloanFeeRate);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a >= b) { return b; }
      return a;
    }

    /**
    * @dev Convert amount of handler's unified decimals to amount of token's underlying decimals
    * @param unifiedTokenAmount The amount of unified decimals
    * @return (underlyingTokenAmount)
    */
    function _convertUnifiedToUnderlying(ContractInfo memory handlerInfo, uint256 unifiedTokenAmount) internal view returns (uint256) {
      (, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
        abi.encodeWithSelector(
          handlerInfo.handlerFunction
          .convertUnifiedToUnderlying.selector,
          unifiedTokenAmount
        )
      );

      uint256 underlyingTokenDecimal = abi.decode(handlerInfo.data, (uint256));
      return underlyingTokenDecimal;
    }

    /**
    * @dev Get handler contract balance
    * @param handlerInfo Handler's information about getting the balance
    * @param handlerID The ID of handler get the balance
    * @return tokenAddr is actual tokenAddress and contract token balance.
    */
    function _getThisBalance(ContractInfo memory handlerInfo, uint256 handlerID) internal view returns (address tokenAddr, uint256 balance) {
      if(handlerID == 0) { // ether
        balance = address(this).balance;
        return (address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), balance);
      } else { // token
        (, handlerInfo.data) = handlerInfo.tokenHandler.handlerViewProxy(
          abi.encodeWithSelector(
            handlerInfo.handlerFunction
            .getERC20Addr.selector
          )
        );

        tokenAddr = abi.decode(handlerInfo.data, (address));
        balance = IERC20(tokenAddr).balanceOf(address(this));
        return (tokenAddr, balance);
      }
    }
}