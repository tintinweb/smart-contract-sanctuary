// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Constants that need to be set before deploying:
// set DECIMALS, LINK_ADDRESS (in both contracts), STABLECOIN_ADDRESS, ARBOL_ORACLE, and EVALUATION_JOB depending on network
// set ORACLE_PAYMENT to 1 on mainnet
// set END based on final date + update delay to IPFS of weather data source 

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/SimpleWriteAccessController.sol";


contract BlizzardDerivativeProvider is SimpleWriteAccessController {
    /**
     * @dev BlizzardDerivativeProvider contract for Dallas Snow Protection 21-22 Season
     */
    uint256 private constant DECIMALS = 3;                                                                      // Decimals for chosen stablecoin
    address private constant LINK_ADDRESS = 0xa36085F69e2889c224210F603D836748e7dC0088;                         // Link token address on Ethereum Kovan
    address private constant STABLECOIN_ADDRESS = 0xe8AA8A60C9417d8fD59EB4378687dDCEEd29c1B4;                   // Stablecoin/USDC token address on Ethereum Kovan
    
    uint256 public constant COLLATERAL_PAYMENT = 250000 * 10**DECIMALS;                                         // 250,000 * 1 USDC
    uint256 public constant PREMIUM_PAYMENT = 10000 * 10**DECIMALS;                                             // 10,000 * 1 USDC
    address public constant ORACLE_BANK = 0x69640770407A09B166AED26B778699045B304768;                           // Oracle funder
    address public constant COLLATERAL_ADDRESS = 0xbf417C41F3ab1e01BD6867fB540dA7b734EaeA95;                    // Collateral provider
    address public constant PREMIUM_ADDRESS = 0xa679c6154b8d4619Af9F83f0bF9a13A680e01eCf;                       // Purchaser

    bool public collateralDeposited;
    bool public premiumDeposited;
    bool public contractPaidOut;

    BlizzardOption public blizzardContract;
    BlizzardOption private testContract;

    /**
     * @dev Event to log when a contract is created
     */
    event contractCreated(address _contract, string _id, string[] _params);
    
    /**
     * @dev Sets deploying address as owner, owner must approve this address to move LINK
     */
    constructor() {
        collateralDeposited = false;
        premiumDeposited = false;
        contractPaidOut = false;
    }

    /**
     * @dev Deploy test option contract for verification purposes
     */
    function deployVerificationContract()
        external
        onlyOwner
    {
        testContract = new BlizzardOption();
    }

    /**
     * @dev Get address of deployed test contract for verification
     * @return address of contract
     */
    function getVerificationAddress()
        external
        onlyOwner
        view
        returns (address)
    {
        return address(testContract);
    }

    /**
     * @notice Deposit collateral for Dallas snow protection contract (must first approve smart contract to move USDC!)
     * @dev Neither collateral nor premium can already be deposited, sender must have access
     */
    function depositCollateral()
        external
        checkAccess
    {
        require(!premiumDeposited && !collateralDeposited, "unable to deposit premium more than once");
        LinkTokenInterface stablecoin = LinkTokenInterface(STABLECOIN_ADDRESS);  
        collateralDeposited = true;
        require(stablecoin.transferFrom(msg.sender, address(this), COLLATERAL_PAYMENT), "unable to deposit collateral");
    }

    /**
     * @notice Deposit premium and purchase new options contract (must first approve smart contract to move USDC!)
     * @dev Collateral must already be deposited, premium must not already be deposited, sender must have access
     */
    function depositPremium()
        external
        checkAccess
    {
        require(!premiumDeposited && collateralDeposited, "unable to deposit premium until collateral has been deposited");
        LinkTokenInterface stablecoin = LinkTokenInterface(STABLECOIN_ADDRESS);
        premiumDeposited = true;
        require(stablecoin.transferFrom(msg.sender, address(this), PREMIUM_PAYMENT), "unable to deposit premium");
        newContract();
    }

    /**
     * @notice Request payout evaluation for the snow protection contract
     * @dev Sender must have access, owner must first approve this address to move LINK
     */
    function initiateContractEvaluation() 
        external 
        checkAccess 
    {
        bool evalStatus = blizzardContract.contractEvaluated();
        require(collateralDeposited && premiumDeposited && !evalStatus, "no reason to initiate contract evaluation after contract has been evaluated");
        LinkTokenInterface link = LinkTokenInterface(LINK_ADDRESS);
        uint256 oracle_payment = blizzardContract.getOraclePayment();
        require(link.transferFrom(ORACLE_BANK, address(blizzardContract), oracle_payment), "unable to fund oracle request");
        blizzardContract.requestPayoutEvaluation();
    }

    /**
     * @notice Fulfill payout evaluation for the snow protection contract
     * @dev Sender must have access
     */
    function fulfillContractEvaluation() 
        external 
        checkAccess 
    {
        bool evalStatus = blizzardContract.contractEvaluated();
        require(collateralDeposited && premiumDeposited && evalStatus && !contractPaidOut, "unable to fulfill payout before contract is evaluated or after contract is paid out");
        LinkTokenInterface stablecoin = LinkTokenInterface(STABLECOIN_ADDRESS);
        uint256 payout = blizzardContract.payout();
        contractPaidOut = true;
        if (payout > 0) {
            require(stablecoin.transfer(PREMIUM_ADDRESS, payout), "unable to payout to buyer");
        }
        require(stablecoin.transfer(COLLATERAL_ADDRESS, stablecoin.balanceOf(address(this))), "unable to return final balance to provider");
    }

    /**
     * @notice Add a new node and associated job ID to the contract execution/evalution set
     * @dev Sender must have access
     * @param _oracle address of oracle contract for chainlink node
     * @param _job string ID for associated oracle job
     */
    function addContractJob(
        address _oracle,
        string memory _job
    ) 
        external 
        checkAccess 
    {
        blizzardContract.addOracleJob(_oracle, stringToBytes32(_job));
    }

    /**
     * @notice Remove a job from the contract execution/evaluation set
     * @dev Sender must have access
     * @param _job string ID for associated oracle job
     */
    function removeContractJob(
        string memory _job
    )
        external
        checkAccess
    {
        blizzardContract.removeOracleJob(stringToBytes32(_job));
    }

    /**
     * @dev Private function to create a new options contract once collateral and premium have been deposited
     */
    function newContract() 
        private
    {
        blizzardContract = new BlizzardOption();
        string[] memory params = blizzardContract.getParameters();
        emit contractCreated(address(blizzardContract), "Dallas Mavs 2022-04-10 00:00:00", params);
    }

    /**
     * @notice Get the parameters for the blizzard contract
     * @dev Sender must have access
     * @return string[] contract terms
     */
    function getContractParameters() 
        public 
        checkAccess 
        view
        returns (string[] memory) 
    {
        return blizzardContract.getParameters();
    }

    /**
     * @notice Returns the evaluation status of the snow protection contract
     * @return bool evaluated
     */
    function getContractEvaluated()
        external
        view
        returns (bool)
    {
        return blizzardContract.contractEvaluated();
    }

    /**
     * @notice Returns the payout value for snow protection contract
     * @return uint256 payout value
     */
    function getContractPayout()
        external
        view
        returns (uint256)
    {
        return blizzardContract.payout();
    }

    /**
     * @dev Write string to bytes32
     * @param _source string to convert
     * @return _result bytes32 converted string
     */
    function stringToBytes32(
        string memory _source
    )
        private
        pure
        returns (bytes32 _result)
    {
        bytes memory tempEmptyStringTest = bytes(_source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            _result := mload(add(_source, 32))
        }
    }
}


// set END to 0 and dates to the shorter array if running tests
contract BlizzardOption is ChainlinkClient, ConfirmedOwner {
    /**
     * @dev BlizzardOption contract for Dallas Snow Protection 21-22 Season
     */
    using Chainlink for Chainlink.Request;

    // uint256 private constant END = 1649649600;                                                                  // Timestamp of end of contract + data source update delay
    uint256 private constant END = 0;                                                                           // Timestamp of end of contract + data source update delay
    uint256 private constant ORACLE_PAYMENT = 1 * 10**2;                                                        // 0.0000000000000001 LINK
    address private constant LINK_ADDRESS = 0xa36085F69e2889c224210F603D836748e7dC0088;                         // Link token address on Ethereum Kovan
    // address private constant ARBOL_ORACLE = 0x58935F97aB874Bc4181Bc1A3A85FDE2CA80885cd;                         // address of Arbol Chainlink Node oracle contract
    address private constant ARBOL_ORACLE = 0x2bD976e4AB857eE553f461E6934d06c086a25D7e;                         // address of Arbol Chainlink Node operator contract
    // bytes32 private constant EVALUATION_JOB = "63bb451d36754aab849577a73ce4eb7e";                               // general Get Contract Evaluation job ID for oracle contract
    bytes32 private constant EVALUATION_JOB = "c9a0bbc14f5e47d09010e32cf1e6d569";                               // general Get Contract Evaluation job ID for oracle contract

    mapping(bytes32 => uint256) public oracleMap;
    address[] public oracles;
    bytes32[] public jobs;

    uint256 public payout;
    bool public contractEvaluated;
    uint256 private requestsPending;
    string[] private parameters;

    /**
     * @notice Creates a new blizzard option contract with the terms below
     * @dev Assigns caller address as contract ownert
     */
    constructor() 
        ConfirmedOwner(msg.sender) 
    {
        payout = 0;
        contractEvaluated = false;
        parameters = ["station_id", "USW00003927", 
            "weather_variable", "SNOW", 
            "dataset", "ghcnd", 
            "opt_type", "CALL", 
            "strike", "0", 
            "limit", "250000", 
            "tick", "250000", 
            "threshold", "6", 
            "imperial_units", "True", 
            "dates", '["2021-10-06", "2021-10-08", "2021-10-26", "2021-10-28", "2021-10-31", "2021-11-02", "2021-11-06", "2021-11-08", "2021-11-15", "2021-11-27", "2021-11-29", "2021-12-03", "2021-12-04", "2021-12-07", "2021-12-13", "2021-12-15", "2021-12-21", "2021-12-23"]'
            // "dates", '["2021-10-06", "2021-10-08", "2021-10-26", "2021-10-28", "2021-10-31", "2021-11-02", "2021-11-06", "2021-11-08", "2021-11-15", "2021-11-27", "2021-11-29", "2021-12-03", "2021-12-04", "2021-12-07", "2021-12-13", "2021-12-15", "2021-12-21", "2021-12-23", "2022-01-03", "2022-01-05", "2022-01-09", "2022-01-15", "2022-01-17", "2022-01-19", "2022-01-20", "2022-01-23", "2022-01-29", "2022-02-02", "2022-02-04", "2022-02-06", "2022-02-08", "2022-02-10", "2022-02-12", "2022-03-03", "2022-03-05", "2022-03-07", "2022-03-09", "2022-03-21", "2022-03-23", "2022-03-27", "2022-03-29", "2022-04-08", "2022-04-10"]'
            ];
        setChainlinkToken(LINK_ADDRESS);
        oracles.push(ARBOL_ORACLE);
        jobs.push(EVALUATION_JOB);
    }

    /**
     * @notice Makes a chainlink oracle request to compute a payout evaluation for this contract
     * @dev Can only be called by the contract owner
     */
    function requestPayoutEvaluation() 
        public 
        onlyOwner 
    {
        require(END < block.timestamp, "unable to call until coverage period has ended");
        // do all looped reads from memory instead of storage
        address[] memory _oracles = oracles;
        bytes32[] memory _jobs = jobs;
        string[] memory _parameters = parameters;
        uint256 requests = 0;

        for (uint256 i = 0; i != _oracles.length; i += 1) {
            Chainlink.Request memory req = buildChainlinkRequest(_jobs[i], address(this), this.fulfillPayoutEvaluation.selector);
            req.addStringArray("parameters", _parameters);
            sendChainlinkRequestTo(_oracles[i], req, ORACLE_PAYMENT);
            requests += 1;
            }
        requestsPending = requests;
    }

    /**
     * @dev Callback function for chainlink oracle requests, assigns payout
     */
    function fulfillPayoutEvaluation(bytes32 _requestId, uint256 _result)
        public
        recordChainlinkFulfillment(_requestId)
    {
        payout += _result;
        requestsPending -= 1;
        if (requestsPending == 0) {
            payout /= oracles.length;
            contractEvaluated = true;

            LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
            require(link.transfer(owner(), link.balanceOf(address(this))), "Unable to transfer remaining LINK tokens");
        }
    }

    /**
     * @notice Add a new node and associated job ID to the contract evaluator set
     * @dev Can only be called by the contract owner
     * @param _oracle address of oracle contract for chainlink node
     * @param _job bytes32 ID for associated oracle job
     */
    function addOracleJob(
        address _oracle, 
        bytes32 _job
    )   
        public 
        onlyOwner
    {
        uint256 index = oracleMap[_job];
        if (jobs.length == 0) {
            oracles.push(_oracle);
            jobs.push(_job);
            oracleMap[_job] = oracles.length - 1;
        } else {
            if (jobs[index] != _job) {
                oracles.push(_oracle);
                jobs.push(_job);
                oracleMap[_job] = oracles.length - 1;
            }
        }
    }

    /**
     * @notice Remove a node and associated job ID from the contract evaluator set
     * @dev Can only be called by the contract owner
     * @param _job bytes32 ID of oracle job to remove
     */
    function removeOracleJob(
        bytes32 _job
    ) 
        public 
        onlyOwner
    {
        uint256 index = oracleMap[_job];
        if (!(index == 0 && jobs[index] != _job)) {
            if (index == jobs.length - 1) {
                oracles.pop();
                jobs.pop();
            } else {
                oracles[index] = oracles[oracles.length - 1];
                oracles.pop();
                jobs[index] = jobs[jobs.length - 1];
                jobs.pop();
                oracleMap[jobs[index]] = index;
            }
        }
    }

    /**
     * @notice Get the contract parameters
     * @dev Can only be called by the contract owner
     * @return string[] contract terms
     */
    function getParameters() 
        public 
        onlyOwner 
        view
        returns (string[] memory) 
    {
        string[] memory _parameters = parameters;
        return _parameters;
    }

    /**
     * @notice Get the oracle payment (number of contract jobs * payment amount)
     * @return uint256 total oracle payment value
     */
    function getOraclePayment() 
        public 
        view 
        returns (uint256) 
    {
        return ORACLE_PAYMENT * jobs.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import { ENSResolver as ENSResolver_Chainlink } from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 constant internal LINK_DIVISIBILITY = 10**18;
  uint256 constant private AMOUNT_OVERRIDE = 0;
  address constant private SENDER_OVERRIDE = address(0);
  uint256 constant private ORACLE_ARGS_VERSION = 1;
  uint256 constant private OPERATOR_ARGS_VERSION = 2;
  bytes32 constant private ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 constant private ENS_ORACLE_SUBNAME = keccak256("oracle");
  address constant private LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private ens;
  bytes32 private ensNode;
  LinkTokenInterface private link;
  OperatorInterface private oracle;
  uint256 private requestCount = 1;
  mapping(bytes32 => address) private pendingRequests;

  event ChainlinkRequested(
    bytes32 indexed id
  );
  event ChainlinkFulfilled(
    bytes32 indexed id
  );
  event ChainlinkCancelled(
    bytes32 indexed id
  );

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddress The callback address that the response will be sent to
   * @param callbackFunctionSignature The callback function signature to use for the callback address
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionSignature
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddress, callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return sendChainlinkRequestTo(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, ORACLE_ARGS_VERSION, oracle.oracleRequest.selector);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `requestOracleDataFrom` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleData(
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32
    )
  {
    return requestOracleDataFrom(address(oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function requestOracleDataFrom(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    return rawRequest(oracleAddress, req, payment, OPERATOR_ARGS_VERSION, oracle.requestOracleData.selector);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @param argsVersion The version of data support (single word, multi word)
   * @return requestId The request ID
   */
  function rawRequest(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment,
    uint256 argsVersion,
    bytes4 funcSelector
  )
    private
    returns (
      bytes32 requestId
    )
  {
    requestId = keccak256(abi.encodePacked(this, requestCount));
    req.nonce = requestCount;
    pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    bytes memory encodedData = abi.encodeWithSelector(
      funcSelector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackAddress,
      req.callbackFunctionId,
      req.nonce,
      argsVersion,
      req.buf.buf);
    require(link.transferAndCall(oracleAddress, payment, encodedData), "unable to transferAndCall to oracle");
    requestCount += 1;
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  )
    internal
  {
    OperatorInterface requested = OperatorInterface(pendingRequests[requestId]);
    delete pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(
    address oracleAddress
  )
    internal
  {
    oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(
    address linkAddress
  )
    internal
  {
    link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() 
    internal
  {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress()
    internal
    view
    returns (
      address
    )
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
    returns (
      address
    )
  {
    return address(oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(
    address oracleAddress,
    bytes32 requestId
  )
    internal
    notPendingRequest(requestId)
  {
    pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(
    address ensAddress,
    bytes32 node
  )
    internal
  {
    ens = ENSInterface(ensAddress);
    ensNode = node;
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
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(
    bytes32 requestId
  )
    internal
    recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(
    bytes32 requestId
  )
  {
    require(msg.sender == pendingRequests[requestId],
            "Source must be the oracle of the request");
    delete pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(
    bytes32 requestId
  )
  {
    require(pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, ConfirmedOwner {

  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor() 
    ConfirmedOwner(msg.sender) 
  {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user)
    external
    onlyOwner()
  {
    if (!accessList[_user]) {
      accessList[_user] = true;

      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user)
    external
    onlyOwner()
  {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
    external
    onlyOwner()
  {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
    external
    onlyOwner()
  {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  )
    internal
    pure
    returns (
      Chainlink.Request memory
    )
  {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(
    Request memory self,
    bytes memory data
  )
    internal
    pure
  {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  )
    internal
    pure
  {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {

  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(
    bytes32 indexed node,
    bytes32 indexed label,
    address owner
  );

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(
    bytes32 indexed node,
    address owner
  );

  // Logged when the resolver for a node changes.
  event NewResolver(
    bytes32 indexed node,
    address resolver
  );

  // Logged when the TTL of a node changes
  event NewTTL(
    bytes32 indexed node,
    uint64 ttl
  );


  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address _owner
  ) external;

  function setResolver(
    bytes32 node,
    address _resolver
  ) external;

  function setOwner(
    bytes32 node,
    address _owner
  ) external;

  function setTTL(
    bytes32 node,
    uint64 _ttl
  ) external;

  function owner(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function resolver(
    bytes32 node
  )
    external
    view
    returns (
      address
    );

  function ttl(
    bytes32 node
  )
    external
    view
    returns (
      uint64
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {

  function requestOracleData(
    address sender,
    uint256 payment,
    bytes32 specId,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  )
    external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  )
    external
    returns (
      bool
    );

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function distributeFunds(
    address payable[] calldata receivers,
    uint[] calldata amounts
  )
    external
    payable;

  function getAuthorizedSenders()
    external
    returns (
      address[] memory
    );

  function setAuthorizedSenders(
    address[] calldata senders
  ) external;

  function getForwarder()
    external
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  
  function getAddress()
    external
    view
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(
    bytes32 node
  )
    public
    view
    virtual
    returns (
      address
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.19;

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

  function encodeType(
    BufferChainlink.buffer memory buf,
    uint8 major,
    uint value
  )
    private
    pure
  {
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

  function encodeIndefiniteLengthType(
    BufferChainlink.buffer memory buf,
    uint8 major
  )
    private
    pure
  {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(
    BufferChainlink.buffer memory buf,
    uint value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_INT, value);
  }

  function encodeInt(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
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

  function encodeBytes(
    BufferChainlink.buffer memory buf,
    bytes memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_BYTES, value.length);
    buf.append(value);
  }

  function encodeBigNum(
    BufferChainlink.buffer memory buf,
    int value
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(value)));
  }

  function encodeSignedBigNum(
    BufferChainlink.buffer memory buf,
    int input
  )
    internal
    pure
  {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint(-1 - input)));
  }

  function encodeString(
    BufferChainlink.buffer memory buf,
    string memory value
  )
    internal
    pure
  {
    encodeType(buf, MAJOR_TYPE_STRING, bytes(value).length);
    buf.append(bytes(value));
  }

  function startArray(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(
    BufferChainlink.buffer memory buf
  )
    internal
    pure
  {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function init(
    buffer memory buf,
    uint capacity
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function fromBytes(
    bytes memory b
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(
    buffer memory buf,
    uint capacity
  )
    private
    pure
  {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(
    uint a,
    uint b
  )
    private
    pure
    returns(
      uint
    )
  {
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
  function truncate(
    buffer memory buf
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function write(
    buffer memory buf,
    uint off,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
    unchecked {
      uint mask = (256 ** (32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
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
  function append(
    buffer memory buf,
    bytes memory data,
    uint len
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, data, len);
  }

  /**
  * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function append(
    buffer memory buf,
    bytes memory data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function writeUint8(
    buffer memory buf,
    uint off,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function appendUint8(
    buffer memory buf,
    uint8 data
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
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
  function write(
    buffer memory buf,
    uint off,
    bytes32 data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint mask = (256 ** len) - 1;
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
  function writeBytes20(
    buffer memory buf,
    uint off,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, off, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chhaining.
  */
  function appendBytes20(
    buffer memory buf,
    bytes20 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
  * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
  *      the capacity of the buffer.
  * @param buf The buffer to append to.
  * @param data The data to append.
  * @return The original buffer, for chaining.
  */
  function appendBytes32(
    buffer memory buf,
    bytes32 data
  )
    internal
    pure
    returns (
      buffer memory
    )
  {
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
  function writeInt(
    buffer memory buf,
    uint off,
    uint data,
    uint len
  )
    private
    pure
    returns(
      buffer memory
    )
  {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint mask = (256 ** len) - 1;
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
  function appendInt(
    buffer memory buf,
    uint data,
    uint len
  )
    internal
    pure
    returns(
      buffer memory
    )
  {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  )
    external
    returns (
      bool
    );

  function isAuthorizedSender(
    address node
  )
    external
    view
    returns (
      bool
    );

  function withdraw(
    address recipient,
    uint256 amount
  ) external;

  function withdrawable()
    external
    view
    returns (
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}