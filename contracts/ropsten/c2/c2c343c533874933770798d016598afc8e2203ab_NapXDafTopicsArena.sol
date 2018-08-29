pragma solidity ^0.4.18;

contract NapXDafTopicsArena {

  bytes15 arenaName;
  address owner;

  struct Topic {
    address topicAddress;
    bytes32 longDescription;
    bytes15 assetClass;
    uint index;
  }

  mapping(bytes15 => Topic) private topics;
  bytes15[] private topicIndex;

  event LogNewTopic   (bytes15 indexed topicName, uint index, address topicAddress, bytes32 indexed longDescription, bytes15 indexed assetClass);
  event LogUpdateTopic(bytes15 indexed topicName, uint index, address topicAddress, bytes32 indexed longDescription, bytes15 indexed assetClass);
  event LogDeleteTopic(bytes15 indexed topicName, uint index);

  modifier onlyOwner(){
      require(msg.sender==owner);
      _;
  }

  constructor(bytes15 _name) public{
      owner = msg.sender;
      arenaName = _name;
  }

  function isTopic(bytes15 topicName)
    public
    constant
    returns(bool isIndeed)
  {
    if(topicIndex.length == 0) return false;
    return (topicIndex[topics[topicName].index] == topicName);
  }

  function insertTopic(
    bytes15 topicName,
    address topicAddress,
    bytes32 longDescription,
    bytes15 assetClass)
    onlyOwner
    public
    returns(uint index)
  {
    if(isTopic(topicName)) revert();
    topics[topicName].topicAddress = topicAddress;
    topics[topicName].longDescription   = longDescription;
    topics[topicName].assetClass   = assetClass;
    topics[topicName].index     = topicIndex.push(topicName)-1;
    emit LogNewTopic(
        topicName,
        topics[topicName].index,
        topicAddress,
        longDescription,
        assetClass);
    return topicIndex.length-1;
  }

  function deleteTopic(bytes15 topicName)
    onlyOwner
    public
    returns(uint index)
  {
    if(!isTopic(topicName)) revert();
    uint rowToDelete = topics[topicName].index;
    bytes15 keyToMove = topicIndex[topicIndex.length-1];
    topicIndex[rowToDelete] = keyToMove;
    topics[keyToMove].index = rowToDelete;
    topicIndex.length--;
    emit LogDeleteTopic(
        topicName,
        rowToDelete);
    emit LogUpdateTopic(
        keyToMove,
        rowToDelete,
        topics[keyToMove].topicAddress,
        topics[keyToMove].longDescription,
        topics[keyToMove].assetClass);
    return rowToDelete;
  }

  function getTopic(bytes15 topicName)
    public
    constant
    returns(address topicAddress, uint index, bytes32 longDescription, bytes15 assetClass)
  {
    if(!isTopic(topicName)) revert();
    return(
      topics[topicName].topicAddress,
      topics[topicName].index,
      topics[topicName].longDescription,
      topics[topicName].assetClass);
  }

  function updateTopicAddress(bytes15 topicName, address topicAddress)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isTopic(topicName)) revert();
    topics[topicName].topicAddress = topicAddress;
    emit LogUpdateTopic(
      topicName,
      topics[topicName].index,
      topicAddress,
      topics[topicName].longDescription,
      topics[topicName].assetClass);
    return true;
  }

  function updateTopicDescription(bytes15 topicName, bytes32 longDescription)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isTopic(topicName)) revert();
    topics[topicName].longDescription = longDescription;
    emit LogUpdateTopic(
      topicName,
      topics[topicName].index,
      topics[topicName].topicAddress,
      longDescription,
      topics[topicName].assetClass);
    return true;
  }

  function updateTopicAssetClass(bytes15 topicName, bytes15 assetClass)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isTopic(topicName)) revert();
    topics[topicName].assetClass = assetClass;
    emit LogUpdateTopic(
      topicName,
      topics[topicName].index,
      topics[topicName].topicAddress,
      topics[topicName].longDescription,
      assetClass);
    return true;
  }

  function getTopicCount()
    public
    constant
    returns(uint count)
  {
    return topicIndex.length;
  }

  function getTopicAtIndex(uint index)
    public
    constant
    returns(bytes15 topicName)
  {
    return topicIndex[index];
  }

}