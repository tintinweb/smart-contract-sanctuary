// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import "./AelinDeal.sol";
import "./MinimalProxyFactory.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AelinPool is AelinERC20, MinimalProxyFactory {
    using SafeERC20 for IERC20;
    uint256 constant BASE = 100 * 10**18;
    uint256 constant MAX_SPONSOR_FEE = 98 * 10**18;
    uint256 constant AELIN_FEE = 2 * 10**18;

    address public purchaseToken;
    uint256 public purchaseTokenCap;
    uint8 public purchaseTokenDecimals;
    uint256 public proRataConversion;

    uint256 public sponsorFee;
    address public sponsor;
    address public futureSponsor;
    address public poolFactory;

    uint256 public purchaseExpiry;
    uint256 public poolExpiry;
    uint256 public holderFundingExpiry;
    uint256 public totalAmountAccepted;
    uint256 public totalAmountWithdrawn;
    uint256 public purchaseTokenTotalForDeal;

    bool public calledInitialize = false;

    address public aelinRewardsAddress;
    address public aelinDealLogicAddress;
    AelinDeal public aelinDeal;
    address public holder;

    mapping(address => uint256) public amountAccepted;
    mapping(address => uint256) public amountWithdrawn;
    mapping(address => bool) public openPeriodEligible;
    mapping(address => uint256) public allowList;
    bool public hasAllowList;

    string private storedName;
    string private storedSymbol;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new pool created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the initialize method replaces the constructor setup and can only be called once
     *
     * Requirements:
     * - max 1 year duration
     * - purchase expiry can be set from 30 minutes to 30 days
     * - max sponsor fee is 98000 representing 98%
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _purchaseTokenCap,
        address _purchaseToken,
        uint256 _duration,
        uint256 _sponsorFee,
        address _sponsor,
        uint256 _purchaseDuration,
        address _aelinDealLogicAddress,
        address _aelinRewardsAddress
    ) external initOnce {
        require(
            30 minutes <= _purchaseDuration && 30 days >= _purchaseDuration,
            "outside purchase expiry window"
        );
        require(365 days >= _duration, "max 1 year duration");
        require(_sponsorFee <= MAX_SPONSOR_FEE, "exceeds max sponsor fee");
        purchaseTokenDecimals = IERC20Decimals(_purchaseToken).decimals();
        require(
            purchaseTokenDecimals <= DEAL_TOKEN_DECIMALS,
            "too many token decimals"
        );
        storedName = _name;
        storedSymbol = _symbol;
        poolFactory = msg.sender;

        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aePool-", _name)),
            string(abi.encodePacked("aeP-", _symbol)),
            purchaseTokenDecimals
        );

        purchaseTokenCap = _purchaseTokenCap;
        purchaseToken = _purchaseToken;
        purchaseExpiry = block.timestamp + _purchaseDuration;
        poolExpiry = purchaseExpiry + _duration;
        sponsorFee = _sponsorFee;
        sponsor = _sponsor;
        aelinDealLogicAddress = _aelinDealLogicAddress;
        aelinRewardsAddress = _aelinRewardsAddress;

        emit SetSponsor(_sponsor);
    }

    function updateAllowList(
        address[] memory _allowList,
        uint256[] memory _allowListAmounts
    ) external onlyPoolFactoryOnce {
        for (uint256 i = 0; i < _allowList.length; i++) {
            allowList[_allowList[i]] = _allowListAmounts[i];
        }
    }

    modifier dealReady() {
        if (holderFundingExpiry > 0) {
            require(
                !aelinDeal.depositComplete() &&
                    block.timestamp >= holderFundingExpiry,
                "cant create new deal"
            );
        }
        _;
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier onlySponsor() {
        require(msg.sender == sponsor, "only sponsor can access");
        _;
    }

    modifier onlyPoolFactoryOnce() {
        require(
            msg.sender == poolFactory && !hasAllowList && totalSupply() == 0,
            "only pool factory can access"
        );
        hasAllowList = true;
        _;
    }

    modifier dealFunded() {
        require(
            holderFundingExpiry > 0 && aelinDeal.depositComplete(),
            "deal not yet funded"
        );
        _;
    }

    /**
     * @dev the sponsor may change addresses
     */
    function setSponsor(address _sponsor) external onlySponsor {
        futureSponsor = _sponsor;
    }

    function acceptSponsor() external {
        require(msg.sender == futureSponsor, "only future sponsor can access");
        sponsor = futureSponsor;
        emit SetSponsor(futureSponsor);
    }

    /**
     * @dev only the sponsor can create a deal. The deal must be funded by the holder
     * of the underlying deal token before a purchaser may accept the deal. If the
     * holder does not fund the deal before the expiry period is over then the sponsor
     * can create a new deal for the pool of capital by calling this method again.
     *
     * Requirements:
     * - The purchase expiry period must be over
     * - the holder funding expiry period must be from 30 minutes to 30 days
     * - the pro rata redemption period must be from 30 minutes to 30 days
     * - the purchase token total for the deal that may be accepted must be <= the funds in the pool
     * - if the pro rata conversion ratio (purchase token total for the deal:funds in pool)
     *   is 1:1 then the open redemption period must be 0,
     *   otherwise the open period is from 30 minutes to 30 days
     */
    function createDeal(
        address _underlyingDealToken,
        uint256 _purchaseTokenTotalForDeal,
        uint256 _underlyingDealTokenTotal,
        uint256 _vestingPeriod,
        uint256 _vestingCliff,
        uint256 _proRataRedemptionPeriod,
        uint256 _openRedemptionPeriod,
        address _holder,
        uint256 _holderFundingDuration
    ) external onlySponsor dealReady returns (address) {
        require(_holder != address(0), "cant pass null holder address");
        require(
            _underlyingDealToken != address(0),
            "cant pass null token address"
        );
        require(
            block.timestamp >= purchaseExpiry,
            "pool still in purchase mode"
        );
        require(
            30 minutes <= _proRataRedemptionPeriod &&
                30 days >= _proRataRedemptionPeriod,
            "30 mins - 30 days for prorata"
        );
        require(1825 days >= _vestingCliff, "max 5 year cliff");
        require(1825 days >= _vestingPeriod, "max 5 year vesting");
        require(
            30 minutes <= _holderFundingDuration &&
                30 days >= _holderFundingDuration,
            "30 mins - 30 days for holder"
        );
        require(
            _purchaseTokenTotalForDeal <= totalSupply(),
            "not enough funds available"
        );
        proRataConversion = (_purchaseTokenTotalForDeal * 1e18) / totalSupply();
        if (proRataConversion == 1e18) {
            require(
                0 minutes == _openRedemptionPeriod,
                "deal is 1:1, set open to 0"
            );
        } else {
            require(
                30 minutes <= _openRedemptionPeriod &&
                    30 days >= _openRedemptionPeriod,
                "30 mins - 30 days for open"
            );
        }

        poolExpiry = block.timestamp;
        holder = _holder;
        holderFundingExpiry = block.timestamp + _holderFundingDuration;
        purchaseTokenTotalForDeal = _purchaseTokenTotalForDeal;
        uint256 maxDealTotalSupply = convertPoolToDeal(
            _purchaseTokenTotalForDeal,
            purchaseTokenDecimals
        );

        address aelinDealStorageProxy = _cloneAsMinimalProxy(
            aelinDealLogicAddress,
            "Could not create new deal"
        );
        aelinDeal = AelinDeal(aelinDealStorageProxy);

        aelinDeal.initialize(
            storedName,
            storedSymbol,
            _underlyingDealToken,
            _underlyingDealTokenTotal,
            _vestingPeriod,
            _vestingCliff,
            _proRataRedemptionPeriod,
            _openRedemptionPeriod,
            _holder,
            maxDealTotalSupply,
            holderFundingExpiry,
            aelinRewardsAddress
        );

        emit CreateDeal(
            string(abi.encodePacked("aeDeal-", storedName)),
            string(abi.encodePacked("aeD-", storedSymbol)),
            sponsor,
            aelinDealStorageProxy
        );

        emit DealDetail(
            aelinDealStorageProxy,
            _underlyingDealToken,
            _purchaseTokenTotalForDeal,
            _underlyingDealTokenTotal,
            _vestingPeriod,
            _vestingCliff,
            _proRataRedemptionPeriod,
            _openRedemptionPeriod,
            _holder,
            _holderFundingDuration
        );

        return aelinDealStorageProxy;
    }

    /**
     * @dev the 2 methods allow a purchaser to exchange accept all or a
     * portion of their pool tokens for deal tokens
     *
     * Requirements:
     * - the redemption period is either in the pro rata or open windows
     * - the purchaser cannot accept more than their share for a period
     * - if participating in the open period, a purchaser must have maxxed their
     *   contribution in the pro rata phase
     */
    function acceptMaxDealTokens() external {
        _acceptDealTokens(msg.sender, 0, true);
    }

    function acceptDealTokens(uint256 poolTokenAmount) external {
        _acceptDealTokens(msg.sender, poolTokenAmount, false);
    }

    /**
     * @dev the if statement says if you have no balance or if the deal is not funded
     * or if the pro rata period is not active, then you have 0 available for this period
     */
    function maxProRataAmount(address purchaser) public view returns (uint256) {
        if (
            (balanceOf(purchaser) == 0 &&
                amountAccepted[purchaser] == 0 &&
                amountWithdrawn[purchaser] == 0) ||
            holderFundingExpiry == 0 ||
            aelinDeal.proRataRedemptionStart() == 0 ||
            block.timestamp >= aelinDeal.proRataRedemptionExpiry()
        ) {
            return 0;
        }
        return
            (proRataConversion *
                (balanceOf(purchaser) +
                    amountAccepted[purchaser] +
                    amountWithdrawn[purchaser])) /
            1e18 -
            amountAccepted[purchaser];
    }

    function maxOpenAvail(address purchaser) internal view returns (uint256) {
        return
            balanceOf(purchaser) + totalAmountAccepted <=
                purchaseTokenTotalForDeal
                ? balanceOf(purchaser)
                : purchaseTokenTotalForDeal - totalAmountAccepted;
    }

    function _acceptDealTokens(
        address recipient,
        uint256 poolTokenAmount,
        bool useMax
    ) internal dealFunded lock {
        if (
            block.timestamp >= aelinDeal.proRataRedemptionStart() &&
            block.timestamp < aelinDeal.proRataRedemptionExpiry()
        ) {
            _acceptDealTokensProRata(recipient, poolTokenAmount, useMax);
        } else if (
            aelinDeal.openRedemptionStart() > 0 &&
            block.timestamp < aelinDeal.openRedemptionExpiry()
        ) {
            _acceptDealTokensOpen(recipient, poolTokenAmount, useMax);
        } else {
            revert("outside of redeem window");
        }
    }

    function _acceptDealTokensProRata(
        address recipient,
        uint256 poolTokenAmount,
        bool useMax
    ) internal {
        uint256 maxProRata = maxProRataAmount(recipient);
        uint256 maxAccept = maxProRata > balanceOf(recipient)
            ? balanceOf(recipient)
            : maxProRata;
        if (!useMax) {
            require(
                poolTokenAmount <= maxProRata &&
                    balanceOf(recipient) >= poolTokenAmount,
                "accepting more than share"
            );
        }
        uint256 acceptAmount = useMax ? maxAccept : poolTokenAmount;
        amountAccepted[recipient] += acceptAmount;
        totalAmountAccepted += acceptAmount;
        mintDealTokens(recipient, acceptAmount);
        if (proRataConversion != 1e18 && maxProRataAmount(recipient) == 0) {
            openPeriodEligible[recipient] = true;
        }
    }

    function _acceptDealTokensOpen(
        address recipient,
        uint256 poolTokenAmount,
        bool useMax
    ) internal {
        require(
            openPeriodEligible[recipient],
            "ineligible: didn't max pro rata"
        );
        uint256 maxOpen = maxOpenAvail(recipient);
        require(maxOpen > 0, "nothing left to accept");
        uint256 acceptAmount = useMax ? maxOpen : poolTokenAmount;
        if (!useMax) {
            require(acceptAmount <= maxOpen, "accepting more than share");
        }
        totalAmountAccepted += acceptAmount;
        mintDealTokens(recipient, acceptAmount);
    }

    /**
     * @dev the holder will receive less purchase tokens than the amount
     * transferred if the purchase token burns or takes a fee during transfer
     */
    function mintDealTokens(address recipient, uint256 poolTokenAmount)
        internal
    {
        _burn(recipient, poolTokenAmount);
        uint256 poolTokenDealFormatted = convertPoolToDeal(
            poolTokenAmount,
            purchaseTokenDecimals
        );
        uint256 aelinFeeAmt = (poolTokenDealFormatted * AELIN_FEE) / BASE;
        uint256 sponsorFeeAmt = (poolTokenDealFormatted * sponsorFee) / BASE;

        aelinDeal.mint(sponsor, sponsorFeeAmt);
        aelinDeal.mint(aelinRewardsAddress, aelinFeeAmt);
        aelinDeal.mint(
            recipient,
            poolTokenDealFormatted - (sponsorFeeAmt + aelinFeeAmt)
        );
        IERC20(purchaseToken).safeTransfer(holder, poolTokenAmount);
        emit AcceptDeal(
            recipient,
            address(aelinDeal),
            poolTokenAmount,
            sponsorFeeAmt,
            aelinFeeAmt
        );
    }

    /**
     * @dev allows anyone to become a purchaser by sending purchase tokens
     * in exchange for pool tokens
     *
     * Requirements:
     * - the deal is in the purchase expiry window
     * - the cap has not been exceeded
     */
    function purchasePoolTokens(uint256 _purchaseTokenAmount) external lock {
        if (hasAllowList) {
            require(
                _purchaseTokenAmount <= allowList[msg.sender],
                "more than allocation"
            );
            allowList[msg.sender] -= _purchaseTokenAmount;
        }
        require(block.timestamp < purchaseExpiry, "not in purchase window");
        uint256 currentBalance = IERC20(purchaseToken).balanceOf(address(this));
        IERC20(purchaseToken).safeTransferFrom(
            msg.sender,
            address(this),
            _purchaseTokenAmount
        );
        uint256 balanceAfterTransfer = IERC20(purchaseToken).balanceOf(
            address(this)
        );
        uint256 purchaseTokenAmount = balanceAfterTransfer - currentBalance;
        if (purchaseTokenCap > 0) {
            uint256 totalPoolAfter = totalSupply() + purchaseTokenAmount;
            require(
                totalPoolAfter <= purchaseTokenCap,
                "cap has been exceeded"
            );
            if (totalPoolAfter == purchaseTokenCap) {
                purchaseExpiry = block.timestamp;
            }
        }

        _mint(msg.sender, purchaseTokenAmount);
        emit PurchasePoolToken(msg.sender, purchaseTokenAmount);
    }

    /**
     * @dev the withdraw and partial withdraw methods allow a purchaser to take their
     * purchase tokens back in exchange for pool tokens if they do not accept a deal
     *
     * Requirements:
     * - the pool has expired either due to the creation of a deal or the end of the duration
     */
    function withdrawMaxFromPool() external {
        _withdraw(balanceOf(msg.sender));
    }

    function withdrawFromPool(uint256 purchaseTokenAmount) external {
        _withdraw(purchaseTokenAmount);
    }

    /**
     * @dev purchasers can withdraw at the end of the pool expiry period if
     * no deal was presented or they can withdraw after the holder funding period
     * if they do not like a deal
     */
    function _withdraw(uint256 purchaseTokenAmount) internal {
        require(block.timestamp >= poolExpiry, "not yet withdraw period");
        if (holderFundingExpiry > 0) {
            require(
                block.timestamp > holderFundingExpiry ||
                    aelinDeal.depositComplete(),
                "cant withdraw in funding period"
            );
        }
        _burn(msg.sender, purchaseTokenAmount);
        IERC20(purchaseToken).safeTransfer(msg.sender, purchaseTokenAmount);
        amountWithdrawn[msg.sender] += purchaseTokenAmount;
        totalAmountWithdrawn += purchaseTokenAmount;
        emit WithdrawFromPool(msg.sender, purchaseTokenAmount);
    }

    /**
     * @dev view to see how much of the deal a purchaser can accept.
     */
    function maxDealAccept(address purchaser) external view returns (uint256) {
        /**
         * The if statement is checking to see if the holder has not funded the deal
         * or if the period is outside of a redemption window so nothing is available.
         * It then checks if you are in the pro rata period and open period eligibility
         */
        if (
            holderFundingExpiry == 0 ||
            aelinDeal.proRataRedemptionStart() == 0 ||
            (block.timestamp >= aelinDeal.proRataRedemptionExpiry() &&
                aelinDeal.openRedemptionStart() == 0) ||
            (block.timestamp >= aelinDeal.openRedemptionExpiry() &&
                aelinDeal.openRedemptionStart() != 0)
        ) {
            return 0;
        } else if (block.timestamp < aelinDeal.proRataRedemptionExpiry()) {
            uint256 maxProRata = maxProRataAmount(purchaser);
            return
                maxProRata > balanceOf(purchaser)
                    ? balanceOf(purchaser)
                    : maxProRata;
        } else if (!openPeriodEligible[purchaser]) {
            return 0;
        } else {
            return maxOpenAvail(purchaser);
        }
    }

    /**
     * @dev pool tokens may not be transferred once the deal redemption window starts.
     * However, they may be withdrawn for purchase tokens which can then be transferred
     */
    modifier transferWindow() {
        require(
            aelinDeal.proRataRedemptionStart() == 0,
            "no transfers after redeem starts"
        );
        _;
    }

    function transfer(address dst, uint256 amount)
        public
        virtual
        override
        transferWindow
        returns (bool)
    {
        return super.transfer(dst, amount);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) public virtual override transferWindow returns (bool) {
        return super.transferFrom(src, dst, amount);
    }

    /**
     * @dev convert pool with varying decimals to deal tokens of 18 decimals
     * NOTE that a purchase token must not be greater than 18 decimals
     */
    function convertPoolToDeal(
        uint256 poolTokenAmount,
        uint256 poolTokenDecimals
    ) internal pure returns (uint256) {
        return poolTokenAmount * 10**(18 - poolTokenDecimals);
    }

    event SetSponsor(address indexed sponsor);
    event PurchasePoolToken(
        address indexed purchaser,
        uint256 purchaseTokenAmount
    );
    event WithdrawFromPool(
        address indexed purchaser,
        uint256 purchaseTokenAmount
    );
    event AcceptDeal(
        address indexed purchaser,
        address indexed dealAddress,
        uint256 poolTokenAmount,
        uint256 sponsorFee,
        uint256 aelinFee
    );
    event CreateDeal(
        string name,
        string symbol,
        address indexed sponsor,
        address indexed dealContract
    );
    event DealDetail(
        address indexed dealContract,
        address indexed underlyingDealToken,
        uint256 purchaseTokenTotalForDeal,
        uint256 underlyingDealTokenTotal,
        uint256 vestingPeriod,
        uint256 vestingCliff,
        uint256 proRataRedemptionPeriod,
        uint256 openRedemptionPeriod,
        address indexed holder,
        uint256 holderFundingDuration
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

/**
 * @dev a standard ERC20 contract that is extended with a few methods
 * described in detail below
 */
contract AelinERC20 is ERC20 {
    bool setInfo;
    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name and symbol in the initializer which requires these custom variables
     */
    string private _custom_name;
    string private _custom_symbol;
    uint8 private _custom_decimals;
    bool private locked;
    uint8 constant DEAL_TOKEN_DECIMALS = 18;

    constructor() ERC20("", "") {}

    modifier initInfoOnce() {
        require(!setInfo, "can only initialize once");
        _;
    }

    /**
     * @dev Due to the constructor being empty for the MinimalProxy architecture we need
     * to set the name, symbol, and decimals in the initializer which requires this
     * custom logic for name(), symbol(), decimals(), and _setNameSymbolAndDecimals()
     */
    function name() public view virtual override returns (string memory) {
        return _custom_name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _custom_symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _custom_decimals;
    }

    function _setNameSymbolAndDecimals(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initInfoOnce returns (bool) {
        _custom_name = _name;
        _custom_symbol = _symbol;
        _custom_decimals = _decimals;
        setInfo = true;
        emit AelinToken(_name, _symbol, _decimals);
        return true;
    }

    /**
     * @dev Add this to prevent reentrancy attacks on purchasePoolTokens and depositUnderlying
     * source: https://quantstamp.com/blog/how-the-dforce-hacker-used-reentrancy-to-steal-25-million
     * uniswap implementation: https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol#L31-L36
     */
    modifier lock() {
        require(!locked, "AelinV1: LOCKED");
        locked = true;
        _;
        locked = false;
    }

    event AelinToken(string name, string symbol, uint8 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./AelinERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AelinDeal is AelinERC20 {
    using SafeERC20 for IERC20;
    uint256 public maxTotalSupply;
    address public aelinRewardsAddress;

    address public underlyingDealToken;
    uint256 public underlyingDealTokenTotal;
    uint256 public totalUnderlyingClaimed;
    address public holder;
    address public futureHolder;

    uint256 public underlyingPerDealExchangeRate;

    address public aelinPool;
    uint256 public vestingCliff;
    uint256 public vestingPeriod;
    uint256 public vestingExpiry;
    uint256 public holderFundingExpiry;

    uint256 public proRataRedemptionPeriod;
    uint256 public proRataRedemptionStart;
    uint256 public proRataRedemptionExpiry;

    uint256 public openRedemptionPeriod;
    uint256 public openRedemptionStart;
    uint256 public openRedemptionExpiry;

    bool public calledInitialize;
    bool public depositComplete;
    mapping(address => uint256) public amountVested;

    /**
     * @dev the constructor will always be blank due to the MinimalProxyFactory pattern
     * this allows the underlying logic of this contract to only be deployed once
     * and each new deal created is simply a storage wrapper
     */
    constructor() {}

    /**
     * @dev the initialize method replaces the constructor setup and can only be called once
     * NOTE the deal tokens wrapping the underlying are always 18 decimals
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _underlyingDealToken,
        uint256 _underlyingDealTokenTotal,
        uint256 _vestingPeriod,
        uint256 _vestingCliff,
        uint256 _proRataRedemptionPeriod,
        uint256 _openRedemptionPeriod,
        address _holder,
        uint256 _maxDealTotalSupply,
        uint256 _holderFundingDuration,
        address _aelinRewardsAddress
    ) external initOnce {
        _setNameSymbolAndDecimals(
            string(abi.encodePacked("aeDeal-", _name)),
            string(abi.encodePacked("aeD-", _symbol)),
            DEAL_TOKEN_DECIMALS
        );

        holder = _holder;
        underlyingDealToken = _underlyingDealToken;
        underlyingDealTokenTotal = _underlyingDealTokenTotal;
        maxTotalSupply = _maxDealTotalSupply;

        aelinPool = msg.sender;
        vestingCliff =
            block.timestamp +
            _proRataRedemptionPeriod +
            _openRedemptionPeriod +
            _vestingCliff;
        vestingPeriod = _vestingPeriod;
        vestingExpiry = vestingCliff + _vestingPeriod;
        proRataRedemptionPeriod = _proRataRedemptionPeriod;
        openRedemptionPeriod = _openRedemptionPeriod;
        holderFundingExpiry = _holderFundingDuration;
        aelinRewardsAddress = _aelinRewardsAddress;

        depositComplete = false;

        /**
         * calculates the amount of underlying deal tokens you get per wrapped deal token accepted
         */
        underlyingPerDealExchangeRate =
            (_underlyingDealTokenTotal * 1e18) /
            maxTotalSupply;
        emit SetHolder(_holder);
    }

    modifier initOnce() {
        require(!calledInitialize, "can only initialize once");
        calledInitialize = true;
        _;
    }

    modifier finalizeDeposit() {
        require(block.timestamp < holderFundingExpiry, "deposit past deadline");
        require(!depositComplete, "deposit already complete");
        _;
    }

    /**
     * @dev the holder may change their address
     */
    function setHolder(address _holder) external onlyHolder {
        futureHolder = _holder;
    }

    function acceptHolder() external {
        require(msg.sender == futureHolder, "only future holder can access");
        holder = futureHolder;
        emit SetHolder(futureHolder);
    }

    /**
     * @dev the holder finalizes the deal for the pool created by the
     * sponsor by depositing funds using this method.
     *
     * NOTE if the deposit was completed with a transfer instead of this method
     * the deposit still needs to be finalized by calling this method with
     * _underlyingDealTokenAmount set to 0
     */
    function depositUnderlying(uint256 _underlyingDealTokenAmount)
        external
        finalizeDeposit
        lock
        returns (bool)
    {
        if (_underlyingDealTokenAmount > 0) {
            uint256 currentBalance = IERC20(underlyingDealToken).balanceOf(
                address(this)
            );
            IERC20(underlyingDealToken).safeTransferFrom(
                msg.sender,
                address(this),
                _underlyingDealTokenAmount
            );
            uint256 balanceAfterTransfer = IERC20(underlyingDealToken)
                .balanceOf(address(this));
            uint256 underlyingDealTokenAmount = balanceAfterTransfer -
                currentBalance;

            emit DepositDealToken(
                underlyingDealToken,
                msg.sender,
                underlyingDealTokenAmount
            );
        }

        if (
            IERC20(underlyingDealToken).balanceOf(address(this)) >=
            underlyingDealTokenTotal
        ) {
            depositComplete = true;
            proRataRedemptionStart = block.timestamp;
            proRataRedemptionExpiry = block.timestamp + proRataRedemptionPeriod;

            if (openRedemptionPeriod > 0) {
                openRedemptionStart = proRataRedemptionExpiry;
                openRedemptionExpiry =
                    proRataRedemptionExpiry +
                    openRedemptionPeriod;
            }
            emit DealFullyFunded(
                aelinPool,
                proRataRedemptionStart,
                proRataRedemptionExpiry,
                openRedemptionStart,
                openRedemptionExpiry
            );
            return true;
        }
        return false;
    }

    /**
     * @dev the holder can withdraw any amount accidentally deposited over
     * the amount needed to fulfill the deal
     *
     * NOTE if the deposit was completed with a transfer instead of this method
     * the deposit still needs to be finalized by calling this method with
     * _underlyingDealTokenAmount set to 0
     */
    function withdraw() external onlyHolder {
        uint256 withdrawAmount;
        if (!depositComplete && block.timestamp >= holderFundingExpiry) {
            withdrawAmount = IERC20(underlyingDealToken).balanceOf(
                address(this)
            );
        } else {
            withdrawAmount =
                IERC20(underlyingDealToken).balanceOf(address(this)) -
                (underlyingDealTokenTotal - totalUnderlyingClaimed);
        }
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(
            underlyingDealToken,
            holder,
            withdrawAmount
        );
    }

    /**
     * @dev after the redemption period has ended the holder can withdraw
     * the excess funds remaining from purchasers who did not accept the deal
     *
     * Requirements:
     * - both the pro rata and open redemption windows are no longer active
     */
    function withdrawExpiry() external onlyHolder {
        require(proRataRedemptionExpiry > 0, "redemption period not started");
        require(
            openRedemptionExpiry > 0
                ? block.timestamp >= openRedemptionExpiry
                : block.timestamp >= proRataRedemptionExpiry,
            "redeem window still active"
        );
        uint256 withdrawAmount = IERC20(underlyingDealToken).balanceOf(
            address(this)
        ) - ((underlyingPerDealExchangeRate * totalSupply()) / 1e18);
        IERC20(underlyingDealToken).safeTransfer(holder, withdrawAmount);
        emit WithdrawUnderlyingDealToken(
            underlyingDealToken,
            holder,
            withdrawAmount
        );
    }

    modifier onlyHolder() {
        require(msg.sender == holder, "only holder can access");
        _;
    }

    modifier onlyPool() {
        require(msg.sender == aelinPool, "only AelinPool can access");
        _;
    }

    /**
     * @dev a view showing the number of claimable deal tokens and the
     * amount of the underlying deal token a purchser gets in return
     */
    function claimableTokens(address purchaser)
        public
        view
        returns (uint256 underlyingClaimable, uint256 dealTokensClaimable)
    {
        underlyingClaimable = 0;
        dealTokensClaimable = 0;
        uint256 maxTime = block.timestamp > vestingExpiry
            ? vestingExpiry
            : block.timestamp;
        if (
            balanceOf(purchaser) > 0 &&
            (maxTime > vestingCliff ||
                (maxTime == vestingCliff && vestingPeriod == 0))
        ) {
            uint256 timeElapsed = maxTime - vestingCliff;
            dealTokensClaimable = vestingPeriod == 0
                ? balanceOf(purchaser)
                : ((balanceOf(purchaser) + amountVested[purchaser]) *
                    timeElapsed) /
                    vestingPeriod -
                    amountVested[purchaser];
            underlyingClaimable =
                (underlyingPerDealExchangeRate * dealTokensClaimable) /
                1e18;
        }
    }

    /**
     * @dev allows a user to claim their underlying deal tokens or a partial amount
     * of their underlying tokens once they have vested according to the schedule
     * created by the sponsor
     */
    function claim() external returns (uint256) {
        return _claim(msg.sender);
    }

    function _claim(address recipient) internal returns (uint256) {
        (
            uint256 underlyingDealTokensClaimed,
            uint256 dealTokensClaimed
        ) = claimableTokens(recipient);
        if (dealTokensClaimed > 0) {
            amountVested[recipient] += dealTokensClaimed;
            _burn(recipient, dealTokensClaimed);
            IERC20(underlyingDealToken).safeTransfer(
                recipient,
                underlyingDealTokensClaimed
            );
            totalUnderlyingClaimed += underlyingDealTokensClaimed;
            emit ClaimedUnderlyingDealToken(
                underlyingDealToken,
                recipient,
                underlyingDealTokensClaimed
            );
        }
        return dealTokensClaimed;
    }

    /**
     * @dev allows the purchaser to mint deal tokens. this method is also used
     * to send deal tokens to the sponsor and the aelin rewards pool. It may only
     * be called from the pool contract that created this deal
     */
    function mint(address dst, uint256 dealTokenAmount) external onlyPool {
        require(depositComplete, "deposit not complete");
        _mint(dst, dealTokenAmount);
    }

    /**
     * @dev deal tokens cant be transferred after the vesting expiry since
     * all tokens will be claimed at the start of the transfer leaving 0 to send
     */
    modifier transferWindow() {
        require(
            vestingExpiry > block.timestamp,
            "no transfers after vest done"
        );
        _;
    }

    /**
     * @dev below are helpers for transferring deal tokens. NOTE the token holder transferring
     * the deal tokens must pay the gas to claim their vested tokens first, which will burn their vested deal
     * tokens. They must also pay for the receivers claim and burn any of their vested tokens in order to ensure
     * the claim calculation is always accurate for all parties in the system
     */
    function transferMax(address recipient) external returns (bool) {
        (, uint256 claimableDealTokens) = claimableTokens(msg.sender);
        return transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
    }

    function transferFromMax(address sender, address recipient)
        external
        returns (bool)
    {
        (, uint256 claimableDealTokens) = claimableTokens(sender);
        return
            transferFrom(
                sender,
                recipient,
                balanceOf(sender) - claimableDealTokens
            );
    }

    /**
     * @dev a function only the treasury can use so they can send both the all
     * unvested deal tokens as well as all the vested underlying deal tokens in a
     * single transaction. we can use this when we are ready to distri
     */
    function treasuryTransfer(address recipient) external returns (bool) {
        require(
            msg.sender == aelinRewardsAddress,
            "only Rewards address can access"
        );
        (
            uint256 underlyingClaimable,
            uint256 claimableDealTokens
        ) = claimableTokens(msg.sender);
        transfer(recipient, balanceOf(msg.sender) - claimableDealTokens);
        return
            IERC20(underlyingDealToken).transfer(
                recipient,
                underlyingClaimable
            );
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        transferWindow
        returns (bool)
    {
        _claim(msg.sender);
        _claim(recipient);
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override transferWindow returns (bool) {
        _claim(sender);
        _claim(recipient);
        return super.transferFrom(sender, recipient, amount);
    }

    event SetHolder(address indexed holder);
    event DealFullyFunded(
        address indexed poolAddress,
        uint256 proRataRedemptionStart,
        uint256 proRataRedemptionExpiry,
        uint256 openRedemptionStart,
        uint256 openRedemptionExpiry
    );
    event DepositDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event WithdrawUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed depositor,
        uint256 underlyingDealTokenAmount
    );
    event ClaimedUnderlyingDealToken(
        address indexed underlyingDealTokenAddress,
        address indexed recipient,
        uint256 underlyingDealTokensClaimed
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.7;

// https://docs.synthetix.io/contracts/source/contracts/minimalproxyfactory
contract MinimalProxyFactory {
    function _cloneAsMinimalProxy(address _base, string memory _revertMsg)
        internal
        returns (address clone)
    {
        bytes memory createData = _generateMinimalProxyCreateData(_base);

        assembly {
            clone := create(
                0, // no value
                add(createData, 0x20), // data
                55 // data is always 55 bytes (10 constructor + 45 code)
            )
        }

        // If CREATE fails for some reason, address(0) is returned
        require(clone != address(0), _revertMsg);
    }

    function _generateMinimalProxyCreateData(address _base)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                //---- constructor -----
                bytes10(0x3d602d80600a3d3981f3),
                //---- proxy code -----
                bytes10(0x363d3d373d3d3d363d73),
                _base,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
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

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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