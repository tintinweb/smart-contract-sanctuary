pragma solidity ^0.4.24;
pragma experimental "v0.5.0";
//pragma experimental ABIEncoderV2;

contract ProcessAnchorContract {

    struct Anchor {
        // Milis from UTC Epoch
        uint128 when;

        // The "who" who caused the "what"
        string who;

        // The step, location, position of process
        string where;

        // The decision or action that was taken at "where" by "who"
        string what;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    address owner;
    string processId;
    Anchor[] anchors;

    constructor(string memory _processId) public {
        owner = msg.sender;
        processId = _processId;
    }

    function addAnchor(uint128 when, string memory who, string memory where, string memory what) public {
        requireBoundedStringSize(who, 255);
        requireBoundedStringSize(where, 255);
        requireBoundedStringSize(what, 255);

        Anchor memory newAnchor = Anchor(when, who, where, what);
        anchors.push(newAnchor);
    }

    // Helper function to compare two given strings. Based on the assumption that if their hashes are equals,
    // then so are their values. In other words, a collision is considered sufficiently unlikely.
    function stringEquals(string memory one, string memory two) internal pure returns (bool) {
        bytes memory bytes_one = bytes(one);
        bytes memory bytes_two = bytes(two);

        if (bytes_one.length != bytes_two.length) {
            // if length doesn&#39;t match, don&#39;t even have to hash
            return false;
        }

        return keccak256(bytes_one) == keccak256(bytes_two);
    }

    // Helper function to bound the size of accepted string values, useful for keeping gas costs bounded
    function requireBoundedStringSize(string memory value, uint bound) internal pure {
        require((bytes(value)).length <= bound);
    }
}