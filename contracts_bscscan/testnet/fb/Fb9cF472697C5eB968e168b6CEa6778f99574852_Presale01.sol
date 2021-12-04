// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

/**
  Allows a decentralised presale to take place, and on success creates an AMM pair and locks liquidity on Unicrypt.
  B_TOKEN, or base token, is the token the presale attempts to raise. (Usally ETH).
  S_TOKEN, or sale token, is the token being sold, which investors buy with the base token.
  If the base currency is set to the WETH9 address, the presale is in ETH.
  Otherwise it is for an ERC20 token - such as DAI, USDC, WBTC etc.
  For the Base token - It is advised to only use tokens such as ETH (WETH), DAI, USDC or tokens that have no rebasing, or complex fee on transfers. 1 token should ideally always be 1 token.
  Token withdrawls are done on a percent of total contribution basis (opposed to via a hardcoded 'amount'). This allows 
  fee on transfer, rebasing, or any magically changing balances to still work for the Sale token.
*/

pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPresaleLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function uniswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface ITokenVesting {
    struct LockParams {
      address payable owner; // the user who can withdraw tokens once the lock expires.
      uint256 amount; // amount of tokens to lock
      uint256 startEmission; // 0 if lock type 1, else a unix timestamp
      uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
      address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }
    function lock (address _token, LockParams[] calldata _lock_params) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getRound1Length () external view returns (uint256);
    function getRound0Offset () external view returns (uint256);
    function userHoldsSufficientRound1Token (address _user) external view returns (bool);
    function referrerIsValid(address _referrer) external view returns (bool);
    function getReferrer01() external view returns (address);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getNonEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getReferralFee () external view returns (uint256);
    function getReferralSplitFee () external view returns (uint256);
    function getEthCreationFee () external view returns (uint256);
    function getUNCLInfo () external view returns (address, uint256, address);
    function getWhitelistPercentage () external view returns (uint128);
    function getUNCLPercentage () external view returns (uint128);
    function getMinimumParticipants () external view returns (uint128);
}

contract Presale01 is ReentrancyGuard {
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
  uint16 public CONTRACT_VERSION = 6;
  
  struct PresaleInfo {
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of presale tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT; // divided by 1000
    uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
    uint256 START_BLOCK;
    uint256 END_BLOCK;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
  }

  struct PresaleInfo2 {
    address payable PRESALE_OWNER;
    bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
    uint16 COUNTRY_CODE;
    uint128 UNCL_MAX_PARTICIPANTS; // max number of UNCL reserve allocation participants
    uint128 UNCL_PARTICIPANTS; // number of uncl reserve allocation participants
    uint128 WHITELIST_MAX_PARTICIPANTS; // max number of whitelist participants
    uint128 WHITELIST_ASSIGNED; //actual number of assigned whitelisted spots, this is overwritten with the enumerable set WHITELIST in getInfo
  }
  
  struct PresaleFeeInfo {
    uint256 UNICRYPT_BASE_FEE; // divided by 1000
    uint256 UNICRYPT_TOKEN_FEE; // divided by 1000
    uint256 REFERRAL_FEE; // divided by 1000
    address payable REFERRAL_1;
    address payable REFERRAL_2;
  }
  
  struct PresaleStatus {
    bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the presale
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
    uint256 ROUND1_LENGTH; // in blocks
    uint256 ROUND_0_START;
    uint256 NUM_BUYERS; // number of unique participants
    uint256 PRESALE_END_DATE; // Set once LP GENERATION is complete.
  }

  struct PresaleVesting {
    bool REQUEST_VESTING; // a flag set on creation indicating the developer requested tokenVesting on presale participants
    bool IMPLEMENT_VESTING; // a flag set by Unicrypt Developers to enfoce vesting
    bool LINEAR_LOCK; // is the lock linear ? else a normal cliff lock
    uint256 VESTING_START_EMISSION; // 0 for cliff locks or added onto PRESALE_END_DATE
    uint256 VESTING_END_EMISSION; // added onto PRESALE_END_DATE
    uint256 VESTING_PERCENTAGE; // the percentage of a users tokens vested
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
    uint256 unclOwed; // num uncl owed if user used UNCL for pre-allocation
  }

  struct WhitelistPager {
    address userAddress; // the address of the whitelisted user
    uint256 baseDeposited; // the amount the user has contributed to the presale
  }
  
  PresaleInfo public PRESALE_INFO;
  PresaleInfo2 public PRESALE_INFO_2;
  PresaleFeeInfo public PRESALE_FEE_INFO;
  PresaleStatus public STATUS;
  PresaleVesting public PRESALE_VESTING;

  address public PRESALE_GENERATOR;
  IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
  IPresaleSettings public PRESALE_SETTINGS;
  address UNICRYPT_DEV_ADDRESS;
  IUniswapV2Factory public UNI_FACTORY;
  IWETH public WETH;
  ITokenVesting public TOKEN_VESTING;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private WHITELIST;
  uint public UNCL_AMOUNT_OVERRIDE;
  uint public UNCL_BURN_ON_FAIL; // amount of UNCL to burn on failed presale

  constructor(address _presaleGenerator, IPresaleSettings _presaleSettings, address _tokenVesting, address _weth) {
    PRESALE_GENERATOR = _presaleGenerator;
    PRESALE_SETTINGS = _presaleSettings;
    WETH = IWETH(_weth);
    TOKEN_VESTING = ITokenVesting(_tokenVesting);
    UNI_FACTORY = IUniswapV2Factory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(0x46ae2bE0585e7f03d7A22411a76C0fd5CD24FCc3);
    UNICRYPT_DEV_ADDRESS = 0xAA3d85aD9D128DFECb55424085754F6dFa643eb1;
  }
  
  function init1 (
    uint16 _countryCode,
    uint256 _amount,
    uint256 _tokenPrice,
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _roundZeroStart,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      require(_softcap >= _hardcap / 4, 'SOFTCAP TOO LOW');
      require(_hardcap / _maxEthPerBuyer >= PRESALE_SETTINGS.getMinimumParticipants(), 'ALLOCATION TOO HIGH');
      PRESALE_INFO_2.COUNTRY_CODE = _countryCode;
      PRESALE_INFO.AMOUNT = _amount;
      PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
      PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      PRESALE_INFO.HARDCAP = _hardcap;
      PRESALE_INFO.SOFTCAP = _softcap;
      PRESALE_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      PRESALE_INFO.LISTING_RATE = _listingRate;
      PRESALE_INFO.START_BLOCK = _startblock;
      PRESALE_INFO.END_BLOCK = _endblock;
      PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
      PRESALE_INFO_2.UNCL_MAX_PARTICIPANTS = uint128(_hardcap / _maxEthPerBuyer * PRESALE_SETTINGS.getUNCLPercentage() / 100);
      PRESALE_INFO_2.WHITELIST_MAX_PARTICIPANTS = uint128(_hardcap / _maxEthPerBuyer * PRESALE_SETTINGS.getWhitelistPercentage() / 100);
      if (_roundZeroStart < block.number + PRESALE_SETTINGS.getRound0Offset()) {
        STATUS.ROUND_0_START = block.number + PRESALE_SETTINGS.getRound0Offset();
      } else {
        STATUS.ROUND_0_START = _roundZeroStart;
      }

      if (PRESALE_INFO.START_BLOCK < STATUS.ROUND_0_START) {
        PRESALE_INFO.START_BLOCK = STATUS.ROUND_0_START + PRESALE_SETTINGS.getRound0Offset();
        PRESALE_INFO.END_BLOCK = PRESALE_INFO.START_BLOCK + (_endblock - _startblock);
      }
  }
  
  function init2 (
    address payable _presaleOwner,
    IERC20 _baseToken,
    IERC20 _presaleToken,
    uint256 _unicryptBaseFee,
    uint256 _unicryptTokenFee,
    uint256 _referralFee,
    address payable _referral_1,
    address payable _referral_2,
    bool _requestVesting
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      PRESALE_INFO_2.PRESALE_OWNER = _presaleOwner;
      PRESALE_INFO_2.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
      PRESALE_INFO.S_TOKEN = _presaleToken;
      PRESALE_INFO.B_TOKEN = _baseToken;
      PRESALE_FEE_INFO.UNICRYPT_BASE_FEE = _unicryptBaseFee;
      PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE = _unicryptTokenFee;
      PRESALE_FEE_INFO.REFERRAL_FEE = _referralFee;
      
      PRESALE_FEE_INFO.REFERRAL_1 = _referral_1;
      PRESALE_FEE_INFO.REFERRAL_2 = _referral_2;
      STATUS.ROUND1_LENGTH = PRESALE_SETTINGS.getRound1Length();
      PRESALE_VESTING.REQUEST_VESTING = _requestVesting;
  }
  
  modifier onlyPresaleOwner() {
    require(PRESALE_INFO_2.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
    _;
  }

  /**
   * @notice Set Vesting params
   * @param _percentage between 0 - 100 // cannot be > 100
   */
  function setTokenVestingParams (bool _implementVesting, bool _linearLock, uint256 _startIncrement, uint256 _endIncrement, uint256 _percentage) external {
    require(msg.sender == UNICRYPT_DEV_ADDRESS, 'NOT DEV');
    require(_percentage <= 100, 'PERCENTAGE ABOVE 100');
    // Can be edited at ANY stage of the presale, including afterwards incase incorrectly configured and preventing withdrawls
    PRESALE_VESTING.IMPLEMENT_VESTING = _implementVesting;
    PRESALE_VESTING.LINEAR_LOCK = _linearLock;
    PRESALE_VESTING.VESTING_START_EMISSION = _startIncrement;
    PRESALE_VESTING.VESTING_END_EMISSION = _endIncrement;
    PRESALE_VESTING.VESTING_PERCENTAGE = _percentage;
  }

  function setUNCLAmount (uint _amount) external {
    require(msg.sender == UNICRYPT_DEV_ADDRESS, 'NOT DEV');
    UNCL_AMOUNT_OVERRIDE = _amount;
  }

  function setReferrer (address payable _referrer) external {
    require(msg.sender == UNICRYPT_DEV_ADDRESS, 'NOT DEV');
    PRESALE_FEE_INFO.REFERRAL_2 = _referrer;
  }

  function getUNCLOverride () public view returns (address, uint256) {
    (address unclAddress, uint256 unclAmount,) = PRESALE_SETTINGS.getUNCLInfo();
    unclAmount = UNCL_AMOUNT_OVERRIDE == 0 ? unclAmount : UNCL_AMOUNT_OVERRIDE;
    return (unclAddress, unclAmount);
  }

  function getElapsedSinceRound1 () external view returns (int) {
    return int(block.number) - int(PRESALE_INFO.START_BLOCK);
  }

  function getElapsedSinceRound0 () external view returns (int) {
    return int(block.number) - int(STATUS.ROUND_0_START);
  }

  function getInfo () public view returns (uint16, PresaleInfo memory, PresaleInfo2 memory, PresaleFeeInfo memory, PresaleStatus memory, PresaleVesting memory, uint256) {
    PresaleInfo2 memory pinfo2 = PRESALE_INFO_2;
    pinfo2.WHITELIST_ASSIGNED = uint128(WHITELIST.length());
    return (CONTRACT_VERSION, PRESALE_INFO, pinfo2, PRESALE_FEE_INFO, STATUS, PRESALE_VESTING, presaleStatus());
  }
  
  function presaleStatus () public view returns (uint256) {
    return 2;
  }

  function reserveAllocationWithUNCL () external payable nonReentrant {
    require(presaleStatus() == 0, 'NOT QUED'); // ACTIVE
    require(block.number > STATUS.ROUND_0_START, 'NOT YET');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(buyer.unclOwed == 0, 'UNCL NOT ZERO');
    require(PRESALE_INFO_2.UNCL_PARTICIPANTS < PRESALE_INFO_2.UNCL_MAX_PARTICIPANTS, 'NO SLOT');
    (address unclAddress, uint256 unclAmount) = getUNCLOverride();
    TransferHelper.safeTransferFrom(unclAddress, msg.sender, address(this), unclAmount);
    uint256 unclToBurn = unclAmount / 4;
    UNCL_BURN_ON_FAIL += unclToBurn;
    buyer.unclOwed = unclAmount - unclToBurn;
    PRESALE_INFO_2.UNCL_PARTICIPANTS ++;
  }

  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable nonReentrant {
    if (presaleStatus() == 0) {
      require(BUYERS[msg.sender].unclOwed > 0 || WHITELIST.contains(msg.sender), 'NOT RESERVED');
    } else {
      require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
      bool userHoldsUnicryptTokens = PRESALE_SETTINGS.userHoldsSufficientRound1Token(msg.sender);
      if (block.number < PRESALE_INFO.START_BLOCK + STATUS.ROUND1_LENGTH) { // 276 blocks = 1 hour
        require(userHoldsUnicryptTokens, 'INSUFFICENT ROUND 1 TOKEN BALANCE');
      }
    }
    _userDeposit(_amount);
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function _userDeposit (uint256 _amount) internal {
    // DETERMINE amount_in
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 amount_in = PRESALE_INFO_2.PRESALE_IN_ETH ? msg.value : _amount;
    uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER - buyer.baseDeposited;
    uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }

    // UPDATE STORAGE
    uint256 tokensSold = amount_in * PRESALE_INFO.TOKEN_PRICE  / (10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }
    buyer.baseDeposited += amount_in;
    buyer.tokensOwed += tokensSold;
    STATUS.TOTAL_BASE_COLLECTED += amount_in;
    STATUS.TOTAL_TOKENS_SOLD += tokensSold;
    
    // FINAL TRANSFERS OUT AND IN
    // return unused ETH
    if (PRESALE_INFO_2.PRESALE_IN_ETH && amount_in < msg.value) {
      payable(msg.sender).transfer(msg.value - amount_in);
    }
    // deduct non ETH token from user
    if (!PRESALE_INFO_2.PRESALE_IN_ETH) {
      TransferHelper.safeTransferFrom(address(PRESALE_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
  }
  
  // withdraw presale tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 tokensRemainingDenominator = STATUS.TOTAL_TOKENS_SOLD - STATUS.TOTAL_TOKENS_WITHDRAWN;
    uint256 tokensOwed = PRESALE_INFO.S_TOKEN.balanceOf(address(this)) * buyer.tokensOwed / tokensRemainingDenominator;
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_TOKENS_WITHDRAWN += buyer.tokensOwed;
    buyer.tokensOwed = 0;

    if (PRESALE_VESTING.IMPLEMENT_VESTING) {
      // TOKEN VESTING
      uint256 vestAmount = tokensOwed * PRESALE_VESTING.VESTING_PERCENTAGE / 100;
      if (vestAmount >= 100) { // TokenVesting fails on amounts less than 100
        TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(TOKEN_VESTING), vestAmount);
        ITokenVesting.LockParams[] memory LP = new ITokenVesting.LockParams[](1);
        LP[0] = ITokenVesting.LockParams(
          payable(msg.sender),
          vestAmount,
          PRESALE_VESTING.LINEAR_LOCK ? STATUS.PRESALE_END_DATE + PRESALE_VESTING.VESTING_START_EMISSION : 0,
          STATUS.PRESALE_END_DATE + PRESALE_VESTING.VESTING_END_EMISSION,
          address(0)
        );
        TOKEN_VESTING.lock(address(PRESALE_INFO.S_TOKEN), LP);
        tokensOwed -= vestAmount;
      }
    }
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    require(buyer.baseDeposited > 0 || buyer.unclOwed > 0, 'NOTHING TO WITHDRAW');
    if (buyer.baseDeposited > 0) {
      uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED - STATUS.TOTAL_BASE_WITHDRAWN;
      uint256 remainingBaseBalance = PRESALE_INFO_2.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
      uint256 tokensOwed = remainingBaseBalance * buyer.baseDeposited / baseRemainingDenominator;
      require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
      STATUS.TOTAL_BASE_WITHDRAWN += buyer.baseDeposited;
      buyer.baseDeposited = 0;
      TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), payable(msg.sender), tokensOwed, !PRESALE_INFO_2.PRESALE_IN_ETH);
    }
    if (buyer.unclOwed > 0) {
      (address unclAddress,,) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, payable(msg.sender), buyer.unclOwed);
      buyer.unclOwed = 0;
    }
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlyPresaleOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_INFO_2.PRESALE_OWNER, PRESALE_INFO.S_TOKEN.balanceOf(address(this)));
  }
  
  // if something goes wrong in LP generation
  function forceFailByUnicrypt () external {
      require(msg.sender == UNICRYPT_DEV_ADDRESS);
      require(!STATUS.FORCE_FAILED);
      STATUS.FORCE_FAILED = true;
      // send UNCL to uncl burn address
      (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, unclFeeAddress, UNCL_BURN_ON_FAIL);
  }

  // Allows the owner to end a presale before a pool has been created
  function forceFailByPresaleOwner () external onlyPresaleOwner {
      require(!STATUS.LP_GENERATION_COMPLETE, 'POOL EXISTS');
      require(!STATUS.FORCE_FAILED);
      STATUS.FORCE_FAILED = true;
      (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
      TransferHelper.safeTransfer(unclAddress, unclFeeAddress, UNCL_BURN_ON_FAIL);
  }
  
  // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the presale parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    // require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(presaleStatus() == 2, 'NOT SUCCESS'); // SUCCESS

    // BYPASS BLOCK - Useful for testing
    /*
    if (presaleStatus() == 2) {
      uint256 ubf = STATUS.TOTAL_BASE_COLLECTED * PRESALE_FEE_INFO.UNICRYPT_BASE_FEE / 1000;
      uint256 utf = STATUS.TOTAL_TOKENS_SOLD * PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE / 1000;
        if (PRESALE_FEE_INFO.REFERRAL_1 != address(0)) {
          uint256 referralBaseFee = ubf * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;
          uint256 referralTokenFee = utf * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;

          if (PRESALE_FEE_INFO.REFERRAL_2 != address(0)) {
            uint256 ref2BaseFee = referralBaseFee * PRESALE_SETTINGS.getReferralSplitFee() / 100;
            TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_2, ref2BaseFee, !PRESALE_INFO_2.PRESALE_IN_ETH);
            referralBaseFee -= ref2BaseFee;

            uint256 ref2TokenFee = referralTokenFee * PRESALE_SETTINGS.getReferralSplitFee() / 100;
            TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_2, referralTokenFee);
            referralTokenFee -= ref2TokenFee;
          }
          // Base fee
          TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_1, referralBaseFee, !PRESALE_INFO_2.PRESALE_IN_ETH);
          ubf -= referralBaseFee;
          // Token fee
          TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_1, referralTokenFee);
          utf -= referralTokenFee;
      }
      STATUS.LP_GENERATION_COMPLETE = true;
      STATUS.PRESALE_END_DATE = block.timestamp;
      return;
    } */
    // BYPASS BLOCK - Useful for testing

    // Fail the presale if the pair exists and contains presale token liquidity
    if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
    }
    
    uint256 unicryptBaseFee = STATUS.TOTAL_BASE_COLLECTED * PRESALE_FEE_INFO.UNICRYPT_BASE_FEE / 1000;
    
    // base token liquidity
    uint256 baseLiquidity = (STATUS.TOTAL_BASE_COLLECTED - unicryptBaseFee) * PRESALE_INFO.LIQUIDITY_PERCENT / 1000;
    if (PRESALE_INFO_2.PRESALE_IN_ETH) {
        WETH.deposit{value : baseLiquidity}();
    }
    TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity * PRESALE_INFO.LISTING_RATE / (10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER), tokenLiquidity);
    
    PRESALE_LOCK_FORWARDER.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO_2.PRESALE_OWNER);
    // transfer fees
    uint256 unicryptTokenFee = STATUS.TOTAL_TOKENS_SOLD * PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE / 1000;
    // referrals are checked for validity in the presale generator
    if (PRESALE_FEE_INFO.REFERRAL_1 != address(0)) {
        uint256 referralBaseFee = unicryptBaseFee * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;
        uint256 referralTokenFee = unicryptTokenFee * PRESALE_FEE_INFO.REFERRAL_FEE / 1000;

        if (PRESALE_FEE_INFO.REFERRAL_2 != address(0)) {
          uint256 ref2BaseFee = referralBaseFee * PRESALE_SETTINGS.getReferralSplitFee() / 100;
          TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_2, ref2BaseFee, !PRESALE_INFO_2.PRESALE_IN_ETH);
          referralBaseFee -= ref2BaseFee;

          uint256 ref2TokenFee = referralTokenFee * PRESALE_SETTINGS.getReferralSplitFee() / 100;
          TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_2, referralTokenFee);
          referralTokenFee -= ref2TokenFee;
        }
        // Base fee
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_1, referralBaseFee, !PRESALE_INFO_2.PRESALE_IN_ETH);
        unicryptBaseFee -= referralBaseFee;
        // Token fee
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_1, referralTokenFee);
        unicryptTokenFee -= referralTokenFee;
    }
    TransferHelper.safeTransferBaseToken(
      address(PRESALE_INFO.B_TOKEN), 
      PRESALE_INFO_2.PRESALE_IN_ETH ? PRESALE_SETTINGS.getEthAddress() : PRESALE_SETTINGS.getNonEthAddress(), 
      unicryptBaseFee, 
      !PRESALE_INFO_2.PRESALE_IN_ETH
    );
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_SETTINGS.getTokenAddress(), unicryptTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance - STATUS.TOTAL_TOKENS_SOLD;
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), 0x000000000000000000000000000000000000dEaD, burnAmount);
    }
    
    // send remaining base tokens to presale owner
    uint256 remainingBaseBalance = PRESALE_INFO_2.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_INFO_2.PRESALE_OWNER, remainingBaseBalance, !PRESALE_INFO_2.PRESALE_IN_ETH);

    // send UNCL to uncl burn address
    (address unclAddress,,address unclFeeAddress) = PRESALE_SETTINGS.getUNCLInfo();
    TransferHelper.safeTransfer(unclAddress, unclFeeAddress, IERC20(unclAddress).balanceOf(address(this)));
    
    STATUS.LP_GENERATION_COMPLETE = true;
    STATUS.PRESALE_END_DATE = block.timestamp;
  }
  
  // postpone or bring a presale forward, this will only work when a presale is inactive.
  // i.e. current start block > block.number
  function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyPresaleOwner {
    require(presaleStatus() == 0 && _startBlock > STATUS.ROUND_0_START + PRESALE_SETTINGS.getRound0Offset(), 'UB1');
    require(_endBlock - _startBlock <= PRESALE_SETTINGS.getMaxPresaleLength(), 'UB2');
    PRESALE_INFO.START_BLOCK = _startBlock;
    PRESALE_INFO.END_BLOCK = _endBlock;
  }

  // editable at any stage of the presale
  function editWhitelist(address[] memory _users, bool _add) external onlyPresaleOwner {
    require(presaleStatus() == 0, 'PRESALE HAS STARTED'); // ACTIVE
    if (_add) {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.add(_users[i]);
          require(WHITELIST.length() <= PRESALE_INFO_2.WHITELIST_MAX_PARTICIPANTS, "NOT ENOUGH SPOTS");
        }
    } else {
        for (uint i = 0; i < _users.length; i++) {
          require(BUYERS[_users[i]].baseDeposited == 0, "CANT UNLIST USERS WHO HAVE CONTRIBUTED");
          WHITELIST.remove(_users[i]);
        }
    }
  }

  // whitelist getters
  function getWhitelistedUsersLength () external view returns (uint256) {
    return WHITELIST.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return WHITELIST.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return WHITELIST.contains(_user);
  }

  /**
   * @notice Get a paged response of whitelisted users
   * @param _start the start index
   * @param _count number of items to return
   */
  function getPagedWhitelist (uint256 _start, uint256 _count) external view returns (WhitelistPager[] memory) {
    uint256 tlength = WHITELIST.length();
    uint128 max_getter_length = 20;
    uint256 clamp = _start + _count > tlength ? tlength - _start : _count;
    require(clamp <= max_getter_length, 'MAX GET');
    WhitelistPager[] memory response = new WhitelistPager[](clamp);
    uint256 counter = 0;
    while (counter < clamp) {
        address user = WHITELIST.at(_start + counter);
        response[counter] = WhitelistPager(user, BUYERS[user].baseDeposited);
        counter++;
    }
    return response;
  }
}