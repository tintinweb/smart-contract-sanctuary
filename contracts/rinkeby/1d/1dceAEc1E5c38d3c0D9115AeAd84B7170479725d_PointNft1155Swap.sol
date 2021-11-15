// "SPDX-License-Identifier: MIT"

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

contract PointNft1155Swap is Ownable, ReentrancyGuard {
  event EthWithdrawn(uint256 amount);

  event UnicornToEthSet(uint256 value);
  event RainbowToEthSet(uint256 value);

  event NftByRainbowSwapped(uint256 id, uint256 amount, address payer);
  event NftByUnicornSwapped(uint256 id, uint256 amount, address payer);

  event NftRefilled(uint256 id, uint256 amount);
  event NftPriceSet(uint256 id, uint256 unicornPrice, uint256 rainbowPrice, bool unicornAllowed, bool rainbowAllowed);
  event NftAdded(uint256 id, uint256 amount, uint256 unicornPrice, uint256 rainbowPrice, bool unicornAllowed, bool rainbowAllowed);

  using SafeMath for uint256; 

  IStakingPool public rainbowPool;
  IStakingPool public unicornPool;
  IERC1155 public nft;

  uint256 private unicornToEth;
  uint256 private rainbowToEth;

  struct Nft {
    bool defined;
    uint256 unicornPrice;
    uint256 rainbowPrice;
    bool unicornAllowed;
    bool rainbowAllowed;
    uint256 amount;
  }

  mapping(uint256 => Nft) internal nfts;

  constructor(address _nft, address _rainbowPool, address _unicornPool)
    public {
      require(_nft != address(0), "PointNft1155Swap: _nft is zero address");
      require(_rainbowPool != address(0), "PointNft1155Swap: _rainbowPool is zero address");
      require(_unicornPool != address(0), "PointNft1155Swap: _unicornPool is zero address");

      nft = IERC1155(_nft);
      rainbowPool = IStakingPool(_rainbowPool);
      unicornPool = IStakingPool(_unicornPool);
  }

  function setUnicornToEth(uint256 _unicornToEth)
    external onlyOwner {
      unicornToEth = _unicornToEth;
      emit UnicornToEthSet(_unicornToEth);
  }

  function setRainbowToEth(uint256 _rainbowToEth)
    external onlyOwner {
      rainbowToEth = _rainbowToEth;
      emit RainbowToEthSet(_rainbowToEth);
  }

  function addNft(uint256 _id, uint256 _amount, uint256 _unicornPrice, uint256 _rainbowPrice, bool _unicornAllowed, bool _rainbowAllowed)
    external onlyOwner {
      require(!nfts[_id].defined, "PointNft1155Swap: nft id already exists");
      require(_amount > 0, "PointNft1155Swap: _amount is zero");
      require(nft.balanceOf(_msgSender(), _id) >= _amount, "PointNft1155Swap: not enough balance");

      nft.safeTransferFrom(_msgSender(), address(this), _id, _amount, "");

      nfts[_id] = Nft({
        defined: true,
        amount: _amount,
        unicornPrice: _unicornPrice,
        rainbowPrice: _rainbowPrice,
        unicornAllowed: _unicornAllowed,
        rainbowAllowed: _rainbowAllowed
      });

      emit NftAdded(_id, _amount, _unicornPrice, _rainbowPrice, _unicornAllowed, _rainbowAllowed);
  }

  function setNftPrice(uint256 _id, uint256 _unicornPrice, uint256 _rainbowPrice, bool _unicornAllowed, bool _rainbowAllowed)
    external onlyOwner {
      require(nfts[_id].defined, "PointNft1155Swap: nft id not defined");
    
      nfts[_id].unicornPrice = _unicornPrice;
      nfts[_id].rainbowPrice = _rainbowPrice;
      nfts[_id].unicornAllowed = _unicornAllowed;
      nfts[_id].rainbowAllowed = _rainbowAllowed;

      emit NftPriceSet(_id, _unicornPrice, _rainbowPrice, _unicornAllowed, _rainbowAllowed);
  }

  function refillNft(uint256 _id, uint256 _amount) 
    external nonReentrant {
      require(nfts[_id].defined, "PointNft1155Swap: nft id not defined");
      require(_amount > 0, "PointNft1155Swap: _amount is zero");
      require(nft.balanceOf(_msgSender(), _id) >= _amount, "PointNft1155Swap: not enough balance");

      nft.safeTransferFrom(_msgSender(), address(this), _id, _amount, "");
  
      nfts[_id].amount = nfts[_id].amount.add(_amount);

      emit NftRefilled(_id, _amount);
  }

  function swapByUnicorn(uint256 _id, uint256 _amount)
    external payable nonReentrant {
      require(nfts[_id].defined, "PointNft1155Swap: nft id not defined");
      require(nfts[_id].amount >= _amount, "PointNft1155Swap: invalid nft's amount");
      require(nfts[_id].unicornAllowed, "PointNft1155Swap: unicorn swap not allowed");

      uint256 _balance = unicornPool.balanceOf(_msgSender());
      uint256 _totalPrice = nfts[_id].unicornPrice.mul(_amount);

      if (_balance < _totalPrice) {
        require(msg.value.mul(unicornToEth).add(_balance) >= _totalPrice, "PointNft1155Swap: not enough balance");
        unicornPool.burn(_msgSender(), _balance);

        uint256 _amountToWithdraw = msg.value.sub(_totalPrice.sub(_balance).div(unicornToEth));

        (bool success, ) = _msgSender().call{ value: _amountToWithdraw }("");
        require(success, "PointNft1155Swap: transfer failed");
      } else {
        unicornPool.burn(_msgSender(), _totalPrice);

        (bool success, ) = _msgSender().call{ value: msg.value }("");
        require(success, "PointNft1155Swap: transfer failed");
      }

      _swap(_id, _amount);
      emit NftByUnicornSwapped(_id, _amount, _msgSender());
  }

  function swapByRainbow(uint256 _id, uint256 _amount)
    external payable nonReentrant {
      require(nfts[_id].defined, "PointNft1155Swap: nft id not defined");
      require(nfts[_id].amount >= _amount, "PointNft1155Swap: invalid nft's amount");
      require(nfts[_id].rainbowAllowed, "PointNft1155Swap: rainbow swap not allowed");

      uint256 _balance = rainbowPool.balanceOf(_msgSender());
      uint256 _totalPrice = nfts[_id].rainbowPrice.mul(_amount);

      if (_balance < _totalPrice) {
        require(msg.value.mul(rainbowToEth).add(_balance) >= _totalPrice, "PointNft1155Swap: not enough balance");
        rainbowPool.burn(_msgSender(), _balance);

        uint256 _amountToWithdraw = msg.value.sub(_totalPrice.sub(_balance).div(rainbowToEth));
        
        (bool success, ) = _msgSender().call{ value: _amountToWithdraw }("");
        require(success, "PointNft1155Swap: transfer failed");
      } else {
        rainbowPool.burn(_msgSender(), _totalPrice);

        (bool success, ) = _msgSender().call{ value: msg.value }("");
        require(success, "PointNft1155Swap: transfer failed");
      }

      _swap(_id, _amount);
      emit NftByRainbowSwapped(_id, _amount, _msgSender());
  }

  function withdraw(uint256 _amount)
    external onlyOwner {
      require(_amount <= address(this).balance, "PointNft1155Swap: not enough contract balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "PointNft1155Swap: transfer failed");
      emit EthWithdrawn(_amount);
  }

  function _swap(uint256 _id, uint256 _amount)
    private {
      nfts[_id].amount = nfts[_id].amount.sub(_amount);
      nft.safeTransferFrom(address(this), _msgSender(), _id, _amount, "");
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
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

