//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../interfaces/IECRegistry.sol";

contract AccidentalCollaboration {

    uint16      public immutable    traitId;
    IECRegistry public              ECRegistry;

    // using arrays so we can add more layers in the future
    mapping(uint16 => uint8[]) public data;

    event updateTraitEvent(uint16 indexed _tokenId, uint8[] indexed _newData);

    constructor(address _registry, uint16 _traitId) {
        traitId = _traitId;
        ECRegistry = IECRegistry(_registry);
    }

    function setData(uint16[] memory _tokenIds, uint8[][] memory _value) public onlyAllowed {
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            data[_tokenIds[i]] = _value[i];
            emit updateTraitEvent(_tokenIds[i], _value[i]);
        }
    }

    function setValue(uint16 _tokenId, uint8[] memory _value) public onlyAllowed {
        data[_tokenId] = _value;
        emit updateTraitEvent(_tokenId, _value);
    }

    function getValue(uint16 _tokenId) public view returns (uint8[] memory) {
         return data[_tokenId];
    }

    modifier onlyAllowed() {
        require(
            ECRegistry.addressCanModifyTrait(msg.sender, traitId)
             || msg.sender == ECRegistry.owner()
             || ECRegistry.contractController(msg.sender),
            "Not Authorised" 
        );
        _;
    }
}

pragma solidity >=0.6.0 <0.8.0;

interface IECRegistry {
    function getImplementer(uint16 traitID) external view returns (address);
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function addressCanModifyTraits(address, uint16[] memory) external view returns (bool);
    function hasTrait(uint16 traitID, uint16 tokenID) external view returns (bool);
    function setTrait(uint16 traitID, uint16 tokenID, bool) external;
    function setTraitOnTokens(uint16 traitID, uint16[] memory tokenID, bool[] memory) external;
    function owner() external view returns (address);
    function contractController(address) external view returns (bool);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}