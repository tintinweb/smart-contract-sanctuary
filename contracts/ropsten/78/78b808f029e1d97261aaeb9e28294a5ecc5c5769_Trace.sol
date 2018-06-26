pragma solidity ^0.4.24;

contract Trace {

  struct Object {
    uint256 id;
    string name;
    bool inTransit;
    address recipient;
    uint256[] ownershipIDs;
  }

  struct Ownership {
    uint256 id;
    address owner;
    uint256 receptionTime;
  }

  uint256 public nbObjects;
  mapping (uint256 => Object) public objects;

  uint256 public nbOwnerships;
  mapping (uint256 => Ownership) public ownerships;

  constructor() public {
    nbOwnerships = 0;
    nbObjects = 0;
  }

  function createObject(string _name) public {
    nbOwnerships += 1;
    uint256 _ownershipID = nbOwnerships;
    ownerships[_ownershipID] = Ownership({
      id: _ownershipID,
      owner: msg.sender,
      receptionTime: now
    });

    nbObjects += 1;
    uint256 _objectID = nbObjects;
    address _recipient;

    uint256[] memory _ownershipIDs;

    objects[_objectID] = Object({
      id: _objectID,
      name: _name,
      inTransit: false,
      recipient: _recipient,
      ownershipIDs: _ownershipIDs
    });

    Object storage o = objects[_objectID];
    o.ownershipIDs.push(_ownershipID);
  }

  modifier ownsObject(uint256 _objectID, address _sender) {
    Object storage o = objects[_objectID];
    require( getCurrentOwner(_objectID) == _sender ); _;
  }

  modifier canReceiveObject(uint256 _objectID, address _sender) {
    Object storage o = objects[_objectID];
    require( (o.inTransit) && (o.recipient == _sender) ); _;
  }

  function sendObjectWithApproval(uint256 _objectID, address _recipient) public
    ownsObject(_objectID, msg.sender)
  {
    Object storage o = objects[_objectID];
    o.inTransit = true;
    o.recipient = _recipient;
  }

  function approveObjectReception(uint256 _objectID) public
    canReceiveObject(_objectID, msg.sender)
  {
    receiveObject(_objectID, msg.sender);
  }

  function sendObjectWithoutApproval(uint256 _objectID, address _recipient) public
    ownsObject(_objectID, msg.sender)
  {
    receiveObject(_objectID, _recipient);
  }

  function receiveObject(uint256 _objectID, address _recipient) private
  {
    Object storage o = objects[_objectID];
    o.inTransit = false;
    o.recipient = address(0);

    nbOwnerships += 1;
    uint256 _ownershipID = nbOwnerships;
    ownerships[_ownershipID] = Ownership({
      id: _ownershipID,
      owner: _recipient,
      receptionTime: now
    });
    o.ownershipIDs.push(_ownershipID);
  }

  function getCurrentOwner(uint256 _objectID) public view returns(address) {
    Object storage o = objects[_objectID];
    uint256 ownershipID = o.ownershipIDs[getTotalNbOwners(_objectID)-1];
    return ownerships[ownershipID].owner;
  }

  function getTotalNbOwners(uint256 _objectID) public view returns(uint256) {
    Object storage o = objects[_objectID];
    return o.ownershipIDs.length;
  }

  /* function getTrace(uint256 _objectID) public returns(string) {
    return strConcat(toString(msg.sender), &quot;-->&quot;);
  }

  function toString(address x) private returns (string) {
    bytes memory b = new bytes(20);
    for (uint i = 0; i < 20; i++)
      b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    return string(b);
  }

  function strConcat(string _a, string _b, string _c, string _d, string _e) private returns (string){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
    return strConcat(_a, _b, _c, _d, &quot;&quot;);
  }

  function strConcat(string _a, string _b, string _c) internal returns (string) {
    return strConcat(_a, _b, _c, &quot;&quot;, &quot;&quot;);
  }

  function strConcat(string _a, string _b) internal returns (string) {
    return strConcat(_a, _b, &quot;&quot;, &quot;&quot;, &quot;&quot;);
  } */

}