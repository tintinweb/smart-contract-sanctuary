//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICirculatingMarketCapOracle.sol";


/**
 * @dev Contract for querying tokens' circulating market caps from CoinGecko via Chainlink.
 *
 * The contract's owner may whitelist or dewhitelist tokens.
 * Only whitelisted tokens' market caps can be requested from Chainlink.
 * This contract requires LINK to operate and assumes that the owner has supplied it with LINK.
 * If it does not have enough LINK to execute a request, it will revert.
 *
 * Returned market caps are denominated in wei units of USD.
 * Each token's market cap can be queried from Chainlink once every `minimumDelay` seconds.
 * If the last update to the market cap is older than `maximumAge`, queries for the token's
 * market cap will revert.
 */
contract CirculatingMarketCapOracle is Ownable, ChainlinkClient, ICirculatingMarketCapOracle {
  string public constant TOKEN_ADDRESS_BASE_URL = "https://api.coingecko.com/api/v3/simple/token_price/ethereum?contract_addresses=";
  string public constant TOKEN_ID_BASE_URL = "https://api.coingecko.com/api/v3/simple/price?ids=";
  string public constant QUERY_PARAMS = "&vs_currencies=usd&include_market_cap=true";

/* ==========  Events  ========== */

  event TokenAdded(address token);
  event TokenRemoved(address token);
  event NewMinimumDelay(uint256 minimumDelay);
  event NewMaximumAge(uint256 maximumAge);
  event NewRequestTimeout(uint256 requestTimeout);
  event NewChainlinkFee(uint256 fee);
  event NewJobID(bytes32 jobID);
  event TokenOverrideAdded(address token, string overrideID);
  event TokenOverrideRemoved(address token);

/* ==========  Structs  ========== */

  struct TokenDetails {
    bool whitelisted;
    bool hasPendingRequest;
    bool useOverride;
    uint32 lastPriceTimestamp;
    uint32 lastRequestTimestamp;
    uint168 marketCap;
  }

/* ==========  Storage  ========== */

  /** @dev Minimum delay between Chainlink queries for a token's market cap */
  uint256 public minimumDelay;
  /** @dev Maximum age of a market cap value that can be queried */
  uint256 public maximumAge;
  /** @dev Maximum age of a request before allowing the query to be retried. */
  uint256 public requestTimeout;
  /** @dev Amount of LINK paid for each query */
  uint256 public fee = 4e17; // 0.4 LINK
  /** @dev Address of the Chainlink node */
  address public oracle;
  /** @dev Chainlink job ID */
  bytes32 public jobID;

  /** @dev Records for token approval, market cap and status. */
  mapping(address => TokenDetails) public getTokenDetails;
  /** @dev Records of which addresses are associated with pending requests. */
  mapping(bytes32 => address) public pendingRequestMap;
  /** @dev Used for wrapper tokens to query the base asset instead of the erc20. */
  mapping(address => string) public tokenOverrideIDs;

  /**
  * @dev Constructor
  * @param _minimumDelay Minimum delay in seconds before token price can be updated again.
  * @param _maximumAge Maximum age of a market cap record that can be queried.
  * @param _requestTimeout Maximum age of a request before allowing the query to be retried.
  * @param _oracle Chainlink oracle address.
  * @param _jobID Chainlink job id.
  * @param _link Chainlink token address.
  */
  constructor(
    uint256 _minimumDelay,
    uint256 _maximumAge,
    uint256 _requestTimeout,
    address _oracle,
    bytes32 _jobID,
    address _link
  ) public Ownable() {
    minimumDelay = _minimumDelay;
    maximumAge = _maximumAge;
    requestTimeout = _requestTimeout;
    oracle = _oracle;
    jobID = _jobID;
    setChainlinkToken(_link);
  }

/* ==========  Public Actions  ========== */

  /**
   * @dev Requests the market caps for a set of tokens from Chainlink.
   *
   * Note: If token is not whitelisted, this function will revert.
   * If the token already has a pending request, or the last update is too
   * recent, this will not revert but a new request will not be created.
   */
  function updateCirculatingMarketCaps(address[] calldata _tokenAddresses) external override {
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      address token = _tokenAddresses[i];
      TokenDetails storage details = getTokenDetails[token];
      // If token is not whitelisted, don't pay to update it.
      require(details.whitelisted, "CirculatingMarketCapOracle: Token is not whitelisted");
      // If token already has a pending update request, or the last update is too
      // new, fail gracefully.
      if (
        details.hasPendingRequest ||
        now - details.lastPriceTimestamp < minimumDelay
      ) {
        continue;
      }
      details.hasPendingRequest = true;
      details.lastRequestTimestamp = uint32(now);
      // Execute Chainlink request
      bytes32 requestId = requestCoinGeckoData(_tokenAddresses[i]);
      // Map requestId to the token address
      pendingRequestMap[requestId] = token;
    }
  }

  /**
   * @dev Cancel an expired request by setting `hasPendingRequest` to false.
   *
   * Note: Does not actually cancel the request on Chainlink, only marks the
   * token as not having a pending request so it can be queried again.
   */
  function cancelExpiredRequest(address token) external {
    TokenDetails storage details = getTokenDetails[token];
    require(
      details.hasPendingRequest &&
      now - details.lastRequestTimestamp >= requestTimeout,
      "CirculatingMarketCapOracle: Request has not expired or does not exist"
    );
    details.hasPendingRequest = false;
  }

/* ==========  Market Cap Queries  ========== */

  /**
   * @dev Query the latest circulating market caps for a set of tokens.
   *
   * Note: Reverts if any of the tokens has no stored market cap or if the last
   * market cap is older than `maximumAge` seconds.
   *
   * @param tokens Addresses of tokens to get market caps for.
   * @return marketCaps Array of latest markets cap for tokens
   */
  function getCirculatingMarketCaps(address[] calldata tokens)
    external
    view
    override
    returns (uint256[] memory marketCaps)
  {
    uint256 len = tokens.length;
    marketCaps = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      marketCaps[i] = getCirculatingMarketCap(tokens[i]);
    }
  }

  /**
   * @dev Query the latest circulating market cap for a token.
   *
   * Note: Reverts if the token has no stored market cap or if the last
   * market cap is older than `maximumAge` seconds.
   *
   * @param token Address of token to get market cap for.
   * @return uint256 of latest market cap for token
   */
  function getCirculatingMarketCap(address token) public view override returns (uint256) {
    require(
      now - getTokenDetails[token].lastPriceTimestamp < maximumAge,
      "CirculatingMarketCapOracle: Marketcap has expired"
    );

    return getTokenDetails[token].marketCap;
  }

  /**
   * @dev Check if a token is whitelisted.
   * @param token Address to check
   * @return boolean indicating whether token is whitelisted
   */
  function isTokenWhitelisted(address token) external view override returns (bool) {
    return getTokenDetails[token].whitelisted;
  }

/* ==========  Chainlink Functions  ========== */

  /**
  * @dev Create a Chainlink request to retrieve API response, find the target
  * data, then multiply 1e18 to normalize the value as a token amount.
  *
  * CoinGecko API Example:
  * {
  *   '0x514910771af9ca656af840dff83e8264ecf986ca': {
  *   'usd': 23.01,
  *   'usd_market_cap': 9362732898.302298
  *     }
  *   }
  *
  * https://docs.chain.link/docs/make-a-http-get-request#api-consumer
  *
  * @param _token Address of the token to query the circulating market cap of.
  * @return requestId The request id for the node operator
  */
  function requestCoinGeckoData(address _token) internal virtual returns (bytes32 requestId) {
    Chainlink.Request memory request = buildChainlinkRequest(
      jobID,
      address(this),
      this.fulfill.selector
    );

    // Build the CoinGecko request URL
    (string memory url, string memory tokenKey) = getCoingeckoMarketCapUrlAndKey(_token);

    // Set the request object to perform a GET request with the constructed URL
    request.add("get", url);

    // Build path to parse JSON response from CoinGecko
    // e.g. '0x514910771af9ca656af840dff83e8264ecf986ca.usd_market_cap'
    string memory pathString = string(abi.encodePacked(tokenKey, ".usd_market_cap"));
    request.add("path", pathString);

    // Multiply by 1e18 to format the number as a typical token value.
    request.addInt("times", 1e18);

    // Sends the request
    requestId = sendChainlinkRequestTo(oracle, request, fee);
  }

  /**
  * @dev Callback function for Chainlink node.
  * Updates the token mapping and removes the request from pendingRequestMap
  */
  function fulfill(bytes32 _requestId, uint256 _marketCap) external virtual recordChainlinkFulfillment(_requestId) {
    // Wraps the internal function to simplify automated testing with mocks.
    _fulfill(_requestId, _marketCap);
  }

  function _fulfill(bytes32 _requestId, uint256 _marketCap) internal {
    address token = pendingRequestMap[_requestId];

    TokenDetails storage details = getTokenDetails[token];
    details.lastPriceTimestamp = uint32(now);
    details.marketCap = _safeUint168(_marketCap);
    details.hasPendingRequest = false;

    delete pendingRequestMap[_requestId];
  }

/* ==========  Control Functions  ========== */

  /**
   * @dev Withdraw Link tokens in contract to owner address
   */
  function withdrawLink() external onlyOwner {
    IERC20 linkToken = IERC20(chainlinkTokenAddress());
    linkToken.transfer(owner(), linkToken.balanceOf(address(this)));
  }

  /**
   * @dev Whitelist a list of token addresses
   */
  function addTokensToWhitelist(address[] calldata _tokens) external onlyOwner {
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      address token = _tokens[i];
      getTokenDetails[token].whitelisted = true;
      emit TokenAdded(token);
    }
  }

  /**
   * @dev Remove a list of token addresses from whitelist
   */
  function removeTokensFromWhitelist(address[] calldata _tokens) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++){
      address token = _tokens[i];
      getTokenDetails[token].whitelisted = false;
      emit TokenRemoved(token);
    }
  }

  /**
   * @dev Change minimumDelay
   */
  function setMinimumDelay(uint256 _newDelay) external onlyOwner {
    minimumDelay = _newDelay;
    emit NewMinimumDelay(_newDelay);
  }

  /**
   * @dev Change maximumAge
   */
  function setMaximumAge(uint256 _maximumAge) external onlyOwner {
    maximumAge = _maximumAge;
    emit NewMaximumAge(_maximumAge);
  }

  /**
   * @dev Change requestTimeout
   */
  function setRequestTimeout(uint256 _requestTimeout) external onlyOwner {
    requestTimeout = _requestTimeout;
    emit NewRequestTimeout(_requestTimeout);
  }

  /**
  * @dev Changes the chainlink node operator fee to be sent
  */
  function setChainlinkNodeFee(uint256 _fee) external onlyOwner {
    fee = _fee;
    emit NewChainlinkFee(_fee);
  }

  /**
  * @dev Changes the chainlink job ID
  */
  function setJobID(bytes32 _jobID) external onlyOwner {
    jobID = _jobID;
    emit NewJobID(_jobID);
  }

  /**
   * @dev Sets an override ID to use for a token instead of its address.
   * Note: This will change the API query used to get the market cap.
   */
  function setTokenOverrideID(address token, string calldata overrideID) external onlyOwner {
    TokenDetails storage details = getTokenDetails[token];
    if (bytes(overrideID).length == 0) {
      details.useOverride = false;
      delete tokenOverrideIDs[token];
      emit TokenOverrideRemoved(token);
    } else {
      details.useOverride = true;
      tokenOverrideIDs[token] = overrideID;
      emit TokenOverrideAdded(token, overrideID);
    }
  }

/* ==========  Utility Functions  ========== */

  /**
   * @dev Internal function to convert an address to a string memory
   */
  function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint256 i = 0; i < 20; i++) {
      str[2*i + 2] = alphabet[uint8(value[i + 12] >> 4)];
      str[2*i + 3] = alphabet[uint8(value[i + 12] & 0x0f)];
    }
    return string(str);
  }

  function getCoingeckoMarketCapUrlAndKey(address token)
    public
    view
    returns (string memory url, string memory tokenKey)
  {
    TokenDetails storage details = getTokenDetails[token];
    if (details.useOverride) {
      tokenKey = tokenOverrideIDs[token];
      url = string(
        abi.encodePacked(
          TOKEN_ID_BASE_URL,
          tokenKey,
          QUERY_PARAMS
        )
      );
    } else {
      tokenKey = addressToString(token);
      url = string(
        abi.encodePacked(
          TOKEN_ADDRESS_BASE_URL,
          tokenKey,
          QUERY_PARAMS
        )
      );
    }
  }

  function _safeUint168(uint256 x) internal pure returns (uint168 y) {
    y = uint168(x);
    require(x == y, "CirculatingMarketCapOracle: uint exceeds 168 bits");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ARGS_VERSION = 1;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  ChainlinkRequestInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param _specId The Job Specification ID that the request will be created for
   * @param _callbackAddress The callback address that the response will be sent to
   * @param _callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 _specId,
    address _callbackAddress,
    bytes4 _callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(_specId, _callbackAddress, _callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
  {
    return sendChainlinkRequestTo(address(oracle), _req, _payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param _oracle The address of the oracle for the request
   * @param _req The initialized Chainlink Request
   * @param _payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(address _oracle, Chainlink.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    _req.nonce = requestCount;
    pendingRequests[requestId] = _oracle;
    emit ChainlinkRequested(requestId);
    require(link.transferAndCall(_oracle, _payment, encodeRequest(_req)), "unable to transferAndCall to oracle");
    requestCount += 1;

    return requestId;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param _requestId The request ID
   * @param _payment The amount of LINK sent for the request
   * @param _callbackFunc The callback function specified for the request
   * @param _expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 _requestId,
    uint256 _payment,
    bytes4 _callbackFunc,
    uint256 _expiration
  )
    internal
  {
    ChainlinkRequestInterface requested = ChainlinkRequestInterface(pendingRequests[_requestId]);
    delete pendingRequests[_requestId];
    emit ChainlinkCancelled(_requestId);
    requested.cancelOracleRequest(_requestId, _payment, _callbackFunc, _expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param _oracle The address of the oracle contract
   */
  function setChainlinkOracle(address _oracle) internal {
    oracle = ChainlinkRequestInterface(_oracle);
  }

  /**
   * @notice Sets the LINK token address
   * @param _link The address of the LINK token contract
   */
  function setChainlinkToken(address _link) internal {
    link = LinkTokenInterface(_link);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (address)
  {
    return address(link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress()
    internal
    view
    returns (address)
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param _oracle The address of the oracle contract that will fulfill the request
   * @param _requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address _oracle, bytes32 _requestId)
    internal
    notPendingRequest(_requestId)
  {
    pendingRequests[_requestId] = _oracle;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param _ens The address of the ENS contract
   * @param _node The ENS node hash
   */
  function useChainlinkWithENS(address _ens, bytes32 _node)
    internal
  {
    ens = ENSInterface(_ens);
    ensNode = _node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS()
    internal
  {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Encodes the request to be sent to the oracle contract
   * @dev The Chainlink node expects values to be in order for the request to be picked up. Order of types
   * will be validated in the oracle contract.
   * @param _req The initialized Chainlink Request
   * @return The bytes payload for the `transferAndCall` method
   */
  function encodeRequest(Chainlink.Request memory _req)
    private
    view
    returns (bytes memory)
  {
    return abi.encodeWithSelector(
      oracle.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      _req.id,
      _req.callbackAddress,
      _req.callbackFunctionId,
      _req.nonce,
      ARGS_VERSION,
      _req.buf.buf);
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param _requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 _requestId)
    internal
    recordChainlinkFulfillment(_requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param _requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 _requestId) {
    require(msg.sender == pendingRequests[_requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[_requestId];
    emit ChainlinkFulfilled(_requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param _requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 _requestId) {
    require(pendingRequests[_requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
abstract contract Ownable is Context {
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
pragma solidity ^0.6.0;


interface ICirculatingMarketCapOracle {
  function isTokenWhitelisted(address token) external view returns (bool);

  function getCirculatingMarketCap(address) external view returns (uint256);

  function getCirculatingMarketCaps(address[] calldata) external view returns (uint256[] memory);

  function updateCirculatingMarketCaps(address[] calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { CBORChainlink } from "./vendor/CBORChainlink.sol";
import { BufferChainlink } from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param _id The Job Specification ID
   * @param _callbackAddress The callback address
   * @param _callbackFunction The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 _id,
    address _callbackAddress,
    bytes4 _callbackFunction
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = _id;
    self.callbackAddress = _callbackAddress;
    self.callbackFunctionId = _callbackFunction;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param _data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory _data)
    internal pure
  {
    BufferChainlink.init(self.buf, _data.length);
    BufferChainlink.append(self.buf, _data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The string value to add
   */
  function add(Request memory self, string memory _key, string memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeString(_value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The bytes value to add
   */
  function addBytes(Request memory self, string memory _key, bytes memory _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeBytes(_value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The int256 value to add
   */
  function addInt(Request memory self, string memory _key, int256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeInt(_value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _value The uint256 value to add
   */
  function addUint(Request memory self, string memory _key, uint256 _value)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.encodeUInt(_value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param _key The name of the key
   * @param _values The array of string values to add
   */
  function addStringArray(Request memory self, string memory _key, string[] memory _values)
    internal pure
  {
    self.buf.encodeString(_key);
    self.buf.startArray();
    for (uint256 i = 0; i < _values.length; i++) {
      self.buf.encodeString(_values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);


  function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) external;
  function setResolver(bytes32 node, address _resolver) external;
  function setOwner(bytes32 node, address _owner) external;
  function setTTL(bytes32 node, uint64 _ttl) external;
  function owner(bytes32 node) external view returns (address);
  function resolver(bytes32 node) external view returns (address);
  function ttl(bytes32 node) external view returns (uint64);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.19 < 0.7.0;

import { BufferChainlink } from "./BufferChainlink.sol";

library CBORChainlink {
    using BufferChainlink for BufferChainlink.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    function encodeType(BufferChainlink.buffer memory buf, uint8 major, uint value) private pure {
        if(value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if(value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if(value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if(value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else if(value <= 0xFFFFFFFFFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
        encodeType(buf, MAJOR_TYPE_INT, value);
    }

    function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
        if(value < -0x10000000000000000) {
            encodeSignedBigNum(buf, value);
        } else if(value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, value);
        } else if(value >= 0) {
            encodeType(buf, MAJOR_TYPE_INT, uint(value));
        } else {
            encodeType(buf, MAJOR_TYPE_NEGATIVE_INT, uint(-1 - value));
        }
    }

    function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_BYTES, value.length);
        buf.append(value);
    }

    function encodeBigNum(BufferChainlink.buffer memory buf, int value) internal pure {
      buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
      encodeBytes(buf, abi.encode(uint(value)));
    }

    function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
      buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
      encodeBytes(buf, abi.encode(uint(-1 - input)));
    }

    function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
        encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
        buf.append(bytes(value));
    }

    function startArray(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
* @dev A library for working with mutable byte buffers in Solidity.
*
* Byte buffers are mutable and expandable, and provide a variety of primitives
* for writing to them. At any time you can fetch a bytes object containing the
* current contents of the buffer. The bytes object should not be stored between
* operations, as it may change due to resizing of the buffer.
*/
library BufferChainlink {
  /**
  * @dev Represents a mutable buffer. Buffers have a current value (buf) and
  *      a capacity. The capacity may be longer than the current value, in
  *      which case it can be extended without the need to allocate more memory.
  */
  struct buffer {
    bytes buf;
    uint capacity;
  }

  /**
  * @dev Initializes a buffer with an initial capacity.
  * @param buf The buffer to initialize.
  * @param capacity The number of bytes of space to allocate the buffer.
  * @return The buffer, for chaining.
  */
  function init(buffer memory buf, uint capacity) internal pure returns(buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
  * @dev Initializes a new buffer from an existing bytes object.
  *      Changes to the buffer may mutate the original value.
  * @param b The bytes object to initialize the buffer with.
  * @return A new buffer.
  */
  function fromBytes(bytes memory b) internal pure returns(buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint a, uint b) private pure returns(uint) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
  * @dev Sets buffer length to 0.
  * @param buf The buffer to truncate.
  * @return The original buffer, for chaining..
  */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
  * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The start offset to write to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes memory data, uint len) internal pure returns(buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint dest;
    uint src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }

    return buf;
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @param len The number of bytes to copy.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data, uint len) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
  * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write the byte at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeUint8(buffer memory buf, uint off, uint8 data) internal pure returns(buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
  * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns(buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
  * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
  *      exceed the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (left-aligned).
  * @return The original buffer, for chaining.
  */
  function write(buffer memory buf, uint off, bytes32 data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    // Right-align data
    data = data >> (8 * (32 - len));
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
  * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
  *      capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function writeBytes20(buffer memory buf, uint off, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
  * @dev Writes an integer to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param off The offset to write at.
  * @param data The data to append.
  * @param len The number of bytes to write (right-aligned).
  * @return The original buffer, for chaining.
  */
  function writeInt(buffer memory buf, uint off, uint data, uint len) private pure returns(buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = 256 ** len - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
    * @dev Appends a byte to the end of the buffer. Resizes if doing so would
    * exceed the capacity of the buffer.
    * @param buf The buffer to append to.
    * @param data The data to append.
    * @return The original buffer.
    */
  function appendInt(buffer memory buf, uint data, uint len) internal pure returns(buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
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