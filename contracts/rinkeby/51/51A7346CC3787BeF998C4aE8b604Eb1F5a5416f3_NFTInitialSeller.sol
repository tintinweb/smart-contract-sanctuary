// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IFacelessNFT.sol";

/**
 * Meta Kings - 4
 * Metavatars - 9
 * Archaeons - 19
 * Aeons - 69
 * Eos - 900
 *
 * Total number of NFTs: 1001
 */

contract NFTInitialSeller is Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  enum SaleStep {
    None,
    EarlyBirdSale,
    Airdrop,
    SecondSale,
    SoldOut
  }

  uint16 public constant MAX_NFT_SUPPLY = 1001;

  // Early bird sale prices
  uint256 public constant METAKING_PRICE = 0.5 ether;
  uint256 public constant METAVATARS_PRICE = 0.5 ether;
  uint256 public constant ARCHAEONS_PRICE = 0.3 ether;
  uint256 public constant AEONS_PRICE = 0.3 ether;
  uint256 public constant EOS_PRICE = 0.19 ether;

  // Second sale price
  uint256 public constant SECOND_SALE_PRICE = 0.3 ether;

  uint16 public pendingCount = MAX_NFT_SUPPLY;

  bool[1002] public minted;

  IFacelessNFT public facelessNFT;

  uint16[10000] private _pendingIds;

  // First sale is Early Bird Sale
  SaleStep private _currentSale = SaleStep.None;

  modifier airdropPeriod() {
    require(
      _currentSale == SaleStep.Airdrop,
      "NFTInitialSeller: Airdrop ended"
    );
    _;
  }

  modifier earlyBirdSalePeriod() {
    require(
      _currentSale == SaleStep.EarlyBirdSale,
      "NFTInitialSeller: Early Bird Sale ended"
    );
    _;
  }

  modifier secondSalePeriod() {
    require(
      _currentSale == SaleStep.SecondSale,
      "NFTInitialSeller: Second Sale ended"
    );
    _;
  }

  constructor(address nftAddress) {
    facelessNFT = IFacelessNFT(nftAddress);
  }

  function setCurrentSale(SaleStep _sale) external onlyOwner {
    require(_currentSale != _sale, "NFTInitialSeller: step already set");
    _currentSale = _sale;
  }

  function airdropTransfer(address to, uint16 nftIndex)
    external
    airdropPeriod
    onlyOwner
  {
    require(nftIndex >= 0, "NFTInitialSeller: too low index");
    require(nftIndex < 200, "NFTInitialSeller: too high index");
    uint16 tokenId = _popPendingAtIndex(nftIndex + 648);
    minted[tokenId] = true;
    facelessNFT.mint(to, tokenId);
  }

  function standardPurchase(uint16 nftIndex)
    external
    payable
    earlyBirdSalePeriod
  {
    require(nftIndex >= 0, "NFTInitialSeller: too low index");
    require(nftIndex < 155, "NFTInitialSeller: too high index");
    uint16 tokenId = _popPendingAtIndex(nftIndex + 847);
    require(
      msg.value == _getMintPrice(tokenId),
      "NFTInitialSeller: invalid ether value"
    );
    minted[tokenId] = true;
    facelessNFT.mint(msg.sender, tokenId);
  }

  /**
   * @dev Mint 'numberOfNfts' new tokens
   */
  function randomPurchase(uint256 numberOfNfts)
    external
    payable
    secondSalePeriod
  {
    require(pendingCount > 0, "NFTInitialSeller: All minted");
    require(numberOfNfts > 0, "NFTInitialSelle: numberOfNfts cannot be 0");
    require(
      numberOfNfts <= 20,
      "NFTInitialSeller: You may not buy more than 20 NFTs at once"
    );
    require(
      facelessNFT.totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY,
      "NFTInitialSeller: sale already ended"
    );
    require(
      SECOND_SALE_PRICE.mul(numberOfNfts) == msg.value,
      "NFTInitialSeller: invalid ether value"
    );

    for (uint i = 0; i < numberOfNfts; i++) {
      _randomMint(msg.sender);
    }
  }

  /**
   * @dev Withdraw total eth balance on the contract to owner
   */
  function withdraw() external onlyOwner {
    (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(sent, "NFTInitialSeller: Failed to withdraw");
  }

  function getPendingAtIndex(uint16 _index) public view returns (uint16) {
    return _pendingIds[_index] + _index;
  }

  function _getMintPrice(uint16 tokenId) internal pure returns (uint256) {
    require(tokenId >= 847, "NFTInitialSeller: low token id");
    if (tokenId <= 848) return METAKING_PRICE;
    if (tokenId <= 851) return METAVATARS_PRICE;
    if (tokenId <= 862) return ARCHAEONS_PRICE;
    if (tokenId <= 901) return AEONS_PRICE;
    if (tokenId <= 1001) return EOS_PRICE;
    revert("NFTInitialSeller: invalid token id");
  }

  function _popPendingAtIndex(uint16 _index) internal returns (uint16) {
    uint16 tokenId = getPendingAtIndex(_index);
    if (_index != pendingCount) {
      uint16 lastPendingId = getPendingAtIndex(pendingCount);
      _pendingIds[_index] = lastPendingId - _index;
    }
    pendingCount--;
    return tokenId;
  }

  function _randomMint(address _to) internal {
    uint16 index = uint16((_getRandom() % pendingCount) + 1);
    uint256 tokenId = _popPendingAtIndex(index);
    minted[tokenId] = true;
    facelessNFT.mint(_to, index);
  }

  function _getRandom() internal view returns (uint256) {
    return
      uint256(
        keccak256(
          abi.encodePacked(block.difficulty, block.timestamp, pendingCount)
        )
      );
  }
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IFacelessNFT {
  function totalSupply() external view returns (uint256);

  function isNameReserved(string memory nameString)
    external
    view
    returns (bool);

  function changeName(uint256 tokenId, string memory newName) external;

  function mint(address to, uint256 tokenId) external;
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

