// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
// import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser, PredictionResponse } from "./DataStructures.sol";

import { ISwapAI } from "./interfaces/ISwapAI.sol";
import { OracleMaster } from "./OracleMaster.sol";
import { TokenSwapper } from "./TokenSwapper.sol";

// contract SwapAI is ISwapAI, KeeperCompatibleInterface {
contract SwapAI is ISwapAI {
  address[] private userAddresses;
  mapping(address => SwapUser) private userData;

  address private oracleMasterAddr;
  address private tokenSwapperAddr;

  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(
    address _tusdTokenAddr, address _wbtcTokenAddr,
    address _oracleMasterAddr, address _tokenSwapperAddr
  ) public {
    tusdTokenAddr = _tusdTokenAddr;
    wbtcTokenAddr = _wbtcTokenAddr;

    oracleMasterAddr = _oracleMasterAddr;
    tokenSwapperAddr = _tokenSwapperAddr;
  }

  // /**
  // * Use an interval in seconds and a timestamp to slow execution of Upkeep
  // */
  // uint public immutable interval;
  // uint public lastTimeStamp;

  // constructor(uint updateInterval) public {
  //   interval = updateInterval;
  //   lastTimeStamp = block.timestamp;
  // }

  ///////////////////////////
  // User register / login //
  ///////////////////////////

  function userExists() external override {
    bool exists = userData[msg.sender].exists;
    emit UserExists(exists);
  }

  function registerUser() external override {
    SwapUser storage user = userData[msg.sender];
    bool isNewUser;

    if (!user.exists) {
      user.exists = true;

      userAddresses.push(msg.sender);
      isNewUser = true;
    } else {
      isNewUser = false;
    }

    emit RegisterUser(true, isNewUser);
  }

  /////////////////////
  // User Attributes //
  /////////////////////

  function fetchUserBalance() external override {
    emit UserBalance(
      userData[msg.sender].tusdBalance,
      userData[msg.sender].wbtcBalance
    );
  }

  function fetchOptInStatus() external override {
    emit OptInStatus(userData[msg.sender].optInStatus);
  }

  /////////////////////
  // User management //
  /////////////////////

  function setOptInStatus(bool newOptInStatus) external override {
    userData[msg.sender].optInStatus = newOptInStatus;
    emit OptInStatus(userData[msg.sender].optInStatus);
  }

  ////////////////////////
  // Internal functions //
  ////////////////////////

  function _isAtleastOneUserOptIn() private view returns (bool) {
    for (uint i = 0; i < userAddresses.length; i++)
      if (userData[userAddresses[i]].optInStatus)
        return true;

    return false;
  }

  ////////////////////////
  // Balance depositing //
  ////////////////////////

  function depositTUSD(uint depositAmount) external override {
    // First transfer the token amount to the SwapAI contract
    require(
      IERC20(tusdTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "DEPOSIT_TUSD_TO_SWAPAI_FAIL"
    );

    // Then transfer the token amount to the token swapper contract
    require(
      IERC20(tusdTokenAddr).approve(address(this), depositAmount),
      "APPROVE_TUSD_TOKENSWAP_FAIL"
    );

    require(
      IERC20(tusdTokenAddr).transferFrom(address(this), tokenSwapperAddr, depositAmount),
      "TRANSFER_TUSD_TOKENSWAP_FAIL"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldTUSDBalance = user.tusdBalance;
    user.tusdBalance = oldTUSDBalance + depositAmount;

    emit DepositTUSD(oldTUSDBalance, user.tusdBalance);
  }

  function depositWBTC(uint depositAmount) external override {
    // First transfer the token amount to the SwapAI contract
    require(
      IERC20(wbtcTokenAddr).transferFrom(msg.sender, address(this), depositAmount),
      "DEPOSIT_WBTC_TO_SWAPAI_FAIL"
    );

    // Then transfer the token amount to the token swapper contract
    require(
      IERC20(wbtcTokenAddr).approve(address(this), depositAmount),
      "APPROVE_WBTC_TOKENSWAP_FAIL"
    );

    require(
      IERC20(wbtcTokenAddr).transferFrom(address(this), tokenSwapperAddr, depositAmount),
      "TRANSFER_WBTC_TOKENSWAP_FAIL"
    );

    SwapUser storage user = userData[msg.sender];
    uint oldWBTCBalance = user.wbtcBalance;
    user.wbtcBalance = oldWBTCBalance + depositAmount;

    emit DepositWBTC(oldWBTCBalance, user.wbtcBalance);
  }

  /////////////////////////////
  // Manual balance swapping //
  /////////////////////////////

  function _attemptSwapToWBTC(SwapUser storage user) internal {
    SwapUser memory _tmpUser = TokenSwapper(tokenSwapperAddr).swapToWBTC(user);
    user.wbtcBalance = _tmpUser.wbtcBalance;
    user.tusdBalance = _tmpUser.tusdBalance;
  }

  function manualSwapUserToWBTC() external override {
    SwapUser storage currentUser = userData[msg.sender];

    uint oldWbtcBalance = currentUser.wbtcBalance;
    uint oldTusdBalance = currentUser.tusdBalance;

    _attemptSwapToWBTC(currentUser);

    uint newWbtcBalance = currentUser.wbtcBalance;
    uint newTusdBalance = currentUser.tusdBalance;

    emit ManualSwap(
      oldWbtcBalance, newWbtcBalance,
      oldTusdBalance, newTusdBalance
    );
  }

  function _attemptSwapToTUSD(SwapUser storage user) internal {
    SwapUser memory _tmpUser = TokenSwapper(tokenSwapperAddr).swapToTUSD(user);
    user.wbtcBalance = _tmpUser.wbtcBalance;
    user.tusdBalance = _tmpUser.tusdBalance;
  }

  function manualSwapUserToTUSD() external override {
    SwapUser storage currentUser = userData[msg.sender];

    uint oldWbtcBalance = currentUser.wbtcBalance;
    uint oldTusdBalance = currentUser.tusdBalance;

    _attemptSwapToTUSD(currentUser);

    uint newWbtcBalance = currentUser.wbtcBalance;
    uint newTusdBalance = currentUser.tusdBalance;

    emit ManualSwap(
      oldWbtcBalance, newWbtcBalance,
      oldTusdBalance, newTusdBalance
    );
  }

  ////////////////////////////
  // Prediction forecasting //
  ////////////////////////////

  function fetchPredictionForecast() external override {
    OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processPredictionResults.selector);
  }

  function _processPredictionResults(PredictionResponse memory res) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(res);

    emit PredictionResults(
      res.btcPriceCurrent,
      res.btcPricePrediction,
      res.tusdAssetsAmt,
      res.tusdReservesAmt,
      res.btcSentiment,

      isNegativeFuture,
      isPositiveFuture
    );
  }

  function _analyzeResults(PredictionResponse memory res) public pure returns (bool, bool) {
    uint btcPriceOffset = (res.btcPricePrediction - res.btcPriceCurrent);

    // We want to check within +/- 5%, hence we"ll multiply current price by 1 / 20
    uint percentModifier = 20;
    uint btcPriceTolerance = res.btcPriceCurrent / percentModifier;

    // 10000 means 1:1 asset:reserve ratio, less means $ assets > $ reserves
    // TODO:
    // bool isInsufficientTUSDRatio = tusdRatio < 9999;
    bool isNegativeBTCSentiment = res.btcSentiment < -5000; // -5000 means -0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingDown = btcPriceOffset < -btcPriceTolerance; // check for > 5% decrease
    bool isNegativeFuture = /*isInsufficientTUSDRatio ||*/ isNegativeBTCSentiment || isBTCPriceGoingDown;

    // bool isSufficientTUSDRatio = tusdRatio >= 10000;
    bool isPositiveBTCSentiment = res.btcSentiment > 5000; // 5000 means 0.5 sentiment from range [-1,1]
    bool isBTCPriceGoingUp = btcPriceOffset > btcPriceTolerance; // check for > 5% increase
    bool isPositiveFuture = /*isSufficientTUSDRatio &&*/ isPositiveBTCSentiment && isBTCPriceGoingUp;

    return (isNegativeFuture, isPositiveFuture);
  }

  ////////////////////////////////
  // Automatic balance swapping //
  ////////////////////////////////

  // NOTE: This should only be called by the Keeper
  function smartSwapAllBalances() external override {
    OracleMaster(oracleMasterAddr).executeAnalysis(address(this), this._processAnalysisAuto.selector);
  }

  // SECURITY RISK!!!
  // TODO: This poses a security risk where anyone can call this function and trigger an auto-swap
  // at will. This needs to be patched ASAP
  function _processAnalysisAuto(PredictionResponse memory res) public {
    bool isNegativeFuture;
    bool isPositiveFuture;

    (isNegativeFuture, isPositiveFuture) = _analyzeResults(res);

    for (uint i = 0; i < userAddresses.length; i++) {
      address userAddr = userAddresses[i];
      SwapUser storage user = userData[userAddr];

      if (user.optInStatus) {
        if (isPositiveFuture) {
          // Swap from TUSD in favor of WBTC to capitalize on gains
          _attemptSwapToWBTC(user);
        } else if (isNegativeFuture) {
          // Swap from WBTC in favor of TUSD to minimize losses
          _attemptSwapToTUSD(user);
        }
        // Otherwise do nothing
      }
    }

    emit PredictionResults(
      res.btcPriceCurrent,
      res.btcPricePrediction,
      res.tusdAssetsAmt,
      res.tusdReservesAmt,
      res.btcSentiment,

      isNegativeFuture,
      isPositiveFuture
    );
  }

  ////////////////////////////
  // Chainlink Keeper Logic //
  ////////////////////////////

  // function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
  //   bool hasIntervalPassed = (block.timestamp - lastTimeStamp) > interval;
  //   upkeepNeeded = hasIntervalPassed && _isAtleastOneUserOptIn();
  //   return (upkeepNeeded, bytes(""));
  //   // We don"t use the checkData in this example. The checkData is defined when the Upkeep was registered.
  // }

  // function performUpkeep(bytes calldata /* performData */) external override {
  //   lastTimeStamp = block.timestamp;
  //   swapAllUsersBalances(false);
  //   // We don"t use the performData in this example. The performData is generated by the Keeper"s call to your checkUpkeep function
  // }
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
pragma solidity ^0.6.12;

library Constants {
  address public constant SUSHIV2_FACTORY_ADDRESS = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
  address public constant SUSHIV2_ROUTER02_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

  address public constant VRF_COORDINATOR_ADDRESS = 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9;
  bytes32 public constant VRF_KEY_HASH = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;

  address public constant KOVAN_LINK_TOKEN = 0xa36085F69e2889c224210F603D836748e7dC0088;

  uint public constant ONE_TENTH_LINK_PAYMENT = 0.1 * 1 ether;
  uint public constant ONE_LINK_PAYMENT = 1 ether;

  uint public constant TUSD_MULT_AMT = 10 ** 7;

  ////////////////////////
  // Oracle information //
  ////////////////////////

  address public constant BTC_USD_PRICE_FEED_ADDR = 0x6135b13325bfC4B00278B4abC5e20bbce2D6580e;

  address public constant PRICE_ORACLE_ADDR = 0xfF07C97631Ff3bAb5e5e5660Cdf47AdEd8D4d4Fd;
  bytes32 public constant PRICE_JOB_ID = "35e14dbd490f4e3b9fbe92b85b32d98a";

  address public constant HTTP_GET_ORACLE_ADDR = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
  bytes32 public constant HTTP_GET_JOB_ID = "d5270d1c311941d0b08bead21fea7747";
  string public constant TUSD_URL = "https://core-api.real-time-attest.trustexplorer.io/trusttoken/TrueUSD";

  address public constant SENTIMENT_ORACLE_ADDR = 0x56dd6586DB0D08c6Ce7B2f2805af28616E082455;
  bytes32 public constant SENTIMENT_JOB_ID = "e7beed14d06d477192ef30edc72557b1";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

struct SwapUser {
  // The 'exists' attribute is used purely for checking if a user exists. This works
  // since when you instantiate a new SwapUser, the default value is 'false'
  bool exists;

  uint tusdBalance;
  uint wbtcBalance;
  bool optInStatus;
}

struct PredictionResponse {
  uint btcPriceCurrent;
  uint btcPricePrediction;
  uint tusdAssetsAmt;
  uint tusdReservesAmt;
  int btcSentiment;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SwapUser } from "../DataStructures.sol";

interface ISwapAI {
  // User register / login
  function userExists() external;
  function registerUser() external;

  event UserExists(bool userExists);
  event RegisterUser(bool success, bool isNewUser);

  // User attributes
  function fetchUserBalance() external;
  function fetchOptInStatus() external;

  event UserBalance(uint tusdBalance, uint wbtcBalance);
  event OptInStatus(bool optInStatus);

  // User management
  function setOptInStatus(bool newOptInStatus) external;

  // Balance depositing
  function depositTUSD(uint depositAmount) external;
  function depositWBTC(uint depositAmount) external;

  event DepositTUSD(uint oldAmount, uint newAmount);
  event DepositWBTC(uint oldAmount, uint newAmount);

  // Manual balance swapping
  function manualSwapUserToWBTC() external;
  function manualSwapUserToTUSD() external;

  event ManualSwap(
    uint oldWbtcBalance, uint newWbtcBalance,
    uint oldTusdBalance, uint newTusdBalance
  );

  // Prediction forecasting
  function fetchPredictionForecast() external;

  event PredictionResults(
    uint btcPriceCurrent,
    uint btcPricePrediction,
    uint tusdAssets,
    uint tusdReserves,
    int btcSentiment,

    bool isNegativeFuture,
    bool isPositiveFuture
  );

  // Automatic balance swapping
  function smartSwapAllBalances() external;

  event AutoSwap(
    uint btcPriceCurrent,
    uint btcPricePrediction,
    uint tusdAssets,
    uint tusdReserves,
    int btcSentiment,

    bool isNegativeFuture,
    bool isPositiveFuture
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { Chainlink } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { PredictionResponse } from "./DataStructures.sol";

import { OracleAggregator } from "./utility/OracleAggregator.sol";
import { OracleJob } from "./utility/OracleJob.sol";
import { JobBuilder } from "./utility/JobBuilder.sol";

// import { PseudoRandom } from "./utility/PseudoRandom.sol";

// Chainlink oracle code goes here
contract OracleMaster is OracleAggregator {
  using JobBuilder for OracleJob;

  PredictionResponse private res;
  address private cbAddress;
  bytes4 private cbFunction;

  constructor() public {
    setChainlinkToken(Constants.KOVAN_LINK_TOKEN);
  }

  function generateRandom(uint max) public view returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
      block.timestamp + block.difficulty +
      ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
      block.gaslimit +
      ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
      block.number
    )));

    return (seed - ((seed / max) * max));
  }

  function executeAnalysis(address callbackAddress, bytes4 callbackFunc) external {
    cbAddress = callbackAddress;
    cbFunction = callbackFunc;

    _startPredictionAnalysis();
  }

  function _isResponseReady(PredictionResponse memory _res) private pure returns (bool) {
    return /*_res.btcPriceCurrent != 0 &&*/
      _res.tusdAssetsAmt != 0 &&
      _res.tusdReservesAmt != 0 /*&&
      _res.btcSentiment != 0*/;
  }

  function checkResponse(PredictionResponse memory _res) private {
    if (_isResponseReady(_res)) {
      // Call the callback function on the callback contract address
      bytes memory data = abi.encodeWithSelector(cbFunction, res);
      (bool success,) = cbAddress.delegatecall(data);
      require(success, "Unable to submit OracleMaster results to callback");
    }
  }

  function _startPredictionAnalysis() private {
    /////////////////////////////
    // Fetch current BTC price //
    /////////////////////////////

    AggregatorV3Interface priceFeed = AggregatorV3Interface(Constants.BTC_USD_PRICE_FEED_ADDR);
    (,int btcCurrentPrice,,,) = priceFeed.latestRoundData();

    res.btcPriceCurrent = uint(btcCurrentPrice);

    //////////////////////////////////////
    // Prepare BTC price prediction job //
    //////////////////////////////////////

    // TODO: For now, we're just (insecurely) generating some values

    // 10,000 = 100.00%
    // 1,000  = 10.00%
    // 100    = 1.00%
    // 10     = 0.10%
    // 1      = 0.01%

    uint _randBtcPredictRaw = generateRandom(2000);
    int percentMod = int(_randBtcPredictRaw) - 1000;
    int priceMod = int(btcCurrentPrice) * percentMod / 10000;
    res.btcPricePrediction = uint(btcCurrentPrice + priceMod);

    // NOTE: Commented out since there's no equivalent on Kovan testnet

    // OracleJob memory btcPricePredictionJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.PRICE_ORACLE_ADDR,
    //     Constants.PRICE_JOB_ID,
    //     Constants.ONE_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getBTCPricePrediction.selector
    //   );

    // btcPricePredictionJob.request.add("endpoint", "price");
    // btcPricePredictionJob.request.add("symbol", "BTC");
    // btcPricePredictionJob.request.add("days", "1");

    /////////////////////////////
    // Prepare TUSD assets job //
    /////////////////////////////

    OracleJob memory tusdAssetsJob = super
      .createJob()
      .setOracle(
        Constants.HTTP_GET_ORACLE_ADDR,
        Constants.HTTP_GET_JOB_ID,
        Constants.ONE_TENTH_LINK_PAYMENT
      )
      .withCallback(
        address(this),
        this.getTusdAssets.selector
      );

    Chainlink.Request memory tusdAssetsReq;
    tusdAssetsReq.add("get", Constants.TUSD_URL);
    tusdAssetsReq.add("path", "responseData.totalToken");
    tusdAssetsReq.addInt("times", int(Constants.TUSD_MULT_AMT));
    tusdAssetsJob.request = tusdAssetsReq;

    ///////////////////////////////
    // Prepare TUSD reserves job //
    ///////////////////////////////

    OracleJob memory tusdReservesJob = super
      .createJob()
      .setOracle(
        Constants.HTTP_GET_ORACLE_ADDR,
        Constants.HTTP_GET_JOB_ID,
        Constants.ONE_TENTH_LINK_PAYMENT
      )
      .withCallback(
        address(this),
        this.getTusdReserves.selector
      );

    Chainlink.Request memory tusdReservesReq;
    tusdReservesReq.add("get", Constants.TUSD_URL);
    tusdReservesReq.add("path", "responseData.totalTrust");
    tusdReservesReq.addInt("times", int(Constants.TUSD_MULT_AMT));
    tusdReservesJob.request = tusdReservesReq;

    ///////////////////////////////////////
    // Prepare BTC sentiment analyis job //
    ///////////////////////////////////////

    // TODO: For now, we're just (insecurely) generating some values

    uint _randBtcSentimentRaw = generateRandom(20000);
    res.btcSentiment = int(_randBtcSentimentRaw) - 10000;

    // NOTE: Commented out since there's no equivalent on Kovan testnet

    // OracleJob memory btcSentimentJob = super
    //   .createJob()
    //   .setOracle(
    //     Constants.SENTIMENT_ORACLE_ADDR,
    //     Constants.SENTIMENT_JOB_ID,
    //     Constants.ONE_TENTH_LINK_PAYMENT
    //   )
    //   .withCallback(
    //     address(this),
    //     this.getBTCSentiment.selector
    //   );

    // btcSentimentJob.request.add("endpoint", "crypto-sentiment");
    // btcSentimentJob.request.add("token", "BTC");
    // btcSentimentJob.request.add("period", "24");

    /////////////////////////////
    // Execute all oracle jobs //
    /////////////////////////////

    // super.executeJob(btcPricePredictionJob);
    super.executeJob(tusdAssetsJob);
    super.executeJob(tusdReservesJob);
    // super.executeJob(btcSentimentJob);
  }

  ///////////////////////////
  // Fulfillment Functions //
  ///////////////////////////

  // function getBTCPricePrediction(bytes32 _requestID, uint _btcPricePrediction) public recordChainlinkFulfillment(_requestID) {
  //   res.btcPricePrediction = _btcPricePrediction;
  //   checkResponse(res);
  // }

  event UintLog(uint value);

  function getTusdAssets(bytes32 _requestID, uint _tusdAssetsAmt) public recordChainlinkFulfillment(_requestID) {
    emit UintLog(_tusdAssetsAmt);
    res.tusdAssetsAmt = _tusdAssetsAmt;
    checkResponse(res);
  }

  function getTusdReserves(bytes32 _requestID, uint _tusdReservesAmt) public recordChainlinkFulfillment(_requestID) {
    emit UintLog(_tusdReservesAmt);
    res.tusdReservesAmt = _tusdReservesAmt;
    checkResponse(res);
  }

  // function getBTCSentiment(bytes32 _requestID, int _btcSentiment) public recordChainlinkFulfillment(_requestID) {
  //   res.btcSentiment = _btcSentiment;
  //   checkResponse(res);
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// 3rd-party library imports
import { IUniswapV2Router02 } from "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 1st-party project imports
import { Constants } from "./Constants.sol";
import { SwapUser } from "./DataStructures.sol";

contract TokenSwapper {
  address private tusdTokenAddr;
  address private wbtcTokenAddr;

  constructor(address _tusdTokenAddr, address _wbtcTokenAddr) public {
    tusdTokenAddr = _tusdTokenAddr;
    wbtcTokenAddr = _wbtcTokenAddr;
  }

  /*
   * Generic function to approve and perform swap from starting to ending token
   */
  function _swapTokens(uint _inputAmt, address[] memory _tokenPath) internal returns (uint) {
    // First get approval to transfer from starting to ending token via the router
    require(
      IERC20(_tokenPath[0]).approve(Constants.SUSHIV2_ROUTER02_ADDRESS, _inputAmt),
      "APPROVE_SWAP_START_TOKEN_FAIL"
    );

    IUniswapV2Router02 swapRouter = IUniswapV2Router02(
      Constants.SUSHIV2_ROUTER02_ADDRESS
    );

    // Finally, perform the swap from starting to ending token via the token path specified
    uint[] memory swappedAmts = swapRouter.swapExactTokensForTokens(
      _inputAmt,       // amount in terms of starting token
      1,               // min amount expected in terms of ending token
      _tokenPath,      // path of swapping from starting to ending token
      address(this),   // address of where the starting & ending token assets are/will be held
      block.timestamp  // expiry time for transaction
    );

    return swappedAmts[swappedAmts.length - 1];
  }

  /*
   * Swapping TUSD -> BTC (WBTC)
   */
  function swapToWBTC(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.tusdBalance > 0, "USER_SWAP_TUSD_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = tusdTokenAddr;
    path[1] = wbtcTokenAddr;

    uint addedWbtcBalance = _swapTokens(_user.tusdBalance, path);

    _user.tusdBalance = 0;
    _user.wbtcBalance += addedWbtcBalance;

    return _user;
  }

  /*
   * Swapping BTC (WBTC) -> TUSD
   */
  function swapToTUSD(SwapUser memory _user) external returns (SwapUser memory) {
    require(_user.wbtcBalance > 0, "USER_SWAP_WBTC_NOT_FOUND");

    // HACK: This form of array initialization is used to bypass a type cast error
    address[] memory path = new address[](2);
    path[0] = wbtcTokenAddr;
    path[1] = tusdTokenAddr;

    uint addedTusdBalance = _swapTokens(_user.wbtcBalance, path);

    _user.tusdBalance += addedTusdBalance;
    _user.wbtcBalance = 0;

    return _user;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
pragma solidity ^0.6.12;

// 3rd-party library imports
import { ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

// 1st-party project imports
import { OracleJob } from "./OracleJob.sol";
import { JobBuilder } from "./JobBuilder.sol";

contract OracleAggregator is ChainlinkClient {
  using JobBuilder for OracleJob;

  //////////////////////
  // Real oracle jobs //
  //////////////////////

  function createJob() internal pure returns (OracleJob memory) {
    OracleJob memory job;
    job.initialize();
    return job;
  }

  function executeJob(
    OracleJob memory job
  ) internal {
    // NOTE: Equivalent to buildChainlinkRequest()
    job.request.initialize(job.specId, job.cbAddress, job.cbFunction);

    super.sendChainlinkRequestTo(job.oracleAddress, job.request, job.fee);
  }

  // //////////////////////
  // // Mock oracle jobs //
  // //////////////////////

  // function createMockJob() internal pure returns (MockOracleJob memory) {
  //   MockOracleJob memory mjob;
  //   mjob.initialize();
  //   return mjob;
  // }

  // function executeMockJob(
  //   OracleJob memory job
  // ) internal {
  //   // NOTE: Equivalent to buildChainlinkRequest()
  //   job.request.initialize(job.specId, job.cbAddress, job.cbFunction);

  //   super.sendChainlinkRequestTo(job.oracleAddress, job.request, job.fee);
  // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { Chainlink } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

struct OracleJob {
  address oracleAddress;
  bytes32 specId;
  uint256 fee;
  address cbAddress;
  bytes4 cbFunction;

  Chainlink.Request request;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// 3rd-party library imports
import { Chainlink, ChainlinkClient } from "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import { BufferChainlink } from "@chainlink/contracts/src/v0.6/vendor/BufferChainlink.sol";

// 1st-party library imports
import { OracleJob } from "./OracleJob.sol";

library JobBuilder {
  // Copied from @chainlink/contracts/src/v0.6/Chainlink.sol
  uint256 internal constant REQ_DEFAULT_BUFFER_SIZE = 256;

  using Chainlink for Chainlink.Request;

  function initialize(
    OracleJob memory self
  ) internal pure returns (OracleJob memory) {
    BufferChainlink.init(self.request.buf, REQ_DEFAULT_BUFFER_SIZE);
  }

  function setOracle(
    OracleJob memory self,
    address oracleAddress,
    bytes32 specId,
    uint256 fee
  ) internal pure returns (OracleJob memory) {
    self.oracleAddress = oracleAddress;
    self.specId = specId;
    self.fee = fee;
    return self;
  }

  function withCallback(
    OracleJob memory self,
    address cbAddress,
    bytes4 cbFunction
  ) internal pure returns (OracleJob memory) {
    self.cbAddress = cbAddress;
    self.cbFunction = cbFunction;
    return self;
  }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}