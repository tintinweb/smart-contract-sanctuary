pragma solidity ^0.8.0;

import "owner.sol";

contract UserStorage is Ownable {
    
    string name;
    address PoS_Contract_Address;
    
    constructor (
        string memory _name,
        address  _address
    ) {
        name = _name;
        PoS_Contract_Address = _address;
    }
    
    struct user_data {
        bytes32 user_root_hash;
        uint64 nonce;
        uint32 last_block_number;
    }
    
    event ChngeRootHash(
            address indexed user_address,
            address indexed node_address,
            bytes32 new_root_hash
        );
    mapping (address => user_data)  public users;
    
    function UpdateRootHash(address  _user_address, bytes32 _user_root_hash, uint64 _nonce, address _updater) public {
       
        require(_nonce >= users[_user_address].nonce && _user_root_hash != users[_user_address].user_root_hash);
        
        // updating new user_root hash
        users[_user_address].user_root_hash = _user_root_hash;
        users[_user_address].nonce = _nonce;
        
        emit ChngeRootHash(_user_address, _updater, _user_root_hash);
        // also need to make proof
    }
    
    
}