// SPDX-License-Identifier: MIT

/**
 *
 *  Site: https://omniadefi.com
 *  Telegram: https://t.me/omnia_defi_official
 *  Twitter: https://twitter.com/Omnia_DeFi
 *  GitLab: https://gitlab.com/createlinx/omnia/omnia-token
 *
 */

pragma solidity ^0.8.0;

import "./MockOMNIABase.sol";
import "../contracts/claim/AutoClaimDetails.sol";

// Implements rewards
contract MockOMNIA is MockOMNIABase, AutoClaimDetails {
    event OSCUpdated(address old_, address new_);
    event CustomTokenUpdated(address old_, address new_);

    constructor(uint256 listingDate_)
        ERC20PresetFixedSupply("OMNIA", "OMNIA", 10**7 * 10**18, _msgSender())
        MockOMNIABase(
            0x337610d27c682E347C9cD60BD4b3b107C9d34dDd, // USDT
            0x64544969ed7EBf5f083679233325356EbE738930, //USDC
            0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee, // BUSD
            0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867, // DAI
            0x337610d27c682E347C9cD60BD4b3b107C9d34dDd, // USDT
            0x64544969ed7EBf5f083679233325356EbE738930, //USDC
            0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee, // BUSD
            0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867, // DAI
            0xEC5dCb5Dbf4B114C9d0F65BcCAb49EC54F6A0867 // DAI
        )
        MockSwapExecutorDetails(listingDate_)
    {
        //// Exclude addresses from rewards
        EnumerableSet.add(_addressesExcludedFromRewards, BURN_WALLET);
        EnumerableSet.add(_addressesExcludedFromRewards, address(this));
        EnumerableSet.add(_addressesExcludedFromRewards, address(0));
    }

    function setOSC(address osc_) external onlyOwner nonReentrant {
        emit OSCUpdated(OSC, osc_);
        OSC = osc_;
    }

    function setMyCustomToken(address custom_) external {
        emit CustomTokenUpdated(customTokenChosenBy[_msgSender()], custom_);
        customTokenChosenBy[_msgSender()] = custom_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(MockTransfers, ERC20) {
        bool isSelling = isPancakeSwapPair(recipient) && presaleEnded();
        if (isSelling) {
            // If last sell from `sender` was 24h ago or more
            // Also true when an address has never sold
            if (block.timestamp - _dailySellOf[sender].day >= 1 days) {
                _dailySellOf[sender].day = block.timestamp;
                _dailySellOf[sender].sold = 0;
            }
            // In case last sell from `sender` was less than 24h ago
            else {
                require(
                    _dailySellOf[sender].sold < maxDailySell(),
                    "Daily oversell"
                );
                amount = maxDailySell() - _dailySellOf[sender].sold;
            }
        }

        MockTransfers._transfer(sender, recipient, amount);

        // Update `_addressesExcludedFromRewards` to register when amount is sold to a contract.
        // As by default, all contracts are excluded from rewards except `OMNIA_REFLECTION_WALLET`
        // We need to update `_addressesExcludedFromRewards` to have a more accurate
        // `totalAmountOfOMNIAEligibleForRewards()`
        if (
            isExcludedFromRewards(recipient) &&
            !EnumerableSet.contains(_addressesExcludedFromRewards, recipient)
        ) EnumerableSet.add(_addressesExcludedFromRewards, recipient);

        if (isSelling) _dailySellOf[sender].sold += amount;
    }

    function calculateCirculatingSupply()
        public
        view
        override
        returns (uint256)
    {
        return super.calculateCirculatingSupply() - balanceOf(DX_SALE_LOCK);
    }

    function maxDailySell() public view returns (uint256) {
        return calculateCirculatingSupply() / listingDate;
    }

    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(sender, recipient, amount);

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
        _nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(
            balanceOf(recipient),
            amount,
            _nextAvailableClaimDate[recipient]
        );
        _nextAvailableClaimDate[sender] += calculateRewardCycleExtension(
            balanceOf(sender),
            amount,
            _nextAvailableClaimDate[sender]
        );

        bool isSelling = isPancakeSwapPair(recipient) && presaleEnded();
        if (!isSelling) {
            return;
        }

        // Trigger auto-claim
        try this.processRewardClaimQueue(_maxGasForAutoClaim) {} catch {}
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        EnumerableSet.add(_addressesExcludedFromFees, newOwner);
        super.transferOwnership(newOwner);
    }

    function _afterTokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._afterTokenTransfer(sender, recipient, amount);

        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Update auto-claim queue after balances have been updated
        updateAutoClaimQueue(sender);
        updateAutoClaimQueue(recipient);
    }

    function onPancakeSwapRouterUpdated() internal override {
        EnumerableSet.add(
            _addressesExcludedFromRewards,
            pancakeSwapRouterAddress()
        );
        EnumerableSet.add(
            _addressesExcludedFromRewards,
            pancakeSwapPairAddress()
        );
    }

    function isMarketTransfer(address sender, address recipient)
        internal
        view
        override
        returns (bool)
    {
        // Not a market transfer when we are sending out rewards
        return super.isMarketTransfer(sender, recipient) && !_processingQueue;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MockTransfers.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Base class that implements: BEP20 interface (through SwapManager), transfers & swaps, fees
abstract contract MockOMNIABase is MockTransfers {
    address public constant DX_SALE_LOCK =
        0x81E0eF68e103Ee65002d3Cf766240eD1c070334d;

    //Router MAINNET: 0x10ed43c718714eb63d5aa57b78b54704e256024e
    //Router TESTNET: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 || other 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    //Factory testnet: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
    constructor(
        address usdtAddr,
        address usdcAddr,
        address busdAddr,
        address daiAddr,
        address btcbAddr,
        address ethAddr,
        address adaAddr,
        address dotAddr,
        address maticAddr
    )
        SwapsManager(
            usdtAddr,
            usdcAddr,
            busdAddr,
            daiAddr,
            btcbAddr,
            ethAddr,
            adaAddr,
            dotAddr,
            maticAddr
        )
    {
        // Exclude contract from fees
        EnumerableSet.add(_addressesExcludedFromFees, address(this));
        EnumerableSet.add(_addressesExcludedFromFees, owner());

        // Initialize PancakeSwap V2 router and Omnia <-> BNB pair.
        setPancakeSwapRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

        _autoLiquidityWallet = owner();

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    // Ensures that the contract is able to receive BNB
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AutoClaim.sol";

abstract contract AutoClaimDetails is AutoClaim {
    address private _farmingContract;
    address private _vestingContract;

    event UpdateFarmingContract(address oldAddr, address newAddr);
    event UpdateVestingContract(address oldAddr, address newAddr);

    function setFarmingContract(address addr) external onlyOwner {
        emit UpdateFarmingContract(_farmingContract, addr);
        _farmingContract = addr;
    }

    function setVestingContract(address addr) external onlyOwner {
        emit UpdateVestingContract(_vestingContract, addr);
        _vestingContract = addr;
    }

    function setWhitelistedExternalProcessor(address addr, bool isWhitelisted)
        external
        onlyOwner
    {
        require(addr != address(0), "Invalid address");
        _whitelistedExternalProcessors[addr] = isWhitelisted;
    }

    function setMaxGasForAutoClaim(uint256 gas) external onlyOwner {
        _maxGasForAutoClaim = gas;
    }

    function farmingContract() external view returns (address) {
        return _farmingContract;
    }

    function vestingContract() external view returns (address) {
        return _vestingContract;
    }

    function isWhitelistedExternalProcessor(address addr)
        public
        view
        returns (bool)
    {
        return _whitelistedExternalProcessors[addr];
    }

    function isInRewardClaimQueue(address addr) public view returns (bool) {
        return _addressesInRewardClaimQueue[addr];
    }

    function rewardClaimQueueIndex() public view returns (uint256) {
        return _rewardClaimQueueIndex;
    }

    function rewardClaimQueueLength() public view returns (uint256) {
        return _rewardClaimQueue.length;
    }

    function maxGasForAutoClaim() public view returns (uint256) {
        return _maxGasForAutoClaim;
    }

    /*
    * @dev: 
    *   Default balances excluded from circulating supply: 
    *       - address(0) & `BURN_WALLET`: burn addresses, 
            - Locker contracts: 
                * DxSale locker 
                * Farming contract 
                * Vesting contract
    */
    function calculateCirculatingSupply()
        public
        view
        virtual
        returns (uint256)
    {
        uint256 excludedFromCirculation = totalSupply();
        excludedFromCirculation -= balanceOf(BURN_WALLET);
        excludedFromCirculation -= balanceOf(address(0));
        excludedFromCirculation -= balanceOf(_farmingContract);
        excludedFromCirculation -= balanceOf(_vestingContract);

        // Only burnt/inaccessible tokens are excluded from circluating supply
        return totalSupply() - excludedFromCirculation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./swaps/MockSwapExecutorDetails.sol";

// Base class that implements: tranfers
abstract contract MockTransfers is MockSwapExecutorDetails {
    mapping(address => Sell) internal _dailySellOf; //

    struct Sell {
        uint256 day;
        uint256 sold;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        require(
            sender != address(0),
            "Transfer from the zero address is not allowed"
        );
        require(
            recipient != address(0),
            "Transfer to the zero address is not allowed"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        if (
            (isPancakeSwapPair(sender) || isPancakeSwapPair(recipient)) &&
            (block.timestamp < listingDate)
        ) {
            revert(
                "Buying and selling are not allowed before September 5th 7:33 CET"
            );
        }

        // Perform a swap if needed.  A swap in the context of this contract is the process of swapping the contract's token balance with BNBs in order to provide liquidity and increase the reward pool
        executeSwapIfNeeded(sender, recipient);

        _beforeTokenTransfer(sender, recipient, amount);

        // Calculate fee rate
        uint256 feeRate = calculateFeeRate(sender, recipient);

        uint256 feeAmount = (amount * feeRate) / 100;
        uint256 transferAmount = amount - feeAmount;

        // Update balances
        updateBalances(sender, recipient, amount, feeAmount);

        // Update total fees, this is just a counter provided for visibility
        _totalFeesPooledInOMNIA += feeAmount;

        emit Transfer(sender, recipient, transferAmount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function updateBalances(
        address sender,
        address recipient,
        uint256 sentAmount,
        uint256 feeAmount
    ) private {
        // Calculate amount to be received by recipient
        uint256 receivedAmount = sentAmount - feeAmount;

        // Update balances
        _balances[sender] -= sentAmount;
        _balances[recipient] += receivedAmount;

        // Add fees to contract
        _balances[address(this)] += feeAmount;
    }

    function calculateFeeRate(address sender, address recipient)
        private
        view
        returns (uint256)
    {
        bool applyFees = presaleEnded() &&
            !isExcludedFromFees(sender) &&
            !isExcludedFromFees(recipient);
        if (applyFees) return TOTAL_TRANSACTION_FEE;

        return 0;
    }

    function dailySellOf(address user) public view returns (Sell memory) {
        return _dailySellOf[user];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../contracts/swaps/SwapExecutor.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Base class that implements: setters & getters for fees & swaps
abstract contract MockSwapExecutorDetails is SwapExecutor {
    constructor(uint256 listingDate_) {
        listingDate = listingDate_;
    }

    uint256 public listingDate;
    EnumerableSet.AddressSet internal _addressesExcludedFromFees; // The list of addresses that do not pay a fee for transactions
    uint256 internal _totalFeesPooledInOMNIA; // The total fees pooled (in OMNIA)

    /**------> SETTERS <------**/
    // Set from what amount in the token contract a swap should be triggered
    function setTokenSwapThreshold(uint256 threshold) external onlyOwner {
        require(
            threshold > 0 && threshold <= 1000,
            "0 > threshold <= 1,000 OMNIA"
        );
        _tokenSwapThreshold = threshold;
    }

    // Wallet that receives LP tokens
    function setAutoLiquidityWallet(address liquidityWallet)
        external
        onlyOwner
    {
        _autoLiquidityWallet = liquidityWallet;
    }

    function setExcludedFromFees(address addr, bool isExcluded)
        public
        onlyOwner
    {
        if (isExcluded && !EnumerableSet.add(_addressesExcludedFromFees, addr))
            revert("Cycle extension already enabled");

        if (
            !isExcluded &&
            !EnumerableSet.remove(_addressesExcludedFromFees, addr)
        ) revert("Cycle extension already disabled");
    }

    /**------> GETTERS <------**/
    function tokenSwapThreshold() public view returns (uint256) {
        return _tokenSwapThreshold;
    }

    function liquidityFee() public pure returns (uint8) {
        return LIQUIDITY_FEE;
    }

    function rewardFee() public pure returns (uint8) {
        return REWARD_FEE;
    }

    function autoLiquidityWallet() public view returns (address) {
        return _autoLiquidityWallet;
    }

    function totalBNBLiquidityAddedFromFees() public view returns (uint256) {
        return _totalBNBLiquidityAddedFromFees;
    }

    function totalTransactionFee() public pure returns (uint8) {
        return TOTAL_TRANSACTION_FEE;
    }

    function isExcludedFromFees(address addr) public view returns (bool) {
        return EnumerableSet.contains(_addressesExcludedFromFees, addr);
    }

    function totalFeesPooledInOMNIA() public view returns (uint256) {
        return _totalFeesPooledInOMNIA;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Swaps.sol";

abstract contract SwapExecutor is Swaps {
    uint256 public constant LISTING_DATE = 1630819980; // 5th September 2021, 7:33 CET
    uint256 public immutable MAX_BNB_LOCKED = 12000 * 10**18;

    function executeSwapIfNeeded(address sender, address recipient) internal {
        if (!isMarketTransfer(sender, recipient)) {
            return;
        }

        // Check if it's time to swap for liquidity & reward pool
        uint256 tokensAvailableForSwap = balanceOf(address(this));
        if (tokensAvailableForSwap >= _tokenSwapThreshold) {
            // Make sure that we are not stuck in a loop (Swap only once)
            bool isSelling = isPancakeSwapPair(recipient) && presaleEnded();
            if (isSelling) {
                executeSwap(tokensAvailableForSwap);
            }
        }
    }

    function executeSwap(uint256 amount) private {
        // Allow pancakeSwap to spend the tokens of the address
        _approve(address(this), pancakeSwapRouterAddress(), amount);

        // Liquidity fee until 12,000 BNB are locked
        if (_totalBNBLiquidityAddedFromFees < MAX_BNB_LOCKED)
            swapForLiquidityAndRewards(amount);
        else emit Swapped(amount, swapOMNIAForBNB(amount), 0, 0);
    }

    function swapForLiquidityAndRewards(uint256 amount) private {
        // The amount parameter includes both the liquidity and the reward tokens, we need to find the correct portion for each one so that they are allocated accordingly
        uint256 tokensReservedForLiquidity = (amount * LIQUIDITY_FEE) /
            TOTAL_TRANSACTION_FEE;
        uint256 tokensReservedForReward = amount - tokensReservedForLiquidity;

        // For the liquidity portion, half of it will be swapped for BNB and the other half will be used to add the BNB into the liquidity
        uint256 tokensToSwapForLiquidity = tokensReservedForLiquidity / 2;
        uint256 tokensToAddAsLiquidity = tokensToSwapForLiquidity;

        // Swap both reward tokens and liquidity tokens for BNB
        uint256 tokensToSwap = tokensReservedForReward +
            tokensToSwapForLiquidity;
        uint256 bnbSwapped = swapOMNIAForBNB(tokensToSwap);

        // Calculate what portion of the swapped BNB is for liquidity and supply it using the other half of the token liquidity portion.  The remaining BNBs in the contract represent the reward pool
        uint256 bnbToBeAddedToLiquidity = (bnbSwapped *
            tokensToSwapForLiquidity) / tokensToSwap;

        // `tokenA`, 0, is OMNIA
        // `tokenB`, 1, is WBNB
        // See `RouterManager.setPancakeSwapRouter()`
        uint256 omniaPrice = pancakeSwapPair().price0CumulativeLast();
        uint256 maxBnbAdded = bnbToBeAddedToLiquidity / omniaPrice;

        uint256 bnbPrice = pancakeSwapPair().price1CumulativeLast();
        uint256 maxOmniaAdded = tokensToAddAsLiquidity / bnbPrice;

        (, uint256 bnbAddedToLiquidity, ) = pancakeswapV2Router()
            .addLiquidityETH{value: bnbToBeAddedToLiquidity}(
            address(this),
            tokensToAddAsLiquidity,
            maxOmniaAdded - (maxOmniaAdded / _maxSlippage),
            maxBnbAdded - (maxBnbAdded / _maxSlippage),
            _autoLiquidityWallet,
            block.timestamp + 360
        );

        // Keep track of how many BNB were added to liquidity this way
        _totalBNBLiquidityAddedFromFees += bnbAddedToLiquidity;

        emit Swapped(
            tokensToSwap,
            bnbSwapped,
            tokensToAddAsLiquidity,
            bnbToBeAddedToLiquidity
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwapsManager.sol";

// Base class that implements: swaps
abstract contract Swaps is SwapsManager {
    // This function swaps a {amountOfOmnia} of Omnia tokens for BNB and returns the total amount of BNB received
    function swapOMNIAForBNB(uint256 amountOfOmnia) internal returns (uint256) {
        uint256 initialBalance = address(this).balance;

        // Generate pair for Omnia -> WBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router().WETH();

        // `tokenA`, 0, is OMNIA
        // `tokenB`, 1, is WBNB
        // See `RouterManager.setPancakeSwapRouter()`
        uint256 bnbPrice = pancakeSwapPair().price1CumulativeLast();
        uint256 maxOut = amountOfOmnia / bnbPrice;

        // Swap
        pancakeswapV2Router()
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountOfOmnia,
            maxOut - (maxOut / _maxSlippage),
            path,
            address(this),
            block.timestamp + 360
        );

        // Return the amount received
        return address(this).balance - initialBalance;
    }

    // Returns how many more $Omnia tokens are needed in the contract before triggering a swap
    function amountUntilSwap() public view returns (uint256) {
        uint256 balance = balanceOf(address(this));
        if (balance > _tokenSwapThreshold) {
            // Swap on next relevant transaction
            return 0;
        }

        return _tokenSwapThreshold - balance;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../RouterManager.sol";
import "../imported/ERC20PresetFixedSupply.sol";

abstract contract SwapsManager is ERC20PresetFixedSupply, RouterManager {
    uint8 public immutable LIQUIDITY_FEE = 3; //% of each transaction that will be added as liquidity
    uint8 public immutable REWARD_FEE = 12; //% of each transaction that will be reflected to holders
    uint8 public immutable TOTAL_TRANSACTION_FEE = 15; // The total fee taken and each transfer: buy, sell & send.
    uint16 internal _maxSlippage = 1000; // max slippage on transaction: from 0.1% to 1%

    bool private _inPresale = true;
    bool private _presaleEnded = false;

    uint256 internal _tokenSwapThreshold = totalSupply() / 100000; //There should be at least 0.0001% of the total supply in the contract before triggering a swap
    address internal _autoLiquidityWallet; // Wallet that receives LP tokens
    uint256 internal _totalBNBLiquidityAddedFromFees; // The total number of BNB added to the pool through fees

    address public USDT;
    address public USDC;
    address public BUSD;
    address public DAI;
    // Other top coins: BTCB ETH, ADA, DOT, MATIC
    // BTCB: https://www.binance.com/en/blog/421499824684901264/chain/experience-btcb--bitcoin-on-binance-smart-chain
    address public BTCB;
    address public ETH;
    address public ADA;
    address public DOT;
    address public MATIC;

    // EVENTS
    event Swapped(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity,
        uint256 bnbIntoLiquidity
    );

    constructor(
        address usdtAddr,
        address usdcAddr,
        address busdAddr,
        address daiAddr,
        address btcbAddr,
        address ethAddr,
        address adaAddr,
        address dotAddr,
        address maticAddr
    ) {
        USDT = usdtAddr;
        USDC = usdcAddr;
        BUSD = busdAddr;
        DAI = daiAddr;
        BTCB = btcbAddr;
        ETH = ethAddr;
        ADA = adaAddr;
        DOT = dotAddr;
        MATIC = maticAddr;
    }

    function inPresale() public view returns (bool) {
        return _inPresale;
    }

    function presaleEnded() public view returns (bool) {
        return _presaleEnded;
    }

    function endPresale() external onlyOwner {
        _inPresale = false;
        _presaleEnded = true;
    }

    function setMaxSlippage(uint16 slippage) external onlyOwner {
        if (slippage < 1000) revert("Slippage too low");
        if (slippage > 100) revert("Slippage too high");
        _maxSlippage = slippage;
    }

    // Function that is used to determine whether a transfer occurred due to a user buying/selling/transfering and not due to the contract swapping tokens
    function isMarketTransfer(address sender, address recipient)
        internal
        view
        virtual
        returns (bool)
    {
        return !isSwapTransfer(sender, recipient);
    }

    function isSwapTransfer(address sender, address recipient)
        private
        view
        returns (bool)
    {
        bool isContractSelling = sender == address(this) &&
            isPancakeSwapPair(recipient);
        return isContractSelling;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakeRouter02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract RouterManager is Ownable {
    address internal _pancakeSwapRouterAddress;
    IPancakeRouter02 internal _pancakeswapV2Router;
    IUniswapV2Pair internal _pancakeswapV2Pair;

    function onPancakeSwapRouterUpdated() internal virtual {}

    function setPancakeSwapRouter(address routerAddress) public onlyOwner {
        require(
            routerAddress != address(0),
            "Cannot use the zero address as router address"
        );

        _pancakeSwapRouterAddress = routerAddress;
        _pancakeswapV2Router = IPancakeRouter02(_pancakeSwapRouterAddress);
        address pair = IPancakeFactory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());
        _pancakeswapV2Pair = IUniswapV2Pair(pair);

        onPancakeSwapRouterUpdated();
    }

    function pancakeSwapRouterAddress() public view returns (address) {
        return _pancakeSwapRouterAddress;
    }

    function pancakeswapV2Router() public view returns (IPancakeRouter02) {
        return _pancakeswapV2Router;
    }

    function pancakeSwapPair() public view returns (IUniswapV2Pair) {
        return _pancakeswapV2Pair;
    }

    function pancakeSwapPairAddress() public view returns (address) {
        return address(_pancakeswapV2Pair);
    }

    function isPancakeSwapPair(address addr) public view returns (bool) {
        return address(_pancakeswapV2Pair) == addr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "./ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @notice code from OpenZeppelin with our ERC20: internal _balances (instead private)
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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
    /**
     * @dev Made private by Openzeppelin. Internal required for OMNIA as the reflection
     * needed to updates balances to take fees
     */
    mapping(address => uint256) internal _balances;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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

import "./Claim.sol";

abstract contract AutoClaim is Claim {
    uint256 internal _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
    address[] public _rewardClaimQueue;
    mapping(address => uint256) public _rewardClaimQueueIndices;
    uint256 internal _rewardClaimQueueIndex;
    mapping(address => bool) public _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
    bool internal _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
    mapping(address => bool) internal _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing

    function updateAutoClaimQueue(address user) internal {
        bool isQueued = _addressesInRewardClaimQueue[user];

        if (!isIncludedInRewards(user)) {
            if (isQueued) {
                // Need to dequeue
                uint256 index = _rewardClaimQueueIndices[user];
                address lastUser = _rewardClaimQueue[
                    _rewardClaimQueue.length - 1
                ];

                // Move the last one to this index, and pop it
                _rewardClaimQueueIndices[lastUser] = index;
                _rewardClaimQueue[index] = lastUser;
                _rewardClaimQueue.pop();

                // Clean-up
                delete _rewardClaimQueueIndices[user];
                delete _addressesInRewardClaimQueue[user];
            }
        } else {
            if (!isQueued) {
                // Need to enqueue
                _rewardClaimQueue.push(user);
                _rewardClaimQueueIndices[user] = _rewardClaimQueue.length - 1;
                _addressesInRewardClaimQueue[user] = true;
            }
        }
    }

    // Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue.
    // Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it
    // and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
    function processRewardClaimQueue(uint256 gas) public {
        require(gas > 0, "Gas limit is required");

        uint256 queueLength = _rewardClaimQueue.length;

        if (queueLength == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iteration = 0;
        _processingQueue = true;

        // Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
        while (gasUsed < gas && iteration < queueLength) {
            if (_rewardClaimQueueIndex >= queueLength) {
                _rewardClaimQueueIndex = 0;
            }

            address user = _rewardClaimQueue[_rewardClaimQueueIndex];
            if (isRewardReady(user) && isIncludedInRewards(user)) {
                doClaimReward(user);
            }

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                uint256 consumedGas = gasLeft - newGasLeft;
                gasUsed += consumedGas;
                gasLeft = newGasLeft;
            }

            iteration++;
            _rewardClaimQueueIndex++;
        }

        _processingQueue = false;
    }

    // Allows a whitelisted external contract/user/service to process the queue and have a portion of the gas costs refunded.
    // This can be used to help with transaction fees and payout response time when/if the queue grows too big for the contract.
    // "gas" parameter is the maximum amount of gas allowed to be used.
    function processRewardClaimQueueAndRefundGas(uint256 gas) external {
        require(
            _whitelistedExternalProcessors[_msgSender()],
            "Not whitelisted - use processRewardClaimQueue instead"
        );

        uint256 startGas = gasleft();
        processRewardClaimQueue(gas);
        uint256 gasUsed = startGas - gasleft();

        payable(_msgSender()).transfer(gasUsed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClaimCoins.sol";

abstract contract Claim is ClaimCoins {
    function claimReward() external nonReentrant {
        claimReward(_msgSender());
    }

    function claimReward(address user) public nonReentrant {
        require(
            _msgSender() == user || isClaimFromDelegatedTo(user, _msgSender()),
            "You are not allowed to claim rewards on behalf of this user"
        );
        require(
            isRewardReady(user),
            "Claim date for this address has not passed yet"
        );
        require(
            isIncludedInRewards(user),
            "Address is excluded from rewards, make sure there is enough OMNIA balance"
        );

        bool success = doClaimReward(user);
        require(success, "Reward claim failed");
    }

    function doClaimReward(address user) internal returns (bool) {
        // Update the next claim date & the total amount claimed
        _nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();

        (
            ClaimBaseRewards memory base,
            ClaimStableCoinsRewards memory stable,
            ClaimTopCoinsRewards memory topCoins
        ) = calculateClaimRewards(user);

        bool baseSuccess = claimBase(user, base);
        bool stablecoinSuccess = claimStableCoins(user, base, stable);
        bool topCoinSuccess = claimTopCoins(user, base, topCoins);

        // Claim BNB
        bool bnbClaimSuccess = claimBNB(user, base.bnb);

        // Fire the event in case something was claimed
        if (
            bnbClaimSuccess ||
            baseSuccess ||
            stablecoinSuccess ||
            topCoinSuccess
        ) {
            emit RewardClaimed(
                user,
                base,
                stable,
                topCoins,
                _nextAvailableClaimDate[user]
            );
        }

        return
            bnbClaimSuccess &&
            baseSuccess &&
            stablecoinSuccess &&
            topCoinSuccess;
    }

    function claimBNB(address user, uint256 bnbAmount) private returns (bool) {
        if (bnbAmount == 0) {
            // If `bnbAmount` is 0 and reward are set: `user` can choose to not earn BNB
            // If `bnbAmount` is 0 and rewards are NOT set there is an issue somewhere.
            // `RewardsCalculator.calculateClaimRewards()` set BNB percentage at 100 in case
            // rewards percentages are not set
            return areRewardsSet(user);
        }
        bool sent;

        // Send the reward to the caller
        if (_sendWeiGasLimit > 0) {
            (sent, ) = user.call{value: bnbAmount, gas: _sendWeiGasLimit}("");
        } else (sent, ) = user.call{value: bnbAmount}("");

        if (sent) {
            bnbRewardClaimed[user] += bnbAmount;
            totalBNBClaimed += bnbAmount;
        }
        return sent;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ClaimBEP20.sol";
import "../rewards/RewardsCalculator.sol";
import "./Claimable.sol";

abstract contract ClaimCoins is ClaimBEP20, RewardsCalculator, Claimable {
    function claimBase(address user, ClaimBaseRewards memory base)
        internal
        returns (bool)
    {
        bool omniaClaimSuccess = true;
        // Claim OMNIA tokens
        if (!claimBEP20(address(this), user, base.omnia)) {
            // If token claim fails for any reason, claim as BNB
            if (_reimburseAfterOMNIAClaimFailure) {
                base.bnb += base.omnia;
            } else {
                omniaClaimSuccess = false;
            }
            base.omnia = 0;
        } else {
            bnbAsOMNIAClaimed[user] += base.omnia;
            totalBNBAsOMNIAClaimed += base.omnia;
        }
        // Claim OSC
        bool oscClaimSuccess = true;
        if (OSC == address(0)) oscClaimSuccess = false;
        else if (!claimBEP20(OSC, user, base.osc)) {
            base.bnb += base.osc;
            base.osc = 0;
            oscClaimSuccess = false;
        } else {
            bnbAsOSCClaimed[user] += base.osc;
            totalBNBAsOSCClaimed += base.osc;
        }
        // Claim custom token chosen by user
        bool customClaimSuccess = true;
        if (customTokenChosenBy[user] == address(0)) oscClaimSuccess = false;
        else if (!claimBEP20(customTokenChosenBy[user], user, base.custom)) {
            base.bnb += base.custom;
            base.custom = 0;
            customClaimSuccess = false;
        } else {
            bnbAsCustomClaimed[user] += base.custom;
            totalBNBAsCustomClaimed += base.custom;
        }

        return omniaClaimSuccess && oscClaimSuccess && customClaimSuccess;
    }

    function claimStableCoins(
        address user,
        ClaimBaseRewards memory base,
        ClaimStableCoinsRewards memory stable
    ) internal returns (bool) {
        // Claim USDT tokens
        bool usdtClaimSuccess = true;
        if (!claimBEP20(USDT, user, stable.usdt)) {
            base.bnb += stable.usdt;
            stable.usdt = 0;
            usdtClaimSuccess = false;
        } else {
            bnbAsUSDTClaimed[user] += stable.usdt;
            totalBNBAsUSDTClaimed += stable.usdt;
        }

        // Claim USDC tokens
        bool usdcClaimSuccess = true;
        if (!claimBEP20(USDC, user, stable.usdc)) {
            base.bnb += stable.usdc;
            stable.usdc = 0;
            usdcClaimSuccess = false;
        } else {
            bnbAsUSDCClaimed[user] += stable.usdc;
            totalBNBAsUSDCClaimed += stable.usdc;
        }

        // Claim BUSD tokens
        bool busdClaimSuccess = true;
        if (!claimBEP20(BUSD, user, stable.busd)) {
            base.bnb += stable.busd;
            stable.busd = 0;
            busdClaimSuccess = false;
        } else {
            bnbAsBUSDClaimed[user] += stable.busd;
            totalBNBAsBUSDClaimed += stable.busd;
        }

        // Claim DAI tokens
        bool daiClaimSuccess = true;
        if (!claimBEP20(DAI, user, stable.dai)) {
            base.bnb += stable.dai;
            stable.dai = 0;
            daiClaimSuccess = false;
        } else {
            bnbAsDAIClaimed[user] += stable.dai;
            totalBNBAsDAIClaimed += stable.dai;
        }

        return
            usdtClaimSuccess &&
            usdcClaimSuccess &&
            busdClaimSuccess &&
            daiClaimSuccess;
    }

    function claimTopCoins(
        address user,
        ClaimBaseRewards memory base,
        ClaimTopCoinsRewards memory topCoins
    ) internal returns (bool) {
        // Claim BTCB tokens
        bool btcbClaimSuccess = true;
        if (!claimBEP20(BTCB, user, topCoins.btcb)) {
            base.bnb += topCoins.btcb;
            topCoins.btcb = 0;
            btcbClaimSuccess = false;
        } else {
            bnbAsBTCBClaimed[user] += topCoins.btcb;
            totalBNBAsBTCBClaimed += topCoins.btcb;
        }

        // Claim ETH tokens
        bool ethClaimSuccess = true;
        if (!claimBEP20(ETH, user, topCoins.eth)) {
            base.bnb += topCoins.eth;
            topCoins.eth = 0;
            ethClaimSuccess = false;
        } else {
            bnbAsETHClaimed[user] += topCoins.eth;
            totalBNBAsETHClaimed += topCoins.eth;
        }

        // Claim ADA tokens
        bool adaClaimSuccess = true;
        if (!claimBEP20(ADA, user, topCoins.ada)) {
            base.bnb += topCoins.ada;
            topCoins.ada = 0;
            adaClaimSuccess = false;
        } else {
            bnbAsADAClaimed[user] += topCoins.ada;
            totalBNBAsADAClaimed += topCoins.ada;
        }

        // Claim DOT tokens
        bool dotClaimSuccess = true;
        if (!claimBEP20(DOT, user, topCoins.dot)) {
            base.bnb += topCoins.dot;
            topCoins.dot = 0;
            dotClaimSuccess = false;
        } else {
            bnbAsDOTClaimed[user] += topCoins.dot;
            totalBNBAsDOTClaimed += topCoins.dot;
        }

        // Claim MATIC tokens
        bool maticClaimSuccess = true;
        if (!claimBEP20(MATIC, user, topCoins.matic)) {
            base.bnb += topCoins.matic;
            topCoins.matic = 0;
            maticClaimSuccess = false;
        } else {
            bnbAsMATICClaimed[user] += topCoins.matic;
            totalBNBAsMATICClaimed += topCoins.matic;
        }

        return
            btcbClaimSuccess &&
            ethClaimSuccess &&
            adaClaimSuccess &&
            dotClaimSuccess &&
            maticClaimSuccess;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../swaps/BEP20Swap.sol";

abstract contract ClaimBEP20 is BEP20Swap {
    function claimBEP20(
        address bep20Token,
        address user,
        uint256 bnbAmount
    ) internal returns (bool) {
        if (bnbAmount == 0) {
            return true;
        }

        bool success = swapBNBForBEP20(bep20Token, bnbAmount, user);
        if (!success) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./RewardManager.sol";
import "../swaps/SwapsManager.sol";
import "./tracker/RewardTracker.sol";

abstract contract RewardsCalculator is
    RewardManager,
    SwapsManager,
    RewardTracker
{
    address public constant BURN_WALLET =
        0x000000000000000000000000000000000000dEaD;

    function calculateClaimRewards(address ofAddress)
        public
        returns (
            ClaimBaseRewards memory,
            ClaimStableCoinsRewards memory,
            ClaimTopCoinsRewards memory
        )
    {
        // If rewards have not been choosen by _msgSender() it will be 100% in BNB
        if (!areRewardsSet(ofAddress))
            claimRewardAsBNBPercentage[_msgSender()] = 100;

        uint256 reward = calculateBNBReward(ofAddress);

        return (
            calculateClaimBaseRewards(ofAddress, reward),
            calculateClaimStableCoinsRewards(ofAddress, reward),
            calculateClaimTopCoinsRewards(ofAddress, reward)
        );
    }

    function calculateBNBReward(address ofAddress)
        public
        view
        returns (uint256)
    {
        uint256 holdersAmount = totalAmountOfOMNIAEligibleForRewards();

        uint256 balance = balanceOf(ofAddress);
        uint256 bnbPool = address(this).balance;

        // Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
        if (bnbPool > _mainBNBPoolSize) {
            bnbPool = _mainBNBPoolSize;
        }

        // If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
        uint256 reward = (bnbPool * balance) / holdersAmount;

        if (reward > _maxClaimAllowed) {
            reward = _maxClaimAllowed;
        }

        return reward;
    }

    // @notice: count the total amount of OMNIA that is eligible for rewards
    function totalAmountOfOMNIAEligibleForRewards()
        public
        view
        returns (uint256)
    {
        uint256 totalAmountExcludedFromRewards = 0;

        for (
            uint256 i = 0;
            i < EnumerableSet.length(_addressesExcludedFromRewards);
            i++
        ) {
            totalAmountExcludedFromRewards += balanceOf(
                EnumerableSet.at(_addressesExcludedFromRewards, i)
            );
        }

        return totalSupply() - totalAmountExcludedFromRewards;
    }

    function calculateClaimBaseRewards(
        address ofAddress,
        uint256 rewardOfAddress
    ) public view returns (ClaimBaseRewards memory) {
        uint256 percentageBNB = claimRewardAsBNBPercentage[ofAddress];
        uint256 percentageOMNIA = claimRewardAsOMNIAPercentage[ofAddress];
        uint256 percentageOSC = claimRewardAsOSCPercentage[ofAddress];
        uint256 percentageCustom = claimRewardAsCustomPercentage[ofAddress];

        ClaimBaseRewards memory base;

        base.bnb = (rewardOfAddress * percentageBNB) / 100;
        base.omnia = (rewardOfAddress * percentageOMNIA) / 100;
        base.osc = (rewardOfAddress * percentageOSC) / 100;
        base.custom = (rewardOfAddress * percentageCustom) / 100;

        return base;
    }

    function calculateClaimStableCoinsRewards(
        address ofAddress,
        uint256 rewardOfAddress
    ) public view returns (ClaimStableCoinsRewards memory) {
        uint256 percentageUSDT = claimRewardAsUSDTPercentage[ofAddress];
        uint256 percentageUSDC = claimRewardAsUSDCPercentage[ofAddress];
        uint256 percentageBUSD = claimRewardAsBUSDPercentage[ofAddress];
        uint256 percentageDAI = claimRewardAsDAIPercentage[ofAddress];

        ClaimStableCoinsRewards memory stable;

        stable.usdt = (rewardOfAddress * percentageUSDT) / 100;
        stable.usdc = (rewardOfAddress * percentageUSDC) / 100;
        stable.busd = (rewardOfAddress * percentageBUSD) / 100;
        stable.dai = (rewardOfAddress * percentageDAI) / 100;

        return stable;
    }

    function calculateClaimTopCoinsRewards(
        address ofAddress,
        uint256 rewardOfAddress
    ) public view returns (ClaimTopCoinsRewards memory) {
        uint256 percentageBTCB = claimRewardAsBTCBPercentage[ofAddress];
        uint256 percentageETH = claimRewardAsETHPercentage[ofAddress];
        uint256 percentageADA = claimRewardAsADAPercentage[ofAddress];
        uint256 percentageDOT = claimRewardAsDOTPercentage[ofAddress];
        uint256 percentageMATIC = claimRewardAsMATICPercentage[ofAddress];

        ClaimTopCoinsRewards memory topCoins;

        topCoins.btcb = (rewardOfAddress * percentageBTCB) / 100;
        topCoins.eth = (rewardOfAddress * percentageETH) / 100;
        topCoins.ada = (rewardOfAddress * percentageADA) / 100;
        topCoins.dot = (rewardOfAddress * percentageDOT) / 100;
        topCoins.matic = (rewardOfAddress * percentageMATIC) / 100;

        return topCoins;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../rewards/RewardCycle.sol";
import "../rewards/RewardManager.sol";

abstract contract Claimable is RewardCycle, RewardManager {
    bool internal _reimburseAfterOMNIAClaimFailure = true; // If true, and OMNIA reward claim portion fails, the portion will be given as BNB instead
    uint256 internal _sendWeiGasLimit;

    function isRewardReady(address user) public view returns (bool) {
        return _nextAvailableClaimDate[user] <= block.timestamp;
    }

    function isIncludedInRewards(address user) public view returns (bool) {
        return !isExcludedFromRewards(user);
    }

    function setSendWeiGasLimit(uint256 amount) external onlyOwner {
        _sendWeiGasLimit = amount;
    }

    function setReimburseAfterOMNIAClaimFailure(bool value) external onlyOwner {
        _reimburseAfterOMNIAClaimFailure = value;
    }

    function reimburseAfterOMNIAClaimFailure() public view returns (bool) {
        return _reimburseAfterOMNIAClaimFailure;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SwapsManager.sol";

abstract contract BEP20Swap is SwapsManager {
    function swapBNBForBEP20(
        address bep20Token,
        uint256 bnbAmount,
        address to
    ) internal returns (bool) {
        address[] memory path = new address[](2);
        path[0] = pancakeswapV2Router().WETH();
        path[1] = address(bep20Token);

        // `tokenA`, 0, is OMNIA
        // `tokenB`, 1, is WBNB
        // See `RouterManager.setPancakeSwapRouter()`
        uint256 omniaPrice = pancakeSwapPair().price0CumulativeLast();
        uint256 maxOut = bnbAmount / omniaPrice;

        // Swap and send the tokens to the 'to' address
        try
            pancakeswapV2Router()
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: bnbAmount
            }(maxOut - (maxOut / _maxSlippage), path, to, block.timestamp + 360)
        {
            return true;
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract RewardManager is Ownable, ReentrancyGuard {
    address public constant OMNIA_REFLECTION_WALLET =
        0x19eF52F4cE991fe9705c3a443dc1c2C7DDdB2fF9;
    using EnumerableSet for EnumerableSet.AddressSet;

    // REWARD MANAGER
    EnumerableSet.AddressSet internal _addressesExcludedFromRewards; // The list of addresses excluded from rewards
    mapping(address => mapping(address => bool)) internal _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else

    // REWARD MANAGER
    uint256 internal _maxClaimAllowed = 100 ether; // Can only claim up to 100 bnb at a time.
    uint256 internal _mainBNBPoolSize = 10000 ether; // Any excess BNB after the main pool will be used as reserves to ensure consistency in rewards

    function maxClaimAllowed() public view returns (uint256) {
        return _maxClaimAllowed;
    }

    function setMaxClaimAllowed(uint256 value) external onlyOwner {
        require(value > 0, "Value must be greater than zero");
        _maxClaimAllowed = value;
    }

    function setMainBNBPoolSize(uint256 size) external onlyOwner {
        require(size >= 10 ether, "Size is too small");
        _mainBNBPoolSize = size;
    }

    // @dev: Gives the rights to `byAddress` to claim my rewards on my behalf
    function deletegateMyClaimTo(address byAddress, bool isApproved) external {
        require(byAddress != address(0), "Invalid address");
        _rewardClaimApprovals[_msgSender()][byAddress] = isApproved;
    }

    function isExcludedFromRewards(address addr) public view returns (bool) {
        return
            _addressesExcludedFromRewards.contains(addr) ||
            (isContract(addr) && addr != OMNIA_REFLECTION_WALLET);
    }

    // @dev: Check if rewards of `ofAddress` can be claimed by `byAddress`
    function isClaimFromDelegatedTo(address ofAddress, address byAddress)
        public
        view
        returns (bool)
    {
        return _rewardClaimApprovals[ofAddress][byAddress];
    }

    function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function mainBNBPoolSize() public view returns (uint256) {
        return _mainBNBPoolSize;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./BaseRewardTracker.sol";
import "./TopCoinsRewardTracker.sol";
import "./StablecoinRewardTracker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract RewardTracker is
    BaseRewardTracker,
    TopCoinsRewardTracker,
    StablecoinRewardTracker,
    ReentrancyGuard
{
    address public OSC;
    mapping(address => address) public customTokenChosenBy;

    event RewardClaimed(
        address recipient,
        ClaimBaseRewards indexed base,
        ClaimStableCoinsRewards indexed stable,
        ClaimTopCoinsRewards indexed topCoins,
        uint256 nextAvailableClaimDate
    );

    function setClaimRewardPercentage(
        BasePercentage memory basePercentages,
        StableCoinsPercentage memory stableCoinsPercentages,
        TopCoinsPercentage memory topCoinsPercentages
    ) external nonReentrant {
        if (basePercentages.osc != 0) require(OSC != address(0), "OSC");
        if (basePercentages.custom != 0)
            require(customTokenChosenBy[msg.sender] != address(0), "Custom");

        uint256 totalPercentage = basePercentages.bnb +
            basePercentages.omnia +
            basePercentages.osc +
            basePercentages.custom;
        // Use block scoping for addition, otherwise: Stack too deep error
        {
            totalPercentage +=
                stableCoinsPercentages.usdt +
                stableCoinsPercentages.usdc +
                stableCoinsPercentages.busd +
                stableCoinsPercentages.dai;
        }
        {
            totalPercentage +=
                topCoinsPercentages.btcb +
                topCoinsPercentages.eth +
                topCoinsPercentages.ada +
                topCoinsPercentages.dot +
                topCoinsPercentages.matic;
        }

        require(totalPercentage == 100, "Sum is not 100%");

        // Base
        claimRewardAsBNBPercentage[msg.sender] = basePercentages.bnb;
        claimRewardAsOMNIAPercentage[msg.sender] = basePercentages.omnia;
        claimRewardAsOSCPercentage[msg.sender] = basePercentages.osc;
        claimRewardAsCustomPercentage[msg.sender] = basePercentages.custom;
        // Stablecoins
        claimRewardAsUSDTPercentage[msg.sender] = stableCoinsPercentages.usdt;
        claimRewardAsUSDCPercentage[msg.sender] = stableCoinsPercentages.usdc;
        claimRewardAsBUSDPercentage[msg.sender] = stableCoinsPercentages.busd;
        claimRewardAsDAIPercentage[msg.sender] = stableCoinsPercentages.dai;
        // Top coins
        claimRewardAsBTCBPercentage[msg.sender] = topCoinsPercentages.btcb;
        claimRewardAsETHPercentage[msg.sender] = topCoinsPercentages.eth;
        claimRewardAsADAPercentage[msg.sender] = topCoinsPercentages.ada;
        claimRewardAsDOTPercentage[msg.sender] = topCoinsPercentages.dot;
        claimRewardAsMATICPercentage[msg.sender] = topCoinsPercentages.matic;
    }

    function areRewardsSet(address addr) public view returns (bool) {
        uint256 totalPercentage = claimRewardAsBNBPercentage[addr] +
            claimRewardAsOMNIAPercentage[addr] +
            claimRewardAsOSCPercentage[addr] +
            claimRewardAsCustomPercentage[addr];

        {
            totalPercentage +=
                claimRewardAsUSDTPercentage[addr] +
                claimRewardAsUSDCPercentage[addr] +
                claimRewardAsBUSDPercentage[addr] +
                claimRewardAsDAIPercentage[addr];
        }

        {
            totalPercentage +=
                claimRewardAsBTCBPercentage[addr] +
                claimRewardAsETHPercentage[addr] +
                claimRewardAsADAPercentage[addr] +
                claimRewardAsDOTPercentage[addr] +
                claimRewardAsMATICPercentage[addr];
        }

        return totalPercentage > 0;
    }
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

abstract contract BaseRewardTracker {
    uint256 internal totalBNBClaimed; // The total number of BNB claimed by all addresses
    uint256 internal totalBNBAsOMNIAClaimed; // The total number of BNB that was converted to OMNIA and claimed by all addresses
    uint256 internal totalBNBAsOSCClaimed; // The total number of BNB that was converted to OSC and claimed by all addresses
    uint256 internal totalBNBAsCustomClaimed; // The total number of BNB that was converted to a custom token chosen by each holder and claimed by all addresses

    mapping(address => uint256) internal bnbRewardClaimed; // The amount of BNB claimed by each address
    mapping(address => uint256) internal bnbAsOMNIAClaimed; // The amount of BNB converted to OMNIA and claimed by each address
    mapping(address => uint256) internal bnbAsOSCClaimed; // The amount of BNB converted to OSC and claimed by each address
    mapping(address => uint256) internal bnbAsCustomClaimed; // The amount of BNB converted to a custom token and claimed by each address

    mapping(address => uint256) internal claimRewardAsBNBPercentage; //Allows users to optionally use a % of the reward pool to receive BNB automatically
    mapping(address => uint256) internal claimRewardAsOMNIAPercentage; //Allows users to optionally use a % of the reward pool to buy OMNIA automatically
    mapping(address => uint256) internal claimRewardAsOSCPercentage; //Allows users to optionally use a % of the reward pool to buy OSC automatically
    mapping(address => uint256) internal claimRewardAsCustomPercentage; //Allows users to optionally use a % of the reward pool to buy a custom token chosen by each holder automatically

    struct BasePercentage {
        uint256 bnb;
        uint256 omnia;
        uint256 osc;
        uint256 custom;
    }

    struct ClaimBaseRewards {
        uint256 bnb;
        uint256 omnia;
        uint256 osc;
        uint256 custom;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract TopCoinsRewardTracker {
    uint256 internal totalBNBAsBTCBClaimed; // The total number of BNB that was converted to BTCB and claimed by all addresses
    uint256 internal totalBNBAsETHClaimed; // The total number of BNB that was converted to ETH and claimed by all addresses
    uint256 internal totalBNBAsADAClaimed; // The total number of BNB that was converted to ADA and claimed by all addresses
    uint256 internal totalBNBAsDOTClaimed; // The total number of BNB that was converted to DOT and claimed by all addresses
    uint256 internal totalBNBAsMATICClaimed; // The total number of BNB that was converted to MATIC and claimed by all addresses

    mapping(address => uint256) internal bnbAsBTCBClaimed; // The amount of BNB converted to BTCB and claimed by each address
    mapping(address => uint256) internal bnbAsETHClaimed; // The amount of BNB converted to ETH and claimed by each address
    mapping(address => uint256) internal bnbAsADAClaimed; // The amount of BNB converted to ADA and claimed by each address
    mapping(address => uint256) internal bnbAsDOTClaimed; // The amount of BNB converted to DOT and claimed by each address
    mapping(address => uint256) internal bnbAsMATICClaimed; // The amount of BNB converted to MATIC and claimed by each address

    mapping(address => uint256) internal claimRewardAsBTCBPercentage; //Allows users to optionally use a % of the reward pool to receive BTCB automatically
    mapping(address => uint256) internal claimRewardAsETHPercentage; //Allows users to optionally use a % of the reward pool to receive ETH automatically
    mapping(address => uint256) internal claimRewardAsADAPercentage; //Allows users to optionally use a % of the reward pool to receive ADA automatically
    mapping(address => uint256) internal claimRewardAsDOTPercentage; //Allows users to optionally use a % of the reward pool to receive DOT automatically
    mapping(address => uint256) internal claimRewardAsMATICPercentage; //Allows users to optionally use a % of the reward pool to receive MATIC automatically

    struct TopCoinsPercentage {
        uint256 btcb;
        uint256 eth;
        uint256 ada;
        uint256 dot;
        uint256 matic;
    }
    struct ClaimTopCoinsRewards {
        uint256 btcb;
        uint256 eth;
        uint256 ada;
        uint256 dot;
        uint256 matic;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract StablecoinRewardTracker {
    uint256 internal totalBNBAsUSDTClaimed; // The total number of BNB that was converted to USDT and claimed by all addresses
    uint256 internal totalBNBAsUSDCClaimed; // The total number of BNB that was converted to USDC and claimed by all addresses
    uint256 internal totalBNBAsBUSDClaimed; // The total number of BNB that was converted to BUSD and claimed by all addresses
    uint256 internal totalBNBAsDAIClaimed; // The total number of BNB that was converted to DAI and claimed by all addresses

    mapping(address => uint256) internal bnbAsUSDTClaimed; // The amount of BNB converted to USDT and claimed by each address
    mapping(address => uint256) internal bnbAsUSDCClaimed; // The amount of BNB converted to USDC and claimed by each address
    mapping(address => uint256) internal bnbAsBUSDClaimed; // The amount of BNB converted to BUSD and claimed by each address
    mapping(address => uint256) internal bnbAsDAIClaimed; // The amount of BNB converted to DAI and claimed by each address

    mapping(address => uint256) internal claimRewardAsUSDTPercentage; //Allows users to optionally use a % of the reward pool to receive USDT automatically
    mapping(address => uint256) internal claimRewardAsUSDCPercentage; //Allows users to optionally use a % of the reward pool to receive USDC automatically
    mapping(address => uint256) internal claimRewardAsBUSDPercentage; //Allows users to optionally use a % of the reward pool to receive BUSD automatically
    mapping(address => uint256) internal claimRewardAsDAIPercentage; //Allows users to optionally use a % of the reward pool to receive DAI automatically

    struct StableCoinsPercentage {
        uint256 usdt;
        uint256 usdc;
        uint256 busd;
        uint256 dai;
    }
    struct ClaimStableCoinsRewards {
        uint256 usdt;
        uint256 usdc;
        uint256 busd;
        uint256 dai;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract RewardCycle is Ownable, ReentrancyGuard {
    uint256 private _rewardCyclePeriod = 6 hours; // Can claim rewards every 6h
    uint256 internal _rewardCycleExtensionThresholdOnTransfers = 50; // If someone sends or receives more than 50% of their current balance in a transaction, their reward cycle date will increase accordingly (max one more cycle to get rewards)
    mapping(address => uint256) internal _nextAvailableClaimDate; // The next available reward claim date for each address

    function setRewardCycleExtensionThreshold(uint256 threshold)
        external
        nonReentrant
        onlyOwner
    {
        require(threshold >= 0 && threshold <= 100, "Percentage only");
        _rewardCycleExtensionThresholdOnTransfers = threshold;
    }

    function rewardCyclePeriod() public view returns (uint256) {
        return _rewardCyclePeriod;
    }

    function rewardCycleExtensionThresholdOnTransfers()
        public
        view
        returns (uint256)
    {
        return _rewardCycleExtensionThresholdOnTransfers;
    }

    function nextAvailableClaimDate(address ofAddress)
        public
        view
        returns (uint256)
    {
        return _nextAvailableClaimDate[ofAddress];
    }

    // This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
    function calculateRewardCycleExtension(
        uint256 balance,
        uint256 amount,
        uint256 nextAvailableClaimDate_
    ) public view returns (uint256) {
        uint256 basePeriod = rewardCyclePeriod();

        if (balance == 0) {
            // Receiving $OMNIA on a zero balance address:
            // This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
            // Or the address has transferred all of its tokens in the past and has now received some again, in which case we will increase the reward claiming of one cycle
            return
                nextAvailableClaimDate_ == 0
                    ? block.timestamp + basePeriod
                    : basePeriod;
        }

        uint256 percentageTransferred = (amount * 100) / balance;

        // Depending on the % of $OMNIA tokens transferred, relative to the balance, we might need to extend the period
        if (
            percentageTransferred >= _rewardCycleExtensionThresholdOnTransfers
        ) {
            // If new balance is X percent higher, then we will extend the reward date by X percent
            uint256 extension = (basePeriod * percentageTransferred) / 100;

            // Cap to the base period
            if (extension >= basePeriod) {
                extension = basePeriod;
            }

            return extension;
        }

        return 0;
    }
}

