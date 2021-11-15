// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";

import "./IERC20.sol";
import "./IERC721Collection.sol";

contract BurningStore is Ownable {
    using SafeMath for uint256;

    struct CollectionData {
        mapping (uint256 => uint256) pricePerOptionId;
        mapping (uint256 => uint256) availableQtyPerOptionId;
        address saleBeneficiary;
        uint256 collectionFee;
    }

    IERC20 public acceptedToken;
    address storeFeeAddresses;

    uint256 constant FEE_PRECISION = 10000;

    mapping (address => CollectionData) collectionsData;

    event Bought(address indexed _collectionAddress, uint256[] _optionIds, address _beneficiary, uint256 _price);
    event SetCollectionData(address indexed _collectionAddress, uint256[] _optionIds, uint256[] _availableQtys, uint256[] _prices);

    /**
    * @dev Constructor of the contract.
    * @param _acceptedToken - Address of the ERC20 token accepted
    * @param _collectionAddresses - collection addresses
    * @param _collectionOptionIds - collection option ids
    * @param _collectionAvailableQtys - collection available qtys for sale
    * @param _collectionPrices - collection prices
    */
    constructor(
        IERC20 _acceptedToken,
        address _storeFeeAddresses,
        address[] memory _collectionAddresses,
        address[] memory _saleBeneficiaryAddresses,
        uint256[] memory _collectionFee,
        uint256[][] memory _collectionOptionIds,
        uint256[][] memory _collectionAvailableQtys,
        uint256[][] memory _collectionPrices
      )
      public {
        acceptedToken = _acceptedToken;
        storeFeeAddresses = _storeFeeAddresses;

        for (uint256 i = 0; i < _collectionAddresses.length; i++) {
            _setCollectionData(_collectionAddresses[i], _saleBeneficiaryAddresses[i], _collectionFee[i], _collectionOptionIds[i], _collectionAvailableQtys[i], _collectionPrices[i]);
        }
    }

    /**
    * @dev Donate in exchange for NFTs.
    * @notice that there is a maximum amount of NFTs that can be issued per call.
    * If the donation greater than `price * maxNFTsPerCall`, all the donation will be used and
    * a maximum of `maxNFTsPerCall` will be issued.
    * @param _collectionAddress - collectionn address
    * @param _optionIds - collection option id
    * @param _beneficiary - beneficiary address
    */
    function buy(address _collectionAddress, uint256[] calldata _optionIds, address _beneficiary) external {
        CollectionData storage collection = collectionsData[_collectionAddress];

        uint256 amount = _optionIds.length;
        uint256 finalPrice = 0;
        address[] memory beneficiaries = new address[](amount);
        bytes32[] memory items = new bytes32[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 optionId = _optionIds[i];
            require(collection.availableQtyPerOptionId[optionId] > 0, "Sold out item");

            // Add price
            uint256 itemPrice = collection.pricePerOptionId[optionId];
            finalPrice = finalPrice.add(itemPrice);

            // Add beneneficiary
            beneficiaries[i] = _beneficiary;

            // Add item
            string memory item = itemByOptionId(_collectionAddress, optionId);
            bytes32 itemAsBytes32;
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                itemAsBytes32 := mload(add(item, 32))
            }
            items[i] = itemAsBytes32;
            collection.availableQtyPerOptionId[optionId] = collection.availableQtyPerOptionId[optionId].sub(1);
        }

        // Check if the sender has at least `price` and the contract has allowance to use on its behalf
        _requireBalance(msg.sender, finalPrice);

        uint256 fee = finalPrice / FEE_PRECISION * collection.collectionFee;

        // Debit `price` from sender
        require(
            acceptedToken.transferFrom(msg.sender, collection.saleBeneficiary, finalPrice-fee),
            "Transfering finalPrice to sale beneficiary failed"
        );
        require(
            acceptedToken.transferFrom(msg.sender, storeFeeAddresses, fee),
            "Transfering fee failed"
        );

        // Burn it
//        acceptedToken.burn(finalPrice);

        // Mint NFT
        IERC721Collection(_collectionAddress).issueTokens(beneficiaries, items);

        emit Bought(_collectionAddress, _optionIds, _beneficiary, finalPrice);
    }

    /**
    * @dev Returns whether the wearable can be minted.
    * @param _collectionAddress - collectionn address
    * @param _optionId - item option id
    * @return whether a wearable can be minted
    */
    function canMint(address _collectionAddress, uint256 _optionId, uint256 _amount) public view returns (bool) {
        CollectionData storage collection = collectionsData[_collectionAddress];

        return collection.availableQtyPerOptionId[_optionId] >= _amount;
    }

    /**
     * @dev Returns a wearable's available supply .
     * Throws if the option ID does not exist. May return 0.
     * @param _collectionAddress - collectionn address
     * @param _optionId - item option id
     * @return wearable's available supply
     */
    function balanceOf(address _collectionAddress, uint256 _optionId) public view returns (uint256) {
        CollectionData storage collection = collectionsData[_collectionAddress];

        return collection.availableQtyPerOptionId[_optionId];
    }

    /**
    * @dev Get item id by option id
    * @param _collectionAddress - collectionn address
    * @param _optionId - collection option id
    * @return string of the item id
    */
    function itemByOptionId(address _collectionAddress, uint256 _optionId) public view returns (string memory) {
       /* solium-disable-next-line */
        (bool success, bytes memory data) = address(_collectionAddress).staticcall(
            abi.encodeWithSelector(
                IERC721Collection(_collectionAddress).wearables.selector,
                _optionId
            )
        );

        require(success, "Invalid wearable");

        return abi.decode(data, (string));
    }

    /**
    * @dev Get collection data by option id
    * @param _collectionAddress - collectionn address
    * @param _optionId - collection option id
    * @return availableQty - collection option id available qty
    * @return price - collection option id price
    */
    function collectionData(address _collectionAddress, uint256 _optionId) external view returns (
        uint256 availableQty, uint256 price
    ) {
        availableQty = collectionsData[_collectionAddress].availableQtyPerOptionId[_optionId];
        price = collectionsData[_collectionAddress].pricePerOptionId[_optionId];
    }

    /**
    * @dev Sets the beneficiary address where the sales amount
    *  will be transferred on each sale for a collection
    * @param _collectionAddress - collectionn address
    * @param _collectionOptionIds - collection option ids
    * @param _collectionAvailableQtys - collection available qtys for sale
    * @param _collectionPrices - collectionn prices
    */
    function setCollectionData(
        address _collectionAddress,
        address _saleBeneficiaryAddress,
        uint256 _collectionFee,
        uint256[] calldata _collectionOptionIds,
        uint256[] calldata _collectionAvailableQtys,
        uint256[] calldata _collectionPrices
    ) external onlyOwner {
        _setCollectionData(_collectionAddress, _saleBeneficiaryAddress, _collectionFee, _collectionOptionIds, _collectionAvailableQtys, _collectionPrices);
    }

    /**
    * @dev Sets the beneficiary address where the sales amount
    *  will be transferred on each sale for a collection
    * @param _collectionAddress - collectionn address
    * @param _collectionOptionIds - collection option ids
    * @param _collectionAvailableQtys - collection available qtys for sale
    * @param _collectionPrices - collectionn prices
    */
    function _setCollectionData(
        address _collectionAddress,
        address _saleBeneficiaryAddress,
        uint256 _collectionFee,
        uint256[] memory _collectionOptionIds,
        uint256[] memory _collectionAvailableQtys,
        uint256[] memory _collectionPrices
    ) internal {
        // emit ChangedCollectionBeneficiary(_collectionAddress, collectionBeneficiaries[_collectionAddress], _beneficiary);
        CollectionData storage collection = collectionsData[_collectionAddress];

        collection.saleBeneficiary = _saleBeneficiaryAddress;
        collection.collectionFee = _collectionFee;

        for (uint256 i = 0; i < _collectionOptionIds.length; i++) {
            collection.availableQtyPerOptionId[_collectionOptionIds[i]] = _collectionAvailableQtys[i];
            collection.pricePerOptionId[_collectionOptionIds[i]] = _collectionPrices[i];
        }

        emit SetCollectionData(_collectionAddress, _collectionOptionIds, _collectionAvailableQtys, _collectionPrices);
    }

    /**
    * @dev Validate if a user has balance and the contract has enough allowance
    * to use user's accepted token on his belhalf
    * @param _user - address of the user
    */
    function _requireBalance(address _user, uint256 _price) internal view {
        require(
            acceptedToken.balanceOf(_user) >= _price,
            "Insufficient funds"
        );
        require(
            acceptedToken.allowance(_user, address(this)) >= _price,
            "The contract is not authorized to use the accepted token on sender behalf"
        );
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;


interface IERC20 {
    function balanceOf(address from) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


interface IERC721Collection {
    function issueToken(address _beneficiary, string calldata _wearableId) external;
    function getWearableKey(string calldata _wearableId) external view returns (bytes32);
    function issued(bytes32 _wearableKey) external view returns (uint256);
    function maxIssuance(bytes32 _wearableKey) external view returns (uint256);
    function issueTokens(address[] calldata _beneficiaries, bytes32[] calldata _wearableIds) external;
    function owner() external view returns (address);
    function wearables(uint256 _index) external view returns (string memory);
    function wearablesCount() external view returns (uint256);
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

