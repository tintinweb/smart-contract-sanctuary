pragma solidity ^0.4.21;

contract Database {

    address public owner;
    address public newOwner;
    
    uint private id;
	
    struct Data {
        string key;
        string value;
    }

    mapping(uint=>Data) public datam;
    
    event Inserted(
        uint id,
        string key,
        string value
    );

    event OwnershipTransferred(
        address indexed _from,
        address indexed _to
    );

    function constructor() public {
        owner = msg.sender;
        id = 1;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function insert(string _key, string _value) onlyOwner public {

        datam[id] = Data({
            key: _key,
            value: _value
        });
        
        emit Inserted(id, _key, _value);

        id++;
        
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        newOwner = _newOwner;
    }
        
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }

}