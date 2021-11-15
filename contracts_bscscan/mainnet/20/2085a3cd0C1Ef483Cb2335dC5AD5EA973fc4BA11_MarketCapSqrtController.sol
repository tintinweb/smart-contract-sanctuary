// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Interfaces ========== */
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* ========== External Libraries ========== */
import "../lib/FixedPoint.sol";

/* ========== Internal Inheritance ========== */
import "./OwnableProxy.sol";


/**
 * @title MarketCapSortedCategories
 * @author d1ll0n
 *
 * @dev This contract stores token categories created by the contract owner.
 * Token categories are sorted by their fully diluted market caps, which is
 * extrapolated by multiplying each token's total supply by its moving
 * average weth price on UniSwap.
 *
 * Categories are periodically sorted, ranking their tokens in descending order by
 * market cap.
 *
 * CRITERIA
 * ===============
 * To be added to a category, a token should meet the following requirements in addition
 * to any other criteria for the particular category:
 *
 * 1. The token is at least a week old.
 * 2. The token complies with the ERC20 standard (boolean return values not required)
 * 3. No major vulnerabilities have been discovered in the token contract.
 * 4. The token does not have a deflationary supply model.
 * 5. The token's supply can not be arbitrarily inflated or deflated maliciously.
 * 5.a. The control model should be considered if the supply can be modified arbitrarily.
 * ===============
 */
contract MarketCapSortedTokenCategories is OwnableProxy {
/* ==========  Constants  ========== */

  uint32 internal constant LONG_TWAP_MIN_TIME_ELAPSED = 1 days;
  uint32 internal constant LONG_TWAP_MAX_TIME_ELAPSED = 1.5 weeks;

  // TWAP parameters for assessing current price
  uint32 internal constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 internal constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;


  // Maximum time between a category being sorted and a query for the top n tokens
  uint256 internal constant MAX_SORT_DELAY = 1 days;

  // Maximum number of tokens in a category
  uint256 internal constant MAX_CATEGORY_TOKENS = 25;


/* ==========  Events  ========== */

  /** @dev Emitted when a new category is created. */
  event CategoryAdded(uint256 categoryID, bytes32 metadataHash);

  /** @dev Emitted when a category is sorted. */
  event CategorySorted(uint256 categoryID);

  /** @dev Emitted when a token is added to a category. */
  event TokenAdded(address token, uint256 categoryID);

  /** @dev Emitted when a token is removed from a category. */
  event TokenRemoved(address token, uint256 categoryID);

/* ==========  Storage  ========== */

  // Number of categories that exist.
  uint256 public categoryIndex;

  // Oracle connected to category. 
  mapping(uint256 => IBisharesUniswapV2Oracle) internal _categoryOracles;

  // Routers connected to the category.
  mapping(uint256 => address ) internal _categoryRouters;

  // Array of tokens for each category.
  mapping(uint256 => address[]) internal _categoryTokens;

  // Weight value for tokens for each category
  mapping(uint256 => mapping(address => FixedPoint.uq112x112)) internal _categoryTokensInitialWeights;

  mapping(uint256 => mapping(address => bool)) internal _isCategoryToken;

  // Last time a category was sorted
  mapping(uint256 => uint256) internal _lastCategoryUpdate;


/* ========== Modifiers ========== */

  modifier validCategory(uint256 categoryID) {
    require(categoryID <= categoryIndex && categoryID > 0, "ERR_CATEGORY_ID");
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related contracts.
   */
  constructor() public OwnableProxy() {}

/* ==========  Initializer  ========== */

  /**
   * @dev Initialize the categories with the owner address.
   * This sets up the contract which is deployed as a singleton proxy.
   */
  function initialize() public virtual {
    _initializeOwnership();
  }

/* ==========  Category Management  ========== */

  /**
   * @dev Updates the prices on the oracle for all the tokens in a category.
   */
  function updateCategoryPrices(uint256 categoryID) external validCategory(categoryID) returns (bool[] memory pricesUpdated) {
    address[] memory tokens = _categoryTokens[categoryID];
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID];
    pricesUpdated = oracle.updatePrices(tokens);
  }

  /**
   * @dev Creates a new token category.
   * @param metadataHash Hash of metadata about the token category
   * which can be distributed on IPFS.
   * @param oracle The UniswapV2oracle connected to this category. 
   * @param router The Router of the uniswap connected to this category. 
   */
  function createCategory(bytes32 metadataHash, IBisharesUniswapV2Oracle oracle, address router) external onlyOwner {
    uint256 categoryID = ++categoryIndex;
    _categoryOracles[categoryID] = oracle;
    _categoryRouters[categoryID] = router;
    emit CategoryAdded(categoryID, metadataHash);
  }

  /**
   * @dev Adds a new token to a category.
   *
   * @param categoryID Category identifier.
   * @param token Token to add to the category.
   */
  function addToken(
    uint256 categoryID,
    address token,
    FixedPoint.uq112x112 memory weight
  ) 
    external
    onlyOwner
    validCategory(categoryID)
  {
    require(
      _categoryTokens[categoryID].length < MAX_CATEGORY_TOKENS,
      "ERR_MAX_CATEGORY_TOKENS"
    );
    _addToken(categoryID, token, weight);
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID]; 
    oracle.updatePrice(token);
    // Decrement the timestamp for the last category update to ensure
    // that the new token is sorted before the category's top tokens
    // can be queried.
    _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
  }

  /**
   * @dev Add tokens to a category.
   * @param categoryID Category identifier.
   * @param tokens Array of tokens to add to the category.
   */
  function addTokens(
    uint256 categoryID,
    address[] calldata tokens,
    FixedPoint.uq112x112[] memory weights
  )
    external
    onlyOwner
    validCategory(categoryID)
  {
    uint256 len = tokens.length;
    require(
      _categoryTokens[categoryID].length + len <= MAX_CATEGORY_TOKENS,
      "ERR_MAX_CATEGORY_TOKENS"
    );
    require(weights.length == len, "ERR_WEIGHTS_LEN");
    for (uint256 i = 0; i < len; i++) {
      _addToken(categoryID, tokens[i], weights[i]);
    }
   
    _categoryOracles[categoryID].updatePrices(tokens);
    // Decrement the timestamp for the last category update to ensure
    // that the new tokens are sorted before the category's top tokens
    // can be queried.
    _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
  }

  /**
   * @dev Remove token from a category.
   * @param categoryID Category identifier.
   * @param token Token to remove from the category.
   */
  function removeToken(uint256 categoryID, address token) external onlyOwner validCategory(categoryID) {
    uint256 i = 0;
    uint256 len = _categoryTokens[categoryID].length;
    require(len > 0, "ERR_EMPTY_CATEGORY");
    require(_isCategoryToken[categoryID][token], "ERR_TOKEN_NOT_BOUND");
    _isCategoryToken[categoryID][token] = false;
    for (; i < len; i++) {
      if (_categoryTokens[categoryID][i] == token) {
        uint256 last = len - 1;
        if (i != last) {
          address lastToken = _categoryTokens[categoryID][last];
          _categoryTokens[categoryID][i] = lastToken;
        }
        _lastCategoryUpdate[categoryID] -= MAX_SORT_DELAY;
        _categoryTokens[categoryID].pop();
        _categoryTokensInitialWeights[categoryID][token] = FixedPoint.uq112x112(0);
        emit TokenRemoved(token, categoryID);
        return;
      }
    }
    // This will never occur.
    revert("ERR_NOT_FOUND");
  }

  /**
   * @dev Sorts a category's tokens in descending order by market cap.
   * Note: Uses in-memory insertion sort.
   *
   * @param categoryID Category to sort
   */
  function orderCategoryTokensByMarketCap(uint256 categoryID) external validCategory(categoryID) {
    address[] memory categoryTokens = _categoryTokens[categoryID];
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID];
    uint256 len = categoryTokens.length;
    uint144[] memory marketCaps = computeAverageMarketCaps(categoryTokens, oracle);
    for (uint256 i = 1; i < len; i++) {
      uint144 cap = marketCaps[i];
      address token = categoryTokens[i];
      uint256 j = i - 1;
      while (int(j) >= 0 && marketCaps[j] < cap) {
        marketCaps[j + 1] = marketCaps[j];
        categoryTokens[j + 1] = categoryTokens[j];
        j--;
      }
      marketCaps[j + 1] = cap;
      categoryTokens[j + 1] = token;
    }
    _categoryTokens[categoryID] = categoryTokens;
    
    _lastCategoryUpdate[categoryID] = block.timestamp;
    emit CategorySorted(categoryID);
  }

/* ==========  Market Cap Queries  ========== */

  /**
   * @dev Compute the average market cap of a token in weth.
   * Queries the average amount of ether that the total supply is worth
   * using the recent moving average price.
   */
  function computeAverageMarketCap(address token, IBisharesUniswapV2Oracle oracle)
    external
    view
    returns (uint144)
  {
    uint256 totalSupply = IERC20(token).totalSupply();
    return oracle.computeAverageEthForTokens(
      token,
      totalSupply,
      LONG_TWAP_MIN_TIME_ELAPSED,
      LONG_TWAP_MAX_TIME_ELAPSED
    ); 
  }

  /**
   * @dev Returns the average market cap for each token.
   */
  function computeAverageMarketCaps(address[] memory tokens, IBisharesUniswapV2Oracle oracle)
    public
    view
    returns (uint144[] memory marketCaps)
  {
    uint256 len = tokens.length;
    uint256[] memory totalSupplies = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      totalSupplies[i] = IERC20(tokens[i]).totalSupply();
    }
    marketCaps = oracle.computeAverageEthForTokens(
      tokens,
      totalSupplies,
      LONG_TWAP_MIN_TIME_ELAPSED,
      LONG_TWAP_MAX_TIME_ELAPSED
    );
  }

/* ==========  Category Queries  ========== */

  /**
   * @dev Returns a boolean stating whether a category exists.
   */
  function hasCategory(uint256 categoryID) external view returns (bool) {
    return categoryID <= categoryIndex && categoryID > 0;
  }

  /**
   * @dev Returns the timestamp of the last time the category was sorted.
   */
  function getLastCategoryUpdate(uint256 categoryID)
    external
    view
    validCategory(categoryID)
    returns (uint256)
  {
    return _lastCategoryUpdate[categoryID];
  }

  /**
   * @dev Returns boolean stating whether `token` is a member of the category `categoryID`.
   */
  function isTokenInCategory(uint256 categoryID, address token)
    external
    view
    validCategory(categoryID)
    returns (bool)
  {
    return _isCategoryToken[categoryID][token];
  }

  /**
   * @dev Returns the array of tokens in a category.
   */
  function getCategoryTokens(uint256 categoryID)
    external
    view
    validCategory(categoryID)
    returns (address[] memory tokens)
  {
    address[] storage _tokens = _categoryTokens[categoryID];
    tokens = new address[](_tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      tokens[i] = _tokens[i];
    }
  }

  function getCategoryTokensInitialWeights(uint256 categoryID)
    external
    view
    validCategory(categoryID)
    returns (FixedPoint.uq112x112[] memory weights)
  {
    address[] storage _tokens = _categoryTokens[categoryID];
    weights = new FixedPoint.uq112x112[](_tokens.length);
    for (uint256 i = 0; i < weights.length; i++) {
      weights[i] = _categoryTokensInitialWeights[categoryID][_tokens[i]];
    }
  }

  /**
   * @dev Returns the fully diluted market caps for the tokens in a category.
   */
  function getCategoryMarketCaps(uint256 categoryID)
    external
    view
    validCategory(categoryID)
    returns (uint144[] memory marketCaps)
  {
    return computeAverageMarketCaps(_categoryTokens[categoryID], _categoryOracles[categoryID]);
  }

  /**
   * @dev Get the top `num` tokens in a category.
   *
   * Note: The category must have been sorted by market cap
   * in the last `MAX_SORT_DELAY` seconds.
   */
  function getTopCategoryTokens(uint256 categoryID, uint256 num)
    public
    view
    validCategory(categoryID)
    returns (address[] memory tokens)
  {
    address[] storage categoryTokens = _categoryTokens[categoryID];
    require(num <= categoryTokens.length, "ERR_CATEGORY_SIZE");
    require(
      block.timestamp - _lastCategoryUpdate[categoryID] <= MAX_SORT_DELAY,
      "ERR_CATEGORY_NOT_READY"
    );
    tokens = new address[](num);
    for (uint256 i = 0; i < num; i++) tokens[i] = categoryTokens[i];
  }

  function getTopCategoryTokensInitialWeights(uint256 categoryID, uint256 num)
    public
    view
    validCategory(categoryID)
    returns (FixedPoint.uq112x112[] memory weights)
  {
    address[] storage categoryTokens = _categoryTokens[categoryID];
    require(num <= categoryTokens.length, "ERR_CATEGORY_SIZE");
    require(
      block.timestamp - _lastCategoryUpdate[categoryID] <= MAX_SORT_DELAY,
      "ERR_CATEGORY_NOT_READY"
    );
    weights = new FixedPoint.uq112x112[](num);
    for (uint256 i = 0; i < num; i++) weights[i] = _categoryTokensInitialWeights[categoryID][categoryTokens[i]];
  }

/* ==========  Category Utility Functions  ========== */

  /**
   * @dev Adds a new token to a category.
   */
  function _addToken(uint256 categoryID, address token, FixedPoint.uq112x112 memory weight) internal {
    require(!_isCategoryToken[categoryID][token], "ERR_TOKEN_BOUND");
    require(weight._x != 0, "ERR_WEIGHT");
    _isCategoryToken[categoryID][token] = true;
    _categoryTokens[categoryID].push(token);
    _categoryTokensInitialWeights[categoryID][token] = weight;
    emit TokenAdded(token, categoryID);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Interfaces ========== */
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "../interfaces/IDelegateCallProxyManager.sol";

/* ========== External Libraries ========== */
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";
import "../proxies/SaltyLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/* ========== Internal Interfaces ========== */
import "../interfaces/IIndexPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IPoolInitializer.sol";
import "../interfaces/IUnboundTokenSeller.sol";

/* ========== Internal Libraries ========== */
import "../lib/MCapSqrtLibrary.sol";

/* ========== Internal Inheritance ========== */
import "./MarketCapSortedTokenCategories.sol";


/**
 * @title MarketCapSqrtController
 * @author d1ll0n
 * @dev This contract implements the market cap square root index management strategy.
 *
 * Bishares pools have a defined size which is used to select the top tokens from the pool's
 * category.
 *
 * REBALANCING
 * ===============
 * Every 1 weeks, pools are either re-weighed or re-indexed.
 * They are re-indexed once for every three re-weighs.
 *
 * Re-indexing involves selecting the top tokens from the pool's category and weighing them
 * by the square root of their market caps.
 * Re-weighing involves weighing the tokens which are already indexed by the pool by the
 * square root of their market caps.
 * When a pool is re-weighed, only the tokens with a desired weight above 0 are included.
 * ===============
 */
contract MarketCapSqrtController is MarketCapSortedTokenCategories {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using SafeMath for uint256;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;

/* ==========  Constants  ========== */
  // Minimum number of tokens in an index.
  uint256 internal constant MIN_INDEX_SIZE = 2;

  // Maximum number of tokens in an index.
  uint256 internal constant MAX_INDEX_SIZE = 25;

  // Minimum balance for a token (only applied at initialization)
  uint256 internal constant MIN_BALANCE = 1e6;

  // Identifier for the pool initializer implementation on the proxy manager.
  bytes32 internal constant INITIALIZER_IMPLEMENTATION_ID = keccak256("PoolInitializer.sol");

  // Identifier for the unbound token seller implementation on the proxy manager.
  bytes32 internal constant SELLER_IMPLEMENTATION_ID = keccak256("UnboundTokenSeller.sol");

  // Identifier for the index pool implementation on the proxy manager.
  bytes32 internal constant POOL_IMPLEMENTATION_ID = keccak256("IndexPool.sol");

  // Default total weight for a pool.
  uint256 internal constant WEIGHT_MULTIPLIER = 25e18;

  // Time between reweigh/reindex calls.
  uint256 internal constant POOL_REWEIGH_DELAY = 1 weeks;

  // The number of reweighs which occur before a pool is re-indexed.
  uint256 internal constant REWEIGHS_BEFORE_REINDEX = 3;

  // Pool factory contract
  IPoolFactory internal immutable _factory;

  // Proxy manager & factory
  IDelegateCallProxyManager internal immutable _proxyManager;

  // Exit fee recipient for the index pools
  address public immutable defaultExitFeeRecipient;

  address public immutable defaultExitFeeRecipientAdditional;
  

/* ==========  Events  ========== */

  /** @dev Emitted when a pool is initialized and made public. */
  event PoolInitialized(
    address pool,
    address unboundTokenSeller,
    uint256 categoryID,
    uint256 indexSize
  );

  /** @dev Emitted when a pool and its initializer are deployed. */
  event NewPoolInitializer(
    address pool,
    address initializer
  );

/* ==========  Structs  ========== */

  /**
   * @dev Data structure with metadata about an index pool.
   *
   * Includes the number of times a pool has been either reweighed
   * or re-indexed, as well as the timestamp of the last such action.
   *
   * To reweigh or re-index, the last update must have occurred at
   * least `POOL_REWEIGH_DELAY` seconds ago.
   *
   * If `++index % REWEIGHS_BEFORE_REINDEX + 1` is 0, the pool will
   * re-index, otherwise it will reweigh.
   *
   * The struct fields are assigned their respective integer sizes so
   * that solc can pack the entire struct into a single storage slot.
   * `reweighIndex` is intended to overflow, `categoryID` will never
   * reach 2**16, `indexSize` is capped at 10 and it is unlikely that
   * this protocol will be in use in the year 292277026596 (unix time
   * for 2**64 - 1).
   *
   * @param initialized Whether the pool has been initialized with the
   * starting balances.
   * @param categoryID Category identifier for the pool.
   * @param indexSize Number of tokens the pool should hold.
   * @param reweighIndex Number of times the pool has either re-weighed
   * or re-indexed.
   * @param lastReweigh Timestamp of last pool re-weigh or re-index.
   */
  struct IndexPoolMeta {
    bool initialized;
    uint16 categoryID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }

/* ==========  Storage  ========== */

  // Default slippage rate for token seller contracts.
  uint8 public defaultSellerPremium;

  // Metadata about index pools
  mapping(address => IndexPoolMeta) internal _poolMeta;
  

/* ========== Modifiers ========== */

  modifier _havePool(address pool) {
    require(_poolMeta[pool].initialized, "ERR_POOL_NOT_FOUND");
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related contracts.
   */
  constructor(
    IPoolFactory factory,
    IDelegateCallProxyManager proxyManager,
    address defaultExitFeeRecipient_,
    address defaultExitFeeRecipientAdditional_
  )
    public
    MarketCapSortedTokenCategories()
  {
    _factory = factory;
    _proxyManager = proxyManager;
    defaultExitFeeRecipient = defaultExitFeeRecipient_;
    defaultExitFeeRecipientAdditional = defaultExitFeeRecipientAdditional_;
  }

/* ==========  Initializer  ========== */

  /**
   * @dev Initialize the controller with the owner address and default seller premium.
   * This sets up the controller which is deployed as a singleton proxy.
   */
  function initialize() public override {
    defaultSellerPremium = 2;
    super.initialize();
  }

/* ==========  Pool Deployment  ========== */

  /**
   * @dev Deploys an index pool and a pool initializer.
   * The initializer contract is a pool with specific token
   * balance targets which gives pool tokens in the finished
   * pool to users who provide the underlying tokens needed
   * to initialize it.
   */
  function prepareIndexPool(
    uint256 categoryID,
    uint256 indexSize,
    uint256 initialWethValue,
    string calldata name,
    string calldata symbol
  )
    external
    onlyOwner
    returns (address poolAddress, address initializerAddress)
  {
    require(indexSize >= MIN_INDEX_SIZE, "ERR_MIN_INDEX_SIZE");
    require(indexSize <= MAX_INDEX_SIZE, "ERR_MAX_INDEX_SIZE");
    require(initialWethValue < uint144(-1), "ERR_MAX_UINT144");

    address router = _categoryRouters[categoryID]; // _categoryRouters[categoryID]
    IBisharesUniswapV2Oracle oracle = _categoryOracles[categoryID]; // _categoryOracles[categoryID]

    poolAddress = _factory.deployPool(
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(categoryID, indexSize))
    );
    IIndexPool(poolAddress).configure(
      address(this),
      name,
      symbol,
      address(oracle),
      router,
      defaultExitFeeRecipient,
      defaultExitFeeRecipientAdditional
    );

    _poolMeta[poolAddress] = IndexPoolMeta({
      initialized: false,
      categoryID: uint16(categoryID),
      indexSize: uint8(indexSize),
      lastReweigh: 0,
      reweighIndex: 0
    });

    initializerAddress = _proxyManager.deployProxyManyToOne(
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IPoolInitializer initializer = IPoolInitializer(initializerAddress);

    // Get the initial tokens and balances for the pool.
    (
      address[] memory tokens,
      uint256[] memory balances
    ) = getInitialTokensAndBalances(categoryID, indexSize, uint144(initialWethValue));

    initializer.initialize(poolAddress, tokens, balances, oracle);

    emit NewPoolInitializer(
      poolAddress,
      initializerAddress
    );
 
  }

  /**
   * @dev Initializes a pool which has been deployed but not initialized
   * and transfers the underlying tokens from the initialization pool to
   * the actual pool.
   */
  function finishPreparedIndexPool(
    address poolAddress,
    address[] calldata tokens,
    uint256[] calldata balances
  ) external {
    require(
      msg.sender == computeInitializerAddress(poolAddress),
      "ERR_NOT_PRE_DEPLOY_POOL"
    );
    uint256 len = tokens.length;
    require(balances.length == len, "ERR_ARR_LEN");

    address oracleAddress = IIndexPool(poolAddress).oracle();

    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(!meta.initialized, "ERR_INITIALIZED");
    uint96[] memory denormalizedWeights = new uint96[](len);
    uint256 valueSum;
    uint144[] memory ethValues = IBisharesUniswapV2Oracle(oracleAddress).computeAverageEthForTokens(
      tokens,
      balances,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    for (uint256 i = 0; i < len; i++) {
      valueSum = valueSum.add(ethValues[i]);
    }
    for (uint256 i = 0; i < len; i++) {
      denormalizedWeights[i] = _denormalizeFractionalWeight(
        FixedPoint.fraction(uint112(ethValues[i]), uint112(valueSum))
      );
    }

    address sellerAddress = _proxyManager.deployProxyManyToOne(
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IIndexPool(poolAddress).initialize(
      tokens,
      balances,
      denormalizedWeights,
      msg.sender,
      sellerAddress
    );

    IUnboundTokenSeller(sellerAddress).initialize(
      poolAddress,
      defaultSellerPremium
    );

    meta.lastReweigh = uint64(block.timestamp);
    meta.initialized = true;
    _poolMeta[poolAddress] = meta;

    emit PoolInitialized(
      poolAddress,
      sellerAddress,
      meta.categoryID,
      meta.indexSize
    );
  }

/* ==========  Pool Management  ========== */

  /**
   * @dev Sets the default premium rate for token seller contracts.
   */
  function setDefaultSellerPremium(
    uint8 _defaultSellerPremium
  ) external onlyOwner {
    require(_defaultSellerPremium > 0 && _defaultSellerPremium < 20, "ERR_PREMIUM");
    defaultSellerPremium = _defaultSellerPremium;
  }

  /**
   * @dev Set the premium rate on `sellerAddress` to the given rate.
   */
  function updateSellerPremium(address tokenSeller, uint8 premiumPercent) external onlyOwner {
    require(premiumPercent > 0 && premiumPercent < 20, "ERR_PREMIUM");
    IUnboundTokenSeller(tokenSeller).setPremiumPercent(premiumPercent);
  }

  
  /**
   * @dev Sets the maximum number of pool tokens that can be minted
   * for a particular pool.
   *
   * This value will be used in the alpha to limit the maximum damage
   * that can be caused by a catastrophic error. It can be gradually
   * increased as the pool continues to not be exploited.
   *
   * If it is set to 0, the limit will be removed.
   *
   * @param poolAddress Address of the pool to set the limit on.
   * @param maxPoolTokens Maximum LP tokens the pool can mint.
   */
  function setMaxPoolTokens(
    address poolAddress,
    uint256 maxPoolTokens
  ) external onlyOwner _havePool(poolAddress) {
    IIndexPool(poolAddress).setMaxPoolTokens(maxPoolTokens);
  }

  /**
   * @dev Sets the swap fee on an index pool.
   */
  function setExitFeeReciver(
    address poolAddress,
    address exitFeeRecipient,
    bool additional
  ) external onlyOwner _havePool(poolAddress) {
    IIndexPool(poolAddress).setExitFeeRecipient(exitFeeRecipient, additional);
  }

  /**
   * @dev Updates the minimum balance of an uninitialized token, which is
   * useful when the token's price on the pool is too low relative to
   * external prices for people to trade it in.
   */
  function updateMinimumBalance(IIndexPool pool, address tokenAddress) external _havePool(address(pool)) {
    IIndexPool.Record memory record = pool.getTokenRecord(tokenAddress);
    require(!record.ready, "ERR_TOKEN_READY");
    uint256 poolValue = _estimatePoolValue(pool);

    address oracleAddress = IIndexPool(pool).oracle();

    PriceLibrary.TwoWayAveragePrice memory price = IBisharesUniswapV2Oracle(oracleAddress).computeTwoWayAveragePrice(
      tokenAddress,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint256 minimumBalance = price.computeAverageTokensForEth(poolValue) / 100;
    pool.setMinimumBalance(tokenAddress, minimumBalance);
  }

  /**
   * @dev Delegates a comp-like governance token from an index pool
   * to a provided address.
   */
  function delegateCompLikeTokenFromPool(
    address pool,
    address token,
    address delegatee
  )
    external
    onlyOwner
    _havePool(pool)
  {
    IIndexPool(pool).delegateCompLikeToken(token, delegatee);
  }

/* ==========  Pool Rebalance Actions  ========== */

  /**
   * @dev Re-indexes a pool by setting the underlying assets to the top
   * tokens in its category by market cap.
   */
  function reindexPool(address poolAddress) external {
    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");
    require(
      block.timestamp - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );
    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) == 0,
      "ERR_REWEIGH_INDEX"
    );
    uint256 size = meta.indexSize;
    uint256 categoryID = meta.categoryID;
    address[] memory tokens = getTopCategoryTokens(categoryID, size);

    address oracleAddress = IIndexPool(poolAddress).oracle();

    PriceLibrary.TwoWayAveragePrice[] memory prices = IBisharesUniswapV2Oracle(oracleAddress).computeTwoWayAveragePrices(
      tokens,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(categoryID, size);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);

    uint256[] memory minimumBalances = new uint256[](size);
    uint96[] memory denormalizedWeights = new uint96[](size);
    uint144 totalValue = _estimatePoolValue(IIndexPool(poolAddress));

    for (uint256 i = 0; i < size; i++) {
      // The minimum balance is the number of tokens worth the minimum weight
      // of the pool. The minimum weight is 1/100, so we divide the total value
      // by 100 to get the desired weth value, then multiply by the price of eth
      // in terms of that token to get the minimum balance.
      minimumBalances[i] = prices[i].computeAverageTokensForEth(totalValue) / 100;
      denormalizedWeights[i] = _denormalizeFractionalWeight(weights[i]);
    }

    meta.lastReweigh = uint64(block.timestamp);
    _poolMeta[poolAddress] = meta;

    IIndexPool(poolAddress).reindexTokens(
      tokens,
      denormalizedWeights,
      minimumBalances
    );
  }

  /**
   * @dev Reweighs the assets in a pool by market cap and sets the
   * desired new weights, which will be adjusted over time.
   */
  function reweighPool(address poolAddress) external {
    IndexPoolMeta memory meta = _poolMeta[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");

    require(
      block.timestamp - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );

    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) != 0,
      "ERR_REWEIGH_INDEX"
    );

    address[] memory tokens = IIndexPool(poolAddress).getCurrentDesiredTokens();

    address oracleAddress = IIndexPool(poolAddress).oracle();
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(meta.categoryID, meta.indexSize);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);
    uint96[] memory denormalizedWeights = new uint96[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      denormalizedWeights[i] = _denormalizeFractionalWeight(weights[i]);
    }

    meta.lastReweigh = uint64(block.timestamp);
    _poolMeta[poolAddress] = meta;
    IIndexPool(poolAddress).reweighTokens(tokens, denormalizedWeights);
  }

/* ==========  Pool Queries  ========== */

  /**
   * @dev Compute the create2 address for a pool initializer.
   */
  function computeInitializerAddress(address poolAddress)
    public
    view
    returns (address initializerAddress)
  {
    initializerAddress = SaltyLib.computeProxyAddressManyToOne(
      address(_proxyManager),
      address(this),
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool's unbound token seller.
   */
  function computeSellerAddress(address poolAddress)
    external
    view
    returns (address sellerAddress)
  {
    sellerAddress = SaltyLib.computeProxyAddressManyToOne(
      address(_proxyManager),
      address(this),
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool.
   */
  function computePoolAddress(uint256 categoryID, uint256 indexSize)
    external
    view
    returns (address poolAddress)
  {
    poolAddress = SaltyLib.computeProxyAddressManyToOne(
      address(_proxyManager),
      address(_factory),
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(
        address(this),
        keccak256(abi.encodePacked(categoryID, indexSize))
      ))
    );
  }

  /**
   * @dev Queries the top `indexSize` tokens in a category from the market oracle,
   * computes their relative weights by market cap square root and determines
   * the weighted balance of each token to meet a specified total value.
   */
  function getInitialTokensAndBalances(
    uint256 categoryID,
    uint256 indexSize,
    uint144 wethValue
  )
    public
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances
    )
  {
    tokens = getTopCategoryTokens(categoryID, indexSize);
    PriceLibrary.TwoWayAveragePrice[] memory prices = _categoryOracles[categoryID].computeTwoWayAveragePrices(
      tokens,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    FixedPoint.uq112x112[] memory weights = getTopCategoryTokensInitialWeights(categoryID, indexSize);
    weights = MCapSqrtLibrary.computeTokenWeights(weights);
    balances = new uint256[](indexSize);
    for (uint256 i = 0; i < indexSize; i++) {
      uint256 targetBalance = MCapSqrtLibrary.computeWeightedBalance(
        wethValue,
        weights[i],
        prices[i]
      );
      require(targetBalance >= MIN_BALANCE, "ERR_MIN_BALANCE");
      balances[i] = targetBalance;
    }
  }

/* ==========  Internal Pool Utility Functions  ========== */

  /**
   * @dev Estimate the total value of a pool by taking its first token's
   * "virtual balance" (balance * (totalWeight/weight)) and multiplying
   * by that token's average ether price from UniSwap.
   */
  function _estimatePoolValue(IIndexPool pool) internal view returns (uint144) {

    (address token, uint256 value) = pool.extrapolatePoolValueFromToken();

    address oracleAddress = pool.oracle();

    return IBisharesUniswapV2Oracle(oracleAddress).computeAverageEthForTokens(
      token,
      value,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
  }

/* ==========  General Utility Functions  ========== */

  /**
   * @dev Converts a fixed point fraction to a denormalized weight.
   * Multiply the fraction by the max weight and decode to an unsigned integer.
   */
  function _denormalizeFractionalWeight(FixedPoint.uq112x112 memory fraction)
    internal
    pure
    returns (uint96)
  {
    return uint96(fraction.mul(WEIGHT_MULTIPLIER).decode144());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This is a modified implementation of OpenZeppelin's Ownable.sol.
 * The modifications allow the contract to be inherited by a proxy's logic contract.
 * Any owner-only functions on the base implementation will be unusable.
 *
 * By default, the owner account will be a null address which can be set by the
 * first call to {initializeOwner}. This can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner. It also makes the function {initializeOwner} available to be used
 * in the initialization function for the inherited contract.
 *
 * Note: This contract should only be inherited by proxy implementation contracts
 * where the implementation will only ever be used as the logic address for proxies.
 * The constructor permanently locks the owner of the implementation contract, but the
 * owner of the proxies can be configured by the first caller.
 */
contract OwnableProxy is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    _owner = address(1);
    emit OwnershipTransferred(address(0), address(1));
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
    // Modified from OZ contract - sets owner to address(1) to prevent
    // _initializeOwnership from being called after ownership is revoked.
    emit OwnershipTransferred(_owner, address(1));
    _owner = address(1);
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

  /**
   * @dev Initializes the contract setting the initializer as the initial owner.
   * Note: Owner address must be zero.
   */
  function _initializeOwnership() internal {
    require(_owner == address(0), "Ownable: owner has already been initialized");
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Initializes the contract setting the owner to an invalid address.
   * This ensures that the contract can never be owned, and should only be used
   * in the constructor of a proxy's implementation contract.
   * Note: Owner address must be zero.
   */
  function _lockImplementationOwner() internal {
    require(_owner == address(0), "Ownable: owner has already been initialized");
    emit OwnershipTransferred(address(0), address(1));
    _owner = address(1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Libraries  ========== */
import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IBisharesUniswapV2Oracle {
/* ==========  Mutative Functions  ========== */

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

/* ==========  Meta Price Queries  ========== */

  function hasPriceObservationInWindow(address token, uint256 priceKey) external view returns (bool);

  function getPriceObservationInWindow(
    address token, uint256 priceKey
  ) external view returns (PriceLibrary.PriceObservation memory);

  function getPriceObservationsInRange(
    address token, uint256 timeFrom, uint256 timeTo
  ) external view returns (PriceLibrary.PriceObservation[] memory prices);

/* ==========  Price Update Queries  ========== */

  function canUpdatePrice(address token) external view returns (bool);

  function canUpdatePrices(address[] calldata tokens) external view returns (bool[] memory);

/* ==========  Price Queries: Singular  ========== */

  function computeTwoWayAveragePrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice memory);

  function computeAverageTokenPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);

  function computeAverageEthPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);

/* ==========  Price Queries: Multiple  ========== */

  function computeTwoWayAveragePrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice[] memory);

  function computeAverageTokenPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);

  function computeAverageEthPrices(
    address[] calldata tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);

/* ==========  Value Queries: Singular  ========== */

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);

/* ==========  Value Queries: Multiple  ========== */

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/**
 * @dev Contract that manages deployment and upgrades of delegatecall proxies.
 *
 * An implementation identifier can be created on the proxy manager which is
 * used to specify the logic address for a particular contract type, and to
 * upgrade the implementation as needed.
 *
 * A one-to-one proxy is a single proxy contract with an upgradeable implementation
 * address.
 *
 * A many-to-one proxy is a single upgradeable implementation address that may be
 * used by many proxy contracts.
 */
interface IDelegateCallProxyManager {
/* ==========  Controls  ========== */

  /**
   * @dev Allows `deployer` to deploy many-to-one proxies.
   */
  function approveDeployer(address deployer) external;

  /**
   * @dev Prevents `deployer` from deploying many-to-one proxies.
   */
  function revokeDeployerApproval(address deployer) external;

/* ==========  Implementation Management  ========== */

  /**
   * @dev Creates a many-to-one proxy relationship.
   *
   * Deploys an implementation holder contract which stores the
   * implementation address for many proxies. The implementation
   * address can be updated on the holder to change the runtime
   * code used by all its proxies.
   *
   * @param implementationID ID for the implementation, used to identify the
   * proxies that use it. Also used as the salt in the create2 call when
   * deploying the implementation holder contract.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function createManyToOneProxyRelationship(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationManyToOne(bytes32 implementationID) external;

  /**
   * @dev Lock the current implementation for `proxyAddress` so that it can never be upgraded again.
   */
  function lockImplementationOneToOne(address proxyAddress) external;

  /**
   * @dev Updates the implementation address for a many-to-one
   * proxy relationship.
   *
   * @param implementationID Identifier for the implementation.
   * @param implementation Address with the runtime code the proxies
   * should use.
   */
  function setImplementationAddressManyToOne(
    bytes32 implementationID,
    address implementation
  ) external;

  /**
   * @dev Updates the implementation address for a one-to-one proxy.
   *
   * Note: This could work for many-to-one as well if the caller
   * provides the implementation holder address in place of the
   * proxy address, as they use the same access control and update
   * mechanism.
   *
   * @param proxyAddress Address of the deployed proxy
   * @param implementation Address with the runtime code for
   * the proxy to use.
   */
  function setImplementationAddressOneToOne(
    address proxyAddress,
    address implementation
  ) external;

/* ==========  Proxy Deployment  ========== */

  /**
   * @dev Deploy a proxy contract with a one-to-one relationship
   * with its implementation.
   *
   * The proxy will have its own implementation address which can
   * be updated by the proxy manager.
   *
   * @param suppliedSalt Salt provided by the account requesting deployment.
   * @param implementation Address of the contract with the runtime
   * code that the proxy should use.
   */
  function deployProxyOneToOne(
    bytes32 suppliedSalt,
    address implementation
  ) external returns(address proxyAddress);

  /**
   * @dev Deploy a proxy with a many-to-one relationship with its implemenation.
   *
   * The proxy will call the implementation holder for every transaction to
   * determine the address to use in calls.
   *
   * @param implementationID Identifier for the proxy's implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deployProxyManyToOne(
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external returns(address proxyAddress);

/* ==========  Queries  ========== */

  /**
   * @dev Returns a boolean stating whether `implementationID` is locked.
   */
  function isImplementationLocked(bytes32 implementationID) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `proxyAddress` is locked.
   */
  function isImplementationLocked(address proxyAddress) external view returns (bool);

  /**
   * @dev Returns a boolean stating whether `deployer` is allowed to deploy many-to-one
   * proxies.
   */
  function isApprovedDeployer(address deployer) external view returns (bool);

  /**
   * @dev Queries the temporary storage value `_implementationHolder`.
   * This is used in the constructor of the many-to-one proxy contract
   * so that the create2 address is static (adding constructor arguments
   * would change the codehash) and the implementation holder can be
   * stored as a constant.
   */
  function getImplementationHolder() external view returns (address);

  /**
   * @dev Returns the address of the implementation holder contract
   * for `implementationID`.
   */
  function getImplementationHolder(bytes32 implementationID) external view returns (address);

  /**
   * @dev Computes the create2 address for a one-to-one proxy requested
   * by `originator` using `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address originator,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` requested by `originator` using
   * `suppliedSalt`.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  ) external view returns (address);

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(bytes32 implementationID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string calldata name,
    string calldata symbol,
    address uniswapV2oracle,
    address uniswapV2router,
    address exitFeeReciver,
    address exitFeeReciverAdditional
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider,
    address unbindHandler
  ) external;

  function setMaxPoolTokens(uint256 maxPoolTokens) external;

  function delegateCompLikeToken(address token, address delegatee) external;

  function setExitFeeRecipient(address exitFeeRecipient, bool additional) external;

  function reweighTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms
  ) external;

  function reindexTokens(
    address[] calldata tokens,
    uint96[] calldata desiredDenorms,
    uint256[] calldata minimumBalances
  ) external;

  function setMinimumBalance(address token, uint256 minimumBalance) external;

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function gulp(address token) external;

  function flashBorrow(
    address recipient,
    address token,
    uint256 amount,
    bytes calldata data
  ) external;

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external returns (uint256/* tokenAmountOut */, uint256/* spotPriceAfter */);

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external returns (uint256 /* tokenAmountIn */, uint256 /* spotPriceAfter */);

  function oracle() external view returns (address);

  function router() external view returns (address);

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256/* swapFee */);

  function getController() external view returns (address);

  function getMaxPoolTokens() external view returns (uint256);

  function isBound(address t) external view returns (bool);

  function getNumTokens() external view returns (uint256);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getCurrentDesiredTokens() external view returns (address[] memory tokens);

  function getDenormalizedWeight(address token) external view returns (uint256/* denorm */);

  function getTokenRecord(address token) external view returns (Record memory record);

  function extrapolatePoolValueFromToken() external view returns (address/* token */, uint256/* extrapolatedValue */);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getBalance(address token) external view returns (uint256);

  function getMinimumBalance(address token) external view returns (uint256);

  function getUsedBalance(address token) external view returns (uint256);

  function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256);

  function getExitFee() external view returns (uint256/* exitFee */);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IDelegateCallProxyManager.sol";


interface IPoolFactory {

/* ========== Mutative ========== */

  function approvePoolController(address controller) external;

  function disapprovePoolController(address controller) external;

  function deployPool(bytes32 implementationID, bytes32 controllerSalt) external returns (address);

/* ========== Views ========== */

  function proxyManager() external view returns (IDelegateCallProxyManager);

  function isApprovedController(address) external view returns (bool);

  function getPoolImplementationID(address) external view returns (bytes32);

  function isRecognizedPool(address pool) external view returns (bool);

  function computePoolAddress(
    bytes32 implementationID,
    address controller,
    bytes32 controllerSalt
  ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./IBisharesUniswapV2Oracle.sol";

interface IPoolInitializer {

/* ========== Mutative ========== */

  function initialize(
    address poolAddress,
    address[] calldata tokens,
    uint256[] calldata amounts,
    IBisharesUniswapV2Oracle oracle
  ) external;

  function finish() external;

  function claimTokens() external;

  function claimTokens(address account) external;

  function claimTokens(address[] calldata accounts) external;

  function contributeTokens(
    address token,
    uint256 amountIn,
    uint256 minimumCredit
  ) external returns (uint256);

  function contributeTokens(
    address[] calldata tokens,
    uint256[] calldata amountsIn,
    uint256 minimumCredit
  ) external returns (uint256);

  function updatePrices() external;

/* ========== Views ========== */

  function isFinished() external view returns (bool);

  function getTotalCredit() external view returns (uint256);

  function getCreditOf(address account) external view returns (uint256);

  function getDesiredTokens() external view returns (address[] memory);

  function getDesiredAmount(address token) external view returns (uint256);

  function getDesiredAmounts(address[] calldata tokens) external view returns (uint256[] memory);

  function getCreditForTokens(address token, uint256 amountIn) external view returns (uint144);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


interface IUnboundTokenSeller {

/* ========== Mutative ========== */

  function initialize(address pool, uint8 premiumPercent) external;

  function handleUnbindToken(address token, uint256 amount) external;

  function setPremiumPercent(uint8 premiumPercent) external;

  function executeSwapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    address[] calldata path
  ) external returns (uint256);

  function executeSwapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    address[] calldata path
  ) external returns (uint256);

  function swapExactTokensForTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256);

  function swapTokensForExactTokens(
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 maxAmountIn
  ) external returns (uint256);

/* ========== Views ========== */

  function getPremiumPercent() external view returns (uint8);

  function calcInGivenOut(
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) external view returns (uint256);

  function calcOutGivenIn(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/Babylonian.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.

Subject to the GPL-3.0 license
*************************************************************************************************/


// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = (y + 1) / 2;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/************************************************************************************************
From https://github.com/Uniswap/uniswap-lib/blob/master/contracts/libraries/FixedPoint.sol

Copied from the github repository at commit hash 9642a0705fdaf36b477354a4167a8cd765250860.

Modifications:
- Removed `sqrt` function

Subject to the GPL-3.0 license
*************************************************************************************************/


// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint private constant Q112 = uint(1) << RESOLUTION;
  uint private constant Q224 = Q112 << RESOLUTION;

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112(self._x / uint224(x));
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
    uint z;
    require(
      y == 0 || (z = uint(self._x) * y) / y == uint(self._x),
      "FixedPoint: MULTIPLICATION_OVERFLOW"
    );
    return uq144x112(z);
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // take the reciprocal of a UQ112x112
  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uq112x112(uint224(Q224 / self._x));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Interfaces ========== */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* ========== External Libraries ========== */
import "./PriceLibrary.sol";
import "./FixedPoint.sol";

/* ========== Internal Libraries ========== */
import "./Babylonian.sol";


library MCapSqrtLibrary {
  using Babylonian for uint256;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;

  /**
   * @dev Compute the average market cap of a token by extrapolating the
   * average price to the token's total supply.
   * @param token Address of the ERC20 token
   * @param averagePrice Two-way average price of the token (token-weth & weth-token).
   * @return Extrapolated average market cap.
   */
  function computeAverageMarketCap(
    address token,
    PriceLibrary.TwoWayAveragePrice memory averagePrice
  ) internal view returns (uint144) {
    uint256 totalSupply = IERC20(token).totalSupply();
    return averagePrice.computeAverageEthForTokens(totalSupply);
  }

  /**
   * @dev Calculate the square roots of the market caps of the indexed tokens.
   * @param tokens Array of ERC20 tokens to get the market cap square roots for.
   * @param averagePrices Array of two-way average prices of each token.
   *  - Must be in the same order as the tokens array.
   * @return sqrts Array of market cap square roots for the provided tokens.
   */
  function computeMarketCapSqrts(
    address[] memory tokens,
    PriceLibrary.TwoWayAveragePrice[] memory averagePrices
  ) internal view returns (uint112[] memory sqrts) {
    uint256 len = tokens.length;
    sqrts = new uint112[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 marketCap = computeAverageMarketCap(tokens[i], averagePrices[i]);
      sqrts[i] = uint112(marketCap.sqrt());
    }
  }

    /**
   * @dev Calculate the weights of the provided tokens.
   * The weight of a token is the square root of its market cap
   * divided by the sum of market cap square roots.
   * @param tokens Array of ERC20 tokens to weigh
   * @param averagePrices Array of average prices from UniSwap for the tokens array.
   * @return weights Array of token weights represented as fractions of the sum of roots.
   */
  function computeTokenWeights(
    address[] memory tokens,
    PriceLibrary.TwoWayAveragePrice[] memory averagePrices
  ) internal view returns (FixedPoint.uq112x112[] memory weights) {
    // Get the square roots of token market caps
    uint112[] memory sqrts = computeMarketCapSqrts(tokens, averagePrices);
    uint112 rootSum;
    uint256 len = sqrts.length;
    // Calculate the sum of square roots
    // Will not overflow - would need 72057594037927940 tokens in the index
    // before the sum of sqrts of a uint112 could overflow
    for (uint256 i = 0; i < len; i++) rootSum += sqrts[i];
    // Initialize the array of weights
    weights = new FixedPoint.uq112x112[](len);
    // Calculate the token weights as fractions of the root sum.
    for (uint256 i = 0; i < len; i++) {
      weights[i] = FixedPoint.fraction(sqrts[i], rootSum);
    }
  }

  function computeTokenWeights(
    FixedPoint.uq112x112[] memory weights
  ) internal pure returns (FixedPoint.uq112x112[] memory) {
    uint256 len = weights.length;
    uint112 weightsSum;
    for (uint256 i = 0; i < len; i++) weightsSum += uint112(weights[i]._x);
    for (uint256 i = 0; i < len; i++) weights[i] = FixedPoint.fraction(uint112(weights[i]._x), weightsSum);
    return weights;
  }

  /**
   * @dev Computes the weighted balance of a token relative to the
   * total value of the index. Multiplies the total value by the weight,
   * then multiplies by the reciprocal of the price (equivalent to dividing
   * by price, but without rounding the price).
   * @param totalValue Total value of the index in the stablecoin
   * @param weight Fraction of the total value that should be held in the token.
   * @param averagePrice Two-way average price of the token.
   * @return weightedBalance Desired balance of the token based on the weighted value.
   */
  function computeWeightedBalance(
    uint144 totalValue,
    FixedPoint.uq112x112 memory weight,
    PriceLibrary.TwoWayAveragePrice memory averagePrice
  ) internal pure returns (uint144 weightedBalance) {
    uint144 desiredWethValue = weight.mul(totalValue).decode144();
    // Multiply by reciprocal to avoid rounding in intermediary steps.
    return averagePrice.computeAverageTokensForEth(desiredWethValue);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";


library PriceLibrary {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

/* ========= Structs ========= */

  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  /**
   * @dev Average prices for a token in terms of weth and weth in terms of the token.
   *
   * Note: The average weth price is not equivalent to the reciprocal of the average
   * token price. See the UniSwap whitepaper for more info.
   */
  struct TwoWayAveragePrice {
    uint224 priceAverage;
    uint224 ethPriceAverage;
  }

/* ========= View Functions ========= */

  function pairInitialized(
    address uniswapFactory,
    address token,
    address weth
  )
    internal
    view
    returns (bool)
  {
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token, weth);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
    return reserve0 != 0 && reserve1 != 0;
  }

  function observePrice(
    address uniswapFactory,
    address tokenIn,
    address quoteToken
  )
    internal
    view
    returns (uint32 /* timestamp */, uint224 /* priceCumulativeLast */)
  {
    (address token0, address token1) = UniswapV2Library.sortTokens(tokenIn, quoteToken);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    if (token0 == tokenIn) {
      (uint256 price0Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
      return (blockTimestamp, uint224(price0Cumulative));
    } else {
      (uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
      return (blockTimestamp, uint224(price1Cumulative));
    }
  }

  /**
   * @dev Query the current cumulative price of a token in terms of weth
   * and the current cumulative price of weth in terms of the token.
   */
  function observeTwoWayPrice(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (PriceObservation memory) {
    (address token0, address token1) = UniswapV2Library.sortTokens(token, weth);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    // Get the sorted token prices
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    // Check which token is weth and which is the token,
    // then build the price observation.
    if (token0 == token) {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price0Cumulative),
        ethPriceCumulativeLast: uint224(price1Cumulative)
      });
    } else {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price1Cumulative),
        ethPriceCumulativeLast: uint224(price0Cumulative)
      });
    }
  }

/* ========= Utility Functions ========= */

  /**
   * @dev Computes the average price of a token in terms of weth
   * and the average price of weth in terms of a token using two
   * price observations.
   */
  function computeTwoWayAveragePrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (TwoWayAveragePrice memory) {
    uint32 timeElapsed = uint32(observation2.timestamp - observation1.timestamp);
    FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      timeElapsed
    );
    FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      timeElapsed
    );
    return TwoWayAveragePrice({
      priceAverage: priceAverage._x,
      ethPriceAverage: ethPriceAverage._x
    });
  }

  function computeAveragePrice(
    uint32 timestampStart,
    uint224 priceCumulativeStart,
    uint32 timestampEnd,
    uint224 priceCumulativeEnd
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      priceCumulativeStart,
      priceCumulativeEnd,
      uint32(timestampEnd - timestampStart)
    );
  }

  /**
   * @dev Computes the average price of the token the price observations
   * are for in terms of weth.
   */
  function computeAverageTokenPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  /**
   * @dev Computes the average price of weth in terms of the token
   * the price observations are for.
   */
  function computeAverageEthPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  /**
   * @dev Compute the average value in weth of `tokenAmount` of the
   * token that the average price values are for.
   */
  function computeAverageEthForTokens(
    TwoWayAveragePrice memory prices,
    uint256 tokenAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.priceAverage).mul(tokenAmount).decode144();
  }

  /**
   * @dev Compute the average value of `wethAmount` weth in terms of
   * the token that the average price values are for.
   */
  function computeAverageTokensForEth(
    TwoWayAveragePrice memory prices,
    uint256 wethAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.ethPriceAverage).mul(wethAmount).decode144();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";

/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 87edfdcaf49ccc52591502993db4c8c08ea9eec0.

Subject to the GPL-3.0 license
*************************************************************************************************/

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

library UniswapV2Library {
  using SafeMath for uint256;
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal view returns (address pair) {
    IUniswapFactory _factory = IUniswapFactory(factory);
    pair = _factory.getPair(token0, token1);
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/* ==========  Internal Interfaces  ========== */
import "../interfaces/IUniswapV2Pair.sol";

/* ==========  Internal Libraries  ========== */
import "./FixedPoint.sol";


/************************************************************************************************
Originally from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2OracleLibrary.sol

This source code has been modified from the original, which was copied from the github repository
at commit hash 6d03bede0a97c72323fa1c379ed3fdf7231d0b26.

Subject to the GPL-3.0 license
*************************************************************************************************/


// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative prices using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
      // counterfactual
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  // only gets the first price
  function currentCumulativePrice0(address pair)
    internal
    view
    returns (uint256 price0Cumulative, uint32 blockTimestamp)
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
    }
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  // only gets the second price
  function currentCumulativePrice1(address pair)
    internal
    view
    returns (uint256 price1Cumulative, uint32 blockTimestamp)
  {
    blockTimestamp = currentBlockTimestamp();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      // addition overflow is desired
      // counterfactual
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function computeAveragePrice(
    uint224 priceCumulativeStart,
    uint224 priceCumulativeEnd,
    uint32 timeElapsed
  ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
    // overflow is desired.
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./ManyToOneImplementationHolder.sol";
import "./DelegateCallProxyManyToOne.sol";
import "./DelegateCallProxyOneToOne.sol";


/**
 * @dev Because we use the code hashes of the proxy contracts for proxy address
 * derivation, it is important that other packages have access to the correct
 * values when they import the salt library.
 */
library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = keccak256(type(DelegateCallProxyOneToOne).creationCode);
  bytes32 internal constant MANY_TO_ONE_CODEHASH = keccak256(type(DelegateCallProxyManyToOne).creationCode);
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = keccak256(type(ManyToOneImplementationHolder).creationCode);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Proxy contract which uses an implementation address shared with many
 * other proxies.
 *
 * An implementation holder contract stores the upgradeable implementation address.
 * When the proxy is called, it queries the implementation address from the holder
 * contract and delegatecalls the returned address, forwarding the received calldata
 * and ether.
 *
 * Note: This contract does not verify that the implementation
 * address is a valid delegation target. The manager must perform
 * this safety check before updating the implementation on the holder.
 */
contract DelegateCallProxyManyToOne is Proxy {
/* ==========  Constants  ========== */

  // Address that stores the implementation address.
  address internal immutable _implementationHolder;

/* ==========  Constructor  ========== */

  constructor() public {
    // Calls the sender rather than receiving the address in the constructor
    // arguments so that the address is computable using create2.
    _implementationHolder = ProxyDeployer(msg.sender).getImplementationHolder();
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Queries the implementation address from the implementation holder.
   */
  function _implementation() internal override view returns (address) {
    // Queries the implementation address from the implementation holder.
    (bool success, bytes memory data) = _implementationHolder.staticcall("");
    require(success, string(data));
    address implementation = abi.decode((data), (address));
    require(implementation != address(0), "ERR_NULL_IMPLEMENTATION");
    return implementation;
  }
}

interface ProxyDeployer {
  function getImplementationHolder() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";


/**
 * @dev Upgradeable delegatecall proxy for a single contract.
 *
 * This proxy stores an implementation address which can be upgraded by the proxy manager.
 *
 * To upgrade the implementation, the manager calls the proxy with the abi encoded implementation address.
 *
 * If any other account calls the proxy, it will delegatecall the implementation address with the received
 * calldata and ether. If the call succeeds, it will return with the received returndata.
 * If it reverts, it will revert with the received revert data.
 *
 * Note: The storage slot for the implementation address is:
 * `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`
 * This slot must not be used by the implementation contract.
 *
 * Note: This contract does not verify that the implementation address is a valid delegation target.
 * The manager must perform this safety check.
 */
contract DelegateCallProxyOneToOne is Proxy {
/* ==========  Constants  ========== */
  address internal immutable _manager;

/* ==========  Constructor  ========== */
  constructor() public {
    _manager = msg.sender ;
  }

/* ==========  Internal Overrides  ========== */

  /**
   * @dev Reads the implementation address from storage.
   */
  function _implementation() internal override view returns (address) {
    address implementation;
    assembly {
      implementation := sload(
        // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
        0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a
      )
    }
    return implementation;
  }

  /**
    * @dev Hook that is called before falling back to the implementation.
    *
    * Checks if the call is from the owner.
    * If it is, reads the abi-encoded implementation address from calldata and stores
    * it at the slot `bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)`,
    * then returns with no data.
    * If it is not, continues execution with the fallback function.
    */
  function _beforeFallback() internal override {
    if (msg.sender != _manager) {
      super._beforeFallback();
    } else {
      assembly {
        sstore(
          // bytes32(uint256(keccak256("IMPLEMENTATION_ADDRESS")) + 1)
          0x913bd12b32b36f36cedaeb6e043912bceb97022755958701789d3108d33a045a,
          calldataload(0)
        )
        return(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


/**
 * @dev The ManyToOneImplementationHolder stores an upgradeable implementation address
 * in storage, which many-to-one proxies query at execution time to determine which
 * contract to delegate to.
 *
 * The manager can upgrade the implementation address by calling the holder with the
 * abi-encoded address as calldata. If any other account calls the implementation holder,
 * it will return the implementation address.
 *
 * This pattern was inspired by the DharmaUpgradeBeacon from 0age
 * https://github.com/dharma-eng/dharma-smart-wallet/blob/master/contracts/upgradeability/smart-wallet/DharmaUpgradeBeacon.sol
 */
contract ManyToOneImplementationHolder {
/* ---  Storage  --- */
  address internal immutable _manager;
  address internal _implementation;

/* ---  Constructor  --- */
  constructor() public {
    _manager = msg.sender;
  }

  /**
   * @dev Fallback function for the contract.
   *
   * Used by proxies to read the implementation address and used
   * by the proxy manager to set the implementation address.
   *
   * If called by the owner, reads the implementation address from
   * calldata (must be abi-encoded) and stores it to the first slot.
   *
   * Otherwise, returns the stored implementation address.
   */
  fallback() external payable {
    if (msg.sender != _manager) {
      assembly {
        mstore(0, sload(0))
        return(0, 32)
      }
    }
    assembly { sstore(0, calldataload(0)) }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/* ---  External Libraries  --- */
import "@openzeppelin/contracts/utils/Create2.sol";

/* ---  Proxy Contracts  --- */
import "./CodeHashes.sol";


/**
 * @dev Library for computing create2 salts and addresses for proxies
 * deployed by `DelegateCallProxyManager`.
 *
 * Because the proxy factory is meant to be used by multiple contracts,
 * we use a salt derivation pattern that includes the address of the
 * contract that requested the proxy deployment, a salt provided by that
 * contract and the implementation ID used (for many-to-one proxies only).
 */
library SaltyLib {
/* ---  Salt Derivation  --- */

  /**
   * @dev Derives the create2 salt for a many-to-one proxy.
   *
   * Many different contracts in the Bishares framework may use the
   * same implementation contract, and they all use the same init
   * code, so we derive the actual create2 salt from a combination
   * of the implementation ID, the address of the account requesting
   * deployment and the user-supplied salt.
   *
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveManyToOneSalt(
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        originator,
        implementationID,
        suppliedSalt
      )
    );
  }

  /**
   * @dev Derives the create2 salt for a one-to-one proxy.
   *
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function deriveOneToOneSalt(
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(originator, suppliedSalt));
  }

/* ---  Address Derivation  --- */

  /**
   * @dev Computes the create2 address for a one-to-one proxy deployed
   * by `deployer` (the factory) when requested by `originator` using
   * `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param suppliedSalt Salt provided by the account requesting deployment.
   */
  function computeProxyAddressOneToOne(
    address deployer,
    address originator,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveOneToOneSalt(originator, suppliedSalt);
    return Create2.computeAddress(salt, CodeHashes.ONE_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address for a many-to-one proxy for the
   * implementation `implementationID` deployed by `deployer` (the factory)
   * when requested by `originator` using `suppliedSalt`.
   *
   * @param deployer Address of the proxy factory.
   * @param originator Address of the account requesting deployment.
   * @param implementationID The identifier for the contract implementation.
   * @param suppliedSalt Salt provided by the account requesting deployment.
  */
  function computeProxyAddressManyToOne(
    address deployer,
    address originator,
    bytes32 implementationID,
    bytes32 suppliedSalt
  )
    internal
    pure
    returns (address)
  {
    bytes32 salt = deriveManyToOneSalt(
      originator,
      implementationID,
      suppliedSalt
    );
    return Create2.computeAddress(salt, CodeHashes.MANY_TO_ONE_CODEHASH, deployer);
  }

  /**
   * @dev Computes the create2 address of the implementation holder
   * for `implementationID`.
   *
   * @param deployer Address of the proxy factory.
   * @param implementationID The identifier for the contract implementation.
  */
  function computeHolderAddressManyToOne(
    address deployer,
    bytes32 implementationID
  )
    internal
    pure
    returns (address)
  {
    return Create2.computeAddress(
      implementationID,
      CodeHashes.IMPLEMENTATION_HOLDER_CODEHASH,
      deployer
    );
  }
}

