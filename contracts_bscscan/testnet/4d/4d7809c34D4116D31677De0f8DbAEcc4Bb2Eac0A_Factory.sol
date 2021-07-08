// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./ISettings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Factory {
    using EnumerableSet for EnumerableSet.AddressSet;

    ISettings settings;

    enum GENERATOR {
        AUDITOR,
        REQUEST,
        AUDIT
    }

    struct Audit {
        bool exists;
        address contractAddress;
    }
    mapping(address => Audit) audits;

    EnumerableSet.AddressSet requests;

    EnumerableSet.AddressSet auditors;
    address[] public certifiedAuditors;

    address public auditorGenerator;
    address public requestGenerator;
    address public auditGenerator;

    event auditorRegistered(address indexed _auditor);
    event requestRegistered(address indexed _request);
    event auditRegistered(address indexed _audit);

    constructor(address _settings) {
        settings = ISettings(_settings);
    }

    function init(
        address _auditorGenerator,
        address _requestGenerator,
        address _auditGenerator
    ) external {
        require(msg.sender == settings.getAdminAddress());
        auditorGenerator = _auditorGenerator;
        requestGenerator = _requestGenerator;
        auditGenerator = _auditGenerator;
    }

    function getAuditByContract(address _contract)
        external
        view
        returns (address)
    {
        require(audits[_contract].exists, "NO AUDIT FOUND FOR THIS CONTRACT");

        return audits[_contract].contractAddress;
    }

    function doesRequestExist(address _request) external view returns (bool) {
        return requests.contains(_request);
    }

    function doesAuditorExist(address _auditor) external view returns (bool) {
        return auditors.contains(_auditor);
    }

    function getGenerator(GENERATOR _generator)
        external
        view
        returns (address)
    {
        if (_generator == GENERATOR.AUDITOR) {
            return auditorGenerator;
        } else if (_generator == GENERATOR.REQUEST) {
            return requestGenerator;
        }
        return auditGenerator;
    }

    modifier onlyRequestGenerator() {
        require(msg.sender == requestGenerator);
        _;
    }

    function registerRequest(address _request) external onlyRequestGenerator {
        requests.add(_request);
        emit requestRegistered(_request);
    }

    modifier onlyAuditGenerator() {
        require(msg.sender == auditGenerator);
        _;
    }

    function registerAudit(address _audit, address[] memory _contracts)
        external
        onlyAuditGenerator
    {
        for (uint256 index = 0; index < _contracts.length; index += 1) {
            audits[_contracts[index]].exists = true;
            audits[_contracts[index]].contractAddress = _audit;
        }

        emit auditRegistered(_audit);
    }

    function unregisterRequest() external {
        require(requests.contains(msg.sender));
        requests.remove(msg.sender);
    }

    modifier onlyAuditorGenerator() {
        require(msg.sender == auditorGenerator);
        _;
    }

    function registerAuditor(address _auditor) external onlyAuditorGenerator {
        auditors.add(_auditor);
        emit auditorRegistered(_auditor);
    }

    function removeCertifiedAuditor(address _certifiedAuditor) internal {
        for (uint256 index = 0; index < certifiedAuditors.length; index += 1) {
            if (certifiedAuditors[index] == _certifiedAuditor) {
                certifiedAuditors[index] = certifiedAuditors[
                    certifiedAuditors.length - 1
                ];
                certifiedAuditors.pop();
            }
        }
    }

    function updateCertifiedAuditor(bool _isCertified)
        external
    {
        require(auditors.contains(msg.sender));

        if (_isCertified) {
            certifiedAuditors.push(msg.sender);
        } else {
            removeCertifiedAuditor(msg.sender);
        }
    }

    function unregisterAuditor(bool _isCertified) external {
        require(auditors.contains(msg.sender));

        auditors.remove(msg.sender);
        if (_isCertified) {
            removeCertifiedAuditor(msg.sender);
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface ISettings {
  enum MAX_LENGTH {
      COMPANY_NAME,
      URL,
      CONTRACTS
  }

  function getMaxLength(MAX_LENGTH _index) external view returns (uint256);

  function getAuditDeliveryFeesPercentage() external view returns (uint256);

  function getAdminAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

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