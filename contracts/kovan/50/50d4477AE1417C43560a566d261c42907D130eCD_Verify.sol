// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";
//import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Verify is Ownable{
    //using ECDSA for bytes32;
  
  mapping(string => mapping(string => uint)) public noncesParentIdChildId; //nonce for each parentId and childid (e.g. projectId and  courseId or CourseId and questId)
  mapping(string => uint) public thresholdNoncesById;//nonce for each parentId Threshold (e.g. projectId for course and Course Id for quest)
  address public serverAddress;
  //mapping (address => bool)  public serverAddresses;
  mapping (address => bool) public approvers;
  
  constructor(address _serverAddress, address[] memory _approvers){
      //serverAddresses[_serverAddress] = true;
      require(_serverAddress != address(0));
      serverAddress = _serverAddress;
      for (uint i=0; i< _approvers.length; i++){
        approvers[_approvers[i]] = true;
      }
  }
  
  function getHash(address _senderAddress, string memory _objectId, string memory _parentId, address _contractAddress) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(noncesParentIdChildId[_parentId][_objectId], _senderAddress, _contractAddress, address(this), _objectId));
  }

  function metaDataVerify(address _senderAddress, string memory _objectId, string memory _parentId, bytes32 r, bytes32 s, uint8 v) public returns(bool) {
    bytes32 hashRecover = getHash(_senderAddress, _objectId, _parentId, _msgSender());
    address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashRecover)), v, r, s);
    require( signer == serverAddress,"SIGNER MUST BE SERVER"); 
    //nonces[msg.sender]++;
    noncesParentIdChildId[_parentId][_objectId]++;
    return signer == serverAddress;
    //Call NFT mint function(address, _did, _questID)
  }

  function thresholdVerify(address _senderAddress, string memory _objectId, uint votesNeeded, bytes32 r, bytes32 s, uint8 v) public returns(bool){
    bytes32 hashRecover = keccak256(abi.encodePacked(thresholdNoncesById[_objectId], votesNeeded, _senderAddress, _msgSender(), address(this), _objectId));
    address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hashRecover)), v, r, s);
    require( signer == serverAddress,"SIGNER MUST BE SERVER"); 
    thresholdNoncesById[_objectId]++;
    return signer == serverAddress;
  }

  function setServerAddress(address _newAddress) public{
    require(approvers[_msgSender()], "must be approved");
    require(_newAddress != address(0));
    serverAddress = _newAddress;
  }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}