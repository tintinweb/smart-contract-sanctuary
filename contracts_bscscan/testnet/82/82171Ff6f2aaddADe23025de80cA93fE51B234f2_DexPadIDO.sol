/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File contracts/IERC20.sol

//: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

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


// File contracts/Ownable.sol

//: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external view returns (address);

  function renounceManagement() external;

  function pushManagement( address newOwner_ ) external;

  function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}


// File contracts/SafeMath.sol

//: AGPL-3.0-or-later
pragma solidity ^0.8.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}


// File contracts/EnumerableSet.sol

//: MIT
// OpenZeppelin Contracts v4.3.2 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/TransferHelper.sol

//: GPL-2.0-or-later
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}


// File contracts/IDOLockForwarder.sol

//: UNLICENSED
// ALL RIGHTS RESERVED

/**
    This contract creates the lock on behalf of each presale. This contract will be whitelisted to bypass the flat rate 
    ETH fee. Please do not use the below locking code in your own contracts as the lock will fail without the ETH fee
*/

pragma solidity ^0.8.0;



interface IUniswapV2Locker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer, string memory logoUrl) external payable;
    function whitelistFeeAccount(address _user, bool _add) external ;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract IDOLockForwarder is Ownable {
    
    IUniswapV2Locker public DEXPAD_LOCKER;
    IUniswapV2Factory public UNI_FACTORY;
    
    constructor(address _uniswapV2Locker, address _uniswapFactory) {
        DEXPAD_LOCKER = IUniswapV2Locker(_uniswapV2Locker);
        UNI_FACTORY = IUniswapV2Factory(_uniswapFactory);
    }
    
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer, string memory logoUrl) external {
        address pair = UNI_FACTORY.getPair(address(_baseToken), address(_saleToken));
        if (pair == address(0)) {
            UNI_FACTORY.createPair(address(_baseToken), address(_saleToken));
            pair = UNI_FACTORY.getPair(address(_baseToken), address(_saleToken));
        }
        
        TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(pair), _saleAmount);
        IUniswapV2Pair(pair).mint(address(this));
        uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(address(this));
        require(totalLPTokensMinted != 0 , "LP creation failed");
    
        TransferHelper.safeApprove(pair, address(DEXPAD_LOCKER), totalLPTokensMinted);
        uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;
        DEXPAD_LOCKER.lockLPToken(pair, totalLPTokensMinted, unlock_date, payable(address(0)), true, _withdrawer,logoUrl);
    }
    
}


// File contracts/DexPadIDO.sol

//: AGPL-3.0-or-later
pragma solidity ^0.8.0;




interface ITokenLocker{
    function singleLock (address _token, address payable _owner, uint256 _amount, uint256 _startEmission, uint256 _endEmission, string memory _logoUrl) external;
    function editZeroFeeWhitelist (address _token, bool _add) external;
    function adminSetWhitelister(address _user, bool _add) external;
}

contract DexPadIDO is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Addresses{
        address DXP;
        address USDT;
        address PHOTON;
        address devAddress;
        address lockForwarder;
        address tokenLocker;
    }
    struct Status{
        uint8 initialized;
        uint8 whiteListEnabled;
        uint8 cancelled;
        uint8 finalized;
    }
    struct AmountInfo{
        uint256 remainingAmountOfDXP;
        uint256 totalWhiteListed;
        uint256 startOfSale; // in epoch
        uint256 endOfSale; // in epoch
        uint256 totalRaisedAmount; // in wei
        uint256 softCap; // in wei
        uint256 hardCap; // in wei
        uint256 dxpListingPrice; // in 100s of USDT, so 3 means 0.03 usdt
        uint256 photonListingPrice; // in 100s of USDT, so 1 means 0.01 usdt
        uint256 dxpLiquidity; // in 1000s so for 50% it is 500
        uint256 photonLiquidity;// in 1000s so for 50% it is 500
    }
    struct UnlockInfo{
        uint256 startEmission;
        uint256 endEmission;
        uint256 amountToUnlock;
    }
    struct ReArrangeInfo{
        address receiver;
        uint256 amount;
    }
    Addresses public addresses;
    Status public status;
    AmountInfo public amountInfo;
    UnlockInfo public unlockInfo;
    EnumerableSet.AddressSet buyers;
    mapping(address => uint256) public purchasedAmounts;
    mapping(address => uint256) public contributedAmounts;

    EnumerableSet.AddressSet whiteListedBuyers;

    constructor(
        address _DXP,
        address _USDT,
        address _PHOTON,
        address _IDOLockForwarder,
        address _tokenLocker,
        address _devAddress
    ) {
        require(_DXP != address(0));
        require(_USDT != address(0));
        require(_PHOTON != address(0));
        require(_IDOLockForwarder != address(0));
        require(_tokenLocker != address(0));

        addresses.DXP = _DXP;
        addresses.USDT = _USDT;
        addresses.PHOTON = _PHOTON;
        addresses.devAddress = _devAddress;
        addresses.lockForwarder = _IDOLockForwarder;
        addresses.tokenLocker = _tokenLocker;
        status.cancelled = 0;
        status.finalized = 0;
        status.whiteListEnabled = 1;
    }


    function saleStarted() public view returns (bool) {
        return status.initialized==1 && amountInfo.startOfSale <= block.timestamp;
    }
    function isWhitelisted(address buyer) public view returns (bool){
        return whiteListedBuyers.contains(buyer);
    }
    function reArrangeEntry(ReArrangeInfo[] memory _reArrangeInfo, uint256 checksum) public {
        require(status.finalized==0, 'only can claim after finalized');
        require(purchasedAmounts[msg.sender] > 0, 'not purchased');
        uint256 originalContributionAmount = contributedAmounts[msg.sender];
        uint256 calculatedChecksum = 0;
        for(uint16 i = 0; i < _reArrangeInfo.length; i++){
            calculatedChecksum += _reArrangeInfo[i].amount;
            uint256 purchaseShare = _calculateSaleQuote(_reArrangeInfo[i].amount);
            purchasedAmounts[_reArrangeInfo[i].receiver] = purchasedAmounts[_reArrangeInfo[i].receiver].add(purchaseShare);
            contributedAmounts[_reArrangeInfo[i].receiver] = contributedAmounts[_reArrangeInfo[i].receiver].add(_reArrangeInfo[i].amount);
            purchasedAmounts[msg.sender] = purchasedAmounts[msg.sender].sub(purchaseShare);
            contributedAmounts[msg.sender] = contributedAmounts[msg.sender].sub(_reArrangeInfo[i].amount);
            buyers.add(_reArrangeInfo[i].receiver);
        }
        require(calculatedChecksum <= checksum, 'checkSum mismatch');
        require(calculatedChecksum <= originalContributionAmount, 'amount mismatch');
    }

    function whiteListBuyers(address[] memory _buyers)
        external
        onlyOwner
        returns (bool)
    {
        require(saleStarted() == false, 'Already started');

        amountInfo.totalWhiteListed = amountInfo.totalWhiteListed.add(_buyers.length);

        for (uint256 i; i < _buyers.length; i++) {
            whiteListedBuyers.add(_buyers[i]);
        }

        return true;
    }
    function setWhitelistEnabled(uint8 _whiteListEnabled)external onlyOwner returns (bool){
        require(saleStarted() == false, 'Already started');
        status.whiteListEnabled = _whiteListEnabled;
        return true;
    }
    function initialize(
        uint256 _remainingAmountOfDXP,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _saleLength,
        uint256 _startOfSale,
        uint256 _unlockPercentage // in thousands so 150 equals to 15%
     ) external onlyOwner returns (bool) {
        require(status.initialized == 0, 'Already initialized');
        status.initialized = 1;
        amountInfo.remainingAmountOfDXP = _remainingAmountOfDXP;
        amountInfo.softCap = _softCap;
        amountInfo.hardCap = _hardCap;
        amountInfo.startOfSale = _startOfSale;
        amountInfo.endOfSale = _startOfSale.add(_saleLength);
        unlockInfo.amountToUnlock = _unlockPercentage;
        return true;
    }
    function setLiquidityAndPrice(        
        uint256 _dxpListingPrice, // in 100s of USDT, so 3 means 0.03 usdt
        uint256 _photonListingPrice, // in 100s of USDT, so 1 means 0.01 usdt
        uint256 _dxpLiquidity, // in 1000s so for 50% it is 500
        uint256 _photonLiquidity// in 1000s so for 50% it is 500
        )external onlyOwner returns (bool) {
        amountInfo.dxpListingPrice = _dxpListingPrice;
        amountInfo.photonListingPrice = _photonListingPrice;
        amountInfo.dxpLiquidity = _dxpLiquidity;
        amountInfo.photonLiquidity = _photonLiquidity;
        return true;
    }

    function purchaseDXP(uint256 _amountUSDT) external returns (bool) {
        require(saleStarted() == true, 'Not started');
        require(
            status.whiteListEnabled==0 || whiteListedBuyers.contains(msg.sender) == true,
            'Not whitelisted'
        );

        uint256 _purchaseAmount = _calculateSaleQuote(_amountUSDT);
        require(
            _purchaseAmount <= amountInfo.remainingAmountOfDXP,
            'Not enough DXP left'
        );
        amountInfo.remainingAmountOfDXP = amountInfo.remainingAmountOfDXP.sub(_purchaseAmount);

        TransferHelper.safeTransferFrom(addresses.USDT,msg.sender, address(this), _amountUSDT);
        
        amountInfo.totalRaisedAmount = amountInfo.totalRaisedAmount.add(_amountUSDT);
        purchasedAmounts[msg.sender] += _purchaseAmount;
        contributedAmounts[msg.sender] += _amountUSDT;
        buyers.add(msg.sender);


        return true;
    }

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        pure
        returns (uint256)
    {
       
        return paymentAmount_.mul(10**18).div(15*(10**15));
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        pure
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    /// @dev Only Emergency Use
    /// cancel the IDO and return the funds to all buyer
    function cancel() external onlyOwner {
        status.cancelled = 1;
        amountInfo.startOfSale = 99999999999;
    }

    function withDrawEmergencyFund(address token, address payable receiver) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, balance);
    }

    function withdraw() external {
        require(status.cancelled==1, 'ido is not cancelled');
        uint256 amount = contributedAmounts[msg.sender];
        TransferHelper.safeTransfer(addresses.USDT, msg.sender, amount);
    }
    function getLockedAndUnlockedAmount(address _recipient) external view returns (uint256,uint256, uint256){
        
        require(status.finalized==1, 'only can claim after finalized');
        require(purchasedAmounts[_recipient] > 0, 'not purchased');
        uint256 totalAmount = purchasedAmounts[_recipient];
        uint256 unlockedAmount = totalAmount.mul(unlockInfo.amountToUnlock).div(1000);
        uint256 lockedAmount = totalAmount.sub(unlockedAmount);
        return (unlockedAmount,lockedAmount, IERC20(addresses.DXP).balanceOf(address(this)));
    }
    function claim(address _recipient) external {
        require(status.finalized==1, 'only can claim after finalized');
        require(purchasedAmounts[_recipient] > 0, 'not purchased');
        uint256 totalAmount = purchasedAmounts[_recipient];
        uint256 unlockedAmount = totalAmount.mul(unlockInfo.amountToUnlock).div(1000);
        uint256 lockedAmount = totalAmount.sub(unlockedAmount);
        TransferHelper.safeApprove(addresses.DXP, _recipient, unlockedAmount);
        TransferHelper.safeTransfer(addresses.DXP,payable( _recipient), unlockedAmount);
        TransferHelper.safeApprove(addresses.DXP, addresses.tokenLocker, lockedAmount+1);
        require(lockedAmount < IERC20(addresses.DXP).balanceOf(address(this)), 'locked amount is gt balance');
        ITokenLocker(addresses.tokenLocker).singleLock(addresses.DXP, payable(_recipient),  lockedAmount,unlockInfo.startEmission, unlockInfo.endEmission, "");
        purchasedAmounts[_recipient] = 0;
    }

    function finalize() external onlyOwner {
        require(amountInfo.totalRaisedAmount > amountInfo.softCap, 'It must reach softcap');
        require(addresses.lockForwarder!=address(0), 'IDOLockForwarder is not deployed');
       
        uint256 usdtForDxpLP = amountInfo.totalRaisedAmount.mul(amountInfo.dxpLiquidity).div(1000);
        uint256 usdtForPhotonLP = amountInfo.totalRaisedAmount.mul(amountInfo.photonLiquidity).div(1000);
        uint256 DXPAmount = usdtForDxpLP.mul(100).div(amountInfo.dxpListingPrice);
        uint256 PhotonAmount = usdtForPhotonLP.div(100).div(amountInfo.photonListingPrice);
        TransferHelper.safeApprove(addresses.DXP, addresses.lockForwarder, DXPAmount);
        TransferHelper.safeApprove(addresses.PHOTON,  addresses.lockForwarder, PhotonAmount);
        TransferHelper.safeApprove(addresses.USDT,  addresses.lockForwarder, usdtForDxpLP.add(usdtForPhotonLP));
        IDOLockForwarder(addresses.lockForwarder).lockLiquidity(IERC20(addresses.USDT), IERC20(addresses.DXP), usdtForDxpLP, DXPAmount,block.timestamp.add(60) , payable(addresses.devAddress),"");
        IDOLockForwarder(addresses.lockForwarder).lockLiquidity(IERC20(addresses.USDT), IERC20(addresses.PHOTON), usdtForPhotonLP, PhotonAmount,block.timestamp.add(120) , payable(addresses.devAddress),"");
                
        //setup start and end emmission time
        unlockInfo.startEmission = block.timestamp;
        unlockInfo.endEmission = block.timestamp.add(60);
        //unlockInfo.endEmission = block.timestamp.add(60*60*24*30*18);

        //TODO remaining balance of USDT
        uint256 devUSDTAmount = amountInfo.totalRaisedAmount.mul(uint256(1000).sub(amountInfo.dxpLiquidity).sub(amountInfo.photonLiquidity)).div(1000);
        
        uint256 remainingPhoton = IERC20(addresses.PHOTON).balanceOf(address(this));
        uint256 remainingDXP = IERC20(addresses.DXP).balanceOf(address(this)).sub(amountInfo.remainingAmountOfDXP);
        TransferHelper.safeApprove(addresses.USDT, addresses.devAddress, devUSDTAmount);
        TransferHelper.safeApprove(addresses.PHOTON, addresses.devAddress, remainingPhoton);
        TransferHelper.safeApprove(addresses.DXP, addresses.devAddress, remainingDXP);
        TransferHelper.safeTransfer(addresses.PHOTON, addresses.devAddress, remainingPhoton);
        TransferHelper.safeTransfer(addresses.DXP, addresses.devAddress, remainingDXP);
        status.finalized = 1;

    }
}