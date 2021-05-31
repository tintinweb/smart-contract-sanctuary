//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/** Libraries */
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

/** Contracts */
import "../base/BaseUpgradeable.sol";

/** Interfaces */
import "../pools/IRewardsPool.sol";
import "./IAuctionItems.sol";

contract AuctionItems is IAuctionItems, BaseUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct AuctionInfo {
        // The NFT token that will be auctioned.
        address token;
        // Current item price for this auction.
        uint256 itemPrice;
        // Current total balance for this auction.
        uint256 totalBalance;
        // Max items to offer in the auction.
        uint256 maxItems;
        // Rewards to transfer per item in each bid.
        uint256 rewardsPerItem;
        // Token to give as reward.
        address rewardToken;
        // User balance for the auction (deposited by the user).
        mapping(address => uint256) balanceOf;
        // Defines the block number where the auction starts.
        uint256 startBlock;
        // Defines the block number where the auction ends.
        uint256 endBlock;
        // Defines whether auction is paused or not.
        bool isPaused;
    }

    mapping(uint256 => AuctionInfo) private auctions;

    address payable public override paymentReceiver;

    address public override rewardsPool;

    uint256 public override lastAuction;

    uint256 public override totalBalance;

    function bid(uint256 auctionId) external payable override whenPlatformIsNotPaused() {
        AuctionInfo storage auctionInfo = auctions[auctionId];
        require(address(auctionInfo.rewardToken) != address(0x0), "AUCTION_DOESNT_EXIST");
        require(auctionInfo.startBlock <= block.number, "AUCTION_DIDNT_START");
        require(!auctionInfo.isPaused, "AUCTION_IS_PAUSED");
        require(msg.value.mod(auctionInfo.itemPrice) == 0, "VALUE_DOESNT_MATCH_ITEM_PRICE");
        require(
            auctionInfo.totalBalance.add(msg.value).div(auctionInfo.itemPrice) <=
                auctionInfo.maxItems,
            "MAX_ITEMS_REACHED_OUT"
        );
        address userWallet = msg.sender;
        uint256 itemsToBid = msg.value.div(auctionInfo.itemPrice);

        auctionInfo.balanceOf[userWallet] = auctionInfo.balanceOf[userWallet].add(msg.value);
        auctionInfo.totalBalance = auctionInfo.totalBalance.add(msg.value);
        totalBalance = totalBalance.add(msg.value);

        paymentReceiver.transfer(msg.value);

        uint256 totalRewardsAmount = itemsToBid.mul(auctionInfo.rewardsPerItem);
        IRewardsPool(rewardsPool).transferRewards(auctionId, userWallet, totalRewardsAmount);

        emit BidCreated(
            userWallet,
            auctionId,
            itemsToBid,
            auctionInfo.totalBalance,
            totalRewardsAmount,
            _isAuctionSoldOut(auctionId)
        );
    }

    function initialize(
        address settingsAddress,
        address rewardsPoolAddress,
        address payable paymentReceiverAddress
    ) public override {
        require(rewardsPoolAddress.isContract(), "REWARDS_POOL_MUST_BE_CONTRACT");
        require(paymentReceiverAddress != address(0x0), "PAYMENT_RECEIVER_IS_REQUIRED");
        super.initialize(settingsAddress);
        paymentReceiver = paymentReceiverAddress;
        rewardsPool = rewardsPoolAddress;
    }

    /** Admin Functions */
    function createAuction(
        address tokenAddress,
        uint256 rewardsPerItem,
        address rewardTokenAddress,
        uint256 itemPrice,
        uint256 maxItems,
        uint256 startInBlocks,
        uint256 durationBlocks
    ) external override onlyConfigurator(msg.sender) {
        require(rewardTokenAddress.isContract(), "REWARD_TOKEN_MUST_BE_CONTRACT");
        require(itemPrice > 0, "ITEM_PRICE_REQUIRED");
        require(maxItems > 0, "MAX_ITEMS_REQUIRED");
        require(durationBlocks > 0, "DURATION_BLOCKS_REQUIRED");

        lastAuction = lastAuction.add(1);

        auctions[lastAuction] = AuctionInfo({
            token: tokenAddress,
            itemPrice: itemPrice,
            totalBalance: 0,
            maxItems: maxItems,
            rewardToken: rewardTokenAddress,
            rewardsPerItem: rewardsPerItem,
            startBlock: block.number.add(startInBlocks),
            endBlock: block.number.add(startInBlocks).add(durationBlocks),
            isPaused: false
        });

        emit NewAuctionCreated(
            tokenAddress,
            rewardTokenAddress,
            lastAuction,
            rewardsPerItem,
            itemPrice,
            maxItems,
            auctions[lastAuction].startBlock,
            auctions[lastAuction].endBlock
        );
    }

    function pauseAuction(uint256 auctionId)
        external
        override
        onlyConfigurator(msg.sender)
        whenPlatformIsNotPaused()
    {
        require(address(auctions[auctionId].rewardToken) != address(0x0), "AUCTION_DOESNT_EXIST");
        require(!auctions[auctionId].isPaused, "AUCTION_IS_ALREADY_PAUSED");

        auctions[auctionId].isPaused = true;

        emit AuctionPaused(auctionId);
    }

    function unpauseAuction(uint256 auctionId)
        external
        override
        onlyConfigurator(msg.sender)
        whenPlatformIsNotPaused()
    {
        require(address(auctions[auctionId].rewardToken) != address(0x0), "AUCTION_DOESNT_EXIST");
        require(auctions[auctionId].isPaused, "AUCTION_ISNT_PAUSED");

        auctions[auctionId].isPaused = false;

        emit AuctionUnpaused(auctionId);
    }

    /** View Functions */

    function getVersion() external pure override returns (bytes32) {
        return "0.1.0";
    }

    function getAuctionInfo(uint256 auctionId)
        external
        view
        override
        returns (
            address token,
            uint256 itemPrice,
            uint256 auctionTotalBalance,
            uint256 maxItems,
            address rewardToken,
            uint256 rewardsPerItem,
            uint256 startBlock,
            uint256 endBlock,
            bool isPaused
        )
    {
        return _getAuctionInfo(auctionId);
    }

    function getAuctionStatus(uint256 auctionId)
        external
        view
        override
        returns (
            uint256 availableItems,
            bool exist,
            bool isSoldOut,
            bool isFinished
        )
    {
        return _getAuctionStatus(auctionId);
    }

    function requireAuctionClaimable(uint256 auctionId) external view override {
        (, bool exist, , bool isFinished) = _getAuctionStatus(auctionId);
        bool isPaused = auctions[auctionId].isPaused;
        require(exist && isFinished && !isPaused, "AUCTION_ISNT_CLAIMABLE");
    }

    function requireAuctionAvailable(uint256 auctionId) external view override {
        (, bool exist, , bool isFinished) = _getAuctionStatus(auctionId);
        require(exist && !isFinished, "AUCTION_ISNT_AVAILABLE");
    }

    function getUserInfo(uint256 auctionId, address userWallet)
        external
        view
        override
        returns (
            uint256 itemPrice,
            uint256 balance,
            uint256 totalItems
        )
    {
        AuctionInfo storage auction = auctions[auctionId];
        return (
            auction.itemPrice,
            auction.balanceOf[userWallet],
            auction.balanceOf[userWallet].div(auction.itemPrice)
        );
    }

    function getAllUserInfo(address userWallet)
        external
        view
        override
        returns (
            uint256[] memory auctionIds,
            uint256[] memory itemPrices,
            uint256[] memory balances,
            uint256[] memory totalItems
        )
    {
        uint256 length = lastAuction;
        auctionIds = new uint256[](length);
        itemPrices = new uint256[](length);
        balances = new uint256[](length);
        totalItems = new uint256[](length);

        for (uint256 auctionId = 1; auctionId <= length; auctionId++) {
            AuctionInfo storage auction = auctions[auctionId];
            auctionIds[auctionId - 1] = auctionId;
            itemPrices[auctionId - 1] = auction.itemPrice;
            balances[auctionId - 1] = auction.balanceOf[userWallet];
            totalItems[auctionId - 1] = auction.balanceOf[userWallet].div(auction.itemPrice);
        }
    }

    /** Internal Functions */

    function _isAuctionSoldOut(uint256 auctionId) internal view returns (bool) {
        AuctionInfo storage auction = auctions[auctionId];
        return auction.totalBalance.div(auction.itemPrice) == auction.maxItems;
    }

    function _getAuctionInfo(uint256 auctionId)
        internal
        view
        returns (
            address token,
            uint256 itemPrice,
            uint256 auctionTotalBalance,
            uint256 maxItems,
            address rewardToken,
            uint256 rewardsPerItem,
            uint256 startBlock,
            uint256 endBlock,
            bool isPaused
        )
    {
        token = auctions[auctionId].token;
        itemPrice = auctions[auctionId].itemPrice;
        auctionTotalBalance = auctions[auctionId].totalBalance;
        maxItems = auctions[auctionId].maxItems;
        rewardToken = address(auctions[auctionId].rewardToken);
        rewardsPerItem = auctions[auctionId].rewardsPerItem;
        startBlock = auctions[auctionId].startBlock;
        endBlock = auctions[auctionId].endBlock;
        isPaused = auctions[auctionId].isPaused;
    }

    function _getAuctionStatus(uint256 auctionId)
        internal
        view
        returns (
            uint256 availableItems,
            bool exist,
            bool isSoldOut,
            bool isFinished
        )
    {
        if (auctions[auctionId].itemPrice == 0) {
            return (0, false, false, false);
        }
        availableItems = auctions[auctionId].maxItems.sub(
            auctions[auctionId].totalBalance.div(auctions[auctionId].itemPrice)
        );
        exist = address(auctions[auctionId].rewardToken) != address(0x0);
        isSoldOut = _isAuctionSoldOut(auctionId);
        isFinished = auctions[auctionId].endBlock < block.number;
    }

    /** Modifiers */

    /** Events */
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract BaseUpgradeable {
    using AddressUpgradeable for address;

    /* Constant Variables */

    /* State Variables */

    address public settings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_settings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_settings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyMinter(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).MINTER_ROLE(),
            account,
            "SENDER_ISNT_MINTER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */

    function initialize(address settingsAddress) public {
        require(settings == address(0x0), "SETTINGS_ALREADY_INITIALIZED");
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _settingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_settings().consts());
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(settings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _settings().getSettingValue(name);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/** Libraries */

/** Contracts */

/** Interfaces */

interface IRewardsPool {
    /* Functions */

    function depositRewards(uint256 auctionId, uint256 amount) external returns (uint256);

    function transferRewards(
        uint256 auctionId,
        address account,
        uint256 amount
    ) external returns (uint256);

    function withdrawRewards(uint256 auctionId, uint256 amount) external returns (uint256);

    function initialize(address platformSettingsAddress, address auctionItemsAddress) external;

    /** View Functions */

    function auctionItems() external view returns (address);

    function availableRewards(uint256 auctionId) external view returns (uint256);

    /** Events */

    event RewardsDeposited(address indexed token, uint256 amount, uint256 availableRewards);

    event RewardsTransferred(address indexed token, uint256 amount, uint256 availableRewards);

    event RewardsWithdrawn(address indexed token, uint256 amount, uint256 availableRewards);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/** Libraries */

/** Contracts */

/** Interfaces */

interface IAuctionItems {
    function bid(uint256 auctionId) external payable;

    function initialize(
        address settingsAddress,
        address rewardsPoolAddress,
        address payable paymentReceiverAddress
    ) external;

    /** Admin Functions */

    function createAuction(
        address tokenAddress,
        uint256 rewardsPerItem,
        address rewardTokenAddress,
        uint256 itemPrice,
        uint256 maxItems,
        uint256 startInBlocks,
        uint256 durationBlocks
    ) external;

    function pauseAuction(uint256 auctionId) external;

    function unpauseAuction(uint256 auctionId) external;

    /** View Functions */

    function rewardsPool() external pure returns (address);

    function getVersion() external pure returns (bytes32);

    function getAuctionInfo(uint256 auctionId)
        external
        view
        returns (
            address token,
            uint256 itemPrice,
            uint256 auctionTotalBalance,
            uint256 maxItems,
            address rewardToken,
            uint256 rewardsPerItem,
            uint256 startBlock,
            uint256 endBlock,
            bool isPaused
        );

    function getAuctionStatus(uint256 auctionId)
        external
        view
        returns (
            uint256 availableItems,
            bool exist,
            bool isSoldOut,
            bool isFinished
        );

    function getAllUserInfo(address userWallet)
        external
        view
        returns (
            uint256[] memory auctionIds,
            uint256[] memory itemPrices,
            uint256[] memory balances,
            uint256[] memory totalItems
        );

    function getUserInfo(uint256 auctionId, address userWallet)
        external
        view
        returns (
            uint256 itemPrice,
            uint256 balance,
            uint256 totalItems
        );

    function requireAuctionClaimable(uint256 auctionId) external view;

    function requireAuctionAvailable(uint256 auctionId) external view;

    function paymentReceiver() external view returns (address payable);

    function totalBalance() external view returns (uint256);

    function lastAuction() external view returns (uint256);

    /** Modifiers */

    /** Events */

    event BidCreated(
        address userWallet,
        uint256 auctionId,
        uint256 itemsToBid,
        uint256 auctionTotalBalance,
        uint256 totalRewardsAmount,
        bool isSoldOut
    );

    event NewAuctionCreated(
        address indexed token,
        address indexed rewardToken,
        uint256 newAuctionId,
        uint256 rewardsPerItem,
        uint256 itemPrice,
        uint256 maxItems,
        uint256 startBlock,
        uint256 endBlock
    );

    event AuctionPaused(uint256 auctionId);

    event AuctionUnpaused(uint256 auctionId);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract PlatformSettingsConsts {
    bytes32 public constant MEOW_PAUSED = "MeowPaused";

    bytes32 public constant PIXU_CATS_PAUSED = "PixuCatsPaused";
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event ConstsUpdated(address indexed sender, address oldConsts, address newConsts);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IRolesManager {
    function multiGrantRole(bytes32 role, address[] calldata accounts) external;

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external;

    function setConsts(address newConstsAddress) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function requireHasRole(bytes32 role, address account) external view;

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view;

    function consts() external view returns (address);

    event ConstsUpdated(address indexed sender, address oldConsts, address newConsts);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

library SettingsLib {
    /**
        It defines a setting. It includes: value, min, and max values.
     */
    struct Setting {
        uint256 value;
        uint256 min;
        uint256 max;
        bool exists;
    }

    /**
        @notice It creates a new setting given a name, min and max values.
        @param value initial value for the setting.
        @param min min value allowed for the setting.
        @param max max value allowed for the setting.
     */
    function create(
        Setting storage self,
        uint256 value,
        uint256 min,
        uint256 max
    ) internal {
        requireNotExists(self);
        require(value >= min, "VALUE_MUST_BE_GT_MIN_VALUE");
        require(value <= max, "VALUE_MUST_BE_LT_MAX_VALUE");
        self.value = value;
        self.min = min;
        self.max = max;
        self.exists = true;
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the setting already exists.
        @param self the current setting.
     */
    function requireNotExists(Setting storage self) internal view {
        require(!self.exists, "SETTING_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the current setting doesn't exist.
        @param self the current setting.
     */
    function requireExists(Setting storage self) internal view {
        require(self.exists, "SETTING_NOT_EXISTS");
    }

    /**
        @notice It updates a current setting.
        @dev It throws a require error if:
            - The new value is equal to the current value.
            - The new value is not lower than the max value.
            - The new value is not greater than the min value
        @param self the current setting.
        @param newValue the new value to set in the setting.
     */
    function update(Setting storage self, uint256 newValue) internal returns (uint256 oldValue) {
        requireExists(self);
        require(self.value != newValue, "NEW_VALUE_REQUIRED");
        require(newValue >= self.min, "NEW_VALUE_MUST_BE_GT_MIN_VALUE");
        require(newValue <= self.max, "NEW_VALUE_MUST_BE_LT_MAX_VALUE");
        oldValue = self.value;
        self.value = newValue;
    }

    /**
        @notice It removes a current setting.
        @param self the current setting to remove.
     */
    function remove(Setting storage self) internal {
        requireExists(self);
        self.value = 0;
        self.min = 0;
        self.max = 0;
        self.exists = false;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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