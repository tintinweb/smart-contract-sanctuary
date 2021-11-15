pragma solidity ^0.8.4;

/**
* @dev An interface for contracts implementing a DNSSEC digest.
*/
interface Digest {
    /**
    * @dev Verifies a cryptographic hash.
    * @param data The data to hash.
    * @param hash The hash to compare to.
    * @return True iff the hashed data matches the provided hash value.
    */
    function verify(bytes calldata data, bytes calldata hash) external virtual pure returns (bool);
}

pragma solidity ^0.8.4;

import "./Digest.sol";

/**
* @dev Implements a dummy DNSSEC digest that approves all hashes, for testing.
*/
contract DummyDigest is Digest {
    function verify(bytes calldata, bytes calldata) external override pure returns (bool) { return true; }
}

