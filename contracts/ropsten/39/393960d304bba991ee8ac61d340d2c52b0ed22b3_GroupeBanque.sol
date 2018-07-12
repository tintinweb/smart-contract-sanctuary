pragma solidity ^0.4.23;

contract DocumentStore {

  event Created(
    address _creator,
    address _currentOwner
  );

  function getOwner() public view returns (address);
  function updateNotaireAddress (address _new) public;
  function updateBanqueAddress (address _new) public;
  function mintCopieExecutoire (bytes32 signedDocumentHash) public;
  function verifyCopieExecutoire (bytes32 signedDocumentHash) public;
  function acknowledgeCopieExecutoire (bytes32 signedDocumentHash) internal;
  function transfertCopieExecutoire(bytes32 _signedDocumentHash) public;
}

contract GroupeCE {
  function setStorageAddress (address _storageAddress) public;
  function getOwner() public view returns(address _owner);
  function getStorageAddress() public view returns(address);
}

contract GroupeBanque is GroupeCE {

  address public owner;
  address public storageAddress;

  constructor()
  public
  {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function getOwner() 
  public view returns(address _owner)
  {
    return owner;
  }

  function setStorageAddress (address _storageAddress)
  onlyOwner public {
    storageAddress = _storageAddress;
  }

  function getStorageAddress()
  public view returns(address _storageAddress)
  {
    return storageAddress;
  }

  function verifyCopieExecutoire(bytes32 _CE) 
  onlyOwner public 
  {
    require(storageAddress != address(0));
    DocumentStore d = DocumentStore(storageAddress);
    d.verifyCopieExecutoire(_CE);
  }

  function transfertCopieExecutoire(bytes32 _CE)
  onlyOwner public
  {
    require(storageAddress != address(0));
    DocumentStore d = DocumentStore(storageAddress);
    d.transfertCopieExecutoire(_CE);
  }
}