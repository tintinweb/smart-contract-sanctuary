/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;




/**
  @title ChangeContract
  @notice This interface is the one used by the governance system.
  @dev If you plan to do some changes to a system governed by this project you should write a contract
  that does those changes, like a recipe. This contract MUST not have ANY kind of public or external function
  that modifies the state of this ChangeContract, otherwise you could run into front-running issues when the governance
  system is fully in place.
 */
interface ChangeContract {
    /**
      @notice Override this function with a recipe of the changes to be done when this ChangeContract
      is executed
     */
    function execute() external;
}


/**
  @title Governor
  @notice Governor interface. This functions should be overwritten to
  enable the comunnication with the rest of the system
  */
interface IGovernor {
    /**
      @notice Function to be called to make the changes in changeContract
      @dev This function should be protected somehow to only execute changes that
      benefit the system. This decision process is independent of this architechture
      therefore is independent of this interface too
      @param changeContract Address of the contract that will execute the changes
     */
    function executeChange(ChangeContract changeContract) external;

    /**
      @notice Function to be called to make the changes in changeContract
      @param _changer Address of the contract that will execute the changes
     */
    function isAuthorizedChanger(address _changer) external view returns (bool);
}


/**
  @title Governed
  @notice Base contract to be inherited by governed contracts
  @dev This contract is not usable on its own since it does not have any _productive useful_ behaviour
  The only purpose of this contract is to define some useful modifiers and functions to be used on the
  governance aspect of the child contract
  */
contract Governed {
    /**
      @notice The address of the contract which governs this one
     */
    IGovernor public governor;

    string private constant NOT_AUTHORIZED_CHANGER = "not_authorized_changer";

    /**
      @notice Modifier that protects the function
      @dev You should use this modifier in any function that should be called through
      the governance system
     */
    modifier onlyAuthorizedChanger() {
        require(governor.isAuthorizedChanger(msg.sender), NOT_AUTHORIZED_CHANGER);
        _;
    }

    /**
      @notice Initialize the contract with the basic settings
      @dev This initialize replaces the constructor but it is not called automatically.
      It is necessary because of the upgradeability of the contracts
      @param _governor Governor address
     */
    function _initialize(IGovernor _governor) internal {
        governor = _governor;
    }

    /**
      @notice Change the contract's governor. Should be called through the old governance system
      @param newIGovernor New governor address
     */
    function changeIGovernor(IGovernor newIGovernor) external onlyAuthorizedChanger {
        governor = newIGovernor;
    }

    /**
      @notice This method is used by a change contract to access the storage freely even without a setter.
      @param data the serialized function arguments
     */
    function delegateCallToChanger(bytes calldata data)
        external
        onlyAuthorizedChanger
        returns (bytes memory)
    {
        address changerContrat = msg.sender;
        (bool success, bytes memory result) = changerContrat.delegatecall(
            abi.encodeWithSignature("impersonate(bytes)", data)
        );
        require(success, "Error in delegate call");
        return result;
    }

    // Leave a gap betweeen inherited contracts variables in order to be
    // able to add more variables in them later
    uint256[50] private upgradeGap;
}



/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}



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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
  @notice Based on heavily on EnumberableSet, but with the ability to clear all the contents.
 */
library AddressSetLib {
    using SafeMath for uint256;

    struct AddressSet {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    function init() internal pure returns (AddressSet memory) {
        return AddressSet({_values: new address[](0)});
    }

    /**
     * @dev Removes all value from a set. O(N).
     *
     */
    function clear(AddressSet storage set) internal {
        for (uint256 i = 0; i < set._values.length; i++) {
            delete set._indexes[set._values[i]];
        }
        delete set._values;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(AddressSet storage set, address value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            address lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1;
            // All indexes are 1-based

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
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        require(set._values.length > index, "index out of bounds");
        return set._values[index];
    }

    /**
     * @dev Returns the set contents as an array
     */
    function asArray(AddressSet storage set)
        internal
        view
        returns (address[] memory selectedOracles)
    {
        return set._values;
    }
}


interface IRegistry {
    // *** Getter Methods ***
    function getDecimal(bytes32 _key) external view returns (int232 base, int16 exp);

    function getUint(bytes32 _key) external view returns (uint248);

    function getString(bytes32 _key) external view returns (string memory);

    function getAddress(bytes32 _key) external view returns (address);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int248);

    // *** Setter Methods ***
    function setDecimal(
        bytes32 _key,
        int232 _base,
        int16 _exp
    ) external;

    function setUint(bytes32 _key, uint248 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setAddress(bytes32 _key, address _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int248 _value) external;

    // *** Delete Methods ***
    function deleteDecimal(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteAddress(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    // Nov 2020 Upgrade
    // *** Getter Methods ***
    function getAddressArrayLength(bytes32 _key) external view returns (uint256);

    function getAddressArrayElementAt(bytes32 _key, uint256 idx) external view returns (address);

    function pushAddressArrayElement(bytes32 _key, address _addr) external;

    function getAddressArray(bytes32 _key) external view returns (address[] memory);

    function addressArrayContains(bytes32 _key, address value) external view returns (bool);

    // *** Setters ***
    function pushAddressArray(bytes32 _key, address[] memory data) external;

    function clearAddressArray(bytes32 _key) external;

    function removeAddressArrayElement(bytes32 _key, address value) external;
}


// Based on https://github.com/fravoll/solidity-patterns EternalStorage
contract GovernedRegistry is Initializable, Governed, IRegistry {
    using AddressSetLib for AddressSetLib.AddressSet;

    struct UIntVal {
        bool b;
        uint248 v;
    }

    struct BoolVal {
        bool b;
        bool v;
    }

    struct IntVal {
        bool b;
        int248 v;
    }

    struct DecimalVal {
        bool b;
        int232 base;
        int16 exp;
    }

    mapping(bytes32 => DecimalVal) internal decimalStorage;
    mapping(bytes32 => UIntVal) internal uIntStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => BoolVal) internal boolStorage;
    mapping(bytes32 => IntVal) internal intStorage;
    /////////// Nov 2020 UPGRADE
    mapping(bytes32 => AddressSetLib.AddressSet) internal addressArrayStorage;

    /**
      @notice Initialize the contract with the basic settings
      @dev This initialize replaces the constructor but it is not called automatically.
      It is necessary because of the upgradeability of the contracts
      @param _governor Governor address
     */
    function initialize(IGovernor _governor) external initializer {
        Governed._initialize(_governor);
    }

    // *** Getter Methods ***
    function getDecimal(bytes32 _key) external view override returns (int232 base, int16 exp) {
        require(decimalStorage[_key].b, "Invalid key");
        return (decimalStorage[_key].base, decimalStorage[_key].exp);
    }

    function getUint(bytes32 _key) external view override returns (uint248) {
        require(uIntStorage[_key].b, "Invalid key");
        return uIntStorage[_key].v;
    }

    function getString(bytes32 _key) external view override returns (string memory) {
        require(bytes(stringStorage[_key]).length != 0, "Invalid key");
        return stringStorage[_key];
    }

    function getAddress(bytes32 _key) external view override returns (address) {
        require(addressStorage[_key] != address(0), "Invalid key");
        return addressStorage[_key];
    }

    function getBytes(bytes32 _key) external view override returns (bytes memory) {
        require(bytesStorage[_key].length != 0, "Invalid key");
        return bytesStorage[_key];
    }

    function getBool(bytes32 _key) external view override returns (bool) {
        require(boolStorage[_key].b, "Invalid key");
        return boolStorage[_key].v;
    }

    function getInt(bytes32 _key) external view override returns (int248) {
        require(intStorage[_key].b, "Invalid key");
        return intStorage[_key].v;
    }

    // *** Setter Methods ***
    function setDecimal(
        bytes32 _key,
        int232 _base,
        int16 _exp
    ) external override onlyAuthorizedChanger {
        decimalStorage[_key] = DecimalVal(true, _base, _exp);
    }

    function setUint(bytes32 _key, uint248 _value) external override onlyAuthorizedChanger {
        uIntStorage[_key] = UIntVal(true, _value);
    }

    function setString(bytes32 _key, string calldata _value)
        external
        override
        onlyAuthorizedChanger
    {
        require(bytes(_value).length != 0, "Invalid value");
        stringStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) external override onlyAuthorizedChanger {
        require(_value != address(0), "Invalid value");
        addressStorage[_key] = _value;
    }

    function setBytes(bytes32 _key, bytes calldata _value) external override onlyAuthorizedChanger {
        require(_value.length != 0, "Invalid value");
        bytesStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) external override onlyAuthorizedChanger {
        boolStorage[_key] = BoolVal(true, _value);
    }

    function setInt(bytes32 _key, int248 _value) external override onlyAuthorizedChanger {
        intStorage[_key] = IntVal(true, _value);
    }

    // *** Delete Methods ***
    function deleteDecimal(bytes32 _key) external override onlyAuthorizedChanger {
        delete decimalStorage[_key];
    }

    function deleteUint(bytes32 _key) external override onlyAuthorizedChanger {
        delete uIntStorage[_key];
    }

    function deleteString(bytes32 _key) external override onlyAuthorizedChanger {
        delete stringStorage[_key];
    }

    function deleteAddress(bytes32 _key) external override onlyAuthorizedChanger {
        delete addressStorage[_key];
    }

    function deleteBytes(bytes32 _key) external override onlyAuthorizedChanger {
        delete bytesStorage[_key];
    }

    function deleteBool(bytes32 _key) external override onlyAuthorizedChanger {
        delete boolStorage[_key];
    }

    function deleteInt(bytes32 _key) external override onlyAuthorizedChanger {
        delete intStorage[_key];
    }

    /////////// Nov 2020 UPGRADE

    // *** Getter Methods ***
    function getAddressArray(bytes32 _key) external view override returns (address[] memory) {
        require(addressArrayStorage[_key].length() != 0, "Invalid key");
        return addressArrayStorage[_key].asArray();
    }

    function getAddressArrayLength(bytes32 _key) external view override returns (uint256) {
        return addressArrayStorage[_key].length();
    }

    function getAddressArrayElementAt(bytes32 _key, uint256 idx)
        external
        view
        override
        returns (address)
    {
        require(addressArrayStorage[_key].length() != 0, "Invalid key");
        return addressArrayStorage[_key].at(idx);
    }

    function addressArrayContains(bytes32 _key, address value)
        external
        view
        override
        returns (bool)
    {
        return addressArrayStorage[_key].contains(value);
    }

    // *** Setters ***
    function pushAddressArrayElement(bytes32 _key, address _addr)
        external
        override
        onlyAuthorizedChanger
    {
        addressArrayStorage[_key].add(_addr);
    }

    function pushAddressArray(bytes32 _key, address[] memory data)
        external
        override
        onlyAuthorizedChanger
    {
        for (uint256 i = 0; i < data.length; i++) {
            addressArrayStorage[_key].add(data[i]);
        }
    }

    function clearAddressArray(bytes32 _key) external override onlyAuthorizedChanger {
        addressArrayStorage[_key].clear();
    }

    function removeAddressArrayElement(bytes32 _key, address value)
        external
        override
        onlyAuthorizedChanger
    {
        addressArrayStorage[_key].remove(value);
    }
}