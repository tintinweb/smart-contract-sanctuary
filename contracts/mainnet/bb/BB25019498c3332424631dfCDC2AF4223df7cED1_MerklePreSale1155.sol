// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMerklePreSale.sol";
import "./ISuper1155.sol";

contract MerklePreSale1155 is IMerklePreSale, Ownable {
    using SafeMath for uint256;

    address public immutable override token;

    address payable public receiver;

    uint256 public price;

    uint256 public purchaseLimit;

    //bytes32 public immutable override merkleRoot;
    mapping ( uint256 => bytes32 ) public merkleRoots;

    // This is a packed array of booleans.
    mapping( uint256 => mapping( uint256 => uint256) ) private purchasedBitMap;

    constructor( address _token, address payable _receiver, uint256 _price, uint256 _purchaseLimit) {
        token = _token;
        receiver = _receiver;
        price = _price;
        purchaseLimit = _purchaseLimit;
     }

    function setRoundRoot(uint256 groupId, bytes32 merkleRoot) external onlyOwner {
      merkleRoots[groupId] = merkleRoot;
    }

    function updateReceiver(address payable _receiver) external onlyOwner {
      receiver = _receiver;
    }

    function updatePrice(uint256 _price) external onlyOwner {
      price = _price;
    }

    function updatePurchaseLimit(uint256 _purchaseLimit) external onlyOwner {
      purchaseLimit = _purchaseLimit;
    }

    function isPurchased( uint256 groupId, uint256 index ) public view override returns ( bool ) {
        uint256 purchasedWordIndex = index / 256;
        uint256 purchasedBitIndex = index % 256;
        uint256 purchasedWord = purchasedBitMap[groupId][purchasedWordIndex];
        uint256 mask = ( 1 << purchasedBitIndex );
        return purchasedWord & mask == mask;
    }

    function _setPurchased( uint256 groupId, uint256 index ) private {
        uint256 purchasedWordIndex = index / 256;
        uint256 purchasedBitIndex = index % 256;
        purchasedBitMap[groupId][purchasedWordIndex] = purchasedBitMap[groupId][purchasedWordIndex] | ( 1 << purchasedBitIndex );
    }

    function purchase( uint256 groupId, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof ) public payable override {
        require( !isPurchased( groupId, index ), 'MerklePreSale: Drop already purchased.' );
        require( amount <= purchaseLimit, 'MerklePreSale: Buy fewer items');
        uint256 totalCost = amount.mul(price);
        require( msg.value >= totalCost, 'MerklePreSale: Send more eth');
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, uint(1)));
        uint256 path = index;
        for (uint16 i = 0; i < merkleProof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(merkleProof[i], node));
            } else {
                node = keccak256(abi.encodePacked(node, merkleProof[i]));
            }
            path /= 2;
        }

        // Check the merkle proof
        require(node == merkleRoots[groupId], 'MerklePreSale: Invalid proof.' );
        // Mark it purchased and send the token.
        _setPurchased(  groupId, index );

        uint256 newTokenIdBase = groupId << 128;
        uint256 currentMintCount = ISuper1155( token ).groupMintCount(groupId);

        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint[](amount);
        for(uint256 i = 0; i < amount; i++) {
          ids[i] = newTokenIdBase.add(currentMintCount).add(i).add(1);
          amounts[i] = uint256(1);
        }
        (bool paymentSuccess, ) = receiver.call{ value: msg.value }("");
        require( paymentSuccess, 'MerklePreSale: payment failure');

        ISuper1155( token ).mintBatch( account, ids, amounts, "" );
        emit Purchased( index, account, amount );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

// Allows anyone to purchase a token if they exist in a merkle root.
interface IMerklePreSale {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns true if the index has been marked purchased.
    function isPurchased(uint256 groupId, uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function purchase(uint256 groupId, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external payable;

    // This event is triggered whenever a call to #purchase succeeds.
    event Purchased(uint256 index, address account, uint256 amount);
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