// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ITuxERC20.sol";
import "./library/RankedSet.sol";
import "./library/AddressSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

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
contract TuxERC20 is
    ITuxERC20,
    ERC20Burnable
{
    using RankedSet for RankedSet.Set;
    using AddressSet for AddressSet.Set;

    // Admin address for managing payout addresses
    address public owner;

    // Tux auctions address
    address public minter;

    // Currently featured auction
    uint256 public featured;

    // Timestamp of next featured auction
    uint256 public nextFeaturedTime;

    // Amount of time for featured auctions
    uint256 constant public featuredDuration = 3600; // 1 hour -> 3600 seconds

    // Amount of time between payouts
    uint256 constant public payoutsFrequency = 604800; // 7 days -> 604800 seconds

    // Timestamp of next payouts
    uint256 public nextPayoutsTime = block.timestamp + payoutsFrequency;

    // Payout amount to pinning and API services
    uint256 public payoutAmount = 100 * 10**18;

    // AddressSet of payout addresses to pinning and API services
    AddressSet.Set private _payoutAddresses;

    // RankedSet for queue of next featured auction
    RankedSet.Set private _featuredQueue;

    /**
     * @dev Mints 100,000 tokens and adds payout addresses.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        owner = msg.sender;

        _mint(owner, 100000 * 10**18);

        _payoutAddresses.add(0x71C7656EC7ab88b098defB751B7401B5f6d8976F); // Etherscan
        // _payoutAddresses.add(0xInfura); // Infura
        // _payoutAddresses.add(0xPinata); // Pinata
        // _payoutAddresses.add(0xAlchemy); // Alchemy
        // _payoutAddresses.add(0xNFT.Storage); // nft.storage
    }

    /**
     * @dev Sets the minting address.
     */
    function setMinter(address minter_)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        minter = minter_;
    }

    /**
     * @dev Add a payout address, up to 10.
     */
    function addPayoutAddress(address payoutAddress)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");
        require(
            _payoutAddresses.length() < 10,
            "Maximum reached");

        _payoutAddresses.add(payoutAddress);
    }

    /**
     * @dev Remove a payout address.
     */
    function removePayoutAddress(address payoutAddress)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        _payoutAddresses.remove(payoutAddress);
    }

    /**
     * @dev Update payout amount up to 1000.
     */
    function updatePayoutAmount(uint256 amount)
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");
        require(
            amount < 1000 * 10**18,
            "Amount too high");

        payoutAmount = amount;
    }

    /**
     * @dev Renounce ownership once payout addresses are added and the payout
     * amount gets settled.
     */
    function renounceOwnership()
        external
    {
        require(
            msg.sender == owner,
            "Not owner address");

        owner = address(0);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be the Tux auctions contract.
     */
    function mint(address to, uint256 amount)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");

        _mint(to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount)
        public
        override(ERC20Burnable)
    {
        _burn(msg.sender, amount);
    }

    /**
     * Add Tux auction to featured queue
     */
    function feature(uint256 auctionId, uint256 amount, address from)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");
        require(
            balanceOf(from) >= amount,
            "Not enough TUX");
        require(
            _featuredQueue.contains(auctionId) == false,
            "Already queued");
        require(
            amount >= 1 * 10**18,
            "Price too low");

        updateFeatured();

        _burn(from, amount);

        _featuredQueue.add(auctionId);
        _featuredQueue.rankScore(auctionId, amount);

        payouts();
    }

    function cancel(uint256 auctionId, address from)
        external
        virtual
        override
    {
        require(
            msg.sender == minter,
            "Not minter address");
        require(
            _featuredQueue.contains(auctionId) == true,
            "Not queued");

        _mint(from, _featuredQueue.scoreOf(auctionId));

        _featuredQueue.remove(auctionId);

        updateFeatured();
        payouts();
    }

    /**
     * Get featured items
     */
    function getFeatured(uint256 from, uint256 n)
        view
        public
        returns(uint256[] memory)
    {
        return _featuredQueue.valuesFromN(from, n);
    }

    /**
     * Get featured queue length
     */
    function getFeaturedLength()
        view
        public
        returns(uint256 length)
    {
        return _featuredQueue.length();
    }

    /**
     * Get if featured queue contains an auction ID
     */
    function getFeaturedContains(uint auctionId)
        view
        public
        returns(bool)
    {
        return _featuredQueue.contains(auctionId);
    }

    /**
     * Get next featured timestamp
     */
    function getNextFeaturedTime()
        view
        public
        returns(uint256 timestamp)
    {
        return nextFeaturedTime;
    }

    /**
     * Get featured price of queue item
     */
    function getFeaturedPrice(uint256 auctionId)
        view
        public
        returns(uint256 price)
    {
        return _featuredQueue.scoreOf(auctionId);
    }

    /**
     * Update featured queue
     */
    function updateFeatured()
        public
        override
    {
        if (block.timestamp < nextFeaturedTime || _featuredQueue.length() == 0) {
            return;
        }

        nextFeaturedTime = block.timestamp + featuredDuration;
        uint256 auctionId = _featuredQueue.head();
        _featuredQueue.remove(auctionId);
        featured = auctionId;

        _mint(msg.sender, 1 * 10**18);
    }

    /**
     * Mint weekly payouts to pinning and API services
     */
    function payouts()
        public
        override
    {
        if (block.timestamp < nextPayoutsTime) {
            return;
        }

        nextPayoutsTime = block.timestamp + payoutsFrequency;

        for (uint i = 0; i < _payoutAddresses.length(); i++) {
            _mint(_payoutAddresses.at(i), payoutAmount);
        }

        _mint(msg.sender, 1 * 10**18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITuxERC20 {
    function mint(address to, uint256 amount) external;

    function feature(
        uint256 auctionId,
        uint256 amount,
        address from
    ) external;

    function cancel(
        uint256 auctionId,
        address from
    ) external;

    function updateFeatured() external;
    function payouts() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OrderedSet.sol";

/**
 * @title RankedSet
 * @dev Ranked data structure using two ordered sets, a mapping of scores to
 * boundary values and counter, a mapping of last ranked scores, and a highest
 * score.
 */
library RankedSet {
    using OrderedSet for OrderedSet.Set;

    struct RankGroup {
        uint256 count;
        uint256 start;
        uint256 end;
    }

    struct Set {
        uint256 highScore;
        mapping(uint256 => RankGroup) rankgroups;
        mapping(uint256 => uint256) scores;
        OrderedSet.Set rankedScores;
        OrderedSet.Set rankedItems;
    }

    /**
     * @dev Add an item at the end of the set
     */
    function add(Set storage set, uint256 item) internal {
        set.rankedItems.append(item);
        set.rankgroups[0].end = item;
        set.rankgroups[0].count += 1;
        if (set.rankgroups[0].start == 0) {
            set.rankgroups[0].start = item;
        }
    }

    /**
     * @dev Remove an item
     */
    function remove(Set storage set, uint256 item) internal {
        uint256 score = set.scores[item];
        delete set.scores[item];

        RankGroup storage rankgroup = set.rankgroups[score];
        if (rankgroup.count > 0) {
            rankgroup.count -= 1;
        }

        if (rankgroup.count == 0) {
            rankgroup.start = 0;
            rankgroup.end = 0;
            if (score == set.highScore) {
                set.highScore = set.rankedScores.next(score);
            }
            if (score > 0) {
                set.rankedScores.remove(score);
            }
        } else {
            if (rankgroup.start == item) {
                rankgroup.start = set.rankedItems.next(item);
            }
            if (rankgroup.end == item) {
                rankgroup.end = set.rankedItems.prev(item);
            }
        }

        set.rankedItems.remove(item);
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (uint256) {
        return set.rankedItems._next[0];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (uint256) {
        return set.rankedItems._prev[0];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.rankedItems.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set.rankedItems._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set.rankedItems._next[0] == value ||
               set.rankedItems._next[value] != 0 ||
               set.rankedItems._prev[value] != 0;
    }

    /**
     * @dev Returns a value's score
     */
    function scoreOf(Set storage set, uint256 value) internal view returns (uint256) {
        return set.scores[value];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](set.rankedItems.count);
        uint256 value = set.rankedItems._next[0];
        uint256 i = 0;
        while (value != 0) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, uint256 from, uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](n);
        uint256 value = set.rankedItems._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set.rankedItems._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Rank new score
     */
    function rankScore(Set storage set, uint256 item, uint256 newScore) internal {
        RankGroup storage rankgroup = set.rankgroups[newScore];

        if (newScore > set.highScore) {
            remove(set, item);
            rankgroup.start = item;
            set.highScore = newScore;
            set.rankedItems.add(item);
            set.rankedScores.add(newScore);
        } else {
            uint256 score = set.scores[item];
            uint256 prevScore = set.rankedScores.prev(score);

            if (set.rankgroups[score].count == 1) {
                score = set.rankedScores.next(score);
            }

            remove(set, item);

            while (prevScore > 0 && newScore > prevScore) {
                prevScore = set.rankedScores.prev(prevScore);
            }

            set.rankedItems.insert(
                set.rankgroups[prevScore].end,
                item,
                set.rankgroups[set.rankedScores.next(prevScore)].start
            );

            if (rankgroup.count == 0) {
                set.rankedScores.insert(prevScore, newScore, score);
                rankgroup.start = item;
            }
        }

        rankgroup.end = item;
        rankgroup.count += 1;

        set.scores[item] = newScore;
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
 * As of v3.3.0, sets of type `address` (`addressSet`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library AddressSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // address values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in address.

    struct Set {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(Set storage set, address value) internal returns (bool) {
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
                address lastvalue = set._values[lastIndex];

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
    function contains(Set storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
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
    function at(Set storage set, uint256 index) internal view returns (address) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (address[] memory) {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
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
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OrderedSet
 * @dev Ordered data structure. It has the properties of a mapping of uint256, but members are ordered
 * and can be enumerated. Values can be inserted and removed from anywhere. Add, append, remove and
 * contains are O(1). Enumerate is O(N).
 */
library OrderedSet {

    struct Set {
        uint256 count;
        mapping (uint256 => uint256) _next;
        mapping (uint256 => uint256) _prev;
    }

    /**
     * @dev Insert a value between two values
     */
    function insert(Set storage set, uint256 prev_, uint256 value, uint256 next_) internal {
        set._next[prev_] = value;
        set._next[value] = next_;
        set._prev[next_] = value;
        set._prev[value] = prev_;
        set.count += 1;
    }

    /**
     * @dev Insert a value as the new head
     */
    function add(Set storage set, uint256 value) internal {
        insert(set, 0, value, set._next[0]);
    }

    /**
     * @dev Insert a value as the new tail
     */
    function append(Set storage set, uint256 value) internal {
        insert(set, set._prev[0], value, 0);
    }

    /**
     * @dev Remove a value
     */
    function remove(Set storage set, uint256 value) internal {
        set._next[set._prev[value]] = set._next[value];
        set._prev[set._next[value]] = set._prev[value];
        delete set._next[value];
        delete set._prev[value];
        if (set.count > 0) {
            set.count -= 1;
        }
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (uint256) {
        return set._next[0];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (uint256) {
        return set._prev[0];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, uint256 _value) internal view returns (uint256) {
        return set._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._next[0] == value ||
               set._next[value] != 0 ||
               set._prev[value] != 0;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](set.count);
        uint256 value = set._next[0];
        uint256 i = 0;
        while (value != 0) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, uint256 from, uint256 n) internal view returns (uint256[] memory) {
        uint256[] memory _values = new uint256[](n);
        uint256 value = set._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
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