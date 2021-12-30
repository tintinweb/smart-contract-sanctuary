//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct ERC1155NFT {
  address nftAddress;
  uint8 nftID;
  uint256 reward;
  uint lastBlock;
}

contract ARTStaking is IERC1155Receiver {

  // Block when rewards will be ended
  uint public immutable rewardEndBlock;

  // Block when rewards will be started
  uint public rewardStartBlock;

  // Holds all NFTs
  ERC1155NFT[] private allNFTs;

  //keep record of the owner of NFT
  mapping(address => mapping(address => ERC1155NFT[])) private nftBank;

  // Total Rewards to be distributed
  uint256 public totalRewards;

  // duration of staking period
  uint256 public totalBlocks;

  // Reward Token Address, this contract must have reward tokens in it
  address public immutable rewardToken;

  uint256 public rewardsPerBlock;

  // rank => weight
  mapping(uint256 => uint256) public weightOfRank;
  // rank total Usage
  mapping(uint256 => uint256) public rankUsage;

  uint256 public totalUsageWithWeight = 0;

  address public immutable owner;

  using EnumerableSet for EnumerableSet.AddressSet;

  // Address of allowed NFT's
  EnumerableSet.AddressSet private allowedNfts;

  constructor(
    uint _rewardStartBlock,
    uint256 _totalRewards,
    uint _totalBlocks,
    address _rewardToken,
    address[] memory _allowedNfts
  ) {
    rewardStartBlock = _rewardStartBlock;
    totalRewards = _totalRewards;
    totalBlocks = _totalBlocks;
    rewardToken = _rewardToken;
    rewardsPerBlock = totalRewards / totalBlocks;
    rewardEndBlock = rewardStartBlock + _totalBlocks;
    owner = msg.sender;

    weightOfRank[0] = 220;
    weightOfRank[1] = 143;
    weightOfRank[2] = 143;
    weightOfRank[3] = 58;
    weightOfRank[4] = 58;
    weightOfRank[5] = 58;
    weightOfRank[6] = 9;
    weightOfRank[7] = 9;
    weightOfRank[8] = 9;
    weightOfRank[9] = 9;

    for (uint256 i = 0; i < _allowedNfts.length; i++) {
      allowedNfts.add(_allowedNfts[i]);
    }
  }

  // stake NFT,
  function stake(uint8 _nftID, address _nftAddress) external {

    require(allowedNfts.contains(_nftAddress), "only ART's are allowed");
    // require(_nftID <= 9, "upto 9 rank is allowed");

    //check if it is within the staking period
    require(rewardStartBlock <= block.number,"reward period not started yet");
    //check if it is within the staking period
    require(block.number < rewardEndBlock, "reward period has ended");
    
    //check if the owner has approved the contract to safe transfer the NFT
    require(IERC1155(_nftAddress).isApprovedForAll(msg.sender, address(this)), "approve missing");

    ERC1155NFT memory nft = ERC1155NFT({
      nftAddress: _nftAddress,
      nftID: _nftID,
      reward: 0,
      lastBlock: Math.min(block.number, rewardEndBlock)
    });

    nftBank[msg.sender][_nftAddress].push(nft);
    allNFTs.push(nft);
    // update rank
    increaseRank(_nftID);
    IERC1155(_nftAddress).safeTransferFrom(
      msg.sender,
      address(this),
      _nftID,
      1,
      "0x0"
    );
  }

  function unstake(uint8 _nftID, address _nftAddress) external {

    require(
      checkIFExists(nftBank[msg.sender][_nftAddress], _nftID),
      "token not deposited"
    );

    decreaseRank(_nftID);
    uint256 reward = _getAccumulatedrewards(_nftAddress, _nftID);

    deleteNFTFromBank(_nftAddress, msg.sender, _nftID);
    removeNFTFromArray(_nftAddress, _nftID);

    IERC20(rewardToken).transfer(msg.sender, reward);

    IERC1155(_nftAddress).safeTransferFrom(
      address(this),
      msg.sender,
      _nftID,
      1,
      "0x0"
    );    
  }

  function viewReward(uint8 _nftID, address _nftAddress)
    external
    view
    returns (uint256)
  {
    uint256 calculatedReward = 0;
    for (uint256 i = 0; i < allNFTs.length; i++) {
      if (allNFTs[i].nftID == _nftID && allNFTs[i].nftAddress == _nftAddress) {
        uint256 rewardPerShare = 0;

        if (totalUsageWithWeight > 0) {
          rewardPerShare = (rewardsPerBlock / totalUsageWithWeight);
        } else {
          rewardPerShare = rewardsPerBlock;
        }

        calculatedReward =
          allNFTs[i].reward +
          (weightOfRank[allNFTs[i].nftID] *
            rewardPerShare *
            (Math.min(block.number, rewardEndBlock) - allNFTs[i].lastBlock));
      }
    }
    return calculatedReward;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override
    returns (bool)
  {
    return
      interfaceId == type(IERC1155Receiver).interfaceId ||
      interfaceId == type(IERC20).interfaceId;
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes memory
  ) public pure override returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] memory,
    uint256[] memory,
    bytes memory
  ) public pure override returns (bytes4) {
    return
      bytes4(
        keccak256(
          "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
        )
      );
  }

  function checkIFExists(ERC1155NFT[] memory _nfts, uint8 _nftID)
    internal
    pure
    returns (bool)
  {
    for (uint8 i = 0; i < _nfts.length; i++) {
      if (_nfts[i].nftID == _nftID) {
        return true;
      }
    }
    return false;
  }

  function viewStakedNFTIds(address _owner, address _nftAddress)
    public
    view
    returns (uint8[] memory)
  {
    uint8[] memory ids = new uint8[](nftBank[_owner][_nftAddress].length);
    for (uint8 i = 0; i < nftBank[_owner][_nftAddress].length; i++) {
      ids[i] = (nftBank[_owner][_nftAddress][i].nftID);
    }
    return ids;
  }

  function viewStakedNFTs(address _owner)
    public
    view
    returns (address[] memory)
  {
    address[] memory nftTypes = new address[](15);
    for (uint8 i = 0; i < allowedNfts.length(); i++) {
      if (nftBank[_owner][allowedNfts.at(i)].length > 0) {
        nftTypes[i] = allowedNfts.at(i);
      }
    }
    return nftTypes;
  }

  function viewAllowedNFTs() public view returns (address[] memory) {
    address[] memory nftTypes = new address[](15);
    for (uint8 i = 0; i < allowedNfts.length(); i++) {
      nftTypes[i] = allowedNfts.at(i);
    }
    return nftTypes;
  }

  function deleteNFTFromBank(
    address _nftAddress,
    address _owner,
    uint8 _nftID
  ) internal {
 
    for (uint8 i = 0; i < nftBank[_owner][_nftAddress].length; i++) {
      if (nftBank[_owner][_nftAddress][i].nftID == _nftID) {
         nftBank[_owner][_nftAddress][i] = nftBank[_owner][
          _nftAddress
        ][nftBank[_owner][_nftAddress].length - 1];
        nftBank[_owner][_nftAddress].pop();
      }
    }
  }

  function calculateRewards() internal {
    for (uint8 i = 0; i < allNFTs.length; i++) {
      uint256 rewardPerShare = 0;

      if (totalUsageWithWeight > 0) {
        rewardPerShare = (rewardsPerBlock / totalUsageWithWeight);
      } else {
        rewardPerShare = rewardsPerBlock;
      }

      // reward = (weightofrank * rewardPerShare) * totalBlocks
      
      uint smallerBlock = Math.min(block.number, rewardEndBlock);
      
      allNFTs[i].reward += (weightOfRank[allNFTs[i].nftID] *
        rewardPerShare *
        (smallerBlock - allNFTs[i].lastBlock));

      allNFTs[i].lastBlock = smallerBlock;
    }
  }

  function _getAccumulatedrewards(address _nftAddress, uint8 _nftID)
    internal
    view
    returns (uint256)
  {
    uint256 reward = 0;

    for (uint8 i = 0; i < allNFTs.length; i++) {
      if (allNFTs[i].nftID == _nftID && allNFTs[i].nftAddress == _nftAddress) {
        reward = allNFTs[i].reward;
        //allNFTs[i].reward = 0;
      }
    }

    return reward;
  }

  function increaseRank(uint8 _rank) internal {
    calculateRewards();
    
    //increase this NFT's rank counter
    rankUsage[_rank] = rankUsage[_rank] + 1;
    
    //totalUsage = number of that rank used
    totalUsageWithWeight = totalUsageWithWeight + (1 * weightOfRank[_rank]);
  }

  function decreaseRank(uint8 _rank) internal {
    calculateRewards();
    rankUsage[_rank] = rankUsage[_rank] - 1;
    totalUsageWithWeight = totalUsageWithWeight - (1 * weightOfRank[_rank]);
  }

  function expectedRewardTillEnd(uint8 _nftID)
    external
    view
    returns (uint256)
  {
    uint256 rewardPerShare = 0;
    uint256 weight = 0;

    
    if (rankUsage[_nftID]<=0){
      weight = totalUsageWithWeight + weightOfRank[_nftID];
    } else{
      weight = weightOfRank[_nftID];
    }

    if (weight > 0) {
      rewardPerShare = (rewardsPerBlock / weight);
    } else {
      rewardPerShare = rewardsPerBlock;
    }
    return
      weightOfRank[_nftID] * rewardPerShare * (rewardEndBlock - block.number);
  }

  function addNFTtoArray(ERC1155NFT memory _nft) internal {
    allNFTs.push(_nft);
  }

  function removeNFTFromArray(address _nftAddress, uint8 _nftID) internal {
    for (uint8 i = 0; i < allNFTs.length; i++) {
      if (allNFTs[i].nftID == _nftID && allNFTs[i].nftAddress == _nftAddress) {
        allNFTs[i] = allNFTs[allNFTs.length - 1];
        allNFTs.pop();
      }
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only owner can do this action");
    _;
  }

  function withdrawToken(address _tokenContract, uint8 _amount)
    external
    onlyOwner
  {
    require(_tokenContract != rewardToken, "rewards token not allowed");
    IERC20 tokenContract = IERC20(_tokenContract);
    tokenContract.transfer(msg.sender, _amount);
  }

  function withdrawEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function burnRewardToken() external {
    require(rewardEndBlock < block.number, "reward period is still on");
    require(allNFTs.length == 0, "NFT's are still staked");
    IERC20 tokenContract = IERC20(rewardToken);
    tokenContract.transfer(
      address(0x000000000000000000000000000000000000dEaD),
      tokenContract.balanceOf(address(this))
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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