// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./MerkleCore.sol";
import "./interfaces/ISuper1155.sol";

/**
  @title A merkle tree based distributor.
  @author Qazawat Zirak

  This contract replaces the traditional whitelists for redeeming tokens
  by using a merkle tree, storing the root on-chain instead of all the 
  addressses. The merkle tree alongside the whitelist is kept off-chain 
  for lookups and creating proofs to validate a claim.
  This code is inspired by and modified from incredible work of RicMoo.
  https://github.com/ricmoo/ethers-airdrop/blob/master/AirDropToken.sol

  October 12th, 2021.
*/
contract SuperMerkleDistributor is MerkleCore {

  /// The public identifier for the right to set a root for a round.
  bytes32 public constant SET_DISTRIBUTION_ROUND = keccak256("SET_DISTRIBUTION_ROUND");

  /** 
    An enum representing the type of tokens to give out.
    @param Fungible non unique tokens.
    @param Nonfungible unique tokens.
    @param Semifungible semi unique tokens.
  */
  enum AssetType {
    Fungible,
    Nonfungible,
    Semifungible
  }

  /** 
    An enum representing the type of distributionlist.
    @param Distributive initial distribution of brand new collection.
    @param Airdrop late distribution of a collection, had its first purchase.
  */
  enum listType {
    Distributive, 
    Airdrop
  }

  /** 
    A struct containing information about the Distributionlist.
    @param merkleRoot the proof stored on chain to verify against.
    @param startTime the start time of validity for the Distributionlist.
    @param endTime the end time of validity for the Distributionlist.
    @param round the number times the Distributionlist has been set.
    @param token the token address to distribute tokens from.
    @param assetType the asset type of distribution.
    @param listType flag that specifies the type of distributionlist.
    @param redeemed 'round' to mod of 'index' from off-chain list
      to 'value' representing already redeemed addresses.
  */ 
  struct DistributionList {
    bytes32 merkleRoot;
    uint256 startTime;
    uint256 endTime;
    uint256 round;
    address token;
    AssetType assetType;
    listType listType;
    mapping(uint256 => mapping(uint256 => uint256)) redeemed;
  }

  /// MerkleRootId to 'DistributionList'
  mapping (uint256 => DistributionList) public distributionRoots;

  /// Event emitted when a redemption is successful.
  event Redeemed(uint256 indexed index, address indexed account, uint256 indexed amount);

  /** 
    Set a new round for the Distributionlist.
    @param _groupId the distributionlist id containg the merkleRoot.
    @param _merkleRoot the new merkleRoot for the round.
    @param _startTime the start time of the new round.
    @param _endTime the end time of the new round.
    @param _token the address of token to be disbursed.
    @param _assetType the type of token to be disbursed.
    @param _listType the type of distributionlist. Distributive/Airdrop.
  */
  function setDistributionRound(uint256 _groupId, bytes32 _merkleRoot, 
  uint256 _startTime, uint256 _endTime, address _token, 
  AssetType _assetType, listType _listType) public 
  hasValidPermit(UNIVERSAL, SET_DISTRIBUTION_ROUND) {

    distributionRoots[_groupId].merkleRoot = _merkleRoot;
    distributionRoots[_groupId].startTime = _startTime;
    distributionRoots[_groupId].endTime = _endTime;
    distributionRoots[_groupId].round += 1;
    distributionRoots[_groupId].token = _token;
    distributionRoots[_groupId].assetType = _assetType;
    distributionRoots[_groupId].listType = _listType;
  }
  
  /** 
    A function to check if the caller has already redeemed a claim.
    @param _groupId the id of the distributionlist having the merkleRoot.
    @param _index the index of the Node in the list off-chain.
    @return whether or not the address at that index has already redeemed.
  */
  function redeemed(uint256 _groupId, uint256 _index) public view returns (bool) {

      uint256 redeemedBlock = distributionRoots[_groupId].redeemed[distributionRoots[_groupId].round][_index / 256];
      uint256 redeemedMask = (uint256(1) << uint256(_index % 256));
      return ((redeemedBlock & redeemedMask) != 0);
  }

  /** 
    A function that is called when a caller intends to redeem tokens
    verified against a merkleRoot.
    @param _groupId the id of the distributionlist having the merkleRoot.
    @param _index index of the hashed node from off-chain list.
    @param _account account at that '_index'.
    @param _tokenId the id of the token to be claimed.
    @param _amount the amount of the tokens to be claimed.
    @param _merkleProof the list of related hashes from merkle tree.

    This function accepts redemption of Fungible, NonFungible and Semi
    fungible tokens.
  */
  function redeem(uint256 _groupId, uint256 _index, address _account, 
  uint256 _tokenId, uint256 _amount, bytes32[] calldata _merkleProof) 
  external {

    require(!redeemed(_groupId, _index), 
      "Already Redeemed.");

    // Mark as redeemed, for that round, for that '_account'
    distributionRoots[_groupId].redeemed[distributionRoots[_groupId].round][_index / 256] = 
      distributionRoots[_groupId].redeemed[distributionRoots[_groupId].round][_index / 256] | (uint256(1) << uint256(_index % 256));

    uint256 shiftedItemGroupId = _groupId << 128;
    uint256 tokenId;
    uint256 amount;
    bytes32 node;

    // Fungible Distribution and Airdrop both use tokenId = 1
    if (distributionRoots[_groupId].assetType == AssetType.Fungible) {
      tokenId = shiftedItemGroupId + 1;
      amount = _amount;
      node = keccak256(abi.encodePacked(_index, _account, _amount));

    // Non fungible Distribution uses '_index' as tokenId
    } else if (distributionRoots[_groupId].assetType == AssetType.Nonfungible) { 
      if (distributionRoots[_groupId].listType == listType.Distributive) {
        tokenId = shiftedItemGroupId + _index;
        node = keccak256(abi.encodePacked(_index, _account));

      // Non fungible Airdrop uses explicit tokenId
      } else {
        tokenId = _tokenId;
        node = keccak256(abi.encodePacked(_index, _account, _tokenId));
      }  
      amount = 1;

    // Semi fungible Distribution and Airdrop both use explicit tokenId
    } else {
      tokenId = _tokenId;
      amount = _amount;
      node = keccak256(abi.encodePacked(_index, _account, _tokenId, _amount));
    }

    // Notice that index is only included in the hash for the leaf nodes
    require(getRootHash(_index, node, _merkleProof) == 
      distributionRoots[_groupId].merkleRoot, 
      "Invalid Proof.");
  
    ISuper1155(distributionRoots[_groupId].token).mintBatch(_account, 
      _asSingletonArray(tokenId), _asSingletonArray(amount), "");

    emit Redeemed(_index, _account, amount);
  }
  
  /**
    This private helper function converts a number into a single-element array.
    @param _element The element to convert to an array.
    @return The array containing the single `_element`.
  */
  function _asSingletonArray(uint256 _element) private pure returns (uint256[] memory) {

    uint256[] memory array = new uint256[](1);
    array[0] = _element;
    return array;
  }  
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Sweepable.sol";

/**
  @title A merkle tree root finder.
  @author Qazawat Zirak

  This contract is meant for calculating a root hash from any given 
  valid index, valid node at that index, and valid merkle proofs.

  October 12th, 2021. 
*/
abstract contract MerkleCore is Sweepable {

  /**
    Calculate a root hash from given parameters.
    @param _index index of the hashed node from the list.
    @param _node the hashed node at that index.
    @param _merkleProof array of one required merkle hash per level.
    @return a root hash from given parameters.
   */
  function getRootHash(uint256 _index, bytes32 _node, 
  bytes32[] calldata _merkleProof) internal pure returns(bytes32) {

    uint256 path = _index;
    for (uint256 i = 0; i < _merkleProof.length; i++) {
      if ((path & 0x01) == 1) {
          _node = keccak256(abi.encodePacked(_merkleProof[i], _node));
      } else {
          _node = keccak256(abi.encodePacked(_node, _merkleProof[i]));
      }
      path /= 2;
    }
    return _node;
  }
}

// SPDX-License-Identifier: GPL-3.0
import "../libraries/DFStorage.sol";
pragma solidity ^0.8.8;

/**
  @title An interface for the `Super1155` ERC-1155 item collection contract.
  @author 0xthrpw
  @author Tim Clancy

  August 12th, 2021.
*/
interface ISuper1155 {

  /// The public identifier for the right to set this contract's metadata URI.
  function SET_URI () external view returns (bytes32);

  /// The public identifier for the right to set this contract's proxy registry.
  function SET_PROXY_REGISTRY () external view returns (bytes32);

  /// The public identifier for the right to configure item groups.
  function CONFIGURE_GROUP () external view returns (bytes32);

  /// The public identifier for the right to mint items.
  function MINT () external view returns (bytes32);

  /// The public identifier for the right to burn items.
  function BURN () external view returns (bytes32);

  /// The public identifier for the right to set item metadata.
  function SET_METADATA () external view returns (bytes32);

  /// The public identifier for the right to lock the metadata URI.
  function LOCK_URI () external view returns (bytes32);

  /// The public identifier for the right to lock an item's metadata.
  function LOCK_ITEM_URI () external view returns (bytes32);

  /// The public identifier for the right to disable item creation.
  function LOCK_CREATION () external view returns (bytes32);

  /// The public name of this contract.
  function name () external view returns (string memory);

  /**
    The ERC-1155 URI for tracking item metadata, supporting {id} substitution.
    For example: https://token-cdn-domain/{id}.json. See the ERC-1155 spec for
    more details: https://eips.ethereum.org/EIPS/eip-1155#metadata.
  */
  function metadataUri () external view returns (string memory);

  /// A proxy registry address for supporting automatic delegated approval.
  function proxyRegistryAddress () external view returns (address);

  /// A mapping from each group ID to per-address balances.
  function groupBalances (uint256, address) external view returns (uint256);

  /// A mapping from each address to a collection-wide balance.
  function totalBalances (address) external view returns (uint256);

  /// A mapping of data for each item group.
  // function itemGroups (uint256) external view returns (ItemGroup memory);
  /* function itemGroups (uint256) external view returns (bool initialized, string memory _name, uint8 supplyType, uint256 supplyData, uint8 itemType, uint256 itemData, uint8 burnType, uint256 burnData, uint256 _circulatingSupply, uint256 _mintCount, uint256 _burnCount); */

  /// A mapping of circulating supplies for each individual token.
  function circulatingSupply (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been minted.
  function mintCount (uint256) external view returns (uint256);

  /// A mapping of the number of times each individual token has been burnt.
  function burnCount (uint256) external view returns (uint256);

  /**
    A mapping of token ID to a boolean representing whether the item's metadata
    has been explicitly frozen via a call to `lockURI(string calldata _uri,
    uint256 _id)`. Do note that it is possible for an item's mapping here to be
    false while still having frozen metadata if the item collection as a whole
    has had its `uriLocked` value set to true.
  */
  function metadataFrozen (uint256) external view returns (bool);

  /**
    A public mapping of optional on-chain metadata for each token ID. A token's
    on-chain metadata is unable to be changed if the item's metadata URI has
    been permanently fixed or if the collection's metadata URI as a whole has
    been frozen.
  */
  function metadata (uint256) external view returns (string memory);

  /// Whether or not the metadata URI has been locked to future changes.
  function uriLocked () external view returns (bool);

  /// Whether or not the item collection has been locked to all further minting.
  function locked () external view returns (bool);

  /**
    Return a version number for this contract's interface.
  */
  function version () external view returns (uint256);

  /**
    Return the item collection's metadata URI. This implementation returns the
    same URI for all tokens within the collection and relies on client-side
    ID substitution per https://eips.ethereum.org/EIPS/eip-1155#metadata. Per
    said specification, clients calling this function must replace the {id}
    substring with the actual token ID in hex, not prefixed by 0x, and padded
    to 64 characters in length.

    @return The metadata URI string of the item with ID `_itemId`.
  */
  function uri (uint256) external view returns (string memory);

  /**
    Allow the item collection owner or an approved manager to update the
    metadata URI of this collection. This implementation relies on a single URI
    for all items within the collection, and as such does not emit the standard
    URI event. Instead, we emit our own event to reflect changes in the URI.

    @param _uri The new URI to update to.
  */
  function setURI (string memory _uri) external;

  /**
    Allow the item collection owner or an approved manager to update the proxy
    registry address handling delegated approval.

    @param _proxyRegistryAddress The address of the new proxy registry to
      update to.
  */
  function setProxyRegistry (address _proxyRegistryAddress) external;

  /**
    Retrieve the balance of a particular token `_id` for a particular address
    `_owner`.

    @param _owner The owner to check for this token balance.
    @param _id The ID of the token to check for a balance.
    @return The amount of token `_id` owned by `_owner`.
  */
  function balanceOf (address _owner, uint256 _id) external view returns (uint256);

  /**
    Retrieve in a single call the balances of some mulitple particular token
    `_ids` held by corresponding `_owners`.

    @param _owners The owners to check for token balances.
    @param _ids The IDs of tokens to check for balances.
    @return the amount of each token owned by each owner.
  */
  function balanceOfBatch (address[] memory _owners, uint256[] memory _ids) external view returns (uint256[] memory);

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`. This approval check features an override to explicitly
    whitelist any addresses delegated in the proxy registry.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.
    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll (address _owner, address _operator) external view returns (bool);

  /**
    Enable or disable approval for a third party `_operator` address to manage
    (transfer or burn) all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll (address _operator, bool _approved) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _id The specific token ID to transfer.
    @param _amount The amount of the specific `_id` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeTransferFrom (address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data) external;

  /**
    Transfer on behalf of a caller or one of their authorized token managers
    items from one address to another.

    @param _from The address to transfer tokens from.
    @param _to The address to transfer tokens to.
    @param _ids The specific token IDs to transfer.
    @param _amounts The amounts of the specific `_ids` to transfer.
    @param _data Additional call data to send with this transfer.
  */
  function safeBatchTransferFrom (address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    Create a new NFT item group or configure an existing one. NFTs within a
    group share a group ID in the upper 128-bits of their full item ID.
    Within a group NFTs can be distinguished for the purposes of serializing
    issue numbers.

    @param _groupId The ID of the item group to create or configure.
    @param _data The `ItemGroup` data input.
  */
  function configureGroup (uint256 _groupId, DFStorage.ItemGroupInput calldata _data) external;

  /**
    Mint a batch of tokens into existence and send them to the `_recipient`
    address. In order to mint an item, its item group must first have been
    created. Minting an item must obey both the fungibility and size cap of its
    group.

    @param _recipient The address to receive all NFTs within the newly-minted
      group.
    @param _ids The item IDs for the new items to create.
    @param _amounts The amount of each corresponding item ID to create.
    @param _data Any associated data to use on items minted in this transaction.
  */
  function mintBatch (address _recipient, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external;

  /**
    This function allows an address to destroy some of its items.

    @param _burner The address whose item is burning.
    @param _id The item ID to burn.
    @param _amount The amount of the corresponding item ID to burn.
  */
  function burn (address _burner, uint256 _id, uint256 _amount) external;

  /**
    This function allows an address to destroy multiple different items in a
    single call.

    @param _burner The address whose items are burning.
    @param _ids The item IDs to burn.
    @param _amounts The amounts of the corresponding item IDs to burn.
  */
  function burnBatch (address _burner, uint256[] memory _ids, uint256[] memory _amounts) external;

  /**
    Set the on-chain metadata attached to a specific token ID so long as the
    collection as a whole or the token specifically has not had metadata
    editing frozen.

    @param _id The ID of the token to set the `_metadata` for.
    @param _metadata The metadata string to store on-chain.
  */
  function setMetadata (uint256 _id, string memory _metadata) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on the entire collection to future changes.

    @param _uri The value of the URI to lock for `_id`.
  */
  function lockURI(string calldata _uri) external;

  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on an item to future changes.

    @param _uri The value of the URI to lock for `_id`.
    @param _id The token ID to lock a metadata URI value into.
  */
  function lockURI(string calldata _uri, uint256 _id) external;


  /**
    Allow the item collection owner or an associated manager to forever lock the
    metadata URI on a group of items to future changes.

    @param _uri The value of the URI to lock for `groupId`.
    @param groupId The group ID to lock a metadata URI value into.
  */
  function lockGroupURI(string calldata _uri, uint256 groupId) external;

  /**
    Allow the item collection owner or an associated manager to forever lock
    this contract to further item minting.
  */
  function lock() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./access/PermitControl.sol";

/**
  @title A base contract which supports an administrative sweep function wherein
    authorized callers may transfer ERC-20 tokens out of this contract.
  @author Tim Clancy
  @author Qazawat Zirak

  This is a base contract designed with the intent to support rescuing ERC-20
  tokens which users might have wrongly sent to a contract.
*/
contract Sweepable is PermitControl {
  using SafeERC20 for IERC20;

  /// The public identifier for the right to sweep tokens.
  bytes32 public constant SWEEP = keccak256("SWEEP");

  /// The public identifier for the right to lock token sweeps.
  bytes32 public constant LOCK_SWEEP = keccak256("LOCK_SWEEP");

  /// A flag determining whether or not the `sweep` function may be used.
  bool public sweepLocked;

  /**
    An event to track a token sweep event.

    @param sweeper The calling address which triggered the sweeep.
    @param token The specific ERC-20 token being swept.
    @param amount The amount of the ERC-20 token being swept.
    @param recipient The recipient of the swept tokens.
  */
  event TokenSweep(address indexed sweeper, IERC20 indexed token,
    uint256 amount, address indexed recipient);

  /**
    An event to track future use of the `sweep` function being locked.

    @param locker The calling address which locked down sweeping.
  */
  event SweepLocked(address indexed locker);

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual override pure returns (uint256) {
    return 1;
  }

  /**
    Allow the owner or an approved manager to sweep all of a particular ERC-20
    token from the contract and send it to another address. This function exists
    to allow the shop owner to recover tokens that are otherwise sent directly
    to this contract and get stuck. Provided that sweeping is not locked, this
    is a useful tool to help buyers recover otherwise-lost funds.

    @param _token The token to sweep the balance from.
    @param _amount The amount of token to sweep.
    @param _address The address to send the swept tokens to.
  */
  function sweep(IERC20 _token, uint256 _amount, address _address) external
    hasValidPermit(UNIVERSAL, SWEEP) {
    require(!sweepLocked,
      "Sweep: the sweep function is locked");
    _token.safeTransfer(_address, _amount);
    emit TokenSweep(_msgSender(), _token, _amount, _address);
  }

  /**
    Allow the shop owner or an approved manager to lock the contract against any
    future token sweeps.
  */
  function lockSweep() external hasValidPermit(UNIVERSAL, LOCK_SWEEP) {
    sweepLocked = true;
    emit SweepLocked(_msgSender());
  }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
  bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /**
    A mapping of per-address permissions to the circumstances, represented as
    an additional layer of generic bytes32 data, under which the addresses have
    various permits. A permit in this sense is represented by a per-circumstance
    mapping which couples some right, represented as a generic bytes32, to an
    expiration time wherein the right may no longer be exercised. An expiration
    time of 0 indicates that there is in fact no permit for the specified
    address to exercise the specified right under the specified circumstance.

    @dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
    max-integer circumstance. Perpetual rights may be given an expiry time of
    max-integer.
  */
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
    address indexed manager,
    bytes32 indexed managedRight,
    bytes32 indexed managerRight
  );

  /**
    A modifier which allows only the super-administrative owner or addresses
    with a specified valid right to perform a call.

    @param _circumstance The circumstance under which to check for the validity
      of the specified `right`.
    @param _right The right to validate for the calling address. It must be
      non-expired and exist within the specified `_circumstance`.
  */
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
  }

  /**
    Determine whether or not an address has some rights under the given
    circumstance, and if they do have the right, until when.

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return The timestamp in seconds when the `_right` expires. If the timestamp
      is zero, we can assume that the user never had the right.
  */
  function hasRightUntil(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (uint256) {
    return permissions[_address][_circumstance][_right];
  }

   /**
    Determine whether or not an address has some rights under the given
    circumstance,

    @param _address The address to check for the specified `_right`.
    @param _circumstance The circumstance to check the specified `_right` for.
    @param _right The right to check for validity.
    @return true or false, whether user has rights and time is valid.
  */
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
  }

  /**
    Set the permit to a specific address under some circumstances. A permit may
    only be set by the super-administrative contract owner or an address holding
    some delegated management permit.

    @param _address The address to assign the specified `_right` to.
    @param _circumstance The circumstance in which the `_right` is valid.
    @param _right The specific right to assign.
    @param _expirationTime The time when the `_right` expires for the provided
      `_circumstance`.
  */
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

pragma solidity 0.8.8;

library DFStorage {
    /**
    @notice This enumeration type specifies the different access rules that may be
    applied to pools in this shop. Access to a pool may be restricted based on
    the buyer's holdings of either tokens or items.

    @param Public This specifies a pool which requires no special asset holdings
      to buy from.
    @param TokenRequired This specifies a pool which requires the buyer to hold
      some amount of ERC-20 tokens to buy from.
    @param ItemRequired This specifies a pool which requires the buyer to hold
      some amount of an ERC-1155 item to buy from.
    @param PointRequired This specifies a pool which requires the buyer to hold
      some amount of points in a Staker to buy from.
  */
    enum AccessType {
        Public,
        TokenRequired,
        ItemRequired,
        PointRequired,
        ItemRequired721
    }

    /**
    @notice This enumeration type specifies the different assets that may be used to
    complete purchases from this mint shop.

    @param Point This specifies that the asset being used to complete
      this purchase is non-transferrable points from a `Staker` contract.
    @param Ether This specifies that the asset being used to complete
      this purchase is native Ether currency.
    @param Token This specifies that the asset being used to complete
      this purchase is an ERC-20 token.
  */
    enum AssetType {
        Point,
        Ether,
        Token
    }

    /**
    @notice This struct tracks information about a single asset with the associated
    price that an item is being sold in the shop for. It also includes an
    `asset` field which is used to convey optional additional data about the
    asset being used to purchase with.

    @param assetType The `AssetType` type of the asset being used to buy.
    @param asset Some more specific information about the asset to charge in.
     If the `assetType` is Point, we use this address to find the specific
     Staker whose points are used as the currency.
     If the `assetType` is Ether, we ignore this field.
     If the `assetType` is Token, we use this address to find the
     ERC-20 token that we should be specifically charging with.
    @param price The amount of the specified `assetType` and `asset` to charge.
  */
    struct Price {
        AssetType assetType;
        address asset;
        uint256 price;
    }
  /**
    This enumeration lists the various supply types that each item group may
    use. In general, the administrator of this collection or those permissioned
    to do so may move from a more-permissive supply type to a less-permissive.
    For example: an uncapped or flexible supply type may be converted to a
    capped supply type. A capped supply type may not be uncapped later, however.

    @param Capped There exists a fixed cap on the size of the item group. The
      cap is set by `supplyData`.
    @param Uncapped There is no cap on the size of the item group. The value of
      `supplyData` cannot be set below the current circulating supply but is
      otherwise ignored.
    @param Flexible There is a cap which can be raised or lowered (down to
      circulating supply) freely. The value of `supplyData` cannot be set below
      the current circulating supply and determines the cap.
  */
  enum SupplyType {
    Capped,
    Uncapped,
    Flexible
  }

  /**
    This enumeration lists the various item types that each item group may use.
    In general, these are static once chosen.

    @param Nonfungible The item group is truly nonfungible where each ID may be
      used only once. The value of `itemData` is ignored.
    @param Fungible The item group is truly fungible and collapses into a single
      ID. The value of `itemData` is ignored.
    @param Semifungible The item group may be broken up across multiple
      repeating token IDs. The value of `itemData` is the cap of any single
      token ID in the item group.
  */
  enum ItemType {
    Nonfungible,
    Fungible,
    Semifungible
  }

  /**
    This enumeration lists the various burn types that each item group may use.
    These are static once chosen.

    @param None The items in this group may not be burnt. The value of
      `burnData` is ignored.
    @param Burnable The items in this group may be burnt. The value of
      `burnData` is the maximum that may be burnt.
    @param Replenishable The items in this group, once burnt, may be reminted by
      the owner. The value of `burnData` is ignored.
  */
  enum BurnType {
    None,
    Burnable,
    Replenishable
  }

  /**
    This struct is a source of mapping-free input to the `configureGroup`
    function. It defines the settings for a particular item group.
   
    @param supplyData An optional integer used by some `supplyType` values.
    @param itemData An optional integer used by some `itemType` values.
    @param burnData An optional integer used by some `burnType` values.
    @param name A name for the item group.
    @param supplyType The supply type for this group of items.
    @param itemType The type of item represented by this item group.
    @param burnType The type of burning permitted by this item group.
    
  */
  struct ItemGroupInput {
    uint256 supplyData;
    uint256 itemData;
    uint256 burnData;
    SupplyType supplyType;
    ItemType itemType;
    BurnType burnType;
    string name;
  }


    /**
    This struct is a source of mapping-free input to the `addWhitelist`
    function.

    @param expiryTime A block timestamp after which this whitelist is
      automatically considered inactive, no matter the value of `isActive`.
    @param isActive Whether or not this whitelist is actively restricting
      purchases in blocks ocurring before `expiryTime`.
    @param addresses An array of addresses to whitelist for participation in a
      purchases guarded by a whitelist.
  */
  struct WhitelistInput {
    uint256 expiryTime;
    bool isActive;
    address[] addresses;
  }
}