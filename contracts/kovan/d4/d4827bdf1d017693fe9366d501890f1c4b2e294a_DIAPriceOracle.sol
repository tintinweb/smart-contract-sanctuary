/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT and Apache License, Version 2.0

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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

// File: contracts/interfaces/external/IDIAOracle.sol

pragma solidity 0.6.10;

interface IDIAOracle {
        function getCoinInfo(string memory name) external view returns (uint256, uint256, uint256, string memory);
}

// File: contracts/interfaces/IPriceOracle.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    
*/
pragma solidity 0.6.10;

/**
 * @title IPriceOracle
 * @author Set Protocol
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {

    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);
    function masterQuoteAsset() external view returns (address);
}

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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

// File: contracts/protocol/DIAPriceOracle.sol

pragma solidity 0.6.10;





/**
 * @title DIAPriceOracle
 *
 * Contract that returns the price for any given asset pair. Price is retrieved directly from a DIA oracle.
 * Note: Prices are returned in preciseUnits (i.e. 18 decimals of precision)
 */
contract DIAPriceOracle is Ownable, IPriceOracle {
    using SafeMath for uint256;
    // DIA oracle returns 5 decimals, and the result requires 18
    uint256 public constant DECIMAL_CORRECTION = 10**13;
    uint256 public constant WAD = 10**18;

    /* ============ State Variables ============ */

    address public override immutable masterQuoteAsset;
    IDIAOracle public immutable underlyingOracle;
    mapping (address => mapping (address => string)) private  priceIdentifiers;

    /* ============ Events ============ */

    event PairAdded(address indexed _assetOne, address indexed _assetTwo, string identifier, string previous);
    event PairRemoved(address indexed _assetOne, address indexed _assetTwo, string identifier);

    /* ============ Constructor ============ */

    constructor( address _masterQuoteAsset, address _underlyingOracle) public {
      masterQuoteAsset =_masterQuoteAsset;
      underlyingOracle = IDIAOracle(_underlyingOracle);
    }

    /* ============ External Functions ============ */

    /**
    * Get the price from the DIAOracle, and return it with the precision
    * expected by the Set valuer.
    * If the direct price isn't available, the inverse to it is queried.
    * Reverts if there is no price identifier registered for that pair
    */

    function getPrice(address _assetOne, address _assetTwo) external override view returns (uint256) {
        uint256 price;
        (bool inverse, string memory identifier) = getPriceIdentifier(_assetOne,_assetTwo);
        (price,,,) = underlyingOracle.getCoinInfo(identifier);

        if (inverse) {
          return WAD.mul(WAD).div(price.mul(DECIMAL_CORRECTION));
        } else {
          return price.mul(DECIMAL_CORRECTION);
        }
    }

    /**
    * Owner-only function to add a price identifier to call the DIAOracle with,
    * when in need for a price for the pair determined by (_assetOne,
    * _assetTwo)
    * If the pair is already registered, it's overwritten.
    */

    function addPair(address _assetOne, address _assetTwo, string memory identifier) onlyOwner external {
      emit PairAdded(_assetOne, _assetTwo, identifier, priceIdentifiers[_assetOne][_assetTwo]);
      priceIdentifiers[_assetOne][_assetTwo] = identifier;
    }

    /**
    * Owner-only function to remove support for an asset pair
    * reverts if the pair isn't registered.
    */

    function removePair(address _assetOne, address _assetTwo) onlyOwner external {
      string storage identifier = priceIdentifiers[_assetOne][_assetTwo];
      require(bytes(identifier).length != 0,"Pair does not exist");
      emit PairRemoved(_assetOne, _assetTwo, identifier);
      delete(priceIdentifiers[_assetOne][_assetTwo]);
    }

    /**
    * Retrieves the price identifier (used to fetch the price from the DIA
    * oracle)for an asset pair, and a flag indicating if the price is the
    * inverse of what's desired. Reverts if no regular or inverse price
    * identifier is found
    */

    function getPriceIdentifier (address _assetOne, address _assetTwo) public view returns (bool inverse, string memory identifier){
        identifier = priceIdentifiers[_assetOne][_assetTwo];
        inverse = false;
        if (bytes(identifier).length == 0){
            identifier = priceIdentifiers[_assetTwo][_assetOne];
            inverse = true;
        }
        require(bytes(identifier).length != 0,"Price feed not available");
    }
}