// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./TransferHelper.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

interface IWrapToken {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

interface IPoolSetting {
    function getMaxPoolLength() external view returns (uint256);

    function getFirstRoundLength() external view returns (uint256);

    function userHoldSufficientFirstRoundToken(address _user) external view returns (bool);

    function getAdminAddress() external view returns (address);

    function baseTokenIsValid(address _baseToken) external view returns (bool);

    function getZeroRoundFinishBeforeFirstRound() external view returns (uint256);

    function getZeroRoundTokenAddress() external view returns (address);

    function getZeroRoundTokenAmount() external view returns (uint256);

    function getZeroRoundPercent() external view returns (uint256);

    function getWrapTokenAddress() external view returns (address);

    function getAuctionRoundTokenAddress() external view returns (address);

    function getAuctionRoundFinishBeforeFirstRound() external view returns (uint256);

    function creatorAddressIsValid(address _creatorAddress) external view returns (bool);
}

contract Pool is ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum POOL_STATUS {PENDING, ACTIVE, SUCCESS, FAILED}

    event BuyToken(address user, uint256 baseTokenAmount, uint256 poolTokenAmount);
    event UserWithdrawPoolToken(address user, uint256 poolTokenAmount, uint256 percent, uint256 numberClaimed);
    event UserWithdrawAuctionToken(address user, uint256 tokenAmount);
    event UserWithdrawBaseToken(address user, uint256 baseTokenAmount);
    event ActiveClaim(uint256 zeroRoundTokenBurn, uint256 auctionRoundTokenBurn, uint256 notSoldToken);

    struct PoolInfo {
        address payable POOL_OWNER;
        IERC20 POOL_TOKEN; // pool token
        IERC20 BASE_TOKEN; // base token usually WETH (ETH), WBNB (BNB)
        uint256 TOKEN_PRICE; // 1 base token = ? pool_tokens, fixed price
        uint256 LIMIT_PER_BUYER; // maximum base token BUY amount per account
        uint256 AMOUNT; // the amount of pool tokens up for pool
        uint256 HARD_CAP;
        uint256 SOFT_CAP;
        uint256 START_TIME;
        uint256 END_TIME;
        bool POOL_IN_MAIN_TOKEN; // if this flag is true the pool is raising ETH/BNB, otherwise an ERC20 token such as DGO
        address WRAP_TOKEN_ADDRESS;
    }

    struct PoolZeroRoundInfo {
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

    struct PoolAuctionRoundInfo {
        address TOKEN_ADDRESS;
        uint256 START_TIME;
        uint256 END_TIME;
        uint256 REGISTERED_SLOT;
        uint256 TOTAL_TOKEN_AMOUNT;
        uint256 BURNED_TOKEN_AMOUNT;
        uint256 REFUND_TOKEN_AMOUNT;
        EnumerableSet.AddressSet LIST_USER;
        EnumerableSet.AddressSet LIST_WITHDRAW;
        mapping(address => uint256) LIST_AMOUNT;
    }

    struct PoolRound {
        bool ACTIVE_AUCTION_ROUND;
        bool ACTIVE_ZERO_ROUND;
        bool ACTIVE_FIRST_ROUND;
        PoolZeroRoundInfo ZERO_ROUND_INFO;
        PoolAuctionRoundInfo AUCTION_ROUND_INFO;
    }

    struct PoolVesting {
        bool ACTIVE_VESTING;
        uint256[] VESTING_PERIOD;
        uint256[] VESTING_PERCENT;
    }

    struct PoolStatusInfo {
        bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
        bool ACTIVE_CLAIM; // final flag required to end a pool and enable withdrawals
        bool FORCE_FAILED; // set this flag to force fail the pool
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKEN_SOLD; // total pool token sold
        uint256 TOTAL_TOKEN_WITHDRAWN; // total token withdrawn post successful pool
        uint256 TOTAL_BASE_WITHDRAWN; // total base token withdrawn on pool failure
        uint256 FIRST_ROUND_LENGTH; // in seconds
        uint256 NUM_BUYERS; // number of unique participants
        EnumerableSet.AddressSet LIST_BUYER;
        uint256 SUCCESS_AT;
        uint256 ACTIVE_CLAIM_AT;
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (ETH/BNB...) deposited by user, can be withdrawn on pool failure
        uint256 tokenBought; // num pool token a user bought, can be withdrawn on pool success
        uint256 tokenClaimed; // num pool token a user claimed
        uint256 numberClaimed;
        uint256[] historyTimeClaimed;
        uint256[] historyAmountClaimed;
    }

    struct POOL {
        uint256 CONTRACT_VERSION;
        address POOL_GENERATOR;
        string CONTRACT_TYPE;
        PoolInfo INFO;
        PoolStatusInfo STATUS;
        PoolRound ROUND_INFO;
        PoolVesting VESTING_INFO;
    }

    POOL POOL_ITEM;
    IPoolSetting public POOL_SETTING;
    IWrapToken public WrapToken;
    mapping(address => BuyerInfo) public BUYERS;
    EnumerableSet.AddressSet private WHITELIST;

    constructor(address _poolGenerator) {
        POOL_ITEM.CONTRACT_VERSION = 1;
        POOL_ITEM.POOL_GENERATOR = _poolGenerator;
        POOL_SETTING = IPoolSetting(0x3a8fC7D23E605268d71450a68F7B4c9e2e9F8927);
        POOL_ITEM.INFO.WRAP_TOKEN_ADDRESS = POOL_SETTING.getWrapTokenAddress();
        WrapToken = IWrapToken(POOL_ITEM.INFO.WRAP_TOKEN_ADDRESS);
    }

    function setMainInfo(
        address payable _poolOwner,
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _limitPerBuyer,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _startTime,
        uint256 _endTime
    ) external {
        require(msg.sender == POOL_ITEM.POOL_GENERATOR, 'FORBIDDEN');

        // INFO
        POOL_ITEM.INFO.POOL_OWNER = _poolOwner;
        POOL_ITEM.INFO.AMOUNT = _amount;
        POOL_ITEM.INFO.TOKEN_PRICE = _tokenPrice;
        POOL_ITEM.INFO.LIMIT_PER_BUYER = _limitPerBuyer;
        POOL_ITEM.INFO.HARD_CAP = _hardCap;
        POOL_ITEM.INFO.SOFT_CAP = _softCap;
        POOL_ITEM.INFO.START_TIME = _startTime;
        POOL_ITEM.INFO.END_TIME = _endTime;
    }

    function setTokenInfo(
        IERC20 _baseToken,
        IERC20 _poolToken
    ) external {
        require(msg.sender == POOL_ITEM.POOL_GENERATOR, 'FORBIDDEN');

        POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN = address(_baseToken) == address(WrapToken);
        POOL_ITEM.INFO.POOL_TOKEN = _poolToken;
        POOL_ITEM.INFO.BASE_TOKEN = _baseToken;

        POOL_ITEM.STATUS.FIRST_ROUND_LENGTH = POOL_SETTING.getFirstRoundLength();
    }

    function setRoundInfo(
        bool _activeZeroRound,
        bool _activeFirstRound,
        bool _activeAuctionRound
    ) external {
        require(msg.sender == POOL_ITEM.POOL_GENERATOR, 'FORBIDDEN');

        if (POOL_SETTING.getZeroRoundTokenAddress() == address(0)) {
            _activeZeroRound = false;
        }

        if (POOL_SETTING.getAuctionRoundTokenAddress() == address(0)) {
            _activeAuctionRound = false;
        }

        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT = POOL_SETTING.getZeroRoundPercent();
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT = POOL_ITEM.INFO.HARD_CAP.div(1000).mul(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT);
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT = POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT.div(POOL_ITEM.INFO.LIMIT_PER_BUYER);
        if (POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT == 0) {
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT = 0;
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT = 0;
            _activeZeroRound = false;
        }

        POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND = _activeZeroRound;
        POOL_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND = _activeFirstRound;
        POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND = _activeAuctionRound;

        if (POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND) {
            // ZERO ROUND INFO
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS = POOL_SETTING.getZeroRoundTokenAddress();
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT = POOL_SETTING.getZeroRoundTokenAmount();
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND = POOL_SETTING.getZeroRoundFinishBeforeFirstRound();
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT = POOL_ITEM.INFO.START_TIME - POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND;
            POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT = 0;
        }

        if (POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND) {
            // AUCTION ROUND INFO
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS = POOL_SETTING.getAuctionRoundTokenAddress();
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REGISTERED_SLOT = 0;
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOTAL_TOKEN_AMOUNT = 0;
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.BURNED_TOKEN_AMOUNT = 0;
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REFUND_TOKEN_AMOUNT = 0;
        }
    }

    function setAuctionRoundInfo(
        uint256 _startTime,
        uint256 _endTime
    ) external {
        require(msg.sender == POOL_ITEM.POOL_GENERATOR, 'FORBIDDEN');
        if (POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND) {
            require(_startTime > 0 && _endTime > 0 && _endTime > _startTime, 'POOL: INVALID AUCTION TIME');
            require(_endTime.add(POOL_SETTING.getAuctionRoundFinishBeforeFirstRound()) < POOL_ITEM.INFO.START_TIME, 'POOL: AUCTION END TIME TOO LATE');
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.START_TIME = _startTime;
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.END_TIME = _endTime;
        }
    }

    function setVestingInfo(
        bool _activeVesting,
        uint256[] memory _vestingPeriod,
        uint256[] memory _vestingPercent
    ) external {
        require(msg.sender == POOL_ITEM.POOL_GENERATOR, 'FORBIDDEN');

        POOL_ITEM.VESTING_INFO.ACTIVE_VESTING = _activeVesting;
        POOL_ITEM.VESTING_INFO.VESTING_PERIOD = _vestingPeriod;
        POOL_ITEM.VESTING_INFO.VESTING_PERCENT = _vestingPercent;
        if (_activeVesting) {
            POOL_ITEM.CONTRACT_TYPE = 'vesting';
        } else {
            POOL_ITEM.CONTRACT_TYPE = 'normal';
        }
    }

    modifier onlyPoolOwner() {
        require(POOL_ITEM.INFO.POOL_OWNER == msg.sender, "NOT POOL OWNER");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == POOL_SETTING.getAdminAddress(), "SENDER IS NOT ADMIN");
        _;
    }

    function getPoolStatus() public view returns (uint256) {
        if (POOL_ITEM.STATUS.FORCE_FAILED) {
            return uint256(POOL_STATUS.FAILED);
            // FAILED - force fail
        }
        if ((block.timestamp > POOL_ITEM.INFO.END_TIME) && (POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED < POOL_ITEM.INFO.SOFT_CAP)) {
            return uint256(POOL_STATUS.FAILED);
            // FAILED - soft cap not met by end time
        }
        if (POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED >= POOL_ITEM.INFO.HARD_CAP) {
            return uint256(POOL_STATUS.SUCCESS);
            // SUCCESS - hard cap met
        }
        if ((block.timestamp > POOL_ITEM.INFO.END_TIME) && (POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED >= POOL_ITEM.INFO.SOFT_CAP)) {
            return uint256(POOL_STATUS.SUCCESS);
            // SUCCESS - end time and soft cap reached
        }
        if ((block.timestamp >= POOL_ITEM.INFO.START_TIME) && (block.timestamp <= POOL_ITEM.INFO.END_TIME)) {
            return uint256(POOL_STATUS.ACTIVE);
            // ACTIVE - deposits enabled
        }
        // PENDING - awaiting start time
        return uint256(POOL_STATUS.PENDING);
    }

    function getPoolRound() public view returns (int8) {
        int8 round = - 1;

        if (block.timestamp < POOL_ITEM.INFO.START_TIME) {
            if (POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND) {
                if (block.timestamp <= POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT) {
                    round = 0;
                }
            }

            if (POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND) {
                if (block.timestamp >= POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.START_TIME && block.timestamp <= POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.END_TIME) {
                    round = 10;
                }
            }

        } else {
            if (block.timestamp <= POOL_ITEM.INFO.END_TIME) {
                if (POOL_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND) {
                    if (block.timestamp < (POOL_ITEM.INFO.START_TIME + POOL_ITEM.STATUS.FIRST_ROUND_LENGTH)) {
                        round = 1;
                    } else {
                        round = 2;
                    }
                } else {
                    round = 2;
                }
            }
        }
        return round;

    }

    // accepts msg.value for eth or _amount for ERC20 token
    function buyToken(uint256 _amount) external payable nonReentrant {

        if (POOL_ITEM.STATUS.WHITELIST_ONLY) {
            require(WHITELIST.contains(msg.sender), 'POOL: NOT WHITELISTED');
        }

        if (getPoolRound() < 0) {
            // After (Round 0 Or Auction Round) And Before Round 1
            // Or After Round 2 (Finished)
            require(getPoolStatus() == uint256(POOL_STATUS.ACTIVE), 'POOL: NOT ACTIVE');
        } else if (getPoolRound() == 0) {
            // Still in time Round 0 - Before Round 1
            if (POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND) {
                require(getPoolStatus() == uint256(POOL_STATUS.PENDING), 'POOL: NOT ACTIVE');
                require(block.timestamp < POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT, "POOL: ZERO ROUND FINISHED");
                if (!POOL_ITEM.STATUS.WHITELIST_ONLY) {
                    require(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender), "POOL: ZERO ROUND NOT REGISTERED");
                }
            } else {
                require(getPoolStatus() == uint256(POOL_STATUS.ACTIVE), 'POOL: NOT ACTIVE');
            }
        } else if (getPoolRound() == 1) {
            // Pool Round 1 - require participant to hold a certain token and balance
            require(getPoolStatus() == uint256(POOL_STATUS.ACTIVE), 'POOL: NOT ACTIVE');
            if (POOL_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND && !POOL_ITEM.STATUS.WHITELIST_ONLY) {
                bool userHoldsSpecificTokens = POOL_SETTING.userHoldSufficientFirstRoundToken(msg.sender);
                require(userHoldsSpecificTokens, 'INSUFFICIENT ROUND 1 TOKEN BALANCE');
            }
        } else {
            require(getPoolStatus() == uint256(POOL_STATUS.ACTIVE), 'POOL: NOT ACTIVE');
        }

        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 amountDeposit = POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN ? msg.value : _amount;
        uint256 allowToBuy = POOL_ITEM.INFO.LIMIT_PER_BUYER.sub(buyer.baseDeposited);
        uint256 remaining = POOL_ITEM.INFO.HARD_CAP - POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED;
        allowToBuy = allowToBuy > remaining ? remaining : allowToBuy;
        if (amountDeposit > allowToBuy) {
            amountDeposit = allowToBuy;
        }
        uint256 tokensSold = amountDeposit.mul(POOL_ITEM.INFO.TOKEN_PRICE).div(10 ** uint256(POOL_ITEM.INFO.BASE_TOKEN.decimals()));
        require(tokensSold > 0, 'ZERO TOKENS TO BUY');
        if (buyer.baseDeposited == 0) {
            POOL_ITEM.STATUS.NUM_BUYERS++;
            POOL_ITEM.STATUS.LIST_BUYER.add(msg.sender);
            buyer.tokenClaimed = 0;
            buyer.numberClaimed = 0;
        }
        buyer.baseDeposited = buyer.baseDeposited.add(amountDeposit);
        buyer.tokenBought = buyer.tokenBought.add(tokensSold);
        POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED = POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED.add(amountDeposit);
        POOL_ITEM.STATUS.TOTAL_TOKEN_SOLD = POOL_ITEM.STATUS.TOTAL_TOKEN_SOLD.add(tokensSold);

        // Return unused Main Token
        if (POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN && amountDeposit < msg.value) {
            payable(msg.sender).transfer(msg.value.sub(amountDeposit));
        }
        // Take non Main Token from user
        if (!POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN) {
            TransferHelper.safeTransferFrom(address(POOL_ITEM.INFO.BASE_TOKEN), msg.sender, address(this), amountDeposit);
        }

        // If reach soft cap but not hard cap, set success at = end time
        if (POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED >= POOL_ITEM.INFO.SOFT_CAP && POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED < POOL_ITEM.INFO.HARD_CAP) {
            POOL_ITEM.STATUS.SUCCESS_AT = POOL_ITEM.INFO.END_TIME;
        }

        // If reach hard cap, set success at = now
        if (POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED >= POOL_ITEM.INFO.HARD_CAP) {
            POOL_ITEM.STATUS.SUCCESS_AT = block.timestamp;
        }
        emit BuyToken(msg.sender, amountDeposit, tokensSold);
    }

    // withdraw pool tokens
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawPoolToken() external nonReentrant {
        require(POOL_ITEM.STATUS.ACTIVE_CLAIM, 'AWAITING ACTIVE CLAIM');
        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 tokensRemainingDenominator = POOL_ITEM.STATUS.TOTAL_TOKEN_SOLD.sub(POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN);
        uint256 currentClaimPercent;
        uint256 tokenBought;
        if (POOL_ITEM.VESTING_INFO.ACTIVE_VESTING) {
            require(buyer.numberClaimed < POOL_ITEM.VESTING_INFO.VESTING_PERIOD.length, 'ALREADY CLAIMED ALL TOKENS');
            uint256 currentClaimTime = POOL_ITEM.VESTING_INFO.VESTING_PERIOD[buyer.numberClaimed];
            require(block.timestamp >= currentClaimTime, 'INVALID CLAIM TIME');
            // Last time
            uint256 currentClaimAmount;
            currentClaimPercent = POOL_ITEM.VESTING_INFO.VESTING_PERCENT[buyer.numberClaimed];
            if (buyer.numberClaimed == POOL_ITEM.VESTING_INFO.VESTING_PERIOD.length - 1) {
                currentClaimAmount = buyer.tokenBought.sub(buyer.tokenClaimed);
            } else {
                currentClaimAmount = buyer.tokenBought.div(1000).mul(currentClaimPercent);
            }
            tokenBought = POOL_ITEM.INFO.POOL_TOKEN.balanceOf(address(this)).mul(currentClaimAmount).div(tokensRemainingDenominator);
            require(tokenBought > 0, 'NOTHING TO WITHDRAW');
            POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN = POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN.add(currentClaimAmount);
            buyer.tokenClaimed = buyer.tokenClaimed.add(tokenBought);
        } else {
            currentClaimPercent = 1000;
            tokenBought = POOL_ITEM.INFO.POOL_TOKEN.balanceOf(address(this)).mul(buyer.tokenBought).div(tokensRemainingDenominator);
            require(tokenBought > 0, 'NOTHING TO WITHDRAW');
            POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN = POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN.add(buyer.tokenBought);
            buyer.tokenClaimed = buyer.tokenBought;
        }
        buyer.historyAmountClaimed.push(tokenBought);
        buyer.historyTimeClaimed.push(block.timestamp);
        buyer.numberClaimed += 1;
        TransferHelper.safeTransfer(address(POOL_ITEM.INFO.POOL_TOKEN), msg.sender, tokenBought);
        emit UserWithdrawPoolToken(msg.sender, tokenBought, currentClaimPercent, buyer.numberClaimed);
    }

    // on pool failure
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseToken() external nonReentrant {
        // Require Status Failed
        require(getPoolStatus() == uint256(POOL_STATUS.FAILED), 'POOL NOT FAILED');

        // Refund Zero Round Token
        if (POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender)) {
            TransferHelper.safeTransfer(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, msg.sender, POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
        }

        BuyerInfo storage buyer = BUYERS[msg.sender];
        uint256 baseRemainingDenominator = POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED.sub(POOL_ITEM.STATUS.TOTAL_BASE_WITHDRAWN);
        uint256 remainingBaseBalance = POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN ? address(this).balance : POOL_ITEM.INFO.BASE_TOKEN.balanceOf(address(this));
        uint256 baseToken = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
        require(baseToken > 0, 'NOTHING TO WITHDRAW');
        POOL_ITEM.STATUS.TOTAL_BASE_WITHDRAWN = POOL_ITEM.STATUS.TOTAL_BASE_WITHDRAWN.add(buyer.baseDeposited);
        buyer.baseDeposited = 0;
        TransferHelper.safeTransferBaseToken(address(POOL_ITEM.INFO.BASE_TOKEN), payable(msg.sender), baseToken, !POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN);
        emit UserWithdrawBaseToken(msg.sender, baseToken);
    }

    // on pool failure
    // allows the owner to withdraw the tokens they sent for pool
    function ownerWithdrawPoolToken() external onlyPoolOwner {
        // Require Status Failed
        require(getPoolStatus() == uint256(POOL_STATUS.FAILED), 'POOL NOT FAILED');
        TransferHelper.safeTransfer(address(POOL_ITEM.INFO.POOL_TOKEN), POOL_ITEM.INFO.POOL_OWNER, POOL_ITEM.INFO.POOL_TOKEN.balanceOf(address(this)));
    }

    // withdraw auction tokens
    // percentile withdrawals allows fee on transfer or rebasing tokens to still work
    function userWithdrawAuctionToken() external nonReentrant {
        require(getPoolStatus() == uint256(POOL_STATUS.FAILED) || getPoolStatus() == uint256(POOL_STATUS.SUCCESS), 'POOL NOT FAILED OR SUCCESS');
        require(!getUserWhitelistStatus(msg.sender), 'YOU ARE IN WHITELIST');
        require(!POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_WITHDRAW.contains(msg.sender), 'YOU ALREADY WITHDRAW AUCTION TOKEN');
        uint256 tokenAmount = getAuctionUserInfo(msg.sender);
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_WITHDRAW.add(msg.sender);
        TransferHelper.safeTransfer(address(POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS), msg.sender, tokenAmount);
        emit UserWithdrawAuctionToken(msg.sender, tokenAmount);
    }

    // if something goes wrong in pool
    function forceFailByAdmin() onlyAdmin external {
        POOL_ITEM.STATUS.FORCE_FAILED = true;
    }

    // on pool success, this is the final step to end the pool, active claim and enable withdrawals of the pool token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic are not taken into account at this stage.
    function activeClaim() external onlyPoolOwner nonReentrant {
        require(!POOL_ITEM.STATUS.ACTIVE_CLAIM, 'ALREADY ACTIVE CLAIM');
        require(getPoolStatus() == uint256(POOL_STATUS.SUCCESS), 'POOL NOT SUCCESS');

        uint256 notSoldToken = POOL_ITEM.INFO.AMOUNT.sub(POOL_ITEM.STATUS.TOTAL_TOKEN_SOLD);

        // Burn Zero Round Token
        uint256 zeroRoundTokenBurn = 0;
        if (POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT > 0) {
            uint256 zeroRoundRegisteredTokenAmount = POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT.mul(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
            uint256 zeroRoundTokenBalance = IERC20(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS).balanceOf(address(this));
            zeroRoundTokenBurn = zeroRoundRegisteredTokenAmount > zeroRoundTokenBalance ? zeroRoundTokenBalance : zeroRoundRegisteredTokenAmount;
            TransferHelper.safeTransfer(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, 0x000000000000000000000000000000000000dEaD, zeroRoundTokenBurn);
        }

        // Burn Auction Round Token
        uint256 auctionRoundTokenBurn = 0;
        if (POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REGISTERED_SLOT > 0) {
            uint256 auctionRoundRegisteredTokenAmount = getAuctionAmountToBurn();
            uint256 auctionRoundTokenBalance = IERC20(POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS).balanceOf(address(this));
            auctionRoundTokenBurn = auctionRoundRegisteredTokenAmount > auctionRoundTokenBalance ? auctionRoundTokenBalance : auctionRoundRegisteredTokenAmount;
            TransferHelper.safeTransfer(POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS, 0x000000000000000000000000000000000000dEaD, auctionRoundTokenBurn);
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.BURNED_TOKEN_AMOUNT = auctionRoundTokenBurn;
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REFUND_TOKEN_AMOUNT = POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOTAL_TOKEN_AMOUNT.sub(auctionRoundTokenBurn);
        }

        POOL_ITEM.STATUS.ACTIVE_CLAIM = true;
        POOL_ITEM.STATUS.ACTIVE_CLAIM_AT = block.timestamp;
        emit ActiveClaim(zeroRoundTokenBurn, auctionRoundTokenBurn, notSoldToken);
    }

    // on pool success, owner withdraw base token
    function ownerWithdrawBaseToken() external onlyPoolOwner nonReentrant {
        require(getPoolStatus() == uint256(POOL_STATUS.SUCCESS), 'POOL NOT SUCCESS');
        // send remaining base tokens to pool owner
        uint256 remainingBaseTokenBalance = POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN ? address(this).balance : POOL_ITEM.INFO.BASE_TOKEN.balanceOf(address(this));
        TransferHelper.safeTransferBaseToken(address(POOL_ITEM.INFO.BASE_TOKEN), POOL_ITEM.INFO.POOL_OWNER, remainingBaseTokenBalance, !POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN);
    }

    // Update Limit Per Buyer
    function updateLimitPerBuyer(uint256 _limitPerBuyer) external onlyPoolOwner {
        require(POOL_ITEM.INFO.START_TIME > block.timestamp, 'POOL: POOL STARTED');
        POOL_ITEM.INFO.LIMIT_PER_BUYER = _limitPerBuyer;
    }

    // postpone or bring a pool forward, this will only work when a pool is pending (not start).
    function updateTime(uint256 _startTime, uint256 _endTime) external onlyPoolOwner {
        require(POOL_ITEM.INFO.START_TIME > block.timestamp);
        require(_startTime.add(POOL_SETTING.getMaxPoolLength()) >= _endTime);
        POOL_ITEM.INFO.START_TIME = _startTime;
        POOL_ITEM.INFO.END_TIME = _endTime;
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT = _startTime - POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND;
    }

    // GET WHITELIST FLAG
    function getWhitelistFlag() external view returns (bool) {
        return POOL_ITEM.STATUS.WHITELIST_ONLY;
    }

    // SET WHITELIST FLAG
    function setWhitelistFlag(bool _flag) external onlyPoolOwner {
        POOL_ITEM.STATUS.WHITELIST_ONLY = _flag;
    }

    // EDIT WHITELIST LIST
    function editWhitelist(address[] memory _users, bool _add) external onlyPoolOwner {
        require(getPoolStatus() != uint256(POOL_STATUS.SUCCESS), 'POOL ALREADY SUCCESS');
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
    function getWhitelistedUsersLength() public view returns (uint256) {
        return WHITELIST.length();
    }

    // WHITELIST AT INDEX
    function getWhitelistedUserAtIndex(uint256 _index) public view returns (address) {
        return WHITELIST.at(_index);
    }

    // GET USER WHITELIST STATUS
    function getUserWhitelistStatus(address _user) public view returns (bool) {
        return WHITELIST.contains(_user);
    }

    // REGISTER ZERO ROUND
    function registerZeroRound() external nonReentrant {
        if (POOL_ITEM.STATUS.WHITELIST_ONLY) {
            require(WHITELIST.contains(msg.sender), 'POOL: NOT WHITELISTED');
        }

        require(POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND, 'POOL: ZERO ROUND NOT ACTIVE');
        require(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS != address(0), 'POOL: ZERO ROUND NOT ACTIVE');
        require(getPoolRound() == 0, "POOL: ZERO ROUND FINISHED");
        require(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT < POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT, "POOL: ZERO ROUND ENOUGH SLOT");
        require(!POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.contains(msg.sender), "POOL: ZERO ROUND ALREADY REGISTERED");

        TransferHelper.safeTransferFrom(POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS, address(msg.sender), address(this), POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT);
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT = POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT.add(1);
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.add(msg.sender);
    }

    // REGISTER AUCTION ROUND
    function registerAuctionRound(uint256 _amount) external nonReentrant {
        require(_amount > 0, 'POOL: AUCTION INVALID AMOUNT');
        require(POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND, 'POOL: AUCTION ROUND NOT ACTIVE');
        require(POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS != address(0), 'POOL: AUCTION ROUND NOT ACTIVE');
        require(block.timestamp >= POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.START_TIME && block.timestamp <= POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.END_TIME, "POOL: INVALID AUCTION TIME");

        TransferHelper.safeTransferFrom(POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS, address(msg.sender), address(this), _amount);
        if (!POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_USER.contains(msg.sender)) {
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REGISTERED_SLOT = POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REGISTERED_SLOT.add(1);
            POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_USER.add(msg.sender);
        }
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_AMOUNT[msg.sender] = POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_AMOUNT[msg.sender].add(_amount);
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOTAL_TOKEN_AMOUNT = POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOTAL_TOKEN_AMOUNT.add(_amount);
    }

    // Update vesting info when not active claim
    function updateVestingInfo(
        uint256[] memory _vestingPeriod,
        uint256[] memory _vestingPercent
    ) external onlyPoolOwner nonReentrant {
        require(!POOL_ITEM.STATUS.ACTIVE_CLAIM, 'ALREADY ACTIVE CLAIM');
        require(POOL_ITEM.VESTING_INFO.ACTIVE_VESTING, 'POOL NOT ACTIVE VESTING');

        require(_vestingPeriod.length > 0, 'INVALID VESTING PERIOD');
        require(_vestingPeriod.length == _vestingPercent.length, 'INVALID VESTING DATA');
        uint256 totalVestingPercent = 0;
        for (uint256 i = 0; i < _vestingPercent.length; i++) {
            totalVestingPercent = totalVestingPercent.add(_vestingPercent[i]);
        }
        require(totalVestingPercent == 1000, 'INVALID VESTING PERCENT');

        POOL_ITEM.VESTING_INFO.VESTING_PERIOD = _vestingPeriod;
        POOL_ITEM.VESTING_INFO.VESTING_PERCENT = _vestingPercent;
    }

    // GENERAL INFO
    function getGeneralInfo() external view returns (uint256 contractVersion, string memory contractType, address poolGenerator) {
        return (POOL_ITEM.CONTRACT_VERSION, POOL_ITEM.CONTRACT_TYPE, POOL_ITEM.POOL_GENERATOR);
    }

    // GET ROUND INFO
    function getRoundInfo() external view returns (bool activeZeroRound, bool activeFirstRound, bool activeAuctionRound) {
        return (POOL_ITEM.ROUND_INFO.ACTIVE_ZERO_ROUND, POOL_ITEM.ROUND_INFO.ACTIVE_FIRST_ROUND, POOL_ITEM.ROUND_INFO.ACTIVE_AUCTION_ROUND);
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
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_ADDRESS,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.TOKEN_AMOUNT,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.PERCENT,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_BEFORE_FIRST_ROUND,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.FINISH_AT,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_BASE_TOKEN_AMOUNT,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.MAX_SLOT,
        POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.REGISTERED_SLOT
        );
    }

    // ZERO ROUND USER LENGTH
    function getZeroRoundUserLength() external view returns (uint256) {
        return POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.length();
    }
    // ZERO ROUND USER AT INDEX
    function getZeroRoundUserAtIndex(uint256 _index) external view returns (address) {
        return POOL_ITEM.ROUND_INFO.ZERO_ROUND_INFO.LIST_USER.at(_index);
    }

    // STATUS INFO
    function getStatusInfo() external view returns (
        bool whitelistOnly,
        bool isActiveClaim,
        bool forceFailed,
        uint256 totalBaseCollected,
        uint256 totalTokenSold,
        uint256 totalTokenWithdrawn,
        uint256 totalBaseWithdrawn,
        uint256 firstRoundLength,
        uint256 numBuyers,
        uint256 successAt,
        uint256 activeClaimAt,
        uint256 currentStatus,
        int8 currentRound
    ) {
        return (
        POOL_ITEM.STATUS.WHITELIST_ONLY,
        POOL_ITEM.STATUS.ACTIVE_CLAIM,
        POOL_ITEM.STATUS.FORCE_FAILED,
        POOL_ITEM.STATUS.TOTAL_BASE_COLLECTED,
        POOL_ITEM.STATUS.TOTAL_TOKEN_SOLD,
        POOL_ITEM.STATUS.TOTAL_TOKEN_WITHDRAWN,
        POOL_ITEM.STATUS.TOTAL_BASE_WITHDRAWN,
        POOL_ITEM.STATUS.FIRST_ROUND_LENGTH,
        POOL_ITEM.STATUS.NUM_BUYERS,
        POOL_ITEM.STATUS.SUCCESS_AT,
        POOL_ITEM.STATUS.ACTIVE_CLAIM_AT,
        getPoolStatus(),
        getPoolRound()
        );
    }

    // LIST BUYER LENGTH
    function getListBuyerLength() external view returns (uint256) {
        return POOL_ITEM.STATUS.LIST_BUYER.length();
    }
    // LIST BUYER AT INDEX
    function getListBuyerLengthAtIndex(uint256 _index) external view returns (address) {
        return POOL_ITEM.STATUS.LIST_BUYER.at(_index);
    }

    // GET MAIN INFO
    function getPoolMainInfo() external view returns (
        uint256 tokenPrice,
        uint256 limitPerBuyer,
        uint256 amount,
        uint256 hardCap,
        uint256 softCap,
        uint256 startTime,
        uint256 endTime,
        bool poolInMainToken
    ) {
        return (
        POOL_ITEM.INFO.TOKEN_PRICE,
        POOL_ITEM.INFO.LIMIT_PER_BUYER,
        POOL_ITEM.INFO.AMOUNT,
        POOL_ITEM.INFO.HARD_CAP,
        POOL_ITEM.INFO.SOFT_CAP,
        POOL_ITEM.INFO.START_TIME,
        POOL_ITEM.INFO.END_TIME,
        POOL_ITEM.INFO.POOL_IN_MAIN_TOKEN
        );
    }

    // GET ADDRESS INFO
    function getPoolAddressInfo() external view returns (
        address poolOwner,
        address poolToken,
        address baseToken,
        address wrapTokenAddress
    ) {
        return (
        POOL_ITEM.INFO.POOL_OWNER,
        address(POOL_ITEM.INFO.POOL_TOKEN),
        address(POOL_ITEM.INFO.BASE_TOKEN),
        POOL_ITEM.INFO.WRAP_TOKEN_ADDRESS
        );
    }

    function getBuyerInfo(address _address) external view returns (uint256 baseDeposited, uint256 tokenBought, uint256 tokenClaimed, uint256 numberClaimed, uint256[] memory historyTimeClaimed, uint256[] memory historyAmountClaimed) {
        return (BUYERS[_address].baseDeposited, BUYERS[_address].tokenBought, BUYERS[_address].tokenClaimed, BUYERS[_address].numberClaimed, BUYERS[_address].historyTimeClaimed, BUYERS[_address].historyAmountClaimed);
    }

    // GET AUCTION ROUND INFO
    function getAuctionRoundInfo() external view returns (
        address tokenAddress,
        uint256 startTime,
        uint256 endTime,
        uint256 registeredSlot,
        uint256 totalTokenAmount,
        uint256 burnedTokenAmount,
        uint256 refundTokenAmount
    ) {
        return (
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOKEN_ADDRESS,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.START_TIME,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.END_TIME,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REGISTERED_SLOT,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.TOTAL_TOKEN_AMOUNT,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.BURNED_TOKEN_AMOUNT,
        POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.REFUND_TOKEN_AMOUNT
        );
    }

    // USER AUCTION LENGTH
    function getAuctionUserLength() external view returns (uint256) {
        return POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_USER.length();
    }

    // USER AUCTION AT INDEX
    function getAuctionUserAtIndex(uint256 _index) external view returns (address) {
        return POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_USER.at(_index);
    }

    function getAuctionUserInfo(address _address) public view returns (uint256 auctionAmount) {
        return POOL_ITEM.ROUND_INFO.AUCTION_ROUND_INFO.LIST_AMOUNT[_address];
    }

    // Get Auction Amount Burn By Whitelist
    function getAuctionAmountToBurn() public view returns (uint256 burnAmount){
        uint256 whitelistLength = getWhitelistedUsersLength();
        uint256 totalToken = 0;
        for (uint256 i = 0; i < whitelistLength; i++) {
            totalToken = totalToken.add(getAuctionUserInfo(getWhitelistedUserAtIndex(i)));
        }
        return totalToken;
    }

    function getVestingInfo() external view returns (bool activeVesting, uint256[] memory vestingPeriod, uint256[] memory vestingPercent) {
        return (POOL_ITEM.VESTING_INFO.ACTIVE_VESTING, POOL_ITEM.VESTING_INFO.VESTING_PERIOD, POOL_ITEM.VESTING_INFO.VESTING_PERCENT);
    }

    function retrieveToken(address tokenAddress, uint256 amount) external onlyAdmin returns (bool) {
        return IERC20(tokenAddress).transfer(POOL_SETTING.getAdminAddress(), amount);
    }

    function retrieveBalance(uint256 amount) external onlyAdmin {
        payable(POOL_SETTING.getAdminAddress()).transfer(amount);
    }
}