/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;
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

pragma solidity >=0.6.0 <0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;
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

pragma solidity >=0.5.0;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

pragma solidity >=0.6.0 <0.8.0;
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

pragma solidity 0.6.12;
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
    
    // sends ETH or an erc20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isERC20) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
}

/********************************************************************************************/
/*                                  Presale Contract                                        */
/********************************************************************************************/
/*Allows a decentralised presale to take place, and on success creates a uniswap pair and locks liquidity on Unicrypt.
  B_TOKEN, or base token, is the token the presale attempts to raise. (Usally ETH).
  S_TOKEN, or sale token, is the token being sold, which investors buy with the base token.
  If the base currency is set to the WETH9 address, the presale is in ETH.
  Otherwise it is for an ERC20 token - such as DAI, USDC, WBTC etc.
  For the Base token - It is advised to only use tokens such as ETH (WETH), DAI, USDC or tokens that have no rebasing, or complex fee on transfers. 1 token should ideally always be 1 token.
  Token withdrawls are done on a percent of total contribution basis (opposed to via a hardcoded 'amount'). This allows 
  fee on transfer, rebasing, or any magically changing balances to still work for the Sale token.*/
/********************************************************************************************/
pragma solidity 0.6.12;
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPresaleLockForwarder {
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external;
    function uniswapPairIsInitialised (address _token0, address _token1) external view returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getRound1Length () external view returns (uint256);
    function userHoldsSufficientRound1Token (address _user) external view returns (bool);
    function referrerIsValid(address _referrer) external view returns (bool);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getReferralFee () external view returns (uint256);
    function getEthCreationFee () external view returns (uint256);
}

contract Presale01 is ReentrancyGuard {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  
  /// @notice Presale Contract Version, used to choose the correct ABI to decode the contract
  uint256 public CONTRACT_VERSION = 2;
  
  struct PresaleInfo {
    address payable PRESALE_OWNER;
    IERC20 S_TOKEN; // sale token
    IERC20 B_TOKEN; // base token // usually WETH (ETH)
    uint256 TOKEN_PRICE; // 1 base token = ? s_tokens, fixed price
    uint256 MAX_SPEND_PER_BUYER; // maximum base token BUY amount per account
    uint256 AMOUNT; // the amount of presale tokens up for presale
    uint256 HARDCAP;
    uint256 SOFTCAP;
    uint256 LIQUIDITY_PERCENT; // divided by 1000
    uint256 LISTING_RATE; // fixed rate at which the token will list on uniswap
    uint256 START_BLOCK;
    uint256 END_BLOCK;
    uint256 LOCK_PERIOD; // unix timestamp -> e.g. 2 weeks
    bool PRESALE_IN_ETH; // if this flag is true the presale is raising ETH, otherwise an ERC20 token such as DAI
  }
  
  struct PresaleFeeInfo {
    uint256 UNICRYPT_BASE_FEE; // divided by 1000
    uint256 UNICRYPT_TOKEN_FEE; // divided by 1000
    uint256 REFERRAL_FEE; // divided by 1000
    address payable BASE_FEE_ADDRESS;
    address payable TOKEN_FEE_ADDRESS;
    address payable REFERRAL_FEE_ADDRESS; // if this is not address(0), there is a valid referral
  }
  
  struct PresaleStatus {
    bool WHITELIST_ONLY; // if set to true only whitelisted members may participate
    bool LP_GENERATION_COMPLETE; // final flag required to end a presale and enable withdrawls
    bool FORCE_FAILED; // set this flag to force fail the presale
    uint256 TOTAL_BASE_COLLECTED; // total base currency raised (usually ETH)
    uint256 TOTAL_TOKENS_SOLD; // total presale tokens sold
    uint256 TOTAL_TOKENS_WITHDRAWN; // total tokens withdrawn post successful presale
    uint256 TOTAL_BASE_WITHDRAWN; // total base tokens withdrawn on presale failure
    uint256 ROUND1_LENGTH; // in blocks
    uint256 NUM_BUYERS; // number of unique participants
  }

  struct BuyerInfo {
    uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
    uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
  }
  
  PresaleInfo public PRESALE_INFO;
  PresaleFeeInfo public PRESALE_FEE_INFO;
  PresaleStatus public STATUS;
  address public PRESALE_GENERATOR;
  IPresaleLockForwarder public PRESALE_LOCK_FORWARDER;
  IPresaleSettings public PRESALE_SETTINGS;
  address UNICRYPT_DEV_ADDRESS;
  IUniswapV2Factory public UNI_FACTORY;
  IWETH public WETH;
  mapping(address => BuyerInfo) public BUYERS;
  EnumerableSet.AddressSet private WHITELIST;

  constructor(address _presaleGenerator) public {
    PRESALE_GENERATOR = _presaleGenerator;
    UNI_FACTORY = IUniswapV2Factory(0x9DdE6BbE3933696955ab0C79810804B9e3B08a41);
    WETH = IWETH(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    PRESALE_SETTINGS = IPresaleSettings(0x9a1767c3B8aA75B726b8D56a5Ee1ab5ED961d16C);
    PRESALE_LOCK_FORWARDER = IPresaleLockForwarder(0x2Ba51A572193f0E7045C766b50Bce40fa3C24784);
    UNICRYPT_DEV_ADDRESS = 0x96D82296ef04e42Ae3a1dE611445d3EE9486d5C3;
  }
  
  function init1 (
    address payable _presaleOwner, 
    uint256 _amount,
    uint256 _tokenPrice, 
    uint256 _maxEthPerBuyer, 
    uint256 _hardcap, 
    uint256 _softcap,
    uint256 _liquidityPercent,
    uint256 _listingRate,
    uint256 _startblock,
    uint256 _endblock,
    uint256 _lockPeriod
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      PRESALE_INFO.PRESALE_OWNER = _presaleOwner;
      PRESALE_INFO.AMOUNT = _amount;
      PRESALE_INFO.TOKEN_PRICE = _tokenPrice;
      PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxEthPerBuyer;
      PRESALE_INFO.HARDCAP = _hardcap;
      PRESALE_INFO.SOFTCAP = _softcap;
      PRESALE_INFO.LIQUIDITY_PERCENT = _liquidityPercent;
      PRESALE_INFO.LISTING_RATE = _listingRate;
      PRESALE_INFO.START_BLOCK = _startblock;
      PRESALE_INFO.END_BLOCK = _endblock;
      PRESALE_INFO.LOCK_PERIOD = _lockPeriod;
  }
  
  function init2 (
    IERC20 _baseToken,
    IERC20 _presaleToken,
    uint256 _unicryptBaseFee,
    uint256 _unicryptTokenFee,
    uint256 _referralFee,
    address payable _baseFeeAddress,
    address payable _tokenFeeAddress,
    address payable _referralAddress
    ) external {
          
      require(msg.sender == PRESALE_GENERATOR, 'FORBIDDEN');
      // require(!PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(_presaleToken), address(_baseToken)), 'PAIR INITIALISED');
      
      PRESALE_INFO.PRESALE_IN_ETH = address(_baseToken) == address(WETH);
      PRESALE_INFO.S_TOKEN = _presaleToken;
      PRESALE_INFO.B_TOKEN = _baseToken;
      PRESALE_FEE_INFO.UNICRYPT_BASE_FEE = _unicryptBaseFee;
      PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE = _unicryptTokenFee;
      PRESALE_FEE_INFO.REFERRAL_FEE = _referralFee;
      
      PRESALE_FEE_INFO.BASE_FEE_ADDRESS = _baseFeeAddress;
      PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
      PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS = _referralAddress;
      STATUS.ROUND1_LENGTH = PRESALE_SETTINGS.getRound1Length();
  }
  
  modifier onlyPresaleOwner() {
    require(PRESALE_INFO.PRESALE_OWNER == msg.sender, "NOT PRESALE OWNER");
    _;
  }
  
  function presaleStatus () public view returns (uint256) {
    if (STATUS.FORCE_FAILED) {
      return 3; // FAILED - force fail
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED < PRESALE_INFO.SOFTCAP)) {
      return 3; // FAILED - softcap not met by end block
    }
    if (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.HARDCAP) {
      return 2; // SUCCESS - hardcap met
    }
    if ((block.number > PRESALE_INFO.END_BLOCK) && (STATUS.TOTAL_BASE_COLLECTED >= PRESALE_INFO.SOFTCAP)) {
      return 2; // SUCCESS - endblock and soft cap reached
    }
    if ((block.number >= PRESALE_INFO.START_BLOCK) && (block.number <= PRESALE_INFO.END_BLOCK)) {
      return 1; // ACTIVE - deposits enabled
    }
    return 0; // QUED - awaiting start block
  }
  
  // accepts msg.value for eth or _amount for ERC20 tokens
  function userDeposit (uint256 _amount) external payable nonReentrant {
    require(presaleStatus() == 1, 'NOT ACTIVE'); // ACTIVE
    // Presale Round 1 - require participant to hold a certain token and balance
    bool userHoldsUnicryptTokens = PRESALE_SETTINGS.userHoldsSufficientRound1Token(msg.sender);
    if (block.number < PRESALE_INFO.START_BLOCK + STATUS.ROUND1_LENGTH) { // 276 blocks = 1 hour
        require(userHoldsUnicryptTokens, 'INSUFFICENT ROUND 1 TOKEN BALANCE');
    } else if (STATUS.WHITELIST_ONLY && !userHoldsUnicryptTokens) {
      // Round 2
      require(WHITELIST.contains(msg.sender), 'NOT WHITELISTED');
    }
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 amount_in = PRESALE_INFO.PRESALE_IN_ETH ? msg.value : _amount;
    uint256 allowance = PRESALE_INFO.MAX_SPEND_PER_BUYER.sub(buyer.baseDeposited);
    uint256 remaining = PRESALE_INFO.HARDCAP - STATUS.TOTAL_BASE_COLLECTED;
    allowance = allowance > remaining ? remaining : allowance;
    if (amount_in > allowance) {
      amount_in = allowance;
    }
    uint256 tokensSold = amount_in.mul(PRESALE_INFO.TOKEN_PRICE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    require(tokensSold > 0, 'ZERO TOKENS');
    if (buyer.baseDeposited == 0) {
        STATUS.NUM_BUYERS++;
    }
    buyer.baseDeposited = buyer.baseDeposited.add(amount_in);
    buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
    STATUS.TOTAL_BASE_COLLECTED = STATUS.TOTAL_BASE_COLLECTED.add(amount_in);
    STATUS.TOTAL_TOKENS_SOLD = STATUS.TOTAL_TOKENS_SOLD.add(tokensSold);
    
    // return unused ETH
    if (PRESALE_INFO.PRESALE_IN_ETH && amount_in < msg.value) {
      msg.sender.transfer(msg.value.sub(amount_in));
    }
    // deduct non ETH token from user
    if (!PRESALE_INFO.PRESALE_IN_ETH) {
      TransferHelper.safeTransferFrom(address(PRESALE_INFO.B_TOKEN), msg.sender, address(this), amount_in);
    }
  }
  
  // withdraw presale tokens
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawTokens () external nonReentrant {
    require(STATUS.LP_GENERATION_COMPLETE, 'AWAITING LP GENERATION');
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 tokensRemainingDenominator = STATUS.TOTAL_TOKENS_SOLD.sub(STATUS.TOTAL_TOKENS_WITHDRAWN);
    uint256 tokensOwed = PRESALE_INFO.S_TOKEN.balanceOf(address(this)).mul(buyer.tokensOwed).div(tokensRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_TOKENS_WITHDRAWN = STATUS.TOTAL_TOKENS_WITHDRAWN.add(buyer.tokensOwed);
    buyer.tokensOwed = 0;
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), msg.sender, tokensOwed);
  }
  
  // on presale failure
  // percentile withdrawls allows fee on transfer or rebasing tokens to still work
  function userWithdrawBaseTokens () external nonReentrant {
    require(presaleStatus() == 3, 'NOT FAILED'); // FAILED
    BuyerInfo storage buyer = BUYERS[msg.sender];
    uint256 baseRemainingDenominator = STATUS.TOTAL_BASE_COLLECTED.sub(STATUS.TOTAL_BASE_WITHDRAWN);
    uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
    require(tokensOwed > 0, 'NOTHING TO WITHDRAW');
    STATUS.TOTAL_BASE_WITHDRAWN = STATUS.TOTAL_BASE_WITHDRAWN.add(buyer.baseDeposited);
    buyer.baseDeposited = 0;
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), msg.sender, tokensOwed, !PRESALE_INFO.PRESALE_IN_ETH);
  }
  
  // on presale failure
  // allows the owner to withdraw the tokens they sent for presale & initial liquidity
  function ownerWithdrawTokens () external onlyPresaleOwner {
    require(presaleStatus() == 3); // FAILED
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_INFO.PRESALE_OWNER, PRESALE_INFO.S_TOKEN.balanceOf(address(this)));
  }
  

  // Can be called at any stage before or during the presale to cancel it before it ends.
  // If the pair already exists on uniswap and it contains the presale token as liquidity 
  // the final stage of the presale 'addLiquidity()' will fail. This function 
  // allows anyone to end the presale prematurely to release funds in such a case.
  function forceFailIfPairExists () external {
    require(!STATUS.LP_GENERATION_COMPLETE && !STATUS.FORCE_FAILED);
    if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
    }
  }
  
  // if something goes wrong in LP generation
  function forceFailByUnicrypt () external {
      require(msg.sender == UNICRYPT_DEV_ADDRESS);
      STATUS.FORCE_FAILED = true;
  }
  
  // on presale success, this is the final step to end the presale, lock liquidity and enable withdrawls of the sale token.
  // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
  // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to 
  // the presale parameters and fixed prices.
  function addLiquidity() external nonReentrant {
    require(!STATUS.LP_GENERATION_COMPLETE, 'GENERATION COMPLETE');
    require(presaleStatus() == 2, 'NOT SUCCESS'); // SUCCESS
    // Fail the presale if the pair exists and contains presale token liquidity
    if (PRESALE_LOCK_FORWARDER.uniswapPairIsInitialised(address(PRESALE_INFO.S_TOKEN), address(PRESALE_INFO.B_TOKEN))) {
        STATUS.FORCE_FAILED = true;
        return;
    }
    
    uint256 unicryptBaseFee = STATUS.TOTAL_BASE_COLLECTED.mul(PRESALE_FEE_INFO.UNICRYPT_BASE_FEE).div(1000);
    
    // base token liquidity
    uint256 baseLiquidity = STATUS.TOTAL_BASE_COLLECTED.sub(unicryptBaseFee).mul(PRESALE_INFO.LIQUIDITY_PERCENT).div(1000);
    if (PRESALE_INFO.PRESALE_IN_ETH) {
        WETH.deposit{value : baseLiquidity}();
    }
    TransferHelper.safeApprove(address(PRESALE_INFO.B_TOKEN), address(PRESALE_LOCK_FORWARDER), baseLiquidity);
    
    // sale token liquidity
    uint256 tokenLiquidity = baseLiquidity.mul(PRESALE_INFO.LISTING_RATE).div(10 ** uint256(PRESALE_INFO.B_TOKEN.decimals()));
    TransferHelper.safeApprove(address(PRESALE_INFO.S_TOKEN), address(PRESALE_LOCK_FORWARDER), tokenLiquidity);
    
    PRESALE_LOCK_FORWARDER.lockLiquidity(PRESALE_INFO.B_TOKEN, PRESALE_INFO.S_TOKEN, baseLiquidity, tokenLiquidity, block.timestamp + PRESALE_INFO.LOCK_PERIOD, PRESALE_INFO.PRESALE_OWNER);
    
    // transfer fees
    uint256 unicryptTokenFee = STATUS.TOTAL_TOKENS_SOLD.mul(PRESALE_FEE_INFO.UNICRYPT_TOKEN_FEE).div(1000);
    // referrals are checked for validity in the presale generator
    if (PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS != address(0)) {
        // Base token fee
        uint256 referralBaseFee = unicryptBaseFee.mul(PRESALE_FEE_INFO.REFERRAL_FEE).div(1000);
        TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS, referralBaseFee, !PRESALE_INFO.PRESALE_IN_ETH);
        unicryptBaseFee = unicryptBaseFee.sub(referralBaseFee);
        // Token fee
        uint256 referralTokenFee = unicryptTokenFee.mul(PRESALE_FEE_INFO.REFERRAL_FEE).div(1000);
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.REFERRAL_FEE_ADDRESS, referralTokenFee);
        unicryptTokenFee = unicryptTokenFee.sub(referralTokenFee);
    }
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_FEE_INFO.BASE_FEE_ADDRESS, unicryptBaseFee, !PRESALE_INFO.PRESALE_IN_ETH);
    TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), PRESALE_FEE_INFO.TOKEN_FEE_ADDRESS, unicryptTokenFee);
    
    // burn unsold tokens
    uint256 remainingSBalance = PRESALE_INFO.S_TOKEN.balanceOf(address(this));
    if (remainingSBalance > STATUS.TOTAL_TOKENS_SOLD) {
        uint256 burnAmount = remainingSBalance.sub(STATUS.TOTAL_TOKENS_SOLD);
        TransferHelper.safeTransfer(address(PRESALE_INFO.S_TOKEN), 0x000000000000000000000000000000000000dEaD, burnAmount);
    }
    
    // send remaining base tokens to presale owner
    uint256 remainingBaseBalance = PRESALE_INFO.PRESALE_IN_ETH ? address(this).balance : PRESALE_INFO.B_TOKEN.balanceOf(address(this));
    TransferHelper.safeTransferBaseToken(address(PRESALE_INFO.B_TOKEN), PRESALE_INFO.PRESALE_OWNER, remainingBaseBalance, !PRESALE_INFO.PRESALE_IN_ETH);
    
    STATUS.LP_GENERATION_COMPLETE = true;
  }
  
  function updateMaxSpendLimit(uint256 _maxSpend) external onlyPresaleOwner {
    require(PRESALE_INFO.START_BLOCK > block.number);
    PRESALE_INFO.MAX_SPEND_PER_BUYER = _maxSpend;
  }
  
  // postpone or bring a presale forward, this will only work when a presale is inactive.
  // i.e. current start block > block.number
  function updateBlocks(uint256 _startBlock, uint256 _endBlock) external onlyPresaleOwner {
    require(PRESALE_INFO.START_BLOCK > block.number);
    require(_endBlock.sub(_startBlock) <= PRESALE_SETTINGS.getMaxPresaleLength());
    PRESALE_INFO.START_BLOCK = _startBlock;
    PRESALE_INFO.END_BLOCK = _endBlock;
  }

  // editable at any stage of the presale
  function setWhitelistFlag(bool _flag) external onlyPresaleOwner {
    STATUS.WHITELIST_ONLY = _flag;
  }

  // editable at any stage of the presale
  function editWhitelist(address[] memory _users, bool _add) external onlyPresaleOwner {
    if (_add) {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.add(_users[i]);
        }
    } else {
        for (uint i = 0; i < _users.length; i++) {
          WHITELIST.remove(_users[i]);
        }
    }
  }

  // whitelist getters
  function getWhitelistedUsersLength () external view returns (uint256) {
    return WHITELIST.length();
  }
  
  function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
    return WHITELIST.at(_index);
  }
  
  function getUserWhitelistStatus (address _user) external view returns (bool) {
    return WHITELIST.contains(_user);
  }
}

/********************************************************************************************/
/*                                  PresaleGenerator                                        */
/* This contract generates Presale01 contracts and registers them in the PresaleFactory.    */
/********************************************************************************************/
pragma solidity 0.6.12;
interface IPresaleFactory {
    function registerPresale (address _presaleAddress) external;
    function presaleIsRegistered(address _presaleAddress) external view returns (bool);
}

interface IUniswapV2Locker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _referral, bool _fee_in_eth, address payable _withdrawer) external payable;
}

contract PresaleGenerator01 is Ownable {
    using SafeMath for uint256;
    
    IPresaleFactory public PRESALE_FACTORY;
    IPresaleSettings public PRESALE_SETTINGS;
    
    struct PresaleParams {
        uint256 amount;
        uint256 tokenPrice;
        uint256 maxSpendPerBuyer;
        uint256 hardcap;
        uint256 softcap;
        uint256 liquidityPercent;
        uint256 listingRate; // sale token listing price on uniswap
        uint256 startblock;
        uint256 endblock;
        uint256 lockPeriod;
    }
    
    constructor() public {
        PRESALE_FACTORY = IPresaleFactory(0x1c0a4cDc105c109667c9B9685aE37A9A06e27a34);
        PRESALE_SETTINGS = IPresaleSettings(0x9a1767c3B8aA75B726b8D56a5Ee1ab5ED961d16C);
    }
    
    /**
     * @notice Creates a new Presale contract and registers it in the PresaleFactory.sol.
     */
    function createPresale (
      address payable _presaleOwner,
      IERC20 _presaleToken,
      IERC20 _baseToken,
      address payable _referralAddress,
      uint256[10] memory uint_params
      ) public payable {
        
        PresaleParams memory params;
        params.amount = uint_params[0];
        params.tokenPrice = uint_params[1];
        params.maxSpendPerBuyer = uint_params[2];
        params.hardcap = uint_params[3];
        params.softcap = uint_params[4];
        params.liquidityPercent = uint_params[5];
        params.listingRate = uint_params[6];
        params.startblock = uint_params[7];
        params.endblock = uint_params[8];
        params.lockPeriod = uint_params[9];
        
        if (params.lockPeriod < 4 weeks) {
            params.lockPeriod = 4 weeks;
        }
        
        // Charge ETH fee for contract creation
        //require(msg.value == PRESALE_SETTINGS.getEthCreationFee(), 'FEE NOT MET');
        //PRESALE_SETTINGS.getEthAddress().transfer(PRESALE_SETTINGS.getEthCreationFee());
        
        if (_referralAddress != address(0)) {
            require(PRESALE_SETTINGS.referrerIsValid(_referralAddress), 'INVALID REFERRAL');
        }
        
        require(params.amount >= 10000, 'MIN DIVIS'); // minimum divisibility
        require(params.endblock.sub(params.startblock) <= PRESALE_SETTINGS.getMaxPresaleLength());
        require(params.tokenPrice.mul(params.hardcap) > 0, 'INVALID PARAMS'); // ensure no overflow for future calculations
        require(params.liquidityPercent >= 300 && params.liquidityPercent <= 1000, 'MIN LIQUIDITY'); // 30% minimum liquidity lock
        
        uint256 tokensRequiredForPresale = calculateAmountRequired(params.amount, params.tokenPrice, params.listingRate, params.liquidityPercent, PRESALE_SETTINGS.getTokenFee());
      
        Presale01 newPresale = new Presale01(address(this));
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokensRequiredForPresale);
        newPresale.init1(_presaleOwner, params.amount, params.tokenPrice, params.maxSpendPerBuyer, params.hardcap, params.softcap, params.liquidityPercent, params.listingRate, params.startblock, params.endblock, params.lockPeriod);
        newPresale.init2(_baseToken, _presaleToken, PRESALE_SETTINGS.getBaseFee(), PRESALE_SETTINGS.getTokenFee(), PRESALE_SETTINGS.getReferralFee(), PRESALE_SETTINGS.getEthAddress(), PRESALE_SETTINGS.getTokenAddress(), _referralAddress);
        PRESALE_FACTORY.registerPresale(address(newPresale));
    }
    function calculateAmountRequired (uint256 _amount, uint256 _tokenPrice, uint256 _listingRate, uint256 _liquidityPercent, uint256 _tokenFee) public pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(1000).div(_tokenPrice);
        uint256 unicryptTokenFee = _amount.mul(_tokenFee).div(1000);
        uint256 amountMinusFee = _amount.sub(unicryptTokenFee);
        uint256 liquidityRequired = amountMinusFee.mul(_liquidityPercent).mul(listingRatePercent).div(1000000);
        uint256 tokensRequiredForPresale = _amount.add(liquidityRequired).add(unicryptTokenFee);
        return tokensRequiredForPresale;
    }
}