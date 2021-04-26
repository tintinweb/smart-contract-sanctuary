// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


contract ControllerConstants {
  // Minimum number of tokens in an index.
  uint256 public constant MIN_INDEX_SIZE = 2;

  // Maximum number of tokens in an index.
  uint256 public constant MAX_INDEX_SIZE = 10;

  // Minimum balance for a token (only applied at initialization)
  uint256 public constant MIN_BALANCE = 1e6;

  // Identifier for the pool initializer implementation on the proxy manager.
  bytes32 public constant INITIALIZER_IMPLEMENTATION_ID = keccak256("SigmaPoolInitializerV1.sol");

  // Identifier for the unbound token seller implementation on the proxy manager.
  bytes32 public constant SELLER_IMPLEMENTATION_ID = keccak256("SigmaUnboundTokenSellerV1.sol");

  // Identifier for the index pool implementation on the proxy manager.
  bytes32 public constant POOL_IMPLEMENTATION_ID = keccak256("SigmaIndexPoolV1.sol");

  // Time between reweigh/reindex calls.
  uint256 public constant POOL_REWEIGH_DELAY = 1 weeks;

  // The number of reweighs which occur before a pool is re-indexed.
  uint8 public constant REWEIGHS_BEFORE_REINDEX = 3;

  // TWAP parameters for assessing current price
  uint32 public constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 public constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== Internal Libraries ========== */
import "../lib/ScoreLibrary.sol";

/* ========== Internal Interfaces ========== */
import "../interfaces/ICirculatingMarketCapOracle.sol";
import "../interfaces/IScoringStrategy.sol";

/* ========== Internal Inheritance ========== */
import "../OwnableProxy.sol";


/**
 * @title ScoredTokenLists
 * @author d1ll0n
 *
 * @dev This contract stores token lists sorted and filtered using arbitrary scoring strategies.
 *
 * Each token list contains an array of tokens, a scoring strategy address, minimum and maximum
 * scores for the list, and a mapping for which tokens are included.
 *
 * A scoring strategy is a smart contract which implements the `getTokenScores`, which scores
 * tokens using an arbitrary methodology.
 *
 * Token lists are sorted in descending order by the scores returned by the list's scoring strategy,
 * and filtered according to the minimum/maximum scores.
 *
 * The contract owner can create a new token list with a metadata hash used to query
 * additional details about its purpose and inclusion criteria from IPFS.
 *
 * The owner can add and remove tokens from the lists.
 */
contract ScoredTokenLists is OwnableProxy {
  using ScoreLibrary for address[];
  using ScoreLibrary for uint256[];
  using ScoreLibrary for uint256;

/* ==========  Constants  ========== */
  // Maximum number of tokens in a token list
  uint256 public constant MAX_LIST_TOKENS = 25;

  // Uniswap TWAP oracle
  IIndexedUniswapV2Oracle public immutable uniswapOracle;

/* ==========  Events  ========== */

  /** @dev Emitted when a new token list is created. */
  event TokenListAdded(
    uint256 listID,
    bytes32 metadataHash,
    address scoringStrategy,
    uint128 minimumScore,
    uint128 maximumScore
  );

  /** @dev Emitted when a token list is sorted and filtered. */
  event TokenListSorted(uint256 listID);

  /** @dev Emitted when a token is added to a list. */
  event TokenAdded(address token, uint256 listID);

  /** @dev Emitted when a token is removed from a list. */
  event TokenRemoved(address token, uint256 listID);

/* ==========  Structs  ========== */

  /**
   * @dev Token list storage structure.
   * @param minimumScore Minimum market cap for included tokens
   * @param maximumScore Maximum market cap for included tokens
   * @param scoringStrategy Address of the scoring strategy contract used
   * @param tokens Array of included tokens
   * @param isIncludedToken Mapping of included tokens
   */
  struct TokenList {
    uint128 minimumScore;
    uint128 maximumScore;
    address scoringStrategy;
    address[] tokens;
    mapping(address => bool) isIncludedToken;
  }

/* ==========  Storage  ========== */

  // Chainlink or other circulating market cap oracle
  ICirculatingMarketCapOracle public circulatingMarketCapOracle;

  // Number of categories that exist.
  uint256 public tokenListCount;
  mapping(uint256 => TokenList) internal _lists;

/* ========== Modifiers ========== */

  modifier validTokenList(uint256 listID) {
    require(listID <= tokenListCount && listID > 0, "ERR_LIST_ID");
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related contracts.
   */
  constructor(IIndexedUniswapV2Oracle _oracle) public OwnableProxy() {
    uniswapOracle = _oracle;
  }

/* ==========  Configuration  ========== */

  /**
   * @dev Initialize the categories with the owner address.
   * This sets up the contract which is deployed as a singleton proxy.
   */
  function initialize() public virtual {
    _initializeOwnership();
  }

/* ==========  Permissioned List Management  ========== */

  /**
   * @dev Creates a new token list.
   *
   * @param metadataHash Hash of metadata about the token list which can
   * be distributed on IPFS.
   */
  function createTokenList(
    bytes32 metadataHash,
    address scoringStrategy,
    uint128 minimumScore,
    uint128 maximumScore
  )
    external
    onlyOwner
  {
    require(minimumScore > 0, "ERR_NULL_MIN_CAP");
    require(maximumScore > minimumScore, "ERR_MAX_CAP");
    require(scoringStrategy != address(0), "ERR_NULL_ADDRESS");
    uint256 listID = ++tokenListCount;
    TokenList storage list = _lists[listID];
    list.scoringStrategy = scoringStrategy;
    list.minimumScore = minimumScore;
    list.maximumScore = maximumScore;
    emit TokenListAdded(listID, metadataHash, scoringStrategy, minimumScore, maximumScore);
  }

  /**
   * @dev Adds a new token to a token list.
   *
   * @param listID Token list identifier.
   * @param token Token to add to the list.
   */
  function addToken(uint256 listID, address token) external onlyOwner validTokenList(listID) {
    TokenList storage list = _lists[listID];
    require(
      list.tokens.length < MAX_LIST_TOKENS,
      "ERR_MAX_LIST_TOKENS"
    );
    _addToken(list, token);
    uniswapOracle.updatePrice(token);
    emit TokenAdded(token, listID);
  }

  /**
   * @dev Add tokens to a token list.
   *
   * @param listID Token list identifier.
   * @param tokens Array of tokens to add to the list.
   */
  function addTokens(uint256 listID, address[] calldata tokens)
    external
    onlyOwner
    validTokenList(listID)
  {
    TokenList storage list = _lists[listID];
    require(
      list.tokens.length + tokens.length <= MAX_LIST_TOKENS,
      "ERR_MAX_LIST_TOKENS"
    );
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      _addToken(list, token);
      emit TokenAdded(token, listID);
    }
    uniswapOracle.updatePrices(tokens);
  }

  /**
   * @dev Remove token from a token list.
   *
   * @param listID Token list identifier.
   * @param token Token to remove from the list.
   */
  function removeToken(uint256 listID, address token) external onlyOwner validTokenList(listID) {
    TokenList storage list = _lists[listID];
    uint256 i = 0;
    uint256 len = list.tokens.length;
    require(len > 0, "ERR_EMPTY_LIST");
    require(list.isIncludedToken[token], "ERR_TOKEN_NOT_BOUND");
    list.isIncludedToken[token] = false;
    for (; i < len; i++) {
      if (list.tokens[i] == token) {
        uint256 last = len - 1;
        if (i != last) {
          address lastToken = list.tokens[last];
          list.tokens[i] = lastToken;
        }
        list.tokens.pop();
        emit TokenRemoved(token, listID);
        return;
      }
    }
  }

/* ==========  Public List Updates  ========== */

  /**
   * @dev Updates the prices on the Uniswap oracle for all the tokens in a token list.
   */
  function updateTokenPrices(uint256 listID)
    external
    validTokenList(listID)
    returns (bool[] memory pricesUpdated)
  {
    pricesUpdated = uniswapOracle.updatePrices(_lists[listID].tokens);
  }

  /**
   * @dev Returns the tokens and scores in the token list for `listID` after
   * sorting and filtering the tokens according to the list's configuration.
   */
  function sortAndFilterTokens(uint256 listID)
    external
    validTokenList(listID)
  {
    TokenList storage list = _lists[listID];
    address[] memory tokens = list.tokens;
    uint256[] memory marketCaps = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    address[] memory removedTokens = tokens.sortAndFilterReturnRemoved(
      marketCaps,
      list.minimumScore,
      list.maximumScore
    );
    _lists[listID].tokens = tokens;
    for (uint256 i = 0; i < removedTokens.length; i++) {
      address token = removedTokens[i];
      list.isIncludedToken[token] = false;
      emit TokenRemoved(token, listID);
    }
  }


/* ==========  Score Queries  ========== */

  /**
   * @dev Returns the tokens and market caps for `catego
   */
  function getSortedAndFilteredTokensAndScores(uint256 listID)
    public
    view
    validTokenList(listID)
    returns (
      address[] memory tokens,
      uint256[] memory scores
    )
  {
    TokenList storage list = _lists[listID];
    tokens = list.tokens;
    scores = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    tokens.sortAndFilter(
      scores,
      list.minimumScore,
      list.maximumScore
    );
  }

/* ==========  Token List Queries  ========== */

  /**
   * @dev Returns boolean stating whether `token` is a member of the list `listID`.
   */
  function isTokenInlist(uint256 listID, address token)
    external
    view
    validTokenList(listID)
    returns (bool)
  {
    return _lists[listID].isIncludedToken[token];
  }

  /**
   * @dev Returns the array of tokens in a list.
   */
  function getTokenList(uint256 listID)
    external
    view
    validTokenList(listID)
    returns (address[] memory tokens)
  {
    tokens = _lists[listID].tokens;
  }

  /**
   * @dev Returns the top `count` tokens and market caps in the list for `listID`
   * after sorting and filtering the tokens according to the list's configuration.
   */
  function getTopTokensAndScores(uint256 listID, uint256 count)
    public
    view
    validTokenList(listID)
    returns (
      address[] memory tokens,
      uint256[] memory scores
    )
  {
    (tokens, scores) = getSortedAndFilteredTokensAndScores(listID);
    require(count <= tokens.length, "ERR_LIST_SIZE");
    assembly {
      mstore(tokens, count)
      mstore(scores, count)
    }
  }

  /**
   * @dev Query the configuration values for a token list.
   *
   * @param listID Identifier for the token list
   * @return scoringStrategy Address of the scoring strategy contract used
   * @return minimumScore Minimum market cap for an included token
   * @return maximumScore Maximum market cap for an included token
   */
  function getTokenListConfig(uint256 listID)
    external
    view
    validTokenList(listID)
    returns (
      address scoringStrategy,
      uint128 minimumScore,
      uint128 maximumScore
    )
  {
    TokenList storage list = _lists[listID];
    scoringStrategy = list.scoringStrategy;
    minimumScore = list.minimumScore;
    maximumScore = list.maximumScore;
  }

  function getTokenScores(uint256 listID, address[] memory tokens)
    public
    view
    validTokenList(listID)
    returns (uint256[] memory scores)
  {
    scores = IScoringStrategy(_lists[listID].scoringStrategy).getTokenScores(tokens);
  }

/* ==========  Token List Utility Functions  ========== */

  /**
   * @dev Adds a new token to a list.
   */
  function _addToken(TokenList storage list, address token) internal {
    require(!list.isIncludedToken[token], "ERR_TOKEN_BOUND");
    list.isIncludedToken[token] = true;
    list.tokens.push(token);
  }
}

interface IIndexedUniswapV2Oracle {

  function updatePrice(address token) external returns (bool);

  function updatePrices(address[] calldata tokens) external returns (bool[] memory);

  function computeAverageEthForTokens(
    address[] calldata tokens,
    uint256[] calldata tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory);

  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256);

  function computeAverageTokensForEth(
    address[] calldata tokens,
    uint256[] calldata ethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256[] memory);

  function computeAverageTokensForEth(
    address token,
    uint256 ethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ========== External Libraries ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";


library ScoreLibrary {
  using SafeMath for uint256;

  // Default total weight for a pool.
  uint256 internal constant WEIGHT_MULTIPLIER = 25e18;

  function computeProportionalAmounts(uint256 total, uint256[] memory scores)
    internal
    pure
    returns(uint256[] memory values)
  {
    uint256 sum;
    uint256 len = scores.length;
    values = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      sum = sum.add(scores[i]);
    }
    uint256 denormalizedSum = sum * 1e18;
    uint256 denormalizedTotal = total * 1e18;
    for (uint256 i = 0; i < len; i++) {
      values[i] = scores[i].mul(denormalizedTotal).div(denormalizedSum);
    }
  }

  function computeDenormalizedWeights(uint256[] memory values)
    internal
    pure
    returns (uint96[] memory weights)
  {
    uint256 sum;
    uint256 len = values.length;
    weights = new uint96[](len);
    for (uint256 i = 0; i < len; i++) {
      sum = sum.add(values[i]);
    }
    for (uint256 i = 0; i < len; i++) {
      weights[i] = _safeUint96(values[i].mul(WEIGHT_MULTIPLIER).div(sum));
    }
  }

  /**
   * @dev Given a list of tokens and their scores, sort by scores
   * in descending order, and filter out the tokens with scores that
   * are not within the min/max bounds provided.
   */
  function sortAndFilter(
    address[] memory tokens,
    uint256[] memory scores,
    uint256 minimumScore,
    uint256 maximumScore
  ) internal pure {
    uint256 len = tokens.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 cap = scores[i];
      address token = tokens[i];
      if (cap > maximumScore || cap < minimumScore) {
        token = tokens[--len];
        cap = scores[len];
        scores[i] = cap;
        tokens[i] = token;
        i--;
        continue;
      }
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < cap) {
        scores[j + 1] = scores[j];
        tokens[j + 1] = tokens[j];
        j--;
      }
      scores[j + 1] = cap;
      tokens[j + 1] = token;
    }
    if (len != tokens.length) {
      assembly {
        mstore(tokens, len)
        mstore(scores, len)
      }
    }
  }

  /**
   * @dev Given a list of tokens and their scores, sort by scores
   * in descending order, and filter out the tokens with scores that
   * are not within the min/max bounds provided.
   * This function also returns the list of removed tokens.
   */
  function sortAndFilterReturnRemoved(
    address[] memory tokens,
    uint256[] memory scores,
    uint256 minimumScore,
    uint256 maximumScore
  ) internal pure returns (address[] memory removed) {
    uint256 removedIndex = 0;
    uint256 len = tokens.length;
    removed = new address[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 cap = scores[i];
      address token = tokens[i];
      if (cap > maximumScore || cap < minimumScore) {
        removed[removedIndex++] = token;
        token = tokens[--len];
        cap = scores[len];
        scores[i] = cap;
        tokens[i] = token;
        i--;
        continue;
      }
      uint256 j = i - 1;
      while (int(j) >= 0 && scores[j] < cap) {
        scores[j + 1] = scores[j];
        tokens[j + 1] = tokens[j];
        j--;
      }
      scores[j + 1] = cap;
      tokens[j + 1] = token;
    }
    if (len != tokens.length) {
      assembly {
        mstore(tokens, len)
        mstore(scores, len)
        mstore(removed, removedIndex)
      }
    }
  }

  function _safeUint96(uint256 x) internal pure returns (uint96 y) {
    y = uint96(x);
    require(y == x, "ERR_MAX_UINT96");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


interface ICirculatingMarketCapOracle {
  function getCirculatingMarketCap(address) external view returns (uint256);

  function getCirculatingMarketCaps(address[] calldata) external view returns (uint256[] memory);

  function updateCirculatingMarketCaps(address[] calldata) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IScoringStrategy {
  function getTokenScores(address[] calldata tokens) external view returns (uint256[] memory scores);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

/* ========== External Interfaces ========== */
import "@indexed-finance/proxies/contracts/interfaces/IDelegateCallProxyManager.sol";

/* ========== External Libraries ========== */
import "@indexed-finance/proxies/contracts/SaltyLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/* ========== Internal Interfaces ========== */
import "../interfaces/IIndexPool.sol";
import "../interfaces/IPoolFactory.sol";
import "../interfaces/IPoolInitializer.sol";
import "../interfaces/IUnboundTokenSeller.sol";

/* ========== Internal Inheritance ========== */
import "./ScoredTokenLists.sol";
import "./ControllerConstants.sol";


/**
 * @title SigmaControllerV1
 * @author d1ll0n
 * @dev This contract is used to deploy and manage index pools.
 * It implements the methodology for rebalancing and asset selection, as well as other
 * controls such as pausing public swaps and managing fee configuration.
 *
 * ===== Pool Configuration =====
 * When an index pool is deployed, it is assigned a token list and a target size.
 *
 * The token list is the set of tokens and configuration used for selecting and weighting
 * assets, which is detailed in the documentation for the ScoredTokenLists contract.
 *
 * The size is the target number of underlying assets held by the pool, it is used to determine
 * which assets the pool will hold.
 *
 * The list's scoring strategy is used to assign weights.
 *
 * ===== Asset Selection =====
 * When the pool is deployed and when it is re-indexed, the top assets from the pool's token list
 * are selected using the index size. They are selected after sorting the token list in descending
 * order by the scores of tokens.
 *
 * ===== Rebalancing =====
 * Every week, pools are either re-weighed or re-indexed.
 * They are re-indexed once for every three re-weighs.
 * The contract owner can also force a reindex out of the normal schedule.
 *
 * Re-indexing involves re-selecting the top tokens from the pool's token list using the pool's index
 * size, assigning target weights and setting balance targets for new tokens.
 *
 * Re-weighing involves assigning target weights to only the tokens already included in the pool.
 *
 * ===== Toggling Swaps =====
 * The contract owner can set a circuitBreaker address which is allowed to toggle public swaps on index pools.
 * The contract owner also has the ability to toggle swaps.
 * 
 * ===== Fees =====
 * The contract owner can change the swap fee on index pools, and can change the premium paid on swaps in the
 * unbound token seller contracts.
 */
contract SigmaControllerV1 is ScoredTokenLists, ControllerConstants {
  using SafeMath for uint256;

/* ==========  Constants  ========== */
  // Pool factory contract
  IPoolFactory public immutable poolFactory;

  // Proxy manager & factory
  IDelegateCallProxyManager public immutable proxyManager;

  // Governance address
  address public immutable governance;

/* ==========  Events  ========== */

  /** @dev Emitted when a pool is initialized and made public. */
  event PoolInitialized(
    address pool,
    address unboundTokenSeller,
    uint256 listID,
    uint256 indexSize
  );

  /** @dev Emitted when a pool and its initializer are deployed. */
  event NewPoolInitializer(
    address pool,
    address initializer,
    uint256 listID,
    uint256 indexSize
  );

  /** @dev Emitted when a pool is reweighed. */
  event PoolReweighed(address pool);

  /** @dev Emitted when a pool is reindexed. */
  event PoolReindexed(address pool);

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
   * `reweighIndex` is intended to overflow, `listID` will never
   * reach 2**16, `indexSize` is capped at 10 and it is unlikely that
   * this protocol will be in use in the year 292277026596 (unix time
   * for 2**64 - 1).
   *
   * @param initialized Whether the pool has been initialized with the
   * starting balances.
   * @param listID Token list identifier for the pool.
   * @param indexSize Number of tokens the pool should hold.
   * @param reweighIndex Number of times the pool has either re-weighed or re-indexed
   * @param lastReweigh Timestamp of last pool re-weigh or re-index
   */
  struct IndexPoolMeta {
    bool initialized;
    uint16 listID;
    uint8 indexSize;
    uint8 reweighIndex;
    uint64 lastReweigh;
  }

/* ==========  Storage  ========== */

  // Default slippage rate for token seller contracts.
  uint8 public defaultSellerPremium;

  // Metadata about index pools
  mapping(address => IndexPoolMeta) public indexPoolMetadata;

  // Address able to halt swaps
  address public circuitBreaker;

  // Exit fee recipient for the index pools
  address public defaultExitFeeRecipient;

/* ========== Modifiers ========== */

  modifier isInitializedPool(address poolAddress) {
    require(
      indexPoolMetadata[poolAddress].initialized,
      "ERR_POOL_NOT_FOUND"
    );
    _;
  }

  modifier onlyInitializer(address poolAddress) {
    require(
      msg.sender == computeInitializerAddress(poolAddress),
      "ERR_NOT_PRE_DEPLOY_POOL"
    );
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance, "ERR_NOT_GOVERNANCE");
    _;
  }

/* ==========  Constructor  ========== */

  /**
   * @dev Deploy the controller and configure the addresses
   * of the related accounts.
   */
  constructor(
    IIndexedUniswapV2Oracle uniswapOracle_,
    IPoolFactory poolFactory_,
    IDelegateCallProxyManager proxyManager_,
    address governance_
  )
    public
    ScoredTokenLists(uniswapOracle_)
  {
    poolFactory = poolFactory_;
    proxyManager = proxyManager_;
    governance = governance_;
  }

/* ==========  Initializer  ========== */

  /**
   * @dev Initialize the controller with the owner address and default seller premium.
   * This sets up the controller which is deployed as a singleton proxy.
   */
  function initialize(address circuitBreaker_) public {
    super.initialize();
    defaultSellerPremium = 2;
    circuitBreaker = circuitBreaker_;
  }

/* ==========  Configuration  ========== */

  /**
   * @dev Sets the default premium rate for token seller contracts.
   */
  function setDefaultSellerPremium(uint8 _defaultSellerPremium) external onlyOwner {
    require(_defaultSellerPremium > 0 && _defaultSellerPremium < 20, "ERR_PREMIUM");
    defaultSellerPremium = _defaultSellerPremium;
  }

  /**
   * @dev Sets the circuit breaker address allowed to toggle public swaps.
   */
  function setCircuitBreaker(address circuitBreaker_) external onlyOwner {
    circuitBreaker = circuitBreaker_;
  }

  /**
   * @dev Sets the default exit fee recipient for new pools.
   */
  function setDefaultExitFeeRecipient(address defaultExitFeeRecipient_) external onlyGovernance {
    require(defaultExitFeeRecipient_ != address(0), "ERR_NULL_ADDRESS");
    defaultExitFeeRecipient = defaultExitFeeRecipient_;
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
    uint256 listID,
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

    poolAddress = poolFactory.deployPool(
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(listID, indexSize))
    );
    IIndexPool(poolAddress).configure(address(this), name, symbol);

    indexPoolMetadata[poolAddress] = IndexPoolMeta({
      initialized: false,
      listID: uint16(listID),
      indexSize: uint8(indexSize),
      lastReweigh: 0,
      reweighIndex: 0
    });

    initializerAddress = proxyManager.deployProxyManyToOne(
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IPoolInitializer initializer = IPoolInitializer(initializerAddress);

    // Get the initial tokens and balances for the pool.
    (address[] memory tokens, uint256[] memory balances) = getInitialTokensAndBalances(
      listID,
      indexSize,
      uint144(initialWethValue)
    );

    initializer.initialize(address(this), poolAddress, tokens, balances);

    emit NewPoolInitializer(
      poolAddress,
      initializerAddress,
      listID,
      indexSize
    );
  }

  /**
   * @dev Initializes a pool which has been deployed but not initialized
   * and transfers the underlying tokens from the initialization pool to
   * the actual pool.
   *
   * The actual weights assigned to tokens is calculated based on the
   * relative values of the acquired balances, rather than the initial
   * weights computed from the token scores.
   */
  function finishPreparedIndexPool(
    address poolAddress,
    address[] calldata tokens,
    uint256[] calldata balances
  )
    external
    onlyInitializer(poolAddress)
  {
    uint256 len = tokens.length;
    require(balances.length == len, "ERR_ARR_LEN");

    IndexPoolMeta memory meta = indexPoolMetadata[poolAddress];
    require(!meta.initialized, "ERR_INITIALIZED");

    uint256[] memory ethValues = uniswapOracle.computeAverageEthForTokens(
      tokens,
      balances,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint96[] memory denormalizedWeights = ethValues.computeDenormalizedWeights();

    address sellerAddress = proxyManager.deployProxyManyToOne(
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );

    IIndexPool(poolAddress).initialize(
      tokens,
      balances,
      denormalizedWeights,
      msg.sender,
      sellerAddress,
      defaultExitFeeRecipient
    );

    IUnboundTokenSeller(sellerAddress).initialize(
      address(this),
      poolAddress,
      defaultSellerPremium
    );

    meta.lastReweigh = uint64(now);
    meta.initialized = true;
    indexPoolMetadata[poolAddress] = meta;

    emit PoolInitialized(
      poolAddress,
      sellerAddress,
      meta.listID,
      meta.indexSize
    );
  }

/* ==========  Pool Management  ========== */

  /**
   * @dev Sets the premium rate on `sellerAddress` to the given rate.
   */
  function updateSellerPremium(address tokenSeller, uint8 premiumPercent) external onlyOwner {
    require(premiumPercent > 0 && premiumPercent < 20, "ERR_PREMIUM");
    IUnboundTokenSeller(tokenSeller).setPremiumPercent(premiumPercent);
  }

  /**
   * @dev Sets the controller on an index pool.
   */
  function setController(address poolAddress, address controller) external isInitializedPool(poolAddress) onlyGovernance {
    IIndexPool(poolAddress).setController(controller);
  }

  /**
   * @dev Sets the exit fee recipient for an existing pool.
   */
  function setExitFeeRecipient(address poolAddress, address exitFeeRecipient) external isInitializedPool(poolAddress) onlyGovernance {
    IIndexPool(poolAddress).setExitFeeRecipient(exitFeeRecipient);
  }

  /**
   * @dev Sets the exit fee recipient on multiple existing pools.
   */
  function setExitFeeRecipient(address[] calldata poolAddresses, address exitFeeRecipient) external onlyGovernance {
    for (uint256 i = 0; i < poolAddresses.length; i++) {
      address poolAddress = poolAddresses[i];
      require(indexPoolMetadata[poolAddress].initialized, "ERR_POOL_NOT_FOUND");
      // No not-null requirement - already in pool function.
      IIndexPool(poolAddress).setExitFeeRecipient(exitFeeRecipient);
    }
  }

  /**
   * @dev Sets the swap fee on multiple index pools.
   */
  function setSwapFee(address poolAddress, uint256 swapFee) external onlyGovernance isInitializedPool(poolAddress) {
    IIndexPool(poolAddress).setSwapFee(swapFee);
  }

  /**
   * @dev Sets the swap fee on an index pool.
   */
  function setSwapFee(address[] calldata poolAddresses, uint256 swapFee) external onlyGovernance {
    for (uint256 i = 0; i < poolAddresses.length; i++) {
      address poolAddress = poolAddresses[i];
      require(indexPoolMetadata[poolAddress].initialized, "ERR_POOL_NOT_FOUND");
      // No not-null requirement - already in pool function.
      IIndexPool(poolAddress).setSwapFee(swapFee);
    }
  }

  /**
   * @dev Updates the minimum balance of an uninitialized token, which is
   * useful when the token's price on the pool is too low relative to
   * external prices for people to trade it in.
   */
  function updateMinimumBalance(address pool, address tokenAddress) external isInitializedPool(address(pool)) {
    IIndexPool.Record memory record = IIndexPool(pool).getTokenRecord(tokenAddress);
    require(!record.ready, "ERR_TOKEN_READY");
    uint256 poolValue = _estimatePoolValue(pool);
    uint256 minimumBalance = uniswapOracle.computeAverageTokensForEth(
      tokenAddress,
      poolValue / 100,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    IIndexPool(pool).setMinimumBalance(tokenAddress, minimumBalance);
  }

  /**
   * @dev Delegates a comp-like governance token from an index pool to a provided address.
   */
  function delegateCompLikeTokenFromPool(
    address pool,
    address token,
    address delegatee
  )
    external
    onlyOwner
    isInitializedPool(pool)
  {
    IIndexPool(pool).delegateCompLikeToken(token, delegatee);
  }

  /**
   * @dev Enable/disable public swaps on an index pool.
   * Callable by the contract owner and the `circuitBreaker` address.
   */
  function setPublicSwap(address indexPool_, bool publicSwap) external isInitializedPool(indexPool_) {
    require(
      msg.sender == circuitBreaker || msg.sender == owner(),
      "ERR_NOT_AUTHORIZED"
    );
    IIndexPool(indexPool_).setPublicSwap(publicSwap);
  }

/* ==========  Pool Rebalance Actions  ========== */

  /**
   * @dev Re-indexes a pool by setting the underlying assets to the top
   * tokens in its candidates list by score.
   */
  function reindexPool(address poolAddress) external {
    IndexPoolMeta storage meta = indexPoolMetadata[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");
    require(
      now - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );
    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) == 0,
      "ERR_REWEIGH_INDEX"
    );
    _reindexPool(meta, poolAddress);
  }

  function forceReindexPool(address poolAddress) external onlyOwner {
    IndexPoolMeta storage meta = indexPoolMetadata[poolAddress];
    uint8 divisor = REWEIGHS_BEFORE_REINDEX + 1;
    uint8 remainder = ++meta.reweighIndex % divisor;

    meta.reweighIndex += divisor - remainder;
    _reindexPool(meta, poolAddress);
  }

  function _reindexPool(IndexPoolMeta storage meta, address poolAddress) internal {
    uint256 size = meta.indexSize;
    (address[] memory tokens, uint256[] memory scores) = getTopTokensAndScores(meta.listID, size);
    uint256 wethValue = _estimatePoolValue(poolAddress);
    uint256 minValue = wethValue / 100;
    uint256[] memory ethValues = new uint256[](size);
    for (uint256 i = 0; i < size; i++){
      ethValues[i] = minValue;
    }
    uint256[] memory minimumBalances = uniswapOracle.computeAverageTokensForEth(
      tokens,
      ethValues,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint96[] memory denormalizedWeights = scores.computeDenormalizedWeights();

    meta.lastReweigh = uint64(now);

    IIndexPool(poolAddress).reindexTokens(
      tokens,
      denormalizedWeights,
      minimumBalances
    );
    emit PoolReindexed(poolAddress);
  }

  /**
   * @dev Reweighs the assets in a pool by their scores and sets the
   * desired new weights, which will be adjusted over time.
   */
  function reweighPool(address poolAddress) external {
    IndexPoolMeta memory meta = indexPoolMetadata[poolAddress];
    require(meta.initialized, "ERR_POOL_NOT_FOUND");

    require(
      now - meta.lastReweigh >= POOL_REWEIGH_DELAY,
      "ERR_POOL_REWEIGH_DELAY"
    );

    require(
      (++meta.reweighIndex % (REWEIGHS_BEFORE_REINDEX + 1)) != 0,
      "ERR_REWEIGH_INDEX"
    );

    TokenList storage list = _lists[meta.listID];

    address[] memory tokens = IIndexPool(poolAddress).getCurrentDesiredTokens();
    uint256[] memory scores = IScoringStrategy(list.scoringStrategy).getTokenScores(tokens);
    uint96[] memory denormalizedWeights = scores.computeDenormalizedWeights();

    meta.lastReweigh = uint64(now);
    indexPoolMetadata[poolAddress] = meta;
    IIndexPool(poolAddress).reweighTokens(tokens, denormalizedWeights);
    emit PoolReweighed(poolAddress);
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
      address(proxyManager),
      address(this),
      INITIALIZER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool's unbound token seller.
   */
  function computeSellerAddress(address poolAddress)
    public
    view
    returns (address sellerAddress)
  {
    sellerAddress = SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(this),
      SELLER_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(poolAddress))
    );
  }

  /**
   * @dev Compute the create2 address for a pool.
   */
  function computePoolAddress(uint256 listID, uint256 indexSize)
    public
    view
    returns (address poolAddress)
  {
    poolAddress = SaltyLib.computeProxyAddressManyToOne(
      address(proxyManager),
      address(poolFactory),
      POOL_IMPLEMENTATION_ID,
      keccak256(abi.encodePacked(
        address(this),
        keccak256(abi.encodePacked(listID, indexSize))
      ))
    );
  }

  /**
   * @dev Queries the top `indexSize` tokens in a list from the market oracle,
   * computes their relative weights and determines the weighted balance of each
   * token to meet a specified total value.
   */
  function getInitialTokensAndBalances(
    uint256 listID,
    uint256 indexSize,
    uint256 wethValue
  )
    public
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances
    )
  {
    uint256[] memory scores;
    (tokens, scores) = getTopTokensAndScores(listID, indexSize);
    uint256[] memory relativeEthValues = wethValue.computeProportionalAmounts(scores);
    balances = uniswapOracle.computeAverageTokensForEth(
      tokens,
      relativeEthValues,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    uint256 len = balances.length;
    for (uint256 i = 0; i < len; i++) {
      require(balances[i] >= MIN_BALANCE, "ERR_MIN_BALANCE");
    }
  }

/* ==========  Internal Pool Utility Functions  ========== */

  /**
   * @dev Estimate the total value of a pool by taking its first token's
   * "virtual balance" (balance * (totalWeight/weight)) and multiplying
   * by that token's average ether price from UniSwap.
   */
  function _estimatePoolValue(address pool) internal view returns (uint256) {
    (address token, uint256 value) = IIndexPool(pool).extrapolatePoolValueFromToken();
    return uniswapOracle.computeAverageEthForTokens(
      token,
      value,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


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
/* ==========  Events  ========== */

  event DeploymentApprovalGranted(address deployer);
  event DeploymentApprovalRevoked(address deployer);

  event ManyToOne_ImplementationCreated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ImplementationUpdated(
    bytes32 implementationID,
    address implementationAddress
  );

  event ManyToOne_ProxyDeployed(
    bytes32 implementationID,
    address proxyAddress
  );

  event OneToOne_ProxyDeployed(
    address proxyAddress,
    address implementationAddress
  );

  event OneToOne_ImplementationUpdated(
    address proxyAddress,
    address implementationAddress
  );

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

/* ---  External Libraries  --- */
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/* ---  Proxy Contracts  --- */
import { CodeHashes } from "./CodeHashes.sol";


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
   * Many different contracts in the Indexed framework may use the
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return address(uint256(_data));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


/**
 * @dev Because we use the code hashes of the proxy contracts for proxy address
 * derivation, it is important that other packages have access to the correct
 * values when they import the salt library.
 */
library CodeHashes {
  bytes32 internal constant ONE_TO_ONE_CODEHASH = 0x63d9f7b5931b69188c8f6b806606f25892f1bb17b7f7e966fe3a32c04493aee4;
  bytes32 internal constant MANY_TO_ONE_CODEHASH = 0xa035ad05a1663db5bfd455b99cd7c6ac6bd49269738458eda140e0b78ed53f79;
  bytes32 internal constant IMPLEMENTATION_HOLDER_CODEHASH = 0x11c370493a726a0ffa93d42b399ad046f1b5a543b6e72f1a64f1488dc1c58f2c;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
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

/* ==========  EVENTS  ========== */

  /** @dev Emitted when tokens are swapped. */
  event LOG_SWAP(
    address indexed caller,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 tokenAmountIn,
    uint256 tokenAmountOut
  );

  /** @dev Emitted when underlying tokens are deposited for pool tokens. */
  event LOG_JOIN(
    address indexed caller,
    address indexed tokenIn,
    uint256 tokenAmountIn
  );

  /** @dev Emitted when pool tokens are burned for underlying. */
  event LOG_EXIT(
    address indexed caller,
    address indexed tokenOut,
    uint256 tokenAmountOut
  );

  /** @dev Emitted when a token's weight updates. */
  event LOG_DENORM_UPDATED(address indexed token, uint256 newDenorm);

  /** @dev Emitted when a token's desired weight is set. */
  event LOG_DESIRED_DENORM_SET(address indexed token, uint256 desiredDenorm);

  /** @dev Emitted when a token is unbound from the pool. */
  event LOG_TOKEN_REMOVED(address token);

  /** @dev Emitted when a token is unbound from the pool. */
  event LOG_TOKEN_ADDED(
    address indexed token,
    uint256 desiredDenorm,
    uint256 minimumBalance
  );

  /** @dev Emitted when a token's minimum balance is updated. */
  event LOG_MINIMUM_BALANCE_UPDATED(address token, uint256 minimumBalance);

  /** @dev Emitted when a token reaches its minimum balance. */
  event LOG_TOKEN_READY(address indexed token);

  /** @dev Emitted when public trades are enabled or disabled. */
  event LOG_PUBLIC_SWAP_TOGGLED(bool isPublic);

  /** @dev Emitted when the swap fee is updated. */
  event LOG_SWAP_FEE_UPDATED(uint256 swapFee);

  /** @dev Emitted when exit fee recipient is updated. */
  event LOG_EXIT_FEE_RECIPIENT_UPDATED(address exitFeeRecipient);

  /** @dev Emitted when controller is updated. */
  event LOG_CONTROLLER_UPDATED(address exitFeeRecipient);

  function configure(
    address controller,
    string calldata name,
    string calldata symbol
  ) external;

  function initialize(
    address[] calldata tokens,
    uint256[] calldata balances,
    uint96[] calldata denorms,
    address tokenProvider,
    address unbindHandler,
    address exitFeeRecipient
  ) external;

  function setSwapFee(uint256 swapFee) external;

  function setController(address controller) external;

  function delegateCompLikeToken(address token, address delegatee) external;

  function setExitFeeRecipient(address) external;

  function setPublicSwap(bool enabled) external;

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

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external returns (uint256/* poolAmountOut */);

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external returns (uint256/* tokenAmountIn */);

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  )
    external returns (uint256/* tokenAmountOut */);

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external returns (uint256/* poolAmountIn */);

  function gulp(address token) external;

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

  function isPublicSwap() external view returns (bool);

  function getSwapFee() external view returns (uint256/* swapFee */);

  function getExitFee() external view returns (uint256/* exitFee */);

  function getController() external view returns (address);

  function getExitFeeRecipient() external view returns (address);

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@indexed-finance/proxies/contracts/interfaces/IDelegateCallProxyManager.sol";


interface IPoolFactory {
/* ========== Events ========== */

  event NewPool(address pool, address controller, bytes32 implementationID);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IPoolInitializer {
/* ========== Events ========== */

  event TokensContributed(
    address from,
    address token,
    uint256 amount,
    uint256 credit
  );

/* ========== Mutative ========== */

  function initialize(
    address controller,
    address poolAddress,
    address[] calldata tokens,
    uint256[] calldata amounts
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IUnboundTokenSeller {
/* ========== Events ========== */

  event PremiumPercentSet(uint8 premium);

  event NewTokensToSell(address indexed token, uint256 amountReceived);

  event SwappedTokens(
    address indexed tokenSold,
    address indexed tokenBought,
    uint256 soldAmount,
    uint256 boughtAmount
  );

/* ========== Mutative ========== */

  function initialize(address controller_, address pool, uint8 premiumPercent) external;

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

{
  "metadata": {
    "useLiteralContent": false
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}