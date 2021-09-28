// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./ISuper1155.sol";

/**
  @title TokenRedeemer: a contract for redeeming ERC-1155 token claims with
    optional burns.
  @author 0xthrpw
  @author Tim Clancy

  This contract allows a specific ERC-1155 token of a given group ID to be
  redeemed or burned in exchange for a new token from a new group in an
  optionally-new ERC-1155 token contract.
*/
contract NFTUpgrade1155 is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  /// The smart contract being used in redemptions.
  ISuper1155 public super1155;

  /// The address being used as a custom burn address.
  address public burnAddress;

  bool public customBurn;

  /**
  */
  struct RedemptionConfig {
    uint256 groupIdOut;
    uint256 amountOut;
    bool burnOnRedemption;
  }

  // collection in => collection out => groupId in => config
  mapping(address => mapping(address => mapping(uint256 => RedemptionConfig))) public redemptionConfigs;

  //[_tokenOut][groupIdOut][_tokenIn][_tokenId]
  // collection out => groupIdOut => collection in => tokenId in => address of redeemer
  mapping (address => mapping (uint256 => mapping(address => mapping(uint256 => address)))) public redeemer;

  /**
  */
  event TokenRedemption(address indexed user, address indexed tokenIn, uint256 tokenIdIn, address indexed tokenOut, uint256[] tokensOut);

  /**
  */
  event ConfigUpdate(address indexed tokenIn, uint256 indexed groupIdIn, uint256 groupIdOut, address indexed tokenOut, uint256 amountOut, bool burnOnRedemption);

  /**
    On deployment, set the burn address as `_burnTarget` and enable use of a
    custom burn address by setting `_customBurn`.

    @param _burnTarget The address that will be used for burning tokens.
    @param _customBurn Whether or not a custom burn address is used.
  */
  constructor(address _burnTarget, bool _customBurn) {
    customBurn = _customBurn;
    if (customBurn) {
      require(_burnTarget != address(0), "TokenRedeemer::constructor: Custom burn address cannot be 0 address");
      burnAddress = _burnTarget;
    }
  }

  /**
    Redeem a specific token `_tokenId` for a token from group `_groupIdOut`

    @param _tokenId The bitpacked 1155 token id
    @param _tokenIn The collection address of the redeemedable item
    @param _tokenOut The address of the token to receive
  */
  function redeem(
    uint256 _tokenId,
    address _tokenIn,
    address _tokenOut
  ) external nonReentrant {
    _redeemToken(_tokenId, _tokenIn, _tokenOut);
  }

  /**
    Redeem a specific set of tokens `_tokenIds` for a set of token from group `_groupIdOut`

    @param _tokenIds An array of bitpacked 1155 token ids
    @param _tokenIn The collection address of the redeemedable item
    @param _tokenOut The address of the token to receive
  */
  function redeemMult(
    uint256[] calldata _tokenIds,
    address _tokenIn,
    address _tokenOut
  ) external nonReentrant {
    for(uint256 n = 0; n < _tokenIds.length; n++){
      _redeemToken(_tokenIds[n], _tokenIn, _tokenOut);
    }
  }

  /**
    Redeem a token for n number of tokens in return.  This function parses the
    tokens group id, determines the appropriate exchange token and amount, if
    necessary burns the deposited token and mints the receipt token(s)

    @param _tokenId The bitpacked 1155 token id
    @param _tokenIn The collection address of the redeemedable item
    @param _tokenOut The collection address of the token being received
  */
  function _redeemToken(
    uint256 _tokenId,
    address _tokenIn,
    address _tokenOut
  ) internal {
    uint256 _groupIdIn = _tokenId >> 128;
    RedemptionConfig memory config = redemptionConfigs[_tokenIn][_tokenOut][_groupIdIn];
    uint256 redemptionAmount = config.amountOut;
    uint256 groupIdOut = config.groupIdOut;
    require(redeemer[_tokenOut][groupIdOut][_tokenIn][_tokenId] == address(0), "TokenRedeemer::redeem: token has already been redeemed for this group" );

    {
      require(groupIdOut != uint256(0), "TokenRedeemer::redeem: invalid group id from token");
      require(redemptionAmount != uint256(0), "TokenRedeemer::redeem: invalid redemption amount");

      uint256 balanceOfSender = ISuper1155(_tokenIn).balanceOf(_msgSender(), _tokenId);
      require(balanceOfSender != 0, "TokenRedeemer::redeem: msg sender is not token owner");
    }

    uint256 mintCount = ISuper1155(_tokenOut).groupMintCount(groupIdOut);
    uint256 nextId = mintCount.add(1);
    uint256[] memory ids = new uint256[](redemptionAmount);
    uint256[] memory amounts = new uint[](redemptionAmount);

    uint256 newgroupIdPrep = groupIdOut << 128;
    for(uint256 i = 0; i < redemptionAmount; i++) {
      ids[i] = newgroupIdPrep.add(nextId).add(i);
      amounts[i] = uint256(1);
    }

    redeemer[_tokenOut][groupIdOut][_tokenIn][_tokenId] = _msgSender();

    if (config.burnOnRedemption) {
      if (customBurn) {
        ISuper1155(_tokenIn).safeTransferFrom(_msgSender(), burnAddress, _tokenId, 1, "");
      } else {
        ISuper1155(_tokenIn).burnBatch(_msgSender(), _asSingletonArray(_tokenId), _asSingletonArray(1));
      }
    }

    ISuper1155(_tokenOut).mintBatch(_msgSender(), ids, amounts, "");

    emit TokenRedemption(_msgSender(), _tokenIn, _tokenId, _tokenOut, ids);
  }

  /**
    Configure redemption amounts for each group.  ONE token of _groupIdin from
    collection _tokenIn results in _amountOut number of _groupIdOut tokens from
    collection _tokenOut

    @param _tokenIn The collection address of the redeemedable item
    @param _groupIdIn The group ID of the token being redeemed
    @param _tokenOut The collection address of the item being received
    @param _data The redemption config data input.
  */

  function setRedemptionConfig(
    address _tokenIn,
    uint256 _groupIdIn,
    address _tokenOut,
    RedemptionConfig calldata _data
  ) external onlyOwner {
    redemptionConfigs[_tokenIn][_tokenOut][_groupIdIn] = RedemptionConfig({
      groupIdOut: _data.groupIdOut,
      amountOut: _data.amountOut,
      burnOnRedemption: _data.burnOnRedemption
    });

    emit ConfigUpdate(_tokenIn, _groupIdIn, _data.groupIdOut, _tokenOut, _data.amountOut, _data.burnOnRedemption);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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
library SafeMath {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ISuper1155 {
  function BURN (  ) external view returns ( bytes32 );
  function CONFIGURE_GROUP (  ) external view returns ( bytes32 );
  function LOCK_CREATION (  ) external view returns ( bytes32 );
  function LOCK_ITEM_URI (  ) external view returns ( bytes32 );
  function LOCK_URI (  ) external view returns ( bytes32 );
  function MANAGER (  ) external view returns ( bytes32 );
  function MINT (  ) external view returns ( bytes32 );
  function SET_METADATA (  ) external view returns ( bytes32 );
  function SET_PROXY_REGISTRY (  ) external view returns ( bytes32 );
  function SET_URI (  ) external view returns ( bytes32 );
  function UNIVERSAL (  ) external view returns ( bytes32 );
  function ZERO_RIGHT (  ) external view returns ( bytes32 );

  function balanceOf ( address _owner, uint256 _id ) external view returns ( uint256 );
  function balanceOfBatch ( address[] memory _owners, uint256[] memory _ids ) external view returns ( uint256[] memory );
  function burn ( address _burner, uint256 _id, uint256 _amount ) external;
  function burnBatch ( address _burner, uint256[] memory _ids, uint256[] memory _amounts ) external;
  function burnCount ( uint256 ) external view returns ( uint256 );
  function circulatingSupply ( uint256 ) external view returns ( uint256 );
  function configureGroup ( uint256 _groupId, bytes calldata _data ) external;
  function groupBalances ( uint256, address ) external view returns ( uint256 );
  function groupMintCount ( uint256 ) external view returns ( uint256 );
  function hasRightUntil ( address _address, bytes32 _circumstance, bytes32 _right ) external view returns ( uint256 );
  function isApprovedForAll ( address _owner, address _operator ) external view returns ( bool );
  function itemGroups ( uint256 ) external view returns ( bool initialized, string memory _name, uint8 supplyType, uint256 supplyData, uint8 itemType, uint256 itemData, uint8 burnType, uint256 burnData, uint256 _circulatingSupply, uint256 _mintCount, uint256 _burnCount );
  function lock (  ) external;
  function lockURI ( string memory _uri, uint256 _id ) external;
  function lockURI ( string memory _uri ) external;
  function locked (  ) external view returns ( bool );
  function managerRight ( bytes32 ) external view returns ( bytes32 );
  function metadata ( uint256 ) external view returns ( string memory );
  function metadataFrozen ( uint256 ) external view returns ( bool );
  function metadataUri (  ) external view returns ( string memory );
  function mintBatch ( address _recipient, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data ) external;
  function mintCount ( uint256 ) external view returns ( uint256 );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function permissions ( address, bytes32, bytes32 ) external view returns ( uint256 );
  function proxyRegistryAddress (  ) external view returns ( address );
  function renounceOwnership (  ) external;
  function safeBatchTransferFrom ( address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data ) external;
  function safeTransferFrom ( address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data ) external;
  function setApprovalForAll ( address _operator, bool _approved ) external;
  function setManagerRight ( bytes32 _managedRight, bytes32 _managerRight ) external;
  function setMetadata ( uint256 _id, string memory _metadata ) external;
  function setPermit ( address _address, bytes32 _circumstance, bytes32 _right, uint256 _expirationTime ) external;
  function setProxyRegistry ( address _proxyRegistryAddress ) external;
  function setURI ( string memory _uri ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function totalBalances ( address ) external view returns ( uint256 );
  function transferOwnership ( address newOwner ) external;
  function uri ( uint256 ) external view returns ( string memory );
  function uriLocked (  ) external view returns ( bool );
  function version (  ) external view returns ( uint256 );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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