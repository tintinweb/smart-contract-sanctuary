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

contract BlockchainId is Ownable {

    event NewCompany(bytes32 companyId, bytes32 merkleRoot);
    event ChangeCompany(bytes32 companyId, bytes32 merkleRoot);
    event DeleteCompany(bytes32 companyId);

    mapping (bytes32 => bytes32) companyMap;

    function _createCompany(bytes32 companyId, bytes32 merkleRoot) public onlyOwner() {
        companyMap[companyId] = merkleRoot;
        emit NewCompany(companyId, merkleRoot);
    }

    function _createCompanies(bytes32[] companyIds, bytes32[] merkleRoots) public onlyOwner() {
        require(companyIds.length == merkleRoots.length);
        for (uint i = 0; i < companyIds.length; i++) {
            _createCompany(companyIds[i], merkleRoots[i]);
        }
    }

    function getCompany(bytes32 companyId) public view returns (bytes32) {
        return companyMap[companyId];
    }

    function _updateCompany(bytes32 companyId, bytes32 merkleRoot) public onlyOwner() {
        companyMap[companyId] = merkleRoot;
        emit ChangeCompany(companyId, merkleRoot);
    }

    function _updateCompanies(bytes32[] companyIds, bytes32[] merkleRoots) public onlyOwner() {
        require(companyIds.length == merkleRoots.length);
        for (uint i = 0; i < companyIds.length; i++) {
            _updateCompany(companyIds[i], merkleRoots[i]);
        }
    }

    function _deleteCompany(bytes32 companyId) public onlyOwner() {
        delete companyMap[companyId];
        emit DeleteCompany(companyId);
    }
}