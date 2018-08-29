pragma solidity ^0.4.18;

contract StrategyManager {

  bytes15 managerName;
  address owner;

  struct StrategyStruct {
    address strategyAddress;
    uint strategyCategory;
    string label;
    uint index;
  }

  mapping(bytes15 => StrategyStruct) private strategyStructs;
  bytes15[] private strategyIndex;

  event LogNewStrategy   (bytes15 indexed strategyName, uint index, address strategyAddress, uint strategyCategory);
  event LogUpdateStrategy(bytes15 indexed strategyName, uint index, address strategyAddress, uint strategyCategory, string label);
  event LogDeleteStrategy(bytes15 indexed strategyName, uint index);

  modifier onlyOwner(){
      require(msg.sender==owner);
      _;
  }

  constructor(bytes15 _name) public{
      owner = msg.sender;
      managerName = _name;
  }

  function isStrategy(bytes15 strategyName)
    public
    constant
    returns(bool isIndeed)
  {
    if(strategyIndex.length == 0) return false;
    return (strategyIndex[strategyStructs[strategyName].index] == strategyName);
  }

  function insertStrategy(
    bytes15 strategyName,
    address strategyAddress,
    uint    strategyCategory,
    string label)
    onlyOwner
    public
    returns(uint index)
  {
    if(isStrategy(strategyName)) revert();
    strategyStructs[strategyName].strategyAddress = strategyAddress;
    strategyStructs[strategyName].strategyCategory   = strategyCategory;
    strategyStructs[strategyName].label   = label;
    strategyStructs[strategyName].index     = strategyIndex.push(strategyName)-1;
    emit LogNewStrategy(
        strategyName,
        strategyStructs[strategyName].index,
        strategyAddress,
        strategyCategory);
    return strategyIndex.length-1;
  }

  function deleteStrategy(bytes15 strategyName)
    onlyOwner
    public
    returns(uint index)
  {
    if(!isStrategy(strategyName)) revert();
    uint rowToDelete = strategyStructs[strategyName].index;
    bytes15 keyToMove = strategyIndex[strategyIndex.length-1];
    strategyIndex[rowToDelete] = keyToMove;
    strategyStructs[keyToMove].index = rowToDelete;
    strategyIndex.length--;
    emit LogDeleteStrategy(
        strategyName,
        rowToDelete);
    emit LogUpdateStrategy(
        keyToMove,
        rowToDelete,
        strategyStructs[keyToMove].strategyAddress,
        strategyStructs[keyToMove].strategyCategory,
        strategyStructs[keyToMove].label);
    return rowToDelete;
  }

  function getStrategy(bytes15 strategyName)
    public
    constant
    returns(address strategyAddress, uint strategyCategory, uint index, string label)
  {
    if(!isStrategy(strategyName)) revert();
    return(
      strategyStructs[strategyName].strategyAddress,
      strategyStructs[strategyName].strategyCategory,
      strategyStructs[strategyName].index,
      strategyStructs[strategyName].label);
  }

  function updateStrategyAddress(bytes15 strategyName, address strategyAddress)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isStrategy(strategyName)) revert();
    strategyStructs[strategyName].strategyAddress = strategyAddress;
    emit LogUpdateStrategy(
      strategyName,
      strategyStructs[strategyName].index,
      strategyAddress,
      strategyStructs[strategyName].strategyCategory,
      strategyStructs[strategyName].label);
    return true;
  }

  function updateStrategyCategory(bytes15 strategyName, uint strategyCategory)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isStrategy(strategyName)) revert();
    strategyStructs[strategyName].strategyCategory = strategyCategory;
    emit LogUpdateStrategy(
      strategyName,
      strategyStructs[strategyName].index,
      strategyStructs[strategyName].strategyAddress,
      strategyCategory,
      strategyStructs[strategyName].label);
    return true;
  }

  function updateStrategyLabel(bytes15 strategyName, string newLabel)
    onlyOwner
    public
    returns(bool success)
  {
    if(!isStrategy(strategyName)) revert();
    strategyStructs[strategyName].label = newLabel;
    emit LogUpdateStrategy(
      strategyName,
      strategyStructs[strategyName].index,
      strategyStructs[strategyName].strategyAddress,
      strategyStructs[strategyName].strategyCategory,
      newLabel);
    return true;
  }

  function getStrategyCount()
    public
    constant
    returns(uint count)
  {
    return strategyIndex.length;
  }

  function getStrategyAtIndex(uint index)
    public
    constant
    returns(bytes15 strategyName)
  {
    return strategyIndex[index];
  }

}