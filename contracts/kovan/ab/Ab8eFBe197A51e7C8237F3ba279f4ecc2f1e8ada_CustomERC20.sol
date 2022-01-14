// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./data/Tax.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IHODLRewardDistributor.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./SwapHandler.sol";

contract CustomERC20 is ERC20, Ownable {
    using SafeMath for uint256;

    struct Whitelisted {
        bool maxSell;
        bool maxBalance;
        bool tax;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    uint256 constant BASE = 10 ** 9; // 5 decimals
    uint256 constant TOTAL_SUPPLY = 100_000_000_000_000_000 * BASE;

    address constant BLACK_HOLE = address(0xdead);

    uint256 constant HOURS72 = 300;//259_200;
    uint256 constant HOUR = 120;   //3_600;

    address public wbnb;
    address public swapRouter;
    address public wbnbPair;


    address public autoLPWallet;
    address public marketingWallet;
    address public buybackWallet;
    address public devWallet;

    uint256 public maxSell = TOTAL_SUPPLY.mul(25).div(10000); // 0.25%
    uint256 public maxBalance = (2 ** 256) - 1; // no max balance

    uint256 public minimumShareForRewards;
    bool public autoBatchProcess = true;

    mapping(uint256 => mapping(address => uint256)) public volumes72H;
    mapping(uint256 => mapping(address => uint256)) public sells1H;

    Tax public buyerTax = Tax(
        5, // AUTOLP
        5, // HOLDER
        3, // Marketing
        5, // buyback
        2  // dev
    );
    Tax public sellerTax = Tax(
        5, // AUTOLP
        5, // HOLDER
        3, // Marketing
        5, // buyback
        2  // dev
    );
    Tax public transferTax = Tax(
        5, // AUTOLP
        5, // HOLDER
        3, // Marketing
        5, // buyback
        2  // dev
    );

    mapping(address => bool) public isLpPair;

    mapping(address => Whitelisted) public whitelisted;

    IHODLRewardDistributor public hodlRewardDistributor;

    bool public isDistributorSet;

    bool public reflectionEnabled = false;

    SwapHandler public swapHandler;

    uint256 public autoLPReserved;
    uint256 public hodlReserved;
    uint256 public marketingReserved;
    uint256 public buybackReserved;
    uint256 public devReserved;

    uint256 public processingGasLimit = 500000;

    constructor(
        string memory name_,
        string memory symbol_,
        SwapHandler swapHandler_,
        address wrappedNativeToken_,
        address swapRouter_,
        address payable autoLP_,
        address payable marketing_,
        address payable buyback_,
        address payable dev_
    ) ERC20(name_, symbol_) {
        // init wallets addresses
        wbnb = wrappedNativeToken_;
        swapRouter = swapRouter_;
        autoLPWallet = autoLP_;
        marketingWallet = marketing_;
        buybackWallet = buyback_;
        devWallet = dev_;

        // create pair for OPSY/
        wbnbPair = IFactory(
            IRouter(swapRouter_).factory()
        ).createPair(wrappedNativeToken_, address(this));

        isLpPair[wbnbPair] = true;

        swapHandler = swapHandler_;

        // whiteliste wallets
        whitelisted[autoLP_] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[marketing_] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[buyback_] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[dev_] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[address(this)] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[address(swapHandler_)] = Whitelisted(
            true, // max transfer
            true, // max balance
            true  // Tax
        );

        whitelisted[swapRouter_] = Whitelisted(
            true, // max transfer
            true, // max balance
            false  // Tax
        );

        whitelisted[wbnbPair] = Whitelisted(
            false, // max transfer
            true, // max balance
            false  // Tax
        );
        // mint supply to wallet
        _mint(autoLP_, TOTAL_SUPPLY);
    }

    function setSwapHandler(SwapHandler swapHandler_) external {
        require(swapHandler_.owner() == address(this));
        hodlRewardDistributor.excludeFromRewards(address(swapHandler_));
        whitelisted[address(swapHandler_)] = Whitelisted(
            true,
            true,
            true
        );
        // we need to proccess the old swapHandler;
        processReserves();
        swapHandler = swapHandler_;
    }

    function initDistributor(
        address distributor_
    ) external onlyOwner {
        hodlRewardDistributor = IHODLRewardDistributor(distributor_);

        require(hodlRewardDistributor.owner() == address(this), "initDistributor: Erc20 not owner");

        hodlRewardDistributor.excludeFromRewards(wbnbPair);
        hodlRewardDistributor.excludeFromRewards(swapRouter);
        hodlRewardDistributor.excludeFromRewards(autoLPWallet);
        hodlRewardDistributor.excludeFromRewards(marketingWallet);
        hodlRewardDistributor.excludeFromRewards(buybackWallet);
        hodlRewardDistributor.excludeFromRewards(devWallet);
        hodlRewardDistributor.excludeFromRewards(address(this));
        hodlRewardDistributor.excludeFromRewards(address(swapHandler));
        hodlRewardDistributor.excludeFromRewards(BLACK_HOLE);

        whitelisted[distributor_] = Whitelisted(
            true,
            true,
            true
        );

        isDistributorSet = true;
    }

    function transfer(
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        return _customTransfer(_msgSender(), to_, amount_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        // check allowance
        require(allowance(from_, _msgSender()) >= amount_, "> allowance");
        bool success = _customTransfer(from_, to_, amount_);
        approve(from_, allowance(from_, _msgSender()).sub(amount_));
        return success;
    }


    /**
        When taxes are generated from swaps
        we cannot make the swap to avax due to reentrency gard
        on LPpool , so unstead we add it to a reserve , on next transfer
        this function is called and can also be called by any user
        if they are willing to pay gas.
    */
    function processReserves() public {
        swapHandler.swapToNativeWrappedToken(
            autoLPReserved,
            hodlReserved,
            marketingReserved,
            buybackReserved,
            devReserved
        );

        autoLPReserved = 0;
        hodlReserved = 0;
        marketingReserved = 0;
        buybackReserved = 0;
        devReserved = 0;
    }

    function setAutoLPWallet(
        address newAutoLPWallet_
    ) external onlyOwner {
        require(
            newAutoLPWallet_ != autoLPWallet,
            "ReflectionERC20: same as current wallet"
        );
        require(
            newAutoLPWallet_ != address(0),
            "ReflectionERC20: cannot be address(0)"
        );
        autoLPWallet = newAutoLPWallet_;
        whitelisted[newAutoLPWallet_] = Whitelisted(
            true,
            true,
            true
        );
    }

    function setMarketingWallet(
        address newMarketingWallet_
    ) external onlyOwner {
        require(
            newMarketingWallet_ != marketingWallet,
            "ReflectionERC20: same as current wallet"
        );
        require(
            newMarketingWallet_ != address(0),
            "ReflectionERC20: cannot be address(0)"
        );
        marketingWallet = newMarketingWallet_;
        whitelisted[newMarketingWallet_] = Whitelisted(
            true,
            true,
            true
        );
    }

    function setDevWallet(
        address newDevWallet_
    ) external onlyOwner {
        require(
            newDevWallet_ != buybackWallet,
            "ReflectionERC20: same as current wallet"
        );
        require(
            newDevWallet_ != address(0),
            "ReflectionERC20: cannot be address(0)"
        );
        devWallet = newDevWallet_;
        whitelisted[newDevWallet_] = Whitelisted(
            true,
            true,
            true
        );
    }

    function setBuybackWallet(
        address newBuybackWallet_
    ) external onlyOwner {
        require(
            newBuybackWallet_ != buybackWallet,
            "ReflectionERC20: same as current wallet"
        );
        require(
            newBuybackWallet_ != address(0),
            "ReflectionERC20: cannot be address(0)"
        );
        buybackWallet = newBuybackWallet_;
        whitelisted[newBuybackWallet_] = Whitelisted(
            true,
            true,
            true
        );
    }

    /**
        Sets the whitlisting of a wallet
        you can set it's whitlisting from maxTransfer #fromMaxSell
        or from payign tax #fromTax separatly
    */
    function whitelist(
        address wallet_,
        bool fromMaxSell_,
        bool fromMaxBalance_,
        bool fromTax_
    ) external onlyOwner {
        whitelisted[wallet_] = Whitelisted(
            fromMaxSell_,
            fromMaxBalance_,
            fromTax_
        );
    }

    /**
        this wallet will be excluded from rewards
        it is had any amount of rewards they will be
        distributed to all share holders
    */
    function excludeFromHodlRewards(
        address wallet_
    ) external onlyOwner {
        if (autoLPReserved + hodlReserved > 0)
            processReserves();
        hodlRewardDistributor.excludeFromRewards(wallet_);
    }

    /**
        This wallet will be included in rewards
    */
    function includeFromHodlRewards(
        address wallet_
    ) external onlyOwner {
        if (autoLPReserved + hodlReserved > 0)
            processReserves();
        hodlRewardDistributor.includeInRewards(wallet_);
    }

    function setBuyerTax(
        uint256 autoLP_,
        uint256 holder_,
        uint256 marketing_,
        uint256 buyback_,
        uint256 development_
    ) external onlyOwner {
        transferTax = Tax(
            autoLP_, holder_, marketing_, buyback_, development_
        );
    }

    function setSellerTax(
        uint256 autoLP_,
        uint256 holder_,
        uint256 marketing_,
        uint256 buyback_,
        uint256 development_
    ) external onlyOwner {
        transferTax = Tax(
            autoLP_, holder_, marketing_, buyback_, development_
        );
    }

    function setTransferTax(
        uint256 autoLP_,
        uint256 holder_,
        uint256 marketing_,
        uint256 buyback_,
        uint256 development_
    ) external onlyOwner {
        transferTax = Tax(
            autoLP_, holder_, marketing_, buyback_, development_
        );
    }

    function setReflection(
        bool isEnabled_
    ) external onlyOwner {
        require(isDistributorSet, "Distributor_not_set");
        if (autoLPReserved + hodlReserved > 0)
            processReserves();
        reflectionEnabled = isEnabled_;
    }

    function setMaxSellAmount(
        uint256 maxSell_
    ) external onlyOwner {
        maxSell = maxSell_;
    }

    /**
        @dev percentage is calculated as maxSell_Percentage_/10000
        so for example 25 = 0.25% 
     */
    function setMaxSellPercentage(
        uint256 maxSellPercentage_
    ) external onlyOwner {
        maxSell = TOTAL_SUPPLY.mul(maxSellPercentage_).div(10000);
    }

    function setMaxBalanceAmount(
        uint256 maxBalance_
    ) external onlyOwner {
        maxBalance = maxBalance_;
    }

    /**
        sets the  percentage of max balance per wallet
        maxBalance = (maxBalancePercentage_ * totalSupply) / 10000
     */
    function setMaxBalancePercentage(
        uint256 maxBalancePercentage_
    ) external onlyOwner {
        maxBalance = TOTAL_SUPPLY.mul(maxBalancePercentage_).div(10000);
    }

    function setIsLPPair(
        address pairAddess_,
        bool isPair_
    ) external onlyOwner {
        isLpPair[pairAddess_] = isPair_;
       
        if (isPair_) {
            hodlRewardDistributor.excludeFromRewards(pairAddess_);
            whitelisted[pairAddess_] = Whitelisted(
                false, // max transfer
                true, // max balance
                false  // Tax
            );
        }
    }

    function setPeocessingGasLimit(
        uint256 maxAmount_
    ) external onlyOwner {
        processingGasLimit = maxAmount_;
    }
    /**
        prevents accidental renouncement of owner ship
        can sill renounce if set explicitly to dead address
     */
    function renounceOwnership() public virtual override onlyOwner {}

    /**
        sets the minimum balance required to make holder eligible to reseave reflection rewards
     */
    function setMinimumShareForRewards(uint256 minimumAmount_) external onlyOwner {
        minimumShareForRewards = minimumAmount_;
    }

    /**
        Token uses some of the transaction gas to distribute rewards
        you can enable disable/enable here
        users can still claim
     */
    function setAutoBatchProcess(bool autoBatchProcess_) external onlyOwner {
        autoBatchProcess = autoBatchProcess_;
    }

    function claimRewardsFor(address wallet_) external {
        // No danger here claim sends to the share holder
        hodlRewardDistributor.claimPending(wallet_);
    }

    /**
        this is the implementation the custom transfer for this token
     */
    function _customTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal returns (bool) {
        // if whitlisted or we are internally swapping no tax
        if (whitelisted[from_].tax || whitelisted[to_].tax) {
            _transfer(from_, to_, amount_);
        } else {
            uint256 netTransfer = amount_;

            if (reflectionEnabled) {
                Tax memory currentAppliedTax = isLpPair[from_] ? buyerTax : isLpPair[to_] ? sellerTax : transferTax;
                uint256 prevTotal = autoLPReserved + hodlReserved;
                autoLPReserved += amount_.mul(currentAppliedTax.autoLP).div(100);
                hodlReserved += amount_.mul(currentAppliedTax.holder).div(100);
                marketingReserved += amount_.mul(currentAppliedTax.marketing).div(100);
                buybackReserved += amount_.mul(currentAppliedTax.buyback).div(100);
                devReserved += amount_.mul(currentAppliedTax.development).div(100);
                uint256 totalTax = autoLPReserved + hodlReserved + marketingReserved + buybackReserved + devReserved;
                uint256 currentTax = totalTax.sub(prevTotal);
                netTransfer = amount_.sub(currentTax);

                if (currentTax > 0)
                    _transfer(from_, address(swapHandler), currentTax);

                // if we have tokens and we are not in swap => swap and distribute to wallets
                if (totalTax > 0 && from_ != wbnbPair && to_ != wbnbPair)
                    processReserves();
            }
            // transfer
            _transfer(from_, to_, netTransfer);
            // This will trigger after_transfer and will update shares for from_ and to_ is needed
        }
        return true;
    }

    function _massProcess() internal {
        if (autoBatchProcess && gasleft() > processingGasLimit)
            hodlRewardDistributor.batchProcessClaims(processingGasLimit);
    }

    function _afterTokenTransfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        super._afterTokenTransfer(from_, to_, amount_);

        // add it to the 72hours volume 
        if (!whitelisted[from_].maxSell && from_ != address(0)) {
            volumes72H[block.timestamp / HOURS72][from_] += amount_;
            require(volumes72H[block.timestamp / HOURS72][from_] <= maxSell, "Anti-whale: Max transfer per 72H reached");
            require(sells1H[block.timestamp / HOUR][from_] == 0, 'Anti-bot: one sell per hour');
            if(isLpPair[to_])
                sells1H[block.timestamp / HOUR][from_] += 1;
        }

        require(
            balanceOf(to_) <= maxBalance || whitelisted[to_].maxBalance,
            'Max balance exceeds allowed limits'
        );

        if (isDistributorSet) {
            _updateShare(from_);
            _updateShare(to_);
            _massProcess();
        }
    }

    function _updateShare(
        address wallet
    ) internal {
        if (!hodlRewardDistributor.excludedFromRewards(wallet))
            hodlRewardDistributor.setShare(wallet, balanceOf(wallet) > minimumShareForRewards ? balanceOf(wallet) : 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

interface IRouter {
    function factory() external returns (address);
    /**
        for AMMs that cloned uni without changes to functions names
    */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    /**
        for joe AMM that cloned uni and changed functions names
    */
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken,uint256 amountAVAX,uint256 liquidity);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import '../data/ShareHolder.sol';

interface IHODLRewardDistributor {

    function excludedFromRewards(
        address wallet_
    ) external view returns (bool);

    function pending(
        address sharholderAddress_
    ) external view returns (uint256 pendingAmount);

    function totalPending () external view returns (uint256 );

    function shareHolderInfo (
        address shareHoldr_
    ) external view returns(ShareHolder memory);

    function depositWrappedNativeTokenRewards(
        uint256 amount_
    ) external;

    function setShare(
        address sharholderAddress_,
        uint256 amount_
    ) external;

    function excludeFromRewards (
        address shareHolderToBeExcluded_ 
    ) external;

    function includeInRewards(
        address shareHolderToBeIncluded_
    ) external;

    function claimPending(
        address sharholderAddress_
    ) external;

    function owner() external returns(address);
    
    function batchProcessClaims(uint256 gas) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "./IHODLRewardDistributor.sol";

interface ICustomERC20 {
    function autoLPWallet () external returns(address);
    function marketingWallet() external returns(address);
    function buybackWallet() external returns(address);
    function devWallet() external returns(address);
    function hodlRewardDistributor() external returns(IHODLRewardDistributor);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

    struct Tax {
        uint256 autoLP;
        uint256 holder;
        uint256 marketing;
        uint256 buyback;
        uint256 development;
    }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

struct ShareHolder {
    uint256 shares;
    uint256 rewardDebt;
    uint256 claimed;
    uint256 pending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
    @author humanshield85
    rachidboudjelida[at]gmail.com
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/ICustomERC20.sol";

contract SwapHandler is Ownable {

    address immutable swapRouter;
    address immutable wbnb;

    ICustomERC20 erc20;

    bool private _inSwap = false;

    uint256 public totalToHoldersInERC20;

    modifier isInSwap () {
        require(!_inSwap, "SwapHandler: Already in swap");
        _inSwap = true;
        _;
        _inSwap = false;
    }

    receive() external payable {}

    constructor (
        address swapRouter_,
        address wrappedNativeToken_
    ) {
        swapRouter = swapRouter_;
        wbnb = wrappedNativeToken_;
        erc20 = ICustomERC20(msg.sender);
    }

    /**
        this will swap the amounts to avax/eth/bnb/matic and send them to the respective wallets
     */
    function swapToNativeWrappedToken(
        uint256 autoLPAmount_,
        uint256 holderAmount_,
        uint256 marketingAmount_,
        uint256 buybackAmount_,
        uint256 devAmount_
    ) isInSwap onlyOwner external {
        IERC20(owner()).approve(swapRouter, IERC20(owner()).balanceOf(address(this)));

        if (autoLPAmount_ > 0) {
            uint256 half = autoLPAmount_ / 2;
            _swap(half, address(this));
            // swap half
            _createLP(autoLPAmount_-half);
        }

        if (marketingAmount_ > 0) {
            // transfer to marketing wallet
            IERC20(owner()).transfer(erc20.marketingWallet(), marketingAmount_);
        }

        if (buybackAmount_ > 0) {
            // transfer to buybackWallet wallet
            IERC20(owner()).transfer(erc20.buybackWallet(), buybackAmount_);
        }
        if (devAmount_ > 0) {
            // transfer to marketing wallet
            IERC20(owner()).transfer(erc20.devWallet(), devAmount_);
        }
        if (holderAmount_ > 0) {
            totalToHoldersInERC20 += IERC20(owner()).balanceOf(address(this));
            _swap(
                IERC20(owner()).balanceOf(address(this)),
                address(erc20.hodlRewardDistributor())
            );
            // Does not matter if it fails because it should not 
            address(erc20.hodlRewardDistributor()).call{value : address(this).balance}("");
        }
    }

    /**
        swap helper function
     */
    function _swap(
        uint amount_,
        address to_
    ) internal {
        // make the swap to wrappedNativeToken
        address[] memory path = new address[](2);
        path[0] = owner();
        path[1] = wbnb;

        IRouter(swapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount_,
            0,
            path,
            to_,
            block.timestamp + 10000
        );

    }


    function _createLP(uint256 erc20Amount_) internal {
        IRouter(swapRouter).addLiquidityETH{value : address(this).balance}(
            owner(),
            erc20Amount_,
            0,
            0,
            erc20.autoLPWallet(),
            block.timestamp + 10000
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
        erc20 = ICustomERC20(newOwner);
    }
}