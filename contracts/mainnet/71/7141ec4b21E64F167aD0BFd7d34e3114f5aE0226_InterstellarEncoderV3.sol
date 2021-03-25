/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// Dependency file: openzeppelin-solidity/contracts/ownership/Ownable.sol

// pragma solidity ^0.4.24;


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


// Dependency file: contracts/interfaces/IInterstellarEncoderV3.sol

// pragma solidity ^0.4.24;

contract IInterstellarEncoderV3 {
    uint256 constant CLEAR_HIGH =  0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 1; // 1 is Atlantis, 0 is NaN.

    enum ObjectClass { 
        NaN,
        LAND,
        APOSTLE,
        OBJECT_CLASS_COUNT
    }

    function registerNewObjectClass(address _objectContract, uint8 objectClass) public;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId);

    function encodeTokenIdForOuterObjectContract(
        address _objectContract, address nftAddress, address _originNftAddress, uint128 _objectId, uint16 _producerId, uint8 _convertType) public view returns (uint256);

    function getContractAddress(uint256 _tokenId) public view returns (address);

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId);

    function getObjectClass(uint256 _tokenId) public view returns (uint8);

    function getObjectAddress(uint256 _tokenId) public view returns (address);

    function getProducerId(uint256 _tokenId) public view returns (uint16);

    function getOriginAddress(uint256 _tokenId) public view returns (address);

}

// Root file: contracts/InterstellarEncoderV3.sol

pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
// import "contracts/interfaces/IInterstellarEncoderV3.sol";

// TODO: upgrade.
contract InterstellarEncoderV3 is IInterstellarEncoderV3, Ownable {
    // [magic_number, chain_id, contract_id <2>, origin_chain_id, origin_contract_id<2>, object_class, convert_type, <6>, land, <128>]
    mapping(uint8 => address) public ownershipId2Address;
    mapping(address => uint8) public ownershipAddress2Id;

    mapping(address => uint8) public classAddress2Id;   // class
    // extended since V2
    mapping(uint8 => address) public classId2Address;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectId) public view returns (uint256 _tokenId) {
        uint16 contractId = ownershipAddress2Id[_tokenAddress];
        require(ownershipAddress2Id[_tokenAddress] > 0, "Contract address does not exist");

        _tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
            + (CHAIN_ID << 216) + (uint256(contractId) << 200) + (uint256(_objectClass) << 192) + (CURRENT_LAND << 128) + uint256(_objectId);
    }

    function encodeTokenIdForOuter(
        address _nftAddress, address _originNftAddress, uint8 _objectClass, uint128 _objectId, uint16 _producerId, uint8 _convertType) public view returns (uint256) {
        uint16 contractId = ownershipAddress2Id[_nftAddress];
        uint16 originContractId = ownershipAddress2Id[_originNftAddress];
        require(contractId > 0 && originContractId > 0 && _producerId > 0, "Contract address does not exist");

        uint256 tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
        + (CHAIN_ID << 216) + (uint256(originContractId) << 200) + (uint256(_objectClass) << 192) + (uint256(_convertType) << 184)+ (uint256(_producerId) << 128) + uint256(_objectId);

        return tokenId;
    }

    // TODO; newly added
    // @param _tokenAddress - objectOwnership
    // @param _objectContract - xxxBase contract
    function encodeTokenIdForOuterObjectContract(
        address _objectContract, address _nftAddress, address _originNftAddress, uint128 _objectId, uint16 _producerId, uint8 _convertType) public view returns (uint256) {
        require (classAddress2Id[_objectContract] > 0, "Object class for this object contract does not exist.");

        return encodeTokenIdForOuter(_nftAddress, _originNftAddress, classAddress2Id[_objectContract], _objectId, _producerId, _convertType);

    }
    // TODO; newly added
    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId) {
        require (classAddress2Id[_objectContract] > 0, "Object class for this object contract does not exist.");

        _tokenId = encodeTokenId(_tokenAddress, classAddress2Id[_objectContract], _objectId);
    }

    function registerNewOwnershipContract(address _nftAddress, uint8 _nftId) public onlyOwner {
        ownershipAddress2Id[_nftAddress] = _nftId;
        ownershipId2Address[_nftId] = _nftAddress;
    }

    function registerNewObjectClass(address _objectContract, uint8 _objectClass) public onlyOwner {
        classAddress2Id[_objectContract] = _objectClass;
        classId2Address[_objectClass] = _objectContract;
    }

    function getProducerId(uint256 _tokenId) public view returns (uint16) {
        return uint16((_tokenId >> 128) & 0xff);
    }

    function getContractAddress(uint256 _tokenId) public view returns (address) {
        return ownershipId2Address[uint8((_tokenId >> 240) & 0xff)];
    }

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId) {
        return uint128(_tokenId & CLEAR_HIGH);
    }

    function getObjectClass(uint256 _tokenId) public view returns (uint8) {
        return uint8((_tokenId << 56) >> 248);
    }

    function getObjectAddress(uint256 _tokenId) public view returns (address) {
        return classId2Address[uint8((_tokenId << 56) >> 248)];
    }

    // TODO; newly added
    function getOriginAddress(uint256 _tokenId) public view returns (address) {
        uint8 originContractId = uint8((_tokenId >> 200) & 0xff);
        return ownershipId2Address[originContractId];

    }
}