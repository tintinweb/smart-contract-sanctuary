pragma solidity ^0.4.23;

contract Bitmonds {
    struct BitmondsOwner {
        string bitmond;
        string owner;
    }

    BitmondsOwner[] internal registry;

    event Take(string Owner);

    function take(string Bitmond, string Owner) public {
        registry.push(BitmondsOwner(Bitmond, Owner));
    }

    function lookup(string Bitmond) public view returns (string Owner) {
        for (uint i = 0; i < registry.length; i++) {
            if (compareStrings(Bitmond, registry[i].bitmond)) {
                Owner = registry[i].owner;
            }
        }
    }

    function compareStrings (string a, string b) internal pure returns (bool) {
        return (keccak256(a) == keccak256(b));
    }
}