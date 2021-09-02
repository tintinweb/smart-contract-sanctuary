/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// NOTE: This strategy will not works for enabled merkletree verification funds






interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
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


interface IRouter {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IFund {
  function trade(
    address _source,
    uint256 _sourceAmount,
    address _destination,
    uint256 _type,
    bytes32[] calldata _proof,
    uint256[] calldata _positions,
    bytes calldata _additionalData,
    uint256 _minReturn
  ) external;

  function getFundTokenHolding(address _token) external view returns (uint256);
  function coreFundAsset() external view returns(address);
}

interface IERC20 {
  function balanceOf() external view returns(uint256);
}

contract UNIBuyLowSellHigh is KeeperCompatibleInterface, Ownable {
    using SafeMath for uint256;

    uint256 public previousUnderlyingPrice;
    address public poolAddress;
    uint256 public splitPercentToSell = 10;
    uint256 public splitPercentToBuy = 10;
    uint256 public triggerPercentToSell = 10;
    uint256 public triggerPercentToBuy = 10;

    IRouter public router;
    address[] public path;
    IFund public fund;
    address public UNI_TOKEN;
    address public UNDERLYING_ADDRESS;

    enum TradeType { Skip, BuyUNI, SellUNI }


    constructor(
        address _router, // Uniswap v2 router
        address _poolAddress, // Uniswap v2 pool (pair)
        address[] memory _path, // path [UNI, UNDERLYING]
        address _fund, // SmartFund address
        address _UNI_TOKEN // Uniswap token
      )
      public
    {
      router = IRouter(_router);
      poolAddress = _poolAddress;
      path = _path;
      fund = IFund(_fund);
      UNI_TOKEN = _UNI_TOKEN;
      UNDERLYING_ADDRESS = fund.coreFundAsset();

      previousUnderlyingPrice = getUNIPriceInUNDERLYING();
    }

    // Helper for check price for 1 UNI in UNDERLYING
    function getUNIPriceInUNDERLYING()
      public
      view
      returns (uint256)
    {
      uint256[] memory res = router.getAmountsOut(1000000000000000000, path);
      return res[1];
    }

    // Check if need unkeep
    function checkUpkeep(bytes calldata)
      external
      override
      returns (bool upkeepNeeded, bytes memory)
    {
        if(computeTradeAction() != 0)
          upkeepNeeded = true;
    }

    // REMOVE THIS IN PRODUCTION
    function tradeFromUNItest() external onlyOwner {
      // Trade from uni to underlying
      trade(
        UNI_TOKEN,
        UNDERLYING_ADDRESS,
        uniAmountToSell()
       );
    }

    // REMOVE THIS IN PRODUCTION
    function tradeFromUNDERLYINGtest() external onlyOwner {
      // Trade from underlying to uni
      trade(
        UNDERLYING_ADDRESS,
        UNI_TOKEN,
        underlyingAmountToSell()
       );
    }

    // Check if need perform unkeep
    function performUpkeep(bytes calldata) external override {
        // perform action
        uint256 actionType = computeTradeAction();

        // BUY action
        if(actionType == uint256(TradeType.BuyUNI)){
          // Trade from underlying to uni
          trade(
            UNDERLYING_ADDRESS,
            UNI_TOKEN,
            underlyingAmountToSell()
           );
        }
        // SELL action
        else if(actionType == uint256(TradeType.SellUNI)){
          // Trade from uni to underlying
          trade(
            UNI_TOKEN,
            UNDERLYING_ADDRESS,
            uniAmountToSell()
           );
        }
        // NO need action
        else{
          return;
        }

        // update data after buy or sell action
        previousUnderlyingPrice = getUNIPriceInUNDERLYING();
    }

    // compute if need trade
    // 0 - Skip, 1 - Buy, 2 - Sell
    function computeTradeAction() public view returns(uint){
       uint256 currentUnderlyingPrice = getUNIPriceInUNDERLYING();

       // Buy if current price >= trigger % to buy
       // This means UNI go UP
       if(currentUnderlyingPrice > previousUnderlyingPrice){
          uint256 res = computeTrigger(
            currentUnderlyingPrice,
            previousUnderlyingPrice,
            triggerPercentToBuy
          )
          ? 2 // SELL UNI
          : 0;

          return res;
       }

       // Sell if current price =< trigger % to sell
       // This means UNI go DOWN
       else if(currentUnderlyingPrice < previousUnderlyingPrice){
         uint256 res = computeTrigger(
           previousUnderlyingPrice,
           currentUnderlyingPrice,
           triggerPercentToSell
         )
         ? 1 // BUY UNI
         : 0;

         return res;
       }
       else{
         return 0; // SKIP
       }
    }

    // return true if difference >= trigger percent
    function computeTrigger(
      uint256 priceA,
      uint256 priceB,
      uint256 triggerPercent
    )
      public
      view
      returns(bool)
    {
      uint256 currentDifference = priceA.sub(priceB);
      uint256 triggerPercent = previousUnderlyingPrice.div(100).mul(triggerPercent);
      return currentDifference >= triggerPercent;
    }

    // Calculate how much % of UNDERLYING send from fund balance for buy UNI
    function underlyingAmountToSell() public view returns(uint256){
      uint256 totatlETH = fund.getFundTokenHolding(UNDERLYING_ADDRESS);
      return totatlETH.div(100).mul(splitPercentToBuy);
    }

    // Calculate how much % of UNI send from fund balance for buy UNDERLYING
    function uniAmountToSell() public view returns(uint256){
      uint256 totalUNI = fund.getFundTokenHolding(UNI_TOKEN);
      return totalUNI.div(100).mul(splitPercentToSell);
    }

    // Helper for trade
    function trade(address _fromToken, address _toToken, uint256 _amount) internal {
      bytes32[] memory proof;
      uint256[] memory positions;

      fund.trade(
        _fromToken,
        _amount,
        _toToken,
        4,
        proof,
        positions,
        "0x",
        1
      );
    }

    // Only owner setters
    function setSplitPercentToSell(uint256 _splitPercentToSell) external onlyOwner{
      require(splitPercentToSell <= 100, "Wrong %");
      splitPercentToSell = _splitPercentToSell;
    }

    function setSplitPercentToBuy(uint256 _splitPercentToBuy) external onlyOwner{
      require(splitPercentToBuy <= 100, "Wrong %");
      splitPercentToBuy = _splitPercentToBuy;
    }

    function setTriggerPercentToSell(uint256 _triggerPercentToSell) external onlyOwner{
      require(triggerPercentToSell <= 100, "Wrong %");
      triggerPercentToSell = _triggerPercentToSell;
    }

    function setTriggerPercentToBuy(uint256 _triggerPercentToBuy) external onlyOwner{
      require(triggerPercentToBuy <= 100, "Wrong %");
      triggerPercentToBuy = _triggerPercentToBuy;
    }
}