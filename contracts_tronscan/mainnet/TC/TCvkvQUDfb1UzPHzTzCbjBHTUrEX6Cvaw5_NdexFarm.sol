//SourceUnit: EnumerableSet.sol

pragma solidity ^0.5.14;
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


//SourceUnit: INdexFactory.sol

pragma solidity ^0.5.8;

interface INdexFactory {
    event NewPair(address indexed token, address indexed exchange);

    function createExchange(address token) external returns (address payable);

    function getExchange(address token) external view returns (address payable);

    function getToken(address token) external view returns (address);

    function getTokenWithId(uint256 token_id) external view returns (address payable);

    function feeTo() external view returns (address payable);
}


//SourceUnit: INdexPair.sol

pragma solidity ^0.5.8;

interface INdexPair {
    event TokenPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);

    /**
    * @notice Convert TRX to Tokens.
    * @dev User specifies exact input (msg.value).
    * @dev User cannot specify minimum output or deadline.
    */
    function () external payable;

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param input_amount Amount of TRX or Tokens being sold.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens bought.
      */
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param output_amount Amount of TRX or Tokens being bought.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256);

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies exact input (msg.value) && minimum output
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return  Amount of Tokens bought.
     */
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);


    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);
    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return Amount of TRX sold.
     */
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return  Amount of TRX bought.
     */
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address recipient) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address token_addr)
    external returns (uint256);


    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address token_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address exchange_addr)
    external returns (uint256);

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr)
    external returns (uint256);


    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice external price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

    /**
     * @notice external price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

    /**
     * @notice external price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() external view returns (address);

    /**
     * @return Address of factory that created this exchange.
     */
    function factoryAddress() external view returns (address);


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint NDex tokens.
     * @dev min_liquidity does nothing when total NDex supply is 0.
     * @param min_liquidity Minimum number of NDex sender will mint if total NDex supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total NDex supply is 0.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of NDex minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);

    /**
     * @dev Burn NDex tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of NDex burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}


//SourceUnit: INdexPool.sol

pragma solidity ^0.5.8;

//TODO:add minters modifier

interface INdexPool{
    // Events
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed to, uint256 value);

    /**
     * @notice mint LP tokens to address 
     * @param to Address to receive LP token.
     * @param amount Amount of LP token to be minted.
     * @return  true or false.
     */
     function mint(address to, uint256 amount) external returns (bool);

    /**
     * @notice burn LP tokens from address 
     * @param from From witch address to burn LP token.
     * @param amount Amount of LP token to be burned.
     * @return  true or false.
     */
     function burn(address from, uint256 amount) external returns (bool); 
}


//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value); 
}


//SourceUnit: Migrations.sol

pragma solidity >=0.4.23 <0.6.0;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}


//SourceUnit: NDSPool.sol

pragma solidity ^0.5.10;

import './ITRC20.sol';
import './owned.sol';

contract NDSPool is owned{

    address payable public owner;
    ITRC20 public ndx;
    ITRC20 public usdt;
	
    constructor(address ndx_addr, address usdt_addr) public {

        owner = msg.sender;

	ndx = ITRC20(ndx_addr); 
	usdt = ITRC20(usdt_addr); 
    }

   function total_ndx_balance() public view returns (uint256) {
    	return ndx.balanceOf(address(this));
   }
   
   function total_usdt_balance() public view returns (uint256) {
    	return usdt.balanceOf(address(this));
   }

   function emergencyWithdraw() onlyOwner public {
   	if (owner == msg.sender) { 
		uint256 ndx_balance = ndx.balanceOf(address(this));
		if(ndx_balance > 0)
			ndx.transfer(msg.sender, ndx_balance);

		uint256 usdt_balance = usdt.balanceOf(address(this));
		if(usdt_balance > 0)
			usdt.transfer(msg.sender, usdt_balance);
   	}
   }
}


//SourceUnit: NdexFactory.sol

pragma solidity ^0.5.8;
import "./NdexPair.sol";
contract NdexFactory {
  /***********************************|
  |       Events And Variables        |
  |__________________________________*/
  event NewPair(address indexed token, address indexed exchange);
  uint256 public tokenCount;
  address payable public feeTo;
  address public feeToSetter;
  mapping (address => address) internal token_to_exchange;
  mapping (address => address) internal exchange_to_token;
  mapping (uint256 => address) internal id_to_token;
  /***********************************|
  |         Factory Functions         |
  |__________________________________*/

  constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
  }

  function createExchange(address token) public returns (address) {
    require(token != address(0), "illegal token");
    require(token_to_exchange[token] == address(0), "pair already created");
    NdexPair exchange = new NdexPair();
    exchange.setup(token);
    token_to_exchange[token] = address(exchange);
    exchange_to_token[address(exchange)] = token;
    uint256 token_id = tokenCount + 1;
    tokenCount = token_id;
    id_to_token[token_id] = token;
    emit NewPair(token, address(exchange));
    return address(exchange);
  }

  function setFeeTo(address payable _feeTo) external {
        require(msg.sender == feeToSetter, 'NdexV2: FORBIDDEN');
        feeTo = _feeTo;
  }
 
  function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'NdexV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
  }

  /***********************************|
  |         Getter Functions          |
  |__________________________________*/
  function getExchange(address token) public view returns (address) {
    return token_to_exchange[token];
  }
  function getToken(address exchange) public view returns (address) {
    return exchange_to_token[exchange];
  }
  function getTokenWithId(uint256 token_id) public view returns (address) {
    return id_to_token[token_id];
  }
}


//SourceUnit: NdexFarm.sol

pragma solidity ^0.5.13;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./INdexPool.sol";
import "./NdexPool.sol";
import "./SimplePriceOracle.sol";
import "./ReentrancyGuard.sol";

contract NdexFarm is ReentrancyGuard {

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    using SafeMath for uint256;
    // Variables 
    //	uint type - 1:70USDT-30NDX, 2:50USDT-50NDX, 3:100%NDX, 4:100%NDX, 1000NDX; multiplier: 1: 1000, 2:1350, 3:2000, 4:3000, Divider is 1000.
    struct Pool {
	uint256 usdt_amount;
	uint256 ndx_amount;
	uint256 lp_amount;
	uint256 stake_time; //unix timestamp, in seconds
	uint256 lp_staked; 
    }
    struct User {
        address upline;
        uint256 energy_value;
	Pool pool1;
	Pool pool2;
	Pool pool3;
	Pool pool4;
    }

    address payable public owner;
    address payable public admin_fee;
    address payable public entropy_pool;
    address payable public nds_pool;
    address payable public dao_pool;
    address payable public defi_pool;
    SimplePriceOracle public oracle;

    mapping(address => User) public users;
    uint8[] public ref_bonuses; 
    uint8[] public usdt_pool_ratio; 
    uint8[] public ndx_pool_ratio; 
    uint40[] public power_multiplier; 

    ITRC20 usdt;
    ITRC20 ndx;
    NdexPool lpt;

    uint256 constant PERCENTS_DIVIDER = 1_000;
    uint256 constant MIN_NDX_AMOUNT = 50_000_000;
    uint256 constant MIN_USDT_VALUE = 300_000_000;
    uint256 constant MIN_POOL4_AMOUNT = 1_000_000_000;
    uint256 constant LOCK_TIME_SPAN = 15552_000; //6 months

    // Events
    event SupplyLP(address indexed sender, uint pool_type, uint256 ndx_amount, uint256 usdt_amount, uint256 lp_value);
    event RemoveLP(address indexed sender, uint pool_type, uint256 ndx_amount, uint256 usdt_amount, uint256 lp_value);
    event StakeLP(address indexed sender, address indexed upline, uint pool_type, uint256 lp_amount);
    event UnstakeLP(address indexed sender, address indexed upline, uint pool_type, uint256 lp_amount);
    event WithdrawNDX(address indexed sender);
    event PoolWithdrawNDX(address indexed sender, uint pool_type);
    event DistributeNDX(address indexed receiver, uint256 amount);
    event IncEnergyValue(address indexed sender, uint256 amount);
    event ReCalLp(address indexed sender, uint256 ndx_amount, uint256 lp_amount);

    /***********************************|
    |        Constructor                |
    |__________________________________*/
    constructor(address payable nds_pool_addr, address payable dao_pool_addr, address payable defi_pool_addr, address lpt_addr, address oracle_addr) public {
        owner = msg.sender;
    
	ndx = ITRC20(0x563CB80479ca86cffC16160d80433B4Ceaac07d2); 
	usdt = ITRC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C); 
	admin_fee = address(0x2d097516aEd475dFB92bA611e1E5fd665e67dbB3);
	entropy_pool = address(0x504A9088291c325338d171dDE587B26296399E58);
	nds_pool = address(nds_pool_addr);
	dao_pool = address(dao_pool_addr);
	defi_pool = address(defi_pool_addr);
	lpt = NdexPool(lpt_addr);
	oracle = SimplePriceOracle(oracle_addr);

	usdt_pool_ratio.push(70);
	usdt_pool_ratio.push(50);
	usdt_pool_ratio.push(0);
	usdt_pool_ratio.push(0);

	ndx_pool_ratio.push(30);
	ndx_pool_ratio.push(50);
	ndx_pool_ratio.push(100);
	ndx_pool_ratio.push(100);

	power_multiplier.push(1000);
	power_multiplier.push(1350);
	power_multiplier.push(2000);
	power_multiplier.push(3000);
    }


    /***********************************|
    |        Farm Functions         |
    |__________________________________*/

    /**
     * @notice mint LP tokens to address 
     * @param pool_type type of LP 
     * @param ndx_amount Amount of NDX token.
     * @param usdt_amount Amount of NDX token.
     * @return  LP amount.
     */
     function supply(uint pool_type, uint256 ndx_amount, uint256 usdt_amount) external nonReentrant returns (uint256) {
	require((pool_type > 0) && (pool_type < 5), "Ndex V2: INVALID_POOL_TYPE");


	//fetch NDX price from Oracle
	uint256 ndx_price = oracle.getUnderlyingPrice(ndx);
	require(ndx_price > 0, "Ndex V2: INVALID NDX PRICE");

	User storage user = users[msg.sender];
	Pool storage pool = user.pool1;
	if(pool_type == 1)
	{
		pool = user.pool1;
	}else if(pool_type == 2)
	{
		pool = user.pool2;
	}else if(pool_type == 3)
	{
		pool = user.pool3;
	}else if(pool_type == 4)
	{
		require(ndx_amount >= MIN_POOL4_AMOUNT, "Ndex V2: POOL4 MINIMAL 1000 NDX");
		pool = user.pool4;
	}
	uint256 lp_amount = pool.lp_amount;
	require(lp_amount == 0, "Ndex V2: REMOVE LIQUIDITY POOL FIRST");

	uint256 ndx_usdt_val = ndx_amount.mul(ndx_price).div(1000000);

	require((ndx_amount >= MIN_NDX_AMOUNT) || (usdt_amount.add(ndx_usdt_val)>= MIN_USDT_VALUE), "Ndex V2: MINIMAL 50 NDX or VALUE 300 USDT AT LEAST");

	uint ind = pool_type.sub(1);

	uint256 ndx_adjust_val = ndx_usdt_val;
	if(pool_type < 3)
		ndx_adjust_val = usdt_amount.mul(ndx_pool_ratio[ind]).div(usdt_pool_ratio[ind]);	
	if(ndx_usdt_val < ndx_adjust_val)
	{
		uint256 usdt_adjust_amount = ndx_usdt_val.mul(usdt_pool_ratio[ind]).div(ndx_pool_ratio[ind]);
		lp_amount = (ndx_usdt_val.add(usdt_adjust_amount)).mul(power_multiplier[ind]).div(PERCENTS_DIVIDER);

		require(ndx.balanceOf(msg.sender)>= ndx_amount, "Ndex V2: INSUFFICIENT NDX");
		ndx.transferFrom(msg.sender, address(this), ndx_amount);
		uint256 ndx_fee = ndx_amount.div(50);
		//70%->Defi fund, 20%->admin_fee, 10%->super miners
		ndx.transfer(defi_pool, ndx_fee.mul(7).div(10));
		ndx.transfer(admin_fee, ndx_fee.div(5));

		require(usdt.balanceOf(msg.sender)>= usdt_adjust_amount, "Ndex V2: INSUFFICIENT USDT");
		uint256 usdt_fee = usdt_adjust_amount.div(50);
		if(usdt_adjust_amount > 0)
		{
			usdt.transferFrom(msg.sender, address(this), usdt_adjust_amount);
			usdt.transfer(admin_fee, usdt_fee.div(5));
			usdt.transfer(entropy_pool, usdt_fee.div(5));
			usdt.transfer(nds_pool, usdt_fee.mul(3).div(5));
		}

		pool.usdt_amount = usdt_adjust_amount.sub(usdt_fee);
		pool.ndx_amount = ndx_amount.sub(ndx_fee);
		pool.lp_amount = lp_amount;
	}else if(ndx_usdt_val >= ndx_adjust_val)
	{
		lp_amount = (ndx_adjust_val.add(usdt_amount)).mul(power_multiplier[ind]).div(PERCENTS_DIVIDER);	

		uint256 ndx_adjust_amount = ndx_adjust_val.mul(1000000).div(ndx_price);
		require(ndx.balanceOf(msg.sender)>= ndx_adjust_amount, "Ndex V2: INSUFFICIENT NDX");
		ndx.transferFrom(msg.sender, address(this), ndx_adjust_amount);
		uint256 ndx_fee = ndx_adjust_amount.div(50);
		//70%->Defi fund, 20%->admin_fee, 10%->super miners
		ndx.transfer(defi_pool, ndx_fee.mul(7).div(10));
		ndx.transfer(admin_fee, ndx_fee.div(5));

		require(usdt.balanceOf(msg.sender)>= usdt_amount, "Ndex V2: INSUFFICIENT USDT");
		uint256 usdt_fee = usdt_amount.div(50);
		if(usdt_amount > 0)
		{
			usdt.transferFrom(msg.sender, address(this), usdt_amount);
			usdt.transfer(admin_fee, usdt_fee.div(5));
			usdt.transfer(entropy_pool, usdt_fee.div(5));
			usdt.transfer(nds_pool, usdt_fee.mul(3).div(5));
		}

		pool.usdt_amount = usdt_amount.sub(usdt_fee);
		pool.ndx_amount = ndx_adjust_amount.sub(ndx_fee);
		pool.lp_amount = lp_amount;
	}
        lpt.mint(msg.sender, lp_amount);

    	emit SupplyLP(msg.sender, pool_type, ndx_amount, usdt_amount, lp_amount);

	return lp_amount;
    }

    /**
     * @notice burn LP tokens from address 
     * @param pool_type - pool type of LP 
     * @return  true or false.
     */
     function remove(uint pool_type) external nonReentrant returns (bool) {
	require((pool_type > 0) && (pool_type < 5), "Ndex V2: INVALID_POOL_TYPE");
	User storage user = users[msg.sender];
	Pool storage pool = user.pool1;
	if(pool_type == 1)
	{
		pool = user.pool1;
	}else if(pool_type == 2)
	{
		pool = user.pool2;
	}else if(pool_type == 3)
	{
		pool = user.pool3;
	}else if(pool_type == 4)
	{
		pool = user.pool4;
	}
	uint256 lp_amount = pool.lp_amount;
	require(lp_amount > 0, "Ndex V2: INSUFFICIENT LIQUIDITY BURNED");

	uint256 lp_staked = pool.lp_staked;
	require(lp_staked == 0, "Ndex V2: UNSTAKE LP TOKEN FIRST");

	uint256 ndx_amount = pool.ndx_amount;
	uint256 usdt_amount = pool.usdt_amount;

	pool.lp_amount = 0;
	pool.lp_staked = 0;
	pool.ndx_amount = 0;
	pool.usdt_amount = 0;

	uint256 balance = lpt.balanceOf(msg.sender);
	require(balance >= lp_amount, "Ndex V2: INSUFFCIENT LP TOKEN");
        lpt.burn(msg.sender, lp_amount);

	if(ndx_amount > 0)
		ndx.transfer(msg.sender, ndx_amount);

	if(usdt_amount > 0)
		usdt.transfer(msg.sender, usdt_amount);

	emit RemoveLP(msg.sender, pool_type, ndx_amount, usdt_amount, lp_amount);

	return true;
    }

   /**
    * stake to Farming valut
    */
    function stake(address upline, uint pool_type) external nonReentrant returns (uint256){
	require((upline != address(0)) && (upline != msg.sender), "Ndex V2: INVALID UPLINE");
	require((pool_type > 0) && (pool_type < 5), "Ndex V2: INVALID_POOL_TYPE");
	User storage user = users[msg.sender];
	user.upline = upline;
	Pool storage pool = user.pool1;
	if(pool_type == 1)
	{
		pool = user.pool1;
	}else if(pool_type == 2)
	{
		pool = user.pool2;
	}else if(pool_type == 3)
	{
		pool = user.pool3;
	}else if(pool_type == 4)
	{
		pool = user.pool4;
	}
	uint256 lp_staked = pool.lp_staked;
	require(lp_staked == 0, "Ndex V2: UNSTAKE LP TOKEN FIRST");

	uint256 lp_amount = pool.lp_amount;
	require(lp_amount >0, "Ndex V2: PLEASE SUPPLY FIRST");

	uint256 amount = lpt.balanceOf(msg.sender);
	require(amount >= lp_amount, "Ndex V2: INSUFFICIENT LP TOKEN");

	if(amount > lp_amount)
		amount = lp_amount;

	pool.lp_staked = amount;

	pool.stake_time = block.timestamp;

	lpt.transferFrom(msg.sender, address(this), amount);

	emit StakeLP(msg.sender, upline, pool_type, amount);

	return amount;
    }
   /**
    *unstake from Farming valut
    */
    function unstake(uint pool_type) external nonReentrant returns (uint256){
	require((pool_type > 0) && (pool_type < 5), "Ndex V2: INVALID_POOL_TYPE");

	User storage user = users[msg.sender];
	Pool storage pool = user.pool1;
	if(pool_type == 1)
	{
		pool = user.pool1;
	}else if(pool_type == 2)
	{
		pool = user.pool2;
	}else if(pool_type == 3)
	{
		pool = user.pool3;
	}else if(pool_type == 4)
	{
		pool = user.pool4;
		uint256 timespan = block.timestamp.sub(pool.stake_time);
		require(timespan >= LOCK_TIME_SPAN, "Ndex V2: LOCK 6 MONTHS IN POOL4.");
	}
	uint256 amount = pool.lp_staked;
	require(amount>0, "Ndex V2: PLESE STAKE FIRST");

	pool.lp_staked = 0;

	pool.stake_time = 0;
	
	lpt.transfer(msg.sender, amount);
	
	emit UnstakeLP(msg.sender, user.upline, pool_type, amount);

	return amount;
    }
    /*
     * Deposit NDX to increase energy value 
     */
    function inc_energy_value(uint256 amount) external payable nonReentrant returns (bool){

	require(amount >= 5000000, "Ndex V2: 5 NDX AT MINIMUM");
	
	require(ndx.balanceOf(msg.sender)>=amount, "Ndex V2: INSUFFICIENT NDX IN USER ADDR");

	ndx.transferFrom(msg.sender, address(this), amount);

	User storage user = users[msg.sender];

	user.energy_value = user.energy_value.add(amount);

	//50% burn NDX to 0x0, 10%->admin_fee, 10%->DAO, 30%->super miners
	ndx.burn(amount.div(2));
	ndx.transfer(admin_fee, amount.div(10));
	ndx.transfer(dao_pool, amount.div(10));

	emit IncEnergyValue(msg.sender, amount);	

	return true;
    }
    //recal
     function recal() external nonReentrant returns (uint256) {

	//fetch NDX price from Oracle
	uint256 ndx_price = oracle.getUnderlyingPrice(ndx);
	require(ndx_price > 0, "Ndex V2: INVALID NDX PRICE");

	User storage user = users[msg.sender];
	Pool storage pool = user.pool4;
	uint256 lp_amount = pool.lp_amount;
	require(lp_amount > 0, "Ndex V2: STAKE POOL 4 FIRST");
	uint256 ndx_amount = pool.ndx_amount;

	uint256 ndx_fee = ndx_amount.div(100);
	//70%->Defi fund, 20%->admin_fee, 10%->super miners
	ndx.transfer(defi_pool, ndx_fee.mul(7).div(10));
	ndx.transfer(admin_fee, ndx_fee.div(5));

	ndx_amount = pool.ndx_amount.sub(ndx_fee);

	uint256 ndx_usdt_val = ndx_amount.mul(ndx_price).div(1000000);

	lp_amount = ndx_usdt_val.mul(power_multiplier[3]).div(PERCENTS_DIVIDER);

	require(lp_amount>=pool.lp_amount, "Ndex V2: only increase power is supported");

	uint256 more_lp = lp_amount.sub(pool.lp_amount);
        lpt.mint(msg.sender, more_lp);

	pool.ndx_amount = ndx_amount;
	pool.lp_amount = lp_amount;

    	emit ReCalLp(msg.sender, ndx_amount, more_lp);

	return more_lp;
    }
    /*
     * Withdraw NDX
     */
    function withdraw_ndx() external payable nonReentrant returns (bool){

	require(msg.value >= 50000000, "Ndex V2: INSUFFICIENT GAS FEE");
	
	admin_fee.transfer(msg.value);

	emit WithdrawNDX(msg.sender);	

	return true;
    }
    /*
     * Pool Withdraw NDX
     */
    function pool_withdraw_ndx(uint pool_type) external payable nonReentrant returns (bool){

	require(msg.value >= 50000000, "Ndex V2: POOL INSUFFICIENT GAS FEE");
	
	admin_fee.transfer(msg.value);

	emit PoolWithdrawNDX(msg.sender, pool_type);	

	return true;
    }
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
	require(owner == msg.sender, "ONLY OWNER.");
	uint256 usdt_amount = usdt.balanceOf(address(this));
	uint256 ndx_amount = ndx.balanceOf(address(this));
	if(usdt_amount > 0)
		usdt.transfer(owner, usdt_amount);
	if(ndx_amount > 0)
		ndx.transfer(owner, ndx_amount);
    }
    /*
     * distribute NDX
     */
    function distribute_ndx(address receiver, uint256 amount) external nonReentrant returns (bool){

	require(msg.sender == owner, "Ndex V2: ONLY OWNER CAN DISTRIBUTE");
	require(receiver != address(0), "Ndex V2: INVALID RECEIVER ADDRESS");
	require(amount > 0, "Ndex V2: LESS THAN 0");
	
	ndx.transfer(receiver, amount);

	emit DistributeNDX(receiver, amount);	

	return true;
    }
    /*
     * set pool addr 
     */
    function set_pool_addr(address payable entropy_pool_addr, address payable nds_pool_addr, address payable dao_pool_addr, address payable defi_pool_addr, address oracle_addr) external nonReentrant returns (bool){

	require(msg.sender == owner, "Ndex V2: ONLY OWNER CAN MODIFY");
	entropy_pool = address(entropy_pool_addr);	
	nds_pool = address(nds_pool_addr);	
	dao_pool = address(dao_pool_addr);	
	defi_pool = address(defi_pool_addr);	
	oracle = SimplePriceOracle(oracle_addr);	

	return true;
    }

    /**
     * get valut pool list
     */
    function get_pool_info(uint pool_type) view external returns(uint256, uint256, uint256, uint256, uint256 ) {
	User storage user = users[msg.sender];
	Pool memory pool = user.pool1;
	if(pool_type == 2)
		pool = user.pool2;
	else if(pool_type == 3)
		pool = user.pool3;
	else if(pool_type == 4)
		pool = user.pool4;
        return (pool.usdt_amount, pool.ndx_amount, pool.lp_amount, pool.stake_time, pool.lp_staked);
    }
}


//SourceUnit: NdexPair.sol

pragma solidity ^0.5.8;
import "./TRC20.sol";
import "./ITRC20.sol";
import "./INdexFactory.sol";
import "./INdexPair.sol";
import "./ReentrancyGuard.sol";

contract NdexPair is TRC20,ReentrancyGuard {

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    // Variables
    string public name;         // Ndex V2.0
    string public symbol;       // Ndex-V2
    uint256 public decimals;     // 6
    ITRC20 token;                // address of the TRC20 token traded on this contract
    INdexFactory factory;     // interface for the factory that created this contract
    uint256 constant SWAP_FEE_RATIO = 5;
    uint256 constant PERCENTS_DIVIDER = 1000;

    // Events
    event TokenNdexPurchase(address indexed buyer, uint256 indexed trx_sold, uint256 indexed tokens_bought);
    event TrxNdexPurchase(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed trx_bought);
    event AddNdexLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event RemoveNdexLiquidity(address indexed provider, uint256 indexed trx_amount, uint256 indexed token_amount);
    event NdexSnapshot(address indexed operator, uint256 indexed trx_balance, uint256 indexed token_balance);


    /***********************************|
    |            Constsructor           |
    |__________________________________*/

    /**
     * @dev This function acts as a contract constructor which is not currently supported in contracts deployed
     *      using create_with_code_of(). It is called once by the factory during contract creation.
     */
    function setup(address token_addr) public {
        require(
            address(factory) == address(0) && address(token) == address(0) && token_addr != address(0),
            "INVALID_ADDRESS"
        );
        factory = INdexFactory(msg.sender);
        token = ITRC20(token_addr);
        name = "NDEX V2.0";
        symbol = "NDEX-V2";
        decimals = 6;
    }


    /***********************************|
    |        Exchange Functions         |
    |__________________________________*/


    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value).
     * @dev User cannot specify minimum output or deadline.
     */
    function () external payable {
        trxToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender);
    }

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param input_amount Amount of TRX or Tokens being sold.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens bought.
      */

    // except trading fee : amount=input_amount*995=input_amount_with_fee
    // new_output_reserve=output_reserve-output_amount
    // new_input_reserve=input_reserve+amount
    // new_output_reserve*new_input_reserve=output_reserve*input_reserve=K
    // new_output_reserve*new_input_reserve=(output_reserve-output_amount)*(input_reserve+amount)
    // x*y=(x-a)*(y+b)
    // => x*y=x*y+x*b-a*y-a*b => a*y+a*b=x*b => a*(y+b)=x*b
    // => a=x*b/(y+b)
    // output_amount = output_reserve*input_amount_with_fee/(input_reserve+input_amount_with_fee)
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
        uint256 input_amount_with_fee = input_amount.mul(995);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator.div(denominator);

    }

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param output_amount Amount of TRX or Tokens being bought.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens sold.
      */
    // new_output_reserve=output_reserve-output_amount
    // new_input_reserve=input_reserve+input_amount
    // new_output_reserve*new_input_reserve=output_reserve*input_reserve=不变的K值
    // new_output_reserve*new_input_reserve=(output_reserve-output_amount)*(input_reserve+input_amount)
    // x*y=(x-a)*(y+b)
    // => x*y=x*y+x*b-a*y-a*b => a*y=x*b-a*b => a*y=(x-a)*b
    // => b=y*a/(x-a)
    // input_amount = input_reserve*output_amount/(output_reserve-output_amount)
    // real_intput_amount=input_amount/0.995+1
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0);
        uint256 numerator = input_reserve.mul(output_amount).mul(1000);
        uint256 denominator = (output_reserve.sub(output_amount)).mul(995);
        return (numerator.div(denominator)).add(1);
    }

    function trxToTokenInput(uint256 trx_sold, uint256 min_tokens, uint256 deadline, address buyer, address recipient) private nonReentrant returns (uint256) {
        require(deadline >= block.timestamp && trx_sold > 0 && min_tokens > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getInputPrice(trx_sold, address(this).balance.sub(trx_sold), token_reserve);
        require(tokens_bought >= min_tokens);

        token.transfer(address(recipient),tokens_bought);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "NdexV2: zero feeTo address");
	uint256 fee = trx_sold.mul(SWAP_FEE_RATIO).div(PERCENTS_DIVIDER);
        feeTo.transfer(fee);
        emit TokenNdexPurchase(buyer, trx_sold, tokens_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));
        return tokens_bought;
    }

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens bought.
     */
    function  trxToTokenSwapInput(uint256 min_tokens, uint256 deadline)  public payable returns (uint256)  {
        return trxToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender);
    }

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies exact input (msg.value) && minimum output
     * @param min_tokens Minimum Tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return  Amount of Tokens bought.
     */
    function trxToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256) {
        require(recipient != address(this) && recipient != address(0));
        return trxToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient);
    }

    function trxToTokenOutput(uint256 tokens_bought, uint256 max_trx, uint256 deadline, address payable buyer, address recipient) private nonReentrant returns (uint256) {
        require(deadline >= block.timestamp && tokens_bought > 0 && max_trx > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_sold = getOutputPrice(tokens_bought, address(this).balance.sub(max_trx), token_reserve);
        // Throws if trx_sold > max_trx
        uint256 trx_refund = max_trx.sub(trx_sold);
        if (trx_refund > 0) {
            buyer.transfer(trx_refund);
        }

        token.transfer(recipient,tokens_bought);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "NdexV2: zero feeTo address");
	uint256 fee = trx_sold.mul(SWAP_FEE_RATIO).div(PERCENTS_DIVIDER);
        feeTo.transfer(fee);
        emit TokenNdexPurchase(buyer, trx_sold, tokens_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));
        return trx_sold;
    }

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) public payable returns(uint256) {
        return trxToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, msg.sender);
    }

    /**
     * @notice Convert TRX to Tokens && transfers Tokens to recipient.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output Tokens.
     * @return Amount of TRX sold.
     */
    function trxToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) public payable returns (uint256) {
        require(recipient != address(this) && recipient != address(0));
        return trxToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, recipient);
    }

    // 995 * tokens_sold / 1000 = liquidity 
    // 5 * tokens_sold / 1000 = fee
    // tokens_reserve +  (995 * tokens_sold / 1000) = trx_reserve - x
    // x = ?
    // token_amount = token_reserve*trx_amount/(trx_reserve-trx_amount)
    // real_token_amount=toekn_amount/0.995+1

    function tokenToTrxInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address buyer, address payable recipient) private nonReentrant returns (uint256) {
        require(deadline >= block.timestamp && tokens_sold > 0 && min_trx > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        uint256 wei_bought = trx_bought;
        require(wei_bought >= min_trx);
        recipient.transfer(wei_bought);

	//require(token.transferFrom(buyer, address(this), tokens_sold),"Ndex V2: transfer token failed.");
	token.transferFrom(buyer, address(this), tokens_sold);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "Ndex V2: zero feeTo address");
	uint256 fee = tokens_sold.mul(SWAP_FEE_RATIO).div(PERCENTS_DIVIDER);
	//require(token.transfer(feeTo, fee),"Ndex V2: transfer fee failed.");
	token.transfer(feeTo, fee);
        emit TrxNdexPurchase(buyer, tokens_sold, wei_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));

        return wei_bought;
    }

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline) public returns (uint256) {
        return tokenToTrxInput(tokens_sold, min_trx, deadline, msg.sender, msg.sender);
    }

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return  Amount of TRX bought.
     */
    function tokenToTrxTransferInput(uint256 tokens_sold, uint256 min_trx, uint256 deadline, address payable recipient) public returns (uint256) {
        require(recipient != address(this) && recipient != address(0));
        return tokenToTrxInput(tokens_sold, min_trx, deadline, msg.sender, recipient);
    }


    function tokenToTrxOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address buyer, address payable recipient) private nonReentrant returns (uint256) {
        require(deadline >= block.timestamp && trx_bought > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_sold = getOutputPrice(trx_bought, token_reserve, address(this).balance);
        // tokens sold is always > 0
        require(max_tokens >= tokens_sold);
        recipient.transfer(trx_bought);

        token.transferFrom(buyer, address(this), tokens_sold);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "NdexV2: zero feeTo address");
	uint256 fee = tokens_sold.mul(SWAP_FEE_RATIO).div(PERCENTS_DIVIDER);
        token.transfer(feeTo, fee);
        emit TrxNdexPurchase(buyer, tokens_sold, trx_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));
        return tokens_sold;
    }

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline) public returns (uint256) {
        return tokenToTrxOutput(trx_bought, max_tokens, deadline, msg.sender, msg.sender);
    }

    /**
     * @notice Convert Tokens to TRX && transfers TRX to recipient.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxTransferOutput(uint256 trx_bought, uint256 max_tokens, uint256 deadline, address payable recipient) public returns (uint256) {
        require(recipient != address(this) && recipient != address(0));
        return tokenToTrxOutput(trx_bought, max_tokens, deadline, msg.sender, recipient);
    }

    function tokenToTokenInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address buyer,
        address recipient,
        address payable exchange_addr)
    nonReentrant
    private returns (uint256)
    {
        require(deadline >= block.timestamp && tokens_sold > 0 && min_tokens_bought > 0 && min_trx_bought > 0, "illegal input parameters");
        require(exchange_addr != address(this) && exchange_addr != address(0), "illegal exchange addr");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        uint256 wei_bought = trx_bought;
        require(wei_bought >= min_trx_bought, "min trx bought not matched");

        token.transferFrom(buyer, address(this), tokens_sold);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "NdexV2: zero feeTo address");
	uint256 fee = tokens_sold.mul(SWAP_FEE_RATIO);
	fee = fee.div(PERCENTS_DIVIDER);
        token.transfer(feeTo, fee);
        uint256 tokens_bought = INdexPair(exchange_addr).trxToTokenTransferInput.value(wei_bought)(min_tokens_bought, deadline, recipient);
        emit TrxNdexPurchase(buyer, tokens_sold, wei_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));
        return tokens_bought;
    }

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address token_addr)
    public returns (uint256)
    {
        address payable exchange_addr = factory.getExchange(token_addr);
        return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, msg.sender, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token_addr) bought.
     */
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address token_addr)
    public returns (uint256)
    {
        address payable exchange_addr = factory.getExchange(token_addr);
        return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, recipient, exchange_addr);
    }

    function tokenToTokenOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address buyer,
        address recipient,
        address payable exchange_addr)
    nonReentrant
    private returns (uint256)
    {
        require(deadline >= block.timestamp && (tokens_bought > 0 && max_trx_sold > 0), "illegal input parameters");
        require(exchange_addr != address(this) && exchange_addr != address(0), "illegal exchange addr");
        uint256 trx_bought = INdexPair(exchange_addr).getTrxToTokenOutputPrice(tokens_bought);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_sold = getOutputPrice(trx_bought, token_reserve, address(this).balance);
        // tokens sold is always > 0
        require(max_tokens_sold >= tokens_sold && max_trx_sold >= trx_bought, "max token sold not matched");

        token.transferFrom(buyer, address(this), tokens_sold);
	address payable feeTo = factory.feeTo();
	require(feeTo != address(0), "NdexV2: zero feeTo address");
	uint256 fee = tokens_sold.mul(SWAP_FEE_RATIO).div(PERCENTS_DIVIDER);
        token.transfer(feeTo, fee);
        INdexPair(exchange_addr).trxToTokenTransferOutput.value(trx_bought)(tokens_bought, deadline, recipient);
        emit TrxNdexPurchase(buyer, tokens_sold, trx_bought);
        emit NdexSnapshot(buyer,address(this).balance,token.balanceOf(address(this)));
        return tokens_sold;
    }

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr).
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address token_addr)
    public returns (uint256)
    {
        address payable exchange_addr = factory.getExchange(token_addr);
        return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, msg.sender, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (token_addr) && transfers
     *         Tokens (token_addr) to recipient.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param token_addr The address of the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address token_addr)
    public returns (uint256)
    {
        address payable exchange_addr = factory.getExchange(token_addr);
        return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, recipient, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address payable exchange_addr)
    public returns (uint256)
    {
        return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, msg.sender, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_tokens_bought Minimum Tokens (token_addr) purchased.
     * @param min_trx_bought Minimum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (exchange_addr.token) bought.
     */
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address payable exchange_addr)
    public returns (uint256)
    {
        require(recipient != address(this), "illegal recipient");
        return tokenToTokenInput(tokens_sold, min_tokens_bought, min_trx_bought, deadline, msg.sender, recipient, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token).
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address payable exchange_addr)
    public returns (uint256)
    {
        return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, msg.sender, exchange_addr);
    }

    /**
     * @notice Convert Tokens (token) to Tokens (exchange_addr.token) && transfers
     *         Tokens (exchange_addr.token) to recipient.
     * @dev Allows trades through contracts that were not deployed from the same factory.
     * @dev User specifies maximum input && exact output.
     * @param tokens_bought Amount of Tokens (token_addr) bought.
     * @param max_tokens_sold Maximum Tokens (token) sold.
     * @param max_trx_sold Maximum TRX purchased as intermediary.
     * @param deadline Time after which this transaction can no longer be executed.
     * @param recipient The address that receives output TRX.
     * @param exchange_addr The address of the exchange for the token being purchased.
     * @return Amount of Tokens (token) sold.
     */
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_trx_sold,
        uint256 deadline,
        address recipient,
        address payable exchange_addr)
    public returns (uint256)
    {
        require(recipient != address(this), "illegal recipient");
        return tokenToTokenOutput(tokens_bought, max_tokens_sold, max_trx_sold, deadline, msg.sender, recipient, exchange_addr);
    }


    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold) public view returns (uint256) {
        require(trx_sold > 0, "trx sold must greater than 0");
        uint256 token_reserve = token.balanceOf(address(this));
        return getInputPrice(trx_sold, address(this).balance, token_reserve);
    }

    /**
     * @notice Public price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
        require(tokens_bought > 0, "tokens bought must greater than 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_sold = getOutputPrice(tokens_bought, address(this).balance, token_reserve);
        return trx_sold;
    }

    /**
     * @notice Public price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold) public view returns (uint256) {
        require(tokens_sold > 0, "tokens sold must greater than 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_bought = getInputPrice(tokens_sold, token_reserve, address(this).balance);
        return trx_bought;
    }

    /**
     * @notice Public price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought) public view returns (uint256) {
        require(trx_bought > 0, "trx bought must greater than 0");
        uint256 token_reserve = token.balanceOf(address(this));
        return getOutputPrice(trx_bought, token_reserve, address(this).balance);
    }

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address) {
        return address(token);
    }

    /**
     * @return Address of factory that created this exchange.
     */
    function factoryAddress() public view returns (address) {
        return address(factory);
    }


    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint NDEX tokens.
     * @dev min_liquidity does nothing when total NDEX supply is 0.
     * @param min_liquidity Minimum number of NDEX sender will mint if total NDEX supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total NDEX supply is 0.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of NDEX minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public payable nonReentrant returns (uint256) {
        require(deadline > block.timestamp && max_tokens > 0 && msg.value > 0, 'Ndex#addLiquidity: INVALID_ARGUMENT');
        uint256 total_liquidity = _totalSupply;

        if (total_liquidity > 0) {
            require(min_liquidity > 0, "min_liquidity must greater than 0");
            uint256 trx_reserve = address(this).balance.sub(msg.value);
            uint256 token_reserve = token.balanceOf(address(this));
            uint256 token_amount = (msg.value.mul(token_reserve).div(trx_reserve)).add(1);
            uint256 liquidity_minted = msg.value.mul(total_liquidity).div(trx_reserve);

            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity, "max tokens not meet or liquidity_minted not meet min_liquidity");
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            _totalSupply = total_liquidity.add(liquidity_minted);

            token.transferFrom(msg.sender, address(this), token_amount);
            emit AddNdexLiquidity(msg.sender, msg.value, token_amount);
            emit NdexSnapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;

        } else {
            require(address(factory) != address(0) && address(token) != address(0) && msg.value >= 10_000_000, "INVALID_VALUE");
            require(factory.getExchange(address(token)) == address(this), "token address not meet exchange");
            uint256 token_amount = max_tokens;
            uint256 initial_liquidity = address(this).balance;
            _totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;

            token.transferFrom(msg.sender, address(this), token_amount);
            emit AddNdexLiquidity(msg.sender, msg.value, token_amount);
            emit NdexSnapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
            emit Transfer(address(0), msg.sender, initial_liquidity);
            return initial_liquidity;
        }
    }

    /**
     * @dev Burn NDEX tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of NDEX burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @param deadline Time after which this transaction can no longer be executed.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens, uint256 deadline) public nonReentrant returns (uint256, uint256) {
        require(amount > 0 && deadline > block.timestamp && min_trx > 0 && min_tokens > 0, "illegal input parameters");
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0, "total_liquidity must greater than 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 trx_amount = amount.mul(address(this).balance) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(trx_amount >= min_trx && token_amount >= min_tokens, "min_token or min_trx not meet");

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = total_liquidity.sub(amount);
        msg.sender.transfer(trx_amount);

        token.transfer(msg.sender, token_amount);
        emit RemoveNdexLiquidity(msg.sender, trx_amount, token_amount);
        emit NdexSnapshot(msg.sender,address(this).balance,token.balanceOf(address(this)));
        emit Transfer(msg.sender, address(0), amount);
        return (trx_amount, token_amount);
    }


}


//SourceUnit: NdexPool.sol

//TODO: add minters list

pragma solidity ^0.5.8;
import "./TRC20.sol";
import "./ITRC20.sol";
import "./INdexPair.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./owned.sol";

contract NdexPool is TRC20,ReentrancyGuard,owned {

    /***********************************|
    |        Variables && Events        |
    |__________________________________*/

    // Variables
    string public name = "Ndex V2.0 LP Token";
    string public symbol = "Ndex-V2-LP";
    uint256 public decimals = 6;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _minters;

    // Events
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed to, uint256 value);

    /***********************************|
    |        Liquidity Pool Functions         |
    |__________________________________*/

    /**
     * @notice mint LP tokens to address 
     * @param to Address to receive LP token.
     * @param amount Amount of LP token to be minted.
     * @return  true or false.
     */
     function mint(address to, uint256 amount) external onlyMinter nonReentrant returns (bool) {
	require(to != address(0), "Ndex V2: INVALID_ADDRESS");
	require(amount > 0, "Ndex V2: INSUFFICIENT_LIQUIDITY_MINTED");

        _mint(to, amount);

        emit Mint(to, amount);

	return true;
    }

    /**
     * @notice burn LP tokens from address 
     * @param from From witch address to burn LP token.
     * @param amount Amount of LP token to be burned.
     * @return  true or false.
     */
     function burn(address from, uint256 amount) external nonReentrant returns (bool) {
	require(from != address(0), "Ndex V2: INVALID_ADDRESS");
	require(amount > 0, "Ndex V2: INSUFFICIENT_LIQUIDITY_BURNED");
	uint256 balance = this.balanceOf(from);
	require(balance >= amount, "INSUFFICIENT LP TOKEN IN USER ADDRESS");

        _burn(from, amount);

        emit Burn(from, amount);

	return true;
    }
    /***********************************|
    |        Minters Functions         |
    |__________________________________*/
    function addMinter(address _addMinter) public onlyOwner returns (bool) {
        require(_addMinter != address(0), "Ndex V2: _addMinter is the zero address");
        return EnumerableSet.add(_minters, _addMinter);
    }

    function delMinter(address _delMinter) public onlyOwner returns (bool) {
        require(_delMinter != address(0), "Ndex V2: _delMinter is the zero address");
        return EnumerableSet.remove(_minters, _delMinter);
    }

    function getMinterLength() public view returns (uint256) {
        return EnumerableSet.length(_minters);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(_minters, account);
    }

    function getMinter(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getMinterLength() - 1, "Ndex V2: index out of bounds");
        return EnumerableSet.at(_minters, _index);
    }

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "Ndex V2: caller is not the minter");
        _;
    }
}


//SourceUnit: PriceOracle.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";

contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of an asset
      * @param token The token to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(ITRC20 token) external view returns (uint);
}


//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.5.8;
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }

}


//SourceUnit: SimplePriceOracle.sol

pragma solidity ^0.5.8;

import "./PriceOracle.sol";
import "./ITRC20.sol";
import "./EnumerableSet.sol";

contract SimplePriceOracle is PriceOracle {
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(address => uint) prices;
    uint baseTokenPrice;
    string public baseSymbol;
    EnumerableSet.AddressSet private _setters;

    address owner;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    constructor(string memory symbol) public {
        owner = msg.sender;
        baseSymbol = symbol;
        EnumerableSet.add(_setters, owner);
    }

    function getUnderlyingPrice(ITRC20 token) public view returns (uint) {
        if (compareStrings(token.symbol(), baseSymbol)) {
            return baseTokenPrice;
        } else {
            return prices[address(token)];
        }
    }

    function setUnderlyingPrice(ITRC20 token, uint underlyingPriceMantissa) onlySetter public {
        if (compareStrings(token.symbol(), baseSymbol)) {
            baseTokenPrice = underlyingPriceMantissa;
        } else {
            address asset = address(token);
            emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
            prices[asset] = underlyingPriceMantissa;
        }
    }

    function setDirectPrice(address asset, uint price) onlySetter public {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == owner, "only the owner may call changeAdmin");
        EnumerableSet.remove(_setters, owner);
        owner = newAdmin;
        EnumerableSet.add(_setters, owner);
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setSymbol(string memory symbol) public {
        require(msg.sender == owner, "only the owner may call baseSymbol");
        baseSymbol = symbol;
    }
    /***********************************|
    |        Setters Functions         |
    |__________________________________*/
    function addSetter(address _setter) public returns (bool) {
        require(msg.sender == owner, "only the owner may call");
        require(_setter != address(0), "SimplePriceOracle: _setter is the zero address");
        return EnumerableSet.add(_setters, _setter);
    }

    function delSetter(address _delSetter) public returns (bool) {
        require(msg.sender == owner, "only the owner may call");
        require(_delSetter != address(0), "SimplePriceOracle: _delSetter is the zero address");
        return EnumerableSet.remove(_setters, _delSetter);
    }

    function getSetterLength() public view returns (uint256) {
        return EnumerableSet.length(_setters);
    }

    function isSetter(address account) public view returns (bool) {
        return EnumerableSet.contains(_setters, account);
    }

    function getSetter(uint256 _index) public view returns (address){
        require(msg.sender == owner, "only the owner may call");
        require(_index <= getSetterLength() - 1, "SimplePriceOracle: index out of bounds");
        return EnumerableSet.at(_setters, _index);
    }

    // modifier for setter function
    modifier onlySetter() {
        require(isSetter(msg.sender), "SimplePriceOracle: caller is not the setter");
        _;
    }
}



//SourceUnit: TRC20.sol

pragma solidity ^0.5.8;
import "./SafeMath.sol";


/**
 * @title Standard TRC20 token
 *
 * @dev Implementation of the basic standard token.
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;

    /**
      * @dev Total number of tokens in existence
      */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
      * @dev Gets the balance of the specified address.
      * @param owner The address to query the balance of.
      * @return A uint256 representing the amount owned by the passed address.
      */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
      * @dev Function to check the amount of tokens that an owner allowed to a spender.
      * @param owner address The address which owns the funds.
      * @param spender address The address which will spend the funds.
      * @return A uint256 specifying the amount of tokens still available for the spender.
      */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
      * @dev Transfer token to a specified address
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
      * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
      * Beware that changing an allowance with this method brings the risk that someone may use both the old
      * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
      * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
      * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
      * @param spender The address which will spend the funds.
      * @param value The amount of tokens to be spent.
      */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
      * @dev Transfer tokens from one address to another.
      * Note that while this function emits an Approval event, this is not required as per the specification,
      * and other compliant implementations may not emit the event.
      * @param from address The address which you want to send tokens from
      * @param to address The address which you want to transfer to
      * @param value uint256 the amount of tokens to be transferred
      */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
      * @dev Increase the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To increment
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param addedValue The amount of tokens to increase the allowance by.
      */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
      * @dev Decrease the amount of tokens that an owner allowed to a spender.
      * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
      * allowed value is better to use this function to avoid 2 calls (and wait until
      * the first transaction is mined)
      * From MonolithDAO Token.sol
      * Emits an Approval event.
      * @param spender The address which will spend the funds.
      * @param subtractedValue The amount of tokens to decrease the allowance by.
      */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
      * @dev Transfer token for a specified addresses
      * @param from The address to transfer from.
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
      * @dev Internal function that mints an amount of the token and assigns it to
      * an account. This encapsulates the modification of balances such that the
      * proper events are emitted.
      * @param account The account that will receive the created tokens.
      * @param value The amount that will be created.
      */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account.
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
      * @dev Approve an address to spend another addresses' tokens.
      * @param owner The address that owns the tokens.
      * @param spender The address that will spend the tokens.
      * @param value The number of tokens that can be spent.
      */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
      * @dev Internal function that burns an amount of the token of a given
      * account, deducting from the sender's allowance for said account. Uses the
      * internal burn function.
      * Emits an Approval event (reflecting the reduced allowance).
      * @param account The account whose tokens will be burnt.
      * @param value The amount that will be burnt.
      */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


//SourceUnit: owned.sol

pragma solidity ^0.5.10;
contract owned {
    address public owner;
 
    constructor() public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}