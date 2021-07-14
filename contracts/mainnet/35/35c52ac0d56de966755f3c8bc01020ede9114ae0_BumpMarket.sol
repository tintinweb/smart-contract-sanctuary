// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "./BUSDC.sol";
import "./interfaces/IVault.sol";
import "./BUMPToken.sol";
import "./BumperAccessControl.sol";

///@title Bumper Protocol Liquidity Provision Program (LPP) - Main Contract
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021
contract BumpMarket is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    BumperAccessControl
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///@dev Interest rate not used
    struct Deposit {
        uint256 interest;
        uint256 balance;
        uint256 timestamp;
    }

    struct StableCoinDetail {
        address contractAddress;
        AggregatorV3Interface priceFeed;
    }

    enum StableCoins {USDC}

    ///@dev This maps an address to cumulative details of deposit made by an LP
    mapping(address => Deposit) public depositDetails;

    ///@dev This maps an address to number of USDC used to purchase BUMP tokens
    mapping(address => uint256) public usdcForBumpPurchase;

    ///@dev This map contains StableCoins enum in bytes form to the respective address
    mapping(bytes32 => StableCoinDetail) internal stableCoinsDetail;

    uint256 public currentTVL;

    ///@dev Represents the maximum percentage of their total deposit that an LP can use to buy BUMP
    ///@dev Decimal precision will be up to 2 decimals
    uint256 public maxBumpPercent;

    ///@dev Stores number of BUMP tokens available to be distributed as rewards during the LPP
    uint256 public bumpRewardAllocation;

    ///@dev Stores maximum number of BUMP tokens that can be purchased during the LPP
    uint256 public bumpPurchaseAllocation;

    ///@dev Address of USDC yearn vault where deposits will be sent to
    address public usdcVault;

    ///@dev 1a BUMP token address
    ///@notice To be replaced in future
    address public bumpTokenAddress;

    ///@dev 1a bUSDC token address
    ///@notice To be replaced in future
    address public busdcTokenAddress;

    ///@dev These will be constants used in TVL and BUMP price formulas
    ///@notice These constants have been carefully selected to calibrate BUMP price and reward rates
    uint256 public constant BUMP_INITAL_PRICE = 6000;
    uint256 public constant SWAP_RATE_CONSTANT = 8;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG = 68;
    uint256 public constant BUMP_REWARDS_BONUS_DRAG_DIVIDER = 11000;
    uint256 public constant BUMP_REWARDS_FORMULA_CONSTANT = 6 * (10**7);

    ///@dev Emitted after an LP deposit is made
    event DepositMade(
        address indexed depositor,
        uint256 amount,
        uint256 interestRate
    );

    ///@dev Emitted when rewards are issued to the LP at the time of deposit
    event RewardIssued(address indexed rewardee, uint256 amount, uint256 price);

    ///@dev Emitted when BUMP is swapped for USDC during LPP
    event BumpPurchased(
        address indexed depositor,
        uint256 amount,
        uint256 price
    );

    ///@dev These events will be emitted when yearn related methods will be called by governance.
    event ApprovedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event DepositedAmountToYearnVault(
        string description,
        address sender,
        uint256 amount
    );
    event AmountWithdrawnFromYearn(
        string description,
        address sender,
        uint256 burnedYearnTokens,
        uint256 amountWithdrawn
    );

    ///@dev These events will be emitted when respective governance parameters will change.
    event UpdatedMaxBumpPercent(
        string description,
        address sender,
        uint256 newMaxBumpPercent
    );
    event UpdatedBumpRewardAllocation(
        string description,
        address sender,
        uint256 newBumpRewardAllocation
    );
    event UpdatedBumpPurchaseAllocation(
        string description,
        address sender,
        uint256 newBumpPurchaseAllocation
    );

    ///@notice This initializes state variables of this contract
    ///@dev This method is called during deployment by open zeppelin and works like a constructor.
    ///@param _usdcAddresses This array stores following addresses at following indexes 0: usdc address 1: usdc aggregator address 2: yUSDC address.
    ///@param _whitelistAddresses Array of white list addresses.
    ///@param _bumpTokenAddress This is the address of the BUMP token.
    ///@param _busdcTokenAddress This is the address of the BUSDC token.
    ///@param _maxBumpPercent This is the maximum percentage of deposit amount that can be used to buy BUMP tokens.
    ///@param _bumpRewardAllocation This stores a maximum number of BUMP tokens that can be distributed as rewards.
    ///@param _bumpPurchaseAllocation This stores a maximum number of BUMP tokens that can be purchased by the LPs.
    function initialize(
        address[] memory _usdcAddresses,
        address[] memory _whitelistAddresses,
        address _bumpTokenAddress,
        address _busdcTokenAddress,
        uint256 _maxBumpPercent,
        uint256 _bumpRewardAllocation,
        uint256 _bumpPurchaseAllocation
    ) public initializer {
        require(
            _bumpTokenAddress != address(0),
            "Bump Token Address cannot be 0"
        );
        require(
            _busdcTokenAddress != address(0),
            "BUSDC Token Address cannot be 0"
        );
        __Pausable_init();
        __ReentrancyGuard_init();
        _BumperAccessControl_init(_whitelistAddresses);
        stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
            .contractAddress = _usdcAddresses[0];
        stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
            .priceFeed = AggregatorV3Interface(_usdcAddresses[1]);
        usdcVault = _usdcAddresses[2];
        bumpTokenAddress = _bumpTokenAddress;
        busdcTokenAddress = _busdcTokenAddress;
        maxBumpPercent = _maxBumpPercent;
        bumpRewardAllocation = _bumpRewardAllocation;
        bumpPurchaseAllocation = _bumpPurchaseAllocation;
        _pause();
    }

    ///@notice This method pauses bUSDC token and can only be called by governance.
    function pauseProtocol() external virtual onlyGovernance {
        BUSDC(busdcTokenAddress).pause();
        _pause();
    }

    ///@notice This method un-pauses bUSDC token and can only be called by governance.
    function unpauseProtocol() external virtual onlyGovernance {
        BUSDC(busdcTokenAddress).unpause();
        _unpause();
    }

    ///@notice This returns a number of yUSDC tokens issued on the name of BumpMarket contract.
    ///@return amount returns the amount of yUSDC issued to BumpMarket by yearn vault.
    function getyUSDCIssuedToReserve()
        external
        view
        virtual
        returns (uint256 amount)
    {
        amount = IERC20Upgradeable(usdcVault).balanceOf(address(this));
    }

    ///@notice Transfers approved amount of asset ERC20 Tokens from user wallet to Reserve contract and further to yearn for yield farming. Mints bUSDC for netDeposit made to reserve and mints rewarded and purchased BUMP tokens
    ///@param _amount Amount of ERC20 tokens that need to be transfered.
    ///@param _amountForBumpPurchase Amount of deposit that user allocates for bump purchase.
    ///@param _coin Type of token.
    function depositAmount(
        uint256 _amount,
        uint256 _amountForBumpPurchase,
        StableCoins _coin
    ) external virtual nonReentrant whenNotPaused {
        uint256 bumpPurchasePercent =
            (_amountForBumpPurchase * 10000) / _amount;
        uint256 amountToDeposit = _amount - _amountForBumpPurchase;
        uint256 bumpTokensAsRewards;
        uint256 bumpTokensPurchased;
        require(
            bumpPurchasePercent <= maxBumpPercent,
            "Exceeded maximum deposit percentage that can be allocated for BUMP pruchase"
        );

        if (depositDetails[msg.sender].timestamp == 0) {
            depositDetails[msg.sender] = Deposit(
                0,
                amountToDeposit,
                block.timestamp
            );
        } else {
            depositDetails[msg.sender].balance =
                depositDetails[msg.sender].balance +
                amountToDeposit;
        }
        usdcForBumpPurchase[msg.sender] =
            usdcForBumpPurchase[msg.sender] +
            _amountForBumpPurchase;
        currentTVL = currentTVL + _amount;
        (bumpTokensAsRewards, bumpTokensPurchased) = getBumpAllocation(
            amountToDeposit,
            _amountForBumpPurchase
        );
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))]
                .contractAddress
        )
            .safeTransferFrom(msg.sender, address(this), _amount);
        ///Mint busdc tokens in user's name
        BUSDC(busdcTokenAddress).mint(msg.sender, amountToDeposit);
        ///Mint BUMP tokens in user's name
        BUMPToken(bumpTokenAddress).distributeToAddress(
            msg.sender,
            bumpTokensAsRewards + bumpTokensPurchased
        );
        _approveUSDCToYearnVault(_amount);
        _depositUSDCInYearnVault(_amount);
        emit DepositMade(msg.sender, amountToDeposit, 0);
        emit RewardIssued(
            msg.sender,
            bumpTokensAsRewards,
            getSwapRateBumpUsdc()
        );
        emit BumpPurchased(
            msg.sender,
            bumpTokensPurchased,
            getSwapRateBumpUsdc()
        );
    }

    ///@notice This acts like an external onlyGovernance interface for internal method _approveUSDCToYearnVault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function approveUSDCToYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        whenNotPaused
    {
        _approveUSDCToYearnVault(_amount);
        emit ApprovedAmountToYearnVault(
            "BUMPER ApprovedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    //////@notice This acts like an external onlyGovernance interface for internal method _depositUSDCInYearnVault.
    ///@param _amount Amount of USDC you want to deposit to the yearn vault.
    function depositUSDCInYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        nonReentrant
        whenNotPaused
    {
        _depositUSDCInYearnVault(_amount);
        emit DepositedAmountToYearnVault(
            "BUMPER DepositedAmountToYearnVault",
            msg.sender,
            _amount
        );
    }

    ///@notice Withdraws USDC from yearn vault and burn yUSDC tokens
    ///@param _amount Amount of yUSDC tokens you want to burn
    ///@return Returns the amount of USDC redeemed.
    function withdrawUSDCFromYearnVault(uint256 _amount)
        external
        virtual
        onlyGovernance
        whenNotPaused
        returns (uint256)
    {
        uint256 tokensRedeemed = IVault(usdcVault).withdraw(_amount);
        emit AmountWithdrawnFromYearn(
            "BUMPER AmountWithdrawnFromYearnVault",
            msg.sender,
            _amount,
            tokensRedeemed
        );
        return tokensRedeemed;
    }

    ///@notice This function is used to update maxBumpPercent state variable by governance.
    ///@param _maxBumpPercent New value of maxBumpPercent state variable.
    ///@dev Decimal precision is 2
    function updateMaxBumpPercent(uint256 _maxBumpPercent)
        external
        virtual
        onlyGovernance
    {
        maxBumpPercent = _maxBumpPercent;
        emit UpdatedMaxBumpPercent(
            "BUMPER UpdatedMaxBUMPPercent",
            msg.sender,
            _maxBumpPercent
        );
    }

    ///@notice This function is used to update bumpRewardAllocation state variable by governance.
    ///@param _bumpRewardAllocation New value of bumpRewardAllocation state variable.
    ///@dev Decimal precision should be 18
    function updateBumpRewardAllocation(uint256 _bumpRewardAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpRewardAllocation = _bumpRewardAllocation;
        emit UpdatedBumpRewardAllocation(
            "BUMPER UpdatedBUMPRewardAllocation",
            msg.sender,
            _bumpRewardAllocation
        );
    }

    ///@notice This function is used to update bumpPurchaseAllocation state variable by governance.
    ///@param _bumpPurchaseAllocation New value of bumpPurchaseAllocation state variable
    ///@dev Decimal precision should be 18
    function updateBumpPurchaseAllocation(uint256 _bumpPurchaseAllocation)
        external
        virtual
        onlyGovernance
    {
        bumpPurchaseAllocation = _bumpPurchaseAllocation;
        emit UpdatedBumpPurchaseAllocation(
            "BUMPER UpdatedBumpPurchaseAllocation",
            msg.sender,
            _bumpPurchaseAllocation
        );
    }

    ///@notice This method estimates how much BUMP you will get as rewards if a certain amount of deposit is made.
    ///@param _totalDeposit Total amount of USDC you are depositing
    ///@param _amountForPurchase Amount of USDC for BUMP token purchase
    ///@return Amount of BUMP rewards you will get if a certain deposit amount is made.
    function estimateBumpRewards(
        uint256 _totalDeposit,
        uint256 _amountForPurchase
    ) external view returns (uint256) {
        uint256 bumpPrice = estimateSwapRateBumpUsdc(_totalDeposit);
        uint256 netDepositAfterPurchase = _totalDeposit - _amountForPurchase;
        uint256 bumpRewards =
            ((netDepositAfterPurchase * bumpRewardAllocation) /
                (bumpPrice * BUMP_REWARDS_FORMULA_CONSTANT * (10**2))) +
                ((_totalDeposit * BUMP_REWARDS_BONUS_DRAG * (10**12)) /
                    BUMP_REWARDS_BONUS_DRAG_DIVIDER);
        return bumpRewards;
    }

    ///@notice This function returns a predicted swap rate for BUMP/USDC after a given deposit is made.
    ///@param _deposit It is the deposit amount for which it calculates swap rate.
    ///@return Returns swap rate for BUMP/USDC.
    function estimateSwapRateBumpUsdc(uint256 _deposit)
        public
        view
        returns (uint256)
    {
        uint256 currentTVLAfterDeposit = currentTVL + _deposit;
        return
            ((currentTVLAfterDeposit * SWAP_RATE_CONSTANT) / (10**9 * 10**2)) +
            BUMP_INITAL_PRICE;
    }

    ///@notice This returns current price of stablecoin passed as an param.
    ///@param _coin Coin of which current price user wants to know.
    ///@return Returns price that it got from aggregator address provided.
    ///@dev Decimal precision of 8 decimals
    function getCurrentPrice(StableCoins _coin)
        public
        view
        virtual
        returns (int256)
    {
        AggregatorV3Interface priceFeed =
            stableCoinsDetail[keccak256(abi.encodePacked(_coin))].priceFeed;
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    ///@notice This calculates what is the latest swap rate of BUMP/USDC
    ///@return Returns what is the swap rate of BUMP/USDC
    function getSwapRateBumpUsdc() public view returns (uint256) {
        return
            ((currentTVL * SWAP_RATE_CONSTANT) / (10**9 * 10**2)) +
            BUMP_INITAL_PRICE;
    }

    ///@notice Calculates BUMP rewards that is issued to user
    ///@param _totalDeposit total deposit made by user
    ///@param _amountForPurchase Amount of usdc spent to buy BUMP tokens
    ///@return BUMP rewards that need to be transferred
    function getBumpRewards(uint256 _totalDeposit, uint256 _amountForPurchase)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 bumpPrice = getSwapRateBumpUsdc();
        uint256 netDepositAfterPurchase = _totalDeposit - _amountForPurchase;
        uint256 bumpRewards =
            ((netDepositAfterPurchase * bumpRewardAllocation) /
                (bumpPrice * BUMP_REWARDS_FORMULA_CONSTANT * (10**2))) +
                ((_totalDeposit * BUMP_REWARDS_BONUS_DRAG * (10**12)) /
                    BUMP_REWARDS_BONUS_DRAG_DIVIDER);
        return bumpRewards;
    }

    ///@notice This function returns amount of BUMP tokens you will get for amount of usdc you want to use for purchase.
    ///@param _amountForPurchase Amount of USDC for BUMP purchase.
    ///@return Amount of BUMP tokens user will get.
    function getBumpPurchaseAmount(uint256 _amountForPurchase)
        internal
        virtual
        returns (uint256)
    {
        //The reason we have multiplied numerator by 10**12 because decimal precision of BUMP token is 18
        //Given precision of _amountForPurchase is 6 , we need 12 more
        //And we have again multiplied it by 10**4 because , below swap rate is of precision 4
        uint256 bumpPurchaseAmount =
            (_amountForPurchase * 10**12 * 10**4) / (getSwapRateBumpUsdc());
        return bumpPurchaseAmount;
    }

    ///@notice Calculates amount of BUMP tokens that need to be transferred as rewards and as purchased amount
    ///@param _amountForDeposit Amount of USDC tokens deposited for which BUMP rewards need to be issued
    ///@param _amountForPurchase Amount of USDC tokens sent for the purchase of BUMP tokens
    ///@return Returns amount of BUMP tokens as rewards and amount of BUMP tokens purchased
    function getBumpAllocation(
        uint256 _amountForDeposit,
        uint256 _amountForPurchase
    ) internal virtual returns (uint256, uint256) {
        uint256 bumpRewards =
            getBumpRewards(
                (_amountForDeposit + _amountForPurchase),
                _amountForPurchase
            );
        require(
            bumpRewards <= bumpRewardAllocation,
            "Not enough BUMP Rewards left!"
        );
        bumpRewardAllocation = bumpRewardAllocation - bumpRewards;
        uint256 bumpPurchased = getBumpPurchaseAmount(_amountForPurchase);
        require(
            bumpPurchased <= bumpPurchaseAllocation,
            "Not enough BUMP left to purchase!"
        );
        bumpPurchaseAllocation = bumpPurchaseAllocation - bumpPurchased;
        return (bumpRewards, bumpPurchased);
    }

    ///@notice Approves USDC to yearn vault.
    ///@param _amount Amount of USDC you want to approve to yearn vault.
    function _approveUSDCToYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IERC20Upgradeable(
            stableCoinsDetail[keccak256(abi.encodePacked(StableCoins.USDC))]
                .contractAddress
        )
            .safeApprove(usdcVault, _amount);
    }

    ///@notice Deposits provided amount of USDC to yearn vault.
    ///@param _amount Amount of USDC you want to deposit to yearn vault.
    function _depositUSDCInYearnVault(uint256 _amount)
        internal
        virtual
        whenNotPaused
    {
        IVault(usdcVault).deposit(_amount);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TimeLockMechanism.sol";
import "./BumperAccessControl.sol";

///@title  Bumper Liquidity Provision Program (LPP) - BUSDC ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUSDC will be BumpMarket
contract BUSDC is
    Initializable,
    ERC20PausableUpgradeable,
    TimeLockMechanism,
    BumperAccessControl
{
    ///@notice Will initialize state variables of this contract
    ///@param name_- Name of ERC20 token.
    ///@param symbol_- Symbol to be used for ERC20 token.
    ///@param _unlockTimestamp- Amount of duration for which certain functions are locked
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 _unlockTimestamp,
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _TimeLockMechanism_init(_unlockTimestamp);
        _BumperAccessControl_init(_whitelistAddresses);
        _pause();
    }

    function pause() external whenNotPaused onlyGovernanceOrOwner {
        _pause();
    }

    function unpause() external whenPaused onlyGovernanceOrOwner {
        _unpause();
    }

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    ///@notice This method will be update timelock of BUSDC contract.
    ///@param _unlockTimestamp New unlock timestamp
    ///@dev The reason it is onlyGovernanceOrOwner because owner in this case will be BumpMarket.
    function updateUnlockTimestamp(uint256 _unlockTimestamp)
        external
        virtual
        onlyGovernanceOrOwner
    {
        unlockTimestamp = _unlockTimestamp;
        emit UpdateUnlockTimestamp("", msg.sender, _unlockTimestamp);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external returns (uint256);

    function withdrawAll() external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./TimeLockMechanism.sol";
import "./BumperAccessControl.sol";

///@title  Bumper Liquidity Provision Program (LPP) - BUMP ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUMPToken is BumpMarket
contract BUMPToken is
    Initializable,
    ERC20PausableUpgradeable,
    TimeLockMechanism,
    BumperAccessControl
{
    ///@notice Will initialize state variables of this contract
    ///@param name_- Name of ERC20 token.
    ///@param symbol_- Symbol to be used for ERC20 token.
    ///@param _unlockTimestamp- Amount of duration for which certain functions are locked
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 _unlockTimestamp,
        uint256 bumpSupply,
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _TimeLockMechanism_init(_unlockTimestamp);
        _BumperAccessControl_init(_whitelistAddresses);
        _mint(address(this), bumpSupply);
        _pause();
    }

    ///@notice This function is used by governance to pause BUMP token contract.
    function pause() external whenNotPaused onlyGovernance {
        _pause();
    }

    ///@notice This function is used by governance to un-pause BUMP token contract.
    function unpause() external whenPaused onlyGovernance {
        _unpause();
    }

    ///@notice This function is used by governance to increase supply of BUMP tokens.
    ///@param _increaseSupply Amount by which supply will increase.
    ///@dev So this basically mints new tokens in the name of protocol.
    function mint(uint256 _increaseSupply) external virtual onlyGovernance {
        _mint(address(this), _increaseSupply);
    }

    ///@notice This function updates unlockTimestamp variable
    ///@param _unlockTimestamp New deadline for lock in period
    function updateUnlockTimestamp(uint256 _unlockTimestamp)
        external
        virtual
        onlyGovernance
    {
        unlockTimestamp = _unlockTimestamp;
        emit UpdateUnlockTimestamp("", msg.sender, _unlockTimestamp);
    }

    ///@notice Called when distributing BUMP tokens from the protocol
    ///@param account- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    ///@dev Only governance or owner will be able to transfer these tokens
    function distributeToAddress(address account, uint256 amount)
        external
        virtual
        onlyGovernanceOrOwner
    {
        _transfer(address(this), account, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param recipient- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param spender- Account to which tokens are approved
    ///@param amount- Amount of tokens approved
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param sender- Account which is transferring tokens
    ///@param recipient- Account which is receiving tokens
    ///@param amount- Amount of tokens being transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

///@title BumperAccessControl contract is used to restrict access of functions to onlyGovernance and onlyOwner.
///@notice This contains suitable modifiers to restrict access of functions to onlyGovernance and onlyOwner.
contract BumperAccessControl is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    ///@dev This stores if a particular address is considered as whitelist or not in form of mapping.
    mapping(address => bool) internal whitelist;

    event AddressAddedToWhitelist(address newWhitelistAddress);
    event AddressRemovedFromWhitelist(address removedWhitelistAddress);

    function _BumperAccessControl_init(address[] memory _whitelist)
        internal
        initializer
    {
        __Context_init_unchained();
        __Ownable_init();
        ///Setting white list addresses as true
        for (uint256 i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    modifier onlyGovernance {
        require(whitelist[_msgSender()], "Address not in whitelist.");
        _;
    }

    modifier onlyGovernanceOrOwner {
        require(
            whitelist[_msgSender()] || owner() == _msgSender(),
            "Neither a whitelist address nor an owner."
        );
        _;
    }

    ///@dev It sets this address as true in whitelist address mapping
    ///@param addr Address that is set as whitelist address
    function addAddressToWhitelist(address addr) external onlyGovernance {
        whitelist[addr] = true;
        emit AddressAddedToWhitelist(addr);
    }

    ///@dev It sets passed address as false in whitelist address mapping
    ///@param addr Address that is removed as whitelist address
    function removeAddressFromWhitelist(address addr) external onlyGovernance {
        whitelist[addr] = false;
        emit AddressRemovedFromWhitelist(addr);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

///@title TimeLockMechanism contains mechanism to lock functions for a specific period of time.
///@notice This contains modifier that can be used to lock functions for a certain period of time.
contract TimeLockMechanism is Initializable {
    uint256 public unlockTimestamp;

    event UpdateUnlockTimestamp(
        string description,
        address sender,
        uint256 newUnlockTimestamp
    );

    modifier timeLocked {
        require(
            block.timestamp >= unlockTimestamp,
            "Cannot access before token unlock"
        );
        _;
    }

    function _TimeLockMechanism_init(uint256 _unlockTimestamp)
        internal
        initializer
    {
        unlockTimestamp = _unlockTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "petersburg",
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