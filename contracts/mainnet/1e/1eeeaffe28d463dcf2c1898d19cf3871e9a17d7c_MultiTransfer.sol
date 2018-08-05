pragma solidity ^0.4.24;

contract SNOVToken {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract MultiOwnable {

    mapping(address => bool) ownerMap;
    address[] public owners;

    event OwnerAdded(address indexed _newOwner);
    event OwnerRemoved(address indexed _oldOwner);

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    constructor() public {
        // Add default owner
        address owner = msg.sender;
        ownerMap[owner] = true;
        owners.push(owner);
    }

    function ownerCount() public constant returns (uint256) {
        return owners.length;
    }

    function isOwner(address owner) public constant returns (bool) {
        return ownerMap[owner];
    }

    function addOwner(address owner) public onlyOwner returns (bool) {
        if (!isOwner(owner) && owner != 0) {
            ownerMap[owner] = true;
            owners.push(owner);

            emit OwnerAdded(owner);
            return true;
        } else return false;
    }

    function removeOwner(address owner) public onlyOwner returns (bool) {
        if (isOwner(owner)) {
            ownerMap[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;

            emit OwnerRemoved(owner);
            return true;
        } else return false;
    }
}

contract MultiTransfer is MultiOwnable {
    
    function MultiTransaction(address _tokenAddress, address[] _addresses, uint256[] _values) public onlyOwner {
        SNOVToken token = SNOVToken(_tokenAddress);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.transfer(_addresses[i], _values[i]);
        }
    }
}