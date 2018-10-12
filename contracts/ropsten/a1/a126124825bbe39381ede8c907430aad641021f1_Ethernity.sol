pragma solidity ^0.4.17;

contract Ethernity {
  mapping (address => bytes32) internal name;  //mapping of addresses to names
  mapping (address => bool) internal isIssuer;  //mapping of addresses to bool whether adress is registered as issuer
  mapping (address => bytes) internal data;    //mapping of addresses to data
  mapping (address => mapping (address => mapping (uint256 => bytes32))) internal hashStore;  //mapping of issuer adresses to mapping of onwer addresses to mapping of nonce to hashes
  mapping (address => mapping (address => uint256)) internal hashNonce;  //mapping of issuer address to mapping of onwer address to nonce
  mapping (address => bool) internal recipientActive;  //if onwer ever got certificate in this platform or registered his eth address by name
  mapping (address => mapping (address => mapping (uint256 => bool))) internal recipientPermissionToChange;  //recipient _permission will be required to change any certificate hash

  event newIssue(address _issuer, address _receiver, uint256 document_number );
  event issuerNameLinked(address _ethaddress, bytes32 _name);
  event recipientNameLinked(address _ethaddress, bytes32 _name);
  event dataLinked(address _ethaddress, bytes _data);
  event permissionToChangeGranted(address _issuer, address _receiver, uint256 document_number, bool _permission);
  
  function forwardFunds(address _receiver)
    internal
  {
    _receiver.transfer(msg.value);
  }

  function () public payable {
    if (msg.value > 0)
    {
      forwardFunds(msg.sender);
    }
  }

  function linkIssuerName(bytes32 _name) public payable returns (bool success) {  //register issuer
    if (recipientActive[msg.sender]==true) {
      revert();
    }
    name[msg.sender] = _name;
    isIssuer[msg.sender] = true;
    if (msg.value > 0)
    {
      forwardFunds(msg.sender);
    }
    emit issuerNameLinked(msg.sender,_name);
    return true;
  }

  function linkRecipientName(bytes32 _name) public payable returns (bool success) {  //register certificate recipient (optional)
    if (isIssuer[msg.sender]==true) {
      revert();
    }
    name[msg.sender] = _name;
    recipientActive[msg.sender]=true;
    if (msg.value > 0)
    {
      forwardFunds(msg.sender);
    }
    emit recipientNameLinked(msg.sender,_name);
    return true;
  }

  function linkData(bytes _data) public payable returns (bool success) {  //link data to eth address (optional)
    data[msg.sender] = _data;
    if (msg.value > 0)
    {
      forwardFunds(msg.sender);
    }
    emit dataLinked(msg.sender, _data);
    return true;
  }

  function getData(address _ethaddress) public constant returns (bytes _data) {  //get linked data
    return data[_ethaddress];
  }

  function getName(address _ethaddress) public constant returns (bytes32 _name) {  //get linked name to eth address
    return name[_ethaddress];
  }

  function getIssuerStatus(address _ethaddress) public constant returns (bool status) {  //get whether eth address is issuer or onwer
    return isIssuer[_ethaddress];
  }

  function isRecipientActive(address _ethaddress) public constant returns (bool status) {  //function to know whether onwer used the service
    return recipientActive[_ethaddress];
  }

  function getCurrentCertificateNonce(address _issuer, address _recipient) public constant returns (uint256 _certificateNonce) {  //no of certificates issued by issuer to onwer
    return hashNonce[_issuer][_recipient];
  }

  function registerCertificateHash(address _receiver, bytes32 _hash) public payable returns (bool success) {  //issuer issues certificate to onwer
    //issuer can also send eth which will be forwarded to recipient
    if (isIssuer[msg.sender]==false || isIssuer[_receiver]==true) {
      revert();
    }
    if (msg.value > 0) {
      forwardFunds(_receiver);
    }
    uint256 current_nonce = hashNonce[msg.sender][_receiver];
    hashStore[msg.sender][_receiver][current_nonce] = _hash;
    hashNonce[msg.sender][_receiver] = current_nonce+1;

    if (recipientActive[_receiver]==false) {
      recipientActive[_receiver]=true;
    }
    emit newIssue(msg.sender, _receiver, hashNonce[msg.sender][_receiver]);
    return true;
  }

  function getCertificateHash(address _issuer, address _recipient, uint256 _certificateNonce) public constant returns (bytes32 _hash) {  //retrive certificate hash by providing issuer, onwer address and certificate no.
    return hashStore[_issuer][_recipient][_certificateNonce];
  }

  function grantPermissionToChange(address _issuer, uint256 _certificateNonce, bool _permission) public payable returns (bool success) {  //recipient grants issuer to _permission to change hash of any previously issued certificate
    if ( _certificateNonce >= hashNonce[_issuer][msg.sender] || _certificateNonce < 0)
    {
      revert();
    }
    else
    {
      recipientPermissionToChange[_issuer][msg.sender][_certificateNonce] = _permission;
      if (msg.value > 0)
      {
        forwardFunds(msg.sender);
      }
      emit permissionToChangeGranted( _issuer, msg.sender, _certificateNonce+1, _permission);
      return _permission;
    }
  }

  function changeCertificateHash(address _receiver, bytes32 _hash, uint256 _certificateNonce) public payable returns (bool success) {
    if ( recipientPermissionToChange[msg.sender][_receiver][_certificateNonce] == false )
    {
      revert();
    }
    else
    {
      hashStore[msg.sender][_receiver][_certificateNonce] = _hash;
      recipientPermissionToChange[msg.sender][_receiver][_certificateNonce] = false;
      if (msg.value > 0)
      {
        forwardFunds(_receiver);
      }
      emit newIssue(msg.sender, _receiver, _certificateNonce+1 );
      return true;
    }
  }

  function permissionToChange(address _issuer, address _receiver, uint256 _certificateNonce) public constant returns (bool status) {
    return recipientPermissionToChange[_issuer][_receiver][_certificateNonce];
  }
}