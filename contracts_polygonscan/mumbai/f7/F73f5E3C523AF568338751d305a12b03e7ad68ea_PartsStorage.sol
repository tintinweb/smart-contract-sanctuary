/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// File contracts/access/Owned.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Owned {

    address public owner;
    address public nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address indexed newOwner);

    constructor(address _owner) {
        require(_owner != address(0),
            "Address cannot be 0");

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function nominateNewOwner(address _owner)
    external
    onlyOwner {
        nominatedOwner = _owner;

        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
    external {
        require(msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership");

        emit OwnershipTransferred(owner, nominatedOwner);

        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
            "Only the contract owner may perform this action");
        _;
    }

}


// File contracts/access/AssociationController.sol


pragma solidity 0.8.7;

contract AssociationController is Owned {

    address public associatedContract;

    event AssociatedContractUpdated(address indexed associatedContract);

    constructor(address _associatedContract, address _owner) Owned(_owner) {
        require(_owner != address(0),
            "Onwer cannot be empty");

        associatedContract = _associatedContract;

        emit AssociatedContractUpdated(_associatedContract);
    }

    function setAssociatedContract(address _associatedContract)
    external
    onlyOwner {
        associatedContract = _associatedContract;

        emit AssociatedContractUpdated(_associatedContract);
    }

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract,
            "Only the associate contract may perform this action");
        _;
    }

}


// File contracts/PartsStorage.sol


pragma solidity ^0.8.7;

contract PartsStorage is AssociationController {

  struct Property {
    uint16 score;
    uint8 property;
    bool registered;
  }

  mapping(uint => mapping(uint => Property)) public partsProperties;

  mapping(uint => uint) public numOfParts;

  mapping(uint => bool) public seedRegistered;

  uint public numOfKind;

  constructor(address _associatedContract, address _owner)
  AssociationController(_associatedContract, _owner) {
  }

  function setNumOfKind(uint _numOfKind)
  external
  onlyOwner {
    require(numOfKind <= _numOfKind,
      "New number should not less than previous one");

    numOfKind = _numOfKind;
  }

  function setParts(
    uint[] memory _kindIndexes,
    uint[] memory _partsIndexes,
    uint16[] memory _scores,
    uint8[] memory _properties
  ) external
  onlyOwner {
    require(
      _kindIndexes.length == _partsIndexes.length &&
      _kindIndexes.length == _scores.length &&
      _kindIndexes.length == _properties.length,
      "Input lengths are not matched");

    for(uint i = 0; i < _kindIndexes.length; i++) {
      _setPart(_kindIndexes[i], _partsIndexes[i], _scores[i], _properties[i]);
    }
  }

  function generateAsset(uint _seed)
  external
  onlyAssociatedContract
  returns(
    uint[] memory generated,
    uint16 score,
    uint8 property,
    bool flagged
  ) {
    uint randNum = _seed % _getTotalCases();

    if(seedRegistered[randNum]) {
      return (new uint[](numOfKind), 0, 0, true);
    }

    seedRegistered[randNum] = true;

    (generated, score, property) = _getCombination(randNum);
  }

  function getCombination(uint _seed)
  external view
  returns(uint[] memory generated, uint16 score, uint8 property) {
    uint randNum = _seed % _getTotalCases();

    (generated, score, property) = _getCombination(randNum);
  }

  function _setPart(
    uint _kindIndex,
    uint _partsIndex,
    uint16 _score,
    uint8 _property
  ) internal {
    Property memory _mem_Property = partsProperties[_kindIndex][_partsIndex];

    if(!_mem_Property.registered) {
      numOfParts[_kindIndex]++;

      _mem_Property.registered = true;
    }

    _mem_Property.score = _score;
    _mem_Property.property = _property;

    partsProperties[_kindIndex][_partsIndex] = _mem_Property;
  }

  function _getCombination(uint _random)
  internal view
  returns(uint[] memory generated, uint16 score, uint8 property) {
    uint[] memory _generated = new uint[](numOfKind);
    uint16 scoreTotal;
    int _property;
    uint acc = 1;
    for(uint i = 0; i < numOfKind; i++) {
      uint reversedIndex = numOfKind - i - 1;
      uint _numOfPart_reversedIdx = numOfParts[reversedIndex];

      _generated[i] = uint(_random / acc) % _numOfPart_reversedIdx;
      scoreTotal += partsProperties[i][_generated[i]].score;
      if(partsProperties[i][_generated[i]].property == 2) {
        _property++;
      }
      if(partsProperties[i][_generated[i]].property == 1) {
        _property--;
      }

      acc *= _numOfPart_reversedIdx;
    }

    generated = _generated;
    score = scoreTotal / uint16(numOfKind);
    if(_property > 0) {
      property = 2;
    }
    if(_property < 0) {
      property = 1;
    }
  }

  function _getTotalCases()
  internal view
  returns(uint totalCases) {
    totalCases = 1;
    for(uint i = 0; i < numOfKind; i++) {
      totalCases = numOfParts[i] > 0 ? totalCases * numOfParts[i] : totalCases;
    }
  }

}