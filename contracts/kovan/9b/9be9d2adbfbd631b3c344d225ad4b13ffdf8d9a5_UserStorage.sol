/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

pragma solidity ^0.8.0;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract UserStorage is Ownable {
    
    string public name;
    address public PoS_Contract_Address;
    
    event ChngeRootHash(
            address indexed user_address,
            address indexed node_address,
            bytes32 new_root_hash
    );
    
    event ChangePoSContract(
        address indexed PoS_Contract_Address
    );
    
    constructor (
        string memory _name,
        address  _address
    ) {
        name = _name;
        PoS_Contract_Address = _address;
    }
    
    modifier onlyPoS() {
        require(msg.sender == PoS_Contract_Address);
        _;
    }
    
    function changePoS(address _new_address) onlyOwner public  {
        PoS_Contract_Address = _new_address;
        emit ChangePoSContract(_new_address);
    }
    
    struct user_data {
        bytes32 user_root_hash;
        uint64 nonce;
        uint32 last_block_number;
    }
    
    
    
    mapping (address => user_data)  public users;
    
    function UpdateRootHash(address  _user_address, bytes32 _user_root_hash, uint64 _nonce, address _updater) onlyPoS public {
       
        require(_nonce >= users[_user_address].nonce && _user_root_hash != users[_user_address].user_root_hash);
        
        users[_user_address].user_root_hash = _user_root_hash;
        users[_user_address].nonce = _nonce;
        
        emit ChngeRootHash(_user_address, _updater, _user_root_hash);
    }
    
    function UpdateLastBlockNumber(address  _user_address, uint32 _block_number) onlyPoS public {
        require (_block_number > users[_user_address].last_block_number);
        users[_user_address].last_block_number = _block_number;
    }
    
}