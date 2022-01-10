/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.
/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)
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

// 
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
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

// 
interface IWineEnums {
    enum BottleSize {Piccolo, Demi, Standard, Magnum, DoubleMagnum, Jeroboam, Rehoboam, Imperial, Salmanazar, Balthazar, Nebuchadnezzar, Solomon}
    enum WineType {Red, White, Rose, Sparkling, Dessert, Fortified}

    struct Wine {
        uint256 tokenId;
        address brand;
        string title;
        WineType wineType;
        BottleSize bottleSize;
        string classification;
        string vintage;
        string country;
        string region;
        string volume; // todo remove?
        string condition;
        string label;
        string imageUrl;
    }

    struct Case {
        uint256 caseId;
        uint256[] tokenIds;
        uint256[] amounts;
        BottleSize bottleSize;
        uint256 numberOfBottles;
        uint256 storagePaidTill;
        address tenant;
    }

    struct Location {
        string addressLine1;
        string addressLine2;
        string city;
        string province;
        string countryCode;
        string postalCode;
        uint256 lng;
        uint256 lat;
    }

    //enum Currency {EUR, USD, ETH, MATIC}
}

// 
interface IWineToken is IWineEnums {

    function getWine(uint256 tokenId_) external;

    function getBrand(uint256 tokenId_) external returns (address);

    function getNumberOfBottles(uint256 tokenId_, address cellar_, address owner_) external view returns (uint256);

    function mint(address to_, address cellar_, uint256 tokenId_, uint256 amount_, bytes memory data_) external;

    function mintBatch(address to_, address cellar_, uint256[] memory tokenIds_, uint256[] memory amounts_, bytes memory data_) external;

    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external;

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory tokenIds_, uint256[] memory amounts_, bytes memory data_) external;

    function registerWine() external returns (uint256);

    function unregisterWine(uint256 tokenId_) external;

}

// 
interface IWineOracle {

    function getLatestPrice() external view returns (int, uint8);
}

// 
interface IWineFeeManager {

    function getFee() external view returns (uint256);
}

// 
contract WineOrdersHandler {

    using SafeMath for uint256;

    enum OrderType {Ask, Bid}
    enum OrderStatus {Dummy, Open, Pending, Closed, Canceled}

    struct Order {
        uint256 orderId;
        OrderType orderType;
        address contractor;
        uint256 tokenId;
        uint256 numberOfBottles;
        uint256 numberOfBottlesInCase;
        address cellar;
        string currency; // currently only "USD" and "EUR"
        uint256 pricePerBottle18;
        uint256 createdAt;
        uint256 validTill;
        OrderStatus status;
    }

    struct Deal {
        uint256 dealId;
        uint256 askOrderId;
        uint256 bidOrderId;
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 numberOfBottles;
        uint256 numberOfBottlesInCase;
        address cellar;
        string currency; // currently only "USD" and "EUR"
        uint256 pricePerBottle18;
        uint256 createdAt;
    }


    function getBottlePriceUSD18(Order memory order_) internal view virtual returns (uint256){
        return order_.pricePerBottle18;
    }

    // quickSort sorting algorithm implementation
    function _quickSortByPrice(Order[] memory orders_, int left_, int right_) internal view {
        int i = left_;
        int j = right_;

        if (i == j) return;

        uint256 pivotBottlePriceUSD18 = getBottlePriceUSD18(orders_[uint(left_ + (right_ - left_) / 2)]);

        while (i <= j) {
            while (getBottlePriceUSD18(orders_[uint(i)]) < pivotBottlePriceUSD18) i++;

            while (pivotBottlePriceUSD18 < getBottlePriceUSD18(orders_[uint(j)])) j--;

            if (i <= j) {
                (orders_[uint(i)], orders_[uint(j)]) = (orders_[uint(j)], orders_[uint(i)]);
                i++;
                j--;
            }
        }

        if (left_ < j)
            _quickSortByPrice(orders_, left_, j);

        if (i < right_)
            _quickSortByPrice(orders_, i, right_);
    }

    function _countBottles(Order[] memory orders_) internal pure returns (uint256){
        uint256 n = 0;

        for (uint a = 0; a < orders_.length; a++) {
            if (orders_[a].status != OrderStatus.Open) {
                continue;
            }

            n = n.add(orders_[a].numberOfBottles);
        }

        return n;
    }

    function _setOrderStatus(Order[] storage orders_, uint256 orderId_, OrderStatus status_) internal returns (bool) {
        for (uint i = 0; i < orders_.length; i++) {
            if (orders_[i].orderId == orderId_) {
                orders_[i].status = status_;
                return true;
            }
        }

        return false;
    }

    function _getOpenOrders(Order[] memory in_) internal pure returns (Order[] memory){
        Order[] memory out = new Order[](in_.length);

        uint c = 0;

        for (uint i = 0; i < in_.length; i++) {
            if (in_[i].status != OrderStatus.Open) {
                assembly {mstore(out, sub(mload(out), 1))}
                continue;
            }

            out[c] = in_[i];
            c++;
        }

        return out;
    }

    enum Price {Max, Min, Below, Above}

    function _getPriceUSD18(Order[] memory orders_, Price mm_) internal view returns (uint256){
        uint256 price;

        for (uint i = 0; i < orders_.length; i++) {
            uint256 p = getBottlePriceUSD18(orders_[i]);

            if (price == 0) {
                price = p;
                continue;
            }

            if ((mm_ == Price.Min && p < price) || (mm_ == Price.Max && p > price)) {
                price = p;
            }
        }

        return price;
    }

    function _getOrders(Order[] memory in_, Price mm_, uint256 price_) internal view returns (Order[] memory){
        Order[] memory out = new Order[](in_.length);

        uint c = 0;

        for (uint i = 0; i < in_.length; i++) {
            uint256 p = getBottlePriceUSD18(in_[i]);

            if ((mm_ == Price.Below && p <= price_) || (mm_ == Price.Above && p >= price_)) {
                out[c] = in_[i];
                c++;
            } else {
                assembly {mstore(out, sub(mload(out), 1))}
            }
        }

        return out;
    }

    function _removeOrders(Order[] storage orders_, OrderStatus status_, uint256 orderValidityPeriodSec_) internal {
        Order memory removeMe;
        bool runAgain = false;

        for (uint i = 0; i < orders_.length; i++) {

            if ((orderValidityPeriodSec_ > 0 &&
                (orders_[i].contractor == msg.sender       // user may have only one active bid order per wine token id
                || orders_[i].validTill < block.timestamp
                || orders_[i].createdAt + orderValidityPeriodSec_ < block.timestamp))
                || orders_[i].status == status_)
            {
                // save it to a variable
                removeMe = orders_[i];
                // overwrite it with the last struct
                orders_[i] = orders_[orders_.length - 1];
                // overwrite the last struct with the struct we want to delete
                orders_[orders_.length - 1] = removeMe;
                // make sure we have not missed anything
                runAgain = true;
                // we remove one Order at a time
                break;
            }
        }

        // remove the last struct (which should be the one we want to delete)
        orders_.pop();

        if (runAgain) {
            // Check if any other Order needs to be removed
            _removeOrders(orders_, status_, orderValidityPeriodSec_);
        }
    }


    function _calculatePriceOfTheFirstNBottlesUSD18(Order[] memory orders_, uint256 numberOfBottles_) internal view returns (uint256){

        uint256 amountUSD18 = 0;
        uint256 bottlesCounter = 0;

        for (uint i = 0; i < orders_.length; i++) {
            if (bottlesCounter + orders_[i].numberOfBottles >= numberOfBottles_) {
                amountUSD18 += getBottlePriceUSD18(orders_[i]).mul(numberOfBottles_ - bottlesCounter);
                break;
            } else {
                amountUSD18 += getBottlePriceUSD18(orders_[i]).mul(orders_[i].numberOfBottles);
            }

            bottlesCounter += orders_[i].numberOfBottles;
        }

        return amountUSD18;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b? a: b;
    }
}

// 
// todo register users https://github.com/f-o-a-m/parking-dao/tree/master/contracts
// todo https://github.com/f-o-a-m/parking-dao/blob/master/contracts/ParkingAuthority.sol
contract WineMarketplace is WineOrdersHandler, Ownable {

    using Address for address;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _orderIdTracker;
    Counters.Counter private _dealIdTracker;

    // Wine Token ID => Ask Orders
    mapping(uint256 => Order[]) private _tokenIdAskOrders;

    // Wine Token ID => Bid Orders
    mapping(uint256 => Order[]) private _tokenIdBidOrders;

    // Deals to be processed
    Deal[] private _deals;

    // Wine Token ID => Last Price in USD
    mapping(uint256 => uint256) private _latestPricesUSD18;

    // Wine Token ID => Last Price in EUR
    mapping(uint256 => uint256) private _latestPricesEUR18;

    uint256 private _latestEURtoUSDRate18 = 1e18;

    uint256 private _bidOrderValidityPeriodSec = 2592000; // 30 days
    uint256 private _askOrderValidityPeriodSec = 157680000; // 5 years

    // user => ETH balance
    mapping(address => uint256) private _balance;

    // Deal ID => Locked ETH amount from bidder balance
    mapping(uint256 => uint256) private _dealPool;

    // Deal ID => Locked ETH fee amount from bidder balance
    mapping(uint256 => uint256) private _feePool;

    event ASK(Order order_);
    event BID(Order order_);
    event DEAL(Deal deal_);

    event DealDetails(Deal deal_);

    address _wineToken = address(0);
    address _feeManager = address(0);
    address _oracle = address(0);

    constructor (address wineToken_, address feeManager_, address oracle_){
        _wineToken = wineToken_;
        _feeManager = feeManager_;
        _oracle = oracle_;

        // start with 1
        _orderIdTracker.increment();
        _dealIdTracker.increment();
    }

    function setWineToken(address wineToken_) external onlyOwner {
        _wineToken = wineToken_;
    }

    function getWineToken() external view returns (address) {
        return _wineToken;
    }

    function setFeeManager(address feeManager_) external onlyOwner {
        _feeManager = feeManager_;
    }

    function getFeeManager() external view returns (address) {
        return _feeManager;
    }

    function setOracle(address oracle_) external onlyOwner {
        _oracle = oracle_;
    }

    function getOracle() external view returns (address) {
        return _oracle;
    }

    function setEURtoUSDRate18(uint256 latestEURtoUSDRate18_) external onlyOwner {
        _latestEURtoUSDRate18 = latestEURtoUSDRate18_;
    }

    function getEURtoUSDRate18() external view returns (uint256) {
        return _latestEURtoUSDRate18;
    }

    function setBidOrderValidityPeriodSec(uint256 bidOrderValidityPeriodSec_) external onlyOwner {
        _bidOrderValidityPeriodSec = bidOrderValidityPeriodSec_;
    }

    function setAskOrderValidityPeriodSec(uint256 askOrderValidityPeriodSec_) external onlyOwner {
        _askOrderValidityPeriodSec = askOrderValidityPeriodSec_;
    }

    function getBottlePriceUSD18(Order memory order_) internal view override returns (uint256){
        return strcmp(order_.currency, "EUR") ? order_.pricePerBottle18.mul(_latestEURtoUSDRate18).div(1e18) : order_.pricePerBottle18;
    }

    function strcmp(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function placeBidMarketOrder(uint256 tokenId_, uint256 numberOfBottles_, uint256 maxPricePerBottleUSD18_) external payable {

        _balance[msg.sender] = _balance[msg.sender].add(msg.value);

        Order memory bidOrder = Order({
            orderId : _orderIdTracker.current(),
            orderType : OrderType.Bid,
            contractor : msg.sender,
            tokenId : tokenId_,
            numberOfBottles : numberOfBottles_,
            numberOfBottlesInCase : 0,
            cellar : address(0),
            currency : "USD",
            pricePerBottle18 : maxPricePerBottleUSD18_,
            createdAt : block.timestamp,
            validTill : block.timestamp + _bidOrderValidityPeriodSec,
            status : OrderStatus.Open
        });

        this.bid(bidOrder);
    }

    function bid(Order memory bidOrder_) external {
        Order[] memory askOrders = _getOpenOrders(_tokenIdAskOrders[bidOrder_.tokenId]);

        if (bidOrder_.pricePerBottle18 > 0) {
            askOrders = _getOrders(askOrders, Price.Below, bidOrder_.pricePerBottle18);
        }

        uint256 availableBottles = _countBottles(askOrders);

        require(availableBottles >= bidOrder_.numberOfBottles, "Marketplace: not enough bottles on the market");

        _quickSortByPrice(askOrders, int(0), int(askOrders.length - 1));
        uint256 allBottlesPriceUSD18 = _calculatePriceOfTheFirstNBottlesUSD18(askOrders, bidOrder_.numberOfBottles);

        // ETH/USD oracle
        (int ethPrice, uint8 decimals) = IWineOracle(_oracle).getLatestPrice();
        uint256 ethPriceUSD18 = uint256(ethPrice).mul(1e18).div(10 ** decimals);

        uint256 allBottlesPriceETH18 = allBottlesPriceUSD18.div(ethPriceUSD18);

        uint256 fee = IWineFeeManager(_feeManager).getFee();

        require(allBottlesPriceETH18.mul(1e18 + fee).div(1e18) >= _balance[msg.sender], "Marketplace: insufficient funds");

        bidOrder_.contractor = msg.sender;
        bidOrder_.orderType = OrderType.Bid;
        bidOrder_.orderId = _orderIdTracker.current();
        bidOrder_.createdAt = block.timestamp;
        bidOrder_.status = OrderStatus.Open;

        _orderIdTracker.increment();

        _removeOrders(_tokenIdBidOrders[bidOrder_.tokenId], OrderStatus.Dummy, _bidOrderValidityPeriodSec);

        _tokenIdBidOrders[bidOrder_.tokenId].push(bidOrder_);

        emit BID(bidOrder_);

        uint256 fee18 = IWineFeeManager(_feeManager).getFee();

        findMatchingOrders(bidOrder_.tokenId, ethPriceUSD18, fee18);
    }

    function ask(Order memory askOrder_) external {
        uint256 ownedBottles = IWineToken(_wineToken).getNumberOfBottles(askOrder_.tokenId, askOrder_.cellar, msg.sender);
        require(ownedBottles > askOrder_.numberOfBottles, "Marketplace: not enough bottles");

        askOrder_.contractor = msg.sender;
        askOrder_.orderType = OrderType.Ask;
        askOrder_.orderId = _orderIdTracker.current();
        askOrder_.createdAt = block.timestamp;
        askOrder_.status = OrderStatus.Open;

        _orderIdTracker.increment();

        _removeOrders(_tokenIdAskOrders[askOrder_.tokenId], OrderStatus.Dummy, _askOrderValidityPeriodSec);

        _tokenIdAskOrders[askOrder_.tokenId].push(askOrder_);

        emit ASK(askOrder_);

        // ETH/USD oracle
        (int ethPrice, uint8 decimals) = IWineOracle(_oracle).getLatestPrice();
        uint256 ethPriceUSD18 = uint256(ethPrice).mul(1e18).div(10 ** decimals);

        uint256 fee18 = IWineFeeManager(_feeManager).getFee();

        findMatchingOrders(askOrder_.tokenId, ethPriceUSD18, fee18);
    }

    function getOrdersIntersection(uint256 tokenId_) internal view returns (Order[] memory, Order[] memory){
        Order[] memory bo = _getOpenOrders(_tokenIdBidOrders[tokenId_]);
        Order[] memory ao = _getOpenOrders(_tokenIdAskOrders[tokenId_]);

        Order[] memory bidOrders = _getOrders(bo, Price.Above, _getPriceUSD18(ao, Price.Min));
        Order[] memory askOrders = _getOrders(ao, Price.Below, _getPriceUSD18(bo, Price.Max));

        _quickSortByPrice(askOrders, int(0), int(askOrders.length - 1));

        return (bidOrders, askOrders);
    }

    function findMatchingOrders(uint256 tokenId_, uint256 ethPriceUSD18_, uint256 fee18_) internal {

        (Order[] memory bidOrders, Order[] memory askOrders) = getOrdersIntersection(tokenId_);

        if (bidOrders.length == 0 || askOrders.length == 0) {
            return;
        }

        for (uint b = 0; b < bidOrders.length; b++) {
            Order memory bidOrder = bidOrders[b];

            if (_balance[bidOrder.contractor] == 0) {
                continue;
            }

            uint256 bidPricePerBottleUSD18 = getBottlePriceUSD18(bidOrder);

            for (uint a = 0; a < askOrders.length; a++) {
                Order memory askOrder = askOrders[a];

                uint256 askPricePerBottleUSD18 = getBottlePriceUSD18(askOrder);

                if (askPricePerBottleUSD18 > bidPricePerBottleUSD18) {
                    // Ask orders are sorted, no need to continue
                    break;
                }

                uint256 dealAmountETH18 = askPricePerBottleUSD18
                    .mul(min(bidOrder.numberOfBottles, askOrder.numberOfBottles))
                    .div(ethPriceUSD18_);

                if (_balance[bidOrder.contractor] < dealAmountETH18.mul(1e18 + fee18_).div(1e18)) {
                    continue;
                }

                _setOrderStatus(_tokenIdAskOrders[tokenId_], askOrder.orderId, OrderStatus.Pending);
                _setOrderStatus(_tokenIdBidOrders[tokenId_], bidOrder.orderId, OrderStatus.Pending);

                uint256 dealId = makeDeal(askOrder, bidOrder);

                _balance[bidOrder.contractor] = _balance[bidOrder.contractor].sub(dealAmountETH18.mul(1e18 + fee18_).div(1e18));

                _dealPool[dealId] = dealAmountETH18;
                _feePool[dealId] = dealAmountETH18.mul(fee18_).div(1e18);

                findMatchingOrders(tokenId_, ethPriceUSD18_, fee18_);
            }
        }
    }


    function makeDeal(Order memory askOrder_, Order memory bidOrder_) internal returns (uint256) {

        uint256 numberOfBottles;

        if (askOrder_.numberOfBottles == bidOrder_.numberOfBottles) {
            numberOfBottles = askOrder_.numberOfBottles;
        }

        if (askOrder_.numberOfBottles > bidOrder_.numberOfBottles) {
            numberOfBottles = bidOrder_.numberOfBottles;
            updateOrder(askOrder_, bidOrder_.numberOfBottles);
        }

        if (askOrder_.numberOfBottles < bidOrder_.numberOfBottles) {
            numberOfBottles = askOrder_.numberOfBottles;
            updateOrder(bidOrder_, askOrder_.numberOfBottles);
        }

        Deal memory deal = Deal({
            dealId : _dealIdTracker.current(),
            askOrderId : askOrder_.orderId,
            bidOrderId : bidOrder_.orderId,
            seller : askOrder_.contractor,
            buyer : bidOrder_.contractor,
            tokenId : askOrder_.tokenId,
            numberOfBottles : numberOfBottles,
            numberOfBottlesInCase : askOrder_.numberOfBottlesInCase,
            cellar : askOrder_.cellar,
            currency : askOrder_.currency,
            pricePerBottle18 : askOrder_.pricePerBottle18,
            createdAt : block.timestamp
        });

        _deals.push(deal);

        emit DEAL(deal);

        _dealIdTracker.increment();

        return deal.dealId;
    }

    function updateOrder(Order memory oldOrder_, uint256 numberOfSoldBottles_) internal {

        Order memory order = Order({
            orderId : _orderIdTracker.current(),
            orderType : oldOrder_.orderType,
            contractor : oldOrder_.contractor,
            tokenId : oldOrder_.tokenId,
            numberOfBottles : oldOrder_.numberOfBottles - numberOfSoldBottles_,
            numberOfBottlesInCase : oldOrder_.numberOfBottlesInCase,
            cellar : oldOrder_.cellar,
            currency : oldOrder_.currency,
            pricePerBottle18 : oldOrder_.pricePerBottle18,
            createdAt : block.timestamp,
            validTill : oldOrder_.validTill,
            status : OrderStatus.Open
        });

        if (order.orderType == OrderType.Ask) {
            _tokenIdAskOrders[order.tokenId].push(order);
            emit ASK(order);
        }

        if (order.orderType == OrderType.Bid) {
            _tokenIdBidOrders[order.tokenId].push(order);
            emit BID(order);
        }

        _orderIdTracker.increment();
    }

    function confirmDeal(uint256 dealId_) external onlyOwner {

        Deal memory deal = getDeal(dealId_);

        IWineToken(_wineToken).safeTransferFrom(deal.seller, deal.buyer, deal.tokenId, deal.numberOfBottles, "");

        uint256 fee = _feePool[dealId_];
        _feePool[dealId_] = 0;
        payable(_feeManager).transfer(fee);

        // todo remove pending orders

        uint256 dealAmount = _dealPool[dealId_];
        _dealPool[dealId_] = 0;

        payable(deal.seller).transfer(dealAmount);
    }

    function cancelDeal(uint256 dealId_) external onlyOwner {
        // todo revert all
    }

    function getDeal(uint256 dealId_) internal view returns (Deal memory) {
        for (uint i = 0; i < _deals.length; i++) {
            if (_deals[i].dealId == dealId_) {
                return _deals[i];
            }
        }

        revert("Marketplace: deal not found");
    }

    function getDealByIndex(uint256 index_) external {
        emit DealDetails(_deals[index_]);
    }

    function balanceOf(address user_) external view returns (uint256) {
        require(user_ != address(0), "Marketplace: balance query for the zero address");
        return _balance[user_];
    }

    function deposit() external payable {
        _balance[msg.sender] = _balance[msg.sender].add(msg.value);
    }

    function withdraw() external {
        uint256 amount = _balance[msg.sender];
        _balance[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }

}