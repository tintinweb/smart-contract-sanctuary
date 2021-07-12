/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: contracts/interfaces/IPositionStorage.sol
pragma solidity 0.6.12;
interface IPositionStorage {
  function createStrategy(address strategyLogic) external returns (bool);
  function setStrategy(uint256 strategyID, address strategyLogic) external returns (bool);
  function getStrategy(uint256 strategyID) external view returns (address);
  function newUserProduct(address user, address product) external returns (bool);
  function getUserProducts(address user) external view returns (address[] memory);
  function setFactory(address _factory) external returns (bool);
  function setProductToNFTID(address product, uint256 nftID) external returns (bool);
  function getNFTID(address product) external view returns (uint256);
}

// File: contracts/interfaces/IStrategyCreator.sol
pragma solidity 0.6.12;
interface IStrategyCreator {
  function create(address sender, address strategyLogic, bytes memory strategyParams) external payable returns (address);
}

// File: contracts/interfaces/IERC721.sol
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

// File: contracts/interfaces/IFactory.sol
pragma solidity ^0.6.12;

interface IFactory  {
  function setManagerAddr(address _bifiManagerAddr) external returns (bool);

  function setUniswapAddr(address _uniswapAddr) external returns (bool);

  function setNFT(address payable nftAddr) external returns (bool);

  function getManagerAddr() external view returns (address);

  function getUniswapAddr() external view returns (address);

  function getNFT() external view returns (address);

  function getStrategy(uint256 id) external view returns (address);

  function getBifiAddr() external view returns (address);

  function getWETHAddr() external view returns (address);

  function payFee(address user) external view returns (uint256);
}

// File: contracts/Position/Product/ProductSlot.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X ProductSlot contract
  * @notice For prevent proxy storage variable mismatch
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract ProductSlot {
  IERC721 public NFT;
  IFactory public factory;
  
  bool public strategyExecuted;
  bool startedByOwner;

  address public strategy;
  uint256 public strategyID;
  uint256 public productID;

  uint256 public depositAsset;
  uint256 public srcAsset;
  uint256 public srcPrice;
  uint256 public dstAsset;
  uint256 public dstPrice;

  modifier onlyOwner {
    require(msg.sender == NFT.ownerOf(productID));
    _;
  }

  modifier onlyManager {
    require(msg.sender == factory.getManagerAddr(), "onlyManager");
    _;
  }

  modifier onlyFactory {
    require(msg.sender == address(factory), "onlyFactory");
    _;
  }
}

// File: contracts/Position/Product/ProductProxy.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X ProductProxy contract
  * @notice Deployed contract, (delegate)call Strategy logic
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract ProductProxy is ProductSlot {
  constructor(uint256 _strategyID, address _nft, address _factory, uint256 _productID) public {
    strategyID = _strategyID;
    NFT = IERC721(_nft);
    productID = _productID;
    factory = IFactory(_factory);
  }

  function setStrategyID(uint256 _strategyID) external onlyOwner returns (bool) {
    strategyID = _strategyID;
    return true;
  }

  function getStrategyID() external view returns (uint256) {
    return strategyID;
  }

  fallback() external payable {
    address addr = factory.getStrategy(strategyID);
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), addr, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  receive() external payable {}
}

// File: contracts/Position/Strategies/Standard/StrategyStructures.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X Standard StrategyStructures contract
  * @notice Define Standard Strategy params structure
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract StrategyStructures {
  struct StrategyParams {
    address managerAddr;
    uint256[] handlerIDs;
    address[] handlersAddress;
    address[] tokenAddr;
    address[] path;
    uint256 pathCount;
    uint256[] fees;
    uint256[] amounts;
    uint256 amountsInMax;
    uint256 lendingAmount;
    uint256[] decimal;
    uint256 collateralPrice;
    uint256 lendingPrice;
    uint256 totalDebt;
    uint256 flashAmount;
    bool lockFlag;
  }

  struct UniswapParams {
    address wethAddr;
    uint256 timestamp;
  }
}

// File: contracts/Position/Strategies/Standard/StrategySlot.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X Standard StrategySlot contract
  * @notice For prevent Strategy proxy storage variable mismatch
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract StrategySlot is ProductSlot, StrategyStructures {

  event StartStrategy(
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address productAddr, // The Address of Product.
    uint256 srcID, // The ID of handler that is deposited.
    uint256 dstID, // The ID of handler that is borrowed.
    uint256 collateralAmount, // The amount of token required when creating a position in BIFI-X.
    uint256 flashloanAmount, // The amount borrowed via flashloan for leverage, When creating a position in BIFI-X.
    uint256 lendingAmount, // The amount of borrow. This amount is borrowed to pay off flashloan amount.
    uint256 timestamp // The timestamp of StartStrategy action.
  );

  event EndStrategy(
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address productAddr, // The Address of Product.
    uint256 srcID, // The ID of handler that is deposited.
    uint256 dstID, // The ID of handler that is borrowed.
    uint256 depositAmount, // The amount of deposit.
    uint256 flashloanAmount, // The amount borrowed to pay off the loan through flashloan, When closing a position in BIFI-X.
    uint256 timestamp // The timestamp of EndStrategy action.
  );

  event LockPositionSwap(
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address productAddr, // The Address of Product.
    uint256 swapAmount, // The amount of swap.
    address[] path, // The path of swap (An array of token addresses).
    uint256 timestamp // The timestamp of LockPositionSwap action.
  );

  event UnlockPositionSwap(
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address productAddr, // The Address of Product.
    uint256 outAmount, // The amount of tokens when exchanging tokens.
    uint256 amountInMax, // The maximum amount of token to be exchanged when exchanging tokens.
    address[] path, // The path of swap (An array of token addresses).
    uint256 timestamp // The timestamp of UnlockPositionSwap action.
  );

  event ExtraPayback(
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address productAddr, // The Address of Product.
    address tokenAddr, // the Address of token.
    uint256 amount, // the amount to send remaining assets when creating or closing a position.
    address recipient, // the Address of recipient.
    uint256 timestamp // The timestamp of ExtraPayback action.
  );

  address[] handlersAddress;
  uint256[] handlerIDs;

  address uniswapV2Addr;
}

// File: contracts/interfaces/bifi/IMarketManager.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market manager interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketManager  {
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

   function rewardClaimAll(address payable userAddr) external returns (uint256);
   function claimHandlerReward(uint256 handlerID, address payable userAddr) external returns (uint256);

   function updateRewardParams(address payable userAddr) external returns (bool);
   function interestUpdateReward() external returns (bool);
   function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);

   function setOracleProxy(address oracleProxyAddr) external returns (bool);

   function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool);
   function ownerRewardTransfer(uint256 _amount) external returns (bool);
   function getFeePercent(uint256 handlerID) external view returns (uint256);
   function flashloan(uint256 handlerID, address receiverAddress, uint256 amount, bytes calldata params) external returns (bool);
  function getFeeFromArguments(uint256 handlerID, uint256 amount, uint256 bifiAmount) external view returns (uint256);
}

// File: contracts/interfaces/bifi/IFlashloanReceiver.sol
pragma solidity 0.6.12;

interface IFlashloanReceiver {
    function executeOperation(
      address reserve,
      uint256 amount,
      uint256 fee,
      bytes calldata params
    ) external returns (bool);
}

// File: contracts/interfaces/bifi/IManagerFlashloan.sol
pragma solidity 0.6.12;

interface IManagerFlashloan {
    function flashloan(
      uint256 handlerID,
      address receiverAddress,
      uint256 amount,
      bytes calldata params
    ) external returns (bool);

    function getFee(uint256 handlerID, uint256 amount) external view returns (uint256);

    function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);
}

// File: contracts/interfaces/bifi/IProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IProxy  {
  function deposit(uint256 unifiedTokenAmount, bool flag) external payable returns (bool);
  function withdraw(uint256 unifiedTokenAmount, bool flag) external returns (bool);
  function borrow(uint256 unifiedTokenAmount, bool flag) external returns (bool);
  function repay(uint256 unifiedTokenAmount, bool flag) external payable returns (bool);

  function handlerProxy(bytes memory data) external returns (bool, bytes memory);
  function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/interfaces/bifi/IMarketHandler.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market handler interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketHandler  {
  function deposit(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);
  function withdraw(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
  function borrow(uint256 unifiedTokenAmount, bool allFlag) external returns (bool);
  function repay(uint256 unifiedTokenAmount, bool allFlag) external payable returns (bool);

  function getTokenHandlerBorrowLimit() external view returns (uint256);

  function getMarketRewardInfo() external view returns (uint256, uint256, uint256);
  function getUserAmount(address payable userAddr) external view returns (uint256, uint256);
  function getUserAmountWithInterest(address payable userAddr) external view returns (uint256, uint256);
  function getUserRewardInfo(address payable userAddr) external view returns (uint256, uint256, uint256);

  function getUserMaxBorrowAmount(address payable userAddr) external view returns (uint256);
  function getUserMaxWithdrawAmount(address payable userAddr) external view returns (uint256);
  function getUserMaxRepayAmount(address payable userAddr) external view returns (uint256);

  function getDepositTotalAmount() external view returns (uint256);
  function getBorrowTotalAmount() external view returns (uint256);

  function getERC20Addr() external view returns (address);
  function getSIRandBIR() external view returns (uint256, uint256);
  function handlerViewProxy(bytes memory data) external view returns (bool, bytes memory);
  function siViewProxy(bytes memory data) external view returns (bool, bytes memory);
}

// File: contracts/interfaces/IERC20.sol
// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
pragma solidity 0.6.12;
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function deposit() external payable;
  function withdraw(uint wad) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IStrategy.sol
pragma solidity 0.6.12;
interface IStrategy {
  function startStrategy(bytes memory params) external payable returns (bool);
  function endStrategy(bytes memory strategyParams) external payable returns (bool);
  function getDepositAsset() external view returns (uint256);
  function getSrcAsset() external view returns (uint256);
  function getSrcPrice() external view returns (uint256);
  function getDstAsset() external view returns (uint256);
  function getDstPrice() external view returns (uint256);
  function endStrategyWithTransfer(uint256 amount, bytes memory params) external payable returns (bool);
}

// File: contracts/interfaces/uniswap/IUniswapV2Router02.sol
pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function factory() external view returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/utils/SafeMath.sol
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

// File: contracts/utils/Address.sol
pragma solidity ^0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/utils/SafeERC20.sol
pragma solidity ^0.6.12;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IIERC20-approve}, and its usage is discouraged.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeIERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeIERC20: IERC20 operation did not succeed");
        }
    }
}

// File: contracts/Position/Strategies/Standard/StrategyLogic.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X Standard StrategyLogic contract
  * @notice Strategy's make positions based on this contract
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract StrategyLogic is IStrategy, StrategySlot {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  uint256 constant COLLATERAL_HANDLER = 0;
  uint256 constant LENDING_HANDLER    = 1;

  uint256 constant EXECUTE_AMOUNT = 10 ** 30;
  uint256 constant UNIFIED_ONE = 10 ** 18;

  /**
   * @dev For successfully start the strategy,
          calculate the amount of borrow and
          call the BiFi's manager flashloan function.
   * @param params The encoded params of strategy
   * @return Whether or not start strategy succeed
   */
  function startStrategy(bytes memory params) external payable override returns (bool) {
    // check strategy already executed
    require(!strategyExecuted, "SL001");
    address _this = address(this);

    strategyExecuted = true;
    startedByOwner = true;

    // decode strategy params
    StrategyParams memory vars = _startParamsDecoder(params);

    uint256 actualBalance;
    uint256 expectedBalance = vars.amounts[0].add(vars.fees[0]).add(vars.fees[1]);

    handlerIDs = vars.handlerIDs;
    handlersAddress = vars.handlersAddress;

    if(handlerIDs[COLLATERAL_HANDLER] == 0) {
      actualBalance = _this.balance;
    } else {
      IERC20 collateralToken = IERC20(vars.tokenAddr[COLLATERAL_HANDLER]);
      actualBalance = collateralToken.balanceOf(_this);
    }

    // check seed
    require(actualBalance >= _convertUnifiedToUnderlying(expectedBalance, vars.decimal[0]), "SL002");

    // start strategy for make product contract of position
    // so, lockFlag true for switch control flow in executeOperation function
    vars.lockFlag = true;

    IMarketManager manager = IMarketManager(factory.getManagerAddr());

    vars.lendingAmount = vars.amounts[1];
    vars.collateralPrice = manager.getTokenHandlerPrice(vars.handlerIDs[COLLATERAL_HANDLER]);
    // startStrategy's flashloan target asset is collateral asset
    // if handlerIDs length 1 for Boost Strategy
    // so, lending token same as collateral, lending asset
    if(handlerIDs.length == 1) {
      // Boost case collatral, lending token amount == flashloan amount
      vars.lendingPrice = vars.collateralPrice;

      IMarketHandler handler = IMarketHandler(vars.handlersAddress[0]);

      (, bytes memory data) = handler.handlerViewProxy(abi.encodeWithSelector(handler.getTokenHandlerBorrowLimit.selector));

      uint256 borrowLimit = abi.decode(data, (uint256));

      // check max borrow amount can repay flashloan
      uint256 maxBorrowAmount = vars.amounts[0].add(vars.amounts[2]).unifiedMul(borrowLimit);
      require(maxBorrowAmount >= vars.lendingAmount, "SL003");
      emit StartStrategy(productID, address(this), handlerIDs[COLLATERAL_HANDLER], handlerIDs[COLLATERAL_HANDLER], vars.amounts[0], vars.amounts[2], vars.amounts[1], block.timestamp);
    } else if (handlerIDs.length == 2) {
      vars.lendingPrice = manager.getTokenHandlerPrice(vars.handlerIDs[LENDING_HANDLER]);
      emit StartStrategy(productID, address(this), handlerIDs[COLLATERAL_HANDLER], handlerIDs[LENDING_HANDLER], vars.amounts[0], vars.amounts[2], vars.amounts[1], block.timestamp);
    } else {
      revert("SL007");
    }


    // execute(start) flashloan
    manager.flashloan(
      handlerIDs[COLLATERAL_HANDLER],
      _this,
      vars.amounts[2],
      abi.encode(vars)
    );

    return true;
  }

  function endStrategyWithTransfer(uint256 amount, bytes memory params) external onlyOwner payable override returns (bool) {
    StrategyParams memory vars = _endParamsDecoder(params);
    address collateralAddr = vars.tokenAddr[0];
    if(collateralAddr == ETH_ADDRESS){
      require(amount == 0, "only ether transfer");
    }else {
      address owner = NFT.ownerOf(productID);
      IERC20(collateralAddr).safeTransferFrom(owner, address(this), amount);
    }
    _endStrategy(params);
    return true;
  }

  function endStrategy(bytes memory params) external onlyOwner payable override returns (bool) {
    _endStrategy(params);
    return true;
  }

  /**
   * @dev End Strategy and selfdestruct Product contract.
   * @param params The encoded params of end strategy
   * @return Whether or not succeed
   */
  function _endStrategy(bytes memory params) internal onlyOwner returns (bool) {
    startedByOwner = true;

    // decode parameter
    StrategyParams memory vars = _endParamsDecoder(params);

    address managerAddr = factory.getManagerAddr();
    IMarketManager manager = IMarketManager(managerAddr);

    // end strategy & release product position
    // so, lockFlag false for switch control flow in executeOperation function
    vars.lockFlag = false;

    address _this = address(this);
    uint256 handlerID;

    // endStrategy's flashloan target token is lending token
    (uint256 depositWithInterest, ) = _getUserAmountWithInterest(handlersAddress[COLLATERAL_HANDLER]);

    // if handlerIDs length 1 for Boost Strategy
    // so, same as collateral, lending token
    if(handlerIDs.length > 1){
      handlerID = handlerIDs[LENDING_HANDLER];
      emit EndStrategy(productID, address(this), handlerIDs[COLLATERAL_HANDLER], handlerIDs[LENDING_HANDLER], depositWithInterest, vars.amounts[1], block.timestamp);
    }
    // else Leverage Strategy
    // so, flashloan target is repay token
    else {
      handlerID = handlerIDs[COLLATERAL_HANDLER];
      emit EndStrategy(productID, address(this), handlerIDs[COLLATERAL_HANDLER], handlerIDs[COLLATERAL_HANDLER], depositWithInterest, vars.amounts[1], block.timestamp);
    }

    vars.amounts[2] = vars.amounts[1];

    // execute(start) flashloan
    manager.flashloan(
      handlerID,
      _this,
      vars.amounts[2],
      abi.encode(vars)
    );

    // claim the rewards accumulated through the lending service.
    _rewardClaim();

    // selfdestruct this contract (for reduce gas fee)
    address _owner = NFT.ownerOf(productID);
    selfdestruct(payable(_owner));
  }

  /**
   * @dev Callback function when execute manager flashloan
   * @param reserve The address of token borrowed
   * @param amount The amount of token borrowed
   * @param fee The fee amount of token amount borrowed
   * @param params The encoded params of strategy(start or end)
   * @return Whether or not succeed
   */
  function executeOperation(
      address reserve,
      uint256 amount,
      uint256 fee,
      bytes calldata params
  ) external onlyManager returns (bool) {
    // check executeOperation entry point is start or end Strategy
    require(startedByOwner, "onlyOwner");

    // decode params
    (StrategyParams memory vars) = abi.decode(params, (StrategyParams) );

    // calculate flashloan total debt for repay flashloan
    vars.totalDebt = amount.add(fee);

    address wethAddr = factory.getWETHAddr();

    IERC20 weth = IERC20(wethAddr);
    address _this = address(this);

    // if reserve is ETH, replace to WETH address for uniswap
    if(reserve == ETH_ADDRESS) { reserve = wethAddr; }

    // if handlersAddress length is 2, Boost case
    // Boost case, don't to build path for uniswap
    if(handlersAddress.length == 1) {
    }
    // if handlersAddress length is 2, Leverage case
    // Leverage case, need to build path for uniswap
    else if(handlersAddress.length == 2) {
      // pool is not enough (default)
      vars.pathCount = 3;

      for(uint256 i=0; i<vars.handlerIDs.length; i++){
        if(vars.handlerIDs[i] == 0){
          // pool is enough, ETH
          vars.pathCount = 2;
        }
      }

      vars.path = new address[](vars.pathCount);

      if (vars.pathCount == 3) {
        vars.path[1] = wethAddr;
        vars.path[2] = reserve;
      } else if (vars.pathCount == 2) {
        vars.path[1] = reserve;
      }

      // if lock(startStrategy) case
      // path[0] : lending token (BiFi borrow)
      if(vars.lockFlag == true) {
        vars.path[0] = vars.tokenAddr[LENDING_HANDLER] == ETH_ADDRESS ? wethAddr : vars.tokenAddr[LENDING_HANDLER];
      }
      // if unlock(endStrategy) case
      // path[0] : collateral token (BiFi withdraw)
      else {
        vars.path[0] = vars.tokenAddr[COLLATERAL_HANDLER] == ETH_ADDRESS ? wethAddr : vars.tokenAddr[COLLATERAL_HANDLER];
      }
    } else {
      require(false, "SL004");
    }

    // deposit, borrow
    if(vars.lockFlag){ _lockPosition(vars); }

    // repay, withdraw
    else{ _unlockPosition(vars); }

    // if handlersAddress.length is 2, Leverage case
    // need to use uniswap
    if(handlersAddress.length == 2){
      // if user collateral is ETH, convert ETH to WETH
      uint256 _thisBalance = _this.balance;

      if(_thisBalance > 0) {
        weth.deposit{value: _thisBalance}();
      }

      if(vars.lockFlag){
        // lock case, swap flashloan amount
        _lockPositionSwapPath(_this, vars);
      } else {
        // unlock case, swap flashloan + fee amount
        _unlockPositionSwapPath(_this, vars);
      }

      // if swap token is WETH, withdraw to ETH
      _thisBalance = weth.balanceOf(_this);
      if(_thisBalance > 0) { weth.withdraw(_thisBalance); }
    }

    depositAsset = vars.amounts[0].add(vars.amounts[2]).unifiedMul(vars.collateralPrice);

    srcAsset = vars.amounts[0].unifiedMul(vars.collateralPrice);
    srcPrice = vars.collateralPrice;

    dstAsset = vars.lendingAmount.unifiedMul(vars.lendingPrice);
    dstPrice = vars.lendingPrice;

    // repay flashloan
    _repayFlashloan(reserve, msg.sender, vars.totalDebt);

    // extra token return to owner
    _extraPayback(vars.tokenAddr, _this);

    startedByOwner = false;
    return true;
  }

  function getDepositAsset() external override view returns (uint256) {
    return depositAsset;
  }

  function getSrcAsset() external override view returns (uint256) {
    return srcAsset;
  }

  function getSrcPrice() external override view returns (uint256) {
    return srcPrice;
  }

  function getDstAsset() external override view returns (uint256) {
    return dstAsset;
  }

  function getDstPrice() external override view returns (uint256) {
    return dstPrice;
  }

  /**
   * @dev Repay flashloan borrow
   * @param reserve The address of flashloan borrow token
   * @param _to the address of flashloan lender
   * @param amount The amount of repay token
   */
  function _repayFlashloan(address reserve, address _to, uint256 amount) internal {
    address wethAddr = factory.getWETHAddr();
    if(reserve == ETH_ADDRESS || reserve == wethAddr) {
      payable(_to).transfer(amount);
    }else {
      IERC20 token = IERC20(reserve);
      token.safeTransfer(_to, amount);
    }
  }

  /**
   * @dev Repay flashloan borrow
   * @param reserve The address[] of payback token
   * @param _this the address of extra token owner
   */
  function _extraPayback(address[] memory reserve, address _this) internal {
    address _owner = NFT.ownerOf(productID);
    uint256 extraAmount;

    for(uint256 i=0; i<reserve.length; i++){
      if(reserve[i] != ETH_ADDRESS){
        address tokenAddr = reserve[i];

        IERC20 token = IERC20(tokenAddr);
        extraAmount = token.balanceOf(_this);
        token.safeTransfer(_owner, extraAmount);

        emit ExtraPayback(productID, address(this), tokenAddr, extraAmount, _owner, block.timestamp);
      }
    }

    payable(_owner).transfer(_this.balance);
    emit ExtraPayback(productID, address(this), ETH_ADDRESS, _this.balance, _owner, block.timestamp);
  }

  /**
   * @dev Token Swap when lock
   * @param _this The address of flashloan borrow token
   * @param vars the count of swap number
   */
  function _lockPositionSwapPath(address _this, StrategyParams memory vars) internal {
    UniswapParams memory params;
    params.wethAddr = factory.getWETHAddr();
    params.timestamp = block.timestamp;
    IUniswapV2Router02 uniswap = IUniswapV2Router02(factory.getUniswapAddr());
    IERC20 swapToken = IERC20(vars.path[0]);

    uint256 swapAmount = swapToken.balanceOf(address(this));
    swapToken.safeApprove(address(uniswap), swapAmount);
    uniswap.swapExactTokensForTokens(swapAmount, 0, vars.path, _this, params.timestamp);
    emit LockPositionSwap(productID, address(this), swapAmount, vars.path, params.timestamp);
  }

  // for avoid stack too deep
  struct UnlockPosition {
    IUniswapV2Router02 uniswap;
    IERC20 swapToken;
    uint256 outTokenAmount;
    uint256 dstBalanceAmount;
  }

  /**
   * @dev Token Swap when unlock
   * @param _this The address of flashloan borrow token
  * @param vars the address[] of token swap path when use uniswap
   */
  function _unlockPositionSwapPath(address _this, StrategyParams memory vars) internal {
    UniswapParams memory params;
    UnlockPosition memory localVars;
    params.timestamp = block.timestamp;
    localVars.uniswap = IUniswapV2Router02(factory.getUniswapAddr());
    localVars.swapToken = IERC20(vars.path[0]);

    localVars.outTokenAmount = vars.totalDebt;

    IERC20 dstToken = IERC20(vars.path[vars.path.length-1]);
    localVars.dstBalanceAmount = dstToken.balanceOf(_this);

    if(vars.totalDebt > localVars.dstBalanceAmount){
      localVars.outTokenAmount = vars.totalDebt.sub(localVars.dstBalanceAmount);
    }

    uint amountsInMax = _convertUnifiedToUnderlying(vars.amountsInMax, vars.decimal[0]);
    localVars.swapToken.safeApprove(address(localVars.uniswap), amountsInMax);
    localVars.uniswap.swapTokensForExactTokens(localVars.outTokenAmount, amountsInMax, vars.path, _this, params.timestamp);
    emit UnlockPositionSwap(productID, address(this), localVars.outTokenAmount, amountsInMax, vars.path, params.timestamp);
  }

  function _endParamsDecoder(bytes memory strategyParams) internal pure returns (StrategyParams memory) {
    StrategyParams memory vars;
    vars.amounts = new uint256[](3);
    (vars.tokenAddr,
    vars.handlersAddress,
    vars.handlerIDs,
    vars.amounts[1],
    vars.amountsInMax,
    vars.decimal) = abi.decode(strategyParams, (address[], address[], uint256[], uint256, uint256, uint256[]));
    return vars;
  }

  function _startParamsDecoder(bytes memory strategyParams) internal pure returns (StrategyParams memory) {
    StrategyParams memory vars;
    (vars.tokenAddr,
    vars.handlersAddress,
    vars.handlerIDs,
    // 0: flashloan fee, 1: swap fee
    vars.fees,
    // 0: collateral amount, 1: lending amount, 2: flashloan amount
    vars.amounts,
    vars.decimal) = abi.decode(strategyParams, (address[], address[], uint256[], uint256[], uint256[], uint256[]));
    return vars;
  }

  /**
   * @dev deposit and borrow
   * @param vars The variable of lock strategy
   * @return Whether or not _lockPosition succeed
   */
  function _lockPosition(StrategyParams memory vars) internal returns (bool) {
    // add collateral amount
    uint256 depositAmount = vars.amounts[2].add(vars.amounts[0]);

    _deposit(vars.tokenAddr[0], handlersAddress[0], depositAmount);

    uint256 index = handlersAddress.length.sub(1);
    _borrow(handlersAddress[index], vars.lendingAmount);

    return true;
  }

  /**
   * @dev Repay and withdraw
   * @param vars The variable of lock strategy
   * @return Whether or not _lockPosition succeed
   */
  function _unlockPosition(StrategyParams memory vars) internal returns (bool) {

    uint256 index = handlersAddress.length.sub(1);

    _repay(vars.tokenAddr[index], handlersAddress[index], vars.decimal[index]);

    _withdraw(vars.tokenAddr[0], handlersAddress[0], vars.decimal[0]);

    return true;
  }

  /**
   * @dev Deposit action to BiFi
   * @param reserve The address of token
   * @param tokenHandlerAddr The address of BiFi's tokenHandler contract
   * @param amount The amount of deposit
   */
  function _deposit(address reserve, address tokenHandlerAddr, uint256 amount) internal {
    IProxy proxy = IProxy(tokenHandlerAddr);

    if(reserve == ETH_ADDRESS){
      proxy.deposit{value: amount}(0, false);
    }else {
      IERC20 token = IERC20(reserve);
      token.safeApprove(tokenHandlerAddr, amount);
      proxy.deposit(amount, false);
    }
  }

  /**
   * @dev Repay action to BiFi
   * @param reserve The address of token
   * @param tokenHandlerAddr the address of BiFi's tokenHandler contract
   * @param decimal the decimal of reserve token
   */
  function _repay(address reserve, address tokenHandlerAddr, uint256 decimal) internal {
    IProxy proxy = IProxy(tokenHandlerAddr);

    if(reserve == ETH_ADDRESS){
      proxy.repay{value: address(this).balance}(0, false);
    }else {
      IERC20 token = IERC20(reserve);
      uint256 balance = token.balanceOf(address(this));
      uint256 unifiedAmount = _convertUnderlyingToUnified(balance, decimal);
      token.safeApprove(tokenHandlerAddr, balance);
      proxy.repay(unifiedAmount, false);
    }
  }

  /**
   * @dev Borrow action to BiFi
   * @param tokenHandlerAddr the address of BiFi tokenHandler contract
   * @param amount the amount of borrow
   */
  function _borrow(address tokenHandlerAddr, uint256 amount) internal {
    IProxy proxy = IProxy(tokenHandlerAddr);
    proxy.borrow(amount, false);
  }

  /**
   * @dev Withdraw action to BiFi
  * @param tokenAddr the address of bifi token handler
  * @param tokenHandlerAddr the address of BiFi tokenHandler contract
  * @param decimal the decimal of withdraw token
   */
  function _withdraw(address tokenAddr, address tokenHandlerAddr, uint256 decimal) internal {
    uint256 beforeBalance;
    uint256 afterBalance;

    address _this = address(this);

    if(tokenAddr == ETH_ADDRESS) {
      beforeBalance = _this.balance;
    }else{
      beforeBalance = IERC20(tokenAddr).balanceOf(_this);
    }

    IProxy proxy = IProxy(tokenHandlerAddr);
    (uint256 depositAmountWithInterest, ) = _getUserAmountWithInterest(tokenHandlerAddr);

    proxy.withdraw(depositAmountWithInterest, false);

    if(tokenAddr == ETH_ADDRESS) {
      afterBalance = _this.balance;
    }else{
      afterBalance = IERC20(tokenAddr).balanceOf(_this);
    }

    uint256 gap = depositAmountWithInterest.unifiedMul(10 ** 15);
    uint256 balance = _convertUnderlyingToUnified(afterBalance.sub(beforeBalance), decimal);

    if(depositAmountWithInterest > balance){
      require(depositAmountWithInterest.sub(balance) <= gap, "SL005");
    }else{
      require(balance.sub(depositAmountWithInterest) <= gap, "SL006");
    }

  }


  /**
   * @dev Reward claim action to BiFi
   */
  function rewardClaim() external  {
    _rewardClaim();
  }

  function getProductID() external view returns (uint256) {
    return productID;
  }

  /**
   * @dev Reward claim action to BiFi
   */
  function _rewardClaim() internal {
    address userAddr = address(this);

    address bifiAddr = factory.getBifiAddr();
    IMarketManager manager = IMarketManager(factory.getManagerAddr());
    IERC20 bifi = IERC20(bifiAddr);

    uint256 handlerLength = handlerIDs.length;

    for (uint256 i=0; i < handlerLength; i++){
      manager.claimHandlerReward(handlerIDs[i], payable(userAddr));
    }

    address owner = NFT.ownerOf(productID);
    bifi.safeTransfer(owner, bifi.balanceOf(userAddr));
  }

  function _getUserAmountWithInterest(address handlerAddr) internal view returns (uint256, uint256) {
    IMarketHandler handler = IMarketHandler(handlerAddr);
    (,bytes memory data)= handler.handlerViewProxy(
      abi.encodeWithSelector(handler.getUserAmountWithInterest.selector, address(this))
    );
    return abi.decode(data, (uint256, uint256));
  }

   function _convertUnderlyingToUnified(uint256 underlyingTokenAmount, uint256 underlyingTokenDecimal) internal pure returns (uint256)
   {
    return (underlyingTokenAmount.mul(UNIFIED_ONE)) / underlyingTokenDecimal;
   }

  function _convertUnifiedToUnderlying(uint256 unifiedTokenAmount, uint256 underlyingTokenDecimal) internal pure returns (uint256)
   {
      return (unifiedTokenAmount.mul(underlyingTokenDecimal)) / UNIFIED_ONE;
   }

  receive() external payable{
  }
}

// File: contracts/XFactory/storage/XFactorySlot.sol
pragma solidity ^0.6.12;

 /**
  * @title BiFi-X XFactorySlot contract
  * @notice For prevent proxy storage variable mismatch
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactorySlot {
  address public storageAddr;
  address public _implements;
  address public _storage;

  address public owner;
  address public NFT;

  address public bifiManagerAddr;
  address public uniswapV2Addr;

  address public bifiAddr;
  address public wethAddr;

  // bifi fee variable
  uint256 fee;
  uint256 discountBase;
}

// File: contracts/XFactory/logic/XFactoryInternal.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X XFactoryInternal contract
  * @notice Implement internal logics for contract, basically storage setter
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactoryInternal is StrategyStructures, XFactorySlot {
  using SafeMath for uint256;

  uint256 constant UNIFIED_ONE = 10 ** 18;

   modifier onlyOwner {
      require(msg.sender == address(owner), "Revert: onlyOwner");
      _;
   }
  modifier onlyAdmin {
    require(msg.sender == address(owner), "Revert: onlyOwner");
      _;
  }

  function _setOwner(address _owner) internal onlyOwner returns (bool) {
    owner = _owner;
    return true;
  }

  function _setImplements(address implementsAddr) internal onlyOwner returns (bool) {
    _implements = implementsAddr;
    return true;
  }

  function _setStorageAddr(address storageAddr) internal onlyOwner returns (bool) {
    _storage = storageAddr;
    return true;
  }

  function _setManagerAddr(address _bifiManagerAddr) internal onlyOwner returns (bool) {
    bifiManagerAddr = _bifiManagerAddr;
    return true;
  }

  function _setUniswapV2Addr(address _uniswapV2Addr) internal onlyOwner returns (bool) {
    uniswapV2Addr = _uniswapV2Addr;
    return true;
  }

  function _setNFT(address nftAddr) internal onlyOwner returns (bool) {
    NFT = nftAddr;
    return true;
  }

  function _setFee(uint256 _fee) internal onlyOwner returns (bool) {
    fee = _fee;
    return true;
  }

  function _setDiscountBase(uint256 _discountBase) internal onlyOwner returns (bool) {
    discountBase = _discountBase;
    return true;
  }

  function _convertUnifiedToUnderlying(uint256 unifiedTokenAmount, uint256 underlyingTokenDecimal) internal pure returns (uint256)
   {
      return (unifiedTokenAmount.mul(underlyingTokenDecimal)) / UNIFIED_ONE;
   }
}

// File: contracts/XFactory/logic/XFactoryExternal.sol
pragma solidity ^0.6.12;

/**
  * @title BiFi-X XFactoryExternal contract
  * @notice Implement entry point for XFactory contract
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactoryExternal is XFactoryInternal {
  using SafeERC20 for IERC20;

  event Create(
    uint256 strategyID, // The ID to identify strategy logic contracts
    uint256 productID, // The NFT ID of Product. When checking the owner of the NFT, this ID will be used.
    address positionAddr, // The Address of Product.
    address userAddr // The Address of the user who created the product.
  );

  event PayFee(
    address userAddr, // The Address of the user who created the product.
    uint256 feeAmount // The amount of BIFI token you pay to create a product
  );

  event WithdrawFee(
    address receiver, // The Address of the receiver.
    uint256 feeAmount // The amount of BIFI token to be withdrawn.
  );

  /**
   * @dev Create product and store user's product data in storage
   * @param strategyID The ID of product strategy
   * @param strategyParams The encode parameter of strategy
   * @return Whether or not create succeed
   */
  function create(uint256 strategyID, bytes memory strategyParams) external payable returns (bool) {
    address userAddr = msg.sender;

    // pay use BiFi-X
    IERC20 bifi = IERC20(bifiAddr);
    uint256 feeAmount = _payFee(userAddr);
    bifi.safeTransferFrom(userAddr, address(this), feeAmount);
    _createProduct(strategyID, userAddr, strategyParams);

    emit PayFee(userAddr, feeAmount);
    return true;
  }

   /**
   * @dev Create product and mint NFT
   * @param strategyID The ID of product strategy
   * @param sender The address of product creator and own nft
   * @param strategyParams The encoded parameter of strategy
   * @return Whether or not create succeed
   */
  function _createProduct(uint256 strategyID, address sender, bytes memory strategyParams) internal returns (address, uint256) {
    StrategyParams memory vars;

    // TODO more abstraction
    // decode strategyParams
    (vars.tokenAddr,
    vars.handlersAddress,
    vars.handlerIDs,
    // 0: flashloan fee, 1: swap fee
    vars.fees,
    // 0: collateral amount, 1: lending amount, 2:flashloan amount
    vars.amounts,
    vars.decimal) = abi.decode(strategyParams, (address[], address[], uint256[], uint256[], uint256[], uint256[]));

    IERC721 nft = IERC721(NFT);
    uint256 productID = nft.totalSupply();

    // create new user's product contract include registered logic
    address payable productAddr = address(new ProductProxy(strategyID, address(NFT), address(this), productID));

    // mint NFT token for user's product owner access control
    nft.mint(sender, productID);

    // store product information in storage contract
    IPositionStorage positionStorage = IPositionStorage(storageAddr);

    positionStorage.newUserProduct(sender, productAddr);
    positionStorage.setProductToNFTID(productAddr, productID);

    // send collateral asset for start strategy
    if(msg.value == 0){
      IERC20(vars.tokenAddr[0]).safeTransferFrom(
        sender,
        productAddr,
        _convertUnifiedToUnderlying(vars.amounts[0].add(vars.fees[0]).add(vars.fees[1]), vars.decimal[0])
      );

      IStrategy(productAddr).startStrategy(strategyParams);
    } else {
      require(msg.value == vars.amounts[0].add(vars.fees[0]).add(vars.fees[1]), "FE001");
      IStrategy(productAddr).startStrategy{value: msg.value}(strategyParams);
    }

    emit Create(strategyID, productID, productAddr, msg.sender);
    return (productAddr, productID);
  }

  function payFee(address user) external view returns (uint256) {
    return _payFee(user);
  }

  function _payFee(address user) internal view returns (uint256) {
    uint256 amount = fee;

    IERC20 bifi = IERC20(bifiAddr);

    uint256 bifiBalance = bifi.balanceOf(user);

    // discount model
    if (bifiBalance > fee) {
      bifiBalance = bifiBalance.sub(fee);
      // (static bifi amount) * (0.1 + 0.9 * min(1.0, (BASE * 10^18) / bifiBalance))
      uint256 unifiedPoint = 10 ** 18;
      uint256 minimum = 10 ** 17;
      uint256 slope = unifiedPoint - minimum;
      uint256 discountRate = _min(unifiedPoint, discountBase.unifiedDiv(bifiBalance));

      amount = amount.unifiedMul(
        minimum.add(slope.unifiedMul(discountRate))
      );
    }

    return amount;
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a >= b) { return b; }
    return a;
  }

  function setStrategy(uint256 strategyID, address strategyAddr) external onlyOwner returns (bool) {
    IPositionStorage(storageAddr).setStrategy(strategyID, strategyAddr);
    return true;
  }

  function getStrategy(uint256 strategyID) external view returns (address) {
    return IPositionStorage(storageAddr).getStrategy(strategyID);
  }

  function setBifiAddr(address _bifiAddr) external onlyOwner returns (bool) {
    bifiAddr = _bifiAddr;
    return true;
  }

  function getBifiAddr() external view returns (address) {
    return bifiAddr;
  }

  function setWethAddr(address _wethAddr) external onlyOwner returns (bool) {
    wethAddr = _wethAddr;
    return true;
  }

  function setOwner(address owner) external onlyOwner returns (bool) {
    _setOwner(owner);
  }

  function setImplements(address implementsAddr) external onlyOwner returns (bool) {
    return _setImplements(implementsAddr);
  }

  function setStorageAddr(address storageAddr) external onlyOwner returns (bool) {
    return _setStorageAddr(storageAddr);
  }

  function getWETHAddr() external view returns (address) {
    return wethAddr;
  }

  function setManagerAddr(address _bifiManagerAddr) external onlyOwner returns (bool) {
    _setManagerAddr(_bifiManagerAddr);
    return true;
  }

  function setUniswapV2Addr(address _uniswapV2Addr) external onlyOwner returns (bool) {
    _setUniswapV2Addr(_uniswapV2Addr);
    return true;
  }

  function setNFT(address payable nftAddr) external onlyOwner returns (bool) {
    _setNFT(nftAddr);
    return true;
  }

  function setFee(uint256 _fee) external onlyOwner returns (bool) {
    _setFee(_fee);
    return true;
  }

  function setDiscountBase(uint256 _discountBase) external onlyOwner returns (bool) {
    _setDiscountBase(_discountBase);
    return true;
  }

  function getManagerAddr() external view returns (address) {
    return bifiManagerAddr;
  }

  function getUniswapAddr() external view returns (address) {
    return uniswapV2Addr;
  }

  function getNFT() external view returns (address) {
    return NFT;
  }

  function withdrawFee(address owner, uint256 amount) external onlyOwner returns (bool){
    // pay use BiFi-X
    IERC20 bifi = IERC20(bifiAddr);
    bifi.safeTransfer(owner, amount);
    emit WithdrawFee(owner, amount);
    return true;
  }
}

// File: contracts/XFactory/logic/XFactoryLogic.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
  * @title BiFi-X XFactory logic contract
  * @author BiFi-X(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
  */
contract XFactoryLogic is XFactoryExternal {
  constructor(address _storageAddr, address _bifiManagerAddr) public {
    owner = msg.sender;
    storageAddr = _storageAddr;
    bifiManagerAddr = _bifiManagerAddr;
  }
}