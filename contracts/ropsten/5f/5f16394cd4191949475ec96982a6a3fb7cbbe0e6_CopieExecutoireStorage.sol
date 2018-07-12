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

contract CopieExecutoireStorage is DocumentStore {

  address public owner;
  address public contratNotaire;
  address public contratBanque;
  uint256 public count;

  mapping (bytes32 => CopieExecutoire) documents;

  struct CopieExecutoire {
    address creator;
    address currentOwner;
    bool acknowledgment;
    bool verified;
  }

  constructor() 
  public
  {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyNotaire {
    require(contratNotaire != address(0));
    require(msg.sender == contratNotaire);
    _;
  }

  modifier onlyBanque {
    require(contratBanque != address(0));
    require(msg.sender == contratBanque);
    _;   
  }

  modifier onlyApproved {
    require(msg.sender == contratBanque);
    _;  
  }

  function kill()
  onlyOwner public
  {
    selfdestruct(owner);
  }

  function getOwner()
  public view returns (address _owner)
  {
    return owner;
  }

  function getNotaire()
  public view returns (address _contratNotaire)
  {
    return contratNotaire;
  }

  function getBanque()
  public view returns (address _contratBanque)
  {
    return contratBanque;
  }

  function getNumberOfCE()
  public view returns (uint256 _count)
  {
    return count;
  }

  function updateNotaireAddress (address _contratNotaire)
  onlyOwner public {
    contratNotaire = _contratNotaire;
  }

  function updateBanqueAddress (address _contratBanque)
  onlyOwner public {
    contratBanque = _contratBanque;
  }

  function mintCopieExecutoire (bytes32 _signedDocumentHash)
  onlyNotaire public 
  {
    require(documents[_signedDocumentHash].creator == address(0));
    documents[_signedDocumentHash] = CopieExecutoire(
      msg.sender,
      msg.sender,
      false,
      false
      );
    count = count + 1;
    emit Created(msg.sender, msg.sender);
  }

  function verifyCopieExecutoire (bytes32 _signedDocumentHash)
  onlyBanque public
  {
    require(documents[_signedDocumentHash].creator != address(0));
    documents[_signedDocumentHash].verified = true;
  }

  function acknowledgeCopieExecutoire (bytes32 _signedDocumentHash)
  internal
  {
    require(documents[_signedDocumentHash].verified == true);
    documents[_signedDocumentHash].acknowledgment = true;
  }

  function transfertCopieExecutoire (bytes32 _signedDocumentHash)
  onlyBanque public
  {
    require(documents[_signedDocumentHash].creator != address(0));
    acknowledgeCopieExecutoire(_signedDocumentHash);
    documents[_signedDocumentHash].currentOwner = msg.sender;
    emit Created(
      documents[_signedDocumentHash].creator,
      documents[_signedDocumentHash].currentOwner
      );
  }

  function getCEdetails (bytes32 _signedDocumentHash)
  public view returns(address _creator, address _currentOwner, bool _verified, bool _acknowledgment)
  {
    return (
    documents[_signedDocumentHash].creator,
    documents[_signedDocumentHash].currentOwner,
    documents[_signedDocumentHash].verified,
    documents[_signedDocumentHash].acknowledgment
    );
  }
}