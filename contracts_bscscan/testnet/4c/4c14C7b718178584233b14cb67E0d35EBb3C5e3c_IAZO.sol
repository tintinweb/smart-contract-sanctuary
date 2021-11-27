//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

/*
 * ApeSwapFinance 
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com    
 * Twitter:         https://twitter.com/ape_swap 
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/ERC20.sol";
import "./interface/IWNative.sol";
import "./interface/IIAZOSettings.sol";
import "./interface/IIAZOLiquidityLocker.sol";


/**
 *  Welcome to the "Initial Ape Zone Offering" (IAZO) contract
 */
/// @title IAZO
/// @author ApeSwapFinance
/// @notice IAZO contract where to buy the tokens from
contract IAZO is Initializable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    event ForceFailed(address indexed by);
    event UpdateMaxSpendLimit(uint256 previousMaxSpend, uint256 newMaxSpend);
    event FeesCollected(address indexed feeAddress, uint256 baseFeeCollected, uint256 IAZOTokenFee);
    event UpdateIAZOBlocks(uint256 previousStartTime, uint256 newStartBlock, uint256 previousActiveTime, uint256 newActiveBlocks);
    event AddLiquidity(uint256 baseLiquidity, uint256 saleTokenLiquidity, uint256 remainingBaseBalance);
    event SweepWithdraw(
        address indexed receiver, 
        IERC20 indexed token, 
        uint256 balance
    );
    event UserWithdrawSuccess(address _address, uint256 _amount);
    event UserWithdrawFailed(address _address, uint256 _amount);
    event UserDeposited(address _address, uint256 _amount);

    struct IAZOInfo {
        address payable IAZO_OWNER; //IAZO_OWNER address
        ERC20 IAZO_TOKEN; // token offered for IAZO
        ERC20 BASE_TOKEN; // token to buy IAZO_TOKEN
        bool IAZO_SALE_IN_NATIVE; // IAZO sale in NATIVE or ERC20.
        /// @dev To account for tokens with different decimals values the TOKEN_PRICE/LISTING_PRICE need to account for that
        /// Find the amount of tokens in BASE_TOKENS that 1 IAZO_TOKEN costs and use the equation below to find the TOKEN_PRICE
        /// TOKEN_PRICE = BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        /// i.e. 1 IAZO 8 decimal token (1e8) = 1 BASE_TOKEN 18 decimal token (1e18): TOKEN_PRICE = 1e28
        uint256 TOKEN_PRICE; // BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        uint256 AMOUNT; // amount of IAZO_TOKENS for sale
        uint256 HARDCAP; // hardcap of earnings.
        uint256 SOFTCAP; // softcap for earning. if not reached IAZO is cancelled 
        uint256 MAX_SPEND_PER_BUYER; // max spend per buyer
        uint256 LIQUIDITY_PERCENT; // 1 = 0.1%
        /// @dev Find the amount of tokens in BASE_TOKENS that 1 IAZO_TOKEN will be listed for and use the equation below to find the LISTING_PRICE
        /// LISTING_PRICE = BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        uint256 LISTING_PRICE; // BASE_TOKEN_AMOUNT * 10**(18 - iazoTokenDecimals)
        bool BURN_REMAINS;
    }

    struct IAZOTimeInfo {
        uint256 START_TIME; // start timestamp of the IAZO
        uint256 ACTIVE_TIME; // end of IAZO -> START_TIME + ACTIVE_TIME
        uint256 LOCK_PERIOD; // unix timestamp (3 weeks) to lock earned tokens for IAZO_OWNER
    }

    struct IAZOStatus {
        bool LP_GENERATION_COMPLETE; // final flag required to end a iazo and enable withdrawals
        bool FORCE_FAILED; // set this flag to force fail the iazo
        uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
        uint256 TOTAL_TOKENS_SOLD; // total iazo tokens sold
        uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful iazo
        uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on iazo failure
        uint256 NUM_BUYERS; // number of unique participants
    }

    struct BuyerInfo {
        uint256 deposited; // deposited base tokens, if IAZO fails these can be withdrawn
        uint256 tokensBought; // bought tokens. can be withdrawn on iazo success
    }

    struct FeeInfo {
        address payable FEE_ADDRESS;
        uint256 BASE_FEE; // 1 = 0.1%
        uint256 IAZO_TOKEN_FEE; // 1 = 0.1%
    }

    bool constant public isIAZO = true;

    // structs
    IAZOInfo public IAZO_INFO;
    IAZOTimeInfo public IAZO_TIME_INFO;
    IAZOStatus public STATUS;
    FeeInfo public FEE_INFO;
    // contracts
    IIAZOSettings public IAZO_SETTINGS;
    IIAZOLiquidityLocker public IAZO_LIQUIDITY_LOCKER;
    IWNative WNative;
    /// @dev reference variable
    address public IAZO_FACTORY;
    // addresses
    address public TOKEN_LOCK_ADDRESS;
    // BuyerInfo mapping
    mapping(address => BuyerInfo) public BUYERS;

    /// @notice Initialization of IAZO
    /// @dev This contract should not be deployed without the factory as important safety checks are made before deployment
    /// @param _addresses [IAZOSettings, IAZOLiquidityLocker]
    /// @param _addressesPayable [IAZOOwner, feeAddress]
    /// @param _uint256s [_tokenPrice,  _amount, _hardcap,  _softcap, _maxSpendPerBuyer, _liquidityPercent, _listingPrice, _startTime, _activeTime, _lockPeriod, _baseFee, iazoTokenFee]
    /// @param _bools [_burnRemains]
    /// @param _ERC20s [_iazoToken, _baseToken]
    /// @param _wnative Address of the Wrapped Native token for the chain
    function initialize(
        address[2] memory _addresses, 
        address payable[2] memory _addressesPayable, 
        uint256[12] memory _uint256s, 
        bool[1] memory _bools, 
        ERC20[2] memory _ERC20s, 
        IWNative _wnative
    ) external initializer {
        IAZO_FACTORY = msg.sender;
        WNative = _wnative;

        IAZO_SETTINGS = IIAZOSettings(_addresses[0]);
        IAZO_LIQUIDITY_LOCKER = IIAZOLiquidityLocker(_addresses[1]);

        IAZO_INFO.IAZO_OWNER = _addressesPayable[0]; // User which created the IAZO
        FEE_INFO.FEE_ADDRESS = _addressesPayable[1];

        IAZO_INFO.IAZO_SALE_IN_NATIVE = address(_ERC20s[1]) == address(WNative) ? true : false;
        IAZO_INFO.TOKEN_PRICE = _uint256s[0]; // Price of time in base currency
        IAZO_INFO.AMOUNT = _uint256s[1]; // Amount of tokens for sale
        IAZO_INFO.HARDCAP = _uint256s[2]; // Hardcap base token to collect (TOKEN_PRICE * AMOUNT)
        IAZO_INFO.SOFTCAP = _uint256s[3]; // Minimum amount of base tokens to collect for successful IAZO
        IAZO_INFO.MAX_SPEND_PER_BUYER = _uint256s[4]; // Max amount of base tokens that can be used to purchase IAZO token per account
        IAZO_INFO.LIQUIDITY_PERCENT = _uint256s[5]; // Percentage of liquidity to lock after IAZO
        IAZO_INFO.LISTING_PRICE = _uint256s[6]; // The rate to be listed for liquidity
        IAZO_TIME_INFO.START_TIME = _uint256s[7];
        IAZO_TIME_INFO.ACTIVE_TIME = _uint256s[8];
        IAZO_TIME_INFO.LOCK_PERIOD = _uint256s[9];
        FEE_INFO.BASE_FEE = _uint256s[10];
        FEE_INFO.IAZO_TOKEN_FEE = _uint256s[11];

        IAZO_INFO.BURN_REMAINS = _bools[0]; // Burn remainder of IAZO tokens not sold

        IAZO_INFO.IAZO_TOKEN = _ERC20s[0]; // Token for sale 
        IAZO_INFO.BASE_TOKEN = _ERC20s[1]; // Token used to buy IAZO token
    }

    /// @notice Modifier: Only allow admin address to call certain functions
    modifier onlyAdmin() {
        require(IAZO_SETTINGS.isAdmin(msg.sender), "Admin only");
        _;
    }

    /// @notice Modifier: Only allow IAZO owner address to call certain functions
    modifier onlyIAZOOwner() {
        require(msg.sender == IAZO_INFO.IAZO_OWNER, "IAZO owner only");
        _;
    }

    /// @notice Modifier: Only allow IAZO owner address to call certain functions
    modifier onlyIAZOFactory() {
        require(msg.sender == IAZO_FACTORY, "IAZO_FACTORY only");
        _;
    }

    /// @notice The state of the IAZO
    /// @return The state of the IAZO
    function getIAZOState() public view returns (uint256) {
        // 4 FAILED - force fail
        if (STATUS.FORCE_FAILED) return 4; 
        // 4 FAILED - softcap not met by end timestamp
        if ((block.timestamp > IAZO_TIME_INFO.START_TIME + IAZO_TIME_INFO.ACTIVE_TIME) && (STATUS.TOTAL_BASE_COLLECTED < IAZO_INFO.SOFTCAP)) return 4; 
        // 3 SUCCESS - hardcap met
        if (STATUS.TOTAL_BASE_COLLECTED >= IAZO_INFO.HARDCAP) return 3; 
        // 2 SUCCESS - end timestamp and soft cap reached
        if ((block.timestamp > IAZO_TIME_INFO.START_TIME + IAZO_TIME_INFO.ACTIVE_TIME) && (STATUS.TOTAL_BASE_COLLECTED >= IAZO_INFO.SOFTCAP)) return 2; 
        // 1 ACTIVE - deposits enabled
        if ((block.timestamp >= IAZO_TIME_INFO.START_TIME) && (block.timestamp <= IAZO_TIME_INFO.START_TIME + IAZO_TIME_INFO.ACTIVE_TIME)) return 1; 
        // 0 QUEUED - awaiting starting timestamp
        return 0; 
    }

    /// @notice Buy IAZO tokens with native coin
    function userDepositNative () external payable {
        require(IAZO_INFO.IAZO_SALE_IN_NATIVE, "not a native token IAZO");
        userDepositPrivate(msg.value);
    }

    /// @notice Buy IAZO tokens with base token
    /// @param _amount Amount of base tokens to use to buy IAZO tokens for
    function userDeposit (uint256 _amount) external {
        require(!IAZO_INFO.IAZO_SALE_IN_NATIVE, "cannot deposit tokens in a native token sale");
        userDepositPrivate(_amount);
    }

    /// @notice Internal function used to buy IAZO tokens in either native coin or base token
    /// @param _amount Amount of base tokens to use to buy IAZO tokens for
    function userDepositPrivate (uint256 _amount) private nonReentrant {
        require(_amount > 0, 'deposit amount must be greater than zero');
        // Check that IAZO is in the ACTIVE state for user deposits
        require(getIAZOState() == 1, 'IAZO not active');
        BuyerInfo storage buyer = BUYERS[msg.sender];

        uint256 allowance = IAZO_INFO.MAX_SPEND_PER_BUYER - buyer.deposited;
        uint256 remaining = IAZO_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
        allowance = allowance > remaining ? remaining : allowance;
        uint256 allowedAmount = _amount;
        if (_amount > allowance) {
            allowedAmount = allowance;
        }

        uint256 depositedAmount = allowedAmount;
        // return unused NATIVE tokens
        if (IAZO_INFO.IAZO_SALE_IN_NATIVE && allowedAmount < msg.value) {
            transferNativeCurrencyPrivate(payable(msg.sender), msg.value - allowedAmount);
        }
        // deduct non NATIVE token from user
        if (!IAZO_INFO.IAZO_SALE_IN_NATIVE) {
            /// @dev Find actual transfer amount if reflect token
            uint256 beforeBaseBalance = IAZO_INFO.BASE_TOKEN.balanceOf(address(this));
            IAZO_INFO.BASE_TOKEN.safeTransferFrom(msg.sender, address(this), allowedAmount);
            depositedAmount = IAZO_INFO.BASE_TOKEN.balanceOf(address(this)) - beforeBaseBalance;
        }

        uint256 tokensSold = (depositedAmount * 1e18) / IAZO_INFO.TOKEN_PRICE;
        require(tokensSold > 0, '0 tokens bought');
        if (buyer.deposited == 0) {
            STATUS.NUM_BUYERS++;
        }
        buyer.deposited += depositedAmount;
        buyer.tokensBought += tokensSold;
        STATUS.TOTAL_BASE_COLLECTED += depositedAmount;
        STATUS.TOTAL_TOKENS_SOLD += tokensSold;
        
        emit UserDeposited(msg.sender, depositedAmount);
    }

    /// @notice The function users call to withdraw funds
    function userWithdraw() external {
        uint256 currentIAZOState = getIAZOState();
        require(
            currentIAZOState == 2 || // SUCCESS
            currentIAZOState == 3 || // HARD_CAP_MET
            currentIAZOState == 4,   // FAILED 
            'Invalid IAZO state withdraw'
        );
       
       // Failed
       if(currentIAZOState == 4) { 
           userWithdrawFailedPrivate();
       }
        // Success / hardcap met
       if(currentIAZOState == 2 || currentIAZOState == 3) { 
           userWithdrawSuccessPrivate();
       }
    }

    function userWithdrawSuccessPrivate() private {
        if(!STATUS.LP_GENERATION_COMPLETE){
            addLiquidity();
        }
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(buyer.tokensBought > 0, 'Nothing to withdraw');
        STATUS.TOTAL_TOKENS_WITHDRAWN += buyer.tokensBought;
        uint256 tokensToTransfer = buyer.tokensBought;
        buyer.tokensBought = 0;
        IAZO_INFO.IAZO_TOKEN.safeTransfer(msg.sender, tokensToTransfer);
        emit UserWithdrawSuccess(msg.sender, tokensToTransfer);
    }

    function userWithdrawFailedPrivate() private {
        BuyerInfo storage buyer = BUYERS[msg.sender];
        require(buyer.deposited > 0, 'Nothing to withdraw');
        STATUS.TOTAL_BASE_WITHDRAWN += buyer.deposited;
        uint256 tokensToTransfer = buyer.deposited;
        buyer.deposited = 0;
        
        if(IAZO_INFO.IAZO_SALE_IN_NATIVE){
            transferNativeCurrencyPrivate(payable(msg.sender), tokensToTransfer);
        } else {
            IAZO_INFO.BASE_TOKEN.safeTransfer(msg.sender, tokensToTransfer);
        }
        emit UserWithdrawFailed(msg.sender, tokensToTransfer);
    }

    function transferNativeCurrencyPrivate(address payable _to, uint256 _value) private {
        (bool success,) = _to.call{value: _value}("");
        require(success, "failed to send native currency");
    }

    /**
     * onlyAdmin functions
     */

    function forceFailAdmin() external onlyAdmin {
        /// @notice Cannot fail IAZO after liquidity has been added
        require(!STATUS.LP_GENERATION_COMPLETE, 'LP Generation is already complete');
        STATUS.FORCE_FAILED = true;
        emit ForceFailed(msg.sender);
    }

    /**
     * onlyIAZOOwner functions
     */

    /// @notice Change start and end of IAZO
    /// @param _startTime New start time of IAZO
    /// @param _activeTime New active time of IAZO
    function updateStart(uint256 _startTime, uint256 _activeTime) external onlyIAZOOwner {
        require(IAZO_TIME_INFO.START_TIME > block.timestamp, "IAZO has already started");
        require(_startTime >= IAZO_SETTINGS.getMinStartTime(), "Start time must be in future");
        require(_activeTime >= IAZO_SETTINGS.getMinIAZOLength(), "IAZO active time is too short");
        require(_activeTime <= IAZO_SETTINGS.getMaxIAZOLength(), "IAZO active time is too long");
        uint256 previousStartTime = IAZO_TIME_INFO.START_TIME;
        IAZO_TIME_INFO.START_TIME = _startTime;

        uint256 previousActiveTime = IAZO_TIME_INFO.ACTIVE_TIME;
        IAZO_TIME_INFO.ACTIVE_TIME = _activeTime;
        emit UpdateIAZOBlocks(previousStartTime, IAZO_TIME_INFO.START_TIME, previousActiveTime, IAZO_TIME_INFO.ACTIVE_TIME);
    }

    /// @notice Change the max spend limit for a buyer
    /// @param _maxSpend New spend limit
    function updateMaxSpendLimit(uint256 _maxSpend) external onlyIAZOOwner {
        uint256 previousMaxSpend = IAZO_INFO.MAX_SPEND_PER_BUYER;
        IAZO_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
        emit UpdateMaxSpendLimit(previousMaxSpend, IAZO_INFO.MAX_SPEND_PER_BUYER);
    }

    /// @notice Final step when IAZO is successful. lock liquidity and enable withdrawals of sale token.
    function addLiquidity() public nonReentrant { 
        require(!STATUS.LP_GENERATION_COMPLETE, 'LP Generation is already complete');
        uint256 currentIAZOState = getIAZOState();
        // Check if IAZO SUCCESS or HARDCAP met
        require(currentIAZOState == 2 || currentIAZOState == 3, 'IAZO failed or still in progress'); // SUCCESS

        ERC20 iazoToken = IAZO_INFO.IAZO_TOKEN;
        ERC20 baseToken = IAZO_INFO.BASE_TOKEN;

        // If pair for this token has already been initialized, then this will fail the IAZO
        if (IAZO_LIQUIDITY_LOCKER.apePairIsInitialized(address(iazoToken), address(baseToken))) {
            STATUS.FORCE_FAILED = true;
            return;
        }

        //calculate fees
        uint256 apeswapBaseFee = STATUS.TOTAL_BASE_COLLECTED * FEE_INFO.BASE_FEE / 1000;
        uint256 apeswapIAZOTokenFee = STATUS.TOTAL_TOKENS_SOLD * FEE_INFO.IAZO_TOKEN_FEE / 1000;
                
        // base token liquidity
        uint256 baseLiquidity = STATUS.TOTAL_BASE_COLLECTED * IAZO_INFO.LIQUIDITY_PERCENT / 1000;
        
        bool saleInNativeCurrency = IAZO_INFO.IAZO_SALE_IN_NATIVE;

        // deposit NATIVE to receive WNative tokens
        if (saleInNativeCurrency) {
            WNative.deposit{value : baseLiquidity}();
        }

        baseToken.approve(address(IAZO_LIQUIDITY_LOCKER), baseLiquidity);

        // sale token liquidity
        uint256 saleTokenLiquidity = (baseLiquidity * 1e18) / IAZO_INFO.LISTING_PRICE;
        iazoToken.approve(address(IAZO_LIQUIDITY_LOCKER), saleTokenLiquidity);

        address payable feeAddress = FEE_INFO.FEE_ADDRESS;
        address payable iazoOwner = IAZO_INFO.IAZO_OWNER;

        address newTokenLockContract = IAZO_LIQUIDITY_LOCKER.lockLiquidity(
            baseToken, 
            iazoToken, 
            baseLiquidity, 
            saleTokenLiquidity, 
            block.timestamp + IAZO_TIME_INFO.LOCK_PERIOD, 
            iazoOwner
        );
        TOKEN_LOCK_ADDRESS = newTokenLockContract;

        STATUS.LP_GENERATION_COMPLETE = true;

        if(saleInNativeCurrency){
            transferNativeCurrencyPrivate(feeAddress, apeswapBaseFee);
        } else { 
            baseToken.safeTransfer(feeAddress, apeswapBaseFee);
        }
        iazoToken.safeTransfer(feeAddress, apeswapIAZOTokenFee);
        emit FeesCollected(feeAddress, apeswapBaseFee, apeswapIAZOTokenFee);

        // send remaining iazo tokens to iazo owner
        uint256 remainingIAZOTokenBalance = iazoToken.balanceOf(address(this));
        if (remainingIAZOTokenBalance > STATUS.TOTAL_TOKENS_SOLD) {
            uint256 amountLeft = remainingIAZOTokenBalance - STATUS.TOTAL_TOKENS_SOLD;
            if(IAZO_INFO.BURN_REMAINS){
                iazoToken.safeTransfer(IAZO_SETTINGS.getBurnAddress(), amountLeft);
            } else {
                iazoToken.safeTransfer(iazoOwner, amountLeft);
            }
        }
        
        // send remaining base tokens to iazo owner
        uint256 remainingBaseBalance = saleInNativeCurrency ? address(this).balance : baseToken.balanceOf(address(this));
        
        if(saleInNativeCurrency) {
            transferNativeCurrencyPrivate(iazoOwner, remainingBaseBalance);
        } else {
            baseToken.safeTransfer(iazoOwner, remainingBaseBalance);
        }
        
        emit AddLiquidity(baseLiquidity, saleTokenLiquidity, remainingBaseBalance);

    }

    /// @notice A public function to sweep accidental ERC20 transfers to this contract. 
    /// @param _tokens Array of ERC20 addresses to sweep
    /// @param _to Address to send tokens to
    function sweepTokens(ERC20[] memory _tokens, address _to) external onlyAdmin {
        for (uint256 index = 0; index < _tokens.length; index++) {
            ERC20 token = _tokens[index];
            require(token != IAZO_INFO.IAZO_TOKEN, "cannot sweep IAZO_TOKEN");
            require(token != IAZO_INFO.BASE_TOKEN, "cannot sweep BASE_TOKEN");
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(_to, balance);
            emit SweepWithdraw(_to, token, balance);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

/**
 * A Wrapped token interface for native EVM tokens
 */
interface IWNative {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance

pragma solidity 0.8.6;

interface IIAZOSettings {
    function SETTINGS()
        external
        view
        returns (
            address ADMIN_ADDRESS,
            address FEE_ADDRESS,
            uint256 BASE_FEE,
            uint256 MAX_BASE_FEE,
            uint256 NATIVE_CREATION_FEE,
            uint256 MIN_IAZO_LENGTH,
            uint256 MAX_IAZO_LENGTH,
            uint256 MIN_LOCK_PERIOD
        );

    function isIAZOSettings() external view returns (bool);

    function getAdminAddress() external view returns (address);

    function isAdmin(address toCheck) external view returns (bool);

    function getMinStartTime() external view returns (uint256);

    function getMaxIAZOLength() external view returns (uint256);

    function getMinIAZOLength() external view returns (uint256);

    function getBaseFee() external view returns (uint256);

    function getIAZOTokenFee() external view returns (uint256);
    
    function getMaxBaseFee() external view returns (uint256);

    function getMaxIAZOTokenFee() external view returns (uint256);

    function getNativeCreationFee() external view returns (uint256);

    function getMinLockPeriod() external view returns (uint256);

    function getMinLiquidityPercent() external view returns (uint256);

    function getFeeAddress() external view returns (address payable);

    function getBurnAddress() external view returns (address);

    function setAdminAddress(address _address) external;

    function setFeeAddresses(address _address) external;

    function setFees(uint256 _baseFee, uint256 _iazoTokenFee, uint256 _nativeCreationFee) external;

    function setStartDelay(uint256 _maxLength) external;

    function setMaxIAZOLength(uint256 _maxLength) external;

    function setMinIAZOLength(uint256 _minLength) external;

    function setMinLockPeriod(uint256 _minLockPeriod) external;

    function setMinLiquidityPercent(uint256 _minLiquidityPercent) external;

    function setBurnAddress(address _burnAddress) external;

}

//SPDX-License-Identifier: UNLICENSED
//ALL RIGHTS RESERVED
//apeswap.finance
pragma solidity 0.8.6;

import "./ERC20.sol";

interface IIAZOLiquidityLocker {
    function APE_FACTORY() external view returns (address);

    function IAZO_EXPOSER() external view returns (address);

    function isIAZOLiquidityLocker() external view returns (bool);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function apePairIsInitialized(address _token0, address _token1)
        external
        view
        returns (bool);

    function lockLiquidity(
        ERC20 _baseToken,
        ERC20 _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockDate,
        address _withdrawer
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}