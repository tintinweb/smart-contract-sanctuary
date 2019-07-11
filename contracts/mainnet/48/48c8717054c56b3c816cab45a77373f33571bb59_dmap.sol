/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.5.10;

contract dmap {
    address owner;
    mapping(bytes32=>bytes32) values;

    event ValueUpdate( bytes32 indexed key
                     , bytes32 indexed value );
    event OwnerUpdate( address indexed oldOwner
                     , address indexed newOwner );

    constructor() public {
        owner = msg.sender;
        emit OwnerUpdate(address(0), owner);
    }
    function getValue(bytes32 key) public view returns (bytes32) {
        return values[key];
    }
    function setValue(bytes32 key, bytes32 value) public {
        assert(msg.sender == owner);
        values[key] = value;
        emit ValueUpdate(key, value);
    }
    function getOwner() public view returns (address) {
        return owner;
    }
    function setOwner(address newOwner) public {
        assert(msg.sender == owner);
        owner = newOwner;
        emit OwnerUpdate(msg.sender, owner);
    }
}