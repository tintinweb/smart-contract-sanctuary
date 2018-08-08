pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Profile is Ownable {
    struct User {
        string nickname;
        string avatar;
        string payload;
        bool isEntity;
    }
    
    mapping(address => User) private users;
    mapping(bytes32 => address) private addresses;
    
    function newUserFrom(address _addr, string _nickname, string _avatar, string _payload) public onlyOwner {
        if (!users[_addr].isEntity) {
            users[_addr] = User(_nickname, _avatar, _payload, true);
            addresses[keccak256(_nickname)] = _addr;
        }
    }
    
    function newUser(string _nickname, string _avatar, string _payload) public {
        if (!users[msg.sender].isEntity) {
            users[msg.sender] = User(_nickname, _avatar, _payload, true);
            addresses[keccak256(_nickname)] = msg.sender;
        }
    }
    
    function getNicknameByAddress(address _addr) public constant returns(string) {
        return users[_addr].nickname;
    }
    
    function getNickname() public constant returns(string) {
        return getNicknameByAddress(msg.sender);
    }
    
    function getAddressByNickname(string _nickname) public constant returns(address) {
        return addresses[keccak256(_nickname)];
    }
    
    function getAvatarByAddress(address _addr) public constant returns(string) {
        return users[_addr].avatar;
    }
    
    function getAvatarByNickname(string _nickname) public constant returns(string) {
        return getAvatarByAddress(getAddressByNickname(_nickname));
    }
    
    function getAvatar() public constant returns(string) {
        return getAvatarByAddress(msg.sender);
    }
    
    function setAvatar(string _avatar) public {
        users[msg.sender].avatar = _avatar;
    }
    
    function setAvatarFrom(address _addr, string _avatar) public onlyOwner {
        users[_addr].avatar = _avatar;
    }
    
    function setPayloadFrom(address _addr, string _payload) public onlyOwner {
        users[_addr].payload = _payload;
    }
    
    function setPayload(string _payload) public {
        users[msg.sender].payload = _payload;
    }
    
    function getPayloadFrom(address _addr) public constant onlyOwner returns(string) {
        return users[_addr].payload;
    }
    
    function getPayload() public constant returns(string) {
        return users[msg.sender].payload;
    }
    
    function removeUser(address _addr) public onlyOwner {
        delete addresses[keccak256(getNicknameByAddress(_addr))];
        delete users[_addr];
    }
}