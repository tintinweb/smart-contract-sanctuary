/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity >=0.8.6;

contract Bee {
    
    address public owner;
    
    mapping(uint => string) public script;
    
    constructor() {
        owner = msg.sender;
    }
    
    function storeScript(string memory _script, uint id) external {
        require(msg.sender == owner, "Not owner");
        
        require(StringUtils.equal(script[id], ""), "ID Already Used");
        
        script[id] = _script;
    }
    
    function returnScript(uint id) external view returns (string memory) {
        return script[id];
    }
}

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) public returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) public returns (bool) {
        return compare(_a, _b) == 0;
    }
    
}