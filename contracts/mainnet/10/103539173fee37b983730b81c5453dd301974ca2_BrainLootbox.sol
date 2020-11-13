// File: contracts/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

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

// File: contracts/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.2;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/BrainLootbox.sol

// Brain/WETH Locked LP
// https://nobrainer.finance/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;



interface IBrainNFT {
  function addCard(uint256 maxSupply) external returns (uint256);
  function mint(address to, uint256 id, uint256 amount) external;
}

contract BrainLootbox is Ownable {
  using SafeMath for uint256;
  address public NFTAddress;
  mapping(address => bool) public isFarmAddress;

  constructor(address _brainFarm, address _lockedLPFarm, address _NFTAddress) public {
    isFarmAddress[_brainFarm] = true;
    isFarmAddress[_lockedLPFarm] = true;
    NFTAddress = _NFTAddress;
  }

  event AddLootBox(uint256 id);
  event CardRedeemed(address user, uint256 id, uint256 card);

  uint256 private createdLootboxes;
  mapping(uint256 => LootBox) public lootbox;

  function getPrice(uint256 _id) public view returns (uint256) {
    return lootbox[_id].price;
  }

  struct LootBox {
    uint256 seed;
    string name;
    uint256 price;
    uint256[] cardIds;
    uint256[] cardAmounts;
    uint256 totalCards;
  }

  /*
  Gas consumption in function "addLootBox" in contract "BrainLootbox" depends on the size of data structures that may grow unboundedly. 
  The highlighted assignment overwrites or deletes a state variable that contains an array. When assigning to or deleting storage arrays, 
    the Solidity compiler emits an implicit clearing loop.
  If the array grows too large, the gas required to execute the code will exceed the block gas limit, effectively causing a denial-of-service condition. 
  Consider that an attacker might attempt to cause this condition on purpose.
  https://swcregistry.io/docs/SWC-128
  
  AUDITOR NOTE: Since this function has the onlyOwner modifier, this vulnerability can't be executed by other users.
    Be aware to increase the gas limit when executing the function over a large array.
  */
  function addLootBox(string memory _name, uint256 _price, uint256[] memory _cardAmounts) public onlyOwner returns (uint256[] memory) {
    require(_price > 0, "Price must be greater than 0");
    createdLootboxes = createdLootboxes.add(1);
    lootbox[createdLootboxes].name = _name;
    lootbox[createdLootboxes].price = _price;
    lootbox[createdLootboxes].cardAmounts = _cardAmounts;
    uint256 total;
    for (uint256 i = 0; i < _cardAmounts.length; i++) {
      total = total.add(_cardAmounts[i]);
      lootbox[createdLootboxes].cardIds.push(IBrainNFT(NFTAddress).addCard(_cardAmounts[i]));
    }
    lootbox[createdLootboxes].totalCards = total;
    lootbox[createdLootboxes].seed = uint256(keccak256(abi.encodePacked(now, _price, _name, block.difficulty)));
    emit AddLootBox(createdLootboxes);
    return lootbox[createdLootboxes].cardIds;
  }

  function remainingCards(uint256 _id) public view returns (uint256) {
    return lootbox[_id].totalCards;
  }

/*
  Gas consumption in function "addLootBox" in contract "BrainLootbox" depends on the size of data structures that may grow unboundedly. 
  The highlighted assignment overwrites or deletes a state variable that contains an array. When assigning to or deleting storage arrays, 
    the Solidity compiler emits an implicit clearing loop.
  If the array grows too large, the gas required to execute the code will exceed the block gas limit, effectively causing a denial-of-service condition. 
  Consider that an attacker might attempt to cause this condition on purpose.
  https://swcregistry.io/docs/SWC-128
  
  AUDITOR NOTE: Provided the mapping of lootbox to cardIds array is not too large this should not be a major issue.
    But, can still fall prey to a deliberate denial-of-service attack by sending a transaction lower enough to halt processing.
    Provided the array size of lootbox[id].cardIds.length does not grow so large as to allow of a under gased transaction to make it's way through through the network.
    Generally, this should be resolved by a tansaction with just a low gas limit geting stuck.
  */
  function redeem(uint256 id, address to) public {
    require(isFarmAddress[_msgSender()] == true, "Only NFT Farm can call this method");
    require(id != 0 && id <= createdLootboxes, "Lootbox does not exist");
    require(lootbox[id].totalCards > 0, "No cards left in lootbox");
    uint256 rand = uint256(keccak256(abi.encodePacked(now, lootbox[id].totalCards, lootbox[id].seed, block.difficulty)));
    lootbox[id].seed = rand;
    uint256 pickedCard = rand.mod(lootbox[id].totalCards);
    uint256 counted;
    uint256[] memory _cardAmounts = lootbox[id].cardAmounts;
    
    for (
        uint256 i = 0; 
        i < lootbox[id].cardIds.length;
        i++
    ) {
      counted = counted.add(_cardAmounts[i]);
      if (pickedCard < counted) {
        IBrainNFT(NFTAddress).mint(to, lootbox[id].cardIds[i], 1);
        lootbox[id].cardAmounts[i] = lootbox[id].cardAmounts[i].sub(1);
        lootbox[id].totalCards = lootbox[id].totalCards.sub(1);
        emit CardRedeemed(to, id, lootbox[id].cardIds[i]);
        break;
      }
    }
  }
}