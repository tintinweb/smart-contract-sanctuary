// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
interface IERC1155TokenCreator {
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {

    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function creatorOfToken(uint256 _tokenId)
    external
    view
    returns (address payable);

    /**
     * @dev Gets the Service Fee
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function getServiceFee(uint256 _tokenId)
    external
    view
    returns (uint8);

    /**
     * @dev Gets the price type
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     * @return get the price type
     */
    function getPriceType(uint256 _tokenId, address _owner)
    external
    view
    returns (uint8);

    /**
     * @dev update price only from auction.
     * @param _price price of the token
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setPrice(uint256 _price, uint256 _tokenId, address _owner) external;

    /**
     * @dev update bids only from auction.
     * @param _bid bid Amount
     * @param _bidder bidder address
     * @param _tokenId uint256 id of the token.
     * @param _owner address of the token owner
     */
    function setBid(uint256 _bid, address _bidder, uint256 _tokenId, address _owner) external;

    /**
     * @dev remove token from sale
     * @param _tokenId uint256 id of the token.
     * @param _owner owner of the token
     */
    function removeFromSale(uint256 _tokenId, address _owner) external;

    /**
     * @dev get tokenIds length
     */
    function getTokenIdsLength() external view returns (uint256);

    /**
     * @dev get token Id
     * @param _index uint256 index
     */
    function getTokenId(uint256 _index) external view returns (uint256);

    /**
     * @dev Gets the owners
     * @param _tokenId uint256 ID of the token
     */
    function getOwners(uint256 _tokenId)
    external
    view
    returns (address[] memory owners);

    /**
     * @dev Gets the is for sale
     * @param _tokenId uint256 ID of the token
     * @param _owner address of the token owner
     */
    function getIsForSale(uint256 _tokenId, address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC1155TokenCreator.sol";

/**
 * @title IERC1155CreatorRoyalty Token level royalty interface.
 */
interface INafterRoyaltyRegistry is IERC1155TokenCreator {
    /**
     * @dev Get the royalty fee percentage for a specific ERC1155 contract.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getTokenRoyaltyPercentage(
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Sets the royalty percentage set for an Nafter token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _tokenId uint256 token ID.
     * @param _percentage uint8 wei royalty fee.
     */
    function setPercentageForTokenRoyalty(
        uint256 _tokenId,
        uint8 _percentage
    ) external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IERC721 Non-Fungible Token Creator basic interface
 */
interface INafterTokenCreatorRegistry {
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    returns (address payable);

    /**
     * @dev Sets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @param _creator address of the creator for the token
     */
    function setTokenCreator(
        uint256 _tokenId,
        address payable _creator
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INafterRoyaltyRegistry.sol";
import "./INafterTokenCreatorRegistry.sol";
import "./INafter.sol";

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
contract NafterTokenCreatorRegistry is Ownable, INafterTokenCreatorRegistry {
    using SafeMath for uint256;

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Mapping of ERC1155 token to it's creator.
    mapping(uint256 => address payable)
    private tokenCreators;
    address public nafter;

    /////////////////////////////////////////////////////////////////////////
    // tokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Gets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @return address of the creator
     */
    function tokenCreator(uint256 _tokenId)
    external
    view
    override
    returns (address payable)
    {
        if (tokenCreators[_tokenId] != address(0)) {
            return tokenCreators[_tokenId];
        }

        return address(0);
    }

    /////////////////////////////////////////////////////////////////////////
    // setNafter
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Set nafter contract address
     * @param _nafter uint256 ID of the token
     */
    function setNafter(address _nafter) external onlyOwner {
        nafter = _nafter;
    }

    /////////////////////////////////////////////////////////////////////////
    // setTokenCreator
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Sets the creator of the token
     * @param _tokenId uint256 ID of the token
     * @param _creator address of the creator for the token
     */
    function setTokenCreator(
        uint256 _tokenId,
        address payable _creator
    ) external override {
        require(
            _creator != address(0),
            "setTokenCreator::Cannot set null address as creator"
        );

        require(msg.sender == nafter || msg.sender == owner(), "setTokenCreator::only nafter and owner allowed");

        tokenCreators[_tokenId] = _creator;
    }

    /**
     * @dev restore data from old contract, only call by owner
     * @param _oldAddress address of old contract.
     * @param _oldNafterAddress get the token ids from the old nafter contract.
     * @param _startIndex start index of array
     * @param _endIndex end index of array
     */
    function restore(address _oldAddress, address _oldNafterAddress, uint256 _startIndex, uint256 _endIndex) external onlyOwner {
        NafterTokenCreatorRegistry oldContract = NafterTokenCreatorRegistry(_oldAddress);
        INafter oldNafterContract = INafter(_oldNafterAddress);

        uint256 length = oldNafterContract.getTokenIdsLength();
        require(_startIndex < length, "wrong start index");
        require(_endIndex <= length, "wrong end index");

        for (uint i = _startIndex; i < _endIndex; i++) {
            uint256 tokenId = oldNafterContract.getTokenId(i);
            if (tokenCreators[tokenId] != address(0)) {
                tokenCreators[tokenId] = oldContract.tokenCreator(tokenId);
            }
        }
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

