// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMintableERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Staking contract that allows NFT users
 *         to temporarily lock their NFTs to earn
 *         ERC-20 token rewards
 *
 * The NFTs are locked inside this contract for the
 * duration of the staking period while allowing the
 * user to unstake at any time
 *
 * While the NFTs are staked, they are technically
 * owned by this contract and cannot be moved or placed
 * on any marketplace
 *
 * The contract allows users to stake and unstake multiple
 * NFTs efficiently, in one transaction
 *
 * Staking rewards are paid out to users once
 * they unstake their NFTs and are calculated
 * based on a rounded down number of days the NFTs
 * were staken for
 *
 * Some of the rarest NFTs are boosted by the contract
 * owner to receive bigger staking rewards
 *
 * @dev Features a contract owner that is able to change
 *      the daily rewards, the boosted NFT list and the
 *      boosted NFT daily rewards
 */
contract TokenRewardStakingRange is ERC721Holder, Ownable {
  using EnumerableSet for EnumerableSet.UintSet;

  /**
   * @notice Uint256Range struct is used to encapsulate information regarding
   *         range items. The type of these ranges are uint256.
   */
  struct Uint256Range {
    uint256 begin;
    uint256 end;
  }

  /**
   * @notice Stores the ERC-20 token that will
   *         be paid out to NFT holders for staking
   */
  IMintableERC20 public immutable erc20;

  /**
   * @notice Stores the ERC-721 token that will
   *         be staken to receive ERC-20 rewards
   */
  IERC721 public immutable erc721;

  /**
   * @notice Amount of tokens earned for each
   *         day (24 hours) the token was staked for
   *
   * @dev Can be changed by contract owner via setDailyRewards()
   */
  uint128 public dailyRewards;

  /**
   * @notice Some NFTs are boosted to receive bigger token
   *         rewards. This multiplier shows how much more
   *         they will receive
   *
   * E.g. dailyRewardBoostMultiplier = 10 means that the boosted
   * NFTs will receive 10 times the dailyRewards
   *
   * @dev Can be changed by contract owner via setDailyRewardBoostMultiplier()
   */
  uint128 public dailyRewardBoostMultiplier;

  /**
   * @notice Boosted NFT ids contained in [boostedNftIdsRange.begin, boostedNftIdsRange.end]
   *         (inclusively) earn bigger daily rewards
   *
   * @dev The boosted NFT must belong on this range to be valid.
   *
   * @dev Can be changed by contract owner via setBoostedNftIdsRange()
   */
  Uint256Range private boostedNftIdsRange;

  /**
   * @notice Stores ownership information for staked
   *         NFTs
   */
  mapping(uint256 => address) public ownerOf;

  /**
   * @notice Stores time staking started for staked
   *         NFTs
   */
  mapping(uint256 => uint256) public stakedAt;

  /**
   * @dev Stores the staked tokens of an address
   */
  mapping(address => EnumerableSet.UintSet) private stakedTokens;

  /**
   * @dev Sets initialization variables which cannot be
   *      changed in the future
   *
   * @param _erc20Address address of erc20 rewards token
   * @param _erc721Address address of erc721 token to be staken for rewards
   * @param _dailyRewards daily amount of tokens to be paid to stakers for every day
   *                       they have staken an NFT
   * @param _boostedNftIdsRange Struct that denotes the token id range of boosted NFTs (inclusively)
   * @param _dailyRewardBoostMultiplier multiplier of rewards for boosted NFTs
   */
  constructor(
    address _erc20Address,
    address _erc721Address,
    uint128 _dailyRewards,
    Uint256Range memory _boostedNftIdsRange,
    uint128 _dailyRewardBoostMultiplier
  ) {
    erc20 = IMintableERC20(_erc20Address);
    erc721 = IERC721(_erc721Address);
    setDailyRewards(_dailyRewards);
    setBoostedNftIdsRange(_boostedNftIdsRange);
    setDailyRewardBoostMultiplier(_dailyRewardBoostMultiplier);
  }

  /**
   * @dev Emitted every time a token is staked
   *
   * Emitted in stake()
   *
   * @param by address that staked the NFT
   * @param time block timestamp the NFT were staked at
   * @param tokenId token ID of NFT that was staken
   */
  event Staked(address indexed by, uint256 indexed tokenId, uint256 time);

  /**
   * @dev Emitted every time a token is unstaked
   *
   * Emitted in unstake()
   *
   * @param by address that unstaked the NFT
   * @param time block timestamp the NFT were staked at
   * @param tokenId token ID of NFT that was unstaken
   * @param stakedAt when the NFT initially staked at
   * @param reward how many tokens user got for the
   *               staking of the NFT
   */
  event Unstaked(address indexed by, uint256 indexed tokenId, uint256 time, uint256 stakedAt, uint256 reward);

  /**
   * @dev Emitted when the boosted NFT ids is changed
   *
   * Emitted in setDailyReward()
   *
   * @param by address that changed the daily reward
   * @param oldDailyRewards old daily reward
   * @param newDailyRewards new daily reward in effect
   */
  event DailyRewardsChanged(address indexed by, uint128 oldDailyRewards, uint128 newDailyRewards);

  /**
   * @dev Emitted when the boosted NFT daily reward
   *      multiplier is changed
   *
   * Emitted in setDailyRewardBoostMultiplier()
   *
   * @param by address that changed the daily reward boost multiplier
   * @param oldDailyRewardBoostMultiplier old daily reward boost multiplier
   * @param newDailyRewardBoostMultiplier new daily reward boost multiplier
   */
  event DailyRewardBoostMultiplierChanged(
    address indexed by,
    uint128 oldDailyRewardBoostMultiplier,
    uint128 newDailyRewardBoostMultiplier
  );

  /**
   * @dev Emitted when the boosted NFT ids change
   *
   * Emitted in setBoostedNftIdsRange()
   *
   * @param by address that changed the boosted NFT ids
   * @param oldBoostedNftIdsRange old boosted NFT ids range
   * @param newBoostedNftIdsRange new boosted NFT ids range
   */
  event BoostedNftIdsChanged(address indexed by, Uint256Range oldBoostedNftIdsRange, Uint256Range newBoostedNftIdsRange);

  /**
   * @notice Checks whether a token is boosted to receive
   *         bigger staking rewards
   *
   * @param _tokenId ID of token to check
   * @return whether the token is boosted
   */
  function isBoostedToken(uint256 _tokenId) public view returns (bool) {
    return  _tokenId >= boostedNftIdsRange.begin && _tokenId <=boostedNftIdsRange.end;
  }

  /**
   * @notice Changes the daily reward in erc20 tokens received
   *         for every NFT staked
   *
   * @dev Restricted to contract owner
   *
   * @param _newDailyRewards the new daily reward in erc20 tokens
   */
  function setDailyRewards(uint128 _newDailyRewards) public onlyOwner {
    // Emit event
    emit DailyRewardsChanged(msg.sender, dailyRewards, _newDailyRewards);

    // Change storage variable
    dailyRewards = _newDailyRewards;
  }

  /**
   * @notice Changes the daily reward boost multiplier for
   *         boosted NFTs
   *
   * @dev Restricted to contract owner
   *
   * @param _newDailyRewardBoostMultiplier the new daily reward boost multiplier
   */
  function setDailyRewardBoostMultiplier(uint128 _newDailyRewardBoostMultiplier) public onlyOwner {
    // Emit event
    emit DailyRewardBoostMultiplierChanged(msg.sender, dailyRewardBoostMultiplier, _newDailyRewardBoostMultiplier);

    // Change storage variable
    dailyRewardBoostMultiplier = _newDailyRewardBoostMultiplier;
  }

  /**
   * @notice Changes the boosted NFT ids that receive
   *         a bigger daily reward
   *
   * @dev Restricted to contract owner
   *
   * @param _newBoostedNftIdsRange the new boosted NFT ids range
   */
  function setBoostedNftIdsRange(Uint256Range memory _newBoostedNftIdsRange) public onlyOwner {
    // Check that end range >= start range
    require(
      _newBoostedNftIdsRange.end >= _newBoostedNftIdsRange.begin, 
      "end less than begin"
    );

    // Create Uint256Range to store old boosted NFTs and emit
    // event later
    Uint256Range memory oldBoostedNftIdsRange = Uint256Range(boostedNftIdsRange.begin, boostedNftIdsRange.end);

    // Update the boostedNftIdsRange with the new range.
    boostedNftIdsRange = _newBoostedNftIdsRange;

    // Emit event
    emit BoostedNftIdsChanged(msg.sender, oldBoostedNftIdsRange, _newBoostedNftIdsRange);
  }

  /**
   * @notice Calculates all the NFTs currently staken by
   *         an address
   *
   * @dev This is an auxiliary function to help with integration
   *      and is not used anywhere in the smart contract login
   *
   * @param _owner address to search staked tokens of
   * @return an array of token IDs of NFTs that are currently staken
   */
  function tokensStakedByOwner(address _owner) external view returns (uint256[] memory) {
    // Cache the length of the staked tokens set for the owner
    uint256 stakedTokensLength = stakedTokens[_owner].length();

    // Create an empty array to store the result
    // Should be the same length as the staked tokens
    // set
    uint256[] memory tokenIds = new uint256[](stakedTokensLength);

    // Copy set values to array
    for (uint256 i = 0; i < stakedTokensLength; i++) {
      tokenIds[i] = stakedTokens[_owner].at(i);
    }

    // Return array result
    return tokenIds;
  }

  /**
   * @notice Calculates the rewards that would be earned by
   *         the user for each an NFT if he was to unstake it at
   *         the current block
   *
   * @param _tokenId token ID of NFT rewards are to be calculated for
   * @return the amount of rewards for the input staken NFT
   */
  function currentRewardsOf(uint256 _tokenId) public view returns (uint256) {
    // Verify NFT is staked
    require(stakedAt[_tokenId] != 0, "not staked");

    // Get current token ID staking time by calculating the
    // delta between the current block time(`block.timestamp`)
    // and the time the token was initially staked(`stakedAt[tokenId]`)
    uint256 stakingTime = block.timestamp - stakedAt[_tokenId];

    // `stakingTime` is the staking time in seconds
    // Calculate the staking time in days by:
    //   * dividing by 60 (seconds in a minute)
    //   * dividing by 60 (minutes in an hour)
    //   * dividing by 24 (hours in a day)
    // This will yield the (rounded down) staking
    // time in days
    uint256 stakingDays = stakingTime / 60 / 60 / 24;

    // Calculate reward for token by multiplying
    // rounded down number of staked days by daily
    // rewards variable
    uint256 reward = stakingDays * dailyRewards;

    // If the NFT is boosted
    if (isBoostedToken(_tokenId)) {
      // Multiply the reward
      reward *= dailyRewardBoostMultiplier;
    }

    // Return reward
    return reward;
  }

  /**
   * @notice Stake NFTs to start earning ERC-20
   *         token rewards
   *
   * The ERC-20 token rewards will be paid out
   * when the NFTs are unstaken
   *
   * @dev Sender must first approve this contract
   *      to transfer NFTs on his behalf and NFT
   *      ownership is transferred to this contract
   *      for the duration of the staking
   *
   * @param _tokenIds token IDs of NFTs to be staken
   */
  function stake(uint256[] memory _tokenIds) public {
    // Ensure at least one token ID was sent
    require(_tokenIds.length > 0, "no token IDs sent");

    // Enumerate sent token IDs
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Get token ID
      uint256 tokenId = _tokenIds[i];

      // Store NFT owner
      ownerOf[tokenId] = msg.sender;

      // Add NFT to owner staked tokens
      stakedTokens[msg.sender].add(tokenId);

      // Store staking time as block timestamp the
      // the transaction was confirmed in
      stakedAt[tokenId] = block.timestamp;

      // Transfer token to staking contract
      // Will fail if the user does not own the
      // token or has not approved the staking
      // contract for transferring tokens on his
      // behalf
      erc721.safeTransferFrom(msg.sender, address(this), tokenId, "");

      // Emit event
      emit Staked(msg.sender, tokenId, stakedAt[tokenId]);
    }
  }

  /**
   * @notice Unstake NFTs to receive ERC-20 token rewards
   *
   * @dev Sender must have first staken the NFTs
   *
   * @param _tokenIds token IDs of NFTs to be unstaken
   */
  function unstake(uint256[] memory _tokenIds) public {
    // Ensure at least one token ID was sent
    require(_tokenIds.length > 0, "no token IDs sent");

    // Create a variable to store the total rewards for all
    // NFTs sent
    uint256 totalRewards = 0;

    // Enumerate sent token IDs
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      // Get token ID
      uint256 tokenId = _tokenIds[i];

      // Verify sender is token ID owner
      // Will fail if token is not staked (owner is 0x0)
      require(ownerOf[tokenId] == msg.sender, "not token owner");

      // Calculate rewards for token ID. Will revert
      // if the token is not staken
      uint256 rewards = currentRewardsOf(tokenId);

      // Increase amount of total rewards
      // for all tokens sent
      totalRewards += rewards;

      // Emit event
      emit Unstaked(msg.sender, tokenId, block.timestamp, stakedAt[tokenId], rewards);

      // Reset `ownerOf` and `stakedAt`
      // for token
      ownerOf[tokenId] = address(0);
      stakedAt[tokenId] = 0;

      // Remove NFT from owner staked tokens
      stakedTokens[msg.sender].remove(tokenId);

      // Transfer NFT back to user
      erc721.transferFrom(address(this), msg.sender, tokenId);
    }

    // Mint total rewards for all sent NFTs
    // to user
    erc20.mint(msg.sender, totalRewards);
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
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice ERC20-compliant interface with added
 *         function for minting new tokens to addresses
 *
 * See {IERC20}
 */
interface IMintableERC20 is IERC20 {
  /**
   * @dev Allows issuing new tokens to an address
   *
   * @dev Should have restricted access
   */
  function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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