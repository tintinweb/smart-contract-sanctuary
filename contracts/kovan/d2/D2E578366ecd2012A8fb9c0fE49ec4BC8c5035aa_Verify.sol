// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

contract Verify is Ownable{
    //using ECDSA for bytes32;
   
   mapping (address => uint) public nonces;
   bytes32 public checkHash;
   bytes32 public finalHash;
   address public serverAddress;
   address public NFTAddress;
   address public DAOAddress;
   mapping (address => bool) public serverAddresses;
  
  
  constructor(address _serverAddress) public {
    serverAddress = _serverAddress;
    serverAddresses[_serverAddress] = true;
  }
  
  function getHash(address _mintAddress, string memory _tokenURI, uint256 _tokenId, uint256 _timeStamp) internal returns (bytes32) {
      checkHash = keccak256(abi.encodePacked(nonces[_mintAddress],_mintAddress, address(this), _timeStamp, _tokenURI, _tokenId));
    return keccak256(abi.encodePacked(nonces[_mintAddress],_mintAddress, address(this), _timeStamp, _tokenURI, _tokenId));
  }

  function metaDataVerify(address _mintAddress, string memory _tokenURI, uint256 _tokenId, uint256 timeStamp, bytes32 r, bytes32 s, uint8 v) public returns(bool) {
    require(_msgSender() == NFTAddress, "not called by NFT contract");
    bytes32 hashRecover = getHash(_mintAddress, _tokenURI, _tokenId, timeStamp);
    address signer = ecrecover(hashRecover, v, r, s);
    require( serverAddresses[signer],"SIGNER MUST BE SERVER"); 
    nonces[_msgSender()]++;
    return serverAddresses[signer];
  }

  function driverDataVerify(address ownerAddress, string memory rating, uint256 tokenId, uint256 timeStamp, bytes32 r, bytes32 s, uint8 v) public returns(bool){
    require(_msgSender() == DAOAddress, "not called by DAO contract");
    bytes32 hashRecover = getHash(ownerAddress, rating, tokenId, timeStamp);
    address signer = ecrecover(hashRecover, v, r, s);
    require( serverAddresses[signer],"SIGNER MUST BE SERVER"); 
    nonces[_msgSender()]++;
    return serverAddresses[signer];
  }

  function setNFTAddress (address _NFTAddress) public onlyOwner{
    require(_NFTAddress != address(0), "can't set as zero address");
    NFTAddress = _NFTAddress;
  }

  function setDAOAddress (address _DAOAddress) public onlyOwner{
    require(_DAOAddress != address(0), "can't set as zero address");
    DAOAddress = _DAOAddress;
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