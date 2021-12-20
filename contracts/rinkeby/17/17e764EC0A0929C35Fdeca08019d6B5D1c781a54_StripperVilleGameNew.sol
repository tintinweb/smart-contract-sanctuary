// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Administration.sol";

interface IStrip is IERC20 {
    function burnTokens(uint amount) external;
}

interface IStripperVille is IERC721 {
    function clubsCount() external view returns (uint256);
}

contract StripperVilleGameNew is Administration, Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    event Claim(address indexed caller, uint256 qty);
    event Work(uint256 tokenId, uint256 gameId);
    event BuyWorker(address indexed to, uint256 gameId, uint256 stripperId, bool isThief);
    event ClubRank(uint256 indexed gameId, uint256 indexed clubId, uint256 ranking);

    struct Game {
        uint256 prize;
        uint256 startBlock;
        uint256 endBlock;
        uint256 price;
        uint256 maxThieves;
        uint256 availableCustomers;
        uint256 customerMultiplier;
    }

    struct Club {
        uint256 percentage;
        mapping(address => uint256) usersAndStrippersInClub;
        EnumerableSet.AddressSet addressesInClub;
        uint256 totalStrippers;
        // EnumerableSet.UintSet strippers;
        uint256 earn;
    }

    uint public thiefPrice = 100 ether;
    uint public customerPrice = 100 ether;

    IStrip public _coin;
    IStripperVille public _nft;

    Counters.Counter private _gameCounter;
    // stripperId => earnAmt
    mapping(uint256 => uint256) private _stripperEarnings;
    // gameNumber => Game
    mapping(uint256 => Game) private _games;
    // gameNumber => stripperId => hasCustomer
    mapping(uint256 => mapping(uint256 => bool)) private _gameStripperHasCustomer;
    // gameNumber => stripperId => clubId
    mapping(uint256 => mapping(uint256 => uint256)) private _gameStripperInClub;
    // gameNumber => clubId => Club
    mapping(uint => mapping (uint => Club)) private _gameClub;
    // account -> stripperId
    // Limit 1 customer per account and can only be assigned to 1 stripper
    mapping(address => uint256) private _currentGameCustomers;
    // gameNumber => top5 clubs for earn
    mapping(uint256 => uint[5]) private _gameClubRanks;
    // address => coinAmtEarned
    mapping(address => uint256) private _gameRewardsUnclaimed;

    modifier requireContractsSet() {
        require(address(_nft) != address(0) && address(_coin) != address(0), "Contracts not set");
        _;
    }
    
    modifier currentGameActive(){
        require(getCurrentGame().startBlock > 0 && getCurrentGame().endBlock == 0, "Game not active");
        _;
    }
    
    function getCurrentGame() public view returns (Game memory) {
        return _games[_gameCounter.current()];
    }

    function getEarnValue(uint256 stripperId) public view returns (uint256) {
        return _stripperEarnings[stripperId];
    }

    function isStripperCurrentlyInClub(uint256 stripperId) external view returns (bool) {
        return _gameStripperInClub[_gameCounter.current()][stripperId] >= 1000000;
    }

    function getClubOfStripper(uint256 gameId, uint256 stripperId) external view returns (uint256) {
        return _gameStripperInClub[gameId][stripperId];
    }

    function getUnclaimedGameRewards(address addr) external view returns (uint256) {
        return _gameRewardsUnclaimed[addr];
    }

    function getClubIds() external view returns (uint[] memory){
        uint[] memory ids = new uint[](_nft.clubsCount());
        uint initial = 1000000;
        for(uint i = 0; i < ids.length; i++) {
            ids[i] = i + initial;
        }
        return ids;
    }

    function getCustomerStripper(address addr) public view returns (uint256) {
        // Will return 0 if there isn't a customer purchased.
        // The game currently requires every customer purchase to instantly assign to an NFT
        return _currentGameCustomers[addr];
    }

    function claimRewards() external whenNotPaused {
        uint256 rewards = _gameRewardsUnclaimed[_msgSender()];
        require(rewards > 0, "No rewards to claim");
        _coin.transfer(_msgSender(), rewards);
        _gameRewardsUnclaimed[_msgSender()] = 0;
        emit Claim(_msgSender(), rewards);
    }
    
    function getCurrentGameId() public view returns (uint256) {
        return _gameCounter.current();
    }

    function pause() public onlyAdmin {
        _pause();
    }
    function unpause() public onlyAdmin {
        _unpause();
    }
    
    function setContracts(address coin, address nft) external onlyAdmin {
        _coin = IStrip(coin);
        _nft = IStripperVille(nft);
    }
    
    function setPrices(uint customer, uint thief) external onlyAdmin {
        thiefPrice = thief;
        customerPrice = customer;
    }

    function startNewGame(
        uint256 gamePrize,
        uint256 price,
        uint256 maxThieves,
        uint256 availableCustomers,
        uint256 customersMultiply
    ) external requireContractsSet onlyAdmin
    {
        // Increment the counter here to allow the last finished games to be accessible
        _gameCounter.increment();
        _games[_gameCounter.current()] = Game(
            gamePrize, 
            block.number, 
            0, 
            price, 
            maxThieves, 
            availableCustomers, 
            customersMultiply
        );
    }

    function endCurrentGame() external onlyAdmin {
        Game storage game = _games[_gameCounter.current()];
        game.endBlock = block.number;
        uint256[5] memory clubRanks = _gameClubRanks[_gameCounter.current()];
        for (uint256 i = 0; i < clubRanks.length; i++) {
            if(clubRanks[i] == 0) {
                continue;
            }
            Club storage club = _gameClub[_gameCounter.current()][clubRanks[i]];
            uint256 prizePercent = getPrizePercentForRank(i);
            uint256 totalClubEarning = game.prize * prizePercent / 100;
            uint256 clubOwnerReward = totalClubEarning * 10 / 100;
            uint256 rewardPerStripper = totalClubEarning * 90 / 100 / club.totalStrippers;
            _gameRewardsUnclaimed[_nft.ownerOf(clubRanks[i])] += clubOwnerReward;
            // Loop through each address that has strippers working in this club
            // This avoids high gas claiming for users
            for (uint256 j = 0; j < club.addressesInClub.length(); j++) {
                address addrCur = club.addressesInClub.at(j);
                _gameRewardsUnclaimed[addrCur] += rewardPerStripper 
                    * club.usersAndStrippersInClub[addrCur];
            }
            // Emit a rank for the game, club, and ranking of the club.
            emit ClubRank(_gameCounter.current(), clubRanks[i], i + 1);
        }
    }

    function setEarns(uint256 startingId, uint256 endingId, uint256[] calldata earns) external onlyAdmin {
        require(endingId >= startingId, "Invalid chunk of ids");
        require(endingId - startingId + 1 == earns.length, "Wrong # of earn values given");
        for (uint256 i = startingId; i <= endingId; i += 1) {
            _stripperEarnings[i] = earns[i - startingId];
        }
    }
    
    function buyCustomer(uint256 stripperId) external currentGameActive {
        require(_coin.balanceOf(_msgSender()) >= customerPrice, "BALANCE: insuficient funds");
        require(getCurrentGame().availableCustomers > 0, "No customers available.");
        require(_nft.ownerOf(stripperId) == _msgSender(), "Not owner of token");
        require(_gameStripperInClub[_gameCounter.current()][stripperId] < 1000000, "Stripper cannot be in club");
        _currentGameCustomers[_msgSender()] = stripperId;
        _games[_gameCounter.current()].availableCustomers -= 1;
        emit BuyWorker(_msgSender(), _gameCounter.current(), stripperId, false);
    }

    function sortTop5(uint256 clubIdChanged, uint256 clubEarn) private {
        uint256[5] storage ranks = _gameClubRanks[_gameCounter.current()];
        uint256 shiftingClubId = clubIdChanged;
        uint256 shiftingClubEarn = clubEarn;
        for (uint256 i = 0; i < ranks.length; i++) {
            if(ranks[i] == shiftingClubId) {
                return;
            }
            uint256 currentClubEarn = _gameClub[_gameCounter.current()][ranks[i]].earn;
            if(shiftingClubEarn > currentClubEarn) {
                // Save the current clubId as the current rank
                //  and take the old current to be shifted to the next rank
                (ranks[i], shiftingClubId) = (shiftingClubId, ranks[i]);
                shiftingClubEarn = currentClubEarn;
            }
        }

    }
    
    function work(uint256[] calldata stripperIds, uint256 clubId) external currentGameActive whenNotPaused {
        require(stripperIds.length > 0, "No tokens given");
        require(clubId >= 1000000, "CLUB: token is not a club");
        // NOTE: Cannot verify that clubId exists due to lack of _exists visibility
        Game memory game = getCurrentGame();
        if(game.price > 0) {
            // Burn the number of total coins needed to send every token to a club
            require(_coin.balanceOf(_msgSender()) >= game.price * stripperIds.length, "BALANCE: insuficient funds");
            _coin.burnTokens(game.price * stripperIds.length);
        }
        uint newClubEarn;
        for (uint256 i = 0; i < stripperIds.length; i++) {
            uint256 stripperId = stripperIds[i];
            require(_gameStripperInClub[_gameCounter.current()][stripperId] < 1000000, "NFT already in club");
            require(_nft.ownerOf(stripperId) == _msgSender(), "Not owner of token");
            uint256 earn = getEarnValue(stripperId);
            // If the stripper has a customer assigned to them,
            //  increase the earn by the customer's multiplier
            if(_currentGameCustomers[_msgSender()] == stripperId) {
                earn *= game.customerMultiplier;
            }

            // Assign stripper to club
            // Increment club earn / stripper count
            Club storage club = _gameClub[_gameCounter.current()][clubId];
            club.earn += earn;
            newClubEarn = club.earn;
            club.usersAndStrippersInClub[_msgSender()]++;
            // Will only add if not present in array
            club.addressesInClub.add(_msgSender());
            club.totalStrippers++;
            _gameStripperInClub[_gameCounter.current()][stripperId] = clubId;
            emit Work(stripperId, _gameCounter.current());
        }
        sortTop5(clubId, newClubEarn);
    }

    function getPrizePercentForRank(uint256 rankIndex) internal pure returns (uint256) {
        if(rankIndex == 0) {
            return 40;
        }
        if(rankIndex == 1) {
            return 30;
        }
        if(rankIndex == 2) {
            return 15;
        }
        if(rankIndex == 3) {
            return 10;
        }
        if(rankIndex == 4) {
            return 5;
        }
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Administration is Ownable {
    
    event SetAdmin(address indexed admin, bool active);
    
    mapping (address => bool) private admins;
    
    modifier onlyAdmin(){
        require(admins[_msgSender()] || owner() == _msgSender(), "Admin: caller is not an admin");
        _;
    }
    
    function setAdmin(address admin, bool active) external onlyOwner {
        admins[admin] = active;
        emit SetAdmin(admin, active);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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