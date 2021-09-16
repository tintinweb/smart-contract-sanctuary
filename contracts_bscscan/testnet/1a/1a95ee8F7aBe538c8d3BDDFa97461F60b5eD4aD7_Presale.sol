// SPDX-License-Identifier: UNLICENSED

/**
  Allows a decentralised presale to take place, and on success creates a dex (pancake, uniswap...) pair and locks liquidity on Dexgo.
  BASE_TOKEN, or base token, is the token the presale attempts to raise. (Usually ETH/BNB).
  SALE_TOKEN, or sale token, is the token being sold, which investors buy with the base token.
  If the base currency is set to the WBNB/WETH address, the presale is in BNB/ETH.
  Otherwise it is for an ERC20 token - such as DAI, USDC, WBTC etc.
  For the Base token - It is advised to only use tokens such as ETH (WETH), DAI, USDC or tokens that have no rebasing, or complex fee on transfers. 1 token should ideally always be 1 token.
  Token withdrawals are done on a percent of total contribution basis (opposed to via a hardcoded 'amount').
  This allows fee on transfer, rebasing, or any magically changing balances to still work for the Sale token.
*/

pragma solidity 0.8.6;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPresaleLockForwarder {
    function lockLiquidity(IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlockDate, address payable _withdrawer) external;

    function dexPairIsInitialised(address _token0, address _token1) external view returns (bool);
}

interface IWrapToken {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

interface IPresaleSetting {
    function getMaxPresaleLength() external view returns (uint256);

    function getFirstRoundLength() external view returns (uint256);

    function userHoldSufficientFirstRoundToken(address _user) external view returns (bool);

    function refererIsValid(address _referer) external view returns (bool);

    function getBaseFeePercent() external view returns (uint256);

    function getTokenFeePercent() external view returns (uint256);

    function getBaseFeeAddress() external view returns (address payable);

    function getTokenFeeAddress() external view returns (address payable);

    function getRefererPercent(address) external view returns (uint256);

    function getCreationFee() external view returns (uint256);

    function getAdminAddress() external view returns (address);

    function getMinLiquidityPercent() external view returns (uint256);

    function getMinLockPeriod() external view returns (uint256);

    function baseTokenIsValid(address _baseToken) external view returns (bool);

    function getFinishBeforeFirstRound() external view returns (uint256);

    function getZeroRoundTokenAddress() external view returns (address);

    function getZeroRoundTokenAmount() external view returns (uint256);

    function getZeroRoundPercent() external view returns (uint256);

    function getWrapTokenAddress() external view returns (address);

    function getDexLockerAddress() external view returns (address);

    function getMaxSuccessToLiquidity() external view returns (uint256);
}

contract Presale is ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum PRESALE_STATUS {PENDING, ACTIVE, SUCCESS, FAILED}

    event BuyToken(address user, uint256 baseTokenAmount, uint256 saleTokenAmount);
    event UserWithdrawSaleToken(address user, uint256 saleTokenAmount);
    event UserWithdrawBaseToken(address user, uint256 baseTokenAmount);

    struct PresaleInfo {
        address payable PRESALE_OWNER;
        IERC20 SALE_TOKEN; // sale token
        IERC20 BASE_TOKEN; // base token usually WETH (ETH), WBNB (BNB)
        uint256 TOKEN_PRICE; // 1 base token = ? sale_tokens, fixed price
        uint256 LIMIT_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of presale tokens up for presale
        uint256 HARD_CAP;
        uint256 SOFT_CAP;
        uint256 LIQUIDITY_PERCENT;
        uint256 LISTING_PRICE; // fixed rate at which the token will list on Dex
        uint256 START_TIME;
        uint256 END_TIME;
        uint256 LOCK_PERIOD; // seconds
        bool PRESALE_IN_MAIN_TOKEN; // if this flag is true the presale is raising ETH/BNB, otherwise an ERC20 token such as DGO
        address WRAP_TOKEN_ADDRESS;
        address DEX_LOCKER_ADDRESS;
        address DEX_FACTORY_ADDRESS;
    }

    struct PresaleRound {
        bool ACTIVE_ZERO_ROUND;
        bool ACTIVE_FIRST_ROUND;
        PresaleZeroRoundInfo ZERO_ROUND_INFO;

    }

    struct PresaleZeroRoundInfo {
        address TOKEN_ADDRESS;
        uint256 TOKEN_AMOUNT;
        uint256 PERCENT;
        uint256 FINISH_BEFORE_FIRST_ROUND;
        uint256 FINISH_AT;
        uint256 MAX_BASE_TOKEN_AMOUNT;
        uint256 MAX_SLOT;
        uint256 REGISTERED_SLOT;
        EnumerableSet.AddressSet LIST_USER;
    }

    struct PresaleFeeInfo {
        uint256 BASE_FEE_PERCENT;
        uint256 TOKEN_FEE_PERCENT;
        uint256 REFERER_FEE_PERCENT;
        address payable BASE_FEE_ADDRESS;
        address payable TOKEN_FEE_ADDRESS;
        address payable REFERER_FEE_ADDRESS; // if this is not address(0), there is a valid referer
    }

    struct PresaleStatusInfo {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawals
        bool FORCE_FAILED; // set this flag to force fail the presale
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKEN_SOLD; // total presale token sold
        uint256 TOTAL_TOKEN_WITHDRAWN; // total token withdrawn post successful presale
        uint256 TOTAL_BASE_WITHDRAWN; // total base token withdrawn on presale failure
        uint256 FIRST_ROUND_LENGTH; // in seconds
        uint256 NUM_BUYERS; // number of unique participants
        EnumerableSet.AddressSet LIST_BUYER;
        uint256 SUCCESS_AT;
        uint256 LIQUIDITY_AT;
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (ETH/BNB...) deposited by user, can be withdrawn on presale failure
        uint256 tokenBought; // num presale token a user bought, can be withdrawn on presale success
    }

    struct PRESALE {
        uint256 CONTRACT_VERSION;
        address PRESALE_GENERATOR;
        PresaleInfo INFO;
        PresaleFeeInfo FEE;
        PresaleStatusInfo STATUS;
        PresaleRound ROUND_INFO;
    }

    PRESALE PRESALE_ITEM;
    IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
    IPresaleSetting public PRESALE_SETTING;
    IWrapToken public WrapToken;
    mapping(address => BuyerInfo) public BUYERS;
    EnumerableSet.AddressSet private WHITELIST;

    constructor(address _presaleGenerator) {
        PRESALE_ITEM.CONTRACT_VERSION = 1;
        PRESALE_ITEM.PRESALE_GENERATOR = _presaleGenerator;
        PRESALE_SETTING = IPresaleSetting(0x5aD293E7B3ad9f61fCfEEf01582D8b2f0aA0a2e3);
        PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(0xec31Cf03c53400b73fE3C1885B029f956c6Fc417);
        PRESALE_ITEM.INFO.WRAP_TOKEN_ADDRESS = PRESALE_SETTING.getWrapTokenAddress();
        PRESALE_ITEM.INFO.DEX_LOCKER_ADDRESS = PRESALE_SETTING.getDexLockerAddress();
        PRESALE_ITEM.INFO.DEX_FACTORY_ADDRESS = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
        WrapToken = IWrapToken(PRESALE_ITEM.INFO.WRAP_TOKEN_ADDRESS);

    }

    function setMainInfo(
        address payable _presaleOwner,
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _limitPerBuyer,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _liquidityPercent,
        uint256 _listingPrice,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _lockPeriod
    ) external {
        require(msg.sender == PRESALE_ITEM.PRESALE_GENERATOR, 'FORBIDDEN');

        // INFO
        PRESALE_ITEM.INFO.PRESALE_OWNER = _presaleOwner;
        PRESALE_ITEM.INFO.AMOUNT = _amount;
        PRESALE_ITEM.INFO.TOKEN_PRICE = _tokenPrice;
        PRESALE_ITEM.INFO.LIMIT_PER_BUYER = _limitPerBuyer;
        PRESALE_ITEM.INFO.HARD_CAP = _hardCap;
        PRESALE_ITEM.INFO.SOFT_CAP = _softCap;
        PRESALE_ITEM.INFO.LIQUIDITY_PERCENT = _liquidityPercent;
        PRESALE_ITEM.INFO.LISTING_PRICE = _listingPrice;
        PRESALE_ITEM.INFO.START_TIME = _startTime;
        PRESALE_ITEM.INFO.END_TIME = _endTime;
        PRESALE_ITEM.INFO.LOCK_PERIOD = _lockPeriod;
    }

    function setFeeInfo(
        IERC20 _baseToken,
        IERC20 _presaleToken,
        uint256 _baseFeePercent,
        uint256 _tokenFeePercent,
        uint256 _refererFeePercent,
        address payable _baseFeeAddress,
        address payable _tokenFeeAddress,
        address payable _refererAddress
    ) external {
        require(msg.sender == PRESALE_ITEM.PRESALE_GENERATOR, 'FORBIDDEN');

        PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN = address(_baseToken) == address(WrapToken);
        PRESALE_ITEM.INFO.SALE_TOKEN = _presaleToken;
        PRESALE_ITEM.INFO.BASE_TOKEN = _baseToken;

        PRESALE_ITEM.FEE.BASE_FEE_PERCENT = _baseFeePercent;
        PRESALE_ITEM.FEE.TOKEN_FEE_PERCENT = _tokenFeePercent;
        PRESALE_ITEM.FEE.REFERER_FEE_PERCENT = _refererFeePercent;

        PRESALE_ITEM.FEE.BASE_FEE_ADDRESS = _baseFeeAddress;
        PRESALE_ITEM.FEE.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
        PRESALE_ITEM.FEE.REFERER_FEE_ADDRESS = _refererAddress;

        PRESALE_ITEM.STATUS.FIRST_ROUND_LENGTH = PRESALE_SETTING.getFirstRoundLength();
    }

    function setRoundInfo(
        bool _activeZeroRound,
        bool _activeFirstRound
    ) external {
        require(msg.sender == PRESALE_ITEM.PRESALE_GENERATOR, 'FORBIDDEN');

        if (PRESALE_SETTING.getZeroRoundTokenAddress() == address(0)) {
            _activeZeroRound = false;
        }
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT = PRESALE_SETTING.getZeroRoundPercent();
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT = PRESALE_ITEM.INFO.HARD_CAP.div(1000).mul(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT);
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT = PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT.div(PRESALE_ITEM.INFO.LIMIT_PER_BUYER);
        if (PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT == 0) {
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT = 0;
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT = 0;
            _activeZeroRound = false;
        }

        PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND = _activeZeroRound;
        PRESALE_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND = _activeFirstRound;

        if (PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND) {
            // ZERO ROUND INFO
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS = PRESALE_SETTING.getZeroRoundTokenAddress();
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT = PRESALE_SETTING.getZeroRoundTokenAmount();
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND = PRESALE_SETTING.getFinishBeforeFirstRound();
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT = PRESALE_ITEM.INFO.START_TIME - PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND;
            PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT = 0;
        }

    }

    modifier onlyPresaleOwner() {
        require(PRESALE_ITEM.INFO.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == PRESALE_SETTING.getAdminAddress(), "SENDER IS NOT ADMIN");
        _;
    }

    function getPresaleStatus() public view returns (uint256) {
        if (PRESALE_ITEM.STATUS.FORCE_FAILED) {
            return uint256(PRESALE_STATUS.FAILED);
            // FAILED - force fail
        }
        if ((block.timestamp > PRESALE_ITEM.INFO.END_TIME) && (PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED < PRESALE_ITEM.INFO.SOFT_CAP)) {
            return uint256(PRESALE_STATUS.FAILED);
            // FAILED - soft cap not met by end time
        }
        if (PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED >= PRESALE_ITEM.INFO.HARD_CAP) {
            return uint256(PRESALE_STATUS.SUCCESS);
            // SUCCESS - hard cap met
        }
        if ((block.timestamp > PRESALE_ITEM.INFO.END_TIME) && (PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED >= PRESALE_ITEM.INFO.SOFT_CAP)) {
            return uint256(PRESALE_STATUS.SUCCESS);
            // SUCCESS - end time and soft cap reached
        }
        if ((block.timestamp >= PRESALE_ITEM.INFO.START_TIME) && (block.timestamp <= PRESALE_ITEM.INFO.END_TIME)) {
            return uint256(PRESALE_STATUS.ACTIVE);
            // ACTIVE - deposits enabled
        }
        // PENDING - awaiting start time
        return uint256(PRESALE_STATUS.PENDING);
    }

    function getPresaleRound() public view returns (int8) {
        int8 round = - 1;
        if (block.timestamp <= PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT) {
            round = 0;
        } else if (block.timestamp >= PRESALE_ITEM.INFO.START_TIME && block.timestamp < (PRESALE_ITEM.INFO.START_TIME + PRESALE_ITEM.STATUS.FIRST_ROUND_LENGTH)) {
            round = 1;
        } else if (block.timestamp >= (PRESALE_ITEM.INFO.START_TIME + PRESALE_ITEM.STATUS.FIRST_ROUND_LENGTH) && block.timestamp <= PRESALE_ITEM.INFO.END_TIME) {
            round = 2;
        }
        return round;
    }

    // accepts msg.value for eth or _amount for ERC20 token
    function buyToken(uint256 _amount) external payable nonReentrant {

        if (PRESALE_ITEM.STATUS.WHITELIST_ONLY) {
            require(WHITELIST.contains(msg.sender), 'PRESALE: NOT WHITELISTED');
        }

        if (getPresaleRound() < 0) {
            // After Round 0 And Before Round 1
            // Or After Round 2 (Finished)
            require(getPresaleStatus() == uint256(PRESALE_STATUS.ACTIVE), 'PRESALE: NOT ACTIVE');
        } else if (getPresaleRound() == 0) {
            // Still in time Round 0 - Before Round 1
            if (PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND) {
                require(getPresaleStatus() == uint256(PRESALE_STATUS.PENDING), 'PRESALE: NOT ACTIVE');
                require(block.timestamp < PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT, "PRESALE: ZERO ROUND FINISHED");
                require(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender), "PRESALE: ZERO ROUND NOT REGISTERED");
            } else {
                require(getPresaleStatus() == uint256(PRESALE_STATUS.ACTIVE), 'PRESALE: NOT ACTIVE');
            }
        } else if (getPresaleRound() == 1) {
            // Presale Round 1 - require participant to hold a certain token and balance
            require(getPresaleStatus() == uint256(PRESALE_STATUS.ACTIVE), 'PRESALE: NOT ACTIVE');
            if (PRESALE_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND) {
                bool userHoldsSpecificTokens = PRESALE_SETTING.userHoldSufficientFirstRoundToken(msg.sender);
                require(userHoldsSpecificTokens, 'INSUFFICIENT ROUND 1 TOKEN BALANCE');
            }
        } else {
            require(getPresaleStatus() == uint256(PRESALE_STATUS.ACTIVE), 'PRESALE: NOT ACTIVE');
        }

        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amountDeposit = PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN ? msg.value : _amount;
        uint256 allowToBuy = PRESALE_ITEM.INFO.LIMIT_PER_BUYER.sub(buyer.baseDeposited);
        uint256 remaining = PRESALE_ITEM.INFO.HARD_CAP - PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED;
        if (PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND && getPresaleRound() == 0) {
            remaining = PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT - PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED;
        }

        allowToBuy = allowToBuy > remaining ? remaining : allowToBuy;
        if (amountDeposit > allowToBuy) {
            amountDeposit = allowToBuy;
        }
        uint256 tokensSold = amountDeposit.mul(PRESALE_ITEM.INFO.TOKEN_PRICE).div(10 ** uint256(PRESALE_ITEM.INFO.BASE_TOKEN.decimals()));
        require(tokensSold > 0, 'ZERO TOKENS');
        if (buyer.baseDeposited == 0) {
            PRESALE_ITEM.STATUS.NUM_BUYERS++;
            PRESALE_ITEM.STATUS.LIST_BUYER.add(msg.sender);
        }
        buyer.baseDeposited = buyer.baseDeposited.add(amountDeposit);
        buyer.tokenBought = buyer.tokenBought.add(tokensSold);
        PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED = PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED.add(amountDeposit);
        PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD = PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD.add(tokensSold);

        // Return unused Main Token
        if (PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN && amountDeposit < msg.value) {
            payable(msg.sender).transfer(msg.value.sub(amountDeposit));
        }
        // Take non Main Token from user
        if (!PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN) {
            TransferHelper.safeTransferFrom(address(PRESALE_ITEM.INFO.BASE_TOKEN), msg.sender, address(this), amountDeposit);
        }

        // If reach soft cap but not hard cap, set success at = end time
        if (PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED >= PRESALE_ITEM.INFO.SOFT_CAP && PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED < PRESALE_ITEM.INFO.HARD_CAP) {
            PRESALE_ITEM.STATUS.SUCCESS_AT = PRESALE_ITEM.INFO.END_TIME;
        }

        // If reach hard cap, set success at = now
        if (PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED >= PRESALE_ITEM.INFO.HARD_CAP) {
            PRESALE_ITEM.STATUS.SUCCESS_AT = block.timestamp;
        }
        emit BuyToken(msg.sender, amountDeposit, tokensSold);
    }

    // withdraw presale tokens
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawSaleToken() external nonReentrant {
        require(PRESALE_ITEM.STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 tokensRemainingDenominator = PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD.sub(PRESALE_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN);
        uint256 tokenBought = PRESALE_ITEM.INFO.SALE_TOKEN.balanceOf(address(this)).mul(buyer.tokenBought).div(tokensRemainingDenominator);
        require(tokenBought > 0, 'NOTHING TO WITHDRAW');
        PRESALE_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN = PRESALE_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN.add(buyer.tokenBought);
        buyer.tokenBought = 0;
        TransferHelper.safeTransfer(address(PRESALE_ITEM.INFO.SALE_TOKEN), msg.sender, tokenBought);
        emit UserWithdrawSaleToken(msg.sender, tokenBought);
    }

    // on presale failure
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseToken() external nonReentrant {
        // Require Status Failed
        require(getPresaleStatus() == uint256(PRESALE_STATUS.FAILED), 'PRESALE NOT FAILED');

        // Refund Zero Round Token
        if (PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender)) {
            TransferHelper.safeTransfer(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, msg.sender, PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
        }

        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 baseRemainingDenominator = PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED.sub(PRESALE_ITEM.STATUS.TOTAL_BASE_WITHDRAWN);
        uint256 remainingBaseBalance = PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN ? address(this).balance : PRESALE_ITEM.INFO.BASE_TOKEN.balanceOf(address(this));
        uint256 baseToken = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
        require(baseToken > 0, 'NOTHING TO WITHDRAW');
        PRESALE_ITEM.STATUS.TOTAL_BASE_WITHDRAWN = PRESALE_ITEM.STATUS.TOTAL_BASE_WITHDRAWN.add(buyer.baseDeposited);
        buyer.baseDeposited = 0;
        TransferHelper.safeTransferBaseToken(address(PRESALE_ITEM.INFO.BASE_TOKEN), payable(msg.sender), baseToken, !PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN);
        emit UserWithdrawBaseToken(msg.sender, baseToken);
    }

    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function ownerWithdrawSaleToken() external onlyPresaleOwner {
        // Require Status Failed
        require(getPresaleStatus() == uint256(PRESALE_STATUS.FAILED), 'PRESALE NOT FAILED');
        TransferHelper.safeTransfer(address(PRESALE_ITEM.INFO.SALE_TOKEN), PRESALE_ITEM.INFO.PRESALE_OWNER, PRESALE_ITEM.INFO.SALE_TOKEN.balanceOf(address(this)));
    }

    // Can be called at any stage before or during the presale to cancel it before it ends.
    // If the pair already exists on dex and it contains the presale token as liquidity the final stage of the presale 'addLiquidity()' will fail.
    // This function allows anyone to end the presale prematurely to release funds in such a case.
    function forceFailIfPairExists() external {
        require(!PRESALE_ITEM.STATUS.LP_GENERATION_COMPLETE && !PRESALE_ITEM.STATUS.FORCE_FAILED);
        if (PRESALE_LOCK_FORWARDER.dexPairIsInitialised(address(PRESALE_ITEM.INFO.SALE_TOKEN), address(PRESALE_ITEM.INFO.BASE_TOKEN))) {
            PRESALE_ITEM.STATUS.FORCE_FAILED = true;
        }
    }

    // if something goes wrong in LP generation
    function forceFailByAdmin() onlyAdmin external {
        PRESALE_ITEM.STATUS.FORCE_FAILED = true;
    }

    // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawals of the sale token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to
    // the presale parameters and fixed prices.
    function addLiquidity() external nonReentrant {
        require(!PRESALE_ITEM.STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
        require(getPresaleStatus() == uint256(PRESALE_STATUS.SUCCESS), 'PRESALE NOT SUCCESS');
        // Fail the presale if the pair exists and contains presale token liquidity
        if (PRESALE_LOCK_FORWARDER.dexPairIsInitialised(address(PRESALE_ITEM.INFO.SALE_TOKEN), address(PRESALE_ITEM.INFO.BASE_TOKEN))) {
            PRESALE_ITEM.STATUS.FORCE_FAILED = true;
            return;
        }

        // If not presale owner, can add after success time + max success to liquidity
        if (PRESALE_ITEM.INFO.PRESALE_OWNER != msg.sender) {
            require(block.timestamp >= PRESALE_ITEM.STATUS.SUCCESS_AT + PRESALE_SETTING.getMaxSuccessToLiquidity(), "PRESALE: ADD LIQUIDITY TIME FOR PRESALE OWNER");
        }

        uint256 baseFeeAmount = PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED.mul(PRESALE_ITEM.FEE.BASE_FEE_PERCENT).div(1000);

        // base token liquidity
        uint256 baseLiquidity = PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED.sub(baseFeeAmount).mul(PRESALE_ITEM.INFO.LIQUIDITY_PERCENT).div(1000);
        if (PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN) {
            WrapToken.deposit{value : baseLiquidity}();
        }
        TransferHelper.safeApprove(address(PRESALE_ITEM.INFO.BASE_TOKEN), address(PRESALE_LOCK_FORWARDER), baseLiquidity);

        // sale token liquidity
        uint256 tokenLiquidity = baseLiquidity.mul(PRESALE_ITEM.INFO.LISTING_PRICE).div(10 ** uint256(PRESALE_ITEM.INFO.BASE_TOKEN.decimals()));
        TransferHelper.safeApprove(address(PRESALE_ITEM.INFO.SALE_TOKEN), address(PRESALE_LOCK_FORWARDER), tokenLiquidity);

        PRESALE_LOCK_FORWARDER.lockLiquidity(PRESALE_ITEM.INFO.BASE_TOKEN, PRESALE_ITEM.INFO.SALE_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + PRESALE_ITEM.INFO.LOCK_PERIOD, PRESALE_ITEM.INFO.PRESALE_OWNER);

        // transfer fees
        uint256 tokenFeeAmount = PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD.mul(PRESALE_ITEM.FEE.TOKEN_FEE_PERCENT).div(1000);

        // referer is checked for validity in the presale generator
        if (PRESALE_ITEM.FEE.REFERER_FEE_ADDRESS != address(0)) {
            // Base token fee
            uint256 refererBaseFeeAmount = baseFeeAmount.mul(PRESALE_ITEM.FEE.REFERER_FEE_PERCENT).div(1000);
            TransferHelper.safeTransferBaseToken(address(PRESALE_ITEM.INFO.BASE_TOKEN), PRESALE_ITEM.FEE.REFERER_FEE_ADDRESS, refererBaseFeeAmount, !PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN);
            baseFeeAmount = baseFeeAmount.sub(refererBaseFeeAmount);
            // Token fee
            uint256 refererTokenFeeAmount = tokenFeeAmount.mul(PRESALE_ITEM.FEE.REFERER_FEE_PERCENT).div(1000);
            TransferHelper.safeTransfer(address(PRESALE_ITEM.INFO.SALE_TOKEN), PRESALE_ITEM.FEE.REFERER_FEE_ADDRESS, refererTokenFeeAmount);
            tokenFeeAmount = tokenFeeAmount.sub(refererTokenFeeAmount);
        }

        TransferHelper.safeTransferBaseToken(address(PRESALE_ITEM.INFO.BASE_TOKEN), PRESALE_ITEM.FEE.BASE_FEE_ADDRESS, baseFeeAmount, !PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN);
        TransferHelper.safeTransfer(address(PRESALE_ITEM.INFO.SALE_TOKEN), PRESALE_ITEM.FEE.TOKEN_FEE_ADDRESS, tokenFeeAmount);

        // burn unsold tokens
        uint256 remainingSaleTokenBalance = PRESALE_ITEM.INFO.SALE_TOKEN.balanceOf(address(this));
        if (remainingSaleTokenBalance > PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD) {
            uint256 burnAmount = remainingSaleTokenBalance.sub(PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD);
            TransferHelper.safeTransfer(address(PRESALE_ITEM.INFO.SALE_TOKEN), 0x000000000000000000000000000000000000dEaD, burnAmount);
        }

        // Burn Zero  Round Token
        if (PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT > 0) {
            uint256 zeroRoundRegisteredTokenAmount = PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT.mul(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
            uint256 zeroRoundTokenBalance = IERC20(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS).balanceOf(address(this));
            uint256 zeroRoundTokenBurn = zeroRoundRegisteredTokenAmount > zeroRoundTokenBalance ? zeroRoundTokenBalance : zeroRoundRegisteredTokenAmount;
            TransferHelper.safeTransfer(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, 0x000000000000000000000000000000000000dEaD, zeroRoundTokenBurn);
        }

        // send remaining base tokens to presale owner
        uint256 remainingBaseTokenBalance = PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN ? address(this).balance : PRESALE_ITEM.INFO.BASE_TOKEN.balanceOf(address(this));
        TransferHelper.safeTransferBaseToken(address(PRESALE_ITEM.INFO.BASE_TOKEN), PRESALE_ITEM.INFO.PRESALE_OWNER, remainingBaseTokenBalance, !PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN);

        PRESALE_ITEM.STATUS.LP_GENERATION_COMPLETE = true;
        PRESALE_ITEM.STATUS.LIQUIDITY_AT = block.timestamp;
    }

    // Update Limit Per Buyer
    function updateLimitPerBuyer(uint256 _limitPerBuyer) external onlyPresaleOwner {
        require(PRESALE_ITEM.INFO.START_TIME > block.timestamp, 'PRESALE: PRESALE STARTED');
        PRESALE_ITEM.INFO.LIMIT_PER_BUYER = _limitPerBuyer;
    }

    // postpone or bring a presale forward, this will only work when a presale is pending (not start).
    function updateTime(uint256 _startTime, uint256 _endTime) external onlyPresaleOwner {
        require(PRESALE_ITEM.INFO.START_TIME > block.timestamp);
        require(_endTime.sub(_startTime) <= PRESALE_SETTING.getMaxPresaleLength());
        PRESALE_ITEM.INFO.START_TIME = _startTime;
        PRESALE_ITEM.INFO.END_TIME = _endTime;
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT = _startTime - PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND;
    }

    // GET WHITELIST FLAG
    function getWhitelistFlag() external view returns (bool) {
        return PRESALE_ITEM.STATUS.WHITELIST_ONLY;
    }

    // SET WHITELIST FLAG
    function setWhitelistFlag(bool _flag) external onlyPresaleOwner {
        PRESALE_ITEM.STATUS.WHITELIST_ONLY = _flag;
    }

    // EDIT WHITELIST LIST
    function editWhitelist(address[] memory _users, bool _add) external onlyPresaleOwner {
        if (_add) {
            for (uint256 i = 0; i < _users.length; i++) {
                WHITELIST.add(_users[i]);
            }
        } else {
            for (uint256 i = 0; i < _users.length; i++) {
                WHITELIST.remove(_users[i]);
            }
        }
    }

    // WHITELIST LENGTH
    function getWhitelistedUsersLength() external view returns (uint256) {
        return WHITELIST.length();
    }

    function getWhitelistedUserAtIndex(uint256 _index) external view returns (address) {
        return WHITELIST.at(_index);
    }

    // GET USER WHITELIST STATUS
    function getUserWhitelistStatus(address _user) external view returns (bool) {
        return WHITELIST.contains(_user);
    }

    // REGISTER ROUND 0
    function registerZeroRound() external nonReentrant {
        if (PRESALE_ITEM.STATUS.WHITELIST_ONLY) {
            require(WHITELIST.contains(msg.sender), 'PRESALE: NOT WHITELISTED');
        }

        require(PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND, 'PRESALE: ZERO ROUND NOT ACTIVE');
        require(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS != address(0), 'PRESALE: ZERO ROUND NOT ACTIVE');
        require(getPresaleRound() == 0, "PRESALE: ZERO ROUND FINISHED");
        require(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT < PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT, "PRESALE: ZERO ROUND ENOUGH SLOT");
        require(!PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender), "PRESALE: ZERO ROUND ALREADY REGISTERED");

        TransferHelper.safeTransferFrom(PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, address(msg.sender), address(this), PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT = PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT.add(1);
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.add(msg.sender);
    }

    // CONTRACT VERSION
    function getContractVersion() external view returns (uint256) {
        return PRESALE_ITEM.CONTRACT_VERSION;
    }

    // PRESALE GENERATOR
    function getPresaleGenerator() external view returns (address) {
        return PRESALE_ITEM.PRESALE_GENERATOR;
    }

    // PRESALE GENERATOR
    function getWrapTokenAddress() external view returns (address) {
        return PRESALE_ITEM.INFO.WRAP_TOKEN_ADDRESS;
    }

    // GENERAL INFO
    function getGeneralInfo() external view returns (uint256 contractVersion, address presaleGenerator) {
        return (PRESALE_ITEM.CONTRACT_VERSION, PRESALE_ITEM.PRESALE_GENERATOR);
    }

    // GET ROUND INFO
    function getRoundInfo() external view returns (bool activeZeroRound, bool activeFirstRound) {
        return (PRESALE_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND, PRESALE_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND);
    }

    // GET ZERO ROUND INFO
    function getZeroRoundInfo() external view returns (
        address tokenAddress,
        uint256 tokenAmount,
        uint256 percent,
        uint256 finishBeforeFirstRound,
        uint256 finishAt,
        uint256 maxBaseTokenAmount,
        uint256 maxSlot,
        uint256 registeredSlot
    ) {
        return (
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT,
        PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT
        );
    }

    // ZERO ROUND USER LENGTH
    function getZeroRoundUserLength() external view returns (uint256) {
        return PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.length();
    }
    // ZERO ROUND USER AT INDEX
    function getZeroRoundUserAtIndex(uint256 _index) external view returns (address) {
        return PRESALE_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.at(_index);
    }

    // GET FEE INFO
    function getFeeInfo() external view returns (
        uint256 baseFeePercent,
        uint256 tokenFeePercent,
        uint256 refererFeePercent,
        address baseFeeAddress,
        address tokenFeeAddress,
        address refererFeeAddress
    ) {
        return (
        PRESALE_ITEM.FEE.BASE_FEE_PERCENT,
        PRESALE_ITEM.FEE.TOKEN_FEE_PERCENT,
        PRESALE_ITEM.FEE.REFERER_FEE_PERCENT,
        PRESALE_ITEM.FEE.BASE_FEE_ADDRESS,
        PRESALE_ITEM.FEE.TOKEN_FEE_ADDRESS,
        PRESALE_ITEM.FEE.REFERER_FEE_ADDRESS
        );
    }

    // STATUS INFO
    function getStatusInfo() external view returns (
        bool whitelistOnly,
        bool lpGenerationComplete,
        bool forceFailed,
        uint256 totalBaseCollected,
        uint256 totalTokenSold,
        uint256 totalTokenWithdrawn,
        uint256 totalBaseWithdrawn,
        uint256 firstRoundLength,
        uint256 numBuyers,
        uint256 successAt,
        uint256 liquidityAt,
        uint256 currentStatus,
        int8 currentRound
    ) {
        return (
        PRESALE_ITEM.STATUS.WHITELIST_ONLY,
        PRESALE_ITEM.STATUS.LP_GENERATION_COMPLETE,
        PRESALE_ITEM.STATUS.FORCE_FAILED,
        PRESALE_ITEM.STATUS.TOTAL_BASE_COLLECTED,
        PRESALE_ITEM.STATUS.TOTAL_TOKEN_SOLD,
        PRESALE_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN,
        PRESALE_ITEM.STATUS.TOTAL_BASE_WITHDRAWN,
        PRESALE_ITEM.STATUS.FIRST_ROUND_LENGTH,
        PRESALE_ITEM.STATUS.NUM_BUYERS,
        PRESALE_ITEM.STATUS.SUCCESS_AT,
        PRESALE_ITEM.STATUS.LIQUIDITY_AT,
        getPresaleStatus(),
        getPresaleRound()
        );
    }

    // LIST BUYER LENGTH
    function getListBuyerLength() external view returns (uint256) {
        return PRESALE_ITEM.STATUS.LIST_BUYER.length();
    }
    // LIST BUYER AT INDEX
    function getListBuyerLengthAtIndex(uint256 _index) external view returns (address) {
        return PRESALE_ITEM.STATUS.LIST_BUYER.at(_index);
    }

    // GET MAIN INFO
    function getPresaleMainInfo() external view returns (
        uint256 tokenPrice,
        uint256 limitPerBuyer,
        uint256 amount,
        uint256 hardCap,
        uint256 softCap,
        uint256 liquidityPercent,
        uint256 listingPrice,
        uint256 startTime,
        uint256 endTime,
        uint256 lockPeriod,
        bool presaleInMainToken
    ) {
        return (
        PRESALE_ITEM.INFO.TOKEN_PRICE,
        PRESALE_ITEM.INFO.LIMIT_PER_BUYER,
        PRESALE_ITEM.INFO.AMOUNT,
        PRESALE_ITEM.INFO.HARD_CAP,
        PRESALE_ITEM.INFO.SOFT_CAP,
        PRESALE_ITEM.INFO.LIQUIDITY_PERCENT,
        PRESALE_ITEM.INFO.LISTING_PRICE,
        PRESALE_ITEM.INFO.START_TIME,
        PRESALE_ITEM.INFO.END_TIME,
        PRESALE_ITEM.INFO.LOCK_PERIOD,
        PRESALE_ITEM.INFO.PRESALE_IN_MAIN_TOKEN
        );
    }

    // GET ADDRESS INFO
    function getPresaleAddressInfo() external view returns (
        address presaleOwner,
        address saleToken,
        address baseToken,
        address wrapTokenAddress,
        address dexLockerAddress,
        address dexFactoryAddress
    ) {
        return (
        PRESALE_ITEM.INFO.PRESALE_OWNER,
        address(PRESALE_ITEM.INFO.SALE_TOKEN),
        address(PRESALE_ITEM.INFO.BASE_TOKEN),
        PRESALE_ITEM.INFO.WRAP_TOKEN_ADDRESS,
        PRESALE_ITEM.INFO.DEX_LOCKER_ADDRESS,
        PRESALE_ITEM.INFO.DEX_FACTORY_ADDRESS
        );
    }

    function getBuyerInfo(address _address) external view returns (uint256 baseDeposited, uint256 tokenBought) {
        return (BUYERS[_address].baseDeposited, BUYERS[_address].tokenBought);
    }

    function retrieveToken(address tokenAddress, uint256 amount) public onlyAdmin returns (bool) {
        return IERC20(tokenAddress).transfer(PRESALE_SETTING.getAdminAddress(), amount);
    }

    function retrieveBalance(uint256 amount) public onlyAdmin {
        payable(PRESALE_SETTING.getAdminAddress()).transfer(amount);
    }
}