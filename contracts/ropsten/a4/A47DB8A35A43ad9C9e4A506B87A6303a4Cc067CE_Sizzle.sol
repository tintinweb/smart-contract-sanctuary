// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.6 <0.9.0;

library SignedMath {
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? b : a;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.6 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./SignedMath.sol";

contract Sizzle {
    enum CertStatus {Invalid, Valid, Revoked}

    struct CertMetadata {
        address owner;
        string domain;
        string pubKey;
        int256 reputation;
        int256 reputationMax;
        CertStatus status;
    }

    struct CertParticipation {
        EnumerableSet.AddressSet endUser;
        EnumerableSet.AddressSet endorser;
        EnumerableSet.AddressSet denier;
    }

    struct PeerMetadata {
        address addr;
        int256 reputation;
    }

    int256 REPUTATION_THRESHOLD = 2;
    int256 PEER_REPUTATION_RATING_COUNT = 30;
    int256 PEER_REPUTATION_MAX = 100;
    int256 PEER_REPUTATION_PRECISION = 10000;

    mapping(string => CertMetadata) certs;
    mapping(string => CertParticipation) participations;
    mapping(address => PeerMetadata) peers;
    mapping(address => int256[]) peersRating;

    event CertPublishRequestCreated(
        address owner,
        string domain,
        string pubKey
    );
    event CertRekeyed(address owner, string domain, string pubKey);
    event CertRevoked(address owner, string domain);
    event CertValid(
        address owner,
        string domain,
        string pubKey,
        int256 reputation
    );
    event CertEndorsed(string domain, address peer);
    event CertDenied(string domain, address peer);

    constructor() {
        PeerMetadata storage peer = peers[msg.sender];
        peer.addr = msg.sender;
        peer.reputation = PEER_REPUTATION_MAX;
        for (int256 i = 0; i < PEER_REPUTATION_RATING_COUNT; i++) {
            peersRating[msg.sender].push(1);
        }
    }

    function certPublishRequest(string memory domain, string memory pubKey)
        public
    {
        CertMetadata storage c = certs[domain];
        require(c.owner == address(0));

        c.owner = msg.sender;
        c.domain = domain;
        c.pubKey = pubKey;
        c.reputation = 0;
        c.reputationMax = 0;
        c.status = CertStatus.Invalid;

        emit CertPublishRequestCreated(c.owner, c.domain, c.pubKey);
    }

    function certRekey(string memory domain, string memory pubKey) public {
        CertMetadata storage c = certs[domain];
        require(c.owner == msg.sender);

        c.pubKey = pubKey;
        c.reputation = 0;
        c.reputationMax = 0;

        emit CertRekeyed(c.owner, c.domain, c.pubKey);
    }

    function certRevoke(string memory domain) public {
        CertMetadata storage c = certs[domain];
        require(c.owner == msg.sender);
        require(c.status != CertStatus.Revoked);

        c.status = CertStatus.Revoked;
        emit CertRevoked(c.owner, c.domain);
    }

    function calculateCertValidity(string memory domain) private {
        CertMetadata storage c = certs[domain];

        if (
            c.status != CertStatus.Revoked &&
            c.status != CertStatus.Valid &&
            c.reputation * REPUTATION_THRESHOLD >= c.reputationMax
        ) {
            c.status = CertStatus.Valid;
            emit CertValid(c.owner, c.domain, c.pubKey, c.reputation);
        }
    }

    function certEndorseByPeer(string memory domain) public {
        PeerMetadata storage peer = peers[msg.sender];
        CertMetadata storage cert = certs[domain];
        CertParticipation storage participation = participations[domain];

        require(cert.owner != address(0));
        require(cert.owner != msg.sender);
        require(!EnumerableSet.contains(participation.endUser, msg.sender));
        require(!EnumerableSet.contains(participation.endorser, msg.sender));
        require(!EnumerableSet.contains(participation.denier, msg.sender));
        require(peer.addr != address(0));

        cert.reputation += peer.reputation;
        cert.reputationMax += PEER_REPUTATION_MAX;
        EnumerableSet.add(participation.endorser, msg.sender);

        emit CertEndorsed(domain, peer.addr);
        calculateCertValidity(domain);
    }

    function certDenyByPeer(string memory domain) public {
        PeerMetadata storage peer = peers[msg.sender];
        CertMetadata storage cert = certs[domain];
        CertParticipation storage participation = participations[domain];

        require(cert.owner != address(0));
        require(cert.owner != msg.sender);
        require(!EnumerableSet.contains(participation.endUser, msg.sender));
        require(!EnumerableSet.contains(participation.endorser, msg.sender));
        require(!EnumerableSet.contains(participation.denier, msg.sender));
        require(peer.addr != address(0));

        cert.reputation -= peer.reputation;
        cert.reputationMax += PEER_REPUTATION_MAX;
        EnumerableSet.add(participation.denier, msg.sender);

        emit CertDenied(domain, peer.addr);
        calculateCertValidity(domain);
    }

    function calculatePeerReputation(address addr) private {
        int256[] storage peerRating = peersRating[addr];
        int256 ratingLen = int256(peerRating.length);
        int256 startIdx = ratingLen - PEER_REPUTATION_RATING_COUNT;
        if (startIdx < 0) {
            startIdx = 0;
        }
        int256 significantRatingLen = ratingLen - startIdx;
        int256 sumF =
            (((startIdx + 1) / (ratingLen + 1) + 1) * significantRatingLen) / 2;
        int256 sumR = 0;
        if (sumF != 0) {
            for (int256 i = startIdx; i < ratingLen; i++) {
                int256 p =
                    ((PEER_REPUTATION_PRECISION * (i + 1)) / ratingLen) / sumF;
                sumR += p * peerRating[uint256(i)];
            }
        }
        int256 reputation =
            sumR / (PEER_REPUTATION_PRECISION / PEER_REPUTATION_MAX);
        reputation = SignedMath.max(0, SignedMath.min(100, reputation));

        PeerMetadata storage peer = peers[addr];
        peer.reputation = reputation;
    }

    function certEndorseByUser(string memory domain) public {
        CertMetadata storage cert = certs[domain];
        CertParticipation storage participation = participations[domain];

        require(cert.owner != address(0));
        require(cert.owner != msg.sender);
        require(!EnumerableSet.contains(participation.endUser, msg.sender));
        require(!EnumerableSet.contains(participation.endorser, msg.sender));
        require(!EnumerableSet.contains(participation.denier, msg.sender));

        int256 rating = 1;
        uint256 endorserLen = EnumerableSet.length(participation.endorser);
        for (uint256 i = 0; i < endorserLen; i++) {
            address addr = EnumerableSet.at(participation.endorser, i);
            peersRating[addr].push(rating);
            calculatePeerReputation(addr);
        }

        uint256 denierLen = EnumerableSet.length(participation.denier);
        for (uint256 i = 0; i < denierLen; i++) {
            address addr = EnumerableSet.at(participation.denier, i);
            peersRating[addr].push(-1 * rating);
            calculatePeerReputation(addr);
        }

        EnumerableSet.add(participation.endUser, msg.sender);
    }

    function certDenyByUser(string memory domain) public {
        CertMetadata storage cert = certs[domain];
        CertParticipation storage participation = participations[domain];

        require(cert.owner != address(0));
        require(cert.owner != msg.sender);
        require(!EnumerableSet.contains(participation.endUser, msg.sender));
        require(!EnumerableSet.contains(participation.endorser, msg.sender));
        require(!EnumerableSet.contains(participation.denier, msg.sender));

        int256 rating = -1;
        uint256 endorserLen = EnumerableSet.length(participation.endorser);
        for (uint256 i = 0; i < endorserLen; i++) {
            address addr = EnumerableSet.at(participation.endorser, i);
            peersRating[addr].push(rating);
            calculatePeerReputation(addr);
        }

        uint256 denierLen = EnumerableSet.length(participation.denier);
        for (uint256 i = 0; i < denierLen; i++) {
            address addr = EnumerableSet.at(participation.denier, i);
            peersRating[addr].push(-1 * rating);
            calculatePeerReputation(addr);
        }

        EnumerableSet.add(participation.endUser, msg.sender);
    }

    function certQuery(string memory domain)
        public
        view
        returns (CertMetadata memory cert)
    {
        return certs[domain];
    }

    function peerRegister() public {
        PeerMetadata storage peer = peers[msg.sender];
        require(peer.addr == address(0));

        peer.addr = msg.sender;
        peer.reputation = 0;
    }

    function peerQuery(address addr)
        public
        view
        returns (PeerMetadata memory peer)
    {
        return peers[addr];
    }
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

